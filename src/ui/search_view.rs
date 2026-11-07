use std::{collections::{BTreeMap, VecDeque, BTreeSet}, sync::{Arc, atomic::{AtomicBool, Ordering}}};
use gpui_kit::*;
use gpui_kit::component::{ActiveTheme as _, h_flex, v_flex};
use gpui_kit::component::input::{Input, InputState, InputEvent};
use gpui_kit::prelude::FluentBuilder as _;
use super::{Workbench, folders::FolderWorkspace, project_search::{self, Options, File}, metrics};

pub const SEARCH: &str = "workbench://Project Search";
pub const DIAGNOSTICS: &str = "workbench://No problems";

pub struct SearchView {
    owner: WeakEntity<Workbench>,
    ws: Entity<FolderWorkspace>,
    inputs: [Entity<InputState>; 4],
    options: Options,
    submitted: Options,
    pub title: String,
    pub position: Option<String>,
    files: Vec<File>,
    selected: usize,
    reveal: bool,
    collapsed: BTreeSet<usize>,
    expanded: BTreeMap<usize, (usize, usize)>,
    filters: bool,
    replace: bool,
    running: bool,
    cancel: Arc<AtomicBool>,
    message: String,
    pending: VecDeque<(File, usize, Option<String>)>,
    notice: String,
    list: ListState,
    _subscriptions: Vec<Subscription>,
}

impl Drop for SearchView { fn drop(&mut self) { self.cancel.store(true, Ordering::Relaxed); } }

impl SearchView {
    fn new(owner: WeakEntity<Workbench>, ws: Entity<FolderWorkspace>, window: &mut Window, cx: &mut Context<Self>) -> Self {
        let inputs = ["Search all files…", "Include: e.g. src/**/*.rs", "Exclude: e.g. vendor/*, *.lock", "Replace in project…"]
            .map(|placeholder| cx.new(|cx| InputState::new(window, cx).placeholder(placeholder)));
        let mut subscriptions: Vec<_> = inputs.iter().map(|input| cx.subscribe_in(input, window, |this, input, event: &InputEvent, window, cx| {
            if matches!(event, InputEvent::PressEnter { .. }) && *input == this.inputs[0] { this.start(cx); }
            cx.notify();
            let _ = window;
        })).collect();
        subscriptions.push(cx.observe_in(&ws, window, |this, _, window, cx| this.process(window, cx)));
        Self { owner, ws, inputs, options: Options::default(), submitted: Options::default(), title: "Project Search".into(), position: None,
            files: vec![], selected: 0, reveal: false, collapsed: BTreeSet::new(), expanded: BTreeMap::new(), filters: false, replace: false, running: false,
            cancel: Arc::new(AtomicBool::new(false)), message: String::new(), pending: VecDeque::new(), notice: String::new(),
            list: ListState::new(0, ListAlignment::Top, px(0.)), _subscriptions: subscriptions }
    }

    fn start(&mut self, cx: &mut Context<Self>) {
        if !self.pending.is_empty() { return; }
        self.cancel.store(true, Ordering::Relaxed);
        self.cancel = Arc::new(AtomicBool::new(false));
        let cancel = self.cancel.clone();
        self.options.query = self.inputs[0].read(cx).value().to_string();
        self.options.include = self.inputs[1].read(cx).value().to_string();
        self.options.exclude = self.inputs[2].read(cx).value().to_string();
        let options = self.options.clone();
        self.submitted = options.clone();
        self.title = if options.query.is_empty() { "Project Search".into() } else { options.query.clone() };
        let ws = self.ws.read(cx);
        if ws.folder_id.is_empty() { self.message = "Open a folder to search".into(); cx.notify(); return; }
        let root = ws.tree.root.clone();
        let open: BTreeMap<_, _> = ws.group.paths().into_iter().filter_map(|path| {
            let editor = ws.group.views(&path).next()?;
            ws.group.docs.get(&path).filter(|d| d.loaded)?;
            Some((path.clone(), editor.read(cx).value().to_string()))
        }).collect();
        self.running = true; self.files.clear(); self.selected = 0; self.collapsed.clear(); self.expanded.clear(); self.position = None;
        self.message = "Searching…".into(); cx.notify();
        cx.spawn(async move |this, cx| {
            let token = cancel.clone();
            let result = cx.background_spawn(async move { project_search::search(&root, &options, &open, &token) }).await;
            let _ = this.update(cx, |this, cx| {
                if !Arc::ptr_eq(&this.cancel, &cancel) { return; }
                this.running = false;
                match result {
                    Ok(result) => {
                        this.message = if result.cancelled { "Search cancelled".into() } else if result.limited { "Search limit reached".into() }
                            else if !result.errors.is_empty() { result.errors.join("\n") } else { std::mem::take(&mut this.notice) };
                        this.files = result.files;
                        this.select(0, cx);
                    },
                    Err(error) => this.message = error,
                }
                cx.notify();
            });
        }).detach();
    }

    fn count(&self) -> usize { self.files.iter().map(|f| f.hits.len()).sum() }
    fn at(&self, index: usize) -> Option<(usize, usize)> {
        let mut offset = 0;
        for (f, file) in self.files.iter().enumerate() {
            if index < offset + file.hits.len() { return Some((f, index - offset)); }
            offset += file.hits.len();
        }
        None
    }
    fn select(&mut self, index: usize, cx: &mut Context<Self>) {
        self.selected = index;
        if let Some((file, _)) = self.at(index) { self.collapsed.remove(&file); self.reveal = true; }
        self.position = self.at(index).map(|(f, h)| {
            let file = &self.files[f]; let hit = &file.hits[h];
            super::status::parts(&file.text, hit.range.end, std::slice::from_ref(&hit.range), None).0
        });
        let _ = self.owner.update(cx, |_, cx| cx.notify());
        cx.notify();
    }

    fn queue(&mut self, replace: bool, all: bool, window: &mut Window, cx: &mut Context<Self>) {
        if self.running || !self.pending.is_empty() { return; }
        let value = replace.then(|| self.inputs[3].read(cx).value().to_string());
        if all {
            self.pending.extend(self.files.iter().cloned().map(|f| (f, usize::MAX, value.clone())));
        } else if let Some((f, h)) = self.at(self.selected) { self.pending.push_back((self.files[f].clone(), h, value)); }
        self.message = "Opening search result…".into();
        self.open_pending(window, cx);
    }
    fn open_pending(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        if let Some((file, _, _)) = self.pending.front() {
            let path = file.path.clone();
            self.ws.update(cx, |ws, cx| { ws.group.open(&path, false, window, cx); cx.notify(); });
            self.process(window, cx);
        }
    }
    fn process(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let Some((file, hit, replacement)) = self.pending.front().cloned() else { return };
        let ws = self.ws.read(cx);
        let Some(doc) = ws.group.docs.get(&file.path) else {
            self.message = "Search result was closed; search again".into(); self.pending.clear(); cx.notify(); return;
        };
        if doc.pending.is_some() { return; }
        if !doc.loaded { self.message = "File could not be loaded for editing".into(); self.pending.clear(); cx.notify(); return; }
        let Some(editor) = ws.group.views(&file.path).next().cloned() else { return };
        let current = editor.read(cx).value();
        self.pending.pop_front();
        if let Some(replacement) = replacement {
            let text = match project_search::replacement(&file, &current, &self.submitted, &replacement, (hit != usize::MAX).then_some(hit)) {
                Ok(text) => text,
                Err(error) => { self.message = error; self.pending.clear(); cx.notify(); return; }
            };
            self.ws.update(cx, |ws, cx| {
                ws.group.fill(&file.path, &text, window, cx);
                ws.group.on_edit(&editor, super::pane::buffer_hash(&text)); cx.notify();
            });
            // Zed replaces in the open buffer only: the tab stays modified and the user saves it (nothing is written to disk).
            self.notice = "Replacement applied".into();
            if self.pending.is_empty() { self.start(cx); } else { self.open_pending(window, cx); }
            cx.notify();
        } else {
            if current.as_ref() != file.text { self.message = "File changed since search; search again".into(); cx.notify(); return; }
            if let Some(hit) = file.hits.get(hit) {
                // I-10: opening a result is an explicit jump, recorded for Go Back whatever the distance.
                self.ws.update(cx, |ws, cx| ws.group.nav_jump(&file.path, &current, hit.range.end, cx));
                editor.update(cx, |editor, cx| editor.set_selected_range(hit.range.clone(), cx));
                let _ = self.owner.update(cx, |this, cx| { this.focus_active_pane(window, cx); cx.notify(); });
            }
        }
    }
}

/// 22×22 icon button (hover background; `on` highlights a toggle). `tip` = (probe id, tooltip text).
fn icon_button(id: impl Into<ElementId>, icon: &'static str, tip: Option<(&'static str, &'static str)>, on: bool, cx: &App) -> Stateful<Div> {
    let theme = cx.theme();
    let hover = theme.secondary_hover;
    div().id(id).flex().flex_shrink_0().items_center().justify_center().size(metrics::BUTTON_DEFAULT).rounded_md()
        .text_color(if on { theme.foreground } else { theme.muted_foreground })
        .when(on, |d| d.bg(theme.secondary_active))
        .hover(move |s| s.bg(hover))
        .when_some(tip, |d, (id, text)| d.tooltip(super::tooltip::build(super::tooltip::Spec::one(id, super::tooltip::Line::text(text)))))
        .child(super::zed_icons::icon(icon).size(metrics::ICON_SMALL))
}

/// Bordered, rounded query/replace/filter box in the buffer font; `suffix` sits inside on the right.
fn input_box(input: &Entity<InputState>, suffix: Option<Div>, cx: &App) -> Div {
    h_flex().flex_1().min_w_0().h(metrics::SEARCH_INPUT_HEIGHT).items_center().border_1().border_color(cx.theme().border)
        .rounded(metrics::SEARCH_INPUT_RADIUS).pl(metrics::SEARCH_INPUT_PADDING_LEFT).pr(metrics::SEARCH_INPUT_PADDING_RIGHT)
        .font(super::fonts::editor())
        .child(div().flex_1().min_w_0().child(Input::new(input).appearance(false).px(metrics::SEARCH_INPUT_TEXT_INSET)))
        .children(suffix)
}

/// A toolbar row: 32 high, items 8 apart.
fn bar_row() -> Div { h_flex().w_full().h(metrics::SEARCH_INPUT_HEIGHT).items_center().gap(metrics::SEARCH_BAR_GAP) }

/// Padded toolbar with the bottom border shared by Project Search and Diagnostics.
fn toolbar(cx: &App) -> Div {
    v_flex().w_full().flex_shrink_0().px(metrics::SEARCH_TOOLBAR_PADDING_X).py(metrics::SEARCH_TOOLBAR_PADDING_Y).gap(metrics::SEARCH_BAR_GAP)
        .border_b_1().border_color(cx.theme().border)
}

/// Query box column: [22 spacer] [box up to 1200] [fixed trailing controls] — aligns every row's box.
fn aligned_row(content: impl IntoElement, trail: impl IntoElement) -> Div {
    bar_row().pr(metrics::SEARCH_RIGHT_RESERVE).child(div().flex_none().size(metrics::BUTTON_DEFAULT))
        .child(h_flex().flex_1().min_w_0().max_w(metrics::SEARCH_INPUT_MAX_WIDTH).child(content))
        .child(h_flex().flex_none().w(metrics::SEARCH_TRAIL_WIDTH).gap(metrics::SEARCH_MODES_GAP).child(trail))
}

impl Render for SearchView {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let theme = cx.theme();
        let muted = theme.muted_foreground;
        let gap = metrics::STATUS_BAR_ITEM_GAP;
        let mut suffix = h_flex().gap(gap);
        let mut modes = h_flex().gap(metrics::SEARCH_MODES_GAP);
        for (id, icon, enabled) in [("case", "case_sensitive", self.options.case), ("words", "whole_word", self.options.words), ("regex", "regex", self.options.regex),
            ("filters", "filter", self.filters), ("replace", "replace", self.replace)] {
            let tip = match id { "case" => "Match case Alt-C", "words" => "Match whole words Alt-W", "regex" => "Match with regex Alt-R",
                "filters" => "Toggle Filters Alt-F", _ => "Toggle Replace Alt-Shift-H" };
            let button = icon_button(id, icon, Some((id, tip)), enabled, cx)
                .on_click(cx.listener(move |this, _, _, cx| {
                    match id { "case" => this.options.case ^= true, "words" => this.options.words ^= true, "regex" => this.options.regex ^= true,
                        "filters" => this.filters ^= true, _ => this.replace ^= true }; cx.notify();
                }));
            if ["case", "words", "regex"].contains(&id) { suffix = suffix.child(button); } else { modes = modes.child(button); }
        }
        // The 1 px transparent left border is Zed's separator slot before the match buttons (capture: replace end → previous = 8 + 1 + 6).
        let mut matches = h_flex().items_center().gap(gap).pl(metrics::SEARCH_MATCHES_PADDING_LEFT).border_l_1().border_color(gpui_kit::transparent_black());
        for (id, icon, delta) in [("Previous", "chevron_left", -1isize), ("Next", "chevron_right", 1)] {
            matches = matches.child(icon_button(id, icon, Some((id, id)), false, cx).size(metrics::SEARCH_MATCH_BUTTON).on_click(cx.listener(move |this, _, _, cx| {
                let count = this.count(); if count > 0 { this.select((this.selected as isize + delta).rem_euclid(count as isize) as usize, cx); }
            })));
        }
        matches = matches.child(div().ml(metrics::SEARCH_COUNT_MARGIN_LEFT).min_w(metrics::SEARCH_COUNT_MIN_WIDTH).text_size(metrics::TEXT_SIZE_SMALL).text_color(muted)
            .child(format!("{}/{}", if self.count() == 0 { 0 } else { self.selected + 1 }, self.count())));
        if self.running {
            matches = matches.child(div().id("cancel").px(gap).text_size(metrics::TEXT_SIZE_SMALL).child("Cancel")
                .on_click(cx.listener(|this, _, _, _| this.cancel.store(true, Ordering::Relaxed))));
        }
        // Zed ChevronDownUp while results are expanded, ChevronUpDown once they are all folded.
        let collapse = icon_button("collapse", if !self.files.is_empty() && self.collapsed.len() == self.files.len() { "chevron_up_down" } else { "chevron_down_up" }, Some(("collapse", "Collapse/Expand All")), false, cx).on_click(cx.listener(|this, _, _, cx| {
            if this.collapsed.is_empty() { this.collapsed.extend(0..this.files.len()); } else { this.collapsed.clear(); } cx.notify();
        }));
        let mut bar = toolbar(cx).child(bar_row().pr(metrics::SEARCH_RIGHT_RESERVE).child(collapse)
            .child(h_flex().flex_1().min_w_0().max_w(metrics::SEARCH_INPUT_MAX_WIDTH).child(input_box(&self.inputs[0], Some(suffix), cx)))
            .child(h_flex().flex_none().w(metrics::SEARCH_TRAIL_WIDTH).gap(metrics::SEARCH_BAR_GAP).child(modes).child(matches)));
        if self.filters {
            let toggles = h_flex().gap(metrics::SEARCH_MODES_GAP).children([("only-open", "folder_search", "Only Search Open Files", self.options.only_open), ("ignored", "file_ignored", "Also search files ignored by configuration", self.options.ignored)]
                .map(|(id, icon, title, enabled)| icon_button(id, icon, Some((id, title)), enabled, cx).on_click(cx.listener(move |this, _, _, cx| {
                    if id == "only-open" { this.options.only_open ^= true; } else { this.options.ignored ^= true; } cx.notify();
                }))));
            bar = bar.child(aligned_row(h_flex().w_full().gap(metrics::SEARCH_BAR_GAP).child(input_box(&self.inputs[1], None, cx)).child(input_box(&self.inputs[2], None, cx)), toggles));
        }
        if self.replace {
            let actions = h_flex().gap(metrics::SEARCH_MODES_GAP)
                .child(icon_button("replace-next", "replace_next", Some(("replace-next", "Replace Next")), false, cx).on_click(cx.listener(|this, _, window, cx| this.queue(true, false, window, cx))))
                .child(icon_button("replace-all", "replace_all", Some(("replace-all", "Replace All")), false, cx).on_click(cx.listener(|this, _, window, cx| this.queue(true, true, window, cx))));
            bar = bar.child(aligned_row(input_box(&self.inputs[3], None, cx), actions));
        }
        let mut view = v_flex().size_full().bg(theme.background).text_color(theme.foreground)
            .key_context("ProjectSearch").capture_key_down(cx.listener(|this, event: &KeyDownEvent, window, cx| {
                let key = event.keystroke.key.as_str(); let modifiers = event.keystroke.modifiers;
                if modifiers.alt {
                    match key {
                        "enter" => this.queue(false, false, window, cx), "c" => this.options.case ^= true,
                        "w" => this.options.words ^= true, "r" => this.options.regex ^= true,
                        "f" => this.filters ^= true, "h" if modifiers.shift => this.replace ^= true, _ => return,
                    } cx.stop_propagation(); cx.notify();
                }
            })).child(bar);
        if !self.message.is_empty() {
            view = view.child(div().px(metrics::SEARCH_TOOLBAR_PADDING_X).py(gap).text_size(metrics::TEXT_SIZE_SMALL).text_color(muted).child(self.message.clone()));
        }
        let mut rows = Vec::new();
        let mut index = 0;
        for (f, file) in self.files.iter().enumerate() {
            rows.push((f, None, index));
            for h in 0..file.hits.len() {
                if !self.collapsed.contains(&f) { rows.push((f, Some(h), index)); }
                index += 1;
            }
        }
        if self.list.item_count() != rows.len() { self.list.reset(rows.len()); }
        if self.reveal {
            if let Some(row) = rows.iter().position(|(_, hit, index)| hit.is_some() && *index == self.selected) { self.list.scroll_to_reveal_item(row); }
            self.reveal = false;
        }
        let _ = window;
        if !rows.is_empty() {
            return view.child(list(self.list.clone(), cx.processor(move |this, row, window, cx| this.result_row(rows[row], window, cx))).flex_1()).into_any_element();
        }
        // Empty state: the block is centred, its lines are left-aligned (icon, name, muted key).
        let mut guide = v_flex().items_start().gap(gap)
            // Zed project_search.rs:1089/1111 (Label Large 16) and 2519-2527 (subtitle Label 14, muted, mb_2): Labels use the default 1.618 line height.
            .child(div().text_size(metrics::TEXT_SIZE_LARGE).line_height(relative(metrics::SEARCH_LANDING_LINE_HEIGHT)).child("Search All Files"))
            .child(div().text_size(metrics::TEXT_SIZE_DEFAULT).line_height(relative(metrics::SEARCH_LANDING_LINE_HEIGHT)).text_color(muted).mb(metrics::SEARCH_BAR_GAP).child("Start typing to search. For more options:"));
        for (icon, text, key) in [("filter", "Include/exclude specific paths", "Alt-F"), ("replace", "Find and replace", "Alt-Shift-H"),
            ("regex", "Match with regex", "Alt-R"), ("case_sensitive", "Match case", "Alt-C"), ("whole_word", "Match whole words", "Alt-W")] {
            guide = guide.child(h_flex().items_center().h(metrics::BUTTON_DEFAULT).px(metrics::STATUS_TEXT_BUTTON_PADDING_X).gap(gap).text_size(metrics::TEXT_SIZE_DEFAULT).child(super::zed_icons::icon(icon).size(metrics::ICON_SMALL))
                .child(text).child(div().ml(gap).text_color(muted).child(key)));
        }
        view.child(div().flex().flex_1().items_center().justify_center().child(guide)).into_any_element()
    }
}

impl SearchView {
    fn result_row(&self, (f, h, at): (usize, Option<usize>, usize), window: &Window, cx: &mut Context<Self>) -> AnyElement {
        let theme = cx.theme();
        let (muted, border) = (theme.muted_foreground, theme.border);
        let file = &self.files[f];
        let Some(h) = h else {
            let root = self.ws.read(cx).tree.root.clone();
            let directory = relative_directory(&root, &file.path);
            let collapsed = self.collapsed.contains(&f);
            let current = self.at(self.selected).is_some_and(|(selected, _)| selected == f);
            let open = h_flex().id(("open", f)).flex_none().h(metrics::BUTTON_DEFAULT).items_center().gap(metrics::SEARCH_HEADER_GAP)
                .px(metrics::STATUS_BAR_ITEM_GAP).border_1().border_color(border).rounded(metrics::SEARCH_HEADER_RADIUS).bg(theme.popover)
                .child("Open File").child(div().text_color(muted).child("Alt-Enter"))
                .on_click(cx.listener(move |this, _, window, cx| { cx.stop_propagation(); this.select(at, cx); this.queue(false, false, window, cx); }));
            // Header band height = search_results["header.lines"] buffer lines minus the margins above and below.
            let band = metrics::BUFFER_FONT_SIZE * metrics::BUFFER_LINE_HEIGHT_MULTIPLIER * metrics::SEARCH_HEADER_LINES;
            return div().w_full().p(metrics::SEARCH_HEADER_MARGIN).child(h_flex().id(("file", f)).w_full().items_center().gap(metrics::SEARCH_HEADER_GAP)
                .h(band - super::rem::to_px(metrics::SEARCH_HEADER_MARGIN, window) * 2.).pl(metrics::SEARCH_HEADER_PADDING_LEFT).pr(metrics::SEARCH_HEADER_PADDING_RIGHT)
                .border_1().border_color(border).rounded(metrics::SEARCH_HEADER_RADIUS).bg(theme.secondary)
                .hover(|d| d.bg(theme.secondary_hover)).font(super::fonts::editor()).text_size(metrics::BUFFER_FONT_SIZE)
                .child(div().flex().flex_none().items_center().justify_center().size(metrics::SEARCH_HEADER_FOLD_BUTTON).text_color(muted)
                    .child(super::zed_icons::icon(if collapsed { "chevron_right" } else { "chevron_down" }).size(metrics::ICON_SMALL)))
                .child(file.path.file_name().unwrap_or_default().to_string_lossy().to_string())
                .child(div().flex_1().min_w_0().overflow_hidden().whitespace_nowrap().text_ellipsis().text_color(muted).child(directory))
                .children(current.then_some(open))
                .on_click(cx.listener(move |this, _, _, cx| { if !this.collapsed.remove(&f) { this.collapsed.insert(f); } cx.notify(); }))
                ).into_any_element();
        };
        let hit = &file.hits[h];
        let extra = self.expanded.get(&at).copied().unwrap_or_default();
        let first_row = hit.context_line.saturating_sub(extra.0);
        let last_row = (hit.line + 2 + extra.1).min(file.line_starts.len());
        let start = file.line_starts[first_row];
        let end = file.line_starts.get(last_row).copied().unwrap_or(file.text.len());
        let source = &file.text[start..end];
        let lines: Vec<_> = source.split_inclusive('\n').collect();
        let mut excerpt = v_flex().id(("result", at)).w_full().font(super::fonts::editor()).text_size(metrics::BUFFER_FONT_SIZE)
            .line_height(relative(metrics::BUFFER_LINE_HEIGHT_MULTIPLIER))
            .when(h > 0, |d| d.border_t_1().border_color(border))
            .tooltip(super::tooltip::build(super::tooltip::Spec::one("search-excerpt", super::tooltip::Line::text(format!("{}:{}\n{}", hit.line, hit.column, hit.excerpt)))))
            .on_click(cx.listener(move |this, _, window, cx| { this.select(at, cx); this.queue(false, false, window, cx); }));
        let mut offset = start;
        for (row, line) in lines.iter().enumerate() {
            let number = row + first_row;
            let range = offset..offset + line.len(); offset += line.len();
            let value = line.trim_end_matches(['\r', '\n']);
            let lo = hit.range.start.saturating_sub(range.start).min(value.len());
            let hi = hit.range.end.saturating_sub(range.start).min(value.len());
            let code = if lo < hi {
                h_flex().child(value[..lo].to_owned()).child(div().bg(theme.selection).child(value[lo..hi].to_owned())).child(value[hi..].to_owned())
            } else { h_flex().child(value.to_owned()) };
            // Expand arrows live in the gutter: up on the first line, down on the last.
            let arrow = div().flex().flex_none().items_center().justify_center().w(metrics::SEARCH_GUTTER_ARROW).text_color(muted);
            let arrow = if row == 0 {
                arrow.child(icon_button(("expand-up", at), "expand_up", Some(("expand-up", "Expand excerpt above")), false, cx)
                    .on_click(cx.listener(move |this, _, _, cx| { cx.stop_propagation(); this.expanded.entry(at).or_default().0 += 2; cx.notify(); })))
            } else if row + 1 == lines.len() {
                arrow.child(icon_button(("expand-down", at), "expand_down", Some(("expand-down", "Expand excerpt below")), false, cx)
                    .on_click(cx.listener(move |this, _, _, cx| { cx.stop_propagation(); this.expanded.entry(at).or_default().1 += 2; cx.notify(); })))
            } else { arrow };
            let on_hit = lo < hi;
            excerpt = excerpt.child(h_flex().w_full().items_start().child(arrow)
                .child(div().flex_none().w(metrics::SEARCH_GUTTER_NUMBER).text_right().text_color(if on_hit { theme.foreground } else { muted }).child((number + 1).to_string()))
                .child(div().flex_1().min_w_0().overflow_hidden().pl(metrics::SEARCH_GUTTER_GAP).child(code)));
        }
        excerpt.into_any_element()
    }
}

pub struct Diagnostics { focus: FocusHandle }
impl Render for Diagnostics {
    fn render(&mut self, _: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let theme = cx.theme();
        let gap = metrics::STATUS_BAR_ITEM_GAP;
        let actions = h_flex().gap(gap).children([("diagnostics-search", "magnifying_glass"), ("diagnostics-ai", "sparkle"), ("diagnostics-refresh", "refresh_title"), ("diagnostics-warnings", "warning")]
            .map(|(id, icon)| icon_button(id, icon, None, false, cx)));
        v_flex().track_focus(&self.focus).size_full().bg(theme.background).text_color(theme.foreground)
            .child(toolbar(cx).child(bar_row().justify_between()
                .child(icon_button("diagnostics-collapse", "chevron_down_up", None, false, cx)).child(actions)))
            .child(div().flex().flex_1().items_center().justify_center().text_color(theme.muted_foreground).child("No problems in workspace"))
    }
}

impl Workbench {
    pub(super) fn on_project_search(&mut self, _: &super::keymap::pane::DeploySearch, window: &mut Window, cx: &mut Context<Self>) {
        let Some(ws) = self.config_workspace(cx) else { return };
        self.open_tool(SEARCH, window, cx, |window, cx| {
            let owner = cx.entity().downgrade();
            let view = cx.new(|cx| SearchView::new(owner, ws, window, cx));
            let focus = view.read(cx).inputs[0].focus_handle(cx); (view.into(), focus)
        });
    }
    pub(super) fn on_diagnostics(&mut self, _: &super::keymap::diagnostics::Deploy, window: &mut Window, cx: &mut Context<Self>) {
        self.open_tool(DIAGNOSTICS, window, cx, |_, cx| {
            let view = cx.new(|cx| Diagnostics { focus: cx.focus_handle() });
            let focus = view.read(cx).focus.clone(); (view.into(), focus)
        });
    }
}

/// The result header's muted directory: relative to the folder root with a trailing `\` (empty for files in the root).
fn relative_directory(root: &std::path::Path, path: &std::path::Path) -> String {
    path.strip_prefix(root).ok().and_then(|p| p.parent()).map(|p| p.display().to_string()).filter(|p| !p.is_empty())
        .map(|p| format!("{p}\\")).unwrap_or_default()
}

#[cfg(test)]
mod tests {
    use super::relative_directory;
    use std::path::Path;

    #[test]
    fn k27_result_directory_is_relative() {
        let root = Path::new(r"D:\w\proj");
        assert_eq!(relative_directory(root, &root.join("specs").join("v0.1").join("INTENT.md")), r"specs\v0.1\");
        assert_eq!(relative_directory(root, &root.join("AGENTS.md")), "");
        assert_eq!(relative_directory(root, Path::new(r"E:\other\x.md")), "");
    }
}

use std::path::Path;

use gpui_kit::*;
use gpui_kit::component::{ActiveTheme as _, WindowExt as _, h_flex, v_flex};
use gpui_kit::component::button::{Button, ButtonVariants as _};
use gpui_kit::component::input::{EditorState, Input, InputEvent, InputState};
use gpui_kit::component::select::{Select, SelectState, SearchableVec};
use jsonc_parser::common::Ranged as _;
use serde_json::{Value, json};

use super::{Workbench, keymap, settings};
use super::metrics::keymap_editor as layout;

actions!(keymap_editor, [EditJson, Create]);

// An invalid Windows file path identifies the tool without ever entering Docs or disk I/O.
const TOOL_PATH: &str = "workbench://Keymap Editor";

#[derive(Clone, Debug)]
pub struct Row {
    pub action: String,
    pub arguments: Option<Value>,
    pub keys: String,
    pub context: String,
    pub user: bool,
}

impl Row {
    fn source(&self) -> &'static str { if self.user { "User" } else { "Default" } }
    fn label(&self) -> String { action_label(&self.action) }
    fn arguments_text(&self) -> String {
        if self.action == "<null>" { "<null>".into() }
        else { self.arguments.as_ref().map_or_else(|| "<no arguments>".into(), Value::to_string) }
    }
    fn context_text(&self) -> &str { if self.context.is_empty() { "<global>" } else { &self.context } }
    fn matches(&self, query: &str) -> bool {
        let names = format!("{} {}", self.label(), self.action).to_lowercase();
        query.split_whitespace().all(|term| names.contains(&term.to_lowercase()))
    }
}

fn action_label(name: &str) -> String {
    let mut out = String::new();
    let mut previous = None;
    for c in name.replace("::", ": ").chars() {
        if c.is_uppercase() && previous.is_some_and(|p: char| p.is_lowercase() || p.is_ascii_digit()) { out.push(' '); }
        out.extend(if c == '_' { ' ' } else { c }.to_lowercase());
        previous = Some(c);
    }
    out
}

fn keys_text(keys: &str) -> String {
    keys.split_whitespace().map(|key| Keystroke::parse_with_os(key, OperatingSystem::Windows).map(|key| {
        let m = key.modifiers;
        crate::keymap::display::stroke_text(&crate::keymap::display::Stroke {
            function: m.function, control: m.control, platform: m.platform, alt: m.alt, shift: m.shift, key: &key.key,
        })
    }).unwrap_or_else(|_| key.into())).collect::<Vec<_>>().join(" ")
}

pub(super) fn user_rows(text: &str) -> Result<Vec<Row>, String> {
    let text = text.trim_start_matches('\u{feff}');
    if text.trim().is_empty() { return Ok(vec![]); }
    let raw = jsonc_parser::parse_to_serde_value::<Value>(text, &crate::keymap::file::options()).map_err(|e| e.to_string())?;
    let mut rows = Vec::new();
    for section in raw.as_array().ok_or("Keymap must be an array")? {
        if let Some(bindings) = section.get("bindings").and_then(Value::as_object) {
            for (keys, action) in bindings {
                let (name, arguments) = match action {
                    Value::Null => ("<null>", None),
                    Value::String(name) => (name.as_str(), None),
                    Value::Array(parts) => (parts.first().and_then(Value::as_str).ok_or("Invalid action")?, Some(parts.get(1).cloned().unwrap_or(Value::Null))),
                    _ => return Err("Invalid action".into()),
                };
                rows.push(Row { action: name.into(), arguments, keys: keys.clone(), context: section.get("context").and_then(Value::as_str).unwrap_or_default().into(), user: true });
            }
        }
    }
    Ok(rows)
}

pub(super) fn read_snapshot(path: &Path) -> Result<Option<String>, String> {
    match std::fs::read_to_string(path) {
        Ok(text) => Ok(Some(text)),
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(None),
        Err(e) => Err(e.to_string()),
    }
}

fn save_binding(path: &Path, expected: Option<&str>, row: &Row, old: Option<&Row>) -> Result<(), String> {
    let current = read_snapshot(path)?;
    if current.as_deref() != expected { return Err("Keymap changed on disk. Reopen the binding before saving.".into()); }
    settings::write(path, &append_binding(current.as_deref().unwrap_or("[]"), row, old)?)
}

fn record_stroke(recorded: &mut Vec<String>, stroke: &str) -> bool {
    if recorded.len() >= layout::MAX_STROKES || matches!(stroke, "ctrl" | "shift" | "alt" | "win" | "fn") { return false; }
    recorded.push(stroke.into());
    true
}

struct BindingForm { editor: Entity<KeymapEditor> }

impl Render for BindingForm {
    fn render(&mut self, _: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        self.editor.update(cx, |this, cx| {
            let keys = keys_text(&this.keys.read(cx).value());
            let mut form = v_flex().gap(layout::MODAL_GAP)
                .child("Action")
                .child(Select::new(&this.action).accessibility_label("Action"))
                .child("Edit Keystroke")
                .child(h_flex().track_focus(&this.recorder_focus).gap(layout::TOP_GAP)
                    .child(if this.recording { format!("REC {keys}") } else if keys.is_empty() { "No keystrokes".into() } else { keys })
                    .child(Button::new("record-keybinding").label("Record")
                        .on_click(cx.listener(|this, _, window, cx| {
                            this.recorded.clear();
                            this.keys.update(cx, |input, cx| input.set_value("", window, cx));
                            this.recorder_focus.focus(window, cx);
                            this.recording = true;
                            cx.notify();
                        }))))
                .child("Edit Context")
                .child(Input::new(&this.context))
                .child(h_flex().gap(layout::FOOTER_GAP)
                    .child(Button::new("cancel-keybinding").label("Cancel").ghost().on_click(|_, window, cx| window.close_dialog(cx)))
                    .child(Button::new("save-keybinding").label("Save").on_click(cx.listener(|this, _, window, cx| this.save(window, cx)))));
            if let Some(error) = &this.error { form = form.child(error.clone()); }
            form
        })
    }
}

fn append_binding(text: &str, row: &Row, old: Option<&Row>) -> Result<String, String> {
    let bom = if text.starts_with('\u{feff}') { 3 } else { 0 };
    let body = &text[bom..];
    let body = if body.trim().is_empty() { "[]" } else { body };
    let parsed = jsonc_parser::parse_to_ast(body, &Default::default(), &crate::keymap::file::options()).map_err(|e| e.to_string())?;
    let array = parsed.value.as_ref().and_then(|v| v.as_array()).ok_or("Keymap must be an array")?;
    let mut sections = Vec::new();
    if let Some(old) = old.filter(|old| !old.keys.is_empty() && (old.keys != row.keys || old.context != row.context)) {
        sections.push(json!({"context": if old.context.is_empty() { None } else { Some(&old.context) }, "bindings": {old.keys.clone(): null}}));
    }
    let action = if row.action == "<null>" { Value::Null } else { json!(row.action) };
    sections.push(json!({"context": if row.context.is_empty() { None } else { Some(&row.context) }, "bindings": {row.keys.clone(): action}}));
    let addition = sections.iter().map(|s| serde_json::to_string_pretty(s).expect("JSON value")).collect::<Vec<_>>().join(",\n");
    let mut result = body.to_owned();
    let (offset, prefix) = array.elements.last().map_or((array.range.start + 1, "\n"), |v| (v.range().end, ",\n"));
    // shortcut: append overrides to preserve every existing byte; compact only on explicit user request.
    result.insert_str(offset, &format!("{prefix}{addition}\n"));
    if bom != 0 { result.insert(0, '\u{feff}'); }
    Ok(result)
}

pub struct KeymapEditor {
    filter: Entity<InputState>,
    action: Entity<SelectState<SearchableVec<SharedString>>>,
    keys: Entity<InputState>,
    context: Entity<InputState>,
    selected: Option<Row>,
    editing: bool,
    expected: Option<String>,
    recording: bool,
    recorded: Vec<String>,
    recorder_focus: FocusHandle,
    row_focus: Vec<FocusHandle>,
    error: Option<String>,
    owner: WeakEntity<Workbench>,
    _subscriptions: Vec<Subscription>,
}

impl KeymapEditor {
    fn new(owner: WeakEntity<Workbench>, window: &mut Window, cx: &mut Context<Self>) -> Self {
        let filter = cx.new(|cx| InputState::new(window, cx).placeholder("Filter action names…"));
        let mut names: Vec<SharedString> = cx.all_action_names().iter().map(|name| SharedString::from(*name)).collect();
        names.push("<null>".into());
        names.sort();
        let action = cx.new(|cx| SelectState::new(SearchableVec::new(names), None, window, cx).searchable(true));
        let keys = cx.new(|cx| InputState::new(window, cx).placeholder("Keystrokes (e.g. ctrl-alt-k)"));
        let context = cx.new(|cx| InputState::new(window, cx).placeholder("Context (empty = global)"));
        let mut subscriptions: Vec<_> = [&filter, &keys, &context].into_iter().map(|input| cx.subscribe(input, |_, _, _: &InputEvent, cx| cx.notify())).collect();
        let recorder_focus = cx.focus_handle();
        subscriptions.push(cx.on_blur(&recorder_focus, window, |this, _, cx| { this.recording = false; cx.notify(); }));
        let weak = cx.entity().downgrade();
        subscriptions.push(cx.intercept_keystrokes(move |event, window, cx| {
            let consumed = weak.update(cx, |this, cx| {
                if !this.recording || !this.recorder_focus.is_focused(window) { this.recording = false; return false; }
                let stroke = keymap::keystroke_notation(&event.keystroke);
                if record_stroke(&mut this.recorded, &stroke) {
                    let keys = this.recorded.join(" ");
                    this.keys.update(cx, |input, cx| input.set_value(keys, window, cx));
                    this.recording = this.recorded.len() < layout::MAX_STROKES;
                    cx.notify();
                }
                true
            }).unwrap_or(false);
            if consumed { cx.stop_propagation(); }
        }));
        Self { filter, action, keys, context, selected: None, editing: false, expected: None,
            recording: false, recorded: vec![], recorder_focus, row_focus: vec![], error: None, owner, _subscriptions: subscriptions }
    }

    fn edit(&mut self, row: Option<Row>, window: &mut Window, cx: &mut Context<Self>) {
        if self.editing { return; }
        if row.as_ref().is_some_and(|r| r.arguments.is_some()) {
            window.push_notification("Action arguments are not supported by this app. Edit this binding in JSON.", cx);
            return;
        }
        let snapshot = keymap::keymap_path().ok_or("Application data folder unavailable".into()).and_then(|path| read_snapshot(&path));
        match snapshot {
            Ok(text) => self.expected = text,
            Err(error) => { self.error = Some(error); cx.notify(); return; }
        }
        self.action.update(cx, |input, cx| {
            if let Some(row) = &row { input.set_selected_value(&SharedString::from(row.action.clone()), window, cx); }
            else { input.set_selected_index(None, window, cx); }
        });
        self.keys.update(cx, |input, cx| input.set_value(row.as_ref().map_or("", |r| &r.keys), window, cx));
        self.context.update(cx, |input, cx| input.set_value(row.as_ref().map_or("", |r| &r.context), window, cx));
        self.selected = row;
        self.editing = true;
        self.error = None;
        self.recording = false;
        let title = self.selected.as_ref().map_or_else(|| "Create Keybinding".into(), Row::label);
        let editor = cx.entity();
        let form = cx.new(|cx| {
            cx.observe(&editor, |_, _, cx| cx.notify()).detach();
            BindingForm { editor }
        });
        let weak = cx.entity().downgrade();
        window.open_dialog(cx, move |dialog, _, _| dialog.width(layout::MODAL_WIDTH).title(title.clone())
            .child(form.clone()).on_close({
                let weak = weak.clone();
                move |_, window, cx| { let _ = weak.update(cx, |this, cx| {
                    this.editing = false; this.recording = false; this.filter.focus_handle(cx).focus(window, cx); cx.notify();
                }); }
            }));
        self.action.focus_handle(cx).focus(window, cx);
        cx.notify();
    }

    fn save(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let row = Row { action: self.action.read(cx).selected_value().map(|v| v.to_string()).unwrap_or_default(), arguments: None, keys: self.keys.read(cx).value().trim().into(), context: self.context.read(cx).value().trim().into(), user: true };
        let result = (|| {
            let action: Box<dyn Action> = if row.action == "<null>" { Box::new(NoAction) } else { cx.build_action(&row.action, None).map_err(|e| e.to_string())? };
            if row.keys.is_empty() { return Err("Keystrokes are required".into()); }
            let predicate = if row.context.is_empty() { None } else { Some(std::rc::Rc::new(KeyBindingContextPredicate::parse(&row.context).map_err(|e| e.to_string())?)) };
            KeyBinding::load(&row.keys, action, predicate, false, None, cx).map_err(|e| e.to_string())?;
            let path = keymap::keymap_path().ok_or("Application data folder unavailable")?;
            save_binding(&path, self.expected.as_deref(), &row, self.selected.as_ref())?;
            Ok::<_, String>(())
        })();
        match result {
            Ok(()) => { self.editing = false; self.recording = false; self.error = None; window.close_dialog(cx); keymap::load(window, cx); }
            Err(error) => { window.push_notification(error.as_str(), cx); self.error = Some(error); }
        }
        cx.notify();
    }

    fn edit_json(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let result = self.owner.update(cx, |owner, cx| owner.open_keymap_json(window, cx)).map_err(|e| e.to_string()).and_then(|result| result);
        if let Err(error) = result { self.error = Some(error); }
        cx.notify();
    }
}

impl Render for KeymapEditor {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let query = self.filter.read(cx).value();
        let mut list = v_flex().id("keymap-rows").flex_1().min_h_0().overflow_y_scroll();
        let cells = |values: [String; 5]| h_flex().w_full().children(values.into_iter().zip(layout::COLUMN_RATIOS).map(|(value, ratio)| div().flex_basis(px(0.)).flex_grow(ratio).min_w_0().child(value)));
        list = list.child(h_flex().child(div().w(layout::EDIT_WIDTH).flex_shrink_0()).child(cells(["Action", "Arguments", "Keystrokes", "Context", "Source"].map(str::to_owned))));
        for (index, row) in keymap::editor_rows(cx).into_iter().filter(|row| row.matches(&query)).enumerate() {
            if self.row_focus.len() <= index { self.row_focus.push(cx.focus_handle().tab_index(0)); }
            let focus = self.row_focus[index].clone();
            let focused = focus.contains_focused(window, cx);
            let content = cells([row.label(), row.arguments_text(), keys_text(&row.keys), row.context_text().into(), row.source().into()]);
            let edit = row.clone();
            let enter = row.clone();
            list = list.child(h_flex().id(("keybinding", index)).group("keybinding-row").track_focus(&focus)
                .on_key_down(cx.listener(move |this, event: &KeyDownEvent, window, cx| {
                    if event.keystroke.key == "enter" { this.edit(Some(enter.clone()), window, cx); cx.stop_propagation(); }
                }))
                .on_click(cx.listener(move |this, event: &ClickEvent, window, cx| {
                    if event.click_count() == 2 { this.edit(Some(row.clone()), window, cx); }
                    else { focus.focus(window, cx); }
                }))
                .child(div().w(layout::EDIT_WIDTH).flex_shrink_0().child(div().opacity(if focused { 1. } else { 0. }).group_hover("keybinding-row", |style| style.opacity(1.))
                    .child(Button::new(("edit-binding", index)).w(layout::EDIT_SIZE).h(layout::EDIT_SIZE)
                        .icon(super::zed_icons::icon("pencil").size(super::metrics::ICON_SMALL)).ghost()
                        .on_click(cx.listener(move |this, _, window, cx| { this.edit(Some(edit.clone()), window, cx); cx.stop_propagation(); })))))
                .child(content));
        }
        let mut root = v_flex().size_full().p(layout::PADDING).gap(layout::GAP).key_context("KeymapEditor")
            .on_action(cx.listener(|this, _: &EditJson, window, cx| this.edit_json(window, cx)))
            .on_action(cx.listener(|this, _: &Create, window, cx| this.edit(None, window, cx)))
            .child(h_flex().gap(layout::TOP_GAP).child(div().flex_1().h(layout::SEARCH_HEIGHT).child(Input::new(&self.filter)))
                .child(Button::new("edit-keymap-json").label("Edit in JSON  Ctrl-E").ghost().on_click(cx.listener(|this, _, window, cx| this.edit_json(window, cx))))
                .child(Button::new("create-keybinding").label("Create Keybinding  Ctrl-K").on_click(cx.listener(|this, _, window, cx| this.edit(None, window, cx)))))
            .child(list);
        if let Some(error) = &self.error { root = root.child(error.clone()); }
        root.bg(cx.theme().background).text_color(cx.theme().foreground)
    }
}

impl Workbench {
    pub(super) fn on_open_keymap(&mut self, _: &keymap::zed::OpenKeymap, window: &mut Window, cx: &mut Context<Self>) {
        self.open_tool(TOOL_PATH, window, cx, |window, cx| {
            let owner = cx.entity().downgrade();
            let view = cx.new(|cx| KeymapEditor::new(owner, window, cx));
            let focus = view.read(cx).filter.focus_handle(cx);
            (view.into(), focus)
        });
    }

    pub(super) fn open_tool(&mut self, path: &str, window: &mut Window, cx: &mut Context<Self>, make: impl FnOnce(&mut Window, &mut Context<Self>) -> (AnyView, FocusHandle)) {
        // Keymap Editor belongs to the current workspace; Extensions keeps its existing cross-workspace lookup.
        let mut workspaces: Vec<_> = self.folders.workspaces.values().cloned().collect();
        if let Some(ws) = &self.settings_workspace { workspaces.push(ws.clone()); }
        if path == TOOL_PATH { workspaces = self.active_ws().into_iter().collect(); }
        for ws in workspaces {
            let found = ws.read(cx).group.find_source(Path::new(path), ws.read(cx).group.active);
            if let Some((pane, index)) = found {
                let folder = self.folders.workspaces.iter().find_map(|(id, w)| (w == &ws).then_some(id.clone()));
                if let Some(index) = self.folders.state.folders.iter().position(|f| Some(&f.id) == folder.as_ref()) {
                    self.activate_folder(index, window, cx);
                } else {
                    self.folders.state.active = None;
                    self.sync_watch("tool-tab", cx);
                }
                ws.update(cx, |ws, _| { ws.group.activate(pane); ws.group.panes.get_mut(&pane).unwrap().active = Some(index); });
                self.focus_active_pane(window, cx);
                cx.notify();
                return;
            }
        }
        let Some(ws) = self.config_workspace(cx) else { return };
        let (view, focus) = make(window, cx);
        let editor = cx.new(|cx| EditorState::new(window, cx));
        ws.update(cx, |ws, _| {
            let pane = ws.group.active;
            ws.group.panes.get_mut(&pane).unwrap().place(super::pane::Tab { path: path.into(), preview: false, markdown: false, editor, tool: Some((view, focus.clone())) }, false);
        });
        focus.focus(window, cx);
        cx.notify();
    }

    fn open_keymap_json(&mut self, window: &mut Window, cx: &mut Context<Self>) -> Result<(), String> {
        let path = keymap::keymap_path().ok_or("Application data folder unavailable")?;
        if !path.exists() { settings::write(&path, "[]\n")?; }
        if let Some(ws) = self.config_workspace(cx) {
            ws.update(cx, |ws, cx| { ws.group.open(&path, false, window, cx); });
            self.focus_active_pane(window, cx);
            cx.notify();
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::{Row, append_binding};

    #[test]
    fn k17_display_and_and_filter() {
        let rows = super::user_rows(r#"[{"bindings":{"ctrl-k ctrl-s":"pane::CloseActiveItem","ctrl-x":null,"ctrl-a":["test::Action",{"enabled":true}]}}]"#).unwrap();
        let row = rows.iter().find(|r| r.action == "pane::CloseActiveItem").unwrap();
        assert_eq!(row.label(), "pane: close active item");
        assert!(row.matches("CLOSE pane"));
        assert!(row.matches("pane::CloseActiveItem active"));
        assert!(!row.matches("pane missing"));
        assert!(row.matches(" \t "));
        assert_eq!(row.arguments_text(), "<no arguments>");
        assert_eq!(row.context_text(), "<global>");
        assert_eq!(super::keys_text(&row.keys), "Ctrl-K Ctrl-S");
        assert_eq!(rows.iter().find(|r| r.action == "<null>").unwrap().arguments_text(), "<null>");
        assert_eq!(rows.iter().find(|r| r.action == "test::Action").unwrap().arguments_text(), r#"{"enabled":true}"#);
        assert_eq!(super::action_label("multi_workspace::ToggleWorkspaceSidebar"), "multi workspace: toggle workspace sidebar");
    }

    #[test]
    fn k17_recording_stops_at_three_strokes() {
        let mut strokes = Vec::new();
        assert!(!super::record_stroke(&mut strokes, "ctrl"));
        for stroke in ["ctrl-k", "ctrl-s", "enter"] { assert!(super::record_stroke(&mut strokes, stroke)); }
        assert!(!super::record_stroke(&mut strokes, "escape"));
        assert_eq!(strokes, ["ctrl-k", "ctrl-s", "enter"]);
    }

    #[test]
    fn k17_save_refuses_changed_created_or_deleted_files() {
        let dir = std::env::temp_dir().join(format!("workbench-k17-{}", crate::state::win::new_uuid()));
        let path = dir.join("keymap.json");
        std::fs::create_dir_all(&dir).unwrap();
        let row = Row { action: "workspace::Save".into(), arguments: None, keys: "ctrl-alt-s".into(), context: String::new(), user: true };
        assert_eq!(super::read_snapshot(&path).unwrap(), None);
        std::fs::write(&path, "[] // external edit").unwrap();
        assert!(super::save_binding(&path, None, &row, None).is_err());
        assert!(super::save_binding(&path, Some("[]"), &row, None).is_err());
        assert_eq!(std::fs::read_to_string(&path).unwrap(), "[] // external edit");
        std::fs::remove_file(&path).unwrap();
        assert!(super::save_binding(&path, Some("[]"), &row, None).is_err());
        assert!(!path.exists());
        super::save_binding(&path, None, &row, None).unwrap();
        let snapshot = super::read_snapshot(&path).unwrap().unwrap();
        let null = Row { action: "<null>".into(), ..row.clone() };
        super::save_binding(&path, Some(&snapshot), &null, Some(&row)).unwrap();
        let parsed = crate::keymap::file::read(&path, &crate::keymap::is_known_action);
        assert!(parsed.errors().is_empty());
        assert_eq!(parsed.bindings().last().unwrap().action, None);
        std::fs::remove_dir_all(dir).unwrap();
    }

    #[test]
    fn filter_and_sources() {
        let mut row = Row { action: "workspace::Save".into(), arguments: None, keys: "ctrl-s".into(), context: "Workspace".into(), user: false };
        assert!(row.matches("SAVE"));
        assert!(!row.matches("ctrl-s"));
        assert_eq!(row.source(), "Default");
        row.user = true;
        assert_eq!(row.source(), "User");
    }

    #[test]
    fn save_and_reload_preserve_comments_and_disable_old_key() {
        let old = Row { action: "workspace::Save".into(), arguments: None, keys: "ctrl-s".into(), context: "Workspace".into(), user: false };
        let new = Row { keys: "ctrl-alt-s".into(), user: true, ..old.clone() };
        for original in ["[]", "// comment\n[ /* keep */ ]", "\u{feff}[{\"bindings\":{\"ctrl-q\":\"zed::Quit\"}}, // keep\n]"] {
            let text = append_binding(original, &new, Some(&old)).unwrap();
            assert!(text.contains("keep") || !original.contains("keep"));
            let parsed = crate::keymap::file::parse(&text, &crate::keymap::is_known_action);
            assert!(parsed.errors().is_empty(), "{:?}", parsed.errors());
            let bindings = parsed.bindings();
            assert_eq!(bindings[bindings.len()-2].action, None);
            assert_eq!(bindings.last().unwrap().keys, "ctrl-alt-s");
            assert_eq!(bindings.last().unwrap().action.as_deref(), Some("workspace::Save"));
        }
        assert!(append_binding("{ broken", &new, None).is_err());
        assert!(append_binding("{}", &new, None).is_err());
        assert!(append_binding("[{'bindings': {}}]", &new, None).is_err());
        let dir = std::env::temp_dir().join(format!("workbench-k14-{}", crate::state::win::new_uuid()));
        let path = dir.join("keymap.json");
        let original = "// keep header\n[{\"bindings\":{\"ctrl-q\":\"zed::Quit\"}}, // keep tail\n]\n";
        let updated = append_binding(original, &new, Some(&old)).unwrap();
        assert!(updated.starts_with("// keep header\n[{\"bindings\":{\"ctrl-q\":\"zed::Quit\"}}"));
        assert!(updated.ends_with(", // keep tail\n]\n"));
        super::settings::write(&path, &updated).unwrap();
        assert_eq!(std::fs::read_to_string(&path).unwrap(), updated);
        let parsed = crate::keymap::file::read(&path, &crate::keymap::is_known_action);
        assert!(parsed.errors().is_empty());
        assert_eq!(parsed.bindings().last().unwrap().keys, new.keys);
        std::fs::remove_dir_all(dir).unwrap();
    }
}

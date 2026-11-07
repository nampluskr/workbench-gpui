//! "Select Theme…" and "Select Icon Theme…" modals (K-20, core ORDER-07 I-3·I-4).
//!
//! Moving the selection previews it, Enter or a click applies it and saves it to settings.json, and
//! closing any other way (Esc, backdrop, Install link) puts the original back. Restoring runs when the
//! view is released, so every close path of the dialog is covered.

use gpui_kit::*;
use gpui_kit::component::{ActiveTheme as _, WindowExt as _, v_flex};
use gpui_kit::component::button::{Button, ButtonVariants as _};
use gpui_kit::component::input::{Input, InputEvent, InputState};
use gpui_kit::prelude::FluentBuilder as _;

use super::keymap::{self, menu as menu_actions};
use super::{Workbench, extensions, menu_common, metrics::selector as layout, settings};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Kind { Theme, IconTheme }

impl Kind {
    fn key(self) -> &'static str {
        match self { Self::Theme => "theme", Self::IconTheme => "icon_theme" }
    }
    fn names(self) -> Vec<String> {
        match self { Self::Theme => super::theme::names(), Self::IconTheme => super::icon_theme::names() }
    }
    fn placeholder(self) -> &'static str {
        match self { Self::Theme => "Select a theme…", Self::IconTheme => "Select an icon theme…" }
    }
    fn install(self) -> &'static str {
        match self { Self::Theme => "Install Themes", Self::IconTheme => "Install Icon Themes" }
    }
}

/// Names containing every whitespace-separated word of `query`, case-insensitive, in list order.
fn matching(names: &[String], query: &str) -> Vec<String> {
    let words: Vec<_> = query.split_whitespace().map(str::to_lowercase).collect();
    names.iter().filter(|name| { let name = name.to_lowercase(); words.iter().all(|word| name.contains(word)) }).cloned().collect()
}

/// Selection after moving `delta` rows, wrapping at both ends.
fn stepped(selected: usize, len: usize, delta: isize) -> usize {
    (selected as isize + delta).rem_euclid(len as isize) as usize
}

struct Selector {
    kind: Kind,
    search: Entity<InputState>,
    names: Vec<String>,
    shown: Vec<String>,
    selected: usize,
    original: String,
    /// Set once the choice is applied or the original restored; later close paths do nothing.
    done: bool,
    scroll: ScrollHandle,
    _subscriptions: Vec<Subscription>,
}

impl Selector {
    fn new(kind: Kind, window: &mut Window, cx: &mut Context<Self>) -> Self {
        let original = settings::current(kind.key(), cx);
        let names = kind.names();
        let selected = names.iter().position(|name| *name == original).unwrap_or(0);
        let search = cx.new(|cx| InputState::new(window, cx).placeholder(kind.placeholder()));
        let scroll = ScrollHandle::new();
        scroll.scroll_to_item(selected);
        let subscriptions = vec![
            cx.subscribe_in(&search, window, |this, search, event: &InputEvent, window, cx| match event {
                InputEvent::Change => {
                    this.shown = matching(&this.names, &search.read(cx).value());
                    this.selected = 0;
                    this.preview(cx);
                    cx.notify();
                }
                InputEvent::PressEnter { .. } => this.confirm(window, cx),
                _ => {}
            }),
            cx.on_release(|this, cx| this.restore(cx)),
        ];
        Self { kind, search, shown: names.clone(), names, selected, original, done: false, scroll, _subscriptions: subscriptions }
    }

    fn preview(&self, cx: &mut App) {
        if let Some(name) = self.shown.get(self.selected) { settings::preview(self.kind.key(), name, cx); }
    }

    fn restore(&mut self, cx: &mut App) {
        if !self.done {
            self.done = true;
            settings::preview(self.kind.key(), &self.original, cx);
        }
    }

    fn step(&mut self, delta: isize, cx: &mut Context<Self>) {
        if self.shown.is_empty() { return; }
        self.selected = stepped(self.selected, self.shown.len(), delta);
        self.scroll.scroll_to_item(self.selected);
        self.preview(cx);
        cx.notify();
    }

    fn confirm(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        if self.done { return; }
        let Some(name) = self.shown.get(self.selected).cloned() else { return };
        self.done = true;
        if let Err(error) = settings::choose(self.kind.key(), &name, cx) {
            settings::preview(self.kind.key(), &self.original, cx);
            window.push_notification(error.as_str(), cx);
        }
        window.close_dialog(cx);
    }

    fn cancel(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        self.restore(cx);
        window.close_dialog(cx);
    }

    fn install(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        self.restore(cx);
        extensions::request_category(self.kind == Kind::IconTheme, cx);
        window.close_dialog(cx);
        window.dispatch_action(Box::new(keymap::zed::Extensions), cx);
    }
}

impl Render for Selector {
    fn render(&mut self, _: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let theme = cx.theme();
        let (hover, border, muted) = (theme.secondary_hover, theme.border, theme.muted_foreground);
        let mut list = v_flex().id("selector-list").track_scroll(&self.scroll).max_h(layout::LIST_MAX_HEIGHT).overflow_y_scroll();
        for (i, name) in self.shown.iter().enumerate() {
            list = list.child(menu_common::row(("selector-item", i))
                .h(layout::ROW_HEIGHT).flex_shrink_0()
                .when(i == self.selected, |row| row.bg(hover))
                .on_click(cx.listener(move |this, _, window, cx| { this.selected = i; this.confirm(window, cx); }))
                .child(name.clone())
                .child(menu_common::shortcut_cell().child(if *name == self.original { "✓" } else { "" })));
        }
        if self.shown.is_empty() { list = list.child(div().px(layout::GAP).text_color(muted).child("No matches")); }
        v_flex().key_context(crate::keymap::builtin::MENU_CONTEXT).gap(layout::GAP)
            .on_action(cx.listener(|this, _: &menu_actions::SelectNext, _, cx| this.step(1, cx)))
            .on_action(cx.listener(|this, _: &menu_actions::SelectPrevious, _, cx| this.step(-1, cx)))
            .on_action(cx.listener(|this, _: &menu_actions::Confirm, window, cx| this.confirm(window, cx)))
            .on_action(cx.listener(|this, _: &menu_actions::Cancel, window, cx| this.cancel(window, cx)))
            .child(Styled::h(Input::new(&self.search), layout::SEARCH_HEIGHT))
            .child(list.relative().child(div().absolute().inset_0().child(
                gpui_kit::base::Scrollbar::vertical(&self.scroll)
                    .mode(gpui_kit::base::ScrollbarMode::Hover).viewport_from_layout())))
            .child(div().h(layout::SEPARATOR_HEIGHT).flex_shrink_0().w_full().bg(border))
            .child(Button::new("selector-install").label(self.kind.install()).ghost()
                .h(layout::FOOTER_HEIGHT).flex_shrink_0()
                .on_click(cx.listener(|this, _, window, cx| this.install(window, cx))))
    }
}

impl Workbench {
    pub(super) fn on_toggle_theme_selector(&mut self, _: &keymap::theme_selector::Toggle, window: &mut Window, cx: &mut Context<Self>) {
        Self::open_selector(Kind::Theme, window, cx);
    }

    pub(super) fn on_toggle_icon_theme_selector(&mut self, _: &keymap::icon_theme_selector::Toggle, window: &mut Window, cx: &mut Context<Self>) {
        Self::open_selector(Kind::IconTheme, window, cx);
    }

    fn open_selector(kind: Kind, window: &mut Window, cx: &mut Context<Self>) {
        if window.has_active_dialog(cx) { return; }
        let view = cx.new(|cx| Selector::new(kind, window, cx));
        let focus = view.read(cx).search.focus_handle(cx);
        window.open_dialog(cx, move |dialog, _, _| dialog.width(layout::MODAL_WIDTH).p_0().gap_0().child(view.clone()));
        focus.focus(window, cx);
    }
}

#[cfg(test)]
mod tests {
    use super::{Kind, matching, settings, stepped};

    #[test]
    fn k21_selector_dimensions_match_zed_measure_order07() {
        use super::layout;
        use gpui_kit::px;
        assert_eq!([layout::MODAL_WIDTH, layout::SEARCH_HEIGHT, layout::LIST_MAX_HEIGHT,
            layout::ROW_HEIGHT, layout::GAP, layout::SEPARATOR_HEIGHT, layout::FOOTER_HEIGHT],
            [px(544.), px(38.), px(384.), px(32.), px(0.), px(1.), px(38.)]);
        assert_eq!(layout::LIST_MAX_HEIGHT, layout::ROW_HEIGHT * 12.);
    }

    #[test]
    fn k20_matching_is_case_insensitive_word_and_keeps_order() {
        let names: Vec<String> = ["One Dark", "One Light", "Ayu Dark", "Catppuccin Mocha"].map(String::from).into();
        assert_eq!(matching(&names, ""), names);
        assert_eq!(matching(&names, "  DARK "), ["One Dark", "Ayu Dark"]);
        assert_eq!(matching(&names, "one  dark"), ["One Dark"]);
        assert!(matching(&names, "zzz").is_empty());
    }

    #[test]
    fn k20_selection_wraps_both_ways() {
        assert_eq!([stepped(0, 3, 1), stepped(2, 3, 1), stepped(0, 3, -1), stepped(1, 3, -1)], [1, 0, 2, 0]);
    }

    #[test]
    fn k20_kinds_use_settings_keys_and_catalog_names() {
        assert_eq!((Kind::Theme.key(), Kind::IconTheme.key()), ("theme", "icon_theme"));
        assert!(Kind::Theme.names().contains(&settings::THEME.to_owned()));
        assert_eq!(Kind::IconTheme.names()[0], settings::ICON_THEME);
        assert!(Kind::IconTheme.names().iter().any(|name| name == "Catppuccin Mocha"));
    }
}

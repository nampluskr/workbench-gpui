//! Tab input of a pane: a press on a tab, pin and unpin (v0.4 P4-2, R-12; 02-INTERACTION `I-063`, `I-065`, `I-066`,
//! `I-075`, `L-66`, `L-74`). The model is `pane::Pane` (impl-editor); `layout::tab_press` judges the press.

use gpui_kit::*;

use super::Workbench;
use super::context_menu::{CmEntry, ContextMenu, ContextMenuEvent};
use super::pane_view::OpenMenu;
use super::keymap::{self, pane as pane_actions};
use super::layout::TabPress;
use super::pane_group::PaneId;

/// Where the keyboard goes for the active pane: its editor, or the center area for an empty pane and a preview.
#[derive(Debug, PartialEq, Eq)]
pub enum FocusTarget {
    Editor,
    Center,
}

/// `markdown`: the active tab is a Markdown preview; `None`: the pane has no tab.
pub fn focus_target(active_is_markdown: Option<bool>) -> FocusTarget {
    match active_is_markdown {
        Some(false) => FocusTarget::Editor,
        _ => FocusTarget::Center,
    }
}

/// The context menu entry of a tab (Zed: "Pin Tab" / "Unpin Tab").
pub fn pin_menu_label(pinned: bool) -> &'static str {
    if pinned { "Unpin Tab" } else { "Pin Tab" }
}

fn cycle_tab_index(active: Option<usize>, count: usize, forward: bool) -> Option<usize> {
    let active = active.filter(|&i| count > 1 && i < count)?;
    Some(if forward {
        if active + 1 == count { 0 } else { active + 1 }
    } else if active == 0 {
        count - 1
    } else {
        active - 1
    })
}

impl Workbench {
    fn cycle_tab(&mut self, forward: bool, window: &mut Window, cx: &mut Context<Self>) {
        let Some(ws) = self.active_ws() else { return };
        let group = &ws.read(cx).group;
        let pane = group.active_pane();
        if let Some(index) = cycle_tab_index(pane.active, pane.tabs.len(), forward) {
            self.on_tab_press(group.active, index, TabPress::Activate, window, cx);
        }
    }

    pub(super) fn on_activate_previous_item(&mut self, action: &pane_actions::ActivatePreviousItem, window: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(action, self.focus_name(window, cx), cx);
        self.cycle_tab(false, window, cx);
    }

    pub(super) fn on_activate_next_item(&mut self, action: &pane_actions::ActivateNextItem, window: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(action, self.focus_name(window, cx), cx);
        self.cycle_tab(true, window, cx);
    }

    /// Keyboard focus to the active pane's active editor, else the center area.
    pub(super) fn focus_active_pane(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        // A Markdown preview tab shows no editor, so the center area keeps the keys (its editor is hidden).
        let active = self.active_ws().and_then(|ws| ws.read(cx).group.active_tab().map(|t| (t.markdown, t.editor.focus_handle(cx))));
        match (focus_target(active.as_ref().map(|a| a.0)), active) {
            (FocusTarget::Editor, Some((_, h))) => h.focus(window, cx),
            _ => self.center_focus.focus(window, cx),
        }
    }

    /// A press on tab `ix` of pane `pane` (`layout::tab_press`): activate it, a double-click also makes it a normal
    /// tab (I-063); a middle click closes it with the save question unless pinned (I-066, I-075).
    pub(super) fn on_tab_press(&mut self, pane: PaneId, ix: usize, press: TabPress, window: &mut Window, cx: &mut Context<Self>) {
        match press {
            TabPress::Ignore => {}
            TabPress::Close => self.close_tab_at(pane, ix, window, cx),
            TabPress::Activate | TabPress::Promote => {
                let Some(ws) = self.active_ws() else { return };
                ws.update(cx, |ws, _| {
                    ws.group.activate(pane);
                    if let Some(p) = ws.group.panes.get_mut(&pane).filter(|p| ix < p.tabs.len()) {
                        p.active = Some(ix);
                        if press == TabPress::Promote {
                            p.promote(ix);
                        }
                    }
                });
                self.focus_active_pane(window, cx);
                cx.notify();
            }
        }
    }

    /// Pin or unpin tab `ix` of pane `pane` (I-065); the pin icon of a pinned tab calls this too (L-66).
    pub(super) fn toggle_pin_at(&mut self, pane: PaneId, ix: usize, window: &mut Window, cx: &mut Context<Self>) {
        let Some(ws) = self.active_ws() else { return };
        ws.update(cx, |ws, _| {
            ws.group.activate(pane);
            if let Some(p) = ws.group.panes.get_mut(&pane) {
                p.toggle_pin(ix);
            }
        });
        self.focus_active_pane(window, cx);
        cx.notify();
    }

    /// The right-click menu of tab `ix` in pane `pane` (P4-2): Pin Tab / Unpin Tab for that tab, whichever is active.
    /// The menu restores the focus it found when it closes.
    pub(super) fn open_tab_menu(&mut self, pane: PaneId, ix: usize, position: Point<Pixels>, window: &mut Window, cx: &mut Context<Self>) {
        let Some(ws) = self.active_ws() else { return };
        let Some(pinned) = ws.read(cx).group.panes.get(&pane).filter(|p| ix < p.tabs.len()).map(|p| p.is_pinned(ix)) else { return };
        let focus = window.focused(cx);
        let shortcut = keymap::shortcut_for_name("pane::TogglePinTab", focus.as_ref(), window, cx);
        let entries = vec![CmEntry::with_shortcut(pin_menu_label(pinned), true, shortcut)];
        let menu = cx.new(|cx| ContextMenu::new(entries, Vec::new(), position, window, cx));
        let sub = cx.subscribe_in(&menu, window, move |this, menu, event: &ContextMenuEvent, window, cx| {
            if !this.tab_menu.as_ref().is_some_and(|m| m.menu == *menu) {
                return;
            }
            match event {
                ContextMenuEvent::Dismissed => {
                    let menu = menu.clone();
                    cx.defer_in(window, move |this, _, cx| {
                        if this.tab_menu.as_ref().is_some_and(|m| m.menu == menu) {
                            this.tab_menu = None;
                            cx.notify();
                        }
                    });
                }
                ContextMenuEvent::Chosen(_) => this.toggle_pin_at(pane, ix, window, cx),
            }
        });
        self.tab_menu = Some(OpenMenu::new(menu, sub));
        cx.notify();
    }

    /// `pane::TogglePinTab` (Ctrl+K Shift+Enter, I-065).
    pub(super) fn on_toggle_pin_tab(&mut self, action: &pane_actions::TogglePinTab, window: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(action, self.focus_name(window, cx), cx);
        let Some(ws) = self.active_ws() else { return };
        let group = &ws.read(cx).group;
        if let Some(ix) = group.active_pane().active {
            let pane = group.active;
            self.toggle_pin_at(pane, ix, window, cx);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::{FocusTarget, focus_target, pin_menu_label};

    #[test]
    fn k10_cycles_tabs_in_both_directions() {
        assert_eq!(super::cycle_tab_index(Some(2), 3, true), Some(0));
        assert_eq!(super::cycle_tab_index(Some(0), 3, false), Some(2));
        assert_eq!(super::cycle_tab_index(Some(1), 3, true), Some(2));
        assert_eq!(super::cycle_tab_index(Some(1), 3, false), Some(0));
        for forward in [false, true] {
            assert_eq!(super::cycle_tab_index(Some(0), 1, forward), None);
            assert_eq!(super::cycle_tab_index(None, 0, forward), None);
            assert_eq!(super::cycle_tab_index(Some(3), 3, forward), None);
        }
    }

    /// A press outside the editor body hands the keyboard to the pane: its editor, or the center area when the pane
    /// is empty or shows a preview (no editor to focus), so typing, Save and Close share one target.
    #[test]
    fn focus_target_of_a_pane() {
        assert_eq!(focus_target(Some(false)), FocusTarget::Editor);
        assert_eq!(focus_target(Some(true)), FocusTarget::Center);
        assert_eq!(focus_target(None), FocusTarget::Center);
    }

    /// The tab menu names the action the tab can take.
    #[test]
    fn tab_menu_label_follows_pin_state() {
        assert_eq!(pin_menu_label(false), "Pin Tab");
        assert_eq!(pin_menu_label(true), "Unpin Tab");
    }
}

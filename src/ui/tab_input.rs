//! Tab input of a pane: a press on a tab, pin and unpin (v0.4 P4-2, R-12; 02-INTERACTION `I-063`, `I-065`, `I-066`,
//! `I-075`, `L-66`, `L-74`). The model is `pane::Pane` (impl-editor); `layout::tab_press` judges the press.

use gpui_kit::*;

use super::Workbench;
use super::keymap::{self, pane as pane_actions};
use super::layout::TabPress;
use super::pane_group::PaneId;

impl Workbench {

    /// Keyboard focus to the active pane's active editor, else the center area.
    pub(super) fn focus_active_pane(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let handle = self.active_ws().and_then(|ws| ws.read(cx).group.active_tab().map(|t| t.editor.focus_handle(cx)));
        match handle {
            Some(h) => h.focus(window, cx),
            None => self.center_focus.focus(window, cx),
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

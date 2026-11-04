//! Tab drag and drop (v0.4 P4-4, R-13, D-7; 02-INTERACTION `I-074`, `I-712~I-722`). Dragging a tab reorders it,
//! moves it to another pane, or splits a pane when dropped on a body edge; Ctrl copies instead of moving (I-718).
//! The judging functions are `pane_group::drop_split` and `drop_overlay`; the model moves are `PaneGroup::move_tab`,
//! `drop_center`, `drop_split` and `copy_tab_view`.

use gpui_kit::*;

use super::Workbench;
use super::layout::TabDrag;
use super::pane_group::{PaneId, SplitDirection, drop_split};

/// Where a tab drag over a pane body would land right now, for the overlay (I-714) and the drop.
#[derive(Clone, Copy, Debug, PartialEq)]
pub struct DropHint {
    pub pane: PaneId,
    /// `None` is the centre; a direction splits.
    pub dir: Option<SplitDirection>,
    /// Body size, px.
    pub w: f32,
    pub h: f32,
}

/// I-712, I-713: the hint for a pointer at (`x`, `y`) in a `w` × `h` body of pane `pane`. A pane may split unless the
/// drag is its own only tab (splitting would just empty it).
pub fn body_hint(pane: PaneId, from: PaneId, tabs: usize, w: f32, h: f32, x: f32, y: f32) -> DropHint {
    let can_split = !(from == pane && tabs <= 1);
    DropHint { pane, dir: drop_split(w, h, x, y, can_split), w, h }
}

impl Workbench {
    /// The pointer moves over the body of `pane` (`inside`: within its bounds) during a tab drag.
    pub(super) fn set_drop_hint(&mut self, pane: PaneId, hint: Option<DropHint>, cx: &mut Context<Self>) {
        let next = hint.or_else(|| self.drop_hint.filter(|h| h.pane != pane));
        if self.drop_hint != next {
            self.drop_hint = next;
            cx.notify();
        }
    }

    /// I-715, I-716: a drop on tab `at` of pane `to`, or on the tab-bar end (`at` = the tab count). Within a pane it
    /// reorders; into another pane it moves the tab there, or with Ctrl copies it (I-718).
    pub(super) fn drop_tab_at(&mut self, d: &TabDrag, to: PaneId, at: usize, window: &mut Window, cx: &mut Context<Self>) {
        let Some(ws) = self.active_ws() else { return };
        let copy = window.modifiers().control;
        ws.update(cx, |ws, cx| {
            let g = &mut ws.group;
            match copy.then(|| g.clone_view(d.pane, d.ix, window, cx)).flatten() {
                Some(editor) if d.pane != to => g.copy_tab_view(d.pane, d.ix, to, at, editor),
                _ => g.move_tab(d.pane, d.ix, to, at),
            }
        });
        self.after_drop(cx, window);
    }

    /// I-717: a drop on the body of pane `target`, where the last move over it said: centre → into the pane (a drop on
    /// its own pane's centre changes nothing); an edge → a new pane there gets the tab, a copy of it with Ctrl.
    pub(super) fn drop_on_body(&mut self, d: &TabDrag, target: PaneId, window: &mut Window, cx: &mut Context<Self>) {
        let Some(ws) = self.active_ws() else { return };
        let dir = self.drop_hint.filter(|h| h.pane == target).and_then(|h| h.dir);
        let copy = window.modifiers().control;
        ws.update(cx, |ws, cx| {
            let g = &mut ws.group;
            match dir {
                Some(dir) => {
                    let editor = copy.then(|| g.clone_view(d.pane, d.ix, window, cx)).flatten();
                    g.drop_split(d.pane, d.ix, target, dir, editor);
                }
                None if d.pane != target => match copy.then(|| g.clone_view(d.pane, d.ix, window, cx)).flatten() {
                    Some(editor) => {
                        let at = g.panes.get(&target).map_or(0, |p| p.active.map_or(p.tabs.len(), |a| a + 1));
                        g.copy_tab_view(d.pane, d.ix, target, at, editor);
                    }
                    None => g.drop_center(d.pane, d.ix, target),
                },
                None => {}
            }
        });
        self.after_drop(cx, window);
    }

    fn after_drop(&mut self, cx: &mut Context<Self>, window: &mut Window) {
        self.drop_hint = None;
        self.focus_active_pane(window, cx);
        cx.notify();
    }
}

#[cfg(test)]
mod tests {
    use super::body_hint;
    use crate::ui::pane_group::{SplitDirection, drop_overlay};

    /// I-712~I-714: an 800×600 body takes edges within 120px (min × 0.2); the overlay covers half on the split side.
    #[test]
    fn body_hint_edges_and_overlay() {
        let h = body_hint(1, 0, 3, 800., 600., 50., 300.);
        assert_eq!(h.dir, Some(SplitDirection::Left));
        let r = drop_overlay(h.w, h.h, h.dir);
        assert_eq!((r.x, r.y, r.w, r.h), (0., 0., 400., 600.));
        assert_eq!(body_hint(1, 0, 3, 800., 600., 400., 300.).dir, None, "centre");
        assert_eq!(body_hint(1, 0, 3, 800., 600., 120., 300.).dir, None, "boundary is centre");
        assert_eq!(body_hint(1, 0, 3, 800., 600., 400., 580.).dir, Some(SplitDirection::Down));
    }

    /// Dragging the only tab of a pane over its own edge cannot split it; with two tabs it can; other panes always can.
    #[test]
    fn own_single_tab_cannot_split() {
        assert_eq!(body_hint(0, 0, 1, 800., 600., 10., 300.).dir, None);
        assert_eq!(body_hint(0, 0, 2, 800., 600., 10., 300.).dir, Some(SplitDirection::Left));
        assert_eq!(body_hint(2, 0, 1, 800., 600., 10., 300.).dir, Some(SplitDirection::Left));
    }
}

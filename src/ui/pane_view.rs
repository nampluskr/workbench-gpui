//! Drawing of a workspace's pane tree and its mouse and key handlers (v0.4 P4-2, P4-3b; R-12, R-13, D-7;
//! 02-INTERACTION `I-060~I-066`, `I-706~I-739`).
//!
//! The model is `pane_group::PaneGroup` (impl-editor). Here: one tab bar and one body per pane (`pane_el`), flex
//! shares as `flex_grow` (child length = axis length × flex ÷ count, I-724), the divider line with its mouse area and
//! drag (I-725~I-727), the zoomed pane (I-730), the split popup (I-706, I-707) and the actions of I-065, I-731,
//! I-732 and I-737. Judging functions are plain and tested (H-9).

use std::rc::Rc;

use gpui_kit::component::{ActiveTheme as _, InteractiveElementExt as _, v_flex};
use gpui_kit::prelude::FluentBuilder as _;
use gpui_kit::*;

use super::Workbench;
use super::context_menu::{CmEntry, ContextMenu, ContextMenuEvent};
use super::keymap::{self, pane as pane_actions, workspace as ws_actions};
use super::layout::{self, BarEnd, TabDrag, TabPress, TabView};
use super::layout_probe::probe;
use super::pane::editor_view;
use super::pane::DividerSides;
use super::pane_group::{Axis, Node, PaneGroup, PaneId, Rect, SPLIT_LINE_HITBOX, SPLIT_LINE_THICKNESS, SplitDirection, SplitMode, drop_overlay};
use super::markdown_preview::{self, file_name, preview_title};
use super::pane::Tab;
use super::panel_menu::is_markdown;
use super::tab_drag::body_hint;

/// L-17 zoomed pane: 8px around it (`pane["zoomed_padding"]`) and a 1px border (`pane["zoomed_border"]`).
const ZOOMED_PADDING: Pixels = px(8.);

/// An open popup (the split popup of I-706 or a tab menu) with the subscription that hears its choice.
pub struct OpenMenu {
    pub menu: Entity<ContextMenu>,
    _sub: Subscription,
}

impl OpenMenu {
    pub fn new(menu: Entity<ContextMenu>, sub: Subscription) -> Self {
        Self { menu, _sub: sub }
    }
}

/// A divider being dragged: the axis (child indices from the root) and the divider's index in it (between children
/// `ix` and `ix + 1`). Nothing is drawn for the drag itself.
#[derive(Clone)]
struct DividerDrag {
    path: Vec<usize>,
    ix: usize,
}

impl Render for DividerDrag {
    fn render(&mut self, _: &mut Window, _: &mut Context<Self>) -> impl IntoElement {
        div()
    }
}

/// I-706: the end buttons belong to the pane that has focus; a workspace with a single pane (the first screen has
/// one) has only the active one.
fn end_buttons_shown(active: bool, only_pane: bool) -> bool {
    active || only_pane
}

/// The end buttons of the first screen (no folder): split is off (I-707, nothing to split), zoom does nothing.
fn first_screen_end() -> BarEnd {
    BarEnd { split_enabled: false, zoomed: false, on_split: Rc::new(|_, _, _| {}), on_zoom: Rc::new(|_, _, _| {}) }
}

/// The title a tab shows: the file name, or "Preview {name}" for a Markdown preview (L-69).
fn tab_title<E>(t: &Tab<E>) -> String {
    if t.markdown { preview_title(&file_name(&t.path)) } else { t.title() }
}

/// The flexes of the axis at `path` (child indices from `root`).
fn flexes_at<'a>(root: &'a Node, path: &[usize]) -> Option<&'a [f32]> {
    match (root, path) {
        (Node::Axis { flexes, .. }, []) => Some(flexes),
        (Node::Axis { children, .. }, [i, rest @ ..]) => flexes_at(children.get(*i)?, rest),
        _ => None,
    }
}

/// I-726: how far divider `ix` must move so it sits under the pointer, `offset` px from the axis start, on an axis
/// `len` px long. The divider is where the first `ix + 1` children end (I-724 lengths). Computed from the live flexes
/// each move, so a divider held back by a minimum size does not drift away from the pointer.
fn divider_delta(flexes: &[f32], ix: usize, offset: f32, len: f32) -> f32 {
    let before: f32 = flexes.iter().take(ix + 1).sum();
    offset - len * before / flexes.len() as f32
}

/// Where the divider line starts: the middle of its mouse area (`start` + `hit` / 2, I-725) on a whole logical px.
/// A fractional boundary (the flex shares after a drag) would put the 1px line across two pixels.
fn line_start(start: f32, hit: f32) -> f32 {
    (start + hit / 2.).round()
}

/// Which edges of a pane at `r` (its share of the unit square) lie on a divider: every inner boundary has one, drawn
/// on the leading edge of the later child. Left, right and bottom only; the top edge is under the tab bar. The editor
/// leaves its own border out there (P4-E-F3): it sat right beside the divider line and made the boundary 2px.
fn divider_sides(r: Rect) -> DividerSides {
    const EDGE: f32 = 1e-3;
    DividerSides { left: r.x > EDGE, right: r.x + r.w < 1. - EDGE, bottom: r.y + r.h < 1. - EDGE }
}

/// While a pane is zoomed its frame is the 1px border (`pane["zoomed_border"]`, L-17), so the editor leaves out its own
/// 1px border, which sat right next to it and made the left, right and bottom edges 2px. Otherwise the editor keeps it.
fn editor_bordered(zoomed: bool) -> bool {
    !zoomed
}

/// The split popup's entries in the I-707 order: label and the action whose key it shows.
fn split_item(dir: SplitDirection) -> (&'static str, &'static str) {
    match dir {
        SplitDirection::Right => ("Split Right", "pane::SplitRight"),
        SplitDirection::Left => ("Split Left", "pane::SplitLeft"),
        SplitDirection::Up => ("Split Up", "pane::SplitUp"),
        SplitDirection::Down => ("Split Down", "pane::SplitDown"),
    }
}

impl Workbench {
    /// The center area: the pane tree of the active folder, or the zoomed pane alone (I-730).
    pub(super) fn pane_tree(&self, window: &Window, cx: &Context<Self>) -> AnyElement {
        // L-306: the tree and the sidebar take focus away from the panes (a Markdown preview tab then dims).
        let focus = !(self.panel_focus.is_focused(window) || self.sidebar_focus.is_focused(window));
        let Some(ws) = self.active_ws() else {
            let theme = cx.theme();
            return v_flex()
                .on_children_prepainted(probe(&["tab-bar", "active-item"]))
                .size_full()
                // The first screen has no folder and one pane, which counts as the active one: its end buttons show as
                // before P4-3b (`+`, split off, zoom), with nothing to act on yet.
                .child(layout::tab_bar(&[], end_buttons_shown(false, true).then(first_screen_end), Rc::new(|_, _, _| {}), cx))
                .child(div().flex_1().min_h_0().child(div().size_full().bg(theme.background)))
                .into_any_element();
        };
        let group = &ws.read(cx).group;
        match group.zoomed.filter(|z| group.panes.contains_key(z)) {
            Some(z) => {
                // L-17: over the body, padded by 8px, with a 1px border.
                let theme = cx.theme();
                div()
                    .size_full()
                    .p(ZOOMED_PADDING)
                    .bg(theme.background)
                    .child(div().size_full().border_1().border_color(theme.border).child(self.pane_el(z, group, focus, cx)))
                    .into_any_element()
            }
            None => self.node_el(&group.root, &mut Vec::new(), group, focus, cx),
        }
    }

    fn node_el(&self, node: &Node, path: &mut Vec<usize>, group: &PaneGroup, focus: bool, cx: &Context<Self>) -> AnyElement {
        let Node::Axis { axis, children, flexes } = node else {
            let Node::Pane(id) = node else { unreachable!("a node is a pane or an axis") };
            return self.pane_el(*id, group, focus, cx);
        };
        let horizontal = *axis == Axis::Horizontal;
        let theme = cx.theme();
        let axis_path = path.clone();
        let mut el = div()
            .id(SharedString::from(format!("axis-{axis_path:?}")))
            .relative()
            .flex()
            .size_full()
            // I-726: the divider follows the pointer along the axis; the axis length and start are this element's.
            .on_drag_move::<DividerDrag>(cx.listener(move |this, e: &DragMoveEvent<DividerDrag>, _, cx| {
                let drag = e.drag(cx).clone();
                if drag.path != axis_path {
                    return;
                }
                let (start, len, pos) = if horizontal {
                    (e.bounds.left(), e.bounds.size.width, e.event.position.x)
                } else {
                    (e.bounds.top(), e.bounds.size.height, e.event.position.y)
                };
                this.drag_divider(&drag, f32::from(pos - start), f32::from(len), cx);
            }));
        if !horizontal {
            el = el.flex_col();
        }
        for (i, (child, flex)) in children.iter().zip(flexes).enumerate() {
            path.push(i);
            let inner = self.node_el(child, path, group, focus, cx);
            path.pop();
            // The wrapper does not clip, so the divider's mouse area can reach 2px into the previous child.
            el = el.child(
                div()
                    .relative()
                    .flex()
                    .flex_1()
                    .flex_grow(*flex)
                    .min_w_0()
                    .min_h_0()
                    .child(div().size_full().overflow_hidden().child(inner))
                    .when(i > 0, |d| d.child(self.divider(path, i - 1, horizontal, theme.border, cx))),
            );
        }
        el.into_any_element()
    }

    /// The divider on the leading edge of its child: a `SPLIT_LINE_THICKNESS` line (I-725, color `border` for
    /// `pane_group_border`) inside a `SPLIT_LINE_HITBOX` mouse area, half before the edge. Double-click shares equally (I-727).
    // shortcut: the line takes the theme `border` color; gpui-kit has no `pane_group_border` token (G-106).
    fn divider(&self, axis_path: &[usize], ix: usize, horizontal: bool, color: Hsla, cx: &Context<Self>) -> impl IntoElement {
        let (hit, line) = (SPLIT_LINE_HITBOX, SPLIT_LINE_THICKNESS);
        let drag = DividerDrag { path: axis_path.to_vec(), ix };
        let equalize = axis_path.to_vec();
        let base = div().id(SharedString::from(format!("divider-{axis_path:?}-{ix}"))).absolute();
        let base = if horizontal {
            base.top_0().bottom_0().left(-(hit / 2.)).w(hit).cursor_col_resize()
        } else {
            base.left_0().right_0().top(-(hit / 2.)).h(hit).cursor_row_resize()
        };
        base.on_drag(drag, |drag, _, _, cx| cx.new(|_| drag.clone()))
            .on_double_click(cx.listener(move |this, _, _, cx| this.equalize_axis(&equalize, cx)))
            // The flex layout puts the boundary at a fractional px after a drag, which would smear the 1px line over two
            // pixels; the line is painted on a whole logical px (P4-E-F2).
            .child(
                canvas(
                    |bounds, _, _| bounds,
                    move |hit_bounds, _, window, _| {
                        let start = if horizontal { hit_bounds.left() } else { hit_bounds.top() };
                        let at = px(line_start(f32::from(start), f32::from(hit)));
                        let rect = if horizontal {
                            Bounds::new(point(at, hit_bounds.top()), size(line, hit_bounds.size.height))
                        } else {
                            Bounds::new(point(hit_bounds.left(), at), size(hit_bounds.size.width, line))
                        };
                        window.paint_quad(fill(rect, color));
                    },
                )
                .absolute()
                .size_full(),
            )
    }

    /// One pane: its tab bar and the active tab's editor (I-706 end buttons only on the active pane).
    fn pane_el(&self, id: PaneId, group: &PaneGroup, focus: bool, cx: &Context<Self>) -> AnyElement {
        let pane = &group.panes[&id];
        let focused = group.active == id;
        let theme = cx.theme();
        let tabs: Vec<TabView> = pane
            .tabs
            .iter()
            .enumerate()
            .map(|(i, t)| {
                let doc = group.docs.get(&t.path);
                TabView {
                    title: tab_title(t).into(),
                    markdown: t.markdown,
                    focused: focus && focused,
                    preview: t.preview,
                    pinned: pane.is_pinned(i),
                    active: pane.active == Some(i),
                    press: Rc::new(cx.listener(move |this, p: &TabPress, window, cx| this.on_tab_press(id, i, *p, window, cx))),
                    unpin: Rc::new(cx.listener(move |this, _: &ClickEvent, window, cx| this.toggle_pin_at(id, i, window, cx))),
                    context: Rc::new(cx.listener(move |this, p: &Point<Pixels>, window, cx| this.open_tab_menu(id, i, *p, window, cx))),
                    drag: TabDrag { pane: id, ix: i, title: tab_title(t).into() },
                    dropped: Rc::new(cx.listener(move |this, d: &TabDrag, window, cx| this.drop_tab_at(d, id, i, window, cx))),
                    dirty: doc.is_some_and(|d| d.modified()),
                    conflict: doc.is_some_and(|d| d.has_conflict()),
                    deleted: doc.is_some_and(|d| d.deleted),
                    close: Rc::new(cx.listener(move |this, _: &ClickEvent, window, cx| this.close_tab_at(id, i, window, cx))),
                }
            })
            .collect();
        let end = end_buttons_shown(focused, group.panes.len() == 1).then(|| BarEnd {
            split_enabled: group.split_button().is_some(),
            zoomed: group.zoomed == Some(id),
            on_split: Rc::new(cx.listener(|this, e: &ClickEvent, window, cx| this.open_split_menu(e, window, cx))),
            on_zoom: Rc::new(cx.listener(|this, _: &ClickEvent, window, cx| this.toggle_zoom(window, cx))),
        });
        let tab_count = pane.tabs.len();
        let end_drop: layout::DropHandler = Rc::new(cx.listener(move |this, d: &TabDrag, window, cx| this.drop_tab_at(d, id, tab_count, window, cx)));
        // I-714: the overlay of an ongoing tab drag over this body; the colour is the theme drop-target token.
        // shortcut: gpui-kit's `drop_target` colour, not Zed's `drop_target_background` (no spec value, spec/ambiguous.md has none).
        let overlay = self.drop_hint.filter(|h| h.pane == id && cx.has_active_drag()).map(|h| {
            let r = drop_overlay(h.w, h.h, h.dir);
            div().absolute().left(px(r.x)).top(px(r.y)).w(px(r.w)).h(px(r.h)).bg(theme.drop_target)
        });
        // Edges on a divider: the divider is the only line there, the editor's own border stays on the outer edges.
        let sides = group
            .rects(Rect { x: 0., y: 0., w: 1., h: 1. })
            .into_iter()
            .find(|(p, _)| *p == id)
            .map_or_else(DividerSides::default, |(_, r)| divider_sides(r));
        let item: AnyElement = match (focused.then_some(&self.editor_poc).and_then(Option::as_ref), pane.active_tab()) {
            (Some(poc), _) => div().size_full().child(poc.clone()).into_any_element(),
            (None, Some(t)) if t.markdown => markdown_preview::body(id, t.editor.read(cx).value(), cx).into_any_element(),
            (None, Some(t)) => {
                let readonly = !group.docs.get(&t.path).is_some_and(|d| d.loaded);
                div()
                    .size_full()
                    .bg(theme.background)
                    // The editor handled the press itself (selection, IME); the pane handler above is for the rest.
                    .on_mouse_down(MouseButton::Left, |_, _, cx| cx.stop_propagation())
                    .child(editor_view(&t.editor, readonly, editor_bordered(group.zoomed == Some(id)), sides))
                    .into_any_element()
            }
            (None, None) => div().size_full().bg(theme.background).into_any_element(),
        };
        // E-038, E-039: a Markdown editor tab gets the toolbar with the preview button.
        let item = match pane.active_tab().filter(|t| !t.markdown && is_markdown(&t.path)) {
            Some(_) if !(focused && self.editor_poc.is_some()) => {
                let on_preview: layout::CloseHandler = Rc::new(cx.listener(|this, _: &ClickEvent, window, cx| {
                    let side = window.modifiers().alt;
                    this.open_markdown_preview(side, window, cx)
                }));
                v_flex()
                    .size_full()
                    .child(layout::markdown_toolbar(on_preview, cx))
                    .child(div().flex_1().min_h_0().child(item))
                    .into_any_element()
            }
            _ => item,
        };
        v_flex()
            .on_children_prepainted(probe(&["tab-bar", "active-item"]))
            .id(("pane", id as usize))
            .size_full()
            // A press anywhere in the pane makes it the active one (the editor still gets the press).
            .capture_any_mouse_down(cx.listener(move |this, _: &MouseDownEvent, _, cx| this.activate_pane(id, cx)))
            // A press the editor body did not take (tab bar, toolbar, empty or preview body) moves the keyboard to the
            // pane too, so typing, Save and Close go where the active pane is (P4-23b-R1).
            .on_mouse_down(MouseButton::Left, cx.listener(|this, _: &MouseDownEvent, window, cx| this.focus_active_pane(window, cx)))
            .child(layout::tab_bar(&tabs, end, end_drop, cx))
            .child(
                div()
                    .relative()
                    .flex_1()
                    .min_h_0()
                    // I-712: the drop zone is judged on the body below the tab bar.
                    .on_drag_move::<TabDrag>(cx.listener(move |this, e: &DragMoveEvent<TabDrag>, window, cx| {
                        let (b, p) = (e.bounds, e.event.position);
                        let hint = b.contains(&p).then(|| {
                            let (w, h) = (f32::from(b.size.width), f32::from(b.size.height));
                            body_hint(id, e.drag(cx).pane, tab_count, window.modifiers().control, (w, h), (f32::from(p.x - b.left()), f32::from(p.y - b.top())))
                        });
                        this.set_drop_hint(id, hint, cx);
                    }))
                    .on_drop::<TabDrag>(cx.listener(move |this, d: &TabDrag, window, cx| this.drop_on_body(d, id, window, cx)))
                    .child(item)
                    .children(overlay),
            )
            .into_any_element()
    }

    pub(super) fn activate_pane(&mut self, id: PaneId, cx: &mut Context<Self>) {
        let Some(ws) = self.active_ws() else { return };
        if ws.read(cx).group.active != id {
            ws.update(cx, |ws, _| ws.group.activate(id));
            cx.notify();
        }
    }

    /// Splits the active pane toward `dir` with a clone of its active tab (I-707, I-708, I-711, I-731); nothing
    /// happens for an empty pane. The new pane gets the keyboard.
    fn split(&mut self, dir: SplitDirection, window: &mut Window, cx: &mut Context<Self>) {
        let Some(ws) = self.active_ws() else { return };
        if ws.update(cx, |ws, cx| ws.group.split_active(dir, SplitMode::Clone, window, cx)).is_some() {
            self.focus_active_pane(window, cx);
        }
        cx.notify();
    }

    pub(super) fn on_split_right(&mut self, a: &pane_actions::SplitRight, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.split(SplitDirection::Right, w, cx);
    }

    pub(super) fn on_split_left(&mut self, a: &pane_actions::SplitLeft, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.split(SplitDirection::Left, w, cx);
    }

    pub(super) fn on_split_up(&mut self, a: &pane_actions::SplitUp, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.split(SplitDirection::Up, w, cx);
    }

    pub(super) fn on_split_down(&mut self, a: &pane_actions::SplitDown, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.split(SplitDirection::Down, w, cx);
    }

    /// The split button (I-706, I-707): a popup of the four directions at the click. `Clone` is the mode of every entry.
    // shortcut: the popup opens at the click, not anchored to the button's top-right as in Zed (the popup width is
    // not known here); anchor it once `ContextMenu` can place itself by its right edge.
    pub(super) fn open_split_menu(&mut self, e: &ClickEvent, window: &mut Window, cx: &mut Context<Self>) {
        let position = e.mouse_position().unwrap_or_default();
        let focus = window.focused(cx);
        let entries = SplitDirection::POPUP
            .iter()
            .map(|d| {
                let (label, action) = split_item(*d);
                CmEntry::with_shortcut(label, true, keymap::shortcut_for_name(action, focus.as_ref(), window, cx))
            })
            .collect();
        let menu = cx.new(|cx| ContextMenu::new(entries, Vec::new(), position, window, cx));
        let sub = cx.subscribe_in(&menu, window, |this, menu, event: &ContextMenuEvent, window, cx| {
            if !this.split_menu.as_ref().is_some_and(|m| m.menu == *menu) {
                return;
            }
            match event {
                ContextMenuEvent::Dismissed => {
                    let menu = menu.clone();
                    cx.defer_in(window, move |this, _, cx| {
                        if this.split_menu.as_ref().is_some_and(|m| m.menu == menu) {
                            this.split_menu = None;
                            cx.notify();
                        }
                    });
                }
                ContextMenuEvent::Chosen(i) => {
                    if let Some(dir) = SplitDirection::POPUP.get(*i) {
                        this.split(*dir, window, cx);
                    }
                }
            }
        });
        self.split_menu = Some(OpenMenu::new(menu, sub));
        cx.notify();
    }

    /// `workspace::ToggleZoom` (Shift+Escape, I-737) and the zoom button (I-730).
    pub(super) fn toggle_zoom(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let Some(ws) = self.active_ws() else { return };
        ws.update(cx, |ws, _| ws.group.toggle_zoom());
        self.focus_active_pane(window, cx);
        cx.notify();
    }

    pub(super) fn on_toggle_zoom(&mut self, a: &ws_actions::ToggleZoom, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.toggle_zoom(w, cx);
    }

    /// Ctrl+K Ctrl+arrow (I-732): focus moves to the pane next to the active one. At the group's edge nothing moves
    /// (Zed goes on to the dock or the sidebar there).
    // shortcut: no dock or sidebar hop at the group's edge; add it with the focus-ring work (I-101).
    fn activate_neighbor(&mut self, dir: SplitDirection, window: &mut Window, cx: &mut Context<Self>) {
        let Some(ws) = self.active_ws() else { return };
        let moved = ws.update(cx, |ws, _| {
            let next = ws.group.pane_in_direction(dir);
            next.inspect(|id| ws.group.activate(*id)).is_some()
        });
        if moved {
            self.focus_active_pane(window, cx);
            cx.notify();
        }
    }

    pub(super) fn on_activate_pane_left(&mut self, a: &ws_actions::ActivatePaneLeft, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.activate_neighbor(SplitDirection::Left, w, cx);
    }

    pub(super) fn on_activate_pane_right(&mut self, a: &ws_actions::ActivatePaneRight, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.activate_neighbor(SplitDirection::Right, w, cx);
    }

    pub(super) fn on_activate_pane_up(&mut self, a: &ws_actions::ActivatePaneUp, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.activate_neighbor(SplitDirection::Up, w, cx);
    }

    pub(super) fn on_activate_pane_down(&mut self, a: &ws_actions::ActivatePaneDown, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.activate_neighbor(SplitDirection::Down, w, cx);
    }

    /// I-726: moves the dragged divider under the pointer (`offset` px from the axis start, axis `len` px).
    fn drag_divider(&mut self, drag: &DividerDrag, offset: f32, len: f32, cx: &mut Context<Self>) {
        let Some(ws) = self.active_ws() else { return };
        ws.update(cx, |ws, _| {
            let Some(flexes) = flexes_at(&ws.group.root, &drag.path) else { return };
            let delta = divider_delta(flexes, drag.ix, offset, len);
            ws.group.drag_divider(&drag.path, drag.ix, delta, len);
        });
        cx.notify();
    }

    /// I-727: a double-click on a divider shares that axis equally.
    fn equalize_axis(&mut self, path: &[usize], cx: &mut Context<Self>) {
        let Some(ws) = self.active_ws() else { return };
        ws.update(cx, |ws, _| ws.group.equalize(path));
        cx.notify();
    }
}

#[cfg(test)]
mod tests {
    // Explicit imports: `super::*` would pull in gpui's `test` macro through `gpui_kit::*`.
    use super::{divider_delta, divider_sides, editor_bordered, end_buttons_shown, first_screen_end, flexes_at, line_start};
    use crate::ui::pane::DividerSides;

    fn sides_of(g: &PaneGroup<u32>) -> Vec<(u32, DividerSides)> {
        use crate::ui::pane_group::Rect;
        g.rects(Rect { x: 0., y: 0., w: 1., h: 1. }).into_iter().map(|(id, r)| (id, divider_sides(r))).collect()
    }

    /// P4-E-F3: each boundary gets one line, the divider. A lone pane keeps its whole editor border; in two columns the
    /// shared sides lose it and the outer ones keep it; stacked panes drop the bottom of the upper one; nested splits
    /// follow the tree.
    #[test]
    fn editor_border_leaves_the_divider_sides() {
        let none = DividerSides::default();
        let mut g = PaneGroup::<u32>::default();
        assert_eq!(sides_of(&g), [(0, none)]);
        g.open_in(0, Path::new("a"), false, || 1);
        g.split(SplitDirection::Right, SplitMode::Clone, |_| 2);
        assert_eq!(
            sides_of(&g),
            [(0, DividerSides { left: false, right: true, bottom: false }), (1, DividerSides { left: true, right: false, bottom: false })]
        );
        g.split(SplitDirection::Down, SplitMode::Clone, |_| 3);
        let s = sides_of(&g);
        assert_eq!(s[0].1, DividerSides { left: false, right: true, bottom: false });
        assert_eq!(s[1], (1, DividerSides { left: true, right: false, bottom: true }), "upper right: divider left and below");
        assert_eq!(s[2], (2, DividerSides { left: true, right: false, bottom: false }), "lower right: divider only on the left");
    }

    /// P4-E-F2 (1): after a drag the boundary is a fractional px, the line still starts on a whole one (and a whole
    /// boundary stays where it is); the 4px mouse area puts the line 2px in.
    #[test]
    fn divider_line_snaps_to_a_whole_px() {
        for start in [100.0_f32, 100.4, 100.5, 321.73, 999.99] {
            let at = line_start(start, 4.);
            assert_eq!(at, at.round(), "{start}");
            assert!((at - (start + 2.)).abs() <= 0.5, "{start}");
        }
        assert_eq!(line_start(98., 4.), 100.);
        assert_eq!(line_start(97.6, 4.), 100.);
    }

    /// P4-E-F2 (2): a zoomed pane has the zoom frame as its only border; the editor keeps its own otherwise.
    #[test]
    fn zoomed_pane_draws_one_border() {
        assert!(!editor_bordered(true));
        assert!(editor_bordered(false));
    }

    /// P4-E-F1 (U1, I-706): the first screen's only pane shows its end buttons although no pane is "active" there;
    /// in a split, only the active pane does. The first-screen buttons are `+` and zoom with split off.
    #[test]
    fn first_screen_keeps_its_end_buttons() {
        assert!(end_buttons_shown(false, true));
        assert!(end_buttons_shown(true, false));
        assert!(!end_buttons_shown(false, false));
        let end = first_screen_end();
        assert!(!end.split_enabled && !end.zoomed);
    }
    use crate::ui::pane_group::{Axis, Node, PaneGroup, SplitDirection, SplitMode};
    use std::path::Path;

    /// A group of `u32` editors with one file open, split once toward `dir` (Clone: the new pane shows the file too).
    fn split_group(dir: SplitDirection) -> PaneGroup<u32> {
        let mut g = PaneGroup::<u32>::default();
        g.open_in(0, Path::new("a.txt"), false, || 1);
        g.split(dir, SplitMode::Clone, |_| 2);
        g
    }

    /// The first divider's position on an axis of `len` px.
    fn divider_at(g: &PaneGroup<u32>, len: f32) -> f32 {
        let Node::Axis { flexes, .. } = &g.root else { panic!("split makes an axis") };
        len * flexes[0] / flexes.len() as f32
    }

    /// I-724, I-726: the divider sits where the first children end, so the delta to a pointer position is the
    /// difference of the two.
    #[test]
    fn divider_delta_is_pointer_minus_divider() {
        assert_eq!(divider_delta(&[1., 1.], 0, 300., 800.), -100.);
        assert_eq!(divider_delta(&[1., 1.], 0, 400., 800.), 0.);
        // Three children: the second divider ends the first two shares, (0.5 + 1.0) / 3 of 1000 px = 500.
        assert_eq!(divider_delta(&[0.5, 1., 1.5], 1, 600., 1000.), 100.);
    }

    /// I-726: following the pointer moves the divider to it, one move after another, until a pane reaches its
    /// minimum (80 wide): then the divider stops there and the pointer's rest is not carried over to later moves.
    #[test]
    fn dragging_follows_pointer_and_stops_at_minimum() {
        let mut g = split_group(SplitDirection::Right);
        let len = 800.;
        for pointer in [500., 650., 300.] {
            let flexes = flexes_at(&g.root, &[]).unwrap().to_vec();
            g.drag_divider(&[], 0, divider_delta(&flexes, 0, pointer, len), len);
            assert!((divider_at(&g, len) - pointer).abs() < 0.01, "divider follows {pointer}");
        }
        // Far past the right end: the right pane keeps 80px.
        let flexes = flexes_at(&g.root, &[]).unwrap().to_vec();
        g.drag_divider(&[], 0, divider_delta(&flexes, 0, 790., len), len);
        assert!((divider_at(&g, len) - 720.).abs() < 0.01);
        // Back inside: the divider follows again from where it stopped.
        let flexes = flexes_at(&g.root, &[]).unwrap().to_vec();
        g.drag_divider(&[], 0, divider_delta(&flexes, 0, 600., len), len);
        assert!((divider_at(&g, len) - 600.).abs() < 0.01);
    }

    /// I-726: stacked panes stop at 100px high.
    #[test]
    fn stacked_drag_stops_at_minimum_height() {
        let mut g = split_group(SplitDirection::Down);
        let len = 600.;
        let flexes = flexes_at(&g.root, &[]).unwrap().to_vec();
        g.drag_divider(&[], 0, divider_delta(&flexes, 0, 10., len), len);
        assert!((divider_at(&g, len) - 100.).abs() < 0.01);
    }

    /// I-727: a double-click shares the axis equally again.
    #[test]
    fn equalize_resets_the_dragged_axis() {
        let mut g = split_group(SplitDirection::Right);
        g.drag_divider(&[], 0, 100., 800.);
        assert_ne!(flexes_at(&g.root, &[]).unwrap(), [1., 1.]);
        g.equalize(&[]);
        assert_eq!(flexes_at(&g.root, &[]).unwrap(), [1., 1.]);
    }

    /// `flexes_at` walks child indices from the root and rejects a leaf.
    #[test]
    fn flexes_at_follows_the_path() {
        let mut g = split_group(SplitDirection::Right);
        g.split(SplitDirection::Down, SplitMode::Clone, |_| 3);
        // Right then Down on the new pane: root axis (horizontal) → [pane0, axis(vertical)].
        let Node::Axis { axis, children, .. } = &g.root else { panic!() };
        assert_eq!(*axis, Axis::Horizontal);
        assert!(matches!(children[1], Node::Axis { axis: Axis::Vertical, .. }));
        assert!(flexes_at(&g.root, &[1]).is_some());
        assert!(flexes_at(&g.root, &[0]).is_none());
        assert!(flexes_at(&g.root, &[5]).is_none());
    }
}

//! Pane tree of a workspace (v0.4 P4-3, R-13, D-7; 02-INTERACTION 3.1 `I-706~I-739`).
//!
//! - The root is one pane or a recursive axis (I-723). Split Right/Left/Up/Down add a pane next to the active one;
//!   no limit on the count. A new sibling resets that axis' flexes to 1 (I-724).
//! - Split modes (I-709): `ClonePane` (default, a second view of the active tab), `EmptyPane`, `MovePane`.
//! - A pane whose last tab goes is removed, unless it is the only (root) pane (I-728).
//! - Files are `Docs` (one per path); tabs are views. Views of one file are kept equal: an edit in one view is
//!   spliced into the others (`sync_view`), so dirty and save state stay per file (H-20 option A).
//! - Drawing (dividers, overlays, buttons) and keys are P4-3b / P4-4 (impl-ui); the judging functions are here.
// P4-3b wired splits, divider drag, zoom and focus moves; P4-4 wired the tab drops.
#![cfg_attr(not(test), expect(dead_code, reason = "SPLIT_HORIZONTAL/VERTICAL and SplitMode::Empty have no caller yet (no SplitHorizontal/Vertical action, no empty-pane command)"))]

use std::collections::BTreeMap;
use std::path::Path;
use std::rc::Rc;

use gpui_kit::component::input::{EditorState, InputEvent};
use gpui_kit::*;

use super::folders::FolderWorkspace;
use super::pane::{CloseState, Docs, Pane, ReadApply, ReadOutcome, Tab, buffer_hash, editor_scrollbar, read_text, text_hash};

/// I-725 divider line (`pane["split_line_thickness"]`).
pub const SPLIT_LINE_THICKNESS: Pixels = px(1.);
/// I-725 divider mouse area, 2px each side (`pane["split_line_mouse_hitbox"]`).
pub const SPLIT_LINE_HITBOX: Pixels = px(4.);
/// I-726 drag minimum for side-by-side panes, px (`pane["min_drag_width"]`).
pub const MIN_DRAG_WIDTH: f32 = 80.;
/// I-726 drag minimum for stacked panes, px (`pane["min_drag_height"]`).
pub const MIN_DRAG_HEIGHT: f32 = 100.;
/// I-712 drop edge band, share of min(width, height) (`pane["drop_target_size_ratio"]`).
pub const DROP_TARGET_RATIO: f32 = 0.2;
/// I-714 directional drop overlay, share of the body (`pane["directional_drop_overlay_ratio"]`).
pub const DROP_OVERLAY_RATIO: f32 = 0.5;

pub type PaneId = u32;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Axis {
    /// Children side by side (Left / Right).
    Horizontal,
    /// Children stacked (Up / Down).
    Vertical,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum SplitDirection {
    Up,
    Down,
    Left,
    Right,
}

impl SplitDirection {
    /// The split popup order (I-707).
    pub const POPUP: [Self; 4] = [Self::Right, Self::Left, Self::Up, Self::Down];

    pub fn axis(self) -> Axis {
        match self {
            Self::Left | Self::Right => Axis::Horizontal,
            Self::Up | Self::Down => Axis::Vertical,
        }
    }

    /// Left and Up go before the existing pane (I-723).
    fn before(self) -> bool {
        matches!(self, Self::Left | Self::Up)
    }

    pub fn opposite(self) -> Self {
        match self {
            Self::Up => Self::Down,
            Self::Down => Self::Up,
            Self::Left => Self::Right,
            Self::Right => Self::Left,
        }
    }
}

/// I-710: `SplitHorizontal` follows `pane_split_direction_horizontal` (default down), `SplitVertical` follows
/// `pane_split_direction_vertical` (default right); the explicit four directions ignore the settings.
pub const SPLIT_HORIZONTAL: SplitDirection = SplitDirection::Down;
pub const SPLIT_VERTICAL: SplitDirection = SplitDirection::Right;

/// I-709, Zed's `ClonePane` / `EmptyPane` / `MovePane`. The default is `Clone` (I-707, I-711, I-731).
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub enum SplitMode {
    #[default]
    Clone,
    Empty,
    Move,
}

/// I-707 split button: `None` is disabled. A splittable active item clones; an unsplittable one moves when the pane
/// has two or more tabs. `active_splittable`: `None` when the pane is empty.
pub fn split_button(tabs: usize, active_splittable: Option<bool>) -> Option<SplitMode> {
    match active_splittable {
        Some(true) => Some(SplitMode::Clone),
        Some(false) if tabs >= 2 => Some(SplitMode::Move),
        _ => None,
    }
}

/// Axis-aligned rectangle in px (or any unit).
#[derive(Clone, Copy, Debug, PartialEq)]
pub struct Rect {
    pub x: f32,
    pub y: f32,
    pub w: f32,
    pub h: f32,
}

impl Rect {
    fn contains(&self, x: f32, y: f32) -> bool {
        x >= self.x && x < self.x + self.w && y >= self.y && y < self.y + self.h
    }
}

/// I-712, I-713: where a drag over a pane body of `w` × `h` (tab bar excluded) at (`x`, `y`) drops. `None` is the
/// centre (move into the pane); a direction splits. The edge band is min(w, h) × 0.2, its boundary counts as centre;
/// inside the band the nearest edge wins. A pane that may not split always takes the centre.
// shortcut: equal distances pick up, right, down, left in that order; Zed's tie order is unverified (I-713).
pub fn drop_split(w: f32, h: f32, x: f32, y: f32, can_split: bool) -> Option<SplitDirection> {
    let d = w.min(h) * DROP_TARGET_RATIO;
    if !can_split || !(x < d || x > w - d || y < d || y > h - d) {
        return None;
    }
    let edges = [(y, SplitDirection::Up), (w - x, SplitDirection::Right), (h - y, SplitDirection::Down), (x, SplitDirection::Left)];
    edges.into_iter().fold(None, |best: Option<(f32, SplitDirection)>, e| match best {
        Some(b) if b.0 <= e.0 => Some(b),
        _ => Some(e),
    })
    .map(|(_, dir)| dir)
}

/// I-714: the drop overlay inside a `w` × `h` body: the whole body for the centre, the half on the split side.
pub fn drop_overlay(w: f32, h: f32, split: Option<SplitDirection>) -> Rect {
    let (hw, hh) = (w * DROP_OVERLAY_RATIO, h * DROP_OVERLAY_RATIO);
    match split {
        None => Rect { x: 0., y: 0., w, h },
        Some(SplitDirection::Up) => Rect { x: 0., y: 0., w, h: hh },
        Some(SplitDirection::Down) => Rect { x: 0., y: h - hh, w, h: hh },
        Some(SplitDirection::Left) => Rect { x: 0., y: 0., w: hw, h },
        Some(SplitDirection::Right) => Rect { x: w - hw, y: 0., w: hw, h },
    }
}

/// I-726: drags divider `ix` (between children `ix` and `ix + 1`) by `delta` px on an axis `len` px long. The growing
/// side takes what the other side gives; a child at its minimum (`mins[i]`, the subtree's own minimum, `Node::min_len`)
/// passes the rest to the next one further away. Flexes keep the I-724 scale (child length = len × flex ÷ count).
pub fn drag_divider(flexes: &mut [f32], ix: usize, delta: f32, len: f32, mins: &[f32]) {
    let n = flexes.len();
    if ix + 1 >= n || len <= 0. {
        return;
    }
    let mut sizes: Vec<f32> = flexes.iter().map(|f| len * f / n as f32).collect();
    let (grow, shrink): (usize, Vec<usize>) =
        if delta > 0. { (ix, (ix + 1..n).collect()) } else { (ix + 1, (0..=ix).rev().collect()) };
    let mut left = delta.abs();
    for i in shrink {
        let take = (sizes[i] - mins[i]).max(0.).min(left);
        sizes[i] -= take;
        sizes[grow] += take;
        left -= take;
        if left <= 0. {
            break;
        }
    }
    for (f, s) in flexes.iter_mut().zip(sizes) {
        *f = s * n as f32 / len;
    }
}

/// The byte range of `old` that changes into `new`: (start, end in old, end in new), on char boundaries. `None`
/// when equal. Common prefix and suffix only, so one typed edit maps to itself.
pub fn splice(old: &str, new: &str) -> Option<(usize, usize, usize)> {
    if old == new {
        return None;
    }
    let mut start = old.bytes().zip(new.bytes()).take_while(|(a, b)| a == b).count();
    while !old.is_char_boundary(start) || !new.is_char_boundary(start) {
        start -= 1;
    }
    let max = old.len().min(new.len()) - start;
    let mut suffix = old.bytes().rev().zip(new.bytes().rev()).take(max).take_while(|(a, b)| a == b).count();
    while !old.is_char_boundary(old.len() - suffix) || !new.is_char_boundary(new.len() - suffix) {
        suffix -= 1;
    }
    Some((start, old.len() - suffix, new.len() - suffix))
}

#[derive(Clone, Debug, PartialEq)]
pub enum Node {
    Pane(PaneId),
    /// `flexes[i]` is child `i`'s share; they sum to the child count (I-724).
    Axis { axis: Axis, children: Vec<Node>, flexes: Vec<f32> },
}

impl Node {
    fn leaves(&self, out: &mut Vec<PaneId>) {
        match self {
            Node::Pane(id) => out.push(*id),
            Node::Axis { children, .. } => children.iter().for_each(|c| c.leaves(out)),
        }
    }

    /// I-723, I-724: puts `new` beside `target`. Same axis: a sibling in the parent; otherwise the leaf becomes an
    /// axis of the two. Left / Up before, Right / Down after. The axis that got the sibling resets its flexes to 1.
    fn split(&mut self, target: PaneId, new: PaneId, dir: SplitDirection) -> bool {
        match self {
            Node::Pane(id) if *id == target => {
                let pair = if dir.before() { [new, target] } else { [target, new] };
                *self = Node::Axis { axis: dir.axis(), children: pair.map(Node::Pane).to_vec(), flexes: vec![1.; 2] };
                true
            }
            Node::Pane(_) => false,
            Node::Axis { axis, children, flexes } => {
                if *axis == dir.axis()
                    && let Some(i) = children.iter().position(|c| *c == Node::Pane(target))
                {
                    children.insert(if dir.before() { i } else { i + 1 }, Node::Pane(new));
                    *flexes = vec![1.; children.len()];
                    return true;
                }
                children.iter_mut().any(|c| c.split(target, new, dir))
            }
        }
    }

    /// I-728: removes leaf `id`; the axis it left resets its flexes, and an axis left with one child is replaced by it.
    fn remove(&mut self, id: PaneId) -> bool {
        let Node::Axis { children, flexes, .. } = self else { return false };
        if let Some(i) = children.iter().position(|c| *c == Node::Pane(id)) {
            children.remove(i);
            *flexes = vec![1.; children.len()];
            if children.len() == 1 {
                *self = children.remove(0);
            }
            return true;
        }
        children.iter_mut().any(|c| c.remove(id))
    }

    /// Leaf rectangles inside `r` (I-724 lengths).
    fn rects(&self, r: Rect, out: &mut Vec<(PaneId, Rect)>) {
        match self {
            Node::Pane(id) => out.push((*id, r)),
            Node::Axis { axis, children, flexes } => {
                let n = children.len() as f32;
                let mut at = 0.;
                for (c, f) in children.iter().zip(flexes) {
                    let part = f / n;
                    let cr = match axis {
                        Axis::Horizontal => Rect { x: r.x + r.w * at, y: r.y, w: r.w * part, h: r.h },
                        Axis::Vertical => Rect { x: r.x, y: r.y + r.h * at, w: r.w, h: r.h * part },
                    };
                    c.rects(cr, out);
                    at += part;
                }
            }
        }
    }

    /// The node at `path` (child indices from this node).
    fn node_at(&mut self, path: &[usize]) -> Option<&mut Node> {
        match (self, path) {
            (node, []) => Some(node),
            (Node::Axis { children, .. }, [i, rest @ ..]) => children.get_mut(*i)?.node_at(rest),
            _ => None,
        }
    }

    /// I-726: the least length this subtree can take along `along` keeping its current ratios, with no pane under its
    /// minimum (80 px wide, 100 px high). Resizing a parent scales its children (I-724 lengths), so a child laid out
    /// along that axis with share `flex / count` needs `min / share`; the subtree needs the largest of those. Children
    /// across the axis all get the full length, so the largest minimum counts (P4-3-R2).
    fn min_len(&self, along: Axis) -> f32 {
        match self {
            Node::Pane(_) if along == Axis::Horizontal => MIN_DRAG_WIDTH,
            Node::Pane(_) => MIN_DRAG_HEIGHT,
            Node::Axis { axis, children, flexes } => {
                let n = children.len() as f32;
                children
                    .iter()
                    .zip(flexes)
                    .map(|(c, f)| if *axis == along { c.min_len(along) * n / f } else { c.min_len(along) })
                    .fold(0., f32::max)
            }
        }
    }
}

/// What `PaneGroup::open_in` did.
#[derive(Debug, PartialEq)]
pub struct Opened {
    pub ix: usize,
    pub created: bool,
    /// A first read to start for a file nothing showed yet; `None` with `created`: copy another view's text.
    pub read: Option<u64>,
}

/// The panes of a workspace and their files.
pub struct PaneGroup<E = Entity<EditorState>> {
    pub docs: Docs,
    pub panes: BTreeMap<PaneId, Pane<E>>,
    pub root: Node,
    /// The pane that has (or last had) focus; opens, splits and Ctrl+W act on it.
    pub active: PaneId,
    /// I-730: the zoomed pane, drawn alone over the group.
    pub zoomed: Option<PaneId>,
    next_id: PaneId,
}

impl<E> Default for PaneGroup<E> {
    fn default() -> Self {
        Self { docs: Docs::default(), panes: BTreeMap::from([(0, Pane::default())]), root: Node::Pane(0), active: 0, zoomed: None, next_id: 1 }
    }
}

impl<E> PaneGroup<E> {
    pub fn active_pane(&self) -> &Pane<E> {
        &self.panes[&self.active]
    }

    pub fn active_pane_mut(&mut self) -> &mut Pane<E> {
        self.panes.get_mut(&self.active).expect("active pane exists")
    }

    pub fn active_tab(&self) -> Option<&Tab<E>> {
        self.active_pane().active_tab()
    }

    /// Focus moved into pane `id` (click, keyboard).
    pub fn activate(&mut self, id: PaneId) {
        if self.panes.contains_key(&id) {
            self.active = id;
        }
    }

    /// Panes in tree order (left to right, top to bottom).
    pub fn leaves(&self) -> Vec<PaneId> {
        let mut out = Vec::new();
        self.root.leaves(&mut out);
        out
    }

    /// Every view of `path`, in every pane.
    pub fn views<'a>(&'a self, path: &'a Path) -> impl Iterator<Item = &'a E> + 'a {
        self.panes.values().flat_map(|p| p.tabs.iter()).filter(move |t| t.path == path).map(|t| &t.editor)
    }

    /// Paths of the open files.
    pub fn paths(&self) -> Vec<std::path::PathBuf> {
        self.docs.docs.iter().map(|d| d.path.clone()).collect()
    }

    pub fn tab_count(&self) -> usize {
        self.panes.values().map(|p| p.tabs.len()).sum()
    }

    fn forget_if_unseen(&mut self, path: &Path) {
        if self.views(path).next().is_none() {
            self.docs.remove(path);
        }
    }

    /// Opens `path` in pane `pane` (I-061~I-063): an open tab is activated (a non-preview open promotes it); else a
    /// new view is placed, replacing the pane's preview tab (I-062). A file new to the workspace gets a doc and a read.
    /// A preview that is the last view of a file with something to keep (modified, e.g. a deleted non-empty buffer
    /// E-087, or saving) is not replaced but promoted (phase3-final Must fix 2); another view keeps the file anyway.
    pub fn open_in(&mut self, pane: PaneId, path: &Path, preview: bool, make: impl FnOnce() -> E) -> Option<Opened> {
        let keep = preview
            && self.panes.get(&pane)?.tabs.iter().find(|t| t.preview).is_some_and(|t| {
                self.views(&t.path).nth(1).is_none()
                    && self.docs.get(&t.path).is_some_and(|d| d.modified() || d.saving.is_some())
            });
        let p = self.panes.get_mut(&pane)?;
        self.active = pane;
        if let Some(i) = p.find(path) {
            if !preview {
                p.promote(i);
            }
            p.active = Some(i);
            return Some(Opened { ix: i, created: false, read: None });
        }
        let (ix, replaced) = p.place(Tab { path: path.to_path_buf(), preview, markdown: false, editor: make(), tool: None }, keep);
        if let Some(old) = replaced {
            self.forget_if_unseen(&old.path);
        }
        let read = self.docs.find(path).is_none().then(|| self.docs.add(path));
        Some(Opened { ix, created: true, read })
    }

    /// L-69: opens the Markdown preview of `path` in `pane` next to the active tab; one that is already there is activated.
    /// Returns its index and whether it is new (it then needs its text: `copy_source`). The file must be open (its doc).
    pub fn open_markdown(&mut self, pane: PaneId, path: &Path, make: impl FnOnce() -> E) -> Option<(usize, bool)> {
        self.docs.find(path)?;
        let p = self.panes.get_mut(&pane)?;
        self.active = pane;
        if let Some(i) = p.find_preview(path) {
            p.active = Some(i);
            return Some((i, false));
        }
        let (ix, _) = p.place(Tab { path: path.to_path_buf(), preview: false, markdown: true, editor: make(), tool: None }, false);
        Some((ix, true))
    }

    /// A user edit in view `editor` whose buffer hashes to `hash`: the file's dirty state, and the edit promotes that
    /// view's preview tab (I-063). Returns the file path.
    pub fn on_edit(&mut self, editor: &E, hash: u64) -> Option<std::path::PathBuf>
    where
        E: PartialEq,
    {
        let tab = self.panes.values_mut().flat_map(|p| p.tabs.iter_mut()).find(|t| t.editor == *editor)?;
        tab.preview = false;
        let path = tab.path.clone();
        let ix = self.docs.find(&path)?;
        self.docs.on_edit(ix, hash);
        Some(path)
    }

    /// Closes tab `ix` of pane `pane`. The file is forgotten when this was its last view; an emptied pane goes
    /// (I-728, I-735).
    pub fn close_view(&mut self, pane: PaneId, ix: usize) -> Option<Tab<E>> {
        let tab = self.panes.get_mut(&pane)?.close_tab(ix)?;
        self.forget_if_unseen(&tab.path);
        self.remove_if_empty(pane);
        Some(tab)
    }

    /// What closing one view of `path` must do (P3-3 flow): another view keeps the file, so nothing to ask; the last
    /// view is judged by the file (`Docs::close_state`).
    pub fn close_state(&self, path: &Path) -> CloseState {
        if self.panes.values().flat_map(|p| &p.tabs).any(|t| t.path == path && t.tool.is_some()) { return CloseState::Clean; }
        if self.views(path).nth(1).is_some() { CloseState::Clean } else { self.docs.close_state(path) }
    }

    /// Closes every view of `path` (the file was given up, E-085).
    pub fn close_path(&mut self, path: &Path) {
        let ids: Vec<PaneId> = self.panes.keys().copied().collect();
        for id in ids {
            while let Some(ix) = self.panes.get(&id).and_then(|p| p.tabs.iter().position(|t| t.path == path)) {
                self.close_view(id, ix);
            }
        }
        self.docs.remove(path);
    }

    /// I-728: an empty pane leaves the tree, unless it is the root pane (it stays as the empty editor area).
    // shortcut: focus goes to the pane now at the removed one's tree position, not Zed's last-focused pane.
    fn remove_if_empty(&mut self, id: PaneId) {
        if self.root == Node::Pane(id) || self.panes.get(&id).is_none_or(|p| !p.tabs.is_empty()) {
            return;
        }
        let at = self.leaves().iter().position(|l| *l == id).unwrap_or(0);
        self.root.remove(id);
        self.panes.remove(&id);
        if self.zoomed == Some(id) {
            self.zoomed = None;
        }
        if self.active == id {
            let leaves = self.leaves();
            self.active = leaves[at.min(leaves.len() - 1)];
        }
    }

    fn add_pane(&mut self, beside: PaneId, dir: SplitDirection) -> PaneId {
        let id = self.next_id;
        self.next_id += 1;
        self.panes.insert(id, Pane::default());
        self.root.split(beside, id, dir);
        id
    }

    /// I-708, I-709: splits the active pane toward `dir`. `ClonePane`: a new pane with a second view of the active tab
    /// (`clone` makes its editor), nothing when the pane is empty. `EmptyPane`: a new empty pane. `MovePane`: the
    /// active tab moves to the new pane; with one tab or none, an empty pane opens on the opposite side and focus
    /// stays, which gives the same layout. Returns the new pane.
    pub fn split(&mut self, dir: SplitDirection, mode: SplitMode, clone: impl FnOnce(&Tab<E>) -> E) -> Option<PaneId> {
        let src = self.active;
        match mode {
            SplitMode::Clone => {
                let tab = self.active_pane().active_tab()?;
                let view = Tab { path: tab.path.clone(), preview: false, markdown: tab.markdown, editor: clone(tab), tool: tab.tool.clone() };
                let id = self.add_pane(src, dir);
                self.panes.get_mut(&id)?.insert_at(view, 0, false);
                self.active = id;
                Some(id)
            }
            SplitMode::Empty => {
                let id = self.add_pane(src, dir);
                self.active = id;
                Some(id)
            }
            SplitMode::Move if self.active_pane().tabs.len() <= 1 => Some(self.add_pane(src, dir.opposite())),
            SplitMode::Move => {
                let ix = self.active_pane().active?;
                let pinned = self.active_pane().is_pinned(ix);
                let tab = self.active_pane_mut().close_tab(ix)?;
                let id = self.add_pane(src, dir);
                self.panes.get_mut(&id)?.insert_at(tab, 0, pinned);
                self.active = id;
                Some(id)
            }
        }
    }

    /// I-707 for the active pane: every tab here is an editor, which can split.
    pub fn split_button(&self) -> Option<SplitMode> {
        let p = self.active_pane();
        split_button(p.tabs.len(), p.active_tab().map(|_| true))
    }

    /// Pane rectangles inside `bounds` (I-724), for drawing and for `pane_in_direction`.
    pub fn rects(&self, bounds: Rect) -> Vec<(PaneId, Rect)> {
        let mut out = Vec::new();
        self.root.rects(bounds, &mut out);
        out
    }

    /// I-732 Ctrl+K Ctrl+arrow: the pane next to the active one toward `dir`, at the middle of the active pane's edge.
    /// `None` at the group's edge (the caller goes on to the dock or sidebar there).
    // shortcut: judged on a unit square; the real px layout is the same picture scaled, so neighbours match.
    pub fn pane_in_direction(&self, dir: SplitDirection) -> Option<PaneId> {
        let rects = self.rects(Rect { x: 0., y: 0., w: 1., h: 1. });
        let r = rects.iter().find(|(id, _)| *id == self.active)?.1;
        let e = 1e-4;
        let (x, y) = match dir {
            SplitDirection::Left => (r.x - e, r.y + r.h / 2.),
            SplitDirection::Right => (r.x + r.w + e, r.y + r.h / 2.),
            SplitDirection::Up => (r.x + r.w / 2., r.y - e),
            SplitDirection::Down => (r.x + r.w / 2., r.y + r.h + e),
        };
        rects.iter().find(|(_, r)| r.contains(x, y)).map(|(id, _)| *id)
    }

    /// I-726: drags divider `ix` of the axis at `path` (child indices from the root) by `delta` px; `len` is that
    /// axis' length in px. Each child shrinks no further than its subtree's minimum (`Node::min_len`).
    pub fn drag_divider(&mut self, path: &[usize], ix: usize, delta: f32, len: f32) {
        if let Some(Node::Axis { axis, children, flexes }) = self.root.node_at(path) {
            let mins: Vec<f32> = children.iter().map(|c| c.min_len(*axis)).collect();
            drag_divider(flexes, ix, delta, len, &mins);
        }
    }

    /// I-727 divider double-click: that axis' children share equally (nested axes keep theirs).
    pub fn equalize(&mut self, path: &[usize]) {
        if let Some(Node::Axis { flexes, .. }) = self.root.node_at(path) {
            flexes.iter_mut().for_each(|f| *f = 1.);
        }
    }

    /// I-730, I-737 (Shift+Escape): zooms the active pane, or unzooms it.
    pub fn toggle_zoom(&mut self) {
        self.zoomed = if self.zoomed == Some(self.active) { None } else { Some(self.active) };
    }

    /// I-715, I-716, I-719, I-720: drag of tab `ix` of pane `from` onto pane `to` at `at` (a tab's index, or the
    /// tab count for the empty tab-bar end). Same pane: reorder. Another pane: the tab moves (never a preview, I-717),
    /// pinned when it lands in the target's pinned run or was pinned and lands first; an emptied source pane goes.
    pub fn move_tab(&mut self, from: PaneId, ix: usize, to: PaneId, at: usize) {
        if from == to {
            if let Some(p) = self.panes.get_mut(&from) {
                p.reorder(ix, at);
            }
            return;
        }
        if !self.panes.contains_key(&to) {
            return;
        }
        let Some(src) = self.panes.get_mut(&from) else { return };
        let pinned = src.is_pinned(ix);
        let Some(tab) = src.close_tab(ix) else { return };
        let dst = self.panes.get_mut(&to).expect("checked above");
        match if tab.markdown { dst.find_preview(&tab.path) } else { dst.find(&tab.path) } {
            // The file is already shown there: keep that tab, drop the dragged view.
            Some(i) => dst.active = Some(i),
            None => {
                dst.insert_at(tab, at, pinned && at == 0);
            }
        }
        self.active = to;
        self.remove_if_empty(from);
    }

    /// I-717 centre drop: moves into pane `to` after its active tab.
    pub fn drop_center(&mut self, from: PaneId, ix: usize, to: PaneId) {
        let at = self.panes.get(&to).map(|p| p.active.map_or(p.tabs.len(), |a| a + 1)).unwrap_or(0);
        self.move_tab(from, ix, to, at);
    }

    /// I-717, I-718: edge drop of tab `ix` of pane `from` on pane `target` toward `dir`: a new empty pane there gets
    /// the tab. `copy` (Ctrl held, an editor that can clone) puts a new view there instead and leaves the source.
    pub fn drop_split(&mut self, from: PaneId, ix: usize, target: PaneId, dir: SplitDirection, copy: Option<E>) -> Option<PaneId> {
        let tab = self.panes.get(&from)?.tabs.get(ix)?;
        let (path, markdown, tool) = (tab.path.clone(), tab.markdown, tab.tool.clone());
        let pinned = self.panes[&from].is_pinned(ix);
        let id = self.add_pane(target, dir);
        match copy {
            Some(editor) => {
                self.panes.get_mut(&id)?.insert_at(Tab { path, preview: false, markdown, editor, tool }, 0, false);
            }
            None => {
                let tab = self.panes.get_mut(&from)?.close_tab(ix)?;
                self.panes.get_mut(&id)?.insert_at(tab, 0, pinned);
                self.remove_if_empty(from);
            }
        }
        self.active = id;
        Some(id)
    }

    /// I-718 Ctrl-drop of tab `ix` of pane `from` into another pane `to`: the source keeps its tab and `to` gets a new
    /// view (`editor`, a copy made by the caller; never a preview) added without a position, so by the plain add rule
    /// (after the active tab, outside the pinned run; `Pane::place`), not at the drop place a move uses. A pane that
    /// already shows the file only activates that tab. Nothing happens within one pane.
    pub fn copy_tab_view(&mut self, from: PaneId, ix: usize, to: PaneId, editor: E) {
        let Some((path, markdown, tool)) = self.panes.get(&from).and_then(|p| p.tabs.get(ix)).map(|t| (t.path.clone(), t.markdown, t.tool.clone())) else { return };
        let Some(dst) = self.panes.get_mut(&to).filter(|_| from != to) else { return };
        match if markdown { dst.find_preview(&path) } else { dst.find(&path) } {
            Some(i) => dst.active = Some(i),
            None => {
                dst.place(Tab { path, preview: false, markdown, editor, tool }, false);
            }
        }
        self.active = to;
    }

    /// I-045: where the editor tab of `path` is, looking in `prefer` first and then in the other panes (a preview opened
    /// to the side has its source in another pane).
    pub fn find_source(&self, path: &Path, prefer: PaneId) -> Option<(PaneId, usize)> {
        let in_pane = |id: &PaneId| self.panes.get(id).and_then(|p| p.find(path)).map(|i| (*id, i));
        in_pane(&prefer).or_else(|| self.panes.keys().find_map(in_pane))
    }

    /// The file or folder `from` was renamed or moved to `to` (판단). Returns the new paths whose read in flight was
    /// dropped (`Docs::rename_path`); the caller reads them again.
    pub fn rename_path(&mut self, from: &Path, to: &Path) -> Vec<std::path::PathBuf> {
        for p in self.panes.values_mut() {
            p.rename_path(from, to);
        }
        self.docs.rename_path(from, to)
    }
}

impl PaneGroup {
    /// A tab editor whose user edits mark the file dirty and reach the file's other views (`edited`).
    fn new_editor(window: &mut Window, cx: &mut Context<FolderWorkspace>) -> Entity<EditorState> {
        let editor = cx.new(|cx| {
            let mut state = EditorState::new(window, cx);
            state.set_scrollbar_renderer(Some(Rc::new(editor_scrollbar)));
            state
        });
        // Only edits emit Change (`set_value` does not), so this tracks edits, not reads.
        cx.observe(&editor, |_, _, cx| cx.notify()).detach();
        cx.subscribe_in(&editor, window, |ws, editor, event: &InputEvent, window, cx| {
            if matches!(event, InputEvent::Change) {
                ws.group.edited(editor, window, cx);
            }
        })
        .detach();
        editor
    }

    /// An edit in view `editor`. The other views of the file take the same change (`sync_view`); their own Change then
    /// finds every view equal and stops there, so a synced view is not promoted from preview.
    fn edited(&mut self, editor: &Entity<EditorState>, window: &mut Window, cx: &mut Context<FolderWorkspace>) {
        let text = editor.read(cx).value();
        let Some(path) = self.panes.values().flat_map(|p| p.tabs.iter()).find(|t| t.editor == *editor).map(|t| t.path.clone()) else {
            return;
        };
        let others: Vec<(Entity<EditorState>, SharedString)> =
            self.views(&path).filter(|e| *e != editor).map(|e| (e.clone(), e.read(cx).value())).collect();
        let Some(targets) = sync_targets(&text, &others) else { return };
        // shortcut: hashes the whole buffer per edit, fine for typical files; keep a running state if large files lag.
        self.on_edit(editor, buffer_hash(&text));
        for other in targets {
            sync_view(other, &text, window, cx);
        }
        cx.notify();
    }

    /// Fills every view of `path` with `text` (a read landed or edits were discarded).
    pub fn fill(&self, path: &Path, text: &str, window: &mut Window, cx: &mut App) {
        let views: Vec<Entity<EditorState>> = self.views(path).cloned().collect();
        for v in views {
            v.update(cx, |e, cx| e.set_value(text, window, cx));
        }
    }

    /// 파일을 활성 Pane 에 연다. 돌려주는 값: (탭 번호, 새로 만들었나). A file new to the workspace starts empty and is
    /// filled when the background read finishes (dropped if the tab or workspace is gone by then); a file another
    /// pane shows gets a copy of that view's text.
    pub fn open(&mut self, path: &Path, preview: bool, window: &mut Window, cx: &mut Context<FolderWorkspace>) -> (usize, bool) {
        let pane = self.active;
        let Some(o) = self.open_in(pane, path, preview, || Self::new_editor(window, cx)) else { return (0, false) };
        if !o.created {
            return (o.ix, false);
        }
        let Some(token) = o.read else {
            // The new view is the editor just placed at `o.ix`; its text comes from any other view (P4-3-R1).
            let new = self.panes[&pane].tabs[o.ix].editor.clone();
            if let Some(text) = copy_source(self.views(path), &new).map(|src| src.read(cx).value()) {
                new.update(cx, |e, cx| e.set_value(text, window, cx));
            }
            return (o.ix, true);
        };
        let path = path.to_path_buf();
        cx.spawn_in(window, async move |ws, cx| {
            let text = cx.background_executor().spawn(async move { read_text(&path) }).await;
            let _ = ws.update_in(cx, |ws, window, cx| {
                let outcome = match &text {
                    Some((t, format, raw)) => ReadOutcome::Changed(text_hash(t), *format, *raw),
                    None => ReadOutcome::Unreadable,
                };
                // Fill the views at the doc's path now (P4-3-R1: not the path captured when the read started).
                if let ReadApply::Fill(now) = ws.group.docs.finish_read(token, outcome)
                    && let Some((text, _, _)) = &text
                {
                    ws.group.fill(&now, text, window, cx);
                }
                // The window reads `loaded` to lift read-only; redraw it.
                cx.notify();
            });
        })
        .detach();
        (o.ix, true)
    }

    /// Opens the Markdown preview tab of `path` in `pane` (L-69, `open_markdown`). Its hidden editor starts with the
    /// text of another view; a file still being read fills it with the rest (`fill`).
    pub fn open_preview(&mut self, pane: PaneId, path: &Path, window: &mut Window, cx: &mut Context<FolderWorkspace>) -> Option<usize> {
        let (ix, created) = self.open_markdown(pane, path, || Self::new_editor(window, cx))?;
        if created {
            let new = self.panes[&pane].tabs[ix].editor.clone();
            if let Some(text) = copy_source(self.views(path), &new).map(|src| src.read(cx).value()) {
                new.update(cx, |e, cx| e.set_value(text, window, cx));
            }
        }
        Some(ix)
    }

    /// A new editor with the text of tab `ix` of pane `from` (the copy of a Ctrl-drag, I-718).
    pub fn clone_view(&self, from: PaneId, ix: usize, window: &mut Window, cx: &mut Context<FolderWorkspace>) -> Option<Entity<EditorState>> {
        let text = self.panes.get(&from)?.tabs.get(ix)?.editor.read(cx).value();
        let editor = Self::new_editor(window, cx);
        editor.update(cx, |e, cx| e.set_value(text, window, cx));
        Some(editor)
    }

    /// Splits the active pane (Split Right/Left/Up/Down, I-707~I-711, I-731). A clone is a new editor with the
    /// active tab's text.
    pub fn split_active(&mut self, dir: SplitDirection, mode: SplitMode, window: &mut Window, cx: &mut Context<FolderWorkspace>) -> Option<PaneId> {
        let id = self.split(dir, mode, |tab| {
            let text = tab.editor.read(cx).value();
            let editor = Self::new_editor(window, cx);
            editor.update(cx, |e, cx| e.set_value(text, window, cx));
            editor
        });
        cx.notify();
        id
    }
}

/// Applies `new` to `view` as one replacement of the changed range, so its cursor and scroll stay put (the
/// selection is shifted past the change). `replace` records it in the view's undo history.
// shortcut: undo in the synced view also undoes the other view's edit (one shared change, two histories); a shared
// buffer would need its own undo model.
fn sync_view(view: &Entity<EditorState>, new: &str, window: &mut Window, cx: &mut App) {
    view.update(cx, |e, cx| {
        let old = e.value().to_string();
        let Some(cut) = splice(&old, new) else { return };
        let sel = e.selected_range();
        e.set_selected_range(cut.0..cut.1, cx);
        e.replace(new[cut.0..cut.2].to_string(), window, cx);
        e.set_selected_range(shift(sel.start, cut)..shift(sel.end, cut), cx);
    });
}

/// The view that gives a new view of an open file its text: any view other than `new` (all hold the same text).
pub fn copy_source<'a, E: PartialEq + 'a>(views: impl IntoIterator<Item = &'a E>, new: &E) -> Option<&'a E> {
    views.into_iter().find(|v| *v != new)
}

/// The views to bring to `text` after an edit in one view, from the other views and their texts. `None`: every other
/// view already holds `text`, so this is the echo of a sync and there is no edit to record (no dirty, no promotion).
pub fn sync_targets<'a, E, S: AsRef<str>>(text: &str, others: &'a [(E, S)]) -> Option<Vec<&'a E>> {
    if !others.is_empty() && others.iter().all(|(_, t)| t.as_ref() == text) {
        return None;
    }
    Some(others.iter().filter(|(_, t)| t.as_ref() != text).map(|(e, _)| e).collect())
}

/// Where byte offset `p` of the old text lands after `splice` replaced `start..old_end` with `start..new_end`: before
/// the change it stays, after it moves by the length difference, inside it goes to the end of the new part.
pub fn shift(p: usize, (start, old_end, new_end): (usize, usize, usize)) -> usize {
    if p <= start {
        p
    } else if p >= old_end {
        p - old_end + new_end
    } else {
        new_end
    }
}

#[cfg(test)]
mod tests {
    use super::super::metrics;
    use super::{
        Axis, DROP_OVERLAY_RATIO, DROP_TARGET_RATIO, MIN_DRAG_HEIGHT, MIN_DRAG_WIDTH, Node, PaneGroup, Path, Rect,
        SPLIT_HORIZONTAL, SPLIT_LINE_HITBOX, SPLIT_LINE_THICKNESS, SPLIT_VERTICAL, SplitDirection, SplitMode,
        copy_source, drag_divider, drop_overlay, drop_split, shift, split_button, splice, sync_targets,
    };
    use SplitDirection::{Down, Left, Right, Up};

    type G = PaneGroup<u32>;

    /// Opens `path` in the active pane with a fresh editor id.
    fn open(g: &mut G, path: &str, preview: bool) {
        let id = g.tab_count() as u32 + 100 * g.panes.len() as u32;
        g.open_in(g.active, Path::new(path), preview, || id);
    }

    fn names(g: &G, pane: u32) -> Vec<String> {
        g.panes[&pane].tabs.iter().map(|t| t.title()).collect()
    }

    fn clone(g: &mut G, dir: SplitDirection) -> Option<u32> {
        g.split(dir, SplitMode::Clone, |t| t.editor + 1000)
    }

    /// L-69: a preview is a second tab of the same file beside the editor tab; `find` still means the editor tab, a
    /// second request activates the preview, and the file stays open while either view is.
    #[test]
    fn markdown_preview_is_its_own_tab() {
        let mut g = G::default();
        open(&mut g, "a.md", false);
        assert_eq!(g.open_markdown(0, Path::new("b.md"), || 9), None, "the file must be open");
        assert_eq!(g.open_markdown(0, Path::new("a.md"), || 9), Some((1, true)));
        assert_eq!(g.panes[&0].find(Path::new("a.md")), Some(0));
        assert_eq!(g.panes[&0].find_preview(Path::new("a.md")), Some(1));
        g.panes.get_mut(&0).unwrap().active = Some(0);
        assert_eq!(g.open_markdown(0, Path::new("a.md"), || 10), Some((1, false)));
        assert_eq!(g.panes[&0].active, Some(1));
        assert_eq!(g.views(Path::new("a.md")).count(), 2, "the hidden editor is a view that stays in sync");
        g.close_view(0, 0);
        assert!(g.docs.find(Path::new("a.md")).is_some(), "the preview keeps the file");
        g.close_path(Path::new("a.md"));
        assert_eq!(g.tab_count(), 0);
    }

    /// I-718: a Ctrl-drop copies the tab to another pane and keeps the source; a pane that has the file only activates it.
    #[test]
    fn i718_copy_tab_view() {
        let mut g = G::default();
        open(&mut g, "a", false);
        open(&mut g, "b", false);
        let to = g.split(Right, SplitMode::Empty, |t| t.editor).unwrap();
        g.copy_tab_view(0, 1, to, 77);
        assert_eq!(names(&g, 0), ["a", "b"], "the source keeps its tab");
        assert_eq!(names(&g, to), ["b"]);
        assert_eq!(g.panes[&to].tabs[0].editor, 77);
        assert!(!g.panes[&to].tabs[0].preview);
        g.copy_tab_view(0, 1, to, 88);
        assert_eq!(names(&g, to), ["b"], "already there: no second view");
        g.copy_tab_view(0, 0, 0, 99);
        assert_eq!(names(&g, 0), ["a", "b"], "same pane: nothing");
    }

    /// P4-45-R1 (1, I-718): a copy lands by the plain add rule, after the target active tab and outside its pinned run,
    /// whatever the drop place a move would use; the source tab stays.
    #[test]
    fn copy_lands_after_the_active_tab_not_at_the_drop_place() {
        let mut g = G::default();
        open(&mut g, "a", false);
        let to = g.split(Right, SplitMode::Empty, |t| t.editor).unwrap();
        open(&mut g, "x", false);
        open(&mut g, "y", false);
        open(&mut g, "z", false);
        g.panes.get_mut(&to).unwrap().active = Some(0);
        g.copy_tab_view(0, 0, to, 55);
        assert_eq!(names(&g, to), ["x", "a", "y", "z"]);
        assert_eq!(g.panes[&to].active, Some(1));
        assert_eq!(names(&g, 0), ["a"], "the single source tab stays");
        // A pinned run is not entered: the active tab is pinned, the copy goes after the run.
        let mut g = G::default();
        open(&mut g, "a", false);
        let to = g.split(Right, SplitMode::Empty, |t| t.editor).unwrap();
        open(&mut g, "p", false);
        open(&mut g, "q", false);
        g.panes.get_mut(&to).unwrap().toggle_pin(0);
        g.panes.get_mut(&to).unwrap().active = Some(0);
        g.copy_tab_view(0, 0, to, 56);
        assert_eq!(names(&g, to), ["p", "a", "q"]);
    }

    /// P4-45-R1 (5): a dirty file keeps its doc, its editor handle and its dirty state when its last view moves to
    /// another pane; dropped onto a pane that already shows it, the dragged view goes and the doc keeps the edit state.
    #[test]
    fn dirty_view_moves_without_losing_state() {
        let mut g = G::default();
        open(&mut g, "a", false);
        let editor = g.panes[&0].tabs[0].editor;
        assert_eq!(g.on_edit(&editor, 123), Some("a".into()));
        assert!(g.docs.get(Path::new("a")).unwrap().dirty);
        let to = g.split(Right, SplitMode::Empty, |t| t.editor).unwrap();
        g.move_tab(0, 0, to, 0);
        assert_eq!(g.panes[&to].tabs[0].editor, editor, "the same editor handle");
        assert!(g.docs.get(Path::new("a")).unwrap().dirty, "still dirty");
        assert!(!g.panes.contains_key(&0), "the emptied pane goes");
        // Onto a pane that has the file: the other view stays, the doc is kept.
        let mut g = G::default();
        open(&mut g, "a", false);
        let dup = clone(&mut g, Right).unwrap();
        let first = g.panes[&0].tabs[0].editor;
        g.on_edit(&first, 7);
        g.move_tab(0, 0, dup, 0);
        assert_eq!(g.views(Path::new("a")).count(), 1);
        assert!(g.docs.get(Path::new("a")).unwrap().dirty, "the doc keeps the edit state");
    }

    /// P4-45-R2 (5): the read and save tokens belong to the doc, not to a pane, so a tab moved to another pane keeps
    /// them. The save started before the move completes on the right file (and no other), a read pending on the
    /// other file still lands on its own file, and a stale token changes nothing.
    #[test]
    fn tokens_and_state_survive_a_tab_move() {
        use crate::text_io::{Format, LineEnding, TextEncoding};
        use crate::ui::pane::{ReadApply, ReadOutcome, SaveStart, text_hash};
        let fmt = Some(Format { encoding: TextEncoding::Utf8, line_ending: LineEnding::Lf });
        let mut g = G::default();
        let read_a = g.open_in(0, Path::new("a"), false, || 1).unwrap().read.unwrap();
        let read_b = g.open_in(0, Path::new("b"), false, || 2).unwrap().read.unwrap();
        assert_eq!(g.docs.finish_read(read_a, ReadOutcome::Changed(text_hash("A"), fmt, 11)), ReadApply::Fill("a".into()));
        // Edit "a", start its save, and only then move both tabs to a new pane ("b" is still being read).
        assert_eq!(g.on_edit(&1, text_hash("A!")), Some("a".into()));
        let ia = g.docs.find(Path::new("a")).unwrap();
        let SaveStart::Write(save, _) = g.docs.begin_save(ia, "A!") else { panic!("a loaded and modified: it writes") };
        let to = g.split(Right, SplitMode::Empty, |t| t.editor).unwrap();
        g.move_tab(0, 0, to, 0);
        g.move_tab(0, 0, to, 1);
        assert_eq!(names(&g, to), ["a", "b"]);
        let (da, db) = (g.docs.get(Path::new("a")).unwrap(), g.docs.get(Path::new("b")).unwrap());
        assert_eq!((da.saving, da.dirty), (Some(save), true), "the save in flight is still a's");
        assert_eq!((db.pending, db.loaded), (Some(read_b), false), "the read in flight is still b's");
        // A stale token completes nothing; the real one clears a's save and leaves b alone.
        assert!(!g.docs.finish_save(save + 1000, true, text_hash("A!"), text_hash("A!")));
        assert!(g.docs.finish_save(save, true, text_hash("A!"), text_hash("A!")));
        let da = g.docs.get(Path::new("a")).unwrap();
        assert_eq!((da.saving, da.dirty, da.hash), (None, false, text_hash("A!")));
        let db = g.docs.get(Path::new("b")).unwrap();
        assert_eq!((db.pending, db.hash), (Some(read_b), text_hash("")), "b is untouched by a's save");
        // b's read, started before the move, applies to b in its new pane.
        assert_eq!(g.docs.finish_read(read_b, ReadOutcome::Changed(text_hash("B"), fmt, 22)), ReadApply::Fill("b".into()));
        let db = g.docs.get(Path::new("b")).unwrap();
        assert_eq!((db.loaded, db.hash), (true, text_hash("B")));
        assert_eq!(g.docs.get(Path::new("a")).unwrap().hash, text_hash("A!"), "and not to a");
    }

    /// P4-45-R1 (3, I-045): the editor tab for a preview is found in the preview pane first, then in any other pane;
    /// none when its source was closed.
    #[test]
    fn find_source_looks_in_other_panes() {
        let mut g = G::default();
        open(&mut g, "a.md", false);
        let side = g.split(Right, SplitMode::Empty, |t| t.editor).unwrap();
        assert_eq!(g.open_markdown(side, Path::new("a.md"), || 9), Some((0, true)));
        assert_eq!(g.find_source(Path::new("a.md"), side), Some((0, 0)), "source in the other pane");
        assert_eq!(g.find_source(Path::new("a.md"), 0), Some((0, 0)), "same pane first");
        g.close_view(0, 0);
        assert_eq!(g.find_source(Path::new("a.md"), side), None, "source closed");
    }

    /// P4-45-R1 (5, L-109): a preview hidden view is a view of the file, so an edit in the source reaches it.
    #[test]
    fn preview_view_is_a_sync_target() {
        let mut g = G::default();
        open(&mut g, "a.md", false);
        let source = g.panes[&0].tabs[0].editor;
        g.open_markdown(0, Path::new("a.md"), || 9);
        let others: Vec<(u32, &str)> = g.views(Path::new("a.md")).filter(|e| **e != source).map(|e| (*e, "old")).collect();
        assert_eq!(sync_targets("new", &others), Some(vec![&9]), "the preview view is brought to the new text");
    }

    /// I-707: popup order Right, Left, Up, Down; clone by default, move for an unsplittable item with ≥2 tabs, else off.
    #[test]
    fn i707_split_button_and_order() {
        assert_eq!(SplitDirection::POPUP, [Right, Left, Up, Down]);
        assert_eq!(split_button(1, Some(true)), Some(SplitMode::Clone));
        assert_eq!(split_button(2, Some(false)), Some(SplitMode::Move));
        assert_eq!(split_button(1, Some(false)), None);
        assert_eq!(split_button(0, None), None);
        let mut g = G::default();
        assert_eq!(g.split_button(), None, "empty pane: disabled");
        open(&mut g, "a", false);
        assert_eq!(g.split_button(), Some(SplitMode::Clone));
    }

    /// I-708: ClonePane puts a second view of the active tab (only) in the new pane; the source keeps its tabs; one
    /// file stays one doc. An empty pane makes nothing.
    #[test]
    fn i708_clone_pane_copies_active_item_only() {
        let mut g = G::default();
        assert_eq!(clone(&mut g, Right), None);
        assert_eq!(g.panes.len(), 1);
        open(&mut g, "a", false);
        open(&mut g, "b", false);
        let new = clone(&mut g, Right).unwrap();
        assert_eq!((names(&g, 0), names(&g, new)), (vec!["a".into(), "b".into()], vec!["b".into()]));
        assert_eq!(g.active, new);
        assert_eq!(g.docs.docs.len(), 2);
        assert_eq!(g.views(Path::new("b")).count(), 2);
        assert_ne!(g.panes[&new].tabs[0].editor, g.panes[&0].tabs[1].editor, "own editor per view");
    }

    /// I-709: EmptyPane opens an empty pane; MovePane moves the active tab; with ≤1 tab it opens an empty pane on
    /// the opposite side and keeps focus.
    #[test]
    fn i709_split_modes() {
        let mut g = G::default();
        open(&mut g, "a", false);
        let e = g.split(Right, SplitMode::Empty, |_| 0).unwrap();
        assert!(g.panes[&e].tabs.is_empty() && g.active == e);

        let mut g = G::default();
        open(&mut g, "a", false);
        open(&mut g, "b", false);
        let m = g.split(Right, SplitMode::Move, |_| 0).unwrap();
        assert_eq!((names(&g, 0), names(&g, m), g.active), (vec!["a".into()], vec!["b".into()], m));

        let mut g = G::default();
        open(&mut g, "a", false);
        let m = g.split(Right, SplitMode::Move, |_| 0).unwrap();
        assert_eq!(g.root, Node::Axis { axis: Axis::Horizontal, children: vec![Node::Pane(m), Node::Pane(0)], flexes: vec![1.; 2] });
        assert_eq!((g.active, names(&g, 0)), (0, vec!["a".into()]));
        assert_eq!(SplitMode::default(), SplitMode::Clone);
    }

    /// I-710: SplitHorizontal goes down, SplitVertical right (defaults).
    #[test]
    fn i710_horizontal_vertical_defaults() {
        assert_eq!((SPLIT_HORIZONTAL, SPLIT_VERTICAL), (Down, Right));
    }

    /// I-712: edge band min(w, h) × 0.2, its boundary is centre; I-713: nearest edge; an unsplittable pane is centre.
    #[test]
    fn i712_i713_drop_judgement() {
        // f32 0.2 is not exactly f64 0.2, so compare in f32 (assert_spec has no tolerance here).
        assert_eq!(metrics::spec::lookup("pane[\"drop_target_size_ratio\"]").unwrap().value as f32, DROP_TARGET_RATIO);
        // 800 × 600: d = 120.
        assert_eq!(drop_split(800., 600., 400., 300., true), None);
        assert_eq!(drop_split(800., 600., 120., 300., true), None, "boundary is centre");
        assert_eq!(drop_split(800., 600., 119., 300., true), Some(Left));
        assert_eq!(drop_split(800., 600., 690., 300., true), Some(Right));
        assert_eq!(drop_split(800., 600., 400., 10., true), Some(Up));
        assert_eq!(drop_split(800., 600., 400., 590., true), Some(Down));
        // Corner: the nearer edge wins, no corner quadrants.
        assert_eq!(drop_split(800., 600., 30., 10., true), Some(Up));
        assert_eq!(drop_split(800., 600., 10., 30., true), Some(Left));
        assert_eq!(drop_split(800., 600., 10., 30., false), None);
    }

    /// I-714: centre covers the body, a direction its half.
    #[test]
    fn i714_drop_overlay() {
        metrics::spec::assert_spec("pane[\"directional_drop_overlay_ratio\"]", "default", DROP_OVERLAY_RATIO);
        assert_eq!(drop_overlay(800., 600., None), Rect { x: 0., y: 0., w: 800., h: 600. });
        assert_eq!(drop_overlay(800., 600., Some(Right)), Rect { x: 400., y: 0., w: 400., h: 600. });
        assert_eq!(drop_overlay(800., 600., Some(Down)), Rect { x: 0., y: 300., w: 800., h: 300. });
    }

    /// I-715, I-716: on a tab: that place (reorder in the same pane, move to another); tab-bar end: last, no split.
    #[test]
    fn i715_i716_drop_on_tab_or_bar_end() {
        let mut g = G::default();
        for p in ["a", "b", "c"] {
            open(&mut g, p, false);
        }
        g.move_tab(0, 2, 0, 0);
        assert_eq!(names(&g, 0), ["c", "a", "b"]);
        let r = g.split(Right, SplitMode::Empty, |_| 0).unwrap();
        g.move_tab(0, 0, r, 0);
        g.move_tab(0, 0, r, g.panes[&r].tabs.len());
        assert_eq!((names(&g, 0), names(&g, r)), (vec!["b".into()], vec!["c".into(), "a".into()]));
        assert_eq!(g.panes.len(), 2);
    }

    /// I-717: centre moves into the pane after its active tab; edge makes a new pane with the tab; a dragged preview
    /// becomes normal; I-718: Ctrl copies (source keeps the tab).
    #[test]
    fn i717_i718_center_edge_and_copy() {
        let mut g = G::default();
        open(&mut g, "a", false);
        open(&mut g, "p", true);
        let r = g.split(Right, SplitMode::Empty, |_| 0).unwrap();
        g.drop_center(0, 1, r);
        assert_eq!(names(&g, r), ["p"]);
        assert!(!g.panes[&r].tabs[0].preview, "dragged preview is normal");
        let d = g.drop_split(r, 0, r, Down, None).unwrap();
        assert!(!g.panes.contains_key(&r), "emptied source pane goes");
        assert_eq!(names(&g, d), ["p"]);
        let c = g.drop_split(0, 0, 0, Left, Some(77)).unwrap();
        assert_eq!((names(&g, 0), names(&g, c), g.panes[&c].tabs[0].editor), (vec!["a".into()], vec!["a".into()], 77));
        assert_eq!(g.docs.docs.len(), 2);
    }

    /// I-719: in one pane, pinned follows the new place; I-720: to another pane, pinned in its pinned run or when a
    /// pinned tab lands first.
    #[test]
    fn i719_i720_pinned_by_place() {
        let mut g = G::default();
        for p in ["a", "b", "c"] {
            open(&mut g, p, false);
        }
        g.active_pane_mut().toggle_pin(0);
        g.move_tab(0, 2, 0, 0);
        assert_eq!((names(&g, 0), g.panes[&0].pinned_count), (vec!["c".into(), "a".into(), "b".into()], 2));
        g.move_tab(0, 0, 0, 2);
        assert_eq!((names(&g, 0), g.panes[&0].pinned_count), (vec!["a".into(), "b".into(), "c".into()], 1));
        let r = g.split(Right, SplitMode::Empty, |_| 0).unwrap();
        g.move_tab(0, 0, r, 0);
        assert_eq!(g.panes[&r].pinned_count, 1, "pinned tab first in the new pane stays pinned");
        g.move_tab(0, 0, r, 1);
        assert_eq!(g.panes[&r].pinned_count, 1, "a normal tab after the run stays normal");
        g.move_tab(0, 0, r, 0);
        assert_eq!(g.panes[&r].pinned_count, 2, "landing in the pinned run pins");
    }

    /// I-722 (model part): a dropped open is a normal tab, pinned when placed in the pinned run.
    #[test]
    fn i722_dropped_tab_is_normal_and_pins_in_run() {
        let mut p = super::Pane::<u32>::default();
        p.insert_at(super::Tab { path: "a".into(), preview: true, markdown: false, editor: 1, tool: None }, 0, false);
        p.toggle_pin(0);
        p.insert_at(super::Tab { path: "b".into(), preview: true, markdown: false, editor: 2, tool: None }, 0, false);
        assert_eq!((p.pinned_count, p.tabs[0].preview), (2, false));
    }

    /// I-723: Left/Right lay out horizontally, Up/Down vertically; same axis inserts a sibling, another axis wraps the
    /// leaf; Left/Up before, Right/Down after. I-724: the axis that got a sibling resets its flexes to 1.
    #[test]
    fn i723_i724_tree_shape_and_flex_reset() {
        let mut g = G::default();
        open(&mut g, "a", false);
        let r = clone(&mut g, Right).unwrap();
        g.activate(0);
        g.drag_divider(&[], 0, 100., 1000.);
        let l = clone(&mut g, Left).unwrap();
        assert_eq!(
            g.root,
            Node::Axis { axis: Axis::Horizontal, children: vec![Node::Pane(l), Node::Pane(0), Node::Pane(r)], flexes: vec![1.; 3] }
        );
        g.activate(r);
        let d = clone(&mut g, Down).unwrap();
        let Node::Axis { children, .. } = &g.root else { panic!() };
        assert_eq!(children[2], Node::Axis { axis: Axis::Vertical, children: vec![Node::Pane(r), Node::Pane(d)], flexes: vec![1.; 2] });
        let u = clone(&mut g, Up).unwrap();
        let Node::Axis { children, .. } = &g.root else { panic!() };
        assert_eq!(children[2], Node::Axis { axis: Axis::Vertical, children: vec![Node::Pane(r), Node::Pane(u), Node::Pane(d)], flexes: vec![1.; 3] });
        // No count limit.
        for _ in 0..20 {
            clone(&mut g, Right).unwrap();
        }
        assert_eq!(g.panes.len(), 25);
    }

    /// I-725: divider 1px, mouse area 4px.
    #[test]
    fn i725_divider_metrics() {
        metrics::spec::assert_spec("pane[\"split_line_thickness\"]", "default", f32::from(SPLIT_LINE_THICKNESS));
        metrics::spec::assert_spec("pane[\"split_line_mouse_hitbox\"]", "default", f32::from(SPLIT_LINE_HITBOX));
    }

    /// I-726: a drag stops each pane at the minimum and passes the rest on to the next one.
    #[test]
    fn i726_drag_respects_minimum_and_cascades() {
        metrics::spec::assert_spec("pane[\"min_drag_width\"]", "default", MIN_DRAG_WIDTH);
        metrics::spec::assert_spec("pane[\"min_drag_height\"]", "default", MIN_DRAG_HEIGHT);
        // Three panes of 300 on 900.
        let mut f = vec![1.; 3];
        drag_divider(&mut f, 0, 400., 900., &[80.; 3]);
        let px: Vec<f32> = f.iter().map(|f| (f * 300.).round()).collect();
        assert_eq!(px, [700., 80., 120.], "neighbour stops at 80, the next one gives the rest");
        drag_divider(&mut f, 0, 1000., 900., &[80.; 3]);
        let px: Vec<f32> = f.iter().map(|f| (f * 300.).round()).collect();
        assert_eq!(px, [740., 80., 80.], "nothing left to give");
        let mut f = vec![1.; 2];
        drag_divider(&mut f, 0, -100., 600., &[100.; 2]);
        assert_eq!(f.iter().map(|f| f * 300.).collect::<Vec<_>>(), [200., 400.]);
        let mut g = G::default();
        open(&mut g, "a", false);
        clone(&mut g, Down);
        g.drag_divider(&[], 0, -250., 400.);
        let Node::Axis { flexes, .. } = &g.root else { panic!() };
        assert_eq!(flexes.iter().map(|f| f * 200.).collect::<Vec<_>>(), [100., 300.], "stacked minimum is 100");
    }

    /// P4-3-R1 (3): a nested subtree shrinks only to what its panes need: Horizontal[A, Vertical[B, Horizontal[C, D]]]
    /// needs 160 px for the right side (C and D at 80 each), and across axes the largest child counts.
    #[test]
    fn i726_nested_subtree_minimum() {
        let mut g = G::default();
        open(&mut g, "a", false);
        clone(&mut g, Right).unwrap();
        clone(&mut g, Down).unwrap();
        clone(&mut g, Right).unwrap();
        // Root: Horizontal[A, Vertical[B, Horizontal[C, D]]].
        g.drag_divider(&[], 0, 370., 900.);
        let Node::Axis { flexes, children, .. } = &g.root else { panic!() };
        assert_eq!(flexes.iter().map(|f| (f * 450.).round()).collect::<Vec<_>>(), [740., 160.]);
        assert_eq!(children[1].min_len(Axis::Horizontal), 160.);
        assert_eq!(children[1].min_len(Axis::Vertical), 200., "stacked B over C|D: 100 + 100");
        // Vertical drag of the right column: the lower row (C|D) keeps 100 px high, the rest goes nowhere.
        g.drag_divider(&[1], 0, 500., 600.);
        let Node::Axis { children, .. } = &g.root else { panic!() };
        let Node::Axis { flexes, .. } = &children[1] else { panic!() };
        assert_eq!(flexes.iter().map(|f| (f * 300.).round()).collect::<Vec<_>>(), [500., 100.]);
        // What a subtree at its minimum cannot give passes on to the next child (middle child: a subtree needing 160).
        let mut f = vec![1.; 3];
        drag_divider(&mut f, 0, 400., 900., &[80., 160., 80.]);
        assert_eq!(f.iter().map(|f| (f * 300.).round()).collect::<Vec<_>>(), [660., 160., 80.]);
    }

    /// Every leaf of `g` laid out in `w` × `h` is at least 80 px wide and 100 px high (I-726).
    fn assert_leaf_minimums(g: &G, w: f32, h: f32) {
        for (id, r) in g.rects(Rect { x: 0., y: 0., w, h }) {
            assert!(r.w >= MIN_DRAG_WIDTH - 0.01 && r.h >= MIN_DRAG_HEIGHT - 0.01, "pane {id}: {r:?}");
        }
    }

    /// P4-3-R2: an inner axis made uneven first keeps its ratio when the outer divider shrinks it, so the outer drag stops
    /// where the smaller inner pane reaches its minimum. Horizontal[A, Vertical[B, Horizontal[C, D]]] with C:D = 90:360
    /// (flex 0.4:1.6) needs 80 / 0.2 = 400 px on the right; then the mirrored stacked case.
    #[test]
    fn i726_outer_drag_keeps_uneven_inner_minimum() {
        let mut g = G::default();
        open(&mut g, "a", false);
        clone(&mut g, Right).unwrap();
        clone(&mut g, Down).unwrap();
        clone(&mut g, Right).unwrap();
        g.drag_divider(&[1, 1], 0, -135., 450.);
        let Node::Axis { children, .. } = &g.root else { panic!() };
        assert_eq!(children[1].min_len(Axis::Horizontal), 400.);
        g.drag_divider(&[], 0, 370., 900.);
        let Node::Axis { flexes, .. } = &g.root else { panic!() };
        assert_eq!(flexes.iter().map(|f| (f * 450.).round()).collect::<Vec<_>>(), [500., 400.]);
        assert_leaf_minimums(&g, 900., 600.);
        let c = g.rects(Rect { x: 0., y: 0., w: 900., h: 600. })[2].1;
        assert_eq!(c.w.round(), 80., "C ends exactly at its minimum");

        // Vertical[A, Horizontal[B, Vertical[C, D]]], 800 high: C:D = 150:250 needs 100 / 0.375 ≈ 266.7 px below.
        let mut g = G::default();
        open(&mut g, "a", false);
        clone(&mut g, Down).unwrap();
        clone(&mut g, Right).unwrap();
        clone(&mut g, Down).unwrap();
        g.drag_divider(&[1, 1], 0, -50., 400.);
        g.drag_divider(&[], 0, 300., 800.);
        let Node::Axis { flexes, .. } = &g.root else { panic!() };
        assert_eq!(flexes.iter().map(|f| (f * 400.).round()).collect::<Vec<_>>(), [533., 267.]);
        assert_leaf_minimums(&g, 900., 800.);
    }

    /// I-727: double-click equalizes only that axis.
    #[test]
    fn i727_equalize_one_axis() {
        let mut g = G::default();
        open(&mut g, "a", false);
        let r = clone(&mut g, Right).unwrap();
        clone(&mut g, Down);
        g.activate(r);
        g.drag_divider(&[], 0, 100., 1000.);
        g.drag_divider(&[1], 0, 50., 800.);
        g.equalize(&[]);
        let Node::Axis { flexes, children, .. } = &g.root else { panic!() };
        assert_eq!(flexes, &vec![1.; 2]);
        let Node::Axis { flexes: inner, .. } = &children[1] else { panic!() };
        assert_ne!(inner, &vec![1.; 2], "nested axis keeps its ratio");
    }

    /// I-728, I-735: closing a pane's last tab removes the pane and collapses a one-child axis with its ratio reset;
    /// the root pane stays (empty editor area). Closing one of two views keeps the file.
    #[test]
    fn i728_empty_pane_removed_root_stays() {
        let mut g = G::default();
        open(&mut g, "a", false);
        let r = clone(&mut g, Right).unwrap();
        assert!(g.close_view(r, 0).is_some());
        assert!(!g.panes.contains_key(&r));
        assert_eq!((g.root.clone(), g.active), (Node::Pane(0), 0));
        assert_eq!(g.docs.docs.len(), 1, "the other view keeps the file");
        g.close_view(0, 0);
        assert_eq!((g.root.clone(), g.panes.len(), g.docs.docs.len()), (Node::Pane(0), 1, 0));

        let mut g = G::default();
        open(&mut g, "a", false);
        let b = clone(&mut g, Right).unwrap();
        let c = clone(&mut g, Down).unwrap();
        g.zoomed = Some(c);
        g.close_view(c, 0);
        assert_eq!(g.zoomed, None);
        assert_eq!(g.root, Node::Axis { axis: Axis::Horizontal, children: vec![Node::Pane(0), Node::Pane(b)], flexes: vec![1.; 2] });
    }

    /// I-730, I-737: zoom toggles the active pane.
    #[test]
    fn i730_zoom_toggles_active_pane() {
        let mut g = G::default();
        open(&mut g, "a", false);
        let r = clone(&mut g, Right).unwrap();
        g.toggle_zoom();
        assert_eq!(g.zoomed, Some(r));
        g.toggle_zoom();
        assert_eq!(g.zoomed, None);
    }

    /// I-731: Split Right etc. clone by default (I-711 menus use the same default).
    #[test]
    fn i731_split_keys_clone_by_default() {
        let mut g = G::default();
        open(&mut g, "a", false);
        let r = g.split(Right, SplitMode::default(), |t| t.editor + 1).unwrap();
        assert_eq!(names(&g, r), ["a"]);
    }

    /// I-732: focus moves to the neighbour toward the arrow; none at the group edge.
    #[test]
    fn i732_focus_in_direction() {
        let mut g = G::default();
        open(&mut g, "a", false);
        let r = clone(&mut g, Right).unwrap();
        let d = clone(&mut g, Down).unwrap();
        assert_eq!(g.pane_in_direction(Up), Some(r));
        assert_eq!(g.pane_in_direction(Left), Some(0));
        assert_eq!(g.pane_in_direction(Right), None);
        g.activate(0);
        let right = g.pane_in_direction(Right);
        assert!(right == Some(r) || right == Some(d), "the right column");
        assert_eq!(g.pane_in_direction(Down), None);
    }

    /// I-734: Ctrl+Shift+PageUp/PageDown move the tab within the pane.
    #[test]
    fn i734_move_tab_left_right() {
        let mut g = G::default();
        for p in ["a", "b", "c"] {
            open(&mut g, p, false);
        }
        g.active_pane_mut().reorder(2, 1);
        assert_eq!((names(&g, 0), g.panes[&0].active), (vec!["a".into(), "c".into(), "b".into()], Some(1)));
    }

    /// I-062 per pane: each pane has its own preview tab; replacing one forgets its file unless another view shows it.
    #[test]
    fn preview_per_pane_and_doc_lifetime() {
        let mut g = G::default();
        open(&mut g, "a", true);
        let r = clone(&mut g, Right).unwrap();
        open(&mut g, "b", true);
        assert_eq!((names(&g, 0), names(&g, r)), (vec!["a".into()], vec!["a".into(), "b".into()]));
        g.activate(0);
        open(&mut g, "c", true);
        assert_eq!(names(&g, 0), ["c"]);
        assert!(g.docs.get(Path::new("a")).is_some(), "still shown in the right pane");
        g.activate(r);
        open(&mut g, "d", true);
        assert!(g.docs.get(Path::new("b")).is_none(), "replaced preview forgets its file");
    }

    /// I-063 across views: an edit promotes the edited view and marks the file dirty for all views.
    #[test]
    fn edit_promotes_view_and_dirties_file() {
        let mut g = G::default();
        open(&mut g, "a", true);
        let editor = g.panes[&0].tabs[0].editor;
        let token = g.docs.docs[0].pending.unwrap();
        g.docs.finish_read(token, super::ReadOutcome::Changed(super::text_hash("A"), None, 1));
        assert_eq!(g.on_edit(&editor, super::text_hash("AB")), Some("a".into()));
        assert!(!g.panes[&0].tabs[0].preview && g.docs.docs[0].dirty);
    }

    /// P3-3 across panes: a dirty file shown twice closes one view without a question, the last view asks; the exit
    /// flow sees the file once (`paths`).
    #[test]
    fn close_question_only_for_last_view() {
        use super::CloseState;
        let mut g = G::default();
        open(&mut g, "a", false);
        let token = g.docs.docs[0].pending.unwrap();
        g.docs.finish_read(token, super::ReadOutcome::Changed(super::text_hash("A"), None, 1));
        let editor = g.panes[&0].tabs[0].editor;
        g.on_edit(&editor, super::text_hash("AB"));
        let r = clone(&mut g, Right).unwrap();
        let a = Path::new("a");
        assert_eq!(g.close_state(a), CloseState::Clean);
        assert_eq!(g.paths().len(), 1);
        g.close_view(r, 0);
        assert_eq!(g.close_state(a), CloseState::Ask);
    }

    /// E-085 give-up closes every view; rename reaches docs and all panes.
    #[test]
    fn close_path_and_rename_reach_all_views() {
        let mut g = G::default();
        open(&mut g, "d/a", false);
        let r = clone(&mut g, Right).unwrap();
        g.rename_path(Path::new("d"), Path::new("e"));
        assert_eq!(g.views(Path::new("e/a")).count(), 2);
        assert!(g.docs.get(Path::new("e/a")).is_some());
        g.close_path(Path::new("e/a"));
        // The last pane left is the root and stays (I-728).
        assert_eq!((g.tab_count(), g.docs.docs.len(), g.panes.len()), (0, 0, 1));
        let _ = r;
    }

    /// P4-3-R1 (1): a file shown in panes 0 and 2 opened in pane 1 (between them in id order) copies into the new view
    /// from an existing one, whatever the order.
    #[test]
    fn third_view_in_middle_pane_copies_from_existing() {
        let mut g = G::default();
        open(&mut g, "a", false);
        let mid = g.split(Right, SplitMode::Empty, |_| 0).unwrap();
        g.activate(0);
        let last = clone(&mut g, Right).unwrap();
        assert!(mid < last);
        g.activate(mid);
        let o = g.open_in(mid, Path::new("a"), false, || 555).unwrap();
        assert_eq!((o.created, o.read), (true, None));
        let new = g.panes[&mid].tabs[o.ix].editor;
        assert_eq!(new, 555);
        assert_eq!(g.views(Path::new("a")).copied().collect::<Vec<_>>(), [g.panes[&0].tabs[0].editor, 555, g.panes[&last].tabs[0].editor]);
        let src = *copy_source(g.views(Path::new("a")), &new).unwrap();
        assert!(src != new && (src == g.panes[&0].tabs[0].editor || src == g.panes[&last].tabs[0].editor));
        assert_eq!(copy_source([1, 2].iter(), &1), Some(&2));
        assert_eq!(copy_source([1].iter(), &1), None);
    }

    /// P4-3-R1 (4, H-9): an edit syncs only the views that differ; the sync's echo (all equal) records nothing; a single
    /// view is a plain edit.
    #[test]
    fn sync_targets_and_echo() {
        assert_eq!(sync_targets::<u32, &str>("AB", &[]), Some(vec![]), "one view: a plain edit");
        assert_eq!(sync_targets("AB", &[(1, "A"), (2, "A")]), Some(vec![&1, &2]));
        assert_eq!(sync_targets("AB", &[(1, "AB"), (2, "A")]), Some(vec![&2]), "a third view still behind");
        assert_eq!(sync_targets("AB", &[(1, "AB"), (2, "AB")]), None, "echo of a sync");
    }

    /// P4-3-R1 (4): the synced view's selection moves with the change.
    #[test]
    fn selection_shift_after_splice() {
        let cut = splice("hello world", "hello big world").unwrap();
        assert_eq!(cut, (6, 6, 10));
        assert_eq!((shift(3, cut), shift(6, cut), shift(8, cut)), (3, 6, 12));
        let cut = splice("abcdef", "abXf").unwrap();
        assert_eq!((shift(3, cut), shift(6, cut)), (3, 4), "inside the change goes to its end");
    }

    /// phase3-final Must fix 2 in the pane tree: a preview whose non-empty file was deleted is promoted, not replaced, by
    /// the next preview open; an empty deleted preview, a clean preview, and a kept file's other view are replaced.
    #[test]
    fn deleted_nonempty_preview_is_kept() {
        use super::ReadOutcome;
        let read = |g: &mut G, text: &str| {
            let t = g.docs.docs.last().unwrap().pending.unwrap();
            g.docs.finish_read(t, ReadOutcome::Changed(super::text_hash(text), None, 1));
        };
        let missing = |g: &mut G, path: &str| {
            let ix = g.docs.find(Path::new(path)).unwrap();
            let t = g.docs.start_read(ix);
            g.docs.finish_read(t, ReadOutcome::Missing);
        };
        let mut g = G::default();
        open(&mut g, "a", true);
        read(&mut g, "A");
        missing(&mut g, "a");
        open(&mut g, "b", true);
        let tabs: Vec<_> = g.panes[&0].tabs.iter().map(|t| (t.title(), t.preview)).collect();
        assert_eq!(tabs, [("a".to_string(), false), ("b".to_string(), true)]);
        assert!(g.docs.get(Path::new("a")).is_some_and(|d| d.deleted && d.modified()));

        let mut g = G::default();
        open(&mut g, "e", true);
        read(&mut g, "");
        missing(&mut g, "e");
        open(&mut g, "c", true);
        assert_eq!(names(&g, 0), ["c"], "empty deleted preview is replaced");
        open(&mut g, "d", true);
        assert_eq!(names(&g, 0), ["d"], "clean preview is replaced");

        // The file shown in another pane too: this preview view can go, the other view keeps the buffer.
        let mut g = G::default();
        open(&mut g, "a", true);
        read(&mut g, "A");
        missing(&mut g, "a");
        let r = g.split(Right, SplitMode::Clone, |t| t.editor + 1).unwrap();
        g.activate(0);
        open(&mut g, "b", true);
        assert_eq!((names(&g, 0), names(&g, r)), (vec!["b".into()], vec!["a".into()]));
    }

    /// The splice between two views' texts covers only the changed bytes, on char boundaries.
    #[test]
    fn splice_is_minimal_and_char_safe() {
        assert_eq!(splice("abc", "abc"), None);
        assert_eq!(splice("abc", "abXc"), Some((2, 2, 3)));
        assert_eq!(splice("abc", "ac"), Some((1, 2, 1)));
        assert_eq!(splice("aa", "aaa"), Some((2, 2, 3)));
        // "가" and "각" share their first two UTF-8 bytes.
        assert_eq!(splice("가", "각"), Some((0, 3, 3)));
        let (s, oe, ne) = splice("x가y", "x각y").unwrap();
        assert_eq!((&"x가y"[s..oe], &"x각y"[s..ne]), ("가", "각"));
    }
}

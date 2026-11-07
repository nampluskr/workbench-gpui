//! I-10: one pane's back/forward navigation history. Pure state, no gpui.
//! Rules from Zed (read only): `crates/workspace/src/pane.rs` `NavHistory::push` / `pop`, `crates/editor/src/navigation.rs`
//! `push_to_nav_history`, `crates/workspace/src/workspace.rs` `navigate_history_impl`.

use std::collections::VecDeque;
use std::path::PathBuf;

/// Zed `MAX_NAVIGATION_HISTORY_LEN`; the oldest entry goes first. The value is the tauri app's confirmed one (SPEC R-10).
pub const MAX_NAVIGATION_HISTORY_LEN: usize = 1024;
/// Zed `MIN_NAVIGATION_HISTORY_ROW_DELTA` (`editor.rs:307`): a cursor move inside one file is recorded from this many rows.
pub const MIN_NAVIGATION_HISTORY_ROW_DELTA: usize = 10;

/// A place: a file and a cursor position (0-based row, column in characters).
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct NavEntry {
    pub path: PathBuf,
    pub row: usize,
    pub col: usize,
}

impl NavEntry {
    /// Zed's `is_same_location`: the same file and row.
    fn same_place(&self, other: &NavEntry) -> bool {
        self.path == other.path && self.row == other.row
    }
}

#[derive(Debug, Default)]
pub struct NavHistory {
    back: VecDeque<NavEntry>,
    forward: VecDeque<NavEntry>,
    /// Where the pane's active editor tab was last seen; the entry recorded when it is left or the cursor jumps away.
    here: Option<NavEntry>,
    /// A place being navigated to whose tab is still loading; the cursor moves there once the text is in.
    /// While it is set, what the pane shows is not observed (a go back must not record itself).
    pub pending: Option<NavEntry>,
}

/// Zed `NavHistory::push`: an entry for the same place is replaced, the oldest is dropped at the limit.
fn push_into(stack: &mut VecDeque<NavEntry>, entry: NavEntry) {
    stack.retain(|e| !e.same_place(&entry));
    if stack.len() >= MAX_NAVIGATION_HISTORY_LEN {
        stack.pop_front();
    }
    stack.push_back(entry);
}

impl NavHistory {
    pub fn can_go_back(&self) -> bool {
        !self.back.is_empty()
    }

    pub fn can_go_forward(&self) -> bool {
        !self.forward.is_empty()
    }

    /// A new place was left behind: it goes on the back stack and the forward stack is cleared (Zed, normal mode).
    fn record(&mut self, entry: NavEntry) {
        push_into(&mut self.back, entry);
        self.forward.clear();
    }

    /// What the pane shows now (its active editor tab and cursor, none for a tool tab or an empty pane). Leaving a tab
    /// records its last cursor (Zed `Item::deactivated`); a move inside the file records the place it left only when it
    /// is `MIN_NAVIGATION_HISTORY_ROW_DELTA` rows or more. Edits move the cursor the same way and follow the same rule
    /// (Zed treats a selection change from an edit like any other).
    pub fn observe(&mut self, now: Option<NavEntry>) {
        match (self.here.take(), now) {
            (Some(old), now) => {
                let left = match &now {
                    None => true,
                    Some(n) => old.path != n.path || n.row.abs_diff(old.row) >= MIN_NAVIGATION_HISTORY_ROW_DELTA,
                };
                if left {
                    self.record(old);
                }
                self.here = now;
            }
            (None, now) => self.here = now,
        }
    }

    /// An explicit jump to `target` (a search result): the place left is recorded whatever the distance, unless the
    /// jump stays on the same row (Zed `always: true` still skips a zero row delta).
    pub fn jump(&mut self, target: &NavEntry) {
        if let Some(here) = self.here.clone().filter(|h| !h.same_place(target)) {
            self.record(here);
        }
    }

    /// Go back (or forward): the entry to move to. The place the pane is at goes on the opposite stack, and the move
    /// itself is not recorded. An entry for the place the pane is already at, or one `usable` rejects (its file is gone),
    /// is skipped and dropped (Zed tries the next entry when nothing was navigated). `pending` is set to the target.
    pub fn step(&mut self, forward: bool, mut usable: impl FnMut(&NavEntry) -> bool) -> Option<NavEntry> {
        loop {
            let entry = if forward { self.forward.pop_back() } else { self.back.pop_back() }?;
            if self.here.as_ref().is_some_and(|h| h.same_place(&entry)) || !usable(&entry) {
                continue;
            }
            if let Some(here) = self.here.take() {
                push_into(if forward { &mut self.back } else { &mut self.forward }, here);
            }
            self.here = Some(entry.clone());
            self.pending = Some(entry.clone());
            return Some(entry);
        }
    }

    /// The pending move is done at `at` (the position the cursor really took, clamped to the text).
    pub fn arrived(&mut self, at: NavEntry) {
        self.pending = None;
        self.here = Some(at);
    }
}

/// 0-based row and character column of byte `offset` in `text`.
pub fn position_of(text: &str, offset: usize) -> (usize, usize) {
    let before = text.get(..offset.min(text.len())).unwrap_or("");
    let row = before.matches('\n').count();
    let col = before.rsplit('\n').next().map_or(0, |line| line.chars().count());
    (row, col)
}

/// Byte offset of (`row`, `col`) in `text`; a row past the end goes to the end, a column past the line to its end.
pub fn offset_of(text: &str, row: usize, col: usize) -> usize {
    let mut start = 0;
    for (i, line) in text.split('\n').enumerate() {
        if i == row {
            let line = line.strip_suffix('\r').unwrap_or(line);
            return start + line.char_indices().nth(col).map_or(line.len(), |(at, _)| at);
        }
        start += line.len() + 1;
    }
    text.len()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn at(path: &str, row: usize) -> NavEntry {
        NavEntry { path: path.into(), row, col: 0 }
    }

    /// A pane with a cursor, driven the way the app drives it: `observe` after every change, keys call `step`.
    struct Pane {
        nav: NavHistory,
        now: Option<NavEntry>,
    }

    impl Pane {
        fn new(path: &str, row: usize, col: usize) -> Self {
            let mut p = Pane { nav: NavHistory::default(), now: Some(NavEntry { path: path.into(), row, col }) };
            p.nav.observe(p.now.clone());
            p
        }
        fn open(&mut self, path: &str) {
            self.now = Some(at(path, 0));
            self.nav.observe(self.now.clone());
        }
        fn goto(&mut self, row: usize, explicit: bool) {
            let path = self.now.as_ref().unwrap().path.clone();
            let target = NavEntry { path, row, col: 0 };
            if explicit {
                self.nav.jump(&target);
            }
            self.now = Some(target);
            self.nav.observe(self.now.clone());
        }
        fn key(&mut self, forward: bool) {
            if let Some(e) = self.nav.step(forward, |_| true) {
                self.nav.arrived(e.clone());
                self.now = Some(e);
            }
        }
        fn shown(&self) -> (String, usize) {
            let n = self.now.as_ref().unwrap();
            (n.path.display().to_string(), n.row + 1)
        }
    }

    /// SPEC R-10: the nine steps captured in Zed (rows are 1-based there, 0-based here).
    #[test]
    fn k35_the_nine_zed_steps() {
        let mut p = Pane::new("AGENTS.md", 4, 22);
        p.open("App.tsx");
        assert_eq!(p.shown(), ("App.tsx".into(), 1));
        p.goto(65, true); // Go to Line 66
        assert_eq!(p.shown(), ("App.tsx".into(), 66));
        p.key(false);
        assert_eq!(p.shown(), ("App.tsx".into(), 1));
        p.key(false);
        assert_eq!(p.now, Some(NavEntry { path: "AGENTS.md".into(), row: 4, col: 22 }));
        p.key(true);
        assert_eq!(p.shown(), ("App.tsx".into(), 1));
        p.key(true);
        assert_eq!(p.shown(), ("App.tsx".into(), 66));
        p.goto(74, false); // Ctrl-End: 9 rows, not recorded
        assert_eq!(p.shown(), ("App.tsx".into(), 75));
        p.key(false);
        assert_eq!(p.shown(), ("App.tsx".into(), 1), "not row 66");
    }

    #[test]
    fn k35_ten_rows_are_recorded_nine_are_not() {
        let mut p = Pane::new("a", 0, 0);
        p.goto(9, false);
        assert!(!p.nav.can_go_back());
        p.goto(19, false); // 10 rows from row 9
        assert!(p.nav.can_go_back());
        p.key(false);
        assert_eq!(p.shown(), ("a".into(), 10), "back to where the 10-row move started");
    }

    #[test]
    fn k35_explicit_jump_is_recorded_at_any_distance_but_not_on_the_same_row() {
        let mut p = Pane::new("a", 3, 0);
        p.goto(3, true);
        assert!(!p.nav.can_go_back());
        p.goto(5, true);
        assert!(p.nav.can_go_back());
    }

    #[test]
    fn k35_a_new_place_clears_the_forward_stack() {
        let mut p = Pane::new("a", 0, 0);
        p.open("b");
        p.key(false);
        assert!(p.nav.can_go_forward());
        p.open("c");
        assert!(!p.nav.can_go_forward());
        assert!(p.nav.can_go_back());
    }

    #[test]
    fn k35_the_stack_is_capped_and_the_same_place_is_kept_once() {
        let mut p = Pane::new("f0", 0, 0);
        for i in 1..=MAX_NAVIGATION_HISTORY_LEN + 5 {
            p.open(&format!("f{i}"));
        }
        assert_eq!(p.nav.back.len(), MAX_NAVIGATION_HISTORY_LEN);
        assert_eq!(p.nav.back.front().unwrap().path, PathBuf::from("f5"), "the oldest were dropped");
        let mut q = Pane::new("a", 0, 0);
        q.open("b");
        q.open("a");
        q.open("b");
        q.open("a");
        assert_eq!(q.nav.back.len(), 2, "a and b once each");
    }

    #[test]
    fn k35_a_missing_file_is_skipped_to_the_next_entry() {
        let mut p = Pane::new("a", 0, 0);
        p.open("gone");
        p.open("c");
        let entry = p.nav.step(false, |e| e.path.as_os_str() != "gone").unwrap();
        assert_eq!(entry.path, PathBuf::from("a"));
        assert_eq!(p.nav.pending, Some(entry));
        assert!(!p.nav.can_go_back(), "the missing entry is dropped");
    }

    /// A closed tab's entry stays: going back returns it (the app reopens the file from the path).
    #[test]
    fn k35_closed_tab_entries_stay() {
        let mut p = Pane::new("a", 7, 2);
        p.open("b"); // a closed later: nothing removes its entry
        let back = p.nav.step(false, |_| true).unwrap();
        assert_eq!(back, NavEntry { path: "a".into(), row: 7, col: 2 });
    }

    #[test]
    fn k35_leaving_for_a_tool_tab_records_and_coming_back_does_not() {
        let mut p = Pane::new("a", 2, 0);
        p.nav.observe(None);
        assert!(p.nav.can_go_back());
        let before = p.nav.back.len();
        p.nav.observe(Some(at("a", 2)));
        assert_eq!(p.nav.back.len(), before);
    }

    #[test]
    fn k35_positions_convert_both_ways_and_clamp() {
        let text = "ab\r\ncd한\nlast";
        assert_eq!(position_of(text, 0), (0, 0));
        let han = text.find('한').unwrap();
        assert_eq!(position_of(text, han), (1, 2));
        assert_eq!(offset_of(text, 1, 2), han);
        assert_eq!(offset_of(text, 0, 99), 2, "column past the line end stops before the CR");
        assert_eq!(offset_of(text, 99, 0), text.len(), "row past the end goes to the end");
        assert_eq!(offset_of(text, 2, 0), text.find("last").unwrap());
    }
}

//! 최소 탭 (v0.2 Phase 4, SPEC R-27, DECISIONS D-9·D-18). 폴더(Workspace)마다 Pane 트리를 둔다(A-15.1; P4-3 `pane_group`).
//!
//! - 트리에서 임시(preview)로 열거나 일반 탭으로 연다(I-087, I-033, I-061).
//! - 임시 탭은 하나다. 다른 파일을 임시로 열면 그 자리(인덱스)에서 바꾼다(I-062).
//! - 이미 임시로 열린 파일을 일반으로 열면 일반 탭이 된다(I-063).
//! - Preview, normal and pinned are separate states (I-060): a pinned tab is never a preview. Pinned tabs are the
//!   first `pinned_count` tabs (I-065, I-719); new tabs never go inside that run. Edits, a tab double-click
//!   (`promote`) or a non-preview open make a preview tab normal (I-063); pinning also does, but promoting never
//!   pins (I-065). Normal closes (Ctrl+W, Ctrl+F4, middle click) skip pinned tabs (`close_protected`, I-066).
//! - 새 탭은 활성 탭 바로 뒤에 넣는다(판단: Zed 의 새 항목 자리).
//! - Tabs are editable (v0.4 D-6, P3-1; D-18 lifted). A tab is dirty when its buffer differs from the content last
//!   read from disk (`hash`). An edit promotes a preview tab to a normal tab (I-063). The editor stays read-only
//!   until the first read lands, so typing cannot race the load. Dirty buffers are not reloaded; a disk change marks
//!   them as conflicts and a removed file marks any tab deleted (P3-4a, E-086, E-087; `Tab::has_conflict`, `deleted`).
//! - Reads detect the encoding (`text_io`, P3-2) and saves write it back unchanged (BOM, UTF-16, CP949; line endings
//!   stay in the text). An undecodable file is shown lossily and stays read-only, so a save cannot corrupt it.
//! - First open reads the file on the background executor; the tab exists at once and gets its text when
//!   the read finishes (v0.4 P1-3, AUDIT 4). First read and watch reload share one request token per tab:
//!   only the latest started read applies, and a closed pane (folder removed) applies nothing.
//! - P4-3: a file's disk and edit state is one `Doc` per path in the workspace (`Docs`); a `Tab` is one view of it in
//!   a `Pane`. Several panes can show the same file (ClonePane, I-708); each view has its own editor and they are
//!   kept equal (`pane_group`). The pane tree is `pane_group::PaneGroup`.

use std::path::{Path, PathBuf};

use gpui_kit::base::Scrollbar;
use gpui_kit::prelude::FluentBuilder as _;
use gpui_kit::base::input::EditorScrollbarContext;
use gpui_kit::component::input::{Editor, EditorState};
use gpui_kit::*;

use super::metrics;
use super::tab_close::End;
use crate::text_io::{self, Format};

/// One view of a file in a pane. `E` is the editor handle; generic only so tab bookkeeping is testable without a window.
pub struct Tab<E = Entity<EditorState>> {
    pub path: PathBuf,
    pub preview: bool,
    /// A rendered Markdown preview of `path` (L-69), not a second editor of it: its `editor` is a hidden view kept
    /// equal to the file like any other view, and the tab draws that text rendered. Never a preview tab (I-064).
    pub markdown: bool,
    pub editor: E,
    /// Non-file tool content and its keyboard focus; never part of Docs or disk I/O.
    pub tool: Option<(AnyView, FocusHandle)>,
}

/// The disk and edit state of one open file, shared by all its views (P4-3).
pub struct Doc {
    pub path: PathBuf,
    /// 편집기에 넣은 내용의 해시(`text_hash`). 감시가 다시 읽은 내용과 비교한다(Phase 5 리뷰 1회차 ⑤, D-046).
    /// Hash of the content last read from disk; the buffer may differ once edited (`dirty`). While the first read is
    /// pending the editor is empty, so this is `text_hash("")`.
    pub hash: u64,
    /// Token of the latest started read (first read or reload) not yet applied.
    pub pending: Option<u64>,
    /// The buffer differs from `hash` (P3-1).
    pub dirty: bool,
    /// A read has landed with a known encoding, so the buffer holds the file; editing and saving only then.
    pub loaded: bool,
    /// Encoding and line ending of the last accepted read; saves write them back (P3-2, P3-12-R1).
    /// `None`: not read yet or undecodable.
    pub format: Option<Format>,
    /// Token of the save in flight; a second save waits until it finishes. Reads do not apply while it runs.
    pub saving: Option<u64>,
    /// Hash of the raw file bytes at the last accepted read or own save (H-18). A reload whose bytes differ is a disk
    /// change, including encoding, BOM and line-ending changes that `hash` (normalized text) cannot see.
    pub disk_hash: u64,
    /// Raw-byte hash of the save in flight; becomes `disk_hash` when it succeeds.
    saving_hash: u64,
    /// The path the save in flight writes to (the tab's path when it started). A rename or move of the file while it
    /// runs leaves the tab at another path, and that write does not count for the tab (phase3-final Must fix 1).
    saving_path: PathBuf,
    /// The disk no longer holds `disk_hash` while the buffer was not reloaded from it (E-086): set by a reload of a
    /// dirty tab, kept when undo then makes the buffer clean, cleared by a save or by the disk going back.
    pub disk_changed: bool,
    /// A reload found the file gone (E-087). Cleared when a read finds it again or a save recreates it.
    pub deleted: bool,
}

/// How a finished read ended (first read or watch reload), with the detected format (`None`: undecodable).
/// Hashes are of the editor representation (`\n` line endings, `text_io::decode_text`).
pub enum ReadOutcome {
    /// Raw disk bytes equal the `disk_hash` the read started with.
    Same(Option<Format>),
    /// New disk bytes: (normalized text hash, format, raw-byte hash).
    Changed(u64, Option<Format>, u64),
    /// The file no longer exists (E-087).
    Missing,
    Unreadable,
}

/// What `finish_read` decided.
#[derive(Debug, PartialEq)]
pub enum ReadApply {
    /// Not the tab's latest read, the tab is saving, or the pane is closed: ignore the result. Also a dirty tab: its
    /// buffer is left alone, only its conflict / deleted state is recorded.
    Dropped,
    /// Accepted, the buffer already matches (same hash or unreadable): leave the editor alone (`set_value` would
    /// reset selection, scroll and undo).
    Kept,
    /// Accepted with new content: fill every view of the file at this path (the doc's path now; a rename may have
    /// changed it since the read was requested, P4-3-R1).
    Fill(PathBuf),
}

/// See `Docs::close_state`.
#[derive(Debug, PartialEq)]
pub enum CloseState {
    /// No such tab.
    Gone,
    /// A save is running: wait for it, then look again.
    Wait,
    /// Nothing to keep: may close.
    Clean,
    /// Unsaved edits, a conflict or a deleted file with content: ask.
    Ask,
}

/// What a save request turned into.
#[derive(Debug, PartialEq)]
pub enum SaveStart {
    /// Not loaded, undecodable (read-only), not edited, or a save already in flight: nothing to do.
    Skip,
    /// The text cannot be written in the file's encoding (CP949 loss); the reason is shown, nothing is written.
    Refused(String),
    /// Write these bytes, then `finish_save` with the token.
    Write(u64, Vec<u8>),
}

impl<E> Tab<E> {
    /// 탭 제목: 파일 이름(L-64). 같은 이름 구별 설명은 넣지 않는다(판단).
    pub fn title(&self) -> String {
        self.path
            .file_name()
            .map(|n| n.to_string_lossy().into_owned())
            .unwrap_or_else(|| self.path.display().to_string())
    }
}

impl Doc {
    /// Modified for the tab dot and saving: edited, in conflict, or deleted on disk with a non-empty buffer (E-087). A clean
    /// buffer equals `hash`, so its emptiness is `hash == text_hash("")`.
    pub fn modified(&self) -> bool {
        self.dirty || self.disk_changed || (self.deleted && self.hash != text_hash(""))
    }

    /// Conflict (E-086, Warning dot): the disk changed since the last read or save and the buffer was not reloaded
    /// (it had unsaved edits; undoing them keeps the conflict until the disk is read or written again).
    pub fn has_conflict(&self) -> bool {
        self.disk_changed
    }

    /// Everything the tab bar draws from the disk state; a read that changes it must redraw (P3-4a-R1).
    pub fn marks(&self) -> (bool, bool, bool) {
        (self.has_conflict(), self.deleted, self.modified())
    }
}

/// The tabs of one pane (a leaf of `pane_group::PaneGroup`).
pub struct Pane<E = Entity<EditorState>> {
    pub tabs: Vec<Tab<E>>,
    pub active: Option<usize>,
    /// Tabs `0..pinned_count` are pinned (I-065, I-719, A-23.4); the tab bar draws them in the same row (I-066).
    pub pinned_count: usize,
}

impl<E> Default for Pane<E> {
    fn default() -> Self {
        Self { tabs: Vec::new(), active: None, pinned_count: 0 }
    }
}

/// The open files of a workspace, one `Doc` per path, whatever number of views show it.
#[derive(Default)]
pub struct Docs {
    pub docs: Vec<Doc>,
    next_load: u64,
    /// Set when the folder is removed; reads finishing afterwards are dropped (strong refs may keep it alive).
    closed: bool,
}

/// Save reference that matches no buffer and no file: set when a save finished after the tab's path changed, so what
/// the file at the tab's path now holds is unknown (phase3-final R1). The tab stays modified through any undo, closing
/// asks, a reload never refills it, and the pre-save check asks before overwriting.
// shortcut: a reserved FNV value; a real text or file hashing to 0 is a 1-in-2^64 chance.
pub const UNSURE_HASH: u64 = 0;

/// 내용 해시: UTF-8 바이트의 FNV-1a 64(dev 출력 `fnv=` 와 같은 값).
pub fn text_hash(text: &str) -> u64 {
    bytes_hash(text.as_bytes())
}

/// The disk bytes `raw` differ from the reference `disk_hash` (H-18): one rule for the watch reload and the pre-save check.
pub fn disk_differs(raw: u64, disk_hash: u64) -> bool {
    raw != disk_hash
}

/// FNV-1a 64 of raw file bytes (the disk state, H-18).
pub fn bytes_hash(bytes: &[u8]) -> u64 {
    bytes.iter().fold(0xcbf29ce484222325u64, |h, &b| (h ^ b as u64).wrapping_mul(0x100000001b3))
}

/// Hash of the editor buffer in the representation reads produce (LF, `text_io::to_lf`), so a pasted `\r\n`
/// compares equal to the file it will be saved as.
pub(super) fn buffer_hash(text: &str) -> u64 {
    if text.contains("\r\n") { text_hash(&text.replace("\r\n", "\n")) } else { text_hash(text) }
}

/// Tab editor scrollbar: gpui-base's own scrollbar on the editor's scroll handle, track width from the spec
/// (P2-5, D-10 item 6). I-9: show overflowing axes without hover or fade; Base hides axes with no overflow.
pub(super) fn editor_scrollbar(context: EditorScrollbarContext, _: &mut Window, _: &mut App) -> AnyElement {
    Scrollbar::new(&context)
        .axis(context.axis())
        .mode(gpui_kit::base::ScrollbarMode::Always)
        .styles(|s| s.track(|t| t.width(metrics::EDITOR_SCROLLBAR_WIDTH)))
        .into_any_element()
}

/// The edges of a pane next to a divider (left, right, bottom; the top is under the tab bar).
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct DividerSides {
    pub left: bool,
    pub right: bool,
    pub bottom: bool,
}

/// Tab editor element. Ctrl+Shift+drag starts a column selection at the pointer (E-047, P2-6). gpui-base binds
/// that to Alt+Shift only, inside its private `on_mouse_down` (gpui-base state.rs 2750), so the press is swallowed
/// in the capture phase and re-sent as Alt+Shift at the same spot; the drag then runs gpui-base's own block
/// selection (virtual columns, wrapped rows). Deferred: gpui takes the listener list out while dispatching.
/// `readonly` while the first read is pending (`!Tab::loaded`). The legacy `bordered` and divider-side refinements
/// are overridden by I-7: pane/tab/divider frames own every boundary; the input has no border or corner radius.
pub fn editor_view(editor: &Entity<EditorState>, readonly: bool, bordered: bool, sides: DividerSides, cx: &App) -> impl IntoElement {
    div()
        .size_full()
        .capture_any_mouse_down(|event, window, cx| {
            let Some(press) = column_select_press(event) else { return };
            cx.stop_propagation();
            window.defer(cx, move |window, cx| {
                // Real modifiers right before the re-send (the original press already set them).
                for input in column_select_events(press, window.modifiers(), window.capslock()) {
                    window.dispatch_event(input, cx);
                }
            });
        })
        .child(
            // P2-7: font size and comfortable line height from the spec; refine over gpui-kit's mono size × 1.5.
            Editor::new(editor)
                .font(super::fonts::editor())
                .readonly(readonly)
                .bordered(bordered)
                .when(sides.left, |e| e.border_l(px(0.)))
                .when(sides.right, |e| e.border_r(px(0.)))
                .when(sides.bottom, |e| e.border_b(px(0.)))
                // I-7: pane/tab/divider frames own the boundary, not the input control.
                .border_0()
                .rounded_none()
                .text_size(super::settings::buffer_size(cx))
                .line_height(relative(metrics::BUFFER_LINE_HEIGHT_MULTIPLIER))
                .h_full(),
        )
}

/// Ctrl+Shift+left press → the same press with Alt+Shift (gpui-base's column selection); anything else → `None`.
fn column_select_press(event: &MouseDownEvent) -> Option<MouseDownEvent> {
    let m = event.modifiers;
    if event.button != MouseButton::Left || !(m.control && m.shift) || m.alt || m.platform {
        return None;
    }
    let mut press = event.clone();
    press.modifiers.control = false;
    press.modifiers.alt = true;
    Some(press)
}

/// What to dispatch, in order, for a remapped press: the Alt+Shift press, then the real modifiers back.
/// `dispatch_event` stores a mouse event's modifiers as the window's (gpui-pre window.rs 5664), and the only public
/// way to set them back is a `ModifiersChanged` event (`set_modifiers` is test-support only). The restore keeps
/// Ctrl+Shift (two modifiers), so gpui never turns it into a modifier-only keystroke (window.rs 6063: that needs
/// zero), and gpui-base only re-renders on it (state.rs 5112); the column selection started by the press stays.
fn column_select_events(press: MouseDownEvent, real: Modifiers, capslock: Capslock) -> [PlatformInput; 2] {
    [
        PlatformInput::MouseDown(press),
        PlatformInput::ModifiersChanged(ModifiersChangedEvent { modifiers: real, capslock }),
    ]
}

/// File text in the editor representation (`\n` line endings) and its format (`text_io::decode_text`). An
/// undecodable file comes back as lossy UTF-8 with no format, so it stays read-only. Also the raw-byte hash
/// (`bytes_hash`, H-18). `None` when unreadable.
pub fn read_text(path: &Path) -> Option<(String, Option<Format>, u64)> {
    let bytes = std::fs::read(path).ok()?;
    let raw = bytes_hash(&bytes);
    Some(match text_io::decode_text(&bytes) {
        Ok((text, format)) => (text, Some(format), raw),
        Err(_) => (text_io::to_lf(String::from_utf8_lossy(&bytes).into_owned()), None, raw),
    })
}

impl<E> Pane<E> {
    /// The editor tab of `path` (a Markdown preview of it is `find_preview`).
    pub fn find(&self, path: &Path) -> Option<usize> {
        self.tabs.iter().position(|t| !t.markdown && t.path == path)
    }

    /// The Markdown preview tab of `path`.
    pub fn find_preview(&self, path: &Path) -> Option<usize> {
        self.tabs.iter().position(|t| t.markdown && t.path == path)
    }

    pub fn active_tab(&self) -> Option<&Tab<E>> {
        self.active.and_then(|i| self.tabs.get(i))
    }

    /// Puts a new tab in place: replaces the preview tab (I-062) or inserts after the active tab, but never inside the
    /// pinned run (I-719). Returns its index and the preview tab it replaced. `keep_preview`: the preview tab holds
    /// something to keep (phase3-final Must fix 2, decided by `PaneGroup::open_in`), so it is promoted to a normal tab
    /// instead (one more I-063 promotion) and the new tab is inserted.
    pub fn place(&mut self, tab: Tab<E>, keep_preview: bool) -> (usize, Option<Tab<E>>) {
        if tab.preview
            && let Some(pi) = self.tabs.iter().position(|t| t.preview)
        {
            if !keep_preview {
                let old = std::mem::replace(&mut self.tabs[pi], tab);
                self.active = Some(pi);
                return (pi, Some(old));
            }
            self.tabs[pi].preview = false;
        }
        let at = self.active.map(|a| a + 1).unwrap_or(self.tabs.len()).max(self.pinned_count).min(self.tabs.len());
        self.tabs.insert(at, tab);
        self.active = Some(at);
        (at, None)
    }

    /// Inserts a dropped or moved `tab` at `at` (clamped) and activates it. It is never a preview (I-717, I-722). A
    /// place inside the pinned run pins it (I-719, I-720, I-722); `pinned` keeps a pin at the run's end (I-720).
    pub fn insert_at(&mut self, mut tab: Tab<E>, at: usize, pinned: bool) -> usize {
        let at = at.min(self.tabs.len());
        tab.preview = false;
        let at = if pinned { at.min(self.pinned_count) } else { at };
        if pinned || at < self.pinned_count {
            self.pinned_count += 1;
        }
        self.tabs.insert(at, tab);
        self.active = Some(at);
        at
    }

    /// Removes tab `ix` (v0.4 P3-3, H-16). The active tab stays active; closing the active one activates the tab
    /// that slides into its place, else the last.
    // shortcut: neighbour instead of Zed's most-recently-used order (`activate_on_close: history`); needs an
    // activation history if that order is wanted.
    pub fn close_tab(&mut self, ix: usize) -> Option<Tab<E>> {
        if ix >= self.tabs.len() {
            return None;
        }
        let tab = self.tabs.remove(ix);
        if ix < self.pinned_count {
            self.pinned_count -= 1;
        }
        self.active = match self.active {
            _ if self.tabs.is_empty() => None,
            Some(a) if a == ix => Some(ix.min(self.tabs.len() - 1)),
            Some(a) if a > ix => Some(a - 1),
            other => other,
        };
        Some(tab)
    }

    pub fn is_pinned(&self, ix: usize) -> bool {
        ix < self.pinned_count
    }

    /// I-066: Ctrl+W, Ctrl+F4 and a middle click leave a pinned tab open. Closing the folder or window still closes it.
    pub fn close_protected(&self, ix: usize) -> bool {
        self.is_pinned(ix)
    }

    /// I-063: a tab double-click (or a non-preview open of the same file) makes the tab normal. It does not pin (I-065).
    pub fn promote(&mut self, ix: usize) {
        if let Some(tab) = self.tabs.get_mut(ix) {
            tab.preview = false;
        }
    }

    /// `pane::TogglePinTab` (Ctrl+K Shift+Enter, I-065, I-577). Pin: the tab stops being a preview and moves to the
    /// end of the pinned run. Unpin: it moves to the first place after the run. The tab keeps its active state.
    pub fn toggle_pin(&mut self, ix: usize) {
        if ix >= self.tabs.len() {
            return;
        }
        if self.is_pinned(ix) {
            self.pinned_count -= 1;
            self.move_tab(ix, self.pinned_count);
        } else {
            self.tabs[ix].preview = false;
            self.move_tab(ix, self.pinned_count);
            self.pinned_count += 1;
        }
    }

    /// Moves tab `from` to index `to`; the active tab follows its tab. The pinned count is not touched (`reorder`
    /// judges pinning by the new place).
    pub fn move_tab(&mut self, from: usize, to: usize) {
        let tab = self.tabs.remove(from);
        self.tabs.insert(to, tab);
        self.active = self.active.map(|a| match a {
            a if a == from => to,
            a if from < a && a <= to => a - 1,
            a if to <= a && a < from => a + 1,
            a => a,
        });
    }

    /// 트리에서 이름을 바꾸거나 옮긴 파일·폴더를 탭 경로에 반영한다(판단).
    pub fn rename_path(&mut self, from: &Path, to: &Path) {
        for tab in &mut self.tabs {
            if let Ok(rest) = tab.path.strip_prefix(from) {
                tab.path = if rest.as_os_str().is_empty() { to.to_path_buf() } else { to.join(rest) };
            }
        }
    }

    /// dev 출력 한 줄: `제목|preview 또는 normal|경로` 를 탭으로 잇는다.
    pub fn describe(&self) -> String {
        self.tabs
            .iter()
            .map(|t| format!("{}|{}|{}", t.title(), if t.preview { "preview" } else { "normal" }, t.path.display()))
            .collect::<Vec<_>>()
            .join("\t")
    }

    /// Same-pane drag or Ctrl+Shift+PageUp/PageDown (I-715, I-734): moves tab `from` to `to`. Pinned is judged by the
    /// new place (I-719): into the pinned run pins it, out of it unpins it.
    pub fn reorder(&mut self, from: usize, to: usize) {
        if from >= self.tabs.len() {
            return;
        }
        let to = to.min(self.tabs.len() - 1);
        let (was, now) = (from < self.pinned_count, to < self.pinned_count);
        self.move_tab(from, to);
        self.tabs[to].preview = false;
        match (was, now) {
            (false, true) => self.pinned_count += 1,
            (true, false) => self.pinned_count -= 1,
            _ => {}
        }
    }
}

impl Docs {
    pub fn find(&self, path: &Path) -> Option<usize> {
        self.docs.iter().position(|d| d.path == path)
    }

    pub fn get(&self, path: &Path) -> Option<&Doc> {
        self.find(path).map(|i| &self.docs[i])
    }

    fn next_token(&mut self) -> u64 {
        self.next_load += 1;
        self.next_load
    }

    /// A new pending doc for `path` with a fresh read token (its first read).
    pub fn add(&mut self, path: &Path) -> u64 {
        let token = self.next_token();
        self.docs.push(Doc {
            path: path.to_path_buf(),
            hash: text_hash(""),
            pending: Some(token),
            dirty: false,
            loaded: false,
            format: None,
            saving: None,
            disk_hash: bytes_hash(b""),
            saving_hash: 0,
            saving_path: PathBuf::new(),
            disk_changed: false,
            deleted: false,
        });
        token
    }

    /// Forgets `path` (its last view closed). Its pending reads and saves stop applying (nothing to match).
    pub fn remove(&mut self, path: &Path) {
        self.docs.retain(|d| d.path != path);
    }

    /// Starts a read for tab `ix`; any earlier read of that tab stops applying.
    pub fn start_read(&mut self, ix: usize) -> u64 {
        let token = self.next_token();
        self.docs[ix].pending = Some(token);
        token
    }

    /// Drops every pending read (folder removal).
    pub fn close(&mut self) {
        self.closed = true;
    }

    /// Decides a finished read. It applies only if it is still the tab's latest read; a replaced, removed or closed
    /// tab drops it. A dirty tab keeps its buffer (no reload over edits, P3-1) and records the disk state instead:
    /// changed raw bytes are a conflict (E-086, H-18), a missing file is deleted (E-087, any tab). A tab being saved
    /// drops it. A save also invalidates reads started before it finished (`finish_save`), so a read
    /// from before or during a save never lands after it. Content cannot change between start and accept: only the
    /// latest token applies, and edits make the tab dirty.
    pub fn finish_read(&mut self, token: u64, outcome: ReadOutcome) -> ReadApply {
        if self.closed {
            return ReadApply::Dropped;
        }
        let Some(tab) = self.docs.iter_mut().find(|t| t.pending == Some(token)) else {
            return ReadApply::Dropped;
        };
        tab.pending = None;
        if tab.saving.is_some() {
            return ReadApply::Dropped;
        }
        // Disk state first, by raw bytes (E-086, E-087, H-18); an unreadable file (e.g. locked) tells nothing.
        match outcome {
            ReadOutcome::Missing => tab.deleted = true,
            ReadOutcome::Same(_) => (tab.deleted, tab.disk_changed) = (false, false),
            ReadOutcome::Changed(_, _, raw) => (tab.deleted, tab.disk_changed) = (false, disk_differs(raw, tab.disk_hash)),
            ReadOutcome::Unreadable => {}
        }
        if tab.dirty {
            // Edits stay; the format and `disk_hash` stay the ones the buffer was read with.
            return ReadApply::Dropped;
        }
        match outcome {
            ReadOutcome::Changed(h, format, raw) => {
                // A clean buffer takes the new file, even one left clean by undo during a conflict (P3-4a-R1).
                (tab.format, tab.disk_hash, tab.disk_changed) = (format, raw, false);
                tab.loaded = format.is_some();
                if h == tab.hash {
                    // The text already matches (D-046: no `set_value`); e.g. only the line ending or encoding changed.
                    return ReadApply::Kept;
                }
                tab.hash = h;
                ReadApply::Fill(tab.path.clone())
            }
            ReadOutcome::Same(format) => {
                tab.format = format;
                tab.loaded = format.is_some();
                ReadApply::Kept
            }
            // A deleted file's buffer stays as it was (E-087).
            ReadOutcome::Missing | ReadOutcome::Unreadable => ReadApply::Kept,
        }
    }

    /// Starts saving tab `ix` whose buffer is `text`: encodes it with the tab's encoding and line ending (P3-2, D-6).
    /// A tab that is not modified is not written (H-15), so an unedited file keeps its exact bytes. A deleted file with
    /// a non-empty buffer is modified, so saving recreates it (E-085, E-087); saving over a conflict overwrites (E-084;
    /// the confirmation dialog is P3-3's).
    pub fn begin_save(&mut self, ix: usize, text: &str) -> SaveStart {
        let tab = &self.docs[ix];
        let (true, true, Some(format), None) = (tab.loaded, tab.modified(), tab.format, tab.saving) else {
            return SaveStart::Skip;
        };
        match text_io::encode_text(text, format) {
            Ok(bytes) => {
                let token = self.next_token();
                let tab = &mut self.docs[ix];
                (tab.saving, tab.saving_hash, tab.saving_path) = (Some(token), bytes_hash(&bytes), tab.path.clone());
                SaveStart::Write(token, bytes)
            }
            Err(e) => SaveStart::Refused(e),
        }
    }

    /// The save with `token` finished. On success the disk now holds the buffer text `saved_hash` and the written
    /// bytes (`disk_hash`, which the watch reload compares with, so the own write reads back as `Same`, D-046, H-18); the tab is dirty only if the buffer
    /// (`buffer_hash`) changed since. Reads started before now are invalidated either way: they may hold content
    /// from before the write. Returns `false` when the tab is gone.
    /// A successful write to a path the tab no longer has (renamed or moved meanwhile, phase3-final R1): the write may
    /// have landed before or after the move, so the file at the tab's path holds either text. The reference becomes
    /// unknown (`UNSURE_HASH`) and the tab dirty, whatever the buffer is now (an undo during the save included);
    /// saving again writes the tab's path and settles it.
    pub fn finish_save(&mut self, token: u64, ok: bool, saved_hash: u64, buffer_hash: u64) -> bool {
        let Some(tab) = self.docs.iter_mut().find(|t| t.saving == Some(token)) else {
            return false;
        };
        tab.saving = None;
        tab.pending = None;
        if ok && tab.path != tab.saving_path {
            (tab.hash, tab.disk_hash, tab.dirty) = (UNSURE_HASH, UNSURE_HASH, true);
        } else if ok {
            tab.hash = saved_hash;
            tab.dirty = buffer_hash != saved_hash;
            // The disk now holds the written bytes: the new reference (H-18), no conflict, a deleted file exists again.
            (tab.disk_hash, tab.disk_changed, tab.deleted) = (tab.saving_hash, false, false);
        }
        true
    }

    /// A user edit on doc `ix` whose buffer now hashes to `buffer_hash`: dirty when it differs from the disk
    /// content. The view's preview promotion (I-063) is `PaneGroup::on_edit`.
    pub fn on_edit(&mut self, ix: usize, buffer_hash: u64) {
        let tab = &mut self.docs[ix];
        // Undo back to `hash` during a conflict clears `dirty` but not `disk_changed`: still a modified conflict.
        tab.dirty = buffer_hash != tab.hash;
    }

    /// What a closing flow must do with the tab at `path` right now (P3-3-R1). A save in flight comes first: its
    /// result and the buffer are judged after it ends, even if the buffer looks clean (undo during the write).
    pub fn close_state(&self, path: &Path) -> CloseState {
        match self.find(path).map(|i| &self.docs[i]) {
            None => CloseState::Gone,
            Some(t) if t.saving.is_some() => CloseState::Wait,
            Some(t) if !t.modified() => CloseState::Clean,
            Some(_) => CloseState::Ask,
        }
    }

    /// E-084 "Discard Edits": the buffer was reset to the disk text (`hash`, `format` from that read), so the tab is
    /// clean again. Reads started earlier stop applying (they may hold older content).
    pub fn discard_edits(&mut self, ix: usize, hash: u64, format: Option<Format>, raw: u64) {
        let tab = &mut self.docs[ix];
        (tab.disk_hash, tab.disk_changed, tab.deleted) = (raw, false, false);
        tab.hash = hash;
        tab.format = format;
        tab.loaded = format.is_some();
        tab.dirty = false;
        tab.pending = None;
    }

    /// The file or folder `from` was renamed or moved to `to`. A read still running for a renamed doc may have read
    /// the old place after the move, so it stops applying (P4-3-R1); the new paths that lost a read are returned so the
    /// caller reads them again.
    pub fn rename_path(&mut self, from: &Path, to: &Path) -> Vec<PathBuf> {
        let mut reread = Vec::new();
        for doc in &mut self.docs {
            if let Ok(rest) = doc.path.strip_prefix(from) {
                doc.path = if rest.as_os_str().is_empty() { to.to_path_buf() } else { to.join(rest) };
                if doc.pending.take().is_some() {
                    reread.push(doc.path.clone());
                }
            }
        }
        reread
    }
}

impl super::Workbench {
    /// `workspace::Save` (Ctrl-S, E-088): saves the active tab (`tab_close::save_tab`: encoding kept, E-084/E-085
    /// asked first, E-083 on failure).
    pub(super) fn on_save(&mut self, action: &super::keymap::workspace::Save, window: &mut Window, cx: &mut Context<Self>) {
        super::keymap::log_handled(action, self.focus_name(window, cx), cx);
        let Some(ws) = self.active_ws() else { return };
        let Some(path) = ws.read(cx).group.active_tab().map(|t| t.path.clone()) else { return };
        cx.spawn_in(window, async move |this, cx| {
            if super::tab_close::save_tab(&ws, &path, None, cx).await == End::Closed {
                // E-085 "Close": the user gave the file up.
                let _ = this.update_in(cx, |this, window, cx| this.drop_file(&ws, &path, window, cx));
            }
        })
        .detach();
    }
}

/// E-083 "Unable to save file: {error}" as a notification (D-14), plus the dev line other notifications use.
pub(super) fn save_failed(path: &Path, error: &str, window: &mut Window, cx: &mut App) {
    use gpui_kit::component::WindowExt as _;
    let text = format!("Unable to save file: {error}");
    if super::keymap::dev_enabled(cx) {
        println!("[dev] notification text={text} path={}", path.display());
    }
    window.push_notification(SharedString::from(text), cx);
}

#[cfg(test)]
mod tests {
    // Explicit imports: `super::*` would pull in gpui's `test` macro through `gpui_kit::*`.
    use super::{
        buffer_hash, Capslock, Modifiers, MouseButton, MouseDownEvent, Docs, Pane, Path, PlatformInput, ReadApply, ReadOutcome, SaveStart, Tab, column_select_events,
        CloseState, UNSURE_HASH, bytes_hash, disk_differs, column_select_press, metrics, point, px, text_hash,
    };

    /// V1 (P2-6-R1): the re-sent press comes first, then the real Ctrl+Shift (and capslock) are restored, so
    /// `window.modifiers()` does not keep the fake Alt. The restore has ≥2 modifiers: never a modifier-only keystroke.
    #[test]
    fn column_press_then_real_modifiers_restored() {
        let real = Modifiers { control: true, shift: true, ..Default::default() };
        let pressed = press(MouseButton::Left, real);
        let remapped = column_select_press(&pressed).unwrap();
        let caps = Capslock { on: true };
        let [first, second] = column_select_events(remapped, real, caps);
        let PlatformInput::MouseDown(down) = first else { panic!("first must be the re-sent press") };
        assert_eq!(down.modifiers, Modifiers { alt: true, shift: true, ..Default::default() });
        let PlatformInput::ModifiersChanged(restore) = second else { panic!("second must restore modifiers") };
        assert_eq!((restore.modifiers, restore.capslock), (real, caps));
        assert!(restore.modifiers.number_of_modifiers() >= 2);
    }

    use crate::text_io::{Format, LineEnding, TextEncoding};

    const UTF8: Option<Format> = Some(Format { encoding: TextEncoding::Utf8, line_ending: LineEnding::Lf });

    impl ReadApply {
        fn accepted(&self) -> bool {
            !matches!(self, Self::Dropped)
        }
    }

    fn fmt(encoding: TextEncoding, line_ending: LineEnding) -> Option<Format> {
        Some(Format { encoding, line_ending })
    }

    fn press(button: MouseButton, modifiers: Modifiers) -> MouseDownEvent {
        MouseDownEvent { button, position: point(px(40.), px(60.)), modifiers, click_count: 1, first_mouse: false }
    }

    /// V2: tab editor font size 15 and line height 1.618 × 15 = 24.27 (P2-7). Exact checks, not only the ±1 tolerance.
    #[test]
    fn editor_font_and_line_height_are_spec() {
        let size = f32::from(metrics::BUFFER_FONT_SIZE);
        metrics::spec::assert_spec("typography[\"buffer_font_size\"]", "default", size);
        assert_eq!(metrics::spec::lookup("typography[\"buffer_font_size\"]").unwrap().value, f64::from(size));
        let mult = metrics::spec::lookup("editor[\"line_height.comfortable_multiplier\"]").unwrap().value;
        assert_eq!(mult as f32, metrics::BUFFER_LINE_HEIGHT_MULTIPLIER);
        let line = size * metrics::BUFFER_LINE_HEIGHT_MULTIPLIER;
        let spec_line = metrics::spec::lookup("editor[\"line_height.comfortable\"]").unwrap().value as f32;
        assert!((line - spec_line).abs() < 0.01, "line height {line} vs spec {spec_line}");
    }

    /// V1: Ctrl+Shift+left becomes gpui-base's Alt+Shift column press at the same spot (E-047).
    #[test]
    fn ctrl_shift_press_becomes_column_press() {
        let p = column_select_press(&press(MouseButton::Left, Modifiers { control: true, shift: true, ..Default::default() }))
            .expect("ctrl+shift left remaps");
        assert_eq!(p.modifiers, Modifiers { alt: true, shift: true, ..Default::default() });
        assert_eq!((p.position, p.click_count, p.button), (point(px(40.), px(60.)), 1, MouseButton::Left));
    }

    /// V1: other presses go to the editor unchanged (plain, Shift, Ctrl, Alt+Shift, right button, Ctrl+Shift+Alt).
    #[test]
    fn other_presses_are_not_remapped() {
        let m = |control, alt, shift| Modifiers { control, alt, shift, ..Default::default() };
        for (button, mods) in [
            (MouseButton::Left, m(false, false, false)),
            (MouseButton::Left, m(false, false, true)),
            (MouseButton::Left, m(true, false, false)),
            (MouseButton::Left, m(false, true, true)),
            (MouseButton::Left, m(true, true, true)),
            (MouseButton::Right, m(true, false, true)),
        ] {
            assert!(column_select_press(&press(button, mods)).is_none(), "{button:?} {mods:?}");
        }
    }

    /// V2: the tab editor scrollbar track width is the spec value (P2-5 item 6).
    #[test]
    fn editor_scrollbar_width_is_spec() {
        let id = "scrollbar[\"width.editor\"]";
        let width = f32::from(metrics::EDITOR_SCROLLBAR_WIDTH);
        metrics::spec::assert_spec(id, "default", width);
        // Exact too: the ±1 tolerance would also pass gpui-base's 16 (D-3 fixes in-tolerance gaps).
        assert_eq!(metrics::spec::lookup(id).unwrap().value, f64::from(width));
    }

    /// A new doc for `path`; returns its first-read token.
    fn open(docs: &mut Docs, path: &str, _preview: bool) -> u64 {
        docs.add(Path::new(path))
    }

    /// A new tab (view) in `pane`.
    fn view(pane: &mut Pane<()>, path: &str, preview: bool) {
        pane.place(Tab { path: path.into(), preview, markdown: false, editor: (), tool: None }, false);
    }

    /// A forgotten doc (replaced preview, I-062: `PaneGroup::open_in`) drops its earlier load.
    #[test]
    fn replaced_preview_drops_earlier_load() {
        let mut pane = Docs::default();
        let a = open(&mut pane, "a.txt", true);
        pane.remove(Path::new("a.txt"));
        let b = open(&mut pane, "b.txt", true);
        assert_eq!(pane.docs.len(), 1);
        assert!(!pane.finish_read(a, ReadOutcome::Changed(1, UTF8, 1)).accepted());
        assert!(pane.finish_read(b, ReadOutcome::Changed(2, UTF8, 2)).accepted());
        assert_eq!((pane.docs[0].hash, pane.docs[0].pending), (2, None));
        // A finished token is not accepted twice.
        assert!(!pane.finish_read(b, ReadOutcome::Changed(3, UTF8, 3)).accepted());
    }

    #[test]
    fn closed_tab_drops_load() {
        let mut pane = Docs::default();
        let a = open(&mut pane, "a.txt", false);
        let b = open(&mut pane, "b.txt", false);
        pane.docs.retain(|t| t.pending != Some(a));
        assert!(!pane.finish_read(a, ReadOutcome::Changed(1, UTF8, 1)).accepted());
        assert!(pane.finish_read(b, ReadOutcome::Changed(2, UTF8, 2)).accepted());
        assert_eq!(pane.docs[0].hash, 2);
    }

    /// First read got A, reload got B and applied first; the late first read must not bring A back.
    #[test]
    fn late_first_read_after_reload_is_dropped() {
        let mut pane = Docs::default();
        let first = open(&mut pane, "a.txt", false);
        let reload = pane.start_read(0);
        assert!(pane.finish_read(reload, ReadOutcome::Changed(text_hash("B"), UTF8, text_hash("B"))).accepted());
        assert!(!pane.finish_read(first, ReadOutcome::Changed(text_hash("A"), UTF8, text_hash("A"))).accepted());
        assert_eq!(pane.docs[0].hash, text_hash("B"));
    }

    /// Reload started while loading saw the file emptied (`Same` against the empty hash). The earlier first
    /// read of A must not apply, so the tab stays empty like the disk.
    #[test]
    fn empty_same_reload_wins_over_first_read() {
        let mut pane = Docs::default();
        let first = open(&mut pane, "a.txt", false);
        let reload = pane.start_read(0);
        assert!(!pane.finish_read(first, ReadOutcome::Changed(text_hash("A"), UTF8, text_hash("A"))).accepted());
        assert!(pane.finish_read(reload, ReadOutcome::Same(UTF8)).accepted());
        assert_eq!((pane.docs[0].hash, pane.docs[0].pending), (text_hash(""), None));
    }

    /// Folder removed while first read and reload are in flight (reload keeps the workspace alive).
    #[test]
    fn closed_pane_drops_all_reads() {
        let mut pane = Docs::default();
        let first = open(&mut pane, "a.txt", false);
        let reload = pane.start_read(0);
        pane.close();
        assert!(!pane.finish_read(first, ReadOutcome::Changed(1, UTF8, 1)).accepted());
        assert!(!pane.finish_read(reload, ReadOutcome::Changed(2, UTF8, 2)).accepted());
        assert_eq!(pane.docs[0].hash, text_hash(""));
    }

    /// P3-1: the first read loads the tab (editing allowed); an edit that changes the text makes it dirty; undoing
    /// back to the disk text clears dirty. (Preview promotion by the edit: `pane_group` tests.)
    #[test]
    fn edit_marks_dirty() {
        let mut pane = Docs::default();
        let first = open(&mut pane, "a.txt", true);
        assert!(!pane.docs[0].loaded);
        assert!(pane.finish_read(first, ReadOutcome::Changed(text_hash("A"), UTF8, text_hash("A"))).accepted());
        assert!(pane.docs[0].loaded && !pane.docs[0].dirty);
        pane.on_edit(0, text_hash("AB"));
        assert!(pane.docs[0].dirty);
        pane.on_edit(0, text_hash("A"));
        assert!(!pane.docs[0].dirty);
    }

    /// P3-1: a reload of a dirty tab keeps the buffer and the disk hash (no apply), and is not accepted again.
    #[test]
    fn dirty_tab_is_not_reloaded() {
        let mut pane = Docs::default();
        let first = open(&mut pane, "a.txt", false);
        pane.finish_read(first, ReadOutcome::Changed(text_hash("A"), UTF8, text_hash("A")));
        pane.on_edit(0, text_hash("A edited"));
        let reload = pane.start_read(0);
        assert!(!pane.finish_read(reload, ReadOutcome::Changed(text_hash("B"), UTF8, text_hash("B"))).accepted());
        let t = &pane.docs[0];
        assert_eq!((t.hash, t.dirty, t.pending), (text_hash("A"), true, None));
    }

    fn loaded(pane: &mut Docs, text: &str) {
        let first = open(pane, "a.txt", false);
        pane.finish_read(first, ReadOutcome::Changed(text_hash(text), UTF8, text_hash(text)));
    }

    fn reload(pane: &mut Docs, outcome: ReadOutcome) -> bool {
        let token = pane.start_read(0);
        matches!(pane.finish_read(token, outcome), ReadApply::Fill(_))
    }

    /// P3-4a (E-086): a dirty buffer whose file changed is a conflict and keeps its text; the disk returning to the
    /// read content clears it; a save clears it.
    #[test]
    fn disk_change_on_dirty_tab_is_conflict_until_saved() {
        let mut pane = Docs::default();
        loaded(&mut pane, "A");
        pane.on_edit(0, text_hash("A edited"));
        assert!(!reload(&mut pane, ReadOutcome::Changed(text_hash("B"), UTF8, text_hash("B"))), "buffer kept");
        assert!(pane.docs[0].has_conflict() && pane.docs[0].modified());
        assert!(!reload(&mut pane, ReadOutcome::Same(UTF8)));
        assert!(!pane.docs[0].has_conflict(), "disk back to the read content");
        reload(&mut pane, ReadOutcome::Changed(text_hash("B"), UTF8, text_hash("B")));
        // Locked file: says nothing about the disk, the conflict stays.
        reload(&mut pane, ReadOutcome::Unreadable);
        assert!(pane.docs[0].has_conflict());
        let SaveStart::Write(token, _) = pane.begin_save(0, "A edited") else { panic!("conflict saves (overwrite)") };
        pane.finish_save(token, true, text_hash("A edited"), text_hash("A edited"));
        assert!(!pane.docs[0].has_conflict() && !pane.docs[0].modified());
    }

    /// P3-4a (E-086): a clean tab still reloads on a disk change and never shows a conflict.
    #[test]
    fn disk_change_on_clean_tab_reloads() {
        let mut pane = Docs::default();
        loaded(&mut pane, "A");
        assert!(reload(&mut pane, ReadOutcome::Changed(text_hash("B"), UTF8, text_hash("B"))));
        let t = &pane.docs[0];
        assert_eq!((t.hash, t.has_conflict(), t.disk_changed), (text_hash("B"), false, false));
    }

    /// P3-4a (E-087, E-085): a removed file marks the tab deleted and keeps the buffer; non-empty means modified, so
    /// a save writes it (recreates the file) and clears deleted. A file that comes back clears it too.
    #[test]
    fn deleted_file_is_marked_and_save_recreates() {
        let mut pane = Docs::default();
        loaded(&mut pane, "A");
        assert!(!reload(&mut pane, ReadOutcome::Missing), "buffer kept");
        let t = &pane.docs[0];
        assert!(t.deleted && t.modified() && !t.dirty && !t.has_conflict());
        let SaveStart::Write(token, bytes) = pane.begin_save(0, "A") else { panic!("deleted non-empty tab saves") };
        assert_eq!(bytes, b"A");
        pane.finish_save(token, true, text_hash("A"), text_hash("A"));
        assert!(!pane.docs[0].deleted && !pane.docs[0].modified());
        // Deleted then restored with the same content: not deleted, not modified.
        reload(&mut pane, ReadOutcome::Missing);
        reload(&mut pane, ReadOutcome::Same(UTF8));
        assert!(!pane.docs[0].deleted && !pane.docs[0].modified());
    }

    /// P3-4a (E-087): an empty deleted buffer is not modified (nothing to save); a dirty one is deleted and modified.
    #[test]
    fn deleted_empty_and_dirty_tabs() {
        let mut pane = Docs::default();
        loaded(&mut pane, "");
        reload(&mut pane, ReadOutcome::Missing);
        assert!(pane.docs[0].deleted && !pane.docs[0].modified());
        assert_eq!(pane.begin_save(0, ""), SaveStart::Skip);
        pane.on_edit(0, text_hash("x"));
        reload(&mut pane, ReadOutcome::Missing);
        assert!(pane.docs[0].deleted && pane.docs[0].modified() && !pane.docs[0].has_conflict());
    }

    /// P3-4a-R1 (1): A read, C typed, disk changed to B, undo back to A. The buffer is clean against the read but not
    /// against the disk: it stays a modified conflict (no later event needed), saving overwrites, and the next reload
    /// of the clean buffer fills the latest file.
    #[test]
    fn undo_during_conflict_keeps_conflict() {
        let mut pane = Docs::default();
        loaded(&mut pane, "A");
        pane.on_edit(0, text_hash("C"));
        reload(&mut pane, ReadOutcome::Changed(text_hash("B"), UTF8, text_hash("B")));
        pane.on_edit(0, text_hash("A"));
        let t = &pane.docs[0];
        assert!(!t.dirty && t.has_conflict() && t.modified());
        assert!(matches!(pane.begin_save(0, "A"), SaveStart::Write(..)), "overwrite stays possible");
        let mut pane2 = Docs::default();
        loaded(&mut pane2, "A");
        pane2.on_edit(0, text_hash("C"));
        reload(&mut pane2, ReadOutcome::Changed(text_hash("B"), UTF8, text_hash("B")));
        pane2.on_edit(0, text_hash("A"));
        assert!(reload(&mut pane2, ReadOutcome::Changed(text_hash("B"), UTF8, text_hash("B"))), "latest file fills");
        assert!(!pane2.docs[0].has_conflict() && !pane2.docs[0].modified());
    }

    /// P3-4a-R1 (2, H-18): same text with other bytes (UTF-16 BOM, CRLF) is a disk change: a conflict for a dirty
    /// tab; a clean tab takes the new format without `set_value`. Own save sets the reference, so its read-back is
    /// `Same` and not a conflict.
    #[test]
    fn raw_bytes_decide_disk_change() {
        let utf16 = fmt(TextEncoding::Utf16Le, LineEnding::Lf);
        let crlf = fmt(TextEncoding::Utf8, LineEnding::Crlf);
        let mut pane = Docs::default();
        loaded(&mut pane, "A");
        pane.on_edit(0, text_hash("A edited"));
        reload(&mut pane, ReadOutcome::Changed(text_hash("A"), utf16, bytes_hash(b"\xFF\xFEA\0")));
        assert!(pane.docs[0].has_conflict() && pane.docs[0].format == UTF8, "dirty keeps its format");

        let mut pane = Docs::default();
        loaded(&mut pane, "a\nb");
        let token = pane.start_read(0);
        assert_eq!(pane.finish_read(token, ReadOutcome::Changed(text_hash("a\nb"), crlf, bytes_hash(b"a\r\nb"))), ReadApply::Kept);
        let t = &pane.docs[0];
        assert_eq!((t.format, t.disk_hash, t.has_conflict()), (crlf, bytes_hash(b"a\r\nb"), false));

        pane.on_edit(0, text_hash("a\nbc"));
        let SaveStart::Write(token, bytes) = pane.begin_save(0, "a\nbc") else { panic!("expected a write") };
        pane.finish_save(token, true, text_hash("a\nbc"), text_hash("a\nbc"));
        assert_eq!(pane.docs[0].disk_hash, bytes_hash(&bytes));
        pane.on_edit(0, text_hash("a\nbcd"));
        // The watch read compares raw bytes with `disk_hash`: equal is `Same`, and a dirty tab is no conflict.
        reload(&mut pane, ReadOutcome::Same(crlf));
        assert!(!pane.docs[0].has_conflict());
        // Bytes equal to the reference reported as Changed (only the text hash differs) are no conflict either.
        reload(&mut pane, ReadOutcome::Changed(0, crlf, bytes_hash(&bytes)));
        assert!(!pane.docs[0].has_conflict());
    }

    /// P3-4a-R1 (3): a dirty conflict and a clean deletion change the tab marks without a fill, so the reload
    /// completion must redraw (watch_io compares `marks` before and after); a no-op reload does not.
    #[test]
    fn state_only_reads_change_marks() {
        let mut pane = Docs::default();
        loaded(&mut pane, "A");
        pane.on_edit(0, text_hash("A edited"));
        let before = pane.docs[0].marks();
        assert!(!reload(&mut pane, ReadOutcome::Changed(text_hash("B"), UTF8, text_hash("B"))));
        assert_ne!(pane.docs[0].marks(), before, "dirty conflict");

        let mut pane = Docs::default();
        loaded(&mut pane, "A");
        let before = pane.docs[0].marks();
        assert!(!reload(&mut pane, ReadOutcome::Missing));
        assert_ne!(pane.docs[0].marks(), before, "clean deletion");
        let before = pane.docs[0].marks();
        reload(&mut pane, ReadOutcome::Unreadable);
        assert_eq!(pane.docs[0].marks(), before, "nothing new");
    }

    /// P3-1: an unreadable first read leaves the tab not loaded (read-only), so nothing typed can replace the file.
    #[test]
    fn unreadable_first_read_stays_read_only() {
        let mut pane = Docs::default();
        let first = open(&mut pane, "a.txt", false);
        assert!(pane.finish_read(first, ReadOutcome::Unreadable).accepted());
        assert!(!pane.docs[0].loaded);
        // A later reload that reads the (empty) file loads it.
        let reload = pane.start_read(0);
        pane.finish_read(reload, ReadOutcome::Same(UTF8));
        assert!(pane.docs[0].loaded);
    }
    /// P3-2: save writes the tab's encoding; a second save waits; success records the saved hash and keeps the
    /// tab dirty only if the buffer changed while writing.
    #[test]
    fn save_encodes_with_tab_encoding_and_records_hash() {
        let mut pane = Docs::default();
        let first = open(&mut pane, "a.txt", false);
        assert_eq!(pane.begin_save(0, "x"), SaveStart::Skip, "not loaded yet");
        pane.finish_read(first, ReadOutcome::Changed(text_hash("A"), fmt(TextEncoding::Utf8Bom, LineEnding::Lf), text_hash("A")));
        pane.on_edit(0, text_hash("AB"));
        let SaveStart::Write(token, bytes) = pane.begin_save(0, "AB") else { panic!("expected a write") };
        assert_eq!(bytes, [&[0xEF, 0xBB, 0xBF][..], b"AB"].concat());
        assert_eq!(pane.begin_save(0, "AB"), SaveStart::Skip, "save in flight");
        // Typed "C" while writing: saved, but still dirty against the new disk content.
        assert!(pane.finish_save(token, true, text_hash("AB"), text_hash("ABC")));
        let t = &pane.docs[0];
        assert_eq!((t.hash, t.dirty, t.saving), (text_hash("AB"), true, None));
        let SaveStart::Write(token, _) = pane.begin_save(0, "ABC") else { panic!("expected a write") };
        assert!(pane.finish_save(token, true, text_hash("ABC"), text_hash("ABC")));
        assert!(!pane.docs[0].dirty);
    }

    /// P3-2: a failed write keeps the old disk hash and the dirty mark.
    #[test]
    fn failed_save_keeps_dirty() {
        let mut pane = Docs::default();
        let first = open(&mut pane, "a.txt", false);
        pane.finish_read(first, ReadOutcome::Changed(text_hash("A"), UTF8, text_hash("A")));
        pane.on_edit(0, text_hash("AB"));
        let SaveStart::Write(token, _) = pane.begin_save(0, "AB") else { panic!("expected a write") };
        pane.finish_save(token, false, text_hash("AB"), text_hash("AB"));
        let t = &pane.docs[0];
        assert_eq!((t.hash, t.dirty, t.saving), (text_hash("A"), true, None));
    }

    /// P3-2: an undecodable file is shown but never editable or saved.
    #[test]
    fn undecodable_file_is_read_only_and_not_saved() {
        let mut pane = Docs::default();
        let first = open(&mut pane, "bin.dat", false);
        assert!(pane.finish_read(first, ReadOutcome::Changed(text_hash("\u{FFFD}"), None, text_hash("\u{FFFD}"))).accepted());
        assert!(!pane.docs[0].loaded);
        assert_eq!(pane.begin_save(0, "\u{FFFD}"), SaveStart::Skip);
    }

    /// P3-2: CP949 text with a character CP949 cannot hold is refused (no best-fit) and nothing is in flight.
    #[cfg(windows)]
    #[test]
    fn cp949_loss_refuses_save() {
        let mut pane = Docs::default();
        let first = open(&mut pane, "k.txt", false);
        pane.finish_read(first, ReadOutcome::Changed(text_hash("가격"), fmt(TextEncoding::Cp949, LineEnding::Lf), text_hash("가격")));
        pane.on_edit(0, text_hash("가격 \u{20A9}1000"));
        let SaveStart::Refused(e) = pane.begin_save(0, "가격 \u{20A9}1000") else { panic!("expected refusal") };
        assert!(e.contains("U+20A9"), "{e}");
        assert_eq!(pane.docs[0].saving, None);
    }

    /// Loaded "A", edited to `buffer`, save started. Returns the save token.
    fn loaded_and_saving(pane: &mut Docs, buffer: &str) -> u64 {
        let first = open(pane, "a.txt", false);
        pane.finish_read(first, ReadOutcome::Changed(text_hash("A"), UTF8, text_hash("A")));
        pane.on_edit(0, text_hash(buffer));
        let SaveStart::Write(token, _) = pane.begin_save(0, buffer) else { panic!("expected a write") };
        token
    }

    /// P3-12-R1 (review 2-A): the app's own write is read back by a reload that started during the save and lands
    /// after it. It must not fill the editor again (set_value would reset undo and the cursor).
    #[test]
    fn own_write_read_back_after_save_is_dropped() {
        let mut pane = Docs::default();
        let save = loaded_and_saving(&mut pane, "B");
        let reload = pane.start_read(0);
        assert!(pane.finish_save(save, true, text_hash("B"), text_hash("B")));
        assert_eq!(pane.finish_read(reload, ReadOutcome::Changed(text_hash("B"), UTF8, text_hash("B"))), ReadApply::Dropped);
        let t = &pane.docs[0];
        assert_eq!((t.hash, t.dirty), (text_hash("B"), false));
        // A reload started after the save reads the same text: accepted but nothing to fill.
        let after = pane.start_read(0);
        assert_eq!(pane.finish_read(after, ReadOutcome::Changed(text_hash("B"), UTF8, text_hash("B"))), ReadApply::Kept);
    }

    /// P3-12-R1 (review 2-B): a reload started before the save (it read an older external "B") lands after "C" was
    /// saved. It must not replace the saved buffer.
    #[test]
    fn stale_read_from_before_save_is_dropped() {
        let mut pane = Docs::default();
        let first = open(&mut pane, "a.txt", false);
        pane.finish_read(first, ReadOutcome::Changed(text_hash("A"), UTF8, text_hash("A")));
        let reload = pane.start_read(0);
        pane.on_edit(0, text_hash("C"));
        let SaveStart::Write(save, _) = pane.begin_save(0, "C") else { panic!("expected a write") };
        assert!(pane.finish_save(save, true, text_hash("C"), text_hash("C")));
        assert_eq!(pane.finish_read(reload, ReadOutcome::Changed(text_hash("B"), UTF8, text_hash("B"))), ReadApply::Dropped);
        let t = &pane.docs[0];
        assert_eq!((t.hash, t.dirty), (text_hash("C"), false));
    }

    /// P3-12-R1: a read that lands while a save is running is dropped even when the buffer is clean again (undo
    /// back to the disk text during the save), and the save's end invalidates it.
    #[test]
    fn read_landing_during_save_is_dropped() {
        let mut pane = Docs::default();
        let save = loaded_and_saving(&mut pane, "B");
        pane.on_edit(0, text_hash("A"));
        assert!(!pane.docs[0].dirty);
        let reload = pane.start_read(0);
        assert_eq!(pane.finish_read(reload, ReadOutcome::Changed(text_hash("X"), UTF8, text_hash("X"))), ReadApply::Dropped);
        pane.finish_save(save, true, text_hash("B"), text_hash("A"));
        let t = &pane.docs[0];
        assert_eq!((t.hash, t.dirty), (text_hash("B"), true));
    }

    /// H-15: an unedited tab is not written (a mixed-ending file keeps its bytes); after an edit the save uses the
    /// detected majority ending.
    #[test]
    fn clean_tab_is_not_written_and_edit_saves_majority_ending() {
        let mut pane = Docs::default();
        let first = open(&mut pane, "mixed.txt", false);
        // "a\nb\r\nc\r\nd" read as LF text, CRLF by majority.
        pane.finish_read(first, ReadOutcome::Changed(text_hash("a\nb\nc\nd"), fmt(TextEncoding::Utf8, LineEnding::Crlf), text_hash("a\nb\nc\nd")));
        assert_eq!(pane.begin_save(0, "a\nb\nc\nd"), SaveStart::Skip, "no write without an edit");
        pane.on_edit(0, text_hash("a\nb\nc\nd\ne"));
        let SaveStart::Write(_, bytes) = pane.begin_save(0, "a\nb\nc\nd\ne") else { panic!("expected a write") };
        assert_eq!(bytes, b"a\r\nb\r\nc\r\nd\r\ne");
    }

    /// P3-12-R1: the tab's line ending is used for the save, typed lines included.
    #[test]
    fn save_writes_tab_line_ending() {
        let mut pane = Docs::default();
        let first = open(&mut pane, "a.txt", false);
        pane.finish_read(first, ReadOutcome::Changed(text_hash("a\nb"), fmt(TextEncoding::Utf8, LineEnding::Crlf), text_hash("a\nb")));
        pane.on_edit(0, text_hash("a\nb\nc"));
        let SaveStart::Write(_, bytes) = pane.begin_save(0, "a\nb\nc") else { panic!("expected a write") };
        assert_eq!(bytes, b"a\r\nb\r\nc");
    }

    /// P3-3: closing keeps the active tab active; closing the active one picks the tab that slides in, else the last.
    #[test]
    fn close_tab_picks_next_active() {
        let mut pane = Pane::<()>::default();
        for n in ["a", "b", "c", "d"] {
            view(&mut pane, n, false);
        }
        assert_eq!(pane.active, Some(3));
        pane.close_tab(0);
        assert_eq!(pane.active, Some(2), "left of active closed: follow the same tab");
        pane.active = Some(0);
        pane.close_tab(0);
        assert_eq!((pane.active, pane.tabs[0].title()), (Some(0), "c".into()), "right neighbour slides in");
        pane.close_tab(1);
        assert_eq!(pane.active, Some(0));
        pane.close_tab(0);
        assert_eq!((pane.active, pane.tabs.len()), (None, 0));
        assert!(pane.close_tab(0).is_none());
    }

    /// P3-3: a closed tab's late read and save results are dropped.
    #[test]
    fn closed_tab_ignores_late_results() {
        let mut pane = Docs::default();
        let first = open(&mut pane, "a.txt", false);
        pane.finish_read(first, ReadOutcome::Changed(text_hash("A"), UTF8, bytes_hash(b"A")));
        pane.on_edit(0, text_hash("AB"));
        let SaveStart::Write(save, _) = pane.begin_save(0, "AB") else { panic!("expected a write") };
        let reload = pane.start_read(0);
        pane.remove(Path::new("a.txt"));
        assert!(!pane.finish_save(save, true, text_hash("AB"), text_hash("AB")));
        assert_eq!(pane.finish_read(reload, ReadOutcome::Changed(1, UTF8, 1)), ReadApply::Dropped);
    }

    /// P3-3: "Discard Edits" resets the tab to the disk read.
    #[test]
    fn discard_edits_resets_to_disk() {
        let mut pane = Docs::default();
        let first = open(&mut pane, "a.txt", false);
        pane.finish_read(first, ReadOutcome::Changed(text_hash("A"), UTF8, bytes_hash(b"A")));
        pane.on_edit(0, text_hash("AB"));
        pane.discard_edits(0, text_hash("B"), UTF8, bytes_hash(b"B"));
        let t = &pane.docs[0];
        assert_eq!((t.hash, t.dirty, t.pending, t.disk_hash, t.disk_changed), (text_hash("B"), false, None, bytes_hash(b"B"), false));
    }

    /// P3-3-R1 (review 2): a save in flight is waited for before anything else, even when undo made the buffer look
    /// clean; after it ends the buffer is judged again (a later edit asks, a matching buffer is clean).
    #[test]
    fn close_waits_for_save_then_rejudges_buffer() {
        let mut pane = Docs::default();
        let save = loaded_and_saving(&mut pane, "B");
        let p = Path::new("a.txt");
        pane.on_edit(0, text_hash("A")); // undo back to the disk text while "B" is being written
        assert!(!pane.docs[0].modified());
        assert_eq!(pane.close_state(p), CloseState::Wait);
        pane.finish_save(save, true, text_hash("B"), text_hash("A"));
        assert_eq!(pane.close_state(p), CloseState::Ask, "buffer A differs from the saved B");
        let SaveStart::Write(save, _) = pane.begin_save(0, "A") else { panic!("expected a write") };
        assert_eq!(pane.close_state(p), CloseState::Wait);
        pane.finish_save(save, true, text_hash("A"), text_hash("A"));
        assert_eq!(pane.close_state(p), CloseState::Clean);
        assert_eq!(pane.close_state(Path::new("x")), CloseState::Gone);
    }

    /// P3-3-R1 (review 1): edits typed while the save wrote leave the tab to ask again, not to close.
    #[test]
    fn edit_during_save_asks_again() {
        let mut pane = Docs::default();
        let save = loaded_and_saving(&mut pane, "B");
        pane.on_edit(0, text_hash("BC"));
        pane.finish_save(save, true, text_hash("B"), text_hash("BC"));
        assert_eq!(pane.close_state(Path::new("a.txt")), CloseState::Ask);
    }

    /// P3-3-R2: two dirty tabs closing together. Each step re-reads every tab: a tab re-edited after its save or a
    /// new dirty tab keeps the close from finishing (R1 guarantee), and a save that never ends aborts only the
    /// close request, leaving the save and the tab as they were.
    #[test]
    fn multi_tab_exit_rejudges_until_clean_and_aborts_on_stuck_save() {
        use super::super::tab_close::{Next, next};
        use std::time::Duration;
        let mut pane = Docs::default();
        for n in ["a.txt", "b.txt"] {
            let t = open(&mut pane, n, false);
            pane.finish_read(t, ReadOutcome::Changed(text_hash("0"), UTF8, bytes_hash(b"0")));
        }
        let (a, b) = (Path::new("a.txt"), Path::new("b.txt"));
        let look = |pane: &Docs, waited| {
            let all: Vec<_> = pane.docs.iter().map(|t| pane.close_state(&t.path)).collect();
            next(&all, Duration::from_secs(waited))
        };
        let (ia, ib) = (pane.find(a).unwrap(), pane.find(b).unwrap());
        pane.on_edit(ia, text_hash("A1"));
        pane.on_edit(ib, text_hash("B1"));
        assert_eq!(look(&pane, 0), Next::Ask);
        // "Save all": a is saved, b is being written, and the user types into a again meanwhile.
        let SaveStart::Write(ta, _) = pane.begin_save(ia, "A1") else { panic!("write") };
        pane.finish_save(ta, true, text_hash("A1"), text_hash("A1"));
        let SaveStart::Write(tb, _) = pane.begin_save(ib, "B1") else { panic!("write") };
        assert_eq!(look(&pane, 0), Next::Sleep);
        pane.on_edit(ia, text_hash("A2"));
        assert_eq!(look(&pane, 1), Next::Sleep);
        // The write of b never finishes: after the limit only the close request is dropped; nothing else changes.
        assert_eq!(look(&pane, 10), Next::Abort);
        assert_eq!((pane.docs[ib].saving, pane.docs[ib].dirty), (Some(tb), true));
        // A later request is judged normally once the write ends: a (re-edited) still needs a question.
        pane.finish_save(tb, true, text_hash("B1"), text_hash("B1"));
        assert_eq!(look(&pane, 0), Next::Ask, "a was edited after its save");
        let SaveStart::Write(ta, _) = pane.begin_save(ia, "A2") else { panic!("write") };
        pane.finish_save(ta, true, text_hash("A2"), text_hash("A2"));
        assert_eq!(look(&pane, 0), Next::Finish);
        // A new dirty tab opened meanwhile is asked about too.
        let t = open(&mut pane, "c.txt", false);
        pane.finish_read(t, ReadOutcome::Changed(text_hash("0"), UTF8, bytes_hash(b"0")));
        let ic = pane.find(Path::new("c.txt")).unwrap();
        pane.on_edit(ic, text_hash("C1"));
        assert_eq!(look(&pane, 0), Next::Ask);
    }

    /// P3-3-R1 (review 3): the pre-save check and the watch reload share one rule on raw bytes (H-18): a re-encoded
    /// file differs even when its text is equal, identical bytes do not.
    #[test]
    fn disk_rule_is_on_raw_bytes() {
        assert!(disk_differs(bytes_hash(b"\xFF\xFEA\0"), bytes_hash(b"A")));
        assert!(disk_differs(bytes_hash(b"a\r\nb"), bytes_hash(b"a\nb")));
        assert!(!disk_differs(bytes_hash(b"a\nb"), bytes_hash(b"a\nb")));
    }

    /// P4-3-R1 (2): a read in flight when the file is renamed does not apply (it may have read the old place); the
    /// renamed doc is returned for a new read, which fills the views at the new path.
    #[test]
    fn rename_during_read_drops_it_and_rereads_new_path() {
        let mut pane = Docs::default();
        let first = open(&mut pane, "d/a.txt", false);
        let other = open(&mut pane, "e.txt", false);
        assert_eq!(pane.rename_path(Path::new("d"), Path::new("f")), vec![std::path::PathBuf::from("f/a.txt")]);
        assert_eq!(pane.finish_read(first, ReadOutcome::Changed(text_hash("A"), UTF8, 1)), ReadApply::Dropped);
        assert!(!pane.docs[0].loaded, "not loaded: still read-only, nothing typed can replace the file");
        let again = pane.start_read(0);
        assert_eq!(pane.finish_read(again, ReadOutcome::Changed(text_hash("A"), UTF8, 1)), ReadApply::Fill("f/a.txt".into()));
        assert!(pane.docs[0].loaded && pane.docs[0].hash == text_hash("A"));
        assert!(pane.finish_read(other, ReadOutcome::Same(UTF8)).accepted(), "untouched doc keeps its read");
        assert!(pane.rename_path(Path::new("d"), Path::new("g")).is_empty());
    }

    /// phase3-final Must fix 1: Save started, the file renamed in the app, then the write to the old path finished. The
    /// tab (now at the new path, whose bytes are still the old read) stays modified with the old reference, the buffer is
    /// kept, and the next save writes the new path.
    #[test]
    fn rename_during_save_keeps_tab_unsaved() {
        let mut pane = Docs::default();
        let first = open(&mut pane, "a.txt", false);
        pane.finish_read(first, ReadOutcome::Changed(text_hash("old"), UTF8, bytes_hash(b"old")));
        pane.on_edit(0, text_hash("new"));
        let SaveStart::Write(token, _) = pane.begin_save(0, "new") else { panic!("expected a write") };
        pane.rename_path(Path::new("a.txt"), Path::new("b.txt"));
        assert!(pane.finish_save(token, true, text_hash("new"), text_hash("new")));
        let t = &pane.docs[0];
        assert_eq!((t.path.as_path(), t.hash, t.disk_hash, t.saving), (Path::new("b.txt"), UNSURE_HASH, UNSURE_HASH, None));
        assert!(t.dirty && t.modified());
        assert_eq!(pane.close_state(Path::new("b.txt")), CloseState::Ask, "closing still asks");
        let SaveStart::Write(token, bytes) = pane.begin_save(0, "new") else { panic!("saves again, to b.txt") };
        assert!(pane.finish_save(token, true, text_hash("new"), text_hash("new")));
        assert!(!pane.docs[0].modified() && pane.docs[0].disk_hash == bytes_hash(&bytes));
    }

    /// phase3-final R1: undo back to the read text while the save runs, then the path changes before the completion.
    /// Whether the write landed before the move (b holds "new") or after it (b holds "old"), the tab stays modified:
    /// closing asks, later undos and edits keep it dirty, and the reload keeps the buffer (only marks the conflict).
    #[test]
    fn undo_during_save_then_rename_stays_unsure() {
        for disk_now in ["new", "old"] {
            let mut pane = Docs::default();
            let first = open(&mut pane, "a.txt", false);
            pane.finish_read(first, ReadOutcome::Changed(text_hash("old"), UTF8, bytes_hash(b"old")));
            pane.on_edit(0, text_hash("new"));
            let SaveStart::Write(token, _) = pane.begin_save(0, "new") else { panic!("expected a write") };
            pane.on_edit(0, text_hash("old")); // undo while writing
            assert!(!pane.docs[0].dirty);
            pane.rename_path(Path::new("a.txt"), Path::new("b.txt"));
            pane.finish_save(token, true, text_hash("new"), text_hash("old"));
            let b = Path::new("b.txt");
            assert!(pane.docs[0].dirty && pane.docs[0].modified(), "{disk_now}: not clean");
            assert_eq!(pane.close_state(b), CloseState::Ask, "{disk_now}: closing asks");
            pane.on_edit(0, text_hash("old"));
            pane.on_edit(0, text_hash("new"));
            assert!(pane.docs[0].dirty, "{disk_now}: no buffer matches the unknown reference");
            let reload = pane.start_read(0);
            let raw = bytes_hash(disk_now.as_bytes());
            assert_eq!(pane.finish_read(reload, ReadOutcome::Changed(text_hash(disk_now), UTF8, raw)), ReadApply::Dropped, "{disk_now}: buffer kept");
            assert!(pane.docs[0].has_conflict(), "{disk_now}: shown as changed on disk");
            let SaveStart::Write(token, bytes) = pane.begin_save(0, "new") else { panic!("{disk_now}: saves again") };
            pane.finish_save(token, true, text_hash("new"), text_hash("new"));
            assert!(!pane.docs[0].modified() && pane.docs[0].disk_hash == bytes_hash(&bytes), "{disk_now}: settled by the save");
        }
    }

    /// P3-12-R1: a pasted "\r\n" hashes like the LF text reads produce, so it is not a phantom edit.
    #[test]
    fn pasted_crlf_hashes_as_lf() {
        assert_eq!(buffer_hash("a\r\nb"), text_hash("a\nb"));
        assert_eq!(buffer_hash("a\nb"), text_hash("a\nb"));
    }

    fn names(pane: &Pane<()>) -> Vec<String> {
        pane.tabs.iter().map(|t| t.title()).collect()
    }

    fn previews(pane: &Pane<()>) -> Vec<bool> {
        pane.tabs.iter().map(|t| t.preview).collect()
    }

    /// I-060: preview, normal and pinned are three states; a pinned tab is never a preview.
    #[test]
    fn i060_pinned_is_never_preview() {
        let mut pane = Pane::<()>::default();
        view(&mut pane, "a", true);
        pane.toggle_pin(0);
        assert!(pane.is_pinned(0));
        assert!(!pane.tabs[0].preview);
        // The next preview open makes a new tab instead of replacing the pinned one.
        view(&mut pane, "b", true);
        assert_eq!(names(&pane), ["a", "b"]);
        assert_eq!(previews(&pane), [false, true]);
    }

    /// I-061: a single-click (preview) open makes a preview tab; a non-preview open makes a normal one.
    #[test]
    fn i061_preview_open_is_preview() {
        let mut pane = Pane::<()>::default();
        view(&mut pane, "a", true);
        view(&mut pane, "b", false);
        assert_eq!(previews(&pane), [true, false]);
    }

    /// I-062: one preview per pane, replaced at its own index (not the active one); other panes are separate.
    #[test]
    fn i062_preview_replaced_in_place() {
        let mut pane = Pane::<()>::default();
        view(&mut pane, "a", false);
        view(&mut pane, "p", true);
        view(&mut pane, "b", false);
        pane.active = Some(0);
        view(&mut pane, "q", true);
        assert_eq!(names(&pane), ["a", "q", "b"]);
        assert_eq!(pane.active, Some(1));
        assert_eq!(pane.tabs.iter().filter(|t| t.preview).count(), 1);
        let mut other = Pane::<()>::default();
        view(&mut other, "r", true);
        assert!(pane.tabs[1].preview && other.tabs[0].preview);
    }

    /// I-063: an edit or a double-click (`promote`) makes a preview tab normal; the next preview open adds a tab.
    #[test]
    fn i063_double_click_promotes() {
        let mut pane = Pane::<()>::default();
        view(&mut pane, "a", true);
        pane.promote(0);
        assert!(!pane.tabs[0].preview);
        assert!(!pane.is_pinned(0), "promoting does not pin (I-065)");
        view(&mut pane, "b", true);
        assert_eq!(names(&pane), ["a", "b"]);
        pane.promote(1); // an edit promotes the same way (`PaneGroup::on_edit`)
        assert_eq!(previews(&pane), [false, false]);
    }

    /// I-064: the italic title is drawn from `preview` alone (layout `TabView`); dev output reports the same state.
    #[test]
    fn i064_preview_state_is_reported() {
        let mut pane = Pane::<()>::default();
        view(&mut pane, "a", true);
        view(&mut pane, "b", false);
        assert_eq!(pane.describe(), "a|preview|a\tb|normal|b");
        pane.toggle_pin(0);
        assert!(pane.describe().starts_with("a|normal|"));
    }

    /// I-065: pin moves the tab to the end of the pinned run and clears preview; unpin moves it right after the run.
    /// The active tab follows its tab.
    #[test]
    fn i065_toggle_pin_moves_tab() {
        let mut pane = Pane::<()>::default();
        for p in ["a", "b", "c", "d"] {
            view(&mut pane, p, false);
        }
        pane.active = Some(2);
        pane.toggle_pin(2);
        assert_eq!((names(&pane), pane.pinned_count, pane.active), (vec!["c".into(), "a".into(), "b".into(), "d".into()], 1, Some(0)));
        pane.toggle_pin(3);
        assert_eq!((names(&pane), pane.pinned_count, pane.active), (vec!["c".into(), "d".into(), "a".into(), "b".into()], 2, Some(0)));
        pane.toggle_pin(0);
        assert_eq!((names(&pane), pane.pinned_count, pane.active), (vec!["d".into(), "c".into(), "a".into(), "b".into()], 1, Some(1)));
        // New tabs never land inside the pinned run, even after a pinned active tab (I-719).
        pane.active = Some(0);
        view(&mut pane, "e", false);
        assert_eq!(names(&pane)[1], "e");
        assert!(!pane.is_pinned(1));
        // Closing a pinned tab shrinks the run.
        pane.close_tab(0);
        assert_eq!(pane.pinned_count, 0);
    }

    /// I-066: normal closes leave pinned tabs; unpinned tabs close as before.
    #[test]
    fn i066_pinned_tab_protected_from_normal_close() {
        let mut pane = Pane::<()>::default();
        view(&mut pane, "a", false);
        view(&mut pane, "b", false);
        pane.toggle_pin(0);
        assert!(pane.close_protected(0));
        assert!(!pane.close_protected(1));
    }
}

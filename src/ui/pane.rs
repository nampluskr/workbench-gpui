//! 최소 탭 (v0.2 Phase 4, SPEC R-27, DECISIONS D-9·D-18). 폴더(Workspace)마다 Pane 하나를 둔다(A-15.1).
//!
//! - 트리에서 임시(preview)로 열거나 일반 탭으로 연다(I-087, I-033, I-061).
//! - 임시 탭은 하나다. 다른 파일을 임시로 열면 그 자리(인덱스)에서 바꾼다(I-062).
//! - 이미 임시로 열린 파일을 일반으로 열면 일반 탭이 된다(I-063).
//! - 새 탭은 활성 탭 바로 뒤에 넣는다(판단: Zed 의 새 항목 자리).
//! - Tabs are editable (v0.4 D-6, P3-1; D-18 lifted). A tab is dirty when its buffer differs from the content last
//!   read from disk (`hash`). An edit promotes a preview tab to a normal tab (I-063). The editor stays read-only
//!   until the first read lands, so typing cannot race the load. Dirty buffers are not reloaded (P3-4 marks them).
//! - Reads detect the encoding (`text_io`, P3-2) and saves write it back unchanged (BOM, UTF-16, CP949; line endings
//!   stay in the text). An undecodable file is shown lossily and stays read-only, so a save cannot corrupt it.
//! - First open reads the file on the background executor; the tab exists at once and gets its text when
//!   the read finishes (v0.4 P1-3, AUDIT 4). First read and watch reload share one request token per tab:
//!   only the latest started read applies, and a closed pane (folder removed) applies nothing.

use std::path::{Path, PathBuf};
use std::rc::Rc;

use gpui_kit::base::Scrollbar;
use gpui_kit::base::input::EditorScrollbarContext;
use gpui_kit::component::input::{Editor, EditorState, InputEvent};
use gpui_kit::*;

use super::folders::FolderWorkspace;
use super::metrics;
use crate::text_io::{self, Format};

/// `E` is the editor handle; generic only so tab bookkeeping is testable without a window.
pub struct Tab<E = Entity<EditorState>> {
    pub path: PathBuf,
    pub preview: bool,
    pub editor: E,
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
}

/// How a finished read ended (first read or watch reload), with the detected format (`None`: undecodable).
/// Hashes are of the editor representation (`\n` line endings, `text_io::decode_text`).
pub enum ReadOutcome {
    /// Disk content equals the hash the read started with.
    Same(Option<Format>),
    /// New disk content with this hash.
    Changed(u64, Option<Format>),
    Unreadable,
}

/// What `finish_read` decided.
#[derive(Debug, PartialEq)]
pub enum ReadApply<'a, E> {
    /// Not the tab's latest read, the tab is dirty or saving, or the pane is closed: ignore the result.
    Dropped,
    /// Accepted, the buffer already matches (same hash or unreadable): leave the editor alone (`set_value` would
    /// reset selection, scroll and undo).
    Kept,
    /// Accepted with new content: fill this editor.
    Fill(&'a E),
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

pub struct Pane<E = Entity<EditorState>> {
    pub tabs: Vec<Tab<E>>,
    pub active: Option<usize>,
    next_load: u64,
    /// Set when the folder is removed; reads finishing afterwards are dropped (strong refs may keep it alive).
    closed: bool,
}

impl<E> Default for Pane<E> {
    fn default() -> Self {
        Self { tabs: Vec::new(), active: None, next_load: 0, closed: false }
    }
}

/// 내용 해시: UTF-8 바이트의 FNV-1a 64(dev 출력 `fnv=` 와 같은 값).
pub fn text_hash(text: &str) -> u64 {
    text.bytes().fold(0xcbf29ce484222325u64, |h, b| (h ^ b as u64).wrapping_mul(0x100000001b3))
}

/// Hash of the editor buffer in the representation reads produce (LF, `text_io::to_lf`), so a pasted `\r\n`
/// compares equal to the file it will be saved as.
fn buffer_hash(text: &str) -> u64 {
    if text.contains("\r\n") { text_hash(&text.replace("\r\n", "\n")) } else { text_hash(text) }
}

/// Tab editor scrollbar: gpui-base's own scrollbar on the editor's scroll handle, track width from the spec
/// (P2-5, D-10 item 6). Axis follows the editor (vertical with soft wrap, both without), like gpui-base's default.
fn editor_scrollbar(context: EditorScrollbarContext, _: &mut Window, _: &mut App) -> AnyElement {
    Scrollbar::new(&context)
        .axis(context.axis())
        .styles(|s| s.track(|t| t.width(metrics::EDITOR_SCROLLBAR_WIDTH)))
        .into_any_element()
}

/// Tab editor element. Ctrl+Shift+drag starts a column selection at the pointer (E-047, P2-6). gpui-base binds
/// that to Alt+Shift only, inside its private `on_mouse_down` (gpui-base state.rs 2750), so the press is swallowed
/// in the capture phase and re-sent as Alt+Shift at the same spot; the drag then runs gpui-base's own block
/// selection (virtual columns, wrapped rows). Deferred: gpui takes the listener list out while dispatching.
/// `readonly` while the first read is pending (`!Tab::loaded`).
pub fn editor_view(editor: &Entity<EditorState>, readonly: bool) -> impl IntoElement {
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
                .readonly(readonly)
                .text_size(metrics::BUFFER_FONT_SIZE)
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
/// undecodable file comes back as lossy UTF-8 with no format, so it stays read-only. `None` when unreadable.
pub fn read_text(path: &Path) -> Option<(String, Option<Format>)> {
    let bytes = std::fs::read(path).ok()?;
    Some(match text_io::decode_text(&bytes) {
        Ok((text, format)) => (text, Some(format)),
        Err(_) => (text_io::to_lf(String::from_utf8_lossy(&bytes).into_owned()), None),
    })
}

impl<E> Pane<E> {
    pub fn find(&self, path: &Path) -> Option<usize> {
        self.tabs.iter().position(|t| t.path == path)
    }

    pub fn active_tab(&self) -> Option<&Tab<E>> {
        self.active.and_then(|i| self.tabs.get(i))
    }

    fn next_token(&mut self) -> u64 {
        self.next_load += 1;
        self.next_load
    }

    /// A new pending tab for `path` with a fresh read token.
    fn pending_tab(&mut self, path: &Path, preview: bool, editor: E) -> (Tab<E>, u64) {
        let token = self.next_token();
        let tab = Tab {
            path: path.to_path_buf(),
            preview,
            editor,
            hash: text_hash(""),
            pending: Some(token),
            dirty: false,
            loaded: false,
            format: None,
            saving: None,
        };
        (tab, token)
    }

    /// Starts a read for tab `ix`; any earlier read of that tab stops applying.
    pub fn start_read(&mut self, ix: usize) -> u64 {
        let token = self.next_token();
        self.tabs[ix].pending = Some(token);
        token
    }

    /// Drops every pending read (folder removal).
    pub fn close(&mut self) {
        self.closed = true;
    }

    /// Puts a new tab in place: replaces the preview tab (I-062) or inserts after the active tab. Returns its index.
    fn place(&mut self, tab: Tab<E>) -> usize {
        if tab.preview
            && let Some(pi) = self.tabs.iter().position(|t| t.preview)
        {
            self.tabs[pi] = tab;
            self.active = Some(pi);
            return pi;
        }
        let at = self.active.map(|a| a + 1).unwrap_or(self.tabs.len()).min(self.tabs.len());
        self.tabs.insert(at, tab);
        self.active = Some(at);
        at
    }

    /// Decides a finished read. It applies only if it is still the tab's latest read; a replaced, removed or closed
    /// tab drops it, a dirty tab keeps its buffer (no reload over edits, P3-1; P3-4 adds the conflict mark), and so
    /// does a tab being saved. A save also invalidates reads started before it finished (`finish_save`), so a read
    /// from before or during a save never lands after it. Content cannot change between start and accept: only the
    /// latest token applies, and edits make the tab dirty.
    pub fn finish_read(&mut self, token: u64, outcome: ReadOutcome) -> ReadApply<'_, E> {
        if self.closed {
            return ReadApply::Dropped;
        }
        let Some(tab) = self.tabs.iter_mut().find(|t| t.pending == Some(token)) else {
            return ReadApply::Dropped;
        };
        tab.pending = None;
        if tab.dirty || tab.saving.is_some() {
            return ReadApply::Dropped;
        }
        match outcome {
            ReadOutcome::Changed(h, format) => {
                tab.format = format;
                tab.loaded = format.is_some();
                if h == tab.hash {
                    // The buffer already holds it (e.g. the app's own write read back, D-046).
                    return ReadApply::Kept;
                }
                tab.hash = h;
                ReadApply::Fill(&tab.editor)
            }
            ReadOutcome::Same(format) => {
                tab.format = format;
                tab.loaded = format.is_some();
                ReadApply::Kept
            }
            ReadOutcome::Unreadable => ReadApply::Kept,
        }
    }

    /// Starts saving tab `ix` whose buffer is `text`: encodes it with the tab's encoding and line ending (P3-2, D-6).
    /// A tab that is not dirty is not written (H-15), so an unedited file keeps its exact bytes.
    pub fn begin_save(&mut self, ix: usize, text: &str) -> SaveStart {
        let tab = &self.tabs[ix];
        let (true, true, Some(format), None) = (tab.loaded, tab.dirty, tab.format, tab.saving) else {
            return SaveStart::Skip;
        };
        match text_io::encode_text(text, format) {
            Ok(bytes) => {
                let token = self.next_token();
                self.tabs[ix].saving = Some(token);
                SaveStart::Write(token, bytes)
            }
            Err(e) => SaveStart::Refused(e),
        }
    }

    /// The save with `token` finished. On success the disk now holds `saved_hash` (the hash the watch reload
    /// compares with, so the app's own write reads back as `Same`, D-046) and the tab is dirty only if the buffer
    /// (`buffer_hash`) changed since. Reads started before now are invalidated either way: they may hold content
    /// from before the write. Returns `false` when the tab is gone.
    pub fn finish_save(&mut self, token: u64, ok: bool, saved_hash: u64, buffer_hash: u64) -> bool {
        let Some(tab) = self.tabs.iter_mut().find(|t| t.saving == Some(token)) else {
            return false;
        };
        tab.saving = None;
        tab.pending = None;
        if ok {
            tab.hash = saved_hash;
            tab.dirty = buffer_hash != saved_hash;
        }
        true
    }

    /// A user edit on tab `ix` whose buffer now hashes to `buffer_hash`: dirty when it differs from the disk
    /// content, and the edit promotes a preview tab (I-063).
    pub fn on_edit(&mut self, ix: usize, buffer_hash: u64) {
        let tab = &mut self.tabs[ix];
        tab.dirty = buffer_hash != tab.hash;
        tab.preview = false;
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
}

impl super::Workbench {
    /// `workspace::Save` (Ctrl-S, E-088): writes the active tab with its own encoding and line ending in the
    /// background (AUDIT 4). A CP949 loss or a write error is shown as E-083's "Unable to save file: {error}";
    /// `text_io::write_file` swaps a complete temp file in and keeps it (named in the error) if the swap lost the
    /// original.
    pub(super) fn on_save(&mut self, action: &super::keymap::workspace::Save, window: &mut Window, cx: &mut Context<Self>) {
        super::keymap::log_handled(action, self.focus_name(window, cx), cx);
        let Some(ws) = self.active_ws() else { return };
        let Some((ix, editor, path)) =
            ws.read(cx).pane.active.and_then(|i| ws.read(cx).pane.tabs.get(i).map(|t| (i, t.editor.clone(), t.path.clone())))
        else {
            return;
        };
        let text = editor.read(cx).value();
        let saved_hash = buffer_hash(&text);
        let dev = super::keymap::dev_enabled(cx);
        let (token, bytes) = match ws.update(cx, |ws, _| ws.pane.begin_save(ix, &text)) {
            SaveStart::Skip => return,
            SaveStart::Refused(e) => return save_failed(&path, &e, window, cx),
            SaveStart::Write(token, bytes) => (token, bytes),
        };
        cx.spawn_in(window, async move |_, cx| {
            let target = path.clone();
            let len = bytes.len();
            let result = cx
                .background_executor()
                .spawn(async move { text_io::write_file(&target, &bytes).map_err(|e| e.to_string()) })
                .await;
            let _ = cx.update(|window, cx| {
                let buffer_now = buffer_hash(&editor.read(cx).value());
                ws.update(cx, |ws, cx| {
                    ws.pane.finish_save(token, result.is_ok(), saved_hash, buffer_now);
                    cx.notify();
                });
                if dev {
                    println!("[dev] tab-save path={} bytes={len} ok={} fnv={saved_hash:016x}", path.display(), result.is_ok());
                }
                if let Err(e) = &result {
                    save_failed(&path, e, window, cx);
                }
            });
        })
        .detach();
    }
}

/// E-083 "Unable to save file: {error}" as a notification (D-14), plus the dev line other notifications use.
fn save_failed(path: &Path, error: &str, window: &mut Window, cx: &mut App) {
    use gpui_kit::component::WindowExt as _;
    let text = format!("Unable to save file: {error}");
    if super::keymap::dev_enabled(cx) {
        println!("[dev] notification text={text} path={}", path.display());
    }
    window.push_notification(SharedString::from(text), cx);
}

impl Pane {
    /// 파일을 연다. 돌려주는 값: (탭 번호, 새로 만들었나). A new tab starts empty and is filled when the
    /// background read finishes; the result is dropped if the tab or workspace is gone by then.
    pub fn open(
        &mut self,
        path: &Path,
        preview: bool,
        window: &mut Window,
        cx: &mut Context<FolderWorkspace>,
    ) -> (usize, bool) {
        if let Some(i) = self.find(path) {
            if !preview {
                self.tabs[i].preview = false;
            }
            self.active = Some(i);
            return (i, false);
        }
        let editor = cx.new(|cx| {
            let mut state = EditorState::new(window, cx);
            state.set_scrollbar_renderer(Some(Rc::new(editor_scrollbar)));
            state
        });
        // Only user edits emit Change (`set_value` does not), so this tracks edits, not reads.
        cx.subscribe(&editor, |ws, editor, event: &InputEvent, cx| {
            if !matches!(event, InputEvent::Change) {
                return;
            }
            // shortcut: hashes the whole buffer per edit, fine for typical files; keep a running state if large files lag.
            let h = buffer_hash(&editor.read(cx).value());
            if let Some(ix) = ws.pane.tabs.iter().position(|t| t.editor == editor) {
                ws.pane.on_edit(ix, h);
                cx.notify();
            }
        })
        .detach();
        let (tab, token) = self.pending_tab(path, preview, editor);
        let ix = self.place(tab);
        let path = path.to_path_buf();
        cx.spawn_in(window, async move |ws, cx| {
            let text = cx.background_executor().spawn(async move { read_text(&path) }).await;
            let _ = ws.update_in(cx, |ws, window, cx| {
                let outcome = match &text {
                    Some((t, format)) => ReadOutcome::Changed(text_hash(t), *format),
                    None => ReadOutcome::Unreadable,
                };
                if let ReadApply::Fill(editor) = ws.pane.finish_read(token, outcome)
                    && let Some((text, _)) = &text
                {
                    let editor = editor.clone();
                    editor.update(cx, |e, cx| e.set_value(text.as_str(), window, cx));
                }
                // The window reads `loaded` to lift read-only; redraw it.
                cx.notify();
            });
        })
        .detach();
        (ix, true)
    }
}

#[cfg(test)]
mod tests {
    // Explicit imports: `super::*` would pull in gpui's `test` macro through `gpui_kit::*`.
    use super::{
        buffer_hash, Capslock, Modifiers, MouseButton, MouseDownEvent, Pane, Path, PlatformInput, ReadApply, ReadOutcome, SaveStart, column_select_events,
        column_select_press, metrics, point, px, text_hash,
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

    impl<E> ReadApply<'_, E> {
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

    fn open(pane: &mut Pane<()>, path: &str, preview: bool) -> u64 {
        let (tab, token) = pane.pending_tab(Path::new(path), preview, ());
        pane.place(tab);
        token
    }

    #[test]
    fn replaced_preview_drops_earlier_load() {
        let mut pane = Pane::<()>::default();
        let a = open(&mut pane, "a.txt", true);
        let b = open(&mut pane, "b.txt", true);
        assert_eq!(pane.tabs.len(), 1);
        assert!(!pane.finish_read(a, ReadOutcome::Changed(1, UTF8)).accepted());
        assert!(pane.finish_read(b, ReadOutcome::Changed(2, UTF8)).accepted());
        assert_eq!((pane.tabs[0].hash, pane.tabs[0].pending), (2, None));
        // A finished token is not accepted twice.
        assert!(!pane.finish_read(b, ReadOutcome::Changed(3, UTF8)).accepted());
    }

    #[test]
    fn closed_tab_drops_load() {
        let mut pane = Pane::<()>::default();
        let a = open(&mut pane, "a.txt", false);
        let b = open(&mut pane, "b.txt", false);
        pane.tabs.retain(|t| t.pending != Some(a));
        assert!(!pane.finish_read(a, ReadOutcome::Changed(1, UTF8)).accepted());
        assert!(pane.finish_read(b, ReadOutcome::Changed(2, UTF8)).accepted());
        assert_eq!(pane.tabs[0].hash, 2);
    }

    /// First read got A, reload got B and applied first; the late first read must not bring A back.
    #[test]
    fn late_first_read_after_reload_is_dropped() {
        let mut pane = Pane::<()>::default();
        let first = open(&mut pane, "a.txt", false);
        let reload = pane.start_read(0);
        assert!(pane.finish_read(reload, ReadOutcome::Changed(text_hash("B"), UTF8)).accepted());
        assert!(!pane.finish_read(first, ReadOutcome::Changed(text_hash("A"), UTF8)).accepted());
        assert_eq!(pane.tabs[0].hash, text_hash("B"));
    }

    /// Reload started while loading saw the file emptied (`Same` against the empty hash). The earlier first
    /// read of A must not apply, so the tab stays empty like the disk.
    #[test]
    fn empty_same_reload_wins_over_first_read() {
        let mut pane = Pane::<()>::default();
        let first = open(&mut pane, "a.txt", false);
        let reload = pane.start_read(0);
        assert!(!pane.finish_read(first, ReadOutcome::Changed(text_hash("A"), UTF8)).accepted());
        assert!(pane.finish_read(reload, ReadOutcome::Same(UTF8)).accepted());
        assert_eq!((pane.tabs[0].hash, pane.tabs[0].pending), (text_hash(""), None));
    }

    /// Folder removed while first read and reload are in flight (reload keeps the workspace alive).
    #[test]
    fn closed_pane_drops_all_reads() {
        let mut pane = Pane::<()>::default();
        let first = open(&mut pane, "a.txt", false);
        let reload = pane.start_read(0);
        pane.close();
        assert!(!pane.finish_read(first, ReadOutcome::Changed(1, UTF8)).accepted());
        assert!(!pane.finish_read(reload, ReadOutcome::Changed(2, UTF8)).accepted());
        assert_eq!(pane.tabs[0].hash, text_hash(""));
    }

    /// P3-1: the first read loads the tab (editing allowed); an edit that changes the text makes it dirty and
    /// promotes the preview tab (I-063); undoing back to the disk text clears dirty.
    #[test]
    fn edit_marks_dirty_and_promotes_preview() {
        let mut pane = Pane::<()>::default();
        let first = open(&mut pane, "a.txt", true);
        assert!(!pane.tabs[0].loaded);
        assert!(pane.finish_read(first, ReadOutcome::Changed(text_hash("A"), UTF8)).accepted());
        assert!(pane.tabs[0].loaded && !pane.tabs[0].dirty);
        pane.on_edit(0, text_hash("AB"));
        assert!(pane.tabs[0].dirty);
        assert!(!pane.tabs[0].preview);
        pane.on_edit(0, text_hash("A"));
        assert!(!pane.tabs[0].dirty);
    }

    /// P3-1: a reload of a dirty tab keeps the buffer and the disk hash (no apply), and is not accepted again.
    #[test]
    fn dirty_tab_is_not_reloaded() {
        let mut pane = Pane::<()>::default();
        let first = open(&mut pane, "a.txt", false);
        pane.finish_read(first, ReadOutcome::Changed(text_hash("A"), UTF8));
        pane.on_edit(0, text_hash("A edited"));
        let reload = pane.start_read(0);
        assert!(!pane.finish_read(reload, ReadOutcome::Changed(text_hash("B"), UTF8)).accepted());
        let t = &pane.tabs[0];
        assert_eq!((t.hash, t.dirty, t.pending), (text_hash("A"), true, None));
    }

    /// P3-1: an unreadable first read leaves the tab not loaded (read-only), so nothing typed can replace the file.
    #[test]
    fn unreadable_first_read_stays_read_only() {
        let mut pane = Pane::<()>::default();
        let first = open(&mut pane, "a.txt", false);
        assert!(pane.finish_read(first, ReadOutcome::Unreadable).accepted());
        assert!(!pane.tabs[0].loaded);
        // A later reload that reads the (empty) file loads it.
        let reload = pane.start_read(0);
        pane.finish_read(reload, ReadOutcome::Same(UTF8));
        assert!(pane.tabs[0].loaded);
    }
    /// P3-2: save writes the tab's encoding; a second save waits; success records the saved hash and keeps the
    /// tab dirty only if the buffer changed while writing.
    #[test]
    fn save_encodes_with_tab_encoding_and_records_hash() {
        let mut pane = Pane::<()>::default();
        let first = open(&mut pane, "a.txt", false);
        assert_eq!(pane.begin_save(0, "x"), SaveStart::Skip, "not loaded yet");
        pane.finish_read(first, ReadOutcome::Changed(text_hash("A"), fmt(TextEncoding::Utf8Bom, LineEnding::Lf)));
        pane.on_edit(0, text_hash("AB"));
        let SaveStart::Write(token, bytes) = pane.begin_save(0, "AB") else { panic!("expected a write") };
        assert_eq!(bytes, [&[0xEF, 0xBB, 0xBF][..], b"AB"].concat());
        assert_eq!(pane.begin_save(0, "AB"), SaveStart::Skip, "save in flight");
        // Typed "C" while writing: saved, but still dirty against the new disk content.
        assert!(pane.finish_save(token, true, text_hash("AB"), text_hash("ABC")));
        let t = &pane.tabs[0];
        assert_eq!((t.hash, t.dirty, t.saving), (text_hash("AB"), true, None));
        let SaveStart::Write(token, _) = pane.begin_save(0, "ABC") else { panic!("expected a write") };
        assert!(pane.finish_save(token, true, text_hash("ABC"), text_hash("ABC")));
        assert!(!pane.tabs[0].dirty);
    }

    /// P3-2: a failed write keeps the old disk hash and the dirty mark.
    #[test]
    fn failed_save_keeps_dirty() {
        let mut pane = Pane::<()>::default();
        let first = open(&mut pane, "a.txt", false);
        pane.finish_read(first, ReadOutcome::Changed(text_hash("A"), UTF8));
        pane.on_edit(0, text_hash("AB"));
        let SaveStart::Write(token, _) = pane.begin_save(0, "AB") else { panic!("expected a write") };
        pane.finish_save(token, false, text_hash("AB"), text_hash("AB"));
        let t = &pane.tabs[0];
        assert_eq!((t.hash, t.dirty, t.saving), (text_hash("A"), true, None));
    }

    /// P3-2: an undecodable file is shown but never editable or saved.
    #[test]
    fn undecodable_file_is_read_only_and_not_saved() {
        let mut pane = Pane::<()>::default();
        let first = open(&mut pane, "bin.dat", false);
        assert!(pane.finish_read(first, ReadOutcome::Changed(text_hash("\u{FFFD}"), None)).accepted());
        assert!(!pane.tabs[0].loaded);
        assert_eq!(pane.begin_save(0, "\u{FFFD}"), SaveStart::Skip);
    }

    /// P3-2: CP949 text with a character CP949 cannot hold is refused (no best-fit) and nothing is in flight.
    #[cfg(windows)]
    #[test]
    fn cp949_loss_refuses_save() {
        let mut pane = Pane::<()>::default();
        let first = open(&mut pane, "k.txt", false);
        pane.finish_read(first, ReadOutcome::Changed(text_hash("가격"), fmt(TextEncoding::Cp949, LineEnding::Lf)));
        pane.on_edit(0, text_hash("가격 \u{20A9}1000"));
        let SaveStart::Refused(e) = pane.begin_save(0, "가격 \u{20A9}1000") else { panic!("expected refusal") };
        assert!(e.contains("U+20A9"), "{e}");
        assert_eq!(pane.tabs[0].saving, None);
    }

    /// Loaded "A", edited to `buffer`, save started. Returns the save token.
    fn loaded_and_saving(pane: &mut Pane<()>, buffer: &str) -> u64 {
        let first = open(pane, "a.txt", false);
        pane.finish_read(first, ReadOutcome::Changed(text_hash("A"), UTF8));
        pane.on_edit(0, text_hash(buffer));
        let SaveStart::Write(token, _) = pane.begin_save(0, buffer) else { panic!("expected a write") };
        token
    }

    /// P3-12-R1 (review 2-A): the app's own write is read back by a reload that started during the save and lands
    /// after it. It must not fill the editor again (set_value would reset undo and the cursor).
    #[test]
    fn own_write_read_back_after_save_is_dropped() {
        let mut pane = Pane::<()>::default();
        let save = loaded_and_saving(&mut pane, "B");
        let reload = pane.start_read(0);
        assert!(pane.finish_save(save, true, text_hash("B"), text_hash("B")));
        assert_eq!(pane.finish_read(reload, ReadOutcome::Changed(text_hash("B"), UTF8)), ReadApply::Dropped);
        let t = &pane.tabs[0];
        assert_eq!((t.hash, t.dirty), (text_hash("B"), false));
        // A reload started after the save reads the same text: accepted but nothing to fill.
        let after = pane.start_read(0);
        assert_eq!(pane.finish_read(after, ReadOutcome::Changed(text_hash("B"), UTF8)), ReadApply::Kept);
    }

    /// P3-12-R1 (review 2-B): a reload started before the save (it read an older external "B") lands after "C" was
    /// saved. It must not replace the saved buffer.
    #[test]
    fn stale_read_from_before_save_is_dropped() {
        let mut pane = Pane::<()>::default();
        let first = open(&mut pane, "a.txt", false);
        pane.finish_read(first, ReadOutcome::Changed(text_hash("A"), UTF8));
        let reload = pane.start_read(0);
        pane.on_edit(0, text_hash("C"));
        let SaveStart::Write(save, _) = pane.begin_save(0, "C") else { panic!("expected a write") };
        assert!(pane.finish_save(save, true, text_hash("C"), text_hash("C")));
        assert_eq!(pane.finish_read(reload, ReadOutcome::Changed(text_hash("B"), UTF8)), ReadApply::Dropped);
        let t = &pane.tabs[0];
        assert_eq!((t.hash, t.dirty), (text_hash("C"), false));
    }

    /// P3-12-R1: a read that lands while a save is running is dropped even when the buffer is clean again (undo
    /// back to the disk text during the save), and the save's end invalidates it.
    #[test]
    fn read_landing_during_save_is_dropped() {
        let mut pane = Pane::<()>::default();
        let save = loaded_and_saving(&mut pane, "B");
        pane.on_edit(0, text_hash("A"));
        assert!(!pane.tabs[0].dirty);
        let reload = pane.start_read(0);
        assert_eq!(pane.finish_read(reload, ReadOutcome::Changed(text_hash("X"), UTF8)), ReadApply::Dropped);
        pane.finish_save(save, true, text_hash("B"), text_hash("A"));
        let t = &pane.tabs[0];
        assert_eq!((t.hash, t.dirty), (text_hash("B"), true));
    }

    /// H-15: an unedited tab is not written (a mixed-ending file keeps its bytes); after an edit the save uses the
    /// detected majority ending.
    #[test]
    fn clean_tab_is_not_written_and_edit_saves_majority_ending() {
        let mut pane = Pane::<()>::default();
        let first = open(&mut pane, "mixed.txt", false);
        // "a\nb\r\nc\r\nd" read as LF text, CRLF by majority.
        pane.finish_read(first, ReadOutcome::Changed(text_hash("a\nb\nc\nd"), fmt(TextEncoding::Utf8, LineEnding::Crlf)));
        assert_eq!(pane.begin_save(0, "a\nb\nc\nd"), SaveStart::Skip, "no write without an edit");
        pane.on_edit(0, text_hash("a\nb\nc\nd\ne"));
        let SaveStart::Write(_, bytes) = pane.begin_save(0, "a\nb\nc\nd\ne") else { panic!("expected a write") };
        assert_eq!(bytes, b"a\r\nb\r\nc\r\nd\r\ne");
    }

    /// P3-12-R1: the tab's line ending is used for the save, typed lines included.
    #[test]
    fn save_writes_tab_line_ending() {
        let mut pane = Pane::<()>::default();
        let first = open(&mut pane, "a.txt", false);
        pane.finish_read(first, ReadOutcome::Changed(text_hash("a\nb"), fmt(TextEncoding::Utf8, LineEnding::Crlf)));
        pane.on_edit(0, text_hash("a\nb\nc"));
        let SaveStart::Write(_, bytes) = pane.begin_save(0, "a\nb\nc") else { panic!("expected a write") };
        assert_eq!(bytes, b"a\r\nb\r\nc");
    }

    /// P3-12-R1: a pasted "\r\n" hashes like the LF text reads produce, so it is not a phantom edit.
    #[test]
    fn pasted_crlf_hashes_as_lf() {
        assert_eq!(buffer_hash("a\r\nb"), text_hash("a\nb"));
        assert_eq!(buffer_hash("a\nb"), text_hash("a\nb"));
    }
}

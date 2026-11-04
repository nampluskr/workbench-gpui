//! 최소 탭 (v0.2 Phase 4, SPEC R-27, DECISIONS D-9·D-18). 폴더(Workspace)마다 Pane 하나를 둔다(A-15.1).
//!
//! - 트리에서 임시(preview)로 열거나 일반 탭으로 연다(I-087, I-033, I-061).
//! - 임시 탭은 하나다. 다른 파일을 임시로 열면 그 자리(인덱스)에서 바꾼다(I-062).
//! - 이미 임시로 열린 파일을 일반으로 열면 일반 탭이 된다(I-063).
//! - 새 탭은 활성 탭 바로 뒤에 넣는다(판단: Zed 의 새 항목 자리).
//! - 내용은 gpui-kit Editor 로 보이고 편집을 막는다(D-18). 저장·탭 닫기·이동 기록은 없다(PoC 6단계).
//! - First open reads the file on the background executor; the tab exists at once and gets its text when
//!   the read finishes (v0.4 P1-3, AUDIT 4). First read and watch reload share one request token per tab:
//!   only the latest started read applies, and a closed pane (folder removed) applies nothing.

use std::path::{Path, PathBuf};
use std::rc::Rc;

use gpui_kit::base::Scrollbar;
use gpui_kit::base::input::EditorScrollbarContext;
use gpui_kit::component::input::{Editor, EditorState};
use gpui_kit::*;

use super::folders::FolderWorkspace;
use super::metrics;

/// `E` is the editor handle; generic only so tab bookkeeping is testable without a window.
pub struct Tab<E = Entity<EditorState>> {
    pub path: PathBuf,
    pub preview: bool,
    pub editor: E,
    /// 편집기에 넣은 내용의 해시(`text_hash`). 감시가 다시 읽은 내용과 비교한다(Phase 5 리뷰 1회차 ⑤, D-046). 보기 전용이라
    /// 편집기 내용은 늘 넣은 내용과 같다(D-18). While the first read is pending the editor is empty, so this is `text_hash("")`.
    pub hash: u64,
    /// Token of the latest started read (first read or reload) not yet applied.
    pub pending: Option<u64>,
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
pub fn editor_view(editor: &Entity<EditorState>) -> impl IntoElement {
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
                .readonly(true)
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

/// 파일 내용(UTF-8 로 읽고, 깨진 바이트는 대체 문자로 둔다. 판단: 인코딩 감지는 PoC 6단계).
pub fn read_text(path: &Path) -> String {
    match std::fs::read(path) {
        Ok(bytes) => String::from_utf8_lossy(&bytes).into_owned(),
        Err(_) => String::new(),
    }
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
        (Tab { path: path.to_path_buf(), preview, editor, hash: text_hash(""), pending: Some(token) }, token)
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

    /// Accepts a finished read if it is still the latest for its tab; a replaced, removed or closed tab drops it.
    /// `hash` is the new content hash, or `None` when the content stays (unchanged or unreadable). Returns the editor
    /// to fill. Content cannot change between start and accept: only the latest token applies.
    pub fn finish_read(&mut self, token: u64, hash: Option<u64>) -> Option<&E> {
        if self.closed {
            return None;
        }
        let tab = self.tabs.iter_mut().find(|t| t.pending == Some(token))?;
        tab.pending = None;
        if let Some(h) = hash {
            tab.hash = h;
        }
        Some(&tab.editor)
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
        let (tab, token) = self.pending_tab(path, preview, editor);
        let ix = self.place(tab);
        let path = path.to_path_buf();
        cx.spawn_in(window, async move |ws, cx| {
            let text = cx.background_executor().spawn(async move { read_text(&path) }).await;
            let _ = ws.update_in(cx, |ws, window, cx| {
                if let Some(editor) = ws.pane.finish_read(token, Some(text_hash(&text))).cloned() {
                    editor.update(cx, |e, cx| e.set_value(text.as_str(), window, cx));
                }
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
        Capslock, Modifiers, MouseButton, MouseDownEvent, Pane, Path, PlatformInput, column_select_events,
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
        assert!(pane.finish_read(a, Some(1)).is_none());
        assert!(pane.finish_read(b, Some(2)).is_some());
        assert_eq!((pane.tabs[0].hash, pane.tabs[0].pending), (2, None));
        // A finished token is not accepted twice.
        assert!(pane.finish_read(b, Some(3)).is_none());
    }

    #[test]
    fn closed_tab_drops_load() {
        let mut pane = Pane::<()>::default();
        let a = open(&mut pane, "a.txt", false);
        let b = open(&mut pane, "b.txt", false);
        pane.tabs.retain(|t| t.pending != Some(a));
        assert!(pane.finish_read(a, Some(1)).is_none());
        assert!(pane.finish_read(b, Some(2)).is_some());
        assert_eq!(pane.tabs[0].hash, 2);
    }

    /// First read got A, reload got B and applied first; the late first read must not bring A back.
    #[test]
    fn late_first_read_after_reload_is_dropped() {
        let mut pane = Pane::<()>::default();
        let first = open(&mut pane, "a.txt", false);
        let reload = pane.start_read(0);
        assert!(pane.finish_read(reload, Some(text_hash("B"))).is_some());
        assert!(pane.finish_read(first, Some(text_hash("A"))).is_none());
        assert_eq!(pane.tabs[0].hash, text_hash("B"));
    }

    /// Reload started while loading saw the file emptied (`Same` against the empty hash). The earlier first
    /// read of A must not apply, so the tab stays empty like the disk.
    #[test]
    fn empty_same_reload_wins_over_first_read() {
        let mut pane = Pane::<()>::default();
        let first = open(&mut pane, "a.txt", false);
        let reload = pane.start_read(0);
        assert!(pane.finish_read(first, Some(text_hash("A"))).is_none());
        assert!(pane.finish_read(reload, None).is_some());
        assert_eq!((pane.tabs[0].hash, pane.tabs[0].pending), (text_hash(""), None));
    }

    /// Folder removed while first read and reload are in flight (reload keeps the workspace alive).
    #[test]
    fn closed_pane_drops_all_reads() {
        let mut pane = Pane::<()>::default();
        let first = open(&mut pane, "a.txt", false);
        let reload = pane.start_read(0);
        pane.close();
        assert!(pane.finish_read(first, Some(1)).is_none());
        assert!(pane.finish_read(reload, Some(2)).is_none());
        assert_eq!(pane.tabs[0].hash, text_hash(""));
    }
}

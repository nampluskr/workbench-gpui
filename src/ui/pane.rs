//! 최소 탭 (v0.2 Phase 4, SPEC R-27, DECISIONS D-9·D-18). 폴더(Workspace)마다 Pane 하나를 둔다(A-15.1).
//!
//! - 트리에서 임시(preview)로 열거나 일반 탭으로 연다(I-087, I-033, I-061).
//! - 임시 탭은 하나다. 다른 파일을 임시로 열면 그 자리(인덱스)에서 바꾼다(I-062).
//! - 이미 임시로 열린 파일을 일반으로 열면 일반 탭이 된다(I-063).
//! - 새 탭은 활성 탭 바로 뒤에 넣는다(판단: Zed 의 새 항목 자리).
//! - 내용은 gpui-kit Editor 로 보이고 편집을 막는다(D-18). 저장·탭 닫기·이동 기록은 없다(PoC 6단계).
//! - First open reads the file on the background executor; the tab exists at once and gets its text when
//!   the read finishes (v0.4 P1-3, AUDIT 4). Only the tab still carrying that load token accepts the result.

use std::path::{Path, PathBuf};

use gpui_kit::component::input::EditorState;
use gpui_kit::*;

use super::folders::FolderWorkspace;

/// `E` is the editor handle; generic only so tab bookkeeping is testable without a window.
pub struct Tab<E = Entity<EditorState>> {
    pub path: PathBuf,
    pub preview: bool,
    pub editor: E,
    /// 편집기에 넣은 내용의 해시(`text_hash`). 감시가 다시 읽은 내용과 비교한다(Phase 5 리뷰 1회차 ⑤, D-046). 보기 전용이라
    /// 편집기 내용은 늘 넣은 내용과 같다(D-18). While the first read is pending the editor is empty, so this is `text_hash("")`.
    pub hash: u64,
    /// Token of the pending first read; `None` once loaded.
    pub loading: Option<u64>,
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
}

impl<E> Default for Pane<E> {
    fn default() -> Self {
        Self { tabs: Vec::new(), active: None, next_load: 0 }
    }
}

/// 내용 해시: UTF-8 바이트의 FNV-1a 64(dev 출력 `fnv=` 와 같은 값).
pub fn text_hash(text: &str) -> u64 {
    text.bytes().fold(0xcbf29ce484222325u64, |h, b| (h ^ b as u64).wrapping_mul(0x100000001b3))
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

    /// A new pending tab for `path` with a fresh load token.
    fn pending_tab(&mut self, path: &Path, preview: bool, editor: E) -> (Tab<E>, u64) {
        let token = self.next_load;
        self.next_load += 1;
        (Tab { path: path.to_path_buf(), preview, editor, hash: text_hash(""), loading: Some(token) }, token)
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

    /// Accepts a finished first read if a tab still waits for `token`; a replaced or closed tab drops it.
    /// Returns the editor to fill.
    fn finish_load(&mut self, token: u64, hash: u64) -> Option<&E> {
        let tab = self.tabs.iter_mut().find(|t| t.loading == Some(token))?;
        tab.loading = None;
        tab.hash = hash;
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
        let editor = cx.new(|cx| EditorState::new(window, cx));
        let (tab, token) = self.pending_tab(path, preview, editor);
        let ix = self.place(tab);
        let path = path.to_path_buf();
        cx.spawn_in(window, async move |ws, cx| {
            let text = cx.background_executor().spawn(async move { read_text(&path) }).await;
            let _ = ws.update_in(cx, |ws, window, cx| {
                if let Some(editor) = ws.pane.finish_load(token, text_hash(&text)).cloned() {
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
    use super::{Pane, Path};

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
        assert!(pane.finish_load(a, 1).is_none());
        assert!(pane.finish_load(b, 2).is_some());
        assert_eq!((pane.tabs[0].hash, pane.tabs[0].loading), (2, None));
        // A finished token is not accepted twice.
        assert!(pane.finish_load(b, 3).is_none());
    }

    #[test]
    fn closed_tab_drops_load() {
        let mut pane = Pane::<()>::default();
        let a = open(&mut pane, "a.txt", false);
        let b = open(&mut pane, "b.txt", false);
        pane.tabs.retain(|t| t.loading != Some(a));
        assert!(pane.finish_load(a, 1).is_none());
        assert!(pane.finish_load(b, 2).is_some());
        assert_eq!(pane.tabs[0].hash, 2);
    }
}

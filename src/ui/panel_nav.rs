//! 프로젝트 패널의 선택·펼침·열기 (v0.2 Phase 4, SPEC R-18·R-23·R-27, I-030~I-033·I-043·I-087~I-090·I-096).

use std::path::{Path, PathBuf};

use gpui_kit::*;

use super::Workbench;
use super::folders::FolderWorkspace;
use super::keymap::{self, menu, project_panel as pp};

thread_local! {
    static LAST_TREE: std::cell::RefCell<String> = const { std::cell::RefCell::new(String::new()) };
    static LAST_TABS: std::cell::RefCell<String> = const { std::cell::RefCell::new(String::new()) };
}

impl Workbench {
    /// 활성 폴더의 Workspace(경로 없음 상태면 None).
    pub(super) fn active_ws(&self) -> Option<Entity<FolderWorkspace>> {
        let folder = self.folders.active_folder()?;
        if self.folders.missing.contains(&folder.id) {
            return None;
        }
        self.folders.workspaces.get(&folder.id).cloned()
    }

    /// 인라인 입력 중인가(P-022 `editing`).
    pub(super) fn panel_editing(&self, cx: &App) -> bool {
        self.active_ws().is_some_and(|ws| ws.read(cx).tree.edit.is_some())
    }

    /// dev 출력: 트리 상태(펼침·선택·표시·보이는 행)가 바뀌면 낸다(R-18 판정).
    pub(super) fn log_tree(&self, cx: &App) {
        if !keymap::dev_enabled(cx) {
            return;
        }
        let Some(ws) = self.active_ws() else { return };
        let ws = ws.read(cx);
        let t = &ws.tree;
        let mut expanded: Vec<String> = t.expanded.iter().map(|p| t.rel(p)).collect();
        expanded.sort();
        let rows: Vec<String> = t
            .rows
            .iter()
            .map(|r| match r.new_entry {
                Some(d) => format!("<new {}>|{}", if d { "dir" } else { "file" }, r.depth),
                None => format!("{}|{}|{}", r.label(), r.depth, if r.is_dir { if r.expanded { "open" } else { "closed" } } else { "file" }),
            })
            .collect();
        let line = format!(
            "folder={} selected={} marked={} expanded={} rows={}",
            ws.folder_id,
            t.selected.as_deref().map(|p| t.rel(p)).unwrap_or_else(|| "none".into()),
            t.marked.iter().map(|p| t.rel(p)).collect::<Vec<_>>().join(";"),
            expanded.join(";"),
            rows.join("\t")
        );
        LAST_TREE.with(|last| {
            if *last.borrow() != line {
                println!("[dev] tree {line}");
                *last.borrow_mut() = line;
            }
        });
    }

    /// dev 출력: 활성 폴더의 탭 목록·활성 탭(R-27·R-25·R-26 판정).
    pub(super) fn log_tabs(&self, cx: &App) {
        if !keymap::dev_enabled(cx) {
            return;
        }
        let Some(ws) = self.active_ws() else { return };
        let ws = ws.read(cx);
        let line = format!(
            "folder={} active={} count={} list={}",
            ws.folder_id,
            ws.group.active_pane().active.map(|a| a.to_string()).unwrap_or_else(|| "none".into()),
            ws.group.active_pane().tabs.len(),
            ws.group.active_pane().describe()
        );
        LAST_TABS.with(|last| {
            if *last.borrow() != line {
                println!("[dev] tabs {line}");
                *last.borrow_mut() = line;
            }
        });
    }
}

impl Workbench {
    /// 활성 트리를 고친 뒤 기록·다시 그리기. 입력 중이면 하지 않는다(키가 입력칸을 지나 패널까지 와도 무시).
    fn tree_update(
        &mut self,
        allow_editing: bool,
        cx: &mut Context<Self>,
        f: impl FnOnce(&mut super::project_panel::ProjectTree, &mut App),
    ) {
        let Some(ws) = self.active_ws() else { return };
        if !allow_editing && ws.read(cx).tree.edit.is_some() {
            return;
        }
        ws.update(cx, |ws, cx| f(&mut ws.tree, cx));
        self.log_tree(cx);
        cx.notify();
    }

    /// Up/Down/Home/End: 선택·스크롤만 바꾸고 열지 않는다(I-030, I-088). 끝에서 멈춘다(판단: Zed 패널은 돌지 않는다).
    fn step_selection(&mut self, to: Step, extend: bool, cx: &mut Context<Self>) {
        self.tree_update(false, cx, |t, cx| {
            let len = t.rows.iter().filter(|r| r.new_entry.is_none()).count();
            if len == 0 {
                return;
            }
            let cur = t.selected_index();
            let next = match (to, cur) {
                (Step::Next, Some(i)) => (i + 1).min(t.rows.len() - 1),
                (Step::Prev, Some(i)) => i.saturating_sub(1),
                (Step::Next | Step::First, None) | (Step::First, _) => 0,
                (Step::Prev | Step::Last, None) | (Step::Last, _) => t.rows.len() - 1,
            };
            let path = t.rows[next].path.clone();
            if extend {
                // I-043 Shift+Up/Down: 기준점부터 범위를 늘린다.
                let anchor = t.anchor.clone().or_else(|| t.selected.clone()).unwrap_or_else(|| path.clone());
                let a = t.index_of(&anchor).unwrap_or(next);
                let (lo, hi) = if a <= next { (a, next) } else { (next, a) };
                t.marked = t.rows[lo..=hi].iter().filter(|r| r.new_entry.is_none()).map(|r| r.path.clone()).collect();
                t.anchor = Some(anchor);
                t.selected = Some(path);
            } else {
                t.select_only(Some(path));
            }
            t.scroll_to(next, cx);
        });
    }

    pub(super) fn on_tree_next(&mut self, a: &menu::SelectNext, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.step_selection(Step::Next, false, cx);
    }
    pub(super) fn on_tree_prev(&mut self, a: &menu::SelectPrevious, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.step_selection(Step::Prev, false, cx);
    }
    pub(super) fn on_tree_first(&mut self, a: &menu::SelectFirst, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.step_selection(Step::First, false, cx);
    }
    pub(super) fn on_tree_last(&mut self, a: &menu::SelectLast, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.step_selection(Step::Last, false, cx);
    }
    pub(super) fn on_tree_next_extend(&mut self, a: &pp::SelectNextExtend, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.step_selection(Step::Next, true, cx);
    }
    pub(super) fn on_tree_prev_extend(&mut self, a: &pp::SelectPreviousExtend, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.step_selection(Step::Prev, true, cx);
    }
}

#[derive(Clone, Copy)]
enum Step {
    Next,
    Prev,
    First,
    Last,
}

/// `dir` 아래 폴더를 모두 모은다(Expand All). 읽지 못한 폴더는 건너뛴다.
/// 정션·링크가 상위 폴더를 가리켜도 끝나도록 실제 경로로 이미 들른 폴더는 다시 들어가지 않는다(D-043 ②).
fn all_dirs_under(dir: &Path, out: &mut Vec<PathBuf>) {
    let mut visited = std::collections::HashSet::new();
    walk_dirs(dir, out, &mut visited);
}

fn walk_dirs(dir: &Path, out: &mut Vec<PathBuf>, visited: &mut std::collections::HashSet<PathBuf>) {
    let real = std::fs::canonicalize(dir).unwrap_or_else(|_| dir.to_path_buf());
    if !visited.insert(real) {
        return;
    }
    out.push(dir.to_path_buf());
    if let Ok(children) = crate::fsops::list::read_children(dir) {
        for c in children.into_iter().filter(|c| c.is_dir) {
            walk_dirs(&c.path, out, visited);
        }
    }
}

impl Workbench {
    /// Right(I-089, I-031): 접힌 경로의 앞 조각이면 다음 조각, 닫힌 폴더는 펼치고, 이미 펼쳤으면 다음 항목.
    pub(super) fn on_tree_expand(&mut self, a: &pp::ExpandSelectedEntry, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.tree_update(false, cx, |t, cx| {
            let Some(ix) = t.selected_index() else { return };
            let row = t.rows[ix].clone();
            let sel = t.selected.clone().unwrap_or_default();
            if let Some(pos) = row.segments.iter().position(|(_, p)| *p == sel)
                && pos + 1 < row.segments.len()
            {
                t.select_only(Some(row.segments[pos + 1].1.clone()));
                return;
            }
            if !row.is_dir {
                return;
            }
            if !row.expanded {
                t.expanded.insert(row.path.clone());
                t.rebuild(cx);
            } else if ix + 1 < t.rows.len() {
                let next = t.rows[ix + 1].path.clone();
                t.select_only(Some(next));
                t.scroll_to(ix + 1, cx);
            }
        });
    }

    /// Left(I-089, I-031): 펼친 폴더는 접고, 접힌 경로의 뒤 조각이면 앞 조각, 아니면 부모로.
    pub(super) fn on_tree_collapse(&mut self, a: &pp::CollapseSelectedEntry, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.tree_update(false, cx, |t, cx| {
            let Some(ix) = t.selected_index() else { return };
            let row = t.rows[ix].clone();
            let sel = t.selected.clone().unwrap_or_default();
            let pos = row.segments.iter().position(|(_, p)| *p == sel).unwrap_or(0);
            if row.is_dir && row.expanded && pos + 1 == row.segments.len() {
                t.expanded.remove(&row.path);
                t.rebuild(cx);
                return;
            }
            if pos > 0 {
                t.select_only(Some(row.segments[pos - 1].1.clone()));
                return;
            }
            let first = &row.segments[0].1;
            if let Some(parent) = first.parent().filter(|_| !row.is_root)
                && let Some(pix) = t.index_of(parent)
            {
                t.select_only(Some(parent.to_path_buf()));
                t.scroll_to(pix, cx);
            }
        });
    }

    /// Ctrl+Left 전체 접기(I-032). 루트는 펼친 채 둔다(판단: Zed 는 루트 항목을 접지 않는다).
    pub(super) fn on_tree_collapse_all(&mut self, a: &pp::CollapseAllEntries, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.tree_update(false, cx, |t, cx| {
            let root = t.root.clone();
            t.expanded.retain(|p| *p == root);
            t.rebuild(cx);
        });
    }

    /// Ctrl+Right 전체 펼치기(I-032).
    pub(super) fn on_tree_expand_all(&mut self, a: &pp::ExpandAllEntries, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.tree_update(false, cx, |t, cx| {
            let mut dirs = Vec::new();
            all_dirs_under(&t.root.clone(), &mut dirs);
            t.expanded.extend(dirs);
            t.rebuild(cx);
        });
    }

    /// 폴더와 그 아래를 모두 펼치거나 접는다(Alt+클릭 I-089, 하위 폴더 메뉴의 Expand All·Collapse All I-556·I-557).
    pub(super) fn set_subtree(&mut self, dir: &Path, expand: bool, cx: &mut Context<Self>) {
        let dir = dir.to_path_buf();
        self.tree_update(false, cx, move |t, cx| {
            let mut dirs = Vec::new();
            all_dirs_under(&dir, &mut dirs);
            for d in dirs {
                if expand {
                    t.expanded.insert(d);
                } else if d != t.root {
                    t.expanded.remove(&d);
                }
            }
            t.rebuild(cx);
        });
    }
}

impl Workbench {
    /// 파일을 탭으로 연다(R-27). `preview` = 임시 탭, `focus_editor` = 편집기에 포커스(I-087).
    /// 연 뒤 트리에서 그 항목을 펼쳐 보이고 고른다. 포커스는 옮기지 않는다(R-23, I-096).
    pub(super) fn open_file(
        &mut self,
        path: &Path,
        preview: bool,
        focus_editor: bool,
        via: &str,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        let Some(ws) = self.active_ws() else { return };
        if !path.is_file() {
            return;
        }
        // 지금 활성 탭 편집기에 포커스가 있으면(예: 입력칸 밖 편집기를 눌러 확정한 경우) 바뀐 활성 탭으로 포커스를 옮긴다.
        // 그러지 않으면 화면에서 사라진 편집기에 포커스가 남아 키가 아무 데도 가지 않는다.
        let focus_editor = focus_editor || self.active_editor_focused(window, cx);
        let (ix, created) = ws.update(cx, |ws, cx| ws.group.open(path, preview, window, cx));
        if keymap::dev_enabled(cx) {
            println!(
                "[dev] open-file path={} preview={preview} focus_editor={focus_editor} via={via} index={ix} created={created}",
                path.display()
            );
        }
        self.reveal(path, cx);
        if focus_editor {
            let handle = ws.read(cx).group.active_pane().tabs.get(ix).map(|t| t.editor.focus_handle(cx));
            if let Some(h) = handle {
                h.focus(window, cx);
            }
        }
        self.log_tabs(cx);
        cx.notify();
    }

    /// I-096 자동 표시: 상위 폴더를 펼치고 그 항목을 고르고 보이게 한다. 포커스는 그대로다.
    pub(super) fn reveal(&mut self, path: &Path, cx: &mut Context<Self>) {
        if keymap::dev_enabled(cx) {
            println!("[dev] reveal path={}", path.display());
        }
        let path = path.to_path_buf();
        self.tree_update(true, cx, move |t, cx| {
            if !path.starts_with(&t.root) {
                return;
            }
            let mut changed = false;
            for a in path.ancestors().skip(1) {
                if !a.starts_with(&t.root) {
                    break;
                }
                changed |= t.expanded.insert(a.to_path_buf());
            }
            if changed {
                t.rebuild(cx);
            }
            if t.edit.is_none() {
                t.select_only(Some(path.clone()));
            }
            if let Some(ix) = t.index_of(&path) {
                t.scroll_to(ix, cx);
            }
        });
    }

    /// Space(I-033): 파일을 임시 탭으로 열고 트리에 포커스를 남긴다. 폴더면 펼침 토글(판단).
    pub(super) fn on_tree_open(&mut self, a: &pp::Open, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        let Some(ws) = self.active_ws() else { return };
        let Some(sel) = ws.read(cx).tree.selected.clone() else { return };
        if ws.read(cx).tree.edit.is_some() {
            return;
        }
        if sel.is_dir() {
            self.toggle_dir(&sel, cx);
        } else {
            self.open_file(&sel, true, false, "space", w, cx);
        }
    }

    pub(super) fn toggle_dir(&mut self, dir: &Path, cx: &mut Context<Self>) {
        let dir = dir.to_path_buf();
        self.tree_update(false, cx, move |t, cx| {
            // 접힌 경로의 조각을 눌렀으면 그 줄(마지막 조각)의 펼침을 토글한다.
            let key = t.index_of(&dir).map(|i| t.rows[i].path.clone()).unwrap_or(dir);
            if !t.expanded.remove(&key) {
                t.expanded.insert(key);
            }
            t.rebuild(cx);
        });
    }
}

/// 행 누르기 한 번.
pub struct RowPress {
    pub path: PathBuf,
    pub button: MouseButton,
    pub click_count: usize,
    pub modifiers: Modifiers,
    pub position: Point<Pixels>,
}

impl Workbench {
    /// 행 누르기(I-087·I-089·I-090). 왼쪽은 놓을 때, 가운데·오른쪽은 누를 때 부른다.
    pub(super) fn on_row_press(&mut self, press: RowPress, window: &mut Window, cx: &mut Context<Self>) {
        let Some(ws) = self.active_ws() else { return };
        let path = press.path.clone();
        let is_dir = path.is_dir();
        if keymap::dev_enabled(cx) {
            let t = &ws.read(cx).tree;
            println!(
                "[dev] tree-press path={} button={:?} count={} ctrl={} shift={} alt={}",
                t.rel(&path),
                press.button,
                press.click_count,
                press.modifiers.control,
                press.modifiers.shift,
                press.modifiers.alt
            );
        }
        match press.button {
            MouseButton::Right => {
                // I-560: 누른 항목이 선택이 된다. 여러 항목 표시 안이면 표시를 둔다(I-562).
                self.tree_update(false, cx, |t, _| {
                    if !t.marked.contains(&path) {
                        t.select_only(Some(path.clone()));
                    } else {
                        t.selected = Some(path.clone());
                    }
                });
                self.open_panel_menu(Some(press.path), press.position, window, cx);
            }
            MouseButton::Middle => {
                self.tree_update(false, cx, |t, _| t.select_only(Some(path.clone())));
                if !is_dir {
                    self.open_file(&press.path, false, true, "middle-click", window, cx);
                }
            }
            MouseButton::Left if press.modifiers.shift => {
                // I-090 Shift+클릭: 보이는 항목 범위.
                self.tree_update(false, cx, |t, _| {
                    let anchor = t.anchor.clone().or_else(|| t.selected.clone()).unwrap_or_else(|| path.clone());
                    let (Some(a), Some(b)) = (t.index_of(&anchor), t.index_of(&path)) else { return };
                    let (lo, hi) = if a <= b { (a, b) } else { (b, a) };
                    t.marked = t.rows[lo..=hi].iter().filter(|r| r.new_entry.is_none()).map(|r| r.path.clone()).collect();
                    t.anchor = Some(anchor);
                    t.selected = Some(path.clone());
                });
            }
            MouseButton::Left if press.modifiers.control => {
                // I-090 Windows Ctrl+클릭: 개별 선택 토글.
                self.tree_update(false, cx, |t, _| {
                    if t.marked.is_empty()
                        && let Some(sel) = t.selected.clone()
                    {
                        t.marked.push(sel);
                    }
                    if let Some(i) = t.marked.iter().position(|p| *p == path) {
                        // 리뷰 1회차 ③(D-043): 표시에서 뺀 항목은 작업 대상이 아니다. 커서를 남은 항목(마지막)으로 옮기고,
                        // 다 뺐으면 선택도 없앤다. 불변식: 표시가 있으면 선택은 늘 그 안에 있다.
                        t.marked.remove(i);
                        t.selected = t.marked.last().cloned();
                        t.anchor = t.selected.clone();
                    } else {
                        t.marked.push(path.clone());
                        t.selected = Some(path.clone());
                        t.anchor = Some(path.clone());
                    }
                });
            }
            MouseButton::Left => {
                self.tree_update(false, cx, |t, _| t.select_only(Some(path.clone())));
                if is_dir {
                    if press.modifiers.alt {
                        // I-089 Alt+클릭: 하위 전체 토글.
                        let expand = !ws.read(cx).tree.expanded.contains(&path);
                        self.set_subtree(&path, expand, cx);
                    } else {
                        self.toggle_dir(&path, cx);
                    }
                } else if press.click_count >= 2 {
                    self.open_file(&path, false, true, "double-click", window, cx);
                } else {
                    self.open_file(&path, true, false, "click", window, cx);
                }
            }
            _ => {}
        }
    }
}

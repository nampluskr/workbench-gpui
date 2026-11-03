//! 프로젝트 패널 우클릭 메뉴 (v0.2 Phase 4, SPEC R-22, 02-INTERACTION 11.2절 I-530~I-562·I-660~I-662, D-15·D-17).
//!
//! 구분선은 위아래에 항목이 남을 때만 둔다(11절 규칙). 단축키는 프로젝트 패널 포커스 자리의 키맵 결과다(11.2절 머리말).

use std::path::{Path, PathBuf};

use gpui_kit::*;

use super::Workbench;
use super::context_menu::{CmEntry, ContextMenu, ContextMenuEvent};
use super::keymap::{self, project_panel as pp};
use super::metrics::menu::{KEYBOARD_OFFSET_X, KEYBOARD_OFFSET_Y};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum PanelCmd {
    NewFile,
    NewFolder,
    Reveal,
    OpenDefault,
    MarkdownPreview,
    Unfold,
    Fold,
    Cut,
    Copy,
    Duplicate,
    Paste,
    CopyPath,
    CopyRelativePath,
    Rename,
    Trash,
    Delete,
    AddFolders,
    RemoveFromProject,
    ExpandAll,
    CollapseAll,
}

/// 열린 패널 메뉴.
pub struct OpenPanelMenu {
    pub menu: Entity<ContextMenu>,
    pub target: PathBuf,
    pub commands: Vec<Option<PanelCmd>>,
    _sub: Subscription,
}

/// 항목 하나: (글자, 켜짐, 단축키를 고를 액션 이름, 명령).
type Item = (&'static str, bool, Option<&'static str>, PanelCmd);

fn is_markdown(path: &Path) -> bool {
    path.extension()
        .map(|e| e.to_string_lossy().to_lowercase())
        .is_some_and(|e| e == "md" || e == "markdown")
}

impl Workbench {
    /// 메뉴 항목 묶음(I-660 파일, I-661 폴더, I-662 루트). 빈 묶음은 뺀다.
    fn panel_menu_groups(&self, target: &Path, cx: &App) -> Vec<Vec<Item>> {
        let Some(ws) = self.active_ws() else { return Vec::new() };
        let t = &ws.read(cx).tree;
        let is_root = t.is_root(target);
        let is_dir = target.is_dir();
        let row = t.index_of(target).map(|i| t.rows[i].clone());
        let folded = row.as_ref().is_some_and(|r| r.segments.len() > 1);
        // I-539 접을 수 있을 때: Unfold 로 접기를 끈 폴더이고 자식이 폴더 하나뿐이다.
        let can_fold = is_dir
            && !is_root
            && t.unfolded.contains(target)
            && crate::fsops::list::read_children(target).is_ok_and(|c| c.len() == 1 && c[0].is_dir);
        let paste = self.can_paste();
        let mut groups: Vec<Vec<Item>> = Vec::new();
        groups.push(vec![
            ("New File", true, Some("project_panel::NewFile"), PanelCmd::NewFile),
            ("New Folder", true, Some("project_panel::NewDirectory"), PanelCmd::NewFolder),
        ]);
        let mut open = vec![
            ("Reveal in File Explorer", true, Some("project_panel::RevealInFileManager"), PanelCmd::Reveal),
            ("Open in Default App", true, Some("project_panel::OpenWithSystem"), PanelCmd::OpenDefault),
        ];
        if !is_dir && is_markdown(target) {
            // D-15: 비활성 항목(I-515).
            open.push(("Open Markdown Preview", false, None, PanelCmd::MarkdownPreview));
        }
        groups.push(open);
        if is_dir {
            let mut fold = Vec::new();
            if folded {
                fold.push(("Unfold Directory", true, None, PanelCmd::Unfold));
            }
            if can_fold {
                fold.push(("Fold Directory", true, None, PanelCmd::Fold));
            }
            groups.push(fold);
        }
        groups.push(vec![
            ("Cut", true, Some("project_panel::Cut"), PanelCmd::Cut),
            ("Copy", true, Some("project_panel::Copy"), PanelCmd::Copy),
            ("Duplicate", true, None, PanelCmd::Duplicate),
            ("Paste", paste, Some("project_panel::Paste"), PanelCmd::Paste),
        ]);
        groups.push(vec![
            ("Copy Path", true, Some("workspace::CopyPath"), PanelCmd::CopyPath),
            ("Copy Relative Path", true, Some("workspace::CopyRelativePath"), PanelCmd::CopyRelativePath),
        ]);
        if is_root {
            groups.push(vec![
                ("Add Folders to Project…", true, None, PanelCmd::AddFolders),
                ("Remove from Project", true, None, PanelCmd::RemoveFromProject),
            ]);
        } else {
            groups.push(vec![
                ("Rename", true, Some("project_panel::Rename"), PanelCmd::Rename),
                ("Trash", true, Some("project_panel::Trash"), PanelCmd::Trash),
                ("Delete", true, Some("project_panel::Delete"), PanelCmd::Delete),
            ]);
        }
        if is_dir {
            // I-556·I-557: 루트는 Ctrl-Right·Ctrl-Left, 하위 폴더는 단축키 없음.
            let (ea, ca) = if is_root {
                (Some("project_panel::ExpandAllEntries"), Some("project_panel::CollapseAllEntries"))
            } else {
                (None, None)
            };
            groups.push(vec![
                ("Expand All", true, ea, PanelCmd::ExpandAll),
                ("Collapse All", true, ca, PanelCmd::CollapseAll),
            ]);
        }
        groups.retain(|g| !g.is_empty());
        groups
    }
}

impl Workbench {
    /// 패널 메뉴를 연다. `target` 이 없으면(빈 공간, I-559) 루트 항목의 메뉴다.
    pub(super) fn open_panel_menu(
        &mut self,
        target: Option<PathBuf>,
        position: Point<Pixels>,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        let Some(ws) = self.active_ws() else { return };
        if ws.read(cx).tree.edit.is_some() {
            return;
        }
        let target = match target {
            Some(t) => t,
            None => {
                let root = ws.read(cx).tree.root.clone();
                // I-560: 메뉴는 선택 항목에 대해 동작하므로 루트를 고른다(판단).
                ws.update(cx, |ws, _| ws.tree.select_only(Some(root.clone())));
                root
            }
        };
        // 단축키는 메뉴를 열기 직전 자리(프로젝트 패널)의 컨텍스트로 고른다(11.2절 머리말). 메뉴를 열면 포커스가 메뉴로 간다.
        self.panel_focus.focus(window, cx);
        let focus = self.panel_focus.clone();
        let mut entries = Vec::new();
        let mut commands = Vec::new();
        // I-520: 항목마다 단축키 해석용 액션 이름.
        let mut actions: Vec<Option<&'static str>> = Vec::new();
        for (gi, group) in self.panel_menu_groups(&target, cx).into_iter().enumerate() {
            if gi > 0 {
                entries.push(CmEntry::Separator);
                commands.push(None);
                actions.push(None);
            }
            for (label, enabled, action, cmd) in group {
                let shortcut = action.and_then(|a| keymap::shortcut_for_name(a, Some(&focus), window, cx));
                entries.push(CmEntry::with_shortcut(label, enabled, shortcut));
                commands.push(Some(cmd));
                actions.push(action);
            }
        }
        if keymap::dev_enabled(cx) {
            let rel = ws.read(cx).tree.rel(&target);
            println!("[dev] panel-menu-target path={rel} x={:.1} y={:.1}", f32::from(position.x), f32::from(position.y));
        }
        let menu = cx.new(|cx| ContextMenu::new(entries, actions, position, window, cx));
        let sub = cx.subscribe_in(&menu, window, |this, menu, event: &ContextMenuEvent, window, cx| {
            if !this.panel_menu.as_ref().is_some_and(|m| m.menu == *menu) {
                return;
            }
            match event {
                ContextMenuEvent::Dismissed => {
                    let menu = menu.clone();
                    cx.defer_in(window, move |this, _, cx| {
                        if this.panel_menu.as_ref().is_some_and(|m| m.menu == menu) {
                            this.panel_menu = None;
                            cx.notify();
                        }
                    });
                }
                ContextMenuEvent::Chosen(i) => {
                    let Some(open) = this.panel_menu.as_ref() else { return };
                    let cmd = open.commands.get(*i).copied().flatten();
                    let target = open.target.clone();
                    if let Some(cmd) = cmd {
                        this.run_panel_cmd(cmd, &target, window, cx);
                    }
                }
            }
        });
        self.panel_menu = Some(OpenPanelMenu { menu, target, commands, _sub: sub });
        cx.notify();
    }

    /// Menu 키·Shift+F10(I-042): 선택 항목 옆 (2, 2)px(I-502). 선택이 없으면 루트(판단).
    /// "옆"은 행의 왼쪽 아래 모서리로 둔다(판단: 원문에 기준 모서리가 없다).
    pub(super) fn on_deploy_menu(&mut self, a: &pp::DeployContextMenu, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        let Some(ws) = self.active_ws() else { return };
        let (target, ix, bounds) = {
            let t = &ws.read(cx).tree;
            let target = t.selected.clone();
            let ix = target.as_deref().and_then(|p| t.index_of(p)).unwrap_or(0);
            let b = t.row_bounds.borrow().get(&ix).copied();
            (target, ix, b)
        };
        let _ = ix;
        let position = bounds
            .map(|b| point(b.left() + KEYBOARD_OFFSET_X, b.bottom() + KEYBOARD_OFFSET_Y))
            .unwrap_or_else(|| point(KEYBOARD_OFFSET_X, KEYBOARD_OFFSET_Y));
        self.open_panel_menu(target, position, w, cx);
    }

    fn run_panel_cmd(&mut self, cmd: PanelCmd, target: &Path, window: &mut Window, cx: &mut Context<Self>) {
        if keymap::dev_enabled(cx) {
            println!("[dev] panel-menu-exec cmd={cmd:?}");
        }
        match cmd {
            PanelCmd::NewFile => self.start_new(false, window, cx),
            PanelCmd::NewFolder => self.start_new(true, window, cx),
            PanelCmd::Reveal => self.reveal_in_explorer(cx),
            PanelCmd::OpenDefault => self.open_with_system(cx),
            PanelCmd::MarkdownPreview => {}
            PanelCmd::Unfold | PanelCmd::Fold => {
                let Some(ws) = self.active_ws() else { return };
                let target = target.to_path_buf();
                ws.update(cx, |ws, cx| {
                    let t = &mut ws.tree;
                    if cmd == PanelCmd::Unfold {
                        // 접힌 줄의 조각을 모두 풀어 한 단계씩 보인다(I-538).
                        if let Some(ix) = t.index_of(&target) {
                            let segs: Vec<PathBuf> = t.rows[ix].segments.iter().map(|(_, p)| p.clone()).collect();
                            t.unfolded.extend(segs);
                        }
                    } else {
                        let under: Vec<PathBuf> = t.unfolded.iter().filter(|p| p.starts_with(&target)).cloned().collect();
                        for p in under {
                            t.unfolded.remove(&p);
                        }
                    }
                    t.rebuild(cx);
                });
                self.log_tree(cx);
            }
            PanelCmd::Cut => self.set_clipboard(true, cx),
            PanelCmd::Copy => self.set_clipboard(false, cx),
            PanelCmd::Duplicate => self.duplicate(window, cx),
            PanelCmd::Paste => self.paste(window, cx),
            PanelCmd::CopyPath => self.copy_paths(false, cx),
            PanelCmd::CopyRelativePath => self.copy_paths(true, cx),
            PanelCmd::Rename => self.start_rename(window, cx),
            PanelCmd::Trash => self.request_delete(false, window, cx),
            PanelCmd::Delete => self.request_delete(true, window, cx),
            PanelCmd::AddFolders => self.start_pick(window, cx),
            PanelCmd::RemoveFromProject => {
                // I-555: 등록 해제(사이드바 Remove 와 같다). 디스크는 그대로(A-14.3).
                if let Some(i) = self.folders.active_index() {
                    self.remove_folder(i, "project-panel-menu", window, cx);
                }
            }
            PanelCmd::ExpandAll | PanelCmd::CollapseAll => {
                let root = self.active_ws().map(|ws| ws.read(cx).tree.root.clone());
                if root.as_deref() == Some(target) {
                    if cmd == PanelCmd::ExpandAll {
                        self.on_tree_expand_all(&pp::ExpandAllEntries, window, cx);
                    } else {
                        self.on_tree_collapse_all(&pp::CollapseAllEntries, window, cx);
                    }
                } else {
                    self.set_subtree(target, cmd == PanelCmd::ExpandAll, cx);
                }
            }
        }
        cx.notify();
    }
}

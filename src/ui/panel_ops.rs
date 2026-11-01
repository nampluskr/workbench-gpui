//! 프로젝트 패널 파일 작업 (v0.2 Phase 4, SPEC R-21·R-22, I-037·I-041·I-532·I-533·I-541~I-549·I-097).

use std::path::{Path, PathBuf};

use gpui_kit::*;

use super::Workbench;
use super::keymap::{self, project_panel as pp, workspace as ws_actions};
use crate::fsops::{ops, paths};

/// 패널의 파일 클립보드(I-037: 텍스트가 아니라 파일·폴더 작업). 창 하나에 하나다(판단: 폴더 사이 복사도 된다).
#[derive(Clone, Debug)]
pub struct FileClipboard {
    pub paths: Vec<PathBuf>,
    pub cut: bool,
}

impl Workbench {
    /// dev 출력: 디스크 작업 하나.
    pub(super) fn log_fs(&self, op: &str, targets: &[&Path], error: Option<String>, cx: &App) {
        if keymap::dev_enabled(cx) {
            let t: Vec<String> = targets.iter().map(|p| p.display().to_string()).collect();
            println!(
                "[dev] fs-op op={op} result={} targets={} error={}",
                if error.is_none() { "ok" } else { "failed" },
                t.join(";"),
                error.unwrap_or_else(|| "none".into())
            );
        }
    }

    /// 선택 기준 붙여넣기 대상 폴더: 폴더면 그것, 파일이면 부모, 없으면 루트.
    fn target_dir(&self, cx: &App) -> Option<PathBuf> {
        let ws = self.active_ws()?;
        let t = &ws.read(cx).tree;
        Some(match &t.selected {
            Some(p) if p.is_dir() => p.clone(),
            Some(p) => p.parent().map(Path::to_path_buf).unwrap_or_else(|| t.root.clone()),
            None => t.root.clone(),
        })
    }

    /// 옮기거나 이름을 바꾼 경로를 모든 폴더 Workspace 에 반영한다(리뷰 1회차 ④ D-043): 탭 경로를 새 경로로 바꾸고,
    /// 활성이 아닌 폴더의 트리도 디스크를 다시 읽는다(출발 폴더가 다른 폴더일 때).
    pub(super) fn apply_move(&mut self, from: &Path, to: &Path, cx: &mut Context<Self>) {
        let active = self.active_ws().map(|w| w.entity_id());
        let all: Vec<_> = self.folders.workspaces.values().cloned().collect();
        for ws in all {
            let is_active = Some(ws.entity_id()) == active;
            ws.update(cx, |ws, cx| {
                ws.pane.rename_path(from, to);
                if !is_active && (from.starts_with(&ws.tree.root) || to.starts_with(&ws.tree.root)) {
                    ws.tree.refresh(cx);
                }
            });
        }
        if keymap::dev_enabled(cx) {
            println!("[dev] move-applied from={} to={}", from.display(), to.display());
        }
    }

    /// dev 출력: 복사가 따라가지 않고 건너뛴 재분석 지점(D-044 ①).
    fn log_skipped(&self, op: &str, report: &ops::CopyReport, cx: &App) {
        if keymap::dev_enabled(cx) {
            let s: Vec<String> = report.skipped_links.iter().map(|p| p.display().to_string()).collect();
            println!(
                "[dev] copy-report op={op} files={} dirs={} bytes={} skipped_links={} skipped={}",
                report.files,
                report.dirs,
                report.bytes,
                report.skipped_links.len(),
                s.join(";")
            );
        }
    }

    /// 알림 한 줄(D-14 gpui-kit notification). dev 출력에도 낸다.
    fn notify(&self, text: String, window: &mut Window, cx: &mut App) {
        use gpui_kit::component::WindowExt as _;
        window.push_notification(SharedString::from(text.clone()), cx);
        if keymap::dev_enabled(cx) {
            println!("[dev] notification text={text}");
        }
    }

    fn panel_targets(&self, cx: &App) -> Vec<PathBuf> {
        self.active_ws().map(|ws| ws.read(cx).tree.targets()).unwrap_or_default()
    }

    pub(super) fn set_clipboard(&mut self, cut: bool, cx: &mut Context<Self>) {
        if self.panel_editing(cx) {
            return;
        }
        let paths = self.panel_targets(cx);
        if paths.is_empty() {
            return;
        }
        if keymap::dev_enabled(cx) {
            let t: Vec<String> = paths.iter().map(|p| p.display().to_string()).collect();
            println!("[dev] file-clipboard op={} paths={}", if cut { "cut" } else { "copy" }, t.join(";"));
        }
        self.file_clipboard = Some(FileClipboard { paths, cut });
        cx.notify();
    }

    pub(super) fn on_copy(&mut self, a: &pp::Copy, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.set_clipboard(false, cx);
    }

    pub(super) fn on_cut(&mut self, a: &pp::Cut, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.set_clipboard(true, cx);
    }

    /// I-544: 붙여 넣을 것이 있는가.
    pub(super) fn can_paste(&self) -> bool {
        self.file_clipboard.as_ref().is_some_and(|c| !c.paths.is_empty())
    }

    pub(super) fn on_paste(&mut self, a: &pp::Paste, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.paste(w, cx);
    }
}

impl Workbench {
    /// 붙여넣기(I-037·I-544). 같은 이름이 있으면 ` copy` 를 붙인다(`ops::paste_path`).
    /// 잘라낸 항목은 옮기고 클립보드를 비운다. 같은 폴더에 잘라 붙이면 아무것도 하지 않는다(판단).
    pub(super) fn paste(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        if self.panel_editing(cx) {
            return;
        }
        let Some(clip) = self.file_clipboard.clone() else { return };
        let Some(dir) = self.target_dir(cx) else { return };
        let mut created = Vec::new();
        for src in &clip.paths {
            let Some(name) = src.file_name().map(|n| n.to_string_lossy().into_owned()) else { continue };
            if clip.cut && src.parent() == Some(dir.as_path()) {
                self.log_fs("paste-skip-same-folder", &[src], None, cx);
                continue;
            }
            let dst = ops::paste_path(&dir, &name, src.is_dir());
            let result = if clip.cut {
                ops::move_entry(src, &dst).map(|_| ops::CopyReport::default())
            } else {
                ops::copy_entry(src, &dst)
            };
            let op = if clip.cut { "paste-move" } else { "paste-copy" };
            self.log_fs(op, &[src, &dst], result.as_ref().err().map(|e| e.to_string()), cx);
            if let Ok(report) = &result {
                self.log_skipped(op, report, cx);
            }
            if let Err(e) = &result
                && e.to_string() == ops::MOVE_REFUSED_LINKS
            {
                // D-044 ②: 다른 볼륨 이동을 시작 전에 거부했다(원본·대상 변화 없음). 문구는 원문에 없어 판단으로 정했다.
                self.notify(format!("Cannot move `{name}` to another drive because it contains links (junctions or symbolic links)."), window, cx);
            }
            // 맨 위 항목이 링크라 건너뛰었으면 만든 것이 없다.
            if result.is_ok() && dst.symlink_metadata().is_ok() {
                if clip.cut {
                    self.apply_move(src, &dst, cx);
                }
                created.push(dst);
            }
        }
        if clip.cut {
            self.file_clipboard = None;
        }
        self.after_create(created, "paste", window, cx);
    }

    /// Duplicate(I-543): 같은 폴더에 ` copy` 이름으로 복사한다.
    pub(super) fn duplicate(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let mut created = Vec::new();
        for src in self.panel_targets(cx) {
            let (Some(parent), Some(name)) = (src.parent(), src.file_name()) else { continue };
            if self.active_ws().is_some_and(|ws| ws.read(cx).tree.is_root(&src)) {
                continue;
            }
            let dst = ops::paste_path(parent, &name.to_string_lossy(), src.is_dir());
            let result = ops::copy_entry(&src, &dst);
            self.log_fs("duplicate", &[&src, &dst], result.as_ref().err().map(|e| e.to_string()), cx);
            if let Ok(report) = &result {
                self.log_skipped("duplicate", report, cx);
            }
            if result.is_ok() && dst.symlink_metadata().is_ok() {
                created.push(dst);
            }
        }
        self.after_create(created, "duplicate", window, cx);
    }

    /// 붙여넣기·복제 뒤: 디스크를 다시 읽고, 만든 것을 고르고, 파일은 연다(I-097 `on_paste`, 일반 탭, 포커스는 패널에 둔다. 판단).
    fn after_create(&mut self, created: Vec<PathBuf>, via: &str, window: &mut Window, cx: &mut Context<Self>) {
        if let Some(ws) = self.active_ws() {
            ws.update(cx, |ws, cx| ws.tree.refresh(cx));
        }
        for p in created.iter().filter(|p| p.is_file()) {
            self.open_file(p, false, false, via, window, cx);
        }
        if let Some(last) = created.last() {
            self.reveal(last, cx);
        }
        self.log_tree(cx);
        cx.notify();
    }

    pub(super) fn copy_paths(&mut self, relative: bool, cx: &mut Context<Self>) {
        let Some(ws) = self.active_ws() else { return };
        let root = ws.read(cx).tree.root.clone();
        let targets = ws.read(cx).tree.targets();
        if targets.is_empty() {
            return;
        }
        // 여러 항목이면 줄바꿈으로 잇는다(판단).
        let text = targets
            .iter()
            .map(|p| if relative { paths::relative(p, &root) } else { paths::absolute(p) })
            .collect::<Vec<_>>()
            .join("\n");
        if keymap::dev_enabled(cx) {
            println!("[dev] clipboard-write kind={} text={text:?}", if relative { "relative" } else { "absolute" });
        }
        cx.write_to_clipboard(ClipboardItem::new_string(text));
    }

    pub(super) fn on_copy_path(&mut self, a: &ws_actions::CopyPath, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.copy_paths(false, cx);
    }

    pub(super) fn on_copy_relative_path(&mut self, a: &ws_actions::CopyRelativePath, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.copy_paths(true, cx);
    }
}

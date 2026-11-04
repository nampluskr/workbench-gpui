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

/// One finished copy/move job: error text instead of `io::Error` so it can cross threads cheaply.
struct FsJob {
    src: PathBuf,
    dst: PathBuf,
    result: Result<ops::CopyReport, String>,
    /// The destination exists afterwards (a skipped top-level link creates nothing).
    made: bool,
}

static MOVE_LOCK: std::sync::Mutex<()> = std::sync::Mutex::new(());

/// What a finished batch means for the UI, decided without touching the app (so it is unit-testable).
#[derive(Debug, Default, PartialEq)]
struct Outcome {
    /// Moves to apply to tabs/trees (cut only), as (from, to).
    moved: Vec<(PathBuf, PathBuf)>,
    /// Newly made paths, in order; these get selected/opened.
    created: Vec<PathBuf>,
    /// Sources that failed.
    failed: Vec<PathBuf>,
    /// Sources refused because they contain links (own notice each).
    refused: Vec<PathBuf>,
    /// Failures that get the aggregate notice.
    general_failed: usize,
}

fn summarize(done: &[FsJob], cut: bool) -> Outcome {
    let mut o = Outcome::default();
    for job in done {
        match &job.result {
            Ok(_) => {
                // A skipped top-level link creates nothing.
                if job.made {
                    if cut {
                        o.moved.push((job.src.clone(), job.dst.clone()));
                    }
                    o.created.push(job.dst.clone());
                }
            }
            Err(e) => {
                o.failed.push(job.src.clone());
                if e == ops::MOVE_REFUSED_LINKS {
                    o.refused.push(job.src.clone());
                } else {
                    o.general_failed += 1;
                }
            }
        }
    }
    o
}

/// A finished cut paste may put its failed entries back only if no copy/cut/paste started after it.
fn may_restore(current_gen: u64, job_gen: u64) -> bool {
    current_gen == job_gen
}

/// Selecting/opening results is allowed only while the workspace that started the job is still the active one.
fn same_workspace<T: PartialEq>(active: Option<T>, started: Option<T>) -> bool {
    active == started
}

/// Blocking half: runs `(src, target dir)` jobs in order. Destination names are picked here, right before each copy.
fn run_jobs(jobs: Vec<(PathBuf, PathBuf)>, cut: bool) -> Vec<FsJob> {
    jobs.into_iter()
        .map(|(src, dir)| {
            // A same-volume rename replaces an existing file, so picking a name and moving must be one step
            // across concurrent moves. Copies use create_new and need no lock.
            // shortcut: guards only this app's own moves; an external program creating the name in between is not covered.
            let _guard = cut.then(|| MOVE_LOCK.lock().unwrap_or_else(|e| e.into_inner()));
            let name = src.file_name().map(|n| n.to_string_lossy().into_owned()).unwrap_or_default();
            let dst = ops::paste_path(&dir, &name, src.is_dir());
            let result = if cut {
                ops::move_entry(&src, &dst).map(|_| ops::CopyReport::default())
            } else {
                ops::copy_entry(&src, &dst)
            };
            let made = dst.symlink_metadata().is_ok();
            FsJob { src, dst, result: result.map_err(|e| e.to_string()), made }
        })
        .collect()
}
/// Aggregate failure line, same shape as `panel_delete::failure_text`.
fn failure_text(verb: &str, failed: usize, total: usize) -> String {
    format!("Failed to {verb} {failed} of {total} file(s).")
}

/// Clipboard left after a cut paste: only the entries that failed to move, `None` if all moved.
fn cut_leftover(failed: Vec<PathBuf>) -> Option<FileClipboard> {
    (!failed.is_empty()).then_some(FileClipboard { paths: failed, cut: true })
}

impl Workbench {
    /// dev 출력: 디스크 작업 하나.
    pub(super) fn log_fs(&self, op: &str, targets: &[&Path], error: Option<String>, cx: &App) {
        // Phase 5(R-24): 앱 자신의 작업 경로를 남겨 감시 이벤트를 바깥 변경과 구분한다.
        // 시험 훅(D-047): 파일 작업 직후 UI 스레드를 잠시 멈춘다(`--dev-ui-stall fs-<op> <ms>`).
        crate::dev::ui_stall(&format!("fs-{op}"));
        let now = std::time::Instant::now();
        self.watch.self_ops.borrow_mut().record(targets, now);
        // 앱이 이미 반영한 이름 바꾸기·이동은 감시가 다시 적용하지 않게 짝으로 남긴다(Phase 5 리뷰 1회차 ① D-046).
        if error.is_none() && targets.len() == 2 && matches!(op, "rename" | "paste-move") {
            self.watch.self_ops.borrow_mut().record_rename(targets[0], targets[1], now);
        }
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
        self.clip_gen += 1;
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
    /// 잘라낸 항목은 옮기고 클립보드를 비운다(실패한 항목만 남긴다, AUDIT 3). 같은 폴더에 잘라 붙이면 아무것도 하지 않는다(판단).
    /// 복사·이동은 백그라운드에서 돈다(AUDIT 4). 겹친 요청은 서로 독립이다.
    pub(super) fn paste(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        if self.panel_editing(cx) {
            return;
        }
        let Some(clip) = self.file_clipboard.clone() else { return };
        let Some(dir) = self.target_dir(cx) else { return };
        let mut jobs = Vec::new();
        for src in &clip.paths {
            if src.file_name().is_none() {
                continue;
            }
            if clip.cut && src.parent() == Some(dir.as_path()) {
                self.log_fs("paste-skip-same-folder", &[src], None, cx);
                continue;
            }
            jobs.push((src.clone(), dir.clone()));
        }
        if clip.cut {
            // Taken now so a second paste cannot move the same entries; failed ones are put back on completion.
            self.file_clipboard = None;
            self.clip_gen += 1;
        }
        self.run_fs_jobs(jobs, clip.cut, if clip.cut { "paste-move" } else { "paste-copy" }, window, cx);
    }

    /// Duplicate(I-543): 같은 폴더에 ` copy` 이름으로 복사한다.
    pub(super) fn duplicate(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let mut jobs = Vec::new();
        for src in self.panel_targets(cx) {
            let Some(parent) = src.parent() else { continue };
            if src.file_name().is_none() || self.active_ws().is_some_and(|ws| ws.read(cx).tree.is_root(&src)) {
                continue;
            }
            jobs.push((src.clone(), parent.to_path_buf()));
        }
        self.run_fs_jobs(jobs, false, "duplicate", window, cx);
    }

    /// Runs `(src, target dir)` copy/move jobs on the background executor, then applies the results on the UI thread.
    fn run_fs_jobs(
        &mut self,
        jobs: Vec<(PathBuf, PathBuf)>,
        cut: bool,
        op: &'static str,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        let ws_id = self.active_ws().map(|w| w.entity_id());
        let gen_at_start = self.clip_gen;
        cx.spawn_in(window, async move |this, cx| {
            let done = cx.background_spawn(async move { run_jobs(jobs, cut) }).await;
            let _ = this.update_in(cx, |this, window, cx| this.finish_fs_jobs(done, cut, op, (ws_id, gen_at_start), window, cx));
        })
        .detach();
    }

    /// UI-thread half of a paste/duplicate: log, notify failures, apply moves, restore failed cut entries, select results.
    /// Disk changes already happened, so those are always applied; selection/opening only if the workspace is still active.
    fn finish_fs_jobs(
        &mut self,
        done: Vec<FsJob>,
        cut: bool,
        op: &str,
        start: (Option<EntityId>, u64), // (workspace, clipboard generation) when the job began
        window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        let (ws_id, job_gen) = start;
        for job in &done {
            self.log_fs(op, &[&job.src, &job.dst], job.result.as_ref().err().cloned(), cx);
            if let Ok(report) = &job.result {
                self.log_skipped(op, report, cx);
            }
        }
        let Outcome { moved, created, failed, refused, general_failed } = summarize(&done, cut);
        for src in &refused {
            // D-044 ②: 다른 볼륨 이동을 시작 전에 거부했다(원본·대상 변화 없음). 문구는 원문에 없어 판단으로 정했다.
            let name = src.file_name().map(|n| n.to_string_lossy().into_owned()).unwrap_or_default();
            self.notify(format!("Cannot move `{name}` to another drive because it contains links (junctions or symbolic links)."), window, cx);
        }
        for (from, to) in &moved {
            self.apply_move(from, to, cx);
        }
        // AUDIT 3: a cut keeps only the entries that failed so they can be retried, unless a newer copy/cut/paste started since.
        if cut && may_restore(self.clip_gen, job_gen) {
            self.file_clipboard = cut_leftover(failed);
        }
        if general_failed > 0 {
            let verb = match op {
                "paste-move" => "move",
                "paste-copy" => "copy",
                _ => "duplicate",
            };
            self.notify(failure_text(verb, general_failed, done.len()), window, cx);
        }
        if same_workspace(self.active_ws().map(|w| w.entity_id()), ws_id) {
            self.after_create(created, if op == "duplicate" { "duplicate" } else { "paste" }, window, cx);
        } else {
            // The workspace changed or closed while copying: skip selecting/opening, just reload the one that started it.
            if let Some(ws) = self.folders.workspaces.values().find(|w| Some(w.entity_id()) == ws_id).cloned() {
                ws.update(cx, |ws, cx| ws.tree.refresh(cx));
            }
            cx.notify();
        }
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

#[cfg(test)]
mod tests {
    // Explicit imports: gpui_kit::* via super::* shadows the 	est macro.
    use super::{FsJob, PathBuf, cut_leftover, failure_text, may_restore, ops, run_jobs, same_workspace, summarize};

    #[test]
    fn partial_cut_failure_keeps_only_failed_entries() {
        assert!(cut_leftover(Vec::new()).is_none());
        let left = cut_leftover(vec![PathBuf::from("b")]).unwrap();
        assert_eq!(left.paths, vec![PathBuf::from("b")]);
        assert!(left.cut);
        assert_eq!(failure_text("move", 1, 3), "Failed to move 1 of 3 file(s).");
    }

    #[test]
    fn run_jobs_keeps_going_after_a_failed_entry() {
        let dir = std::env::temp_dir().join(format!("wb-p1-2-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();
        let ok = dir.join("a.txt");
        std::fs::write(&ok, "x").unwrap();
        let missing = dir.join("missing.txt");
        let out = run_jobs(vec![(missing.clone(), dir.clone()), (ok.clone(), dir.clone())], false);
        assert!(out[0].result.is_err() && !out[0].made);
        assert!(out[1].result.is_ok() && out[1].made);
        assert!(out[1].dst != ok && out[1].dst.exists());
        let _ = std::fs::remove_dir_all(&dir);
    }

    fn job(src: &str, dst: &str, result: Result<(), &str>, made: bool) -> FsJob {
        FsJob {
            src: PathBuf::from(src),
            dst: PathBuf::from(dst),
            result: result.map(|_| Default::default()).map_err(str::to_string),
            made,
        }
    }

    #[test]
    fn summarize_partial_cut_selects_only_successes() {
        let done = vec![
            job("a", "out/a", Ok(()), true),
            job("b", "out/b", Err("denied"), false),
            job("c", "out/c", Err(ops::MOVE_REFUSED_LINKS), false),
            job("d", "out/d", Ok(()), false), // skipped link: nothing made
        ];
        let o = summarize(&done, true);
        assert_eq!(o.created, vec![PathBuf::from("out/a")]);
        assert_eq!(o.moved, vec![(PathBuf::from("a"), PathBuf::from("out/a"))]);
        assert_eq!(o.failed, vec![PathBuf::from("b"), PathBuf::from("c")]);
        assert_eq!(o.refused, vec![PathBuf::from("c")]);
        assert_eq!(o.general_failed, 1);
        // Copy: nothing is "moved".
        assert!(summarize(&done, false).moved.is_empty());
    }

    #[test]
    fn only_the_latest_generation_restores_the_clipboard() {
        // A starts (gen 1), B starts (gen 2); A finishes last or first, only B may restore.
        assert!(!may_restore(2, 1));
        assert!(may_restore(2, 2));
        // A copy/cut after the paste started (gen 3) also blocks restoring.
        assert!(!may_restore(3, 2));
    }

    #[test]
    fn results_skip_selection_when_workspace_changed() {
        assert!(same_workspace(Some(1), Some(1)));
        assert!(!same_workspace(Some(2), Some(1)));
        assert!(!same_workspace(None, Some(1)));
    }

    #[test]
    fn concurrent_cuts_to_the_same_name_keep_both_files() {
        let dir = std::env::temp_dir().join(format!("wb-p1-12-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        let (a, b, out) = (dir.join("A"), dir.join("B"), dir.join("out"));
        for d in [&a, &b, &out] {
            std::fs::create_dir_all(d).unwrap();
        }
        let handles: Vec<_> = [(&a, "from-a"), (&b, "from-b")]
            .into_iter()
            .map(|(d, text)| {
                let src = d.join("x.txt");
                std::fs::write(&src, text).unwrap();
                let out = out.clone();
                std::thread::spawn(move || run_jobs(vec![(src, out)], true))
            })
            .collect();
        for h in handles {
            assert!(h.join().unwrap()[0].result.is_ok());
        }
        let mut texts: Vec<String> =
            std::fs::read_dir(&out).unwrap().map(|e| std::fs::read_to_string(e.unwrap().path()).unwrap()).collect();
        texts.sort();
        assert_eq!(texts, vec!["from-a", "from-b"]);
        let _ = std::fs::remove_dir_all(&dir);
    }
}

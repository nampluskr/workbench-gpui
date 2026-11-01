//! 휴지통·영구 삭제와 탐색기·기본 앱 열기 (v0.2 Phase 4, SPEC R-20·R-22, A-14.1~A-14.11, P-015, D-12·D-14, I-532·I-533).

use std::path::PathBuf;

use gpui_kit::*;

use super::Workbench;
use super::keymap::{self, project_panel as pp};
use super::task_dialog::{self, Answer, Prompt};
use crate::fsops::ops;

/// P-015 목록 최대 줄 수. 넘으면 `.. {N} files not shown`.
const LIST_MAX: usize = 10;

/// A-14.7~A-14.9·P-015 확인창 문구. 수정된 버퍼 문구(A-14.10)는 v0.2 에 생기지 않는다(D-18).
pub fn delete_prompt(names: &[String], permanent: bool) -> Prompt {
    let n = names.len();
    let question = match (permanent, n) {
        (false, 1) => format!("Do you want to trash `{}`?", names[0]),
        (true, 1) => format!("Are you sure you want to permanently delete `{}`?", names[0]),
        (false, _) => format!("Do you want to trash the following {n} files?"),
        (true, _) => format!("Are you sure you want to permanently delete the following {n} files?"),
    };
    let instruction = if n > 1 {
        let mut lines: Vec<String> = names.iter().take(LIST_MAX).cloned().collect();
        if n > LIST_MAX {
            lines.push(format!(".. {} files not shown", n - LIST_MAX));
        }
        format!("{question}\n{}", lines.join("\n"))
    } else {
        question
    };
    Prompt {
        title: super::APP_TITLE.to_string(),
        instruction,
        content: permanent.then(|| "This cannot be undone.".to_string()),
        confirm_label: if permanent { "Delete" } else { "Trash" },
    }
}

/// A-14.11 실패 알림 문구.
pub fn failure_text(permanent: bool, failed: usize, total: usize) -> String {
    format!("Failed to {} {failed} of {total} file(s).", if permanent { "delete" } else { "trash" })
}

impl Workbench {
    pub(super) fn on_trash(&mut self, a: &pp::Trash, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.request_delete(false, w, cx);
    }

    pub(super) fn on_delete(&mut self, a: &pp::Delete, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.request_delete(true, w, cx);
    }

    /// A-14.1: 루트가 아닌 항목만. 루트만 선택했으면 아무 일도 하지 않는다(A-14 아래 목록). 확인창은 늘 띄운다.
    pub(super) fn request_delete(&mut self, permanent: bool, window: &mut Window, cx: &mut Context<Self>) {
        let Some(ws) = self.active_ws() else { return };
        if ws.read(cx).tree.edit.is_some() || self.deleting {
            return;
        }
        let targets: Vec<PathBuf> = {
            let t = &ws.read(cx).tree;
            t.targets().into_iter().filter(|p| !t.is_root(p)).collect()
        };
        if targets.is_empty() {
            if keymap::dev_enabled(cx) {
                println!("[dev] delete-skipped permanent={permanent} reason=root-or-empty");
            }
            return;
        }
        let names: Vec<String> = targets
            .iter()
            .map(|p| p.file_name().map(|n| n.to_string_lossy().into_owned()).unwrap_or_default())
            .collect();
        let prompt = delete_prompt(&names, permanent);
        if keymap::dev_enabled(cx) {
            println!(
                "[dev] task-dialog-open title={:?} instruction={:?} content={:?} buttons={}|Cancel default=Cancel",
                prompt.title, prompt.instruction, prompt.content, prompt.confirm_label
            );
        }
        let parent = task_dialog::active_window();
        self.deleting = true;
        cx.spawn_in(window, async move |this, cx| {
            let answer = cx
                .background_spawn(async move { task_dialog::show_blocking(parent, &prompt) })
                .await;
            let _ = this.update_in(cx, |this, window, cx| {
                this.deleting = false;
                let answer = match answer {
                    Ok(a) => a,
                    Err(e) => {
                        if keymap::dev_enabled(cx) {
                            println!("[dev] task-dialog-result error={e}");
                        }
                        return;
                    }
                };
                if keymap::dev_enabled(cx) {
                    println!("[dev] task-dialog-result button={answer:?} comctl32_loads={}", task_dialog::load_count());
                }
                if answer == Answer::Confirm {
                    this.perform_delete(targets, permanent, window, cx);
                }
            });
        })
        .detach();
    }
}

impl Workbench {
    /// 확인 뒤 실제로 버리거나 지운다(A-14.3). 실패가 있으면 알림(A-14.11, D-14). 열린 탭은 그대로 둔다(D-18: 지워진 파일 탭 표시는 이후 버전).
    fn perform_delete(&mut self, targets: Vec<PathBuf>, permanent: bool, window: &mut Window, cx: &mut Context<Self>) {
        let first_ix = self
            .active_ws()
            .and_then(|ws| targets.first().and_then(|p| ws.read(cx).tree.index_of(p)));
        let jobs = targets.clone();
        cx.spawn_in(window, async move |this, cx| {
            let results: Vec<Result<(), String>> = cx
                .background_spawn(async move {
                    jobs.iter()
                        .map(|p| if permanent { ops::delete(p).map_err(|e| e.to_string()) } else { ops::trash(p) })
                        .collect()
                })
                .await;
            let _ = this.update_in(cx, |this, window, cx| {
                let op = if permanent { "delete" } else { "trash" };
                for (p, r) in targets.iter().zip(&results) {
                    this.log_fs(op, &[p.as_path()], r.as_ref().err().cloned(), cx);
                }
                let failed = results.iter().filter(|r| r.is_err()).count();
                if failed > 0 {
                    let text = failure_text(permanent, failed, results.len());
                    use gpui_kit::component::WindowExt as _;
                    window.push_notification(SharedString::from(text.clone()), cx);
                    if keymap::dev_enabled(cx) {
                        println!("[dev] notification text={text}");
                    }
                }
                if let Some(ws) = this.active_ws() {
                    ws.update(cx, |ws, cx| {
                        let t = &mut ws.tree;
                        t.refresh(cx);
                        // 지운 자리의 다음 행(없으면 끝 행)을 고른다(판단).
                        if let Some(ix) = first_ix {
                            let ix = ix.min(t.rows.len().saturating_sub(1));
                            let path = t.rows.get(ix).map(|r| r.path.clone());
                            t.select_only(path);
                        }
                    });
                }
                this.log_tree(cx);
                cx.notify();
            });
        })
        .detach();
    }

    /// Reveal in File Explorer(I-532): 탐색기에서 항목을 골라 보인다. `--dev-no-shell` 이면 실행하지 않고 기록만 한다.
    pub(super) fn on_reveal(&mut self, a: &pp::RevealInFileManager, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.reveal_in_explorer(cx);
    }

    pub(super) fn reveal_in_explorer(&mut self, cx: &mut Context<Self>) {
        let Some(ws) = self.active_ws() else { return };
        let Some(path) = ws.read(cx).tree.selected.clone() else { return };
        let arg = format!("/select,\"{}\"", path.display());
        self.shell_run("reveal", "explorer.exe", &arg, cx);
    }

    /// Open in Default App(I-533): 기본 앱으로 연다(폴더면 탐색기).
    pub(super) fn on_open_with_system(&mut self, a: &pp::OpenWithSystem, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.open_with_system(cx);
    }

    pub(super) fn open_with_system(&mut self, cx: &mut Context<Self>) {
        let Some(ws) = self.active_ws() else { return };
        let Some(path) = ws.read(cx).tree.selected.clone() else { return };
        if keymap::dev_enabled(cx) {
            println!("[dev] shell op=open-default path={} executed={}", path.display(), !crate::dev::no_shell());
        }
        if !crate::dev::no_shell() {
            super::shell::open_default(&path);
        }
    }

    fn shell_run(&self, op: &str, program: &str, arg: &str, cx: &App) {
        let executed = !crate::dev::no_shell();
        if keymap::dev_enabled(cx) {
            println!("[dev] shell op={op} program={program} arg={arg:?} executed={executed}");
        }
        if executed {
            super::shell::spawn_raw(program, arg);
        }
    }
}

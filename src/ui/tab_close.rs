//! Closing tabs and the save questions (v0.4 P3-3, D-6; A-13.4, I-069, E-081~E-085).
//!
//! - A dirty tab asks "Save / Don't Save / Cancel" before it closes (E-081). Closing the window or quitting asks
//!   once for all dirty tabs (E-082: "Save all / Discard all / Cancel"). Cancel keeps everything open.
//! - Every save goes through `save_tab`: before writing it compares the disk with what the tab last read and asks
//!   E-084 (changed on disk) or E-085 (deleted on disk) first. Ctrl-S, the close question and the exit question
//!   all use it, so the write path (P3-2 `begin_save`/`finish_save`) is the only one.
//! - The questions are Windows TaskDialogs (`task_dialog::choose_blocking`, E-080) shown on a background thread.
//!   What each button does is decided by plain functions below (`guard`, `guard_action`, `close_action`).

use std::path::{Path, PathBuf};

use gpui_kit::*;

use super::folders::FolderWorkspace;
use super::keymap;
use super::metrics;
use super::pane::{SaveStart, buffer_hash, read_text, save_failed, text_hash};
use super::task_dialog::{self, Choice};
use crate::text_io::{self, Format};

/// How a save (or its question) ended.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum End {
    /// Written, or nothing to write (clean tab, tab already gone).
    Saved,
    /// "Discard Edits" (E-084): the buffer was reset to the disk text.
    Discarded,
    /// "Close" (E-085): the user gave the tab up.
    Closed,
    /// Cancelled, refused or failed: the tab stays as it was.
    Cancelled,
}

impl End {
    /// A closing flow may go on (the tab holds nothing the user wants to keep).
    fn may_close(self) -> bool {
        self != End::Cancelled
    }
}

/// What the disk holds for a tab's file.
pub enum Disk {
    Missing,
    /// Exists but cannot be read (permissions, locked): the write will report the error.
    Unreadable,
    Read { text: String, hash: u64, format: Option<Format> },
}

/// Result of comparing the disk with the tab's last read (`Tab::hash`).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Guard {
    Proceed,
    /// E-084: the file changed on disk since the tab last read it.
    Changed,
    /// E-085: the file was deleted on disk.
    Deleted,
}

pub fn guard(disk: &Disk, base_hash: u64) -> Guard {
    match disk {
        Disk::Missing => Guard::Deleted,
        Disk::Read { hash, .. } if *hash != base_hash => Guard::Changed,
        Disk::Read { .. } | Disk::Unreadable => Guard::Proceed,
    }
}

/// The E-084 / E-085 question (buttons end with Cancel).
pub fn guard_choice(guard: Guard) -> Option<Choice> {
    let (instruction, buttons) = match guard {
        Guard::Proceed => return None,
        Guard::Changed => (
            "This file has changed on disk since you started editing it. Do you want to overwrite it?",
            vec!["Overwrite", "Discard Edits", "Cancel"],
        ),
        Guard::Deleted => (
            "This file has been deleted on disk since you started editing it. Do you want to recreate it?",
            vec!["Save", "Close", "Cancel"],
        ),
    };
    Some(Choice { instruction: instruction.into(), content: None, buttons })
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum GuardAction {
    Write,
    Discard,
    Close,
    Cancel,
}

/// Button `button` (index into `guard_choice`) of the E-084 / E-085 question.
pub fn guard_action(guard: Guard, button: usize) -> GuardAction {
    match (guard, button) {
        (Guard::Proceed, _) => GuardAction::Write,
        (_, 0) => GuardAction::Write,
        (Guard::Changed, 1) => GuardAction::Discard,
        (Guard::Deleted, 1) => GuardAction::Close,
        _ => GuardAction::Cancel,
    }
}

/// Keeps the last `max` characters of `path`, with a leading `…` when cut (E-081: front trimmed, 80 characters).
fn trim_front(path: &str, max: usize) -> String {
    let n = path.chars().count();
    if n <= max {
        return path.to_string();
    }
    format!("…{}", path.chars().skip(n - (max - 1)).collect::<String>())
}

/// The close / exit question for these dirty tab names (workspace-relative paths). One name: E-081, several: E-082.
pub fn unsaved_choice(names: &[String]) -> Choice {
    match names {
        [one] => Choice {
            instruction: format!(
                "`{}` contains unsaved edits. Do you want to save it?",
                trim_front(one, metrics::CONFIRM_CLOSE_PATH_MAX_CHARS)
            ),
            content: None,
            buttons: vec!["Save", "Don't Save", "Cancel"],
        },
        _ => Choice {
            instruction: "Do you want to save changes to the following files?".into(),
            content: Some(names.join("\n")),
            buttons: vec!["Save all", "Discard all", "Cancel"],
        },
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum CloseAction {
    Save,
    Discard,
    Cancel,
}

/// Button `button` of `unsaved_choice` (both forms have the same order).
pub fn close_action(button: usize) -> CloseAction {
    match button {
        0 => CloseAction::Save,
        1 => CloseAction::Discard,
        _ => CloseAction::Cancel,
    }
}

/// A dirty tab to ask about: its workspace, path and the name shown in the question.
pub struct Dirty {
    ws: Entity<FolderWorkspace>,
    path: PathBuf,
    name: String,
}

/// What a window close / quit request is waiting on.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Exit {
    Quit,
    CloseWindow,
}

/// Question state of the window: one question at a time; `Leaving` once the exit was allowed.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub enum Prompt {
    #[default]
    Idle,
    Asking,
    Leaving,
}

/// Shows `choice` and returns the pressed button. Esc, closing the dialog and a dialog that cannot be shown all
/// count as the last button (Cancel), so nothing is lost.
async fn ask(choice: Choice, cx: &mut AsyncWindowContext) -> usize {
    let last = choice.buttons.len() - 1;
    let parent = cx.update(|_, _| task_dialog::active_window()).unwrap_or(0);
    let dev = cx.update(|_, cx| keymap::dev_enabled(cx)).unwrap_or(false);
    if dev {
        println!(
            "[dev] task-dialog-open instruction={:?} content={:?} buttons={}",
            choice.instruction,
            choice.content,
            choice.buttons.join("|")
        );
    }
    let answer = cx.background_spawn(async move { task_dialog::choose_blocking(parent, &choice) }).await;
    if dev {
        println!("[dev] task-dialog-result button={answer:?}");
    }
    answer.unwrap_or(last)
}

fn probe(path: &Path) -> Disk {
    if let Err(e) = std::fs::metadata(path)
        && e.kind() == std::io::ErrorKind::NotFound
    {
        return Disk::Missing;
    }
    match read_text(path) {
        Some((text, format)) => Disk::Read { hash: text_hash(&text), text, format },
        None => Disk::Unreadable,
    }
}

/// Saves the tab `path` of `ws` (P3-2 path), asking E-084 / E-085 first when the disk disagrees. A failed or refused
/// write is shown as E-083 and ends `Cancelled`.
pub async fn save_tab(ws: &Entity<FolderWorkspace>, path: &Path, cx: &mut AsyncWindowContext) -> End {
    enum Start {
        Nothing,
        Cancelled,
        Go { token: u64, bytes: Vec<u8>, editor: Entity<gpui_kit::component::input::EditorState>, base: u64, saved_hash: u64 },
    }
    let start = cx.update(|window, cx| {
        let Some(ix) = ws.read(cx).pane.find(path) else { return Start::Nothing };
        let tab = &ws.read(cx).pane.tabs[ix];
        if !tab.dirty {
            return Start::Nothing;
        }
        let (editor, base) = (tab.editor.clone(), tab.hash);
        let text = editor.read(cx).value();
        let saved_hash = buffer_hash(&text);
        match ws.update(cx, |ws, _| ws.pane.begin_save(ix, &text)) {
            SaveStart::Write(token, bytes) => Start::Go { token, bytes, editor, base, saved_hash },
            // Dirty but not writable: a save is already running (the caller retries) or CP949 would lose text.
            SaveStart::Refused(e) => {
                save_failed(path, &e, window, cx);
                Start::Cancelled
            }
            SaveStart::Skip => Start::Cancelled,
        }
    });
    let (token, bytes, editor, base, saved_hash) = match start {
        Ok(Start::Go { token, bytes, editor, base, saved_hash }) => (token, bytes, editor, base, saved_hash),
        Ok(Start::Nothing) | Err(_) => return End::Saved,
        Ok(Start::Cancelled) => return End::Cancelled,
    };

    // Release the in-flight mark without writing (a read started before may be stale, so finish_save drops it).
    let release = |cx: &mut AsyncWindowContext| {
        let _ = cx.update(|_, cx| ws.update(cx, |ws, cx| {
            ws.pane.finish_save(token, false, 0, 0);
            cx.notify();
        }));
    };

    let target = path.to_path_buf();
    let disk = cx.background_executor().spawn(async move { probe(&target) }).await;
    let g = guard(&disk, base);
    if let Some(choice) = guard_choice(g) {
        match guard_action(g, ask(choice, cx).await) {
            GuardAction::Write => {}
            GuardAction::Cancel => {
                release(cx);
                return End::Cancelled;
            }
            GuardAction::Close => {
                release(cx);
                return End::Closed;
            }
            GuardAction::Discard => {
                let _ = cx.update(|window, cx| {
                    ws.update(cx, |ws, cx| {
                        ws.pane.finish_save(token, false, 0, 0);
                        if let (Some(ix), Disk::Read { text, hash, format }) = (ws.pane.find(path), &disk) {
                            ws.pane.discard_edits(ix, *hash, *format);
                            editor.update(cx, |e, cx| e.set_value(text.as_str(), window, cx));
                        }
                        cx.notify();
                    })
                });
                return End::Discarded;
            }
        }
    }

    let target = path.to_path_buf();
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
        if keymap::dev_enabled(cx) {
            println!("[dev] tab-save path={} bytes={len} ok={} fnv={saved_hash:016x}", path.display(), result.is_ok());
        }
        if let Err(e) = &result {
            save_failed(path, e, window, cx);
        }
    });
    if result.is_ok() { End::Saved } else { End::Cancelled }
}

/// Asks about `items` (E-081 / E-082) and saves them when the answer is Save. `true`: the caller may go on
/// (everything saved or given up); `false`: Cancel, or a save that did not finish.
async fn settle(items: &[Dirty], cx: &mut AsyncWindowContext) -> bool {
    let names: Vec<String> = items.iter().map(|d| d.name.clone()).collect();
    match close_action(ask(unsaved_choice(&names), cx).await) {
        CloseAction::Cancel => false,
        CloseAction::Discard => true,
        CloseAction::Save => {
            for d in items {
                if !save_tab(&d.ws, &d.path, cx).await.may_close() {
                    return false;
                }
            }
            true
        }
    }
}

/// Removes the tab `path` (no question).
pub fn remove_tab(ws: &mut FolderWorkspace, path: &Path, cx: &mut Context<FolderWorkspace>) {
    if let Some(ix) = ws.pane.find(path) {
        ws.pane.close_tab(ix);
        cx.notify();
    }
}

impl super::Workbench {
    /// `pane::CloseActiveItem` (Ctrl-W, I-356).
    pub(super) fn on_close_active_item(
        &mut self,
        action: &keymap::pane::CloseActiveItem,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        keymap::log_handled(action, self.focus_name(window, cx), cx);
        let Some(ix) = self.active_ws().and_then(|ws| ws.read(cx).pane.active) else { return };
        self.close_tab_at(ix, window, cx);
    }

    /// Closes tab `ix` of the active folder; a dirty tab asks first (E-081).
    pub(super) fn close_tab_at(&mut self, ix: usize, window: &mut Window, cx: &mut Context<Self>) {
        let Some(ws) = self.active_ws() else { return };
        let Some(tab) = ws.read(cx).pane.tabs.get(ix) else { return };
        let (path, dirty) = (tab.path.clone(), tab.dirty);
        if !dirty {
            self.drop_tab(&ws, &path, window, cx);
            return;
        }
        if self.prompt != Prompt::Idle {
            return;
        }
        self.prompt = Prompt::Asking;
        let item = Dirty { name: ws.read(cx).tree.rel(&path), ws, path };
        cx.spawn_in(window, async move |this, cx| {
            let go = settle(std::slice::from_ref(&item), cx).await;
            let _ = this.update_in(cx, |this, window, cx| {
                this.prompt = Prompt::Idle;
                if go {
                    this.drop_tab(&item.ws, &item.path, window, cx);
                }
            });
        })
        .detach();
    }

    /// Removes the tab and gives the keyboard back to the pane (the closed editor may have had it).
    pub(super) fn drop_tab(&mut self, ws: &Entity<FolderWorkspace>, path: &Path, window: &mut Window, cx: &mut Context<Self>) {
        ws.update(cx, |ws, cx| remove_tab(ws, path, cx));
        self.center_focus.focus(window, cx);
        cx.notify();
    }

    /// Dirty tabs of every folder, in sidebar order.
    fn dirty_tabs(&self, cx: &App) -> Vec<Dirty> {
        let several = self.folders.workspaces.len() > 1;
        let mut out = Vec::new();
        for folder in &self.folders.state.folders {
            let Some(ws) = self.folders.workspaces.get(&folder.id) else { continue };
            let w = ws.read(cx);
            for tab in w.pane.tabs.iter().filter(|t| t.dirty) {
                let rel = w.tree.rel(&tab.path);
                let name = if several { format!("{}\\{rel}", w.tree.root_name) } else { rel };
                out.push(Dirty { ws: ws.clone(), path: tab.path.clone(), name });
            }
        }
        out
    }

    /// A window close or quit was requested. Returns `true` when it may go on now (no dirty tab, or the exit was
    /// already allowed); otherwise asks (E-081 / E-082) and finishes the exit itself when the answer allows it.
    pub(super) fn request_exit(&mut self, exit: Exit, window: &mut Window, cx: &mut Context<Self>) -> bool {
        if self.prompt == Prompt::Leaving {
            return true;
        }
        if self.prompt == Prompt::Asking {
            return false;
        }
        let items = self.dirty_tabs(cx);
        if items.is_empty() {
            return true;
        }
        self.prompt = Prompt::Asking;
        cx.spawn_in(window, async move |this, cx| {
            let go = settle(&items, cx).await;
            let _ = this.update_in(cx, |this, window, cx| {
                this.prompt = if go { Prompt::Leaving } else { Prompt::Idle };
                if go {
                    this.finish_exit(exit, window, cx);
                }
            });
        })
        .detach();
        false
    }

    /// Writes the pending folder-list change, then leaves.
    pub(super) fn finish_exit(&mut self, exit: Exit, window: &mut Window, cx: &mut Context<Self>) {
        match exit {
            Exit::Quit => {
                self.flush_save(Some(window), "quit", cx);
                cx.quit();
            }
            Exit::CloseWindow => {
                // Before the window disappears (A-24.3).
                self.flush_save(Some(window), "close-window", cx);
                window.remove_window();
            }
        }
    }
}

#[cfg(test)]
mod tests {
    // Explicit imports: `super::*` would pull in gpui's `test` macro through `gpui_kit::*`.
    use super::{CloseAction, Disk, End, Guard, GuardAction, close_action, guard, guard_action, guard_choice, metrics, trim_front, unsaved_choice};

    fn read(hash: u64) -> Disk {
        Disk::Read { text: String::new(), hash, format: None }
    }

    /// E-084 / E-085 conditions: a missing file is E-085, different content E-084, same content or an unreadable
    /// file (the write reports it) goes on.
    #[test]
    fn guard_follows_disk_state() {
        assert_eq!(guard(&Disk::Missing, 1), Guard::Deleted);
        assert_eq!(guard(&read(2), 1), Guard::Changed);
        assert_eq!(guard(&read(1), 1), Guard::Proceed);
        assert_eq!(guard(&Disk::Unreadable, 1), Guard::Proceed);
    }

    /// E-084 / E-085 texts and buttons (02-INTERACTION 13.4), each ending with Cancel.
    #[test]
    fn guard_questions_match_spec() {
        let c = guard_choice(Guard::Changed).unwrap();
        assert_eq!(c.instruction, "This file has changed on disk since you started editing it. Do you want to overwrite it?");
        assert_eq!(c.buttons, ["Overwrite", "Discard Edits", "Cancel"]);
        let d = guard_choice(Guard::Deleted).unwrap();
        assert_eq!(d.instruction, "This file has been deleted on disk since you started editing it. Do you want to recreate it?");
        assert_eq!(d.buttons, ["Save", "Close", "Cancel"]);
        assert!(guard_choice(Guard::Proceed).is_none());
    }

    #[test]
    fn guard_buttons_map_to_actions() {
        use GuardAction::*;
        let acts = |g| (0..3).map(|b| guard_action(g, b)).collect::<Vec<_>>();
        assert_eq!(acts(Guard::Changed), [Write, Discard, Cancel]);
        assert_eq!(acts(Guard::Deleted), [Write, Close, Cancel]);
    }

    /// E-081 one tab: path in backticks; E-082 several: file list in the detail and "all" buttons.
    #[test]
    fn unsaved_questions_match_spec() {
        let one = unsaved_choice(&["src\\a.rs".into()]);
        assert_eq!(one.instruction, "`src\\a.rs` contains unsaved edits. Do you want to save it?");
        assert_eq!(one.buttons, ["Save", "Don't Save", "Cancel"]);
        let many = unsaved_choice(&["a.rs".into(), "b.rs".into()]);
        assert_eq!(many.instruction, "Do you want to save changes to the following files?");
        assert_eq!(many.content.as_deref(), Some("a.rs\nb.rs"));
        assert_eq!(many.buttons, ["Save all", "Discard all", "Cancel"]);
        assert_eq!([0, 1, 2].map(close_action), [CloseAction::Save, CloseAction::Discard, CloseAction::Cancel]);
    }

    /// E-081: a long path is cut at the front to 80 characters (spec editor["confirm_close.path_max_chars"]).
    #[test]
    fn long_path_is_trimmed_at_front() {
        let spec = metrics::spec::lookup("editor[\"confirm_close.path_max_chars\"]").unwrap().value;
        assert_eq!(metrics::CONFIRM_CLOSE_PATH_MAX_CHARS as f64, spec);
        let long = format!("{}file.rs", "d\\".repeat(60));
        let cut = trim_front(&long, metrics::CONFIRM_CLOSE_PATH_MAX_CHARS);
        assert_eq!(cut.chars().count(), 80);
        assert!(cut.starts_with('…') && cut.ends_with("file.rs"));
        assert_eq!(trim_front("short.rs", 80), "short.rs");
    }

    /// Only Cancelled stops a closing flow.
    #[test]
    fn closing_stops_only_on_cancel() {
        assert!([End::Saved, End::Discarded, End::Closed].iter().all(|e| e.may_close()));
        assert!(!End::Cancelled.may_close());
    }
}

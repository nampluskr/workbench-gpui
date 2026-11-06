//! Closing tabs and the save questions (v0.4 P3-3, D-6; A-13.4, I-069, E-081~E-085).
//!
//! - A dirty tab asks "Save / Don't Save / Cancel" before it closes (E-081). Closing the window or quitting asks
//!   once for all dirty tabs (E-082: "Save all / Discard all / Cancel"). Cancel keeps everything open.
//! - Every save goes through `save_tab`: before writing it compares the disk with what the tab last read and asks
//!   E-084 (changed on disk) or E-085 (deleted on disk) first. Ctrl-S, the close question and the exit question
//!   all use it, so the write path (P3-2 `begin_save`/`finish_save`) is the only one.
//! - The questions are Windows TaskDialogs (`task_dialog::choose_blocking`, E-080) shown on a background thread.
//!   What each button does is decided by plain functions below (`guard`, `guard_action`, `close_action`).

use std::cell::Cell;
use std::path::{Path, PathBuf};
use std::rc::Rc;

use gpui_kit::*;

use super::folders::FolderWorkspace;
use super::keymap;
use super::metrics;
use super::pane::{CloseState, SaveStart, buffer_hash, disk_differs, read_text, save_failed, text_hash};
use super::pane_group::PaneId;
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

/// What the disk holds for a tab's file.
pub enum Disk {
    Missing,
    /// Exists but cannot be read (permissions, locked): the write will report the error.
    Unreadable,
    /// `hash`: normalized text; `raw`: file bytes (H-18).
    Read { text: String, hash: u64, format: Option<Format>, raw: u64 },
}

/// Result of comparing the disk with the tab's last read or save (`Tab::disk_hash`, raw bytes, H-18).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Guard {
    Proceed,
    /// E-084: the file changed on disk since the tab last read it.
    Changed,
    /// E-085: the file was deleted on disk.
    Deleted,
}

pub fn guard(disk: &Disk, disk_hash: u64) -> Guard {
    match disk {
        Disk::Missing => Guard::Deleted,
        Disk::Read { raw, .. } if disk_differs(*raw, disk_hash) => Guard::Changed,
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
        Some((text, format, raw)) => Disk::Read { hash: text_hash(&text), text, format, raw },
        None => Disk::Unreadable,
    }
}

/// Saves the tab `path` of `ws` (P3-2 path), asking E-084 / E-085 first when the disk disagrees. A failed or refused
/// write is shown as E-083 and ends `Cancelled`.
pub async fn save_tab(
    ws: &Entity<FolderWorkspace>,
    path: &Path,
    batch: Option<&Batch>,
    cx: &mut AsyncWindowContext,
) -> End {
    enum Start {
        Nothing,
        Cancelled,
        Go { token: u64, bytes: Vec<u8>, editor: Entity<gpui_kit::component::input::EditorState>, base: u64, saved_hash: u64 },
    }
    let start = cx.update(|window, cx| {
        // Every view of the file holds the same text (P4-3), so any one gives the buffer.
        let group = &ws.read(cx).group;
        let (Some(ix), Some(editor)) = (group.docs.find(path), group.views(path).next().cloned()) else {
            return Start::Nothing;
        };
        let tab = &group.docs.docs[ix];
        if !tab.modified() {
            return Start::Nothing;
        }
        let base = tab.disk_hash;
        let text = editor.read(cx).value();
        let saved_hash = buffer_hash(&text);
        match ws.update(cx, |ws, _| ws.group.docs.begin_save(ix, &text)) {
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
            ws.group.docs.finish_save(token, false, 0, 0);
            cx.notify();
        }));
    };

    let target = path.to_path_buf();
    let disk = cx.background_executor().spawn(async move { probe(&target) }).await;
    let g = guard(&disk, base);
    if let Some(choice) = guard_choice(g) {
        // The user's answer time is not I/O time: the close flow's wait limit pauses meanwhile (R3).
        batch.inspect(|b| b.asking.set(true));
        let answer = ask(choice, cx).await;
        batch.inspect(|b| b.asking.set(false));
        match guard_action(g, answer) {
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
                        ws.group.docs.finish_save(token, false, 0, 0);
                        if let (Some(ix), Disk::Read { text, hash, format, raw }) = (ws.group.docs.find(path), &disk) {
                            ws.group.docs.discard_edits(ix, *hash, *format, *raw);
                            ws.group.fill(path, text, window, cx);
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
        // A view still open now (the one read at the start may have closed since, and then is no longer kept equal).
        let now = ws.read(cx).group.views(path).next().cloned().unwrap_or(editor);
        let buffer_now = buffer_hash(&now.read(cx).value());
        ws.update(cx, |ws, cx| {
            ws.group.docs.finish_save(token, result.is_ok(), saved_hash, buffer_now);
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

/// How long to wait before looking again at a tab whose save is running. spec: none (app value).
const SAVE_WAIT: std::time::Duration = std::time::Duration::from_millis(25);

/// What a closing flow does once nothing is left to keep (or the user gave it up).
#[derive(Clone)]
pub enum Then {
    /// Close this one tab (the file's view in that pane).
    /// The bool is a Markdown preview tab (L-69): the same path as the editor tab beside it.
    Drop(Entity<FolderWorkspace>, PaneId, PathBuf, bool),
    /// Close the window / quit; covers every tab of every folder.
    Exit(Exit),
}

impl Then {
    fn run(&self, this: &mut super::Workbench, window: &mut Window, cx: &mut Context<super::Workbench>) {
        match self {
            Then::Drop(ws, pane, path, markdown) => {
                if this.prompt == Prompt::Asking {
                    this.prompt = Prompt::Idle;
                }
                this.drop_tab(ws, *pane, path, *markdown, window, cx);
            }
            Then::Exit(exit) => {
                this.prompt = Prompt::Leaving;
                this.finish_exit(*exit, window, cx);
            }
        }
    }
}

/// A tab a closing flow still has to deal with; `waiting`: its save is running.
pub struct Open {
    item: Dirty,
    waiting: bool,
}

enum Settled {
    Cancel,
    Discard,
    /// Every listed tab was saved (or given up); look again, the buffers may have changed meanwhile.
    Saved,
}

/// Asks about `items` (E-081 / E-082) and saves them when the answer is Save.
async fn settle(
    items: &[&Dirty],
    this: &WeakEntity<super::Workbench>,
    batch: &Rc<Batch>,
    cx: &mut AsyncWindowContext,
) -> Settled {
    let names: Vec<String> = items.iter().map(|d| d.name.clone()).collect();
    match close_action(ask(unsaved_choice(&names), cx).await) {
        CloseAction::Cancel => Settled::Cancel,
        CloseAction::Discard => Settled::Discard,
        CloseAction::Save => {
            // The saves run as their own task and this returns at once, so `resolve` keeps looking (and keeps its
            // wait limit) while they run; the task, the save tokens and the completion handling live on (R3).
            let jobs: Vec<(Entity<FolderWorkspace>, PathBuf)> = items.iter().map(|d| (d.ws.clone(), d.path.clone())).collect();
            let batch = batch.clone();
            batch.running.set(true);
            let started = this.update_in(cx, |_, window, cx| {
                cx.spawn_in(window, async move |this, cx| {
                    for (ws, path) in &jobs {
                        let end = save_tab(ws, path, Some(&batch), cx).await;
                        batch.progress.set(batch.progress.get() + 1);
                        match end {
                            End::Cancelled => {
                                batch.cancelled.set(true);
                                break;
                            }
                            // E-085 "Close": the user gave this file up.
                            End::Closed => {
                                let _ = this.update_in(cx, |this, window, cx| this.drop_file(ws, path, window, cx));
                            }
                            End::Saved | End::Discarded => {}
                        }
                    }
                    batch.running.set(false);
                })
                .detach();
            });
            if started.is_err() {
                return Settled::Cancel;
            }
            Settled::Saved
        }
    }
}

/// Progress of the saves a close question started (R3). Foreground only, hence `Cell`.
#[derive(Default)]
pub struct Batch {
    /// The save task has not finished all its tabs.
    running: Cell<bool>,
    /// A save was cancelled, refused or failed: the close request ends.
    cancelled: Cell<bool>,
    /// An E-084 / E-085 question is open: the user is answering, not the disk.
    asking: Cell<bool>,
    /// Tabs finished so far; any progress restarts the wait.
    progress: Cell<u32>,
}

/// How long the close flow has waited on save I/O (R3). Time is passed in so it is testable. Waiting restarts when a
/// tab finishes, and does not run while the user answers a question.
#[derive(Default)]
pub struct WaitClock {
    since: Option<std::time::Duration>,
    progress: u32,
}

impl WaitClock {
    pub fn waited(&mut self, now: std::time::Duration, waiting: bool, asking: bool, progress: u32) -> std::time::Duration {
        if !waiting {
            (self.since, self.progress) = (None, progress);
            return std::time::Duration::ZERO;
        }
        if asking || progress != self.progress || self.since.is_none() {
            (self.since, self.progress) = (Some(now), progress);
        }
        now - self.since.unwrap_or(now)
    }
}

/// The window's question state once a closing flow ended with `go`: a cancelled or aborted request is `Idle` again.
pub fn prompt_after(go: bool, prompt: Prompt) -> Prompt {
    if go { prompt } else { Prompt::Idle }
}

/// What a closing flow does next, from the state of every tab it covers and how long it has waited for a save.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Next {
    /// Nothing left to keep: run the close.
    Finish,
    /// A save is running: look again shortly.
    Sleep,
    /// Unsaved tabs: ask.
    Ask,
    /// A save outlasted the limit: cancel the close request only (the save and the tabs stay as they are).
    Abort,
}

pub fn next(states: &[CloseState], waited: std::time::Duration) -> Next {
    if states.contains(&CloseState::Wait) {
        return if waited >= metrics::timing::CLOSE_SAVE_WAIT_LIMIT { Next::Abort } else { Next::Sleep };
    }
    if states.contains(&CloseState::Ask) { Next::Ask } else { Next::Finish }
}

/// Runs a closing flow (P3-3-R1): look at the tabs, wait for running saves, ask, save, and look again until nothing
/// is left to keep; then `then` runs in the same turn as the last look, so no edit can slip in between. `false`: the
/// user cancelled, a save did not finish, or a running save took longer than the limit (R2; only this close request
/// is cancelled and the user is told), and everything stays open.
async fn resolve(then: Then, this: &WeakEntity<super::Workbench>, cx: &mut AsyncWindowContext) -> bool {
    let start = std::time::Instant::now();
    let batch = Rc::new(Batch::default());
    let mut clock = WaitClock::default();
    loop {
        let seen = this.update_in(cx, |this, window, cx| {
            let open = this.open_tabs(&then, cx);
            let mut states = open_states(&open);
            // Saves started by the close question count as running even between two of their tabs.
            if batch.running.get() {
                states.push(CloseState::Wait);
            }
            let waited = clock.waited(start.elapsed(), states.contains(&CloseState::Wait), batch.asking.get(), batch.progress.get());
            let cancelled = batch.cancelled.get();
            let next = if cancelled { Next::Abort } else { next(&states, waited) };
            match next {
                Next::Finish => then.run(this, window, cx),
                // A cancelled save already told the user why; only a timeout needs a notice.
                Next::Abort if !cancelled => {
                    use gpui_kit::component::WindowExt as _;
                    window.push_notification(SharedString::from("Close cancelled: a save is still running."), cx);
                }
                Next::Abort | Next::Sleep | Next::Ask => {}
            }
            (next, open)
        });
        let Ok((next, open)) = seen else { return false };
        match next {
            Next::Finish => return true,
            Next::Abort => return false,
            Next::Sleep => {
                cx.background_executor().timer(SAVE_WAIT).await;
                continue;
            }
            Next::Ask => {}
        }
        let items: Vec<&Dirty> = open.iter().map(|o| &o.item).collect();
        match settle(&items, this, &batch, cx).await {
            Settled::Cancel => return false,
            Settled::Discard => {
                let _ = this.update_in(cx, |this, window, cx| then.run(this, window, cx));
                return true;
            }
            Settled::Saved => {}
        }
    }
}

fn open_states(open: &[Open]) -> Vec<CloseState> {
    open.iter().map(|o| if o.waiting { CloseState::Wait } else { CloseState::Ask }).collect()
}

/// Removes the view of `path` in pane `pane` (no question); the file goes with its last view.
pub fn remove_tab(ws: &mut FolderWorkspace, pane: PaneId, path: &Path, markdown: bool, cx: &mut Context<FolderWorkspace>) {
    if let Some(ix) = ws.group.panes.get(&pane).and_then(|p| if markdown { p.find_preview(path) } else { p.find(path) }) {
        ws.group.close_view(pane, ix);
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
        let Some((pane, ix)) = self.active_ws().and_then(|ws| {
            let g = &ws.read(cx).group;
            g.active_pane().active.map(|ix| (g.active, ix))
        }) else {
            return;
        };
        self.close_tab_at(pane, ix, window, cx);
    }

    /// Closes tab `ix` of pane `pane` of the active folder; the last view of a file with a save running or unsaved
    /// state goes through `resolve`. Another view keeps the file, so closing this one asks nothing (P4-3). A pinned
    /// tab stays: Ctrl-W, Ctrl-F4, a middle click and the tab button all end here (I-066, I-735 `close_pinned = false`);
    /// closing the folder or the window does not use this path.
    pub(super) fn close_tab_at(&mut self, pane: PaneId, ix: usize, window: &mut Window, cx: &mut Context<Self>) {
        let Some(ws) = self.active_ws() else { return };
        let group = &ws.read(cx).group;
        let Some(p) = group.panes.get(&pane) else { return };
        if p.close_protected(ix) {
            return;
        }
        let Some((path, markdown)) = p.tabs.get(ix).map(|t| (t.path.clone(), t.markdown)) else { return };
        match group.close_state(&path) {
            CloseState::Gone => {}
            CloseState::Clean => self.drop_tab(&ws, pane, &path, markdown, window, cx),
            CloseState::Wait | CloseState::Ask => {
                if self.prompt != Prompt::Idle {
                    return;
                }
                self.prompt = Prompt::Asking;
                let then = Then::Drop(ws, pane, path, markdown);
                cx.spawn_in(window, async move |this, cx| {
                    let go = resolve(then, &this, cx).await;
                    let _ = this.update(cx, |this, _| {
                        this.prompt = prompt_after(go, this.prompt);
                    });
                })
                .detach();
            }
        }
    }

    /// Removes the tab and gives the keyboard back to the pane (the closed editor may have had it).
    pub(super) fn drop_tab(&mut self, ws: &Entity<FolderWorkspace>, pane: PaneId, path: &Path, markdown: bool, window: &mut Window, cx: &mut Context<Self>) {
        ws.update(cx, |ws, cx| remove_tab(ws, pane, path, markdown, cx));
        self.center_focus.focus(window, cx);
        cx.notify();
    }

    /// Removes every view of `path` (E-085 "Close": the file was given up).
    pub(super) fn drop_file(&mut self, ws: &Entity<FolderWorkspace>, path: &Path, window: &mut Window, cx: &mut Context<Self>) {
        ws.update(cx, |ws, cx| {
            ws.group.close_path(path);
            cx.notify();
        });
        self.center_focus.focus(window, cx);
        cx.notify();
    }

    /// The tabs `then` covers that still need attention now: unsaved or with a save running (`Pane::close_state`).
    /// Names are workspace-relative, prefixed with the folder name when several folders are open.
    fn open_tabs(&self, then: &Then, cx: &App) -> Vec<Open> {
        let several = self.folders.workspaces.len() > 1;
        let mut out = Vec::new();
        let mut look = |ws: &Entity<FolderWorkspace>, path: &Path| {
            let w = ws.read(cx);
            let waiting = match w.group.docs.close_state(path) {
                CloseState::Gone | CloseState::Clean => return,
                CloseState::Wait => true,
                CloseState::Ask => false,
            };
            let rel = w.tree.rel(path);
            let name = if several { format!("{}\\{rel}", w.tree.root_name) } else { rel };
            out.push(Open { item: Dirty { ws: ws.clone(), path: path.to_path_buf(), name }, waiting });
        };
        match then {
            Then::Drop(ws, _, path, _) => look(ws, path),
            Then::Exit(_) => {
                if let Some(ws) = &self.settings_workspace {
                    for path in ws.read(cx).group.paths() { look(ws, &path); }
                }
                for folder in &self.folders.state.folders {
                    let Some(ws) = self.folders.workspaces.get(&folder.id) else { continue };
                    let paths: Vec<PathBuf> = ws.read(cx).group.paths();
                    for path in paths {
                        look(ws, &path);
                    }
                }
            }
        }
        out
    }

    /// A window close or quit was requested. Returns `true` when it may go on now (nothing to keep, or the exit was
    /// already allowed); otherwise runs `resolve`, which finishes the exit itself when the answer allows it.
    pub(super) fn request_exit(&mut self, exit: Exit, window: &mut Window, cx: &mut Context<Self>) -> bool {
        match self.prompt {
            Prompt::Leaving => return true,
            Prompt::Asking => return false,
            Prompt::Idle => {}
        }
        let then = Then::Exit(exit);
        if self.open_tabs(&then, cx).is_empty() {
            return true;
        }
        self.prompt = Prompt::Asking;
        cx.spawn_in(window, async move |this, cx| {
            let go = resolve(then, &this, cx).await;
            let _ = this.update(cx, |this, _| {
                this.prompt = prompt_after(go, this.prompt);
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
    use super::{CloseAction, Disk, Guard, GuardAction, close_action, guard, guard_action, guard_choice, metrics, trim_front, unsaved_choice};

    fn read(hash: u64) -> Disk {
        Disk::Read { text: String::new(), hash, format: None, raw: hash }
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


    /// P3-3-R1 (review 3, H-18): the pre-save check is on raw bytes, like the watch. Same text with other bytes
    /// (re-encoded, other line ending) asks E-084; identical bytes go on.
    #[test]
    fn guard_sees_reencoded_file() {
        let same_text = |raw| Disk::Read { text: "A".into(), hash: 7, format: None, raw };
        assert_eq!(guard(&same_text(2), 1), Guard::Changed);
        assert_eq!(guard(&same_text(1), 1), Guard::Proceed);
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


    /// P3-3-R2: the wait limit decides Sleep vs Abort only while a save runs; without one the limit is irrelevant.
    #[test]
    fn wait_limit_aborts_only_a_running_save() {
        use super::{Next, next};
        use crate::ui::pane::CloseState::{Ask, Clean, Wait};
        let limit = metrics::timing::CLOSE_SAVE_WAIT_LIMIT;
        let just_under = limit - std::time::Duration::from_millis(1);
        assert_eq!(next(&[Ask, Wait], just_under), Next::Sleep);
        assert_eq!(next(&[Ask, Wait], limit), Next::Abort);
        assert_eq!(next(&[Ask], limit * 2), Next::Ask);
        assert_eq!(next(&[Clean], limit * 2), Next::Finish);
        assert_eq!(next(&[], limit), Next::Finish);
    }

    /// P3-3-R3: after "Save" a save that never ends is bounded like any running save. The user's answer time does not
    /// count, progress restarts the wait, and when the limit passes the request ends and the window is `Idle` again.
    #[test]
    fn stuck_save_after_save_choice_aborts_and_returns_idle() {
        use super::{Next, Prompt, WaitClock, next, prompt_after};
        use crate::ui::pane::CloseState::Wait;
        use std::time::Duration;
        let s = Duration::from_secs;
        let mut clock = WaitClock::default();
        // t=0: "Save" was chosen, the save task runs.
        assert_eq!(next(&[Wait], clock.waited(s(0), true, false, 0)), Next::Sleep);
        // t=5..35: an E-084 question is open; nothing counts however long the user thinks.
        assert_eq!(next(&[Wait], clock.waited(s(5), true, true, 0)), Next::Sleep);
        assert_eq!(next(&[Wait], clock.waited(s(35), true, true, 0)), Next::Sleep);
        // The answer came at t=35; the write then hangs: 9s later still waiting, at 10s the request is aborted.
        assert_eq!(next(&[Wait], clock.waited(s(44), true, false, 0)), Next::Sleep);
        assert_eq!(next(&[Wait], clock.waited(s(45), true, false, 0)), Next::Abort);
        assert_eq!(prompt_after(false, Prompt::Asking), Prompt::Idle);
        assert_eq!(prompt_after(true, Prompt::Leaving), Prompt::Leaving);
        // A tab finishing restarts the wait for the next one.
        let mut clock = WaitClock::default();
        clock.waited(s(0), true, false, 0);
        assert_eq!(clock.waited(s(9), true, false, 0), s(9));
        assert_eq!(clock.waited(s(12), true, false, 1), s(0));
        assert_eq!(next(&[Wait], clock.waited(s(21), true, false, 1)), Next::Sleep);
        // No running save: the clock resets.
        assert_eq!(clock.waited(s(30), false, false, 1), s(0));
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
}

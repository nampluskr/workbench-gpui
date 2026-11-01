//! 디스크 감시 (v0.2 Phase 5, SPEC R-24, G-115, D-6 `notify`, D-18, A-16.3; 리뷰 1회차 D-046).
//!
//! - 활성 폴더 하나만 감시한다(PLAN Phase 5 "활성 폴더와 열린 파일"). 루트는 하위까지(Recursive), 루트의 부모는
//!   그 아래 한 단계만(NonRecursive) 감시해 루트 자신이 지워지거나 이름이 바뀐 것을 바로 안다(A-16.3).
//! - 열린 탭 파일의 실제 경로가 루트 실제 트리 밖이면(다른 폴더로 옮긴 파일, 정션 안 파일) 그 부모를 따로 한 단계만
//!   감시한다(D-046 ④, `watch_io`). 정션 안의 트리 반영은 알려진 한계로 남긴다.
//! - 폴더를 바꾸거나 해제하거나 폴더가 사라지면 감시자를 버린다(감시 해제). 버린 감시자의 받는 쪽도 함께 버려서
//!   늦게 온 이벤트가 새 폴더에 섞이지 않는다. 루트 자신의 삭제·이름 바꾸기·감시 오류를 받거나 루트 폴더 정체(파일 번호)가
//!   달라지면, 경로가 같아도 감시를 새로 등록한다(D-046 ③).
//! - 이벤트는 `fsops::watch::Pending` 으로 묶어 한 번에 반영한다. 트리는 디스크를 다시 읽고(펼침·선택·스크롤 유지),
//!   열린 탭은 백그라운드에서 다시 읽어 내용이 달라졌을 때만 바꾼다(G-115·E-086, D-18, D-046 ⑤).
//! - 인라인 입력 중에는 묶음을 통째로(이름 바꾸기 짝 포함) 보관했다가 입력이 끝나면 차례대로 반영한다(D-046 ②).
//! - 앱 자신이 이미 반영한 이름 바꾸기 짝은 감시 묶음에서 다시 적용하지 않는다(D-046 ①). 그 밖의 앱 자신 이벤트는
//!   집계만 하고, 트리·탭은 디스크 내용으로 다시 확인할 뿐이라 결과가 같다.
//! - 등록 폴더 존재·루트 정체 확인은 1초마다 백그라운드에서 한다(D-046 ⑤, `watch_io`).

use std::cell::RefCell;
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::mpsc;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use gpui_kit::*;
use notify::Watcher as _;

use super::Workbench;
use super::keymap;
use crate::fsops::ident::{self, DirId};
use crate::fsops::watch::{self as fw, Batch, Change, Kind, Pending, SelfOps};
use crate::state::path;

/// 감시 확인 주기(판단).
const TICK: Duration = Duration::from_millis(100);
/// 등록 폴더 존재 확인은 이 틱마다(1초, 판단).
const EXIST_EVERY: u32 = 10;
/// 틱 간격이 이보다 길면 dev 출력에 남긴다.
const TICK_LATE: Duration = Duration::from_millis(250);

/// 감시 스레드가 받은 시각(Instant, Unix ms)을 함께 보낸다. 묶기는 받은 시각으로 잰다.
pub(super) enum Msg {
    Change(Change, Instant, u128),
    Lost(Instant, u128),
    /// 루트 밖 열린 파일 부모 감시의 오류(D-047 ⓒ).
    ExtraError(String),
}

/// 루트 밖 열린 파일의 부모 폴더 감시(D-046 ④).
pub(super) struct ExtraWatch {
    pub dirs: Vec<PathBuf>,
    /// 등록할 때 각 폴더의 정체. 1초 확인에서 달라지면(없어짐·새 폴더) 다시 등록한다(D-047 ⓒ).
    pub ids: Vec<Option<DirId>>,
    pub _watcher: notify::RecommendedWatcher,
}

/// 활성 폴더 하나의 감시자.
pub struct RootWatch {
    pub folder_id: String,
    pub root: PathBuf,
    pub parent_watched: bool,
    /// 감시를 등록할 때의 루트 폴더 정체(D-046 ③).
    pub root_id: Option<DirId>,
    pub(super) tx: mpsc::Sender<Msg>,
    rx: mpsc::Receiver<Msg>,
    _watcher: notify::RecommendedWatcher,
    /// 탭 경로 → 실제 경로(다를 때만). 이벤트가 실제 경로로 와도 그 탭을 찾는다(D-046 ④).
    pub(super) tab_real: HashMap<PathBuf, PathBuf>,
    pub(super) extra: Option<ExtraWatch>,
}

/// 백그라운드 일 하나의 상태: 도는 중인가, 도는 동안 다시 해 달라는 요청이 왔나(중복 작업 제한, D-046 ⑤).
#[derive(Default)]
pub(super) struct Job {
    pub running: bool,
    pub again: Option<String>,
}

#[derive(Default)]
pub struct WatchState {
    pub current: Option<RootWatch>,
    pending: Pending,
    /// 앱 자신의 파일 작업 경로(`log_fs` 가 남긴다. `&self` 에서 쓰므로 RefCell).
    pub self_ops: RefCell<SelfOps>,
    ticks: u32,
    /// 폭주 뒤 한 번 더 다시 읽을 때.
    settle_at: Option<Instant>,
    /// 인라인 입력 중이라 미룬 전체 다시 읽기(폭주 뒤·폴더 다시 생김).
    deferred: bool,
    /// 인라인 입력 중이라 미룬 묶음(이름 바꾸기 짝 포함, 받은 차례대로, D-046 ②).
    deferred_batches: Vec<ReadyBatch>,
    /// 루트 자신의 변경·감시 오류를 받아 감시를 새로 등록해야 한다(존재 확인 결과를 보고 한다, D-046 ③).
    pub(super) rewatch: bool,
    last_tick: Option<Instant>,
    pub(super) exist_job: Job,
    pub(super) reload_job: Job,
    /// 다시 읽을 탭: (폴더 Workspace, 탭 경로). 일이 도는 동안 모은다.
    pub(super) reload_queue: Vec<(Entity<super::folders::FolderWorkspace>, PathBuf)>,
    pub(super) real_job: Job,
    /// 마지막으로 실제 경로를 구한 탭 목록(폴더 id + 탭 경로).
    pub(super) real_sig: String,
    /// 부모 감시 등록에 실패했다: 이 때까지 기다렸다가 다시 시도한다(서명은 저장하지 않는다, D-047 ⓒ).
    pub(super) real_retry_at: Option<Instant>,
}

/// dev 출력용 지금 시각(Unix ms). 시험 스크립트가 바깥 변경 시각과 빼서 반영까지 걸린 시간을 잰다.
pub fn epoch_ms() -> u128 {
    SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_millis()).unwrap_or(0)
}

pub(super) fn kind_of(kind: &notify::EventKind) -> Kind {
    use notify::event::{ModifyKind, RenameMode};
    match kind {
        notify::EventKind::Create(_) => Kind::Create,
        notify::EventKind::Remove(_) => Kind::Remove,
        notify::EventKind::Modify(ModifyKind::Name(RenameMode::From)) => Kind::RenameFrom,
        notify::EventKind::Modify(ModifyKind::Name(RenameMode::To)) => Kind::RenameTo,
        notify::EventKind::Modify(_) => Kind::Modify,
        _ => Kind::Other,
    }
}

pub(super) fn same_path(a: &Path, b: &Path) -> bool {
    path::compare_key(&a.to_string_lossy()) == path::compare_key(&b.to_string_lossy())
}

/// 감시자를 만든다. 부모 폴더 감시에서 온 형제 항목 이벤트는 버린다(루트 자신만 남긴다).
fn start(folder_id: &str, root: &Path) -> Result<RootWatch, String> {
    let (tx, rx) = mpsc::channel::<Msg>();
    let filter_root = root.to_path_buf();
    let send = tx.clone();
    let mut watcher = notify::recommended_watcher(move |res: notify::Result<notify::Event>| match res {
        Ok(event) => {
            let (at, ms) = (Instant::now(), epoch_ms());
            if event.need_rescan() {
                let _ = send.send(Msg::Lost(at, ms));
            }
            let kind = kind_of(&event.kind);
            for p in event.paths {
                if p.starts_with(&filter_root) || same_path(&p, &filter_root) {
                    let _ = send.send(Msg::Change(Change { kind, path: p }, at, ms));
                }
            }
        }
        Err(_) => {
            let _ = send.send(Msg::Lost(Instant::now(), epoch_ms()));
        }
    })
    .map_err(|e| e.to_string())?;
    watcher
        .watch(root, notify::RecursiveMode::Recursive)
        .map_err(|e| e.to_string())?;
    let parent_watched = match root.parent() {
        Some(parent) => watcher.watch(parent, notify::RecursiveMode::NonRecursive).is_ok(),
        None => false,
    };
    Ok(RootWatch {
        folder_id: folder_id.to_string(),
        root: root.to_path_buf(),
        parent_watched,
        root_id: ident::dir_id(root),
        tx,
        rx,
        _watcher: watcher,
        tab_real: HashMap::new(),
        extra: None,
    })
}

impl Workbench {
    /// 활성 폴더(경로가 있을 때)만 감시하도록 맞춘다. 다르면 지금 감시자를 버리고 새로 만든다.
    pub(super) fn sync_watch(&mut self, via: &str, cx: &App) {
        self.sync_watch_inner(via, false, cx);
    }

    /// 경로가 같아도 감시를 새로 등록한다(루트가 같은 경로의 새 폴더로 바뀜, D-046 ③).
    pub(super) fn rewatch(&mut self, via: &str, cx: &App) {
        self.sync_watch_inner(via, true, cx);
    }

    fn sync_watch_inner(&mut self, via: &str, force: bool, cx: &App) {
        let want = self
            .folders
            .active_folder()
            .filter(|f| !self.folders.missing.contains(&f.id))
            .map(|f| (f.id.clone(), PathBuf::from(&f.path)));
        let same = match (&self.watch.current, &want) {
            (Some(w), Some((id, root))) => &w.folder_id == id && &w.root == root,
            (None, None) => true,
            _ => false,
        };
        if same && !force {
            return;
        }
        let dev = keymap::dev_enabled(cx);
        self.watch.rewatch = false;
        if let Some(old) = self.watch.current.take() {
            // 감시 해제: 감시자와 받는 쪽을 함께 버린다. 아직 반영하지 않은 이벤트·미룬 묶음도 버린다(새 감시는 다시 읽는다).
            self.watch.pending = Pending::default();
            self.watch.deferred = false;
            self.watch.deferred_batches.clear();
            self.watch.settle_at = None;
            self.watch.real_sig.clear();
            self.watch.real_retry_at = None;
            if dev {
                println!("[dev] watch-stop folder={} root={} via={via}", old.folder_id, old.root.display());
            }
        }
        if let Some((id, root)) = want {
            match start(&id, &root) {
                Ok(w) => {
                    if dev {
                        println!(
                            "[dev] watch-start folder={id} root={} parent_watched={} root_id={} via={via}",
                            root.display(),
                            w.parent_watched,
                            w.root_id.map(|(v, i)| format!("{v:08x}:{i:016x}")).unwrap_or_else(|| "none".into())
                        );
                    }
                    self.watch.current = Some(w);
                }
                Err(e) => {
                    // 감시를 못 하면 창 활성·폴더 활성 때 다시 읽기만 남는다(판단).
                    if dev {
                        println!("[dev] watch-start-failed folder={id} root={} error={e} via={via}", root.display());
                    }
                }
            }
        }
    }

    /// 감시 틱을 돈다. Workbench 가 사라지면 멈춘다.
    pub(super) fn start_watch_loop(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        cx.spawn_in(window, async move |this, cx| {
            loop {
                cx.background_executor().timer(TICK).await;
                if this.update_in(cx, |this, window, cx| this.watch_tick(window, cx)).is_err() {
                    break;
                }
            }
        })
        .detach();
    }

    fn watch_tick(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let now = Instant::now();
        // dev 출력: 틱이 늦었다(메인 스레드가 그리기 등으로 바빴다). 반영 시간을 나누어 보려고 남긴다.
        if let Some(prev) = self.watch.last_tick
            && now.duration_since(prev) > TICK_LATE
            && keymap::dev_enabled(cx)
        {
            println!("[dev] watch-tick-late gap_ms={} t_ms={}", now.duration_since(prev).as_millis(), epoch_ms());
        }
        self.watch.last_tick = Some(now);
        self.drain_events(cx);
        let editing = self.panel_editing(cx);
        // 입력이 끝났으면 미룬 묶음을 먼저, 받은 차례대로 반영한다. 그 뒤에 새 묶음(D-047 ⓑ).
        let deferred_applied = !editing && !self.watch.deferred_batches.is_empty();
        if deferred_applied {
            self.apply_deferred(window, cx);
        }
        if !self.watch.pending.is_empty()
            && self.watch.pending.ready(now)
            && let Some(batch) = self.watch.pending.take()
        {
            self.apply_batch(batch, window, cx);
        } else if self.watch.deferred && !editing && !deferred_applied {
            self.watch.deferred = false;
            self.watch_refresh_all("deferred", window, cx);
        }
        if self.watch.settle_at.is_some_and(|t| now >= t) {
            self.watch.settle_at = None;
            self.watch_refresh_all("settle", window, cx);
        }
        self.watch.ticks = self.watch.ticks.wrapping_add(1);
        if self.watch.ticks % EXIST_EVERY == 0 {
            self.request_exist("poll", window, cx);
        }
        // 활성 폴더가 바뀐 모든 경로를 한곳에서 맞춘다(폴더 전환·해제·사라짐·다시 생김).
        self.sync_watch("tick", cx);
        // 열린 탭이 바뀌었으면 실제 경로를 다시 구해 루트 밖 파일의 부모를 감시한다(D-046 ④).
        self.sync_tab_real(window, cx);
    }

    fn drain_events(&mut self, cx: &App) {
        let Some(w) = &self.watch.current else { return };
        let dev = keymap::dev_enabled(cx);
        let mut extra_error: Option<String> = None;
        while let Ok(msg) = w.rx.try_recv() {
            if let Msg::ExtraError(e) = msg {
                extra_error = Some(e);
                continue;
            }
            // 묶음의 첫 이벤트는 감시 스레드가 받은 시각을 dev 출력에 남긴다(반영 시간 나누어 보기).
            if dev && self.watch.pending.is_empty() {
                let (at_ms, what) = match &msg {
                    Msg::Change(c, _, ms) => (*ms, format!("kind={:?} path={}", c.kind, c.path.display())),
                    Msg::Lost(_, ms) => (*ms, "kind=lost".to_string()),
                    Msg::ExtraError(_) => continue,
                };
                println!("[dev] watch-recv {what} recv_t_ms={at_ms} t_ms={}", epoch_ms());
            }
            match msg {
                Msg::Change(c, at, _) => self.watch.pending.push(c, at),
                Msg::Lost(at, _) => self.watch.pending.push_lost(at),
                Msg::ExtraError(_) => {}
            }
        }
        // 루트 밖 열린 파일 부모 감시의 오류: 그 감시를 버리고 다음 틱에 다시 등록한다(D-047 ⓒ).
        if let Some(e) = extra_error {
            if dev {
                println!("[dev] watch-extra-error error={e} t_ms={}", epoch_ms());
            }
            self.invalidate_extra();
        }
    }

    /// 루트 밖 열린 파일 부모 감시를 버리고, 탭 실제 경로 서명을 지워 다음 틱에 다시 구하고 등록하게 한다(D-047 ⓒ).
    pub(super) fn invalidate_extra(&mut self) {
        if let Some(w) = self.watch.current.as_mut() {
            w.extra = None;
        }
        self.watch.real_sig.clear();
        self.watch.real_retry_at = None;
    }
}

/// 반영할 묶음과, 받을 때 이미 가려 둔 바깥 이름 바꾸기 짝(앱 자신이 반영한 짝은 뺐다, D-046 ①).
/// 미뤘다가 반영해도 가리기는 받은 때 기준이다(앱 작업 기억 시간이 지나도 앱 짝을 바깥으로 오인하지 않는다).
pub(super) struct ReadyBatch {
    batch: Batch,
    pairs: Vec<(PathBuf, PathBuf)>,
}

impl Workbench {
    /// 등록 폴더의 있음·없음이 바뀌었다(A-16.3). 사라졌으면 감시를 풀고 "경로 없음" 상태로, 다시 생겼으면 감시하고 다시 읽는다.
    pub(super) fn on_missing_changed(&mut self, via: &str, window: &mut Window, cx: &mut Context<Self>) {
        if keymap::dev_enabled(cx) {
            let mut ids: Vec<&String> = self.folders.missing.iter().collect();
            ids.sort();
            println!(
                "[dev] watch-missing via={via} missing={} t_ms={}",
                ids.iter().map(|s| s.as_str()).collect::<Vec<_>>().join(";"),
                epoch_ms()
            );
        }
        self.sync_watch(via, cx);
        self.log_folders(cx);
        if self.active_ws().is_some() {
            self.watch_refresh_all(via, window, cx);
        }
        cx.notify();
    }

    /// 활성 폴더 트리를 다시 읽고 모든 탭 내용을 다시 본다(폭주 뒤·미룬 것·폴더가 다시 생김·감시 다시 등록).
    pub(super) fn watch_refresh_all(&mut self, via: &str, window: &mut Window, cx: &mut Context<Self>) {
        let Some(ws) = self.active_ws() else { return };
        if ws.read(cx).tree.edit.is_some() {
            self.watch.deferred = true;
            return;
        }
        ws.update(cx, |ws, cx| ws.tree.refresh(cx));
        let queued = self.request_reload(&ws, |_| true, window, cx);
        if keymap::dev_enabled(cx) {
            println!("[dev] watch-refresh via={via} reload_queued={queued} t_ms={}", epoch_ms());
        }
        self.log_tree(cx);
        self.log_tabs(cx);
        cx.notify();
    }

    /// 묶음 하나를 받는다: 앱 자신의 이름 바꾸기 짝을 가리고, 루트 변경이면 존재·정체 확인을 부탁하고, 입력 중이면 미룬다.
    fn apply_batch(&mut self, batch: Batch, window: &mut Window, cx: &mut Context<Self>) {
        let now = Instant::now();
        let Some(root) = self.watch.current.as_ref().map(|w| w.root.clone()) else { return };
        let (own, external) = self.watch.self_ops.borrow().classify(&batch);
        let mut own_renames = 0;
        // 앱 자신의 짝인지는 감시 스레드가 받은 시각으로 판단한다. UI 반영이 늦어도 바뀌지 않는다(D-047 ⓐ).
        let pairs: Vec<(PathBuf, PathBuf)> = batch
            .renames_at()
            .into_iter()
            .filter(|(f, t, at)| {
                let mine = self.watch.self_ops.borrow_mut().take_rename(f, t, *at, now);
                own_renames += usize::from(mine);
                !mine
            })
            .map(|(f, t, _)| (f, t))
            .collect();
        if batch.root_replaced(&root) {
            self.watch.rewatch = true;
        }
        if batch.touches_root(&root) || self.watch.rewatch {
            self.request_exist(if self.watch.rewatch { "root-event" } else { "event" }, window, cx);
        }
        let (count, lost, first) = (batch.count, batch.lost, batch.first);
        let ready = ReadyBatch { batch, pairs };
        let editing = self.panel_editing(cx);
        let must_queue = !self.watch.deferred_batches.is_empty()
            || (editing && (ready.batch.touches_tree(&root) || !ready.pairs.is_empty()));
        let (tree, renames, queued) = if must_queue {
            // 인라인 입력 중: 묶음을 통째로 보관했다가 입력이 끝나면 차례대로 반영한다(D-046 ②). 이미 미룬 묶음이 있으면
            // 새 묶음도 같은 줄 뒤에 세워 받은 차례를 지킨다(D-047 ⓑ).
            let n = ready.pairs.len();
            self.watch.deferred_batches.push(ready);
            ("deferred", n, 0)
        } else {
            let r = self.apply_ready(&ready, &root, window, cx);
            if count > fw::FLOOD || lost {
                self.watch.settle_at = Some(now + fw::SETTLE);
            }
            r
        };
        if keymap::dev_enabled(cx) {
            println!(
                "[dev] watch-applied events={count} own={own} external={external} lost={lost} tree={tree} renames={renames} own_renames={own_renames} reloaded={queued} wait_ms={} t_ms={}",
                now.duration_since(first).as_millis(),
                epoch_ms()
            );
        }
        if tree == "refreshed" {
            self.log_tree(cx);
            self.log_tabs(cx);
            cx.notify();
        }
    }

    /// 입력이 끝났다: 미룬 묶음을 받은 차례대로 반영한다(이름 바꾸기 따라가기 → 트리 다시 읽기 → 탭 다시 읽기, D-046 ②).
    fn apply_deferred(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let Some(root) = self.watch.current.as_ref().map(|w| w.root.clone()) else {
            self.watch.deferred_batches.clear();
            return;
        };
        let batches = std::mem::take(&mut self.watch.deferred_batches);
        let mut renames = 0;
        let mut queued = 0;
        for ready in &batches {
            let (_, r, q) = self.apply_ready(ready, &root, window, cx);
            renames += r;
            queued += q;
        }
        if keymap::dev_enabled(cx) {
            println!(
                "[dev] watch-refresh via=deferred batches={} renames={renames} reload_queued={queued} t_ms={}",
                batches.len(),
                epoch_ms()
            );
        }
        self.log_tree(cx);
        self.log_tabs(cx);
        cx.notify();
    }

    /// 묶음 하나를 반영한다. 돌려주는 값: (트리, 따라간 이름 바꾸기 수, 다시 읽기로 넘긴 탭 수).
    fn apply_ready(&mut self, ready: &ReadyBatch, root: &Path, window: &mut Window, cx: &mut Context<Self>) -> (&'static str, usize, usize) {
        let Some(ws) = self.active_ws() else { return ("none", 0, 0) };
        let batch = &ready.batch;
        let mut tree = "none";
        if batch.touches_tree(root) || !ready.pairs.is_empty() {
            ws.update(cx, |ws, cx| {
                for (from, to) in &ready.pairs {
                    ws.tree.follow_rename(from, to);
                    ws.pane.rename_path(from, to);
                }
                ws.tree.refresh(cx);
            });
            tree = "refreshed";
        }
        // 탭 경로가 바뀌었으면 실제 경로 표도 옛것이다. 그래도 이 묶음은 바뀐 탭 경로로 찾는다.
        let real = self.watch.current.as_ref().map(|w| w.tab_real.clone()).unwrap_or_default();
        let queued = self.request_reload(
            &ws,
            |p| batch.names(p) || real.get(p).is_some_and(|r| batch.names(r)),
            window,
            cx,
        );
        (tree, ready.pairs.len(), queued)
    }
}

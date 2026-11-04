//! 감시 쪽 디스크 일을 백그라운드에서 한다 (v0.2 Phase 5 리뷰 1회차 ③④⑤, D-046).
//!
//! - 존재·정체 확인(`request_exist`): 등록 폴더마다 `is_dir`, 활성 루트의 폴더 정체(`ident::dir_id`). 결과는 폴더 목록이
//!   그대로일 때만 쓴다. 바뀌었으면 다시 확인한다.
//! - 탭 다시 읽기(`request_reload`): 파일 읽기·UTF-8 바꾸기·해시를 백그라운드에서 한다. 해시가 탭에 넣은 내용과 다를 때만
//!   글을 넘겨 UI 스레드에서 `set_value` 한다. 결과는 같은 탭(편집기 엔티티·경로)이 아직 있을 때만 쓴다.
//! - 탭 실제 경로(`sync_tab_real`): 열린 탭 목록이 바뀌면 실제 경로를 구해, 루트 실제 트리 밖이면 그 부모를 한 단계만 감시한다.
//! - 세 일 모두 하나씩만 돈다. 도는 동안 온 요청은 모았다가 끝난 뒤 한 번 더 돈다(중복 작업 제한).

use std::collections::HashSet;
use std::path::PathBuf;
use std::time::Instant;

use gpui_kit::*;
use notify::Watcher as _;

use super::Workbench;
use super::folders::FolderWorkspace;
use super::keymap;
use super::pane::{ReadOutcome, read_text, text_hash};
use crate::text_io::TextEncoding;
use super::watch::{ExtraWatch, Msg, epoch_ms, kind_of, same_path};
use crate::fsops::ident::{self, DirId};
use crate::fsops::ops;
use crate::fsops::watch::Change;

/// 탭 하나 다시 읽은 결과. Encoding is the detected one (`None`: undecodable, shown lossy and read-only, P3-2).
enum ReadResult {
    Same(Option<TextEncoding>),
    Changed(String, u64, Option<TextEncoding>),
    Unreadable,
}

struct ReloadItem {
    ws: Entity<FolderWorkspace>,
    /// Pane read token; shared with the first read so only the latest started read applies (P1-3-R1).
    token: u64,
    path: PathBuf,
    old_hash: u64,
}

impl Workbench {
    /// 등록 폴더 존재·루트 정체 확인을 백그라운드에서 한다.
    pub(super) fn request_exist(&mut self, via: &str, window: &mut Window, cx: &mut Context<Self>) {
        if self.watch.exist_job.running {
            self.watch.exist_job.again.get_or_insert_with(|| via.to_string());
            return;
        }
        self.watch.exist_job.running = true;
        let folders: Vec<(String, PathBuf)> =
            self.folders.state.folders.iter().map(|f| (f.id.clone(), PathBuf::from(&f.path))).collect();
        let root = self.watch.current.as_ref().map(|w| (w.folder_id.clone(), w.root.clone()));
        // 루트 밖 열린 파일 부모 감시의 폴더·등록 때 정체(D-047 ⓒ).
        let extra: Vec<(PathBuf, Option<DirId>)> = self
            .watch
            .current
            .as_ref()
            .and_then(|w| w.extra.as_ref())
            .map(|e| e.dirs.iter().cloned().zip(e.ids.iter().copied()).collect())
            .unwrap_or_default();
        let via = via.to_string();
        cx.spawn_in(window, async move |this, cx| {
            let (f2, r2, e2) = (folders.clone(), root.clone(), extra.clone());
            let (missing, root_id, extra_now) = cx
                .background_executor()
                .spawn(async move {
                    let extra_now: Vec<Option<DirId>> = e2.iter().map(|(d, _)| ident::dir_id(d)).collect();
                    let missing: HashSet<String> = f2
                        .iter()
                        .filter(|(_, p)| {
                            crate::dev::slow_io(p);
                            !p.is_dir()
                        })
                        .map(|(id, _)| id.clone())
                        .collect();
                    let root_id = r2.and_then(|(_, p)| ident::dir_id(&p));
                    (missing, root_id, extra_now)
                })
                .await;
            let _ = this.update_in(cx, |this, window, cx| {
                this.check_extra_ids(&via, &extra, &extra_now, cx);
                this.exist_done(&via, folders, root, missing, root_id, window, cx)
            });
        })
        .detach();
    }

    /// 루트 밖 열린 파일 부모 감시의 폴더가 없어졌거나 같은 경로의 새 폴더로 바뀌었으면(정체가 다름) 그 감시를 버리고
    /// 다음 틱에 다시 등록한다(D-047 ⓒ). 확인하는 동안 감시가 바뀌었으면 결과를 버린다.
    fn check_extra_ids(&mut self, via: &str, snap: &[(PathBuf, Option<DirId>)], now_ids: &[Option<DirId>], cx: &App) {
        if snap.is_empty() {
            return;
        }
        let same_watch = self
            .watch
            .current
            .as_ref()
            .and_then(|w| w.extra.as_ref())
            .is_some_and(|e| e.dirs.len() == snap.len() && e.dirs.iter().zip(snap).all(|(d, (s, id))| d == s && e.ids.contains(id)));
        if !same_watch {
            return;
        }
        let changed: Vec<String> = snap
            .iter()
            .zip(now_ids)
            .filter(|((_, old), new)| old != *new)
            .map(|((d, _), _)| d.display().to_string())
            .collect();
        if changed.is_empty() {
            return;
        }
        if keymap::dev_enabled(cx) {
            println!("[dev] watch-extra-invalid reason=identity dirs={} via={via} t_ms={}", changed.join(";"), epoch_ms());
        }
        self.invalidate_extra();
    }

    #[allow(clippy::too_many_arguments)]
    fn exist_done(
        &mut self,
        via: &str,
        folders: Vec<(String, PathBuf)>,
        root: Option<(String, PathBuf)>,
        missing: HashSet<String>,
        root_id: Option<DirId>,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        self.watch.exist_job.running = false;
        let now: Vec<(String, PathBuf)> =
            self.folders.state.folders.iter().map(|f| (f.id.clone(), PathBuf::from(&f.path))).collect();
        if now != folders {
            // 확인하는 동안 목록이 바뀌었다: 결과를 버리고 다시 확인한다.
            self.watch.exist_job.again.get_or_insert_with(|| via.to_string());
        } else {
            if missing != self.folders.missing {
                self.folders.missing = missing;
                self.on_missing_changed(via, window, cx);
            }
            // 같은 감시자를 아직 쓰고 있을 때만 정체를 비교한다.
            let same_watch = matches!((&self.watch.current, &root), (Some(w), Some((fid, rp))) if &w.folder_id == fid && &w.root == rp);
            if same_watch && root_id.is_some() {
                let old = self.watch.current.as_ref().and_then(|w| w.root_id);
                let changed = old.is_some() && old != root_id;
                if changed || self.watch.rewatch {
                    if keymap::dev_enabled(cx) {
                        let f = |v: Option<DirId>| v.map(|(a, b)| format!("{a:08x}:{b:016x}")).unwrap_or_else(|| "none".into());
                        println!(
                            "[dev] watch-rewatch reason={} root_event={} old_id={} new_id={} via={via} t_ms={}",
                            if changed { "identity" } else { "root-event" },
                            self.watch.rewatch,
                            f(old),
                            f(root_id),
                            epoch_ms()
                        );
                    }
                    self.rewatch(if changed { "identity" } else { "root-event" }, cx);
                    self.watch_refresh_all("rewatch", window, cx);
                }
            } else if !same_watch {
                self.watch.rewatch = false;
            }
        }
        if let Some(v) = self.watch.exist_job.again.take() {
            self.request_exist(&v, window, cx);
        }
    }
}

impl Workbench {
    /// 고른 탭을 다시 읽기에 넘긴다. 돌려주는 값: 넘긴 탭 수.
    pub(super) fn request_reload(
        &mut self,
        ws: &Entity<FolderWorkspace>,
        pick: impl Fn(&std::path::Path) -> bool,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) -> usize {
        let paths: Vec<PathBuf> = ws.read(cx).pane.tabs.iter().filter(|t| pick(&t.path)).map(|t| t.path.clone()).collect();
        let n = paths.len();
        for p in paths {
            if !self.watch.reload_queue.iter().any(|(w, q)| w.entity_id() == ws.entity_id() && *q == p) {
                self.watch.reload_queue.push((ws.clone(), p));
            }
        }
        if n > 0 {
            self.run_reload(window, cx);
        }
        n
    }

    fn run_reload(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        if self.watch.reload_job.running {
            self.watch.reload_job.again = Some("queued".into());
            return;
        }
        let queue = std::mem::take(&mut self.watch.reload_queue);
        let items: Vec<ReloadItem> = queue
            .into_iter()
            .filter_map(|(ws, path)| {
                let (token, old_hash) = ws.update(cx, |ws, _| {
                    let ix = ws.pane.find(&path)?;
                    Some((ws.pane.start_read(ix), ws.pane.tabs[ix].hash))
                })?;
                Some(ReloadItem { token, old_hash, path, ws })
            })
            .collect();
        if items.is_empty() {
            return;
        }
        self.watch.reload_job.running = true;
        let jobs: Vec<(PathBuf, u64)> = items.iter().map(|i| (i.path.clone(), i.old_hash)).collect();
        cx.spawn_in(window, async move |this, cx| {
            let results: Vec<ReadResult> = cx
                .background_executor()
                .spawn(async move {
                    jobs.into_iter()
                        .map(|(p, old)| {
                            crate::dev::slow_io(&p);
                            // Same decoding as the first read, so a reload never turns UTF-16/CP949 into lossy UTF-8.
                            match read_text(&p) {
                                Some((text, encoding)) => {
                                    let h = text_hash(&text);
                                    if h == old { ReadResult::Same(encoding) } else { ReadResult::Changed(text, h, encoding) }
                                }
                                None => ReadResult::Unreadable,
                            }
                        })
                        .collect()
                })
                .await;
            let _ = this.update_in(cx, |this, window, cx| this.reload_done(items, results, window, cx));
        })
        .detach();
    }

    fn reload_done(&mut self, items: Vec<ReloadItem>, results: Vec<ReadResult>, window: &mut Window, cx: &mut Context<Self>) {
        self.watch.reload_job.running = false;
        let dev = keymap::dev_enabled(cx);
        for (item, result) in items.into_iter().zip(results) {
            let folder_id = item.ws.read(cx).folder_id.clone();
            // Apply only if this is still the tab's latest read and the folder is not removed.
            // Dirty tabs keep their buffer (P3-1).
            let outcome = match &result {
                ReadResult::Same(e) => ReadOutcome::Same(*e),
                ReadResult::Changed(_, h, e) => ReadOutcome::Changed(*h, *e),
                ReadResult::Unreadable => ReadOutcome::Unreadable,
            };
            let editor = item.ws.update(cx, |ws, _| ws.pane.finish_read(item.token, outcome).cloned());
            let Some(editor) = editor else { continue };
            match result {
                ReadResult::Same(_) => {}
                ReadResult::Unreadable => {
                    if dev {
                        println!("[dev] tab-reload folder={folder_id} path={} result=unreadable", item.path.display());
                    }
                }
                ReadResult::Changed(text, h, _) => {
                    editor.update(cx, |e, cx| e.set_value(text.as_str(), window, cx));
                    if dev {
                        println!(
                            "[dev] tab-reload folder={folder_id} path={} result=reloaded len={} fnv={h:016x} t_ms={}",
                            item.path.display(),
                            text.len(),
                            epoch_ms()
                        );
                    }
                }
            }
        }
        if self.watch.reload_job.again.take().is_some() || !self.watch.reload_queue.is_empty() {
            self.run_reload(window, cx);
        }
    }
}

impl Workbench {
    /// 열린 탭 목록이 바뀌었으면 실제 경로를 백그라운드에서 다시 구한다(D-046 ④). 부모 감시 등록에 실패했으면 서명을 저장하지
    /// 않았으므로 기다릴 시간이 지나면 다시 시도한다(D-047 ⓒ).
    pub(super) fn sync_tab_real(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let Some(w) = &self.watch.current else { return };
        let Some(ws) = self.active_ws() else { return };
        let tabs: Vec<PathBuf> = ws.read(cx).pane.tabs.iter().map(|t| t.path.clone()).collect();
        let sig = tab_sig(&w.folder_id, &w.root, &tabs);
        if sig == self.watch.real_sig || self.watch.real_job.running {
            return;
        }
        if self.watch.real_retry_at.is_some_and(|t| Instant::now() < t) {
            return;
        }
        self.watch.real_job.running = true;
        let (fid, root) = (w.folder_id.clone(), w.root.clone());
        cx.spawn_in(window, async move |this, cx| {
            let (r2, t2) = (root.clone(), tabs.clone());
            let (root_real, reals) = cx
                .background_executor()
                .spawn(async move {
                    let root_real = ops::real_path(&r2).ok().map(|p| ident::plain(&p));
                    let reals: Vec<Option<PathBuf>> =
                        t2.iter().map(|t| ops::real_path(t).ok().map(|p| ident::plain(&p))).collect();
                    (root_real, reals)
                })
                .await;
            let _ = this.update_in(cx, |this, window, cx| {
                this.real_done(sig, fid, root, tabs, root_real, reals, window, cx)
            });
        })
        .detach();
    }

    #[allow(clippy::too_many_arguments)]
    fn real_done(
        &mut self,
        sig: String,
        fid: String,
        root: PathBuf,
        tabs: Vec<PathBuf>,
        root_real: Option<PathBuf>,
        reals: Vec<Option<PathBuf>>,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        self.watch.real_job.running = false;
        let dev = keymap::dev_enabled(cx);
        let Some(w) = self.watch.current.as_mut() else { return };
        if w.folder_id != fid || w.root != root {
            return;
        }
        let mut tab_real = std::collections::HashMap::new();
        let mut dirs: Vec<PathBuf> = Vec::new();
        for (tab, real) in tabs.iter().zip(reals) {
            let Some(real) = real else { continue };
            if !same_path(&real, tab) {
                tab_real.insert(tab.clone(), real.clone());
            }
            let outside = root_real.as_ref().is_some_and(|rr| !ident::starts_with_ci(&real, rr));
            if outside
                && let Some(parent) = real.parent()
                && !dirs.iter().any(|d| same_path(d, parent))
            {
                dirs.push(parent.to_path_buf());
            }
        }
        dirs.sort();
        w.tab_real = tab_real;
        let old: Vec<PathBuf> = w.extra.as_ref().map(|e| e.dirs.clone()).unwrap_or_default();
        // 폴더가 바뀌었거나, 감시를 잃었는데(실패·오류·정체 변경) 감시할 폴더가 있으면 다시 등록한다.
        let need = old != dirs || (w.extra.is_none() && !dirs.is_empty());
        let mut registered = false;
        if need {
            w.extra = None;
            let mut failed = None;
            if !dirs.is_empty() {
                match extra_watch(&dirs, w.tx.clone()) {
                    Ok(e) => {
                        w.extra = Some(e);
                        registered = true;
                    }
                    Err(e) => failed = Some(e),
                }
            }
            if dev {
                let list = dirs.iter().map(|d| d.display().to_string()).collect::<Vec<_>>().join(";");
                if let Some(e) = &failed {
                    println!("[dev] watch-extra-failed dirs={list} error={e} retry_ms={} t_ms={}", super::metrics::timing::EXTRA_RETRY.as_millis(), epoch_ms());
                }
                println!("[dev] watch-extra folder={fid} dirs={list} active={} t_ms={}", w.extra.is_some(), epoch_ms());
            }
            if failed.is_some() {
                // 성공 서명을 저장하지 않는다. 잠시 뒤 다시 시도한다(D-047 ⓒ).
                self.watch.real_retry_at = Some(Instant::now() + super::metrics::timing::EXTRA_RETRY);
                return;
            }
        }
        self.watch.real_sig = sig;
        self.watch.real_retry_at = None;
        // 새로 감시를 걸었으면 그동안 놓쳤을 수 있는 변경을 탭이 다시 읽는다.
        if registered && let Some(ws) = self.active_ws() {
            self.request_reload(&ws, |_| true, window, cx);
        }
    }
}

fn tab_sig(fid: &str, root: &std::path::Path, tabs: &[PathBuf]) -> String {
    let mut s = format!("{fid}|{}", root.display());
    for t in tabs {
        s.push('|');
        s.push_str(&t.to_string_lossy());
    }
    s
}

/// 루트 밖 열린 파일의 부모 폴더들을 한 단계만 감시한다. 그 폴더 바로 아래 항목 이벤트만 같은 받는 쪽으로 보낸다.
/// 감시 오류는 받는 쪽에 알려 그 감시를 버리고 다시 등록하게 한다(D-047 ⓒ).
fn extra_watch(dirs: &[PathBuf], tx: std::sync::mpsc::Sender<Msg>) -> Result<ExtraWatch, String> {
    let filter = dirs.to_vec();
    let mut watcher = notify::recommended_watcher(move |res: notify::Result<notify::Event>| match res {
        Ok(event) => {
            let (at, ms) = (Instant::now(), epoch_ms());
            let kind = kind_of(&event.kind);
            for p in event.paths {
                if p.parent().is_some_and(|pp| filter.iter().any(|d| same_path(d, pp))) {
                    let _ = tx.send(Msg::Change(Change { kind, path: p }, at, ms));
                }
            }
        }
        Err(e) => {
            let _ = tx.send(Msg::ExtraError(e.to_string()));
        }
    })
    .map_err(|e| e.to_string())?;
    for d in dirs {
        watcher.watch(d, notify::RecursiveMode::NonRecursive).map_err(|e| e.to_string())?;
    }
    let ids = dirs.iter().map(|d| ident::dir_id(d)).collect();
    Ok(ExtraWatch { dirs: dirs.to_vec(), ids, _watcher: watcher })
}

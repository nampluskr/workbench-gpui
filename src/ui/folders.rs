//! 사이드바 폴더 등록·선택·해제 (v0.2 Phase 3, SPEC R-10~R-16·R-28, DECISIONS D-6·D-7·D-10·D-035).
//!
//! - 등록(A-13.1): OS 폴더 선택 창(rfd, D-6) 또는 `--dev-pick-folder <파일>`(D-035) → 앱이 직접 검사(A-16.4)
//!   → 이미 있으면 그 항목 활성화(A-13.2·A-16.6), 없으면 맨 아래에 붙이고 활성화.
//! - 활성화(A-13.3): 폴더마다 Workspace 엔티티 하나(D-7, G-002). 처음 활성화할 때 만들고 해제할 때까지 남긴다(A-15.2).
//!   트리·탭은 Phase 4(D-035 ①). 지금은 프로젝트 패널에 루트 한 줄만 그린다.
//! - 해제(A-13.4·A-13.5): 목록에서만 뺀다. 디스크는 건드리지 않는다. 활성이면 아래, 없으면 위 항목을 활성화.
//! - 순서(A-13.6): 우클릭 Move Up·Move Down.
//! - 저장(R-28, A-24.2·A-24.3): 바뀌면 500ms 묶어 쓰고, 종료 직전에 한 번 더 쓴다.

use std::collections::{HashMap, HashSet};
use std::path::PathBuf;

use gpui_kit::component::{ActiveTheme as _, Icon, IconName, h_flex, v_flex};
use gpui_kit::prelude::FluentBuilder as _;
use gpui_kit::*;

use super::Workbench;
use super::context_menu::{CmEntry, ContextMenu, ContextMenuEvent};
use super::keymap;
use crate::state::{self, Folder, path};

/// A-16.4 등록 실패 알림(원문 문구).
pub const ERR_OPEN: &str = "Cannot open this folder.";
/// L-88 타이틀 바 폴더 이름 최대 글자 수.
const TITLE_MAX_CHARS: usize = 40;

/// 폴더 하나의 작업 문맥(D-7 Workspace 엔티티): 트리(펼침·선택·스크롤, A-15.2)와 탭(A-15.1).
/// 등록을 해제하면 엔티티째 버리므로 그 폴더의 탭도 닫힌다(R-13, A-14.5 "열었던 탭은 복구되지 않는다").
/// 그리기는 Workbench 가 한다(`panel_view`): 행 처리기가 Workbench 의 포커스·탭·알림을 함께 다룬다.
pub struct FolderWorkspace {
    pub folder_id: String,
    pub tree: super::project_panel::ProjectTree,
    pub pane: super::pane::Pane,
}

impl FolderWorkspace {
    pub fn new(folder: &Folder, cx: &mut App) -> Self {
        let root_name = path::folder_name(&folder.path);
        Self {
            folder_id: folder.id.clone(),
            tree: super::project_panel::ProjectTree::new(PathBuf::from(&folder.path), root_name, cx),
            pane: super::pane::Pane::default(),
        }
    }
}

/// 우클릭 메뉴가 가리키는 폴더와 그 메뉴.
pub struct OpenContextMenu {
    pub menu: Entity<ContextMenu>,
    pub folder_id: String,
    /// 메뉴 항목 번호 → 할 일.
    pub commands: Vec<Option<FolderCommand>>,
    _sub: Subscription,
}

#[derive(Clone, Copy, Debug)]
pub enum FolderCommand {
    MoveUp,
    MoveDown,
    Remove,
}

/// 사이드바 폴더 상태.
pub struct FolderList {
    pub state: state::State,
    /// `%APPDATA%\workbench-gpui`. 얻지 못하면 저장하지 않는다.
    pub dir: Option<PathBuf>,
    /// 경로가 없거나 폴더가 아닌 항목의 id(A-12.7). 시작·활성화·창 활성 때 다시 본다.
    pub missing: HashSet<String>,
    /// 키보드 커서(A-17.3). 활성 폴더와 따로다(D-035).
    pub cursor: Option<usize>,
    /// 폴더 id → Workspace 엔티티(G-002).
    pub workspaces: HashMap<String, Entity<FolderWorkspace>>,
    /// 묶어 쓰기 세대. `saved_generation` 과 다르면 아직 쓰지 않은 변경이 있다.
    pub save_generation: u64,
    pub saved_generation: u64,
    /// `--dev-pick-folder` 파일.
    pub pick_file: Option<String>,
    /// 선택 창이 열려 있다(겹쳐 열지 않는다).
    pub picking: bool,
    pub context_menu: Option<OpenContextMenu>,
    /// 목록 스크롤(A-16.7). dev 출력에서 위치를 낸다.
    pub scroll: ScrollHandle,
    pub last_scroll_y: f32,
}

pub fn state_dir() -> Option<PathBuf> {
    dirs::config_dir().map(|d| d.join(super::keymap::APP_DIR))
}

impl FolderList {
    pub fn load(pick_file: Option<String>) -> (Self, state::Loaded) {
        let dir = state_dir();
        let loaded = match &dir {
            Some(d) => state::load(d),
            None => state::Loaded {
                state: state::State::default(),
                source: "none",
                notice: None,
                bad_moved_to: None,
            },
        };
        let mut this = Self {
            state: loaded.state.clone(),
            dir,
            missing: HashSet::new(),
            cursor: None,
            workspaces: HashMap::new(),
            save_generation: 0,
            saved_generation: 0,
            pick_file,
            picking: false,
            context_menu: None,
            scroll: ScrollHandle::new(),
            last_scroll_y: 0.,
        };
        this.refresh_missing();
        (this, loaded)
    }

    /// 경로 확인(A-12.7, A-16.2). 디스크는 읽기만 한다.
    pub fn refresh_missing(&mut self) -> bool {
        let missing: HashSet<String> = self
            .state
            .folders
            .iter()
            .filter(|f| {
                crate::dev::slow_io(std::path::Path::new(&f.path));
                !std::path::Path::new(&f.path).is_dir()
            })
            .map(|f| f.id.clone())
            .collect();
        let changed = missing != self.missing;
        self.missing = missing;
        changed
    }

    /// 폴더 하나만 확인한다(활성화 때 그 폴더의 트리를 그리려고, Phase 5 리뷰 1회차 ⑤ D-046). 나머지는 감시 쪽이
    /// 백그라운드에서 확인한다.
    pub fn refresh_one(&mut self, id: &str) -> bool {
        let Some(f) = self.state.folders.iter().find(|f| f.id == id) else { return false };
        let p = std::path::Path::new(&f.path);
        crate::dev::slow_io(p);
        let gone = !p.is_dir();
        let was = self.missing.contains(id);
        if gone {
            self.missing.insert(id.to_string());
        } else {
            self.missing.remove(id);
        }
        gone != was
    }

    pub fn index_of(&self, id: &str) -> Option<usize> {
        self.state.folders.iter().position(|f| f.id == id)
    }

    pub fn active_index(&self) -> Option<usize> {
        self.state.active.as_deref().and_then(|id| self.index_of(id))
    }

    pub fn active_folder(&self) -> Option<&Folder> {
        self.active_index().map(|i| &self.state.folders[i])
    }

    /// 화면 이름: 폴더 이름, 같은 이름이 둘 이상이면 ` · 바로 위 폴더 이름`(A-12.6). 비교는 대소문자 무시.
    pub fn display_names(&self) -> Vec<String> {
        let names: Vec<String> = self.state.folders.iter().map(|f| path::folder_name(&f.path)).collect();
        let mut counts: HashMap<String, usize> = HashMap::new();
        for n in &names {
            *counts.entry(path::compare_key(n)).or_default() += 1;
        }
        names
            .iter()
            .zip(&self.state.folders)
            .map(|(n, f)| match path::parent_name(&f.path) {
                Some(parent) if counts[&path::compare_key(n)] > 1 => format!("{n} · {parent}"),
                _ => n.clone(),
            })
            .collect()
    }
}

/// L-88 타이틀 바 이름: 40자를 넘으면 40자 + `…`(판단: 말줄임표를 40자 뒤에 붙인다).
pub fn title_text(name: &str) -> String {
    if name.chars().count() > TITLE_MAX_CHARS {
        let cut: String = name.chars().take(TITLE_MAX_CHARS).collect();
        format!("{cut}…")
    } else {
        name.to_string()
    }
}

/// A-16.4 앱이 직접 하는 검사: 있고, 폴더이고, `read_dir` 이 된다. 디스크는 읽기만 한다.
pub fn validate(input: &str) -> Result<String, &'static str> {
    let normalized = path::normalize(input).ok_or("not-absolute")?;
    let p = std::path::Path::new(&normalized);
    let meta = std::fs::metadata(p).map_err(|_| "not-found")?;
    if !meta.is_dir() {
        return Err("not-dir");
    }
    std::fs::read_dir(p).map_err(|_| "read-dir-failed")?;
    Ok(normalized)
}

/// 알림(gpui-kit notification, D-14). dev 출력에도 낸다.
fn notify_text(text: &'static str, window: &mut Window, cx: &mut App) {
    use gpui_kit::component::WindowExt as _;
    window.push_notification(text, cx);
    if keymap::dev_enabled(cx) {
        println!("[dev] notification text={text}");
    }
}

impl Workbench {
    fn dev(&self, cx: &App) -> bool {
        keymap::dev_enabled(cx)
    }

    /// dev 출력: 목록 전체(바뀔 때마다).
    pub(super) fn log_folders(&self, cx: &App) {
        if !self.dev(cx) {
            return;
        }
        let f = &self.folders;
        let names = f.display_names();
        let active = f.active_index().map(|i| i.to_string()).unwrap_or_else(|| "none".into());
        let cursor = f.cursor.map(|i| i.to_string()).unwrap_or_else(|| "none".into());
        println!(
            "[dev] folders count={} active={active} cursor={cursor} workspaces={}",
            f.state.folders.len(),
            f.workspaces.len()
        );
        for (i, (folder, name)) in f.state.folders.iter().zip(names).enumerate() {
            println!(
                "[dev] folder-row index={i} id={} name={name} path={} missing={} active={}",
                folder.id,
                folder.path,
                f.missing.contains(&folder.id),
                f.state.active.as_deref() == Some(folder.id.as_str())
            );
        }
        println!("[dev] folders-end");
    }

    /// A-24.2: 500ms 묶어 쓰기.
    pub(super) fn schedule_save(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        self.folders.save_generation += 1;
        let generation = self.folders.save_generation;
        cx.spawn_in(window, async move |this, cx| {
            cx.background_executor().timer(super::metrics::FOLDERS_SAVE_DEBOUNCE).await;
            let _ = this.update_in(cx, |this, window, cx| {
                if this.folders.save_generation == generation {
                    this.save_now(Some(window), cx);
                }
            });
        })
        .detach();
    }

    /// 지금 쓴다. 창이 없으면(종료 직전) 실패 알림은 dev 출력만 낸다.
    pub(super) fn save_now(&mut self, window: Option<&mut Window>, cx: &mut App) {
        let Some(dir) = self.folders.dir.clone() else {
            return;
        };
        // 쓰기 직전 세대. 성공했을 때만 "저장됨"으로 둔다(리뷰 1회차 ②, D-037). 실패하면 A-24.4 재시도(state::save 안)·알림 뒤
        // 변경을 남겨 다음 저장·종료 직전 쓰기에서 다시 시도한다.
        let generation = self.folders.save_generation;
        let result = state::save(&dir, &self.folders.state);
        if result.is_ok() {
            self.folders.saved_generation = generation;
        }
        if keymap::dev_enabled(cx) {
            let text = match &result {
                Ok(state::Saved::Written) => "written".to_string(),
                Ok(state::Saved::SkippedReadOnly) => "skipped-read-only".to_string(),
                Err(e) => format!("failed error={e}"),
            };
            println!("[dev] state-save result={text}");
        }
        if result.is_err()
            && let Some(window) = window
        {
            notify_text(state::ERR_SAVE, window, cx);
        }
    }

    /// `workspace::Open`(A-13.1): 폴더 선택 창을 연다.
    pub(super) fn on_open_folder(
        &mut self,
        action: &keymap::workspace::Open,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        keymap::log_handled(action, self.focus_name(window, cx), cx);
        self.start_pick(window, cx);
    }

    pub(super) fn start_pick(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        if self.folders.picking {
            return;
        }
        if let Some(file) = self.folders.pick_file.clone() {
            // D-035: dev 주입. 파일 첫 줄이 고른 경로, 없거나 비었거나 `<cancel>` 이면 취소.
            let line = std::fs::read_to_string(&file)
                .ok()
                .and_then(|s| s.lines().next().map(|l| l.trim().trim_start_matches('\u{feff}').to_string()))
                .filter(|l| !l.is_empty() && l != "<cancel>");
            if self.dev(cx) {
                println!("[dev] pick-folder method=dev-file");
            }
            self.finish_pick(line, window, cx);
            return;
        }
        self.folders.picking = true;
        if self.dev(cx) {
            println!("[dev] pick-folder method=dialog opened");
        }
        let dialog = rfd::AsyncFileDialog::new().set_parent(&*window).pick_folder();
        cx.spawn_in(window, async move |this, cx| {
            let picked = dialog.await.map(|h| h.path().to_string_lossy().into_owned());
            let _ = this.update_in(cx, |this, window, cx| {
                this.folders.picking = false;
                this.finish_pick(picked, window, cx);
            });
        })
        .detach();
    }

    fn finish_pick(&mut self, picked: Option<String>, window: &mut Window, cx: &mut Context<Self>) {
        let Some(input) = picked else {
            // A-13.8 취소: 아무 일도 없다.
            if self.dev(cx) {
                println!("[dev] pick-folder result=cancel");
            }
            return;
        };
        if self.dev(cx) {
            println!("[dev] pick-folder result=picked path={input}");
        }
        self.add_folder(&input, window, cx);
    }

    /// 등록(A-13.1·A-13.2·A-16.4·A-16.6).
    pub(super) fn add_folder(&mut self, input: &str, window: &mut Window, cx: &mut Context<Self>) {
        let normalized = match validate(input) {
            Ok(n) => n,
            Err(reason) => {
                if self.dev(cx) {
                    println!("[dev] folder-add result=rejected reason={reason} input={input}");
                }
                notify_text(ERR_OPEN, window, cx);
                return;
            }
        };
        let key = path::compare_key(&normalized);
        if let Some(i) = self
            .folders
            .state
            .folders
            .iter()
            .position(|f| path::compare_key(&f.path) == key)
        {
            if self.dev(cx) {
                println!("[dev] folder-add result=existing index={i} path={normalized}");
            }
            self.activate_folder(i, window, cx);
            return;
        }
        let folder = Folder {
            id: state::win::new_uuid(),
            path: normalized.clone(),
            added_at: state::time::iso_now(),
        };
        self.folders.state.folders.push(folder);
        let index = self.folders.state.folders.len() - 1;
        if self.dev(cx) {
            println!("[dev] folder-add result=added index={index} path={normalized}");
        }
        self.activate_folder(index, window, cx);
    }
}

impl Workbench {
    /// 활성화(A-13.3). 포커스는 옮기지 않는다(A-15.6). Workspace 엔티티는 처음 활성화할 때 만든다.
    pub(super) fn activate_folder(&mut self, index: usize, window: &mut Window, cx: &mut Context<Self>) {
        let Some(folder) = self.folders.state.folders.get(index).cloned() else {
            return;
        };
        self.folders.state.active = Some(folder.id.clone());
        // 활성화한 폴더만 지금 확인하고, 나머지 등록 폴더는 백그라운드에서 확인한다(Phase 5 리뷰 1회차 ⑤ D-046).
        self.folders.refresh_one(&folder.id);
        self.request_exist("activate", window, cx);
        let created = !self.folders.workspaces.contains_key(&folder.id);
        let ws = match self.folders.workspaces.get(&folder.id) {
            Some(ws) => ws.clone(),
            None => {
                let ws = cx.new(|cx| FolderWorkspace::new(&folder, cx));
                self.folders.workspaces.insert(folder.id.clone(), ws.clone());
                ws
            }
        };
        // 다시 활성화하면 디스크를 다시 읽는다(펼침·선택·스크롤은 그대로, A-15.2). 활성이 아닌 동안은 감시하지 않으므로
        // 탭 내용도 다시 본다(Phase 5, R-24). 감시는 이 폴더로 옮긴다.
        self.sync_watch("activate", cx);
        if !created && !self.folders.missing.contains(&folder.id) {
            ws.update(cx, |ws, cx| ws.tree.refresh(cx));
            self.request_reload(&ws, |_| true, window, cx);
        }
        if self.dev(cx) {
            println!(
                "[dev] folder-activate index={index} id={} workspace={:?} created={created} folder_id={}",
                folder.id,
                ws.entity_id(),
                ws.read(cx).folder_id
            );
        }
        self.log_folders(cx);
        self.log_tree(cx);
        self.log_tabs(cx);
        self.schedule_save(window, cx);
        cx.notify();
    }

    /// 해제(A-13.4·A-13.5). 목록에서만 뺀다. 디스크는 건드리지 않는다(A-14.3).
    pub(super) fn remove_folder(&mut self, index: usize, via: &str, window: &mut Window, cx: &mut Context<Self>) {
        if index >= self.folders.state.folders.len() {
            return;
        }
        let was_active = self.folders.active_index() == Some(index);
        let removed = self.folders.state.folders.remove(index);
        // R-13: 엔티티째 버리므로 그 폴더의 탭도 닫힌다.
        if let Some(ws) = self.folders.workspaces.remove(&removed.id)
            && self.dev(cx)
        {
            println!("[dev] folder-tabs-closed id={} count={}", removed.id, ws.read(cx).pane.tabs.len());
        }
        self.folders.missing.remove(&removed.id);
        let len = self.folders.state.folders.len();
        if self.dev(cx) {
            println!("[dev] folder-remove index={index} id={} path={} via={via}", removed.id, removed.path);
        }
        // 커서는 같은 자리(아래 항목), 끝이면 위로.
        self.folders.cursor = self.folders.cursor.and_then(|c| {
            if len == 0 {
                None
            } else if c > index || c >= len {
                Some(c.saturating_sub(1).min(len - 1))
            } else {
                Some(c)
            }
        });
        if was_active {
            // A-13.5: 아래 항목, 없으면 위 항목, 하나도 없으면 빈 상태.
            if len == 0 {
                self.folders.state.active = None;
            } else {
                let next = if index < len { index } else { len - 1 };
                self.activate_folder(next, window, cx);
                return;
            }
        }
        // 감시 해제(Phase 5): 활성 폴더가 없어졌으면 감시자를 버린다.
        self.sync_watch("remove", cx);
        self.log_folders(cx);
        self.schedule_save(window, cx);
        cx.notify();
    }

    /// 순서 한 칸 바꾸기(A-13.6).
    pub(super) fn move_folder(&mut self, index: usize, up: bool, window: &mut Window, cx: &mut Context<Self>) {
        let len = self.folders.state.folders.len();
        let other = if up { index.checked_sub(1) } else { (index + 1 < len).then_some(index + 1) };
        let Some(other) = other else {
            return;
        };
        self.folders.state.folders.swap(index, other);
        if self.folders.cursor == Some(index) {
            self.folders.cursor = Some(other);
        } else if self.folders.cursor == Some(other) {
            self.folders.cursor = Some(index);
        }
        if self.dev(cx) {
            println!("[dev] folder-move from={index} to={other}");
        }
        self.log_folders(cx);
        self.schedule_save(window, cx);
        cx.notify();
    }

    /// 사이드바 항목 우클릭 메뉴(I-667, A-12.10). Move Up·Move Down 은 폴더가 둘 이상일 때만, 끝이면 비활성(I-934, I-940).
    pub(super) fn open_folder_menu(
        &mut self,
        index: usize,
        position: Point<Pixels>,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        let Some(folder) = self.folders.state.folders.get(index) else {
            return;
        };
        let folder_id = folder.id.clone();
        let len = self.folders.state.folders.len();
        let mut entries = Vec::new();
        let mut commands = Vec::new();
        if len >= 2 {
            entries.push(CmEntry::item("Move Up", index > 0));
            commands.push(Some(FolderCommand::MoveUp));
            entries.push(CmEntry::item("Move Down", index + 1 < len));
            commands.push(Some(FolderCommand::MoveDown));
            entries.push(CmEntry::Separator);
            commands.push(None);
        }
        entries.push(CmEntry::item("Remove", true));
        commands.push(Some(FolderCommand::Remove));
        if self.dev(cx) {
            println!("[dev] context-menu-target index={index} id={folder_id}");
        }
        let menu = cx.new(|cx| ContextMenu::new(entries, Vec::new(), position, window, cx));
        let sub = cx.subscribe_in(&menu, window, |this, menu, event: &ContextMenuEvent, window, cx| {
            let current = this.folders.context_menu.as_ref().is_some_and(|m| m.menu == *menu);
            if !current {
                return;
            }
            match event {
                ContextMenuEvent::Dismissed => {
                    // Chosen 은 Dismissed 뒤에 오므로 여기서 지우지 않고 다음 프레임에 지운다.
                    let menu = menu.clone();
                    cx.defer_in(window, move |this, _, cx| {
                        if this.folders.context_menu.as_ref().is_some_and(|m| m.menu == menu) {
                            this.folders.context_menu = None;
                            cx.notify();
                        }
                    });
                }
                ContextMenuEvent::Chosen(i) => {
                    let Some(open) = this.folders.context_menu.as_ref() else {
                        return;
                    };
                    let command = open.commands.get(*i).copied().flatten();
                    let id = open.folder_id.clone();
                    let Some(index) = this.folders.index_of(&id) else {
                        return;
                    };
                    match command {
                        Some(FolderCommand::MoveUp) => this.move_folder(index, true, window, cx),
                        Some(FolderCommand::MoveDown) => this.move_folder(index, false, window, cx),
                        Some(FolderCommand::Remove) => this.remove_folder(index, "context-menu", window, cx),
                        None => {}
                    }
                }
            }
        });
        self.folders.context_menu = Some(OpenContextMenu {
            menu,
            folder_id,
            commands,
            _sub: sub,
        });
        cx.notify();
    }
}

impl Workbench {
    /// A-17.3 Up/Down: 키보드 커서 이동. 처음에는 첫(Down)·끝(Up) 항목, 끝에서 반대편으로 순환한다
    /// (판단: `menu::SelectNext`·`SelectPrevious` 의 I-518 순환을 따른다).
    fn step_cursor(&mut self, forward: bool, cx: &mut Context<Self>) {
        let len = self.folders.state.folders.len();
        if len == 0 {
            return;
        }
        self.folders.cursor = Some(match self.folders.cursor {
            None if forward => 0,
            None => len - 1,
            Some(c) if forward => (c + 1) % len,
            Some(c) => (c + len - 1) % len,
        });
        self.log_folders(cx);
        cx.notify();
    }

    pub(super) fn on_sidebar_next(
        &mut self,
        action: &keymap::menu::SelectNext,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        keymap::log_handled(action, self.focus_name(window, cx), cx);
        self.step_cursor(true, cx);
    }

    pub(super) fn on_sidebar_previous(
        &mut self,
        action: &keymap::menu::SelectPrevious,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        keymap::log_handled(action, self.focus_name(window, cx), cx);
        self.step_cursor(false, cx);
    }

    /// A-17.4 Enter: 커서 항목을 활성화한다. 포커스는 사이드바에 그대로(A-15.6).
    pub(super) fn on_sidebar_confirm(
        &mut self,
        action: &keymap::menu::Confirm,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        keymap::log_handled(action, self.focus_name(window, cx), cx);
        if let Some(c) = self.folders.cursor {
            self.activate_folder(c, window, cx);
        }
    }

    /// A-17.5 Delete: 커서 항목을 해제한다(A-13.4 ②, D-035).
    pub(super) fn on_sidebar_remove(
        &mut self,
        action: &keymap::project_panel::RemoveFromProject,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        keymap::log_handled(action, self.focus_name(window, cx), cx);
        if let Some(c) = self.folders.cursor {
            self.remove_folder(c, "delete-key", window, cx);
        }
    }

    /// 사이드바를 열고 포커스한다. 이전 포커스를 기억한다(사이드바 자신·메뉴 포커스는 빼지 않는다: 돌아갈 자리).
    fn open_and_focus_sidebar(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        self.sidebar_open = true;
        if !self.sidebar_focus.is_focused(window) {
            self.sidebar_prev_focus = window.focused(cx);
        }
        self.sidebar_focus.focus(window, cx);
    }

    /// 사이드바에서 이전 포커스로 돌아간다. 없으면(또는 사라졌으면) 가운데 Pane.
    fn return_from_sidebar(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        // 돌아갈 자리가 지금도 화면에 있을 때만 돌아간다: 가운데 Pane(과 그 안), 열린 Dock 의 프로젝트 패널.
        // ☰ 메뉴처럼 이미 닫힌 자리의 포커스로 돌아가면 포커스가 사라지므로 그때는 가운데 Pane 으로 간다.
        let target = self.sidebar_prev_focus.take().filter(|prev| {
            *prev == self.center_focus
                || self.center_focus.contains(prev, window)
                || (*prev == self.panel_focus && self.dock_open)
        });
        match target {
            Some(prev) => prev.focus(window, cx),
            None => self.center_focus.focus(window, cx),
        }
    }

    /// `Ctrl+Alt+J`(A-17.1, I-100): 열기·닫기. 열 때 포커스, 닫을 때 사이드바에 포커스가 있었으면 이전 위치로.
    pub(super) fn on_toggle_sidebar(
        &mut self,
        action: &keymap::multi_workspace::ToggleWorkspaceSidebar,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        keymap::log_handled(action, self.focus_name(window, cx), cx);
        if self.sidebar_open {
            let had_focus = self.sidebar_focus.is_focused(window);
            self.sidebar_open = false;
            // R-16·A-17.1: 사이드바에 포커스가 있었으면 이전 위치로, 없으면 가운데 Pane 으로(리뷰 1회차 ⑥, D-037).
            if had_focus {
                self.return_from_sidebar(window, cx);
            } else {
                self.sidebar_prev_focus = None;
                self.center_focus.focus(window, cx);
            }
        } else {
            self.open_and_focus_sidebar(window, cx);
        }
        self.log_sidebar(window, cx);
        cx.notify();
    }

    /// `Ctrl+Alt+;`(A-17.2, I-099): 닫혀 있으면 열고 포커스, 열려 있고 포커스가 있으면 이전 포커스로(닫지 않는다).
    pub(super) fn on_focus_sidebar(
        &mut self,
        action: &keymap::multi_workspace::FocusWorkspaceSidebar,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        keymap::log_handled(action, self.focus_name(window, cx), cx);
        if self.sidebar_open && self.sidebar_focus.is_focused(window) {
            self.return_from_sidebar(window, cx);
        } else {
            self.open_and_focus_sidebar(window, cx);
        }
        self.log_sidebar(window, cx);
        cx.notify();
    }

    fn log_sidebar(&self, window: &Window, cx: &App) {
        if self.dev(cx) {
            println!(
                "[dev] sidebar open={} dock_open={} focus={}",
                self.sidebar_open,
                self.dock_open,
                self.focus_name(window, cx)
            );
        }
    }
}

const ROW_PROBES: [&str; 12] = [
    "folder-row-00", "folder-row-01", "folder-row-02", "folder-row-03",
    "folder-row-04", "folder-row-05", "folder-row-06", "folder-row-07",
    "folder-row-08", "folder-row-09", "folder-row-10", "folder-row-11",
];

impl Workbench {
    /// 사이드바 폴더 목록(A-12, L-34). 세로 스크롤(A-16.7). 툴팁은 없다(A-12.8).
    pub(super) fn render_folder_list(&mut self, window: &mut Window, cx: &mut Context<Self>) -> AnyElement {
        let theme = cx.theme();
        let fg = theme.foreground;
        let muted = theme.muted_foreground;
        let disabled = theme.muted_foreground.opacity(0.45);
        let active_bg = theme.list_active;
        let hover_bg = theme.secondary_hover;
        let press_bg = theme.secondary_active;
        let ring = theme.ring;
        let sidebar_focused = self.sidebar_focus.is_focused(window);
        let names = self.folders.display_names();
        let active = self.folders.active_index();
        let cursor = self.folders.cursor;
        let scroll_y = f32::from(self.folders.scroll.offset().y);
        if scroll_y != self.folders.last_scroll_y {
            self.folders.last_scroll_y = scroll_y;
            if self.dev(cx) {
                println!("[dev] sidebar-scroll offset_y={scroll_y}");
            }
        }
        let mut list = v_flex()
            .on_children_prepainted(super::layout_probe::probe(&ROW_PROBES))
            .w_full();
        for (i, (folder, name)) in self.folders.state.folders.iter().zip(names).enumerate() {
            let missing = self.folders.missing.contains(&folder.id);
            let is_active = active == Some(i);
            let focused = sidebar_focused && cursor == Some(i);
            // A-12.6: 같은 이름이면 ` · 위 폴더` 를 muted 로.
            let (base, suffix) = match name.split_once(" · ") {
                Some((b, s)) => (b.to_string(), Some(format!(" · {s}"))),
                None => (name.clone(), None),
            };
            let text_color = if missing { disabled } else if is_active { fg } else { muted };
            let icon_color = if missing { disabled } else { muted };
            list = list.child(
                h_flex()
                    .id(("folder-row", i))
                    .flex_shrink_0()
                    .w_full()
                    .h(super::metrics::SIDEBAR_ROW_HEIGHT)
                    .pl(super::metrics::SIDEBAR_ROW_PADDING_LEFT)
                    .pr(super::metrics::SIDEBAR_ROW_PADDING_RIGHT)
                    .gap(super::metrics::SIDEBAR_ROW_GAP)
                    .items_center()
                    .text_sm()
                    .border_1()
                    .border_color(if focused { ring } else { gpui_kit::transparent_black() })
                    .text_color(text_color)
                    .when(is_active, |r| r.bg(active_bg))
                    .hover(move |s| if missing { s.bg(hover_bg) } else { s.bg(hover_bg).text_color(fg) })
                    .active(move |s| s.bg(press_bg))
                    .on_click(cx.listener(move |this, _: &ClickEvent, window, cx| {
                        this.folders.cursor = Some(i);
                        this.sidebar_focus.focus(window, cx);
                        this.activate_folder(i, window, cx);
                    }))
                    .on_mouse_down(
                        MouseButton::Right,
                        cx.listener(move |this, e: &MouseDownEvent, window, cx| {
                            cx.stop_propagation();
                            this.open_folder_menu(i, e.position, window, cx);
                        }),
                    )
                    .child(
                        Icon::new(IconName::Folder)
                            .size(super::metrics::ICON_SMALL)
                            .text_color(icon_color),
                    )
                    .child(
                        h_flex()
                            .flex_1()
                            .min_w_0()
                            .overflow_hidden()
                            .whitespace_nowrap()
                            .child(div().min_w_0().overflow_hidden().text_ellipsis().child(base))
                            .when_some(suffix, |d, s| {
                                d.child(div().flex_shrink_0().text_color(muted).child(s))
                            }),
                    ),
            );
        }
        // 스크롤 상자 안에 줄 묶음을 둔다(줄 경계 탐침은 스크롤 상자가 아닌 안쪽 묶음에 단다).
        div()
            .id("sidebar-folder-list")
            .track_scroll(&self.folders.scroll)
            .size_full()
            .overflow_y_scroll()
            .child(list)
            .into_any_element()
    }
}

impl Workbench {
    /// 프로젝트 패널 내용: 빈 상태(A-16.1), 경로 없음(A-16.2), 활성 폴더의 Workspace(루트 한 줄).
    pub(super) fn render_project_panel(&mut self, window: &mut Window, cx: &mut Context<Self>) -> AnyElement {
        let theme = cx.theme();
        let muted = theme.muted_foreground;
        let border = theme.border;
        let hover_bg = theme.secondary_hover;
        let button = |id: &'static str, label: &'static str| {
            div()
                .id(id)
                .px(super::metrics::EMPTY_BUTTON_PAD_X)
                .py(super::metrics::EMPTY_BUTTON_PAD_Y)
                .rounded(super::metrics::EMPTY_BUTTON_RADIUS)
                .border_1()
                .border_color(border)
                .text_sm()
                .hover(move |s| s.bg(hover_bg))
                .child(label)
        };
        let Some(index) = self.folders.active_index() else {
            return v_flex()
                .on_children_prepainted(super::layout_probe::probe(&["project-empty-text", "project-empty-open"]))
                .size_full()
                .p(super::metrics::EMPTY_BODY_PADDING)
                .gap(super::metrics::EMPTY_BODY_GAP)
                .text_sm()
                .text_color(muted)
                .child(div().child("Choose one of the options below to use the Project Panel"))
                .child(button("project-open-project", "Open Project").on_click(cx.listener(
                    |this, _: &ClickEvent, window, cx| {
                        if this.dev(cx) {
                            println!("[dev] button-click name=open-project");
                        }
                        this.start_pick(window, cx);
                    },
                )))
                .into_any_element();
        };
        let id = self.folders.state.folders[index].id.clone();
        if self.folders.missing.contains(&id) {
            return v_flex()
                .on_children_prepainted(super::layout_probe::probe(&["project-missing-text", "project-missing-remove"]))
                .size_full()
                .p(super::metrics::EMPTY_BODY_PADDING)
                .gap(super::metrics::EMPTY_BODY_GAP)
                .text_sm()
                .text_color(muted)
                .child(div().child("This folder no longer exists."))
                .child(button("project-missing-remove", "Remove").on_click(cx.listener(
                    move |this, _: &ClickEvent, window, cx| {
                        if let Some(i) = this.folders.index_of(&id) {
                            this.remove_folder(i, "missing-remove-button", window, cx);
                        }
                    },
                )))
                .into_any_element();
        }
        match self.folders.workspaces.get(&id) {
            Some(ws) => {
                let ws = ws.clone();
                self.render_tree(&ws, window, cx)
            }
            None => div().size_full().into_any_element(),
        }
    }

    /// 타이틀 바 폴더 이름(A-13.9, L-88). 폴더가 없으면 None(`Open Recent Project`).
    pub(super) fn title_folder_name(&self) -> Option<String> {
        self.folders
            .active_folder()
            .map(|f| title_text(&path::folder_name(&f.path)))
    }

    /// 창이 다시 활성화되면 경로·트리·탭을 다시 본다. 감시(R-24, Phase 5)가 있어도 감시를 못 만든 경우의 대비로 남긴다.
    pub(super) fn refresh_on_activation(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        // 등록 폴더 존재는 백그라운드에서 확인한다(Phase 5 리뷰 1회차 ⑤ D-046). 바뀌면 감시 쪽이 반영한다.
        self.request_exist("window-activation", window, cx);
        if let Some(ws) = self.active_ws() && ws.read(cx).tree.edit.is_none() {
            ws.update(cx, |ws, cx| ws.tree.refresh(cx));
            self.request_reload(&ws, |_| true, window, cx);
            self.log_tree(cx);
            self.log_tabs(cx);
            cx.notify();
        }
    }
}

impl Workbench {
    /// 사이드바 폭을 끌어 바꿨다(A-11.1, R-28). 폭이 달라졌을 때만 저장한다.
    pub(super) fn on_sidebar_resized(&mut self, width: Pixels, window: &mut Window, cx: &mut Context<Self>) {
        let w = f64::from(f32::from(width)).round();
        if self.folders.state.sidebar_width == Some(w) {
            return;
        }
        self.folders.state.sidebar_width = Some(w);
        if self.dev(cx) {
            println!("[dev] sidebar-width width={w}");
        }
        self.schedule_save(window, cx);
    }

    /// 시작 때: 읽은 상태를 알리고 활성 폴더의 Workspace 를 만든다(저장하지 않는다).
    pub(super) fn start_folders(&mut self, loaded: &state::Loaded, window: &mut Window, cx: &mut Context<Self>) {
        if self.dev(cx) {
            println!(
                "[dev] state-load source={} read_only={} bad_moved_to={}",
                loaded.source,
                loaded.state.read_only,
                loaded
                    .bad_moved_to
                    .as_ref()
                    .map(|p| p.display().to_string())
                    .unwrap_or_else(|| "none".into())
            );
        }
        if let Some(text) = loaded.notice {
            notify_text(text, window, cx);
        }
        if let Some(folder) = self.folders.active_folder().cloned() {
            let ws = cx.new(|cx| FolderWorkspace::new(&folder, cx));
            self.folders.workspaces.insert(folder.id, ws);
        }
        self.log_folders(cx);
        self.log_tree(cx);
        cx.notify();
    }
}

thread_local! {
    static LAST_TITLE: std::cell::RefCell<Option<String>> = const { std::cell::RefCell::new(None) };
}

/// dev 출력: 타이틀 바 폴더 이름이 바뀌면 낸다.
pub(super) fn log_title(title: &Option<String>, cx: &App) {
    if !keymap::dev_enabled(cx) {
        return;
    }
    let text = title.clone().unwrap_or_else(|| "Open Recent Project".into());
    LAST_TITLE.with(|last| {
        if last.borrow().as_deref() != Some(text.as_str()) {
            println!("[dev] title text={text} placeholder={}", title.is_none());
            *last.borrow_mut() = Some(text);
        }
    });
}

impl Workbench {
    /// 아직 쓰지 않은 변경이 있으면 지금 쓴다(A-24.3 종료 직전 쓰기, 리뷰 1회차 ①). 창이 사라지기 전 경로(Close Window,
    /// 창 닫기 버튼)와 앱 종료 경로가 함께 부른다.
    pub(super) fn flush_save(&mut self, window: Option<&mut Window>, via: &str, cx: &mut App) {
        if self.folders.save_generation == self.folders.saved_generation {
            return;
        }
        if keymap::dev_enabled(cx) {
            println!("[dev] state-flush via={via}");
        }
        self.save_now(window, cx);
    }
}

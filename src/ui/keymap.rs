//! 키맵을 gpui 키 엔진에 묶는다 (v0.2 Phase 1, SPEC R-1~R-4, DECISIONS D-2·D-3·D-4·D-6·D-11·D-14).
//!
//! 층 순서(나중 것이 같은 깊이에서 이긴다, I-702·A-27.1):
//! 1. gpui-kit(gpui-component) 이 `gpui_kit::init` 때 넣은 자기 바인딩. 다시 읽을 때도 처음 것을 그대로 다시 넣는다.
//! 2. 앱 내장 키맵(`crate::keymap::builtin`). 등급 `KeyBindingMetaIndex(3)`(기본).
//! 3. 사용자 `keymap.json`. 등급 `KeyBindingMetaIndex(0)`(사용자). `null` 은 gpui `NoAction` 으로 묶는다(G-105 확인).
//!
//! `NoAction` 은 등급이 같거나 약한 바인딩만 가린다(gpui-pre 0.3.10 `keymap.rs` `resolve_bindings_for_input`).
//! 사용자 등급이 가장 강하므로 사용자 `null` 은 내장 바인딩을 가리고, 내장에는 `null` 이 없다(I-703).

use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::mpsc;

use gpui_kit::component::WindowExt as _;
use gpui_kit::*;

use crate::keymap::builtin::BUILTIN;
use crate::keymap::display::{self, Stroke};
use crate::keymap::file::{self, ERR_LOAD, err_not_found};
use crate::keymap::{ACTIONS, is_known_action};

/// I-703 출처 등급. 숫자가 작을수록 강하다(gpui `KeyBindingMetaIndex`).
const USER_META: KeyBindingMetaIndex = KeyBindingMetaIndex(0);
const BUILTIN_META: KeyBindingMetaIndex = KeyBindingMetaIndex(3);

/// 키맵 파일 이름 (A-20.4).
const KEYMAP_FILE: &str = "keymap.json";
/// 앱 데이터 폴더 이름 (D-11).
pub const APP_DIR: &str = "workbench-gpui";

pub mod workspace {
    gpui_kit::actions!(
        workspace,
        [ToggleLeftDock, Open, CopyPath, CopyRelativePath, CloseWindow, Save]
    );
}

pub mod zed {
    gpui_kit::actions!(zed, [Quit, Minimize, Zoom]);
}

pub mod multi_workspace {
    gpui_kit::actions!(
        multi_workspace,
        [ToggleWorkspaceSidebar, FocusWorkspaceSidebar]
    );
}

pub mod app_menu {
    gpui_kit::actions!(app_menu, [Toggle]);
}

pub mod project_panel {
    gpui_kit::actions!(
        project_panel,
        [
            ToggleFocus,
            CollapseSelectedEntry,
            ExpandSelectedEntry,
            CollapseAllEntries,
            ExpandAllEntries,
            Open,
            Rename,
            NewFile,
            NewDirectory,
            Copy,
            Cut,
            Paste,
            Trash,
            Delete,
            DeployContextMenu,
            SelectPreviousExtend,
            SelectNextExtend,
            RemoveFromProject,
            RevealInFileManager,
            OpenWithSystem,
        ]
    );
}

pub mod menu {
    gpui_kit::actions!(
        menu,
        [
            SelectNext,
            SelectPrevious,
            SelectFirst,
            SelectLast,
            Confirm,
            Cancel,
            SelectChild,
            SelectParent,
        ]
    );
}

/// 앱 전체 키맵 상태.
struct KeymapState {
    /// gpui-kit 이 넣은 바인딩(층 1).
    base: Vec<KeyBinding>,
    /// `%APPDATA%\workbench-gpui\keymap.json`. 경로를 얻지 못하면 None.
    path: Option<PathBuf>,
    /// `--dev-keymap`: 바인딩 전체·표시 문자열·키 입력 결과를 표준출력에 낸다.
    dev: bool,
    /// 읽은 횟수(dev 출력의 seq).
    seq: u32,
    /// 감시자. 살아 있어야 감시가 이어진다.
    watcher: Option<notify::RecommendedWatcher>,
    /// 표시 문자열을 고를 포커스 자리(이름, 포커스).
    places: Vec<(&'static str, FocusHandle)>,
}

impl Global for KeymapState {}

/// `%APPDATA%\workbench-gpui\keymap.json` (D-11, `dirs::config_dir` = Windows 의 `FOLDERID_RoamingAppData`).
pub fn keymap_path() -> Option<PathBuf> {
    dirs::config_dir().map(|dir| dir.join(APP_DIR).join(KEYMAP_FILE))
}

/// `gpui_kit::init` 바로 뒤에 한 번 부른다. 액션 처리기와 키 입력 관찰을 붙인다. 바인딩은 `load` 가 넣는다.
pub fn init(dev: bool, cx: &mut App) {
    DEV.store(dev, Ordering::Relaxed);
    let base: Vec<KeyBinding> = cx.key_bindings().borrow().bindings().cloned().collect();
    cx.set_global(KeymapState {
        base,
        path: keymap_path(),
        dev,
        seq: 0,
        watcher: None,
        places: Vec::new(),
    });

    // 액션 이름이 모두 등록되어 있어야 내장 키맵·사용자 키맵이 이름으로 액션을 만든다.
    for (name, _) in ACTIONS {
        if let Err(e) = cx.build_action(name, None) {
            panic!("action {name} is not registered: {e:?}");
        }
    }

    register_placeholder_handlers(cx);

    if dev {
        cx.observe_keystrokes(|event, _window, _cx| {
            let action = event
                .action
                .as_ref()
                .map(|a| a.name().to_string())
                .unwrap_or_else(|| "none".into());
            let context = event
                .context_stack
                .iter()
                .map(|c| format!("{c:?}"))
                .collect::<Vec<_>>()
                .join(" > ");
            println!(
                "[dev] key keystroke={} action={action} context={context}",
                keystroke_notation(&event.keystroke)
            );
        })
        .detach();
    }
}

/// 아직 화면·동작이 없는 액션의 자리 처리기(Phase 2~4 에서 실제 동작으로 바꾼다).
/// 처리기가 없으면 gpui 가 다음 순위 바인딩으로 넘어가므로(gpui-pre `window.rs` dispatch_key_event),
/// 바인딩 우선순위를 판정하려면 모든 액션에 처리기가 있어야 한다. 화면 요소의 처리기가 먼저 받으면 여기에는 오지 않는다.
fn register_placeholder_handlers(cx: &mut App) {
    macro_rules! placeholder {
        ($($t:ty),* $(,)?) => {
            $(
                cx.on_action(|action: &$t, cx: &mut App| {
                    if cx.global::<KeymapState>().dev {
                        println!("[dev] action-handled name={} by=placeholder", action.name());
                    }
                });
            )*
        };
    }
    placeholder!(
        workspace::ToggleLeftDock,
        workspace::Open,
        workspace::CopyPath,
        workspace::CopyRelativePath,
        workspace::CloseWindow,
        zed::Quit,
        zed::Minimize,
        zed::Zoom,
        multi_workspace::ToggleWorkspaceSidebar,
        multi_workspace::FocusWorkspaceSidebar,
        app_menu::Toggle,
        project_panel::ToggleFocus,
        project_panel::CollapseSelectedEntry,
        project_panel::ExpandSelectedEntry,
        project_panel::CollapseAllEntries,
        project_panel::ExpandAllEntries,
        project_panel::Open,
        project_panel::Rename,
        project_panel::NewFile,
        project_panel::NewDirectory,
        project_panel::Copy,
        project_panel::Cut,
        project_panel::Paste,
        project_panel::Trash,
        project_panel::Delete,
        project_panel::DeployContextMenu,
        project_panel::SelectPreviousExtend,
        project_panel::SelectNextExtend,
        project_panel::RemoveFromProject,
        project_panel::RevealInFileManager,
        project_panel::OpenWithSystem,
        menu::SelectNext,
        menu::SelectPrevious,
        menu::SelectFirst,
        menu::SelectLast,
        menu::Confirm,
        menu::Cancel,
        menu::SelectChild,
        menu::SelectParent,
    );
}


/// `--dev-keymap` 이 켜졌는가. `App` 이 없는 곳(Drop 등)에서 쓴다.
static DEV: AtomicBool = AtomicBool::new(false);

pub fn dev_flag() -> bool {
    DEV.load(Ordering::Relaxed)
}

pub fn dev_enabled(cx: &App) -> bool {
    cx.try_global::<KeymapState>().is_some_and(|s| s.dev)
}

/// 액션 이름 하나의 표시 문자열(메뉴 I-307·I-510, 툴팁 L-201·L-202, I-704·L-217).
/// `focus` 가 있으면(메뉴: 열기 직전 포커스) 그 자리의 컨텍스트에서만, 없으면(툴팁) 지금 포커스 핸들의 컨텍스트에서
/// 고른다. 다른 액션에 가려진 키는 빼고 남은 것 중 마지막이다(I-704, gpui `highest_precedence_binding_for_action_in`).
/// 없으면 None 이다(L-223: 단축키 없이 제목만). I-307 의 "없으면 창 전체"는 열기 직전 포커스가 없을 때(지금 포커스)로만 쓴다.
/// 리뷰 1회차 ②(D-032)·2회차 ②(D-033): 가려진 결과를 다른 컨텍스트나 키맵 전체의 후보로 바꾸지 않는다.
pub fn shortcut_for_name(
    name: &str,
    focus: Option<&FocusHandle>,
    window: &Window,
    cx: &App,
) -> Option<String> {
    let action = cx.build_action(name, None).ok()?;
    // "지금 포커스"는 포커스 핸들로 직접 고른다. `Window::highest_precedence_binding_for_action` 은 디스패치 트리에
    // 마지막으로 그린 요소의 컨텍스트 스택을 써서 포커스 자리와 다를 수 있다(gpui-pre `window.rs` 6809행).
    // `focus` 가 있으면 그 자리에서만 고른다. 거기서 가려져 없으면 표시하지 않는다(리뷰 2회차 ②, D-033):
    // 메뉴 포커스 같은 다른 컨텍스트로 다시 찾으면 원래 자리에서 가려진 키가 되살아난다.
    let binding = match focus {
        Some(focus) => window.highest_precedence_binding_for_action_in(action.as_ref(), focus)?,
        None => {
            let current = window.focused(cx)?;
            window.highest_precedence_binding_for_action_in(action.as_ref(), &current)?
        }
    };
    Some(display::binding_text(&strokes(&binding)))
}
/// dev 출력: 화면 요소 처리기가 액션을 받았다.
pub fn log_handled(action: &dyn Action, focus: &str, cx: &App) {
    if cx.global::<KeymapState>().dev {
        println!(
            "[dev] action-handled name={} by=workbench focus={focus}",
            action.name()
        );
    }
}

/// 세 층을 모두 다시 넣고, 오류가 있으면 알림 하나로 보인다(D-14 이후 변경). 창이 열린 뒤에 부른다.
pub fn load(window: &mut Window, cx: &mut App) {
    let errors = apply(cx);
    if !errors.is_empty() {
        let text = errors.join("\n");
        window.push_notification(text.as_str(), cx);
    }
    let state = cx.global::<KeymapState>();
    if state.dev {
        let seq = state.seq;
        dump(&errors, cx);
        window.on_next_frame(move |window, cx| dump_display(seq, window, cx));
    }
    // 메뉴·툴팁 표시는 그릴 때 키맵에서 다시 고른다. 바인딩을 바꾸면 gpui 가 창을 다시 그린다(bind_keys → RefreshWindows).
    window.refresh();
}

fn apply(cx: &mut App) -> Vec<String> {
    let mut bindings: Vec<KeyBinding> = cx.global::<KeymapState>().base.clone();
    let mut errors = Vec::new();

    for b in BUILTIN {
        let action = cx
            .build_action(b.action, None)
            .unwrap_or_else(|e| panic!("builtin action {}: {e:?}", b.action));
        // 빈 문자열은 컨텍스트 없는(전역) 바인딩이다.
        let predicate = (!b.context.is_empty()).then(|| {
            Rc::new(
                KeyBindingContextPredicate::parse(b.context)
                    .unwrap_or_else(|e| panic!("builtin context {}: {e}", b.context)),
            )
        });
        let binding = KeyBinding::load(b.keys, action, predicate, false, None, cx)
            .unwrap_or_else(|e| panic!("builtin keys {}: {e:?}", b.keys));
        bindings.push(binding.with_meta(BUILTIN_META));
    }

    if let Some(path) = cx.global::<KeymapState>().path.clone() {
        let parsed = file::read(&path, &is_known_action);
        for entry in parsed.entries {
            let user = match entry {
                Ok(user) => user,
                Err(text) => {
                    errors.push(text);
                    continue;
                }
            };
            let predicate = match &user.context {
                None => None,
                Some(context) => match KeyBindingContextPredicate::parse(context) {
                    Ok(p) => Some(Rc::new(p)),
                    Err(_) => {
                        errors.push(ERR_LOAD.into());
                        continue;
                    }
                },
            };
            let action: Box<dyn Action> = match &user.action {
                None => Box::new(NoAction),
                Some(name) => match cx.build_action(name, None) {
                    Ok(a) => a,
                    Err(_) => {
                        errors.push(err_not_found(name));
                        continue;
                    }
                },
            };
            match KeyBinding::load(&user.keys, action, predicate, false, None, cx) {
                Ok(binding) => bindings.push(binding.with_meta(USER_META)),
                Err(_) => errors.push(ERR_LOAD.into()),
            }
        }
    }

    cx.clear_key_bindings();
    cx.bind_keys(bindings);
    cx.global_mut::<KeymapState>().seq += 1;
    errors
}

fn strokes(binding: &KeyBinding) -> Vec<Stroke<'_>> {
    binding
        .keystrokes()
        .iter()
        .map(|k| {
            let m = k.modifiers();
            Stroke {
                function: m.function,
                control: m.control,
                platform: m.platform,
                alt: m.alt,
                shift: m.shift,
                key: k.key(),
            }
        })
        .collect()
}

fn keystroke_notation(k: &Keystroke) -> String {
    display::binding_notation(&[Stroke {
        function: k.modifiers.function,
        control: k.modifiers.control,
        platform: k.modifiers.platform,
        alt: k.modifiers.alt,
        shift: k.modifiers.shift,
        key: &k.key,
    }])
}

/// 표시 문자열을 고를 포커스 자리를 알린다(dev 출력과 Phase 2 메뉴·툴팁에서 쓴다).
pub fn register_place(name: &'static str, focus: FocusHandle, cx: &mut App) {
    cx.global_mut::<KeymapState>().places.push((name, focus));
}

/// 액션 하나의 표시 문자열(I-704·L-217): `focus` 자리에 포커스가 있다고 볼 때, 그 액션에 묶인 바인딩 중
/// 해제되지 않았고 그 자리의 컨텍스트에서 다른 액션에 가려지지 않은 마지막 것. gpui
/// `Window::highest_precedence_binding_for_action_in` 이 이 규칙대로 고른다(gpui-pre `key_dispatch.rs`
/// `binding_matches_predicate_and_not_shadowed`). 그 자리에서 듣지 않는 액션이면 None.
pub fn display_text_in(action: &dyn Action, focus: &FocusHandle, window: &Window) -> Option<String> {
    let binding = window.highest_precedence_binding_for_action_in(action, focus)?;
    Some(display::binding_text(&strokes(&binding)))
}

/// dev 출력: 자리마다 액션별 표시 문자열. 그려진 화면의 디스패치 트리가 필요해 다음 프레임에 낸다.
fn dump_display(seq: u32, window: &mut Window, cx: &mut App) {
    let places = cx.global::<KeymapState>().places.clone();
    for (place, focus) in &places {
        for (name, _) in ACTIONS {
            let Ok(action) = cx.build_action(name, None) else {
                continue;
            };
            let text = display_text_in(action.as_ref(), focus, window)
                .unwrap_or_else(|| "<none>".into());
            println!("[dev] display seq={seq} where={place} action={name} text={text}");
        }
    }
    println!("[dev] display-end seq={seq}");
}

fn dump(errors: &[String], cx: &App) {
    let state = cx.global::<KeymapState>();
    let seq = state.seq;
    let path = state
        .path
        .as_ref()
        .map(|p| p.display().to_string())
        .unwrap_or_else(|| "none".into());
    let exists = state.path.as_ref().is_some_and(|p| p.exists());
    let keymap: Rc<RefCell<Keymap>> = cx.key_bindings();
    let keymap = keymap.borrow();
    println!(
        "[dev] keymap-load seq={seq} path={path} exists={exists} bindings={} errors={}",
        keymap.bindings().len(),
        errors.len()
    );
    for e in errors {
        println!("[dev] notification seq={seq} text={e}");
    }
    for (index, binding) in keymap.bindings().enumerate() {
        let source = match binding.meta() {
            None => "gpui-kit",
            Some(m) if m == BUILTIN_META => "builtin",
            Some(m) if m == USER_META => "user",
            Some(_) => "other",
        };
        let context = binding
            .predicate()
            .map(|p| p.to_string())
            .unwrap_or_else(|| "-".into());
        let keys = binding
            .keystrokes()
            .iter()
            .map(|k| keystroke_notation(k.inner()))
            .collect::<Vec<_>>()
            .join(" ");
        println!(
            "[dev] binding seq={seq} index={index} source={source} keys={keys} context={context} action={}",
            binding.action().name()
        );
    }
    drop(keymap);
    for (index, b) in BUILTIN.iter().enumerate() {
        println!(
            "[dev] builtin seq={seq} index={index} keys={} context={} action={} source={}",
            b.keys,
            if b.context.is_empty() { "-" } else { b.context },
            b.action,
            b.source
        );
    }
    println!("[dev] keymap-load-end seq={seq}");
}

/// `keymap.json` 이 바뀌면 다시 읽는다(R-4, D-6 notify). 폴더를 감시해 저장 방식(덮어쓰기·바꿔치기)과 상관없이 잡는다.
/// 폴더가 없으면 만든다(D-11 앱 데이터 폴더).
pub fn watch(window: &mut Window, cx: &mut App) {
    use notify::Watcher as _;

    let Some(path) = cx.global::<KeymapState>().path.clone() else {
        return;
    };
    let Some(dir) = path.parent().map(|d| d.to_path_buf()) else {
        return;
    };
    let _ = std::fs::create_dir_all(&dir);
    let (tx, rx) = mpsc::channel::<()>();
    let watcher = notify::recommended_watcher(move |res: notify::Result<notify::Event>| {
        if let Ok(event) = res
            && event
                .paths
                .iter()
                .any(|p| p.file_name().is_some_and(|n| n.eq_ignore_ascii_case(KEYMAP_FILE)))
        {
            let _ = tx.send(());
        }
    });
    let mut watcher = match watcher {
        Ok(w) => w,
        Err(e) => {
            eprintln!("keymap watch failed: {e}");
            return;
        }
    };
    if let Err(e) = watcher.watch(&dir, notify::RecursiveMode::NonRecursive) {
        eprintln!("keymap watch failed: {e}");
        return;
    }
    cx.global_mut::<KeymapState>().watcher = Some(watcher);

    window
        .spawn(cx, async move |cx| {
            loop {
                cx.background_executor()
                    .timer(crate::ui::metrics::timing::KEYMAP_POLL)
                    .await;
                if rx.try_recv().is_err() {
                    continue;
                }
                // 저장 한 번에 이벤트가 여러 개 온다. 잠잠해질 때까지 기다렸다가 한 번만 읽는다.
                loop {
                    cx.background_executor()
                        .timer(crate::ui::metrics::timing::KEYMAP_QUIET)
                        .await;
                    if rx.try_iter().count() == 0 {
                        break;
                    }
                }
                if cx.update(load).is_err() {
                    break;
                }
            }
        })
        .detach();
}

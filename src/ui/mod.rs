//! 얇은 래퍼 계층(ui 헬퍼). gpui-kit 의존을 이 모듈 안에 가둔다 (DECISIONS D-5).
//!
//! 진입 순서는 gpui-kit 0.8.1 crate 문서의 예시(application → init → open_window)를 따른다.

mod app_menu;
mod context_menu;
mod editor_poc;
mod extensions;
mod folders;
mod fonts;
mod keymap;
mod keymap_editor;
mod markdown_preview;
mod layout;
mod layout_probe;
mod menu_common;
pub(crate) mod metrics;
mod pane;
mod pane_group;
mod pane_view;
mod tab_drag;
mod tab_input;
mod panel_delete;
mod panel_edit;
mod panel_menu;
mod panel_nav;
mod panel_ops;
mod panel_view;
mod project_panel;
mod rem;
mod settings;
mod shell;
mod tab_close;
mod task_dialog;
mod theme;
mod title_bar;
mod tooltip;
mod watch;
mod watch_io;
mod zed_icons;

use std::time::Duration;

use gpui_kit::component::{
    ActiveTheme as _, InteractiveElementExt as _, TitleBar, h_resizable, resizable_panel, v_flex,
};
use gpui_kit::prelude::FluentBuilder as _;
use gpui_kit::*;

use crate::dev::DevOptions;
use layout_probe::probe;
use metrics::{
    DOCK_DEFAULT_WIDTH, DOCK_HANDLE_WIDTH, SIDEBAR_DEFAULT_WIDTH, SIDEBAR_MAX_WIDTH,
    SIDEBAR_MIN_WIDTH, WINDOW_INITIAL_SIZE, WINDOW_MIN_SIZE, WINDOW_ROUNDING,
};
use rem::to_px;

const APP_TITLE: &str = "workbench-gpui";

struct Workbench {
    glyph_font: SharedString,
    /// Phase 2 편집기 PoC (디버그 전용 `--dev-editor-poc`). 있으면 가운데 Pane 의 활성 아이템 자리에 둔다.
    editor_poc: Option<Entity<editor_poc::EditorPoc>>,
    /// 왼쪽 Dock 의 저장 폭. None 이면 기본 폭(L-32 240)이다. 핸들 더블클릭이 None 으로 되돌린다(L-30).
    /// 화면에 쓰는 폭은 `effective_dock_width` 로 본문 폭에 맞춰 다시 제한한 값이다.
    dock_width: Option<Pixels>,
    /// 직전 레이아웃의 Workspace 본문 폭. 사이드바 폭·창 크기가 바뀌면 달라지고, 달라지면 다시 그린다.
    body_width: Option<Pixels>,
    /// dev 출력: 마지막으로 낸 (포커스 자리, 창 활성) 상태.
    last_focus_log: String,
    /// 왼쪽 Dock 이 열려 있는가 (Ctrl-B, I-022). 처음에는 열려 있다.
    dock_open: bool,
    /// 키 컨텍스트 `Sidebar` 자리의 포커스 (D-3 이후 변경, D-027 ④).
    sidebar_focus: FocusHandle,
    /// 키 컨텍스트 `ProjectPanel` 자리의 포커스 (I-002).
    panel_focus: FocusHandle,
    /// 가운데 Pane 자리의 포커스. 창이 뜨면 여기에 포커스를 둔다.
    center_focus: FocusHandle,
    /// ☰ 앱 메뉴 (Phase 2, R-8·R-9).
    app_menu: Entity<app_menu::AppMenu>,
    user_menu: Entity<app_menu::UserMenu>,
    settings_workspace: Option<Entity<folders::FolderWorkspace>>,
    /// 등록 폴더·활성·커서·state.json (Phase 3, R-10~R-16·R-28).
    folders: folders::FolderList,
    /// 사이드바가 열려 있는가(A-11.7: 처음에는 열려 있다). 저장하지 않는다(D-10 범위 밖).
    sidebar_open: bool,
    /// 사이드바로 포커스를 옮기기 직전의 포커스(A-17.1·A-17.2 돌아갈 자리).
    sidebar_prev_focus: Option<FocusHandle>,
    /// 사이드바·Workspace 분할 상태. 사이드바를 닫았다 열어도 폭을 그대로 둔다.
    split: Entity<gpui_kit::component::ResizableState>,
    /// 프로젝트 패널 파일 클립보드(I-037, Phase 4).
    file_clipboard: Option<panel_ops::FileClipboard>,
    /// Bumped on every copy/cut and every cut-paste start; a finished cut paste restores failed entries only if it is still the latest.
    clip_gen: u64,
    /// 열린 프로젝트 패널 우클릭 메뉴(R-22).
    panel_menu: Option<panel_menu::OpenPanelMenu>,
    /// 열린 탭 바 분할 팝업(I-706, P4-3b).
    split_menu: Option<pane_view::OpenMenu>,
    /// 열린 탭 우클릭 메뉴(Pin / Unpin, P4-23b-R1).
    tab_menu: Option<pane_view::OpenMenu>,
    /// Where a tab being dragged would land over a pane body (I-714, P4-4).
    drop_hint: Option<tab_drag::DropHint>,
    /// 왼쪽 단추를 누른 트리 행(놓을 때 같은 행이면 누르기로 본다).
    pending_press: Option<std::path::PathBuf>,
    /// 휴지통·삭제 확인창이 떠 있다(겹쳐 띄우지 않는다).
    deleting: bool,
    /// 저장 질문(탭 닫기·창 닫기·종료)이 떠 있나 (P3-3, `tab_close`).
    prompt: tab_close::Prompt,
    /// 활성 폴더 디스크 감시(Phase 5, R-24).
    watch: watch::WatchState,
}

/// 왼쪽 Dock 핸들을 끄는 동안의 끌기 값 (L-30). 화면에는 아무것도 그리지 않는다.
#[derive(Clone)]
struct DockResize;

impl Render for DockResize {
    fn render(&mut self, _: &mut Window, _: &mut Context<Self>) -> impl IntoElement {
        div()
    }
}

impl Workbench {
    /// 지금 포커스가 있는 자리 이름 (dev 출력용).
    fn focus_name(&self, window: &Window, cx: &App) -> &'static str {
        if self.sidebar_focus.is_focused(window) {
            "sidebar"
        } else if self.panel_focus.is_focused(window) {
            "project_panel"
        } else if self.center_focus.is_focused(window) {
            "center"
        } else if self.active_editor_focused(window, cx) {
            // Phase 4: 활성 탭의 편집기(가운데 Pane 안).
            "editor"
        } else if self.panel_editing(cx) {
            // 프로젝트 패널 인라인 입력칸(P-022 editing).
            "panel_input"
        } else {
            "none"
        }
    }

    /// 활성 폴더의 활성 탭 편집기에 포커스가 있는가.
    fn active_editor_focused(&self, window: &Window, cx: &App) -> bool {
        self.active_ws().is_some_and(|ws| {
            ws.read(cx)
                .group
                .active_tab()
                .is_some_and(|t| t.editor.focus_handle(cx).is_focused(window))
        })
    }

    /// Phase 1 에서 화면 요소가 직접 받는 액션. 나머지는 `keymap` 의 자리 처리기가 받는다.
    /// 포커스 이동은 R-3·R-4 시험에서 포커스 자리를 바꾸는 데 쓰는 최소 동작이다. 이전 포커스로 돌아가기 등
    /// A-17.1·A-17.2·I-098~I-100 의 전체 동작은 Phase 3(R-16)에서 맞춘다.
    fn on_toggle_left_dock(
        &mut self,
        action: &keymap::workspace::ToggleLeftDock,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        keymap::log_handled(action, self.focus_name(window, cx), cx);
        self.dock_open = !self.dock_open;
        if !self.dock_open && self.panel_focus.is_focused(window) {
            self.center_focus.focus(window, cx);
        }
        cx.notify();
    }

    fn on_toggle_project_panel_focus(
        &mut self,
        action: &keymap::project_panel::ToggleFocus,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        keymap::log_handled(action, self.focus_name(window, cx), cx);
        if self.panel_focus.is_focused(window) {
            self.center_focus.focus(window, cx);
        } else {
            self.dock_open = true;
            self.panel_focus.focus(window, cx);
        }
        cx.notify();
    }

    /// F10: ☰ 앱 메뉴 열기, 열린 채 F10 = 닫기 (I-310, A-18.1).
    fn on_toggle_app_menu(
        &mut self,
        action: &keymap::app_menu::Toggle,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        keymap::log_handled(action, self.focus_name(window, cx), cx);
        self.app_menu.update(cx, |menu, cx| menu.toggle(window, cx));
    }

    /// Quit workbench-gpui (I-341).
    fn on_quit(&mut self, action: &keymap::zed::Quit, window: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(action, self.focus_name(window, cx), cx);
        // Dirty tabs are asked about first (P3-3, E-081/E-082); the exit finishes there when the answer allows it.
        if self.request_exit(tab_close::Exit::Quit, window, cx) {
            self.finish_exit(tab_close::Exit::Quit, window, cx);
        }
    }

    /// Close Window (I-358). 창이 하나라 창을 닫으면 앱도 끝난다.
    fn on_close_window(
        &mut self,
        action: &keymap::workspace::CloseWindow,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        keymap::log_handled(action, self.focus_name(window, cx), cx);
        if self.request_exit(tab_close::Exit::CloseWindow, window, cx) {
            self.finish_exit(tab_close::Exit::CloseWindow, window, cx);
        }
    }

    /// Window > Minimize (I-445).
    fn on_minimize(&mut self, action: &keymap::zed::Minimize, window: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(action, self.focus_name(window, cx), cx);
        window.minimize_window();
    }

    /// Window > Zoom (I-446): 창 확대(최대화)·복원.
    fn on_zoom(&mut self, action: &keymap::zed::Zoom, window: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(action, self.focus_name(window, cx), cx);
        window.zoom_window();
    }

    /// 왼쪽 Dock 폭 한계 (L-31): 하한 = 핸들 6, 상한 = 폭 − 6. 오른쪽 Dock 은 없다(L-14).
    /// "창 폭"은 Dock 이 들어 있는 Workspace 본문 폭으로 본다(사이드바는 Workspace 밖, L-11).
    fn clamp_dock_width(width: Pixels, body_width: Pixels, window: &Window) -> Pixels {
        let handle = to_px(DOCK_HANDLE_WIDTH, window);
        let max = (body_width - handle).max(handle);
        width.max(handle).min(max)
    }

    /// 화면에 쓰는 Dock 폭: 저장 폭(없으면 기본 240)을 지금 본문 폭으로 다시 제한한 값(L-31).
    /// 끌기 때만이 아니라 사이드바 확장·창 축소·기본 폭 복원 뒤에도 상한 "본문 폭 − 6"을 넘지 않는다.
    /// 첫 레이아웃 전(본문 폭을 아직 모를 때)에는 저장 폭을 그대로 쓴다.
    fn effective_dock_width(&self, window: &Window) -> Pixels {
        let width = self
            .dock_width
            .unwrap_or_else(|| to_px(DOCK_DEFAULT_WIDTH, window));
        match self.body_width {
            Some(body_width) => Self::clamp_dock_width(width, body_width, window),
            None => width,
        }
    }

    /// 본문: [왼쪽 Dock] → [가운데 Pane], 그리고 Dock 오른쪽 경계에 걸친 6px 핸들 (L-14, L-16, L-30).
    fn body(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement + use<> {
        let project_panel = self.render_project_panel(window, cx);
        let editing = self.panel_editing(cx);
        // P4-3b: every pane of the active folder (tab bar and body each), or the zoomed one alone.
        let tree = self.pane_tree(window, cx);
        let theme = cx.theme();
        let handle = to_px(DOCK_HANDLE_WIDTH, window);
        // Dock 폭과 핸들 위치 모두 유효 폭 기준이다.
        let dock_width = self.effective_dock_width(window);


        // 프로젝트 패널 자리의 키 컨텍스트: `ProjectPanel` 과 `menu` 를 함께 가진다(I-002, I-030 "ProjectPanel + menu").
        // 인라인 입력 중이면 `editing`, 아니면 `not_editing`(P-022, I-033).
        let mut panel_context = KeyContext::default();
        panel_context.add(crate::keymap::builtin::PROJECT_PANEL_CONTEXT);
        panel_context.add(crate::keymap::builtin::MENU_CONTEXT);
        panel_context.add(if editing { "editing" } else { crate::keymap::builtin::NOT_EDITING });

        let dock: Option<AnyElement> = self.dock_open.then(|| {
            div()
                .key_context(panel_context)
                .track_focus(&self.panel_focus)
                // 트리 빈 곳을 누르면 TreeState 가 자기 포커스를 잡는다. 그 뒤에 우리 자리로 되돌린다(입력칸을 누른 때는 빼고).
                .on_mouse_down(MouseButton::Left, cx.listener(|this, _: &MouseDownEvent, window, cx| {
                    let input_focused = this.active_ws().is_some_and(|ws| {
                        ws.read(cx).tree.edit.as_ref().is_some_and(|e| e.input.read(cx).focus_handle(cx).is_focused(window))
                    });
                    if !input_focused {
                        this.panel_focus.focus(window, cx);
                    }
                }))
                .on_action(cx.listener(Self::on_tree_next))
                .on_action(cx.listener(Self::on_tree_prev))
                .on_action(cx.listener(Self::on_tree_first))
                .on_action(cx.listener(Self::on_tree_last))
                .on_action(cx.listener(Self::on_tree_next_extend))
                .on_action(cx.listener(Self::on_tree_prev_extend))
                .on_action(cx.listener(Self::on_tree_expand))
                .on_action(cx.listener(Self::on_tree_collapse))
                .on_action(cx.listener(Self::on_tree_expand_all))
                .on_action(cx.listener(Self::on_tree_collapse_all))
                .on_action(cx.listener(Self::on_tree_open))
                .on_action(cx.listener(Self::on_rename))
                .on_action(cx.listener(Self::on_new_file))
                .on_action(cx.listener(Self::on_new_dir))
                .on_action(cx.listener(Self::on_copy))
                .on_action(cx.listener(Self::on_cut))
                .on_action(cx.listener(Self::on_paste))
                .on_action(cx.listener(Self::on_trash))
                .on_action(cx.listener(Self::on_delete))
                .on_action(cx.listener(Self::on_copy_path))
                .on_action(cx.listener(Self::on_copy_relative_path))
                .on_action(cx.listener(Self::on_deploy_menu))
                .on_action(cx.listener(Self::on_reveal))
                .on_action(cx.listener(Self::on_open_with_system))
                .on_action(cx.listener(Self::on_panel_cancel))
                .on_action(cx.listener(Self::on_input_escape))
                .flex_shrink_0()
                .h_full()
                .w(dock_width)
                .border_r_1()
                .border_color(theme.border)
                .bg(theme.sidebar)
                .child(project_panel)
                .into_any_element()
        });

        div()
            .on_children_prepainted(probe(if self.dock_open {
                &["dock", "center", "dock-handle"][..]
            } else {
                &["center"][..]
            }))
            .id("workspace-body")
            .relative()
            .flex()
            .size_full()
            .on_drag_move::<DockResize>(cx.listener(
                |this, e: &DragMoveEvent<DockResize>, window, cx| {
                    let width = e.event.position.x - e.bounds.left();
                    this.dock_width =
                        Some(Self::clamp_dock_width(width, e.bounds.size.width, window));
                    cx.notify();
                },
            ))
            .children(dock)
            .child(
                v_flex()
                    .key_context(crate::keymap::builtin::PANE_CONTEXT)
                    .track_focus(&self.center_focus)
                    .flex_1()
                    .min_w_0()
                    .h_full()
                    .child(tree),
            )
            .when(self.dock_open, |body| {
                body.child(
                // L-30 핸들: 폭 6, Dock 오른쪽 테두리 위에 절반씩 걸친다(−3). 가운데 영역보다 뒤에 두어 위에 그린다.
                div()
                    .id("dock-handle")
                    .absolute()
                    .top_0()
                    .bottom_0()
                    .left(dock_width - handle / 2.)
                    .w(handle)
                    .cursor_col_resize()
                    .on_drag(DockResize, |drag, _, _, cx| cx.new(|_| drag.clone()))
                    .on_double_click(cx.listener(|this, _, _, cx| {
                        this.dock_width = None;
                        cx.notify();
                    })),
                )
            })
    }

    /// `--dev-layout`: 레이아웃 경계가 바뀔 때마다 이름별 경계와 rem·Dock 폭을 표준출력에 낸다.
    fn start_layout_dump(&self, window: &mut Window, cx: &mut Context<Self>) {
        layout_probe::enable();
        cx.spawn_in(window, async move |this, cx| {
            let mut last = String::new();
            let mut seq = 0u32;
            loop {
                cx.background_executor()
                    .timer(metrics::timing::LAYOUT_DUMP_POLL)
                    .await;
                let mut doc = None;
                let Ok(text) = this.update_in(cx, |this, window, cx| {
                    let mut out = format!(
                        "rem={} scale={} viewport={}x{} maximized={} dock_width={} dock_stored={} body_width={}",
                        f32::from(window.rem_size()),
                        window.scale_factor(),
                        f32::from(window.viewport_size().width),
                        f32::from(window.viewport_size().height),
                        window.is_maximized(),
                        f32::from(this.effective_dock_width(window)),
                        this.dock_width
                            .map(|w| f32::from(w).to_string())
                            .unwrap_or_else(|| "default".into()),
                        this.body_width
                            .map(|w| f32::from(w).to_string())
                            .unwrap_or_else(|| "unknown".into()),
                    );
                    // Phase 4 A-15.2: 활성 폴더 트리의 스크롤 위치.
                    if let Some(ws) = this.active_ws() {
                        let y = ws.read(cx).tree.state.read(cx).scroll_handle().0.borrow().base_handle.offset().y;
                        out.push_str(&format!(" tree_scroll_y={:.1}", f32::from(y)));
                        // R-27·D-18: 활성 탭 편집기 내용(길이·FNV-1a). 보기 전용이면 글자를 쳐도 바뀌지 않는다.
                        if let Some(tab) = ws.read(cx).group.active_tab() {
                            let text = tab.editor.read(cx).text().to_string();
                            let fnv = text.bytes().fold(0xcbf29ce484222325u64, |h, b| (h ^ b as u64).wrapping_mul(0x100000001b3));
                            out.push_str(&format!(" active_text_len={} active_text_fnv={fnv:016x}", text.len()));
                        }
                    }
                    // --dev-layout-json input (same snapshot as the stdout boxes below).
                    let viewport = window.viewport_size();
                    doc = Some((
                        f32::from(window.rem_size()),
                        window.scale_factor(),
                        (f32::from(viewport.width), f32::from(viewport.height)),
                        layout_probe::snapshot()
                            .into_iter()
                            .map(|(n, b)| {
                                let r = [b.origin.x, b.origin.y, b.size.width, b.size.height].map(f32::from);
                                (n, r)
                            })
                            .collect::<Vec<_>>(),
                    ));
                    for (name, b) in layout_probe::snapshot() {
                        out.push_str(&format!(
                            "\nname={name} bounds={:.2},{:.2},{:.2},{:.2}",
                            f32::from(b.origin.x),
                            f32::from(b.origin.y),
                            f32::from(b.size.width),
                            f32::from(b.size.height)
                        ));
                    }
                    out
                }) else {
                    break;
                };
                if text != last {
                    seq += 1;
                    if let (Some(path), Some((rem, scale, vp, boxes))) = (crate::dev::layout_json_path(), doc) {
                        let json = layout_probe::layout_json(seq, rem, scale, vp, &boxes);
                        if let Err(e) = std::fs::write(path, json) {
                            eprintln!("[dev] layout-json write failed: {path}: {e}");
                        }
                    }
                    let mut lines = text.lines();
                    if let Some(head) = lines.next() {
                        println!("[dev] layout-snapshot seq={seq} {head}");
                    }
                    for line in lines {
                        println!("[dev] layout-box seq={seq} {line}");
                    }
                    println!("[dev] layout-snapshot-end seq={seq}");
                    last = text;
                }
            }
        })
        .detach();
    }
}

impl Render for Workbench {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        window.set_rem_size(settings::ui_size(cx));
        let classic = settings::is_classic(self.dock_open, self.effective_dock_width(window), to_px(DOCK_DEFAULT_WIDTH, window));
        self.user_menu.update(cx, |menu, cx| menu.set_classic(classic, cx));
        // 레이아웃 탐침의 프레임 번호(사라진 툴팁·메뉴 경계를 스냅숏에서 빼려고). 창 루트라 프레임마다 그린다.
        layout_probe::begin_frame();
        // dev: 포커스 자리나 창 활성 상태가 바뀌면 낸다(키 판정에서 포커스가 어디로 갔는지 추적).
        if crate::ui::keymap::dev_flag() {
            let state = format!("focus={} active={}", self.focus_name(window, cx), window.is_window_active());
            if state != self.last_focus_log {
                println!("[dev] focus-state {state}");
                self.last_focus_log = state;
            }
        }
        let theme = cx.theme();
        let border = theme.border;
        let background = theme.background;

        // 본문 폭 추적: 레이아웃이 끝나면 본문 폭을 읽어, 달라졌으면 저장하고 다시 그린다.
        // 다음 렌더에서 effective_dock_width 가 새 폭으로 Dock 을 다시 제한한다.
        let weak = cx.entity().downgrade();
        let probe_body = probe(&["body"]);
        let track_body = move |bounds: Vec<Bounds<Pixels>>, window: &mut Window, cx: &mut App| {
            if let Some(width) = bounds.first().map(|b| b.size.width) {
                let _ = weak.update(cx, |this, cx| {
                    if this.body_width != Some(width) {
                        this.body_width = Some(width);
                        cx.notify();
                    }
                });
            }
            probe_body(bounds, window, cx);
        };

        // L-13 Workspace 세로 배치: 타이틀 바 → 본문 → 상태 표시줄.
        // L-301 본문 상자는 위·아래 1px 테두리를 갖는다(타이틀 바 아래 선, 상태 표시줄 위 선).
        let title = self.title_folder_name();
        folders::log_title(&title, cx);
        let workspace = v_flex()
            .on_children_prepainted(probe(&["title-bar", "work-area", "status-bar"]))
            .size_full()
            .bg(background)
            .child(title_bar::title_bar(
                self.glyph_font.clone(),
                self.app_menu.clone().into(),
                self.user_menu.clone().into(),
                self.app_menu.read(cx).is_open(),
                title,
                window,
                cx,
            ))
            .child(
                div()
                    .on_children_prepainted(track_body)
                    .flex()
                    .flex_1()
                    .min_h_0()
                    .border_t_1()
                    .border_b_1()
                    .border_color(border)
                    .child(self.body(window, cx)),
            )
            .child(layout::status_bar(self.dock_open, self.sidebar_open, cx));

        // L-11 창 최상위 가로 배치: [왼쪽 사이드바] → [Workspace]. 오른쪽 사이드바는 없다.
        // L-12 사이드바는 창 전체 높이를 차지하고 Workspace 의 타이틀 바는 사이드바 오른쪽에서 시작한다.
        // 사이드바 = resizable 패널(기본 300, 200~800, D-10 이후 변경). 폭은 state.json 에 저장한다(R-28, A-11.1).
        // 닫히면(A-17.1) 분할 자체를 그리지 않는다. 분할 상태(`split`)는 남아 다시 열면 폭이 그대로다.
        let workspace = div()
            .on_children_prepainted(probe(&["workspace"]))
            .size_full()
            .child(workspace);
        let content: AnyElement = if self.sidebar_open {
            let list = self.render_folder_list(window, cx);
            let width = self
                .folders
                .state
                .sidebar_width
                .map(|w| px(w as f32))
                .unwrap_or_else(|| to_px(SIDEBAR_DEFAULT_WIDTH, window));
            let weak = cx.entity().downgrade();
            h_resizable("workbench-split")
                .with_state(&self.split)
                .on_resize(move |state, window, cx| {
                    let Some(w) = state.read(cx).sizes().first().copied() else {
                        return;
                    };
                    let _ = weak.update(cx, |this, cx| this.on_sidebar_resized(w, window, cx));
                })
                .child(
                    resizable_panel()
                        // The sidebar keeps its width when the container resizes. Without `fixed`, the group rescales
                        // every panel in proportion when the window grows after the first layout (opens smaller, then
                        // maximized 1536 -> 1920): 300 -> 375, restored 494 -> 617 (x1.25). A drag still resizes it.
                        .fixed()
                        .size(width)
                        .size_range(to_px(SIDEBAR_MIN_WIDTH, window)..to_px(SIDEBAR_MAX_WIDTH, window))
                        .child(
                            div()
                                .key_context(crate::keymap::builtin::SIDEBAR_CONTEXT)
                                .track_focus(&self.sidebar_focus)
                                .on_action(cx.listener(Self::on_sidebar_next))
                                .on_action(cx.listener(Self::on_sidebar_previous))
                                .on_action(cx.listener(Self::on_sidebar_confirm))
                                .on_action(cx.listener(Self::on_sidebar_remove))
                                .on_children_prepainted(probe(&["sidebar"]))
                                .size_full()
                                .child(layout::sidebar(list, cx)),
                        ),
                )
                .child(resizable_panel().child(workspace))
                .into_any_element()
        } else {
            workspace.into_any_element()
        };
        let context_menu = self.folders.context_menu.as_ref().map(|m| m.menu.clone());

        // 키 컨텍스트 `Workspace`(I-022~I-024): 사이드바와 Workspace 를 함께 감싸, 어느 자리에 포커스가 있어도
        // 창 단위 키가 듣는다. 깊이는 Workspace > Sidebar, Workspace > ProjectPanel 이다.
        let root = div()
            .font(fonts::ui())
            .key_context(crate::keymap::builtin::WORKSPACE_CONTEXT)
            .on_action(cx.listener(Self::on_toggle_left_dock))
            .on_action(cx.listener(Self::on_toggle_project_panel_focus))
            .on_action(cx.listener(Self::on_focus_sidebar))
            .on_action(cx.listener(Self::on_toggle_sidebar))
            .on_action(cx.listener(Self::on_open_folder))
            .on_action(cx.listener(Self::on_toggle_app_menu))
            .on_action(cx.listener(Self::on_quit))
            .on_action(cx.listener(Self::on_close_window))
            .on_action(cx.listener(Self::on_save))
            .on_action(cx.listener(Self::on_open_settings))
            .on_action(cx.listener(Self::on_open_keymap))
            .on_action(cx.listener(Self::on_open_extensions))
            .on_action(cx.listener(Self::on_use_classic_layout))
            .on_action(cx.listener(Self::on_close_active_item))
            .on_action(cx.listener(Self::on_activate_previous_item))
            .on_action(cx.listener(Self::on_activate_next_item))
            .on_action(cx.listener(Self::on_toggle_pin_tab))
            .on_action(cx.listener(Self::on_open_preview))
            .on_action(cx.listener(Self::on_open_preview_to_the_side))
            .on_action(cx.listener(Self::on_split_right))
            .on_action(cx.listener(Self::on_split_left))
            .on_action(cx.listener(Self::on_split_up))
            .on_action(cx.listener(Self::on_split_down))
            .on_action(cx.listener(Self::on_toggle_zoom))
            .on_action(cx.listener(Self::on_activate_pane_left))
            .on_action(cx.listener(Self::on_activate_pane_right))
            .on_action(cx.listener(Self::on_activate_pane_up))
            .on_action(cx.listener(Self::on_activate_pane_down))
            .on_action(cx.listener(Self::on_minimize))
            .on_action(cx.listener(Self::on_zoom))
            .size_full()
            .child(content)
            .children(context_menu)
            .children(self.panel_menu.as_ref().map(|m| m.menu.clone()))
            .children(self.split_menu.as_ref().map(|m| m.menu.clone()))
            .children(self.tab_menu.as_ref().map(|m| m.menu.clone()));

        client_decorations(window, border, root)
    }
}

/// L-311 클라이언트 장식: 화면 가장자리에 맞닿지 않은(tiled 아닌) 변마다 1px 테두리, 두 변이
/// 모두 맞닿지 않은 모서리는 10px 둥글림. 최대화하면 모든 변이 맞닿은 것으로 본다.
///
/// gpui-pre 0.3.10 의 Windows 창은 `window_decorations()` 를 재정의하지 않아 항상
/// `Decorations::Server` 다(gpui-pre platform.rs 기본값). 그래서 Windows 에서는 이 분기가
/// 그리지 않고, 창 테두리·모서리는 DWM(OS)이 그린다.
fn client_decorations(window: &Window, border: Hsla, content: impl IntoElement) -> Div {
    match window.window_decorations() {
        Decorations::Server => div().size_full().child(content),
        Decorations::Client { tiling } => {
            let tiling = if window.is_maximized() {
                Tiling::tiled()
            } else {
                tiling
            };
            div()
                .size_full()
                .overflow_hidden()
                .border_color(border)
                .when(!tiling.top, |d| d.border_t_1())
                .when(!tiling.bottom, |d| d.border_b_1())
                .when(!tiling.left, |d| d.border_l_1())
                .when(!tiling.right, |d| d.border_r_1())
                .when(!(tiling.top || tiling.left), |d| {
                    d.rounded_tl(WINDOW_ROUNDING)
                })
                .when(!(tiling.top || tiling.right), |d| {
                    d.rounded_tr(WINDOW_ROUNDING)
                })
                .when(!(tiling.bottom || tiling.left), |d| {
                    d.rounded_bl(WINDOW_ROUNDING)
                })
                .when(!(tiling.bottom || tiling.right), |d| {
                    d.rounded_br(WINDOW_ROUNDING)
                })
                .child(content)
        }
    }
}

#[link(name = "user32")]
unsafe extern "system" {
    fn GetDpiForSystem() -> u32;
    fn GetSystemMetricsForDpi(index: i32, dpi: u32) -> i32;
}

const SM_CYSIZEFRAME: i32 = 33;
const SM_CXPADDEDBORDER: i32 = 92;

fn window_options(work_area: Bounds<Pixels>, frame_height: i32, scale: f32) -> WindowOptions {
    // TitleBar::window_options(): appears_transparent = true 로 OS 타이틀 바를 숨긴다.
    WindowOptions {
        // Keep I-6's fixed size even when the work area is smaller.
        window_bounds: Some(WindowBounds::Windowed(Bounds::centered_at(
            work_area.center() + point(px(0.), px((frame_height / 2) as f32 / scale)),
            WINDOW_INITIAL_SIZE,
        ))),
        titlebar: Some(TitlebarOptions {
            title: Some(APP_TITLE.into()),
            ..TitleBar::title_bar_options()
        }),
        window_min_size: Some(WINDOW_MIN_SIZE),
        ..TitleBar::window_options()
    }
}

/// 앱을 시작하고 창 하나를 연다. `dev` 는 디버그 빌드 전용 시험 플래그다.
pub fn run(dev: DevOptions) {
    // Keep component assets available alongside the local Zed SVGs.
    gpui_kit::application()
        .with_assets(zed_icons::Assets::new())
        .run(move |cx| {
            gpui_kit::init(cx);
            fonts::init(cx);
            theme::init(cx);
            settings::init(cx);
            keymap::init(dev.keymap, cx);
            let glyph_font = title_bar::glyph_font(cx);
            let poc_options = dev.editor_poc.then(|| dev.clone());
            let layout_dump = dev.layout;
            let pick_file = dev.pick_folder_file.clone();
            let work_area = cx
                .primary_display()
                .expect("failed to find primary display")
                .visible_bounds();
            // SAFETY: These functions take only scalar arguments and have no pointer requirements.
            let (dpi, frame_height) = unsafe {
                let dpi = GetDpiForSystem();
                (dpi, GetSystemMetricsForDpi(SM_CYSIZEFRAME, dpi) + GetSystemMetricsForDpi(SM_CXPADDEDBORDER, dpi))
            };
            let (window_handle, _) = gpui_kit::open_window(window_options(work_area, frame_height, dpi as f32 / 96.), cx, |window, cx| {
                let editor_poc = poc_options
                    .map(|options| cx.new(|cx| editor_poc::EditorPoc::new(options, window, cx)));
                let (folders, loaded) = folders::FolderList::load(pick_file);
                cx.new(|cx| {
                    let app_menu = cx.new(|cx| app_menu::AppMenu::new(window, cx));
                    cx.observe(&app_menu, |_, _, cx| cx.notify()).detach();
                    let this = Workbench {
                        glyph_font,
                        editor_poc,
                        dock_width: None,
                        body_width: None,
                        last_focus_log: String::new(),
                        dock_open: true,
                        sidebar_focus: cx.focus_handle(),
                        panel_focus: cx.focus_handle(),
                        center_focus: cx.focus_handle(),
                        app_menu,
                        user_menu: cx.new(|cx| app_menu::UserMenu::new(window, cx)),
                        settings_workspace: None,
                        folders,
                        sidebar_open: true,
                        sidebar_prev_focus: None,
                        split: cx.new(|_| gpui_kit::component::ResizableState::default()),
                        file_clipboard: None,
                        clip_gen: 0,
                        panel_menu: None,
                        split_menu: None,
                        tab_menu: None,
                        drop_hint: None,
                        pending_press: None,
                        deleting: false,
                        prompt: tab_close::Prompt::default(),
                        watch: watch::WatchState::default(),
                    };
                    // 알림은 gpui-kit Root 가 생긴 뒤에 띄운다(창을 연 다음 차례).
                    cx.defer_in(window, move |this: &mut Workbench, window, cx| {
                        this.start_folders(&loaded, window, cx);
                        // Phase 5(R-24): 활성 폴더 감시와 그 틱.
                        this.sync_watch("start", cx);
                        this.start_watch_loop(window, cx);
                    });
                    // 창이 다시 활성화되면 경로·트리·탭을 다시 본다(감시를 못 한 경우의 대비로 남긴다).
                    cx.observe_window_activation(window, |this: &mut Workbench, window, cx| {
                        if window.is_window_active() {
                            this.refresh_on_activation(window, cx);
                        }
                    })
                    .detach();
                    // A-24.3 종료 직전에 아직 쓰지 않은 변경을 쓴다(바뀐 것이 없으면 쓰지 않는다, 판단).
                    // 리뷰 1회차 ①(D-037): Workbench 를 강하게 붙잡는 App 수준 종료 처리기로 둔다. 창이 먼저 사라지는
                    // 경로에서도 엔티티가 살아 있어 쓸 수 있다. 창이 사라지기 전 경로(Close Window·창 닫기 버튼)는 따로 먼저 쓴다.
                    let strong = cx.entity();
                    App::on_app_quit(cx, move |cx| {
                        strong.update(cx, |this, cx| this.flush_save(None, "app-quit", cx));
                        async {}
                    })
                    .detach();
                    let weak_close = cx.entity().downgrade();
                    window.on_window_should_close(cx, move |window, cx| {
                        // Dirty tabs keep the window open until the question is answered (P3-3); finish_exit closes it.
                        weak_close
                            .update(cx, |this, cx| {
                                let go = this.request_exit(tab_close::Exit::CloseWindow, window, cx);
                                if go {
                                    this.flush_save(Some(window), "window-close", cx);
                                }
                                go
                            })
                            .unwrap_or(true)
                    });
                    this.center_focus.focus(window, cx);
                    keymap::register_place("center", this.center_focus.clone(), cx);
                    keymap::register_place("sidebar", this.sidebar_focus.clone(), cx);
                    keymap::register_place("project_panel", this.panel_focus.clone(), cx);
                    if layout_dump {
                        this.start_layout_dump(window, cx);
                    }
                    this
                })
            })
            .expect("failed to open window");

            // 창(gpui-kit Root 포함)이 생긴 뒤에 키맵을 읽는다. 읽기 오류 알림(D-14)은 창의 Root 가 띄운다.
            // 감시를 먼저 등록하고 나서 최초 로드를 한다. 그래야 등록 전후 어느 때 저장해도 놓치지 않는다:
            // 등록 전 저장은 최초 로드가 읽고, 등록 뒤 저장은 감시가 다시 읽는다(리뷰 1회차 ②).
            let startup_delay = dev.keymap_startup_delay_ms;
            window_handle
                .update(cx, |_, window, cx| {
                    keymap::watch(window, cx);
                    keymap::load(window, cx);
                    // 시험용: 최초 로드 직후에 멈춰, 그 사이 저장을 감시가 잡는지 본다. 감시를 로드 뒤에 등록하던
                    // 이전 순서에서는 이 구간의 저장을 놓쳤다.
                    if let Some(ms) = startup_delay {
                        println!("[dev] keymap-startup-pause delay_ms={ms}");
                        std::thread::sleep(Duration::from_millis(ms));
                    }
                })
                .expect("failed to load keymap");

            if dev.is_active() {
                // 창이 뜬 뒤에 시험한다. TaskDialog 는 자체 메시지 루프를 돌리므로
                // App 을 빌린 상태(cx.update 안)에서 부르지 않는다 (G-125 이벤트 루프 충돌 확인).
                cx.spawn(async move |cx| {
                    cx.background_executor()
                        .timer(metrics::timing::DEV_CHECKS_DELAY)
                        .await;
                    crate::dev::run_checks(&dev);
                })
                .detach();
            }
        });
}

#[cfg(test)]
mod window_tests {
    use super::{WINDOW_INITIAL_SIZE, WINDOW_MIN_SIZE, window_options};
    use gpui_kit::{Bounds, WindowBounds, point, px, size};

    #[test]
    fn initial_window_uses_work_area_center_and_fixed_client_size() {
        // gpui-pre-windows/src/window.rs::calculate_window_rect assigns height_offset / 2 to the top (integer division).
        for (work_area, frame_height, scale, expected_offset_y) in [
            (Bounds::new(point(px(0.), px(0.)), size(px(1920.), px(1040.))), 8, 1., 4.),
            (Bounds::new(point(px(-1920.), px(40.)), size(px(1920.), px(1040.))), 9, 1.25, 3.2),
            (Bounds::new(point(px(40.), px(0.)), size(px(1240.), px(720.))), 13, 2., 3.),
        ] {
            let options = window_options(work_area, frame_height, scale);
            let Some(WindowBounds::Windowed(bounds)) = options.window_bounds else {
                panic!("expected a windowed startup");
            };
            assert_eq!(bounds.size, WINDOW_INITIAL_SIZE);
            assert_eq!(bounds.center(), work_area.center() + point(px(0.), px(expected_offset_y)));
            assert_eq!(options.window_min_size, Some(WINDOW_MIN_SIZE));
            assert!(options.titlebar.unwrap().appears_transparent);
        }
    }
}

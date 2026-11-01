//! 얇은 래퍼 계층(ui 헬퍼). gpui-kit 의존을 이 모듈 안에 가둔다 (DECISIONS D-5).
//!
//! 진입 순서는 gpui-kit 0.8.1 crate 문서의 예시(application → init → open_window)를 따른다.

mod editor_poc;
mod layout;
mod layout_probe;
mod metrics;
mod rem;
mod title_bar;

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
    SIDEBAR_MIN_WIDTH, WINDOW_MIN_SIZE, WINDOW_ROUNDING,
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
    fn body(&self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement + use<> {
        let theme = cx.theme();
        let handle = to_px(DOCK_HANDLE_WIDTH, window);
        // Dock 폭과 핸들 위치 모두 유효 폭 기준이다.
        let dock_width = self.effective_dock_width(window);

        let item: AnyElement = match &self.editor_poc {
            Some(poc) => div().size_full().child(poc.clone()).into_any_element(),
            None => div().size_full().bg(theme.background).into_any_element(),
        };

        div()
            .on_children_prepainted(probe(&["dock", "center", "dock-handle"]))
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
            .child(
                div()
                    .flex_shrink_0()
                    .h_full()
                    .w(dock_width)
                    .border_r_1()
                    .border_color(theme.border)
                    .child(layout::project_panel_placeholder(cx)),
            )
            .child(
                v_flex()
                    .on_children_prepainted(probe(&["tab-bar", "active-item"]))
                    .flex_1()
                    .min_w_0()
                    .h_full()
                    .child(layout::tab_bar(cx))
                    .child(div().flex_1().min_h_0().child(item)),
            )
            .child(
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
    }

    /// `--dev-layout`: 레이아웃 경계가 바뀔 때마다 이름별 경계와 rem·Dock 폭을 표준출력에 낸다.
    fn start_layout_dump(&self, window: &mut Window, cx: &mut Context<Self>) {
        layout_probe::enable();
        cx.spawn_in(window, async move |this, cx| {
            let mut last = String::new();
            let mut seq = 0u32;
            loop {
                cx.background_executor()
                    .timer(Duration::from_millis(300))
                    .await;
                let Ok(text) = this.update_in(cx, |this, window, _| {
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
        let workspace = v_flex()
            .on_children_prepainted(probe(&["title-bar", "work-area", "status-bar"]))
            .size_full()
            .bg(background)
            .child(title_bar::title_bar(self.glyph_font.clone(), window, cx))
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
            .child(layout::status_bar(cx));

        // L-11 창 최상위 가로 배치: [왼쪽 사이드바] → [Workspace]. 오른쪽 사이드바는 없다.
        // L-12 사이드바는 창 전체 높이를 차지하고 Workspace 의 타이틀 바는 사이드바 오른쪽에서 시작한다.
        // 사이드바 = resizable 패널(기본 300, 200~800, D-10 이후 변경).
        let content = h_resizable("workbench-split")
            .child(
                resizable_panel()
                    .size(to_px(SIDEBAR_DEFAULT_WIDTH, window))
                    .size_range(to_px(SIDEBAR_MIN_WIDTH, window)..to_px(SIDEBAR_MAX_WIDTH, window))
                    .child(
                        div()
                            .on_children_prepainted(probe(&["sidebar"]))
                            .size_full()
                            .child(layout::sidebar(cx)),
                    ),
            )
            .child(
                resizable_panel().child(
                    div()
                        .on_children_prepainted(probe(&["workspace"]))
                        .size_full()
                        .child(workspace),
                ),
            );

        client_decorations(window, border, div().size_full().child(content))
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

fn window_options() -> WindowOptions {
    // TitleBar::window_options(): appears_transparent = true 로 OS 타이틀 바를 숨긴다.
    WindowOptions {
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
    // gpui-kit 기본 컴포넌트 아이콘(101개) 자산. 등록하지 않으면 Icon 이 자리만 잡고 그려지지 않는다
    // (gpui-kit-assets 0.8.1 README "let app = gpui_kit::application().with_assets(Assets)").
    gpui_kit::application()
        .with_assets(gpui_kit::assets::Assets)
        .run(move |cx| {
            gpui_kit::init(cx);
            let glyph_font = title_bar::glyph_font(cx);
            let poc_options = dev.editor_poc.then(|| dev.clone());
            let layout_dump = dev.layout;
            gpui_kit::open_window(window_options(), cx, |window, cx| {
                let editor_poc = poc_options
                    .map(|options| cx.new(|cx| editor_poc::EditorPoc::new(options, window, cx)));
                cx.new(|cx| {
                    let this = Workbench {
                        glyph_font,
                        editor_poc,
                        dock_width: None,
                        body_width: None,
                    };
                    if layout_dump {
                        this.start_layout_dump(window, cx);
                    }
                    this
                })
            })
            .expect("failed to open window");

            if dev.is_active() {
                // 창이 뜬 뒤에 시험한다. TaskDialog 는 자체 메시지 루프를 돌리므로
                // App 을 빌린 상태(cx.update 안)에서 부르지 않는다 (G-125 이벤트 루프 충돌 확인).
                cx.spawn(async move |cx| {
                    cx.background_executor()
                        .timer(Duration::from_millis(800))
                        .await;
                    crate::dev::run_checks(&dev);
                })
                .detach();
            }
        });
}

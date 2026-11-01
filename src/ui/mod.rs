//! 얇은 래퍼 계층(ui 헬퍼). gpui-kit 의존을 이 모듈 안에 가둔다 (DECISIONS D-5).
//!
//! 진입 순서는 gpui-kit 0.8.1 crate 문서의 예시(application → init → open_window)를 따른다.

mod editor_poc;
mod metrics;
mod title_bar;

use std::time::Duration;

use gpui_kit::component::{ActiveTheme as _, TitleBar, v_flex};
use gpui_kit::prelude::FluentBuilder as _;
use gpui_kit::*;

use crate::dev::DevOptions;
use metrics::{WINDOW_MIN_SIZE, WINDOW_ROUNDING};

const APP_TITLE: &str = "workbench-gpui";

struct Workbench {
    glyph_font: SharedString,
    /// Phase 2 편집기 PoC (디버그 전용 `--dev-editor-poc`). 없으면 본문은 비어 있다.
    editor_poc: Option<Entity<editor_poc::EditorPoc>>,
}

impl Render for Workbench {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let body = match &self.editor_poc {
            Some(poc) => div().flex_1().min_h_0().child(poc.clone()),
            None => div().flex_1(),
        };
        let content = v_flex()
            .size_full()
            .bg(cx.theme().background)
            .child(title_bar::title_bar(self.glyph_font.clone(), window, cx))
            .child(body);

        client_decorations(window, cx.theme().border, content)
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

/// 앱을 시작하고 창 하나를 연다. `dev` 는 R-5 시험용 숨은 플래그다.
pub fn run(dev: DevOptions) {
    gpui_kit::application().run(move |cx| {
        gpui_kit::init(cx);
        let glyph_font = title_bar::glyph_font(cx);
        let poc_options = dev.editor_poc.then(|| dev.clone());
        gpui_kit::open_window(window_options(), cx, |window, cx| {
            let editor_poc = poc_options
                .map(|options| cx.new(|cx| editor_poc::EditorPoc::new(options, window, cx)));
            cx.new(|_| Workbench {
                glyph_font,
                editor_poc,
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

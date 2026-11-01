//! 커스텀 타이틀 바와 창 버튼 (DECISIONS D-9, 02-gpui G-030).
//!
//! gpui-kit `TitleBar` 컴포넌트는 높이 34, 창 버튼 폭 34, SVG 아이콘으로 고정되어 있어
//! L-21(32)·L-39(36×32, 글리프)·L-83(글꼴 글리프)를 맞출 수 없다. 그래서 창 옵션만
//! `TitleBar::window_options()` 를 쓰고(mod.rs), 그리는 부분은 gpui `WindowControlArea`
//! (Drag/Min/Max/Close)로 직접 조립한다. 각 영역은 gpui-pre-windows 의 WM_NCHITTEST 처리에서
//! HTCAPTION/HTMINBUTTON/HTMAXBUTTON/HTCLOSE 로 바뀌므로, 더블클릭 최대화·끌기 이동·
//! 스냅 레이아웃(최대화 버튼 hover)은 OS 가 처리한다 (L-81, L-83, G-103).

use gpui_kit::component::{ActiveTheme as _, h_flex};
use gpui_kit::*;

use super::layout_probe::probe;
use super::metrics::{
    TITLE_BAR_HEIGHT, TITLE_BAR_PADDING_LEFT, WINDOW_BUTTON_GLYPH_SIZE, WINDOW_BUTTON_HEIGHT,
    WINDOW_BUTTON_WIDTH,
};

/// L-83 Windows 11(빌드 22000 이상) 글리프 글꼴.
pub const GLYPH_FONT_FLUENT: &str = "Segoe Fluent Icons";
/// L-83 그 이전 Windows 의 글리프 글꼴.
pub const GLYPH_FONT_MDL2: &str = "Segoe MDL2 Assets";

/// L-83 코드포인트.
const GLYPH_MINIMIZE: &str = "\u{E921}";
const GLYPH_MAXIMIZE: &str = "\u{E922}";
const GLYPH_RESTORE: &str = "\u{E923}";
const GLYPH_CLOSE: &str = "\u{E8BB}";

/// L-84 닫기 hover 배경 #E81120, 누름은 80% 불투명.
const CLOSE_HOVER_BG: u32 = 0xE81120;
const CLOSE_ACTIVE_BG: u32 = 0xE81120CC;
const CLOSE_ACTIVE_FG: u32 = 0xFFFFFFCC;

/// 설치된 글꼴로 글리프 글꼴을 고른다. L-83 은 빌드 번호(22000)로 고르지만, 여기서는
/// `Segoe Fluent Icons` 설치 여부로 대신한다(Windows 11 에 기본 설치).
pub fn glyph_font(cx: &App) -> SharedString {
    let names = cx.text_system().all_font_names();
    if names.iter().any(|name| name == GLYPH_FONT_FLUENT) {
        GLYPH_FONT_FLUENT.into()
    } else {
        GLYPH_FONT_MDL2.into()
    }
}

#[derive(Clone, Copy)]
enum WindowButton {
    Minimize,
    Maximize,
    Restore,
    Close,
}

impl WindowButton {
    fn id(self) -> &'static str {
        match self {
            Self::Minimize => "window-minimize",
            Self::Maximize => "window-maximize",
            Self::Restore => "window-restore",
            Self::Close => "window-close",
        }
    }

    fn glyph(self) -> &'static str {
        match self {
            Self::Minimize => GLYPH_MINIMIZE,
            Self::Maximize => GLYPH_MAXIMIZE,
            Self::Restore => GLYPH_RESTORE,
            Self::Close => GLYPH_CLOSE,
        }
    }

    fn area(self) -> WindowControlArea {
        match self {
            Self::Minimize => WindowControlArea::Min,
            Self::Maximize | Self::Restore => WindowControlArea::Max,
            Self::Close => WindowControlArea::Close,
        }
    }
}

/// L-87 왼쪽 묶음 gap 2 (`gap_0p5`).
const LEFT_GROUP_GAP: Rems = super::rem::rems_from_px(2.);

/// L-87 왼쪽 묶음: [☰ 메뉴] → [폴더 이름]. 폴더 이름 버튼은 이름 표시와 툴팁만 둔다(D-16).
/// v0.2 Phase 2 에는 등록 폴더가 없어 늘 `Open Recent Project`(Muted, L-227)를 보인다. 툴팁 `Recent Projects`(L-226).
/// 툴팁의 액션 `projects::OpenRecent` 는 v0.2 에 없어 단축키 없이 제목만 보인다(R-7, L-223).
fn left_group(app_menu: AnyView, cx: &App) -> impl IntoElement {
    let theme = cx.theme();
    let hover_bg = theme.secondary_hover;
    h_flex()
        .on_children_prepainted(probe(&["app-menu", "title-folder-name"]))
        .id("title-left")
        .flex_shrink_0()
        .h_full()
        .pl(TITLE_BAR_PADDING_LEFT)
        .gap(LEFT_GROUP_GAP)
        .child(app_menu)
        .child(
            div()
                .id("title-folder-name")
                .flex()
                .items_center()
                .h(super::metrics::BUTTON_DEFAULT)
                .px(super::rem::rems_from_px(6.))
                .text_sm()
                .text_color(theme.muted_foreground)
                .hover(move |s| s.bg(hover_bg))
                .tooltip(super::tooltip::build(super::tooltip::Spec::one(
                    "title-folder-name",
                    super::tooltip::Line::action("Recent Projects", "projects::OpenRecent"),
                )))
                .child("Open Recent Project"),
        )
}

/// 타이틀 바: [왼쪽 묶음] + [Drag 영역 (flex_1)] + [최소화][최대화|복원][닫기] (L-83 오른쪽 끝, L-87).
pub fn title_bar(
    glyph_font: SharedString,
    app_menu: AnyView,
    window: &Window,
    cx: &App,
) -> impl IntoElement {
    // L-312 최대화하지 않으면 최대화 □(U+E922), 최대화하면 복원(U+E923).
    let max_or_restore = if window.is_maximized() {
        WindowButton::Restore
    } else {
        WindowButton::Maximize
    };

    let theme = cx.theme();
    let colors = ButtonColors {
        fg: theme.foreground,
        hover_bg: theme.secondary_hover,
        active_bg: theme.secondary_active,
    };

    h_flex()
        .on_children_prepainted(probe(&["title-left", "title-bar-drag", "window-controls"]))
        .id("title-bar")
        .flex_shrink_0()
        .w_full()
        .h(TITLE_BAR_HEIGHT)
        .child(left_group(app_menu, cx))
        .child(
            h_flex()
                .id("title-bar-drag")
                .flex_1()
                .h_full()
                .window_control_area(WindowControlArea::Drag),
        )
        .child(
            h_flex()
                .on_children_prepainted(probe(&[
                    "window-btn-min",
                    "window-btn-max",
                    "window-btn-close",
                ]))
                .id("window-controls")
                .flex_shrink_0()
                .h_full()
                .child(window_button(WindowButton::Minimize, &glyph_font, colors))
                .child(window_button(max_or_restore, &glyph_font, colors))
                .child(window_button(WindowButton::Close, &glyph_font, colors)),
        )
}

/// L-84 닫기 외 버튼 색. Zed 는 `ghost_element_hover`·`ghost_element_active`·`text` 다.
/// 테마 매핑(G-106)은 v0.1 범위 밖이라 지금은 gpui-kit 기본 테마의 가까운 토큰을 쓴다.
#[derive(Clone, Copy)]
struct ButtonColors {
    fg: Hsla,
    hover_bg: Hsla,
    active_bg: Hsla,
}

fn window_button(
    button: WindowButton,
    font: &SharedString,
    colors: ButtonColors,
) -> impl IntoElement {
    let base = div()
        .id(button.id())
        .flex()
        .flex_shrink_0()
        .items_center()
        .justify_center()
        .w(WINDOW_BUTTON_WIDTH)
        .h(WINDOW_BUTTON_HEIGHT)
        .font_family(font.clone())
        .text_size(WINDOW_BUTTON_GLYPH_SIZE)
        .line_height(WINDOW_BUTTON_GLYPH_SIZE)
        .text_color(colors.fg)
        .window_control_area(button.area())
        .child(button.glyph());

    match button {
        WindowButton::Close => base
            .hover(|style| style.bg(rgb(CLOSE_HOVER_BG)).text_color(white()))
            .active(|style| {
                style
                    .bg(rgba(CLOSE_ACTIVE_BG))
                    .text_color(rgba(CLOSE_ACTIVE_FG))
            }),
        _ => base
            .hover(move |style| style.bg(colors.hover_bg))
            .active(move |style| style.bg(colors.active_bg)),
    }
}

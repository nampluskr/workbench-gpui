//! 창·타이틀 바 치수. 값은 01-zed 01-LAYOUT 의 항목 ID 원문 값이다 (논리 px).
//!
//! L-21: Windows 타이틀 바 높이는 rem 과 무관하게 32 고정이다. 그래서 rem 헬퍼(Phase 3)를
//! 거치지 않고 px 로 둔다.

use gpui_kit::{Pixels, Size, px};

/// L-21 타이틀 바 높이 (Windows 32 고정).
pub const TITLE_BAR_HEIGHT: Pixels = px(32.);
/// L-82 타이틀 바 왼쪽 padding `pl_2` = 8.
pub const TITLE_BAR_PADDING_LEFT: Pixels = px(8.);

/// L-39 창 버튼 각 36×32, 글리프 10.
pub const WINDOW_BUTTON_WIDTH: Pixels = px(36.);
pub const WINDOW_BUTTON_HEIGHT: Pixels = px(32.);
pub const WINDOW_BUTTON_GLYPH_SIZE: Pixels = px(10.);

/// L-311 클라이언트 장식의 모서리 둥글림 10px (테두리 1px 은 `border_*_1` 로 그린다).
pub const WINDOW_ROUNDING: Pixels = px(10.);

/// G-103 최소 창 크기 360×240.
pub const WINDOW_MIN_SIZE: Size<Pixels> = Size {
    width: px(360.),
    height: px(240.),
};

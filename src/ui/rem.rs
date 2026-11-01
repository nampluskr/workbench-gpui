//! rem 헬퍼 (SPEC R-15, 01-zed L-01·L-02).
//!
//! - L-01: 창의 rem 은 `ui_font_size`(기본 16px)다. gpui 창 기본 rem 도 16px 이고, v0.1 은 글꼴 크기
//!   설정이 없어 그대로 쓴다. 실제 값은 `--dev-layout` 출력의 `window_rem` 으로 확인한다.
//! - L-02: px → rem 변환은 px ÷ 16 이다. 결과가 rem 이라 rem 이 바뀌면 치수가 비례해 바뀐다.
//!
//! 레이아웃 치수(R-13)는 모두 이 헬퍼로 정의한다. 예외는 SPEC R-15 "이후 변경"에 따른
//! 타이틀 바·창 버튼(L-21 Windows 32 고정, `metrics.rs` 의 px 상수)뿐이다.

use gpui_kit::{Pixels, Rems, Window, rems};

/// L-02 의 기준 rem (px). Zed 치수 표의 px 값은 이 rem 에서의 값이다.
pub const BASE_REM_PX: f32 = 16.0;

/// Zed 치수 표의 px 값(rem 16 기준)을 rem 으로 바꾼다 (L-02 `rems_from_px`).
pub const fn rems_from_px(px: f32) -> Rems {
    rems(px / BASE_REM_PX)
}

/// rem 치수를 현재 창 rem 으로 px 로 바꾼다. px 를 받는 API(예: resizable 패널 크기)에 넘길 때 쓴다.
pub fn to_px(value: Rems, window: &Window) -> Pixels {
    value.to_pixels(window.rem_size())
}

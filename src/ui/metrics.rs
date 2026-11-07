//! 창·레이아웃 치수. 값은 01-zed 01-LAYOUT·04-APP-SPEC 의 항목 ID 원문 값이다(논리 px, rem 16 기준).
//!
//! - 타이틀 바·창 버튼(L-21, L-39, L-82): Windows 타이틀 바는 rem 과 무관하게 32 고정이라(L-21)
//!   px 로 둔다. SPEC R-15 "이후 변경"이 A-32.1·A-32.2 를 rem 헬퍼 예외로 허용했다.
//! - 그 밖의 레이아웃 치수(A-32.3~A-32.13, A-32.16 의 14): 모두 rem 헬퍼(`rems_from_px`)로 정의한다.
//! - 1px 테두리는 gpui 의 `border_*_1` 을 쓴다(Zed 도 `border_*_1` 1px 고정, L-16·L-27·L-35·L-301~L-303).

use std::time::Duration;
use gpui_kit::{Pixels, Rems, Size, px};

use super::rem::rems_from_px;

pub mod settings_window {
    use gpui_kit::{Pixels, Size, px};
    // SPEC R-2, tauri Zed Settings measurement (2026-11-07), logical pixels.
    pub const WINDOW_SIZE: Size<Pixels> = Size { width: px(900.), height: px(750.) };
    pub const SIDEBAR_WIDTH: Pixels = px(226.);
    pub const SIDEBAR_PADDING: Pixels = px(10.);
    pub const CONTROL_HEIGHT: Pixels = px(28.);
    pub const PADDING: Pixels = px(32.);
    pub const GAP: Pixels = px(24.);
    pub const CATEGORY_GAP: Pixels = px(12.);
    pub const EDIT_BUTTON_HEIGHT: Pixels = px(22.);
    // tauri SPEC R-2 Settings section titles (Zed page_data.rs, ORDER-06-R2).
    pub const SECTION_TEXT: Pixels = px(12.);
}

// SPEC R-2, Zed v-button measurement (2026-11-07).
pub const USER_BUTTON_SIZE: Pixels = px(22.);
// user_menu.button_icon_size (I-601), core ORDER-06-R2.
pub const USER_CHEVRON_SIZE: Pixels = px(14.);
pub const USER_BUTTON_MARGIN: Pixels = px(4.);

pub mod selector {
    use gpui_kit::{Pixels, px};
    // Zed measurement: measure-ORDER-07 section 3.2, installed build 4304dec732.
    pub const MODAL_WIDTH: Pixels = px(544.);
    pub const SEARCH_HEIGHT: Pixels = px(38.);
    pub const LIST_MAX_HEIGHT: Pixels = px(384.);
    pub const ROW_HEIGHT: Pixels = px(32.);
    pub const GAP: Pixels = px(0.);
    pub const SEPARATOR_HEIGHT: Pixels = px(1.);
    pub const FOOTER_HEIGHT: Pixels = px(38.);
}

pub mod keymap_editor {
    use gpui_kit::{Pixels, px};
    // keymap_editor padding/gap_vertical/top_row.gap/search_input.height (K-010..K-012).
    pub const PADDING: Pixels = px(8.);
    pub const GAP: Pixels = px(4.);
    pub const TOP_GAP: Pixels = px(8.);
    pub const SEARCH_HEIGHT: Pixels = px(32.);
    // keymap_editor table.ratio_* (K-022).
    pub const COLUMN_RATIOS: [f32; 5] = [0.25, 0.20, 0.14, 0.45, 0.08];
    // keymap_editor table.icon_column_width / icon_column_button.size (K-022, K-036).
    pub const EDIT_WIDTH: Pixels = px(36.);
    pub const EDIT_SIZE: Pixels = px(18.);
    // keymap_editor modal.* (K-080, K-082, K-083), record.max_keystrokes (K-055).
    pub const MODAL_WIDTH: Pixels = px(544.);
    pub const MODAL_GAP: Pixels = px(10.);
    pub const FOOTER_GAP: Pixels = px(4.);
    pub const MAX_STROKES: usize = 3;
}

pub mod extensions {
    use gpui_kit::{Pixels, px};
    // extensions header.padding_*/row_gap (X-45), search_input.height (X-46).
    pub const HEADER_PADDING: Pixels = px(16.);
    pub const HEADER_GAP: Pixels = px(16.);
    pub const SEARCH_HEIGHT: Pixels = px(32.);
    // extensions category_bar.gap/padding_y/padding_x (X-48).
    pub const CATEGORY_GAP: Pixels = px(8.);
    pub const CATEGORY_PADDING_Y: Pixels = px(10.);
    // extensions list.padding_x/padding_bottom, card.* (X-49).
    pub const LIST_PADDING: Pixels = px(16.);
    pub const CARD_MARGIN: Pixels = px(16.);
    pub const CARD_HEIGHT: Pixels = px(110.);
    pub const CARD_PADDING: Pixels = px(12.);
    pub const CARD_GAP: Pixels = px(8.);
    pub const CARD_RADIUS: Pixels = px(6.);
}

// ---- 타이틀 바·창 버튼 (px 예외, SPEC R-15 이후 변경) ----

/// L-21 타이틀 바 높이 (Windows 32 고정). A-32.1.
pub const TITLE_BAR_HEIGHT: Pixels = px(32.);
/// L-82 타이틀 바 왼쪽 padding `pl_2` = 8.
pub const TITLE_BAR_PADDING_LEFT: Pixels = px(8.);
/// L-39 창 버튼 각 36×32, 글리프 10. A-32.2.
pub const WINDOW_BUTTON_WIDTH: Pixels = px(36.);
pub const WINDOW_BUTTON_HEIGHT: Pixels = px(32.);
pub const WINDOW_BUTTON_GLYPH_SIZE: Pixels = px(10.);
/// L-311 클라이언트 장식의 모서리 둥글림 10px.
pub const WINDOW_ROUNDING: Pixels = px(10.);
/// G-103 최소 창 크기 360×240.
pub const WINDOW_MIN_SIZE: Size<Pixels> = Size {
    width: px(360.),
    height: px(240.),
};
/// Initial client size: core v0.5 ITEMS I-6.
pub const WINDOW_INITIAL_SIZE: Size<Pixels> = Size {
    width: px(1440.),
    height: px(852.),
};

// ---- 공통 (rem 헬퍼) ----

/// L-06 아이콘 Small 14. A-32.16(탭 바·상태 표시줄 아이콘), L-35(사이드바 푸터 아이콘).
pub const ICON_SMALL: Rems = rems_from_px(14.);
/// L-07 버튼 Default 높이 22 (아이콘 버튼은 22×22 정사각형으로 둔다).
pub const BUTTON_DEFAULT: Rems = rems_from_px(22.);

// ---- 탭 바 (A-32.3~A-32.6) ----

/// L-22 탭 바 높이 32. A-32.3.
pub const TAB_BAR_HEIGHT: Rems = rems_from_px(32.);
/// L-23 탭 내용 높이 31 (= 32 − 아래 테두리 1). A-32.3.
pub const TAB_CONTENT_HEIGHT: Rems = rems_from_px(31.);
/// L-24 탭 안쪽 좌우 padding 4, 요소 gap 4. A-32.4.
pub const TAB_PADDING_X: Rems = rems_from_px(4.);
pub const TAB_GAP: Rems = rems_from_px(4.);
/// L-25 탭 시작 슬롯 12×12, 끝 슬롯 14×14. A-32.5.
pub const TAB_START_SLOT: Rems = rems_from_px(12.);
/// tab["indicator_size"] (L-65) 수정 표시 점 지름 10, 시작 슬롯 12 가운데.
pub const TAB_INDICATOR_SIZE: Rems = rems_from_px(10.);
pub const TAB_END_SLOT: Rems = rems_from_px(14.);
/// L-27 탭 바 양 끝 버튼 영역: 좌우 padding 6, gap 4. A-32.6.
pub const TAB_BAR_EDGE_PADDING_X: Rems = rems_from_px(6.);
pub const TAB_BAR_EDGE_GAP: Rems = rems_from_px(4.);

// ---- 상태 표시줄 (A-32.7·A-32.8) ----

/// L-28 상태 표시줄 padding 4 (× 2 + 버튼 22 = 높이 30). A-32.7.
pub const STATUS_BAR_PADDING: Rems = rems_from_px(4.);
/// L-29 좌·우 그룹 사이 8, 그룹 안 gap 4. A-32.8.
pub const STATUS_BAR_GROUP_GAP: Rems = rems_from_px(8.);
pub const STATUS_BAR_ITEM_GAP: Rems = rems_from_px(4.);

// ---- 왼쪽 Dock (A-32.9·A-32.10) ----

/// L-30 Dock 리사이즈 핸들 6 (테두리 위에 절반씩 걸친다). L-31 Dock 폭 하한도 핸들 6. A-32.9.
pub const DOCK_HANDLE_WIDTH: Rems = rems_from_px(6.);
/// L-32 프로젝트 패널(왼쪽 Dock) 기본 폭 240. 핸들 더블클릭 시 이 값으로 돌아간다. A-32.10.
pub const DOCK_DEFAULT_WIDTH: Rems = rems_from_px(240.);

// ---- 사이드바 (A-32.11~A-32.13) ----

/// L-33 사이드바 폭: 기본 300, 범위 200~800. A-32.11.
pub const SIDEBAR_DEFAULT_WIDTH: Rems = rems_from_px(300.);
pub const SIDEBAR_MIN_WIDTH: Rems = rems_from_px(200.);
pub const SIDEBAR_MAX_WIDTH: Rems = rems_from_px(800.);
/// L-34 사이드바 폴더(프로젝트 헤더) 줄: 높이 31, 왼쪽 padding 8, 오른쪽 6. A-32.12.
pub const SIDEBAR_ROW_HEIGHT: Rems = rems_from_px(31.);
pub const SIDEBAR_ROW_PADDING_LEFT: Rems = rems_from_px(8.);
pub const SIDEBAR_ROW_PADDING_RIGHT: Rems = rems_from_px(6.);
/// L-35 사이드바 푸터: padding 4, gap 4, 위 테두리 1. A-32.13.
/// sidebar["footer.height"] (A-11.4): 30 in total, the top border included (same as the status bar).
pub const SIDEBAR_FOOTER_HEIGHT: Rems = rems_from_px(30.);
pub const SIDEBAR_FOOTER_PADDING: Rems = rems_from_px(4.);
pub const SIDEBAR_FOOTER_GAP: Rems = rems_from_px(4.);

// ---- 기타 공통 (P2-1) ----
/// spacing["base01"] (L-03) 1px 테두리 두께를 rem 으로 둔 값. 탭 아래 테두리 `pb_px`(L-63).
pub const BORDER_1PX: Rems = rems_from_px(1.);
/// typography["size.default"] (L-05) 글자 14. gpui `text_sm()` 는 font_size = rems(0.875) 만 설정한다(줄 높이는 건드리지 않는다).
pub const TEXT_SIZE_DEFAULT: Rems = rems_from_px(14.);
/// typography["size.small"] (L-05) 글자 12. gpui `text_xs()` 는 font_size = rems(0.75) 만 설정한다(줄 높이는 건드리지 않는다).
pub const TEXT_SIZE_SMALL: Rems = rems_from_px(12.);
/// I-14 UI font size sets the window rem baseline, not individual element sizes.
pub const UI_FONT_SIZE: Rems = rems_from_px(16.);
/// titlebar["left_group.gap"] (L-87) 타이틀 바 왼쪽 그룹 gap 2 (`gap_0p5`).
pub const TITLE_BAR_LEFT_GROUP_GAP: Rems = rems_from_px(2.);
/// scrollbar["width.editor"] (L-308) editor scrollbar track width 15 (gpui-base default 16). Pixels: gpui-base track width type.
pub const EDITOR_SCROLLBAR_WIDTH: Pixels = px(15.);
/// typography["buffer_font_size"] (L-08) tab editor font size 15 (gpui-kit Editor default: theme mono size).
pub const BUFFER_FONT_SIZE: Pixels = px(15.);
/// editor["line_height.comfortable_multiplier"] (E-010) 1.618 × font size = editor["line_height.comfortable"] 24.27.
pub const BUFFER_LINE_HEIGHT_MULTIPLIER: f32 = 1.618;
/// Zed measurement (tauri ORDER-03-R1, section 2): preview code uses 16px at 1.618 line height.
pub const PREVIEW_CODE_FONT_SIZE: Pixels = px(16.);
pub const PREVIEW_CODE_LINE_HEIGHT_MULTIPLIER: f32 = 1.618;
/// editor["confirm_close.path_max_chars"] (E-081) the unsaved-edits question shows at most 80 characters of the path.
pub const CONFIRM_CLOSE_PATH_MAX_CHARS: usize = 80;
// spec: none (app value) — 타이틀 바 폴더 이름 버튼 좌우 padding 6.
pub const TITLE_FOLDER_NAME_PAD_X: Rems = rems_from_px(6.);
// spec: none (app value) — A-24.2 폴더 목록 저장 디바운스(toml 에 없음).
pub const FOLDERS_SAVE_DEBOUNCE: Duration = Duration::from_millis(500);
// spec: none (app value) — 사이드바 프로젝트 헤더 줄 안 gap 4 (L-34 에 gap 값 없음).
pub const SIDEBAR_ROW_GAP: Rems = rems_from_px(4.);
// spec: none (app value) — 빈 프로젝트·사라진 폴더 안내 화면 버튼(좌우 8, 위아래 4, 모서리 4)과 본문(padding 8, gap 8).
pub const EMPTY_BUTTON_PAD_X: Rems = rems_from_px(8.);
pub const EMPTY_BUTTON_PAD_Y: Rems = rems_from_px(4.);
pub const EMPTY_BUTTON_RADIUS: Rems = rems_from_px(4.);
pub const EMPTY_BODY_PADDING: Rems = rems_from_px(8.);
pub const EMPTY_BODY_GAP: Rems = rems_from_px(8.);
/// ☰ 앱 메뉴·컨텍스트 메뉴 (I-312~I-321, I-501~I-502). 두 메뉴가 같은 상수를 쓴다.
pub mod menu {
    use std::time::Duration;
    use gpui_kit::{Pixels, Rems, px};
    use super::rems_from_px;
    /// menu["min_width"] (I-313) 최소 폭 200 (px 상수).
    pub const MIN_WIDTH: Pixels = px(200.);
    /// menu["max_height_ratio"] (I-313) 최대 높이 = 창 높이 × 0.75.
    pub const MAX_HEIGHT_RATIO: f32 = 0.75;
    /// menu["list_padding_y"] (I-315) 목록 위아래 4.
    pub const LIST_PAD_Y: Rems = rems_from_px(4.);
    /// menu["item.margin_x"] (I-316) 항목 바깥 좌우 4.
    pub const ROW_MARGIN_X: Rems = rems_from_px(4.);
    /// menu["item.padding_x"] (I-316) 항목 안 좌우 6.
    pub const ROW_PAD_X: Rems = rems_from_px(6.);
    /// menu["item.shortcut_min_gap"] (I-316) 라벨–단축키 최소 16.
    pub const SHORTCUT_GAP: Rems = rems_from_px(16.);
    /// menu["item.font_size"] (I-317) 라벨 14.
    pub const ROW_TEXT: Rems = rems_from_px(14.);
    /// units["phi"] (L-09) 줄 높이 배수 1.618 (I-317 의 22.652px = 14 × 1.618).
    pub const ROW_LINE_HEIGHT: f32 = 1.618;
    /// menu["separator.height"] (I-318) 구분선 1.
    pub const SEPARATOR_HEIGHT: Pixels = px(1.);
    /// menu["separator.margin_y"] (I-318) 구분선 위아래 6.
    pub const SEPARATOR_MARGIN_Y: Rems = rems_from_px(6.);
    /// borders["radius.sm"] (L-10) 항목 hover 배경 모서리 4 (메뉴 항목 전용 ID 는 toml 에 없다).
    pub const ROW_RADIUS: Rems = rems_from_px(4.);
    /// menu["corner_radius"] (I-315) 메뉴 모서리 8.
    pub const RADIUS: Rems = rems_from_px(8.);
    /// menu["popup_offset_x"] (I-314) 팝업 x 오프셋 −5.
    pub const POPUP_OFFSET_X: Rems = rems_from_px(-5.);
    /// menu["context.window_margin"] (I-501) 창 가장자리 여유 8.
    pub const WINDOW_MARGIN: Pixels = px(8.);
    /// menu["context.keyboard_offset_x"] (I-502) 키보드로 열 때 x 오프셋 2.
    pub const KEYBOARD_OFFSET_X: Pixels = px(2.);
    /// menu["context.keyboard_offset_y"] (I-502) 키보드로 열 때 y 오프셋 2.
    pub const KEYBOARD_OFFSET_Y: Pixels = px(2.);
    /// menu["horizontal.item_font_size"] (I-321) 메뉴 이름 글자 12.
    pub const NAME_TEXT: Rems = rems_from_px(12.);
    /// menu["horizontal.item_gap"] (I-321) 메뉴 이름 버튼 사이 4.
    pub const NAME_GAP: Rems = rems_from_px(4.);
    // K-12: 4px gap + two 4px pads + font side bearings target a 13–14px ink gap (V3 pending).
    pub const NAME_PAD_X: Rems = rems_from_px(4.);
    // spec: none (app value) — I-520 단축키로 실행할 때 선택 표시 시간 50ms(toml 에 없음).
    pub const SHORTCUT_FLASH: Duration = Duration::from_millis(50);
    // spec: none (app value) — chord 앞부분 대기 1초. gpui-pre 0.3.10 `PENDING_INPUT_TIMEOUT`(crate 비공개)과 같은 값.
    pub const CHORD_TIMEOUT: Duration = Duration::from_secs(1);
}
/// 프로젝트 패널 트리 행 (L-36~L-49, P-019~P-021).
pub mod project_panel {
    use std::time::Duration;
    use gpui_kit::{Pixels, Rems, px};
    use super::rems_from_px;
    /// project_panel["item.height"] (L-36, comfortable) 행 높이 26.
    pub const ROW_HEIGHT: Rems = rems_from_px(26.);
    /// project_panel["indent_step"] (L-37) 단계당 들여쓰기 20.
    pub const INDENT: f32 = 20.;
    /// project_panel["item.padding_x"] (L-37) 안쪽 좌우 6.
    pub const ROW_PAD_X: Rems = rems_from_px(6.);
    /// project_panel["item.gap"] (L-37) gap 4.
    pub const ROW_GAP: Rems = rems_from_px(4.);
    /// icons["size.medium"] (L-06, L-40) 파일·폴더 아이콘 16.
    pub const ICON: Rems = rems_from_px(16.);
    /// project_panel["indent_guide.offset_x"] (L-38) 안내선 x = 깊이 × 20 + 15.
    pub const GUIDE_OFFSET: f32 = 15.;
    /// project_panel["indent_guide.padding_y"] (L-38) 안내선 구간 위아래 여백 4.
    pub const GUIDE_INSET: Rems = rems_from_px(4.);
    /// project_panel["indent_guide.width"] (L-38) 안내선 폭 1.
    pub const GUIDE_WIDTH: Pixels = px(1.);
    /// project_panel["collapsed_path.padding_x"] (L-43) 접힌 경로 조각 좌우 padding 2.
    pub const SEGMENT_PAD_X: Rems = rems_from_px(2.);
    // spec: none (app value) — 접힌 경로 조각 hover 배경 모서리 2.
    pub const SEGMENT_RADIUS: Rems = rems_from_px(2.);
    /// inline_input["height"] (P-019) 입력칸 높이 24.
    pub const INPUT_HEIGHT: Rems = rems_from_px(24.);
    /// inline_input["banner.padding_y"] (P-021) 배너 위아래 4.
    pub const BANNER_PAD_Y: Rems = rems_from_px(4.);
    /// inline_input["banner.padding_x"] (P-021) 배너 좌우 8.
    pub const BANNER_PAD_X: Rems = rems_from_px(8.);
    /// typography["size.default"] (L-05, P-021) 배너 글자 14.
    pub const BANNER_TEXT: Rems = rems_from_px(14.);
    // spec: none (app value) — P-021 배너 왼쪽 −1·오른쪽 −0.5 오프셋(행 테두리 폭에 맞춤, toml 에 없음).
    pub const BANNER_OFFSET_LEFT: Pixels = px(-1.);
    pub const BANNER_OFFSET_RIGHT: Pixels = px(-0.5);
    /// project_panel["name_tooltip_delay"] (L-49, L-247) 항목 이름 툴팁 지연 1500ms.
    pub const NAME_TOOLTIP_DELAY: Duration = Duration::from_millis(1500);
}
/// 툴팁 외형 (L-209~L-232).
pub mod tooltip {
    use gpui_kit::{Pixels, Rems, px};
    use super::rems_from_px;
    /// tooltip["transparent_margin_left"] (L-209) 투명 여백 왼쪽 8.
    pub const OUTER_PAD_LEFT: Rems = rems_from_px(8.);
    /// tooltip["transparent_margin_top"] (L-209) 투명 여백 위 10.
    pub const OUTER_PAD_TOP: Rems = rems_from_px(10.);
    /// tooltip["padding_y"] (L-213) 안쪽 위아래 4.
    pub const PAD_Y: Rems = rems_from_px(4.);
    /// tooltip["padding_x"] (L-213) 안쪽 좌우 8.
    pub const PAD_X: Rems = rems_from_px(8.);
    /// tooltip["font_size"] (L-214) 글자 14.
    pub const TEXT_SIZE: Rems = rems_from_px(14.);
    /// tooltip["meta.font_size"] (L-216) 메타 줄 12.
    pub const META_TEXT_SIZE: Rems = rems_from_px(12.);
    /// tooltip["title.max_width"] (L-215) 제목 최대 폭 288(추정).
    pub const TITLE_MAX_WIDTH: Rems = rems_from_px(288.);
    /// tooltip["title.shortcut_gap"] (L-215) 제목–단축키 gap 16.
    pub const SHORTCUT_GAP: Rems = rems_from_px(16.);
    /// tooltip["corner_radius"] (L-211) 모서리 8 (`rounded_lg` 0.5rem).
    pub const RADIUS: Rems = rems_from_px(8.);
    // spec: none (app value) — L-232 두 줄 툴팁: 줄 안 gap 8, 줄 사이 gap 4, 구분선 위 padding 4, 구분선 1(toml 에 없음).
    pub const TWO_LINE_ROW_GAP: Rems = rems_from_px(8.);
    pub const TWO_LINE_GAP: Rems = rems_from_px(4.);
    pub const TWO_LINE_SEPARATOR_PAD_TOP: Rems = rems_from_px(4.);
    pub const TWO_LINE_SEPARATOR_HEIGHT: Pixels = px(1.);
    // spec: none (app value) — L-212 `elevation_2` 그림자 두 겹의 offset·blur(toml 에 없음). 0 값은 `Pixels::ZERO`.
    pub const SHADOW_1_OFFSET_Y: Pixels = px(2.);
    pub const SHADOW_1_BLUR: Pixels = px(3.);
    pub const SHADOW_2_OFFSET_Y: Pixels = px(1.);
}
/// App timers and delays (QUIET, TICK, retry, ...). None are Zed values, so all are `spec: none`.
pub mod timing {
    use std::time::Duration;
    // spec: none (app value) — apply watch events once quiet for this long after the last one (judgement).
    pub const QUIET: Duration = Duration::from_millis(150);
    // spec: none (app value) — a close request gives up waiting for a running save after this long (P3-3-R2, judgement).
    pub const CLOSE_SAVE_WAIT_LIMIT: Duration = Duration::from_secs(10);
    // spec: none (app value) — apply watch events this long after the first even if they keep coming (judgement).
    pub const MAX_WAIT: Duration = Duration::from_millis(1000);
    // spec: none (app value) — delay before one more full reload after an event flood (judgement).
    pub const SETTLE: Duration = Duration::from_millis(500);
    // spec: none (app value) — how long the app's own file-op paths are remembered (judgement).
    pub const SELF_WINDOW: Duration = Duration::from_millis(3000);
    // spec: none (app value) — app op records are dropped after this long (D-047 a).
    pub const KEEP_RECORDS: Duration = Duration::from_secs(60);
    // spec: none (app value) — the watcher may report an event slightly before the app records its op; look back this far.
    pub const RECORD_SLACK: Duration = Duration::from_millis(1000);
    // spec: none (app value) — A-24.4 state file write retry delay.
    pub const STATE_RETRY_DELAY: Duration = Duration::from_millis(50);
    // spec: none (app value) — watch loop tick (judgement).
    pub const WATCH_TICK: Duration = Duration::from_millis(100);
    // spec: none (app value) — a tick gap longer than this is logged in dev output.
    pub const WATCH_TICK_LATE: Duration = Duration::from_millis(250);
    // spec: none (app value) — keymap file watcher channel poll interval.
    pub const KEYMAP_POLL: Duration = Duration::from_millis(100);
    // spec: none (app value) — keymap file events are batched until quiet for this long.
    pub const KEYMAP_QUIET: Duration = Duration::from_millis(150);
    // spec: none (app value) — `--dev-layout` dump poll interval.
    pub const LAYOUT_DUMP_POLL: Duration = Duration::from_millis(300);
    // spec: none (app value) — retry delay after parent watch registration fails (judgement).
    pub const EXTRA_RETRY: Duration = Duration::from_millis(1000);
    // spec: none (app value) — delay before dev checks start after the window opens.
    pub const DEV_CHECKS_DELAY: Duration = Duration::from_millis(800);
}
/// Test helper: look up spec values by ID (`table["key"]`) in `spec/zed-metrics.toml`.
#[cfg(test)]
pub mod spec {
    const SPEC_TOML: &str = include_str!(concat!(env!("CARGO_MANIFEST_DIR"), "/spec/zed-metrics.toml"));

    /// One spec entry: `{ value, unit, cond, src }`.
    #[derive(Debug, Clone, PartialEq)]
    pub struct Entry {
        pub value: f64,
        pub unit: String,
        pub cond: String,
        pub src: String,
    }

    fn not_found(id: &str) -> String {
        format!("spec id not found: {id} (spec/zed-metrics.toml)")
    }

    /// Looks up an ID like `titlebar["height"]` (table path joined by dots, key quoted).
    pub fn lookup(id: &str) -> Result<Entry, String> {
        let table: toml::Table = SPEC_TOML.parse().map_err(|e| format!("spec parse error: {e}"))?;
        let (path, key) = id
            .strip_suffix("\"]")
            .and_then(|s| s.split_once("[\""))
            .ok_or_else(|| not_found(id))?;
        let mut cur = &table;
        for part in path.split('.') {
            cur = cur.get(part).and_then(|v| v.as_table()).ok_or_else(|| not_found(id))?;
        }
        let e = cur.get(key).and_then(|v| v.as_table()).ok_or_else(|| not_found(id))?;
        let value = e.get("value").and_then(|v| v.as_float().or_else(|| v.as_integer().map(|i| i as f64)));
        let text = |k: &str| e.get(k).and_then(|v| v.as_str()).map(str::to_owned);
        match (value, text("unit"), text("cond"), text("src")) {
            (Some(value), Some(unit), Some(cond), Some(src)) => Ok(Entry { value, unit, cond, src }),
            _ => Err(not_found(id)),
        }
    }

    /// Tolerance for a spec unit from `verification.tolerance` (dimension ±1.0 px, font_size ±0.5 px);
    /// other units (ms, count, chars, ratio) must match exactly.
    fn tolerance(unit: &str, font: bool) -> f64 {
        if unit != "px" {
            return 0.0;
        }
        let id = if font { "verification.tolerance[\"font_size\"]" } else { "verification.tolerance[\"dimension\"]" };
        lookup(id).expect("tolerance entry").value
    }

    /// Asserts `actual` (logical px) equals the spec value within tolerance and the spec cond matches.
    /// Failure messages: `spec id not found`, `spec cond mismatch`, `spec mismatch` (ID first, one line).
    #[track_caller]
    pub fn assert_spec(id: &str, expected_cond: &str, actual: f32) {
        let e = lookup(id).unwrap_or_else(|m| panic!("{m}"));
        if e.cond != expected_cond {
            panic!("spec cond mismatch: {id} expected cond={expected_cond}, spec cond={}", e.cond);
        }
        let tol = tolerance(&e.unit, id.starts_with("typography[") || id.contains("font_size"));
        if (f64::from(actual) - e.value).abs() > tol {
            panic!(
                "spec mismatch: {id} expected {} {} (±{tol}, cond={}, src={}), actual {actual} {}",
                e.value, e.unit, e.cond, e.src, e.unit
            );
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn spec_missing_id_error_names_the_id() {
        for id in ["titlebar[\"no_such_key\"]", "no_such_table[\"height\"]"] {
            let err = spec::lookup(id).unwrap_err();
            assert!(err.contains(&format!("spec id not found: {id}")), "{err}");
        }
    }

    #[test]
    fn spec_lookup_and_titlebar() {
        let e = spec::lookup("titlebar[\"height\"]").unwrap();
        assert_eq!((e.value, e.unit.as_str(), e.cond.as_str()), (32.0, "px", "default"));
        assert!(e.src.contains("L-21"));
        spec::assert_spec("titlebar[\"height\"]", "default", f32::from(TITLE_BAR_HEIGHT));
        spec::assert_spec("titlebar[\"window_button.width\"]", "default", f32::from(WINDOW_BUTTON_WIDTH));
        spec::assert_spec("titlebar[\"window_button.height\"]", "default", f32::from(WINDOW_BUTTON_HEIGHT));
        assert_eq!(
            spec::lookup("titlebar[\"heigth\"]").unwrap_err(),
            "spec id not found: titlebar[\"heigth\"] (spec/zed-metrics.toml)"
        );
        assert!(spec::lookup("nope.table[\"x\"]").is_err());
    }

    #[test]
    #[should_panic(expected = "spec cond mismatch: titlebar[\"height\"]")]
    fn spec_cond_mismatch_fails() {
        spec::assert_spec("titlebar[\"height\"]", "other", 32.0);
    }

    #[test]
    #[should_panic(expected = "spec mismatch: titlebar[\"height\"]")]
    fn spec_value_mismatch_fails() {
        spec::assert_spec("titlebar[\"height\"]", "default", 34.0);
    }

    #[test]
    #[should_panic(expected = "spec mismatch: statusbar[\"cursor_position.font_size\"]")]
    fn spec_font_size_tolerance_applies_to_font_size_ids() {
        // 12.75 differs from 12 by more than the font_size tolerance (0.5).
        spec::assert_spec("statusbar[\"cursor_position.font_size\"]", "default", 12.75);
    }

    /// V2: sidebar constants equal the spec exactly (D-3: values inside the tolerance are matched too).
    #[test]
    fn sidebar_metrics_equal_spec_exactly() {
        for (id, rems) in [
            ("sidebar[\"default_width\"]", SIDEBAR_DEFAULT_WIDTH),
            ("sidebar[\"footer.height\"]", SIDEBAR_FOOTER_HEIGHT),
            ("sidebar[\"footer.padding\"]", SIDEBAR_FOOTER_PADDING),
            ("sidebar[\"footer.gap\"]", SIDEBAR_FOOTER_GAP),
        ] {
            let e = spec::lookup(id).unwrap();
            assert_eq!(f64::from(rems.0 * crate::ui::rem::BASE_REM_PX), e.value, "{id}");
        }
    }

    /// V2 (P2-2): the code's menu row line height and tab content height equal the spec before any pixel snapping.
    /// The measured 23 (menu row) and 32 (tab outer box) come from gpui snapping to device pixels and from the
    /// 1px bottom border/blank around the 31px content, not from different code values.
    #[test]
    fn menu_line_height_and_tab_content_equal_spec() {
        let base = crate::ui::rem::BASE_REM_PX;
        let line = menu::ROW_TEXT.0 * base * menu::ROW_LINE_HEIGHT;
        let spec_line = spec::lookup("menu[\"item.line_height\"]").unwrap().value;
        assert!((f64::from(line) - spec_line).abs() < 1e-3, "{line} vs {spec_line}");
        let tab = spec::lookup("tab[\"content_height\"]").unwrap().value;
        assert_eq!(f64::from(TAB_CONTENT_HEIGHT.0 * base), tab);
    }
}

#[cfg(test)]
mod tab_indicator_tests {
    /// V2: dirty dot size is the spec value (L-65).
    #[test]
    fn tab_indicator_size_is_spec() {
        let px = super::TAB_INDICATOR_SIZE.0 * 16.0;
        super::spec::assert_spec("tab[\"indicator_size\"]", "default", px);
    }
}

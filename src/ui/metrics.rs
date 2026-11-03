//! 창·레이아웃 치수. 값은 01-zed 01-LAYOUT·04-APP-SPEC 의 항목 ID 원문 값이다(논리 px, rem 16 기준).
//!
//! - 타이틀 바·창 버튼(L-21, L-39, L-82): Windows 타이틀 바는 rem 과 무관하게 32 고정이라(L-21)
//!   px 로 둔다. SPEC R-15 "이후 변경"이 A-32.1·A-32.2 를 rem 헬퍼 예외로 허용했다.
//! - 그 밖의 레이아웃 치수(A-32.3~A-32.13, A-32.16 의 14): 모두 rem 헬퍼(`rems_from_px`)로 정의한다.
//! - 1px 테두리는 gpui 의 `border_*_1` 을 쓴다(Zed 도 `border_*_1` 1px 고정, L-16·L-27·L-35·L-301~L-303).

use gpui_kit::{Pixels, Rems, Size, px};

use super::rem::rems_from_px;

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
pub const SIDEBAR_FOOTER_PADDING: Rems = rems_from_px(4.);
pub const SIDEBAR_FOOTER_GAP: Rems = rems_from_px(4.);

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
        let tol = tolerance(&e.unit, id.starts_with("typography") && id.contains("size"));
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
}

//! 툴팁 뷰 (v0.2 Phase 2, SPEC R-5~R-7, DECISIONS D-5 이후 변경·D-031 ②).
//!
//! 시점·위치·뒤집기는 gpui 의 `.tooltip()` 장치가 맡는다. gpui-pre 0.3.10 의 기본값이 01-zed 와 같다:
//! 지연 500ms(L-206, `elements/div.rs` 53행), 마우스 + (1, 1)(L-208, `window.rs` 3835행),
//! 창을 넘으면 커서 왼쪽·위쪽으로 뒤집기(L-210, `window.rs` 3841~3860행), 벗어남·누름·스크롤로 사라짐(L-207).
//! 이 모듈은 그 안에 넣는 상자만 그린다.
//!
//! - L-209 바깥 상자의 투명 여백 왼쪽 8·위 10 (보이는 상자는 커서에서 약 (9, 11)).
//! - L-211 `elevation_2`: 모서리 8, 테두리 1, L-212 그림자 두 겹.
//! - L-213 안쪽 여백 위아래 4·좌우 8, L-214 글자 14px.
//! - L-215 [제목(최대 폭 288)] … [단축키], 둘 사이 gap 16. L-216 메타 줄 12px Muted.
//! - L-232 두 줄 툴팁: 줄마다 gap 8 양끝 정렬, 두 줄 사이 gap 4, 사이 구분선(위 padding 4, 1px).
//! - 단축키 글자는 우리 표시 문자열(L-219~L-221). 바인딩이 없으면 제목만(L-223).
//!
//! 색 토큰은 테마 매핑(PoC 7단계) 전이라 gpui-kit 기본 테마의 가까운 토큰을 쓴다(R-6 판정 대상 아님).

use std::time::{SystemTime, UNIX_EPOCH};

use gpui_kit::component::{ActiveTheme as _, h_flex, v_flex};
use gpui_kit::prelude::FluentBuilder as _;
use gpui_kit::*;

use super::keymap;
use super::layout_probe;
use super::metrics::tooltip::*;

/// 툴팁 한 줄: 제목과 (있으면) 단축키 액션.
#[derive(Clone)]
pub struct Line {
    pub title: SharedString,
    pub action: Option<&'static str>,
}

impl Line {
    pub fn text(title: impl Into<SharedString>) -> Self {
        Self {
            title: title.into(),
            action: None,
        }
    }

    pub fn action(title: impl Into<SharedString>, action: &'static str) -> Self {
        Self {
            title: title.into(),
            action: Some(action),
        }
    }
}

/// 툴팁 내용.
#[derive(Clone)]
pub struct Spec {
    /// dev 출력과 레이아웃 탐침에서 쓰는 요소 이름.
    pub id: &'static str,
    /// 한 줄이면 L-200·L-201, 두 줄이면 L-232(L-204 임의 요소).
    pub lines: Vec<Line>,
    /// L-203·L-216 메타 줄.
    pub meta: Option<SharedString>,
}

impl Spec {
    pub fn one(id: &'static str, line: Line) -> Self {
        Self {
            id,
            lines: vec![line],
            meta: None,
        }
    }

    pub fn two(id: &'static str, first: Line, second: Line) -> Self {
        Self {
            id,
            lines: vec![first, second],
            meta: None,
        }
    }
}

struct TooltipView {
    id: &'static str,
    /// (제목, 단축키 표시 문자열).
    lines: Vec<(SharedString, Option<String>)>,
    meta: Option<SharedString>,
}

fn now_ms() -> u128 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis())
        .unwrap_or_default()
}

/// 요소에 `.tooltip(tooltip::build(spec))` 로 붙인다. gpui 가 지연이 지난 뒤 이 함수를 불러 뷰를 만든다.
pub fn build(spec: Spec) -> impl Fn(&mut Window, &mut App) -> AnyView + 'static {
    move |window, cx| {
        let lines: Vec<(SharedString, Option<String>)> = spec
            .lines
            .iter()
            .map(|line| {
                let shortcut = line
                    .action
                    .and_then(|name| keymap::shortcut_for_name(name, None, window, cx));
                (line.title.clone(), shortcut)
            })
            .collect();
        if keymap::dev_enabled(cx) {
            let mouse = window.mouse_position();
            let rows = lines
                .iter()
                .map(|(t, s)| format!("{t}|{}", s.as_deref().unwrap_or("<none>")))
                .collect::<Vec<_>>()
                // 줄 구분은 탭(단축키 글자 `;` 와 겹치지 않게).
                .join("\t");
            println!(
                "[dev] tooltip-shown id={} t_ms={} mouse={:.2},{:.2} rows={rows}",
                spec.id,
                now_ms(),
                f32::from(mouse.x),
                f32::from(mouse.y)
            );
        }
        let id = spec.id;
        cx.new(|_| TooltipView {
            id,
            lines,
            meta: spec.meta.clone(),
        })
        .into()
    }
}

impl Drop for TooltipView {
    fn drop(&mut self) {
        layout_probe::forget("tooltip-box");
        if layout_probe::is_enabled() || keymap::dev_flag() {
            println!("[dev] tooltip-hidden id={} t_ms={}", self.id, now_ms());
        }
    }
}

/// L-211·L-212 `elevation_2` 그림자 두 겹(라이트 3% / 다크 6%).
pub fn elevation_2_shadow(is_dark: bool) -> Vec<BoxShadow> {
    vec![
        BoxShadow {
            color: super::theme::elevation_2_shadow_1(),
            offset: point(Pixels::ZERO, SHADOW_1_OFFSET_Y),
            blur_radius: SHADOW_1_BLUR,
            spread_radius: Pixels::ZERO,
            inset: false,
        },
        BoxShadow {
            color: super::theme::elevation_2_shadow_2(is_dark),
            offset: point(Pixels::ZERO, SHADOW_2_OFFSET_Y),
            blur_radius: Pixels::ZERO,
            spread_radius: Pixels::ZERO,
            inset: false,
        },
    ]
}

fn line_row(title: SharedString, shortcut: Option<String>, gap: Rems, muted: Hsla) -> Div {
    h_flex()
        .w_full()
        .justify_between()
        .gap(gap)
        .child(div().max_w(TITLE_MAX_WIDTH).child(title))
        .when_some(shortcut, |row, s| {
            row.child(div().flex_shrink_0().text_color(muted).child(s))
        })
}

impl Render for TooltipView {
    fn render(&mut self, _window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let theme = cx.theme();
        let muted = theme.muted_foreground;
        let border = theme.border;
        let two_line = self.lines.len() > 1;

        let mut body = v_flex();
        if two_line {
            body = body.gap(TWO_LINE_GAP);
            for (i, (title, shortcut)) in self.lines.iter().enumerate() {
                if i > 0 {
                    body = body.child(
                        div()
                            .pt(TWO_LINE_SEPARATOR_PAD_TOP)
                            .child(div().w_full().h(TWO_LINE_SEPARATOR_HEIGHT).bg(border)),
                    );
                }
                body = body.child(line_row(
                    title.clone(),
                    shortcut.clone(),
                    TWO_LINE_ROW_GAP,
                    muted,
                ));
            }
        } else if let Some((title, shortcut)) = self.lines.first() {
            body = body.child(line_row(title.clone(), shortcut.clone(), SHORTCUT_GAP, muted));
        }
        body = body.when_some(self.meta.clone(), |b, meta| {
            b.child(
                div()
                    .max_w(TITLE_MAX_WIDTH)
                    .text_size(META_TEXT_SIZE)
                    .text_color(muted)
                    .child(meta),
            )
        });

        // 바깥 상자(투명 여백) → 보이는 상자. 보이는 상자의 경계를 탐침으로 남긴다.
        div()
            .pl(OUTER_PAD_LEFT)
            .pt(OUTER_PAD_TOP)
            .on_children_prepainted(layout_probe::probe(&["tooltip-box"]))
            .child(
                div()
                    .bg(theme.popover)
                    .text_color(theme.popover_foreground)
                    .border_1()
                    .border_color(border)
                    .rounded(RADIUS)
                    .shadow(elevation_2_shadow(theme.is_dark()))
                    .py(PAD_Y)
                    .px(PAD_X)
                    .text_size(TEXT_SIZE)
                    .child(body),
            )
    }
}

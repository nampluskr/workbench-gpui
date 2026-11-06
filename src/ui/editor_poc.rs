//! Phase 2 편집기 PoC 화면 (SPEC R-6~R-11, 02-gpui G-100·G-101·G-102·G-129·G-139).
//!
//! 디버그 빌드의 `--dev-editor-poc` 계열 플래그로만 뜬다(`crate::dev`). 사용자 기능이 아니다.
//! gpui-kit 0.8.1 의 `Input`(한 줄)과 `Editor`(여러 줄 코드 편집기)를 그대로 두고, 측정 결과를
//! 표준출력에 `[dev] ...` 한 줄씩 낸다. 좌표는 창 기준 논리 px 다.

use std::cell::Cell;
use std::rc::Rc;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::time::{Duration, Instant};

use gpui_kit::component::input::{
    Editor, EditorState, Input, InputEvent, InputState, Position, RopeExt as _,
};
use gpui_kit::component::{ActiveTheme as _, v_flex};
use gpui_kit::*;

use crate::dev::{self, DevOptions};

/// R-10 측정용 줄. 0: 영문(아래로 내려가는 글자 없음), 1: 한글, 2: 한글 혼합. 세 줄 모두 10글자 안팎이다.
const MEASURE_LINES: [&str; 3] = ["abcdehiklm", "가나다라마바사아자차", "abc가나다def"];

/// 파일 없이 열 때의 기본 내용.
fn default_text() -> String {
    let mut text = MEASURE_LINES.join("\n");
    text.push_str("\n\nfn main() {\n    println!(\"hello 안녕\");\n}\n");
    text
}

pub struct EditorPoc {
    input: Entity<InputState>,
    editor: Entity<EditorState>,
    _subscriptions: Vec<Subscription>,
}

impl EditorPoc {
    pub fn new(options: DevOptions, window: &mut Window, cx: &mut Context<Self>) -> Self {
        let input = cx.new(|cx| InputState::new(window, cx).placeholder("Input (single line)"));
        let editor = cx.new(|cx| EditorState::new(window, cx).soft_wrap(!options.no_wrap));

        let subscriptions = vec![
            cx.subscribe(&input, |_, state, event: &InputEvent, cx| {
                if matches!(event, InputEvent::Change) {
                    println!(
                        "[dev] value field=input text={:?}",
                        state.read(cx).value().as_ref()
                    );
                }
            }),
            cx.subscribe(&editor, |_, state, event: &InputEvent, cx| {
                if matches!(event, InputEvent::Change) {
                    let state = state.read(cx);
                    let text = state.text();
                    // 큰 파일에서 출력이 넘치지 않게 앞부분만 낸다.
                    let head: String = text.to_string().chars().take(200).collect();
                    println!(
                        "[dev] value field=editor len={} head={:?}",
                        text.len(),
                        head
                    );
                }
            }),
        ];

        let this = Self {
            input,
            editor,
            _subscriptions: subscriptions,
        };
        this.load(&options, window, cx);
        this.schedule(options, window, cx);
        this
    }

    /// 파일(또는 기본 내용)을 Editor 에 넣는다. R-8 은 읽기·변환·set_value 시간을 낸다.
    fn load(&self, options: &DevOptions, window: &mut Window, cx: &mut Context<Self>) {
        let Some(path) = options.poc_file.clone() else {
            let text = default_text();
            self.editor
                .update(cx, |state, cx| state.set_value(text.as_str(), window, cx));
            return;
        };

        let t_read = Instant::now();
        let bytes = match std::fs::read(&path) {
            Ok(bytes) => bytes,
            Err(err) => {
                println!("[dev] load result=error path={path:?} error={err:?}");
                return;
            }
        };
        let read_ms = ms(t_read);

        let t_decode = Instant::now();
        let (text, encoding) = match dev::decode(&bytes, options.roundtrip_mode) {
            Ok(decoded) => decoded,
            Err(err) => {
                println!(
                    "[dev] load result=error path={path:?} mode={} error={err:?}",
                    options.roundtrip_mode.name()
                );
                return;
            }
        };
        let decode_ms = ms(t_decode);

        let t_set = Instant::now();
        self.editor
            .update(cx, |state, cx| state.set_value(text.as_str(), window, cx));
        let set_value_ms = ms(t_set);

        let lines = self.editor.read(cx).text().lines_len();
        println!(
            "[dev] load result=ok path={path:?} mode={} encoding={} bytes={} chars={} lines={lines} read_ms={read_ms:.2} decode_ms={decode_ms:.2} set_value_ms={set_value_ms:.2}",
            options.roundtrip_mode.name(),
            encoding.name(),
            bytes.len(),
            text.chars().count(),
        );

        // set_value 뒤 첫 프레임의 draw·present 가 끝날 때까지 (R-8). 방법은 after_present 설명.
        let t_frame = Instant::now();
        after_present(window, move |drawn| {
            println!(
                "[dev] perf first_frame_after_set_value_ms={:.2} drawn={drawn}",
                ms(t_frame)
            );
        });

        // R-9: Editor 가 가진 값을 다시 읽어 같은 인코딩으로 저장한다.
        if let Some(out) = options.roundtrip_out.clone() {
            let value = self.editor.read(cx).value();
            let same_text = value.as_ref() == text.as_str();
            match dev::encode(value.as_ref(), encoding).and_then(|out_bytes| {
                std::fs::write(&out, &out_bytes).map_err(|e| format!("write: {e}"))?;
                Ok(out_bytes)
            }) {
                Ok(out_bytes) => println!(
                    "[dev] roundtrip result=ok mode={} encoding={} in_bytes={} out_bytes={} bytes_identical={} editor_value_equals_decoded={same_text} out={out:?}",
                    options.roundtrip_mode.name(),
                    encoding.name(),
                    bytes.len(),
                    out_bytes.len(),
                    out_bytes == bytes,
                ),
                Err(err) => println!(
                    "[dev] roundtrip result=error mode={} error={err:?}",
                    options.roundtrip_mode.name()
                ),
            }
        }
    }

    /// 첫 프레임 뒤에 레이아웃을 내고, 켜진 측정(R-8 perf, R-10 measure)을 차례로 돌린다.
    fn schedule(&self, options: DevOptions, window: &mut Window, cx: &mut Context<Self>) {
        cx.spawn_in(window, async move |this, cx| {
            wait(cx, 600).await;
            let _ = this.update_in(cx, |this, window, cx| this.print_layout(window, cx));
            if options.perf {
                perf(&this, cx).await;
            }
            if options.measure {
                measure(&this, cx).await;
            }
            println!("[dev] poc done");
        })
        .detach();
    }

    /// IME 시험 스크립트가 클릭할 위치 (R-6).
    fn print_layout(&self, window: &mut Window, cx: &mut Context<Self>) {
        let editor = self.editor.read(cx).input_bounds();
        let input = self.input.read(cx).input_bounds();
        println!(
            "[dev] layout scale={} editor={} input={}",
            window.scale_factor(),
            fmt_bounds(editor),
            fmt_bounds(input),
        );
    }
}

impl Render for EditorPoc {
    fn render(&mut self, _: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        RENDERS.fetch_add(1, Ordering::Relaxed);
        v_flex()
            .size_full()
            .p_2()
            .gap_2()
            .bg(cx.theme().background)
            .child(Input::new(&self.input))
            .child(
                div()
                    .flex_1()
                    .min_h_0()
                    .child(Editor::new(&self.editor).font(super::fonts::editor()).text_size(super::metrics::BUFFER_FONT_SIZE).line_height(relative(super::metrics::BUFFER_LINE_HEIGHT_MULTIPLIER)).h_full()),
            )
    }
}

fn ms(start: Instant) -> f64 {
    start.elapsed().as_secs_f64() * 1000.0
}

fn fmt_bounds(b: Bounds<Pixels>) -> String {
    format!(
        "{:.2},{:.2},{:.2},{:.2}",
        f32::from(b.origin.x),
        f32::from(b.origin.y),
        f32::from(b.size.width),
        f32::from(b.size.height)
    )
}

async fn wait(cx: &mut AsyncWindowContext, millis: u64) {
    cx.background_executor()
        .timer(Duration::from_millis(millis))
        .await;
}

/// 다음 프레임의 draw·present 가 끝난 뒤에 `f` 를 부른다.
///
/// gpui-pre 0.3.10 의 프레임 처리(`src/window.rs` 1878~1912행)는 한 프레임 핸들러 안에서
/// ① `on_next_frame` 콜백 실행 → ② `window.draw` → ③ `window.present` 를 차례로 동기 실행한다.
/// 콜백(①) 시점은 그리기 전이라 그대로 재면 그리기 비용이 빠진다. 그래서 콜백 안에서 foreground
/// 작업을 하나 예약한다. 이 작업은 메인 스레드에서 지금 도는 프레임 핸들러가 끝난 뒤(②·③ 이후)에야
/// 실행되므로, 그 시점이 "변경이 그려진 프레임의 draw·present 이후"다.
///
/// `f` 에는 "콜백 뒤에 이 화면이 실제로 다시 그려졌는가"(EditorPoc::render 횟수가 늘었는가)를 넘긴다.
/// 측정마다 이 값을 세어 순서 가정이 맞았는지 출력한다.
fn after_present(window: &Window, f: impl FnOnce(bool) + 'static) {
    window.on_next_frame(move |_, cx| {
        let before = RENDERS.load(Ordering::Relaxed);
        cx.foreground_executor()
            .spawn(async move { f(RENDERS.load(Ordering::Relaxed) > before) })
            .detach();
    });
}

/// EditorPoc::render 가 불린 횟수. gpui 는 그릴 때마다 루트부터 view 의 render 를 다시 부른다.
static RENDERS: AtomicUsize = AtomicUsize::new(0);

/// `change` 를 적용한 뒤 그 변경이 그려진 프레임의 draw·present 가 끝날 때까지의 시간(ms).
/// 2초 안에 끝나지 않으면 None.
async fn frame_after(
    this: &WeakEntity<EditorPoc>,
    cx: &mut AsyncWindowContext,
    change: impl FnOnce(&mut EditorPoc, &mut Window, &mut Context<EditorPoc>) + 'static,
) -> Option<(f64, bool)> {
    let done = Rc::new(Cell::new(None::<(f64, bool)>));
    let done_in = done.clone();
    this.update_in(cx, move |this, window, cx| {
        let start = Instant::now();
        change(this, window, cx);
        after_present(window, move |drawn| done_in.set(Some((ms(start), drawn))));
    })
    .ok()?;
    for _ in 0..200 {
        if done.get().is_some() {
            break;
        }
        wait(cx, 10).await;
    }
    done.get()
}

/// 측정값 요약. `drawn` = 시간을 잰 시점까지 화면이 실제로 다시 그려진 측정 수.
fn summarize(samples: &[(f64, bool)]) -> String {
    if samples.is_empty() {
        return "n=0".into();
    }
    let values: Vec<f64> = samples.iter().map(|s| s.0).collect();
    let drawn = samples.iter().filter(|s| s.1).count();
    let avg = values.iter().sum::<f64>() / values.len() as f64;
    let max = values.iter().cloned().fold(f64::MIN, f64::max);
    let min = values.iter().cloned().fold(f64::MAX, f64::min);
    format!(
        "n={} avg={avg:.2} min={min:.2} max={max:.2} drawn={drawn}",
        values.len()
    )
}

/// R-8: 스크롤 20번, 입력 20번. 각각 변경 → 그 변경이 그려진 프레임의 draw·present 이후까지의 시간.
async fn perf(this: &WeakEntity<EditorPoc>, cx: &mut AsyncWindowContext) {
    let Ok(total_lines) = this.update_in(cx, |this, _, cx| this.editor.read(cx).text().lines_len())
    else {
        return;
    };

    let mut scroll = Vec::new();
    for i in 1..=20u32 {
        // 줄 높이를 모르므로 큰 간격(픽셀)으로 아래로 내린다. 실제로 이동했는지는 보이는 줄 범위로 확인한다.
        let y = -(i as f32) * 25_000.0;
        if let Some(t) = frame_after(this, cx, move |this, _, cx| {
            this.editor.update(cx, |state, cx| {
                state.set_scroll_offset(point(Pixels::ZERO, px(y)), cx)
            });
        })
        .await
        {
            scroll.push(t);
        }
        wait(cx, 30).await;
    }
    let rows = this
        .update_in(cx, |this, _, cx| this.editor.read(cx).visible_row_range())
        .ok()
        .flatten();
    println!(
        "[dev] perf scroll {} last_visible_rows={:?} total_lines={total_lines}",
        summarize(&scroll),
        rows
    );

    let middle = (total_lines / 2) as u32;
    let _ = this.update_in(cx, move |this, window, cx| {
        this.editor.update(cx, |state, cx| {
            state.set_cursor_position(
                Position {
                    line: middle,
                    character: 0,
                },
                window,
                cx,
            )
        });
    });
    wait(cx, 200).await;
    let mut insert = Vec::new();
    for _ in 0..20 {
        if let Some(t) = frame_after(this, cx, |this, window, cx| {
            this.editor
                .update(cx, |state, cx| state.insert("x", window, cx));
        })
        .await
        {
            insert.push(t);
        }
        wait(cx, 30).await;
    }
    println!("[dev] perf insert {} at_line={middle}", summarize(&insert));
}

/// R-10: 줄 높이·글자 폭·거터·커서 위치. 기준선과 글자 폭은 스크린샷 픽셀로 함께 잰다(스크립트 쪽).
async fn measure(this: &WeakEntity<EditorPoc>, cx: &mut AsyncWindowContext) {
    let _ = this.update_in(cx, |this, window, cx| {
        let state = this.editor.read(cx);
        let text = state.text();
        let input = state.input_bounds();
        let text_bounds = state.text_bounds();
        println!(
            "[dev] measure editor scale={} line_height={:?} input_bounds={} text_bounds={} gutter_width={:?}",
            window.scale_factor(),
            state.line_height().map(f32::from),
            fmt_bounds(input),
            text_bounds.map(fmt_bounds).unwrap_or_default(),
            text_bounds.map(|t| f32::from(t.origin.x - input.origin.x)),
        );
        for (row, sample) in MEASURE_LINES.iter().enumerate() {
            let start = text.line_start_offset(row);
            let end = text.line_end_offset(row);
            let line = state.range_to_bounds(&(start..end));
            println!(
                "[dev] measure line row={row} text={sample:?} bytes={} bounds={}",
                end - start,
                line.map(fmt_bounds).unwrap_or_default()
            );
        }
        // 편집기 글꼴로 각 줄을 다시 배치해, 글자 묶음(run)마다 실제로 쓰인 글꼴을 낸다.
        // 한글이 없는 글꼴이면 한글 묶음에 DirectWrite 가 고른 대체 글꼴 이름이 나온다 (G-139).
        let family = cx.theme().mono_font_family.clone();
        let size = cx.theme().mono_font_size;
        for (row, sample) in MEASURE_LINES.iter().enumerate() {
            let run = TextRun {
                len: sample.len(),
                font: font(family.clone()),
                color: super::theme::measure_text(),
                background_color: None,
                underline: None,
                strikethrough: None,
            };
            let layout = window.text_system().layout_line(sample, size, &[run], None);
            let runs: Vec<String> = layout
                .runs
                .iter()
                .map(|r| {
                    let name = window
                        .text_system()
                        .get_font_for_id(r.font_id)
                        .map(|f| f.family.to_string())
                        .unwrap_or_else(|| "?".into());
                    format!("{name}:{}glyphs", r.glyphs.len())
                })
                .collect();
            println!(
                "[dev] measure font row={row} family={family:?} size={} width={:.2} ascent={:.2} descent={:.2} runs={runs:?}",
                f32::from(size),
                f32::from(layout.width),
                f32::from(layout.ascent),
                f32::from(layout.descent),
            );
        }
        // 혼합 줄의 구간: "abc" / "가나다" / "def" (UTF-8 바이트 범위)
        let start = text.line_start_offset(2);
        for (name, range) in [("abc", 0..3), ("ga-na-da", 3..12), ("def", 12..15)] {
            let r = (start + range.start)..(start + range.end);
            println!(
                "[dev] measure segment row=2 name={name} bounds={}",
                state.range_to_bounds(&r).map(fmt_bounds).unwrap_or_default()
            );
        }
    });

    // 각 줄 끝에 커서를 두고 그 프레임 뒤의 커서 사각형을 읽는다.
    for (row, sample) in MEASURE_LINES.iter().enumerate() {
        let chars = sample.encode_utf16().count() as u32;
        let _ = this.update_in(cx, move |this, window, cx| {
            this.editor.update(cx, |state, cx| {
                state.set_cursor_position(
                    Position {
                        line: row as u32,
                        character: chars,
                    },
                    window,
                    cx,
                )
            });
        });
        wait(cx, 300).await;
        let _ = this.update_in(cx, move |this, _, cx| {
            let cursor = this.editor.read(cx).cursor_layout();
            println!(
                "[dev] measure cursor row={row} at_end_of_line cursor={} line_height={:?}",
                cursor.map(|(b, _)| fmt_bounds(b)).unwrap_or_default(),
                cursor.map(|(_, h)| f32::from(h))
            );
        });
    }
}

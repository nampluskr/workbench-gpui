# gpui-base 0.8.1 local patch

- Source: `C:\Users\nampl\.cargo\registry\src\index.crates.io-1949cf8c6b5b557f\gpui-base-0.8.1\` (crates.io gpui-base 0.8.1).
- License: original `LICENSE-APACHE` (Apache-2.0), copied unchanged.
- Authority: workbench-core v0.5 DECISIONS D-14; gpui K-07; I-14 gutter geometry and I-13 line-number colors.
- Version remains 0.8.1. Files not listed below are unchanged copies. No Zed application source was copied.

## Diff summary

| File / function | Change | Reason |
|---|---|---|
| `src/theme.rs` / `EditorGutterTheme` | Add an independent GPUI Global containing normal/active line-number colors; expose `width` and `text_start` geometry helpers. | Keep application theme tokens outside component input-style projection; make geometry testable from the consuming application. |
| `src/lib.rs` | Export `EditorGutterTheme`. | Application-owned theme initialization. |
| `src/input/base/element.rs` / `line_number_len` | Minimum digits 3 → 4; existing unit expectations and test name updated to the new requirement. | Reserve at least four digit cells. |
| `src/input/base/element.rs` / `layout_line_numbers` | For code editors, use 22px + shaped digit cells + 29px + 5px, subtracting existing component left padding once. Keep fold controls within the new right spacing rather than adding another 18px. | Match measured gutter/text positions without changing text size or wrapping algorithms. |
| `src/input/base/element.rs` / `TextElement::prepaint` line-number runs | Resolve normal/active number colors from `EditorGutterTheme`, with original editor-style fallback when no global is installed. | Component reprojects `InputEditorStyle` each render; the independent global survives that operation. Main text colors are unchanged. |
| `src/input/base/element.rs` / `TextElement::paint` line numbers | Offset code-editor number origin to 22px from the outer editor edge, accounting for existing input padding. | Number origin must move independently of the text start. |

## Geometry and verification boundary

At a 9px Lilex cell advance, four digits give gutter 22 + 36 + 29 = 87px, text start 92px. Five digits give gutter 96px, text start 101px. The engine uses the shaped font advance rather than assuming every font has a 9px advance. `width` reserves at least four cells.

The component's 6px code-editor left padding is already present in the input bounds. The internal reserved width subtracts that padding; the number paint origin does the same. This avoids counting it twice. Fold controls remain in the right spacing, and existing cursor/hit-test/scroll geometry consumes the resulting line-number width as before.

Ink edges (57px / 66px) depend on the font's side bearings and rasterization. Final acceptance requires checker V3 at 1440×852, 100%, Lilex 15; calculations alone do not establish ink alignment.

Application integration: root `Cargo.toml` patches only gpui-base to this directory. `src/ui/theme.rs` installs One Light normal `#b4b4bb` and active `#44454b`; application tests `k07_gutter_geometry_and_colors` check handwritten geometry and color expectations. Component source and every other dependency remain unchanged.

## K-23 추가 — 승인(core D-14 확장, 2026-11-07)

core-leader 결정 (A)에 따라 core D-14의 vendor 수정 승인 범위가 '미리보기 클릭 원본 위치 콜백'까지 확장되었다(2026-11-07, 사용자 전달). 아래 text 콜백 변경과 앱의 콜백 연결은 이 승인 범위에 포함된다. 의존성 버전·Cargo.toml·Cargo.lock은 변경하지 않았다.

| File / function | Diff | Reason |
|---|---|---|
| `src/text/text_view.rs` / `TextView`, constructors, `on_source_block_click`, prepaint state update | Add an optional `Arc<dyn Fn(usize, &mut Window, &mut App) + Send + Sync>` callback, default `None`; expose a builder and forward it to the view state. | Report the clicked Markdown block's original source byte offset to the application. |
| `src/text/state.rs` / `TextViewState`, initialization, rendering | Retain the optional callback and pass it into `NodeContext`. | Keep the callback through stateful rendering and updates. |
| `src/text/node.rs` / `NodeContext` | Add the optional callback field. | Carry the callback to document rendering; Send + Sync preserves background parsing compatibility. |
| `src/text/document.rs` / `source_click_block`, `src/text/node.rs` / `render_block`, list item rendering | Optionally wrap each rendered block and list item with a left-mouse capture handler using `block.span().start`; shared by ordinary and virtualized rendering. Return the existing element unchanged if no callback or source span exists. | Map the innermost preview block to source without reparsing separate fragments or losing document reference links. |

The callback does not prevent the original event or stop propagation. Application integration is `src/ui/markdown_preview.rs`: update the preview tab editor's byte cursor to the source line start; `src/ui/status.rs::position` converts it to a one-based source line and column 1. No Zed code was copied.

K-24 user/core-leader decision (2026-11-07, within the D-14 callback extension): move callback wrapping from document roots into `BlockNode::render_block` and list item rendering. Capture visits ancestors before descendants, so the innermost clicked block supplies the final offset. Paragraphs, headings, list items, fenced/indented code, tables and nested quote blocks retain their parser spans. The application normalizes that offset to the beginning of its original source line. This supersedes K-23's top-level-only mapping; no dependency or selection getter changes were made.

Verification boundary: K-23-R1 uses ordinary pure-function tests for source-position conversion, language names and toggle colors. Input/click behavior, scrolling, nested block mapping, and any wrapper effect on preview layout remain for V3. `gpui-kit/test-support` is not used because its dependency resolution conflicts with the current lockfile. The callback change is approved under the core D-14 extension dated 2026-11-07; this approval does not replace V3 verification.

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

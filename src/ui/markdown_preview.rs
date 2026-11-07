//! Markdown preview (v0.4 P4-5, R-14, D-7; 01-LAYOUT `E-038`, `E-039`, `L-69`, `L-101~L-111`, 02-INTERACTION `I-044`,
//! `I-045`). A preview is a tab of its own (`Tab::markdown`) whose hidden editor view is kept equal to the file, so an
//! edit in the source shows at once. The render is gpui-component's `TextView::markdown`, styled with the 5th section
//! values of `spec/zed-metrics.toml` (`[markdown_preview]`). K-03 uses the Base TextView heading-weight hook.

use std::path::Path;

use gpui_kit::component::ActiveTheme as _;
use gpui_kit::component::text::{MarkdownExtensions, MarkdownNode};
use gpui_kit::base::{TextView, TextViewStyle};
use gpui_kit::prelude::FluentBuilder as _;
use gpui_kit::*;

use super::Workbench;
use super::keymap::{self, markdown as md_actions};
use super::pane_group::{PaneId, SplitDirection, SplitMode};
use super::panel_menu::is_markdown;
use super::rem::rems_from_px;

/// `[markdown_preview] max_width` (L-101).
const MAX_WIDTH: Pixels = px(800.);
/// `container_padding` (L-102).
const CONTAINER_PADDING: Pixels = px(16.);
/// `body.font_size` and `body.line_height_multiplier` (L-103).
const BODY_FONT_SIZE: Pixels = px(16.);
const BODY_LINE_HEIGHT: f32 = 1.5;
/// `paragraph_gap` (L-103).
const PARAGRAPH_GAP: f32 = 16.;
/// L-105 heading borders and padding remain outside K-03's typography scope.
/// `h1.font_size` … `h6.font_size` (L-104).
const HEADING_SIZES: [f32; 6] = [28., 22.4, 19.2, 16., 14., 13.6];
/// `blockquote.padding_left` / `border_left` (L-106).
const QUOTE_PADDING_LEFT: Pixels = px(16.);
const QUOTE_BORDER_LEFT: Pixels = px(4.);
/// `table.border_outer`, `table.corner_radius`, `table.cell_padding_x/y` (L-107).
const TABLE_BORDER: Pixels = px(1.5);
const TABLE_RADIUS: Pixels = px(4.);
const CELL_PADDING_X: Pixels = px(10.);
const CELL_PADDING_Y: Pixels = px(4.);
/// `code_block.padding`, `margin_y`, `corner_radius` (L-109).
const CODE_PADDING: Pixels = px(12.);
const CODE_MARGIN_Y: Pixels = px(16.);
/// The text view adds `paragraph_gap` under every block but the last. Zed measures 16 between two code blocks (V3), not
/// margin + gap + margin (48), so a code block keeps `code_block.margin_y` above and takes the gap back below.
const CODE_MARGIN_BOTTOM: Pixels = px(-PARAGRAPH_GAP);
const CODE_RADIUS: Pixels = px(6.);
/// `code_block.border` (the colour is `code_block.border_color`, `theme::CodeBlockBorder`).
const CODE_BORDER: Pixels = px(1.);
/// `frontmatter.corner_radius` (L-111).
const FRONTMATTER_RADIUS: Pixels = px(4.);
/// `inline_code.background_opacity` (L-109).
const INLINE_CODE_OPACITY: f32 = 0.08;

/// L-69: "Preview {file name}", cut to 24 characters with an ellipsis. An unnamed path is "Markdown Preview".
pub fn preview_title(file_name: &str) -> String {
    if file_name.is_empty() {
        return "Markdown Preview".into();
    }
    let title = format!("Preview {file_name}");
    if title.chars().count() <= 24 {
        return title;
    }
    format!("{}…", title.chars().take(24).collect::<String>())
}

/// What a front matter block turned into: the flat `key: value` rows of L-110, or the raw text for a code-style box.
#[derive(Clone, Debug, PartialEq)]
enum Frontmatter {
    Table(Vec<(String, String)>),
    Raw(String),
}

/// The YAML between the `---` fences of a front matter node source, `None` if `source` is not a fenced block.
fn frontmatter_body(source: &str) -> Option<&str> {
    let source = source.trim_end();
    let rest = source.strip_prefix("---")?;
    let inner = rest.strip_prefix("\r\n").or_else(|| rest.strip_prefix('\n'))?;
    let inner = inner.strip_suffix("---").or_else(|| (inner == "---").then_some(""))?;
    // Only the line break that ends the last body line goes: a blank line before the closing fence stays in the body
    // (`"a: b\n"` is `a: b` plus an empty line), so L-110 sees it.
    Some(inner.strip_suffix("\r\n").or_else(|| inner.strip_suffix('\n')).unwrap_or(inner))
}

/// The front matter of a node `source`: a table or a raw box (L-110); `None` if `source` is not a fenced block.
fn classify(source: &str) -> Option<Frontmatter> {
    let body = frontmatter_body(source)?;
    Some(frontmatter_rows(body).map_or_else(|| Frontmatter::Raw(body.to_owned()), Frontmatter::Table))
}

/// L-110: a table only if EVERY line is `key: value` with a key and a value, both non-empty, and does not start with a
/// space; any other line (comment, blank, indented, block scalar continuation) makes the whole block a raw box.
pub fn frontmatter_rows(body: &str) -> Option<Vec<(String, String)>> {
    let rows: Option<Vec<(String, String)>> = body
        // `split`, not `lines`: a trailing empty line (a blank line before the closing fence) must be seen.
        .split('\n')
        .map(|line| {
            if line.starts_with(char::is_whitespace) {
                return None;
            }
            let (key, value) = line.split_once(':')?;
            let (key, value) = (key.trim(), value.trim());
            (!key.is_empty() && !value.is_empty()).then(|| (key.to_owned(), value.to_owned()))
        })
        .collect();
    rows.filter(|r| !r.is_empty())
}

/// Installs the front matter parser and renderer (L-110, L-111) on a preview. The component's own plugin differs from
/// the original in what it accepts and how it draws (description list), so the two public hooks are used instead.
fn with_frontmatter(view: TextView) -> TextView {
    view.markdown_block_parser(|node, cx| {
        let source = cx.node_source(node)?;
        let data = classify(source)?;
        let text = frontmatter_body(source)?.to_owned();
        Some(MarkdownNode::new("frontmatter", data).text(text).markdown(source.to_owned()))
    })
    .markdown_block_renderer("frontmatter", |node, _window, cx| {
        let theme = cx.theme();
        let (border, key_bg, fg) = (theme.border, theme.sidebar, theme.foreground);
        let cell = || div().px(CELL_PADDING_X).py(CELL_PADDING_Y);
        match node.data::<Frontmatter>() {
            // L-111: 2 columns over the full width, 1px border with radius 4; key cell on `panel_background` and
            // SEMIBOLD, value cell with a left line, rows after the first with a top line.
            Some(Frontmatter::Table(rows)) => div()
                .w_full()
                .flex()
                .flex_col()
                .border_1()
                .border_color(border)
                .rounded(FRONTMATTER_RADIUS)
                .overflow_hidden()
                .children(rows.iter().enumerate().map(|(i, (k, v))| {
                    div()
                        .flex()
                        .when(i > 0, |d| d.border_t_1().border_color(border))
                        .child(cell().flex_1().bg(key_bg).font_weight(FontWeight::SEMIBOLD).child(k.clone()))
                        .child(cell().flex_1().border_l_1().border_color(border).child(v.clone()))
                }))
                .into_any_element(),
            Some(Frontmatter::Raw(text)) => div()
                .w_full()
                .p(CODE_PADDING)
                .rounded(CODE_RADIUS)
                .bg(fg.opacity(INLINE_CODE_OPACITY))
                .font(super::fonts::editor())
                .text_size(super::metrics::BUFFER_FONT_SIZE)
                .child(text.clone())
                .into_any_element(),
            None => div().into_any_element(),
        }
    })
}

/// The preview body (L-101~L-111): `text` rendered, a column of at most 800px centred in the pane with 16px around it,
/// on the editor background.
fn heading_style(level: u8) -> StyleRefinement {
    StyleRefinement::default()
        .text_size(px(HEADING_SIZES[usize::from(level.clamp(1, 6)) - 1]))
        .font_weight(FontWeight::SEMIBOLD)
}

pub fn body(pane: PaneId, text: SharedString, editor: Entity<gpui_kit::component::input::EditorState>, cx: &App) -> impl IntoElement {
    let theme = cx.theme();
    // K-46: `code_block.border_color` is `border.variant`; a theme without it keeps the general border.
    let code_border = cx.try_global::<super::theme::CodeBlockBorder>().and_then(|b| b.0).unwrap_or(theme.border);
    let side = |s: StyleRefinement| s.border_t(TABLE_BORDER).border_b(TABLE_BORDER).border_l(TABLE_BORDER).border_r(TABLE_BORDER);
    let style = TextViewStyle::default()
        .with_foreground(theme.foreground)
        .with_muted_foreground(theme.muted_foreground)
        .with_link(theme.link)
        .with_selection(theme.selection)
        .with_code_background(theme.muted)
        .with_border(theme.border)
        .with_dark(theme.is_dark())
        .with_paragraph_gap(rems_from_px(PARAGRAPH_GAP))
        .with_heading(heading_style)
        .with_code_block(StyleRefinement::default().font(super::fonts::editor())
            .text_size(super::metrics::PREVIEW_CODE_FONT_SIZE)
            .line_height(relative(super::metrics::PREVIEW_CODE_LINE_HEIGHT_MULTIPLIER))
            .p(CODE_PADDING).mt(CODE_MARGIN_Y).mb(CODE_MARGIN_BOTTOM).rounded(CODE_RADIUS)
            // K-46-R1: Zed paints a preview code block with the editor background.
            .bg(theme.background)
            .border_t(CODE_BORDER).border_b(CODE_BORDER).border_l(CODE_BORDER).border_r(CODE_BORDER).border_color(code_border))
        .with_inline_code(HighlightStyle { background_color: Some(theme.foreground.opacity(INLINE_CODE_OPACITY)), ..Default::default() })
        .with_table(side(StyleRefinement::default()).border_color(theme.border).rounded(TABLE_RADIUS))
        .with_table_head(StyleRefinement::default().font_weight(FontWeight::SEMIBOLD).bg(theme.title_bar))
        .with_table_cell(StyleRefinement::default().px(CELL_PADDING_X).py(CELL_PADDING_Y));
    let quote = StyleRefinement::default()
        .pl(QUOTE_PADDING_LEFT)
        .border_l(QUOTE_BORDER_LEFT)
        .border_color(theme.border)
        .text_color(theme.muted_foreground);
    div()
        .id(("markdown-preview", pane as usize))
        .size_full()
        .overflow_y_scroll()
        .bg(theme.background)
        .p(CONTAINER_PADDING)
        .text_color(theme.foreground)
        .font(super::fonts::ui())
        .text_size(BODY_FONT_SIZE)
        .line_height(relative(BODY_LINE_HEIGHT))
        .child(
            div().mx_auto().max_w(MAX_WIDTH).child(with_frontmatter(
                TextView::markdown(("markdown-text", pane as usize), text)
                    .shared_code_block_highlighter(super::syntax::code_block_highlighter())
                    .style(style)
                    .blockquote_style(quote)
                    .markdown_extensions(MarkdownExtensions::default().frontmatter())
                    .on_source_block_click(move |offset, _, cx| {
                        editor.update(cx, |state, cx| {
                            let start = super::status::preview_line_start(&state.value(), offset);
                            state.set_selected_range(start..start, cx);
                        });
                    })
                    .selectable(true)
                    .scrollable(false),
            )),
        )
}

impl Workbench {
    /// Opens the preview of the active markdown tab (E-039, I-044): in the active pane, or `side` in a new pane to the
    /// right (the button with Alt, Ctrl+K V). On a preview tab it goes back to the editor tab beside it (I-045).
    pub(super) fn open_markdown_preview(&mut self, side: bool, window: &mut Window, cx: &mut Context<Self>) {
        let Some(ws) = self.active_ws() else { return };
        let Some((path, preview)) = ws.read(cx).group.active_tab().map(|t| (t.path.clone(), t.markdown)) else { return };
        if preview {
            // I-045: back to the editor tab (found in any pane, since a side preview has it elsewhere; else a view of
            // the shared buffer is opened here), then the preview closes through the usual close path, which asks
            // the save question when it was the file's last view.
            let (here, ix) = {
                let g = &ws.read(cx).group;
                (g.active, g.active_pane().active)
            };
            ws.update(cx, |ws, cx| {
                let g = &mut ws.group;
                match g.find_source(&path, here) {
                    Some((pane, i)) => {
                        g.activate(pane);
                        if let Some(p) = g.panes.get_mut(&pane) {
                            p.active = Some(i);
                        }
                    }
                    None => {
                        g.open(&path, false, window, cx);
                    }
                }
            });
            if let Some(ix) = ix {
                self.close_tab_at(here, ix, window, cx);
            }
        } else if is_markdown(&path) {
            ws.update(cx, |ws, cx| {
                let g = &mut ws.group;
                let pane = if side { g.split_active(SplitDirection::Right, SplitMode::Empty, window, cx) } else { Some(g.active) };
                if let Some(pane) = pane {
                    g.open_preview(pane, &path, window, cx);
                }
            });
        }
        self.focus_active_pane(window, cx);
        cx.notify();
    }

    pub(super) fn on_open_preview(&mut self, a: &md_actions::OpenPreview, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.open_markdown_preview(false, w, cx);
    }

    pub(super) fn on_open_preview_to_the_side(&mut self, a: &md_actions::OpenPreviewToTheSide, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.open_markdown_preview(true, w, cx);
    }
}

/// The file name of `path` for the preview title.
pub fn file_name(path: &Path) -> String {
    path.file_name().map(|n| n.to_string_lossy().into_owned()).unwrap_or_default()
}

#[cfg(test)]
mod tests {
    #[test]
    fn k06_preview_code_size_and_line_height() {
        let size = f32::from(super::super::metrics::PREVIEW_CODE_FONT_SIZE);
        let multiplier = super::super::metrics::PREVIEW_CODE_LINE_HEIGHT_MULTIPLIER;
        assert_eq!(size, 16.);
        assert!((size * multiplier - 25.888).abs() < 0.00001);
        assert_eq!(super::super::metrics::BUFFER_FONT_SIZE, gpui_kit::px(15.));
    }
    #[test]
    fn k03_preview_heading_weight_and_body_size() {
        assert_eq!(super::BODY_FONT_SIZE, super::super::fonts::UI_SIZE);
        for level in 1..=6 {
            assert_eq!(super::heading_style(level).text.font_weight, Some(gpui_kit::FontWeight::SEMIBOLD));
        }
    }
    use super::{Frontmatter, classify, BODY_FONT_SIZE, BODY_LINE_HEIGHT, CELL_PADDING_X, CELL_PADDING_Y, CODE_BORDER, CODE_MARGIN_BOTTOM, CODE_MARGIN_Y, CODE_PADDING, CODE_RADIUS, CONTAINER_PADDING, FRONTMATTER_RADIUS, HEADING_SIZES, INLINE_CODE_OPACITY, MAX_WIDTH, PARAGRAPH_GAP, QUOTE_BORDER_LEFT, QUOTE_PADDING_LEFT, TABLE_BORDER, TABLE_RADIUS, file_name, frontmatter_body, frontmatter_rows, preview_title};
    use crate::ui::metrics::spec::assert_spec;
    use std::path::Path;

    /// P4-45-R1 (5): the L-101~L-111 values the preview sets equal the spec (`[markdown_preview]`).
    #[test]
    fn preview_values_equal_spec() {
        let px = f32::from;
        let s = |id: &str, v: f32| assert_spec(&format!("markdown_preview[\"{id}\"]"), "default", v);
        s("max_width", px(MAX_WIDTH));
        s("container_padding", px(CONTAINER_PADDING));
        s("body.font_size", px(BODY_FONT_SIZE));
        s("body.line_height_multiplier", BODY_LINE_HEIGHT);
        s("paragraph_gap", PARAGRAPH_GAP);
        for (i, size) in HEADING_SIZES.iter().enumerate() {
            s(&format!("h{}.font_size", i + 1), *size);
        }
        s("blockquote.padding_left", px(QUOTE_PADDING_LEFT));
        s("blockquote.border_left", px(QUOTE_BORDER_LEFT));
        s("table.border_outer", px(TABLE_BORDER));
        s("table.corner_radius", px(TABLE_RADIUS));
        s("table.cell_padding_x", px(CELL_PADDING_X));
        s("table.cell_padding_y", px(CELL_PADDING_Y));
        s("code_block.padding", px(CODE_PADDING));
        s("code_block.margin_y", px(CODE_MARGIN_Y));
        // K-46-R1: two code blocks in a row are `margin_y` apart (V3 Zed: 16), however the gap and margins add up.
        s("code_block.margin_y", px(CODE_MARGIN_BOTTOM) + PARAGRAPH_GAP + px(CODE_MARGIN_Y));
        assert_eq!(f32::from(CODE_MARGIN_BOTTOM), -PARAGRAPH_GAP, "the bottom margin takes the paragraph gap back");
        s("code_block.corner_radius", px(CODE_RADIUS));
        s("code_block.border", px(CODE_BORDER));
        // A ratio held as f32 against the spec's f64: the helper has no tolerance for ratios.
        let opacity = crate::ui::metrics::spec::lookup("markdown_preview[\"inline_code.background_opacity\"]").unwrap().value;
        assert!((opacity - f64::from(INLINE_CODE_OPACITY)).abs() < 1e-6);
        s("frontmatter.corner_radius", px(FRONTMATTER_RADIUS));
    }

    /// L-110: only a block whose every line is an unindented `key: value` (both non-empty) is a table; a Korean key is
    /// fine, a comment, a blank line, an indented line or an empty value makes the whole block a raw box.
    #[test]
    fn frontmatter_table_only_for_flat_pairs() {
        let rows = frontmatter_rows("title: Hello\n제목: 값\ntags: a: b").unwrap();
        assert_eq!(rows, [("title".into(), "Hello".into()), ("제목".into(), "값".into()), ("tags".into(), "a: b".into())]);
        for bad in ["title: hi\n# comment", "title: hi\n\nb: c", "title: hi\n  more", "title:", ": value", "just text", ""] {
            assert_eq!(frontmatter_rows(bad), None, "{bad:?}");
        }
    }

    /// The fenced source of a front matter node loses its `---` lines.
    #[test]
    fn frontmatter_body_strips_the_fences() {
        assert_eq!(frontmatter_body("---\na: b\n---"), Some("a: b"));
        assert_eq!(frontmatter_body("---\r\na: b\r\n---\r\n"), Some("a: b"));
        assert_eq!(frontmatter_body("---\n---"), Some(""));
        assert_eq!(frontmatter_body("# heading"), None);
        assert_eq!(frontmatter_body("---"), None);
    }

    /// P4-45-R2 (4, L-110): a blank line right before the closing `---` is kept by the extraction and makes the whole
    /// block raw, for LF and CRLF alike; the same block without it is a table.
    #[test]
    fn blank_line_before_the_closing_fence_makes_it_raw() {
        for (flat, blank) in [("---\na: b\n---", "---\na: b\n\n---"), ("---\r\na: b\r\n---", "---\r\na: b\r\n\r\n---")] {
            assert_eq!(classify(flat), Some(Frontmatter::Table(vec![("a".into(), "b".into())])), "{flat:?}");
            assert!(matches!(classify(blank), Some(Frontmatter::Raw(_))), "{blank:?}");
        }
        assert_eq!(frontmatter_body("---\na: b\n\n---"), Some("a: b\n"));
        assert_eq!(frontmatter_body("---\r\na: b\r\n\r\n---"), Some("a: b\r\n"));
    }

    /// L-69: "Preview {name}", 24 characters at most, an ellipsis after a cut one; no name → "Markdown Preview".
    #[test]
    fn preview_title_follows_l69() {
        assert_eq!(preview_title("README.md"), "Preview README.md");
        assert_eq!(preview_title("exactly-fifteen.md"), "Preview exactly-fifteen.…");
        assert_eq!(preview_title("1234567890123456"), "Preview 1234567890123456", "exactly 24 stays");
        assert_eq!(preview_title("한글로된아주긴파일이름입니다.md"), "Preview 한글로된아주긴파일이름입니다.m…");
        assert_eq!(preview_title(""), "Markdown Preview");
        assert_eq!(file_name(Path::new("a/b/c.md")), "c.md");
    }
}

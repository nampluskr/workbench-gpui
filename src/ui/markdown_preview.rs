//! Markdown preview (v0.4 P4-5, R-14, D-7; 01-LAYOUT `E-038`, `E-039`, `L-69`, `L-101~L-111`, 02-INTERACTION `I-044`,
//! `I-045`). A preview is a tab of its own (`Tab::markdown`) whose hidden editor view is kept equal to the file, so an
//! edit in the source shows at once. The render is gpui-component's `TextView::markdown`, styled with the 5th section
//! values of `spec/zed-metrics.toml` (`[markdown_preview]`) as far as that component allows.

use std::path::Path;

use gpui_kit::component::ActiveTheme as _;
use gpui_kit::component::text::{FrontmatterPlugin, MarkdownExtensions, TextView, TextViewStyle};
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
const CODE_RADIUS: Pixels = px(6.);
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

/// The preview body (L-101~L-111): `text` rendered, a column of at most 800px centred in the pane with 16px around it,
/// on the editor background.
pub fn body(pane: PaneId, text: SharedString, cx: &App) -> impl IntoElement {
    let theme = cx.theme();
    let side = |s: StyleRefinement| s.border_t(TABLE_BORDER).border_b(TABLE_BORDER).border_l(TABLE_BORDER).border_r(TABLE_BORDER);
    let style = TextViewStyle::default()
        .paragraph_gap(rems_from_px(PARAGRAPH_GAP))
        .heading_font_size(|level, _| px(HEADING_SIZES[usize::from(level.clamp(1, 6)) - 1]))
        .code_block(StyleRefinement::default().p(CODE_PADDING).my(CODE_MARGIN_Y).rounded(CODE_RADIUS))
        .inline_code(HighlightStyle { background_color: Some(theme.foreground.opacity(INLINE_CODE_OPACITY)), ..Default::default() })
        .table(side(StyleRefinement::default()).border_color(theme.border).rounded(TABLE_RADIUS))
        .table_head(StyleRefinement::default().font_weight(FontWeight::SEMIBOLD).bg(theme.title_bar))
        .table_cell(StyleRefinement::default().px(CELL_PADDING_X).py(CELL_PADDING_Y));
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
        .text_size(BODY_FONT_SIZE)
        .line_height(relative(BODY_LINE_HEIGHT))
        .child(
            div().mx_auto().max_w(MAX_WIDTH).child(
                TextView::markdown(("markdown-text", pane as usize), text)
                    .style(style)
                    .blockquote_style(quote)
                    .markdown_extensions(MarkdownExtensions::default().frontmatter())
                    .plugin(FrontmatterPlugin::new())
                    .selectable(true)
                    .scrollable(false),
            ),
        )
}

impl Workbench {
    /// Opens the preview of the active markdown tab (E-039, I-044): in the active pane, or `side` in a new pane to the
    /// right (the button with Alt, Ctrl+K V). On a preview tab it goes back to the editor tab beside it (I-045).
    // shortcut: I-045 switches to the source tab; Zed closes the preview. Closing it would need the save question when
    // the preview is the file's last view.
    pub(super) fn open_markdown_preview(&mut self, side: bool, window: &mut Window, cx: &mut Context<Self>) {
        let Some(ws) = self.active_ws() else { return };
        let Some((path, preview)) = ws.read(cx).group.active_tab().map(|t| (t.path.clone(), t.markdown)) else { return };
        if preview {
            ws.update(cx, |ws, _| {
                let g = &mut ws.group;
                let pane = g.active;
                if let Some(p) = g.panes.get_mut(&pane)
                    && let Some(i) = p.find(&path)
                {
                    p.active = Some(i);
                }
            });
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
    use super::{file_name, preview_title};
    use std::path::Path;

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

//! Styling shared by the app menu and the context menu (AUDIT 8).
//!
//! Only the identical row/popup base lives here; enabled state, events, focus and probe ids stay in each menu.

use gpui_kit::component::{ActiveTheme as _, h_flex};
use gpui_kit::*;

use super::metrics::menu::{
    LIST_PAD_Y, MIN_WIDTH, RADIUS, ROW_LINE_HEIGHT, ROW_MARGIN_X, ROW_PAD_X, ROW_RADIUS, ROW_TEXT,
    SEPARATOR_HEIGHT, SEPARATOR_MARGIN_Y, SHORTCUT_GAP,
};
use super::tooltip;

/// Scrolling list base. The caller sets its probe on the `v_flex` before the id is applied.
pub fn list(probed: Div, id: &'static str, max_height: Pixels) -> Stateful<Div> {
    probed
        .id(id)
        .min_w(MIN_WIDTH)
        .py(LIST_PAD_Y)
        .max_h(max_height)
        .overflow_y_scroll()
}

pub fn separator(border: Hsla) -> Div {
    div().my(SEPARATOR_MARGIN_Y).h(SEPARATOR_HEIGHT).w_full().bg(border)
}

/// Row base; the caller adds disabled/selected colors, hover and click.
pub fn row(id: impl Into<ElementId>) -> Stateful<Div> {
    h_flex()
        .id(id)
        .mx(ROW_MARGIN_X)
        .px(ROW_PAD_X)
        .rounded(ROW_RADIUS)
        .justify_between()
        .text_size(ROW_TEXT)
        .line_height(relative(ROW_LINE_HEIGHT))
}

/// Shortcut column cell; the caller sets its text color.
pub fn shortcut_cell() -> Div {
    div().flex_shrink_0().ml(SHORTCUT_GAP)
}

/// Popup surface applied after the menu's own key context, focus and action handlers.
pub fn popup_surface(popup: Div, cx: &App) -> Div {
    let theme = cx.theme();
    popup
        .occlude()
        .bg(theme.popover)
        .text_color(theme.popover_foreground)
        .border_1()
        .border_color(theme.border)
        .rounded(RADIUS)
        .shadow(tooltip::elevation_2_shadow(theme.is_dark()))
}

//! Color literals in one place (P2-3). Values are unchanged; the theme mapping/selector is v0.4+ (D-9).

use gpui_kit::{Hsla, Rgba, black, hsla, rgb, rgba, white};

/// L-84 close button hover background #E81120.
pub fn close_hover_bg() -> Rgba {
    rgb(0xE81120)
}

/// L-84 close button hover glyph color (white).
pub fn close_hover_fg() -> Hsla {
    white()
}

/// L-84 close button pressed background: #E81120 at 80% opacity.
pub fn close_active_bg() -> Rgba {
    rgba(0xE81120CC)
}

/// L-84 close button pressed glyph color: white at 80% opacity.
pub fn close_active_fg() -> Rgba {
    rgba(0xFFFFFFCC)
}

/// L-211·L-212 `elevation_2` first shadow (black 12%, both light and dark).
pub fn elevation_2_shadow_1() -> Hsla {
    hsla(0., 0., 0., 0.12)
}

/// L-211·L-212 `elevation_2` second shadow (black 6% dark / 3% light).
pub fn elevation_2_shadow_2(is_dark: bool) -> Hsla {
    hsla(0., 0., 0., if is_dark { 0.06 } else { 0.03 })
}

// spec: none (app value) — dev-only font measurement text run color (never painted).
pub fn measure_text() -> Hsla {
    black()
}

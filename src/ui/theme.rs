//! Color literals in one place (P2-3). Values are unchanged; the theme mapping/selector is v0.4+ (D-9).

use gpui_kit::{Hsla, Rgba, black, hsla, rgb, rgba, white};

/// T-05.05: Zed One Light, matching the application's fixed light appearance.
fn active_line_background() -> Hsla {
    rgba(0xebebecbf).into()
}

pub fn init(cx: &mut gpui_kit::App) {
    gpui_kit::component::Theme::update(cx, |theme| {
        std::sync::Arc::make_mut(&mut theme.highlight_theme).style.editor_active_line = Some(active_line_background());
    });
    cx.set_global(line_number_theme());
}

/// T-05.07/08: Zed One Light, matching the application's fixed light appearance.
fn line_number_theme() -> gpui_kit::base::EditorGutterTheme {
    gpui_kit::base::EditorGutterTheme {
        line_number: rgb(0xb4b4bb).into(),
        active_line_number: rgb(0x44454b).into(),
    }
}

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

#[cfg(test)]
mod tests {
    #[test]
    fn k07_gutter_geometry_and_colors() {
        use gpui_kit::{base::EditorGutterTheme, px, rgb};
        for (digits, gutter, text) in [(1, 87., 92.), (4, 87., 92.), (5, 96., 101.)] {
            assert_eq!(EditorGutterTheme::width(digits, px(9.)), px(gutter));
            assert_eq!(EditorGutterTheme::text_start(digits, px(9.)), px(text));
        }
        let theme = super::line_number_theme();
        assert_eq!(theme.line_number, rgb(0xb4b4bb).into());
        assert_eq!(theme.active_line_number, rgb(0x44454b).into());
    }
    #[test]
    fn k04_active_line_uses_zed_one_light_color() {
        let color: gpui_kit::Rgba = super::active_line_background().into();
        assert_eq!(color, gpui_kit::rgba(0xebebecbf));
    }
}

//! K-03 / I-14 typography and T-16 Windows fallback order.
use std::borrow::Cow;
use gpui_kit::*;

pub const UI_FAMILY: &str = "IBM Plex Sans";
pub const EDITOR_FAMILY: &str = "Lilex";
pub const UI_SIZE: Pixels = px(super::metrics::UI_FONT_SIZE.0 * super::rem::BASE_REM_PX);

pub fn ui() -> Font {
    Font {
        features: FontFeatures::disable_ligatures(),
        fallbacks: Some(FontFallbacks::from_fonts(vec!["Segoe UI".into(), "Malgun Gothic".into()])),
        ..font(UI_FAMILY)
    }
}

pub fn editor() -> Font {
    Font {
        fallbacks: Some(FontFallbacks::from_fonts(vec!["Cascadia Mono".into(), "Consolas".into(), "Malgun Gothic".into()])),
        ..font(EDITOR_FAMILY)
    }
}

pub fn init(cx: &mut App) {
    let fonts: &[&[u8]] = &[
        include_bytes!("../../resources/fonts/ibm-plex-sans/IBMPlexSans-Regular.ttf"),
        include_bytes!("../../resources/fonts/ibm-plex-sans/IBMPlexSans-Italic.ttf"),
        include_bytes!("../../resources/fonts/ibm-plex-sans/IBMPlexSans-SemiBold.ttf"),
        include_bytes!("../../resources/fonts/ibm-plex-sans/IBMPlexSans-SemiBoldItalic.ttf"),
        include_bytes!("../../resources/fonts/lilex/Lilex-Regular.ttf"),
        include_bytes!("../../resources/fonts/lilex/Lilex-Bold.ttf"),
        include_bytes!("../../resources/fonts/lilex/Lilex-Italic.ttf"),
        include_bytes!("../../resources/fonts/lilex/Lilex-BoldItalic.ttf"),
    ];
    cx.text_system().add_fonts(fonts.iter().map(|data| Cow::Borrowed(*data)).collect())
        .expect("failed to register bundled fonts");
    gpui_kit::component::Theme::update(cx, |theme| {
        theme.font_family = UI_FAMILY.into();
        theme.font_size = UI_SIZE;
        theme.mono_font_family = EDITOR_FAMILY.into();
        theme.mono_font_size = super::metrics::BUFFER_FONT_SIZE;
    });
}

#[cfg(test)]
mod tests {
    use super::*;
    #[core::prelude::v1::test]
    fn k03_font_values_and_fallback_order() {
        let ui = ui();
        let editor = editor();
        assert_eq!(ui.family.as_ref(), "IBM Plex Sans");
        assert_eq!(editor.family.as_ref(), "Lilex");
        assert_eq!(ui.weight, FontWeight::NORMAL);
        assert_eq!(editor.weight, FontWeight::NORMAL);
        assert_eq!(ui.features.is_calt_enabled(), Some(false));
        assert_eq!(ui.fallbacks.unwrap().fallback_list(), ["Segoe UI", "Malgun Gothic"]);
        assert_eq!(editor.fallbacks.unwrap().fallback_list(), ["Cascadia Mono", "Consolas", "Malgun Gothic"]);
        assert_eq!(UI_SIZE, px(16.));
        assert_eq!(UI_SIZE, px(super::super::rem::BASE_REM_PX));
        for (size, expected) in [(super::super::metrics::TEXT_SIZE_DEFAULT, 14.), (super::super::metrics::TEXT_SIZE_SMALL, 12.),
            (super::super::metrics::menu::ROW_TEXT, 14.), (super::super::metrics::menu::NAME_TEXT, 12.),
            (super::super::metrics::project_panel::BANNER_TEXT, 14.),
            (super::super::metrics::tooltip::TEXT_SIZE, 14.), (super::super::metrics::tooltip::META_TEXT_SIZE, 12.)] {
            assert_eq!(size.0 * super::super::rem::BASE_REM_PX, expected);
        }
        assert_eq!(super::super::metrics::BUFFER_FONT_SIZE, px(15.));
        assert_eq!(super::super::metrics::BUFFER_LINE_HEIGHT_MULTIPLIER, 1.618);
        assert!((f32::from(super::super::metrics::BUFFER_FONT_SIZE) * super::super::metrics::BUFFER_LINE_HEIGHT_MULTIPLIER - 24.27).abs() < 0.001);
    }
}

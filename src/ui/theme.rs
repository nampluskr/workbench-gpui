//! Local Zed theme catalog and projection into gpui-kit.

use gpui_kit::{Hsla, Rgba, black, hsla, rgb, rgba, white};

#[derive(Clone, Debug)]
pub struct Entry {
    pub name: String,
    /// JSON path under the theme root, `/` separated (Extensions sort key and bundle lookup).
    pub source: String,
    pub theme: serde_json::Value,
}

fn load(root: &std::path::Path) -> Vec<Entry> {
    fn visit(path: &std::path::Path, root: &std::path::Path, result: &mut Vec<Entry>) {
        let Ok(files) = std::fs::read_dir(path) else { return };
        let mut paths: Vec<_> = files.filter_map(Result::ok).map(|f| f.path()).collect();
        paths.sort();
        for path in paths {
            if path.is_dir() { visit(&path, root, result); continue; }
            if path.extension().and_then(|s| s.to_str()) != Some("json") { continue; }
            let parsed = std::fs::read_to_string(&path).ok().and_then(|text|
                jsonc_parser::parse_to_serde_value::<serde_json::Value>(&text, &Default::default()).ok());
            let Some(mut family) = parsed else { continue };
            let source = path.strip_prefix(root).unwrap_or(&path).to_string_lossy().replace('\\', "/");
            let themes = family.get_mut("themes").map(serde_json::Value::take);
            for theme in themes.as_ref().and_then(|t| t.as_array()).into_iter().flatten() {
                if let Some(name) = theme["name"].as_str() {
                    result.push(Entry { name: name.into(), source: source.clone(), theme: theme.clone() });
                }
            }
        }
    }
    let mut result = Vec::new();
    visit(root, root, &mut result);
    result
}

pub fn catalog() -> &'static [Entry] {
    static CATALOG: std::sync::OnceLock<Vec<Entry>> = std::sync::OnceLock::new();
    CATALOG.get_or_init(|| load(&std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("resources/zed-themes")))
}

/// Selectable names. Keeps the default valid when the copies are missing.
pub fn names() -> Vec<String> {
    let mut entries: Vec<_> = catalog().iter().collect();
    entries.sort_by_key(|entry| (entry.theme["appearance"] == "light", &entry.name));
    let mut names: Vec<String> = entries.iter().map(|entry| entry.name.clone()).collect();
    if !names.iter().any(|name| name == super::settings::THEME) { names.insert(0, super::settings::THEME.into()); }
    names
}

fn color(style: &serde_json::Value, key: &str) -> Option<Hsla> {
    let hex = style.get(key)?.as_str()?.strip_prefix('#')?;
    let value = u32::from_str_radix(hex, 16).ok()?;
    match hex.len() { 6 => Some(rgb(value).into()), 8 => Some(rgba(value).into()), _ => None }
}

/// Core ORDER-07: JSON, T-26 derivation, same-appearance One, then T-26 fixed colors.
fn resolved_color(style: &serde_json::Value, base: &serde_json::Value, key: &str) -> Option<Hsla> {
    color(style, key).or_else(|| match key {
        "scrollbar.thumb.active_background" => resolved_color(style, base, "scrollbar.thumb.background"),
        "pane_group.border" => resolved_color(style, base, "border"),
        "panel.overlay_background" => resolved_color(style, base, "panel.background").map(|mut c| { c.a = 1.; c }),
        "panel.overlay_hover" => resolved_color(style, base, "panel.background").and_then(|bg|
            resolved_color(style, base, "element.hover").map(|hover| { let mut c = bg.blend(hover); c.a = 1.; c })),
        "editor.document_highlight.bracket_background" => resolved_color(style, base, "editor.document_highlight.read_background"),
        _ => None,
    }).or_else(|| color(base, key)).or_else(|| {
        // Fixed values from T-26.5..14, used only after the One fallback.
        let value = match key {
            "panel.focused_border" | "pane.focused_border" => 0x62adef,
            "panel.indent_guide" | "scrollbar.thumb.border" | "editor.indent_guide" => 0x3b3d45,
            "panel.indent_guide_hover" | "panel.indent_guide_active" | "editor.indent_guide_active" => 0x1b1d23,
            "editor.hover_line_number" => 0x8a8f97,
            "drop_target.border" => 0xd7dadf,
            _ => return None,
        };
        Some(rgb(value).into())
    })
}

fn project(entry: Option<&Entry>, theme: &mut gpui_kit::component::Theme) -> Option<gpui_kit::base::EditorGutterTheme> {
    let entry = entry?;
    let style = &entry.theme["style"];
    let base_name = if entry.theme["appearance"] == "light" { "One Light" } else { "One Dark" };
    let base = catalog().iter().find(|e| e.name == base_name).map(|e| &e.theme["style"]).unwrap_or(&serde_json::Value::Null);
    let color = |style: &serde_json::Value, key: &str| resolved_color(style, base, key);
    macro_rules! map {
        ($($field:ident => $key:literal),* $(,)?) => { $(if let Some(value) = color(style, $key) { theme.colors.$field = value; })* };
    }
    map! {
        background => "editor.background", foreground => "text", border => "border",
        muted_foreground => "text.muted", primary => "text.accent", accent => "text.accent",
        ring => "border.focused", link => "text.accent", sidebar => "panel.background",
        title_bar => "title_bar.background", title_bar_border => "border", status_bar => "status_bar.background",
        status_bar_border => "border", tab_bar => "tab_bar.background", popover => "elevated_surface.background",
        popover_foreground => "text", secondary => "element.background", secondary_hover => "element.hover",
        secondary_active => "element.selected", secondary_foreground => "text", list => "panel.background",
        list_active => "element.selected", list_hover => "element.hover", muted => "surface.background",
        input => "border", caret => "text.accent", drop_target => "drop_target.background",
        drag_border => "border.selected", scrollbar => "scrollbar.track.background",
        scrollbar_thumb => "scrollbar.thumb.background", scrollbar_thumb_hover => "scrollbar.thumb.hover_background",
        danger => "error", warning => "warning", success => "success",
    }
    if let Some(value) = resolved_color(&style["players"][0], &base["players"][0], "selection") { theme.selection = value; }
    let highlight = &mut std::sync::Arc::make_mut(&mut theme.highlight_theme).style;
    highlight.editor_background = color(style, "editor.background");
    highlight.editor_foreground = color(style, "editor.foreground");
    highlight.editor_active_line = color(style, "editor.active_line.background");
    highlight.editor_gutter_background = color(style, "editor.gutter.background");
    Some(gpui_kit::base::EditorGutterTheme {
        line_number: color(style, "editor.line_number").unwrap_or(theme.muted_foreground),
        active_line_number: color(style, "editor.active_line_number").unwrap_or(theme.foreground),
    })
}

/// I-12: the breadcrumb's two theme colours that gpui-kit's theme has no field for. Computed in `apply`, so a theme
/// change replaces them. `separator` is Zed `text.placeholder` (One fallback as the other tokens); `title` is the
/// syntax `title` colour of Markdown headings, none when the theme has no such entry (the text keeps its muted colour).
#[derive(Clone, Copy, Debug, PartialEq)]
pub struct BreadcrumbColors {
    pub separator: Option<Hsla>,
    pub title: Option<Hsla>,
}

impl gpui_kit::Global for BreadcrumbColors {}

fn breadcrumb_colors(entry: Option<&Entry>) -> BreadcrumbColors {
    let Some(entry) = entry else { return BreadcrumbColors { separator: None, title: None } };
    let style = &entry.theme["style"];
    let base_name = if entry.theme["appearance"] == "light" { "One Light" } else { "One Dark" };
    let base = catalog().iter().find(|e| e.name == base_name).map(|e| &e.theme["style"]).unwrap_or(&serde_json::Value::Null);
    BreadcrumbColors { separator: resolved_color(style, base, "text.placeholder"), title: color(&style["syntax"]["title"], "color") }
}

pub fn apply(name: &str, cx: &mut gpui_kit::App) {
    let entry = catalog().iter().find(|entry| entry.name == name);
    if let Some(entry) = entry {
        let mode = if entry.theme["appearance"] == "light" { gpui_kit::component::ThemeMode::Light } else { gpui_kit::component::ThemeMode::Dark };
        gpui_kit::component::Theme::change(mode, None, cx);
    }
    cx.set_global(breadcrumb_colors(entry));
    let gutter = gpui_kit::component::Theme::update(cx, |theme| project(entry, theme));
    if let Some(gutter) = gutter {
        cx.set_global(gutter);
    } else {
        static WARNED: std::sync::atomic::AtomicBool = std::sync::atomic::AtomicBool::new(false);
        if !WARNED.swap(true, std::sync::atomic::Ordering::Relaxed) {
            eprintln!("Local Zed theme unavailable ({name}); using gpui-kit default theme. Run tools/fetch-zed-themes.ps1.");
        }
    }
}

pub fn init(cx: &mut gpui_kit::App) {
    apply(super::settings::THEME, cx);
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
    fn k22_names_sort_dark_then_light_by_name() {
        let names = super::names();
        assert_eq!(names.len(), super::catalog().len());
        let keys: Vec<_> = names.iter().map(|name| {
            let e = super::catalog().iter().find(|e| &e.name == name).unwrap();
            (e.theme["appearance"] == "light", name)
        }).collect();
        assert!(keys.windows(2).all(|w| w[0] <= w[1]));
    }

    #[test]
    fn k22_missing_token_fallback_order() {
        use serde_json::json;
        use super::{color, resolved_color};
        let style = json!({"border":"#123456", "pane_group.border":"#abcdef", "scrollbar.thumb.background":"#234567"});
        let base = json!({"border":"#345678", "pane_group.border":"#456789", "text.accent":"#56789a"});
        assert_eq!(resolved_color(&style, &base, "pane_group.border"), color(&style, "pane_group.border"));
        assert_eq!(resolved_color(&json!({"border":"#123456"}), &base, "pane_group.border"), color(&style, "border"));
        assert_eq!(resolved_color(&style, &base, "scrollbar.thumb.active_background"), color(&style, "scrollbar.thumb.background"));
        assert_eq!(resolved_color(&json!({"text.accent":null}), &base, "text.accent"), color(&base, "text.accent"));
        assert_eq!(resolved_color(&json!({}), &json!({}), "drop_target.border"), Some(gpui_kit::rgb(0xd7dadf).into()));
        for name in ["One Dark", "One Light"] {
            let base = &super::catalog().iter().find(|e| e.name == name).unwrap().theme["style"];
            assert_eq!(resolved_color(&json!({}), base, "text.accent"), color(base, "text.accent"));
        }
    }

    #[test]
    fn k19_all_copied_theme_colors() {
        use super::{catalog, color, project};
        for name in ["One Dark", "One Light", "Ayu Dark"] {
            assert!(catalog().iter().any(|e| e.name == name), "missing {name}");
        }
        for entry in catalog() {
            let mut theme = gpui_kit::component::Theme::default();
            let fonts = (theme.font_family.clone(), theme.font_size, theme.mono_font_family.clone(), theme.mono_font_size);
            let gutter = project(Some(entry), &mut theme).unwrap();
            let s = &entry.theme["style"];
            for (actual, key) in [(theme.background, "editor.background"), (theme.foreground, "text"),
                (theme.border, "border"), (theme.primary, "text.accent"), (theme.status_bar, "status_bar.background"),
                (theme.title_bar, "title_bar.background"), (theme.sidebar, "panel.background"),
                (theme.scrollbar_thumb, "scrollbar.thumb.background"), (theme.popover, "elevated_surface.background"),
                (gutter.line_number, "editor.line_number"), (gutter.active_line_number, "editor.active_line_number")] {
                if let Some(expected) = color(s, key) { assert_eq!(actual, expected, "{}: {key}", entry.name); }
            }
            let base_name = if entry.theme["appearance"] == "light" { "One Light" } else { "One Dark" };
            let base = &catalog().iter().find(|e| e.name == base_name).unwrap().theme["style"];
            assert_eq!(theme.highlight_theme.style.editor_active_line, super::resolved_color(s, base, "editor.active_line.background"));
            if let Some(expected) = color(&s["players"][0], "selection") { assert_eq!(theme.selection, expected); }
            assert_eq!(fonts, (theme.font_family.clone(), theme.font_size, theme.mono_font_family.clone(), theme.mono_font_size));
        }
    }

    #[test]
    fn k19_missing_copies_and_default() {
        let missing = std::env::temp_dir().join(format!("missing-themes-{}", crate::state::win::new_uuid()));
        assert!(super::load(&missing).is_empty());
        let mut theme = gpui_kit::component::Theme::default();
        let before = theme.clone();
        assert!(super::project(super::load(&missing).first(), &mut theme).is_none());
        assert_eq!(theme.colors, before.colors);
        assert_eq!(theme.highlight_theme, before.highlight_theme);
        assert_eq!(theme.mode, before.mode);
        assert_eq!(super::super::settings::Values::default().theme, "One Dark");
        assert_eq!(super::color(&serde_json::json!({"bad":"#oops"}), "bad"), None);
    }
    /// I-12: the breadcrumb separator and heading colours are the theme JSON's `text.placeholder` and `syntax.title.color`.
    #[test]
    fn k34_breadcrumb_colors_follow_the_theme_json() {
        use super::{breadcrumb_colors, catalog, color};
        for name in ["One Dark", "One Light"] {
            let Some(entry) = catalog().iter().find(|e| e.name == name) else { continue };
            let style = &entry.theme["style"];
            let got = breadcrumb_colors(Some(entry));
            assert_eq!(got.separator, color(style, "text.placeholder"), "{name}: separator");
            assert!(got.separator.is_some() && got.title.is_some(), "{name}");
            assert_eq!(got.title, color(&style["syntax"]["title"], "color"), "{name}: title");
        }
        let bare = super::Entry { name: "bare".into(), source: String::new(), theme: serde_json::json!({"style": {}}) };
        let got = breadcrumb_colors(Some(&bare));
        assert!(got.title.is_none(), "no syntax.title: the muted text colour stays");
        assert_eq!(got.separator, color(&catalog().iter().find(|e| e.name == "One Dark").unwrap().theme["style"], "text.placeholder"));
        assert_eq!(breadcrumb_colors(None), super::BreadcrumbColors { separator: None, title: None });
    }

    #[test]
    fn k07_gutter_geometry_and_colors() {
        use gpui_kit::{base::EditorGutterTheme, px, rgb};
        for (digits, gutter, text) in [(1, 87., 92.), (4, 87., 92.), (5, 96., 101.)] {
            assert_eq!(EditorGutterTheme::width(digits, px(9.)), px(gutter));
            assert_eq!(EditorGutterTheme::text_start(digits, px(9.)), px(text));
        }
        let entry = super::catalog().iter().find(|e| e.name == "One Light").unwrap();
        let theme = super::project(Some(entry), &mut gpui_kit::component::Theme::default()).unwrap();
        assert_eq!(theme.line_number, rgb(0xb4b4bb).into());
        assert_eq!(theme.active_line_number, rgb(0x44454b).into());
    }
    #[test]
    fn k04_active_line_uses_zed_one_light_color() {
        let entry = super::catalog().iter().find(|e| e.name == "One Light").unwrap();
        let mut theme = gpui_kit::component::Theme::default();
        super::project(Some(entry), &mut theme);
        let color: gpui_kit::Rgba = theme.highlight_theme.style.editor_active_line.unwrap().into();
        assert_eq!(color, gpui_kit::rgba(0xebebecbf));
    }
}

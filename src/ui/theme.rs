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
            "pane.focused_border" => 0x62adef,
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
    // I-15: the colour of editor text no syntax capture covers (`editor_view` applies it).
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

/// I-15: the theme JSON's `style.syntax` as editor highlight styles (key -> colour, `font_style`, `font_weight`).
/// Every key is kept, even one with all fields null: for Zed it still ends the capture-name lookup.
fn syntax_styles(entry: Option<&Entry>) -> std::collections::HashMap<String, gpui_kit::HighlightStyle> {
    let Some(syntax) = entry.and_then(|e| e.theme["style"]["syntax"].as_object()) else { return Default::default() };
    syntax.iter().map(|(key, value)| {
        let font_style = match value["font_style"].as_str() {
            Some("italic") => Some(gpui_kit::FontStyle::Italic),
            Some("oblique") => Some(gpui_kit::FontStyle::Oblique),
            _ => None,
        };
        let style = gpui_kit::HighlightStyle {
            color: color(value, "color"),
            font_style,
            font_weight: value["font_weight"].as_f64().map(|w| gpui_kit::FontWeight(w as f32)),
            ..Default::default()
        };
        (key.clone(), style)
    }).collect()
}

/// K-46: `border.variant`, the border of a markdown preview code block (W-51 `code_block.border_color`); replaced on
/// every theme change. None when no theme is loaded.
#[derive(Clone, Copy, Debug, PartialEq)]
pub struct CodeBlockBorder(pub Option<Hsla>);

impl gpui_kit::Global for CodeBlockBorder {}

fn code_block_border(entry: Option<&Entry>) -> CodeBlockBorder {
    let Some(entry) = entry else { return CodeBlockBorder(None) };
    let base_name = if entry.theme["appearance"] == "light" { "One Light" } else { "One Dark" };
    let base = catalog().iter().find(|e| e.name == base_name).map(|e| &e.theme["style"]).unwrap_or(&serde_json::Value::Null);
    CodeBlockBorder(resolved_color(&entry.theme["style"], base, "border.variant"))
}

/// Sidebar tokens without gpui-kit fields; replaced on every theme change.
#[derive(Clone, Copy)]
pub struct SidebarColors {
    pub focused_border: Hsla,
    pub hover: Option<Hsla>,
    pub active: Option<Hsla>,
}

impl gpui_kit::Global for SidebarColors {}

fn panel_focused_border(style: &serde_json::Value, light: bool) -> Hsla {
    // theme.fallback panel.focused_border: Zed blue dark step 8 / light step 10 (K-39).
    color(style, "panel.focused_border").unwrap_or_else(|| rgb(if light { 0x0588f0 } else { 0x2870bd }).into())
}

fn sidebar_colors(entry: Option<&Entry>) -> SidebarColors {
    let style = entry.map(|e| &e.theme["style"]).unwrap_or(&serde_json::Value::Null);
    let light = entry.is_some_and(|e| e.theme["appearance"] == "light");
    let base_name = if light { "One Light" } else { "One Dark" };
    let base = catalog().iter().find(|e| e.name == base_name).map(|e| &e.theme["style"]).unwrap_or(&serde_json::Value::Null);
    SidebarColors {
        focused_border: panel_focused_border(style, light),
        hover: resolved_color(style, base, "ghost_element.hover"),
        active: resolved_color(style, base, "ghost_element.active"),
    }
}

pub fn apply(name: &str, cx: &mut gpui_kit::App) {
    let entry = catalog().iter().find(|entry| entry.name == name);
    if let Some(entry) = entry {
        let mode = if entry.theme["appearance"] == "light" { gpui_kit::component::ThemeMode::Light } else { gpui_kit::component::ThemeMode::Dark };
        gpui_kit::component::Theme::change(mode, None, cx);
    }
    cx.set_global(breadcrumb_colors(entry));
    cx.set_global(sidebar_colors(entry));
    cx.set_global(code_block_border(entry));
    super::syntax::set_theme(syntax_styles(entry));
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
    fn k39_sidebar_theme_tokens() {
        use serde_json::json;
        assert_eq!(super::panel_focused_border(&json!({}), false), gpui_kit::rgb(0x2870bd).into());
        assert_eq!(super::panel_focused_border(&json!({"panel.focused_border": null}), true), gpui_kit::rgb(0x0588f0).into());
        for light in [false, true] {
            assert_eq!(super::panel_focused_border(&json!({"panel.focused_border": "#123456"}), light), gpui_kit::rgb(0x123456).into());
        }
        for entry in super::catalog() {
            let colors = super::sidebar_colors(Some(entry));
            for (actual, key) in [(colors.hover, "ghost_element.hover"), (colors.active, "ghost_element.active")] {
                if let Some(expected) = super::color(&entry.theme["style"], key) {
                    assert_eq!(actual, Some(expected), "{}: {key}", entry.name);
                }
            }
        }
    }
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


    /// K-46-R1: the preview code block is painted with `theme.background`, the editor background (One Dark #282c33).
    #[test]
    fn k46_preview_code_block_uses_the_editor_background() {
        let one = super::catalog().iter().find(|e| e.name == "One Dark").unwrap();
        let mut theme = gpui_kit::component::Theme::default();
        super::project(Some(one), &mut theme).unwrap();
        assert_eq!(theme.background, super::color(&one.theme["style"], "editor.background").unwrap());
        assert_eq!(theme.background, gpui_kit::rgb(0x282c33).into());
    }
    /// K-46: the preview code block border is `border.variant`, with the One value when a theme lacks it.
    #[test]
    fn k46_code_block_border_is_border_variant() {
        for entry in super::catalog() {
            let got = super::code_block_border(Some(entry)).0;
            assert!(got.is_some(), "{}", entry.name);
            if let Some(own) = super::color(&entry.theme["style"], "border.variant") { assert_eq!(got, Some(own), "{}", entry.name); }
        }
        let bare = super::Entry { name: "bare".into(), source: String::new(), theme: serde_json::json!({"style": {}}) };
        let one = super::catalog().iter().find(|e| e.name == "One Dark").unwrap();
        assert_eq!(super::code_block_border(Some(&bare)), super::code_block_border(Some(one)));
        assert_eq!(super::code_block_border(None), super::CodeBlockBorder(None));
    }

    /// I-15: `style.syntax` becomes editor styles; keys with only null fields are kept.
    #[test]
    fn k42b_syntax_styles_follow_the_theme_json() {
        use gpui_kit::{FontStyle, FontWeight, rgb};
        let json = serde_json::json!({"style": {"syntax": {
            "keyword": {"color": "#112233", "font_style": "italic", "font_weight": 700},
            "none": {"color": null, "font_style": null, "font_weight": null},
        }}});
        let entry = super::Entry { name: "t".into(), source: String::new(), theme: json };
        let styles = super::syntax_styles(Some(&entry));
        assert_eq!(styles.len(), 2);
        let keyword = styles["keyword"];
        assert_eq!((keyword.color, keyword.font_style, keyword.font_weight), (Some(rgb(0x112233).into()), Some(FontStyle::Italic), Some(FontWeight(700.))));
        assert_eq!(styles["none"], gpui_kit::HighlightStyle::default());
        assert!(super::syntax_styles(None).is_empty());
        for name in ["One Dark", "One Light"] {
            let Some(entry) = super::catalog().iter().find(|e| e.name == name) else { continue };
            let styles = super::syntax_styles(Some(entry));
            assert_eq!(styles.len(), entry.theme["style"]["syntax"].as_object().unwrap().len(), "{name}");
            assert!(styles["keyword"].color.is_some() && styles["title"].color.is_some(), "{name}");
        }
    }

    /// K-47: the editor's default text colour is the theme's `editor.foreground` (One Dark `#acb2be`), not `text`.
    #[test]
    fn k47_editor_foreground_is_the_themes_editor_foreground() {
        use gpui_kit::rgb;
        let project_fg = |entry: &super::Entry| {
            let mut theme = gpui_kit::component::Theme::default();
            super::project(Some(entry), &mut theme);
            (theme.highlight_theme.style.editor_foreground, theme.foreground)
        };
        for entry in super::catalog() {
            let (editor, _) = project_fg(entry);
            if let Some(expected) = super::color(&entry.theme["style"], "editor.foreground") {
                assert_eq!(editor, Some(expected), "{}", entry.name);
            }
            assert!(editor.is_some(), "{}: One fallback", entry.name);
        }
        let one_dark = super::catalog().iter().find(|e| e.name == "One Dark").unwrap();
        let (editor, ui_text) = project_fg(one_dark);
        assert_eq!(editor, Some(rgb(0xacb2be).into()));
        assert_ne!(editor, Some(ui_text), "the UI's `text` is a different colour (#dce0e5)");
        // A theme without the token takes the same-appearance One value.
        let bare = super::Entry { name: "bare".into(), source: String::new(), theme: serde_json::json!({"appearance": "dark", "style": {}}) };
        assert_eq!(project_fg(&bare).0, Some(rgb(0xacb2be).into()));
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

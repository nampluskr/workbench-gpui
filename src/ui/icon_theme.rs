//! Local icon theme catalog (resources/zed-icon-themes) and file/folder icon lookup from theme data.
//!
//! Icon paths in a theme JSON are relative to its bundle folder (the extension root), as in Zed.
//! They are served to gpui through the `res/` asset prefix (see `zed_icons::Assets`).

use gpui_kit::*;
use gpui_kit::component::Icon;
use serde_json::Value;

#[derive(Clone, Debug)]
pub struct Entry {
    pub name: String,
    /// JSON path under the icon theme root, `/` separated (Extensions sort key).
    pub source: String,
    pub theme: Value,
    /// Bundle folder under `resources/`, `/` separated (base for icon paths).
    base: String,
}

fn load(root: &std::path::Path) -> Vec<Entry> {
    let root_name = root.file_name().map(|s| s.to_string_lossy().into_owned()).unwrap_or_default();
    fn visit(dir: &std::path::Path, root: &std::path::Path, root_name: &str, result: &mut Vec<Entry>) {
        let Ok(files) = std::fs::read_dir(dir) else { return };
        let mut paths: Vec<_> = files.filter_map(Result::ok).map(|f| f.path()).collect();
        paths.sort();
        for path in paths {
            if path.is_dir() {
                // The pack's icons/ folder holds thousands of SVGs and no theme JSON.
                if path.file_name().is_some_and(|name| name != "icons") { visit(&path, root, root_name, result); }
                continue;
            }
            if path.extension().and_then(|s| s.to_str()) != Some("json") { continue; }
            let Some(mut family) = std::fs::read_to_string(&path).ok().and_then(|text|
                jsonc_parser::parse_to_serde_value::<Value>(&text, &Default::default()).ok()) else { continue };
            let Ok(relative) = path.strip_prefix(root) else { continue };
            let source = relative.to_string_lossy().replace('\\', "/");
            let bundle = source.split('/').next().unwrap_or_default();
            let themes = family.get_mut("themes").map(Value::take);
            for theme in themes.as_ref().and_then(Value::as_array).into_iter().flatten() {
                if let Some(name) = theme["name"].as_str() {
                    result.push(Entry { name: name.into(), source: source.clone(), theme: theme.clone(),
                        base: format!("{root_name}/{bundle}") });
                }
            }
        }
    }
    let mut result = Vec::new();
    visit(root, root, &root_name, &mut result);
    // Zed (Default) leads the list; the rest keep file path and array order.
    result.sort_by_key(|entry| entry.name != super::settings::ICON_THEME);
    result
}

pub fn catalog() -> &'static [Entry] {
    static CATALOG: std::sync::OnceLock<Vec<Entry>> = std::sync::OnceLock::new();
    CATALOG.get_or_init(|| load(&super::zed_icons::resources_dir().join("zed-icon-themes")))
}

/// Selectable names. Always starts with the default so Settings stays valid when the copies are missing.
pub fn names() -> Vec<String> {
    let mut names: Vec<String> = catalog().iter().map(|entry| entry.name.clone()).collect();
    if !names.iter().any(|name| name == super::settings::ICON_THEME) { names.insert(0, super::settings::ICON_THEME.into()); }
    names
}

/// Asset path (`res/...`) of a theme-relative icon path; None if it climbs out of `resources/`.
fn asset(entry: &Entry, relative: &str) -> Option<String> {
    let mut parts: Vec<&str> = entry.base.split('/').collect();
    for part in relative.split('/') {
        match part {
            "" | "." => {}
            ".." => { parts.pop()?; }
            part => parts.push(part),
        }
    }
    Some(format!("res/{}", parts.join("/")))
}

/// Icon key for a file name: whole name, then each dotted suffix, then the stem before the first dot.
fn key<'a>(theme: &'a Value, name: &str) -> Option<&'a str> {
    let get = |s: &str| theme["file_stems"][s].as_str().or_else(|| theme["file_suffixes"][s].as_str());
    if let Some(key) = get(name) { return Some(key); }
    let (mut rest, mut first) = (name, None);
    while let Some((prefix, suffix)) = rest.split_once('.') {
        first.get_or_insert(prefix);
        if let Some(key) = get(suffix) { return Some(key); }
        rest = suffix;
    }
    first.and_then(get)
}

/// Looks `find` up in the theme, then in the default theme (Zed falls back the same way).
fn with_default(entry: &Entry, find: impl Fn(&Entry) -> Option<String>) -> Option<String> {
    find(entry).or_else(|| catalog().iter().find(|e| e.name == super::settings::ICON_THEME).filter(|d| d.name != entry.name).and_then(find))
}

pub fn file_icon_path(entry: &Entry, file_name: &str) -> Option<String> {
    let typed = |entry: &Entry, key: &str| entry.theme["file_icons"][key]["path"].as_str().and_then(|path| asset(entry, path));
    let key = key(&entry.theme, file_name);
    key.and_then(|key| with_default(entry, |e| typed(e, key))).or_else(|| with_default(entry, |e| typed(e, "default")))
}

pub fn folder_icon_path(entry: &Entry, folder_name: &str, expanded: bool) -> Option<String> {
    let state = if expanded { "expanded" } else { "collapsed" };
    with_default(entry, |e| {
        let relative = e.theme["named_directory_icons"][folder_name][state].as_str().or_else(|| e.theme["directory_icons"][state].as_str());
        relative.and_then(|path| asset(e, path))
    })
}

fn current(cx: &App) -> Option<&'static Entry> {
    let name = super::settings::icon_theme_name(cx);
    catalog().iter().find(|entry| entry.name == name)
}

/// File or folder icon of the selected icon theme; None when no theme data exists (caller keeps its fallback).
/// The default theme stays a monochrome mask in the text color; other themes carry their own colors.
pub fn icon(path: &std::path::Path, is_dir: bool, expanded: bool, size: Rems, cx: &App) -> Option<AnyElement> {
    let entry = current(cx)?;
    let name = path.file_name()?.to_string_lossy();
    let asset = if is_dir { folder_icon_path(entry, &name, expanded) } else { file_icon_path(entry, &name) }?;
    Some(if entry.name == super::settings::ICON_THEME {
        Icon::default().path(asset).size(size).flex_shrink_0().into_any_element()
    } else {
        img(asset).size(size).flex_shrink_0().into_any_element()
    })
}

#[cfg(test)]
mod tests {
    #[test]
    fn k22_names_include_all_nine_copied_icon_themes() {
        let names = super::names();
        assert_eq!(names.len(), 9);
        assert_eq!(names[0], super::super::settings::ICON_THEME);
        assert_eq!(names.iter().filter(|name| name.contains("Monochrome")).count(), 4);
        for flavor in ["Latte", "Frappé", "Macchiato", "Mocha"] {
            assert!(names.iter().any(|name| name == &format!("Catppuccin {flavor}")));
            assert!(names.iter().any(|name| name.contains(flavor) && name.contains("Monochrome")));
        }
    }
    use super::{Entry, asset, catalog, file_icon_path, folder_icon_path, names};

    fn entry(name: &str) -> &'static Entry {
        catalog().iter().find(|e| e.name == name).unwrap_or_else(|| panic!("missing {name}"))
    }

    #[test]
    fn k20_catalog_lists_default_first_and_catppuccin_flavors() {
        let names = names();
        assert_eq!(names[0], super::super::settings::ICON_THEME);
        for flavor in ["Catppuccin Latte", "Catppuccin Frappé", "Catppuccin Macchiato", "Catppuccin Mocha"] {
            assert!(names.iter().any(|n| n == flavor), "{flavor}");
        }
    }

    #[test]
    fn k20_default_theme_maps_extensions_stems_and_folders() {
        let zed = entry(super::super::settings::ICON_THEME);
        let path = |name| file_icon_path(zed, name);
        assert_eq!(path("main.rs").unwrap(), "res/zed-icons/file_icons/rust.svg");
        assert_eq!(path("Dockerfile.prod").unwrap(), "res/zed-icons/file_icons/docker.svg");
        assert_eq!(path("a.data.json").unwrap(), "res/zed-icons/file_icons/code.svg");
        assert_eq!(path("unknown.zzz").unwrap(), "res/zed-icons/file_icons/file.svg");
        assert_eq!(folder_icon_path(zed, "src", false).unwrap(), "res/zed-icons/file_icons/folder.svg");
        assert_eq!(folder_icon_path(zed, "src", true).unwrap(), "res/zed-icons/file_icons/folder_open.svg");
    }

    #[test]
    fn k20_catppuccin_maps_by_theme_json_and_named_folders() {
        let mocha = entry("Catppuccin Mocha");
        assert_eq!(file_icon_path(mocha, "main.rs").unwrap(), "res/zed-icon-themes/catppuccin-icons/icons/mocha/rust.svg");
        assert!(folder_icon_path(mocha, "src", false).unwrap().starts_with("res/zed-icon-themes/catppuccin-icons/icons/mocha/"));
        assert_ne!(folder_icon_path(mocha, "admin", false), folder_icon_path(mocha, "plain-folder", false));
        // Every mapped file exists in the copied pack.
        let resources = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("resources");
        for name in ["main.rs", "README.md", "Cargo.toml", "x.unknown"] {
            assert!(resources.join(file_icon_path(mocha, name).unwrap().strip_prefix("res/").unwrap()).is_file(), "{name}");
        }
    }

    #[test]
    fn k20_asset_path_cannot_leave_resources() {
        let zed = entry(super::super::settings::ICON_THEME);
        assert_eq!(asset(zed, "../../zed-icons/a.svg").unwrap(), "res/zed-icons/a.svg");
        assert_eq!(asset(zed, "../../../x.svg"), None);
    }
}

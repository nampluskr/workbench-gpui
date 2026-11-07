use gpui_kit::*;
use gpui_kit::component::{ActiveTheme as _, h_flex, v_flex};
use gpui_kit::component::button::{Button, ButtonVariants as _};
use gpui_kit::component::input::{Input, InputEvent, InputState};
use gpui_kit::prelude::FluentBuilder as _;
use serde_json::Value;

use super::{Workbench, keymap, metrics::extensions as layout};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Category { All, Themes, IconThemes }

impl Category {
    fn label(self) -> &'static str {
        match self { Self::All => "All", Self::Themes => "Themes", Self::IconThemes => "Icon Themes" }
    }
}

/// Category the next Extensions render should show (set by the theme selectors' Install links).
struct PendingCategory(Category);
impl Global for PendingCategory {}

pub(super) fn request_category(icon_themes: bool, cx: &mut App) {
    cx.set_global(PendingCategory(if icon_themes { Category::IconThemes } else { Category::Themes }));
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Status { All, Installed, NotInstalled }

impl Status {
    fn label(self) -> &'static str {
        match self { Self::All => "All", Self::Installed => "Installed", Self::NotInstalled => "Not Installed" }
    }
}

struct Resource {
    name: String,
    category: Category,
    source_path: String,
    theme_index: usize,
    theme: Value,
    family: Value,
}

/// Minimal extension.toml reader for the copied manifests: top-level `key = "text"` and `key = ["a", "b"]` lines.
/// Returns `{name, version, description, author}`; authors lose their `<email>` part.
fn manifest(dir: &std::path::Path) -> Value {
    let Ok(text) = std::fs::read_to_string(dir.join("extension.toml")) else { return Value::Null };
    let mut keys = serde_json::Map::new();
    for line in text.lines().take_while(|line| !line.trim_start().starts_with('[')) {
        let Some((key, value)) = line.split_once('=') else { continue };
        if let Ok(value) = serde_json::from_str::<Value>(value.trim()) { keys.insert(key.trim().into(), value); }
    }
    let authors = keys.get("authors").and_then(Value::as_array).map(|authors| authors.iter().filter_map(Value::as_str)
        .map(|author| author.split('<').next().unwrap_or(author).trim()).collect::<Vec<_>>().join(", "));
    let mut result = serde_json::Map::new();
    for key in ["name", "version", "description"] {
        if let Some(value) = keys.get(key) { result.insert(key.into(), value.clone()); }
    }
    if let Some(authors) = authors { result.insert("author".into(), authors.into()); }
    Value::Object(result)
}

/// One card per copied extension manifest; built-in resources are not extensions.
fn resources() -> &'static [Resource] {
    static RESOURCES: std::sync::OnceLock<Vec<Resource>> = std::sync::OnceLock::new();
    RESOURCES.get_or_init(|| {
        let resources = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("resources");
        let mut seen = std::collections::HashSet::new();
        let mut make = |root: &str, source: &str, category: Category| {
            let bundle = source.split('/').next().unwrap_or_default();
            let meta = manifest(&resources.join(root).join(bundle));
            let name = meta.get("name")?.as_str()?.to_owned();
            if !seen.insert((root.to_owned(), bundle.to_owned())) { return None; }
            Some(Resource { name, category, source_path: source.into(), theme_index: 0, theme: Value::Null, family: meta })
        };
        let mut result: Vec<_> = super::theme::catalog().iter().filter_map(|e| make("zed-themes", &e.source, Category::Themes)).collect();
        result.extend(super::icon_theme::catalog().iter().filter_map(|e| make("zed-icon-themes", &e.source, Category::IconThemes)));
        result
    })
}

impl Resource {
    fn metadata(&self, key: &str) -> &str {
        self.theme.get(key).and_then(Value::as_str).filter(|s| !s.is_empty())
            .or_else(|| self.family.get(key).and_then(Value::as_str)).unwrap_or_default()
    }
    fn version_text(&self) -> Option<String> {
        let version = self.metadata("version");
        (!version.is_empty()).then(|| format!("v{version}"))
    }
    fn matches(&self, query: &str, category: Category, status: Status) -> bool {
        let text = format!("{} {} {}", self.name, self.metadata("description"), self.metadata("author")).to_lowercase();
        status != Status::NotInstalled
            && (category == Category::All || category == self.category)
            && query.split_whitespace().all(|word| text.contains(&word.to_lowercase()))
    }
}

fn visible<'a>(resources: &'a [Resource], query: &str, category: Category, status: Status) -> Vec<&'a Resource> {
    let mut result: Vec<_> = resources.iter().filter(|r| r.matches(query, category, status)).collect();
    // Theme file path, then array order; icons last. Never reorder by display name.
    result.sort_by_key(|r| (r.category == Category::IconThemes, &r.source_path, r.theme_index));
    result
}

fn empty_message(query: &str, status: Status) -> String {
    let kind = match status { Status::All => "", Status::Installed => "installed ", Status::NotInstalled => "uninstalled " };
    let query = query.trim();
    let suffix = if query.is_empty() { String::new() } else { format!(" that match \"{query}\"") };
    format!("No {kind}extensions{suffix}")
}

struct Extensions {
    search: Entity<InputState>,
    category: Category,
    status: Status,
    _search_subscription: Subscription,
}

impl Extensions {
    fn new(window: &mut Window, cx: &mut Context<Self>) -> Self {
        let search = cx.new(|cx| InputState::new(window, cx).placeholder("Search extensions…"));
        let subscription = cx.subscribe(&search, |_, _, _: &InputEvent, cx| cx.notify());
        Self { search, category: Category::All, status: Status::All, _search_subscription: subscription }
    }
}

impl Render for Extensions {
    fn render(&mut self, _: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        if let Some(category) = cx.try_global::<PendingCategory>().map(|pending| pending.0) {
            self.category = category;
            cx.remove_global::<PendingCategory>();
        }
        let query = self.search.read(cx).value();
        let theme = cx.theme();
        let selected = theme.secondary_active;
        let mut statuses = h_flex().gap(layout::CATEGORY_GAP);
        for (index, status) in [Status::All, Status::Installed, Status::NotInstalled].into_iter().enumerate() {
            statuses = statuses.child(Button::new(("extension-status", index)).label(status.label()).ghost()
                .when(self.status == status, |button| button.bg(selected))
                .on_click(cx.listener(move |this, _, _, cx| { this.status = status; cx.notify(); })));
        }
        let mut categories = h_flex().px(layout::HEADER_PADDING).py(layout::CATEGORY_PADDING_Y).gap(layout::CATEGORY_GAP)
            .border_b_1().border_color(theme.border);
        for (index, category) in [Category::All, Category::Themes, Category::IconThemes].into_iter().enumerate() {
            categories = categories.child(Button::new(("extension-category", index)).label(category.label()).ghost()
                .when(self.category == category, |button| button.bg(selected))
                .on_click(cx.listener(move |this, _, _, cx| { this.category = category; cx.notify(); })));
        }
        let mut cards = v_flex().id("extension-resources").flex_1().min_h_0().overflow_y_scroll().px(layout::LIST_PADDING).pb(layout::LIST_PADDING);
        let resources = visible(resources(), &query, self.category, self.status);
        if resources.is_empty() { cards = cards.child(empty_message(&query, self.status)); }
        for resource in resources {
            cards = cards.child(h_flex().mt(layout::CARD_MARGIN).h(layout::CARD_HEIGHT).p(layout::CARD_PADDING)
                .border_1().border_color(theme.border).rounded(layout::CARD_RADIUS).justify_between()
                .child(v_flex().flex_1().min_w_0().gap(layout::CARD_GAP)
                    .child(h_flex().gap(layout::CARD_GAP).child(resource.name.clone())
                        .when_some(resource.version_text(), |row, version| row.child(div().text_color(theme.muted_foreground).child(version))))
                    .child(resource.category.label())
                    .child(resource.metadata("description").to_owned())
                    .child(div().text_color(theme.muted_foreground).child(resource.metadata("author").to_owned())))
                .child(div().text_color(theme.muted_foreground).child("Installed")));
        }
        v_flex().size_full().bg(theme.background).text_color(theme.foreground)
            .child(v_flex().pt(layout::HEADER_PADDING).px(layout::HEADER_PADDING).gap(layout::HEADER_GAP)
                .child("Extensions")
                .child(h_flex().gap(layout::HEADER_GAP)
                    .child(div().flex_1().h(layout::SEARCH_HEIGHT).child(Input::new(&self.search)))
                    .child(statuses)))
            .child(categories).child(cards)
    }
}

impl Workbench {
    pub(super) fn on_open_extensions(&mut self, _: &keymap::zed::Extensions, window: &mut Window, cx: &mut Context<Self>) {
        self.open_tool("workbench://Extensions", window, cx, |window, cx| {
            let view = cx.new(|cx| Extensions::new(window, cx));
            let focus = view.read(cx).search.focus_handle(cx);
            (view.into(), focus)
        });
    }
}

#[cfg(test)]
mod tests {
    use super::{Category, Resource, Status, resources};

    fn find(name: &str, category: Category) -> &'static Resource {
        resources().iter().find(|r| r.name == name && r.category == category).unwrap_or_else(|| panic!("missing {name}"))
    }

    #[test]
    fn bundled_filters_categories_and_search() {
        let count = |query, category, status| resources().iter().filter(|r| r.matches(query, category, status)).count();
        let (themes, icons) = (2, 1);
        assert_eq!(count("", Category::All, Status::All), themes + icons);
        assert_eq!(count("", Category::All, Status::Installed), resources().len());
        assert_eq!(count("", Category::All, Status::NotInstalled), 0);
        assert_eq!(count("", Category::Themes, Status::All), themes);
        assert_eq!(count("", Category::IconThemes, Status::All), icons);
        assert_eq!(count("  CATPPUCCIN  ", Category::IconThemes, Status::Installed), 1);
        assert_eq!(count("catppuccin", Category::Themes, Status::All), 1);
        assert_eq!(count("missing", Category::All, Status::All), 0);
    }

    #[test]
    fn k20_resources_show_extension_manifests() {
        let (mocha, mauve, classic) = (find("Catppuccin Icons", Category::IconThemes), find("Catppuccin", Category::Themes),
            find("macOS Classic Theme", Category::Themes));
        assert_eq!(mocha.version_text().as_deref(), Some("v1.24.0"));
        assert_eq!(mocha.metadata("description"), "🦊 Soothing pastel icons for Zed");
        assert_eq!((mocha.metadata("author"), mocha.category), ("Catppuccin", Category::IconThemes));
        assert_eq!(mauve.version_text().as_deref(), Some("v0.2.27"));
        assert_eq!(mauve.metadata("author"), "Catppuccin");
        assert_eq!(classic.version_text().as_deref(), Some("v0.4.0"));
        assert_eq!(classic.metadata("author"), "Jason Lee");
        assert_eq!(resources().len(), 3);
        assert!(resources().iter().all(|r| !r.source_path.starts_with("zed/")));
    }

    #[test]
    fn k20_manifest_reader_matches_toml_parser() {
        let resources = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("resources");
        for dir in ["zed-themes/catppuccin", "zed-themes/macos-classic", "zed-icon-themes/catppuccin-icons"] {
            let text = std::fs::read_to_string(resources.join(dir).join("extension.toml")).unwrap();
            let parsed: toml::Table = text.parse().unwrap();
            let read = super::manifest(&resources.join(dir));
            assert_eq!(read["version"], parsed["version"].as_str().unwrap(), "{dir}");
            assert_eq!(read["description"], parsed["description"].as_str().unwrap(), "{dir}");
            let authors: Vec<_> = parsed["authors"].as_array().unwrap().iter().map(|a| a.as_str().unwrap().split('<').next().unwrap().trim().to_owned()).collect();
            assert_eq!(read["author"], authors.join(", "), "{dir}");
        }
        assert!(super::manifest(&resources.join("zed-themes/zed")).is_null());
    }

    #[test]
    fn search_includes_description_and_author_as_and_terms() {
        let resource = Resource { name: "Example".into(), category: Category::Themes, source_path: "b.json".into(), theme_index: 0,
            theme: serde_json::json!({"version":"9.8.7", "description":"High contrast theme", "author":"Creator"}), family: serde_json::Value::Null };
        assert!(resource.matches("CONTRAST", Category::All, Status::Installed));
        assert!(resource.matches("Creator", Category::All, Status::All));
        assert!(resource.matches("  EXAMPLE creator CONTRAST ", Category::All, Status::All));
        assert!(!resource.matches("Creator missing", Category::All, Status::All));
        assert!(!resource.matches("9.8.7", Category::All, Status::All));
        assert!(!resource.matches("contrast", Category::IconThemes, Status::All));
    }

    #[test]
    fn k18_sort_metadata_and_empty_states() {
        let make = |name: &str, path: &str, index, category| Resource { name: name.into(), source_path: path.into(), theme_index: index, category,
            theme: serde_json::json!({"version":"2", "description":"Theme description", "author":""}),
            family: serde_json::json!({"version":"1", "description":"Family description", "author":"Family author"}) };
        let resources = [make("Icons", "", 0, Category::IconThemes), make("A", "b.json", 0, Category::Themes),
            make("Z", "a.json", 1, Category::Themes), make("Y", "a.json", 0, Category::Themes)];
        let sorted = super::visible(&resources, "", Category::All, Status::All);
        assert_eq!(sorted.iter().map(|r| r.name.as_str()).collect::<Vec<_>>(), ["Y", "Z", "A", "Icons"]);
        let filtered = super::visible(&resources, "family", Category::Themes, Status::Installed);
        assert_eq!(filtered.iter().map(|r| r.name.as_str()).collect::<Vec<_>>(), ["Y", "Z", "A"]);
        assert_eq!(resources[1].version_text().as_deref(), Some("v2"));
        assert_eq!(resources[1].metadata("description"), "Theme description");
        assert_eq!(resources[1].metadata("author"), "Family author");
        for (status, message) in [(Status::All, "No extensions"), (Status::Installed, "No installed extensions"), (Status::NotInstalled, "No uninstalled extensions")] {
            assert_eq!(super::empty_message(" \t", status), message);
            assert_eq!(super::empty_message("  Missing  ", status), format!("{message} that match \"{}\"", "Missing"));
        }
    }
}

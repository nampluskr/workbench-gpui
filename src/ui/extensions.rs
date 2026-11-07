use gpui_kit::*;
use gpui_kit::component::{ActiveTheme as _, h_flex, v_flex};
use gpui_kit::component::button::{Button, ButtonVariants as _};
use gpui_kit::component::input::{Input, InputEvent, InputState};
use gpui_kit::prelude::FluentBuilder as _;
use serde_json::Value;

use super::{Workbench, keymap, settings, metrics::extensions as layout};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Category { All, Themes, IconThemes }

impl Category {
    fn label(self) -> &'static str {
        match self { Self::All => "All", Self::Themes => "Themes", Self::IconThemes => "Icon Themes" }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Status { All, Installed, NotInstalled }

impl Status {
    fn label(self) -> &'static str {
        match self { Self::All => "All", Self::Installed => "Installed", Self::NotInstalled => "Not Installed" }
    }
}

struct Resource {
    name: &'static str,
    category: Category,
    source_path: &'static str,
    theme_index: usize,
    theme: Value,
    family: Value,
}

// Single catalog of bundled extension resources. Phase 7 adds copied resources and original metadata here.
// Current theme is gpui-kit's built-in theme; icons come from resources/zed-icons.
// No theme JSON metadata exists for these resources; Null keeps absent fields empty.
// Phase 7 supplies copied theme/family JSON and its path/array index, without reading installed Zed files.
const RESOURCES: &[Resource] = &[
    Resource { name: settings::THEME, category: Category::Themes, source_path: "", theme_index: 0, theme: Value::Null, family: Value::Null },
    Resource { name: settings::ICON_THEME, category: Category::IconThemes, source_path: "", theme_index: 0, theme: Value::Null, family: Value::Null },
];

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
    result.sort_by_key(|r| (r.category == Category::IconThemes, r.source_path, r.theme_index));
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
        let resources = visible(RESOURCES, &query, self.category, self.status);
        if resources.is_empty() { cards = cards.child(empty_message(&query, self.status)); }
        for resource in resources {
            cards = cards.child(h_flex().mt(layout::CARD_MARGIN).h(layout::CARD_HEIGHT).p(layout::CARD_PADDING)
                .border_1().border_color(theme.border).rounded(layout::CARD_RADIUS).justify_between()
                .child(v_flex().flex_1().min_w_0().gap(layout::CARD_GAP)
                    .child(h_flex().gap(layout::CARD_GAP).child(resource.name)
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
    use super::{Category, Resource, Status, RESOURCES};

    #[test]
    fn bundled_filters_categories_and_search() {
        let count = |query, category, status| RESOURCES.iter().filter(|r| r.matches(query, category, status)).count();
        assert_eq!(count("", Category::All, Status::All), 2);
        assert_eq!(count("", Category::All, Status::Installed), RESOURCES.len());
        assert_eq!(count("", Category::All, Status::NotInstalled), 0);
        assert_eq!(count("", Category::Themes, Status::All), 1);
        assert_eq!(count("", Category::IconThemes, Status::All), 1);
        assert_eq!(count("  ZED  ", Category::IconThemes, Status::Installed), 1);
        assert_eq!(count("zed", Category::Themes, Status::All), 0);
        assert_eq!(count("missing", Category::All, Status::All), 0);
        assert!(RESOURCES.iter().all(|r| r.metadata("author").is_empty() && r.version_text().is_none() && r.metadata("description").is_empty()));
    }

    #[test]
    fn search_includes_description_and_author_as_and_terms() {
        let resource = Resource { name: "Example", category: Category::Themes, source_path: "b.json", theme_index: 0,
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
        let make = |name, path, index, category| Resource { name, source_path: path, theme_index: index, category,
            theme: serde_json::json!({"version":"2", "description":"Theme description", "author":""}),
            family: serde_json::json!({"version":"1", "description":"Family description", "author":"Family author"}) };
        let resources = [make("Icons", "", 0, Category::IconThemes), make("A", "b.json", 0, Category::Themes),
            make("Z", "a.json", 1, Category::Themes), make("Y", "a.json", 0, Category::Themes)];
        let sorted = super::visible(&resources, "", Category::All, Status::All);
        assert_eq!(sorted.iter().map(|r| r.name).collect::<Vec<_>>(), ["Y", "Z", "A", "Icons"]);
        let filtered = super::visible(&resources, "family", Category::Themes, Status::Installed);
        assert_eq!(filtered.iter().map(|r| r.name).collect::<Vec<_>>(), ["Y", "Z", "A"]);
        assert_eq!(resources[1].version_text().as_deref(), Some("v2"));
        assert_eq!(resources[1].metadata("description"), "Theme description");
        assert_eq!(resources[1].metadata("author"), "Family author");
        for (status, message) in [(Status::All, "No extensions"), (Status::Installed, "No installed extensions"), (Status::NotInstalled, "No uninstalled extensions")] {
            assert_eq!(super::empty_message(" \t", status), message);
            assert_eq!(super::empty_message("  Missing  ", status), format!("{message} that match \"Missing\""));
        }
    }
}

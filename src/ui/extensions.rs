use gpui_kit::*;
use gpui_kit::component::{ActiveTheme as _, h_flex, v_flex};
use gpui_kit::component::button::{Button, ButtonVariants as _};
use gpui_kit::component::input::{Input, InputEvent, InputState};
use gpui_kit::prelude::FluentBuilder as _;

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
    version: &'static str,
    description: &'static str,
    author: &'static str,
}

// Single catalog of bundled extension resources. Phase 7 adds copied resources and original metadata here.
// Current theme is gpui-kit's built-in theme; icons come from resources/zed-icons.
// Neither resource supplies an extension manifest, so unavailable metadata stays empty.
const RESOURCES: &[Resource] = &[
    Resource { name: settings::THEME, category: Category::Themes, version: "", description: "", author: "" },
    Resource { name: settings::ICON_THEME, category: Category::IconThemes, version: "", description: "", author: "" },
];

impl Resource {
    fn matches(&self, query: &str, category: Category, status: Status) -> bool {
        let query = query.trim().to_lowercase();
        status != Status::NotInstalled
            && (category == Category::All || category == self.category)
            && (self.name.to_lowercase().contains(&query) || self.description.to_lowercase().contains(&query))
    }
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
        for resource in RESOURCES.iter().filter(|r| r.matches(&query, self.category, self.status)) {
            cards = cards.child(h_flex().mt(layout::CARD_MARGIN).h(layout::CARD_HEIGHT).p(layout::CARD_PADDING)
                .border_1().border_color(theme.border).rounded(layout::CARD_RADIUS).justify_between()
                .child(v_flex().flex_1().min_w_0().gap(layout::CARD_GAP)
                    .child(h_flex().gap(layout::CARD_GAP).child(resource.name).child(resource.version))
                    .child(resource.category.label())
                    .child(resource.description)
                    .child(div().text_color(theme.muted_foreground).child(resource.author)))
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
        assert!(RESOURCES.iter().all(|r| r.author.is_empty() && r.version.is_empty() && r.description.is_empty()));
    }

    #[test]
    fn search_includes_description_without_matching_author_or_version() {
        let resource = Resource { name: "Example", category: Category::Themes, version: "9.8.7", description: "High contrast theme", author: "Creator" };
        assert!(resource.matches("CONTRAST", Category::All, Status::Installed));
        assert!(!resource.matches("Creator", Category::All, Status::All));
        assert!(!resource.matches("9.8.7", Category::All, Status::All));
        assert!(!resource.matches("contrast", Category::IconThemes, Status::All));
    }
}

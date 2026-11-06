use std::io::Write as _;
use std::path::{Path, PathBuf};

use gpui_kit::component::{ActiveTheme as _, IndexPath, Theme, h_flex, v_flex};
use gpui_kit::component::button::{Button, ButtonVariants as _};
use gpui_kit::component::input::{Input, InputEvent, InputState, NumberInput};
use gpui_kit::component::select::{Select, SelectEvent, SelectState};
use gpui_kit::component::searchable_list::SearchableVec;
use gpui_kit::*;
use serde_json::{Value, json};

use super::{Workbench, metrics::settings_window as layout};

pub const THEME: &str = "Default Light";
pub const ICON_THEME: &str = "Zed (Default)";

#[derive(Clone, Debug, PartialEq)]
pub struct Values {
    pub ui_font_size: f32,
    pub buffer_font_size: f32,
}

impl Default for Values {
    fn default() -> Self {
        Self { ui_font_size: f32::from(super::fonts::UI_SIZE), buffer_font_size: f32::from(super::metrics::BUFFER_FONT_SIZE) }
    }
}

fn read(path: &Path) -> Result<Value, String> {
    let text = match std::fs::read_to_string(path) {
        Ok(text) => text,
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => return Ok(json!({})),
        Err(error) => return Err(error.to_string()),
    };
    let value = jsonc_parser::parse_to_serde_value::<Value>(&text, &Default::default())
        .map_err(|error| error.to_string())?;
    if !value.is_object() { return Err("Settings must be an object".into()); }
    Ok(value)
}

fn values(raw: &Value) -> Result<Values, String> {
    for (key, supported) in [("theme", THEME), ("icon_theme", ICON_THEME)] {
        if let Some(value) = raw.get(key).filter(|value| !value.is_null())
            && value.as_str() != Some(supported) {
            return Err(format!("Unsupported {key}"));
        }
    }
    let mut result = Values::default();
    for (key, target) in [("ui_font_size", &mut result.ui_font_size), ("buffer_font_size", &mut result.buffer_font_size)] {
        if let Some(value) = raw.get(key).filter(|value| !value.is_null()) {
            let number = value.as_f64().ok_or_else(|| format!("Invalid {key}"))? as f32;
            if !number.is_finite() || number <= 0. { return Err(format!("Invalid {key}")); }
            *target = number;
        }
    }
    Ok(result)
}

fn write(path: &Path, raw: &Value) -> Result<(), String> {
    let dir = path.parent().ok_or("Settings path has no parent")?;
    std::fs::create_dir_all(dir).map_err(|error| error.to_string())?;
    let tmp = path.with_extension("json.tmp");
    let bytes = serde_json::to_vec_pretty(raw).map_err(|error| error.to_string())?;
    let mut file = std::fs::File::create(&tmp).map_err(|error| error.to_string())?;
    file.write_all(&bytes).and_then(|_| file.sync_all()).map_err(|error| error.to_string())?;
    drop(file);
    crate::state::win::replace_file(&tmp, path).map_err(|error| error.to_string())
}

fn save(path: &Path, key: &str, value: Value) -> Result<Values, String> {
    let mut raw = read(path)?;
    raw[key] = value;
    let result = values(&raw)?;
    write(path, &raw)?;
    Ok(result)
}

struct Settings {
    path: Option<PathBuf>,
    values: Values,
    window: Option<WindowHandle<gpui_kit::base::Root>>,
}
impl Global for Settings {}

pub fn init(cx: &mut App) {
    cx.set_global(Settings {
        path: dirs::config_dir().map(|dir| dir.join(super::keymap::APP_DIR).join("settings.json")),
        values: Values::default(), window: None,
    });
    reload(cx);
}

fn apply(value: Values, cx: &mut App) {
    cx.global_mut::<Settings>().values = value.clone();
    Theme::update(cx, |theme| {
        theme.font_size = px(value.ui_font_size);
        theme.mono_font_size = px(value.buffer_font_size);
    });
    cx.refresh_windows();
}

pub fn reload(cx: &mut App) {
    let Some(path) = cx.global::<Settings>().path.clone() else { return };
    match read(&path).and_then(|raw| values(&raw)) {
        Ok(value) if value != cx.global::<Settings>().values => apply(value, cx),
        Ok(_) => {}
        Err(error) => eprintln!("Could not read settings: {error}"),
    }
}

pub fn ui_size(cx: &App) -> Pixels {
    px(cx.try_global::<Settings>().map_or(Values::default().ui_font_size, |settings| settings.values.ui_font_size))
}
pub fn buffer_size(cx: &App) -> Pixels {
    px(cx.try_global::<Settings>().map_or(Values::default().buffer_font_size, |settings| settings.values.buffer_font_size))
}

pub fn is_classic(open: bool, width: Pixels, default: Pixels) -> bool {
    open && width == default
}

// Titles and descriptions: Zed 4304dec7 crates/settings_ui/src/page_data.rs, appearance_page.
const ROWS: &[(&str, &str, &str)] = &[
    ("theme", "Theme Name", "The name of your selected theme."),
    ("icon_theme", "Icon Theme Name", "The name of your selected icon theme."),
    ("ui_font_size", "Font Size", "Font size for UI elements."),
    ("buffer_font_size", "Font Size", "Font size for editor text."),
];

fn matches_query(key: &str, name: &str, description: &str, query: &str) -> bool {
    let query = query.to_lowercase();
    name.to_lowercase().contains(&query) || description.to_lowercase().contains(&query) || key.contains(&query)
}

struct SettingsView {
    search: Entity<InputState>,
    ui_font: Entity<InputState>,
    buffer_font: Entity<InputState>,
    theme: Entity<SelectState<SearchableVec<SharedString>>>,
    icons: Entity<SelectState<SearchableVec<SharedString>>>,
    owner: WeakEntity<Workbench>,
    owner_window: AnyWindowHandle,
    error: Option<String>,
    _subscriptions: Vec<Subscription>,
}

impl SettingsView {
    fn new(owner: WeakEntity<Workbench>, owner_window: AnyWindowHandle, window: &mut Window, cx: &mut Context<Self>) -> Self {
        let value = cx.global::<Settings>().values.clone();
        let search = cx.new(|cx| InputState::new(window, cx).placeholder("Search settings…"));
        let ui_font = cx.new(|cx| InputState::new(window, cx).default_value(value.ui_font_size.to_string()));
        let buffer_font = cx.new(|cx| InputState::new(window, cx).default_value(value.buffer_font_size.to_string()));
        let theme = cx.new(|cx| SelectState::new(SearchableVec::new(vec![SharedString::from(THEME)]), Some(IndexPath::new(0)), window, cx));
        let icons = cx.new(|cx| SelectState::new(SearchableVec::new(vec![SharedString::from(ICON_THEME)]), Some(IndexPath::new(0)), window, cx));
        let mut subscriptions = vec![cx.subscribe(&search, |_, _, _: &InputEvent, cx| cx.notify())];
        for (key, input) in [("ui_font_size", &ui_font), ("buffer_font_size", &buffer_font)] {
            subscriptions.push(cx.subscribe(input, move |this, input, event: &InputEvent, cx| {
                if matches!(event, InputEvent::Change) {
                    match input.read(cx).value().parse::<f64>() {
                        Ok(value) if value.is_finite() && value > 0. => this.change(key, json!(value), cx),
                        _ => { this.error = Some(format!("Invalid {key}")); cx.notify(); }
                    }
                }
            }));
        }
        for (key, select) in [("theme", &theme), ("icon_theme", &icons)] {
            subscriptions.push(cx.subscribe(select, move |this, _, event: &SelectEvent<SearchableVec<SharedString>>, cx| {
                if let SelectEvent::Confirm(Some(value)) = event { this.change(key, json!(value.as_ref()), cx); }
            }));
        }
        Self { search, ui_font, buffer_font, theme, icons, owner, owner_window, error: None, _subscriptions: subscriptions }
    }

    fn change(&mut self, key: &str, value: Value, cx: &mut Context<Self>) {
        let result = cx.global::<Settings>().path.as_ref().ok_or("Application data folder unavailable".into())
            .and_then(|path| save(path, key, value));
        match result {
            Ok(value) => { self.error = None; apply(value, cx); }
            Err(error) => self.error = Some(error),
        }
        cx.notify();
    }
}

impl Render for SettingsView {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        window.set_rem_size(ui_size(cx));
        let query = self.search.read(cx).value();
        let left = v_flex().w(layout::SIDEBAR_WIDTH).p(layout::PADDING).gap(layout::GAP)
            .child(Input::new(&self.search)).child(Button::new("appearance").label("Appearance").ghost());
        let mut right = v_flex().flex_1().min_w_0().p(layout::PADDING).gap(layout::GAP)
            .child(h_flex().justify_between().child("User").child(
                Button::new("edit-settings-json").label("Edit in settings.json").on_click(cx.listener(|this, _, _, cx| {
                    let owner = this.owner.clone();
                    let result = this.owner_window.update(cx, |_, window, cx| {
                        owner.update(cx, |owner, cx| owner.edit_settings_json(window, cx))
                    });
                    if let Err(error) = result { this.error = Some(error.to_string()); cx.notify(); }
                })),
            ));
        for (index, (key, name, description)) in ROWS.iter().enumerate() {
            if !matches_query(key, name, description, &query) { continue; }
            let control = match index {
                0 => Select::new(&self.theme).accessibility_label("Theme").into_any_element(),
                1 => Select::new(&self.icons).accessibility_label("Icon Theme").into_any_element(),
                2 => NumberInput::new(&self.ui_font).accessibility_label("UI Font Size").into_any_element(),
                _ => NumberInput::new(&self.buffer_font).accessibility_label("Buffer Font Size").into_any_element(),
            };
            right = right.child(h_flex().gap(layout::GAP).justify_between()
                .child(v_flex().child(*name).child(div().text_color(cx.theme().muted_foreground).child(*description)))
                .child(div().w(layout::CONTROL_WIDTH).child(control)));
        }
        if let Some(error) = &self.error { right = right.child(error.clone()); }
        h_flex().size_full().bg(cx.theme().background).text_color(cx.theme().foreground)
            .child(left).child(right)
    }
}

impl Workbench {
    pub(super) fn on_use_classic_layout(&mut self, _: &super::keymap::workspace::UseClassicLayout, _: &mut Window, cx: &mut Context<Self>) {
        self.dock_open = true;
        self.dock_width = None;
        cx.notify();
    }
    pub(super) fn on_open_settings(&mut self, _: &super::keymap::zed::OpenSettings, window: &mut Window, cx: &mut Context<Self>) {
        if let Some(handle) = cx.global::<Settings>().window
            && handle.update(cx, |_, window, _| window.activate_window()).is_ok() { return; }
        let owner = cx.entity().downgrade();
        let owner_window = window.window_handle();
        match gpui_kit::open_window(WindowOptions { window_bounds: layout::WINDOW_BOUNDS,
            titlebar: Some(TitlebarOptions { title: Some("Settings".into()), ..Default::default() }),
            ..Default::default() }, cx, |window, cx| {
            cx.new(|cx| SettingsView::new(owner, owner_window, window, cx))
        }) {
            Ok((handle, _)) => cx.global_mut::<Settings>().window = handle.downcast(),
            Err(error) => eprintln!("Could not open settings: {error}"),
        }
    }

    fn edit_settings_json(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let Some(path) = cx.global::<Settings>().path.clone() else { return };
        let result = if path.exists() { Ok(()) } else { write(&path, &json!({})) };
        if let Err(error) = result { eprintln!("Could not create settings: {error}"); return; }
        if self.active_ws().is_none() {
            let folder = crate::state::Folder { id: String::new(), path: path.parent().expect("settings parent").to_string_lossy().into_owned(), added_at: String::new() };
            let ws = cx.new(|cx| super::folders::FolderWorkspace::new(&folder, cx));
            cx.observe(&ws, |_, _, cx| cx.notify()).detach();
            self.settings_workspace = Some(ws);
        }
        if let Some(ws) = self.active_ws() {
            ws.update(cx, |ws, cx| { ws.group.open(&path, false, window, cx); });
            self.focus_active_pane(window, cx);
            window.activate_window();
            cx.notify();
        }
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn k11_settings_roundtrip_and_invalid_file_preserved() {
        let dir = std::env::temp_dir().join(format!("workbench-k11-{}", crate::state::win::new_uuid()));
        let path = dir.join("settings.json");
        assert_eq!(super::values(&super::read(&path).unwrap()).unwrap(), super::Values::default());
        std::fs::create_dir_all(&dir).unwrap();
        std::fs::write(&path, "{ // comment\n \"unknown\": true, \"ui_font_size\": 18, }").unwrap();
        let saved = super::save(&path, "buffer_font_size", serde_json::json!(20)).unwrap();
        assert_eq!((saved.ui_font_size, saved.buffer_font_size), (18., 20.));
        assert_eq!(super::values(&super::read(&path).unwrap()).unwrap(), saved);
        assert_eq!(super::read(&path).unwrap()["unknown"], true);
        let before = std::fs::read(&path).unwrap();
        assert!(super::save(&path, "ui_font_size", serde_json::json!(-1)).is_err());
        assert_eq!(std::fs::read(&path).unwrap(), before);
        std::fs::write(&path, "{ invalid").unwrap();
        assert!(super::save(&path, "theme", serde_json::json!(super::THEME)).is_err());
        assert_eq!(std::fs::read_to_string(&path).unwrap(), "{ invalid");
        std::fs::remove_dir_all(dir).unwrap();
    }

    #[test]
    fn k11_settings_search_and_validation() {
        assert!(super::matches_query("ui_font_size", "Font Size", "Font size for UI elements.", "UI elements"));
        assert!(!super::matches_query("theme", "Theme Name", "The name of your selected theme.", "buffer"));
        assert!(super::values(&serde_json::json!({"theme": "missing"})).is_err());
        assert!(super::values(&serde_json::json!({"buffer_font_size": 0})).is_err());
        assert!(super::values(&serde_json::json!({"ui_font_size": 1e100})).is_err());
        assert!(super::is_classic(true, gpui_kit::px(240.), gpui_kit::px(240.)));
        assert!(!super::is_classic(false, gpui_kit::px(240.), gpui_kit::px(240.)));
        assert!(!super::is_classic(true, gpui_kit::px(300.), gpui_kit::px(240.)));
    }
}

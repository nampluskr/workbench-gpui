use std::path::Path;

use gpui_kit::*;
use gpui_kit::component::{ActiveTheme as _, h_flex, v_flex};
use gpui_kit::component::button::{Button, ButtonVariants as _};
use gpui_kit::component::input::{EditorState, Input, InputEvent, InputState};
use gpui_kit::component::list::ListItem;
use jsonc_parser::common::Ranged as _;
use serde_json::json;

use super::{Workbench, keymap, settings};
use super::metrics::keymap_editor as layout;

actions!(keymap_editor, [EditJson, Create]);

// An invalid Windows file path identifies the tool without ever entering Docs or disk I/O.
const TOOL_PATH: &str = "workbench://Keymap Editor";

#[derive(Clone, Debug)]
pub struct Row {
    pub action: String,
    pub keys: String,
    pub context: String,
    pub user: bool,
}

impl Row {
    fn source(&self) -> &'static str { if self.user { "User" } else { "Default" } }
    fn matches(&self, query: &str) -> bool { self.action.to_lowercase().contains(&query.to_lowercase()) }
}

fn append_binding(text: &str, row: &Row, old: Option<&Row>) -> Result<String, String> {
    let bom = if text.starts_with('\u{feff}') { 3 } else { 0 };
    let body = &text[bom..];
    let body = if body.trim().is_empty() { "[]" } else { body };
    let parsed = jsonc_parser::parse_to_ast(body, &Default::default(), &crate::keymap::file::options()).map_err(|e| e.to_string())?;
    let array = parsed.value.as_ref().and_then(|v| v.as_array()).ok_or("Keymap must be an array")?;
    let mut sections = Vec::new();
    if let Some(old) = old.filter(|old| !old.keys.is_empty() && (old.keys != row.keys || old.context != row.context)) {
        sections.push(json!({"context": if old.context.is_empty() { None } else { Some(&old.context) }, "bindings": {old.keys.clone(): null}}));
    }
    sections.push(json!({"context": if row.context.is_empty() { None } else { Some(&row.context) }, "bindings": {row.keys.clone(): row.action.clone()}}));
    let addition = sections.iter().map(|s| serde_json::to_string_pretty(s).expect("JSON value")).collect::<Vec<_>>().join(",\n");
    let mut result = body.to_owned();
    let (offset, prefix) = array.elements.last().map_or((array.range.start + 1, "\n"), |v| (v.range().end, ",\n"));
    // shortcut: append overrides to preserve every existing byte; compact only on explicit user request.
    result.insert_str(offset, &format!("{prefix}{addition}\n"));
    if bom != 0 { result.insert(0, '\u{feff}'); }
    Ok(result)
}

pub struct KeymapEditor {
    filter: Entity<InputState>,
    action: Entity<InputState>,
    keys: Entity<InputState>,
    context: Entity<InputState>,
    selected: Option<Row>,
    editing: bool,
    error: Option<String>,
    owner: WeakEntity<Workbench>,
    _subscriptions: Vec<Subscription>,
}

impl KeymapEditor {
    fn new(owner: WeakEntity<Workbench>, window: &mut Window, cx: &mut Context<Self>) -> Self {
        let filter = cx.new(|cx| InputState::new(window, cx).placeholder("Filter action names…"));
        let action = cx.new(|cx| InputState::new(window, cx).placeholder("Action"));
        let keys = cx.new(|cx| InputState::new(window, cx).placeholder("Keystrokes (e.g. ctrl-alt-k)"));
        let context = cx.new(|cx| InputState::new(window, cx).placeholder("Context (empty = global)"));
        let subscriptions = [&filter, &action, &keys, &context].into_iter().map(|input| cx.subscribe(input, |_, _, _: &InputEvent, cx| cx.notify())).collect();
        Self { filter, action, keys, context, selected: None, editing: false, error: None, owner, _subscriptions: subscriptions }
    }

    fn edit(&mut self, row: Option<Row>, window: &mut Window, cx: &mut Context<Self>) {
        self.action.update(cx, |input, cx| input.set_value(row.as_ref().map_or("", |r| &r.action), window, cx));
        self.keys.update(cx, |input, cx| input.set_value(row.as_ref().map_or("", |r| &r.keys), window, cx));
        self.context.update(cx, |input, cx| input.set_value(row.as_ref().map_or("", |r| &r.context), window, cx));
        self.selected = row;
        self.editing = true;
        self.error = None;
        self.action.focus_handle(cx).focus(window, cx);
        cx.notify();
    }

    fn save(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let row = Row { action: self.action.read(cx).value().trim().into(), keys: self.keys.read(cx).value().trim().into(), context: self.context.read(cx).value().trim().into(), user: true };
        let result = (|| {
            let action = cx.build_action(&row.action, None).map_err(|e| e.to_string())?;
            if row.keys.is_empty() { return Err("Keystrokes are required".into()); }
            let predicate = if row.context.is_empty() { None } else { Some(std::rc::Rc::new(KeyBindingContextPredicate::parse(&row.context).map_err(|e| e.to_string())?)) };
            KeyBinding::load(&row.keys, action, predicate, false, None, cx).map_err(|e| e.to_string())?;
            let path = keymap::keymap_path().ok_or("Application data folder unavailable")?;
            let text = match std::fs::read_to_string(&path) {
                Ok(text) => text,
                Err(e) if e.kind() == std::io::ErrorKind::NotFound => "[]".into(),
                Err(e) => return Err(e.to_string()),
            };
            let updated = append_binding(&text, &row, self.selected.as_ref())?;
            settings::write(&path, &updated)?;
            Ok::<_, String>(())
        })();
        match result {
            Ok(()) => { self.editing = false; self.error = None; keymap::load(window, cx); }
            Err(error) => self.error = Some(error),
        }
        cx.notify();
    }

    fn edit_json(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let result = self.owner.update(cx, |owner, cx| owner.open_keymap_json(window, cx)).map_err(|e| e.to_string()).and_then(|result| result);
        if let Err(error) = result { self.error = Some(error); }
        cx.notify();
    }
}

impl Render for KeymapEditor {
    fn render(&mut self, _: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let query = self.filter.read(cx).value();
        let mut list = v_flex().id("keymap-rows").flex_1().min_h_0().overflow_y_scroll();
        let cells = |values: [String; 5]| h_flex().w_full().children(values.into_iter().zip(layout::COLUMN_RATIOS).map(|(value, ratio)| div().flex_basis(px(0.)).flex_grow(ratio).min_w_0().child(value)));
        list = list.child(cells(["Action", "Arguments", "Keystrokes", "Context", "Source"].map(str::to_owned)));
        for (index, row) in keymap::editor_rows(cx).into_iter().filter(|row| row.matches(&query)).enumerate() {
            let content = cells([row.action.clone(), String::new(), row.keys.clone(), row.context.clone(), row.source().into()]);
            list = list.child(ListItem::new(("keybinding", index)).accessibility_label(row.action.clone())
                .on_click(cx.listener(move |this, _, window, cx| this.edit(Some(row.clone()), window, cx))).child(content));
        }
        let mut root = v_flex().size_full().p(layout::PADDING).gap(layout::GAP).key_context("KeymapEditor")
            .on_action(cx.listener(|this, _: &EditJson, window, cx| this.edit_json(window, cx)))
            .on_action(cx.listener(|this, _: &Create, window, cx| this.edit(None, window, cx)))
            .child(h_flex().gap(layout::TOP_GAP).child(div().flex_1().h(layout::SEARCH_HEIGHT).child(Input::new(&self.filter)))
                .child(Button::new("edit-keymap-json").label("Edit in JSON  Ctrl-E").ghost().on_click(cx.listener(|this, _, window, cx| this.edit_json(window, cx))))
                .child(Button::new("create-keybinding").label("Create Keybinding  Ctrl-K").on_click(cx.listener(|this, _, window, cx| this.edit(None, window, cx)))))
            .child(list);
        if self.editing {
            root = root.child(v_flex().child(Input::new(&self.action)).child(Input::new(&self.keys)).child(Input::new(&self.context))
                .child(h_flex().child(Button::new("save-keybinding").label("Save").on_click(cx.listener(|this, _, window, cx| this.save(window, cx))))
                    .child(Button::new("cancel-keybinding").label("Cancel").ghost().on_click(cx.listener(|this, _, _, cx| { this.editing = false; cx.notify(); })))));
        }
        if let Some(error) = &self.error { root = root.child(error.clone()); }
        root.bg(cx.theme().background).text_color(cx.theme().foreground)
    }
}

impl Workbench {
    pub(super) fn on_open_keymap(&mut self, _: &keymap::zed::OpenKeymap, window: &mut Window, cx: &mut Context<Self>) {
        self.open_tool(TOOL_PATH, window, cx, |window, cx| {
            let owner = cx.entity().downgrade();
            let view = cx.new(|cx| KeymapEditor::new(owner, window, cx));
            let focus = view.read(cx).filter.focus_handle(cx);
            (view.into(), focus)
        });
    }

    pub(super) fn open_tool(&mut self, path: &str, window: &mut Window, cx: &mut Context<Self>, make: impl FnOnce(&mut Window, &mut Context<Self>) -> (AnyView, FocusHandle)) {
        // Search all workspaces before creating a new tool tab.
        let mut workspaces: Vec<_> = self.folders.workspaces.values().cloned().collect();
        if let Some(ws) = &self.settings_workspace { workspaces.push(ws.clone()); }
        for ws in workspaces {
            let found = ws.read(cx).group.find_source(Path::new(path), ws.read(cx).group.active);
            if let Some((pane, index)) = found {
                let folder = self.folders.workspaces.iter().find_map(|(id, w)| (w == &ws).then_some(id.clone()));
                if let Some(index) = self.folders.state.folders.iter().position(|f| Some(&f.id) == folder.as_ref()) {
                    self.activate_folder(index, window, cx);
                } else {
                    self.folders.state.active = None;
                    self.sync_watch("tool-tab", cx);
                }
                ws.update(cx, |ws, _| { ws.group.activate(pane); ws.group.panes.get_mut(&pane).unwrap().active = Some(index); });
                self.focus_active_pane(window, cx);
                cx.notify();
                return;
            }
        }
        let Some(ws) = self.config_workspace(cx) else { return };
        let (view, focus) = make(window, cx);
        let editor = cx.new(|cx| EditorState::new(window, cx));
        ws.update(cx, |ws, _| {
            let pane = ws.group.active;
            ws.group.panes.get_mut(&pane).unwrap().place(super::pane::Tab { path: path.into(), preview: false, markdown: false, editor, tool: Some((view, focus.clone())) }, false);
        });
        focus.focus(window, cx);
        cx.notify();
    }

    fn open_keymap_json(&mut self, window: &mut Window, cx: &mut Context<Self>) -> Result<(), String> {
        let path = keymap::keymap_path().ok_or("Application data folder unavailable")?;
        if !path.exists() { settings::write(&path, "[]\n")?; }
        if let Some(ws) = self.config_workspace(cx) {
            ws.update(cx, |ws, cx| { ws.group.open(&path, false, window, cx); });
            self.focus_active_pane(window, cx);
            cx.notify();
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::{Row, append_binding};

    #[test]
    fn filter_and_sources() {
        let mut row = Row { action: "workspace::Save".into(), keys: "ctrl-s".into(), context: "Workspace".into(), user: false };
        assert!(row.matches("SAVE"));
        assert!(!row.matches("ctrl-s"));
        assert_eq!(row.source(), "Default");
        row.user = true;
        assert_eq!(row.source(), "User");
    }

    #[test]
    fn save_and_reload_preserve_comments_and_disable_old_key() {
        let old = Row { action: "workspace::Save".into(), keys: "ctrl-s".into(), context: "Workspace".into(), user: false };
        let new = Row { keys: "ctrl-alt-s".into(), user: true, ..old.clone() };
        for original in ["[]", "// comment\n[ /* keep */ ]", "\u{feff}[{\"bindings\":{\"ctrl-q\":\"zed::Quit\"}}, // keep\n]"] {
            let text = append_binding(original, &new, Some(&old)).unwrap();
            assert!(text.contains("keep") || !original.contains("keep"));
            let parsed = crate::keymap::file::parse(&text, &crate::keymap::is_known_action);
            assert!(parsed.errors().is_empty(), "{:?}", parsed.errors());
            let bindings = parsed.bindings();
            assert_eq!(bindings[bindings.len()-2].action, None);
            assert_eq!(bindings.last().unwrap().keys, "ctrl-alt-s");
            assert_eq!(bindings.last().unwrap().action.as_deref(), Some("workspace::Save"));
        }
        assert!(append_binding("{ broken", &new, None).is_err());
        assert!(append_binding("{}", &new, None).is_err());
        assert!(append_binding("[{'bindings': {}}]", &new, None).is_err());
        let dir = std::env::temp_dir().join(format!("workbench-k14-{}", crate::state::win::new_uuid()));
        let path = dir.join("keymap.json");
        let original = "// keep header\n[{\"bindings\":{\"ctrl-q\":\"zed::Quit\"}}, // keep tail\n]\n";
        let updated = append_binding(original, &new, Some(&old)).unwrap();
        assert!(updated.starts_with("// keep header\n[{\"bindings\":{\"ctrl-q\":\"zed::Quit\"}}"));
        assert!(updated.ends_with(", // keep tail\n]\n"));
        super::settings::write(&path, &updated).unwrap();
        assert_eq!(std::fs::read_to_string(&path).unwrap(), updated);
        let parsed = crate::keymap::file::read(&path, &crate::keymap::is_known_action);
        assert!(parsed.errors().is_empty());
        assert_eq!(parsed.bindings().last().unwrap().keys, new.keys);
        std::fs::remove_dir_all(dir).unwrap();
    }
}

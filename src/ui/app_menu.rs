//! ☰ 앱 메뉴 (v0.2 Phase 2, SPEC R-5·R-8·R-9, DECISIONS D-5 이후 변경·D-13 이후 변경, D-031).
//!
//! gpui 요소로 직접 그린다(gpui-kit PopupMenu 는 항목 높이·여백·구분선이 상수라 I-505~I-512 를 맞출 수 없다).
//!
//! 구조(02 9.2절, I-300~I-311):
//! - 메뉴 정의는 `definition()` 한 곳에 9.2절 순서·구분선 그대로 둔다. v0.2 에서 동작하는 항목만 남기고(D-13),
//!   빈 그룹·연속·끝 구분선을 정리한다(I-306). 하위 메뉴는 없다(I-304).
//! - 닫힌 상태에는 `Menu` 아이콘 버튼 하나(L-85, I-302). 누르거나 F10(I-310)이면 첫 메뉴가 열리고, 열려 있는 동안
//!   가로 메뉴 바(메뉴 이름 Small 12px, 버튼 사이 4, I-321)가 나타난다. 다른 이름에 마우스를 올리면 그 메뉴로 바뀐다(I-303).
//! - 단축키는 메뉴를 열기 직전 포커스의 컨텍스트에서 찾는다(I-307, I-510). 거기서 가려졌으면 표시하지 않는다(L-223, D-033 ②).
//!   열기 직전 포커스가 없을 때만 지금 포커스로 찾는다. 형식 L-219~L-221.
//!
//! 모양(I-504~I-512, I-313~I-321): 최소 폭 200px, 최대 높이 창 높이 75%(넘치면 세로 스크롤), 목록 위아래 4,
//! 항목 바깥 좌우 4·안 좌우 6, 줄 높이 1.618, 라벨 14px, 단축키 앞 16, 구분선 1px·위아래 6, `elevation_2`.
//! 팝업은 메뉴 이름 버튼의 왼쪽 아래에 x −5(rem 16 기준), 창 가장자리 여유 8(I-314).
//!
//! 키(`menu` 컨텍스트, I-516·I-517, D-027 ③): 우리 `menu::` 액션을 받는다. 다음/이전/처음/끝, Enter 실행,
//! Escape·Ctrl-C 닫기, Right/Left 는 다음·이전 메뉴(끝에서 순환, I-303·I-310). 처음 아래 키는 첫 항목(I-518).
//! 닫힘(I-519): 메뉴 밖 누름, Escape, 실행 뒤, 포커스 잃음. 실행 전에 원래 포커스를 복원한다(I-309).
//! 메뉴가 열린 채 항목의 단축키를 누르면 그 항목을 선택 표시하고 50ms 뒤 닫고 실행한다(I-520).

use crate::dev::now_ms;
use gpui_kit::component::{ActiveTheme as _, h_flex, v_flex};
use gpui_kit::prelude::FluentBuilder as _;
use gpui_kit::*;

use super::keymap::{self, menu as menu_actions};
use super::layout_probe::{self, probe};
use super::metrics::menu::*;
use super::menu_common::{self, Chord, Feed};
use super::metrics::{BUTTON_DEFAULT, ICON_SMALL};
use super::tooltip::{self, Line, Spec};

/// 앱 이름 (DECISIONS D-13 이후 변경, D-031 ⑤).
pub const APP_NAME: &str = "workbench-gpui";

// Menu size/time constants live in `metrics::menu` (I-312~I-321, I-520).

/// v0.2 에서 동작하는 액션(D-13, D-031 ④). Phase 3 에서 `workspace::Open`,
/// `multi_workspace::ToggleWorkspaceSidebar`, `multi_workspace::FocusWorkspaceSidebar` 를 더했다.
const AVAILABLE: &[&str] = &[
    "app_menu::EditorLayout",
    "pane::ActivatePreviousItem",
    "pane::ActivateNextItem",
    "workspace::Save",
    "input::Undo",
    "input::Redo",
    "markdown::OpenPreview",
    "markdown::OpenPreviewToTheSide",
    "zed::OpenLicenses",
    "help::FileBugReport",
    "help::RequestFeature",
    "help::Repository",
    "zed::Quit",
    "pane::CloseActiveItem",
    "workspace::CloseWindow",
    "workspace::ToggleLeftDock",
    "project_panel::ToggleFocus",
    "zed::Minimize",
    "zed::Zoom",
    // Phase 3 (D-031 ④, D-035): 폴더 등록과 사이드바 표시·포커스.
    "workspace::Open",
    "multi_workspace::ToggleWorkspaceSidebar",
    "multi_workspace::FocusWorkspaceSidebar",
    // P4-23b-R1: View > Split Up/Down/Left/Right and Maximize Pane (I-711, I-730); same handlers as the keys.
    "pane::SplitUp",
    "pane::SplitDown",
    "pane::SplitLeft",
    "pane::SplitRight",
    "workspace::ToggleZoom",
];

#[derive(Clone)]
enum Entry {
    Item { label: String, action: &'static str },
    Separator,
}

fn item(label: &str, action: &'static str) -> Entry {
    Entry::Item {
        label: label.replace("<앱 이름>", APP_NAME),
        action,
    }
}

/// 02 9.2절 메뉴 구조 전체(순서·구분선 그대로). 액션 이름은 9.2절 표의 액션 열이다.
fn definition() -> Vec<(String, Vec<Entry>)> {
    use Entry::Separator as S;
    vec![
        (
            APP_NAME.to_string(),
            vec![
                item("About <앱 이름>", "zed::About"),
                S,
                item("Open Settings File", "zed::OpenSettingsFile"),
                S,
                item("Open Keymap", "zed::OpenKeymap"),
                item("Open Keymap File", "zed::OpenKeymapFile"),
                S,
                item("Select Theme...", "theme_selector::Toggle"),
                item("Select Icon Theme...", "icon_theme_selector::Toggle"),
                S,
                item("Extensions", "zed::Extensions"),
                S,
                item("Quit <앱 이름>", "zed::Quit"),
            ],
        ),
        (
            "File".into(),
            vec![
                item("New", "workspace::NewFile"),
                item("New Window", "workspace::NewWindow"),
                S,
                item("Open File...", "workspace::OpenFiles"),
                item("Open Folder...", "workspace::Open"),
                item("Open Recent…", "projects::OpenRecent"),
                S,
                item("Add Folder to Project…", "workspace::AddFolderToProject"),
                S,
                item("Save", "workspace::Save"),
                item("Save As…", "workspace::SaveAs"),
                item("Save All", "workspace::SaveAll"),
                S,
                item("Close Editor", "pane::CloseActiveItem"),
                item("Close Window", "workspace::CloseWindow"),
            ],
        ),
        (
            "Edit".into(),
            vec![
                item("Undo", "input::Undo"),
                item("Redo", "input::Redo"),
                S,
                item("Cut", "editor::Cut"),
                item("Copy", "editor::Copy"),
                item("Copy and Trim", "editor::CopyAndTrim"),
                item("Paste", "editor::Paste"),
                S,
                item("Find", "buffer_search::Deploy"),
                item("Replace", "buffer_search::DeployReplace"),
                S,
                item("Toggle Line Comment", "editor::ToggleComments"),
            ],
        ),
        (
            "Selection".into(),
            vec![
                item("Select All", "editor::SelectAll"),
                item("Expand Selection", "editor::SelectLargerSyntaxNode"),
                item("Shrink Selection", "editor::SelectSmallerSyntaxNode"),
                item("Select Next Sibling", "editor::SelectNextSyntaxNode"),
                item("Select Previous Sibling", "editor::SelectPreviousSyntaxNode"),
                S,
                item("Add Cursor Above", "editor::AddSelectionAbove"),
                item("Add Cursor Below", "editor::AddSelectionBelow"),
                item("Select Next Occurrence", "editor::SelectNext"),
                item("Select Previous Occurrence", "editor::SelectPrevious"),
                item("Select All Occurrences", "editor::SelectAllMatches"),
                S,
                item("Move Line Up", "editor::MoveLineUp"),
                item("Move Line Down", "editor::MoveLineDown"),
                item("Duplicate Selection", "editor::DuplicateLineDown"),
            ],
        ),
        (
            "View".into(),
            vec![
                item("Zoom In", "zed::IncreaseBufferFontSize"),
                item("Zoom Out", "zed::DecreaseBufferFontSize"),
                item("Reset Zoom", "zed::ResetBufferFontSize"),
                item("Reset All Zoom", "zed::ResetAllZoom"),
                S,
                item("Toggle Left Dock", "workspace::ToggleLeftDock"),
                item("Toggle All Docks", "workspace::ToggleAllDocks"),
                item("Toggle Folder Sidebar", "multi_workspace::ToggleWorkspaceSidebar"),
                item("Focus Folder Sidebar", "multi_workspace::FocusWorkspaceSidebar"),
                item("Editor Layout", "app_menu::EditorLayout"),
                item("Maximize Pane", "workspace::ToggleZoom"),
                S,
                item("Project Panel", "project_panel::ToggleFocus"),
                item("Open Markdown Preview", "markdown::OpenPreview"),
                item(
                    "Open Markdown Preview to the Side",
                    "markdown::OpenPreviewToTheSide",
                ),
            ],
        ),
        (
            "Go".into(),
            vec![
                item("Back", "pane::GoBack"),
                item("Forward", "pane::GoForward"),
                item("Previous Tab", "pane::ActivatePreviousItem"),
                item("Next Tab", "pane::ActivateNextItem"),
                S,
                item("Command Palette...", "command_palette::Toggle"),
                S,
                item("Go to File...", "file_finder::Toggle"),
                item("Go to Line/Column...", "go_to_line::Toggle"),
            ],
        ),
        (
            "Window".into(),
            vec![item("Minimize", "zed::Minimize"), item("Zoom", "zed::Zoom")],
        ),
        (
            "Help".into(),
            vec![
                item("View Dependency Licenses", "zed::OpenLicenses"),
                S,
                item("File Bug Report...", "help::FileBugReport"),
                item("Request Feature...", "help::RequestFeature"),
                S,
                item("workbench-gpui Repository", "help::Repository"),
            ],
        ),
    ]
}

/// 동작하는 항목만 남기고 구분선을 정리한 메뉴(I-306, D-13). 항목이 없는 메뉴는 뺀다.
fn visible_menus() -> Vec<(String, Vec<Entry>)> {
    definition()
        .into_iter()
        .filter_map(|(name, entries)| {
            let mut out: Vec<Entry> = Vec::new();
            for e in entries {
                match e {
                    Entry::Item { ref action, .. } if AVAILABLE.contains(action) => out.push(e),
                    Entry::Item { .. } => {}
                    Entry::Separator => {
                        if matches!(out.last(), Some(Entry::Item { .. })) {
                            out.push(e);
                        }
                    }
                }
            }
            while matches!(out.last(), Some(Entry::Separator)) {
                out.pop();
            }
            (!out.is_empty()).then_some((name, out))
        })
        .collect()
}

const ROW_PROBES: [&str; 16] = [
    "menu-row-00", "menu-row-01", "menu-row-02", "menu-row-03", "menu-row-04", "menu-row-05",
    "menu-row-06", "menu-row-07", "menu-row-08", "menu-row-09", "menu-row-10", "menu-row-11",
    "menu-row-12", "menu-row-13", "menu-row-14", "menu-row-15",
];
const NAME_PROBES: [&str; 8] = [
    "menu-name-0", "menu-name-1", "menu-name-2", "menu-name-3", "menu-name-4", "menu-name-5",
    "menu-name-6", "menu-name-7",
];

fn help_url(action: &str) -> Option<&'static str> {
    match action {
        "help::FileBugReport" | "help::RequestFeature" => Some("https://github.com/nampluskr/workbench-gpui/issues/new"),
        "help::Repository" => Some("https://github.com/nampluskr/workbench-gpui"),
        _ => None,
    }
}

const LICENSES: &[(&str, &str)] = &[
    ("ignore 0.4.34 — MIT OR Unlicense", concat!(include_str!("../../resources/licenses/ignore/LICENSE-MIT"), "\n", include_str!("../../resources/licenses/ignore/UNLICENSE"))),
    ("regex 1.13.1 — MIT OR Apache-2.0", concat!(include_str!("../../resources/licenses/regex/LICENSE-MIT"), "\n", include_str!("../../resources/licenses/regex/LICENSE-APACHE"))),
    ("IBM Plex Sans", include_str!("../../resources/fonts/ibm-plex-sans/license.txt")),
    ("Lilex", include_str!("../../resources/fonts/lilex/OFL.txt")),
    ("Zed icons — Lucide", include_str!("../../resources/zed-icons/LICENSES")),
    ("Zed Apache license", include_str!("../../resources/zed-icons/LICENSE-APACHE")),
    ("Zed GPL license", include_str!("../../resources/zed-icons/LICENSE-GPL")),
    ("gpui-base Apache license", include_str!("../../vendor/gpui-base/LICENSE-APACHE")),
];

struct Licenses;

impl Render for Licenses {
    fn render(&mut self, _: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let mut list = v_flex().id("dependency-licenses").size_full().overflow_y_scroll()
            .bg(cx.theme().background).text_color(cx.theme().foreground);
        for (name, text) in LICENSES {
            list = list.child(div().child(*name)).child(div().child(*text));
        }
        list
    }
}

const USER_ITEMS: &[(&str, &str)] = &[
    ("Settings", "Ctrl-,"),
    ("Keymap", "Ctrl-K Ctrl-S"),
    ("Themes…", "Ctrl-K Ctrl-T"),
    ("Icon Themes…", ""),
    ("Extensions", "Ctrl-Shift-X"),
];
/// Rows of the v menu: the items plus Panel Layout.
const ROWS: usize = USER_ITEMS.len() + 1;

fn user_action(index: usize) -> Box<dyn Action> {
    use super::keymap::{icon_theme_selector, theme_selector, zed};
    match index {
        0 => Box::new(zed::OpenSettings),
        1 => Box::new(zed::OpenKeymap),
        2 => Box::new(theme_selector::Toggle),
        3 => Box::new(icon_theme_selector::Toggle),
        _ => Box::new(zed::Extensions),
    }
}

const PANEL_LAYOUTS: &[&str] = &["Classic"];
const EDITOR_LAYOUT: &[(&str, &str)] = &[
    ("Split Up", "pane::SplitUp"), ("Split Down", "pane::SplitDown"),
    ("Split Left", "pane::SplitLeft"), ("Split Right", "pane::SplitRight"),
];

pub struct UserMenu {
    selected: usize,
    submenu_bounds: Option<Bounds<Pixels>>,
    classic: bool,
    open: bool,
    panel: bool,
    focus: FocusHandle,
    previous: Option<FocusHandle>,
    button_bounds: Option<Bounds<Pixels>>,
    _blur: Subscription,
}

impl UserMenu {
    pub fn new(window: &mut Window, cx: &mut Context<Self>) -> Self {
        let focus = cx.focus_handle();
        let blur = cx.on_blur(&focus, window, |this, _, cx| {
            this.open = false;
            this.panel = false;
            this.previous = None;
            cx.notify();
        });
        Self { selected: 0, submenu_bounds: None, classic: true, open: false, panel: false, focus, previous: None, button_bounds: None, _blur: blur }
    }

    pub fn set_classic(&mut self, classic: bool, cx: &mut Context<Self>) {
        if self.classic != classic { self.classic = classic; cx.notify(); }
    }

    fn close(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        self.submenu_bounds = None;
        self.open = false;
        self.panel = false;
        if let Some(focus) = self.previous.take() {
            focus.focus(window, cx);
        }
        cx.notify();
    }
}

impl Render for UserMenu {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let muted = cx.theme().muted_foreground;
        let hover = cx.theme().secondary_hover;
        let weak = cx.entity().downgrade();
        let mut root = div()
            .on_children_prepainted(move |bounds, _, cx| {
                let _ = weak.update(cx, |this, _| this.button_bounds = bounds.first().copied());
            }).id("user-menu").relative().child(
            div().id("user-menu-button").flex().items_center().justify_center()
                .size(super::metrics::USER_BUTTON_SIZE)
                .rounded(ROW_RADIUS).text_color(muted).hover(move |s| s.bg(hover))
                .on_click(cx.listener(|this, _, window, cx| {
                    if this.open { this.close(window, cx); } else {
                        this.previous = window.focused(cx);
                        this.selected = 0;
                        this.open = true;
                        this.focus.focus(window, cx);
                        cx.notify();
                    }
                }))
                .child(super::zed_icons::icon("chevron_down").size(super::metrics::USER_CHEVRON_SIZE)),
        );
        if self.open {
            let mut list = menu_common::list(v_flex(), "user-menu-list", window.viewport_size().height * MAX_HEIGHT_RATIO);
            for (i, (label, shortcut)) in USER_ITEMS.iter().enumerate() {
                list = list.child(menu_common::row(("user-menu-item", i)).text_color(cx.theme().foreground)
                    .when(self.selected == i, |row| row.bg(hover))
                    .on_click(cx.listener(move |this, _, window, cx| {
                        this.close(window, cx);
                        window.dispatch_action(user_action(i), cx);
                    }))
                    .child(*label).child(menu_common::shortcut_cell().child(*shortcut)));
            }
            list = list.child(menu_common::separator(cx.theme().border)).child(
                menu_common::row("panel-layout").relative().when(self.selected == USER_ITEMS.len(), |row| row.bg(hover))
                    .on_hover(cx.listener(|this, hovered: &bool, _, cx| {
                        if *hovered { this.selected = USER_ITEMS.len(); this.panel = true; cx.notify(); }
                    }))
                    .on_click(cx.listener(|this, _, _, cx| { this.panel = !this.panel; cx.notify(); }))
                    .child("Panel Layout")
                    .child(super::zed_icons::icon("chevron_right").size(ICON_SMALL))
                    .when(self.panel, |row| {
                        let mut children = v_flex();
                        for (i, label) in PANEL_LAYOUTS.iter().enumerate() {
                            children = children.child(menu_common::row(("panel-layout-item", i))
                                .on_click(cx.listener(|this, _, window, cx| {
                                    this.close(window, cx);
                                    window.dispatch_action(Box::new(super::keymap::workspace::UseClassicLayout), cx);
                                }))
                                .child(if self.classic { "✓" } else { "" }).child(*label));
                        }
                        if !self.classic {
                            children = children.child(menu_common::row("custom-layout").text_color(muted).child("✓").child("Custom"));
                        }
                        let weak = cx.entity().downgrade();
                        row.child(div().absolute().left_full().top_0().child(deferred(anchored()
                            .snap_to_window_with_margin(WINDOW_MARGIN)
                            .child(div().on_children_prepainted(move |bounds, _, cx| {
                                let _ = weak.update(cx, |this, _| this.submenu_bounds = bounds.first().copied());
                            }).child(menu_common::popup_surface(div(), cx).child(children)))).with_priority(2)))
                    }),
            );
            let surface = div().key_context(crate::keymap::builtin::MENU_CONTEXT).track_focus(&self.focus)
                .on_action(cx.listener(|this, _: &menu_actions::Cancel, w, cx| this.close(w, cx)))
                .on_action(cx.listener(|this, _: &menu_actions::Confirm, window, cx| {
                    if this.panel {
                        this.close(window, cx);
                        window.dispatch_action(Box::new(super::keymap::workspace::UseClassicLayout), cx);
                    } else if this.selected < USER_ITEMS.len() {
                        let selected = this.selected;
                        this.close(window, cx);
                        window.dispatch_action(user_action(selected), cx);
                    } else { this.panel = true; cx.notify(); }
                }))
                .on_action(cx.listener(|this, _: &menu_actions::SelectNext, _, cx| { this.selected = (this.selected + 1) % ROWS; this.panel = false; cx.notify(); }))
                .on_action(cx.listener(|this, _: &menu_actions::SelectPrevious, _, cx| { this.selected = (this.selected + ROWS - 1) % ROWS; this.panel = false; cx.notify(); }))
                .on_action(cx.listener(|this, _: &menu_actions::SelectChild, _, cx| { if this.selected == USER_ITEMS.len() { this.panel = true; cx.notify(); } }))
                .on_action(cx.listener(|this, _: &menu_actions::SelectParent, _, cx| { this.panel = false; cx.notify(); }))
                .on_mouse_down_out(cx.listener(|this, event: &MouseDownEvent, w, cx| {
                    if !this.button_bounds.is_some_and(|bounds| bounds.contains(&event.position))
                        && !(this.panel && this.submenu_bounds.is_some_and(|bounds| bounds.contains(&event.position))) {
                        this.close(w, cx);
                    }
                }));
            root = root.child(div().absolute().top_full().right_0().child(
                deferred(anchored().snap_to_window_with_margin(WINDOW_MARGIN)
                    .child(menu_common::popup_surface(surface, cx).child(list))).with_priority(1),
            ));
        }
        root
    }
}

pub struct AppMenu {
    submenu_bounds: Option<Bounds<Pixels>>,
    layout_selected: Option<usize>,
    menus: Vec<(String, Vec<Entry>)>,
    focus: FocusHandle,
    /// 열린 메뉴 번호. None 이면 닫힘.
    open: Option<usize>,
    /// 선택한 항목(entries 안의 번호, 구분선이 아닌 것).
    selected: Option<usize>,
    /// 메뉴를 열기 직전의 포커스(I-307·I-309).
    prev_focus: Option<FocusHandle>,
    /// 가로 메뉴 바의 경계. 메뉴 밖 누름 판정에서 바 위 누름은 뺀다(이름을 눌러 바꾸는 경우).
    bar_bounds: Option<Bounds<Pixels>>,
    /// I-520 단축키 실행 예약. 예약한 액션 자체와 예약 세대를 들고 있다(리뷰 1회차 ①, D-032).
    /// 메뉴를 바꾸거나 닫으면 지운다. 50ms 뒤 세대가 같을 때만 그 액션을 실행한다.
    pending: Option<(Box<dyn Action>, u64)>,
    /// 예약 세대. 메뉴를 열거나 바꾸거나 닫을 때마다 올린다.
    generation: u64,
    /// 메뉴가 열린 채 받은 chord 의 앞 키들과 대기 시간 초과 표지(항목 단축키 해석용, 리뷰 1회차 ③).
    chord: Chord,
    /// 메뉴를 열기 직전 포커스의 컨텍스트 스택(항목 단축키 해석용, 리뷰 2회차 ⓑ).
    prev_stack: Vec<KeyContext>,
    _intercept: Option<Subscription>,
    /// dev 출력: 마지막으로 낸 상태 문자열.
    last_logged: String,
    _blur: Option<Subscription>,
}

impl AppMenu {
    pub fn is_open(&self) -> bool {
        self.open.is_some()
    }
    pub fn new(window: &mut Window, cx: &mut Context<Self>) -> Self {
        let focus = cx.focus_handle();
        let blur = cx.on_blur(&focus, window, |this, window, cx| {
            if this.open.is_some() && this.pending.is_none() {
                this.close("blur", false, window, cx);
            }
        });
        // 항목 단축키는 디스패치 전에 메뉴를 열기 직전 컨텍스트로 해석한다(리뷰 1회차 ③). 소비하면 전파를 멈춘다.
        let weak = cx.entity().downgrade();
        let intercept = cx.intercept_keystrokes(move |event, window, cx| {
            let consumed = weak
                .update(cx, |this, cx| this.intercept(event, window, cx))
                .unwrap_or(false);
            if consumed {
                cx.stop_propagation();
            }
        });
        Self {
            submenu_bounds: None,
            layout_selected: None,
            menus: visible_menus(),
            focus,
            open: None,
            selected: None,
            prev_focus: None,
            bar_bounds: None,
            pending: None,
            generation: 0,
            chord: Chord::default(),
            prev_stack: Vec::new(),
            last_logged: String::new(),
            _blur: Some(blur),
            _intercept: Some(intercept),
        }
    }

    fn dev(&self, cx: &App) -> bool {
        keymap::dev_enabled(cx)
    }

    /// F10(I-310)·☰ 누름: 닫혀 있으면 첫 메뉴를 열고, 열려 있으면 닫는다.
    pub fn toggle(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        if self.open.is_some() {
            self.close("toggle", true, window, cx);
        } else {
            self.open_menu(0, window, cx);
        }
    }

    fn open_menu(&mut self, index: usize, window: &mut Window, cx: &mut Context<Self>) {
        self.layout_selected = None;
        self.submenu_bounds = None;
        if self.menus.is_empty() {
            return;
        }
        if self.open.is_none() {
            // 메뉴 자신이 아닌 포커스만 기록한다.
            self.prev_focus = window.focused(cx).filter(|f| *f != self.focus);
            // 메뉴로 포커스를 옮기기 전, 지금 포커스 자리의 컨텍스트 스택(gpui `Window::context_stack`)을 기록한다.
            self.prev_stack = window.context_stack();
        }
        self.open = Some(index % self.menus.len());
        self.selected = None;
        // 메뉴가 바뀌면 이전 메뉴에서 걸어 둔 단축키 실행 예약은 취소한다(리뷰 1회차 ①).
        self.cancel_pending();
        self.focus.focus(window, cx);
        if self.dev(cx) {
            println!(
                "[dev] menu-open index={} name={} t_ms={}",
                index,
                self.menus[index % self.menus.len()].0,
                now_ms()
            );
        }
        cx.notify();
    }

    /// 닫는다. `restore` 면 원래 포커스로 돌린다(I-309).
    fn close(&mut self, reason: &str, restore: bool, window: &mut Window, cx: &mut Context<Self>) {
        self.submenu_bounds = None;
        self.layout_selected = None;
        if self.open.is_none() {
            return;
        }
        self.open = None;
        self.selected = None;
        self.cancel_pending();
        self.last_logged.clear();
        layout_probe::forget("menu-");
        if restore && let Some(prev) = self.prev_focus.take() {
            prev.focus(window, cx);
        }
        self.prev_focus = None;
        if self.dev(cx) {
            println!("[dev] menu-close reason={reason} t_ms={}", now_ms());
        }
        cx.notify();
    }

    fn entries(&self) -> &[Entry] {
        match self.open {
            Some(i) => &self.menus[i].1,
            None => &[],
        }
    }

    fn item_indices(&self) -> Vec<usize> {
        self.entries()
            .iter()
            .enumerate()
            .filter(|(_, e)| matches!(e, Entry::Item { .. }))
            .map(|(i, _)| i)
            .collect()
    }

    fn select(&mut self, index: Option<usize>, cx: &mut Context<Self>) {
        self.submenu_bounds = None;
        self.layout_selected = None;
        self.selected = index;
        if self.dev(cx) {
            println!(
                "[dev] menu-selected index={}",
                index.map(|i| i.to_string()).unwrap_or_else(|| "none".into())
            );
        }
        cx.notify();
    }

    fn step(&mut self, forward: bool, cx: &mut Context<Self>) {
        if let Some(index) = self.layout_selected {
            self.layout_selected = Some((index + if forward { 1 } else { EDITOR_LAYOUT.len() - 1 }) % EDITOR_LAYOUT.len());
            cx.notify();
            return;
        }
        let items = self.item_indices();
        if items.is_empty() {
            return;
        }
        // I-518: 처음 아래 키는 첫 항목, 끝에서 처음으로 순환(이전은 반대).
        let next = match self.selected.and_then(|s| items.iter().position(|i| *i == s)) {
            None => {
                if forward {
                    items[0]
                } else {
                    items[items.len() - 1]
                }
            }
            Some(pos) => {
                let n = items.len();
                items[if forward { (pos + 1) % n } else { (pos + n - 1) % n }]
            }
        };
        self.select(Some(next), cx);
    }

    fn on_select_next(&mut self, _: &menu_actions::SelectNext, _: &mut Window, cx: &mut Context<Self>) {
        self.step(true, cx);
    }

    fn on_select_previous(
        &mut self,
        _: &menu_actions::SelectPrevious,
        _: &mut Window,
        cx: &mut Context<Self>,
    ) {
        self.step(false, cx);
    }

    fn on_select_first(&mut self, _: &menu_actions::SelectFirst, _: &mut Window, cx: &mut Context<Self>) {
        let first = self.item_indices().first().copied();
        self.select(first, cx);
    }

    fn on_select_last(&mut self, _: &menu_actions::SelectLast, _: &mut Window, cx: &mut Context<Self>) {
        let last = self.item_indices().last().copied();
        self.select(last, cx);
    }

    fn on_cancel(&mut self, _: &menu_actions::Cancel, window: &mut Window, cx: &mut Context<Self>) {
        if self.layout_selected.take().is_some() { cx.notify(); return; }
        self.close("cancel", true, window, cx);
    }

    fn on_confirm(&mut self, _: &menu_actions::Confirm, window: &mut Window, cx: &mut Context<Self>) {
        if let Some(index) = self.layout_selected {
            let action = EDITOR_LAYOUT[index].1;
            self.close("execute", true, window, cx);
            if let Ok(action) = cx.build_action(action, None) { window.dispatch_action(action, cx); }
            return;
        }
        if let Some(i) = self.selected {
            self.execute(i, "enter", window, cx);
        }
    }

    /// Right: 다음 메뉴, Left: 이전 메뉴. 끝에서 반대편으로 순환한다(I-303, I-310).
    fn on_next_menu(&mut self, _: &menu_actions::SelectChild, window: &mut Window, cx: &mut Context<Self>) {
        if self.selected.is_some_and(|i| matches!(self.entries().get(i), Some(Entry::Item { action: "app_menu::EditorLayout", .. }))) {
            self.layout_selected = Some(0);
            cx.notify();
            return;
        }
        if let Some(i) = self.open {
            self.open_menu((i + 1) % self.menus.len(), window, cx);
        }
    }

    fn on_previous_menu(
        &mut self,
        _: &menu_actions::SelectParent,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        if self.layout_selected.take().is_some() { cx.notify(); return; }
        if let Some(i) = self.open {
            let n = self.menus.len();
            self.open_menu((i + n - 1) % n, window, cx);
        }
    }

    /// 항목 실행: 닫고 원래 포커스를 복원한 뒤 액션을 보낸다(I-309, I-519).
    fn execute(&mut self, index: usize, via: &str, window: &mut Window, cx: &mut Context<Self>) {
        let Some(Entry::Item { action, .. }) = self.entries().get(index).cloned() else {
            return;
        };
        if action == "app_menu::EditorLayout" {
            self.selected = Some(index);
            self.layout_selected = Some(0);
            cx.notify();
            return;
        }
        self.close("execute", true, window, cx);
        if self.dev(cx) {
            println!("[dev] menu-exec action={action} via={via} t_ms={}", now_ms());
        }
        if let Some(url) = help_url(action) {
            cx.open_url(url);
            return;
        }
        if action == "zed::OpenLicenses" {
            if let Err(error) = gpui_kit::open_window(WindowOptions::default(), cx, |_, cx| {
                cx.new(|_| Licenses)
            }) {
                eprintln!("failed to open dependency licenses: {error}");
            }
            return;
        }
        if let Ok(action) = cx.build_action(action, None) {
            window.dispatch_action(action, cx);
        }
    }

    /// 단축키 실행 예약을 지우고 세대를 올린다(이미 걸린 50ms 타이머는 세대가 달라 아무것도 하지 않는다).
    fn cancel_pending(&mut self) {
        self.pending = None;
        self.chord.clear();
        self.generation += 1;
    }

    /// I-520: 메뉴가 열린 채 `index` 항목의 단축키가 눌렸다. 그 항목을 선택 표시하고 50ms 뒤 닫고 실행한다.
    /// 예약한 액션 자체를 들고 있다가, 50ms 동안 메뉴가 바뀌거나 닫히지 않았을 때(세대가 같을 때)만 그 액션을 실행한다
    /// (리뷰 1회차 ①, D-032). 항목 번호를 다시 조회하지 않는다.
    fn schedule_item(&mut self, index: usize, window: &mut Window, cx: &mut Context<Self>) {
        let Some(Entry::Item { action: name, .. }) = self.entries().get(index).cloned() else {
            return;
        };
        let Ok(action) = cx.build_action(name, None) else {
            return;
        };
        self.cancel_pending();
        let generation = self.generation;
        self.pending = Some((action, generation));
        self.select(Some(index), cx);
        if self.dev(cx) {
            println!("[dev] menu-shortcut action={name} t_ms={}", now_ms());
        }
        cx.spawn_in(window, async move |this, cx| {
            cx.background_executor().timer(SHORTCUT_FLASH).await;
            let _ = this.update_in(cx, |this, window, cx| this.run_pending(generation, window, cx));
        })
        .detach();
    }

    /// 50ms 뒤: 예약 세대가 그대로면 닫고(원래 포커스 복원, I-309) 예약한 액션을 보낸다.
    /// 세대가 다르면(그 사이 새 예약이 들어왔으면) 새 예약을 건드리지 않는다. 그래서 세대를 먼저 보고, 같을 때만
    /// 예약을 꺼낸다(리뷰 2회차 ⓐ, D-033).
    fn run_pending(&mut self, generation: u64, window: &mut Window, cx: &mut Context<Self>) {
        if !matches!(&self.pending, Some((_, g)) if *g == generation) || self.open.is_none() {
            return;
        }
        let Some((action, _)) = self.pending.take() else {
            return;
        };
        let name = action.name();
        self.close("execute", true, window, cx);
        if self.dev(cx) {
            println!("[dev] menu-exec action={name} via=shortcut t_ms={}", now_ms());
        }
        window.dispatch_action(action, cx);
    }

    /// 열린 메뉴에서 액션 이름이 `name` 인 항목의 번호.
    fn item_index(&self, name: &str) -> Option<usize> {
        self.entries()
            .iter()
            .position(|e| matches!(e, Entry::Item { action, .. } if *action == name))
    }

    /// gpui 의 접두 확정과 같다: 기다리던 키들 가운데 가장 긴 앞부분이 바인딩으로 풀리면 그것을 실행 대상으로 본다
    /// (메뉴를 열기 직전 포커스의 컨텍스트 스택, I-702~I-704). 그 액션이 열린 메뉴의 항목이면 예약한다.
    fn replay_prefix(&mut self, prefix: &[Keystroke], window: &mut Window, cx: &mut Context<Self>) {
        if let Some(name) = menu_common::prefix_action(&self.prev_stack, prefix, cx)
            && let Some(index) = self.item_index(name)
        {
            self.schedule_item(index, window, cx);
        }
    }

    /// chord 앞부분을 기다리기 시작한다. gpui 와 같은 시간(1초, gpui-pre `window.rs` `PENDING_INPUT_TIMEOUT`)이
    /// 지나도록 다음 키가 없으면 기다리던 키들로 확정한다.
    fn start_chord_timeout(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let token = self.chord.wait();
        cx.spawn_in(window, async move |this, cx| {
            cx.background_executor().timer(CHORD_TIMEOUT).await;
            let _ = this.update_in(cx, |this, window, cx| {
                if this.open.is_some()
                    && let Some(prefix) = this.chord.take_expired(token)
                {
                    if this.dev(cx) {
                        println!("[dev] menu-chord-timeout keys={} t_ms={}", prefix.len(), now_ms());
                    }
                    this.replay_prefix(&prefix, window, cx);
                }
            });
        })
        .detach();
    }

    /// 메뉴가 열려 있는 동안 키 입력을 디스패치 전에 본다(리뷰 1회차 ③ D-032, 2회차 ⓑ D-033). 소비하면 true.
    ///
    /// 1. 메뉴 목록 키가 먼저다: chord 를 기다리는 중이 아니고, 지금(메뉴) 컨텍스트에서 이 키가 `menu::` 액션이나
    ///    F10(`app_menu::Toggle`)으로 풀리면 건드리지 않는다(I-517, I-310).
    /// 2. 그렇지 않으면 메뉴를 열기 직전 포커스의 컨텍스트 스택으로 gpui 와 같게 푼다(I-307, D-3):
    ///    - 더 긴 바인딩이 이어질 수 있으면(접두) 키를 소비하고 다음 키를 기다린다. 1초 동안 없으면 접두로 확정한다.
    ///    - 끝까지 풀린 바인딩이 열린 메뉴의 항목 액션이면 그 항목을 예약한다(I-520).
    ///    - 기다리던 키 뒤에 이어지지 않는 키가 오면, 기다리던 키들을 먼저 확정하고 이번 키를 새로 처리한다.
    /// 3. 메뉴 항목이 아닌 액션으로 풀리거나 아무 바인딩도 없으면 보통 디스패치에 맡긴다.
    fn intercept(&mut self, event: &KeystrokeEvent, window: &mut Window, cx: &mut Context<Self>) -> bool {
        if self.open.is_none() {
            return false;
        }
        if self
            .chord
            .is_list_key(event, cx, |name| name.starts_with("menu::") || name == "app_menu::Toggle")
        {
            return false;
        }
        match self.chord.feed(&event.keystroke, &self.prev_stack, cx) {
            Feed::Wait => {
                self.start_chord_timeout(window, cx);
                true
            }
            Feed::Action { name, chord } => {
                if EDITOR_LAYOUT.iter().any(|(_, action)| *action == name) {
                    self.close("execute", true, window, cx);
                    if let Ok(action) = cx.build_action(name, None) { window.dispatch_action(action, cx); }
                    return true;
                }
                if let Some(index) = self.item_index(name) {
                    self.schedule_item(index, window, cx);
                    return true;
                }
                // 메뉴 항목이 아닌 동작. chord 였으면 앞 키를 이미 소비했으니 이번 키도 소비해 반쪽 입력을 남기지 않는다.
                chord
            }
            Feed::Replay(prefix) => {
                self.replay_prefix(&prefix, window, cx);
                self.intercept(event, window, cx)
            }
            Feed::Pass => false,
        }
    }

    fn on_mouse_down_out(&mut self, event: &MouseDownEvent, window: &mut Window, cx: &mut Context<Self>) {
        if self.submenu_bounds.is_some_and(|bounds| bounds.contains(&event.position)) {
            return;
        }
        if self
            .bar_bounds
            .is_some_and(|b| b.contains(&event.position))
        {
            return;
        }
        self.close("click-outside", false, window, cx);
    }

    fn log_render(&mut self, rows: &str, cx: &App) {
        if !self.dev(cx) {
            return;
        }
        let state = format!(
            "index={} name={} selected={} rows={rows}",
            self.open.unwrap_or_default(),
            self.open.map(|i| self.menus[i].0.as_str()).unwrap_or(""),
            self.selected
                .map(|i| i.to_string())
                .unwrap_or_else(|| "none".into()),
        );
        if state != self.last_logged {
            println!("[dev] menu-render {state}");
            self.last_logged = state;
        }
    }

    fn render_popup(&mut self, window: &mut Window, cx: &mut Context<Self>) -> AnyElement {
        let theme = cx.theme();
        let border = theme.border;
        let muted = theme.muted_foreground;
        let selected_bg = theme.secondary_hover;
        let max_height = window.viewport_size().height * MAX_HEIGHT_RATIO;
        let prev_focus = self.prev_focus.clone();

        let entries = self.entries().to_vec();
        let mut rows_log = Vec::new();
        // I-313: 최소 폭 200 은 테두리 안쪽 폭이다(바깥 폭 = 200 + 테두리 1 × 2 = 202).
        let mut list = menu_common::list(
            v_flex().on_children_prepainted(probe(&ROW_PROBES)),
            "app-menu-list",
            max_height,
        );
        for (i, entry) in entries.iter().enumerate() {
            match entry {
                Entry::Separator => {
                    rows_log.push("---".to_string());
                    list = list.child(menu_common::separator(border));
                }
                Entry::Item { label, action } => {
                    let shortcut = keymap::shortcut_for_name(action, prev_focus.as_ref(), window, cx);
                    rows_log.push(format!(
                        "{label}|{}",
                        shortcut.as_deref().unwrap_or("<none>")
                    ));
                    let selected = self.selected == Some(i);
                    list = list.child(
                        menu_common::row(("app-menu-row", i))
                            .relative()
                            .when(selected, |row| row.bg(selected_bg))
                            .on_hover(cx.listener(move |this, hovered: &bool, _, cx| {
                                if *hovered && this.selected != Some(i) {
                                    this.select(Some(i), cx);
                                }
                            }))
                            .on_click(cx.listener(move |this, _, window, cx| {
                                this.execute(i, "click", window, cx);
                            }))
                            .child(div().whitespace_nowrap().child(label.clone()))
                            .when_some(shortcut, |row, s| {
                                row.child(
                                    menu_common::shortcut_cell().text_color(muted).child(s),
                                )
                            })
                            .when(*action == "app_menu::EditorLayout", |row| {
                                row.child(super::zed_icons::icon("chevron_right").size(ICON_SMALL))
                                    .when(selected, |row| {
                                        let mut children = v_flex();
                                        for (index, (label, action)) in EDITOR_LAYOUT.iter().enumerate() {
                                            let action = *action;
                                            let shortcut = keymap::shortcut_for_name(action, prev_focus.as_ref(), window, cx);
                                            children = children.child(menu_common::row(("editor-layout", index))
                                                .when(self.layout_selected == Some(index), |row| row.bg(selected_bg))
                                                .on_hover(cx.listener(move |this, hovered: &bool, _, cx| {
                                                    if *hovered { this.layout_selected = Some(index); cx.notify(); }
                                                }))
                                                .on_click(cx.listener(move |this, _, window, cx| {
                                                    this.close("execute", true, window, cx);
                                                    if let Ok(action) = cx.build_action(action, None) { window.dispatch_action(action, cx); }
                                                    cx.stop_propagation();
                                                }))
                                                .child(*label)
                                                .when_some(shortcut, |row, shortcut| row.child(menu_common::shortcut_cell().text_color(muted).child(shortcut))));
                                        }
                                        let weak = cx.entity().downgrade();
                                        row.child(div().absolute().left_full().top_0().child(deferred(anchored()
                                            .snap_to_window_with_margin(WINDOW_MARGIN)
                                            .child(div().on_children_prepainted(move |bounds, _, cx| {
                                                let _ = weak.update(cx, |this, _| this.submenu_bounds = bounds.first().copied());
                                            }).child(menu_common::popup_surface(div(), cx).child(children)))).with_priority(2)))
                                    })
                            }),
                    );
                }
            }
        }
        // 줄 구분은 탭(단축키 글자 `;` 와 겹치지 않게).
        self.log_render(&rows_log.join("\t"), cx);

        let popup = div()
            .key_context(crate::keymap::builtin::MENU_CONTEXT)
            .track_focus(&self.focus)
            .on_action(cx.listener(Self::on_select_next))
            .on_action(cx.listener(Self::on_select_previous))
            .on_action(cx.listener(Self::on_select_first))
            .on_action(cx.listener(Self::on_select_last))
            .on_action(cx.listener(Self::on_cancel))
            .on_action(cx.listener(Self::on_confirm))
            .on_action(cx.listener(Self::on_next_menu))
            .on_action(cx.listener(Self::on_previous_menu))
            // I-520 항목 단축키는 `intercept`(키 입력 가로채기)가 맡는다.
            .on_mouse_down_out(cx.listener(Self::on_mouse_down_out));
        let popup = menu_common::popup_surface(popup, cx).child(list);

        div()
            .absolute()
            .top_full()
            .left(POPUP_OFFSET_X)
            .child(
                deferred(
                    anchored()
                        .snap_to_window_with_margin(WINDOW_MARGIN)
                        .child(div().on_children_prepainted(probe(&["menu-box"])).child(popup)),
                )
                .with_priority(1),
            )
            .into_any_element()
    }
}

impl Render for AppMenu {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let theme = cx.theme();
        let muted = theme.muted_foreground;
        let hover_bg = theme.secondary_hover;
        let active_bg = theme.secondary_active;

        let Some(open) = self.open else {
            // 닫힌 상태: Menu 아이콘 버튼 하나(L-85, I-302, I-321). 툴팁 L-225.
            return h_flex()
                .on_children_prepainted(probe(&["app-menu-button"]))
                .child(
                    div()
                        .id("app-menu-button")
                        .flex()
                        .items_center()
                        .justify_center()
                        .size(BUTTON_DEFAULT)
                        .text_color(muted)
                        .hover(move |s| s.bg(hover_bg))
                        .on_click(cx.listener(|this, _, window, cx| this.toggle(window, cx)))
                        .tooltip(tooltip::build(Spec::one(
                            "app-menu-button",
                            Line::text("Open Application Menu"),
                        )))
                        .child(super::zed_icons::icon("menu").size(ICON_SMALL)),
                )
                .into_any_element();
        };

        // 열린 상태: 가로 메뉴 바(I-302, I-303). 메뉴가 열려 있으니 툴팁은 없다(L-205).
        let weak = cx.entity().downgrade();
        let names: Vec<String> = self.menus.iter().map(|(n, _)| n.clone()).collect();
        let popup = self.render_popup(window, cx);
        let mut popup = Some(popup);
        let mut bar = h_flex()
            .gap(NAME_GAP)
            .on_children_prepainted(move |bounds: Vec<Bounds<Pixels>>, window, cx| {
                if let (Some(first), Some(last)) = (bounds.first(), bounds.last()) {
                    let union = first.union(last);
                    let _ = weak.update(cx, |this, _| this.bar_bounds = Some(union));
                }
                probe(&NAME_PROBES)(bounds, window, cx);
            });
        for (i, name) in names.into_iter().enumerate() {
            let is_open = i == open;
            bar = bar.child(
                div()
                    .id(("app-menu-name", i))
                    .relative()
                    .flex()
                    .items_center()
                    .h(BUTTON_DEFAULT)
                    .px(NAME_PAD_X)
                    .text_size(NAME_TEXT)
                    .when(is_open, |d| d.bg(active_bg))
                    .hover(move |s| s.bg(hover_bg))
                    .on_hover(cx.listener(move |this, hovered: &bool, window, cx| {
                        if *hovered && this.open.is_some() && this.open != Some(i) {
                            this.open_menu(i, window, cx);
                        }
                    }))
                    .on_click(cx.listener(move |this, _, window, cx| {
                        if this.open == Some(i) {
                            this.close("toggle", true, window, cx);
                        } else {
                            this.open_menu(i, window, cx);
                        }
                    }))
                    .child(name)
                    .when(is_open, |d| d.children(popup.take())),
            );
        }
        bar.into_any_element()
    }
}

#[cfg(test)]
mod tests {
    // `use super::*` 는 gpui_kit::* 의 `test` 매크로까지 가져와 `#[test]` 를 가린다.
    use super::{Entry, definition, visible_menus};

    fn labels(entries: &[Entry]) -> Vec<String> {
        entries
            .iter()
            .map(|e| match e {
                Entry::Item { label, .. } => label.clone(),
                Entry::Separator => "---".into(),
            })
            .collect()
    }

    #[test]
    fn k09_menus_follow_zed_order_with_available_actions() {
        let menus = visible_menus();
        let names: Vec<_> = menus.iter().map(|(n, _)| n.as_str()).collect();
        assert_eq!(names, ["workbench-gpui", "File", "Edit", "View", "Go", "Window", "Help"]);
        assert_eq!(labels(&menus[0].1), ["Quit workbench-gpui"]);
        assert_eq!(labels(&menus[1].1), ["Open Folder...", "---", "Save", "---", "Close Editor", "Close Window"]);
        assert_eq!(labels(&menus[2].1), ["Undo", "Redo"]);
        assert_eq!(
            labels(&menus[3].1),
            [
                "Toggle Left Dock",
                "Toggle Folder Sidebar",
                "Focus Folder Sidebar",
                "Editor Layout",
                "Maximize Pane",
                "---",
                "Project Panel",
                "Open Markdown Preview",
                "Open Markdown Preview to the Side"
            ]
        );
        assert_eq!(labels(&menus[4].1), ["Previous Tab", "Next Tab"]);
        assert_eq!(labels(&menus[5].1), ["Minimize", "Zoom"]);
        assert_eq!(labels(&menus[6].1), ["View Dependency Licenses", "---", "File Bug Report...", "Request Feature...", "---", "workbench-gpui Repository"]);
    }

    #[test]
    fn definition_matches_9_2_tree() {
        // 9.2절 그림의 항목 수(구분선 포함)와 같다.
        let counts: Vec<_> = definition().iter().map(|(_, e)| e.len()).collect();
        assert_eq!(counts, [13, 15, 12, 15, 15, 9, 2, 6]);
    }

    #[test]
    fn k09_help_targets_and_bundled_licenses() {
        assert_eq!(super::help_url("help::FileBugReport"), Some("https://github.com/nampluskr/workbench-gpui/issues/new"));
        assert_eq!(super::help_url("help::RequestFeature"), super::help_url("help::FileBugReport"));
        assert_eq!(super::help_url("help::Repository"), Some("https://github.com/nampluskr/workbench-gpui"));
        assert_eq!(super::help_url("workspace::Save"), None);
        assert_eq!(super::LICENSES.len(), 8);
        for (name, files) in [
            ("ignore 0.4.34", ["ignore/LICENSE-MIT", "ignore/UNLICENSE"]),
            ("regex 1.13.1", ["regex/LICENSE-MIT", "regex/LICENSE-APACHE"]),
        ] {
            let (_, text) = super::LICENSES.iter().find(|(n, _)| n.starts_with(name)).unwrap_or_else(|| panic!("missing license entry {name}"));
            assert!(!text.trim().is_empty());
            for file in files {
                assert!(std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("resources/licenses").join(file).is_file(), "missing {file}");
            }
        }
        assert!(super::LICENSES.iter().all(|(_, text)| text.contains("License") || text.contains("LICENSE")));
        assert_eq!(super::PANEL_LAYOUTS, ["Classic"]);
        assert_eq!(super::EDITOR_LAYOUT, [("Split Up", "pane::SplitUp"), ("Split Down", "pane::SplitDown"), ("Split Left", "pane::SplitLeft"), ("Split Right", "pane::SplitRight")]);
        assert_eq!(super::USER_ITEMS.iter().map(|(name, _)| *name).collect::<Vec<_>>(), ["Settings", "Keymap", "Themes…", "Icon Themes…", "Extensions"]);
    }

    #[test]
    fn k09_editor_menu_uses_existing_input_actions() {
        use gpui_kit::Action as _;
        use gpui_kit::component::input::{Redo, Undo};
        assert!(super::AVAILABLE.contains(&Undo.name()));
        assert!(super::AVAILABLE.contains(&Redo.name()));
        let menus = visible_menus();
        for action in [Undo.name(), Redo.name(), "workspace::Save", "markdown::OpenPreview", "markdown::OpenPreviewToTheSide"] {
            assert!(menus.iter().flat_map(|(_, entries)| entries).any(|entry| matches!(entry, Entry::Item { action: name, .. } if *name == action)));
        }
    }
}

//! 레이아웃 뼈대 (PLAN Phase 3, SPEC R-12~R-14, DECISIONS D-10 이후 변경).
//!
//! 01-zed L-11~L-16 배치(왼쪽 사이드바 → Workspace[타이틀 바 → 본문(왼쪽 Dock → 가운데 Pane) → 상태 표시줄])의
//! 각 영역을 그린다. 내용이 없는 자리(폴더 줄, 탭, 프로젝트 패널, 활성 아이템)는 치수 확인용 자리 표시 요소다.
//! 아이콘은 gpui-kit 기본 아이콘 묶음에서 가까운 것을 임시로 쓴다(Zed 아이콘 테마는 PoC 7단계 범위).
//! 색은 gpui-kit 기본 테마 토큰이다(테마 매핑 G-106 은 v0.1 범위 밖).

use gpui_kit::component::{ActiveTheme as _, h_flex, v_flex};
use gpui_kit::*;

use gpui_kit::prelude::FluentBuilder as _;

use super::layout_probe::{self, probe};
use super::metrics::*;
use super::rem::rems_from_px;
use super::tooltip::{self, Line, Spec};

/// 왼쪽 사이드바(등록 폴더 목록) 내용. resizable 패널 안에 들어간다(D-10 이후 변경).
///
/// L-12 맨 위 줄 높이 = 타이틀 바 높이 32, 아래 테두리(L-302), 창 끌기 영역(A-11.2).
/// L-34 폴더 줄(자리 표시), L-35 푸터: padding 4, gap 4, 위 테두리, Small 14 아이콘 버튼.
/// A-11.8 사이드바가 열린 상태의 푸터: 왼쪽 사이드바 토글, 오른쪽 끝 폴더 추가. L-303 오른쪽 테두리.
pub fn sidebar(list: AnyElement, cx: &App) -> impl IntoElement {
    let theme = cx.theme();
    v_flex()
        .on_children_prepainted(probe(&["sidebar-header", "sidebar-list", "sidebar-footer"]))
        .size_full()
        .bg(theme.sidebar)
        .border_r_1()
        .border_color(theme.border)
        .child(
            div()
                .id("sidebar-header")
                .flex_shrink_0()
                .w_full()
                .h(TITLE_BAR_HEIGHT)
                .border_b_1()
                .border_color(theme.border)
                .window_control_area(WindowControlArea::Drag),
        )
        .child(
            // 폴더 줄 목록(A-12, A-16.7 세로 스크롤). 사이드바 빈 공간에는 우클릭 메뉴가 없다(I-937).
            div()
                .id("sidebar-list")
                .flex_1()
                .min_h_0()
                .child(list),
        )
        .child(
            // 왼쪽 그룹을 flex_1 로 늘려 오른쪽 그룹을 끝에 붙인다(justify_between 과 보이는 결과가 같다).
            // 이렇게 하면 두 그룹 사이가 정확히 gap 4 가 되어 레이아웃으로 잴 수 있다.
            h_flex()
                .on_children_prepainted(probe(&["sidebar-footer-left", "sidebar-footer-right"]))
                .flex_shrink_0()
                .w_full()
                // Border-box: 30 includes the 1px top border, so the 22px buttons overflow the inner box by
                // 1px, centred inside the padding (padding stays the spec 4).
                .h(SIDEBAR_FOOTER_HEIGHT)
                .items_center()
                .p(SIDEBAR_FOOTER_PADDING)
                .gap(SIDEBAR_FOOTER_GAP)
                .border_t_1()
                .border_color(theme.border)
                .child(
                    h_flex()
                        .on_children_prepainted(probe(&[
                            "sidebar-btn-toggle",
                            "sidebar-footer-left-placeholder",
                        ]))
                        .flex_1()
                        .gap(SIDEBAR_FOOTER_GAP)
                        .child(icon_with_probe(
                            "sidebar-btn-toggle",
                            &["sidebar-icon-toggle"],
                            "threads_sidebar_left_open",
                            Some(Spec::two(
                                "sidebar-btn-toggle",
                                Line::action("Toggle Sidebar", "multi_workspace::ToggleWorkspaceSidebar"),
                                Line::action("Focus Sidebar", "multi_workspace::FocusWorkspaceSidebar"),
                            )),
                            cx,
                        ).on_click(dispatch("multi_workspace::ToggleWorkspaceSidebar")))
                        .when(layout_probe::is_enabled(), |d| {
                            d.child(measure_placeholder())
                        }),
                )
                .child(
                    h_flex()
                        .on_children_prepainted(probe(&["sidebar-btn-folder-add"]))
                        .gap(SIDEBAR_FOOTER_GAP)
                        .child(icon_with_probe(
                            "sidebar-btn-folder-add",
                            &["sidebar-icon-folder-add"],
                            "folder_add",
                            Some(Spec::one(
                                "sidebar-btn-folder-add",
                                Line::action("Add Project", "workspace::Open"),
                            )),
                            cx,
                        ).on_click(dispatch("workspace::Open"))),
                ),
        )
}


/// 버튼을 누르면 액션 이름 `name` 을 보낸다(지금 포커스 자리에서 디스패치한다).
fn dispatch(name: &'static str) -> impl Fn(&ClickEvent, &mut Window, &mut App) + 'static {
    move |_, window, cx| {
        if crate::ui::keymap::dev_enabled(cx) {
            println!("[dev] button-click action={name}");
        }
        if let Ok(action) = cx.build_action(name, None) {
            window.dispatch_action(action, cx);
        }
    }
}

/// 아이콘 버튼과 그 안의 아이콘 경계를 함께 기록한다(A-32.16 아이콘 14 확인용).
fn icon_with_probe(
    id: &'static str,
    icon_name: &'static [&'static str],
    icon: &'static str,
    tooltip: Option<Spec>,
    cx: &App,
) -> Stateful<Div> {
    let theme = cx.theme();
    let hover_bg = theme.secondary_hover;
    div()
        .on_children_prepainted(probe(icon_name))
        .id(id)
        .flex()
        .flex_shrink_0()
        .items_center()
        .justify_center()
        .size(BUTTON_DEFAULT)
        .text_color(theme.muted_foreground)
        .hover(move |s| s.bg(hover_bg))
        .when_some(tooltip, |d, spec| d.tooltip(tooltip::build(spec)))
        .child(super::zed_icons::icon(icon).size(ICON_SMALL))
}

/// 탭 바 (L-61: [시작 영역] + [탭 목록] + [끝 영역]).
///
/// - L-22 높이 32, L-23 탭 내용 31, L-24 탭 padding·gap 4, L-25 슬롯 12×12·14×14.
/// - L-27 양 끝 영역: gap 4, 좌우 padding 6, 아래 테두리, 시작 영역 오른쪽·끝 영역 왼쪽 테두리.
/// - L-62 시작 영역 ← →, L-71~L-73 끝 영역 + · 분할 · 최대화 (Small 14).
/// - L-63 활성 탭은 아래 테두리가 없어 내용과 이어진다. 탭은 자리 표시 하나(활성)다.
///
/// Click handler of a tab's close button.
pub type CloseHandler = std::rc::Rc<dyn Fn(&ClickEvent, &mut Window, &mut App)>;

/// What a mouse press on a tab asks for (I-063, I-066, I-075, L-74).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum TabPress {
    /// Single left press: make it the pane's active tab.
    Activate,
    /// Left double-click: the active tab becomes a normal tab (I-063).
    Promote,
    /// Middle click on a normal tab: close with the save question (I-075).
    Close,
    Ignore,
}

/// I-063, I-066, I-075: the request for a press of `button` (`clicks` in a row) on a pinned or normal tab.
pub fn tab_press(button: MouseButton, clicks: usize, pinned: bool) -> TabPress {
    match button {
        MouseButton::Left if clicks >= 2 => TabPress::Promote,
        MouseButton::Left => TabPress::Activate,
        MouseButton::Middle if !pinned => TabPress::Close,
        _ => TabPress::Ignore,
    }
}

/// Which text colour a tab title takes (L-306).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum TabText {
    Text,
    Muted,
    Hidden,
}

/// L-306, L-314: an editor tab is `text` when active and `text_muted` otherwise, whatever has focus. A Markdown preview
/// tab follows its pane's focus: focused → the same; without focus (deemphasized) the active one is `text_muted` and
/// the inactive one `status.hidden`, much fainter.
pub fn tab_text(markdown: bool, active: bool, pane_focused: bool) -> TabText {
    match (markdown && !pane_focused, active) {
        (false, true) => TabText::Text,
        (false, false) | (true, true) => TabText::Muted,
        (true, false) => TabText::Hidden,
    }
}

/// `status.hidden` has no spec value (spec/zed-metrics.toml, ambiguous.md); gpui-kit has no such token.
// shortcut: the muted colour at half strength stands for `status.hidden`; replace with the measured colour (L-306).
const HIDDEN_OPACITY: f32 = 0.5;

/// A right press on a tab: the pointer position, where the tab menu opens.
pub type ContextHandler = std::rc::Rc<dyn Fn(&Point<Pixels>, &mut Window, &mut App)>;

/// Mouse press handler of a tab.
pub type PressHandler = std::rc::Rc<dyn Fn(&TabPress, &mut Window, &mut App)>;

/// Payload of a tab being dragged (I-074, I-715): where it comes from. Shown as a small ghost with the title.
#[derive(Clone)]
pub struct TabDrag {
    pub pane: u32,
    pub ix: usize,
    pub title: SharedString,
}

impl Render for TabDrag {
    fn render(&mut self, _: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let theme = cx.theme();
        div()
            .px(TAB_PADDING_X)
            .h(TAB_CONTENT_HEIGHT)
            .flex()
            .items_center()
            .text_size(TEXT_SIZE_DEFAULT)
            .bg(theme.tab_bar)
            .border_1()
            .border_color(theme.border)
            .child(self.title.clone())
    }
}

/// A tab drag dropped on a tab, the tab-bar end or a pane body.
pub type DropHandler = std::rc::Rc<dyn Fn(&TabDrag, &mut Window, &mut App)>;

/// I-715: a drop mark on the tab's left edge when the dragged tab starts after it (or in another pane), else on its
/// right edge. `true` is left. The pointer's side of the tab does not matter.
pub fn tab_drop_left(drag_pane: u32, drag_ix: usize, pane: u32, ix: usize) -> bool {
    drag_pane != pane || drag_ix > ix
}

/// `tab_bar_end_drop_min_width` (I-716, L-70): the empty tab-bar end takes a drop from 24px wide.
const TAB_BAR_END_DROP_MIN_WIDTH: Rems = rems_from_px(24.);
/// `tab_drop_line_width` (I-715).
const TAB_DROP_LINE_WIDTH: Pixels = px(2.);

/// The end buttons of the pane that has focus (I-706): `+`, split, zoom.
pub struct BarEnd {
    /// I-707: the split button is disabled for an empty pane.
    pub split_enabled: bool,
    /// I-730: zoomed → `Minimize` icon, selected look, "Zoom Out".
    pub zoomed: bool,
    pub on_split: CloseHandler,
    pub on_zoom: CloseHandler,
}

/// 탭 하나의 표시 값(Phase 4 최소 탭, R-27).
pub struct TabView {
    pub title: SharedString,
    /// 임시 탭이면 제목 기울임(I-064, L-68).
    pub preview: bool,
    /// 핀 탭이면 끝 슬롯에 닫기 대신 핀 아이콘(L-66). 핀 탭은 맨 앞 묶음이다(I-065).
    pub pinned: bool,
    pub active: bool,
    /// Mouse press on the tab (activate, double-click promote, middle-click close).
    pub press: PressHandler,
    /// Click on the pin icon: unpin (L-66).
    pub unpin: CloseHandler,
    /// Right press: the Pin / Unpin menu of this tab.
    pub context: ContextHandler,
    /// A rendered Markdown preview tab (L-69): the `FileDoc` (book) icon is always drawn, no italic.
    pub markdown: bool,
    /// The tab's pane has focus (the active pane); a preview tab dims without it (L-306).
    pub focused: bool,
    /// This tab as a drag payload (I-074) and what a drop on it does (I-715).
    pub drag: TabDrag,
    pub dropped: DropHandler,
    /// 수정됨(편집·충돌·내용 있는 지워진 파일)이면 시작 슬롯에 점(L-65, `Tab::modified`).
    pub dirty: bool,
    /// 디스크와 충돌(E-086): 점이 Warning 색.
    pub conflict: bool,
    /// 디스크에서 지워짐(E-087): 제목 취소선.
    pub deleted: bool,
    /// 닫기 버튼 처리기 (L-66, P3-3).
    pub close: CloseHandler,
}

const TAB_PROBES: [&str; 12] = [
    "tab-00", "tab-01", "tab-02", "tab-03", "tab-04", "tab-05", "tab-06", "tab-07", "tab-08", "tab-09", "tab-10",
    "tab-11",
];

/// 탭 목록(L-61 가운데 영역). 탭이 없으면 v0.1 뼈대의 자리 표시 탭 하나를 그린다(판단: 앞 Phase 판정 그대로).
/// L-63: 활성 탭은 아래 테두리 대신 1px 여백(내용 높이 31), 비활성 탭은 아래 테두리. 탭 사이는 오른쪽 테두리(판단).
/// L-64 [시작 슬롯 12][제목][끝 슬롯 14], L-67 파일 아이콘 없음.
fn tab_list(tabs: &[TabView], cx: &App) -> AnyElement {
    let theme = cx.theme();
    if tabs.is_empty() {
        return div()
            .on_children_prepainted(probe(&["tab-content"]))
            .flex_shrink_0()
            .h_full()
            .pb(rems_1px())
            .bg(theme.background)
            .child(
                h_flex()
                    .on_children_prepainted(probe(&["tab-slot-start", "tab-label", "tab-slot-end"]))
                    .h(TAB_CONTENT_HEIGHT)
                    .px(TAB_PADDING_X)
                    .gap(TAB_GAP)
                    .items_center()
                    .text_size(TEXT_SIZE_DEFAULT)
                    .child(div().flex_shrink_0().size(TAB_START_SLOT))
                    .child(div().child("untitled (placeholder)"))
                    .child(div().flex_shrink_0().size(TAB_END_SLOT)),
            )
            .into_any_element();
    }
    let mut row = h_flex().on_children_prepainted(probe(&TAB_PROBES)).flex_shrink_0().h_full();
    for (i, tab) in tabs.iter().enumerate() {
        let label_names: &'static [&'static str] = match i {
            0 => &["", "tab-label-00", ""],
            1 => &["", "tab-label-01", ""],
            2 => &["", "tab-label-02", ""],
            _ => &[],
        };
        let (press, pinned) = (tab.press.clone(), tab.pinned);
        let press_middle = press.clone();
        let (me, dropped, context) = (tab.drag.clone(), tab.dropped.clone(), tab.context.clone());
        let (mark_bg, mark_border) = (theme.drop_target, theme.drag_border);
        row = row.child(
            div()
                .id(("tab", i))
                .flex_shrink_0()
                .h_full()
                .group(SharedString::from(format!("tab-{i}")))
                .on_mouse_down(MouseButton::Left, move |e, window, cx| {
                    press(&tab_press(MouseButton::Left, e.click_count, pinned), window, cx)
                })
                .on_mouse_down(MouseButton::Right, move |e, window, cx| context(&e.position, window, cx))
                .on_mouse_up(MouseButton::Middle, move |_, window, cx| {
                    press_middle(&tab_press(MouseButton::Middle, 1, pinned), window, cx)
                })
                .on_drag(tab.drag.clone(), |drag, _, _, cx| cx.new(|_| drag.clone()))
                .on_drop::<TabDrag>(move |d, window, cx| dropped(d, window, cx))
                // I-715: background, border and a 2px line on the side the tab will land on.
                .drag_over::<TabDrag>(move |s, d, _, _| {
                    let s = s.bg(mark_bg).border_color(mark_border);
                    if tab_drop_left(d.pane, d.ix, me.pane, me.ix) {
                        s.border_l(TAB_DROP_LINE_WIDTH)
                    } else {
                        s.border_r(TAB_DROP_LINE_WIDTH)
                    }
                })
                .border_r_1()
                .border_color(theme.border)
                .when(tab.active, |d| d.pb(rems_1px()).bg(theme.background))
                .when(!tab.active, |d| d.border_b_1().bg(theme.tab_bar))
                .child(
                    h_flex()
                        .on_children_prepainted(probe(label_names))
                        .h(TAB_CONTENT_HEIGHT)
                        .px(TAB_PADDING_X)
                        .gap(TAB_GAP)
                        .items_center()
                        .text_size(TEXT_SIZE_DEFAULT)
                        .text_color(match tab_text(tab.markdown, tab.active, tab.focused) {
                            TabText::Text => theme.foreground,
                            TabText::Muted => theme.muted_foreground,
                            TabText::Hidden => theme.muted_foreground.opacity(HIDDEN_OPACITY),
                        })
                        .child(
                            div()
                                .flex()
                                .flex_shrink_0()
                                .items_center()
                                .justify_center()
                                .size(TAB_START_SLOT)
                                // shortcut: Accent approximated by the theme primary (no Accent token in gpui-kit); conflict uses Warning (L-65).
                                .when(tab.dirty, |d| d.child(div().size(TAB_INDICATOR_SIZE).rounded_full().bg(if tab.conflict { theme.warning } else { theme.primary }))),
                        )
                        .child(
                            h_flex()
                                .gap(TAB_GAP)
                                .items_center()
                                .when(tab.markdown, |d| d.child(super::zed_icons::icon("file_doc").size(ICON_SMALL)))
                                .child(div().whitespace_nowrap().when(tab.preview, |d| d.italic()).when(tab.deleted, |d| d.line_through()).child(tab.title.clone())),
                        )
                        .child(end_slot(i, tab, cx)),
                ),
        );
    }
    row.into_any_element()
}

/// Pin slot of a pinned tab (L-66): the pin icon replaces the close button; a click unpins.
fn pin_slot(i: usize, tab: &TabView, cx: &App) -> AnyElement {
    let unpin = tab.unpin.clone();
    div()
        .id(("tab-pin", i))
        .flex()
        .flex_shrink_0()
        .items_center()
        .justify_center()
        .size(TAB_END_SLOT)
        .text_color(cx.theme().muted_foreground)
        .text_size(ICON_SMALL)
        .on_click(move |e, window, cx| unpin(e, window, cx))
        .child(super::zed_icons::icon("pin").size(ICON_SMALL))
        .into_any_element()
}

fn end_slot(i: usize, tab: &TabView, cx: &App) -> AnyElement {
    if tab.pinned { pin_slot(i, tab, cx) } else { close_slot(i, tab, cx).into_any_element() }
}

/// 탭 끝 슬롯 (L-64, L-66): 닫기 버튼. 아이콘 `Close` Small Muted, 탭에 마우스를 올릴 때만 보인다(`show_close_button` 기본 "hover").
/// 보이지 않을 때도 슬롯 14 자리는 그대로다(L-25).
fn close_slot(i: usize, tab: &TabView, cx: &App) -> impl IntoElement {
    let close = tab.close.clone();
    div()
        .id(("tab-close", i))
        .flex()
        .flex_shrink_0()
        .items_center()
        .justify_center()
        .size(TAB_END_SLOT)
        .text_color(cx.theme().muted_foreground)
        .invisible()
        .group_hover(SharedString::from(format!("tab-{i}")), |s| s.visible())
        .on_click(move |e, window, cx| close(e, window, cx))
        .child(super::zed_icons::icon("close").size(ICON_SMALL))
}

pub fn tab_bar(tabs: &[TabView], end: Option<BarEnd>, end_drop: DropHandler, cx: &App) -> impl IntoElement {
    let theme = cx.theme();
    let drop_bg = theme.drop_target;
    h_flex()
        .on_children_prepainted(probe(&[
            "tab-bar-start",
            "tab",
            "tab-bar-filler",
            "tab-bar-end",
        ]))
        .flex_shrink_0()
        .w_full()
        .h(TAB_BAR_HEIGHT)
        .bg(theme.tab_bar)
        .child(
            h_flex()
                .on_children_prepainted(probe(&["tab-btn-back", "tab-btn-forward"]))
                .flex_shrink_0()
                .h_full()
                .items_center()
                .px(TAB_BAR_EDGE_PADDING_X)
                .gap(TAB_BAR_EDGE_GAP)
                .border_b_1()
                .border_r_1()
                .border_color(theme.border)
                .child(icon_with_probe(
                    "tab-btn-back",
                    &["tab-icon-back"],
                    "arrow_left",
                    Some(Spec::one("tab-btn-back", Line::action("Go Back", "pane::GoBack"))),
                    cx,
                ))
                .child(icon_with_probe(
                    "tab-btn-forward",
                    &["tab-icon-forward"],
                    "arrow_right",
                    Some(Spec::one("tab-btn-forward", Line::action("Go Forward", "pane::GoForward"))),
                    cx,
                )),
        )
        .child(
            // 활성 탭: 아래 테두리 대신 1px 여백을 두어 내용 높이 31 을 남긴다. 탭이 없으면 자리 표시.
            tab_list(tabs, cx),
        )
        .child(
            // I-716: a drop on the empty end puts the tab last and does not split.
            div()
                .flex_1()
                .min_w(TAB_BAR_END_DROP_MIN_WIDTH)
                .h_full()
                .border_b_1()
                .border_color(theme.border)
                .on_drop::<TabDrag>(move |d, window, cx| end_drop(d, window, cx))
                .drag_over::<TabDrag>(move |s, _, _, _| s.bg(drop_bg)),
        )
        // I-706: the end buttons belong to the pane that has focus only.
        .children(end.map(|end| {
            let split = icon_with_probe(
                "tab-btn-split",
                &["tab-icon-split"],
                "split",
                Some(Spec::one("tab-btn-split", Line::text("Split Pane"))),
                cx,
            );
            let (on_split, on_zoom) = (end.on_split, end.on_zoom);
            let (zoom_label, zoom_icon) = if end.zoomed { ("Zoom Out", "minimize") } else { ("Zoom In", "maximize") };
            h_flex()
                .on_children_prepainted(probe(&["tab-btn-new", "tab-btn-split", "tab-btn-zoom"]))
                .flex_shrink_0()
                .h_full()
                .items_center()
                .px(TAB_BAR_EDGE_PADDING_X)
                .gap(TAB_BAR_EDGE_GAP)
                .border_b_1()
                .border_l_1()
                .border_color(theme.border)
                .child(icon_with_probe(
                    "tab-btn-new",
                    &["tab-icon-new"],
                    "plus",
                    Some(Spec::one("tab-btn-new", Line::text("New…"))),
                    cx,
                ))
                .child(if end.split_enabled {
                    split.on_click(move |e, window, cx| on_split(e, window, cx))
                } else {
                    // I-707: nothing to split → disabled look, no click.
                    split.opacity(0.4)
                })
                .child(
                    icon_with_probe(
                        "tab-btn-zoom",
                        &["tab-icon-zoom"],
                        zoom_icon,
                        Some(Spec::one("tab-btn-zoom", Line::action(zoom_label, "workspace::ToggleZoom"))),
                        cx,
                    )
                    .when(end.zoomed, |d| d.bg(theme.secondary_active))
                    .on_click(move |e, window, cx| on_zoom(e, window, cx)),
                )
        }))
}

/// E-038 toolbar box: padding 6 / 8, at least 32 high, 1px line below, quick actions 1px apart.
const TOOLBAR_MIN_HEIGHT: Rems = rems_from_px(32.);
const TOOLBAR_PADDING_X: Rems = rems_from_px(8.);
const TOOLBAR_PADDING_Y: Rems = rems_from_px(6.);
const TOOLBAR_QUICK_ACTIONS_GAP: Pixels = px(1.);

/// The toolbar of a Markdown editor tab with its quick actions (E-038, E-039): the preview button (`Eye`, Small,
/// tooltip "Preview Markdown" with its key and the meta line). Buffer Search and Selection Controls are not built yet.
// shortcut: the toolbar shows for Markdown files only (no breadcrumbs, no other quick actions yet), and takes the editor
// background for `toolbar_background`; extend to every editor tab with the breadcrumb work.
pub fn markdown_toolbar(on_preview: CloseHandler, cx: &App) -> impl IntoElement {
    let theme = cx.theme();
    let mut tip = Spec::one("toolbar-btn-preview", Line::action("Preview Markdown", "markdown::OpenPreview"));
    tip.meta = Some("Alt-Click to open in a split".into());
    h_flex()
        .on_children_prepainted(probe(&["toolbar-btn-preview"]))
        .flex_shrink_0()
        .w_full()
        .min_h(TOOLBAR_MIN_HEIGHT)
        .px(TOOLBAR_PADDING_X)
        .py(TOOLBAR_PADDING_Y)
        .justify_end()
        .items_center()
        .gap(TOOLBAR_QUICK_ACTIONS_GAP)
        .border_b_1()
        .border_color(theme.border)
        .bg(theme.background)
        .child(
            icon_with_probe("toolbar-btn-preview", &["toolbar-icon-preview"], "eye", Some(tip), cx)
                .on_click(move |e, window, cx| on_preview(e, window, cx)),
        )
}

/// 1 논리 px (rem 16 기준) — 활성 탭 아래 여백(L-63 `pb_px`).
fn rems_1px() -> Rems {
    BORDER_1PX
}

/// 상태 표시줄 (L-28 padding 4, L-29 그룹 사이 8·그룹 안 4, L-91 좌·우 목록).
///
/// A-11.8 사이드바가 열린 상태: 왼쪽에 프로젝트 패널 토글. A-11.9 닫힌 상태: 사이드바 토글·폴더 추가·프로젝트 패널 토글.
/// 오른쪽에 커서 위치(L-97, 자리 표시 "1:1").
pub fn status_bar(dock_open: bool, sidebar_open: bool, cx: &App) -> impl IntoElement {
    let theme = cx.theme();
    // 왼쪽 그룹을 flex_1 로 늘려 오른쪽 그룹을 끝에 붙인다(justify_between 과 보이는 결과가 같다).
    // 이렇게 하면 두 그룹 사이가 정확히 gap 8 이 되어 레이아웃으로 잴 수 있다.
    let measuring = layout_probe::is_enabled();
    h_flex()
        .on_children_prepainted(probe(&["status-left", "status-right"]))
        .flex_shrink_0()
        .w_full()
        .p(STATUS_BAR_PADDING)
        .gap(STATUS_BAR_GROUP_GAP)
        .bg(theme.status_bar)
        .child({
            // A-11.9 사이드바가 닫히면 [사이드바 토글][폴더 추가][프로젝트 패널 토글] 순서.
            let pp_action = if dock_open { "workspace::ToggleLeftDock" } else { "project_panel::ToggleFocus" };
            let pp = icon_with_probe(
                "status-btn-project-panel",
                &["status-icon-project-panel"],
                "file_tree",
                Some(project_panel_toggle_tooltip(dock_open)),
                cx,
            )
            .on_click(dispatch(pp_action));
            let left = h_flex().flex_1().gap(STATUS_BAR_ITEM_GAP);
            if sidebar_open {
                left.on_children_prepainted(probe(&["status-btn-project-panel", "status-left-placeholder"]))
                    .child(pp)
                    .when(measuring, |d| d.child(measure_placeholder()))
            } else {
                left.on_children_prepainted(probe(&[
                    "status-btn-sidebar-toggle",
                    "status-btn-folder-add",
                    "status-btn-project-panel",
                ]))
                .child(
                    icon_with_probe(
                        "status-btn-sidebar-toggle",
                        &["status-icon-sidebar-toggle"],
                        "threads_sidebar_left_closed",
                        // L-251 사이드바가 닫혔을 때: `Open Folder Sidebar` + 사이드바 토글 키.
                        Some(Spec::one(
                            "status-btn-sidebar-toggle",
                            Line::action("Open Folder Sidebar", "multi_workspace::ToggleWorkspaceSidebar"),
                        )),
                        cx,
                    )
                    .on_click(dispatch("multi_workspace::ToggleWorkspaceSidebar")),
                )
                .child(
                    icon_with_probe(
                        "status-btn-folder-add",
                        &["status-icon-folder-add"],
                        "folder_add",
                        Some(Spec::one("status-btn-folder-add", Line::action("Add Project", "workspace::Open"))),
                        cx,
                    )
                    .on_click(dispatch("workspace::Open")),
                )
                .child(pp)
            }
        })
        .child(
            h_flex()
                .on_children_prepainted(probe(&["status-right-placeholder", "status-cursor"]))
                .gap(STATUS_BAR_ITEM_GAP)
                .when(measuring, |d| d.child(measure_placeholder()))
                .child(
                    div()
                        .flex()
                        .items_center()
                        .h(BUTTON_DEFAULT)
                        .text_size(TEXT_SIZE_SMALL)
                        .child("1:1"),
                ),
        )
}

/// 측정 모드(`--dev-layout`)에서만 넣는 자리 표시 요소: 버튼 크기(22×22)의 빈 상자.
/// 그룹 안 항목이 하나뿐이면 gap 을 잴 수 없어(SPEC R-13), 그룹당 두 개가 되도록 하나 더 둔다.
fn measure_placeholder() -> Div {
    div().flex_shrink_0().size(BUTTON_DEFAULT)
}

/// 상태 표시줄 프로젝트 패널 토글의 툴팁(L-253, L-254, L-266). 패널이 열려 있고 활성이면 `Close Left Dock`
/// + Dock 토글 키, 닫혀 있으면 `Project Panel` + 패널 포커스 토글 키. 왼쪽 Dock 의 패널은 프로젝트 패널 하나라
///   Dock 이 열려 있으면 활성이다.
fn project_panel_toggle_tooltip(dock_open: bool) -> Spec {
    if dock_open {
        Spec::one(
            "status-btn-project-panel",
            Line::action("Close Left Dock", "workspace::ToggleLeftDock"),
        )
    } else {
        Spec::one(
            "status-btn-project-panel",
            Line::action("Project Panel", "project_panel::ToggleFocus"),
        )
    }
}

#[cfg(test)]
mod tests {
    // Explicit imports: `super::*` would pull in gpui's `test` macro through `gpui_kit::*`.
    use super::{TabPress, TabText, tab_drop_left, tab_press, tab_text};
    use gpui_kit::MouseButton;

    /// I-063, I-066, I-075, L-74: a left press activates, a double press promotes, a middle click closes a normal
    /// tab and is ignored on a pinned one; other buttons do nothing.
    #[test]
    fn tab_press_follows_i063_i066_i075() {
        assert_eq!(tab_press(MouseButton::Left, 1, false), TabPress::Activate);
        assert_eq!(tab_press(MouseButton::Left, 2, false), TabPress::Promote);
        assert_eq!(tab_press(MouseButton::Left, 3, true), TabPress::Promote);
        assert_eq!(tab_press(MouseButton::Middle, 1, false), TabPress::Close);
        assert_eq!(tab_press(MouseButton::Middle, 1, true), TabPress::Ignore);
        assert_eq!(tab_press(MouseButton::Right, 1, false), TabPress::Ignore);
    }

    /// L-306, L-314: only a Markdown preview tab dims with the pane's focus.
    #[test]
    fn tab_text_follows_l306() {
        for focused in [true, false] {
            assert_eq!(tab_text(false, true, focused), TabText::Text);
            assert_eq!(tab_text(false, false, focused), TabText::Muted);
        }
        assert_eq!(tab_text(true, true, true), TabText::Text);
        assert_eq!(tab_text(true, false, true), TabText::Muted);
        assert_eq!(tab_text(true, true, false), TabText::Muted);
        assert_eq!(tab_text(true, false, false), TabText::Hidden);
    }

    /// I-715: the line is on the left when the dragged tab starts after the target (or in another pane), else right.
    #[test]
    fn tab_drop_line_side_follows_drag_start() {
        assert!(tab_drop_left(0, 3, 0, 1));
        assert!(!tab_drop_left(0, 1, 0, 3));
        assert!(!tab_drop_left(0, 2, 0, 2));
        assert!(tab_drop_left(1, 0, 0, 5));
    }
}

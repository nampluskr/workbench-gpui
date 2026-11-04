//! 레이아웃 뼈대 (PLAN Phase 3, SPEC R-12~R-14, DECISIONS D-10 이후 변경).
//!
//! 01-zed L-11~L-16 배치(왼쪽 사이드바 → Workspace[타이틀 바 → 본문(왼쪽 Dock → 가운데 Pane) → 상태 표시줄])의
//! 각 영역을 그린다. 내용이 없는 자리(폴더 줄, 탭, 프로젝트 패널, 활성 아이템)는 치수 확인용 자리 표시 요소다.
//! 아이콘은 gpui-kit 기본 아이콘 묶음에서 가까운 것을 임시로 쓴다(Zed 아이콘 테마는 PoC 7단계 범위).
//! 색은 gpui-kit 기본 테마 토큰이다(테마 매핑 G-106 은 v0.1 범위 밖).

use gpui_kit::component::{ActiveTheme as _, Icon, IconName, h_flex, v_flex};
use gpui_kit::*;

use gpui_kit::prelude::FluentBuilder as _;

use super::layout_probe::{self, probe};
use super::metrics::*;
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
                            IconName::PanelLeft,
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
                            IconName::Folder,
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
    icon: IconName,
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
        .child(Icon::new(icon).size(ICON_SMALL))
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

/// 탭 하나의 표시 값(Phase 4 최소 탭, R-27).
pub struct TabView {
    pub title: SharedString,
    /// 임시 탭이면 제목 기울임(I-064, L-68).
    pub preview: bool,
    pub active: bool,
    /// 수정됨이면 시작 슬롯에 점(L-65).
    pub dirty: bool,
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
        row = row.child(
            div()
                .flex_shrink_0()
                .h_full()
                .group(SharedString::from(format!("tab-{i}")))
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
                        .when(!tab.active, |d| d.text_color(theme.muted_foreground))
                        .child(
                            div()
                                .flex()
                                .flex_shrink_0()
                                .items_center()
                                .justify_center()
                                .size(TAB_START_SLOT)
                                // shortcut: Accent approximated by the theme primary; conflict (Warning) arrives with P3-4.
                                .when(tab.dirty, |d| d.child(div().size(TAB_INDICATOR_SIZE).rounded_full().bg(theme.primary))),
                        )
                        .child(div().whitespace_nowrap().when(tab.preview, |d| d.italic()).child(tab.title.clone()))
                        .child(close_slot(i, tab, cx)),
                ),
        );
    }
    row.into_any_element()
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
        .child(Icon::new(IconName::Close).size(ICON_SMALL))
}

pub fn tab_bar(tabs: &[TabView], cx: &App) -> impl IntoElement {
    let theme = cx.theme();
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
                    IconName::ArrowLeft,
                    Some(Spec::one("tab-btn-back", Line::action("Go Back", "pane::GoBack"))),
                    cx,
                ))
                .child(icon_with_probe(
                    "tab-btn-forward",
                    &["tab-icon-forward"],
                    IconName::ArrowRight,
                    Some(Spec::one("tab-btn-forward", Line::action("Go Forward", "pane::GoForward"))),
                    cx,
                )),
        )
        .child(
            // 활성 탭: 아래 테두리 대신 1px 여백을 두어 내용 높이 31 을 남긴다. 탭이 없으면 자리 표시.
            tab_list(tabs, cx),
        )
        .child(
            div()
                .flex_1()
                .h_full()
                .border_b_1()
                .border_color(theme.border),
        )
        .child(
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
                    IconName::Plus,
                    Some(Spec::one("tab-btn-new", Line::text("New…"))),
                    cx,
                ))
                .child(icon_with_probe(
                    "tab-btn-split",
                    &["tab-icon-split"],
                    IconName::PanelRight,
                    Some(Spec::one("tab-btn-split", Line::text("Split Pane"))),
                    cx,
                ))
                .child(icon_with_probe(
                    "tab-btn-zoom",
                    &["tab-icon-zoom"],
                    IconName::Maximize,
                    Some(Spec::one("tab-btn-zoom", Line::action("Zoom In", "workspace::ToggleZoom"))),
                    cx,
                )),
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
                IconName::FolderOpen,
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
                        IconName::PanelLeft,
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
                        IconName::Folder,
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

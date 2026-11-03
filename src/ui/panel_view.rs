//! 프로젝트 패널 트리 그리기 (v0.2 Phase 4, SPEC R-17·R-19, L-36~L-49, P-019~P-021, L-247).
//!
//! gpui-base `Tree`(gpui-component tree 의 바탕, TreeState 가상화)로 행을 그린다(D-8). 행 내용은 우리 것이다:
//! - L-36 행 높이 26 = 안쪽 24 + 위아래 테두리 1. L-48 테두리 1 + 오른쪽 2, 평소 배경색(안 보임),
//!   패널에 키보드 포커스가 있고 그 행이 활성이면 포커스 테두리 색.
//! - L-37 들여쓰기 = 깊이 × 20(안쪽 margin-left), 안쪽 좌우 padding 6, gap 4. L-40 아이콘 16.
//! - L-38 안내선: 폭 1, x = 깊이 × 20 + 15, 구간 첫 행 위·끝 행 아래 4 여백.
//! - L-43 접힌 경로: 조각마다 따로 hover(좌우 padding 2), 구분자 `\`. 조각을 누르면 그 단계를 고른다.
//! - L-44 폴더는 화살표 없이 열림·닫힘 아이콘. L-49·L-247 이름 툴팁: 절대 경로(홈은 `~`), 1500ms.
//! - 누르기는 행 안에서 받아 전파를 멈춘다: TreeState 의 "누르면 선택·펼침 토글"과 자기 포커스 옮기기를 쓰지 않는다.

use std::cell::RefCell;
use std::collections::HashMap;
use std::path::PathBuf;
use std::rc::Rc;

use gpui_kit::base::Tree;
use gpui_kit::component::input::Input;
use gpui_kit::component::{ActiveTheme as _, Icon, IconName, h_flex};
use gpui_kit::prelude::FluentBuilder as _;
use gpui_kit::*;

use super::Workbench;
use super::layout_probe;
use super::panel_nav::RowPress;
use super::project_panel::EditKind;
use super::metrics::project_panel::*;
use super::rem::rems_from_px;
use super::tooltip::{self, Line, Spec};
use crate::fsops::names::Validation;
use crate::fsops::tree::Row;

/// P1-3: row height must equal the spec value (rem constant converted to logical px).
// `use gpui_kit::*` shadows `#[test]` with gpui's macro, so the std one is named explicitly.
#[cfg(test)]
#[core::prelude::v1::test]
fn row_height_matches_spec() {
    super::metrics::spec::assert_spec(
        "project_panel[\"item.height\"]",
        "project_panel_comfortable",
        ROW_HEIGHT.0 * super::rem::BASE_REM_PX,
    );
}

thread_local! {
    static NAMES: RefCell<HashMap<String, &'static str>> = RefCell::new(HashMap::new());
}

/// 탐침 이름(dev 전용, 한 번 만들어 계속 쓴다).
fn name(s: String) -> &'static str {
    NAMES.with(|m| *m.borrow_mut().entry(s.clone()).or_insert_with(|| Box::leak(s.into_boxed_str())))
}

fn names(list: Vec<String>) -> &'static [&'static str] {
    let key = list.join("|");
    thread_local! {
        static LISTS: RefCell<HashMap<String, &'static [&'static str]>> = RefCell::new(HashMap::new());
    }
    LISTS.with(|m| {
        *m.borrow_mut()
            .entry(key)
            .or_insert_with(|| Box::leak(list.into_iter().map(name).collect::<Vec<_>>().into_boxed_slice()))
    })
}

/// 행 하나를 그릴 때 쓰는 값(프레임마다 Workbench 가 만든다).
#[derive(Clone)]
struct RowView {
    row: Row,
    selected: bool,
    marked: bool,
    /// 키보드 포커스 테두리(L-48).
    focused: bool,
    /// 선택된 조각(접힌 경로).
    active_segment: Option<PathBuf>,
    /// 이 행이 입력칸이면 (입력, 검증).
    edit: Option<(Entity<gpui_kit::component::input::InputState>, Option<Validation>)>,
    tooltip: String,
}

/// 행 색(테마 매핑 G-106 전이라 gpui-kit 기본 테마의 가까운 토큰. 색은 판정 대상이 아니다).
#[derive(Clone, Copy)]
struct Colors {

    hover: Hsla,
    selected: Hsla,
    focus: Hsla,
    guide: Hsla,
    fg: Hsla,
    warning: Hsla,
    error: Hsla,
    banner_bg: Hsla,
}

impl Workbench {
    /// 활성 폴더의 트리. 빈 공간(마지막 행 아래)을 우클릭하면 루트 메뉴(I-559).
    pub(super) fn render_tree(
        &mut self,
        ws: &Entity<super::folders::FolderWorkspace>,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) -> AnyElement {
        let panel_focused = self.panel_focus.is_focused(window);
        let home = dirs::home_dir();
        let (views, state, bounds_store) = {
            let t = &ws.read(cx).tree;
            let edit = t.edit.as_ref().map(|e| (e.input.clone(), e.validation.clone(), e.kind.clone()));
            let views: Vec<RowView> = t
                .rows
                .iter()
                .map(|row| {
                    let selected = row.new_entry.is_none() && t.selected.as_deref().is_some_and(|p| row.covers(p));
                    let marked = row.new_entry.is_none() && row.segments.iter().any(|(_, p)| t.marked.contains(p));
                    let row_edit = match &edit {
                        Some((input, v, EditKind::New { .. })) if row.new_entry.is_some() => Some((input.clone(), v.clone())),
                        Some((input, v, EditKind::Rename { path })) if row.new_entry.is_none() && row.path == *path => {
                            Some((input.clone(), v.clone()))
                        }
                        _ => None,
                    };
                    RowView {
                        row: row.clone(),
                        selected,
                        marked,
                        focused: panel_focused && selected,
                        active_segment: (row.segments.len() > 1).then(|| t.selected.clone()).flatten(),
                        edit: row_edit,
                        tooltip: crate::fsops::paths::tooltip(&row.path, home.as_deref()),
                    }
                })
                .collect();
            (Rc::new(views), t.state.clone(), t.row_bounds.clone())
        };
        let theme = cx.theme();
        let colors = Colors {

            hover: theme.list_hover,
            selected: theme.list_active,
            focus: theme.ring,
            guide: theme.border,
            fg: theme.foreground,
            warning: theme.warning,
            error: theme.danger,
            banner_bg: theme.background,
        };
        let scroll = state.read(cx).scroll_handle().clone();
        let weak = cx.entity().downgrade();
        let tree = Tree::new(&state)
            .item(move |ix, _entry, _state, window, cx| match views.get(ix) {
                Some(v) => render_row(ix, v, &weak, colors, &bounds_store, window, cx),
                None => div().into_any_element(),
            })
            .list_style(StyleRefinement::default().size_full())
            .size_full();
        let weak = cx.entity().downgrade();
        use gpui_kit::component::scroll::ScrollableElement as _;
        div()
            .id("project-tree")
            .size_full()
            .on_mouse_down(
                MouseButton::Right,
                move |e: &MouseDownEvent, window, cx| {
                    let pos = e.position;
                    let _ = weak.update(cx, |this, cx| this.open_panel_menu(None, pos, window, cx));
                },
            )
            .child(tree)
            .vertical_scrollbar(&scroll)
            .into_any_element()
    }
}

/// 행 누르기 처리기를 붙인다. 전파를 멈춰 TreeState 의 기본 누르기(선택·펼침 토글·자기 포커스)가 돌지 않게 한다.
fn with_press<E: InteractiveElement>(el: E, path: PathBuf, weak: &WeakEntity<Workbench>) -> E {
    let (w1, w2, w3, w4) = (weak.clone(), weak.clone(), weak.clone(), weak.clone());
    let (p1, p2, p3, p4) = (path.clone(), path.clone(), path.clone(), path);
    el.on_mouse_down(MouseButton::Left, move |_: &MouseDownEvent, window, cx| {
        window.prevent_default();
        cx.stop_propagation();
        let _ = w1.update(cx, |this, cx| {
            this.panel_focus.focus(window, cx);
            this.pending_press = Some(p1.clone());
        });
    })
    .on_mouse_up(MouseButton::Left, move |e: &MouseUpEvent, window, cx| {
        cx.stop_propagation();
        let _ = w2.update(cx, |this, cx| {
            if this.pending_press.take().as_ref() == Some(&p2) {
                let press = RowPress {
                    path: p2.clone(),
                    button: MouseButton::Left,
                    click_count: e.click_count,
                    modifiers: e.modifiers,
                    position: e.position,
                };
                this.on_row_press(press, window, cx);
            }
        });
    })
    .on_mouse_down(MouseButton::Right, move |e: &MouseDownEvent, window, cx| {
        window.prevent_default();
        cx.stop_propagation();
        let press = RowPress { path: p3.clone(), button: MouseButton::Right, click_count: 1, modifiers: e.modifiers, position: e.position };
        let _ = w3.update(cx, |this, cx| {
            this.panel_focus.focus(window, cx);
            this.on_row_press(press, window, cx);
        });
    })
    .on_mouse_down(MouseButton::Middle, move |e: &MouseDownEvent, window, cx| {
        window.prevent_default();
        cx.stop_propagation();
        let press = RowPress { path: p4.clone(), button: MouseButton::Middle, click_count: 1, modifiers: e.modifiers, position: e.position };
        let _ = w4.update(cx, |this, cx| {
            this.panel_focus.focus(window, cx);
            this.on_row_press(press, window, cx);
        });
    })
}

fn icon_for(row: &Row) -> IconName {
    if row.new_entry == Some(true) || (row.is_dir && !row.expanded) {
        IconName::FolderClosed
    } else if row.is_dir {
        IconName::FolderOpen
    } else {
        IconName::File
    }
}

fn render_row(
    ix: usize,
    v: &RowView,
    weak: &WeakEntity<Workbench>,
    c: Colors,
    bounds_store: &Rc<RefCell<HashMap<usize, Bounds<Pixels>>>>,
    window: &mut Window,
    _cx: &mut App,
) -> AnyElement {
    let row = &v.row;
    let nn = format!("{ix:02}");
    let (icon_name, label_name) = if ix == 0 {
        ("project-root-icon".to_string(), "project-root-label".to_string())
    } else {
        (format!("tree-icon-{nn}"), format!("tree-label-{nn}"))
    };
    let inner_names = names(vec![icon_name, label_name]);
    let input_focused = v.edit.as_ref().is_some_and(|(i, _)| i.read(_cx).focus_handle(_cx).is_focused(window));

    // 이름 자리: 입력칸, 접힌 경로 조각, 또는 이름.
    let label: AnyElement = if let Some((input, _)) = &v.edit {
        div().flex_1().min_w_0().h(INPUT_HEIGHT).child(Input::new(input).appearance(false).h(INPUT_HEIGHT)).into_any_element()
    } else if row.segments.len() > 1 {
        let mut seg_row = h_flex().whitespace_nowrap();
        for (si, (seg_name, seg_path)) in row.segments.iter().enumerate() {
            if si > 0 {
                seg_row = seg_row.child(div().child("\\"));
            }
            let active = v.active_segment.as_ref() == Some(seg_path);
            let seg = div()
                .id(("tree-seg", ix * 64 + si))
                .px(SEGMENT_PAD_X)
                .rounded(SEGMENT_RADIUS)
                .when(active, |d| d.underline())
                .hover(move |s| s.bg(c.hover))
                .child(seg_name.clone());
            seg_row = seg_row.child(with_press(seg, seg_path.clone(), weak));
        }
        seg_row.into_any_element()
    } else {
        div().whitespace_nowrap().child(row.label()).into_any_element()
    };

    let inner = h_flex()
        .on_children_prepainted(layout_probe::probe(inner_names))
        .h_full()
        .ml(rems_from_px(row.depth as f32 * INDENT))
        .px(ROW_PAD_X)
        .gap(ROW_GAP)
        .items_center()
        .child(Icon::new(icon_for(row)).size(ICON).flex_shrink_0())
        .child(label);

    let highlighted = v.selected || v.marked;
    let border = match (&v.edit, input_focused) {
        (Some((_, Some(Validation::Error(_)))), true) => c.error,
        (Some((_, Some(Validation::Warning(_)))), true) => c.warning,
        (Some(_), true) => c.focus,
        (Some(_), false) => transparent_black(),
        (None, _) if v.focused => c.focus,
        _ => transparent_black(),
    };
    let mut content = div()
        .id(("tree-row", ix))
        .w_full()
        .h(ROW_HEIGHT)
        .border_1()
        .border_r_2()
        .border_color(border)
        .text_size(super::metrics::TEXT_SIZE_DEFAULT)
        .text_color(c.fg)
        .when(highlighted, |d| d.bg(c.selected))
        .when(!highlighted, |d| d.hover(move |s| s.bg(c.hover)))
        .child(inner);
    if v.edit.is_none() {
        content = content
            .tooltip(tooltip::build(Spec::one("tree-item", Line::text(v.tooltip.clone()))))
            .tooltip_show_delay(NAME_TOOLTIP_DELAY);
        content = with_press(content, row.path.clone(), weak);
    } else {
        // 입력칸 행: 입력칸이 스스로 포커스를 잡는다. 전파만 멈춰 TreeState 가 펼침을 토글하지 않게 한다.
        content = content.on_mouse_down(MouseButton::Left, |_: &MouseDownEvent, _, cx| cx.stop_propagation());
    }

    let mut wrapper_names = vec![format!("tree-content-{nn}")];
    let mut wrapper = div().relative().w_full().h(ROW_HEIGHT).child(content);
    for g in &row.guides {
        wrapper_names.push(format!("tree-guide-{nn}-{}", g.depth));
        wrapper = wrapper.child(
            div()
                .absolute()
                .left(rems_from_px(g.depth as f32 * INDENT + GUIDE_OFFSET))
                .w(GUIDE_WIDTH)
                .top(if g.first { GUIDE_INSET } else { Rems(0.) })
                .bottom(if g.last { GUIDE_INSET } else { Rems(0.) })
                .bg(c.guide),
        );
    }
    // P-021 검증 배너: 입력 행 바로 아래에 겹쳐 띄운다(왼쪽 −1, 오른쪽 −0.5).
    if let Some((_, Some(val))) = &v.edit {
        let color = match val {
            Validation::Error(_) => c.error,
            Validation::Warning(_) => c.warning,
        };
        wrapper_names.push(format!("tree-banner-{nn}"));
        wrapper = wrapper.child(
            deferred(
                div()
                    .absolute()
                    .top(ROW_HEIGHT)
                    .left(BANNER_OFFSET_LEFT)
                    .right(BANNER_OFFSET_RIGHT)
                    .py(BANNER_PAD_Y)
                    .px(BANNER_PAD_X)
                    .border_1()
                    .border_color(color)
                    .bg(c.banner_bg)
                    .text_size(BANNER_TEXT)
                    .text_color(color)
                    .child(val.text().to_string()),
            )
            .with_priority(1),
        );
    }
    let wrapper = wrapper.on_children_prepainted(layout_probe::probe(names(wrapper_names)));
    let probe = layout_probe::probe(names(vec![format!("tree-row-{nn}")]));
    let store = bounds_store.clone();
    div()
        .on_children_prepainted(move |bounds: Vec<Bounds<Pixels>>, window: &mut Window, cx: &mut App| {
            if let Some(b) = bounds.first() {
                store.borrow_mut().insert(ix, *b);
            }
            probe(bounds, window, cx);
        })
        .w_full()
        .child(wrapper)
        .into_any_element()
}

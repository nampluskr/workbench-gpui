//! 우클릭 메뉴 (v0.2 Phase 3, SPEC R-9·R-14, I-667·I-934~I-940, A-12.10).
//!
//! ☰ 앱 메뉴(app_menu)와 같은 치수(I-504~I-512)로 그린다: 최소 폭 200, 최대 높이 창 75%, 목록 위아래 4,
//! 항목 바깥 4·안 6, 라벨 14px·줄 높이 1.618, 구분선 1px·위아래 6, 모서리 8, `elevation_2`, 창 가장자리 여유 8.
//! 누른 자리(마우스 위치)에 연다. 단축키 열은 없다(R-14 "단축키는 없다").
//!
//! 키(`menu` 컨텍스트, I-516·I-517): 다음/이전/처음/끝(비활성 항목은 건너뛴다), Enter 실행, Escape·Ctrl-C 닫기.
//! 닫힘(I-519): 메뉴 밖 누름, Escape, 실행 뒤, 포커스 잃음. Escape·실행이면 원래 포커스를 돌려준다(I-309).
//! 고른 항목은 `ContextMenuEvent::Chosen(번호)` 로 알린다. 닫히면 `Dismissed`.

use gpui_kit::component::{ActiveTheme as _, h_flex, v_flex};
use gpui_kit::prelude::FluentBuilder as _;
use gpui_kit::*;

use super::app_menu::{
    LIST_PAD_Y, MAX_HEIGHT_RATIO, MIN_WIDTH, RADIUS, ROW_LINE_HEIGHT, ROW_MARGIN_X, ROW_PAD_X,
    ROW_TEXT, SEPARATOR_MARGIN_Y, WINDOW_MARGIN,
};
use super::keymap::{self, menu as menu_actions};
use super::layout_probe::{self, probe};
use super::rem::rems_from_px;
use super::tooltip;

#[derive(Clone, Debug)]
pub enum CmEntry {
    Item { label: &'static str, enabled: bool },
    Separator,
}

pub enum ContextMenuEvent {
    Chosen(usize),
    Dismissed,
}

impl EventEmitter<ContextMenuEvent> for ContextMenu {}

const ROW_PROBES: [&str; 6] = [
    "ctx-menu-row-0",
    "ctx-menu-row-1",
    "ctx-menu-row-2",
    "ctx-menu-row-3",
    "ctx-menu-row-4",
    "ctx-menu-row-5",
];

pub struct ContextMenu {
    entries: Vec<CmEntry>,
    position: Point<Pixels>,
    focus: FocusHandle,
    selected: Option<usize>,
    prev_focus: Option<FocusHandle>,
    closed: bool,
    _blur: Subscription,
}

impl ContextMenu {
    /// `position` 에 연다. 포커스를 메뉴로 옮기고, 지금 포커스를 기억한다.
    pub fn new(
        entries: Vec<CmEntry>,
        position: Point<Pixels>,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) -> Self {
        let focus = cx.focus_handle();
        let blur = cx.on_blur(&focus, window, |this, window, cx| {
            this.close("blur", false, window, cx);
        });
        let prev_focus = window.focused(cx);
        focus.focus(window, cx);
        if keymap::dev_enabled(cx) {
            let rows: Vec<String> = entries
                .iter()
                .map(|e| match e {
                    CmEntry::Item { label, enabled } => {
                        format!("{label}|{}", if *enabled { "enabled" } else { "disabled" })
                    }
                    CmEntry::Separator => "---".into(),
                })
                .collect();
            println!("[dev] context-menu-open rows={}", rows.join("\t"));
        }
        Self {
            entries,
            position,
            focus,
            selected: None,
            prev_focus,
            closed: false,
            _blur: blur,
        }
    }

    fn close(&mut self, reason: &str, restore: bool, window: &mut Window, cx: &mut Context<Self>) {
        if self.closed {
            return;
        }
        self.closed = true;
        layout_probe::forget("ctx-menu-");
        if restore && let Some(prev) = self.prev_focus.take() {
            prev.focus(window, cx);
        }
        if keymap::dev_enabled(cx) {
            println!("[dev] context-menu-close reason={reason}");
        }
        cx.emit(ContextMenuEvent::Dismissed);
        cx.notify();
    }

    fn enabled_indices(&self) -> Vec<usize> {
        self.entries
            .iter()
            .enumerate()
            .filter(|(_, e)| matches!(e, CmEntry::Item { enabled: true, .. }))
            .map(|(i, _)| i)
            .collect()
    }

    fn step(&mut self, forward: bool, cx: &mut Context<Self>) {
        let items = self.enabled_indices();
        if items.is_empty() {
            return;
        }
        let n = items.len();
        let next = match self.selected.and_then(|s| items.iter().position(|i| *i == s)) {
            None if forward => items[0],
            None => items[n - 1],
            Some(p) => items[if forward { (p + 1) % n } else { (p + n - 1) % n }],
        };
        self.selected = Some(next);
        cx.notify();
    }

    fn execute(&mut self, index: usize, via: &str, window: &mut Window, cx: &mut Context<Self>) {
        let Some(CmEntry::Item { label, enabled: true }) = self.entries.get(index).cloned() else {
            return;
        };
        if keymap::dev_enabled(cx) {
            println!("[dev] context-menu-exec item={label} via={via}");
        }
        self.close("execute", true, window, cx);
        cx.emit(ContextMenuEvent::Chosen(index));
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
        self.selected = self.enabled_indices().first().copied();
        cx.notify();
    }

    fn on_select_last(&mut self, _: &menu_actions::SelectLast, _: &mut Window, cx: &mut Context<Self>) {
        self.selected = self.enabled_indices().last().copied();
        cx.notify();
    }

    fn on_cancel(&mut self, _: &menu_actions::Cancel, window: &mut Window, cx: &mut Context<Self>) {
        self.close("cancel", true, window, cx);
    }

    fn on_confirm(&mut self, _: &menu_actions::Confirm, window: &mut Window, cx: &mut Context<Self>) {
        if let Some(i) = self.selected {
            self.execute(i, "enter", window, cx);
        }
    }
}

impl Render for ContextMenu {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        if self.closed {
            return div().into_any_element();
        }
        let theme = cx.theme();
        let border = theme.border;
        let disabled_fg = theme.muted_foreground;
        let selected_bg = theme.secondary_hover;
        let bg = theme.popover;
        let fg = theme.popover_foreground;
        let shadow = tooltip::elevation_2_shadow(theme.is_dark());
        let max_height = window.viewport_size().height * MAX_HEIGHT_RATIO;

        let mut list = v_flex()
            .on_children_prepainted(probe(&ROW_PROBES))
            .id("ctx-menu-list")
            .min_w(MIN_WIDTH)
            .py(LIST_PAD_Y)
            .max_h(max_height)
            .overflow_y_scroll();
        for (i, entry) in self.entries.clone().into_iter().enumerate() {
            match entry {
                CmEntry::Separator => {
                    list = list.child(div().my(SEPARATOR_MARGIN_Y).h(px(1.)).w_full().bg(border));
                }
                CmEntry::Item { label, enabled } => {
                    let selected = enabled && self.selected == Some(i);
                    list = list.child(
                        h_flex()
                            .id(("ctx-menu-row", i))
                            .mx(ROW_MARGIN_X)
                            .px(ROW_PAD_X)
                            .rounded(rems_from_px(4.))
                            .text_size(ROW_TEXT)
                            .line_height(relative(ROW_LINE_HEIGHT))
                            .when(!enabled, |row| row.text_color(disabled_fg))
                            .when(selected, |row| row.bg(selected_bg))
                            .when(enabled, |row| {
                                row.on_hover(cx.listener(move |this, hovered: &bool, _, cx| {
                                    if *hovered && this.selected != Some(i) {
                                        this.selected = Some(i);
                                        cx.notify();
                                    }
                                }))
                                .on_click(cx.listener(move |this, _, window, cx| {
                                    this.execute(i, "click", window, cx);
                                }))
                            })
                            .child(div().whitespace_nowrap().child(label)),
                    );
                }
            }
        }

        let popup = div()
            .key_context(crate::keymap::builtin::MENU_CONTEXT)
            .track_focus(&self.focus)
            .on_action(cx.listener(Self::on_select_next))
            .on_action(cx.listener(Self::on_select_previous))
            .on_action(cx.listener(Self::on_select_first))
            .on_action(cx.listener(Self::on_select_last))
            .on_action(cx.listener(Self::on_cancel))
            .on_action(cx.listener(Self::on_confirm))
            .on_mouse_down_out(cx.listener(|this, _: &MouseDownEvent, window, cx| {
                this.close("click-outside", false, window, cx);
            }))
            .occlude()
            .bg(bg)
            .text_color(fg)
            .border_1()
            .border_color(border)
            .rounded(RADIUS)
            .shadow(shadow)
            .child(list);

        deferred(
            anchored()
                .position(self.position)
                .snap_to_window_with_margin(WINDOW_MARGIN)
                .child(div().on_children_prepainted(probe(&["ctx-menu-box"])).child(popup)),
        )
        .with_priority(1)
        .into_any_element()
    }
}

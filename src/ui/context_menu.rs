//! 우클릭 메뉴 (v0.2 Phase 3, SPEC R-9·R-14, I-667·I-934~I-940, A-12.10).
//!
//! ☰ 앱 메뉴(app_menu)와 같은 치수(I-504~I-512)로 그린다: 최소 폭 200, 최대 높이 창 75%, 목록 위아래 4,
//! 항목 바깥 4·안 6, 라벨 14px·줄 높이 1.618, 구분선 1px·위아래 6, 모서리 8, `elevation_2`, 창 가장자리 여유 8.
//! 누른 자리(마우스 위치)에 연다. 단축키 열은 없다(R-14 "단축키는 없다").
//!
//! 키(`menu` 컨텍스트, I-516·I-517): 다음/이전/처음/끝(비활성 항목은 건너뛴다), Enter 실행, Escape·Ctrl-C 닫기.
//! 닫힘(I-519): 메뉴 밖 누름, Escape, 실행 뒤, 포커스 잃음. Escape·실행이면 원래 포커스를 돌려준다(I-309).
//! 고른 항목은 `ContextMenuEvent::Chosen(번호)` 로 알린다. 닫히면 `Dismissed`.

use gpui_kit::component::{ActiveTheme as _, v_flex};
use gpui_kit::prelude::FluentBuilder as _;
use gpui_kit::*;

use crate::dev::now_ms;
use super::metrics::menu::{CHORD_TIMEOUT, MAX_HEIGHT_RATIO, SHORTCUT_FLASH, WINDOW_MARGIN};
use super::keymap::{self, menu as menu_actions};
use super::layout_probe::{self, probe};
use super::menu_common::{self, Chord, Feed};

#[derive(Clone, Debug)]
pub enum CmEntry {
    Item { label: SharedString, enabled: bool, shortcut: Option<SharedString> },
    Separator,
}

impl CmEntry {
    pub fn item(label: impl Into<SharedString>, enabled: bool) -> Self {
        CmEntry::Item { label: label.into(), enabled, shortcut: None }
    }

    /// 단축키 열이 있는 항목(프로젝트 패널 메뉴, I-509·I-530~I-557).
    pub fn with_shortcut(label: impl Into<SharedString>, enabled: bool, shortcut: Option<String>) -> Self {
        CmEntry::Item { label: label.into(), enabled, shortcut: shortcut.map(Into::into) }
    }
}

pub enum ContextMenuEvent {
    Chosen(usize),
    Dismissed,
}

impl EventEmitter<ContextMenuEvent> for ContextMenu {}

/// 목록 자식(구분선 포함) 순서대로의 탐침 이름. 프로젝트 패널 폴더 메뉴가 가장 길다(구분선 포함 27줄).
const ROW_PROBES: [&str; 28] = [
    "ctx-menu-row-0", "ctx-menu-row-1", "ctx-menu-row-2", "ctx-menu-row-3", "ctx-menu-row-4",
    "ctx-menu-row-5", "ctx-menu-row-6", "ctx-menu-row-7", "ctx-menu-row-8", "ctx-menu-row-9",
    "ctx-menu-row-10", "ctx-menu-row-11", "ctx-menu-row-12", "ctx-menu-row-13", "ctx-menu-row-14",
    "ctx-menu-row-15", "ctx-menu-row-16", "ctx-menu-row-17", "ctx-menu-row-18", "ctx-menu-row-19",
    "ctx-menu-row-20", "ctx-menu-row-21", "ctx-menu-row-22", "ctx-menu-row-23", "ctx-menu-row-24",
    "ctx-menu-row-25", "ctx-menu-row-26", "ctx-menu-row-27",
];

// Shortcut flash (I-520) and chord timeout live in `metrics::menu`.
// Both values are shared with the app menu.

pub struct ContextMenu {
    entries: Vec<CmEntry>,
    /// 항목마다 단축키를 해석할 액션 이름(I-520). 비어 있으면 단축키 실행이 없다(사이드바 메뉴, R-14).
    actions: Vec<Option<&'static str>>,
    position: Point<Pixels>,
    focus: FocusHandle,
    selected: Option<usize>,
    prev_focus: Option<FocusHandle>,
    closed: bool,
    /// I-520 예약(항목 번호, 세대). 50ms 뒤 세대가 같고 메뉴가 열려 있을 때만 실행한다(☰ 메뉴 D-032·D-033 과 같은 방식).
    pending: Option<(usize, u64)>,
    generation: u64,
    /// 메뉴가 열린 채 받은 chord 앞 키들과 대기 token.
    chord: Chord,
    /// 메뉴를 열기 직전 포커스의 컨텍스트 스택(항목 단축키는 이 자리에서 해석한다, 11.2절 머리말·I-307).
    prev_stack: Vec<KeyContext>,
    _intercept: Option<Subscription>,
    _blur: Subscription,
}

impl ContextMenu {
    /// `position` 에 연다. 포커스를 메뉴로 옮기고, 지금 포커스를 기억한다.
    /// `actions` 는 항목마다 단축키 해석용 액션 이름이다(없으면 빈 Vec).
    pub fn new(
        entries: Vec<CmEntry>,
        actions: Vec<Option<&'static str>>,
        position: Point<Pixels>,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) -> Self {
        let focus = cx.focus_handle();
        let blur = cx.on_blur(&focus, window, |this, window, cx| {
            if this.pending.is_none() {
                this.close("blur", false, window, cx);
            }
        });
        let prev_focus = window.focused(cx);
        // 메뉴로 포커스를 옮기기 전 자리의 컨텍스트 스택.
        let prev_stack = window.context_stack();
        let intercept = actions.iter().any(Option::is_some).then(|| {
            let weak = cx.entity().downgrade();
            cx.intercept_keystrokes(move |event, window, cx| {
                let consumed = weak.update(cx, |this, cx| this.intercept(event, window, cx)).unwrap_or(false);
                if consumed {
                    cx.stop_propagation();
                }
            })
        });
        focus.focus(window, cx);
        if keymap::dev_enabled(cx) {
            let rows: Vec<String> = entries
                .iter()
                .map(|e| match e {
                    CmEntry::Item { label, enabled, shortcut } => {
                        let state = if *enabled { "enabled" } else { "disabled" };
                        match shortcut {
                            Some(s) => format!("{label}|{state}|{s}"),
                            None => format!("{label}|{state}"),
                        }
                    }
                    CmEntry::Separator => "---".into(),
                })
                .collect();
            println!("[dev] context-menu-open rows={}", rows.join("\t"));
        }
        Self {
            entries,
            actions,
            position,
            focus,
            selected: None,
            prev_focus,
            closed: false,
            pending: None,
            generation: 0,
            chord: Chord::default(),
            prev_stack,
            _intercept: intercept,
            _blur: blur,
        }
    }

    fn close(&mut self, reason: &str, restore: bool, window: &mut Window, cx: &mut Context<Self>) {
        if self.closed {
            return;
        }
        self.closed = true;
        self.cancel_pending();
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
        let Some(CmEntry::Item { label, enabled: true, .. }) = self.entries.get(index).cloned() else {
            return;
        };
        if keymap::dev_enabled(cx) {
            println!("[dev] context-menu-exec item={label} via={via} t_ms={}", now_ms());
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
        let muted = theme.muted_foreground;
        let selected_bg = theme.secondary_hover;
        let max_height = window.viewport_size().height * MAX_HEIGHT_RATIO;

        let mut list = menu_common::list(
            v_flex().on_children_prepainted(probe(&ROW_PROBES)),
            "ctx-menu-list",
            max_height,
        );
        for (i, entry) in self.entries.clone().into_iter().enumerate() {
            match entry {
                CmEntry::Separator => {
                    list = list.child(menu_common::separator(border));
                }
                CmEntry::Item { label, enabled, shortcut } => {
                    let selected = enabled && self.selected == Some(i);
                    list = list.child(
                        menu_common::row(("ctx-menu-row", i))
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
                            .child(div().whitespace_nowrap().child(label))
                            // I-509 라벨과 단축키는 양끝 정렬, 단축키 앞 여백 16.
                            .when_some(shortcut, |row, s| {
                                row.child(
                                    menu_common::shortcut_cell()
                                        .when(enabled, |d| d.text_color(muted))
                                        .child(s),
                                )
                            }),
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
            }));
        let popup = menu_common::popup_surface(popup, cx).child(list);

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

/// I-520: 메뉴가 열린 채 항목의 단축키를 누르면 그 항목을 선택 표시하고 50ms 뒤 닫고 실행한다(☰ 메뉴와 같은 방식, R-9).
impl ContextMenu {
    fn dev(&self, cx: &App) -> bool {
        keymap::dev_enabled(cx)
    }

    /// 예약을 지우고 세대를 올린다. 이미 걸린 50ms 타이머는 세대가 달라 아무것도 하지 않는다.
    fn cancel_pending(&mut self) {
        self.pending = None;
        self.chord.clear();
        self.generation += 1;
    }

    /// 액션 이름이 `name` 인 켜진 항목의 번호.
    fn item_index(&self, name: &str) -> Option<usize> {
        self.actions.iter().enumerate().find_map(|(i, a)| {
            let enabled = matches!(self.entries.get(i), Some(CmEntry::Item { enabled: true, .. }));
            (enabled && *a == Some(name)).then_some(i)
        })
    }

    fn schedule_item(&mut self, index: usize, window: &mut Window, cx: &mut Context<Self>) {
        self.cancel_pending();
        let generation = self.generation;
        self.pending = Some((index, generation));
        self.selected = Some(index);
        cx.notify();
        if self.dev(cx) {
            println!("[dev] context-menu-shortcut index={index} action={} t_ms={}", self.actions[index].unwrap_or(""), now_ms());
        }
        cx.spawn_in(window, async move |this, cx| {
            cx.background_executor().timer(SHORTCUT_FLASH).await;
            let _ = this.update_in(cx, |this, window, cx| {
                if this.closed || !matches!(this.pending, Some((_, g)) if g == generation) {
                    return;
                }
                if let Some((index, _)) = this.pending.take() {
                    this.execute(index, "shortcut", window, cx);
                }
            });
        })
        .detach();
    }

    /// 메뉴를 열기 직전 자리의 컨텍스트 스택으로 접두를 푼다. 그 액션이 켜진 항목이면 예약한다.
    fn replay_prefix(&mut self, prefix: &[Keystroke], window: &mut Window, cx: &mut Context<Self>) {
        if let Some(name) = menu_common::prefix_action(&self.prev_stack, prefix, cx)
            && let Some(index) = self.item_index(name)
        {
            self.schedule_item(index, window, cx);
        }
    }

    fn start_chord_timeout(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let token = self.chord.wait();
        cx.spawn_in(window, async move |this, cx| {
            cx.background_executor().timer(CHORD_TIMEOUT).await;
            let _ = this.update_in(cx, |this, window, cx| {
                if !this.closed
                    && let Some(prefix) = this.chord.take_expired(token)
                {
                    this.replay_prefix(&prefix, window, cx);
                }
            });
        })
        .detach();
    }

    /// 열린 동안 키 입력을 디스패치 전에 본다. 소비하면 true.
    /// 1. chord 대기가 아니고 메뉴 자리에서 `menu::` 액션으로 풀리는 키(위·아래·Enter·Escape·Ctrl-C 등, I-517)는 건드리지 않는다.
    /// 2. 아니면 열기 직전 자리의 스택으로 풀어, 접두면 기다리고(1초), 켜진 항목의 액션이면 그 항목을 예약한다.
    /// 3. 항목이 아닌 액션이나 바인딩 없음은 보통 디스패치에 맡긴다.
    fn intercept(&mut self, event: &KeystrokeEvent, window: &mut Window, cx: &mut Context<Self>) -> bool {
        if self.closed {
            return false;
        }
        if self.chord.is_list_key(event, cx, |name| name.starts_with("menu::")) {
            return false;
        }
        match self.chord.feed(&event.keystroke, &self.prev_stack, cx) {
            Feed::Wait => {
                self.start_chord_timeout(window, cx);
                true
            }
            Feed::Action { name, chord } => {
                if let Some(index) = self.item_index(name) {
                    self.schedule_item(index, window, cx);
                    return true;
                }
                chord
            }
            Feed::Replay(prefix) => {
                self.replay_prefix(&prefix, window, cx);
                self.intercept(event, window, cx)
            }
            Feed::Pass => false,
        }
    }
}

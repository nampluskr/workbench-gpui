//! Styling shared by the app menu and the context menu (AUDIT 8).
//!
//! Only the identical row/popup base lives here; enabled state, events, focus and probe ids stay in each menu.

use gpui_kit::component::{ActiveTheme as _, h_flex};
use gpui_kit::*;

use super::metrics::menu::{
    LIST_PAD_Y, MIN_WIDTH, RADIUS, ROW_LINE_HEIGHT, ROW_MARGIN_X, ROW_PAD_X, ROW_RADIUS, ROW_TEXT,
    SEPARATOR_HEIGHT, SEPARATOR_MARGIN_Y, SHORTCUT_GAP,
};
use super::tooltip;

/// Scrolling list base. The caller sets its probe on the `v_flex` before the id is applied.
pub fn list(probed: Div, id: &'static str, max_height: Pixels) -> Stateful<Div> {
    probed
        .id(id)
        .min_w(MIN_WIDTH)
        .py(LIST_PAD_Y)
        .max_h(max_height)
        .overflow_y_scroll()
}

pub fn separator(border: Hsla) -> Div {
    div().my(SEPARATOR_MARGIN_Y).h(SEPARATOR_HEIGHT).w_full().bg(border)
}

/// Row base; the caller adds disabled/selected colors, hover and click.
pub fn row(id: impl Into<ElementId>) -> Stateful<Div> {
    h_flex()
        .id(id)
        .mx(ROW_MARGIN_X)
        .px(ROW_PAD_X)
        .rounded(ROW_RADIUS)
        .justify_between()
        .text_size(ROW_TEXT)
        .line_height(relative(ROW_LINE_HEIGHT))
}

/// Shortcut column cell; the caller sets its text color.
pub fn shortcut_cell() -> Div {
    div().flex_shrink_0().ml(SHORTCUT_GAP)
}

/// Popup surface applied after the menu's own key context, focus and action handlers.
pub fn popup_surface(popup: Div, cx: &App) -> Div {
    let theme = cx.theme();
    popup
        .occlude()
        .bg(theme.popover)
        .text_color(theme.popover_foreground)
        .border_1()
        .border_color(theme.border)
        .rounded(RADIUS)
        .shadow(tooltip::elevation_2_shadow(theme.is_dark()))
}

/// Result of feeding one keystroke to a [`Chord`].
pub enum Feed {
    /// Nothing matched and nothing was waiting: let normal dispatch handle it.
    Pass,
    /// A longer binding may follow: the key was kept and the caller starts the timeout.
    Wait,
    /// The input resolved to `name`. `chord` is true when more than one key was involved.
    Action { name: &'static str, chord: bool },
    /// The waiting keys did not continue: the caller replays them, then feeds the current key again.
    Replay(Vec<Keystroke>),
}

/// Pending chord prefix and its timeout token (D-032·D-033). Execution stays with each menu.
#[derive(Default)]
pub struct Chord {
    input: Vec<Keystroke>,
    token: u64,
}

impl Chord {
    pub fn clear(&mut self) {
        self.input.clear();
    }

    /// Starts a new wait and returns its token; an older timer then no longer matches.
    pub fn wait(&mut self) -> u64 {
        self.token += 1;
        self.token
    }

    /// The waiting keys when the timer for `token` is still the latest and keys are waiting.
    pub fn take_expired(&mut self, token: u64) -> Option<Vec<Keystroke>> {
        (self.token == token && !self.input.is_empty()).then(|| std::mem::take(&mut self.input))
    }

    /// True when no chord is waiting and the key resolves, in the menu's own context, to a list key
    /// (`is_list_key` on the action name), which the menu must not touch (I-517).
    pub fn is_list_key(&self, event: &KeystrokeEvent, cx: &App, is_list_key: impl Fn(&str) -> bool) -> bool {
        if !self.input.is_empty() {
            return false;
        }
        let keymap = cx.key_bindings();
        let keymap = keymap.borrow();
        let (bindings, _) = keymap.bindings_for_input(std::slice::from_ref(&event.keystroke), &event.context_stack);
        bindings.first().is_some_and(|b| is_list_key(b.action().name()))
    }

    /// Resolves the waiting keys plus `keystroke` in the context stack the menu was opened from.
    pub fn feed(&mut self, keystroke: &Keystroke, stack: &[KeyContext], cx: &App) -> Feed {
        let mut input = self.input.clone();
        input.push(keystroke.clone());
        let (first, pending) = resolve(stack, &input, cx);
        if pending {
            self.input = input;
            return Feed::Wait;
        }
        if let Some(name) = first {
            self.input.clear();
            return Feed::Action { name, chord: input.len() > 1 };
        }
        if !self.input.is_empty() {
            return Feed::Replay(std::mem::take(&mut self.input));
        }
        Feed::Pass
    }
}

/// (winning action name, whether a longer binding may follow) — gpui `Keymap::bindings_for_input`.
fn resolve(stack: &[KeyContext], input: &[Keystroke], cx: &App) -> (Option<&'static str>, bool) {
    let keymap = cx.key_bindings();
    let keymap = keymap.borrow();
    let (bindings, pending) = keymap.bindings_for_input(input, stack);
    (bindings.first().map(|b| b.action().name()), pending)
}

/// Same as gpui's prefix confirmation: the longest leading part of `prefix` that resolves wins.
pub fn prefix_action(stack: &[KeyContext], prefix: &[Keystroke], cx: &App) -> Option<&'static str> {
    (1..=prefix.len()).rev().find_map(|len| resolve(stack, &prefix[..len], cx).0)
}

#[cfg(test)]
mod tests {
    use super::Chord;

    #[test]
    fn late_timer_does_not_end_a_newer_wait() {
        let mut chord = Chord::default();
        chord.input.push(gpui_kit::Keystroke::parse("ctrl-k").unwrap());
        let old = chord.wait();
        let new = chord.wait();
        assert!(chord.take_expired(old).is_none());
        assert!(!chord.input.is_empty());
        assert_eq!(chord.take_expired(new).map(|k| k.len()), Some(1));
        assert!(chord.take_expired(new).is_none());
    }
}

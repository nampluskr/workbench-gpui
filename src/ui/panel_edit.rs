//! 프로젝트 패널 인라인 입력칸: 새 파일·새 폴더·이름 변경 (v0.2 Phase 4, SPEC R-19, I-091·I-092·P-019~P-022).

use std::path::{Path, PathBuf};

use gpui_kit::component::input::{InputEvent, InputState};
use gpui_kit::*;

use super::Workbench;
use super::keymap::{self, project_panel as pp};
use super::project_panel::{EditKind, EditState};
use crate::fsops::{names, ops};

impl Workbench {
    pub(super) fn on_new_file(&mut self, a: &pp::NewFile, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.start_new(false, w, cx);
    }

    pub(super) fn on_new_dir(&mut self, a: &pp::NewDirectory, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.start_new(true, w, cx);
    }

    pub(super) fn on_rename(&mut self, a: &pp::Rename, w: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(w, cx), cx);
        self.start_rename(w, cx);
    }

    /// P-019 새 항목: 대상 폴더(선택이 폴더면 그것, 파일이면 그 부모, 없으면 루트)를 펼치고 빈 입력칸에 포커스.
    pub(super) fn start_new(&mut self, is_dir: bool, window: &mut Window, cx: &mut Context<Self>) {
        let Some(ws) = self.active_ws() else { return };
        if ws.read(cx).tree.edit.is_some() {
            return;
        }
        let (dir, was_expanded, prev) = {
            let t = &ws.read(cx).tree;
            let dir = match &t.selected {
                Some(p) if p.is_dir() => p.clone(),
                Some(p) => p.parent().map(Path::to_path_buf).unwrap_or_else(|| t.root.clone()),
                None => t.root.clone(),
            };
            (dir.clone(), t.expanded.contains(&dir), t.selected.clone())
        };
        let input = self.make_input("", None, window, cx);
        let subs = self.input_subscriptions(&input, window, cx);
        ws.update(cx, |ws, cx| {
            let t = &mut ws.tree;
            t.expanded.insert(dir.clone());
            t.edit = Some(EditState {
                kind: EditKind::New { dir: dir.clone(), is_dir },
                input: input.clone(),
                validation: None,
                prev_selected: prev,
                temp_expanded: (!was_expanded).then(|| dir.clone()),
                _subs: subs,
            });
            t.rebuild(cx);
            if let Some(ix) = t.rows.iter().position(|r| r.new_entry.is_some()) {
                t.scroll_to(ix, cx);
            }
        });
        input.update(cx, |s, cx| s.focus(window, cx));
        self.log_edit("start", cx);
        self.log_tree(cx);
        cx.notify();
    }

    /// P-019 이름 변경: 기존 이름을 채우고 파일은 확장자를 뺀 이름만, 폴더는 전체를 고른다. 루트는 하지 않는다(I-091).
    pub(super) fn start_rename(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let Some(ws) = self.active_ws() else { return };
        let (path, prev) = {
            let t = &ws.read(cx).tree;
            if t.edit.is_some() {
                return;
            }
            let Some(sel) = t.selected.clone() else { return };
            if t.is_root(&sel) {
                if keymap::dev_enabled(cx) {
                    println!("[dev] rename-skipped reason=root");
                }
                return;
            }
            (sel.clone(), Some(sel))
        };
        let name = path.file_name().map(|n| n.to_string_lossy().into_owned()).unwrap_or_default();
        let select = if path.is_dir() {
            0..name.len()
        } else {
            match name.rfind('.') {
                Some(i) if i > 0 => 0..i,
                _ => 0..name.len(),
            }
        };
        let input = self.make_input(&name, Some(select), window, cx);
        let subs = self.input_subscriptions(&input, window, cx);
        ws.update(cx, |ws, cx| {
            ws.tree.edit = Some(EditState {
                kind: EditKind::Rename { path: path.clone() },
                input: input.clone(),
                validation: None,
                prev_selected: prev,
                temp_expanded: None,
                _subs: subs,
            });
            ws.tree.rebuild(cx);
        });
        input.update(cx, |s, cx| s.focus(window, cx));
        self.log_edit("start", cx);
        cx.notify();
    }
}

impl Workbench {
    fn make_input(
        &mut self,
        value: &str,
        select: Option<std::ops::Range<usize>>,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) -> Entity<InputState> {
        let input = cx.new(|cx| InputState::new(window, cx));
        input.update(cx, |s, cx| {
            s.set_value(value, window, cx);
            if let Some(r) = select {
                s.set_selected_range(r, cx);
            }
        });
        input
    }

    fn input_subscriptions(
        &mut self,
        input: &Entity<InputState>,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) -> Vec<Subscription> {
        vec![cx.subscribe_in(input, window, |this, input, event: &InputEvent, window, cx| {
            let current = this
                .active_ws()
                .is_some_and(|ws| ws.read(cx).tree.edit.as_ref().is_some_and(|e| e.input == *input));
            if !current {
                return;
            }
            match event {
                InputEvent::Change => this.revalidate(cx),
                InputEvent::PressEnter { .. } => this.commit_edit(false, window, cx),
                // P-022 포커스 잃음: 창이 활성일 때만 확정을 시도한다.
                InputEvent::Blur if window.is_window_active() => this.commit_edit(true, window, cx),
                _ => {}
            }
        })]
    }

    /// P-021 입력할 때마다 검증.
    fn revalidate(&mut self, cx: &mut Context<Self>) {
        let Some(ws) = self.active_ws() else { return };
        ws.update(cx, |ws, cx| {
            let Some(edit) = ws.tree.edit.as_mut() else { return };
            let value = edit.input.read(cx).value().to_string();
            edit.validation = match &edit.kind {
                EditKind::New { dir, .. } => names::validate(&value, dir, true, None),
                EditKind::Rename { path } => {
                    let parent = path.parent().unwrap_or(path);
                    names::validate(&value, parent, false, Some(path))
                }
            };
        });
        self.log_edit("change", cx);
        cx.notify();
    }

    /// dev 출력: 입력칸 상태(값·선택 범위·검증).
    pub(super) fn log_edit(&self, what: &str, cx: &App) {
        // 시험 훅(D-047): 입력 확정·취소 때 UI 스레드를 잠시 멈춘다(`--dev-ui-stall edit-committed|edit-cancelled <ms>`).
        crate::dev::ui_stall(&format!("edit-{what}"));
        if !keymap::dev_enabled(cx) {
            return;
        }
        let Some(ws) = self.active_ws() else { return };
        let t = &ws.read(cx).tree;
        let Some(edit) = t.edit.as_ref() else {
            println!("[dev] edit what={what} active=false");
            return;
        };
        let state = edit.input.read(cx);
        let value = state.value().to_string();
        let sel = state.selected_range();
        let (kind, target) = match &edit.kind {
            EditKind::New { dir, is_dir } => (if *is_dir { "new-dir" } else { "new-file" }, t.rel(dir)),
            EditKind::Rename { path } => ("rename", t.rel(path)),
        };
        let (vkind, vtext) = match &edit.validation {
            Some(names::Validation::Warning(s)) => ("warning", s.as_str()),
            Some(names::Validation::Error(s)) => ("error", s.as_str()),
            None => ("none", ""),
        };
        println!(
            "[dev] edit what={what} active=true kind={kind} target={target} value={value:?} selected={}..{} selected_text={:?} validation={vkind} text={vtext:?}",
            sel.start,
            sel.end,
            value.get(sel.clone()).unwrap_or("")
        );
    }
}

/// 확정 시도 결과.
enum Outcome {
    /// 입력칸을 연 채 둔다(P-022 거부 ①·②).
    Keep,
    /// 편집을 버린다(포커스 잃음 때 거부, P-022).
    Cancel,
    /// 끝냈다: 고를 경로, 열 파일.
    Done { select: PathBuf, open: Option<PathBuf>, focus_panel: bool },
}

impl Workbench {
    /// P-022 Enter·포커스 잃음 확정.
    pub(super) fn commit_edit(&mut self, from_blur: bool, window: &mut Window, cx: &mut Context<Self>) {
        let Some(ws) = self.active_ws() else { return };
        let Some((kind, value)) = ws
            .read(cx)
            .tree
            .edit
            .as_ref()
            .map(|e| (e.kind.clone(), e.input.read(cx).value().to_string()))
        else {
            return;
        };
        let reject = if from_blur { Outcome::Cancel } else { Outcome::Keep };
        let outcome = match &kind {
            EditKind::New { dir, is_dir } => match names::confirm(&value, true, *is_dir) {
                None => reject,
                Some(c) => {
                    let target = c.path_under(dir);
                    // D-043 ①: 디스크 호출 직전에 대상이 실제로 그 폴더(와 등록 루트) 안인지 한 번 더 본다.
                    let root = ws.read(cx).tree.root.clone();
                    let inside = ops::is_within_real(&target, dir) && ops::is_within_real(&target, &root);
                    if !inside {
                        self.log_fs("create-refused-outside", &[&target], None, cx);
                        reject
                    } else if target.symlink_metadata().is_ok() {
                        reject
                    } else {
                        let result = if c.is_dir { ops::create_dir(&target) } else { ops::create_file(&target) };
                        self.log_fs("create", &[&target], result.as_ref().err().map(|e| e.to_string()), cx);
                        match result {
                            // I-097 auto_open.on_create: 만든 파일을 연다.
                            Ok(()) => Outcome::Done {
                                select: target.clone(),
                                open: (!c.is_dir).then_some(target),
                                focus_panel: c.is_dir,
                            },
                            Err(_) => reject,
                        }
                    }
                }
            },
            EditKind::Rename { path } => match names::confirm(&value, false, false) {
                None => reject,
                Some(c) => {
                    let parent = path.parent().unwrap_or(path).to_path_buf();
                    let target = c.path_under(&parent);
                    let same_name = target == *path;
                    if same_name {
                        // P-022: 자기 자신과 같은 이름이면 편집만 끝내고 패널로 포커스.
                        Outcome::Done { select: path.clone(), open: None, focus_panel: true }
                    } else if !ops::is_direct_child(&target, &parent) {
                        // D-043 ①: 이름 변경 대상은 원래 부모 폴더 바로 아래여야 한다.
                        self.log_fs("rename-refused-outside", &[path, &target], None, cx);
                        reject
                    } else if target.symlink_metadata().is_ok() && !names::same_path(&target, path) {
                        reject
                    } else {
                        let result = ops::rename(path, &target);
                        self.log_fs("rename", &[path, &target], result.as_ref().err().map(|e| e.to_string()), cx);
                        match result {
                            Ok(()) => {
                                let (from, to) = (path.clone(), target.clone());
                                self.apply_move(&from, &to, cx);
                                Outcome::Done { select: target, open: None, focus_panel: true }
                            }
                            Err(_) => reject,
                        }
                    }
                }
            },
        };
        match outcome {
            Outcome::Keep => {
                self.revalidate(cx);
                self.log_edit("rejected", cx);
            }
            Outcome::Cancel => self.cancel_edit(false, window, cx),
            Outcome::Done { select, open, focus_panel } => {
                ws.update(cx, |ws, cx| {
                    let t = &mut ws.tree;
                    t.edit = None;
                    // 이름을 바꾼 폴더의 펼침 상태를 새 경로로 옮긴다.
                    if let EditKind::Rename { path } = &kind {
                        let moved: Vec<PathBuf> = t.expanded.iter().filter(|p| p.starts_with(path)).cloned().collect();
                        for p in moved {
                            t.expanded.remove(&p);
                            if let Ok(rest) = p.strip_prefix(path) {
                                t.expanded.insert(select.join(rest));
                            }
                        }
                    }
                    t.refresh(cx);
                    t.select_only(Some(select.clone()));
                });
                self.log_edit("committed", cx);
                if focus_panel && !from_blur {
                    self.panel_focus.focus(window, cx);
                }
                if let Some(file) = open {
                    self.open_file(&file, false, !from_blur, "create", window, cx);
                } else {
                    self.reveal(&select, cx);
                }
                self.log_tabs(cx);
                self.log_tree(cx);
                cx.notify();
            }
        }
    }

    /// P-022 Escape(또는 포커스 잃음 때 거부): 편집을 버리고 임시로 펼친 폴더를 접고 이전 선택으로. Escape 면 패널에 포커스.
    pub(super) fn cancel_edit(&mut self, focus_panel: bool, window: &mut Window, cx: &mut Context<Self>) {
        let Some(ws) = self.active_ws() else { return };
        if ws.read(cx).tree.edit.is_none() {
            return;
        }
        ws.update(cx, |ws, cx| {
            let t = &mut ws.tree;
            if let Some(edit) = t.edit.take() {
                if let Some(dir) = edit.temp_expanded {
                    t.expanded.remove(&dir);
                }
                t.select_only(edit.prev_selected);
            }
            t.rebuild(cx);
        });
        self.log_edit("cancelled", cx);
        if focus_panel {
            self.panel_focus.focus(window, cx);
        }
        self.log_tree(cx);
        cx.notify();
    }

    /// 입력칸의 Escape(입력칸이 처리하지 않고 넘긴 것)·패널의 `menu::Cancel`.
    pub(super) fn on_input_escape(
        &mut self,
        _: &gpui_kit::component::input::Escape,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        if self.panel_editing(cx) {
            self.cancel_edit(true, window, cx);
        } else {
            cx.propagate();
        }
    }

    pub(super) fn on_panel_cancel(&mut self, a: &keymap::menu::Cancel, window: &mut Window, cx: &mut Context<Self>) {
        keymap::log_handled(a, self.focus_name(window, cx), cx);
        if self.panel_editing(cx) {
            self.cancel_edit(true, window, cx);
        }
    }
}

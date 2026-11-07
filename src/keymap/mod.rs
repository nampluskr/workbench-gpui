//! 키맵의 gpui 와 무관한 부분 (v0.2 Phase 1, SPEC R-1~R-4).
//!
//! - `builtin`: 앱 내장 키맵 표(D-2). 01-zed 02-INTERACTION 1절 키 표의 적용 결과에서 v0.2 동작만 골라 다시 적었다.
//! - `file`: 사용자 `keymap.json`(JSONC, D-4) 읽기와 오류 문구(D-14 이후 변경).
//! - `display`: 메뉴·툴팁 단축키 표시 문자열(L-217~L-221).
//!
//! gpui 키 엔진에 묶는 일은 `ui::keymap` 이 한다(D-5: gpui-kit 의존은 ui 안에 둔다).

pub mod builtin;
pub mod display;
pub mod file;

/// 우리 앱에 있는 액션 이름 전체(A-20.4 "우리 앱에 있는 액션 이름만"). `ui::keymap` 의 `actions!` 정의와 같아야 한다.
///
/// `(이름, 우리가 지었나)`. 두 번째 값이 true 면 01-zed·02-gpui 에 이름이 없어 우리가 지은 이름이다(D-2 이후 변경, D-027 ②).
pub const ACTIONS: &[(&str, bool)] = &[
    ("input::Undo", false),
    ("input::Redo", false),
    ("workspace::ToggleLeftDock", false),
    ("workspace::Open", false),
    ("workspace::CopyPath", false),
    ("workspace::CopyRelativePath", false),
    ("workspace::CloseWindow", false),
    ("workspace::Save", false),
    ("workspace::UseClassicLayout", false),
    ("zed::OpenSettings", false),
    ("zed::OpenKeymap", false),
    ("zed::Extensions", false),
    ("keymap_editor::EditJson", true),
    ("keymap_editor::Create", true),
    ("pane::CloseActiveItem", false),
    ("pane::ActivatePreviousItem", false),
    ("pane::ActivateNextItem", false),
    ("pane::TogglePinTab", false),
    ("markdown::OpenPreview", false),
    ("markdown::OpenPreviewToTheSide", false),
    ("pane::SplitRight", false),
    ("pane::SplitLeft", false),
    ("pane::SplitUp", false),
    ("pane::SplitDown", false),
    ("workspace::ToggleZoom", false),
    ("workspace::ActivatePaneLeft", false),
    ("workspace::ActivatePaneRight", false),
    ("workspace::ActivatePaneUp", false),
    ("workspace::ActivatePaneDown", false),
    ("zed::Quit", false),
    ("zed::Minimize", false),
    ("zed::Zoom", false),
    ("multi_workspace::ToggleWorkspaceSidebar", false),
    ("multi_workspace::FocusWorkspaceSidebar", false),
    ("app_menu::Toggle", true),
    ("project_panel::ToggleFocus", false),
    ("project_panel::CollapseSelectedEntry", true),
    ("project_panel::ExpandSelectedEntry", true),
    ("project_panel::CollapseAllEntries", true),
    ("project_panel::ExpandAllEntries", true),
    ("project_panel::Open", true),
    ("project_panel::Rename", false),
    ("project_panel::NewFile", false),
    ("project_panel::NewDirectory", false),
    ("project_panel::Copy", false),
    ("project_panel::Cut", false),
    ("project_panel::Paste", false),
    ("project_panel::Trash", false),
    ("project_panel::Delete", false),
    ("project_panel::DeployContextMenu", true),
    ("project_panel::SelectPreviousExtend", true),
    ("project_panel::SelectNextExtend", true),
    ("project_panel::RemoveFromProject", false),
    ("project_panel::RevealInFileManager", false),
    ("project_panel::OpenWithSystem", false),
    ("menu::SelectNext", true),
    ("menu::SelectPrevious", true),
    ("menu::SelectFirst", true),
    ("menu::SelectLast", true),
    ("menu::Confirm", false),
    ("menu::Cancel", true),
    ("menu::SelectChild", true),
    ("menu::SelectParent", true),
];

/// 우리 앱 액션 이름인가.
pub fn is_known_action(name: &str) -> bool {
    ACTIONS.iter().any(|(n, _)| *n == name)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn builtin_uses_only_known_actions() {
        for b in builtin::BUILTIN {
            assert!(is_known_action(b.action), "{}", b.action);
        }
    }

    #[test]
    fn k10_tab_cycle_keys_match_tauri() {
        for (keys, action) in [
            ("ctrl-pageup", "pane::ActivatePreviousItem"),
            ("ctrl-pagedown", "pane::ActivateNextItem"),
        ] {
            let binding = builtin::BUILTIN.iter().find(|binding| binding.keys == keys).unwrap();
            assert_eq!((binding.context, binding.action), (builtin::PANE_CONTEXT, action));
            assert!(is_known_action(action));
        }
    }

    #[test]
    fn k11_settings_and_layout_actions_registered() {
        let binding = builtin::BUILTIN.iter().find(|binding| binding.keys == "ctrl-,").unwrap();
        assert_eq!((binding.context, binding.action), ("", "zed::OpenSettings"));
        assert!(is_known_action(binding.action));
        assert!(is_known_action("workspace::UseClassicLayout"));
    }

    /// P4-23b-R1 (I-731, I-065): pin and split keys apply inside the Pane context only; the Workspace chords stay.
    #[test]
    fn pane_keys_are_pane_context_only() {
        let context = |keys: &str| builtin::BUILTIN.iter().find(|b| b.keys == keys).map(|b| b.context);
        for keys in ["ctrl-k shift-enter", "ctrl-\\", "ctrl-k up", "ctrl-k down", "ctrl-k left", "ctrl-k right"] {
            assert_eq!(context(keys), Some(builtin::PANE_CONTEXT), "{keys}");
        }
        assert_eq!(context("ctrl-k ctrl-o"), Some(builtin::WORKSPACE_CONTEXT));
        assert_eq!(context("shift-escape"), Some(builtin::WORKSPACE_CONTEXT));
        assert_eq!(context("ctrl-k ctrl-left"), Some(builtin::WORKSPACE_CONTEXT));
        let project_panel = builtin::BUILTIN.iter().find(|b| b.keys == "ctrl-k ctrl-shift-c").map(|b| b.context);
        assert_eq!(project_panel, Some(builtin::PROJECT_PANEL_CONTEXT));
    }

    #[test]
    fn k12_menu_keys_keep_zed_first_key_for_display() {
        for (action, context, keys) in [
            ("input::Undo", "Input", vec!["ctrl-z"]),
            ("input::Redo", "Input", vec!["ctrl-shift-z", "ctrl-y"]),
            ("pane::CloseActiveItem", "Workspace", vec!["ctrl-f4", "ctrl-w"]),
            ("pane::SplitRight", "Pane", vec!["ctrl-k right", "ctrl-\\"]),
            ("workspace::Save", "Workspace", vec!["ctrl-s"]),
            ("pane::ActivatePreviousItem", "Pane", vec!["ctrl-pageup"]),
            ("pane::ActivateNextItem", "Pane", vec!["ctrl-pagedown"]),
        ] {
            let bindings: Vec<_> = builtin::BUILTIN.iter().filter(|b| b.action == action).collect();
            assert!(bindings.iter().all(|b| b.context == context), "{action}");
            assert_eq!(bindings.iter().map(|b| b.keys).collect::<Vec<_>>(), keys, "{action}");
        }
    }

    #[test]
    fn action_names_unique() {
        let mut names: Vec<_> = ACTIONS.iter().map(|(n, _)| *n).collect();
        names.sort();
        let len = names.len();
        names.dedup();
        assert_eq!(len, names.len());
    }
}

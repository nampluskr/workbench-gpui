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
    ("workspace::ToggleLeftDock", false),
    ("workspace::Open", false),
    ("workspace::CopyPath", false),
    ("workspace::CopyRelativePath", false),
    ("workspace::CloseWindow", false),
    ("workspace::Save", false),
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
    fn action_names_unique() {
        let mut names: Vec<_> = ACTIONS.iter().map(|(n, _)| *n).collect();
        names.sort();
        let len = names.len();
        names.dedup();
        assert_eq!(len, names.len());
    }
}

//! 앱 내장 키맵 (D-2, SPEC R-1).
//!
//! 01-zed 02-INTERACTION 1절 키 표(Windows 기본 → VSCode 덧씌움 → specific-overrides 적용 결과, I-001·I-700)와
//! 04-APP-SPEC A-13.1·A-17 에서 v0.2 에 있는 동작의 키만 골라 우리 말로 다시 적었다. Zed 키맵 JSON 은 옮기지 않았다
//! (zed-like-editor README 3절).
//!
//! 키 표기는 gpui `Keystroke::parse` 형식이다(수식키-키, chord 는 공백).
//! 등록 순서가 곧 같은 깊이에서의 우선순위다(나중 것이 이긴다, I-702). 그래서 `menu` 묶음을 먼저 두고
//! `ProjectPanel` 묶음을 뒤에 둔다. 프로젝트 패널 요소는 `ProjectPanel` 과 `menu` 를 함께 컨텍스트로 가지므로
//! (I-002, I-030 "ProjectPanel + menu") Ctrl-N·Ctrl-C·Enter·Left·Right 는 패널 쪽 바인딩이 이긴다.

/// 내장 바인딩 한 줄.
pub struct Builtin {
    /// gpui 키 표기. 예: `ctrl-k ctrl-o`.
    pub keys: &'static str,
    /// 컨텍스트 조건식(gpui `KeyBindingContextPredicate` 문법).
    pub context: &'static str,
    /// 액션 이름(`super::ACTIONS` 안의 이름).
    pub action: &'static str,
    /// 근거 ID.
    pub source: &'static str,
}

const fn b(
    keys: &'static str,
    context: &'static str,
    action: &'static str,
    source: &'static str,
) -> Builtin {
    Builtin {
        keys,
        context,
        action,
        source,
    }
}

/// 사이드바 컨텍스트 이름 (D-3 이후 변경, D-027 ④).
pub const SIDEBAR_CONTEXT: &str = "Sidebar";
/// 프로젝트 패널 컨텍스트 이름 (I-002).
pub const PROJECT_PANEL_CONTEXT: &str = "ProjectPanel";
/// 메뉴 컨텍스트 이름 (I-516).
pub const MENU_CONTEXT: &str = "menu";
/// 작업 영역 컨텍스트 이름 (I-022~I-024 의 컨텍스트 열).
pub const WORKSPACE_CONTEXT: &str = "Workspace";
/// 이름 편집 중이 아님 (I-033 "이름 편집 중 아님").
pub const NOT_EDITING: &str = "not_editing";

pub const BUILTIN: &[Builtin] = &[
    // 메뉴 (I-516, I-517). 프로젝트 패널의 위·아래·처음·끝(I-030)과 이름 입력 확정·취소(I-035)도 이 묶음이 맡는다.
    b("down", "menu", "menu::SelectNext", "I-517, I-030"),
    b("tab", "menu", "menu::SelectNext", "I-517, I-030"),
    b("ctrl-n", "menu", "menu::SelectNext", "I-517"),
    b("up", "menu", "menu::SelectPrevious", "I-517, I-030"),
    b("shift-tab", "menu", "menu::SelectPrevious", "I-517, I-030"),
    b("ctrl-p", "menu", "menu::SelectPrevious", "I-517"),
    b("home", "menu", "menu::SelectFirst", "I-517, I-030"),
    b("pageup", "menu", "menu::SelectFirst", "I-517"),
    b("shift-pageup", "menu", "menu::SelectFirst", "I-517"),
    b("end", "menu", "menu::SelectLast", "I-517, I-030"),
    b("pagedown", "menu", "menu::SelectLast", "I-517"),
    b("shift-pagedown", "menu", "menu::SelectLast", "I-517"),
    b("enter", "menu", "menu::Confirm", "I-517, I-035"),
    b("escape", "menu", "menu::Cancel", "I-517, I-035"),
    b("ctrl-c", "menu", "menu::Cancel", "I-517"),
    b("right", "menu", "menu::SelectChild", "I-517"),
    b("left", "menu", "menu::SelectParent", "I-517"),
    // 창·작업 영역 (I-022~I-024, I-310, A-13.1, A-17.1·A-17.2·A-17.6~A-17.8).
    b("ctrl-b", "Workspace", "workspace::ToggleLeftDock", "I-022, A-17.7"),
    b("ctrl-shift-e", "Workspace", "project_panel::ToggleFocus", "I-023, A-17.8"),
    b("ctrl-alt-j", "Workspace", "multi_workspace::ToggleWorkspaceSidebar", "I-024, A-17.1"),
    b("ctrl-alt-;", "Workspace", "multi_workspace::FocusWorkspaceSidebar", "I-024, A-17.2"),
    b("ctrl-k ctrl-o", "Workspace", "workspace::Open", "A-13.1, A-17.6"),
    b("f10", "Workspace", "app_menu::Toggle", "I-310"),
    // 사이드바 (A-17.3~A-17.5). 컨텍스트 이름은 D-027 ④.
    b("up", "Sidebar", "menu::SelectPrevious", "A-17.3"),
    b("down", "Sidebar", "menu::SelectNext", "A-17.3"),
    b("enter", "Sidebar", "menu::Confirm", "A-17.4"),
    b("delete", "Sidebar", "project_panel::RemoveFromProject", "A-17.5"),
    // 프로젝트 패널 (I-031~I-037, I-039~I-043. I-038 은 제외).
    b("left", "ProjectPanel", "project_panel::CollapseSelectedEntry", "I-031"),
    b("right", "ProjectPanel", "project_panel::ExpandSelectedEntry", "I-031"),
    b("ctrl-left", "ProjectPanel", "project_panel::CollapseAllEntries", "I-032"),
    b("ctrl-right", "ProjectPanel", "project_panel::ExpandAllEntries", "I-032"),
    b("space", "ProjectPanel && not_editing", "project_panel::Open", "I-033"),
    b("enter", "ProjectPanel", "project_panel::Rename", "I-034"),
    b("f2", "ProjectPanel", "project_panel::Rename", "I-034"),
    b("ctrl-n", "ProjectPanel", "project_panel::NewFile", "I-036"),
    b("alt-n", "ProjectPanel", "project_panel::NewDirectory", "I-036"),
    b("ctrl-c", "ProjectPanel", "project_panel::Copy", "I-037"),
    b("ctrl-insert", "ProjectPanel", "project_panel::Copy", "I-037"),
    b("ctrl-x", "ProjectPanel", "project_panel::Cut", "I-037"),
    b("ctrl-v", "ProjectPanel", "project_panel::Paste", "I-037"),
    b("shift-insert", "ProjectPanel", "project_panel::Paste", "I-037"),
    b("delete", "ProjectPanel", "project_panel::Trash", "I-039"),
    b("backspace", "ProjectPanel", "project_panel::Trash", "I-039"),
    b("shift-delete", "ProjectPanel", "project_panel::Delete", "I-040"),
    b("ctrl-delete", "ProjectPanel", "project_panel::Delete", "I-040"),
    b("ctrl-backspace", "ProjectPanel", "project_panel::Delete", "I-040"),
    b("alt-shift-c", "ProjectPanel", "workspace::CopyPath", "I-041"),
    b("ctrl-k ctrl-shift-c", "ProjectPanel", "workspace::CopyRelativePath", "I-041"),
    b("menu", "ProjectPanel", "project_panel::DeployContextMenu", "I-042"),
    b("shift-f10", "ProjectPanel", "project_panel::DeployContextMenu", "I-042"),
    b("shift-up", "ProjectPanel", "project_panel::SelectPreviousExtend", "I-043"),
    b("shift-down", "ProjectPanel", "project_panel::SelectNextExtend", "I-043"),
];

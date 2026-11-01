# R-5 대조표: 화면 단축키 / 키맵 적용 결과 (v0.2 Phase 2)

생성: tools/verify-v02-phase2.ps1, 2026-11-02 01:53.

- **화면**: 앱이 그린 단축키 글자(`[dev] tooltip-shown rows=`, `[dev] menu-render rows=`). `<none>` 은 단축키 없이 제목만(L-223).
- **키맵 적용 결과**: 같은 실행의 `[dev] display seq=<최신> where=center` 줄(gpui `highest_precedence_binding_for_action_in`, I-704: 가려진 키 제외, 남은 것 중 마지막, L-219~L-221 형식). 메뉴는 메뉴를 열기 직전 포커스(가운데 Pane)의 컨텍스트, 툴팁은 지금 포커스(가운데 Pane)의 컨텍스트다(I-307, L-201).
- **01-zed 원문**: 02 8.2절·9.2절의 키 열. v0.2 에 그 동작이 없는 항목은 키맵에 바인딩이 없어 화면에 단축키가 없다(R-7 설명).

| 사례 | 위치 | 문구 | 액션 | 화면 | 키맵 적용 결과 | 01-zed 원문 | 판정 | 증거 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| tooltip | 툴팁 app-menu-button | Open Application Menu | `` | `<none>` | `<none>` | 없음 (F10, 표시 안 함 L-225) | 일치 | r7-app-menu-button.png |
| tooltip | 툴팁 title-folder-name | Recent Projects | `projects::OpenRecent` | `<none>` | `<none>` | Ctrl-R (v0.2 에 동작 없음) | 일치 | r7-title-folder-name.png |
| tooltip | 툴팁 sidebar-btn-folder-add | Add Project | `workspace::Open` | `Ctrl-K Ctrl-O` | `Ctrl-K Ctrl-O` | Ctrl-K Ctrl-O (A-13.1) | 일치 | r7-sidebar-btn-folder-add.png |
| tooltip | 툴팁 sidebar-btn-toggle | Toggle Sidebar | `multi_workspace::ToggleWorkspaceSidebar` | `Ctrl-Alt-J` | `Ctrl-Alt-J` | Ctrl-Alt-J | 일치 | r7-sidebar-btn-toggle.png |
| tooltip | 툴팁 sidebar-btn-toggle | Focus Sidebar | `multi_workspace::FocusWorkspaceSidebar` | `Ctrl-Alt-;` | `Ctrl-Alt-;` | Ctrl-Alt-; | 일치 | r7-sidebar-btn-toggle.png |
| tooltip | 툴팁 tab-btn-back | Go Back | `pane::GoBack` | `<none>` | `<none>` | Alt-Left (v0.2 에 동작 없음) | 일치 | r7-tab-btn-back.png |
| tooltip | 툴팁 tab-btn-forward | Go Forward | `pane::GoForward` | `<none>` | `<none>` | Alt-Right (v0.2 에 동작 없음) | 일치 | r7-tab-btn-forward.png |
| tooltip | 툴팁 tab-btn-new | New… | `` | `<none>` | `<none>` | 없음 | 일치 | r7-tab-btn-new.png |
| tooltip | 툴팁 tab-btn-split | Split Pane | `` | `<none>` | `<none>` | 없음 | 일치 | r7-tab-btn-split.png |
| tooltip | 툴팁 tab-btn-zoom | Zoom In | `workspace::ToggleZoom` | `<none>` | `<none>` | Shift-Escape (v0.2 에 동작 없음) | 일치 | r7-tab-btn-zoom.png |
| tooltip | 툴팁 status-btn-project-panel | Close Left Dock | `workspace::ToggleLeftDock` | `Ctrl-B` | `Ctrl-B` | Ctrl-B | 일치 | r7-status-btn-project-panel.png |
| tooltip | 툴팁 status-btn-project-panel (Dock 닫힘) | Project Panel | `project_panel::ToggleFocus` | `Ctrl-Shift-E` | `Ctrl-Shift-E` | Ctrl-Shift-E | 일치 | r7-status-btn-project-panel-closed.png |
| menu | 메뉴 workbench-gpui | Quit workbench-gpui | `zed::Quit` | `Ctrl-Q` | `Ctrl-Q` | Ctrl+Q | 일치 | r8-menu-0.png |
| menu | 메뉴 File | Open Folder... | `workspace::Open` | `Ctrl-K Ctrl-O` | `Ctrl-K Ctrl-O` | Ctrl+K Ctrl+O | 일치 | r8-menu-1.png |
| menu | 메뉴 File | Close Window | `workspace::CloseWindow` | `Ctrl-Shift-W` | `Ctrl-Shift-W` | Ctrl+Shift+W | 일치 | r8-menu-1.png |
| menu | 메뉴 View | Toggle Left Dock | `workspace::ToggleLeftDock` | `Ctrl-B` | `Ctrl-B` | Ctrl+B | 일치 | r8-menu-2.png |
| menu | 메뉴 View | Toggle Folder Sidebar | `multi_workspace::ToggleWorkspaceSidebar` | `Ctrl-Alt-J` | `Ctrl-Alt-J` | Ctrl+Alt+J | 일치 | r8-menu-2.png |
| menu | 메뉴 View | Focus Folder Sidebar | `multi_workspace::FocusWorkspaceSidebar` | `Ctrl-Alt-;` | `Ctrl-Alt-;` | Ctrl+Alt+; | 일치 | r8-menu-2.png |
| menu | 메뉴 View | Project Panel | `project_panel::ToggleFocus` | `Ctrl-Shift-E` | `Ctrl-Shift-E` | Ctrl+Shift+E | 일치 | r8-menu-2.png |
| menu | 메뉴 Window | Minimize | `zed::Minimize` | `<none>` | `<none>` | 없음 | 일치 | r8-menu-3.png |
| menu | 메뉴 Window | Zoom | `zed::Zoom` | `<none>` | `<none>` | 없음 (F11 은 다른 액션) | 일치 | r8-menu-3.png |
| reload | 메뉴 View (keymap.json 바꾼 뒤) | Toggle Left Dock | `workspace::ToggleLeftDock` | `Alt-B` | `Alt-B` | 사용자 keymap.json | 일치 | r4-menu-after.png |
| reload | 메뉴 View (keymap.json 바꾼 뒤) | Toggle Folder Sidebar | `multi_workspace::ToggleWorkspaceSidebar` | `Ctrl-Alt-J` | `Ctrl-Alt-J` | 사용자 keymap.json | 일치 | r4-menu-after.png |
| reload | 메뉴 View (keymap.json 바꾼 뒤) | Focus Folder Sidebar | `multi_workspace::FocusWorkspaceSidebar` | `Ctrl-Alt-;` | `Ctrl-Alt-;` | 사용자 keymap.json | 일치 | r4-menu-after.png |
| reload | 메뉴 View (keymap.json 바꾼 뒤) | Project Panel | `project_panel::ToggleFocus` | `Ctrl-Shift-E` | `Ctrl-Shift-E` | 사용자 keymap.json | 일치 | r4-menu-after.png |
| reload | 툴팁 status-btn-project-panel (keymap.json 바꾼 뒤) | Close Left Dock | `workspace::ToggleLeftDock` | `Alt-B` | `Alt-B` | 사용자 keymap.json | 일치 | r4-tooltip-after.png |
| shadow | 메뉴 View (ctrl-b 를 Minimize 로 덮음) | Toggle Left Dock | `workspace::ToggleLeftDock` | `<none>` | `<none>` | 가려짐 → 없음 | 일치 | shadow-menu.png |
| shadow | 메뉴 View (ctrl-b 를 Minimize 로 덮음) | Toggle Folder Sidebar | `multi_workspace::ToggleWorkspaceSidebar` | `Ctrl-Alt-J` | `Ctrl-Alt-J` | 가려짐 → 없음 | 일치 | shadow-menu.png |
| shadow | 메뉴 View (ctrl-b 를 Minimize 로 덮음) | Focus Folder Sidebar | `multi_workspace::FocusWorkspaceSidebar` | `Ctrl-Alt-;` | `Ctrl-Alt-;` | 가려짐 → 없음 | 일치 | shadow-menu.png |
| shadow | 메뉴 View (ctrl-b 를 Minimize 로 덮음) | Project Panel | `project_panel::ToggleFocus` | `Ctrl-Shift-E` | `Ctrl-Shift-E` | 가려짐 → 없음 | 일치 | shadow-menu.png |
| shadow | 툴팁 status-btn-project-panel (ctrl-b 를 Minimize 로 덮음) | Close Left Dock | `workspace::ToggleLeftDock` | `<none>` | `<none>` | 가려짐 → 없음 | 일치 | shadow-tooltip.png |

- 줄 31개, 불일치 0개.

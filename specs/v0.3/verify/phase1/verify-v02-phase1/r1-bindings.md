# R-1 바인딩 대조표 (v0.2 Phase 1)

생성: tools/verify-v02-phase1.ps1, 2026-11-03 23:21. 앱 출력: base-stdout.txt 의 `[dev] binding seq=1` 줄(source=builtin).
기대 표: r1-expected.tsv (01-zed 02-INTERACTION 1절·9절 I-517, 04-APP-SPEC A-13.1·A-17 원문 키, 02 9.2절 키 열의 I-341·I-358(D-031 ③)).

- 기대 62줄, 일치 62줄, 앱 내장 바인딩 56개, 표 밖 내장 바인딩 0개.
- 기대 표의 I-030·I-035 줄(`menu` 컨텍스트)과 I-517 줄은 같은 앱 바인딩 하나에 대응한다. 프로젝트 패널 요소가 `ProjectPanel`·`menu`·`not_editing` 을 함께 컨텍스트로 가져(I-002) 이 바인딩이 패널에서도 듣는다.
- 그 밖에 gpui-kit 이 넣은 바인딩 142개(source=gpui-kit)는 대조에서 뺐다(D-5 이후 변경, D-027 ③).

| ID | 키 | 컨텍스트 | 액션 | 앱 index | 판정 |
| --- | --- | --- | --- | --- | --- |
| I-341 | `ctrl-q` | `-` | `zed::Quit` | 159 | 통과 |
| I-358 | `ctrl-shift-w` | `-` | `workspace::CloseWindow` | 160 | 통과 |
| I-022 | `ctrl-b` | `Workspace` | `workspace::ToggleLeftDock` | 161 | 통과 |
| I-023 | `ctrl-shift-e` | `Workspace` | `project_panel::ToggleFocus` | 162 | 통과 |
| I-024 | `ctrl-alt-j` | `Workspace` | `multi_workspace::ToggleWorkspaceSidebar` | 163 | 통과 |
| I-024 | `ctrl-alt-;` | `Workspace` | `multi_workspace::FocusWorkspaceSidebar` | 164 | 통과 |
| A-13.1 | `ctrl-k ctrl-o` | `Workspace` | `workspace::Open` | 165 | 통과 |
| I-310 | `f10` | `Workspace` | `app_menu::Toggle` | 166 | 통과 |
| A-17.3 | `up` | `Sidebar` | `menu::SelectPrevious` | 167 | 통과 |
| A-17.3 | `down` | `Sidebar` | `menu::SelectNext` | 168 | 통과 |
| A-17.4 | `enter` | `Sidebar` | `menu::Confirm` | 169 | 통과 |
| A-17.5 | `delete` | `Sidebar` | `project_panel::RemoveFromProject` | 170 | 통과 |
| I-030 | `up` | `menu` | `menu::SelectPrevious` | 145 | 통과 |
| I-030 | `down` | `menu` | `menu::SelectNext` | 142 | 통과 |
| I-030 | `home` | `menu` | `menu::SelectFirst` | 148 | 통과 |
| I-030 | `end` | `menu` | `menu::SelectLast` | 151 | 통과 |
| I-030 | `tab` | `menu` | `menu::SelectNext` | 143 | 통과 |
| I-030 | `shift-tab` | `menu` | `menu::SelectPrevious` | 146 | 통과 |
| I-031 | `left` | `ProjectPanel` | `project_panel::CollapseSelectedEntry` | 171 | 통과 |
| I-031 | `right` | `ProjectPanel` | `project_panel::ExpandSelectedEntry` | 172 | 통과 |
| I-032 | `ctrl-left` | `ProjectPanel` | `project_panel::CollapseAllEntries` | 173 | 통과 |
| I-032 | `ctrl-right` | `ProjectPanel` | `project_panel::ExpandAllEntries` | 174 | 통과 |
| I-033 | `space` | `ProjectPanel && not_editing` | `project_panel::Open` | 175 | 통과 |
| I-034 | `enter` | `ProjectPanel` | `project_panel::Rename` | 176 | 통과 |
| I-034 | `f2` | `ProjectPanel` | `project_panel::Rename` | 177 | 통과 |
| I-035 | `enter` | `menu` | `menu::Confirm` | 154 | 통과 |
| I-035 | `escape` | `menu` | `menu::Cancel` | 155 | 통과 |
| I-036 | `ctrl-n` | `ProjectPanel` | `project_panel::NewFile` | 178 | 통과 |
| I-036 | `alt-n` | `ProjectPanel` | `project_panel::NewDirectory` | 179 | 통과 |
| I-037 | `ctrl-c` | `ProjectPanel` | `project_panel::Copy` | 181 | 통과 |
| I-037 | `ctrl-insert` | `ProjectPanel` | `project_panel::Copy` | 180 | 통과 |
| I-037 | `ctrl-x` | `ProjectPanel` | `project_panel::Cut` | 182 | 통과 |
| I-037 | `ctrl-v` | `ProjectPanel` | `project_panel::Paste` | 184 | 통과 |
| I-037 | `shift-insert` | `ProjectPanel` | `project_panel::Paste` | 183 | 통과 |
| I-039 | `delete` | `ProjectPanel` | `project_panel::Trash` | 186 | 통과 |
| I-039 | `backspace` | `ProjectPanel` | `project_panel::Trash` | 185 | 통과 |
| I-040 | `shift-delete` | `ProjectPanel` | `project_panel::Delete` | 187 | 통과 |
| I-040 | `ctrl-delete` | `ProjectPanel` | `project_panel::Delete` | 189 | 통과 |
| I-040 | `ctrl-backspace` | `ProjectPanel` | `project_panel::Delete` | 188 | 통과 |
| I-041 | `alt-shift-c` | `ProjectPanel` | `workspace::CopyPath` | 190 | 통과 |
| I-041 | `ctrl-k ctrl-shift-c` | `ProjectPanel` | `workspace::CopyRelativePath` | 191 | 통과 |
| I-042 | `menu` | `ProjectPanel` | `project_panel::DeployContextMenu` | 192 | 통과 |
| I-042 | `shift-f10` | `ProjectPanel` | `project_panel::DeployContextMenu` | 193 | 통과 |
| I-043 | `shift-up` | `ProjectPanel` | `project_panel::SelectPreviousExtend` | 194 | 통과 |
| I-043 | `shift-down` | `ProjectPanel` | `project_panel::SelectNextExtend` | 195 | 통과 |
| I-517 | `down` | `menu` | `menu::SelectNext` | 142 | 통과 |
| I-517 | `tab` | `menu` | `menu::SelectNext` | 143 | 통과 |
| I-517 | `ctrl-n` | `menu` | `menu::SelectNext` | 144 | 통과 |
| I-517 | `up` | `menu` | `menu::SelectPrevious` | 145 | 통과 |
| I-517 | `shift-tab` | `menu` | `menu::SelectPrevious` | 146 | 통과 |
| I-517 | `ctrl-p` | `menu` | `menu::SelectPrevious` | 147 | 통과 |
| I-517 | `home` | `menu` | `menu::SelectFirst` | 148 | 통과 |
| I-517 | `pageup` | `menu` | `menu::SelectFirst` | 149 | 통과 |
| I-517 | `shift-pageup` | `menu` | `menu::SelectFirst` | 150 | 통과 |
| I-517 | `end` | `menu` | `menu::SelectLast` | 151 | 통과 |
| I-517 | `pagedown` | `menu` | `menu::SelectLast` | 152 | 통과 |
| I-517 | `shift-pagedown` | `menu` | `menu::SelectLast` | 153 | 통과 |
| I-517 | `enter` | `menu` | `menu::Confirm` | 154 | 통과 |
| I-517 | `escape` | `menu` | `menu::Cancel` | 155 | 통과 |
| I-517 | `ctrl-c` | `menu` | `menu::Cancel` | 156 | 통과 |
| I-517 | `right` | `menu` | `menu::SelectChild` | 157 | 통과 |
| I-517 | `left` | `menu` | `menu::SelectParent` | 158 | 통과 |

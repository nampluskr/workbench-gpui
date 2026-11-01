# v0.2 Phase 1 일치도 검증 보고서 (키맵 R-1~R-4)

- **검증자**: wg-checker (Claude Sonnet 5.5 · high, HERDR-SETUP 9절 2026-11-01 교체 후)
- **검증 일시**: 2026-11-01
- **방식**: 앱 재실행·증거 재수집 없음. 이미 있는 증거(`specs/v0.2/verify/phase1/`)와 코드·원문으로만 판정했다. 증거 파일(`results.json`, `r1-bindings.md`)의 요약을 믿지 않고 원래 출력(`*-stdout.txt`)의 `[dev] key`·`[dev] binding`·`[dev] display`·`[dev] notification` 줄과 직접 대조했다.
- **기준 문서**
  - `specs/v0.2/SPEC.md` 공통 판정 방식, R-1~R-4
  - `specs/v0.2/PLAN.md` Phase 1 완료 조건
  - `01-zed/02-INTERACTION.md`: 1절 키 표(I-001~I-043), I-516·I-517, I-700~I-705, L-217~L-221, K-085, K-091, I-098~I-100, I-310
  - `01-zed/04-APP-SPEC.md`: A-13.1, A-17, A-20.4, A-27
  - `docs/HERDR-DECISIONS.md` D-027, D-028
- **시험 환경**: 디버그 빌드 `--dev-keymap`, 입력은 SendInput. 파일 위치 `C:\Users\nampl\AppData\Roaming\workbench-gpui\keymap.json`(`results.json` `keymapPath`, 각 stdout 의 `keymap-load path=`).

---

## 요약 판정

| 요구 | 판정 | 한 줄 |
| --- | --- | --- |
| **R-1** | **통과** | 원문 키 표 60줄 모두 앱 내장 바인딩과 키·컨텍스트·동작이 같다. 빠진 것 0, 표 밖 내장 0, 다른 키 0 |
| **R-2** | **통과** | 덮어쓰기·`null` 해제·없는 액션 이름(K-085 문구)·주석/끝 쉼표 4가지에 형식 오류(K-091 문구)까지 모두 기대대로 |
| **R-3** | **통과 (Phase 1 범위)** | 포커스별 Delete·Ctrl-N, 깊이·등록 순서 규칙이 dev 출력으로 확인됨. 파일 시스템·목록 결과는 판정 불가 → Phase 3·4 이월(D-027 ⑤) |
| **R-4** | **통과 (Phase 1 범위)** | 실행 중 저장 3회(제자리·바꿔치기·시작 구간) 모두 다시 읽고 새 키·옛 키 해제·표시 문자열이 바뀜. ☰ 메뉴·툴팁 스크린샷은 판정 불가 → Phase 2 이월(D-027 ⑤) |
| **G-105 기록** | **있음** | `specs/v0.2/PROGRESS.md` 11~20행, 소스 대조로 사실 확인 |

**불일치 목록: 0건.** 판정 불가(이월) 항목은 맨 아래에 따로 적었다.

---

## R-1. 내장 키맵이 02 1절 키 표 중 v0.2 동작의 키를 표대로 가진다

- **기준**: SPEC R-1. 원문 표는 위 기준 문서에서 직접 읽었다. `r1-expected.tsv`(coder 가 옮긴 표)에 기대하지 않고 원문과 앱 출력을 직접 맞췄다.
- **앱 쪽 증거**: `base-stdout.txt` 의 `[dev] binding seq=1 ... source=builtin` 52줄(index 142~193), `[dev] builtin` 표(`unknown-stdout.txt` 등), `src/keymap/builtin.rs`.
- **숫자**: 원문 기대 60줄(키 단위), 앱 내장 52개. 차이 8은 I-030·I-035 의 `menu` 컨텍스트 키(Up/Down/Home/End/Tab/Shift-Tab/Enter/Escape)가 I-517 과 같은 바인딩이라서다(중복 8). 52 + 8 = 60 이 맞다. 앱 출력의 builtin 개수는 52, 표 밖 내장은 0(gpui-kit 바인딩 142개는 D-027 ③ 에 따라 대조에서 뺐다).

### 줄별 대조 (원문 → 앱)

| 원문 ID | 원문 키 | 원문 컨텍스트 · 동작 | 앱 index · 키 · 컨텍스트 · 액션 | 판정 |
| --- | --- | --- | --- | --- |
| I-022 | Ctrl+B | Workspace · 왼쪽 Dock 열기/닫기 | 159 · `ctrl-b` · `Workspace` · `workspace::ToggleLeftDock` | 통과 |
| I-023 | Ctrl+Shift+E | Workspace · 프로젝트 패널 포커스 토글 | 160 · `ctrl-shift-e` · `Workspace` · `project_panel::ToggleFocus` | 통과 |
| I-024 | Ctrl+Alt+J | Workspace · 사이드바 표시 토글 | 161 · `ctrl-alt-j` · `Workspace` · `multi_workspace::ToggleWorkspaceSidebar` | 통과 |
| I-024 | Ctrl+Alt+; | Workspace · 사이드바 포커스 | 162 · `ctrl-alt-;` · `Workspace` · `multi_workspace::FocusWorkspaceSidebar` | 통과 |
| I-004 · A-13.1 · A-17.6 | Ctrl+K Ctrl+O | 전역(I-004)·창(A-17.6) · `workspace::Open`(폴더 등록에 재사용) | 163 · `ctrl-k ctrl-o` · `Workspace` · `workspace::Open` | 통과 |
| I-310 | F10 | 작업 영역 · 앱 메뉴 열기 | 164 · `f10` · `Workspace` · `app_menu::Toggle` | 통과 |
| A-17.3 | Up | 사이드바 · 항목 이동(이전) | 165 · `up` · `Sidebar` · `menu::SelectPrevious` | 통과 |
| A-17.3 | Down | 사이드바 · 항목 이동(다음) | 166 · `down` · `Sidebar` · `menu::SelectNext` | 통과 |
| A-17.4 | Enter | 사이드바 · 선택 폴더 활성화 | 167 · `enter` · `Sidebar` · `menu::Confirm` | 통과 |
| A-17.5 | Delete | 사이드바 · Remove(등록 해제) | 168 · `delete` · `Sidebar` · `project_panel::RemoveFromProject` | 통과 |
| I-030 | Up / Down | ProjectPanel + menu · 이전·다음 | 145 `up`→`menu::SelectPrevious`, 142 `down`→`menu::SelectNext` (`menu`) | 통과 |
| I-030 | Home / End | ProjectPanel + menu · 처음·끝 | 148 `home`→`menu::SelectFirst`, 151 `end`→`menu::SelectLast` (`menu`) | 통과 |
| I-030 | Tab / Shift+Tab | 전역 menu 의 다음·이전 | 143 `tab`→`menu::SelectNext`, 146 `shift-tab`→`menu::SelectPrevious` (`menu`) | 통과 |
| I-031 | Left / Right | ProjectPanel · 접기 / 펼치기 | 169 `left`→`project_panel::CollapseSelectedEntry`, 170 `right`→`project_panel::ExpandSelectedEntry` (`ProjectPanel`) | 통과 |
| I-032 | Ctrl+Left / Ctrl+Right | ProjectPanel · 전체 접기 / 펼치기 | 171 `ctrl-left`→`...CollapseAllEntries`, 172 `ctrl-right`→`...ExpandAllEntries` (`ProjectPanel`) | 통과 |
| I-033 | Space | ProjectPanel, 이름 편집 중 아님 · 파일 열기(임시 탭) | 173 · `space` · `ProjectPanel && not_editing` · `project_panel::Open` | 통과 |
| I-034 | Enter 또는 F2 | ProjectPanel · 이름 변경 | 174 `enter`, 175 `f2` · `ProjectPanel` · `project_panel::Rename` | 통과 |
| I-035 | Enter / Escape | 이름 입력, ProjectPanel + menu · 확정 / 취소 | 154 `enter`→`menu::Confirm`, 155 `escape`→`menu::Cancel` (`menu`) | 통과 |
| I-036 | Ctrl+N / Alt+N | ProjectPanel · 새 파일 / 새 폴더 | 176 `ctrl-n`→`project_panel::NewFile`, 177 `alt-n`→`project_panel::NewDirectory` (`ProjectPanel`) | 통과 |
| I-037 | Ctrl+C 또는 Ctrl+Insert | ProjectPanel · 복사 | 178 `ctrl-c`, 179 `ctrl-insert` → `project_panel::Copy` | 통과 |
| I-037 | Ctrl+X | ProjectPanel · 잘라내기 | 180 `ctrl-x` → `project_panel::Cut` | 통과 |
| I-037 | Ctrl+V 또는 Shift+Insert | ProjectPanel · 붙여넣기 | 181 `ctrl-v`, 182 `shift-insert` → `project_panel::Paste` | 통과 |
| I-038 | Ctrl+Z / Ctrl+Shift+Z | ProjectPanel · **제외** | 앱에 없음(52개 중 `ctrl-z` 없음) | 통과(제외가 지켜짐) |
| I-039 | Delete 또는 Backspace | ProjectPanel · 휴지통 | 183 `delete`, 184 `backspace` → `project_panel::Trash` | 통과 |
| I-040 | Shift+Delete / Ctrl+Delete / Ctrl+Backspace | ProjectPanel · 영구 삭제 | 185 `shift-delete`, 186 `ctrl-delete`, 187 `ctrl-backspace` → `project_panel::Delete` | 통과 |
| I-041 | Shift+Alt+C | ProjectPanel · 경로 복사 | 188 · `alt-shift-c` · `ProjectPanel` · `workspace::CopyPath` | 통과 |
| I-041 | Ctrl+K Ctrl+Shift+C | ProjectPanel · 상대 경로 복사 | 189 · `ctrl-k ctrl-shift-c` · `ProjectPanel` · `workspace::CopyRelativePath` | 통과 |
| I-042 | Menu 키 또는 Shift+F10 | ProjectPanel · 우클릭 메뉴 열기 | 190 `menu`, 191 `shift-f10` → `project_panel::DeployContextMenu` | 통과 |
| I-043 | Shift+Up / Shift+Down | ProjectPanel · 선택 범위 확장 | 192 `shift-up`→`...SelectPreviousExtend`, 193 `shift-down`→`...SelectNextExtend` | 통과 |
| I-517 | Down, Tab, Ctrl-N | `menu` · 다음 | 142, 143, 144 → `menu::SelectNext` | 통과 |
| I-517 | Up, Shift-Tab, Ctrl-P | `menu` · 이전 | 145, 146, 147 → `menu::SelectPrevious` | 통과 |
| I-517 | Home, PageUp, Shift-PageUp | `menu` · 처음 | 148, 149, 150 → `menu::SelectFirst` | 통과 |
| I-517 | End, PageDown, Shift-PageDown | `menu` · 끝 | 151, 152, 153 → `menu::SelectLast` | 통과 |
| I-517 | Enter | `menu` · 실행 | 154 → `menu::Confirm` | 통과 |
| I-517 | Escape, Ctrl-C | `menu` · 닫기 | 155, 156 → `menu::Cancel` | 통과 |
| I-517 | Right / Left | `menu` · 하위 메뉴 열기 / 상위로 | 157 `right`→`menu::SelectChild`, 158 `left`→`menu::SelectParent` | 통과 |
| I-516 | (컨텍스트 이름) | `menu` | 위 `menu` 바인딩 17개가 컨텍스트 `menu` | 통과 |

원문 줄 수: 10(창·사이드바) + 6(I-030) + 1+1+1+2(I-031~I-034) + 2(I-035) + 2+5(I-036·I-037) + 2+3+2+2+2(I-039~I-043) + 17(I-517) = 60. 표 위 "숫자"의 52/8 과 같다.

### 빠진 것·다른 키 찾기 결과

- **빠진 것**: 없음. 원문에서 v0.2 범위로 채용된 키를 모두 앱에서 찾았다.
- **표 밖 내장(원문에 없는데 앱에 있는 것)**: 없음. 52개 전부 위 표에 대응한다. 특히 다음이 들어 있지 않음을 확인했다. Workspace 의 Ctrl+N(I-005, v0.2 동작 아님), Ctrl+O(I-003), I-038 Undo/Redo(제외), I-025·I-026 같은 범위 밖 키.
- **다른 키(키 오타·수식키 순서)**: 없음. 앱 표기는 gpui 순서(`alt-shift-c`)이고 원문 `Shift+Alt+C` 와 같은 키다.
- **원문에 이름이 있는 액션 17개**(`workspace::ToggleLeftDock`·`Open`·`CopyPath`·`CopyRelativePath`, `multi_workspace::ToggleWorkspaceSidebar`·`FocusWorkspaceSidebar`, `project_panel::ToggleFocus`·`Rename`·`NewFile`·`NewDirectory`·`Copy`·`Cut`·`Paste`·`Trash`·`Delete`·`RemoveFromProject`, `menu::Confirm`)는 01-zed 원문 파일에서 이름을 직접 찾아 확인했다. 원문에 이름이 없어 coder 가 지은 16개(D-027 ②, EVIDENCE.md 에 목록)는 모두 원문이 설명한 동작과 뜻이 같다(예: I-031 접기/펼치기 → `CollapseSelectedEntry`/`ExpandSelectedEntry`). 이름 자체는 원문 기준이 없어 판정하지 않는다.
- **컨텍스트 해석(참고)**: 원문 I-030·I-035 의 "ProjectPanel + menu"는 앱에서 `menu` 컨텍스트 바인딩으로 두었다. 프로젝트 패널 요소가 `ProjectPanel menu not_editing` 을 함께 가진다(I-002). 이는 `base-stdout.txt` 의 `[dev] key ... context=Root > Workspace > ProjectPanel menu not_editing` 줄로 확인된다. D-027 ③ 의 결정과 같다.

**R-1 판정: 통과.**

---

## R-2. 사용자 keymap.json 이 내장 키맵 위에 마지막으로 얹히고 null 은 낮은 후보를 해제한다

- **기준**: SPEC R-2(A-20.4, A-27.1, I-703, K-085, K-091, D-4, D-11, D-14)

| 사례 | 명세 값 | 실제 값 | 판정 | 증거 파일 |
| --- | --- | --- | --- | --- |
| 덮어쓰기(`override`) | 내장과 같은 키를 다른 액션으로 묶으면 사용자 액션 실행(A-27.1) | `Workspace` 의 `ctrl-b` 를 `project_panel::ToggleFocus` 로 묶음. 가운데 포커스·패널 포커스 두 곳 모두 `action=project_panel::ToggleFocus`. 표시: 그 액션 `Ctrl-B`, `ToggleLeftDock` 은 `<none>`(I-704 가려짐) | 통과 | `override-keymap.json`, `override-stdout.txt`(351·353행, display) |
| `null` 해제(`null`) | `null` 이면 그 컨텍스트에서 내장 바인딩이 실행되지 않음(I-703) | `Workspace` `ctrl-b: null` → `action=none`. `ProjectPanel` `delete: null` → `action=none`, 해제하지 않은 `backspace` 는 `project_panel::Trash` 그대로. 사이드바 `Delete` 는 `RemoveFromProject` 그대로(그 컨텍스트에서만 해제). 바인딩 196개 = 194 + 2, 사용자 줄은 `zed::NoAction` | 통과 | `null-keymap.json`, `null-stdout.txt`(351~362행) |
| 없는 액션 이름(`unknown`) | 읽기 오류 알림, 문구는 K-085 `Action '{이름}' not found` 와 같다 | 알림 2줄 `Action 'workspace::NoSuchAction' not found`, `Action 'zed::Unknown' not found`(글자 단위 같음, 스크린샷과 stdout 일치). 잘못된 항목만 빼고 나머지는 적용(`f10`→`ToggleLeftDock` 실행, `ctrl-b`·`ctrl-alt-j` 는 내장 그대로). `errors=2`, 바인딩 195 | 통과 | `unknown-keymap.json`, `unknown-stdout.txt`(2·3행), `unknown-notification.png` |
| 주석·끝 쉼표(`jsonc`) | `//`, `/* */`, 끝 쉼표 허용(D-4) | `errors=0`, `f10` 이 `project_panel::ToggleFocus` 로 실행 | 통과 | `jsonc-keymap.json`, `jsonc-stdout.txt`(1·351행) |
| 형식 오류(`broken`, 추가 사례) | K-091 `Failed to load keymap file`, 내장 키맵 유지 | 알림 `Failed to load keymap file`(스크린샷과 stdout 일치), `ctrl-b` 가 내장 `ToggleLeftDock` 로 실행, 바인딩 194(사용자 0) | 통과 | `broken-keymap.json`, `broken-stdout.txt`(2행), `broken-notification.png` |
| 파일 위치(D-11) | `%APPDATA%\workbench-gpui\keymap.json` | 모든 `keymap-load path=C:\Users\nampl\AppData\Roaming\workbench-gpui\keymap.json` | 통과 | 각 `*-stdout.txt` 1행 |

- **코드 확인**: 사용자 층은 meta 등급 0, 내장은 `BUILTIN_META`(`src/ui/keymap.rs:246-248`), `null` 은 `NoAction`(같은 파일 271-272행)이다. gpui-pre `keymap.rs:225-236` 이 NoAction 의 meta 등급 이상(같거나 약한)인 바인딩을 걸러 낸다. 이는 I-703 "사용자 > 기본" 등급과 같다.

**R-2 판정: 통과.**

---

## R-3. 같은 키는 컨텍스트가 더 깊은 쪽, 깊이가 같으면 나중 바인딩이 이긴다

- **기준**: SPEC R-3(I-002, I-702, I-005, I-036, I-039, A-13.4, A-14). D-027 ⑤ 에 따라 Phase 1 은 dev 출력의 "실행된 액션 이름"으로 판정하고 파일 시스템·목록 결과는 Phase 3·4 에서 다시 판정한다.

| 항목 ID | 명세 값 | 실제 값 | 판정 | 증거 파일 |
| --- | --- | --- | --- | --- |
| I-002 · A-13.4 (사이드바 Delete) | 사이드바 포커스의 Delete = 등록 해제 | `delete` → `project_panel::RemoveFromProject`, 컨텍스트 `Root > Workspace > Sidebar` | 통과 | `base-stdout.txt` 369행 |
| I-039 (패널 Delete) | 프로젝트 패널 Delete = 휴지통 | `delete` → `project_panel::Trash`, 컨텍스트 `... ProjectPanel menu not_editing` | 통과 | `base-stdout.txt` 375행 |
| A-14 (가운데 Delete) | Workspace 에 Delete 바인딩 없음 | `delete` → `action=none`, `Root > Workspace` | 통과 | `base-stdout.txt` 349행 |
| I-036 · I-005 (Ctrl+N) | 패널에서 새 파일. Workspace 의 새 버퍼는 v0.2 에 없음 | 패널 `ctrl-n` → `project_panel::NewFile`(같은 컨텍스트의 `menu::SelectNext` 보다 나중 등록이라 이김). Workspace 에 `ctrl-n` 바인딩 없음(내장 52개에 없음) | 통과 | `base-stdout.txt` 383행, 내장 표 |
| I-702 (같은 깊이·나중 등록) | 같은 컨텍스트에 두 번 묶으면 나중 것 | `Workspace` `f10` 두 번(`ToggleLeftDock` → `ToggleFocus`). 가운데·패널 포커스 모두 `project_panel::ToggleFocus` 실행. 표시도 `F10` → `ToggleFocus` | 통과 | `order-keymap.json`, `order-stdout.txt`(353·355행) |
| I-702 (깊이 다름) | 깊은 컨텍스트가 나중 등록을 이김 | 사용자 `Workspace` `delete`→`ToggleLeftDock`(나중 등록)이 있어도, 가운데에서는 `ToggleLeftDock`, `Sidebar` 에서는 내장 `RemoveFromProject` | 통과 | `order-stdout.txt`(357~363행) |
| I-702 내장끼리 | 같은 깊이는 나중 등록 | 패널 `ctrl-c`→`Copy`(`menu::Cancel` 보다 나중), `enter`→`Rename`(`menu::Confirm` 보다 나중) | 통과 | `base-stdout.txt` 387·395행 |

- **판정 불가(이월)**: 루트 항목에서 Delete 무동작(A-14 아래 목록), 사이드바 목록·디스크 상태 변화, 휴지통 이동 결과. 이 화면·동작이 아직 없다. D-027 ⑤ 와 PROGRESS 47행이 Phase 3·4 재판정을 적었다.

**R-3 판정: 통과 (Phase 1 범위).**

---

## R-4. keymap.json 을 고쳐 저장하면 바로 다시 읽고 메뉴·툴팁 표시도 바뀐다

- **기준**: SPEC R-4(I-704, K-096). 메뉴·툴팁 화면이 아직 없어 단축키 표시는 `[dev] display`(액션별 표시 문자열)로 대신 판정했다(D-027 ⑤).

| 항목 ID | 명세 값 | 실제 값 | 판정 | 증거 파일 |
| --- | --- | --- | --- | --- |
| I-704 · K-096 (실행 중 다시 읽기) | 앱을 다시 띄우지 않고 새 키가 동작 | `reload`: `keymap-load seq=1`(194) → seq=2(196, `ctrl-b: null` + `alt-b`) → seq=3(195, `ctrl-alt-b`). `alt-b` 가 `ToggleLeftDock` 실행(705행), seq=3 후 `ctrl-alt-b` 실행(1057행) | 통과 | `reload-stdout.txt`, `results.json` |
| 옛 키 해제 | 바꾼 뒤 옛 키는 동작하지 않음 | seq=2 후 `ctrl-b` → `action=none`(706행). seq=3 후 `alt-b` → `action=none`(1060행). `null` 을 뺀 seq=3 에서는 내장 `ctrl-b` 가 돌아옴(1059행) | 통과 | `reload-stdout.txt` |
| 표시 문자열 갱신 | L-219 형식, I-704 마지막 후보 | `ToggleLeftDock` 표시 `Ctrl-B`(249행) → `Alt-B`(603행) → `Ctrl-Alt-B`(956행). 형식은 하이픈·Ctrl→Alt 순서·첫 글자 대문자(L-219, L-220) 일치 | 통과 | `reload-stdout.txt` |
| 저장 방식 | 제자리 덮어쓰기와 바꿔치기(이름 변경) 둘 다 감지 | `reload-keymap-2.json`(제자리), `reload-keymap-3.json`(다른 파일 후 이름 바꾸기) 모두 다시 읽음 | 통과 | `reload-keymap-2.json`, `reload-keymap-3.json` |
| 시작 구간 저장(D-028 ②) | 최초 로드 직후 저장도 놓치지 않음 | `startup`: seq=1(194) → 멈춘 동안 저장 → seq=2(195), 표시 `Alt-B`(599행), `alt-b` 실행(700행) | 통과 | `startup-stdout.txt`, `startup-keymap-2.json` |
| 반영 시간 | SPEC 에 기준 수치 없음 | `results.json` `reloadMs2` 1389, `reloadMs3` 1364. 스크립트 폴링 시간을 포함하므로 참고값 | 참고 | `results.json` |

- **판정 불가(이월)**: ☰ 메뉴·툴팁에 새 키가 보이는지의 전후 스크린샷. 메뉴·툴팁이 Phase 2 구현이다. D-027 ⑤, PROGRESS 47행이 Phase 2 재판정을 적었다.

**R-4 판정: 통과 (Phase 1 범위).**

---

## G-105 확인 결과의 PROGRESS 기록

- `specs/v0.2/PROGRESS.md` 11~20행 "G-105 키맵 엔진 확인 (2026-11-01)"에 있다. 공개 여부(공개, 경로 포함), `null` 처리(`NoAction` + meta 등급), 충돌 규칙, 표시용 조회 API, 액션 정의 방법이 적혀 있다.
- **소스 대조**: gpui-pre 0.3.10 에서 직접 확인했다. `gpui.rs:195` `pub use keymap::*;`, `keymap.rs:5` `pub use context::*;`, `keymap/context.rs:170` `pub enum KeyBindingContextPredicate`, `action.rs:5` `pub use no_action::{NoAction, Unbind, is_no_action, is_unbind}`, `keymap.rs:225-236` NoAction meta 등급 필터. PROGRESS 의 서술과 일치한다.
- DECISIONS D-3 이후 변경과 D-027 에도 같은 결과가 반영되어 있다.

**판정: 있음 (조건 충족).**

---

## PLAN Phase 1 완료 조건 대조

| 완료 조건 | 판정 | 비고 |
| --- | --- | --- |
| R-1~R-4 가 SPEC 판정 방법대로 통과 | 통과(R-3·R-4 는 Phase 1 범위) | 이월 항목은 아래 표 |
| G-105 결과가 PROGRESS 에 있음 | 충족 | 11~20행 |
| `verify/phase1/` 에 보고서와 R-1 바인딩 대조표 | 충족 | 이 보고서 + `r1-bindings.md` |
| wg-reviewer Phase 1 리뷰 결과가 PROGRESS 에 있음 | 1회차만 있음 | PROGRESS 55~66행. D-028 이 "리뷰 2회차"를 예고했으나 2회차 기록은 아직 없다(checker 판정 범위 밖, leader 확인 필요) |
| Phase 1 커밋 | 미확인 | 세션 시작 시점 git 상태가 staged 이고 최근 커밋에 Phase 1 이 없다. 이 판정 뒤의 절차 |

## 판정 불가(이월) 목록

| 요구 | 판정 불가 항목 | 이유 | 다시 판정할 Phase |
| --- | --- | --- | --- |
| R-3 | 루트 항목 Delete 무동작, 사이드바 목록·디스크·휴지통 상태 변화 | 사이드바 폴더 등록·트리·파일 작업이 아직 없음 | Phase 3·4 |
| R-4 | ☰ 메뉴·툴팁의 새 키 표시 스크린샷 | 메뉴·툴팁이 아직 없음 | Phase 2 |

## 관찰(불일치 아님)

1. **PROGRESS 41행 사례 수 불일치**: "8개 사례 모두 실패 0"이라고 적었으나 `results.json`·EVIDENCE.md·PROGRESS 60행은 9개(startup 추가). 41행이 리뷰 1회차 전 숫자로 남은 것이다. 판정에는 영향 없다.
2. **`unknown` 사례 컨텍스트**: 마지막 키 `ctrl-alt-j` 줄의 컨텍스트가 `Root > Workspace > Sidebar` 로, base 사례의 같은 키(`Root > Workspace`)와 다르다(`unknown-stdout.txt` 357행). 실행된 액션은 기대한 내장 `ToggleWorkspaceSidebar` 이므로 R-2 판정은 같다. 원인은 확인하지 않았다(알림 표시 때문으로 짐작).
3. **Phase 4 에 넘길 점**: I-035 의 "이름 입력 중" 상태(`editing`)와 패널의 `Enter` 가 `Rename` 에 가려지는 문제는 `editing` 컨텍스트가 아직 없어 판정하지 않았다. R-22 의 메뉴 단축키(Ctrl-Alt-R 등 I-530~I-557)는 R-1 범위가 아니라 Phase 4 에서 키맵에 추가될 때 대조한다.

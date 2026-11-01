# v0.2 Phase 1 증거 (wg-coder)

판정 보고서는 wg-checker 가 쓴다. 이 파일은 증거 파일의 목록과 읽는 법이다.

- 만든 방법: `pwsh -NoProfile -File tools/verify-v02-phase1.ps1`(2026-11-01). 디버그 빌드에 `tools/apply-manifest.ps1` 를 적용한 뒤 돌렸다.
- 결과: 9개 사례, 실패 0(`results.json` 의 `failures`·`passed`). 리뷰 1회차(D-028) 수정 뒤 다시 돌린 결과다.

## 파일

| 파일 | 내용 |
| --- | --- |
| `r1-expected.tsv` | R-1 기대 표. 01-zed 원문 키 표에서 옮겨 적었다(ID·키·컨텍스트·액션) |
| `r1-bindings.md` | R-1 대조표. 기대 60줄과 앱 내장 바인딩(base-stdout.txt)을 줄마다 대조했다 |
| `results.json` | 사례별 키 입력 결과(기대·실제 액션·컨텍스트·원래 출력 줄), 표시 문자열 대조, 알림 문구 |
| `<사례>-stdout.txt` | 앱 `--dev-keymap` 표준출력 |
| `<사례>-keymap.json` | 그 사례에서 쓴 `%APPDATA%\workbench-gpui\keymap.json`. base 는 파일 없음 |
| `reload-keymap-2.json`, `reload-keymap-3.json` | R-4 실행 중에 바꿔 저장한 내용(2: 제자리 덮어쓰기, 3: 다른 파일에 쓴 뒤 이름 바꾸기) |
| `startup-keymap-2.json` | startup 사례에서 최초 로드 직후 멈춘 동안 저장한 내용 |
| `unknown-notification.png`, `broken-notification.png` | 읽기 오류 알림 화면. 문구만 판정한다(D-14) |

## 사례와 대응 요구

| 사례 | 요구 | 확인한 것 |
| --- | --- | --- |
| base | R-1, R-3 | 바인딩 대조. 포커스 자리(가운데·사이드바·프로젝트 패널)마다 같은 키를 넣어 실행된 액션 확인. Delete 는 사이드바 = 등록 해제, 패널 = 휴지통, 가운데 = 없음. 패널의 Ctrl-N 은 새 파일 |
| override | R-2 | Workspace 의 ctrl-b 를 사용자가 다른 액션으로 묶으면 사용자 액션이 실행된다 |
| null | R-2 | `null` 은 그 컨텍스트의 내장 바인딩만 해제한다(사이드바 Delete 는 그대로) |
| unknown | R-2 | 없는 액션 이름 2개 → `Action '{이름}' not found` 두 줄 알림. 나머지 항목은 적용 |
| jsonc | R-2 | 주석(`//`, `/* */`)·끝 쉼표 허용 |
| broken | R-2 | 형식 오류 → `Failed to load keymap file`. 내장 키맵은 그대로 |
| order | R-3 | 같은 깊이 두 번 묶으면 나중 것이 이긴다. 깊이가 다르면 깊은 쪽(Sidebar 내장)이 나중 등록(Workspace 사용자)보다 이긴다 |
| startup | R-4 | 최초 로드 직후(`--dev-keymap-startup-delay 3000` 으로 멈춘 동안) 저장해도 감시가 잡아 다시 읽는다(seq=2, 표시 `Alt-B`, Alt-B 실행). 감시를 로드 뒤에 등록하던 이전 순서에서는 놓치던 구간이다(리뷰 1회차 ②) |
| reload | R-4 | 실행 중 두 번 바꿔 저장. 다시 읽기(seq 증가), 새 키 실행, 옛 키 해제, 표시 문자열 `Ctrl-B` → `Alt-B` → `Ctrl-Alt-B` |

## 출력 줄 읽는 법

- `[dev] binding seq=N index=i source=<gpui-kit|builtin|user> keys=... context=... action=...` 은 읽은 뒤의 바인딩 전체다(등록 순서). `zed::NoAction` 은 사용자 `null` 이다.
- `[dev] display seq=N where=<center|sidebar|project_panel> action=... text=...` 는 그 자리에 포커스가 있을 때의 표시 문자열이다(I-704: 다른 액션에 가려진 키 제외, 남은 것 중 마지막. 형식 L-217~L-221). `<none>` 은 그 자리에서 듣지 않는다는 뜻이다.
- `[dev] key keystroke=... action=... context=...` 는 키 입력과 처리된 액션이다. `action=none` 이면 처리된 액션이 없다. `keystroke=alt` 처럼 수식키만 있는 줄은 Alt 를 뗄 때 gpui 가 내는 줄이라 판정에서 뺐다.
- `[dev] notification seq=N text=...` 는 알림 한 줄이다.

## 우리가 지은 액션 이름 (D-2 이후 변경, D-027 ②)

01-zed·02-gpui 에 이름이 없어 Zed 와 같은 `namespace::Name` 꼴로 지은 이름 16개다.

`app_menu::Toggle`, `menu::SelectNext`, `menu::SelectPrevious`, `menu::SelectFirst`, `menu::SelectLast`, `menu::Cancel`, `menu::SelectChild`, `menu::SelectParent`, `project_panel::CollapseSelectedEntry`, `project_panel::ExpandSelectedEntry`, `project_panel::CollapseAllEntries`, `project_panel::ExpandAllEntries`, `project_panel::Open`, `project_panel::DeployContextMenu`, `project_panel::SelectPreviousExtend`, `project_panel::SelectNextExtend`

## Phase 2~4 에서 다시 판정할 것 (D-027 ⑤)

- R-3 의 실제 결과(사이드바 등록 해제, 휴지통, 루트 항목 Delete 무동작, 디스크·목록 상태)는 Phase 3·4 에서 판정한다.
- R-4 의 ☰ 메뉴·툴팁 화면의 새 키 표시는 Phase 2 에서 판정한다.
- Phase 1 은 dev 출력의 실행된 액션 이름과 액션별 표시 문자열로 판정했다.

## 검증 스크립트의 안전 확인 (리뷰 1회차 ①·③)

- 바꿔치기용 임시 파일은 `keymap.json.<GUID>.tmp` 이고, 끝날 때 이번 실행이 만든 경로만 지운다.
- 같은 폴더의 `keymap.json.tmp`(이 스크립트 것이 아닌 파일)는 실행 전후 SHA-256 이 같아야 한다. 결과는 `results.json` 의 `foreignTmp` 에 있고, 이번 실행에서 `unchanged: true` 였다. 원래 파일이 없어 표지 파일을 만들어 비교한 뒤 지웠다.
- 띄운 프로세스는 Start-App 이 띄우자마자 기록한다. 준비 대기나 창 탐색이 실패해도 그 PID 만 닫는다.
- 키 판정은 보낸 마지막 키 입력과 keystroke 가 같은 `[dev] key` 줄로 한다. 이 스크립트가 보내지 않은 키 줄은 `results.json` 의 `foreignKeys` 에 경고로 남긴다. 이번 실행에서는 0개였다.
- 정리 순서(리뷰 2회차, D-029): 사용자 keymap.json 복원을 가장 먼저, 독립된 try/finally 로 한다. 그 뒤 백업 지우기(복원 해시가 같을 때만), 외부 tmp 해시 확인, 표지 파일 지우기, GUID tmp 지우기를 각각 따로 try/catch 해 예외를 `results.json` 의 `errors` 에 모은다. 사용자 keymap.json 의 실행 전후 SHA-256 은 `results.json` 의 `userKeymap` 에 있다. 이번 실행은 `<absent>` → `<absent>`, `restored: true`, `errors` 0개다.

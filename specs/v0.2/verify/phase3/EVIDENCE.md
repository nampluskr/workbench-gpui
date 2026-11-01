# v0.2 Phase 3 증거 — 사이드바 폴더 등록·선택·해제 (R-10~R-16·R-28)

생성: `pwsh -NoProfile -File tools/verify-v02-phase3.ps1` (2026-11-01). 결과: **판정 114개, 실패 0**, 사용자 파일 복원 확인(`results.json` 의 `userFiles.restored = true`).

- 결정: D-035(트리·탭 의존 판정 Phase 4 이월, 읽기 오류 문구 `Could not read the window state.`(우리 문구), A-24.1~A-24.7 적용).
- 앱 실행: 사례마다 `--dev-keymap --dev-layout --dev-pick-folder <파일>` 으로 새로 띄운다. `dialog` 사례만 플래그 없이 실제 OS 폴더 선택 창.
- 폴더 선택 방법(R-10 판정 방법): **두 가지 모두 썼다.**
  - `dialog` 사례: rfd 0.17.2 의 실제 선택 창(#32770, 제목 `폴더 선택`)을 SendInput 으로 조작. 폴더 칸에 전체 경로 입력 → Enter(그 폴더로 이동) → 확인 버튼(`폴더 선택`, IDOK)을 SendInput 마우스로 누름. Escape 취소도 실제 창으로 확인. 스크린샷 `dialog-open.png`, `dialog-navigated.png`.
  - 나머지 사례: `--dev-pick-folder <파일>`(D-035) 로 고른 경로를 주입(파일 첫 줄, `<cancel>` 이면 취소). 진입 경로(키·버튼·메뉴)는 실제 입력이다.
- 시험 폴더: `target\phase3-folders`(끝나면 지움). 읽을 수 없는 폴더는 이 시험 폴더(`locked`)에만 `icacls /deny <사용자>:(RD)` 를 걸었다.
- 사용자 파일: `%APPDATA%\workbench-gpui` 의 `keymap.json`·`state.json*` 을 백업하고 끝에 가장 먼저 복원, 전후 SHA-256 비교(D-029 방식).
- 좌표·치수는 논리 px(rem 16, 배율 2). 창은 띄운 창만 최대화(1440×852).

## 사례별 요약

| 사례 | 요구 | 확인한 것 | 증거 |
| --- | --- | --- | --- |
| empty | R-15 A-16.1, R-12 A-13.9 | 빈 목록, 빈 상태 문구·`Open Project` 버튼, 타이틀 `Open Recent Project`, 버튼 → 선택 창 → 등록·활성, 루트 줄 | `empty-screen.png`, `empty-after-open-project.png`, `empty-stdout.txt` |
| add | R-10 | Ctrl+K Ctrl+O·푸터 버튼·☰ File > Open Folder... 로 맨 아래 등록·활성, 대소문자·끝 `\` 다른 같은 경로 → 기존 활성, 없는 경로·파일·읽기 불가 → `Cannot open this folder.` 알림·미등록, 취소 → 변화 없음, state.json(UUID v4 id, ISO 8601 UTC added_at, A-28 정규화 경로) | `add-state.json`, `add-notification.png`, `add-stdout.txt` |
| dialog | R-10 A-10.6·D-6 | 실제 선택 창 Escape 취소, 경로 입력 + 확인 → 등록 | `dialog-*.png`, `dialog-stdout.txt` |
| items | R-11, R-15 | `docs · one`/`docs · two`(A-12.6), 없는 경로 비활성 색(A-12.7), 안쪽·바깥 폴더 독립(A-16.5), 줄 높이 31·간격 31, hover 2초 툴팁 없음(A-12.8), 키보드 커서 둘레 1px(A-12.5), 없는 경로 활성 → `This folder no longer exists.` + Remove, Remove → 아래 항목 활성 | `items-active0.png`, `items-hover-row2.png`, `items-keyboard-focus-row1.png`, `items-missing-active.png` |
| scroll | R-15 A-16.7 | 32개 등록, 휠 → 목록 세로 스크롤(`[dev] sidebar-scroll offset_y` 음수) | `scroll-after-wheel.png` |
| switch | R-12 | 클릭 활성화(Workspace 엔티티 처음 생성), 다른 폴더로 갔다 오면 같은 엔티티(created=false), 엔티티 2개 유지, 포커스 사이드바 그대로(A-15.6), Up/Down·Enter 활성화, state.json active_folder_id | `switch-beta.png`, `switch-state.json` |
| title | R-12 L-88 | 45자 폴더 이름 → 타이틀 40자 + `…` | `title-long-name.png` |
| remove | R-13 | 우클릭 Remove(활성 → 아래 활성), 사이드바 Delete(커서 항목), 맨 아래 활성 해제 → 위 활성, 폴더 하나면 메뉴에 Remove 만, 모두 해제 → 빈 상태, 확인창 없음, **디스크 목록(폴더 이름, 파일 크기·수정 시각·SHA-256) 전후 같음** | `remove-disk-before.txt`, `remove-disk-after.txt`, `remove-context-menu.png`, `remove-all-empty.png`, `remove-state.json` |
| order / order-restart | R-14 | 메뉴 `Move Up / Move Down / --- / Remove`, 맨 위 Move Up·맨 아래 Move Down 비활성(누르면 아무 일 없음), 한 칸씩 이동, 메뉴 키 Down·Enter, Escape, 실행 뒤 포커스 복원(I-309), 빈 공간·폴더 추가 버튼 우클릭 메뉴 없음, 메뉴 상자 폭 ≥ 202·구분선 1·위아래 6, state.json 순서, 다시 시작 복원 | `order-menu-top.png`, `order-state.json`, `order-restart.png` |
| keys | R-16 | Ctrl+Alt+J(A-17.1, 닫을 때 이전 포커스), Ctrl+Alt+;(A-17.2, 이전 포커스로·닫지 않음, 패널 ↔ 사이드바), Ctrl+B(A-17.7), Ctrl+Shift+E(A-17.8), 사이드바 닫힘 상태 표시줄 순서(A-11.9)·열림(A-11.8), L-251 툴팁 `Open Folder Sidebar|Ctrl-Alt-J`, 상태 표시줄 폴더 추가 툴팁 `Add Project|Ctrl-K Ctrl-O`, 푸터·상태 표시줄 버튼 누름, 메뉴가 열린 채 사이드바로 갔다 돌아오면 center | `keys-sidebar-closed.png`, `keys-tooltip-open-folder-sidebar.png` |
| menus | R-8 9.2 (Phase 2 이월) | File: `Open Folder...|Ctrl-K Ctrl-O`·`---`·`Close Window|Ctrl-Shift-W`, View: `Toggle Left Dock|Ctrl-B`·`Toggle Folder Sidebar|Ctrl-Alt-J`·`Focus Folder Sidebar|Ctrl-Alt-;`·`---`·`Project Panel|Ctrl-Shift-E`, 메뉴 실행 동작 | `menus-view.png` |
| state / state-restart | R-28 | 사이드바 경계 끌기 → state.json `sidebar.width`, 알 수 없는 키(root·window·folder·sidebar) 보존, 다시 시작 → 폭·목록·활성 복원 | `state-after-resize.json`, `state-restart.png` |
| broken | R-28 A-24.6 | 깨진 state.json → 빈 상태, 알림 `Could not read the window state.`(우리 문구, D-035 ②), `state.json.bad-YYYYMMDD-HHMMSS` 로 옮김 | `broken-notification.png` |
| tmp | A-24.5 | 깨진 state.json + 올바른 `.tmp` → `.tmp` 로 복구, 깨진 파일 `.bad` | `tmp-stdout.txt` |
| quitsave / quitnochange | A-24.3 | 바꾸고 500ms 안에 Ctrl+Q → 끝나기 전에 저장, 바꾼 것 없이 끝내면 쓰지 않음(판단) | `quitsave-state.json` |
| version | A-24.7 | version 2 → 읽기만, 바꿔도 파일 해시 그대로(`state-save result=skipped-read-only`) | `version-stdout.txt` |

## 판단·이월(원문에 값이 없거나 Phase 4·5 범위)

- **판단(우리 값)**
  - 읽기 오류 알림 문구 `Could not read the window state.` 는 D-035 ② 로 정한 우리 문구다(원문 문구 아님).
  - 깨진 파일 이름 `state.json.bad-YYYYMMDD-HHMMSS` 의 시각은 UTC 다.
  - 타이틀 바 40자 말줄임은 40자 뒤에 `…` 를 붙인다(L-88 은 40자만 정한다).
  - 사이드바 Up/Down 은 끝에서 반대편으로 순환한다(`menu::SelectNext` 의 I-518 을 따름). 처음 Down 은 첫 항목, Up 은 끝 항목.
  - 폴더 줄의 아이콘–이름 간격 4(A-12.1 에 값 없음). 색은 gpui-kit 기본 테마 토큰(활성 `list_active`, hover `secondary_hover`, 누름 `secondary_active`, 포커스 `ring`, 경로 없음 `muted_foreground` 45%). 색 값은 판정하지 않고 구별만 본다(R-11).
  - 종료 직전 쓰기(A-24.3)는 아직 쓰지 않은 변경이 있을 때만 한다. 바뀐 것 없이 끝내면 state.json 을 만들지 않는다.
  - 사이드바를 닫으면 분할(h_resizable) 자체를 그리지 않는다(`ResizablePanel::visible(false)` 대신). 분할 상태 엔티티는 남아 다시 열면 폭이 그대로다.
  - 경로 없음은 시작·활성화·창 다시 활성화 때 다시 본다. 실행 중 사라짐(A-16.3)의 즉시 반영은 디스크 감시(R-24, Phase 5)다.
- **Phase 4 로 이월(D-035 ①)**: 폴더별 트리 펼침·선택·스크롤 유지(A-15.2 의 트리 부분), 폴더별 탭과 해제 때 탭 닫기(A-15.1, R-13), 프로젝트 패널 루트 항목 우클릭 `Remove from Project`(I-555). Phase 3 은 폴더마다 Workspace 엔티티(G-002)를 만들고 프로젝트 패널에 루트 한 줄만 그린다.
- **Phase 5 로 이월**: 실행 중 폴더가 사라지는 경우의 즉시 반영(A-16.3, R-24 감시).

## Phase 1·2 다시 돌리기(Phase 3 변경 반영)

- 같은 날 `phase1/d035-rerun/`(실패 0), `phase2/d035-rerun/`(판정 137, 실패 0, 단축키 대조 31줄 불일치 0). 앞선 증거 폴더는 덮어쓰지 않았다.
- 스크립트 변경: Ctrl-K Ctrl-O 가 이제 실제 선택 창을 열어, Phase 1·2 스크립트는 `--dev-pick-folder <취소 파일>` 로 띄우고 state.json 전후 해시를 확인한다. Phase 2 는 File·View 기대 행(새 항목), View 치수 행 번호(구분선 3), 목록 키 번호, 라벨→액션 표를 고쳤고, 자리 표시 폴더 줄 툴팁 확인은 Phase 3 items 로 옮겼다.
- Phase 1 다시 돌리기에서 찾은 결함: ☰ 메뉴가 열린 채 Ctrl+Alt+; 로 사이드바에 갔다가 다시 누르면 닫힌 메뉴의 포커스로 돌아가 포커스가 사라졌다. 돌아갈 자리가 지금 화면에 있을 때만(가운데 Pane 과 그 안, 열린 Dock 의 패널) 돌아가고 아니면 가운데 Pane 으로 가게 고쳤다(Phase 3 keys 사례에 판정 추가).
- 처음 Phase 1 다시 돌리기(고치기 전 스크립트)에서 실제 선택 창이 열려 `D:\projects` 가 등록되고 사용자 폴더에 state.json 이 생겼다. 그 실행 전 사용자 폴더는 비어 있었으므로(확인함) 그 파일을 지웠고, 이후 실행은 모두 state.json 전후 해시가 같다.

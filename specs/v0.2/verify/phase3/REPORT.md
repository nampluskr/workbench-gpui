# v0.2 Phase 3 일치도 검증 보고서 (사이드바 폴더 등록·선택·해제 · R-10~R-16 · R-28)

> 검증자: wg-checker · 일자: 2026-11-01 · 대상: wg-coder 의 Phase 3 증거(`specs/v0.2/verify/phase3/`)와 소스
>
> **방법:** 앱을 다시 띄우거나 증거를 새로 모으지 않았다. 원래 출력(`*-stdout.txt`), `results.json`, `state-*.json`, `remove-disk-*.txt`, 스크린샷, 소스 코드, 01-zed 원문을 직접 대조했다. 스크린샷은 모두 열어 보았고, 선 위치는 스크린샷 픽셀을 읽어 쟀다(아래 §10). 이 보고서만 썼다.
>
> **기준:** SPEC R-10~R-16·R-28(+ Phase 1·2 이월분), PLAN Phase 3 완료 조건, 01-zed `04-APP-SPEC.md` A-10~A-17·A-20·A-22·A-24·A-28, `01-LAYOUT.md` L-33~L-35·L-88, `02-INTERACTION.md` L-226·L-227·L-230·L-231·L-251·I-098~I-100·I-346·I-472·I-473·I-667·I-934·I-935·I-940, `docs/HERDR-DECISIONS.md` D-035·D-036.

## 요약

| 요구 | 판정 | 한 줄 |
| --- | --- | --- |
| R-10 폴더 추가 | **통과** | 진입 3가지는 실제 입력, 실제 OS 선택 창(SendInput)과 주입 둘 다 확인. 상태 표시줄 폴더 추가 버튼의 클릭은 코드로만 확인 |
| R-11 항목 모양·상태 | **통과** | 줄 높이 31·간격 31·폭 299(+테두리 1), 같은 이름 `docs · one`, 경로 없음 비활성색, 툴팁 없음 |
| R-12 활성화·작업 문맥 | **통과 (Phase 3 범위)** | 클릭·Enter·Up/Down 활성화, 폴더마다 Workspace 엔티티 유지, 타이틀 40자. 트리·탭 부분은 Phase 4 이월(D-035 ①) |
| R-13 등록 해제 | **통과 (Phase 3 범위)** | 우클릭 Remove·사이드바 Delete, 활성 이동 규칙, 확인창 없음, **디스크 52줄(크기·시각·SHA-256) 전후 같음**. 루트 우클릭 `Remove from Project`·탭 닫기는 Phase 4 이월 |
| R-14 순서 바꾸기 | **통과** | 메뉴 구성·비활성·한 칸 이동·빈 곳 메뉴 없음, 저장·재시작 복원까지 확인 |
| R-15 예외 상태 | **통과 (Phase 3 범위)** | 빈 상태·경로 없음·안쪽/바깥·32개 스크롤. 실행 중 사라짐의 즉시 반영은 Phase 5(R-24) |
| R-16 표시·포커스 키 | **통과** | Ctrl+Alt+J·Ctrl+Alt+;·Ctrl+B·Ctrl+Shift+E 와 버튼 배치(A-11.8·A-11.9)를 키마다 포커스와 함께 확인 |
| R-28 저장·복원 | **통과** | 등록·순서·활성·폭 저장, 재시작 복원, 알 수 없는 키 보존, 깨진 파일·`.tmp`·version 사례 |
| 이월분: R-3 사이드바 Delete | **통과** | 사이드바에서 Delete → 등록 해제, 디스크 그대로. (루트 Delete 무동작·휴지통은 Phase 4) |
| 이월분: ☰ `Open Folder...`·`Toggle/Focus Folder Sidebar` | **통과** | 구조·글자·키·실행 모두 확인 |
| 이월분: L-251 툴팁 | **통과** | `Open Folder Sidebar` / `Ctrl-Alt-J`, 스크린샷 확인 |
| 이월분: 사이드바 이전 포커스 복귀 | **통과** | A-17.1·A-17.2·I-099·I-100, 메뉴가 열렸다 닫힌 경우까지 |
| Phase 1 R-1 62줄 / Phase 2 R-4~R-9 | **유지** | `d035-rerun/` 두 폴더 모두 불일치 0(§9) |

**불일치(명세 값과 다른 실제 값): 0건.** 다만 허용 오차(±1 px) 끝에 걸린 값 둘과 leader 판단이 필요한 확인 요청 몇 건을 §11 에 따로 적었다.

---

## 1. 증거 개요와 신뢰 점검

- `results.json`: 판정 **114개, 실패 0**, 19개 사례(add 17, keys 20, order 12, items 10, remove 10, switch 10, empty 8, state 5, menus 4, dialog 3, broken 3, scroll 2, tmp 2, version 2, state-restart 2, order-restart 1, quitsave 1, quitnochange 1, title 1). 내가 `results.json` 을 읽어 세어 `EVIDENCE.md` 와 같음을 확인했다.
- 사용자 파일: `results.json` 의 `userFiles.before = {}`, `after = {}`, `restored = true`. 보고서 쓰는 시점에 `%APPDATA%\workbench-gpui` 는 비어 있고 `target\phase3-folders` 시험 폴더도 없다(내가 목록만 확인함).
- 읽을 수 없는 폴더(`locked`)는 시험 폴더에만 ACL 을 걸었고 시험 폴더째 지워졌다(`lockedAcl` 기록, 폴더 없음).
- D-036(고치기 전 Phase 1 스크립트가 실제 선택 창을 열어 `D:\projects` 가 등록되고 state.json 이 생겼다가 지움): 이후 증거(Phase 1·2·3 모두)에서 사용자 `state.json`·`keymap.json` 전후 해시가 `<absent>` → `<absent>` 로 같다(`phase1/d035-rerun/results.json` `userState.unchanged = true`, `phase2/d035-rerun/results.json` `userKeymap`·`userState`, `phase3/results.json`).
- 폴더 선택 방법(R-10 판정 방법이 요구한 "어느 방법을 썼는지"): **두 가지 모두.** `dialog` 사례는 실제 `#32770`(제목 `폴더 선택`) 창을 SendInput 으로 조작(`dialog-open.png` 로 창이 실제 OS 폴더 선택 창임을 직접 확인), 나머지는 `--dev-pick-folder <파일>` 주입(`[dev] pick-folder method=dev-file`). 진입은 모두 실제 키·클릭이다.

## 2. R-10 폴더 추가

| 항목 | 명세 | 실제 | 증거 |
| --- | --- | --- | --- |
| 진입: `Ctrl+K Ctrl+O` | A-13.1·A-18.4 | `folder-add result=added index=0` | `results.json` add·`add-stdout.txt:491` |
| 진입: 사이드바 푸터 폴더 추가 버튼 | A-13.1 | `index=1` 맨 아래에 추가 | `add-stdout.txt:564` |
| 진입: ☰ File → `Open Folder...` | A-13.1 | `index=2`. 메뉴 첫 줄 `Open Folder...|Ctrl-K Ctrl-O` | `add-stdout.txt:782`, `menu-render` |
| 진입: **상태 표시줄** 폴더 추가 버튼 | A-13.1·A-11.9 | 툴팁 `Add Project|Ctrl-K Ctrl-O` 만 입력으로 확인. **클릭 실행은 증거 없음**(코드 `layout.rs:314` `.on_click(dispatch("workspace::Open"))` 로 확인) | `results.json` keys `L-230`, §11-4 |
| 맨 아래에 붙고 활성화 | A-13.1·A-13.8 | `alpha / beta / gamma`, `active=2` | add `순서·활성` |
| 취소 → 아무 일 없음 | A-13.1 | `pick-folder result=cancel`, 개수 3 그대로. 실제 창 Escape 도 `result=cancel, count=0` | `add-stdout.txt:1009`, dialog |
| 같은 경로 다시 고름(대소문자·끝 `\` 다름) | A-13.2·A-16.6 | 입력 `D:\PROJECTS\WORKBENCH-GPUI\TARGET\PHASE3-FOLDERS\ALPHA\` → `result=existing index=0`, 개수 3·활성 0 | `add-stdout.txt:916-917` |
| 없는 경로 / 파일 경로 / 읽을 수 없는 폴더 | A-16.4 | `rejected reason=not-found` / `not-dir` / `read-dir-failed`, 각각 알림 `Cannot open this folder.` 1건, 미등록 | `add-stdout.txt:992-1005`, `add-notification.png` |
| 알림 글자 | `Cannot open this folder.` | 소스 `folders.rs:25 ERR_OPEN` · dev `notification text=` · 스크린샷 글자 모두 같음 | §8 문구 표 |
| 실제 선택 창 | D-6 `rfd` | 창 제목 `폴더 선택`(#32770, 이 프로세스), 경로 입력 + Enter(이동) + 확인 → `result=added index=0 path=…\beta` | `dialog-open.png`·`dialog-navigated.png`·`dialog-after-pick.png` |
| 디스크는 읽기만 | A-13.1 | 등록 전후 디스크 비교는 이 사례에 없음(§11-5). 해제 사례(R-13)의 전후 비교가 같은 폴더들을 다루며 변화 없음. 소스는 등록 검사에 존재·폴더·`read_dir` 만 씀 | `remove-disk-*.txt` |

**판정: 통과.** (불일치 0건)

## 3. R-11 폴더 항목 모양과 상태

| 항목 | 명세 | 실제(측정) | 증거 |
| --- | --- | --- | --- |
| 줄 높이 | 31 (A-11.3·A-32.12) | `folder-row-00..04` 높이 31, y 간격 31(빈틈 없음) | `items-stdout.txt` `layout-box`, `results.json` items |
| 줄 폭 | 사이드바 폭 − 오른쪽 테두리 1 | 299 (사이드바 300) | 같음 |
| 왼쪽 padding 8 · 오른쪽 6 · 아이콘 14 | A-11.3·A-12.1 | 상자 측정은 없다. 소스 상수 `metrics.rs` `SIDEBAR_ROW_PADDING_LEFT 8`, `RIGHT 6`, `ICON_SMALL 14`가 `folders.rs:723-724·748` 에서 쓰인다 | 코드 확인 |
| 이름 한 줄·말줄임 | A-12.1 | 45자 이름 사이드바 줄이 `…` 로 잘림(`title-long-name.png`), `text_ellipsis` | 스크린샷 |
| 활성·hover·누름·키보드 포커스 구분 | A-12.2~A-12.5 | 활성: 연한 파랑(`items-active0.png`), hover: 회색(`items-hover-row2.png`), 포커스 커서: 둘레 1px 테두리(`items-keyboard-focus-row1.png`) — 서로 구별된다. 누름 상태는 정지 화면으로 잡지 못했다(색은 판정 대상 아님) | 스크린샷 |
| 같은 이름 → `docs · guides` 꼴 | A-12.6 | `docs · one` / `docs · two` (dev `folder-row name=`, 화면 일치) | `items-stdout.txt:6-7` |
| 경로 없음 → 비활성 색 | A-12.7 | `vanished` 줄 이름·아이콘이 연한 회색, dev `missing=true` 이 줄만 | `items-active0.png`, `items-stdout.txt:8` |
| 툴팁 없음 | A-12.8·L-231 | 줄 위에 2초 두어도 `tooltip-shown` 0건 | `results.json` items |
| 안쪽·바깥 폴더 독립 | A-16.5 | `alpha` 와 `alpha\inner` 가 별개 항목 | items |

**판정: 통과.** 색 토큰 값은 테마 매핑 전이라 판정하지 않았다(SPEC R-11). 확인한 관찰은 §11-8.

## 4. R-12 폴더 활성화와 작업 문맥

| 항목 | 명세 | 실제 | 증거 |
| --- | --- | --- | --- |
| 클릭으로 활성화 | A-13.3 | `folder-activate index=1 … created=true`, 포커스 사이드바 그대로(A-15.6) | `switch-stdout.txt`, `switch-beta.png` |
| Up/Down 이동 후 Enter | A-13.3·A-17.3·A-17.4 | `Down, Enter → active=2`, `Up×2, Enter → active=1` | `results.json` switch |
| 프로젝트 패널이 그 폴더 루트 하나로 바뀜 | A-13.3 | 패널 맨 위에 `beta` 한 줄(열린 폴더 아이콘) — 스크린샷으로 확인, 타이틀도 `beta` | `switch-beta.png` |
| 폴더마다 Workspace 엔티티를 두고 전환해도 유지 | A-15.2·A-23.2·G-002 | beta 처음 활성 `EntityId(15v1) created=true`, alpha 로 갔다 beta 로 다시: **같은 엔티티 `created=false`**, 엔티티 수 2 | `results.json` switch(`folder-activate` 줄) |
| 타이틀 바 폴더 이름 40자 말줄임 | L-88·A-15.5 | 45자 이름 → 타이틀 `a`×40 + `…` (dev `title text=`, 스크린샷에서 확인) | `title-long-name.png` |
| 폴더 없음 → `Open Recent Project`(Muted) | A-13.9·L-227·R-12 | dev `title text=Open Recent Project placeholder=true`, 스크린샷에서 글자색이 일반 이름보다 옅음 | `empty-screen.png` |
| 눌러도 아무 일 없음, 툴팁 `Recent Projects` | D-16·L-226 | 소스 `title_bar.rs:111` 툴팁 문구. 클릭 동작 없음은 코드로만 확인 | 코드 |
| **폴더별 트리 펼침·선택·스크롤, 폴더별 탭** | A-15.1·A-15.2 | **Phase 4 이월**(D-035 ①). Phase 3 은 엔티티 유지를 dev 출력으로 판정 | §7 |

**판정: 통과 (Phase 3 범위).**

## 5. R-13 등록 해제 — 디스크 비교

### 5.1 진입 경로

| 진입 | 명세 | 실제 | 증거 |
| --- | --- | --- | --- |
| ① 사이드바 항목 우클릭 → `Remove` | I-935·A-13.4 | `context-menu-exec item=Remove via=click` → `folder-remove … via=context-menu` 세 번(beta, gamma, alpha) | `remove-stdout.txt:571-573, 794-796, 929-931` |
| ② 사이드바 포커스에서 `Delete` | A-13.4 ②·A-17.5 | `action-handled name=project_panel::RemoveFromProject … focus=sidebar` → `folder-remove … via=delete-key`(커서 항목 `one\docs`) | `remove-stdout.txt:656-657` |
| ③ 프로젝트 패널 루트 우클릭 `Remove from Project` | I-555 | **Phase 4 이월**(D-035 ①) | §7 |

### 5.2 활성 이동·확인창

| 항목 | 명세 | 실제 |
| --- | --- | --- |
| 활성 폴더 해제 → 아래 항목 활성 | A-13.5 | beta(가운데·활성) 해제 → `folder-activate index=1 id=…002`(gamma) |
| 맨 아래 활성 해제 → 위 항목 활성 | A-13.5 | gamma(맨 아래·활성) 해제 → `folder-activate index=0`(alpha) |
| 활성이 아닌 항목 해제 → 활성 그대로 | A-13.4 | `Delete` 로 docs 해제, 활성(gamma) 그대로 |
| 하나도 없으면 빈 상태 | A-13.5·A-16.1 | `count=0`, `project-empty-text` 경계 있음, `remove-all-empty.png` |
| 확인창 없음 | A-14.4 | 해제 직후 이 프로세스의 대화상자 창 0개(`FindDialog`) |
| 폴더 하나면 메뉴에 Remove 만 | I-934 | `context-menu-open rows=Remove|enabled` |
| 해제한 폴더의 탭을 닫음 | A-13.4 | **Phase 4 이월** — v0.2 Phase 3 에는 폴더별 탭이 없다 |

### 5.3 디스크 전후 비교 (직접 확인)

- 시험 방식(`tools/verify-v02-phase3.ps1` remove 사례, 788~830행): 해제 **전** 시험 루트 전체를 `경로|크기|수정시각|SHA-256`(폴더는 `|dir`) 로 목록화 → alpha·beta·gamma·`one\docs` 네 폴더를 위 ①② 경로로 **모두** 해제 → **후** 다시 목록화해 비교.
- 내가 직접 `diff remove-disk-before.txt remove-disk-after.txt` 를 돌렸다: **차이 없음(IDENTICAL)**, 두 파일 모두 52줄. 해제한 네 폴더가 모두 목록에 있다(`\alpha\readme.txt|19|…|32532A…`, `\alpha\inner\readme.txt|25|…|092FD8…`, `\beta\readme.txt|18|…|9185DB…`, `\gamma\readme.txt|19|…|0037BB…`, `\one\docs\readme.txt|22|…|28914…`, 그리고 `\many\m00..m31`·`\locked` 등).
- 같은 실행의 `remove-state.json`: `{"version":1,"windows":[{"folders":[],"active_folder_id":null}]}` — 모두 해제 뒤 상태가 저장된다.

**판정: 통과 (Phase 3 범위).** 디스크는 그대로다(A-14.3).

## 6. R-14 순서 바꾸기

| 항목 | 명세 | 실제 | 증거 |
| --- | --- | --- | --- |
| 메뉴 구성 | `Move Up`, `Move Down`, 구분선, `Remove` (I-667) | `context-menu-open rows=Move Up|enabled  Move Down|enabled  ---  Remove|enabled`, 스크린샷에서 글자 일치 | `remove-context-menu.png` |
| 맨 위: Move Up 비활성 / 맨 아래: Move Down 비활성 | I-934·I-940 | `Move Up|disabled …` / `… Move Down|disabled …`, 스크린샷에서 Move Up 이 옅게 | `order-menu-top.png` |
| 비활성 항목을 눌러도 아무 일 없음 | I-940 | 실행 0, 순서 그대로, 메뉴 그대로 | `results.json` order |
| 한 칸씩 이동 | A-13.6 | alpha Move Down → `beta / alpha / gamma`, gamma Move Up → `beta / gamma / alpha`, 메뉴 키 Down·Enter → `gamma / beta / alpha` | order |
| 메뉴 닫힘·포커스 | I-519·I-309 | Escape → `context-menu-close reason=cancel`, 실행 뒤 포커스 `center` | order |
| 빈 공간·폴더 추가 버튼 우클릭 → 메뉴 없음 | I-937·I-939 | `context-menu-open` 0건 | order |
| 메뉴 모양 | I-313·I-318 | 상자 폭 202(≥ 202), 구분선 높이 1·다음 항목까지 13(위아래 6) | order |
| 한 폴더 → Move 항목 없음 | I-934 | 위 R-13 표 | remove |
| 저장·복원 | A-13.6·A-22.2 | `order-state.json` `folders` 순서 gamma, beta, alpha(활성 alpha id `…000`). 다시 시작 후 `folder-row index=0 gamma, 1 beta, 2 alpha(active=true)` | `order-state.json`, `order-restart-stdout.txt:5-7`, `order-restart.png` |
| 끌어서 바꾸기 없음 | A-12.11 | 만들지 않음. `folders.rs` 에 drag 처리 코드가 없다(`grep` 결과 0건) | 코드 |

**판정: 통과.**

## 7. R-15 예외 상태 · D-035 ① 이월 목록

| 항목 | 명세 | 실제 | 증거 |
| --- | --- | --- | --- |
| 폴더 없음 | A-16.1 | 사이드바 목록 0, 패널에 문구와 `Open Project` 버튼 하나(`Clone Repository` 없음), 버튼 → 선택 창 → 등록·활성(`folder-add result=added index=0`), 타이틀 `Open Recent Project` | `empty-screen.png`, `empty-after-open-project.png` |
| 경로 없는 폴더를 활성화 | A-16.2 | 트리 자리에 `This folder no longer exists.` + `Remove` 버튼, `Remove` → 해제·아래 항목(inner) 활성 | `items-missing-active.png`, `results.json` items |
| 시작할 때 경로가 없다 | A-16.2·R-28 | `state.json` 에 있는 `vanished` 가 시작에 `missing=true` 로 읽힘(사용자 제공 파일, §11-9) | `items-stdout.txt:8` |
| 안쪽·바깥 허용 | A-16.5 | 둘 다 독립 항목 | items |
| 개수 제한 없음·세로 스크롤 | A-16.7 | 32개 등록, 휠 → `sidebar-scroll offset_y=-234`, 스크린샷에서 위쪽이 잘리고 `m31` 까지 보임 | `scroll-after-wheel.png` |
| 실행 중 사라짐 | A-16.3 | **Phase 5 이월**(R-24 감시). 시작·활성화·창 다시 활성화 때만 다시 본다(PROGRESS) | §7 |

**판정: 통과 (Phase 3 범위).**

### D-035 ① 로 Phase 4 이월된 항목 (판정하지 않음)

| 항목 | 원문 | 이월 이유 |
| --- | --- | --- |
| 폴더별 트리 펼침·선택·스크롤 유지 | A-15.2·R-12 | 트리가 Phase 4. Phase 3 은 루트 한 줄만 그림 |
| 폴더별 열린 탭, 해제 때 탭 닫기 | A-15.1·A-13.4·R-13 | 탭이 Phase 4 (D-9·D-18) |
| 프로젝트 패널 루트 우클릭 `Remove from Project` | I-555·R-13 ③ | 트리 루트 항목이 Phase 4 |
| 루트 선택 상태에서 `Delete` 무동작, 휴지통 | A-14 아래 목록·R-3 | Phase 4 (R-3 이월분 중 사이드바 쪽만 이번에 판정) |
| 실행 중 폴더 사라짐의 즉시 반영 | A-16.3·R-24 | Phase 5 |

## 8. 문구 대조 (글자 단위)

앱 소스의 상수(`grep`), dev 출력, 스크린샷의 세 곳을 원문 글자와 맞췄다.

| 문구 | 원문 | 앱 소스 | dev 출력 / 화면 | 판정 |
| --- | --- | --- | --- | --- |
| 빈 상태 안내 | `Choose one of the options below to use the Project Panel` (A-16.1) | `folders.rs:802` 같음 | `empty-screen.png`(두 줄로 줄바꿈) 같음 | 일치 |
| 빈 상태 버튼 | `Open Project` (A-16.1) | `folders.rs:803` | 화면 같음 | 일치 |
| 경로 없음 | `This folder no longer exists.` (A-16.2) | `folders.rs:822` | `items-missing-active.png` 같음 | 일치 |
| 경로 없음 버튼 | `Remove` | `folders.rs:823` | 화면 같음 | 일치 |
| 등록 거부 알림 | `Cannot open this folder.` (A-16.4) | `folders.rs:25` | `notification text=`·`add-notification.png` 같음 | 일치 |
| 타이틀(폴더 없음) | `Open Recent Project` (L-227·A-13.9) | `folders.rs:904`·`title_bar.rs:113` | `title text=Open Recent Project placeholder=true` | 일치 |
| 사이드바 우클릭 메뉴 | `Move Up` / `Move Down` / `Remove` (I-934·I-940·I-935) | `folders.rs:480-487` | `context-menu-open rows=` 같음 | 일치 |
| ☰ File | `Open Folder...` (I-346, 점 셋) | `app_menu.rs:124` | `menu-render … Open Folder...|Ctrl-K Ctrl-O  ---  Close Window|Ctrl-Shift-W` | 일치 |
| ☰ View | `Toggle Folder Sidebar`·`Focus Folder Sidebar` (I-472·I-473; `†` 는 "우리가 추가한 항목" 표시이지 글자가 아니다, 02 459행) | `app_menu.rs:184-185` | `menu-render` 와 `menus-view.png` 같음 | 일치 |
| 상태 표시줄 툴팁(사이드바 닫힘) | `Open Folder Sidebar` + `Ctrl-Alt-J` (L-251·L-270) | `layout.rs:300` | `tooltip` 행 `Open Folder Sidebar|Ctrl-Alt-J`, `keys-tooltip-open-folder-sidebar.png` | 일치 |
| 폴더 추가 툴팁 | `Add Project` (L-230) + 우리 키 `Ctrl-K Ctrl-O` (I-029) | `layout.rs:92·311` | `Add Project|Ctrl-K Ctrl-O` (푸터·상태 표시줄 모두) | 일치 |
| 타이틀 이름 버튼 툴팁 | `Recent Projects` (L-226) | `title_bar.rs:111` | Phase 2 R-7 에서 판정됨, `d035-rerun` 에서 그대로 | 일치 |
| state.json 읽기 오류 알림 | **원문에 문구 없음**(A-24.6 은 "알림 한 줄"만). D-035 ②: `Could not read the window state.` (우리 문구) | `state/mod.rs:27` | `broken-notification.png`·`notification text=` 같음 | **우리 문구와 일치** (원문 문구 아님 — 보고서에 밝힘) |
| state.json 저장 실패 알림 | `Could not save the window state.` (A-24.4) | `state/mod.rs:29` | 실패 경로는 증거로 시험되지 않음(§11-6) | 소스 문구 일치 |

## 9. R-16 표시·포커스 키와 Phase 1·2 재확인

### 9.1 R-16

| 키·동작 | 명세 | 실제(포커스 포함) | 증거 |
| --- | --- | --- | --- |
| 시작 상태 | A-11.7 | 사이드바 열림, 포커스 center | `keys-stdout.txt:1` |
| `Ctrl+Alt+J`, center 에서 | A-17.1 | `sidebar open=false … focus=center` (닫힘, 포커스 그대로) | `keys-stdout.txt:558` |
| `Ctrl+Alt+J`, 닫힘에서 | A-17.1 | `open=true focus=sidebar` (열 때 포커스 이동) | `:822` |
| `Ctrl+Alt+J`, **사이드바 포커스에서** | A-17.1·I-100 | 키 컨텍스트 `Root > Workspace > Sidebar` → `open=false focus=center` (이전 위치) | `:888-890` |
| `Ctrl+Alt+;`, 닫힘에서 | A-17.2 | 열고 `focus=sidebar` | `:943-945` |
| `Ctrl+Alt+;`, 사이드바 포커스에서 | A-17.2·I-099 | `open=true focus=center`(이전 포커스로, 닫지 않음) | `:1008-1010` |
| 패널 → 사이드바 → 다시 `Ctrl+Alt+;` | I-099 | 이전 포커스가 `project_panel` 이므로 패널로 복귀 | `:1015-1021` |
| `Ctrl+Shift+E` 패널에서 | A-17.8·I-098 | `focus=center`, Dock 은 열린 채 | `:1023-1024` |
| `Ctrl+B` | A-17.7 | Dock 닫힘, 이어 `Ctrl+Shift+E` → Dock 열고 `project_panel` 포커스 | `:1026, 1085-1086` |
| 사이드바 닫힘 상태 표시줄 순서 | A-11.9 | 사이드바 토글 x=4 → 폴더 추가 x=30 → 프로젝트 패널 토글 x=56 | `results.json` keys, `keys-sidebar-closed.png` |
| 사이드바 열림 푸터·상태 표시줄 | A-11.8 | 푸터: 토글 x=4(왼쪽), 폴더 추가 x=273~295(오른쪽 끝, 테두리 1 앞). 상태 표시줄 왼쪽: 프로젝트 패널 토글만 | `items-stdout.txt` boxes |
| 푸터·상태 표시줄 사이드바 토글 누름 | A-11.8·A-11.9 | 푸터 → 닫힘, 상태 표시줄 → 열림·포커스 사이드바 | keys |
| 푸터 치수 | A-11.4·L-35 | 높이 31(위 테두리 1 + 30), 버튼 22, padding 4, gap 4, 아이콘 14 | boxes |
| 사이드바 맨 위 줄 | A-11.2 | 높이 32. 아래 선의 높이 위치는 §10 | boxes |
| 메뉴가 열린 채 `Ctrl+Alt+;` → 사이드바 → 다시 | I-309 변형 | 돌아갈 자리(메뉴)가 닫혔으므로 center(`keys-stdout.txt:1342-1349`) — Phase 1 재실행에서 찾은 결함의 수정 확인 | keys |

**판정: 통과.**

### 9.2 Phase 1·2 재확인 (`d035-rerun/`)

- **Phase 1 R-1 62줄:** `phase1/d035-rerun/base-stdout.txt` 의 내장 바인딩 `[dev] binding seq=1 … source=builtin` 54줄이 `d033-rerun` 과 `diff` 결과 없이 같다. `r1-expected.tsv` 도 `d033-rerun` 과 같다. `r1-bindings.md`·`results.json`: 기대 62, 일치 62, 내장 54, 표 밖 0, `failures: []`, `foreignKeys: []`, 9개 사례 키 판정 70개 모두 통과. 사용자 keymap.json·state.json 전후 `<absent>`.
- **Phase 2:** `phase2/d035-rerun/results.json` 137개 판정 모두 통과, R-5 대조표 **31줄, 불일치 0**.
  - `d033-rerun`(136개)과 항목별 비교: 옛 판정 가운데 새 쪽에 없는 것은 목록 키 6개의 이름(항목 번호가 바뀜: 항목이 늘어 `→ 항목 2` 가 `→ 항목 4` 등으로)과 `sidebar-folder-row-label 툴팁 없음`(Phase 3 items 사례로 옮김, §3)이고, 새로 생긴 것은 같은 목록 키 판정 8개(down·up 포함, 항목 번호만 달라짐)다. 나머지의 `got` 이 달라진 것은 시각, 지연 ms(`500~515`), View·File 메뉴 줄(새 3항목), 메뉴 최소 폭(`202→236`, View 메뉴가 넓어져 최소값 202 이상이면 통과인 판정), chord 시간 초과 `dt 1160→1121` 뿐이다.
  - 툴팁 상자 `box`·문구·뒤집기 10개는 `d033-rerun` 과 모두 같다.
  - `r5-shortcuts.md` 는 `d033-rerun` 과 비교해 새 행 7줄(`Open Folder...`, `Toggle/Focus Folder Sidebar` 가 menu·reload·shadow 사례에 나옴)만 더해졌다. 새 행의 화면·키맵 결과·원문(`Ctrl-K Ctrl-O`, `Ctrl-Alt-J`, `Ctrl-Alt-;`)이 일치한다. (표기 흠은 §11-7.)
  - R-4(reload 6개), R-6~R-9 판정 값이 그대로다.

## 10. R-28 저장·복원 · 파일 형식

| 항목 | 명세 | 실제 | 증거 |
| --- | --- | --- | --- |
| 등록 저장 | A-22.2~A-22.6 | `add-state.json`: `folders` 3개(alpha, beta, gamma 순), 각 `id` UUID v4(`0435fb61-8d4a-4597-8353-4045da14d760` 등, 판정이 정규식 `xxxxxxxx-xxxx-4xxx-[89ab]xxx-…` 로 확인), `added_at` ISO 8601 UTC(`2026-11-01T10:02:36Z`), `active_folder_id` = alpha 의 id | `add-state.json` |
| 경로 정규화 | A-28 | 저장 경로 `D:\projects\workbench-gpui\target\phase3-folders\alpha`(드라이브 대문자·끝 `\` 없음). 입력 `D:\PROJECTS\…\ALPHA\` 도 같은 항목으로 비교됨. A-28.7~13 표는 `state/path.rs` 단위 테스트가 소스에 있다(입력→기대값이 원문 표와 같음, 실행 결과는 PROGRESS 의 "cargo test 29개 통과"를 따름) | `path.rs:107-119` |
| 활성 변경 저장 | A-22.6 | `switch-state.json` 에서 `active_folder_id` = beta | `results.json` switch |
| 순서 변경 저장 | A-13.6 | `order-state.json` 에서 gamma, beta, alpha | R-14 |
| 사이드바 폭 저장 | A-11.1·R-28 | 폭 끌기 → `state-save result=written`, `state-after-resize.json` `"sidebar":{"width":419.0}`, 화면 폭 419 와 같음 | `state-after-resize.json` |
| 알 수 없는 키 보존 | A-20 | 최상위 `zz_unknown_root`, 창 `zz_unknown_window`, 폴더 `zz_unknown_folder: 42`, 사이드바 `zz_unknown_sidebar` 가 저장 뒤에도 그대로 | `state-after-resize.json` |
| **다시 시작** — 폭·목록·활성 복원 | R-28 | `state-restart` 사례: `folder-row index=0 alpha active=false, index=1 beta active=true`, 사이드바 폭 419(`results.json`), 스크린샷에서 사이드바가 넓게 복원됨. `order-restart`: 순서와 활성 alpha 복원 | `state-restart-stdout.txt:3-6`, `state-restart.png`, `order-restart.png` |
| 경로가 없어진 폴더 | A-16.2·R-28 | 시작에 `missing=true` + 비활성 색(R-15) | `items-stdout.txt:8` |
| 깨진 파일 | A-24.6·D-14 | 시작 `state-load source=empty … bad_moved_to=…state.json.bad-20261101-100428`, 빈 상태, 알림 `Could not read the window state.`, `.bad-…` 1개·`state.json` 없음 | `broken-stdout.txt:3-4`, `broken-notification.png` |
| 깨진 `state.json` + 올바른 `.tmp` | A-24.5 | `source=tmp`, gamma 복원, 깨진 파일은 `.bad` 로, 알림 | `tmp-stdout.txt:3-6` |
| `version` 이 앱보다 큼 | A-24.7 | `read_only=true`, 폴더 읽음, 바꿔도 쓰지 않음 `state-save result=skipped-read-only`, 파일 해시 같음 | `version-stdout.txt:3, 562` |
| 종료 직전 저장 | A-24.3 | Move Down 직후 Ctrl+Q → 끝나기 전 `state-save result=written`, 파일에 `beta / alpha` | `quitsave-stdout.txt:634`, `quitsave-state.json` |
| 변경 없이 끝냄 | A-24.3 | `state.json` 을 만들지 않음(판단, §11-가) | `quitnochange-stdout.txt` |
| 그 밖의 A-22 항목은 쓰지 않음 | D-10 | `state.json` 에 `recent`, `left_dock`, `window`, `workspaces` 등이 없다 | `add-state.json` 등 |

- **`state.json` 재시작 전후 비교 요약:** 재시작 전(`order-state.json`/`state-after-resize.json`) 에 쓴 순서·활성·폭이 재시작 뒤 `folder-row`·폭 판정으로 그대로 나온다. 사용자 폴더의 `state.json` 은 모든 실행에서 시작과 끝에 `<absent>` 다.
- **원문과 다른 점·시험되지 않은 A-24 세부(코드 확인만):** A-24.2 의 500ms 묶음(`SAVE_DEBOUNCE`, `folders.rs:27`), A-24.4 의 50ms×3 재시도·저장 실패 알림(`state/mod.rs:36-37, 270`), A-24.6 의 3개 보관·`-2` 접미(`move_bad`, 단위 테스트 `keeps_three_bad_files`), A-24.1 의 쓰기 순서(`win.rs` FFI). 실제 실행에서 실패 경로를 만들지는 않았다.

**판정: 통과.**

### 선 위치 측정 (스크린샷 픽셀)

`empty-screen.png`(2880×1704, 배율 2)를 직접 읽어 잰 값이다.

| 선 | 물리 px | 논리 px | 비고 |
| --- | --- | --- | --- |
| 사이드바 맨 위 줄 아래 선 | y 62~63 | **31~32** | `sidebar-header` 상자 0,0,299,32 의 안쪽 맨 아래 |
| 타이틀 바 아래 선(사이드바 오른쪽) | y 64~65 | **32~33** | `body` 가 y=33 에서 시작 |
| 사이드바 푸터 위 선 | y 1642~1643 | 821~822 | 상태 표시줄 위 선(1642~1643)과 **같은 줄** |
| 사이드바 오른쪽 경계(패널 높이) | x 598~601 | 299~301 (**폭 2**) | Dock 오른쪽 경계는 폭 1(1078~1079) |

## 11. 불일치 · 확인 요청 · 관찰

**명세 값과 다른 실제 값(불일치): 0건.**

### 허용 오차(±1 px, A-31.1) 끝에 걸린 값 — 통과로 보되 알린다

1. **A-11.2 "사이드바 맨 위 줄 아래 선이 타이틀 바 아래 선과 한 줄로 이어진다"**
   - 명세 값: 두 선이 같은 높이에서 이어진다. 높이 32(= 타이틀 바 높이).
   - 실제 값: 사이드바 선이 논리 y=31~32, 타이틀 바 선이 y=32~33 으로 **1 논리 px 단차**. 사이드바 첫 줄은 y=32 에서 시작(타이틀 바 선을 사이드바 쪽에서는 안쪽에 둠).
   - 증거: `empty-screen.png` 픽셀(위 표), `items-stdout.txt` `sidebar-header`·`title-bar`·`work-area`.
   - 판정: ±1 안이라 R-11·R-16 판정에는 영향을 주지 않았다. "한 줄로 이어진다" 문구를 엄격히 읽으면 단차가 맞지 않는다. leader 가 허용 오차 안으로 둘지 정한다.
2. **A-11.5 "오른쪽 테두리 1px"** — 사이드바와 가운데(프로젝트 패널) 사이 경계가 논리 폭 2(299~301)로 그려진다(Dock 오른쪽 경계는 1). 사이드바를 닫은 화면(`keys-sidebar-closed.png`)은 폭 1. A-11.12 가 핸들 모양을 미확인으로 둔 부분이라 핸들 그리기 탓일 수 있다. 원인은 확인하지 않았다. ±1 안.

### leader 판단이 필요한 것

- **§11-가 A-24.3 종료 직전 쓰기:** 원문은 "종료 직전에 한 번 더 쓴다", D-035 ③ 은 A-24.1~A-24.7 을 "그대로 적용". 구현은 **쓰지 않은 변경이 있을 때만** 쓴다(바뀐 것 없이 끝내면 `state.json` 을 만들지 않음, `quitnochange` 증거). PROGRESS 에 판단으로 적혀 있다. R-28 의 정해진 결과는 이 부분을 요구하지 않아 판정에는 영향이 없다. 원문대로 항상 쓸지 정해 주기 바란다.
- **§11-나 문서 내부 충돌(앱 명세):** A-16.1 은 "타이틀 바 이름은 앱 이름", A-13.9·L-227·SPEC R-12·D-16 은 폴더가 없을 때 `Open Recent Project`(Muted). 구현과 이 판정은 SPEC R-12 를 따랐다(통과). 04 의 A-16.1 문장은 정정 대상일 수 있다.

### 판정 범위·증거의 빈틈

3. **A-11.1 폭 범위 200~800:** 기본 300(시작 폭 판정)과 끌어서 바꾼 값 저장(419)은 증거가 있다. 최소 200·최대 800 의 막힘은 소스(`mod.rs:412` `size_range(SIDEBAR_MIN..SIDEBAR_MAX)`)로만 확인했다.
4. **상태 표시줄 폴더 추가 버튼 클릭**(R-10 진입 중 하나)은 툴팁 판정뿐이고 선택 창이 열리는 입력 증거는 없다. 소스는 푸터 버튼과 같은 `dispatch("workspace::Open")` 다.
5. **R-10 "디스크는 읽기만 한다"** 는 등록 사례에서 폴더 목록 전후를 따로 비교한 증거가 없다(R-13 의 비교가 같은 폴더들에 대해 무변화를 보여 준다).
6. **A-24.2 500ms 묶음·A-24.4 저장 실패 경로·A-24.6 `-2`/3개 보관**은 소스·단위 테스트 소스로만 확인했고 앱 실행으로 시험하지 않았다(R-28 판정 방법의 사례 범위 밖).
7. **`phase2/d035-rerun/r5-shortcuts.md` 표기 흠:** `shadow` 사례의 새 두 행(`Toggle Folder Sidebar`, `Focus Folder Sidebar`)의 "01-zed 원문" 칸에 `가려짐 → 없음` 이 적혀 있으나 화면·키맵 결과는 `Ctrl-Alt-J`·`Ctrl-Alt-;` 로 가려지지 않은 값이다. 판정은 일치로 맞다. 열 내용이 틀린 표기일 뿐이다.
8. **상태 표시 관찰(R-11 색은 판정 대상 아님):**
   - 활성인 줄 위에 마우스가 있으면 hover 색이 활성 색을 덮는다(`switch-beta.png`·`items-missing-active.png`·`remove-context-menu.png`). 활성 줄 단독 색은 `items-active0.png`. 명세는 겹친 경우를 정하지 않았다.
   - 마우스로 눌러 활성화한 줄에도 키보드 포커스 테두리(1px)가 보인다(A-12.5 "키보드 포커스"는 판단).
   - 휠 스크롤 뒤(`scroll-after-wheel.png`) m12 줄의 글자만 hover 색(배경 없음)이고 마우스 아래 m19 줄에 배경이 있다. 스크롤 중 hover 갱신이 한 박자 늦는 것으로 보인다.
   - 긴 폴더 이름은 프로젝트 패널 루트 줄에서 말줄임 없이 잘린다(`title-long-name.png`). 트리는 Phase 4 이므로 판정하지 않는다.
9. **경로 없음 사례의 만든 방법:** `vanished` 는 "등록 뒤 이름 바꾸기"가 아니라 처음부터 존재하지 않는 경로를 담은 `state.json` 으로 시작해서 만들었다. 시작 때 확인(A-16.2)은 같다. 활성화·창 다시 활성화 때 확인하는 경로는 증거로 따로 시험되지 않았다.

## 12. PLAN Phase 3 완료 조건

| 조건 | 상태 | 비고 |
| --- | --- | --- |
| R-10~R-16, R-28 이 SPEC 판정 방법대로 통과 | **충족** | 이 보고서(트리·탭 의존 부분은 D-035 ① 로 Phase 4, A-16.3 은 Phase 5) |
| `specs/v0.2/verify/phase3/` 에 검증 보고서, 등록 해제 뒤 디스크 비교, 재시작 전후 `state.json`·복원 결과 | **충족** | §5.3, §10 |
| wg-reviewer 의 Phase 3 리뷰 결과가 PROGRESS 에 기록 | **미충족** | `specs/v0.2/PROGRESS.md` Phase 3 항목 끝에 "Phase 3 리뷰(wg-reviewer)와 커밋은 아직이다"라고 적혀 있다. PLAN 순서(리뷰 → checker)와 달리 리뷰 전 검증이다. leader 가 순서를 확인한다 |
| Phase 3 커밋 | **미충족**(확인 시점) | `git log` 최신은 Phase 2 커밋 `1e900dd`. Phase 3 변경은 stage 상태 |
| (참고) Phase 1·2 회귀 | 충족 | `d035-rerun` 두 폴더 모두 실패·불일치 0 |

## 13. 판정하지 못한 것 · 다른 Phase 로 넘긴 것 (한곳에 정리)

- **Phase 4 이월(D-035 ①):** 폴더별 트리 펼침·선택·스크롤(A-15.2), 폴더별 탭·해제 때 탭 닫기(A-15.1·A-13.4), 루트 우클릭 `Remove from Project`(I-555), 루트에서 `Delete` 무동작·휴지통(R-3 이월분의 나머지).
- **Phase 5 이월:** 실행 중 사라진 폴더의 즉시 반영(A-16.3, R-24).
- **판정 대상 아님:** 색 토큰 값(R-11, 테마 매핑 전), 누름(active) 상태의 정지 화면.
- **코드·단위 테스트 소스로만 확인:** 폭 200~800 막힘, 행 padding 8/6·아이콘 14, A-24.2·A-24.4·A-24.6 의 일부, A-28.7~13 표.
- **내가 쓴 파일은 이 보고서 하나다.** 코드·다른 문서·증거는 고치지 않았다.

---

# 2회차 — 리뷰 1회차 수정(D-037·D-038) 뒤 재검증

범위: R-10~R-16·R-28 다시 판정, Phase 1·2 유지 확인. 1회차 절(위)은 고치지 않았다. 증거는 새로 모으지 않고 `d037-rerun/`(EVIDENCE.md, before/, after-targeted/, after/, guard-before/, guard-after/)와 `phase1/d037-rerun/`, `phase2/d037-rerun/` 를 읽었다. 앱은 돌리지 않았다. 코드는 `src/ui/folders.rs`(save_now 254, flush_save 925), `src/ui/mod.rs`(on_quit 135, on_close_window 142, on_app_quit·on_window_should_close 555~568), `src/state/path.rs`(compare_key 77, 단위 시험 174~)를 읽었다. 원문은 04-APP-SPEC A-17.1·A-24.3·A-24.4·A-28.5, SPEC R-16·R-28, D-037·D-038 이다.

## 2-0. 2회차 요약

| 요구 | 1회차 | 2회차 | 근거 |
| --- | --- | --- | --- |
| R-10 폴더 추가 | 통과 | **통과** (중복 판정은 A-28.5 원문대로. 이 볼륨과의 차이는 §2-9-가) | §2-5 |
| R-11 항목 모양 | 통과 | **통과** | §2-7 |
| R-12 활성화 | 통과(Phase 3 범위) | **통과** (Phase 3 범위) | §2-7 |
| R-13 등록 해제 | 통과(Phase 3 범위) | **통과** (Phase 3 범위, 디스크 전후 56줄 같음) | §2-7 |
| R-14 순서 | 통과 | **통과** | §2-7 |
| R-15 예외 상태 | 통과(Phase 3 범위) | **통과** (Phase 3 범위) | §2-7 |
| R-16 표시·포커스 키 | 통과 | **통과** (닫을 때 포커스가 사이드바에 없으면 가운데 Pane 추가 확인) | §2-6 |
| R-28 저장·복원 | 통과 | **통과** (종료 저장 3경로·저장 실패 뒤 재저장 추가 확인) | §2-3·§2-4 |
| Phase 1 R-1~R-4 | 유지 | **유지** | §2-8 |
| Phase 2 R-4~R-9 | 유지 | **유지** | §2-8 |

- **명세 값과 다른 실제 값: 0건.** 1회차의 허용 오차 끝 값 2건(헤더선 1px 단차, 경계선 폭 2)은 이번 수정과 무관하고 이번 증거에서 다시 재지 않았다. 1회차 판정 그대로다.
- 새 증거 `after/` 는 판정 **122개, 실패 0**(23사례). 1회차 114개는 같은 사례·같은 판정 이름으로 모두 남아 통과했고, 새 판정은 8개다(§2-1).

## 2-1. 증거 신뢰 점검

- `after/results.json`: 판정 122, 실패 0, errors 없음, `userFiles` 전후 비어 있고 `restored: true`. `before/`·`after-targeted/` 도 `userFiles` 전후 비어 있고 `restored: true`.
- 1회차(114)와 2회차(122)를 `사례|ID|내용` 으로 맞춰 보았다. 1회차에만 있는 판정은 0, 2회차에만 있는 판정은 8이다: `keys` D-037 ⑥ 1, `closesave` 2(보내기 시간·저장), `xclosesave` 2, `savefail` 2(A-24.4·종료 뒤 재저장), `sigma` 1.
- 같은 판정의 실제 값이 달라진 것은 실행마다 달라지는 값(UUID, `added_at`, `.bad-` 파일 이름의 시각)과 두 가지뿐이다: `quitsave` 의 저장 줄 수(§2-3 관찰), 디스크 목록 줄 수(52 → 56, §2-7).
- `before/` 와 `after-targeted/` 는 **같은 사례 5개(`closesave, xclosesave, savefail, sigma, keys`), 판정 28개**다. 고치기 전은 실패 5(키 ⑥ 1, 종료 저장 2, 저장 실패 1, σ 1), 고친 뒤는 실패 0. 나머지 23개 판정은 양쪽 모두 통과다. 그러므로 새 판정은 수정을 가려낸다(고치기 전 실패·고친 뒤 통과).
- 고치기 전 exe 가 stage 된 리뷰 대상 트리와 같은지는 확인하지 못했다(exe 는 증거에 없고 빌드 기록만 있다). 실패 내용이 리뷰 지적과 같은 모양이라는 점만 확인했다.

## 2-2. D-037 6건 판정 요약

| 지적 | 수정 | 판정 | 확인한 곳 |
| --- | --- | --- | --- |
| ① 종료 저장 | `flush_save`: Close Window·창 닫기 버튼·Quit 에서 창 제거·종료 전에 먼저 씀 | **해결** | §2-3 |
| ② 저장 실패 처리 | 성공했을 때만 `saved_generation` 올림 | **해결** | §2-4 |
| ③ 스크립트 복원 | 파일마다 따로 복원 | **해결**(하네스 결과 근거) | §2-9-라 |
| ④ 기존 앱 검사 | 사용자 파일을 바꾸기 전에 검사·중단 | **해결**(하네스 결과 근거) | §2-9-라 |
| ⑤ A-28.5 케이스 폴딩 | 단순 케이스 폴딩 키 | **원문대로 해결**(이 볼륨과 차이 있음) | §2-5 |
| ⑥ R-16 사이드바 닫힘 포커스 | 사이드바에 포커스 없으면 가운데 Pane | **해결** | §2-6 |

## 2-3. R-28 종료 저장 (A-24.3, D-037 ①)

- **원문**: A-24.3 "종료 직전에 한 번 더 쓴다". R-28 "목록·순서·활성 폴더·사이드바 폭을 저장하고 다음 시작 때 복원한다".
- **사례 `closesave`**(`after/closesave-stdout.txt`, `closesave-state.json`):
  - 시작 `alpha / beta`(활성 alpha). 폴더 우클릭 메뉴 `Move Up|disabled, Move Down|enabled, ---, Remove|enabled` 에서 Enter 로 Move Down → `[dev] folder-move from=0 to=1`.
  - 바로 Ctrl-Shift-W: `action-handled name=workspace::CloseWindow` → `[dev] state-flush via=close-window` → `[dev] state-save result=written`.
  - 종료 뒤 `closesave-state.json`: `folders` = `beta`(id …0001), `alpha`(id …0000), `active_folder_id` = alpha 의 id. 순서 `beta / alpha` 가 디스크에 남았다.
  - 보내기 시간 판정 `Move Down 과 닫기를 500ms 묶어 쓰기 안에 보냄`: 4ms(기대 400ms 미만). 500ms 묶어 쓰기가 먼저 저장한 것이 아니라 종료 직전 쓰기가 저장한 것이다.
- **사례 `xclosesave`**(창 닫기 버튼): 같은 흐름에서 `state-flush via=window-close` → `state-save result=written`, `xclosesave-state.json` 이 `beta / alpha`. 보내기 시간 207ms(< 400ms).
- **고치기 전**(`before/`): 두 사례 모두 `exited=True`, 종료 뒤 `alpha / beta`(변경 잃음), `state-flush` 줄 없음. 보내기 시간 판정은 통과(5ms·206ms)했으므로 같은 조건에서 고치기 전은 잃고 고친 뒤는 저장한다.
- **코드 확인**: `mod.rs:142-152` Close Window 는 `remove_window()` 앞에서 `flush_save(.., "close-window")`. `mod.rs:565-567` 창 닫기 버튼은 `on_window_should_close` 에서 `flush_save(.., "window-close")` 뒤 `true`. `mod.rs:135-139` Quit 은 `flush_save(.., "quit")` 뒤 `cx.quit()`. `mod.rs:558-563` App 수준 `on_app_quit` 은 `cx.entity()`(강한 참조)로 `flush_save(None, "app-quit")`. `flush_save` 는 `save_generation == saved_generation`(쓰지 않은 변경 없음)이면 아무것도 쓰지 않는다(`folders.rs:926`).
- **바뀐 것 없이 종료**(`quitnochange`): `action-handled zed::Quit` 만 있고 `state-flush`·`state-save` 줄이 없다. 1회차의 판단("바뀐 것이 없으면 쓰지 않음")은 그대로다.
- **증거로 시험되지 않은 것**: `app-quit` 경로 자체(위 세 경로가 먼저 쓰므로 `app-quit` 줄은 한 번도 나오지 않는다), 운영체제 종료·작업 관리자 종료 같은 강제 종료. 코드 읽기만 했다.
- **관찰(판정 영향 없음)**: `quitsave`(Move Down 직후 Ctrl+Q)에서 `state-flush via=quit` 뒤 `state-save result=written` 이 **2번** 나온다(1회차 증거는 1번, 판정 `saves=1` → `saves=2`, 통과 조건은 "끝나기 전에 저장"). 두 번째 쓰기에는 `state-flush` 줄이 없다. 원인은 증거로 확인하지 못했다. 코드로는 500ms 묶어 쓰기 콜백(`folders.rs:244-247`)이 `saved_generation` 을 보지 않고 `save_generation == generation` 이면 쓰므로 같은 내용을 한 번 더 쓸 수 있다(추정). 파일 내용은 같다.
- **판정: 통과.** `closesave`·`xclosesave`·`quitsave` 로 Close Window·창 닫기 버튼·Quit 세 경로에서 마지막 변경이 저장됨을 직접 확인했다.

## 2-4. R-28 저장 실패 처리 (A-24.4, D-037 ②)

- **원문**: A-24.4 "50ms 간격으로 3번 다시 시도한다. 그래도 실패하면 `state.json.tmp` 를 그대로 두고, 메모리 상태를 유지하고, 알림 한 줄(`Could not save the window state.`)을 보이고, 다음 쓰기 때 처음부터 다시 한다".
- **사례 `savefail`**(`after/savefail-stdout.txt`, `savefail-state.json`, `savefail-notification.png`):
  - state.json 을 교체할 수 없게 잠근 채(공유 삭제 없이 열어 둠) 폴더 메뉴 Move Down(`via=click`) → `folder-move from=0 to=1`.
  - `[dev] state-save result=failed error=Could not save the window state.` → `[dev] notification text=Could not save the window state.`
  - 잠금을 풀고 Ctrl+Q → `action-handled zed::Quit` → `[dev] state-flush via=quit` → `[dev] state-save result=written`. 종료 뒤 state.json 은 `beta / alpha`, 활성 alpha.
- **스크린샷 `savefail-notification.png`**(직접 열어 봄): 오른쪽 위에 알림 한 줄 `Could not save the window state.` 이 보인다. 사이드바는 `beta`, `alpha`(활성 줄 강조) 순이다. 알림의 위치·모양은 A-45.1 이 "조사 대기"라 판정하지 않는다.
- **문구**: A-24.4 괄호 안 원문과 앱 출력·스크린샷이 글자 단위로 같다(끝 마침표 포함). 1회차 §8 의 소스 상수(`state/mod.rs` `ERR_SAVE`)와도 같다.
- **고치기 전**(`before/`): 알림까지는 나오지만(`result=failed` + 알림 판정 통과) 종료 뒤 state.json 이 `alpha / beta`, `state-flush` 줄 없음. 실패한 변경을 저장 완료로 보아 다시 쓰지 않았다. 고친 뒤는 다시 쓴다.
- **코드 확인**: `folders.rs:260-264` 쓰기 직전 세대를 잡아 두고 `result.is_ok()` 일 때만 `saved_generation` 을 올린다. 실패하면 두 세대가 달라 이후 `flush_save` 가 다시 쓴다.
- **증거로 시험되지 않은 것**: 50ms 간격·3번 재시도 횟수(판정 이름은 "3번 다시 시도"지만 증거는 최종 `result=failed` 와 알림만 보인다. 횟수는 `state/mod.rs` 소스·단위 시험 소스로만 확인), `state.json.tmp` 를 그대로 둔다는 부분, 종료 직전 쓰기가 다시 실패하는 경우.
- **판정: 통과.** 실패 → 알림 → 변경 유지 → 종료 직전 쓰기에서 성공까지 직접 확인했다.

## 2-5. R-10 중복 판정 (A-28.5, D-037 ⑤, D-038)

- **원문**: A-28.5 "정규화한 문자열을 대소문자 무시(유니코드 단순 케이스 폴딩)로 비교한다. 대소문자를 구분하는 NTFS 폴더는 구분하지 않는다 (판단)". R-10 은 같은 경로를 다시 고르면 새로 만들지 않고 기존 항목을 활성화한다(1회차 §2).
- **사례 `sigma`**(`after/sigma-stdout.txt`):
  - `σ` 폴더 선택 → `folder-add result=added index=0 path=...\phase3-folders\σ`, 활성화, `folders count=1`.
  - `ς` 폴더 선택 → `folder-add result=existing index=0 path=...\ς`, `folder-activate index=0 ... created=false`, `folders count=1`, 행은 `name=σ path=...\σ` 그대로. 새 항목 없이 기존 항목이 활성이다.
  - 고치기 전(`before/sigma-stdout.txt`): `result=added index=1`, `count=2` 로 판정 실패.
- **이 볼륨의 사실**(`after/remove-disk-before.txt`): 디스크 목록에 `\σ\readme.txt`, `\ς\readme.txt`, `\σ`, `\ς` 가 **따로 있다**(1회차 52줄에는 없던 4줄, `sigma` 사례가 만든 폴더). 이 D: 볼륨에서 σ 와 ς 는 서로 다른 폴더다.
- **단위 시험 소스**(`path.rs:174-185`): ς·σ·Σ 같은 키, `D:\Projects` → `d:\projects`, ſ=S, µ=Μ, 체로키, `İ` 는 그대로. `compare_key` 의 예외 표를 CaseFolding.txt 원본과 항목별로 대조하지는 않았다. `cargo test` 30개 통과는 wg-coder 보고(PROGRESS)이며 이번에 돌리지 않았다.
- **같은 이름 표시 키**: `folders.rs:163·169` 의 `docs · one` 구별도 같은 `compare_key` 를 쓴다(코드 확인). σ/ς 로 이 표시를 시험한 증거는 없다.
- **판정: 통과(원문 기준).** 구현이 원문 "유니코드 단순 케이스 폴딩"과 "대소문자를 구분하는 폴더도 구분하지 않는다(판단)"를 따르고 D-038 이 그렇게 두기로 했다. **이 볼륨과의 차이는 확인 요청으로 남긴다(§2-9-가).**

## 2-6. R-16 사이드바 닫힘 포커스 (D-037 ⑥)

- **원문**: SPEC R-16 "`Ctrl+Alt+J`: … 닫을 때 사이드바에 포커스가 있었으면 이전 위치로, 없으면 가운데 Pane 으로 돌아간다(A-17.1, I-100)". 04-APP-SPEC A-17.1 은 "사이드바에 포커스가 있었으면 이전 위치로 돌아간다"까지이고 "없으면 가운데 Pane" 은 SPEC R-16 이 더한 문장이다. 구현과 판정은 SPEC R-16 을 따른다.
- **새 판정**(`after/keys-stdout.txt`, `results.json`) `R-16·A-17.1 (D-037 ⑥) 패널 포커스에서 Ctrl+Alt+J 로 닫기 → 가운데 Pane`: Ctrl+Shift+E 로 패널에 포커스를 둔 뒤 Ctrl+Alt+J → `before=project_panel, open=false focus=center`.
  - 고치기 전(`before/`): `open=false focus=project_panel` 로 실패(사이드바는 닫혔는데 포커스가 패널에 그대로). 고친 뒤 통과.
- **함께 통과한 기존 판정**(`after/`): 사이드바에 포커스가 있다가 닫으면 `open=false focus=center`(A-17.1·I-100), 열면 `open=true focus=sidebar`, `Ctrl+Alt+;` 가 닫혀 있으면 열고 포커스·열려 있고 포커스가 있으면 이전 포커스로(닫지 않음, `open=true focus=center`)·패널과 사이드바 사이 오가기, `Ctrl+B` Dock 없음/있음, `Ctrl+Shift+E` `project_panel` ↔ `center, dock present`, A-11.8(열림: 상태 표시줄에 `status-btn-sidebar-toggle` 없음)·A-11.9(닫힘: x 4 < 30 < 56 순서), L-251 `Open Folder Sidebar|Ctrl-Alt-J`, L-230 `Add Project|Ctrl-K Ctrl-O`.
- **스크린샷 `keys-sidebar-closed.png`**(직접 열어 봄): 사이드바가 닫혀 폴더 목록이 없고, 왼쪽에 프로젝트 패널(`alpha` 루트 줄), 가운데에 Pane 탭이 보이며, 상태 표시줄 왼쪽 아래에 아이콘 세 개(사이드바 토글·폴더 추가·패널 토글)가 이 순서로 있다(A-11.9). 타이틀 `alpha`.
- **판정: 통과.**

## 2-7. R-10~R-15·R-28 나머지 판정 유지

- `after/` 의 1회차와 같은 114개 판정은 모두 통과다(§2-1). 직접 다시 확인한 것:
  - **R-13 디스크 비교**: `after/remove-disk-before.txt` 와 `remove-disk-after.txt` 는 `cmp` 로 **바이트까지 같다**(56줄). 1회차 파일(52줄)과 비교하면 앞 52줄은 경로·크기·SHA-256 이 같고 수정 시각만 다르다(실행이 새로 만든 폴더). 새 4줄은 `sigma` 사례가 만든 `\σ`·`\ς` 와 안의 `readme.txt` 다. 해제한 네 폴더가 모두 목록에 있는 것은 1회차와 같다.
  - **R-28 재시작·복원**: `state`·`state-restart`·`order-restart` 가 `after/` 에서 통과(폭 복원, 목록·순서·활성 복원, 알 수 없는 키 보존). `broken`·`tmp`·`version`·`quitsave`·`quitnochange` 도 통과.
  - **R-10 진입·실패·취소**: `add`·`dialog`(실제 OS 선택 창) 사례가 새 증거에서도 통과.
  - R-11·R-12·R-14·R-15(`items`·`scroll`·`switch`·`title`·`empty`·`order`·`menus`)도 모두 통과.
- 화면 치수는 스크린샷을 새로 재지 않았다. 대신 `after/results.json` 의 치수 판정(줄 높이 31·간격 31·폭 299·메뉴 상자 폭 등)이 1회차와 같은 값으로 통과한 것을 근거로 삼는다. 이번 수정 범위(저장 시점·비교 키·포커스 이동)의 그리기 코드 변경 여부는 따로 읽지 않았다.

## 2-8. Phase 1·2 유지 확인

- **Phase 1**(`phase1/d037-rerun/`): `passed=true`, 실패 0, 표 밖 키 0. 키 판정 70개(9사례) 실패 0. R-1 대조표: `r1-expected.tsv` 는 d035 와 해시가 같고 `r1-bindings.md` 는 생성 시각 한 줄만 d035 와 다르다. 기대 62줄 일치 62줄, 앱 내장 바인딩 54개, 표 밖 내장 바인딩 0개. 사용자 `keymap.json`·`state.json` 전후 해시 모두 `<absent>`, `restored: true`·`unchanged: true`.
- **Phase 2**(`phase2/d037-rerun/`): `passed=true`, 판정 137개 실패 0. `r5-shortcuts.md` 는 생성 시각 한 줄만 d035 와 다르고 "줄 31개, 불일치 0개". d035 와 판정별로 맞춰 본 결과 실제 값이 달라진 것은 `t_ms`·지연 ms 같은 시각 값뿐이다(의미가 바뀐 판정 없음). 사용자 파일 전후 해시 같음.
- **판정: Phase 1·2 결과 유지.**

## 2-9. 불일치 · 확인 요청 · 관찰 (2회차)

- **불일치(명세 값과 다른 실제 값): 0건.**
- **가. [leader 확인] σ/ς 두 폴더가 한 항목으로 합쳐진다**
  - 항목 ID: A-28.5 / R-10 중복 판정. 명세 값: "대소문자 무시(유니코드 단순 케이스 폴딩)로 비교", 대소문자를 구분하는 NTFS 폴더도 구분하지 않음(판단). 실제 값: 구현이 그대로 따른다. 이 볼륨에서는 **서로 다른 두 폴더** σ·ς 중 하나가 등록돼 있으면 다른 쪽을 고르는 순간 새 항목 없이 등록된 쪽(σ)이 활성화되고 알림도 없다. ς 를 등록하려면 σ 를 먼저 해제해야 한다. 증거: `after/sigma-stdout.txt`, `after/remove-disk-before.txt`(두 폴더가 디스크에 따로 있음).
  - 원문 판정과 R-10 의 목적("같은 폴더면 새로 만들지 않음")이 이 경우에는 갈린다. D-038 은 wg-coder 의 대리 응답이다. 원문이 이 경우를 판단으로 정했으므로 이 보고서는 원문대로 통과로 두고, 사람이 다시 정할 일인지는 leader 가 정해 주기 바란다.
  - 코드 주석 `path.rs:76` 은 "NTFS 도 같은 이름으로 본다"고 쓰지만 이 볼륨 증거(두 폴더 공존)와 맞지 않는다. 판정 영향 없음, 주석 문구만의 문제다.
- **나. [관찰] 종료 때 같은 내용을 한 번 더 쓴다**: §2-3 관찰. 파일 내용은 같다.
- **다. [1회차 확인 요청이 남음]** §11-가(A-24.3 종료 직전 쓰기를 "바뀐 것이 있을 때만" 쓰는 판단)는 구현이 그대로이고 `quitnochange` 가 그대로 통과한다. §11-나(A-16.1 과 A-13.9 의 타이틀 이름 충돌)도 그대로다. 새 증거에서도 빈 상태 타이틀은 `Open Recent Project`(`sigma-start.png`).
- **라. [검증 도구] ③·④ 스크립트 수정은 하네스 결과로만 확인했다.**
  - `guard-before/guard-results.json`: `running` 은 실행 중 앱이 사용자 파일 변경을 봄(`runningAppKeymapReloads: 1`)·실패, `locked` 는 keymap.json 을 잃음(`keymapAfter: <absent>`, `keymapRestored: false`)·실패. 고치기 전 스크립트 출력은 "이미 실행 중인 workbench-gpui 가 있다 … 닫고 다시 실행하라"(사용자 파일을 이미 바꾼 뒤 검사)와 사용자 파일 복원 False.
  - `guard-after/guard-results.json`: `running` 은 다시 읽기 0번·해시 전후 같음·"사용자 파일을 바꾸기 전에 중단한다", `locked` 는 keymap.json 해시 그대로(`keymapRestored: true`). 하네스의 `userFiles` 는 전후 비어 있고 `restored: true`.
  - `guard-after` 의 `locked` 스크립트 출력에 `복원 state.json` 정리 오류가 남아 있는데도 `user files restored: True` 로 찍힌다. 이 사례는 일부러 state.json 을 잠근 시험이고 해시는 그대로라 판정에는 영향이 없다. 출력 표현만 맞지 않는다.
  - 고치기 전 스크립트(`target/prefix-d037/...`)가 리뷰 대상 스크립트와 같은 것인지는 확인하지 못했다.
- **마.** Phase 1·2·3 실행 모두 사용자 파일 전후 해시가 같고(`<absent>`/빈 폴더) 기존 앱 때문에 중단된 실행은 없다.

## 2-10. PLAN Phase 3 완료 조건 (2회차 시점)

| 조건 | 상태 |
| --- | --- |
| R-10~R-16·R-28 일치도 검증 통과 | 충족(1회차 + 2회차) |
| wg-reviewer 리뷰 결과 PROGRESS 기록 | **부분**: PROGRESS 에 "리뷰 1회차(wg-reviewer)"가 기록됨(D-037, 6건). 2회차 리뷰는 아직(wg-coder 보고의 "다음 단계") |
| 증거 보관 | 충족(`phase3/d037-rerun/`, `phase1/`·`phase2/d037-rerun/`, 앞선 증거를 덮어쓰지 않음) |
| 커밋 | **미충족**: 최신 커밋은 Phase 2 `1e900dd`. Phase 3 파일은 stage 만 됨. `docs/HERDR-DECISIONS.md` 는 stage 되지 않은 수정 상태 |
| PROGRESS Phase 3 항목 | 충족. 다만 첫 항목에 "Phase 3 리뷰(wg-reviewer)와 커밋은 아직이다"(308줄)가 남아 있어 리뷰 1회차 기록(310줄)과 읽는 순서가 어긋난다. leader 가 정리할 몫 |

## 2-11. 판정하지 못한 것 · 다른 Phase 로 넘긴 것 (2회차 추가분)

- 1회차 §13 은 그대로다(Phase 4 이월: 폴더별 트리·탭·`Remove from Project`·루트 `Delete`, Phase 5 이월: A-16.3 실행 중 사라짐).
- 2회차에서 코드·소스로만 본 것: `app-quit` 경로, 강제 종료, A-24.4 의 50ms×3 재시도·`state.json.tmp` 그대로 둠, A-12.6 같은 이름 표시의 σ/ς, `compare_key` 표와 CaseFolding.txt 의 일치, `cargo test` 30개(보고만 읽음).
- 이 2회차에서도 내가 쓴 파일은 이 보고서 하나다. 코드·다른 문서·증거는 고치지 않았다.

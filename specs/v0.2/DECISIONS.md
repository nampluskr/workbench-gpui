> 버전: v0.2 · 작성일: 2026-11-01 · 상태: 확정 (2026-11-01)
>
> 이번 버전(PoC 4~5단계)에 적용할 설계 결정을 기록한다. 변하지 않는 의도는 루트 `INTENT.md`에, 이번 버전에 무엇을 왜 하는지는 `specs/v0.2/INTENT.md`에 있다. 근거로 쓰는 G-ID 는 02-gpui 출발 문서(D:\projects\docs\guides\zed-like-editor\02-gpui\README.md), L-·I-·A-·E- ID 는 01-zed 명세(D:\projects\docs\guides\zed-like-editor\01-zed\)의 항목이다.

# DECISIONS — workbench-gpui v0.2

## D-1. v0.1 결정 D-1~D-10(이후 변경 포함)을 그대로 이어받는다

**선택**

`specs/v0.1/DECISIONS.md`의 D-1~D-10 을 v0.2 에서도 그대로 따른다. 지난 버전 폴더는 고치지 않고, 이 문서에서 이어받는다고만 적는다.

- D-1 Zed 를 포크하지 않고 재구현한다.
- D-2 Zed GPL 코드를 복사·의존하지 않고 gpui·gpui-kit 만 의존한다.
- D-3 gpui-kit 0.8.1 을 진입점으로 쓰고 gpui 를 따로 의존하지 않는다.
- D-4 gpui-kit 을 =0.8.1 로 고정하고 Cargo.lock 을 커밋한다.
- D-5 gpui-kit 의존을 우리 쪽 얇은 래퍼 계층(`src/ui`)에 가둔다.
- D-6 단일 Rust 프로세스, 창마다 Window 하나.
- D-7 상태는 gpui Entity 로 두고 변경 후 `cx.notify()`.
- D-8 화면은 gpui 요소 트리와 gpui-kit 컴포넌트로 그리고, 치수는 rem 헬퍼(`rems_from_px`)로 낸다.
- D-9 타이틀 바는 gpui `WindowControlArea` 로 직접 만든다(v0.1 D-9 이후 변경).
- D-10 레이아웃 뼈대: 사이드바는 resizable 패널 안에 직접 조립, 왼쪽 Dock 은 앱이 폭을 관리(v0.1 D-10 이후 변경).

**근거**

v0.1 결정은 버전과 무관한 구현 방식이고, v0.2 범위(PoC 4~5단계)는 그 위에 쌓는다. 진행 방식이 v0.1 과 같다는 것은 사용자 결정이다(2026-11-01). WORKFLOW 5절: 지난 버전 폴더는 그대로 두고 읽기만 한다.

**배제한 대안**

없음.

---

## D-2. 앱 내장 키맵은 02 1절 키 표의 "적용 결과"를 우리 말로 다시 적은 것이고, 그 위에 사용자 keymap.json 을 얹는다

**선택**

- 앱에 내장하는 키맵은 01-zed 02-INTERACTION 1절 키 표(Windows 기본 키맵에 VSCode 덧씌움과 specific-overrides 를 반영한 적용 결과, I-001·I-700)에서 우리 앱에 있는 액션만 골라, 우리 코드로 다시 적은 것이다.
- 사용자 키맵 파일 `keymap.json`(A-20.4, 형식은 Zed 와 같은 객체 배열)을 그 위에 마지막으로 얹는다(A-27.1).
- `base_keymap` 설정은 만들지 않는다. 항상 VSCode 덧씌움 결과를 쓴다(A-27.2).

**근거**

- A-27.1 적용 순서: Windows 기본 keymap → VSCode 덧씌움 → 우리 `keymap.json`. 나중 것이 이긴다.
- A-27.2: `base_keymap` 설정을 만들지 않고 항상 VSCode 덧씌움 결과를 쓴다(01-zed 판단).
- zed-like-editor README 3절 라이선스 원칙: 키맵 JSON 파일 원문은 "가져오지 않는다". 키·동작의 사실은 우리 말로 다시 쓴다. 그래서 Zed 의 `default-windows.json`·`vscode.json` 을 그대로 넣어 두 층을 합치는 방식은 쓸 수 없고, 적용 결과를 표로 다시 적는다.
- 02-gpui 7절 4단계 기준 "VSCode 덧씌움 결과로 메뉴·툴팁 키 일치".
- 사용자 결정(2026-11-01, docs/HERDR-DECISIONS.md D-023 ⑪): 키맵 층 구성은 이 결정(내장 키맵 = 적용 결과 표를 다시 적은 것 + 사용자 keymap.json)대로 한다.

**배제한 대안**

- **Zed 키맵 JSON 원문(`default-windows.json` + `linux/vscode.json`)을 앱에 넣고 실행할 때 합치기** — README 3절이 키맵 JSON 원문을 가져오지 않는다고 정했다. 배제.

**이후 변경** — Phase 1 구현 중 leader 결정(위임 권한, docs/HERDR-DECISIONS.md D-027 ②)으로 액션 이름을 정했다(2026-11-01). 01-zed·02-gpui 에 이름이 나온 액션은 그 이름을 그대로 쓴다. 문서에 이름이 없는 액션은 Zed 와 같은 `namespace::Name` 꼴로 우리가 짓고, 그 목록을 PROGRESS 와 검증 보고서(`specs/v0.2/verify/phase1/`)에 "우리가 지은 이름"으로 남긴다.

**이후 변경** — Phase 2 구현 전 leader 결정(위임 권한, docs/HERDR-DECISIONS.md D-031 ③)으로 내장 키맵에 두 키를 더했다(2026-11-01). ☰ 메뉴의 Quit(I-341 `zed::Quit`, Ctrl+Q)과 Close Window(I-358 `workspace::CloseWindow`, Ctrl+Shift+W)는 v0.2 에서 동작하는 항목인데, 키가 02 1절 표가 아니라 9.2절 표(A-18.11, 적용 keymap 결과)에만 있다. 두 키를 내장 키맵에 넣고 R-1 기대 표와 Phase 1 검증 스크립트를 함께 고친다.

---

## D-3. 키 충돌·해제·표시 규칙은 01-zed I-702·I-703·I-704 와 L-217~L-221 을 그대로 따르고, 키 엔진은 gpui 의 actions·KeyBinding·key_context 를 쓴다

**선택**

- 충돌: 일치한 포커스 컨텍스트가 더 깊은 쪽이 이기고, 깊이가 같으면 나중에 등록된 바인딩이 이긴다(I-702).
- 해제: `null` 은 그 컨텍스트에서 낮은 우선순위 후보를 해제한다. 사용자 키맵이 내장 키맵보다 등급이 높다(I-703).
- 표시: 메뉴·툴팁은 액션 인수까지 같은 바인딩 중 현재 컨텍스트에서 가려지지 않은 마지막 바인딩 하나를 `Ctrl-Shift-E` 형식(하이픈, Fn → Ctrl → Win → Alt → Shift → 키, 키 이름 첫 글자 대문자, chord 는 덩어리 사이 gap 4px)으로 그린다(I-704, L-217~L-221, A-27.4). 사용자 키맵을 다시 불러오면 메뉴도 다시 만든다(I-704).
- 키 엔진은 gpui 의 `actions!` + `KeyBinding` + `key_context` 를 그대로 쓴다(G-005).

**근거**

- 01-zed I-702·I-703·I-704, L-217~L-221, A-27.4 원문.
- 02-gpui G-005: "gpui `actions!` + `KeyBinding` + `key_context`를 그대로 쓴다. Zed와 같은 엔진이라 컨텍스트 우선순위 재현이 가장 쉽다" — 02-gpui 작성자 판단.
- 02-gpui G-105: 키맵 컨텍스트 우선순위 재현은 P0 확인 항목이다. gpui `KeyBindingContextPredicate` 공개 여부(gpui-pre 재수출)와 `unbind` 처리 방법은 미확인이라 미결 사항에 둔다.

**배제한 대안**

없음.

**이후 변경** — Phase 1 구현 중 leader 결정(위임 권한, docs/HERDR-DECISIONS.md D-027 ④·⑤)으로 다음을 정했다(2026-11-01).

- 사이드바의 키 컨텍스트 이름은 `Sidebar` 다(④). A-17 아래 설명이 Zed 의 `ThreadsSidebar` 를 쓰지 않고 우리 앱 값을 쓴다고 했고, 이름은 Zed 패널 컨텍스트(`ProjectPanel`)와 같은 꼴로 한다.
- G-105 확인 결과(PROGRESS Phase 1): `KeyBindingContextPredicate` 는 gpui-kit 재수출로 공개이고, `null` 해제는 gpui `NoAction` 바인딩으로 표현한다. 사용자 바인딩에 내장보다 강한 등급(`KeyBindingMetaIndex`)을 주어 I-703 의 출처 등급을 맞춘다.
- R-3·R-4 의 Phase 1 판정(⑤): 사이드바·프로젝트 패널 자리 표시에 포커스와 컨텍스트를 달아 키를 넣고, dev 출력의 "실행된 액션 이름"과 "액션별 표시 문자열"로 판정한다. 실제 결과(디스크 상태, 사이드바 목록, 메뉴·툴팁 화면)는 Phase 2~4 판정에서 다시 확인한다.

---

## D-4. JSON 은 serde_json 으로 읽고 쓰며, keymap.json 은 주석·끝 쉼표를 허용한다(jsonc-parser)

**선택**

- `keymap.json` 과 `state.json` 의 JSON 읽기·쓰기는 `serde_json`(02-gpui G-020, 1.0.154)으로 한다.
- 사용자가 직접 고치는 `keymap.json` 은 주석·끝 쉼표를 허용한다. `jsonc-parser`(G-020, 0.34.0)로 읽는다.
- 앱만 쓰는 `state.json` 은 앱이 주석 없이 쓴다.

**근거**

- 사용자 결정(2026-11-01, docs/HERDR-DECISIONS.md D-023 ③): JSONC 허용(jsonc-parser).
- 02-gpui G-006·G-020: settings.json·keymap.json 은 JSONC(주석·끝 쉼표 허용)로 읽는다. Zed 설정 파일이 이를 허용한다(02-gpui 작성자 판단).
- 새 크레이트 `serde_json`·`jsonc-parser` 는 02-gpui G-010~G-025 목록 안이라 docs/HERDR-SETUP.md 7절에 따라 leader 가 승인했다(docs/HERDR-DECISIONS.md D-023).

**배제한 대안**

- **엄격한 JSON(주석·끝 쉼표 불가, 01-zed A-20 의 판단)** — 사용자가 JSONC 허용을 골랐다(D-023 ③). 배제.

---

## D-5. 툴팁·메뉴는 gpui·gpui-kit 의 기본 동작을 쓰고, 01-zed 값과 다른 점만 앱에서 보정한다

**선택**

- 툴팁은 gpui 툴팁과 gpui-kit `Tooltip` 을 쓴다(G-040).
- ☰ 앱 메뉴와 우클릭 메뉴는 gpui-kit `menu`(PopupMenu·ContextMenu)를 쓰고, 최소 폭 200·최대 높이 75%·단축키 표시·50ms 깜빡임·가로 메뉴 바 전환은 01-zed 값에 맞춰 보정한다(G-039).
- 기본 동작이 01-zed 값(L-206~L-216, I-504~I-521)과 같은지는 PLAN Phase 2 에서 소스 대조와 측정으로 확인한다(G-111).

**근거**

- 02-gpui G-039(메뉴: `menu`(PopupMenu·ContextMenu), `native_menu`, "최소 폭 200·75% 높이·단축키 표시·50ms 깜빡임·가로 메뉴 바 전환은 맞춤", 기본 제공 "일부").
- 02-gpui G-040(툴팁: gpui 툴팁 + gpui-kit `Tooltip`, "500ms·마우스 기준 (+1,+1)·뒤집기·elevation_2 는 gpui 동작과 같을 가능성이 높다").
- 02-gpui G-111: gpui 툴팁·메뉴 기본 동작이 Zed 와 같은지 gpui-pre 소스 대조로 확인(P1). "대부분 같다고 예상"은 02-gpui 작성자 판단이다.
- 01-zed I-301: Windows 에서 Zed 는 네이티브 메뉴를 띄우지 않고 직접 그린 메뉴를 쓴다. 우리도 직접 그린다. 그래서 gpui-kit `native_menu` 는 앱 메뉴에 쓰지 않는다.

**배제한 대안**

- **Windows 네이티브 메뉴(`native_menu`)로 ☰ 메뉴 만들기** — 01-zed I-301 이 Zed 는 직접 그린 메뉴이고 우리도 직접 그린다고 정했다. 배제.

**이후 변경** — Phase 1 구현 중 leader 결정(위임 권한, docs/HERDR-DECISIONS.md D-027 ③)으로 메뉴 키 컨텍스트를 정했다(2026-11-01). I-516·I-517 대로 `menu` 컨텍스트에 I-517 의 키를 우리 `menu::` 액션으로 묶고, Phase 2 에서 메뉴 요소에 `menu` 컨텍스트를 달아 그 액션을 gpui-kit PopupMenu 동작으로 잇는다. gpui-component 0.8.1 PopupMenu 가 자기 컨텍스트 `PopupMenu` 에 넣는 바인딩(enter·escape·up·down·left·right, `menu/popup_menu.rs` 22~29행)은 gpui-kit 것으로 두고 R-1 대조에서 뺀다.

**이후 변경** — Phase 2 구현 전 leader 결정(위임 권한, docs/HERDR-DECISIONS.md D-031 ①·②)으로 다음과 같이 바꿨다(2026-11-01). 근거는 G-111 소스 대조(PROGRESS Phase 2)다. gpui-component 0.8.1 `PopupMenu` 는 항목 높이 26·안쪽 좌우 8·구분선 2px 같은 값을 상수로 박아 두어(`menu/popup_menu.rs` 1236~1285행) 바깥에서 I-505~I-512 로 고칠 수 없다. `Kbd` 단축키 형식(`Ctrl+Alt+Shift+Win+A`, `kbd.rs` 105~125행)도 L-219 와 다르다. gpui-kit `Tooltip` 의 여백·gap·애니메이션(`tooltip.rs` 113~130행)도 L-209·L-213·L-215 와 다르다.

- ☰ 메뉴는 gpui 요소(`div`·`anchored`·`deferred`, 포커스, `menu` 키 컨텍스트)로 직접 그린다. gpui-kit `PopupMenu`·`AppMenuBar` 는 쓰지 않는다. `menu` 컨텍스트의 우리 `menu::` 액션(위 이후 변경)을 이 메뉴 요소가 받는다.
- 툴팁은 gpui 의 `.tooltip()` 장치(지연 500ms·마우스 + (1, 1)·창 가장자리 뒤집기, gpui-pre `elements/div.rs` 53행·`window.rs` 3834~3860행. Zed 값과 같다)를 그대로 쓰고, 그 안의 상자는 우리 툴팁 뷰로 그린다. gpui-kit `Tooltip` 은 쓰지 않는다.
- 메뉴·툴팁의 단축키 글자는 우리 표시 문자열(`crate::keymap::display`, L-219~L-221)로 그린다. gpui-kit `Kbd` 는 쓰지 않는다.

---

## D-6. 폴더 선택 창은 rfd, 휴지통은 trash, 디스크 감시는 notify, 앱 데이터 경로는 dirs 로 한다

**선택**

| 쓰임 | 크레이트 | 버전(02-gpui 기준) | 02-gpui ID |
| --- | --- | --- | --- |
| OS 폴더 선택 창(폴더 하나, A-13.1) | `rfd` | 0.17.2 | G-018 |
| Windows 휴지통(Trash, I-552) | `trash` | 5.2.9 | G-017 |
| 폴더 트리·열린 파일 감시(G-115) | `notify` | 8.2.x (gpui-component 가 이미 의존) | G-016 |
| `%APPDATA%` 경로(A-20) | `dirs` | 7.0.0 | G-023 |

**근거**

02-gpui 3절 G-016·G-017·G-018·G-023 과 2절 G-004("휴지통은 `trash`, 감시는 `notify`"). 네 크레이트 모두 02-gpui G-010~G-025 목록 안이라 docs/HERDR-SETUP.md 7절에 따라 leader 가 승인했다(docs/HERDR-DECISIONS.md D-023).

**배제한 대안**

없음.

**이후 변경** — Phase 3 구현 전 leader 결정(위임 권한, docs/HERDR-DECISIONS.md D-035)으로 정했다(2026-11-01). 폴더 선택 창은 `rfd` 0.17.2(G-018)로 연다. 검증에서는 실제 선택 창을 SendInput 으로 조작하는 경로와, 디버그 전용 `--dev-pick-folder <파일>`(선택 창 대신 그 파일에 적힌 경로를 고른 결과로 쓴다)로 주입하는 경로를 함께 쓰고, 보고서에 어느 쪽인지 적는다(SPEC R-10 판정 방법).

---

## D-7. 등록 폴더 하나가 독립 항목이고, 폴더마다 작업 문맥(Workspace)을 따로 둔다

**선택**

- 우리 "폴더"는 Zed 의 프로젝트 한 개에 해당하고, 폴더 하나에 루트 하나다(A-10.3). 폴더를 여러 개 골라도 폴더마다 독립 항목으로 등록한다(A-10.6). 선택 창은 폴더 하나만 고른다.
- 폴더마다 열린 탭·트리 펼침·선택·스크롤 같은 작업 문맥을 따로 보관하고, 사이드바에서 활성 폴더를 바꾸면 그 폴더의 문맥이 보인다. 전환해도 이전 폴더의 문맥은 메모리에 남는다(A-15, I-108, I-111).
- 상태 구조는 폴더 id 를 키로 Workspace 엔티티를 보관한다(G-002 `HashMap<FolderId, Entity<Workspace>>`).

**근거**

01-zed A-10.3·A-10.6(판단), A-15, I-108, I-111(권장 모델, 판단). 02-gpui G-002.

**배제한 대안**

- **Zed 처럼 한 프로젝트에 여러 루트를 한 트리에 보이기(multi-root)** — I-111 이 "요구와 달라 선택 옵션으로 남긴다"고 했고, A-18.4 가 multi-root 인 "Add Folder to Project…"를 앱 메뉴에서 뺐다. 배제.

**이후 변경** — Phase 3 구현 전 leader 결정(위임 권한, docs/HERDR-DECISIONS.md D-035 ①)으로 Phase 3 범위를 정했다(2026-11-01).

- Phase 3 은 폴더마다 Workspace 엔티티를 만들고, 활성 폴더가 바뀌면 프로젝트 패널에 그 폴더 루트 한 줄(이름, 펼침 없음)을 보이는 자리 표시까지 한다.
- 트리·탭에 기대는 판정은 Phase 4 로 이월한다. R-12 의 폴더별 펼침·선택·스크롤 유지와 폴더별 탭, R-13 의 해제 때 탭 닫기와 루트 항목 우클릭 `Remove from Project` 가 여기에 든다.
- 사이드바에는 활성 폴더와 따로 키보드 커서를 둔다(A-17.3 Up/Down, A-12.5 포커스 테두리). Enter 는 커서 항목 활성화(A-13.3), Delete 는 커서 항목 해제(A-13.4 ②)다.

---

## D-8. 프로젝트 패널 트리는 gpui-component `tree`(Tree, TreeState 가상화)로 만든다

**선택**

프로젝트 패널 트리는 gpui-component `tree`(Tree, TreeState 가상화)를 쓴다. 접힌 경로(`docs \ guides`), 들여쓰기 안내선, 인라인 이름 입력, 검증 배너는 01-zed 에 맞춰 직접 보탠다.

**근거**

02-gpui G-033: 프로젝트 트리 = `tree`(Tree, TreeState 가상화). "접힌 경로·들여쓰기 안내선·인라인 이름 입력·검증 배너·드래그"는 손봐야 하는 부분, 기본 제공 "일부".

**배제한 대안**

없음. (사이드바 폴더 목록은 v0.1 D-10 대로 `list`·`VirtualList` 자리다.)

---

## D-9. 탭은 시나리오 A-33.2·A-33.4 에 필요한 최소 동작만 넣는다

**선택**

v0.2 의 탭은 다음 다섯 가지만 한다.

- 트리에서 파일을 탭으로 연다(I-087, I-033).
- Pane 당 임시(preview) 탭은 하나이고, 다른 임시 파일을 열면 그 자리(인덱스)에서 교체한다(I-062).
- 더블클릭(트리의 비임시 열기)으로 일반 탭이 된다(I-087, I-063).
- 임시 탭 제목은 기울임꼴이다(I-064).
- 열린 탭은 폴더마다 따로 보관한다(A-15.1).

핀·분할·드래그와 그 밖의 탭 기능(탭 닫기, 이동 기록, 미리보기 탭 등)은 PoC 6단계로 둔다.

**근거**

사용자 결정(2026-11-01, docs/HERDR-DECISIONS.md D-023 ①). 01-zed A-33.2(트리 한 번 클릭 → 임시 탭·기울임 → 다른 파일 한 번 클릭 → 같은 자리 교체 → 더블클릭 → 일반 탭), A-33.4(폴더마다 탭 유지), I-061~I-064, I-087. 02-gpui 7절 5단계 기준이 이 두 시나리오다.

**배제한 대안**

- **탭 동작 전부를 PoC 6단계로 미루기** — 시나리오 A-33.2·A-33.4 를 판정할 수 없다. 사용자가 최소 동작을 넣기로 했다. 배제.
- **핀·분할·드래그까지 앞당기기** — 사용자가 시나리오 최소 동작만 골랐다. 배제.

---

## D-10. 등록 폴더 목록·순서·활성 폴더·사이드바 폭만 state.json 에 저장하고 시작할 때 복원한다

**선택**

- `state.json` 에 등록 폴더 목록(경로)과 그 순서, 활성 폴더, 사이드바 폭을 저장하고, 앱을 시작할 때 복원한다.
- 필드 이름과 구조는 A-22 의 해당 부분을 따른다: `version`, `windows[].folders[]`(`id`, `path`, `added_at`), `windows[].active_folder_id`, `windows[].sidebar.width`. 순서는 `folders` 배열 순서다(A-13.6, A-22.2).
- 그 밖의 A-22 항목(열린 탭, Dock 폭, 창 위치, 최근 목록 등)과 A-25 의 복원은 PoC 8단계로 둔다.

**근거**

사용자 결정(2026-11-01, D-023 ②). 01-zed A-11.1(사이드바 폭을 `state.json` 에 저장), A-13.6·A-22.2(폴더 순서), A-22(구조), A-20.2(`state.json` 은 앱만 쓴다).

**배제한 대안**

- **저장하지 않기(실행 중 메모리만)** — 사용자가 이 범위의 저장·복원을 골랐다. 배제.
- **A-22 전체 저장** — PoC 8단계 "상태 복원"이다. 사용자가 범위를 좁혔다. 배제.

**이후 변경** — Phase 3 구현 전 leader 결정(위임 권한, docs/HERDR-DECISIONS.md D-035 ②·③)으로 다음을 정했다(2026-11-01).

- `state.json` 을 읽지 못했을 때(형식 오류)의 알림 문구는 `Could not read the window state.` 다. 01-zed 에는 이 문구가 없다(A-24.6 은 "알림 한 줄"만 말한다). A-24.4 의 `Could not save the window state.` 와 짝을 맞춘 **우리 문구**다.
- `state.json` 의 쓰기·읽기에는 01-zed A-24.1~A-24.7 을 그대로 적용한다.
  - `.tmp` 쓰기 → `sync_all` → `ReplaceFileW`/`MoveFileExW`.
  - 변경 뒤 500ms 묶어 쓰기. 쓰는 때는 D-10 범위의 변경(폴더 등록·해제·순서·활성·사이드바 폭)이다.
  - 종료 직전에 쓰기.
  - 교체 실패 때 50ms × 3번 재시도. 그래도 실패하면 `.tmp` 를 두고 `Could not save the window state.` 알림.
  - 깨졌으면 `.tmp` 로 복구.
  - 깨진 파일은 `state.json.bad-YYYYMMDD-HHMMSS` 로 옮기고 최근 3개만 보관, 위 문구로 알림.
  - `version` 이 앱(1)보다 크면 읽기만 한다.
  - Win32 API 는 FFI 로 부르고 새 크레이트는 없다.
- `folders[].id`(UUID v4, A-22.3)는 Windows `CoCreateGuid`(FFI)로 만든다. `added_at`(A-22.5)은 UTC ISO 8601 문자열이다. 경로는 A-28.1~A-28.6 으로 정규화·비교한다.
- 사이드바 폭 저장은 gpui-kit `ResizablePanelGroup::on_resize`, 사이드바 닫기는 `ResizablePanel::visible` 로 한다.

---

## D-11. 앱 데이터 폴더는 %APPDATA%\workbench-gpui 다

**선택**

`keymap.json`·`state.json` 을 `%APPDATA%\workbench-gpui\` 에 둔다. 경로는 `dirs`(D-6)로 얻는다.

**근거**

사용자 결정(2026-11-01, D-023 ④). 01-zed A-20 의 `%APPDATA%\ZedLike\` 는 임시 이름이고 구현 때 바꾼다고 적혀 있다(A-20.3).

**배제한 대안**

없음.

---

## D-12. 휴지통·영구 삭제 확인창은 Windows TaskDialog 를 Win32 FFI 로 부르고, 기본 버튼과 Esc 는 취소다

**선택**

- 확인창(A-14.4, A-14.7~A-14.10)은 Windows TaskDialog 를 새 크레이트 없이 Win32 FFI 로 부른다.
- 기본 버튼은 취소이고, `Esc` 도 취소다.
- 본문·버튼 문구는 A-14.7~A-14.10 원문이다.

**근거**

- 사용자 결정(2026-11-01, D-023 ⑤): TaskDialog Win32 FFI, 기본 버튼 취소·Esc 취소.
- 02-gpui G-042: Zed 는 Windows TaskDialog 를 쓴다(`windows` 크레이트). v0.1 R-5 에서 TaskDialog 를 크레이트 없이 Win32 FFI 로 부를 수 있음을 확인했다(`specs/v0.1/verify/phase1/r5-taskdialog.txt`).
- 01-zed A-44 아래 설명: 기본 버튼과 `Esc` 의 결과는 P-001~ 조사가 정한다고 했으나, 사용자가 취소로 정했다.

**배제한 대안**

- **`windows` 크레이트(G-019)로 TaskDialog 부르기** — 사용자가 새 크레이트 없는 FFI 를 골랐다. 배제.
- **gpui-kit `dialog` 로 그리기** — 사용자가 TaskDialog 를 골랐다. 배제.

---

## D-13. ☰ 앱 메뉴에는 v0.2 에서 동작하는 항목만 둔다

**선택**

☰ 앱 메뉴는 02 9.2절·A-18 의 구조와 문구를 따르되, v0.2 에서 실제로 동작하는 항목만 둔다. 항목이 하나도 없는 메뉴는 메뉴 바에 두지 않는다(I-306 빈 그룹 건너뛰기). 항목 순서와 구분선은 02 9.2절 그대로다.

**근거**

사용자 결정(2026-11-01, D-023 ⑥). 01-zed I-306(빈 그룹은 건너뛰고 연속·끝 구분선을 정리), I-308(비활성 계산은 우리 설계, I-480).

**배제한 대안**

- **전체 구조를 만들고 동작 없는 항목은 비활성** — 사용자가 동작 항목만 골랐다. 배제.
- **전체 구조를 만들고 동작 없는 항목도 활성** — 위와 같음. 배제.

**이후 변경** — Phase 2 구현 전 leader 결정(위임 권한, docs/HERDR-DECISIONS.md D-031 ④·⑤)으로 다음을 정했다(2026-11-01).

- Phase 2 의 ☰ 메뉴에는 지금 동작하는 항목만 둔다. Open Folder...(R-10)와 Toggle Folder Sidebar·Focus Folder Sidebar(R-16)는 그 동작이 생기는 Phase 3 에서 메뉴에 넣고, R-8 의 그 세 항목 판정도 Phase 3 으로 이월한다. 메뉴 정의는 02 9.2절 순서 그대로 한 곳에 두고, 동작 여부로만 걸러 순서·구분선(I-306)을 지킨다.
- 메뉴에 쓰는 앱 이름은 `workbench-gpui` 다(I-341, A-18.10). 첫 메뉴 이름은 `workbench-gpui`, 항목은 `Quit workbench-gpui` 다. 01-zed A-40.5 가 앱 이름을 정하지 않았고, 창 제목(v0.1)과 앱 데이터 폴더(D-11)가 이미 이 이름이다.

---

## D-14. 알림(토스트)은 gpui-kit notification 을 임시로 쓰고 문구만 판정한다

**선택**

알림 한 줄(A-16.4 `Cannot open this folder.`, A-14.11 `Failed to trash/delete X of Y file(s).`, `keymap.json` 읽기 오류)은 gpui-kit `notification`(G-011)으로 보인다. 위치·모양·닫기는 판정하지 않고 문구만 판정한다.

**근거**

사용자 결정(2026-11-01, D-023 ⑦). 01-zed A-45.1: 알림의 위치·모양·닫기는 "P-001 ~ 조사 대기. 그때까지 모양은 정하지 않는다". 02-gpui G-011: gpui-component 에 notification 이 있다.

**배제한 대안**

없음.

**이후 변경** — Phase 1 구현 중 leader 결정(위임 권한, docs/HERDR-DECISIONS.md D-027 ①)으로 `keymap.json` 읽기 오류 문구를 정했다(2026-11-01).

- 파일을 읽지 못하거나 형식이 틀리면 `Failed to load keymap file`(01-zed 02-INTERACTION K-091 원문 문구).
- 없는 액션 이름이면 `Action '{이름}' not found`(K-085 원문 문구, `{이름}` 자리에 파일에 적힌 이름).
- 오류가 여럿이면 알림 하나에 한 줄씩 잇는다.
- 오류 항목만 빼고 나머지 바인딩은 적용한다(leader 판단).

---

## D-15. 프로젝트 패널 우클릭 메뉴의 Open Markdown Preview 는 비활성으로 둔다

**선택**

02 11.2절 파일 메뉴의 `Open Markdown Preview`(I-535, 마크다운 파일일 때)는 v0.2 에서 비활성 항목으로 둔다.

**근거**

사용자 결정(2026-11-01, D-023 ⑧). 마크다운 미리보기는 PoC 6단계다. 비활성 항목은 회색 라벨, hover·클릭 반응 없음, 키보드 선택에서 건너뛴다(I-515).

**배제한 대안**

- **메뉴에서 빼기** — 사용자가 비활성으로 두기로 했다. 배제.

---

## D-16. 타이틀 바의 폴더 이름 버튼은 이름 표시와 툴팁만 두고, 눌렀을 때의 목록은 PoC 8단계로 둔다

**선택**

- 타이틀 바에 활성 폴더 이름(40자 말줄임)을 보이고, 폴더가 없으면 `Open Recent Project`(Muted)를 보인다(A-13.9, A-15.5, L-88, L-227).
- 툴팁은 `Recent Projects`(L-226)다.
- 누르면 여는 Open Recent 목록(P-009)은 PoC 8단계로 둔다.

**근거**

사용자 결정(2026-11-01, D-023 ⑨). 01-zed A-13.9, A-15.5, L-88, L-226, L-227.

**배제한 대안**

- **버튼 전체를 PoC 8단계로 미루기** / **등록 폴더 목록 팝업** — 사용자가 이름 표시·툴팁만 골랐다. 배제.

---

## D-17. 트리 드래그 앤 드롭(I-094)은 이후 버전으로 둔다

**선택**

프로젝트 패널의 드래그 앤 드롭(끌어서 이동, Ctrl 복사, 루트 순서 이동, 외부 드롭과 그 뒤 자동 열기)은 v0.2 에 넣지 않는다.

**근거**

사용자 결정(2026-11-01, D-023 ⑩). 01-zed I-094, I-097 `on_drop`.

**배제한 대안**

- **v0.2 에 넣기** — 사용자가 이후 버전으로 미뤘다. 배제.

---

## D-18. v0.2 탭은 보기 전용이다(편집을 막는다)

**선택**

- D-9 의 최소 탭은 파일 내용을 gpui-kit Editor 로 보이되 편집을 막는다(읽기만).
- 그래서 v0.2 에는 저장 안 한 버퍼가 생기지 않는다. 저장 질문(A-13.4, I-069), 충돌 표시(E-086 의 수정한 버퍼, 탭 점 Warning 색), 지워진 파일 탭 표시(E-087), 저장 때 확인창(E-084, E-085)은 저장 기능과 함께 이후 버전에서 다룬다.
- 디스크 변경에서 v0.2 가 판정하는 것은 깨끗한 버퍼의 자동 다시 읽기(E-086 앞부분, G-115)뿐이다.

**근거**

사용자 결정(2026-11-01, docs/HERDR-DECISIONS.md D-024): 읽기만. 01-zed E-086("수정하지 않은 버퍼는 자동으로 다시 읽는다"), 02-gpui G-115(깨끗한 버퍼 자동 다시 읽기, 수정 중이면 충돌 표시, 지워진 파일 취소선).

**배제한 대안**

- **편집은 허용하고 수정 표시만 하기** — 저장할 수 없는 수정이 생기고 저장 질문·충돌 표시가 따라온다. 사용자가 읽기만을 골랐다. 배제.

---

## 미결 사항

v0.2 에서 남은 것:

- **사이드바 폭 조절 핸들(A-11.12)** — 위치·너비·커서·더블클릭 초기화가 01-zed 에서 확인되지 않았다(v0.1 에서 이어짐). v0.2 는 v0.1 의 resizable 핸들을 그대로 쓴다.
- **폴더 경로 비교 키의 케이스 폴딩(A-28.5) — 알려진 한계** (leader 결정 D-040, Phase 3 리뷰 2회차) — `src/state/path.rs` `compare_key` 는 한 글자 소문자화에, 소문자화와 결과가 다른 일부 C·S 항목(ς·ſ·µ·체로키 등)을 손으로 적은 표를 더한 것이다. Unicode 단순 케이스 폴딩(CaseFolding.txt 의 C·S) 전체가 아니다. 예를 들어 U+1FD3→U+0390, U+1FE3→U+03B0, U+FB05→U+FB06 이 빠져 있어, 이 문자만 다른 경로는 다른 항목으로 등록된다. 이후 버전에서 버전을 정한 Unicode CaseFolding C/S 표를 들여와 모든 매핑과 대조한다.

v0.1 에서 이어지는 미결(이번 버전 범위 밖, `specs/v0.1/PROGRESS.md` "버전 종료" 남은 것 2):

- Zed 글꼴(.ZedSans/.ZedMono) 자산 도입 — 사용자 결정(2026-11-01)으로 v0.2 에는 넣지 않는다.
- 닫기 외 창 버튼 hover·누름 색(테마 매핑 G-106 전 임시).
- 글리프 글꼴 선택 기준(설치 여부 vs 빌드 번호 22000).
- G-121 Rust 최소 버전 기준(1.90 vs 1.92).

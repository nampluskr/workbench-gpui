> 버전: v0.5 · 작성일: 2026-11-06 · 상태: 확정 (core-leader 판정, 사용자 위임 2026-11-06)
>
> workbench-gpui v0.5가 만족해야 할 요구와 판정 방법을 담는다. 요구는 workbench-core `specs/v0.5/ITEMS.md`의 I-1~I-23을 옮긴 것이고, 판정 방법은 ITEMS의 "판정 방법"을 바꾸지 않고 옮겼다(core D-11). 목적은 `INTENT.md`에, 결정은 `DECISIONS.md`에, Phase 순서는 `PLAN.md`에 있다.

# SPEC — workbench-gpui v0.5

## 읽는 법

- 요구 번호 R-n은 core 항목 I-n과 같은 번호다(R-1 = I-1 … R-23 = I-23). 이 번호 체계는 초안이다(`DECISIONS.md` 미결 사항).
- 요구마다 "요구"·"정해진 결과"·"판정 방법"·"출처"를 둔다. "정해진 결과"는 ITEMS의 "기대"와 "정한 것"이고, "판정 방법"은 ITEMS 문구 그대로다.
- "이 레포의 현재 상태"는 ITEMS의 확인한 사실 가운데 workbench-gpui에 해당하는 것과 writer가 src를 읽어 더한 것이다. 원인 확정과 구현 방법이 아니다.
- V0~V4는 `AGENTS.md` 3A의 검증 수준이다. Zed와 비교하는 판정은 같은 조건(창 1440×852, 화면 배율 100%, 같은 폴더·파일·테마)에서 한다(core D-11).
- 화면 비교 자료(`refs/...`)는 `D:\projects\workbench-core\specs\v0.5\refs\` 아래에 있다. 읽기만 한다(core D-7).
- "Zed에서 확인" 표시가 있는 값은 ITEMS가 갈래에게 확인을 맡긴 것이다. 확인하기 전까지 미정이고, 해당 Phase에서 확인해 이 문서에 더한다.

---

## R-1. UI 아이콘 모양을 Zed와 같게 한다

**요구**

UI 전체의 아이콘 모양이 Zed(또는 Zed 화면 캡처)와 같다.

- 이 레포의 현재 상태: gpui-kit의 `IconName` 아이콘과 `Segoe Fluent Icons` 글리프 폰트를 쓴다(`src/ui/layout.rs`, `src/ui/title_bar.rs`). `codicon` 문자열은 소스에 없다.

**정해진 결과**

- 아이콘 모양이 Zed와 같다.
- Zed 아이콘 원본(`zed/assets/icons/*.svg`, 299개)을 이 레포의 `.gitignore` 폴더에 복사해 그대로 쓴다. 대상은 UI 아이콘 전부다(core D-9).
- 아이콘은 SVG로 그리고 색은 `currentColor`로 두어 테마 색을 따른다(core D-9).
- 복사 폴더 경로, 출처 커밋, 복사본이 없을 때의 모습, 다시 채우는 방법: `DECISIONS.md` D-6.
- 예외: 창 제어 버튼 4개는 SVG가 아니라 Zed Windows와 같은 Segoe Fluent Icons 글리프로 그린다(`DECISIONS.md` D-7, core-leader 결정).
- 남은 비-Zed 출처: 파일 트리 파일 아이콘 `IconName::File`(Phase 7).

앱 자리와 Zed 아이콘의 대응(K-08 보고, 창 제어 4행은 K-08-R1). 근거는 Zed 커밋 `4304dec732a75505066de5ce2dbbfb2bec369498`의 저장소 상대 경로다.

| 앱 자리 | Zed 아이콘 | 근거 / 판정 |
|---|---|---|
| 타이틀 바 앱 메뉴 | `menu.svg` | `crates/title_bar/src/application_menu.rs:194` Menu |
| 창 최소화 | Segoe Fluent Icons 글리프 U+E921 | Zed Windows와 같음. `crates/platform_title_bar/src/platforms/platform_windows.rs:16–39,80–83` |
| 창 최대화 | Segoe Fluent Icons 글리프 U+E922 | Zed Windows와 같음. 위 파일, Fluent가 없으면 Segoe MDL2 Assets |
| 창 복원 | Segoe Fluent Icons 글리프 U+E923 | Zed Windows와 같음. 위 파일, 같은 글꼴 선택 |
| 창 닫기 | Segoe Fluent Icons 글리프 U+E8BB | Zed Windows와 같음. 위 파일, 같은 글꼴 선택 |
| sidebar 푸터 토글(열림) | `threads_sidebar_left_open.svg` | `crates/sidebar/src/sidebar.rs:7493` ThreadsSidebarLeftOpen |
| 상태 바 sidebar 토글(닫힘) | `threads_sidebar_left_closed.svg` | `crates/workspace/src/status_bar.rs:258` ThreadsSidebarLeftClosed |
| sidebar·상태 바 Add Project | `folder_add.svg` | `crates/sidebar/src/sidebar.rs:6772` FolderAdd |
| 상태 바 프로젝트 패널 / Close Left Dock | `file_tree.svg` | `crates/project_panel/src/project_panel.rs:8281` FileTree |
| 탭 뒤로 / 앞으로 | `arrow_left.svg` / `arrow_right.svg` | `crates/workspace/src/pane.rs:3508,3531` ArrowLeft·ArrowRight |
| Markdown 미리보기 탭 | `file_doc.svg` | `crates/markdown_preview/src/markdown_preview_view.rs:1664` FileDoc |
| 탭 고정 해제 | `pin.svg` | `crates/workspace/src/pane.rs:3040` Pin |
| 탭 닫기 | `close.svg` | 위 파일 :3055,3057 Close |
| 탭 새 항목 | `plus.svg` | 위 파일 :4366 Plus |
| 탭 분할 | `split.svg` | 위 파일 :4390 Split |
| pane 확대 / 축소 | `maximize.svg` / `minimize.svg` | 위 파일 :4417,4420 Maximize·Minimize |
| Markdown 툴바 Preview Markdown | `eye.svg` | `crates/zed/src/zed/quick_action_bar/preview.rs:43,64` Preview Markdown·Eye |
| sidebar 등록 폴더 | `folder.svg` | 애매: 앱 전용 등록 폴더 자리. Zed 기본 폴더와 같은 이름의 UI SVG, V3 대조 필요 |
| 프로젝트 트리 접힌/새 폴더 | `folder.svg` | 애매: Zed의 트리 폴더는 아이콘 테마 영역. 파일 아이콘 적용 유보(Phase 7)에 따라 UI SVG |
| 프로젝트 트리 열린 폴더 | `folder_open.svg` | 애매: 위와 같음. 새 폴더 입력은 접힌 폴더 표시 유지 |

**판정 방법**

UI의 모든 아이콘이 D-9로 복사한 Zed 원본 SVG에서 나온다(코드에서 아이콘 출처 대조). 같은 화면 캡처에서 아이콘 모양이 Zed와 같다. V3.

**출처**

I-1, core D-9. 요청 원문 "UI에 적용된 아이콘의 모양이 zed(또는 화면 캡처)와 다릅니다. codicon이 적용된 것 같음"(사용자 2026-11-06).

---

## R-2. 타이틀 바 오른쪽 최소화 버튼 앞에 "v" 메뉴를 둔다

**요구**

타이틀 바 오른쪽 최소화 버튼 바로 앞에 "v" 버튼이 있고, 누르면 Zed처럼 하위 메뉴 Settings, Keymap, Themes, Icon Themes, Extensions, Panel Layout이 나온다.

- 이 레포의 현재 상태: "v"가 없다(`refs/compare/REPORT.md`). 타이틀 바는 `src/ui/title_bar.rs`에 있다.

**정해진 결과**

- 메뉴만 두지 않고 각 항목이 Zed처럼 동작한다. 단축키도 Zed와 같다: Settings `Ctrl-,`, Keymap `Ctrl-K Ctrl-S`, Themes `Ctrl-K Ctrl-T`, Extensions `Ctrl-Shift-X`. Panel Layout은 하위 메뉴다(`refs/compare/I-2-zed.png`).
- Themes는 R-4, Icon Themes는 R-3의 선택 화면을 연다.
- Settings·Keymap·Extensions·Panel Layout이 여는 화면: Zed의 틀(여는 방식·배치·검색·컨트롤 모양·단축키)에 이 앱의 실제 내용만 담는다(core D-15, core ORDER-06-R1 2장). 화면별 항목은 아래 "2단계 화면별 항목 표".
- 이 요구는 루트 `INTENT.md` "다루지 않는 것"(설정 UI 화면, 화면을 추가하는 확장, 온라인 확장 목록)과 "쓰지 않는 기능의 아이콘·메뉴·옵션은 넣지 않는다"보다 우선한다(core D-12). 루트 INTENT 해당 줄에 예외를 표시했다.

**판정 방법**

타이틀 바 오른쪽 최소화 버튼 앞에 "v"가 있다. 누르면 Settings, Keymap, Themes, Icon Themes, Extensions, Panel Layout이 Zed와 같은 순서와 단축키로 나온다. 각 항목을 누르거나 단축키를 쓰면 Zed와 같은 화면이 열린다. V3.

**출처**

I-2. 요청 원문 "맨 위 상단바의 오른쪽 최소화 버튼 앞에 'v'로 zed에 있는 Settings / Keymap / Themes / Icon Themes / Extensions / Panel Layout 서브 메뉴 구성 필요", 정한 것 "'v' 메뉴 동작까지 구현"(사용자 2026-11-06).

**"v" 메뉴 표 (ORDER-06 1단계)**

coder 보고 `cards/K-09.report.md`의 "v 메뉴 표"에서 옮겼다. 항목 순서는 Zed `crates/title_bar/src/title_bar.rs`(커밋 `4304dec732a75505066de5ce2dbbfb2bec369498`)를 따랐다. 버튼 아이콘은 `chevron_down.svg`, 하위 메뉴 표시는 `chevron_right.svg`다.

| 항목 | 단축키 표시 | 지금 동작 |
|---|---|---|
| Settings | `Ctrl-,` | Settings 창을 연다(K-11-R1). 이미 열려 있으면 앞으로 |
| Keymap | `Ctrl-K Ctrl-S` | Keymap Editor 탭을 연다. 이미 열려 있으면 그 탭으로(K-14) |
| Themes… | `Ctrl-K Ctrl-T` | 비활성. Phase 7 |
| Icon Themes… | 없음 | 비활성. Phase 7 |
| Extensions | `Ctrl-Shift-X` | Extensions 탭을 연다. 이미 열려 있으면 그 탭으로(K-15) |
| (구분선) | | |
| Panel Layout | 없음 | 하위 메뉴를 연다(hover·클릭 또는 Enter·Right). K-11에서 하위 메뉴 동작 |
| Panel Layout > Classic | 없음 | 왼쪽 dock 열기·기본 폭으로 되돌리기(K-11-R1) |
| Panel Layout > Custom | 없음 | 체크·비활성. 배치가 기본과 다를 때만 보인다(K-11-R1) |

Panel Layout > Agentic은 core ORDER-06-R1 2.4로 뺐다(K-11-R1).

- 닫기: Escape·Ctrl-C·메뉴 밖 클릭·포커스 이탈. Left는 하위 메뉴를 닫는다. 닫으면 이전 포커스로 돌아간다(포커스 이탈이면 새 포커스 유지).
- Zed의 `Custom`은 사용자 정의 배치일 때만 나온다. 이 앱에서는 dock이 닫혔거나 폭이 기본과 다를 때 체크·비활성으로 보인다(core ORDER-06-R1 2.4).

**2단계 화면별 항목 표 (ORDER-06-R1)**

core D-15·ORDER-06-R1 2장, 이 레포 DECISIONS D-8·D-9에서 옮겼다. 두 갈래는 같은 내용(범주, 행, 열, 항목, 단축키)을 가진다. tauri 표(`D:\projects\workbench-tauri\specs0.5\SPEC.md` R-2, 읽기만)와 다른 곳은 `cards/W-22.report.md`에 있다. 저장 위치는 `%APPDATA%\workbench-gpui`이고 Zed 파일은 읽거나 쓰지 않는다.

*Settings — 별도 OS 창 (`Ctrl-,`, "v" 메뉴 Settings)*

| 자리 | 내용 |
|---|---|
| 창 | 별도 OS 창. 이미 열려 있으면 그 창을 앞으로 가져온다 |
| 검색 | 왼쪽 맨 위 검색칸 "Search settings…". 이름·설명에서 찾는다 |
| 범주 | `Appearance` 하나(이 앱 설정이 있는 Zed 범주만) |
| 범위 | `User`만(프로젝트 범위 설정 기능이 없다) |
| `Edit in settings.json` | 오른쪽 위 버튼. `%APPDATA%\workbench-gpui\settings.json`을 편집기 탭으로 연다. 파일이 없으면 `{}`로 만들어 연다 |
| 저장 | 값을 바꾸면 바로 저장·바로 적용. Zed settings.json 형식(JSONC 허용). 바뀐 키의 값만 고치고 주석·다른 키·내용을 보존한다. 잘못된 값은 그 키만 기본값으로 쓰고 오류를 알린다(core 결정 2026-11-07, tauri 방식) |

- 저장 방식 결과(K-13): 파일 전체를 다시 쓰지 않고 바꾼 키의 값 범위만 교체한다(jsonc-parser AST). 없는 키는 첫 속성 앞(빈 객체면 닫는 괄호 앞)에 더한다. 같은 키가 여러 번 있으면 모두 고친다. 주석·한글·CRLF·모르는 키·후행 쉼표를 보존하고, 원자 교체로 쓴다. 파일이 깨져 있으면 저장을 거부한다. 다른 키에 잘못된 값이 있어도 저장할 수 있고, 파일 안의 잘못된 값은 덮어쓰지 않는다. 시작할 때와 외부 변경 때 오류는 기존 앱 알림으로, Settings 저장 오류는 Settings 화면의 오류 자리에 보인다.

| 소제목 | 행 | 키 | 컨트롤 | 기본값 | Zed 이름 | Zed 설명 |
|---|---|---|---|---|---|---|
| Theme | Theme | `theme` | 드롭다운 | 지금 테마(`Default Light` 하나, Phase 7에서 늘어남) | Theme Name | The name of your selected theme. |
| Theme | Icon Theme | `icon_theme` | 드롭다운 | `Zed (Default)` 하나 | Icon Theme Name | The name of your selected icon theme. |
| Buffer Font | Buffer Font Size | `buffer_font_size` | 숫자 | 15 | Font Size | Font size for editor text. |
| UI Font | UI Font Size | `ui_font_size` | 숫자 | 16 | Font Size | Font size for UI elements. |

- 소제목 순서는 Zed 순서 Theme → Buffer Font → UI Font다(core-leader 결정 2026-11-07, ORDER-06-R2).
- 컨트롤(ORDER-06-R2, tauri SPEC R-2 표와 같다): 숫자는 감소·증가 버튼이 붙은 형태(높이 28, 1 단위), 드롭다운은 `chevron_up_down` 버튼(높이 28).
- 저장 충돌: 창을 연 뒤 디스크 settings.json이 바뀌었으면(변경·생성·삭제) 저장을 거부하고 알린다. 디스크 파일은 건드리지 않는다. 정상 저장 뒤에는 기준 원문을 갱신해 같은 창에서 이어서 바꿀 수 있다.
- 이 레포의 현재 상태(K-18): 위 소제목·행 순서와 컨트롤, 저장 충돌 거부를 넣었다. 숫자는 gpui-kit NumberInput(높이 28 상수), 드롭다운은 Select 아이콘을 `chevron_up_down.svg`로 바꿨다. 확인 V1(`settings::tests` 5 passed, 충돌 거부·디스크 보존·연속 저장·섹션 순서), checker C-29 리뷰 PASS. 화면(소제목·행 순서, 컨트롤 배치)은 V3 남음. Settings 입력·드롭다운 동작은 Phase 12 V4(ORDER-06-R2).
- tauri SPEC R-2 표와 남은 차이: Settings·"v" 버튼 모두 없음(C-29 대조 표 2.2·2.3 전 항목 일치).
- 기본값은 지금 앱 상수다. 파일이나 키가 없으면 이 값을 쓴다(DECISIONS D-8).
- Zed 이름·설명 출처: Zed 커밋 `4304dec732a75505066de5ce2dbbfb2bec369498` `crates/settings_ui/src/page_data.rs` `appearance_page`(`cards/K-11.report.md`). 두 글꼴 행은 Zed 원문 제목이 모두 `Font Size`라 원문을 쓰고, 컨트롤 접근성 이름만 UI Font Size·Buffer Font Size로 나눈다.

Settings 창 치수: tauri-leader가 2026-11-07 Zed 캡처 `D:\projects\workbench-tauri\specs0.5erify\ORDER-06\zed-settings-window.png`(클라이언트 1440×852, 100%, Zed One Dark)에서 잰 논리 px다(창 왼쪽 위 기준). 출처: tauri `SPEC.md` R-2 "Settings 창 Zed 실측값"(읽기만, core-leader 결정 2026-11-07: gpui는 이 표를 읽어 같은 값을 쓴다). `spec/zed-metrics.toml`에 없는 값이라 core D-12로 이 값을 쓴다. 캡처 한 장에서 잰 값이라 다른 배율·글꼴에서는 다시 잰다.

| 항목 | 값 | 비고 |
|---|---|---|
| 창 보이는 크기 | 900×750 | 캡처의 창 사각형 916×758은 좌우·아래의 보이지 않는 크기 조절 테두리 8px 포함 |
| 타이틀 바 | 위 32px, Zed가 그림 | 최소화·최대화·닫기. 창 모양은 메인 창과 같은 방식 |
| 타이틀 바 아래 경계 | 1px | 본문은 y=33부터 |
| 왼쪽 탐색 폭 | 225 + 오른쪽 경계 1px | 배경은 본문보다 한 단계 밝다(Zed One Dark: 탐색 (47,52,62), 본문 (40,44,51)) |
| 검색칸 | x 10~214(폭 205), 높이 28, 테두리 1px | 본문 위(y=33)에서 10 아래(y 43~70) |
| 범주 행 | 높이 28, pitch 28 | 첫 행 위 = 검색칸 아래 +12(y 83) |
| 선택 범주 행 | x 10~214, 배경 + 1px 테두리 | |
| 범주 글자 시작 | x 22 | 접기 chevron 포함 |
| 본문 | x 226~899, 폭 674 | |
| 본문 좌우 padding | 32 | 내용 폭 610 |
| 범위 칩 `User` | 글자 y 63~75 | 위 줄 |
| `Edit in settings.json` 버튼 | 높이 22(y 57~78) | 오른쪽 끝 = 내용 오른쪽 |
| 범주 제목 | 글자 y 110~121 | |
| 소제목 줄 | 글자 y 145~157 | 버퍼 글꼴 |
| 소제목 아래 선 | y 166, 1px | |
| 행 사이 구분선 | 1px, 내용 폭 | |
| 구분선 → 행 이름 글자 위 | 24 | |
| 이름 → 설명 첫 줄 | pitch 21 | |
| 설명 줄 | pitch 19 | |
| 마지막 설명 글자 아래 → 다음 구분선 | 20 | |
| 토글 | 32×20 | 오른쪽 끝 = 내용 오른쪽 |
| 드롭다운 | 높이 28, 폭은 글자에 맞춤(예 138) | 오른쪽 끝 = 내용 오른쪽 |
| 숫자 컨트롤 | 높이 28 | Zed 캡처에 없어 드롭다운 높이에 맞춘다 |

- 이 레포의 현재 상태(K-13): `src/ui/metrics.rs` `settings_window`의 pending 상수를 위 값으로 바꾸고 주석을 출처로 고쳤다 — 창 900×750, 탐색 폭 226(225 + 경계 1), 본문 padding 32, 탐색 padding 10, 범주 gap 12, 행 gap 24, 컨트롤 높이 28, `Edit in settings.json` 버튼 높이 22. 드롭다운 폭은 "글자에 맞춤"이라 고정 폭 상수(`CONTROL_WIDTH`)를 없애고 자동 폭으로 둔다. 화면 판정은 V3 남음.

*"v" 버튼 치수*

tauri-leader 2026-11-07 Zed 캡처 `zed-v-menu.png`(1440×852·100%)에서 잰 값이다. 출처: tauri `SPEC.md` R-2의 `"v" 버튼 Zed 실측` 절(읽기만, DECISIONS D-9 4).

| 항목 | 값 | 비고 |
|---|---|---|
| 버튼 | 22×22, 둥근 모서리 | I-608·I-609와 같다 |
| chevron 잉크 폭 | 8 | |
| 버튼 오른쪽 끝 ↔ 최소화 버튼 | 4 | |
| chevron 아이콘 크기 | 14 | `user_menu.button_icon_size`(I-601). ORDER-06-R2, tauri SPEC R-2 표와 같다 |

- 이 레포의 현재 상태(K-13 → K-16 → K-18): 버튼 22×22, 최소화 버튼까지 4(K-16, 타이틀 바의 폭 4 요소). chevron은 K-13에서 잉크 8을 목표로 ≈14.388px로 그렸고(R1 V3 3차 잉크 8 PASS), K-18에서 I-601대로 14px(`USER_CHEVRON_SIZE`)로 바꿨다. 14px의 래스터 잉크 폭은 V3 남음.

*Keymap — 편집 영역 새 탭 "Keymap Editor" (`Ctrl-K Ctrl-S`, "v" 메뉴 Keymap)*

| 자리 | 내용 |
|---|---|
| 위 줄 | 필터칸 "Filter action names…", `Edit in JSON`(`Ctrl-E`), `Create Keybinding`(`Ctrl-K`). 키 입력으로 찾기·필터 버튼은 구현할 수 있으면 둔다 |
| 표 열 | Action, Arguments, Keystrokes, Context, Source(Default/User) |
| 행 | 이 앱에 있는 액션과 바인딩 전부 |
| 편집 | 행을 골라 키 바인딩을 바꾸거나 새로 만든다. 저장하면 바로 적용 |
| `Edit in JSON` | 사용자 키맵 파일을 편집기 탭으로 연다 |
| 저장 | `%APPDATA%\workbench-gpui\keymap.json`, Zed keymap.json 형식(섹션 배열, `context`·`bindings`, JSONC 허용) |

- 이 레포의 현재 상태: 앱은 이미 이 파일을 사용자 키맵으로 읽는다. 경로는 `src/ui/keymap.rs` `keymap_path()`(`dirs::config_dir` + `workbench-gpui\keymap.json`), 읽기는 `src/keymap/file.rs`(JSONC, 오류 항목만 빼고 적용), 바뀌면 다시 읽는다(`src/ui/keymap.rs` 파일 감시).

실제 구성(K-14 → K-17, `src/ui/keymap_editor.rs`). ORDER-06-R2 1장대로 tauri SPEC R-2 표(Zed 기준)와 같게 했다. 대조 표는 `cards/C-29.report.md` 2.1:

| 자리 | 지금 구성 |
|---|---|
| 열기 | "v" 메뉴 Keymap·`Ctrl-K Ctrl-S` → 편집 영역 새 탭 "Keymap Editor". 같은 폴더(작업 공간)에 열려 있을 때만 그 탭을 앞으로 가져온다(K-17. Extensions의 기존 탭 찾기 범위는 그대로). 폴더가 없어도 설정 workspace에서 연다. 도구 탭이라 문서(Docs)로 등록하지 않아 저장·감시 대상이 아니고, 닫을 때 저장 확인이 없다. 탭 이동·복제에서 내용을 유지한다 |
| 위 줄 | 필터칸 "Filter action names…", `Edit in JSON  Ctrl-E`, `Create Keybinding  Ctrl-K` |
| 필터 | 원래 이름과 읽기 쉬운 이름 모두에서, 대소문자 구분 없이 찾는다. 공백으로 나눈 검색어가 모두 들어 있어야 한다(AND) |
| 표 열 | Edit 아이콘, Action, Arguments, Keystrokes, Context, Source |
| Edit 아이콘 | 맨 앞 열, 폭 36, `pencil.svg`. 행 hover·포커스에서 보인다 |
| Action | 읽기 쉬운 형식(예 `pane::CloseActiveItem` → `pane: close active item`) |
| Arguments | 인자 없음 `<no arguments>`, null 액션 `<null>`, 배열 인자는 JSON. 사용자 원문에서 읽으므로 실행 파서가 적용하지 않는 배열 인자도 보인다 |
| Keystrokes | 표시 형식(예 `Ctrl-K Ctrl-S`). 바인딩 없는 액션은 빈 칸 |
| Context | 원문. 없으면 `<global>` |
| Source | `Default`(gpui-kit·앱 기본) 또는 `User`(사용자 키맵) |
| 행 | 실행 중인 키맵의 gpui-kit·앱 기본·사용자 바인딩 전부 + 바인딩 없는 앱 액션. Action 이름순 |
| 편집 진입 | Edit 아이콘 클릭·행 더블클릭·Enter → 편집 모달. 단일 클릭은 행 포커스만 옮긴다. `Create Keybinding`도 모달을 연다 |
| 편집 모달 | 폭 544, 본문 gap 10, 바닥 gap 4(K-080·K-082·K-083). Action은 등록 액션 자동완성(`<null>` 선택 가능). 키는 Record로 입력: 기존 키를 비우고 최대 3타(K-055), 수정자 키 단독은 무시, 포커스를 잃거나 모달을 닫으면 중단. 배열 인자의 GUI 편집은 거부하고 JSON 편집을 안내한다 |
| 저장 충돌 | 모달을 열 때의 원문·파일 존재 여부를 보관하고, 저장 직전 디스크와 다르면(변경·생성·삭제) 저장을 거부하고 앱 알림과 모달 오류로 알린다. 디스크 파일은 건드리지 않는다 |
| 저장 | 파일 전체를 다시 쓰지 않고 배열 끝에 override 섹션을 더한다. 키나 컨텍스트를 바꾸면 옛 키를 `null`로 푸는 섹션과 새 키 섹션을 더한다. 주석·키·내용·BOM·후행 쉼표를 보존하고 원자 교체로 쓴다. 파일이 깨져 있으면 저장을 거부한다. 저장 뒤 기존 load로 바로 적용한다. UI 기본 액션도 사용자 파일에서 쓸 수 있게 사용자 키맵 읽기가 등록 액션도 확인한다 |
| `Edit in JSON` | 사용자 keymap.json을 일반 편집기 탭으로 연다. 파일이 없으면 `[]`로 만든다 |

- Zed와 다른 점: 키 입력으로 찾기·필터 버튼이 없다(ORDER-06-R1 2.2 선택 사항). 배열 인자는 GUI로 편집하지 않고 JSON 편집을 안내한다(tauri와 같다). 반복 편집하면 override 섹션이 쌓인다(코드 `shortcut:` 주석).
- tauri SPEC R-2 표와 남은 차이: 없음(C-29 대조 표 2.1 전 항목 일치).
- 확인: V1(K-17, `cargo test keymap` 22 passed — 표시 형식·AND 검색·원래 이름 검색·JSON 인자·null·global, 녹화 최대 3타, 디스크 변경·생성·삭제 때 거부와 바이트 보존, 충돌 없는 저장), checker C-29 리뷰 PASS. 화면(K-010~K-022, Edit 열 K-022·K-036, 모달 K-080~K-083, hover·포커스 아이콘)은 V3 남음. 모달 포커스·Record·자동완성 입력은 Phase 12 V4(ORDER-06-R2).

*Extensions — 편집 영역 새 탭 "Extensions" (`Ctrl-Shift-X`, "v" 메뉴 Extensions)*

| 자리 | 내용 |
|---|---|
| 제목 | "Extensions" |
| 검색 | 검색칸 "Search extensions…" |
| 전환 | `All` / `Installed` / `Not Installed` |
| 범주 칩 | `All`, `Themes`, `Icon Themes` |
| 카드 목록 | 이름, 버전, 태그, 설명, 작성자, 오른쪽 버튼 자리 |
| 내용 | 이 앱에 들어 있는 확장 자원만. core D-8·D-9로 복사한 테마(Ayu, Gruvbox, One, Catppuccin, macOS Classic)와 아이콘 테마(Zed 기본, Catppuccin Icons) |
| 카드 값 | 버전·작성자·설명은 복사한 원본의 메타데이터(확장 manifest 등)에서. 없으면 비워 둔다 |

- Zed와 다른 점: 온라인 목록, 설치·제거, `Install Dev Extension`이 없다(core D-8, 실행 중 내려받기 없음). 카드 오른쪽 버튼 자리에는 설치 상태 표시만 둔다. 범주 칩은 Zed의 8개(All, Languages, Themes, Icon Themes, Language Servers, Debug Adapters, MCP Servers, Snippets) 가운데 셋만 둔다. 다운로드 수는 없다.
- 이 화면은 Phase 7(테마 복사) 뒤에 내용이 채워진다. 이번에는 틀과 지금 있는 자원으로 채워지는 것까지 한다. Phase 7에서 목록이 늘어나는지 확인한다.

실제 구성(K-15, `src/ui/extensions.rs`):

| 자리 | 지금 구성 |
|---|---|
| 열기 | "v" 메뉴 Extensions·`Ctrl-Shift-X` → 편집 영역 새 탭 "Extensions". 이미 열려 있으면 그 workspace·pane·탭을 활성화(Keymap Editor와 같은 도구 탭 흐름 `open_tool`) |
| 위 | 제목 "Extensions", 검색칸 "Search extensions…", 오른쪽에 `All`/`Installed`/`Not Installed` |
| 범주 칩 | `All`, `Themes`, `Icon Themes` |
| 카드 | 이름·버전, 태그(범주 이름), 설명, 작성자, 오른쪽 `Installed` 표시 |
| 검색 | 이름·설명·작성자에서 대소문자 구분 없이. 공백으로 나눈 검색어가 모두 들어 있어야 한다(AND). 버전·태그는 찾지 않는다(K-18) |
| 정렬 | 테마 파일 경로 순 → 같은 파일 안 `themes` 배열 순, 아이콘 테마는 맨 뒤. 필터 뒤에도 이 순서를 유지한다(K-18) |
| 빈 상태 | `All` "No extensions", `Installed` "No installed extensions", `Not Installed` "No uninstalled extensions". 검색어가 있으면 ` that match "검색어"`를 붙인다(K-18) |
| 버전 표시 | 있으면 `v` + 버전, muted 색. 없으면 버전 요소를 만들지 않는다(K-18) |
| 자원 목록 | `RESOURCES` 한 곳. 지금은 `Default Light`(Themes, gpui-kit 기본 테마)와 `Zed (Default)`(Icon Themes, `resources/zed-icons`) 둘. 이름은 settings의 실제 테마·아이콘 테마 이름 |
| 카드 값 | 메타데이터 출처는 테마 JSON의 theme 필드 우선, 없거나 빈 값이면 family 루트 필드, 그것도 없으면 빈 값(지어내지 않는다)(K-18). 지금 두 자원은 해당 메타데이터가 없어 버전·작성자·설명이 비어 있다 |
| 상태 전환 | 모든 자원이 번들이라 `All`과 `Installed`의 내용이 같고 `Not Installed`는 빈 목록 |
| 치수 | `spec/zed-metrics.toml` extensions X-45~X-49를 `metrics.rs` 토큰으로 쓴다 |

- Phase 7: 복사한 테마·아이콘 테마와 원본 메타데이터를 `RESOURCES`에 더하면 화면과 필터에 함께 반영된다. 복사 경로가 아직 미정이라 디렉터리 자동 탐색은 넣지 않았다.
- tauri SPEC R-2 표와 남은 차이(tauri `reports/ORDER-06-R2.md` 3절 번호): 1·2·5·6·7·8은 K-18로 맞췄다(C-29 대조 표 2.4 일치). 3 자원 목록(gpui `Default Light`, tauri `One Dark`·`One Light`)과 4 목록 구성(gpui `RESOURCES` 고정, tauri 빌드 때 자동 읽기)은 Phase 7(ORDER-07)에서 맞춘다. 9 치수는 같은 스펙 ID 값이고 적어 둔 ID 범위만 다르다(tauri X-44~X-49·L-05~L-07).
- 확인: V1(K-15, K-18 `extensions::tests` 3 passed — 검색·정렬·빈 상태·메타데이터 우선순위·버전 표시), checker C-29 리뷰 PASS. 화면(X-45~X-49 제목·검색·상태 전환·범주·카드, 빈 상태·카드 표시)과 메뉴·`Ctrl-Shift-X` 진입, 기존 탭 활성화는 V3·입력 검증 남음.

*Panel Layout — 하위 메뉴*

| 항목 | 표시 | 동작 |
|---|---|---|
| Classic | 배치가 기본이면 체크 | 왼쪽 dock 열기 + dock 폭을 기본 폭으로 되돌리기. 다른 pane·sidebar·탭 배치는 바꾸지 않는다 |
| Custom | 배치가 기본과 다를 때만 보이고 체크·비활성 | 없음 |

- 기본 배치 = dock이 열려 있고 실제 폭이 기본 폭과 같다. 둘 중 하나라도 다르면 Custom이다.
- 기본 폭: `src/ui/metrics.rs` `DOCK_DEFAULT_WIDTH = rems_from_px(240.)`, rem 16 기준 240px(K-11 보고). tauri는 `project_panel.default_width`(L-32) 240px로 같다.
- 창이 매우 좁아 실제 폭이 본문 폭 한계로 줄면 Classic으로 되돌린 뒤에도 Custom으로 보일 수 있다(`src/ui/mod.rs` `effective_dock_width`, K-11 보고).
- Agentic은 넣지 않는다. 이 앱에는 AI·에이전트 패널이 없다(core D-15).

**판정 (ORDER-06-R1 3장)**

- "v" 메뉴의 Settings·Keymap·Extensions·Panel Layout이 위 표대로 열리고 동작한다. 단축키도 같다.
- 설정·키맵 변경이 저장되고 앱을 다시 실행해도 유지된다(V1 테스트 + V3).
- 두 갈래의 화면별 항목 표가 같다.
- 같은 조건(1440×852, 100%)의 앱·Zed 캡처로 틀(배치·영역·컨트롤 모양)이 Zed와 같다(V3). 내용 차이는 "Zed와 다른 점"으로 적는다.

---

## R-3. Zed처럼 아이콘 테마를 추가하고 고를 수 있게 한다

**요구**

미리 정한 아이콘 테마 목록에서 하나를 고르면 UI 아이콘이 그 테마로 바뀐다. R-2의 Icon Themes 메뉴와 이어진다.

- 이 레포의 현재 상태: 앱 메뉴에 "Select Icon Theme..." 항목이 있다(`src/ui/app_menu.rs`). 실행 중인 `≡` 메뉴에는 보이지 않았고 고르는 UI가 없다(`refs/compare/REPORT.md`). 실제 동작은 확인하지 않았다.

**정해진 결과**

- 목록은 이 PC의 Zed에서 쓸 수 있는 아이콘 테마를 모두 복사한 것이다: Catppuccin Icons(MIT), Zed 기본 파일 아이콘(`zed/assets/icons/file_icons`, 96개, "Zed 기본"으로 다룬다)(core D-8·D-9).
- 복사본은 전부 이 레포의 `.gitignore` 폴더에 두고, 원본의 라이선스 문서도 함께 둔다. 실행 중에 내려받지 않는다(core D-8).
- 복사 폴더 경로, 복사 방법, 복사본이 없을 때의 모습, 기본값(Zed (Default)): `DECISIONS.md` D-11.

**아이콘 테마 대응** (K-20, 2026-11-07)

| 앱 자리 | 아이콘 테마 JSON에서 찾는 순서 |
|---|---|
| 파일 트리 파일 | 이름 전체 → 점으로 나눈 접미사 순서대로 → 첫 점 앞 stem 순서로 `file_stems`·`file_suffixes`, 없으면 `default`. 테마에 없는 키는 Zed (Default)로 |
| 파일 트리 폴더 | `named_directory_icons[이름]`, 없으면 `directory_icons` |
| 탭 | 파일 아이콘을 그리지 않는다. Zed 기본값 `tabs.file_icons=false`(core-leader DECISION 2026-11-07, K-22). 탭의 미리 보기 구분 아이콘은 UI 아이콘이라 아이콘 테마 대상이 아니다 |
| UI 아이콘(R-1) | 바꾸지 않는다 |

- 목록: 9개. Zed (Default)(D-6 복사본 아이콘, Zed 커밋 `4304dec`의 연결표를 데이터 JSON으로 다시 쓴 것: stem 5·suffix 291·아이콘 92), Catppuccin 4종(Latte·Frappé·Macchiato·Mocha), Catppuccin Monochrome 4종(v1.24.0)(K-20, 복사본 JSON 기준 개수 K-22).
- 순서: dark 이름순 → light 이름순. 테마 선택기와 같은 규칙이다(K-22).
- 그리기: Zed (Default)는 글자색 마스크, 그 밖의 테마는 SVG 자체 색. 아이콘 테마 데이터가 없으면 Phase 5 아이콘으로 그린다(K-20).
- 선택기 모양·치수·스크롤바는 R-4의 "Select Theme…" 선택기와 같다(K-21·K-22).
- Extensions 탭은 `extension.toml`이 있는 확장만 카드로 보인다: Catppuccin Icons 1.24.0(테마 카드는 R-4). 내장 Zed (Default)는 카드가 없다(K-22).
- V3(2026-11-07): Zed 트리 아이콘 비교는 측정 불가(Zed가 단일 파일로만 열려 트리가 없음). V1 근거(`icon_theme` 테스트, 매핑·SVG 존재)로 판정한다. 재측정 예정(`verify/reviews/measure-ORDER-07.md` 4장).

**판정 방법**

Icon Themes 선택 화면에 D-8로 복사한 아이콘 테마가 모두 나온다. 하나를 고르면 파일 트리와 탭의 파일 아이콘이 그 테마로 바뀐다. 같은 아이콘 테마를 고른 Zed 캡처와 모양이 같다. V3.

**출처**

I-3, core D-8·D-9. 요청 원문 "zed와 같이 아이콘팩 추가 기능 구현 - 항목을 미리 정하고 해당 깃헙 주소 또는 미리 다운로드 받아서 선택하도록"(사용자 2026-11-06).

---

## R-4. 테마를 추가하고 "v" 메뉴의 Themes에서 골라 바꿀 수 있게 한다

**요구**

미리 정한 테마 목록에서 하나를 고르면 UI 테마가 그 테마로 바뀐다. 방식은 R-3과 같다.

- 이 레포의 현재 상태: 앱 메뉴에 "Select Theme..." 항목이 있다(`src/ui/app_menu.rs`). 실행 화면에서 고르는 UI는 없다. 색은 gpui-kit 테마(`cx.theme()`)를 쓴다(`AGENTS.md` 5장). 두 갈래의 테마 지원 수준이 같은지는 확인하지 않았다(다르면 `[BLOCKED]`, core D-3).

**정해진 결과**

- 목록은 이 PC의 Zed에서 쓸 수 있는 테마를 모두 복사한 것이다: Zed 기본 Ayu 3종, Gruvbox 6종, One Dark·Light, 설치된 확장 Catppuccin, macOS Classic(모두 MIT)(core D-8).
- 복사본은 전부 이 레포의 `.gitignore` 폴더에 두고, 원본의 라이선스 문서도 함께 둔다(core D-8).
- 두 앱의 테마가 다르게 보이는 것(gpui 밝은 테마, tauri 어두운 테마)은 이 요구에서 다룬다(ITEMS 사용자 답변 메모).
- 기본 테마는 One Dark다(`settings.json`에 `theme`이 없을 때, `DECISIONS.md` D-11).

**테마 대응 표** (K-19, 2026-11-07)

복사한 Zed 테마 JSON의 토큰을 gpui-kit 테마(`cx.theme()`)와 앱 자리에 대응한다. 원본에 없는 선택적 색은 gpui-kit 모드 기본값을 쓰고 수치를 추정하지 않는다. 창 닫기 버튼의 Windows 빨강과 실측 그림자 값은 테마와 무관하다.

| 앱 자리 | 원본 Zed 토큰 → 적용 대상 |
|---|---|
| 편집 영역·미리보기·Settings/Keymap/Extensions 배경 | `editor.background` → `background` |
| UI 글자, 보조 글자 | `text`, `text.muted` → `foreground`, `muted_foreground` |
| 경계·포커스 | `border`, `border.focused` → `border`, `ring` |
| 강조·링크 | `text.accent` → `primary`, `accent`, `link` |
| 타이틀 바 | `title_bar.background` → `title_bar` |
| 탭 바 | `tab_bar.background` → `tab_bar` |
| 상태 바 | `status_bar.background` → `status_bar` |
| 패널·사이드바·목록 바탕 | `panel.background` → `sidebar`, `list` |
| 메뉴·모달·툴팁 | `elevated_surface.background`, `text` → `popover`, `popover_foreground` |
| 컨트롤·호버·선택 행 | `element.background`, `element.hover`, `element.selected` → `secondary` 계열, `list_hover`, `list_active` |
| 보조 표면·미리보기 코드 배경 | `surface.background` → `muted` |
| 편집 글자·바탕 | `editor.foreground`, `editor.background` → `editor_foreground`, `editor_background` |
| 현재 줄 | `editor.active_line.background` → `editor_active_line` |
| 거터 바탕 | `editor.gutter.background` → `editor_gutter_background` |
| 줄 번호·현재 줄 번호 | `editor.line_number`, `editor.active_line_number` → 거터 테마(없으면 `muted_foreground`·`foreground`) |
| 텍스트 선택 | `players[0].selection` → `selection` |
| 스크롤바 | `scrollbar.track.background`, `scrollbar.thumb.background`, `scrollbar.thumb.hover_background` → `scrollbar` 계열 |
| 드롭 영역·드래그 테두리 | `drop_target.background`, `border.selected` → `drop_target`, `drag_border` |
| 오류·경고·성공 | `error`, `warning`, `success` → `danger`, `warning`, `success` |

- K-04-R1·K-07에서 고정했던 One Light 색(현재 줄·줄 번호)은 이제 One Light 테마 JSON에서 읽는다(K-19).
- 목록: 21개 테마(Zed 11, Catppuccin 8, macOS Classic 2). 선택기·Settings 드롭다운이 같은 이름 목록을 쓴다(K-19·K-20).
- 순서: dark 이름순 → light 이름순(선택기·Settings 공통 `theme::names()`, core-leader DECISION 2026-11-07, K-22).
- 토큰 대체 순서: 테마 JSON → T-26 파생(`docs/refs/01-zed/03-THEME-ICONS.md` T-26) → 같은 appearance의 One 값(One Dark/One Light) → T-26 고정값. tauri D-8과 같다(K-22). One에도 없는 일반 토큰은 gpui-kit 초기값을 유지한다(K-22 한계, Zed fallback 테마의 완전 재현은 아니다).
- Extensions 탭은 `extension.toml`이 있는 확장만 카드로 보인다: Catppuccin 0.2.27, Catppuccin Icons 1.24.0, macOS Classic 0.4.0의 3장. 내장 테마(One·Ayu·Gruvbox)는 카드가 없다(K-22).
- 복사 폴더 경로, 복사 방법, 복사본이 없을 때의 모습: `DECISIONS.md` D-11.

**선택기 치수** (Zed 실측, `verify/reviews/measure-ORDER-07.md` 3.2, Zed `4304dec732` 설치본, 2026-11-07)

테마·아이콘 테마 선택기 두 개에 쓴다(K-21). spec ID는 `spec/zed-metrics.toml` `[picker]`(W-30, 목록 `cards/W-30.report.md`).

| 항목 | Zed 실측 | spec ID | 앱(K-21) |
|---|---|---|---|
| 모달 외곽 너비 | 544px | `picker["theme_selector.measured.width"]` | 544 |
| 검색칸 높이 | 38px(테두리·패딩 포함, 내부 36px) | `picker["theme_selector.measured.search_height"]` | 38 |
| 목록 높이 | 384px(12행, 행 피치 31~32px) | `picker["theme_selector.measured.list_height"]`·`["theme_selector.measured.list_rows"]` | 최대 384, 행 32 |
| 요소 사이 간격 | 0(1px 경계로 접함) | `picker["theme_selector.measured.gap"]` | 0 |
| 아래 푸터 | 1px 구분선 + 38px(Install 행) | `picker["theme_selector.measured.footer_divider"]`·`["theme_selector.measured.footer_height"]` | 1 + 38 |

- 원문 `01-LAYOUT.md` 4.13(P-002·P-004)과 다른 2건(384가 모달인지 목록인지, 행 높이 30.65와 실측 피치)은 `spec/ambiguous.md` 5절에 미결로 있다(W-30).
- 스크롤바: 목록 위에 포인터가 있을 때만 보인다(편집 영역의 Always와 다르다, core-leader DECISION 2026-11-07, K-22).
- V3(2026-11-07): 앱 선택기 열림·미리 보기·Esc 복원은 4차에서 PASS(`verify/reviews/measure-ORDER-07-run4/summary.json`).

**판정 방법**

Themes 선택 화면에 D-8로 복사한 테마가 모두 나온다. 하나를 고르면 UI 색이 그 테마로 바뀐다. 같은 테마를 고른 Zed 캡처와 주요 색(배경, 글자, 경계, 강조)이 같다. V3.

**출처**

I-4, core D-8. 요청 원문 "테마 적용 필요. 'v' 항목의 Themes에서 추가 가능(Icon Theme과 마찬가지로, 미리 로컬 / 깃헙 주소에 관련) 테마 변경"(사용자 2026-11-06).

---

## R-5. 편집 중인 탭의 커서 위치와 파일 형식을 상태 바에 보인다

**요구**

마크다운 문서나 소스 코드 파일이 에디터 탭에서 편집 상태로 열려 있으면 상태 바에 `{line}:{column} {Filetype}`이 보이고, 커서가 움직이면 line·column이 바뀐다.

- 이 레포의 현재 상태: 상태 바는 `src/ui/layout.rs`의 `status_bar`다. 오른쪽에 `1:1`만 보이고 파일 형식이 없다(`refs/I-7-gpui.png`).

**정해진 결과**

- `13:27 Markdown`처럼 `{line}:{column}` 뒤에 한 칸 띄우고 파일 형식 이름을 보인다(`refs/I-5-zed.png`).
- 상태 바 안의 위치는 Zed와 같다. 오른쪽 아이콘 묶음 바로 앞이다(`refs/zed-split.png`).
- 마크다운 미리보기에서도 마우스로 누른 곳의 위치를 잡고 같은 형식으로 보인다. line·column은 누른 곳에 해당하는 원본 문서의 위치다.
- 열린 탭이 없을 때의 표시: Zed와 같게 한다. 위치·파일 형식 모두 보이지 않는다(아래 "Zed 확인").

**판정 방법**

마크다운 파일과 코드 파일을 편집 상태로 열고 커서를 옮기면 상태 바의 `{line}:{column}`이 그 위치로 바뀐다. 파일 형식 이름이 Zed와 같다. 미리보기에서 누른 곳에 해당하는 원본 위치가 같은 형식으로 보인다. 위치는 오른쪽 아이콘 묶음 바로 앞이다. 위치 계산은 V1 테스트, 화면은 V3.

**출처**

I-5. 요청 원문 "마크다운 문서 또는 소스코드 파일이 에디터 탭에서 편집 상태로 열리면, 상태바에 {line}:{column} {Filetype} 표시 필요 - zed에서 동작 방식임", 정한 것 "편집 상태가 아니라 미리보기일 때도 마우스 클릭으로 위치를 잡고 동일"(사용자 2026-11-06).


**Zed 확인(2026-11-07)**

조건: core ORDER-08 2장, Zed `4304dec` 설치본 `zed -n` 새 창, 1440×852, One Dark, 사용자 `base_keymap` VSCode. 출처: workbench-tauri의 Zed 확인(tauri `specs/v0.5/SPEC.md` R-5·R-19·R-22 "Zed 확인(2026-11-07)", W-34로 옮김, core ORDER-08 2장 "한 갈래가 먼저 확인했으면 읽어 써도 됨"). 캡처는 `D:\projects\workbench-tauri\specs\v0.5\verify\ORDER-08\` 아래(이하 `ORDER-08/`로 줄임).

| 상태 | 상태 바 오른쪽(오른쪽 아이콘 묶음 바로 앞) | 캡처 |
|---|---|---|
| 편집 중 | `5:23 Markdown` | `ORDER-08/zed-cursor.png` |
| 선택 있음 | `5:28 (5 characters) Markdown` — 위치는 선택 끝(커서), 괄호에 선택한 글자 수 | `ORDER-08/zed-selection.png` |
| 열린 탭 없음 | 위치·파일 형식 모두 없음, 오른쪽 아이콘만 | `ORDER-08/zed-no-tab2.png`, `ORDER-08/zed-end-run2.png` |
| Project Search 결과 탭(여러 파일 묶음) | `45:35 (8 characters)`만, 파일 형식 이름 없음 | `ORDER-08/zed-search-results.png` |
| Diagnostics 탭 | 둘 다 없음 | `ORDER-08/zed-diagnostics.png` |

- 선택 문구 규칙(tauri K-24 구현 `src/editor/position.ts`, Zed `crates/go_to_line/src/cursor_position.rs` 기준): 괄호 안에 선택이 2개 이상이면 `N selections`, 선택한 줄이 2줄 이상이면 `N lines`, 선택한 글자가 1자 이상이면 `N character(s)`를 `, `로 이어 보인다. 글자 수는 Unicode scalar 수다. 선택 끝이 줄의 0열이면 그 마지막 줄은 줄 수에 넣지 않는다. 캡처로 확인한 것은 글자 수 한 가지다.

*파일 형식 이름 대응 표* (Zed `4304dec732` `crates/grammars/src/*/config.toml`의 `name`·`path_suffixes`. tauri `src/editor/filetypes.json`, gpui K-23 `src/ui/status_languages.rs`와 같다)

| Zed 이름 | path_suffixes |
|---|---|
| Shell Script | sh, bash, bashrc, bash_profile, bash_aliases, bash_login, bash_logout, brushrc, bats, envrc, profile, zsh, zshrc, zshenv, zsh_profile, zsh_aliases, zsh_histfile, zlogin, zprofile, PKGBUILD, APKBUILD, ebuild |
| C | c |
| C++ | cc, ccm, hh, cpp, cppm, h, hpp, cxx, cxxm, hxx, c++, c++m, h++, hip, ipp, inl, ino, ixx, cu, cuh, C, H |
| CSS | css, postcss, pcss |
| Diff | diff, patch |
| Env | .env |
| Git Commit | TAG_EDITMSG, MERGE_MSG, COMMIT_EDITMSG, NOTES_EDITMSG, EDIT_DESCRIPTION |
| Go | go |
| Go Mod | mod |
| Go Work | work |
| JavaScript | js, jsx, mjs, cjs |
| JSON | json, flake.lock, geojson, topojson, prettierrc, json.dist, deno.lock |
| JSONC | jsonc, bun.lock, devcontainer.json, pyrightconfig.json, tsconfig.json, luaurc, swcrc, babelrc, eslintrc, stylelintrc, jshintrc |
| Markdown | md, mdx, mdwn, mdc, markdown, MD |
| Python | py, pyi, mpy |
| Rust | rs |
| TSX | tsx |
| TypeScript | ts, cts, mts |
| YAML | yml, yaml, pixi.lock, clang-format, clangd, bst |
| Plain Text | 위 표에 없는 suffix(fallback) |

- 맞추는 규칙: 파일 이름이 suffix와 같거나 `.{suffix}`로 끝나면 대응한다. 여러 개가 맞으면 긴 suffix가 이긴다(`tsconfig.json` → JSONC). 마크다운 미리보기 탭은 Markdown이다.

---

## R-6. 기본 창 크기를 1440×852로, 작업 영역 한가운데에 연다

**요구**

앱을 시작할 때 메인 창을 논리 1440×852로, 작업 표시줄을 뺀 작업 영역의 한가운데에 연다.

- 이 레포의 현재 상태: 크기를 정하지 않아 gpui 기본값으로 연다(`src/ui/mod.rs`의 `window_options()`). 새로 띄우면 창 테두리를 포함해 1552×1088, 왼쪽 184·위 -4로 열렸다(`refs/compare/I-6-gpui.png`). 최소 크기 360×240은 `src/ui/metrics.rs`에 있다.

**정해진 결과**

- 논리 1440×852로 연다.
- 작업 영역의 한가운데에 둔다.
- 최소 크기는 360×240이다.
- 마지막 창 크기는 기억하지 않는다. 매번 1440×852로 연다. 이 점은 Zed와 다르게 정했다(사용자 2026-11-06).

**판정 방법**

설정이나 기록이 없는 상태로 처음 실행하면 창 클라이언트 영역이 논리 1440×852이고 작업 영역 가운데에 있다. 360×240보다 작게 줄어들지 않는다. 크기를 바꾸고 다시 실행해도 1440×852로 열린다. V3.

**출처**

I-6. 요청 원문 "기본 창 크기가 다릅니다. 제안해 주세요.", "1920×1080 FHD 모니터입니다. 아래 작업표시줄도 있습니다. 필요시 확장하면 되므로 모니터 한가운데 위치하고 전체 해상도보다는 작은 크기로 제안해 주세요."(사용자 2026-11-06). 1440×852는 `specs/v0.1/SPEC.md` A-30.1·A-30.2의 Zed 측정 조건과 같다.

---

## R-7. 탭 아래 편집 영역의 경계를 한 줄, 직각 모서리로 한다

**요구**

에디터 탭 아래 문서 편집 영역(분할한 pane 각각)의 경계가 한 줄이고 모서리가 직각이다. workbench-tauri와 Zed와 같다.

- 이 레포의 현재 상태: 경계가 두 줄이고 모서리가 둥글다(`refs/I-7-gpui.png`). 탭 편집기는 gpui-kit `Editor`이고 `bordered(true)`일 때 자체 1px 테두리를 그린다(`src/ui/pane.rs` `editor_view`). pane 분할선과 닿는 변만 테두리를 끈다(v0.4 P4-E-F3). 원인 확정은 Phase 3에서 한다.

**정해진 결과**

편집 영역의 경계가 한 줄이고 모서리가 직각이다.

**판정 방법**

분할한 pane마다 편집 영역 경계가 한 줄이고 모서리가 직각이다. 확대 캡처에서 Zed와 같다. V3.

**출처**

I-7. 요청 원문 "gpui의 경우 탭 아래 문서 편집 영역의 경계가 테두리 2중이고, 코너가 라운드되어 있어, tauri와 zed와 다름"(사용자 2026-11-06).

---

## R-8. 마크다운 문서 편집 화면에서 자동 줄바꿈을 한다

**요구**

에디터 탭에서 편집 상태로 연 마크다운 문서의 긴 줄이 편집 영역 폭에서 자동으로 줄바꿈된다. Zed와 같다.

- 이 레포의 현재 상태: 이미 기대와 같다(사용자 2026-11-06 실행 화면). 바뀌지 않았는지 판정 방법으로 확인한다.

**정해진 결과**

긴 줄이 편집 영역 폭에서 줄바꿈되고 가로 스크롤바가 생기지 않는다.

**판정 방법**

마크다운 문서의 긴 줄이 편집 영역 폭에서 줄바꿈되고 가로 스크롤바가 생기지 않는다. V3.

**출처**

I-8. 요청 원문 "gpui는 마크다운 문서 편집창에서 자동 줄바꿈 - zed와 동일 / 하지만, tauri는 자동 줄바꿈이 되지 않음"(사용자 2026-11-06).

---

## R-9. 편집 영역에 마우스를 올렸을 때만 스크롤바를 보인다

**요구**

마우스가 편집 영역 위에 있을 때 스크롤바가 보이고, 벗어나면 사라진다. Zed와 같다.

- 이 레포의 현재 상태: 마우스를 올려도 스크롤바가 보이지 않는다(`refs/compare/I-9-*.png`).

**정해진 결과**

- 스크롤바가 보이는 조건이 Zed와 같다.
- 기대 정정(core-leader, 사용자 위임 2026-11-07, D-13): 판정 기준은 Zed 실제 동작이다. 위 "요구"의 "올렸을 때만 보인다"를 다음으로 바꿔 읽는다. 스크롤할 내용이 있으면 세로 스크롤바가 마우스 위치와 상관없이 늘 보이고, 가로 스크롤바는 내용이 가로로 넘칠 때만 보인다(마크다운은 I-8 줄바꿈으로 넘치지 않는다).
- Zed 실제 동작(2026-11-07, 두 갈래 leader가 마우스 입력으로 확인, gpui C-09 `verify/reviews/zed-ORDER-03.md`): 이 PC의 Zed(Windows `DynamicScrollbars` 미설정, 기본 설정)는 편집 영역 세로 스크롤바 thumb를 마우스가 창 밖·편집 영역 위·스크롤 중·멈춘 뒤 4초에서 모두 보인다. 숨김은 없다. 가로 스크롤바는 내용이 넘칠 때 보인다. C-08의 "첫 화면에서 보이지 않음"은 캡처 방식(PrintWindow) 때문이었다.

**판정 방법**

마우스가 편집 영역 밖에 있을 때와 위에 있을 때, 스크롤 중과 멈춘 뒤에 스크롤바가 보이는 조건이 Zed와 같다(위 확인 결과). V3.

**출처**

I-9. 요청 원문 "zed에서는 탭 영역에 마우스가 호버링될 때, 스크롤바가 생김"(사용자 2026-11-06).

---

## R-10. 탭 바의 뒤로·앞으로 버튼에 툴팁을 보이고 동작하게 한다

**요구**

탭 바 왼쪽 뒤로(←)·앞으로(→) 버튼에 Zed와 같은 툴팁이 보이고, 버튼과 단축키로 탐색 기록을 따라 이동한다.

- 이 레포의 현재 상태: `Go Back`·`Go Forward` 툴팁이 나오지만 단축키는 없다(`refs/compare/I-10-*.png`). 사용자 보고로는 동작하지 않는다. 버튼을 눌러 이동하는지는 확인하지 않았다.

**정해진 결과**

- 툴팁 글자와 단축키 표시가 Zed와 같다. 비교 캡처의 Zed 툴팁은 `Go Back` 이름만 보였다(`refs/compare/I-10-zed.png`).
- 단축키는 뒤로 `Alt+Left`, 앞으로 `Alt+Right`다.
- 버튼을 누르거나 단축키를 쓰면 탐색 기록을 따라 뒤로·앞으로 이동한다.

**판정 방법**

두 버튼의 툴팁 글자와 단축키 표시가 Zed와 같다. 파일을 두 개 이상 차례로 연 뒤 뒤로·앞으로 버튼과 `Alt+Left`·`Alt+Right`로 이전·다음 위치로 이동한다. 이동 기록은 V1 테스트, 화면은 V3.

**출처**

I-10. 요청 원문 "Go Back Alt Left / Go Forward Alt Right 미표시 - 마우스 호버링 시 / 작동도 되지 않음 - 둘 다", "zed와 동일하게"(사용자 2026-11-06).


**Zed 확인(tauri, 2026-11-07)**

조건: core ORDER-09, Zed `4304dec` 설치본 `zed -n` 새 창, 1440×852, 100%, One Dark, 사용자 `base_keymap` VSCode. 출처: workbench-tauri의 Zed 확인(tauri `specs/v0.5/SPEC.md` 해당 R-n "Zed 확인(2026-11-07)", 커밋 `bba6cfc`, W-41로 옮김, core-leader [NOTICE]). 캡처는 `D:\projects\workbench-tauri\specs\v0.5\verify\ORDER-09\` 아래(이하 `ORDER-09/`로 줄임). 근거 열은 이 레포 checker의 Zed 소스 확인(`cards/C-36.report.md`, Zed `4304dec` 파일:줄).

| 항목 | Zed | 캡처 | 근거(C-36) |
|---|---|---|---|
| 뒤로 툴팁 | "Go Back" + `Alt-Left` | `ORDER-09/zed-tip-back.png` | `crates/workspace/src/pane.rs:3514`, 키는 `Tooltip::for_action_in` |
| 앞으로 툴팁 | "Go Forward" + `Alt-Right` | `ORDER-09/zed-tip-forward.png` | `pane.rs:3536` |
| 기록이 없을 때 | 버튼이 흐림(비활성) | `ORDER-09/zed-tip-back.png`·`zed-tip-forward.png` | `pane.rs:3519, 3541`(disabled), 버튼은 늘 보임 `pane.rs:3614`·`assets/settings/default.json:1479` `show_nav_history_buttons` |
| Windows 키 | `pane::GoBack` 마우스 뒤로 버튼·`alt--`·`alt-left`, `pane::GoForward` 마우스 앞으로 버튼·`alt-=`·`alt-right` | 없음 | `assets/keymaps/default-windows.json:516-521` |

이동 기록(상태 바 위치로 확인, `ORDER-09/zed-nav-*.png`):

| 순서 | 조작 | 결과 위치 |
|---|---|---|
| 1 | 시작 | AGENTS.md `5:23` |
| 2 | `Ctrl-P`로 App.tsx 열기 | App.tsx `1:1` |
| 3 | `Ctrl-G` 66 | App.tsx `66:1` |
| 4 | `Alt-Left` | App.tsx `1:1` |
| 5 | `Alt-Left` | AGENTS.md `5:23` |
| 6 | `Alt-Right` | App.tsx `1:1` |
| 7 | `Alt-Right` | App.tsx `66:1` |
| 8 | `Ctrl-End` | App.tsx `75:1`(9줄 이동) |
| 9 | `Alt-Left` | App.tsx `1:1`(`66:1`이 아님) |

- 파일 열기와 Go to Line 점프는 기록되고, 9줄 커서 이동은 기록되지 않는다.

기록 규칙(C-36 Zed 소스):

| 규칙 | 근거 |
|---|---|
| pane마다 따로 기록한다(분할 pane은 독립 스택) | `crates/workspace/src/pane.rs:413, 586` |
| 탭을 떠날 때(비활성화) 그 커서 위치를 기록한다 | `crates/editor/src/items.rs:907` `Item::deactivated` |
| 같은 파일 안에서는 커서가 10줄 이상 움직였을 때만 기록한다 | `crates/editor/src/editor.rs:307` `MIN_NAVIGATION_HISTORY_ROW_DELTA = 10`, `crates/editor/src/navigation.rs:1567` |
| Go to Line 같은 명시적 점프는 줄 수와 상관없이 항상 기록한다(`always: true`) | `navigation.rs:1567`(C-36의 예는 `go_to_definition`) |
| 닫힌 탭의 기록도 남는다. 돌아가면 그 경로로 다시 열고 그 위치로 간다 | `crates/workspace/src/workspace.rs:3300-3345` |
| 기록 상한 1024개 | tauri 확인(tauri K-38 보고, 곧 tauri R-10에 옮겨짐). 이 레포 checker 확인 전 |

---

## R-11. 탭 제목에 마우스를 올리면 파일 전체 경로를 툴팁으로 보인다

**요구**

탭 제목 위에 마우스를 올리면 그 파일의 절대 경로가 툴팁으로 보인다(예: `D:\projects\workbench-gpui\INTENT.md`).

- 이 레포의 현재 상태: 툴팁이 없고 닫기 `×`만 나타난다(`refs/compare/I-11-*.png`).

**정해진 결과**

탭 제목 툴팁이 그 파일의 절대 경로다. Zed와 같다(`refs/I-11-zed.png`).

**판정 방법**

탭 제목에 마우스를 올리면 그 파일의 절대 경로가 툴팁으로 보인다. V3.

**출처**

I-11. 요청 원문 "탭 제목에 마우스를 호버링했을 때 - 파일 경로가 나타나야 함"(사용자 2026-11-06).


**Zed 확인(tauri, 2026-11-07)**

조건: core ORDER-09, Zed `4304dec` 설치본 `zed -n` 새 창, 1440×852, 100%, One Dark, 사용자 `base_keymap` VSCode. 출처: workbench-tauri의 Zed 확인(tauri `specs/v0.5/SPEC.md` 해당 R-n "Zed 확인(2026-11-07)", 커밋 `bba6cfc`, W-41로 옮김, core-leader [NOTICE]). 캡처는 `D:\projects\workbench-tauri\specs\v0.5\verify\ORDER-09\` 아래(이하 `ORDER-09/`로 줄임). 근거 열은 이 레포 checker의 Zed 소스 확인(`cards/C-36.report.md`, Zed `4304dec` 파일:줄).

| 항목 | Zed | 캡처 | 근거(C-36) |
|---|---|---|---|
| 탭 툴팁 | 탭 아래에 절대 경로 `D:\projects\workbench-tauri\AGENTS.md`(역슬래시) | `ORDER-09/zed-tip-tab.png` | `crates/editor/src/items.rs:706` `file.worktree.absolutize(&file.path).compact()`, `crates/workspace/src/pane.rs:3104-3108` |
| "+" 버튼 툴팁 | "New…"(키 없음) | `ORDER-09/zed-tip-plus.png` | 없음(C-36 범위 밖) |

- C-36 추가(캡처 없음): 읽기 전용 파일은 경로 + "Read-Only Tab", 멀티버퍼는 그 제목. 툴팁 지연은 gpui 기본(약 500ms, `crates/ui/src/components/tooltip.rs`).

---

## R-12. 편집 영역 위에 파일 경로와 현재 제목 줄을 보인다

**요구**

탭 바 아래, 편집 영역 바로 위의 줄(지금은 오른쪽에 미리보기 버튼만 있는 줄) 왼쪽에 파일 경로와, 커서가 있는 곳의 제목 계층이 `›`로 이어져 보인다.

- 이 레포의 현재 상태: 이 줄에는 오른쪽 미리보기 버튼만 있다(`refs/I-7-gpui.png`).

**정해진 결과**

- 경로를 어디부터 보일지와 마크다운이 아닌 파일에서 무엇을 보일지 모두 Zed와 같다. 캡처로 본 Zed는 폴더를 하나만 열면 파일 이름부터(`INTENT.md › # INTENT — workbench-gpui › ## 무엇을 하는가`), 여럿 열면 폴더 이름부터(`workbench-gpui\INTENT.md › …`) 보인다.
- 분할된 창은 각자 자기 커서 위치의 제목 계층을 보인다(`refs/zed-split.png`).
- 코드 파일에서 Zed가 보이는 것: 경로 뒤에 커서를 포함한 심볼 계층(아래 "Zed 확인"). 이 레포는 Phase 11에서 한다(core [DECISION] 2026-11-07).
- Zed 캡처의 같은 줄 오른쪽 버튼들은 요청에 들어 있지 않다.

**판정 방법**

같은 파일, 같은 커서 위치에서 경로 줄 글자가 Zed와 같다. 확인은 폴더 하나와 여럿, 마크다운 파일과 코드 파일 각 한 경우씩 한다. V3.

**출처**

I-12. 요청 원문 "문서의 편집창 상단에 파일 경로/제목이 보여야 함", 정한 것 "zed와 동일하게"(사용자 2026-11-06).


**Zed 확인(tauri, 2026-11-07)**

조건: core ORDER-09, Zed `4304dec` 설치본 `zed -n` 새 창, 1440×852, 100%, One Dark, 사용자 `base_keymap` VSCode. 출처: workbench-tauri의 Zed 확인(tauri `specs/v0.5/SPEC.md` 해당 R-n "Zed 확인(2026-11-07)", 커밋 `bba6cfc`, W-41로 옮김, core-leader [NOTICE]). 캡처는 `D:\projects\workbench-tauri\specs\v0.5\verify\ORDER-09\` 아래(이하 `ORDER-09/`로 줄임). 근거 열은 이 레포 checker의 Zed 소스 확인(`cards/C-36.report.md`, Zed `4304dec` 파일:줄).

자리: 편집 영역 위 툴바 왼쪽.

| 경우 | Zed 경로 줄 | 캡처 | 근거(C-36) |
|---|---|---|---|
| 폴더 하나, 마크다운 1행 | `AGENTS.md › # AGENTS` | `ORDER-09/zed-a-start.png` | 경로 `crates/editor/src/editor.rs:11685` `file.path()` |
| 폴더 하나, 마크다운 5행 | `AGENTS.md › # AGENTS › ## 레포 규칙`(제목 전체 계층, 제목은 문법 색) | `ORDER-09/zed-bc-md-h2.png` | `crates/grammars/src/markdown/outline.scm`, `editor.rs:4025, 11707` |
| 하위 폴더 파일 | 루트 기준 상대 경로 `src\App.tsx`, `src\shell\Pane.tsx` | `ORDER-09/zed-bc-code.png` 등 | `editor.rs:11685`, 경로 첫 조각은 한 문자열(디렉터리마다 `›`로 나누지 않음) |
| 코드 파일, 66행(심볼 안) | `src\App.tsx › function App()`(심볼 계층, 문법 색) | `ORDER-09/zed-bc-code.png` | `editor.rs:4025, 11707`(LSP 또는 tree-sitter outline) |
| 코드 파일, 1행(심볼 밖) | 경로만 `src\App.tsx` | `ORDER-09/zed-bc-code.png` 계열 | 같음 |
| 폴더 둘 | 루트 폴더 이름부터: `workbench-tauri\AGENTS.md › # AGENTS`, `workbench-core\specs\v0.5\ITEMS.md › # ITEMS — workbench-core v0.5` | `ORDER-09/zed-bc-two-*.png` | `crates/language/src/buffer.rs:5533` `file.full_path()` |
| 분할 | pane마다 자기 커서 기준: 왼쪽 `… › # AGENTS`, 오른쪽 6행 `… › # AGENTS › ## 레포 규칙` | `ORDER-09/zed-split-right-click.png` | `crates/workspace/src/pane.rs:598`(pane마다 Toolbar) |

- 구분자 `›`는 placeholder 색, 조각이 12개를 넘으면 가운데를 `⋯`로 줄인다(C-36, `crates/editor/src/element.rs:7141, 7170`).
- 표시 조건: 설정 `toolbar.breadcrumbs`(기본 true), 단일 버퍼 파일일 때만(C-36, `assets/settings/default.json:598`, `crates/editor/src/items.rs:1107`).
- 툴바 오른쪽 버튼: Zed는 미리보기(마크다운만)·검색·AI·커서·설정이다. 이 앱은 미리보기만 둔다(core ORDER-09).
- Phase 9 범위(core [DECISION] 2026-11-07): 경로 + 마크다운 제목 계층까지 한다. 코드 파일의 심볼 계층은 Phase 11(ORDER-11)에서 한다. Phase 9에서 코드 파일은 경로만 보인다.


**코드 파일 심볼 기대값(core [NOTICE] 2026-11-07, Zed 캡처)**

같은 파일·커서에서 경로 줄 글자가 Zed와 같아야 한다. 캡처 `D:\projects\workbench-tauri\specs\v0.5\verify\ORDER-11\`(`zed-rs-sym.png`·`zed-ts-sym.png`·`zed-py-sym.png`), 샘플은 tauri `test-fixtures/syntax/`. 조건 1920×1080 100%, 클라이언트 1440×852, One Dark.

| 파일 | 커서 | 경로 줄의 심볼 글자 |
|---|---|---|
| `sample.rs` | 21행 | `impl Counter › pub fn bump › fn clamp` |
| `sample.ts` | 18행 | `class Inventory › add( ) › function normalize( )` |
| `sample.py` | 21행 | `class Library › def add › def normalize` |

- 심볼 글자는 문법 색(One Dark에서 keyword #b477cf, type, function)이다(tauri ORDER-11 보고 3행). 심볼 밖(예: `sample.html` 1행)은 경로만 보인다. 규칙은 R-15 "I-12 코드 파일 심볼(outline)".
---

## R-13. 커서가 있는 줄의 배경과 줄 번호를 강조한다

**요구**

커서가 있는 줄의 배경과 그 줄의 줄 번호가 강조된다. 자동 줄바꿈(R-8)으로 여러 줄로 보이는 줄도 한 줄로 강조된다. Zed와 같다.

- 이 레포의 현재 상태: 줄 번호 `1`만 굵고 배경 강조가 없다(`refs/compare/base-gpui.png`).

**정해진 결과**

- 커서 줄의 배경과 줄 번호가 강조되고, 커서를 옮기면 강조도 옮겨 간다.
- 강조 색: 지금 Light 테마에 Zed One Light 값을 쓴다(`docs/refs/01-zed/03-THEME-ICONS.md`).
  - 현재 줄 배경 `editor.active_line.background` `#ebebecbf`(T-05.05).
  - 현재 줄 번호 `editor.active_line_number` `#44454b`(T-05.08), 나머지 줄 번호 `editor.line_number` `#b4b4bb`(T-05.07).
- 줄 번호 색은 core D-14(gpui-base vendor)로 Zed 값에 맞춘다. 앞서 "(A) 현재 동작 유지"(core-leader DECISION 2026-11-07)는 D-14로 대체됐다(DECISIONS D-5).

**판정 방법**

커서가 있는 줄의 배경과 줄 번호가 강조된다. 줄바꿈으로 여러 줄로 보이는 줄은 그 전체가 강조된다. 커서를 옮기면 강조도 옮겨 간다. V3.

**출처**

I-13. 요청 원문 "zed에서는 커서가 위치한 줄의 배경이 강조되고, 자동 줄바꿈이 됩니다. 줄 번호 강조"(사용자 2026-11-06).

---

## R-14. UI·에디터 본문·미리보기의 글꼴을 Zed와 같게 한다

**요구**

UI 전체(타이틀 바, 메뉴, 파일 트리, 탭, 상태 바, 툴팁), 에디터 탭의 편집 영역, 마크다운 미리보기의 글꼴(글꼴 이름, 크기, 굵기, 줄 높이)이 Zed 기본값과 같다. 그 결과로 줄 번호 열 폭과 한글 글자 간격도 Zed와 같아진다.

- 이 레포의 현재 상태:
  - UI는 gpui-kit 기본 `.SystemUIFont`(Windows 시스템 UI 글꼴)다.
  - 에디터 본문은 gpui-kit 기본 mono 글꼴(Windows는 `Consolas`)이고 크기는 15다(`src/ui/metrics.rs` `BUFFER_FONT_SIZE`).
  - 미리보기 본문은 글꼴을 정하지 않아 UI 글꼴을 따르는 것으로 보이고, 코드는 mono 글꼴이다(`src/ui/markdown_preview.rs`).

**정해진 결과**

- 글꼴은 아래 Zed 기본값과 같다.

  | 자리 | Zed 기본값 |
  |---|---|
  | UI | `.ZedSans` = IBM Plex Sans, 16, 굵기 400, 합자(`calt`) 끔 |
  | 에디터 본문 | `.ZedMono` = Lilex, 15, 굵기 400, 줄 높이 comfortable(1.618) |
  | 미리보기 본문 | UI 글꼴을 따른다(`markdown_preview.font_family`·`font_size` 기본 null). 제목 굵기 600 |
  | 미리보기 코드 블록 | 에디터 글꼴을 따른다(`markdown_preview.code_font_family` 기본 null) |

- 미리보기 코드 블록 크기: 글자 16px(에디터 15가 아님), 줄 높이 16 × 1.618 = 25.888px. 근거: Zed 실측(tauri ORDER-03-R1 2절), core-leader NOTICE 2026-11-07.
- 줄 번호 열(ITEMS I-14 "줄 번호 열 폭도 Zed와 같다"): 1440×852, 100%, Lilex 15에서 편집기 왼쪽 끝 = 0px 기준, 허용 ±1px.

  | 자릿수 | 숫자 잉크 오른쪽 끝 | 본문 잉크 시작 |
  |---|---|---|
  | 4자리 이하 | 57 | 92 |
  | 5자리 | 66 | 101 |

  근거: Zed 실측(tauri ORDER-03-R1, `D:\projects\workbench-tauri\specs\v0.5\verify\ORDER-03-R1\ORDER-03-R1-judgement.md` 1절), core-leader NOTICE 2026-11-07. 스펙 E-003·E-004(3ch·4ch)와 다르며 이 실측이 우선한다(core D-12). gpui는 core D-14(gpui-base vendor)로 맞춘다.

- IBM Plex Sans와 Lilex의 글꼴 파일과 라이선스 파일(SIL OFL 1.1)을 이 레포에 넣고 커밋한다. 받는 곳은 각 글꼴의 공식 배포처(GitHub 릴리스)이고 버전을 문서에 남긴다(core D-10).
- 넣을 굵기·스타일 파일과 버전: IBM Plex Sans 1.1.0(`@ibm/plex-sans@1.1.0` 릴리스) Regular·Italic·SemiBold·SemiBoldItalic, Lilex 2.630(릴리스 `2.630`) Regular·Bold·Italic·BoldItalic(K-03, `cards/K-03.report.md`).
- 편집 영역 본문의 한글이 Zed처럼 고딕 계열로 보인다. Zed는 글꼴에 없는 글자를 Windows 기본 대체 글꼴로 그린다. 한글 대체 글꼴: Malgun Gothic(추정, C-08; 갈래 앱도 같은 글꼴로 맞춤, core-leader DECISION).

**판정 방법**

UI, 편집 영역, 미리보기 본문, 미리보기 코드 블록의 글꼴 이름·크기·굵기·줄 높이가 표의 Zed 기본값과 같다. D-10의 글꼴 파일과 라이선스 파일이 레포에 있다. 편집 영역의 한글이 굴림체가 아닌 고딕 계열이다(tauri는 개발자 도구 Rendered Fonts로 확인). 값은 V2, 화면은 V3, 글자 모양은 V4.

**출처**

I-14, core D-10. 요청 원문 "편집 기능일 때의 글꼴을 zed와 일치시키면 해결될 것 같습니다.", "UI에 사용된 글꼴과, 에디터 본문에 사용된 글꼴, 미리보기에 사용된 글꼴을 확인해 주세요. 모두 Zed와 동일하게 해 주세요.", "편집창 본문에서 tauri는 굴림체인 것 같고, gpui와 zed는 고딕 계열인데 이 글꼴로 보이게 해 주세요"(사용자 2026-11-06). Zed 기본값은 `zed/assets/settings/default.json`(main `4304dec732`).

---

## R-15. 편집 영역에서 구문 강조를 한다

**요구**

편집 상태의 편집 영역에서 Zed처럼 파일 형식에 따라 구문 강조를 한다. 마크다운(제목 등)을 비롯해 HTML을 포함한 코드 파일 형식마다 강조한다.

- 이 레포의 현재 상태: 편집 영역의 글자가 모두 한 색이다(`refs/compare/base-gpui.png`).

**정해진 결과**

- 지원할 파일 형식은 Zed가 지원하는 형식 전체다(사용자 2026-11-06).
- 형식 목록: 아래 "Zed 확인(tauri, 2026-11-07)"의 언어 목록(Zed 커밋 `4304dec732` 내장 언어 23개 + HTML 확장, W-48, 그리고 core 결정으로 Zed 확장 TOML v1.1.0과 git-firefly 0.1.9의 4개 언어, W-53). 옛 줄 "미정(Zed에서 확인, Phase 11)"은 이것으로 풀렸다.
- 강조 색은 테마(R-4)에서 온다(core PLAN Phase 순서의 이유).
- core D-18: Zed 커밋 `4304dec732` 내장 언어 전부를 Zed와 같은 문법 저장소·버전으로 한다(gpui는 tree-sitter crate를 정확한 버전으로 고정). 색은 Zed 쿼리(highlights·outline·injections 등)로 맞추고, 쿼리는 레포에 커밋하지 않고 `.gitignore` 폴더에 고정 커밋으로 복사한다. 다시 채우는 스크립트는 커밋한다. I-12 코드 파일 심볼 계층도 같은 outline 쿼리로 한다.
- core ORDER-11 2장: 실행 중에 이 PC의 Zed 설치 폴더나 확장 폴더를 읽지 않는다(core D-8). 쿼리 복사본이 없으면 강조 없이 평문으로 보이고 앱은 죽지 않는다. 두 갈래의 언어 목록과 하이라이트 이름 → 테마 `syntax` 토큰 대응은 같아야 하고, 언어 주입은 Zed와 같게 한다. 문법 라이선스를 Licenses 창에 넣는다.

**판정 방법**

Zed가 지원하는 파일 형식마다 샘플 파일을 열면 구문 강조가 된다. 마크다운과 HTML 샘플은 같은 테마의 Zed 캡처와 색이 같다. 형식 목록과 샘플 결과는 갈래 보고에 표로 남긴다. V3, 색 품질은 V4.

**출처**

I-15. 요청 원문 "마크다운 문서의 하이라이트가 되지 않습니다. 하이라이트 기능 필요. html 포함 코드별 하이라이트 필요"(사용자 2026-11-06).

**Zed 확인(tauri, 2026-11-07)**

tauri `D:\projects\workbench-tauri\specs\v0.5\SPEC.md` R-15(읽기만, 커밋 `208b900` 기준 — 카드의 `5dbf6d9` 뒤 라이선스 열·빌드 출처·쿼리 정규식이 더해졌다)에서 옮겼다. 표와 규칙은 글자까지 같게 두었다(두 갈래 목록이 같아야 함, core ORDER-11 2장). tauri 구현에만 해당하는 줄은 아래 "tauri 구현(참고)"로 묶었다.

**언어 목록 (ORDER-11, Zed 4304dec)**

출처: Zed 커밋 `4304dec732`. 언어 설정 `crates/grammars/src/<이름>/config.toml`, 내장 등록 `crates/languages/src/lib.rs` 91~229행 `built_in_languages`(23개, 아래 표와 같음), 문법 등록 `crates/grammars/src/grammars.rs` `native_grammars`(문법 이름 → crate), 버전 루트 `Cargo.toml` 947~968행과 `Cargo.lock`. 문법 열은 config.toml `grammar` 키다. 숨김(`hidden = true`)은 사용자가 고르는 언어 목록에 없고 주입이나 내부에만 쓰인다. 문법 라이선스는 K-49에서 문법 저장소 LICENSE 본문으로 확인했다(24행 모두 MIT). crate에 LICENSE가 없는 css·diff·jsdoc·json·regex는 crate의 `.cargo_vcs_info.json` 게시 커밋 archive에서 parser.c SHA256이 crate와 같은지 대조한 뒤 LICENSE만 가져왔다(열에 게시 커밋). 쿼리 라이선스는 문법과 따로다: Zed 쿼리(`crates/grammars`) GPL-3.0, HTML 확장 쿼리(`extensions/html`) Apache-2.0.

| 언어 이름(`name`) | 확장자·파일 이름(`path_suffixes`), `first_line_pattern` | 문법 → crate·저장소 | 버전/rev | 쿼리 파일 | 문법 라이선스 |
| --- | --- | --- | --- | --- | --- |
| Shell Script | sh bash bashrc bash_profile bash_aliases bash_login bash_logout brushrc bats envrc profile zsh zshrc zshenv zsh_profile zsh_aliases zsh_histfile zlogin zprofile PKGBUILD APKBUILD ebuild; `^#!.*\b(?:ash\|bash\|bats\|dash\|sh\|zsh)\b` | `bash` → tree-sitter-bash (crates.io) | 0.25.1 (Cargo.toml 947) | brackets · highlights · indents · injections · overrides · redactions · runnables · textobjects | MIT |
| C | c | `c` → tree-sitter-c (crates.io) | 0.24.1 (948) | brackets · debugger · highlights · indents · injections · outline · overrides · runnables · textobjects | MIT |
| C++ | cc ccm hh cpp cppm h hpp cxx cxxm hxx c++ c++m h++ hip ipp inl ino ixx cu cuh C H; `^//.*-\*-\s*C\+\+\s*-\*-` | `cpp` → tree-sitter-cpp, git https://github.com/tree-sitter/tree-sitter-cpp | 0.23.4, rev 5cb9b693cfd7bfacab1d9ff4acac1a4150700609 (949) | brackets · debugger · highlights · indents · injections · outline · overrides · runnables · textobjects | MIT |
| CSS | css postcss pcss | `css` → tree-sitter-css (crates.io) | 0.23.2 (950, `"0.23"`) | brackets · highlights · indents · injections · outline · overrides · textobjects | MIT (crate에 LICENSE 없음, 게시 커밋 c0d581e32d183a536731ed6c3a72758b27e20411) |
| Diff | diff patch | `diff` → tree-sitter-diff (crates.io) | 0.1.0 (951) | highlights · injections | MIT (crate에 LICENSE 없음, 게시 커밋 4867e8470e1b0ad7364c4e3ffab762c361bbb635) |
| Env | .env | `bash` → tree-sitter-bash (Shell Script와 같은 문법) | 0.25.1 (947) | brackets · highlights · injections · overrides · redactions | MIT |
| Git Commit | TAG_EDITMSG MERGE_MSG COMMIT_EDITMSG NOTES_EDITMSG EDIT_DESCRIPTION | `gitcommit` → tree-sitter-gitcommit, git https://github.com/zed-industries/tree-sitter-git-commit | 0.0.1, rev 88309716a69dd13ab83443721ba6e0b491d37ee9 (954) | highlights · injections | MIT |
| Go | go; `^//.*\bgo run\b` | `go` → tree-sitter-go, git https://github.com/zed-industries/tree-sitter-go | 0.25.0, rev 6862a49e3c5a7567a6c576420e9a8f944e198a85 (955) | brackets · debugger · highlights · indents · injections · outline · overrides · runnables · textobjects | MIT |
| Go Mod | mod | `gomod` → tree-sitter-gomod(package 이름, 의존성 이름 tree-sitter-go-mod), git https://github.com/camdencheek/tree-sitter-go-mod | 1.1.1, rev 2e886870578eeba1927a2dc4bd2e2b3f598c5f9a (956) | highlights · injections · structure | MIT |
| Go Work | work | `gowork` → tree-sitter-gowork, git https://github.com/zed-industries/tree-sitter-go-work | 0.0.1, rev acb0617bf7f4fda02c6217676cc64acb89536dc7 (957) | highlights · injections | MIT |
| JavaScript | js jsx mjs cjs; `^#!.*\b(?:[/ ]node\|deno run.*--ext[= ]js)\b` | `tsx` → tree-sitter-typescript의 TSX 문법(TSX와 같은 문법, 쿼리는 javascript 폴더 것) | TypeScript 행과 같음 | brackets · debugger · highlights · indents · injections · outline · overrides · runnables · textobjects | MIT |
| JSDoc (주입 전용/내부, hidden) | 없음 | `jsdoc` → tree-sitter-jsdoc (crates.io) | 0.23.2 (960, `"0.23"`) | brackets · highlights | MIT (crate에 LICENSE 없음, 게시 커밋 b253abf68a73217b7a52c0ec254f4b6a7bb86665) |
| JSON | json flake.lock geojson topojson prettierrc json.dist deno.lock | `json` → tree-sitter-json (crates.io) | 0.24.8 (961, `"0.24"`) | brackets · highlights · indents · outline · overrides · redactions · runnables · textobjects | MIT (crate에 LICENSE 없음, 게시 커밋 ee35a6ebefcef0c5c416c0d1ccec7370cfca5a24) |
| JSONC | jsonc bun.lock devcontainer.json pyrightconfig.json tsconfig.json luaurc swcrc babelrc eslintrc stylelintrc jshintrc | `jsonc` → tree-sitter-json(JSON과 같은 crate, `grammars.rs`에서 jsonc 이름으로 한 번 더 등록) | 0.24.8 (961) | brackets · highlights · indents · injections · outline · overrides · redactions · textobjects | MIT (crate에 LICENSE 없음, 게시 커밋 ee35a6ebefcef0c5c416c0d1ccec7370cfca5a24) |
| Markdown | md mdx mdwn mdc markdown MD | `markdown` → tree-sitter-md 블록 문법(`LANGUAGE`), git https://github.com/zed-industries/tree-sitter-markdown (9a23c1a 포크, serialize 버퍼 넘침 수정) | 0.3.2, rev b596e737286780d7bfa9fcddceaeeb754574b352 (962) | brackets · highlights · indents · injections · outline · textobjects | MIT |
| Markdown-Inline (주입 전용/내부, hidden) | 없음 | `markdown-inline` → tree-sitter-md 인라인 문법(`INLINE_LANGUAGE`) | Markdown 행과 같음 | highlights · injections | MIT |
| Python | py pyi mpy; `^#!.*((\bpython[0-9.]*\b)\|(\buv run\b))` | `python` → tree-sitter-python (crates.io) | 0.25.0 (963, `"0.25"`) | brackets · debugger · highlights · indents · injections · outline · overrides · runnables · textobjects | MIT |
| Regex (주입 전용/내부, hidden) | 없음 | `regex` → tree-sitter-regex (crates.io) | 0.24.3 (964, `"0.24"`) | brackets · highlights | MIT (crate에 LICENSE 없음, 게시 커밋 4470c59041416e8a2a9fa343595ca28ed91f38b8) |
| Rust | rs | `rust` → tree-sitter-rust (crates.io) | 0.24.2 (966) | brackets · debugger · highlights · indents · injections · outline · overrides · runnables · textobjects | MIT |
| TSX | tsx | `tsx` → tree-sitter-typescript의 TSX 문법(`LANGUAGE_TSX`) | TypeScript 행과 같음 | brackets · debugger · highlights · indents · injections · outline · overrides · runnables · textobjects | MIT |
| TypeScript | ts cts mts; `^#!.*\b(?:deno run\|ts-node\|bun\|tsx\|[/ ]node)\b` | `typescript` → tree-sitter-typescript(`LANGUAGE_TYPESCRIPT`), git https://github.com/zed-industries/tree-sitter-typescript (upstream PR 347 반영) | 0.23.2, rev e2c53597d6a5d9cf7bbe8dccde576fe1e46c5899 (967) | brackets · debugger · highlights · indents · injections · outline · overrides · runnables · textobjects | MIT |
| YAML | yml yaml pixi.lock clang-format clangd bst | `yaml` → tree-sitter-yaml, git https://github.com/zed-industries/tree-sitter-yaml | 0.6.1, rev baff0b51c64ef6a1fb1f8390f3ad6015b83ec13a (968) | brackets · highlights · injections · outline · overrides · redactions · textobjects | MIT |
| Zed Keybind Context (주입 전용/내부, hidden) | 없음 | `rust` → tree-sitter-rust(Rust와 같은 문법) | 0.24.2 (966) | brackets · highlights | MIT |
| HTML (Zed 레포 안 확장, 내장 아님) | html htm shtml (`extensions/html/languages/html/config.toml`) | `html` → https://github.com/tree-sitter/tree-sitter-html (`extensions/html/extension.toml` `[grammars.html]`, 확장 버전 0.3.2) | commit bfa075d83c6b97cd48440b3829ab8d24a2319809 | brackets · highlights · indents · injections · outline · overrides (`extensions/html/languages/html/`) | MIT |
| TOML (Zed 확장, 설치본과 같은 버전) | Cargo.lock toml Pipfile uv.lock | `toml` → https://github.com/tree-sitter/tree-sitter-toml (확장 https://github.com/zed-extensions/toml v1.1.0, 커밋 8e18e5045841f0f265f9c8b89f138c7f7dd09e2e의 `[grammars.toml]`) | rev 342d9be207c2dba869b9967124c679b5e6fd0ebe | brackets · highlights · indents · injections · outline · overrides · redactions · textobjects (확장 `languages/toml/`) | MIT (확장은 Apache-2.0) |
| Git Attributes (git-firefly 확장, 설치본과 같은 버전) | gitattributes .gitattributes | `gitattributes` → https://github.com/tree-sitter-grammars/tree-sitter-gitattributes (확장 https://github.com/d1y/git_firefly v0.1.9, 커밋 c63c6c0287ab5c8eb3872cf2bc8803e21c7a9675) | rev 1b7af09d45b579f9f288453b95ad555f1f431645 | highlights · injections (확장 `languages/gitattributes/`) | MIT (확장은 Apache-2.0) |
| Git Config (git-firefly 확장, 설치본과 같은 버전) | config.worktree .gitconfig .gitmodules .lfsconfig | `git_config` → https://github.com/the-mikedavis/tree-sitter-git-config (확장 https://github.com/d1y/git_firefly v0.1.9, 커밋 c63c6c0287ab5c8eb3872cf2bc8803e21c7a9675) | rev 3a61756a81a86291a0f48e3eeeaa0692b9981aa9 | highlights · injections (확장 `languages/gitconfig/`) | MIT (확장은 Apache-2.0) |
| Git Ignore (git-firefly 확장, 설치본과 같은 버전) | .containerignore .cursorignore .dockerignore .eslintignore .fdignore .gitignore .gitignore_global .git-blame-ignore-revs .ignore .npmignore .prettierignore .rgignore .vscodeignore | `gitignore` → https://github.com/shunsambongi/tree-sitter-gitignore (확장 https://github.com/d1y/git_firefly v0.1.9, 커밋 c63c6c0287ab5c8eb3872cf2bc8803e21c7a9675) | rev f4685bf11ac466dd278449bcfe5fd014e94aa504 | highlights · injections (확장 `languages/gitignore/`) | MIT (확장은 Apache-2.0) |
| Git Rebase (git-firefly 확장, 설치본과 같은 버전) | git-rebase-todo | `git_rebase` → https://github.com/the-mikedavis/tree-sitter-git-rebase (확장 https://github.com/d1y/git_firefly v0.1.9, 커밋 c63c6c0287ab5c8eb3872cf2bc8803e21c7a9675) | rev 39bf3b7566c86ccffd70aaa5105c7c8b76788975 | highlights · injections (확장 `languages/gitrebase/`) | MIT (확장은 Apache-2.0) |

- TOML 행(core 결정 2026-11-07, K-54): Zed 4304dec에 내장이 아니고 Zed 확장 `zed-extensions/toml`이다. 설치본 버전 확인은 개발 때 한 번만 했다(2026-11-07, `%LOCALAPPDATA%\Zed\extensions\installed\toml` 1.1.0). 실행 중에는 읽지 않는다(core D-8). 설치본과 대조하면 언어 config와 쿼리 9개(config.toml + .scm 8개)가 바이트 단위로 같다. `extension.toml`만 원시 해시가 다르다: 설치본은 필드 순서·표현이 다르고 themes·languages·capabilities·`[lib]` 등이 더 있다. 원본에는 `language_servers.taplo`의 name·opt_in_languages가 있다. 문법 필드는 원본 `commit`, 설치본 `rev`이고 값은 같다. 앱은 이 확장의 LSP·lib를 쓰지 않고 문법·쿼리만 쓴다.
- git-firefly 행(core 결정 2026-11-07, tauri K-55): 확장 `d1y/git_firefly` v0.1.9(커밋 c63c6c0287ab5c8eb3872cf2bc8803e21c7a9675), 문법 git_config 3a61756a·git_rebase 39bf3b75·gitattributes 1b7af09d·gitignore f4685bf1(전체 커밋은 표). 확장 Apache-2.0, 문법 MIT. tauri 보고: 설치본과 언어 파일 12/12 같고 `extension.toml` 원시 해시만 다르다. `.git/config`는 확장 config에 `config` 이름이 없어 고르지 않는다(Zed config대로, core 확인 요청). 실행 중에는 읽지 않는다(core D-8). 언어 이름(`name`)·`path_suffixes`·쿼리 파일은 tauri SPEC 표에 행이 없어 이 레포 복사본 `resources/zed-languages/<id>/config.toml`과 `.scm` 파일 이름(확장 고정 커밋 c63c6c02, K-48)으로 채웠다(W-54). 첫 줄 패턴·숨김은 없다.
- gpui 문법 방식(K-48 보고 2절, K-43A-R1): 위 표의 crate·저장소 열은 tauri와 같게 두고, 이 레포가 문법을 넣는 방식만 따로 적는다. 나머지 행은 표의 crate를 그대로 쓴다.

  | 언어(id) | 문법 저장소·커밋 | ABI | gpui 방식 |
  |---|---|---|---|
  | HTML (`html`) | tree-sitter/tree-sitter-html bfa075d8 | 14 | vendor(C 소스, `vendor/tree-sitter-html/`, `build.rs`) — crate 0.20.2가 core 0.28과 맞지 않음(K-43A-R1) |
  | TOML (`toml`) | tree-sitter/tree-sitter-toml 342d9be2 | 13 | vendor(C 소스, `vendor/tree-sitter-toml/`, `build.rs`) — crate `tree-sitter-toml 0.5.1`이 `tree-sitter ~0.20`·`cc ~1.0` 의존 |
  | Git Config (`gitconfig`) | the-mikedavis/tree-sitter-git-config 3a61756a | 14 | vendor(C 소스, `vendor/tree-sitter-git-config/`, `build.rs`) — `~0.20` 의존 |
  | Git Ignore (`gitignore`) | shunsambongi/tree-sitter-gitignore f4685bf1 | 13 | vendor(C 소스, `vendor/tree-sitter-gitignore/`, `build.rs`) — `~0.20` 의존 |
  | Git Attributes (`gitattributes`) | tree-sitter-grammars/tree-sitter-gitattributes 1b7af09d | 14 | crate git rev(`Cargo.toml` rev 1b7af09d45b579f9f288453b95ad555f1f431645, lock 0.2.0) — `tree-sitter-language 0.1`만 의존 |
  | Git Rebase (`gitrebase`) | the-mikedavis/tree-sitter-git-rebase 39bf3b75 | 15 | crate git rev(`Cargo.toml` rev 39bf3b7566c86ccffd70aaa5105c7c8b76788975, lock 0.1.0) — `tree-sitter-language 0.1`만 의존 |

- `crates/languages/src/lib.rs`에서 위 23개 밖에 내장으로 등록되는 언어는 없다. 같은 커밋 레포 안 확장은 `extensions/html`·`glsl`·`proto`·`test-extension` 넷이고 내장이 아니다(ORDER-11이 명시한 HTML만 표에 넣었다). 그 밖에 core 결정(ORDER-11 [DECISION], 2026-11-07)으로 Zed 확장 TOML(v1.1.0)과 git-firefly 0.1.9의 4개 언어(gitattributes·gitconfig·gitignore·gitrebase)를 설치본과 같은 버전·고정 커밋으로 넣는다(위 표 끝 5행, W-53).
- 루트 Cargo.toml에 있지만 `native_grammars`에 없는 문법:
  - tree-sitter-html 0.23(959, lock 0.23.2): `crates/editor`(테스트 지원 기능·dev-dependencies)와 `crates/language` dev-dependencies에서 테스트에만 쓴다. 앱의 HTML 강조는 위 확장의 문법(commit bfa075d)을 쓴다.
  - tree-sitter-elixir 0.3(952, lock 0.3.4), tree-sitter-heex(958, rev 1dd45142fbb05562e35b2040c6129c9bca346592), tree-sitter-embedded-template 0.23.0(953, lock 0.23.2), tree-sitter-ruby 0.23(965, lock 0.23.1): `crates/language` dev-dependencies에서 테스트에만 쓴다. 목록 밖.
- 쿼리 열의 이름 가운데 색에 쓰는 것은 `highlights`(강조)·`injections`(주입)·`outline`(경로 줄 심볼)이다. 나머지(brackets·indents·overrides·textobjects 등)는 편집 기능용이다.

**하이라이트 이름 → 테마 syntax 토큰**

- Zed: 테마 `syntax` 키를 정렬된 맵(`BTreeMap`)에 넣고, 캡처 이름마다 "첫 마디(`.` 앞) 이상, 캡처 이름 이하" 범위를 뒤에서부터 보며 "캡처 이름이 그 키로 시작하고 남은 부분이 없거나 `.`으로 시작하는" 첫 키를 고른다(`crates/syntax_theme/src/syntax_theme.rs` 87~102 `highlight_id`). 점 경계 앞부분 가운데 가장 긴 키다. 예: `@keyword.control.import` → 테마에 `keyword.control`이 있으면 그것, 없으면 `keyword`, 둘 다 없으면 색 없음. 이 대응은 문법마다 캡처 이름 목록으로 한 번 만든다(`crates/language/src/language.rs` 1298~1301 `HighlightMap::from_ids`).
- Zed: 한 글자 위에 캡처가 여럿 겹치면 시작 위치 순서로 쌓고 맨 위(마지막에 쌓인) 캡처 하나의 색만 쓴다. 테마 키가 없는 캡처는 쌓지 않아 바깥 캡처 색이 남는다(`crates/language/src/buffer.rs` 5909~5922 쌓기, 5967~5972 맨 위 하나).

**주입(injection)**

- 언어 결정(`crates/language/src/syntax_map.rs` 1720~1746, `crates/language/src/available_languages.rs` 218~239 `find_by_name_or_extension`):
  - 쿼리에 `#set! injection.language "<이름>"`이 있으면 그 이름, 없으면 `@injection.language` 캡처 글자를 쓴다. 캡처 글자에 `.`이 있으면 마지막 `.` 뒤만 쓴다(예: "foo/bar/baz.rs" → "rs").
  - 그 문자열을 대소문자 구분 없이 언어 이름(`name`) 또는 `path_suffixes`의 한 항목과 맞춘다. 맞는 언어가 없으면 주입하지 않는다(그 범위는 바깥 언어 색 그대로).
  - `#set! injection.combined`은 같은 언어의 여러 조각을 한 문서처럼 묶어 파싱한다(1671~1686, 1755~1756).
- 마크다운(`crates/grammars/src/markdown/injections.scm`): 코드 블록 `info_string`의 `language` 글자 → 코드 내용. 예: 언어 글자 `rust`는 이름 "Rust"와 대소문자 무시로 맞고, `ts`는 TypeScript의 확장자 `ts`로 맞는다. `inline`·`pipe_table_cell` → markdown-inline, `html_block` → html, `minus_metadata`(`---` 머리말) → yaml, `plus_metadata`(`+++`) → toml(목록에 없어 주입 안 됨). markdown-inline(`markdown-inline/injections.scm`): `html_tag` → html(combined), `latex_block` → latex(목록에 없어 주입 안 됨).
- HTML(`extensions/html/languages/html/injections.scm`): `script_element` 안 `raw_text` → javascript, `style_element` 안 `raw_text` → css, `style="…"` 속성 값 → css, `on…="…"` 속성 값 → javascript, `comment` → comment(목록에 없어 주입 안 됨).
- injections.scm이 있는 그 밖의 언어와 주입 대상(목록 밖 이름은 주입 안 됨): bash·css·diff·env·gitcommit·gomod·gowork·jsonc → comment만. c → c·comment·doxygen. cpp → c++·comment·doxygen과 `@injection.language` 캡처. go → bash·comment·css·csv·html·javascript·json·lua·regex·sql·xml·yaml. javascript·typescript → comment·css·glsl·graphql·html·isograph·javascript·jsdoc·json·regex·sql·typescript·WGSL/WESL·yaml(typescript는 angular도). tsx → comment·css·graphql·html·isograph·javascript·jsdoc·json·regex·sql·typescript·yaml. python → comment·sql. rust → comment·regex·rstml·rust·sql. yaml → comment·javascript. injections.scm이 없는 것: json·jsdoc·regex·zed-keybind-context.

**I-12 코드 파일 심볼(outline)**

- 쿼리: 언어마다 `outline.scm`(위 표 쿼리 열에 outline이 있는 c·cpp·css·go·javascript·json·jsonc·markdown·python·rust·tsx·typescript·yaml·html). 캡처 `@item`(심볼 범위), `@name`(필수), `@context`, `@context.extra`, `@open`·`@close`, `@annotation`(`crates/language_core/src/grammar.rs` 514~541).
- 경로 줄로 가는 길: 커서(가장 새 선택의 head)가 바뀌면 `symbols_containing(cursor, 테마 syntax)`를 부른다(`crates/editor/src/editor.rs` 4021~4049). 기본 설정 `document_symbols: "off"`(`assets/settings/default.json` 1458)라 LSP가 아닌 tree-sitter outline 경로다. 경로 줄 글자는 파일 경로 하나 + 심볼 글자들이다(`editor.rs` 11682~11721 `breadcrumbs_inner`).
- 심볼 고르기(`crates/language/src/buffer.rs` 4782~4797, 4890~4986):
  - 범위 = 커서 - 1 ~ 커서 + 1. `@item` 노드가 이 범위와 닿는 outline 일치를 모두 모은다(주입된 언어의 outline도 포함).
  - (시작 오름차순, 끝 내림차순)으로 정렬하고, 앞 항목 끝 안에 들어가면 한 단계 깊게 깊이를 매긴다.
  - 앞에서부터 깊이가 바로 앞에 남긴 항목보다 클 때만 남긴다. 그래서 바깥에서 안쪽으로 이어지는 한 줄기만 남는다.
- 심볼 글자(`buffer.rs` 4988~5110 `next_outline_item`): `@name`과 `@context` 캡처(경로 줄은 `@context.extra`를 빼고 부름) 노드를 소스 순서대로 잇는다. 사이에 소스상 틈이 있으면 공백 하나를 넣는다. 여러 줄 노드는 첫 줄 끝에서 자른다. 색은 편집기와 같은 하이라이트(위 "하이라이트 이름 → 테마 syntax 토큰")를 그대로 붙인다. `@name`이 없으면 항목이 아니다. 예: `src\App.tsx › function App()`(`zed-bc-code.png`, R-12).

**gpui 구현 방침**

- gpui: tree-sitter crate를 Zed `Cargo.lock`과 같은 버전으로 고정한다(core D-18). 위 표의 버전/rev 열이 기준이다.
- gpui: TOML·git-firefly 문법은 tree-sitter 0.28 크레이트로 넣는다. 크레이트가 0.28과 맞지 않으면 HTML과 같은 방식(vendor C 소스 + `build.rs`, core 결정 안 A)으로 한다. 쿼리는 확장 저장소 고정 커밋(TOML `zed-extensions/toml` 8e18e5045841f0f265f9c8b89f138c7f7dd09e2e, git-firefly `d1y/git_firefly` c63c6c0287ab5c8eb3872cf2bc8803e21c7a9675)에서 `.gitignore` 복사본(`resources/zed-languages/`)으로 가져온다(`tools/fetch-zed-languages.ps1`)(core ORDER-11 [DECISION], W-53).
- gpui: Rust `regex`라 쿼리 정규식 변환이 필요 없다(아래 tauri "쿼리 정규식"의 4개도 그대로 컴파일된다고 tauri가 적었다).
- gpui: Zed 쿼리 복사본은 레포 안 `.gitignore` 폴더에 두고, 다시 채우는 스크립트를 커밋한다. 위치 `resources/zed-languages/`(`.gitignore`), 스크립트 `tools/fetch-zed-languages.ps1`(K-41 제안, leader W-49). 원본은 Zed `crates/grammars/src/<언어>/`(config.toml·highlights·injections·outline)와 HTML `extensions/html/languages/html/`·`extensions/html/extension.toml`.
- gpui: 실행 중 config.toml을 읽지 않는다. 언어 표(이름·확장자·파일 이름·`first_line_pattern`·문법·쿼리 폴더)는 코드의 정적 표로 두고, 위 "언어 목록" 표와 같게 한다(leader W-49).
- gpui: gpui-component의 `tree-sitter` feature는 켜지 않는다(그 feature의 core는 0.26.13이라 Zed 0.28.0과 다름). 앱이 Zed와 같은 core·문법으로 기존 `InputHighlighter` API에 연결한다(K-41).

**gpui 의존성(Zed Cargo.lock 그대로)**

K-41 보고 2절에서 옮겼다. 출처 Zed `4304dec732` `Cargo.lock` 18850–19074, `Cargo.toml` 944–968·1037–1042. registry crate는 `=정확버전`, git crate는 전체 rev로 고정한다. registry는 `registry+https://github.com/rust-lang/crates.io-index`이고 git 행에는 registry checksum이 없다. `tree-sitter-language`는 Zed처럼 `[patch.crates-io]`로 core와 같은 git rev로 맞춘다.

| crate | 정확 버전 | registry checksum 또는 git 전체 rev |
|---|---|---|
| tree-sitter(core) | 0.28.0 | git `803c6ebaac27d69e1808b45058482e868d073ceb` |
| tree-sitter-language | 0.1.8 | git `803c6ebaac27d69e1808b45058482e868d073ceb` |
| tree-sitter-bash | 0.25.1 | `9e5ec769279cc91b561d3df0d8a5deb26b0ad40d183127f409494d6d8fc53062` |
| tree-sitter-c | 0.24.1 | `1a3aad8f0129083a59fe8596157552d2bb7148c492d44c21558d68ca1c722707` |
| tree-sitter-cpp | 0.23.4 | git `5cb9b693cfd7bfacab1d9ff4acac1a4150700609` |
| tree-sitter-css | 0.23.2 | `5ad6489794d41350d12a7fbe520e5199f688618f43aace5443980d1ddcf1b29e` |
| tree-sitter-diff | 0.1.0 | `dfe1e5ca280a65dfe5ba4205c1bcc84edf486464fed315db53dee6da9a335889` |
| tree-sitter-gitcommit | 0.0.1 | git `88309716a69dd13ab83443721ba6e0b491d37ee9` |
| tree-sitter-go | 0.25.0 | git `6862a49e3c5a7567a6c576420e9a8f944e198a85` |
| tree-sitter-gomod | 1.1.1 | git `2e886870578eeba1927a2dc4bd2e2b3f598c5f9a` |
| tree-sitter-gowork | 0.0.1 | git `acb0617bf7f4fda02c6217676cc64acb89536dc7` |
| tree-sitter-jsdoc | 0.23.2 | `a3862dfcb1038fc5e7812d7df14190afdeb7e1415288fd5f51f58395f8cb0faf` |
| tree-sitter-json | 0.24.8 | `4d727acca406c0020cffc6cf35516764f36c8e3dc4408e5ebe2cb35a947ec471` |
| tree-sitter-md | 0.3.2 | git `b596e737286780d7bfa9fcddceaeeb754574b352` |
| tree-sitter-python | 0.25.0 | `6bf85fd39652e740bf60f46f4cda9492c3a9ad75880575bf14960f775cb74a1c` |
| tree-sitter-regex | 0.24.3 | `712656f8c262a5a4b7d6026e6246950787d178d613864952554e1516a33ab0c1` |
| tree-sitter-rust | 0.24.2 | `439e577dbe07423ec2582ac62c7531120dbfccfa6e5f92406f93dd271a120e45` |
| tree-sitter-typescript | 0.23.2 | git `e2c53597d6a5d9cf7bbe8dccde576fe1e46c5899` |
| tree-sitter-yaml | 0.6.1 | git `baff0b51c64ef6a1fb1f8390f3ad6015b83ec13a` |

| crate | repository |
|---|---|
| core / language | https://github.com/tree-sitter/tree-sitter |
| cpp | https://github.com/tree-sitter/tree-sitter-cpp |
| gitcommit | https://github.com/zed-industries/tree-sitter-git-commit |
| go | https://github.com/zed-industries/tree-sitter-go |
| gomod | https://github.com/camdencheek/tree-sitter-go-mod |
| gowork | https://github.com/zed-industries/tree-sitter-go-work |
| md | https://github.com/zed-industries/tree-sitter-markdown |
| typescript | https://github.com/zed-industries/tree-sitter-typescript |
| yaml | https://github.com/zed-industries/tree-sitter-yaml |

- HTML: 앱은 확장 문법 https://github.com/tree-sitter/tree-sitter-html rev `bfa075d83c6b97cd48440b3829ab8d24a2319809`(확장 버전 0.3.2)를 쓴다. Zed lock의 tree-sitter-html 0.23.2(checksum `261b708e5d92061ede329babaaa427b819329a9d427a1d710abb0f67bbef63ee`)는 Zed 테스트 의존성이라 쓰지 않는다. 그 rev의 Rust binding 버전·빌드 경로: 미정(K-41 미확인, 다음 의존성 카드).
- 문법 crate가 아닌 추가 후보 `streaming-iterator =0.1.9`, `toml =1.1.8`(dev → runtime)은 D-18 허락 범위인지 core 확인 필요(K-41). 위 정적 언어 표 방침이면 `toml` runtime 이동은 필요 없다.

**tauri 구현(참고)**

- tauri 지금(`src/syntax/grammar.ts` `themeKey`): 캡처 이름 끝에서 `.` 마디를 하나씩 떼며 테마 키를 찾는다. 점 경계 가장 긴 앞부분이라 Zed 규칙과 같다.
- tauri 지금과 다른 점(코드는 고치지 않음):
  - 겹침: tauri(`src/syntax/highlight.ts` `build`)는 일치하는 캡처마다 CM6 mark를 겹쳐 넣어 CSS 클래스가 함께 붙는다. 같은 범위의 두 캡처에서 보이는 색이 Zed의 "맨 위 캡처 하나"와 같은지는 보장되지 않는다. 확인 필요.
  - 주입: tauri는 한 문법의 highlights만 쓰고 주입 언어를 강조하지 않는다.
  - 문법 출처: tauri는 실행 중 설치된 Zed 확장 폴더에서 문법을 읽는다(`zlext` 스킴). ORDER-11(core D-8)대로 이 Phase에서 복사본으로 바꾼다.
- tauri 지금: 경로 + 마크다운 ATX 제목만(K-40, `src/editor/breadcrumbs.ts`). 코드 심볼은 이 Phase(D-14).

**빌드 출처 (사용자 허락 2026-11-07, core-leader 전달)**

- 문법 wasm은 tree-sitter CLI로 문법 저장소의 parser.c(와 scanner)를 그대로 빌드한다. 문법을 재생성하지 않는다(parser.c 그대로). crate 문법은 Zed `Cargo.lock`의 버전·checksum으로 검증하고, git 문법은 lock의 저장소·rev, HTML은 `extensions/html/extension.toml`의 commit을 쓴다. 공유 문법을 합쳐 wasm 20개(언어 24개).
- 빌드 도구(K-47·K-49):

| 도구 | 버전 | URL | SHA256 |
| --- | --- | --- | --- |
| tree-sitter CLI Windows x64 (gzip) | 0.27.1 | https://github.com/tree-sitter/tree-sitter/releases/download/v0.27.1/tree-sitter-windows-x64.gz | e21184878f908f91c753b78a76a0766e61954e06627b46088d70d66233424531 (스크립트에 고정, 로컬 파일과 대조) |
| wasi-sdk (CLI가 자동으로 받음) | 34.0 | https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-34/wasi-sdk-34.0-x86_64-windows.tar.gz | cccb5c323a9b34f0349a9b09e8804a0a7632c68c3310f4b5f437ed57d7e71d8f (GitHub 자산 메타데이터 값, 로컬 압축 해시는 확인 안 함) |
| Binaryen (CLI가 자동으로 받음) | 132 | https://github.com/WebAssembly/binaryen/releases/download/version_132/binaryen-version_132-x86_64-windows.tar.gz | 2089428ec98c899b45ee5d00636ddd6e2da8636cc473ef50b165cc25793ef7cb (GitHub 자산 메타데이터 값, 로컬 압축 해시는 확인 안 함) |

- CLI와 자동 도구 캐시는 실행마다 고유한 `%TEMP%` 폴더(`workbench-zed-grammars-*`)에 두고 끝나면 그 폴더만 지운다. `LOCALAPPDATA`·`XDG_CACHE_HOME`·`XDG_CONFIG_HOME`은 자식 프로세스에서만 바꾼다.
- 복사본 위치 `src/assets/zed-grammars/`(`.gitignore`, wasm·쿼리·manifest·라이선스·빌드 로그). 다시 만들기 `tools/fetch-zed-grammars.ps1`(커밋 `bc95568`). 복사본이 없으면 강조 없이 평문(ORDER-11 2장).

**쿼리 정규식**

- Zed 쿼리 4개의 정규식을 web-tree-sitter(JavaScript RegExp)가 거부한다: `javascript/injections.scm`·`tsx/injections.scm`·`typescript/injections.scm` 5행 `(?s)`(dot-all), `python/injections.scm` 25행 `(?i:sql)`(범위 대소문자 무시). K-49에서 쿼리 58개 중 54개 컴파일, 이 4개 실패.
- 로더가 같은 뜻의 JavaScript 정규식으로 바꿔 컴파일한다. 복사본 원문은 바꾸지 않는다(K-50).
- gpui(Rust `regex`)는 이 문법을 받아들여 해당 없음.


**미리보기 코드 블록(C-41, core [NOTICE] 2026-11-07)**

- Zed 마크다운 미리보기도 코드 블록을 언어별로 강조한다(`zed-md-preview.png`, tauri ORDER-11 보고 9행). 색은 편집기와 같은 테마 `syntax`(`markdown_preview_view.rs` 1108~1114, `markdown.rs` 4224~4235)(C-41).
- 언어 찾기: 펜스 info string을 다듬어(`trim`) 비면 언어 없음, `/`가 있으면 경로, 그 밖은 언어 이름 → `language_for_name_or_extension`(대소문자 무시, 이름 또는 확장자), 실패하고 공백이 있으면 첫 단어로 다시 찾는다(`parser.rs` 425~439, `markdown.rs` 1334~1345). 편집기 주입 규칙과 같다(C-41).
- 언어가 없거나 모르는 언어, 들여쓰기 코드 블록은 강조 없이 `text` 색 평문이고 상자 모양은 같다(`markdown.rs` 1664~1673, 4246)(C-41).
- 상자: 배경 `editor_background`(`markdown.rs` 288), 안쪽 12·위아래 margin 16·반경 6(`markdown_preview.code_block.*`), 테두리 1px `border_variant`(`code_block.border`·`code_block.border_color`, `markdown.rs` 272~279). C-41 보고의 "테두리 없음"은 렌더러의 추가 테두리만 끄는 `border: false`를 본 것이라 맞지 않는다(W-51, `spec/ambiguous.md` 1절 L-109).
- 이 레포 지금(C-41): 미리보기 코드 블록에 강조 없음(`code_block_highlighter` 미연결), 배경 `theme.muted`(Zed는 `editor_background`), 글자 16(Zed `buffer_font_size` 15). 연결은 K-41 분할안 K-46.
---

## R-16. 탭이 탭 바보다 넘칠 때 Zed와 같게 처리한다

**요구**

탭이 탭 바 폭을 넘을 때 Zed와 같게 보이고 동작한다.

- 이 레포의 현재 상태: 비교 때(폴더 보기를 연 상태) 탭이 다 보였다. 실제로 넘칠 때는 확인하지 않았다.

**정해진 결과**

- 넘칠 때의 모습과 동작(스크롤, 잘림, 활성 탭 보이기)이 Zed와 같다.
- Zed의 실제 처리: 아래 "Zed 확인".

**판정 방법**

탭을 탭 바 폭보다 많이 열었을 때 보이는 모습과 동작(스크롤, 잘림, 활성 탭 보이기)이 Zed와 같다. V3.

**출처**

I-16. 요청 원문 "zed와 동일하게"(화면 비교의 "탭 바 넘침"에 대한 답, 사용자 2026-11-06).


**Zed 확인(tauri, 2026-11-07)**

조건: core ORDER-09, Zed `4304dec` 설치본 `zed -n` 새 창, 1440×852, 100%, One Dark, 사용자 `base_keymap` VSCode. 출처: workbench-tauri의 Zed 확인(tauri `specs/v0.5/SPEC.md` 해당 R-n "Zed 확인(2026-11-07)", 커밋 `bba6cfc`, W-41로 옮김, core-leader [NOTICE]). 캡처는 `D:\projects\workbench-tauri\specs\v0.5\verify\ORDER-09\` 아래(이하 `ORDER-09/`로 줄임). 근거 열은 이 레포 checker의 Zed 소스 확인(`cards/C-36.report.md`, Zed `4304dec` 파일:줄).

| 항목 | Zed | 캡처 | 근거(C-36) |
|---|---|---|---|
| 넘칠 때 탭 모양 | 탭은 원래 폭 그대로 한 줄, 좌우가 잘림. 스크롤 화살표·목록 버튼·스크롤바 없음 | `ORDER-09/zed-overflow.png` | `crates/workspace/src/pane.rs:3653-3665` `overflow_x_scroll()`, 페이드 없이 잘림 |
| 고정되는 것 | 뒤로/앞으로 버튼과 오른쪽 버튼 묶음은 고정, 탭 줄만 가로로 움직임 | `ORDER-09/zed-overflow.png`, `zed-wheel-*.png` | 같음 |
| 마우스 휠 | 세로 휠 한 칸에 가로 약 80px 이동 | `ORDER-09/zed-wheel-*.png` | 휠을 가로 스크롤로(`pane.rs:3653-3665`). 80px은 캡처 값 |
| 키보드로 탭 바꾸기 | `Ctrl-PageUp` 등으로 바꾸면 활성 탭이 보이게 스크롤 | `ORDER-09/zed-first-active.png` | `pane.rs:1523` `scroll_to_item`, 사용자가 직접 스크롤하면 억제(`suppress_scroll`) |
| 새 탭 위치 | 활성 탭 바로 오른쪽 | `ORDER-09/zed-overflow.png` 계열 | 없음(C-36 범위 밖) |

- C-36 추가: 핀 탭이 스크롤될 때 오른쪽 경계선이 보인다(`pane.rs:3720-3728`).

---

## R-17. `≡` 메뉴를 Zed와 같은 구성으로 하고, 구현된 기능만 넣는다

**요구**

타이틀 바 왼쪽 `≡` 메뉴와 메뉴 막대가 Zed의 메뉴 구성을 따르고, 구현된 기능의 항목만 넣으며, 두 갈래가 같다.

- 이 레포의 현재 상태: workbench-gpui(Quit) · File(Open Folder..., Close Editor, Close Window) · View · Window(Minimize, Zoom)다(`refs/compare/I-2-gpui.png`). 메뉴 막대를 열면 Window 뒤에 열린 폴더 이름 `workbench-gpui`가 한 번 더 보이고 Help가 없다. 메뉴는 `src/ui/app_menu.rs`에 있다. Save, Undo·Redo, 탭 이동 기능 자체가 있는지는 확인하지 않았다(없으면 `[BLOCKED]`, core D-3).

**정해진 결과**

- 메뉴 이름과 순서, 항목 순서가 Zed를 따른다. Zed의 메뉴 막대는 Zed·File·Edit·Selection·View·Go·Run·Window·Help 순서다(`zed/crates/zed/src/zed/app_menus.rs` main `4304dec732`).
- 구현되지 않은 Zed 항목은 넣지 않는다.
- tauri에만 있는 메뉴와 항목을 더한다: Edit의 Undo·Redo, Go의 Previous Tab·Next Tab, File의 Save, View의 `Open Markdown Preview`·`Open Markdown Preview to the Side`(사용자 2026-11-06).
- 마지막 메뉴는 Help다. Help에는 View Dependency Licenses(앱에 넣은 테마·아이콘·글꼴의 라이선스), (구분선) File Bug Report..., Request Feature...(workbench-gpui GitHub 저장소의 이슈 작성 페이지), (구분선) workbench-gpui Repository(저장소)를 넣는다. View Telemetry, Show Welcome, Email Us는 넣지 않는다.
- 메뉴 막대 뒤에 열린 폴더 이름이 한 번 더 보이지 않는다.
- 메뉴 이름 사이 간격이 Zed와 같다.

**판정 방법**

두 갈래의 `≡` 메뉴 막대와 항목이 서로 같다. 메뉴 순서는 Zed를 따르고, 마지막 메뉴는 Help다. 구현되지 않은 항목은 없다. 메뉴 막대 뒤에 폴더 이름이 한 번 더 보이지 않는다. 이름 사이 간격은 Zed와 같다. 각 항목을 누르면 그 기능이 동작한다. V3.

**출처**

I-17. 요청 원문 "zed와 동일하게", "햄버거 메뉴 동일하게 - zed를 기준으로 하고, 구현된 기능만 반영", "gpui의 메뉴를 tauri와 동일하게 추가", "메뉴의 마지막 항목에 help가 있어야 하고, 열린 폴더 이름이 마지막에 중복됩니다.", "Help 제안대로"(사용자 2026-11-06).

**메뉴 항목 표 (ORDER-06 1단계)**

coder 보고 `cards/K-09.report.md`의 메뉴 표와 `## K-10`에서 옮겼다. 메뉴 정의는 `src/ui/app_menu.rs`다. 단축키는 기본 키맵 기준이다. 실제 표시는 메뉴를 열기 전 포커스와 사용자 키맵에서 기존 조회 함수로 구하고, 그 컨텍스트에 없는 단축키는 표시하지 않는다.

| 메뉴 | 항목 | 기본 단축키 | 동작 |
|---|---|---|---|
| workbench-gpui | Quit workbench-gpui | `Ctrl-Q` | 기존 종료 action |
| File | Open Folder... | `Ctrl-K Ctrl-O` | 기존 폴더 열기 |
| File | (구분선) | | |
| File | Save | `Ctrl-S` | 기존 `workspace::Save` |
| File | (구분선) | | |
| File | Close Editor | `Ctrl-W`(`Ctrl-F4`도 동작) | 기존 활성 탭 닫기 |
| File | Close Window | `Ctrl-Shift-W` | 기존 창 닫기 |
| Edit | Undo | `Ctrl-Z` | 기존 `input::Undo`(앱 키맵에 Input 컨텍스트로 명시) |
| Edit | Redo | `Ctrl-Y`(`Ctrl-Shift-Z`도 동작) | 기존 `input::Redo` |
| View | Toggle Left Dock | `Ctrl-B` | 기존 dock 토글 |
| View | Toggle Folder Sidebar | `Ctrl-Alt-J` | 기존 sidebar 토글 |
| View | Focus Folder Sidebar | `Ctrl-Alt-;` | 기존 sidebar 포커스 |
| View | Editor Layout | 없음 | 하위 메뉴(K-11) |
| View → Editor Layout | Split Up | `Ctrl-K Up` | 기존 pane 분할 |
| View → Editor Layout | Split Down | `Ctrl-K Down` | 기존 pane 분할 |
| View → Editor Layout | Split Left | `Ctrl-K Left` | 기존 pane 분할 |
| View → Editor Layout | Split Right | `Ctrl-\`(`Ctrl-K Right`도 동작) | 기존 pane 분할 |
| View | Maximize Pane | `Shift-Escape` | 기존 pane 확대 토글 |
| View | (구분선) | | |
| View | Project Panel | `Ctrl-Shift-E` | 기존 패널 포커스 토글 |
| View | Open Markdown Preview | `Ctrl-Shift-V` | 기존 Markdown 미리보기 |
| View | Open Markdown Preview to the Side | `Ctrl-K V` | 기존 옆 pane 미리보기 |
| Go | Previous Tab | `Ctrl-PageUp` | 활성 pane의 이전 탭으로, 처음에서 끝으로 돈다(K-10) |
| Go | Next Tab | `Ctrl-PageDown` | 활성 pane의 다음 탭으로, 끝에서 처음으로 돈다(K-10) |
| Window | Minimize | 없음 | 기존 창 최소화 |
| Window | Zoom | 없음 | 기존 창 최대화/복원 |
| Help | View Dependency Licenses | 없음 | 포함한 라이선스 원문을 읽기 전용 창으로 표시 |
| Help | (구분선) | | |
| Help | File Bug Report... | 없음 | 브라우저로 `https://github.com/nampluskr/workbench-gpui/issues/new` |
| Help | Request Feature... | 없음 | 브라우저로 `https://github.com/nampluskr/workbench-gpui/issues/new` |
| Help | (구분선) | | |
| Help | workbench-gpui Repository | 없음 | 브라우저로 `https://github.com/nampluskr/workbench-gpui` |

- 메뉴 순서는 workbench-gpui·File·Edit·View·Go·Window·Help다. Selection·Run은 구현된 항목이 없어 메뉴째 뺐다.
- Go의 탭 순환은 core-leader 결정(2026-11-07)으로 새로 만들었다. action은 Zed와 같은 `pane::ActivatePreviousItem`·`pane::ActivateNextItem`, 단축키는 tauri와 같게 Pane 컨텍스트의 `Ctrl-PageUp`·`Ctrl-PageDown`이다. 탭이 0개·1개면 아무 일 없다. Zed 기본 키맵의 RunModal 컨텍스트 `Ctrl-Tab`·`Ctrl-Shift-Tab` 바인딩은 넣지 않았다(K-10).
- View의 Split Up/Down/Left/Right는 Zed처럼 View → `Editor Layout` 하위 메뉴로 옮긴다(core ORDER-06-R1 2.5, Zed `app_menus.rs:31~40`). K-11-R1에서 옮겼다.
- 메뉴 막대가 열려 있는 동안 타이틀 바의 폴더 이름을 그리지 않는다. 원인은 `title_bar::left_group`이 메뉴 열림과 상관없이 폴더 이름을 늘 더한 것이었다(K-09).
- 메뉴 이름 사이 막대 gap은 `menu["horizontal.item_gap"]`(I-321) 4px다. 07:54 V3에서 4.0px로 쟀다(`verify/reviews/measure-ORDER-06/`, C-22).
- Licenses 창: 앱에 들어간 자원의 라이선스 원문 여섯 개를 컴파일할 때 넣어 별도 읽기 전용 스크롤 창에 보인다 — IBM Plex Sans `license.txt`, Lilex `OFL.txt`, Zed 아이콘 `LICENSES`·`LICENSE-APACHE`·`LICENSE-GPL`, `vendor/gpui-base` `LICENSE-APACHE`(K-13에서 추가). `resources/`·`vendor/`를 ignored 파일까지 찾아 확인했다. 테마 라이선스는 Phase 7 대상이다(K-09, K-13).

**메뉴 키 기준 (core-leader 결정 2026-11-07, 두 갈래 공통, K-12)**

- 메뉴 항목의 키는 Zed Windows 기본 키맵 `assets/keymaps/default-windows.json`(커밋 `4304dec732a75505066de5ce2dbbfb2bec369498`, 레포 밖 sparse checkout에서 읽기만)을 따른다. 한 액션에 키가 여럿이면 메뉴에는 그 파일의 첫 키를 보인다. Close Editor는 `Ctrl-W`를 보인다.
- 표시 조회 함수는 고치지 않았다. 조회 함수가 마지막에 등록한 키를 보이므로 보일 키를 마지막에 등록한다. 사용자 바인딩·가려진 키 처리는 그대로다.

| 항목 | 전 | 후 |
|---|---|---|
| Undo | gpui-kit `Ctrl-Z` | 앱 키맵에 `Ctrl-Z` 명시, Input 컨텍스트 |
| Redo | gpui-kit `Ctrl-Y`만 | `Ctrl-Y` + `Ctrl-Shift-Z`, 표시 `Ctrl-Y`(원본 첫 키) |
| Close Editor | `Ctrl-W` + `Ctrl-F4`, 표시 `Ctrl-F4` | 두 키 유지, 표시 `Ctrl-W` |
| Split Right | `Ctrl-\` + `Ctrl-K Right`, 표시 `Ctrl-K Right` | 두 키 유지, 표시 `Ctrl-\`(원본 첫 키) |

- 원본과 같아 그대로 둔 것: Save `Ctrl-S`, Previous/Next Tab `Ctrl-PageUp`/`Ctrl-PageDown`, Open Folder `Ctrl-K Ctrl-O`, Quit `Ctrl-Q`, Close Window `Ctrl-Shift-W`, Toggle Left Dock `Ctrl-B`, Project Panel `Ctrl-Shift-E`, Toggle/Focus Folder Sidebar `Ctrl-Alt-J`/`Ctrl-Alt-;`, Markdown Preview `Ctrl-Shift-V`/`Ctrl-K V`, Maximize Pane `Shift-Escape`, Split Up/Down/Left `Ctrl-K Up`/`Down`/`Left`.
- Minimize·Zoom·Help 항목·Editor Layout은 원본에 대응 기본 키가 없어 키를 만들지 않았다.
- 확인: V1(K-12), `keymap::` 17·`app_menu::tests` 4 통과, 바인딩·컨텍스트·표시 순서 회귀 테스트. 메뉴 키 표시 화면은 V3 남음.

**메뉴 이름 간격 (K-12)**

이름 사이 간격 = 앞 이름 마지막 글자의 오른쪽 측면 여백 + 오른쪽 padding + 막대 gap + 왼쪽 padding + 뒤 이름 첫 글자의 왼쪽 측면 여백. Zed 잉크 간격은 13~14px이고 허용은 1px다(DECISIONS D-9).

- 막대 gap 4px(I-321)는 그대로 두고 이름 버튼 좌우 padding(`menu::NAME_*`)을 6 → 4px로 바꿨다(`src/ui/metrics.rs`).
- 계산: IBM Plex Sans Regular(번들 TTF), 12px, fontTools로 글리프 외곽 경계와 advance를 읽었다.

| 이름 경계 | 측면 여백 합(px) | 전 예상(px) | 후 예상(px) |
|---|---:|---:|---:|
| workbench-gpui / File | 2.028 | 18.028 | 14.028 |
| File / Edit | 1.680 | 17.680 | 13.680 |
| Edit / View | 0.768 | 16.768 | 12.768 |
| View / Go | 1.068 | 17.068 | 13.068 |
| Go / Window | 0.804 | 16.804 | 12.804 |
| Window / Help | 1.488 | 17.488 | 13.488 |

- 후 예상 12.768~14.028px로 13~14px에서 최대 0.232px 벗어난다(1px 이내). 글꼴 외곽 계산이라 래스터·힌팅·픽셀 반올림은 V3에서 판정한다.

---

## R-18. 상태 바 왼쪽 아이콘 모양을 Zed와 같게 한다

**요구**

상태 바 왼쪽 아이콘 묶음과 폴더 보기 패널 아래쪽에서, 왼쪽 dock 여닫기 버튼 아이콘이 Zed처럼 트리 모양이고 Add Project(폴더 추가) 버튼 아이콘에 Zed처럼 "+"가 붙어 있다.

- 이 레포의 현재 상태: 상태 바 왼쪽은 패널 토글, 폴더, 열린 폴더이고, 폴더 보기 아래쪽은 패널 토글과 폴더 아이콘이다(`refs/compare/base-gpui.png`, `X-folders-gpui.png`).

**정해진 결과**

- 왼쪽 dock 여닫기 버튼이 트리 모양 아이콘이다.
- Add Project 버튼에 "+"가 붙어 있다.
- 아이콘 출처는 R-1과 같다(core D-9).
- 상태 바 왼쪽 dock 여닫기 버튼: `file_tree.svg`(Zed `crates/project_panel/src/project_panel.rs:8281` FileTree). Add Project 버튼: `folder_add.svg`(Zed `crates/sidebar/src/sidebar.rs:6772` FolderAdd). R-1 대응 표와 같다(K-08).

**판정 방법**

왼쪽 dock 여닫기 버튼이 Zed와 같은 트리 모양 아이콘이다. Add Project 버튼에 "+"가 붙어 있다. 확대 캡처에서 Zed와 같다. V3.

**출처**

I-18, core D-9. 요청 원문 "close left dock 아이콘 모양 - 트리 모양 아이콘으로(zed와 같게), Add Project 아이콘에 '+' 추가"(사용자 2026-11-06).

---

## R-19. 사이드바·왼쪽 dock이 켜져 있으면 그 버튼을 진하게 보인다

**요구**

상태 바 왼쪽의 사이드바(폴더 보기)·왼쪽 dock 여닫기 버튼이, 그 패널이 열려 있으면 Zed처럼 켜짐 상태로 진하게 보이고, 닫히면 원래대로 돌아온다.

- 이 레포의 현재 상태: `status_bar(dock_open, sidebar_open, cx)`가 두 상태를 받는다(`src/ui/layout.rs`). 켜짐 표시가 Zed와 같은지는 확인하지 않았다.

**정해진 결과**

열려 있으면 Zed와 같은 켜짐 표시로 진해지고, 닫으면 원래대로 돌아온다.

**판정 방법**

사이드바와 왼쪽 dock을 열면 그 버튼이 Zed와 같은 켜짐 표시로 진해지고, 닫으면 원래대로 돌아온다. V3.

**출처**

I-19. 요청 원문 "side bar, left bar on 상태일 때 진하게 표시"(사용자 2026-11-06).


**Zed 확인(2026-11-07)**

조건: core ORDER-08 2장, Zed `4304dec` 설치본 `zed -n` 새 창, 1440×852, One Dark, 사용자 `base_keymap` VSCode. 출처: workbench-tauri의 Zed 확인(tauri `specs/v0.5/SPEC.md` R-5·R-19·R-22 "Zed 확인(2026-11-07)", W-34로 옮김, core ORDER-08 2장 "한 갈래가 먼저 확인했으면 읽어 써도 됨"). 캡처는 `D:\projects\workbench-tauri\specs\v0.5\verify\ORDER-08\` 아래(이하 `ORDER-08/`로 줄임).

- 왼쪽 dock(프로젝트 패널) 열림: 상태 바 `file_tree` 아이콘 색이 강조색(One Dark `#74ade8`, `text.accent` 계열)이 되고 배경은 바뀌지 않는다. 닫힘: 보통 아이콘 색이다(`ORDER-08/zed-cursor.png` 대 `ORDER-08/zed-project-click1.png`).
- 사이드바 열림: 상태 바의 사이드바 토글이 사라지고, 사이드바 아래쪽 줄에 `threads_sidebar_left_open` 아이콘(왼쪽 절반 채움)이 보인다(`ORDER-08/zed-dock-click1.png`).
- Zed 사이드바 아래쪽의 시계(스레드 기록)는 AI 기능이라 이 앱 범위 밖이다(core D-17).

---

## R-20. 파일 경로의 역슬래시를 원화 기호가 아닌 `\`로 보인다

**요구**

파일 트리와 경로를 보이는 다른 곳(R-11 탭 툴팁, R-12 경로 줄)에서 역슬래시가 workbench-tauri처럼 `\`로 보인다.

- 이 레포의 현재 상태: 파일 트리에서 `resources ₩ windows`로 보인다(`refs/compare/base-gpui.png`). 원인이 한글 글꼴이라는 것은 사용자 판단이고 코드로 확인하지 않았다. R-14 글꼴 변경으로 풀릴 수 있다(core PLAN Phase 4).

**정해진 결과**

역슬래시가 `\`로 보이고 `₩`로 보이지 않는다.

**판정 방법**

파일 트리, 탭 툴팁(I-11), 경로 줄(I-12)에서 역슬래시가 `\`로 보이고 `₩`로 보이지 않는다. V3.

**출처**

I-20. 요청 원문 "한글 글꼴 때문에 ₩로 보이는 것을 \로 보이게 해 주세요. tauri 화면이 맞습니다."(사용자 2026-11-06).

---

## R-21. 폴더 보기 패널의 모양을 Zed와 같게 한다

**요구**

상태 바 왼쪽 버튼으로 여는 폴더 보기 패널의 폭, 아이콘과 이름 사이 간격, 선택 표시가 Zed 사이드바와 같다.

- 이 레포의 현재 상태: 폭 약 207px, 검색칸이 없고 `projects`가 위에 있으며, 현재 폴더는 옅은 파란 배경이다(`refs/compare/X-folders-gpui.png`). Zed는 폭 약 220px다. 정정: 300(core 2026-11-07, Zed 소스 `threads_sidebar.default_width` 300, tauri 캡처 오른쪽 선 x 299).

**정해진 결과**

- 폭, 아이콘과 이름 사이 간격, 선택 표시가 Zed 사이드바와 같다.
- 검색칸은 두지 않는다.
- 패널이 보이는 내용과 순서는 지금처럼 이 레포의 폴더 관리 기준을 따른다. Zed 사이드바는 세션(에이전트 스레드) 관리이고 이 레포의 사이드바는 독립된 폴더 관리라서 모양만 맞춘다(사용자 2026-11-06).

**판정 방법**

폴더 보기 패널의 폭, 아이콘과 이름 사이 간격, 선택 표시가 Zed 사이드바와 같다. 검색칸이 없다. V3.

**출처**

I-21. 요청 원문 "나머지는 Zed와 동일하게"(사용자 2026-11-06).

**Zed 확인(tauri, 2026-11-07)**

조건: 데스크톱 1920×1080 100%, 클라이언트 1440×852, One Dark, Zed `zed -n` 새 창(폴더 workbench-tauri), Ctrl-Alt-J로 열고 닫음. 캡처 `D:\projects\workbench-tauri\specs\v0.5\verify\ORDER-10\`(Zed `zed-start.png`·`zed-sb-open.png`·`zed-sb-down.png`·`zed-sb-hover.png`, tauri `tauri-two-idle.png`·`tauri-two-hover.png`·`tauri-two-focused.png`·`tauri-v3-two.json`). tauri SPEC R-21(읽기만)과 tauri `specs/v0.5/reports/ORDER-10.md`에서 옮겼고 마지막 열에 이 레포 `spec/zed-metrics.toml` ID를 붙였다(섹션 없이 적은 `item.*`·`project_header.*`·`footer.*`는 `[sidebar]`). 줄 = Zed 프로젝트 묶음 머리(이 앱의 폴더 줄).

| 항목 | Zed 소스 근거 | Zed 실측 | tauri 실측 | 판정 | 우리 toml ID |
| --- | --- | --- | --- | --- | --- |
| 폭 | `default.json` 1195 `threads_sidebar.default_width` 300, 최소 200·최대 800(`agent_settings.rs` 37-38) | 300(오른쪽 선 x 299) | 300(선 x 299) | 같음. core가 앞서 본 약 220은 이번 조건에서 나오지 않음 | `sidebar.default_width` 300 (`min_width` 200·`max_width` 800) |
| 줄 높이 | `sidebar.rs` 2409 `Tab::content_height` = 32 - 1 | 31(y 33~63) | 31(y 33~63) | 같음 | `sidebar.project_header.height` 31 (`item_row.height` 31) |
| 안쪽 여백·테두리 | 2412-2416 `pl_2 pr_1p5 border_1 border_r_2` = 왼 8·오른 6, 테두리 1(오른쪽 2), 평소 투명 | 이름 잉크 x 9 | 아이콘 칸 x 9 | 같음 | `project_header.padding_left` 8·`padding_right` 6, `item.focus_border_width` 1·`item.border_right_width` 2 |
| 아이콘과 이름 | `thread_item.rs` 291·461 아이콘 칸 `size_4` = 16, 아이콘 Small 14, 간격 `gap_1p5` = 6(Zed 사이드바에서 이름 앞에 아이콘이 있는 줄. 묶음 머리 자체에는 앞 아이콘이 없다) | 묶음 머리에 아이콘 없음 | 아이콘 칸 x 9~25, 이름 x 31 | 소스 기준 같음 | `item.icon_slot_size` 16·`item.icon_size` 14·`item.icon_gap` 6 |
| 현재 폴더 표시 | 2377-2386 현재 묶음은 글자 기본색(text), 나머지 Muted, 배경 없음 | 글자 #dce0e5 계열, 배경 없음 | text rgb(220,224,229)·나머지 text.muted rgb(169,175,188), 배경 없음 | 같음 | 테마 토큰 `text`·`text.muted` |
| 키보드 선택 | 2246-2247·2417-2421 사이드바 포커스 + 선택 줄만 테두리 `panel_focused_border`. One Dark는 null이라 기본값(`default_colors.rs` 252 dark blue step 8) | #2870bd, 왼 1·오른 2 | #2870bd, 1/2 | 같음 | 토큰 `panel_focused_border` → toml `[theme.fallback]` `panel.focused_border` #2870bd, 폭 `item.focus_border_width` 1·`item.border_right_width` 2 |
| hover / 누름 | 2425-2426 `ghost_element_hover` / `ghost_element_active` | hover #363c46 | rgb(54,60,70) = #363c46 | 같음(누름은 소스만) | 토큰 `ghost_element_hover`·`ghost_element_active` |
| 줄 사이 선 | 2297-2299 둘째 묶음부터 위 1px `border` | 묶음 하나라 캡처 없음 | y 64 1px #474b57(border) | 소스 기준 같음 | `item.separator_width` 1, 토큰 `border` |
| 글자 크기 | Label 기본 크기 | 이름 잉크 폭 120(workbench-tauri) | 119 | 1px 이내 | 없음(Label 기본 크기) |
| 검색칸 | Zed는 위에 "Search threads…" 검색칸 | 있음 | 없음 | 사용자 결정(2026-11-06)대로 두지 않음 | 없음 |
| 아래쪽 줄 | 7529-7539 `p_1 gap_1 border_t_1(border)`, 왼쪽 토글, Thread History(시계), 빈칸, 오른쪽 끝 Add Project(`folder_add`) | 위 선 y 821, 토글 잉크 x 9~20, 시계 35~46, Add Project 278~290 | 위 선 y 821, 토글 svg x 8~22, Add Project svg 277~291 | 같음. 시계 버튼은 이 앱에 스레드 기록 기능이 없어 두지 않음(내용 불변 원칙) | `footer.padding` 4·`footer.gap` 4·`footer.border_top` 1(토큰 `border`)·`footer.icon_size` 14·`footer.height` 30 |
| "No threads yet" 줄 | 스레드 없는 묶음 아래 안내 줄 | 있음 | 없음 | 내용이라 두지 않음(I-21은 모양만) | 없음 |

- tauri `toml에 없는 값` 표의 다섯 값은 W-45에서 이 레포 toml에 올렸다: `sidebar.item.border_right_width` 2, `sidebar.item.separator_width` 1, `sidebar.item.icon_slot_size` 16, `sidebar.item.icon_gap` 6, `theme.fallback.panel.focused_border` #2870bd(옛 값 #62adef는 `spec/ambiguous.md` 3절).
- **두 갈래 다름, core 확인 필요**: `panel.focused_border` 라이트 기본값. tauri는 정하지 않고 라이트에서 `border.focused`를 쓴다. 이 레포 toml은 Zed 소스 라이트 기본 `#0588f0`(`default_colors.rs` 98행 blue light step 10)을 src에 적었다(W-45, 별도 ID 없음).
- 남은 차이(tauri 보고): 줄 사이 선은 Zed에서 묶음이 둘 이상일 때만 생겨 캡처로 확인하지 못했다(소스 기준). 누름(`ghost_element_active`) 색은 소스 기준, 실측 안 함.

**toml에 없는 값(gpui 등록 요청)** — 근거는 위 표.

| 임시 ID | 값 | Zed 근거 |
| --- | --- | --- |
| `sidebar.item.border_right_width` | 2 | `sidebar.rs` 2415-2416 `border_1` + `border_r_2` |
| `sidebar.item.separator_width` | 1 | `sidebar.rs` 2297-2299 `border_t_1` |
| `sidebar.item.icon_slot_size` | 16 | `thread_item.rs` 291 `size_4` |
| `sidebar.item.icon_gap` | 6 | `thread_item.rs` 461 `gap_1p5` |
| `panel.focused_border` 다크 기본값(테마에 값이 없을 때) | #2870bd | `default_colors.rs` 252 dark blue step 8, One Dark 실측 |

`panel.focused_border` 기본값(core 결정 2026-11-07, K-46): 테마에 값이 없으면 다크는 Zed `default_colors.rs` 252행 `blue().dark().step_8()` = #2870bd, 라이트는 98행 `blue().light().step_10()` = #0588f0. (앞서 라이트를 정하지 않고 `border.focused`를 쓰던 것을 바꾼다.)

**tauri 구현(tauri K-44, 참고)**

- 파일: `src/app.css`, `src/spec/metrics.ts`, `src/theme/theme.ts`·`apply.ts`·`theme.test.ts`. `src/shell/Sidebar.tsx`의 내용·순서·클릭·키·메뉴·추가·제거와 아래쪽 버튼, 폭 설정은 바꾸지 않았다.
- 현재 폴더는 `text`, 나머지는 `text.muted`. 현재 줄 선택 배경을 없애고 hover·누름 배경만 둔다. hover 때 다른 폴더 이름을 기본색으로 바꾸던 규칙도 없앴다.
- 줄 테두리는 왼·위·아래 1, 오른쪽 2이고 평소 투명하다. 사이드바에 포커스가 있고 cursor 줄일 때만 `panel.focused_border` 색이다. 이전 inset box-shadow(1px 윤곽선)는 없앴다.
- 둘째 줄부터 `border` 색 1px 구분선을 줄 테두리 바깥에 둔다(줄 사이 margin과 pseudo-element). 포커스 테두리와 구분선이 함께 보이고 줄 높이는 31 그대로다.
- 아이콘 14는 그대로 두고 16×16 칸 가운데에 놓는다. 칸과 이름 사이 6.
- 테마에 `panel.focused_border` 값이 있으면 그것을 쓴다(`parseColor`·`formatColor`로 검사). 다크에서 null·누락이면 #2870bd, 라이트는 CSS 변수를 내지 않아 `border.focused`가 남는다. 테마를 바꿀 때 sheet를 바꿔 끼워 다크 기본값이 라이트에 남지 않는다. 단위 테스트 1개(명시값 우선, 다크 기본값, 라이트 미설정, 잘못된 색 거부).
- 위 임시 ID 네 개는 `src/spec/metrics.ts`, 다크 기본값은 `src/theme/theme.ts`에 두고 gpui toml 등록 뒤 바꾼다. 기존 toml 값(줄 높이 31, padding 8/6, 아이콘 14, 테두리 1)은 그대로 쓴다.

---

## R-22. 상태 바 왼쪽 버튼 구성을 Zed와 같게 한다

**요구**

상태 바 왼쪽 버튼의 종류와 순서가 Zed와 같다. Zed에는 패널 토글, 프로젝트 패널, 검색, 진단(✓)이 있다.

- 이 레포의 현재 상태: 패널 토글, 폴더, 열린 폴더 버튼이 있고 검색·진단 버튼은 없다(`refs/compare/base-gpui.png`). 프로젝트 검색과 진단(언어 서버) 기능이 있는지는 확인하지 않았다.

**정해진 결과**

- 버튼의 종류와 순서가 Zed와 같고, 각 버튼이 Zed와 같은 패널이나 화면을 연다.
- 아이콘 모양은 R-18, 켜짐 표시는 R-19를 따른다.
- 이 요구는 루트 `INTENT.md` "다루지 않는 것"(프로젝트 전체 검색)과 "쓰지 않는 기능의 아이콘·메뉴·옵션은 넣지 않는다"보다 우선한다(core D-12). 루트 INTENT 해당 줄에 예외를 표시했다.
- 진단처럼 지금 기능이 없어 구현 범위가 큰 것도 빼지 않는다. 구현이 막히면 Phase 8 보고에 `[BLOCKED]`와 이유를 남긴다(core D-12, ORDER-01-R1 3장 5).

**판정 방법**

상태 바 왼쪽 버튼의 종류와 순서가 Zed와 같고, 각 버튼을 누르면 Zed와 같은 패널이나 화면이 열린다. V3.

**출처**

I-22. 요청 원문 "나머지는 Zed와 동일하게"(사용자 2026-11-06).


**Zed 확인(2026-11-07)**

조건: core ORDER-08 2장, Zed `4304dec` 설치본 `zed -n` 새 창, 1440×852, One Dark, 사용자 `base_keymap` VSCode. 출처: workbench-tauri의 Zed 확인(tauri `specs/v0.5/SPEC.md` R-5·R-19·R-22 "Zed 확인(2026-11-07)", W-34로 옮김, core ORDER-08 2장 "한 갈래가 먼저 확인했으면 읽어 써도 됨"). 캡처는 `D:\projects\workbench-tauri\specs\v0.5\verify\ORDER-08\` 아래(이하 `ORDER-08/`로 줄임). 툴팁의 키는 사용자 Zed 키맵 기준이다. 범위는 core D-17(언어 서버 없음, 진단은 문제 없음 화면, Project Search는 실제 검색, 이 앱에 없는 기능의 버튼은 넣지 않음)을 따른다.

*왼쪽 버튼* (`ORDER-08/zed-tip-*.png`, 버튼 중심 x 14·44·74·104)

| 순서 | 아이콘 | 툴팁 | 비고 |
|---|---|---|---|
| 1 | `threads_sidebar_left_closed` | "Open Threads Sidebar" `Ctrl-Alt-J` | 이 앱은 폴더 사이드바다. 사이드바가 열리면 상태 바에서 사라진다(R-19) |
| — | 세로 구분선 | | spec `statusbar.left_divider.*`(W-33): 폭 1, 높이 16(y 829~844), 색 border 토큰, x 28 |
| 2 | `file_tree` | dock 열림 "Close Left Dock" `Ctrl-B`, 닫힘 "Project Panel" | 켜짐 표시는 R-19 |
| — | 세로 구분선 | | 같은 spec ID, x 59 |
| 3 | 돋보기 | "Project Search" `Ctrl-Shift-F` | Project Search 탭을 연다 |
| 4 | 진단 ✓ | "Project Diagnostics" `Ctrl-Shift-M` | Diagnostics 탭을 연다 |

- 사이드바가 닫혀 있을 때 상태 바에 Add Project(`folder_add`) 버튼이 없다. `folder_add`는 사이드바가 열렸을 때 사이드바 아래쪽 줄 오른쪽 끝에만 있다(`ORDER-08/zed-dock-click1.png`).
- 구분선 근거: Zed `4304dec732` `crates/workspace/src/status_bar.rs` 283·287행 `Divider::vertical().color(DividerColor::Border)`(W-33).

*Project Search 탭* (`ORDER-08/zed-search-empty.png`, `zed-search-results.png`, `zed-search-filters.png`, `zed-search-replace-row.png`, `zed-search-end.png`, `zed-search-open.png`, `zed-tip-filter.png`, `zed-tip-replace.png`)

- 탭 제목: 돋보기 아이콘 + "Project Search"(빈 상태), 검색 뒤에는 검색어.
- 툴바 한 줄: 왼쪽 모두 접기/펴기 버튼, 검색칸(placeholder "Search all files…"), 칸 안 오른쪽 Aa(Match case `Alt-C`)·wd(Match whole words `Alt-W`)·.*(Match with regex `Alt-R`), 칸 밖 Toggle Filters(`Alt-F`)·Toggle Replace(`Alt-Shift-H`), 이전/다음 결과 화살표, `1/19`(현재/전체, 빈 상태 `0/0`).
- 빈 상태 가운데: "Search All Files" / "Start typing to search. For more options:" / 아이콘 + "Include/exclude specific paths `Alt-F`", "Find and replace `Alt-Shift-H`", "Match with regex `Alt-R`", "Match case `Alt-C`", "Match whole words `Alt-W`".
- Filters 줄: "Include: e.g. src/**/*.rs", "Exclude: e.g. vendor/*, *.lock" 두 칸 + "Only Search Open Files" 토글 + "Also search files ignored by configuration" 토글(기본 꺼짐 = `.gitignore`에 걸린 파일 제외).
- Replace 줄: "Replace in project…" 칸 + 다음 바꾸기·모두 바꾸기 아이콘 두 개(확인 때 누르지 않음).
- 결과: 파일마다 머리줄(접기 화살표, 파일 이름, 흐린 경로 또는 제목 경로 breadcrumb, 오른쪽 "Open File `Alt-Enter`"). 그 아래 일치 줄과 앞뒤 2줄 발췌(줄 번호, 위/아래로 더 펼치기 화살표), 일치 부분 강조. 결과 수는 툴바의 `현재/전체`.
- 동작: Enter로 검색한다. `Alt-Enter`나 Open File로 그 파일·위치를 일반 편집 탭으로 연다(`ORDER-08/zed-search-open.png`: AGENTS.md 미리보기 탭, `45:35`).
- 검색 대상(tauri 구현 `src-tauri/src/project_search.rs`, Zed `crates/project/src/project_search.rs` 166·167행 기준): `.gitignore`에 걸린 파일은 위 토글이 꺼져 있으면 뺀다. NUL 바이트가 있거나 디코딩되지 않는 파일(바이너리)은 뺀다. 한도는 파일 5,000개·일치 10,000개, 발췌 앞뒤 줄은 2다.
- 참고: 사용자 Zed는 VSCode 기본 키맵이라 편집 영역 포커스에서 `Alt-Shift-H`는 다른 명령(incoming calls)이 잡았다. 툴팁 표기는 `Alt-Shift-H`다.
- 구현 의존성: crate `ignore 0.4.34`·`regex 1.13.1`(DECISIONS D-12).

*Project Search 빈 화면 크기* (core DECISION 2026-11-07: Zed 소스 값으로, W-39)

- 소스 값(Zed `4304dec`, leader 확인, toml `[project_search]` `landing.*`):
  - 제목: `crates/search/src/project_search.rs:1089` `Label::new(heading_text).size(LabelSize::Large)` → `crates/ui/src/components/label/label_like.rs:242` `text_ui_lg` → `crates/ui/src/styles/typography.rs:138` `TextSize::Large = rems_from_px(16)` → 16(`project_search.landing.heading_size`).
  - 부제: `project_search.rs:2521-2527` `Label::new("Start typing to search. For more options:").color(Muted).mb_2()`, size 지정 없음 → `LabelSize::Default` → `TextSize::Default` 14(`landing.subtitle_size`), 아래 margin `mb_2` 8(`landing.subtitle_margin_bottom`).
  - 안내 줄: `project_search.rs:1032-1043` `Button::new(id, label).start_icon(Icon::new(icon).size(IconSize::Small)).key_binding(..)` → 라벨 `button.rs:517` `label_size.unwrap_or_default()` 14(`landing.action_label_size`), 키 `keybinding.rs:544-546` size 없음 → 14(`landing.key_size`).
  - 간격: 부제·안내 줄 묶음 `project_search.rs:2519` `v_flex().gap_1()` 4, 제목과 그 묶음 `:1111` `v_flex().gap_1()` 4(`landing.gap`).
  - rem 환산: `rems_from_px(n)`은 1rem = 16px 기준(typography.rs 주석), Zed 기본 ui_font_size 16.
- 캡처 측정(tauri `ORDER-08/zed-search-empty.png`, 1440×852 100%): 안내 줄 "Include/exclude specific paths" 잉크 폭 192, 키 "Alt-F" 30, 부제 709–960(251). gpui 같은 글꼴로 14px이면 219·34·287, 12px이면 164·26 → 캡처는 ≈13px에 해당한다. 제목 "Search All Files"는 16px에서 109로 Zed와 같다.
- 결론: 소스 값 14를 쓰고, 캡처도 14px와 맞는다(소스 14 = 캡처). leader V3 5차(17:12, `verify/reviews/measure-ORDER-08-run5/app-step8-search-empty.png`)에서 14로 되돌린 앱의 부제 잉크 폭 251 = Zed 251, 세로 잉크 y 377·407·441·466·493·519·545 = Zed와 같음, 블록 왼쪽(영역 중심 기준) −129 대 Zed −131이다.
- 위 "캡처는 ≈13px에 해당"은 측정 비교 오류였다. 4차 비교에 쓴 앱 폭 219는 K-28 상태의 다른 배치에서 잰 값이다(W-40). `spec/ambiguous.md` 6절 해소.

*Diagnostics 탭* (`ORDER-08/zed-diagnostics.png`)

- 탭 제목 "✓ No problems"(✓ 초록).
- 툴바 왼쪽 접기 버튼, 오른쪽 아이콘 4개(검색, 스파클, 새로고침, 경고 토글).
- 가운데 "No problems in workspace".
- 이 앱에는 언어 서버가 없어 진단 출처가 없으므로 이 "문제 없음" 화면만 보인다(core D-17).

---

## R-23. 탭 바 오른쪽 버튼(+, 분할, 최대화)이 보이는 방식을 Zed와 같게 한다

**요구**

탭 바 오른쪽 버튼 묶음(+, 분할, 최대화)이 언제 보이는지(늘 보이는지, 마우스를 올렸을 때만 보이는지)가 Zed와 같다.

- 이 레포의 현재 상태: 늘 보인다(`refs/compare/base-gpui.png`).

**정해진 결과**

- 버튼이 보이는 조건이 Zed와 같다.
- Zed의 실제 조건: 아래 "Zed 확인"(pane 포커스 기준). 비교 때 Zed는 미리보기 pane이 없어 같은 자리를 보지 못했다.

**판정 방법**

탭 바 오른쪽 버튼(+, 분할, 최대화)이 보이는 조건이 Zed와 같다. V3.

**출처**

I-23. 요청 원문 "나머지는 Zed와 동일하게"(사용자 2026-11-06).

**Zed 확인(tauri, 2026-11-07)**

조건: core ORDER-09, Zed `4304dec` 설치본 `zed -n` 새 창, 1440×852, 100%, One Dark, 사용자 `base_keymap` VSCode. 출처: workbench-tauri의 Zed 확인(tauri `specs/v0.5/SPEC.md` 해당 R-n "Zed 확인(2026-11-07)", 커밋 `bba6cfc`, W-41로 옮김, core-leader [NOTICE]). 캡처는 `D:\projects\workbench-tauri\specs\v0.5\verify\ORDER-09\` 아래(이하 `ORDER-09/`로 줄임). 근거 열은 이 레포 checker의 Zed 소스 확인(`cards/C-36.report.md`, Zed `4304dec` 파일:줄).

| 상황 | +, 분할, 최대화 버튼 | 캡처 |
|---|---|---|
| 그 pane에 포커스가 있음 | 보임 | `ORDER-09/zed-focus-panel*.png` |
| 프로젝트 패널에 포커스, 마우스를 탭 바에 올림 | 안 보임 | `ORDER-09/zed-cond-panel-hover-tabbar.png` |
| 프로젝트 패널에 포커스, 마우스를 편집 영역에 올림 | 안 보임 | `ORDER-09/zed-cond-panel-hover-editor.png` |
| 분할 | 포커스가 있는 pane에만 보임 | `ORDER-09/zed-split-right-click.png` |

- 마우스를 올리는 것만으로는 보이지 않는다. 기준은 pane 포커스다.
- 근거(C-36): 조건 `pane.has_focus(window, cx) || pane.context_menu_focused(window, cx)` — 그 pane에 포커스가 있거나 그 pane의 컨텍스트 메뉴가 열려 있을 때(`crates/workspace/src/pane.rs:4345-4352`, `pane.rs:3618`). 설정 `tab_bar.show_tab_bar_buttons`(기본 true, `assets/settings/default.json:1481`).
- 왼쪽 뒤로·앞으로 버튼은 포커스와 상관없이 늘 보인다(기록이 없으면 비활성, R-10).

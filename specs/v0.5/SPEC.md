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

| 행 | 키 | 컨트롤 | 기본값 | Zed 이름 | Zed 설명 |
|---|---|---|---|---|---|
| Theme | `theme` | 드롭다운 | 지금 테마(`Default Light` 하나, Phase 7에서 늘어남) | Theme Name | The name of your selected theme. |
| Icon Theme | `icon_theme` | 드롭다운 | `Zed (Default)` 하나 | Icon Theme Name | The name of your selected icon theme. |
| UI Font Size | `ui_font_size` | 숫자 | 16 | Font Size | Font size for UI elements. |
| Buffer Font Size | `buffer_font_size` | 숫자 | 15 | Font Size | Font size for editor text. |

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

- 이 레포의 현재 상태(K-13): 버튼 22×22, 오른쪽 여백 4. chevron은 SVG viewport 16에서 실제 path 폭이 8.89644(`11.8483−4.15186+1.2`)라 아이콘을 `8×16/8.89644 ≈ 14.388px`로 그려 잉크 폭 8을 목표로 한다. 실제 래스터 잉크 폭과 배치는 V3 남음.
| chevron 잉크 폭 | 8 | |
| 버튼 오른쪽 끝 ↔ 최소화 버튼 | 4 | |

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

실제 구성(K-14, `src/ui/keymap_editor.rs`):

| 자리 | 지금 구성 |
|---|---|
| 열기 | "v" 메뉴 Keymap·`Ctrl-K Ctrl-S` → 편집 영역 새 탭 "Keymap Editor". 다른 폴더 workspace까지 찾아 이미 열려 있으면 그 workspace·pane·탭을 활성화. 폴더가 없어도 설정 workspace에서 연다. 도구 탭이라 문서(Docs)로 등록하지 않아 저장·감시 대상이 아니고, 닫을 때 저장 확인이 없다. 탭 이동·복제에서 내용을 유지한다 |
| 위 줄 | 필터칸 "Filter action names…", `Edit in JSON  Ctrl-E`, `Create Keybinding  Ctrl-K` |
| 필터 | Action 이름에서 대소문자 구분 없이 찾는다 |
| 표 열 | Action, Arguments, Keystrokes, Context, Source |
| Action | 원래 액션 이름(예 `workspace::Save`) |
| Arguments | 비워 둔다(이 앱 액션은 인자가 없다) |
| Keystrokes | gpui 표기(예 `ctrl-k ctrl-s`). 바인딩 없는 액션은 빈 칸 |
| Context | 원문. 없으면 빈 칸 |
| Source | `Default`(gpui-kit·앱 기본) 또는 `User`(사용자 키맵) |
| 행 | 실행 중인 키맵의 gpui-kit·앱 기본·사용자 바인딩 전부 + 바인딩 없는 앱 액션. Action 이름순 |
| 편집 | 행을 누르거나 `Create Keybinding`을 누르면 표 아래에 Action·Keystrokes·Context 입력칸과 Save·Cancel이 나온다. 저장 전에 gpui 파서로 액션·키·컨텍스트를 검사하고, 오류는 화면에 보인다 |
| 저장 | 파일 전체를 다시 쓰지 않고 배열 끝에 override 섹션을 더한다. 키나 컨텍스트를 바꾸면 옛 키를 `null`로 푸는 섹션과 새 키 섹션을 더한다. 주석·키·내용·BOM·후행 쉼표를 보존하고 원자 교체로 쓴다. 파일이 깨져 있으면 저장을 거부한다. 저장 뒤 기존 load로 바로 적용한다. UI 기본 액션도 사용자 파일에서 쓸 수 있게 사용자 키맵 읽기가 등록 액션도 확인한다 |
| `Edit in JSON` | 사용자 keymap.json을 일반 편집기 탭으로 연다. 파일이 없으면 `[]`로 만든다 |

- Zed와 다른 점: 키 입력으로 찾기·필터 버튼이 없다(ORDER-06-R1 2.2 선택 사항). 편집은 Zed의 모달·키 녹화가 아니라 표 아래 입력칸에 gpui 표기(`ctrl-alt-k`)로 친다. 인자 편집이 없다. Action은 Zed의 읽기 쉬운 형식이 아니라 원래 이름이고, Arguments·Context의 빈 값 표시(Zed `<no arguments>`·`<global>`)가 없다. 반복 편집하면 override 섹션이 쌓인다(코드 `shortcut:` 주석). 후속 범위는 leader가 정한다(K-14 보고).
- 확인: V1(K-14). 화면(K-010~K-022 필터·버튼·표, 행 선택·편집 영역 배치)과 메뉴·`Ctrl-K Ctrl-S` 진입, `Ctrl-E`·`Ctrl-K` 동작은 V3·입력 검증 남음.

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
| 검색 | 이름·설명에서 대소문자 구분 없이. 작성자·버전은 찾지 않는다 |
| 자원 목록 | `RESOURCES` 한 곳. 지금은 `Default Light`(Themes, gpui-kit 기본 테마)와 `Zed (Default)`(Icon Themes, `resources/zed-icons`) 둘. 이름은 settings의 실제 테마·아이콘 테마 이름 |
| 카드 값 | 두 자원 모두 확장 manifest가 없어 버전·작성자·설명은 비워 둔다 |
| 상태 전환 | 모든 자원이 번들이라 `All`과 `Installed`의 내용이 같고 `Not Installed`는 빈 목록 |
| 치수 | `spec/zed-metrics.toml` extensions X-45~X-49를 `metrics.rs` 토큰으로 쓴다 |

- Phase 7: 복사한 테마·아이콘 테마와 원본 메타데이터를 `RESOURCES`에 더하면 화면과 필터에 함께 반영된다. 복사 경로가 아직 미정이라 디렉터리 자동 탐색은 넣지 않았다.
- 확인: V1(K-15). 화면(X-45~X-49 제목·검색·상태 전환·범주·카드)과 메뉴·`Ctrl-Shift-X` 진입, 기존 탭 활성화는 V3·입력 검증 남음.

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
- 복사 폴더 경로, 복사 방법, 복사본이 없을 때의 모습: 미정(Phase 7).

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
- 복사 폴더 경로, 복사 방법, 복사본이 없을 때의 모습: 미정(Phase 7).

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
- 열린 탭이 없을 때의 표시: Zed와 같게 한다. Zed의 실제 표시는 미정(Zed에서 확인, Phase 8).

**판정 방법**

마크다운 파일과 코드 파일을 편집 상태로 열고 커서를 옮기면 상태 바의 `{line}:{column}`이 그 위치로 바뀐다. 파일 형식 이름이 Zed와 같다. 미리보기에서 누른 곳에 해당하는 원본 위치가 같은 형식으로 보인다. 위치는 오른쪽 아이콘 묶음 바로 앞이다. 위치 계산은 V1 테스트, 화면은 V3.

**출처**

I-5. 요청 원문 "마크다운 문서 또는 소스코드 파일이 에디터 탭에서 편집 상태로 열리면, 상태바에 {line}:{column} {Filetype} 표시 필요 - zed에서 동작 방식임", 정한 것 "편집 상태가 아니라 미리보기일 때도 마우스 클릭으로 위치를 잡고 동일"(사용자 2026-11-06).

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

---

## R-12. 편집 영역 위에 파일 경로와 현재 제목 줄을 보인다

**요구**

탭 바 아래, 편집 영역 바로 위의 줄(지금은 오른쪽에 미리보기 버튼만 있는 줄) 왼쪽에 파일 경로와, 커서가 있는 곳의 제목 계층이 `›`로 이어져 보인다.

- 이 레포의 현재 상태: 이 줄에는 오른쪽 미리보기 버튼만 있다(`refs/I-7-gpui.png`).

**정해진 결과**

- 경로를 어디부터 보일지와 마크다운이 아닌 파일에서 무엇을 보일지 모두 Zed와 같다. 캡처로 본 Zed는 폴더를 하나만 열면 파일 이름부터(`INTENT.md › # INTENT — workbench-gpui › ## 무엇을 하는가`), 여럿 열면 폴더 이름부터(`workbench-gpui\INTENT.md › …`) 보인다.
- 분할된 창은 각자 자기 커서 위치의 제목 계층을 보인다(`refs/zed-split.png`).
- 코드 파일에서 Zed가 보이는 것(심볼 계층 등): 미정(Zed에서 확인, Phase 9).
- Zed 캡처의 같은 줄 오른쪽 버튼들은 요청에 들어 있지 않다.

**판정 방법**

같은 파일, 같은 커서 위치에서 경로 줄 글자가 Zed와 같다. 확인은 폴더 하나와 여럿, 마크다운 파일과 코드 파일 각 한 경우씩 한다. V3.

**출처**

I-12. 요청 원문 "문서의 편집창 상단에 파일 경로/제목이 보여야 함", 정한 것 "zed와 동일하게"(사용자 2026-11-06).

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
- 형식 목록: 미정(Zed에서 확인, Phase 11).
- 강조 색은 테마(R-4)에서 온다(core PLAN Phase 순서의 이유).

**판정 방법**

Zed가 지원하는 파일 형식마다 샘플 파일을 열면 구문 강조가 된다. 마크다운과 HTML 샘플은 같은 테마의 Zed 캡처와 색이 같다. 형식 목록과 샘플 결과는 갈래 보고에 표로 남긴다. V3, 색 품질은 V4.

**출처**

I-15. 요청 원문 "마크다운 문서의 하이라이트가 되지 않습니다. 하이라이트 기능 필요. html 포함 코드별 하이라이트 필요"(사용자 2026-11-06).

---

## R-16. 탭이 탭 바보다 넘칠 때 Zed와 같게 처리한다

**요구**

탭이 탭 바 폭을 넘을 때 Zed와 같게 보이고 동작한다.

- 이 레포의 현재 상태: 비교 때(폴더 보기를 연 상태) 탭이 다 보였다. 실제로 넘칠 때는 확인하지 않았다.

**정해진 결과**

- 넘칠 때의 모습과 동작(스크롤, 잘림, 활성 탭 보이기)이 Zed와 같다.
- Zed의 실제 처리: 미정(Zed에서 확인, Phase 9).

**판정 방법**

탭을 탭 바 폭보다 많이 열었을 때 보이는 모습과 동작(스크롤, 잘림, 활성 탭 보이기)이 Zed와 같다. V3.

**출처**

I-16. 요청 원문 "zed와 동일하게"(화면 비교의 "탭 바 넘침"에 대한 답, 사용자 2026-11-06).

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

- 이 레포의 현재 상태: 폭 약 207px, 검색칸이 없고 `projects`가 위에 있으며, 현재 폴더는 옅은 파란 배경이다(`refs/compare/X-folders-gpui.png`). Zed는 폭 약 220px다.

**정해진 결과**

- 폭, 아이콘과 이름 사이 간격, 선택 표시가 Zed 사이드바와 같다.
- 검색칸은 두지 않는다.
- 패널이 보이는 내용과 순서는 지금처럼 이 레포의 폴더 관리 기준을 따른다. Zed 사이드바는 세션(에이전트 스레드) 관리이고 이 레포의 사이드바는 독립된 폴더 관리라서 모양만 맞춘다(사용자 2026-11-06).

**판정 방법**

폴더 보기 패널의 폭, 아이콘과 이름 사이 간격, 선택 표시가 Zed 사이드바와 같다. 검색칸이 없다. V3.

**출처**

I-21. 요청 원문 "나머지는 Zed와 동일하게"(사용자 2026-11-06).

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

---

## R-23. 탭 바 오른쪽 버튼(+, 분할, 최대화)이 보이는 방식을 Zed와 같게 한다

**요구**

탭 바 오른쪽 버튼 묶음(+, 분할, 최대화)이 언제 보이는지(늘 보이는지, 마우스를 올렸을 때만 보이는지)가 Zed와 같다.

- 이 레포의 현재 상태: 늘 보인다(`refs/compare/base-gpui.png`).

**정해진 결과**

- 버튼이 보이는 조건이 Zed와 같다.
- Zed의 실제 조건: 미정(Zed에서 확인, Phase 9). 비교 때 Zed는 미리보기 pane이 없어 같은 자리를 보지 못했다.

**판정 방법**

탭 바 오른쪽 버튼(+, 분할, 최대화)이 보이는 조건이 Zed와 같다. V3.

**출처**

I-23. 요청 원문 "나머지는 Zed와 동일하게"(사용자 2026-11-06).

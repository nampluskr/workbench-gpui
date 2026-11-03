# P0-6 V3 기준 실측 — 2026-11-03

- 조건: DISPLAY1 1920×1080, DPI 96·100%, 최대화 client 1920×1032, 앱 기본 라이트 테마, rem=16. 기본 UI 글꼴 크기 설정을 바꾸지 않았다. 실제 font family/point size를 레이아웃 덤프로 식별할 수 없어 해당 항목은 판정하지 않는다.
- 허용 오차: toml verification.tolerance.dimension = ±1 논리 px. 색·아이콘 그림·시간과 카드 제외 영역은 측정하지 않았다. ratio·chars의 경계 조건을 만들려고 카드 밖 조작을 추가하지 않았다.
- 앱 프로세스 1회: session.json의 PID 24004. 시작 시 기존 앱 없음 확인, --dev-layout --dev-keymap --dev-pick-folder로 실행. 빌드 없음. SHA-256은 session.json에 보존했고 종료 후 exeUnchanged=true다.
- 상태: S1 빈 폴더·최대화; S2 80개 파일이 있는 target 시험 폴더 등록 및 branch/nested 선택·펼침; S3a 파일 한 번 클릭의 preview; S3 다른 파일 double click의 normal tab; S4 New… 탭 버튼 tooltip; S5 앱 메뉴; S6 파일 컨텍스트 메뉴; S7 F2 rename input, 이후 Esc 취소. 상태 전환용 입력만 수행했다.
- 원문 덤프와 캡처는 p0-measure/에 있다. 각 상태 JSON의 sourceStartLine/sourceEndLine은 app-stdout.txt의 원래 줄 번호다. 아래 근거는 해당 상태의 *-dump.txt 경계 이름이며 숫자는 도구로 계산했다. S1에서 이미 판정한 공통 경계는 다른 상태에서 중복 판정하지 않았다.

## 측정 결과

| 화면 상태 | 스펙 ID | 기대값 | 측정값 | 차이 | 판정 | 근거 |
|---|---|---:|---:|---:|---|---|
| S1 | `titlebar["height"]` | 32 px | 32 | 0 | PASS | S1-dump.txt seq=2 title-bar.h;  |
| S1 | `titlebar["padding_left"]` | 8 px | 8 | 0 | PASS | S1-dump.txt seq=2 app-menu.x - title-bar.x;  |
| S1 | `titlebar["left_group.gap"]` | 2 px | 2 | 0 | PASS | S1-dump.txt seq=2 title-folder-name.x - app-menu.right;  |
| S1 | `titlebar["window_button.width"]` | 36 px | 36 | 0 | PASS | S1-dump.txt seq=2 window-btn-close.w;  |
| S1 | `titlebar["window_button.height"]` | 32 px | 32 | 0 | PASS | S1-dump.txt seq=2 window-btn-close.h;  |
| S1 | `window["border_workspace_top"]` | 1 px | 1 | 0 | PASS | S1-dump.txt seq=2 body.y - work-area.y;  |
| S1 | `window["border_workspace_bottom"]` | 1 px | 1 | 0 | PASS | S1-dump.txt seq=2 status-bar.y - body.bottom;  |
| S1 | `window["border_sidebar_right"]` | 1 px | 1 | 0 | PASS | S1-dump.txt seq=2 sidebar.w - sidebar-header.w;  |
| S1 | `sidebar["default_width"]` | 300 px | 375 | 75 | FAIL | S1-dump.txt seq=2 sidebar.w; Q-15: empty state, before folder registration |
| S1 | `sidebar["header_height"]` | 32 px | 32 | 0 | PASS | S1-dump.txt seq=2 sidebar-header.h;  |
| S2 | `sidebar["project_header.height"]` | 31 px | 31 | 0 | PASS | S2-dump.txt seq=9 folder-row-00.h;  |
| S1 | `sidebar["footer.height"]` | 30 px | 31 | 1 | PASS | S1-dump.txt seq=2 sidebar-footer.h; Q-9: 31 vs 30; +1 is within tolerance |
| S1 | `sidebar["footer.padding"]` | 4 px | 4 | 0 | PASS | S1-dump.txt seq=2 sidebar-btn-toggle.x - sidebar-footer.x;  |
| S1 | `sidebar["footer.gap"]` | 4 px | 4 | 0 | PASS | S1-dump.txt seq=2 placeholder.x - toggle.right;  |
| S1 | `sidebar["footer.icon_size"]` | 14 px | 14 | 0 | PASS | S1-dump.txt seq=2 sidebar-icon-toggle.w;  |
| S1 | `dock["resize_handle_width"]` | 6 px | 6 | 0 | PASS | S1-dump.txt seq=2 dock-handle.w;  |
| S1 | `project_panel["default_width"]` | 240 px | 240 | 0 | PASS | S1-dump.txt seq=2 dock.w;  |
| S2 | `project_panel["item.height"]` | 26 px | 26 | 0 | PASS | S2-dump.txt seq=9 tree-row-01.h; comfortable 26 observed; standard is not switchable in this UI |
| S2 | `project_panel["item.gap"]` | 4 px | 4 | 0 | PASS | S2-dump.txt seq=9 tree-label-02.x - tree-icon-02.right;  |
| S2 | `project_panel["indent_step"]` | 20 px | 20 | 0 | PASS | S2-dump.txt seq=9 depth2 icon.x - depth1 icon.x;  |
| S2 | `project_panel["indent_guide.width"]` | 1 px | 1 | 0 | PASS | S2-dump.txt seq=9 tree-guide-02-1.w;  |
| S2 | `project_panel["indent_guide.offset_x"]` | 15 px | 15 | 0 | PASS | S2-dump.txt seq=9 tree-guide-01-0.x - tree-row-01.x;  |
| S2 | `project_panel["indent_guide.padding_y"]` | 4 px | 4 | 0 | PASS | S2-dump.txt seq=9 tree-guide-01-0.y - tree-row-01.y;  |
| S2 | `icons["size.medium"]` | 16 px | 16 | 0 | 기록만 | S2-dump.txt seq=9 tree-icon-02.w; Q-11/L-40: panel icon box 16 only recorded |
| S3 | `tab["bar_height"]` | 32 px | 32 | 0 | PASS | S3-dump.txt seq=14 tab-bar.h;  |
| S3 | `tab["content_height"]` | 31 px | 32 | 1 | 기록만 | S3-dump.txt seq=14 tab-00.h minus bottom blank/border; combined occupied box; tab-content probe absent for live tabs; outer box is 32 |
| S3 | `tab["end_buttons_area.gap"]` | 4 px | 4 | 0 | PASS | S3-dump.txt seq=14 tab-btn-split.x - tab-btn-new.right;  |
| S3 | `tab["end_buttons_area.padding_x"]` | 6 px | 6 | 0 | PASS | S3-dump.txt seq=14 tab-btn-new.x - tab-bar-end.x - left border(1); border measured as adjacent single-pixel gap |
| S3 | `tab["bar_icon_size"]` | 14 px | 14 | 0 | PASS | S3-dump.txt seq=14 tab-icon-new.w;  |
| S1 | `statusbar["height"]` | 30 px | 30 | 0 | PASS | S1-dump.txt seq=2 status-bar.h;  |
| S1 | `statusbar["padding_y"]` | 4 px | 4 | 0 | PASS | S1-dump.txt seq=2 status-btn-project-panel.y - status-bar.y;  |
| S1 | `statusbar["button_height"]` | 22 px | 22 | 0 | PASS | S1-dump.txt seq=2 status-btn-project-panel.h;  |
| S1 | `statusbar["group_gap"]` | 8 px | 8 | 0 | PASS | S1-dump.txt seq=2 status-right.x - status-left.right;  |
| S1 | `statusbar["item_gap"]` | 4 px | 4 | 0 | PASS | S1-dump.txt seq=2 status-left-placeholder.x - button.right;  |
| S1 | `statusbar["icon_size"]` | 14 px | 14 | 0 | PASS | S1-dump.txt seq=2 status-icon-project-panel.w;  |
| S1 | `buttons["height.default"]` | 22 px | 22 | 0 | PASS | S1-dump.txt seq=2 app-menu-button.h;  |
| S1 | `icons["size.small"]` | 14 px | 14 | 0 | PASS | S1-dump.txt seq=2 sidebar-icon-toggle.w;  |
| S4 | `tooltip.cursor_offset_x + tooltip.transparent_margin_left` | 9 px | 9 | 0 | PASS | S4-dump.txt seq=15 tooltip-box.x - logged mouse.x; app-stdout tooltip-shown; combined offset only; individual margins are not separately measured |
| S4 | `tooltip.cursor_offset_y + tooltip.transparent_margin_top` | 11 px | 11 | 0 | PASS | S4-dump.txt seq=15 tooltip-box.y - logged mouse.y; app-stdout tooltip-shown; combined offset only; individual margins are not separately measured |
| S4 | `tooltip outer box (L-211~L-215)` | internal terms not separated px | 57 x 33 | — | 기록만 | S4-dump.txt seq=15 tooltip-box; S4.png; 57x33 recorded; no independent font/padding/radius verdict |
| S5 | `menu["min_width"]` | 200 px | 211 | 11 | 기록만 | S5-dump.txt seq=17 menu-box.w minus 2 borders; observed inner width; 200 is a minimum, not fixed width |
| S5 | `menu["min_outer_width"]` | 202 px | 213 | 11 | 기록만 | S5-dump.txt seq=17 menu-box.w; 213 >= 202; minimum threshold not reached with this label |
| S5 | `menu["popup_offset_x"]` | -5 px | -5 | 0 | PASS | S5-dump.txt seq=17 menu-box.x - app-menu.x;  |
| S5 | `menu["popup_offset_y"]` | 0 px | 0 | 0 | PASS | S5-dump.txt seq=17 menu-box.y - app-menu.bottom;  |
| S5 | `menu["list_padding_y"]` | 4 px | 4 | 0 | PASS | S5-dump.txt seq=17 menu-row-00.y - menu-box.y - border;  |
| S5 | `menu["item.margin_x"]` | 4 px | 4 | 0 | PASS | S5-dump.txt seq=17 menu-row-00.x - menu-box.x - border;  |
| S5 | `menu["item.line_height"]` | 22.652 px | 23 | 0.348 | PASS | S5-dump.txt seq=17 menu-row-00.h; rendered line box 23 vs source 22.652 |
| S5 | `menu["horizontal.item_gap"]` | 4 px | 4 | 0 | PASS | S5-dump.txt seq=17 menu-name-1.x - menu-name-0.right;  |
| S6 | `menu["separator.height"]` | 1 px | 1 | 0 | PASS | S6-dump.txt seq=19 ctx-menu-row-2.h;  |
| S6 | `menu["separator.margin_y"]` | 6 px | 6 | 0 | PASS | S6-dump.txt seq=19 separator.y - preceding row.bottom;  |
| S6 | `menu["item.line_height"]` | 22.652 px | 23 | 0.348 | 기록만 | S6-dump.txt seq=19 ctx-menu-row-0.h; Q-11/I-508: current context row height 23; no estimated-height verdict |
| S7 | `inline_input["height"]` | 24 px | 24 | 0 | PASS | S7-dump.txt seq=21 tree-label-04.h (rename input container);  |
| S7 | `inline_input["border_right"]` | 2 px | 2 | 0 | PASS | S7-dump.txt seq=21 S7.png y=150 x=612..613; S7-pixel-runs.json; pixel scan, not a source-code value |
| S7 | `inline_input["border_top_bottom_left"]` | 1 px | 1 | 0 | PASS | S7-dump.txt seq=21 S7.png: top y=137, interior y=138, bottom y=162; left x=375; pixel runs and row boundaries; guide interrupts x=390 |

## 적용되지 않거나 별도 경계를 얻지 못한 항목

다음은 PASS로 간주하지 않는다. 카드의 제외 영역을 넓히거나 구현 코드를 실제 측정값 대신 사용하지 않았다. 이 목록은 허용된 섹션의 나머지 px·ratio·chars 항목별 측정 한계를 남긴다.

| 스펙 ID | 기대값 / 조건 | 측정값 | 판정 | 사유 |
|---|---|---|---|---|
| `typography["ui_font_size"]` | 16 px / default | 미측정 | 기록만 | 텍스트 line box/잉크 높이는 font size가 아니다. font 설정값을 측정값으로 대체하지 않음. |
| `typography["buffer_font_size"]` | 15 px / default | 미측정 | 기록만 | 텍스트 line box/잉크 높이는 font size가 아니다. font 설정값을 측정값으로 대체하지 않음. |
| `typography["size.large"]` | 16 px / default | 미측정 | 기록만 | 텍스트 line box/잉크 높이는 font size가 아니다. font 설정값을 측정값으로 대체하지 않음. |
| `typography["size.default"]` | 14 px / default | 미측정 | 기록만 | 텍스트 line box/잉크 높이는 font size가 아니다. font 설정값을 측정값으로 대체하지 않음. |
| `typography["size.small"]` | 12 px / default | 미측정 | 기록만 | 텍스트 line box/잉크 높이는 font size가 아니다. font 설정값을 측정값으로 대체하지 않음. |
| `typography["size.xsmall"]` | 10 px / default | 미측정 | 기록만 | 텍스트 line box/잉크 높이는 font size가 아니다. font 설정값을 측정값으로 대체하지 않음. |
| `icons["size.indicator"]` | 10 px / default | 미측정 | 기록만 | 허용된 상자만 대상. 이 변형 상자 미노출 또는 viewbox/stroke/inner artwork 제외(Q-8). |
| `icons["size.xsmall"]` | 12 px / default | 미측정 | 기록만 | 허용된 상자만 대상. 이 변형 상자 미노출 또는 viewbox/stroke/inner artwork 제외(Q-8). |
| `icons["size.xlarge"]` | 48 px / default | 미측정 | 기록만 | 허용된 상자만 대상. 이 변형 상자 미노출 또는 viewbox/stroke/inner artwork 제외(Q-8). |
| `icons["viewbox"]` | 16 px / default | 미측정 | 기록만 | 허용된 상자만 대상. 이 변형 상자 미노출 또는 viewbox/stroke/inner artwork 제외(Q-8). |
| `icons["stroke_width"]` | 1.2 px / default | 미측정 | 기록만 | 허용된 상자만 대상. 이 변형 상자 미노출 또는 viewbox/stroke/inner artwork 제외(Q-8). |
| `icons["inner_box"]` | 12 px / default | 미측정 | 기록만 | 허용된 상자만 대상. 이 변형 상자 미노출 또는 viewbox/stroke/inner artwork 제외(Q-8). |
| `buttons["height.large"]` | 32 px / default | 미측정 | 기록만 | 현재 S1~S7에서 이 크기 변형이 노출되지 않거나 내부 개별 경계 없음. |
| `buttons["height.medium"]` | 28 px / default | 미측정 | 기록만 | 현재 S1~S7에서 이 크기 변형이 노출되지 않거나 내부 개별 경계 없음. |
| `buttons["height.compact"]` | 18 px / default | 미측정 | 기록만 | 현재 S1~S7에서 이 크기 변형이 노출되지 않거나 내부 개별 경계 없음. |
| `buttons["height.none"]` | 16 px / default | 미측정 | 기록만 | 현재 S1~S7에서 이 크기 변형이 노출되지 않거나 내부 개별 경계 없음. |
| `buttons["padding_x.large_medium"]` | 8 px / default | 미측정 | 기록만 | 현재 S1~S7에서 이 크기 변형이 노출되지 않거나 내부 개별 경계 없음. |
| `buttons["padding_x.default_compact"]` | 4 px / default | 미측정 | 기록만 | 현재 S1~S7에서 이 크기 변형이 노출되지 않거나 내부 개별 경계 없음. |
| `buttons["gap"]` | 4 px / default | 미측정 | 기록만 | 현재 S1~S7에서 이 크기 변형이 노출되지 않거나 내부 개별 경계 없음. |
| `spacing["base00"]` | 0 px / default | 미측정 | 기록만 | Base 토큰은 렌더 요소가 아니다. 위 관측 gap을 각 화면 ID로 기록했으며 다른 Base 변형을 만들지 않음. |
| `spacing["base01"]` | 1 px / default | 미측정 | 기록만 | Base 토큰은 렌더 요소가 아니다. 위 관측 gap을 각 화면 ID로 기록했으며 다른 Base 변형을 만들지 않음. |
| `spacing["base02"]` | 2 px / default | 미측정 | 기록만 | Base 토큰은 렌더 요소가 아니다. 위 관측 gap을 각 화면 ID로 기록했으며 다른 Base 변형을 만들지 않음. |
| `spacing["base03"]` | 3 px / default | 미측정 | 기록만 | Base 토큰은 렌더 요소가 아니다. 위 관측 gap을 각 화면 ID로 기록했으며 다른 Base 변형을 만들지 않음. |
| `spacing["base04"]` | 4 px / default | 미측정 | 기록만 | Base 토큰은 렌더 요소가 아니다. 위 관측 gap을 각 화면 ID로 기록했으며 다른 Base 변형을 만들지 않음. |
| `spacing["base06"]` | 6 px / default | 미측정 | 기록만 | Base 토큰은 렌더 요소가 아니다. 위 관측 gap을 각 화면 ID로 기록했으며 다른 Base 변형을 만들지 않음. |
| `spacing["base08"]` | 8 px / default | 미측정 | 기록만 | Base 토큰은 렌더 요소가 아니다. 위 관측 gap을 각 화면 ID로 기록했으며 다른 Base 변형을 만들지 않음. |
| `spacing["base12"]` | 12 px / default | 미측정 | 기록만 | Base 토큰은 렌더 요소가 아니다. 위 관측 gap을 각 화면 ID로 기록했으며 다른 Base 변형을 만들지 않음. |
| `spacing["base16"]` | 16 px / default | 미측정 | 기록만 | Base 토큰은 렌더 요소가 아니다. 위 관측 gap을 각 화면 ID로 기록했으며 다른 Base 변형을 만들지 않음. |
| `spacing["base20"]` | 20 px / default | 미측정 | 기록만 | Base 토큰은 렌더 요소가 아니다. 위 관측 gap을 각 화면 ID로 기록했으며 다른 Base 변형을 만들지 않음. |
| `spacing["base24"]` | 24 px / default | 미측정 | 기록만 | Base 토큰은 렌더 요소가 아니다. 위 관측 gap을 각 화면 ID로 기록했으며 다른 Base 변형을 만들지 않음. |
| `spacing["base32"]` | 32 px / default | 미측정 | 기록만 | Base 토큰은 렌더 요소가 아니다. 위 관측 gap을 각 화면 ID로 기록했으며 다른 Base 변형을 만들지 않음. |
| `spacing["base40"]` | 40 px / default | 미측정 | 기록만 | Base 토큰은 렌더 요소가 아니다. 위 관측 gap을 각 화면 ID로 기록했으며 다른 Base 변형을 만들지 않음. |
| `spacing["base48"]` | 48 px / default | 미측정 | 기록만 | Base 토큰은 렌더 요소가 아니다. 위 관측 gap을 각 화면 ID로 기록했으며 다른 Base 변형을 만들지 않음. |
| `borders["radius.sm"]` | 4 px / default | 미측정 | 기록만 | 현재 probe는 바깥 직사각형. 모서리 radius를 직사각형 bounds에서 역산하지 않음. |
| `borders["radius.lg"]` | 8 px / default | 미측정 | 기록만 | 현재 probe는 바깥 직사각형. 모서리 radius를 직사각형 bounds에서 역산하지 않음. |
| `window["unmaximized.corner_radius"]` | 10 px / window_unmaximized | 미측정 | 기록만 | S1은 최대화. 비최대화 모서리·그림자 조건은 미적용. 일부 1px 경계는 중첩 테두리 때문에 독립 probe 없음. |
| `window["unmaximized.border_width"]` | 1 px / window_unmaximized | 미측정 | 기록만 | S1은 최대화. 비최대화 모서리·그림자 조건은 미적용. 일부 1px 경계는 중첩 테두리 때문에 독립 probe 없음. |
| `window["unmaximized.shadow_size"]` | 10 px / window_unmaximized | 미측정 | 기록만 | S1은 최대화. 비최대화 모서리·그림자 조건은 미적용. 일부 1px 경계는 중첩 테두리 때문에 독립 probe 없음. |
| `window["border_sidebar_header_bottom"]` | 1 px / default | 미측정 | 기록만 | S1은 최대화. 비최대화 모서리·그림자 조건은 미적용. 일부 1px 경계는 중첩 테두리 때문에 독립 probe 없음. |
| `window["border_dock_left"]` | 1 px / default | 미측정 | 기록만 | S1은 최대화. 비최대화 모서리·그림자 조건은 미적용. 일부 1px 경계는 중첩 테두리 때문에 독립 probe 없음. |
| `titlebar["project_name.max_chars"]` | 40 chars / default | 미측정 | 기록만 | S1/S2에 없는 user-menu 또는 글리프/문자수 한계. 글리프 상자는 font point size와 같지 않아 추정 판정하지 않음. |
| `titlebar["window_button.glyph_size"]` | 10 px / default | 미측정 | 기록만 | S1/S2에 없는 user-menu 또는 글리프/문자수 한계. 글리프 상자는 font point size와 같지 않아 추정 판정하지 않음. |
| `titlebar["right_group.padding_right"]` | 4 px / default | 미측정 | 기록만 | S1/S2에 없는 user-menu 또는 글리프/문자수 한계. 글리프 상자는 font point size와 같지 않아 추정 판정하지 않음. |
| `titlebar["right_group.gap"]` | 4 px / default | 미측정 | 기록만 | S1/S2에 없는 user-menu 또는 글리프/문자수 한계. 글리프 상자는 font point size와 같지 않아 추정 판정하지 않음. |
| `titlebar["user_menu.button_width"]` | 22 px / default | 미측정 | 기록만 | S1/S2에 없는 user-menu 또는 글리프/문자수 한계. 글리프 상자는 font point size와 같지 않아 추정 판정하지 않음. |
| `titlebar["user_menu.button_height"]` | 22 px / default | 미측정 | 기록만 | S1/S2에 없는 user-menu 또는 글리프/문자수 한계. 글리프 상자는 font point size와 같지 않아 추정 판정하지 않음. |
| `titlebar["user_menu.button_icon_size"]` | 14 px / default | 미측정 | 기록만 | S1/S2에 없는 user-menu 또는 글리프/문자수 한계. 글리프 상자는 font point size와 같지 않아 추정 판정하지 않음. |
| `titlebar["user_menu.button_corner_radius"]` | 4 px / default | 미측정 | 기록만 | S1/S2에 없는 user-menu 또는 글리프/문자수 한계. 글리프 상자는 font point size와 같지 않아 추정 판정하지 않음. |
| `titlebar["user_menu.popup_offset_x"]` | 5 px / default | 미측정 | 기록만 | S1/S2에 없는 user-menu 또는 글리프/문자수 한계. 글리프 상자는 font point size와 같지 않아 추정 판정하지 않음. |
| `titlebar["user_menu.popup_offset_y"]` | 0 px / default | 미측정 | 기록만 | S1/S2에 없는 user-menu 또는 글리프/문자수 한계. 글리프 상자는 font point size와 같지 않아 추정 판정하지 않음. |
| `titlebar["user_menu.popup_min_width"]` | 200 px / default | 미측정 | 기록만 | S1/S2에 없는 user-menu 또는 글리프/문자수 한계. 글리프 상자는 font point size와 같지 않아 추정 판정하지 않음. |
| `titlebar["user_menu.popup_min_outer_width"]` | 202 px / default | 미측정 | 기록만 | S1/S2에 없는 user-menu 또는 글리프/문자수 한계. 글리프 상자는 font point size와 같지 않아 추정 판정하지 않음. |
| `titlebar["user_menu.popup_max_height_ratio"]` | 0.75 ratio / default | 미측정 | 기록만 | S1/S2에 없는 user-menu 또는 글리프/문자수 한계. 글리프 상자는 font point size와 같지 않아 추정 판정하지 않음. |
| `sidebar["min_width"]` | 200 px / default | 미측정 | 기록만 | S1/S2에서 범위 끝값·오버플로·행 내부 개별 경계는 미노출. Q-12 핸들은 제외. |
| `sidebar["max_width"]` | 800 px / default | 미측정 | 기록만 | S1/S2에서 범위 끝값·오버플로·행 내부 개별 경계는 미노출. Q-12 핸들은 제외. |
| `sidebar["project_header.padding_left"]` | 8 px / default | 미측정 | 기록만 | S1/S2에서 범위 끝값·오버플로·행 내부 개별 경계는 미노출. Q-12 핸들은 제외. |
| `sidebar["project_header.padding_right"]` | 6 px / default | 미측정 | 기록만 | S1/S2에서 범위 끝값·오버플로·행 내부 개별 경계는 미노출. Q-12 핸들은 제외. |
| `sidebar["item_row.height"]` | 31 px / default | 미측정 | 기록만 | S1/S2에서 범위 끝값·오버플로·행 내부 개별 경계는 미노출. Q-12 핸들은 제외. |
| `sidebar["footer.border_top"]` | 1 px / default | 미측정 | 기록만 | S1/S2에서 범위 끝값·오버플로·행 내부 개별 경계는 미노출. Q-12 핸들은 제외. |
| `dock["min_width"]` | 6 px / default | 미측정 | 기록만 | 최소 폭은 이번 기본 폭 상태에서 미도달; 리사이즈 동작 검증을 추가하지 않음. |
| `project_panel["item.height.standard"]` | 24 px / project_panel_standard | 미측정 | 기록만 | standard 조건 전환 UI가 없거나 개별 border/segment 경계 probe 없음. 관측 행은 comfortable 외형 26px. |
| `project_panel["item.content_height"]` | 24 px / default | 미측정 | 기록만 | standard 조건 전환 UI가 없거나 개별 border/segment 경계 probe 없음. 관측 행은 comfortable 외형 26px. |
| `project_panel["item.border_width"]` | 1 px / default | 미측정 | 기록만 | standard 조건 전환 UI가 없거나 개별 border/segment 경계 probe 없음. 관측 행은 comfortable 외형 26px. |
| `project_panel["item.border_right_width"]` | 2 px / default | 미측정 | 기록만 | standard 조건 전환 UI가 없거나 개별 border/segment 경계 probe 없음. 관측 행은 comfortable 외형 26px. |
| `project_panel["item.padding_x"]` | 6 px / default | 미측정 | 기록만 | standard 조건 전환 UI가 없거나 개별 border/segment 경계 probe 없음. 관측 행은 comfortable 외형 26px. |
| `project_panel["collapsed_path.padding_x"]` | 2 px / default | 미측정 | 기록만 | standard 조건 전환 UI가 없거나 개별 border/segment 경계 probe 없음. 관측 행은 comfortable 외형 26px. |
| `tab["padding_x"]` | 4 px / default | 미측정 | 기록만 | 실제 탭에서 일부 slot/content probe가 없거나 overflow·제목 최대 길이 조건 미도달. |
| `tab["gap"]` | 4 px / default | 미측정 | 기록만 | 실제 탭에서 일부 slot/content probe가 없거나 overflow·제목 최대 길이 조건 미도달. |
| `tab["start_slot.width"]` | 12 px / default | 미측정 | 기록만 | 실제 탭에서 일부 slot/content probe가 없거나 overflow·제목 최대 길이 조건 미도달. |
| `tab["start_slot.height"]` | 12 px / default | 미측정 | 기록만 | 실제 탭에서 일부 slot/content probe가 없거나 overflow·제목 최대 길이 조건 미도달. |
| `tab["end_slot.width"]` | 14 px / default | 미측정 | 기록만 | 실제 탭에서 일부 slot/content probe가 없거나 overflow·제목 최대 길이 조건 미도달. |
| `tab["end_slot.height"]` | 14 px / default | 미측정 | 기록만 | 실제 탭에서 일부 slot/content probe가 없거나 overflow·제목 최대 길이 조건 미도달. |
| `tab["max_title_chars"]` | 24 chars / default | 미측정 | 기록만 | 실제 탭에서 일부 slot/content probe가 없거나 overflow·제목 최대 길이 조건 미도달. |
| `tab["end_buttons_area.border_bottom"]` | 1 px / default | 미측정 | 기록만 | 실제 탭에서 일부 slot/content probe가 없거나 overflow·제목 최대 길이 조건 미도달. |
| `tab["end_buttons_area.border_start_right"]` | 1 px / default | 미측정 | 기록만 | 실제 탭에서 일부 slot/content probe가 없거나 overflow·제목 최대 길이 조건 미도달. |
| `tab["end_buttons_area.border_end_left"]` | 1 px / default | 미측정 | 기록만 | 실제 탭에서 일부 slot/content probe가 없거나 overflow·제목 최대 길이 조건 미도달. |
| `tab["overflow.empty_drop_width"]` | 24 px / default | 미측정 | 기록만 | 실제 탭에서 일부 slot/content probe가 없거나 overflow·제목 최대 길이 조건 미도달. |
| `pane["split_line_thickness"]` | 1 px / default | 미측정 | 기록만 | 현재 단일 Pane. 분할선·drag/drop·zoom 조건은 S3에 없고 카드 밖 상태를 만들지 않음. |
| `pane["split_line_mouse_hitbox"]` | 4 px / default | 미측정 | 기록만 | 현재 단일 Pane. 분할선·drag/drop·zoom 조건은 S3에 없고 카드 밖 상태를 만들지 않음. |
| `pane["min_drag_width"]` | 80 px / default | 미측정 | 기록만 | 현재 단일 Pane. 분할선·drag/drop·zoom 조건은 S3에 없고 카드 밖 상태를 만들지 않음. |
| `pane["min_drag_height"]` | 100 px / default | 미측정 | 기록만 | 현재 단일 Pane. 분할선·drag/drop·zoom 조건은 S3에 없고 카드 밖 상태를 만들지 않음. |
| `pane["drop_target_size_ratio"]` | 0.2 ratio / default | 미측정 | 기록만 | 현재 단일 Pane. 분할선·drag/drop·zoom 조건은 S3에 없고 카드 밖 상태를 만들지 않음. |
| `pane["directional_drop_overlay_ratio"]` | 0.5 ratio / default | 미측정 | 기록만 | 현재 단일 Pane. 분할선·drag/drop·zoom 조건은 S3에 없고 카드 밖 상태를 만들지 않음. |
| `pane["tab_drop_line_width"]` | 2 px / default | 미측정 | 기록만 | 현재 단일 Pane. 분할선·drag/drop·zoom 조건은 S3에 없고 카드 밖 상태를 만들지 않음. |
| `pane["tab_bar_end_drop_min_width"]` | 24 px / default | 미측정 | 기록만 | 현재 단일 Pane. 분할선·drag/drop·zoom 조건은 S3에 없고 카드 밖 상태를 만들지 않음. |
| `pane["zoomed_padding"]` | 8 px / default | 미측정 | 기록만 | 현재 단일 Pane. 분할선·drag/drop·zoom 조건은 S3에 없고 카드 밖 상태를 만들지 않음. |
| `pane["zoomed_border"]` | 1 px / default | 미측정 | 기록만 | 현재 단일 Pane. 분할선·drag/drop·zoom 조건은 S3에 없고 카드 밖 상태를 만들지 않음. |
| `statusbar["cursor_position.font_size"]` | 12 px / default | 미측정 | 기록만 |  |
| `tooltip["cursor_offset_x"]` | 1 px / default | 미측정 | 기록만 | S4는 짧은 제목 단일줄 tooltip. 상자 probe만 있어 내부 padding·corner·font·shortcut 구간을 독립 식별할 수 없음. |
| `tooltip["cursor_offset_y"]` | 1 px / default | 미측정 | 기록만 | S4는 짧은 제목 단일줄 tooltip. 상자 probe만 있어 내부 padding·corner·font·shortcut 구간을 독립 식별할 수 없음. |
| `tooltip["transparent_margin_left"]` | 8 px / default | 미측정 | 기록만 | S4는 짧은 제목 단일줄 tooltip. 상자 probe만 있어 내부 padding·corner·font·shortcut 구간을 독립 식별할 수 없음. |
| `tooltip["transparent_margin_top"]` | 10 px / default | 미측정 | 기록만 | S4는 짧은 제목 단일줄 tooltip. 상자 probe만 있어 내부 padding·corner·font·shortcut 구간을 독립 식별할 수 없음. |
| `tooltip["corner_radius"]` | 8 px / default | 미측정 | 기록만 | S4는 짧은 제목 단일줄 tooltip. 상자 probe만 있어 내부 padding·corner·font·shortcut 구간을 독립 식별할 수 없음. |
| `tooltip["border_width"]` | 1 px / default | 미측정 | 기록만 | S4는 짧은 제목 단일줄 tooltip. 상자 probe만 있어 내부 padding·corner·font·shortcut 구간을 독립 식별할 수 없음. |
| `tooltip["padding_y"]` | 4 px / default | 미측정 | 기록만 | S4는 짧은 제목 단일줄 tooltip. 상자 probe만 있어 내부 padding·corner·font·shortcut 구간을 독립 식별할 수 없음. |
| `tooltip["padding_x"]` | 8 px / default | 미측정 | 기록만 | S4는 짧은 제목 단일줄 tooltip. 상자 probe만 있어 내부 padding·corner·font·shortcut 구간을 독립 식별할 수 없음. |
| `tooltip["font_size"]` | 14 px / default | 미측정 | 기록만 | S4는 짧은 제목 단일줄 tooltip. 상자 probe만 있어 내부 padding·corner·font·shortcut 구간을 독립 식별할 수 없음. |
| `tooltip["title.max_width"]` | 288 px / default | 미측정 | 기록만 | S4는 짧은 제목 단일줄 tooltip. 상자 probe만 있어 내부 padding·corner·font·shortcut 구간을 독립 식별할 수 없음. |
| `tooltip["title.shortcut_gap"]` | 16 px / default | 미측정 | 기록만 | S4는 짧은 제목 단일줄 tooltip. 상자 probe만 있어 내부 padding·corner·font·shortcut 구간을 독립 식별할 수 없음. |
| `tooltip["meta.font_size"]` | 12 px / default | 미측정 | 기록만 | S4는 짧은 제목 단일줄 tooltip. 상자 probe만 있어 내부 padding·corner·font·shortcut 구간을 독립 식별할 수 없음. |
| `tooltip["shortcut.padding_x"]` | 2 px / default | 미측정 | 기록만 | S4는 짧은 제목 단일줄 tooltip. 상자 probe만 있어 내부 padding·corner·font·shortcut 구간을 독립 식별할 수 없음. |
| `tooltip["shortcut.padding_y"]` | 2 px / default | 미측정 | 기록만 | S4는 짧은 제목 단일줄 tooltip. 상자 probe만 있어 내부 padding·corner·font·shortcut 구간을 독립 식별할 수 없음. |
| `tooltip["shortcut.chord_gap"]` | 4 px / default | 미측정 | 기록만 | S4는 짧은 제목 단일줄 tooltip. 상자 probe만 있어 내부 padding·corner·font·shortcut 구간을 독립 식별할 수 없음. |
| `menu["max_height_ratio"]` | 0.75 ratio / default | 미측정 | 기록만 | S5/S6에서 해당 내부 label/icon/font 또는 한계 높이·keyboard 위치 조건이 노출되지 않음. |
| `menu["border_width"]` | 1 px / default | 미측정 | 기록만 | S5/S6에서 해당 내부 label/icon/font 또는 한계 높이·keyboard 위치 조건이 노출되지 않음. |
| `menu["corner_radius"]` | 8 px / default | 미측정 | 기록만 | S5/S6에서 해당 내부 label/icon/font 또는 한계 높이·keyboard 위치 조건이 노출되지 않음. |
| `menu["item.padding_x"]` | 6 px / default | 미측정 | 기록만 | S5/S6에서 해당 내부 label/icon/font 또는 한계 높이·keyboard 위치 조건이 노출되지 않음. |
| `menu["item.shortcut_min_gap"]` | 16 px / default | 미측정 | 기록만 | S5/S6에서 해당 내부 label/icon/font 또는 한계 높이·keyboard 위치 조건이 노출되지 않음. |
| `menu["item.font_size"]` | 14 px / default | 미측정 | 기록만 | S5/S6에서 해당 내부 label/icon/font 또는 한계 높이·keyboard 위치 조건이 노출되지 않음. |
| `menu["separator.total_height"]` | 13 px / default | 미측정 | 기록만 | S5/S6에서 해당 내부 label/icon/font 또는 한계 높이·keyboard 위치 조건이 노출되지 않음. |
| `menu["app_menu_button.icon_size"]` | 14 px / default | 미측정 | 기록만 | S5/S6에서 해당 내부 label/icon/font 또는 한계 높이·keyboard 위치 조건이 노출되지 않음. |
| `menu["horizontal.item_font_size"]` | 12 px / default | 미측정 | 기록만 | S5/S6에서 해당 내부 label/icon/font 또는 한계 높이·keyboard 위치 조건이 노출되지 않음. |
| `menu["context.window_margin"]` | 8 px / default | 미측정 | 기록만 | S5/S6에서 해당 내부 label/icon/font 또는 한계 높이·keyboard 위치 조건이 노출되지 않음. |
| `menu["context.keyboard_offset_x"]` | 2 px / default | 미측정 | 기록만 | S5/S6에서 해당 내부 label/icon/font 또는 한계 높이·keyboard 위치 조건이 노출되지 않음. |
| `menu["context.keyboard_offset_y"]` | 2 px / default | 미측정 | 기록만 | S5/S6에서 해당 내부 label/icon/font 또는 한계 높이·keyboard 위치 조건이 노출되지 않음. |
| `menu["context.icon_size"]` | 14 px / default | 미측정 | 기록만 | S5/S6에서 해당 내부 label/icon/font 또는 한계 높이·keyboard 위치 조건이 노출되지 않음. |
| `menu["context.header_font_size"]` | 12 px / default | 미측정 | 기록만 | S5/S6에서 해당 내부 label/icon/font 또는 한계 높이·keyboard 위치 조건이 노출되지 않음. |
| `scrollbar["width.ui"]` | 6 px / default | 미측정 | 기록만 | S2는 overflow지만 저장된 캡처에서 scrollbar thumb/track을 독립 식별할 probe나 분리된 픽셀 구간이 없음. 숨김 상태에서 폭을 추정하지 않음. |
| `scrollbar["width.editor"]` | 15 px / default | 미측정 | 기록만 | S2는 overflow지만 저장된 캡처에서 scrollbar thumb/track을 독립 식별할 probe나 분리된 픽셀 구간이 없음. 숨김 상태에서 폭을 추정하지 않음. |
| `scrollbar["padding"]` | 4 px / default | 미측정 | 기록만 | S2는 overflow지만 저장된 캡처에서 scrollbar thumb/track을 독립 식별할 probe나 분리된 픽셀 구간이 없음. 숨김 상태에서 폭을 추정하지 않음. |
| `scrollbar["border_width"]` | 1 px / default | 미측정 | 기록만 | S2는 overflow지만 저장된 캡처에서 scrollbar thumb/track을 독립 식별할 probe나 분리된 픽셀 구간이 없음. 숨김 상태에서 폭을 추정하지 않음. |
| `scrollbar["thumb_min_length"]` | 25 px / default | 미측정 | 기록만 | S2는 overflow지만 저장된 캡처에서 scrollbar thumb/track을 독립 식별할 probe나 분리된 픽셀 구간이 없음. 숨김 상태에서 폭을 추정하지 않음. |
| `inline_input["banner.padding_y"]` | 4 px / default | 미측정 | 기록만 | S7은 정상 이름을 선택한 입력칸. warning/error banner는 없으며 입력 오류를 일부러 만들지 않음. |
| `inline_input["banner.padding_x"]` | 8 px / default | 미측정 | 기록만 | S7은 정상 이름을 선택한 입력칸. warning/error banner는 없으며 입력 오류를 일부러 만들지 않음. |
| `inline_input["banner.border"]` | 1 px / default | 미측정 | 기록만 | S7은 정상 이름을 선택한 입력칸. warning/error banner는 없으며 입력 오류를 일부러 만들지 않음. |

계수: 수치 관측 54행 중 PASS 47, FAIL 1, 기록만 6. 미측정 항목은 통과 수에 넣지 않았다.

## 스펙 불일치 목록

- S1 `sidebar["default_width"]`: 기대 300px, 실제 375, 차이 +75. 리팩토링 전 기준선이며 수정하지 않음. v0.4 이후 대상.

### Q-9·Q-15 및 조건별 해석

- Q-15: 폴더를 등록하기 전 S1부터 사이드바가 375px였다. 앱 로그 scale=1·rem=16, 캡처 DPI=96이므로 DPI 125%로 설명하지 않는다. P0-0c에서 본 300→375와 같은 방향이다. 이번 카드에서는 원인을 수정하지 않았다.
- Q-9: 푸터 실제 31px, 스펙 30px, 차이 +1px다. ±1px 규칙에 따라 PASS지만 값이 같다는 뜻은 아니다. 후속 리팩토링에서도 31px 기준선을 보존하고 스펙 정합화는 별도 결정으로 다룬다.
- S2 comfortable 외형은 행 26px로 관측했다. `project_panel_standard`의 24px 조건을 전환하는 앱 설정 UI는 현재 없어 standard 실측은 못 했다. 26px 관측만으로 설정 내부 값이나 standard 지원을 추론하지 않았다.
- S3a의 preview 파일은 시험 폴더의 `.p0-measure-marker`, S3의 normal 파일은 `file-001.txt`다. preview가 다른 파일로 교체된 뒤 normal로 승격되어 최종 탭은 하나다. 별도 탭 기능 검증은 하지 않았다.
- S4 툴팁 상자는 57×33px이고, 로그의 마우스 위치로부터 외곽 상자까지 합산 오프셋은 x=9px·y=11px다. 개별 투명 margin과 cursor offset을 분리 측정한 것은 아니다.
- S5 메뉴 바깥 폭 213px는 최소 202px와의 불일치가 아니다. 실제 라벨 때문에 최소보다 넓게 렌더된 값으로 기록만 했다. S6 컨텍스트 메뉴의 행 23px는 Q-11/I-508의 추정 행 높이에 대해 판정하지 않았다.
- 스크롤바·폰트 크기·실제 탭 슬롯 내부·툴팁 내부 세부 및 현재 화면에 없는 상태 등 **125개 항목은 미측정/미적용 목록**에 있다. 이 수에는 카드 제외인 아이콘 artwork와 이번 상태에서 나타나지 않는 변형도 포함되므로, 추가로 125개 화면을 측정해야 한다는 의미는 아니다. 전체 스펙 실측 PASS라고 보고하지 않는다.

## 반복 측정 및 V2 이전 후보

Phase 2·3에서 같은 상태로 다시 대조할 핵심 항목이다. lead가 공통 경계 probe와 스펙 ID 기대값을 연결하는 V2 카드로 옮길 수 있다.

| 상태 | 항목 | 현재 기준선 | V2 이전 범위 |
|---|---|---|---|
| S1 | sidebar.default_width / footer.height | 375 / 31px | 초기 분할 폭 및 푸터 바깥 높이. 스펙 300/30과 baseline을 별개 보존 |
| S1 | titlebar.height / window_button.width,height / padding_left / left_group.gap | 32 / 36×32 / 8 / 2px | 정적 상자 및 차분 |
| S1 | window.border_workspace_top,bottom / border_sidebar_right | 1 / 1 / 1px | 인접 상자 차분 |
| S1 | dock.resize_handle_width / project_panel.default_width | 6 / 240px | 기본 폭과 핸들 바깥 상자 |
| S1 | statusbar height·padding·group gap·item gap, footer padding·gap, 작은 아이콘/버튼 | 위 측정표 | 기존 probe만으로 가능한 상자·간격 |
| S2 | project_panel.item.height / indent_step / item.gap / indent_guide 폭·offset·padding | 26 / 20 / 4 / 1·15·4px | 가상화 행과 깊이별 차분. 패널 아이콘 16은 기록만 유지 |
| S3 | tab.bar_height / bar_icon_size / end_buttons_area gap·padding | 32 / 14 / 4·6px | 현재 노출 probe. 실제 탭 슬롯은 probe 보강 후 별도 확인 |
| S4 | tooltip 외곽 및 마우스 기준 합산 offset | 57×33 / 9·11px (동일 문구) | 상자 크기는 글꼴·문구 조건 포함. 독립 padding/font 판정은 분리 |
| S5·S6 | menu item line box·list padding·margin·separator | 위 측정표 | 공통 메뉴 스타일 체인 통합 전후 비교. 메뉴 폭은 라벨에 따라 변함 |
| S7 | inline_input.height·행 테두리 | 24 / 위아래왼쪽1·오른쪽2px | 입력 컨테이너 probe, 테두리는 별도 픽셀 증거 |

## 실행·복원 및 도구 한계

- master 커밋 `c6b680ab0fe0edbd75f59ca95288afa69cd47383`. 현재 실행 파일 SHA-256은 `FEF355ED355A20A446BD9CDBF5157CF49256214DF9A69445C28BD1D6162B1EFA`이며 측정 시작·종료에 같다. 이번 카드에서 cargo build나 매니페스트 변경은 하지 않았다.
- 앱은 한 번만 실행했다. 초기 숨김 창을 동일 HWND로 표시·최대화했다. 창 제어 도구가 활성화 시 최대화를 해제한 중간 프레임은 채택하지 않고, 이후 기존 검증 스크립트의 native 입력 선언을 재사용해 상태를 만들었다. 저장된 S1~S7 캡처 모두 DISPLAY1·DPI 96·maximized=true·capture.ok=true다.
- S4 전환 중 별도 OpenWith 프로세스의 `Open With` 창이 전면을 막았다. 전면 확인 실패 시 앱 입력은 보내지 않았다. 클래스·프로세스 이름을 확인한 뒤 Esc로 그 창을 닫았으며, 연결 앱을 선택하거나 파일 연결 설정을 바꾸지 않았다. 이후 유효한 S4~S7 덤프만 채택했다.
- `tools/measure/p0-session.ps1`: 사용자 데이터 전체 백업, 새 target 시험 폴더 준비, 실행·덤프·capture.ps1 호출·복원. `p0-input.ps1`: 기존 phase4 native 입력 선언 재사용과 대상 창·전면·최대화·좌표 경계 확인. `p0-show.ps1`: 최초 숨김 창 표시. `p0-pixels.ps1`: 저장된 S7 캡처의 픽셀 run 측정. `p0-report.ps1`: 저장된 근거와 toml의 값 대조 및 범위 목록 생성.
- source 값을 실행 측정값 대신 넣지 않았다. 예를 들어 live tab에 slot probe가 없어 계산기가 중단한 항목은 실제 tab-slot 측정으로 바꾸지 않고 미측정으로 남겼다. 픽셀 run은 S7 테두리 형상 판정에만 썼고 색 정합화 판정은 하지 않았다.
- 사용자 데이터: `specs/v0.3/verify/reviews/_p0-6-backup/before.json`, 원본 전체 복사 `appdata/`. 시작 파일 목록 `{}`와 종료 파일 목록 `{}`가 동일하다. `after.json`: restored=true, fixtureRemoved=true, exeUnchanged=true. 앱 정상 종료 후 시험 폴더는 표지·절대 경로를 확인해 삭제했다.
- src·spec·지난 버전 폴더 수정 없음. git 커밋 없음. PROGRESS·TASKS·HANDOFF는 lead에게 이 결과로 전달한다.
- 측정 불가/미적용의 처리와 후속 probe 보강 범위는 lead 판단 대상이다. 본 기록은 관측된 상태의 기준선이며, 미측정 항목을 통과로 간주하지 않는다.

- Open With 발생 시점 **추정**: `actions.log` 5~6행의 `DoubleClick tree-row-04`(file-001.txt) → `Hover active-item` 이후, S4 툴팁 이동의 전면 확인에서 처음 발견했다.
- 직전 S3 덤프 seq=14와 app-stdout.txt 2382~2388행은 file-001.txt가 앱 내부 normal 탭으로 열린 사실을 보여 준다. 따라서 시간상 S3 더블클릭 뒤에 나타난 것으로 추정하되, 더블클릭이 외부 Open With를 직접 호출했다는 근거는 없다.
- 해당 구간에 `shell op=open-default` 기록은 없어 발생 원인은 확정하지 못했으며, 다른 프로세스에서 발생했을 가능성도 배제하지 않는다.

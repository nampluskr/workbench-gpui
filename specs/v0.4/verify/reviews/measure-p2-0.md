# P2-0 V3 실측 (UI 셸·에디터 영역) — 2026-11-04

- 대상: master `cf3a82d`. 빌드 직후 `target\debug\workbench-gpui.exe`를 `C:\Users\nampl\AppData\Local\Temp\wbg-measure\cf3a82d\workbench-gpui.exe`로 복사해 그 사본으로 실행했다(lead 지시). 사본 SHA-256 `6160BC7B3E4D8A10495C92F7E6E3C06D285A7150B05215C8CDDD523534C86F13`(매니페스트 병합 전 `E1AF0A4BB47BFD2EDFE82805B5A78E099162F91A5BC5B214F79A62A45D33926A`). 종료 뒤 exeUnchanged를 session 정리 결과로 확인.
- 이전 시도(`_p2-0-run1-unverified/`): 공유 target exe로 한 번 측정했으나 그 exe가 master 빌드인지 증명할 수 없어(빌드 뒤 다른 worktree 빌드가 덮어썼을 수 있음) 폐기하고 사본으로 다시 쟀다. 이 문서는 사본 실행만 근거로 한다.
- 조건: DISPLAY1 1920x1080, DPI 96 (100%), 최대화 client 1920x1032, 앱 기본 라이트 테마, rem=16. 허용 오차는 toml verification.tolerance.dimension = ±1 논리 px.
- 판정: 같으면 PASS, 오차(±1px) 안에서 다르면 **불일치(오차 안)**(D-3: 이것도 맞춘다), 오차 밖이면 FAIL, 의미가 최솟값·경계값이라 판정하지 않으면 기록만. 미측정은 통과 수에 넣지 않는다.
- 앱 프로세스 1회(PID 14600): `--dev-layout --dev-keymap --dev-pick-folder`, 시작 전 기존 앱 없음 확인. --dev-editor-poc 는 쓰지 않았다(앱 1회 원칙). 에디터 영역은 gpui-kit Editor(읽기 전용)에 probe가 없어 캡처 픽셀로 쟀다.
- 상태: S1 빈 화면·최대화; S2 시험 폴더(파일 80개) 등록, branch·nested 펼침; S3a 파일 한 번 클릭(preview 탭); S3 다른 파일 더블클릭(일반 탭, 에디터 표시); S3c 같은 상태를 커서가 켜진 프레임에서 다시 캡처; S4 새 탭 버튼 tooltip; S5 앱 메뉴; S6 파일 컨텍스트 메뉴; S7 F2 이름 바꾸기 입력칸(이후 Esc). 상태에 도달하는 입력만 했다. 원문 덤프·캡처는 `p2-0-measure/`.

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
| S2 | `sidebar["project_header.height"]` | 31 px | 31 | 0 | PASS | S2-dump.txt seq=8 folder-row-00.h;  |
| S1 | `sidebar["footer.height"]` | 30 px | 31 | 1 | 불일치(오차 안) | S1-dump.txt seq=2 sidebar-footer.h; Q-9: 31 vs 30; +1 is within tolerance |
| S1 | `sidebar["footer.padding"]` | 4 px | 4 | 0 | PASS | S1-dump.txt seq=2 sidebar-btn-toggle.x - sidebar-footer.x;  |
| S1 | `sidebar["footer.gap"]` | 4 px | 4 | 0 | PASS | S1-dump.txt seq=2 placeholder.x - toggle.right;  |
| S1 | `sidebar["footer.icon_size"]` | 14 px | 14 | 0 | PASS | S1-dump.txt seq=2 sidebar-icon-toggle.w;  |
| S1 | `dock["resize_handle_width"]` | 6 px | 6 | 0 | PASS | S1-dump.txt seq=2 dock-handle.w;  |
| S1 | `project_panel["default_width"]` | 240 px | 240 | 0 | PASS | S1-dump.txt seq=2 dock.w;  |
| S2 | `project_panel["item.height"]` | 26 px | 26 | 0 | PASS | S2-dump.txt seq=8 tree-row-01.h; comfortable 26 observed; standard is not switchable in this UI |
| S2 | `project_panel["item.gap"]` | 4 px | 4 | 0 | PASS | S2-dump.txt seq=8 tree-label-02.x - tree-icon-02.right;  |
| S2 | `project_panel["indent_step"]` | 20 px | 20 | 0 | PASS | S2-dump.txt seq=8 depth2 icon.x - depth1 icon.x;  |
| S2 | `project_panel["indent_guide.width"]` | 1 px | 1 | 0 | PASS | S2-dump.txt seq=8 tree-guide-02-1.w;  |
| S2 | `project_panel["indent_guide.offset_x"]` | 15 px | 15 | 0 | PASS | S2-dump.txt seq=8 tree-guide-01-0.x - tree-row-01.x;  |
| S2 | `project_panel["indent_guide.padding_y"]` | 4 px | 4 | 0 | PASS | S2-dump.txt seq=8 tree-guide-01-0.y - tree-row-01.y;  |
| S2 | `icons["size.medium"]` | 16 px | 16 | 0 | 기록만 | S2-dump.txt seq=8 tree-icon-02.w; Q-11/L-40: panel icon box 16 only recorded |
| S3 | `tab["bar_height"]` | 32 px | 32 | 0 | PASS | S3-dump.txt seq=13 tab-bar.h;  |
| S3 | `tab["content_height"]` | 31 px | 32 | 1 | 기록만 | S3-dump.txt seq=13 tab-00.h minus bottom blank/border; combined occupied box; tab-content probe absent for live tabs; outer box is 32 |
| S3 | `tab["end_buttons_area.gap"]` | 4 px | 4 | 0 | PASS | S3-dump.txt seq=13 tab-btn-split.x - tab-btn-new.right;  |
| S3 | `tab["end_buttons_area.padding_x"]` | 6 px | 6 | 0 | PASS | S3-dump.txt seq=13 tab-btn-new.x - tab-bar-end.x - left border(1); border measured as adjacent single-pixel gap |
| S3 | `tab["bar_icon_size"]` | 14 px | 14 | 0 | PASS | S3-dump.txt seq=13 tab-icon-new.w;  |
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
| S5 | `menu["item.line_height"]` | 22.652 px | 23 | 0.348 | 불일치(오차 안) | S5-dump.txt seq=17 menu-row-00.h; rendered line box 23 vs source 22.652 |
| S5 | `menu["horizontal.item_gap"]` | 4 px | 4 | 0 | PASS | S5-dump.txt seq=17 menu-name-1.x - menu-name-0.right;  |
| S6 | `menu["separator.height"]` | 1 px | 1 | 0 | PASS | S6-dump.txt seq=20 ctx-menu-row-2.h;  |
| S6 | `menu["separator.margin_y"]` | 6 px | 6 | 0 | PASS | S6-dump.txt seq=20 separator.y - preceding row.bottom;  |
| S6 | `menu["item.line_height"]` | 22.652 px | 23 | 0.348 | 기록만 | S6-dump.txt seq=20 ctx-menu-row-0.h; Q-11/I-508: current context row height 23; no estimated-height verdict |
| S7 | `inline_input["height"]` | 24 px | 24 | 0 | PASS | S7-dump.txt seq=24 tree-label-05.h (rename input container);  |
| S7 | `inline_input["border_right"]` | 2 px | 2 | 0 | PASS | S7-dump.txt seq=24 S7.png y=176 x=612..613; S7-pixels.json; pixel scan, not a source-code value |
| S7 | `inline_input["border_top_bottom_left"]` | 1 px | 1 | 0 | PASS | S7-dump.txt seq=24 S7.png: top y=163, interior y=164..187, bottom y=188 (x=520); top and bottom measured; left border not separable from the dock border (x=374-375, 229-gray) |
| S3 | `editor["cursor_width"]` | 2 px | 1 | -1 | 불일치(오차 안) | S3-dump.txt seq=13 S3c.png blink-on frame: dark column x=667 only (1 px), y=75..91; pixel scan; cursor visible only in blink-on frames |
| S3 | `editor["line_height.standard"]` | 19.5 px | 20 | 0.5 | 불일치(오차 안) | S3-dump.txt seq=13 S3.png line-number glyph rows 80-87 / 100-107: pitch 20; pixel pitch from 2 visible lines (1 px resolution); compared with standard 19.5 |
| S3 | `editor["line_height.comfortable"]` | 24.27 px | 20 | -4.27 | FAIL | S3-dump.txt seq=13 S3.png line-number glyph rows 80-87 / 100-107: pitch 20; same pitch compared with comfortable 24.27 (Zed default multiplier 1.618) |

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
| `tab["border_width"]` | 1 px / default | 미측정 | 기록만 | 실제 탭에서 일부 slot/content probe가 없거나 overflow·제목 최대 길이 조건 미도달. |
| `tab["active_padding_bottom"]` | 1 px / default | 미측정 | 기록만 | 실제 탭에서 일부 slot/content probe가 없거나 overflow·제목 최대 길이 조건 미도달. |
| `tab["indicator_size"]` | 10 px / default | 미측정 | 기록만 | 실제 탭에서 일부 slot/content probe가 없거나 overflow·제목 최대 길이 조건 미도달. |
| `tab["secondary_path.font_size"]` | 10 px / default | 미측정 | 기록만 | 실제 탭에서 일부 slot/content probe가 없거나 overflow·제목 최대 길이 조건 미도달. |
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
| `editor["line_height.comfortable_multiplier"]` | 1.618 ratio / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["line_height.standard_multiplier"]` | 1.3 ratio / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["scrollbar_track_border_left"]` | 1 px / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["toolbar.padding_y"]` | 6 px / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["toolbar.padding_x"]` | 8 px / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["toolbar.border_bottom"]` | 1 px / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["toolbar.min_height"]` | 32 px / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["toolbar.quick_actions_gap"]` | 1 px / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["search_bar.gap"]` | 8 px / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["search_input.min_height"]` | 32 px / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["search_input.padding_left"]` | 8 px / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["search_input.padding_right"]` | 4 px / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["search_input.border"]` | 1 px / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["search_input.corner_radius"]` | 6 px / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["search_input.font_size"]` | 14 px / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["search_input.line_height_multiplier"]` | 1.3 ratio / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["search_input.options_gap"]` | 4 px / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["search_bar.modes_min_width"]` | 256 px / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["search_bar.modes_gap"]` | 4 px / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["search_bar.separator_width"]` | 1 px / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["search_bar.separator_padding_left"]` | 8 px / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["search_bar.separator_margin_left"]` | 8 px / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["search_results_count.font_size"]` | 12 px / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["search_results_count.margin_left"]` | 8 px / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["search_results_count.min_width"]` | 40 px / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["search_bar.narrow_threshold"]` | 340 px / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["search_error.offset_top"]` | -4 px / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["search_error.offset_left"]` | 8 px / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["tab_size"]` | 4 chars / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["confirm_close.path_max_chars"]` | 80 chars / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["new_buffer.title_max_chars"]` | 40 chars / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["horizontal_scroll_margin"]` | 5 chars / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `editor["selection.corner_radius_multiplier"]` | 0.15 ratio / default | 미측정 | 기록만 | gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다. |
| `inline_input["banner.padding_y"]` | 4 px / default | 미측정 | 기록만 | S7은 정상 이름을 선택한 입력칸. warning/error banner는 없으며 입력 오류를 일부러 만들지 않음. |
| `inline_input["banner.padding_x"]` | 8 px / default | 미측정 | 기록만 | S7은 정상 이름을 선택한 입력칸. warning/error banner는 없으며 입력 오류를 일부러 만들지 않음. |
| `inline_input["banner.border"]` | 1 px / default | 미측정 | 기록만 | S7은 정상 이름을 선택한 입력칸. warning/error banner는 없으며 입력 오류를 일부러 만들지 않음. |

계수: 수치 관측 57행 = PASS 45, 불일치(오차 안) 4, FAIL 2, 기록만 6. 미측정 162항목은 통과 수에 넣지 않았다.

## 영역별 불일치 수

| 영역 | 관측 | PASS | 불일치(오차 안) | FAIL | 기록만 |
|---|---:|---:|---:|---:|---:|
| buttons | 1 | 1 | 0 | 0 | 0 |
| dock | 1 | 1 | 0 | 0 | 0 |
| editor | 3 | 0 | 2 | 1 | 0 |
| icons | 2 | 1 | 0 | 0 | 1 |
| inline_input | 3 | 3 | 0 | 0 | 0 |
| menu | 11 | 7 | 1 | 0 | 3 |
| project_panel | 7 | 7 | 0 | 0 | 0 |
| sidebar | 7 | 5 | 1 | 1 | 0 |
| statusbar | 6 | 6 | 0 | 0 | 0 |
| tab | 5 | 4 | 0 | 0 | 1 |
| titlebar | 5 | 5 | 0 | 0 | 0 |
| tooltip | 3 | 2 | 0 | 0 | 1 |
| window | 3 | 3 | 0 | 0 | 0 |

## 스펙 불일치 목록 (D-3: Phase 2에서 맞춘다)

- [FAIL] S1 `sidebar["default_width"]`: 기대 300px, 실제 375, 차이 75. Q-15: empty state, before folder registration
- [불일치(오차 안)] S1 `sidebar["footer.height"]`: 기대 30px, 실제 31, 차이 1. Q-9: 31 vs 30; +1 is within tolerance
- [불일치(오차 안)] S5 `menu["item.line_height"]`: 기대 22.652px, 실제 23, 차이 0.348. rendered line box 23 vs source 22.652
- [불일치(오차 안)] S3 `editor["cursor_width"]`: 기대 2px, 실제 1, 차이 -1. pixel scan; cursor visible only in blink-on frames
- [불일치(오차 안)] S3 `editor["line_height.standard"]`: 기대 19.5px, 실제 20, 차이 0.5. pixel pitch from 2 visible lines (1 px resolution); compared with standard 19.5
- [FAIL] S3 `editor["line_height.comfortable"]`: 기대 24.27px, 실제 20, 차이 -4.27. same pitch compared with comfortable 24.27 (Zed default multiplier 1.618)

## 기록만 항목 중 값이 기대와 다른 것

- S3 `tab["content_height"]`: 기준 31px, 실제 32, 차이 1. tab-content probe absent for live tabs; outer box is 32
- S5 `menu["min_width"]`: 기준 200px, 실제 211, 차이 11. observed inner width; 200 is a minimum, not fixed width
- S5 `menu["min_outer_width"]`: 기준 202px, 실제 213, 차이 11. 213 >= 202; minimum threshold not reached with this label
- S6 `menu["item.line_height"]`: 기준 22.652px, 실제 23, 차이 0.348. Q-11/I-508: current context row height 23; no estimated-height verdict

## 에디터 영역 관찰값 (스펙 ID는 있으나 ch·digits 단위라 판정하지 않음)

- 편집기 본문 왼쪽 경계 x=616(캡처). 줄 번호 `1`의 잉크는 x=637~642, 본문 첫 글자는 x=668부터다. 줄 번호 왼쪽 여백 21px, 줄 번호 오른쪽 끝에서 본문까지 25px.
- 본문 `Measurement fixture`(19자)의 잉크 폭 x=668~802(135px)로 글자 진행 폭이 약 7.2px이다. 모노 글꼴 0.6em 가정이면 약 12px 글꼴이고, 스펙 `typography["buffer_font_size"]` 15px(진행 폭 약 9px)와 다르다. 글꼴 설정값을 직접 읽지 못해 추정이며 판정하지 않는다.
- 줄 번호는 한 자리로만 그려졌다(오른쪽 정렬 4자리 최소 폭 `gutter.min_line_number_digits` 4의 흔적이 없음). 판정하지 않는다.
- 커서 높이 17px(y=75~91), 폭 1px. 줄 높이는 줄 번호 `1`·`2`의 같은 높이 간격 20px(줄이 2개뿐이라 ±1px).
- 스크롤바(`scrollbar["width.editor"]` 15px)·툴바·검색 막대·분할은 이 상태에 보이지 않아 측정하지 않았다.

## 참고

- 사이드바 기본 폭 300 대 375(FAIL)는 v0.3 P0-6, R-1·R-15의 phase3 R-28 폭 불일치(375/617)와 같은 값이다. 원인은 아직 미확정이다.
- 증거: `p2-0-measure/`(덤프 S1~S7·S3c, 캡처 PNG, 픽셀 스캔 `S3-editor-pixels.json`·`S7-pixels.json`, 생성 스크립트 `p2-0-report.ps1`, `measurements.json`). `_p2-0-run1-unverified/`는 폐기한 첫 시도다.

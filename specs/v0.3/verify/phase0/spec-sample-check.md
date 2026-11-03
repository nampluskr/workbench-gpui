# F3 스펙 표본 대조 — 2026-11-03

- 판정: **REWORK**. 수치 자체가 같아도 조건 또는 출처 절이 다르면 불일치로 판정했다. 아래 불일치 섹션의 전체 재검토를 lead가 spec에게 요청해야 한다.
- 대상: `spec/zed-metrics.toml`, 원문 `docs/refs/01-zed/`의 네 문서. 앱 실행·빌드·테스트와 spec 수정은 하지 않았다.
- 집계: value가 있는 인라인 항목 **388개**, 고유 src 문자열 178개, 고유 원문 ID 177개. **282개는 현재 파일의 항목·출처·ID 집계 어느 것으로도 재현되지 않는 요약 집계 오류이며, 원래 산식은 기록되어 있지 않아 원인은 더 특정할 수 없다.**
- 표본: 각 TOML 테이블에서 파일 순서상 처음 3개(3개 미만이면 전부), 총 **85/388 = 21.91%**. theme 하위 테이블도 각각 3개를 뽑았다. 기본 토큰의 모든 테이블을 포함하므로 번호 붙은 20개 영역 중 19개는 3개 이상이다.
- 표본 수 제한: units 2개, borders 2개, dock 2개는 전부 검사했으며 같은 번호 영역의 다른 테이블을 합치면 각각 3개 이상이다. **17번 interaction은 전체가 1개뿐이므로 3개 조건을 충족할 수 없다.** 중복 표본을 세거나 없는 항목을 만들지 않았다. 이것도 lead에게 전달한다.
- 항목 ID는 실제 TOML 조회 경로 `테이블["키"]`다. 따옴표 안의 점은 중첩 테이블 구분자가 아니다.
- 방법: 먼저 각 표본의 value·unit·cond·src를 읽고, src가 가리키는 원문 절의 항목 행과 조건 문맥을 대조했다. 파일 전체 본문은 열지 않았다. 원문 위치는 파일명(확장자 .md 생략)·절·ID로 표시한다.
- 아래 PASS는 네 필드 모두 일치한다는 뜻이다. 공통 `default`는 TOML 정의의 UI 16px·버퍼 15px·UI 밀도 Default, 프로젝트의 Windows 범위로 해석했다. 원문이 별도 요구하는 조건은 이 공통 조건으로 대체하지 않았다. 섹션별 일치율은 표본 일치율이며 전체 정확도의 추정치는 아니다.

## 불일치 상세 및 lead 전달

1. **window (번호 2)**: 표본 3개 모두 값·px·src는 맞으나 `reference_latte`는 비최대화만 표시한다. L-311의 클라이언트 장식 및 tiled 아닌 변에만 적용되는 조건을 보존하지 않는다. corner_radius·border_width·shadow_size에 적용 범위를 명시해야 한다.
2. **project_panel (번호 5)**: `item.height=26px`는 L-36에서 프로젝트 패널 간격 comfortable일 때다. standard는 위아래 -1px 보정이 있다. UI 밀도 Default와 프로젝트 패널 간격 설정은 다른 조건이다. `cond=default`만으로 26px를 무조건 적용하면 안 된다. content_height=24px는 보정 전 내용 높이로 일치한다.
3. **interaction (번호 17)**: I-103은 `02-INTERACTION`의 **6절**에 있고 **6.1절은 없다**. 250ms는 맞지만 focus_follows_mouse.enabled가 기본 false인 옵션의 debounce라는 적용 조건도 누락됐다. 총 1개라 표본 3개 요건도 충족할 수 없다.
4. **theme.fallback (번호 18)**: 표본 색 3개·hex·src는 맞다. 원문 T-26.5~7은 토큰이 없거나 null일 때 대체 테마를 적용하며 One의 해당 토큰이 사례다. `default`만으로는 그 조건을 나타내지 못해 다른 테마의 명시 색을 덮어쓸 위험이 있다.
5. **verification.tolerance (번호 19)**: `image_reading=0.5px`는 A-30.2의 **기준 이미지 200%에서 물리 1px = 논리 0.5px**인 읽기 오차다. `default`는 scale_factor=1.0이므로 기준 이미지 배율과 논리 단위라는 조건을 보존하지 않는다. dimension·font_size는 해당 논리 오차와 일치한다.

전체 재검토 요청 섹션: **window, project_panel, interaction, theme.fallback, verification.tolerance**. 번호 영역 기준 **2, 5, 17, 18, 19**. 검토자가 직접 수정하지 않았다.

## 조건 정의의 추가 주의

conditions는 value 항목이 아닌 메타데이터라 388개 및 표본 85개에서 제외했다. 세 정의를 참조하면서 원문을 확인했다.

- reference_mocha와 reference_latte의 2.0 배율은 01-LAYOUT 1·1.1절에서 타이틀 바 높이로 역산한 값이다. 원문은 Windows 설정으로 확인하지 않았다고 명시한다. TOML의 dpi=192에는 이 불확실성이 보이지 않는다. A-30.1도 ambiguous에 남아 있으므로 확정 실측 조건으로 취급하지 말아야 한다.
- default의 scale_factor=1.0은 논리 px 정규화 조건으로 이해할 수 있지만 실제 기준 화면 배율은 아니다. 테마 선택, 프로젝트 패널 간격, 기능 활성 여부, fallback 발동 조건까지 대신하지 못한다.

## ambiguous 항목 중 누락 표본 확인

전수 조사는 하지 않았다. 이번에 연 절 안에서 다음을 확인했다.

| 원문 항목 | 확인 | 처리 요청 |
|---|---|---|
| L-152 / L-153, 01-LAYOUT 7절 | sidebar 관찰 약 200px, project panel Mocha 약 284px·Latte 약 215px는 숫자가 분명히 적혀 있지만 toml에는 기본 폭만 있다. ambiguous는 사용자 조정값이라는 이유로 분리한다. | 기본값과 충돌하는 미지의 수치가 아니라 조건부 관찰값이다. 기준 화면 관찰값도 수록할 범위라면 별도 reference 조건 항목으로 보존할지 lead가 결정. 기본값을 바꾸라는 뜻은 아니다. |
| L-309, 01-LAYOUT 5절 | frontmatter 열 비율 1:1은 명시적 관찰값이고 toml에 없다. 행 높이는 **약** 34px이며 소스 미대조라고 원문이 표시한다. | 열 비율 누락 후보를 별도 기록한다. 약 34px를 확정 수치로 입력하라는 요청은 아니다. |
| E-003, 01-LAYOUT 4.12.1절 | 3ch는 확정 선택이고 약 27px는 글꼴 의존 환산이다. toml에는 3ch가 이미 있다. | 누락 아님. ambiguous의 px 환산 불확실성과 원 단위를 구분한다. |
| L-104, 01-LAYOUT 5절 | ambiguous는 margin 위 24px·아래 12px를 추정이라고 분리했으나, toml markdown_preview.heading.margin_top/bottom에도 이미 들어 있다. | 누락이 아니라 이중 취급이다. 추정값을 본 스펙에 넣는 정책과 맞는지 번호 16도 별도 확인 요청. 아래 85개 표본의 불일치율에는 추가하지 않았다. |

## 표본 대조표

원문 값 열은 원문의 값과 필요한 적용 조건을 요약한다. 상세 이견은 위 번호를 따른다.

| 섹션 | 항목 ID | toml 값 (value / unit / cond) | 원문 값·조건 | 원문 위치 (= src 대조) | 판정 |
|---|---|---|---|---|---|
| units | `units["rem_size"]` | 16 / px / default | 16 px; 기본 조건 동일 | 01-LAYOUT 2절 L-01 | PASS |
| units | `units["phi"]` | 1.618 / ratio / default | 1.618 ratio; 기본 조건 동일 | 01-LAYOUT 2절 L-09 | PASS |
| typography | `typography["ui_font_size"]` | 16 / px / default | 16 px; 기본 조건 동일 | 01-LAYOUT 2절 L-08 | PASS |
| typography | `typography["buffer_font_size"]` | 15 / px / default | 15 px; 기본 조건 동일 | 01-LAYOUT 2절 L-08 | PASS |
| typography | `typography["size.large"]` | 16 / px / default | 16 px; 기본 조건 동일 | 01-LAYOUT 2절 L-05 | PASS |
| icons | `icons["size.indicator"]` | 10 / px / default | 10 px; 기본 조건 동일 | 01-LAYOUT 2절 L-06 | PASS |
| icons | `icons["size.xsmall"]` | 12 / px / default | 12 px; 기본 조건 동일 | 01-LAYOUT 2절 L-06 | PASS |
| icons | `icons["size.small"]` | 14 / px / default | 14 px; 기본 조건 동일 | 01-LAYOUT 2절 L-06 | PASS |
| buttons | `buttons["height.large"]` | 32 / px / default | 32 px; 기본 조건 동일 | 01-LAYOUT 2절 L-07 | PASS |
| buttons | `buttons["height.medium"]` | 28 / px / default | 28 px; 기본 조건 동일 | 01-LAYOUT 2절 L-07 | PASS |
| buttons | `buttons["height.default"]` | 22 / px / default | 22 px; 기본 조건 동일 | 01-LAYOUT 2절 L-07 | PASS |
| spacing | `spacing["base00"]` | 0 / px / default | 0 px; 기본 조건 동일 | 01-LAYOUT 2절 L-03 | PASS |
| spacing | `spacing["base01"]` | 1 / px / default | 1 px; 기본 조건 동일 | 01-LAYOUT 2절 L-03 | PASS |
| spacing | `spacing["base02"]` | 2 / px / default | 2 px; 기본 조건 동일 | 01-LAYOUT 2절 L-03 | PASS |
| borders | `borders["radius.sm"]` | 4 / px / default | 4 px; 기본 조건 동일 | 01-LAYOUT 2절 L-10 | PASS |
| borders | `borders["radius.lg"]` | 8 / px / default | 8 px; 기본 조건 동일 | 01-LAYOUT 2절 L-10 | PASS |
| window | `window["unmaximized.corner_radius"]` | 10 / px / reference_latte | 10 px; 비최대화·client decoration·tiled 아닌 변 | 01-LAYOUT 3절 L-311 | FAIL cond (1) |
| window | `window["unmaximized.border_width"]` | 1 / px / reference_latte | 1 px; 비최대화·client decoration·tiled 아닌 변 | 01-LAYOUT 3절 L-311 | FAIL cond (1) |
| window | `window["unmaximized.shadow_size"]` | 10 / px / reference_latte | 10 px; 비최대화·client decoration·tiled 아닌 변 | 01-LAYOUT 3절 L-311 | FAIL cond (1) |
| titlebar | `titlebar["height"]` | 32 / px / default | 32px; Windows 고정 (프로젝트 Windows 범위) | 01-LAYOUT 4.1절 L-21 | PASS |
| titlebar | `titlebar["padding_left"]` | 8 / px / default | 8 px; 기본 조건 동일 | 01-LAYOUT 4.1절 L-82 | PASS |
| titlebar | `titlebar["left_group.gap"]` | 2 / px / default | 2 px; 기본 조건 동일 | 01-LAYOUT 4.1절 L-87 | PASS |
| sidebar | `sidebar["default_width"]` | 300 / px / default | 300 px; 기본 조건 동일 | 01-LAYOUT 4.2절 L-33 | PASS |
| sidebar | `sidebar["min_width"]` | 200 / px / default | 200 px; 기본 조건 동일 | 01-LAYOUT 4.2절 L-33 | PASS |
| sidebar | `sidebar["max_width"]` | 800 / px / default | 800 px; 기본 조건 동일 | 01-LAYOUT 4.2절 L-33 | PASS |
| dock | `dock["resize_handle_width"]` | 6 / px / default | 6 px; 기본 조건 동일 | 01-LAYOUT 4.3절 L-30 | PASS |
| dock | `dock["min_width"]` | 6 / px / default | 6 px; 기본 조건 동일 | 01-LAYOUT 4.3절 L-31 | PASS |
| project_panel | `project_panel["default_width"]` | 240 / px / default | 240 px; 기본 조건 동일 | 01-LAYOUT 4.3절 L-32 | PASS |
| project_panel | `project_panel["item.height"]` | 26 / px / default | 26px; 패널 간격 comfortable (standard 보정 별도) | 01-LAYOUT 4.3절 L-36 | FAIL cond (2) |
| project_panel | `project_panel["item.content_height"]` | 24 / px / default | 24 px; 기본 조건 동일 | 01-LAYOUT 4.3절 L-36 | PASS |
| tab | `tab["bar_height"]` | 32 / px / default | 32 px; 기본 조건 동일 | 01-LAYOUT 4.4절 L-22 | PASS |
| tab | `tab["content_height"]` | 31 / px / default | 31 px; 기본 조건 동일 | 01-LAYOUT 4.4절 L-23 | PASS |
| tab | `tab["padding_x"]` | 4 / px / default | 4 px; 기본 조건 동일 | 01-LAYOUT 4.4절 L-24 | PASS |
| pane | `pane["split_line_thickness"]` | 1 / px / default | 1 px; 기본 조건 동일 | 01-LAYOUT 4.5절 I-725 | PASS |
| pane | `pane["split_line_mouse_hitbox"]` | 4 / px / default | 4 px; 기본 조건 동일 | 01-LAYOUT 4.5절 I-725 | PASS |
| pane | `pane["min_drag_width"]` | 80 / px / default | 80 px; 기본 조건 동일 | 01-LAYOUT 4.5절 I-726 | PASS |
| statusbar | `statusbar["height"]` | 30 / px / default | 30px 계산값 (4×2+22); 관찰 약31과 구분 | 01-LAYOUT 4.6절 L-28 | PASS |
| statusbar | `statusbar["padding_y"]` | 4 / px / default | 4 px; 기본 조건 동일 | 01-LAYOUT 4.6절 L-28 | PASS |
| statusbar | `statusbar["button_height"]` | 22 / px / default | 22 px; 기본 조건 동일 | 01-LAYOUT 4.6절 L-28 | PASS |
| tooltip | `tooltip["delay_default"]` | 500 / ms / default | 500 ms; 기본 조건 동일 | 01-LAYOUT 4.7절 L-206 | PASS |
| tooltip | `tooltip["cursor_offset_x"]` | 1 / px / default | 1 px; 기본 조건 동일 | 01-LAYOUT 4.7절 L-208 | PASS |
| tooltip | `tooltip["cursor_offset_y"]` | 1 / px / default | 1 px; 기본 조건 동일 | 01-LAYOUT 4.7절 L-208 | PASS |
| menu | `menu["min_width"]` | 200 / px / default | 200 px; 기본 조건 동일 | 01-LAYOUT 4.8절 I-313 | PASS |
| menu | `menu["min_outer_width"]` | 202 / px / default | 202 px; 기본 조건 동일 | 01-LAYOUT 4.8절 I-313 | PASS |
| menu | `menu["max_height_ratio"]` | 0.75 / ratio / default | 0.75 ratio; 기본 조건 동일 | 01-LAYOUT 4.8절 I-313 | PASS |
| scrollbar | `scrollbar["width.ui"]` | 6 / px / default | 6 px; 기본 조건 동일 | 01-LAYOUT 4.10절 L-308 | PASS |
| scrollbar | `scrollbar["width.editor"]` | 15 / px / default | 15 px; 기본 조건 동일 | 01-LAYOUT 4.10절 L-308 | PASS |
| scrollbar | `scrollbar["padding"]` | 4 / px / default | 4 px; 기본 조건 동일 | 01-LAYOUT 4.10절 L-308 | PASS |
| editor | `editor["gutter.min_line_number_digits"]` | 4 / digits / default | 4 digits; 기본 조건 동일 | 01-LAYOUT 4.12.1절 E-002 | PASS |
| editor | `editor["gutter.padding_left_ch"]` | 3 / ch / default | 3 ch; 원문에서 앱이 같은 여백을 유지하도록 선택 | 01-LAYOUT 4.12.1절 E-003 | PASS |
| editor | `editor["gutter.padding_right_ch"]` | 4 / ch / default | 4 ch; 원문에서 앱이 같은 여백을 유지하도록 선택 | 01-LAYOUT 4.12.1절 E-004 | PASS |
| picker | `picker["modal_top_offset"]` | 80 / px / default | 80 px; 기본 조건 동일 | 01-LAYOUT 4.13.1절 P-001 | PASS |
| picker | `picker["default_width"]` | 544 / px / default | 544 px; 기본 조건 동일 | 01-LAYOUT 4.13.1절 P-002 | PASS |
| picker | `picker["default_max_height"]` | 384 / px / default | 384 px; 기본 조건 동일 | 01-LAYOUT 4.13.1절 P-002 | PASS |
| dialog | `dialog["about.width"]` | 440 / px / default | 440 px; 기본 조건 동일 | 01-LAYOUT 4.13.6절 P-018 | PASS |
| dialog | `dialog["about.height"]` | 300 / px / default | 300 px; 기본 조건 동일 | 01-LAYOUT 4.13.6절 P-018 | PASS |
| dialog | `dialog["about.padding"]` | 16 / px / default | 16 px; 기본 조건 동일 | 01-LAYOUT 4.13.6절 P-018 | PASS |
| inline_input | `inline_input["height"]` | 24 / px / default | 24 px; 기본 조건 동일 | 01-LAYOUT 4.13.7절 P-019 | PASS |
| inline_input | `inline_input["border_top_bottom_left"]` | 1 / px / default | 1 px; 기본 조건 동일 | 01-LAYOUT 4.13.7절 P-020 | PASS |
| inline_input | `inline_input["border_right"]` | 2 / px / default | 2 px; 기본 조건 동일 | 01-LAYOUT 4.13.7절 P-020 | PASS |
| keymap_editor | `keymap_editor["padding"]` | 8 / px / default | 8 px; 기본 조건 동일 | 01-LAYOUT 4.14.1절 K-010 | PASS |
| keymap_editor | `keymap_editor["gap_vertical"]` | 4 / px / default | 4 px; 기본 조건 동일 | 01-LAYOUT 4.14.1절 K-010 | PASS |
| keymap_editor | `keymap_editor["top_row.gap"]` | 8 / px / default | 8 px; 기본 조건 동일 | 01-LAYOUT 4.14.1절 K-011 | PASS |
| extensions | `extensions["header.padding_top"]` | 16 / px / default | 16 px; 기본 조건 동일 | 01-LAYOUT 4.15절 X-45 | PASS |
| extensions | `extensions["header.padding_x"]` | 16 / px / default | 16 px; 기본 조건 동일 | 01-LAYOUT 4.15절 X-45 | PASS |
| extensions | `extensions["header.row_gap"]` | 16 / px / default | 16 px; 기본 조건 동일 | 01-LAYOUT 4.15절 X-45 | PASS |
| markdown_preview | `markdown_preview["max_width"]` | 800 / px / default | 800 px; 기본 조건 동일 | 01-LAYOUT 5절 L-101 | PASS |
| markdown_preview | `markdown_preview["container_padding"]` | 16 / px / default | 16 px; 기본 조건 동일 | 01-LAYOUT 5절 L-102 | PASS |
| markdown_preview | `markdown_preview["body.font_size"]` | 16 / px / default | 16 px; 기본 조건 동일 | 01-LAYOUT 5절 L-103 | PASS |
| interaction | `interaction["mouse_focus_debounce"]` | 250 / ms / default | 250ms; focus_follows_mouse 옵션, 기본 disabled; 실제 6절 I-103 | 02-INTERACTION 6.1절 I-103 | FAIL cond/src (3) |
| theme.fallback | `theme.fallback["panel.focused_border"]` | "#62adef" / hex / default | "#62adef" hex; 해당 토큰 missing/null일 때 fallback (One 사례) | 03-THEME-ICONS 1.2절 T-26.5 | FAIL cond (4) |
| theme.fallback | `theme.fallback["panel.indent_guide"]` | "#3b3d45" / hex / default | "#3b3d45" hex; 해당 토큰 missing/null일 때 fallback (One 사례) | 03-THEME-ICONS 1.2절 T-26.6 | FAIL cond (4) |
| theme.fallback | `theme.fallback["panel.indent_guide_hover"]` | "#1b1d23" / hex / default | "#1b1d23" hex; 해당 토큰 missing/null일 때 fallback (One 사례) | 03-THEME-ICONS 1.2절 T-26.7 | FAIL cond (4) |
| theme.reference_mocha | `theme.reference_mocha["title_bar.background"]` | "#11111b" / hex / reference_mocha | "#11111b" hex; reference_mocha 화면·테마 동일 | 03-THEME-ICONS 2.3절 T-08.1 | PASS |
| theme.reference_mocha | `theme.reference_mocha["tab_bar.background"]` | "#11111b" / hex / reference_mocha | "#11111b" hex; reference_mocha 화면·테마 동일 | 03-THEME-ICONS 2.3절 T-08.1 | PASS |
| theme.reference_mocha | `theme.reference_mocha["status_bar.background"]` | "#11111b" / hex / reference_mocha | "#11111b" hex; reference_mocha 화면·테마 동일 | 03-THEME-ICONS 2.3절 T-08.1 | PASS |
| theme.reference_latte | `theme.reference_latte["title_bar.background"]` | "#dce0e8" / hex / reference_latte | "#dce0e8" hex; reference_latte 화면·테마 동일 | 03-THEME-ICONS 2.3절 T-08.7 | PASS |
| theme.reference_latte | `theme.reference_latte["panel.background"]` | "#e6e9ef" / hex / reference_latte | "#e6e9ef" hex; reference_latte 화면·테마 동일 | 03-THEME-ICONS 2.3절 T-08.8 | PASS |
| theme.reference_latte | `theme.reference_latte["status_bar.background"]` | "#dce0e8" / hex / reference_latte | "#dce0e8" hex; reference_latte 화면·테마 동일 | 03-THEME-ICONS 2.3절 T-08.9 | PASS |
| verification.tolerance | `verification.tolerance["dimension"]` | 1.0 / px / default | 1.0 px; 기본 조건 동일 | 04-APP-SPEC 7.2절 A-31.1 | PASS |
| verification.tolerance | `verification.tolerance["font_size"]` | 0.5 / px / default | 0.5 px; 기본 조건 동일 | 04-APP-SPEC 7.2절 A-31.2 | PASS |
| verification.tolerance | `verification.tolerance["image_reading"]` | 0.5 / px / default | 물리 1px = 논리 0.5px; 기준 이미지 200% | 04-APP-SPEC 7.1절 A-30.2 | FAIL cond (5) |
| app | `app["state_save_debounce"]` | 500 / ms / default | 500 ms; 기본 조건 동일 | 04-APP-SPEC 4.5절 A-24.2 | PASS |
| app | `app["state_replace_retry_delay"]` | 50 / ms / default | 50 ms; 기본 조건 동일 | 04-APP-SPEC 4.5절 A-24.4 | PASS |
| app | `app["state_replace_retry_count"]` | 3 / count / default | 3 count; 기본 조건 동일 | 04-APP-SPEC 4.5절 A-24.4 | PASS |

## 섹션별 표본 일치율

| TOML 섹션 | 전체 항목 | 표본 | 일치 | 불일치 | 일치율 |
|---|---:|---:|---:|---:|---:|
| units | 2 | 2 | 2 | 0 | 100.00% |
| typography | 6 | 3 | 3 | 0 | 100.00% |
| icons | 8 | 3 | 3 | 0 | 100.00% |
| buttons | 8 | 3 | 3 | 0 | 100.00% |
| spacing | 14 | 3 | 3 | 0 | 100.00% |
| borders | 2 | 2 | 2 | 0 | 100.00% |
| window | 8 | 3 | 0 | 3 | 0.00% |
| titlebar | 18 | 3 | 3 | 0 | 100.00% |
| sidebar | 13 | 3 | 3 | 0 | 100.00% |
| dock | 2 | 2 | 2 | 0 | 100.00% |
| project_panel | 13 | 3 | 2 | 1 | 66.67% |
| tab | 16 | 3 | 3 | 0 | 100.00% |
| pane | 10 | 3 | 3 | 0 | 100.00% |
| statusbar | 7 | 3 | 3 | 0 | 100.00% |
| tooltip | 16 | 3 | 3 | 0 | 100.00% |
| menu | 24 | 3 | 3 | 0 | 100.00% |
| scrollbar | 6 | 3 | 3 | 0 | 100.00% |
| editor | 40 | 3 | 3 | 0 | 100.00% |
| picker | 30 | 3 | 3 | 0 | 100.00% |
| dialog | 5 | 3 | 3 | 0 | 100.00% |
| inline_input | 6 | 3 | 3 | 0 | 100.00% |
| keymap_editor | 32 | 3 | 3 | 0 | 100.00% |
| extensions | 28 | 3 | 3 | 0 | 100.00% |
| markdown_preview | 35 | 3 | 3 | 0 | 100.00% |
| interaction | 1 | 1 | 0 | 1 | 0.00% |
| theme.fallback | 8 | 3 | 0 | 3 | 0.00% |
| theme.reference_mocha | 9 | 3 | 3 | 0 | 100.00% |
| theme.reference_latte | 12 | 3 | 3 | 0 | 100.00% |
| verification.tolerance | 4 | 3 | 2 | 1 | 66.67% |
| app | 5 | 3 | 3 | 0 | 100.00% |

전체 표본: 76/85 일치, 9개 불일치, 일치율 89.41%.

## F3-R1 재대조

- 일자: 2026-11-03. 대상: F1-R1 수정판. **판정: PASS (이번 재대조 범위)**.
- 범위: 기존 불일치 9개 항목의 value·unit·cond·src, 새 조건 6개의 정의, conditions.reference_mocha/reference_latte의 배율 역산 불확실성 표기만 확인했다. 기존 통과 76개는 재검사하지 않았다. 원문은 아래 출처에 해당하는 절·항목만 읽었다.
- 기존 F3 결과와 표는 이력으로 유지한다. 이번 범위의 기존 불일치 9개는 모두 해소됐다. 이 판정은 수정판 전체 387개 항목의 전수 검증이나 다른 변경의 승인이라는 뜻이 아니다.

### 기존 불일치 9개

| 섹션 | 항목 ID | 수정 toml 값 / unit / cond | 원문 값·적용 조건 | src 및 원문 위치 | 판정 |
|---|---|---|---|---|---|
| window | `window["unmaximized.corner_radius"]` | 10 / px / window_unmaximized | 모서리 10px; 클라이언트 장식, 비최대화·비tiled 조건 | 01-LAYOUT 3절 L-311, 116행 | PASS |
| window | `window["unmaximized.border_width"]` | 1 / px / window_unmaximized | 테두리 1px; 같은 조건 | 01-LAYOUT 3절 L-311, 116행 | PASS |
| window | `window["unmaximized.shadow_size"]` | 10 / px / window_unmaximized | 바깥 그림자 영역 10px; 같은 조건 | 01-LAYOUT 3절 L-311, 116행 | PASS |
| project_panel | `project_panel["item.height"]` | 26 / px / project_panel_comfortable | 24+2=26px, 패널 간격 comfortable의 추가 padding 0 | 01-LAYOUT 4.3절 L-36, 176행 | PASS |
| interaction | `interaction["mouse_focus_debounce"]` | 250 / ms / focus_follows_mouse | focus_follows_mouse 활성 시 debounce 250ms; 기본 비활성과 구분 | 02-INTERACTION **6절** I-103, 282행. 존재하지 않던 6.1절 참조 수정됨 | PASS |
| theme.fallback | `theme.fallback["panel.focused_border"]` | #62adef / hex / theme_token_fallback | 토큰 null/누락 시 내장 대체값 #62adef (One 사례) | 03-THEME-ICONS 1.2절 T-26.5, 59행 | PASS |
| theme.fallback | `theme.fallback["panel.indent_guide"]` | #3b3d45 / hex / theme_token_fallback | 토큰 null/누락 시 내장 대체값 #3b3d45 (One 사례) | 03-THEME-ICONS 1.2절 T-26.6, 60행 | PASS |
| theme.fallback | `theme.fallback["panel.indent_guide_hover"]` | #1b1d23 / hex / theme_token_fallback | 토큰 null/누락 시 내장 대체값 #1b1d23 (One 사례) | 03-THEME-ICONS 1.2절 T-26.7, 61행 | PASS |
| verification.tolerance | `verification.tolerance["image_reading"]` | 0.5 / px / reference_image_200 | 기준 이미지 200%에서 물리 1px=논리 0.5px의 읽기 오차 | 04-APP-SPEC 7.1절 A-30.2, 987행 | PASS |

### 새 조건 6개

| 조건 | 정의 확인 | 원문 대조 | 판정 |
|---|---|---|---|
| window_unmaximized | decorations=client, maximized=false, tiled_edges=none | 01-LAYOUT 3절 L-311의 비최대화·변이 맞닿지 않은 클라이언트 장식 상태를 나타낸다. 원문의 변별 적용 규칙을 최대화 창에 무조건 적용하는 조건은 아니다. | PASS |
| project_panel_comfortable | name이 프로젝트 패널 간격임을 명시, density=comfortable | 01-LAYOUT 4.3절 L-36의 패널 간격 comfortable, 추가 padding 0. UI 밀도 Default와 구분됐다. | PASS |
| project_panel_standard | name이 프로젝트 패널 간격임을 명시, density=standard | 같은 L-36의 별도 간격 standard 조건을 표현한다. 원문 보정은 위아래 -1px다. 조건 정의만 확인했으며 이 조건을 쓰는 다른 수치는 재검사하지 않았다. | PASS |
| focus_follows_mouse | setting=focus_follows_mouse.enabled=true | 02-INTERACTION 6절 I-103의 옵션 활성 조건. 기본 false라는 원문과 모순 없이 활성 시 적용을 분리했다. | PASS |
| theme_token_fallback | trigger=missing_or_null, fallback_theme=zed_default_dark | 03-THEME-ICONS 1.2절은 missing/null을 값 없음으로 동일 취급하고 JSON 값을 내장 zed_default_dark 위에 덮어쓴다고 명시한다. 이번 세 토큰의 fallback 조건과 일치한다. | PASS |
| reference_image_200 | scale_factor=2.0, unit_conversion=1 physical px = 0.5 logical px | 04-APP-SPEC 7.1절 A-30.2의 기준 이미지 읽기 오차 환산 조건과 일치한다. 실제 Windows 배율을 새로 측정한 결과가 아니다. | PASS |

### 기준 화면 배율 불확실성

| 조건 | 표기 확인 | 원문 | 판정 |
|---|---|---|---|
| reference_mocha | note에 배율 2.0·DPI 192가 타이틀 바 64 물리 px에서 역산한 가정이며 Windows 설정으로 확인하지 않았다고 명시 | 01-LAYOUT 1절, 04-APP-SPEC 7.1절 A-30.1 | PASS |
| reference_latte | 같은 note로 역산 가정과 Windows 설정 미확인을 명시 | 01-LAYOUT 1.1절 L-310(같은 역산), 04-APP-SPEC A-30.1 | PASS |

- 결과: 기존 불일치 **9/9 해소**, 새 조건 **6/6 일치**, 기준 화면 불확실성 표기 **2/2 확인**. 이번 범위의 추가 REWORK 항목 없음.
- 생략: 기존 통과 76개·기타 F1-R1 변경 재검증, 앱 실행, spec 수정. PROGRESS·TASKS는 lead가 이 결과로 갱신한다.

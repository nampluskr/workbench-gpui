# P2-R16 — 자동 레이아웃 검사 `check-layout.ps1`

반복 실측 항목(P2-0·P2-E에서 손으로 잰 빈 화면 S1)을 실제 렌더 경로를 거치는 자동 검사로 옮겼다(SPEC R-16).

## 구성

- `tools/measure/check-layout.ps1 -Exe <절대 경로> [-Out <dir>] [-Report <md>]`: 앱을 `--dev-layout`으로 **1회** 띄운다. 창이 **작게(1536x1080, 최대화 아님) 먼저 뜬 상태의 덤프(S1a)**를 받고, 그다음 최대화해 최대화 상태 덤프(S1, 1920x1032)를 받는다. 첫 덤프가 이미 최대화였거나 최대화가 안 되면 경로 검사 자체가 FAIL이다. 덤프를 `spec/zed-metrics.toml` 기대값과 비교해 항목마다 PASS/FAIL을 내고, 하나라도 FAIL이면 exit 1. 끝나면 앱을 닫고 앱 데이터를 복원한다(`session.ps1 Stop`).
- 재사용: `session.ps1`(시작·스냅숏·종료·`-Exe`), `input.ps1`(최대화), `compare.ps1`.
- `compare.ps1` 확장: 두 박스 차이를 잴 수 있게 `diff` 행(`A.f ~ B.f`, f는 x·y·w·h·r·b)을 추가했다. 검사 목록은 `tools/measure/checks-layout.txt`(28항목).
- 항목: titlebar height·padding_left·left_group.gap·window_button 36x32(3개), window border 3, sidebar default_width·header_height·footer height·padding·gap·icon_size, dock resize_handle_width, project_panel default_width, statusbar height·padding_y·button_height·group_gap·item_gap·icon_size, buttons height.default, icons size.small.
- 사용 주의: 출력을 파이프(`| Tee-Object` 등)로 받지 말고 그대로 두거나 파일로 리다이렉트한다. 앱이 콘솔 핸들을 물고 있어 파이프가 닫히지 않을 수 있다. 시작 호출은 파일 리다이렉트로 분리해 두었다. 100% DPI·주 모니터 전제(다른 `tools/measure` 스크립트와 같다).

## 실행 결과

| 실행 | exe(사본) | 경로 | 결과 | FAIL |
|---|---|---|---|---|
| master `63710c0` | `%TEMP%\wbg-measure\63710c0\` (SHA-256 `57602AAF…E4E483`) | 1536x1080 → 1920x1032 최대화 | **CHECK-LAYOUT: PASS**, exit 0 | 없음 (28/28 PASS) |
| df280c5 (P2-1-R1 이전) | `%TEMP%\wbg-measure\df280c5\` (SHA-256 `00BEB75B…589B73`) | 1536x1080 → 1920x1032 최대화 | **CHECK-LAYOUT: FAIL**, exit 1 | `sidebar["default_width"]` 기대 300, 실제 **375**(+75) |

- 회귀를 잡는다: P2-E 시점의 사이드바 1.25배 회귀(300 → 375)를 df280c5에서 `sidebar["default_width"]` FAIL 하나로 정확히 잡았고, 나머지 27항목은 PASS였다(그 빌드의 푸터 30 등은 이미 맞았다).
- 두 실행 모두 시작 전 앱 프로세스 없음, 종료 후 프로세스 없음, 앱 데이터 폴더 비어 있음(실행 전과 같음).
- 실행 로그는 이 문서에 요약했다. 덤프·session은 `%TEMP%\wbg-check-layout\run4-63710c0\`, `run1-df280c5\`.

## 알려진 한계

- 항목은 빈 화면 S1에서 덤프로 잴 수 있는 것뿐이다. 폴더 등록 뒤 화면(트리 행·들여쓰기), 탭·툴팁·메뉴·입력칸, 에디터 줄 높이·글자 폭·커서·스크롤바는 이 검사에 없다(메뉴·탭 높이는 V2 테스트가 있고, 에디터는 덤프 probe가 없어 캡처 픽셀 측정이 필요하다).
- 사이드바 폭 외에 폴더 등록 뒤 사이드바 폭도 같은 값이어야 하지만(P2-E에서 S2도 375) 이 검사는 S1만 본다.

## R1 — 정확 비교(exact) (P2-R16-R1, phase2-final.md R1)

- `checks-layout.txt` 행 끝에 `| exact`를 두면 `compare.ps1`이 그 행만 허용 오차 0으로 판정한다(`diff` 행도 같다). 표의 `tol` 열에 `exact`로 나온다. cond 열(4번째)과 `exact`는 서로 독립이다.
- 28항목 **전부 `exact`**다. 63710c0 덤프에서 전부 차이 0이고(D-3으로 맞춘 sidebar `default_width` 300, `footer.height` 30 포함), 앞으로 ±1px 어긋나도 잡아야 하기 때문이다.
- 앱은 다시 띄우지 않았다. 저장된 63710c0 덤프(`%TEMP%\wbg-check-layout\run4-63710c0\layout.json`)로만 확인했다.

| 확인 | 덤프 | 비교 | 결과 |
|---|---|---|---|
| 정상 | 63710c0 그대로 | exact 28항목 | **28/28 PASS, exit 0** |
| 회귀 흉내 | 같은 덤프에서 `sidebar-footer` h만 31로 바꾼 사본 | exact 28항목 | **`sidebar["footer.height"]` 기대 30, 실제 31, 차이 1 → FAIL, exit 1** (나머지 27 PASS) |
| 대조 | 같은 사본 | 이전 방식(±1, exact 표시 제거) | 같은 항목이 PASS, exit 0 — 이전 규칙은 이 1px 어긋남을 놓쳤다 |

- 변경 파일: `tools/measure/compare.ps1`(`exact` 열 지원), `tools/measure/checks-layout.txt`(28행에 `| exact`). `check-layout.ps1` 본체는 그대로다.

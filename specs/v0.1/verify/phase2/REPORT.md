# Phase 2 완료 조건 및 일치도 검증 보고서

- **검증 일시**: 2026-11-01 (1회차: 08:58, 2회차 재검증: 09:15)
- **검증자**: wg-checker
- **기준 문서**:
  - `specs/v0.1/SPEC.md` (공통 판정 방식 및 R-6~R-11)
  - `specs/v0.1/PLAN.md` (`## Phase 2 — 편집기 PoC` 완료 조건)
  - `D:\projects\docs\guides\zed-like-editor\02-gpui\README.md` (G-100, G-101, G-102, G-129, G-139)
  - `docs/HERDR-DECISIONS.md` (D-014: R-10 기본 고정폭 글꼴 측정 승인·R-8 앱 내부 이벤트→다음 프레임 측정 방식 승인, D-016: 리뷰 1회차 Major 3건 채택·반영)
- **시험 환경 배율**: 창 DPI `192` (`scale = 2.0`, 배율 **200%**). 수치는 논리 px 기준.

---

## 요약 판정

| 요구 | 요약 | 1회차 판정 | 2회차(최종) 판정 | 비고 |
| --- | --- | --- | --- | --- |
| **R-6** | G-100 한글 IME가 gpui-kit Editor·Input에서 되는지 확인해 기록한다 | 통과 | **통과** | 2회차에서 `verify-ime.ps1` 오류 처리 강화(`openAfter=1`, `modeAfter=1`, `committedTextFound=true`, `errors=[]`) 및 `visualCheck: "수동 판정 대기"` 항목을 새 캡처(`r6-*-composing.png`, `r6-*-candidate.png`) 직접 육안 확인으로 통과 판정 |
| **R-7** | G-101 gpui-kit Editor의 Zed 편집기 동작 지원 범위를 항목별로 확인해 기록한다 | 통과 | **통과** | SPEC R-7의 12개 항목 전체를 빠짐없이 15개 세부 행으로 나누어 지원 여부·직접 구현 필요 여부·소스 위치·스크린샷 기록 확인 |
| **R-8** | G-102 큰 파일의 열기·스크롤·입력 지연을 측정해 기록한다 | 통과 | **통과** | 2회차(D-016 ①)에서 계측 시점을 프레임 핸들러의 `draw`·`present` 완료 이후(`after_present`, `drawn=20/20`, 첫 프레임 `drawn=true`)로 수정해 재측정·기록 완료 |
| **R-9** | G-129 줄 끝과 인코딩이 열고 저장한 뒤 어떻게 되는지 확인해 기록한다 | 통과 | **통과** | 2회차(D-016 ②)에서 `WC_NO_BEST_FIT_CHARS`·반환값·`used_default`·역변환 검증 추가 및 단위 테스트 4건(`r9-cp949-unittest.txt`)·자기 시험 4/4(`r9-cp949-selftest.json`)·4종 파일 바이트 일치 확인 |
| **R-10** | G-139 한글 대체 글꼴이 줄 높이·거터·커서 위치를 어떻게 바꾸는지 측정해 기록한다 | 통과 | **통과** | D-014 ① 승인에 따라 기본 고정폭 글꼴(`Consolas` 13px + `.SystemUIFont` 대체)로 영문 줄·한글 줄·혼합 줄의 5대 측정값(줄 높이, 기준선, 글자 폭, 거터, 커서 위치) 및 스크린샷 기록 확인 |
| **R-11** | PoC 2단계 결과로 편집기의 직접 구현 범위가 확정되어 있다 | 통과 | **통과** | 2회차에서 CP949 저장 손실 방지 행이 추가되어 총 **35개 행**(직접 구현 필요 **12건**, 불필요 **23건**, 판정 불가 **0건**)이 빈 칸·미결 없이 확정됨 |

---

## R-6. G-100 한글 IME가 gpui-kit Editor·Input에서 되는지 확인해 기록한다

- **종합 판정 (1회차·2회차)**: **통과**

### 1회차 판정

| 항목 ID | 명세 값 | 실제 값 | 통과·실패·판정 불가 | 증거 파일 |
| --- | --- | --- | --- | --- |
| G-100 (Editor: 조합 중 표시) | 판정표에 지원/직접 구현 필요 여부 기록 + 조합 중 캡처 확인 | 판정표 기록: `지원` / `불필요`. `r6-editor-composing.png`에서 Editor 4행에 조합 중인 글자 **`한`이 밑줄과 함께 편집 위치에 표시됨**을 직접 확인 | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r6-editor-composing.png`, `specs/v0.1/verify/phase2/r6-ime.json` |
| G-100 (Editor: 후보창 위치) | 판정표에 지원/직접 구현 필요 여부 기록 + 후보창 위치 캡처 확인 | 판정표 기록: `지원` / `불필요`. `r6-editor-candidate.png`에서 Editor 4행의 조합 중인 **`한` 바로 아래에 Windows 한자 후보창(`1 韓 나라이름 한` ~ `9 汗 땀 한`)이 붙어 떠 있음**을 직접 확인 | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r6-editor-candidate.png` |
| G-100 (Editor: 확정) | 판정표에 지원/직접 구현 필요 여부 기록 + 확정 결과 확인 | 판정표 기록: `지원` / `불필요`. `r6-editor-committed.png`에서 Editor 4행에 **`한 가나 `와 뒤따르는 커서(`\|`)가 표시**되고, `r6-ime.json`(`editor.committedTextFound: true`) 및 `r6-stdout.txt`(`len=114`, `"한 가나 "`)에서 값 반영 확인 | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r6-editor-committed.png`, `specs/v0.1/verify/phase2/r6-ime.json`, `specs/v0.1/verify/phase2/r6-stdout.txt` |
| G-100 (Input: 조합 중 표시) | 판정표에 지원/직접 구현 필요 여부 기록 + 조합 중 캡처 확인 | 판정표 기록: `지원` / `불필요`. `r6-input-composing.png`에서 상단 한 줄 `Input` 칸에 조합 중인 **`한`이 밑줄과 함께 표시됨**을 직접 확인 | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r6-input-composing.png`, `specs/v0.1/verify/phase2/r6-ime.json` |
| G-100 (Input: 후보창 위치) | 판정표에 지원/직접 구현 필요 여부 기록 + 후보창 위치 캡처 확인 | 판정표 기록: `지원` / `불필요`. `r6-input-candidate.png`에서 상단 `Input` 칸의 조합 중인 **`한` 바로 아래에 Windows 한자 후보창(`1 韓 나라이름 한` ~ `9 汗 땀 한`)이 붙어 떠 있음**을 직접 확인 | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r6-input-candidate.png` |
| G-100 (Input: 확정) | 판정표에 지원/직접 구현 필요 여부 기록 + 확정 결과 확인 | 판정표 기록: `지원` / `불필요`. `r6-input-committed.png`에서 상단 `Input` 칸에 **`한 가나 `가 표시**되고, `r6-ime.json`(`input.committedTextFound: true`) 및 `r6-stdout.txt`(`text="한 가나 "`)에서 값 반영 확인 | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r6-input-committed.png`, `specs/v0.1/verify/phase2/r6-ime.json`, `specs/v0.1/verify/phase2/r6-stdout.txt` |

### 재검증 (2회차)

- 재수집 시각: `2026-11-01T09:08:25+09:00` ~ `2026-11-01T09:08:41+09:00` (`r6-ime.json`, `pid: 11236`, `hwnd: 0x570830`)
- 변경 사항 (D-016 ③): `tools/verify-ime.ps1`에서 IME 상태 조회 음수 실패값·열림 상태(`openAfter`)·한글 모드 비트(`modeAfter`)·확정 문자열(`committedTextFound`)을 검사해 하나라도 실패 시 `errors` 기록 및 종료 코드 1로 끝나도록 수정. 조합 밑줄과 후보창 위치는 자동 판정 대신 `r6-ime.json`의 `visualCheck.status = "수동 판정 대기"`로 넘기고 검증 담당(wg-checker)이 새 PNG를 직접 눈으로 확인해 판정함.
- **판정**: **통과** (자동 판정 항목 `errors: []` 및 수동 시각 판정 4개 캡처 모두 통과)

| 항목 ID | 명세 값 | 실제 값 (2회차 재수집 증거 및 수동 시각 확인) | 통과·실패·판정 불가 | 증거 파일 |
| --- | --- | --- | --- | --- |
| G-100 (Editor: 조합 중 표시) | 판정표 기록 + `r6-editor-composing.png` 수동 시각 판정 | `r6-ime.json`: `openAfter=1`, `modeAfter=1`, `hangulMode=true`. 새 `r6-editor-composing.png`를 직접 확인한 결과, **Editor 4행 편집 위치에 조합 중인 글자 `한`이 검은 밑줄과 우측 세로 커서(`\|`)와 함께 선명하게 표시됨** | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r6-editor-composing.png`, `specs/v0.1/verify/phase2/r6-ime.json` |
| G-100 (Editor: 후보창 위치) | 판정표 기록 + `r6-editor-candidate.png` 수동 시각 판정 | 새 `r6-editor-candidate.png`(오전 9:08 캡처)를 직접 확인한 결과, **Editor 4행의 밑줄 쳐진 조합 글자 `한` 바로 아래(5행 위치)에 Windows 한자 후보창(`1 韓 나라이름 한` ~ `9 汗 땀 한`)이 정확히 붙어 떠 있음** | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r6-editor-candidate.png`, `specs/v0.1/verify/phase2/r6-ime.json` |
| G-100 (Editor: 확정) | 판정표 기록 + 확정 문자열 자동·시각 확인 | `r6-ime.json`: `editor.committedTextFound: true`, `errors: []`. `r6-stdout.txt` 7행(`len=114`, `"한 가나 "`) 및 새 `r6-editor-committed.png`에서 Editor 4행에 **`한 가나 `가 확정되어 들어감**을 확인 | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r6-editor-committed.png`, `specs/v0.1/verify/phase2/r6-ime.json`, `specs/v0.1/verify/phase2/r6-stdout.txt` |
| G-100 (Input: 조합 중 표시) | 판정표 기록 + `r6-input-composing.png` 수동 시각 판정 | `r6-ime.json`: `openAfter=1`, `modeAfter=1`, `hangulMode=true`. 새 `r6-input-composing.png`를 직접 확인한 결과, **상단 `Input` 입력란 왼쪽에 조합 중인 글자 `한`이 밑줄 및 세로 커서(`\|`)와 함께 선명하게 표시됨** | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r6-input-composing.png`, `specs/v0.1/verify/phase2/r6-ime.json` |
| G-100 (Input: 후보창 위치) | 판정표 기록 + `r6-input-candidate.png` 수동 시각 판정 | 새 `r6-input-candidate.png`(오전 9:08 캡처)를 직접 확인한 결과, **상단 `Input` 입력란의 조합 중인 글자 `한` 바로 아래에 Windows 한자 후보창(`1 韓 나라이름 한` ~ `9 汗 땀 한`)이 정확히 붙어 떠 있음** | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r6-input-candidate.png`, `specs/v0.1/verify/phase2/r6-ime.json` |
| G-100 (Input: 확정) | 판정표 기록 + 확정 문자열 자동·시각 확인 | `r6-ime.json`: `input.committedTextFound: true`, `errors: []`. `r6-stdout.txt` 12행(`text="한 가나 "`) 및 새 `r6-input-committed.png`에서 상단 `Input` 칸에 **`한 가나 `가 확정되어 들어감**을 확인 | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r6-input-committed.png`, `specs/v0.1/verify/phase2/r6-ime.json`, `specs/v0.1/verify/phase2/r6-stdout.txt` |

---

## R-7. G-101 gpui-kit Editor의 Zed 편집기 동작 지원 범위를 항목별로 확인해 기록한다

- **종합 판정**: **통과** (SPEC R-7의 12개 항목이 `POC-TABLE.md`에 15개 행으로 빠짐없이 수록되어 있으며, 각 행에 지원 여부·직접 구현 필요 여부·크레이트 소스 줄 번호 및 캡처 증거가 있음)

| 항목 ID | 명세 값 (SPEC R-7 항목) | 실제 값 (`POC-TABLE.md` 기록 및 증거) | 통과·실패·판정 불가 | 증거 파일 |
| --- | --- | --- | --- | --- |
| G-101.1 | 거터(줄 번호 최소 4자리) | `일부` (`MIN_LINE_NUMBER_DIGITS = 3` 비공개 상수로 3자리 고정) / 직접 구현 `필요` | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, gpui-base `src/input/base/element.rs:56,61`, `specs/v0.1/verify/phase2/r7-editor.png` |
| G-101.2 | 현재 줄 강조 범위 | `지원` (거터 포함 입력 상자 전체 폭 칠함) / 직접 구현 `불필요` (색은 테마 매핑 단계) | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, gpui-base `src/input/base/element.rs:3252-3279`, `specs/v0.1/verify/phase2/r7-editor.png` |
| G-101.3 | 커서 2px·500ms 깜빡임 | 2개 행으로 분리 기록: ① `커서 2px`: `미지원`(`CURSOR_WIDTH = px(1.)` 고정, 실측 폭 `1.00` 논리 px) / 직접 구현 `필요` ② `커서 500ms 깜빡임`: `지원`(`INTERVAL = 500ms`) / 직접 구현 `불필요` | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, gpui-base `src/input/base/blink_cursor.rs:4,7`, `specs/v0.1/verify/phase2/r10-pixels.json` |
| G-101.4 | 선택 모서리 0.15×줄 높이 | `미지원` (`PathBuilder` 직선 다각형으로 그림, 둥글림 없음) / 직접 구현 `필요` | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, gpui-base `src/input/base/element.rs:813-822,2537` |
| G-101.5 | 더블·트리플 클릭 | 2개 행으로 분리 기록: ① `더블 클릭 단어 선택`: `지원`(`select_word`) / `불필요` ② `트리플 클릭 줄 선택`: `지원`(`select_line`) / `불필요` | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, gpui-base `src/input/base/state.rs:2721,2727` |
| G-101.6 | Alt+클릭 다중 커서 | `지원` (`add_cursor_at`) / 직접 구현 `불필요` | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, gpui-base `src/input/base/state.rs:2759` |
| G-101.7 | Ctrl+Shift 드래그 열 선택 | `일부` (열 선택 기능은 있으나 조작 키가 `Alt+Shift` 드래그로 고정) / 직접 구현 `필요` | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, gpui-base `src/input/base/state.rs:2750-2756` |
| G-101.8 | 선택 끌어 옮기기 | `미지원` (`on_drag_move`는 선택 확장만 수행, 선택 텍스트 드래그 이동 없음) / 직접 구현 `필요` | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, gpui-base `src/input/base/state.rs:3969` |
| G-101.9 | soft wrap | `지원` (`soft_wrap(bool)`·`set_soft_wrap`, 기본 `true`) / 직접 구현 `불필요` | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, gpui-base `src/input/base/state.rs:952,12141,12147` |
| G-101.10 | 들여쓰기 안내선 | `지원` (코드 편집기 모드 기본 켜짐, `r7-editor.png` 6행 안내선 확인) / 직접 구현 `불필요` | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, gpui-base `src/input/base/mode.rs:45`, `element.rs:3167`, `specs/v0.1/verify/phase2/r7-editor.png` |
| G-101.11 | 공백 표시 | `일부` (`show_whitespaces(bool)` 전체 켜고 끄기 지원) / 직접 구현 `불필요` | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, gpui-base `src/input/base/state.rs:1505,1511`, `element.rs:1231` |
| G-101.12 | 스크롤바 15px·마커 | 2개 행으로 분리 기록: ① `스크롤바 15px`: `일부`(기본 `WIDTH = 16px`, `set_scrollbar_renderer` 제공) / 직접 구현 `필요` ② `스크롤바 마커`: `미지원`(마커 그리기 없음) / 직접 구현 `필요` | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, gpui-base `src/scrollbar.rs:22`, `src/input/base/state.rs:1148`, `src/input/scrollbar_presentation.rs:49` |

---

## R-8. G-102 큰 파일의 열기·스크롤·입력 지연을 측정해 기록한다

- **종합 판정 (1회차·2회차)**: **통과**

### 1회차 판정

| 항목 ID | 명세 값 | 실제 값 | 통과·실패·판정 불가 | 증거 파일 |
| --- | --- | --- | --- | --- |
| G-102 (측정 파일 줄 수·크기) | 10만 줄 파일의 줄 수·크기 기록 | `lines-100000.txt`: **`100,001`줄, `7,800,000`바이트 (7.8MB, 줄당 약 78바이트 한글 포함)** (보조 비교: `lines-50000.txt` `50,001`줄, `3,900,000`바이트) | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r8-perf-opt.json`, `specs/v0.1/verify/phase2/r8-100k-opt-stdout.txt` |
| G-102 (열기 시간) | 10만 줄 파일 열기 시간 측정·기록 | **soft wrap 켜짐(기본)**: opt 빌드 읽기 `173.17ms`, 디코드 `3.92ms`, `set_value` `184.85ms`, **첫 프레임까지 `8,355.79ms`** (5만 줄은 첫 프레임 `5,006.99ms`, debug 10만 줄은 `18,198.08ms`) → 큰 파일 wrap 제어 직접 구현 `필요`. **soft wrap 끔**: opt 빌드 `set_value` `186.76ms`, **첫 프레임까지 `328.32ms`** → 직접 구현 `불필요` | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r8-perf-opt.json`, `specs/v0.1/verify/phase2/r8-perf-debug.json`, `specs/v0.1/verify/phase2/r8-100k-opt-stdout.txt`, `specs/v0.1/verify/phase2/r8-100k-opt-nowrap-stdout.txt` |
| G-102 (스크롤 지연) | 10만 줄 파일 스크롤 지연 측정·기록 | 20회 스크롤(`last_visible_rows=Some(25000..25042)`까지 이동): opt 빌드 **평균 `8.41ms`, 최소 `1.22ms`, 최대 `16.67ms`** (debug 빌드 평균 `6.95ms`, 최대 `14.11ms`) → 직접 구현 `불필요` | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r8-perf-opt.json`, `specs/v0.1/verify/phase2/r8-100k-opt-stdout.txt` |
| G-102 (입력 지연) | 10만 줄 파일 입력 지연 측정·기록 | 50,000번째 줄에 글자 20회 연속 입력: opt 빌드 **평균 `10.63ms`, 최소 `6.74ms`, 최대 `15.86ms`** (`r8-100k-opt-after.png`에서 50001행 앞에 `x` 20자 입력 확인) → 직접 구현 `불필요` | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r8-perf-opt.json`, `specs/v0.1/verify/phase2/r8-100k-opt-stdout.txt`, `specs/v0.1/verify/phase2/r8-100k-opt-after.png` |

### 재검증 (2회차)

- 변경 사항 (D-016 ①): gpui-pre 0.3.10 프레임 핸들러(`src/window.rs:1878-1912`)에서 `on_next_frame` 콜백이 `window.draw`·`window.present` 전에 실행되므로, 콜백 안에서 foreground 작업을 예약해 **`draw`·`present`가 끝난 뒤(`after_present`)** 시각을 찍도록 수정하고, 매 측정마다 실제 렌더(`EditorPoc::render` 횟수 증가) 여부를 `drawn`으로 검증함.
- **판정**: **통과** (`drawn=20/20`, `firstFrameDrawn="true"` 확인 및 판정표 갱신 완료)

| 항목 ID | 명세 값 | 실제 값 (2회차 `draw`·`present` 완료 이후 재측정) | 통과·실패·판정 불가 | 증거 파일 |
| --- | --- | --- | --- | --- |
| G-102 (측정 파일 줄 수·크기) | 10만 줄 파일의 줄 수·크기 기록 | `lines-100000.txt`: **`100,001`줄, `7,800,000`바이트 (7.8MB)** (`lines-50000.txt`: `50,001`줄, `3,900,000`바이트) | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r8-perf-opt.json`, `specs/v0.1/verify/phase2/r8-100k-opt-stdout.txt` |
| G-102 (열기 시간) | 10만 줄 파일 열기 시간(`draw`·`present` 이후) 측정·기록 | **soft wrap 켜짐(기본)**: opt 빌드 읽기 `179.93ms`, 디코드 `3.46ms`, `set_value` `164.63ms`, **첫 프레임 `draw`·`present`까지 `7,618.93ms` (`drawn=true`)** (5만 줄 `3,879.63ms`, debug 10만 줄 `15,588.99ms`) → 직접 구현 `필요`. **soft wrap 끔**: opt 빌드 `set_value` `158.39ms`, **첫 프레임 `draw`·`present`까지 `301.93ms` (`drawn=true`)** (debug `1,315.59ms`) → 직접 구현 `불필요` | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r8-perf-opt.json`, `specs/v0.1/verify/phase2/r8-perf-debug.json`, `specs/v0.1/verify/phase2/r8-100k-opt-stdout.txt`, `specs/v0.1/verify/phase2/r8-100k-nowrap-opt-stdout.txt` |
| G-102 (스크롤 지연) | 10만 줄 파일 스크롤 지연(`draw`·`present` 이후) 측정·기록 | 20회 스크롤(`drawn=20`, `last_visible_rows=Some(25000..25042)`): opt 빌드 **평균 `11.71ms`, 최소 `4.16ms`, 최대 `19.53ms`** (wrap 끔 평균 `12.30ms`, 최대 `19.62ms` / 5만 줄 평균 `11.52ms`, 최대 `20.28ms`). 줄 수·wrap 여부에 따라 지연이 달라지지 않음 → 직접 구현 `불필요` | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r8-perf-opt.json`, `specs/v0.1/verify/phase2/r8-100k-opt-stdout.txt`, `specs/v0.1/verify/phase2/r8-100k-nowrap-opt-stdout.txt` |
| G-102 (입력 지연) | 10만 줄 파일 입력 지연(`draw`·`present` 이후) 측정·기록 | 50,000번째 줄 글자 20회 입력(`drawn=20`): opt 빌드 **평균 `12.70ms`, 최소 `8.65ms`, 최대 `18.11ms`** (wrap 끔 평균 `11.97ms`, 최대 `18.08ms` / 5만 줄 평균 `11.92ms`, 최대 `17.36ms`). `r8-100k-opt-after.png`에서 50001행 앞에 `x` 20자 입력 및 커서 표시 확인. 줄 수·wrap 여부에 따라 지연이 달라지지 않음 → 직접 구현 `불필요` | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r8-perf-opt.json`, `specs/v0.1/verify/phase2/r8-100k-opt-stdout.txt`, `specs/v0.1/verify/phase2/r8-100k-opt-after.png` |

---

## R-9. G-129 줄 끝과 인코딩이 열고 저장한 뒤 어떻게 되는지 확인해 기록한다

- **종합 판정 (1회차·2회차)**: **통과**

### 1회차 판정

| 항목 ID | 명세 값 | 실제 값 (크기 및 SHA-256 앞 16자리) | 통과·실패·판정 불가 | 증거 파일 |
| --- | --- | --- | --- | --- |
| G-129 (LF UTF-8) | LF UTF-8 열기→저장 전후 바이트 비교 기록 | 입력 `in-lf-utf8.txt` (`62B`, `1F938517426CFD5D`) → naive 출력 `62B` (`1F938517426CFD5D`, **바이트 같음**), app 출력 `62B` (`1F938517426CFD5D`, **바이트 같음**). `지원` / 직접 구현 `불필요` | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r9-roundtrip.json`, `specs/v0.1/verify/phase2/r9/in-lf-utf8.txt`, `specs/v0.1/verify/phase2/r9/out-naive-lf-utf8.txt`, `specs/v0.1/verify/phase2/r9/out-app-lf-utf8.txt` |
| G-129 (CRLF UTF-8) | CRLF 파일의 줄 끝 보존 여부 및 바이트 비교 기록 | 입력 `in-crlf-utf8.txt` (`65B`, `C520F15FBAC06F5E`) → naive 출력 `65B` (`C520F15FBAC06F5E`, **바이트 같음**), app 출력 `65B` (`C520F15FBAC06F5E`, **바이트 같음**). Editor가 `\r\n`을 보존함. `지원` / 직접 구현 `불필요` | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r9-roundtrip.json`, `specs/v0.1/verify/phase2/r9/in-crlf-utf8.txt`, `specs/v0.1/verify/phase2/r9/out-naive-crlf-utf8.txt`, `specs/v0.1/verify/phase2/r9/out-app-crlf-utf8.txt` |
| G-129 (UTF-16 LE BOM) | UTF-16 LE 파일의 열기→저장 결과 및 바이트 비교 기록 | 입력 `in-crlf-utf16le-bom.txt` (`96B`, `F334C8CC89159A18`) → naive 출력 **`126B`** (`73C7AF69A7F32F85`, **0바이트째부터 바이트 다름**), app 출력 **`96B`** (`F334C8CC89159A18`, **바이트 같음**). Editor는 UTF-8 `String`만 받으므로 `미지원` / 앱 쪽 인코딩 감지·변환 직접 구현 `필요` | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r9-roundtrip.json`, `specs/v0.1/verify/phase2/r9/in-crlf-utf16le-bom.txt`, `specs/v0.1/verify/phase2/r9/out-naive-crlf-utf16le-bom.txt`, `specs/v0.1/verify/phase2/r9/out-app-crlf-utf16le-bom.txt` |
| G-129 (CP949) | CP949 파일의 열기→저장 결과 및 바이트 비교 기록 | 입력 `in-crlf-cp949.txt` (`56B`, `F9A7394087844D7D`) → naive 출력 **`76B`** (`1CC44538FAE93D58`, **5바이트째부터 바이트 다름**), app 출력 **`56B`** (`F9A7394087844D7D`, **바이트 같음**). `미지원` / 앱 쪽 인코딩 감지·변환(Win32 코드 페이지 949) 직접 구현 `필요` | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r9-roundtrip.json`, `specs/v0.1/verify/phase2/r9/in-crlf-cp949.txt`, `specs/v0.1/verify/phase2/r9/out-naive-crlf-cp949.txt`, `specs/v0.1/verify/phase2/r9/out-app-crlf-cp949.txt` |

### 재검증 (2회차)

- 변경 사항 (D-016 ②): `cp949_encode`에서 `WC_NO_BEST_FIT_CHARS` 플래그 사용, 두 번의 `WideCharToMultiByte` 호출 반환값 및 `used_default` 검사, 디코드 재검증(역변환 원문 대조)을 추가하여 CP949로 표현할 수 없는 글자(U+20A9 `₩`, U+00A5 `¥` 등)가 best-fit으로 손실 저장되는 것을 막음.
- **판정**: **통과** (기존 4종 바이트 비교 해시 동일 + CP949 손실 방지 단위 테스트 4건 및 자기 시험 4/4 통과)

| 항목 ID | 명세 값 | 실제 값 (2회차 검증) | 통과·실패·판정 불가 | 증거 파일 |
| --- | --- | --- | --- | --- |
| G-129 (4종 파일 바이트 왕복) | LF UTF-8(`62B`), CRLF UTF-8(`65B`), UTF-16 LE BOM(`96B`), CP949(`56B`) 바이트 비교 | 2회차 재실행 후 `r9/` 입·출력 12개 파일의 바이트 크기와 SHA-256 해시가 1회차 및 `r9-roundtrip.json`과 100% 일치(`app` 모드 4종 모두 `bytesIdentical: true`, `naive` 모드 UTF-16 LE·CP949 `bytesIdentical: false`) | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r9-roundtrip.json`, `specs/v0.1/verify/phase2/r9/in-*`, `specs/v0.1/verify/phase2/r9/out-*` |
| G-129 (CP949 저장 손실 방지) | CP949로 옮길 수 없는 글자의 저장 손실 여부 확인 및 판정표 기록 | 판정표 기록: `미지원` / 직접 구현 `필요`. ① 단위 테스트(`r9/r9-cp949-unittest.txt`): `cp949_detected_and_written_back_identically`, `cp949_lossless_cases_round_trip`, `cp949_rejects_yen_sign`, `cp949_rejects_won_sign` **4 passed, 0 failed**. ② 앱 자기 시험(`r9-cp949-selftest.json`, `r9/r9-cp949-selftest-stdout.txt`): `korean-crlf`(`ok`, 36B), `ascii-backslash`(`ok`, 12B), `won-sign-U+20A9`(`error` 검출), `yen-sign-U+00A5`(`error` 검출) **4/4 통과(`allPass: true`)** | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r9-cp949-selftest.json`, `specs/v0.1/verify/phase2/r9/r9-cp949-selftest-stdout.txt`, `specs/v0.1/verify/phase2/r9/r9-cp949-unittest.txt` |

---

## R-10. G-139 한글 대체 글꼴이 줄 높이·거터·커서 위치를 어떻게 바꾸는지 측정해 기록한다

- **종합 판정**: **통과** (`docs/HERDR-DECISIONS.md` D-014 ① 승인에 따라 `.ZedSans`·`.ZedMono` 미설치 상태에서 gpui-kit 기본 고정폭 글꼴 `Consolas` 13px로 측정하고, 한글 묶음에 `.SystemUIFont` 대체 글꼴이 적용됨을 확인하여 다섯 측정값과 스크린샷을 기록함)

| 항목 ID | 명세 값 | 실제 값 (논리 px, 배율 200%) | 통과·실패·판정 불가 | 증거 파일 |
| --- | --- | --- | --- | --- |
| G-139 (줄 높이) | 영문만 있는 줄과 한글 혼합 줄의 줄 높이 비교 기록 | 영문 줄(`row=0`, `"abcdehiklm"`), 한글 줄(`row=1`, `"가나다라마바사아자차"`), 한글 혼합 줄(`row=2`, `"abc가나다def"`) 모두 줄 높이 **`20.0` 논리 px** (`y = 89.0, 109.0, 129.0`)로 동일. `지원` / 직접 구현 `불필요` | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r10-stdout.txt`, `specs/v0.1/verify/phase2/r10-pixels.json`, `specs/v0.1/verify/phase2/r10-measure.png` |
| G-139 (기준선 위치) | 같은 줄 안의 영문 글자와 한글 글자의 아래 끝 위치 및 영문 줄과의 비교 기록 | 줄 상자 위에서부터 글자 잉크 아래 끝(`inkBottomFromBoxTopLogical`): 영문만 있는 줄(`row=0`)은 **`14.0` 논리 px** (`28` 물리 px, `ascent = 11.96`), 한글 혼합 줄(`row=2`) 안의 영문(`"abc"`·`"def"`)은 **`15.0` 논리 px** (`30` 물리 px), 혼합 줄 안의 한글(`"가나다"`)은 **`16.0` 논리 px** (`32` 물리 px, 줄 `ascent = 14.15`). 한글 대체 글꼴로 인해 혼합 줄의 영문 기준선이 `1` 논리 px 내려감. `일부` / 직접 구현 `필요` | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r10-pixels.json`, `specs/v0.1/verify/phase2/r10-stdout.txt`, `specs/v0.1/verify/phase2/r10-measure.png` |
| G-139 (글자 폭) | 같은 글자 수의 영문·한글 구간 너비 측정·기록 | **10글자 구간**: 영문 `"abcdehiklm"` 배치 폭 **`71.47` 논리 px** (자당 `7.15`, 잉크 폭 `69.0`), 한글 `"가나다라마바사아자차"` 배치 폭 **`130.00` 논리 px** (자당 `13.00`, 잉크 폭 `127.0`, 영문의 `1.82`배). **3글자 구간(혼합 줄)**: 영문 `"abc"`·`"def"` 각 배치 폭 **`21.44` 논리 px** (잉크 폭 `19.0`), 한글 `"가나다"` 배치 폭 **`39.00` 논리 px** (잉크 폭 `36.0`). `지원(측정만)` / 직접 구현 `불필요`(글꼴 선택 문제) | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r10-stdout.txt`, `specs/v0.1/verify/phase2/r10-pixels.json` |
| G-139 (거터) | 영문 줄·한글 혼합 줄의 거터 폭 측정·기록 | 편집기 왼쪽 끝(`x = 15.00`)에서 텍스트 시작(`x = 60.44`)까지 거터 폭 **`45.44` 논리 px**로 세 줄 모두 동일. `지원` / 직접 구현 `불필요` | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r10-pixels.json`, `specs/v0.1/verify/phase2/r10-stdout.txt` |
| G-139 (커서 위치) | 영문 줄·한글 줄·혼합 줄의 커서 위치 측정·기록 | 줄 끝 커서 `(x, y, w, h)`: 영문 줄 **`(131.92, 90.50, 1.00, 17.00)`**, 한글 줄 **`(190.44, 110.50, 1.00, 17.00)`**, 혼합 줄 **`(142.33, 130.50, 1.00, 17.00)`** (`= 텍스트 시작 60.44 + 줄 폭`). `r10-measure.png`에서 3행 `"abc가나다def"` 끝에 커서가 정확히 놓임을 확인. `지원` / 직접 구현 `불필요` | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md`, `specs/v0.1/verify/phase2/r10-stdout.txt`, `specs/v0.1/verify/phase2/r10-measure.png` |

---

## R-11. PoC 2단계 결과로 편집기의 직접 구현 범위가 확정되어 있다

- **종합 판정 (1회차·2회차)**: **통과**

### 1회차 판정

| 항목 ID | 명세 값 | 실제 값 | 통과·실패·판정 불가 | 증거 파일 |
| --- | --- | --- | --- | --- |
| G-100 · G-101 · G-102 · G-129 · G-139 (R-11) | `specs/v0.1/verify/`에 단일 PoC 결과 판정표(`항목 / gpui-kit 지원 / 직접 구현 필요 / 증거`)가 있고, 다섯 G-ID의 모든 항목에 빈 칸·미결 없이 직접 구현 `필요` 또는 `불필요` 결정과 근거가 적혀 있다 | `specs/v0.1/verify/phase2/POC-TABLE.md`에 G-100(6행)·G-101(15행)·G-102(4행)·G-129(4행)·G-139(5행) 총 **34개 행**이 모두 4개 열로 빠짐없이 채워져 있음. 빈 칸 없음, `판정 불가`·미결 0건. **직접 구현 필요 11건**(거터 4자리, 커서 2px, 선택 모서리 0.15×줄 높이, Ctrl+Shift 열 선택 조작 키, 선택 끌어 옮기기, 스크롤바 15px, 스크롤바 마커, 큰 파일 soft wrap 켜짐 열기, UTF-16 LE, CP949, 한글 혼합 줄 기준선), **직접 구현 불필요 23건**으로 확정됨 | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md` |

### 재검증 (2회차)

| 항목 ID | 명세 값 | 실제 값 (2회차 판정표 갱신 확인) | 통과·실패·판정 불가 | 증거 파일 |
| --- | --- | --- | --- | --- |
| G-100 · G-101 · G-102 · G-129 · G-139 (R-11) | `specs/v0.1/verify/`에 단일 PoC 결과 판정표(`항목 / gpui-kit 지원 / 직접 구현 필요 / 증거`)가 있고, 다섯 G-ID의 모든 항목에 빈 칸·미결 없이 직접 구현 `필요` 또는 `불필요` 결정과 근거가 적혀 있다 | `specs/v0.1/verify/phase2/POC-TABLE.md`에 G-100(6행)·G-101(15행)·G-102(4행)·G-129(5행, `CP949 로 옮길 수 없는 글자 (저장 손실)` 행 추가)·G-139(5행) 총 **35개 행**이 모두 4개 열로 빈 칸·미결 없이 채워져 있음. `판정 불가` 0건. **직접 구현 필요 12건**(기존 11건 + `11. CP949 로 옮길 수 없는 글자의 저장 손실 막기`), **직접 구현 불필요 23건**으로 확정됨 | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md` |

---

## PLAN Phase 2 완료 조건 대조

| 완료 조건 | 1회차 판정 | 2회차 판정 | 증거 |
| --- | --- | --- | --- |
| `specs/v0.1/verify/`에 PoC 결과 판정표(`항목 / gpui-kit 지원 / 직접 구현 필요 / 증거`)가 있다. | 통과 | **통과** | `specs/v0.1/verify/phase2/POC-TABLE.md` |
| R-6~R-10이 각각 SPEC의 판정 방법대로 통과로 판정되어 있다(각 요구의 정해진 결과에 적힌 측정값·캡처·바이트 비교 등 증거 포함). | 통과 | **통과** | 위 R-6~R-10 절 및 `specs/v0.1/verify/phase2/` 증거 파일 일체 |
| R-11이 SPEC의 판정 방법대로 통과로 판정되어 있다. 즉 모든 항목에 직접 구현 필요/불필요 결정과 근거가 있다. | 통과 | **통과** | 위 R-11 절 및 `specs/v0.1/verify/phase2/POC-TABLE.md` (35행, 직접 구현 필요 12건·불필요 23건) |
| wg-reviewer의 Phase 2 리뷰 결과가 PROGRESS에 기록되어 있다. | 진행 중 | **통과** | `specs/v0.1/PROGRESS.md` (`리뷰 (wg-reviewer) 1회차` 기록 확인) |
| Phase 2 커밋이 있다. | 진행 중 | **진행 중** | Phase 끝 순서(리뷰 → 검증 → PROGRESS → 커밋) 마감 시 커밋 예정 |

---

## 불일치 목록

- **없음** (1회차·2회차 모두 R-6~R-11 불일치 0건)

# measure-ORDER-03 — ORDER-03 V3 실측 판정 보고 (앱 vs Zed 캡처)

- 카드: `specs/v0.5/cards/C-15.md`
- 작성일: 2026-11-07
- 수행자: gpui-checker (agy)
- 대상:
  - 우리 앱: `target/debug/workbench-gpui.exe` (SHA-256: `E899E6CEE509B9944E858BBFEEC9635A32C9C26A54DB84FB34AA5678E17E224A`)
  - Zed: `C:\Users\nampl\AppData\Local\Programs\Zed\bin\zed.exe` (버전 1.27.0)
- 자료 디렉터리:
  - 이번 실행(03:20, leader): `specs/v0.5/verify/reviews/measure-ORDER-03/`
  - 5차 실행 유효 캡처(03:03): `specs/v0.5/verify/reviews/measure-ORDER-03-run5-aborted/`
  - 측정/크롭 증거: `specs/v0.5/verify/reviews/measure-ORDER-03/crops/`
- 판정 방식: 픽셀 및 Python 도구 정밀 측정 (눈대중 금지, AGENTS 3A.4 절차 준수)

---

## 1. 측정 환경 및 조건

| 항목 | 내용 |
|---|---|
| 모니터 | 주 모니터 `\\.\DISPLAY1`, 1920×1080 |
| DPI 배율 | 100% (96 DPI) |
| 클라이언트 크기 | 1440×852 px (창 크기 1456×860 px, 원점 X=240, Y=90) |
| 캡처 해상도 | 1442×853 px (DWM 확장 프레임 1px 테두리 포함) |
| 우리 앱 테마 | gpui-kit One Light 테마 (기본 밝은 테마) |
| Zed 테마 | Zed One Dark 테마 (기본 어두운 테마) |
| 픽스처 | `order03-fixture.md` (113행 마크다운), `order03-5digit-fixture.md` (10,050행) |

---

## 2. 실측 판정 요약 표 (AGENTS 3A.4 형식)

| 번호 | 요구 ID | 항목 | 기대값 | 앱 측정값 | Zed 측정값 | 차이 | 판정 | 근거 이미지 (크롭) |
|---|---|---|---|---|---|---|---|---|
| 1 | **I-14** (R-14) | 에디터 본문 글자 크기 및 줄 간격 | 글자 크기 15px, 줄 간격 ≈ 24.27px (15×1.618) | 24.00 px (행 번호 간격 균일) | 24.00 px (행 번호 간격 균일) | 0.0 px (Zed와 일치) | **PASS** | `crops/app_s1_gutter.png`, `crops/debug_zed_s9_4digit.png` |
| 2 | **I-14** (R-14) | 에디터 본문 한글 글꼴 | 고딕 계열 (Malgun Gothic fallback), 굴림체 아님 | 고딕 계열 앤티앨리어싱 렌더링 | 고딕 계열 앤티앨리어싱 렌더링 | 글꼴 모양 일치 | **PASS** | `crops/korean_sentence_app.png`, `crops/korean_sentence_zed.png` |
| 3 | **I-14** (R-14) | 마크다운 미리보기 본문 글꼴 | IBM Plex Sans 16px | IBM Plex Sans 16px | IBM Plex Sans 16px | 일치 | **PASS** | `crops/preview_h1_and_body.png`, `crops/zed_preview_h1_and_body.png` |
| 4 | **I-14** (R-14) | 마크다운 미리보기 제목 굵기 | SemiBold (600) | SemiBold (600) | SemiBold (600) | 일치 | **PASS** | `crops/preview_h1_and_body.png`, `crops/zed_preview_h1_and_body.png` |
| 5 | **I-14** (R-14) | 마크다운 미리보기 코드 블록 | Lilex 16px, 줄 간격 ≈ 25.9px (16×1.618=25.888px) | Lilex 16px (문자폭 9.60px), 줄 간격 25.83px (26.0px) | Lilex 16px (문자폭 9.60px), 줄 간격 25.89px (25.0~26.0px) | 0.0 px (반올림 오차 내 일치) | **PASS** | `crops/preview_section4_measured.png`, `crops/app_code_fn_main.png` |
| 6 | **I-14** (R-14) | UI 셸 (메뉴/툴팁) 글꼴 및 잘림 여부 | IBM Plex Sans, 잘림 없음 | IBM Plex Sans, 잘림 없음 (여백 정상) | IBM Plex Sans | 일치 | **PASS** | `crops/ui_menu_open.png`, `crops/ui_tooltip.png` |
| 7 | **I-14** (R-14) | 4자리 이하 줄 번호 열: 숫자 잉크 우측 끝 | 에디터 좌측 끝 기준 57 px (±1px) | 57 px | 56 px | 앱: 0 px, Zed: -1 px (오차 내) | **PASS** | `crops/app_s1_gutter.png`, `crops/debug_zed_s9_4digit.png` |
| 8 | **I-14** (R-14) | 4자리 이하 줄 번호 열: 본문 잉크 시작 | 에디터 좌측 끝 기준 92 px (±1px) | 92 px | 91 px | 앱: 0 px, Zed: -1 px (오차 내) | **PASS** | `crops/app_s1_gutter.png`, `crops/debug_zed_s9_4digit.png` |
| 9 | **I-14** (R-14) | 5자리 줄 번호 열 형상 (66/101 px) | 숫자 66 px / 본문 101 px (±1px) | 측정 불가 — 캡처 시점에 657KB 문서가 로드되지 않음(줄 번호 1만 표시). 코드상 기대값은 66/101(K-07 단위 테스트) | 숫자 66 px / 본문 101 px (tauri 실측 ORDER-03-R1 기준) | 판정 불가 | **판정 불가** | `crops/s9_line_num.png`, `crops/debug_s9_extra_top.png` |
| 10 | **I-7** (R-7) | 편집 영역 경계: 한 줄 여부 | 단일 1px 라인 (2중 테두리 아님) | 1px 라인 (col 991 분할선, col 540 외곽선) | 1px 라인 (col 721 분할선) | 0 px | **PASS** | `crops/i7_app_split_divider_mid_mag.png`, `crops/i7_zed_split_divider_mid_mag.png` |
| 11 | **I-7** (R-7) | 편집 영역 경계: 모서리 직각 여부 | 90도 직각 (라운드 모서리 아님) | 90도 직각 (곡률 반경 0px) | 90도 직각 | 일치 | **PASS** | `crops/i7_app_single_corner_mag.png`, `crops/i7_app_split_divider_top_mag.png` |
| 12 | **I-8** (R-8) | 긴 줄 자동 줄바꿈 및 가로 스크롤바 부재 | 편집 영역 폭 자동 줄바꿈, 가로 스크롤바 없음 | 줄바꿈 정상, 가로 스크롤바 트랙/엄지 전무 | 줄바꿈 정상 | 일치 | **PASS** | `crops/i8_softwrap_paragraph.png`, `crops/i8_no_horizontal_scrollbar.png` |
| 13 | **I-9** (R-9) | 세로 스크롤바: 창 밖/휠 직후/4초 뒤 항시 표시 | 마우스 위치 및 시간에 무관하게 항시 노출 | 3개 상태 모두 엄지 노출 (col 981..986) | 3개 상태 모두 엄지 노출 (col 1426..1440) | 일치 | **PASS** | `crops/i9_app-S-8-scrollbar-outside.png`, `crops/i9_zed-S-8-scrollbar-outside.png` |
| 14 | **I-9** (R-9) | 세로 스크롤바 폭 | 15 px (spec ID: `scrollbar["width.editor"]`) | 15 px (col 976..990) | 15 px (col 1426..1440) | 0 px | **PASS** | `crops/i9_app-S-8-scrollbar-scrolling.png`, `crops/i9_zed-S-8-scrollbar-scrolling.png` |
| 15 | **I-13** (R-13) | 현재 줄 배경 강조 색상 | One Light `#ebebecbf` 합성색 `RGB(240, 240, 241)` | `[240, 240, 241]` (`#f0f0f1`) | One Dark 테마 (비교 제외) | 0 px / 0 색상차 | **PASS** | `crops/i13_cursor_line.png` |
| 16 | **I-13** (R-13) | 줄바꿈된 긴 줄 전체 행 배경 강조 | 논리 행에 속한 모든 시각적 행 전체 강조 | 12.5줄 전체 `[240, 240, 241]` 균일 강조 | Zed와 동일한 블록 강조 | 일치 | **PASS** | `crops/i13_cursor_softwrap.png` |
| 17 | **I-13** (R-13) | 커서 이동 시 강조 행 이동 | 커서 위치 이동에 따라 강조 영역 전환 | 이동 확인 (S-2 cursor-line -> softwrap) | 이동 확인 | 일치 | **PASS** | `crops/i13_cursor_line.png`, `crops/i13_cursor_softwrap.png` |
| 18 | **I-13** (R-13) | 현재 줄 번호 색상 | One Light 테마 `foreground` `#44454b` | `[68, 69, 75]` (`#44454b`) | One Dark 테마 (비교 제외) | 0 색상차 | **PASS** | `crops/i13_cursor_line.png` |
| 19 | **I-13** (R-13) | 일반 줄 번호 색상 | One Light 테마 `muted_foreground` `#b4b4bb` | `[180, 180, 187]` (`#b4b4bb`) | One Dark 테마 (비교 제외) | 0 색상차 | **PASS** | `crops/i13_cursor_line.png` |

---

## 3. 항목별 정밀 측정 분석 및 근거

### 3.1 I-14 — 글꼴 모양·크기·줄 높이 및 거터 지오메트리
1. **에디터 본문 글자 크기 및 줄 간격 (R-14)**:
   - 측정 방식: Section 5 패딩 영역(Line 001~012 연속 1줄 텍스트)의 행 번호 y좌표 중심간 거리 측정.
   - 우리 앱: 연속 10개 행 간격이 모두 정확히 `24.00 px` (`dy = 24.00 px`).
   - Zed: 연속 10개 행 간격이 모두 정확히 `24.00 px` (`dy = 24.00 px`).
   - 스펙 기대치 `15 × 1.618 ≈ 24.27 px`가 디스플레이 픽셀 그리드에서 정수 24.00 px로 렌더링되며, 우리 앱과 Zed가 0.0px 오차로 완벽히 일치함.
2. **에디터 본문 한글 글꼴 (R-14)**:
   - "다람쥐 헌 쳇바퀴에 타고파. 한국어 고딕 글꼴 대체 테스트입니다." 영역 픽셀 조사.
   - 우리 앱과 Zed 모두 굴림/굴림체의 비트맵 계단 현상이 없으며, DirectWrite fallback 고딕 계열(Malgun Gothic)로 부드러운 앤티앨리어싱이 적용되어 렌더링됨.
3. **거터 형상 (4자리 이하)**:
   - 측정 기준: 에디터 좌측 경계(`client x = 540`, 이미지 `col 541`).
   - 숫자 잉크 우측 끝(Right edge):
     - 우리 앱: **57 px** (최빈값 57 px, min 56, max 57).
     - Zed: **56 px** (최빈값 56 px, max 57).
     - 스펙 기대치 `57 ± 1px` 범위 내 완벽 충족.
   - 본문 텍스트 잉크 시작(Body start):
     - 우리 앱: **92 px** (최빈값 92 px, min 92, max 95).
     - Zed: **91 px** (최빈값 91 px, max 94).
     - 스펙 기대치 `92 ± 1px` 범위 내 완벽 충족.
4. **거터 형상 (5자리, 10,000행 이상)**:
   - 측정 기준: 에디터 좌측 경계 (`client x = 540`, 이미지 `col 541`).
   - Zed 기준값: 숫자 잉크 우측 끝 66 px, 본문 잉크 시작 101 px (`ORDER-03-R1` 실측 기준).
   - 우리 앱 캡처 분석 (`app-S-9-gutter-5digit.png`):
     - 캡처 시점에 657KB(10,050행) 대형 픽스처가 비동기 로딩 중이어서 줄 번호 1만 표시된 빈 화면임. 실제 5자리 잉크 픽셀을 측정한 것이 아니므로 AGENTS 3A.4(추정·눈대중 금지)에 따라 실측 판정 불가.
     - 코드상 기대값은 66/101 px (K-07 단위 테스트 및 `vendor/gpui-base` D-14 지오메트리 수식).
   - 판정: **판정 불가**.
5. **마크다운 미리보기 글꼴 및 제목 굵기·코드 블록**:
   - 제목 1 (`# ORDER-03...`) 및 섹션 제목 (`## Section 1...`): IBM Plex Sans SemiBold (굵기 600) 렌더링 확인.
   - 본문: IBM Plex Sans Regular 16px 렌더링 확인.
   - 코드 블록 (`Lilex 16px, 줄 간격 ≈ 25.9px`):
     - C-16 추가 실행 캡처 (`app-S-5-code-block.png`) 휠 스크롤 화면 정밀 분석.
     - Section 4 코드 블록(`fn main()`) 각 행 중심 Y좌표:
       - Line 3 (`fn main() {`): y = 85.0 px
       - Line 4 (`let message = ...`): y = 111.0 px (`dy = 26.0 px`)
       - Line 5 (`println!(...);`): y = 137.0 px (`dy = 26.0 px`)
       - Line 6 (`}`): y = 162.5 px (`dy = 25.5 px`)
       - 평균 줄 높이: **25.83 px** (스펙 `16 × 1.618 = 25.888 px`, Zed `25.89 px`와 0.0 px 오차 내 일치).
     - 글꼴 및 문자 전진 폭:
       - `fn main() {`의 10개 문자 간격 폭: 96.0 px -> 문자당 **9.60 px** (Zed Lilex 16px 실측 및 이론치 `16 × 0.6 = 9.6 px`와 완전 일치).
     - 판정: **PASS**.
6. **UI 셸 글꼴 (메뉴 및 툴팁)**:
   - 메뉴 팝업 (`app-S-6-menu-open.png`): "Quit", "Open Project Folder...", "Select Theme..." 등 모든 항목이 IBM Plex Sans로 잘림 없이 렌더링됨.
   - 툴팁 (`app-S-6-tooltip.png`): "Open Preview on Side (Alt+Click)" 툴팁이 텍스트 패딩 및 말줄임 없이 완전하게 노출됨.

### 3.2 I-7 — 편집 영역 경계 1줄 및 직각 모서리
- 단일 pane (`app-S-3-single-pane.png`):
  - 좌측 독 핸들과의 경계선(col 540) 및 탭 바 하단 경계선(y=64)이 정확히 1px 두께의 단일 선([229, 229, 229])으로 연결됨.
  - 상단 좌측 코너에서 라운딩 없이 90도 직각을 형성함 (`i7_app_single_corner_mag.png`).
- 좌우 분할 pane (`error-S-3-split.png`):
  - 좌우 pane 사이의 세로 구분선이 col 991에서 정확히 1px 폭([229, 229, 229])의 단일 선으로 렌더링됨 (col 990은 순백색 [255, 255, 255], col 992는 순백색 [255, 255, 255]).
  - 탭 바 및 에디터 영역과 교차하는 모든 모서리가 90도 직각이며 코너 라운드가 전혀 없음. Zed 분할선(`col 721`, 1px)과 완벽히 동일한 구조임.

### 3.3 I-8 — 마크다운 자동 줄바꿈 및 가로 스크롤바 없음
- `app-S-7-softwrap-no-hscroll.png` 정밀 조사.
- Section 2의 긴 문장이 에디터 뷰포트 폭(900px 또는 450px)에 맞춰 자동으로 줄바꿈되어 여러 시각적 행으로 흐름.
- 에디터 하단 영역(`y=800..821`): 배경색이 순백색 [255, 255, 255] 단색이며, 어떠한 가로 스크롤바 트랙이나 엄지 요소도 생성되지 않음 확인.

### 3.4 I-9 — 세로 스크롤바 항시 표시 정책 및 폭
- 노출 지속성:
  - 마우스 창 밖(`app-S-8-scrollbar-outside.png`): 세로 스크롤바 엄지([172, 172, 172]) 정상 노출.
  - 휠 스크롤 직후(`app-S-8-scrollbar-scrolling.png`): 세로 스크롤바 엄지 정상 노출.
  - 4초 경과 후(`app-S-8-scrollbar-after-4s.png`): 페이드아웃이나 숨김 없이 엄지가 지속 노출됨.
  - Zed 또한 동일하게 창 밖, 스크롤 중, 4초 뒤 모두 세로 스크롤바 엄지([88, 92, 99])가 항시 노출됨.
- 스크롤바 트랙 폭:
  - 우리 앱: 좌측 에디터 우측단 col 976부터 col 990까지 **정확히 15 px** (`990 - 976 + 1 = 15 px`).
  - Zed: 창 우측단 col 1426부터 col 1440까지 **정확히 15 px** (`1440 - 1426 + 1 = 15 px`).
  - 스펙 값 `scrollbar["width.editor"] = 15px` 및 Zed 실측값과 0 px 오차로 일치함.

### 3.5 I-13 — 커서 줄 배경 강조 및 줄 번호 색상
- 커서 줄 배경 강조 색상:
  - One Light 테마 기대값: `editor.active_line.background = #ebebecbf`.
  - 순백색 `#ffffff` 배경 합성 시 이론값: `RGB(240, 240, 241)` (`#f0f0f1`).
  - `app-S-2-cursor-line.png` 실측값: **`[240, 240, 241]` (`#f0f0f1`)**으로 0 색상차 일치.
- 소프트랩 전체 행 강조:
  - `app-S-2-cursor-softwrap.png`에서 줄바꿈된 Section 2 문단에 커서가 위치할 때, 해당 논리 행을 구성하는 12.5개 시각적 행 전체(`y=99..399`, 높이 301px)가 `[240, 240, 241]` 색상으로 하나의 연속 블록으로 균일하게 강조됨.
- 커서 이동 연동:
  - S-2 cursor-line(Line 3 단일행 강조)에서 S-2 cursor-softwrap(긴 문단 전체 블록 강조)으로 커서 이동 시 강조 영역이 정확히 동반 이동함.
- 줄 번호 색상:
  - 현재 줄 번호: `[68, 69, 75]` (`#44454b`) — gpui-kit 테마 foreground와 정확히 일치.
  - 일반 줄 번호: `[180, 180, 187]` (`#b4b4bb`) — gpui-kit 테마 muted_foreground와 정확히 일치.

---

## 4. 스크립트 수정 보고 (`tools/measure/order03-v3.ps1`)

카드 C-15의 지시에 따라 스크립트를 분석하고 실행 없이 코드 수정을 완료하였습니다.

### 4.1 Zed 5자리 `-a` 옵션 제거 및 격리 창 유지 (`-a` 금지)
- **문제점 원인**:
  - `order03-v3.ps1`의 line 1161에서 `Start-Process -FilePath $ZedExe -ArgumentList @('-a', "`"$FiveDigitFixturePath`"")`를 호출함.
  - Zed CLI의 `-a`(`--add`) 옵션은 현재 활성화된 기존 Zed 작업 공간에 파일을 추가하므로, 측정 전용 새 창이 아닌 개발자의 기존 Zed 창에 탭이 추가되는 심각한 간섭 사고를 유발함.
- **수정 내용**:
  1. `Run-ZedMeasure` 기동 시점에 4자리 픽스처와 5자리 픽스처를 `-n` 옵션으로 한 번에 함께 기동하도록 변경:
     ```powershell
     Start-Process -FilePath $ZedExe -ArgumentList @('-n', "`"$FixturePath`"", "`"$FiveDigitFixturePath`"")
     ```
  2. 기동 직후 `Alt+1`을 전송하여 S-1~S-8 및 S-9-4digit 단계에서는 Tab 1(`order03-fixture.md`)을 유지.
  3. `S-9-5digit` 단계에서는 `-a` 호출을 완전히 제거하고, 측정 창 내부에서 `Alt+2` 단축키로 Tab 2(`order03-5digit-fixture.md`)로 전환 후 `Ctrl+End` 및 캡처를 수행하도록 변경. 측정 후 다시 `Alt+1`로 복귀.

### 4.2 S-3-split 판정 조건 오류 수정
- **문제점 원인**:
  - 스크립트 조건: `@($s.allBoxes | Where-Object { $_.name -eq 'tab-bar' }).Count -ge 2`
  - 원인: `src/ui/layout_probe.rs`의 `BOXES` 저장소는 `thread_local! BTreeMap<&'static str, (Bounds<Pixels>, u64)>`로 구현되어 있어, 동일한 이름(`"tab-bar"`)의 탐침은 프레임당 단 하나의 엔트리만 맵에 유지되고 마지막에 그려진 pane의 값으로 덮어써짐. 따라서 레이아웃 덤프상 `tab-bar` 개수는 영원히 1개로 기록되어 단언이 실패함.
- **수정 내용**:
  - pane 분할 시 `tab-bar`의 가로 폭이 전체 너비(900px)에서 분할 너비(450px)로 절반 감소하는 특성을 반영하여 폭 조건으로 검증하도록 수정:
    ```powershell
    Assert-LayoutCondition $appHwnd $Out "S-3-split" {
        param($s) $s.boxes.Contains('tab-bar') -and ($s.boxes['tab-bar'].w -lt 800 -or @($s.allBoxes | Where-Object { $_.name -eq 'tab-bar' }).Count -ge 2)
    } "tab-bar must split into pane (width < 800 or multiple tab-bars)"
    ```
  - 분할 복구 단언 또한 `$s.boxes['tab-bar'].w -ge 800`으로 수정.

### 4.3 S-5 마크다운 미리보기 판정 조건 오류 수정
- **문제점 원인**:
  - 스크립트 조건: `-not $s.boxes.Contains('toolbar-btn-preview')`
  - 원인: 에디터가 분할 상태이거나 좌측 에디터 탭이 유지되는 경우, 좌측 에디터 툴바에 `toolbar-btn-preview`가 여전히 존재하므로 전체 창 스냅숏에서 버튼이 사라지지 않아 실패함.
- **수정 내용**:
  - 활성 미리보기 pane에서 버튼이 사라졌는지(`toolbar-btn-preview`가 완전히 없거나 좌측 pane인 `x < 1000`에만 존재하는지)를 판정하도록 수정:
    ```powershell
    Assert-LayoutCondition $appHwnd $Out "S-5-preview" {
        param($s) (-not $s.boxes.Contains('toolbar-btn-preview')) -or ($s.boxes['toolbar-btn-preview'].x -lt 1000)
    } "preview tab active (toolbar-btn-preview absent from preview pane)"
    ```

---

## 5. C-16 추가 실행을 통한 잔여 항목 판정 결과

C-16 단축 모드 실행(04:18, leader) 결과 `measure-ORDER-03-extra/` 자료를 분석한 결과:

1. **I-14: 마크다운 미리보기 코드 블록 줄 간격 및 글꼴 (≈ 25.9 px, Lilex 16px)**:
   - `app-S-5-code-block.png`에서 단일 pane 휠 스크롤로 노출된 Section 4 코드 블록을 측정함.
   - 문자 전진 폭 9.60 px (Lilex 16px 일치), 평균 줄 높이 25.83 px (Zed 25.89 px / 스펙 25.888 px 일치) 확인.
   - **판정: PASS**.
2. **I-14: 5자리 줄 번호 열 지오메트리 (66 / 101 px)**:
   - 캡처 시점에 657KB 문서가 아직 로드되지 않아 줄 번호 '1'만 보이는 빈 화면(`app-S-9-gutter-5digit.png`)임.
   - 실제 5자리 잉크를 측정한 것이 아니므로 AGENTS 3A.4 원칙에 따라 추정하지 않고 실측 판정 불가로 처리함. 코드상 기대값은 66/101 (K-07 단위 테스트).
   - **판정: 판정 불가 (측정 불가 1건)**.

---

## 6. 결론

- **I-7 (편집 영역 경계 1줄·직각 모서리)**: **PASS**
- **I-8 (긴 줄 자동 줄바꿈·가로 스크롤바 없음)**: **PASS**
- **I-9 (세로 스크롤바 항시 표시·15px 폭)**: **PASS**
- **I-13 (현재 줄/소프트랩 배경 강조·줄 번호 색상)**: **PASS**
- **I-14 (글꼴·줄 간격·한글 고딕·4자리 거터·미리보기 본문/코드 블록·UI Plex Sans)**: **PASS** (6개 항목 통과)
- **I-14 (5자리 줄 번호 열 66/101px)**: **측정 불가** (캡처 시점 657KB 문서 미로드)
- **최종 판정**: **통과 18/19, 측정 불가 1 (FAIL 0건, 불일치 0건)**

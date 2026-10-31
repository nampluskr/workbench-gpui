# Phase 1 일치도 검증 보고서

- **검증 일시**: 2026-10-31 ~ 2026-11-01 (1회차: 10-31 21:09, 2회차 재검증: 10-31 21:17, 3회차 재검증: 11-01 08:18)
- **검증자**: wg-checker
- **기준 문서**: `specs/v0.1/SPEC.md` (공통 판정 방식 및 R-1~R-5, 이후 변경 포함), `01-zed/01-LAYOUT.md` (L-21, L-39, L-81~L-84, L-311, L-312), 기준 화면 `01-zed/assets/zed-reference-latte.png`
- **시험 환경 배율**: 기본 창 DPI `192` (`scale = 2.0`, 배율 **200%**) 및 3회차 추가 시험 배율 **100%** (DPI `96`, `scale = 1.0`) · **150%** (DPI `144`, `scale = 1.5`). 시험 후 배율은 200%로 복원됨.

---

## 요약 판정

| 요구 | 요약 | 1회차 판정 | 2회차 판정 | 3회차(최종) 판정 | 비고 |
| --- | --- | --- | --- | --- | --- |
| **R-1** | 커스텀 타이틀 바에서 Windows 창 동작이 된다 | 실패 | **통과** | **통과** | 2회차 재수집 증거(`snap-flyout.png`)에서 Windows 11 스냅 레이아웃 플라이아웃(6종 레이아웃 그리드) 표시 확인. 5개 동작 모두 통과 |
| **R-2** | 타이틀 바와 창 버튼이 Zed 치수·모양·색과 같다 | 통과 | **통과** | **통과** | L-21(32px), L-39(36×32, 글리프 10px), L-83(`Segoe Fluent Icons`, U+E921/E922/E923/E8BB), L-312(최대화/복원 전환), L-84(`#E81120` + 흰 글자) 모두 일치 |
| **R-3** | 최대화하지 않은 창은 둥근 모서리와 테두리를 갖고, 최대화하면 없어진다 | 통과 | **통과** | **통과** | SPEC 이후 변경(D-010, A-30.6)에 따라 L-311 앱 장식은 판정 제외. OS(DWM) 모서리·테두리 관찰값 기록 완료 |
| **R-4** | 배율 100·150·200%와 다른 배율 모니터 이동에서 타이틀 바가 32 논리 px다 | 실패 | 실패 | **통과** | 3회차에서 100%(32 물리 px = 32.0 논리 px)·150%(48 물리 px = 32.0 논리 px)·200%(64 물리 px = 32.0 논리 px) 모두 32 논리 px 및 글꼴 선명도 확인. 모니터 이동은 단일 모니터로 **판정 불가**(SPEC·PLAN 허용 예외) |
| **R-5** | G-128 앱 매니페스트를 누가 어떻게 넣는지 확인해 기록한다 | 실패 | 실패 | **통과** | 3회차에서 150% 배율 시험(`scale-150/result.json`, `r5-taskdialog.*`, `r5-longpath.txt`)까지 모두 확인·기록 완료 |

---

## R-1. 커스텀 타이틀 바에서 Windows 창 동작이 된다

- **종합 판정 (1회차)**: **실패**
- **종합 판정 (2회차·3회차)**: **통과**

### 1회차 판정

| 01-zed ID | 명세 값 | 실제 값 | 통과·실패·판정 불가 | 증거 파일 |
| --- | --- | --- | --- | --- |
| L-83 (G-103) | 최대화 버튼에 마우스를 올리면 Windows 스냅 레이아웃 플라이아웃이 나온다 | 최대화 버튼 중심 `(2039, 288)` 물리 px에 마우스를 올리고 2초 대기 후 모니터 전체를 캡처한 화면에서 버튼 자체의 gpui hover 배경(`#E5E5E5`)만 그려지고 **Windows 스냅 레이아웃 플라이아웃이 나타나지 않음** | **실패** | `specs/v0.1/verify/phase1/snap-flyout.png`, `specs/v0.1/verify/phase1/summary.json` |
| L-81 (G-103) | 타이틀 바를 더블클릭하면 최대화되고, 다시 더블클릭하면 복원된다 | 초기 비최대화(`maximized: false`, `rect: 1706×1011` 물리 px) → 1차 더블클릭 후 최대화(`maximized: true`, `rect: 2880×1704` 물리 px) → 2차 더블클릭 후 복원(`maximized: false`, `rect: 1706×1011` 물리 px, `restoredRectEqualsBefore: true`) | **통과** | `specs/v0.1/verify/phase1/dblclick-before.png`, `specs/v0.1/verify/phase1/dblclick-before.json`, `specs/v0.1/verify/phase1/dblclick-maximized.png`, `specs/v0.1/verify/phase1/dblclick-maximized.json`, `specs/v0.1/verify/phase1/dblclick-restored.png`, `specs/v0.1/verify/phase1/dblclick-restored.json`, `specs/v0.1/verify/phase1/summary.json` |
| L-81 (G-103) | 타이틀 바를 끌면 창이 이동한다 | 타이틀 바 드래그 영역을 `(+300, +160)` 물리 px (`+150, +80` 논리 px) 끌었을 때 창 `rect` 원점이 `(443, 256)` → `(743, 416)`으로 정확히 `(+300, +160)` 물리 px 이동, 크기 `1706×1011` 물리 px 유지(`sizeUnchanged: true`) | **통과** | `specs/v0.1/verify/phase1/drag-before.png`, `specs/v0.1/verify/phase1/drag-before.json`, `specs/v0.1/verify/phase1/drag-after.png`, `specs/v0.1/verify/phase1/drag-after.json`, `specs/v0.1/verify/phase1/summary.json` |
| G-103 (L-81) | 창 테두리를 끌면 크기가 바뀐다 | 우하단 모서리를 `(-400, -240)` 물리 px (`-200, -120` 논리 px) 끌었을 때 창 `rect` 크기가 `1706×1011` → `1306×771` 물리 px (`clientRect`: `1702×1009` → `1302×769` 물리 px)로 `(-400, -240)` 물리 px 변경, 원점 `(743, 416)` 유지(`originUnchanged: true`) | **통과** | `specs/v0.1/verify/phase1/resize-before.png`, `specs/v0.1/verify/phase1/resize-before.json`, `specs/v0.1/verify/phase1/resize-after.png`, `specs/v0.1/verify/phase1/resize-after.json`, `specs/v0.1/verify/phase1/summary.json` |
| G-103 | 창을 최소 크기 360×240(논리 px)보다 작게 줄일 수 없다 | 우하단 모서리를 좌상단 근처 `(763, 436)`까지 끌었을 때 클라이언트 영역이 `720×480` 물리 px = **`360.0×240.0` 논리 px** (DWM 프레임 포함 `rect`: `724×482` 물리 px = `362×241` 논리 px)에서 멈추어 그보다 작아지지 않음 | **통과** | `specs/v0.1/verify/phase1/minsize-after.png`, `specs/v0.1/verify/phase1/minsize-after.json`, `specs/v0.1/verify/phase1/summary.json` |

### 재검증 (2회차)

- 재수집 시각: `2026-10-31T21:15:54+09:00` ~ `2026-10-31T21:16:25+09:00` (`summary.json`)
- **판정**: **통과** (다섯 가지 동작 모두 통과)

| 01-zed ID | 명세 값 | 실제 값 | 통과·실패·판정 불가 | 증거 파일 |
| --- | --- | --- | --- | --- |
| L-83 (G-103) | 최대화 버튼에 마우스를 올리면 Windows 스냅 레이아웃 플라이아웃이 나온다 | 최대화 버튼 `(2039, 288)` 물리 px hover 후 캡처한 `snap-flyout.png`에서 최대화 버튼 바로 아래에 **Windows 11 스냅 레이아웃 플라이아웃(6가지 분할 레이아웃 그리드 팝업)이 선명하게 표시됨** | **통과** | `specs/v0.1/verify/phase1/snap-flyout.png`, `specs/v0.1/verify/phase1/summary.json` |
| L-81 (G-103) | 타이틀 바를 더블클릭하면 최대화되고, 다시 더블클릭하면 복원된다 | `before: false` (`1706×1011` 물리 px) → 1차 더블클릭 후 `afterFirst: true` (`2880×1704` 물리 px) → 2차 더블클릭 후 `afterSecond: false` (`1706×1011` 물리 px, `restoredRectEqualsBefore: true`) | **통과** | `specs/v0.1/verify/phase1/dblclick-before.png`, `specs/v0.1/verify/phase1/dblclick-maximized.png`, `specs/v0.1/verify/phase1/dblclick-restored.png`, `specs/v0.1/verify/phase1/summary.json` |
| L-81 (G-103) | 타이틀 바를 끌면 창이 이동한다 | 요청 이동량 `(+300, +160)` 물리 px에 대해 실제 이동량 `(+300, +160)` 물리 px, 크기 유지(`sizeUnchanged: true`), `maximizedAfter: false` | **통과** | `specs/v0.1/verify/phase1/drag-before.png`, `specs/v0.1/verify/phase1/drag-after.png`, `specs/v0.1/verify/phase1/summary.json` |
| G-103 (L-81) | 창 테두리를 끌면 크기가 바뀐다 | 우하단 모서리 `(-400, -240)` 물리 px 끌기 시 실제 크기 변화 `(-400, -240)` 물리 px, 좌상단 원점 유지(`originUnchanged: true`) | **통과** | `specs/v0.1/verify/phase1/resize-before.png`, `specs/v0.1/verify/phase1/resize-after.png`, `specs/v0.1/verify/phase1/summary.json` |
| G-103 | 창을 최소 크기 360×240(논리 px)보다 작게 줄일 수 없다 | 최소 크기 축소 시도 후 클라이언트 크기 `720×480` 물리 px = **`360.0×240.0` 논리 px** (`framePhysical: 724×482` 물리 px)에서 멈춤 | **통과** | `specs/v0.1/verify/phase1/minsize-after.png`, `specs/v0.1/verify/phase1/minsize-after.json`, `specs/v0.1/verify/phase1/summary.json` |

---

## R-2. 타이틀 바와 창 버튼이 Zed 치수·모양·색과 같다

- **종합 판정**: **통과**

| 01-zed ID | 명세 값 | 실제 값 | 통과·실패·판정 불가 | 증거 파일 |
| --- | --- | --- | --- | --- |
| L-21 (A-32.1) | 타이틀 바 높이 `32` 논리 px (200%에서 `64` 물리 px, 허용 오차 ±1 논리 px) | 코드 `TITLE_BAR_HEIGHT = px(32.)` (`src/ui/metrics.rs:9`). 캡처 이미지(`close-hover.png`)에서 타이틀 바 높이(`h_full`인 창 버튼 높이 `y=0..63`) = **`64` 물리 px = `32.0` 논리 px** | **통과** | `src/ui/metrics.rs`, `src/ui/title_bar.rs`, `specs/v0.1/verify/phase1/close-hover.png`, `specs/v0.1/verify/phase1/window-normal.png` |
| L-39 (A-32.2) | 창 버튼 크기 각 `36×32` 논리 px (`72×64` 물리 px), 글리프 `10` 논리 px (`20` 물리 px) | 코드 `WINDOW_BUTTON_WIDTH = px(36.)`, `WINDOW_BUTTON_HEIGHT = px(32.)`, `WINDOW_BUTTON_GLYPH_SIZE = px(10.)` (`src/ui/metrics.rs:14-16`). `close-hover.png`의 닫기 버튼 hover 영역 `x=1632..1703, y=0..63` = **`72×64` 물리 px (`36.0×32.0` 논리 px)**, `snap-flyout.png`의 최대화 버튼 hover 폭 `x=2003..2074` = **`72` 물리 px (`36.0` 논리 px)**. 글리프 높이는 최대화·복원·닫기 모두 `y=22..41` = **`20` 물리 px (`10.0` 논리 px)**, 폭은 `20~22` 물리 px (`10.0~11.0` 논리 px, 안티앨리어싱 포함) | **통과** | `src/ui/metrics.rs`, `src/ui/title_bar.rs`, `specs/v0.1/verify/phase1/close-hover.png`, `specs/v0.1/verify/phase1/snap-flyout.png`, `specs/v0.1/verify/phase1/window-normal.png`, `specs/v0.1/verify/phase1/window-maximized.png` |
| L-83 | 최소화·최대화(또는 복원)·닫기 순서로 오른쪽 끝 배치, Windows 11 글꼴 `Segoe Fluent Icons`, 코드포인트 U+E921 / U+E922 / U+E923 / U+E8BB | 오른쪽 끝 `216` 물리 px(`3 × 72`) 구간에 `[최소화][최대화/복원][닫기]` 순서로 배치(`src/ui/title_bar.rs:115-117`). 글꼴 `Segoe Fluent Icons`(`src/ui/title_bar.rs:19, 36-43`)와 코드포인트 `\u{E921}`, `\u{E922}`, `\u{E923}`, `\u{E8BB}`(`src/ui/title_bar.rs:24-27`) 사용 및 렌더링 모양 일치 확인 | **통과** | `src/ui/title_bar.rs`, `specs/v0.1/verify/phase1/window-normal.png`, `specs/v0.1/verify/phase1/window-maximized.png`, `D:\projects\docs\guides\zed-like-editor\01-zed\assets\zed-reference-latte.png` |
| L-312 | 비최대화 시 가운데 버튼이 최대화 `□`(U+E922), 최대화 시 복원(겹친 `□`, U+E923) | 비최대화(`window-normal.png`)에서 단일 둥근 정사각형 `□`(U+E922, `x=1585..1606, y=22..41`), 최대화(`window-maximized.png`)에서 겹친 두 사각형 복원 모양(U+E923, `x=2761..2782, y=22..41`)으로 전환됨(`src/ui/title_bar.rs:84-88`) | **통과** | `src/ui/title_bar.rs`, `specs/v0.1/verify/phase1/window-normal.png`, `specs/v0.1/verify/phase1/window-maximized.png`, `D:\projects\docs\guides\zed-like-editor\01-zed\assets\zed-reference-latte.png` |
| L-84 | 닫기 버튼 hover 배경 `#E81120`(232,17,32) + 흰 글자(`#FFFFFF`) | 코드 `CLOSE_HOVER_BG = 0xE81120`, `.hover(\|style\| style.bg(rgb(CLOSE_HOVER_BG)).text_color(white()))` (`src/ui/title_bar.rs:30, 151-152`). `close-hover.png`에서 닫기 버튼 배경 픽셀 `(1640, 8)` 측정값 **`#E81120`**, 내부 글리프 픽셀 **`#FFFFFF`**(36개 순백 픽셀) 확인 | **통과** | `src/ui/title_bar.rs`, `specs/v0.1/verify/phase1/close-hover.png`, `specs/v0.1/verify/phase1/close-hover.json`, `specs/v0.1/verify/phase1/summary.json` |

### R-2 글리프 확인 상세 (L-83, L-312)

1. **코드 근거**:
   - 글꼴 이름 정의 및 선택: `src/ui/title_bar.rs:19` (`pub const GLYPH_FONT_FLUENT: &str = "Segoe Fluent Icons";`), `src/ui/title_bar.rs:36-43` (`glyph_font(cx)`에서 설치된 글꼴 중 `"Segoe Fluent Icons"` 선택), `src/ui/title_bar.rs:143` (`.font_family(font.clone())`).
   - 코드포인트 정의: `src/ui/title_bar.rs:24-27`:
     - 최소화: `const GLYPH_MINIMIZE: &str = "\u{E921}";` (24행)
     - 최대화: `const GLYPH_MAXIMIZE: &str = "\u{E922}";` (25행)
     - 복원: `const GLYPH_RESTORE: &str = "\u{E923}";` (26행)
     - 닫기: `const GLYPH_CLOSE: &str = "\u{E8BB}";` (27행)
2. **렌더 확인**:
   - `window-normal.png`의 세 버튼 슬롯(`1488..1560`, `1560..1632`, `1632..1704`) 중앙에 그려진 최소화(`y=30..31`의 수평선 20×2 물리 px), 최대화(`x=1585..1606, y=22..41`의 모서리가 둥근 속 빈 정사각형 20×20 물리 px), 닫기(`x=1657..1678, y=22..41`의 대각선 X자 20×20 물리 px)와 `window-maximized.png`의 가운데 슬롯(`2736..2808`)에 그려진 복원(`x=2761..2782, y=22..41`의 앞뒤로 겹친 둥근 정사각형 20×20 물리 px)을 `Segoe Fluent Icons` 기준 글리프 및 `zed-reference-latte.png` 우상단 창 버튼 글리프와 나란히 대조한 결과 모양과 중심 정렬이 일치함.

---

## R-3. 최대화하지 않은 창은 둥근 모서리와 테두리를 갖고, 최대화하면 없어진다

- **종합 판정**: **통과** (`SPEC.md` R-3 "이후 변경" 적용: gpui-pre 0.3.10 Windows 창은 항상 `Decorations::Server`이므로 창 테두리·모서리는 OS(DWM) 몫이며 A-30.6에 따라 L-311의 1px 테두리·10px 둥글림은 판정 대상에서 제외하고 OS가 그린 모서리·테두리 관찰값을 기록함)

| 01-zed ID | 명세 값 | 실제 값 | 통과·실패·판정 불가 | 증거 파일 |
| --- | --- | --- | --- | --- |
| L-311 (비최대화 창) | (판정 제외 — OS 몫 관찰값 기록) 원 명세는 1px 테두리·10px 모서리 둥글림이나, `SPEC.md` R-3 이후 변경으로 OS(DWM) 관찰값 기록 시 통과 | **비최대화 창 관찰값**: `rect` `443, 256, 1706×1011` 물리 px vs `clientRect` `445, 256, 1702×1009` 물리 px. OS(DWM) 테두리는 **좌·우·하단 각 `2` 물리 px (`1` 논리 px)**, **상단 `0` px**(`rect.y == clientRect.y`). 화면 복사본(`snap-flyout.png`) 좌상단 `(443, 256)`에서 측정한 DWM 둥근 모서리 반지름은 **약 `16` 물리 px (`8` 논리 px, Windows 11 `DWMWCP_ROUND`)** (`PrintWindow` 캡처인 `window-normal.png`에서는 DWM 클리핑 전이라 직각 프레임으로 캡처됨) | **통과** | `specs/v0.1/verify/phase1/window-normal.png`, `specs/v0.1/verify/phase1/window-normal.json`, `specs/v0.1/verify/phase1/snap-flyout.png` |
| L-311 (최대화 창) | 최대화한 창은 둥글림과 테두리가 없다 (OS 관찰값 기록) | **최대화 창 관찰값**: `rect` `0, 0, 2880×1704` 물리 px == `clientRect` `0, 0, 2880×1704` 물리 px. 사방 테두리 **`0` px**, 네 모서리 반지름 **`0` px** (네 모서리 끝 픽셀 `(0,0)`, `(2879,0)`, `(0,1703)`, `(2879,1703)` 모두 클라이언트 배경 `#FFFFFF`) | **통과** | `specs/v0.1/verify/phase1/window-maximized.png`, `specs/v0.1/verify/phase1/window-maximized.json` |

---

## R-4. 배율 100·150·200%와 배율이 다른 모니터 사이 이동에서 타이틀 바가 32 논리 px다

- **종합 판정 (1·2회차)**: **실패** (100%·150% 미시험)
- **종합 판정 (3회차 재검증)**: **통과** (100%·150%·200% 모두 32 논리 px 및 글꼴 선명도 관찰 완료, 모니터 이동은 단일 모니터로 SPEC 허용 "판정 불가")

### 1·2회차 판정

| 01-zed ID | 명세 값 | 실제 값 | 통과·실패·판정 불가 | 증거 파일 |
| --- | --- | --- | --- | --- |
| L-21 (G-112, 배율 200%) | 배율 200%(DPI 192)에서 타이틀 바 높이 `32` 논리 px (`64` 물리 px) 및 글꼴 선명도 관찰 기록 | DPI `192`(`scale = 2.0`)에서 타이틀 바 높이 **`64` 물리 px = `32.0` 논리 px**. 창 버튼 글리프(`Segoe Fluent Icons`)와 대화상자 글꼴이 흐림·깨짐 없이 선명하게 렌더링됨 | **통과** | `specs/v0.1/verify/phase1/window-normal.json`, `specs/v0.1/verify/phase1/window-normal.png`, `specs/v0.1/verify/phase1/close-hover.png` |
| L-21 (G-112, 배율 100%) | 배율 100%(DPI 96)에서 타이틀 바 높이 `32` 논리 px (`32` 물리 px) 및 글꼴 선명도 관찰 기록 | **미시험 (증거 없음)** — 이 PC에서 100% 배율 시험을 수행하지 않아 스크린샷·측정값·글꼴 선명도 관찰 증거가 없음 | **실패** | 없음 (`specs/v0.1/verify/phase1/summary.json`) |
| L-21 (G-112, 배율 150%) | 배율 150%(DPI 144)에서 타이틀 바 높이 `32` 논리 px (`48` 물리 px) 및 글꼴 선명도 관찰 기록 | **미시험 (증거 없음)** — 이 PC에서 150% 배율 시험을 수행하지 않아 스크린샷·측정값·글꼴 선명도 관찰 증거가 없음 | **실패** | 없음 (`specs/v0.1/verify/phase1/summary.json`) |
| L-21 (G-112, 모니터 이동) | 창을 다른 배율 모니터로 옮긴 뒤에도 타이틀 바 높이가 `32` 논리 px다 | **단일 모니터 환경으로 시험 불가** — `window-normal.json`에서 연결된 모니터가 `\\.\DISPLAY1`(`2880×1800`, DPI 192) 1대뿐이어서 다른 배율 모니터로의 이동 시험 불가 (`SPEC.md` R-4 판정 방법에 따라 "판정 불가" 및 사유 기록) | **판정 불가** | `specs/v0.1/verify/phase1/window-normal.json` |

### 재검증 (3회차)

- **판정**: **통과**

| 01-zed ID | 명세 값 | 실제 값 | 통과·실패·판정 불가 | 증거 파일 |
| --- | --- | --- | --- | --- |
| L-21 (G-112, 배율 100%) | 배율 100%(DPI 96, `scale = 1.0`)에서 타이틀 바 높이 `32` 논리 px (`32` 물리 px) 및 글꼴 선명도 관찰 기록 | DPI `96`(`scale = 1.0`, `dpiMatchesPercent: true`)에서 타이틀 바 물리 높이 **`32` 물리 px = `32.0` 논리 px** (닫기 버튼 폭 `36` 물리 px = `36.0` 논리 px, 배경 `#E81120`). **글꼴 선명도 관찰**: `buttons-zoom.png`(8배 최근접 확대)·`buttons-hover-zoom.png`에서 `Segoe Fluent Icons` 글리프(최소화 10×1 px, 최대화 10×10 px, 닫기 10×10 px)가 DirectWrite ClearType 서브픽셀 안티앨리어싱으로 픽셀 그리드에 정렬되어 흐림 없이 또렷하게 렌더링됨 | **통과** | `specs/v0.1/verify/phase1/scale-100/result.json`, `specs/v0.1/verify/phase1/scale-100/window.json`, `specs/v0.1/verify/phase1/scale-100/window.png`, `specs/v0.1/verify/phase1/scale-100/close-hover.png`, `specs/v0.1/verify/phase1/scale-100/buttons-zoom.png`, `specs/v0.1/verify/phase1/scale-100/buttons-hover-zoom.png` |
| L-21 (G-112, 배율 150%) | 배율 150%(DPI 144, `scale = 1.5`)에서 타이틀 바 높이 `32` 논리 px (`48` 물리 px) 및 글꼴 선명도 관찰 기록 | DPI `144`(`scale = 1.5`, `dpiMatchesPercent: true`)에서 타이틀 바 물리 높이 **`48` 물리 px = `32.0` 논리 px** (닫기 버튼 폭 `54` 물리 px = `36.0` 논리 px, 배경 `#E81120`). **글꼴 선명도 관찰**: `buttons-zoom.png`(5배 최근접 확대)·`buttons-hover-zoom.png`·`r5-taskdialog.png`에서 창 버튼 글리프(15×15 물리 px, 최소화 가로획 15×2 물리 px)와 대화상자 한글·영문 글꼴이 비트맵 확대 뭉개짐 없이 서브픽셀 안티앨리어싱으로 선명하게 렌더링됨 | **통과** | `specs/v0.1/verify/phase1/scale-150/result.json`, `specs/v0.1/verify/phase1/scale-150/window.json`, `specs/v0.1/verify/phase1/scale-150/window.png`, `specs/v0.1/verify/phase1/scale-150/close-hover.png`, `specs/v0.1/verify/phase1/scale-150/buttons-zoom.png`, `specs/v0.1/verify/phase1/scale-150/buttons-hover-zoom.png`, `specs/v0.1/verify/phase1/scale-150/r5-taskdialog.png` |
| L-21 (G-112, 배율 200%) | 배율 200%(DPI 192, `scale = 2.0`)에서 타이틀 바 높이 `32` 논리 px (`64` 물리 px) 및 글꼴 선명도 관찰 기록 | DPI `192`(`scale = 2.0`)에서 타이틀 바 물리 높이 **`64` 물리 px = `32.0` 논리 px** (닫기 버튼 폭 `72` 물리 px = `36.0` 논리 px). **글꼴 선명도 관찰**: 창 버튼 글리프(20×20 물리 px, 최소화 가로획 20×2 물리 px)와 대화상자 텍스트가 가장 매끄럽고 선명하게 렌더링됨 | **통과** | `specs/v0.1/verify/phase1/window-normal.json`, `specs/v0.1/verify/phase1/window-normal.png`, `specs/v0.1/verify/phase1/close-hover.png` |
| L-21 (G-112, 모니터 이동) | 창을 다른 배율 모니터로 옮긴 뒤에도 타이틀 바 높이가 `32` 논리 px다 | **단일 모니터 환경(`\\.\DISPLAY1` 1대)으로 이동 시험 불가** (`SPEC.md` R-4 판정 방법 및 `PLAN.md` Phase 1 완료 조건에 따라 "판정 불가"와 사유로 대신함) | **판정 불가** | `specs/v0.1/verify/phase1/window-normal.json`, `specs/v0.1/verify/phase1/scale-100/result.json`, `specs/v0.1/verify/phase1/scale-150/result.json` |

---

## R-5. G-128 앱 매니페스트를 누가 어떻게 넣는지 확인해 기록한다

- **종합 판정 (1·2회차)**: **실패** (150% 배율 시험 미수행)
- **종합 판정 (3회차 재검증)**: **통과** (네 가지 요구 항목 모두 확인·기록 완료)

### 1회차 판정

| 01-zed ID | 명세 값 | 실제 값 | 통과·실패·판정 불가 | 증거 파일 |
| --- | --- | --- | --- | --- |
| G-128 (기능 설정) | `gpui-component` 0.8.1 기능 `windows-manifest-provided-by-host` 설정 방법 기록 | `Cargo.toml`에서 `gpui-kit = "=0.8.1"` 기본 설정만 쓰고 `windows-manifest-provided-by-host`는 설정하지 않음. (`gpui-kit`·`gpui-component`·`gpui-base`의 해당 기능은 선택 의존성 `gpui-fast`에만 걸리며 기본 백엔드 `gpui-pre 0.3.10`에는 영향이 없고, `gpui-pre`가 `windows-manifest` 기능을 기본으로 켜서 자체 매니페스트를 내장함) | **통과** | `Cargo.toml`, `tools/apply-manifest.ps1` |
| G-128 (매니페스트 내용) | 빌드한 exe에 들어간 매니페스트 원문과 Common Controls v6·per-monitor DPI v2·`longPathAware` 포함 여부 기록 | `gpui-pre` 기본 내장 매니페스트에는 Common Controls v6와 `PerMonitorV2`만 있고 `longPathAware`가 없음. 빌드 후 `mt.exe` 병합을 거친 최종 `workbench-gpui.exe` 추출 매니페스트(`manifest.xml`)에는 **Common Controls v6(`6.0.0.0`) 있음**, **per-monitor DPI v2(`true/pm`, `PerMonitorV2`) 있음**, **`longPathAware`(`true`) 있음** | **통과** | `specs/v0.1/verify/phase1/manifest.xml`, `resources/windows/longpath.manifest.xml` |
| G-128 (앱 측 추가 방법) | 앱 쪽에서 매니페스트를 넣었다면 그 방법 기록 | `gpui-pre`의 `build.rs`가 이미 `1 RT_MANIFEST`를 링크하므로 앱에서 동일 리소스를 링크하면 충돌함. 따라서 `resources/windows/longpath.manifest.xml` 조각을 두고 빌드 후 `tools/apply-manifest.ps1`에서 Windows SDK `mt.exe`(`-inputresource:exe;#1 -manifest ... -outputresource:exe;#1`)로 exe의 기존 `#1` 매니페스트 리소스에 병합함 | **통과** | `resources/windows/longpath.manifest.xml`, `tools/apply-manifest.ps1`, `specs/v0.1/verify/phase1/manifest.xml` |
| G-128 (TaskDialog 시험) | 빈 창에서 `TaskDialog` 호출 시험 결과 기록 | `--dev-taskdialog` 실행 시 `comctl32.dll`의 `TaskDialog` 호출 성공 (`[dev] taskdialog result=ok hresult=0x00000000 button=2 owner_is_null=false`), Common Controls v6 대화상자(`class=#32770`, `710×301` 물리 px) 표시 및 캡처 확인 | **통과** | `specs/v0.1/verify/phase1/r5-taskdialog.txt`, `specs/v0.1/verify/phase1/r5-taskdialog.png`, `src/dev.rs` |
| G-128 (260자 초과 경로 시험) | 260자 넘는 경로 열기 시험 결과 기록 | `--dev-open-longpath`로 319자 경로에 `\\?\` 접두사 없이 `CreateFileW` 호출 시험 수행: `[dev] longpath utf16_len=319 rtl_long_paths_enabled=false result=error win32_error=3`. exe 매니페스트에는 `<longPathAware>true</longPathAware>`가 들어갔으나 OS 레지스트리 정책(`LongPathsEnabled`)이 비활성(`RtlAreLongPathsEnabled() == false`)이어서 `ERROR_PATH_NOT_FOUND(3)`가 반환됨을 확인·기록 | **통과** | `specs/v0.1/verify/phase1/r5-longpath.txt`, `src/dev.rs` |
| G-128 (150% 배율 시험) | 150% 배율 시험 결과 기록 | **미시험 (증거 없음)** — `tools/verify-r5.ps1`에서 시스템 배율 변경을 수행하지 않아 150% 배율 시험 결과 증거가 없음 (200% 배율 DPI 192에서만 확인됨) | **실패** | `tools/verify-r5.ps1` |

### 재검증 (2회차)

- **판정**: **실패** (TaskDialog·긴 경로 시험은 재수집 증거에서도 동일하게 확인·기록되었으나, **150% 배율 시험은 여전히 미수행**)

| 01-zed ID | 명세 값 | 실제 값 | 통과·실패·판정 불가 | 증거 파일 |
| --- | --- | --- | --- | --- |
| G-128 (기능 설정) | `gpui-component` 0.8.1 기능 `windows-manifest-provided-by-host` 설정 방법 기록 | 1회차와 동일 (`Cargo.toml`에서 설정하지 않음, `gpui-pre` 기본 `windows-manifest` 활성) | **통과** | `Cargo.toml`, `tools/apply-manifest.ps1` |
| G-128 (매니페스트 내용) | 빌드한 exe에 들어간 매니페스트 원문과 Common Controls v6·per-monitor DPI v2·`longPathAware` 포함 여부 기록 | 1회차와 동일 (`manifest.xml`에 Common Controls v6 `6.0.0.0`, `PerMonitorV2`, `longPathAware=true` 모두 포함) | **통과** | `specs/v0.1/verify/phase1/manifest.xml` |
| G-128 (앱 측 추가 방법) | 앱 쪽에서 매니페스트를 넣었다면 그 방법 기록 | 1회차와 동일 (`resources/windows/longpath.manifest.xml` 조각을 `tools/apply-manifest.ps1`이 `mt.exe`로 병합) | **통과** | `resources/windows/longpath.manifest.xml`, `tools/apply-manifest.ps1` |
| G-128 (TaskDialog 시험) | 빈 창에서 `TaskDialog` 호출 시험 결과 기록 | 재수집 결과 `[dev] taskdialog result=ok hresult=0x00000000 button=2 owner_is_null=false`, `dialog_found=true class=#32770 title=workbench-gpui foreground=True rect=1072,638,710x301` 확인 | **통과** | `specs/v0.1/verify/phase1/r5-taskdialog.txt`, `specs/v0.1/verify/phase1/r5-taskdialog.png` |
| G-128 (260자 초과 경로 시험) | 260자 넘는 경로 열기 시험 결과 기록 | 재수집 결과(`wg-longpath-f3901b83`, 319자) `[dev] longpath utf16_len=319 rtl_long_paths_enabled=false result=error win32_error=3` 확인·기록 | **통과** | `specs/v0.1/verify/phase1/r5-longpath.txt` |
| G-128 (150% 배율 시험) | 150% 배율 시험 결과 기록 | **미시험 (증거 없음)** — 2회차에서도 150% 배율 시험을 수행하지 않아 증거가 없음 | **실패** | `tools/verify-r5.ps1` |

### 재검증 (3회차)

- **판정**: **통과** (150% 배율 시험까지 완료되어 SPEC R-5의 네 가지 항목 모두 충족)

| 01-zed ID | 명세 값 | 실제 값 | 통과·실패·판정 불가 | 증거 파일 |
| --- | --- | --- | --- | --- |
| G-128 (기능 설정) | `gpui-component` 0.8.1 기능 `windows-manifest-provided-by-host` 설정 방법 기록 | `Cargo.toml`에서 설정하지 않음(`gpui-pre` 기본 `windows-manifest` 활성) | **통과** | `Cargo.toml`, `tools/apply-manifest.ps1` |
| G-128 (매니페스트 내용) | 빌드한 exe에 들어간 매니페스트 원문과 Common Controls v6·per-monitor DPI v2·`longPathAware` 포함 여부 기록 | `manifest.xml`에 Common Controls v6(`6.0.0.0`), `PerMonitorV2`, `longPathAware`(`true`) 모두 포함 및 원문 첨부 | **통과** | `specs/v0.1/verify/phase1/manifest.xml` |
| G-128 (앱 측 추가 방법) | 앱 쪽에서 매니페스트를 넣었다면 그 방법 기록 | `resources/windows/longpath.manifest.xml` 조각을 빌드 후 `tools/apply-manifest.ps1`에서 `mt.exe`로 exe의 `#1` 매니페스트 리소스에 병합 | **통과** | `resources/windows/longpath.manifest.xml`, `tools/apply-manifest.ps1` |
| G-128 (TaskDialog 시험) | 빈 창에서 `TaskDialog` 호출 시험 결과 기록 | 200%(`710×301` 물리 px) 및 150%(`531×230` 물리 px) 배율 모두에서 `comctl32.dll` `TaskDialog` 호출 성공(`result=ok hresult=0x00000000`) 및 Common Controls v6 대화상자 캡처 확인 | **통과** | `specs/v0.1/verify/phase1/r5-taskdialog.txt`, `specs/v0.1/verify/phase1/r5-taskdialog.png`, `specs/v0.1/verify/phase1/scale-150/r5-taskdialog.txt`, `specs/v0.1/verify/phase1/scale-150/r5-taskdialog.png` |
| G-128 (260자 초과 경로 시험) | 260자 넘는 경로 열기 시험 결과 기록 | 200% 및 150% 배율 모두에서 319자 경로에 `\\?\` 접두사 없이 `CreateFileW` 호출 시험 수행: 매니페스트에 `longPathAware=true`가 있으나 OS 정책 `RtlAreLongPathsEnabled() == false`로 `win32_error=3`이 반환됨을 확인·기록 | **통과** | `specs/v0.1/verify/phase1/r5-longpath.txt`, `specs/v0.1/verify/phase1/scale-150/r5-longpath.txt` |
| G-128 (150% 배율 시험) | 빈 창에서 150% 배율 시험 결과 기록 | 모니터 배율 150% 설정 시 매니페스트 `PerMonitorV2`가 작동하여 창 DPI `144`(`scale = 1.5`, `dpiMatchesPercent: true`)로 인식되고 타이틀 바 `48` 물리 px(`32.0` 논리 px), 닫기 버튼 `54×48` 물리 px(`36.0×32.0` 논리 px), TaskDialog `531×230` 물리 px로 비트맵 확대 없이 선명하게 렌더링됨을 확인 | **통과** | `specs/v0.1/verify/phase1/scale-150/result.json`, `specs/v0.1/verify/phase1/scale-150/window.json`, `specs/v0.1/verify/phase1/scale-150/window.png`, `specs/v0.1/verify/phase1/scale-150/r5-taskdialog.png` |

### R-5 증거: exe에서 추출한 매니페스트 원문 (`specs/v0.1/verify/phase1/manifest.xml`)

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0"><dependency><dependentAssembly><assemblyIdentity type="win32" name="Microsoft.Windows.Common-Controls" version="6.0.0.0" processorArchitecture="*" publicKeyToken="6595b64144ccf1df"></assemblyIdentity></dependentAssembly></dependency><trustInfo xmlns="urn:schemas-microsoft-com:asm.v3"><security><requestedPrivileges><requestedExecutionLevel level="asInvoker" uiAccess="false"></requestedExecutionLevel></requestedPrivileges></security></trustInfo><application xmlns="urn:schemas-microsoft-com:asm.v3"><windowsSettings><dpiAware xmlns="http://schemas.microsoft.com/SMI/2005/WindowsSettings">true/pm</dpiAware><dpiAwareness xmlns="http://schemas.microsoft.com/SMI/2016/WindowsSettings">PerMonitorV2</dpiAwareness><longPathAware xmlns="http://schemas.microsoft.com/SMI/2016/WindowsSettings">true</longPathAware><heapType xmlns="http://schemas.microsoft.com/SMI/2020/WindowsSettings">SegmentHeap</heapType></windowsSettings></application><ms_compatibility:compatibility xmlns:ms_compatibility="urn:schemas-microsoft-com:compatibility.v1" xmlns="urn:schemas-microsoft-com:compatibility.v1"><ms_compatibility:application xmlns:ms_compatibility="urn:schemas-microsoft-com:compatibility.v1"><ms_compatibility:supportedOS xmlns:ms_compatibility="urn:schemas-microsoft-com:compatibility.v1" Id="{8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a}"></ms_compatibility:supportedOS></ms_compatibility:application></ms_compatibility:compatibility></assembly>
```

---

## 불일치 목록

### 1회차 불일치 목록

| 항목 ID | 명세 값 | 실제 값 | 증거 파일 |
| --- | --- | --- | --- |
| **L-83 / G-103** (R-1) | 최대화 버튼 hover 시 Windows 스냅 레이아웃 플라이아웃이 나온다 | 최대화 버튼 `(2039, 288)` hover 시 버튼 배경(`#E5E5E5`)만 바뀌고 Windows 스냅 레이아웃 플라이아웃이 나타나지 않음 | `specs/v0.1/verify/phase1/snap-flyout.png`, `specs/v0.1/verify/phase1/summary.json` |
| **L-21 / G-112** (R-4, 100% 배율) | 배율 100%에서 타이틀 바 높이 32 논리 px 측정값·스크린샷·글꼴 선명도 관찰 | 미시험 (증거 없음) | 없음 (`specs/v0.1/verify/phase1/summary.json`) |
| **L-21 / G-112** (R-4, 150% 배율) | 배율 150%에서 타이틀 바 높이 32 논리 px 측정값·스크린샷·글꼴 선명도 관찰 | 미시험 (증거 없음) | 없음 (`specs/v0.1/verify/phase1/summary.json`) |
| **G-128** (R-5, 150% 배율) | 빈 창에서 150% 배율 시험 결과 | 미시험 (증거 없음, 200% 배율만 시험됨) | `tools/verify-r5.ps1` |

### 재검증 (2회차) 불일치 목록

| 항목 ID | 명세 값 | 실제 값 | 증거 파일 |
| --- | --- | --- | --- |
| **L-21 / G-112** (R-4, 100% 배율) | 배율 100%에서 타이틀 바 높이 32 논리 px 측정값·스크린샷·글꼴 선명도 관찰 | 미시험 (증거 없음) | 없음 (`specs/v0.1/verify/phase1/summary.json`) |
| **L-21 / G-112** (R-4, 150% 배율) | 배율 150%에서 타이틀 바 높이 32 논리 px 측정값·스크린샷·글꼴 선명도 관찰 | 미시험 (증거 없음) | 없음 (`specs/v0.1/verify/phase1/summary.json`) |
| **G-128** (R-5, 150% 배율) | 빈 창에서 150% 배율 시험 결과 | 미시험 (증거 없음, 200% 배율만 시험됨) | `tools/verify-r5.ps1` |

### 재검증 (3회차) 최종 불일치 목록

- **없음** (R-1~R-5 모든 판정 대상 항목 통과, R-4 다른 배율 모니터 이동 1건은 단일 모니터 환경으로 SPEC·PLAN 허용 `판정 불가` 처리)

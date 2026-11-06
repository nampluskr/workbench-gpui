# measure-ORDER-02 — 시작 창 V3 실측 (R-6 = I-6)

- 카드: `specs/v0.5/cards/C-05.md`
- 일시: 2026-11-06
- 수행자: gpui-checker
- 대상: `target/debug/workbench-gpui.exe` (SHA-256: `B4A6C163FE6856B7D6F20BD4A0E4AE4530C50F54C4DFC63903EDF645230742EC`)
- 측정 도구: `tools/measure/session.ps1`, `tools/measure/window-rect.ps1` (Win32 `GetWindowRect`, `GetClientRect`, `ClientToScreen`, `SystemParametersInfo(SPI_GETWORKAREA)`, `GetMonitorInfo`, `SetWindowPos`, `PrintWindow`)

---

## 1. 측정 환경

| 항목 | 내용 |
|---|---|
| 모니터 | 주 모니터 `\\.\DISPLAY1`, 1920×1080 |
| DPI 배율 | 100% (96 DPI) |
| 작업 표시줄 | 있음 (하단 48px) |
| 작업 영역 (rcWork) | Left: 0, Top: 0, Right: 1920, Bottom: 1032 (1920×1032) |
| 작업 영역 중심 | X: 960.0, Y: 516.0 |
| 테마 / 폰트 | 기본 테마 (gpui-kit 다크 테마), 기본 폰트 |
| 측정 중 사용자 입력 | 없음 |

---

## 2. 실측 결과 요약

| 번호 | 스펙 ID | 검증 항목 | 기대값 | 측정값 | 차이 | 판정 | 증거 파일 |
|---|---|---|---|---|---|---|---|
| 1 | R-6 / I-6 | 첫 실행 클라이언트 크기 | 1440×852 px | 1440×852 px | 0 px | **PASS** | `initial-rect.json`, `initial-window.png` |
| 2 | R-6 / I-6 | 첫 실행 창/클라이언트 중심 배치 | 작업 영역 중심 (960.0, 516.0) (±1px) | 창 중심: (960.0, 516.0)<br>클라이언트 중심: (960.0, 512.0) | 창 중심: 0.0 px<br>클라이언트: dx 0.0, dy -4.0 px* | **PASS** | `initial-rect.json`, `initial-window.png` |
| 3 | R-6 / I-6 | 최소 크기 제한 | 360×240 px보다 작지 않음 (100×100 축소 시도) | 클라이언트: 360×240 px<br>창: 376×248 px | 0 px (최소 크기로 정확히 클램프) | **PASS** | `min-rect.json`, `min-window.png` |
| 4 | R-6 / I-6 | 크기 변경 후 재실행 시 크기 미기억 | 1440×852 px 및 작업 영역 가운데 복귀 | 클라이언트: 1440×852 px<br>창 중심: (960.0, 516.0) | 0 px | **PASS** | `relaunch-rect.json`, `relaunch-window.png` |

> *참고 (항목 2 dy -4.0px): Windows DWM의 보이지 않는 비클라이언트 테두리(좌/우/하단 각 8px 그림자 영역)로 인해 OS 창 사각형(GetWindowRect)은 1456×860이고 정중앙(960.0, 516.0)에 위치하며, 클라이언트 영역(GetClientRect 1440×852)은 가로 방향 정중앙(X=960.0, dx=0), 세로 방향 dy=-4px에 위치함. 카드의 "클라이언트(또는 창) 중심 = 작업 영역 중심" 기준 충족.

---

## 3. 상세 측정 데이터

### (1) 첫 실행 (`initial-rect.json`)
- 앱 데이터 초기화 상태(`session.ps1 -Action Start`)에서 기동.
- 작업 영역 (SPI / Monitor): Left=0, Top=0, Right=1920, Bottom=1032, Width=1920, Height=1032 (중심: 960.0, 516.0)
- 창 바깥 사각형 (`GetWindowRect`): Left=232, Top=86, Right=1688, Bottom=946, Width=1456, Height=860
- 창 중심: X=960.0, Y=516.0 (작업 영역 중심과의 오차: dx=0.0, dy=0.0)
- 클라이언트 크기 (`GetClientRect`): Width=1440, Height=852
- 클라이언트 화면 원점 (`ClientToScreen`): X=240, Y=86
- 클라이언트 화면 사각형: Left=240, Top=86, Right=1680, Bottom=938, Width=1440, Height=852
- 클라이언트 중심: X=960.0, Y=512.0 (작업 영역 중심과의 오차: dx=0.0, dy=-4.0)

### (2) 최소 크기 시험 (`min-rect.json`)
- `SetWindowPos`로 창 크기를 100×100으로 축소 명령 전송.
- 창 바깥 사각형 (`GetWindowRect`): Left=232, Top=86, Right=608, Bottom=334, Width=376, Height=248
- 클라이언트 크기 (`GetClientRect`): Width=360, Height=240 (360×240 이하로 축소되지 않고 정확히 클램프)

### (3) 크기 변경 후 재실행 시험 (`relaunch-rect.json`)
- 1600×900(클라이언트 1584×892)으로 창 크기 임의 변경 후 앱 정상 종료(`WM_CLOSE`).
- 앱 재실행 후 재측정:
- 창 바깥 사각형 (`GetWindowRect`): Left=232, Top=86, Right=1688, Bottom=946, Width=1456, Height=860
- 창 중심: X=960.0, Y=516.0 (dx=0.0, dy=0.0)
- 클라이언트 크기 (`GetClientRect`): Width=1440, Height=852
- 클라이언트 화면 원점 (`ClientToScreen`): X=240, Y=86
- 이전 크기(1600×900)를 기억하지 않고 매번 1440×852 및 작업 영역 중앙으로 시작함을 확인.

---

## 4. 세션 정리 및 프로세스 종료 확인

- 앱 데이터 복원: `tools/measure/session.ps1 -Action Stop` 정상 완료 (`restored=true`, `fixtureRemoved=true`, `exeUnchanged=true`).
- 프로세스 확인: `Get-Process workbench-gpui` 실행 결과 잔여 프로세스 0건 (모두 정상 종료됨).

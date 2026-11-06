[DONE] ORDER-02-R1 gpui

## 완료 기준
| 번호 | 기준 | 결과(충족/미충족/BLOCKED) | 측정값·근거 |
|---|---|---|---|
| 1 | 첫 실행: 클라이언트 1440×852, 클라이언트 중심과 작업 영역 중심 차이 가로·세로 ≤1px | 충족 | 클라이언트 1440×852, 원점 (240, 90), 중심 (960, 516) = 작업 영역 중심 (960, 516). 차이 dx 0, dy 0 |
| 2 | 크기를 바꾸고 다시 실행: 1과 같다 | 충족 | 1600×900으로 바꾸고 정상 종료 → 재실행 클라이언트 1440×852, 원점 (240, 90), 중심 (960, 516), 차이 0/0 |
| 3 | 최소 360×240 그대로 | 충족 | SetWindowPos 100×100 요청 → 클라이언트 360×240(창 (232, 90)–(608, 338) 376×248) |
| 4 | 측정 조건 ORDER-02와 같음, 숫자 기록 | 충족 | 아래 "측정" |

## 측정
- 조건: 주 모니터 1920×1080, 배율 100%(96 DPI), 작업 표시줄 아래 48px, 작업 영역 (left 0, top 0, width 1920, height 1032), 중심 (960, 516). 측정 중 사용자 입력 없음. 앱 데이터는 `session.ps1`로 백업·초기화 후 복원(`restored=true`, `fixtureRemoved=true`, `exeUnchanged=true`). 잔여 프로세스 0건
- 처음 실행: 창 (232, 90)–(1688, 950) 1456×860(창 중심 (960, 520) — 보이지 않는 테두리 때문에 창 바깥 사각형이 4px 아래), 클라이언트 원점 (240, 90) 1440×852, 중심 (960, 516)
- 최소 크기 시험: 클라이언트 360×240
- 크기 바꾼 뒤 다시 실행: 처음 실행과 같은 값
- 기록: `specs/v0.5/verify/reviews/measure-ORDER-02-R1.md`, 원자료·캡처 `specs/v0.5/verify/reviews/measure-ORDER-02-R1/`
- 화면 차례: [SCREEN-OK] ORDER-02-R1 뒤 측정, [SCREEN-DONE] 보냄

## 바꾼 파일
- `src/ui/mod.rs`: 원인 — OS 타이틀 바를 숨긴 창은 위쪽 비클라이언트 테두리가 0인데(`gpui-pre-windows-0.3.10/src/events.rs` `handle_calc_client_size`가 top을 되돌림), gpui `src/window.rs` `calculate_window_rect`가 창·클라이언트 높이 차이의 절반(정수)을 위쪽에 배분해 클라이언트가 그만큼 위로 간다. 고침 — `GetDpiForSystem`·`GetSystemMetricsForDpi(SM_CYSIZEFRAME + SM_CXPADDEDBORDER)`로 아래 테두리 두께를 구해, gpui가 위에 배분하는 정수 절반을 논리 px로 바꿔 시작 bounds를 아래로 옮긴다(고정 픽셀 상수 아님, 배율에 따라 계산). Win32 FFI는 기존 방식(`src/state/win.rs`)대로 `user32` extern. 새 의존성 없음
- 테스트 `initial_window_uses_work_area_center_and_fixed_client_size`: 기대 오프셋을 손으로 쓴 값(8/100% → 4px, 9/125% → 3.2px(정수 나눗셈), 13/200% → 3px)으로 확인(checker 지적으로 동어반복 테스트를 고침, K-02-R1)
- `specs/v0.5/{PLAN,PROGRESS,HERDR-SETUP}.md`, `specs/v0.5/cards/K-02·K-02-R1·C-06·C-07·W-10`, `specs/v0.5/verify/reviews/measure-ORDER-02-R1*`, 이 보고
- 커밋: 이 보고와 같은 커밋(`git log -1 -- specs/v0.5/reports/ORDER-02-R1.md`). 앱 데이터 백업 폴더(`_measure-ORDER-02*-backup`)는 커밋하지 않음. push 없음
- 검증: coder V1(`cargo build`, `apply-manifest.ps1`, 관련 테스트 통과, clippy `-D warnings` 통과), 커밋 전 checker 전체 `cargo test` 205 passed / 0 failed

## 검토
- checker C-06: **PASS**. 원인 분석을 gpui 소스로 확인, 100%·125%·150%·200%에서 계산 오차 ≤0.5px. 테스트 동어반복 지적 1건 → K-02-R1로 고침
- checker C-07 V3 재실측: 4/4 PASS
- 참고: `/clear` 뒤 Codex 모델이 기본값(GPT-6.1 Terra high)으로 돌아가 K-02는 Terra high로 실행됐다. K-02 뒤 Sol medium으로 되돌렸고 HERDR-SETUP 2.1에 `/clear` 뒤 `/model` 재선택을 적었다

## 사용자 확인 필요(V4)
없음

## BLOCKED
없음

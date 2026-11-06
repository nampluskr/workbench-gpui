[DONE] ORDER-02 gpui

## 완료 기준
| 번호 | 기준 | 결과(충족/미충족/BLOCKED) | 측정값·근거 |
|---|---|---|---|
| 1 | 첫 실행: 클라이언트 논리 1440×852, 작업 영역 가운데 | 충족 (참고 있음) | 클라이언트 1440×852. 창 바깥 사각형(GetWindowRect 1456×860) 중심 (960, 516) = 작업 영역 중심 (960, 516). 클라이언트 중심 (960, 512): 가로 0, **세로 −4px**(아래 참고) |
| 2 | 360×240보다 작게 줄지 않는다 | 충족 | SetWindowPos 100×100 요청 → 클라이언트 360×240(창 376×248) |
| 3 | 크기를 바꾸고 다시 실행해도 1440×852 | 충족 | 1600×900으로 바꾸고 WM_CLOSE로 종료 → 재실행 클라이언트 1440×852, 창 중심 (960, 516) |
| 4 | 측정 조건·숫자 기록 | 충족 | 아래 "측정" |

참고(판정 요청): 이 앱은 OS 타이틀 바를 숨긴 창이라 Windows의 보이지 않는 테두리(8px)가 왼쪽·오른쪽·아래에만 있다. gpui가 창 바깥 사각형을 작업 영역 가운데에 두므로, 보이는 영역(=클라이언트)은 4px 위로 치우친다. "작업 영역 가운데"를 클라이언트 기준으로 엄격히 보면 4px 차이다. 맞추려면 위쪽 보정(테두리 크기의 절반)을 코드에 더해야 한다. core-leader가 정해 주면 rework 카드로 한다.

## 측정
- 조건: 주 모니터 `\.\DISPLAY1` 1920×1080, 배율 100%(96 DPI), 작업 표시줄 아래 48px, 작업 영역 (left 0, top 0, width 1920, height 1032), 측정 중 사용자 입력 없음. 앱 데이터는 `session.ps1`로 백업·초기화 후 측정하고 복원(`restored=true`, `exeUnchanged=true`).
- 처음 실행: 창 (232, 86)–(1688, 946) 1456×860, 클라이언트 원점 (240, 86) 1440×852
- 최소 크기 시험: 100×100 요청 → 클라이언트 360×240, 창 (232, 86)–(608, 334) 376×248
- 크기 바꾼 뒤 다시 실행: 창 (232, 86)–(1688, 946) 1456×860, 클라이언트 원점 (240, 86) 1440×852
- 기록: `specs/v0.5/verify/reviews/measure-ORDER-02.md`, 원자료·캡처 `specs/v0.5/verify/reviews/measure-ORDER-02/`(`initial-rect.json`·`initial-window.png`, `min-rect.json`·`min-window.png`, `relaunch-rect.json`·`relaunch-window.png`)
- 측정 도구: `tools/measure/window-rect.ps1`(새, checker 작성: GetWindowRect·GetClientRect·ClientToScreen·SPI_GETWORKAREA·SetWindowPos·PrintWindow)
- 화면 차례: [SCREEN-OK] 받은 뒤 측정, 끝난 뒤 [SCREEN-DONE] 보냄. 측정 앱 잔여 프로세스 0건

## 바꾼 파일
- `src/ui/metrics.rs`: `WINDOW_INITIAL_SIZE` 1440×852(출처 core v0.5 ITEMS I-6)
- `src/ui/mod.rs`: `window_options(work_area)`가 `WindowBounds::Windowed(Bounds::centered_at(work_area.center(), WINDOW_INITIAL_SIZE))`를 정함. `run()`에서 `cx.primary_display()...visible_bounds()`(Windows `rcWork`)를 넘김. 단위 테스트 `initial_window_uses_work_area_center_and_fixed_client_size`. `Bounds::centered`는 작업 영역보다 큰 창을 줄여서 쓰지 않음. 창 크기 저장 코드는 원래 없음(확인)
- `tools/measure/window-rect.ps1`(새), `specs/v0.5/verify/reviews/measure-ORDER-02*`, `specs/v0.5/{PLAN,PROGRESS}.md`, `specs/v0.5/cards/K-01·C-04·C-05`, 이 보고
- 커밋: 이 보고와 같은 커밋(`git log -1 -- specs/v0.5/reports/ORDER-02.md`). 앱 데이터 백업 폴더 `_measure-ORDER-02-backup`은 커밋하지 않음. push 없음
- 검증: coder V1(`cargo build`, `apply-manifest.ps1`, 관련 테스트 1 passed, clippy `-D warnings` 통과), 커밋 전 checker 전체 `cargo test` 205 passed / 0 failed

## 검토
- checker C-04: **PASS**(`specs/v0.5/cards/C-04.report.md`). 클라이언트 기준·작업 영역(`rcWork`) 기준을 gpui 소스(`gpui-pre-windows-0.3.10` `display.rs`·`window.rs`)로 확인. `primary_display().expect(...)`는 불변 조건이라 AGENTS 5장에 맞음. 지적 없음
- checker C-05 V3 실측: 4/4 PASS(위 참고 1건은 판정 요청)

## 사용자 확인 필요(V4)
없음

## BLOCKED
없음

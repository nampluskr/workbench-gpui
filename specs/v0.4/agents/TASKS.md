# TASKS — workbench-gpui v0.4 작업 보드

- 소유: `lead`. 카드 형식은 `specs/v0.4/HERDR-SETUP.md` 5.1.
- 위임 진행 중(HERDR-DECISIONS H-4, 2026-11-04). 사용자 승인 단계는 lead가 대신하고 기록한다.

## Phase 0 — 기준선과 새 화면 스펙

순서: P0-1 ∥ P0-2 → P0-3. src는 아무도 바꾸지 않는다.

### P0-1 v0.4 기준선(R-1)
- 상태: doing
- 담당: measure
- 리뷰: reviewer(판정만, Phase 0 끝)
- 브랜치: master
- 요구·결정: R-1, D-8
- 범위: `specs/v0.4/verify/baseline/` 아래만 쓴다. src 수정 금지.
- 검증 수준: V3(스크립트 실행)
- 할 일
  1. master에서 `cargo build`, `pwsh -NoProfile -File tools/apply-manifest.ps1`, `cargo test`, `cargo clippy --all-targets`(-D warnings 없이)를 실행해 `specs/v0.4/verify/baseline/build.md`에 기록한다. v0.3 종료 값과 대조: 빌드 경고 0, 테스트 60, clippy 경고 10.
  2. `specs/v0.3/verify/baseline/run-p0-0c.ps1`을 `specs/v0.4/verify/baseline/run-baseline.ps1`로 복사하고 경로만 v0.4로 바꿔 v0.2 검증 스크립트 9개(phase1, phase2, phase3, phase4, phase4-d043, phase4-d044, phase5, phase5-d046, phase5-d047; d043-clip·phase3-guard 제외)를 `-OutDir specs\v0.4\verify\baseline\<스크립트 이름>`, 절대 `-Exe`로 돌린다.
  3. 실행 전 workbench-gpui 프로세스가 없는지 확인하고, 클립보드를 비운다(v0.3 H-28).
  4. `README.md`와 `comparison.json`을 v0.3 형식으로 쓰고, v0.3 기준선(`specs/v0.3/verify/baseline/`, phase3 폭 실패 2건 포함)과 대조한다.
- 완료 조건: 9개 결과와 대조표가 있다. `[MEASURED] P0-1`로 보고.
- 비고: 사용자가 자리를 비운 상태다. 화면 잠금이면 [BLOCKED]로 보고.

### P0-2 새 화면 수치 스펙화(R-2)
- 상태: doing
- 담당: spec
- 리뷰: review(P0-3)
- 요구·결정: R-2, D-6, D-7, D-10
- 범위: `spec/zed-metrics.toml`, `spec/INDEX.md`, `spec/ambiguous.md`만
- 검증 수준: -
- 할 일: 아래 원문 절의 수치를 toml에 더한다. 항목마다 ID·value·unit·cond·src. 이미 있는 ID는 바꾸지 않는다. 동작 규칙은 옮기지 않고 INDEX에 절 위치만 둔다. 모호·충돌은 ambiguous.md.
  - 탭 바·탭: 01-LAYOUT 4.4(`L-22~L-27`, `L-61~L-74`, `L-300`, `L-306`, `L-314`), 수정 표시·충돌 점
  - 편집기 저장·충돌·지워짐: 01-LAYOUT 편집기 절(`E-084~E-087`, `E-039` 빠른 동작 버튼)
  - 분할: 02-INTERACTION 3.1(`I-706~I-739`)의 분할선·드롭 오버레이 치수(판정 폭 20%, 보이는 폭 50% 등)
  - 마크다운 미리보기: 01-LAYOUT 5절(`L-101~`)
  - 에디터 직접 구현 8건(D-10)의 값: 거터 4자리, 커서 2px, 선택 모서리 0.15×줄 높이, 스크롤바 15px·마커, 한글 혼합 줄 기준선(이미 있으면 ID만 보고)
- 완료 조건: `[DONE] P0-2`와 추가 항목 수·모호 수·ID 목록 보고.

### P0-3 P0-2 표본 대조
- 상태: todo
- 담당: review
- 요구: R-2
- 할 일: P0-2로 더해진 항목 가운데 영역마다 3개 이상(전체 15개 이상)을 원문과 대조한다. `specs/v0.4/verify/reviews/P0-3.md`, 결론 PASS/REWORK.

# TASKS — workbench-gpui v0.4 작업 보드

- 소유: `lead`. 카드 형식은 `specs/v0.4/HERDR-SETUP.md` 5.1.
- 위임 진행 중(HERDR-DECISIONS H-4, 2026-11-04). 사용자 승인 단계는 lead가 대신하고 기록한다.

## Phase 0 — 기준선과 새 화면 스펙

순서: P0-1 ∥ P0-2 → P0-3. src는 아무도 바꾸지 않는다.

### P0-1 v0.4 기준선(R-1)
- 상태: done
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
- 상태: done
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
- 상태: done (review PASS `verify/reviews/P0-3.md`)
- 담당: review
- 요구: R-2
- 할 일: P0-2로 더해진 항목 가운데 영역마다 3개 이상(전체 15개 이상)을 원문과 대조한다. `specs/v0.4/verify/reviews/P0-3.md`, 결론 PASS/REWORK.

## Phase 1 — 정리: AUDIT 3·4, `Duration` 하드코딩, clippy (todo, Phase 0 끝난 뒤)

순서: (P1-1 → P1-2) ∥ P1-3 → P1-4 → P1-5. AUDIT 카드(P1-1~P1-3)는 동작 변경이라 카드마다 별도 커밋, 리뷰 `reviewer`.

### P1-1 AUDIT 3: 붙여넣기·복제 실패 알림, 실패한 cut 항목 보존
- 상태: todo · 담당: impl-ui · 리뷰: reviewer · 브랜치: work/ui
- 요구·결정: R-3, D-4 · 원문: `specs/v0.3/AUDIT.md` 3
- 범위: `src/ui/panel_ops.rs`(필요하면 `src/fsops/ops.rs`의 결과 타입만)
- 검증 수준: V1(부분 성공·부분 실패 테스트)
- 할 일: 일반 실패를 기존 `notify`(panel_ops.rs 87행) 또는 삭제 실패 집계 알림 패턴으로 알린다. 부분 성공이면 성공한 대상만 선택하고, 실패한 cut 항목은 `file_clipboard`에 남긴다(지금은 178행에서 전부 비운다).

### P1-2 AUDIT 4 (패널 쪽): 트리 열기·복사·이동을 백그라운드로
- 상태: todo · 담당: impl-ui · 리뷰: reviewer · 브랜치: work/ui
- 요구·결정: R-4, D-4 · 원문: AUDIT 4
- 범위: `src/ui/panel_nav.rs`(286행 `open_file` 주변), `src/ui/panel_ops.rs`(paste·duplicate의 복사·이동)
- 검증 수준: V1
- 할 일: 파일 IO를 `watch_io.rs`(200~240행)·`panel_delete.rs`(133행)의 background executor 패턴으로 옮긴다. 완료 때 workspace·요청이 아직 유효한지 확인하고 반영한다. 겹친 요청: 복사·이동은 서로 독립으로 돈다. 취소 UI 없음.
- 테스트: 무효 요청 결과를 버리는 테스트 1개 이상.

### P1-3 AUDIT 4 (탭 쪽): 큰 파일 첫 열기를 백그라운드로
- 상태: todo · 담당: impl-editor · 리뷰: reviewer · 브랜치: work/editor
- 요구·결정: R-4, D-4, D-10
- 범위: `src/ui/pane.rs`(`read_text`·`open`), 필요하면 `src/ui/mod.rs`의 호출부(공통 — lead 지정: 호출부만)
- 검증 수준: V1
- 할 일: `read_text`를 백그라운드로 옮긴다. 탭은 먼저 만들고 내용은 읽기가 끝나면 넣는다(`set_value`는 UI 스레드). 같은 탭에 열기 요청이 겹치면 마지막 요청 결과만 반영한다. 완료 전에 탭·workspace가 닫히면 결과를 버린다. 기존 해시(`hash`, D-046) 동작을 유지한다.
- 테스트: 겹친 열기에서 마지막 요청만 반영되는 테스트, 닫힌 탭 결과를 버리는 테스트.

### P1-4 남은 `Duration` 하드코딩을 metrics.rs 앱 상수로
- 상태: todo · 담당: impl-ui · 리뷰: review · 브랜치: work/ui
- 요구·결정: R-5, D-5
- 범위: `src/ui/metrics.rs`(이 카드에 한해 impl-ui에 지정), `src/fsops/watch.rs`, `src/state/mod.rs`, `src/ui/watch.rs`, `src/ui/watch_io.rs`, `src/ui/keymap.rs`, `src/ui/mod.rs`(타이머 리터럴만)
- 검증 수준: V0(값 불변)
- 할 일: 테스트 밖의 `Duration::from_*(<숫자 리터럴>)`과 모듈 로컬 Duration 상수를 `metrics.rs`로 옮기고 `// spec: none (app value)` 주석을 단다(Zed 원문 값이면 스펙 ID). 값은 그대로. 변수 인자(`from_millis(ms)`)는 대상 아님.
- 판정: grep 집계 명령과 결과 0건을 완료 보고에 적는다.

### P1-5 clippy 기준선 경고 0건
- 상태: todo · 담당: impl-ui(에디터 코어 파일 경고는 impl-editor) · 리뷰: review
- 요구·결정: R-6, D-5
- 검증 수준: V0(경고마다 동작 불변)
- 할 일: `cargo clippy --all-targets -- -D warnings` exit 0. `allow`로 숨기지 않는다.

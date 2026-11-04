> 버전: v0.4 · 작성일: 2026-11-04 · 상태: 진행 중
>
> 실제로 한 일과 검증 결과를 담는다. 계획은 `PLAN.md`에, 요구는 `SPEC.md`에 있다. 기존 기록은 지우지 않고 뒤에 더한다.

# PROGRESS — workbench-gpui v0.4

## Phase별 진행

### Phase 0 — 기준선과 새 화면 스펙

**P0-1 v0.4 기준선 (R-1)** (2026-11-04)
- 무엇을 했나: measure가 master에서 build·apply-manifest·test·clippy를 돌리고, v0.3 `run-p0-0c.ps1`을 경로만 바꾼 `run-baseline.ps1`로 v0.2 검증 스크립트 9개를 `-OutDir specs\v0.4\verify\baseline\<이름>`으로 1회씩 실행했다. 사용자 부재, 입력 없음, 실행 전 클립보드 비움.
- 결과

  | R-n | 항목 | v0.3 종료(기준) | v0.4 기준선 | 증거 |
  |---|---|---|---|---|
  | R-1 | 빌드 경고 | 0 | 0 | `verify/baseline/build.md`, `_build.log` |
  | R-1 | 테스트 | 60 통과 | 60 통과 / 0 실패 | `_test.log` |
  | R-1 | clippy 경고 | 10 | 10 | `_clippy.log` |
  | R-1 | 스크립트 8개(checks 배열) | 585 통과 / 2 실패 | 585 통과 / 2 실패 | `comparison.json`, 폴더별 `results.json` |
  | R-1 | phase1 | 9사례, failures 0 | 9사례, failures 0 | `verify-v02-phase1/` |
  | R-1 | 알려진 실패 phase3 R-28 | 300→375, 494→617 | 같음 | `README.md` |

- 검증: V3(스크립트 실행). measure 보고, reviewer 대조(`verify/reviews/phase0-final.md`). 앱 데이터 전후 파일 없음(`_backup/after.json` restored=true).
- 특이사항: d043-clip 미실행·휴지통 판정 불가는 v0.3과 같은 이유다. phase3 폭 실패 2건은 Phase 2(P4)에서 `sidebar["default_width"]` 300으로 맞출 대상이다(D-3).

**P0-2 새 화면 수치 스펙화 (R-2)** (2026-11-04)
- 무엇을 했나: spec이 탭·편집기 저장·분할·마크다운 미리보기·에디터 8건 관련 원문 절을 확인하고 `spec/zed-metrics.toml`에 없는 항목을 더했다(14줄). 이미 있는 항목은 ID만 확인했다. 동작 규칙은 `spec/INDEX.md`에 위치만 색인(4.4·4.12·13.4절 보강).
- 결과: 모호·추정 4건을 `spec/ambiguous.md`에 기록 — E-034 스크롤바 마커 개별 치수, E-012·D-10 한글 혼합 줄 기준선 허용치, I-713·I-842 분할 드롭 경계·우선순위, I-726·I-840 Pane 최소 드래그 크기.
- 검증: spec의 `tomllib` 파싱·필수 필드 검사. review 표본 대조 P0-3.
- 특이사항: 모호 4건은 Phase 2·4 카드에서 V3 실측으로 판정한다.

**P0-3 P0-2 표본 대조** (2026-11-04)
- 무엇을 했나: review가 5개 영역 22건을 원문과 대조했다.
- 결과: PASS(`verify/reviews/P0-3.md`).
- 검증: 원문 대조, `cargo test` 60 통과.
- 특이사항: 없음.

**Phase 0 종료** (2026-11-04, lead, 위임 H-4)
- 무엇을 했나: PLAN "Phase 종료 때". R-15는 Phase 0 제외. V3·V4 대상 없음(src 변경 없음). `/ponytail-debt` 대상 없음. reviewer 최종 판정.
- 결과: reviewer 1차 REWORK(이 PROGRESS 대조표 없음) → lead가 기록. src 변경 0.
- 검증: `git diff --stat` src 없음.
- 특이사항: 없음.

### Phase 1 — 정리: AUDIT 3·4, `Duration` 하드코딩, clippy

없음(시작 전).

### Phase 2 — Zed 일치: P4 UI 셸 ∥ P5 에디터 코어

없음(시작 전).

### Phase 3 — 탭 편집과 저장

없음(시작 전).

### Phase 4 — PoC 6단계 탭 기능

없음(시작 전).

## 사용자 요청 작업

### v0.4 herdr 재구성 (2026-11-04)

- 요청: "현재 herdr 워크스페이스에서 lead 에이젼트만 남기고 탭패널을 초기화 하고, herdr 환경을 v0.4 용으로 다시 구성해 주세요."
- 조치
  - v0.3 verify 탭(review·measure·reviewer)과 wt-ui 워크스페이스(impl-ui)를 닫았다.
  - `.worktrees\ui`의 `work/ui`를 master로 fast-forward했다.
  - `specs/v0.4/HERDR-SETUP.md`·`HERDR-DECISIONS.md`를 쓰고, 루트 `AGENTS.md`의 경로를 v0.4로 바꿨다(커밋 `33238fe`).
  - control 탭에 spec, verify 탭에 reviewer·review·measure, wt-ui에 impl-ui(agy)를 띄우고 역할 확인 프롬프트를 보냈다.
- 결과: 에이전트 6개(lead 포함)가 역할을 확인하고 대기 중이다. impl-editor는 카드가 생길 때 띄운다.
- 검증: `herdr agent list`(이름·pane·상태), 각 에이전트의 확인 응답 `herdr agent read`. reviewer 상태줄 "GPT-6.1-Sol medium · 5h 99% left · weekly 28% left".
- 상태: 완료

### v0.4 버전 문서 초안 (2026-11-04)

- 요청: "v0.4 문서 초안 작성해 주세요"
- 조치: `specs/v0.4/` INTENT·DECISIONS·SPEC·PLAN 초안과 이 PROGRESS를 썼다. 범위·순서·리뷰 분담은 사용자 선택(2026-11-04)을, 절 구성은 project-workflow-compact `DOCUMENTS.md` 4~8절을 따랐다.
- 결과: 초안. 정해지지 않은 것은 DECISIONS "미결 사항"에 "미정"으로 두었다.
- 검증: 다시 읽어 한글 깨짐 확인.
- 상태: 확정 (사용자 "확정하고 커밋해 주세요", 2026-11-04)

### v0.4 미결 사항 9개 결정 (2026-11-04)

- 요청: "미결 사항 하나씩 질문해 주세요"
- 조치: 9개를 하나씩 물어 답을 받고 DECISIONS(D-3·D-4·D-5·D-6·D-7·D-8, 새 D-10)·SPEC(R-4·R-7·R-8·R-10·R-13·R-14·R-15)·PLAN·INTENT·HERDR-SETUP 4장에 반영했다.
  - AUDIT 4 겹침: 마지막 요청만 반영 / 앱 시간 값: metrics.rs 앱 상수 / 오차 안 불일치: 맞춘다 / 탭 편집기: gpui-kit Editor 유지 / 직접 구현: 표시 4·스크롤바 2·입력 2 / 인코딩: 원래 인코딩 보존 + 3건 / 분할: Zed 원문 전부 / 마크다운: gpui-component 렌더 + Zed 스타일 / 흔들리는 값: 통과 여부만 대조
  - 초안 D-6의 "`editor_poc.rs`의 에디터 코어"는 잘못된 표현이라 고쳤다. `editor_poc.rs`는 gpui-kit Editor를 재는 디버그 측정 화면이다.
- 결과: v0.4 미결 0. 에디터 코어 담당 경로가 `pane.rs`·탭 편집 새 모듈·`editor_poc.rs`로 바뀌었다(D-10).
- 검증: 문서 안 "미정"이 남은 곳이 지난 버전에서 이어진 미결뿐인 것을 grep으로 확인.
- 상태: 확정 (사용자 "확정하고 커밋해 주세요", 2026-11-04)

## 버전 종료

진행 중.

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

**P1-1 AUDIT 3 + P1-2 AUDIT 4 패널 쪽 (R-3·R-4)** (2026-11-04)
- 무엇을 했나: impl-ui가 `panel_ops.rs`에서 붙여넣기·복제 일반 실패를 기존 `notify`로 알리고(`Failed to {copy|move|duplicate} N of M file(s).`), 실패한 cut 항목만 클립보드에 남기게 했다(P1-1 `60857e6`). 붙여넣기·복제의 복사·이동을 `panel_delete.rs` 패턴의 백그라운드 작업으로 옮겼다(P1-2 `a88b78c`).
- 결과: reviewer REWORK 3회 → R3 PASS(`verify/reviews/P1-1-2.md`).
  - R0: 같은 볼륨 동시 이동이 목적지를 덮어씀(파일 손실), 오래된 작업이 최신 cut 복원 권한을 가져감, 완료 경로 테스트 없음.
  - R1(`b9b699b`): 이동 전역 잠금, 클립보드 세대 토큰(해소). 복사·이동 사이 내부 경합과 이동 전체 잠금이 남음.
  - R2(`5e6b62a`, H-9): 잠금을 이름 선택·예약/rename으로 좁히고 복사도 같은 잠금 사용, 완료 결정을 순수 `plan` 함수로 빼서 #[test](해소). 교차 볼륨 재귀 검사가 잠금 안에 남음.
  - R3(`2916ac2`): 교차 볼륨 `tree_summary`·링크 검사를 잠금 밖으로(해소).
- 검증: V1. 추가 테스트(동시 이동 보존, 복사 예약 뒤 이동, 교차 볼륨 사전 검사 중 다른 작업 진행, plan 5종) 통과.
- 특이사항: `#[gpui::test]`는 Cargo test-support 추가가 필요해 위임 밖이라 순수 함수 테스트로 대신했다(H-9). 외부 프로그램과의 이름 경합은 `shortcut:`(`panel_ops.rs:138`). 실제 다른 볼륨 장치로의 이동은 실행 확인하지 못했다(사용자 확인 목록).

**P1-3 AUDIT 4 탭 쪽 (R-4)** (2026-11-04)
- 무엇을 했나: impl-editor가 `pane.rs`의 탭 첫 열기를 백그라운드 읽기로 바꿨다(`777abe1`). 탭은 바로 만들고 내용은 읽기가 끝나면 UI 스레드에서 넣는다.
- 결과: reviewer REWORK 1회 → R1 PASS(`verify/reviews/P1-3.md`). R0 지적: 첫 읽기와 감시 reload 경합, 폴더 해제 뒤 결과 적용. R1(`0ca9d44`, H-7): 첫 읽기와 reload가 탭별 최신 토큰 공유, 폴더 해제 때 `pane.close()`.
- 검증: V1. 테스트 5개(임시 탭 교체, 닫힌 탭, 늦은 첫 읽기, 빈 파일 Same, 닫힌 pane) 통과.
- 특이사항: 큰 파일을 열 때 빈 편집기가 잠깐 보인다(로딩 표시 없음) — 사용자 확인 목록(V4).

**P1-4 `Duration` 하드코딩 (R-5)** (2026-11-04)
- 무엇을 했나: impl-ui가 테스트 밖 `Duration::from_*` 리터럴과 모듈 로컬 Duration 상수 14개를 `metrics.rs`의 `timing` 앱 상수(`// spec: none (app value)`)로 옮겼다(`c6522ce`, `5ddb8d5`). 값은 그대로.
- 결과: review PASS(`verify/reviews/P1-4.md`). grep 집계 metrics.rs 밖 0건.
- 검증: V0. 값 하나씩 대조, build·clippy·test 통과.
- 특이사항: agy 한도 소진으로 도중에 impl-ui를 Claude Code로 바꿨다(H-8). `fsops` → `ui::metrics` 의존이 새로 생겼다(D-5대로, 사용자 확인 목록).

**P1-5 clippy 기준선 경고 0건 (R-6)** (2026-11-04)
- 무엇을 했나: impl-ui가 기준선 경고 10개를 동작 불변으로 고쳤다(`3f41bc8`). 새 `allow` 없음.
- 결과: review PASS(`verify/reviews/P1-5.md`). `cargo clippy --all-targets -- -D warnings` exit 0.
- 검증: V0.
- 특이사항: 루트 `AGENTS.md` 2장의 "Phase 0 기준선 clippy 경고는 기록만" 예외를 없앴다(PLAN Phase 1 완료 조건, 위임 H-4로 lead 반영).

병합: work/editor → master `1e6d76d`, work/ui → master `99ec7dc`. `Cargo.*` 변경 없음.

**P1-E Phase 1 끝 R-15 회귀 대조** (2026-11-04)
- 무엇을 했나: measure가 master `99ec7dc`에서 v0.2 검증 스크립트 9개를 1회씩 돌리고(`verify/baseline/phase1/`), R-1 기준선과 항목 단위로 대조했다. reviewer 최종 확인 REWORK(값 비교 누락) 뒤 저장된 결과로 `got` 값까지 다시 대조했다(P1-E-R1, H-10).
- 결과

  | R-n | 스크립트·사례·항목 | 기준선(R-1) | Phase 1 | 의도한 변경 여부 | 증거 |
  |---|---|---|---|---|---|
  | R-15 | 9개 통과/실패 합계 | 585 / 2(phase1 9사례 0) | 585 / 2(phase1 9사례 0) | 같음 | `verify/baseline/phase1/README.md`, `comparison.json` |
  | R-15 | phase3 / scroll / A-16.7 | `offset_y=-23` | `offset_y=-234` | 아님. 이력상 흔들림(v0.2·v0.3 같은 코드에서 −23/−234 교대) | 같은 README ①, H-10 |
  | R-15 | phase5 / flood / R-24 이벤트 수 | 1815 | 1811 | 아님. 이력상 흔들림(1811~1831) | README ②③ |
  | R-15 | phase3 R-28 시작·복원 폭 | 375·617(실패) | 375·617(실패) | 같음(Phase 2 P2-1 대상) | README |

  - 의도한 변경 목록(Phase 1): AUDIT 3 실패 알림·실패 cut 항목 보존, AUDIT 4 붙여넣기·복제·탭 첫 열기 백그라운드. 이 스크립트들의 판정에는 나타나지 않았다(새 동작은 V1 테스트로 검증).
  - 값이 다른 항목 3건 = 이력상 흔들림 3, 의도한 변경 0, 미설명 0. 시간 값만 다른 항목은 스크립트 자체 판정으로만 대조(D-8).
- R-5 집계(master `99ec7dc`): `rg -n 'Duration::from_[a-z]+\([0-9_]+\)' src --glob '!**/metrics.rs'` → 원시 10줄. `src/fsops/ops.rs:404` 1줄과 `src/fsops/watch.rs:238,243,296,314,329,330,332,333,340` 9줄로, 모두 각 파일의 `#[cfg(test)] mod tests` 안이다(판독, reviewer 재현). 테스트 모듈을 빼면 운영 코드 0건이다. R-5는 "테스트를 뺀 `src/`"를 대상으로 한다.
- R-6: `cargo clippy --all-targets -- -D warnings` exit 0(reviewer 최종 확인).
- 검증: V3(스크립트 실행), reviewer 판정.
- 특이사항: V3 UI 실측 대상 없음(Phase 1은 레이아웃·수치 변경 없음, 알림은 기존 notify 재사용).

**Phase 1 종료** (2026-11-04, lead, 위임 H-4)
- 무엇을 했나: PLAN "Phase 종료 때". R-15(P1-E), V3 대상 없음, `/ponytail-debt`(`shortcut:` 3건: `fsops/ops.rs:155` 예약 뒤 외부 쓰기, `fsops/ops.rs:305` 삭제 직전 비교 뒤 변경, `ui/panel_ops.rs:138` 외부 프로그램 이름 경합 / tools/measure 4건은 v0.3과 같음), reviewer 최종 확인.
- 결과: 최종 확인 REWORK 2회(R-15 값 비교 누락·PROGRESS 대조표 누락 → R1, R-5 집계 줄 오류 → R2) → R2 PASS(`verify/reviews/phase1-final.md`). 전체 테스트 78 통과, clippy `-D warnings` 통과. 루트 `AGENTS.md` 2장 clippy 예외 삭제.
- 검증: reviewer 판정.
- 특이사항: 사용자 확인 목록 — H-8(impl-ui를 Claude Code로 교체, Claude 부담 증가), `fsops`→`ui::metrics` 의존, H-10(위치 표본 흔들림 분류), 큰 파일 열 때 빈 편집기 잠깐 보임(V4), 교차 볼륨 이동 실기 확인 안 됨.

### Phase 2 — Zed 일치: P4 UI 셸 ∥ P5 에디터 코어

**P2-0 시작 V3 실측 (D-3)** (2026-11-04)
- 무엇을 했나: measure가 master `cf3a82d` 빌드의 사본 exe(H-11)로 UI 셸·에디터 영역을 1회 실행해 실측했다(`verify/reviews/measure-p2-0.md`, 증거 `p2-0-measure/`).
- 결과: 불일치 FAIL 2(`sidebar["default_width"]` 300→375, `editor["line_height.comfortable"]` 24.27→20), 오차 안 4(`sidebar["footer.height"]` 30→31, `menu["item.line_height"]` 22.652→23, `editor["cursor_width"]` 2→1, `editor["line_height.standard"]` 19.5→20). 편집기 글꼴은 진행 폭으로 약 12px(스펙 15) 관찰. 그 밖의 UI 셸 항목 PASS.
- 검증: V3. 첫 시도는 공유 exe가 master 빌드인지 증명할 수 없어 폐기했다(H-11).
- 특이사항: 없음.

**P2-1 사이드바 폭·푸터 (R-7, Q-15)** (2026-11-04)
- 무엇을 했나: impl-ui가 원인을 찾았다 — `resizable_panel`의 기본 `flex_grow`로 사이드바가 basis보다 커졌다. `.flex_none()`으로 고치고 `sidebar["footer.height"]` 30을 적용했다(`2be8a9a`). 레이아웃 테스트 `sidebar_metrics_equal_spec_exactly`.
- 결과: review PASS(`verify/reviews/P2-1.md`).
- 검증: V2.
- 특이사항: v0.3부터 이어진 phase3 R-28 폭 실패 2건(375·617)의 원인이다. P2-E R-15에서 통과로 바뀌는지 본다.

**P2-2 메뉴 행·탭 내용 높이 (R-7)** (2026-11-04)
- 무엇을 했나: impl-ui가 코드 값이 스펙과 같음을 확인하고(메뉴 행 22.652는 렌더 반올림으로 23, 탭 바깥 박스 32는 기록만 항목) 값을 고정하는 테스트만 더했다(`309c9f3`).
- 결과: review PASS(`verify/reviews/P2-2.md`).
- 검증: V2.
- 특이사항: 메뉴 행 높이 23은 렌더 반올림이라 코드로 맞출 대상이 아니다.

**P2-5 에디터 표시 + 스크롤바, P2-6 에디터 입력, P2-7 글꼴·줄 높이 (R-8, D-10)** (2026-11-04)
- 무엇을 했나: impl-editor가 gpui-kit Editor 위에 스크롤바 트랙 폭 15(`3d14c03`, `set_scrollbar_renderer`), Ctrl+Shift 드래그 열 선택(`72043ac`, Alt+Shift로 바꿔 다시 보냄), 재전송 뒤 실제 수정키 복원(`cc7c902`), 탭 편집기 글꼴 15·줄 높이 1.618배(`f0c7c62`)를 넣었다.
- 결과: P2-5·P2-6 reviewer REWORK 1(재전송한 Alt+Shift가 창 수정키 상태에 남음) → R1 PASS(`verify/reviews/P2-5-6.md`). P2-7 review PASS(`verify/reviews/P2-7.md`).
- 검증: V1·V2. 순수 함수 테스트(H-9).
- 특이사항 — D-10 8건 가운데 2건 완료, 6건 보류(사용자 결정 필요, R-8 일부 미충족):

  | 항목 | 상태 | 막힌 곳 | 가능한 길 |
  |---|---|---|---|
  | 줄 번호 최소 4자리 | 보류 | gpui-kit 비공개 상수 `MIN_LINE_NUMBER_DIGITS = 3` | gpui-kit 설정 요청·버전 변경, 또는 거터 직접 그리기 |
  | 커서 2px | 보류 | gpui-kit 커서 폭 고정, 훅 없음 | 같음 |
  | 선택 모서리 0.15×줄 높이 | 보류 | `element.rs` 3349~3360 직선 PathBuilder, 모양 훅 없음 | 같음, 또는 선택 직접 그리기 |
  | 한글 혼합 줄 기준선 | 보류 | 허용치 모호(`spec/ambiguous.md` E-012), 기준선 API 없음 | 허용치 결정 뒤 기능 요청, Zed 글꼴 도입 때 재측정 |
  | 스크롤바 15 | 완료 | — | — |
  | 스크롤바 마커 | 보류 | 치수 모호(`spec/ambiguous.md` E-034). 그릴 자리(렌더러 훅)는 있음 | spec이 치수를 정하면 추가 |
  | Ctrl+Shift 열 선택 | 완료 | — | — |
  | 선택 끌어 옮기기 | 보류 | E-049 300ms가 toml에 없음, 위치→오프셋 공개 API 없음 | 스펙 값 추가 + gpui-kit API 요청 |

  위임(H-4) 안에서는 gpui-kit 교체·`Cargo` 변경·직접 렌더 재구현을 하지 않는다.

병합: work/editor → master `b7ae2f7`, work/ui → master `df280c5`. `Cargo.*` 변경 없음.

**P2-1-R1 사이드바 폭 실제 원인 (R-7)** (2026-11-04)
- 무엇을 했나: P2-E 실측에서 병합 뒤에도 시작 폭이 375였다(P2-1의 `flex_none`은 원인이 아니었다). impl-ui가 원인을 찾았다 — 창이 처음 작게 열린 뒤 최대화될 때 resizable 패널이 컨테이너 크기 변화에 비례해 다시 커졌다(1920/1536 = 1.25). 사이드바 패널을 고정(fixed)으로 바꿨다(`e02a6f8`).
- 결과: measure 좁은 V3(`verify/reviews/measure-p2-1-r1.md`): S1·S2 폭 300, phase3 122/0(R-28 시작 300, 복원 419/419). review R1 PASS(`verify/reviews/P2-1.md`).
- 검증: V3(실행 확인). 레이아웃 경로 단위 테스트는 gpui 컨텍스트가 필요해 만들지 못했다(H-9).
- 특이사항: 단위 테스트가 상수만 보고 실제 경로를 못 잡은 사례다. 실측(V3)으로 잡았다.

**P2-E Phase 2 끝 R-15 회귀 대조와 V3** (2026-11-04)
- 무엇을 했나: measure가 master `df280c5`에서 R-15와 불일치 항목 V3 재측정(`verify/reviews/measure-phase2.md`)을 하고, 사이드바 rework 병합 뒤 master `63710c0`에서 R-15를 다시 돌렸다(`verify/baseline/phase2b/`). 사본 exe(H-11).
- 결과

  | R-n | 스크립트·항목 | 기준선(R-1) | Phase 2(`63710c0`) | 의도한 변경 여부 | 증거 |
  |---|---|---|---|---|---|
  | R-15 | 9개 합계(checks 8개) | 585 / 2 | **587 / 0** | phase3 R-28 2건이 통과로 — 의도한 변경 | `phase2b/README.md`, `comparison.json` |
  | R-15 | phase3 state R-28 시작 폭 | 375(실패) | 300(통과) | 의도한 변경 | README #1 |
  | R-15 | phase3 state-restart R-28 복원 폭 | 617(실패, 기대 494) | 419(통과, 기대 419) | 의도한 변경(기대값이 시작 폭+119라 함께 바뀜) | README #2·#3 |
  | R-15 | phase2 툴팁 x 6건, 메뉴 I-314, phase3 A-11.3, phase4 2건 | — | 모두 정확히 −75 | 의도한 변경의 결과(사이드바 폭을 따라 이동) | README #4~ |
  | R-15 | phase3 A-16.7, phase5 flood 2건 | — | — | 이력상 흔들림(H-10) | README |

  - 값이 다른 항목 16건 = 의도한 변경 13, 이력상 흔들림 3, **미설명 0**.
  - V3 재측정(`measure-phase2.md`, `df280c5` 기준): `sidebar["footer.height"]` 30 PASS. `editor["line_height.comfortable"]` 24(24.27의 렌더 반올림, 39줄 모두 24), `menu["item.line_height"]` 23(22.652의 렌더 반올림) — 코드 값은 스펙과 같아 맞출 수 없다. `editor["cursor_width"]` 1(D-10 보류). 편집기 글꼴은 글자 진행 폭이 8.2px로 늘어 15px 적용과 맞다(기록만). 스크롤바 썸 중심이 폭 15 트랙 중심과 ±1(트랙은 배경색이라 기록만). 사이드바 300은 `measure-p2-1-r1.md`로 PASS.
- R-16(1차, reviewer REWORK): 스펙 ID 상수 테스트(`sidebar_metrics_equal_spec_exactly`, P2-2 테스트, `editor_font_and_line_height_are_spec`, `editor_scrollbar_width_is_spec`)는 상수만 비교해 렌더 경로 회귀를 잡지 못한다(P2-1이 그 예). 그래서 실제 렌더 경로 자동 검사로 옮겼다.
- R-16(P2-R16): `tools/measure/check-layout.ps1` — 앱을 `--dev-layout`으로 1회 띄워 작은 창(1536x1080) → 최대화 경로의 덤프를 `spec/zed-metrics.toml`과 비교, 28항목(titlebar·window border·sidebar·dock·project_panel·statusbar·buttons·icons), FAIL이면 exit 1. master `63710c0` 28/28 PASS, P2-1-R1 이전 `df280c5`에서 `sidebar["default_width"]` 375 FAIL로 회귀 검출(`verify/reviews/check-layout.md`). D-3 정확 비교 항목은 허용 오차 없이 판정(P2-R16-R1). 적용 범위 밖: 폴더 등록 뒤 화면, 탭·툴팁·메뉴·입력칸, 에디터 줄 높이·글자 폭·커서·스크롤바(덤프 probe 없음) — 상수 테스트와 V3로 남는다.
- 검증: V3(스크립트 실행·실측).
- 특이사항: R-8은 2/8만 충족, 6건 사용자 결정 대기(H-14, 위 표).

**Phase 2 종료** (2026-11-04, lead, 위임 H-4)
- 무엇을 했나: PLAN "Phase 종료 때". R-15(P2-E·P2-E-R1), V3(measure-p2-0·measure-phase2·measure-p2-1-r1), R-16 자동 검사(check-layout), `/ponytail-debt`(새 `shortcut:` 없음, Phase 1과 같음), reviewer 최종 확인.
- 결과: 최종 확인 REWORK 2회(R-16 상수 테스트만으로 렌더 경로 회귀를 못 잡음 → check-layout 실제 렌더 검사, 허용 오차 1px이 푸터 31을 놓침 → exact 비교) → R2 PASS(`verify/reviews/phase2-final.md`). 전체 테스트 85, clippy `-D warnings` 통과. 커밋 `20cc514`, 태그 `v0.4-phase-2`.
- 검증: reviewer 판정.
- 특이사항: 사용자 확인 목록 — R-8 보류 6건(H-14), 렌더 반올림 2건(에디터 줄 높이 24.27→24, 메뉴 행 22.652→23), 저장 때 줄 끝 공백 제거·마지막 줄바꿈(04-APP-SPEC 4.2)을 D-6에 따라 넣지 않음.

### Phase 3 — 탭 편집과 저장

Phase 2 종료 전에 편집기 카드 P3-1·P3-2를 work/editor에서 먼저 시작했다(H-12). 병합은 Phase 2 태그 뒤에 했다.

**P3-1 편집 허용·수정 상태 + P3-2 저장과 인코딩 왕복 (R-9·R-10)** (2026-11-04)
- 무엇을 했나: impl-editor가 탭 Editor의 읽기 전용을 풀고 dirty 상태를 두었다(`209ff95`). `src/dev.rs`의 `decode`·`encode`(UTF-8/BOM, UTF-16 LE/BE, CP949 Win32 FFI)를 `src/text_io.rs`로 옮겨 저장(`workspace::Save`, Ctrl-S)에 썼다(`56da5a0`). Save 액션·바인딩 세 줄은 impl-ui 소유 키맵 파일에 넣었다(H-13).
- 결과: reviewer REWORK 2회 → R2 PASS(`verify/reviews/P3-1-2.md`).
  - R0: 교체 실패(ReplaceFileW 1176) 때 원본과 임시본을 모두 잃을 수 있음, 저장과 읽기 토큰이 따로라 저장 뒤 오래된 읽기 적용, CRLF 파일에 LF가 섞임.
  - R1(`fe10562`): 대상이 사라지면 임시본을 남기고 경로를 알림, 저장·읽기 토큰 공유, 열 때 줄 끝 기억. 혼합 줄 끝 파일은 무편집 저장도 통일되는 문제가 남음.
  - R2(`8441ace`, H-15): 깨끗한 탭은 저장 때 쓰지 않음, 편집한 혼합 파일은 주된 줄 끝으로 통일(`shortcut:`).
- 검증: V1. 왕복 바이트(UTF-8 LF·CRLF, BOM, UTF-16 LE, CP949), CP949 손실 거부, 교체 실패 주입, 저장·읽기 순서 테스트.
- 특이사항: 앱 내부 문자열이 LF 기준이 되어 v0.2 phase5 스크립트의 CRLF fnv 비교가 달라진다(의도한 변경). 저장 때 줄 끝 공백 제거·마지막 줄바꿈은 D-6에 따라 넣지 않았다(사용자 결정).

**P3-4a 디스크 충돌·지워진 파일 상태 (R-11)** (2026-11-04)
- 무엇을 했나: impl-editor가 dirty 버퍼의 디스크 변경을 충돌 상태로, 열린 파일 삭제를 지워짐 상태로 두었다(`f973dcf`).
- 결과: reviewer REWORK 1 → R1 PASS(`verify/reviews/P3-4a.md`). R0: 충돌 중 undo로 거짓 깨끗함, 정규화 텍스트 해시로는 인코딩·BOM·줄 끝 외부 변경을 못 잡음, 상태만 바뀐 경로의 갱신 누락. R1(`d76c516`, H-18): 디스크 원본 바이트 해시로 변경 판정, undo 뒤 충돌 유지, notify.
- 검증: V1.
- 특이사항: mtime이 아니라 바이트 해시라, 같은 내용으로 덮어쓰면 변경으로 보지 않는다(Zed와 다를 수 있음, 사용자 확인 목록).

**P3-3 탭 닫기·저장 질문·저장 확인창 (R-10)** (2026-11-04)
- 무엇을 했나: impl-ui가 탭 닫기(`pane::CloseActiveItem`, 닫기 버튼), dirty 탭을 닫거나 창을 닫거나 종료할 때 저장 질문(저장·버리기·취소), 저장 때 확인창(E-084·E-085)을 넣었다(`ca5afb4`, `src/ui/tab_close.rs`). 판단 항목은 H-17(종료 때 질문 유지, 기본 Cancel).
- 결과: reviewer REWORK 3회 → R3 PASS(`verify/reviews/P3-3.md`).
  - R0: 저장 성공 뒤 새 편집이 있어도 닫힘, 저장 중 dirty가 풀리면 기다리지 않고 닫힘, 저장 전 충돌 검사 기준 불일치.
  - R1(`fd75432`): 닫기 직전 재판정, 진행 중 저장 대기, 원본 바이트 기준. 끝나지 않는 저장을 기다리는 닫기에서 빠져나올 수 없음.
  - R2(`920f05d`): 대기 상한 10초(앱 값) 뒤 닫기 요청만 취소. 닫기 질문에서 시작한 저장에는 상한이 안 걸림.
  - R3(`c3dc9cb`): 그 저장도 독립 작업으로 돌리고 같은 대기 경로에 상한 적용.
- 검증: V1. 순수 판단 함수 테스트(여러 탭 종료 재조사 시나리오 포함).
- 특이사항: 종료 때 미저장 내용 복원(A-25.8·I-118)은 PoC 8단계라 넣지 않고 질문으로 둔다(H-17, 스펙 불일치·사용자 확인 목록).

**P3-4b 탭 표시: 수정 점·충돌·지워짐 (R-9·R-11)** (2026-11-04)
- 무엇을 했나: impl-ui가 dirty 탭 수정 점(L-65, `b6526ee`)과 충돌 점 Warning 색·지워진 파일 취소선(E-086·E-087, `c08dd44`)을 그렸다.
- 결과: P3-4b-1 review PASS(`verify/reviews/P3-4b-1.md`), P3-4b-2 reviewer PASS(`verify/reviews/P3-4b-2.md`).
- 검증: V2. 첫 구현 V3는 P3-E.
- 특이사항: 없음.

병합: work/editor → master `646c513`(P3-1·P3-2), `d16f0cb`(P3-4a), work/ui → master `37be418`(P3-3·P3-4b). `Cargo.*` 변경 없음.

**P3-E Phase 3 끝 R-15·check-layout·V3** (2026-11-04)
- 무엇을 했나: measure가 master `37be418` 사본 exe로 v0.2 검증 스크립트 9개(원본), check-layout, 새 화면 V3를 했다(`verify/reviews/measure-phase3.md`, `verify/baseline/phase3/`). phase2 원본 스크립트가 새 File 메뉴 행에서 중단해 생긴 공백은 v0.4 사본(`verify/scripts/verify-v04-phase2.ps1`, 원본 대비 3곳·6줄, H-21)으로 다시 돌려 메웠다(P3-E-R1).
- 결과

  | R-n | 스크립트·항목 | 기준선(R-1) | Phase 3 | 의도한 변경 여부 | 증거 |
  |---|---|---|---|---|---|
  | R-15 | phase1 내장 바인딩 R-1 표 밖 3건 | 없음 | `ctrl-s` Save, `ctrl-w`·`ctrl-f4` CloseActiveItem | 의도한 변경(P3-2·P3-3 키) | measure-phase3 F1 |
  | R-15 | phase2·phase3 File 메뉴 | `Open Folder… ─ Close Window` | `… ─ Close Editor\|Ctrl-F4  Close Window` | 의도한 변경(P3-3) | F2·F4 |
  | R-15 | phase2 메뉴 48항목·뒤 사례 11개 | 137/0 | v0.4 사본 137/137, 값 R-1과 같음(사이드바 −75 결과 제외) | — | R1 절 |
  | R-15 | phase4 readonly(D-18 탭 보기 전용) | 글자 안 들어감 | 글자 들어감, 디스크 그대로 | 의도한 변경(D-6 탭 편집 허용) | F5 |
  | R-15 | phase5 tab CRLF 파일 len·fnv 5건 | CRLF 기준 | LF 기준(len −2 등) | 의도한 변경(내부 LF 정규화, D-6·H-15). reload 자체는 일어남 | F6~F10 |
  | R-15 | 그 밖의 값 차이 | — | 사이드바 −75 결과·이력상 흔들림(H-10) | 의도한 변경의 결과 / 흔들림 | 1.2절 |

  - 미설명 0, 실제 회귀 0.
- check-layout: 28/28 PASS(허용 오차 0).
- V3 새 화면(첫 구현): `tab["indicator_size"]` 수정 점 10×10 PASS, 슬롯 위치 PASS, 저장 질문 대화창 문구·버튼 순서(Save / Don't Save / Cancel) PASS, 충돌 점 Warning 색(수정 점과 구별) PASS, 지워진 파일 취소선 PASS. 불일치 0, 측정 불가 1(수정 점 Accent 색 값 — 스펙 toml에 색 값 없음, `theme.primary` 근사).
- 검증: V3(스크립트 실행·실측).
- 특이사항: 사용자 확인 목록 — 수정 점 색(23,23,23 근사)과 Warning 색(234,179,8)이 Zed와 같은지. v0.2 phase2 원본 스크립트는 계속 실패한다(새 메뉴 행). 이후 R-15는 v0.4 사본을 쓴다(H-21).

**P3-F1 Phase 3 최종 확인 REWORK 수정 (R-10)** (2026-11-04)
- 무엇을 했나: reviewer 최종 확인(`37be418`)이 통합 코드에서 데이터 보존 경계 2건을 찾았다 — 저장 중 앱 내부 rename/move 뒤 다른 경로에 쓴 결과로 탭을 clean 처리, 삭제된 비어 있지 않은 미리보기 탭을 다음 미리보기 열기가 질문 없이 버림. work/editor·work/ui에 Phase 4 커밋이 이미 있어 master 기준 `work/p3fix` 브랜치에서 impl-editor가 고쳤다(H-23): `9321613`(저장 경로가 같을 때만 기준 갱신, 보존할 미리보기는 일반 탭으로 승격), `72c3ac7`(저장 중 경로가 바뀌면 완료 때 dirty=true·기준 해시 확정 불가).
- 결과: 최종 확인 R1 REWORK(저장 중 undo + rename 순서의 거짓 clean) → R2 PASS(`verify/reviews/phase3-final.md`). master `63b7cd2`.
- 검증: V1(순서 회귀 테스트). R-15·V3는 `37be418` 결과를 그대로 쓴다 — 수정이 저장·rename 경로의 상태 판정에 한정되고 화면·키·메뉴를 바꾸지 않으며 회귀 테스트와 reviewer 재확인으로 덮였다(lead 판단, 위임 H-4).
- 특이사항: 없음.

**Phase 3 종료** (2026-11-04, lead, 위임 H-4)
- 무엇을 했나: PLAN "Phase 종료 때". R-15·check-layout·V3(P3-E, P3-E-R1), `/ponytail-debt`(새 `shortcut:`: 혼합 줄 끝 통일 H-15, 미리보기 종료 시 포커스 등), reviewer 최종 확인.
- 결과: 최종 확인 REWORK(데이터 보존 2건) → P3-F1 → R1 REWORK → R2 PASS. 전체 테스트 134 통과(37be418 기준), clippy `-D warnings` 통과. 태그 `v0.4-phase-3`.
- 검증: reviewer 판정.
- 특이사항: 사용자 확인 목록 — 종료 때 저장 질문(복원 대신, H-17), 바이트 해시 기준 충돌(H-18), 혼합 줄 끝 통일(H-15), 저장 때 공백 제거·마지막 줄바꿈 미적용, 수정 점·Warning 색.

### Phase 4 — PoC 6단계 탭 기능

Phase 3 종료 전에 P4-1·P4-3(work/editor, H-19)과 P4-2·P4-3b·P4-4·P4-5(work/ui, H-22)를 먼저 진행했다. master 병합은 Phase 3 태그 뒤에 했다.

**P4-1 미리보기 탭·핀 모델 (R-12)** (2026-11-04)
- 무엇을 했나: impl-editor가 `pane.rs` 탭 모델을 원문 I-060~I-066 전부로 넓혔다(`fb6e149`). 탭 한 번 누르기로는 승격하지 않는다(원문 I-063, 카드 문구와 다름).
- 결과: reviewer PASS(`verify/reviews/P4-1.md`).
- 검증: V1(항목 ID별 테스트).
- 특이사항: 없음.

**P4-3 분할 모델 (R-13)** (2026-11-04)
- 무엇을 했나: impl-editor가 workspace의 단일 Pane을 Pane 트리(`src/ui/pane_group.rs`)로 바꾸고 분할 방식 ClonePane·EmptyPane·MovePane, 크기 조절·확대 상태, 같은 파일 여러 뷰 동기화를 넣었다(`ba2c2f6`). 6개 파일의 `.pane` 호출부 교체는 H-20으로 impl-editor 범위.
- 결과: reviewer REWORK 2회 → R2 PASS(`verify/reviews/P4-3.md`). R0: 세 번째 뷰가 비어 있음, 읽기 중 rename, 중첩 축 최소 크기, 동기화 판단 테스트 부족. R1(`a00a23d`): 셋 해소. R2(`f07801f`): 불균등 하위 비율의 최소 크기.
- 검증: V1.
- 특이사항: pane이 닫히면 트리에서 인접 pane으로 포커스(Zed는 마지막 포커스 pane) — `shortcut:`.

**P4-2 탭 바 미리보기·핀 + P4-3b 분할 그리기 (R-12·R-13)** (2026-11-04)
- 무엇을 했나: impl-ui가 미리보기·핀 탭 표시와 입력 연결(`ecbddb0`), Pane 트리 그리기·분할선 드래그·확대·분할 키와 버튼(`6ec2df9`)을 넣었다.
- 결과: reviewer REWORK 1 → R1 PASS(`verify/reviews/P4-2-3b.md`). R0: 빈 영역 클릭의 포커스 불일치, Pin/Unpin 컨텍스트 메뉴 없음, 새 키가 Workspace 전체에 등록됨, 분할·확대 메뉴 숨김. R1(`7a2d3ce`).
- 검증: V1.
- 특이사항: 없음.

**P4-4 탭 드래그 + P4-5 마크다운 미리보기 (R-13·R-14)** (2026-11-04)
- 무엇을 했나: impl-ui가 탭 끌어 순서 바꾸기·pane 옮기기·가장자리 분할(`6310856`), 마크다운 미리보기 탭과 툴바 버튼(`8532d71`, gpui-component `TextView::markdown`, 새 의존성 없음)을 넣었다.
- 결과: reviewer REWORK 2회 → R2 PASS(`verify/reviews/P4-4-5.md`). R0 5건 처리는 H-24 — Ctrl 복제 드롭·옆 pane 원문 복귀·테스트 보강은 고침(`692cdde`), 프로젝트 패널 드래그로 열기(I-721·I-722)는 INTENT 제외 범위라 넣지 않음, frontmatter(L-110·L-111)는 공개 hook으로 맞춤. R1: frontmatter 빈 줄·이동 뒤 상태 테스트 → R2(`85e7c86`).
- 검증: V1.
- 특이사항: 사용자 확인 목록 — I-721·I-722(INTENT 제외 범위와 분할 결정의 충돌), 마크다운 근사 처리 2건(키 셀 배경색, frontmatter 코드 상자 배경·글꼴).

**병합과 충돌 해결** (2026-11-04)
- master(Phase 3 종료 `ff836f2`)를 work/editor에 병합할 때 `pane.rs` 충돌(P3-F1과 P4-1·P4-3)을 impl-editor가 풀었다(P4-M1 `829dbcc`). work/editor를 work/ui에 병합할 때 `pane_group.rs` 충돌을 impl-ui가 풀었다(P4-M2 `aa4ad9d`). reviewer가 충돌 해결이 두 쪽 의도를 지키는지 확인했다(P4-4-5.md R1).
- master 병합 `4732464`. `Cargo.*` 변경 없음.

**P4-E Phase 4 끝 R-15·check-layout·V3** (2026-11-04)
- 무엇을 했나: measure가 master `4732464` 사본 exe로 R-15(phase2는 v0.4 사본), check-layout, 새 화면 V3를 했다(`verify/reviews/measure-phase4.md`, `verify/baseline/phase4/`). 미설명 3원인(30항목)이 나왔다 — U1 첫 화면 탭 바 끝 단추가 사라짐(P4-3b 회귀, 문서 결정 없음), U2 메뉴 hover, U3 메뉴 밖 누름. U1은 P4-E-F1(`2e3dc51`)로 고쳤다(reviewer REWORK 1 → R1 PASS `verify/reviews/P4-E-F1.md`, 제목 분리 방식 되돌림 H-25). master `56f1d93`에서 다시 쟀다(P4-E-R1).
- 결과

  | R-n | 항목 | 기준선(R-1) | Phase 4(`56f1d93`) | 의도한 변경 여부 | 증거 |
  |---|---|---|---|---|---|
  | R-15 | phase2 tooltip#32~#59(U1) | 통과 | 평가됨, R-1과 같은 값 | 회귀 → 해소 | measure-phase4 R1.2 |
  | R-15 | phase2 menu#7 I-303(U2), menu#50 I-519(U3) | 통과 | 통과(4732464 한 번만 실패) | 이력상 흔들림(재현 실패 2/2, 원인 확정 아님) | R1.2 |
  | R-15 | View 메뉴 행 5 → 10, 뒤따르는 메뉴 행 번호·구분선 위치 | — | — | 의도한 변경(Phase 4 분할·확대 메뉴) | R1.3 #4·#6·#7 |
  | R-15 | 포커스 컨텍스트 `Root > Workspace` | — | `Root > Workspace > Pane` | 의도한 변경(Pane key_context, P4-23b-R1) | R1.3 #8, phase1 28항목 |
  | R-15 | tab-btn-zoom 툴팁 단축키 | `<none>` | `Shift-Escape` | 의도한 변경(확대 동작) | R1.3 #2 |
  | R-15 | phase1 내장 바인딩 R-1 표 밖 | Phase 3의 3건 | + 핀·분할 키 | 의도한 변경 | measure-phase4 1.1 |
  | R-15 | 그 밖 | — | Phase 2 폭 −75 결과, Phase 3 변경 | 의도한 변경 | 1.2 |

  - 미설명 0, 실제 회귀 0(U1 해소 뒤). phase2 사본은 View 메뉴 새 행 때문에 다시 중단돼 `verify-v04-phase2-r1.ps1`(View 기대 행 1곳 + `$orig` 5항목, H-21과 같은 취지)로 한 번 더 돌렸다.
- check-layout: 28/28 PASS(4732464, 56f1d93 모두).
- V3 새 화면(`4732464`): 핀 탭 아이콘 14×14 PASS 등. 불일치 3 — L-105 h1·h2 아래 선·여백(컴포넌트 한계, H-25), L-108 링크 밑줄 불투명도 0.40 — gpui-base 0.8.1 `text/node.rs:3208`의 고정값 `opacity(0.4)`라 스펙 0.5와 다르다(컴포넌트 고정값, 사용자 결정 목록. 처음의 "안티에일리어싱 경계" 기록은 틀렸다 — phase4-final 지적). 측정 불가 4(`split_line_mouse_hitbox`·`drop_target_size_ratio`·`tab_drop_line_width`·핀 묶음), 판정 불가 3(표 줄 높이·오버레이 색·핀 묶음 스펙).
- 검증: V3(스크립트 실행·실측).
- 특이사항: 사용자 확인 목록 — U2·U3 흔들림 분류, L-105 컴포넌트 한계, L-108 컴포넌트 고정값 0.4, 측정 불가 항목. phase3 A-16.7 스크롤 offset_y −23 → −234는 이력상 흔들림(H-10)이다.

**P4-E-F2·F3 분할선·확대 테두리 두께 (R-13)** (2026-11-04)
- 무엇을 했나: reviewer Phase 4 최종 확인 REWORK — 기록 정정 3건(scroll −23→−234, phase2 실패 13 내역, L-108 컴포넌트 고정 0.4)과 누락 V3(크기 조절 뒤 배치·중첩 비율·확대 padding/border·탭 삽입선)을 measure가 처리했다(measure-phase4 R2: PASS 7). 남은 선 두께 차이를 impl-ui가 고쳤다 — `62f7dfa`(분할선 정수 좌표, 확대 테두리 겹침 → 1px), `c594bed`(분할선 옆 pane 가장자리선 겹침 → 경계마다 1px).
- 결과: reviewer PASS(`verify/reviews/P4-E-F2.md`, `P4-E-F3.md`). measure R3에서 분할선이 오히려 모든 상태 2px가 된 것을 잡았고, R4에서 분할선 3상태·확대 padding·border 모두 PASS, 불일치 0(`measure-phase4.md` R3·R4). master `13ed821`.
- 검증: V3(픽셀 측정).
- 특이사항: 분할하지 않은 화면의 사이드바 경계 x539~540 2px는 R2·R3·R4 모두 같고 스펙 값이 없다(참고, 사용자 확인 목록). `split_line_mouse_hitbox` 4px 폭은 도구로 재지 못했다(동작만 확인).

**Phase 4 종료** (2026-11-04, lead, 위임 H-4)
- 무엇을 했나: PLAN "Phase 종료 때". R-15·check-layout·V3(P4-E, R1~R4), `/ponytail-debt`(새 `shortcut:`: pane 닫힘 뒤 포커스, 외부 프로그램 경합 등), reviewer 최종 확인.
- 결과: 최종 확인 REWORK 2회(기록 오류 3건·분할 화면 V3 누락 → R1, 분할선 2px → P4-E-F2·F3 → R2) → R2 PASS(`verify/reviews/phase4-final.md`). 전체 테스트 201 통과(56f1d93 기준), clippy `-D warnings` 통과. 태그 `v0.4-phase-4`.
- 검증: reviewer 판정.
- 특이사항: v0.4 PLAN Phase 0~4를 모두 마쳤다. 버전 종료 판단은 사용자가 한다(WORKFLOW 4절) — 아래 "버전 종료"는 사용자 판단 전까지 "진행 중"으로 둔다.

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

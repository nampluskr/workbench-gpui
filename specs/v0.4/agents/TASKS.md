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
- 상태: done · 담당: impl-ui · 리뷰: reviewer · 브랜치: work/ui
- 요구·결정: R-3, D-4 · 원문: `specs/v0.3/AUDIT.md` 3
- 범위: `src/ui/panel_ops.rs`(필요하면 `src/fsops/ops.rs`의 결과 타입만)
- 검증 수준: V1(부분 성공·부분 실패 테스트)
- 할 일: 일반 실패를 기존 `notify`(panel_ops.rs 87행) 또는 삭제 실패 집계 알림 패턴으로 알린다. 부분 성공이면 성공한 대상만 선택하고, 실패한 cut 항목은 `file_clipboard`에 남긴다(지금은 178행에서 전부 비운다).

### P1-2 AUDIT 4 (패널 쪽): 트리 열기·복사·이동을 백그라운드로
- 상태: done · 담당: impl-ui · 리뷰: reviewer · 브랜치: work/ui
- 요구·결정: R-4, D-4 · 원문: AUDIT 4
- 범위: `src/ui/panel_nav.rs`(286행 `open_file` 주변), `src/ui/panel_ops.rs`(paste·duplicate의 복사·이동)
- 검증 수준: V1
- 할 일: 파일 IO를 `watch_io.rs`(200~240행)·`panel_delete.rs`(133행)의 background executor 패턴으로 옮긴다. 완료 때 workspace·요청이 아직 유효한지 확인하고 반영한다. 겹친 요청: 복사·이동은 서로 독립으로 돈다. 취소 UI 없음.
- 테스트: 무효 요청 결과를 버리는 테스트 1개 이상.

### P1-3 AUDIT 4 (탭 쪽): 큰 파일 첫 열기를 백그라운드로
- 상태: done · 담당: impl-editor · 리뷰: reviewer · 브랜치: work/editor
- 요구·결정: R-4, D-4, D-10
- 범위: `src/ui/pane.rs`(`read_text`·`open`), 필요하면 `src/ui/mod.rs`의 호출부(공통 — lead 지정: 호출부만)
- 검증 수준: V1
- 할 일: `read_text`를 백그라운드로 옮긴다. 탭은 먼저 만들고 내용은 읽기가 끝나면 넣는다(`set_value`는 UI 스레드). 같은 탭에 열기 요청이 겹치면 마지막 요청 결과만 반영한다. 완료 전에 탭·workspace가 닫히면 결과를 버린다. 기존 해시(`hash`, D-046) 동작을 유지한다.
- 테스트: 겹친 열기에서 마지막 요청만 반영되는 테스트, 닫힌 탭 결과를 버리는 테스트.

### P1-4 남은 `Duration` 하드코딩을 metrics.rs 앱 상수로
- 상태: done · 담당: impl-ui · 리뷰: review · 브랜치: work/ui
- 요구·결정: R-5, D-5
- 범위: `src/ui/metrics.rs`(이 카드에 한해 impl-ui에 지정), `src/fsops/watch.rs`, `src/state/mod.rs`, `src/ui/watch.rs`, `src/ui/watch_io.rs`, `src/ui/keymap.rs`, `src/ui/mod.rs`(타이머 리터럴만)
- 검증 수준: V0(값 불변)
- 할 일: 테스트 밖의 `Duration::from_*(<숫자 리터럴>)`과 모듈 로컬 Duration 상수를 `metrics.rs`로 옮기고 `// spec: none (app value)` 주석을 단다(Zed 원문 값이면 스펙 ID). 값은 그대로. 변수 인자(`from_millis(ms)`)는 대상 아님.
- 판정: grep 집계 명령과 결과 0건을 완료 보고에 적는다.

### P1-5 clippy 기준선 경고 0건
- 상태: done · 담당: impl-ui · 리뷰: review
- 요구·결정: R-6, D-5
- 검증 수준: V0(경고마다 동작 불변)
- 할 일: `cargo clippy --all-targets -- -D warnings` exit 0. `allow`로 숨기지 않는다.

## Phase 2 — Zed 일치: P4 UI 셸 ∥ P5 에디터 코어 (todo)

순서: P2-0(시작 실측) → (P2-1 ∥ P2-2 …) → P2-E. 값 맞춤 카드 리뷰는 review, 에디터 로직(P2-5·P2-6)은 reviewer.

### P2-0 시작 V3 실측: UI 셸·에디터 불일치 목록 (D-3)
- 담당: measure · 검증 수준: V3
- 측정 목록: UI 셸(titlebar, sidebar, project_panel, tab bar, statusbar, menu, tooltip) 스펙 ID 전부 + 에디터(거터, 커서, 선택, 줄 높이, 스크롤바) 스펙 ID. 기존 `tools/measure/`와 `--dev-layout` 덤프를 쓴다. 허용 오차 안 불일치도 목록에 넣는다(D-3).
- 결과: `specs/v0.4/verify/reviews/measure-p2-0.md`(스펙 ID, 기대, 측정, 차이, 판정). [MEASURED] P2-0.

### P2-1 사이드바 시작 폭 300·복원 폭(R-7, Q-15)
- 담당: impl-ui · 리뷰: review · V2
- 할 일: 데스크톱에서 시작 폭이 300 → 375(약 1.25배)로 나오는 원인을 찾아 고친다(스케일 이중 적용 의심). `sidebar["default_width"]` 300, 복원 폭 494 그대로. phase3 R-28 실패 2건이 통과로 바뀌는 것이 기대 결과다.

### P2-2 UI 셸 나머지 불일치(P2-0 목록에서, 영역별 카드로 나눔)
- 담당: impl-ui · 리뷰: review · V2. `sidebar["footer.height"]` 31 → 30 포함.

### P2-5 에디터 표시 4건 + 스크롤바 2건(D-10)
- 담당: impl-editor · 리뷰: reviewer · V2
- 거터 줄 번호 최소 4자리, 커서 2px, 선택 모서리 0.15×줄 높이, 한글 혼합 줄 기준선, 스크롤바 15px, 스크롤바 마커. gpui-kit Editor 위에 더한다(렌더러 훅·래퍼). 수치는 스펙 ID로.

### P2-6 에디터 입력 2건(D-10)
- 담당: impl-editor · 리뷰: reviewer · V1
- Ctrl+Shift 드래그 열 선택(gpui-kit은 Alt+Shift), 선택 끌어 옮기기.

### P2-E Phase 2 끝: R-15, V3(바뀐 화면), 반복 측정 항목 V2 이전(R-16), 최종 확인

### P2-7 에디터 글꼴 크기·줄 높이(P2-0에서 추가)
- 담당: impl-editor · 리뷰: review(값 맞춤) · V2
- P2-0: 본문 글자 진행 폭으로 보아 글꼴 약 12px(스펙 `typography["buffer_font_size"]` 15), 줄 간격 20(스펙 `editor["line_height.comfortable"]` 24.27, Zed 기본 1.618). gpui-kit Editor 공개 설정(텍스트 스타일·줄 높이)으로 맞춘다. 공개 API가 없으면 그 항목만 보류.

## Phase 3 — 탭 편집과 저장 (todo, Phase 2 끝난 뒤)

규칙: 모든 카드 리뷰는 reviewer(동작 변경). 수치는 스펙 ID. 원문은 `spec/INDEX.md` 13.4절(E-080~E-089a), A-13.4, I-069, G-115.
재사용: 인코딩은 `src/dev.rs`의 `decode`·`encode`·`TextEncoding`(UTF-8/BOM, UTF-16 LE/BE, CP949 Win32 FFI, 손실 검사)이 이미 있다. 새 의존성 없이 이것을 탭 편집에서 쓸 수 있는 곳으로 옮긴다(lead 지정: 새 모듈 `src/text_io.rs`, impl-editor 소유, dev.rs는 그 모듈을 쓰게 바꾼다).

### P3-1 편집 허용·수정 상태 (R-9)
- 담당: impl-editor · V1(+첫 구현 V3는 P3-E)
- 범위: `src/ui/pane.rs`, 탭 편집 새 모듈
- 할 일: 탭 Editor의 읽기 전용을 푼다. 탭마다 수정 상태(dirty)를 둔다: 디스크에서 읽은 내용의 해시와 현재 버퍼가 다르면 dirty. 깨끗한 버퍼 자동 다시 읽기(E-086 앞부분, D-046)는 그대로 두고, dirty 버퍼에는 다시 읽기를 적용하지 않는다(P3-4가 충돌 표시를 붙인다). 입력 시뮬레이션은 #[gpui::test]가 안 되므로 상태 결정을 순수 함수로 테스트한다(H-9).

### P3-2 저장과 인코딩 왕복 (R-10 일부)
- 담당: impl-editor · V1
- 범위: `src/text_io.rs`(신규, dev.rs의 decode/encode 이동), `src/dev.rs`(호출부만), `src/ui/pane.rs`, `src/ui/mod.rs`(Save 액션 연결만)
- 할 일: 탭을 열 때 `decode`로 인코딩·BOM·줄 끝을 기억하고, 저장(`workspace::Save`, Ctrl+S — 기존 키맵 확인) 때 같은 인코딩으로 `encode`해 쓴다. CP949로 옮길 수 없는 글자가 있으면 저장하지 않고 기존 notify로 알린다(best-fit 금지). 쓰기는 데이터 손실 없게(임시 파일 + 교체 등 기존 `state::replace_file` 패턴 재사용 검토). 저장 뒤 dirty 해제, 해시 갱신(감시 자기 쓰기 무시 D-046 유지).
- 테스트: UTF-8 LF/CRLF, UTF-8 BOM, UTF-16 LE, CP949 왕복 바이트 비교, CP949 손실 거부.

### P3-3 탭 닫기·저장 질문·저장 확인창 (R-10)
- 담당: impl-ui(대화창·탭 닫기 UI) + impl-editor(저장 호출) — lead가 순서 지정: P3-2 병합 뒤 impl-ui
- 할 일: 탭 닫기(`pane::CloseActiveItem`, 탭 닫기 버튼)를 만들고, dirty 탭이면 A-13.4·I-069 저장 질문(저장·버리기·취소)을 띄운다. 창 닫기·종료 때도 dirty 탭이 있으면 같은 질문. 저장 때 확인창(E-084·E-085 조건). 대화창은 기존 `task_dialog.rs`·`delete_prompt` 패턴 재사용.

### P3-4 디스크 충돌·지워진 파일 표시 (R-11)
- 담당: impl-editor(감시 반영 로직, watch_io.rs 해당 부분 지정) + impl-ui(탭 표시: 점 Warning 색, 취소선 등 E-086·E-087)
- 할 일: dirty 버퍼의 파일이 디스크에서 바뀌면 버퍼는 두고 충돌 표시, 열린 파일이 지워지면 지워진 표시.

### P3-E Phase 3 끝: R-15, V3(새 화면: 수정 표시·저장 질문·충돌·지워짐·편집기 글꼴), 최종 확인

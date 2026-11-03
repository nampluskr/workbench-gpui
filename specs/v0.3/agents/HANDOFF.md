# HANDOFF — workbench-gpui v0.3

> 소유: `lead`. 세션이 바뀔 때 다음 `lead`가 이어받을 상태만 적는다. 최신이 위.

## 2026-11-03 lead 세션 1 끝 → Phase 1 새 세션으로

### 현재 상태
- Phase 0 완료(`v0.3-phase-0`). Phase 1 카드 승인됨(TASKS "Phase 1"). 아직 어떤 Phase 1 지시도 보내지 않았다.
- 구성 변경 H-20 승인: `review`(agy gemini-3.8-flash-high) 카드 리뷰, `measure`(Claude Code Sonnet 5.5 medium) 측정·R-12 재실행·V3, `reviewer`(Codex)는 Phase당 최종 확인 1회. HERDR-SETUP 1장·1.3·4장, AGENTS 7.1a에 반영.
- P1-2: `Cargo.toml` `[dev-dependencies] toml = "=1.1.8"` 사용자 승인(이미 `Cargo.lock`에 있음).
- 새 규칙(HERDR-SETUP 9장): Phase가 바뀔 때 모든 에이전트를 새 세션으로 시작.
- 구독 여유(사용자 2026-11-03): Claude·Gemini(Flash) 여유, Codex 부족, Argon 사용 불가.

### 다음 할 일 (새 lead)
1. `herdr workspace list`로 워크스페이스 확인(1.3).
2. 기존 pane의 에이전트를 새 세션으로 시작한다(9장). 다시 띄우지 않고 새 대화 명령(Claude Code `/clear`, Codex `/new`·`/clear`)으로 대신해도 된다. 이름·pane이 그대로 남는다. Codex는 새 대화 뒤 `/model`(Sol·Medium)을 다시 확인하고, agy는 새 대화 명령이 없으면 다시 띄운다. 이 lead 세션도 `/clear`로 시작했다. pane: control 탭 spec `wD:p2`, verify 탭 reviewer `wD:p3`·shell `wD:p4`, wt-ui impl-ui `wE:p1`·shell `wE:p2`. id는 `herdr pane list`로 다시 확인.
   - reviewer: `codex` 옵션 없이 → `/model` GPT-6.1-Sol·Medium·`s`. Phase 1에서는 끝의 최종 확인 때만 쓰니 그때 띄워도 된다.
   - spec: `agy --model gemini-3.8-flash-medium`, 편집 자동 승인(shift+tab). Phase 1에는 spec 카드가 없으니 필요할 때만.
   - impl-ui: `agy --model claude-sonnet-5-5-medium`(`.worktrees/ui`).
   - 새로: verify 탭에 `review`(`agy --model gemini-3.8-flash-high`), `measure`(`claude --model sonnet --effort medium`) pane을 나눠 만들고 이름을 붙인다.
3. `.worktrees/ui`에서 `git merge --ff-only master`(work/ui는 `c6b680a`, master는 Phase 0 커밋 이후).
4. PLAN 진행 현황 Phase 1 → doing. P1-1(lead 문서) → P1-2·P1-4(impl-ui) ∥ P1-5(measure) → P1-3. 카드 리뷰는 review, Phase 끝 최종 확인은 reviewer.

### 주의
- 사이드바 시작 폭 375(스펙 300)는 기준선(Q-15). R-12 재실행에서 375면 변화 없음.
- `verify/**/appdata/`는 `.gitignore`(개인 경로 유출 방지).
- Git Bash에서 슬래시 명령은 `MSYS_NO_PATHCONV=1` + `herdr pane send-text`.
- agy 기본 모드는 읽기 명령도 승인을 묻는다. 지속 허용·전체 자동 승인은 lead 안전 분류기가 막는다. 1회 승인으로 처리.

## 2026-11-03 lead 세션 1 — Phase 0 종료

### 현재 상태
- Phase 0 모든 카드 완료, 커밋·태그 `v0.3-phase-0`(push 안 함). Phase 1 카드 초안은 `TASKS.md` 아래에 있고 사용자 승인 대기.
- 결정은 PROGRESS의 F5·감사 채택 절, 하위 에이전트 승인 기록은 `HERDR-DECISIONS.md` H-1~H-19.

### herdr
- 워크스페이스 `workbench-gpui`(wD): 탭 control(lead `wD:p1`, spec `wD:p2`), verify(reviewer `wD:p3`, shell `wD:p4`).
- 워크스페이스 `wt-ui`(wE): impl-ui `wE:p1`(agy claude-sonnet-5-5-medium), shell `wE:p2`. worktree `.worktrees/ui`, 브랜치 `work/ui`(master `c6b680a`에서 만듦 — Phase 1 시작 때 master로 갱신 필요).
- reviewer는 `codex` 옵션 없이 띄우고 `/model`에서 GPT-6.1-Sol·Medium·세션 한정. 한도는 마지막 확인 때 5시간 30%, 주간 약 35%, 컨텍스트 79% — Phase 1 전에 새 세션으로 띄우는 것을 검토.
- spec은 agy 편집 자동 승인 모드(F5 Q-4). impl-ui는 기본 모드라 읽기 명령도 승인을 묻는다.

### 주의
- 사이드바 시작 폭 375(스펙 300)는 기준선에 포함(Q-15). R-12 재실행 때 375이면 "변화 없음".
- 실측·검증 스크립트는 앱 데이터를 `verify/**/_backup*/appdata/`에 복사한다. 이 경로는 `.gitignore`에 있다(개인 경로 유출 방지).
- `tools/measure/`의 리뷰 지적 2~5는 P1-5에서 처리.
- worktree에는 커밋된 문서만 있다. 하위 에이전트에게 문서를 읽힐 때 커밋 전이면 메인 체크아웃 절대 경로를 준다.

### 다음 할 일
1. 사용자 승인: Phase 1 카드 초안, P1-2의 `[dev-dependencies] toml = "=1.1.8"`.
2. `work/ui`를 master(Phase 0 커밋)로 갱신.
3. P1-1(reviewer) → P1-2·P1-4(impl-ui)·P1-5(reviewer) → P1-3.

## 2026-11-03 lead 세션 1 — Phase 0 카드 작성

### 현재 상태
- Phase 0 카드를 `TASKS.md`에 썼다. 사용자 승인 대기. 아직 어떤 에이전트에게도 지시하지 않았다.
- F0 결과는 `TASKS.md` F0 카드 비고에 있다.
- P0-5 제안(아래)을 사용자 확정 대기 중이다. 확정되면 HERDR-SETUP 4장 두 행을 고친다.

### herdr 점검 (`herdr workspace list`, `herdr pane layout --current`)
- 워크스페이스는 `workbench-gpui`(wD) 하나뿐이다. 토큰 부담은 HERDR-SETUP 1.3 가정과 같다.
- 탭 1개(wD:t1), pane 1개(wD:p1 = lead)뿐이다. `control`·`verify` 탭, `spec`·`reviewer`·`impl-ui` pane, `wt-ui` worktree가 아직 없다.
  - Phase 0 시작 조건(PLAN: 네 에이전트 실행·이름 붙임)이 아직 채워지지 않았다. HERDR-SETUP 3.4 레이아웃 생성과 에이전트 실행이 먼저다.
- git worktree는 master 하나뿐이다.

### P0-5 제안 (사용자 확정 대기)
- 근거: `src/` 41개 파일 11,881줄. gpui-kit `Input`/`Editor`를 쓰는 에디터 화면은 `src/ui/editor_poc.rs`(439줄) 하나다. 다른 참조는 `src/ui/mod.rs`(모듈 선언·생성·렌더 분기)와 `src/dev.rs`(`--dev-editor-poc` 플래그)뿐이다. `panel_edit.rs`의 입력은 프로젝트 패널 이름 바꾸기라 UI 셸이다.

| 영역 | 경로 | 소유자 |
| --- | --- | --- |
| 에디터 코어 | `src/ui/editor_poc.rs` | `impl-editor` |
| UI 셸 | `src/ui/` 의 나머지 파일(아래 공통 제외), `src/keymap/`, `src/fsops/`, `src/state/`, `src/main.rs` | `impl-ui` |
| 공통(카드 단위로 lead가 지정) | `src/ui/mod.rs`, `src/ui/metrics.rs`, `src/ui/rem.rs`, `src/ui/layout_probe.rs`, `src/dev.rs`, `Cargo.toml` | `lead` 지정 |

- 원안과 다른 점: `src/ui/mod.rs`(에디터 생성·렌더 분기가 있어 양쪽이 고칠 수 있음), `src/ui/rem.rs`·`layout_probe.rs`(Phase 1·2 공통 도구)를 공통으로 옮겼다. `src/main.rs`를 UI 셸에 명시했다.

### 다음 할 일
1. 사용자 승인: Phase 0 카드 목록, F0, P0-5, P0-0a 진행.
2. herdr 레이아웃(HERDR-SETUP 3.4)과 에이전트 실행 — 사용자와 함께.
3. 승인 뒤 바로: F1(`spec`, 7.2 프롬프트), F2(lead).
4. P0-0a 끝나면: P0-0b → P0-2(reviewer), P0-4(impl-ui, wt-ui 생성 뒤) → P0-0c.

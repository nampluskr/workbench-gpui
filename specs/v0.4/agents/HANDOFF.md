# HANDOFF — workbench-gpui v0.4

- 소유: `lead`. 맨 위 절이 지금 상태다. 지난 절은 지우지 않는다.
## 지금 (2026-11-05, v0.4 종료)

- 사용자가 v0.4를 종료했다. 태그 `v0.4`. 판단과 남은 것(A1~A3)은 PROGRESS "버전 종료".
- herdr에는 lead pane(wD:p1)만 남았고 감시기는 멈춰 있다. 다음 버전 번호는 사람이 정한다.

## 이전 (2026-11-04 22:45, v0.4 Phase 0~4 완료 — 사용자 버전 종료 판단 대기)

- PLAN Phase 0~4 모두 done(태그 `v0.4-phase-0`~`v0.4-phase-4`, master). 버전 종료는 사용자가 판단한다.
- 사용자 결정·확인 목록은 PROGRESS 각 Phase "특이사항"과 HERDR-DECISIONS H-8·H-10·H-14·H-15·H-17·H-18·H-24·H-25.
- herdr 에이전트는 모두 대기. 감시기 `watch4.sh`는 계속 돈다(멈추려면 `restart-watch.sh`의 kill 부분).

## 이전 (2026-11-04 16:36, Phase 1 끝 → Phase 2 시작)

- Phase 1 done(태그 `v0.4-phase-1`, master). AUDIT 3·4, Duration, clippy 0. 테스트 78.
- herdr: impl-ui는 Claude Code Sonnet(H-8, agy Claude 주간 한도 소진). impl-editor Claude Code Opus(auto 모드). spec·review agy(편집 자동 승인).
- Phase 2 카드 초안 P2-0~P2-E는 `TASKS.md`. 먼저 P2-0(measure 시작 V3 실측).
- 감시기 `watch4.sh`(재시작 `restart-watch.sh`). 대기 중 프롬프트는 2분마다 다시 알린다.

## 이전 (2026-11-04 15:20, Phase 0 끝 → Phase 1 시작)

- Phase 0 done(태그 `v0.4-phase-0`). 기준선은 v0.3과 같다(빌드 경고 0, 테스트 60, clippy 10, 스크립트 585/2). 새 스펙 14줄, 모호 4건(`spec/ambiguous.md`).
- Phase 1 카드 P1-1~P1-5는 `TASKS.md`. impl-ui(wF, work/ui)·impl-editor(wG, work/editor) 대기 중.
- 위임 진행 중(H-4). 감시기 `watch4.sh`, 재시작은 `restart-watch.sh`(Git Bash에 pkill 없음). spec·review는 agy 편집 자동 승인 모드(H-5).
- Codex 5h 98% 남음.


## 이전 (2026-11-04, Phase 0 시작)

- 위임 진행 중(HERDR-DECISIONS H-4). 이 lead 세션이 Phase 0~4를 이어간다.
- 상시 감시기: lead scratchpad `watch4.sh`(백그라운드), 이벤트 `events.log`, 자동 승인 `auto-approved.log`.
- herdr: wD control(lead, spec) · wD verify(reviewer, review, measure) · wF wt-ui(impl-ui). impl-editor는 Phase 1에 띄운다.
- Phase 0 카드: P0-1(measure), P0-2(spec), P0-3(review) — `TASKS.md`.

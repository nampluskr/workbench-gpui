# HANDOFF — workbench-gpui v0.4

- 소유: `lead`. 맨 위 절이 지금 상태다. 지난 절은 지우지 않는다.
## 지금 (2026-11-04 15:20, Phase 0 끝 → Phase 1 시작)

- Phase 0 done(태그 `v0.4-phase-0`). 기준선은 v0.3과 같다(빌드 경고 0, 테스트 60, clippy 10, 스크립트 585/2). 새 스펙 14줄, 모호 4건(`spec/ambiguous.md`).
- Phase 1 카드 P1-1~P1-5는 `TASKS.md`. impl-ui(wF, work/ui)·impl-editor(wG, work/editor) 대기 중.
- 위임 진행 중(H-4). 감시기 `watch4.sh`, 재시작은 `restart-watch.sh`(Git Bash에 pkill 없음). spec·review는 agy 편집 자동 승인 모드(H-5).
- Codex 5h 98% 남음.


## 이전 (2026-11-04, Phase 0 시작)

- 위임 진행 중(HERDR-DECISIONS H-4). 이 lead 세션이 Phase 0~4를 이어간다.
- 상시 감시기: lead scratchpad `watch4.sh`(백그라운드), 이벤트 `events.log`, 자동 승인 `auto-approved.log`.
- herdr: wD control(lead, spec) · wD verify(reviewer, review, measure) · wF wt-ui(impl-ui). impl-editor는 Phase 1에 띄운다.
- Phase 0 카드: P0-1(measure), P0-2(spec), P0-3(review) — `TASKS.md`.

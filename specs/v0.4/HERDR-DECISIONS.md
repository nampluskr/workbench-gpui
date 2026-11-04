# HERDR-DECISIONS — workbench-gpui v0.4 대리 응답 기록

- `lead`가 하위 에이전트의 결정 요청에 대리 응답한 것과, 구성 변경(대체 모델 전환 등)을 기록한다.
- 위임 범위는 `specs/v0.4/HERDR-SETUP.md` 6.5를 따른다. 위임 밖 항목은 사용자에게 올리고, 그 결과도 여기에 남긴다.
- 지난 버전 기록은 `specs/v0.3/HERDR-DECISIONS.md`(H-1~), `docs/HERDR-DECISIONS.md`(v0.1·v0.2)에 있다. 이 문서는 v0.4에서 새로 번호를 매긴다.
- 형식: 항목마다 `### H-n · 날짜 · 요청 에이전트 → 대상` 절을 두고, 요청·판단·근거·결과를 적는다.

---

### H-1 · 2026-11-04 · 사용자 → lead (v0.4 herdr 재구성)
- 요청: "현재 herdr 워크스페이스에서 lead 에이젼트만 남기고 탭패널을 초기화 하고, herdr 환경을 v0.4 용으로 다시 구성해 주세요." 계획(`HERDR-SETUP.md` 1장 구성안)을 사용자가 승인.
- 판단: v0.3 verify 탭(review·measure·reviewer)과 wt-ui 워크스페이스(impl-ui, Claude Code 대체)를 닫고, `.worktrees\ui`는 지우지 않고 `work/ui`를 master로 fast-forward해 재사용한다. impl-ui는 agy 한도 여유로 기본값(agy Claude Sonnet)으로 되돌린다. impl-editor는 카드가 생길 때 띄운다.
- 근거: 구독 현황(사용자 2026-11-04: Codex 5h 초기화, agy Argon만 소진, 다른 워크스페이스 없음), reviewer 비중 "기능 카드만 Codex".
- 결과: `HERDR-SETUP.md` 1·2장의 구성으로 재구성.

### H-2 · 2026-11-04 · impl-ui → lead (읽기 전용 명령 승인)
- 요청: 시작 프롬프트 뒤 `Get-ChildItem specs -Recurse -Depth 1 | Select-Object -First 40 FullName; git branch --show-current` 실행 승인.
- 판단: 쓰기 토큰이 없는 읽기 전용 명령이라 1회 승인한다(HERDR-SETUP 6.4, 위임).
- 결과: 승인. worktree에 v0.4 문서가 없다는 보고를 받아, 문서를 master에 커밋하고 `work/ui`를 fast-forward했다.

### H-3 · 2026-11-04 · impl-ui → lead (읽기 전용 명령 승인)
- 요청: `Select-String -Path specs\v0.4\HERDR-SETUP.md -Pattern '^#' ...` 실행 승인.
- 판단·결과: 읽기 전용이라 1회 승인(6.4). impl-ui가 역할 확인 후 대기.

### H-4 · 2026-11-04 · 사용자 → lead (v0.4 권한 위임)
- 요청: 사용자 말 "리더 에이젼트에게 승인원 권한을 위임합니다. 플랜 문서를 모든 phase 를 순서대로 단계별로 진행합니다. 서브 에이젼트가 승인 요청이 오면 확인하여 승인하고, v0.3 에서 처럼 몇시간의 멈춤이 발생하지 않도록 해 주세요. 특히 , agy 에서 요청을 자주하니 확인하여 승인해 주세요. codex 5시간 사용량이 다 되면 다른 이이젼트로 전환해 주세요."
- 판단: PLAN Phase 0~4를 순서대로 진행한다. 6.5 위임 밖 항목도 v0.4 범위 안에서는 lead가 판단하고 여기에 남긴다(v0.3 H-26과 같다). 하지 않는 것: push·원격 설정, `Cargo.toml`·`Cargo.lock` 변경, 사용자 시스템 설정 변경, 지난 버전 폴더 쓰기, 사용자 파일 삭제. 마크다운 렌더는 gpui-component 0.8.1 기본 기능이라 Cargo 변경이 없다.
- 9장 예외: 이 lead 세션이 끝까지 이어간다. Phase마다 HANDOFF 맨 위 절을 갱신하고 하위 에이전트는 새 대화로 시작한다.
- 멈춤 방지: 상시 감시기(scratchpad `watch4.sh`, Monitor)가 담당 범위 안 승인을 자동 처리하고 `auto-approved.log`에 남긴다. 모르는 프롬프트는 종료하지 않고 lead에게 알린다(v0.3 watch.sh는 종료해서 멈췄다).
- 한도 전환: Codex 5h ≤10% 또는 weekly ≤5%이면 기능 카드 리뷰·최종 확인을 `review`로 넘긴다(최종 확인을 미루지 않는 것은 1.1의 예외, 사용자 지시). agy 5h 90% 이상이면 1.1의 대체로 바꾼다.

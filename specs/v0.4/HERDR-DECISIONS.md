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

### H-5 · 2026-11-04 · lead (agy 편집 자동 승인 모드, 위임 H-4)
- 요청: spec(agy)이 `spec/zed-metrics.toml` 편집마다 승인을 묻는다. 감시기는 긴 diff 화면에서 경로를 놓쳤다.
- 판단: spec은 v0.3처럼 agy 편집 자동 승인 모드(shift+tab, v0.3 F5 Q-4)로 둔다. spec은 `spec/` 밖을 고치지 않는다는 규칙이 있고, 결과는 review가 표본 대조한다. impl-ui·review도 Phase 1 시작 때 같은 모드로 바꾼다. impl-ui는 worktree 안에서만 일하고, 병합 전 리뷰가 diff를 본다. `Cargo.*`·담당 밖 파일이 diff에 있으면 병합하지 않는다. 명령 승인은 감시기가 계속 맡는다.
- 결과: spec 모드 전환. 감시기는 경로를 화면 전체에서 찾도록 고쳤다.

### H-6 · 2026-11-04 · lead (impl-editor 권한 모드, 위임 H-4)
- 요청: impl-editor(Claude Code)가 빌드·테스트·커밋마다 승인을 묻고, LSP 플러그인 설치 제안이 작업 중 반복해 떴다.
- 판단: impl-editor를 Claude Code auto 모드로 둔다(measure와 같다). worktree `work/editor` 안에서만 일하고 병합 전 reviewer가 diff를 본다. LSP 플러그인은 설치하지 않는다("Never for this plugin", 감시기 규칙). 감시기의 deny 목록 `Format-`은 `Format-Volume`으로 좁혔다(Format-Table 오탐).
- 결과: P1-3 커밋 `777abe1`(work/editor). 이후 Claude 계열 구현자는 auto 모드로 띄운다.

### H-7 · 2026-11-04 · lead (P1-3 rework 범위, 위임 H-4)
- 요청: reviewer P1-3 REWORK 2건(첫 읽기와 reload 경합, folder 해제 뒤 결과 적용). 수정이 `src/ui/watch_io.rs`·`src/ui/folders.rs`(impl-ui 소유)에 걸친다.
- 판단: 원인이 P1-3에 있으니 같은 담당(impl-editor)이 고친다. 이 카드에 한해 `watch_io.rs`·`folders.rs`의 관련 부분을 impl-editor 범위로 지정한다. impl-ui는 지금 `panel_ops.rs`·`panel_nav.rs`(P1-2)를 맡아 파일이 겹치지 않는다. 병합 때 충돌은 lead가 푼다.
- 결과: P1-3-R1 카드.

### H-8 · 2026-11-04 15:40 · lead (impl-ui 대체 모델, 위임 H-4)
- 요청: impl-ui(agy Claude Sonnet)가 P1-4 도중 "Individual quota reached … Resets in 150h"로 멈췄다(agy Claude 주간 한도).
- 판단: HERDR-SETUP 1.1의 대체로 바꾼다. 같은 pane `wF:p1`, 같은 worktree `.worktrees/ui`, 이름 `impl-ui`, Claude Code Sonnet 5.5 medium, auto 모드(H-6과 같다). worktree에 남은 P1-4 미커밋 변경(`metrics.rs`, `fsops/watch.rs`)을 이어받게 한다. 이전 agy 대화: `agy --conversation=e5e62da5-518c-4e1c-8810-96e8ae21cdfd`.
- 결과: Claude 구독(Max) 부담이 늘어난다(lead·measure·impl-editor·impl-ui 모두 Claude). 사용자 확인 목록에 올린다.

### H-9 · 2026-11-04 · lead (P1-12-R2 설계, 위임 H-4)
- 요청: reviewer P1-12-R1 REWORK — 복사(create_new 예약)와 같은 볼륨 이동(rename) 사이 앱 내부 경합으로 내용 손실 가능, 이동 전체를 잡는 전역 잠금이 큰 교차 볼륨 이동 동안 다른 이동을 막음, 완료 경로 테스트 부족.
- 판단: 잠금 범위를 "이름 고르기 + 예약(복사: create_new / create_dir, 교차 볼륨 이동: 대상 예약) 또는 같은 볼륨 rename"으로 좁히고, 복사도 같은 잠금을 쓴다. 느린 복사·검증·원본 삭제는 잠금 밖에서 한다. 예약된 이름은 다른 작업이 고르지 않는다(이미 있으므로). 외부 프로그램 경합만 `shortcut:`으로 남는다. 테스트는 `#[gpui::test]`(Cargo test-support 필요, 위임 밖) 대신 완료 반영을 순수 "plan" 함수(입력: 결과·현재 workspace 목록·클립보드 세대, 출력: 알림·복원·선택·트리 갱신)로 빼서 검증하고, 핸들러는 plan을 그대로 실행한다(v0.3 H-30 방식).
- 결과: P1-12-R2 카드(impl-ui).

### H-10 · 2026-11-04 · lead (R-15 값 비교와 실행마다 흔들리는 위치 표본, 위임 H-4)
- 요청: reviewer Phase 1 최종 확인 REWORK — R-15 비교기가 `ok`만 보고 `got` 값을 비교하지 않았다. phase3 A-16.7 휠 스크롤 `offset_y`가 R-1 −23, Phase 1 −234.
- 판단: 같은 코드에서 이 값은 실행마다 −23/−234로 갈린다(v0.2 재실행 5회 −234, v0.3 기준선 −23, v0.3 phase1 −234, phase2·phase3 −23, v0.4 기준선 −23). 스크립트가 휠 입력 600ms 뒤 마지막 스크롤 로그를 저장하므로 스크롤 진행 중 표본이다. 위치 값이지만 시각에 따라 표본이 바뀌므로 D-8의 "흔들리는 시간 값"과 같이 스크립트 자체 판정(`offset_y < 0`)만 대조한다. 이 분류는 이력 근거가 있는 항목에만 쓰고, 근거 없는 값 차이는 회귀로 본다. R-15 비교는 앞으로 모든 `got` 값을 비교하고 차이마다 분류(의도한 변경 / 이력상 흔들림 / 미설명)를 남긴다.
- 결과: measure에 값 비교 재대조 지시. 사용자 확인 목록에 올린다(D-8 해석).

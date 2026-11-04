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

### H-11 · 2026-11-04 · lead (공유 target exe와 실측, 위임 H-4)
- 요청: impl-ui P2-1 빌드가 링크 단계에서 `target\debug\workbench-gpui.exe`를 지우지 못했다(measure가 실행 중). 공유 `CARGO_TARGET_DIR`라 worktree 빌드가 measure가 재는 exe를 바꿀 수 있다.
- 판단: measure는 빌드 직후 exe를 `%TEMP%\wbg-measure\<커밋>\`로 복사해 그 사본으로 실측·검증 스크립트를 돌린다(`-Exe` 절대 경로). 공유 target 규칙(AGENTS 2장)은 그대로 둔다. 구현자는 링크 실패 때 다른 세션의 exe를 끄지 않는다(지금처럼).
- 결과: measure에 지시. P2-0은 사용한 exe가 master `cf3a82d` 빌드인지 확인한다.

### H-12 · 2026-11-04 · lead (Phase 3 편집기 카드 선행, 위임 H-4)
- 요청: Phase 2는 사이드바 폭 rework(P2-1-R1, impl-ui) 하나만 남았다. impl-editor는 Phase 2 카드를 모두 마쳤다.
- 판단: Phase 3의 편집기 카드 P3-1·P3-2를 work/editor에서 먼저 시작한다. Phase 2 종료(R-15·V3·최종 확인) 전에는 master에 병합하지 않는다. PLAN "이전 Phase 완료 조건을 통과해야 다음 Phase 시작"의 예외이며, 병합 순서는 지킨다. 사용자 확인 목록에 올린다.
- 결과: P3-1·P3-2 지시. Phase 2 측정 결과 정리: 에디터 줄 높이 24(24.27 렌더 반올림)·메뉴 행 23(22.652 렌더 반올림)은 코드 값이 스펙과 같아 맞출 수 없다. 커서 2px는 D-10 보류 항목.

### H-13 · 2026-11-04 · impl-editor → lead (P3-2 Save 액션 연결 범위, 위임 H-4)
- 요청: Ctrl-S 저장(E-088)에 `workspace::Save` 액션과 `ctrl-s` 바인딩이 없다. 넣을 곳은 impl-ui 소유 `src/ui/keymap.rs`(액션 목록), `src/keymap/mod.rs`(ACTIONS), `src/keymap/builtin.rs`에 한 줄씩.
- 판단: impl-editor가 이 카드에 한해 세 파일의 해당 한 줄씩을 고친다(H-7과 같다). impl-ui는 지금 이 파일들을 고치지 않는다.
- 결과: impl-editor 선택지 1.

### H-14 · 2026-11-04 · lead (Phase 2 종료와 R-8 미충족 6건, 위임 H-4)
- 요청: PLAN Phase 2 완료 조건 "직접 구현 8건(D-10)이 들어가고"를 채우지 못했다. 6건은 gpui-kit 공개 API 부재(4자리·커서·선택 모서리·기준선·끌어 옮기기) 또는 스펙 모호(마커·기준선 허용치·끌어 옮기기 지연)로 보류했다(PROGRESS Phase 2 표).
- 판단: 6건을 고치려면 gpui-kit 교체·`Cargo` 변경 또는 편집기 렌더 직접 구현이 필요하다. 모두 위임 밖이거나 D-6(gpui-kit Editor 유지)과 어긋난다. Phase 2는 이 6건을 "사용자 결정 대기"로 남기고 닫는다. 나머지 완료 조건(UI 셸 V3, R-15, R-16)은 채운다. 계획 변경이 아니라 미충족 기록이며, 사용자가 길을 정하면 v0.4 안의 추가 카드나 다음 버전으로 다룬다.
- 결과: Phase 2 최종 확인에서 R-8은 "2/8 충족, 6 사용자 결정 대기"로 판정받는다.

### H-15 · 2026-11-04 · lead (혼합 줄 끝 저장, 위임 H-4)
- 요청: reviewer P3-12-R1 REWORK — LF/CRLF가 섞인 파일을 편집 없이 저장해도 첫 줄 끝으로 통일된다(D-6 "줄 끝을 그대로" 위반).
- 판단: 수정하지 않은(dirty 아닌) 버퍼는 저장 명령에서 쓰기를 하지 않는다. 그러면 편집하지 않은 혼합 파일 바이트는 그대로다. 편집한 혼합 파일은 감지한 주된 줄 끝 하나로 통일한다(Zed가 버퍼를 한 줄 끝으로 다루는 것과 같다). 사용자 확인 목록에 올린다.
- 결과: P3-12-R2 카드.

### H-16 · 2026-11-04 · lead (Phase 3 탭 닫기·충돌 표시 범위, 위임 H-4)
- 판단: P3-3(impl-ui)은 탭 닫기에 필요한 최소 함수를 `src/ui/pane.rs`(impl-editor 소유)에 더할 수 있다. P3-4는 둘로 나눈다 — P3-4a(impl-editor): dirty 버퍼의 디스크 변경·삭제를 감지해 탭 상태(충돌·지워짐)로 두는 로직(`pane.rs`·`watch_io.rs`). P3-4b(impl-ui): 그 상태를 탭에 그리는 표시(E-086 점 Warning 색, E-087 지워진 파일). 두 담당이 `pane.rs`를 같이 고칠 수 있어 병합 때 lead가 충돌을 푼다.

### H-17 · 2026-11-04 · impl-ui → lead (P3-3 판단 항목, 위임 H-4)
- 요청: (1) 종료(Ctrl-Q) 때 저장 질문 vs A-25.8·I-118의 "묻지 않고 미저장 내용 복원". (2) 대화창 기본 버튼. (3) 대화창 표시 실패 때 처리. (4) 탭 dirty 점(L-65)이 아직 그려지지 않음.
- 판단: (1) 복원은 PoC 8단계로 v0.4 범위 밖이라 지금은 묻는 쪽(데이터 보존)으로 둔다. 복원을 만들 때 다시 정한다 — 스펙 불일치 목록·사용자 확인 목록. (2) 기본 버튼 Cancel 유지(v0.2 D-12 방식, 안전). (3) 표시 실패 때 Cancel 유지(데이터 보존). (4) P3-4b에서 dirty 점·충돌·지워짐 표시를 함께 그린다.

### H-18 · 2026-11-04 · lead (충돌 판정 기준, 위임 H-4)
- 요청: reviewer P3-4a REWORK 2 — 정규화 텍스트 해시로는 디스크의 인코딩·BOM·줄 끝 변경을 충돌로 보지 못한다. mtime/버전 추적 또는 lead의 명시 결정 필요.
- 판단: 마지막으로 읽거나 저장한 파일의 원본 바이트 해시(디스크 기준)를 탭에 두고, 디스크 원본 바이트 해시가 그것과 다르면 "디스크 변경"으로 본다. mtime은 쓰지 않는다(같은 내용으로 덮어쓰기는 변경이 아님 — Zed와 다를 수 있어 사용자 확인 목록). 정규화 텍스트 해시는 D-046의 불필요한 `set_value` 방지에만 쓴다. 자기 저장은 완료 때 기준 해시를 갱신한다.
- 결과: P3-4a-R1.

### H-19 · 2026-11-04 · lead (Phase 4 모델 카드 선행, 위임 H-4)
- 판단: Phase 3는 마무리 측정(P3-E)만 남았다. impl-editor는 비어 있으니 Phase 4의 P4-1(미리보기 탭·핀 모델)을 work/editor에서 먼저 시작한다. Phase 3 종료(R-15·V3·최종 확인) 전에는 병합하지 않는다(H-12와 같다).

### H-20 · 2026-11-04 · impl-editor → lead (P4-3 범위, 위임 H-4)
- 요청: P4-3 `[BLOCKED]` — workspace의 단일 `pane` 필드를 Pane 트리로 바꾸면 `tab_close.rs`(15곳)·`watch_io.rs`(9)·`panel_nav.rs`(5)·`folders.rs`(2)·`panel_ops.rs`(1)·`watch.rs`(1)의 호출부가 바뀐다(impl-ui 소유). 크기 조절(I-726·I-727)·확대(I-730·I-737)를 넣을지.
- 판단: 이 카드에 한해 위 6개 파일의 `.pane` 호출부 교체만 impl-editor 범위로 지정한다(H-7·H-13과 같다). 그리기(`layout.rs`의 탭 바 여러 개·분할선)와 키 등록(`keymap/`, I-731)은 impl-ui 카드 P4-3b로 나눈다. 사용자 결정 "분할: Zed 원문 전부"(I-706~I-739)에 따라 크기 조절·확대도 넣는다 — 모델 상태(flex 비율, 확대된 pane)는 P4-3, 드래그·그리기는 P4-3b.

### H-21 · 2026-11-04 · lead (R-15 공백: phase2 메뉴 스크립트, 위임 H-4)
- 요청: Phase 3 R-15에서 v0.2 phase2 스크립트가 File 메뉴의 새 행 `Close Editor`(P3-3, 의도한 변경)를 원래 표(`$orig`)에서 찾다 중단해, 뒤의 메뉴 항목 48개와 reload·pending·shadow·prevctx·shadowpp·rapid·chord·quit·closewin 사례가 평가되지 않았다.
- 판단: `tools/verify-v02-phase2.ps1`(v0.2 원본)은 고치지 않는다. `specs/v0.4/verify/scripts/verify-v04-phase2.ps1`에 사본을 두고, 의도한 변경 하나(File 메뉴 `Close Editor|Ctrl-F4` 행과 그 `$orig` 항목)만 반영한다. 다른 기대값은 바꾸지 않는다. 바꾼 줄은 diff로 남긴다. 이 사본으로 phase2를 다시 돌려 나머지 항목을 R-1과 대조한다. Phase 4 이후 R-15에도 이 사본을 쓴다.

### H-22 · 2026-11-04 · lead (Phase 4 UI 카드 선행, 위임 H-4)
- 판단: P4-1·P4-3(work/editor)이 리뷰 PASS다. work/editor를 work/ui에 병합하고 impl-ui가 P4-2(미리보기·핀 탭 표시와 키·닫기 연결)·P4-3b(여러 pane 그리기·분할선·크기 조절 드래그·확대·분할 키 I-731)를 시작한다. master 병합은 Phase 3 종료 뒤에 work/editor → work/ui 순서로 한다(H-12·H-19와 같다).

### H-23 · 2026-11-04 · lead (Phase 3 최종 확인 REWORK 수정 브랜치, 위임 H-4)
- 요청: reviewer Phase 3 최종 확인 REWORK 2건(데이터 보존) — 저장 중 rename/move 뒤 다른 경로에 쓴 결과로 탭을 clean 처리, 삭제된 비어 있지 않은 미리보기 탭을 다음 미리보기 열기가 질문 없이 버림.
- 판단: work/editor·work/ui에는 Phase 4 커밋이 이미 있다(H-19·H-22). Phase 3를 master 기준으로 닫기 위해 editor worktree에서 master `37be418`로 `work/p3fix` 브랜치를 만들어 impl-editor가 두 건을 고친다. 이 카드에 한해 `src/ui/panel_ops.rs`·`folders.rs`의 rename/move 경로도 impl-editor 범위(H-7과 같다). 수정 → reviewer → master 병합·태그 `v0.4-phase-3` → work/editor·work/ui에 master를 병합(충돌은 담당자가 푼다).

### H-24 · 2026-11-04 · lead (P4-4·P4-5 REWORK 처리, 위임 H-4)
- 요청: reviewer P4-4-5 REWORK 5건 — 1 Ctrl 복제 드롭, 2 프로젝트 패널 드래그로 열기(I-721·I-722) 미연결, 3 옆 pane 미리보기의 원문 복귀, 4 frontmatter 판정·렌더(L-110·L-111)가 원문과 다름, 5 dirty 이동·미리보기 갱신·Markdown 치수 테스트 부족.
- 판단: 1·3·5는 고친다. 2는 버전 INTENT "제외 범위: 프로젝트 패널 드래그 앤 드롭"에 해당하므로 넣지 않는다(INTENT가 상위 문서, 분할 결정 "Zed 원문 전부"와의 충돌은 INTENT를 따름) — 스펙 불일치·사용자 확인 목록. 4는 gpui-component 0.8.1에 공개 parser/renderer hook이 있으면 맞추고, 없으면 컴포넌트 한계로 V3 불일치·사용자 결정 목록에 남긴다(D-7 "렌더가 맞추지 못하는 값은 V3 불일치 목록").

### H-25 · 2026-11-04 · lead (L-105 마크다운 제목 선, 위임 H-4)
- 요청: reviewer P4-E-F1 REWORK — h1·h2 아래 선·여백을 위해 제목을 별도 TextView로 떼어 그려 상태 ID 충돌과 참조형 링크 손실이 생겼다.
- 판단: 제목 분리 방식을 되돌린다. gpui-component 0.8.1 TextView 스타일 API에 제목 테두리·여백 설정이 있으면 그것으로 맞추고, 없으면 L-105는 컴포넌트 한계로 V3 불일치·사용자 결정 목록에 남긴다(D-7, H-24의 frontmatter와 같은 기준). U1(첫 화면 끝 단추) 수정은 유지한다.

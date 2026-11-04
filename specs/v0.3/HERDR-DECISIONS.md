# HERDR-DECISIONS — workbench-gpui v0.3 대리 응답 기록

- `lead`가 하위 에이전트의 결정 요청에 대리 응답한 것과, 구성 변경(대체 모델 전환 등)을 기록한다.
- 위임 범위는 `specs/v0.3/HERDR-SETUP.md` 6.5를 따른다. 위임 밖 항목은 사용자에게 올리고, 그 결과도 여기에 남긴다.
- 지난 버전 기록은 `docs/HERDR-DECISIONS.md`(v0.1·v0.2, D-001~)에 있다. 이 문서는 v0.3에서 새로 번호를 매긴다.
- 형식: 항목마다 `### H-n · 날짜 시각 · 요청 에이전트 → 대상` 절을 두고, 요청·판단·근거·결과를 적는다.

## 목록

| ID | 날짜 | 요청 | 내용 | 구분 |
| --- | --- | --- | --- | --- |
| H-1 | 2026-11-03 | lead | spec을 agy `--model gemini-3.8-flash-medium`으로 실행 | lead 판단(구성 세부) |
| H-2 | 2026-11-03 | 사용자 | spec(agy) 폴더 신뢰 확인 승인 | 사용자 지시("눌러줘") |
| H-3 | 2026-11-03 | lead·사용자 | reviewer는 옵션 없이 `codex`로 띄우고 세션 안 `/model`에서 GPT-6.1-Sol medium(세션 한정)을 고른다 | 사용자 선택 뒤 lead 판단 |
| H-4 | 2026-11-03 | 사용자 | 하위 에이전트의 승인·권한 요청은 lead가 판단해 승인한다 | 사용자 위임 |
| H-5 | 2026-11-03 | spec | agy 기본 모드의 명령별 승인 대응: `--mode auto` 재시작은 막혀 기본 모드로 다시 띄우고 F1을 다시 보냄 | lead 판단 |
| H-6 | 2026-11-03 | reviewer | P0-0b cargo build 네트워크 접근 승인 | lead 판단(H-4 위임) |
| H-7 | 2026-11-03 | reviewer | P0-0b cargo run 1회 기동 확인(창 생성 즉시 닫음) 승인 | lead 판단(H-4 위임) |
| H-8 | 2026-11-03 | reviewer | `verify/reviews/baseline-2026-11-03.md` 쓰기(샌드박스 밖 재시도) 승인 — reviewer 소유 경로 | lead 판단(H-4 위임) |
| H-9 | 2026-11-03 | reviewer | P0-0c 실행 래퍼 `verify/baseline/run-p0-0c.ps1` 실행 승인(앱 데이터 백업·해시 대조·복원 포함, d043-clip은 -Before 원본 없음으로 건너뜀) | lead 판단(H-4 위임) |
| H-10 | 2026-11-03 | reviewer | P0-0c 휴지통 판정용 D: 볼륨 정보·BitBucket 레지스트리 읽기(읽기 전용) 승인 | lead 판단(H-4 위임) |
| H-11 | 2026-11-03 | reviewer | P0-0c phase1 1회 재실행(기대표 r1-expected.tsv를 OutDir에 준비) 승인. 래퍼 밖이라 끝난 뒤 앱 데이터 해시 대조·복원을 지시 | lead 판단(H-4 위임) |
| H-12 | 2026-11-03 | reviewer | P0-0c 마무리 확인(앱 데이터 해시 대조, exe 불변, D: 볼륨·휴지통 설정 읽기 → `_backup/final.json`) 승인 | lead 판단(H-4 위임) |
| H-13 | 2026-11-03 | impl-ui | agy 폴더 신뢰 확인(`.worktrees\ui`, 이 저장소의 worktree) 승인 | lead 판단(H-4 위임) |
| H-14 | 2026-11-03 | impl-ui | P0-4 읽기 명령(git branch·rev-parse·파일 목록·줄 수) 1회 승인. 이후 P0-4의 읽기·빌드 명령은 같은 기준으로 승인 | lead 판단(H-4 위임) |
| H-15 | 2026-11-03 | reviewer | P0-6 측정 세션 스크립트 `tools/measure/p0-session.ps1`(Start: 앱 데이터 백업, target 아래 표지 붙은 시험 폴더, 앱 1회 실행 / Snapshot: 덤프·캡처 / Stop: 복원·해시 대조·표지 확인 후 시험 폴더 삭제) 실행 승인. 같은 스크립트의 Snapshot·Stop도 같은 기준으로 승인 | lead 판단(H-4 위임) |
| H-16 | 2026-11-03 | reviewer | P0-6에서 Codex 화면 도구의 workbench-gpui 앱 사용을 "Allow for this session"으로 승인(측정 대상 앱 한정, V3 카드 범위) | lead 판단(H-4 위임) |
| H-17 | 2026-11-03 | reviewer | P0-6 입력 스크립트 `tools/measure/p0-input.ps1`(측정 창이 맨 앞·최대화일 때만, 좌표가 측정 창 안일 때만 클릭·호버, 키는 Esc·F2·F10·Enter·Right·Down만) 승인. 이후 같은 스크립트·Snapshot·p0-show는 lead 감시 스크립트가 자동 승인 | lead 판단(H-4 위임) |
| H-18 | 2026-11-03 | 사용자 → reviewer | P0-6 중 전면에 뜬 "Open With"(OpenWith.exe) 대화상자를 닫으라는 사용자 지시. `p0-input.ps1 -Action DismissOpenWith`(전면 창 클래스·소유 프로세스가 OpenWith일 때만 Esc 1회) 승인 | 사용자 지시 |
| H-19 | 2026-11-03 | reviewer | P0-6 마무리: 측정 프로세스(session.json pid, 경로 확인)만 CloseMainWindow로 닫고 `p0-session.ps1 -Action Stop`(복원·해시 대조·표지 확인 후 시험 폴더 삭제) 승인 | lead 판단(H-4 위임) |
| H-20 | 2026-11-03 | 사용자 | 구성 변경: review(agy Flash high) 카드 리뷰, measure(Claude Code Sonnet medium) 측정·재실행, reviewer(Codex) Phase당 최종 확인 1회 | 사용자 승인 |

## 기록

### H-1 · 2026-11-03 · lead → spec
- 요청: HERDR-SETUP 3.5는 "세션 안에서 gemini-3.8-flash 선택"이지만 `agy models`의 ID에는 effort 접미사가 붙는다(low·medium·high).
- 판단: `herdr agent start spec --kind agy -- --model gemini-3.8-flash-medium`. 기본 effort로 시작한다(HERDR-SETUP 1.1).
- 결과: spec 실행. impl-ui도 같은 방식으로 `claude-sonnet-5-5-medium`을 쓸 예정이다. HERDR-SETUP 3.5 문구 고침은 F4 개정안에 넣는다.

### H-2 · 2026-11-03 · 사용자 → spec
- 요청: agy 시작 때 "Do you trust the contents of this project?"(`D:\projects\workbench-gpui`)
- 판단: 사용자 지시 "눌러줘"로 `herdr agent send-keys spec enter`(Yes).
- 결과: spec idle, F1 지시를 보냈다.

### H-3 · 2026-11-03 · lead·사용자 → reviewer
- 요청: `codex --model gpt-6.1-sol -c model_reasoning_effort=...`가 "Running without the shared background server: ... requires embedded mode" 경고를 냈다. 사용자는 1번(프로필)을 골랐으나 `--profile`도 같은 경고("--profile requires embedded mode")를 냈다.
- 판단: 덮어쓰기 옵션 없이 `codex`로 띄우고 `/model` → GPT-6.1-Sol → Medium → `s`(세션 한정). `~/.codex/config.toml` 기본값(gpt-6.1-terra high)은 바꾸지 않는다.
- 결과: 경고 없이 공유 서버로 실행, 상태줄 `GPT-6.1-Sol medium`. `~/.codex/reviewer.config.toml`(프로필 시도 때 만든 두 줄 파일)은 쓰지 않지만 지우지 않고 남겼다(삭제는 위임 밖). 시도 중 Git Bash가 `/model`을 경로로 바꿔 프롬프트 한 번이 들어갔다(파일 변경 없음, 응답만). 이후 `MSYS_NO_PATHCONV=1`과 `pane send-text`를 쓴다. HERDR-SETUP 3.5 고침은 F4 개정안에 넣는다.

### H-4 · 2026-11-03 · 사용자 → lead
- 요청: 사용자 말 "서브 에이젼트의 승인 요청은 리더가 판단해서 승인해 주세요"
- 판단: HERDR-SETUP 6.4 "승인과 권한 프롬프트는 사용자가 직접 처리한다"를 이 지시로 바꿔 운용한다. 6.5 위임 밖 항목(삭제, push·원격, Cargo 변경, 동작 변경 등)은 여전히 사용자에게 올린다.
- 결과: 이후 하위 에이전트의 승인 프롬프트는 lead가 `herdr agent read`로 내용을 보고 판단해 처리하고 여기에 남긴다. HERDR-SETUP 6.4 문구 고침은 F4 개정안에 넣는다.

### H-5 · 2026-11-03 · spec → lead
- 요청: spec이 `Test-Path spec`, `Get-ChildItem -Path "docs/refs/01-zed"` 같은 읽기 명령마다 승인을 물어 F1이 계속 멈췄다(사용자 알림).
- 판단: `Test-Path spec`은 승인(1회 실행), `Get-ChildItem`은 재시작하면서 취소됐다. 근본 대응으로 `--mode auto` 재시작을 시도했으나 lead 쪽 안전 분류기가 막았다(모든 명령 자동 승인 에이전트 생성). 기본 모드로 다시 띄우고, F1 프롬프트에 "파일은 내장 도구로, 셸 명령은 최소로"를 더해 다시 보냈다.
- 결과: spec working(새 대화). `--mode auto`/`accept-edits` 사용은 사용자 결정으로 남긴다(review-notes N-9).

### H-6 · 2026-11-03 · reviewer → lead
- 요청: P0-0b `cargo build`가 의존성 다운로드를 위한 네트워크 접근 승인을 요청했다.
- 판단: 승인(1회, `y`). `Cargo.lock`에 고정된 크레이트를 crates.io에서 받는 것이라 기준선 빌드에 필요하다. Cargo 파일은 바뀌지 않는다.
- 결과: reviewer working.

### H-20 · 2026-11-03 · 사용자 → lead (구성 변경)
- 요청: 사용자 말 "claude 토큰에 여유가 있으나, codex 여유가 부족 합니다", "gemini 도 여유가 많습니다", "argon 은 사용 불가". lead 안에 "이 구성으로 변경" 선택.
- 판단: 구현자(impl-ui agy Claude, impl-editor Claude Code)와 계열이 다른 Gemini가 카드 리뷰를 맡으면 독립 검증이 된다(HERDR-SETUP 1.2). 측정·재실행은 독립 검증이 아니라 실행이라 Claude로 옮긴다.
  - `review`: agy gemini-3.8-flash-high. 카드 리뷰(diff, 카드 검증 수준만큼 빌드·테스트, 정확성, AGENTS 4장 점검).
  - `measure`: Claude Code Sonnet 5.5 medium. `tools/measure/`, R-12 재실행, V3 실측. measure가 만든 스크립트·결과도 review가 본다.
  - `reviewer`(Codex): Phase당 1회 병합 직전 최종 확인(`@ponytail-review`, 전체 테스트 1회)과 R-12 결과 판정.
- 결과: HERDR-SETUP 1장 표·1.3 토큰 부담·4장 소유권·변경 이력 반영. Phase 1 카드 담당을 바꾼다(P1-1 lead, P1-5 measure).

### H-21 · 2026-11-03 · lead (Phase 1 새 세션, 9장)
- 요청: HANDOFF "다음 할 일" 2, 사용자 말 "불필요한 herdr 패널을 정리해 주세요"
- 판단: 워크스페이스는 `workbench-gpui`·`wt-ui` 둘뿐(1.3 가정 그대로). impl-ui는 agy `/clear`로 새 대화. verify 탭에 `review`(`wD:p5`, agy gemini-3.8-flash-high)·`measure`(`wD:p6`, claude sonnet medium) 새로 띄움. 빈 shell `wD:p4`·`wE:p2` 닫음. spec(`wD:p2`, Phase 1 카드 없음)·reviewer(`wD:p3`, 컨텍스트 79%, Phase 끝에 새로 띄움)도 닫으려 했으나 lead 안전 분류기가 막아 사용자에게 올림.
- 결과: `.worktrees/ui` `git merge --ff-only master` → `6cf94ed`.

### H-22 · 2026-11-03 · impl-ui → lead
- 요청: P1-2에서 `Cargo.toml`을 "Create file"(내용 3줄: `[dev-dependencies]`, `toml = "=1.1.8"`)로 만들겠다는 승인. 그 전에 읽기 명령 2건(`Select-String`, `git status`) 승인 요청.
- 판단: 읽기 명령은 1회 승인. "Create file"은 기존 `Cargo.toml` 전체를 덮어써 의존성을 지우므로 거부하고, 파일 끝에 덧붙이라고 지시했다. 다시 온 편집(+4 −1, `trash` 줄 뒤에 빈 줄·`[dev-dependencies]`·`toml = "=1.1.8"`)은 사용자 승인 범위 그대로라 승인.
- 결과: impl-ui working. lead 감시 스크립트 패턴에 agy 편집 승인 문구를 더했다.

### H-23 · 2026-11-03 · lead (impl-ui 편집 승인 방식)
- 요청: impl-ui(agy 기본 모드, F5 Q-4)가 편집마다 승인을 묻는다.
- 판단: agy 모드는 바꾸지 않는다. lead 감시 스크립트가 impl-ui의 "Pending edit" 가운데 이번 카드 범위 파일(`src/ui/metrics.rs`·`layout_probe.rs`·`mod.rs`, `src/dev.rs`, worktree 안)만 승인하고 `scratchpad/auto-approved.log`에 경로를 남긴다. 새 파일 생성, 명령 실행, 범위 밖 경로, `Cargo.toml`은 lead가 직접 본다. 내용은 카드 리뷰(review)가 diff로 본다.
- 결과: 첫 편집 `src/ui/metrics.rs` +100 −1 승인(P1-2 헬퍼).

### H-24 · 2026-11-03 · 사용자 → lead
- 요청: lead 제안 두 가지에 사용자 말 "제안대로 진행해 주세요".
- 판단: (1) P1-3은 일반 `#[test]` 상수 대조. gpui-kit `test-support`(Cargo 변경)는 쓰지 않는다. 렌더 경계는 V3(P1-4 JSON, P1-5)가 맡는다. (2) spec(`wD:p2`)·reviewer(`wD:p3`) pane을 닫는다. reviewer는 Phase 1 끝 최종 확인 때 새로 띄우고 `/model` Sol·Medium을 다시 맞춘다. spec은 카드가 생길 때 띄운다.
- 결과: TASKS P1-3 범위, `verify/phase1/layout-test-req.md` 6절 갱신. 두 pane 닫음. verify 탭에는 review(`wD:p5`)·measure(`wD:p6`), control 탭에는 lead만 남았다.

### H-25 · 2026-11-03 · 사용자 → lead
- 요청: P1-5에서 measure가 `tools/measure/p0-session.ps1`→`session.ps1`, `p0-input.ps1`→`input.ps1`로 이름을 바꿨다(옛 경로 삭제라 위임 밖). lead 제안 "받아들이고 README에 대응 한 줄"에 사용자 말 "제안대로 진행해 주세요".
- 판단: 이름 변경 승인. P0 기록 문서(`measure-p0.md` 등)는 옛 이름 그대로 둔다(내용은 git 이력).
- 결과: measure에 README 대응 한 줄 지시. 덧붙여 H-23 자동 승인 범위를 넓혔다: impl-ui·review의 읽기 전용 명령(`Select-String`·`Get-Content`·`Get-ChildItem`·`git status/log/diff/show/branch`, 쓰기 토큰 없을 때)도 감시 스크립트가 승인하고 로그에 남긴다.

### H-26 · 2026-11-03 · 사용자 → lead (v0.3 권한 위임)
- 요청: 사용자 말 "이제 잘 시간입니다. v0.3 작업에 대한 권한을 리더에게 위임합니다. 플랜에 따라 순차적으로 진행해 주세요. 모든 단계를 진행하고 결과를 보고해 주세요."
- 판단: 사용자 부재 동안 PLAN 순서대로 진행한다(Phase 1 끝 P1-E → Phase 2 → Phase 3 → Phase 3 뒤 데이터 손실 수정). 6.5 위임 밖 항목도 v0.3 범위 안에서는 lead가 판단하고 여기에 남긴다. 다만 되돌릴 수 없거나 외부로 나가는 것은 하지 않는다: push·원격 설정, 사용자 파일·설정 변경, 지난 버전 폴더 쓰기, 새 크레이트 추가. 동작이 바뀌는 수정(Phase 3 뒤 카드)은 PLAN·AUDIT 채택 목록에 이미 승인된 범위만 하고 별도 커밋으로 둔다. 계획 변경이 필요하면 멈추고 보고로 남긴다.
- 9장(Phase마다 lead 새 세션) 예외: 사용자가 없어 새 lead를 띄울 수 없으므로 이 lead 세션이 이어간다. Phase마다 HANDOFF 맨 위 절을 갱신하고 하위 에이전트는 새 대화로 시작한다.
- R-12 재실행은 사용자 부재(입력 없음) 조건을 만족한다.

### H-27 · 2026-11-03 · lead (미결 처리, 위임 H-26)
- 요청: Phase 2 진행에 DECISIONS 미결 "스펙에 없는 수치를 어떻게 다룰지"가 걸린다. 사용자 부재.
- 판단: 가장 되돌리기 쉬운 쪽으로 정한다. 스펙에 없는 수치도 `src/ui/metrics.rs` 상수로 옮기고 주석을 `// spec: none (app value)`로 단다. `spec/zed-metrics.toml`에는 넣지 않는다(spec 소유, 추정 입력 금지). R-10 집계에서는 metrics.rs 안이므로 0건 판정에 들어간다. `px(0.)`은 gpui 상수(`Pixels::ZERO` 등)로 바꿔도 값이 같다.
- 결과: TASKS Phase 2 카드에 반영. DECISIONS.md(사용자 소유)는 고치지 않는다. 사용자 확인 필요 목록에 올린다. 다르게 정하면 주석만 바꾸면 된다.

### H-30 · 2026-11-04 · lead (P3-R1 테스트 방식, 위임 H-26)
- 요청: Phase 3 최종 확인 REWORK 1(P3-2 비활성 항목 회귀 테스트). impl-ui `[BLOCKED]`: 메뉴 intercept를 그대로 거치려면 `#[gpui::test]`가 필요한데 gpui test-support가 꺼져 있다. 선택지 (a) Cargo.toml dev-dependency에 test-support 추가, (b) intercept의 enabled 판정을 순수 함수로 빼고 `#[test]`.
- 판단: (b). Cargo 변경은 위임 범위 밖이고(H-26), H-24에서도 test-support 없이 `#[test]`로 정했다. (b)는 동작을 바꾸지 않는 추출이라 Phase 3 리팩토링 범위다. `Chord::feed` 결과(`Feed`)와 항목 enabled 조회를 받아 "예약할 항목·소비 여부"를 돌려주는 함수 하나로 하고, intercept는 그 결과대로만 움직인다. reviewer가 같은 판단 경로를 거치는지 재확인한다. 사용자 확인 목록에 올린다.

### H-29 · 2026-11-04 · lead (impl-ui 대체 모델, 위임 H-26)
- 요청: Phase 3 착수 시점(08:59)에 impl-ui agy Claude 5시간 한도 100%(초기화 12:20). 사용자 지시 "멈추지 말고, 단계별로 모든 phase 를 진행해 주세요."
- 판단: HERDR-SETUP 1.1에 미리 정한 대체(`impl-ui` → Claude Code, Sonnet 5.5, effort medium)로 바꾼다. 같은 pane `wE:p1`, 같은 worktree `.worktrees/ui`, 이름 `impl-ui`. Claude 구독은 여유(사용자 2026-11-03), measure와 같은 구독이라 동시에 무거운 작업을 돌리지 않는다. 역할·소유권·지침은 그대로. 사용자 확인 목록에 올린다.

### H-28 · 2026-11-04 · lead (measure 클립보드, 위임 H-26)
- 요청: P1-E R-12 phase4·d043·d044가 클립보드 보호 동작으로 두 번 멈췄다. 사용자가 비운 뒤에도 형식 49161(DataObject)·49171(Ole Private Data)과 텍스트 형식(13·16·1·7)이 남았다(OLE 텍스트 복사 래퍼).
- 판단: 사용자가 클립보드를 비웠고 진행을 지시했으므로 내용은 보존 대상이 아니다. measure가 각 스크립트 직전에 `[System.Windows.Forms.Clipboard]::Clear()`로 비우고 형식 0개를 확인한 뒤 실행한다. 스크립트 보호 동작은 고치지 않는다. 실행 중에는 measure에 프롬프트를 보내지 않는다.
- 결과: measure에 지시. 감시 스크립트가 보고를 놓쳐 이후 대기는 `herdr agent prompt --wait` 백그라운드로 한다.

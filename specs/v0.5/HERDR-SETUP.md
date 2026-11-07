> 버전: v0.5 · 작성일: 2026-11-06 · 상태: 확정 (core-leader 판정, 사용자 위임 2026-11-06)
>
> workbench-gpui v0.5의 herdr 멀티 에이전트 구성, 레이아웃, 작업 프로토콜, 최초 지시 프롬프트, 정리 방법을 담는다. 구성은 workbench-core가 정했고(core D-2·D-4), ORDER-01 3.2·3.3을 그대로 옮겼다. 요구는 `SPEC.md`에, Phase는 `PLAN.md`에 있다. 지난 구성은 `specs/v0.4/HERDR-SETUP.md`이고 고치지 않는다.
>
> 이 문서는 사용자 승인 뒤 writer가 쓰고 leader가 확인한다(`AGENTS.md` 레포 규칙 "HERDR 문서").

# HERDR-SETUP — workbench-gpui v0.5

## 0. 근거

- core D-2: 갈래 에이전트 환경은 core가 정하고, 갈래마다 leader와 서브 에이전트 셋(writer·coder·checker)으로 둔다(`D:\projects\workbench-core\specs\v0.5\DECISIONS.md`).
- core D-4: 화면 차례는 `[SCREEN-REQ]`·`[SCREEN-OK]`·`[SCREEN-DONE]` 메시지로 주고받는다.
- core D-1(화면을 다루는 확인은 한 번에 하나), D-3(공통 지시 카드와 파일 보고), D-7(자기 워크스페이스만 쓴다).
- ORDER-01 3.2·3.3(`D:\projects\workbench-core\specs\v0.5\orders\ORDER-01.md`). 이 카드가 `AGENTS.md` 역할 절과 이 문서를 고치라는 사용자 지시다(사용자 2026-11-06, ORDER-01 3.1·5장).
- leader 확인 사실(2026-11-06, W-01): pane·탭 배치, 실행 명령, 남은 worktree, 서브 에이전트 카드 위치.
- ORDER-01-R2(`D:\projects\workbench-core\specs\v0.5\orders\ORDER-01-R2.md`): 승인 위임(5.6), 구독 현황(3장), v0.4 worktree 정리(2장). 사용자 "미정 네 가지 제안대로 진행해 주세요"(2026-11-06).
- core D-13: 사용자 권한을 core-leader에게 위임한다. 갈래 leader가 사용자에게 물을 것은 core-leader에게 묻는다(사용자 2026-11-06).

---

## 1. 에이전트 구성

| herdr 이름 | 하는 일 | 도구·모델 | 띄우는 때 |
|---|---|---|---|
| `gpui-leader` | 카드 지시, 판정, 커밋, core-leader와 화면 차례 조율(core D-4). 코드·문서는 쓰지 않는다 | Claude Code Opus 5.5 (기존 세션) | 상시 |
| `gpui-writer` | v0.5 문서(INTENT·DECISIONS·SPEC·PLAN·HERDR-SETUP)와 PROGRESS | Claude Code Opus 5.5 medium | 문서 단계와 Phase 끝 |
| `gpui-coder` | 구현 전부(UI·코어를 나누지 않는다) | Codex gpt-6.1-sol medium (2026-11-07 12:14~14:05 Claude Code Sonnet 5.5 high, 2.1) | 구현 Phase 동안 |
| `gpui-checker` | 카드 리뷰(정확성, 카드 검증 수준만큼 빌드·테스트), 화면 검증(V2·V3)과 측정. src는 고치지 않는다 | agy gemini-3.8-flash-high | 리뷰·검증 카드가 있을 때 |

- herdr 에이전트 이름은 세션 안에서 유일해야 하므로 `gpui-` 접두사를 붙인다(`herdr agent rename`).
- 리뷰 독립성: coder(Codex)와 writer(Claude)의 산출물은 checker(agy)가 검토한다.
- Codex는 coder에만 쓴다. 두 갈래 coder가 같은 Codex 구독을 나눠 쓴다. 한도가 바닥나면 직접 쿠폰을 쓰지 않고 leader가 core-leader에게 `[BLOCKED]`로 알린다. 쿠폰은 core-leader가 사용자에게 알리고 쓴다.
- 검증 수준(V0~V4)과 앱 실행 제한은 `AGENTS.md` 3A를 그대로 쓴다.
- v0.4 구성에만 있던 에이전트(`spec`·`reviewer`·`review`·`measure`·`impl-ui`·`impl-editor`)는 두지 않는다. pane이 남아 있으면 닫는다(ORDER-01 3.2).

---

## 2. herdr 레이아웃

```text
workspace: workbench-gpui (wD)   D:\projects\workbench-gpui, 브랜치 master, worktree 없음
├── tab: control (wD:t1)   gpui-leader   (wD:p1)
├── tab: docs    (wD:t4)   gpui-writer   (wD:pD)
├── tab: impl    (wD:t5)   gpui-coder    (wD:pE)
└── tab: check   (wD:t6)   gpui-checker  (wD:pF)
```

- ID는 2026-11-06 leader 확인 값이다. 다시 띄우면 바뀔 수 있으므로 `herdr agent list`·`herdr tab list`로 확인하고 이름으로 부른다.
- worktree는 두지 않는다(core D-2). v0.4의 `.worktrees\editor`·`.worktrees\ui`와 로컬 브랜치 `work/editor`·`work/ui`는 master에 병합된 것을 확인한 뒤 2026-11-06 leader가 지웠다(ORDER-01-R2 C, `DECISIONS.md` D-2).

### 2.1 실행 명령

```powershell
# gpui-leader
claude --model opus --effort high      # 기존 세션
# gpui-writer
claude --model opus --effort medium
# gpui-coder
codex     # 옵션 없이 띄운다. 세션 안에서 /model → GPT-6.1-Sol → Medium → s(세션 한정). v0.3 H-3
# gpui-checker — 현재 실행 명령 (2026-11-06, 미리 허용 설정을 이 세션에만 적용, 5.6)
agy --model gemini-3.8-flash-high --settings D:\projects\workbench-gpui\.agents\checker-settings.json
```

- checker는 사용자 승인("checker가 승인 창 없이 명령을 실행하게 하는 설정하도록 승인합니다", core-leader 전달 2026-11-06)으로 leader가 위 명령으로 다시 띄웠다. 이번에는 거부되지 않았다(leader 2026-11-06, W-08).
- 허용 목록이 동작한다. 목록에 정확한 명령 모양으로 있는 명령은 승인 창 없이 돈다. 대체 방식(출력 파일)은 끝냈다. 목록 밖 명령은 승인 창이 뜨고 leader가 판단한다(5.6 현재 상태, leader 2026-11-06, W-09).

- Codex 한도가 다시 바닥나면 기다리거나 쿠폰을 쓰지 않고 coder를 Claude Code Sonnet 5.5 high(`claude --model sonnet --effort high`)로 바꿔 같은 pane·이름 `gpui-coder`로 잇는다. 바꾼 시각·모델을 이 절과 PROGRESS에 적는다(core D-16, 사용자 결정 2026-11-07).
  - 2026-11-07 12:14: `gpui-coder`를 Codex(GPT-6.1-Sol medium, 5시간 한도 6% 남음)에서 Claude Code Sonnet 5.5 high로 바꿨다. pane `wD:pE`, 이름 그대로(D-16, leader W-28).
  - 되돌리기: 14:00 Codex 한도 초기화 뒤, 그때 진행 중인 카드가 끝나는 때에 Codex(GPT-6.1-Sol medium)로 되돌리고 시각을 여기에 적는다(사용자 결정). 되돌린 시각: 2026-11-07 14:05. K-20이 끝난 카드 경계에서 Codex GPT-6.1-Sol medium으로 되돌렸다. Codex가 시작할 때 자체 업데이트로 한 번 종료돼 다시 띄웠다(leader W-29).
- coder는 컨텍스트를 비운(`/clear`) 뒤에는 `/model`로 Sol medium을 다시 고른다. `/clear` 뒤 기본값(GPT-6.1 Terra high)으로 돌아가 K-02가 Terra high로 실행된 일이 있다(leader 2026-11-07, W-10).
- leader의 effort는 high다(v0.4와 같음, leader 2026-11-06 W-03). core D-2는 "Claude Code Opus 5.5 (기존 세션)"이라고만 적었다.
- Git Bash에서 `/model`처럼 `/`로 시작하는 문자열을 herdr로 보낼 때는 `MSYS_NO_PATHCONV=1`을 붙인다(ORDER-01 3.3, v0.3 H-3).

### 2.2 빌드·실측 환경

`specs/v0.4/HERDR-SETUP.md` 3.4와 같다. 바뀌지 않았다.

- Rust 1.99.1, Build Tools 2022, Windows SDK 10.0.26100.0, PowerShell 7, Python은 WinPython 전체 경로.
- `CARGO_TARGET_DIR`은 `D:\projects\workbench-gpui\target` 하나다. 잠금 파일을 지우지 않는다.
- 빌드할 때마다 `pwsh -NoProfile -File tools/apply-manifest.ps1`을 다시 실행한다.
- `tools\verify-v02-*.ps1`은 항상 `-OutDir specs\v0.5\verify\...`를 넘긴다.
- 화면: 주 모니터 1920x1080, 100%(DPI 96). Zed와 비교하는 판정은 창 1440×852, 화면 배율 100%, 같은 폴더·파일·테마에서 한다(core D-11).

---

## 3. 근거·토큰 부담

레포 규칙 "HERDR 구성은 구독·토큰 부담으로 정한다"에 따라 둔다.

- 구성 근거: core D-2 근거를 따른다. 서브 에이전트는 최소한으로 둔다(토큰 사용량과 컨텍스트 손실, 사용자 2026-11-06). 구독 현황은 core-leader가 사용자에게 확인했다(2026-11-06, core D-2): Claude 여유(Opus 5.5 medium 가능), Codex 여유(gpt-6.1-sol medium, 초기화 쿠폰 있음), agy 여유(gemini-3.8-flash-high, Argon 사용 불가).
- 구독 현황은 위 core D-2 근거의 "여유"로 적고, 남은 한도·초기화 시점 수치는 적지 않는다(사용자 2026-11-06, ORDER-01-R2 B).
- 동시에 도는 다른 워크스페이스: workbench-core(core-leader), workbench-tauri(tauri-leader와 서브 에이전트 셋). 두 갈래 coder가 같은 Codex 구독을 나눠 쓴다(core D-2).

| 구독 | 구독 현황(core D-2) | 이 워크스페이스 | 조정 |
|---|---|---|---|
| Claude | 여유 | `gpui-leader` Opus high | 판단 위주, 코드·문서를 쓰지 않는다 |
| Claude | 여유 | `gpui-writer` Opus medium | 문서 단계와 Phase 끝에만 띄운다 |
| Codex | 여유, 초기화 쿠폰 있음 | `gpui-coder` gpt-6.1-sol medium | tauri-coder와 나눠 쓴다. 바닥나면 core-leader에게 `[BLOCKED]` |
| agy | 여유(Argon 사용 불가) | `gpui-checker` gemini-3.8-flash-high | 리뷰·검증 카드가 있을 때만 띄운다 |

- 한도가 바뀌어 구성을 바꾸면 다시 승인받는다(레포 규칙).

---

## 4. 파일 소유권

| 경로 | 쓰는 이 | 비고 |
|---|---|---|
| `specs/v0.5/INTENT.md`, `DECISIONS.md`, `SPEC.md`, `PLAN.md` | `gpui-writer` | 상태 확정은 core-leader 판정 뒤 사용자가 정한다. PLAN 진행 현황 표는 writer가 갱신하고 leader가 확인한다(leader 2026-11-06 W-03) |
| `specs/v0.5/HERDR-SETUP.md` | `gpui-writer` | 사용자 승인 뒤 쓰고 leader가 확인한다 |
| `specs/v0.5/PROGRESS.md` | `gpui-writer` | core D-2 |
| `specs/v0.5/cards/<ID>.md` | `gpui-leader` | 서브 에이전트 카드(`DECISIONS.md` D-1) |
| `specs/v0.5/cards/<ID>.report.md` | 그 카드를 받은 에이전트 | 보고 |
| `specs/v0.5/reports/ORDER-<n>.md` | `gpui-leader` | core-leader에게 보내는 보고(core D-3) |
| `src/`, `resources/`, core D-8·D-9 복사 폴더(경로 미정), core D-10 글꼴 파일(경로 미정) | `gpui-coder` | 구현 전부(core D-2). `Cargo.toml`·`Cargo.lock`은 승인 없이 바꾸지 않는다 |
| `specs/v0.5/verify/` | `gpui-checker` | 리뷰·측정 결과 |
| `tools/measure/` | `gpui-checker` | 측정 스크립트. v0.4 `measure` 역할을 잇는다 |
| `.agents/checker-settings.json` | `gpui-leader` | checker 미리 허용 목록(5.6). 승인 범위를 바꾸는 파일이라 고칠 때 core-leader 승인을 받는다(leader 2026-11-06, W-06) |
| `spec/zed-metrics.toml`, `spec/INDEX.md`, `spec/ambiguous.md` | `gpui-writer` | leader 카드로만 고친다. Zed 값 확인은 `gpui-checker`가 보고로 넘기고, `gpui-coder`는 읽기만 한다(core-leader 사용자 위임 2026-11-06, core D-13, ORDER-01-R2 D, `DECISIONS.md` D-3) |
| 그 밖의 `tools/` | 미정(leader가 카드로 지정) | 없음 |

- 커밋은 leader만 한다. push는 하지 않는다(ORDER-01 7장).
- 아무도 고치지 않는 것: `specs/v0.1/`~`specs/v0.4/`, `docs/HERDR-*.md`, `docs/refs/`.
- 다른 워크스페이스(workbench-core, workbench-tauri)의 파일은 읽기만 한다(core D-7).

---

## 5. 작업 프로토콜

### 5.1 core → leader

- core-leader가 `D:\projects\workbench-core\specs\v0.5\orders\ORDER-<n>.md` 경로를 herdr 프롬프트로 보낸다.
- 카드 번호는 core Phase 번호와 같고 두 자리로 쓴다(`ORDER-01`~`ORDER-12`). 같은 Phase 안에서 다시 지시하면 `-R<n>`을 붙인다(예: `ORDER-03-R1`). 보고 파일도 카드와 같은 이름을 쓴다.

### 5.2 leader → core

- leader가 결과를 `specs/v0.5/reports/ORDER-<n>.md`에 쓰고, `herdr agent prompt core-leader "<보고 파일 절대 경로>"`로 경로만 보낸다.

### 5.3 leader → 서브 에이전트

- leader가 카드 하나만 읽고 일할 수 있게 `specs/v0.5/cards/<ID>.md`를 쓰고, 그 경로를 herdr 프롬프트로 보낸다(`DECISIONS.md` D-1).
- 프롬프트 예: `너는 gpui-writer다. D:\projects\workbench-gpui\specs\v0.5\cards\W-01.md 를 읽고 그대로 진행하라. 끝나면 보고 파일 경로만 답하라.`
- 받는 에이전트는 `specs/v0.5/cards/<ID>.report.md`에 `AGENTS.md` 8장 형식(`[DONE]`·`[MEASURED]`·`[BLOCKED]`)으로 보고하고, 답으로는 그 경로만 말한다.
- 카드 ID 접두사는 받는 역할의 첫 글자다: `W-`(writer), `C-`(checker), `K-`(coder). 예: `W-01`(leader 2026-11-06 W-03).

### 5.4 화면 차례

1. checker가 화면 검증(V2·V3, 배율 변경 포함)이 필요하면 자기 leader에게 알린다.
2. leader가 `herdr agent prompt core-leader "[SCREEN-REQ] gpui <카드 ID>"`를 보낸다.
3. core-leader가 `[SCREEN-OK] <카드 ID>`를 보낸 뒤에만 화면을 쓴다. 최대 30분 기다리고, 오지 않으면 `[BLOCKED]`로 보고한다. 그동안 화면이 필요 없는 작업은 계속한다.
4. 끝나면 leader가 `herdr agent prompt core-leader "[SCREEN-DONE] gpui <카드 ID>"`를 보낸다.

- 화면을 다루는 확인(자동 검증 스크립트, 디스플레이 배율 변경, 앱 창 포커스·입력·캡처)은 같은 갈래 안에서도 한 번에 하나만 한다(core D-1).
- 사용자가 UI를 직접 확인하는 동안에는 core-leader가 `[SCREEN-OK]`를 보내지 않는다(core D-4).
- **기존 창 보호**: 측정·확인 때는 자기가 띄운 프로세스(PID로 기록)만 닫고 끝낸다. 이미 열려 있던 Zed·앱 창과 프로세스는 닫거나 `Stop-Process`하지 않는다. 이름으로 모든 프로세스를 끝내지 않는다(`Stop-Process -Name` 대신 `-Id <띄운 PID>`). 계기: C-08에서 checker가 이미 열려 있던 Zed 창을 닫고 zed 프로세스를 모두 끝냈다(2026-11-07). (core-leader DECISION 2026-11-07, D-13)
- **입력이 필요한 확인**: checker(agy)는 격리된 가상 데스크톱에서 돌아 `SetCursorPos`·`SendInput`이 실패한다(C-08). 마우스·키 입력이 필요한 확인(호버, 스크롤, 커서 이동 등)은 leader가 화면 차례 안에서 `tools/`의 입력 스크립트를 실행하고 출력·캡처 파일을 남기며, checker는 그 파일로 판정한다. (core-leader DECISION 2026-11-07, D-13)
- **화면 확인 캡처**: `tools/capture.ps1 -Method Screen`을 쓴다. PrintWindow는 DirectComposition 오버레이(스크롤바 등)를 빠뜨린다(C-09).
- **창 크기**: 측정 스크립트는 창 크기를 `Ensure-ClientSize`로 맞추고 `GetClientRect`로 클라이언트 1440×852를 확인한다. 바깥 크기(1442×853 등)로 `SetWindowPos` 하지 않는다. 계기: ORDER-04 `order04-v3.ps1`이 `SetWindowPos(1442,853)`을 넣어 클라이언트가 1426×845가 됐다(ORDER-05 I-6 재측정으로 앱 퇴행 아님을 확인, 2026-11-07).
- **측정 세션 도구**: checker는 `tools/measure/session.ps1`과 측정 스크립트를 직접 실행하지 않는다(Start·Stop 모두, 시험용도 금지). `-DryRunStdout` 모드만 실행한다. 실제 실행은 leader가 화면 차례 안에서 한다. 계기: ORDER-06-R2 V3 시도 (2)에서 세션이 멈춰 사용자 `state.json`이 잠시 없었고, checker가 실제 실행 시험을 하려 했다(백업 삭제 위험). (core ORDER-07 추가 (b), C-30)
- **Zed 창**: Zed는 `zed -n`으로 연 자기 창 안에서만 파일을 연다. `-a`는 쓰지 않는다(V3에서 `zed -a`로 사용자 Zed 창에 탭이 추가된 사고, C-15).

### 5.5 그 밖

- 진행 상태는 PROGRESS에 두고 세션 기억에 기대지 않는다.
- Git Bash에서 `/`로 시작하는 문자열을 herdr로 보낼 때는 `MSYS_NO_PATHCONV=1`을 붙인다.
- herdr가 '대기'로 표시해도 바로 입력을 보내지 않는다. 먼저 `herdr pane read`로 화면을 확인한다. agy는 백그라운드 작업이 남아 있어도 '대기'로 표시되므로, checker의 완료는 보고 파일로 판정한다.

### 5.6 승인 처리

- 서브 에이전트의 승인 요청(권한·도구 실행 프롬프트)은 leader가 대신 응답한다(사용자 2026-11-06, core ORDER-01-R2 A). leader는 `herdr pane read`로 내용을 보고 판단한다.
- 위임에서 빠지는 것(leader가 core-leader에게 묻는다. core D-13, 사용자 권한 위임 2026-11-06):
  - 의존성 추가·제거·버전 변경(`Cargo.toml`, `Cargo.lock`)
  - HERDR 구성 변경(모델·effort·역할·pane)
  - push
- 기록: leader가 처리한 판단은 출처를 달아 `specs/v0.5/PROGRESS.md`에 남긴다. 별도 HERDR-DECISIONS 문서는 두지 않는다(leader 2026-11-06 W-03).
- 미리 허용 목록(checker, core ORDER-01-R3, 사용자 2026-11-06 "제안대로 진행해 주세요"): checker가 맡은 일의 명령은 승인 없이 돌게 한다. leader의 권한은 넓히지 않는다.
  - 위치: 레포 `.agents/checker-settings.json`. checker를 `agy --model gemini-3.8-flash-high --settings D:\projects\workbench-gpui\.agents\checker-settings.json`으로 띄워 그 세션에만 적용한다(`agy --help`, 2.1). agy 전역 설정(`C:\Users\nampl\.gemini\antigravity-cli\settings.json`)은 레포 밖이라 고치지 않는다(core D-7). 레포 안 프로젝트 설정 파일 위치는 agy 문서에 없다(leader 조사 2026-11-06).
  - 형식: `{"permissions":{"allow":["command(<명령>)", ...]}}`(workbench-tauri `.agents/checker-settings.json`과 같은 형식). 앞부분 일치가 아니라 정확한 명령 모양이 맞아야 허용되는 것으로 보인다(leader 2026-11-06, W-09).
  - 허용 목록: 기준은 `.agents/checker-settings.json`이다. 이 문서에 목록을 옮기지 않는다. 목록에 더할 명령은 leader가 core-leader에게 알린다. core-leader가 사용자 요청으로 정확한 명령(`git diff --stat`, `git status --short`, `git log --oneline -5`, 빌드·clippy 변형)을 더했다(core D-7 예외, 사용자 요청, 2026-11-06).
  - 넣지 않은 것: `tools/set-scale.ps1`(디스플레이 배율 변경은 화면 차례 core D-4로 leader가 따로 승인), `git commit`·`push`·`reset`·`checkout`·`switch`·`branch`·`rm`, 파일 삭제, `cargo add`·`remove`·`install`, 내려받기(`curl`, `Invoke-WebRequest`), python 실행. 목록에 없는 명령은 승인 창이 뜨고 leader가 위 위임대로 판단한다.
  - deny는 두지 않는다. tauri 시험(core-leader 2026-11-06)에서 deny를 함께 두면 허용 명령도 승인 창이 떴고, allow만 두면 승인 없이 돌았다.
  - 화면을 다루는 스크립트(`capture.ps1`, `verify-*.ps1`, `tools/measure/`)는 허용되어 있어도 `[SCREEN-OK]`를 받은 뒤에만 실행한다(5.4).
  - 대체 방식(core-leader 2026-11-06): 허용이 동작하지 않거나 설정을 쓸 수 없으면, checker가 실행할 명령은 coder 또는 leader가 실행하고 출력을 `%TEMP%\v05-<카드ID>-*.txt`로 남긴다. checker는 그 파일을 읽어 판정한다.
  - 지난 상태(leader 2026-11-06, W-06): leader가 checker를 `--settings`로 다시 띄우려 하자 leader 세션 자동 모드가 `[Self-Modification]`으로 거부했고, core-leader 지시대로 우회하지 않았다.
  - 지난 상태(leader 2026-11-06, W-08): 사용자 승인("checker가 승인 창 없이 명령을 실행하게 하는 설정하도록 승인합니다", core-leader 전달)으로 leader가 gpui-checker(wD:pF)를 `--settings`로 다시 띄웠고(2.1), 거부되지 않았다. agy 로그(`C:\Users\nampl\.gemini\antigravity-cli\log\cli-20261106_231823.log`)에 `CLI settings initialized: permissions=&{Allow:[command(git diff) ... ] Deny:[] Ask:[]}, toolPermission=request-review`로 허용 목록이 읽혔다. 그런데 checker가 `git diff --stat`을 실행하자 승인 창이 떴다(leader가 1회 승인). 같은 로그에 `ApplyProjectPermissionGrants: no grants for project "CLI Project", cleared project permissions` 줄이 있다.
  - 현재 상태(leader 2026-11-06, W-09): core-leader가 사용자 요청으로 허용 목록에 정확한 명령을 더한 뒤, leader가 checker를 `--settings`로 다시 띄워 `git diff --stat`을 시켰더니 승인 창 없이 돌았다. 허용 목록이 동작하므로 대체 방식(출력 파일)은 끝낸다. 단, 목록 밖 명령은 승인 창이 뜨고 leader가 위 위임대로 판단한다. 예: C-05 실측 중 `Get-ChildItem`, `Get-Process`, `pwsh -NoProfile -Command ...`, `Start-Process`, `Remove-Item` 등은 승인 창이 떴고 leader가 위임으로 판단했다.
  - 대체 방식 시험(C-03, 2026-11-06, 지난 방식): leader가 `git diff --stat` 출력을 `C:\Users\nampl\AppData\Local\Temp\v05-C-03-git-diff-stat.txt`로 남겼고, checker가 그 파일을 승인 창 없이 읽어 바뀐 파일 3개를 맞게 보고했다.

---

## 6. 최초 지시 프롬프트

coder와 checker는 ORDER-01에서 띄우고 역할만 확인시킨다. 코드를 고치거나 앱을 실행하지 않고 다음 카드를 기다리게 한다(ORDER-01 3.2).

```text
너는 workbench-gpui v0.5의 <gpui-coder | gpui-checker>다. 루트 AGENTS.md와 specs/v0.5/HERDR-SETUP.md(1장 구성, 4장 소유권, 5장 프로토콜)를 읽어라.
읽은 뒤 자기 역할을 한 줄로 확인하고, gpui-leader의 카드(specs/v0.5/cards/<ID>.md)를 기다려라. 카드 전에는 파일을 고치지 않고 앱을 실행하지 않는다.
```

- 작업 지시는 5.3의 카드 경로 프롬프트로 한다.
- 실제로 보낸 것: 역할 확인만 시키고 다음 카드를 기다리게 했다(ORDER-01 3.2). 위 문구는 그 취지의 예시다(leader 2026-11-06 W-03).

---

## 7. 정리 방법

- Phase가 바뀔 때 서브 에이전트의 컨텍스트를 비운다(core D-2). 할 일이 없는 서브 에이전트는 닫아도 된다.
- 다만 ORDER-01 완료 시점에는 writer·coder·checker 셋 모두 떠 있어야 한다(ORDER-01 3.2·4장).
- v0.4 에이전트 pane이 남아 있으면 닫는다(ORDER-01 3.2). v0.4 worktree와 로컬 브랜치 `work/editor`·`work/ui`는 2026-11-06에 지웠다(ORDER-01-R2 C).
- 버전이 끝나면 다음 버전의 `specs/{새 버전}/HERDR-SETUP.md`를 새로 쓴다. 이 문서는 고치지 않는다.

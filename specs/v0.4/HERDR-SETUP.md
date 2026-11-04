# HERDR-SETUP — workbench-gpui v0.4 멀티 에이전트 운영

- 상태: 확정 (2026-11-04, 사용자 계획 승인)
- 지난 버전 구성: `specs/v0.3/HERDR-SETUP.md`(v0.3), `docs/HERDR-SETUP.md`(v0.1·v0.2). 고치지 않는다.
  - 이 문서는 v0.3 판을 바탕으로 v0.4 결정과 구독 현황에 맞게 고친 것이다. 바뀐 곳은 0장·1장·2장·4장·6.1·7장·8장이다.
- 이 버전의 대리 응답 기록: `specs/v0.4/HERDR-DECISIONS.md`
- 소유: 사용자. 수정은 사용자 승인 후 `lead`가 반영한다(루트 `AGENTS.md` "HERDR 문서" 규칙).

> 모든 에이전트는 작업 시작 전에 이 문서를 읽는다. 루트 `AGENTS.md`(Claude는 `CLAUDE.md`의 `@AGENTS.md`)가 이 문서를 가리킨다.
> Phase별 목표, 작업 카드, 완료 기준은 `specs/v0.4/PLAN.md`에, 요구는 `specs/v0.4/SPEC.md`에 있다.

## 0. 근거

- 사용자 결정(2026-11-04)
  - v0.4 범위: P4 UI 셸 Zed 일치, P5 에디터 코어 정리, 탭 편집과 저장, PoC 6단계 탭 기능, AUDIT 3·4 수정, 범위 밖 `Duration` 하드코딩, clippy 기준선 경고 10개
  - Phase 순서: 정리 → 일치 → 기능
  - 진행 방식: herdr 멀티 에이전트
  - reviewer(Codex) 비중: "기능 카드만 Codex". 동작이 바뀌는 카드(탭 편집·저장, AUDIT 3·4, 에디터 코어, 탭 기능)는 `reviewer`가 리뷰하고, 값 맞춤·정리 카드는 `review`(agy)가 리뷰한다.
  - herdr 초기화: "현재 herdr 워크스페이스에서 lead 에이젼트만 남기고 탭패널을 초기화 하고, herdr 환경을 v0.4 용으로 다시 구성해 주세요."
- 구독 현황(사용자 확인, 2026-11-04)
  - 구독: Claude Max, Codex Plus, Gemini Pro(agy) — v0.3과 같다.
  - Codex: 5시간 한도 초기화됨(사용 가능).
  - agy: Gemini 4 Argon만 소진. Claude Sonnet과 Flash는 여유.
  - 동시에 도는 다른 herdr 워크스페이스: 없음(`workbench-gpui` 하나).
- 규칙: 구성은 구독 현황과 토큰 부담으로 정한다(루트 `AGENTS.md`, `specs/v0.3/DECISIONS.md` D-4·D-10).

---

## 1. 에이전트 구성

| 이름(label) | 역할 | 도구 | 모델 | effort | 위치 | ponytail |
|---|---|---|---|---|---|---|
| `lead` | 지휘, 작업 분해, 병합 판단, 대리 응답 | Claude Code | Opus 5.5 | high | workbench-gpui / control | full |
| `spec` | Zed 실측값 스펙 관리. v0.4 새 화면(탭 편집·저장, 탭 기능)의 수치를 구현 전에 먼저 스펙화 | agy | gemini-3.8-flash | - | workbench-gpui / control | off |
| `reviewer` | 기능 카드(동작 변경) 리뷰, Phase당 1회 병합 직전 최종 확인(`@ponytail-review`, 전체 테스트 1회), R-12 결과 판정 | Codex | gpt-6.1-sol | medium (에디터 로직은 high) | workbench-gpui / verify | review 전용 |
| `review` | 값 맞춤·정리 카드 리뷰: diff, 카드 검증 수준만큼 빌드·테스트, 정확성 리뷰, AGENTS 4장 점검 | agy | gemini-3.8-flash-high | - | workbench-gpui / verify | 규칙만(플러그인 없음) |
| `measure` | `tools/measure/` 스크립트, Phase별 R-12 재실행, V3 실측 | Claude Code | Sonnet 5.5 | medium | workbench-gpui / verify | full |
| `impl-ui` | UI 셸 구현(P4, AUDIT 3·4의 패널 쪽, 정리 카드) | agy | Claude Sonnet 5.5 (thinking) | - | wt-ui (`work/ui`) | full |
| `impl-editor` | 에디터 코어 구현(P5, 탭 편집·저장의 버퍼 쪽) — **카드가 있을 때만** | Claude Code | Opus 5.5 | medium (어려운 작업만 high) | wt-editor (`work/editor`) | full |

### 1.1 모델 운용 규칙

- effort는 기본값에서 시작하고 필요할 때만 올린다. `max`는 기본값으로 쓰지 않는다.
- Fable 5.1은 Opus 5.5를 xhigh·max로 올려도 해결되지 않을 때만 쓴다. `lead`가 판단하고, 일시적으로만 쓴다.
- Claude Code의 effort는 모델별로 저장된다. 세션을 시작할 때 `/effort status`로 실제 값을 확인한다.
- **`impl-editor`는 상시 띄우지 않는다.** 에디터 코어 카드(Phase 2의 P5, Phase 3의 탭 편집 버퍼)가 생길 때만 `lead`가 worktree `work/editor`와 함께 띄운다. 카드가 끝나면 닫는다.
- `impl-ui`는 v0.3 끝에 Claude Code로 바꿔 썼다(v0.3 H-29, agy 5시간 한도 소진). v0.4는 agy 한도에 여유가 있어 기본값(agy Claude Sonnet)으로 되돌린다(사용자 2026-11-04).
- 대체 모델(한도 소진 시). 구성 변경이므로 `lead`가 `HERDR-DECISIONS.md`에 기록하고 사용자 승인을 받는다.
  - `impl-ui`의 agy Claude 한도 소진: Claude Code, Sonnet 5.5, effort medium(같은 pane·worktree·이름)
  - `spec`의 agy Gemini 한도 소진: Claude Code, Haiku 5.5, effort medium
  - `review`의 agy Gemini 한도 소진: 카드 리뷰를 `reviewer`(Codex)로 묶어 넘긴다. Claude 계열로는 리뷰하지 않는다(1.2).
  - `reviewer`의 Codex 한도 소진: 기능 카드 리뷰를 `review`(agy gemini-3.8-flash-high)로 넘기고, 최종 확인은 한도 초기화 뒤로 미룬다.
  - Gemini 4 Argon은 상시 역할에 두지 않는다. 한도가 초기화된 뒤 설계 판단의 제2 의견용으로만 쓴다.

### 1.2 리뷰 독립성

- `impl-editor`(Claude Code)와 `impl-ui`(agy Claude Sonnet)는 모두 Claude 계열이다. 서로의 코드를 교차 리뷰해도 독립 검증으로 인정하지 않는다. `measure`(Claude)도 리뷰하지 않는다.
- 병합 전 리뷰는 `reviewer`(Codex) 또는 `review`(Gemini)가 한다. 어느 쪽이 맡는지는 카드 종류로 정한다(0장, 사용자 2026-11-04).
  - 동작이 바뀌는 카드: `reviewer`
  - 값 맞춤·정리 카드(동작 불변 또는 스펙 값으로 맞추기만 하는 것): `review`

### 1.3 토큰 부담

| 구독 | 이 워크스페이스 | 부담 | 조정 |
| --- | --- | --- | --- |
| Claude Max | `lead` Opus high | ◐ | 판단 위주라 출력이 짧다. 코드를 직접 쓰지 않는다. |
| Claude Max | `impl-editor` Opus medium | ◐ | v0.3보다 카드가 많다(P5·탭 편집). 카드가 있을 때만 띄운다(1.1). |
| Claude Max | `measure` Sonnet medium | ◐ | R-12와 V3가 Phase 끝에 몰린다. Claude 한도에 여유가 있다. |
| Codex Plus | `reviewer` Sol medium·high | ● 위험 | 셋 가운데 한도가 가장 작다. 기능 카드 리뷰가 늘어 v0.3보다 부담이 크다. 같은 기능 묶음의 카드는 한 번에 리뷰한다. 5시간 한도는 초기화됨(2026-11-04). |
| agy (Gemini Pro) | `review` Flash high | ◐ | 정리·값 맞춤 카드 리뷰. 여유(사용자 2026-11-04). |
| agy (Gemini Pro) | `spec` Flash | ○ | v0.3에서 스펙 파일을 만들었으므로 v0.4는 새 화면 항목 추가만 한다. |
| agy (Gemini Pro) | `impl-ui` Claude Sonnet thinking | ● | P4·정리 카드의 주 구현자다. 한도가 바닥나면 Claude Code Sonnet 5.5 medium으로 바꾼다(1.1). |
| agy (Gemini Pro) | Argon | 사용 안 함 | 소진(사용자 2026-11-04). |

`reviewer`(Codex Plus) 부담을 아끼는 방법:
- 기능 카드만 맡는다. 정리·값 맞춤 카드는 `review`가 한다.
- 같은 기능 묶음(예: 탭 편집·저장의 카드들)은 한 번에 리뷰한다.
- V3 실측은 `measure`가 한다. 전체 테스트는 병합 직전에 한 번만 돌린다(AGENTS 3A.5).

동시에 도는 다른 워크스페이스:
- 2026-11-04 확인 결과 herdr 워크스페이스는 `workbench-gpui` 하나다.
- 세션을 시작할 때 `herdr workspace list`로 다시 확인한다. 늘었으면 `lead`가 사용자에게 알리고 구성 변경을 검토한다(재승인).

---

## 2. herdr 레이아웃

```text
herdr session
├── workspace: workbench-gpui   (main checkout, D:\projects\workbench-gpui, 브랜치 master)
│   ├── tab: control
│   │   ├── pane: lead          (Claude Code)
│   │   └── pane: spec          (agy)
│   └── tab: verify
│       ├── pane: reviewer      (Codex)
│       ├── pane: review        (agy)
│       └── pane: measure       (Claude Code, cargo build / test / run, tools\verify-*.ps1)
├── workspace: wt-ui            (git worktree .worktrees\ui, branch work/ui) — 상시
│   └── pane: impl-ui           (agy)
└── workspace: wt-editor        (git worktree .worktrees\editor, branch work/editor) — 필요할 때만
    └── pane: impl-editor       (Claude Code)
```

- worktree는 `git worktree add`로 `D:\projects\workbench-gpui\.worktrees\<이름>`에 만들고(`.worktrees/`는 `.gitignore`), herdr 워크스페이스로 연다. 이 데스크톱에서 `herdr worktree create`·`worktree list`가 응답하지 않는다(v0.3 F5 Q-5).
- `.worktrees\ui`는 v0.3 것을 그대로 쓴다. v0.4 시작 때 `work/ui`를 master(`5481e2a`)로 fast-forward했다(2026-11-04).
- worktree를 지워도 브랜치는 지우지 않는다. 병합은 `lead`만 한다. 병합 대상 브랜치는 `master`다.

---

## 3. 초기 설정 (데스크톱)

v0.3 `HERDR-SETUP.md` 3장과 같다. 설치·연동·ponytail·빌드 환경·화면 조건이 바뀌지 않았다. 아래는 v0.4에서 그대로 쓰는 요점이다.

### 3.1 설치·연동·ponytail

- herdr 0.9.5, 연동 claude·codex·antigravity-cli 설치됨(v0.3 3.1·3.2).
- ponytail: Claude Code 플러그인 5.3.2(full), Codex 플러그인(`@ponytail-review`·`@ponytail-audit`), agy는 플러그인 없음 → 루트 `AGENTS.md` 4장 규칙(v0.3 3.3).
- 의도적 단순화 주석은 `shortcut: <한계>, <넘어갈 조건>` 형식이다.

### 3.2 레이아웃 만들기

```powershell
herdr workspace list
herdr pane split --current --direction right --cwd D:\projects\workbench-gpui --no-focus   # control: spec
herdr tab create --label verify                                                            # verify: reviewer
herdr pane split --pane <verify-root> --direction right --cwd D:\projects\workbench-gpui --no-focus  # review
herdr pane split --pane <review-pane> --direction down --cwd D:\projects\workbench-gpui --no-focus   # measure
herdr workspace create --cwd D:\projects\workbench-gpui\.worktrees\ui --label wt-ui --no-focus

# 필요할 때만 (impl-editor 카드가 생길 때)
git worktree add .worktrees\editor -b work/editor master
herdr workspace create --cwd D:\projects\workbench-gpui\.worktrees\editor --label wt-editor --no-focus
```

- pane id는 응답 JSON의 실제 값을 쓴다. 에이전트는 `herdr agent start <label> --kind <kind> --pane <id> -- <옵션>`으로 띄운다.

### 3.3 에이전트 실행 명령

```powershell
# lead
claude --model opus --effort high
# impl-editor (필요할 때만)
claude --model opus --effort medium
# measure
claude --model sonnet --effort medium
# reviewer
codex     # 옵션 없이 띄운다(v0.3 H-3). 세션 안에서 /model → GPT-6.1-Sol → Medium → s(세션 한정)
# spec, review, impl-ui (agy 모델 ID는 effort 접미사가 붙는다, `agy models`)
agy --model gemini-3.8-flash-medium     # spec. 편집 자동 승인 모드(shift+tab, v0.3 F5 Q-4)
agy --model gemini-3.8-flash-high       # review
agy --model claude-sonnet-5-5-medium    # impl-ui. 기본 모드 유지
```

### 3.4 빌드·실측 환경

- Rust 1.99.1, Build Tools 2022, Windows SDK 10.0.26100.0, PowerShell 7, Python은 WinPython 전체 경로(v0.3 3.7, D-5·D-12).
- `CARGO_TARGET_DIR`은 모든 pane에서 `D:\projects\workbench-gpui\target` 하나다. 잠금 파일을 지우지 않는다.
- 빌드할 때마다 `pwsh -NoProfile -File tools/apply-manifest.ps1`을 다시 실행한다.
- `tools\verify-v02-*.ps1`은 항상 `-OutDir specs\v0.4\verify\...`를 넘긴다. worktree에서는 `-Exe`에 절대 경로를 넘긴다.
- 화면: 주 모니터 1920x1080, 100%(DPI 96). Zed 기준(노트북 200%)과는 논리 px로 비교한다(v0.3 3.8). 검증 스크립트가 도는 동안 사용자는 마우스·키보드를 쓰지 않는다.

---

## 4. 공유 파일과 소유권

| 경로 | 소유자 | 내용 |
|---|---|---|
| `specs/v0.4/HERDR-SETUP.md` | 사용자 (반영은 `lead`) | 이 문서 |
| `specs/v0.4/HERDR-DECISIONS.md` | `lead` | 대리 응답·구성 변경 기록 |
| `specs/v0.4/INTENT.md`, `DECISIONS.md`, `SPEC.md` | 사용자 (반영은 `lead`) | 버전 의도·결정·요구 |
| `specs/v0.4/PLAN.md` | 사용자 | Phase 계획. `lead`는 진행 현황 표만 갱신한다. |
| `specs/v0.4/PROGRESS.md` | `lead` | 한 일·결과·검증 기록 |
| `specs/v0.4/agents/TASKS.md`, `HANDOFF.md` | `lead` | 작업 보드, 세션 핸드오프 |
| `spec/zed-metrics.toml`, `spec/INDEX.md`, `spec/ambiguous.md` | `spec` | Zed 실측 스펙, 색인, 모호·충돌 항목 |
| `specs/v0.4/verify/reviews/` | `review`·`reviewer`(카드 리뷰·최종 확인), `measure`(`measure-*.md`) | 리뷰, 실측 비교 결과. 파일 이름으로 나눈다 |
| `specs/v0.4/verify/baseline/` | `measure` | Phase별 R-12 재실행 결과(`phase<n>/`) |
| `tools/measure/` | `measure` | V3 측정 스크립트 |
| 에디터 코어: `src/ui/pane.rs`, 탭 편집용 새 모듈(이름은 카드에서 정함), `src/ui/editor_poc.rs` | `impl-editor` | `DECISIONS.md` D-10(사용자 2026-11-04). `pane.rs`는 v0.3에서 `impl-ui` 소유였다 |
| UI 셸: `src/ui/`의 나머지 파일(공통·에디터 코어 제외), `src/keymap/`, `src/fsops/`, `src/state/`, `src/main.rs` | `impl-ui` | v0.3 P0-5 확정 |
| 공통 모듈(`src/ui/mod.rs`, `src/ui/metrics.rs`, `src/ui/rem.rs`, `src/ui/layout_probe.rs`, `src/ui/theme.rs`, `src/ui/menu_common.rs`), `src/dev.rs`, `Cargo.toml` | `lead`가 카드 단위로 지정 | v0.3 P0-5 확정 |

- 소유자가 아니면 그 파일을 고치지 않는다. 고쳐야 하면 `lead`에게 요청한다.
- 지난 버전 폴더(`specs/v0.1/`~`specs/v0.3/`), `docs/HERDR-*.md`, `docs/refs/`는 아무도 고치지 않는다.

---

## 5. 작업 프로토콜

### 5.1 작업 카드 (`specs/v0.4/agents/TASKS.md`)

```markdown
### <카드 ID> <제목>
- 카드 ID: PLAN.md의 Phase 번호 기준(예: P1-1). rework 카드는 원래 ID에 `-R1`, `-R2`를 붙인다.
- 상태: todo | doing | review | rework | done
- 담당: lead | spec | reviewer | review | measure | impl-ui | impl-editor
- 리뷰: reviewer(동작 변경) | review(값 맞춤·정리)
- 브랜치: master | work/ui | work/editor
- 요구·결정: <SPEC R-n, DECISIONS D-n>
- 스펙 ID: <spec/zed-metrics.toml 항목 ID 목록>
- 범위: <수정 대상 파일·모듈>
- 검증 수준: V0 | V1 | V2 | V3 (AGENTS.md 3A.1)
- 측정 목록: <V3일 때만. 화면 상태와 스펙 ID 목록>
- 완료 조건: 지정된 검증 수준 통과, 리뷰 PASS
- 비고:
```

### 5.2 작업 흐름

1. `lead`가 작업 카드를 쓰고 담당자에게 지시한다(`herdr agent prompt <label> "..." --wait`).
2. 담당자가 구현하고 완료 보고를 남긴다. `lead`는 `herdr agent wait <label>`로 기다린다.
3. `lead`가 카드의 리뷰 칸에 적힌 리뷰어(`reviewer` 또는 `review`)에게 검증을 지시한다. 같은 묶음의 카드는 한 번에 지시한다(1.3).
4. `lead`가 결과를 `herdr agent read <label> --source recent-unwrapped --lines 120`으로 읽는다.
5. 통과하면 `lead`가 `master`에 병합하고 PROGRESS에 기록한다. 실패하면 `rework`로 돌려보낸다.

### 5.3 완료 보고 형식

루트 `AGENTS.md` 8장의 `[DONE]`·`[MEASURED]`·`[BLOCKED]` 형식을 따른다.

---

## 6. 공통 규칙

### 6.1 Zed 실측값

- Zed 실측 수치(크기, 간격, 색상, 동작)는 요구사항이다. ponytail 단순화 대상이 아니다.
- 수치는 `spec/zed-metrics.toml`에서만 가져온다. 코드에 하드코딩하지 않는다.
- 스펙에 없는 수치가 필요하면 `lead`를 통해 `spec`에게 요청한다. 새 화면은 `spec`이 먼저 스펙에 추가한 뒤 구현한다(초안 PLAN P6 운영).
- 코드 값을 스펙 값으로 맞추는 것은 Phase 2(P4·P5) 카드에서만 한다. 허용 오차 안 불일치도 맞춘다(`specs/v0.4/DECISIONS.md` D-3). 그 밖의 카드에서 찾은 불일치는 완료 보고에 적는다.

### 6.2 ponytail

- 구현자는 full 모드로 작업한다. ultra는 쓰지 않는다.
- 비자명한 로직에는 Rust 테스트(`#[test]` 또는 `#[gpui::test]`)를 하나 이상 남긴다.
- 의도적 단순화는 `shortcut:` 주석으로 남기고, Phase 끝마다 `/ponytail-debt`로 점검한다.
- ponytail 리뷰는 버그·보안·성능을 보지 않는다. 그래서 리뷰어가 정확성 리뷰를 따로 한다.

### 6.3 검증 정책

루트 `AGENTS.md` 3A장을 따른다. V3 UI 실측은 `measure`가 한다(v0.3 H-20에서 이어짐).

### 6.4 사람이 처리하는 것

- 하위 에이전트의 승인·권한 프롬프트는 `lead`가 `herdr agent read`로 내용을 보고 판단해 처리하고 `HERDR-DECISIONS.md`에 남긴다(사용자 위임, v0.3 H-4에서 이어짐). 6.5의 위임 밖 항목은 사용자에게 올린다.
- Git Bash에서 `/model` 같은 슬래시 명령을 보낼 때는 `MSYS_NO_PATHCONV=1`과 `herdr pane send-text`를 쓴다(v0.3 H-3).
- herdr가 '대기'로 표시해도 바로 입력을 보내지 않는다. 먼저 `herdr pane read`로 화면을 확인한다.
- agy는 백그라운드 작업이 남아 있어도 '대기'로 표시된다. `impl-ui`·`spec`·`review`의 완료는 완료 보고와 결과물로 판정한다.

### 6.5 대리 응답 범위

- 사용자가 `lead`에게 승인 권한을 위임했다(2026-10-31부터 이어짐). 판단마다 근거를 `specs/v0.4/HERDR-DECISIONS.md`에 남긴다.
- 위임 밖: 사용자에게 올린다.
  - 파일·폴더 삭제(소스 파일 포함)
  - push 등 외부 전송, git 원격 설정
  - `Cargo.toml`·`Cargo.lock` 변경
  - 이 문서와 `PLAN.md`의 계획 변경, 대체 모델로의 구성 변경(1.1)
  - SPEC에 없는 동작 변경
- 같은 에이전트와의 검증 왕복은 최대 2회다.

---

## 7. 최초 지시 프롬프트

처음 띄울 때는 역할만 알리고 대기시킨다(2026-11-04에 이 프롬프트로 띄웠다). 작업 지시는 `lead`가 카드로 한다. 버전 문서는 2026-11-04에 확정되었다.

```text
너는 workbench-gpui v0.4의 <label>이다. 루트 AGENTS.md와 specs/v0.4/HERDR-SETUP.md(1장 역할, 4장 소유권)를 읽어라.
v0.4 버전 문서는 아직 작성 중이다. 읽은 뒤 자기 역할을 한 줄로 확인하고, lead의 작업 카드를 기다려라. 지시 전에는 파일을 고치지 않는다.
```

- `spec`에는 "ponytail 규칙을 적용하지 않는다"를, `impl-ui`에는 "작업 위치는 worktree work/ui다"를 덧붙인다.
- `impl-editor`는 띄울 때 같은 프롬프트에 "작업 위치는 worktree work/editor다"를 덧붙인다.

---

## 8. 단계 계획

Phase별 목표, 작업 카드, 완료 기준은 `specs/v0.4/PLAN.md`를 따른다. 사용자 결정(2026-11-04)의 순서는 정리 → 일치 → 기능이다.

| 순서 | 내용 | 주 담당 | 리뷰 |
|---|---|---|---|
| 정리 | AUDIT 3·4, 범위 밖 `Duration` 하드코딩, clippy 기준선 경고 10개 | impl-ui (에디터 쪽은 impl-editor) | AUDIT 3·4는 reviewer, 나머지는 review |
| 일치 | P4 UI 셸 Zed 일치 ∥ P5 에디터 코어 정리 | impl-ui ∥ impl-editor | 값 맞춤은 review, 에디터 로직은 reviewer |
| 기능 | 탭 편집과 저장, PoC 6단계 탭 기능 | impl-editor, impl-ui | reviewer |

## 9. 정리 방법

- `wt-editor`와 `impl-editor`는 카드가 끝나면 닫는다(브랜치는 남긴다).
- 탭 control·verify와 `wt-ui`는 사용자가 닫으라고 할 때까지 유지한다.
- Phase가 바뀔 때 모든 에이전트(lead 포함)를 새 세션으로 시작한다. 이어받을 상태는 `specs/v0.4/agents/HANDOFF.md` 맨 위 절에 둔다(v0.3 사용자 결정 2026-11-03에서 이어짐).
- 버전이 끝나면 다음 버전의 `specs/{새 버전}/HERDR-SETUP.md`를 새로 쓴다. 이 문서는 고치지 않는다.

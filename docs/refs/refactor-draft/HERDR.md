# HERDR.md - Zed-like Editor 멀티 에이전트 운영 문서

Rust + gpui 기반 Zed-like 에디터를 Zed 실측 결과에 맞춰 구현하기 위한 herdr 멀티 에이전트 구성, 역할, 운영 규칙, 최초 지시 프롬프트를 정의한다.

- 기준일: 2026-11-02
- 현재 상태: 메뉴, 아이콘, 에디터 등 기본 구조 완성. ponytail 미적용 상태에서 리팩토링 시작
- 목표: 중복 없이 기존 코드를 최대한 재사용(ponytail)하면서, Zed 실측 검증을 자동화하여 구현 속도를 높인다

> 모든 에이전트는 작업 시작 전에 이 문서를 읽는다. CLAUDE.md와 AGENTS.md에서 이 문서를 참조한다.
> Phase별 목표, 작업 카드, 완료 기준은 PLAN.md에 정의한다.

---

## 1. 에이전트 구성

| 이름(label) | 역할 | 도구 | 모델 | effort | 워크스페이스 | ponytail |
|---|---|---|---|---|---|---|
| `lead` | 지휘, 작업 분해, 병합 판단 | Claude Code | Opus 5.5 | high | zed-main | full |
| `spec` | Zed 실측값 스펙 관리, 비교 결과 정리 | agy | Gemini 3.8 Flash | - | zed-main | off |
| `reviewer` | 빌드/테스트, 실측 비교, 리뷰 | Codex | GPT-6.1 Sol | medium (에디터 로직은 high) | zed-main | review 전용 |
| `impl-editor` | 에디터 코어 구현 | Claude Code | Opus 5.5 | medium (어려운 작업만 high) | wt-editor | full |
| `impl-ui` | UI 셸 구현 | agy | Claude Sonnet 5.5 (thinking) | - | wt-ui | full |

### 1.1 모델 운용 규칙

- effort는 기본값에서 시작하고 필요할 때만 올린다. `max`는 기본값으로 쓰지 않는다.
- Fable 5.1은 Opus 5.5를 xhigh/max로 올려도 해결되지 않는 경우에만 `lead`가 판단해 일시적으로 사용한다.
- Claude Code에서 effort는 모델별로 저장된다. 세션 시작 시 `/effort status`로 실제 적용값을 확인한다.
- 대체 모델
  - `impl-ui`의 agy Claude 한도 소진 시: Claude Code, Sonnet 5.5, effort medium
  - `spec`의 agy Gemini 한도 소진 시: Claude Code, Haiku 5.5, effort medium
  - Gemini 4 Argon은 상시 역할에 배치하지 않는다. 한도 초기화 후 설계 판단의 제2 의견용으로만 사용한다.

### 1.2 리뷰 독립성

- `impl-editor`와 `impl-ui`는 모두 Claude 계열이므로 서로의 코드를 교차 리뷰해도 독립 검증으로 인정하지 않는다.
- 모든 병합 전 리뷰는 `reviewer`(Codex)가 수행한다.

---

## 2. herdr 레이아웃

```text
herdr session
├── workspace: zed-main        (main checkout)
│   ├── tab: control
│   │   ├── pane: lead         (Claude Code)
│   │   └── pane: spec         (agy)
│   └── tab: verify
│       ├── pane: reviewer     (Codex)
│       └── pane: shell        (cargo build / test / run)
├── workspace: wt-editor       (git worktree, branch work/editor)
│   ├── pane: impl-editor      (Claude Code)
│   └── pane: shell            (cargo run)
└── workspace: wt-ui           (git worktree, branch work/ui)
    ├── pane: impl-ui          (agy)
    └── pane: shell            (cargo run)
```

- worktree는 herdr에서 생성한다. herdr는 worktree를 워크스페이스로 관리하고, worktree 제거 시 브랜치는 삭제하지 않는다.
- 병합은 `lead`만 수행한다.

---

## 3. 초기 설정

### 3.1 herdr 설치 (Windows, PowerShell)

```powershell
powershell -ExecutionPolicy Bypass -c "irm https://herdr.dev/install.ps1 | iex"
```

### 3.2 연동 설치

서버 재시작 후 세션 복원과 상태 감지를 위해 설치한다.

```powershell
herdr integration install claude
herdr integration install codex
herdr integration install antigravity-cli
```

### 3.3 ponytail 설치

Claude Code 세션에서 두 명령을 각각 별도의 프롬프트로 보낸다(node가 PATH에 있어야 함).

```text
/plugin marketplace add DietrichGebert/ponytail
/plugin install ponytail@ponytail
```

- Codex: 저장소 README의 Codex 설치 항목을 따른다. 호출은 `@ponytail-review`, `@ponytail-audit` 형식.
- agy: AGENTS.md에 ponytail 규칙을 넣는다. `spec` 세션은 최초 프롬프트에서 ponytail 비적용을 지시한다.

### 3.4 레이아웃 생성

```powershell
# Main workspace
herdr workspace create --cwd <REPO_ROOT> --label zed-main
herdr tab create --label control
herdr tab create --label verify

# Check pane ids before split/run (ids depend on creation order)
herdr pane layout --current
```

- worktree 워크스페이스(`wt-editor`, `wt-ui`)는 herdr UI의 worktree 메뉴 또는 worktree CLI로 생성한다.
  - CLI 구문은 `herdr worktree --help`로 확인한다. (raw API: `worktree.create`, branch `work/editor`, `work/ui`)
- 각 pane에서 에이전트를 실행한 뒤 역할 이름을 붙인다.

```powershell
# Replace pane ids with the actual ones from `herdr pane layout --current`
herdr agent rename w1:p1 lead
herdr agent rename w1:p2 spec
herdr agent rename w1:p3 reviewer
herdr agent rename w2:p1 impl-editor
herdr agent rename w3:p1 impl-ui
```

### 3.5 에이전트 실행 명령

```powershell
# lead
claude --model opus --effort high

# impl-editor
claude --model opus --effort medium

# reviewer
codex --model gpt-6.1-sol -c model_reasoning_effort='"medium"'

# spec, impl-ui
agy    # select model in session: spec = Gemini 3.8 Flash, impl-ui = Claude Sonnet 5.5 (thinking)
```

### 3.6 Windows 설정 (herdr config)

```toml
[ui]
# Use native cursor if Korean IME candidate window is misplaced
# host_cursor = "native"

[experimental]
# Switch Hangul to ASCII only while prefix commands are active
switch_ascii_input_source_in_prefix = true
```

- 붙여넣기는 Windows Terminal에서 `ctrl+shift+v`.
- Windows에서 herdr 플러그인은 preview이므로 초기에는 CLI만으로 운용한다.

### 3.7 Rust 빌드

- worktree마다 target 디렉터리가 분리되면 gpui를 각각 새로 컴파일한다.
- `CARGO_TARGET_DIR`을 공유 경로로 지정한다. 동시 빌드 시 잠금 대기는 감수한다.

---

## 4. 공유 파일과 소유권

| 경로 | 소유자 | 내용 |
|---|---|---|
| `HERDR.md` | 사용자 | 이 문서 |
| `PLAN.md` | 사용자 | Phase 계획. 진행 현황 표만 `lead`가 갱신 |
| `docs/agents/TASKS.md` | `lead` | 작업 보드 |
| `docs/agents/HANDOFF.md` | `lead` | 세션 핸드오프 |
| `spec/zed-metrics.toml` | `spec` | Zed 실측 스펙(항목 ID 포함) |
| `docs/agents/reviews/` | `reviewer` | 감사, 리뷰, 실측 비교 결과 |
| `tools/measure/` | `reviewer` | V3 측정 스크립트(PLAN.md P1-5) |
| `<EDITOR_CORE_PATHS>` | `impl-editor` | 에디터 코어 소스 |
| `<UI_SHELL_PATHS>` | `impl-ui` | 메뉴, 아이콘, 패널, 타이틀바 등 UI 셸 소스 |

- 소유자 외에는 해당 파일을 수정하지 않는다. 수정이 필요하면 `lead`에게 요청한다.
- 공통 모듈(상수, 테마, 공통 컴포넌트)의 소유자는 `lead`가 작업 단위로 지정한다.
- `<...>` 항목은 실제 경로로 채운다.

---

## 5. 작업 프로토콜

### 5.1 작업 카드 (TASKS.md)

```markdown
### <카드 ID> <제목>
- 카드 ID: PLAN.md의 Phase 번호 기준(예: P0-1, P2-3). rework 카드는 원 카드 ID에 `-R1`, `-R2`를 붙인다.
- 상태: todo | doing | review | rework | done
- 담당: impl-editor | impl-ui | spec | reviewer
- 브랜치: work/editor | work/ui
- 스펙 ID: <spec/zed-metrics.toml 항목 ID 목록>
- 범위: <수정 대상 파일/모듈>
- 검증 수준: V0 | V1 | V2 | V3 (AGENTS.md 3A.1)
- 측정 목록: <V3인 경우에만. 화면 상태와 스펙 ID 목록>
- 완료 조건: 지정된 검증 수준 통과, ponytail-review 확인
- 비고:
```

### 5.2 작업 흐름

1. `lead`가 작업 카드를 작성하고 담당자에게 지시한다. (`herdr agent prompt`, `--wait` 사용. 구문은 `herdr agent prompt --help`로 확인)
2. 담당자가 구현 후 완료 보고를 남긴다.
3. `lead`가 완료를 기다린다.

```powershell
herdr agent wait impl-ui --until done
```

4. `lead`가 `reviewer`에게 해당 브랜치 검증을 지시한다.
5. `lead`가 결과를 읽는다.

```powershell
herdr pane read <reviewer-pane-id> --source recent --lines 120
```

6. 통과 시 `lead`가 병합하고, 실패 시 `rework` 상태로 담당자에게 돌려보낸다.

### 5.3 완료 보고 형식

```text
[DONE] <카드 ID>
- 변경: <파일 목록>
- 재사용: <재사용한 기존 코드/컴포넌트>
- 생략: <ponytail로 생략한 것과 추가 조건>
- 검증 수준: V0 | V1 | V2 | V3
- 확인: <실행한 명령과 결과, 또는 "코드 확인">
- 실측 필요: <실제 화면 측정이 필요한 스펙 ID와 화면 상태, 없으면 "없음">
- 사용자 확인 필요: <측정으로 판단할 수 없는 시각 품질 항목, 없으면 "없음">
```

V3 실측 결과는 AGENTS.md 8장의 `[MEASURED]` 형식으로 보고한다.

---

## 6. 공통 규칙

### 6.1 Zed 실측값

- Zed 실측 수치(크기, 간격, 색상, 동작)는 요구사항이다. ponytail 단순화 대상이 아니다.
- 수치는 `spec/zed-metrics.toml`에서만 가져온다. 코드에 하드코딩하지 않는다.
- 스펙에 없는 수치가 필요하면 `spec`에게 요청한다.

### 6.2 ponytail

- 구현자는 full 모드로 작업한다. ultra는 사용하지 않는다.
- 리팩토링 중에는 동작을 변경하지 않는다.
- 비자명한 로직에는 Rust 테스트(`#[test]` 또는 `#[gpui::test]`)를 하나 이상 남긴다.
- 의도적 단순화는 `ponytail:` 주석으로 남긴다. 마일스톤마다 `/ponytail-debt`로 점검한다.
- ponytail 리뷰는 버그, 보안, 성능을 보지 않으므로 `reviewer`는 정확성 리뷰를 별도로 수행한다.

### 6.3 검증 정책

상세 규칙은 AGENTS.md 3A장을 따른다. 모든 에이전트에 동일하게 적용한다.

| 수준 | 언제 | 누가 |
|---|---|---|
| V0 정적 | 동작이 바뀌지 않는 변경(기본값) | 담당자 |
| V1 단위 | 로직이 바뀌는 변경 | 담당자 |
| V2 레이아웃 | 크기나 배치가 바뀌는 변경 | 담당자 |
| V3 UI 실측 | 새 화면/컴포넌트 첫 구현, 공통 값 변경, 테스트로 못 잡는 항목, 사용자 차이 보고, Phase 종료 | `reviewer` |
| V4 사용자 확인 | 측정으로 판단할 수 없는 시각 품질 | 사용자 |

- 작업 단위로는 앱을 띄워 기능을 하나씩 눌러보지 않는다. 코드상 결과가 명확하면 "코드 확인"으로 완료한다.
- 상호작용 동작은 `#[gpui::test]` 입력 시뮬레이션 테스트로 검증한다.
- 실제 화면 측정이 필요한 항목은 "실측 필요"로 보고하고, `lead`가 모아 화면 단위 V3 작업으로 한 번에 수행한다.
- V3는 측정 목록을 먼저 정하고, 앱 1회 실행, 최소 조작, 도구 기반 픽셀 측정, 결과 표 기록 순서로 진행한다. 불일치는 측정자가 고치지 않고 rework로 넘긴다.
- V3에서 반복 측정되는 항목은 레이아웃 테스트(V2)로 옮겨 실측을 점차 줄인다.
- 작업 중에는 관련 테스트만 실행하고, 전체 테스트는 병합 직전 `reviewer`가 1회만 실행한다.

### 6.4 사람이 처리하는 것

- 승인과 권한 프롬프트는 사용자가 직접 처리한다.
- herdr의 '막힘' 판정은 엄격하여 처음 보는 프롬프트가 '대기'로 표시될 수 있다. `lead`는 대기 상태라는 이유만으로 입력을 보내지 않고, 먼저 `herdr pane read`로 화면을 확인한다.
- agy는 백그라운드 작업이 남아 있어도 프롬프트로 돌아오면 '대기'로 표시된다. `impl-ui`와 `spec`의 완료 판정은 완료 보고와 결과물로 확인한다.

---

## 7. 최초 지시 프롬프트

각 에이전트 실행 직후 아래 프롬프트를 보낸다. 순서: `reviewer`, `spec`, `impl-editor`, `impl-ui`, `lead`.

### 7.1 lead

```text
너는 이 프로젝트의 lead다. HERDR.md, PLAN.md, CLAUDE.md를 먼저 읽어라.

역할:
- PLAN.md의 Phase 순서에 따라 작업을 분해하고 docs/agents/TASKS.md와 docs/agents/HANDOFF.md를 관리한다.
- PLAN.md는 진행 현황 표만 갱신한다. 계획 변경은 사용자 승인 후 반영한다.
- 코드는 직접 작성하지 않는다. 병합 판단과 병합만 수행한다.
- herdr CLI로 다른 에이전트(spec, reviewer, impl-editor, impl-ui)에게 지시하고 완료를 기다린다.

첫 작업 (P0 기준선):
1. PLAN.md P0 절의 카드(P0-1 ~ P0-6)를 docs/agents/TASKS.md에 작성해라. 카드마다 검증 수준을 지정하고 기본값은 V0로 한다(HERDR.md 6.3).
2. P0-5로 저장소 구조를 파악하고 HERDR.md 4장의 <EDITOR_CORE_PATHS>, <UI_SHELL_PATHS> 후보를 제안해라. 확정은 사용자에게 받는다.
3. 카드 목록을 사용자에게 보고하고 승인 후 P0-1 ~ P0-4 지시를 시작해라. P0-6(V3 기준 실측)은 P0-3 스펙 파일이 나온 뒤 지시한다.
4. P0가 끝나면 PLAN.md 2.3 Phase 종료 절차를 수행하고, P1 카드 초안을 만들어 사용자에게 보고해라.

P0 동안 src는 아무도 수정하지 않는다.
```

### 7.2 spec

```text
너는 spec 담당이다. HERDR.md를 먼저 읽어라.
이 세션에서는 ponytail 규칙을 적용하지 않는다. 측정 데이터는 줄이거나 단순화하지 않는다.

역할:
- Zed 실측 결과를 spec/zed-metrics.toml로 관리한다. 너는 이 파일과 docs/agents/reviews/의 비교 결과 정리만 수정한다.
- src는 읽기만 하고 수정하지 않는다.

첫 작업 (P0-3, PLAN.md 참고):
1. Zed 실측 결과(<ZED_MEASURE_DIR>)를 읽어라.
2. spec/zed-metrics.toml을 만들어라.
   - 항목마다 고유 ID(예: menu.item.height), 값, 단위, 측정 출처, 측정 조건(DPI, 테마, 폰트)을 기록한다.
   - 화면 영역별(titlebar, menu, tab, panel, editor, statusbar 등)로 섹션을 나눈다.
3. 값이 모호하거나 측정 조건이 빠진 항목은 목록으로 따로 보고해라. 추정값을 채워 넣지 않는다.
완료 시 HERDR.md 5.3 형식으로 보고해라.
```

### 7.3 reviewer

```text
너는 reviewer다. HERDR.md, PLAN.md, AGENTS.md를 먼저 읽어라.

역할:
- 빌드, 테스트, clippy, Zed 실측 비교, @ponytail-review를 수행한다.
- ponytail 리뷰는 버그와 보안을 보지 않으므로 정확성 리뷰도 함께 한다.
- 결과는 docs/agents/reviews/에만 기록한다. src는 수정하지 않는다.

첫 작업 (P0-1, P0-2):
1. P0-1: main에서 cargo build, cargo test, cargo clippy를 실행하고 결과를 docs/agents/reviews/baseline-2026-11-02.md에 기록해라.
   clippy 경고가 많으면 -D warnings 없이 기록한다(PLAN.md P0 주의 사항).
2. P0-2: @ponytail-audit를 저장소 전체에 실행하고 결과를 docs/agents/reviews/audit-2026-11-02.md에 저장해라. 파일은 수정하지 않는다.
3. 감사 결과를 다음으로 분류해라: 하드코딩 수치/색상, 반복 스타일 체인, 중복 컴포넌트, 미사용 의존성, 기타. 이 분류는 P2, P3의 작업 범위가 된다.
완료 시 HERDR.md 5.3 형식으로 보고해라.
P0-6(V3 기준 실측)은 lead의 지시를 받은 뒤 수행한다.

이후 리뷰 요청마다 다음을 수행한다:
- 대상 브랜치 diff 확인
- 작업 카드의 검증 수준(V0, V1, V2)만큼만 빌드/테스트 실행. V2일 때만 해당 스펙 ID 레이아웃 테스트 실행
- @ponytail-review, 코드 읽기 기반 정확성 리뷰
- 일반 리뷰에서는 앱을 띄워 확인하지 않는다. 전체 테스트는 병합 직전 1회만 실행한다.
- 결론은 PASS 또는 REWORK와 사유 목록으로 낸다.

V3 실측 작업 카드를 받으면 AGENTS.md 3A.4 절차를 따른다:
- 카드의 측정 목록에 있는 화면 상태와 스펙 ID만 측정한다.
- 스펙의 측정 조건(창 크기, DPI 배율, 테마, 폰트)을 맞추고 앱은 1회만 실행한다.
- 스크린샷과 도구로 픽셀 값을 측정하고 docs/agents/reviews/measure-<id>.md에 표로 기록한다.
- [MEASURED] 형식으로 보고한다. src는 고치지 않는다.
- 화면 캡처나 조작이 불가능한 환경이면 [BLOCKED]로 보고한다.
```

### 7.4 impl-editor

```text
너는 impl-editor다. HERDR.md, PLAN.md, CLAUDE.md를 먼저 읽어라.
작업 위치는 worktree work/editor다. 담당 범위는 에디터 코어(<EDITOR_CORE_PATHS>)다.

규칙:
- ponytail full 모드. 기존 코드, 공통 컴포넌트, gpui/gpuikit 기능을 먼저 재사용한다.
- Zed 수치는 spec/zed-metrics.toml의 항목 ID로만 사용한다.
- 담당 범위 밖 파일은 수정하지 않는다. 필요하면 lead에게 요청한다.
- 리팩토링 작업에서는 동작을 변경하지 않는다.
- 검증은 작업 카드의 검증 수준까지만 한다(AGENTS.md 3A장). 앱을 띄워 마우스로 하나씩 확인하지 않는다.
  코드상 결과가 명확하면 "코드 확인"으로 완료하고, 화면 측정이 필요한 항목은 "실측 필요", 시각 품질은 "사용자 확인 필요"로 넘긴다.

첫 작업 (P0-4, PLAN.md 참고):
1. worktree와 브랜치를 확인하고 cargo build를 실행해라.
2. 담당 범위의 모듈 구조를 요약해라(파일, 주요 타입, 의존 관계).
3. 코드는 수정하지 말고 보고 후 lead의 작업 지시를 기다려라.
```

### 7.5 impl-ui

```text
너는 impl-ui다. HERDR.md, PLAN.md, AGENTS.md를 먼저 읽어라.
작업 위치는 worktree work/ui다. 담당 범위는 UI 셸(<UI_SHELL_PATHS>: 메뉴, 아이콘, 패널, 타이틀바 등)이다.

규칙:
- ponytail full 모드. 기존 코드, 공통 컴포넌트, gpui/gpuikit 기능을 먼저 재사용한다.
- gpuikit 컴포넌트가 있으면 먼저 검토하되, 크기가 Zed 실측과 다르면 자체 구현을 유지한다.
- Zed 수치는 spec/zed-metrics.toml의 항목 ID로만 사용한다.
- 담당 범위 밖 파일은 수정하지 않는다. 필요하면 lead에게 요청한다.
- 리팩토링 작업에서는 동작을 변경하지 않는다.
- 검증은 작업 카드의 검증 수준까지만 한다(AGENTS.md 3A장). 앱을 띄워 마우스로 하나씩 확인하지 않는다.
  코드상 결과가 명확하면 "코드 확인"으로 완료하고, 화면 측정이 필요한 항목은 "실측 필요", 시각 품질은 "사용자 확인 필요"로 넘긴다.

첫 작업 (P0-4, PLAN.md 참고):
1. worktree와 브랜치를 확인하고 cargo build를 실행해라.
2. 담당 범위의 모듈 구조와, 반복되는 스타일 체인이나 유사 컴포넌트를 요약해라.
3. 코드는 수정하지 말고 보고 후 lead의 작업 지시를 기다려라.
작업이 끝나면 반드시 HERDR.md 5.3 형식의 완료 보고를 남겨라.
```

---

## 8. 단계 계획

Phase별 목표, 작업 카드, 완료 기준, 시작/종료 절차는 PLAN.md를 따른다. 이 문서에는 요약만 둔다.

| Phase | 목표 | 담당 |
|---|---|---|
| P0 기준선 | 현재 상태 고정, 기준 실측 | reviewer, spec |
| P1 검증 기반 | 레이아웃 테스트 틀, 레이아웃 덤프, 측정 스크립트 | reviewer, impl-editor |
| P2 상수/테마 통합 | 하드코딩 제거 | impl-ui, impl-editor |
| P3 공통 컴포넌트 | 중복 제거 | impl-ui |
| P4 UI 셸 정리 | 메뉴, 아이콘, 패널, 타이틀바, 상태바 Zed 일치 | impl-ui |
| P5 에디터 코어 정리 | 버퍼, 커서, 선택, 텍스트 레이아웃, IME, 스크롤 Zed 일치 | impl-editor |
| P6 신규 기능 | 작업 카드 단위 기능 확장 | 전체 |

- P4와 P5는 P3 완료 후 병렬로 진행할 수 있다.
- 진행 현황은 PLAN.md 4장 표에서 관리한다.

# HERDR-SETUP — workbench-gpui v0.3 멀티 에이전트 운영

- 상태: 확정 (2026-11-03)
- 기준 문서: `docs/refs/refactor-draft/HERDR.md`(claude.ai, 사용자 검토), `docs/refs/refactor-draft/HERDR-SETUP.md`(v0.3 변경안)
  - 두 문서를 데스크톱·이 워크스페이스·토큰 부담에 맞게 고쳐 하나로 합쳤다. 원문은 고치지 않고 보존한다.
- 지난 버전 구성: `docs/HERDR-SETUP.md`, `docs/HERDR-DECISIONS.md`(v0.1·v0.2 기록, 고치지 않음)
- 이 버전의 대리 응답 기록: `specs/v0.3/HERDR-DECISIONS.md`
- 소유: 사용자. 수정은 사용자 승인 후 `lead`가 반영한다(루트 `AGENTS.md` "HERDR 문서" 규칙).

> 모든 에이전트는 작업 시작 전에 이 문서를 읽는다. 루트 `AGENTS.md`(Claude는 `CLAUDE.md`의 `@AGENTS.md`)가 이 문서를 가리킨다.
> Phase별 목표, 작업 카드, 완료 기준은 `specs/v0.3/PLAN.md`에, 요구는 `specs/v0.3/SPEC.md`에 있다.

## 0. 근거

- 사용자 지시(2026-11-03)
  - "제일 먼저 github.com/nampluskr/workbench-gpui 에 대한 poytail 기반 리팩토링을 해야 합니다."
  - "refactor-draft 의 문서의 내용이 현재 데스크탑 및 워크스페이스 에 맞게 모두 반영되어야 합니다. … 참고가 아니라 이 문서를 기준으로 v0.3 이 이루어져야 합니다. 1. 데이크탑 환경 적용 2. 멀티에이젼트시 토큰 부담 고려 3. 자료나 파일등 경로 맞게 수정 반영"
  - "HERDR-XXX.md 파일은 sepcs\{version} 에 따로 따로 보관하는 것이 좋을 것 같습니다."
  - "파이썬은 c:\winpython\ 에 _cpu, _gpu 환경을 사용하면 됩니다."
- 사용자 선택(2026-11-03)
  - 에이전트 구성: "HERDR.md + 부담 조정"
  - 측정 도구: "PowerShell 재사용"
  - P4~P6: "v0.4 이후 유지"
- 구독 현황(사용자 확인, 2026-11-03)
  - 구독: Claude Max, Codex Plus, Gemini Pro(agy)
  - agy Gemini 4 Argon은 주간 한도를 다 쓴 상태다.
  - agy의 Claude Sonnet과 Flash 한도는 "둘 다 충분"하다.
- 사용자 선택(2026-11-03): v0.2 검증 스크립트 기준선(P0-0c)은 "reviewer 전부"가 한다.
- 규칙: 구성은 구독 현황과 토큰 부담으로 정한다(루트 `AGENTS.md`, `specs/v0.3/DECISIONS.md` D-4·D-10).

---

## 1. 에이전트 구성

| 이름(label) | 역할 | 도구 | 모델 | effort | 위치 | ponytail |
|---|---|---|---|---|---|---|
| `lead` | 지휘, 작업 분해, 병합 판단, 대리 응답 | Claude Code | Opus 5.5 | high | workbench-gpui / control | full |
| `spec` | Zed 실측값 스펙 관리, 비교 결과 정리 | agy | gemini-3.8-flash | - | workbench-gpui / control | off |
| `reviewer` | 빌드·테스트, 감사, 리뷰, V3 실측 | Codex | gpt-6.1-sol | medium (에디터 로직은 high) | workbench-gpui / verify | review 전용 |
| `impl-ui` | UI 셸 구현 (P2·P3 주 구현자) | agy | Claude Sonnet 5.5 (thinking) | - | wt-ui (`work/ui`) | full |
| `impl-editor` | 에디터 코어 구현 — **필요할 때만** | Claude Code | Opus 5.5 | medium (어려운 작업만 high) | wt-editor (`work/editor`) | full |

### 1.1 모델 운용 규칙

- effort는 기본값에서 시작하고 필요할 때만 올린다. `max`는 기본값으로 쓰지 않는다.
- Fable 5.1은 Opus 5.5를 xhigh·max로 올려도 해결되지 않을 때만 쓴다. `lead`가 판단하고, 일시적으로만 쓴다.
- Claude Code의 effort는 모델별로 저장된다. 세션을 시작할 때 `/effort status`로 실제 값을 확인한다.
- **`impl-editor`는 상시 띄우지 않는다.**
  - v0.3 범위(P0~P3)에서 에디터 코어는 `src/ui/editor_poc.rs` 하나다(P0-5에서 확정).
  - 에디터 코어 카드가 생길 때만 `lead`가 worktree `work/editor`와 함께 띄운다. 카드가 끝나면 닫는다.
- 대체 모델(한도 소진 시). 구성 변경이므로 `lead`가 `HERDR-DECISIONS.md`에 기록하고 사용자 승인을 받는다.
  - `impl-ui`의 agy Claude 한도 소진: Claude Code, Sonnet 5.5, effort medium
  - `spec`의 agy Gemini 한도 소진: Claude Code, Haiku 5.5, effort medium
  - `reviewer`의 Codex 한도 소진: agy gemini-3.8-flash. Claude 계열로는 리뷰하지 않는다(1.2).
  - Gemini 4 Argon은 상시 역할에 두지 않는다. 한도가 초기화된 뒤 설계 판단의 제2 의견용으로만 쓴다.

### 1.2 리뷰 독립성

- `impl-editor`(Claude Code)와 `impl-ui`(agy Claude Sonnet)는 모두 Claude 계열이다. 서로의 코드를 교차 리뷰해도 독립 검증으로 인정하지 않는다.
- 모든 병합 전 리뷰는 `reviewer`(Codex)가 한다.

### 1.3 토큰 부담

| 구독 | 이 워크스페이스 | 부담 | 조정 |
| --- | --- | --- | --- |
| Claude Max | `lead` Opus high | ◐ | 판단 위주라 출력이 짧다. 코드를 직접 쓰지 않는다. |
| Claude Max | `impl-editor` Opus medium | ○ | 필요할 때만 띄운다(1.1). |
| Codex Plus | `reviewer` Sol medium·high | ● 위험 | 셋 가운데 한도가 가장 작다. 아래처럼 아낀다. |
| agy (Gemini Pro) | `spec` Flash | ◐ | P0-3(F1)의 원문 약 700KB 변환에 몰린다. 문서를 하나씩 순차로 처리하고 문서마다 저장한다. |
| agy (Gemini Pro) | `impl-ui` Claude Sonnet thinking | ● | P2·P3의 주 구현자다. 한도가 바닥나면 Claude Code Sonnet 5.5 medium으로 바꾼다(1.1). |
| agy (Gemini Pro) | Argon | 사용 안 함 | 소진 상태다. |

`reviewer`(Codex Plus) 부담을 아끼는 방법:
- 카드를 묶어 리뷰한다. 같은 화면 영역의 카드는 한 번에 리뷰한다.
- V3 실측은 Phase 끝에, 화면 단위로 묶어서만 한다(AGENTS 3A.3).
- 전체 테스트는 병합 직전에 한 번만 돌린다(AGENTS 3A.5).
- P0-2 감사는 한 번에 몰리는 부담이다. 다른 큰 작업과 겹치지 않게 Phase 0 앞쪽에 둔다.

동시에 도는 다른 워크스페이스:
- 2026-11-03 확인 결과 herdr 워크스페이스는 `workbench-gpui` 하나다.
- 세션을 시작할 때 `herdr workspace list`로 다시 확인한다. 늘었으면 `lead`가 사용자에게 알린다.
- 그때는 `impl-ui`를 Claude Code Sonnet으로 바꿀지 검토한다. 구성 변경이므로 재승인을 받는다.

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
│       └── pane: shell         (cargo build / test / run, tools\verify-*.ps1)
├── workspace: wt-ui            (git worktree, branch work/ui) — 상시
│   ├── pane: impl-ui           (agy)
│   └── pane: shell             (cargo build / run)
└── workspace: wt-editor        (git worktree, branch work/editor) — 필요할 때만
    ├── pane: impl-editor       (Claude Code)
    └── pane: shell             (cargo build / run)
```

- worktree는 `git worktree add`로 `D:\projects\workbench-gpui\.worktrees\<이름>`에 만들고(`.worktrees/`는 `.gitignore`), herdr 워크스페이스로 연다. 이 데스크톱에서 `herdr worktree create`·`worktree list`가 응답하지 않는다(F5 Q-5, 2026-11-03). worktree를 지워도 브랜치는 지우지 않는다.
- 병합은 `lead`만 한다. 병합 대상 브랜치는 `master`다.
- `workbench-gpui` 워크스페이스(wD)는 이미 있다. 탭과 패널만 더한다.

---

## 3. 초기 설정 (데스크톱, 2026-11-03 기준)

### 3.1 herdr

- 설치되어 있다: herdr 0.9.5(`C:\Users\nampl\.herdr\...`).
- 새로 설치할 때 쓰는 명령(참고용):

```powershell
powershell -ExecutionPolicy Bypass -c "irm https://herdr.dev/install.ps1 | iex"
```

### 3.2 연동

- 설치되어 있다(`herdr integration status`): claude current(v11), codex current(v10), antigravity-cli current(v4).
- 다시 설치할 때:

```powershell
herdr integration install claude
herdr integration install codex
herdr integration install antigravity-cli
```

### 3.3 ponytail

| 도구 | 현황 (2026-11-03) | 할 일 |
| --- | --- | --- |
| Claude Code | 플러그인 `ponytail@ponytail` 5.3.2 설치, 훅 켜짐 | 없음. 모드는 full |
| Codex | `~/.codex/config.toml`에 플러그인과 훅 3개 등록 | 없음. 호출은 `@ponytail-review`, `@ponytail-audit` |
| agy | 플러그인 없음 | 루트 `AGENTS.md` 4장의 ponytail 규칙을 따른다. `spec` 세션은 최초 프롬프트에서 ponytail 비적용을 지시한다. |

- Claude Code에 새로 설치할 때는 두 명령을 별도 프롬프트로 보낸다(node가 PATH에 있어야 한다): `/plugin marketplace add DietrichGebert/ponytail`, `/plugin install ponytail@ponytail`.
- 의도적 단순화 주석은 `shortcut: <한계>, <넘어갈 조건>` 형식이다(ponytail 5.3.2). `/ponytail-debt`는 예전 `ponytail:` 주석도 함께 읽는다.

### 3.4 레이아웃 만들기

```powershell
# 메인 워크스페이스는 이미 있다 (label: workbench-gpui)
herdr workspace list
herdr tab create --label control
herdr tab create --label verify

# pane id 확인 (생성 순서에 따라 달라진다)
herdr pane layout --current

# worktree 워크스페이스 (herdr worktree create 대신, F5 Q-5)
git worktree add .worktrees\ui -b work/ui master          # wt-ui (상시)
git worktree add .worktrees\editor -b work/editor master  # wt-editor (impl-editor 카드가 생길 때만)
herdr workspace create --cwd D:\projects\workbench-gpui\.worktrees\ui --label wt-ui --no-focus
```

- 각 pane에서 에이전트를 실행한 뒤 역할 이름을 붙인다. pane id는 `herdr pane layout --current`의 실제 값으로 바꾼다.

```powershell
herdr agent rename <control-lead-pane> lead
herdr agent rename <control-spec-pane> spec
herdr agent rename <verify-reviewer-pane> reviewer
herdr agent rename <wt-ui-pane> impl-ui
# 필요할 때만
herdr agent rename <wt-editor-pane> impl-editor
```

### 3.5 에이전트 실행 명령

```powershell
# lead
claude --model opus --effort high

# impl-editor (필요할 때만)
claude --model opus --effort medium

# reviewer
codex     # 옵션 없이 띄운다. -c·--profile은 공유 서버를 끄고 단독(embedded) 모드로 돈다(H-3).
          # 세션 안에서 /model → GPT-6.1-Sol → Medium → s(세션 한정). ~/.codex/config.toml 기본값은 바꾸지 않는다.

# spec, impl-ui
agy --model gemini-3.8-flash-medium     # spec. 세션 안에서 shift+tab으로 편집 자동 승인 모드를 쓴다(F5 Q-4)
agy --model claude-sonnet-5-5-medium    # impl-ui. 기본 모드 유지(F5 Q-4)
# agy 모델 ID는 effort 접미사가 붙는다(`agy models`, H-1).
```

### 3.6 Windows 설정 (herdr config)

```toml
[ui]
# 한글 IME 후보 창 위치가 어긋나면 native 커서를 쓴다
# host_cursor = "native"

[experimental]
# prefix 명령 중에만 한글을 ASCII로 바꾼다
switch_ascii_input_source_in_prefix = true
```

- 붙여넣기는 Windows Terminal에서 `ctrl+shift+v`다.
- Windows에서 herdr 플러그인은 preview라서 처음에는 CLI만으로 운용한다.

### 3.7 빌드 환경 (노트북과 같은 버전, D-5)

| 항목 | 값 | 데스크톱 현황 (2026-11-03) |
| --- | --- | --- |
| Rust | 1.99.1 (rustup 기본 툴체인, clippy 포함) | 설치(P0-0a). rustup 1.29.2, clippy 0.1.99. 설치 전에 만든 pane은 PATH 앞에 `%USERPROFILE%\.cargo\bin`을 붙인다. |
| MSVC | Visual Studio Build Tools 2022 최신 버전 (C++ 빌드 도구) | 설치(P0-0a). 17.14.37827.9, MSVC 14.44.35207. Build Tools 2026은 삭제했다. |
| Windows SDK | 10.0.26100.0 | 26100만 있다. 22621·28000은 2026 삭제 때 함께 없어졌다. 빌드는 26100으로 된다(P0-0b). |
| PowerShell | 7 | 7.6.9 |
| Python (필요할 때만) | `C:\winpython\WPy64-31180_cpu\python-3.11.8.amd64\python.exe` (GPU 작업은 `C:\winpython\WPy64-31180_gpu\python-3.11.8.amd64\python.exe`) | 3.11.8. 시스템 PATH의 `python`은 WindowsApps 스텁이므로 항상 전체 경로로 부른다(D-12). |

- `CARGO_TARGET_DIR`은 모든 pane에서 `D:\projects\workbench-gpui\target` 하나로 둔다. worktree마다 gpui를 새로 컴파일하지 않기 위해서다. 동시 빌드의 잠금 대기는 감수하고, 잠금 파일을 지우지 않는다.
- worktree에서 `tools\verify-*.ps1`을 돌릴 때는 `-Exe D:\projects\workbench-gpui\target\debug\workbench-gpui.exe`처럼 절대 경로를 넘긴다(스크립트 기본값이 상대 경로 `target\debug\...`다).
- 빌드할 때마다 `pwsh -NoProfile -File tools/apply-manifest.ps1`을 다시 실행한다(v0.1 "버전 종료" 남은 것 5).
- `tools\verify-v02-*.ps1`의 기본 `-OutDir`는 `specs\v0.2\verify\...`다. 항상 `specs\v0.3\verify\...` 아래 경로를 넘긴다. 지난 버전 폴더에는 쓰지 않는다.

### 3.8 화면·실측 조건 (데스크톱)

- 모니터: 1920x1080 두 개, 배율 100%(DPI 96). 앱과 측정은 주 모니터(`\\.\DISPLAY1`)에서 한다.
- Zed 기준 화면(`docs/refs/assets/zed-reference*.png`)과 v0.1·v0.2 측정값은 노트북(2880x1704 하나, 200%, DPI 192)에서 만든 것이다. 수치는 논리 px로 비교한다(01-zed 01-LAYOUT 2절 단위 체계).
- LongPathsEnabled는 0이다(D-5). 긴 경로 항목은 v0.1·v0.2와 같은 조건이다.
- 검증 스크립트는 실제 키·마우스 입력을 보낸다. 다음 경우에는 입력을 보내지 못하고 멈춘다(v0.2 "버전 종료" 환경 사실).
  - 화면이 잠겨 있을 때
  - 관리자 권한 창이 맨 앞에 있을 때(UIPI)
  - 같은 앱이 이미 실행 중일 때
- 도는 동안 사용자는 마우스와 키보드를 쓰지 않는다.

---

## 4. 공유 파일과 소유권

| 경로 | 소유자 | 내용 |
|---|---|---|
| `specs/v0.3/HERDR-SETUP.md` | 사용자 (반영은 `lead`) | 이 문서 |
| `specs/v0.3/HERDR-DECISIONS.md` | `lead` | 대리 응답·구성 변경 기록 |
| `specs/v0.3/INTENT.md`, `DECISIONS.md`, `SPEC.md` | 사용자 (반영은 `lead`) | 버전 의도·결정·요구 |
| `specs/v0.3/PLAN.md` | 사용자 | Phase 계획. `lead`는 진행 현황 표만 갱신한다. |
| `specs/v0.3/PROGRESS.md` | `lead` | 한 일·결과·검증 기록(루트 `AGENTS.md` "PROGRESS 기록") |
| `specs/v0.3/agents/TASKS.md` | `lead` | 작업 보드(작업 카드) |
| `specs/v0.3/agents/HANDOFF.md` | `lead` | 세션 핸드오프 |
| `spec/zed-metrics.toml`, `spec/INDEX.md`, `spec/ambiguous.md` | `spec` | Zed 실측 스펙, 색인, 모호·충돌 항목 |
| `specs/v0.3/verify/reviews/` | `reviewer` | 기준선, 감사, 리뷰, 실측 비교 결과 |
| `specs/v0.3/verify/finalize/` | `lead` | 의도·결정 검토, 플랜 대조 (FINALIZE F2) |
| `specs/v0.3/verify/baseline/` | `reviewer` | v0.2 검증 스크립트 기준선 |
| `tools/measure/` | `reviewer` | V3 측정 스크립트(PowerShell, `tools/capture.ps1` 재사용) |
| 에디터 코어: `src/ui/editor_poc.rs` | `impl-editor` | P0-5 사용자 확정 (2026-11-03) |
| UI 셸: `src/ui/` 의 나머지 파일(공통 제외), `src/keymap/`, `src/fsops/`, `src/state/`, `src/main.rs` | `impl-ui` | P0-5 사용자 확정 (2026-11-03) |
| 공통 모듈(`src/ui/mod.rs`, `src/ui/metrics.rs`, `src/ui/rem.rs`, `src/ui/layout_probe.rs`, 테마, 공통 컴포넌트), `src/dev.rs`, `Cargo.toml` | `lead`가 카드 단위로 지정 | P0-5 사용자 확정 (2026-11-03) |

- 소유자가 아니면 그 파일을 고치지 않는다. 고쳐야 하면 `lead`에게 요청한다.
- 지난 버전 폴더(`specs/v0.1/`, `specs/v0.2/`), `docs/HERDR-*.md`, `docs/refs/`는 아무도 고치지 않는다.

---

## 5. 작업 프로토콜

### 5.1 작업 카드 (`specs/v0.3/agents/TASKS.md`)

```markdown
### <카드 ID> <제목>
- 카드 ID: PLAN.md의 Phase 번호 기준(예: P0-1, P2-3, F1-1). rework 카드는 원래 카드 ID에 `-R1`, `-R2`를 붙인다.
- 상태: todo | doing | review | rework | done
- 담당: lead | spec | reviewer | impl-ui | impl-editor
- 브랜치: master | work/ui | work/editor
- 요구·결정: <SPEC R-n, DECISIONS D-n>
- 스펙 ID: <spec/zed-metrics.toml 항목 ID 목록>
- 범위: <수정 대상 파일·모듈>
- 검증 수준: V0 | V1 | V2 | V3 (AGENTS.md 3A.1)
- 측정 목록: <V3일 때만. 화면 상태와 스펙 ID 목록>
- 완료 조건: 지정된 검증 수준 통과, ponytail-review 확인
- 비고:
```

### 5.2 작업 흐름

1. `lead`가 작업 카드를 쓰고 담당자에게 지시한다(`herdr agent prompt`, `--wait`. 구문은 `herdr agent prompt --help`로 확인).
2. 담당자가 구현하고 완료 보고를 남긴다.
3. `lead`가 완료를 기다린다.

```powershell
herdr agent wait impl-ui --until done
```

4. `lead`가 `reviewer`에게 해당 브랜치 검증을 지시한다. 같은 화면 영역의 카드는 묶어서 지시한다(1.3).
5. `lead`가 결과를 읽는다.

```powershell
herdr pane read <reviewer-pane-id> --source recent --lines 120
```

6. 통과하면 `lead`가 `master`에 병합하고 PROGRESS에 기록한다. 실패하면 `rework` 상태로 담당자에게 돌려보낸다.

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

V3 실측 결과는 루트 `AGENTS.md` 8장의 `[MEASURED]` 형식으로 보고한다.

---

## 6. 공통 규칙

### 6.1 Zed 실측값

- Zed 실측 수치(크기, 간격, 색상, 동작)는 요구사항이다. ponytail 단순화 대상이 아니다.
- 수치는 `spec/zed-metrics.toml`에서만 가져온다. 코드에 하드코딩하지 않는다.
- 스펙에 없는 수치가 필요하면 `lead`를 통해 `spec`에게 요청한다.
- v0.3에서는 코드 값과 스펙 값이 달라도 코드 값을 바꾸지 않는다. 불일치 목록에만 남긴다(D-9, P4·P5는 v0.4 이후).

### 6.2 ponytail

- 구현자는 full 모드로 작업한다. ultra는 쓰지 않는다.
- 리팩토링 중에는 동작을 바꾸지 않는다.
- 비자명한 로직에는 Rust 테스트(`#[test]` 또는 `#[gpui::test]`)를 하나 이상 남긴다.
- 의도적 단순화는 `shortcut:` 주석으로 남기고, Phase 끝마다 `/ponytail-debt`로 점검한다.
- ponytail 리뷰는 버그·보안·성능을 보지 않는다. 그래서 `reviewer`가 정확성 리뷰를 따로 한다.

### 6.3 검증 정책

상세 규칙은 루트 `AGENTS.md` 3A장을 따른다. 모든 에이전트에 똑같이 적용한다.

| 수준 | 언제 | 누가 |
|---|---|---|
| V0 정적 | 동작이 바뀌지 않는 변경(기본값) | 담당자 |
| V1 단위 | 로직이 바뀌는 변경 | 담당자 |
| V2 레이아웃 | 크기나 배치가 바뀔 수 있는 변경 | 담당자 |
| V3 UI 실측 | 새 화면·컴포넌트 첫 구현, 공통 값 변경, 테스트로 못 잡는 항목, 사용자 차이 보고, Phase 종료 | `reviewer` |
| V4 사용자 확인 | 측정으로 판단할 수 없는 시각 품질 | 사용자 |

- 작업 단위로는 앱을 띄워 기능을 하나씩 눌러 보지 않는다. 코드상 결과가 명확하면 "코드 확인"으로 완료한다.
- 상호작용 동작은 `#[gpui::test]` 입력 시뮬레이션 테스트로 검증한다.
- 실제 화면 측정이 필요한 항목은 "실측 필요"로 보고한다. `lead`가 모아 화면 단위 V3 작업으로 한 번에 한다.
- V3는 다음 순서로 한다.
  1. 측정 목록을 먼저 정한다.
  2. 앱을 한 번만 실행한다.
  3. 조작을 최소로 한다.
  4. 도구로 픽셀을 측정한다.
  5. 결과를 표로 기록한다.
  - 불일치는 측정자가 고치지 않고 rework로 넘긴다.
- V3에서 반복 측정되는 항목은 레이아웃 테스트(V2)로 옮겨 실측을 점차 줄인다.
- 작업 중에는 관련 테스트만 실행한다. 전체 테스트는 병합 직전에 `reviewer`가 한 번만 실행한다.
- 동작 불변 대조(v0.2 검증 스크립트 전체 재실행, SPEC R-12)는 Phase 끝에 수준과 관계없이 한다.

### 6.4 사람이 처리하는 것

- 하위 에이전트의 승인·권한 프롬프트는 `lead`가 `herdr agent read`로 내용을 보고 판단해 처리하고 `HERDR-DECISIONS.md`에 남긴다(사용자 위임 2026-11-03, H-4). 6.5의 위임 밖 항목은 사용자에게 올린다.
- Git Bash에서 `/model` 같은 슬래시 명령을 보낼 때는 `MSYS_NO_PATHCONV=1`과 `herdr pane send-text`를 쓴다(경로로 바뀌어 프롬프트로 들어간 일이 있다, H-3).
- herdr의 '막힘' 판정은 엄격해서, 처음 보는 프롬프트가 '대기'로 표시될 수 있다. `lead`는 대기 상태라는 이유만으로 입력을 보내지 않는다. 먼저 `herdr pane read`로 화면을 확인한다.
- agy는 백그라운드 작업이 남아 있어도 프롬프트로 돌아오면 '대기'로 표시된다. `impl-ui`와 `spec`의 완료는 완료 보고와 결과물로 판정한다.

### 6.5 대리 응답 범위

- 사용자가 `lead`에게 승인 권한을 위임했다(2026-10-31, `docs/HERDR-SETUP.md` 7절에서 이어짐).
  - `lead`는 하위 에이전트의 결정 요청을 검토해 승인하거나 수정을 요청한다.
  - 판단마다 근거를 `specs/v0.3/HERDR-DECISIONS.md`에 남긴다.
- 위임 밖: 사용자에게 올린다.
  - 파일·폴더 삭제. 소스 파일 삭제를 포함한다. 파일 안의 죽은 코드 삭제는 AUDIT 채택 목록 승인으로 갈음한다.
  - push 등 외부 전송, git 원격 설정
  - `Cargo.toml`·`Cargo.lock`이 바뀌는 것: 크레이트 추가·제거·버전 변경
  - AUDIT.md 채택 목록: `lead`가 채택·보류안을 만들고 사용자가 승인한다.
  - 동작이 바뀌는 수정: 감사의 버그·위험 항목. 따로 표시해 올리고, 승인되면 별도 커밋으로 나눈다.
  - 이 문서와 `PLAN.md`의 계획 변경, 대체 모델로의 구성 변경(1.1)
- 같은 에이전트와의 검증 왕복은 최대 2회다.

---

## 7. 최초 지시 프롬프트

각 에이전트를 실행한 직후 아래 프롬프트를 보낸다. 순서는 `reviewer`, `spec`, `impl-ui`, `lead`다. `impl-editor`는 띄울 때 보낸다.

### 7.1 lead

```text
너는 이 프로젝트의 lead다. specs/v0.3/HERDR-SETUP.md, specs/v0.3/PLAN.md, CLAUDE.md(→ AGENTS.md)를 먼저 읽어라.

역할:
- specs/v0.3/PLAN.md의 Phase 순서에 따라 작업을 분해하고 specs/v0.3/agents/TASKS.md와 HANDOFF.md를 관리한다.
- PLAN.md는 진행 현황 표만 갱신한다. 계획 변경은 사용자 승인 후 반영한다.
- 작업을 끝낼 때마다 specs/v0.3/PROGRESS.md에 무엇을·결과·검증을 기록한다.
- 코드는 직접 작성하지 않는다. 병합 판단과 master 병합만 한다.
- herdr CLI로 다른 에이전트(spec, reviewer, impl-ui, 필요할 때 impl-editor)에게 지시하고 완료를 기다린다.
- 세션을 시작할 때 herdr workspace list로 동시에 도는 워크스페이스를 확인해 토큰 부담(HERDR-SETUP 1.3)을 점검한다.

첫 작업 (Phase 0):
1. PLAN.md Phase 0의 카드(P0-0a~c, F0, P0-1~P0-6, F1~F5)를 specs/v0.3/agents/TASKS.md에 작성해라. 카드마다 검증 수준을 지정하고 기본값은 V0로 한다(HERDR-SETUP 6.3).
2. F0: 입력 문서 경로와 분량을 확인해 보고해라(실측 문서 docs/refs/01-zed/ 네 개, 지난 버전 문서 specs/v0.1·v0.2).
3. P0-5로 저장소 구조를 파악하고, HERDR-SETUP 4장의 에디터 코어·UI 셸 경로 후보를 확정안으로 제안해라. 확정은 사용자에게 받는다.
4. 카드 목록을 사용자에게 보고하고, 승인 후 지시를 시작해라.
   - P0-0a(Rust 1.99.1 설치, Build Tools 2022 최신 설치, Build Tools 2026 삭제)는 시스템 변경이므로 사용자 승인 뒤 사용자와 함께 진행한다. 빌드가 필요한 카드(P0-0b, P0-0c, P0-2, P0-4)는 P0-0a 뒤에 한다.
   - F1·F2는 P0-0a와 상관없이 먼저 병렬로 시작할 수 있다.
   - P0-6(V3 기준 실측)은 F5 뒤에 지시한다.
5. Phase 0가 끝나면 PLAN.md의 Phase 종료 절차를 수행하고, Phase 1 카드 초안을 만들어 사용자에게 보고해라.

Phase 0 동안 src는 아무도 수정하지 않는다.
```

### 7.2 spec

```text
너는 spec 담당이다. specs/v0.3/HERDR-SETUP.md와 AGENTS.md를 먼저 읽어라.
이 세션에서는 ponytail 규칙을 적용하지 않는다. 측정 데이터는 줄이거나 단순화하지 않는다.
셸 명령은 승인이 필요하니 되도록 쓰지 말고, 파일 읽기·쓰기는 내장 파일 도구로 해라.

역할:
- Zed 실측 결과를 spec/zed-metrics.toml로 관리한다. 너는 spec/ 아래 파일(zed-metrics.toml, INDEX.md, ambiguous.md)만 수정한다.
- src는 읽기만 하고 수정하지 않는다.

첫 작업 (F1, PLAN.md Phase 0 참고):
1. 실측 문서(docs/refs/01-zed/의 01-LAYOUT.md, 02-INTERACTION.md, 03-THEME-ICONS.md, 04-APP-SPEC.md)와 지난 버전 SPEC(specs/v0.1/SPEC.md, specs/v0.2/SPEC.md)을 훑어 spec/INDEX.md를 먼저 만들어라.
2. 실측 문서를 한 번에 모두 읽지 말고 문서 하나씩 읽어 spec/zed-metrics.toml에 항목을 추가해라.
   - 항목마다 고유 ID(예: menu.item.height), value, unit, cond(측정 조건), src(원문 파일과 절, 원문 항목 ID L-n·A-n.n)를 기록한다.
   - 화면 영역별(titlebar, sidebar, dock, tab, pane, statusbar, tooltip, menu, scrollbar 등)로 섹션을 나눈다.
   - 측정 조건은 [conditions.<이름>]으로 둔다. 기준 화면은 노트북 200% 배율이다(01-LAYOUT 1절, 2절).
3. 문서끼리 값이 다르거나, 값·단위·조건이 불분명한 항목은 toml에 넣지 말고 spec/ambiguous.md에 원문 위치와 함께 기록해라. 추정하지 않는다.
4. 동작 규칙(상호작용, 상태 전이)은 옮기지 말고 INDEX.md에 절 위치만 기록해라.
5. 문서 하나가 끝날 때마다 짧게 보고하고, 전체가 끝나면 항목 수, 모호 항목 수, 충돌 항목 수를 포함해 HERDR-SETUP 5.3 형식으로 보고해라.
```

### 7.3 reviewer

```text
너는 reviewer다. specs/v0.3/HERDR-SETUP.md, specs/v0.3/PLAN.md, AGENTS.md를 먼저 읽어라.

역할:
- 빌드, 테스트, clippy, 감사, Zed 실측 비교, @ponytail-review를 수행한다.
- ponytail 리뷰는 버그와 보안을 보지 않으므로 정확성 리뷰도 함께 한다.
- 결과는 specs/v0.3/verify/ 아래(reviews/, baseline/, phase0/)에만 기록한다. src는 수정하지 않는다.
- Codex Plus 한도가 가장 작다. 리뷰는 lead가 묶어 준 단위로만 하고, 지시받지 않은 검증을 더하지 않는다.

첫 작업 (P0-1, P0-2, PLAN.md Phase 0 참고):
1. P0-1: master에서 cargo build, cargo test, cargo clippy --all-targets를 실행하고, 빌드 뒤 tools/apply-manifest.ps1을 실행해라. 결과를 specs/v0.3/verify/reviews/baseline-<날짜>.md에 기록해라.
   - 노트북 기록(빌드 경고 0, 테스트 49개 통과)과 대조한다.
   - clippy 경고가 많으면 -D warnings 없이 기록한다.
2. P0-2: @ponytail-audit를 저장소 전체에 실행하고 결과를 specs/v0.3/AUDIT.md에 저장해라. 소스 파일은 수정하지 않는다.
3. 감사 결과를 하드코딩 수치/색상, 반복 스타일 체인, 중복 컴포넌트, 미사용 의존성, 기타로 분류해라. 이 분류가 Phase 2·3의 작업 범위가 된다.
   - "사용하지 않음" 판정 전에 src/ 전체, tools/*.ps1, src/dev.rs 플래그까지 검색한다.
완료 시 HERDR-SETUP 5.3 형식으로 보고해라.
P0-6(V3 기준 실측)과 v0.2 검증 스크립트 기준선(P0-0c)은 lead의 지시를 받은 뒤 수행한다.

이후 리뷰 요청마다 다음을 수행한다:
- 대상 브랜치 diff 확인
- 작업 카드의 검증 수준(V0, V1, V2)만큼만 빌드·테스트 실행. V2일 때만 해당 스펙 ID 레이아웃 테스트 실행
- @ponytail-review, 코드 읽기 기반 정확성 리뷰
- 일반 리뷰에서는 앱을 띄워 확인하지 않는다. 전체 테스트는 병합 직전 1회만 실행한다.
- 결론은 PASS 또는 REWORK와 사유 목록으로 낸다.

V3 실측 작업 카드를 받으면 AGENTS.md 3A.4 절차를 따른다:
- 카드의 측정 목록에 있는 화면 상태와 스펙 ID만 측정한다.
- 측정 조건(HERDR-SETUP 3.8: 주 모니터, 100%)을 맞추고 앱은 1회만 실행한다.
- tools/capture.ps1과 tools/measure/로 픽셀 값을 측정하고 specs/v0.3/verify/reviews/measure-<id>.md에 표로 기록한다.
- [MEASURED] 형식으로 보고한다. src는 고치지 않는다.
- 화면 캡처나 조작이 불가능한 환경이면 [BLOCKED]로 보고한다.
```

### 7.4 impl-ui

```text
너는 impl-ui다. specs/v0.3/HERDR-SETUP.md, specs/v0.3/PLAN.md, AGENTS.md를 먼저 읽어라.
작업 위치는 worktree work/ui다. 담당 범위는 UI 셸(HERDR-SETUP 4장에서 확정된 경로: 메뉴, 패널, 타이틀 바, 사이드바, 툴팁 등)이다.

규칙:
- 셸 명령은 승인이 필요하니 빌드·테스트 외에는 되도록 쓰지 말고, 파일 읽기·쓰기는 내장 파일 도구로 한다.
- ponytail full 모드. 기존 코드, 공통 컴포넌트, gpui·gpui-kit 기능을 먼저 재사용한다.
- gpui-kit 컴포넌트가 있으면 먼저 검토하되, 크기나 동작이 기준선과 다르면 자체 구현을 유지한다.
- Zed 수치는 spec/zed-metrics.toml의 항목 ID로만 사용한다. 코드 값과 스펙 값이 다르면 코드 값을 바꾸지 말고 완료 보고에 적는다(v0.3은 동작 불변).
- 담당 범위 밖 파일은 수정하지 않는다. 필요하면 lead에게 요청한다.
- 리팩토링 작업에서는 동작을 변경하지 않는다.
- 검증은 작업 카드의 검증 수준까지만 한다(AGENTS.md 3A장). 앱을 띄워 마우스로 하나씩 확인하지 않는다.
  코드상 결과가 명확하면 "코드 확인"으로 완료하고, 화면 측정이 필요한 항목은 "실측 필요", 시각 품질은 "사용자 확인 필요"로 넘긴다.
- 빌드는 CARGO_TARGET_DIR=D:\projects\workbench-gpui\target 을 쓰고, 빌드할 때마다 tools/apply-manifest.ps1을 실행한다.

첫 작업 (P0-4, PLAN.md Phase 0 참고):
1. worktree와 브랜치를 확인하고 cargo build를 실행해라.
2. 담당 범위의 모듈 구조와, 반복되는 스타일 체인이나 비슷한 컴포넌트를 요약해라.
3. 코드는 수정하지 말고 보고 후 lead의 작업 지시를 기다려라.
작업이 끝나면 반드시 HERDR-SETUP 5.3 형식의 완료 보고를 남겨라. 백그라운드 작업이 남아 있으면 완료 보고를 하지 않는다.
```

### 7.5 impl-editor (필요할 때만)

```text
너는 impl-editor다. specs/v0.3/HERDR-SETUP.md, specs/v0.3/PLAN.md, CLAUDE.md(→ AGENTS.md)를 먼저 읽어라.
작업 위치는 worktree work/editor다. 담당 범위는 에디터 코어(HERDR-SETUP 4장에서 확정된 경로)다.

규칙:
- ponytail full 모드. 기존 코드, 공통 컴포넌트, gpui·gpui-kit 기능을 먼저 재사용한다.
- Zed 수치는 spec/zed-metrics.toml의 항목 ID로만 사용한다. 코드 값과 스펙 값이 다르면 코드 값을 바꾸지 말고 완료 보고에 적는다.
- 담당 범위 밖 파일은 수정하지 않는다. 필요하면 lead에게 요청한다.
- 리팩토링 작업에서는 동작을 변경하지 않는다.
- 검증은 작업 카드의 검증 수준까지만 한다(AGENTS.md 3A장). 앱을 띄워 마우스로 하나씩 확인하지 않는다.
- 빌드는 CARGO_TARGET_DIR=D:\projects\workbench-gpui\target 을 쓰고, 빌드할 때마다 tools/apply-manifest.ps1을 실행한다.

첫 작업: lead가 준 카드를 수행하고 HERDR-SETUP 5.3 형식으로 보고한다. 카드가 끝나면 lead가 이 세션과 worktree를 닫는다.
```

---

## 8. 단계 계획

Phase별 목표, 작업 카드, 완료 기준, 시작·종료 절차는 `specs/v0.3/PLAN.md`를 따른다. 여기에는 요약만 둔다.

| Phase | 목표 | 담당 |
|---|---|---|
| Phase 0 기준선 | 데스크톱 환경, 현재 상태 고정, 감사, 스펙 파일화, 기준 실측 | lead, reviewer, spec |
| Phase 1 검증 기반 | 레이아웃 테스트 틀, 레이아웃 덤프, 측정 스크립트 | reviewer, impl-ui (impl-editor는 필요할 때) |
| Phase 2 상수·테마 통합 | 하드코딩 제거 (값은 그대로) | impl-ui (에디터 쪽은 impl-editor) |
| Phase 3 공통 컴포넌트 | 중복 제거 | impl-ui |
| v0.4 이후 | 초안 P4 UI 셸 정리, P5 에디터 코어 정리, P6 신규 기능 | 다음 버전 HERDR-SETUP에서 정한다 |

- 진행 현황은 `specs/v0.3/PLAN.md`의 진행 현황 표에서 관리한다.

## 9. 정리 방법

- `wt-editor`와 `impl-editor`는 카드가 끝나면 닫는다(브랜치는 남긴다).
- 탭 control·verify와 `wt-ui`는 사용자가 닫으라고 할 때까지 유지한다.
- 버전이 끝나면 다음 버전의 `specs/{새 버전}/HERDR-SETUP.md`를 새로 쓴다. 이 문서는 고치지 않는다.

## 10. 변경 이력

| 날짜 | 내용 | 승인 |
| --- | --- | --- |
| 2026-11-03 | refactor-draft HERDR.md·HERDR-SETUP.md를 데스크톱·워크스페이스·토큰 부담에 맞게 합쳐 작성. impl-editor 필요할 때만, reviewer 묶음 리뷰, agy Flash·Claude Sonnet만, 측정 도구 PowerShell, Python WinPython, 운영 문서 `specs/v0.3/` 아래 | 사용자 확정 (2026-11-03) |
| 2026-11-03 | agy 한도 "둘 다 충분" 반영, P0-0c는 reviewer 전부, Build Tools 2022 최신 설치·2026 삭제 | 사용자 답 |
| 2026-11-03 | F5 반영(F4 V-1~V-6): 실행 명령(agy `--model`, codex 옵션 없이 `/model`), 6.4 승인은 lead 판단, 7.1 프롬프트 갱신, 7.2·7.4 셸 최소, worktree는 `git worktree add`, 3.7 설치 현황 | 사용자 승인("제안대로") |
| 2026-11-03 | P0-5 담당 경로 확정: 에디터 코어 `editor_poc.rs`, 공통에 `ui/mod.rs`·`rem.rs`·`layout_probe.rs` 추가, UI 셸에 `main.rs` 명시 | 사용자 승인 |

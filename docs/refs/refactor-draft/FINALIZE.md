# FINALIZE.md - 스펙·플랜 확정 작업 절차

기존 구현에서 사용한 Zed 실측 문서와 스펙 관련 문서(intent, decisions, spec, plan, progress)를 정리하여, 최종 스펙과 최종 플랜을 확정하는 절차를 정의한다.

- 기준일: 2026-11-02
- 소유자: 사용자
- 적용 기간: 이 문서의 F5(사용자 확정)가 끝날 때까지

---

## 1. 원칙

- **기존 운영 문서는 수정하지 않는다.** HERDR.md, AGENTS.md, PLAN.md는 이 절차가 끝날 때까지 그대로 둔다. 확정 후 6장의 반영 목록에 따라 한 번에 갱신한다.
- **기준은 하나만 둔다.** 확정 후에는 수치는 `spec/zed-metrics.toml`, 계획은 `PLAN.md`, 진행은 `docs/agents/TASKS.md`와 `docs/agents/HANDOFF.md`만 기준으로 쓴다. 기존 plan, progress는 보관 처리한다.
- **긴 원문은 담당자만 통째로 읽는다.** 다른 에이전트는 담당자의 결과물(색인, toml, 요약)과 작업 카드에 지정된 절만 읽는다.
- **모든 수치에는 출처를 남긴다.** toml 항목마다 원문 파일과 절 위치를 기록해 언제든 역추적할 수 있게 한다.
- **추정하지 않는다.** 원문에서 값이나 측정 조건이 불분명하면 채우지 않고 모호 항목 목록으로 보낸다.
- **이 절차 동안 src는 수정하지 않는다.**

---

## 2. 입력 문서

경로 자리표시자(`<...>`)는 F0에서 `lead`가 실제 경로로 확정한다.

| 문서 | 경로 | 통째로 읽는 담당 | 다른 에이전트 |
|---|---|---|---|
| Zed 실측 문서(여러 개) | `<ZED_MEASURE_DIR>` | `spec` | `reviewer`가 F3 표본 대조 시 해당 절만 |
| spec | `<SPEC_DOC>` | `spec`(수치), `lead`(동작 규칙) | 작업 카드에 지정된 절만 |
| intent | `<INTENT_DOC>` | `lead` | 읽지 않음 |
| decisions | `<DECISIONS_DOC>` | `lead` | 작업 카드에 지정된 결정 ID만 |
| plan | `<PLAN_DOC>` | `lead` | 읽지 않음(F5 후 보관) |
| progress | `<PROGRESS_DOC>` | `lead` | 읽지 않음(F5 후 보관) |

### 2.1 읽기 규칙

- 긴 문서는 AGENTS.md나 CLAUDE.md에 `@`로 import하지 않는다. 모든 세션이 매번 통째로 읽게 된다.
- `spec`은 실측 문서를 한 번에 모두 읽지 않고 문서 단위로 순차 처리한다. 문서 하나를 끝내면 결과를 저장하고 다음 문서로 넘어간다.
- 다른 에이전트는 `spec/INDEX.md`를 보고 필요한 절만 연다.

---

## 3. 산출물과 소유권

이 절차 동안에만 적용하는 소유권이다. 확정 후에는 HERDR.md 4장에 반영한다.

| 경로 | 소유자 | 내용 |
|---|---|---|
| `spec/INDEX.md` | `spec` | 실측 문서와 spec 문서의 색인(문서별 한 줄 요약, 절 목록, 화면 영역) |
| `spec/zed-metrics.toml` | `spec` | 최종 수치 스펙(ID, 값, 단위, 측정 조건, 출처) |
| `spec/ambiguous.md` | `spec` | 값이나 조건이 불분명한 항목, 원문 간 충돌 항목 |
| `docs/agents/finalize/review-notes.md` | `lead` | intent, decisions 검토 결과, 문서 간 충돌 목록 |
| `docs/agents/finalize/plan-reconcile.md` | `lead` | 기존 plan, progress와 새 PLAN.md 대조표 |
| `docs/agents/finalize/PLAN-draft.md` | `lead` | PLAN.md 개정안 |
| `docs/agents/reviews/spec-sample-check.md` | `reviewer` | toml 표본 대조 결과 |
| `archive/` | `lead` | F5 후 보관하는 기존 plan, progress |

### 3.1 toml 항목 형식

```toml
[menu.item]
height = { value = 28, unit = "px", cond = "default", src = "<ZED_MEASURE_DIR>/menu.md#item-height" }
padding_x = { value = 8, unit = "px", cond = "default", src = "<ZED_MEASURE_DIR>/menu.md#item-padding" }

[conditions.default]
window = "1280x800"
dpi_scale = 1.0
theme = "<theme name>"
font = "<font name and size>"
```

- 위 값은 형식 예시다. 실제 값은 원문에서만 가져온다.
- 섹션은 화면 영역 단위로 나눈다(titlebar, menu, tab, panel, editor, statusbar, icon 등).
- 측정 조건이 다른 값은 `[conditions.<name>]`을 추가하고 `cond`로 참조한다.
- 항목 ID(섹션 경로 + 키)는 한번 정하면 바꾸지 않는다.

---

## 4. 단계

| 단계 | 담당 | 내용 | 산출물 | 선행 |
|---|---|---|---|---|
| F0 준비 | `lead` | 입력 경로 확정, 문서 목록과 분량 파악, F 카드 작성 | TASKS.md의 F 카드 | - |
| F1 실측 정리 | `spec` | 색인 작성, toml 변환, 모호 항목 정리 | INDEX.md, zed-metrics.toml, ambiguous.md | F0 |
| F2 의도·결정 검토 | `lead` | intent, decisions 검토, plan, progress 대조 | review-notes.md, plan-reconcile.md | F0 |
| F3 표본 대조 | `reviewer` | toml 항목을 원문과 표본 대조 | spec-sample-check.md | F1 |
| F4 플랜 개정안 | `lead` | PLAN.md 개정안 작성 | PLAN-draft.md | F2, F3 |
| F5 사용자 확정 | 사용자 | 모호 항목 결정, 개정안 승인, 반영 지시 | 확정 기록 | F4 |

- F1과 F2는 병렬로 진행한다.
- PLAN.md의 P0-1(기준선), P0-2(ponytail 감사), P0-4(worktree 빌드 확인)는 원문 문서와 무관하므로 이 절차와 병렬로 진행할 수 있다.
- PLAN.md의 P0-3(스펙 파일화)은 F1로 대체한다. P0-6(V3 기준 실측)은 F5 이후에 진행한다.

### F0 준비 (`lead`)

1. 입력 문서 6종의 실제 경로를 확인하고 2장의 자리표시자를 채운 목록을 사용자에게 보고한다.
2. 실측 문서는 파일 목록, 대략적 분량, 다루는 화면 영역을 함께 보고한다.
3. `docs/agents/TASKS.md`에 F1~F4 카드를 작성한다. 카드 ID는 `F1-1`처럼 단계 번호 기준으로 붙인다.
4. 사용자 승인 후 F1, F2를 시작한다.

### F1 실측 정리 (`spec`)

1. **색인 먼저:** 실측 문서와 spec 문서를 훑어 `spec/INDEX.md`를 만든다.
   - 문서별 한 줄 요약, 절 목록(앵커 포함), 다루는 화면 영역, 측정 조건 기재 여부
2. **문서별 변환:** 실측 문서를 하나씩 읽어 `spec/zed-metrics.toml`에 항목을 추가한다.
   - 항목마다 `src`에 원문 파일과 절을 기록한다.
   - 같은 대상에 대해 문서끼리 값이 다르면 둘 다 toml에 넣지 않고 `ambiguous.md`의 충돌 항목으로 보낸다.
3. **spec 문서 처리:** `<SPEC_DOC>`의 수치는 toml로 옮기고, 동작 규칙(상호작용, 상태 전이 등)은 원문에 그대로 두고 색인에 절 위치만 기록한다.
4. **모호 항목:** 값, 단위, 측정 조건 중 하나라도 불분명한 항목은 `ambiguous.md`에 원문 위치와 함께 기록한다.
5. 문서 하나가 끝날 때마다 진행 상황을 짧게 보고한다. 전체가 끝나면 `[DONE]` 형식으로 보고한다(항목 수, 모호 항목 수, 충돌 항목 수 포함).

### F2 의도·결정 검토 (`lead`)

1. **intent 검토:** 프로젝트 목표와 범위를 정리하고, 현재 PLAN.md의 Phase 구성과 어긋나는 부분을 찾는다.
2. **decisions 검토:** 결정마다 ID가 없으면 `D-001`부터 부여한다. 내용은 바꾸지 않고 ID만 추가한다. 이후 작업 카드는 이 ID로 결정을 참조한다.
3. **충돌 확인:** decisions와 spec, 실측 문서 사이에 서로 다른 내용이 있으면 목록으로 만든다.
4. **plan, progress 대조:** 기존 plan의 항목과 progress의 완료 기록을 새 PLAN.md의 Phase(P0~P6)에 대응시킨다.
   - 이미 완료된 항목, 새 PLAN에 없는 항목, 폐기할 항목, 새 PLAN에만 있는 항목으로 분류한다.
5. 결과를 `review-notes.md`, `plan-reconcile.md`에 기록하고 사용자에게 요약 보고한다.

### F3 표본 대조 (`reviewer`)

1. `spec/zed-metrics.toml`의 섹션마다 항목을 표본으로 뽑는다(섹션당 최소 3개, 전체의 10% 이상).
2. 각 항목의 `src` 위치를 원문에서 열어 값, 단위, 측정 조건이 일치하는지 확인한다.
3. 결과를 `spec-sample-check.md`에 표로 기록한다(ID, toml 값, 원문 값, 판정).
4. 한 섹션에서 불일치가 1건이라도 나오면 그 섹션은 `spec`에게 전체 재검토를 요청하도록 `lead`에게 보고한다.
5. 이 단계는 문서 대조만 한다. 앱을 실행하지 않는다.

### F4 플랜 개정안 (`lead`)

1. 현재 PLAN.md를 기준으로 F2, F3 결과를 반영해 `PLAN-draft.md`를 작성한다.
   - progress에서 이미 완료된 작업은 해당 Phase 카드에서 제외하거나 완료로 표시한다.
   - intent와 decisions에서 나온 범위 조정을 반영한다.
   - P0-3은 F1 완료로 처리하고, P0-6의 측정 목록을 확정된 toml 기준으로 작성한다.
2. 현재 PLAN.md와 달라진 부분을 변경 요약으로 문서 앞부분에 정리한다.
3. 사용자가 결정해야 할 사항을 목록으로 정리한다(모호 항목, 문서 간 충돌, 범위 조정).

### F5 사용자 확정

사용자가 다음을 결정한다.

- [ ] `ambiguous.md`의 모호 항목과 충돌 항목 처리(값 결정, 재측정, 보류)
- [ ] F2의 decisions 충돌 처리
- [ ] `PLAN-draft.md` 승인 또는 수정 지시
- [ ] 기존 plan, progress 보관 처리 승인

승인 후 `lead`가 6장의 반영 목록을 수행한다.

---

## 5. 최초 지시 프롬프트

이 절차를 시작할 때 아래 프롬프트를 보낸다. `impl-editor`, `impl-ui`에는 PLAN.md P0-4만 지시한다.

### 5.1 lead

```text
FINALIZE.md를 먼저 읽어라. 지금부터 스펙·플랜 확정 절차(F0~F5)를 진행한다.
이 절차 동안 HERDR.md, AGENTS.md, PLAN.md는 수정하지 않는다.

1. F0: 입력 문서 6종(실측 문서, spec, intent, decisions, plan, progress)의 실제 경로를 찾아 보고해라.
   실측 문서는 파일 목록, 대략적 분량, 다루는 화면 영역을 함께 보고한다.
2. docs/agents/TASKS.md에 F1~F4 카드를 작성하고 사용자 승인을 받아라.
3. 승인 후 spec에게 F1을 지시하고, 너는 F2를 진행해라.
   병렬로 reviewer에게 PLAN.md P0-1, P0-2를, impl-editor와 impl-ui에게 P0-4를 지시해도 된다.
4. F1이 끝나면 reviewer에게 F3를 지시하고, F2와 F3가 끝나면 F4를 진행해라.
5. F4 결과와 F5 결정 목록을 사용자에게 보고하고 승인을 기다려라.
```

### 5.2 spec

```text
FINALIZE.md와 HERDR.md를 먼저 읽어라. 너는 F1 실측 정리 담당이다.
이 세션에서는 ponytail 규칙을 적용하지 않는다. 측정 데이터는 줄이거나 단순화하지 않는다.

1. 실측 문서(<ZED_MEASURE_DIR>)와 spec 문서(<SPEC_DOC>)를 훑어 spec/INDEX.md를 먼저 만들어라.
2. 실측 문서를 하나씩 읽어 spec/zed-metrics.toml에 항목을 추가해라. FINALIZE.md 3.1 형식을 따르고 항목마다 src에 원문 위치를 기록한다.
3. 문서끼리 값이 다르거나, 값/단위/측정 조건이 불분명한 항목은 toml에 넣지 말고 spec/ambiguous.md에 기록해라. 추정하지 않는다.
4. spec 문서의 동작 규칙은 옮기지 말고 색인에 절 위치만 기록해라.
5. 문서 하나가 끝날 때마다 짧게 보고하고, 전체가 끝나면 항목 수, 모호 항목 수, 충돌 항목 수를 포함해 [DONE] 형식으로 보고해라.
src는 수정하지 않는다.
```

### 5.3 reviewer (F3 지시 시)

```text
FINALIZE.md의 F3 절을 읽어라. 너는 F3 표본 대조 담당이다.

1. spec/zed-metrics.toml의 섹션마다 최소 3개, 전체 10% 이상을 표본으로 뽑아라.
2. 각 항목의 src 위치를 원문에서 열어 값, 단위, 측정 조건을 대조해라.
3. 결과를 docs/agents/reviews/spec-sample-check.md에 표(ID, toml 값, 원문 값, 판정)로 기록해라.
4. 불일치가 나온 섹션은 전체 재검토 대상으로 표시하고 lead에게 보고해라.
앱은 실행하지 않는다. 문서 대조만 한다.
```

---

## 6. 확정 후 반영 목록

F5 승인 후 `lead`가 수행한다. 반영 내용은 사용자에게 diff로 보고한다.

### 6.1 PLAN.md

- `PLAN-draft.md`로 교체한다.
- P0-3을 완료로 표시하고 FINALIZE 산출물을 참조하도록 한다.
- 진행 현황 표를 갱신한다.

### 6.2 HERDR.md

- 4장 소유권 표에 추가: `spec/INDEX.md`, `spec/ambiguous.md`(`spec`), `<DECISIONS_DOC>`(`lead`, ID 추가와 신규 결정 추가만), `<INTENT_DOC>`(사용자), `archive/`(`lead`)
- 7.2 spec 프롬프트의 입력 경로를 확정된 경로로 갱신하고, F1에서 이미 끝난 작업을 제외한다.
- 7.1 lead 프롬프트의 P0 순서를 개정된 PLAN.md에 맞춘다.
- `<ZED_MEASURE_DIR>` 등 자리표시자를 실제 경로로 바꾼다.

### 6.3 AGENTS.md

- 0장 "먼저 읽을 것"에 `spec/INDEX.md`를 추가한다.
- 3장에 추가: 원문 실측 문서는 `spec/INDEX.md`를 통해 필요한 절만 읽는다. 수치는 toml만 기준으로 한다.
- 7.4 lead 지침에 추가: 작업 카드에 관련 결정 ID(`D-xxx`)와 spec 문서 절을 명시한다.
- 9장 금지 사항에 추가: 긴 원문 문서를 AGENTS.md나 CLAUDE.md에 import하는 것.

### 6.4 보관 처리

- `<PLAN_DOC>`, `<PROGRESS_DOC>`을 `archive/`로 옮기고, 각 문서 맨 위에 "보관됨, 기준은 PLAN.md" 한 줄을 추가한다.
- `docs/agents/finalize/`는 확정 기록으로 남겨 둔다.

---

## 7. 진행 현황

| 단계 | 상태 | 완료일 | 비고 |
|---|---|---|---|
| F0 준비 | todo | | |
| F1 실측 정리 | todo | | |
| F2 의도·결정 검토 | todo | | |
| F3 표본 대조 | todo | | |
| F4 플랜 개정안 | todo | | |
| F5 사용자 확정 | todo | | |

- 상태: todo | doing | review | done
- 진행 현황 표는 `lead`가 갱신한다.

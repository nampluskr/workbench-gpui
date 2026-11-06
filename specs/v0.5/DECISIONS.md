> 버전: v0.5 · 작성일: 2026-11-06 · 상태: 초안 (core-leader 판정 뒤 사용자 확정)
>
> workbench-gpui가 v0.5에서 정한 결정을 기록한다. 두 갈래 공통 결정은 workbench-core `specs/v0.5/DECISIONS.md`의 D-1~D-11에 있고, 여기서는 다시 쓰지 않고 `core D-n`으로 가리킨다. 목적은 `INTENT.md`에, 요구는 `SPEC.md`에 있다.

# DECISIONS — workbench-gpui v0.5

## 적용하는 core 결정

이 레포는 아래 core 결정을 그대로 따른다(`D:\projects\workbench-core\specs\v0.5\DECISIONS.md`).

| core 결정 | 이 레포에서 적용하는 곳 |
|---|---|
| D-1 화면을 다루는 확인은 한 번에 하나씩 | `HERDR-SETUP.md` 5.4, `AGENTS.md` 3A |
| D-2 leader·writer·coder·checker 구성 | `HERDR-SETUP.md` 1·2장, `AGENTS.md` 6·7장 |
| D-3 공통 지시 카드와 파일 보고 | `HERDR-SETUP.md` 5장, `PLAN.md` |
| D-4 SCREEN-REQ·SCREEN-OK·SCREEN-DONE | `HERDR-SETUP.md` 5.4 |
| D-5 ITEMS.md | `SPEC.md` |
| D-6 core에는 core-leader 하나 | 없음(이 레포에 적용할 것 없음) |
| D-7 자기 워크스페이스만 쓴다 | `AGENTS.md` 레포 규칙 |
| D-8 Zed 테마·아이콘 테마 복사 | `SPEC.md` R-3·R-4, `PLAN.md` Phase 7 |
| D-9 Zed UI 아이콘 복사 | `SPEC.md` R-1·R-18, `PLAN.md` Phase 5 |
| D-10 IBM Plex Sans·Lilex 커밋 | `SPEC.md` R-14, `PLAN.md` Phase 3 |
| D-11 ITEMS가 SPEC 역할 | `SPEC.md` 판정 방법 |

---

## D-1. 서브 에이전트 카드는 `specs/v0.5/cards/<ID>.md`에, 보고는 `<ID>.report.md`에 둔다

**선택**

- leader가 서브 에이전트에게 주는 카드는 `specs/v0.5/cards/<ID>.md` 파일로 쓴다. herdr 프롬프트로는 카드 경로만 보낸다.
- 받는 에이전트는 결과를 `specs/v0.5/cards/<ID>.report.md`에 쓰고, 답으로는 그 경로만 말한다.
- W-01 카드부터 적용한다.

**근거**

- leader 확인 사실(2026-11-06, W-01 "확정 사실").
- 카드를 파일로 둘지와 어느 폴더에 둘지는 갈래가 정해 HERDR-SETUP에 적는다(ORDER-01 3.3).
- 카드 하나만 읽고 일할 수 있게 쓰고 보고는 파일 경로로 받는다(core D-3).

**배제한 대안**

- **v0.4처럼 `specs/v0.4/agents/TASKS.md` 작업 보드 하나에 카드를 모은다** — core D-3은 카드 하나만 읽고 일하게 하고, 서브 에이전트 컨텍스트를 Phase마다 비우므로 파일이 따로 있는 편이 낫다. leader가 카드 파일 방식을 정했다(2026-11-06).

---

## D-2. v0.4 worktree(`.worktrees\editor`, `.worktrees\ui`)는 v0.5에서 쓰지 않는다

**선택**

- v0.5는 main checkout(`D:\projects\workbench-gpui`, 브랜치 `master`) 하나에서 작업한다.
- 남아 있는 worktree `.worktrees\editor`(`work/editor`)와 `.worktrees\ui`(`work/ui`)는 쓰지 않는다. 지울지는 미정(사용자가 정한다).

**근거**

- worktree는 두지 않는다. coder가 하나라 같은 checkout에서 겹치지 않는다(core D-2).
- v0.4에서 쓰던 worktree가 남아 있으면 지우지 말고 보고한다. 지울지는 사람이 정한다(ORDER-01 3.2).
- leader 확인 사실(2026-11-06, W-01 "확정 사실"). `git worktree list` 결과 두 worktree가 남아 있다(writer 2026-11-06).

**배제한 대안**

- **v0.4처럼 coder를 worktree에서 일하게 한다** — core D-2가 worktree를 두지 않기로 했다.

---

## 미결 사항

- SPEC 요구 번호를 core I-n과 같은 번호의 R-n으로 매기는 것(R-1 = I-1 … R-23 = I-23). writer 초안이다. 번호 체계는 갈래가 정한다(ORDER-01 3.1). 정할 사람: leader(사용자 확정).
- core D-8·D-9의 복사본을 둘 `.gitignore` 폴더 경로, 복사 출처 Zed 커밋, 복사본이 없을 때 앱이 어떻게 보일지, 다시 채우는 방법. 정할 사람: leader(Phase 5·7 카드).
- core D-10에서 넣을 글꼴 굵기·스타일 파일과 글꼴 버전. 정할 사람: leader(Phase 3 카드).
- `spec/zed-metrics.toml`·`spec/INDEX.md`·`spec/ambiguous.md`의 소유자. v0.4의 `spec` 역할이 없어졌다. 정할 사람: leader.
- v0.4의 대리 응답 위임(하위 에이전트 승인 프롬프트를 lead가 판단, `specs/v0.4/HERDR-SETUP.md` 6.5)을 v0.5에서도 잇는지와 기록 위치. 정할 사람: 사용자.
- 루트 `INTENT.md` "다루지 않는 것"과 I-2·I-22의 충돌(`INTENT.md` 제외 범위). 정할 사람: 사용자.
- worktree 두 개를 지울지(D-2). 정할 사람: 사용자.

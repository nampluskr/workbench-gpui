> 버전: v0.5 · 작성일: 2026-11-06 · 상태: 확정 (core-leader 판정, 사용자 위임 2026-11-06)
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
| D-9 Zed UI 아이콘 복사 | 이 문서 D-6·D-7, `SPEC.md` R-1·R-18, `PLAN.md` Phase 5 |
| D-10 IBM Plex Sans·Lilex 커밋 | `SPEC.md` R-14, `PLAN.md` Phase 3 |
| D-11 ITEMS가 SPEC 역할 | `SPEC.md` 판정 방법 |
| D-12 core ITEMS가 갈래 지침보다 우선 | 루트 `INTENT.md`·`AGENTS.md`의 예외 표시, `AGENTS.md` 레포 규칙 "core ITEMS 우선", `SPEC.md` R-2·R-22, `PLAN.md` Phase 8 |
| D-14 gpui-base 0.8.1 vendor로 줄 번호 열을 Zed와 같게 | 이 문서 D-4·D-5, `SPEC.md` R-13·R-14, `vendor/gpui-base/PATCHES.md` |

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

## D-2. v0.4 worktree(`.worktrees\editor`, `.worktrees\ui`)는 v0.5에서 쓰지 않고 지운다

**선택**

- v0.5는 main checkout(`D:\projects\workbench-gpui`, 브랜치 `master`) 하나에서 작업한다.
- v0.4 worktree `.worktrees\editor`·`.worktrees\ui`와 로컬 브랜치 `work/editor`·`work/ui`는 지운다. 2026-11-06 leader가 master에 병합된 것을 확인한 뒤 지웠다. 원격 브랜치는 건드리지 않는다.

**근거**

- worktree는 두지 않는다. coder가 하나라 같은 checkout에서 겹치지 않는다(core D-2).
- v0.4에서 쓰던 worktree가 남아 있으면 지우지 말고 보고한다. 지울지는 사람이 정한다(ORDER-01 3.2).
- 사용자가 지우기로 했다("미정 네 가지 제안대로 진행해 주세요", 2026-11-06, ORDER-01-R2 C). leader가 지운 사실(2026-11-06, W-03). writer 확인: `git worktree list`에 본 트리 하나만 있고 `git branch`에 `work/editor`·`work/ui`가 없다(2026-11-06).

**배제한 대안**

- **v0.4처럼 coder를 worktree에서 일하게 한다** — core D-2가 worktree를 두지 않기로 했다.
- **worktree를 남겨 둔다** — 사용자가 지우기로 했다(ORDER-01-R2 C).

---

## D-3. `spec/`은 writer가 leader 카드로만 고치고, Zed 값 확인은 checker가 한다

**선택**

- `spec/zed-metrics.toml`·`spec/INDEX.md`·`spec/ambiguous.md`는 `writer`가 leader 카드로만 고친다.
- Zed 값 확인(원문 실측 문서 대조, Zed 화면 측정)은 `checker`가 하고 결과를 보고 파일로 넘긴다. `writer`가 그 보고를 `spec/`에 기록한다.
- `coder`는 `spec/`을 읽기만 한다.
- 스펙 항목 ID는 한번 정하면 바꾸지 않는다(v0.4 `AGENTS.md` 7.3에서 이어짐).
- v0.5에서는 각 I-n의 구현 카드가 그 I-n이 다루는 화면·값만 스펙 값으로 맞춘다. 카드 범위 밖에서 찾은 불일치는 고치지 않고 완료 보고에 적고, `writer`가 PROGRESS의 스펙 불일치 목록에 모은다. 모은 것은 Phase 12 사용자 일괄 확인 때 core-leader에게 올린다.
- workbench-tauri가 스펙 ID가 필요하면 core-leader를 거쳐 gpui-leader 카드로 요청한다. tauri는 이 레포 `spec/`에 쓰지 않는다(core D-7).

**근거**

- gpui-leader 안(`specs/v0.5/reports/ORDER-01-R2.md` "D. spec/ 소유 안")을 core-leader가 승인했다(core-leader 사용자 위임 2026-11-06, core D-13, ORDER-01-R2 D).
- core D-2에서 v0.4 `spec`(agy) 역할이 없어졌다. 문서 담당이 writer, 측정 담당이 checker다.
- 지난 커밋에 workbench-tauri용 스펙 ID를 이 레포 `spec/`에 더한 것이 있다(4badee1, 39350b7, 8eb170e). core D-7 이후로는 tauri가 이 레포에 쓰지 않는다.

**배제한 대안**

- **v0.4처럼 `spec` 역할을 따로 둔다** — core D-2가 v0.4 구성을 잇지 않고 서브 에이전트를 writer·coder·checker 셋으로 줄였다.

---

## D-4. gpui-base 0.8.1을 `vendor/gpui-base/`에 두고 줄 번호 열만 고친다

**선택**

- gpui-base 0.8.1을 `vendor/gpui-base/`에 복사하고 `Cargo.toml` `[patch.crates-io]`에 `gpui-base = { path = "vendor/gpui-base" }`를 둔다. 버전은 0.8.1 그대로다. 원본 `LICENSE-APACHE`(Apache-2.0)를 함께 둔다.
- 고친 곳은 줄 번호 열뿐이다: 최소 자릿수 3 → 4, 번호 좌우 여백(왼쪽 22px + 자릿수 × 숫자 폭 + 오른쪽 29px, 본문은 +5px), 일반·현재 줄 번호 색을 따로 받는 `EditorGutterTheme`. 바꾼 파일은 `src/input/base/element.rs`·`src/theme.rs`·`src/lib.rs` 셋이다.
- 원본과의 차이와 이유는 `vendor/gpui-base/PATCHES.md`에 적는다.

**근거**

- core D-14(core-leader 사용자 위임 2026-11-07, D-13)를 이 레포에 적용했다(K-07).
- gpui-component·gpui-base 0.8.1에는 줄 번호 최소 자릿수·여백을 바꿀 공개 옵션이 없다(K-06 조사). 줄 번호 전용 색도 없다(K-04 조사).
- C-14 리뷰: 원본 218개 파일과 해시 대조해 PATCHES.md에 적은 3개 외에는 같다. Cargo 변경은 patch 한 줄과 lock의 gpui-base source·checksum 두 줄뿐이다.

**배제한 대안**

- core D-14의 배제 대안을 따른다: (A) 지금 폭 유지, (C) 바깥 padding으로 근사, gpui-component 전체 fork.

---

## D-5. I-13 줄 번호 색은 Zed One Light 값으로 한다 (앞의 (A) 결정을 대체)

**선택**

- 현재 줄 번호 `#44454b`(T-05.08), 나머지 줄 번호 `#b4b4bb`(T-05.07). 지금 앱 테마(gpui-component Default Light)에 맞춰 One Light 값을 쓴다. 값은 `src/ui/theme.rs`가 `EditorGutterTheme`으로 넣는다(D-4).
- 앞서 core-leader DECISION(2026-11-07)의 "(A) 줄 번호 색은 현재 동작 유지(`foreground`/`muted_foreground`)"는 이 결정으로 대체됐다.

**근거**

- core D-14가 "(A) 유지"를 뒤집고 vendor로 줄 번호 색도 함께 맞추기로 했다.
- C-15 V3: 현재 줄 번호 `#44454b`, 일반 줄 번호 `#b4b4bb`를 픽셀로 확인(PASS, `verify/reviews/measure-ORDER-03.md`).

**배제한 대안**

- **(A) 현재 동작 유지, 차이를 Phase 12 V4로** — core D-14로 대체됐다.

---

## D-6. Zed UI 아이콘 복사본은 고정 커밋에서 `resources/zed-icons/`로 받고 커밋하지 않는다

**선택**

- 출처: `zed-industries/zed` 커밋 `4304dec732a75505066de5ce2dbbfb2bec369498`의 `assets/icons` 전체(UI SVG 299개, `file_icons/` 96개, `knockouts/` 6개, `LICENSES`)와 저장소 `LICENSE-APACHE`·`LICENSE-GPL`. 모두 404개 파일이다.
- 두는 곳: `resources/zed-icons/`. `.gitignore`에 넣고 커밋하지 않는다.
- 다시 채우기: 저장소 루트에서 `pwsh -NoProfile -File tools/fetch-zed-icons.ps1`. git과 네트워크가 필요하다. 같은 커밋만 받고 다른 커밋으로 대신하지 않는다(커밋·파일 수가 다르면 실패한다).
- 복사본이 없을 때: 앱은 죽지 않는다. 아이콘 자리는 같은 크기의 빈 칸으로 그리고, 시작할 때 stderr에 `zed icons missing: run tools/fetch-zed-icons.ps1`를 한 번 낸다.
- 앱 자리에 쓸 Zed 아이콘 이름은 같은 커밋의 Zed crates 소스에서 이름만 대조한다. 소스는 레포 밖 `%TEMP%`에만 받고 코드는 복사하지 않는다.
- 남은 비-Zed 출처: 파일 트리 파일 아이콘 `IconName::File`(gpui-kit). Phase 7(아이콘 테마)에서 다룬다.

**근거**

- core D-9(Zed UI 아이콘 복사)를 이 레포에 적용했다. 폴더·출처 커밋·없을 때 모습·다시 채우기는 leader가 정했다(K-08).
- K-08 보고: 전체 커밋 해시 확인, 404개 파일, `git ls-files resources/zed-icons` 0행. C-19 리뷰 PASS(파일 수·라이선스 3파일·추적 제외 확인).
- Zed crates 소스를 레포에 받으려던 것을 leader가 막고 `%TEMP%`로 옮기게 했다(K-08 작업 중, K-08 보고 "출처와 복원").
- 복사본 없음: `missing_zed_icons_are_empty_without_panic` 테스트, ORDER-05 V3 `MissingIcons` 단계(경고 있음, 빈 칸, 앱 안 죽음).

**배제한 대안**

- **이 PC의 Zed 설치 폴더에서 읽는다** — 버전이 고정되지 않는다. K-08 카드가 금지했다.
- **복사본을 커밋한다** — core D-9가 `.gitignore` 폴더에 두기로 했다.

---

## D-7. 창 제어 버튼 4개는 Zed Windows처럼 Segoe Fluent Icons 글리프로 그린다 (R-1 SVG 기준의 예외)

**선택**

- 최소화 U+E921, 최대화 U+E922, 복원 U+E923, 닫기 U+E8BB. 글꼴은 `Segoe Fluent Icons`, 없으면 `Segoe MDL2 Assets`.
- R-1의 "아이콘은 Zed 원본 SVG로" 기준에서 이 4자리만 뺀다. Linux용 `generic_*.svg`는 쓰지 않는다.

**근거**

- core-leader 결정(창 버튼 Segoe Fluent 글리프 예외, 2026-11-07, D-13).
- Zed도 Windows에서는 창 제어 버튼을 이 글리프로 그린다: 같은 커밋 `crates/platform_title_bar/src/platforms/platform_windows.rs` 16~39·80~83행(leader 확인, K-08-R1). C-19가 같은 행으로 대조했다.
- K-08-R1로 K-08 전 구현(`src/ui/title_bar.rs`)으로 되돌렸다.

**배제한 대안**

- **K-08처럼 `generic_minimize.svg` 등 SVG로 그린다** — Linux용이라 Windows Zed와 모양이 다르다.

---

## 미결 사항

- SPEC 요구 번호를 core I-n과 같은 번호의 R-n으로 매기는 것(R-1 = I-1 … R-23 = I-23). writer 초안이다. 번호 체계는 갈래가 정한다(ORDER-01 3.1). 정할 사람: leader(사용자 확정).
- core D-8의 복사본(테마·아이콘 테마)을 둘 `.gitignore` 폴더 경로, 복사 출처 Zed 커밋, 복사본이 없을 때 앱이 어떻게 보일지, 다시 채우는 방법. 정할 사람: leader(Phase 7 카드). core D-9 쪽은 D-6으로 정했다.
- core D-10에서 넣을 글꼴 굵기·스타일 파일과 글꼴 버전. 정할 사람: leader(Phase 3 카드).

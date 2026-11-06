> 버전: v0.5 · 작성일: 2026-11-06 · 상태: 확정 (core-leader 판정, 사용자 위임 2026-11-06)
>
> workbench-gpui v0.5의 요구(R-1~R-23)를 어떤 Phase 순서로 만족시킬지 적는다. Phase는 workbench-core `specs/v0.5/PLAN.md`의 Phase 1~12와 같은 번호로 둔다. 요구는 `SPEC.md`에, 결정은 `DECISIONS.md`에, 에이전트 구성과 작업 방식은 `HERDR-SETUP.md`에, 실제 진행은 `PROGRESS.md`에 있다.

# PLAN — workbench-gpui v0.5

## 읽는 법과 이 순서에 걸린 규칙

**번호 표기**

- `R-n`은 이 레포 `SPEC.md`의 요구이고, 같은 번호의 core 항목 `I-n`에 대응한다(R-1 = I-1 … R-23 = I-23).
- `core D-n`은 workbench-core `specs/v0.5/DECISIONS.md`의 결정, `D-n`은 이 레포 `DECISIONS.md`의 결정이다. `G-n`은 core ITEMS의 그룹이다.
- `ORDER-<n>`은 core-leader의 지시 카드(`D:\projects\workbench-core\specs\v0.5\orders\ORDER-<n>.md`)이고, 번호는 core Phase 번호와 같다. 다시 지시하면 `-R<n>`이 붙는다(core D-3).
- 이 레포의 Phase 번호는 core Phase 번호와 같다. Phase 안을 더 나눌지는 Phase마다 leader가 카드로 정한다(ORDER-01 3.1).

**대응 표**

| 이 레포 Phase | core Phase | 지시 카드 | 그룹 | 요구(I-n) | 관련 결정 |
|---|---|---|---|---|---|
| Phase 1 — 갈래 준비 | Phase 1 | ORDER-01 | 없음 | 없음 | core D-1·D-2·D-3·D-4·D-7·D-11·D-12 |
| Phase 2 — 창 | Phase 2 | ORDER-02 | G-5 | R-6(I-6) | 없음 |
| Phase 3 — 편집 영역과 글꼴 | Phase 3 | ORDER-03 | G-6 | R-7·R-8·R-9·R-13·R-14(I-7·I-8·I-9·I-13·I-14) | core D-10 |
| Phase 4 — 글자 표시 | Phase 4 | ORDER-04 | G-8 | R-20(I-20) | 없음 |
| Phase 5 — 아이콘 모양 | Phase 5 | ORDER-05 | G-1 | R-1·R-18(I-1·I-18) | core D-9 |
| Phase 6 — 타이틀 바 메뉴 | Phase 6 | ORDER-06 | G-2 | R-2·R-17(I-2·I-17) | core D-12 |
| Phase 7 — 테마·아이콘 테마 | Phase 7 | ORDER-07 | G-3 | R-3·R-4(I-3·I-4) | core D-8 |
| Phase 8 — 상태 바 | Phase 8 | ORDER-08 | G-4 | R-5·R-19·R-22(I-5·I-19·I-22) | core D-12 |
| Phase 9 — 탭 바와 편집 영역 상단 | Phase 9 | ORDER-09 | G-7 | R-10·R-11·R-12·R-16·R-23(I-10·I-11·I-12·I-16·I-23) | 없음 |
| Phase 10 — 폴더 보기 패널 | Phase 10 | ORDER-10 | G-9 | R-21(I-21) | 없음 |
| Phase 11 — 구문 강조 | Phase 11 | ORDER-11 | G-10 | R-15(I-15) | 없음 |
| Phase 12 — 사용자 일괄 확인 | Phase 12 | ORDER-12 | 없음 | V4가 있는 R-14·R-15(I-14·I-15)와 사용자가 다시 보기를 원하는 요구 | 없음 |

R-1~R-23은 모두 Phase 2~11 가운데 한 곳에 대응한다.

**Phase 순서의 이유**

core PLAN의 순서를 그대로 따른다. 이유도 core PLAN "Phase 순서의 이유"와 같다.

- Phase 2(창)를 먼저 한다. Zed와 비교하는 모든 판정이 창 1440×852를 조건으로 한다(core D-11).
- Phase 3(글꼴)을 그다음에 한다. 글꼴(R-14)이 UI 전체의 글자 폭과 높이를 바꾼다.
- Phase 4(`₩`, R-20)는 글꼴 뒤에 둔다. 글꼴 변경으로 풀리면 남은 것만 고친다.
- Phase 5(아이콘)와 Phase 6(메뉴)은 Phase 7(테마·아이콘 테마)보다 먼저 한다. "Zed 기본" 아이콘 테마가 Phase 5의 아이콘이고, Themes·Icon Themes 메뉴가 Phase 6에 있다.
- Phase 8·9·10은 서로 겹치지 않는다. 상태 바 왼쪽 아이콘(R-18)이 Phase 5에서 끝나 있어야 해서 그 뒤에 둔다.
- Phase 11(구문 강조)은 작업량이 가장 크고, 강조 색이 테마(Phase 7)에서 온다.

**모든 Phase에 걸리는 규칙**

- 시작: leader는 core-leader의 ORDER 카드를 받았을 때만 Phase를 시작한다(core D-3).
- 카드: leader는 ORDER 카드를 이 레포 작업 카드(`specs/v0.5/cards/<ID>.md`)로 나눠 서브 에이전트에게 준다. 카드의 완료 기준은 대응 요구의 판정 방법을 그대로 옮긴다(core D-11). 카드마다 검증 수준을 지정한다(`AGENTS.md` 3A).
- 공통 전제와 다를 때: 이 레포에 그 화면·기능이 없거나 이미 다르게 생겼으면 혼자 맞추지 않고 `[BLOCKED]`로 보고한다(core D-3).
- Zed에서 확인: SPEC에 "Zed에서 확인"으로 미정인 값은 그 Phase에서 먼저 Zed를 확인하고, 확인한 Zed 동작을 보고에 적고 SPEC에 더한다(core PLAN 보고 규칙).
- 화면: 화면을 다루는 확인은 한 번에 하나만 하고, `[SCREEN-REQ]`·`[SCREEN-OK]`·`[SCREEN-DONE]`으로 core-leader에게 차례를 받는다(core D-1·D-4, `HERDR-SETUP.md` 5.4).
- 보고: leader가 `specs/v0.5/reports/ORDER-<n>.md`에 항목별 판정 결과, 검증 수준, 같은 조건의 Zed·이 레포 캡처 경로를 쓰고 core-leader에게 경로만 보낸다.
- 기록: Phase 안의 작업마다 PROGRESS에 무엇을·결과·검증을 남긴다.
- 넘어가는 조건: Phase의 모든 요구가 충족되었거나, 충족하지 못한 요구와 이유가 PROGRESS와 보고 파일에 남아 있다(core PLAN).
- 컨텍스트: Phase가 바뀔 때 서브 에이전트의 컨텍스트를 비운다(ORDER-01 3.2).

---

## Phase 1 — 갈래 준비

**목적** — v0.5 작업을 받을 수 있게 이 레포의 v0.5 문서를 쓰고, herdr 에이전트를 core D-2 구성으로 꾸린다.

**대응** — 요구 없음. core D-1·D-2·D-3·D-4·D-7·D-11·D-12, 이 레포 D-1·D-2. 지시 카드 ORDER-01, ORDER-01-R1.

**완료 조건**
- `specs/v0.5/`에 `INTENT.md`·`DECISIONS.md`·`SPEC.md`·`PLAN.md`·`HERDR-SETUP.md`·`PROGRESS.md`가 있다.
- `AGENTS.md`의 레포 규칙과 에이전트 공통 지침이 v0.5 구성(leader·writer·coder·checker)에 맞다.
- 워크스페이스 `workbench-gpui`에 `gpui-writer`·`gpui-coder`·`gpui-checker`가 떠 있고, 탭이 control·docs·impl·check다.
- checker가 위 문서를 ORDER-01 3.4 기준으로 검토했고, 남은 지적이 보고 파일에 있다.
- `specs/v0.5/reports/ORDER-01.md`가 있다.

---

## Phase 2 — 창

**목적** — 앱이 1440×852로 작업 영역 가운데에 열리게 해서 뒤 Phase의 Zed 비교 조건을 맞춘다.

**대응** — R-6. ORDER-02.

**완료 조건**
- R-6의 판정 방법을 충족한다.

---

## Phase 3 — 편집 영역과 글꼴

**목적** — 글꼴을 Zed와 같게 하고, 편집 영역의 경계, 줄바꿈, 스크롤바, 현재 줄 강조를 Zed와 같게 한다.

**대응** — R-7·R-8·R-9·R-13·R-14, core D-10. ORDER-03.

**완료 조건**
- R-14를 먼저 끝낸다. core D-10의 글꼴 파일과 라이선스 파일이 커밋되어 있고, 글꼴 버전이 문서에 있다.
- R-7, R-8, R-9, R-13, R-14의 판정 방법을 충족한다.
- R-9의 Zed 스크롤바 조건과 R-14의 한글 대체 글꼴 이름을 확인해 SPEC에 더했다.

---

## Phase 4 — 글자 표시

**목적** — 경로의 역슬래시가 `₩`가 아닌 `\`로 보이게 한다.

**대응** — R-20. ORDER-04.

**완료 조건**
- R-20의 판정 방법을 충족한다. Phase 3의 글꼴 변경만으로 충족되면 그 사실을 보고에 적는다.

---

## Phase 5 — 아이콘 모양

**목적** — UI 아이콘을 Zed 원본으로 바꾸고, 상태 바 왼쪽 버튼 아이콘을 Zed와 같게 한다.

**대응** — R-1·R-18, core D-9. ORDER-05.

**완료 조건**
- 이 레포 문서에 core D-9의 복사 출처 커밋, 복사 폴더 경로, 다시 채우는 방법, 복사본이 없을 때의 모습이 적혀 있다.
- 복사 폴더가 `.gitignore`에 걸려 있다.
- R-1, R-18의 판정 방법을 충족한다.

---

## Phase 6 — 타이틀 바 메뉴

**목적** — "v" 메뉴를 만들어 동작하게 하고, `≡` 메뉴를 Zed 순서로 두 갈래 같게 맞춘다.

**대응** — R-2·R-17, core D-12. ORDER-06.

**완료 조건**
- R-2의 Settings·Keymap·Extensions·Panel Layout이 Zed에서 여는 화면을 확인해 SPEC에 더했다.
- R-2, R-17의 판정 방법을 충족한다.
- R-2의 Themes·Icon Themes가 Phase 7에서 선택 화면이 생길 때까지 무엇을 하는지 보고에 적는다.

---

## Phase 7 — 테마·아이콘 테마 추가와 선택

**목적** — Zed의 테마와 아이콘 테마를 이 레포에서 골라 쓸 수 있게 한다.

**대응** — R-3·R-4, core D-8. ORDER-07.

**완료 조건**
- 이 레포 문서에 core D-8의 복사 대상, 출처, 복사 폴더 경로, 다시 채우는 방법이 적혀 있다.
- 복사 폴더가 `.gitignore`에 걸려 있다.
- R-3, R-4의 판정 방법을 충족한다.
- R-2의 Themes·Icon Themes 메뉴가 이 선택 화면을 연다.

---

## Phase 8 — 상태 바

**목적** — 상태 바에 위치와 파일 형식을 보이고, 왼쪽 버튼의 구성과 켜짐 표시를 Zed와 같게 한다.

**대응** — R-5·R-19·R-22, core D-12. ORDER-08.

**완료 조건**
- R-5, R-19, R-22의 판정 방법을 충족한다.
- 진단(I-22)처럼 지금 기능이 없어 구현 범위가 큰 것은 빼지 않는다. 구현이 막히면 그때 `[BLOCKED]`로 이유를 남긴다(core D-12, ORDER-01-R1).
- 열린 탭이 없을 때의 Zed 상태 바 표시(R-5)를 보고에 적고 SPEC에 더했다.

---

## Phase 9 — 탭 바와 편집 영역 상단

**목적** — 뒤로·앞으로 버튼, 탭 툴팁, 탭 넘침, 탭 바 오른쪽 버튼, 경로 줄을 Zed와 같게 한다.

**대응** — R-10·R-11·R-12·R-16·R-23. ORDER-09.

**완료 조건**
- R-10, R-11, R-12, R-16, R-23의 판정 방법을 충족한다.
- 코드 파일에서 Zed 경로 줄이 보이는 내용(R-12), Zed의 탭 넘침 처리(R-16), Zed의 탭 바 오른쪽 버튼이 보이는 조건(R-23)을 보고에 적고 SPEC에 더했다.

---

## Phase 10 — 폴더 보기 패널

**목적** — 폴더 보기 패널의 폭, 간격, 선택 표시를 Zed 사이드바와 같게 한다. 내용과 동작은 이 레포의 폴더 관리 기준을 따른다.

**대응** — R-21. ORDER-10.

**완료 조건**
- R-21의 판정 방법을 충족한다.

---

## Phase 11 — 구문 강조

**목적** — Zed가 지원하는 파일 형식 전체에 구문 강조를 한다.

**대응** — R-15. ORDER-11.

**완료 조건**
- 보고에 Zed가 지원하는 파일 형식 목록과 형식별 결과 표가 있다.
- R-15의 판정 방법을 충족한다.

---

## Phase 12 — 사용자 일괄 확인

**목적** — 측정으로 판단할 수 없는 시각 품질(V4)을 사용자가 이 레포 화면에서 Zed와 나란히 보고 확인한다.

**대응** — 판정 방법에 V4가 있는 R-14·R-15와, 사용자가 다시 보기를 원하는 요구. ORDER-12.

**완료 조건**
- 사용자의 항목별 판단이 PROGRESS에 남아 있다.
- 사용자가 고칠 것으로 지적한 것은 core ITEMS 새 항목으로 넘어갔거나, 다음 버전으로 넘긴다는 판단이 PROGRESS "버전 종료"에 있다.

---

## 진행 현황

| Phase | 상태 | 시작일 | 완료일 | 커밋 | 비고 |
|---|---|---|---|---|---|
| Phase 1 | done | 2026-11-06 | 2026-11-06 | `d707513` | 충족(R3 기준 2는 사용자 조치 대기, 대체 방식 적용) |
| Phase 2 | done | 2026-11-06 | 2026-11-07 | `dad12f0` | 충족(core-leader 2026-11-07, 사용자 위임 D-13: 두 갈래 클라이언트 원점 (240,90), 1440×852, 최소 360×240). ORDER-02 기준 1 미충족(클라이언트 세로 −4px) → ORDER-02-R1: K-02·K-02-R1 보정, C-06 리뷰 PASS, C-07 V3 재실측 4/4 PASS(클라이언트 중심 차이 0/0). push 완료(origin master `dad12f0`) |
| Phase 3 | review | 2026-11-07 | - | - | core-leader 판정 대기. V3 통과 18/19, 측정 불가 1(5자리 줄 번호 열, 문서 로드 전 캡처), 불일치 0(`verify/reviews/measure-ORDER-03.md`) |
| Phase 4 | todo | - | - | - | - |
| Phase 5 | todo | - | - | - | - |
| Phase 6 | todo | - | - | - | - |
| Phase 7 | todo | - | - | - | - |
| Phase 8 | todo | - | - | - | - |
| Phase 9 | todo | - | - | - | - |
| Phase 10 | todo | - | - | - | - |
| Phase 11 | todo | - | - | - | - |
| Phase 12 | todo | - | - | - | - |

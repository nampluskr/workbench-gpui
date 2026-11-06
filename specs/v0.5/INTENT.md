> 버전: v0.5 · 작성일: 2026-11-06 · 상태: 초안 (core-leader 판정 뒤 사용자 확정)
>
> 이번 버전의 목적과 범위를 담는다. 결정은 `DECISIONS.md`에, 요구와 판정 방법은 `SPEC.md`에, Phase 순서는 `PLAN.md`에, 에이전트 구성은 `HERDR-SETUP.md`에, 실제 진행은 `PROGRESS.md`에 있다. 변하지 않는 의도는 루트 `INTENT.md`에 있다.

# INTENT — workbench-gpui v0.5

## 목적·범위·기대 결과

- 목적: 사용자가 두 갈래 UI를 직접 테스트하고 Zed와 비교해 요청한 항목 I-1~I-23(workbench-core `specs/v0.5/ITEMS.md`)을 workbench-gpui에 반영한다.
- 범위
  - core-leader가 보내는 지시 카드 `ORDER-01`~`ORDER-12`(`D:\projects\workbench-core\specs\v0.5\orders\`)를 이 레포에서 진행한다(core DECISIONS D-3).
  - core ITEMS의 I-1~I-23을 이 레포의 요구로 옮기고(`SPEC.md`), core PLAN Phase 1~12에 대응하는 Phase로 진행한다(`PLAN.md`).
  - 워크스페이스 `workbench-gpui`의 herdr 에이전트를 core D-2 구성(leader·writer·coder·checker)으로 바꾼다(`HERDR-SETUP.md`).
  - 화면을 다루는 확인은 core-leader에게 차례를 받아서 한다(core D-1·D-4).
- 기대 결과
  - `specs/v0.5/`에 INTENT·DECISIONS·SPEC·PLAN·HERDR-SETUP·PROGRESS가 있다(ORDER-01 3.1).
  - I-1~I-23이 모두 이 레포에 반영되었거나, 반영하지 못한 항목과 이유가 PROGRESS와 ORDER 보고 파일에 남아 있다(core 루트 INTENT 원칙, core PLAN "넘어가는 조건").
  - Phase마다 결과가 `specs/v0.5/reports/ORDER-<n>.md`에 있고, core-leader가 판정했다.
  - Phase 12에서 사용자가 workbench-gpui 화면을 Zed와 나란히 보고 항목별로 판단했다.

## 배경

- 사용자가 2026-11-06에 두 갈래 UI를 테스트하고 Zed와 나란히 비교해 항목 I-1~I-23을 요청했다. core-leader가 이것을 그룹 G-1~G-10으로 묶었고, ITEMS가 SPEC 역할을 한다(core D-11).
- workbench-gpui v0.4는 2026-11-05에 끝났다(태그 `v0.4`, `specs/v0.4/PROGRESS.md` "버전 종료"). 그래서 ORDER-01 3.0(v0.4 종료)은 이 레포에서 하지 않는다.
- 세 레포(workbench-core, workbench-gpui, workbench-tauri)가 같은 버전 번호로 움직이도록 이번 버전을 v0.5로 한다(core INTENT 배경, ORDER-01 2장).
- 이 버전부터 에이전트 구성이 v0.4의 여섯 서브 에이전트(`spec`·`reviewer`·`review`·`measure`·`impl-ui`·`impl-editor`)에서 writer·coder·checker 셋으로 바뀐다(core D-2).
- 근거 문서: `D:\projects\workbench-core\specs\v0.5\INTENT.md`, `D:\projects\workbench-core\specs\v0.5\orders\ORDER-01.md`.

## 제외 범위

- core ITEMS에 없는 기능의 추가. 사용자가 테스트하고 요청한 항목만 한다(core INTENT 제외 범위).
- workbench-core와 workbench-tauri 레포의 파일을 쓰는 것. 읽기만 한다(core D-7).
- 지난 버전 폴더(`specs/v0.1/`~`specs/v0.4/`), `docs/HERDR-*.md`, `docs/refs/`를 고치는 것.
- Zed 앱 코드의 복사(레포 규칙 "Zed 코드 복사 금지"). Zed 테마·아이콘을 `.gitignore` 폴더에 복사해 쓰는 것(core D-8·D-9)과 글꼴 파일을 커밋하는 것(core D-10)은 이 제외에 들지 않는다.
- 루트 `INTENT.md` "다루지 않는 것"과 core ITEMS가 부딪치는 부분은 미정이다(사용자 확인). 루트 INTENT는 "프로젝트 전체 검색, 설정 UI 화면", "온라인 확장 목록"을 다루지 않는다고 적었는데, I-2는 "v" 메뉴의 Settings·Extensions가 Zed와 같은 화면을 열기를, I-22는 상태 바에 Zed와 같은 검색·진단 버튼과 그 화면을 요구한다. 루트 INTENT "쓰지 않는 기능의 아이콘·메뉴·옵션은 넣지 않는다"와 I-22 진단 버튼(언어 서버 없음)도 같다.

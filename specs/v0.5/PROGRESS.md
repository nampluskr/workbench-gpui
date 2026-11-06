> 버전: v0.5 · 작성일: 2026-11-06 · 상태: 초안 (진행 중)
>
> workbench-gpui v0.5에서 실제로 한 일과 검증 결과를 적는다. 계획은 `PLAN.md`에, 요구는 `SPEC.md`에, 결정은 `DECISIONS.md`에 있다. core-leader에게 보내는 보고는 `specs/v0.5/reports/ORDER-<n>.md`에 있다.

# PROGRESS — workbench-gpui v0.5

## Phase별 진행

### Phase 1 — 갈래 준비

- **W-01 v0.5 문서 초안과 AGENTS.md 역할 절** (2026-11-06)
  - 무엇을 했나: ORDER-01 3.1·3.2·3.3을 이 레포에 반영했다. `specs/v0.5/`에 INTENT·DECISIONS·SPEC·PLAN·HERDR-SETUP·PROGRESS 초안을 쓰고, `AGENTS.md`의 레포 규칙과 에이전트 공통 지침을 v0.5 구성(leader·writer·coder·checker)으로 고쳤다. 카드 `specs/v0.5/cards/W-01.md`.
  - 결과:
    - 새 파일: `specs/v0.5/INTENT.md`, `DECISIONS.md`, `SPEC.md`, `PLAN.md`, `HERDR-SETUP.md`, `PROGRESS.md`, `cards/W-01.report.md`.
    - SPEC은 core ITEMS I-1~I-23을 R-1~R-23으로 옮겼다(같은 번호).
    - PLAN은 core Phase 1~12와 같은 번호의 Phase, ORDER 번호, I-n 대응 표를 두었다.
    - `AGENTS.md`: "HERDR 문서" 규칙 문장 교체, core D-7 규칙 한 줄 추가, 0·1·2·3A·6·7·8·9장의 역할 이름과 경로를 v0.5에 맞춤.
  - 검증: 문서만 바꿨다(V0, 빌드·테스트·앱 실행 없음). ITEMS의 판정 방법 23개가 SPEC에 글자 그대로 있는지 스크립트로 대조했다(23/23). PLAN 대응 표에 I-1~I-23이 모두 있는지 눈으로 대조했다. 저장 뒤 다시 읽어 한글이 깨지지 않았는지 확인했다.
  - 특이사항: 루트 `INTENT.md` "다루지 않는 것"이 I-2(Settings·Extensions 화면)·I-22(검색·진단 버튼)와 부딪친다. 혼자 맞추지 않고 미정으로 두고 보고했다(`INTENT.md` 제외 범위, `cards/W-01.report.md`). checker 검토(ORDER-01 3.4)는 아직 하지 않았다.

- **W-02 core ITEMS 우선(core D-12): 갈래 지침의 충돌 정리** (2026-11-06)
  - 무엇을 했나: ORDER-01-R1 3장 1~5를 했다. 루트 `INTENT.md`, `AGENTS.md`, `README.md`에서 core ITEMS I-1~I-23과 부딪치는 문장을 찾아, 문장을 지우지 않고 "단, core v0.5 ITEMS I-n은 예외(core D-12)"를 붙였다(leader 결정 방식). 카드 `specs/v0.5/cards/W-02.md`.
  - 결과:
    - 루트 `INTENT.md` 4곳: "Zed와 같아야 한다"(I-6·I-17·I-21), "쓰지 않는 기능의 아이콘·메뉴·옵션은 넣지 않는다"(I-2·I-22), "프로젝트 전체 검색, 설정 UI 화면, …"(I-2·I-22), "화면을 추가하는 확장, 온라인 확장 목록"(I-2).
    - `AGENTS.md`: 레포 규칙에 "core ITEMS 우선" 한 줄 추가. 1장 "Zed 실측값은 요구사항이다"(I-6), 3장 "수치의 기준은 이 toml 하나다"(I-6·I-14), 3장 "스펙에 없는 값은 spec에게 요청"(Zed 확인을 맡긴 I-n)에 예외 표시.
    - `README.md`: 부딪치는 문장 없음, 고치지 않음.
    - `specs/v0.5/`: INTENT 제외 범위의 "미정" 줄을 D-12 예외로 바꾸고 배경에 D-12를 더함, DECISIONS 적용 표에 D-12 추가·미결 사항의 충돌 줄 삭제, SPEC R-2·R-22의 "미정"을 D-12 우선으로 바꿈(R-22에 막히면 Phase 8 `[BLOCKED]`), PLAN 대응 표·Phase 1·6·8에 D-12와 Phase 8 문장 추가.
    - 지운 문장: 없음.
  - 검증: 문서만 바꿨다(V0). `specs/v0.5/`의 INTENT·DECISIONS·SPEC·PLAN에서 충돌 관련 "미정"이 남지 않았는지 grep으로 확인했다. 레포 규칙 "사람이 정하고 묻는다"·"지난 버전 폴더 불변"·"Zed 코드 복사 금지"는 바꾸지 않았다(git diff 확인).
  - 특이사항: 부딪치지 않는다고 본 경계 사례는 `cards/W-02.report.md`에 있다. checker 검토(ORDER-01-R1 3장 6)는 아직 하지 않았다.

## 사용자 요청 작업

없음.

## 버전 종료

- 사용자 종료 판단: 진행 중.
- 남은 것: 진행 중.

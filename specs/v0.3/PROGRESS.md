> 버전: v0.3 · 작성일: 2026-11-03 · 상태: 진행 중
>
> v0.3에서 실제로 한 일과 검증 결과를 기록한다. 계획은 `PLAN.md`, 결정은 `DECISIONS.md`, 요구는 `SPEC.md`, 에이전트 운영은 `HERDR-SETUP.md`에 있다.

# PROGRESS — workbench-gpui v0.3

## Phase별 진행

### Phase 0 — 기준선: 데스크톱 환경·현재 상태 고정·감사·스펙 파일화

아직 시작하지 않았다. v0.3 문서 확정 뒤 `lead`가 카드를 쓰고 시작한다.

## 사용자 요청 작업

### docs\temp 이름 바꾸기·이동 (2026-11-03)

- 요청: "docs\temp -> 폴더명 변경 제안 / 또는 다른 폴더로 이동 검토"
- 조치
  - `docs/temp`를 `docs/refs/refactor-draft/`로 옮겼다.
  - 하위 폴더에서 자동으로 읽히지 않도록 안의 `AGENTS.md`·`CLAUDE.md`를 `AGENTS.draft.md`·`CLAUDE.draft.md`로 이름을 바꿨다.
- 결과: 초안 다섯 개(PLAN·FINALIZE·HERDR·AGENTS.draft·CLAUDE.draft)가 `docs/refs/refactor-draft/`에 있다. 그 뒤 사용자가 `HERDR-SETUP.md`를 더했다.
- 검증: `ls docs docs/refs docs/refs/refactor-draft`로 `docs/temp`가 없어지고 파일이 옮겨진 것을 확인했다.
- 상태: 완료

### specs\v0.3 폴더 만들기 (2026-11-03)

- 요청: "specs\v0.3 폴더 생성 필요"
- 조치: `specs/v0.3/`를 만들었다.
- 결과: 폴더가 있다. 지난 버전 폴더는 건드리지 않았다.
- 검증: `ls specs`
- 상태: 완료

### HERDR 구성 규칙을 지침에 넣기 (2026-11-03)

- 요청: "구독현황 및 토큰 부담에 따라 HERDR 멀티에이젼트를 정해야 함을 지침문서에 반영해 주세요."
- 조치: 루트 `AGENTS.md`에 "HERDR 구성은 구독·토큰 부담으로 정한다" 규칙을 더했다.
- 결과: 규칙 한 줄이 생겼다(뒤의 요청에서 레포 규칙 절로 유지).
- 검증: 파일을 다시 읽어 확인했다.
- 상태: 완료

### v0.3 INTENT·DECISIONS·SPEC·PLAN 초안 (2026-11-03)

- 요청: "v0.3 INTENT 초안 작성해 주세요", "DECISIONS 초안 작성해 주세요", "refactor-draft 기반으로 specs\v0.3 스펙 문서 작업을 계속 진행하겠습니다."
- 조치: project-workflow-compact 템플릿으로 네 문서를 썼다. 데스크톱 환경 점검(Phase 0)과 노트북과 같은 빌드 환경(D-5)을 반영했다.
- 결과: `specs/v0.3/INTENT.md`, `DECISIONS.md`, `SPEC.md`, `PLAN.md`(상태: 초안)
- 검증: `grep '^## '`로 절 구성을 확인했다. SPEC의 R-n이 모두 PLAN Phase에 대응되는지 대조했다.
- 상태: 다음 요청으로 다시 고침

### refactor-draft를 v0.3 기준으로 반영 (2026-11-03)

- 요청: "workbench-gpui\docs\refs\refactor-draft 의 문서의 내용이 현재 데스크탑 및 워크스페이스 에 맞게 모두 반영되어야 합니다. … 참고가 아니라 이 문서를 기준으로 v0.3 이 이루어져야 합니다. 1. 데이크탑 환경 적용 2. 멀티에이젼트시 토큰 부담 고려 3. 자료나 파일등 경로 맞게 수정 반영"
  - 이어진 지시: HERDR 문서는 `specs/{version}/`에 버전별로 둔다. Python은 `C:\winpython\`의 `_cpu`·`_gpu`를 쓴다.
  - 사용자 선택
    - 에이전트 구성: "HERDR.md + 부담 조정"
    - 측정 도구: "PowerShell 재사용"
    - P4~P6: "v0.4 이후 유지"
- 조치
  - 새로 쓴 문서: `specs/v0.3/HERDR-SETUP.md`, `specs/v0.3/HERDR-DECISIONS.md`, 이 PROGRESS
  - 다시 쓰거나 고친 문서: 루트 `AGENTS.md`, `specs/v0.3/PLAN.md`, `SPEC.md`(R-13~R-15 추가), `DECISIONS.md`(D-2 다시 씀, D-10~D-12 추가), `INTENT.md`, `README.md`
  - 고치지 않은 것: `docs/refs/refactor-draft/`, `specs/v0.1·v0.2/`, `docs/HERDR-*.md`
- 결과: 초안 절마다 반영 위치는 아래와 같다.

  | 초안 | 절 | 반영 위치 |
  | --- | --- | --- |
  | HERDR.md | 1 에이전트 구성, 1.1 모델 운용, 1.2 리뷰 독립성 | HERDR-SETUP 1장(impl-editor 필요할 때만, reviewer 대체 모델 추가, 1.3 토큰 부담 신설), D-10 |
  | HERDR.md | 2 레이아웃 | HERDR-SETUP 2장(`zed-main` → 기존 `workbench-gpui`, `wt-editor` 필요할 때만) |
  | HERDR.md | 3 초기 설정 3.1~3.7 | HERDR-SETUP 3.1~3.7(설치 현황 반영, Rust·Build Tools 2022·WinPython), 3.8 화면·실측 조건 신설 |
  | HERDR.md | 4 소유권 | HERDR-SETUP 4장(경로 치환, `specs/v0.3/` 아래), D-11 |
  | HERDR.md | 5 작업 프로토콜 | HERDR-SETUP 5장(카드에 요구·결정 칸 추가, 묶음 리뷰) |
  | HERDR.md | 6 공통 규칙 | HERDR-SETUP 6장(6.5 대리 응답 범위는 HERDR-SETUP 변경안 7절에서) |
  | HERDR.md | 7 최초 지시 프롬프트 | HERDR-SETUP 7장(경로 치환, impl-editor는 필요할 때) |
  | HERDR.md | 8 단계 계획 | HERDR-SETUP 8장, PLAN |
  | HERDR-SETUP.md (변경안) | 1 근거, 6 토큰 부담, 7 대리 응답, 4 운영 규칙(auditor·checker) | HERDR-SETUP 0장·1.3·6.5. 감사는 reviewer가 하고(D-3), 기준선은 P0-0c, 허용 범위는 미결 |
  | AGENTS.draft.md | 0~9장 전체 | 루트 `AGENTS.md` "에이전트 공통 지침"(경로·`master`·`shortcut:`·WinPython 반영) |
  | PLAN.md | 1 요약, 2.1~2.3 운영 규칙 | PLAN "읽는 법" 절 |
  | PLAN.md | 3 P0~P3 | PLAN Phase 0~3 카드표 |
  | PLAN.md | 3 P4~P6 | PLAN "v0.4 이후" 절 |
  | PLAN.md | 4 진행 현황 | PLAN "진행 현황" 표 |
  | FINALIZE.md | 1 원칙 | AGENTS 3장(수치 기준 하나, 원문은 INDEX로), PLAN Phase 0 완료 조건(src 변경 없음) |
  | FINALIZE.md | 2 입력 문서·읽기 규칙 | PLAN F0 카드, AGENTS 0·3·9장 |
  | FINALIZE.md | 3 산출물·소유권, 3.1 toml 형식 | PLAN Phase 0 산출물, HERDR-SETUP 4장, D-6, SPEC R-5 |
  | FINALIZE.md | 4 F0~F5 | PLAN Phase 0 F0~F5 카드, SPEC R-5·R-6·R-13 |
  | FINALIZE.md | 5 최초 지시 프롬프트 | HERDR-SETUP 7.1·7.2·7.3에 합침 |
  | FINALIZE.md | 6 확정 후 반영 목록 | 이번 반영. 6.4 보관 처리는 하지 않음(D-2) |
  | FINALIZE.md | 7 진행 현황 | PLAN 진행 현황(Phase 0 안의 F 카드는 TASKS.md에서 관리) |

- 검증
  - 반영 문서에서 자리표시자(`<REPO_ROOT>`·`<ZED_MEASURE_DIR>` 등), 옛 경로(`docs/agents`, 루트 `HERDR.md`), `main` 브랜치, `ponytail:` 주석 형식을 grep으로 찾았다. 출처 인용을 빼면 0건이다.
  - `grep '^## '`로 절 구성을 확인했다. SPEC R-1~R-15가 모두 PLAN Phase에 대응된다.
  - `git status`로 지난 버전 폴더, `refactor-draft/`, `docs/HERDR-*.md`에 변경이 없음을 확인했다.
- 상태: 완료(문서 상태는 "초안, 사용자 확인 대기")

### Phase 0 시작 전 결정 반영과 v0.3 문서 확정 (2026-11-03)

- 요청: "v0.3 에 대한 필요한 스펙 문서 작업이 모두 끝났나요?"에 이어, Phase 0 시작 전에 정할 네 가지를 질문받고 답했다.
  - MSVC: "2022 최신 + 2026 삭제"
  - P0-0c 기준선: "reviewer 전부"
  - agy 한도: "둘 다 충분"
  - 문서: "반영 후 확정"
- 조치
  - D-5: Build Tools 2022 최신 설치와 2026 삭제를 넣고, 배제한 대안 두 개를 더했다.
  - D-10 근거에 agy 한도와 P0-0c 담당을 넣었다.
  - DECISIONS 미결 사항에서 정해진 네 줄을 지웠다: 2022 세부 버전, 2026과의 공존 방법, P0-0c 담당, agy 남은 한도.
  - SPEC R-1: 2026 삭제와 버전 기록을 판정 기준에 넣고 "미정"을 지웠다.
  - PLAN P0-0a·P0-0c 카드와 HERDR-SETUP 0장·3.7·변경 이력을 고쳤다.
  - INTENT·DECISIONS·SPEC·PLAN·HERDR-SETUP의 상태를 "확정 (2026-11-03)"으로 바꿨다.
- 결과: v0.3 문서가 확정되었다. 남은 미결은 Phase 0 안이나 이후에 정하도록 짜여 있다.
  - Phase 0 안에서: 담당 경로(P0-5), 모호·충돌 항목(F5), 허용 범위
  - 감사 뒤: 채택 범위, 동작 변경 수정
  - Phase 1·2 전: toml 크레이트, 스펙에 없는 수치
- 검증: 다섯 문서의 상태 줄을 grep으로 확인했다. 파일을 다시 읽어 한글이 깨지지 않았음을 확인했다.
- 상태: 완료

### .serena를 .gitignore에 추가 (2026-11-03)

- 요청: ".serena 는 .gitignore 에 추가해 주세요"
- 조치: `.gitignore`에 `.serena/` 한 줄을 더했다.
- 결과: `git status`에 `.serena/`가 더 나오지 않는다.
- 검증: `git status --short`의 결과가 ` M .gitignore`뿐이다.
- 상태: 완료(커밋 전)

## 버전 종료

- 사용자 종료 판단: 진행 중.
- 남은 것: 진행 중.

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

- **W-03 HERDR-SETUP: 승인 위임, 구독 현황, worktree 정리 반영** (2026-11-06)
  - 무엇을 했나: ORDER-01-R2 A·B와 C의 사실을 `HERDR-SETUP.md`·`DECISIONS.md`에 반영하고, leader가 정한 미정 네 가지(카드 ID 접두사, leader effort, 최초 프롬프트 기록, PLAN 진행 현황 갱신자)를 채웠다. 카드 `specs/v0.5/cards/W-03.md`.
  - 결과:
    - `HERDR-SETUP.md`: 0장 근거에 ORDER-01-R2·core D-13 추가. 2장 worktree 줄을 "leader가 지웠다"로, 2.1 leader effort high. 3장 구독 현황을 core D-2 "여유"로 적고 수치 미정 줄과 표의 "부담 미정"을 정리("한도가 바뀌어 구성을 바꾸면 다시 승인받는다"는 그대로). 4장 PLAN 진행 현황 표는 writer 갱신·leader 확인. 5.3 카드 ID 접두사 `W-`·`C-`·`K-`. 5.6 승인 처리 절 새로 둠(위임, 예외 셋은 core-leader에게 묻기, 기록은 PROGRESS, 미리 허용 목록은 R3에서 채움). 6장 최초 프롬프트 기록. 7장 worktree 정리 사실.
    - `DECISIONS.md`: D-2를 "쓰지 않고 지운다"로 고치고 근거에 ORDER-01-R2 C와 확인 결과를 더함. 미결 사항에서 대리 응답 위임·worktree 삭제 줄을 지움.
    - `spec/` 소유와 AGENTS 3장 `spec` 역할 문장은 고치지 않았다(ORDER-01-R2 D, 승인 전).
  - 검증: 문서만 바꿨다(V0). `git worktree list` → 본 트리 하나, `git branch` → `master`, `work/p3fix`(work/editor·work/ui 없음). HERDR-SETUP·DECISIONS의 "미정"을 grep으로 다시 보아 남은 것은 `spec/`·복사 폴더 경로·그 밖의 `tools/` 소유뿐임을 확인했다.
  - 특이사항: 로컬 브랜치 `work/p3fix`가 남아 있다. 카드·ORDER-01-R2에 언급이 없어 문서에 적지 않고 보고했다.

- **W-04 checker(agy) 명령 미리 허용 설정** (2026-11-06)
  - 무엇을 했나: core ORDER-01-R3에 따라 checker가 맡은 일의 명령을 승인 없이 돌게 하는 설정 파일을 레포에 만들고, `HERDR-SETUP.md`에 위치·허용 목록·대체 방식을 적었다. 카드 `specs/v0.5/cards/W-04.md`.
  - 결과:
    - 새 파일 `.agents/checker-settings.json`: allow만(32개), deny 없음. git 읽기 4, cargo build·test·clippy, `apply-manifest.ps1`, `tools/`의 `capture.ps1`·`verify-*.ps1` 18개, `tools/measure/` 6개. `set-scale.ps1`은 넣지 않음.
    - `HERDR-SETUP.md`: 2.1 checker 실행 명령에 `--settings D:\projects\workbench-gpui\.agents\checker-settings.json`, 5.6 "미리 허용 목록"을 채움(위치, 형식, 허용 목록, 넣지 않은 것, deny를 두지 않는 이유, 화면 차례, 대체 방식).
  - 검증: 문서·설정 파일만 바꿨다(V0). 허용 목록에 금지 명령(`git commit` 등, `cargo add` 등, 삭제, 내려받기, python)이 없음을 눈으로 대조했다. `tools/`·`tools/measure/`의 실제 파일 이름과 목록을 `ls`로 대조했다. 파일 쓰기는 자동 모드에 거부되지 않았다. 허용이 실제로 동작하는지(checker `git diff --stat`)는 이 카드 범위 밖이라 하지 않았다.
  - 특이사항: `verify-scale.ps1`은 배율을 바꾸지 않고 현재 배율을 확인만 한다(스크립트 머리말). 그래서 카드대로 허용 목록에 넣었다.

- **W-05 spec/ 소유 안 반영** (2026-11-06)
  - 무엇을 했나: core-leader가 승인한 `specs/v0.5/reports/ORDER-01-R2.md` "D. spec/ 소유 안"을 그대로 반영했다(core-leader 사용자 위임 2026-11-06, core D-13, ORDER-01-R2 D). 카드 `specs/v0.5/cards/W-05.md`.
  - 결과:
    - `AGENTS.md`: 3장 세 문장(원문 통째로 읽기, v0.5 값 맞춤 카드 범위, 스펙에 없는 값 요청 경로)을 안의 표대로 고침(core D-12 예외 문구는 그대로). 4장 첫 문장의 `spec` 역할 예외를 지움. 6장 writer에 `spec/` 소유, coder는 `spec/` 읽기만. 7.2 writer에 `spec/` 기록 규칙(ID 불변, 출처·조건, 모호 값은 `ambiguous.md`), 7.3 coder 읽기만, 7.4 checker Zed 값 확인.
    - `spec/INDEX.md` 머리말 소유 줄만 고침. 그 밖의 `spec/` 내용은 그대로.
    - `HERDR-SETUP.md` 4장 `spec/` 행의 "미정(leader)"을 `gpui-writer`로. `DECISIONS.md`에 갈래 결정 D-3을 두고 미결 사항의 `spec/` 소유 줄을 지움.
  - 검증: 문서만 바꿨다(V0). AGENTS.md에 `` `spec` 담당``·``spec`에게``·"`spec` 역할" 문구가 남지 않았는지 grep으로 확인했다.
  - 특이사항: 없음.

- **W-06 R3 시험 결과를 HERDR-SETUP에 반영** (2026-11-06)
  - 무엇을 했나: core ORDER-01-R3의 leader 시험 결과를 `HERDR-SETUP.md` 2.1·4장·5.6에 적었다. 카드 `specs/v0.5/cards/W-06.md`.
  - 결과:
    - 시험 결과(leader 2026-11-06): checker를 `--settings D:\projects\workbench-gpui\.agents\checker-settings.json`으로 다시 띄우려 하자 leader 세션 자동 모드가 `[Self-Modification]`으로 거부했다. 우회하지 않았다. 지금 gpui-checker(wD:pF)는 `--settings` 없이 떠 있어 미리 허용이 적용되지 않았다.
    - 대체 방식 시험(출처 C-03): leader가 `git diff --stat` 출력을 `C:\Users\nampl\AppData\Local\Temp\v05-C-03-git-diff-stat.txt`로 남기고, checker가 그 파일을 승인 창 없이 읽어 바뀐 파일 3개를 맞게 보고했다.
    - `HERDR-SETUP.md`: 2.1에 checker "적용 목표" 명령과 "현재 실행 명령"(`--settings` 없음)을 함께 두고 재실행은 사용자 또는 사용자가 허락한 세션이 한다고 적음. 5.6에 현재 상태, 대체 방식이 기본이라는 것, C-03 시험 결과를 더함. 4장에 `.agents/checker-settings.json` 행(소유 leader, 고칠 때 core-leader 승인).
  - 검증: 문서만 바꿨다(V0). 시험 결과는 카드에 적힌 leader 기록을 옮겼고 writer가 다시 시험하지 않았다.
  - 특이사항: 없음.

- **Phase 1 종료 판정** (2026-11-06)
  - 무엇을 했나: core-leader가 ORDER-01과 R1·R2·R3 보고를 보고 Phase 1을 판정했다(core-leader 2026-11-06, 사용자 위임 core D-13).
  - 결과: 충족. ORDER-01-R3 완료 기준 2(checker `--settings` 적용)는 사용자 조치 대기이고, 그동안 대체 방식(`HERDR-SETUP.md` 5.6)을 적용한다. Phase 1 마지막 커밋 `d707513`.
  - 검증: core-leader 판정(gpui-leader 전달, W-07).
  - 특이사항: checker를 `--settings`로 다시 띄우는 일이 남았다(사용자 또는 사용자가 허락한 세션).

- **W-07 v0.5 문서 확정 표시, Phase 1 종료 기록** (2026-11-06)
  - 무엇을 했나: `specs/v0.5/`의 INTENT·DECISIONS·SPEC·PLAN·HERDR-SETUP 인용 블록 상태를 "확정 (core-leader 판정, 사용자 위임 2026-11-06)"으로 바꾸고, PLAN 진행 현황 표의 Phase 1을 done(커밋 `d707513`)으로 했다. 카드 `specs/v0.5/cards/W-07.md`.
  - 결과: 다섯 문서 상태 줄만 바뀜. PROGRESS 상태 줄은 그대로. PLAN Phase 1 행: done, 2026-11-06~2026-11-06, `d707513`, "충족(R3 기준 2는 사용자 조치 대기, 대체 방식 적용)".
  - 검증: 다섯 문서에 확정 상태 줄이 하나씩 있음을 grep으로 확인(각 1건). `git log -1 d707513`이 Phase 1 커밋(ORDER-01-R2·R3)임을 확인.
  - 특이사항: 없음.

- **W-08 R3 재시험 결과 기록** (2026-11-06)
  - 무엇을 했나: core ORDER-01-R3 재시험 결과를 `HERDR-SETUP.md` 2.1·5.6에 적었다. 카드 `specs/v0.5/cards/W-08.md`.
  - 결과:
    - 재시험(leader 2026-11-06): 사용자 승인("checker가 승인 창 없이 명령을 실행하게 하는 설정하도록 승인합니다", core-leader 전달)으로 leader가 gpui-checker(wD:pF)를 `--settings D:\projects\workbench-gpui\.agents\checker-settings.json`으로 다시 띄웠다. 거부되지 않았다.
    - agy 로그 `C:\Users\nampl\.gemini\antigravity-cli\log\cli-20261106_231823.log`에 허용 목록이 읽혔다(`CLI settings initialized: permissions=&{Allow:[command(git diff) ... ] ...}, toolPermission=request-review`). 그런데 checker의 `git diff --stat`에 승인 창이 떴다(leader 1회 승인). 원인 미확인. 같은 로그에 `ApplyProjectPermissionGrants: no grants for project "CLI Project", cleared project permissions` 줄이 있다.
    - `HERDR-SETUP.md`: 2.1의 checker 현재 실행 명령을 `--settings` 명령 하나로 바꾸고 재실행 경위와 "허용 목록은 읽히지만 승인 창이 뜬다"를 적음. 5.6에 W-06 상태를 지난 상태로 두고 W-08 현재 상태, 대체 방식이 계속 기본, 목록에 없거나 승인 창이 뜬 명령은 leader가 위임으로 판단한다는 것을 적음.
  - 검증: 문서만 바꿨다(V0). 재시험 결과는 카드에 적힌 leader 기록을 옮겼고 writer가 다시 시험하지 않았다.
  - 특이사항: 미리 허용이 승인 창을 없애지 못한 원인이 남았다. Phase 1 종료 판정의 "checker `--settings` 재실행" 남은 일은 끝났다.

- **W-09 checker 허용 목록 동작 반영** (2026-11-06)
  - 무엇을 했나: core ORDER-01-R3 덧붙임(core-leader NOTICE)의 결과를 `HERDR-SETUP.md` 2.1·5.6에 적었다. 카드 `specs/v0.5/cards/W-09.md`.
  - 결과:
    - 사실(leader 2026-11-06): core-leader가 사용자 요청으로 `.agents/checker-settings.json` allow에 정확한 명령(`git diff --stat`, `git status --short`, `git log --oneline -5`, 빌드·clippy 변형)을 더했다(core D-7 예외, 사용자 요청). leader가 checker를 `--settings`로 다시 띄워 `git diff --stat`을 시켰더니 승인 창 없이 돌았다. 앞부분 일치가 아니라 정확한 명령 모양이 맞아야 하는 것으로 보인다. C-05 실측 중 목록 밖 명령(`Get-ChildItem`, `Get-Process`, `pwsh -NoProfile -Command ...`, `Start-Process`, `Remove-Item` 등)은 승인 창이 떴고 leader가 위임으로 판단했다.
    - `HERDR-SETUP.md`: 2.1 checker는 `--settings` 적용, 허용 목록 동작, 대체 방식 끝. 5.6 형식 줄을 정확한 명령 모양으로 고치고, 허용 목록 나열을 지우고 `.agents/checker-settings.json`을 기준으로 가리킴(더할 명령은 leader가 core-leader에게 알림). W-08 상태를 지난 상태로 두고 W-09 현재 상태를 더함. 대체 방식 시험(C-03)은 지난 방식으로 표시.
  - 검증: 문서만 바꿨다(V0). 시험 결과는 카드에 적힌 leader 기록을 옮겼고 writer가 다시 시험하지 않았다.
  - 특이사항: W-08의 "원인 미확인"은 정확한 명령 모양 일치로 설명되는 것으로 보이나 확인된 원인은 아니다(카드 표현 "보인다"를 그대로 둠).

### Phase 2 — 창

- **K-01 시작 창 1440×852, 작업 영역 가운데** (2026-11-06, coder)
  - 무엇을 했나: R-6(I-6) 구현. `src/ui/metrics.rs`에 `WINDOW_INITIAL_SIZE`(1440×852, 출처 core v0.5 ITEMS I-6)를 두고, `src/ui/mod.rs` `run`에서 주 디스플레이의 작업 영역(`visible_bounds`) 중심에 `Bounds::centered_at`으로 고정 크기 windowed bounds를 정한다. 최소 크기 360×240(`WINDOW_MIN_SIZE`)과 타이틀 바 설정은 그대로. 카드 `specs/v0.5/cards/K-01.md`.
  - 결과:
    - gpui 소스로 확인: `visible_bounds`는 Windows `rcWork`(작업 표시줄 제외) 기준, 지정한 size는 클라이언트 크기(`calculate_window_rect`가 비클라이언트 영역을 더함).
    - `Bounds::centered`는 작업 영역보다 큰 창을 줄이므로 쓰지 않았다.
    - 앱에 창 크기·위치 저장/복원 코드는 없다.
  - 검증: V1. `cargo build`, `tools/apply-manifest.ps1`, `cargo test initial_window_uses_work_area_center_and_fixed_client_size`(1 passed), `cargo clippy --all-targets -- -D warnings` 통과(`cards/K-01.report.md`).
  - 특이사항: 작업 영역이 1440×852보다 작으면 창 일부가 영역 밖으로 나갈 수 있다(고정 크기 유지 결과).

- **C-04 K-01 코드 리뷰** (2026-11-06, checker)
  - 무엇을 했나: K-01 diff와 leader가 남긴 테스트·clippy 출력을 읽어 정확성·경계 조건·범위·ponytail 규칙을 점검했다. 카드 `specs/v0.5/cards/C-04.md`.
  - 결과: PASS, 지적 없음. 클라이언트 기준·작업 영역 가운데·최소 크기·크기 미기억 모두 충족. `primary_display().expect(...)`는 AGENTS 5장 규칙에 맞음.
  - 검증: V1, 명령 실행 없이 파일로 판정(`cards/C-04.report.md`).
  - 특이사항: 없음.

- **C-05 시작 창 V3 실측** (2026-11-06, checker)
  - 무엇을 했나: AGENTS 3A.4 절차로 R-6을 실측했다. 조건: 주 모니터 1920×1080, 100%, 작업 영역 1920×1032. `tools/measure/window-rect.ps1`(Win32 `GetWindowRect`·`GetClientRect`·`ClientToScreen`·`SPI_GETWORKAREA`·`SetWindowPos`)을 새로 만들었다. 카드 `specs/v0.5/cards/C-05.md`.
  - 결과: 4/4 PASS(`verify/reviews/measure-ORDER-02.md`).
    - 첫 실행 클라이언트 1440×852.
    - 창 바깥 사각형(1456×860) 중심 (960, 516) = 작업 영역 중심, 차이 0.
    - 100×100 축소 시도 → 클라이언트 360×240.
    - 1600×900으로 바꾸고 다시 실행 → 1440×852, 작업 영역 가운데.
  - 검증: V3. 앱 데이터는 `session.ps1`로 복원(`restored=true`), 종료 뒤 `workbench-gpui` 프로세스 0건.
  - 특이사항(core-leader 판정 대상): 클라이언트 중심은 작업 영역 중심보다 위로 4px(dy −4)다. DWM 보이지 않는 테두리가 좌·우·아래에만 있어서다. 창 바깥 사각형 중심은 일치한다.

- **ORDER-02 판정 → ORDER-02-R1** (2026-11-06, core-leader)
  - 무엇을: core-leader가 ORDER-02를 판정했다(사용자 위임, core D-13). 재지시 `D:\projects\workbench-core\specs\v0.5\orders\ORDER-02-R1.md`.
  - 결과:
    - 기준 1 미충족: 클라이언트 중심이 세로 −4px. 기준 2·3·4 충족.
    - 결정: I-6 판정 방법 그대로 **클라이언트 영역** 중심이 작업 영역 중심과 같아야 한다. 정수 반올림 1px까지 허용. 보이지 않는 테두리 크기는 하드코딩하지 않고 실행 중 실제 값을 쓴다.
  - 검증: 해당 없음(판정).

- **K-02 클라이언트 영역을 작업 영역 정가운데로** (2026-11-06, coder)
  - 무엇을: 세로 −4px 원인을 gpui 소스로 찾아 시작 bounds를 보정했다. 카드 `specs/v0.5/cards/K-02.md`.
  - 결과:
    - 원인(`gpui-pre-windows-0.3.10`): `src/events.rs` `handle_calc_client_size`가 숨긴 타이틀 바 창의 위 테두리를 0으로 되돌리는데, `src/window.rs` `calculate_window_rect`는 높이 차이(아래 테두리 8px)를 위아래로 반씩 나눈다. 그래서 클라이언트가 위로 4px 치우친다.
    - 보정(`src/ui/mod.rs`): 주 모니터 시스템 DPI의 `GetSystemMetricsForDpi`(`SM_CYSIZEFRAME` + `SM_CXPADDEDBORDER`)로 테두리를 구하고, gpui가 위에 배분하는 정수 절반을 배율로 나눈 만큼 시작 bounds를 아래로 옮긴다. 고정 픽셀 상수는 쓰지 않았다. 고정 크기·최소 크기 유지.
    - 실행 모델: `/clear` 뒤 Codex 세션 모델이 기본값(GPT-6.1 Terra high)으로 돌아가 K-02는 Terra high로 실행됐다. leader가 K-02 뒤 `/model`로 Sol medium(세션)으로 되돌렸다.
  - 검증: V1. `cargo build`, `tools/apply-manifest.ps1`, `cargo test initial_window_uses_work_area_center_and_fixed_client_size`(1 passed), `cargo clippy --all-targets -- -D warnings` 통과(`cards/K-02.report.md`).

- **C-06 K-02 코드 리뷰** (2026-11-06, checker)
  - 무엇을: 원인 분석, 보정량(정수 나눗셈 포함), `GetDpiForSystem`과 주 모니터 DPI, 배율별 계산, 테스트, 범위를 점검했다. 카드 `specs/v0.5/cards/C-06.md`.
  - 결과: PASS.
    - 원인 분석이 gpui 소스와 맞다. 보정량이 gpui의 위 배분과 같다.
    - 100%·125%·150%·200% 계산 오차 0px(홀수 크기 반올림 0.5px 이하).
    - 지적 1건: 테스트가 `window_options`에서 더한 보정을 같은 식으로 빼서 비교하는 동어반복이다(AGENTS 4.4). → K-02-R1.
  - 검증: V1. `git diff src/`, 그 테스트(1 passed), clippy 통과(`cards/C-06.report.md`).

- **K-02-R1 테스트 동어반복 고치기** (2026-11-07, coder)
  - 무엇을: C-06 지적대로 테스트가 기대 오프셋을 손으로 쓴 값으로 확인하게 고쳤다. 코드 동작은 바꾸지 않았다. 카드 `specs/v0.5/cards/K-02-R1.md`.
  - 결과: 기대 오프셋 리터럴 frame_height 8 / 배율 1.0 → 4px, 9 / 1.25 → 3.2px(정수 절반 4, 홀수 경우), 13 / 2.0 → 3px. gpui `calculate_window_rect`의 정수 위 배분 근거를 테스트 주석에 남겼다. Sol medium으로 실행.
  - 검증: V1. 그 테스트 1 passed, clippy 통과(`cards/K-02.report.md` "K-02-R1" 절).

- **C-07 시작 창 재실측** (2026-11-07, checker)
  - 무엇을: K-02 보정 뒤 C-05와 같은 조건·도구(`tools/measure/session.ps1`, `window-rect.ps1`)로 다시 쟀다. 주 모니터 1920×1080, 100%, 작업 영역 1920×1032(중심 960, 516). 카드 `specs/v0.5/cards/C-07.md`.
  - 결과: 4/4 PASS(`verify/reviews/measure-ORDER-02-R1.md`).
    - 첫 실행: 창 (232,90)–(1688,950) 1456×860, 클라이언트 원점 (240,90) 1440×852, 클라이언트 중심 (960, 516), 차이 0/0.
    - 100×100 축소 시도 → 클라이언트 360×240.
    - 1600×900으로 바꾸고 다시 실행 → 1440×852, 클라이언트 중심 차이 0/0.
  - 검증: V3. `session.ps1 -Action Stop` 복원(`restored=true`), 종료 뒤 `workbench-gpui` 프로세스 0건.

## 사용자 요청 작업

없음.

## 버전 종료

- 사용자 종료 판단: 진행 중.
- 남은 것: 진행 중.

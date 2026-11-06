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

- **Phase 2 종료 판정** (2026-11-07)
  - 무엇을 했나: core-leader가 ORDER-02-R1 보고를 보고 Phase 2를 판정했다(core-leader 2026-11-07, 사용자 위임 core D-13).
  - 결과: "ORDER-02-R1 충족. Phase 2 종료 판정: 충족(두 갈래 클라이언트 원점 (240,90), 1440×852, 최소 360×240)". Phase 2 마지막 커밋 `dad12f0`, push 완료(origin master `dad12f0`).
  - 검증: core-leader 판정(gpui-leader 전달, W-11).
  - 특이사항: 없음.

- **W-11 Phase 2 종료 기록, .gitignore** (2026-11-07)
  - 무엇을 했나: PLAN 진행 현황 Phase 2를 done(커밋 `dad12f0`), Phase 3을 doing(ORDER-03 받음 2026-11-07)으로 바꾸고, 위 Phase 2 종료 판정을 적었다. `.gitignore`에 `specs/v0.5/verify/reviews/_measure-*-backup/`(앱 데이터 백업, core-leader 지시)를 더했다. 카드 `specs/v0.5/cards/W-11.md`.
  - 결과: `PLAN.md`, `PROGRESS.md`, `.gitignore` 수정.
  - 검증: 문서만 바꿨다(V0).
  - 특이사항: 없음.

### Phase 3 — 편집 영역과 글꼴

- **K-03 글꼴을 Zed와 같게(I-14)** (2026-11-07, coder)
  - 무엇을 했나: R-14(I-14) 구현. 공식 GitHub 릴리스에서 IBM Plex Sans 1.1.0(`@ibm/plex-sans@1.1.0`) Regular·Italic·SemiBold·SemiBoldItalic과 Lilex 2.630 Regular·Bold·Italic·BoldItalic, 각 OFL 1.1 라이선스를 `resources/fonts/ibm-plex-sans/`·`resources/fonts/lilex/`에 넣었다. `src/ui/fonts.rs`(신규)에서 `add_fonts`로 등록하고 테마 UI/mono family·크기를 정했다. 카드 `specs/v0.5/cards/K-03.md`.
  - 결과:
    - 대체 순서: UI IBM Plex Sans → Segoe UI → Malgun Gothic, 에디터 Lilex → Cascadia Mono → Consolas → Malgun Gothic. UI `calt` 끔.
    - 에디터 Lilex 15/400, 줄 높이 1.618. 미리보기 본문은 UI 글꼴, 제목 600, 코드 블록 Lilex.
    - 이때 UI 요소별 글자 크기를 모두 16px로 바꿨다(K-03-R1에서 되돌림).
    - 의존성은 바꾸지 않았다. Zed 저장소에서 복사하지 않았다.
  - 검증: V2. `cargo build`, `tools/apply-manifest.ps1`, `cargo test k03`(3), `editor_font_and_line_height_are_spec`(1), `ui::markdown_preview`(6), clippy 통과(`cards/K-03.report.md`).
  - 특이사항: 화면 확인(V3)과 글자 모양(V4)은 남았다. `₩` 표시 변화는 앱을 실행하지 않아 확인하지 않았다.

- **K-03-R1 UI 16 해석 정정** (2026-11-07, coder)
  - 무엇을 했나: I-14 표의 UI "16"은 Zed `ui_font_size` 기본값, 즉 rem 기준값이다(leader 판단, core-leader DECISION으로 확인). K-03에서 16px로 바꾼 요소별 글자 크기를 되돌렸다. 카드 `specs/v0.5/cards/K-03-R1.md`.
  - 결과:
    - 복원: `TEXT_SIZE_DEFAULT` 14, `TEXT_SIZE_SMALL` 12, `menu::ROW_TEXT` 14, `menu::NAME_TEXT` 12, `project_panel::BANNER_TEXT` 14, `tooltip::TEXT_SIZE` 14, `tooltip::META_TEXT_SIZE` 12. `menu_line_height_and_tab_content_equal_spec` 테스트도 원래 이름·스펙 조회로 되돌렸다.
    - `UI_FONT_SIZE`(16)는 테마 `font_size`에만 쓴다. gpui-component 0.8.1이 테마 `font_size`로 창 rem을 정하고 기본값도 16이라 기존 요소 크기는 바뀌지 않는다(소스 확인).
    - 글꼴 family·대체 순서·`calt`·에디터 15/1.618·미리보기 제목 600·글꼴 파일은 그대로다.
  - 검증: V2. `cargo build`, `tools/apply-manifest.ps1`, `cargo test k03`(2), `menu_line_height_and_tab_content_equal_spec`(1), `ui::markdown_preview`(6), clippy 통과(`cards/K-03.report.md` "K-03-R1" 절).
  - 특이사항: 화면 확인은 checker에게 남았다.

- **C-08 Zed 동작 확인: I-9 스크롤바, I-14 한글 글꼴** (2026-11-07, checker)
  - 무엇을 했나: Zed 1.27.0으로 `specs/v0.5/SPEC.md`를 열어 클라이언트 1440×852, 100%, 기본 테마에서 확인했다. 카드 `specs/v0.5/cards/C-08.md`.
  - 결과(`verify/reviews/zed-ORDER-03.md`, 캡처 `verify/reviews/zed-ORDER-03/`):
    - I-9: 첫 화면(마우스 조작 없음)에서 편집 영역 스크롤바가 보이지 않는다. `HKCU\Control Panel\Accessibility` `DynamicScrollbars`는 미설정이다.
    - I-9 호버·휠 스크롤 중·스크롤 뒤 사라지는 시간은 확인하지 못했다. checker는 격리된 가상 데스크톱에서 돌아 `SetCursorPos`·`SendInput`이 실패했다.
    - I-14: Zed가 DirectWrite를 쓰고 한글은 시스템 대체 글꼴로 그린다. 캡처의 한글은 고딕 계열이다. 글꼴은 Malgun Gothic으로 추정했다(픽셀 대조는 하지 않음). core-leader DECISION으로 갈래 앱도 Malgun Gothic으로 맞춘다.
  - 검증: V3(Zed 화면 캡처, 레지스트리 읽기, 모듈 확인).
  - 특이사항(사고): checker가 이미 열려 있던 Zed 창을 닫고 zed 프로세스를 모두 끝냈다(`Get-Process *zed* | Stop-Process -Force` 포함). 이 일로 HERDR-SETUP 5.4에 "기존 창 보호"·"입력이 필요한 확인" 규칙을 더했다(W-12).

- **W-12 화면 확인 규칙 두 가지, Phase 3 진행 기록** (2026-11-07)
  - 무엇을 했나: core-leader DECISION(2026-11-07, D-13)대로 `HERDR-SETUP.md` 5.4에 "기존 창 보호"·"입력이 필요한 확인"을 더했다. SPEC R-14에 글꼴 버전·파일과 한글 대체 글꼴(Malgun Gothic, 추정)을, R-9의 Zed 동작을 "확인 중(leader 입력 확인 예정)"으로 적었다. 위 K-03·K-03-R1·C-08을 기록했다. 카드 `specs/v0.5/cards/W-12.md`.
  - 결과: `HERDR-SETUP.md`, `SPEC.md`, `PROGRESS.md` 수정.
  - 검증: 문서만 바꿨다(V0). 내용은 카드·보고 파일에서 옮겼다.
  - 특이사항: 없음.

- **K-04 I-7 경계·I-13 커서 줄 강조 조사** (2026-11-07, coder, BLOCKED)
  - 무엇을 했나: R-7(I-7)·R-13(I-13)을 조사했다. 카드 `specs/v0.5/cards/K-04.md`.
  - 결과:
    - I-7 원인: gpui-component 0.8.1 `src/input/input.rs` `Input::render`가 `rounded(theme.radius)`·`border_1()`로 Editor 자체 테두리와 둥근 모서리를 그린다. `src/ui/pane.rs` `editor_view`는 분할선에 닿는 변만 끈다. 그래서 pane 경계와 겹쳐 두 줄·둥근 모서리가 된다. `refine_style`로 지울 수 있다.
    - I-13: 엔진(gpui-base `element.rs`)은 `editor_active_line`이 있으면 현재 논리 줄 배경을 soft wrap 줄 전체 높이로 이미 그린다. 줄 번호 색은 `foreground`(현재 줄)·`muted_foreground`(나머지)만 쓰고 번호 전용 색이 없다. `Input::render`가 매 렌더링 테마 색을 다시 넣는다.
    - [BLOCKED]: Zed 줄 번호 색을 따로 넣을 공개 API가 없어 의존성 수정이나 자체 렌더링 범위를 leader가 정해야 한다. 소스는 고치지 않았다.
  - 검증: 코드·실측 문서 확인만. 빌드·테스트는 실행하지 않았다(`cards/K-04.report.md`).

- **K-04-R1 I-7 Editor 테두리 제거, I-13 현재 줄 배경** (2026-11-07, coder)
  - 무엇을 했나: leader 결정대로 I-7을 고치고 I-13 배경만 맞췄다. 줄 번호 색은 바꾸지 않았다. 카드 `specs/v0.5/cards/K-04-R1.md`.
  - 결과:
    - I-7: `pane::editor_view`에 `.border_0().rounded_none()`을 더해 Editor 자체 테두리·radius를 지웠다. pane·탭·분할선 경계는 그대로다.
    - I-13: 앱 테마는 gpui-kit 기본 `Default Light`(테마 전환 없음)다. `src/ui/theme.rs`에서 `highlight_theme.style.editor_active_line`만 Zed One Light T-05.05 `#ebebecbf`로 둔다. soft wrap 줄 전체 강조와 강조 이동은 엔진 기능 그대로다.
    - 공통 `foreground`·`muted_foreground`, 줄 번호 색, 의존성은 바꾸지 않았다.
  - 검증: V1. `cargo build`, `tools/apply-manifest.ps1`, `cargo test k04`(1), `ui::pane::tests`(47), `ui::pane_view::tests`(9), clippy 통과(`cards/K-04.report.md` "K-04-R1" 절).
  - 특이사항: `test-support`가 기본 feature가 아니고 Cargo를 바꾸지 않아 커서 이동·soft wrap 입력 시뮬레이션 테스트는 하지 않았다. 화면 확인(V3)으로 남는다. 테마 전환을 만들 때 그 테마의 T-05.05 값을 다시 넣어야 한다.

- **C-09 Zed 스크롤바 동작 판정** (2026-11-07, checker)
  - 무엇을 했나: leader가 화면 차례 안에서 Zed에 마우스·휠 입력을 주고 `tools/capture.ps1 -Method Screen`으로 남긴 캡처(`verify/reviews/zed-ORDER-03/i9/`)를 픽셀로 판정했다(입력은 leader, 판정은 checker, core-leader DECISION 2026-11-07). 카드 `specs/v0.5/cards/C-09.md`.
  - 결과(`verify/reviews/zed-ORDER-03.md` "I-9 leader 입력 확인 (C-09)" 절):
    - 세로 스크롤바 thumb가 창 밖·호버·스크롤 중·멈춘 뒤(4초까지)·다시 창 밖 모두에서 보인다. 숨김이 없어 숨김 시간은 잴 것이 없다.
    - 가로 스크롤바는 넘침이 없어(soft wrap) 보이지 않는다.
    - C-08의 "첫 화면 스크롤바 안 보임"은 PrintWindow가 DirectComposition 오버레이를 빠뜨렸기 때문이다. 화면 확인 캡처는 Screen 방식으로 한다(HERDR-SETUP 5.4, W-13).
  - 검증: V0(파일·이미지 픽셀 분석, 화면 쓰지 않음).

- **I-9 결정** (2026-11-07, core-leader)
  - 무엇을: 두 갈래 Zed 확인(gpui C-09, tauri `verify/I-9/`)을 보고 core ITEMS I-9에 "기대 정정"을 더했다(사용자 위임 D-13).
  - 결과: 스크롤할 내용이 있으면 세로 스크롤바가 마우스 위치와 상관없이 늘 보이고, 가로 스크롤바는 내용이 가로로 넘칠 때만 보인다. SPEC R-9에 옮겼다(W-13).
  - 검증: 해당 없음(결정).

- **W-13 SPEC R-9·R-13 갱신, Phase 3 진행 기록** (2026-11-07)
  - 무엇을 했나: SPEC R-9에 core ITEMS I-9 기대 정정·판정 방법을 그대로 옮기고 미정 표시를 지웠다. R-13에 강조 색 결정((A), core-leader DECISION 2026-11-07)을 적었다. 줄 번호 색 차이를 아래 스펙 불일치 목록과 Phase 12 V4 항목에 올렸다. HERDR-SETUP 5.4에 Screen 캡처 규칙을 더했다. 위 K-04·K-04-R1·C-09·I-9 결정을 기록했다. 카드 `specs/v0.5/cards/W-13.md`.
  - 결과: `SPEC.md`, `HERDR-SETUP.md`, `PROGRESS.md` 수정.
  - 검증: 문서만 바꿨다(V0).
  - 특이사항: 없음.

- **C-10 Phase 3 코드 리뷰(I-14·I-7·I-13 배경)** (2026-11-07, checker)
  - 무엇을 했나: K-03·K-03-R1·K-04-R1 작업 트리 변경을 리뷰했다. 카드 `specs/v0.5/cards/C-10.md`.
  - 결과: PASS. 글꼴 이름·크기·굵기·`calt`·대체 순서, 요소별 크기 되돌림, 글꼴 파일 출처(공식 릴리스)·라이선스·추적 대상, I-7 Editor 자체 테두리만 끔, I-13 배경 토큰만 바꿈을 확인했다.
  - 검증: V1/V2. `cargo test k03`(2)·`k04`(1)·`menu_line_height_and_tab_content_equal_spec`(1)·`ui::markdown_preview`(6)·`ui::pane`(106), clippy 통과(`cards/C-10.report.md`).

- **K-05 편집 영역 스크롤바: 세로 늘 보임, 가로 넘칠 때만(I-9)** (2026-11-07, coder)
  - 무엇을 했나: I-9 기대 정정대로 고쳤다. 카드 `specs/v0.5/cards/K-05.md`.
  - 결과:
    - 원인: gpui-base `Scrollbar::prepaint`가 mode가 없으면 테마 기본 `ScrollbarMode::Scrolling`을 써서 스크롤할 때만 보이고 숨긴다.
    - 고침: `src/ui/pane.rs` `editor_scrollbar`에 `.mode(ScrollbarMode::Always)` 한 줄. 탭 에디터 전용이라 파일 트리 등은 그대로다. 축별 overflow 판정(soft wrap이면 세로만)과 폭 15px는 그대로 쓴다.
  - 검증: V1. `cargo build`, `tools/apply-manifest.ps1`, `cargo test editor_scrollbar_width_is_spec`(1), clippy 통과(`cards/K-05.report.md`).

- **C-11 K-05 리뷰, V3 입력·캡처 스크립트 작성** (2026-11-07, checker)
  - 무엇을 했나: K-05를 리뷰하고, leader가 화면 차례 안에서 실행할 `tools/measure/order03-v3.ps1`(S-1~S-8, `-Only App|Zed|Both`)을 썼다. `tools/measure/session.ps1`도 보완했다. 카드 `specs/v0.5/cards/C-11.md`.
  - 결과: K-05 PASS. 스크립트는 실행하지 않고 AST 파싱만 확인했다.
  - 검증: V0. `cargo test editor_scrollbar_width_is_spec`(1), clippy 통과(`cards/C-11.report.md`).

- **C-12 V3 스크립트 Zed 부분 고치기(사용자 Zed 보호)** (2026-11-07, checker)
  - 무엇을 했나: core-leader 주의(이미 떠 있던 Zed PID 20788·18016은 사용자 것, Zed는 단일 인스턴스)에 따라 Zed 함수를 고쳤다: `zed -n`으로 새 창, 실행 전후 HWND 비교로 새 창만 대상, 그 HWND에만 `WM_CLOSE`, 프로세스 종료 금지, `window-rect.ps1 -TargetHwnd`에 `-ProcessName` 함께. 카드 `specs/v0.5/cards/C-12.md`.
  - 결과·검증: AST 파싱만(`cards/C-11.report.md` "C-12" 절).

- **C-13 V3 스크립트 앱 흐름 고치기(1차 실행 실패)** (2026-11-07, checker)
  - 무엇을 했나: 1차 실행 실패 원인을 찾아 앱 흐름을 고쳤다. 카드 `specs/v0.5/cards/C-13.md`.
  - 결과: 프로젝트 열기(`project-empty-open`) → fixture 열기 → 편집 상태 → 각 상태. 단계마다 레이아웃 덤프로 기대 상태를 확인하고, 아니면 캡처 1장·로그를 남기고 중단한다. 리사이즈는 `GetClientRect`로 1440×852를 확인한다.
  - 검증: AST 파싱만(`cards/C-11.report.md` "C-13" 절).

- **K-06 줄 번호 열·미리보기 코드 블록 조사(I-14)** (2026-11-07, coder, BLOCKED)
  - 무엇을 했나: core-leader NOTICE(2026-11-07, I-14 판정 기준에 줄 번호 열 폭·미리보기 코드 16px 추가)에 따라 조사했다. 카드 `specs/v0.5/cards/K-06.md`.
  - 결과: gpui-component·gpui-base 0.8.1에 줄 번호 최소 자릿수(내부 상수 3)·오른쪽 여백(6px)을 바꿀 공개 옵션이 없어 [BLOCKED]. 미리보기 코드 블록도 카드 중단 지시에 따라 고치지 않았다.
  - 검증: 코드 확인만. 빌드·테스트는 실행하지 않았다(`cards/K-06.report.md`).

- **K-06-R1 미리보기 코드 블록 16px·줄 높이 1.618** (2026-11-07, coder)
  - 무엇을 했나: 줄 번호 열은 보류하고 미리보기 코드 블록만 맞췄다. 카드 `specs/v0.5/cards/K-06-R1.md`.
  - 결과: `metrics`에 `PREVIEW_CODE_FONT_SIZE`(16px)·`PREVIEW_CODE_LINE_HEIGHT_MULTIPLIER`(1.618)를 두고 `markdown_preview::body` `with_code_block`에 썼다(25.888px). 에디터 15px는 그대로다.
  - 검증: V2. `cargo build`, `tools/apply-manifest.ps1`, `cargo test ui::markdown_preview`(7, 새 `k06_preview_code_size_and_line_height` 포함), clippy 통과(`cards/K-06.report.md` "K-06-R1" 절).

- **K-07 gpui-base 0.8.1 vendor: 줄 번호 열을 Zed와 같게(I-14·I-13)** (2026-11-07, coder)
  - 무엇을 했나: core D-14대로 gpui-base 0.8.1을 `vendor/gpui-base/`에 복사하고 `[patch.crates-io]`로 썼다(이 카드에 한해 Cargo 변경 허락). 카드 `specs/v0.5/cards/K-07.md`, 패치 기록 `vendor/gpui-base/PATCHES.md`.
  - 결과:
    - 최소 자릿수 3 → 4. 코드 편집기 거터 = 22px + 자릿수 × 숫자 폭 + 29px, 본문 +5px(9px 폭 기준 4자리 87/92px, 5자리 96/101px). gpui-component 왼쪽 padding 6px를 한 번만 센다.
    - `EditorGutterTheme`(Global)로 일반·현재 줄 번호 색을 따로 받는다. `src/ui/theme.rs`가 One Light `#b4b4bb`·`#44454b`를 넣는다. gpui-component의 렌더마다 style 덮어쓰기에 지워지지 않는다.
    - 바꾼 파일은 vendor의 3개(`element.rs`·`theme.rs`·`lib.rs`)뿐이다. Cargo.lock 변화는 gpui-base source·checksum 두 줄.
  - 검증: V2. `cargo build --offline`, `tools/apply-manifest.ps1`, `cargo test k07`(1)·`ui::pane::tests`(47)·`ui::pane_view::tests`(9)·`ui::theme::tests`(2), clippy 통과(`cards/K-07.report.md`).
  - 특이사항: 실제 잉크 위치는 글꼴 side bearing에 따라 달라 V3로 판정한다. 테마 전환을 만들 때 번호 색도 그 테마 값으로 바꿔야 한다.

- **C-14 K-06-R1·K-07 리뷰, V3 스크립트에 줄 번호 열 상태 추가** (2026-11-07, checker)
  - 무엇을 했나: 두 작업을 리뷰하고 `order03-v3.ps1`에 S-9(4자리·5자리 fixture 줄 번호 열, 편집기 왼쪽 끝 x 로그)를 더했다. 2~5차 실행 실패마다 스크립트를 고쳤다. 카드 `specs/v0.5/cards/C-14.md`.
  - 결과: K-06-R1 PASS, K-07 PASS(vendor 215개 파일 원본과 해시 같음, LICENSE 있음, 줄 번호 열만 바뀜, Cargo patch 한 줄, 기대값은 손으로 쓴 값).
  - 검증: V0/V1. `cargo test k07`·`ui::markdown_preview`(7)·`ui::theme`(2), clippy 통과, AST 파싱(`cards/C-14.report.md`).

- **V3 실행 기록과 사고** (2026-11-07, leader 실행, checker 스크립트)
  - 무엇을: leader가 화면 차례 안에서 `order03-v3.ps1`을 실행했다. 실패한 실행의 자료는 `verify/reviews/measure-ORDER-03-run<n>-*`에 남겼다.
  - 결과:
    - 1차(01:52): 앱이 "Open Project" 첫 화면에 머물러 파일이 열리지 않았고 캡처 13장이 모두 무효였다. 원인: `window-rect.ps1 -TargetHwnd` 스코프 버그로 리사이즈 실패, `--dev-pick-folder`는 폴더를 자동으로 열지 않음, 실패해도 다음 단계를 계속함(C-13에서 고침).
    - 2차(02:31): `session.ps1 -Action Start` 뒤 `session.json`이 없어 중단.
    - 3차(02:31): `OrderedDictionary`에 `ContainsKey`가 없어 중단(C-14 "런타임 오류 수정").
    - 4차(02:45): `tree-row-01`이 폴더 행이라 fixture가 열리지 않아 `file-open` 단계에서 중단(C-14 "4차 수정").
    - 5차(03:03): S-1·S-2 뒤 S-3에서 `tab-btn-split`이 분할 방향 메뉴를 열어 `tab-bar` 2개 확인이 시간 초과로 중단(C-14 "5차 수정"). S-1·S-2·S-3 단일 pane 캡처는 유효해 C-15에서 썼다.
    - 6차(03:20): 끝까지 실행. 다만 Zed 5자리 단계가 `zed -a`로 파일을 열어 **사용자 Zed 창에 탭이 추가되는 사고**가 있었다(log 03:23:14). C-15에서 `-a`를 없애고 `zed -n` 창 안에서 `Alt+2`로 바꾸게 고쳤다.
    - 기존 창 보호: 측정은 자기가 띄운 PID·HWND만 닫는다(HERDR-SETUP 5.4, W-12). Zed는 `zed -n`으로 연 자기 창 안에서만 파일을 연다(HERDR-SETUP 5.4, W-14).
  - 검증: 해당 없음(실행 기록).

- **C-15 ORDER-03 V3 판정(앱 vs Zed)** (2026-11-07, checker)
  - 무엇을 했나: 6차 실행(03:20)과 5차 유효 캡처를 픽셀·Python 도구로 판정했다. 조건: 주 모니터 1920×1080, 100%, 클라이언트 1440×852. 카드 `specs/v0.5/cards/C-15.md`.
  - 결과(`verify/reviews/measure-ORDER-03.md`, 크롭 `verify/reviews/measure-ORDER-03/crops/`): 17 PASS, 불일치 0, 판정 불가 2.
    - PASS: I-7 경계 한 줄·직각, I-8 줄바꿈·가로 스크롤바 없음, I-9 세로 스크롤바 늘 보임·폭 15px, I-13 현재 줄 배경·soft wrap 줄 전체·강조 이동·줄 번호 색(`#44454b`·`#b4b4bb`), I-14 본문 15px·줄 간격 24px(Zed와 같음)·한글 고딕·4자리 줄 번호 열 57/92px(앱 0px, Zed −1px)·미리보기 본문 Plex Sans·제목 600·UI 셸 Plex Sans.
    - 판정 불가: (1) 5자리 줄 번호 열 66/101px — Zed는 `-a` 사고로 측정 창에 5자리 파일이 없었고, 앱은 포커스가 다른 pane에 있어 `Ctrl+End`가 안 먹었다. (2) 미리보기 코드 블록 16px·25.9px — 분할 450px 폭에서 코드 블록이 뷰포트 밖으로 밀렸다. 둘 다 재측정 예정.
    - 스크립트: Zed `-a` 제거, S-3-split(`layout_probe`가 같은 이름 박스를 하나만 남겨 폭 조건으로)·S-5(미리보기 pane 판정) 확인 조건을 고쳤다.
  - 검증: V3(파일 판정, 화면 쓰지 않음, `cards/C-15.report.md`).
  - 특이사항: 사용자 확인 필요(V4): Malgun Gothic·IBM Plex Sans 렌더링 인상.

- **W-14 Phase 3 진행 기록 갱신** (2026-11-07)
  - 무엇을 했나: 위 C-10~C-15·K-05~K-07과 V3 기록을 적었다(K-04·K-04-R1은 W-13에서 적음). DECISIONS에 D-4(gpui-base vendor)·D-5(I-13 줄 번호 색 One Light, (A) 대체)와 core D-14 행을 더했다. SPEC R-14에 줄 번호 열 기준·미리보기 코드 16px·1.618, R-13에 줄 번호 색 One Light를 적었다. 스펙 불일치 목록의 I-13 줄 번호 색을 해소로 고쳤다. HERDR-SETUP 5.4에 `zed -n` 규칙을 더했다. 카드 `specs/v0.5/cards/W-14.md`.
  - 결과: `PROGRESS.md`, `DECISIONS.md`, `SPEC.md`, `HERDR-SETUP.md` 수정.
  - 검증: 문서만 바꿨다(V0). 내용은 카드·보고·로그에서 옮겼다.
  - 특이사항: 2차 실행 중단의 원인은 log에 `session.json` 없음만 있어 그 이상은 적지 않았다.

- **C-16 남은 두 항목만 재는 짧은 모드** (2026-11-07, checker)
  - 무엇을 했나: C-15의 판정 불가 2건(앱 5자리 줄 번호 열, 앱 미리보기 코드 블록)만 재도록 `order03-v3.ps1`에 `-Steps`(앱만, Zed는 열지 않음)를 더했다. S-9-5digit는 단일 pane에서 편집 영역을 클릭해 포커스를 준 뒤 `Ctrl+End`, S-5-code는 단일 pane 미리보기를 확대하고 휠로 코드 블록까지 스크롤한다. 카드 `specs/v0.5/cards/C-16.md`.
  - 결과: 문법 검사와 `-DryRunStdout` 좌표 확인 통과. Zed 함수가 이 모드에서 불리지 않고 `zed -a`가 없는 것을 확인했다.
  - 검증: V0(스크립트 정적 검사·dry-run, 화면 쓰지 않음, `cards/C-16.report.md`).

- **ORDER-03 V3 최종 판정(C-15·C-16)** (2026-11-07, leader 실행 04:18, checker 판정)
  - 무엇을 했나: leader가 화면 차례 안에서 `-Steps S-9-5digit,S-5-code`로 실행했다(`verify/reviews/measure-ORDER-03-extra/`). checker가 C-15 판정(`measure-ORDER-03/`, 03:20)에 더해 `measure-ORDER-03.md` 5절에 적었다.
  - 결과: 통과 18/19, 측정 불가 1, 불일치 0.
    - 미리보기 코드 블록: Lilex 16px(문자 폭 9.60px), 평균 줄 높이 25.83px(Zed 25.89px, 스펙 25.888px) → PASS.
    - 5자리 줄 번호 열(66/101px): 측정 불가. 캡처 시점에 657KB 문서가 아직 로드되지 않아 줄 번호 1만 보였다. 66/101은 코드 기대값으로 K-07 단위 테스트로만 확인됐다. 재측정 예정.
    - checker가 처음에 이 항목을 코드 근거로 PASS로 적었다가, leader 지적으로 '측정 불가'로 고쳤다(실제 5자리 잉크를 재지 않아 AGENTS 3A.4 "추정 금지").
  - 검증: V3(파일 판정).
  - 특이사항: 중단된 실행 기록은 `measure-ORDER-03-run1-invalid`~`run5-aborted`에 있다(위 "V3 실행 기록과 사고").

- **W-15 ORDER-03 V3 결과 기록** (2026-11-07)
  - 무엇을 했나: 위 C-16과 V3 최종 판정을 적고, Phase 12 V4 목록에 I-14 글자 모양 인상과 I-13 현재 줄 강조 대비를 더했다. PLAN 진행 현황 Phase 3을 review(core-leader 판정 대기)로 바꿨다. 카드 `specs/v0.5/cards/W-15.md`.
  - 결과: `PROGRESS.md`, `PLAN.md` 수정.
  - 검증: 문서만 바꿨다(V0).
  - 특이사항: 없음.

- **Phase 3 종료 판정** (2026-11-07)
  - 무엇을 했나: core-leader가 ORDER-03 보고를 보고 Phase 3을 판정했다(core-leader 2026-11-07, 사용자 위임 core D-13).
  - 결과: "ORDER-03 충족. Phase 3 종료 판정: 충족(I-7·I-8·I-9·I-13·I-14 두 갈래 모두)". Phase 3 커밋 `b82641d`, push 완료.
  - 검증: core-leader 판정(gpui-leader 전달, W-16).
  - 특이사항: 측정 불가 1건(5자리 줄 번호 열 66/101px)은 ORDER-04 지시로 Phase 4 화면 차례에서 다시 잰다(Phase 4 참고).

- **W-16 Phase 3 종료, Phase 4 시작 기록** (2026-11-07)
  - 무엇을 했나: PLAN 진행 현황 Phase 3을 done(커밋 `b82641d`), Phase 4를 doing(ORDER-04 받음 2026-11-07)으로 바꾸고, 위 Phase 3 종료 판정과 Phase 4의 재측정 지시를 적었다. 카드 `specs/v0.5/cards/W-16.md`.
  - 결과: `PLAN.md`, `PROGRESS.md` 수정.
  - 검증: 문서만 바꿨다(V0).
  - 특이사항: 없음.

### Phase 4 — 글자 표시

- **ORDER-04 받음** (2026-11-07)
  - 무엇을 했나: core-leader의 ORDER-04(R-20, I-20)를 받았다.
  - 결과: 추가 지시 — ORDER-03 측정 불가 1건(5자리 줄 번호 열 66/101px, `verify/reviews/measure-ORDER-03.md` 5절)을 Phase 4 화면 차례에서 다시 잰다.
  - 검증: 해당 없음(지시 기록).
  - 특이사항: 없음.

- **C-17 경로 표시 자리 조사와 측정 스크립트** (2026-11-07, checker)
  - 무엇을 했나: 앱에서 경로·`\`가 보이는 자리를 모두 찾아 표로 만들고(`cards/C-17.report.md` 1절), `tools/measure/order03-v3.ps1`을 재사용해 `tools/measure/order04-v3.ps1`(I20-tree·I20-tooltip·I20-dialog-unsaved·I20-dialog-delete·I20-title·S-9-5digit)을 새로 썼다. 카드 `specs/v0.5/cards/C-17.md`.
  - 결과: 앱이 그리는 자리 — 트리 압축 폴더(`branch \ nested`)·트리 툴팁(`D:\...\branch\nested`)은 I-20 판정 대상. 타이틀 바(마지막 폴더 이름)·상태 바·메뉴·탭 라벨(파일 이름)은 경로 구분자를 보이지 않는다. 탭 툴팁(I-11)·경로 줄(I-12)은 아직 없어 Phase 9에서 다시 본다. OS 네이티브 대화 상자(탭 닫기 미저장, 파일 삭제 확인, 폴더 선택 창)는 core-leader 결정대로 I-20 판정에서 빼고 'OS 표시'로 기록한다.
  - 검증: V0(문법 검사, `-DryRunStdout` 좌표 확인, 화면 쓰지 않음).
  - 특이사항: 없음.

- **C-18 ORDER-04 V3 판정** (2026-11-07, leader 실행 05:34, checker 판정)
  - 무엇을 했나: leader가 화면 차례 안에서 `order04-v3.ps1`을 1회 실행했고(`verify/reviews/measure-ORDER-04/`), checker가 픽셀·Python 도구로 판정했다. 카드 `specs/v0.5/cards/C-18.md`.
  - 결과(`verify/reviews/measure-ORDER-04.md`, 크롭 `verify/reviews/measure-ORDER-04/crops/`):
    - I-20: PASS. 트리 압축 폴더·트리 툴팁이 가로 획 없는 `\`로 보인다. 코드 변경 없음 — Phase 3 글꼴 변경(I-14, IBM Plex Sans·Lilex)으로 이미 풀렸다. 네이티브 대화 상자 2건(탭 닫기 미저장, 파일 삭제 확인)은 'OS 표시'로 기록했다.
    - ORDER-03 남은 1건(5자리 줄 번호 열 66/101px): PASS. 10,050줄 문서 끝 29행에서 숫자 잉크 오른쪽 끝 65~66px, 본문 시작 101px.
    - I-14 글꼴 유지: PASS.
  - 검증: V3(파일 판정).
  - 특이사항: 관찰 — 이번 실행의 앱 창 클라이언트는 1426×845(레이아웃 덤프 viewport, 첫 스냅숏부터)였다. 같은 빌드의 ORDER-03 실행들은 1440×852였다. 코드 변경이 없으므로 화면 설정(배율·모니터) 차이로 추정하나 확인하지 않았다. core-leader에게 알렸다.

- **W-17 ORDER-04 기록** (2026-11-07)
  - 무엇을 했나: 위 C-17·C-18을 적고, Phase 12 V4 목록에 I-20 OS 네이티브 대화 상자 항목을 더했다. PLAN 진행 현황 Phase 4를 review(core-leader 판정 대기)로 바꿨다. 카드 `specs/v0.5/cards/W-17.md`.
  - 결과: `PROGRESS.md`, `PLAN.md` 수정.
  - 검증: 문서만 바꿨다(V0).
  - 특이사항: 없음.

## 스펙 불일치 목록

| 요구 | 항목 | Zed | 현재 | 처리 |
|---|---|---|---|---|
| R-13(I-13) | 편집 영역 줄 번호 색 | One Dark 일반 번호 `#4e5a5f` | `#d0d4da` | 해소: core D-14로 One Light 값(현재 `#44454b`, 나머지 `#b4b4bb`) 적용(K-07, DECISIONS D-5). C-15 V3 PASS |

## Phase 12 V4 확인 항목

- (해소) R-13(I-13) 줄 번호 색: (A) 유지 결정이 core D-14로 대체돼 Zed One Light 값으로 맞췄다(K-07, C-15 PASS).
- R-14(I-14) 글자 모양 인상: 영문(IBM Plex Sans·Lilex)·한글(Malgun Gothic)의 글자 모양, 굵기(미리보기 제목 600 포함), 렌더링 인상(K-03, C-10, C-15).
- R-13(I-13) 현재 줄 강조 대비: 현재 줄 배경 `#ebebecbf`의 대비와 시각적 인상(K-04-R1, C-10).
- R-20(I-20) OS 네이티브 대화 상자의 역슬래시 표시(OS 글꼴, 자리·캡처는 `verify/reviews/measure-ORDER-04.md`)(C-17, C-18).

## 사용자 요청 작업

없음.

## 버전 종료

- 사용자 종료 판단: 진행 중.
- 남은 것: 진행 중.

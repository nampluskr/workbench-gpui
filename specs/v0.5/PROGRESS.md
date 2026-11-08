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
  - 결과: 통과 18/19, 측정 불가 1, 불일치 0. → Phase 4 화면 차례의 5자리 재측정 PASS(C-18)로 최종 19/19 PASS, 불일치 0.
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

- **Phase 4 종료 판정** (2026-11-07)
  - 무엇을 했나: core-leader가 ORDER-04 보고와 ORDER-03 5자리 재측정을 보고 Phase 4를 판정했다(core-leader 2026-11-07, 사용자 위임 core D-13).
  - 결과: "ORDER-04 충족, ORDER-03 5자리 재측정 PASS. Phase 4 종료 판정: 충족(I-20 두 갈래, 네이티브 대화 상자는 OS 표시로 V4)". Phase 4 커밋 `f82a292`, push 완료. Phase 3 V3 결과는 19/19 PASS로 고쳤다.
  - 검증: core-leader 판정(gpui-leader 전달, W-18).
  - 특이사항: 없음.

- **W-18 Phase 4 종료, Phase 5 시작 기록** (2026-11-07)
  - 무엇을 했나: PLAN 진행 현황 Phase 4를 done(커밋 `f82a292`), Phase 5를 doing(ORDER-05)으로 바꾸고, Phase 3 V3 결과를 19/19로 고쳤다(PROGRESS ORDER-03 V3 최종 판정, PLAN Phase 3 비고). 위 Phase 4 종료 판정과 Phase 5 추가 지시를 적었다. 카드 `specs/v0.5/cards/W-18.md`.
  - 결과: `PLAN.md`, `PROGRESS.md` 수정.
  - 검증: 문서만 바꿨다(V0).
  - 특이사항: 없음.

### Phase 5 — 아이콘 모양

- **ORDER-05 받음** (2026-11-07)
  - 무엇을 했나: core-leader의 ORDER-05(R-1·R-18, I-1·I-18)를 받았다.
  - 결과: 추가 지시 — "ORDER-04의 1426×845는 화면 설정 문제가 아님(두 모니터 1920×1080, 작업 영역 1920×1032, DPI 96). I-6 퇴행일 수 있어 ORDER-05 첫 화면 차례에 다시 재고, 1440×852가 아니면 원인을 찾아 고친다."
  - 검증: 해당 없음(지시 기록).
  - 특이사항: C-18 특이사항의 "화면 설정 차이로 추정"은 이 지시로 부정됐다.

- **W-18 반영 확인** (2026-11-07)
  - 무엇을 했나: W-18이 고친 PLAN 진행 현황(Phase 3 비고 19/19, Phase 4 done `f82a292`, Phase 5 doing)과 PROGRESS(Phase 4 종료 판정, ORDER-03 V3 19/19, ORDER-05 추가 지시)가 문서에 들어 있는지 확인했다.
  - 결과: 모두 들어 있다.
  - 검증: 문서 대조(V0).
  - 특이사항: 없음.

- **I-6 창 크기 재측정** (2026-11-07, ORDER-05 첫 화면 차례)
  - 무엇을 했나: ORDER-05 추가 지시대로 첫 실행 창을 다시 쟀다(`verify/reviews/measure-ORDER-05-i6/first-launch.txt`).
  - 결과: 클라이언트 1440×852, 클라이언트 원점 화면 (240,90), 클라이언트 중심 (960,516) = 작업 영역(1920×1032) 중심, 차이 (0,0). I-6 퇴행 아님. ORDER-04의 1426×845는 `order04-v3.ps1`이 창 바깥 크기로 `SetWindowPos(1442,853)`을 넣어 클라이언트를 줄인 탓이다(앱 퇴행 아님). 앱 코드는 고치지 않았다.
  - 검증: V3(GetClientRect·ClientToScreen 값).
  - 특이사항: 같은 일을 막으려고 측정 스크립트 규칙을 HERDR-SETUP 5.4에 더했다(W-19).


- **K-08 Zed 아이콘 복사본과 UI 아이콘 교체** (2026-11-07, coder)
  - 무엇을 했나: Zed 커밋 `4304dec732a75505066de5ce2dbbfb2bec369498`의 `assets/icons`와 라이선스를 `resources/zed-icons/`(.gitignore)로 받는 `tools/fetch-zed-icons.ps1`을 쓰고 실행했다. `src/ui/zed_icons.rs`(AssetSource, gpui-kit 기본 자산에 위임)를 두고 타이틀 바·탭 바·상태 바·sidebar·트리·메뉴 아이콘을 복사본 SVG로 바꿨다. 카드 `specs/v0.5/cards/K-08.md`, 보고 `cards/K-08.report.md`.
  - 결과: 404개 파일(UI 299, file_icons 96, knockouts 6, LICENSES, LICENSE-APACHE, LICENSE-GPL), `git ls-files resources/zed-icons` 0행. 대응 표는 SPEC R-1로 옮겼다. 복사본이 없으면 같은 크기 빈 칸 + stderr 경고 한 번. 남은 비-Zed 출처는 파일 트리 파일 아이콘 `IconName::File`(Phase 7). 결정은 DECISIONS D-6.
  - 검증: V1. `cargo build`, `tools/apply-manifest.ps1`, `cargo test missing_zed_icons`(1 passed), `cargo clippy --all-targets -- -D warnings` PASS.
  - 특이사항: 이름 대조용 Zed crates 소스를 레포 안에 받으려던 것을 leader가 막고 레포 밖 `%TEMP%`로 옮기게 했다. 레포 안에 Zed 소스는 없다.

- **K-08-R1 창 제어 버튼 글리프로 되돌림** (2026-11-07, coder)
  - 무엇을 했나: K-08이 창 제어 4개에 쓴 Linux용 `generic_*.svg`를 K-08 전 Segoe Fluent Icons 글리프 구현으로 되돌렸다. 카드 `specs/v0.5/cards/K-08-R1.md`.
  - 결과: U+E921/E922/E923/E8BB, Fluent가 없으면 Segoe MDL2 Assets. Zed Windows와 같다(`crates/platform_title_bar/src/platforms/platform_windows.rs`). core-leader 결정으로 I-1 SVG 기준의 예외(DECISIONS D-7). `src/ui/title_bar.rs`가 HEAD와 같다.
  - 검증: V1. `cargo build`, `tools/apply-manifest.ps1`, `cargo test ui::layout::tests`(3 passed), clippy PASS.
  - 특이사항: 없음.

- **C-19 K-08 리뷰와 ORDER-05 V3 스크립트** (2026-11-07, checker)
  - 무엇을 했나: K-08·K-08-R1 코드와 대응 표를 고정 커밋 소스와 대조하고, `tools/measure/order03-v3.ps1`을 재사용해 `tools/measure/order05-v3.ps1`(앱 12단계, Zed 5단계, `-MissingIcons`)을 썼다. 카드 `specs/v0.5/cards/C-19.md`, 보고 `cards/C-19.report.md`.
  - 결과: 리뷰 PASS(지적 없음). 스크립트는 `Ensure-ClientSize`로 GetClientRect 1440×852를 확인한다. run1·run2 실패 뒤 수정 1로 단계 실패 격리, 단계별 자체 전제(`Ensure-MarkdownFileOpen` 등), 고정 탭 프로브 `tab-00`·단축키 `ctrl-k shift-enter`, `-Skip` 정확 매칭을 고쳤다.
  - 검증: V1(코드 대조, `cargo test missing_zed_icons`·`ui::layout`, clippy, `-DryRunStdout`).
  - 특이사항: 없음.

- **ORDER-05 V3 실행** (2026-11-07, leader 실행)
  - 무엇을 했나: 화면 차례 안에서 `order05-v3.ps1`을 3회 실행했다.
  - 결과:
    - run1(`verify/reviews/measure-ORDER-05-run1/`): titlebar normal·maximized, tabbar, tabbar-zoomed 성공. `I1-tabbar-pinned`에서 FATAL로 멈췄다(프로브 이름·열린 탭 없음·단축키·예외 전파).
    - run2(`measure-ORDER-05-run2/`): 앞 4단계를 건너뛰자 `I1-toolbar`가 앞 단계의 Markdown 파일 열기에 기대고 있어 실패했다(단계 의존).
    - 3차(`measure-ORDER-05/`): 앞 4단계를 건너뛰고 나머지 앱 단계(pinned·toolbar·tab-preview·sidebar open/closed·I18-statusbar·tree-folders·MissingIcons)와 Zed 5단계 전부 PASS. MissingIcons: 경고 있음, 빈 칸, 앱 안 죽음.
  - 검증: V3 캡처. 판정은 C-20(checker) 진행 중.
  - 특이사항: run1·run2 실패는 스크립트 문제였고 C-19 수정 1로 고쳤다.

- **W-19 Phase 5 문서** (2026-11-07)
  - 무엇을 했나: DECISIONS D-6(아이콘 복사본)·D-7(창 제어 글리프 예외)을 더하고, SPEC R-1에 대응 표, R-18에 `file_tree.svg`·`folder_add.svg`를 적고, 위 Phase 5 기록과 HERDR-SETUP 5.4 창 크기 규칙을 더했다. 카드 `specs/v0.5/cards/W-19.md`.
  - 결과: `DECISIONS.md`, `SPEC.md`, `PROGRESS.md`, `HERDR-SETUP.md` 수정.
  - 검증: 문서만 바꿨다(V0).
  - 특이사항: 없음.

- **C-20 ORDER-05 V3 판정** (2026-11-07, checker)
  - 무엇을 했나: `measure-ORDER-05/`·`measure-ORDER-05-run1/` 캡처를 픽셀·Python 도구로 판정했다. 카드 `specs/v0.5/cards/C-20.md`, 보고 `cards/C-20.report.md`.
  - 결과(`verify/reviews/measure-ORDER-05.md`): I-1 대응 22자리 중 21 PASS(창 제어 4자리는 Segoe Fluent 글리프 예외). 측정 불가 1 — pane 축소 `minimize.svg`: 스크립트가 확대 키로 Alt+Z를 보냈는데 이 앱은 Shift-Escape라 확대 상태에 들어가지 못했다. I-18(`file_tree.svg`·`folder_add.svg`) PASS. 복사본 없음(빈 칸, stderr 경고, 패닉 없음) PASS.
  - 검증: V3(파일 판정).
  - 특이사항: 없음.

- **Phase 5 종료 판정** (2026-11-07)
  - 무엇을 했나: core-leader가 ORDER-05 보고(`reports/ORDER-05.md`)와 I-6 재측정을 보고 Phase 5를 판정했다(core-leader 2026-11-07, 사용자 위임 core D-13).
  - 결과: "ORDER-05 충족, I-6 재측정 정상. Phase 5 종료 판정: 충족(I-1·I-18 두 갈래, 같은 Zed 커밋·같은 대응 이름, 창 버튼은 Zed Windows와 같은 글리프)". Phase 5 커밋 `e9c9825`, push 완료.
  - 검증: core-leader 판정(gpui-leader 전달, W-20).
  - 특이사항: 남은 1자리(`minimize.svg`)는 Phase 6 화면 차례에서 다시 잰다.

### Phase 6 — 타이틀 바 메뉴

- **ORDER-06 받음** (2026-11-07)
  - 무엇을 했나: core-leader의 ORDER-06(R-2·R-17, I-2·I-17) 1단계를 받았다.
  - 결과: 추가 지시 — ORDER-05 측정 불가 1자리(pane 축소 `minimize.svg`, Shift-Escape로 확대 진입)를 ORDER-06 화면 차례에 다시 잰다.
  - 검증: 해당 없음(지시 기록).
  - 특이사항: 없음.

- **W-20 Phase 5 종료, Phase 6 시작 기록** (2026-11-07)
  - 무엇을 했나: PLAN 진행 현황 Phase 5를 done(커밋 `e9c9825`), Phase 6을 doing(ORDER-06 1단계)으로 바꾸고, 위 C-20·Phase 5 종료 판정·ORDER-06 추가 지시를 적었다. 카드 `specs/v0.5/cards/W-20.md`.
  - 결과: `PLAN.md`, `PROGRESS.md` 수정.
  - 검증: 문서만 바꿨다(V0).
  - 특이사항: 없음.

- **K-09 `≡` 메뉴·"v" 메뉴·폴더 이름 중복·Help 라이선스 창** (2026-11-07, coder)
  - 무엇을 했나: `≡` 메뉴를 Zed 순서·구현 기능만으로 고치고(File Save, Edit Undo·Redo, Help 네 항목), 타이틀 바 오른쪽 최소화 버튼 앞에 "v" 메뉴(여섯 항목, Panel Layout 하위 메뉴 Classic·Agentic)를 넣었다. 카드 `specs/v0.5/cards/K-09.md`, 보고 `cards/K-09.report.md`.
  - 결과: `src/ui/app_menu.rs`, `src/ui/mod.rs`, `src/ui/title_bar.rs` 수정. 메뉴 표는 SPEC R-17·R-2로 옮겼다(W-21).
    - 폴더 이름 중복 원인: `title_bar::left_group`이 메뉴 열림과 상관없이 메뉴 뒤에 폴더 이름을 늘 더했다. 수정: AppMenu의 열림 상태를 관찰해 열려 있는 동안 폴더 이름을 빼고, 닫히면 되돌린다.
    - Help → View Dependency Licenses: 글꼴(IBM Plex Sans, Lilex)과 Zed 아이콘(`LICENSES`·`LICENSE-APACHE`·`LICENSE-GPL`) 원문을 컴파일할 때 넣어 별도 읽기 전용 스크롤 창에 보인다. 편집기 탭·저장 경로를 만들지 않는다. 테마 라이선스는 Phase 7.
    - "v" 메뉴 여섯 항목은 비활성(회색, 누르면 아무 일 없음), Panel Layout만 하위 메뉴를 연다.
  - 검증: V1. `cargo build`, `tools/apply-manifest.ps1`, `cargo test ui::app_menu::tests` 4 passed, `cargo clippy --all-targets -- -D warnings` 통과. checker C-22 리뷰 PASS.
  - 특이사항: Go(이전·다음 탭)는 기능이 없어 `[BLOCKED]`로 남겼고 K-10에서 풀었다.

- **K-10 탭 순환** (2026-11-07, coder)
  - 무엇을 했나: core-leader 결정(2026-11-07, ORDER-06 Go 메뉴)대로 gpui에 탭 순환을 새로 만들었다. action은 Zed와 같은 `pane::ActivatePreviousItem`·`pane::ActivateNextItem`, 단축키는 tauri와 같은 Pane 컨텍스트 `Ctrl-PageUp`·`Ctrl-PageDown`. Go 메뉴를 View와 Window 사이에 넣었다. 카드 `cards/K-10.md`, 보고 `cards/K-09.report.md` `## K-10`.
  - 결과: `src/ui/tab_input.rs`, `src/ui/keymap.rs`, `src/ui/mod.rs`, `src/keymap/builtin.rs`, `src/keymap/mod.rs`, `src/ui/app_menu.rs` 수정. 끝에서 처음으로·처음에서 끝으로 돈다. 탭 0·1개면 아무 일 없다.
  - 검증: V1. `cargo test k10` 2 passed, `ui::app_menu::tests` 4 passed, `keymap::tests` 4 passed, clippy 통과. checker C-22 `## 6` 리뷰 PASS.
  - 특이사항: Zed 기본 키맵의 RunModal 컨텍스트 `Ctrl-Tab`·`Ctrl-Shift-Tab` 바인딩은 넣지 않았다(tauri와 같게).

- **C-21·C-22 ORDER-06 V3 스크립트** (2026-11-07, checker)
  - 무엇을 했나: `tools/measure/order06-v3.ps1`을 만들었다. C-21은 Zed "v" 메뉴 확인과 pane 확대(`minimize.svg`, Shift-Escape) 재측정, C-22는 앱 메뉴 단계(메뉴 막대·드롭다운·"v" 메뉴·라이선스 창·대표 action·탭 순환)를 더하고 1차 실행 멈춤을 고쳤다. 보고 `cards/C-21.report.md`, `cards/C-22.report.md`.
  - 결과: 1차 실행(07:32) 멈춤 원인 — `session.ps1 -Action Start` 출력을 파이프(`| ForEach-Object`)로 받았는데, 그 안에서 띄운 앱 프로세스가 출력 핸들을 물려받아 스크립트가 끝나도 파이프가 닫히지 않았다. 파이프를 빼고 `session.json`을 읽어 PID를 얻게 고쳤다. `-Exe` 인수 누락과 앱 이중 실행도 고쳤다(`verify/reviews/measure-ORDER-06-run1-hung/`).
  - 검증: 문법 검사 0건, `-DryRunStdout` 정상.
  - 특이사항: 없음.

- **ORDER-06 V3 실행** (2026-11-07, leader 실행, checker 판정 C-22)
  - 무엇을 했나: 화면 차례에서 `order06-v3.ps1`을 두 번 실행했다.
  - 결과:
    - 07:54 전체 실행(`verify/reviews/measure-ORDER-06-run2/summary.json`): 앱 — 메뉴 막대 열림(메뉴 7개, 이름 사이 gap 4.0px = I-321, 열렸을 때 폴더 이름 없음)·드롭다운 7개(닫으면 폴더 이름 복원)·"v" 메뉴와 Panel Layout·대표 action·pane 확대 PASS, 라이선스 창 FAIL(Help 위 hover로 열린 드롭다운을 클릭이 다시 닫음)·탭 순환 FAIL(두 번째 탭이 열리지 않음). Zed — "v" 메뉴·Panel Layout·pane 확대 PASS, Settings·Keymap·Themes·Icon Themes·Extensions 다섯 단계 FAIL(스크립트의 StrictMode `.Count` 오류). 사용자 Zed 설정 파일 해시 불변.
    - C-22가 실패 원인을 고친 뒤 08:07 실패 단계만 다시 실행하려 했으나 `session.json`이 없어 중단(`measure-ORDER-06-run3-aborted/`).
    - 08:08 앱 단계만 재실행(`verify/reviews/measure-ORDER-06/summary.json`): 라이선스 창 PASS(`app-license-window.png`, WM_CLOSE로 닫음, 브라우저 항목은 누르지 않음), 탭 순환 FAIL(트리에서 파일 두 개를 더블클릭해도 `tab-01` 없음, `error-two-tabs-open.png`). Zed 다섯 단계는 다시 돌리지 않았다.
  - 검증: V3(일부).
  - 특이사항: 탭 순환 화면 확인과 Zed 다섯 단계 캡처가 남았다. 탭 순환 동작 자체는 V1 테스트로 확인돼 있다(K-10).

- **Zed Settings 창이 사용자 Zed 프로세스에 남음** (2026-11-07)
  - 무엇을 했나: 07:54 실행의 `zed-v-settings` 단계에서 `Ctrl-,`를 보냈더니 Zed가 스크립트가 띄운 창이 아니라 사용자가 쓰던 Zed 프로세스 안에 'Zed — Settings' 창을 열었다. 단계가 `.Count` 오류로 멈춰 이 창이 닫히지 않고 남았다.
  - 결과: Zed 사용자 설정 파일(`%APPDATA%\Zed\settings.json`) 해시는 실행 앞뒤로 같다(`C3D27B05…`), `keymap.json`은 없음 그대로. leader가 그 창을 닫으려 했으나 자동 모드가 거부했고 우회하지 않았다. core-leader에게 알렸다.
  - 검증: summary.json의 설정 파일 해시 대조.
  - 특이사항: C-22가 스크립트를 고쳐 새로 생긴 Zed 창(HWND)만 닫게 했다. 남은 창은 사람이 닫는다.

- **core 결정: ORDER-06-R1, Settings 공통안** (2026-11-07, core-leader, 사용자 위임 core D-13)
  - 무엇을 했나: core-leader가 ORDER-06 2단계 `ORDER-06-R1`(core D-15)과 Settings 공통안을 정했다.
  - 결과:
    - D-15: "v" 메뉴 화면은 Zed의 틀(여는 방식·배치·검색·컨트롤·단축키)에 이 앱의 실제 내용만 담는다. Settings는 별도 OS 창(User 범위), Keymap·Extensions는 편집 영역 새 탭, Extensions는 복사한 테마·아이콘 테마만(온라인 목록·설치 없음), Panel Layout은 Classic만(Agentic 뺌, 기본과 다르면 Custom 체크·비활성).
    - R1 2.5: View의 Split Up/Down/Left/Right를 Zed처럼 `Editor Layout` 하위 메뉴로 옮긴다(tauri는 이미 이렇다).
    - Settings 공통안: `%APPDATA%\workbench-gpui\settings.json`, Zed 형식(JSONC), 키 `theme`·`icon_theme`·`ui_font_size`(기본 16)·`buffer_font_size`(기본 15), 바꾸면 바로 저장·적용. 범주 `Appearance` 하나, 행 넷(Theme·Icon Theme·UI Font Size·Buffer Font Size), 이름·설명은 Zed Settings UI 문구 그대로.
  - 검증: 해당 없음(결정 기록). gpui 카드 K-11로 넘겼다.
  - 특이사항: K-11은 `[BLOCKED]`다. 카드가 Settings 창 치수·간격을 tauri SPEC 값으로 쓰라 했는데 아직 없다(`cards/K-11.report.md`, "tauri 값 대기"). dock 기본 폭은 `src/ui/metrics.rs` `DOCK_DEFAULT_WIDTH = rems_from_px(240.)`.

- **W-21 메뉴 표 SPEC 반영, tauri 대조** (2026-11-07)
  - 무엇을 했나: K-09·K-10 메뉴 표를 SPEC R-17에, "v" 메뉴 표를 R-2에 옮기고 tauri 표와 대조했다. 카드 `cards/W-21.md`, 보고 `cards/W-21.report.md`.
  - 결과: `SPEC.md`, `PROGRESS.md` 수정. tauri와 다른 곳 — View 분할(gpui 직접 항목, tauri Editor Layout 하위 메뉴, K-11 몫), Close Editor 단축키 표시(gpui `Ctrl-W`/`Ctrl-F4`, tauri 없음), Redo 단축키(gpui `Ctrl-Y`, tauri `Ctrl-Shift-Z`).
  - 검증: 문서만 바꿨다(V0).
  - 특이사항: 맞추는 일은 leader가 coder 카드로 낸다.

- **ORDER-06 1단계 충족 판정** (2026-11-07, core-leader)
  - 무엇을 했나: core-leader가 gpui ORDER-06 1단계 보고(`reports/ORDER-06.md`)를 판정했다.
  - 결과: 충족. 메뉴 막대 순서가 tauri와 같고 폴더 이름 중복을 고쳤다. "v" 버튼과 여섯 항목이 있고 동작 없는 항목은 비활성이다. Licenses 창이 있다. ORDER-05 pane 축소 아이콘 PASS로 ORDER-05 V3는 22/22다(core `PROGRESS.md`).
  - 검증: 해당 없음(판정 기록).
  - 특이사항: 탭 순환은 V1만 했고 화면 확인은 R1 V3에서 한다. 1단계 코드는 R1과 함께 커밋한다.

- **core 결정: 두 갈래 메뉴 차이 다섯 가지** (2026-11-07, core-leader, 사용자 위임 core D-13)
  - 무엇을 했나: 1단계 보고의 결정 요청(Close Editor 키 표시, Redo 키)과 참고 차이에 대한 결정을 받았다.
  - 결과: DECISIONS D-9에 적었다 — 키가 묶인 메뉴 항목은 키 표시(Close Editor `Ctrl-W`), 편집 키는 Zed `default-windows.json` 그대로·메뉴엔 첫 키, 메뉴 이름 간격은 잉크 사이로 Zed 13~14px ±1, "v" 버튼 치수는 tauri SPEC 값, Licenses는 앱에 들어간 자원 전부. gpui 카드 K-12(1~3).
  - 검증: 해당 없음(결정 기록).
  - 특이사항: 없음.

- **K-11·K-11-R1 Settings 창, settings.json, Panel Layout, Editor Layout** (2026-11-07, coder)
  - 무엇을 했나: K-11은 Settings 창 치수가 tauri SPEC에 없어 `[BLOCKED]`로 멈췄다. leader가 K-11-R1로 치수 말고 나머지를 먼저 하게 했다(치수는 gpui-kit 기본값을 `metrics.rs` `settings_window` 한 곳에 모으고 pending 주석). 카드 `cards/K-11.md`·`cards/K-11-R1.md`, 보고 `cards/K-11.report.md`.
  - 결과: `src/ui/settings.rs` 신규, `src/ui/metrics.rs`·`mod.rs`·`keymap.rs`·`pane.rs`·`pane_view.rs`·`panel_nav.rs`·`tab_close.rs`·`app_menu.rs`, `src/keymap/builtin.rs`·`mod.rs` 수정.
    - `%APPDATA%\workbench-gpui\settings.json`(JSONC 읽기, 알 수 없는 키 보존, 원자 교체 저장, 저장 성공 뒤 적용, 파일 감시로 외부 저장 반영). 기본값 UI 16·버퍼 15.
    - Settings 별도 창(`Ctrl-,`, 열려 있으면 앞으로), 검색·Appearance·User·`Edit in settings.json`·행 4개(Zed 문구, SPEC R-2 표).
    - Panel Layout: Agentic 뺌, Classic(dock 열기·기본 폭 240px 복원), 기본과 다르면 Custom 체크·비활성.
    - View → Editor Layout 하위 메뉴(Split Up/Down/Left/Right).
  - 검증: V1. `cargo build`, `tools/apply-manifest.ps1`, `cargo test k11` 3 passed, `ui::app_menu::tests` 4 passed, `keymap::tests` 5 passed, clippy 통과.
  - 특이사항: Settings 창 치수는 아직 기본값이다. tauri SPEC에 Zed 실측값이 생겨 SPEC R-2로 옮겼다(W-22). UI 저장은 JSONC 주석·서식을 유지하지 않는다. 실측 필요 목록은 보고에 있다(V3 대상).

- **Codex 한도 알림과 core 결정** (2026-11-07)
  - 무엇을 했나: gpui-coder의 Codex 5시간 한도가 16% 남았고 주간은 48%라 core-leader에게 알렸다.
  - 결과: 결정(core-leader, core D-13) — 지금 한도로 계속한다. 바닥나면 `[BLOCKED]`로 알리고, 그때 사용자에게 쿠폰 사용을 알린다(core D-2). HERDR 구성(writer가 구현을 맡는 것)은 바꾸지 않는다. coder 카드는 작게 나누고 문서는 writer가 먼저 한다.
  - 검증: 해당 없음(결정 기록).
  - 특이사항: K-12를 작은 카드로 냈고, 이 결정으로 W-22를 coder 카드보다 먼저 했다.

- **W-22 ORDER-06-R1 문서 정리** (2026-11-07)
  - 무엇을 했나: DECISIONS에 core D-15 적용과 D-8(Settings 공통안)·D-9(메뉴 차이 다섯 가지)·D-10(새로 생긴 창도 내가 연 것만 닫는다)을 적고, SPEC R-2를 R1 범위의 화면별 항목 표로 고쳤다. tauri SPEC의 Settings 창·"v" 버튼 Zed 실측값을 출처와 함께 옮겼다. 카드 `cards/W-22.md`, 보고 `cards/W-22.report.md`.
  - 결과: `DECISIONS.md`, `SPEC.md`, `PROGRESS.md` 수정. tauri와 다른 곳은 보고에 목록으로 적었다.
  - 검증: 문서만 바꿨다(V0).
  - 특이사항: 없음.

- **Codex 한도 소진, 쿠폰 적용, coder 모델 되돌림** (2026-11-07)
  - 무엇을 했나: K-11-R1을 끝낸 뒤 gpui-coder의 Codex 5시간 한도가 3% 남아 core-leader에게 `[BLOCKED]`로 알렸다. coder 모델이 GPT-6-Luna로 바뀌어 있었다.
  - 결과: 사용자가 쿠폰 사용을 정하고 직접 적용했다(core `PROGRESS.md`, core D-2). core-leader가 알린 뒤 coder 모델을 GPT-6.1-Sol medium으로 되돌리고 K-12부터 이었다. HERDR 구성은 바꾸지 않았다.
  - 검증: 해당 없음(운영 기록).
  - 특이사항: 없음.

- **core 결정: settings.json 처리를 tauri 방식으로** (2026-11-07, core-leader, 사용자 위임 core D-13)
  - 무엇을 했나: 두 갈래 settings.json 처리 차이에 대한 결정을 받았다.
  - 결과: 주석을 보존하고, 잘못된 값은 그 키만 기본값으로 쓰고 오류를 알린다. gpui가 맞춘다. gpui 카드 K-13.
  - 검증: 해당 없음(결정 기록).
  - 특이사항: 없음.

- **K-12 메뉴 키를 Zed `default-windows.json`에, 메뉴 이름 간격** (2026-11-07, coder)
  - 무엇을 했나: 메뉴 항목의 키를 Zed `default-windows.json`(커밋 `4304dec732`, 레포 밖 sparse checkout 읽기만)과 대조해 맞추고 메뉴에 첫 키를 보이게 했다. 이름 버튼 좌우 padding을 글자 잉크 간격 기준으로 정했다. 카드 `cards/K-12.md`, 보고 `cards/K-12.report.md`.
  - 결과: `src/keymap/builtin.rs`, `src/keymap/mod.rs`, `src/ui/metrics.rs` 수정.
    - 키 전후: Undo 앱 키맵에 `Ctrl-Z` 명시(Input), Redo `Ctrl-Shift-Z` 추가·표시 `Ctrl-Y`, Close Editor 표시 `Ctrl-F4` → `Ctrl-W`, Split Right 표시 `Ctrl-K Right` → `Ctrl-\`. 나머지 메뉴 키는 원본과 같아 그대로다. 표는 SPEC R-17 "메뉴 키 기준".
    - 이름 간격: gap 4px(I-321)는 두고 좌우 padding 6 → 4px. IBM Plex Sans 12px 측면 여백을 넣은 예상 잉크 간격 12.768~14.028px(Zed 13~14px와 1px 이내). 표는 SPEC R-17 "메뉴 이름 간격".
  - 검증: V1. `cargo build`, `tools/apply-manifest.ps1`, `cargo test keymap::` 17 passed, `app_menu::tests` 4 passed, clippy 통과, `git diff --check` 통과.
  - 특이사항: 실측 필요 — I-321/R-17 메뉴를 펼친 상태의 이름 잉크 간격(V3).

- **K-13 settings.json 바뀐 키만 저장, Settings 창·"v" 버튼 치수, Licenses 전부** (2026-11-07, coder)
  - 무엇을 했나: core 결정대로 settings.json 저장을 tauri 방식으로 바꾸고, Settings 창·"v" 버튼 치수를 SPEC R-2의 Zed 실측값으로 넣고, Licenses에 빠진 자원을 더했다. 카드 `cards/K-13.md`, 보고 `cards/K-13.report.md`.
  - 결과: `src/ui/settings.rs`, `src/ui/keymap.rs`, `src/ui/metrics.rs`, `src/ui/app_menu.rs` 수정.
    - 저장: 전체 재직렬화를 없애고 바꾼 키의 값 범위만 교체한다(기존 jsonc-parser AST, 의존성 변경 없음). 주석·한글·CRLF·모르는 키·후행 쉼표를 보존하고, 깨진 파일은 저장을 거부한다. 잘못된 키만 기본값으로 쓰고 다른 키는 적용하며, 파일의 잘못된 값은 덮어쓰지 않는다. 오류는 기존 앱 알림과 Settings 화면 오류 자리에 보인다.
    - Settings 창: pending 상수를 900×750, 탐색 폭 226, 본문 padding 32, 탐색 padding 10, 범주 gap 12, 행 gap 24, 컨트롤 높이 28, 버튼 높이 22로 바꿨다. 드롭다운은 자동 폭(고정 `CONTROL_WIDTH` 제거).
    - "v" 버튼: 22×22, 오른쪽 여백 4, chevron 잉크 8 목표로 아이콘 ≈14.388px.
    - Licenses: 여섯 개 — IBM Plex Sans, Lilex, Zed 아이콘 셋, `vendor/gpui-base` `LICENSE-APACHE`(빠졌던 것).
  - 검증: V1. `cargo build`, `tools/apply-manifest.ps1`, `cargo test settings::tests` 4 passed, `app_menu::tests` 4 passed, clippy 통과, `git diff --check` 통과. 알림·컨트롤 연결은 코드 확인.
  - 특이사항: K-11 특이사항의 "UI 저장은 JSONC 주석·서식을 유지하지 않는다"가 풀렸다. 실측 필요 — Settings 창 크기·탐색 폭·컨트롤 높이·간격, "v" 버튼 22×22·chevron 잉크 8·최소화까지 4(V3).

- **K-14 Keymap Editor 탭** (2026-11-07, coder)
  - 무엇을 했나: core ORDER-06-R1 2.2대로 Keymap Editor 탭을 만들었다. 카드 `cards/K-14.md`, 보고 `cards/K-14.report.md`.
  - 결과: `src/ui/keymap_editor.rs` 신규, `src/keymap/{builtin,file,mod}.rs`, `src/ui/{app_menu,keymap,metrics,mod,pane,pane_group,pane_view,settings,tab_input}.rs` 수정.
    - "v" 메뉴 Keymap·`Ctrl-K Ctrl-S`로 편집 영역 새 탭을 연다(이미 있으면 그 탭, 폴더가 없어도 열림). 도구 탭은 문서로 등록하지 않는다.
    - 필터칸·`Edit in JSON`(`Ctrl-E`)·`Create Keybinding`(`Ctrl-K`), 열 Action·Arguments·Keystrokes·Context·Source(Default/User). 행은 실행 중 키맵의 바인딩 전부와 바인딩 없는 앱 액션.
    - 편집·새로 만들기는 표 아래 입력칸, 저장 전 gpui 파서로 검사, 사용자 keymap.json 끝에 override 섹션을 더해 주석·BOM·후행 쉼표 보존, 바로 적용. 구성은 SPEC R-2 Keymap "실제 구성".
  - 검증: V1. `cargo build`, `tools/apply-manifest.ps1`, `cargo test` keymap 19·`pane_group::tests` 37·`pane::tests` 47·`tab_input::tests` 3·`app_menu::tests` 4·`settings::tests` 4 = 114 passed, clippy 통과, `git diff --check` 통과. 입력 이벤트·액션 연결은 코드 확인(gpui 입력 시뮬레이션 안 함).
  - 특이사항: 키 입력 찾기·필터 버튼(선택 사항), 키 녹화·모달 편집, 인자 편집은 하지 않았다(SPEC R-2 "Zed와 다른 점", 후속 범위는 leader 판정). 반복 편집하면 override 섹션이 쌓인다. 실측 필요 — Keymap Editor 탭 전체, K-010~K-022, 행 선택·편집 영역 배치, 메뉴·`Ctrl-K Ctrl-S` 진입, `Ctrl-E`·`Ctrl-K` 동작.

- **K-15 Extensions 탭** (2026-11-07, coder)
  - 무엇을 했나: core ORDER-06-R1 2.3대로 Extensions 탭을 만들었다. 카드 `cards/K-15.md`, 보고 `cards/K-15.report.md`.
  - 결과: `src/ui/extensions.rs` 신규, `src/ui/{keymap_editor,app_menu,keymap,metrics,mod}.rs`, `src/keymap/{builtin,mod}.rs` 수정.
    - "v" 메뉴 Extensions·`Ctrl-Shift-X`로 새 탭(이미 있으면 그 탭, K-14의 `open_tool` 공유).
    - 제목·검색칸 "Search extensions…"·`All`/`Installed`/`Not Installed`·범주 칩 `All`/`Themes`/`Icon Themes`·카드(이름·버전·태그·설명·작성자·오른쪽 `Installed`). 검색은 이름·설명.
    - 자원 목록은 `RESOURCES` 한 곳: `Default Light`(테마), `Zed (Default)`(아이콘 테마). manifest가 없어 버전·작성자·설명은 비웠다. 지금은 모두 번들이라 `Not Installed`는 빈 목록이다. 치수는 X-45~X-49.
  - 검증: V1. `cargo build`, `tools/apply-manifest.ps1`, `cargo test extensions::tests` 2 passed, `keymap` 19 passed, `app_menu::tests` 4 passed, clippy 통과, `git diff --check` 통과. 입력·액션 연결은 코드 확인.
  - 특이사항: Phase 7에서 복사한 자원과 원본 메타데이터를 `RESOURCES`에 더하고 목록이 늘어나는지 확인한다(복사 경로 미정). 실측 필요 — Extensions 탭, X-45~X-49, 메뉴·`Ctrl-Shift-X` 진입과 기존 탭 활성화.

- **W-23 K-12~K-15 기록** (2026-11-07)
  - 무엇을 했나: 위 K-12~K-15와 쿠폰·settings.json 결정을 적고, SPEC R-2(Settings 저장·치수 현재 상태, "v" 버튼, Keymap·Extensions 실제 구성과 Zed와 다른 점)·R-17(메뉴 표, 메뉴 키 전후 표, 이름 간격, Licenses)을 갱신했다. 카드 `cards/W-23.md`, 보고 `cards/W-23.report.md`.
  - 결과: `SPEC.md`, `PROGRESS.md` 수정. tauri SPEC과 다른 곳은 보고에 목록으로 적었다.
  - 검증: 문서만 바꿨다(V0).
  - 특이사항: 없음.

- **커밋 `c723b7e`** (2026-11-07, leader)
  - 무엇을 했나: ORDER-06 1단계와 K-11-R1(Settings 창·settings.json·Panel Layout·Editor Layout)을 커밋했다.
  - 결과: 측정 폴더의 사용자 앱 데이터 백업 `session-backup/`이 실수로 커밋에 들어가, push 전에 amend로 빼고 `.gitignore`에 `specs/v0.5/verify/reviews/*/session-backup/`을 더했다.
  - 검증: `.gitignore` 7행 확인.
  - 특이사항: K-12~K-16, C-26 리뷰, `tools/measure/order06-r1-v3.ps1`은 아직 커밋하지 않았다(작업 트리).

- **C-26 K-12~K-15 리뷰, R1 V3 스크립트** (2026-11-07, checker)
  - 무엇을 했나: K-12~K-15 코드를 리뷰하고 `tools/measure/order06-r1-v3.ps1`을 11단계(메뉴 이름 잉크 간격, "v" 버튼 확대, Settings 창 치수, settings.json 주석 보존, Edit in settings.json, Keymap Editor, Extensions, Panel Layout, Editor Layout, 탭 순환, 재실행 유지)로 보강했다. 측정 앞뒤로 `%APPDATA%\workbench-gpui`의 settings.json·keymap.json을 백업·복원한다. 카드 `cards/C-26.md`, 보고 `cards/C-26.report.md`.
  - 결과: 리뷰 PASS(K-12 키가 Zed `default-windows.json`과 같음, K-13 값 범위만 교체·원자 교체, K-14 도구 탭이 문서·감시에서 빠짐, K-15 다운로드·설치 없음). 지적 — K-14 반복 편집 때 override 섹션이 쌓인다(`shortcut:` 주석 있음).
  - 검증: `cargo build`, `apply-manifest.ps1`, `cargo test` settings 4·keymap 19·extensions 2·app_menu 4 passed, clippy 통과, 스크립트 문법 검사, `-DryRunStdout` 정상.
  - 특이사항: 없음.

- **ORDER-06-R1 V3 1차** (2026-11-07 09:44, leader 실행, checker 판정 C-27)
  - 무엇을 했나: 화면 차례에서 `order06-r1-v3.ps1`을 실행하고, checker가 결과 파일만으로 판정했다(캡처 20장 해시 대조, 픽셀 실측, layout 대조). 자료 `verify/reviews/measure-ORDER-06-R1/`, 판정 `verify/reviews/measure-ORDER-06-R1.md`, 보고 `cards/C-27.report.md`.
  - 결과:
    - PASS: 메뉴 이름 잉크 간격 13px(목표 13~14 ±1), "v" 버튼 chevron 잉크 8px, Settings 창 클라이언트 900×750, 재실행 뒤 유지, settings.json 주석·다른 키 보존(값 변경 자체는 입력 미전달).
    - 앱 결함 2건: Settings 창 컨트롤이 세로 가운데로 몰림(최외곽 `h_flex`가 `items_center`), "v" 버튼 컨테이너 26×22(안쪽 오른쪽 여백 4 포함) → K-16으로 고쳤다.
    - 스크립트 결함: Keymap Save 클릭 좌표가 사이드바 폭(300) 오프셋을 반영하지 않음, 탭 순환 단계가 도구 탭 뒤 폴더 목록 상태를 처리하지 못하고 dock을 닫음, 여러 단계에서 입력이 전달되지 않음(Extensions 칩·Panel Layout·Editor Layout·Settings 검색 등 캡처 해시 동일 → 측정 불가). checker가 고치는 중.
    - summary.json의 메뉴 간격 FAIL은 스크립트가 박스 간격 4.0px를 목표와 비교한 오류다.
  - 검증: V3(일부). 판정 REWORK.
  - 특이사항: 사용자 데이터 — 측정 앞뒤로 `%APPDATA%\workbench-gpui\state.json` 동일, settings.json·keymap.json은 원래대로(없음).

- **K-16 Settings 창 위 정렬, "v" 버튼 22×22** (2026-11-07, coder)
  - 무엇을 했나: C-27 앱 결함 2건을 고쳤다. 카드 `cards/K-16.md`, 보고 `cards/K-16.report.md`.
  - 결과: `src/ui/settings.rs`, `src/ui/app_menu.rs`, `src/ui/title_bar.rs` 수정. Settings 최외곽 `h_flex`에 `items_start`(기존 padding 그대로). "v" 버튼 안쪽 오른쪽 여백을 없애고 타이틀 바에 폭 4px 요소를 따로 넣어 user-menu가 버튼 영역(22×22)만 차지하게 했다. layout probe에 `user-menu-gap`을 더했다. chevron 크기는 그대로.
  - 검증: V1. `cargo build`, `apply-manifest.ps1`, `cargo test settings::tests` 4·`app_menu::tests` 4 passed, clippy 통과, `git diff --check` 통과. 정렬·간격은 코드 확인.
  - 특이사항: 실측 필요 — Settings 창 위 정렬·padding 위치, "v" 버튼 22×22·최소화까지 4px(C-27 불일치 항목만 재측정).

- **Codex 한도와 core D-16** (2026-11-07)
  - 무엇을 했나: 쿠폰(1차) 적용 뒤 coder Codex 5시간 한도가 48% 남았다. core D-16(사용자 결정)을 받았다.
  - 결과: 다시 바닥나면 기다리거나 쿠폰을 쓰지 않고, coder를 Claude Code Sonnet 5.5 high로 바꿔(같은 pane, 이름 `gpui-coder`) 잇는다. 바꾼 시각·모델을 HERDR-SETUP·PROGRESS에 적는다. HERDR-SETUP 2.1에 이 규칙을 적었다.
  - 검증: 해당 없음(결정 기록).
  - 특이사항: 아직 바꾸지 않았다.

- **ORDER-06-R1 지금 상태와 남은 일** (2026-11-07, W-24 작성, W-25 갱신)
  - 무엇을 했나: core-leader NOTICE(D-3)대로 다음 세션이 이 문서만 보고 이어 가도록 상태를 적었다(카드 `cards/W-24.md`). V3 2·3차 결과로 갱신했다(카드 `cards/W-25.md`). 판정 `verify/reviews/measure-ORDER-06-R1.md`(checker, C-28), 스크립트 수정 `cards/C-28.report.md`.
  - 결과:
    - V3 2차(10:37, 자료 `verify/reviews/measure-ORDER-06-R1-run2/`): PASS — Keymap Editor 필터·바인딩 저장(`keymap.json` 내용 일치), Panel Layout(dock 닫힘 → Custom → Classic 복원), 탭 순환(고정 탭 2개 Ctrl-PageDown/PageUp), 재실행 유지. 측정 불가 — Settings 세 단계(창·주석 보존·Edit in settings.json)는 스크립트 구문 오류(식 안의 `if`)로 중단, Extensions `Icon Themes` 칩과 Editor Layout 하위 메뉴는 캡처 해시가 그대로여서 입력 미전달. K-16은 layout probe로 user-menu 22×22·`user-menu-gap` 4px, Settings `isCentered=False` 확인. checker가 C-28로 스크립트를 고쳤다.
    - V3 3차(10:58, 자료 `verify/reviews/measure-ORDER-06-R1/`, 남은 6단계만): PASS — "v" 버튼 크롭(22×22, chevron 잉크 8px, 오른쪽 여백 4px), Extensions(Themes·Icon Themes 칩, 검색 "Zed" 모두 캡처 해시 변경). Settings 창 클라이언트 900×750은 다시 확인. 측정 불가 — Settings 창 안 조작(검색 입력, Buffer Font Size 값 변경과 주석 보존, Edit in settings.json)과 Editor Layout 하위 메뉴는 입력이 전달되지 않았다(캡처 해시 불변). 이 항목은 화면 실측 대신 V1 테스트를 근거로 둔다 — Settings 저장·주석 보존은 K-13 `settings::tests`, Editor Layout은 `app_menu::tests`(View 메뉴에 항목이 있는지까지, 하위 메뉴 전개는 코드 확인).
    - 사용자 앱 데이터: 2·3차 모두 측정 뒤 `%APPDATA%\workbench-gpui\state.json` 해시가 같고(`D2C22F71…`), settings.json·keymap.json은 원래대로(없음)로 돌렸다.
    - 커밋됨: `c723b7e`(1단계 + K-11-R1).
    - 커밋 안 됨(작업 트리): K-12~K-16 코드, C-26 리뷰(PASS), `tools/measure/order06-r1-v3.ps1`, 카드·보고, V3 1~3차 자료와 판정.
    - 남은 일: 커밋 → `specs/v0.5/reports/ORDER-06-R1.md`.
  - 검증: 문서만 바꿨다(V0).
  - 특이사항: `measure-ORDER-06-R1.md`는 2차까지만 반영돼 있고 3차 결과는 `measure-ORDER-06-R1/summary.json`·`log.txt`에 있다. 2차 자료가 `-run2/`로 옮겨져 판정 파일의 "2차 `measure-ORDER-06-R1/`" 경로 표기와 어긋난다.

- **K-17 Keymap Editor를 tauri(=Zed 기준)와 같게** (2026-11-07, coder, core ORDER-06-R2 1장)
  - 무엇을 했나: Edit 아이콘 열, 읽기 쉬운 Action·AND 필터, 빈 값 표시, 편집 모달·Record·자동완성, 저장 충돌 거부, 같은 작업 공간의 탭만 앞으로. 카드 `cards/K-17.md`, 보고 `cards/K-17.report.md`.
  - 결과: `src/ui/keymap_editor.rs`, `src/ui/keymap.rs`, `src/ui/metrics.rs` 수정. 구성은 SPEC R-2 Keymap "실제 구성".
  - 검증: V1. `cargo build`, `tools/apply-manifest.ps1`, `cargo test keymap` 22 passed, clippy 통과, `git diff --check` 통과. 이벤트·포커스 연결은 코드 확인(gpui 입력 시뮬레이션 안 함).
  - 특이사항: 실측 필요 — K-022·K-036(Edit 열), K-080~K-083(모달), hover·포커스 아이콘. 모달 포커스·Record·자동완성 입력은 Phase 12 V4.

- **K-18 Settings 행 구성·저장 충돌, "v" 아이콘 14px, Extensions** (2026-11-07, coder, core ORDER-06-R2 1장, core-leader 결정)
  - 무엇을 했나: Settings 소제목 Theme → Buffer Font → UI Font(core-leader 결정), 숫자 감소·증가 버튼·드롭다운 `chevron_up_down`, 저장 충돌 거부, "v" chevron 14px(I-601). core-leader 결정으로 Extensions 차이 1·2·5·6·7·8(작성자 검색, AND, 정렬, 빈 상태 문구, 버전 `v`·빈 값 숨김, 메타데이터 출처)을 tauri SPEC R-2 표대로 맞췄다. 카드 `cards/K-18.md`, 보고 `cards/K-18.report.md`.
  - 결과: `src/ui/settings.rs`, `src/ui/extensions.rs`, `src/ui/metrics.rs` 수정. SPEC R-2 Settings·"v" 버튼·Extensions 표에 반영.
  - 검증: V1. `cargo build`, `tools/apply-manifest.ps1`, `cargo test settings::tests` 5·`extensions::tests` 3 passed, clippy 통과, `git diff --check` 통과. 컨트롤·알림 연결은 코드 확인.
  - 특이사항: Extensions 차이 3·4(자원 목록·자동 읽기)는 Phase 7. 실측 필요 — Settings 소제목·행 순서와 컨트롤 배치, "v" 버튼 I-601 14px, Extensions 빈 상태·카드 표시. Settings 입력·드롭다운 동작은 Phase 12 V4.

- **C-29 K-17·K-18 리뷰, tauri 대조, R2 V3 스크립트** (2026-11-07, checker)
  - 무엇을 했나: K-17·K-18 코드를 리뷰하고 tauri SPEC R-2 표와 항목별로 대조했다. `tools/measure/order06-r1-v3.ps1`을 재사용해 `tools/measure/order06-r2-v3.ps1`(v 버튼 크롭, Settings 창, Keymap Editor, Extensions 4단계)을 만들었다. 카드 `cards/C-29.md`, 보고 `cards/C-29.report.md`.
  - 결과: 리뷰 PASS. 대조 표(Keymap Editor 14항목, Settings 11항목, "v" 버튼 3항목, Extensions 차이 6항목) 전부 일치. 저장 충돌 거부는 Keymap·Settings 모두 디스크를 쓰지 않고 거부한다(테스트로 바이트 보존 확인).
  - 검증: `cargo build`, `apply-manifest.ps1`, `cargo test keymap` 22·`settings::tests` 5·`extensions::tests` 3 passed, clippy 통과, 스크립트 문법 검사, `-DryRunStdout`·`-Steps` dry-run 정상.
  - 특이사항: 1차 실행 실패(아래) 원인과 수정을 보고 4.3에 적었다.

- **ORDER-06-R2 V3 시도 3번** (2026-11-07, leader 실행)
  - 무엇을 했나: 화면 차례에서 R2 V3를 세 번 시도했다.
  - 결과:
    - (1) `order06-r2-v3.ps1` 세션 시작 실패 — `session.json`이 생기지 않았다(`verify/reviews/measure-ORDER-06-R2-run1-failed/`). 원인: 스크립트가 백업 폴더를 미리 만들어 `session.ps1`의 "기존 백업 덮어쓰지 않음" 검사에 걸렸고, 출력이 로그에 남지 않았다(C-29 보고 4.3). checker가 고쳤다.
    - (2) 고친 스크립트로 세션 시작 뒤 멈춤(`measure-ORDER-06-R2-run2-hung/`). leader가 timeout으로 끊고 앱 PID 41412만 닫은 뒤 `session.ps1 -Action Stop`으로 앱 데이터를 복원했다. 복원본이 백업과 바이트 동일함을 확인했다. 그 사이 사용자 `state.json`이 잠시 없었다. checker가 `session.ps1` 실제 실행 시험을 하려던 것을 leader가 거절했다(백업 삭제 위험).
    - (3) R1 스크립트(`order06-r1-v3.ps1`)를 `-Steps`로 다시 실행했으나 앞 단계를 건너뛰어 프로젝트가 열리지 않았고, 실행된 단계가 없었다(`measure-ORDER-06-R2-run3-noproject/`).
  - 검증: V3 없음(측정 단계 0). 사용자 앱 데이터는 (2) 뒤 백업과 바이트 동일.
  - 특이사항: Keymap Editor V3 캡처(와 R2 화면 항목)는 다음 화면 차례(Phase 7 V3와 함께)로 미뤘다.

- **W-26 ORDER-06-R2 기록** (2026-11-07)
  - 무엇을 했나: 위 K-17·K-18·C-29·V3 시도를 적고, SPEC R-2 Keymap·Settings·Extensions·"v" 버튼 표를 K-17·K-18 결과로(C-29 대조 표 기준) 고쳤다. PLAN 진행 현황 Phase 6을 review(core-leader 판정 대기)로 바꿨다. 카드 `cards/W-26.md`.
  - 결과: `SPEC.md`, `PROGRESS.md`, `PLAN.md` 수정. tauri와 남은 차이 — Keymap·Settings·"v" 버튼 없음, Extensions 3·4(자원 목록·자동 읽기)는 Phase 7.
  - 검증: 문서만 바꿨다(V0).
  - 특이사항: 없음.

- **Phase 6 종료 판정** (2026-11-07)
  - 무엇을 했나: core-leader가 ORDER-06-R2 보고를 보고 Phase 6을 판정했다(core-leader 2026-11-07, 사용자 위임 core D-13).
  - 결과: "ORDER-06-R2 충족. Phase 6 종료 판정: 충족(I-2·I-17, D-15 범위, 두 갈래 세부 일치)". R2 커밋 `271ebf6`, push 완료.
  - 검증: core-leader 판정(gpui-leader 전달, W-27).
  - 특이사항: ORDER-06-R2 V3 캡처(Keymap Editor·Extensions·"v" 버튼)는 Phase 7 V3에서 함께 한다(ORDER-07 추가 (a)).

### Phase 7 — 테마·아이콘 테마

- **ORDER-07 받음** (2026-11-07)
  - 무엇을 했나: core-leader의 ORDER-07(R-3·R-4, I-3·I-4, core D-8)을 받았다.
  - 결과:
    - 추가 지시 (a): ORDER-06-R2 Keymap Editor·Extensions·"v" 버튼 V3 캡처를 Phase 7 V3에서 함께 한다.
    - 추가 지시 (b): 측정 세션 도구를 단단히 한다(C-30). checker는 `tools/measure/session.ps1`을 직접 실행하지 않는다(HERDR-SETUP 5.4).
    - 버전 고정: 이 PC 설치 확장 catppuccin 0.2.27, catppuccin-icons 1.24.0, macos-classic 0.4.0(leader가 `extension.toml`을 읽기만 해서 확인). Zed 커밋 `4304dec732a75505066de5ce2dbbfb2bec369498`.
    - 복사본 위치·다시 채우기·없을 때 모습·기본값은 DECISIONS D-11.
  - 검증: 해당 없음(지시 기록).
  - 특이사항: 없음.

- **W-27 Phase 6 종료, Phase 7 시작 기록** (2026-11-07)
  - 무엇을 했나: PLAN 진행 현황 Phase 6을 done(커밋 `271ebf6`), Phase 7을 doing으로 바꾸고, 위 Phase 6 종료 판정·ORDER-07 추가 지시를 적었다. DECISIONS D-11(테마·아이콘 테마 복사본)과 HERDR-SETUP 5.4 측정 세션 규칙을 더했다. 카드 `cards/W-27.md`.
  - 결과: `PLAN.md`, `PROGRESS.md`, `DECISIONS.md`, `HERDR-SETUP.md` 수정.
  - 검증: 문서만 바꿨다(V0).
  - 특이사항: `.gitignore`에 두 폴더를 넣는 것과 `tools/fetch-zed-themes.ps1`은 아직 없다(writer 소유 아님).

- **coder 모델 교체 기록** (2026-11-07, W-28, core D-16)
  - 무엇을 했나: 2026-11-07 12:14에 `gpui-coder`를 Codex(GPT-6.1-Sol medium, 5시간 한도 6% 남음)에서 Claude Code Sonnet 5.5 high로 바꿨다. pane `wD:pE`, 이름 그대로.
  - 결과: 사용자 결정 — 14:00 Codex 초기화 뒤 그때 진행 중인 카드가 끝나는 때에 Codex로 되돌리고 시각을 `HERDR-SETUP.md` 2.1과 이 문서에 적는다. 되돌린 시각: 2026-11-07 14:05(아래 W-29 기록).
  - 검증: 해당 없음(구성 기록).
  - 특이사항: K-20은 Sonnet으로 했다.

- **K-19 테마 복사본과 테마 적용** (2026-11-07)
  - 무엇을 했나: `tools/fetch-zed-themes.ps1`로 테마 복사본을 `resources/zed-themes/`(git 제외)에 채우고, 복사한 Zed 테마 JSON을 gpui-kit 테마와 앱 토큰에 대응했다. 기본 테마 One Dark. 테마 이름 목록 API(`theme::names()`). K-04-R1·K-07의 고정 One Light 색은 테마 JSON에서 읽는다. 변경 `.gitignore`, `tools/fetch-zed-themes.ps1`, `src/ui/theme.rs`·`settings.rs`·`title_bar.rs`. 카드 `cards/K-19.md`.
  - 결과: 완료. 21개 테마(Zed `4304dec` 11, catppuccin/zed v0.2.27 → `83fe57b` 8, macos-classic v0.4.0 → `22266e1` 2), JSON 17개. 대응 표는 SPEC R-4. 복사본이 없으면 gpui-kit 초기 테마로 뜨고 stderr 경고 한 번.
  - 검증: V2. build·apply-manifest PASS, theme 테스트 4/4·settings 테스트 5/5 PASS, clippy PASS. 21개 테마 전부 주요 토큰 → 적용 색 비교.
  - 특이사항: 실측 필요(Phase 7 V3) — One Dark 전체 UI, 테마 전환 뒤 폰트·배치 유지, 현재 줄 T-05.05, 줄 번호 T-05.07/08. 사용자 확인 — 대표 밝은·어두운 테마의 대비·인상. 깨끗한 checkout에서는 fetch 스크립트를 먼저 돌려야 색 테스트가 통과한다.

- **K-20 선택기 두 개·아이콘 테마·Settings/Extensions 연결** (2026-11-07, Sonnet 5.5 high로 수행)
  - 무엇을 했나: "Select Theme…"(`Ctrl-K Ctrl-T`, v → Themes…)·"Select Icon Theme…"(v → Icon Themes…) 모달(검색, 현재 테마 체크, 이동 시 미리 보기, Enter·클릭 적용과 `settings.json` 저장, 확정 전 닫으면 원래 테마로, `Install …` → Extensions 범주). 아이콘 테마 복사본(`catppuccin/zed-icons` v1.24.0 → `fe864c9`, `resources/zed-icon-themes/`, git 제외)과 Zed (Default) 연결표 JSON. 파일 트리 아이콘을 아이콘 테마로. Settings 드롭다운을 전체 목록으로, Extensions 탭을 복사본 manifest로. 신규 `src/ui/theme_selector.rs`·`icon_theme.rs`, 그 밖 `src/ui/`·`src/keymap/` 여러 파일, fetch 스크립트, `.gitignore`. 카드 `cards/K-20.md`.
  - 결과: 완료. 아이콘 대응은 SPEC R-3.
  - 검증: V1. build·apply-manifest PASS, `cargo test` 243/243 PASS, clippy PASS. 미리 보기·Esc 복원의 App 경로는 `gpui::test`를 쓸 수 없어(`test-support` 없음, 의존성 변경 금지) 코드 확인, 로직은 순수 함수로 테스트.
  - 특이사항:
    - 탭 아이콘은 바꾸지 않았다(Zed 기본값은 탭에 파일 아이콘 없음). leader 판단 필요.
    - 스펙에 없는 값(`spec: none (app value)`): 선택기 너비 544px, 목록 최대 높이 320px, 간격 8px(`metrics::selector`). Zed 값 확인 카드 필요.
    - 실측 필요(Phase 7 V3): 선택기 모달 크기·목록 높이·행 간격·체크 위치, 미리 보기 때 모달 색 갱신, 트리 아이콘 16px와 Catppuccin 컬러 렌더링, v 메뉴 6행 키보드 이동, Dialog 안 Esc·바깥 클릭·↑↓/Enter 동작.
    - 사용자 확인: Catppuccin 컬러 아이콘 인상, Monochrome 대비, 미리 보기 중 깜박임.

- **C-30 측정 세션 도구 단단히** (2026-11-07, ORDER-07 추가 (b))
  - 무엇을 했나: checker가 `tools/measure/session.ps1`과 측정 스크립트(order03·04·05·06·06-r1·06-r2)를 고쳤다. Start는 앱이 떠 있으면 아무것도 건드리지 않고 오류, 백업 해시·길이 검증 뒤에만 초기화, 초기화·픽스처·기동 실패 시 원래 데이터로 되돌림. Stop은 앱이 떠 있으면 오류, 복원 뒤 바이트 동일 확인이 된 때만 `Remove-BackupSafely`로 백업을 지운다. settings.json·keymap.json을 session.ps1 백업으로 모았다. session 호출을 파이프 없는 변수 캡처로 통일하고, 단계 생략 때도 프로젝트 열기를 먼저 한다. 카드 `cards/C-30.md`.
  - 결과: 완료. 실패 시나리오 표(`cards/C-30.report.md` 3장):

    | # | 실패 시나리오 | 앱 데이터 | 백업 폴더 |
    |---|---|---|---|
    | S-1 | Start 때 앱이 떠 있음 | 그대로 | 만들지 않음 |
    | S-2 | Start 때 이전 백업 폴더가 있음 | 그대로 | 기존 것 보존 |
    | S-3 | 백업 복사 실패·해시 불일치 | 그대로 | 불완전 백업 남김 |
    | S-4 | 픽스처 생성 실패·실행 파일 없음 | 원래대로 되돌림 | 보존 |
    | S-5 | 기동 직후 앱 비정상 종료 | 원래대로 되돌림 | 보존 |
    | S-6 | 측정 스크립트 단계 실패 | `finally`의 Stop으로 복원 | 보존 |
    | S-7 | Stop 때 앱이 떠 있음 | 복원 보류 | 보존 |
    | S-8 | 복원 뒤 해시·바이트 불일치 | 불일치 감지·오류 | 영구 보존 |
    | S-9 | 바이트 동일 미확인 상태에서 백업 정리 | 그대로 | 삭제 거부 |

  - 검증: V0 정적 점검. 7개 스크립트 문법 OK, 6개 측정 스크립트 `-DryRunStdout` PASS. session.ps1 Start/Stop은 카드 규칙대로 실행하지 않았다.
  - 특이사항: 실제 Start/Stop 동작은 다음 V3 세션에서 처음 돈다.

- **버전 고정** (2026-11-07, ORDER-07 2장, D-11)
  - 무엇을 했나: 복사 출처를 아래로 고정했다. 다른 버전은 쓰지 않는다.
  - 결과: Zed 커밋 `4304dec732a75505066de5ce2dbbfb2bec369498`, catppuccin/zed v0.2.27(commit `83fe57ba356a3b4dc4ac78b8d98d8ae95e093e45`), huacnlee/zed-theme-macos-classic v0.4.0(`22266e11c4b8962be2e259011251b4016ff00552`), catppuccin/zed-icons v1.24.0(`fe864c992c5da1e417e5897b741b7de9b90830e0`). 확장 셋은 이 PC 설치 버전과 같다.
  - 검증: K-19·K-20 보고의 실제 checkout commit.
  - 특이사항: 없음.

- **W-28 Phase 7 기록** (2026-11-07)
  - 무엇을 했나: HERDR-SETUP 1장·2.1에 coder 모델 교체, PROGRESS에 위 기록, SPEC R-4에 테마 대응 표·기본 테마, R-3에 아이콘 테마 대응을 적었다. tauri SPEC과의 차이는 `cards/W-28.report.md`. 카드 `cards/W-28.md`.
  - 결과: `HERDR-SETUP.md`, `PROGRESS.md`, `SPEC.md` 수정, `cards/W-28.report.md` 작성.
  - 검증: 문서만 바꿨다(V0).
  - 특이사항: 없음.

- **coder 모델 되돌림** (2026-11-07, 사용자 결정)
  - 무엇을 했나: 2026-11-07 14:05에 `gpui-coder`를 Claude Code Sonnet 5.5 high에서 Codex GPT-6.1-Sol medium으로 되돌렸다. 14:00 한도 초기화 뒤, K-20이 끝난 카드 경계다.
  - 결과: 완료. `HERDR-SETUP.md` 1장·2.1에 시각을 적었다.
  - 검증: 해당 없음(구성 기록).
  - 특이사항: Codex가 시작할 때 자체 업데이트로 한 번 종료돼 다시 띄웠다.

- **Phase 7 V3 시도** (2026-11-07, C-32)
  - 무엇을 했나: 테마·아이콘 테마와 ORDER-06-R2 화면을 V3로 측정했다. 세 번 시도했다.
  - 결과:
    - 1차(13:02): 스크립트가 `session.json`에 없는 hwnd를 읽었고, 그 줄이 `try` 밖이라 앱 데이터가 복원되지 않았다. leader가 앱 PID를 닫고 복원했다(바이트 동일).
    - 2차(13:19): 캡처 함수 결함으로 앱 캡처가 전부 실패했고 Zed 새 창을 못 찾았다. 앱 데이터·Zed 설정은 바뀌지 않았다.
    - 3차(13:35): 대부분 PASS. 판정 `verify/reviews/measure-ORDER-07.md`.
      - 테마: 21개 테마 토큰 대응 불일치 0(V1, 캡처한 6개 테마는 V2).
      - Zed 선택기 실측: 모달 너비 544(앱과 같음), 검색칸 38, 목록 384, 요소 사이 간격 0. 앱 값(검색 32·목록 320·간격 8)은 K-21로 맞춘다. 치수는 SPEC R-4.
      - 측정 불가: 앱 선택기 열림·미리 보기·Esc(포커스 문제), 아이콘 테마 트리(단일 파일만 열림). V1 근거로 두고 재측정 예정.
  - 검증: checker V3(C-32).
  - 특이사항: 측정 불가 항목은 다음 화면 차례에 재측정한다.

- **W-29 Phase 7 기록** (2026-11-07)
  - 무엇을 했나: HERDR-SETUP 1장·2.1에 coder 되돌림 시각, PROGRESS에 위 두 기록, SPEC R-4에 선택기 Zed 실측 치수를 적었다. 카드 `cards/W-29.md`.
  - 결과: `HERDR-SETUP.md`, `PROGRESS.md`, `SPEC.md` 수정.
  - 검증: 문서만 바꿨다(V0).
  - 특이사항: 없음.

- **W-30 선택기 치수 spec ID 추가** (2026-11-07, core-leader DECISION, ORDER-07 공통 3)
  - 무엇을 했나: `spec/zed-metrics.toml` `[picker]`에 선택기 치수 새 ID를 더했다. `01-LAYOUT.md` 4.13 본문 값(창 높이 마진 160, 그림자 4겹, 행 글자 14·줄 높이 1.618·행 높이 30.65, 빈 결과 위아래 8, 체크 16)과 gpui V3 Zed 실측(`theme_selector.measured.*`: 너비 544, 모달 462, 검색칸 38, 목록 384·12행, 간격 0, 구분선 1, 푸터 38). 실측 조건 `conditions.desktop_measure_100`을 새로 두었다. 기존 ID는 바꾸지 않았다. `spec/INDEX.md`에 색인. 카드 `cards/W-30.md`.
  - 결과: 새 ID 목록과 coder에게 넘길 `metrics::selector` 주석 대응은 `cards/W-30.report.md`. 두 출처가 다른 2건(384가 모달인지 목록인지, 행 높이 30.65와 실측 피치 31~32)을 `spec/ambiguous.md` 5절에 올렸다(미결).
  - 검증: V0. `tomllib`로 toml 파싱 OK.
  - 특이사항: 행 높이(`ROW_HEIGHT` 32)는 전용 ID가 없고 ambiguous 결정을 기다린다.

- **K-21 선택기 치수를 Zed 실측으로** (2026-11-07)
  - 무엇을 했나: 테마·아이콘 테마 선택기 두 개에 Zed 실측 치수(`measure-ORDER-07.md` 3.2)를 적용했다. 너비 544, 검색칸 외곽 38, 목록 최대 384, 간격 0, 구분선 1, 푸터 38, 다이얼로그 기본 패딩 0. 행은 선택기에만 32px 높이·축소 금지. 변경 `src/ui/metrics.rs`·`theme_selector.rs`. 카드 `cards/K-21.md`.
  - 결과: 완료.
  - 검증: V1. build·apply-manifest PASS, `theme_selector::tests` 4/4 PASS(치수 상수·12행 높이), clippy PASS.
  - 특이사항: 기존 행은 14 × 1.618 ≈ 22.65px로 Zed 피치 31~32와 달랐다. gpui-kit Input의 사용자 지정 크기가 24px로 처리돼 `Styled::h`로 38px을 줬다. 실측 필요 — 두 선택기의 치수와 경계 접합.

- **K-22 core 공통 결정 반영** (2026-11-07, core-leader DECISION, ORDER-07 공통)
  - 무엇을 했나: 공통 결정 다섯 가지를 반영했다. (1) 탭에 파일 아이콘 없음(코드 확인만, 변경 없음). (2) Extensions 탭은 `extension.toml`이 있는 확장만 카드 3장(Catppuccin 0.2.27, Catppuccin Icons 1.24.0, macOS Classic 0.4.0). (3) 토큰 대체 순서 JSON → T-26 파생 → 같은 appearance One → T-26 고정값(tauri D-8과 같게). (4) 목록 순서 dark 이름순 → light 이름순, 아이콘 테마 9개(Monochrome 4 포함). (5) 선택기 스크롤바는 목록 위 포인터 때만. 변경 `src/ui/extensions.rs`·`theme.rs`·`icon_theme.rs`·`theme_selector.rs`. 카드 `cards/K-22.md`.
  - 결과: 완료. SPEC R-3·R-4에 반영.
  - 검증: V1. build·apply-manifest PASS, 관련 테스트 26/26 PASS(theme 6, icon_theme 5, extensions 5, theme_selector 4, settings 6), clippy PASS.
  - 특이사항: One에도 없는 일반 토큰은 gpui-kit 초기값을 유지한다(Zed fallback 테마의 완전 재현이 아님). 실측 필요 — 선택기 Hover 스크롤바 표시·숨김.

- **Phase 7 V3 4·5차** (2026-11-07)
  - 무엇을 했나: 3차에서 측정 불가였던 항목을 다시 측정했다.
  - 결과:
    - 4차(14:29): 앱 6단계 PASS — 기본 One Dark, 선택기 열림, 미리 보기(↓), Esc 복원, 아이콘 테마 Catppuccin, v 버튼 크롭(`verify/reviews/measure-ORDER-07-run4/summary.json`).
    - 5차(Zed 트리만): 스크립트가 fixture를 앱 단계에서만 만들어 시작 전에 끝났다. Zed 설정·창은 바뀌지 않았다(`verify/reviews/measure-ORDER-07-run5-zedonly/`).
    - Zed 트리 아이콘 비교는 측정 불가로 두고 V1 근거로 판정한다. 판정 `verify/reviews/measure-ORDER-07.md`.
  - 검증: checker V3.
  - 특이사항: Zed 트리 아이콘 비교는 재측정 예정.

- **W-31 Phase 7 마무리 기록** (2026-11-07)
  - 무엇을 했나: PROGRESS에 K-21·K-22·V3 4·5차, SPEC R-3·R-4에 K-21·K-22·W-30 결과(목록 순서, 아이콘 테마 9개, Extensions 카드 3장, 토큰 대체 순서, 선택기 spec ID·스크롤바, 탭 아이콘 없음)를 적고 PLAN Phase 7을 review로 바꿨다. 카드 `cards/W-31.md`.
  - 결과: `PROGRESS.md`, `SPEC.md`, `PLAN.md` 수정.
  - 검증: 문서만 바꿨다(V0).
  - 특이사항: R-3 판정 방법의 "탭의 파일 아이콘"은 core ITEMS 문구라 바꾸지 않았다(core D-11). 탭에 아이콘이 없다는 공통 결정과 어긋나므로 core-leader 확인이 필요하다. `measure-ORDER-07.md`는 3차 기준이며 4·5차 결과는 아직 담고 있지 않다.

- **Phase 7 종료 판정** (2026-11-07)
  - 무엇을 했나: core-leader가 ORDER-07 보고를 보고 Phase 7을 판정했다(core-leader 2026-11-07, 사용자 위임 core D-13).
  - 결과: "Phase 7 종료 판정: 충족(I-3·I-4 두 갈래, 같은 출처·버전·기본값)". 커밋 `158061a`, push 완료.
  - 검증: core-leader 판정(gpui-leader 전달, W-32).
  - 특이사항: 없음.

- **W-32 Phase 7 종료, Phase 8 시작 기록** (2026-11-07)
  - 무엇을 했나: PLAN 진행 현황 Phase 7을 done(커밋 `158061a`), Phase 8을 doing으로 바꾸고, 위 Phase 7 종료 판정을 적었다. DECISIONS 적용 표에 core D-17(ORDER-08 범위: 언어 서버 없음, 진단은 문제 없음 화면, Project Search 실제 검색) 행을 더했다. 카드 `cards/W-32.md`.
  - 결과: `PLAN.md`, `PROGRESS.md`, `DECISIONS.md` 수정.
  - 검증: 문서만 바꿨다(V0).
  - 특이사항: 없음.

### Phase 8 — 상태 바

- **W-33 상태 바 왼쪽 구분선 spec ID 추가** (2026-11-07, core-leader ORDER)
  - 무엇을 했나: `spec/zed-metrics.toml` `[statusbar]`에 왼쪽 버튼 사이 세로 구분선 새 ID 6개(`left_divider.width` 1, `height` 16, `y_top` 829, `color` border 토큰, `x_after_sidebar_toggle` 28, `x_after_file_tree` 59)를 조건 `desktop_measure_100`으로 더하고 `spec/INDEX.md`에 색인했다. 근거는 Zed `4304dec732` `status_bar.rs` 283·287행과 tauri 캡처 `ORDER-08/zed-cursor.png`(One Dark). 기존 ID는 바꾸지 않았다. 카드 `cards/W-33.md`.
  - 결과: ID 목록은 `cards/W-33.report.md`. coder가 K-24에서 그린다.
  - 검증: V0. `tomllib`로 toml 파싱 OK.
  - 특이사항: 없음.

- **W-34 tauri의 Zed 확인 결과를 SPEC으로** (2026-11-07, core ORDER-08 2장)
  - 무엇을 했나: tauri SPEC R-5·R-19·R-22 "Zed 확인(2026-11-07)"과 캡처(`D:\projects\workbench-tauri\specs\v0.5\verify\ORDER-08\`)를 읽고 이 레포 SPEC R-5·R-19·R-22에 같은 절로 옮겼다. R-5: 편집 중·선택 있음·열린 탭 없음·검색 결과 탭·Diagnostics 탭 표시, 선택 문구 규칙, 파일 형식 대응 표(tauri 표 = K-23 표). R-5 "열린 탭 없음" 미정이 풀렸다. R-19: dock 켜짐 강조색, 사이드바 열림 때 토글 위치. R-22: 왼쪽 버튼 순서·툴팁·단축키·구분선 spec ID(W-33), Add Project 없음, Project Search 탭 구성·동작·검색 대상, Diagnostics 탭. DECISIONS D-12(core 승인: `ignore 0.4.34`·`regex 1.13.1` 직접 의존성, Licenses 창 반영 필요). 카드 `cards/W-34.md`.
  - 결과: `SPEC.md`, `DECISIONS.md`, `PROGRESS.md` 수정. gpui 구현과 다른 곳 9건은 `cards/W-34.report.md`.
  - 검증: 문서만 바꿨다(V0).
  - 특이사항: 캡처는 열어 보지 않고 tauri 기록을 그대로 옮겼다. 선택 문구의 selections·lines 규칙과 검색 한도·바이너리 제외는 캡처가 아니라 tauri 구현(Zed 소스 기준)에서 옮겼다. 두 갈래의 미리보기 클릭 위치 산출이 다르다(블록 시작 줄·열 대 블록 시작 줄·열 1).

- **coder 모델 전환 기록** (2026-11-07, W-35, core D-16)
  - 무엇을 했나: 2026-11-07 15:52, K-25 완료 직후 카드 경계에서 `gpui-coder`를 Codex GPT-6.1-Sol medium에서 Claude Code Sonnet 5.5 high로 바꿨다. 사유: Codex 5시간 한도 5% 미만. 이름 그대로. `HERDR-SETUP.md` 1장·2.1에 적었다.
  - 결과: 복귀는 한도 초기화 뒤 카드 경계에서 leader가 따로 알린다(되돌린 시각 미정).
  - 검증: 해당 없음(구성 기록, V0).
  - 특이사항: 없음.

- **W-36 상태 바 ID 두 개 추가** (2026-11-07, core ORDER-08 core-leader 추가 지시)
  - 무엇을 했나: `spec/zed-metrics.toml` `[statusbar]`에 `padding_x` 4(Zed `status_bar.rs:153` Base04)와 `toggle_gap` 2(같은 파일 280–287 `gap_0p5`)를 조건 `desktop_measure_100`으로 더하고 `spec/INDEX.md`에 색인했다. 근거는 tauri 확인(실측 아이콘 시작 x 9·39·70·101, 구분선 x 28·59). 카드 `cards/W-36.md`.
  - 결과: 기존 ID는 바꾸지 않았다. 검색→진단 아이콘 간격 31이 `button_height` 22·`item_gap` 4와 맞지 않는 점은 `cards/W-36.report.md`에 확인 필요로 남겼다.
  - 검증: V0. `tomllib`로 toml 파싱 OK.
  - 특이사항: 없음.

- **K-25-R1 라이선스 테스트 기대값** (2026-11-07): `src/ui/app_menu.rs` 테스트의 `LICENSES.len()` 기대값을 6 → 8로 고치고 `ignore`·`regex` 라이선스 원문 파일이 실제로 있는지 검사를 더했다(C-34 REWORK). 결과: 완료. 검증: V1, `cargo test ui::app_menu` 4/4·clippy PASS.
- **K-26 상태 바 padding·토글 gap** (2026-11-07): `STATUS_BAR_PADDING`을 `padding_x`·`padding_y`로 나누고 `STATUS_TOGGLE_GAP`(2)을 더했다. 버튼 폭 억지 지정과 구분선 x 상수를 지워 구분선 x 28·59가 계산으로 나온다(`src/ui/metrics.rs`·`layout.rs`·`mod.rs`). 결과: 완료. layout_probe 테스트는 `#[gpui::test]` 환경이 없어 순수 계산 테스트로 대신했다. 검증: V2, build·apply-manifest·`cargo test k26`·`ui::` 191개·clippy PASS.
- **K-26-R1 진단 버튼 앞 빈 자리** (2026-11-07): search와 diagnostics 사이에 폭 0 빈 자리를 둬 `item_gap`이 한 번 더 들어가게 했다(Zed의 보이지 않는 lsp_button 자리). 버튼 박스 x 4·33·64·94(글리프 x 9·39·70·101)를 계산 테스트로 확인. 결과: 완료. 검증: V1, `cargo test k26`·clippy PASS. 실측 필요 — 박스 x·글리프 x(V3).
- **K-27 Project Search·Diagnostics 화면** (2026-11-07): `src/ui/search_view.rs` 렌더 전부(툴바 44 + border, Search 버튼 삭제, 둘째 줄 정렬, 빈 화면, 결과 머리줄·발췌 열, Diagnostics 툴바·"No problems in workspace")와 `metrics.rs` 상수. 결과: 완료. spec에 없던 값은 W-37로 기록. 검증: V1, `cargo test k27` 2·전체 258·clippy PASS. 실측 필요 — K-27 보고 "V3 대조 목록".
- **C-34 ORDER-08 리뷰·V3 스크립트** (2026-11-07): K-23~K-25 리뷰 REWORK(라이선스 테스트 기대값 → K-25-R1), `tools/measure/order08-v3.ps1` 9단계 작성. 결과: R-5·R-19·R-22 코드 리뷰 적합, 전체 테스트 254/255(1 실패, K-25-R1로 해소). 검증: V0, 문법·dry-run PASS.
- **C-34-R1 V3 스크립트 고침** (2026-11-07): 파일 열기를 order03 방식(트리 행 더블클릭)으로, fixture를 session fixture 안에 복사, 단계 독립(FAIL 뒤 계속·PID 확인), 판정 문구 제거, 덤프 box 좌표만 사용, Replace 금지. 결과: 완료. 검증: V0, 문법·dry-run PASS.
- **C-34-R2 1차 실행(16:29) 결과 반영** (2026-11-07): Crop-Image 인자 오류, 상태 바 box 이름(`status-icon-*`), 트리 30행 밖 파일 → 하위 폴더 `00-order08\`, 새 snapshot 대기(`Wait-NextSnapshot`). 결과: 완료. 1차 실행의 사용자 데이터는 정상 복원(`verify/reviews/measure-ORDER-08/`). 검증: V0, 문법·dry-run PASS.

- **W-37 K-27 값 기록** (2026-11-07, core ORDER-08): K-27 값 표 가운데 Zed 파일:줄 출처 8개를 `spec/zed-metrics.toml` `[editor]`에 올리고(`search_input.max_width`, `search_results.header.*` 6개, `search_results.matches.padding_left`) `spec/INDEX.md`에 색인했다. `search_results.count.min_width`는 기존 `editor.search_results_count.min_width`(40, E-067)와 같아 새로 두지 않았다. 캡처 추정(발췌 열 32·36/24), 앱 구성값(뒤 컨트롤 150), `rounded_sm` 2는 `spec/ambiguous.md` 6절. 결과: ID 대응은 `cards/W-37.report.md`. 검증: V0, `tomllib` 파싱 OK.

- **W-38 tauri R-22 값 11개를 tauri와 같은 ID로** (2026-11-07, core ORDER-08 core-leader 추가 지시): W-37에서 `[editor]` 아래 둔 `search_results.*` 7개를 새 섹션 `[search_results]`로 옮겨 전체 ID를 tauri와 같게 했다(`editor.search_results.header.*` → `search_results.header.*`, `editor.search_results.matches.padding_left` → `search_results.matches.padding_left`, leader 승인, 코드는 아직 toml 키를 쓰지 않음). `search_results.header.radius` 2(core 지시, 확인 필요는 `spec/ambiguous.md` 6절에 남음)와 `search_results.count.min_width` 40(같은 값 `editor.search_results_count.min_width`)을 더했다. `editor.search_input.max_width`는 그대로. L-84 닫기 버튼 색을 `[titlebar]` `window_button.close.hover_background`·`hover_foreground`·`active_opacity`로 올렸다. `spec/INDEX.md` 맞춤. 결과: 올린 ID와 gpui 상수 대조(11개 모두 같은 값)는 `cards/W-38.report.md`. 검증: V0, `tomllib` 파싱 OK.

- **K-28 Project Search 툴바·빈 화면·상태 바 오른쪽 맞춤** (2026-11-07): 접기 아이콘 `chevron_down_up`/`chevron_up_down`, 검색 상자 끝 1167에 맞춘 오른쪽 여백·뒤 컨트롤 폭, 입력 글자 시작 291, 결과 머리 띠 전체 폭, 빈 화면 행 간격, 상태 바 오른쪽 `{줄:열}`·파일 형식을 두 항목(사이 gap 8)으로(`src/ui/search_view.rs`·`metrics.rs`·`status.rs`·`layout.rs`·`mod.rs`). 결과: 완료, 캡처에 맞춘 값(오른쪽 여백 등)은 소스 값이 아니라 다른 창 크기에서 다를 수 있음. 검증: V1, 전체 `cargo test` 259·clippy PASS. 실측 필요 — K-28 보고 V3 목록.
- **K-29 Replace는 버퍼만, 툴바 아이콘 x, 빈 화면, W-38 ID 주석** (2026-11-07): Replace Next·All이 디스크에 쓰지 않고 버퍼를 바꿔 탭을 수정됨으로 둔다(스냅샷 비교 보호 유지, 바꾼 뒤 자동 재검색). 툴바 뒤 아이콘을 toml 값으로 역산 배치(‹ › 16, 토글 사이 2는 캡처 값), 빈 화면 부제 `pb`→`mb`와 글자 12로 축소(뒤에 W-39로 소스 값 14 결정), `metrics.rs` 주석을 W-38 ID로, `SEARCH_HEADER_LINES` 추가. 결과: 완료. 검증: V1, 전체 `cargo test` 260·clippy PASS, `k29_replacement_does_not_touch_the_disk`. 실측 필요 — K-29 보고 V3 목록.
- **W-39 Project Search 빈 화면 크기** (2026-11-07, core DECISION): Zed `4304dec` 소스 값(leader 확인)을 `spec/zed-metrics.toml` 새 섹션 `[project_search]` `landing.heading_size` 16·`subtitle_size` 14·`subtitle_margin_bottom` 8·`action_label_size` 14·`key_size` 14·`gap` 4로 올리고 `spec/INDEX.md`에 색인. SPEC R-22에 소스 값·캡처 측정(≈13px 해당)·결론(소스 14)을 적고, 차이를 `spec/ambiguous.md` 6절에 V3 재확인 대상으로. 결과: `cards/W-39.report.md`. 검증: V0, `tomllib` 파싱 OK.

- **K-30 빈 화면 Zed 소스 값으로** (2026-11-07): 제목 16, 부제 14 muted + 아래 8, 안내 줄 라벨·키 14, gap 4로 K-29의 12를 되돌리고, Label 줄 높이 phi(1.618)·안내 줄 Button 높이 22로 캡처 역산 값(`SEARCH_EMPTY_TITLE_HEIGHT` 등)을 바꿨다(`src/ui/search_view.rs`·`metrics.rs`). 결과: 완료. 검증: V1, 전체 `cargo test` 261·clippy PASS, `k30_landing_pitches`.
- **K-30-R1 빈 화면 spec 대조** (2026-11-07): `metrics.rs` 주석을 `project_search.landing.*` 전체 ID로 맞추고 `k30_landing_pitches`에 `assert_spec` 여섯 개를 붙였다(값 변경 없음). 결과: 완료. 검증: V1, `cargo test k30`·clippy PASS.
- **ORDER-08 V3 1차** (2026-11-07 16:29, leader 실행, `verify/reviews/measure-ORDER-08/`): 스크립트 버그(Crop-Image 인자, 상태 바 box 이름, 트리 30행 밖 파일)로 대부분 측정 불가 → C-34-R2. 사용자 앱 데이터는 바이트 동일 복원.
- **ORDER-08 V3 2차** (16:43, `measure-ORDER-08-run2/`): 상태 바 왼쪽 버튼 박스 x 4·33·64·94, 툴팁, 파일 형식 5종, Diagnostics 아이콘·문구 PASS(`verify/reviews/measure-ORDER-08.md`). 사용자 앱 데이터 바이트 동일 복원.
- **ORDER-08 V3 3차** (16:54, `measure-ORDER-08-run3/`): 상태 바 오른쪽 간격 19, 입력 박스 끝 1167·글자 시작 292, 결과 머리 띠 PASS. 사용자 앱 데이터 바이트 동일 복원.
- **ORDER-08 V3 4차** (17:03, `measure-ORDER-08-run4/`): 툴바 뒤 아이콘 잉크 x(±2)와 빈 화면 세로 잉크 y PASS. 빈 화면 글자 크기는 보류(뒤에 비교 오류로 밝혀짐). 사용자 앱 데이터 바이트 동일 복원.
- **ORDER-08 V3 5차** (17:12, `measure-ORDER-08-run5/`): 소스 값 14로 되돌린 빈 화면이 부제 잉크 폭 251 = Zed, 세로 잉크 y 같음, 블록 왼쪽 −129 대 Zed −131. 사용자 앱 데이터 바이트 동일 복원.
- **leader 실수: 측정 세션 직접 시작** (2026-11-07 16:40경): 1차 원인 조사 중 leader가 `session.ps1 -WhatIf`를 직접 실행해 실제 세션이 시작됐다(앱 PID 13080). 즉시 그 PID만 닫고 같은 세션 `Stop`으로 복원했고, 사용자 앱 데이터가 백업과 바이트 동일함을 확인했다.
- **W-40 빈 화면 글자 크기 차이 해소 기록** (2026-11-07): V3 5차 결과로 SPEC R-22 "Project Search 빈 화면 크기" 결론을 "소스 14 = 캡처"로 고치고 W-39의 "≈13px"이 측정 비교 오류였음을 적었다. `spec/ambiguous.md` 6절 그 행을 해소로. toml 값은 그대로. 결과: `SPEC.md`·`ambiguous.md`·`PROGRESS.md` 수정, `cards/W-40.report.md`. 검증: V0(문서만).

### Phase 9 — 탭 바와 편집 영역 상단

- **K-32 탭 툴팁 절대 경로(I-11), 탭 바 오른쪽 버튼 보이는 조건(I-23)** (2026-11-07, core ORDER-09): 파일 탭에 hover 툴팁으로 절대 경로(역슬래시 그대로, Zed `items.rs:706-726`), 오른쪽 버튼(+·분할·최대화)은 그 pane에 포커스가 있거나 분할 메뉴가 열려 있을 때만 보이고 숨길 때 자리를 남기지 않는다(Zed `pane.rs:4345-4352`, `only_pane` 예외 제거, 첫 화면도 같은 규칙). Project Search·Diagnostics·마크다운 미리보기 탭은 Zed 툴팁이 확인되지 않아 툴팁을 달지 않았다. 결과: 완료(`src/ui/pane_view.rs`·`layout.rs`). 검증: V1, `cargo build`·apply-manifest·전체 `cargo test` 261·clippy PASS. 실측 필요: 탭 툴팁 글자·지연·위치, 분할·트리 포커스일 때 오른쪽 버튼 유무.
- **W-41 ORDER-09 Zed 확인을 SPEC으로** (2026-11-07, core ORDER-09 [NOTICE]): tauri SPEC R-10·R-11·R-12·R-16·R-23 "Zed 확인(2026-11-07)"(커밋 `bba6cfc`, 캡처 `D:\projects\workbench-tauri\specs\v0.5\verify\ORDER-09\`)을 이 레포 SPEC에 "Zed 확인(tauri, 2026-11-07)" 절로 옮기고 checker C-36의 Zed 소스 근거(파일:줄)를 근거 열로 덧붙였다. R-10에 기록 규칙(pane별, 탭을 떠날 때, 같은 파일 10줄 이상, 명시적 점프 항상, 닫힌 탭 다시 열기, 상한 1024는 tauri 확인), R-12에 core [DECISION](Phase 9는 경로 + 마크다운 제목 계층, 코드 심볼 계층은 Phase 11). R-12·R-16·R-23의 "미정"이 풀렸다. 결과: `SPEC.md`·`PROGRESS.md` 수정, `cards/W-41.report.md`. tauri 확인과 C-36이 어긋나는 곳은 없다. 검증: V0(문서만).

- **W-42 탭 바 휠 이동량 ID** (2026-11-07, core ORDER-09 I-16): `spec/zed-metrics.toml` `[tab]`에 `scroll.wheel_step` = 80px(조건 `desktop_measure_100`, 출처 tauri Zed 캡처 `ORDER-09/zed-wheel-*.png`, 소스 값 아님)을 넣고 `spec/INDEX.md` Tab Bar 행에 적었다. 카드의 `tab_bar.scroll.wheel_step`은 탭 바 섹션이 `[tab]`이라 `tab.scroll.wheel_step`이 됐다. 결과: `zed-metrics.toml`·`INDEX.md`·`PROGRESS.md` 수정, `cards/W-42.report.md`. 검증: V0(문서만, tomllib 파싱 확인).

- **K-33 탭 가로 스크롤** (2026-11-07, core ORDER-09 I-16): 탭 줄만 가로 스크롤(gpui `overflow_x_scroll`·`ScrollHandle`, pane마다 핸들), 뒤로/앞으로·끝 빈 자리·오른쪽 버튼은 고정. 세로 휠은 gpui가 가로로 바꾸고, 한 칸 80px은 행 글자 크기 80/(3×1.618)로 맞췄다. 활성 탭은 (활성, 탭 수)가 바뀔 때만 보이게 스크롤해 휠 위치가 유지된다. 새 탭 위치(활성 탭 오른쪽)는 이미 같아 확인만. 결과: 완료(`layout.rs`·`pane_view.rs`·`mod.rs`·`metrics.rs`). 검증: V1, `cargo build`·apply-manifest·전체 `cargo test` 263·clippy PASS. 생략·한계: 핀 탭 오른쪽 경계선(Zed `pane.rs:3720-3728`) 생략. 휠 80px는 시스템 휠 3줄 가정(Windows 설정이 다르면 같은 비율로 달라짐). 실측 필요: 휠 한 칸 이동량, 넘친 탭 잘림, 활성 탭 보이기.
- **K-34 경로 줄(breadcrumb)** (2026-11-07, core ORDER-09 I-12): 모든 단일 파일 편집기 탭에 툴바와 경로 줄(새 `breadcrumb.rs`). 폴더 하나면 상대 경로, 등록 폴더 둘 이상이면 `루트이름\상대경로`, 마크다운은 커서까지의 ATX 제목 계층(펜스 제외, 12조각 넘으면 앞 6·`⋯`·뒤 6), 코드 파일은 경로만(core [DECISION], 심볼 계층은 Phase 11). 경로·제목은 편집기 글꼴 14. 결과: 완료(`breadcrumb.rs`·`layout.rs`·`pane_view.rs`·`mod.rs`·`metrics.rs`, `tab["scroll.wheel_step"]` `assert_spec` 포함). 검증: V1, 전체 `cargo test` 268·clippy PASS. 생략·한계: 폴더 밖 파일은 파일 이름만(Zed 소스로 읽은 결과, tauri는 전체 경로라 checker 확인 예정). "폴더 둘 이상"은 등록 폴더 수로 판단. 코드 파일 탭에도 툴바가 생겨 편집 영역이 내려간다. 긴 경로는 잘림(Zed는 가로 스크롤). 실측 필요: R-12 표 전체(V3).
- **K-34-R1 경로 줄 색** (2026-11-07): 테마 적용 때 `BreadcrumbColors`(`›` = Zed `text.placeholder`, 제목 조각 = `syntax.title.color`, 없으면 `muted_foreground`)를 전역으로 갱신해 `editor_toolbar`가 쓴다. 경로 조각은 `muted_foreground` 그대로. 결과: 완료(`theme.rs`·`layout.rs`). 검증: V1, 전체 `cargo test` 269·clippy PASS. 한계: 제목 조각은 색만(굵기·글꼴 스타일 미반영). 실측 필요: `›`·제목 색(V3).
- **K-35 이동 기록(뒤로·앞으로)** (2026-11-07, core ORDER-09 I-10): pane별 `NavHistory`(새 `nav_history.rs`). 탭을 떠날 때·같은 파일 10줄 이상 이동을 기록, Project Search 결과 열기는 명시적 점프로 항상 기록, 같은 위치는 한 번만, 새 기록은 앞 스택을 비움, 닫힌 탭은 다시 열어 복귀, 갈 수 없는 항목은 건너뜀. 액션 `pane::GoBack`·`GoForward`, 키 `alt-left`·`alt--`·`alt-right`·`alt-=`, 마우스 뒤로/앞으로 버튼, Go 메뉴 Back·Forward, 탭 바 버튼은 스택이 비면 흐림. 결과: 완료(`nav_history.rs`·`pane.rs`·`pane_group.rs`·`pane_view.rs`·`layout.rs`·`mod.rs`·`keymap.rs`·`keymap/*`·`app_menu.rs`·`search_view.rs`). 검증: V1, 전체 `cargo test` 279(새 10)·clippy PASS. 생략·한계: 기록 상한 1024는 tauri 값(이 레포 checker 확인 전). Go to Line·Diagnostics 위치 이동은 이 앱에 없어 연결하지 않음. 커서 감지는 observe 단위, 위치는 줄·열이라 위쪽 편집 때 어긋날 수 있음. 실측 필요: 버튼 흐림, 툴팁 키, 단축키가 편집기에 먼저 잡히지 않는지, tauri 9단계 시나리오(V3).
- **coder Codex 복귀** (2026-11-07 19:27): K-35 완료 뒤 카드 경계에서 `gpui-coder`를 Claude Code Sonnet 5.5 high에서 Codex GPT-6.1-Sol medium으로 되돌렸다(core [DECISION] 사용자 지시). 옛 pane `wD:pE`가 Claude 종료 뒤 응답하지 않아 닫았고(탭 t5도 함께 닫힘), 새 탭 `code`(`wD:t7`)의 pane `wD:pH`에 Codex를 띄워 이름 `gpui-coder`를 붙였다. Codex는 처음 GPT-6.1 Terra high로 떠서 `/model` → GPT-6.1-Sol → Medium → s(세션)로 맞췄다(leader W-43). `HERDR-SETUP.md` 1장 표·2장 배치·2.1에 반영.
- **W-43 coder Codex 복귀 기록, K-33~K-35 PROGRESS** (2026-11-07): 위 복귀 사실을 HERDR-SETUP(1장 표 모델 칸, 2장 coder 탭·pane ID `wD:t7`·`wD:pH`, 2.1 Codex 한도 절)과 PROGRESS에 적고 K-33·K-34·K-34-R1·K-35를 각 보고에서 옮겼다. 결과: `HERDR-SETUP.md`·`PROGRESS.md` 수정, `cards/W-43.report.md`. 검증: V0(문서만).

- **K-36 넘칠 때 끝 드롭 자리** (2026-11-07, core ORDER-09 I-16): 끝 드롭 자리(최소 24px, `TAB_BAR_END_DROP_MIN_WIDTH`)를 탭 스크롤 행 안 마지막 자식으로 옮겨 탭과 함께 스크롤되게 했다(Zed `pane.rs:3721-3728`). 넘치지 않을 때는 `flex_1`로 남은 폭을 채운다. 행 probe의 마지막 자식은 `tab-bar-filler`. 결과: 완료(`src/ui/layout.rs`). 검증: V1, `cargo build`·apply-manifest·`cargo test ui::layout::tests` 5·clippy PASS. 실측 필요: 넘친 상태에서 오른쪽 버튼 앞 고정 24px가 없어지고 드롭 자리가 스크롤되는지, 비넘침·빈 탭의 폭 채움.
- **K-37 탭을 연 직후 활성 탭 보이기** (2026-11-07, core ORDER-09 I-16): gpui `scroll_to_item` 요청이 prepaint에서 이전 프레임 뷰포트(`state.bounds`·`overflow`)로 소비돼 새 탭이 안 보이던 문제(gpui `div.rs` 4381–4387·2044–2051·2066·4402–4447·2448/2505/2542, K-37 보고). `follow`가 요청을 `pending`으로 두고 행의 `on_children_prepainted`(배치 뒤, `div.rs:2099`)에서 한 번 더 요청하고 `window.refresh()`로 다음 프레임을 부른다. 같은 상태로는 다시 요청하지 않아 휠 위치는 유지. 결과: 완료(`src/ui/layout.rs`). 검증: V1, `cargo test ui::layout::tests` 5·clippy PASS. 범위 밖 발견: 스크롤 행 안 probe(탭·filler)가 덤프에 비거나 갱신되지 않는다 — gpui tracked scroll 분기(`div.rs:2042-2052`)가 `child_bounds`만 채우고 listener용 `children_bounds`를 채우지 않음. 실측 필요: 16번째 탭을 연 직후 보이기, 휠 위치 유지, 첫·마지막 탭, 닫은 뒤.
- **C-37 ORDER-09 V3 측정 스크립트** (2026-11-07): `tools/measure/order09-v3.ps1`(앱만, `order08-v3.ps1` 골격). 결과: 완료. 검증: 구문 검사·`-DryRun`(앱 실행 없음).
- **C-37-R1~R5 측정 스크립트 고치기** (2026-11-07): 회차마다 드러난 스크립트 문제를 고쳤다. R1(1차 뒤): 앱 창 찾기, finally에서 띄운 PID만 닫고 `session.ps1 Stop`으로 복원. R2(3차 뒤): 첫 레이아웃 스냅샷을 기다린 뒤 폴더 열기, 폴더 열기 호출 형식. R3(4차 뒤): 판정 하드코딩 제거, 단계별 새 세션, **입력 가드**(마우스는 그 점의 창이 띄운 PID의 창일 때만, 키는 앞 창이 앱일 때만; core-leader 규칙). R4(5차 뒤): 앞 창 얻기 실패와 스크립트 버그 2건. R5(6차 뒤): 남은 스크립트 버그 4건. 결과: 완료. 검증: 구문 검사·DryRun(dryrun~dryrun6)·stdout 리플레이 모의 실행, 앱 실행 없음.
- **ORDER-09 V3 1~7차** (2026-11-07, leader 실행, `verify/reviews/measure-ORDER-09-run*/`): 모든 회차에서 사용자 앱 데이터 바이트 동일 복원, 사용자 Zed는 바뀌지 않음.
  - 1차 19:32: 앱 창을 못 찾음(사용자 화면 조작). → C-37-R1
  - 2차 19:44, 3차 20:00: 폴더가 열리지 않음. → C-37-R2
  - 4차: 셋업 성공, step4·5 무효. **step5의 마우스 뒤로 버튼 입력 한 번이 사용자 브라우저로 갔다.** core-leader에 알렸고 입력 가드를 넣었다. → C-37-R3
  - 5차: foreground lock으로 앞 창을 얻지 못해 가드가 입력을 막음(다른 창 입력 0건). → C-37-R4
  - 6차·7차: 측정. 판정은 `specs/v0.5/verify/reviews/measure-ORDER-09.md`(C-38에서 작성).
- **W-44 ORDER-09 PROGRESS** (2026-11-07): K-36·K-37, C-37·C-37-R1~R5, V3 1~7차를 Phase 9에 기록하고 Phase 9 제목을 K-32 앞에 넣었다. coder 모델(19:27부터 Codex GPT-6.1-Sol medium)은 W-43 기록 그대로. 결과: `PROGRESS.md` 수정, `cards/W-44.report.md`. 검증: V0(문서만).

- **W-45 사이드바 줄 치수·panel.focused_border·휠 한 칸 공식값** (2026-11-07, core-leader [NOTICE] tauri ORDER-10 R-21): `spec/zed-metrics.toml` `[sidebar]`에 `item.border_right_width` 2·`item.separator_width` 1·`item.icon_slot_size` 16·`item.icon_gap` 6(Zed 소스, tauri R-21 표와 같은 ID), `[theme.fallback]` `panel.focused_border`를 `#62adef`에서 Zed `default_colors.rs:252` 다크 기본 `#2870bd`로(옛 값은 `spec/ambiguous.md` 3절, 라이트 `#0588f0`은 src에만), `tab["scroll.wheel_step"]`를 캡처 80에서 Zed 소스 공식 77.7(3 × 16 × 1.618, 조건 `default`)로 정정. `spec/INDEX.md` Sidebar·Tab Bar 행. 결과: `zed-metrics.toml`·`INDEX.md`·`ambiguous.md`·`PROGRESS.md` 수정, `cards/W-45.report.md`. 검증: V0(tomllib 파싱).

- **W-46 ORDER-10 Zed 확인을 SPEC R-21로** (2026-11-07, core ORDER-10 I-21): tauri SPEC R-21 "Zed 확인(2026-11-07)" 표·toml에 없는 값 표·구현 절과 tauri ORDER-10 보고(읽기만)를 이 레포 SPEC R-21에 "Zed 확인(tauri, 2026-11-07)" 절로 옮기고 행마다 toml ID 열을 붙였다. 현재 상태의 "약 220px" 옆에 "정정: 300(core 2026-11-07)". `panel.focused_border` 라이트(tauri `border.focused` 대 이 레포 `#0588f0`)는 "두 갈래 다름, core 확인 필요"로 적었다. 결과: `SPEC.md`·`PROGRESS.md` 수정, `cards/W-46.report.md`. tauri 표와 toml 값이 다른 곳은 그 라이트 값 하나. 검증: V0(문서만).

### Phase 10 — 폴더 보기 패널

- **K-39 사이드바 모양** (2026-11-07, core ORDER-10 I-21): tauri R-21 Zed 확인 표대로 폴더 줄을 고쳤다. 아이콘 14를 16 칸 가운데에, 아이콘과 이름 간격 4 → 6, 현재 폴더는 글자 `text`만(배경 제거), 줄 테두리 왼·위·아래 1·오른쪽 2(평소 투명), 키보드 선택(목록 포커스 + 커서 줄) 테두리를 `border.focused`에서 `panel.focused_border`로(테마 값 우선, 없거나 null이면 다크 #2870bd·라이트 #0588f0; pane 쪽 대체값 `#62adef`는 그대로), hover/누름은 `ghost_element_hover`/`ghost_element_active`, 둘째 줄부터 위 1px `border` 선(줄 바깥 wrapper), probe `sidebar-row-*`. 폭 300·줄 31·여백 8/6·footer는 이미 같아 유지. 결과: 완료(`src/ui/folders.rs`·`metrics.rs`·`theme.rs`, `k39_sidebar_rows_match_spec` `assert_spec` 9개). 검증: V1, `cargo build`·apply-manifest·`cargo test sidebar` 4·`folder` 5·`ui::theme::tests` 8·clippy PASS.
- **K-40 사이드바 머리 위 1px** (2026-11-07): Zed `sidebar.rs:7391-7399` 서버 장식(`Decorations::Server`)의 위 margin 1px을 `sidebar-header`에 더했다(높이 32 유지). 머리 아래 선 y 31 → 32, 첫 폴더 줄 y 33~63(Zed·tauri와 같음). 결과: 완료(`src/ui/layout.rs`). 검증: V1, `cargo test sidebar` 4·clippy PASS.
- **C-39·C-39-R1 측정 스크립트** (2026-11-07): `tools/measure/order10-v3.ps1`(`order09-v3.ps1`의 입력 가드·세션 관리·DryRun 재사용, 4단계). R1은 1차 결과로 step3 포커스 토글 가드와 덤프 기준 측정 좌표를 고쳤다. 결과: 완료. 검증: 구문 검사·DryRun(dryrun·dryrun2), 앱 실행 없음.
- **ORDER-10 V3 1·2차** (2026-11-07, leader 실행, `verify/reviews/measure-ORDER-10-run1-step1~4/`, `run2-step1·step3/`): 두 회차 모두 사용자 앱 데이터 바이트 동일 복원. 1차 결과로 C-39-R1. 측정표는 C-40이 쓰는 `specs/v0.5/verify/reviews/measure-ORDER-10.md`.
- **tauri와 다른 점** (core에 알림): (1) 사이드바 이름 글자 크기 — gpui 잉크 폭 104 = Zed 104, tauri 119. (2) `panel.focused_border` 라이트 — gpui #0588f0(Zed 소스), tauri `border.focused`(SPEC R-21 "두 갈래 다름, core 확인 필요").
- **W-47 ORDER-10 PROGRESS** (2026-11-07): 위 항목을 Phase 10에 기록. 결과: `PROGRESS.md` 수정, `cards/W-47.report.md`. 검증: V0(문서만).

- **C-40 ORDER-10 리뷰** (2026-11-07): K-39·K-40 코드 리뷰 PASS(동작 불변, `pane.focused_border` #62adef 유지와 `panel.focused_border` 분리 영향 없음), 전체 `cargo test` 282 passed, clippy 경고 0. 측정표 `verify/reviews/measure-ORDER-10.md`: 폭 300, 머리 아래 선 y 32·첫 줄 y 33~63·둘째 줄 위 선 y 64, 아이콘 x 9·이름 x 31·이름 잉크 폭 104, 현재 폴더 글자색·배경 없음, hover #363c46, 키보드 선택 #2870bd(왼 1·오른 2), footer 위 선 y 821 — 전 항목 Zed와 같음. 결과: PASS.
- **ORDER-10 커밋** (2026-11-07): `97d321c`·`df65ba7`. push는 core가 tauri ORDER-10-R1 뒤에 지시한다.
- **ORDER-10 tauri와 다른 점(마무리)**: 사이드바 이름 글자 크기 — gpui 잉크 폭 104 = Zed 104, tauri 119(core에 알림). `panel.focused_border` 라이트 #0588f0은 tauri K-46으로 같아졌다.

### Phase 11 — 구문 강조

- **W-48 tauri R-15를 SPEC R-15로** (2026-11-07, core ORDER-11 I-15·I-12): tauri SPEC R-15(언어 목록 24행·하이라이트 이름 대응·주입·outline, 현재 커밋 `208b900`)를 이 레포 SPEC R-15에 "Zed 확인(tauri, 2026-11-07)" 절로 글자 그대로 옮겼다. tauri 전용(빌드 출처·쿼리 정규식·"tauri 지금" 줄)은 "tauri 구현(참고)"로 묶고, gpui 방침(tree-sitter crate 버전 고정, Rust `regex`라 변환 불필요, 쿼리 복사본 위치·스크립트 이름은 미정 — K-41/K-42)을 적었다. 정해진 결과의 "형식 목록: 미정"을 풀고 core D-18·ORDER-11 2장 규칙을 적었다. 결과: `SPEC.md`·`PROGRESS.md` 수정, `cards/W-48.report.md`. 검증: V0(문서만).

- **K-41 구문 강조 조사** (2026-11-07, core ORDER-11): 코드 변경 없음(조사·계획). 결론: gpui-component의 `tree-sitter` feature는 끄고(core 0.26.13이라 Zed 0.28.0과 타입이 맞지 않음, 문법 버전도 다름), 앱이 Zed와 같은 core·문법으로 기존 `InputHighlighter` API(`set_highlighter_factory`, 정렬된 비중첩 style run)에 연결한다. Zed lock 정확 버전 표 19개(core 0.28.0·tree-sitter-language 0.1.8 git `803c6eb…`, 문법 17개 checksum/rev). HTML은 확장 rev `bfa075d`(Zed lock의 0.23.2는 테스트용이라 쓰지 않음). 쿼리 복사 위치 `resources/zed-languages/`(`.gitignore`)·스크립트 `tools/fetch-zed-languages.ps1`(원본 `crates/grammars/src/`). 카드 분할 제안 K-42A·K-42B·K-43A~C·K-44·K-45·K-46과 checker V3 카드. 미검증: core 0.28.0 MSVC 빌드·쿼리 전체 컴파일·큰 파일 지연·바이너리 증가(추정만), HTML rev의 Rust binding, `streaming-iterator`·`toml` runtime 허락 범위. 결과: `cards/K-41.report.md`. 검증: V0(읽기만).
- **W-49 ORDER-10 마무리·K-41·R-15 gpui 방침** (2026-11-07): Phase 10에 C-40·커밋·tauri 차이, Phase 11 제목과 K-41. SPEC R-15 "gpui 구현 방침"의 미정(복사본 위치·스크립트 이름)을 채우고 실행 중 config.toml을 읽지 않는 정적 언어 표 방침, "gpui 의존성(Zed Cargo.lock 그대로)" 표(K-41)를 옮겼다. 결과: `SPEC.md`·`PROGRESS.md` 수정, `cards/W-49.report.md`. 검증: V0(문서만).

- **coder Claude Sonnet 5.5 high로 바꿈** (2026-11-07 23:15): K-42A 완료 뒤 카드 경계에서 `gpui-coder`를 Codex GPT-6.1-Sol medium(5시간 한도 11% 남음)에서 Claude Code Sonnet 5.5 high(`claude --model sonnet --effort high`)로 바꿨다(core-leader [NOTICE] 사용자 지시, D-16). 같은 pane `wD:pH`, 이름 그대로. `/model`로 Sonnet 5.5·High effort 확인(leader W-50). 되돌리기: Codex 한도 초기화 뒤 사용자·core 지시가 있을 때. 되돌린 시각: 미정. `HERDR-SETUP.md` 1장 표·2.1에 반영.
- **W-50 coder 모델 변경 기록** (2026-11-07): 위 사실을 HERDR-SETUP(1장 표 모델 칸, 2.1 Codex 한도 절)과 PROGRESS에 적었다. 결과: `HERDR-SETUP.md`·`PROGRESS.md` 수정, `cards/W-50.report.md`. 검증: V0(문서만).

- **W-51 사이드바 글자 크기·미리보기 코드 블록 테두리·L-109 정정·ORDER-11 기대값** (2026-11-07, core-leader [NOTICE] tauri ORDER-11 보고): toml `[sidebar]` `item.font_size` 14, `[markdown_preview]` `code_block.border` 1·`code_block.border_color` `border_variant`(Zed `markdown.rs` 272~279). L-109 "테두리 없음" 정정은 `spec/ambiguous.md` 1절에 적었다(`docs/refs/`는 고치지 않음). SPEC R-12에 코드 파일 심볼 기대값 3개(rs·ts·py), R-15에 미리보기 코드 블록 결과(C-41). `spec/INDEX.md` Sidebar·Markdown Preview 행. C-41의 "테두리 없음"은 렌더러 `border: false`만 본 것으로 Zed 소스와 맞지 않음을 함께 적었다. 결과: `zed-metrics.toml`·`ambiguous.md`·`INDEX.md`·`SPEC.md`·`PROGRESS.md` 수정, `cards/W-51.report.md`. 검증: V0(tomllib 파싱).

- **K-42A 구문 강조 기반** (2026-11-07, core ORDER-11): tree-sitter core 0.28.0·tree-sitter-language 0.1.8(git `803c6eb`, `[patch.crates-io]`)과 Rust·JSON·Markdown 문법을 Zed lock 그대로 고정, 쿼리 복사본 `resources/zed-languages/`(`.gitignore`)·`tools/fetch-zed-languages.ps1`(Zed 4304dec, 24폴더·58쿼리), 정적 언어 표 `src/ui/syntax.rs`, Licenses. 결과: 완료. 검증: V1, `cargo build`·apply-manifest·`cargo test ui::syntax` 3·clippy PASS, 복사 스크립트 실제 실행 PASS.
- **K-42B 편집기 강조 연결** (2026-11-07): 테마 `style.syntax` 전체 투영(테마 바꾸면 다음 그리기부터), 캡처 → 점 경계 가장 긴 키, 겹침은 Zed처럼 맨 위 하나, 에디터마다 증분 `Tree`, `InputHighlighter` factory 설치와 `set_language`(탭 열기·읽기·이름 바꾸기). 문법·복사본 없으면 평문. 결과: 완료(`syntax.rs`·`theme.rs`·`pane_group.rs`·`panel_ops.rs`·`watch.rs`). 검증: V1, `cargo test ui::syntax` 10·clippy PASS. 한계: UI 스레드 파싱(`shortcut:`), 접기 없음, Save As 핸들러 없음.
- **K-43A C·C++·CSS** (2026-11-07): 세 문법 Zed lock 고정·연결·Licenses. HTML은 BLOCKED — 확장 rev `bfa075d`의 crate(0.20.2)가 core 0.28과 맞지 않음(cc 버전 충돌). 선택지 A(vendor C 소스 + build.rs)~D 보고. 결과: C·C++·CSS 완료. 검증: V1, `cargo test ui::syntax`·clippy PASS.
- **K-43A-R1 HTML (core 안 A)** (2026-11-07): 같은 rev의 생성 C 소스를 `vendor/tree-sitter-html/`(MIT, `SOURCE.md`에 출처 rev)에 두고 `build.rs`(`cc =1.10.0`)로 컴파일, `tree-sitter-language =0.1.8`, `grammar("html")`. 결과: 완료. 검증: V1, `cargo test ui::syntax` 13·clippy PASS.
- **K-43B Bash·Env·Diff·Git Commit·Go·Go Mod·Go Work** (2026-11-07): crate 6개 고정·연결·Licenses, 막힌 문법 없음. 결과: 완료. 검증: V1, `cargo test ui::syntax` 12·clippy PASS.
- **K-43C Python·JavaScript·TSX·TypeScript·YAML·JSDoc·Regex·Zed Keybind Context** (2026-11-07): crate 5개 고정·연결 8개 id·Licenses, vendor 없음. 문법 24개 연결 끝. 결과: 완료. 검증: V1, `cargo test ui::syntax` 14·clippy PASS.
- **K-44 주입** (2026-11-07): 주입 층 트리(루트 = 파일 언어, 자식 = 주입 층, combined·깊이 6 제한), 층 병합 색칠, 편집 후 바뀐 범위만 갱신. 마크다운 인라인(굵게·기울임·코드 스팬·링크)·펜스 언어·`html_block`·`---` 머리말 YAML, HTML 안 CSS·JS. 언어 없는 주입(comment·toml·latex·sql 등)은 바깥 색. 결과: 완료(`syntax.rs`만). 검증: V1, `cargo test ui::syntax` 20·clippy PASS. 디버그 측정(283 KB 마크다운): 첫 파싱 약 2.4초, 편집 1회 약 210 ms(대부분 루트 증분 파싱, 주입 갱신 약 1 ms), 릴리스 수치 없음. 알림: D: 디스크가 거의 가득 참(release 빌드 실패).
- **K-47 글자색·줄바꿈·탭 폭** (2026-11-07, V3 1차의 다른 점 3가지): 편집기 기본 글자색 `editor.foreground`(One Dark #acb2be), 자동 줄바꿈은 Zed 기본대로 Plain Text·Markdown·Git Commit만, 탭 표시 폭 4. `vendor/gpui-base`에 Window 없는 `apply_soft_wrap` 추가(K-47-R1에서 되돌릴 예정, core 결정). K-42A부터 깨져 있던 Licenses 개수 테스트도 고쳤다. 결과: 완료. 검증: V1, `cargo test ui::` 239·clippy PASS. 한계: Go `hard_tabs` 미적용. 알림: K-42B~K-44의 "테스트 통과"는 `ui::syntax`만이었다.
- **C-41 미리보기 코드 블록 Zed 확인** (2026-11-07): Zed 미리보기도 코드 블록을 편집기와 같은 테마 `syntax`로 언어별 강조, 언어 찾기는 info string 이름·확장자(대소문자 무시, 첫 단어 재시도), 없으면 평문. 이 레포는 강조 없음·배경 `theme.muted`·글자 16. 결과: `cards/C-41.report.md`. 검증: V0(소스 읽기). 그 보고의 "테두리 없음"은 맞지 않음(W-51).
- **C-42 ORDER-11 V3 측정 스크립트** (2026-11-07): `tools/measure/order11-v3.ps1`, step1(rs·json·md)~step6(미리보기), step5는 경로 줄 심볼 3개. 결과: 완료. 검증: 구문 검사·DryRun(6단계 0 errors), 앱 실행 없음.
- W-48~W-51은 위에 이미 기록되어 있다.
- **W-52 지금 상태 요약** (2026-11-08, core-leader [NOTICE] leader 컨텍스트 정리 준비): 아래 요약을 카드 그대로 옮기고 K-42A~K-47·C-41·C-42를 각 보고에서 기록했다. 결과: `PROGRESS.md` 수정, `cards/W-52.report.md`. 검증: V0(문서만).
- **W-53 R-15 언어 표에 TOML·git-firefly** (2026-11-08, core ORDER-11 [DECISION]): R-15 언어 표 HTML 행 뒤에 TOML 행(tauri 표 그대로)과 git-firefly 4개 행(gitattributes·gitconfig·gitignore·gitrebase, 문법·확장 전체 커밋, 라이선스 문법 MIT·확장 Apache-2.0)을 넣었다. git-firefly의 언어 이름·`path_suffixes`·쿼리 파일은 tauri 표에 없어 미정. gpui 방침(tree-sitter 0.28 크레이트, 안 맞으면 vendor C + build.rs, 쿼리는 확장 고정 커밋에서 `.gitignore` 복사본)과 "HTML만 넣었다" 문장 옆 core 결정을 적었다. 결과: `SPEC.md`·`PROGRESS.md` 수정, `cards/W-53.report.md`. 검증: V0(표 열 수 확인).
- **K-45 경로 줄 코드 심볼(outline)** (2026-11-08): `syntax.rs` outline 계산(Zed 규칙: 커서 ±1 범위, 바깥 → 안쪽 한 줄기, `@name`·`@context` 잇기, 편집기와 같은 색), `breadcrumb.rs` 색 범위 있는 조각, 툴바 그리기. [BLOCKED] — `D:` 디스크 부족(여유 약 290 MB)으로 링크 실패해 테스트를 돌리지 못함(`cargo check`·clippy는 통과). vendor/gpui-base에 `OutlineSymbol` 등을 넣었다.
- **K-45-R1 vendor 되돌리기·심볼 연결** (2026-11-08): K-45의 vendor/gpui-base 변경을 되돌리고(diff 없음) 앱 쪽 편집기별 칸(`SymbolSource`, `register_symbols`, `symbols_at`)으로 연결. 결과: 완료. 검증: V1, `cargo build`·`cargo test ui::` 243(tauri 픽스처로 R-12 21·18·21행 대조 포함, SKIP 없음)·clippy PASS. 마크다운은 줄 스캔 유지.
- **K-47-R1 줄바꿈 적용 방식 되돌리기** (2026-11-08, core 결정): K-47의 vendor `apply_soft_wrap`을 되돌리고(vendor diff 없음), 언어별 줄바꿈을 편집기별 칸(`EditorExtras`)에 기억해 `Workbench::render` 앞에서 Window가 있을 때 기존 `set_soft_wrap`으로 적용, 같은 값이면 다시 부르지 않음. 결과: 완료. 검증: V1, `cargo test ui::` 244·clippy PASS. 한계: 코드 파일 첫 프레임은 한 프레임 늦게 꺼짐.
- **K-46 미리보기 코드 블록 강조·테두리** (2026-11-08): 펜스 언어(편집기 주입과 같은 판정)로 편집기와 같은 색(`code_block_runs`, 공유 하이라이터, 테마 바뀌면 비움), 테두리 1px `border_variant`·반지름 6·안쪽 12. 결과: 완료(`syntax.rs`·`markdown_preview.rs`·`theme.rs`). 검증: V1, `cargo test ui::` 247·clippy PASS. 배경은 범위 밖으로 남김.
- **K-46-R1 미리보기 코드 블록 배경·간격** (2026-11-08, V3 2차 결과): 배경 `theme.background`(= `editor.background`), 위 여백 16 + 아래 -16으로 블록 사이 16. 결과: 완료(`markdown_preview.rs`·`theme.rs`). 검증: V1, `cargo test ui::` 248·clippy PASS.
- **K-48 TOML·git-firefly 문법** (2026-11-08, core [DECISION]): TOML·Git Config·Git Ignore는 vendor C 소스 + `build.rs`(크레이트가 `tree-sitter ~0.20` 의존), 쿼리는 확장 고정 커밋(`zed-extensions/toml@8e18e504`, `d1y/git_firefly@c63c6c02`)에서 `resources/zed-languages/`로(`tools/fetch-zed-languages.ps1`, 74파일), 라이선스(문법 MIT, 확장 Apache-2.0). [BLOCKED] gitattributes·gitrebase — coder 세션 권한 검사가 `Cargo.toml` 수정을 거부. leader가 `Cargo.toml`에 두 문법 줄(git rev)을 넣고 `cargo fetch`로 잠금(git-rebase 0.1.0, gitattributes 0.2.0). 검증: V1, 전체 `cargo test` 315·clippy PASS. 알림: 새 vendor C 파일은 LF 필요(`core.autocrlf=true`).
- **K-48-R1 gitattributes·gitrebase 마무리** (2026-11-08): 진행 중(언어 표·`grammar()`·라이선스·테스트).
- **ORDER-11 V3 2차** (2026-11-08, `verify/reviews/measure-ORDER-11-run2-step1·step2·step5·step6/`): 경로 줄 심볼 rs·py·ts의 글자·색·간격이 Zed 캡처와 같음, 마크다운 인라인·HTML 주입 같음. 미리보기 코드 블록은 배경 #2f343e·블록 사이 48로 Zed와 달라 → K-46-R1.
- **ORDER-11 V3 3차** (2026-11-08, `measure-ORDER-11-run3-step6/`): K-46-R1 뒤 미리보기 코드 블록 배경 #282c33·블록 사이 16·높이 130/78/104로 Zed와 같음.
  - 범위 밖 차이: 미리보기 중첩 번호 목록 `A.`/`B.`(Zed `1.`/`2.`), 제목 밑줄·본문 가운데 정렬 없음.
  - 2·3차 캡처 일부에 다른 앱 오버레이 창이 찍혀 그 캡처는 커밋하지 않는다.
- **W-54 R-15 git-firefly 칸 채우기** (2026-11-08): W-53의 미정 칸(언어 이름·`path_suffixes`·쿼리)을 복사본 `resources/zed-languages/<id>/`(K-48)로 채우고, R-15에 gpui 문법 방식 표(vendor: html·toml·git-config·gitignore / crate git rev: gitattributes·git-rebase)를 더했다. 위 K-45~K-48-R1과 V3 2·3차를 기록. 결과: `SPEC.md`·`PROGRESS.md` 수정, `cards/W-54.report.md`. 검증: V0(표 열 수 확인).
- **W-55 Phase 12 V4 목록 초안** (2026-11-08, core ORDER-11-R1 (2)): `specs/v0.5/reports/V4-LIST.md`(leader가 맡긴 파일)를 tauri V4-LIST 형식(머리 설명, 종류 V4·측정 못 함·결정·범위 밖, 표 6열)으로 썼다. ORDER-01~11(R 절 포함)·PROGRESS에서 37행, 근거는 보고 파일·줄 번호, 상태는 보고·PROGRESS로 확인되는 것만(없으면 "기록 없음"). 큰 파일 입력 지연은 K-49 진행 중. 결과: `reports/V4-LIST.md` 새로, `PROGRESS.md`, `cards/W-55.report.md`. 검증: V0(표 열 수).
- **K-49 큰 파일 입력 지연** (2026-11-08, core ORDER-11-R1 (1)): release 측정(i7-8700K, 편집기와 같은 `edit`·`reparse`·`runs`). 원인: 주입 질의를 루트에 돌려 "앞 주석 + 뒤 문자열" 꼴 패턴(html·sql·graphql 등 6개)이 주석마다 최상위 형제 전부를 훑음(TS `program` 아래 수천 개) — 바뀐 범위가 1바이트여도 비쌌다. 고침: 바뀐 범위에 닿는 **최상위 노드마다** 질의(`top_level_nodes`). 루트·최상위 형제 둘에 걸친 패턴은 못 잡지만 24개 언어 injections.scm에 그런 패턴이 없다.
  - 전/후(편집 한 글자 중앙/최대 ms, 첫 파싱 ms): TS `lib.webworker.d.ts` 1.56만 줄 189.2/195.6 → 3.4/3.8, 5,759 → 416. TS `lib.dom.d.ts` 4.5만 줄 726.7/1,450.8 → 7.3/8.7, 37,711 → 1,395. Rust ash `native.rs` 1.25만 줄 3.3/4.3 → 4.1/4.6, 296 → 306. ash `definitions.rs` 5.7만 줄 24.4/29.9 → 25.2/26.2, 385 → 386. 합성 마크다운 1만 줄 19.8/61.9 → 19.9/61.7, 223 → 224. 합성 HTML 1만 줄 6.1/7.1 → 6.4/7.9, 156 → 109.
  - 강조 결과 전/후 같음(샘플 18개·합성·큰 파일 해시, `K49_VERIFY=1` 불일치 0).
  - 백그라운드 파싱은 하지 않음: 고친 뒤 막은 최장이 한 프레임 안팎(TS 3.6~8.3ms, Rust 4~26ms, HTML 8ms). 남은 값 — 합성 마크다운 연 뒤 첫 편집 61ms(이후 반복 없음, tree-sitter-md 블록 파서), ash 5.7만 줄 26ms, 첫 파싱은 UI 스레드(TS 4.5만 줄 1.4초, 1.5만 줄 0.4초). 더 줄이려면 첫 파싱 background + 그동안 평문(별도 카드 후보, V4-LIST "결정" 행).
  - 결과: 완료(`src/ui/syntax.rs`, 측정 테스트 `#[ignore]`). 검증: V1, 전체 `cargo test` 316 passed(2 ignored)·clippy 0, vendor/gpui-base 변경 없음.
- **W-56 K-49 기록, V4-LIST 큰 파일 행** (2026-11-08): 위 K-49를 기록하고 `reports/V4-LIST.md`의 "큰 파일 입력 지연" 상태를 K-49 결과로, 남은 값(마크다운 첫 편집 61ms, 첫 파싱 UI 스레드)을 "결정" 종류 "백그라운드 파싱" 행으로 더했다. 결과: `PROGRESS.md`·`reports/V4-LIST.md` 수정, `cards/W-56.report.md`. 검증: V0(표 열 수).
- **K-50 첫 파싱 background** (2026-11-08, core ORDER-11-R2 [DECISION]: 처음 열 때 전체 파싱만 background, 편집 중 증분은 동기): 새 하이라이터(파일 열기·다시 읽기)의 첫 전체 파싱을 `background_executor`로 보내고 `SYNC_PARSE_TIMEOUT` 1ms(Zed `sync_parse_timeout`)만 기다린다 — 그 안에 끝나면 바로 반영, 아니면 그동안 평문·심볼 빈 목록, 결과가 오면 `EditorState::refresh`. 파싱 중 편집은 로그에 쌓았다가 결과 트리에 재생 + 증분 `reparse` 한 번. 재시작(텍스트 교체)은 세대 번호로, 닫기·다른 파일은 `Weak`로 결과를 버린다(이미 도는 파싱은 끝까지 돌고 결과만 버림). Zed `buffer.rs` 1177·1943~2010 규칙.
  - 전/후(release, UI 스레드 막은 최장 ms, 괄호는 background 완료까지): TS `lib.webworker.d.ts` 402.5 → 5.0(404.6), TS `lib.dom.d.ts` 4.5만 줄 1,353.4 → 1.9(1,376.5), ash `native.rs` 302.8 → 12.4(308.6), ash `definitions.rs` 380.5 → 11.3(393.8), 합성 마크다운 223.4 → 15.9(234.8), 합성 HTML 111.9 → 11.9(112.0). "후"의 2~16ms에는 측정 방법(`recv_timeout` 1ms가 Windows 타이머 틱으로 올림)의 한계가 섞여 있다.
  - 결과: 완료(`src/ui/syntax.rs`, 테스트 2 + 측정 `#[ignore]`). 검증: V1, 전체 `cargo test` 318 passed(3 ignored)·clippy 0, vendor/gpui-base 변경 없음. 실측 필요: 앱에서 평문 → 색 전환, 파싱 중 입력·탭 닫기·파일 바꾸기(V3).
- **W-57 K-50 기록, V4-LIST 백그라운드 파싱 행** (2026-11-08): 위 K-50을 기록하고 `reports/V4-LIST.md` "백그라운드 파싱" 결정 행의 상태를 core 결정(ORDER-11-R2)과 K-50 결과로 바꿨다(마크다운 첫 편집 61ms는 기록만, 화면 모습은 V3/Phase 12). 결과: `PROGRESS.md`·`reports/V4-LIST.md` 수정, `cards/W-57.report.md`. 검증: V0(표 열 수).

#### 지금 상태 요약(2026-11-08, ORDER-11 진행 중)

- 진행 중: coder(Claude Sonnet 5.5 high, pane wD:pH, 23:15부터) **K-45**(경로 줄 코드 심볼 outline). 대기 카드 순서: **K-47-R1**(core 결정: vendor/gpui-base K-47 변경 되돌리고 앱에서 Window 있는 시점에 기존 set_soft_wrap, 같은 값이면 다시 안 부름) → **K-46**(미리보기 코드 블록 강조·테두리 1px border_variant·반지름 6·안쪽 12). 카드 파일은 `specs/v0.5/cards/`에 이미 있다. coder는 카드 경계마다 /clear 뒤 다음 카드(core 지시).
- 끝난 것(ORDER-11): 문법 24개 연결(K-42A~K-43C, Zed Cargo.lock 정확 고정, HTML만 vendor/tree-sitter-html C 소스 + build.rs, cc =1.10.0 — core 안 A), 쿼리 복사본 `resources/zed-languages/`(.gitignore) + `tools/fetch-zed-languages.ps1`(Zed 4304dec), 편집기 강조(K-42B), 주입(K-44), 글자색 editor.foreground·언어별 줄바꿈·탭 폭(K-47, vendor 부분은 R1로 되돌림 예정).
- 남은 ORDER-11: K-45·K-47-R1·K-46, **TOML**(Zed TOML 확장 v1.1.0 8e18e50, 문법 342d9be)과 **git-firefly 0.1.9**(gitattributes·gitconfig·gitignore·gitrebase) — tauri가 SPEC R-15에 행을 적으면 같게(core [DECISION], 설치본과 같은 버전 고정 커밋, 복사본+스크립트, 실행 중 Zed 폴더 안 읽음). 그 뒤 V3 2차(마크다운 인라인·HTML 주입·경로 줄 심볼 sample.rs 21행 `impl Counter › pub fn bump › fn clamp`, sample.ts 18행 `class Inventory › add( ) › function normalize( )`, sample.py 21행 `class Library › def add › def normalize`, 미리보기), checker 리뷰·전체 테스트, 커밋, 보고 `specs/v0.5/reports/ORDER-11.md`(언어 목록 표·형식별 결과 표, vendor한 문법 목록).
- V3 1차(ORDER-11, 2026-11-07 23:55 빌드): 문법 색은 rs·py·ts·css·go에서 Zed와 같음. 다른 점 3가지(글자색·HTML 줄바꿈·탭 폭)는 K-47. tauri Zed 캡처 없는 형식: diff·gomod·gowork·env·COMMIT_EDITMSG. 측정 스크립트 `tools/measure/order11-v3.ps1`(C-42, 단계 step1~6).
- 화면 규칙(core): 사용자 부재 — leader가 [SCREEN-REQ] **알림만** 보내고 바로 실행, 끝나면 [SCREEN-DONE] 알림. core가 [SCREEN-WAIT]을 보내면 그 알림까지 화면 실행 금지. 단계마다 새 세션(`-Steps stepN -Out …-runN-stepN`), 띄운 PID만 닫고 앱 데이터 바이트 동일 복원(state.json D2C22F71), 사용자 Zed(18016·20788)·settings.json(C3D27B05) 불변 확인. **입력 가드**: 모든 마우스 입력은 그 점의 창이 띄운 PID 창일 때만, 키 입력은 앞 창이 앱일 때만, 아니면 입력하지 않고 그 단계 FAIL(ORDER-09 4차에 마우스 뒤로 입력이 사용자 브라우저로 간 사고 뒤 core 규칙). 다른 창 캡처는 커밋 제외.
- toml 할 일: TOML·git-firefly 행이 오면 언어 표·toml 필요 시 등록. `panel.focused_border` 라이트 #0588f0은 toml에 슬롯 없음(코드에만, W-45 제안 미결).
- 커밋 상태: Phase 10까지 push 완료(eeab1c0 위 97d321c·df65ba7, core 지시로 push). ORDER-11 작업은 아직 커밋 안 함(dirty).
- push는 core 지시 때만.

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

- 사용자 종료 판단(core-leader 전달, 2026-11-08): 사용자가 v0.5를 끝냈다. 목표의 약 90%에 도달했고, 추가 수정은 다음 버전에서 한다.
- 마지막 상태: Phase 11까지 push(`0c37da4`). Phase 12 사용자 테스트는 master `0c37da4` 빌드로 했다.
- 남은 것:
  - Phase 12 결과 기록 없음 — 다음 버전에서 다시 확인. 아래는 `specs/v0.5/reports/V4-LIST.md`에서 상태가 "Phase 12"·"기록 없음"·"다시 확인 안 함"인 미확인 항목과 "범위 밖" 차이를 종류별로 옮긴 것이다(근거 줄 번호는 V4-LIST를 만든 때의 보고 파일 기준).
  - V4(11):
    - Phase 3 I-14 글자 모양 인상: 영문(IBM Plex Sans·Lilex)·한글(Malgun Gothic) 글자 모양, 굵기(미리보기 제목 600 포함), 렌더링 인상 — 근거 ORDER-03 39~40행, PROGRESS "Phase 12 V4 확인 항목" 990행 (V4-LIST 상태: Phase 12)
    - Phase 3 I-13 현재 줄 강조 대비: One Light 현재 줄 배경 `#ebebecbf`의 대비·인상 — 근거 ORDER-03 41행, PROGRESS 991행 (V4-LIST 상태: Phase 12)
    - Phase 4 OS 네이티브 대화 상자 `\`: 탭 닫기 미저장·파일 삭제 TaskDialog의 역슬래시 표시(OS 글꼴, I-20 판정 제외, core 결정 A) — 근거 ORDER-04 11행 `measure-ORDER-04/app-I20-dialog-unsaved.png`·`app-I20-dialog-delete.png`, PROGRESS 992행 (V4-LIST 상태: Phase 12)
    - Phase 5 아이콘 모양 인상: Zed SVG로 바꾼 아이콘의 모양 인상 — 근거 ORDER-05 31~32행 (V4-LIST 상태: Phase 12)
    - Phase 6 Licenses 표시 방식: gpui는 별도 창(이제 문법·확장 라이선스 포함) — 근거 ORDER-06-R2 17행 (V4-LIST 상태: Phase 12)
    - Phase 7 테마·아이콘 테마 인상: 테마·아이콘 테마 인상, Catppuccin 컬러·Monochrome 아이콘 대비, 미리 보기 중 깜박임 — 근거 ORDER-07 35~36행 (V4-LIST 상태: Phase 12)
    - Phase 8 검색 툴바 인상: 검색 툴바 아이콘(‹ › 겹 chevron, 필터 줄 두 아이콘) 인상, 다른 창 크기에서 검색 입력 폭 — 근거 ORDER-08 38행 (V4-LIST 상태: Phase 12)
    - Phase 9 긴 경로 탭 툴팁: 긴 경로 툴팁이 여러 줄로 감기는 모양(Zed 캡처는 짧은 경로라 비교 못 함) — 근거 ORDER-09 39행 (V4-LIST 상태: Phase 12)
    - Phase 11 구문 색 품질 인상: 언어별 강조 색 인상(ORDER-11 판정 방법 V4) — 근거 ORDER-11 83행 (V4-LIST 상태: Phase 12)
    - Phase 11 미리보기 코드 블록 인상: 미리보기 코드 블록의 강조·테두리·배경 인상 — 근거 ORDER-11 83행 (V4-LIST 상태: Phase 12)
    - Phase 11 코드 파일 첫 프레임 줄바꿈: 코드 파일을 연 첫 프레임에 줄바꿈이 한 번 켜졌다 꺼지는지(렌더 때 적용, 한 프레임 늦음, K-47-R1) — 근거 ORDER-11 84행 (V4-LIST 상태: Phase 12)
  - 측정 못 함·V4(7):
    - Phase 6 Settings 창 안 조작: Settings 창 안 검색, 숫자 입력 저장, Edit in settings.json 버튼 — SendInput 입력이 별도 창에 가지 않음(V1·코드 리뷰만) — 근거 ORDER-06-R1 17~18·30~31행, ORDER-06-R2 17행 (V4-LIST 상태: Phase 12)
    - Phase 6 View → Editor Layout 하위 메뉴 열림: 하위 메뉴 hover 입력이 전달되지 않아 캡처 해시 불변(`cargo test app_menu::tests`만) — 근거 ORDER-06-R1 10·18·31행, ORDER-06-R2 17행 (V4-LIST 상태: Phase 12)
    - Phase 8 미리보기 클릭 위치: 미리보기에서 목록·코드 블록·인용 클릭 뒤 커서 위치(덤프에 블록 probe가 없어 화면 클릭 측정 안 함, V1 K-24) — 근거 ORDER-08 1·7·37행 (V4-LIST 상태: Phase 12)
    - Phase 8 Replace 뒤 수정 표시: Replace Next·Replace All 뒤 탭이 수정됨 표시이고 디스크 파일은 그대로인지(화면 측정에서 Replace를 누르지 않음) — 근거 ORDER-08 1·36행 (V4-LIST 상태: Phase 12)
    - Phase 9 폴더 둘일 때 경로 줄: 측정 스크립트가 둘째 폴더의 파일을 열지 못함(V1 K-34 `path_text`만). 예 `workbench-tauri\AGENTS.md › # AGENTS` — 근거 ORDER-09 8·36행 (V4-LIST 상태: Phase 12)
    - Phase 9 분할 pane별 제목: 분할 두 pane이 각자 커서 기준 제목을 보이는지(V1 `heading_trail`만) — 근거 ORDER-09 8·37행 (V4-LIST 상태: Phase 12)
    - Phase 9 다른 탭으로 뒤로 가기: 다른 탭으로 뒤로 가기(App.tsx → AGENTS.md)와 닫은 탭 다시 열기 — 근거 ORDER-09 1·38행 (V4-LIST 상태: Phase 12)
  - 측정 못 함(5):
    - Phase 7 Zed 트리 아이콘 화면 비교: Zed 단독 실행이 fixture 폴더를 앱 단계에서만 만들어 시작 전 종료(대응은 테마 JSON 기준 V1 `cargo test icon_theme`) — 근거 ORDER-07 1·8·36행 (V4-LIST 상태: Phase 12)
    - Phase 9 스크롤 행 안 probe: gpui 스크롤 행 안 probe가 덤프에 비거나 갱신되지 않아 스크립트 `[RESULT]` 일부가 틀림(판정은 leader가 캡처로) — 근거 ORDER-09 33행, PROGRESS K-37 범위 밖 발견 (V4-LIST 상태: 기록 없음)
    - Phase 10 사이드바 누름 색: `ghost_element_active`는 화면 측정 안 함(소스 기준) — 근거 ORDER-10 37행 (V4-LIST 상태: Phase 12)
    - Phase 11 Zed 캡처 없는 형식: Diff·Go Mod·Go Work·Env·Git Commit은 강조됨을 캡처로 확인했으나 Zed 캡처가 없어 비교 못 함 — 근거 ORDER-11 57행 (`run4-step3`) (V4-LIST 상태: 기록 없음)
    - Phase 11 V1만 확인한 형식: JSONC, TOML, Git 4종(Attributes·Config·Ignore·Rebase)은 V1 샘플 run 테스트만, 화면 샘플 없음 — 근거 ORDER-11 58행 (V4-LIST 상태: 기록 없음)
  - 결정·V4(1):
    - Phase 10 `panel.focused_border` 라이트: gpui `#0588f0`(Zed `default_colors.rs` 98), tauri `border.focused`. 라이트 값 toml ID 형식 미정 — 근거 ORDER-10 19·36행 (V4-LIST 상태: tauri K-46으로 같아짐(PROGRESS C-40 뒤 "tauri와 다른 점(마무리)"). toml 라이트 슬롯은 기록 없음(W-45 제안 미결). 인상은 Phase 12)
  - 결정(2):
    - Phase 9 폴더 밖 파일 경로 줄: gpui는 파일 이름만, tauri는 전체 경로. Zed 소스 대조(C-38)로 파일 이름만이 Zed와 같음 — 근거 ORDER-09 20~21행 (V4-LIST 상태: gpui는 그대로(Zed와 같음). tauri 쪽 처리 기록 없음)
    - Phase 11 백그라운드 파싱: 남은 값: 합성 마크다운(1만 줄, 코드 블록 330) 연 뒤 첫 편집 61ms(이후 중앙 19.9ms, 루트 증분 파싱), ash `definitions.rs` 5.7만 줄 한 글자 26ms, 큰 파일 첫 파싱이 UI 스레드(TS 4.5만 줄 1.4초, 1.5만 줄 0.4초 — 그동안 화면이 멈춤). Zed식 1ms 동기 + background 파싱(첫 파싱 동안 평문)을 할지 — 근거 `cards/K-49.report.md` 2·3절, `cards/K-50.report.md` 1~3절 (V4-LIST 상태: core 결정(ORDER-11-R2, 2026-11-08): 처음 열 때 전체 파싱만 background, 편집 중 증분은 동기. K-50에서 고침 — TS 4.5만 줄 UI 정지 1,353ms → 1.9ms(색은 약 1.4초 뒤, 그동안 평문). 남은 것: 마크다운 첫 편집 61ms는 기록만(core). 앱에서 평문 → 색 전환, 파싱 중 입력·탭 닫기 모습은 V3/Phase 12)
  - 범위 밖(4):
    - Phase 10 편집 영역 포커스 테두리 대체값: pane 쪽 대체값 `#62adef`는 그대로(panel만 Zed 기본으로 나눔) — 근거 ORDER-10 24행 (V4-LIST 상태: 그대로)
    - Phase 11 미리보기 중첩 번호 목록: 중첩 번호 목록 표시 `A.`/`B.`(Zed `1.`/`2.`) — 근거 ORDER-11 79~80행 (V4-LIST 상태: 기록 없음)
    - Phase 11 미리보기 제목 밑줄·가운데 정렬: 제목 아래 구분선·본문 폭 가운데 정렬 없음 — 근거 ORDER-11 80행 (V4-LIST 상태: 기록 없음)
    - Phase 11 미리보기 코드 블록 다음 제목 간격: 코드 블록 다음 제목 위 간격이 Zed보다 약 3px 작음 — 근거 ORDER-11 80행 (V4-LIST 상태: 기록 없음)

## 버전 종료 뒤 사용자 요청 작업

### 다른 PC에서 도는 배포본 (2026-11-08)

- 요청: core-leader [ORDER](사용자 지시, 2026-11-08) — 다른 PC에서 도는 배포본. 실행 중 resources 경로를 한 함수로(exe 옆 `resources\` 먼저, 없으면 개발 경로), 정적 CRT(`.cargo/config.toml`), `tools/package-release.ps1`.
- 조치(K-51, coder):
  - `src/ui/zed_icons.rs`: `pub fn resources_dir()`(OnceLock, 정한 경로를 stderr에 `resources: <경로>` 한 줄) + 선택 로직 `pick_resources(exe_dir, dev_root)` + `#[test] resources_prefer_dir_next_to_exe`. `Assets::new()`도 이 함수를 쓴다.
  - `src/ui/theme.rs`·`icon_theme.rs`·`syntax.rs`·`extensions.rs`: `env!("CARGO_MANIFEST_DIR")` 경로를 `resources_dir()`로 교체. 테스트 코드의 `CARGO_MANIFEST_DIR`·`include_str!`/`include_bytes!`는 그대로.
  - `.cargo/config.toml`(새 파일): `[target.x86_64-pc-windows-msvc] rustflags = ["-C", "target-feature=+crt-static"]`. `Cargo.toml`·`Cargo.lock`·`vendor/` 변경 없음. 링크 오류 없음.
  - `tools/package-release.ps1`(새 파일): `cargo build --release`(`-NoBuild`로 건너뜀) → `apply-manifest.ps1`(release exe) → `target\dist\workbench-gpui\`(exe + `resources\` 4폴더)와 `target\dist\workbench-gpui.zip`. 4폴더가 없으면 fetch 스크립트 이름을 알리고 실패. 지우는 것은 그 폴더와 zip뿐.
- 결과:
  - release exe: 41.38 MB(43,394,560 B) → 41.61 MB(43,631,616 B, manifest 병합 후). 정적 CRT로 +약 0.23 MB.
  - 배포 폴더 `D:\projects\workbench-gpui\target\dist\workbench-gpui\`: 47.22 MB, 5,751 파일(exe + `resources\{zed-icon-themes, zed-icons, zed-languages, zed-themes}`).
  - zip `D:\projects\workbench-gpui\target\dist\workbench-gpui.zip`: 16.36 MB(17,154,349 B).
  - 배포 폴더와 zip은 `target\` 아래라 git에 들어가지 않는다. 다시 만들 때: `pwsh -NoProfile -File tools/package-release.ps1`.
  - 보고: `specs/v0.5/reports/RELEASE.md`.
- 검증(K-51 V1, C-46 checker PASS):
  - K-51: `cargo build` OK, `apply-manifest.ps1` OK, `cargo test resources_prefer` 1 passed, `cargo clippy --all-targets -- -D warnings` 경고 0, `tools/package-release.ps1` OK. rustflags 변경으로 프로필마다 전부 재빌드(debug 3분 36초, test 1분 24초, clippy 1분 44초, release 5분 2초).
  - C-46: `cargo test` 전체 319 passed, 0 failed, 3 ignored(`resources_prefer_dir_next_to_exe`·`missing_zed_icons_are_empty_without_panic`·`k20_res_prefix_serves_resources_svg_only` 통과). clippy 경고 0. `Cargo.toml`·`Cargo.lock`·`vendor` 변경 없음. 실행 코드의 resources 조회가 모두 `resources_dir()` 하나를 거침(코드 읽기).
  - `dumpbin /dependents`(release exe, 배포 exe): `VCRUNTIME140`·`MSVCP`·`api-ms-win-crt-*`·`ucrt` 없음. 남은 DLL은 전부 OS 제공 26개(KERNEL32, USER32, ole32, SHELL32, advapi32, api-ms-win-core-synch-l1-2-0, combase, icuuc, oleaut32, gdi32, dcomp, dwmapi, winmm, comctl32, dwrite, dxgi, d3d11, imm32, ntdll, api-ms-win-shcore-scaling-l1-1-1, uiautomationcore, api-ms-win-core-winrt-l1-1-0, api-ms-win-core-winrt-error-l1-1-0, bcryptprimitives, gdiplus, userenv).
  - 다른 경로 실행([SCREEN-OK] 뒤): 배포 폴더를 `C:\Users\nampl\AppData\Local\Temp\c46-run-23e06da8\`에 복사(5,751 파일)해 exe 1회 실행(PID 18664, 6초 뒤 실행 중). stderr 한 줄 `resources: C:\Users\nampl\AppData\Local\Temp\c46-run-23e06da8\resources`, stdout 비어 있음, `icons missing`·`queries unavailable` 등 다른 오류 없음. 그 PID만 닫음. 화면 조작·캡처 없음.
- 상태: 완료(C-46 PASS). 남은 제약(`specs/v0.5/reports/RELEASE.md` "남은 제약", K-51·C-46 사용자 확인 필요):
  1. 실제 다른 PC에서는 아직 안 돌려 봤다. 같은 PC의 다른 경로에서만 확인했다. VC++ 재배포 패키지가 없는 PC에서 뜨는지, 아이콘·테마·문법 강조가 실제로 보이는지는 사용자 확인이 필요하다.
  2. 콘솔 창이 같이 뜬다. `main.rs`에 `windows_subsystem = "windows"`가 없어 exe를 더블클릭하면 콘솔 창이 함께 열린다(stderr `resources:` 줄이 거기 찍힌다). 이번 지시 범위 밖이라 바꾸지 않았다.
  3. OS 조건: `icuuc.dll`은 Windows 10 1703 이상의 시스템 DLL이다. 긴 경로 지원(longPathAware)은 그 PC의 레지스트리 `LongPathsEnabled`도 1이어야 켜진다. x64 Windows만 대상이다(정적 CRT 설정은 `x86_64-pc-windows-msvc`에만).
  4. `resources\` 판단은 폴더 존재만 본다. exe 옆에 빈 `resources\`가 있으면 그 폴더를 쓴다(개발 경로로 넘어가지 않는다). 개발 경로(`CARGO_MANIFEST_DIR`) 문자열은 exe에 그대로 남아 있다.
  5. 서명 없음. exe에 코드 서명이 없어 다른 PC에서 SmartScreen 경고가 뜰 수 있다(확인 안 함).
  6. 빌드 시간: rustflags가 바뀌어 공유 `target`의 모든 프로필이 한 번씩 전부 다시 빌드됐다(debug 3분 36초, release 5분 2초 등, K-51). 이후 빌드는 다시 증분이다.
  7. 실행 방식: 이번 작업은 herdr 서브 에이전트 pane이 떠 있지 않아 leader가 Claude Code 내부 서브 에이전트(Sonnet)로 coder·checker 카드를 돌렸다.
  - K-51 생략: 아이콘/테마 폴더 누락 시 배포 폴더 자동 fetch 없음(스크립트 이름만 안내).

### 배포본 빌드 문서 (2026-11-08)

- 요청: core-leader [ORDER](사용자 지시, 2026-11-08) — 배포본 빌드 과정 문서, README 링크, 빌드 산출물을 git에서 막기.
- 조치(W-60, writer):
  - `docs/BUILD.md`(새 파일): 필요한 도구와 버전, 복사본 채우기(fetch 스크립트 3개·채우는 폴더·고정 커밋), 빌드 명령(개발 빌드, `tools/package-release.ps1`·`-NoBuild`, 스크립트 단계, `CARGO_TARGET_DIR`, 정적 CRT), 결과 파일 경로·크기·폴더 구성, 걸린 시간, 다른 PC로 옮기기, 알려진 제약(RELEASE "남은 제약" 1~6), 라이선스 주의(배포물에 들어가는 `resources\` 복사본), GitHub에 올리지 않는 것.
  - `.gitignore`: `target/` 다음에 `dist/`, `bundle/`, `*.exe`, `*.zip`, `*.msi`, `*.pdb`(주석 한 줄).
  - `README.md`: "빌드와 실행" 절 끝에 `docs/BUILD.md` 링크 한 줄.
- 결과: 근거는 `specs/v0.5/reports/RELEASE.md`, K-51 보고, C-46 리뷰, `tools/*.ps1`, `build.rs`, `.cargo/config.toml`, `Cargo.toml`, `HERDR-SETUP.md` 2.2, `resources/` 라이선스 파일, `src/ui/app_menu.rs` 라이선스 목록. 근거가 없는 것은 "확인 안 함"으로 적었다(측정 PC의 CPU·메모리, `extensions/html` 쿼리에 따로 적용되는 라이선스).
- 검증(V0, writer): 절 구성 확인, 링크 경로 확인(README → `docs/BUILD.md`, BUILD.md → RELEASE·K-51·C-46 파일 존재). `git ls-files -ci --exclude-standard` 0건(새 `.gitignore` 줄에 걸리는 추적 파일 없음). 산출물 커밋 여부는 leader 확인(`git ls-files`에 `\.(exe|zip|msi|pdb|dll|7z)$`·`target/`·`dist/`·`bundle/` 0건). 빌드·앱 실행 없음.
- 상태: 완료(writer). 보고: `specs/v0.5/cards/W-60.report.md`.

### 노트북에서 clone 후 BUILD.md만으로 빌드 (2026-11-08)

- 요청: core-leader [ORDER 추가]·[ORDER 정정]·[ORDER 정정 2](사용자 지시, 2026-11-08) — 사용자 개인 노트북에서 `git clone` 한 뒤 `docs/BUILD.md` 순서만 따라 배포본까지 만들 수 있게. 처음 지시로 깨끗한 복제에서 BUILD.md대로 빌드하는 C-47(checker)을 냈으나, 사용자 정정으로 실제 빌드·clone 테스트는 하지 않고 문서만 고치기로 했다. C-47은 시작 직후 멈췄고, 만든 `%TEMP%` 복제 폴더는 leader가 지웠다.
- 조치(W-61, writer): `docs/BUILD.md`만 고쳤다. 스크립트·코드·설정은 바꾸지 않았다.
  - 0절 "처음부터 순서"(새 절): 도구 설치(winget) → 새 터미널 → Rust 1.99.1 맞추기·설치 확인 → `git clone https://github.com/nampluskr/workbench-gpui.git`·`cd workbench-gpui` → fetch 셋 → `tools/package-release.ps1` → 결과 위치. 단계마다 확인 방법(fetch 스크립트 마지막 줄, `package-release.ps1`의 `folder:`·`zip:`·`size:` 세 줄)과 근거 있는 시간만.
  - 1절: winget 설치 명령(Git, PowerShell 7, Build Tools 2022 + VCTools + Windows 11 SDK 10.0.26100, Rustup)과 `rustup toolchain install 1.99.1`·`rustup default 1.99.1`, 설치 확인 명령, GUI 설치 때 고를 것. winget ID·구성 요소 ID는 이 PC에서 실행해 확인하지 않았다고 적음. `Cargo.toml` git 의존성·`vendor/gpui-base`·`build.rs`가 저장소와 공개 고정 rev만 쓴다는 점.
  - 2절: fetch는 GitHub 공개 고정 커밋·태그만 `%TEMP%`에 새로 받고 이 PC 전용 사본에 기대지 않음, 새 PC에서 따로 준비할 것 없음, 필요한 것은 git·pwsh·네트워크(github.com 막히면 실패).
  - 3절: `CARGO_TARGET_DIR`은 기본으로 설정하지 않음(레포 `target\`). 이 PC 공유 경로는 멀티 에이전트 데스크톱 전용 참고로만. 개발 빌드 명령에서 그 줄을 뺐다.
  - 4절: 결과 경로를 `<레포>\target\dist\...`로, 크기는 2026-11-08 이 PC 값.
  - 5절: 이 PC 측정값이며 다른 PC는 다를 수 있음, 새 clone 첫 빌드는 crates·git 의존성 받는 시간이 더해짐, 깨끗한 clone 빌드·fetch 시간은 측정 안 함.
  - 7절: 7 깨끗한 clone에서 빌드해 본 기록 없음(코드 읽기로만 확인), 8 `apply-manifest.ps1`은 PATH의 `mt.exe` 또는 Windows SDK 기본 경로 필요, 9 디스크 여유(release `target` 약 4.5 GB, 이 PC·leader 값).
  - 8절 라이선스 주의, 9절 GitHub에 올리지 않는 것은 유지.
- 결과: 근거는 W-61 카드의 leader 코드 확인 사실, `tools/fetch-zed-*.ps1`·`package-release.ps1`·`apply-manifest.ps1` 출력·경로 코드, W-60 BUILD.md. 근거가 없는 것(도구 설치 시간, fetch 시간, 깨끗한 clone 빌드 시간)은 "측정 안 함"으로 적었다.
- 검증(V0, writer, 코드 읽기): 단계 명령에 이 PC 전용 경로(`D:\projects`)가 없는지 grep — BUILD.md의 `D:\projects`는 2절 "기대지 않는다" 설명과 3절 데스크톱 전용 참고 두 곳뿐이고 단계 명령에는 없다. fetch 스크립트의 마지막 출력 줄, `package-release.ps1`의 출력 세 줄과 `CARGO_TARGET_DIR` 처리, `apply-manifest.ps1`의 SDK 경로를 스크립트에서 대조. 저장소에 `rust-toolchain` 파일 없음 확인. 빌드·clone·winget 설치·앱 실행 없음.
- 상태: 완료(writer). 깨끗한 clone에서 실제로 따라 해 보는 확인은 사용자(노트북)에게 남는다. 보고: `specs/v0.5/cards/W-61.report.md`.

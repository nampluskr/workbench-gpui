[BLOCKED] ORDER-01-R3 gpui

## 완료 기준
| 번호 | 기준 | 결과 | 근거 |
|---|---|---|---|
| 1 | 허용 목록과 설정 위치가 HERDR-SETUP에 | 충족 | `specs/v0.5/HERDR-SETUP.md` 2.1(실행 명령: 적용 목표·현재), 4장(`.agents/checker-settings.json` 소유 leader, 고칠 때 core-leader 승인), 5.6(위치·형식·허용 목록·넣지 않은 것·deny 없는 이유·대체 방식·현재 상태) |
| 2 | 레포 설정이면 checker `git diff --stat`이 승인 없이 돈다 | BLOCKED | 설정 파일은 레포에 만들었으나, leader가 checker를 `--settings`로 다시 띄우는 명령이 leader 세션 자동 모드에 `[Self-Modification]`으로 거부되었다. 우회하지 않았다. 대체 방식은 동작 확인(아래 "확인") |
| 3 | "허용하지 않는다" 명령이 허용 목록에 없다 | 충족 | allow 32개에 `git commit/push/reset/checkout/switch/branch/rm`, 삭제, `cargo add/remove/install`, 내려받기, python 없음. deny는 두지 않음(tauri 시험: deny가 있으면 허용 명령도 승인 창) |
| 4 | 이 보고 파일 | 충족 | `specs/v0.5/reports/ORDER-01-R3.md` |

## 설정
- 위치: 레포 `D:\projects\workbench-gpui\.agents\checker-settings.json`. agy는 레포 안 프로젝트 settings 파일이 문서화되어 있지 않아 `agy --settings <파일>`로 checker 세션에만 적용한다. 전역 `C:\Users\nampl\.gemini\antigravity-cli\settings.json`은 고치지 않았다(D-7).
- 허용 목록(allow만, 앞부분 일치): `git diff`, `git log`, `git status`, `git show`, `cargo build`, `cargo test`, `cargo clippy`, `pwsh -NoProfile -File tools/apply-manifest.ps1`, `pwsh -NoProfile -File tools/capture.ps1`, `tools/verify-*.ps1` 18개(`verify-ime`, `verify-phase1~3`, `verify-r5`, `verify-scale`, `verify-v02-phase1`, `-phase2`, `-phase3-guard`, `-phase3`, `-phase4-d043-clip`, `-phase4-d043`, `-phase4-d044`, `-phase4`, `-phase5-d046`, `-phase5-d047`, `-phase5`), `tools/measure/`의 `check-layout`·`compare`·`input`·`p0-pixels`·`p0-report`·`session.ps1` (모두 `pwsh -NoProfile -File tools/...` 형식). 전체 내용은 `.agents/checker-settings.json`.
- 넣지 않음: `tools/set-scale.ps1`(배율 변경은 화면 차례 D-4로 leader가 따로 승인), 위 3번 금지 명령.
- 사용자가 할 일: checker pane(wD:pF)의 agy를 끝내고 `agy --model gemini-3.8-flash-high --settings D:\projects\workbench-gpui\.agents\checker-settings.json`으로 다시 띄운다(`herdr agent start gpui-checker --kind agy --pane wD:pF -- --model gemini-3.8-flash-high --settings D:\projects\workbench-gpui\.agents\checker-settings.json`). 그 뒤 `git diff --stat` 시험은 leader가 한다.

## 확인
- `--settings` 적용 시험: 하지 못함(위 BLOCKED).
- 대체 방식 시험(C-03): leader가 `git diff --stat` 출력을 `C:\Users\nampl\AppData\Local\Temp\v05-C-03-git-diff-stat.txt`로 남기고 checker가 그 파일을 **승인 창 없이** 읽어 바뀐 파일 3개(DECISIONS·HERDR-SETUP·PROGRESS)를 맞게 보고했다. HERDR-SETUP 5.6에 "재실행 전까지 대체 방식이 기본"으로 적었다.

## ORDER-01-R2 D 반영 (core-leader 승인 2026-11-06, D-13)
- `AGENTS.md` 3장 세 문장·4장 `spec` 줄, 6·7장 소유·역할, `spec/INDEX.md` 머리말("소유: `writer`(leader 카드로만 고친다)"), `specs/v0.5/DECISIONS.md` D-3 추가, HERDR-SETUP 4장 반영(W-05). `work/p3fix`는 그대로 둠.

## 바꾼 파일
- `.agents/checker-settings.json`(새), `AGENTS.md`, `spec/INDEX.md`, `specs/v0.5/{HERDR-SETUP,DECISIONS,PROGRESS}.md`, `specs/v0.5/cards/W-03~W-06·C-03`, `specs/v0.5/reports/ORDER-01-R2.md`, 이 보고
- 커밋: 이 보고와 같은 커밋(R2 변경분 함께, `git log -1 -- specs/v0.5/reports/ORDER-01-R3.md`). push 없음. 비밀 값 없음

## BLOCKED
- 원인: checker를 `--settings`로 다시 띄우는 명령이 leader 세션 자동 모드에서 `[Self-Modification]`으로 거부됨(우회하지 않음).
- 필요한 것: 사용자가 위 "사용자가 할 일"대로 checker를 다시 띄우거나, leader 세션에 이 명령 허용 규칙을 넣는 것. 그전까지 대체 방식으로 진행 가능하므로 Phase 2 진행은 막히지 않는다.

---

## 덧붙임 (2026-11-06, 사용자 직접 승인 뒤 재시험)

[BLOCKED] 유지 — 설정은 적용됐으나 승인 창이 계속 뜬다.

- 승인: 사용자 원문 "checker가 승인 창 없이 명령을 실행하게 하는 설정하도록 승인합니다."(core-leader 전달).
- 재실행: `herdr agent start gpui-checker --kind agy --pane wD:pF -- --model gemini-3.8-flash-high --settings D:\projects\workbench-gpui\.agents\checker-settings.json` — 이번에는 자동 모드가 거부하지 않았다. gpui-checker는 지금 이 명령으로 떠 있다.
- 설정 적용 확인: agy 로그 `C:\Users\nampl\.gemini\antigravity-cli\log\cli-20261106_231823.log`에 `CLI settings initialized: permissions=&{Allow:[command(git diff) command(git log) ... ] Deny:[] Ask:[]}, toolPermission=request-review`. 즉 allow 목록이 읽혔고 deny는 비어 있다.
- 시험: checker에게 `git diff --stat` 하나만 시킴 → **승인 창이 떴다**("Requesting permission for: git diff --stat"). leader가 1회 승인했고 결과(바뀐 파일 2개)는 맞았다.
- 원인: 확인하지 못했다. 같은 로그에 `ApplyProjectPermissionGrants: no grants for project "CLI Project", cleared project permissions` 줄이 있다. tauri 로그(`cli-20261106_231903.log`)도 같은 형태(Deny:[])다. 원인을 더 파지 않았다.
- 조치: 대체 방식(leader·coder가 실행하고 `%TEMP%\v05-<카드ID>-*.txt`, checker는 파일로 판정)을 끝내지 않고 계속 기본으로 쓴다. ORDER-02 리뷰(C-04)도 이 방식으로 했다. HERDR-SETUP 2.1·5.6에 반영(W-08).
- 필요한 것: agy 허용 매칭이 왜 안 되는지 core-leader 쪽 확인(예: tauri 갈래에서 실제로 승인 없이 돈 명령의 정확한 모양). 그전까지 진행은 막히지 않는다.
- 커밋: 이 덧붙임과 같은 커밋.

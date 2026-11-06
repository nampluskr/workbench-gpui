[DONE] ORDER-01-R2 gpui

## 완료 기준
| 번호 | 기준 | 결과(충족/미충족/해당 없음/BLOCKED) | 근거(파일 경로, 명령과 출력) |
|---|---|---|---|
| 1 | A: HERDR-SETUP에 위임과 예외 | 충족 | `specs/v0.5/HERDR-SETUP.md` 5.6 "승인 처리": leader가 대신 응답(사용자 2026-11-06, core ORDER-01-R2). 위임 밖(core-leader에게 묻는다, core D-13): 의존성 추가·제거·버전 변경, HERDR 구성 변경(모델·effort·역할·pane), push. 기록은 출처를 달아 `specs/v0.5/PROGRESS.md`(별도 HERDR-DECISIONS 없음, leader 결정) |
| 2 | B: 구독 현황 = D-2 근거, 수치 "미정" 없음 | 충족 | HERDR-SETUP 3장 표 "구독 현황(core D-2)": Claude 여유 / Codex 여유, 초기화 쿠폰 있음 / agy 여유(Argon 사용 불가). "남은 한도·초기화 시점 수치는 적지 않는다". "한도가 바뀌어 구성을 바꾸면 다시 승인받는다" 그대로 |
| 3 | C: worktree 하나, `work/editor`·`work/ui` 없음 | 충족 | 병합 확인 `git rev-list --count master..work/editor` → 0, `..work/ui` → 0, 두 worktree 변경 없음. `git worktree remove .worktrees/editor`, `.worktrees/ui`, `git branch -d work/editor work/ui` 성공. `git worktree list` → `D:/projects/workbench-gpui d10bb20 [master]` 하나. `git branch` → `master`, `work/p3fix`. 원격 브랜치 손대지 않음 |
| 4 | D: `spec/` 소유 안 | 충족 | 아래 D |
| 5 | 이 보고 파일 | 충족 | `specs/v0.5/reports/ORDER-01-R2.md` |

참고: 로컬 브랜치 `work/p3fix`가 남아 있다(이 카드 대상 아님, 손대지 않음). 지울지 core-leader가 정해 주면 따른다.

## D. spec/ 소유 안 (gpui만)
문서에는 아직 반영하지 않았다.

**소유자: `writer`.** `spec/zed-metrics.toml`·`spec/INDEX.md`·`spec/ambiguous.md`는 문서·데이터라 writer가 leader 카드로만 고친다. Zed 값 확인(원문 대조·Zed 화면 측정)은 `checker`가 하고 결과를 보고 파일로 넘기면 writer가 기록한다. coder는 읽기만 한다. 근거: D-2에서 v0.4 `spec`(agy) 역할이 없어졌고, 문서 담당이 writer, 측정 담당이 checker다. 스펙 항목 ID 불변 규칙(v0.4 AGENTS 7.3)은 그대로 둔다.
- 함께 고칠 것: `spec/INDEX.md` 머리말 "소유: `spec`" → "소유: `writer`(leader 카드로만 고친다)".
- 참고: 지난 커밋에 workbench-tauri용 스펙 ID를 이 레포 `spec/`에 더한 것이 있다(4badee1, 39350b7, 8eb170e). core D-7 이후 tauri는 이 파일을 쓰지 않으므로, tauri가 스펙 ID가 필요하면 core-leader를 거쳐 gpui-leader 카드로 요청한다.

**AGENTS.md 3장 문장 안**
| 고치기 전 | 고친 뒤 |
|---|---|
| 원문 실측 문서(`docs/refs/01-zed/`)는 `spec/INDEX.md`를 통해 필요한 절만 읽는다. 통째로 읽는 것은 `spec` 담당뿐이다. | 원문 실측 문서(`docs/refs/01-zed/`)는 `spec/INDEX.md`를 통해 필요한 절만 읽는다. 통째로 읽는 것은 스펙 기록 카드를 받은 `writer`뿐이다. |
| v0.4에서는 Phase 2(P4·P5) 카드에서만 코드 값을 스펙 값으로 맞춘다. 허용 오차 안 불일치도 맞춘다(`specs/v0.4/DECISIONS.md` D-3). 그 밖의 카드에서 찾은 불일치는 고치지 않고 완료 보고에 적고, `leader`가 PROGRESS의 스펙 불일치 목록에 모은다. | v0.5에서는 각 I-n의 구현 카드(core ORDER-02~11에 대응하는 Phase 카드)가 그 I-n이 다루는 화면·값만 스펙 값으로 맞춘다. 허용 오차 안 불일치도 맞춘다. 카드 범위 밖에서 찾은 불일치는 고치지 않고 완료 보고에 적고, `writer`가 PROGRESS의 스펙 불일치 목록에 모은다. |
| 스펙에 없는 값이 필요하면 추정하지 말고 `leader`를 통해 `spec`에게 요청한다. 단, …(core D-12 예외 문구 그대로) | 스펙에 없는 값이 필요하면 추정하지 말고 `leader`에게 요청한다. `leader`는 `checker`에게 Zed 값 확인 카드를, `writer`에게 `spec/` 기록 카드를 낸다. 단, …(core D-12 예외 문구 그대로) |
| 4장 "`spec` 역할은 이 장을 적용하지 않는다." | 지운다(그 역할이 없다). |

**코드 값 맞추기 카드 범위:** 위 둘째 줄과 같다. I-n 구현 카드 = 그 I-n의 값 맞춤 범위. 범위 밖 불일치는 모아 두었다가 Phase 12 사용자 일괄 확인 때 core-leader에게 올린다.

## 바꾼 파일
- `specs/v0.5/HERDR-SETUP.md`, `specs/v0.5/DECISIONS.md`, `specs/v0.5/PROGRESS.md`, `specs/v0.5/cards/W-03.md`·`W-03.report.md`, 이 보고
- git: worktree 2개와 로컬 브랜치 `work/editor`·`work/ui` 삭제
- 커밋: 이 보고와 같은 커밋(`git log -1 -- specs/v0.5/reports/ORDER-01-R2.md`). push 없음

## BLOCKED
없음

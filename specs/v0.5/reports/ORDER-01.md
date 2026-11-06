[DONE] ORDER-01 gpui

## 완료 기준
| 번호 | 기준 | 결과(충족/미충족/BLOCKED) | 근거(파일 경로, 명령과 출력) |
|---|---|---|---|
| 1 | specs/v0.5 문서 여섯 | 충족 | `specs/v0.5/{INTENT,DECISIONS,SPEC,PLAN,HERDR-SETUP,PROGRESS}.md`. SPEC R-1~R-23 = I-1~I-23, 판정 방법 23/23 글자 일치(checker 스크립트 대조). PLAN Phase 1~12 ↔ core Phase ↔ ORDER ↔ I-n 대응 표 |
| 2 | 서브 에이전트 셋과 탭 배치 | 충족 | `herdr agent list`: gpui-writer wD:pD, gpui-coder wD:pE, gpui-checker wD:pF. `herdr tab list --workspace wD`: control(wD:t1)·docs(wD:t4)·impl(wD:t5)·check(wD:t6), 각 pane 1개 |
| 3 | 이 보고 파일 | 충족 | `specs/v0.5/reports/ORDER-01.md` |
| 0 | (tauri만) v0.4 종료 기록, 커밋, 태그 `v0.4` | 해당 없음 | gpui는 v0.4를 2026-11-05에 닫음(태그 `v0.4`) |

## 문서 경로
모두 상태 줄 "초안 (core-leader 판정 뒤 사용자 확정)", PROGRESS만 "초안 (진행 중)".
- `specs/v0.5/INTENT.md`
- `specs/v0.5/DECISIONS.md` — 갈래 결정 D-1(카드·보고 파일 위치 `specs/v0.5/cards/<ID>.md`·`<ID>.report.md`), D-2(v0.4 worktree 안 씀). core D-n은 가리키기만 함
- `specs/v0.5/SPEC.md` — R-n = I-n
- `specs/v0.5/PLAN.md`
- `specs/v0.5/HERDR-SETUP.md`
- `specs/v0.5/PROGRESS.md`
- 서브 에이전트 카드·보고: `specs/v0.5/cards/W-01.md`(writer), `C-01.md`(checker 검토)와 각 `.report.md`
- 고친 지침: `AGENTS.md`(레포 규칙 HERDR 문서 줄 교체·D-7 줄 추가, 공통 지침을 v0.5 역할 넷으로)

## 에이전트
| 이름 | pane | 탭 | 도구·모델 | 실행 |
|---|---|---|---|---|
| gpui-leader | wD:p1 | control | Claude Code Opus 5.5 | 기존 세션 |
| gpui-writer | wD:pD | docs | Claude Code Opus 5.5 medium | `claude --model opus --effort medium` |
| gpui-coder | wD:pE | impl | Codex GPT-6.1-Sol medium | `codex` 뒤 `/model` → GPT-6.1-Sol → Medium → `s`(세션 한정, v0.3 H-3). 상태줄 `GPT-6.1-Sol medium` 확인 |
| gpui-checker | wD:pF | check | agy Gemini 3.8 Flash (High) | `agy --model gemini-3.8-flash-high` |

- coder·checker는 역할 확인 프롬프트만 받았고(3줄 답 확인), 코드·문서 수정·빌드·앱 실행 없이 다음 카드를 기다린다.
- 닫은 v0.4 에이전트: 없음(시작 때 workbench-gpui 워크스페이스에 leader pane 하나뿐이었다).
- 남겨 둔 worktree: `.worktrees\editor`(work/editor, 829dbcc), `.worktrees\ui`(work/ui, c594bed). 지우지 않았다. 지울지는 사용자가 정한다.

## 바꾼 파일
- 새로: `specs/v0.5/` 문서 여섯, `specs/v0.5/cards/`(W-01·C-01 카드와 보고), 이 보고 파일
- 고침: `AGENTS.md`
- 커밋: 이 보고와 같은 커밋(`git log -1 -- specs/v0.5/reports/ORDER-01.md`). push 없음

## 검토
- checker C-01: **PASS** (`specs/v0.5/cards/C-01.report.md`). 3.4의 네 항목과 AGENTS 레포 규칙 불변 확인. 지적 없음.
- 참고로 남긴 것: AGENTS.md 3장·3A에 없어진 `spec` 역할과 v0.4 참조 문장이 남아 있다(아래 미정).
- 검토 중 checker의 명령 승인 요청(읽기 전용 `git diff`, ITEMS·SPEC 대조 pwsh/python 스크립트, 자기 보고 파일 생성)은 leader가 내용을 보고 승인했다.

## 미정
| 미정 | 정할 사람 |
|---|---|
| 루트 `INTENT.md` "다루지 않는 것"과 I-2·I-22 충돌 | ORDER-01-R1(core D-12)로 정리 중 |
| worktree `.worktrees\editor`·`.worktrees\ui` 삭제 여부 | 사용자 |
| 구독 한도 수치(남은 한도·초기화 시점)와 에이전트별 토큰 부담(HERDR-SETUP 3장) | 사용자 |
| 서브 에이전트 승인 요청 대리 응답 위임(v0.4 H-4)을 v0.5에도 잇는지, 기록 위치 | 사용자 |
| `spec/`(zed-metrics.toml 등) 소유자, AGENTS.md 3장의 `spec` 역할 문장, v0.5에서 코드 값을 스펙에 맞추는 카드 범위 | leader 안(案) → 사용자 확정 |
| D-8·D-9 복사 폴더·출처 커밋, D-10 글꼴 파일 | leader(Phase 5·7·3 카드) |
| SPEC의 Zed 확인 값(R-2·5·9·12·14·15·16·23) | 해당 Phase 카드 |
| PLAN 진행 현황 표 갱신자, `tools/` 소유자, leader effort 기록 | leader(다음 카드에서 HERDR-SETUP에 반영) |

## BLOCKED
없음

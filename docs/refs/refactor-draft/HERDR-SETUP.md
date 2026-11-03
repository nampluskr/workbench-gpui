# HERDR-SETUP — workbench-gpui 멀티 에이전트 구성안

- 상태: v0.3 변경안 초안 (2026-11-03, 사용자 승인 대기)
- 이전 상태: 승인됨 (2026-10-31, plan 승인) — v0.1·v0.2 구성
- 작성: wg-leader (2026-10-31), v0.3 변경안 (2026-11-03)
- 가이드: D:\projects\docs\guides\herdr\README.md

## 1. 근거

### v0.1·v0.2 (2026-10-31)

- INTENT.md: "INTENT.md 없음" — 구축 후 project-workflow-compact "1. 신규 시작"으로 만든다
- 사용자 지시: "현재 워크스페이스는 docs\guides\zed-like-editor 에서 gui-kit 으로 구현하는 프로젝트입니다. 1. 상위 project-workflow-compact 에 따라서 작업을 진행해야 합니다. 2. herdr-multi-agent-guide.md 기반으로 herdr 워크스페이스에 멀티 에이젼트 환경을 구축해야 합니다." / "현재 프로젝트는 zed 와 거의 유사하게 구현이 되어야 하므로, 구현되는 결과가 01-zed 에서 조사한 것과 같은지 확인해서 검증해야 합니다. 즉, coder -> opus 5.5 medium 으로 상향 / 코드 구현 결과 적대적 리뷰 - sol medium"
- 사용자에게 확인한 것:
  - reviewer → "Codex sol 리뷰어"
  - scouter → "agy Flash scouter"
  - git → "git init만" (push·원격 없음)
  - 대리 응답 → "leader에게 승인 권한 위임"
  - 일치도 검증 모델 → "agy Argon medium + Sonnet 대체"

### v0.3 (2026-11-03)

- 사용자 지시: "제일 먼저 github.com/nampluskr/workbench-gpui 에 대한 poytail 기반 리팩토링을 해야 합니다." / "v0.3 버젼의 리팩토링 작업을 할려고 합니다. herdr 멀티플레서 환경 - 탭/패널 구성 및 에이젼트 구성 (모델/effort) 을 제안해 주세요."
- 구독 현황(사용자 확인, 2026-11-03): Claude Max, Codex Plus, Gemini Pro(agy). agy Gemini 4 Argon 은 주간 한도 소진 상태
- v0.3 의 성격: 기능 추가가 아닌 리팩토링이다. 완료 기준은 "v0.2 의 동작이 바뀌지 않았다"는 증명이다

## 2. 작업 유형

- 바탕 구성: 가이드 PLANNING.md 6.3 B. 앱·CLI 개발 (+ 6.4 C 포팅의 동등성 검증 성격)
- 페어: Claude 주력
- v0.1·v0.2 에서 바꾼 점:
  - coder를 Sonnet 5.5 · high → Opus 5.5 · medium으로 상향 — 사용자 지시. Zed와 거의 같아야 해서 명세 해석 품질 우선
  - checker(Zed 일치도 검증) 추가, agy Gemini 4 Argon · medium — 사용자 선택. coder(Claude)·reviewer(Codex)와 다른 제3사 모델로 독립 검증, Claude 부담 분산. README 2절 "agy는 Flash만"의 예외. 단계 최종 판정만 high. agy 한도 소진 시 Claude Sonnet 5.5 · high로 교체
  - writer 없음 — 작성 단계 문서(INTENT·DECISIONS·SPEC·PLAN)는 coder가 겸한다
  - runner 2개 — 빌드·테스트와 앱 실행을 분리
- v0.3 에서 바꾸는 점 (리팩토링):
  - **wg-auditor 신설 (Claude Opus 5.5 · high, 읽기 전용)** — ponytail-audit 로 저장소 전체를 감사해 `specs/v0.3/AUDIT.md` 를 쓴다. 감사 결과가 이후 모든 작업의 입력이므로 품질에 투자한다. 영역별로 여러 에이전트에 나누면 모듈을 가로지르는 중복(`ui/watch*` ↔ `fsops/watch`, `ui/keymap` ↔ `keymap/`, `state/path` ↔ `fsops/paths`)을 놓치므로 한 에이전트가 전체를 본다
  - **wg-leader 를 Opus 5.5 · medium → high** — 감사 항목의 채택·보류 판단이 리팩토링의 핵심 판단이다. 판단 위주이고 출력이 짧아 토큰 부담이 작다
  - **wg-reviewer 를 gpt-6.1-sol · medium → high** — 리팩토링 리뷰의 임무는 "동작이 바뀐 곳 찾기" 하나이고, 놓치면 회귀가 된다. 대신 항목 묶음 단위로만 호출해 Codex Plus 한도를 아낀다
  - **wg-checker 의 역할을 Zed 일치도 검증 → 회귀 검증으로 바꾸고 Claude Sonnet 5.5 · high 로 고정** — 회귀 검증은 v0.2 검증 스크립트를 다시 돌려 기준선 JSON·스크린샷과 대조하는 일이라 Argon 이 필요 없다. Argon 한도가 초기화되어도 바꾸지 않는다
  - **wg-coder 는 한 명 유지** — 리팩토링 항목들이 같은 파일을 건드리므로 병렬 coder 는 충돌 비용이 이득보다 크다
  - **wg-scouter 는 필요할 때만** — 감사가 "gpui-kit·의존 크레이트 기능으로 대체"를 제안할 때, 그 API 가 고정 버전(gpui-kit =0.8.1 등)에 실제로 있는지 확인한다

## 3. 탭·패널 배치

| 탭 | 이름 | 패널 |
| --- | --- | --- |
| 1 | control | wg-leader |
| 2 | agents | wg-coder (왼쪽 위), wg-auditor → wg-scouter (왼쪽 아래), wg-reviewer (오른쪽 위), wg-checker (오른쪽 아래) |
| 3 | run | wg-runner-build (위), wg-runner-app (아래) |

```
탭 2 agents                                       탭 3 run
┌──────────────────────┬──────────────────────┐  ┌──────────────────────┐
│ wg-coder             │ wg-reviewer          │  │ wg-runner-build      │
│                      │                      │  │ cargo build/test     │
├──────────────────────┼──────────────────────┤  ├──────────────────────┤
│ wg-auditor (Phase 0) │ wg-checker           │  │ wg-runner-app        │
│ → wg-scouter (필요시) │                      │  │ verify-*.ps1         │
└──────────────────────┴──────────────────────┘  └──────────────────────┘
```

- 왼쪽 아래 패널은 Phase 0 에서 wg-auditor 로 쓴다. 감사가 끝나면 닫고, 필요할 때 같은 자리에 wg-scouter 를 띄운다. 두 에이전트가 동시에 일할 일이 없다

## 4. 에이전트

| 이름 | kind | 모델 · effort | 위치 | 역할 | 파일 수정 범위 |
| --- | --- | --- | --- | --- | --- |
| wg-leader | claude | Opus 5.5 · high | 1 control | 소통·조율, 감사 항목 채택안 작성, 작업 분해, 대리 응답 | docs/HERDR-SETUP.md, docs/HERDR-DECISIONS.md |
| wg-auditor | claude | Opus 5.5 · high | 2 agents 왼쪽 아래 (Phase 0) | ponytail-audit 로 저장소 전체 감사(읽기 전용) | specs/v0.3/AUDIT.md 만 |
| wg-coder | claude | Opus 5.5 · medium | 2 agents 왼쪽 위 | 항목별 리팩토링, specs/v0.3 문서(INTENT·DECISIONS·SPEC·PLAN·PROGRESS) | 프로젝트 전체 (HERDR-*, AUDIT.md, 지난 버전 폴더 제외) |
| wg-reviewer | codex | gpt-6.1-sol · high | 2 agents 오른쪽 위 | 항목 묶음 `git diff` 에서 동작 변화 탐지 | 안 함 |
| wg-checker | claude | Sonnet 5.5 · high | 2 agents 오른쪽 아래 | 기준선 대비 회귀 검증 | 검증 보고서만 (`specs/v0.3/verify/`) |
| wg-scouter | agy | gemini-3.8-flash-low | 2 agents 왼쪽 아래 (필요시) | gpui-kit·크레이트 API 존재 확인(docs.rs·소스) | 안 함 |

auditor 운영 규칙
- 입력: 저장소 전체(읽기 전용), `specs/v0.2/PROGRESS.md` "버전 종료" 절(알려진 한계), `specs/v0.2/DECISIONS.md`
- 항목마다 다음을 적는다: 번호, 태그(delete / dedupe / stdlib / native / yagni / shrink / split / bug / risk / test), `파일:라인` 범위, 현재 코드가 하는 일, 문제, 가장 작은 수정, 예상 줄 수 변화, 수정 위험(Zed 일치 레이아웃·동작 중 무엇이 깨질 수 있는지), 영향받는 v0.2 R-n
- "사용 안 함"으로 판정하기 전에 `src/` 전체, `tools/*.ps1`, `dev.rs` 플래그까지 검색한다
- 입력 검증, 데이터 손실 방지 오류 처리, 보안 관련 코드는 줄이는 대상에서 뺀다
- 요약하지 않는다. 근거가 빠진 항목은 채택 검토에서 제외한다

reviewer 운영 규칙
- 질문은 하나다: "이 diff 가 바뀌기 전과 다른 동작을 만드는 입력·상황이 있는가"
- 발견은 "위치 / 바뀐 동작 / 재현 상황 / 영향 R-n" 형식으로만 보고한다
- 이동만 한 커밋은 이동 외 변경이 섞였는지만 확인한다

checker 운영 규칙
- Phase 0 에서 리팩토링 전 master 로 `tools/verify-v02-phase*.ps1` 전체를 돌려 `specs/v0.3/verify/baseline/` 에 저장한다
- 항목마다 영향받는 R-n 의 검증 스크립트를 다시 돌려 기준선과 대조한다. Phase 끝에는 전체를 다시 돌린다
- 불일치는 "R-n / 기준선 값 / 현재 값 / 증거 파일" 형식으로만 보고 → leader 가 coder 에게 전달
- 기준선 자체가 흔들리는 값(반영 시간 등)은 Phase 0 에서 두 번 돌려 허용 범위를 정해 둔다

## 5. runner

| 이름 | 용도 | 주인 | 작업 폴더 |
| --- | --- | --- | --- |
| wg-runner-build | cargo build / test / clippy, `tools/apply-manifest.ps1` | wg-leader | D:/projects/workbench-gpui |
| wg-runner-app | 앱 실행, `tools/verify-*.ps1` 회귀 검증 | wg-leader | D:/projects/workbench-gpui |

- 빌드할 때마다 `tools/apply-manifest.ps1` 을 다시 실행한다 (v0.1 "버전 종료" 남은 것 5)
- dev 표준출력은 C: 에 둔다. 이동식 D: 에 쓰면 반영 시간 값이 흔들린다 (v0.2 "버전 종료" 환경 사실)

## 6. 토큰 부담

| 구독 | 이 워크스페이스 | 동시에 도는 다른 워크스페이스 |
| --- | --- | --- |
| Claude Max | ● coder(Opus), ◐ leader(Opus high), ◐ auditor(Opus high, Phase 0 집중), ◐ checker(Sonnet) | 시작 때 확인 |
| Codex Plus | ◐ reviewer(Sol high, 항목 묶음 단위) | 없음 |
| agy (Gemini Pro) | ○ scouter(Flash, 필요시) — Argon 사용 안 함 | 없음 |

- Claude 부담이 가장 큰 구간은 Phase 0(auditor)과 Phase 3(파일 분할, coder)이다. 동시 워크스페이스가 늘면 coder 를 Sonnet 5.5 · high 로 내리는 것을 검토한다 (구성 변경이므로 재승인)
- Codex 한도가 바닥나면 reviewer 를 agy gemini-3.8-flash 로 넘긴다. coder 와 같은 계열(Claude)로 리뷰하지 않는다 (구성 변경이므로 재승인)

## 7. 대리 응답 범위

- 가이드 OPERATING.md 1절 기준을 따른다
- 이 프로젝트에서 따로 정한 것:
  - (2026-10-31 사용자 위임) leader가 사용자 승인 권한을 가진다. 하위 에이전트의 결정 요청을 검토해 승인·수정 요청하고, 판단마다 근거를 HERDR-DECISIONS.md에 남긴다
  - 위임 밖: 파일·폴더 삭제, push 등 외부 전송, git 원격 설정
  - 새 크레이트 추가: 02-gpui 3절 G-010~G-025 목록 안이면 승인, 밖이면 사용자에게 올린다
  - 같은 에이전트와의 검증 왕복은 최대 2회 (가이드 기본)
- v0.3 에서 더하는 것:
  - **AUDIT.md 채택 목록은 위임 밖** — leader 가 채택·보류안을 만들고 사용자가 승인한다
  - **소스 파일 삭제는 위임 밖** (기존 규칙 "파일·폴더 삭제") — 예: `src/ui/editor_poc.rs` 를 지우는 항목은 사용자에게 올린다. 파일 안 죽은 코드 삭제는 채택 목록 승인으로 갈음한다
  - **크레이트 제거·버전 변경은 위임 밖** — `Cargo.toml`·`Cargo.lock` 이 바뀌는 항목은 사용자에게 올린다
  - **동작이 바뀌는 수정은 리팩토링이 아니다** — 감사에서 나온 bug·risk 항목을 고치면 동작이 바뀐다. 이런 항목은 따로 표시해 사용자에게 올리고, 승인되면 별도 커밋으로 분리한다

## 8. v0.3 작업 흐름

정식 Phase 정의는 `specs/v0.3/PLAN.md` 에 둔다. 아래는 구성안 기준의 흐름이다.

| Phase | 내용 | 주 담당 |
| --- | --- | --- |
| 0 | 기준선 저장(master 에서 v0.2 검증 전체) + ponytail-audit → AUDIT.md → 채택 목록 사용자 승인 | checker, auditor, leader |
| 1 | 삭제: 죽은 코드, 쓰지 않는 PoC 코드(삭제 여부는 사용자 승인) | coder |
| 2 | 중복 통합: 공용 헬퍼를 한 벌로 | coder |
| 3 | 파일 분할: 큰 파일(`folders.rs`, `app_menu.rs`, `ui/mod.rs` 등)을 책임 단위로 | coder |
| 4 | dev.rs 격리: 검증 하네스를 release 빌드와 분리 | coder |

- 삭제를 먼저 해서 코드를 줄인 뒤 통합·분할한다. 분할은 코드를 옮겨 diff 가 커지므로 마지막에 가깝게 둔다
- 항목마다: coder 수정 → runner-build(build·test·clippy·apply-manifest) → reviewer diff 리뷰 → checker 관련 R-n 회귀 대조 → PROGRESS 기록 → 커밋
- 파일 분할은 "이동만 하는 커밋"과 "로직을 바꾸는 커밋"을 나눈다
- Phase 끝마다 v0.2 검증 전체를 다시 돌린다. 미해결 실패가 있으면 다음 Phase 로 넘어가지 않는다 (v0.1·v0.2 PLAN 과 같은 규칙)
- 에이전트 사이 전달은 채팅이 아닌 파일로 한다: AUDIT.md(감사), PROGRESS.md(항목별 결과), `specs/v0.3/verify/`(회귀 증거)

## 9. 정리 방법

- 닫을 탭·패널: wg-auditor 패널은 Phase 0 감사 확정 뒤 닫는다. 탭 2 agents, 탭 3 run 은 사용자가 닫으라고 할 때까지 유지
- 지울 worktree: 없음
- 남길 것: 탭 1 control (wg-leader)

## 10. 변경 이력

| 날짜 | 내용 | 승인 |
| --- | --- | --- |
| 2026-10-31 | 초안 작성, plan 승인으로 승인 | 사용자 승인 |
| 2026-10-31 | coder Opus · medium 상향, checker(agy Argon) 추가 (사용자 지시·선택) | 사용자 승인 |
| 2026-11-01 | checker 를 agy Argon → Claude Sonnet 5.5 · high 로 교체 (agy 개별 한도 소진, 초기화 120시간 뒤). 같은 패널 wB:p5, 이름 wg-checker 유지 | 4절 "agy 한도 소진 시 교체" 규칙 (사전 승인) |
| 2026-11-02 | GitHub 공개 저장소 nampluskr/workbench-gpui 생성, 원격 origin 설정, master 푸시 (1절 "git init만"에서 바뀜) | 사용자 지시 "깃헙 레포를 public 으로 생성하고 푸시해 주세요" |
| 2026-11-03 | v0.3 리팩토링 구성: wg-auditor 신설(Opus · high), leader high 상향, reviewer Sol high 상향, checker 를 회귀 검증·Sonnet · high 로 고정, scouter 필요시 운용, 대리 응답 위임 밖 항목 추가, 8절 작업 흐름 추가 | 사용자 승인 대기 |

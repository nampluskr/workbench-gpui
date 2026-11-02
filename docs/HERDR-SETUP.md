# HERDR-SETUP — workbench-gpui 멀티 에이전트 구성안

- 상태: 승인됨 (2026-10-31, plan 승인)
- 작성: wg-leader (2026-10-31)
- 가이드: D:\projects\docs\guides\herdr\README.md

## 1. 근거

- INTENT.md: "INTENT.md 없음" — 구축 후 project-workflow-compact "1. 신규 시작"으로 만든다
- 사용자 지시: "현재 워크스페이스는 docs\guides\zed-like-editor 에서 gui-kit 으로 구현하는 프로젝트입니다. 1. 상위 project-workflow-compact 에 따라서 작업을 진행해야 합니다. 2. herdr-multi-agent-guide.md 기반으로 herdr 워크스페이스에 멀티 에이젼트 환경을 구축해야 합니다." / "현재 프로젝트는 zed 와 거의 유사하게 구현이 되어야 하므로, 구현되는 결과가 01-zed 에서 조사한 것과 같은지 확인해서 검증해야 합니다. 즉, coder -> opus 5.5 medium 으로 상향 / 코드 구현 결과 적대적 리뷰 - sol medium"
- 사용자에게 확인한 것:
  - reviewer → "Codex sol 리뷰어"
  - scouter → "agy Flash scouter"
  - git → "git init만" (push·원격 없음)
  - 대리 응답 → "leader에게 승인 권한 위임"
  - 일치도 검증 모델 → "agy Argon medium + Sonnet 대체"

## 2. 작업 유형

- 바탕 구성: 가이드 PLANNING.md 6.3 B. 앱·CLI 개발 (+ 6.4 C 포팅의 동등성 검증 성격)
- 페어: Claude 주력
- 바꾼 점:
  - coder를 Sonnet 5.5 · high → Opus 5.5 · medium으로 상향 — 사용자 지시. Zed와 거의 같아야 해서 명세 해석 품질 우선
  - checker(Zed 일치도 검증) 추가, agy Gemini 4 Argon · medium — 사용자 선택. coder(Claude)·reviewer(Codex)와 다른 제3사 모델로 독립 검증, Claude 부담 분산. README 2절 "agy는 Flash만"의 예외. 단계 최종 판정만 high. agy 한도 소진 시 Claude Sonnet 5.5 · high로 교체
  - writer 없음 — 작성 단계 문서(INTENT·DECISIONS·SPEC·PLAN)는 coder가 겸한다
  - runner 2개 — 빌드·테스트와 앱 실행을 분리

## 3. 탭·패널 배치

| 탭 | 이름 | 패널 |
| --- | --- | --- |
| 1 | control | wg-leader |
| 2 | agents | wg-coder (왼쪽 위), wg-scouter (왼쪽 아래), wg-reviewer (오른쪽 위), wg-checker (오른쪽 아래) |
| 3 | run | wg-runner-build (위), wg-runner-app (아래) |

```
탭 2 agents                                       탭 3 run
┌──────────────────────┬──────────────────────┐  ┌──────────────────────┐
│ wg-coder             │ wg-reviewer          │  │ wg-runner-build      │
│                      │                      │  │ cargo build/test     │
├──────────────────────┼──────────────────────┤  ├──────────────────────┤
│ wg-scouter           │ wg-checker           │  │ wg-runner-app        │
└──────────────────────┴──────────────────────┘  └──────────────────────┘
```

## 4. 에이전트

| 이름 | kind | 모델 · effort | 위치 | 역할 | 파일 수정 범위 |
| --- | --- | --- | --- | --- | --- |
| wg-leader | claude | Opus 5.5 · medium | 1 control | 소통·조율, 작업 분해, 대리 응답 | docs/HERDR-SETUP.md, docs/HERDR-DECISIONS.md |
| wg-coder | claude | Opus 5.5 · medium | 2 agents 왼쪽 위 | 루트 INTENT·AGENTS·CLAUDE.md, specs/ 문서, Rust 구현·테스트 | 프로젝트 전체 (HERDR-* 제외) |
| wg-scouter | agy | gemini-3.8-flash-low | 2 agents 왼쪽 아래 | gpui-kit·docs.rs 조사 요약 (02-gpui 5절 G-100~) | 안 함 |
| wg-reviewer | codex | gpt-6.1-sol · medium | 2 agents 오른쪽 위 | Phase 끝 `git diff` 적대적 코드 리뷰 | 안 함 |
| wg-checker | agy | gemini-4-argon-medium (최종 판정 high, 대체 Sonnet 5.5 · high) | 2 agents 오른쪽 아래 | Zed 일치도 검증: 단계별 항목 ID(L-/I-/E-/P-/K-/X-/T-/A-)를 스크린샷·측정값과 대조, 04-COMPARISON 체크리스트·A-32(±1px)·A-35 기준 | 검증 보고서만 (`specs/<버전>/verify/`) |

checker 운영 규칙
- 명세 전체가 아니라 그 단계의 항목 ID 절만 넘긴다
- 판정은 증거로: wg-runner-app으로 앱 실행 → 창 스크린샷(기준 화면과 같은 창 크기·DPI) + 측정값(px, hex 색, 키 바인딩 덤프)을 기준 PNG(`D:\projects\docs\guides\zed-like-editor\01-zed\assets\zed-reference*.png`)와 명세 수치에 대조
- 불일치는 "항목 ID / 명세 값 / 실제 값 / 증거 파일" 형식으로만 보고 → leader가 coder에게 전달

## 5. runner

| 이름 | 용도 | 주인 | 작업 폴더 |
| --- | --- | --- | --- |
| wg-runner-build | cargo build / test / clippy | wg-leader | D:/projects/workbench-gpui |
| wg-runner-app | 앱 실행 (검증용 스크린샷) | wg-leader | D:/projects/workbench-gpui |

## 6. 토큰 부담

| 구독 | 이 워크스페이스 | 동시에 도는 다른 워크스페이스 |
| --- | --- | --- |
| Claude | ◐ leader, ● coder(Opus) | projects(wA): leader 1개, idle |
| Codex | ◐ reviewer (Phase 끝) | 없음 |
| agy | ◐ checker(Argon), ○ scouter(Flash) — 같은 한도 공유, checker 우선 | 없음 |

동시 워크스페이스가 늘면 coder를 Sonnet 5.5 · high로 되돌리는 것을 검토한다 (구성 변경이므로 재승인).

## 7. 대리 응답 범위

- 가이드 OPERATING.md 1절 기준을 따른다
- 이 프로젝트에서 따로 정한 것:
  - (2026-10-31 사용자 위임) leader가 사용자 승인 권한을 가진다. 하위 에이전트의 결정 요청을 검토해 승인·수정 요청하고, 판단마다 근거를 HERDR-DECISIONS.md에 남긴다
  - 위임 밖: 파일·폴더 삭제, push 등 외부 전송, git 원격 설정
  - 새 크레이트 추가: 02-gpui 3절 G-010~G-025 목록 안이면 승인, 밖이면 사용자에게 올린다
  - 같은 에이전트와의 검증 왕복은 최대 2회 (가이드 기본)

## 8. 정리 방법

- 닫을 탭·패널: 탭 2 agents, 탭 3 run — 사용자가 닫으라고 할 때까지 유지
- 지울 worktree: 없음
- 남길 것: 탭 1 control (wg-leader)

## 9. 변경 이력

| 날짜 | 내용 | 승인 |
| --- | --- | --- |
| 2026-10-31 | 초안 작성, plan 승인으로 승인 | 사용자 승인 |
| 2026-10-31 | coder Opus · medium 상향, checker(agy Argon) 추가 (사용자 지시·선택) | 사용자 승인 |
| 2026-11-02 | GitHub 공개 저장소 nampluskr/workbench-gpui 생성, 원격 origin 설정, master 푸시 (1절 "git init만"에서 바뀜) | 사용자 지시 "깃헙 레포를 public 으로 생성하고 푸시해 주세요" |
| 2026-11-01 | checker 를 agy Argon → Claude Sonnet 5.5 · high 로 교체 (agy 개별 한도 소진, 초기화 120시간 뒤). 같은 패널 wB:p5, 이름 wg-checker 유지 | 4절 "agy 한도 소진 시 교체" 규칙 (사전 승인) |

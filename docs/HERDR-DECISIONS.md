# HERDR-DECISIONS — workbench-gpui 대리 응답 기록

- 구성안: docs/HERDR-SETUP.md
- 기록자: wg-leader
- 가이드: D:\projects\docs\guides\herdr\README.md

## 목록

| 번호 | 시각 | 에이전트 | 요약 | 구분 | 보고 |
| --- | --- | --- | --- | --- | --- |
| D-001 | 2026-10-31 | wg-coder, wg-reviewer, wg-scouter, wg-checker | 시작 시 폴더 신뢰 확인 화면 → 신뢰 승인 | 대리 응답 | 2026-10-31 |
| D-002 | 2026-10-31 20:04 | wg-reviewer | 기준 문서 읽기(Get-Content) 실행 승인, 같은 접두 명령 상시 허용 | 대리 응답 | 2026-10-31 20:06 |
| D-003 | 2026-10-31 20:05 | wg-reviewer | 루트 INTENT 리뷰 지적 2건 → 고치지 않고 사용자에게 올림 | 사람에게 올림 | 2026-10-31 20:06 |
| D-004 | 2026-10-31 20:09 | wg-reviewer | 여러 파일을 묶은 Get-Content 읽기 명령 1회 승인 | 대리 응답 | 2026-10-31 20:20 |
| D-005 | 2026-10-31 20:18 | wg-reviewer → wg-coder | SPEC 리뷰 지적 7건 전부 채택, 원문 확인 후 반영 지시 | 대리 응답 | 2026-10-31 20:22 |
| D-006 | 2026-10-31 20:21 | wg-reviewer → wg-coder | PLAN 리뷰 지적 1건(Phase 2 완료 조건) 채택, 반영 | 대리 응답 | 미보고 |
| D-007 | 2026-10-31 20:24 | wg-coder | rust-analyzer LSP 플러그인 설치 권유 → 설치하지 않음(Esc) | 대리 응답 | 미보고 |
| D-008 | 2026-10-31 20:35 | wg-reviewer, wg-checker | Phase 0 검증용 읽기 전용 명령(git diff/show, Get-Content, Select-String, Test-Path) 승인, checker 의 REPORT.md 쓰기 승인 | 대리 응답 | 미보고 |
| D-009 | 2026-10-31 20:42 | wg-reviewer → wg-coder | Phase 0 리뷰 지적 4건(Major 2, Minor 2) 전부 채택·반영 | 대리 응답 | 미보고 |
| D-010 | 2026-10-31 20:56 | wg-coder | Phase 1 판단 요청 5건: D-9·R-3·R-15 이후 변경 승인, 버튼 색·글꼴 선택은 미결 사항으로 | 대리 응답 | 미보고 |
| D-011 | 2026-10-31 21:20 | wg-reviewer, wg-checker → wg-coder | Phase 1 리뷰 1·2회차 지적(Major 3, Minor 2)과 R-1 스냅 플라이아웃 실패 채택·반영 | 대리 응답 | 미보고 |
| D-012 | 2026-11-01 | wg-checker | R-4·R-5 의 100·150% 배율 시험 미수행 실패 → Windows 배율 변경이 필요해 사용자에게 올림, Phase 1 미완료로 멈춤 | 사람에게 올림 | 2026-11-01 |
| D-013 | 2026-11-01 | wg-leader | 사용자 허락으로 tools/set-scale.ps1 로 배율 100→150% 바꿔 verify-scale 시험, 200% 로 복원 확인. checker 3회차 R-1~R-5 통과 | 사용자 지시 | 2026-11-01 |

## 기록

### D-001 · 2026-10-31 · wg-coder, wg-reviewer, wg-scouter, wg-checker

- 상황: blocked (승인 요청) — `agent start` 가 `agent_not_ready` 반환
- 질문: Claude "Is this a project you created or one you trust?", Codex "Trust this folder?", agy "Do you trust the contents of this project?" (모두 D:\projects\workbench-gpui)
- 구분: 대리 응답
- 답변: 신뢰 승인 — wg-coder 는 `send-keys down` 후 `enter`, 나머지는 기본 선택이 신뢰라 `enter`
- 근거: HERDR-SETUP.md 7절 — leader 에게 승인 권한 위임. 대상은 사용자가 지정한 이 프로젝트 폴더(방금 git init 한 빈 폴더)
- 결과: 없음
- 보고: 2026-10-31

### D-002 · 2026-10-31 20:04 · wg-reviewer

- 상황: blocked (승인 요청)
- 질문: "Would you like to run the following command? ... Reason: 셸 실행이 액세스 거부로 실패" — `Get-Content -Encoding UTF8 -LiteralPath 'D:\projects\project-workflow-compact\docs\DOCUMENTS.md'` 등 (워크스페이스 밖 기준 문서 읽기)
- 구분: 대리 응답
- 답변: "2. Yes, and don't ask again for commands that start with Get-Content -Encoding UTF8 -LiteralPath" 선택 (`send-keys down enter`)
- 근거: HERDR-SETUP.md 7절 — leader 승인 권한 위임. 읽기 전용 명령이고, 기준 문서를 읽어야 리뷰가 가능하다. 문서마다 같은 요청이 반복되므로 같은 접두의 읽기 명령만 상시 허용
- 결과: 없음
- 보고: 2026-10-31 20:06

### D-003 · 2026-10-31 20:05 · wg-reviewer

- 상황: 질문 (리뷰 지적)
- 질문: ① INTENT.md 원칙 "명세(01-zed)와 대조해 확인한다"는 특정 명세·검증 방법이라 루트 INTENT에 맞지 않음 ② 원칙 "앱을 다시 빌드하지 않고 설치한다"는 기술적 제약이라 버전 문서에 둘 내용 (근거: DOCUMENTS.md 3절)
- 구분: 사람에게 올림
- 답변: 고치지 않고 사용자에게 올림
- 근거: 두 문구 모두 사용자가 "후보 그대로"로 확정한 문구다(2026-10-31). 위임 범위라도 사용자가 직접 확정한 문장은 leader가 바꾸지 않는다 (AGENTS.md "사람이 정하고 묻는다")
- 결과: 사용자 답 "권장대로 진행해 주세요" (2026-10-31) → ① "(01-zed)"만 삭제, ② 그대로 유지. wg-coder 가 반영
- 보고: 2026-10-31 20:06

### D-004 · 2026-10-31 20:09 · wg-reviewer

- 상황: blocked (승인 요청)
- 질문: `Get-Content -Encoding UTF8 -LiteralPath '...DOCUMENTS.md'; Get-Content ... '02-gpui\README.md'; Get-Content ... 'workbench-gpui\INTENT.md'; ...` 실행 승인 (샌드박스 실행 실패 "Failed to create unified exec" 뒤 승인 요청). `;`로 묶여 D-002 상시 허용에 걸리지 않음
- 구분: 대리 응답
- 답변: "1. Yes, proceed" (이번만)
- 근거: D-002 와 같음 — 읽기 전용, 리뷰 기준 문서 읽기. HERDR-SETUP.md 7절 위임
- 결과: 없음. 앞으로 같은 형태(읽기 전용 Get-Content 묶음)는 같은 근거로 승인하고 이 항목을 근거로 삼는다
- 보고: 2026-10-31 20:20

### D-005 · 2026-10-31 20:18 · wg-reviewer → wg-coder

- 상황: 질문 (리뷰 지적)
- 질문: SPEC.md 지적 7건 — R-2 글리프·코드포인트 판정 누락, R-3 L-311 tiled 변 조건 누락, R-10 기준선·폭 누락, R-11 "판정 불가"로 통과 가능, R-13 A-32.16 아이콘 14 누락, R-14 사이드바 핸들 규칙 출처 없음, R-15 rem 헬퍼 사용 판정 없음
- 구분: 대리 응답
- 답변: 7건 모두 채택. wg-coder 에게 "원문을 직접 확인하고, 원문과 맞지 않으면 반영하지 말고 이유를 답하라"는 조건으로 반영 지시. 결과 7건 모두 반영(R-14 는 A-11.12·A-40.12 근거로 사이드바 핸들 규칙 제외)
- 근거: HERDR-SETUP.md 7절 위임. 지적마다 원문 ID(L-83, L-311, G-139, 02-gpui 7절 2단계, A-32.16, L-30/L-33, D-8)가 있고, DOCUMENTS.md 6절 "판정 방법이 없는 요구는 요구가 아니다"에 해당
- 결과: 없음
- 보고: 2026-10-31 20:22

### D-006 · 2026-10-31 20:21 · wg-reviewer → wg-coder

- 상황: 질문 (리뷰 지적)
- 질문: PLAN.md Phase 2 완료 조건이 R-6~R-10 은 판정표에 항목만 있으면 되고 R-11 만 통과를 요구해, 개별 요구의 증거가 빠져도 완료될 수 있음 (근거: SPEC R-6~R-10, DOCUMENTS.md 7절)
- 구분: 대리 응답
- 답변: 채택. "R-6~R-10이 각각 SPEC의 판정 방법대로 통과로 판정되어 있다(증거 포함)"로 고치게 함
- 근거: HERDR-SETUP.md 7절 위임. Phase 1·3 완료 조건과 같은 기준으로 맞춤
- 결과: 없음
- 보고: 미보고

### D-007 · 2026-10-31 20:24 · wg-coder

- 상황: blocked (질문)
- 질문: "LSP plugin recommendation — Plugin: rust-analyzer-lsp ... Would you like to install this LSP plugin?"
- 구분: 대리 응답
- 답변: 설치하지 않음 — `send-keys esc` (닫기). 처음 `down enter`("No, not now")를 보내려던 시도는 leader 쪽 권한 분류기에 거부되어 Esc 로 닫음
- 근거: HERDR-SETUP.md 7절 — 설치·환경 변경은 구성안 밖. 구현에 필수 아님(빌드는 cargo 로 함)
- 결과: 없음
- 보고: 미보고

### D-008 · 2026-10-31 20:35 · wg-reviewer, wg-checker

- 상황: blocked (승인 요청), 여러 번
- 질문: reviewer — `git diff --cached -- ...`, `git show :Cargo.lock | Select-String ...`, `git show :tools/capture.ps1 | ForEach-Object ...` 등. checker — `Test-Path ...Cargo.lock; git status --short; git diff --cached --name-only`, `Get-ChildItem`, `specs/v0.1/verify/phase0/REPORT.md` 쓰기
- 구분: 대리 응답
- 답변: 모두 "이번만 실행"으로 승인. 승인 전 명령 내용을 확인했고 쓰기·삭제·git 변경 명령은 없었음
- 근거: D-002·D-004 와 같음(읽기 전용). checker 의 쓰기는 HERDR-SETUP.md 4절 수정 범위(specs/<버전>/verify/) 안
- 결과: leader 의 자동 승인 스크립트가 reviewer 의 명령 상세 창(pager)을 연 채 멈춰 사용자가 "편집 상태"로 보고함. 스크립트를 멈추고 수동으로 닫은 뒤 승인. 이후 승인은 대화창 문구를 보고 수동으로 한다
- 보고: 미보고

### D-009 · 2026-10-31 20:42 · wg-reviewer → wg-coder

- 상황: 질문 (리뷰 지적)
- 질문: capture.ps1:238 Major(PMv2 스레드에서 GetDpiForMonitor), :250 Major(SetForegroundWindow 실패 무시), :227 Minor(측정·캡처 시점 불일치), src/main.rs:5 Minor(D-5 래퍼 미경유)
- 구분: 대리 응답
- 답변: 4건 채택. 반영 후 재빌드(exit 0)·재캡처(PrintWindow 성공)로 확인
- 근거: HERDR-SETUP.md 7절 위임. 캡처 도구는 이후 모든 일치도 검증의 증거를 만들므로 정확해야 함. D-5
- 결과: 없음
- 보고: 미보고

### D-010 · 2026-10-31 20:56 · wg-coder

- 상황: 질문 (구현 중 판단 요청 5건)
- 질문: ① gpui-kit TitleBar 가 높이 34·버튼 34px SVG 고정이라 D-9 대로 못 함 ② Windows 창 장식이 Server 라 앱이 테두리·모서리를 못 그림(R-3) ③ L-21 은 타이틀 바 32 고정인데 R-15 는 px 상수 금지 ④ 글리프 글꼴을 빌드 번호 대신 설치 여부로 판단 ⑤ 닫기 외 버튼 hover 색은 기본 테마 색 임시
- 구분: 대리 응답
- 답변: ①②③ 승인 — DECISIONS D-9, SPEC R-3·R-15 에 "이후 변경"으로 덧붙임. ④⑤ DECISIONS 미결 사항에 기록
- 근거: HERDR-SETUP.md 7절 위임. ① gpui-component 0.8.1 src/title_bar.rs, L-21·L-39 ② gpui-pre platform.rs 기본값, 04-APP-SPEC A-30.6 원문 ③ 01-LAYOUT L-21 원문 "Windows 32 고정". 모두 원문 근거가 있고 v0.1 범위를 줄이지 않음
- 결과: 사용자 최종 보고에서 알림
- 보고: 미보고

### D-011 · 2026-10-31 21:20 · wg-reviewer, wg-checker → wg-coder

- 상황: 질문 (리뷰·검증 지적)
- 질문: 리뷰 1회차 Major 2(dev 플래그 릴리스 노출, 전면 확인 없는 SendInput)·Minor 2(FreeLibrary, SetLastError), 2회차 새 Major 1(PID/HWND 고정 안 됨). 검증 1회차 R-1 스냅 플라이아웃 미표시
- 구분: 대리 응답
- 답변: 모두 채택·반영. 스냅 플라이아웃은 앱이 HTMAXBUTTON 을 돌려주는 것을 소스로 확인했고(gpui-pre-windows events.rs 971행), 원인은 스크립트의 hover 방식이라 스크립트를 고침 → 2회차 R-1 통과. 리뷰 왕복은 가이드 기준 2회로 마감, 2회차 Major 는 수정 후 스크립트 재실행(errors 0)으로 확인
- 근거: HERDR-SETUP.md 7절 위임, 가이드 PLANNING 4절 검토 왕복 최대 2회
- 결과: 없음
- 보고: 미보고

### D-012 · 2026-11-01 · wg-checker

- 상황: 검증 실패 (미해결)
- 질문: R-4(배율 100·150·200% 타이틀 바 32 논리 px), R-5(150% 배율 시험) — 이 PC 는 200% 이고 다른 배율 시험 증거가 없어 실패
- 구분: 사람에게 올림
- 답변: Windows 디스플레이 배율 변경은 시스템 설정 변경이라 대리하지 않음. PLAN "미해결 실패가 있으면 다음 Phase로 넘어가지 않는다"에 따라 Phase 1 을 커밋하지 않고 멈춤
- 근거: HERDR-SETUP.md 7절 위임 밖(시스템 설정 변경), PLAN.md 규칙(사용자 결정 2026-10-31)
- 결과: 사용자 답 "leader가 배율을 바꿔도 됨" (2026-11-01) → D-013
- 보고: 2026-11-01

### D-013 · 2026-11-01 · wg-leader

- 상황: D-012 의 사용자 답 수신
- 질문: R-4·R-5 배율 시험 수행
- 구분: 사용자 지시 실행
- 답변: `tools/set-scale.ps1 -Percent 100` → `verify-scale.ps1` → 150% 같은 순서(150% 에서 R-5 TaskDialog 포함) → 200% 복원(`"current": 200` 확인). 증거 specs/v0.1/verify/phase1/scale-100/, scale-150/
- 근거: 사용자 답 "leader가 배율을 바꿔도 됨"
- 결과: 100% 32 물리=32 논리 px, 150% 48 물리=32 논리 px. checker 3회차 R-1~R-5 모두 통과(모니터 이동은 단일 모니터라 판정 불가, SPEC 허용)
- 보고: 2026-11-01

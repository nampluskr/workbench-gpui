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

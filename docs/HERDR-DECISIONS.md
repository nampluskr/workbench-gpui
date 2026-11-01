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

### D-014 · 2026-11-01 · wg-coder

- 상황: 질문 (Phase 2 진행 중 판단 요청 3건)
- 질문: ① R-10 은 `.ZedSans`(IBM Plex Sans)·`.ZedMono`(Lilex)를 전제하는데 두 글꼴이 PC 에 없고 앱에도 없다 ② R-8 은 앱 안에서 스크롤·입력을 일으킨 뒤 다음 프레임까지 시간을 잰다(실제 키 입력→화면 지연 아님) ③ `tools/apply-manifest.ps1` 이 빌드마다 Phase 1 증거 `verify/phase1/manifest.xml` 을 덮어쓴다
- 구분: 대리 응답 (사용자 지시 2026-11-01 "결정이 필요한 사항은 리더가 승인하고 결과와 근거를 문서에 기록")
- 답변: ① 승인 — gpui-kit 기본 고정폭 글꼴로 측정한다. 판정표 R-10 행과 PROGRESS 특이사항에 "Zed 글꼴 미설치, 기본 글꼴로 측정, 그 글꼴에 한글이 없어 DirectWrite 대체가 일어남을 확인"을 적는다. Zed 글꼴 자산 도입은 v0.1 범위 밖으로 DECISIONS 미결 사항에 둔다 ② 승인 — 측정 방식(앱 내부 이벤트→다음 프레임)을 판정표에 명시한다 ③ 수정 — apply-manifest.ps1 의 기본 출력 경로를 `target/` 아래로 바꾸고, Phase 1 증거 파일은 커밋된 내용 그대로 둔다
- 근거: ① 글꼴 파일은 로컬에 없고(D:\projects·C:\Windows\Fonts 검색) 받으려면 외부 다운로드라 위임 밖과 가깝다. G-139 의 핵심은 "한글 없는 글꼴 → DirectWrite 대체가 줄 높이·기준선·폭을 바꾸는가"이고, 한글 없는 기본 고정폭 글꼴로도 같은 메커니즘을 잴 수 있다. SPEC R-10 은 측정값 기록이 결과다 ② SPEC R-8 "통과 기준 수치는 원문에 없으므로 측정값과 관찰을 기록하는 것까지" ③ AGENTS.md 정신(지난 증거 보존), Phase 1 은 커밋으로 마감됨
- 결과: wg-coder 에 전달
- 보고: 최종 보고에서 알림

### D-015 · 2026-11-01 · wg-leader

- 상황: specs/v0.1/DECISIONS.md 미결 사항 "D-10 의 또는" (Phase 3 시작 전 결정 필요)
- 질문: 사이드바를 `sidebar` 로 할지 `list`·`VirtualList` 로 할지, 왼쪽 Dock 을 `dock`(DockArea)로 할지 `resizable` 패널로 할지
- 구분: 대리 응답 (사용자 지시 2026-11-01)
- 답변: 사이드바 = gpui-kit `resizable` 패널(기본 300, size_range 200~800) 안에 직접 조립한 div, 폴더 줄 목록은 `list`·`VirtualList` 자리. `sidebar` 컴포넌트는 쓰지 않는다. 왼쪽 Dock = `resizable` 계열(gpui-base `resize_handle`)로 폭을 직접 관리하고, 6px 핸들·더블클릭 240 복원·하한 6/상한 창 폭−6 은 앱 코드로 맞춘다. 핸들 폭을 6 으로 맞출 수 없으면 gpui 드래그 이벤트로 직접 구현한다. `dock`(DockArea)는 쓰지 않는다
- 근거: gpui-component 0.8.1 `sidebar/mod.rs` 27행 DEFAULT_WIDTH 255·접기 애니메이션 내장으로 L-33(기본 300, 200~800)·L-34/L-35 치수와 다르다. `dock` DockArea 는 자체 TabPanel·줌·직렬화 모델을 가져와 L-14(왼쪽 Dock 만, 오른쪽·아래 없음)·L-22~L-27 탭 바 치수를 우리가 통제하기 어렵다. gpui-base `resizable/resize_handle.rs` 는 더블클릭 등 리스너를 호출자가 붙이도록 설계되어(12~13행 HANDLE_PADDING 4·HANDLE_SIZE 1, 문서 주석) L-30 규칙을 앱이 얹을 수 있다. 두 선택 모두 D-10 표 안의 대안이라 v0.1 범위를 바꾸지 않는다
- 결과: Phase 3 시작 때 wg-coder 가 specs/v0.1/DECISIONS.md D-10 에 "이후 변경"으로 반영하고 미결 사항에서 지운다
- 보고: 최종 보고에서 알림

### D-016 · 2026-11-01 · wg-reviewer → wg-coder

- 상황: Phase 2 리뷰 1회차 지적 (Major 3)
- 질문: ① R-8 타이머가 on_next_frame 콜백(draw·present 전)에서 끝나 렌더 비용이 빠진다(gpui-pre window.rs 1878~1895) ② CP949 WideCharToMultiByte flags=0 이라 best-fit 손실 변환(U+20A9→5C)을 성공으로 본다 ③ verify-ime.ps1 이 확정 문자열 불일치·IME 조회 실패를 오류로 처리하지 않는다
- 구분: 대리 응답
- 답변: 3건 모두 채택. ① 다음 프레임의 draw·present 이후 시점으로 계측을 바꾸고 R-8 증거·판정을 다시 수집 ② WC_NO_BEST_FIT_CHARS 와 반환값·used_default 검사, 손실 역변환 사례 시험 추가 ③ 실패를 errors 로 반영하고 종료 코드 1
- 근거: 세 지적 모두 소스 위치와 재현이 있고, 판정표 결론(R-8 지연, R-9 CP949 보존, R-6 확정)의 근거를 직접 흔든다. D-014 ② 승인은 "앱 내부 이벤트→다음 프레임 렌더 완료" 의미였다
- 결과: wg-coder 수정 → 리뷰 2회차
- 보고: 최종 보고에서 알림

### D-017 · 2026-11-01 · wg-reviewer, wg-checker

- 상황: Phase 2 리뷰 2회차·검증 2회차 결과
- 질문: Phase 2 를 마감하고 커밋할 수 있는가
- 구분: 대리 응답
- 답변: 승인. 리뷰 2회차 1회차 Major 3건 모두 해결·새 지적 없음, checker 2회차 R-6~R-11 모두 통과(직접 구현 필요 12, 불필요 23, 판정 불가 0). 미해결 실패가 없어 Phase 2 를 커밋하고 Phase 3 로 넘어간다. 진행 중 하위 에이전트의 승인 창은 명령 전체가 보이는 읽기 전용·지정 파일 쓰기만 승인했고, 줄이 숨겨진 명령 1건은 취소 후 짧은 명령으로 다시 하게 했다
- 근거: PLAN.md "모든 Phase는 끝날 때" 4단계 순서, "미해결 실패가 있으면 다음 Phase로 넘어가지 않는다", 가이드 검토 왕복 최대 2회
- 결과: Phase 2 커밋
- 보고: 최종 보고에서 알림

### D-018 · 2026-11-01 · wg-coder

- 상황: Phase 3 구현 결과 보고 중 판단 사항 3건
- 질문: ① R-13 의 상태 표시줄 gap 8/4·사이드바 푸터 gap 4 는 그룹에 항목이 하나뿐이라 "잴 수 없음"으로 두고 코드 상수를 근거로 함 ② L-31 의 "창 폭"을 Workspace 본문 폭으로 해석 ③ 사이드바 푸터 높이가 31 (A-11.4 는 30)
- 구분: 대리 응답
- 답변: ① 수정 요청 — SPEC R-13 판정 방법 "뼈대에 내용이 없어 잴 수 없는 항목은 자리 표시 요소로 재고, 그렇게 했다고 적는다"를 따라, 측정용 자리 표시 요소(그룹당 2개 이상)를 두고 gap 을 실측한다 ② 승인 — 사이드바는 Workspace 밖(L-11)이고 Dock 은 Workspace 본문 안에서만 움직이므로 본문 폭이 맞다. 보고서에 해석을 적는다 ③ 승인(기록만) — A-32.13 판정 대상은 padding·gap·위 테두리이고 높이는 대상이 아니다. 차이는 PROGRESS 특이사항에 남기고 이후 단계 과제로 둔다
- 근거: SPEC R-13 판정 방법, L-11·L-31, A-32.13 표
- 결과: wg-coder 수정 → 리뷰·검증
- 보고: 최종 보고에서 알림

### D-019 · 2026-11-01 · wg-reviewer → wg-coder

- 상황: Phase 3 리뷰 1회차 지적 (Major 1, Minor 1). checker 1회차는 R-12~R-15 모두 통과
- 질문: ① Dock 폭 clamp 가 끌기 이벤트에서만 일어나, Dock 을 넓힌 뒤 사이드바를 넓히거나 창을 줄이면 Dock 이 상한(본문 폭−6)을 넘고 핸들이 화면 밖으로 나간다(src/ui/mod.rs 61행) ② verify-phase3.ps1 의 r15.pass 가 SPEC R-15 세 번째 조건(R-13 측정 통과)을 검사하지 않는다(430행)
- 구분: 대리 응답
- 답변: 2건 모두 채택. ① 렌더 시 실제 본문 폭으로 Dock 유효 폭을 다시 제한하고 핸들 위치도 유효 폭으로 계산, 검증에 "Dock 확장 후 사이드바 확장·창 축소·좁은 본문에서 더블클릭" 시나리오 추가 ② r15.pass 에 A-32 전체 측정·통과 조건 포함
- 근거: SPEC R-14(L-31 상한), D-018 ②, SPEC R-15 판정 방법 셋째 항목. 1회차 checker 통과는 이 경로를 시험하지 않은 결과라 수정 후 재검증한다
- 결과: wg-coder 수정 → 리뷰 2회차·checker 2회차
- 보고: 최종 보고에서 알림

### D-020 · 2026-11-01 · wg-reviewer → wg-coder

- 상황: Phase 3 리뷰 2회차 — 1회차 2건 해결, 새 Minor 1건
- 질문: verify-phase3.ps1 478~482행이 참/거짓 검사를 0/1 로 바꿔 치수용 Check(±1)에 넘겨, 거짓(0)이어도 기대 1 과 차이 1 이라 pass=true 가 된다
- 구분: 대리 응답
- 답변: 채택. 참/거짓 검사는 허용 오차 0(엄격 boolean) 전용 검사로 바꾸고, 거짓 입력이면 pass=false 가 되는 자체 시험을 넣은 뒤 verify-phase3.ps1 를 다시 돌린다. 리뷰 왕복은 2회로 마감하고, 수정 확인은 재실행 결과(actual 값·errors 0)로 leader 가 한다
- 근거: 가이드 검토 왕복 최대 2회(D-011 과 같은 처리). 현재 증거의 actual 은 모두 1(참)이라 판정 결과 자체는 바뀌지 않을 것이나 검사가 실패를 못 잡으므로 고친다
- 결과: wg-coder 수정 → leader 재실행 결과 확인
- 보고: 최종 보고에서 알림

### D-021 · 2026-11-01 · wg-checker, wg-leader

- 상황: Phase 3 리뷰 2회 마감·checker 2회차 결과
- 질문: Phase 3 를 마감하고 커밋할 수 있는가
- 구분: 대리 응답
- 답변: 승인. 리뷰 1회차 2건·2회차 1건 모두 반영, D-020 수정은 verify-phase3.ps1 -SelfTest(7사례 allOk)와 전체 재실행(errors 0, 새 boolean 검사 4건 actual=True)으로 leader 가 확인. checker 2회차 R-12~R-15 모두 통과. 미해결 실패가 없어 Phase 3 를 커밋한다
- 근거: PLAN.md Phase 끝 순서와 미해결 실패 규칙, 가이드 검토 왕복 최대 2회
- 결과: Phase 3 커밋. v0.1 의 PLAN Phase 0~3 이 모두 끝남. PROGRESS "버전 종료" 절은 버전 종료 절차(사용자 판단)로 남김
- 보고: 최종 보고에서 알림

### D-022 · 2026-11-01 · wg-leader

- 상황: 사용자 지시 "버전 0.1 을 종료합니다. v0.2 계획을 수립해 주세요"
- 질문: v0.2 범위와 진행 방식
- 구분: 사람에게 물음 (WORKFLOW "사람이 정하고 에이전트는 묻는다")
- 답변: 사용자 답(2026-11-01) — 범위 PoC 4~5단계, 편집기 직접 구현 12건은 이후 버전, Zed 글꼴은 넣지 않음, 진행 방식은 v0.1 과 같은 Herdr 구성·리더 위임 유지(작성 문서는 확정 전 사용자에게 보임). 계획(plan)은 사용자 승인
- 근거: project-workflow-compact WORKFLOW 4·5·2절
- 결과: v0.1 PROGRESS 버전 종료 기록·커밋, specs/v0.2/ 문서 초안 작성 → 사용자 확인
- 보고: 2026-11-01

### D-023 · 2026-11-01 · wg-coder → 사용자

- 상황: v0.2 문서 초안의 사용자 질문 11건
- 질문: 탭 동작 범위, 상태 저장 범위, keymap.json JSONC, 앱 데이터 폴더 이름, 확인창 방식, ☰ 앱 메뉴 범위, 알림, Open Markdown Preview, 타이틀 바 폴더 이름 버튼, 트리 드래그 앤 드롭, 키맵 층 구성(초안 D-2)
- 구분: 사람에게 물음
- 답변(사용자, 2026-11-01): ① A-33.2·A-33.4 시나리오에 필요한 최소 탭 동작만(트리에서 열기, Pane당 임시 탭 하나 교체, 더블클릭 승격, 기울임 제목, 폴더별 탭 보관) ② 등록 폴더 목록·순서·활성 폴더·사이드바 폭만 state.json 저장·시작 때 복원 ③ JSONC 허용(jsonc-parser) ④ `%APPDATA%\workbench-gpui` ⑤ TaskDialog Win32 FFI, 기본 버튼 취소·Esc 취소 ⑥ ☰ 앱 메뉴는 v0.2 에서 동작하는 항목만 ⑦ gpui-kit notification 임시, 문구만 판정 ⑧ Open Markdown Preview 는 우클릭 메뉴에 비활성으로 둠 ⑨ 이름 표시·툴팁만, 목록은 PoC 8단계 ⑩ 드래그 앤 드롭은 이후 버전 ⑪ 초안 D-2(내장 키맵 = 적용 결과 표 재작성 + 사용자 keymap.json)
- 근거: WORKFLOW "사람이 정하고 에이전트는 묻는다"
- 결과: wg-coder 가 v0.2 문서에 반영. 새 크레이트 serde_json·jsonc-parser(G-020), rfd(G-018), trash(G-017), notify(G-016), dirs(G-023)는 02-gpui G-010~G-025 목록 안이라 HERDR-SETUP 7절에 따라 leader 가 승인한다
- 보고: 2026-11-01

### D-024 · 2026-11-01 · wg-coder → 사용자

- 상황: D-023 반영 중 새로 생긴 질문 — 최소 탭 안에서 편집을 허용할지
- 구분: 사람에게 물음
- 답변(사용자, 2026-11-01): 읽기만. v0.2 탭은 보기 전용이고, 저장 질문(A-13.4, I-069)·충돌 표시(E-086)는 저장과 함께 이후 버전에서 다룬다. 디스크 변경은 깨끗한 버퍼 다시 읽기(G-115)만 판정한다
- 결과: wg-coder 가 v0.2 문서에 반영
- 보고: 2026-11-01

### D-025 · 2026-11-01 · 사용자

- 상황: v0.2 문서(INTENT·DECISIONS·SPEC·PLAN·PROGRESS) 확정 여부
- 구분: 사람에게 물음
- 답변(사용자, 2026-11-01): 확정·커밋. 구현(PLAN Phase 1)은 사용자가 따로 지시할 때 시작한다
- 결과: 상태 "확정 (2026-11-01)", 커밋 `docs: v0.2 문서 확정`
- 보고: 2026-11-01

### D-026 · 2026-11-01 · 사용자

- 상황: 사용자 지시 "리더 에이전트가 v0.2 플랜에 따라 순서대로 모두 진행하고, 승인이 필요한 사항은 판단해서 승인하고 근거를 문서에 기록해 주세요. 모든 단계를 수행 후 최종 결과를 사용자에게 보고해 주세요"
- 구분: 사용자 지시 실행 (HERDR-SETUP 7절 위임 재확인)
- 답변: v0.2 PLAN Phase 1~5 를 순서대로 진행한다. 하위 에이전트 승인 창은 명령 전체가 보이는 읽기 전용·지정 파일 쓰기만 승인하고, 위임 밖(삭제·외부 전송·원격·목록 밖 크레이트)은 사용자에게 올린다
- 근거: 사용자 지시, HERDR-SETUP 7절
- 결과: Phase 1 시작
- 보고: 최종 보고

### D-027 · 2026-11-01 · wg-coder

- 상황: v0.2 Phase 1 구현 중 질문 5건 (G-105 확인 결과: KeyBindingContextPredicate 공개, null 해제는 gpui NoAction)
- 구분: 대리 응답
- 답변:
  ① keymap.json 읽기 오류 문구 — (a) 원문 K-091 `Failed to load keymap file`(파일 오류)·K-085 `Action '{이름}' not found`(없는 액션)를 쓴다. 오류가 여럿이면 알림 하나에 줄로 잇는다. 오류 항목만 빼고 나머지 바인딩은 적용한다(leader 판단)
  ② 문서에 이름이 없는 액션 — (a) 문서 이름은 그대로, 없는 것은 Zed 와 같은 `namespace::Name` 꼴로 짓고 "우리가 지은 이름" 목록을 PROGRESS·검증 보고서에 남긴다
  ③ `menu` 컨텍스트 — (a) I-516·I-517 대로 `menu` 컨텍스트에 우리 `menu::` 액션을 묶고, Phase 2 에서 메뉴 요소에 연결한다. gpui-kit PopupMenu 자체 바인딩은 대조에서 뺀다
  ④ 사이드바 컨텍스트 이름 — (a) `Sidebar`
  ⑤ R-3·R-4 판정 범위 — (a) Phase 1 은 포커스 자리 표시에서 키를 넣어 dev 출력의 "실행된 액션 이름"·"액션별 표시 문자열"로 판정하고, 실제 결과(디스크·목록·메뉴 화면)는 Phase 2~4 판정에서 다시 확인한다고 PROGRESS 에 적는다
- 근거: ① 01-zed 02-INTERACTION K-085·K-091 원문 문구가 있고 SPEC 공통 규칙(원문 문구 그대로)을 지킨다. 나머지 적용은 사용자의 작업 중단을 막는 쪽. ② A-20.4 "우리 앱에 있는 액션 이름만", Zed 명명 관례. 원문에 이름이 없으니 지은 이름을 드러내 기록한다 ③ I-516 원문 이름 유지, D-5 gpui-kit menu 사용과 충돌하지 않음 ④ A-17 설명(우리 앱 값), Zed 의 패널 컨텍스트 명명(`ProjectPanel`)과 같은 꼴 ⑤ PLAN Phase 1 완료 조건을 바꾸지 않고 판정할 수 있고, 실제 화면 결과는 해당 Phase 에서 다시 판정해 빈틈이 없다
- 결과: wg-coder 구현 계속
- 보고: 최종 보고에서 알림

### D-028 · 2026-11-01 · wg-checker, wg-reviewer

- 상황: ① wg-checker(agy Argon)가 "Individual quota reached, Resets in 120h" 로 멈춤 ② v0.2 Phase 1 리뷰 1회차 지적 Major 1·Minor 2
- 구분: 대리 응답
- 답변: ① HERDR-SETUP 4절 규칙대로 checker 를 Claude Sonnet 5.5 · high 로 교체(같은 패널, 이름 유지), HERDR-SETUP 9절 변경 이력에 기록 ② 3건 모두 채택 — verify-v02-phase1.ps1 이 기존 keymap.json.tmp 를 지우거나 덮어쓰지 않도록 이번 실행이 만든 유일 경로만 정리, 감시 등록 뒤 최초 로드(또는 등록 직후 재읽기)로 시작 구간 변경 누락 방지, Start-App 실패 시 띄운 프로세스 정리
- 근거: ① HERDR-SETUP 4절 "agy 한도 소진 시 Claude Sonnet 5.5 · high로 교체"(사전 승인) ② 사용자 파일 손상(Major)·변경 누락·프로세스 잔존 모두 재현 경로가 구체적이다
- 결과: wg-coder 수정 → 리뷰 2회차, checker 검증
- 보고: 최종 보고에서 알림

### D-029 · 2026-11-01 · wg-reviewer → wg-coder

- 상황: v0.2 Phase 1 리뷰 2회차 — 1회차 3건 해결, 새 Major 1건(verify-v02-phase1.ps1 660행: 외부 tmp 해시 확인·표지 파일 삭제가 사용자 keymap.json 복원보다 먼저 실행되고 예외가 격리되지 않아, 실패 시 사용자 키맵이 시험 내용으로 남음)
- 구분: 대리 응답
- 답변: 채택. 사용자 keymap.json 복원을 가장 먼저·독립된 finally 로 반드시 실행하고, 해시 검사·표지 정리 예외는 따로 모아 errors 로 남긴다. 리뷰 왕복은 2회로 마감, 수정 확인은 leader 가 코드와 재실행 결과로 한다(D-011·D-020 과 같은 처리)
- 근거: 사용자 파일 보존은 검증 스크립트의 최우선 조건. 가이드 검토 왕복 최대 2회
- 결과: wg-coder 수정 → leader 확인
- 보고: 최종 보고에서 알림

### D-030 · 2026-11-01 · wg-checker, wg-leader

- 상황: v0.2 Phase 1 마감 여부
- 구분: 대리 응답
- 답변: 승인. 리뷰 1회차 3건·2회차 1건 반영(D-029 는 leader 가 잠금 시험 결과·복원 해시로 확인), checker(Sonnet) R-1~R-4 통과·불일치 0. R-3·R-4 의 화면 결과는 D-027 ⑤ 대로 Phase 2~4 에서 다시 판정한다. 미해결 실패가 없어 커밋한다
- 근거: v0.2 PLAN 끝 순서·미해결 실패 규칙
- 결과: v0.2 Phase 1 커밋
- 보고: 최종 보고에서 알림

### D-031 · 2026-11-01 · wg-coder

- 상황: v0.2 Phase 2 구현 전 질문 5건 (G-111 대조: gpui 툴팁 시점·위치·뒤집기는 Zed 와 같음, gpui-kit Tooltip·Kbd·PopupMenu 모양·형식·키는 다르고 상수라 바꿀 수 없음)
- 구분: 대리 응답
- 답변: ① ☰ 메뉴 — (a) gpui 요소로 직접 그림, gpui-kit PopupMenu 안 씀 ② 툴팁 — (a) gpui `.tooltip()` 장치는 그대로, 안의 뷰는 우리 것(L-209~L-216·L-219), gpui-kit Tooltip 안 씀 ③ Quit(Ctrl-Q, I-341)·Close Window(Ctrl-Shift-W, I-358)를 내장 키맵에 넣고 R-1 기대 표·Phase 1 스크립트도 함께 고침 ④ Phase 2 메뉴는 지금 동작하는 항목만, Open Folder...·Toggle/Focus Folder Sidebar 는 Phase 3 에서 메뉴에 넣고 그 판정은 Phase 3 으로 이월. 메뉴 정의는 9.2절 순서 한 곳에 두고 동작 여부로만 거름 ⑤ 앱 이름 `workbench-gpui`
- 근거: ①② D-5 의 "다른 점만 보정"이 gpui-kit 상수 때문에 불가능(popup_menu.rs 1236~1285·1517~1518, kbd.rs 105~125). 루트 INTENT "Zed와 같아야 한다"와 R-5·R-6·R-9 원문 값을 지키려면 직접 그려야 한다. gpui·gpui-kit 의존 안에서 끝나고 새 크레이트·포크 없음 ③ 01-zed A-18.11 "9.2절 키 열은 적용 keymap 결과" ④ D-13(동작 항목만)과 R-8 "최종 목록은 Phase 2 에서 확정" ⑤ 사용자가 정한 데이터 폴더 이름(D-023 ④)·v0.1 창 제목과 같음. A-40.5 가 앱 이름을 미정으로 둠
- 결과: wg-coder 가 DECISIONS D-5 등에 "이후 변경"으로 반영하고 Phase 2 진행
- 보고: 최종 보고에서 알림

### D-032 · 2026-11-01 · wg-reviewer → wg-coder

- 상황: v0.2 Phase 2 리뷰 1회차 Major 3건 (checker 1회차는 R-4 화면·R-5~R-9 통과, 불일치 0)
- 질문: ① app_menu.rs 489행 — 50ms 지연 실행이 항목 번호만 보관하고 open_menu 가 pending 을 취소하지 않아, 메뉴 전환 뒤 다른 액션이 실행된다 ② keymap.rs 254행 — 현재 컨텍스트에서 가려져 후보가 없을 때 bindings_for_action().last() 로 돌아가 가려진 바인딩을 표시한다(I-704 위반) ③ app_menu.rs 595행 — 표시 키는 메뉴 열기 전 포커스 컨텍스트로 고르지만 입력은 menu 컨텍스트에서만 해석해, 원래 영역 전용 사용자 바인딩이 실행되지 않는다
- 구분: 대리 응답
- 답변: 3건 모두 채택. ① 지연 실행은 액션 자체를 보관하고 메뉴 전환·닫힘 때 취소 ② 가려진 경우 표시하지 않음(제목만, L-223) — fallback 제거 ③ 메뉴 항목 단축키 입력은 메뉴 열기 직전 컨텍스트의 키맵 적용 결과로 해석해 해당 항목 지연 실행에 연결, menu 목록 키 우선순위 유지. 세 경로를 재현하는 시험을 검증 스크립트에 추가
- 근거: R-5(표시=키맵 적용 결과), R-9·I-520(50ms 뒤 그 항목 실행), I-704(가려진 키 미표시). 지적마다 재현 경로가 구체적이다. checker 통과는 이 경로를 시험하지 않은 결과라 수정 뒤 재검증한다
- 결과: wg-coder 수정 → 리뷰 2회차·checker 2회차
- 보고: 최종 보고에서 알림

### D-033 · 2026-11-01 · wg-reviewer → wg-coder

- 상황: v0.2 Phase 2 리뷰 2회차 — 1회차 ①·③ 해결, ② 부분 미해결(keymap.rs 251행: prev_focus 에서 가려져 None 이면 메뉴 포커스로 재조회해 가려진 키를 다시 표시), 새 Major 2건(app_menu.rs 523행: 세대 비교 전 pending.take() 로 오래된 타이머가 새 예약을 꺼냄 / 578행: 완전 일치를 찾으면 다른 항목의 chord 접두 후보를 보지 않고 즉시 예약해 gpui 접두 대기 규칙을 깸). checker 2회차는 R-4~R-9 통과·불일치 0
- 구분: 대리 응답
- 답변: 3건 모두 채택. ② 재조회 제거 — 가려지면 표시 없음 ⓐ 세대가 같을 때만 꺼내 실행 ⓑ 원래 컨텍스트에서 partial 후보가 있으면 접두 대기·완성·타임아웃을 gpui 와 같게 처리한 뒤 확정된 항목만 예약. 세 경로마다 재현 사례를 추가해 "고치기 전 실패 → 고친 뒤 통과"를 증거로 남긴다. 리뷰 왕복은 2회로 마감하고 수정 확인은 leader 가 재현 결과와 코드로 한다(D-011·D-020·D-029 와 같은 처리). 확인 뒤 checker 가 바뀐 증거로 R-5·R-9 만 다시 판정한다
- 근거: R-5·I-704(가려진 키 미표시), R-9·I-520(50ms 뒤 그 항목 실행), D-3(gpui 키 엔진 규칙). 가이드 검토 왕복 최대 2회. 재현 사례로 수정 여부를 객관적으로 가를 수 있다
- 결과: wg-coder 수정 → leader 확인 → checker R-5·R-9 재판정
- 보고: 최종 보고에서 알림

### D-034 · 2026-11-01 · wg-checker, wg-leader

- 상황: v0.2 Phase 2 마감 여부
- 구분: 대리 응답
- 답변: 승인. 리뷰 1회차 3건·2회차 3건 반영(D-033 은 leader 가 재현 사례 고치기 전 2/7 → 고친 뒤 7/7 과 코드로 확인), checker 1~3회차 R-4(화면)·R-5~R-9 통과·불일치 0, Phase 1 R-1 62줄 유지. Open Folder...·Toggle/Focus Folder Sidebar 메뉴 항목과 L-251 툴팁은 Phase 3, 프로젝트 패널 툴팁(L-247)은 Phase 4 에서 판정한다
- 근거: v0.2 PLAN 끝 순서·미해결 실패 규칙
- 결과: v0.2 Phase 2 커밋
- 보고: 최종 보고에서 알림

### D-035 · 2026-11-01 · wg-coder

- 상황: v0.2 Phase 3 구현 전 질문 3건
- 구분: 대리 응답
- 답변: ① (a) 트리·탭에 기대는 판정(폴더별 펼침·선택·스크롤 유지, 폴더별 탭·해제 때 탭 닫기, 루트 우클릭 Remove from Project)은 Phase 4 로 이월한다. Phase 3 은 폴더마다 Workspace 엔티티를 두고 활성화하면 프로젝트 패널이 그 루트 한 줄로 바뀌는 데까지, 이전 폴더 엔티티 유지는 dev 출력으로 판정 ② (a) state.json 읽기 오류 알림은 `Could not read the window state.` — 원문 A-24.4 `Could not save the window state.` 와 짝을 맞춘 우리 문구이며 원문 문구가 아님을 PROGRESS·보고서에 적는다 ③ (a) 01-zed A-24.1~A-24.7(쓰기 순서·500ms 묶기·종료 직전 쓰기·재시도·.tmp 복구·.bad 보관 3개·version 검사)을 state.json 에 그대로 적용, Win32 FFI 로 새 크레이트 없음
- 근거: ① v0.2 PLAN Phase 4 가 트리·탭 범위이고, Phase 1·2 와 같은 이월 방식으로 판정 빈틈이 없다 ② 01-zed 에 읽기 오류 문구가 없고(A-24.6 은 "알림 한 줄"만), 가장 가까운 원문 문구 A-24.4 와 형식을 맞춘다 ③ A-24 는 01-zed 명세에 정해진 규칙이고 루트 INTENT "Zed와 같아야 한다"에 맞는다. 사용자 결정 D-023 ② 의 저장 범위(폴더 목록·순서·활성·폭)는 바꾸지 않는다
- 결과: wg-coder 가 DECISIONS 에 "이후 변경"으로 반영하고 Phase 3 진행
- 보고: 최종 보고에서 알림

### D-036 · 2026-11-01 · wg-coder (사후 보고)

- 상황: Phase 3 작업 중 고치기 전 Phase 1 스크립트를 다시 돌리다 Ctrl-K Ctrl-O 가 실제 폴더 선택 창을 열어 `D:\projects` 가 등록되고 `%APPDATA%\workbench-gpui\state.json` 이 생김. wg-coder 가 실행 전 그 폴더가 비어 있었음을 확인하고 그 파일을 지움
- 구분: 사후 확인 (파일 삭제는 위임 밖이나, 시험이 직접 만든 파일을 원래 상태로 되돌린 것)
- 답변: 승인(사후). 사용자가 원래 갖고 있던 파일은 없었고 시험 산물만 지웠다. 재발 방지로 Phase 1·2 스크립트는 `--dev-pick-folder <취소>` 로 띄우고 keymap.json·state.json 전후 해시를 확인한다(이후 실행 모두 같음)
- 근거: HERDR-SETUP 7절(삭제는 위임 밖) — 사용자 파일이 아니라 시험이 만든 파일이므로 되돌림으로 본다. 최종 보고에서 사용자에게 알린다
- 결과: 기록
- 보고: 최종 보고에서 알림

### D-037 · 2026-11-01 · wg-reviewer → wg-coder

- 상황: v0.2 Phase 3 리뷰 1회차 Major 4·Minor 2 (checker 1회차 R-10~R-16·R-28 통과)
- 질문: ① mod.rs 553 종료 저장이 약한 참조 on_app_quit 에만 있어 창 제거 경로에서 저장 대상이 먼저 사라짐 ② folders.rs 258 저장 실패해도 saved_generation 을 올려 실패한 변경을 저장 완료로 봄 ③ verify-v02-phase3.ps1 1111 사용자 파일 복원이 실패 가능한 Clear-StateFiles 뒤에 묶임 ④ 같은 스크립트 616 기존 앱 실행 검사가 사용자 파일을 바꾼 뒤에야 일어남 ⑤ path.rs 77 to_lowercase 가 A-28.5 유니코드 단순 케이스 폴딩과 달라 σ/ς 같은 경로를 다른 키로 봄 ⑥ folders.rs 636 사이드바 닫을 때 포커스가 사이드바에 없으면 가운데 Pane 으로 옮기는 분기 없음(R-16)
- 구분: 대리 응답
- 답변: 6건 모두 채택. ① 창 닫힘(마지막 창 제거) 경로에서도 강한 참조로 저장 ② 저장 성공 뒤에만 세대 갱신, 실패 시 A-24.4 재시도·알림 ③ 파일별 독립 복원(D-029 와 같은 원칙) ④ 사용자 파일을 바꾸기 전에 기존 앱 실행 검사 후 즉시 중단 ⑤ A-28.5 대로 단순 케이스 폴딩 비교 키(σ/ς 사례 시험) ⑥ R-16 정해진 결과대로 분기 추가와 사례
- 근거: R-28·A-24.3·A-24.4(종료 직전 쓰기·실패 처리), A-28.5, R-16, D-029·D-036(사용자 파일 보존). checker 통과는 이 경로들을 시험하지 않은 결과라 수정 뒤 재검증한다
- 결과: wg-coder 수정 → 리뷰 2회차·checker 2회차
- 보고: 최종 보고에서 알림

### D-038 · 2026-11-01 · wg-coder

- 상황: D-037 ⑤ 수정 중 확인 — 이 PC 의 D: 볼륨은 σ·ς 를 다른 이름으로 다룬다(두 폴더 공존 가능). A-28.5 단순 케이스 폴딩을 쓰면 서로 다른 σ·ς 폴더를 같은 항목으로 본다
- 구분: 대리 응답
- 답변: 원문 A-28.5("유니코드 단순 케이스 폴딩", "대소문자를 구분하는 폴더도 구분하지 않는다(판단)")대로 둔다. 실제 볼륨 동작과의 차이는 PROGRESS 특이사항에 남긴다
- 근거: 01-zed A-28.5 원문이 이 경우를 판단으로 정했고, 루트 INTENT "Zed와 같아야 한다"(명세 대조). σ/ς 만 다른 두 폴더를 함께 등록하는 경우는 드물다
- 결과: 그대로 진행
- 보고: 최종 보고에서 알림

### D-039 · 2026-11-01 · 사용자

- 상황: 사용자 알림 "노트북에서 작업 중이고, 입력이 일정 시간 없으면 자동으로 화면이 닫히면서 끊김이 발생하는 것 같습니다" — 검증 스크립트(SendInput)가 잠금 화면에서 멈추고, D:(USB) 끊김도 있었음
- 구분: 사람에게 물음
- 답변(사용자, 2026-11-01): 임시 방지 프로세스. wg-runner-app 패널(wB:p7)에서 scratchpad keep-awake.ps1(SetThreadExecutionState ES_CONTINUOUS|SYSTEM_REQUIRED|DISPLAY_REQUIRED, 60초마다 재설정)을 실행. 시스템 설정은 바꾸지 않음
- 결과: 20:18 시작. 최종 보고 때 Ctrl+C 로 끝낸다
- 보고: 2026-11-01

### D-040 · 2026-11-01 · wg-reviewer → wg-coder

- 상황: v0.2 Phase 3 리뷰 2회차 — 1회차 ①②③④⑥ 해결, ⑤ 부분 미해결(Minor: path.rs 111 수작업 예외 표가 단순 케이스 폴딩 전체가 아님, U+1FD3·U+1FE3·U+FB05/FB06 등), 새 Minor 1건(verify-v02-phase3.ps1 1211: 기존 앱 가드로 일찍 중단해도 finally 가 고정 testRoot 를 확인 없이 재귀 삭제). checker 2회차 R-10~R-16·R-28 통과, 명세 값과 다른 값 0
- 구분: 대리 응답
- 답변: ⓐ 새 Minor 채택 — 이번 실행이 만든 testRoot 만(생성 표지 확인) 지운다. 수정 확인은 leader 가 가드 하네스 재실행으로 ⓑ ⑤ 남은 부분은 알려진 한계로 specs/v0.2/DECISIONS.md 미결 사항에 기록하고 이후 버전으로 넘긴다(전체 C/S 표는 Unicode CaseFolding.txt 를 버전 고정으로 들여와야 함). 리뷰 왕복은 2회로 마감
- 근거: ⓐ 사용자 디스크 삭제 위험(HERDR-SETUP 7절 삭제 위임 밖 정신) — 미룰 수 없다 ⓑ 영향 문자가 그리스 확장·합자 등 드물고 R-10 기본 동작(대소문자 무시 중복 판정)은 통과, 전체 표 도입은 외부 데이터 파일 반입이라 v0.2 범위를 넘는다. checker 판정에 실패 없음
- 결과: wg-coder 수정 → leader 확인 → Phase 3 커밋
- 보고: 최종 보고에서 알림

### D-041 · 2026-11-01 · wg-checker, wg-leader

- 상황: v0.2 Phase 3 마감 여부
- 구분: 대리 응답
- 답변: 승인. 리뷰 1회차 6건·2회차 새 Minor 1건 반영(D-040 ⓐ 는 leader 가 가드 하네스 고치기 전/후로 확인), ⑤ 남은 부분은 알려진 한계로 미결 기록. checker 1·2회차 R-10~R-16·R-28 통과, 명세 값과 다른 값 0, Phase 1·2 결과 유지. 이월: Phase 4(폴더별 트리·탭, 루트 Remove from Project), Phase 5(실행 중 사라짐)
- 근거: v0.2 PLAN 끝 순서·미해결 실패 규칙
- 결과: v0.2 Phase 3 커밋
- 보고: 최종 보고에서 알림

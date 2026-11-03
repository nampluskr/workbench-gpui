# HERDR-DECISIONS — workbench-gpui v0.3 대리 응답 기록

- `lead`가 하위 에이전트의 결정 요청에 대리 응답한 것과, 구성 변경(대체 모델 전환 등)을 기록한다.
- 위임 범위는 `specs/v0.3/HERDR-SETUP.md` 6.5를 따른다. 위임 밖 항목은 사용자에게 올리고, 그 결과도 여기에 남긴다.
- 지난 버전 기록은 `docs/HERDR-DECISIONS.md`(v0.1·v0.2, D-001~)에 있다. 이 문서는 v0.3에서 새로 번호를 매긴다.
- 형식: 항목마다 `### H-n · 날짜 시각 · 요청 에이전트 → 대상` 절을 두고, 요청·판단·근거·결과를 적는다.

## 목록

| ID | 날짜 | 요청 | 내용 | 구분 |
| --- | --- | --- | --- | --- |
| H-1 | 2026-11-03 | lead | spec을 agy `--model gemini-3.8-flash-medium`으로 실행 | lead 판단(구성 세부) |
| H-2 | 2026-11-03 | 사용자 | spec(agy) 폴더 신뢰 확인 승인 | 사용자 지시("눌러줘") |
| H-3 | 2026-11-03 | lead·사용자 | reviewer는 옵션 없이 `codex`로 띄우고 세션 안 `/model`에서 GPT-6.1-Sol medium(세션 한정)을 고른다 | 사용자 선택 뒤 lead 판단 |
| H-4 | 2026-11-03 | 사용자 | 하위 에이전트의 승인·권한 요청은 lead가 판단해 승인한다 | 사용자 위임 |
| H-5 | 2026-11-03 | spec | agy 기본 모드의 명령별 승인 대응: `--mode auto` 재시작은 막혀 기본 모드로 다시 띄우고 F1을 다시 보냄 | lead 판단 |
| H-6 | 2026-11-03 | reviewer | P0-0b cargo build 네트워크 접근 승인 | lead 판단(H-4 위임) |
| H-7 | 2026-11-03 | reviewer | P0-0b cargo run 1회 기동 확인(창 생성 즉시 닫음) 승인 | lead 판단(H-4 위임) |
| H-8 | 2026-11-03 | reviewer | `verify/reviews/baseline-2026-11-03.md` 쓰기(샌드박스 밖 재시도) 승인 — reviewer 소유 경로 | lead 판단(H-4 위임) |
| H-9 | 2026-11-03 | reviewer | P0-0c 실행 래퍼 `verify/baseline/run-p0-0c.ps1` 실행 승인(앱 데이터 백업·해시 대조·복원 포함, d043-clip은 -Before 원본 없음으로 건너뜀) | lead 판단(H-4 위임) |
| H-10 | 2026-11-03 | reviewer | P0-0c 휴지통 판정용 D: 볼륨 정보·BitBucket 레지스트리 읽기(읽기 전용) 승인 | lead 판단(H-4 위임) |
| H-11 | 2026-11-03 | reviewer | P0-0c phase1 1회 재실행(기대표 r1-expected.tsv를 OutDir에 준비) 승인. 래퍼 밖이라 끝난 뒤 앱 데이터 해시 대조·복원을 지시 | lead 판단(H-4 위임) |
| H-12 | 2026-11-03 | reviewer | P0-0c 마무리 확인(앱 데이터 해시 대조, exe 불변, D: 볼륨·휴지통 설정 읽기 → `_backup/final.json`) 승인 | lead 판단(H-4 위임) |
| H-13 | 2026-11-03 | impl-ui | agy 폴더 신뢰 확인(`.worktrees\ui`, 이 저장소의 worktree) 승인 | lead 판단(H-4 위임) |
| H-14 | 2026-11-03 | impl-ui | P0-4 읽기 명령(git branch·rev-parse·파일 목록·줄 수) 1회 승인. 이후 P0-4의 읽기·빌드 명령은 같은 기준으로 승인 | lead 판단(H-4 위임) |
| H-15 | 2026-11-03 | reviewer | P0-6 측정 세션 스크립트 `tools/measure/p0-session.ps1`(Start: 앱 데이터 백업, target 아래 표지 붙은 시험 폴더, 앱 1회 실행 / Snapshot: 덤프·캡처 / Stop: 복원·해시 대조·표지 확인 후 시험 폴더 삭제) 실행 승인. 같은 스크립트의 Snapshot·Stop도 같은 기준으로 승인 | lead 판단(H-4 위임) |
| H-16 | 2026-11-03 | reviewer | P0-6에서 Codex 화면 도구의 workbench-gpui 앱 사용을 "Allow for this session"으로 승인(측정 대상 앱 한정, V3 카드 범위) | lead 판단(H-4 위임) |
| H-17 | 2026-11-03 | reviewer | P0-6 입력 스크립트 `tools/measure/p0-input.ps1`(측정 창이 맨 앞·최대화일 때만, 좌표가 측정 창 안일 때만 클릭·호버, 키는 Esc·F2·F10·Enter·Right·Down만) 승인. 이후 같은 스크립트·Snapshot·p0-show는 lead 감시 스크립트가 자동 승인 | lead 판단(H-4 위임) |
| H-18 | 2026-11-03 | 사용자 → reviewer | P0-6 중 전면에 뜬 "Open With"(OpenWith.exe) 대화상자를 닫으라는 사용자 지시. `p0-input.ps1 -Action DismissOpenWith`(전면 창 클래스·소유 프로세스가 OpenWith일 때만 Esc 1회) 승인 | 사용자 지시 |
| H-19 | 2026-11-03 | reviewer | P0-6 마무리: 측정 프로세스(session.json pid, 경로 확인)만 CloseMainWindow로 닫고 `p0-session.ps1 -Action Stop`(복원·해시 대조·표지 확인 후 시험 폴더 삭제) 승인 | lead 판단(H-4 위임) |

## 기록

### H-1 · 2026-11-03 · lead → spec
- 요청: HERDR-SETUP 3.5는 "세션 안에서 gemini-3.8-flash 선택"이지만 `agy models`의 ID에는 effort 접미사가 붙는다(low·medium·high).
- 판단: `herdr agent start spec --kind agy -- --model gemini-3.8-flash-medium`. 기본 effort로 시작한다(HERDR-SETUP 1.1).
- 결과: spec 실행. impl-ui도 같은 방식으로 `claude-sonnet-5-5-medium`을 쓸 예정이다. HERDR-SETUP 3.5 문구 고침은 F4 개정안에 넣는다.

### H-2 · 2026-11-03 · 사용자 → spec
- 요청: agy 시작 때 "Do you trust the contents of this project?"(`D:\projects\workbench-gpui`)
- 판단: 사용자 지시 "눌러줘"로 `herdr agent send-keys spec enter`(Yes).
- 결과: spec idle, F1 지시를 보냈다.

### H-3 · 2026-11-03 · lead·사용자 → reviewer
- 요청: `codex --model gpt-6.1-sol -c model_reasoning_effort=...`가 "Running without the shared background server: ... requires embedded mode" 경고를 냈다. 사용자는 1번(프로필)을 골랐으나 `--profile`도 같은 경고("--profile requires embedded mode")를 냈다.
- 판단: 덮어쓰기 옵션 없이 `codex`로 띄우고 `/model` → GPT-6.1-Sol → Medium → `s`(세션 한정). `~/.codex/config.toml` 기본값(gpt-6.1-terra high)은 바꾸지 않는다.
- 결과: 경고 없이 공유 서버로 실행, 상태줄 `GPT-6.1-Sol medium`. `~/.codex/reviewer.config.toml`(프로필 시도 때 만든 두 줄 파일)은 쓰지 않지만 지우지 않고 남겼다(삭제는 위임 밖). 시도 중 Git Bash가 `/model`을 경로로 바꿔 프롬프트 한 번이 들어갔다(파일 변경 없음, 응답만). 이후 `MSYS_NO_PATHCONV=1`과 `pane send-text`를 쓴다. HERDR-SETUP 3.5 고침은 F4 개정안에 넣는다.

### H-4 · 2026-11-03 · 사용자 → lead
- 요청: 사용자 말 "서브 에이젼트의 승인 요청은 리더가 판단해서 승인해 주세요"
- 판단: HERDR-SETUP 6.4 "승인과 권한 프롬프트는 사용자가 직접 처리한다"를 이 지시로 바꿔 운용한다. 6.5 위임 밖 항목(삭제, push·원격, Cargo 변경, 동작 변경 등)은 여전히 사용자에게 올린다.
- 결과: 이후 하위 에이전트의 승인 프롬프트는 lead가 `herdr agent read`로 내용을 보고 판단해 처리하고 여기에 남긴다. HERDR-SETUP 6.4 문구 고침은 F4 개정안에 넣는다.

### H-5 · 2026-11-03 · spec → lead
- 요청: spec이 `Test-Path spec`, `Get-ChildItem -Path "docs/refs/01-zed"` 같은 읽기 명령마다 승인을 물어 F1이 계속 멈췄다(사용자 알림).
- 판단: `Test-Path spec`은 승인(1회 실행), `Get-ChildItem`은 재시작하면서 취소됐다. 근본 대응으로 `--mode auto` 재시작을 시도했으나 lead 쪽 안전 분류기가 막았다(모든 명령 자동 승인 에이전트 생성). 기본 모드로 다시 띄우고, F1 프롬프트에 "파일은 내장 도구로, 셸 명령은 최소로"를 더해 다시 보냈다.
- 결과: spec working(새 대화). `--mode auto`/`accept-edits` 사용은 사용자 결정으로 남긴다(review-notes N-9).

### H-6 · 2026-11-03 · reviewer → lead
- 요청: P0-0b `cargo build`가 의존성 다운로드를 위한 네트워크 접근 승인을 요청했다.
- 판단: 승인(1회, `y`). `Cargo.lock`에 고정된 크레이트를 crates.io에서 받는 것이라 기준선 빌드에 필요하다. Cargo 파일은 바뀌지 않는다.
- 결과: reviewer working.

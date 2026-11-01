# v0.2 Phase 3 리뷰 1회차(D-037) 수정 증거

생성: 2026-11-01. 앞선 `phase3/` 증거(리뷰 대상)는 덮어쓰지 않았다.

## 폴더

| 폴더 | 무엇 | 결과 |
| --- | --- | --- |
| `before/` | 고치기 전 exe(리뷰 대상, stage 된 트리를 `git checkout-index` 로 꺼내 따로 빌드)에 새 재현 사례 `closesave, xclosesave, savefail, sigma, keys` | 판정 28, **실패 5**(①×2·②·⑤·⑥) |
| `after-targeted/` | 고친 exe 에 같은 사례 | 판정 28, 실패 0 |
| `after/` | 고친 exe 에 `tools/verify-v02-phase3.ps1` 전체(23사례) | 판정 122, 실패 0, 사용자 파일 복원 확인 |
| `guard-before/` | 고치기 전 검증 스크립트를 `tools/verify-v02-phase3-guard.ps1` 로 시험 | running·locked 둘 다 실패 |
| `guard-after/` | 고친 검증 스크립트를 같은 하네스로 시험 | 둘 다 통과 |

Phase 1·2 도 다시 돌렸다: `phase1/d037-rerun/` 실패 0, `phase2/d037-rerun/` 판정 137 실패 0, 단축키 대조 31줄 불일치 0.

## 지적별

| # | 지적 | 수정 | 재현 사례 | 고치기 전 | 고친 뒤 |
| --- | --- | --- | --- | --- | --- |
| ① | 창 제거 경로에서 종료 저장이 약한 참조에만 기대 마지막 변경을 잃음 | `flush_save`: Close Window(창 제거 전)·창 닫기 버튼(`on_window_should_close`)·Quit 에서 먼저 쓴다. App 수준 `on_app_quit` 이 Workbench 를 강하게 붙잡는다 | `closesave`(Move Down 직후 Ctrl-Shift-W), `xclosesave`(직후 창 닫기 버튼). 메뉴 키와 닫기를 SendInput 한 묶음으로 보내 500ms 묶어 쓰기 전에 닫는다(보내기 < 400ms 판정) | state.json 이 `alpha / beta` 그대로(변경 잃음), 저장 줄 없음 | `beta / alpha`, `state-flush via=close-window` / `via=window-close` |
| ② | 저장 실패에도 `saved_generation` 을 먼저 올려 종료 때 다시 쓰지 않음 | 쓰기 직전 세대를 잡아 두고 `state::save` 가 성공했을 때만 저장됨으로 둔다. 실패는 A-24.4(50ms×3 재시도·알림) 뒤 변경을 남긴다 | `savefail`: state.json 을 공유 삭제 없이 열어 두고 Move Down → `result=failed` + `Could not save the window state.` → 잠금을 풀고 Ctrl+Q | 종료 뒤 `alpha / beta`(다시 쓰지 않음) | `state-flush via=quit` → `beta / alpha` |
| ③ | 검증 스크립트 복원이 상태 파일 지우기 하나에 묶여, 실패하면 keymap.json 등 복원을 건너뜀 | 백업 파일마다 따로 복사해 되돌린 뒤, 시험이 만든 파일만 하나씩 지운다. 실패는 파일별로 errors 에 남긴다 | 하네스 `locked`: 시험용 keymap.json·state.json 을 만들고 state.json 을 공유 삭제 없이 연 채 `-Only empty` 실행 | keymap.json 이 없어진 채 끝남 | keymap.json 해시 그대로 |
| ④ | 기존 앱 실행 검사가 사용자 파일을 바꾼 뒤에야 됨 | 스크립트 맨 앞(백업·keymap 지우기·시험 폴더 만들기 전)에서 검사하고 즉시 멈춘다. Start-App 재검사는 둔다. Phase 1·2 스크립트에도 같은 앞 검사를 넣었다 | 하네스 `running`: `--dev-keymap` 앱을 띄워 둔 채 실행 | 실행 중 앱이 keymap 다시 읽기 1번(사용자 keymap 삭제를 봄) | "사용자 파일을 바꾸기 전에 중단", 다시 읽기 0, 파일 해시 그대로 |
| ⑤ | 비교 키가 `to_lowercase` 라 A-28.5 단순 케이스 폴딩과 다름 | `compare_key` 를 단순 케이스 폴딩(CaseFolding.txt C·S 중 소문자화와 다른 항목 표 + 그 밖은 한 글자 소문자화)으로 바꿨다. 같은 이름 표시(A-12.6)도 같은 키를 쓴다. 단위 시험 `a28_5_simple_case_folding` | `sigma`: σ 등록 뒤 ς 선택 | `added index=1`(2개) | `existing index=0`(1개) |
| ⑥ | 사이드바 닫을 때 사이드바에 포커스가 없으면 가운데 Pane 으로 옮기지 않음 | 닫기 경로에서 포커스가 사이드바에 없으면 가운데 Pane 으로 | `keys`: Ctrl+Shift+E(패널) → Ctrl+Alt+J | `focus=project_panel` | `focus=center` |

## 알려 둘 것

- **⑤ 의 전제:** 이 PC 의 D: 볼륨에서 σ·ς 는 다른 이름이다(둘 다 만들 수 있고, ς 경로는 σ 폴더로 풀리지 않는다. Σ 는 σ 로 풀린다). 그래서 리뷰의 "같은 폴더를 가리킨다"는 이 볼륨에서는 맞지 않는다. 수정은 A-28.5 원문("유니코드 단순 케이스 폴딩", "대소문자를 구분하는 NTFS 폴더는 구분하지 않는다(판단)")대로 했고, 그 결과 서로 다른 σ·ς 폴더는 같은 항목으로 본다. `sigma` 사례는 두 폴더를 모두 만든 뒤 판정한다.
- **① 첫 재현 시도:** 처음 만든 사례는 Move Down 과 닫기 사이가 500ms 를 넘어 묶어 쓰기가 먼저 저장했고, 고치기 전 exe 도 통과했다. 닫기를 묶어 쓰기 전에 보내도록 사례를 고친 뒤 고치기 전 실패·고친 뒤 통과를 확인했다.
- **빌드 환경:** 작업 폴더가 있는 D:(USB 드라이브)가 큰 빌드 중에 두 번 끊겼다(`STATUS_IN_PAGE_ERROR`, os error 1006 "볼륨이 바뀌었다"). 고치기 전 exe 는 C: 의 scratchpad 아래 대상 폴더로 빌드했다. 끊긴 동안의 편집은 다시 확인해 다시 넣었다.

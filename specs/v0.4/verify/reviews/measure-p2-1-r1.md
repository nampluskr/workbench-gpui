# P2-1-R1 확인 (좁은 V3) — 2026-11-04

- 대상: work/ui `e02a6f8`(worktree에서 `cargo build`, 공유 target). 빌드 직후 exe를 `%TEMP%\wbg-measure\e02a6f8\`로 복사하고 매니페스트를 병합한 사본만 썼다. SHA-256 `83D99057…FCB16`(병합 전 `A6CA907A…B0009`), 실행 전후 동일.
- 조건: 1920x1080 100%, 최대화(client 1920x1032), rem=16. 앱 데이터 복원 확인(`restored=true`, 실행 뒤 `%APPDATA%\workbench-gpui` 파일 없음).

## (1) 사이드바 폭 (`--dev-layout`, 앱 1회)

| 상태 | `sidebar` 박스 | `sidebar-footer` | `dock` x | `body` w | 비고 |
|---|---|---|---:|---:|---|
| S1 빈 화면 최대화 | 0,0 **300**x1032 | 299x30 | 300 | 1620 | P2-E(df280c5)는 375 |
| S2 폴더 등록 뒤 | 0,0 **300**x1032 | 299x30 | 300 | 1620 | P2-E는 375 |

기대 300 → **PASS**(0 차이). 푸터 높이 30도 유지.

## (2) `verify-v02-phase3` 1회 (`-OutDir specs\v0.4\verify\baseline\p2-1-r1\verify-v02-phase3`, 사본 `-Exe`)

- exit 0, **122 통과 / 0 실패**, user files restored=True. (R-1·Phase 1·Phase 2 모두 120/2)
- R-28 두 건:

| 사례 | 항목 | 기대 | 실제 | 판정 | 이전(R-1 / P2-E) |
|---|---|---:|---:|---|---|
| state | 시작 폭 | 300 | **300** | 통과 | 기대 300, 실제 375 / 375 |
| state-restart | 폭 복원 | 419 | **419** | 통과 | 기대 494, 실제 617 / 617 |

- 복원 폭의 기대값이 494에서 419로 바뀐 것은 스크립트가 "시작 폭 + 끌어 늘린 만큼"으로 계산하기 때문이다. 시작 폭이 375에서 300으로 줄어 494(=375+119)가 419(=300+119)가 됐다. 저장된 값(`state.json sidebar.width`)과 복원된 값이 같다(A-22 검사 419/419 통과).
- 증거: `specs/v0.4/verify/baseline/p2-1-r1/verify-v02-phase3/`, `p2-1-r1-measure/`(S1·S2 덤프).

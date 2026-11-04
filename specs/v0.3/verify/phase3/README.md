# P3-E — Phase 3 끝 R-12 재실행 (2026-11-04, measure, V3)

- 대상: master `69a50ce`(P3-1~P3-4 병합 뒤), 디버그 빌드 + `tools/apply-manifest.ps1`, 빌드 경고 없음. `cargo clean` 안 함. 사용자 부재(H-26).
- exe SHA-256: `9D2559CDFFCC82A9BD51433870FA1577409A022AA88253ADD48F57B040A08B44` (R-12 전체·V3 세션 동안 동일, `_backup/after.json`·`_backup-rerun/after.json`·세션 `exeUnchanged=true`).
- 실행기: `run-phase3.ps1`(= phase2 것 복사, 출력 `phase3/`, d043-clip 제외, phase4 계열은 직전 `clear-clipboard.ps1`로 `Clipboard.Clear()` 후 형식 0 확인 — H-28; 3개 모두 0). 앱 데이터 백업·복원 restored=true(양쪽).
- **1차 실행에서 5개 스크립트가 환경 간섭으로 실패 → 4개 스크립트 1회 재실행** (Phase 2 때와 같은 처리). 1차 결과는 `_first-run/`에 그대로 보존(`run.log`·`run-index.json` 포함).
  - 1차 실패 증상은 전부 창/입력 환경: "캡처 중 창 상태가 바뀌었다"(창 위치가 x 1713→2091 로 이동), "대상 창이 전면이 아니다/아래 창이 대상 창이 아니다. 입력을 보내지 않고 중단", 그 결과 툴팁이 안 뜸·키 입력 누락(phase1 ctrl-n·broken 캡처, phase2 툴팁/메뉴/reload/pending/shadow 13건, phase4 menukeys 2건, d043 crossmove ctrl-v 1건). 기능 단언이 어긋난 것이 아니라 스크립트가 입력을 보내지 못해 생긴 실패다.
  - 재실행(`run-phase3-rerun.ps1`, 색인 `run-index-rerun.json`, 로그 `run-rerun.log`): phase1·phase2·phase4·phase4-d043 모두 exit 0, 실패 0. 같은 exe(해시 동일).
  - phase3·phase4-d044·phase5·phase5-d046·phase5-d047 은 1차 결과를 그대로 썼다(phase3 는 exit 1 이 기준선과 같은 2건).

## 기준선 대조 (`comparison.json`, `compare-baseline.ps1` = phase2 것에서 폴더만 phase3 로, 최종 결과 기준)

| 스크립트 (`verify-v02-`) | exit | 기준선 통과/실패 | 이번 통과/실패 | 항목 대조 |
| --- | ---: | --- | --- | --- |
| phase1 | 0 (재실행) | 9사례, failures 0 | 9사례, failures 0 | 사례 이름·R-1 바인딩표 동일 |
| phase2 | 0 (재실행) | 137 / 0 | 137 / 0 | 차이 0 |
| phase3 | 1 | 120(122중) / 2 | 120 / 2 | 실패 2개 그대로(R-28 시작 폭 기대 300, 저장 폭 복원). Q-15 기준선과 같음 |
| phase4 | 0 (재실행) | 208 / 0 | 208 / 0 | 차이 0 |
| phase4-d043 | 0 (재실행) | 13 / 0 | 13 / 0 | 차이 0 |
| phase4-d043-clip | SKIP | SKIP | SKIP | 기준선과 같은 사유(제외) |
| phase4-d044 | 0 | 6 / 0 | 6 / 0 | 차이 0 |
| phase5 | 0 | 62 / 0 | 62 / 0 | 차이 0 |
| phase5-d046 | 0 | 23 / 0 | 23 / 0 | 차이 0 |
| phase5-d047 | 0 | 16 / 0 | 16 / 0 | 차이 0 |

- 실행된 9개에서 `ok` 뒤바뀜 0. 합계 체크 중 실패는 phase3 의 2건뿐이며 기준선과 같다.
- `itemDiffs` 에 남은 phase3·phase5 각 1쌍은 항목 이름에 실행 GUID 경로·이벤트 수(1818→1831)가 들어 있어 키가 어긋난 것이며 양쪽 ok=True(실질 차이 아님, phase1·phase2 때와 같은 패턴). phase1 은 `checks` 배열이 없는 스크립트라 `itemDiffs` 비교 대상이 아니다(비교 스크립트가 출력한 null 오류 1줄은 이 때문).
- `failedInBoth` 의 `phase1Got` 라벨은 이어받은 이름이며 값은 이번 결과다.

## V3 (`../reviews/measure-phase3.md`)

S1(폴더 없음 안내 화면)·S5(앱 메뉴)·S6(컨텍스트 메뉴)·'경로 없음' 안내 화면 재측정. 세션 산출물 `v3-session/`(S1~S7), `missing-after/`; 스크립트 `v3-session.ps1`·`missing-session.ps1`·`png-diff.ps1`·`box-diff.ps1`; 결과 `box-diff.txt`·`png-region-diff.txt`.

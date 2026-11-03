# P2-E — Phase 2 끝 R-12 재실행 (2026-11-04, measure, V3)

- 대상: master `0f814a7`(P2-1·P2-2·P2-3 병합 뒤), 디버그 빌드 + `tools/apply-manifest.ps1`. 빌드 경고 없음. 사용자 부재(H-26).
- exe SHA-256: R-12 전체와 V3 세션 `7E22E72F…A6038`(실행 전후 동일, `_backup/after.json`·`_backup-rerun/after.json`). V3 뒤 '변경 전' 비교용으로 `3b26320`을 같은 `target`에 빌드하느라 master 를 `cargo clean -p`로 다시 빌드해 지금 `target\debug`의 exe 는 `A318FA42…E271F`다(같은 소스, 해시만 다름. 마지막 '경로 없음' 대조 세션은 이 빌드로 돌렸다).
- 실행기: `run-phase2.ps1`(= `phase1/run-phase1.ps1` 복사, 출력 `phase2/`, d043-clip 제외, phase4 계열은 직전 `clear-clipboard.ps1`로 `Clipboard.Clear()` 후 형식 0 확인, 아니면 SKIP — H-28). 순서·exit: `run-index.json`, 로그 `run.log`.
- **실수와 재실행 1회**: 첫 실행에서 내 실행기의 클립보드 도우미 경로가 깨져(sed 이스케이프) phase4·d043·d044 가 스크립트를 돌리지도 않고 SKIP 처리됐다(`run.log`에 오류 문구가 남아 있음). 경로를 고친 `run-phase2-rerun.ps1`(백업 `_backup-rerun/`, 색인 `run-index-rerun.json`, 로그 `run-rerun.log`)로 그 3개만 1회 다시 돌렸다. 클립보드 형식 수 3개 모두 0, 3개 모두 exit 0. `run-phase2.ps1`에도 같은 경로 수정을 반영했다. 앱 데이터 백업·복원 restored=true(양쪽), 실행 전후 앱 프로세스 없음.

## 기준선 대조 (`comparison.json`, `compare-baseline.ps1` = phase1 것에서 폴더만 phase2 로)

| 스크립트 (`verify-v02-`) | exit | 기준선 통과/실패 | 이번 통과/실패 | 항목 대조 |
| --- | ---: | --- | --- | --- |
| phase1 | 0 | 9사례, failures 0 | 9사례, failures 0 | 사례 이름·R-1 바인딩표 동일 |
| phase2 | 0 | 137 / 0 | 137 / 0 | 차이 0 |
| phase3 | 1 | 120(122중) / 2 | 120 / 2 | 실패 2개 그대로(R-28 시작 폭 기대 300·실제 375, 저장 폭 복원 기대 494·실제 617). Q-15 기준선과 같음 |
| phase4 | 0 | 208 / 0 | 208 / 0 | 차이 0 |
| phase4-d043 | 0 | 13 / 0 | 13 / 0 | 차이 0 |
| phase4-d043-clip | SKIP | SKIP | SKIP | 기준선과 같은 사유(제외) |
| phase4-d044 | 0 | 6 / 0 | 6 / 0 | 차이 0 |
| phase5 | 0 | 62 / 0 | 62 / 0 | 차이 0 |
| phase5-d046 | 0 | 23 / 0 | 23 / 0 | 차이 0 |
| phase5-d047 | 0 | 16 / 0 | 16 / 0 | 차이 0 |

- 실행된 9개에서 `ok` 뒤바뀜 0. 합계 체크 중 실패 2(위 phase3, 기준선과 동일), 그 외 전부 통과.
- `comparison.json`의 `itemDiffs`에 남은 phase3·phase5 각 1쌍은 항목 이름에 실행 GUID 경로·이벤트 수(1818→1825)가 들어 있어 키가 어긋난 것이며 양쪽 모두 ok=True(실질 차이 아님, phase1 때와 같은 패턴).
- `failedInBoth` 필드의 `phase1Got` 이름은 phase1 비교 스크립트에서 이어진 라벨이다(값은 이번 phase2 결과).

## V3 (`../reviews/measure-phase2.md`)

P0-6 S1~S7 재측정 결과와 증거는 그 파일. 세션 산출물은 `v3-session/`(S1~S7·C0~C2 PNG·JSON·덤프), 변경 전 대조는 `missing-before/`·`missing-after/`. 스크립트: `v3-session.ps1`, `missing-session.ps1`, `png-diff.ps1`, 영역 결과 `png-region-diff.txt`.

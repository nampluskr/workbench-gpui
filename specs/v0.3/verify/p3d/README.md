# P3-D — 데이터 손실 방지(복사·이동·붙여넣기·Duplicate) 뒤 R-12 재실행 (2026-11-04, measure, V3 없음)

- 대상: master `5298a75`(P3-D1·P3-D2·P3-D1-R1 병합 뒤), 디버그 빌드 `CARGO_TARGET_DIR=D:\projects\workbench-gpui\target` + `tools/apply-manifest.ps1`, 빌드 에러 없음. `cargo clean`·src 수정·커밋 안 함.
- exe SHA-256: `1B85FC18A8BCA1D11E06D2F73B1549E568C9423B1CA864C2DDA53D77409C8E81` (실행 전후 동일, `_backup/after.json`). 앱 데이터 백업·복원 restored=true.
- 실행기: `run-p3d.ps1`(= phase3 `run-phase3.ps1`에서 출력 폴더만 p3d 로). d043-clip 제외, phase4 계열 3개는 직전 `clear-clipboard.ps1`로 `Clipboard.Clear()` 후 형식 0 확인(H-28): phase4·d043·d044 모두 0.
- **환경 간섭 실패 없음 → 재실행 0회.** 1차 결과가 최종이다. phase3 만 exit 1(기준선·Phase 3 과 같은 2건).

## 기준선·Phase 3 대조 (`comparison.json` = 기준선, `comparison-vs-phase3.json` = Phase 3)

| 스크립트 (`verify-v02-`) | exit | 기준선 / Phase 3 통과·실패 | 이번 통과·실패 | 항목 대조 |
| --- | ---: | --- | --- | --- |
| phase1 | 0 | 9사례, failures 0 | 9사례, failures 0 | 사례 이름·R-1 바인딩표 동일 |
| phase2 | 0 | 137 / 0 | 137 / 0 | 차이 0 |
| phase3 | 1 | 120(122중) / 2 | 120 / 2 | 실패 2개 그대로(R-28 시작 폭 300, 저장 폭 복원, Q-15) |
| phase4 | 0 | 208 / 0 | 208 / 0 | 차이 0 |
| phase4-d043 | 0 | 13 / 0 | 13 / 0 | 차이 0 |
| phase4-d043-clip | SKIP | SKIP | SKIP | 기준선과 같은 사유(제외) |
| phase4-d044 | 0 | 6 / 0 | 6 / 0 | 차이 0 |
| phase5 | 0 | 62 / 0 | 62 / 0 | 차이 0 |
| phase5-d046 | 0 | 23 / 0 | 23 / 0 | 차이 0 |
| phase5-d047 | 0 | 16 / 0 | 16 / 0 | 차이 0 |

## Phase 3 결과와 달라진 항목

`ok` 뒤바뀜 0, 항목 수 변화 0, 새 실패 0. 달라 보이는 것은 `itemDiffs` 4행(2쌍)뿐이며 모두 항목 이름에 실행마다 바뀌는 값이 들어 있어 키가 어긋난 것이다(양쪽 ok=True).

| 스크립트·항목 | 달라진 점 | 복사·이동·붙여넣기·Duplicate 관련 | 비고 |
| --- | --- | --- | --- |
| phase3 `add\|A-13.2·A-16.6` 대소문자·끝 `\` 다른 같은 경로 | 이름 속 실행 GUID 경로(`RUN-…`)만 다름, ok=True | 아니오(폴더 추가) | Phase 1·2·3 때와 같은 패턴 |
| phase5 `flood\|R-24(묶기)` 이벤트 N개를 몇 번에 묶어 반영 | 이름 속 이벤트 수 1831→1824, got `반영 1번` 양쪽 동일, ok=True | 아니오(디스크 감시 묶기) | Phase 3 때(1818→1831)와 같은 패턴 |
| phase1 `itemDiffs` 1 | phase1 은 `checks` 배열이 없는 스크립트라 비교 대상이 아님(null 1개를 세어 나온 값) | 아니오 | R-1 바인딩표·사례 이름은 동일 확인 |

- 복사·이동·붙여넣기·Duplicate 관련으로 결과가 달라진 항목: **없음.** 이 경로를 직접 다루는 phase4(208)·d043(13, crossmove 포함)·d044(6)·phase5 계열이 전부 Phase 3·기준선과 같은 통과 수.
- `failedInBoth` 의 `phase1Got` 라벨은 이어받은 이름이며 값은 이번 결과다. 비교 스크립트의 출력 줄 라벨 "baseline"은 `-Ref` 값과 무관하게 고정 문자열이다(내용은 `comparison-vs-phase3.json` 에서 Phase 3 기준).

## 파일

`run-p3d.ps1`·`compare-baseline.ps1`(`-Ref baseline|phase3 -OutName ...`)·`clear-clipboard.ps1`, `run.log`·`run.err`·`run-index.json`, 스크립트별 `verify-v02-*/`, `comparison.json`, `comparison-vs-phase3.json`, `_backup/`.

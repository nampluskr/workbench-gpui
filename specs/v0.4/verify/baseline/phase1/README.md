# P1-E / P1-E-R1 — Phase 1 끝 R-15 회귀 대조 (값 비교)

- 실행일: 2026-11-04, measure. V3(스크립트 실행). 사용자 부재, 입력 없음.
- 대상: master `99ec7dc`. `cargo build` 경고 0·오류 0, `tools/apply-manifest.ps1` 실행. 실행 전 workbench-gpui 프로세스 없음, 클립보드 비움. src·tools 무변경.
- 실행(P1-E): `run-phase1.ps1`(R-1의 `run-baseline.ps1`에서 출력 경로만 `baseline\phase1`로 변경). 스크립트 9개를 `-OutDir specs\v0.4\verify\baseline\phase1\<이름>`, 절대 `-Exe`로 1회씩. exit: phase3만 1, 나머지 0(`run-index.json`). 앱 데이터 `_backup/after.json` restored=true.
- **P1-E-R1(reviewer Must fix 1)**: 앱을 다시 돌리지 않고 저장된 `results.json`만으로 다시 대조했다. 이전 판정(`ok`만 비교, "다른 항목 0")은 철회하고 이 문서로 대체한다.

## 비교 방법 (`compare.ps1`)

- 항목 키는 `사례#사례 안 순번`. 항목마다 `what`·`expect`·`got`·`ok`를 모두 비교한다. phase1(checks 배열 없음)은 저장된 형식대로 `cases.*.keys[]`의 `keys`·`note`·`expect`/`expectContext`·`got`/`context`·`ok` 70항목을 비교한다.
- 실행마다 달라지는 값만 가린 뒤 비교한다(D-8, 실행 식별자): 벽시계 `t_ms`, ISO 시각, GUID, `run-<hex>` 폴더, `*_ms`·`dt=`·`Nms` 같은 시간 길이, `state.json.bad-<시각>`, 파일 ID(`root_id`·`old_id`·`new_id`), `wg-p4-d044-<hex>`, 그리고 설명에 `ms`가 든 항목의 숫자 값(툴팁 지연 등). 이렇게 가려진 항목은 raw 값이 달라도 `ok`가 같은지만 본다(`timeMasked` 개수). 가림 규칙에 들지 않는 값(개수, offset, 경로 구조, 문구)은 그대로 비교한다.
- 다른 항목마다 과거 값을 찾았다: `specs/v0.2/verify/phase3/*-rerun`, `phase5/*-rerun`, `specs/v0.3/verify/baseline`·`p3d`·`phase1`·`phase2`·`phase3`, v0.4 R-1. 값 목록은 `history-values.txt`.

## 대조 결과

| 스크립트 (`verify-v02-` 생략) | R-1 통과/실패 | Phase 1 통과/실패 | 항목 수 | 시간 값만 다름(`ok` 동일) | 값이 다른 항목 | 의도한 변경 여부 |
|---|---|---|---:|---:|---:|---|
| phase1 | 70 / 0 | 70 / 0 | 70 | 0 | 0 | 변화 없음 |
| phase2 | 137 / 0 | 137 / 0 | 137 | 25 | 0 | 변화 없음 |
| phase3 | 120 / 2 | 120 / 2 | 122 | 19 | **1** | 아래 ① — 이력상 흔들림. AUDIT 3·4 변경 아님 |
| phase4 | 208 / 0 | 208 / 0 | 208 | 15 | 0 | 변화 없음 |
| phase4-d043 | 13 / 0 | 13 / 0 | 13 | 2 | 0 | 변화 없음 |
| phase4-d044 | 6 / 0 | 6 / 0 | 6 | 3 | 0 | 변화 없음 |
| phase5 | 62 / 0 | 62 / 0 | 62 | 43 | **2** | 아래 ②③ — 이력상 흔들림. AUDIT 3·4 변경 아님 |
| phase5-d046 | 23 / 0 | 23 / 0 | 23 | 17 | 0 | 변화 없음 |
| phase5-d047 | 16 / 0 | 16 / 0 | 16 | 11 | 0 | 변화 없음 |

값이 다른 항목은 모두 3건이다. **의도한 변경(AUDIT 3·4) 0건, 이력상 흔들림 3건, 미설명 0건.**

## 값이 다른 항목과 과거 값

| # | 스크립트 / 사례 / 항목 | R-1 값 | Phase 1 값 | 과거 값(같은 항목) | 분류 |
|---|---|---|---|---|---|
| ① | phase3 / scroll / A-16.7 목록 휠 스크롤 | `offset_y=-23` | `offset_y=-234` | v0.2 재실행 8개(`phase3` 본 실행, d037·d040·d043·d046·d047·p4·p5) 전부 -234 / v0.3 기준선 -23 / v0.3 p3d -23 / v0.3 phase1 -234 / v0.3 phase2 -23 / v0.3 phase3 -23 | 이력상 실행마다 흔들림 (HERDR-DECISIONS H-10) |
| ② | phase5 / flood / R-24 밖에서 파일 600개 → 트리 (`watch-applied events`) | 1815 | 1811 | v0.3 기준선 1818 / p3d 1824 / phase1 1811 / phase2 1825 / phase3 1831 | 이력상 실행마다 흔들림 |
| ③ | phase5 / flood / R-24(묶기) `반영 1번, 이벤트 N` | 1815 | 1811 | ②와 같은 값의 요약 줄. 반영 횟수는 둘 다 1번 | 이력상 실행마다 흔들림 |

- ①: 두 값이 한 코드에서 번갈아 나왔다(-23 / -234). 스크립트가 휠 입력 600ms 뒤의 마지막 스크롤 로그를 저장하므로 스크롤 진행 중 표본이다. 두 값 모두 스크립트 판정(`offset_y < 0`)은 통과다. 이 해석은 H-10에서 lead가 정한 것이고 D-8 해석으로 사용자 확인 대상이다. measure는 값 자체가 이력에 있다는 사실만 확인했다.
- ②③: OS가 보낸 파일 이벤트 개수라 600개 생성에 대해 1811~1831 범위에서 매번 달랐다. Phase 1의 1811은 v0.3 phase1의 값과 같다. 스크립트 판정(이벤트가 1번으로 묶여 반영됨, `ok`)은 R-1과 같다. AUDIT 3·4(붙여넣기·복제 알림, cut 보존, 백그라운드 처리)와 관련된 코드 경로가 아니다.

## 남은 것

- phase3 R-28 폭 2건(시작 폭 기대 300 / 실제 375, 저장 폭 복원 기대 494 / 실제 617)은 R-1과 값까지 같다(원인 미확정, 이번 범위 밖).
- phase4 판정 불가(A-14.3 휴지통 내부, A-14.5 복원)는 R-1과 같은 환경 원인(D: NukeOnDelete=1).
- 이 스크립트들은 AUDIT 3·4의 새 동작을 직접 검사하지 않는다(V1 테스트 몫).
- `compare.ps1`을 다시 돌리면 `comparison.json`이 새로 써져 분류·과거 값 주석(`classification`·`history`·`unexplained`)이 사라진다. 주석은 위 표가 기준이다.
- 파일: `compare.ps1`(비교기), `comparison.json`(스크립트별 항목 수·시간 값 개수·다른 항목+분류), `history-values.txt`(과거 값 목록).

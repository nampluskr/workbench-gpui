# P0-1 — v0.4 기준선 (R-1)

- 실행일: 2026-11-04, measure. 검증 수준 V3(스크립트 실행). 사용자 부재, 입력 없음.
- 빌드: master `5481e2a`(+ 작업 트리 변경은 문서뿐, src 무변경). `cargo build` 경고 0, `apply-manifest.ps1` 실행, `cargo test` **60 통과 / 0 실패**, `cargo clippy --all-targets`(-D warnings 없이) **경고 10**. v0.3 종료 값(0 / 60 / 10)과 동일. 로그: `_build.log`, `_test.log`, `_clippy.log`. 상세 `build.md`.
- 실행: `run-baseline.ps1`(v0.3 `run-p0-0c.ps1`에서 경로만 v0.4로, d043-clip 제외). 시작 전 workbench-gpui 프로세스 없음, 클립보드 비움. 각 스크립트는 `-OutDir specs\v0.4\verify\baseline\<이름>`과 절대 `-Exe`(`target\debug\workbench-gpui.exe`)로 1회씩 실행. phase1은 `specs/v0.2/verify/phase1/r1-expected.tsv`를 읽어 출력 폴더에 복사해 두고 실행(v0.3 방식, 원본 불변). 재실행 없음.
- 결과: `run-index.json`(exit), `comparison.json`, 폴더별 `results.json`·`console.log`.
- 앱 데이터(`%APPDATA%\workbench-gpui`): 전후 파일 없음, `_backup/after.json` restored=true.

## 결과와 v0.3 기준선 대조

| 스크립트 (`verify-v02-` 생략) | exit | v0.4 통과/실패 | v0.3 통과/실패 | 차이 |
|---|---|---|---|---|
| phase1 | 0 | 9사례, failures 0 | 9사례, failures 0 | 동일 |
| phase2 | 0 | 137 / 0 | 137 / 0 | 동일 |
| phase3 | 1 | 120 / 2 | 120 / 2 | 동일(같은 2건) |
| phase4 | 0 | 208 / 0 | 208 / 0 | 동일 |
| phase4-d043 | 0 | 13 / 0 | 13 / 0 | 동일 |
| phase4-d044 | 0 | 6 / 0 | 6 / 0 | 동일 |
| phase5 | 0 | 62 / 0 | 62 / 0 | 동일 |
| phase5-d046 | 0 | 23 / 0 | 23 / 0 | 동일 |
| phase5-d047 | 0 | 16 / 0 | 16 / 0 | 동일 |

checks 배열이 있는 8개: **사례 수·통과·실패가 v0.3과 전부 같다**(585 통과 / 2 실패). 변화 0.

## 알려진 실패 2건 (v0.3과 동일, 새 회귀 아님)

| 사례 / 요구 | 기대 | 실제 |
|---|---:|---:|
| state / R-28 시작 폭 | 300 | 375 |
| state-restart / R-28 저장 폭 복원 | 494 | 617 |

원인은 v0.3부터 미확정(약 1.25배). 이번 카드에서 조사·수정하지 않았다.

## 남은 것

- phase4의 판정 불가(휴지통 내부·복원, A-14.3·A-14.5)는 v0.3과 같은 환경 원인(D: NukeOnDelete=1)으로 보인다. 설정을 바꾸지 않았다.
- d043-clip은 v0.3과 같은 이유(Before 원본 없음)로 실행하지 않았다.

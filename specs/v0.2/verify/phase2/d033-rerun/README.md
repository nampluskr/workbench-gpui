# Phase 2 다시 돌리기 (리뷰 2회차, D-033)

- **까닭:** Phase 2 리뷰 2회차 지적(docs/HERDR-DECISIONS.md D-033)을 고쳤다. 고친 것은 ② 열기 직전 포커스에서 가려진 키를 메뉴 포커스로 다시 찾지 않기, ⓐ 50ms 예약은 세대가 같을 때만 꺼내 실행, ⓑ 메뉴 항목 chord 를 gpui 와 같게 접두 대기·완성·시간 초과로 확정한 뒤 예약, 이렇게 셋이다. 세 경로의 재현 사례(shadowpp, rapid, chord)를 `tools/verify-v02-phase2.ps1` 에 더했다.
- **위치:** 위 폴더(`../`)와 `../d032-rerun/` 는 그대로 둔다. Phase 2 검증 보고서(`../REPORT.md`)가 인용한다.
- **고치기 전(`before-fix/`):** 고치기 전 소스(D-032 반영판)로 만든 실행 파일에 새 사례 셋만 돌렸다. 판정 7개 중 2개만 통과했다.

| 사례 | 고치기 전 (`before-fix/`) | 고친 뒤 (이 폴더) |
| --- | --- | --- |
| shadowpp (②) | 1개 중 통과 0. 패널에서 가려졌는데 View 에 `Ctrl-B` 표시 | 1개 중 통과 1. 표시 없음 |
| rapid (ⓐ) | 2개 중 통과 1. 예약은 두 번 되었지만 아무것도 실행 안 됨 | 2개 중 통과 2. 마지막 예약(Project Panel)만 실행 |
| chord (ⓑ) | 4개 중 통과 1. Ctrl-K 에서 바로 Toggle Left Dock 실행(약 0.1초) | 4개 중 통과 4. Ctrl-K Ctrl-Y → Project Panel, Ctrl-K 만 → 1초 뒤 Toggle Left Dock |

- **고친 뒤 전체:** `pwsh -NoProfile -File tools/verify-v02-phase2.ps1 -OutDir specs\v0.2\verify\phase2\d033-rerun`(2026-11-01). 11개 사례, 판정 136개 모두 통과, R-5 대조 24줄 불일치 0.
- **사용자 keymap.json:** 모든 실행에서 `<absent>` → `<absent>`.

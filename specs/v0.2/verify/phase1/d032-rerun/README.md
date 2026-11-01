# Phase 1 다시 돌리기 (Phase 2 리뷰 1회차, D-032 뒤)

- **까닭:** Phase 2 리뷰 1회차 수정(☰ 메뉴 단축키 해석·표시 문자열 조회)이 키맵 쪽 코드(`src/ui/keymap.rs` `shortcut_for_name`)를 바꿨다. 그래서 Phase 1 스크립트도 다시 돌렸다.
- **위치를 따로 둔 까닭:** `../` 와 `../d031-rerun/` 의 증거는 Phase 1·2 검증 보고서가 줄 번호로 인용한다. 그래서 그대로 둔다.
- **실행:** `pwsh -NoProfile -File tools/verify-v02-phase1.ps1 -OutDir specs\v0.2\verify\phase1\d032-rerun`(2026-11-01). `r1-expected.tsv` 는 `../r1-expected.tsv` 를 복사한 것이다.
- **결과:** 9개 사례 실패 0. R-1 기대 62줄 모두 일치. 사용자 keymap.json 은 `<absent>` → `<absent>`.

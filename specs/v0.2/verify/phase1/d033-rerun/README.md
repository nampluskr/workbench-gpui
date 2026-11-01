# Phase 1 다시 돌리기 (Phase 2 리뷰 2회차, D-033 뒤)

- **까닭:** Phase 2 리뷰 2회차 수정이 `src/ui/keymap.rs` `shortcut_for_name` 을 바꿨다. 그래서 Phase 1 스크립트도 다시 돌렸다.
- **위치:** `../`, `../d031-rerun/`, `../d032-rerun/` 은 그대로 둔다.
- **실행:** `pwsh -NoProfile -File tools/verify-v02-phase1.ps1 -OutDir specs\v0.2\verify\phase1\d033-rerun`(2026-11-01). `r1-expected.tsv` 는 `../r1-expected.tsv` 를 복사한 것이다.
- **결과:** 9개 사례 실패 0, R-1 기대 62줄 모두 일치. 사용자 keymap.json 은 `<absent>` → `<absent>`.

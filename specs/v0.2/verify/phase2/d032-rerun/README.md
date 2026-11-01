# Phase 2 다시 돌리기 (리뷰 1회차, D-032)

- **까닭:** Phase 2 리뷰 1회차 Major 3건(docs/HERDR-DECISIONS.md D-032)을 고치고, 세 경로를 재현하는 사례(pending, shadow, prevctx)를 `tools/verify-v02-phase2.ps1` 에 더했다.
- **위치를 따로 둔 까닭:** 위 폴더의 증거는 Phase 2 검증 보고서(`../REPORT.md`)가 줄 번호로 인용한다. 그래서 그대로 두고, 다시 돌린 결과만 이 폴더에 넣었다.
- **실행(고친 뒤):** `pwsh -NoProfile -File tools/verify-v02-phase2.ps1 -OutDir specs\v0.2\verify\phase2\d032-rerun`(2026-11-01). 사례는 8개(tooltip, menu, reload, pending, shadow, prevctx, quit, closewin)이고, 판정 129개 모두 통과, R-5 대조 24줄 불일치 0 이다.
- **고치기 전(`before-fix/`):** 고치기 전 소스(커밋 전 index 의 `src/ui/app_menu.rs`·`src/ui/keymap.rs`)로 만든 실행 파일에 새 사례 셋만 돌린 결과다. 판정 11개 중 7개가 실패했다.
  - **pending(①):** View 에서 Ctrl-B 와 Left 를 지연 없이 보내면, 50ms 예약이 File 의 0번 항목(Close Window)을 실행해 앱이 닫혔다.
  - **shadow(②):** 사용자 키맵이 Workspace 의 ctrl-b 를 zed::Minimize 로 덮어써도, 메뉴·툴팁에 Toggle Left Dock / Close Left Dock 의 `Ctrl-B` 가 보였다.
  - **prevctx(③):** ProjectPanel 전용 사용자 바인딩 ctrl-y 가 메뉴에 `Ctrl-Y` 로 보이지만, 눌러도 예약·실행되지 않았다.
- **사용자 keymap.json:** 실행 전후 모두 `<absent>` 다(`results.json` 의 `userKeymap`).

# Phase 1 다시 돌리기 (D-031 ③, v0.2 Phase 2 중)

- **까닭:** ☰ 메뉴의 Quit(I-341, Ctrl-Q)·Close Window(I-358, Ctrl-Shift-W) 키를 내장 키맵에 더했다(DECISIONS D-2 이후 변경, docs/HERDR-DECISIONS.md D-031 ③). R-1 기대 표(`../r1-expected.tsv`)에 두 줄을 더하고, Phase 1 검증 스크립트가 여전히 통과하는지 다시 돌렸다.
- **위치를 따로 둔 까닭:** 위 폴더의 증거는 Phase 1 검증 보고서(`../REPORT.md`)가 줄 번호로 인용한다. 그래서 그대로 두고, 다시 돌린 결과만 이 폴더에 넣었다.
- **실행:** `pwsh -NoProfile -File tools/verify-v02-phase1.ps1 -OutDir specs\v0.2\verify\phase1\d031-rerun`(2026-11-01). 스크립트가 기대 표를 출력 폴더에서 읽으므로 `r1-expected.tsv` 를 복사해 두었다(내용은 `../r1-expected.tsv` 와 같다).
- **결과:** 9개 사례 실패 0. R-1 기대 62줄 모두 일치, 앱 내장 바인딩 54개, 표 밖 0(`r1-bindings.md`). 사용자 keymap.json 은 `<absent>` → `<absent>`.
- **바뀐 앱 동작:** 이제 F10 이 실제로 ☰ 메뉴를 열어 포커스가 메뉴로 간다(base 사례의 F10 다음 키는 컨텍스트에 `menu` 가 붙는다). 판정에는 영향이 없다.

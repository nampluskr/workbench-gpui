# v0.2 Phase 2 증거 (wg-coder)

판정 보고서는 wg-checker 가 쓴다. 이 파일은 증거 파일의 목록과 읽는 법, 그리고 coder 쪽에서 판정하지 못한 것을 적는다.

- **만든 방법:** `pwsh -NoProfile -File tools/verify-v02-phase2.ps1`(2026-11-01). 디버그 빌드에 `tools/apply-manifest.ps1` 를 적용한 뒤 돌렸다.
- **결과:** 5개 사례(tooltip, menu, reload, quit, closewin), 판정 118개 모두 통과, R-5 대조 21줄 불일치 0. 사용자 keymap.json 은 실행 전 `<absent>` → 뒤 `<absent>`(`results.json` 의 `userKeymap`).
- **창 상태:** 기본 창(1440×900 논리 px)은 200% 배율에서 작업 영역보다 커 아래쪽이 작업 표시줄에 가린다. 그래서 스크립트가 띄운 창만 최대화한 뒤 잰다. 이때 viewport 는 1440×852 이다.

## 파일

| 파일 | 내용 |
| --- | --- |
| `r5-shortcuts.md` | R-5 대조표: 메뉴 항목·툴팁마다 "화면 단축키 / 키맵 적용 결과 / 01-zed 원문" |
| `results.json` | 판정 118개(`checks`: ID·무엇·기대·실제·통과), R-5 줄(`shortcutRows`), 툴팁 측정값(`cases.tooltip.tooltips`: 지연 ms, 마우스 위치, 상자 경계, 뒤집기 여부), 메뉴 경계(`cases.menu.viewBox`·`viewRows`·`menuNames`) |
| `<사례>-stdout.txt` | 앱 `--dev-keymap --dev-layout` 표준출력 |
| `r7-<요소>.png` | 요소마다 툴팁이 뜬 화면(R-6·R-7). `r7-status-btn-project-panel-closed.png` 는 Dock 을 닫은 뒤 |
| `r8-closed.png`, `r8-menu-0..3.png` | ☰ 닫힘, 메뉴 4개(workbench-gpui, File, View, Window)를 hover 로 차례로 연 화면(R-8·R-9) |
| `r8-before-zoom.png`, `r8-after-zoom.png` | Window > Zoom 클릭 전후 |
| `r4-menu-before/after.png`, `r4-tooltip-before/after.png`, `reload-keymap-2.json` | Phase 1 에서 이월한 R-4 화면 판정. keymap.json 을 바꿔 저장하기 전후 |

## 출력 줄 읽는 법

- `[dev] tooltip-shown id= t_ms= mouse=x,y rows=제목|단축키<TAB>…`: 툴팁을 만든 시각(유닉스 ms), 그때의 마우스 위치(창 기준 논리 px), 줄들이다. 줄 구분은 탭(단축키 `;` 와 겹치지 않게)이고, `<none>` 은 단축키가 없다는 뜻이다(L-223).
- `[dev] menu-render index= name= selected= rows=라벨|단축키<TAB>---<TAB>…`: 메뉴가 그린 항목이다. `---` 은 구분선이다.
- `[dev] menu-open / menu-selected / menu-close reason= / menu-shortcut / menu-exec action= via=`: 메뉴 상태 변화.
- `[dev] layout-box seq= name= bounds=x,y,w,h`: 경계(창 기준 논리 px). Phase 2 부터 스냅숏에는 마지막으로 그린 프레임의 요소만 나온다(`src/ui/layout_probe.rs`). 그래서 툴팁·메뉴가 사라지면 그 경계도 사라진다.
  - `tooltip-box` 는 보이는 툴팁 상자다(투명 여백 제외).
  - `menu-box` 는 메뉴 상자(테두리 포함), `menu-row-NN` 은 항목·구분선, `menu-name-N` 은 가로 메뉴 이름이다.
- `[dev] display seq= where=center action= text=`: 키맵 적용 결과(I-704). R-5 대조의 "키맵 적용 결과" 열이다.

## 판정 방법 요약

- **R-6 시점:** 마우스를 옮긴 시각(스크립트의 유닉스 ms)과 `tooltip-shown t_ms` 의 차를 본다. 10개 요소 모두 500~515ms 였다.
- **R-6 위치:**
  - 뒤집지 않으면 보이는 상자 = 마우스 + (1, 1) + 투명 여백 (8, 10) 이다(L-208·L-209).
  - 창을 넘으면 마우스 − 상자 − 1 이다(L-210).
  - 넘는지는 viewport 와 바깥 상자 크기로 계산했다. ±1 px 로 판정했다.
  - 오른쪽 뒤집기(탭 바 +·분할·최대화)와 아래 뒤집기(사이드바 푸터·상태 표시줄)가 모두 실제로 일어났다.
- **R-6 사라짐:** 벗어남·누름·스크롤 뒤 2초 안에 `tooltip-box` 가 스냅숏에서 없어지는지 본다.
- **R-7:** 툴팁 문구를 표와 글자 단위로 대조했다. 툴팁 없는 요소(창 버튼 2개, 사이드바 폴더 줄)는 1.5초 올려도 `tooltip-shown` 이 없어야 한다.
- **R-8:**
  - ☰ 클릭 → 첫 메뉴(I-302), 이름 hover 전환(I-303), Left/Right 순환(I-303·I-310), F10 열기·닫기(I-310)를 확인했다.
  - 항목·구분선은 02 9.2절에서 동작 항목만 거른 결과다(D-13 이후 변경).
  - Enter 실행, 실행 때 원래 포커스(center, I-309), 항목 클릭 실행, Window > Zoom·Minimize, Quit·Close Window(프로세스 끝남)를 확인했다.
- **R-9:**
  - 메뉴 상자·항목·구분선 경계로 잰 값: I-313 바깥 폭 ≥ 202, I-314 위치 −5·0, I-315 목록 위아래 4, I-316 항목 바깥 4, I-317 줄 높이 22.65(실측 22.50, 200% 배율의 0.5 px 반올림), I-318 구분선 1·위아래 6, I-321 이름 사이 4.
  - 목록 키 15가지(I-517·I-518), Escape·Ctrl-C·메뉴 밖 누름 닫기(I-519), 단축키 실행 50ms(I-520, 실측은 `results.json`)를 확인했다.

## 판정하지 못한 것 / 다른 Phase 로 넘긴 것

- **I-313 최대 높이 75%·세로 스크롤:** v0.2 메뉴는 항목이 1~3개라 넘치지 않는다. 코드(`app_menu.rs` `max_h(viewport 높이 × 0.75)` + `overflow_y_scroll`)로만 확인했다.
- **I-515 비활성 항목:** D-13 으로 동작하는 항목만 두어 v0.2 메뉴에 비활성 항목이 없다. 판정 대상이 없다.
- **L-213~L-216 상자 안 치수:** 상자 바깥 경계만 쟀다(`results.json` 의 툴팁 `box`). 안쪽 여백 4·8, gap 16, 최대 폭 288 은 코드 값(`tooltip.rs`)이다. 메타 줄(L-216)을 쓰는 툴팁은 v0.2 에 없다.
- **L-205(메뉴가 열려 있는 동안 ☰ 툴팁 없음):** 열려 있는 동안 ☰ 버튼 자체가 그려지지 않고 가로 메뉴 이름으로 바뀐다(구조로 보장). 메뉴 이름 버튼에는 툴팁이 없다.
- **L-211·L-212 색·그림자, I-514·I-319 색:** 테마 매핑(PoC 7단계) 전이라 판정하지 않는다(SPEC R-6·R-9).
- **Phase 3 이월(D-031 ④):** ☰ 메뉴의 Open Folder...·Toggle Folder Sidebar·Focus Folder Sidebar 항목, 사이드바가 닫혔을 때의 "Open Folder Sidebar" 툴팁(L-251).
- **Phase 4 이월:** 프로젝트 패널 항목 툴팁(경로, 1500ms, L-247).

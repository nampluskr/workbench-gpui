[DONE] ORDER-06 gpui (1단계)        (탭 순환 화면 확인 1건 측정 불가, 코드 커밋은 ORDER-06-R1과 함께 — 아래)

## 완료 기준 (1단계)
| 번호 | 기준 | 결과 | 근거 |
|---|---|---|---|
| 1 | I-17 판정 방법, 두 갈래 메뉴 표가 같음 | 충족(두 갈래 표 차이 3곳은 아래, 결정 요청) | 메뉴 막대 workbench-gpui·File·Edit·View·Go·Window·Help(Zed 순서, Selection·Run 없음, 마지막 Help). 구현된 항목만. 열렸을 때 폴더 이름이 한 번 더 보이지 않음(원인: `title_bar::left_group`이 열림 상태와 무관하게 폴더 이름을 붙임 → 열림 동안 뺌). 메뉴 막대 gap 4px(I-321) 실측 4.0px. 대표 항목 동작(Save, Undo/Redo, Open Markdown Preview·to the Side, Split Right) 캡처 확인. Help: View Dependency Licenses(글꼴 2개·Zed 아이콘 라이선스 3개, 별도 창) PASS, File Bug Report…·Request Feature…(`github.com/nampluskr/workbench-gpui/issues/new`)·Repository는 브라우저를 열어 측정 때 누르지 않음(코드 확인). 표: `specs/v0.5/SPEC.md` R-17, 판정 `specs/v0.5/verify/reviews/measure-ORDER-06.md` |
| 2 | I-2 v 버튼·여섯 항목이 Zed와 같은 순서·단축키, 미동작 항목이 앱을 망가뜨리지 않음 | 충족 | v 버튼(최소화 앞, Zed `chevron_down.svg`), Settings `Ctrl-,` · Keymap `Ctrl-K Ctrl-S` · Themes… `Ctrl-K Ctrl-T` · Icon Themes… · Extensions `Ctrl-Shift-X` · Panel Layout ▸. 동작이 아직 없는 항목은 **비활성(회색), 눌러도 아무 일 없음**(단축키도 무동작). Themes·Icon Themes는 Phase 7까지 이 상태. Zed v 메뉴 캡처와 대조 PASS |
| 3 | `ORDER-06-zed.md` | 충족(일부 tauri 근거) | `specs/v0.5/reports/ORDER-06-zed.md` |
| 4 | 이 보고 | 충족 | |

탭 순환(Go Previous/Next Tab, core-leader 결정으로 새로 만듦: `pane::ActivatePreviousItem`/`ActivateNextItem`, `Ctrl-PageUp`/`Ctrl-PageDown`, tauri와 같음): V1 테스트(`cargo test k10` — 양방향 순환, 탭 1개·0개)로 확인. 화면 확인은 **측정 불가** — 스크립트가 두 번째 파일을 열 때 미리보기 탭이 첫 탭을 대체해 탭이 하나뿐이었다(`measure-ORDER-06/error-two-tabs-open.png`).

## 두 갈래 메뉴 표 차이 (결정 요청)
| 메뉴 | 항목 | gpui | tauri | 처리 |
|---|---|---|---|---|
| View | Split Up/Down/Left/Right | View 직접 항목 | View → Editor Layout 하위 메뉴 | ORDER-06-R1 2.5대로 gpui가 옮기는 중(K-11-R1) |
| File | Close Editor | 단축키 표시 `Ctrl-W`(키맵 `ctrl-w`·`ctrl-f4` → `pane::CloseActiveItem`) | 표시 없음 | **core 결정 요청** — Zed 메뉴처럼 표시할지 |
| Edit | Redo | `Ctrl-Y`(gpui-kit input 키맵) | `Ctrl-Shift-Z` | **core 결정 요청** — 두 갈래 같은 키로 |
그 밖에 참고(메뉴 표 밖): 메뉴 이름 간격은 gpui는 막대 gap 4px만 쟀고 tauri는 잉크 간격 12~13px(Zed 13~14px)까지 쟀다 — 2단계 V3에서 같은 방식으로 다시 잰다. Licenses 내용(tauri는 Lucide·테마 라이선스도), "v" 버튼 치수(tauri 22×22·아이콘 14px) — 2단계에서 맞춘다.

## 덧붙임 — ORDER-05 남은 1자리
pane 축소 아이콘(`minimize.svg`): Shift-Escape로 확대 진입 뒤 앱·Zed 크롭 대조 **PASS**(`measure-ORDER-06-run2/app-tabbar-zoomed.png`, `zed-tabbar-zoomed.png`). → ORDER-05 V3 22/22.

## 바꾼 파일
- `src/ui/app_menu.rs`, `src/ui/mod.rs`, `src/ui/title_bar.rs`(K-09), `src/ui/tab_input.rs`, `src/ui/keymap.rs`, `src/keymap/builtin.rs`, `src/keymap/mod.rs`(K-10), `tools/measure/order06-v3.ps1`, 문서·측정.
- **커밋 안 함(아직)**: ORDER-06-R1 작업(K-11-R1)이 같은 파일을 고치는 중이라 R1과 함께 커밋한다. push 없음.

## 검토
- checker C-22: K-09 리뷰 PASS, K-10 리뷰 PASS. C-23: 1단계 V3 판정.
- 과정: 측정 스크립트가 세 번 막혔다(세션 시작 직후 멈춤 — session.ps1 출력 파이프를 앱이 물려받음, Zed 단계 StrictMode 오류, 탭 두 개 열기 실패). Zed Settings 창 사건은 `ORDER-06-zed.md`.

## 사용자 확인 필요(V4)
없음(2단계에서).

## BLOCKED
없음. 결정 요청 2건(Close Editor 단축키 표시, Redo 단축키).

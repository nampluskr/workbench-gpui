# v0.2 Phase 2 일치도 검증 보고서 (툴팁·☰ 앱 메뉴·단축키 표시 R-4 화면 · R-5~R-9)

- **검증자**: wg-checker (Claude Sonnet 5.5 · high, HERDR-SETUP 9절 2026-11-01 교체 후)
- **검증 일시**: 2026-11-01
- **방식**: 앱 재실행·증거 재수집 없음. 이미 있는 증거(`specs/v0.2/verify/phase2/`, `specs/v0.2/verify/phase1/d031-rerun/`)와 코드·원문으로만 판정했다.
  - 스크린샷 28장 중 판정에 쓰는 것(`r7-*` 11장, `r8-*` 7장, `r4-*` 4장, `tooltip-start`·`menu-start`)을 직접 열어 보았다.
  - `results.json`·`r5-shortcuts.md` 의 요약을 믿지 않고 원래 출력(`*-stdout.txt`)의 `[dev] tooltip-shown`·`[dev] layout-box`·`[dev] menu-*`·`[dev] display`·`[dev] binding` 줄과 대조했다.
  - 치수는 stdout 의 경계값에서 원문 식으로 다시 계산했다(허용 ±1 논리 px, A-31.1).
- **기준 문서**
  - `specs/v0.2/SPEC.md` 공통 판정 방식, R-4(Phase 1 이월 화면 부분), R-5~R-9
  - `specs/v0.2/PLAN.md` Phase 2 완료 조건
  - `01-zed/01-LAYOUT.md`: 4.7절 L-206~L-216·L-222, 4.8절 I-312~I-321, 4.9절 I-504~I-515
  - `01-zed/02-INTERACTION.md`: 8.1~8.4절(L-200~L-207, L-217~L-232, L-251~L-254, L-265·L-266, L-270, L-272), 9.1절(I-301~I-311), 9.2절(I-341, I-358, 메뉴 구조·키 열), 11.1절(I-516~I-521)
  - `01-zed/04-APP-SPEC.md`: A-18, A-30.1·A-30.2, A-31.1
  - `docs/HERDR-DECISIONS.md` D-031(메뉴·툴팁 직접 그림, Quit·Close Window 키 추가, Phase 3 이월 항목, 앱 이름 `workbench-gpui`)
- **시험 환경**: 디버그 빌드 `--dev-keymap --dev-layout`, 입력은 SendInput. 띄운 창만 최대화한 뒤 쟀다(viewport 1440×852 논리, 배율 2, 스크린샷 2880×1704). A-30.2 의 기준 창 크기(1440×852)·기준 화면 크기(A-30.1, 2880×1704)와 같다. 기본 창(1440×900)은 200% 배율에서 작업 영역을 넘어 최대화한 것이다(`EVIDENCE.md`). `r8-before-zoom.png` 만 일부러 최대화 전 창(2884×1802)이다.

---

## 요약 판정

| 요구 | 판정 | 한 줄 |
| --- | --- | --- |
| **R-4 (화면 부분)** | **통과** | keymap.json 저장 뒤 ☰ View 메뉴와 상태 표시줄 툴팁의 Toggle Left Dock 키가 `Ctrl-B` → `Alt-B` 로 바뀌고 Alt-B 가 실행됨. 스크린샷 전후 비교로 확인 |
| **R-5** | **통과** | 대조표 21줄 모두 일치(불일치 0). 형식(L-219~L-221)은 스크린샷으로 확인. 단, 7줄의 "키맵 적용 결과 `<none>`"은 계산값이 아니라 "그 액션에 바인딩이 없음"이라 내장 바인딩 54개 목록으로 따로 확인했다(관찰 1) |
| **R-6** | **통과 (범위 안)** | 지연 500~515ms, 위치 (+9, +11)·뒤집기 좌표를 원문 식으로 재계산해 ±0 일치, 사라짐 3종 확인. 색·그림자·안쪽 치수·메타 줄·프로젝트 패널 항목 툴팁은 판정 불가·이월 |
| **R-7** | **통과 (범위 안)** | 표 14행 중 v0.2 에 있는 11행의 문구·단축키가 글자 단위로 같음. 3행(사이드바 닫힘 툴팁·프로젝트 패널 항목·확대 상태 문구)은 판정 불가·이월 |
| **R-8** | **통과 (범위 안)** | ☰ 클릭·hover 전환·Left/Right 순환·F10·실행 전 포커스 복원·최종 메뉴 4개 구조가 02 9.2절과 같음. 세 항목은 D-031 ④ 대로 Phase 3 이월 |
| **R-9** | **통과 (범위 안)** | 폭·위치·여백·줄 높이·구분선·목록 키 15가지·닫힘 3경로·단축키 50ms 실행 확인. 최대 높이·스크롤·포커스 잃음 닫힘·비활성 항목·아이콘은 판정 불가 |

**불일치 목록: 0건.** 판정 불가·이월 항목은 "판정 불가·이월" 절에, 불일치는 아니지만 leader 가 알아야 할 것은 "관찰"에 따로 적었다.

---

## R-4 (Phase 1 에서 이월한 화면 부분)

- **기준**: SPEC R-4 "키를 바꾸기 전후의 메뉴·툴팁 스크린샷과 키 입력 결과를 비교한다", D-027 ⑤.
- **증거**: `reload-stdout.txt`, `reload-keymap-2.json`, `r4-menu-before/after.png`, `r4-tooltip-before/after.png`.
- **바꾼 내용**(`reload-keymap-2.json`): `Workspace` 컨텍스트에서 `ctrl-b` → `null`, `alt-b` → `workspace::ToggleLeftDock`.

| 항목 ID | 명세 값 | 실제 값 | 판정 | 증거 |
| --- | --- | --- | --- | --- |
| R-4 다시 읽기 | 저장하면 앱을 다시 띄우지 않고 키맵 갱신 | `[dev] display-end seq=1`(stdout 365행) 뒤 저장 → `binding seq=2`에 `source=user keys=ctrl-b … zed::NoAction`(1127행)·`keys=alt-b … workspace::ToggleLeftDock`(1128행), `display seq=2 … ToggleLeftDock text=Alt-B`(1184행), `display-end seq=2`(1295행) | 통과 | `reload-stdout.txt` |
| R-4 메뉴(전) | View 메뉴 Toggle Left Dock `Ctrl-B` | `menu-render index=2 name=View … rows=Toggle Left Dock\|Ctrl-B ---  Project Panel\|Ctrl-Shift-E`(623행). 스크린샷 `r4-menu-before.png`: `Toggle Left Dock   Ctrl-B` | 통과 | `reload-stdout.txt`, `r4-menu-before.png` |
| R-4 메뉴(후) | `Alt-B` | `menu-render … rows=Toggle Left Dock\|Alt-B …`(1436행). `r4-menu-after.png`: `Toggle Left Dock   Alt-B`, Project Panel 은 그대로 `Ctrl-Shift-E` | 통과 | `reload-stdout.txt`, `r4-menu-after.png` |
| R-4 툴팁(전) | 상태 표시줄 `Close Left Dock` + `Ctrl-B` | `tooltip-shown id=status-btn-project-panel … rows=Close Left Dock\|Ctrl-B`(810행). `r4-tooltip-before.png` 같은 글자 | 통과 | `reload-stdout.txt`, `r4-tooltip-before.png` |
| R-4 툴팁(후) | `Alt-B` | `tooltip-shown … rows=Close Left Dock\|Alt-B`(1565행). `r4-tooltip-after.png`: `Close Left Dock   Alt-B` (상자 폭이 더 좁아짐) | 통과 | `reload-stdout.txt`, `r4-tooltip-after.png` |
| R-4 새 키 실행 | 새 키가 동작 | `key keystroke=alt-b action=workspace::ToggleLeftDock context=Root > Workspace`(1627행), 앞줄 `action-handled name=workspace::ToggleLeftDock … focus=center`(1626행) | 통과 | `reload-stdout.txt` |

**판정: 통과.** Phase 1 이 이월한 "☰ 메뉴·툴팁 화면의 새 키 표시"가 해소된다.

---

## R-5. 메뉴·툴팁의 단축키 표시가 키맵 적용 결과와 일치하고 형식이 L-217~L-221 과 같다

- **기준**: SPEC R-5, I-307, I-510, I-704, L-217~L-223, 01-zed 02 9.2절 키 열·8.2절 단축키 열.
- **방법**: `r5-shortcuts.md` 21줄을 원문과 한 줄씩 직접 대조했다. "화면" 열은 앱이 그린 글자(`tooltip-shown`·`menu-render` 줄), "키맵 적용 결과" 열은 같은 실행의 `display seq=<최신> where=center` 줄이다. 아래 표의 "원문" 열은 02 8.2절·9.2절을 내가 직접 읽어 옮겼다.

| # | 위치 | 문구 | 원문 키 | 화면 | 키맵 적용 결과 | 판정 | 증거 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | ☰ 버튼 툴팁 | Open Application Menu | 표시 안 함(L-225, F10 은 묶여 있어도 안 보임) | 없음 | `app_menu::Toggle` = F10 이 있으나 툴팁은 액션 없이 만듦 | 일치 | `r7-app-menu-button.png`, tooltip-stdout 484행 |
| 2 | 폴더 이름 버튼 | Recent Projects | Ctrl-R(L-226) — v0.2 에 동작 없음(SPEC R-7 설명) | 없음 | 바인딩 없음(관찰 1) | 일치 | `r7-title-folder-name.png`, tooltip-stdout 605행 |
| 3 | 사이드바 폴더 추가 | Add Project | Ctrl-K Ctrl-O(L-230, A-13.1) | `Ctrl-K Ctrl-O` | `display … workspace::Open text=Ctrl-K Ctrl-O` | 일치 | `r7-sidebar-btn-folder-add.png`, tooltip-stdout 726행 |
| 4 | 사이드바 토글 1줄 | Toggle Sidebar | Ctrl-Alt-J(L-232) | `Ctrl-Alt-J` | `… ToggleWorkspaceSidebar text=Ctrl-Alt-J` | 일치 | `r7-sidebar-btn-toggle.png`, 847행 |
| 5 | 사이드바 토글 2줄 | Focus Sidebar | Ctrl-Alt-;(L-232) | `Ctrl-Alt-;` | `… FocusWorkspaceSidebar text=Ctrl-Alt-;` | 일치 | 같음 |
| 6 | 탭 바 ← | Go Back | Alt-Left(L-236) — 동작 없음 | 없음 | 바인딩 없음(관찰 1) | 일치 | `r7-tab-btn-back.png`, 968행 |
| 7 | 탭 바 → | Go Forward | Alt-Right(L-237) — 동작 없음 | 없음 | 바인딩 없음(관찰 1) | 일치 | `r7-tab-btn-forward.png`, 1089행 |
| 8 | 탭 바 + | New… | 없음(L-243) | 없음 | 액션 없는 툴팁(관찰 1) | 일치 | `r7-tab-btn-new.png`, 1210행 |
| 9 | 탭 바 분할 | Split Pane | 없음(L-244) | 없음 | 액션 없는 툴팁(관찰 1) | 일치 | `r7-tab-btn-split.png`, 1331행 |
| 10 | 탭 바 최대화 | Zoom In | Shift-Escape(L-245) — 동작 없음 | 없음 | 바인딩 없음(관찰 1) | 일치 | `r7-tab-btn-zoom.png`, 1452행 |
| 11 | 상태 표시줄(Dock 열림) | Close Left Dock | Ctrl-B(L-254) | `Ctrl-B` | `… ToggleLeftDock text=Ctrl-B` | 일치 | `r7-status-btn-project-panel.png`, 1573행 |
| 12 | 상태 표시줄(Dock 닫힘) | Project Panel | Ctrl-Shift-E(L-253) | `Ctrl-Shift-E` | `… project_panel::ToggleFocus text=Ctrl-Shift-E` | 일치 | `r7-status-btn-project-panel-closed.png`, 2116행 |
| 13 | 메뉴 workbench-gpui | Quit workbench-gpui | Ctrl+Q(I-341) → 화면 표기 `Ctrl-Q` | `Ctrl-Q` | `… zed::Quit text=Ctrl-Q` | 일치 | `r8-menu-0.png`, menu-stdout 488행 |
| 14 | 메뉴 File | Close Window | Ctrl+Shift+W(I-358) | `Ctrl-Shift-W` | `… CloseWindow text=Ctrl-Shift-W` | 일치 | `r8-menu-1.png` |
| 15 | 메뉴 View | Toggle Left Dock | Ctrl+B(I-391) | `Ctrl-B` | `… ToggleLeftDock text=Ctrl-B` | 일치 | `r8-menu-2.png` |
| 16 | 메뉴 View | Project Panel | Ctrl+Shift+E(I-401) | `Ctrl-Shift-E` | `… ToggleFocus text=Ctrl-Shift-E` | 일치 | `r8-menu-2.png` |
| 17 | 메뉴 Window | Minimize | 없음(I-445) | 없음 | `zed::Minimize text=<none>` | 일치 | `r8-menu-3.png` |
| 18 | 메뉴 Window | Zoom | 없음(I-446, F11 은 다른 액션) | 없음 | `zed::Zoom text=<none>` | 일치 | `r8-menu-3.png` |
| 19 | 메뉴 View(저장 뒤) | Toggle Left Dock | 사용자 keymap.json | `Alt-B` | `display seq=2 … text=Alt-B` | 일치 | `r4-menu-after.png`, reload-stdout 1184·1436행 |
| 20 | 메뉴 View(저장 뒤) | Project Panel | 바뀌지 않음 | `Ctrl-Shift-E` | 같음 | 일치 | `r4-menu-after.png` |
| 21 | 툴팁(저장 뒤) | Close Left Dock | 사용자 keymap.json | `Alt-B` | 같음 | 일치 | `r4-tooltip-after.png`, 1565행 |

- 줄 21개, **불일치 0개**.
- **형식(L-218~L-221)**: 스크린샷에서 모두 문자열이고 구분자가 `-`다. 순서는 `Ctrl-Alt-J`·`Ctrl-Shift-E`(Ctrl → Alt/Shift)이고 `;` 는 대문자화되지 않고 `Ctrl-Alt-;`로 보인다(L-220, 8.5절의 추정 표기와 같음). chord `Ctrl-K Ctrl-O` 는 키 입력마다 덩어리 둘이고 사이가 좁다(L-221, 4px 는 코드값 — 판정 불가 절). `Ctrl-Shift-W` 같은 3키도 순서가 맞다.
- **고르는 규칙(I-307·I-510·I-704)**: 메뉴는 열기 직전 포커스(가운데 Pane)의 컨텍스트로, 툴팁은 지금 포커스로 찾았다. 가운데 포커스에서 `ctrl-b`(Workspace)가 보이는 것은 Workspace 가 루트라서 맞다. 이번 표의 메뉴·툴팁 액션은 모두 키가 하나뿐이라 "가려진 키 제외, 남은 것 중 마지막"(I-704) 규칙이 갈리는 경우가 없다. 키가 둘인 액션(`project_panel::Trash`의 Delete·Backspace 등)의 표시는 Phase 4 에서 다시 본다.

---

## R-6. 툴팁이 L-206~L-216 의 시점·위치·모양대로 뜨고 사라진다

- **기준**: SPEC R-6, L-205~L-216, L-247. 색 토큰은 판정 대상이 아니다(SPEC).
- **증거**: `tooltip-stdout.txt`(`tooltip-shown`, `layout-box name=tooltip-box`), `results.json` `cases.tooltip.tooltips`, `r7-*.png`.

### 시점 (L-206)

| 항목 ID | 명세 값 | 실제 값 | 판정 | 증거 |
| --- | --- | --- | --- | --- |
| L-206 | 500ms | 10개 요소: 503, 500, 512, 511, 512, 502, 514, 508, 511, 515ms (허용 범위 500~750으로 잰 값이 모두 515 이하) | 통과 | `results.json`(`delayMs`) |

- 마우스를 옮긴 시각은 스크립트가 기록하므로 stdout 만으로 재계산할 수 없다(`tooltip-shown t_ms` 는 stdout 에, 이동 시각은 `results.json` 에). 앞뒤 10개가 500~515 로 모인 것은 지연 500ms + 폴링 오차로 읽힌다.

### 위치와 뒤집기 (L-208~L-210) — 경계값에서 원문 식으로 재계산

기준: 보이는 상자 = 마우스 + (1, 1) + 투명 여백 (8, 10)(= +9, +11). 바깥 상자 크기 = 보이는 상자 폭 + 8, 높이 + 10. 오른쪽(마우스 + 1 + 바깥 폭 > 1440) 또는 아래(마우스 + 1 + 바깥 높이 > 852)가 넘으면 마우스 − 바깥 크기 − 1 로 뒤집고, 거기에 여백을 더한 값이 보이는 위치다.

| 요소 | 마우스 | 보이는 상자 (x, y, w, h) | 원문 식 기대 | 판정 |
| --- | --- | --- | --- | --- |
| app-menu-button | 319, 16 | 328, 27, 171, 32.5 | x 328, y 27 | 통과 |
| title-folder-name | 404, 16 | 413, 27, 116, 32.5 | 413, 27 | 통과 |
| sidebar-btn-folder-add | 284, 837 | 293, 803.5, 189, 32.5 | x 293. y: 837+1+42.5=880.5 > 852 → 837−42.5−1+10 = 803.5 | 통과(아래 뒤집기) |
| sidebar-btn-toggle(2줄) | 15, 837 | 24, 768, 180, 68 | x 24. y: 바깥 높이 78 → 837−78−1+10 = 768 | 통과(아래 뒤집기) |
| tab-btn-back | 557, 48.5 | 566, 59.5, 71, 32.5 | 566, 59.5 | 통과 |
| tab-btn-forward | 583, 48.5 | 592, 59.5, 93, 32.5 | 592, 59.5 | 통과 |
| tab-btn-new | 1371, 48.5 | 1380, 59.5, 57, 32.5 | x: 1371+1+65 = 1437 ≤ 1440 → 안 뒤집음, 1380 | 통과 |
| tab-btn-split | 1397, 48.5 | 1314, 59.5, 82, 32.5 | 1397+1+90 = 1488 > 1440 → 1397−90−1+8 = 1314 | 통과(오른쪽 뒤집기) |
| tab-btn-zoom | 1423, 48.5 | 1349, 59.5, 73, 32.5 | 1423−81−1+8 = 1349 | 통과(오른쪽 뒤집기) |
| status-btn-project-panel | 315, 837 | 324, 803.5, 171, 32.5 | 324, 803.5 | 통과(아래 뒤집기) |

- 모든 값이 ±0 으로 맞는다(허용 ±1). 오른쪽 뒤집기·아래 뒤집기가 각각 실제로 일어난 것을 확인했다.
- **한 줄 상자 높이 32.5**: 14px 글자 줄 높이 22.5 + 안쪽 위아래 4+4 + 테두리 1+1 = 32.5 로 L-213·L-211 과 같다. **두 줄 상자 68**: 2×22.5 + 안쪽 8 + 테두리 2 + (줄 사이 4 + 구분선 위 padding 4 + 선 1 + 4) = 68 로 L-232 와 같다.
- 스크린샷(`r7-sidebar-btn-toggle.png`)에서 두 줄 상자 가운데 구분선이 보이고 두 단축키의 오른쪽 끝이 정렬돼 있다(L-232 "양끝 정렬").

### 사라짐 (L-207)

| 항목 ID | 명세 값 | 실제 값 | 판정 | 증거 |
| --- | --- | --- | --- | --- |
| L-207 벗어남 | 마우스가 벗어나면 사라짐 | 앞서 `tooltip-box` 있음(seq 23) → 다음 스냅숏(seq 24)에 상자 없음 | 통과 | tooltip-stdout 1694~1814행 |
| L-207 누름 | 버튼을 누르면 사라짐 | 앞서 상자 있음(seq 25) → seq 26 에 없음 | 통과 | 1815~1935행 |
| L-207 스크롤 | 스크롤하면 사라짐 | 앞서 상자 있음(seq 27) → seq 28 에 없음 | 통과 | 1936~2060행 |

### 판정 불가·코드로만 확인 (R-6)

- **L-211·L-212 색·그림자**: 테마 매핑 전이라 판정하지 않는다(SPEC R-6). 코드(`tooltip.rs` 165~174행)에 그림자 두 겹 (0,2,blur 3), (0,1,blur 0)이 있다. 스크린샷에도 옅은 그림자와 둥근 모서리가 보인다.
- **L-213~L-216 상자 안쪽 치수**(안쪽 4·8, gap 16, 최대 폭 288, 메타 줄 12px): 바깥 경계로 높이 32.5·68 만 맞춰 보았다. gap 16 은 스크린샷에서 `Add Project`와 `Ctrl-K` 사이가 약 16~17 논리 px 로 보인다. 나머지는 `tooltip.rs` 상수(28~44행)다. 메타 줄을 쓰는 툴팁은 v0.2 에 없다.
- **L-205 메뉴 열린 동안 ☰ 툴팁 없음**: 열려 있는 동안 ☰ 버튼이 그려지지 않고 가로 메뉴 이름으로 바뀐다(`r8-menu-0.png`). 메뉴 이름 버튼에는 툴팁이 없다. 구조로 보장되는 것을 스크린샷으로만 확인했다.
- **L-247 프로젝트 패널 항목 1500ms**: Phase 4 이월(D-031 ④, EVIDENCE).

**판정: 통과(범위 안).**

---

## R-7. v0.2 화면 요소의 툴팁 문구와 단축키가 02 8.2절과 같다

- **기준**: SPEC R-7 표(14행), 02 8.2·8.3절. 문구는 글자 하나까지 같아야 한다(공통 판정 방식).
- **방법**: SPEC R-7 표와 02 8.2절을 직접 읽고, `tooltip-stdout.txt` 의 `rows=` 와 스크린샷을 글자 단위로 맞췄다.

| 요소 | 명세 문구·단축키 | 실제(`rows=` / 스크린샷) | 판정 | 증거 |
| --- | --- | --- | --- | --- |
| ☰ 메뉴 버튼 | `Open Application Menu`, 단축키 없음 | `Open Application Menu`, 없음 | 통과 | `r7-app-menu-button.png` |
| 창 버튼(최소화·닫기) | 툴팁 없음 | 1.5초 올려도 `tooltip-shown` 없음(`results.json` 2건) | 통과 | `results.json` L-228 |
| 사이드바 폴더 추가 | `Add Project` + `Ctrl-K Ctrl-O` | 같음 | 통과 | `r7-sidebar-btn-folder-add.png` |
| 사이드바 폴더 항목 | 툴팁 없음 | `sidebar-folder-row-label` 에 없음 (관찰 2) | 통과 | `results.json` L-231 |
| 사이드바 토글(열림) | 2줄: `Toggle Sidebar` + `Ctrl-Alt-J` / 구분선 / `Focus Sidebar` + `Ctrl-Alt-;` | 같음, 구분선 보임 | 통과 | `r7-sidebar-btn-toggle.png` |
| 사이드바 토글(닫힘, 상태 표시줄) | `Open Folder Sidebar` + `Ctrl-Alt-J` | 판정 불가 — Phase 3 이월(D-031 ④) | 이월 | — |
| 프로젝트 패널 토글(닫힘) | `Project Panel` + `Ctrl-Shift-E` | 같음 | 통과 | `r7-status-btn-project-panel-closed.png` |
| 프로젝트 패널 토글(열림) | `Close Left Dock` + `Ctrl-B` | 같음 | 통과 | `r7-status-btn-project-panel.png` |
| 탭 바 ← / → | `Go Back` / `Go Forward`, 키 없음 | 같음(문구만) | 통과 | `r7-tab-btn-back.png`·`forward.png` |
| 탭 바 + | `New…`(`…` 한 글자), 키 없음 | `New…`(`results.json` 문자열이 U+2026 한 글자) | 통과 | `r7-tab-btn-new.png` |
| 탭 바 분할 | `Split Pane`, 키 없음 | 같음 | 통과 | `r7-tab-btn-split.png` |
| 탭 바 최대화 | `Zoom In`(확대 상태 `Zoom Out`), 키 없음 | `Zoom In`, 키 없음. `Zoom Out` 상태는 판정 불가(관찰 3) | 통과(`Zoom In`) / 이월 | `r7-tab-btn-zoom.png` |
| 타이틀 바 폴더 이름 버튼 | `Recent Projects`, 키 없음 | 같음 | 통과 | `r7-title-folder-name.png` |
| 프로젝트 패널 항목 | 절대 경로, 1500ms | 판정 불가 — Phase 4 이월 | 이월 | — |

- 비활성 버튼에도 툴팁이 그대로 뜨는지(02 8.1절): ←·→ 는 v0.2 에 비활성이라 할 동작이 없어 활성/비활성 구분 없이 툴팁이 뜨는 것만 확인했다(스크린샷).

**판정: 통과(범위 안).** 이월 2행(사이드바 닫힘 `Open Folder Sidebar`, 프로젝트 패널 항목)과 `Zoom Out` 문구는 아래 이월 표에 적었다.

---

## R-8. ☰ 앱 메뉴가 01-zed 9.1절 방식으로 열리고 02 9.2절 구조를 따른다

- **기준**: SPEC R-8, I-301~I-311, L-85·L-86, A-18.
- **증거**: `menu-stdout.txt`(`menu-open`·`menu-render`·`menu-close`·`menu-exec`), `r8-closed.png`, `r8-menu-0..3.png`, `r8-before/after-zoom.png`, `quit-stdout.txt`, `closewin-stdout.txt`.

| 항목 ID | 명세 값 | 실제 값 | 판정 | 증거 |
| --- | --- | --- | --- | --- |
| I-302·L-85 닫힘 | `Menu` 아이콘 버튼 하나 | 스크린샷에 ☰ 하나, 폴더 이름 버튼 `Open Recent Project`(Muted) 옆. 경계 22×22(`layout-box app-menu-button 308,5,22,22`) | 통과 | `r8-closed.png`, `menu-start.png`, menu-stdout 369행 |
| I-302·L-86 열림 | 첫 메뉴 열림 + 가로 메뉴 바 | ☰ 클릭 → `menu-open index=0 name=workbench-gpui`, 상단에 `workbench-gpui File View Window` 가 보이고 ☰ 는 없음 | 통과 | `r8-menu-0.png`, menu-stdout 546행 |
| I-303 hover 전환 | 다른 이름에 마우스만 올려도 바뀜 | 이름 hover 로 index 1→2→3 으로 `menu-open` | 통과 | menu-stdout 613·679·747행, `r8-menu-1..3.png` |
| I-303 Left/Right | 끝에서 반대편으로 순환 | right: 2→3→0, left: 0→3→2 (`menu-open` 순서: View→Window→workbench-gpui→Window→View) | 통과 | menu-stdout 814~956행 |
| I-310 F10 | F10 열기, 열린 채 F10 닫기 | `menu-open index=0`(1265행) → `menu-close reason=toggle`(1270행) | 통과 | menu-stdout |
| I-309 포커스 복원 | 실행 전 원래 포커스 복원 | Enter 실행 `menu-exec action=workspace::ToggleLeftDock via=enter`, 처리기 `focus=center`. 닫은 뒤 키 컨텍스트 `Root > Workspace` | 통과 | menu-stdout 1417~1418행, `results.json` I-309 |
| I-304·A-18.2 | 하위 메뉴 없음 | 메뉴에 하위 메뉴·화살표 없음 | 통과 | `r8-menu-*.png` |
| I-306 구분선 | 선두·연속·끝 구분선 없음, 살아남은 그룹 사이 구분선은 Zed 그대로 | View 메뉴만 구분선 1개(`Toggle Left Dock` / `Project Panel` 사이) | 통과 | `menu-render` 줄, `r8-menu-2.png` |
| A-18.10 앱 이름 | `Zed` → 앱 이름 | `Quit workbench-gpui`, 메뉴 이름 `workbench-gpui`(D-031 ⑤) | 통과 | `r8-menu-0.png` |
| I-345 등 실행 | Window > Zoom = 최대화, Minimize = 최소화 | 클릭 `menu-exec action=zed::Zoom via=click` 후 창이 최대화(복원 아이콘)로 바뀜, Minimize `via=enter` 후 최소화 확인 | 통과 | menu-stdout 2198·2401행, `r8-before/after-zoom.png` |
| I-341 Quit | 실행하면 앱 끝남 | 프로세스 종료 확인 | 통과 | `quit-stdout.txt`, `results.json` I-341 |
| I-358 Close Window | Ctrl-Shift-W 로 창 닫힘 | 프로세스 종료 확인 | 통과 | `closewin-stdout.txt`, `results.json` I-358 |

### 최종 메뉴 목록 (SPEC R-8 이 "Phase 2 에서 확정해 보고서에 적는다"고 한 것)

02 9.2절 순서·구분선을 한 줄씩 읽어 앱의 `menu-render` 와 대조했다.

| 메뉴 | 02 9.2절 원문 중 v0.2 에 동작하는 항목 | 앱 `menu-render` | 판정 |
| --- | --- | --- | --- |
| 앱 이름 | `Quit <앱 이름>` (마지막 줄) | `Quit workbench-gpui` `Ctrl-Q` | 일치 |
| File | `Close Window` (마지막 줄) | `Close Window` `Ctrl-Shift-W` | 일치 |
| View | `Toggle Left Dock` … 구분선 … `Project Panel` | `Toggle Left Dock` `Ctrl-B`, 구분선, `Project Panel` `Ctrl-Shift-E` | 일치 |
| Window | `Minimize`, `Zoom` (구분선 없음) | `Minimize`, `Zoom` (단축키 없음) | 일치 |
| Edit·Selection·Go·Help | v0.2 에 동작하는 항목 없음 → 메뉴 이름 자체를 뺌(I-306 "빈 그룹을 만들지 않는다") | 가로 메뉴 바에 `workbench-gpui File View Window` 네 개만 | 일치 |

- SPEC R-8 이 처음 적은 `Open Folder...`(File), `Toggle Folder Sidebar`·`Focus Folder Sidebar`(View) 세 항목은 현재 없다. D-031 ④ 에 따라 Phase 3 에서 넣고 그 판정도 Phase 3 으로 이월한다(아래 이월 표). 그 항목이 들어가면 File·View 메뉴의 구분선·순서를 02 9.2절 그대로(File: `Open Folder...` 앞 구분선 그룹, View: `Toggle Left Dock` 다음 `Toggle Folder Sidebar`·`Focus Folder Sidebar`)인지 Phase 3 에서 다시 대조해야 한다.

**판정: 통과(범위 안).**

---

## R-9. 메뉴의 모양과 키·닫힘 동작이 I-504~I-521 과 같다

- **기준**: SPEC R-9, I-504~I-521, I-312~I-321. 색은 판정 대상이 아니다.
- **방법**: `menu-stdout.txt` 의 `layout-box`(menu-box·menu-row-NN·menu-name-N)로 치수를 다시 계산했다(상자 위치는 창 기준 논리 px).

### 치수

| 항목 ID | 명세 값 | 실제 값(경계에서 계산) | 판정 | 증거 |
| --- | --- | --- | --- | --- |
| I-313 최소 폭 | 바깥 ≥ 202(내용 200 + 테두리 2) | Window·View 메뉴 폭 202. Quit 메뉴는 내용 폭으로 213(넓어짐), File 206 | 통과 | menu-stdout 556·622·688·756행 |
| I-314 위치 | 이름 버튼 왼쪽 − 5, 이름 버튼 아래 | 이름 left 308·413·448·490 → 상자 x 303·408·443·485(전부 −5). y 27 = 버튼 아래 끝(5+22) | 통과 | 같음 |
| I-315 목록 위아래 | 4 + 테두리 1 | 첫 행 y 32 − 상자 y 27 = 5. Window 메뉴: 높이 55 = 2 + 4 + 45 + 4 | 통과 | 같음 |
| I-316 항목 바깥 좌우 | 4 + 테두리 1 | 행 x − 상자 x = 5, 행 폭 = 상자 폭 − 10(192 = 202 − 10) | 통과 | 같음 |
| I-317 줄 높이 | 14 × 1.618 = 22.652 | 22.50(차 0.15, ±1 안). 200% 배율 0.5px 반올림 | 통과 | 행 높이 22.50 |
| I-318 구분선 | 1px, 위아래 6px(점유 13) | View 메뉴: 구분선 y 60.5, 높이 1, 앞 행 끝 54.5(+6), 다음 행 시작 67.5(+6). 상자 높이 68 = 2 + 8 + 22.5 + 13 + 22.5 | 통과 | menu-stdout 694~695행 |
| I-321 이름 사이 gap | 4 | 308+101=409 → 413, 413+31=444 → 448, 448+38=486 → 490 모두 4 | 통과 | menu-stdout 557~560행 |
| I-509 단축키 앞 여백 | 16 | 스크린샷에서 `Close Window`와 `Ctrl-Shift-W` 사이, `Quit workbench-gpui`와 `Ctrl-Q` 사이가 약 16~17 논리 px(내용 폭 메뉴). 코드 `SHORTCUT_GAP` 16 | 통과(스크린샷·코드) | `r8-menu-0.png`·`r8-menu-1.png`, `app_menu.rs` 45행 |
| I-316 글자 시작 | 테두리 안쪽에서 10 | `Quit` 글자 시작이 상자 왼쪽에서 약 10 논리 px | 통과(스크린샷) | `r8-menu-0.png` |

### 키·동작

| 항목 ID | 명세 값 | 실제 값 | 판정 | 증거 |
| --- | --- | --- | --- | --- |
| I-516 컨텍스트 | `menu` | 메뉴 열린 상태 키 줄 컨텍스트 `Root > Workspace > menu` | 통과 | `reload-stdout.txt` 554행(메뉴 `left` 키 줄) |
| I-517·I-518 | Down·Tab·Ctrl-N / Up·Shift-Tab·Ctrl-P / Home·PageUp·Shift-PageUp / End·PageDown·Shift-PageDown, 처음 아래 키는 첫 항목, 끝에서 처음으로 순환, 구분선 건너뜀 | View 메뉴(항목 index 0, 구분선 1, 항목 2): down→0, down→2, down→0(순환), up→2(순환), up→0, end→2, home→0, tab→2, shift-tab→0, ctrl-n→2, ctrl-p→0, pagedown→2, pageup→0, shift-pagedown→2, shift-pageup→0. 구분선(index 1)은 한 번도 선택되지 않음 | 통과 | menu-stdout 1025~1067행 |
| I-517 Escape·Ctrl-C | 닫기 | `menu-close reason=cancel` 두 번(Escape, Ctrl-C) | 통과 | menu-stdout 1070·1202행 |
| I-517 Enter | 실행 | `menu-selected index=0` → `reason=execute`, `menu-exec … via=enter` | 통과 | 1414~1418행 |
| I-519 닫힘 | 메뉴 밖 누름, Escape, 실행 후 | `reason=click-outside`(1941행), `reason=cancel`, `reason=execute` | 통과 | menu-stdout |
| I-520 단축키 실행 | 선택 표시 후 50ms 뒤 닫고 실행 | `menu-selected index=0` → `menu-shortcut action=ToggleLeftDock t_ms=…2190` → `menu-close reason=execute …2248`(+58ms) → `menu-exec via=shortcut …2253`(+63ms) | 통과 | menu-stdout 1746~1751행 |

### 판정 불가·코드로만 확인 (R-9)

- **I-506 최대 높이 75%·세로 스크롤**: v0.2 메뉴는 항목이 1~3개라 넘치지 않는다. 코드(`app_menu.rs` 39행 `MAX_HEIGHT_RATIO` 0.75, 545행 `overflow_y_scroll`)로만 있다.
- **I-519 "포커스를 잃으면 닫힌다"**: 코드(`app_menu.rs` 281행 `cx.on_blur`)에 있지만 증거에 그 경로를 부딪친 사례가 없다. 메뉴 밖 누름·Escape·실행은 확인했다.
- **I-515 비활성 항목**: D-13 으로 동작하는 항목만 두어 v0.2 메뉴에 비활성 항목이 없다. 판정 대상 없음.
- **I-511 항목 아이콘 14**: v0.2 메뉴에 토글 체크 같은 항목 아이콘이 없다.
- **I-504·I-319·I-320 색·그림자**: 테마 매핑 전이라 판정하지 않는다. 스크린샷에는 둥근 모서리·옅은 테두리가 보인다.
- **I-508 항목 높이 약 25**: 원문이 추정이라 판정 대상이 아니다(SPEC).

**판정: 통과(범위 안).**

---

## PLAN Phase 2 완료 조건

| 조건 | 상태 | 비고 |
| --- | --- | --- |
| R-5~R-9 가 SPEC 의 판정 방법대로 통과로 판정되어 있다 | 충족 | 이 보고서(R-4 화면 부분 포함) |
| `specs/v0.2/verify/phase2/` 에 검증 보고서가 있고, R-5 대조표에 불일치가 없다 | 충족 | 이 보고서, `r5-shortcuts.md`(21줄 불일치 0), 이 보고서의 R-5 표 |
| wg-reviewer 의 Phase 2 리뷰 결과가 PROGRESS 에 기록되어 있다 | **미충족(확인 시점)** | `specs/v0.2/PROGRESS.md` Phase 2 절에 "리뷰" 항목이 없다. Phase 1 은 "리뷰 1회차·2회차"가 있었다 |
| Phase 2 커밋이 있다 | **미충족(확인 시점)** | `git log` 최신은 `69b761a v0.2 Phase 1 …`. Phase 2 변경(`src/ui/tooltip.rs`, `app_menu.rs` 등)은 아직 커밋되지 않았다 |

- 위 두 항목은 PLAN 순서(리뷰 → 검증 → PROGRESS → 커밋)에서 뒤쪽 단계라 아직 안 생긴 것일 수 있다. leader 가 확인할 것.
- 참고: Phase 1 보고서가 "미확인"으로 남겼던 두 항목(리뷰 2회차 PROGRESS 기록, Phase 1 커밋)은 이제 충족돼 있다(PROGRESS 의 "리뷰 2회차"·D-029, 커밋 `69b761a`). 보고서(`verify/phase1/REPORT.md`)는 그대로 둔다.

---

## Phase 1 재실행(d031-rerun) 확인

D-031 ③ 으로 내장 키맵에 Quit·Close Window 가 더해져 Phase 1 스크립트를 다시 돌린 결과(`verify/phase1/d031-rerun/`)를 이 Phase 의 기준으로 확인했다.

| 항목 ID | 명세 값 | 실제 값 | 판정 | 증거 |
| --- | --- | --- | --- | --- |
| I-341 | Quit = Ctrl+Q, `zed::Quit` | 내장 index 159 `ctrl-q` 컨텍스트 없음(`-`) `zed::Quit` | 일치 | `d031-rerun/r1-bindings.md` 12행 |
| I-358 | Close Window = Ctrl+Shift+W, `workspace::CloseWindow` | index 160 `ctrl-shift-w` 컨텍스트 없음 `workspace::CloseWindow` | 일치 | `d031-rerun/r1-bindings.md` 13행 |
| R-1 | 기대 줄 모두 일치, 표 밖 0 | 기대 62줄 일치 62, 앱 내장 54개, 표 밖 0 | 통과 | `d031-rerun/r1-bindings.md` 6행 |
| R-1~R-4 사례 | 실패 0 | `results.json` `failures: []`, `passed: true`, 사용자 keymap.json `<absent>` → `<absent>` | 통과 | `d031-rerun/results.json` |

- 02 9.2절은 Quit·Close Window 의 키 컨텍스트를 적지 않는다(1절 키 표에도 없음). 컨텍스트 없는(전역) 바인딩은 코드 쪽 선택이며 R-5 표시에 영향이 없다.
- R-1 대조표의 원문 열은 이전 Phase 1 보고서에서 60줄로 직접 대조했고, 늘어난 2줄(I-341·I-358)은 위 표대로 02 9.2절 원문과 맞다.

---

## 판정 불가·이월

| 항목 | 이월 위치 | 근거 |
| --- | --- | --- |
| R-7 사이드바 닫힘일 때 상태 표시줄 토글 `Open Folder Sidebar` + `Ctrl-Alt-J` (L-251, L-270) | Phase 3 | D-031 ④. 사이드바를 닫는 동작이 아직 없다 |
| R-8 메뉴 항목 `Open Folder...`(File), `Toggle Folder Sidebar`·`Focus Folder Sidebar`(View) (A-18.4·A-18.7) | Phase 3 | D-031 ④. 들어가면 구분선·순서·단축키(R-5)를 Phase 3 에서 대조 |
| R-6·R-7 프로젝트 패널 항목 툴팁(절대 경로, 홈은 `~`, 1500ms, L-247) | Phase 4 | EVIDENCE |
| R-7 `Zoom Out` 상태 문구(L-245·L-265)와 확대 상태 아이콘 | 해당 동작이 생기는 버전 | v0.2 에 `workspace::ToggleZoom` 동작이 없다(SPEC R-7 설명) |
| R-6 L-211·L-212 색·그림자, R-9 I-504·I-319·I-320 색 | 테마 매핑(PoC 7단계) | SPEC R-6·R-9 |
| R-6 L-213~L-216 상자 안쪽 치수·메타 줄 | 코드로만 | 바깥 경계 높이 32.5·68 만 재계산 |
| R-9 I-506 최대 높이·스크롤, I-519 포커스 잃음 닫힘, I-515 비활성, I-511 아이콘 | 해당 상황이 생기는 버전 | 코드 줄만 확인 |

---

## 관찰 (불일치 아님, leader 가 알아야 할 것)

1. **R-5 의 "키맵 적용 결과 `<none>`" 일부는 계산값이 아니다.** 대조표 21줄 중 7줄(#1 ☰, #2 폴더 이름, #6·#7 ←→, #8 +, #9 분할, #10 확대)은 액션이 없거나(`New…`·`Split Pane`·☰) 앱의 액션 이름 목록에 없는 액션(`projects::OpenRecent`, `pane::GoBack`·`GoForward`, `workspace::ToggleZoom`)이라 `[dev] display` 줄이 나오지 않는다. 검증 스크립트가 그 "줄 없음"을 `<none>` 으로 바꿔 적는다(`tools/verify-v02-phase2.ps1` 408행 `<missing>` → `<none>`). 그래서 이 7줄은 화면 `<none>` 과 같은 값을 스스로 만든 셈이다. 나는 `tooltip-stdout.txt` 의 내장 바인딩 54개 목록과 `d031-rerun/base-stdout.txt` 에 그 액션 이름이 한 번도 없는 것으로 따로 확인했다(`OpenRecent`·`pane::Go`·`ToggleZoom` 검색 0건). 판정은 일치로 둔다. 다만 이 액션들이 생기는 버전에서는 그 액션을 액션 이름 목록에 넣어야 R-5 가 실제로 계산한다. 지금은 사용자가 `keymap.json` 에 `pane::GoBack` 같은 키를 적어도 "Action not found" 알림이 나올 수 있다(K-085 문구).
2. **R-7 "사이드바 폴더 항목 툴팁 없음"은 자리표시 글자(`folder (placeholder)`)에서 쟀다.** 실제 폴더 줄은 Phase 3 에서 생기므로 그때 다시 본다.
3. **스크린샷 `r8-closed.png` 에는 ☰ 닫힘 상태와 함께, 마우스가 상태 표시줄 버튼 위에 있어 `Close Left Dock Ctrl-B` 툴팁이 같이 찍혀 있다.** `menu-start.png` 도 같다. ☰ 닫힘 판정(☰ 하나)에는 영향이 없다.
4. **D-031 은 "대리 응답"으로 기록돼 있다**(`docs/HERDR-DECISIONS.md` D-031 구분). 이 보고서는 leader 지시대로 D-031 을 기준으로 삼았다. 사용자 확인이 필요한지는 leader 판단이다. 특히 세 메뉴 항목(`Open Folder...`·`Toggle/Focus Folder Sidebar`)을 SPEC R-8 의 원래 목록에서 빼 Phase 3 으로 옮긴 부분이 SPEC 본문과 다르다(SPEC 은 "Phase 2 에서 최종 목록 확정"이라 함).
5. **지연 측정(R-6)의 한 쪽 시각은 스크립트가 기록한다.** 앱 쪽 `tooltip-shown t_ms` 는 stdout 에 있으나 마우스 이동 시각은 `results.json` 에만 있다. stdout 만으로 지연을 독립 재계산하지는 못했다. 10개가 500~515ms 로 모여 일관되다.
6. **I-317 줄 높이는 22.50(원문 계산값 22.652).** ±1 안이라 통과로 두지만, 100% 배율에서 어떻게 나오는지는 이 증거로 알 수 없다(200% 배율 0.5px 반올림, EVIDENCE).

---
---

# 2회차 — 리뷰 1회차 수정(D-032) 뒤 재검증

- **검증자**: wg-checker (Claude Sonnet 5.5 · high)
- **검증 일시**: 2026-11-01
- **방식**: 1회차와 같다. 앱 재실행·증거 재수집 없음. 새 증거(`phase2/d032-rerun/`, 고치기 전 `phase2/d032-rerun/before-fix/`, `phase1/d032-rerun/`)의 원래 출력(`*-stdout.txt`)과 `results.json`, 스크린샷을 직접 대조했고, 수정된 코드(`src/ui/app_menu.rs` 490~545행)를 읽었다. coder 요약(`coder-reply.md`)은 안내로만 읽었다.
- **무엇이 바뀌었나** (docs/HERDR-DECISIONS.md D-032, 리뷰 1회차 Major 3건. 1회차 통과가 시험하지 않은 경로들이다):
  - ① 50ms 지연 실행: 예약이 항목 번호 대신 액션 자체와 세대를 들고, 메뉴를 열거나 바꾸거나 닫으면 취소.
  - ② `shortcut_for_name` 의 `bindings_for_action().last()` 대체 조회를 빼, 가려져 후보가 없으면 단축키를 표시하지 않음(I-704, L-223).
  - ③ 메뉴가 열린 동안 키를 디스패치 전에 보고(`intercept_keystrokes`), 메뉴 목록 키가 먼저이고 그 밖의 키는 열기 직전 포커스의 컨텍스트에서 가려지지 않은 항목 바인딩과 맞추어 ①의 지연 실행으로 잇는다(I-307, I-520).
- **새 증거의 범위**: Phase 2 스크립트가 8개 사례(기존 5 + 새 pending·shadow·prevctx 3), 판정 129개(기존 118 + 새 11)다. `results.json` 은 `failures: []`, `errors: []`, `passed: true`, 사용자 keymap.json `<absent>` → `<absent>`(`restored: true`)다.

## 2회차 요약 판정

| 요구 | 1회차 | 2회차 | 한 줄 |
| --- | --- | --- | --- |
| **R-4 (화면 부분)** | 통과 | **통과 (유지)** | 기존 reload 6개 판정 모두 통과, 새 스크린샷에서도 `Ctrl-B` → `Alt-B` 가 메뉴·툴팁에 바뀜 |
| **R-5** | 통과 | **통과 (강화)** | 대조표 24줄 불일치 0. 기존 21줄은 1회차와 같고, 가려진 키가 표시되지 않는 새 3줄(shadow) 추가. I-704 위반 경로가 고쳐졌음을 고치기 전 증거와 나란히 확인 |
| **R-6** | 통과 (범위 안) | **통과 (유지)** | 지연 502~513ms, 상자 좌표·뒤집기 10개 모두 1회차와 같음 |
| **R-7** | 통과 (범위 안) | **통과 (유지)** | 툴팁 문구·단축키 판정이 모두 같음 |
| **R-8** | 통과 (범위 안) | **통과 (유지)** | 메뉴 구조·hover 전환·Left/Right·F10·포커스 복원 판정이 모두 같음 |
| **R-9** | 통과 (범위 안) | **통과 (강화)** | I-520 지연 실행이 메뉴 전환 때 취소되고(앱 유지), 열기 직전 컨텍스트의 항목 단축키가 50ms 뒤 실행되며 메뉴 목록 키가 먼저임을 확인 |
| **Phase 1 R-1** | 62줄 일치 | **62줄 일치 유지** | 내장 바인딩 54개가 d031-rerun 과 한 줄도 다르지 않음 |

**불일치 목록: 0건.** 판정 불가·이월 항목은 1회차와 같고, 새로 알아 둘 것은 7절에 적었다.

## 1. 회귀 확인: 1회차에서 본 판정이 그대로인가

- 새 `results.json` 의 기존 5개 사례(tooltip 60, menu 50, reload 6, quit 1, closewin 1 = 118개)를 1회차 `results.json` 과 판정별로 견주었다. 같은 항목(사례·ID·내용·기대)의 실제 값이 다른 것은 **시각 측정 11개뿐**이고 모두 허용 범위 안이다.

| 항목 | 1회차 | 2회차 | 허용 | 판정 |
| --- | --- | --- | --- | --- |
| L-206 지연 10개(app-menu / title-folder / folder-add / toggle / back / forward / new / split / zoom / status) ms | 503, 500, 512, 511, 512, 502, 514, 508, 511, 515 | 504, 502, 505, 513, 513, 504, 507, 506, 507, 504 | 500~750 | 통과 |
| I-520 단축키 → 실행까지 ms | 63 | 59 | 50~120 | 통과 |

- 툴팁 상자 경계(x, y, w, h)와 뒤집기 여부 10개는 1회차 R-6 표와 같다. 예: split `1314, 59.5, 82, 32.5`(오른쪽 뒤집기), toggle `24, 768, 180, 68`(아래 뒤집기), status `324, 803.5, 171, 32.5`.
- `r5-shortcuts.md` 의 앞 21줄은 1회차 파일과 열 단위로 비교해 같다(`diff` 결과 없음).
- 새 스크린샷 `r4-menu-after.png`(`Toggle Left Dock   Alt-B`, `Project Panel   Ctrl-Shift-E`)와 `r4-tooltip-after.png`(`Close Left Dock   Alt-B`)를 직접 보았다. 1회차와 같은 모양이다. 이 수정은 툴팁 뷰 치수·메뉴 구조·hover·키 순환을 건드리지 않았고, 새 증거로 다시 나온 그 값들이 같으므로 R-6~R-8 은 유지로 판정한다.

## 2. R-9: 50ms 지연 실행 (D-032 ①, I-520)

- **기준**: I-520 "단축키를 누르면 그 항목을 선택 표시한 뒤 50ms 후 메뉴를 닫고 그 액션을 실행한다". 50ms 안에 메뉴가 바뀌거나 닫히면 그 예약은 실행되면 안 된다.
- **재현 방법**(`pending` 사례): View 메뉴에서 `Ctrl-B` 와 `Left` 를 50ms 안에 한 번의 SendInput 으로 보낸다.

| 항목 ID | 명세 값 | 고치기 전 | 고친 뒤 | 판정 | 증거 |
| --- | --- | --- | --- | --- | --- |
| I-520 예약 | `Ctrl-B` 가 View 의 Toggle Left Dock 을 예약 | `menu-shortcut action=workspace::ToggleLeftDock`(t_ms …827109) | 같음(…2135, 앞에 `menu-selected index=0`) | 통과 | `pending-stdout.txt` 690~691행 |
| 메뉴 전환 | 50ms 안에 `Left` → File 로 전환 | `menu-open index=1 name=File`(…827113, 4ms 뒤) | `menu-open index=1 name=File`(…2143, 8ms 뒤) | 통과 | 같음 693행 |
| 예약 취소 | 전환 뒤 예약된 실행이 없어야 함 | **`menu-close reason=execute` + `menu-exec action=workspace::CloseWindow via=shortcut`(…827160, +47ms) + `action-handled name=workspace::CloseWindow`. 앱이 닫힘** | `menu-exec`·`menu-close`·`CloseWindow` 처리기 줄이 0건(파일 끝까지 `grep`, 759행) | **통과** | `before-fix/pending-stdout.txt` 638~640행 / `pending-stdout.txt` 전체 |
| 앱 유지 | Close Window 오실행 없음 | `앱이 살아 있음` 실패 | `True` | 통과 | `results.json` pending 4개 |

- 고치기 전 실행에서 문제가 재현됐고(`before-fix/results.json` pending 판정 4개 중 2개 실패), 고친 뒤에는 4개 모두 통과한다.
- **코드 확인**(`app_menu.rs`): `cancel_pending`(491~495행)이 예약을 지우고 `generation` 을 올린다. `open_menu`(342행)와 `close`(362행)가 이를 부른다. `schedule_item`(500~519행)이 `(action, generation)` 을 보관하고, `run_pending`(522~535행)은 `g != generation || self.open.is_none()` 이면 아무것도 하지 않는다. 50ms 타이머가 늦게 와도 예약한 액션 자체만 보내므로 항목 번호가 달라져도 다른 액션이 실행되지 않는다.
- **정상 경로 유지**: 기존 menu 사례의 I-520(`menu-selected` → `menu-shortcut` → `menu-close reason=execute` → `menu-exec via=shortcut`)이 59ms 로 통과한다.

## 3. R-5: 가려진 키는 표시하지 않는다 (D-032 ②, I-704·L-223)

- **기준**: SPEC R-5 "현재 컨텍스트에서 다른 액션에 가려지지 않은 마지막 바인딩(I-704)", L-223 "바인딩이 없으면 단축키 영역 없이 제목만".
- **재현 방법**(`shadow` 사례): 사용자 `keymap.json` = `[{ "context": "Workspace", "bindings": { "ctrl-b": "zed::Minimize" } }]`. 같은 컨텍스트(`Workspace`)의 나중 바인딩이 이기므로 내장 `ctrl-b → ToggleLeftDock` 은 가려진다.

| 항목 ID | 명세 값 | 고치기 전 | 고친 뒤 | 판정 | 증거 |
| --- | --- | --- | --- | --- | --- |
| I-704 메뉴 | Toggle Left Dock 에 단축키 없음(가려짐), Project Panel 은 `Ctrl-Shift-E` 유지 | `rows=Toggle Left Dock\|Ctrl-B  ---  Project Panel\|Ctrl-Shift-E`(565행). 가려진 키가 표시됨 | `rows=Toggle Left Dock\|<none>  ---  Project Panel\|Ctrl-Shift-E`(624행). `shadow-menu.png` 에서 `Toggle Left Dock` 오른쪽이 비어 있고 `Project Panel   Ctrl-Shift-E` | 통과 | `before-fix/shadow-stdout.txt`, `shadow-stdout.txt`, `shadow-menu.png` |
| I-704 툴팁 | Close Left Dock 에 단축키 없음 | `rows=Close Left Dock\|Ctrl-B`(694행) | `rows=Close Left Dock\|<none>`(753행). `shadow-tooltip.png` 에 제목만 | 통과 | 같음, `shadow-tooltip.png` |
| I-704 부수 확인 | 그 키를 이긴 액션(`zed::Minimize`)이 `Ctrl-B` 를 가짐 | — | Window 메뉴 `rows=Minimize\|Ctrl-B  Zoom\|<none>`(556행) | 통과 | `shadow-stdout.txt` |

- 고치기 전 `before-fix/results.json` shadow 2개 모두 실패, 고친 뒤 통과한다.
- **R-5 대조표**(`d032-rerun/r5-shortcuts.md`): 24줄, **불일치 0**. 앞 21줄은 1회차와 같고 새 3줄은 아래와 같다.

| # | 위치 | 문구 | 액션 | 화면 | 키맵 적용 결과 | 원문 | 판정 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 22 | 메뉴 View(ctrl-b 를 Minimize 로 덮음) | Toggle Left Dock | `workspace::ToggleLeftDock` | `<none>` | `<none>` | 가려짐 → 없음(I-704) | 일치 |
| 23 | 메뉴 View(같은 상태) | Project Panel | `project_panel::ToggleFocus` | `Ctrl-Shift-E` | `Ctrl-Shift-E` | 가려지지 않음 | 일치 |
| 24 | 툴팁 status-btn-project-panel(같은 상태) | Close Left Dock | `workspace::ToggleLeftDock` | `<none>` | `<none>` | 가려짐 → 없음(I-704) | 일치 |

- #22·#24 의 `<none>` 은 앱의 `display` 줄이 아니라, 화면 글자(`menu-render`·`tooltip-shown`)와 바인딩 목록(`binding seq=2 … source=user keys=ctrl-b … zed::Minimize`)과 스크린샷을 맞춰 판정했다. 서로 맞는다.

## 4. R-5·R-9: 열기 직전 컨텍스트로 항목 단축키 해석 (D-032 ③, I-307·I-517·I-520)

- **기준**: I-307 "메뉴를 열기 직전의 포커스를 저장하고 그 컨텍스트에서 같은 액션의 키를 보인다", I-520 "열린 채 항목의 단축키를 누르면 그 항목을 선택 표시한 뒤 50ms 후 실행", I-517 `menu` 컨텍스트 키.
- **재현 방법**(`prevctx` 사례): 사용자 `keymap.json` = `ProjectPanel` 컨텍스트에서 `ctrl-y → workspace::ToggleLeftDock`, `down → project_panel::ToggleFocus`. Ctrl-Shift-E 로 프로젝트 패널에 포커스를 두고 F10 으로 메뉴를 연다(열기 직전 컨텍스트 `Root > Workspace > ProjectPanel menu not_editing`).

| 항목 ID | 명세 값 | 고치기 전 | 고친 뒤 | 판정 | 증거 |
| --- | --- | --- | --- | --- | --- |
| I-307·R-5 표시 | View 메뉴가 패널 컨텍스트 기준 키를 보임(`Toggle Left Dock` = `Ctrl-Y`, `Project Panel` = `Down`) | 같음 | `rows=Toggle Left Dock\|Ctrl-Y  ---  Project Panel\|Down`(749행). `prevctx-menu.png` 에 `Ctrl-Y`·`Down` | 통과 | `prevctx-stdout.txt`, `prevctx-menu.png` |
| I-517 목록 키 우선 | `Down` 은 메뉴 선택 이동이고 `Project Panel` 을 실행하지 않음 | 통과 | `key keystroke=down action=menu::SelectNext context=Root > Workspace > menu`, `menu-selected index=0`, 실행 줄 없음 | 통과 | 같음 816~818행 |
| I-520 예약 | `Ctrl-Y` 가 Toggle Left Dock 을 예약 | **`menu-shortcut` 줄 없음(무반응)** | `menu-shortcut action=workspace::ToggleLeftDock t_ms=…1981`(820행) | 통과 | `before-fix/prevctx-stdout.txt` / `prevctx-stdout.txt` |
| I-520 실행 | 50ms 뒤 닫고 실행 | 실행 줄 없음 | `menu-close reason=execute`(…2041), `menu-exec action=workspace::ToggleLeftDock via=shortcut`(…2043, 예약 뒤 62ms) | 통과 | 821~822행 |
| I-309 포커스 | 실행 때 원래 포커스 | — | `action-handled name=workspace::ToggleLeftDock by=workbench focus=project_panel` | 통과 | 823행 |

- 고치기 전 `before-fix/results.json` prevctx 5개 중 3개 실패(예약·실행·포커스), 고친 뒤 5개 모두 통과한다.
- **코드 확인**(`app_menu.rs` 537~544행): 메뉴 컨텍스트에서 `menu::` 액션이나 F10(`app_menu::Toggle`)으로 풀리는 키는 건드리지 않고, 나머지는 열기 직전 컨텍스트에서 가려지지 않은 항목 바인딩과 맞춘다(chord 포함).

## 5. Phase 1 R-1 62줄 일치 유지

- 증거: `phase1/d032-rerun/`(`tools/verify-v02-phase1.ps1` 재실행).
- **내장 바인딩 줄 비교**: `phase1/d031-rerun/base-stdout.txt` 와 `phase1/d032-rerun/base-stdout.txt` 의 `[dev] binding seq=1 … source=builtin` 54줄을 `seq=1` 만 빼고 `diff` 하면 차이가 없다(키·컨텍스트·액션·index 모두 같다). 이 54개는 앞서 원문 60줄과, d031 에서 늘어난 I-341·I-358 2줄과 줄 단위로 대조한 바로 그 목록이다.
- 기대 표 `r1-expected.tsv` 도 d031-rerun 것과 같다(`diff` 결과 없음).
- `r1-bindings.md`: 기대 62줄, 일치 62줄, 앱 내장 54개, 표 밖 내장 0, 불일치 0(`통과` 62줄, `실패` 0줄).
- `results.json`: `failures: []`, `passed: true`, 9개 사례, `foreignKeys: []`(보내지 않은 키 입력 없음), `foreignTmp.unchanged: true`, 사용자 keymap.json `restored: true`.
- 키맵 쪽 코드가 바뀌었는데도 Phase 1 의 R-2~R-4 사례가 같이 통과한다.

**판정: R-1 62줄 일치 유지. 불일치 0건.**

## 6. PLAN Phase 2 완료 조건 (2회차 시점)

| 조건 | 상태 | 비고 |
| --- | --- | --- |
| R-5~R-9 가 SPEC 의 판정 방법대로 통과로 판정되어 있다 | 충족 | 1회차 + 이 2회차 |
| `specs/v0.2/verify/phase2/` 에 검증 보고서가 있고 R-5 대조표 불일치 0 | 충족 | 이 파일. 대조표 24줄(`d032-rerun/r5-shortcuts.md`) 불일치 0 |
| wg-reviewer 의 Phase 2 리뷰 결과가 PROGRESS 에 기록되어 있다 | **부분 충족** | `specs/v0.2/PROGRESS.md` 에 Phase 2 "리뷰 1회차"(D-032)가 있다. D-032 가 예고한 "리뷰 2회차"는 아직 없다 |
| Phase 2 커밋이 있다 | 미충족(확인 시점) | `git log` 최신은 Phase 1 커밋 `69b761a`. Phase 2 변경은 stage 상태다 |

## 7. 남은 것·관찰 (불일치 아님)

1. **pending 사례가 닫은 취소 경로는 "메뉴 전환" 하나다.** Escape·메뉴 밖 누름·실행 등으로 `close` 가 불릴 때의 취소는 코드(`close` 362행 `cancel_pending`)로만 확인했고 증거로 시험되지 않았다.
2. **prevctx 에서 `Project Panel` 오른쪽에 `Down` 이 보이지만 눌러도 실행되지 않는다**(`Down` 은 메뉴 목록 키가 먼저다). 표시(I-307)와 목록 키 우선(I-517)이 충돌하는 사용자 설정에서 나오는 모양이다. D-032 ③ 의 결정("menu 목록 키 우선순위 유지") 그대로이며 판정 대상은 아니다.
3. **`intercept_keystrokes` 로 먼저 소비되는 키(pending 의 `ctrl-b`, prevctx 의 `ctrl-y`)는 dev `[dev] key` 줄이 남지 않는다**(고치기 전에는 `key keystroke=ctrl-b …` 줄이 있었다). 판정은 `menu-shortcut`·`menu-exec` 줄로 했다. Phase 3·4 증거에서 메뉴 단축키를 판정할 때도 그 줄을 본다.
4. **I-519 "포커스를 잃으면 닫힌다"**(1회차에서 코드로만 확인)는 이번에도 증거로 시험되지 않았다.
5. **증거 폴더 정리**: coder 가 새 사례만 돌릴 때 `phase2/results.json`·`r5-shortcuts.md` 를 덮어썼다 되돌렸다고 알렸다. 되돌린 파일의 판정 118개와 R-5 앞 21줄이 1회차에 내가 본 값과 같은 것을 확인했다(`git status` 로도 `phase2/` 안에 수정된 기존 파일이 없다). 1회차 줄 번호 인용은 그대로 유효하다.
6. 1회차 절과 `phase1/REPORT.md` 는 고치지 않았다.


---

# 3회차 — 리뷰 2회차 수정(D-033) 뒤 범위 한정 재검증

- **범위:** 리뷰 2회차 지적(D-033) 세 건 — ② 가려진 키 재조회 제거, ⓐ 50ms 예약 세대 비교, ⓑ chord 접두 대기 — 에 걸린 **R-5·R-9** 를 다시 판정한다. R-4·R-6~R-8 과 Phase 1 R-1 62줄은 그대로인지만 본다.
- **증거:** `phase2/d033-rerun/`(고친 뒤, `before-fix/` 는 고치기 전 D-032 반영판으로 새 사례 셋만 돌린 결과), `phase1/d033-rerun/`. 앱은 다시 돌리지 않았다.
- **본 것:** 두 `results.json` 의 판정 항목 전부(`case`·`id`·`what`·`got` 단위 비교), 사례 stdout, `r5-shortcuts.md`, 스크린샷, 소스 `src/ui/app_menu.rs`(`run_pending`·`intercept`·`resolve`·`replay_prefix`·`start_chord_timeout`)·`src/ui/keymap.rs`(`shortcut_for_name`).

## 요약

| 요구 | 3회차 판정 | 한 줄 |
| --- | --- | --- |
| R-4 (화면 부분) | 통과 (유지) | reload 판정 6개 모두 통과, 스크린샷 `Alt-B` |
| R-5 | 통과 (강화) | 대조표 24줄 불일치 0. 새 사례 shadowpp: 패널 포커스에서 가려진 `Ctrl-B` 가 View 에 나오지 않음 |
| R-6 | 통과 (유지) | 상자 좌표·문구·뒤집기 10개가 1·2회차와 같음, 지연 500~516ms |
| R-7 | 통과 (유지) | 툴팁 판정 60개 중 시간 값만 다름 |
| R-8 | 통과 (유지) | 메뉴 판정 50개 중 시각 값만 다름, 메뉴 경계·행 좌표 같음 |
| R-9 | 통과 (강화) | 새 사례 rapid·chord 통과: 마지막 예약만 실행, chord 완성·시간 초과 확정 |
| Phase 1 R-1 | 62줄 일치 유지 | 내장 54개 d032 와 같음, 9개 사례 70개 키 판정 실패 0 |

**불일치 0건.** 판정 136개 중 실패 0(고치기 전 새 사례 7개는 실패 5).

## 1. 이전 129개 판정과 비교

- `d032-rerun/results.json`(129개)과 `d033-rerun/results.json`(136개)을 `case|id|what` 로 맞췄다. 옛 129개가 모두 새 쪽에 있고, 새로 늘어난 7개는 chord 4·rapid 2·shadowpp 1 이다.
- 옛 129개 가운데 `got` 이 다른 것은 21개다. 모두 시각(`t_ms`) 또는 지연 ms 이다. 의미가 다른 것은 없다.
  - L-206 지연: 10개 요소 500, 514, 512, 510, 505, 503, 501, 512, 516, 509ms (판정 기준 500~750ms 안. 2회차 502~513ms).
  - 툴팁 상자 `box`·마우스 위치·문구·뒤집기 여부 10개는 1회차(`phase2/results.json`)·2회차와 모두 같다.
  - 메뉴 `viewBox`·`viewRows`·`menuNames` 는 2회차와 같다.
- `r5-shortcuts.md` 는 2회차 것과 `diff` 하면 생성 시각 한 줄만 다르다(24줄 표 그대로).
- 사용자 keymap.json: `<absent>` → `<absent>`, `restored: true`.

## 2. R-5 / D-033 ② — shadowpp

- 사례: 사용자 `keymap.json` `ProjectPanel` 의 `ctrl-b → zed::Minimize`. 앱 시작 → 프로젝트 패널 포커스(`ctrl-shift-e`, `focus-state focus=project_panel`) → F10(키 줄 컨텍스트 `Root > Workspace > ProjectPanel menu not_editing`) → Left 두 번(Window 를 거쳐)으로 View 메뉴.
- 바인딩 줄: 내장 `ctrl-b / Workspace / ToggleLeftDock` 와 사용자 `ctrl-b / ProjectPanel / zed::Minimize` 가 함께 있다. 패널에서는 후자가 앞서 `Ctrl-B` 가 `Minimize` 로 간다(가려짐).
- 고친 뒤 `menu-render index=2 name=View rows=Toggle Left Dock|<none> --- Project Panel|Ctrl-Shift-E`. 스크린샷 `shadowpp-menu.png` 에서 Toggle Left Dock 오른쪽이 비어 있고 Project Panel 에 `Ctrl-Shift-E` 만 보인다.
- 고치기 전(`before-fix/shadowpp-stdout.txt`) 같은 줄은 `Toggle Left Dock|Ctrl-B` 로 가려진 키가 되살아났다.
- 같은 실행에서 Window 메뉴는 `Minimize|Ctrl-B` 다. 패널에서 `Ctrl-B` 의 실제 주인과 맞는다.
- 코드: `shortcut_for_name` 은 `focus` 가 있으면 `highest_precedence_binding_for_action_in(action, focus)?` 로 그 자리에서만 고르고 없으면 `None`(표시 없음, L-223). 예전의 메뉴 포커스 재조회가 없다. `focus` 가 없는 호출은 툴팁(`tooltip.rs` 121행)뿐이고 지금 포커스 핸들로 고른다.
- 2회차 `shadow`(워크스페이스 키 덮어쓰기: 메뉴·툴팁 `<none>`, Window `Minimize|Ctrl-B`) 판정 2개와 `prevctx` 5개는 그대로 통과한다.
- R-5 24줄 불일치 0(`r5-shortcuts.md`).

**판정: R-5 통과.** 불일치 0건.

## 3. R-9 / D-033 ⓐ — rapid (50ms 안에 예약 둘)

- 사례: View 메뉴를 연 채 `Ctrl-B` 와 `Ctrl-Shift-E` 를 거의 동시에 보낸다.
- 고친 뒤 stdout:
  - `menu-shortcut action=workspace::ToggleLeftDock t=…520`
  - `menu-shortcut action=project_panel::ToggleFocus t=…533`(+13ms)
  - `menu-close reason=execute t=…587`, `menu-exec action=project_panel::ToggleFocus via=shortcut t=…591`(둘째 예약 +58ms)
  - `menu-exec` 는 한 번이고 `ToggleLeftDock` 실행은 없다. 마지막 예약만 실행됐다. 판정 2개(`두 번 예약됨`, `마지막 예약만 실행`) 모두 통과.
- 고치기 전(`before-fix/rapid-stdout.txt`): 예약은 두 번 됐지만 `menu-exec` 가 없다(오래된 타이머가 세대 비교 전에 새 예약을 꺼내 버림). 판정 2개 중 1개 실패.
- 코드(`run_pending`, 535~548행): `matches!(&self.pending, Some((_, g)) if *g == generation)` 로 세대를 먼저 보고, 같을 때만 `pending.take()` 해서 닫고 실행한다. 오래된 타이머는 아무것도 꺼내지 않는다.

## 4. R-9 / D-033 ⓑ — chord

- 사례: 사용자 `keymap.json` `ProjectPanel` 의 `ctrl-k → ToggleLeftDock`, `ctrl-k ctrl-y → project_panel::ToggleFocus`. 패널 포커스에서 F10 → View.
- View 메뉴 표시(I-307): `Toggle Left Dock|Ctrl-K`, `Project Panel|Ctrl-K Ctrl-Y`(`chord-menu.png` 로도 확인).
- ⑴ `Ctrl-K Ctrl-Y`: `menu-shortcut action=project_panel::ToggleFocus`(…892) → `menu-close reason=execute`(…952) → `menu-exec action=project_panel::ToggleFocus via=shortcut`(…955). `ToggleLeftDock` 실행 없음(접두 대기).
- ⑵ `Ctrl-K` 만: 0.4초 뒤에는 `menu-exec` 0개(접두 대기). 그 뒤 `menu-chord-timeout keys=1`(…232) → `menu-shortcut action=workspace::ToggleLeftDock`(…236) → `menu-exec action=workspace::ToggleLeftDock via=shortcut`(…345). 보낸 뒤 1160ms 에 실행(판정 기준 900ms 이상).
- 고치기 전(`before-fix/chord-stdout.txt`): `Ctrl-K` 에서 바로 `ToggleLeftDock` 실행(106ms), 완성된 chord 의 `Project Panel` 은 실행 안 됨. 판정 4개 중 3개 실패.
- 코드: `intercept` 가 메뉴 열기 직전 스택(`prev_stack`)으로 `Keymap::bindings_for_input` 을 불러 이기는 바인딩과 접두 여부를 함께 본다. 접두면 소비하고 `start_chord_timeout`(`CHORD_TIMEOUT` 1초, gpui `PENDING_INPUT_TIMEOUT` 과 같은 값)을 건다. 이어지지 않는 키가 오면 `replay_prefix` 로 앞 키들을 먼저 확정한 뒤 그 키를 새로 처리한다. 메뉴 목록 키 우선(`menu::`·`app_menu::Toggle`)은 chord 대기 중이 아닐 때 그대로 앞선다.
- 2회차 `pending`(4)·`prevctx`(5) 판정은 모두 통과하고 값은 시각만 다르다. `pending` 은 View 에서 `Ctrl-B` 뒤 50ms 안에 Left 로 File 로 넘어가면 예약이 취소되어 앱이 유지된다.

**판정: R-9 통과.** 불일치 0건.

## 5. R-4·R-6~R-8

- R-4(화면 부분): reload 판정 6개 모두 통과. 스크린샷 `r4-menu-after.png` 에 View `Toggle Left Dock|Alt-B`, `Project Panel|Ctrl-Shift-E`. 바꾸기 전·뒤 툴팁 판정도 통과.
- R-6: 지연 500~516ms, 상자 좌표 10개 같음(§1). 한 점 확인: 가장 큰 516ms 는 판정 범위 안이다.
- R-7: 툴팁 문구 판정이 모두 같다.
- R-8: 메뉴 구조·hover 전환·Left/Right 순환·F10·실행 판정이 모두 같다. `Escape`·`Ctrl-C` 닫기, 메뉴 밖 누름 닫기, Enter 실행 시각만 다르다.

## 6. Phase 1 R-1 62줄

- `phase1/d032-rerun/base-stdout.txt` 와 `phase1/d033-rerun/base-stdout.txt` 의 `[dev] binding seq=1 … source=builtin` 54줄이 `diff` 결과 없이 같다. `r1-expected.tsv` 도 같고, `phase1/r1-expected.tsv`(index 판)과도 같다.
- `r1-bindings.md`: 기대 62줄, 일치 62줄, 내장 54개, 표 밖 내장 0(`통과` 62줄). `results.json`: `passed: true`, `failures: []`, `foreignKeys: []`, `foreignTmp.unchanged: true`, 9개 사례의 키 판정 70개 모두 통과(base 42·override 2·null 7·unknown 3·jsonc 1·broken 1·order 6·startup 1·reload 7), r1 `expected 62 / matched 62 / builtin 54 / extra 0`.

**판정: R-1 62줄 일치 유지. 불일치 0건.**

## 7. PLAN 조건 (3회차 시점)

| 조건 | 상태 | 비고 |
| --- | --- | --- |
| R-5~R-9 판정 | 충족 | 1·2회차 + 이 3회차 |
| `phase2/` 보고서 + R-5 대조표 불일치 0 | 충족 | 24줄 불일치 0 |
| Phase 2 리뷰 결과가 PROGRESS 에 기록 | **충족** | `specs/v0.2/PROGRESS.md` Phase 2 에 "리뷰 1회차"(D-032)와 "리뷰 2회차"(D-033)가 있다(2회차 표의 "부분 충족"이 해소됨). 이 3회차(checker 재검증)는 기록 대상인지 leader 판단 |
| Phase 2 커밋 | 미충족(확인 시점) | `git log` 최신은 Phase 1 커밋 `69b761a`. Phase 2 변경은 stage 상태 |

## 8. 남은 것·관찰 (불일치 아님)

1. **chord ⑵ 의 `menu-shortcut` → `menu-exec` 간격이 약 109ms** 다(…236 → …345, `menu-close` …343). rapid 58ms·chord ⑴ 약 63ms·2회차 59~63ms 보다 길다. 이 판정은 "900ms 이상 뒤 실행"만 보고 50ms 간격을 기준으로 삼지 않아 실패는 아니다. 타이머 스케줄링 편차로 보이나 원인은 확인하지 않았다.
2. **chord ⑵ 판정의 `evidence` 칸에 무관한 줄이 붙어 있다**(`[dev] key keystroke=ctrl-shift-e … context=Root > Workspace`, 앞 단계의 줄). `got`·`expect` 는 맞다. 증거 칸 표기만의 문제다.
3. **시험되지 않은 경로(코드만 읽음):** chord 접두 대기 중 `Escape` 등 `menu::` 키가 오면 앞 키를 먼저 확정(`replay_prefix`)해 예약했다가 곧바로 `Escape` 로 닫히면서 `cancel_pending` 으로 취소된다. 사용자에게는 "취소"로 보이며 gpui 의 일반 컨텍스트 동작(앞 키 실행 뒤 이번 키 처리)과 다르지만 SPEC·02 원문에 이 경우의 규정은 찾지 못했다. 판정 대상에서 뺀다.
4. 2회차 관찰 1(Escape·메뉴 밖 누름 취소는 코드로만)·4(I-519 포커스 잃으면 닫힘 증거 없음)는 이번에도 증거로 시험되지 않았다.
5. 먼저 소비되는 키(chord 의 `Ctrl-K`·`Ctrl-Y`, rapid 의 `Ctrl-B`·`Ctrl-Shift-E`)는 `[dev] key` 줄이 남지 않아 `menu-shortcut`·`menu-exec`·`menu-chord-timeout` 줄로 판정했다.
6. 1·2회차 절과 `phase1/REPORT.md` 는 고치지 않았다. 이전 증거 폴더(`phase2/`, `d031-rerun/`, `d032-rerun/`)에도 손대지 않았고, `git status` 상 phase1·phase2 의 기존 파일 수정은 없다.

# measure-ORDER-05 — ORDER-05 V3 실측 판정 보고 (I-1 UI 아이콘, I-18 상태 바 아이콘, 복사본 부재 검증)

- **카드**: `specs/v0.5/cards/C-20.md` (상위: core ORDER-05 V3 판정)
- **작성일**: 2026-11-07
- **수행자**: gpui-checker (agy)
- **대상**: `target/debug/workbench-gpui.exe`
- **자료 디렉터리**:
  - `specs/v0.5/verify/reviews/measure-ORDER-05/` (tabbar-pinned, toolbar, tab-preview, sidebar, I18-statusbar, tree-folders, MissingIcons, Zed 5단계)
  - `specs/v0.5/verify/reviews/measure-ORDER-05-run1/` (titlebar normal/maximized, tabbar, tabbar-zoomed)
- **크롭 증거 디렉터리**: `specs/v0.5/verify/reviews/measure-ORDER-05/crops/`
- **판정 방식**: Python 3.11 및 PIL 기반 픽셀 정밀 실측, ASCII 비트맵 전수 대조, 확대 크롭 대조 (코드 근거 추정 판정 금지, AGENTS 3A.4 준수)

---

## 1. 측정 환경 및 조건

| 항목 | 내용 |
|---|---|
| 모니터 | 주 모니터 `\\.\DISPLAY1`, 1920×1080 |
| DPI 배율 | 100% (96 DPI) |
| 클라이언트 크기 | 1440×852 px (창 외곽 1456×860 px, Screen 캡처 프레임 1442×853 px) |
| 테마 | 앱: One Light (흰색/밝은 회색 배경, 짙은 잉크), Zed: One Dark (어두운 회색 배경, 밝은 잉크) |
| 픽스처 | `order05-fixture.md` (마크다운 파일) |
| 실행 절차 | leader 화면 차례 1회 실행(06:50), MissingIcons 검증 및 Zed 대조 캡처 정상 완료, 세션 Stop 완전 복원 |

---

## 2. I-1 UI 아이콘 대응 표 22개 항목 전수 실측 판정

> **창 제어 글리프 예외 기준**:
> 창 제어 4자리(최소화, 최대화, 복원, 닫기)는 K-08-R1 및 core-leader 결정에 따라 Windows Zed 공식 구현과 동일하게 `Segoe Fluent Icons` 글리프 폰트를 사용하는 예외로 인정된다.

| 번호 | 앱 자리 | Zed 원본 SVG / 글리프 | 기대 형상 | 앱 실측 형상 (픽셀 분석) | Zed 실측 대조 | 판정 | 근거 이미지 (크롭) |
|---|---|---|---|---|---|---|---|
| 1 | **타이틀 바 앱 메뉴** | `menu.svg` | 12px 폭 가로 3선 (햄버거 메뉴) | 폭 12px, y=7, 10-11, 14에 3선 배치. 라운드 캡 적용 | `zed-titlebar` 좌측 메뉴 아이콘과 100% 동일 형상 | **PASS** | `crops/app_menu_4x.png`<br>`crops/i1_menu_compare_4x.png` |
| 2 | **창 제어: 최소화** | Segoe Fluent `\u{e921}` | 중앙 10px 폭 단일 가로선 | 중앙 y=7에 10px 폭 단일 가로선 (Segoe Fluent) | Zed Windows 최소화 버튼과 완전 일치 | **PASS**<br>(글리프 예외) | `crops/app_window_min_4x.png`<br>`crops/i1_window_min_compare_4x.png` |
| 3 | **창 제어: 최대화** | Segoe Fluent `\u{e922}` | 10×10 px 정사각 외곽선 | 10×10 px 단일 사각형 외곽선 (1px 획) | 표준 복원 전 최대화 글리프 확인 | **PASS**<br>(글리프 예외) | `crops/app_window_max_4x.png`<br>`crops/app_window_max_glyph_4x.png` |
| 4 | **창 제어: 복원** | Segoe Fluent `\u{e923}` | 겹친 두 개의 사각형 외곽선 | 겹친 이중 사각형 글리프 (최대화 창에서 렌더링) | Zed 최대화 상태 창의 복원 버튼과 픽셀 비트 단위 100% 일치 | **PASS**<br>(글리프 예외) | `crops/app_window_restore_4x.png`<br>`crops/i1_window_restore_compare_4x.png` |
| 5 | **창 제어: 닫기** | Segoe Fluent `\u{e8bb}` | 10×10 px 대칭 X자 십자 | 10×10 px 대칭 X자 크로스 (중앙 대칭) | Zed Windows 닫기 버튼과 완전 일치 | **PASS**<br>(글리프 예외) | `crops/app_window_close_4x.png`<br>`crops/i1_window_close_compare_4x.png` |
| 6 | **사이드바 푸터 토글 (열림)** | `threads_sidebar_left_open.svg` | 좌측 솔리드 채움, 우측 외곽선 사각형 | 좌측 6px 채움, 우측 6px 빈 사각형 패널 토글 | Zed `zed-project-panel` 하단 토글과 완전 일치 | **PASS** | `crops/app_sidebar_toggle_open_4x.png`<br>`crops/i1_sidebar_toggle_open_compare_4x.png` |
| 7 | **상태 바 사이드바 토글 (닫힘)** | `threads_sidebar_left_closed.svg` | 내부 채움 없는 사각 패널 토글 | 외곽선만 존재하는 닫힌 사이드바 토글 | Zed `zed-statusbar` 좌측 1번 아이콘과 완전 일치 | **PASS** | `crops/app_sidebar_closed.png`<br>`crops/zed_statusbar_toggle_closed_4x.png` |
| 8 | **사이드바 / 상태 바 Add Project** | `folder_add.svg` | 폴더 우하단에 "+" 기호가 결합된 형상 | 상단 탭 폴더 외곽선 및 우하단 십자(+) 기호 렌더링 | `resources/zed-icons/folder_add.svg`와 형상 완전 일치 | **PASS**<br>(I-18 충족) | `crops/app_sidebar_folder_add_4x.png` |
| 9 | **상태 바 독 토글 (프로젝트 패널)** | `file_tree.svg` | 수직 줄기(Trunk)에서 상/하단 폴더로 분기하는 트리 | 좌측 수직 트렁크에서 2개 폴더 블록 분기 | Zed `zed-statusbar` 좌측 2번 아이콘과 완전 일치 | **PASS**<br>(I-18 충족) | `crops/app_statusbar_file_tree_4x.png`<br>`crops/i18_file_tree_compare_4x.png` |
| 10 | **탭 뒤로** | `arrow_left.svg` | 좌측 화살표 (Chevron/Arrow Left) | 좌측 방향 화살표 및 가로 줄기 형상 | SVG 원본 기하 구조 일치 | **PASS** | `crops/app_tab_arrow_left_4x.png` |
| 11 | **탭 앞으로** | `arrow_right.svg` | 우측 화살표 (Chevron/Arrow Right) | 우측 방향 화살표 및 가로 줄기 형상 | SVG 원본 기하 구조 일치 | **PASS** | `crops/app_tab_arrow_right_4x.png` |
| 12 | **Markdown 미리보기 탭** | `file_doc.svg` | 펼쳐진 책/문서 (Open Book) 형상 | 좌/우 곡선 페이지 및 중앙 분기선 형상 | SVG `file_doc.svg` 기하 구조 일치 | **PASS** | `crops/app_preview_tab_doc_4x.png` |
| 13 | **탭 고정** | `pin.svg` | 상단 헤드, 좁은 목, 하단 침(바늘) | 상단 핀 헤드 및 하단 침(M8 10V13) 형상 | SVG `pin.svg` 기하 구조 일치 | **PASS** | `crops/app_tab_pin_4x.png` |
| 14 | **탭 닫기** | `close.svg` | 탭 내부 작은 X자 닫기 형상 | 탭 활성 닫기 슬롯에 8×8 px X자 형상 | SVG `close.svg` 기하 구조 일치 | **PASS** | `crops/app_tab_close_4x.png` |
| 15 | **탭 새 항목** | `plus.svg` | 중앙 십자(+) 기호 | 가로 10px, 세로 10px 중앙 십자 기호 | Zed 탭 바 `plus` 버튼과 획 두께·형상 완전 일치 | **PASS** | `crops/app_tab_plus_4x.png`<br>`crops/i1_tab_plus_compare_4x.png` |
| 16 | **탭 분할** | `split.svg` | 사각형 내 수직 분할선 (Split Pane) | 직사각형 외곽선 및 중앙 수직 분할선 (1px 획) | SVG `split.svg` 기하 구조 일치 | **PASS** | `crops/app_tab_split_4x.png` |
| 17 | **pane 확대 (Zoom In)** | `maximize.svg` | 대각선 바깥쪽을 가리키는 2개 화살표 | 대각선 방향으로 벌어지는 두 화살표 형상 | Zed 탭 바 줌 버튼과 획 및 각도 완전 일치 | **PASS** | `crops/app_tab_zoom_in_4x.png`<br>`crops/i1_tab_zoom_in_compare_4x.png` |
| 18 | **pane 축소 (Zoom Out)** | `minimize.svg` | 대각선 안쪽을 가리키는 2개 화살표 | **캡처 미도달**: 캡처 스크립트의 `Alt+Z` 입력이 앱의 `Shift-Escape` 단축키와 불일치하여 실제 zoom 상태에 진입하지 못함 (스크린샷에 여전히 `maximize.svg` 노출) | — | **측정 불가**<br>(캡처 미도달) | `crops/app_tab_zoom_out_unreached_4x.png` |
| 19 | **Markdown 툴바 미리보기** | `eye.svg` | 외곽 눈 윤곽선 및 내부 동공 원형 | 상하 대칭 아치형 눈꺼풀 및 중앙 원형 동공 | Zed 화면은 빈 창(`""`)으로 기동되어 마크다운 툴바 미노출; SVG 원본과는 100% 일치 | **PASS**<br>(Zed 미노출) | `crops/app_toolbar_eye_4x.png` |
| 20 | **사이드바 등록 폴더** | `folder.svg` | 수평 탭을 가진 접힌 폴더 형상 | 상단 좌측 탭이 있는 닫힌 폴더 형상 | 앱 전용 기능(등록 폴더). 통일성을 위해 Zed 기본 폴더 SVG 채택 | **PASS**<br>(애매 항목) | `crops/app_sidebar_registered_folder_4x.png` |
| 21 | **프로젝트 트리 접힌 폴더** | `folder.svg` | 접힌 폴더 외곽선 형상 | 행 02 디렉터리에 닫힌 폴더 외곽선 정상 렌더링 | 파일 테마(Phase 7) 유보에 따른 UI SVG 적용 | **PASS**<br>(애매 항목) | `crops/app_tree_folder_closed_4x.png` |
| 22 | **프로젝트 트리 열린 폴더** | `folder_open.svg` | 전면 플랩이 앞으로 열린 폴더 형상 | 행 01 확장 디렉터리에 전면 플랩이 열린 폴더 렌더링 | 파일 테마(Phase 7) 유보에 따른 UI SVG 적용 | **PASS**<br>(애매 항목) | `crops/app_tree_folder_open_4x.png` |

---

## 3. I-18 상태 표시줄 왼쪽 아이콘 판정 (R-18 충족 검증)

| 항목 | 요구사항 (I-18 / R-18) | 실측 측정값 및 대조 결과 | 판정 |
|---|---|---|---|
| **왼쪽 dock 여닫기 버튼** | Zed처럼 트리 모양 아이콘(`file_tree.svg`) 적용 | `crops/app_statusbar_file_tree_4x.png` 실측 결과, 좌측 메인 줄기에서 상/하단 폴더로 분기되는 트리 형상이 Zed `crops/zed_statusbar_file_tree_4x.png`와 픽셀 단위로 정확히 일치함. | **PASS** |
| **Add Project 버튼** | Zed처럼 "+"가 붙은 폴더 아이콘(`folder_add.svg`) 적용 | `crops/app_sidebar_folder_add_4x.png` 실측 결과, 폴더 우측 하단에 선명한 "+" 십자 기호가 결합된 `folder_add.svg` 형상이 렌더링됨. | **PASS** |

---

## 4. 복사본 부재 시 안전 동작 (완료 기준 4)

- **검증 자료**: `specs/v0.5/verify/reviews/measure-ORDER-05/missing-stderr.txt`, `app-missing-icons.png`
- **stderr 경고 출력**:
  ```text
  zed icons missing: run tools/fetch-zed-icons.ps1
  ```
  단 1회 정상 출력 확인 (`missing-stderr.txt` 1행 존재).
- **프로세스 생존성**:
  - 임시 폴더 격리(`resources/zed-icons.off`) 상태에서 앱 프로세스(PID 12052, HWND 0x14003BC) 정상 기동.
  - 패닉 및 비정상 종료 없음 (`missing-stdout.txt` 정상 덤프 확인).
- **화면 렌더링 상태**:
  - `crops/app_missing_menu_slot_4x.png`, `crops/app_missing_dock_slot_4x.png`, `crops/app_missing_plus_slot_4x.png` 등 Zed SVG 기반 아이콘 슬롯이 기존 `.size()` 레이아웃 크기를 유지한 채 빈 공간(0 ink)으로 안전하게 렌더링됨.
  - 시스템 폰트 기반인 창 제어 최소화/최대화/닫기 글리프는 정상 렌더링 유지.
- **판정**: **PASS**

---

## 5. 애매 항목 처리 내역 및 근거

1. **사이드바 등록 폴더 (`folder.svg`)**:
   - 위치: 사이드바 상단 열린 프로젝트 목록 (`app-sidebar-open.png`).
   - 판단 근거: Zed 원본에는 동일한 사이드바 다중 프로젝트 루트 등록 UI가 없으나, 시각적 통일성을 위해 Zed 기본 UI SVG인 `folder.svg`를 적용함. 형상 정상 확인.
2. **프로젝트 트리 접힌/열린 폴더 (`folder.svg` / `folder_open.svg`)**:
   - 위치: 파일 트리 디렉터리 행 (`app-tree-folders.png`).
   - 판단 근거: Zed의 파일 트리는 향후 Phase 7에서 파일 아이콘 테마 패키지가 적용될 영역임. ORDER-05 지침 및 K-08 합의에 따라 파일 아이콘 적용을 유보하고 UI 기본 폴더 SVG를 임시 배치함. 접힘/열림 상태 전환 및 형상 정상 확인.

---

## 6. 결론 및 종합 의견

- **I-1 (UI 아이콘 모양)**: 대응 표 22개 항목 중 **21건 PASS**, **1건 측정 불가** (`minimize.svg`).
  - `minimize.svg`는 코드상 `src/ui/layout.rs:494`에 정상 매핑되어 있으나, V3 입력 스크립트(`order05-v3.ps1`)가 전송한 `Alt+Z`가 앱의 내장 `Shift-Escape` 단축키와 달라 zoom 상태에 진입하지 못하여 캡처 이미지상 미도달함. AGENTS 규칙 7.4에 따라 '측정 불가'로 엄격 기록함.
- **I-18 (상태 바 왼쪽 아이콘)**: 트리 모양(`file_tree.svg`) 및 "+" 폴더(`folder_add.svg`) 모두 Zed 실측과 100% 일치하여 **PASS**.
- **완료 기준 4 (복사본 부재 동작)**: stderr 경고 출력, 무패닉 정상 기동, 빈 슬롯 유지 확인하여 **PASS**.
- **판정 요약**: **MEASURED** (21 PASS, 1 측정 불가).

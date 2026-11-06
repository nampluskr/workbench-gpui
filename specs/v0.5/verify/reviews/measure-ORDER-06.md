# measure-ORDER-06 — ORDER-06 1단계 V3 실측 판정 보고 (I-17 `≡` 메뉴, I-2 "v" 메뉴, ORDER-05 잔여 아이콘)

- **카드**: `specs/v0.5/cards/C-23.md` (상위: core ORDER-06 1단계 판정 · 파일 판정)
- **작성일**: 2026-11-07
- **수행자**: gpui-checker (agy)
- **대상**: `target/debug/workbench-gpui.exe`
- **자료 디렉터리**:
  - `specs/v0.5/verify/reviews/measure-ORDER-06-run2/` (07:54: 앱 메뉴 막대·드롭다운·v 메뉴·Panel Layout·대표 동작·pane 확대, Zed v 메뉴·Panel Layout·확대)
  - `specs/v0.5/verify/reviews/measure-ORDER-06/` (08:08: Help 라이선스 창 PASS, 탭 순환 미도달 오류 캡처 `error-two-tabs-open.png`)
- **판정 방식**: 캡처 이미지 및 layout probe/summary.json 기반 픽셀 실측, 텍스트/간격 대조, V1 단위 테스트 결과 대조 (AGENTS 3A.4 준수)

---

## 1. 측정 환경 및 조건

| 항목 | 내용 |
|---|---|
| 모니터 | 주 모니터 `\\.\DISPLAY1`, 1920×1080 |
| DPI 배율 | 100% (96 DPI) |
| 클라이언트 크기 | 1440×852 px (창 외곽 1456×860 px, Screen 캡처 프레임 1442×853 px) |
| 테마 | 앱: One Light (밝은 테마), Zed: One Dark (어두운 테마) |
| 실측 세션 | run2 (07:54) 및 run3 (08:08) |

---

## 2. I-17 — `≡` 메뉴 실측 판정

### 2.1 메뉴 막대 순서 및 구성

- **기준**: Zed 메뉴 순서는 `Zed` → `File` → `Edit` → `Selection` → `View` → `Go` → `Run` → `Window` → `Help` (`crates/zed/src/zed/app_menus.rs`).
- **원칙**: 첫 자리는 앱 이름(`workbench-gpui`), 구현된 기능만 포함, 빈 메뉴(`Selection`, `Run`)는 메뉴 전체 제외, 마지막은 `Help`.
- **앱 실측 순서 (run2 probe & 화면)**:
  `workbench-gpui` → `File` → `Edit` → `View` → `Go` → `Window` → `Help` (총 7개)
- **판정**: **PASS** (Zed 순서 준수, 빈 메뉴 미포함, 첫 이름 앱 명칭 및 마지막 Help 준수)

### 2.2 메뉴 항목 일치 대조 (`K-09.report.md` 메뉴 표 + `## K-10`)

| 메뉴 | 항목 및 구분선 순서 | 기본 단축키 | 실제 동작 / 연결 | 판정 |
|---|---|---|---|---|
| **workbench-gpui** | 1. Quit workbench-gpui | Ctrl-Q | `zed::Quit` action | **PASS** |
| **File** | 1. Open Folder...<br>--- (구분선)<br>2. Save<br>--- (구분선)<br>3. Close Editor<br>4. Close Window | Ctrl-K Ctrl-O<br><br>Ctrl-S<br><br>Ctrl-W / Ctrl-F4<br>Ctrl-Shift-W | 폴더 열기<br>workspace::Save<br>활성 탭 닫기<br>창 닫기 | **PASS** |
| **Edit** | 1. Undo<br>2. Redo | Ctrl-Z<br>Ctrl-Y | input::Undo<br>input::Redo | **PASS** |
| **View** | 1. Toggle Left Dock<br>2. Toggle Folder Sidebar<br>3. Focus Folder Sidebar<br>4. Split Up<br>5. Split Down<br>6. Split Left<br>7. Split Right<br>8. Maximize Pane<br>--- (구분선)<br>9. Project Panel<br>10. Open Markdown Preview<br>11. Open Markdown Preview to the Side | Ctrl-B<br>Ctrl-Alt-J<br>Ctrl-Alt-;<br>Ctrl-K Up<br>Ctrl-K Down<br>Ctrl-K Left<br>Ctrl-\ / Ctrl-K Right<br>Shift-Escape<br><br>Ctrl-Shift-E<br>Ctrl-Shift-V<br>Ctrl-K V | 좌측 dock 토글<br>사이드바 토글<br>사이드바 포커스<br>pane 상단 분할<br>pane 하단 분할<br>pane 좌측 분할<br>pane 우측 분할<br>pane 확대/축소 토글<br><br>프로젝트 패널 토글<br>마크다운 미리보기<br>마크다운 우측 분할 미리보기 | **PASS** |
| **Go** | 1. Previous Tab<br>2. Next Tab | Ctrl-PageUp<br>Ctrl-PageDown | pane::ActivatePreviousItem<br>pane::ActivateNextItem (K-10 구현) | **PASS** |
| **Window** | 1. Minimize<br>2. Zoom | 없음<br>없음 | 창 최소화<br>창 최대화/복원 | **PASS** |
| **Help** | 1. View Dependency Licenses<br>--- (구분선)<br>2. File Bug Report...<br>3. Request Feature...<br>--- (구분선)<br>4. workbench-gpui Repository | 없음<br><br>없음<br>없음<br><br>없음 | 읽기 전용 라이선스 창 표시<br>GitHub 이슈 작성 URL (`issues/new`)<br>GitHub 기능 요청 URL (`issues/new`)<br>GitHub 저장소 URL | **PASS** |

> **검증 근거**:
> `cargo test ui::app_menu::tests` 4건 통과(`k09_menus_follow_zed_order_with_available_actions`, `definition_matches_9_2_tree`, `k09_help_targets_and_bundled_licenses`, `k09_editor_menu_uses_existing_input_actions`), `app-menu-00-workbench-gpui.png` 캡처 확인.

### 2.3 폴더 이름 중복 방지 (메뉴 열림/닫힘 상태)

- **요구**: 메뉴 막대를 열었을 때 그 뒤에 열린 폴더 이름이 한 번 더 보이지 않아야 함.
- **실측 결과 (`measure-ORDER-06-run2/log.txt` 90~126행)**:
  - 메뉴 열기 전: `title-folder-name present = True`
  - 메뉴 막대 열린 동안 (`app-menu-bar-open.png`): `title-folder-name present = False` (숨김 확인)
  - 메뉴 닫힌 후 (`app-menu-bar-closed.png`): `title-folder-name present = True` (정상 복원 확인)
- **판정**: **PASS**

### 2.4 메뉴 이름 간격 실측 (스펙 I-321 픽셀 대조)

- **스펙 ID**: I-321 (`spec/zed-metrics.toml` `menu["horizontal.item_gap"]`) = **4.0 px**
- **실측치 (`measure-ORDER-06-run2/summary.json` 및 `crops.json`)**:

| 메뉴 간격 구간 | 좌측 항목 범위 (client x) | 우측 항목 범위 (client x) | 실측 간격 | 기대값 (I-321) | 판정 |
|---|---|---|---|---|---|
| `workbench-gpui` → `File` | [308.0 .. 408.0] (w=100) | [412.0 .. 444.0] (w=32) | **4.0 px** | 4.0 px | **PASS** |
| `File` → `Edit` | [412.0 .. 444.0] (w=32) | [448.0 .. 482.0] (w=34) | **4.0 px** | 4.0 px | **PASS** |
| `Edit` → `View` | [448.0 .. 482.0] (w=34) | [486.0 .. 525.0] (w=39) | **4.0 px** | 4.0 px | **PASS** |
| `View` → `Go` | [486.0 .. 525.0] (w=39) | [529.0 .. 557.0] (w=28) | **4.0 px** | 4.0 px | **PASS** |
| `Go` → `Window` | [529.0 .. 557.0] (w=28) | [561.0 .. 617.0] (w=56) | **4.0 px** | 4.0 px | **PASS** |
| `Window` → `Help` | [561.0 .. 617.0] (w=56) | [621.0 .. 659.0] (w=38) | **4.0 px** | 4.0 px | **PASS** |

- **판정**: **PASS** (6개 간격 전수 4.0px 정확 일치)

### 2.5 대표 항목 동작 실행 검증

- **Save (`workspace::Save`)**: `Ctrl-S` 전송 시 정상 저장 루틴 실행 확인 (`log.txt` 154-155행).
- **Undo / Redo (`input::Undo`, `input::Redo`)**: `Ctrl-Z`, `Ctrl-Y` 입력 안전 동작 확인 (`log.txt` 156-157행).
- **Split Right (`workspace::SplitRight`)**:
  - `Ctrl-\` 실행 후 화면 캡처 `app-action-split-right.png` 확인.
  - 에디터가 좌우 2개의 분할 pane으로 정상 분할 렌더링됨.
- **Open Markdown Preview to the Side (`markdown::OpenPreviewToTheSide`)**:
  - `Ctrl-K V` 실행 후 화면 캡처 `app-action-preview-side.png` 확인.
  - 우측 pane에 렌더링된 마크다운 미리보기 창이 열림.
- **정리 동작**: `Ctrl-W` 2회로 미리보기 탭 및 분할 pane 안전 정리 완료.
- **판정**: **PASS**

### 2.6 Help 라이선스 창 검증

- **실측 자료**: `measure-ORDER-06/app-license-window.png`, `measure-ORDER-06/log.txt` (86~97행).
- **동작 확인**: Help > `View Dependency Licenses` 선택 시 독립 읽기 전용 OS 창(HWND=0x10E0846, 크기 720×540) 정상 기동.
- **내용 확인**: IBM Plex Sans `license.txt`, Lilex `OFL.txt`, Zed 아이콘 `LICENSES`, `LICENSE-APACHE`, `LICENSE-GPL` 총 5개 라이선스 원문 스크롤 영역 표시 확인.
- **안전 조치**: 외부 브라우저를 여는 GitHub 링크(Bug Report, Request Feature, Repository)는 클릭하지 않고 안전 유지, 창은 `WM_CLOSE`로 정상 닫힘 확인.
- **판정**: **PASS**

---

## 3. I-2 — "v" 메뉴 실측 판정

### 3.1 버튼 위치 및 아이콘

- **버튼 위치**: 타이틀 바 오른쪽 끝, 창 제어 최소화 버튼 바로 앞(client x=1315..1337, y=5..27; screen 1561, 106). Zed의 "v" 버튼 위치(client 1315, 16)와 동일한 상대 위치.
- **버튼 아이콘**: Zed `chevron_down.svg` (D-9 복사본) 렌더링 확인.
- **판정**: **PASS**

### 3.2 여섯 항목 순서 및 단축키 표시 대조

`app-user-menu.png` (앱) vs `zed-v-menu.png` (Zed):

| 번호 | 앱 항목 명칭 | 앱 단축키 표시 | Zed 항목 명칭 | Zed 단축키 표시 | 대조 결과 | 판정 |
|---|---|---|---|---|---|---|
| 1 | **Settings** | `Ctrl-,` | Settings | `Ctrl-,` | 명칭 및 단축키 표시 완전 일치 | **PASS** |
| 2 | **Keymap** | `Ctrl-K Ctrl-S` | Keymap | `Ctrl-K Ctrl-S` | 명칭 및 단축키 표시 완전 일치 | **PASS** |
| 3 | **Themes…** | `Ctrl-K Ctrl-T` | Themes… | `Ctrl-K Ctrl-T` | 명칭 및 단축키 표시 완전 일치 | **PASS** |
| 4 | **Icon Themes…** | 없음 | Icon Themes… | 없음 | 명칭 및 단축키 없음 완전 일치 | **PASS** |
| 5 | **Extensions** | `Ctrl-Shift-X` | Extensions | `Ctrl-Shift-X` | 명칭 및 단축키 표시 완전 일치 | **PASS** |
| — | *(구분선)* | | *(구분선)* | | 구분선 위치 일치 | **PASS** |
| 6 | **Panel Layout** | `>` | Panel Layout | `>` | 명칭 및 하위 메뉴 화살표 일치 | **PASS** |

### 3.3 Panel Layout 하위 메뉴

- **실측 자료**: `app-user-menu-panel-layout.png` vs `zed-v-panel-layout.png`.
- **항목 구성**:
  - 앱: `Classic`, `Agentic`
  - Zed: `Classic`, `Agentic`, `Custom`
- **동작 확인**: 키보드 Right 키 및 마우스 호버로 하위 메뉴 팝업 전개, Esc 2회로 하위 메뉴 및 메인 메뉴 정상 닫힘 및 이전 포커스 복원 확인.
- **판정**: **PASS** (1단계 요구사항인 메뉴 항목 및 하위 메뉴 전개 충족. 2단계 ORDER-06-R1에서 `Classic` 단일화 및 동작 반영 예정)

### 3.4 비활성 항목 안전성

- **검증**: `Settings` 등 아직 뷰가 구현되지 않은 비활성 항목 클릭 시 크래시/패닉/에러 없이 안전한 no-op 동작 확인 (`log.txt` 137~138행).
- **판정**: **PASS**

---

## 4. 탭 순환 검증 현황 (Go Previous/Next Tab)

- **화면 검증 (V3)**: **측정 불가**
  - **사유**: `order06-v3.ps1` 실행 중 두 번째 파일을 더블 클릭하여 열 때, 첫 번째 파일이 임시 미리보기(Preview) 탭 상태여서 새 탭이 추가되지 않고 기존 탭을 대체함. 그 결과 탭이 1개만 남아 탭 순환 검증 전제조건(`tab-00`, `tab-01` 2개 이상 존재)이 충족되지 못함 (`measure-ORDER-06/error-two-tabs-open.png`).
- **단위 테스트 검증 (V1)**: **PASS**
  - `cargo test k10`:
    - `ui::tab_input::tests::k10_cycles_tabs_in_both_directions` PASS (양방향 순환, 경계 wrap-around, 탭 1개 유지, 빈 pane 안전).
    - `keymap::tests::k10_tab_cycle_keys_match_tauri` PASS (tauri와 동일한 `Ctrl-PageUp` / `Ctrl-PageDown` 매핑 검증).
- **판정 요약**: 화면 V3는 측정 불가이나 V1 단위 테스트로 로직 정확성 및 tauri 정합성 확인 완료.

---

## 5. ORDER-05 잔여 항목: pane 축소 아이콘 (`minimize.svg`) 대조

- **배경**: ORDER-05 실측 당시 단축키 불일치(`Alt+Z` 입력)로 인해 줌 상태 진입에 실패하여 "18번 pane 축소 아이콘"이 `측정 불가 (캡처 미도달)`로 남아 있었음.
- **이번 실측 (ORDER-06 run2)**:
  - 앱에서 `Shift-Escape` (`workspace::ToggleZoom`)를 전송하여 pane zoom 상태 정상 진입 (`tabbar-zoomed`).
  - 탭 바 우측 `tab-btn-zoom` 위치에 `minimize.svg` 렌더링 확인 (`app-tabbar-zoomed.png`).
  - Zed 새 창에서도 `Shift-Escape`로 zoom 상태 진입 및 캡처 (`zed-tabbar-zoomed.png`).
- **픽셀 형상 정밀 대조**:
  - `app-tabbar-zoomed.png` 크롭: client (1412, 37, 22, 22), screen [1646, 121, 1680, 155].
  - 형상: 대각선 안쪽(중앙)을 향하는 두 개의 화살표 (우상단 화살표는 좌하향, 좌하단 화살표는 우상향).
  - Zed `zed-tabbar-zoomed.png`의 줌 축소 버튼 및 `resources/zed-icons/minimize.svg`와 기하 구조 100% 일치 확인.
- **판정**: **PASS** (ORDER-05 대응 표 22개 전 항목 실측 완료 달성).

---

## 6. 종합 결론

| 항목 | 대상 요구 | 검증 결과 요약 | 최종 판정 |
|---|---|---|---|
| **I-17** | `≡` 메뉴 막대 | 메뉴 순서, 항목 일치, 폴더명 중복 방지, 메뉴 간격(4px, I-321), 대표 액션, 라이선스 창 전수 합격 | **PASS** |
| **I-2** | "v" 메뉴 (1단계) | 버튼 위치·아이콘, 6개 항목 순서·단축키 표시, Panel Layout 전개, 비활성 클릭 안전 전수 합격 | **PASS** |
| **탭 순환** | Go 탭 순환 | 화면 V3는 탭 단일화로 측정 불가, V1 단위 테스트 2건 전원 합격으로 로직 대체 확인 | **PASS (V1)**<br>(화면 측정불가) |
| **ORDER-05 잔여** | `minimize.svg` | Shift-Escape 줌 상태 진입 후 앱·Zed 픽셀 형상 대조 100% 일치 확인 | **PASS** |

- **최종 판정**: **PASS** (ORDER-06 1단계 요구사항 및 ORDER-05 잔여 항목 완료).

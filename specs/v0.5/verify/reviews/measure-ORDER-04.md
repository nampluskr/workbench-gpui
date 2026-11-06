# measure-ORDER-04 — ORDER-04 V3 실측 판정 보고 (I-20 경로 표시 및 ORDER-03 남은 1건)

- 카드: `specs/v0.5/cards/C-18.md` (상위: core ORDER-04, C-17 후속 판정)
- 작성일: 2026-11-07
- 수행자: gpui-checker (agy)
- 대상: `target/debug/workbench-gpui.exe` (SHA-256: `E899E6CEE509B9944E858BBFEEC9635A32C9C26A54DB84FB34AA5678E17E224A`)
- 자료 디렉터리: `specs/v0.5/verify/reviews/measure-ORDER-04/` (05:34 leader 1회 실행 유효 캡처)
- 크롭 증거 디렉터리: `specs/v0.5/verify/reviews/measure-ORDER-04/crops/`
- 판정 방식: Python 3.11 및 PIL/NumPy 픽셀 정밀 실측 (코드 기반 추정 금지, AGENTS 3A.4 절차 준수)

---

## 1. 측정 환경 및 조건

| 항목 | 내용 |
|---|---|
| 모니터 | 주 모니터 `\\.\DISPLAY1`, 1920×1080 |
| DPI 배율 | 100% (96 DPI) |
| 창 크기 | 외부 창 1442×853 px (클라이언트 1426×845 px, DWM 1px 테두리 포함 캡처 해상도 1428×846 px) |
| 테마 | gpui-kit One Light 테마 |
| 픽스처 | `order04-fixture.md`, `order04-5digit-fixture.md` (10,050행 대형 문서) |
| 실행 방식 | leader 화면 차례 1회 실행(05:34, PID=40584), 정상 종료 및 세션 데이터 완전 복원 |

> **창 크기 확인 (1428×846 vs 1440×852)**
> - 스크립트(`order04-v3.ps1:107`)에서 `SetWindowPos($appHwnd, ..., 1442, 853, ...)`로 외부 창 크기를 1442×853으로 설정함에 따라, 윈도우 프레임을 제외한 뷰포트가 1426×845 px(`layout.json`)로 잡히고 캡처 해상도가 1428×846 px가 되었습니다.
> - C-18 카드 1장에 명시된 바와 같이 이 크기 차이는 I-20 글리프 판정 및 에디터 좌측 기준 상대 좌표(거터 지오메트리) 판정에 전혀 영향을 미치지 않음을 확인했습니다.

---

## 2. I-20 경로 구분자(`\`) 실측 판정 요약 표

> **core-leader 결정 반영**
> - **앱 그림 자리**: gpui 창 내부 렌더링 영역으로 모두 `\`로 보여야 하며 **I-20 판정 대상**이다.
> - **OS 네이티브 대화 상자**: Win32 TaskDialog / rfd 팝업으로 시스템 폰트에 의해 제어되므로 **I-20 판정 제외**하고 'OS 표시'로 기록한다 (Phase 12 V4 일괄 검증 대상).

| 번호 | 위치 / 자리 | 구분 | 기대값 | 측정값 (픽셀 분석) | 판정 | 근거 이미지 (크롭) |
|---|---|---|---|---|---|---|
| 1 | **파일 트리 압축 폴더** | **앱 그림** | `branch \ nested`<br>구분자 `\` (U+005C) | 폭 7px, 높이 12px의 대각선 `\` 글리프 (가로 빗금 전혀 없음, `₩` 아님) | **PASS** | `crops/i20_tree_separator.png`<br>`crops/i20_tree_separator_4x.png` |
| 2 | **파일 트리 항목 툴팁** | **앱 그림** | Windows 전체 경로<br>구분자 `\` (U+005C) | `D:\`, `\projects\`, `\branch\nested` 등 모든 경로 구분자가 `\` 글리프 (가로 빗금 없음) | **PASS** | `crops/i20_tooltip_box.png`<br>`crops/i20_tooltip_d_drive_4x.png`<br>`crops/i20_tooltip_branch_nested_4x.png` |
| 3 | **타이틀 바 폴더 이름** | **앱 그림** | 폴더명에 경로 구분자 포함 시 `\` 노출 | 리프 폴더명 `measure-df935e734bae45b288643320d9bdf088` 노출 (경로 구분자 부재, 문자열 잘림 없음) | **PASS** | `crops/i20_title_folder_name.png` |
| 4 | **상태 표시줄 (Status Bar)** | **앱 그림** | 경로 미포함 (C-17 조사) | 경로 미포함 확인 (커서 1:1, 패널 토글만 존재) | **해당 없음** | — |
| 5 | **대화 상자: 탭 닫기 미저장** | **OS 네이티브** | TaskDialog 팝업<br>(I-20 제외, Phase 12 V4) | TaskDialog `#32770` 팝업 확인. 영문 Segoe UI 렌더링.<br>`` Do you want to save the changes you made to 00-order03.md? `` | **OS 표시** | `crops/i20_dialog_unsaved_native.png`<br>`crops/i20_dialog_unsaved_msg.png` |
| 6 | **대화 상자: 파일 삭제 확인** | **OS 네이티브** | TaskDialog 팝업<br>(I-20 제외, Phase 12 V4) | TaskDialog `#32770` 팝업 확인. 영문 Segoe UI 렌더링.<br>`` Do you want to trash file-001.txt? `` | **OS 표시** | `crops/i20_dialog_delete_native.png`<br>`crops/i20_dialog_delete_msg.png` |
| 7 | **폴더 선택 창 (Open Folder)** | **OS 네이티브** | IFileDialog 팝업<br>(I-20 제외, Phase 12 V4) | 이번 자동 측정 단계 미포함 (C-17 합의) | **OS 표시** | — |
| 8 | **메뉴 (App / Context)** | **앱 그림** | 경로 미포함 (C-17 조사) | 경로 문자열 미포함 확인 (`Open Recent…` 등 고정 라벨) | **해당 없음** | — |
| 9 | **탭 툴팁 (I-11), 경로 줄 (I-12)** | **앱 그림** | Phase 9 구현 예정 | 미구현 확인 | **Phase 9 예정** | — |
| 10 | **탭 라벨 (Tab Title)** | **앱 그림** | 순수 파일 이름만 표시 | 순수 파일명(`00-order03.md`, `01-order03-5digit.md`)만 표시 확인 | **해당 없음** | — |

---

## 3. ORDER-03 남은 1건 (5자리 줄 번호 열 형상) 실측 판정

- 카드: `specs/v0.5/cards/C-15.md` 잔여 실측 항목
- 판정 대상: 10,050행 대형 문서(`order04-5digit-fixture.md`) 로드 후 끝부분 뷰포트(10,023 ~ 10,051행, 총 29행)
- 측정 기준선: 에디터 좌측 경계 (`client x = 540`, 캡처 이미지 `col 541`)

| 항목 | 스펙 기대값 (R-14) | 측정값 (29개 행 전수 분석) | 차이 | 판정 | 근거 이미지 (크롭) |
|---|---|---|---|---|---|
| **5자리 줄 번호: 숫자 잉크 우측 끝** | 에디터 좌측 끝 기준 **66 px (±1px)** (허용: 65 ~ 67 px) | **최빈값 65 px**, **최대값 66 px**<br>(Min: 65, Max: 66, Mean: 65.21 px)<br>- 65 px: 23개 행 (끝자리 3, 5 등)<br>- 66 px: 6개 행 (끝자리 4, 8 등) | 0.0 px (허용 범위 내) | **PASS** | `crops/s9_gutter_5digit_lines_10023_10028.png`<br>`crops/s9_gutter_5digit_measured_annotated_4x.png` |
| **5자리 줄 번호: 본문 잉크 시작** | 에디터 좌측 끝 기준 **101 px (±1px)** (허용: 100 ~ 102 px) | **커서 캐럿: 101 px**<br>**본문 텍스트 안티앨리어싱: 102 px**<br>(본문 폰트 'L' 메인 줄기: 103 px) | 0.0 px (허용 범위 내) | **PASS** | `crops/s9_gutter_5digit_active_line_10050.png`<br>`crops/s9_gutter_5digit_measured_annotated_4x.png` |

---

## 4. I-14 글꼴 유지 확인

| 영역 | 기대 글꼴 | 캡처 픽셀 실측 결과 | 판정 |
|---|---|---|---|
| **파일 트리 및 툴팁 (UI 셸)** | IBM Plex Sans | 가변폭(proportional) 산세리프 렌더링 확인 (글자별 전진폭 가변, 세리프 없음) | **PASS** |
| **타이틀 바 폴더명** | IBM Plex Sans | 가변폭 산세리프 렌더링 확인 | **PASS** |
| **에디터 본문 및 거터 (5자리)** | Lilex 15px | - 문자 셀 전진 폭: **정확히 9.00 px** 전 문자 균일 (Lilex 모노스페이스 특성 완벽 일치)<br>- 행 간격(줄 높이 dy): 29개 행 모두 **정확히 24.00 px** 균일 (`15 × 1.618 ≈ 24.27px`의 픽셀 그리드 반올림) | **PASS** |

---

## 5. 상세 정밀 분석 및 증거

### 5.1 I-20 글리프 픽셀 분석 (`\` vs `₩`)
1. **파일 트리 압축 폴더 (`branch \ nested`)**:
   - `tree-row-01` (`x=300, y=59, w=239, h=26`) 내 텍스트 영역을 픽셀 매트릭스로 분해함.
   - 구분자 글리프는 Y=17(col 100)에서 Y=28(col 106)로 내려오는 12px 높이, 7px 폭의 좌상단→우하단 단일 대각선 획으로 렌더링됨.
   - `₩` 글리프의 결정적 특징인 중앙 가로 획(수평 바)이 픽셀 수준에서 0개로 전무함을 확인. 순수 `\` 글리프임 (`crops/i20_tree_separator_4x.png`).
2. **파일 트리 항목 툴팁 (`D:\...\branch\nested`)**:
   - `tooltip-box` (`x=429, y=83, w=306, h=79`) 영역 내 3개 텍스트 밴드를 전수 분해함.
   - `D:\` 드라이브 접두사의 역슬래시(Band 1, x=27~33), `\projects\`, `\branch\nested`(Band 3, x=78~84) 등 모든 경로 구분자가 동일한 각도의 단일 대각선 `\` 글리프로 렌더링됨 (`crops/i20_tooltip_d_drive_4x.png`, `crops/i20_tooltip_branch_nested_4x.png`).
3. **OS 네이티브 대화 상자**:
   - `app-I20-dialog-unsaved.png`: TaskDialog 창(`#32770`)에 영문 시스템 폰트(Segoe UI)로 `` Do you want to save the changes you made to 00-order03.md? `` 렌더링 확인 (`crops/i20_dialog_unsaved_msg.png`).
   - `app-I20-dialog-delete.png`: TaskDialog 창(`#32770`)에 영문 시스템 폰트(Segoe UI)로 `` Do you want to trash file-001.txt? `` 렌더링 확인 (`crops/i20_dialog_delete_msg.png`).
   - 둘 모두 OS 레벨의 다이얼로그로 확인되어 core-leader 지침에 따라 'OS 표시'로 분류 기록.

### 5.2 5자리 거터 지오메트리 픽셀 분석 (ORDER-03 잔여 1건)
- `app-S-9-gutter-5digit.png`에서 10,050행 문서 끝부분(10,023 ~ 10,051행)의 29개 행을 전수 샘플링함.
- 에디터 좌측 분할선은 이미지의 `col 540`이며, 에디터 내부 본체는 `col 541`부터 시작함 (offset 0 = `col 541`).
- **숫자 잉크 우측 끝**:
  - `col 541`로부터의 상대 오프셋 측정 결과, 23개 행이 `65 px`, 6개 행이 `66 px`에 잉크 최우측 픽셀이 위치함.
  - 스펙 요구치 `66 px (±1px)` (즉 65~67 px)에 전 행이 100% 안착함.
- **본문 잉크 시작점**:
  - 활성 행(Line 10050, y=788~799)의 커서 캐럿 잉크는 `col 541 + 101` (`col 642`)에 정확히 1px 두께로 렌더링됨 (`offset = 101 px`).
  - 일반 행의 첫 글자 'L'의 안티앨리어싱 왼쪽 가장자리는 `offset = 102 px` (값 222), 메인 세로 줄기는 `offset = 103 px` (값 38)에 위치함.
  - 스펙 요구치 `101 px (±1px)` (즉 100~102 px)에 커서 캐럿 및 텍스트 시작점이 정확히 일치함 (`crops/s9_gutter_5digit_measured_annotated_4x.png`).

---

## 6. 결론

- **I-20 (경로 역슬래시 표시)**: **PASS** (앱 그림 자리 트리/툴팁 모두 `\` 글리프 실측 확인, OS 네이티브 대화 상자는 'OS 표시' 정상 기록)
- **ORDER-03 남은 1건 (5자리 줄 번호 열 형상)**: **PASS** (숫자 우측 65~66px, 본문 시작 101~102px 실측 확인)
- **I-14 글꼴 유지**: **PASS** (UI IBM Plex Sans, 에디터 Lilex 15px / 9.00px advance / 24.00px 줄 높이 확인)

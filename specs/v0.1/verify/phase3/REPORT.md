# Phase 3 일치도 검증 보고서

- **검증 일시**: 2026-04-20 (1회차) / 2026-04-20 (2회차 재검증)
- **검증자**: wg-checker
- **기준 문서**:
  - `specs/v0.1/SPEC.md` (공통 판정 방식, R-12~R-15 및 R-15 이후 변경)
  - `specs/v0.1/PLAN.md` (`## Phase 3 — 레이아웃 뼈대` 완료 조건)
  - `D:\projects\docs\guides\zed-like-editor\01-zed\01-LAYOUT.md` (`L-01`, `L-02`, `L-06`, `L-11`~`L-16`, `L-21`~`L-35`, `L-62`, `L-92`)
  - `D:\projects\docs\guides\zed-like-editor\01-zed\04-APP-SPEC.md` (`A-30`, `A-32` 치수 점검표)
  - `D:\projects\docs\guides\zed-like-editor\01-zed\assets\zed-reference.png` (2880×1704 물리 px, 1440×852 논리 px, 200% 최대화 기준 화면) 및 `zed-reference-latte.png`
  - `docs/HERDR-DECISIONS.md` (`D-010`, `D-015`, `D-018`, `D-019`)
- **시험 환경 배율**: 창 DPI `192` (`scaleFactor = 2.0`, 200%), 최대화 창 `2880×1704` 물리 px = `1440×852` 논리 px (`rem = 16.0`)

---

## 요약 판정

| 요구 ID | 요구 명칭 | 1회차 판정 | 2회차 판정 | 비고 |
| --- | --- | --- | --- | --- |
| **R-12** | 레이아웃 뼈대가 Zed 화면 구조와 같은 배치로 서 있다 | **통과** | **통과** | `L-11`~`L-16` 6개 항목 모두 통과 (`layout.png`와 `zed-reference.png`·`zed-reference-latte.png` 직접 대조 및 `layout-boxes.json` 좌표 확인; 2회차 `result.json`에서도 8개 배치 검사 모두 `true`로 동일) |
| **R-13** | 레이아웃 뼈대의 치수가 치수 점검표 A-32와 ±1 논리 px 안에서 같다 | **통과** | **통과** | `A-32.1`~`A-32.13` 및 `A-32.16` 일부 총 14개 항목(세부 54개 측정값) 모두 ±1 논리 px(실제 오차 `0.0` 논리 px) 이내 통과 (`D-018 ①` 자리표시자 측정 및 `D-018 ③` 푸터 높이 비대상 반영; 2회차 `result.json`에서도 54개 측정값 모두 동일하게 통과) |
| **R-14** | 사이드바와 Dock의 리사이즈가 Zed 규칙대로 된다 | **통과** | **통과** | 1회차: 기본 끌기·더블클릭 7개 시나리오 통과 (`D-018 ②` L-31 본문 폭 `1140 − 6 = 1134` 해석 적용) / 2회차(`D-019 ①`): 본문 폭 변화 시 Dock 유효 폭(`effective_dock_width`) 재제한 시나리오 `A1`·`A2`·`B`·`C0`·`C` 및 핸들 위치 검사 포함 총 17개 점검 모두 통과 |
| **R-15** | rem 헬퍼가 rem 16px를 기준으로 치수를 낸다 | **통과** | **통과** | `L-01`·`L-02` 및 `SPEC R-15 이후 변경` 통과: 창 `rem = 16` 로그 확인, `A-32.3`~`A-32.13`·`A-32.16` 모두 `rems_from_px` 정의, `A-32.1`·`A-32.2`만 허용된 `px(...)` 예외 사용, 예외 밖 `px(...)` 직접 상수 0건 / 2회차(`D-019 ②`): `r15.a32AllMeasuredAndPass = true` 조건 추가 후 `r15.pass = true` 확인 |

---

## R-12. 레이아웃 뼈대가 Zed 화면 구조와 같은 배치로 서 있다

- **기준**: `SPEC.md` R-12 (`01-LAYOUT.md` `L-11`~`L-16`), 기준 화면 `01-zed/assets/zed-reference.png` (2880×1704 물리 px = 1440×852 논리 px) 및 `zed-reference-latte.png`
- **시각 대조 요약**: `specs/v0.1/verify/phase3/layout.png`(2880×1704 물리 px)를 `zed-reference.png`·`zed-reference-latte.png`와 나란히 대조한 결과, 왼쪽 끝에서 창 전체 높이를 차지하는 사이드바(위 헤더 32px + 폴더 줄 + 아래 푸터), 그 오른쪽의 Workspace(위 타이틀 바 32px + 가운데 본문 + 아래 상태 표시줄 30px), 본문 안의 왼쪽 프로젝트 패널 Dock(폭 240px, 오른쪽 1px 테두리)과 오른쪽 Center Pane(위 탭 바 32px + 아래 활성 아이템 영역) 배치가 기준 화면과 일치하며 오른쪽 사이드바·오른쪽 Dock·아래 Dock이 없다.

| 01-zed ID | 명세 값 | 실제 값 | 통과·실패·판정 불가 | 증거 파일 |
| --- | --- | --- | --- | --- |
| **L-11** | 창 최상위는 가로 배치: `[사이드바(열렸을 때)] → [Workspace]`. 오른쪽 사이드바 없음 | 최상위 가로 배치: `sidebar` (`x=0.0, y=0.0, w=300.0, h=852.0`) → `workspace` (`x=300.0, y=0.0, w=1140.0, h=852.0`). `workspace.x + workspace.w = 1440.0 = viewport.w`로 오른쪽 사이드바 없음 | **통과** | `specs/v0.1/verify/phase3/layout.png`, `specs/v0.1/verify/phase3/layout-boxes.json`, `src/ui/mod.rs:203-222` |
| **L-12** | 사이드바는 창 전체 높이를 차지하고 맨 위 줄(`32px`)이 타이틀 바 자리를 대신함; 타이틀 바는 사이드바 오른쪽에서 시작 | `sidebar` 높이 `852.0` (`viewport.h = 852.0`), 맨 위 `sidebar-header` (`x=0.0, y=0.0, w=299.0, h=32.0`, 아래 1px 테두리 포함). `title-bar`는 `x=300.0, y=0.0, w=1140.0, h=32.0`으로 사이드바 오른쪽에서 시작 | **통과** | `specs/v0.1/verify/phase3/layout.png`, `specs/v0.1/verify/phase3/layout-boxes.json`, `src/ui/layout.rs:21-38`, `src/ui/mod.rs:186` |
| **L-13** | Workspace는 세로 3단: `타이틀 바 (32px) → 가운데 영역(flex-1, 위·아래 테두리 1px) → 상태 표시줄 (30px)` | `workspace` 세로 3단: `title-bar` (`y=0.0, h=32.0`) → `work-area` (`y=32.0, h=790.0`, `.border_t_1().border_b_1()` 적용되어 내부 `body`는 `y=33.0, h=788.0`) → `status-bar` (`y=822.0, h=30.0`, `32 + 790 + 30 = 852`) | **통과** | `specs/v0.1/verify/phase3/layout.png`, `specs/v0.1/verify/phase3/layout-boxes.json`, `src/ui/mod.rs:182-198` |
| **L-14** | 가운데 영역은 가로로 `[왼쪽 Dock] → [Center(Pane)]`만 배치. 오른쪽 Dock·아래 Dock 없음 | `body` (`x=300.0, y=33.0, w=1140.0, h=788.0`) 가로 배치: `dock` (`x=300.0, y=33.0, w=240.0, h=788.0`) → `center` (`x=540.0, y=33.0, w=900.0, h=788.0`). `540.0 + 900.0 = 1440.0`, `33.0 + 788.0 = 821.0`으로 오른쪽·아래 Dock 없음 | **통과** | `specs/v0.1/verify/phase3/layout.png`, `specs/v0.1/verify/phase3/layout-boxes.json`, `src/ui/mod.rs:58-101` |
| **L-15** | Center는 Pane 하나로 고정: `탭 바 (32px) + 활성 아이템 영역 (flex-1)` | `center` (`x=540.0, y=33.0, w=900.0, h=788.0`) 세로 배치: `tab-bar` (`x=540.0, y=33.0, w=900.0, h=32.0`) + `active-item` (`x=540.0, y=65.0, w=900.0, h=756.0`, `32 + 756 = 788`) | **통과** | `specs/v0.1/verify/phase3/layout.png`, `specs/v0.1/verify/phase3/layout-boxes.json`, `src/ui/mod.rs:94-101` |
| **L-16** | 왼쪽 Dock은 탭 헤더 없이 본문만 가지며 오른쪽에 `1px` 테두리만 둠 | `dock`에 별도 탭 헤더가 없고 오른쪽 테두리 `.border_r_1().border_color(theme.border)` 1px 적용 (`layout.png`의 논리 `x=539~540`, 물리 `x=1078~1079` 세로선 확인) | **통과** | `specs/v0.1/verify/phase3/layout.png`, `specs/v0.1/verify/phase3/layout-boxes.json`, `src/ui/mod.rs:82-92` |

---

## R-13. 레이아웃 뼈대의 치수가 치수 점검표 A-32와 ±1 논리 px 안에서 같다

- **기준**: `SPEC.md` R-13 (`04-APP-SPEC.md` `A-32.1`~`A-32.13` 및 `A-32.16` 일부; `01-LAYOUT.md` `L-06`, `L-21`~`L-35`, `L-62`, `L-92`), 허용 오차 `±1` 논리 px
- **특기 사항**:
  - `SPEC.md` R-13 지침에 따라 Phase 4~7 요소(탭·슬롯·폴더 줄)는 자리표시자(`tab`, `tab-slot-start`, `tab-slot-end`, `sidebar-folder-row`)를 두어 치수를 측정했다.
  - `docs/HERDR-DECISIONS.md` `D-018 ①` 승인에 따라 `--dev-layout` 실행 시 상태 표시줄 좌·우 그룹과 사이드바 푸터 왼쪽 그룹에 `22×22` 투명 자리표시자(`status-left-placeholder`, `status-right-placeholder`, `sidebar-footer-placeholder`)를 두어 그룹 안 `gap = 4`를 실측했다.
  - `docs/HERDR-DECISIONS.md` `D-018 ③` 승인에 따라 `A-32.13`의 명세 열 값(`padding 4, gap 4, 위 테두리 1`)만 판정 대상이며 푸터 전체 높이(`31.0` vs 비고 열 `30`)는 판정 대상이 아니다.

| A-32 ID (01-zed ID) | 명세 값 (논리 px) | 실제 값 (논리 px) | 통과·실패·판정 불가 | 증거 파일 |
| --- | --- | --- | --- | --- |
| **A-32.1** (`L-21`) | 타이틀 바 높이: `32` | `title-bar.h = 32.0` (`x=300.0, y=0.0, w=1140.0, h=32.0`) | **통과** | `specs/v0.1/verify/phase3/layout-boxes.json`, `specs/v0.1/verify/phase3/result.json` |
| **A-32.2** (`L-39`) | 창 버튼(최소화·최대화·닫기): 각 `36×32`, 글리프 `10` | `window-btn-min` `36.0×32.0` (`1332,0`), `window-btn-max` `36.0×32.0` (`1368,0`), `window-btn-close` `36.0×32.0` (`1404,0`); 글리프 `WINDOW_BUTTON_GLYPH_SIZE = 10.0` (`title_bar.rs:151-152`, 200%에서 20 물리 px) | **통과** | `specs/v0.1/verify/phase3/layout-boxes.json`, `specs/v0.1/verify/phase3/result.json`, `src/ui/title_bar.rs:151-152` |
| **A-32.3** (`L-22`, `L-23`) | 탭 바 높이 / 탭 내용 높이: `32` / `31` | `tab-bar.h = 32.0` (`540,33, 900×32`), `tab-content.h = 31.0` (`601,34, 179×31`, 위 `1.0` 여백 포함) | **통과** | `specs/v0.1/verify/phase3/layout-boxes.json`, `specs/v0.1/verify/phase3/result.json` |
| **A-32.4** (`L-24`) | 탭 안쪽 padding / gap (자리표시자 탭): 좌우 padding `4` / 요소 gap `4` | `tab-content` (`601..780`) 안: 좌 padding `605.0 - 601.0 = 4.0`, 우 padding `780.0 - (762.0 + 14.0) = 4.0`, 시작 슬롯→라벨 gap `621.0 - (605.0 + 12.0) = 4.0`, 라벨→끝 슬롯 gap `762.0 - (621.0 + 137.0) = 4.0` | **통과** | `specs/v0.1/verify/phase3/layout-boxes.json`, `specs/v0.1/verify/phase3/result.json` |
| **A-32.5** (`L-25`) | 탭 슬롯(시작 / 끝, 빈 슬롯 자리표시자): 시작 `12×12`, 끝 `14×14` | `tab-slot-start`: `12.0×12.0` (`x=605.0, y=42.5`), `tab-slot-end`: `14.0×14.0` (`x=762.0, y=41.5`) | **통과** | `specs/v0.1/verify/phase3/layout-boxes.json`, `specs/v0.1/verify/phase3/result.json` |
| **A-32.6** (`L-27`) | 탭 바 양 끝 영역 padding / gap: 좌우 padding `6`, 아이콘 간 gap `4` | 왼쪽(`tab-bar-start` `540..601`, 오른쪽 테두리 1): 좌 padding `546.0 - 540.0 = 6.0`, 우 padding `(601.0 - 1.0) - (572.0 + 22.0) = 6.0`, gap `572.0 - (546.0 + 22.0) = 4.0` / 오른쪽(`tab-bar-end` `1353..1440`, 왼쪽 테두리 1): 좌 padding `1360.0 - (1353.0 + 1.0) = 6.0`, 우 padding `1440.0 - (1412.0 + 22.0) = 6.0`, gap1 `1386.0 - (1360.0 + 22.0) = 4.0`, gap2 `1412.0 - (1386.0 + 22.0) = 4.0` | **통과** | `specs/v0.1/verify/phase3/layout-boxes.json`, `specs/v0.1/verify/phase3/result.json` |
| **A-32.7** (`L-28`) | 상태 표시줄 높이: `30` (padding `4` × 2 + 아이콘 버튼 `22`) | `status-bar.h = 30.0` (`x=300.0, y=822.0, w=1140.0, h=30.0`; 좌 padding `304.0 - 300.0 = 4.0`, 우 padding `1440.0 - (1420.0 + 16.0) = 4.0`, 버튼 높이 `22.0`) | **통과** | `specs/v0.1/verify/phase3/layout-boxes.json`, `specs/v0.1/verify/phase3/result.json` |
| **A-32.8** (`L-29`) | 상태 표시줄 gap: 그룹 사이 `8`, 그룹 안 `4` | 그룹 사이 gap `status-right.x (1394.0) - (status-left.x (304.0) + status-left.w (1082.0)) = 8.0`; 왼쪽 그룹 안 gap (`D-018 ①` 자리표시자) `330.0 - (304.0 + 22.0) = 4.0`; 오른쪽 그룹 안 gap (`D-018 ①` 자리표시자) `1420.0 - (1394.0 + 22.0) = 4.0` | **통과** | `specs/v0.1/verify/phase3/layout-boxes.json`, `specs/v0.1/verify/phase3/result.json`, `docs/HERDR-DECISIONS.md` (`D-018`) |
| **A-32.9** (`L-30`) | Dock 리사이즈 핸들: 폭 `6`, 테두리 걸침 `-3` | `dock-handle.w = 6.0` (`x=537.0, y=33.0, w=6.0, h=788.0`), Dock 오른쪽 끝(`540.0`) 기준 걸침 `537.0 - 540.0 = -3.0` | **통과** | `specs/v0.1/verify/phase3/layout-boxes.json`, `specs/v0.1/verify/phase3/result.json` |
| **A-32.10** (`L-32`) | 프로젝트 패널(왼쪽 Dock) 기본 폭: `240` | `dock.w = 240.0` (`x=300.0, y=33.0, w=240.0, h=788.0`) | **통과** | `specs/v0.1/verify/phase3/layout-boxes.json`, `specs/v0.1/verify/phase3/result.json` |
| **A-32.11** (`L-33`) | 사이드바 폭: 기본 `300`, 범위 `200~800` | 초기 `sidebar.w = 300.0` (`x=0.0, y=0.0, w=300.0, h=852.0`), 리사이즈 하한 `200.0` (`seq=14`)·상한 `800.0` (`seq=12`) | **통과** | `specs/v0.1/verify/phase3/layout-boxes.json`, `specs/v0.1/verify/phase3/result.json` |
| **A-32.12** (`L-34`) | 사이드바 폴더 줄(자리표시자 1줄): 높이 `31`, 좌 padding `8`, 우 padding `6` | `sidebar-folder-row` (`x=0.0, y=32.0, w=299.0, h=31.0`), 내부 라벨(`x=8.0, y=36.0, w=285.0, h=22.5`): 높이 `31.0`, 좌 padding `8.0 - 0.0 = 8.0`, 우 padding `299.0 - (8.0 + 285.0) = 6.0` | **통과** | `specs/v0.1/verify/phase3/layout-boxes.json`, `specs/v0.1/verify/phase3/result.json` |
| **A-32.13** (`L-35`) | 사이드바 푸터: padding `4`, gap `4`, 위 테두리 `1` (`D-018 ③`: 푸터 높이는 판정 대상 아님) | `sidebar-footer` (`x=0.0, y=821.0, w=299.0, h=31.0`): 좌 padding `4.0 - 0.0 = 4.0`, 우 padding `299.0 - (273.0 + 22.0) = 4.0`, 위 padding(위 테두리 1 제외) `826.0 - (821.0 + 1.0) = 4.0`, 위 테두리 `31.0 - 8.0 - 22.0 = 1.0`, 좌·우 그룹 사이 gap `273.0 - (4.0 + 265.0) = 4.0`, 왼쪽 그룹 안 gap (`D-018 ①` 자리표시자) `30.0 - (4.0 + 22.0) = 4.0` | **통과** | `specs/v0.1/verify/phase3/layout-boxes.json`, `specs/v0.1/verify/phase3/result.json`, `docs/HERDR-DECISIONS.md` (`D-018`) |
| **A-32.16 일부** (`L-06`, `L-62`, `L-92`) | 탭 바·상태 표시줄 아이콘 크기: `14` (`14×14`) | `tab-icon-back` `14.0×14.0`, `tab-icon-forward` `14.0×14.0`, `tab-icon-new` `14.0×14.0`, `tab-icon-split` `14.0×14.0`, `tab-icon-zoom` `14.0×14.0`, `status-icon-project-panel` `14.0×14.0` (사이드바 푸터 아이콘 `sidebar-icon-toggle`·`sidebar-icon-folder-add`도 `14.0×14.0`) | **통과** | `specs/v0.1/verify/phase3/layout-boxes.json`, `specs/v0.1/verify/phase3/result.json` |

---

## R-14. 사이드바와 Dock의 리사이즈가 Zed 규칙대로 된다

- **기준**: `SPEC.md` R-14 (`01-LAYOUT.md` `L-30`~`L-33`), `docs/HERDR-DECISIONS.md` `D-015`·`D-018 ②` (`L-31`의 "창 폭"을 Workspace 본문 폭 `body.w = 1140`으로 해석하여 Dock 최대 폭 = `1140 − 6 = 1134`)

| 01-zed ID | 명세 값 | 실제 값 | 통과·실패·판정 불가 | 증거 파일 |
| --- | --- | --- | --- | --- |
| **L-30** (핸들 치수·커서·끌기) | Dock 오른쪽 경계에 폭 `6px` 투명 핸들이 테두리에 절반씩(`-3px`) 걸치고 마우스 올리면 `col_resize` 커서; 끌면 Dock 폭이 마우스를 따라 바뀜 | 핸들 `dock-handle` (`x=537.0, w=6.0`, 걸침 `-3.0`), `.cursor_col_resize()` 설정(`src/ui/mod.rs:111`). 핸들을 `(540, 427) → (640, 427)`으로 `+100` 논리 px 끌었을 때 Dock 폭 `240.0 → 340.0` (`seq=3`) | **통과** | `specs/v0.1/verify/phase3/result.json`, `specs/v0.1/verify/phase3/r14-dock-plus100.png`, `src/ui/mod.rs:103-119` |
| **L-31** (Dock 하한) | Dock 폭을 `6px`보다 작게 줄일 수 없음 | 핸들을 `(640, 427) → (260, 427)`(사이드바 안쪽)으로 왼쪽 끝 너머까지 끌었을 때 Dock 폭 `340.0 → 6.0`에서 멈춤 (`seq=5`) | **통과** | `specs/v0.1/verify/phase3/result.json`, `specs/v0.1/verify/phase3/r14-dock-past-left.png`, `src/ui/mod.rs:27-35` |
| **L-31** (Dock 상한, `D-018 ②`) | 가운데 Pane 최소 폭 `6px` 남김 (`D-018 ②`: Workspace 본문 폭 `1140 − 6 = 1134px` 상한) | 핸들을 `(306, 427) → (1438, 427)`(창 오른쪽 끝 근처)까지 끌었을 때 Dock 폭 `6.0 → 1134.0` (`body.w 1140.0 - 6.0 = 1134.0`, `center.w = 6.0`)에서 멈춤 (`seq=7`) | **통과** | `specs/v0.1/verify/phase3/result.json`, `specs/v0.1/verify/phase3/r14-dock-past-right.png`, `docs/HERDR-DECISIONS.md` (`D-018`) |
| **L-30, L-32** (Dock 더블클릭 복원) | 프로젝트 패널 기본 폭 `240px`; 핸들을 더블클릭하면 기본 폭 `240px`으로 돌아감 | 초기 Dock 폭 `240.0` (`seq=1`). 폭 `1134.0` 상태에서 핸들 `(1434, 427)` 더블클릭 시 Dock 폭 `1134.0 → 240.0`으로 즉시 복원 (`seq=8`) | **통과** | `specs/v0.1/verify/phase3/result.json`, `specs/v0.1/verify/phase3/r14-dock-double-click.png`, `src/ui/mod.rs:112-117` |
| **L-33** (사이드바 끌기 및 범위 `200~800`) | 사이드바 기본 폭 `300px`, 리사이즈 범위 `200px ~ 800px` | 초기 폭 `300.0` (`seq=1, 8`) → `(300, 427) → (400, 427)` `+100` 끌기 후 `400.0` (`seq=10`) → `(400, 427) → (1000, 427)` 상한 너머 끌기 후 `800.0` (`seq=12`) → `(800, 427) → (60, 427)` 하한 아래 끌기 후 `200.0` (`seq=14`) | **통과** | `specs/v0.1/verify/phase3/result.json`, `specs/v0.1/verify/phase3/r14-sidebar-plus100.png`, `specs/v0.1/verify/phase3/r14-sidebar-past800.png`, `specs/v0.1/verify/phase3/r14-sidebar-below200.png`, `src/ui/mod.rs:206-214` |

---

## R-15. rem 헬퍼가 rem 16px를 기준으로 치수를 낸다

- **기준**: `SPEC.md` R-15 및 `R-15 이후 변경` (`01-LAYOUT.md` `L-01`, `L-02`, `docs/HERDR-DECISIONS.md` `D-010`)
  - ① 창의 `rem` 값이 `16px`임을 로그로 출력
  - ② R-13에서 재는 모든 항목이 코드에서 `rems_from_px`(또는 동등 헬퍼)로 정의되어 있음을 `A-32` ID마다 `파일:줄`로 대조 — 단, `SPEC R-15 이후 변경`(`D-010`)에 따라 타이틀 바(`A-32.1`, `L-21`)와 창 버튼(`A-32.2`, `L-39`)은 `L-01` 원문("탭·상태 표시줄·사이드바·패널의 높이와 간격")과 `L-21` 원문("`px(32.)` 고정")에 맞춰 `px(...)` 고정을 예외로 허용
  - ③ R-13 측정이 통과

### 1) 창 `rem = 16px` 로그 및 헬퍼 정의 확인

| 항목 ID | 명세 값 | 실제 값 | 통과·실패·판정 불가 | 증거 파일 |
| --- | --- | --- | --- | --- |
| **L-01** (창 rem 크기) | 창의 `rem = 16px` (`window.rem_size() == px(16.)`) | `app-stdout.txt` 첫 스냅샷 로그 `[dev] layout-snapshot seq=1 rem=16 scale=2 viewport=1440x852 maximized=true dock_width=240` 및 `layout.json` / `result.json`의 `windowRem: 16.0` | **통과** | `specs/v0.1/verify/phase3/app-stdout.txt`, `specs/v0.1/verify/phase3/layout.json`, `specs/v0.1/verify/phase3/result.json`, `src/ui/layout_probe.rs:146-152` |
| **L-02** (rem 변환 헬퍼) | `rems_from_px(N)` = `N / 16.0 rem` | `pub const BASE_REM_PX: f32 = 16.0;` (`src/ui/rem.rs:13`), `pub const fn rems_from_px(px: f32) -> Rems { rems(px / BASE_REM_PX) }` (`src/ui/rem.rs:16-18`), `pub fn to_px(value: Rems, window: &Window) -> Pixels { value.to_pixels(window.rem_size()) }` (`src/ui/rem.rs:21-23`) | **통과** | `src/ui/rem.rs:13-23` |
| **R-15 ③** (R-13 측정 통과) | R-13의 A-32 치수 측정 전 항목 통과 | `A-32.1`~`A-32.13`, `A-32.16` 세부 54개 측정값 모두 통과 (`failCount = 0`, `notMeasurableCount = 0`) | **통과** | `specs/v0.1/verify/phase3/result.json` |

### 2) A-32 ID별 코드 상수 정의 위치 (`src/ui/metrics.rs`, `src/ui/layout.rs`) 및 `px` 직접 상수 여부

| A-32 ID (01-zed ID) | 상수 이름 및 정의 식 | 파일:줄 | 사용처 (`파일:줄`) | 판정 |
| --- | --- | --- | --- | --- |
| **A-32.1** (`L-21`) | `pub const TITLE_BAR_HEIGHT: Pixels = px(32.);` (보조: `TITLE_BAR_PADDING_LEFT: Pixels = px(8.);`) | `src/ui/metrics.rs:15` (`:17`) | `src/ui/title_bar.rs:88`, `src/ui/layout.rs:26` | **통과** (`SPEC R-15 이후 변경` / `D-010`에 따른 `px` 예외 허용) |
| **A-32.2** (`L-39`) | `pub const WINDOW_BUTTON_WIDTH: Pixels = px(36.);`<br>`pub const WINDOW_BUTTON_HEIGHT: Pixels = px(32.);`<br>`pub const WINDOW_BUTTON_GLYPH_SIZE: Pixels = px(10.);` | `src/ui/metrics.rs:19-21` | `src/ui/title_bar.rs:133-134`, `src/ui/title_bar.rs:151-152` | **통과** (`SPEC R-15 이후 변경` / `D-010`에 따른 `px` 예외 허용) |
| **A-32.3** (`L-22`, `L-23`) | `pub const TAB_BAR_HEIGHT: Rems = rems_from_px(32.);`<br>`pub const TAB_CONTENT_HEIGHT: Rems = rems_from_px(31.);`<br>`fn rems_1px() -> Rems { super::rem::rems_from_px(1.) }` | `src/ui/metrics.rs:40`<br>`src/ui/metrics.rs:42`<br>`src/ui/layout.rs:232-234` | `src/ui/layout.rs:94, 113, 134, 152`<br>`src/ui/layout.rs:163`<br>`src/ui/layout.rs:154` | **통과** (`rems_from_px` 사용) |
| **A-32.4** (`L-24`) | `pub const TAB_PADDING_X: Rems = rems_from_px(4.);`<br>`pub const TAB_GAP: Rems = rems_from_px(4.);` | `src/ui/metrics.rs:44-45` | `src/ui/layout.rs:164-165` | **통과** (`rems_from_px` 사용) |
| **A-32.5** (`L-25`) | `pub const TAB_START_SLOT: Rems = rems_from_px(12.);`<br>`pub const TAB_END_SLOT: Rems = rems_from_px(14.);` | `src/ui/metrics.rs:47-48` | `src/ui/layout.rs:169, 179` | **통과** (`rems_from_px` 사용) |
| **A-32.6** (`L-27`) | `pub const TAB_BAR_EDGE_PADDING_X: Rems = rems_from_px(6.);`<br>`pub const TAB_BAR_EDGE_GAP: Rems = rems_from_px(4.);` | `src/ui/metrics.rs:50-51` | `src/ui/layout.rs:116-117, 137-138` | **통과** (`rems_from_px` 사용) |
| **A-32.7** (`L-28`) | `pub const STATUS_BAR_PADDING: Rems = rems_from_px(4.);`<br>`pub const BUTTON_DEFAULT: Rems = rems_from_px(22.);` (`4×2 + 22 = 30`) | `src/ui/metrics.rs:56`<br>`src/ui/metrics.rs:35` | `src/ui/layout.rs:193-195`<br>`src/ui/layout.rs:220-221, 241-242` | **통과** (`rems_from_px` 사용) |
| **A-32.8** (`L-29`) | `pub const STATUS_BAR_GROUP_GAP: Rems = rems_from_px(8.);`<br>`pub const STATUS_BAR_ITEM_GAP: Rems = rems_from_px(4.);` | `src/ui/metrics.rs:58-59` | `src/ui/layout.rs:196, 200, 207` | **통과** (`rems_from_px` 사용) |
| **A-32.9** (`L-30`) | `pub const DOCK_HANDLE_WIDTH: Rems = rems_from_px(6.);` (걸침 `-half = -to_px(DOCK_HANDLE_WIDTH, window) * 0.5`) | `src/ui/metrics.rs:64` | `src/ui/mod.rs:103-109` | **통과** (`rems_from_px` 사용) |
| **A-32.10** (`L-32`) | `pub const DOCK_DEFAULT_WIDTH: Rems = rems_from_px(240.);` | `src/ui/metrics.rs:66` | `src/ui/mod.rs:23, 60, 114` | **통과** (`rems_from_px` 사용) |
| **A-32.11** (`L-33`) | `pub const SIDEBAR_DEFAULT_WIDTH: Rems = rems_from_px(300.);`<br>`pub const SIDEBAR_MIN_WIDTH: Rems = rems_from_px(200.);`<br>`pub const SIDEBAR_MAX_WIDTH: Rems = rems_from_px(800.);` | `src/ui/metrics.rs:71-73` | `src/ui/mod.rs:206-209` | **통과** (`rems_from_px` 사용) |
| **A-32.12** (`L-34`) | `pub const SIDEBAR_ROW_HEIGHT: Rems = rems_from_px(31.);`<br>`pub const SIDEBAR_ROW_PADDING_LEFT: Rems = rems_from_px(8.);`<br>`pub const SIDEBAR_ROW_PADDING_RIGHT: Rems = rems_from_px(6.);` | `src/ui/metrics.rs:75-77` | `src/ui/layout.rs:51-53` | **통과** (`rems_from_px` 사용) |
| **A-32.13** (`L-35`) | `pub const SIDEBAR_FOOTER_PADDING: Rems = rems_from_px(4.);`<br>`pub const SIDEBAR_FOOTER_GAP: Rems = rems_from_px(4.);`<br>위 테두리 `1`: `.border_t_1()` | `src/ui/metrics.rs:79-80`<br>`src/ui/layout.rs:68` | `src/ui/layout.rs:68-74` | **통과** (`rems_from_px` 및 `.border_t_1()` 사용) |
| **A-32.16 일부** (`L-06`, `L-62`, `L-92`) | `pub const ICON_SMALL: Rems = rems_from_px(14.);` | `src/ui/metrics.rs:33` | `src/ui/layout.rs:226-227` | **통과** (`rems_from_px` 사용) |

- **예외 밖 `px(...)` 직접 상수 감사 결과**: `src/ui/metrics.rs`, `src/ui/layout.rs`, `src/ui/mod.rs` 전체를 확인한 결과, R-13 측정 대상 중 허용된 예외(`A-32.1` 타이틀 바, `A-32.2` 창 버튼) 밖에서 `px(...)` 직접 상수로 정의된 치수는 **0건**이다(`src/ui/metrics.rs:23-28`의 `WINDOW_ROUNDING`·`WINDOW_MIN_SIZE`는 Phase 1 창 껍데기 상수이며 R-13 측정 대상이 아님).

---

## 재검증 (2회차)

- **배경 (`docs/HERDR-DECISIONS.md` `D-019`)**:
  - ① **R-14 (Major)**: 1회차 코드에서는 Dock 폭 제한(`clamp_dock_width`)이 핸들 끌기 이벤트에서만 실행되어, Dock을 넓힌 뒤 사이드바를 넓히거나 창 크기를 줄이면 Dock이 상한(`본문 폭 − 6`)을 넘고 핸들이 본문 밖으로 나갈 수 있었다. 이를 수정하여 `src/ui/mod.rs`에서 본문 상자의 `on_children_prepainted`(`track_body`, `202-212행`)로 실제 `body_width`를 추적하고, 렌더 시 `effective_dock_width`(`63-71행`)로 저장 폭(`dock_width`, 없으면 기본 `240`)을 현재 `body_width`에 맞춰 `[6, body_width − 6]`으로 다시 제한하며 핸들 위치(`124행`)도 유효 폭 기준으로 배치했다.
  - ② **R-15 (Minor)**: `tools/verify-phase3.ps1`의 `r15.pass`(`503-504행`)에 `SPEC R-15` 세 번째 판정 조건("R-13 측정이 통과하면 통과로 판정한다")을 검사하는 `a32AllMeasuredAndPass` 필드를 추가했다.

### 1) R-12 · R-13 새 증거(`result.json`, `layout-boxes.json`) 대조

- 2회차 실행(`pid = 6812`, `hwnd = 0xD2088A`, `errors = []`, `head = "rem=16 scale=2 viewport=1440x852 maximized=true dock_width=240 dock_stored=default body_width=1140"`)에서:
  - **R-12**: `result.json`의 `r12` 8개 배치 항목이 모두 `true`이며, `layout-boxes.json`(`seq=1`)의 모든 상자 좌표·크기가 1회차와 `0.0` 논리 px 차이 없이 동일하다 → **통과 유지**.
  - **R-13**: `result.json`의 `a32` 세부 54개 측정값이 모두 1회차와 동일한 수치로 `pass = true`(`a32Summary: pass=54, fail=0, notMeasurable=0`)이다 → **통과 유지**.

### 2) R-14 재검증 — 기존 시나리오 + 본문 폭 변화 시 Dock 유효 폭 재제한 시나리오 (`A1`·`A2`·`B`·`C0`·`C`)

- 기존 8개 리사이즈 점검(`dockPlus100 = 340.0`, `dockPastLeft = 6.0`, `dockPastRight = 1134.0`, `dockDoubleClick = 240.0`, `dock-handle.w = 6.0`, `sidebarPlus100 = 400.0`, `sidebarPast800 = 800.0`, `sidebarBelow200 = 200.0`)은 2회차에서도 동일하게 모두 통과했다(`seq=3, 5, 7, 8, 10, 12, 14`).
- 새로 추가된 본문 폭 변화 시나리오(`A1`·`A2`·`B`·`C0`·`C`, `seq=17, 19, 21, 23, 24`) 검증 결과:

| 01-zed ID (시나리오) | 명세 값 (논리 px) | 실제 값 (논리 px) | 통과·실패·판정 불가 | 증거 파일 |
| --- | --- | --- | --- | --- |
| **L-31** (`A1`: `reviewDockToMax`, 사이드바 `200`에서 Dock 상한까지 끌기) | `body.w = 1240.0`일 때 Dock 유효 폭 = `1240 − 6 = 1234.0`, 핸들이 본문 안·Dock 경계 중앙에 위치 | `dockStored = "1234"`, `dockWidth = 1234.0`, `dock.w = 1234.0` (`x=200.0`), `center.w = 6.0` (`x=1434.0`), `handle = (1431.0, 33.0, 6.0, 788.0)` (`handleInsideBody = true`, `handleCenteredOnDockEdge = true`, `seq=17`) | **통과** | `specs/v0.1/verify/phase3/result.json`, `specs/v0.1/verify/phase3/r14-review-dock-to-max.png`, `specs/v0.1/verify/phase3/r14-review-dock-to-max.json` |
| **L-30, L-31** (`A2`: `reviewSidebarAfterDockMax`, 더블클릭 없이 사이드바를 `800`으로 확장) | `body.w = 640.0`으로 줄어들 때 저장 폭(`1234`)은 유지하되 유효 폭 = `min(1234, 640 − 6) = 634.0`, 핸들이 본문 안·Dock 경계(`x=1434.0`)에 걸침 | `dockStored = "1234"`, `dockWidth = 634.0`, `dock.w = 634.0` (`x=800.0`), `center.w = 6.0` (`x=1434.0`), `handle = (1431.0, 33.0, 6.0, 788.0)` (`handleInsideBody = true`, `handleCenteredOnDockEdge = true`, `seq=19`) | **통과** | `specs/v0.1/verify/phase3/result.json`, `specs/v0.1/verify/phase3/r14-review-sidebar-800-after-dock-max.png`, `specs/v0.1/verify/phase3/r14-review-sidebar-800-after-dock-max.json` |
| **L-30, L-31** (`B`: `reviewWindowShrink`, 최대화 해제 후 창을 `1000×700` 논리 px로 축소) | `viewport = 987×693.5`, `sidebar.w = 548.5`, `body.w = 438.5`일 때 Dock 상자 폭 = 유효 폭 = `min(1234, 438.5 − 6) = 432.5`, 핸들이 본문 안·Dock 경계(`x=981.0`)에 걸침 | `dockStored = "1234"`, `dockWidth = 432.5`, `dock.w = 432.5` (`x=548.5`), `center.w = 6.0` (`x=981.0`), `handle = (978.0, 33.0, 6.0, 629.5)` (`handleInsideBody = true`, `handleCenteredOnDockEdge = true`, `seq=21`) | **통과** | `specs/v0.1/verify/phase3/result.json`, `specs/v0.1/verify/phase3/r14-review-window-shrink.png`, `specs/v0.1/verify/phase3/r14-review-window-shrink.json` |
| **L-31** (`C0`: `reviewNarrowBody`, 축소된 창에서 사이드바를 `800`으로 넓혀 본문을 `240` 미만으로 좁힘) | `body.w = 187.0` (`limit = 181.0 < 240`)일 때 Dock 유효 폭 = `min(1234, 187.0 − 6) = 181.0`, 핸들이 본문 안·Dock 경계(`x=981.0`)에 걸침 | `dockStored = "1234"`, `dockWidth = 181.0`, `dock.w = 181.0` (`x=800.0`), `center.w = 6.0` (`x=981.0`), `handle = (978.0, 33.0, 6.0, 629.5)` (`handleInsideBody = true`, `handleCenteredOnDockEdge = true`, `seq=23`) | **통과** | `specs/v0.1/verify/phase3/result.json`, `specs/v0.1/verify/phase3/r14-review-narrow-body.png`, `specs/v0.1/verify/phase3/r14-review-narrow-body.json` |
| **L-30, L-31, L-32** (`C`: `reviewNarrowDoubleClick`, 좁은 본문 `body.w − 6 < 240`에서 핸들 더블클릭) | 더블클릭 시 저장 폭이 `default`(`240`)로 돌아가되 화면 유효 폭은 `min(240, 187.0 − 6) = 181.0`으로 제한되고 핸들이 본문 안·Dock 경계에 걸침 | `dockStored = "default"`, `dockWidth = 181.0` (`expected = 181`), `dock.w = 181.0` (`x=800.0`), `handle = (978.0, 33.0, 6.0, 629.5)` (`handleInsideBody = true`, `handleCenteredOnDockEdge = true`, `seq=24`) | **통과** | `specs/v0.1/verify/phase3/result.json`, `specs/v0.1/verify/phase3/r14-review-narrow-double-click.png`, `specs/v0.1/verify/phase3/r14-review-narrow-double-click.json`, `src/ui/mod.rs:63-71, 128-131` |

### 3) R-15 재검증 — `a32AllMeasuredAndPass` 조건 및 코드 상수 위치 확인

| 항목 ID | 명세 값 | 2회차 실제 값 | 통과·실패·판정 불가 | 증거 파일 |
| --- | --- | --- | --- | --- |
| **R-15 ①** (`L-01` 창 rem 로그) | `windowRem == 16.0` | `windowRem: 16.0` (`app-stdout.txt` `seq=1..24` 모두 `rem=16`) | **통과** | `specs/v0.1/verify/phase3/result.json`, `specs/v0.1/verify/phase3/app-stdout.txt`, `src/ui/mod.rs:147-148` |
| **R-15 ②** (`L-02` `rems_from_px` 상수 정의 및 예외 감사) | R-13 측정 항목이 `rems_from_px`로 정의(타이틀 바 `A-32.1`·창 버튼 `A-32.2` `px` 예외), 예외 밖 비-rem 상수 0건 | `nonRemOutsideExceptions: []` (0건); `src/ui/mod.rs` 사용처 줄 번호(`DOCK_HANDLE_WIDTH`: `55, 76, 124-125행`, `DOCK_DEFAULT_WIDTH`: `23, 66행`, `SIDEBAR_*_WIDTH`: `23-24, 240-241행`) 확인 완료 | **통과** | `specs/v0.1/verify/phase3/result.json`, `src/ui/metrics.rs`, `src/ui/rem.rs`, `src/ui/mod.rs` |
| **R-15 ③** (`D-019 ②` `a32AllMeasuredAndPass`) | `a32.Count > 0`이고 모든 항목 `pass == true`일 때만 `r15.pass == true` | `a32AllMeasuredAndPass: true` (54/54 통과), `r15.pass: true` | **통과** | `specs/v0.1/verify/phase3/result.json`, `tools/verify-phase3.ps1:503-504` |

---

## PLAN Phase 3 완료 조건 대조

| 완료 조건 (`specs/v0.1/PLAN.md` Phase 3) | 1회차 | 2회차 | 증거 |
| --- | --- | --- | --- |
| **R-12 통과**: 앱 스크린샷을 기준 화면과 나란히 놓았을 때 최상위 가로 배치(`[사이드바] → [Workspace]`), 사이드바 전체 높이 차지, Workspace 세로 3단, 가운데 영역 `[왼쪽 Dock] → [Center(Pane)]`, Center의 `탭 바 + 활성 아이템`, 왼쪽 Dock 오른쪽 `1px` 테두리가 같고 오른쪽 사이드바·오른쪽 Dock·아래 Dock이 없다 | **통과** | **통과** | `specs/v0.1/verify/phase3/layout.png`, `specs/v0.1/verify/phase3/layout-boxes.json`, `specs/v0.1/verify/phase3/result.json` |
| **R-13 통과**: `A-32`의 Phase 3 해당 치수(`A-32.1`~`A-32.13`과 `A-32.16` 중 탭 바·상태 표시줄 아이콘 크기)가 코드의 요소 경계 로그와 스크린샷 픽셀 측정에서 모두 ±1 논리 px 안에 든다 | **통과** | **통과** | `specs/v0.1/verify/phase3/layout-boxes.json`, `specs/v0.1/verify/phase3/result.json` (54/54 통과) |
| **R-14 통과**: 사이드바 리사이즈 범위 `200~800px`와 기본 폭 `300px`, 왼쪽 Dock 기본 폭 `240px`, 핸들 폭 `6px`(절반씩 걸침, `col_resize` 커서), 최소 폭 `6px`, 가운데 Pane 최소 `6px` 남김, 핸들 더블클릭 시 `240px` 복원이 마우스 끌기·더블클릭 시험에서 확인된다 (2회차: 본문 폭 변화 시 Dock 유효 폭 재제한 `A1`·`A2`·`B`·`C0`·`C` 포함) | **통과** | **통과** | `specs/v0.1/verify/phase3/result.json`, `specs/v0.1/verify/phase3/r14-*.png`, `specs/v0.1/verify/phase3/r14-review-*.png` |
| **R-15 통과**: 창의 `rem`이 `16px`임이 로그로 확인되고, R-13 항목이 코드에서 `rems_from_px`로 정의되어 있으며(타이틀 바 `A-32.1`·창 버튼 `A-32.2` `px` 예외), R-13 측정이 통과한다 (`a32AllMeasuredAndPass = true`) | **통과** | **통과** | `specs/v0.1/verify/phase3/app-stdout.txt`, `specs/v0.1/verify/phase3/result.json`, `src/ui/rem.rs`, `src/ui/metrics.rs`, `src/ui/layout.rs` |
| **Phase 끝 순서**: 리뷰 → 검증 → PROGRESS 기록 → 사용자 승인 후 커밋 | **진행 중** | **진행 중** | 현재 검증(wg-checker 2회차) 단계 수행 완료 |

---

## 불일치 목록

없음 (1회차·2회차 모두 불일치 0건).

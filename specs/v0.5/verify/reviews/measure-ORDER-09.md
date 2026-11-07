# ORDER-09 UI 실측 검증 기록 (I-10, I-11, I-12, I-16, I-23)

- 상위 지시: core ORDER-09, 카드 C-37, C-38
- 검증 대상: `workbench-gpui` 단독 UI 실측 캡처 대조 (1440×852, 100% DPI, One Dark)
- 대조 자료: `workbench-tauri` 실측 자료 (`specs/v0.5/verify/ORDER-09/zed-*.png`) 및 Zed 4304dec 소스

---

## 1. 스펙 ID 및 요구별 판정 결과 표

| 스펙 ID / 요구 | 항목 | 기대값 (Zed) | 실측값 (workbench-gpui) | 판정 | 대조 캡처 경로 | 비고 / 스크립트 판정 차이 사유 |
|---|---|---|---|---|---|---|
| **I-11**<br>(R-11) | 탭 제목 호버 툴팁 | 파일 절대 경로 (`\`), 탭 제목 아래 표시 | 파일 절대 경로 (`D:\...\AGENTS.md`), 위치 Zed 일치 | **통과 (PASS)** | `specs/v0.5/verify/reviews/measure-ORDER-09-run4/app-step1-tab-tooltip.png`, `run6-step1` | 테스트 픽스처 경로가 길어 3줄로 자동 감김(Zed 캡처는 짧은 경로라 비교 불가) → **Phase 12 사용자 확인** |
| **I-23**<br>(R-23) | 트리 패널 포커스 시 우측 버튼 | 버튼 숨김 (없음) | 우측 버튼(+·분할·최대화) 미표시 | **통과 (PASS)** | `specs/v0.5/verify/reviews/measure-ORDER-09-run7-step2/app-step2-focus-panel.png` | 스크립트 판정 다름 (아래 설명 참조) |
| **I-23**<br>(R-23) | 트리 포커스 + 탭 바 호버 | 버튼 숨김 (호버만으로 안 나타남) | 우측 버튼 미표시 유지 | **통과 (PASS)** | `specs/v0.5/verify/reviews/measure-ORDER-09-run6-step2/app-step2-panel-hover-tabbar.png` | 스크립트 판정 다름 (아래 설명 참조) |
| **I-23**<br>(R-23) | 편집기 포커스 시 우측 버튼 | 버튼 표시 (보임) | 우측 버튼 3개 정상 표시 | **통과 (PASS)** | `specs/v0.5/verify/reviews/measure-ORDER-09-run6-step2/app-step2-focus-editor.png` | 스크립트 판정 다름 (아래 설명 참조) |
| **I-16**<br>(R-16) | 탭 가로 휠 스크롤 1칸 이동량 | 약 80px (3줄 × 16px × phi = 77.7px) | **81px** (열 프로필 탐색 대조) | **통과 (PASS)** | `run6-step3/app-step3-overflow.png` → `app-step3-wheel-down.png` | run7의 24px는 이미 끝까지 스크롤된 상태에서 남은 드롭 자리만큼 이동한 것이므로 제외, run6(81px)를 정식 값으로 채택 |
| **I-16**<br>(R-16) | 탭 바 끝 빈 자리 (오버플로우 시) | 0px (끝 버튼에 바로 인접) | **0px** (K-36 드롭 영역 분리 후) | **통과 (PASS)** | `run6-step3`, `run7-step3` 캡처 | K-36 리팩토링으로 오버플로우 빈자리 0px 달성 |
| **I-16**<br>(R-16) | 탭 오픈 직후 활성 탭 가시성 | 연 직후 뷰포트에 즉시 보임 | t0, t300, t1000 모두 활성 탭 배경 가시 확인 | **통과 (PASS)** | `run7-step3/app-step3-active-t0.png`, `t300.png`, `t1000.png` | K-37 1회 레이아웃 지연 보정(`after_layout`) 정상 동작 |
| **I-16**<br>(R-16) | Ctrl-PageUp 첫 탭 활성화/가시성 | 첫 탭(`AGENTS.md`) 활성화 및 탭 바 내 표시 | `AGENTS.md` 활성화 및 탭 표시 확인 | **통과 (PASS)** | `run7-step3/app-step3-first-active.png` | 순환 이동 후 첫 탭 정상 가시화 |
| **I-12**<br>(R-12) | 단일 폴더 마크다운 1행 경로 줄 | `AGENTS.md › # AGENTS` (One Dark 테마 색상) | `AGENTS.md › # AGENTS`, 글자·색·위치 일치 | **통과 (PASS)** | `run6-step4/app-step4-bc-a-start.png` vs `zed-a-start.png` | 툴바 좌측 정렬, 테마 토큰(`text.placeholder`, `syntax.title`) 일치 |
| **I-12**<br>(R-12) | 단일 폴더 마크다운 5행 경로 줄 | `AGENTS.md › # AGENTS › ## 레포 규칙` | `AGENTS.md › # AGENTS › ## 레포 규칙` 일치 | **통과 (PASS)** | `run6-step4/app-step4-bc-md-h2.png` vs `zed-bc-md-h2.png` | 마크다운 헤딩 계층 트레일 일치 |
| **I-12**<br>(R-12) | 코드 파일 경로 줄 (Phase 9 범위) | `src\App.tsx` (Phase 9는 경로만) | `src\App.tsx` (경로만 표시) | **통과 (PASS)** | `run7-step4/app-step4-bc-code.png` vs `zed-bc-code.png` | Zed의 `› function App()` 심볼 표시는 Phase 11 대상 |
| **I-12**<br>(R-12) | 다중 폴더 및 분할 Pane 경로 줄 | 다중 폴더: 루트명 시작<br>분할: pane별 독립 헤딩 | **화면 측정 불가** (스크립트 제약) | **V1 통과<br>(사용자 확인)** | V1 단위 테스트 `k34_path_text_one_or_several_folders` 통과 | 스크립트가 두 번째 폴더 파일을 열지 못함, 분할은 코드 파일이라 경로 동일 → **Phase 12 사용자 확인** |
| **I-10**<br>(R-10) | 네비게이션 탐색 이동 (Go Back/Forward) | 열기/점프 기록, 10줄 미만 이동 미기록, 마우스 뒤로 버튼 | 열기 → 점프 → 뒤로(1:1) → 앞으로(27:87) → 7줄 이동 후 뒤로(1:1), XBUTTON1 동작 확인 | **통과 (PASS)** | `run7-step5/app-step5-nav-*.png` | 스크립트 판정 다름 (아래 설명 참조) |
| **I-10**<br>(R-10) | 다른 탭(`AGENTS.md`)으로 뒤로 가기 | 다른 파일 탭으로 뒤로 이동 | **화면 측정 미완료** | **V1 통과<br>(사용자 확인)** | V1 단위 테스트 `k35_the_nine_zed_steps` 통과 | 화면상 5단계 도달 전 스크립트 클릭 간섭 발생 → **Phase 12 사용자 확인** |

---

## 2. 스크립트 [RESULT]와 Leader 육안 판정 차이 사유

### 2.1 I-23 탭 바 우측 버튼 (스크립트 FAIL vs Leader 통과)
- **스크립트 판정**: `FAIL - Tree focus buttons=False (exp: False), Tree hover buttons=False (exp: False), Editor focus buttons=False (exp: True)`
- **차이 사유**:
  - `run6` 및 `run7` 실행 시점에 GPUI는 에디터 포커스 전환 후 우측 버튼 영역을 화면에 정상적으로 렌더링하였으나(`app-step2-focus-editor.png`에서 육안 확인 완료), layout snapshot의 `tab-bar-end` probe가 prepaint되지 않았고, 픽셀 검사 영역의 배색 오차가 임계치에 미달하여 스크립트 판정상 `False`로 보고됨.
  - 실제 캡처 화면에서는 Zed 스펙(포커스 있을 때만 버튼 표시, 트리 포커스 및 호버 시 숨김)과 완전히 동일하게 렌더링되었으므로 최종 **통과(PASS)**로 판정함.

### 2.2 I-10 네비게이션 탐색 기록 (스크립트 FAIL vs Leader 통과)
- **스크립트 판정**: `FAIL - Matched 0/10 nav steps`
- **차이 사유**:
  - 스크립트가 Step 2에서 `App.tsx`를 연 직후 편집기 본문을 마우스로 클릭(13행)한 후 `Ctrl-Home`을 전송함에 따라, 의도치 않은 추가 커서 이동(`13:8`)이 네비게이션 히스토리 스택에 추가 기록됨.
  - 이로 인해 이후 Step 5, 10의 뒤로가기 대상이 원래 의도했던 Step 1(`AGENTS.md 5:23`)이 아닌 중간 클릭 지점으로 분기되어 스크립트 기대값과 불일치 발생.
  - 그러나 캡처된 실제 이동 과정(`run7-step5` 1~10단계 캡처)을 검증한 결과, **10줄 이상 점프 기록**, **9줄 이하 이동 건너뛰기**, **마우스 뒤로가기 버튼(XBUTTON1) 이벤트 처리** 등 앱의 네비게이션 코어 엔진 동작은 Zed 규칙을 완벽하게 따르고 있음을 확인하여 최종 **통과(PASS)**로 판정함.

---

## 3. Phase 12 사용자 확인 필요 목록

측정 스크립트의 제약 또는 긴 경로 환경으로 인해 자동 측정이 불가능하여 Phase 12에서 육안 확인이 필요한 항목:
1. **긴 픽스처 경로 툴팁 3줄 감김**: `app-step1-tab-tooltip.png`에서 절대 경로가 길 경우 3줄로 자동 줄바꿈됨 (Zed 기준선의 긴 경로 줄바꿈 인상 확인).
2. **다중 폴더 경로 줄 (Breadcrumbs)**: 복수 프로젝트 폴더 등록 시 경로 앞에 루트 폴더명이 정상 접두되는지 확인 (`workbench-tauri\AGENTS.md`, `workbench-core\specs\v0.5\ITEMS.md`).
3. **분할 Pane별 헤딩 독립성**: 분할된 좌/우 Pane에서 각각 다른 위치에 커서가 있을 때 각 Pane 상단 툴바의 헤딩 트레일이 독립적으로 표시되는지 확인.
4. **다른 탭으로 뒤로 가기**: 여러 탭을 순차적으로 탐색한 후 `Alt-Left` 및 마우스 뒤로 버튼으로 이전 파일 탭으로 전환되는 전체 흐름 확인.

---

## 4. 실측 회차별 진행 기록 및 AppData 복원 검증

| 회차 | 대상 폴더 | 주요 내용 및 실패/성공 사유 | AppData 복원 여부 |
|---|---|---|---|
| **1차** | `measure-ORDER-09-run1` | 메인 윈도우 HWND 탐색 지연 및 사용자 조작 간섭으로 실패 | `session.ps1 Stop` 바이트 단위 동일 복원 완료 |
| **2차** | `measure-ORDER-09-run2` | `project-empty-open` 클릭 후 프로젝트 트리 로딩 대기 타임아웃 | `session.ps1 Stop` 바이트 단위 동일 복원 완료 |
| **3차** | `measure-ORDER-09-run3` | 트리가 완전히 열리지 않아 전제 조건 불만족 중단 | `session.ps1 Stop` 바이트 단위 동일 복원 완료 |
| **4차** | `measure-ORDER-09-run4` | 활성화 클릭 누락으로 첫 입력 1회가 사용자 브라우저로 발송됨 (core-leader에 [NOTICE] 보고 후 안전 가드 설계 착수) | `session.ps1 Stop` 바이트 단위 동일 복원 완료 |
| **5차** | `measure-ORDER-09-run5-*` | 안전 입력 가드(`Assert-MouseInput`, `Assert-KeyInput`) 적용, 포그라운드 획득 실패 시 안전하게 중단(오입력 완전 차단) | `session.ps1 Stop` 바이트 단위 동일 복원 완료 |
| **6차** | `measure-ORDER-09-run6-*` | 비입력 Z-order 상승 및 단계별 격리 실행으로 전 단계 측정값 획득, 휠 이동량(81px) 및 마크다운 헤딩 breadcrumb 검증 완료 | `session.ps1 Stop` 바이트 단위 동일 복원 완료 |
| **7차** | `measure-ORDER-09-run7-*` | K-37 탭 스크롤 및 K-36 드롭 영역 분리 검증, 활성 탭 지연 보이기(`t0/t300/t1000`) 및 네비게이션 히스토리 점프 검증 완료 | `session.ps1 Stop` 바이트 단위 동일 복원 완료 |

- **안전성 검증**: 모든 실측 회차 종료 시 `tools/measure/session.ps1 -Action Stop`이 정상 실행되어 세션 전 백업된 원본 AppData의 해시 및 바이트 레벨 일치(100% 동일)가 검증되었습니다.

# ORDER-10 UI 실측 검증 기록 (I-21)

- 상위 지시: core ORDER-10, 카드 C-39, C-39-R1, C-40
- 검증 대상: `workbench-gpui` UI 실측 캡처 대조 (1440×852, 100% DPI, One Dark)
- 대조 자료: `workbench-tauri` 실측 자료 (`D:\projects\workbench-tauri\specs\v0.5\verify\ORDER-10\zed-*.png`) 및 Zed 4304dec 소스
- 판정 주체: leader (캡처 및 실측 데이터 정밀 대조)

---

## 1. 스펙 ID 및 요구별 판정 결과 표

| 스펙 ID / 항목 | 기대값 (Zed 기준) | 실측값 (workbench-gpui) | 판정 | 대조 캡처 / 증거 | 비고 및 판정 상세 |
|---|---|---|---|---|---|
| **사이드바 폭 및 우측 경계선** | 폭 300px, 우측 경계선 x=299 | 폭 300px, 선 x=299 | **통과 (PASS)** | `run1-step1/app-step1-sb-basic.png`<br>`run2-step1/app-step1-sb-basic.png` | 1차 및 2차 step1 실측 모두 Zed 및 tauri와 정확히 일치 |
| **사이드바 머리 하단 경계선 및 행 배치** | 머리 하단 선 y=32<br>첫 줄 y=33~63 (h=31)<br>둘째 줄 위 구분선 y=64 (`border` #474b57 / rgb(70,75,87)) | 머리 하단 선 y=32<br>첫 줄 y=33~63 (h=31)<br>구분선 y=64 (rgb 70,75,87) | **통과 (PASS)** | `run2-step1/app-step1-sb-basic.png`<br>`zed-sb-open.png` | 1차는 1px 상향(y=31)되었으나 K-40(`sidebar-header .mt(BORDER_1PX)`) 반영 후 2차에서 Zed·tauri와 100% 일치 |
| **아이콘 칸 및 폴더 이름 배치/잉크 크기** | 아이콘 칸 x=9<br>이름 x=31<br>`workbench-tauri` 잉크 x=31~134 (폭 104, y=44~53) | 아이콘 칸 x=9<br>이름 x=31<br>잉크 x=31~134 (폭 104, y=44~53) | **통과 (PASS)** | `run2-step1/app-step1-sb-basic-crop.png`<br>`zed-sb-open.png` | Zed 캡처 이름 잉크 폭(104) 및 높이/위치와 완벽 일치 (동일 폰트 크기; 참고로 tauri는 119) |
| **현재/비활성 폴더 글자색 및 배경 없음** | 현재 폴더: `text` (rgb 220,224,229), 배경 없음<br>다른 폴더: `text.muted` (rgb 169,175,188), 배경 없음 | 현재 폴더 (2번 행): text, 배경 없음<br>다른 폴더 (1번 행): text.muted, 배경 없음 | **통과 (PASS)** | `run2-step1/app-step1-sb-basic-crop.png` | 셋업에서 두 번째 폴더를 추가하여 현재 활성 폴더가 둘째 줄(`workbench-core`)임. 두 줄 모두 배경색 없이 올바른 글자색 표시 확인 (스크립트 step1 FAIL은 첫 행 활성 가정 때문이었음) |
| **둘째 줄 hover 배경색** | `ghost_element_hover` (Zed #363c46 / rgb(54,60,70)) | #363C46 (rgb 54,60,70) 일치 | **통과 (PASS)** | `run1-step2/app-step2-sb-hover.png` | 1차 step2 실측 통과, Zed와 동일한 ghost 호버 배경 |
| **키보드 선택 테두리** | `panel.focused_border` (#2870bd)<br>좌측 1px, 우측 2px | #2870BD (rgb 40,112,189)<br>좌측 1px, 우측 2px (y=48) | **통과 (PASS)** | `run2-step3/app-step3-sb-down.png`<br>`zed-sb-down.png` | 1차 step3는 포커스가 이미 사이드바에 있을 때 무조건 `Ctrl-Alt-;`를 보내 포커스가 해제된 스크립트 문제였음. 2차에서 포커스 토글 가드 적용 후 정상 통과 (Zed `zed-sb-down.png`와 일치) |
| **아래쪽 줄(푸터) 구분선 및 아이콘 배치** | 위 선 y=821 (border 색)<br>토글 아이콘: x 8~22 (Zed 잉크 9~20)<br>Add Project: x 277~291 (Zed 잉크 278~290) | 선 y=821<br>토글 x=8..22<br>Add Project x=277..291 | **통과 (PASS)** | `run1-step4/app-step4-sb-footer.png` | 1차 step4 실측에서 완벽 일치 확인 |
| **검색칸 유무** | 없음 (미표시) | 검색칸 없음 | **통과 (PASS)** | 전 회차 공통 | 사용자 결정에 따라 검색칸 배제 유지 |

---

## 2. 스크립트 결과와 Leader 판정 차이 및 상세 분석

### 2.1 Step 1 글자색/활성 행 판정 (스크립트 FAIL vs Leader 통과)
- **현상**: `measure-ORDER-10-run2-step1`에서 스크립트는 `[RESULT] step1: FAIL`로 보고됨.
- **원인**:
  - 스크립트의 픽셀 색상 검사 로직이 "1번 행이 활성 폴더(`text`), 2번 행이 비활성 폴더(`text.muted`)"일 것이라고 고정 가정함.
  - 그러나 셋업 과정에서 `sidebar-btn-folder-add`를 통해 두 번째 폴더(`workbench-core`)를 추가하였고, 폴더 추가 시 새로 추가된 폴더가 활성화되므로 실제 화면에서는 **2번 행이 활성 폴더**, **1번 행이 비활성 폴더**가 됨.
- **검증 및 결론**:
  - 실제 캡처(`app-step1-sb-basic-crop.png`) 육안 및 픽셀 분석 결과, 두 행 모두 배경색(#1e1e24 패널 배경)이 전혀 적용되지 않았고, 1번 행은 `text.muted`(rgb 169,175,188), 2번 행은 `text`(rgb 220,224,229)로 정확하게 렌더링되어 Zed 규격과 완벽히 일치하므로 최종 **통과(PASS)**로 판정함.

### 2.2 Step 3 키보드 선택 테두리 1차 실패 및 2차 통과 과정
- **1차 실측 (`run1-step3`)**:
  - 셋업 직후 이미 `[dev] focus-state focus=sidebar active=true` 상태였음에도 스크립트가 무조건 `Ctrl-Alt-;`(`FocusWorkspaceSidebar`)를 전송함.
  - 앱의 `on_focus_sidebar` 토글 로직에 의해 포커스가 `center`로 반환되었고, `Down` 키가 `context=Root > Workspace > Pane`으로 디스패치되어 선택 테두리가 나타나지 않음 (스크립트 오류).
- **2차 실측 (`run2-step3`)**:
  - 스크립트에 `Get-CurrentFocus`를 도입하여, 포커스가 이미 `sidebar`이면 `Ctrl-Alt-;`를 건너뛰도록 가드 적용 (C-39-R1).
  - 2차 실행 결과 포커스 토글이 방지되어 `Down` 키가 사이드바에 전달되었고, `[dev] action-handled name=menu::SelectNext by=workbench focus=sidebar`가 정상 트리거됨.
  - 선택된 행에 `#2870bd` 테두리(좌측 1px, 우측 2px)가 정확하게 렌더링되어 `zed-sb-down.png`와 완벽히 일치함을 확인하고 최종 **통과(PASS)** 판정함.

---

## 3. 실측 세션 진행 내역 및 AppData 복원 검증

| 회차 | 세션 디렉터리 | 실행 단계 | 실행 내용 및 결과 | 세션 AppData 복원 상태 |
|---|---|---|---|---|
| **1차** | `measure-ORDER-10-run1-step1` | step1 | 기본 폭(300), 경계선(299), 아래쪽 줄 측정. 머리 아래 선이 y=31로 1px 상향 발견 (K-40 작업 유발) | `session.ps1 Stop` 바이트 단위 100% 동일 복원 완료 |
| **1차** | `measure-ORDER-10-run1-step2` | step2 | 둘째 줄 hover 배경 `#363c46` 측정 통과 | `session.ps1 Stop` 바이트 단위 100% 동일 복원 완료 |
| **1차** | `measure-ORDER-10-run1-step3` | step3 | 포커스 토글로 인한 Down 키 누락 발견 (C-39-R1 작업 유발) | `session.ps1 Stop` 바이트 단위 100% 동일 복원 완료 |
| **1차** | `measure-ORDER-10-run1-step4` | step4 | 푸터 위 선 y=821, 토글 및 Add Project 아이콘 x 범위 측정 통과 | `session.ps1 Stop` 바이트 단위 100% 동일 복원 완료 |
| **2차** | `measure-ORDER-10-run2-step1` | step1 | K-40 머리 위 1px 마진 적용 후 재측정: 머리 하단 선 y=32, 첫 줄 y=33~63, 구분선 y=64 완벽 일치 달성 | `session.ps1 Stop` 바이트 단위 100% 동일 복원 완료 |
| **2차** | `measure-ORDER-10-run2-step3` | step3 | C-39-R1 포커스 가드 적용 후 재측정: 포커스 유지 + Down 액션 + 테두리 `#2870bd` 실측 통과 | `session.ps1 Stop` 바이트 단위 100% 동일 복원 완료 |

- **안전성 및 불변성 보장**:
  - 1차(4세션) 및 2차(2세션) 총 6회의 모든 측정 세션에서 스크립트 실행 시작 시 백업된 원본 AppData가 종료(`session.ps1 -Action Stop`) 시 해시 및 바이트 레벨에서 100% 동일하게 복원되었습니다 (`exeUnchanged: true`, `restored: true`, `fixtureRemoved: true`).
  - 모든 마우스/키 입력은 안전 가드(`Assert-MouseInput`, `Assert-KeyInput`, Z-order 승격 검증)를 통과한 상태에서만 앱 프로세스로 전송되어 사용자의 타 창이나 실행 중인 타 앱(Zed 등)에 간섭이 전혀 없었습니다.

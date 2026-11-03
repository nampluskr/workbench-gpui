# measure-phase1 — P1-E R-9 (덤프 JSON 대 스펙 ID)

- 실행: 2026-11-03, measure. 검증 수준 V3. 빌드 master `1e73c44`(card 기준 `3b26320` 이후), exe SHA-256 `E40C2FDF…23380` 전후 동일.
- 조건: 주 모니터 1920×1080 100%, 최대화(viewport 1920×1032, rem 16, scale 1), 앱 기본 테마. 프로젝트를 열지 않은 첫 화면(빈 사이드바). 허용 오차 `verification.tolerance["dimension"]` ±1.
- 입력: `phase1/layout.json`(`--dev-layout-json`, seq=2: 시작 직후 seq=1은 창이 1536 폭이라 최대화 뒤 스냅숏을 썼다). 체크 목록: `tools/measure/checks-phase1.txt`. 명령: `pwsh -File tools/measure/compare.ps1 -Json specs/v0.3/verify/phase1/layout.json -Checks tools/measure/checks-phase1.txt`.
- 결과: 24개 중 **통과 23, 불일치 1, 측정 불가 0**(체크 목록 안). 불일치는 고치지 않았다.

| spec id | box | expected | tol | actual | diff | verdict |
| --- | --- | --- | --- | --- | --- | --- |
| titlebar["height"] | title-bar.h | 32 | ±1 | 32 | 0 | PASS |
| titlebar["window_button.width"] | window-btn-min.w | 36 | ±1 | 36 | 0 | PASS |
| titlebar["window_button.width"] | window-btn-max.w | 36 | ±1 | 36 | 0 | PASS |
| titlebar["window_button.width"] | window-btn-close.w | 36 | ±1 | 36 | 0 | PASS |
| titlebar["window_button.height"] | window-btn-min.h | 32 | ±1 | 32 | 0 | PASS |
| titlebar["window_button.height"] | window-btn-max.h | 32 | ±1 | 32 | 0 | PASS |
| titlebar["window_button.height"] | window-btn-close.h | 32 | ±1 | 32 | 0 | PASS |
| sidebar["default_width"] | sidebar.w | 300 | ±1 | 375 | 75 | FAIL |
| sidebar["header_height"] | sidebar-header.h | 32 | ±1 | 32 | 0 | PASS |
| sidebar["footer.height"] | sidebar-footer.h | 30 | ±1 | 31 | 1 | PASS |
| sidebar["footer.icon_size"] | sidebar-icon-toggle.w | 14 | ±1 | 14 | 0 | PASS |
| sidebar["footer.icon_size"] | sidebar-icon-folder-add.w | 14 | ±1 | 14 | 0 | PASS |
| dock["resize_handle_width"] | dock-handle.w | 6 | ±1 | 6 | 0 | PASS |
| tab["bar_height"] | tab-bar.h | 32 | ±1 | 32 | 0 | PASS |
| tab["content_height"] | tab-content.h | 31 | ±1 | 31 | 0 | PASS |
| tab["start_slot.width"] | tab-slot-start.w | 12 | ±1 | 12 | 0 | PASS |
| tab["start_slot.height"] | tab-slot-start.h | 12 | ±1 | 12 | 0 | PASS |
| tab["end_slot.width"] | tab-slot-end.w | 14 | ±1 | 14 | 0 | PASS |
| tab["end_slot.height"] | tab-slot-end.h | 14 | ±1 | 14 | 0 | PASS |
| tab["bar_icon_size"] | tab-icon-back.w | 14 | ±1 | 14 | 0 | PASS |
| tab["bar_icon_size"] | tab-icon-new.w | 14 | ±1 | 14 | 0 | PASS |
| statusbar["height"] | status-bar.h | 30 | ±1 | 30 | 0 | PASS |
| statusbar["button_height"] | status-btn-project-panel.h | 22 | ±1 | 22 | 0 | PASS |
| statusbar["icon_size"] | status-icon-project-panel.w | 14 | ±1 | 14 | 0 | PASS |


## 불일치

| 스펙 ID | 기대 | 측정 | 분류 |
| --- | ---: | ---: | --- |
| `sidebar["default_width"]` | 300 | 375 | Q-15 기준선(P0-0c phase3 R-28 375/617과 같은 원인). 리팩토링 전부터 다름 → 스펙 불일치 목록(v0.4 이후) |

## 주석(통과지만 기록)

- `sidebar["footer.height"]` 30 대 31(+1): 허용 오차 안이라 통과. `footer.border_top` 1px가 박스에 들었는지 후속 확인 후보(Q-9 기준선과 같은 항목).

## 측정 불가·범위 밖

- `project_panel["item.height"]`(26) 등 프로젝트 패널 행: 폴더를 열지 않은 첫 화면이라 덤프에 행 박스가 없다. P0-6 S2·S7은 폴더가 열린 상태이므로 별도 측정 목록 필요.
- 메뉴·툴팁·컨텍스트 메뉴(S4~S6), 탭 슬롯 내부(S3)는 이 덤프 범위 밖이다.

## 덤프 박스 이름(57개, seq=2)

active-item, app-menu, app-menu-button, body, center, dock, dock-handle, project-empty-open, project-empty-text, sidebar, sidebar-btn-folder-add, sidebar-btn-toggle, sidebar-footer, sidebar-footer-left, sidebar-footer-left-placeholder, sidebar-footer-right, sidebar-header, sidebar-icon-folder-add, sidebar-icon-toggle, sidebar-list, status-bar, status-btn-project-panel, status-cursor, status-icon-project-panel, status-left, status-left-placeholder, status-right, status-right-placeholder, tab, tab-bar, tab-bar-end, tab-bar-filler, tab-bar-start, tab-btn-back, tab-btn-forward, tab-btn-new, tab-btn-split, tab-btn-zoom, tab-content, tab-icon-back, tab-icon-forward, tab-icon-new, tab-icon-split, tab-icon-zoom, tab-label, tab-slot-end, tab-slot-start, title-bar, title-bar-drag, title-folder-name, title-left, window-btn-close, window-btn-max, window-btn-min, window-controls, work-area, workspace
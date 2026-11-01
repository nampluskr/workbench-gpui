# R-5 대조표: 화면 단축키 / 키맵 적용 결과 (v0.2 Phase 2)

생성: tools/verify-v02-phase2.ps1, 2026-11-01 14:27.

- **화면**: 앱이 그린 단축키 글자(`[dev] tooltip-shown rows=`, `[dev] menu-render rows=`). `<none>` 은 단축키 없이 제목만(L-223).
- **키맵 적용 결과**: 같은 실행의 `[dev] display seq=<최신> where=center` 줄(gpui `highest_precedence_binding_for_action_in`, I-704: 가려진 키 제외, 남은 것 중 마지막, L-219~L-221 형식). 메뉴는 메뉴를 열기 직전 포커스(가운데 Pane)의 컨텍스트, 툴팁은 지금 포커스(가운데 Pane)의 컨텍스트다(I-307, L-201).
- **01-zed 원문**: 02 8.2절·9.2절의 키 열. v0.2 에 그 동작이 없는 항목은 키맵에 바인딩이 없어 화면에 단축키가 없다(R-7 설명).

| 사례 | 위치 | 문구 | 액션 | 화면 | 키맵 적용 결과 | 01-zed 원문 | 판정 | 증거 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| shadow | 메뉴 View (ctrl-b 를 Minimize 로 덮음) | Toggle Left Dock | `workspace::ToggleLeftDock` | `Ctrl-B` | `<none>` | 가려짐 → 없음 | 불일치 | shadow-menu.png |
| shadow | 메뉴 View (ctrl-b 를 Minimize 로 덮음) | Project Panel | `project_panel::ToggleFocus` | `Ctrl-Shift-E` | `Ctrl-Shift-E` | 가려짐 → 없음 | 일치 | shadow-menu.png |
| shadow | 툴팁 status-btn-project-panel (ctrl-b 를 Minimize 로 덮음) | Close Left Dock | `workspace::ToggleLeftDock` | `Ctrl-B` | `<none>` | 가려짐 → 없음 | 불일치 | shadow-tooltip.png |

- 줄 3개, 불일치 2개.

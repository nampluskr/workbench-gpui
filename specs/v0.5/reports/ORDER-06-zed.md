# ORDER-06-zed — Zed "v" 메뉴 확인 (gpui)

조건: Zed `zed -n` 새 창, 클라이언트 1440×852, 100%, Zed 커밋 기준 앱(설치본). 사용자 Zed 설정 파일은 실행 전후 해시가 같다(`settings.json` SHA-256 C3D27B05…, `keymap.json` 없음). 상세: `specs/v0.5/verify/reviews/zed-ORDER-06.md`, 캡처 `specs/v0.5/verify/reviews/measure-ORDER-06-run2/zed-v-menu.png`, `zed-v-panel-layout.png`.

## 여섯 항목
| 순서 | 항목 | 단축키 표시 | 여는 것 | gpui 직접 확인 |
|---|---|---|---|---|
| 1 | Settings | Ctrl-, | **별도 OS 창** | 확인함(Ctrl-, 로 열림, 창이 사용자 Zed 프로세스 안에 생김) |
| 2 | Keymap | Ctrl-K Ctrl-S | 편집 영역 새 탭 "Keymap Editor" | 캡처 못 함 — tauri 보고 근거 |
| 3 | Themes… | Ctrl-K Ctrl-T | 모달 선택기 "Select Theme…" | 캡처 못 함 — tauri 보고 근거 |
| 4 | Icon Themes… | (없음) | 모달 선택기 "Select Icon Theme…" | 캡처 못 함 — tauri 보고 근거 |
| 5 | Extensions | Ctrl-Shift-X | 편집 영역 새 탭 "Extensions"(온라인 목록) | 캡처 못 함 — tauri 보고 근거 |
| — | (구분선) | | | |
| 6 | Panel Layout ▸ | | 하위 메뉴: Classic, Agentic, Custom(배치가 둘 다 아닐 때 체크·비활성) | 캡처함(항목은 누르지 않음) |

v 버튼: 타이틀 바 오른쪽 최소화 앞, ChevronDown 아이콘(캡처 `zed-v-menu.png`).

## 각 화면의 구성·동작·저장 위치
gpui 세션은 Settings 창이 열리는 것까지만 직접 확인했다. Keymap·Themes·Icon Themes·Extensions 화면 구성과 저장 위치는 tauri가 확인한 `D:\projects\workbench-tauri\specs\v0.5\reports\ORDER-06-zed.md`를 근거로 한다(core-leader가 그 보고로 ORDER-06-R1·D-15를 정했다). 지어낸 내용은 넣지 않았다.

## 확인하지 못한 이유
- 첫 실행(07:32)은 측정 스크립트가 세션 시작 직후 멈췄다(앱이 출력 파이프를 물려받음). Zed는 띄우지 않았다.
- 둘째 실행(07:54)은 v 메뉴·Panel Layout까지 캡처했고, 나머지 다섯 단계는 스크립트 오류(StrictMode `.Count`)로 실패했다. 그 과정에서 Ctrl-, 로 열린 **Zed Settings 창이 사용자 Zed 프로세스(PID 20788) 안에** 남았다. 사용자 원래 창은 그대로였고 설정 파일은 바뀌지 않았다. leader가 그 창만 닫으려 했으나 이 세션 자동 모드가 거부해, core-leader를 통해 사용자에게 닫아 달라고 알렸다.
- 이후 core 결정(사용자 Zed를 다시 열지 않음)에 따라 다시 재지 않았다.

[DONE] ORDER-06-R1 gpui        (화면 조작 확인 4건 측정 불가 — V1 근거, 아래)

## 완료 기준
| 항목 | 판정 방법 요약 | 결과 | 근거 |
|---|---|---|---|
| 1 Settings | 별도 창, 검색·범주 Appearance·범위 User·Edit in settings.json·행 4개(Zed 문구), 즉시 저장·적용 | 충족(창 틀·치수 V3, 창 안 조작은 V1) | 창 900×750(SPEC R-2 Zed 실측, tauri 측정값 사용) PASS, 위 정렬·v 버튼 22×22 고침(K-16). 파일 `%APPDATA%\workbench-gpui\settings.json`(Zed 형식, 키 theme·icon_theme·ui_font_size·buffer_font_size, 없으면 상수 기본값). 저장은 바뀐 키만·JSONC 주석·다른 키 보존·잘못된 키만 기본값+알림(core 결정) — `cargo test settings::tests` 4 PASS. 창 안 검색·숫자 입력·Edit in settings.json 버튼은 **측정 불가**(측정 스크립트 입력이 별도 Settings 창에 전달되지 않음, 캡처 해시 불변·창 캡처 exit=1). 1차 실행에서 주석·다른 키 보존은 화면으로도 확인(값 입력만 미전달) |
| 1 Keymap | 새 탭 Keymap Editor, 필터·Edit in JSON·Create Keybinding, 열 5개, 저장·즉시 적용 | 충족 | 2차 실행: 열기·필터·바인딩 생성 → `keymap.json` 저장 확인, 재실행 유지 PASS. 저장은 Zed keymap.json 형식, 주석·다른 내용 보존(바뀐 키는 null 해제 + override 섹션 — `shortcut:` 주석: 반복 수정 시 섹션 누적, 정리 기능은 다음) |
| 1 Extensions | 새 탭, 검색·All/Installed/Not Installed·칩 All/Themes/Icon Themes·카드, 앱 자원만, 온라인·설치 없음 | 충족 | 3차 실행: 탭·칩 전환·검색 PASS. 지금 목록 Default Light(테마)·Zed (Default)(아이콘 테마) — Phase 7에서 늘어남. 버전·작성자 없는 것은 비움 |
| 1 Panel Layout | Classic만(체크), dock 열기+기본 폭, Custom(체크·비활성) | 충족 | 2차 PASS(dock 닫기 → Custom → Classic → 복원). dock 기본 폭 상수는 `specs/v0.5/cards/K-11.report.md` |
| 2.5 Editor Layout | View → Editor Layout 하위 메뉴에 Split 네 항목 | 충족(코드), 화면 **측정 불가** | 메뉴 정의·단축키 표시 `cargo test app_menu::tests` PASS. 하위 메뉴 열림 캡처는 hover 입력 미전달로 해시 불변 |
| 2 저장·재실행 유지 | V1 + V3 | 충족 | 재실행 유지 PASS(2차). V1 settings·keymap 테스트 |
| 3 두 갈래 표 | 같음 | 충족(차이 목록) | SPEC R-2·R-17. tauri와 다른 곳은 `specs/v0.5/cards/W-22.report.md`·`W-23.report.md` |
| 4 Zed와 같은 틀 | 1440×852·100% 캡처 | 충족(Settings는 tauri의 Zed 캡처 실측값 사용 — core 결정, Zed 다시 열지 않음) | 판정 `specs/v0.5/verify/reviews/measure-ORDER-06-R1.md` |

ORDER-06 1단계 연계: 메뉴 키를 Zed `default-windows.json` 기준으로(K-12, 메뉴엔 첫 키, Close Editor `Ctrl-W`), 메뉴 이름 잉크 간격 13px(Zed 13~14) PASS, v 버튼 22×22·chevron 잉크 8 PASS, Licenses = 앱에 들어간 자원 전부(K-13), 탭 순환 화면 확인 PASS(2차).

## 측정 불가 4건 (이유)
Settings 창 안 검색, 숫자 입력 저장, Edit in settings.json 버튼, View → Editor Layout 하위 메뉴 열림 — leader가 실행한 SendInput 스크립트의 입력이 별도 Settings 창·하위 메뉴 hover에 전달되지 않았다(3회 시도, 캡처 해시 불변). 동작은 V1 테스트와 코드 리뷰(C-24·C-26 PASS)로만 확인. Phase 12 사용자 확인(V4)으로 넘기기를 제안한다.

## 바꾼 파일
- 새: `src/ui/settings.rs`, `src/ui/keymap_editor.rs`, `src/ui/extensions.rs`; 고침: `src/keymap/{builtin,file,mod}.rs`, `src/ui/{app_menu,keymap,metrics,mod,pane,pane_group,pane_view,panel_nav,tab_close,tab_input,title_bar}.rs`; 도구 `tools/measure/order06-r1-v3.ps1`; 문서·측정.
- 커밋: 이 보고와 같은 커밋. push 없음.

## 검토
- checker: C-24(K-11) PASS, C-26(K-12~K-15) PASS, C-27·C-28 V3 판정. 커밋 전 전체 `cargo test` 225 passed / 0 failed, clippy 경고 0.
- 사용자 데이터: 세 번 실행 모두 전후 `%APPDATA%\workbench-gpui\state.json` 동일, settings.json·keymap.json 원래 상태(없음)로 복원.
- Codex 한도: 한 번 소진 → 사용자 쿠폰 → 지금 사용 중. D-16(소진 시 Sonnet 5.5 high로 교체)은 HERDR-SETUP·PROGRESS에 기록.
- 앞 커밋(c723b7e)에 측정 폴더의 사용자 앱 데이터 백업이 들어갔던 것을 push 전에 amend로 빼고 `.gitignore`에 넣었다.

## 사용자 확인 필요(V4)
- Settings 창 안 조작(검색·값 변경·Edit in settings.json), Editor Layout 하위 메뉴 열림(측정 불가분).
- 글꼴 크기 변경 뒤 렌더링 인상.

## BLOCKED
없음

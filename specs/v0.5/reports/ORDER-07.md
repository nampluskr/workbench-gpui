[DONE] ORDER-07 gpui        (Zed 트리 아이콘 화면 비교 1건 측정 불가 — 아래)

## 완료 기준
| 항목 | 판정 방법 요약 | 결과 | 측정값·근거 |
|---|---|---|---|
| 1 문서·복사본 | 출처·두는 곳·라이선스·다시 채우기·없을 때 모습, 복사본 미커밋 | 충족 | 아래 "복사본 출처". `git ls-files resources/zed-themes resources/zed-icon-themes` 0행 |
| 2 I-4 테마 | 2장 테마 전부, 미리 보기·Esc 복원·저장, 색 대조(V2), One Dark Zed 대조(V3) | 충족 | 선택기(검색·목록·체크) 열림·Down 미리 보기·Esc 복원 캡처 PASS(4차). 저장은 `settings.json` `theme`(K-13 방식, 바뀐 키만). V2: 캡처 6개 테마(One Dark·One Light·Ayu Dark·Gruvbox·Catppuccin·macOS Classic) 주요 자리 픽셀 = JSON 토큰, 21개 전체 테마 토큰 대응은 V1 테스트(불일치 0). V3: One Dark 앱 vs Zed `zed -n` 캡처 같은 자리 PASS. 선택기 틀 Zed 실측 너비 544·검색 38·목록 384(12행)·간격 0 → K-21로 맞춘 뒤 0px 일치 |
| 3 I-3 아이콘 테마 | 목록 전부, 트리 아이콘 변경, Zed Catppuccin Latte 대조 | 충족(Zed 화면 대조 1건 측정 불가) | 목록 9개(Zed (Default) + Catppuccin 4 + Monochrome 4), Catppuccin Latte 적용 뒤 앱 트리 아이콘 캡처 PASS. 대응은 테마 JSON 기준(V1 `cargo test icon_theme` 5종, 5,248 SVG 존재). Zed 트리 화면 비교는 **측정 불가**(5차 Zed 단독 실행이 fixture 폴더를 앱 단계에서만 만들어 시작 전 종료) |
| 4 기본값 | settings.json 없으면 One Dark·Zed (Default) | 충족 | 4차 첫 캡처(app-default-onedark) PASS, V1 테스트 |
| 5 연결 | v 메뉴·Settings·Extensions | 충족 | v Themes…·Icon Themes… 활성, Settings 드롭다운 전체 목록(선택기와 같은 값), Extensions는 `extension.toml` 있는 확장 3개만 카드(core 결정) |
| 6 앞 Phase 그대로 | 테마를 바꿔도 깨지지 않음 | 충족 | 대표 테마 6개 캡처에서 글꼴·아이콘·메뉴·창 정상 |

core 공통 결정 반영(K-22): 탭 파일 아이콘 없음(Zed tabs.file_icons=false), 토큰 대체 순서 JSON → T-26 → 같은 appearance One → 고정값, 목록 순서 dark 이름순 → light 이름순, 선택기 스크롤바는 목록 위 포인터일 때만. 선택기 치수 spec ID는 writer가 `spec/zed-metrics.toml`에 추가(W-30, ID 목록 `specs/v0.5/cards/W-30.report.md` — tauri 참조용).

## 복사본 출처
| 묶음 | 출처 | 두는 곳 | 라이선스 |
|---|---|---|---|
| Zed 기본 테마(Ayu·Gruvbox·One) | `zed-industries/zed` `4304dec732a75505066de5ce2dbbfb2bec369498` `assets/themes/` | `resources/zed-themes/` | `assets/themes/LICENSES` |
| Catppuccin | `catppuccin/zed` 태그 v0.2.27 | `resources/zed-themes/` | 저장소 LICENSE(MIT) |
| macOS Classic | `huacnlee/zed-theme-macos-classic` 태그 v0.4.0 | `resources/zed-themes/` | 저장소 LICENSE(MIT) |
| Catppuccin Icons | `catppuccin/zed-icons` 태그 v1.24.0 | `resources/zed-icon-themes/` | 저장소 LICENSE(MIT) |
| Zed (Default) 아이콘 | Phase 5 복사본 `resources/zed-icons/file_icons/` + 같은 커밋의 확장자 대응(데이터) | — | Phase 5와 같음 |
버전은 이 PC 설치 확장 `extension.toml`(읽기만)과 같다. 다시 채우기: `pwsh -NoProfile -File tools/fetch-zed-themes.ps1`(+ `fetch-zed-icons.ps1`). 복사본이 없으면 gpui-kit 기본 테마로 뜨고 시작 때 경고 한 번(앱 안 죽음, V1 테스트). 둘 다 `.gitignore`, 커밋 안 함. 앱은 실행 중 Zed 설치 폴더를 읽지 않는다.

## 바꾼 파일
- 새: `src/ui/theme_selector.rs`, `src/ui/icon_theme.rs`, `tools/fetch-zed-themes.ps1`, `tools/measure/order07-v3.ps1`; 고침: `src/ui/{theme,settings,extensions,zed_icons,panel_view,app_menu,keymap,metrics,mod,title_bar}.rs`, `tools/measure/session.ps1`·`order0x-*.ps1`(C-30 세션 보호), `.gitignore`, `spec/zed-metrics.toml`·`spec/INDEX.md`(W-30), 문서.
- 커밋: 이 보고와 같은 커밋. push 없음.

## 검토
- checker: C-31(K-19·K-20 리뷰 PASS), C-32 판정. 커밋 전 전체 `cargo test` 247 passed / 0 failed, clippy 0.
- 측정 세션 보호(core 추가 지시 b, C-30): 앱이 떠 있으면 백업·초기화를 시작하지 않음, 실패 시 원래 데이터로 롤백, 백업 폴더는 바이트 동일 복원 확인 뒤에만 정리, checker는 session.ps1을 실행하지 않음. 그럼에도 1차 실행(13:02)에서 스크립트가 session.json에 없는 hwnd를 읽고 그 줄이 try 밖이라 복원이 안 돼, leader가 측정 앱만 닫고 복원했다(바이트 동일). 이후 모든 예외를 finally에서 복원하게 고쳤고 2~5차는 매번 전후 동일 확인. 사용자 Zed 설정 해시·창은 모든 실행에서 불변.
- coder: Codex 한도 소진으로 12:14 Sonnet 5.5 high로 교체(D-16, K-20 수행), 14:05 Codex GPT-6.1-Sol medium으로 되돌림(사용자 결정) — HERDR-SETUP·PROGRESS 기록.
- ORDER-06-R2 남은 V3: Keymap Editor hover(Edit 열·`<no arguments>`·`<global>`)·Extensions·v 버튼 캡처 PASS(3·4차).

## 사용자 확인 필요(V4)
- 테마·아이콘 테마 인상, Catppuccin 컬러·Monochrome 아이콘 대비, 미리 보기 중 깜박임. Zed 트리 아이콘 화면 비교(측정 불가분).

## BLOCKED
없음

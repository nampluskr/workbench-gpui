[DONE] ORDER-08 gpui        (미리보기 클릭 위치·Replace 뒤 dirty는 화면 측정 불가 — V1 테스트, 사용자 확인 필요)

## 완료 기준
| 항목 | 판정 방법 요약 | 결과 | 측정값·근거 |
|---|---|---|---|
| 1 I-5 상태 바 줄:열·파일 형식 | `{line}:{column}`와 파일 형식, 선택 표시, 탭 없을 때 | 충족 | Zed처럼 두 항목: `5:11 (5 characters)`와 `Markdown` 사이 19 = Zed 19(3차 run3 `app-step3-selection.png`). 열은 Unicode 스칼라 기준, 활성 선택만(다중 선택은 core 결정대로 제한, K-24 보고). 파일 형식 rs·json·jsonc(tsconfig.json)·ts·txt 캡처(2차). 대응 표는 SPEC R-5(tauri Zed 확인을 옮김, W-34) |
| 1 I-5 미리보기 클릭 | 누른 곳을 포함하는 가장 안쪽 블록의 원본 시작 줄, 열 1(core 결정) | 충족(화면 측정 불가) | vendor gpui-base 콜백(core D-14 확장, `vendor/gpui-base/PATCHES.md`)과 V1 테스트(K-24). 덤프에 블록 probe가 없어 화면 클릭 측정은 하지 않음 |
| 1 I-19 켜짐 표시 | dock·sidebar 켜짐 accent, 닫으면 복원 | 충족 | `text.accent` 켜짐(K-23-R1), dock·sidebar 열기/닫기 캡처(2차 step6) |
| 1 I-22 왼쪽 버튼·구분선 | 순서 sidebar \| file_tree \| search·diagnostics, 구분선, 툴팁 | 충족 | 버튼 박스 x 4·33·64·94 = Zed 4·33·64·94(2차 덤프, 아이콘 박스 8·37·68·98 폭 14). 구분선 x 28·59(폭 1, 높이 16, border). padding_x 4·toggle_gap 2·진단 앞 보이지 않는 lsp_button 자리 gap 4(K-26·K-26-R1, core [ANSWER]). 툴팁 `Project Search Ctrl-Shift-F` 위치·문구 Zed 캡처와 같음. 버튼 표는 SPEC R-22(tauri와 같은 표) |
| 1 I-22 Project Search | 검색·결과 수·결과 열기, Replace는 누르지 않음 | 충족 | 툴바·입력 끝 1167=Zed, 글자 시작 292/291, 뒤 아이콘 잉크 x 1181·1205·1242·1263·1285 대 Zed 1179·1204·1242·1263·1283(≤2), 결과 머리 띠 전체 폭·`Open File Alt-Enter` 오른쪽 끝, 빈 화면 세로 잉크 y와 부제 폭 251 Zed와 같음(5차). 상한 파일 5,000·일치 10,000(tauri와 같음). **Replace는 열린 버퍼만 바꾸고 저장하지 않음(Zed와 같음, K-29)** — 디스크 불변 V1 테스트, 화면에서는 누르지 않음 |
| 1 I-22 Diagnostics | 탭·툴바·문구 | 충족 | 툴바 아이콘 x 1344·1370·1396·1422 대 Zed 1343·1369·1395·1421, `No problems in workspace` y 465/466(±1) |
| 2 Zed 확인 결과 | 보고에 적기, 탭 없을 때 표시 | 충족 | Zed 확인은 tauri의 확인을 SPEC R-5·R-19·R-22에 옮겨 썼다(W-34, 차이 목록 `specs/v0.5/cards/W-34.report.md`). **열린 탭이 없을 때 Zed 상태 바: 오른쪽의 위치·파일 형식 둘 다 보이지 않는다**(SPEC R-5, gpui도 같음 — 1·2차 step1 캡처) |
| 3 앞 Phase 그대로 | | 충족 | 전체 `cargo test` 261 passed / 0 failed, clippy 0(C-35-R1). 캡처에서 창·메뉴·트리·탭 정상 |

## spec 추가(writer, core 지시)
- `statusbar.padding_x` 4, `statusbar.toggle_gap` 2, `statusbar.left_divider.*`(W-33·W-36).
- tauri R-22 "toml에 없는 값" 11개를 tauri와 글자까지 같은 ID로(W-38): `editor.search_input.max_width`, `search_results.header.{padding,padding_left,padding_right,gap,radius,fold_button,lines}`, `search_results.matches.padding_left`, `search_results.count.min_width`, L-84 `titlebar.window_button.close.{hover_background,hover_foreground,active_opacity}`. gpui 상수 11개 모두 같은 값. `header.radius` 2는 소스 직접 확인 못 함 → `spec/ambiguous.md` 6절.
- 빈 화면 크기(core [DECISION], Zed 4304dec 소스): `project_search.landing.{heading_size 16, subtitle_size 14, subtitle_margin_bottom 8, action_label_size 14, key_size 14, gap 4}`(W-39). 4차에서 캡처가 ≈13px로 보인다고 한 것은 leader 비교 오류였다 — 소스 14로 되돌린 5차 캡처가 Zed와 폭·위치 모두 같다(W-40에서 SPEC·ambiguous 고침).
- 캡처에 맞춘 값(소스 값 없음): 검색 오른쪽 여백 112, 토글 사이 2, 매치 영역 앞 1 — 주석에 "Zed capture 1440×852, desktop_measure_100". 다른 창 크기에서는 다를 수 있다.

## crate·라이선스
- `ignore = "=0.4.34"`, `regex = "=1.13.1"`(core 승인, tauri와 같은 기능에 같은 버전). `Cargo.lock`은 이미 있던 같은 버전이라 2줄만 바뀜. Licenses 창·`resources/licenses/{ignore,regex}/` 반영, DECISIONS 기록.

## 바꾼 파일
- 새: `src/ui/{status,status_languages,project_search,search_view}.rs`, `resources/licenses/{ignore,regex}/`, `tools/measure/order08-v3.ps1`·`order08-zed.ps1`.
- 고침: `src/ui/{layout,metrics,mod,app_menu,markdown_preview,pane_group,pane_view,folders,keymap,keymap_editor}.rs`, `src/keymap/*`, `vendor/gpui-base/src/text/*`·`PATCHES.md`, `Cargo.toml`·`Cargo.lock`, `spec/*`, 문서.
- 커밋 `e1b8c0f`. push 없음.

## 검토·측정
- checker: C-34(리뷰 REWORK → K-25-R1 Licenses 테스트), C-35·C-35-R1 PASS. 측정표 `specs/v0.5/verify/reviews/measure-ORDER-08.md`.
- V3 1~5차(16:29·16:43·16:54·17:03·17:12): 1차는 스크립트 버그(box 이름·트리 위치·인자)로 대부분 측정 불가 → C-34-R2·R3로 고침. 모든 회차 사용자 앱 데이터 바이트 동일 복원, 남은 앱 프로세스 없음, 사용자 Zed(18016·20788)와 settings.json 불변. Zed는 띄우지 않고 tauri 캡처로 대조.
- leader 실수 1건: 16:40경 원인 조사 중 `session.ps1 -WhatIf`를 직접 실행해 실제 세션이 시작됨(PID 13080). 즉시 그 PID만 닫고 같은 세션 Stop으로 복원, 바이트 동일 확인(PROGRESS 기록).
- coder: Codex 5h 한도 5% 미만으로 15:52 Sonnet 5.5 high로 교체(D-16, HERDR-SETUP·PROGRESS 기록). 되돌림은 한도 초기화 뒤 카드 경계.

## 사용자 확인 필요(V4)
- Replace Next·Replace All 뒤 탭이 수정됨 표시이고 디스크 파일이 그대로인지(화면 측정에서 Replace를 누르지 않음).
- 미리보기에서 목록·코드 블록·인용 클릭 뒤 커서 위치.
- 검색 툴바 아이콘(‹ › 겹 chevron, 필터 줄 두 아이콘) 인상, 다른 창 크기에서 검색 입력 폭.

## BLOCKED
없음

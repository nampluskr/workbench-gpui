[DONE] ORDER-03 gpui        (I-14의 5자리 줄 번호 열 1건은 측정 불가 — 아래)

## 완료 기준
| 항목 | 판정 방법 요약 | 결과(충족/미충족/BLOCKED/이미 같음) | 측정값·캡처 경로 |
|---|---|---|---|
| I-14 | 글꼴 이름·크기·굵기·줄 높이(V2), D-10 파일 커밋, 한글 고딕(V3), 줄 번호 열 폭, 미리보기 코드 16/1.618 | 충족 (5자리 줄 번호 열만 측정 불가) | 본문 Lilex 15·줄 간격 24px(Zed 24px), 한글 고딕(Zed와 같은 모양), 미리보기 본문 Plex Sans 16·제목 600, 코드 Lilex 16·줄 간격 25.83px(Zed 25.89), UI Plex Sans 잘림 없음, 4자리 이하 줄 번호 열: 숫자 끝 57px·본문 92px(Zed 56/91, 기준 57/92 ±1). 5자리(66/101): **측정 불가** — 캡처 시점에 657KB 문서가 로드되지 않아 줄 번호 1만 보임. 코드 기대값은 K-07 단위 테스트로만 확인. 표: `specs/v0.5/verify/reviews/measure-ORDER-03.md` 1~9행 |
| I-7 | 분할 pane마다 경계 한 줄·직각, Zed와 같음 | 충족 | 1px 한 줄, 곡률 0. `measure-ORDER-03/crops/i7_app_split_divider_mid_mag.png`, `i7_app_single_corner_mag.png`, Zed `i7_zed_split_divider_mid_mag.png` |
| I-8 | 마크다운 긴 줄 줄바꿈, 가로 스크롤바 없음 | 이미 같음(확인) | `crops/i8_softwrap_paragraph.png`, `i8_no_horizontal_scrollbar.png` |
| I-9 | (기대 정정) 세로 스크롤바 늘 보임, 가로는 넘칠 때만 | 충족 | 창 밖·휠 직후·4초 뒤 모두 엄지 보임, 폭 15px(Zed 15px). `crops/i9_app-S-8-*.png`, `i9_zed-S-8-*.png` |
| I-13 | 커서 줄 배경·줄 번호 강조, soft wrap 줄 전체, 커서 따라 이동 | 충족 | 배경 One Light `#ebebecbf`(합성 #f0f0f1), soft wrap 12.5줄 전체 강조, 이동 확인, 줄 번호 현재 `#44454b`·나머지 `#b4b4bb`(core D-14). `crops/i13_cursor_line.png`, `i13_cursor_softwrap.png` |

캡처 위치: 앱·Zed 본 실행 `specs/v0.5/verify/reviews/measure-ORDER-03/`(03:20), 남은 2항목 `measure-ORDER-03-extra/`(04:18), S-1·S-2·S-3 단일 `measure-ORDER-03-run5-aborted/`(03:03). 측정 조건: 1920×1080, 100%, 앱·Zed 클라이언트 1440×852. 테마: 앱 gpui-component Default Light, Zed One Dark(색 항목은 테마 값과 비교, 테마 맞춤은 Phase 7).

## Zed에서 확인한 것
- I-9: 세로 스크롤바 엄지가 창 밖·호버·휠 직후·멈춘 뒤 4초·다시 창 밖 모두 보임, 숨김 없음(leader 입력, checker 판정 C-09; `specs/v0.5/verify/reviews/zed-ORDER-03.md`). PrintWindow 캡처는 DirectComposition 오버레이를 빠뜨려 처음엔 "안 보임"으로 잘못 보였다 → 화면 확인은 Screen 캡처를 쓴다. core가 ITEMS I-9 기대를 정정(두 갈래 같은 결과).
- I-14 한글: Zed는 DirectWrite 시스템 대체로 한글을 그린다(dwrite.dll 로드 확인). 고딕 계열, Malgun Gothic으로 판단. 갈래 앱도 대체 순서 끝을 Malgun Gothic으로 두었다. 확인 방법: 같은 문장 영역의 앱·Zed 캡처 픽셀 대조(`crops/korean_sentence_app.png`, `korean_sentence_zed.png`). 별도 DirectWrite 대체 결과 로그는 만들지 않았다.
- 줄 번호 열: Zed 4자리 숫자 끝 56px·본문 91px(이 측정), tauri 실측 57/92·66/101과 ±1px.
- Zed 미리보기 코드 블록: Lilex 16px, 줄 간격 25.89px.

## 글꼴 파일 (D-10)
- `resources/fonts/ibm-plex-sans/IBMPlexSans-{Regular,Italic,SemiBold,SemiBoldItalic}.ttf`, `license.txt` — IBM Plex Sans `@ibm/plex-sans@1.1.0`, https://github.com/IBM/plex/releases/download/%40ibm/plex-sans%401.1.0/ibm-plex-sans.zip (SIL OFL 1.1)
- `resources/fonts/lilex/Lilex-{Regular,Bold,Italic,BoldItalic}.ttf`, `OFL.txt` — Lilex `2.630`, https://github.com/mishamyrt/Lilex/releases/download/2.630/Lilex.zip, OFL은 같은 태그의 raw `OFL.txt` (SIL OFL 1.1)
- Zed 앱 저장소에서 복사하지 않았다. 파일 구성은 Zed와 같다(T-15.1·T-15.2).

## 바꾼 파일
- 글꼴(I-14): `src/ui/fonts.rs`(새), `src/ui/mod.rs`, `src/ui/metrics.rs`, `src/ui/markdown_preview.rs`(제목 600, 코드 16/1.618), `src/ui/editor_poc.rs`, `src/ui/tooltip.rs`, `resources/fonts/`. UI 16은 rem 기준값으로 해석(core-leader 결정), 요소별 크기 14/12는 그대로.
- I-7·I-9·I-13: `src/ui/pane.rs`(Editor 자체 테두리·radius 끔, 편집 영역 스크롤바 `Always`), `src/ui/theme.rs`(현재 줄 배경, 줄 번호 색).
- core D-14: `vendor/gpui-base/`(0.8.1 복사, 3개 파일 수정: `src/lib.rs`, `src/theme.rs`, `src/input/base/element.rs` — 최소 4자리, 좌 22·우 29 여백, 줄 번호 색 두 개를 테마 Global로), `vendor/gpui-base/PATCHES.md`(원본과의 diff·이유), LICENSE 포함, `Cargo.toml` `[patch.crates-io]`, `Cargo.lock`. checker가 원본 218개 파일과 해시 대조: 수정 3개 외 동일.
- 측정 도구(checker): `tools/measure/order03-v3.ps1`(새), `tools/measure/session.ps1`(fixture 매개변수, PID 기준 확인), `tools/measure/window-rect.ps1`(TargetHwnd 스코프 버그 수정).
- 문서: `specs/v0.5/{SPEC,DECISIONS,PLAN,PROGRESS,HERDR-SETUP}.md`, `.gitignore`(`_measure-*-backup/`), 카드 `specs/v0.5/cards/K-03~K-07·C-08~C-16·W-11~W-15`, 측정 기록 `specs/v0.5/verify/reviews/`(재생성되는 657KB 5자리 fixture는 커밋하지 않음).
- 커밋: 이 보고와 같은 커밋(`git log -1 -- specs/v0.5/reports/ORDER-03.md`). push 없음.

## 검토
- checker 리뷰: C-10(K-03·K-03-R1·K-04-R1) PASS, C-11(K-05) PASS, C-14(K-06-R1·K-07, vendor 해시 대조) PASS. 지적 없음.
- V1·V2: 카드별 관련 테스트·clippy 통과. 커밋 전 전체 `cargo test` 210 passed / 0 failed, `cargo clippy --all-targets -- -D warnings` 경고 0.
- V3: `specs/v0.5/verify/reviews/measure-ORDER-03.md` 통과 18/19, 측정 불가 1, 불일치 0.
- 과정에서 생긴 일(PROGRESS에 기록): V3 스크립트가 다섯 번 중간에 멈췄다(창 크기 버그, 프로젝트 열기, 행 선택, 런타임 오류, 분할 메뉴). 이후 dry-run·항목 독립 실행으로 바꿨다. checker가 C-08에서 이미 열려 있던 Zed 창을 닫았고, V3 스크립트가 `zed -a`로 사용자 Zed 창에 fixture 탭을 하나 더했다(둘 다 즉시 보고, 이후 `zed -n` 자기 창만·PID 기준 종료로 고침). checker가 5자리 줄 번호 열을 처음에 코드 근거로 PASS로 적었다가 leader 지적으로 측정 불가로 고쳤다. `/clear` 뒤 Codex 모델이 기본값으로 돌아간 일이 다시 없도록 매번 `/model`로 Sol medium을 다시 골랐다.

## 사용자 확인 필요(V4)
- I-14 글자 모양 인상(Plex Sans·Lilex·한글 Malgun Gothic 렌더링).
- I-13 현재 줄 강조 대비(One Light 배경 #ebebecbf).

## BLOCKED
없음. 남은 것: 5자리 줄 번호 열(66/101) 화면 실측 1건 — 큰 문서 로드 뒤 캡처하도록 고친 뒤 다음 화면 차례에 잴 수 있다(코드 기대값은 K-07 테스트로 확인). 필요하면 지시해 달라.

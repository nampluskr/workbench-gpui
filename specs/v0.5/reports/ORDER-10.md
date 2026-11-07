[DONE] ORDER-10 gpui

## 완료 기준
| 항목 | 판정 방법 요약 | 결과 | 측정값·캡처 경로 |
|---|---|---|---|
| 1 I-21 폭 | Zed 사이드바와 1px 이내 | 충족(이미 같음) | 300, 오른쪽 선 x 299 = Zed(`zed-sb-open.png`). toml `sidebar.default_width` 300. core 정정대로 Zed 폭은 300(220 아님) |
| 1 I-21 줄·여백 | 높이·안쪽 여백 | 충족 | 머리 아래 선 y 32, 첫 줄 y 33~63(31), 둘째 줄 위 선 y 64 — Zed·tauri와 같음(2차 `measure-ORDER-10-run2-step1`). 1차는 머리가 1px 짧아 모두 1px 위 → K-40(Zed `sidebar.rs:7391-7399` 서버 장식 위 margin 1px)으로 고침. 왼 8·오른 6, 테두리 1(오른쪽 2) 평소 투명 |
| 1 I-21 아이콘과 이름 간격 | 1px 이내 | 충족(소스 기준) | 아이콘 칸 x 9(칸 16 안에 아이콘 14), 이름 x 31 = 간격 6(4 → 6, K-39). Zed 묶음 머리에는 아이콘이 없어 tauri와 같이 thread_item.rs 291·461 기준 |
| 1 I-21 선택 표시 | 배경·윤곽선·색이 같은 테마 토큰 | 충족 | 현재 폴더 글자 `text` (220,224,229), 다른 폴더 `text.muted` (169,175,188), **배경 없음**(옅은 파란 배경 제거). 키보드 선택(사이드바 포커스 + 커서 줄) 테두리 `panel.focused_border` `#2870bd` 왼 1·오른 2 = Zed(`zed-sb-down.png`, 2차 step3). hover `ghost_element_hover` `#363c46` = Zed(1차 step2). 누름 `ghost_element_active`(소스 기준). 둘째 줄부터 위 1px `border` 선 |
| 1 글자 크기 | 같음 | 충족 | 이름 `workbench-tauri` 잉크 x 31~134 폭 104·y 44~53 = Zed 캡처 이름 잉크 폭 104·y 44~53 |
| 1 검색칸 없음 | 없음 | 충족(이미 같음) | 사용자 결정 |
| 1 아래쪽 줄 | Zed 아래쪽 줄과 같음 | 충족(이미 같음) | 위 선 y 821, 토글 x 8~22(Zed 잉크 9~20), Add Project x 277~291(Zed 278~290)(1차 step4) |
| 2 내용·순서·동작 | V1 테스트 그대로 | 충족 | 폴더 목록·순서·추가·제거·전환·키 처리 불변(C-40 리뷰). 바뀐 것은 스타일·테마 색뿐 |
| 3 두 갈래 치수 표 | 같음 | 충족(아래 다른 점 2) | SPEC R-21에 tauri 표를 옮기고 우리 toml ID를 붙임(W-46). 치수 값은 tauri 표와 같음 |
| 4 앞 Phase | 결과 유지 | 충족 | 전체 `cargo test` 282 passed / 0 failed, clippy 0(C-40 PASS) |

## 두 갈래가 다른 점(core 확인)
- **사이드바 이름 글자 크기**: 같은 Zed 캡처(tauri `zed-sb-open.png`)에서 이름 `workbench-tauri` 잉크 폭은 104px(x 9~112). gpui 104(같음), tauri 119(`tauri-two-idle.png` x 31~149). tauri 보고의 "Zed 120"은 이 캡처에서 104로 잰다(밝기 합 >330 잉크 범위). core에 [NOTICE]로 알림.
- **`panel.focused_border` 라이트 대체값**: gpui는 Zed 소스 라이트 기본값 `#0588f0`(`default_colors.rs` 98, toml src 문구), tauri는 `border.focused`. 다크는 둘 다 `#2870bd`. 라이트 값을 toml ID로 둘지는 정해지지 않음(W-45 제안).

## spec·toml
- W-45(ORDER-09 중 core 지시): `sidebar.item.border_right_width` 2·`separator_width` 1·`icon_slot_size` 16·`icon_gap` 6, `panel.focused_border` #2870bd(옛 #62adef는 ambiguous). 섹션 이름 때문에 전체 ID 앞부분이 tauri 임시 ID와 다른 표는 `cards/W-45.report.md`.
- W-46: SPEC R-21에 tauri Zed 확인 표, 220 → 300 정정.
- `src/ui/theme.rs`: panel과 pane 대체값을 나눔 — panel은 #2870bd/#0588f0, pane(편집 영역 포커스 테두리)은 #62adef 그대로(범위 밖).

## 바꾼 파일
- 고침: `src/ui/{folders,layout,metrics,theme}.rs`, `spec/*`(W-45), `specs/v0.5/{SPEC,PROGRESS}.md`.
- 새: `tools/measure/order10-v3.ps1`(order09의 입력 가드·단계별 세션·dry-run 모의 실행 틀).

## 검토·측정
- checker: C-39·C-39-R1(측정 스크립트), C-40(리뷰 PASS·전체 테스트). 측정표 `specs/v0.5/verify/reviews/measure-ORDER-10.md`.
- V3 1차(4세션)·2차(2세션): 모두 띄운 PID만 닫고 앱 데이터 바이트 동일 복원, 남은 앱 없음, 사용자 Zed(18016·20788)·settings.json 불변, 입력 가드(다른 창 입력 없음). Zed는 띄우지 않고 tauri Zed 캡처로 대조. 시작·끝은 core 알림만(사용자 부재, core 허가).
- 1차 step3는 스크립트 문제(셋업 뒤 이미 사이드바 포커스인데 `Ctrl-Alt-;`를 보내 토글로 빠짐) — C-39-R1로 포커스 확인 뒤 보내게 고쳐 2차에 측정. 스크립트 step1 `[RESULT]` FAIL은 "현재 폴더가 첫 줄" 가정 때문(셋업이 둘째 폴더를 추가해 현재 폴더가 둘째 줄) — 값은 모두 같음, 측정표에 사유.

## 사용자 확인 필요(V4)
- 라이트 테마에서 사이드바 키보드 선택 테두리 색(#0588f0) 인상.
- 누름(ghost_element_active) 색은 화면 측정 안 함.

## BLOCKED
없음

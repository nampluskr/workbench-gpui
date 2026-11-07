[DONE] ORDER-09 gpui        (폴더 둘·분할 경로 줄, 다른 탭으로 뒤로 가기는 화면 측정 못 함 — V1 테스트, Phase 12 사용자 확인)

## 완료 기준
| 항목 | 판정 방법 요약 | 결과 | 측정값·근거 |
|---|---|---|---|
| 1 I-10 뒤로·앞으로 | pane별 기록, 버튼·키·마우스, 비었을 때 흐림 | 충족 | 7차(`measure-ORDER-09-run7-step5`): App.tsx 열기 1:1 → PageDown 27:87 → 뒤로 1:1 → 앞으로 27:87 → 7줄 이동 뒤 뒤로 1:1(10줄 미만 기록 안 함, Zed 9단계 표와 같은 규칙), 마우스 뒤로(XBUTTON1) 동작, 기록 없을 때 두 버튼 흐림. 규칙은 tauri·C-36 Zed 소스와 같음: pane별, 탭 떠날 때·10줄 이상(`MIN_NAVIGATION_HISTORY_ROW_DELTA`), 명시적 점프(Project Search 결과 열기) 항상, 같은 자리 중복 제거, 새 기록이 앞 스택 비움, 상한 1024, 닫힌 탭 다시 열기(K-35, V1 `k35_the_nine_zed_steps` 등 10개). 키 `alt-left`·`alt--` / `alt-right`·`alt-=`, 툴팁 "Go Back Alt-Left"·"Go Forward Alt-Right". 스크립트가 App.tsx를 연 뒤 편집기를 클릭(13행)하고 Ctrl-Home 해 13:8이 기록에 하나 더 들어갔고(앱은 10줄 이상 이동이라 Zed대로 기록) 그래서 스크립트 표의 5·10단계 기대값과 달랐다 |
| 2 I-11 탭 툴팁 | 파일 절대 경로 | 충족 | 4·6차 `app-step1-tab-tooltip.png`: `D:\…\workbench-tauri\AGENTS.md`, 역슬래시 `\`(I-20), 위치 Zed `zed-tip-tab.png`와 같음. 경로 없는 탭(Project Search·Diagnostics·미리보기)은 Zed 확인이 없어 툴팁 없음 |
| 3 I-12 경로 줄 | 경로 + 마크다운 제목 계층(Phase 9 범위) | 충족(일부 화면 측정 못 함) | 폴더 하나 마크다운 1행 `AGENTS.md › # AGENTS`, 5행 `AGENTS.md › # AGENTS › ## 레포 규칙` — 글자·`›` placeholder 색·제목 문법 색·위치가 Zed `zed-a-start.png`·`zed-bc-md-h2.png`와 같음(6차). 코드 파일 `src\App.tsx`는 경로만(7차). **폴더 둘·분할 pane별 제목은 화면 측정 못 함**(측정 스크립트가 두 번째 폴더의 파일을 열지 못함, 분할은 코드 파일이라 같은 경로) — V1 테스트(K-34 `path_text` 폴더 하나/둘, `heading_trail`)만, Phase 12 사용자 확인 |
| 3a Zed가 코드 파일에 보이는 것 | 보고에 적기 | — | Zed: `src\App.tsx › function App()`(66행, 커서를 포함한 심볼 계층, 문법 색), 심볼 밖(1행)은 경로만 `src\App.tsx`(tauri 캡처 `D:\projects\workbench-tauri\specs\v0.5\verify\ORDER-09\zed-bc-code.png`, SPEC R-12). **코드 파일 심볼 계층은 Phase 11에서 마무리**(core [DECISION]). 이 레포 Phase 9는 경로만 |
| 4 I-16 탭 넘침 | 스크롤·잘림·활성 탭 보이기 | 충족 | 탭은 원래 폭, 좌우 잘림, 화살표·스크롤바 없음. 뒤로·앞으로·오른쪽 버튼 고정. 휠 한 칸 81px(6차 캡처 열 프로필, Zed 약 80). 끝 빈 자리 0(K-36: Zed처럼 드롭 자리를 스크롤 행 안에, `pane.rs:3721-3728`). 연 직후 활성 탭 보임(K-37 뒤 7차 `active-t0/t300/t1000`). `Ctrl-PageUp`으로 첫 탭 활성·보임(7차). 새 탭은 활성 탭 바로 오른쪽(이미 그랬음) |
| 5 I-23 오른쪽 버튼 | pane 포커스 때만 | 충족 | 트리 포커스 때 없음(7차 `app-step2-focus-panel.png`), 트리 포커스 + 탭 바 hover 때도 없음, 편집기 포커스 때 보임(6차 `app-step2-focus-editor.png`). 단일 pane 예외 삭제(K-32). 뒤로·앞으로는 늘 보임 |
| 6 I-20 역슬래시 | `\` 그대로 | 충족 | 탭 툴팁·경로 줄 모두 `\`(`src\App.tsx`, `workbench-core\specs\v0.5\ITEMS.md` 형식) |
| 7 앞 Phase 그대로 | | 충족 | 전체 `cargo test` 279 passed / 0 failed, clippy 0(C-38). 리뷰 PASS(`specs/v0.5/verify/reviews/C-38.md`) |

## core 지시 반영(ORDER-09 중)
- 휠 한 칸: 캡처 값 80 → Zed 소스 공식 3줄 × 창 줄 높이(16 × 1.618)로(K-38, tauri와 같게). gpui가 픽셀 줄 높이를 반올림(26)해 이 버전에서 78px. toml `tab["scroll.wheel_step"]` 77.7(W-45).
- tauri ORDER-10 R-21 값 toml 등록(W-45): `sidebar.item.border_right_width` 2, `separator_width` 1, `icon_slot_size` 16, `icon_gap` 6(섹션 이름 때문에 전체 ID 앞부분이 tauri와 다른 점은 `cards/W-45.report.md` 표), `panel.focused_border` 다크 `#2870bd`(옛 `#62adef`는 ambiguous로), 라이트 `#0588f0`(Zed `default_colors.rs` 98, src 문구에만 — 라이트 값 ID 형식은 정해지지 않음). `src/ui/theme.rs:71`의 대체값 `0x62adef`는 사이드바 범위라 ORDER-10에서 맞춘다.
- coder: 19:27 Codex GPT-6.1-Sol medium으로 되돌림(사용자 지시, HERDR-SETUP·PROGRESS).

## 다른 갈래와 다른 점
- 폴더 밖 파일의 경로 줄: 이 앱은 파일 이름만, tauri는 전체 경로. Zed 4304dec 소스 대조(C-38): 폴더 밖 파일은 단일 파일 워크트리라 파일 이름만 — 이 앱이 Zed와 같다.

## 바꾼 파일
- 새: `src/ui/{breadcrumb,nav_history}.rs`, `tools/measure/order09-v3.ps1`.
- 고침: `src/ui/{layout,pane_view,pane,pane_group,mod,keymap,app_menu,search_view,metrics,theme}.rs`, `src/keymap/{mod,builtin}.rs`, `spec/*`, 문서.

## 검토·측정
- checker: C-36(Zed 소스), C-37~C-37-R5(측정 스크립트), C-38(리뷰 PASS·전체 테스트). 측정표 `specs/v0.5/verify/reviews/measure-ORDER-09.md`.
- V3 1~7차, 모두 앱 데이터 바이트 동일 복원, 남은 앱 프로세스 없음, 사용자 Zed(18016·20788)·settings.json 불변, Zed는 띄우지 않고 tauri 캡처로 대조:
  - 1차(창 못 찾음 — 사용자 화면 조작), 2·3차(폴더 열기 호출 형식·첫 스냅샷 대기 버그로 측정 0), 4차(셋업 성공, 단계 간 메뉴가 남아 4·5단계 무효).
  - **4차 사고: step5 마지막 마우스 뒤로 입력 한 번이 앱이 아니라 사용자 브라우저로 갔다**(캡처에 웹 페이지가 찍힘, core-leader가 사용자에게 알림). 그 캡처는 커밋하지 않았다. 이후 core 규칙대로 **입력 가드**: 마우스는 그 점의 창이 띄운 PID 창일 때만, 키는 앞 창이 앱일 때만, 아니면 입력하지 않고 그 단계 중단. 단계 시작에 Esc·메뉴 닫힘 확인, 단계마다 새 세션.
  - 5차(Windows foreground lock으로 가드가 입력을 막아 측정 0 — 다른 창 입력 0건), 6·7차 측정(위 표).
  - 스크립트의 `[RESULT]` 일부는 probe(gpui 스크롤 행 안 probe가 덤프에 비거나 갱신되지 않음, K-37 보고)·픽셀 검사 오류로 틀렸다 — 판정은 leader가 캡처로 했고 측정표에 차이와 사유를 적었다.

## 사용자 확인 필요(Phase 12)
- 폴더 둘일 때 경로 줄(`workbench-tauri\AGENTS.md › # AGENTS`, `workbench-core\specs\v0.5\ITEMS.md › # ITEMS — workbench-core v0.5`).
- 분할 두 pane이 각자 커서 기준 제목을 보이는지.
- 다른 탭으로 뒤로 가기(App.tsx → AGENTS.md)와 닫은 탭 다시 열기.
- 긴 경로 탭 툴팁이 여러 줄로 감기는 모양(Zed 캡처는 짧은 경로라 비교 못 함).

## BLOCKED
없음

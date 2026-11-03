# P0-4 완료 보고 (impl-ui, 2026-11-03)

> 원문: herdr pane `impl-ui`(wE:p1) 화면에서 lead가 옮겨 적었다. 줄바꿈은 터미널 폭 때문에 생긴 것이다.

```text
  [DONE] P0-4
  • 변경: 없음(코드 수정 없음). git status 깨끗함.
  • 환경: worktree D:/projects/workbench-gpui/.
  worktrees/ui, 브랜치 work/ui.
      • cargo build는 공유 CARGO_TARGET_DIR로
      통과했다(30.8초, Finished).
      • apply-manifest.ps1는 -Exe
      D:\projects\workbench-gpui\target\debug\workbench
      -gpui.exe를 넘겨야 통과한다. 세
      항목(commonControlsV6, perMonitorV2,
      longPathAware)이 모두 true다.
      • -Exe 없이 실행하면 기본값이 worktree 상대 경로
      target\debug\...라서 Resolve-Path가 실패한다.
      공유 target을 쓰기 때문이며, 이미 AGENTS.md에
      적힌 규칙이다.
  • 재사용: 해당 없음
  • 생략: 없음
  • 검증 수준: V0
  • 확인: 위 빌드·매니페스트 실행. 모듈 구조와 반복
  패턴은 코드 읽기와 검색으로 확인했다.
  • 실측 필요: 없음
  • 사용자 확인 필요: 없음
  ## 모듈 구조 요약(담당 범위, 줄 수)
  • src/main.rs(14): 진입점. dev::DevOptions를 거쳐
  ui::run을 호출한다.
  • src/fsops/(약 1,000줄)
      • ops.rs 289: 복사·이동·삭제.
      • tree.rs 253, names.rs 170, ident.rs 105, list.
      rs 90, paths.rs 54.
      • watch.rs 369: 순수 로직.
      • 헬퍼는 ui에 의존하지 않는다.
  • src/keymap/(약 590줄): builtin 114, display 150,
  file 242(jsonc), mod 82.
  • src/state/(약 750줄): mod.rs 384(state.json
  저장·읽기), path 197, time 56, win 111.
  • src/ui/ 담당분: 아래 표와 같다.
   역할           │ 파일(줄 수)
  ────────────────┼────────────────────────────────────
   Workbench 루트 │ mod.rs 723(공통, 제외)
   화면           │ layout 408, shell 33, title_bar
                  │ 210, pane 108
   메뉴·툴팁      │ app_menu 902, context_menu 457,
                  │ tooltip 248
   프로젝트 패널  │ folders 968, project_panel 188,
                  │ panel_view 377, panel_nav 473,
                  │ panel_edit 371, panel_ops 247,
                  │ panel_delete 200, panel_menu 288,
                  │ task_dialog 195
   감시           │ watch 476, watch_io 421
   키맵           │ keymap 526
   개발용         │ editor_poc 439

  • 공통 모듈(metrics, rem, layout_probe)은 수정 대상이
  아니다.
  • impl Workbench는 mod.rs에 있고,
  panel_*·watch*·keymap이 같은 impl을 파일별로 나눠
  확장한다.
  ## 반복 스타일 체인·비슷한 컴포넌트

  1. 앱 메뉴와 컨텍스트 메뉴(app_menu.rs:694–788,
  context_menu.rs:240–323)
      • 구분선(div().my(SEPARATOR_MARGIN_Y).h(px(1.)).
      w_full().bg(border))이 app_menu.rs:708와
      context_menu.rs:258에 똑같이 있다.
      • tooltip.rs:206에도 w_full().h(px(1.)).
      bg(border) 구분선이 있다.
      • 행 padding·margin·글자와 팝업 테두리·그림자도
      반복된다.
      • context_menu는 app_menu의 pub(super) 상수를
      가져다 쓴다.
  2. chord 대기 상태(app_menu.rs:505–668, context_menu.
  rs:334–449): 접두 보관, 1초 CHORD_TIMEOUT, 50ms
  SHORTCUT_FLASH, 세대 token이 복제돼 있다.
  3. 같은 값의 로컬 상수 중복
      • 메뉴와 툴팁이 같은 값을 각자 정의한다. 값은
      같지만 스펙 ID가 다를 수 있어 합치지 않는다.
       항목                  │ app_menu   │ tooltip
      ───────────────────────┼────────────┼────────────
       팝업 둥글림(RADIUS)   │ 8          │ 8
       단축키                │ 16         │ 16
       간격(SHORTCUT_GAP)    │            │
       글자 크기             │ ROW_TEXT   │ TEXT_SIZE
                             │ 14         │ 14
      • 프로젝트 패널은 panel_view의 ROW_PAD_X 6,
      ROW_GAP 4, BANNER_*가 로컬 상수다. 메뉴의
      ROW_PAD_X 6과 이름이 겹친다.
  4. 프로젝트 패널 안내 화면 두 개(folders.rs:829–868):
  같은 바탕 스타일이 두 분기에 있다.
  5. 밀리초 로그 시각 함수: app_menu.rs:260,
  context_menu.rs:452, tooltip.rs:105.
  ## AUDIT 채택 항목 5~11 대조
  • 위치는 대체로 맞다. 줄 번호는 app_menu 상수 38–65,
  panel_view 34–53, tooltip 28–44, title_bar 83·105
  모두 확인했다.
  • 감사가 놓쳤거나 보충할 것:
      • (항목 11) 밀리초 시각 함수가 하나 더 있다.
      src/ui/watch.rs:106의 SystemTime::now().
      duration_since(UNIX_EPOCH)...unwrap_or(0)이다.
      감사는 "watch의 별도 epoch 형식"이라고 짧게
      언급했는데, 이것을 가리키는 것으로 보인다. 같은
      계산이지만 반환형(u128)이 다를 수 있어 합치려면
      확인이 필요하다.
      • (항목 6) src/ui/watch.rs의 TICK 100ms,
      TICK_LATE 250ms와 folders.rs:27의 SAVE_DEBOUNCE
      500ms, panel_view.rs:53의 NAME_TOOLTIP_DELAY
      1500ms도 로컬 상수다. 감사 목록에는 시간 상수가
      app_menu와 tooltip만 언급돼 있다.
      • (항목 6) panel_view.rs의 INDENT: f32 = 20.과
      GUIDE_OFFSET: f32 = 15.은 rem 헬퍼를 거치지 않는
      raw f32다. app_menu의 ROW_LINE_HEIGHT 1.618과
      MAX_HEIGHT_RATIO 0.75도 같다. 감사가 말한 "ID
      대응 점검" 대상이다.
      • (항목 6) panel_view.rs:332의 .w(px(1.))(트리
      가이드선)와 panel_menu.rs:221–222의 px(2.)
      오프셋이 있다. panel_menu는 감사에 있다. 가이드선
      폭은 감사에 없다.
      • (항목 5) 감사는 title_bar.rs:31–34, 198–205를
      지적했다. title_bar.rs:200에서 white()도 직접
      쓴다. 테마를 거치지 않는 색이라 함께 처리해야
      한다.
      • (항목 7) .text_sm()·.text_xs()는 folders.
      rs:762,825,835,855, layout.rs:175,205,381,
      title_bar.rs:106, panel_view.rs:309다. 감사
      위치와 일치한다. 추가 누락은 없다.
  • 감사가 언급하지 않은 점: pane.rs, task_dialog.rs,
  panel_delete.rs, panel_edit.rs에서는 스타일 리터럴
  중복이 거의 보이지 않는다. 이 파일들은 Phase 2·3의
  우선순위가 낮다. 반복 리터럴 개수 검색에서도 이
  파일들은 0이었다.

  ## 스펙 불일치

  이번 카드에서는 스펙 값을 대조하지 않았다.

  lead의 작업 지시를 기다린다. 백그라운드 작업은 남아
  있지 않다.

```

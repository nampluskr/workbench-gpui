> 버전: v0.2 · 작성일: 2026-11-01 · 상태: 진행 중
>
> 실제로 한 일과 검증 결과를 기록한다. 계획은 `PLAN.md`에, 요구는 `SPEC.md`에 있다. 검증 보고서는 `specs/v0.2/verify/`에 있다.

# PROGRESS — workbench-gpui v0.2

## Phase별 진행

### Phase 1 — 키맵 로더·액션·컨텍스트

- **G-105 키맵 엔진 확인** (2026-11-01)
  - 무엇을 했나: gpui-pre 0.3.10 소스(`src/gpui.rs`, `src/keymap.rs`, `src/keymap/context.rs`, `src/keymap/binding.rs`, `src/action.rs`)와 gpui-kit 0.8.1 `src/lib.rs` 를 읽어, `KeyBindingContextPredicate` 공개 여부와 `null` 해제를 gpui 로 표현하는 방법을 확인했다.
  - 결과:
    - 공개 여부: 공개다. `gpui.rs` 가 `pub use keymap::*;` 로 내보내고, `keymap.rs` 가 `pub use context::*;` 로 `KeyBindingContextPredicate`(`context.rs` 의 `pub enum`)를 내보낸다. gpui-kit 은 `use gpui_kit::*;` 가 gpui 전체라(lib.rs 문서), `gpui_kit::KeyBindingContextPredicate` 로 쓸 수 있다. `parse`·`depth_of`·`eval`·`is_superset` 이 공개다.
    - `null` 해제: gpui 의 `NoAction`(`action.rs` 의 `pub use no_action::{NoAction, Unbind, is_no_action, is_unbind}`)으로 표현한다. 사용자 키맵에서 값이 `null` 인 키는 같은 키·같은 컨텍스트로 `KeyBinding::load(키, Box::new(NoAction), 조건식, …)` 을 묶는다. `Keymap::bindings_for_input` 은 일치한 바인딩을 깊이 → 등록 순서로 정렬한 뒤, 가장 앞선 `NoAction` 보다 등급(`KeyBindingMetaIndex`, 작을수록 강함, meta 없음 = 0)이 같거나 약한 바인딩을 뺀다. 그래서 내장 바인딩에 약한 meta 를, 사용자 바인딩에 강한 meta 를 주면 I-703 의 "사용자 > 기본" 등급과 같다.
    - 충돌 규칙: `bindings_for_input` 정렬이 "일치한 컨텍스트 깊이 큰 쪽 먼저, 같으면 나중 등록 먼저"이고, 컨텍스트 없는 바인딩은 가장 깊은 것으로 본다(`binding_enabled`). I-702 와 같다.
    - 표시용 조회: `Keymap::bindings_for_action`(해제된 것 제외, 나중 것이 우선), `Window::highest_precedence_binding_for_action(_in)`, `Keymap::bindings()`(전체, 등록 순서)가 공개다. 바인딩 전체 출력은 `cx.key_bindings().borrow().bindings()` 로 키(`keystrokes()`)·조건식(`predicate()`)·액션(`action().name()`)을 꺼낼 수 있다.
    - 액션 정의: gpui-kit 0.8.1 이 `gpui_kit::actions!` 매크로를 따로 둔다(gpui 원래 매크로는 `gpui::Action` 경로라 gpui-kit 만 의존하면 안 풀린다고 lib.rs 가 적었다). 이름으로 액션 만들기는 `App::build_action(이름, 인수)` 다.
  - 검증: 소스 읽기(위 파일). 실행 확인은 R-2 시험에서 한다.
  - 특이사항: gpui-component 0.8.1 이 `gpui_kit::init` 때 자기 바인딩을 넣는다(예: `PopupMenu` 컨텍스트의 enter·escape·up·down·left·right). 바인딩 전체 출력에는 이것도 함께 나온다.

- **새 크레이트 추가** (2026-11-01)
  - 무엇을 했나: `Cargo.toml` 에 D-4·D-6 의 크레이트를 넣었다. `serde_json = "=1.0.154"`, `jsonc-parser = "=0.34.0"`(feature `serde`), `dirs = "=7.0.0"`, `notify = "8.2"`(잠금 8.2.1, gpui-component 와 같은 판).
  - 결과: `Cargo.toml`, `Cargo.lock`.
  - 검증: `cargo add` 와 `cargo fetch` 성공.
  - 특이사항: 결정이 더 필요해 구현은 멈췄다(아래 "구현 보류").

- **구현 보류: 결정 질문** (2026-11-01)
  - 무엇을 했나: 원문만으로 정할 수 없는 것 다섯 가지를 leader 에게 물었다(keymap.json 읽기 오류 알림 문구, 문서에 이름이 없는 액션의 이름, `menu` 컨텍스트와 gpui-kit `PopupMenu` 의 관계, 사이드바 컨텍스트 이름, 화면·동작이 아직 없는 R-3·R-4 의 Phase 1 판정 범위).
  - 결과: leader 가 다섯 가지 모두 추천안 (a)로 답했다(docs/HERDR-DECISIONS.md D-027). `DECISIONS.md` 의 D-2·D-3·D-5·D-14 에 "이후 변경"으로 덧붙였고, 미결 사항의 G-105 를 지웠다(결과는 위 "G-105 키맵 엔진 확인", D-3 이후 변경).
  - 검증: `DECISIONS.md` 를 다시 읽어 확인했다.
  - 특이사항: 없음.

- **키맵 로더·액션·컨텍스트 구현 (R-1~R-4)** (2026-11-01)
  - 무엇을 했나:
    - `src/keymap/`(gpui 없는 부분): `builtin.rs` 내장 키맵 표 52줄(01-zed 1절·I-517·A-13.1·A-17 에서 v0.2 동작만, 근거 ID 포함), `file.rs` keymap.json 읽기(jsonc-parser, 주석·끝 쉼표만 허용, 오류는 파일에 나온 순서대로), `display.rs` 표시 문자열(L-219 순서 Fn → Ctrl → Win → Alt → Shift, L-220 키 이름, L-221 chord), `mod.rs` 액션 이름 33개 목록.
    - `src/ui/keymap.rs`: `gpui_kit::actions!` 로 액션 정의. 층은 gpui-kit 바인딩 → 내장(등급 3) → 사용자(등급 0) 순서다. `null` 은 `NoAction` 이다. 다시 읽을 때는 처음에 받아 둔 gpui-kit 바인딩을 다시 넣는다. notify 로 `%APPDATA%\workbench-gpui\` 폴더를 감시하고, 150ms 동안 잠잠해지면 다시 읽는다. 오류는 gpui-kit notification 하나에 줄로 잇는다. 화면 동작이 아직 없는 액션에는 자리 처리기를 붙였다. 처리기가 없으면 gpui 가 다음 순위 바인딩으로 넘어가 우선순위를 판정할 수 없기 때문이다.
    - `src/ui/mod.rs`: 창 루트에 `Workspace`, 사이드바 자리에 `Sidebar`+포커스, Dock(프로젝트 패널 자리)에 `ProjectPanel menu not_editing`+포커스, 가운데 Pane 자리에 포커스를 달았다. 포커스 자리를 바꾸는 최소 동작을 넣었다. Ctrl-Shift-E 는 패널 ↔ 가운데, Ctrl-Alt-; 는 사이드바 ↔ 가운데, Ctrl-B 는 Dock 열기·닫기다. A-17.1·A-17.2·I-098~I-100 의 이전 포커스 복귀는 Phase 3(R-16)에서 한다.
    - `src/dev.rs`: `--dev-keymap`(디버그 빌드 전용). 바인딩 전체(키·컨텍스트·액션·출처), 내장 표, 알림 문구를 출력한다. 다음 프레임에 자리별 액션 표시 문자열(gpui `highest_precedence_binding_for_action_in`, I-704 가려짐 반영)도 낸다. 키 입력마다 실행된 액션과 컨텍스트, 처리기도 출력한다.
  - 결과: `cargo build` 경고 0, `cargo test` 17개 통과(기존 dev 4개, 새 키맵 13개). 빌드 뒤 `tools/apply-manifest.ps1` 를 실행했고 세 항목이 모두 true 다.
  - 검증: `tools/verify-v02-phase1.ps1` 의 8개 사례 모두 실패 0(구현 당시. 리뷰 1회차에서 startup 사례를 더해 9개가 되었고, 그 뒤 실행도 실패 0 이다). 증거는 `specs/v0.2/verify/phase1/`(EVIDENCE.md, r1-bindings.md, results.json, 사례별 stdout·keymap.json, 알림 스크린샷 2장)에 있다.
    - R-1: 기대 60줄 모두 일치하고, 표 밖 내장 바인딩은 0이다.
    - R-2: 덮어쓰기, `null` 해제, 없는 액션 이름(알림 `Action 'workspace::NoSuchAction' not found`·`Action 'zed::Unknown' not found` 두 줄, 나머지 적용), 주석·끝 쉼표, 형식 오류(`Failed to load keymap file`, 내장 키맵 유지).
    - R-3: Delete 가 사이드바 = `project_panel::RemoveFromProject`, 패널 = `project_panel::Trash`, 가운데 = 없음. 패널 Ctrl-N = `project_panel::NewFile`. 같은 깊이 두 번 묶으면 나중 것이 이기고, 깊이가 다르면 깊은 쪽이 이긴다.
    - R-4: 제자리 덮어쓰기와 바꿔치기 저장 모두 다시 읽었다(약 1.4초, 스크립트 폴링 포함). 새 키가 실행되고, 옛 키는 듣지 않으며, 표시 문자열이 `Ctrl-B` → `Alt-B` → `Ctrl-Alt-B` 로 바뀐다.
  - 특이사항:
    - **Phase 2~4 에서 다시 판정한다(D-027 ⑤).** R-3 의 실제 결과(사이드바 등록 해제·휴지통·루트 Delete 무동작, 디스크·목록 상태)는 Phase 3·4 에서, R-4 의 ☰ 메뉴·툴팁 화면 표시는 Phase 2 에서 다시 판정한다. Phase 1 은 dev 출력의 "실행된 액션 이름"과 "액션별 표시 문자열"로 판정했다.
    - **우리가 지은 액션 이름(D-2 이후 변경, D-027 ②), 16개:** `app_menu::Toggle`, `menu::SelectNext`, `menu::SelectPrevious`, `menu::SelectFirst`, `menu::SelectLast`, `menu::Cancel`, `menu::SelectChild`, `menu::SelectParent`, `project_panel::CollapseSelectedEntry`, `project_panel::ExpandSelectedEntry`, `project_panel::CollapseAllEntries`, `project_panel::ExpandAllEntries`, `project_panel::Open`, `project_panel::DeployContextMenu`, `project_panel::SelectPreviousExtend`, `project_panel::SelectNextExtend`. (`src/keymap/mod.rs` `ACTIONS` 의 두 번째 값이 true 인 것.) 나머지 17개는 01-zed·02-gpui 에 나온 이름이다.
    - keymap.json 해석에서 원문에 없어 정한 것: 빈 파일과 없는 파일은 오류 없이 사용자 바인딩 0개다. 인수가 있는 꼴(`["이름", {..}]`), 틀린 컨텍스트 조건식, 틀린 키 표기, 객체가 아닌 항목은 그 항목만 `Failed to load keymap file` 한 줄로 알린다. UTF-8 BOM 은 받는다. `context`·`bindings` 밖의 필드는 무시한다.
    - Phase 2 에 넘길 것: 표시는 자리별로 고르므로, 패널에서 `menu::Confirm` 은 Enter 가 Rename 에 가려 표시가 없다. `project_panel::Trash` 는 `Backspace`, `project_panel::Rename` 은 `F2` 다(나중 바인딩 우선, I-704). 메뉴 화면에서 01-zed 의 표시 키와 맞는지는 Phase 2 R-5 에서 대조한다. gpui-component `Tree`(Phase 4 D-8)가 자기 `Tree` 컨텍스트에 up·down·left·right 를 묶는다. 트리를 넣을 때 우리 `ProjectPanel` 바인딩과의 깊이를 확인해야 한다.
    - gpui 는 Alt 조합 뒤에 수식키만 누른 `keystroke=alt`(액션 없음)를 따로 낸다. 검증 스크립트는 이 줄을 판정에서 뺀다.
    - 이 PC 에서는 Ctrl-Shift-B 를 SendInput 으로 보내면 앱에 키 이벤트가 오지 않았다. 다른 프로그램의 전역 단축키로 보이지만 원인은 확인하지 않았다. R-4 시험 키는 Alt-B·Ctrl-Alt-B 를 썼다.
    - 검증 스크립트는 시작 전에 앱이 실행 중이면 멈춘다. PID·HWND 를 고정하고, 키마다 전면 창을 확인한다. 기존 keymap.json 은 백업했다가 되돌린다(이번에는 원래 파일이 없어 끝날 때 지웠다). `%APPDATA%\workbench-gpui\` 폴더는 앱이 감시를 위해 만든 것이라 남겼다.

- **리뷰 1회차 (wg-reviewer)** (2026-11-01)
  - 무엇을 했나: Phase 1 `git diff` 리뷰 지적 3건을 모두 반영했다. leader 가 모두 채택했다(docs/HERDR-DECISIONS.md D-028).
    - ① Major `tools/verify-v02-phase1.ps1`: 이 스크립트 것이 아닌 `keymap.json.tmp` 를 지우거나 덮어쓸 수 있었다. 바꿔치기용 파일을 `keymap.json.<GUID>.tmp` 로 바꾸고, 이번 실행이 만든 경로만 기록해 지우게 했다. 같은 폴더의 `keymap.json.tmp` 는 실행 전후 SHA-256 을 비교한다. 없으면 표지 파일을 만들어 비교한 뒤 지운다.
    - ② Minor `src/ui/mod.rs`: 최초 로드 뒤에 감시를 등록해서, 그 사이 저장을 놓칠 수 있었다. 감시를 먼저 등록하고 최초 로드를 하도록 순서를 바꿨다. 시험용 `--dev-keymap-startup-delay <ms>`(디버그 전용)를 넣었다. 최초 로드 직후 멈추는 플래그다. 검증 스크립트에 startup 사례를 더했다. 멈춘 동안 저장하면 seq=2 로 다시 읽는지, 표시가 `Alt-B` 인지, Alt-B 가 실행되는지 본다.
    - ③ Minor `tools/verify-v02-phase1.ps1`: Start-App 이 준비 대기·창 탐색에서 실패하면 띄운 프로세스가 남았다. 띄우자마자 `$script:launched` 에 기록하고, Run-Case 의 finally 가 그 PID 만 닫게 했다.
  - 결과: `cargo build` 경고 0, `cargo test` 17개 통과, apply-manifest 세 항목 true. 검증 스크립트 9개 사례 실패 0, 다른 입력 줄 경고 0, `foreignTmp.unchanged` true.
  - 검증:
    - startup 사례가 고친 점을 실제로 가르는지 확인했다. `src/ui/mod.rs` 를 잠시 예전 순서(로드 → 멈춤 → 감시)로 되돌려 빌드하고 startup 사례만 돌렸다(출력은 scratchpad, 증거 폴더 밖). 결과는 실패 3(seq=2 없음, 표시 `<missing>`, Alt-B 무동작)이었다. 고친 코드로 되돌린 뒤 다시 빌드·apply-manifest 를 하고 전체를 다시 돌려 통과했다.
    - ③은 띄운 뒤 실패하는 상황을 실제로 만들어 돌려 보지는 않았다. 코드 읽기와, 정상 실행 뒤 남은 프로세스가 없는 것으로 확인했다.
  - 특이사항:
    - 다시 돌리는 동안 한 번은 스크립트가 보내지 않은 키(`ctrl--`, `ctrl-w`, `ctrl-tab`, `f1`, `f6`)가 앱에 들어왔다. 같은 데스크톱의 다른 입력으로 보인다. 스크립트가 마지막 줄을 판정에 써서 order 사례가 실패 3이 되었다. 앱의 동작은 맞았다(보낸 키의 줄은 기대대로였다). 스크립트를 고쳐, 보낸 마지막 키 입력과 keystroke 가 같은 줄로 판정하고 다른 키 줄은 `results.json` 의 `foreignKeys` 에 경고로 남기게 했다.
    - 그 전 실행에서 reload 사례의 Ctrl-B 하나가 앱에 오지 않은 일이 한 번 있었다. 바로 이어 reload 만 3번 돌렸을 때는 재현되지 않았다. 원인은 확인하지 않았다(다른 입력과 겹친 것으로 짐작한다).

- **리뷰 2회차 (wg-reviewer)** (2026-11-01)
  - 무엇을 했나: 1회차 3건은 해결로 판정되었다. 새 Major 1건을 반영했다(leader 채택, docs/HERDR-DECISIONS.md D-029).
    - 지적 내용: `tools/verify-v02-phase1.ps1` 의 정리 단계가 외부 tmp 해시 확인·표지 삭제를 사용자 keymap.json 복원보다 먼저 했고, 예외도 격리하지 않았다. 그래서 그 단계가 실패하면 복원이 실행되지 않을 수 있었다.
    - 고친 순서: 사용자 keymap.json 복원을 가장 먼저 독립된 try/finally 로 하고, 안쪽 finally 에서 실행 전후 SHA-256 을 `results.json` 의 `userKeymap` 에 반드시 기록한다. 이어서 백업 지우기(복원 해시가 같을 때만, 아니면 백업 경로를 남김), 외부 tmp 해시 확인, 표지 파일 지우기, GUID tmp 지우기(파일마다)를 각각 따로 try/catch 한다. 예외는 `results.json` 의 `errors` 에 모으고 실패로도 센다.
    - 시작 단계에서 실패해도 정리가 바르게 하도록 상태 변수를 try 밖에 두었다: 백업 완료 여부, 표지를 만들었는지, 외부 tmp 해시.
  - 결과: 전체 재실행(증거 폴더) 결과는 9개 사례 실패 0, `errors` 0개, 다른 입력 줄 경고 0 이다. 사용자 keymap.json 은 실행 전 `<absent>`, 복원 뒤 `<absent>`, `restored: true` 다(원래 파일이 없는 PC).
  - 검증: 복원 경로와 정리 격리를 확인하려고 scratchpad 에서 따로 한 번 더 돌렸다(증거 폴더 밖, override·reload 사례).
    - 준비: 사용자 keymap.json(SHA-256 017C7F13…C373)과 외부 `keymap.json.tmp`(F12CD5E9…748D)를 미리 두었다. reload 사례가 시작되면 다른 프로세스가 `keymap.json.tmp` 를 공유 없이(FileShare.None) 열어 잠그게 했다.
    - 결과: 두 사례 모두 통과했다. 실패는 정리 오류 1건(`keymap.json.tmp 해시 확인: … being used by another process`)뿐이고 `errors` 에 모였다. 그래도 사용자 keymap.json 은 복원되어 실행 전후 해시가 같았고(`restored: true`), 백업 파일도 지워졌다. 잠금을 푼 뒤 `keymap.json.tmp` 해시는 실행 전과 같았다.
    - 확인 뒤 미리 둔 두 파일은 지웠다.
  - 특이사항: `pwsh -File` 로 부르면 `-Only a,b` 가 문자열 하나로 넘어가 사례가 하나도 돌지 않는다. 여러 사례를 고를 때는 `pwsh -Command "& ./tools/verify-v02-phase1.ps1 -Only a,b"` 로 부른다. 처음 시도는 이 때문에 사례 0개로 끝났다(그 실행에서도 사용자 keymap.json 해시는 같았다).
  - 리뷰 마감: 리뷰는 2회로 마감했다. D-029 수정은 leader 가 확인했다.

- **완료 조건 검증 (wg-checker)** (2026-11-01)
  - 무엇을 했나: PLAN Phase 1 완료 조건과 SPEC R-1~R-4 를 검증했다. 앱을 다시 띄우지 않고, 이미 있는 증거의 원래 출력(`*-stdout.txt`)과 코드·원문을 직접 대조했다.
  - 결과: `specs/v0.2/verify/phase1/REPORT.md`. R-1 통과(원문 키 60줄 모두 일치, 빠진 것·표 밖 내장 0), R-2 통과, R-3·R-4 는 Phase 1 범위에서 통과다. G-105 기록은 있음, 불일치 0건이다.
  - 검증: 보고서 `specs/v0.2/verify/phase1/REPORT.md`.
  - 특이사항:
    - checker 는 agy(Argon) 개별 한도가 소진되어 Claude Sonnet 5.5 · high 로 교체된 뒤 검증했다(docs/HERDR-SETUP.md 9절 변경 이력 2026-11-01, 4절 "agy 한도 소진 시 교체" 규칙).
    - 판정 불가로 이월한 것이 둘 있다. R-3 의 루트 항목 Delete 무동작과 사이드바 목록·디스크·휴지통 상태는 Phase 3·4 에서, R-4 의 ☰ 메뉴·툴팁 새 키 표시는 Phase 2 에서 다시 판정한다(D-027 ⑤).
    - 보고서의 관찰(불일치 아님) 셋:
      1. 이 PROGRESS 의 구현 항목에 남은 사례 수 "8개"는 구현 당시 숫자라는 설명을 그 줄에 덧붙였다.
      2. unknown 사례의 `ctrl-alt-j` 줄은 컨텍스트가 `Root > Workspace > Sidebar` 였다. 실행된 액션은 기대대로였고, 원인은 확인하지 않았다.
      3. Phase 4 에서 `editing` 컨텍스트(I-035)와 R-22 메뉴 단축키를 키맵에 넣을 때 대조한다.
    - 보고서의 완료 조건 표에는 "리뷰 2회차 기록 없음"이라 적혀 있다. 검증 시점 뒤에 위 "리뷰 2회차" 항목을 기록했다.

- **Phase 1 완료** (2026-11-01)
  - 무엇을 했나: PLAN Phase 1 완료 조건을 대조했다.
  - 결과: R-1~R-4 통과(R-3·R-4 는 Phase 1 범위, 화면 결과는 Phase 2~4 이월). G-105 확인 결과가 PROGRESS 에 있다. `specs/v0.2/verify/phase1/` 에 검증 보고서와 R-1 바인딩 대조표(`r1-bindings.md`, 키·컨텍스트·액션)가 있다. wg-reviewer 리뷰 결과(1·2회차)가 기록되어 있다. 미해결 실패가 없어 Phase 1 을 완료로 본다.
  - 검증: `specs/v0.2/verify/phase1/REPORT.md`, `specs/v0.2/verify/phase1/results.json`, 이 PROGRESS 기록.
  - 특이사항: PLAN 의 Phase 1 완료 조건 중 "Phase 1 커밋이 있다"는 이 기록 뒤의 커밋으로 채운다.

### Phase 2 — 툴팁·메뉴 단축키 표시

- **G-111 소스 대조: gpui·gpui-kit 툴팁·메뉴 기본 동작 vs 01-zed** (2026-11-01)
  - 무엇을 했나: gpui-pre 0.3.10(`elements/div.rs`, `window.rs`)과 gpui-component 0.8.1(`tooltip.rs`, `kbd.rs`, `menu/popup_menu.rs`)을 읽어, 툴팁(L-206~L-216)과 메뉴(I-504~I-521, L-219) 값을 대조했다.
  - 결과:
    - gpui 툴팁 동작은 같다. 지연 500ms(`div.rs:53` `DEFAULT_TOOLTIP_SHOW_DELAY`, 요소별 변경 가능), 위치는 마우스 + (1, 1)(`window.rs:3835`), 오른쪽·아래가 창을 넘으면 커서 왼쪽·위쪽(−폭−1, −높이−1)으로 뒤집는다(`window.rs:3841-3860`). L-206·L-208·L-210 과 같다.
    - gpui-kit `Tooltip` 의 모양은 다르다. 바깥 여백 사방 12(`m_3`, L-209 는 왼쪽 8·위 10), 안쪽 위아래 2·좌우 8(`py_0p5`·`px_2`, L-213 은 4·8), 제목과 단축키 사이 gap 12(`gap_3`, L-215 는 16), 나타날 때 미끄러지는 애니메이션이 있다. 단축키는 `Kbd` 형식이다.
    - gpui-kit `Kbd::format` 은 `Ctrl+Alt+Shift+Win+A` 꼴이다(`kbd.rs:105-125`, 구분자 `+`, Win 이 마지막). L-219(구분자 `-`, Ctrl → Win → Alt → Shift)와 다르다. 메뉴와 툴팁 모두 이 형식을 쓴다.
    - gpui-kit `PopupMenu` 는 몇 값을 상수로 박아 두었다. 항목 높이 26(`popup_menu.rs:1242`), 항목 안 좌우 8(1236, I-507 은 6), 목록 `p_1`·항목 사이 2(I-507 은 목록 위아래 4, 항목 사이 간격 없음), 구분선 2px·위아래 2(1285, I-512 는 1px·위아래 6)다. 최소 폭은 기본 8rem 이고 `min_w`, 최대 높이는 기본 창 절반·450 이고 `max_h` 로 바꿀 수 있다. 키는 자기 `PopupMenu` 컨텍스트의 6개뿐이다(I-517 의 Tab·Ctrl-N·Ctrl-P·Home·End·PageUp·PageDown·Ctrl-C 없음).
  - 검증: 소스 읽기(위 파일·행).
  - 특이사항: D-5("gpui-kit menu·Tooltip 을 쓰고 다른 점만 보정")로는 상수로 박힌 값을 맞출 수 없어, 구현 전에 leader 에게 물었다(아래).

- **구현 보류: 결정 질문** (2026-11-01)
  - 무엇을 했나: 원문만으로 정할 수 없는 것 다섯 가지를 leader 에게 물었다. 메뉴를 그리는 방법, 툴팁을 그리는 방법, v0.2 내장 키맵에 없는 메뉴 항목 키(Quit·Close Window), Phase 3 동작이 필요한 메뉴 항목(Open Folder..., Toggle/Focus Folder Sidebar), 메뉴의 앱 이름이다.
  - 결과: leader 가 다섯 가지 모두 추천안 (a)로 답했다(docs/HERDR-DECISIONS.md D-031). ① ☰ 메뉴는 gpui 요소로 직접, ② 툴팁 뷰는 직접 그리되 gpui `.tooltip` 장치를 쓴다, ③ Quit Ctrl-Q·Close Window Ctrl-Shift-W 를 내장 키맵에 더한다, ④ 동작하는 항목만 두고 세 항목은 Phase 3 이월, ⑤ 앱 이름은 workbench-gpui 다.
  - 검증: 없음.
  - 특이사항: 없음.

- **DECISIONS D-031 반영** (2026-11-01)
  - 무엇을 했나: `DECISIONS.md` 에 "이후 변경"(leader 결정 D-031)을 덧붙였다. D-5 에 ①·②(근거는 G-111 대조의 파일·행), D-2 에 ③, D-13 에 ④·⑤ 를 적었다.
  - 결과: 위 세 결정에 이후 변경 단락이 하나씩 생겼다(삽입만 했다).
  - 검증: `git diff specs/v0.2/DECISIONS.md` 가 삽입만인지 확인했다.
  - 특이사항: 없음.

- **내장 키맵에 Quit·Close Window 키 추가 (D-031 ③)** (2026-11-01)
  - 무엇을 했나:
    - 액션 `zed::Quit`·`workspace::CloseWindow`·`zed::Minimize`·`zed::Zoom` 을 더했다(이름은 01-zed 9.2절 액션 열).
    - 내장 키맵에 전역(컨텍스트 없음) 바인딩 `ctrl-q` → `zed::Quit`(I-341), `ctrl-shift-w` → `workspace::CloseWindow`(I-358) 을 더했다. 내장 표에서 컨텍스트 빈 문자열은 전역이다.
    - R-1 기대 표 `specs/v0.2/verify/phase1/r1-expected.tsv` 에 두 줄을 더하고, Phase 1 스크립트의 대조표 머리말을 고쳤다.
  - 결과: R-1 기대 62줄, 앱 내장 바인딩 54개.
  - 검증: Phase 1 스크립트를 다시 돌렸다. 9개 사례 실패 0, R-1 62줄 일치·표 밖 0. 결과는 `specs/v0.2/verify/phase1/d031-rerun/`(README 포함)에 있다.
  - 특이사항: 처음에는 다시 돌린 결과가 Phase 1 증거 폴더를 덮어썼다. 그런데 그 폴더는 Phase 1 검증 보고서(`REPORT.md`)가 줄 번호로 인용한다. 그래서 그 파일들(stdout·results.json·r1-bindings.md·알림 스크린샷)은 HEAD 것으로 되돌리고, 다시 돌린 결과를 하위 폴더에 따로 두었다. 기대 표(`r1-expected.tsv`)만 바뀐 채로 둔다.

- **툴팁·☰ 앱 메뉴 구현 (R-5~R-9)** (2026-11-01)
  - 무엇을 했나:
    - `src/ui/tooltip.rs`:
      - gpui `.tooltip()` 장치 안에 넣는 우리 툴팁 뷰를 만들었다. 치수는 L-209 투명 여백 8·10, L-211 모서리 8·테두리 1·그림자 두 겹(L-212), L-213 여백 4·8, L-214 14px, L-215 제목 최대 288·gap 16, L-216 메타 줄, L-232 두 줄 툴팁이다.
      - 단축키는 지금 포커스의 컨텍스트에서 고르고(I-704), 없으면 키맵 전체에서 고른다. 형식은 우리 표시 문자열이다(L-219~L-221). 바인딩이 없으면 제목만 보인다(L-223).
    - `src/ui/app_menu.rs`:
      - ☰ 앱 메뉴 엔티티를 만들었다. 02 9.2절 전체 구조를 `definition()` 한 곳에 두고, 동작하는 액션만 거른다(D-13). 걸러 낸 결과는 workbench-gpui[Quit workbench-gpui] / File[Close Window] / View[Toggle Left Dock, 구분선, Project Panel] / Window[Minimize, Zoom] 이다.
      - 닫히면 ☰ 하나, 열리면 가로 메뉴 바다(I-302). 이름 hover 로 전환하고(I-303), 팝업은 이름 왼쪽 아래에서 x −5, 창 가장자리 여유 8 에 둔다(I-314).
      - 치수는 바깥 최소 폭 202(안쪽 200, I-313), 최대 높이 75%·스크롤, 목록 위아래 4, 항목 바깥 4·안 6, 줄 높이 1.618, 14px, 단축키 앞 16, 구분선 1·위아래 6 이다.
      - 키는 `menu` 컨텍스트에서 우리 `menu::` 액션으로 받는다. 다음·이전·처음·끝, Enter, Escape·Ctrl-C, Left/Right 메뉴 순환이다(I-517·I-518·I-303).
      - 닫힘은 메뉴 밖 누름·포커스 잃음·실행 뒤다(I-519). 실행 전에 원래 포커스로 돌린다(I-309). 열린 채 항목의 단축키를 누르면 선택 표시 후 50ms 뒤 실행한다(I-520).
    - `src/ui/title_bar.rs`: 왼쪽 묶음 [☰][폴더 이름 버튼]을 넣었다(L-87, gap 2). 폴더 이름 버튼은 `Open Recent Project`(Muted)와 툴팁 `Recent Projects` 만 있다(D-16).
    - `src/ui/layout.rs`: 사이드바·탭 바·상태 표시줄 아이콘 버튼에 R-7 표의 툴팁을 달았다. 상태 표시줄 프로젝트 패널 토글은 Dock 이 열리면 `Close Left Dock`, 닫히면 `Project Panel` 이다.
    - `src/ui/mod.rs`:
      - F10(`app_menu::Toggle`), Quit(`cx.quit`), Close Window(`remove_window`), Minimize, Zoom 처리기를 넣었다.
      - dev 출력에 포커스 자리·창 활성 상태 변화(`[dev] focus-state`)를 더했다.
    - `src/ui/layout_probe.rs`: 경계마다 프레임 번호를 둬서, 스냅숏에 마지막 프레임의 요소만 나오게 했다. 이유는 아래 특이사항.
  - 결과: `cargo build` 경고 0, `cargo test` 19개 통과(메뉴 구조 테스트 2개 추가), apply-manifest 세 항목 true.
  - 검증: 아래 "Phase 2 검증 스크립트·증거" 항목.
  - 특이사항:
    - gpui 는 툴팁을 감춘 뒤에도 툴팁 뷰를 프레임 버퍼에 한 프레임 더 들고 있다. 그래서 뷰의 Drop(`[dev] tooltip-hidden`)이 다음 그리기(다음 마우스 이동 등) 때까지 늦게 온다. 사라짐 판정은 Drop 대신 레이아웃 스냅숏(프레임 단위)으로 한다. `tooltip-hidden` 줄은 참고로만 남겼다.
    - Window > Zoom(`zed::Zoom` → `window.zoom_window()`)은 gpui-pre-windows 0.3.10 에서 `SW_MAXIMIZE` 만 한다(토글 아님, `window.rs` 947~950행). 이미 최대화돼 있으면 아무 변화가 없다. 01-zed I-446 "창 확대(최대화)"와 같다.
    - 메뉴 바가 다시 나타날 때 마우스가 어떤 메뉴 이름 위에 있으면 hover 로 그 메뉴가 바로 열린다(I-303 동작). 검증 스크립트는 키 시험 전에 마우스를 비켜 둔다.

- **Phase 2 검증 스크립트·증거** (2026-11-01)
  - 무엇을 했나:
    - `tools/verify-v02-phase2.ps1` 를 만들었다. 사례는 tooltip, menu, reload(Phase 1 에서 이월한 R-4 화면 판정), quit, closewin 이다.
    - 안전 규칙은 Phase 1 과 같다. 실행 중인 앱이 있으면 멈추고, 띄운 PID 만 닫고, 입력 직전마다 전면 창과 커서 아래 최상위 창을 확인한다. 사용자 keymap.json 은 가장 먼저 독립 try/finally 로 복원하고 전후 해시를 남긴다(D-028·D-029).
    - 입력 대상의 경계가 스냅숏에 없으면 입력하지 않고 멈춘다(`Need-Box`).
    - 띄운 창만 최대화해서 잰다. 기본 창이 200% 에서 작업 영역보다 크기 때문이다.
  - 결과: 판정 118개 모두 통과, R-5 대조 21줄 불일치 0(`specs/v0.2/verify/phase2/r5-shortcuts.md`). 증거와 판정하지 못한 것 목록은 `specs/v0.2/verify/phase2/EVIDENCE.md` 에 있다.
    - 툴팁 지연은 10개 요소 모두 500~515ms 다.
    - 위치는 (마우스+1)+(8,10), 오른쪽·아래 뒤집기 모두 ±1 안이다.
    - 메뉴 치수(I-313~I-318, I-321), 목록 키 15가지, I-520 단축키 실행 50ms 를 확인했다.
    - R-4: keymap.json 을 바꿔 저장하면 ☰ View 메뉴와 상태 표시줄 툴팁의 Toggle Left Dock 키가 `Ctrl-B` → `Alt-B` 로 바뀌고, Alt-B 가 실행된다.
  - 검증: 전체 실행(`pwsh -NoProfile -File tools/verify-v02-phase2.ps1`) 뒤 Phase 1 스크립트도 다시 돌려 둘 다 실패 0 을 확인했다.
  - 특이사항:
    - 실행 중 한 번은 tooltip 사례에서 커서 아래 최상위 창이 우리 창이 아니어서(화면 오른쪽 위 (2742,97), 다른 창으로 보인다) 스크립트가 입력을 보내지 않고 멈췄다. 다시 돌린 전체 실행은 통과했다.
    - Phase 1 base 사례에서 두 번 연속, ProjectPanel 에 있던 포커스가 아무 액션 기록 없이 가운데로 옮겨 가 실패 3 이 났다(alt-shift-c 뒤). 원인을 찾으려고 `[dev] focus-state` 출력을 더한 뒤 base 를 4번, 전체를 1번 더 돌렸지만 재현되지 않았다. 원인은 확인하지 못했다(Alt 키를 뗄 때의 창 메뉴 모드나 같은 데스크톱의 다른 입력으로 짐작한다). 다시 나오면 `focus-state` 줄로 원인을 좁힐 수 있다.
    - 판정하지 못한 것: I-313 최대 높이·스크롤(항목이 적어 넘치지 않음, 코드로만 확인), I-515 비활성 항목(v0.2 메뉴에 없음), L-213~L-216 상자 안 치수(바깥 경계만 잼, 메타 줄 쓰는 툴팁 없음), 색·그림자(테마 매핑 전). Phase 3 이월: 메뉴 세 항목, L-251 툴팁. Phase 4 이월: 프로젝트 패널 항목 툴팁(L-247).

- **리뷰 1회차 (wg-reviewer)** (2026-11-01)
  - 무엇을 했나: Phase 2 리뷰 지적 Major 3건을 모두 반영했다(leader 채택, docs/HERDR-DECISIONS.md D-032).
    - **① `src/ui/app_menu.rs`:** I-520 50ms 지연 실행이 항목 번호만 들고 있다가 그때 열린 메뉴에서 다시 찾았다. 그래서 50ms 안에 메뉴가 바뀌면 다른 액션(예: File 의 Close Window)이 실행됐다.
      - 이제 예약은 액션 자체와 예약 세대를 들고 있다(`pending: Option<(Box<dyn Action>, u64)>`).
      - 메뉴를 열거나 바꾸거나 닫으면 `cancel_pending` 이 예약을 지우고 세대를 올린다.
      - 50ms 뒤 세대가 같을 때만 원래 포커스로 돌리고 예약한 액션을 보낸다.
    - **② `src/ui/keymap.rs` `shortcut_for_name`:** 그 컨텍스트에서 가려져 후보가 없으면 키맵 전체의 마지막 바인딩(`bindings_for_action().last()`)으로 돌아가, 가려진 키를 다시 보였다.
      - 그 대체 조회를 뺐다. 이제 메뉴를 열기 직전 포커스(툴팁은 지금 포커스)의 컨텍스트에서 고르고, 없으면 지금 포커스 핸들의 컨텍스트에서 고른다. 두 조회 모두 gpui 가 가려짐을 확인한다.
      - 둘 다 없으면 단축키 없이 제목만 보인다(L-223).
    - **③ `src/ui/app_menu.rs`:** 메뉴의 표시 키는 열기 직전 컨텍스트에서 골랐지만, 입력은 메뉴 컨텍스트(`Root > Workspace > menu`)에서만 해석했다. 그래서 원래 영역 전용 사용자 바인딩이 실행되지 않았다.
      - 이제 메뉴가 열려 있는 동안 `cx.intercept_keystrokes`(디스패치 전)로 키를 본다.
      - 메뉴 컨텍스트에서 `menu::` 액션이나 F10(`app_menu::Toggle`)으로 풀리는 키는 그대로 둔다(목록 키 우선).
      - 그 밖의 키는 열린 메뉴 항목마다, 열기 직전 포커스의 컨텍스트에서 가려지지 않은 바인딩(`Window::bindings_for_action_in`)과 맞춘다. 끝까지 맞으면 그 항목을 ①의 방식으로 예약하고 키를 소비하며, chord 앞부분이면 다음 키를 기다린다.
      - 예전에 메뉴 요소에 붙였던 항목 액션별 `on_action` 가로채기는 뺐다.
    - **같이 고친 것:** 툴팁처럼 `focus` 없이 부르면, 예전에는 `Window::highest_precedence_binding_for_action` 을 썼다. 이 API 는 디스패치 트리에 마지막으로 그린 요소의 컨텍스트 스택을 써서(gpui-pre `window.rs` 6809행) 포커스 자리와 다를 수 있다. 이전에는 ②의 대체 조회가 이 차이를 가렸는데, 대체 조회를 빼자 툴팁 단축키가 모두 사라졌다. 그래서 지금 포커스 핸들(`window.focused`)로 직접 고르게 했다.
    - **검증 스크립트:** `tools/verify-v02-phase2.ps1` 에 재현 사례 셋을 더했다. 지연 없는 키 묶음(`Send-Batch`, SendInput 한 번)도 함께 더했다.
      - pending(①): View 에서 Ctrl-B 와 Left 를 50ms 안에 보낸다.
      - shadow(②): 사용자 키맵 Workspace ctrl-b → zed::Minimize.
      - prevctx(③): ProjectPanel 의 ctrl-y → ToggleLeftDock, down → ToggleFocus. 패널에 포커스를 둔 채 메뉴를 연다.
  - 결과: `cargo build` 경고 0, `cargo test` 19개 통과, apply-manifest 세 항목 true.
  - 검증:
    - **고치기 전:** 고치기 전 소스(index 의 두 파일)로 만든 실행 파일에서 새 사례 셋은 판정 11개 중 7개가 실패했다(pending 은 앱이 Close Window 로 닫힘, shadow 는 `Ctrl-B` 표시, prevctx 는 Ctrl-Y 무반응). 결과는 `specs/v0.2/verify/phase2/d032-rerun/before-fix/`.
    - **고친 뒤:** Phase 2 전체 8개 사례의 판정 129개 모두 통과, R-5 대조 24줄 불일치 0(`specs/v0.2/verify/phase2/d032-rerun/`). Phase 1 9개 사례 실패 0, R-1 62줄 일치(`specs/v0.2/verify/phase1/d032-rerun/`). 사용자 keymap.json 은 모두 `<absent>` → `<absent>` 다.
  - 특이사항:
    - 다시 돌린 결과는 하위 폴더(`d032-rerun/`)에 두었다. `phase2/`·`phase1/d031-rerun/` 의 증거는 Phase 2 검증 보고서(`specs/v0.2/verify/phase2/REPORT.md`, wg-checker)가 줄 번호로 인용하기 때문이다.
    - 처음 새 사례만 돌릴 때 `phase2/results.json`·`r5-shortcuts.md` 를 덮어썼다. 그래서 index 의 것(보고서가 본 판)으로 되돌리고, 그 실행의 새 파일은 지웠다.
    - REPORT.md 는 내용을 고치지 않고 stage 만 했다.
    - 새 사례를 처음 돌리려 할 때 작업 PC 가 잠겨(LogonUI, 전면 창 없음) 스크립트가 입력을 보내지 않고 멈췄다. 잠금이 풀린 뒤 다시 돌렸다.

- **리뷰 2회차 (wg-reviewer)** (2026-11-01)
  - 무엇을 했나: 리뷰 2회차는 1회차 ①·③을 해결로, ②를 부분 미해결로 보았고 새 Major 2건을 냈다. 모두 반영했다(leader 채택, docs/HERDR-DECISIONS.md D-033).
    - **② `src/ui/keymap.rs` `shortcut_for_name`:** 열기 직전 포커스에서 가려져 없으면 메뉴 포커스(`Root > Workspace > menu`)로 다시 찾아, 원래 자리에서 가려진 내장 키를 되살렸다.
      - 이제 `focus` 를 주면 그 자리에서만 고르고, 없으면 표시하지 않는다(L-223).
      - `focus` 가 없을 때(툴팁, 또는 열기 직전 포커스가 없던 메뉴)만 지금 포커스 핸들의 컨텍스트에서 고른다.
    - **ⓐ `src/ui/app_menu.rs` `run_pending`:** 세대를 비교하기 전에 예약을 꺼내, 오래된 타이머가 새 예약을 버렸다. 이제 세대가 같을 때만 꺼내 실행한다.
    - **ⓑ `src/ui/app_menu.rs` `intercept`:** 첫 완전 일치를 바로 예약해, 다른 항목의 chord 접두 대기를 무시했다.
      - 이제 메뉴를 열기 직전에 기록한 컨텍스트 스택(`prev_stack`, gpui `Window::context_stack`)으로 gpui `Keymap::bindings_for_input` 을 불러, 이기는 바인딩과 접두 여부를 함께 본다.
      - 접두면 키를 소비하고 기다린다. gpui 와 같은 1초(`PENDING_INPUT_TIMEOUT`) 동안 다음 키가 없으면, 기다린 키들 가운데 가장 긴 앞부분으로 확정한다.
      - 이어지지 않는 키가 오면 기다린 키들을 먼저 확정하고 그 키를 새로 처리한다.
      - 확정된 액션이 열린 메뉴의 항목일 때만 예약한다.
    - **검증 스크립트:** `tools/verify-v02-phase2.ps1` 에 재현 사례 셋을 더했다.
      - shadowpp(②): ProjectPanel 에서 ctrl-b → zed::Minimize, 패널에서 View 를 연다.
      - rapid(ⓐ): View 에서 Ctrl-B 와 Ctrl-Shift-E 를 SendInput 한 번에 보낸다.
      - chord(ⓑ): ProjectPanel 에 ctrl-k → Toggle Left Dock, ctrl-k ctrl-y → Project Panel. 두 키를 다 누르는 경우와 Ctrl-K 만 누르는 경우를 본다.
  - 결과: `cargo build` 경고 0, `cargo test` 19개 통과, apply-manifest 세 항목 true.
  - 검증:
    - **고치기 전**(D-032 반영판 실행 파일, `specs/v0.2/verify/phase2/d033-rerun/before-fix/`): 새 사례 판정 7개 중 2개만 통과했다.
      - shadowpp 는 1개 중 0개(`Ctrl-B` 표시).
      - rapid 는 2개 중 1개(두 번 예약됐지만 아무것도 실행 안 됨).
      - chord 는 4개 중 1개(Ctrl-K 에서 약 0.1초 만에 Toggle Left Dock 실행).
    - **고친 뒤**(`specs/v0.2/verify/phase2/d033-rerun/`): shadowpp 1/1, rapid 2/2, chord 4/4. Phase 2 전체 11개 사례의 판정 136개 모두 통과, R-5 대조 24줄 불일치 0.
    - Phase 1 은 9개 사례 실패 0, R-1 62줄 일치(`specs/v0.2/verify/phase1/d033-rerun/`).
    - 사용자 keymap.json 은 모두 `<absent>` → `<absent>`.
  - 특이사항:
    - perl 로 한 줄을 넣다가 구분자(`|`)가 코드의 `|f|` 와 겹쳐, `app_menu.rs` 머리 주석 한가운데에 코드가 들어갔다. 빌드 오류로 바로 알았고 손으로 고쳤다.
    - checker 보고서 `specs/v0.2/verify/phase2/REPORT.md` 는 작업 트리에서 checker 가 갱신한 판을 내용을 고치지 않고 다시 stage 했다.
    - 전체 재실행 뒤 `app_menu.rs` 머리 주석(단축키 고르는 규칙 설명)만 고쳐 다시 빌드했다. 코드 동작은 바뀌지 않았다.

- **완료 조건 검증 (wg-checker)** (2026-11-01)
  - 무엇을 했나: PLAN Phase 2 완료 조건과 SPEC R-4(Phase 1 에서 이월한 화면 부분)·R-5~R-9 를 세 번 검증했다. 앱을 다시 띄우지 않고, 원래 출력(`*-stdout.txt`)·스크린샷·코드·원문을 직접 대조했다.
    - 1회차: 처음 구현.
    - 2회차: 리뷰 1회차 수정(D-032) 뒤, `d032-rerun/`.
    - 3회차: 리뷰 2회차 수정(D-033) 뒤 R-5·R-9 범위를 한정해, `d033-rerun/`.
  - 결과: `specs/v0.2/verify/phase2/REPORT.md`. 세 번 모두 불일치 0건이다.
    - R-4(화면 부분)·R-5 통과. R-5 대조표는 1회차 21줄, 2·3회차 24줄로 불일치 0 이다.
    - R-6~R-9 는 범위 안에서 통과다.
    - 3회차 시점 판정 136개 중 실패 0 이다. 고치기 전 새 사례 7개는 실패 5 였다.
    - Phase 1 R-1 62줄 일치가 유지됐다.
  - 검증: 보고서 `specs/v0.2/verify/phase2/REPORT.md`(1회차, 2회차 절, 3회차 절).
  - 특이사항:
    - 판정 불가·이월(보고서 "판정 불가·이월" 표):
      - Phase 3: 사이드바가 닫혔을 때의 `Open Folder Sidebar` 툴팁(L-251), 메뉴 항목 `Open Folder...`·`Toggle Folder Sidebar`·`Focus Folder Sidebar`(D-031 ④).
      - Phase 4: 프로젝트 패널 항목 툴팁(L-247).
      - 해당 동작이 생기는 버전: `Zoom Out` 문구.
      - 테마 매핑(PoC 7단계): 색·그림자.
      - 코드로만 확인: 툴팁 상자 안쪽 치수·메타 줄, I-506 최대 높이·스크롤, I-519 포커스 잃음 닫힘, I-515 비활성, I-511 아이콘.
    - 보고서의 관찰(불일치 아님):
      - R-5 의 `<none>` 7줄은 계산값이 아니라 "바인딩 없음"이라, checker 가 내장 바인딩 목록으로 따로 확인했다.
      - 사이드바 폴더 줄 툴팁 없음은 자리표시 글자에서 잰 것이라 Phase 3 에서 다시 본다.
      - `r8-closed.png`·`menu-start.png` 에 상태 표시줄 툴팁이 함께 찍혀 있다.
      - D-031 은 "대리 응답"으로 기록돼 있다.
      - 3회차 chord ⑵ 의 예약 → 실행 간격이 약 109ms 로 다른 경로(58~63ms)보다 길다. 이 판정은 "900ms 이상 뒤 실행"만 본다.
      - chord ⑵ 판정의 `evidence` 칸에 무관한 앞 단계 줄이 붙어 있다(`got`·`expect` 는 맞다).
      - chord 대기 중 `Escape`·메뉴 밖 누름 취소, I-519 포커스 잃음 닫힘은 증거로 시험되지 않았다(코드만 읽음).
    - 2회차 표의 "리뷰 결과 PROGRESS 기록 부분 충족"은 3회차에서 충족으로 바뀌었다(PROGRESS "리뷰 1회차"·"리뷰 2회차").
    - checker 는 agy(Argon) 개별 한도 소진으로 Claude Sonnet 5.5 · high 로 교체된 상태에서 검증했다(docs/HERDR-SETUP.md 9절, Phase 1 과 같다).
    - 리뷰는 2회로 마감했다. D-033 수정은 leader 가 재현 결과와 코드로 확인했다.

- **Phase 2 완료** (2026-11-01)
  - 무엇을 했나: PLAN Phase 2 완료 조건을 대조했다.
  - 결과:
    - R-5~R-9 가 통과로 판정되었다(R-6~R-9 는 범위 안, 이월 항목은 위 표). Phase 1 에서 이월한 R-4 화면 부분도 통과다.
    - `specs/v0.2/verify/phase2/` 에 검증 보고서가 있고, R-5 "화면 단축키 / 키맵 적용 결과" 대조표(`r5-shortcuts.md`, 최신 `d033-rerun/r5-shortcuts.md` 24줄)에 불일치가 없다.
    - wg-reviewer 리뷰 결과(1·2회차)가 기록되어 있다.
    - 미해결 실패가 없어 Phase 2 를 완료로 본다.
  - 검증: `specs/v0.2/verify/phase2/REPORT.md`, `specs/v0.2/verify/phase2/d033-rerun/results.json`, 이 PROGRESS 기록.
  - 특이사항: PLAN 의 Phase 2 완료 조건 중 "Phase 2 커밋이 있다"는 이 기록 뒤의 커밋으로 채운다.

### Phase 3 — 사이드바 폴더 등록·선택·해제

- **구현 보류: 결정 질문** (2026-11-01)
  - 무엇을 했나: SPEC R-10~R-16·R-28, DECISIONS D-6·D-7·D-10·D-11·D-14·D-16·D-18, 01-zed A-10~A-17·A-20·A-22·A-24·A-28 을 읽었다. gpui-kit `h_resizable`(`on_resize`·`ResizablePanel::visible`)도 확인했다. 원문만으로 정할 수 없는 것 셋을 leader 에게 물었다.
    - 트리·탭에 기대는 판정(R-12 의 폴더별 펼침·선택·스크롤과 탭, R-13 의 해제 때 탭 닫기와 루트 항목 우클릭 `Remove from Project`)의 범위.
    - `state.json` 읽기 오류 알림 문구.
    - A-24(state.json 쓰기·읽기 복구 규칙)를 이번에 적용할지.
  - 결과: leader 가 셋 모두 (a) 로 정했다(D-035). 그 사이 코드는 바꾸지 않았다.
  - 검증: 없음.
  - 특이사항: 사이드바 폭 저장은 gpui-kit `ResizablePanelGroup::on_resize`, 사이드바 숨김은 `ResizablePanel::visible` 로 할 수 있어 질문하지 않았다. `folders[].id`(UUID v4, A-22.3)는 새 크레이트 없이 Windows `CoCreateGuid`(FFI)로 만들 계획이다.

- **D-035 반영** (2026-11-01)
  - 무엇을 했나: `specs/v0.2/DECISIONS.md` 의 D-6·D-7·D-10 에 "이후 변경(leader 결정 D-035)"을 덧붙였다(rfd 0.17.2·`--dev-pick-folder`, Phase 3 범위와 키보드 커서, 읽기 오류 문구·A-24.1~A-24.7·CoCreateGuid·ISO 8601 UTC·A-28·resizable).
  - 결과: 덧붙이기만 했다. 기존 문장은 고치지 않았다.
  - 검증: `git diff specs/v0.2/DECISIONS.md` 가 추가 줄만이다.

- **구현: 폴더 등록·선택·해제·순서, 표시·포커스 키, state.json** (2026-11-01)
  - 무엇을 했나:
    - `Cargo.toml`: `rfd = "=0.17.2"`(D-6, G-018).
    - `src/state/`(새): `path.rs` A-28 정규화·비교 키·이름, `win.rs` `CoCreateGuid`·`ReplaceFileW`/`MoveFileExW` FFI, `time.rs` ISO 8601 UTC·bad 파일 시각, `mod.rs` state.json 읽기·쓰기(A-22 필드, 알 수 없는 키 보존, A-24.1 tmp→sync_all→교체, A-24.4 50ms×3 재시도·`Could not save the window state.`, A-24.5 tmp 복구, A-24.6 `.bad-YYYYMMDD-HHMMSS` 3개 보관·`Could not read the window state.`, A-24.7 버전 큰 파일 읽기만).
    - `src/ui/folders.rs`(새): 등록(rfd 선택 창 또는 `--dev-pick-folder`, 앱이 직접 검사 → `Cannot open this folder.`, 중복 → 기존 활성), 활성화(폴더마다 Workspace 엔티티, 처음 활성화 때 생성·해제까지 유지), 해제(아래·위·빈 상태), Move Up/Down, 우클릭 메뉴, 사이드바 Up/Down/Enter/Delete, Ctrl+Alt+J·Ctrl+Alt+; 이전 포커스 복귀, 500ms 묶어 쓰기·종료 직전 쓰기, 사이드바 폭 저장, 폴더 줄 그리기(A-12), 프로젝트 패널 빈 상태·경로 없음·루트 한 줄, 타이틀 이름(40자 말줄임).
    - `src/ui/context_menu.rs`(새): ☰ 메뉴와 같은 치수의 우클릭 메뉴(비활성 항목, `menu` 키, 닫힘·포커스 복원).
    - `src/ui/mod.rs`·`layout.rs`·`title_bar.rs`·`app_menu.rs`·`keymap.rs`·`dev.rs`: Workbench 에 폴더 상태·사이드바 열림·분할 상태, 사이드바 닫힘 때 분할을 그리지 않음, 상태 표시줄 A-11.8·A-11.9 배치와 L-251 툴팁, 푸터·상태 표시줄 버튼 누름, ☰ File `Open Folder...`·View `Toggle/Focus Folder Sidebar`(D-031 ④ 이월), `--dev-pick-folder`.
    - `tools/verify-v02-phase3.ps1`(새). Phase 1·2 스크립트는 `--dev-pick-folder <취소>` 와 state.json 전후 해시 확인을 더했고, Phase 2 는 새 메뉴 항목에 맞춰 기대값을 고쳤다.
  - 결과: R-10~R-16·R-28 의 Phase 3 범위가 동작한다. 트리·탭 의존 부분은 Phase 4 로 넘긴다(아래).
  - 검증:
    - `cargo build` 경고 0, `cargo test` 29개 통과, `tools/apply-manifest.ps1` 적용.
    - `tools/verify-v02-phase3.ps1` 판정 114개 실패 0, 사용자 파일(keymap.json·state.json*) 전후 해시 같음. 증거 `specs/v0.2/verify/phase3/EVIDENCE.md`, `results.json`.
    - 폴더 선택: 실제 rfd 선택 창(SendInput: 경로 입력·Enter·확인 버튼, Escape 취소)과 `--dev-pick-folder` 주입을 둘 다 썼다(EVIDENCE 에 사례별로 적음).
    - 등록 해제 전후 디스크 목록(폴더 이름, 파일 크기·수정 시각·SHA-256) 같음(`remove-disk-before.txt`·`remove-disk-after.txt`).
    - Phase 1 다시 돌리기 `phase1/d035-rerun/` 실패 0, Phase 2 `phase2/d035-rerun/` 판정 137 실패 0·단축키 대조 31줄 불일치 0. 앞선 증거 폴더는 덮어쓰지 않았다.
  - 특이사항:
    - 판단(우리 값): 읽기 오류 문구(D-035 ②), bad 파일 시각 UTC, 타이틀 40자 + `…`, 사이드바 Up/Down 순환(I-518 따름), 아이콘–이름 간격 4, 색 토큰(구별만 판정), 종료 직전 쓰기는 쓰지 않은 변경이 있을 때만, 사이드바 닫힘 때 `visible(false)` 대신 분할을 그리지 않음, 경로 없음은 시작·활성화·창 다시 활성화 때 확인.
    - Phase 4 로 이월(D-035 ①): 폴더별 트리 펼침·선택·스크롤 유지, 폴더별 탭과 해제 때 탭 닫기, 루트 항목 우클릭 `Remove from Project`(I-555). Phase 5 로 이월: 실행 중 사라진 폴더의 즉시 반영(A-16.3, R-24).
    - Phase 1 다시 돌리기에서 결함 하나를 찾아 고쳤다: ☰ 메뉴가 열린 채 Ctrl+Alt+; 로 사이드바에 갔다 돌아오면 닫힌 메뉴로 포커스가 가서 사라졌다. 지금 화면에 있는 자리로만 돌아가게 했다(Phase 3 keys 판정 추가).
    - 고치기 전 Phase 1 스크립트로 다시 돌렸을 때 실제 선택 창이 열려 `D:\projects` 가 등록되고 사용자 폴더에 state.json 이 생겼다. 실행 전 사용자 폴더가 비어 있던 것을 확인했으므로 그 파일을 지웠다. 이후 실행은 state.json 전후 해시가 같다.
    - Phase 3 리뷰(wg-reviewer)와 커밋은 아직이다.

- **리뷰 1회차 (wg-reviewer)** (2026-11-01)
  - 무엇을 했나: 리뷰 1회차 지적 6건(Major 4, Minor 2)을 모두 반영했다(leader 채택, docs/HERDR-DECISIONS.md D-037).
    - **① `src/ui/mod.rs`·`folders.rs` 종료 저장:** 창이 사라지는 경로(Close Window, 창 닫기 버튼)에서 마지막 변경을 잃었다. 이제 `flush_save` 가 Close Window(창 제거 전)·`on_window_should_close`·Quit 에서 먼저 쓰고, App 수준 `on_app_quit` 이 Workbench 를 강하게 붙잡아 쓴다.
    - **② `folders.rs` `save_now`:** 저장 결과와 상관없이 `saved_generation` 을 올렸다. 이제 쓰기 직전 세대를 잡아 두고 성공했을 때만 올린다. 실패는 A-24.4 재시도·알림 뒤 남겨 종료 직전 쓰기에서 다시 시도한다.
    - **③ `tools/verify-v02-phase3.ps1` 복원:** 사용자 파일 복원을 파일마다 따로 한다(백업 파일 복사 먼저, 시험이 만든 파일 지우기 나중). 한 파일 실패가 keymap.json 복원을 막지 않는다.
    - **④ 같은 스크립트 시작:** 사용자 파일·시험 폴더를 바꾸기 전에 기존 앱 실행을 검사하고 멈춘다. Phase 1·2 스크립트에도 같은 앞 검사를 넣었다.
    - **⑤ `src/state/path.rs` `compare_key`:** `to_lowercase` 대신 A-28.5 단순 케이스 폴딩(소문자화와 다른 C·S 항목 표 + 한 글자 소문자화). 같은 이름 표시(A-12.6)도 같은 키를 쓴다.
    - **⑥ `folders.rs` Ctrl+Alt+J 닫기:** 사이드바에 포커스가 없으면 가운데 Pane 으로 옮긴다(R-16).
    - **재현 사례:** Phase 3 스크립트에 `closesave`·`xclosesave`(①), `savefail`(②), `sigma`(⑤), `keys` 판정 추가(⑥). 새 하네스 `tools/verify-v02-phase3-guard.ps1` 의 `running`(④)·`locked`(③).
  - 결과: 6건 모두 고쳤다. 6건 모두 고치기 전 실패·고친 뒤 통과를 남겼다.
  - 검증:
    - `cargo build` 경고 0, `cargo test` 30개 통과(⑤ 단위 시험 추가), apply-manifest 적용.
    - 고치기 전 exe(stage 된 리뷰 대상 트리를 꺼내 따로 빌드): 새 사례 판정 28, 실패 5(①×2·②·⑤·⑥). 고친 exe: 같은 사례 실패 0.
    - 하네스: 고치기 전 스크립트는 running(실행 중 앱이 keymap 삭제를 봄)·locked(keymap.json 잃음) 실패, 고친 스크립트는 둘 다 통과.
    - 전체: Phase 3 판정 122 실패 0(`phase3/d037-rerun/after/`), Phase 1 실패 0(`phase1/d037-rerun/`), Phase 2 판정 137 실패 0·단축키 대조 31줄 불일치 0(`phase2/d037-rerun/`). 사용자 파일은 모든 실행에서 전후 해시가 같다.
    - 증거 `specs/v0.2/verify/phase3/d037-rerun/EVIDENCE.md`. 앞선 증거 폴더는 덮어쓰지 않았다.
  - 특이사항:
    - ⑤: 이 PC 의 D: 볼륨에서 σ·ς 는 다른 이름이다(둘 다 만들 수 있다). 그래서 리뷰의 "같은 폴더를 가리킨다"는 이 볼륨에서는 맞지 않는다. 수정은 A-28.5 원문(단순 케이스 폴딩, 대소문자를 구분하는 폴더도 구분하지 않음·판단)대로 했다. 그 결과 서로 다른 σ·ς 폴더는 같은 항목으로 본다.
    - ①: 처음 만든 사례는 닫기가 500ms 묶어 쓰기보다 늦어 고치기 전 exe 도 통과했다. 닫기를 묶어 쓰기 전에 보내도록 고친 뒤 재현했다.
    - 작업 폴더가 있는 D:(USB 드라이브)가 큰 빌드 중에 두 번 끊겼다(`STATUS_IN_PAGE_ERROR`, os error 1006). 고치기 전 exe 는 C: 의 대상 폴더로 빌드했다. 끊긴 동안의 편집은 다시 확인해 다시 넣었다.
    - checker 보고서 `specs/v0.2/verify/phase3/REPORT.md` 는 내용을 고치지 않고 stage 만 했다.

- **리뷰 2회차 (wg-reviewer)** (2026-11-01)
  - 무엇을 했나: 리뷰 2회차는 1회차 ①②③④⑥을 해결로, ⑤를 부분 미해결로 보았고 새 Minor 1건을 냈다. leader 결정 D-040 대로 반영했다.
    - **ⓐ 새 Minor `tools/verify-v02-phase3.ps1`:** 가드로 일찍 멈춰도 끝에서 고정 시험 폴더(`target\phase3-folders`)를 통째로 지웠다.
      - 이제 실행마다 `run-<id>` 폴더와 표지 파일(`.wg-p3-run`, 내용 = 실행 id)을 만든다. 이미 있으면 멈춘다.
      - 표지가 이번 실행 것일 때만 그 폴더를 지운다. 바탕 폴더는 이번 실행이 만들었고 비어 있을 때만 지운다.
      - 가드로 일찍 멈추면 아무것도 지우지 않는다.
      - `tools/verify-v02-phase3-guard.ps1` 에 "미리 있던 시험 폴더는 남는다" 판정(세 사례마다)과 `normal` 사례(앱 없이 정상 실행)를 더했다.
    - **ⓑ ⑤ 남은 부분:** 수작업 표가 단순 케이스 폴딩 전체가 아닌 점(U+1FD3·U+1FE3·U+FB05 등 빠짐)을 `specs/v0.2/DECISIONS.md` "미결 사항"에 알려진 한계로 적었다. 이후 버전에서 Unicode CaseFolding C/S 표를 들여온다. `compare_key` 주석에도 적었다. 동작은 바꾸지 않았다.
  - 결과: ⓐ 고쳤다. ⓑ 기록했다.
  - 검증:
    - 하네스 고치기 전(D-037 판 스크립트, `phase3/d040-rerun/guard-before/`): running·locked·normal 모두에서 미리 있던 폴더가 지워졌다(일찍 멈춘 running 포함).
    - 하네스 고친 뒤(`guard-after/`): running(일찍 멈춤, 앱 keymap 다시 읽기 0)·locked(keymap.json 복원)·normal(통과) 모두 통과했다. 미리 있던 폴더는 세 사례 모두 그대로였고 `run-*` 는 남지 않았다.
    - Phase 3 전체(`phase3/d040-rerun/after/`): 판정 122, 실패 0. 이번 실행 폴더·바탕 폴더 모두 남지 않았다. 사용자 파일 전후 해시가 같다.
    - 그 뒤 `path.rs` 주석만 더해 `cargo build`(경고 0)·`cargo test`·apply-manifest 를 다시 했다.
  - 특이사항: 2회차 checker 보고서 `specs/v0.2/verify/phase3/REPORT.md` 는 내용을 고치지 않고 stage 만 했다.

- **완료 조건 검증 (wg-checker)** (2026-11-01)
  - 무엇을 했나: PLAN Phase 3 완료 조건과 SPEC R-10~R-16·R-28(+ Phase 1·2 이월분)을 두 번 검증했다. 앱을 다시 띄우지 않고, 원래 출력(`*-stdout.txt`)·`results.json`·`state-*.json`·`remove-disk-*.txt`·스크린샷·코드·원문을 직접 대조했다.
    - 1회차: 처음 구현, `phase3/`(판정 114개).
    - 2회차: 리뷰 1회차 수정(D-037·D-038) 뒤, `d037-rerun/`(판정 122개, 1회차 114개는 모두 남아 통과하고 새 판정 8개).
  - 결과: `specs/v0.2/verify/phase3/REPORT.md`. 두 번 모두 불일치(명세 값과 다른 실제 값) 0건이다.
    - R-10·R-11·R-14·R-16·R-28 통과. R-12·R-13·R-15 는 Phase 3 범위 안에서 통과다.
    - 이월분(R-3 사이드바 Delete, ☰ `Open Folder...`·`Toggle/Focus Folder Sidebar`, L-251 툴팁, 사이드바 이전 포커스 복귀) 통과.
    - 2회차에 종료 저장 3경로(Ctrl-Q·Ctrl-Shift-W·창 닫기 버튼)와 저장 실패 뒤 재저장을 추가로 확인했다.
    - Phase 1 R-1 62줄 일치, Phase 2 R-4~R-9 가 유지됐다(`d035-rerun/`·`d037-rerun/`).
  - 검증: 보고서 `specs/v0.2/verify/phase3/REPORT.md`(1회차, 2회차 절).
  - 특이사항:
    - 판정 불가·이월(보고서 §13·§2-11):
      - Phase 4(D-035 ①): 폴더별 트리 펼침·선택·스크롤(A-15.2), 폴더별 탭과 해제 때 탭 닫기(A-15.1·A-13.4), 루트 우클릭 `Remove from Project`(I-555), 루트 `Delete` 무동작·휴지통(R-3 이월분의 나머지).
      - Phase 5: 실행 중 사라진 폴더의 즉시 반영(A-16.3, R-24).
      - 판정 대상 아님: 색 토큰 값(R-11, 테마 매핑 전).
      - 코드·단위 시험으로만 확인: 폭 200~800 막힘, 행 padding·아이콘 14, A-24.2·A-24.4 재시도·A-24.6 일부, A-28.7~13 표, `app-quit` 경로.
    - 허용 오차(±1 px) 끝 값(통과로 보되 알림): 사이드바 맨 위 줄 아래 선과 타이틀 바 아래 선의 1 논리 px 단차(A-11.2), 사이드바–프로젝트 패널 경계 폭 2(A-11.5).
    - leader 판단이 필요하다고 적힌 것:
      - A-24.3 을 "쓰지 않은 변경이 있을 때만" 쓰는 판단(§11-가).
      - A-16.1(타이틀 바 이름 = 앱 이름)과 A-13.9·L-227·SPEC R-12(`Open Recent Project`)의 문서 충돌. 구현은 SPEC R-12 를 따랐다(§11-나).
      - σ/ς 두 폴더가 한 항목으로 합쳐지는 것(A-28.5 원문대로, D-038, §2-9-가).
    - 보고서의 관찰(불일치 아님):
      - 상태 표시줄 폴더 추가 버튼 클릭은 툴팁 판정뿐이고 클릭 입력 증거가 없다(코드로 확인).
      - 활성 줄 위 hover 색이 활성 색을 덮는다. 마우스로 활성화한 줄에도 키보드 포커스 테두리가 보인다. 스크롤 직후 hover 갱신이 한 박자 늦다.
      - 종료 때 같은 내용을 한 번 더 쓴다(`quitsave`, 파일 내용 같음).
      - `phase2/d035-rerun/r5-shortcuts.md` 의 shadow 새 두 행 "01-zed 원문" 칸 표기 흠.
      - 코드 주석 `src/state/path.rs` 의 "NTFS 도 같은 이름으로 본다"는 이 볼륨 증거(σ·ς 두 폴더 공존)와 맞지 않는다(판정 영향 없음, 주석만).
    - 리뷰는 2회로 마감했다. D-040 수정(시험 폴더 소유 표지)은 leader 가 가드 하네스 결과(고치기 전 미리 있던 폴더 삭제 → 고친 뒤 보존)로 확인했다.

- **Phase 3 완료** (2026-11-01)
  - 무엇을 했나: PLAN Phase 3 완료 조건을 대조했다.
  - 결과:
    - R-10~R-16·R-28 이 통과로 판정되었다. R-12·R-13·R-15 는 Phase 3 범위 안이다(트리·탭 의존 부분은 D-035 ① 로 Phase 4).
    - `specs/v0.2/verify/phase3/` 에 검증 보고서, 등록 해제 전후 디스크 비교(`remove-disk-*.txt`), 재시작 전후 `state.json`·복원 결과가 있다.
    - wg-reviewer 리뷰 결과(1·2회차)가 기록되어 있다.
    - 미해결 실패가 없어 Phase 3 을 완료로 본다.
  - 검증: `specs/v0.2/verify/phase3/REPORT.md`, `specs/v0.2/verify/phase3/d040-rerun/after/results.json`(판정 122, 실패 0), `d040-rerun/guard-after/guard-results.json`, 이 PROGRESS 기록.
  - 특이사항:
    - 이월: Phase 4 — 트리·탭에 기대는 판정(폴더별 트리 펼침·선택·스크롤 유지, 폴더별 탭과 해제 때 탭 닫기, 루트 우클릭 `Remove from Project`, 루트 `Delete` 무동작·휴지통). Phase 5 — 실행 중 사라진 폴더의 즉시 반영(A-16.3, R-24).
    - 알려진 한계: A-28.5 비교 키의 수작업 표가 Unicode 단순 케이스 폴딩 C·S 전체가 아니다(`specs/v0.2/DECISIONS.md` 미결 사항, D-040). 이후 버전에서 Unicode CaseFolding C/S 표를 들여온다.
    - Phase 3 구현 항목 끝의 "Phase 3 리뷰(wg-reviewer)와 커밋은 아직이다"는 그 시점의 기록이다. 리뷰는 위 "리뷰 1회차"·"리뷰 2회차" 항목에 있다.
    - PLAN 의 Phase 3 완료 조건 중 "Phase 3 커밋이 있다"는 이 기록 뒤의 커밋으로 채운다.

### Phase 4 — 프로젝트 패널 트리·파일 작업과 시나리오

- **구현: 트리·키·인라인 입력·휴지통/삭제·클립보드·우클릭 메뉴·자동 표시·최소 탭** (2026-11-01~02)
  - 무엇을 했나:
    - `Cargo.toml`: `trash = "=5.2.9"`(D-6, G-017). 새로 잠긴 패키지는 trash·urlencoding.
    - `src/fsops/`(새, gpui 무관):
      - `list` 폴더 읽기·L-50 정렬
      - `names` P-021·P-022 검증·확정
      - `ops` 만들기·이름 바꾸기·복사·이동·휴지통·삭제·붙여넣기 이름
      - `paths` I-548·I-549·L-247 경로
      - `tree` 보이는 행(L-41 루트, L-42 접힌 경로, L-38 안내선, P-019 새 항목 가상 행)
    - `src/ui/project_panel.rs`(새): 폴더마다 트리 상태. gpui-kit `base::Tree`·`TreeState`(gpui-component tree 의 바탕)로 가상화한다(D-8).
      - TreeState 의 기본 누르기·`Tree` 컨텍스트 화살표 키는 쓰지 않는다. 행 처리기가 전파를 멈추고, 포커스는 늘 `ProjectPanel` 자리에 둔다.
    - `src/ui/panel_view.rs`(L-36~L-49 행 그리기·입력칸·배너·툴팁), `panel_nav.rs`(R-18 선택·펼침·누르기·열기·R-23 자동 표시), `panel_edit.rs`(R-19), `panel_ops.rs`(R-21), `panel_delete.rs`(R-20, 실패 알림, Reveal·Open in Default App), `panel_menu.rs`(R-22), `shell.rs`.
    - `src/ui/task_dialog.rs`(새): D-12 TaskDialogIndirect FFI. 별도 스레드에서 부르고 부모는 우리 창이다. 기본 버튼·Esc 는 Cancel.
    - `src/ui/pane.rs`(새): D-9 최소 탭(임시 탭 하나 교체·승격, 기울임 제목, 새 탭은 활성 뒤)과 D-18 보기 전용 Editor. `layout.rs` 탭 바가 실제 탭을 그린다(탭이 없으면 v0.1 자리 표시).
    - `folders.rs`: FolderWorkspace 가 트리·탭을 가진다(A-15.1·A-15.2, D-035 ① 이월). 해제하면 엔티티째 버려 탭이 닫힌다(`folder-tabs-closed`). 다시 활성화하면 디스크를 다시 읽는다.
    - `context_menu.rs`: 단축키 열(I-509), 항목 28줄 탐침, I-520(D-042 ④).
      - ☰ 메뉴와 같은 방식이다: 열기 전 자리의 컨텍스트 스택으로 키를 해석하고, 50ms 선택 표시 뒤 실행하며, 세대로 취소하고, chord 를 처리한다.
    - 키맵: I-532 Ctrl-Alt-R·I-533 Ctrl-Shift-Enter 를 ProjectPanel 내장 키로 더했다(02 11.2절 단축키 열). 같은 액션 키의 순서를 바꿔 메뉴 표시가 11.10절(Ctrl-C·Ctrl-V·Delete·Ctrl-Delete)이 되게 했다.
    - dev 플래그·출력
      - `--dev-no-shell`
      - `--dev-trash list|restore|purge <폴더>`(원래 위치가 그 폴더 아래인 항목만)
      - `[dev] tree`·`tabs`·`edit`·`fs-op`·`task-dialog-*`·`panel-menu-*`·`context-menu-shortcut`·`shell`
      - 레이아웃 스냅숏 머리 줄 `tree_scroll_y`·`active_text_len/fnv`
    - `tools/verify-v02-phase4.ps1`(새, 12개 사례).
      - Phase 1 스크립트: 메뉴 키 2줄을 `r1MenuKeys` 로 따로 적고 실패로 세지 않는다.
      - Phase 3 스크립트: `menus` 사례에 메뉴 줄 기다리기를 넣었다.
  - 결과: R-17~R-23·R-25~R-27 과 이월분이 동작한다.
    - R-3: 패널 Delete=휴지통, 루트 Delete 무동작, Ctrl-N 결과.
    - L-247 항목 툴팁.
    - D-035 ①: 폴더별 트리·탭, 해제 때 탭 닫기, 루트 Remove from Project.
  - 검증:
    - `cargo build` 경고 0, `cargo test` 37개 통과, apply-manifest 적용.
    - `tools/verify-v02-phase4.ps1`: 판정 208, 실패 0, 재시도 0, 판정 불가 1(아래). 사용자 파일 해시 같음, OS 클립보드 되돌림, 시험 폴더·이번 실행 휴지통 항목 남지 않음.
    - 증거: `specs/v0.2/verify/phase4/EVIDENCE.md`·`results.json`.
      - 파일 작업마다 디스크 전후 목록(`*-disk-*.txt`), 휴지통 목록.
      - A-33.2·A-33.4 단계별 스크린샷.
    - Phase 1~3 다시 돌리기(`p4-rerun/`): Phase 1 실패 0(R-1 일치 62·표 밖 0), Phase 2 판정 137 실패 0·단축키 31줄 불일치 0, Phase 3 판정 122 실패 0.
  - 특이사항:
    - 판정 불가(D-042 ②): D: 는 이동식 드라이브라 휴지통이 없고, 이 PC 휴지통 설정은 `NukeOnDelete=1` 이다. 그래서 휴지통 안 항목 확인·복원(A-14.3 휴지통 쪽, A-14.5)은 판정 불가로 적었다. "trash 크레이트로 보내고 디스크에서 사라짐"까지는 판정했다. 시스템 설정은 바꾸지 않았다.
    - 원문에 값이 없어 판단한 18가지는 leader 가 승인했다(D-042 ③). `specs/v0.2/DECISIONS.md` D-8 "이후 변경(leader 판단 D-042)" 표에 적었고, D-9 에 가리키는 줄을 두었다.
    - 시험 중 찾아 고친 앱 결함: 입력칸 밖 편집기를 눌러 확정하면, 새 파일 탭이 눌린 편집기를 대신해 포커스가 사라진 요소에 남았다. 활성 편집기에 포커스가 있었으면 새 활성 탭 편집기로 옮긴다.
    - 디버그 빌드는 파일을 처음 열 때 500ms 넘게 멈춘다. 그래서 빠른 더블클릭이 두 번의 한 번 누르기로 세어질 수 있다. 시험은 먼저 한 번 눌러 연 뒤 더블클릭한다.
    - 접힌 경로의 `\` 가 한국어 UI 글꼴에서 `₩` 로 보인다(Zed 글꼴은 v0.2 범위 밖).
    - 시험 도중 사용자가 띄운 관리자 PowerShell 창이 전면에 와서, 일반 권한 시험 스크립트가 입력을 보내지 못하고 멈췄다(UIPI). leader 결정(D-042 ①)대로 그 창은 건드리지 않고 전면이 빈 뒤 다시 돌렸다.
    - Reveal·Open in Default App 은 `--dev-no-shell` 로 실행 명령만 기록해 판정했다(사용자 탐색기·앱 창을 만들지 않으려고).
    - Phase 4 리뷰(wg-reviewer)와 커밋은 아직이다.

- **리뷰 1회차 (wg-reviewer)** (2026-11-02)
  - 무엇을 했나: 지적 6건(Major 5·Minor 1)을 leader 결정 D-043 대로 모두 고쳤다.
    - ① 이름 검증 강화(구분자·드라이브/스트림 `:`·금지 글자·`.`/`..`·끝 마침표·예약 장치 이름 거부, 이름 변경은 한 구간), 확정 직전 실제 경로로 부모 바로 아래·폴더/루트 안 확인.
    - ② 실제 경로(canonical)로 자기 안 복사·이동 차단, 재귀 복사·Expand All·경로 접기의 링크 순환 방지.
    - ③ Ctrl+클릭으로 뺀 항목은 대상에서 제외(커서를 남은 항목으로, 다 빼면 선택 없음).
    - ④ 이동·이름 변경 뒤 모든 폴더 Workspace 의 탭 경로 갱신.
    - ⑤ 시험 스크립트는 클립보드에 텍스트가 아닌 형식이 있으면 사용자 파일·클립보드를 바꾸기 전에 멈추고, 끝에 형식·글자를 확인.
    - ⑥ `TaskDialogIndirect` 를 프로세스 수명 동안 한 번만 찾기.
    - 재현 스크립트 `tools/verify-v02-phase4-d043.ps1`(사례 6개), `tools/verify-v02-phase4-d043-clip.ps1`(⑤)을 새로 만들었다.
  - 결과: 6건 모두 고쳤다. checker 보고서 `specs/v0.2/verify/phase4/REPORT.md` 는 내용을 고치지 않고 stage 했다.
  - 검증:
    - 고치기 전 실행 파일(stage 한 트리를 C: 에서 빌드)로 `phase4/d043-rerun/before/` 판정 13 중 실패 11. 고친 뒤 `after/` 판정 13 실패 0.
    - 고치기 전 실패 내용: 폴더 밖 이동 4건, 정션 붙여넣기 3초에 폴더 122개, 접기 조각 64·펼침 2784, Ctrl+클릭 대상 어긋남, 출발 폴더 탭 옛 경로, comctl32 기록 없음.
    - ⑤: 이미지 클립보드에서 고치기 전 스크립트는 이미지를 잃었고, 고친 스크립트는 먼저 멈춰 이미지를 지켰다(`d043-rerun/clip-results.json`, 사용자 클립보드 되돌림).
    - `cargo build` 경고 0, `cargo test` 39개 통과(새 단위 시험 2개), apply-manifest 적용.
    - 다시 돌리기: Phase 4 전체 `phase4/d043-rerun/phase4-full/` 판정 208 실패 0, Phase 1 `phase1/d043-rerun/` 실패 0, Phase 2 판정 137 실패 0, Phase 3 판정 122 실패 0.
    - 증거 요약 `specs/v0.2/verify/phase4/d043-rerun/EVIDENCE.md`.
  - 특이사항:
    - 정션은 이번 실행 시험 폴더 안에만 만들었다(만들기 전에 경로를 확인한다). 고치기 전 끝없는 복사는 3초 뒤 우리 앱(PID)만 닫아 멈췄다.
    - 판단(원문에 문구 없음): 잘못된 이름은 빈 이름과 같이 배너 없이 입력칸을 연 채 둔다.
    - Phase 4 전체 실행 첫 시도는 trash 사례 도중 전면을 잃어 멈췄다(확인창을 닫은 직후의 일시적 전면 변화로 보인다). 바로 다시 돌려 통과했다.

- **리뷰 2회차 (wg-reviewer)** (2026-11-02)
  - 무엇을 했나: 1회차 6건은 해결로 확인됐다. 새 Major 1건을 leader 결정 D-044 대로 고쳤다.
    - 결함: `ops.rs` 전역 방문 집합이 비순환 별칭까지 건너뛰어 불완전 복사를 Ok 로 돌려주었고, 다른 볼륨 이동은 그 결과로 원본을 지웠다.
    - ① 복사는 재분석 지점을 따라가지 않고 건너뛰어 결과(`CopyReport.skipped_links`, `[dev] copy-report`)에 남긴다. 순환 검사는 지금 조상 경로 집합으로만 한다.
    - ② 다른 볼륨 이동은 원본 트리에 재분석 지점이 있으면 시작 전에 거부한다(변화 없음, 알림). 없으면 파일 수·폴더 수·바이트가 같을 때만 원본을 지운다.
    - 재현 스크립트 `tools/verify-v02-phase4-d044.ps1`(사례 3개)을 새로 만들었다.
  - 결과: 고쳤다. checker 2회차 보고서 `specs/v0.2/verify/phase4/REPORT.md` 는 내용을 고치지 않고 stage 했다.
  - 검증:
    - 고치기 전 실행 파일(stage 한 D-043 판을 C: 에서 빌드)로 `phase4/d044-rerun/before/` 판정 6 중 실패 4.
      - 별칭 폴더 복사에서 실제 z-data 가 빠졌다.
      - 다른 볼륨 이동에서 원본이 지워졌다(데이터 손실).
    - 고친 뒤 `after/` 판정 6, 실패 0.
    - 다른 볼륨은 D:(이동식, 시험 폴더)와 이번 실행이 만든 C: 임시 폴더(표지 확인 뒤 지움, 남지 않음)를 썼다. 정션은 이번 실행 시험 폴더 안에만 만들었다.
    - `cargo build` 경고 0, `cargo test` 40개 통과(새 단위 시험 1개), apply-manifest 적용.
    - Phase 4 전체 `phase4/d044-rerun/phase4-full/` 판정 208 실패 0, D-043 재현 사례 `d044-rerun/d043-after/` 판정 13 실패 0.
    - 증거 요약 `specs/v0.2/verify/phase4/d044-rerun/EVIDENCE.md`.
  - 특이사항:
    - 판단: 다른 볼륨 이동 거부 알림 문구(원문 없음)는 ``Cannot move `이름` to another drive because it contains links (junctions or symbolic links).`` 다.
    - 판단: 맨 위 항목이 링크면 복사하지 않고 건너뛴 것으로만 남긴다.
    - 리뷰 왕복은 D-044 에 따라 2회로 마감한다. 수정 확인은 leader 가 한다.

- **완료 조건 검증 (wg-checker)** (2026-11-02)
  - 무엇을 했나: PLAN Phase 4 완료 조건과 SPEC R-17~R-23·R-25~R-27(+ Phase 1~3 이월분)을 두 번 검증했다. 앱을 다시 띄우지 않고, 원래 출력(`*-stdout.txt`)·`results.json`·`*-disk-*.txt`·스크린샷·원문을 직접 대조했다.
    - 1회차: 처음 구현, `phase4/`(판정 208개).
    - 2회차: 리뷰 1회차 수정(D-043) 뒤, `d043-rerun/`.
      - `phase4-full` 판정 208개는 1회차와 판정 키·결과가 같다.
      - 고치기 전/후 `before/` 실패 11 → `after/` 실패 0.
      - 클립보드 재현 `clip-results.json`.
  - 결과: `specs/v0.2/verify/phase4/REPORT.md`. 두 번 모두 불일치(명세 값과 다른 실제 값) 0건이다.
    - R-17~R-23·R-25~R-27 통과.
    - R-20 은 통과지만, 휴지통 안 항목 확인·복원(A-14.3 휴지통 쪽, A-14.5)은 판정 불가다(D-042 ②: D: 이동식 드라이브라 휴지통 없음, 이 PC 휴지통 설정 `NukeOnDelete=1`, 시스템 설정은 바꾸지 않음).
    - 이월분 통과: R-3 패널 Delete·루트 무동작·Ctrl-N, L-247, 폴더별 트리 상태·탭, 해제 때 탭 닫기, 루트 Remove from Project, I-520.
    - D-043 수정 6건은 고친 뒤 통과다.
    - Phase 1~3 결과가 유지됐다(`p4-rerun/`·`d043-rerun/`).
  - 검증: 보고서 `specs/v0.2/verify/phase4/REPORT.md`(1회차, 2회차 절).
  - 특이사항:
    - 판정 불가·이월(보고서 §17·§23):
      - 환경: 휴지통 안 확인·복원. 휴지통이 있는 볼륨에서 사람이 다시 확인해야 한다.
      - 범위 밖(D-18): A-14.10 수정된 버퍼 문구.
      - Phase 5: R-24 디스크 감시, 실행 중 폴더 사라짐(A-16.3).
      - 시험하지 않음: Shift+Down, ` copy 1`, 여러 항목 Cut, 접힌 경로 두 번째 조각 우클릭, 탭 바 치수(A-32.3~5), 입력칸 높이 24, D-042 판단 #2·#6·#9·#13·#14·#18 값, 등록 루트 밖을 가리키는 정션·심볼릭 링크.
    - leader 판단이 필요하다고 적힌 것:
      - 잘못된 이름(구분자·`:`·예약 이름 등) 거부 때 안내가 없다(무음 거부, §23-카).
      - 휴지통 없는 볼륨에서 Trash 가 영구 삭제처럼 동작하고 앱이 알리지 않는다(§15-가).
    - 보고서의 관찰(불일치 아님):
      - 접힌 경로 우클릭 때 선택 조각이 `docs`(첫 조각)로 기록됐다. 클릭 좌표가 증거에 없다(§15-다).
      - 인라인 입력칸 글자가 행 아래쪽에 앉는다(§15-바).
      - 접힌 경로 `\` 가 `₩` 로 보인다(§15-사).
      - Phase 3 재실행 판정 하나의 기록 시각이 어긋났다. 1회차만이고 2회차에는 없어졌다(§15-라).
      - `quitsave` 저장 줄 수가 실행마다 다르다(§15-마).
      - 클립보드 보호 때문에 이미지 클립보드면 판정 스크립트가 시작하지 않는다(§23-타).
    - 보고서의 완료 조건 표에는 "리뷰 결과 기록 없음·커밋 없음"이라 적혀 있다. 검증 시점 뒤에 위 "리뷰 1회차"·"리뷰 2회차" 항목을 기록했다.
    - D-044 수정(리뷰 2회차)은 checker 검증 뒤의 일이다. leader 가 코드(`ops.rs` ancestors·`is_reparse`)와 재현 결과(고치기 전 4/6 실패 → 고친 뒤 0)로 확인했다(`d044-rerun/`).

- **Phase 4 완료** (2026-11-02)
  - 무엇을 했나: PLAN Phase 4 완료 조건을 대조했다.
  - 결과:
    - R-17~R-23·R-25~R-27 이 통과로 판정되었다. R-20 의 휴지통 안 확인은 판정 불가다(D-042 ②).
    - `specs/v0.2/verify/phase4/` 에 다음이 있다.
      - 검증 보고서
      - 파일 작업마다 디스크 전후 비교(`*-disk-*.txt`, 휴지통 목록 포함)
      - 시나리오 A-33.2·A-33.4 단계별 스크린샷·dev 출력
    - wg-reviewer 리뷰 결과(1·2회차)가 기록되어 있다.
    - 미해결 실패가 없어 Phase 4 를 완료로 본다.
  - 검증: `specs/v0.2/verify/phase4/REPORT.md`, `specs/v0.2/verify/phase4/d044-rerun/phase4-full/results.json`(판정 208, 실패 0), `d044-rerun/after/results.json`(판정 6, 실패 0), `d043-rerun/after/results.json`(판정 13, 실패 0), 이 PROGRESS 기록.
  - 특이사항:
    - 이월:
      - Phase 5: 실행 중 사라진 폴더·파일의 즉시 반영(A-16.3, R-24). 지금은 폴더 활성화·창 다시 활성화 때 다시 읽는다.
    - 알려진 한계:
      - 휴지통이 없는 볼륨(이동식 드라이브)이나 휴지통을 "바로 지우기"로 둔 PC 에서는 Trash 가 실제로 바로 지운다. 앱은 따로 알리지 않는다. 이 PC 에서는 휴지통 안 확인을 판정하지 못했다.
      - 접힌 경로 `\` 가 한국어 UI 글꼴에서 `₩` 로 보인다(Zed 글꼴은 v0.2 범위 밖).
      - 디버그 빌드는 파일을 처음 열 때 500ms 넘게 멈춰, 빠른 더블클릭이 두 번 누르기로 세어질 수 있다.
      - 잘못된 이름 거부는 배너 없이 입력칸을 연 채 둔다(원문 문구 없음).
      - 재분석 지점(정션·심볼릭 링크)은 복사 때 따라가지 않고 건너뛰고, 링크가 든 폴더의 다른 볼륨 이동은 거부한다(D-044).
      - A-28.5 케이스 폴딩 표 한계(Phase 3 에서 이어짐, D-040).
    - Phase 4 구현 항목 끝의 "Phase 4 리뷰(wg-reviewer)와 커밋은 아직이다"는 그 시점의 기록이다. 리뷰는 위 "리뷰 1회차"·"리뷰 2회차" 항목에 있다.
    - PLAN 의 Phase 4 완료 조건 중 "Phase 4 커밋이 있다"는 이 기록 뒤의 커밋으로 채운다.

### Phase 5 — 디스크 감시·변경 감지

아직 없음.

## 사용자 요청 작업

없음.

## 버전 종료

진행 중.

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

아직 없음.

### Phase 3 — 사이드바 폴더 등록·선택·해제

아직 없음.

### Phase 4 — 프로젝트 패널 트리·파일 작업과 시나리오

아직 없음.

### Phase 5 — 디스크 감시·변경 감지

아직 없음.

## 사용자 요청 작업

없음.

## 버전 종료

진행 중.

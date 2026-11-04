# Phase 3 최종 확인

결론: REWORK

What this change does: 탭 편집·인코딩 보존 저장·저장 질문과 디스크 충돌/삭제 표시를 추가한다. master 통합 결과의 정확성 및 R-9·R-10·R-11·R-15 증거를 판정했다.

- 대상: master `37be4189615308be293093bbe750eeb5e5cc9a6a`, `git diff 20cc514..37be418 -- src` 전체 14개 파일. Phase 4 선행 worktree 코드는 포함하지 않았다.
- 검증 전후 HEAD 동일. src·Cargo 파일의 미커밋 변경 없음. 기존에 수정/미추적 상태인 v0.4 문서·측정 산출물은 현재 제공된 증거로 읽었고 변경하지 않았다.
- ponytail-review 및 별도 정확성 리뷰 수행. 기존 인코딩 코드와 표준 파일 API·저장/읽기 token·대화상자를 재사용했고 의존성 변경 없음. 아래 두 데이터 보존 경계는 카드별 통과와 별개로 통합 코드에 남아 있다.

## Must fix

1. **저장 중 rename/move 뒤 다른 경로에 쓴 결과로 탭을 clean 처리한다.**
   - 위치: `src/ui/tab_close.rs:245,279~288`, `src/ui/pane.rs:381~395,447~452`; 호출부 `src/ui/panel_ops.rs:213` 및 `src/ui/panel_edit.rs:279`.
   - 역할: 저장 시작 시 경로를 캡처하고 백그라운드에서 쓴 뒤, 저장 token으로 현재 탭의 기준 hash·dirty 상태를 갱신한다.
   - 사유: 파일 A의 디스크 내용은 old, 버퍼는 new인 상태에서 Save를 시작한다. probe가 A를 읽은 뒤 쓰기가 완료되기 전에 앱의 트리에서 A를 B로 rename하면 탭 경로는 B로 바뀌지만 saving token은 유지된다. 저장 작업은 캡처한 A에 new를 쓰며, A가 없어도 `state::win::replace_file`은 새 파일 생성 경로를 허용한다. 완료는 그 token을 가진 B 탭을 찾아 hash=new·dirty=false로 만든다. 실제 B는 old인데 화면은 new인 clean 탭이 된다. 이후 닫으면 묻지 않고 버퍼를 잃거나 reload가 old로 덮을 수 있다. 비동기 쓰기 중 UI의 rename을 막거나 직렬화하는 경로가 없다.
   - 기대 수정: 앱 내부 파일/상위 폴더 rename·move와 저장 작업의 경로 변경을 조정한다. 진행 중 저장의 경로 변경을 안전하게 직렬화/보류하거나, 쓰기 대상과 현재 파일의 연결을 보장하는 공통 경로를 둔다. 단순히 완료 시 현재 경로만 다시 읽어 clean 처리하거나 저장 future를 버리면 안 된다. Save 시작 → rename/move → 쓰기 완료에서 실제 대상 바이트와 탭 기준이 일치하고 미저장 버퍼가 보존되는 회귀 테스트를 추가한다.
   - 미수정 영향: 새 경로의 파일에 저장하지 않았는데도 저장됐다고 표시한다. R-10의 미저장 변경 보존을 충족하지 않는다.

2. **삭제된 비어 있지 않은 미리보기 탭을 다음 탐색이 질문 없이 버린다.**
   - 위치: `src/ui/pane.rs:122~124,294~301,327` (`modified`, `place`, Missing 처리).
   - 역할: 디스크에서 지워진 비어 있지 않은 버퍼는 modified로 취급하지만, 새 미리보기를 열면 preview 탭을 그대로 교체한다.
   - 사유: 트리에서 A를 한 번 눌러 preview로 열고 내용이 있는 상태에서 외부에서 A를 삭제한다. Missing은 deleted만 설정하므로 A는 modified=true·preview=true다. B를 한 번 누르면 `place`가 A를 무조건 교체하며 `tab_close`의 저장 질문을 거치지 않는다. 삭제 파일의 유일한 버퍼 사본을 사용자가 명시적으로 버린 적 없이 잃는다.
   - 기대 수정: 보존해야 하는 preview 버퍼를 일반 탭으로 승격하거나 교체 경로에서 modified/진행 중 저장을 확인해 보존한다. 빈 삭제 버퍼와 정상 clean preview 교체는 기존 동작을 유지한다. preview A 읽기 → 비어 있지 않은 A 삭제 → preview B 열기 순서의 최소 테스트를 추가한다.
   - 미수정 영향: E-087로 수정됨 표시를 했는데 다음 파일 탐색만으로 그 내용을 잃는다. R-10 보존 및 R-11 상태의 후속 동작이 일관되지 않는다.

## 전체 테스트·clippy

루트 master, `CARGO_TARGET_DIR=D:\projects\workbench-gpui\target`. 공유 worktree 산출물 혼동을 피하도록 대상 package test profile만 override하고 대상 crate 재컴파일을 확인했다.

- `cargo test --config 'profile.test.package.workbench-gpui.debug=1' --config 'profile.test.package.workbench-gpui.opt-level=0' -- --nocapture`: 전체 **134 통과 / 실패 0 / 제외 0**, exit 0. **1회만** 실행했다. spec 오류를 검증하는 `should panic` 테스트의 출력은 정상 통과다.
- `cargo clippy --all-targets -- -D warnings`: exit 0, 경고·오류 0.
- 별도 build·앱·UI 검증 스크립트는 실행하지 않았다. 실행/실측은 요청대로 measure 보고서를 근거로 판정했다.

## R-15: 실행 산출물 대조

`measure-phase3.md` 본문·R1, `PROGRESS.md` Phase 3 P3-E 대조표, R-1 기준선, `baseline/phase3/comparison.json`·`comparison-v04-phase2.json`·실제 results/log를 확인했다. **스크립트에서 관측한 차이의 분류는 타당하며 phase2 실행 공백은 해소됐다.** 이 판정은 위 정적 리뷰에서 발견한 미검출 경계를 없다고 선언하는 뜻이 아니다.

| 증거 | 판정 |
| --- | --- |
| F1: phase1 R-1 표 밖 Save·Ctrl-W·Ctrl-F4 | 실제 failures 배열의 새 바인딩 3개와 Phase 3 키맵 diff가 일치. 의도한 변경. 기존 키 실행 70개는 그대로 통과. |
| F2·F3·F4: Close Editor 행·원본 phase2 중단·phase3 메뉴 차이 | 실제 app_menu/키맵 추가와 일치. F3은 단순 면제하지 않고 H-21 사본의 전체 실행으로 보완. |
| F5: readonly 사례의 편집 후 len=40, 디스크 동일 | D-18 해제에 따른 의도한 변경. 자동 저장하지 않는 조건도 유지. 최초 표시 len=33→31은 내부 LF 정규화. |
| F6~F10: phase5 CRLF 길이/FNV 차이 | 원본 스크립트의 세 문자열을 LF로 바꿔 UTF-8 길이·FNV를 독립 계산했다. **38/facef83d0e9eaa58, 54/97899cbe95ed7094, 32/79dfa0fcb8242014**로 실제 got·reload 로그와 정확히 일치. 삭제 후 유지한 FNV도 두 번째 값과 일치. 원본 대기 조건의 ok=False를 자동 reload 실패 자체로 해석하지 않는다. |
| 사이드바와 메뉴/툴팁 좌표 변화 | Phase 2 폭 변경에 따른 -75와 일치. phase2 사본의 값 차이는 툴팁 6개·File 행·menu I-314의 x -75, 총 8개. |
| scroll -23→-234, flood 1815→1806 | `phase2b/history-values.txt`에 해당 값의 과거 실행 이력이 있고 코드 변경과 관계없는 표본 변동으로 분류할 근거가 있다(H-10). |

원본 9개의 기준 항목 수는 각각 70·137·122·208·13·6·62·23·16이다. phase2는 원본 89개에서 중단했지만 사본 결과에 **137 checks / failed 0 / failures 0 / 단축키 행 32개 불일치 0** 및 11개 사례 전부가 존재한다. 원본 중단 후 미평가 항목을 사본 결과로 대체해 R-1 항목을 모두 대조했다. phase3의 과거 기준 실패 2개가 현재 1개인 점도 raw 결과에 남겼다. 보고서 F1~F10은 설명 항목 번호이며, F1의 바인딩 3개와 F3의 스크립트 중단을 모두 단일 체크 실패처럼 합산하지 않는다.

### 사본 diff 확인(H-21)

- 실제 `git diff --no-index tools/verify-v02-phase2.ps1 specs/v0.4/verify/scripts/verify-v04-phase2.ps1`를 읽고 저장된 `.diff`의 모든 hunk와 일치함을 확인했다.
- 의미 있는 기대값 변경은 **Close Editor 하나**다. `$orig`에 `pane::CloseActiveItem / Ctrl+F4`를 넣고 File 기대 행에 `Close Editor|Ctrl-F4`를 넣었다. 다른 기대값·검사·사례는 바꾸지 않았다.
- 나머지 한 줄은 사본의 위치가 달라진 데 따른 `tools\capture.ps1` 절대 경로 보정이다. 이는 새로운 동작 기대를 면제하는 변경이 아니다.
- 실패하던 중간 참고 사본(`verify-v02-phase2-patched.ps1`)은 최종 근거에서 제외하고 H-21의 `verify-v04-phase2.ps1` 결과를 사용했다. 원본 스크립트와 지난 버전 문서는 수정하지 않았다.

## R-9·R-10·R-11 및 V3

| 요구 | 통합 판정 및 증거 |
| --- | --- |
| R-9 편집·수정 표시 | 편집·dirty 승격/해제, 탭 점과 readonly 해제 연결은 카드 P3-1-2 R2·P3-4b-1·P3-4b-2 및 전체 테스트에서 확인. V3에서 수정 점 10×10·시작 슬롯 배치 통과. **Accent의 정확한 색은 미확정**이며 동일 색 재현까지 PASS라고 쓰지 않는다. |
| R-10 저장·질문·인코딩·데이터 보존 | P3-1-2 R2·P3-3 R3의 기존 지적 해소와 CP949 손실 거부·원자 교체 실패 처리·대기 상한을 확인. V3 저장 질문 문구/버튼 순서 통과. 다만 **새 Must fix 1·2로 REWORK**. |
| R-11 충돌·삭제 표시·clean reload | P3-4a R1·P3-4b-2와 V3의 충돌/삭제 로그·Warning 점·취소선 확인. clean reload의 LF 결과도 R-15 원시 자료와 일치. 삭제된 preview의 후속 보존은 Must fix 2로 미해소. |

- `measure-phase3.md`의 새 화면은 수정 점 10×10, 슬롯, 저장 질문, 충돌 점, 삭제 취소선의 증거를 제시한다. check-layout은 별도 보고서 `_check-layout-phase3.md`에서 **exact 28/28 PASS**다.
- Accent 값이 스펙에 없어 theme.primary=(23,23,23)로 근사한 항목은 **측정 불가 1/사용자 확인 필요**다. Warning=(234,179,8)은 테마 토큰 연결·서로 다른 색의 표시까지 확인한 것이며 정확한 Zed 색 수치 일치 증거는 아니다. PROGRESS도 이 한계를 사용자 확인 목록에 남겼다.
- H-15의 편집한 혼합 줄 끝 통일, H-17의 세션 복원 대신 종료 질문, H-18의 mtime 대신 원본 바이트 기준을 승인된 정책 차이로 유지한다. 이 결정들이 위 두 데이터 보존 결함을 허용하는 근거는 아니다.

Verdict: fix 1 and 2 first.

Not checked: 앱·실제 rename/저장 경합 재현은 실행하지 않았다. 전체 테스트는 한 번 통과했으며 위 경계는 코드 확인이다. src·공유 문서는 수정하지 않았고 PROGRESS 반영은 lead에게 전달한다.

## R1

결론: REWORK

What this change does: 저장 중 캡처한 경로와 완료 시 탭 경로가 다르면 저장 기준을 갱신하지 않는다. 보존해야 하는 preview는 교체 대신 일반 탭으로 승격한다.

- 대상: H-23의 `work/p3fix` / `9321613`, `git diff 37be418..9321613`. `.worktrees\editor`가 해당 브랜치·커밋임을 확인했고 검증 전후 수정 없음. 앞선 Must fix 1·2만 재검토했다.
- **Must fix 2 해소:** `src/ui/pane.rs:298~313`의 `place`는 기존 preview가 modified이거나 saving 중이면 preview=false로 승격하고 새 탭을 삽입한다. 비어 있지 않은 삭제 파일은 원래 버퍼·deleted·modified 상태로 남는다. 빈 삭제 preview와 정상 clean preview의 교체는 유지된다. 추가 테스트도 이 세 경우를 확인한다.
- **Must fix 1 일부 해소:** `begin_save`는 saving_path를 기록하고 `finish_save`는 현재 path가 같을 때만 성공 기준 hash를 채택한다. 추가 테스트의 “rename 뒤 옛 경로 쓰기 완료, dirty=true 유지”는 통과한다. 그러나 rename/move와 실제 저장 I/O를 조정하지 않았으며, 경로가 다른 완료 분기는 기존 dirty 값에만 의존한다.

### 남은 Must fix 1

1. **저장 중 undo가 있었으면 경로 불일치 완료도 거짓 clean을 남길 수 있다.**
   - 위치: `src/ui/pane.rs:392~405` (`finish_save`의 `ok && tab.path == tab.saving_path` 분기), `src/ui/tab_close.rs:279~288`의 실제 쓰기/완료 분리 및 기존 `rename_path`/`apply_move`.
   - 구체적 순서: a.txt에서 old를 읽고 new로 편집해 저장을 시작한다. 저장이 실행 중일 때 undo로 버퍼를 old로 되돌리면 dirty=false다. 백그라운드 쓰기가 a.txt를 new로 교체하고, UI 완료 콜백이 처리되기 전에 앱의 rename이 a.txt를 b.txt로 옮긴다(이름 변경 핸들러 실행과 worker 완료는 조정되지 않는다). b.txt의 실제 내용은 **new**지만, 콜백은 경로가 다르다는 이유로 기준 갱신을 건너뛰어 hash=old·dirty=false를 유지한다. b.txt 탭의 버퍼는 **old**인데 `close_state`는 Clean이다. watcher가 saving 중 읽은 결과도 버림 경로라 이 상태를 자동으로 고쳐 준다는 보장은 없다.
   - 사유: 새 주석의 “rename이 옮긴 파일은 항상 마지막으로 읽은 내용”이라는 전제가 성립하지 않는다. 실제 저장 교체가 rename보다 먼저 끝날 수도 있다. `buffer_hash`를 전달받지만 경로 불일치에서는 미저장 여부를 재판정하지 않는다.
   - 기대 수정: 저장과 앱 내부 rename/move를 안전하게 직렬화/보류하거나, 경로 불일치로 현재 디스크 상태를 확정할 수 없을 때 기존 dirty=false만 믿지 않고 버퍼를 보존해야 하는 상태로 남긴다. 저장 완료 전에 undo한 경우와 실제 쓰기가 rename 전/후에 끝난 양쪽 순서를 검증한다. 현재 테스트처럼 dirty=true인 한 순서만 확인해서는 부족하다.
   - 미수정 영향: 현재 파일과 다른 버퍼를 질문 없이 닫거나 다시 읽기로 덮을 수 있어 R-10 데이터 보존을 아직 충족하지 않는다.

### 추가 테스트

공유 `CARGO_TARGET_DIR=D:\projects\workbench-gpui\target`, `.worktrees\editor`에서 `cargo test --config 'profile.test.package.workbench-gpui.debug=1' --config 'profile.test.package.workbench-gpui.opt-level=1' <filter> -- --nocapture`로 각각 실행했다. 대상 crate 재컴파일을 확인했고 target 잠금은 기다렸다.

- `rename_during_save_keeps_tab_unsaved`: 1 통과, 실패 0.
- `deleted_nonempty_preview_is_kept`: 1 통과, 실패 0.
- 합계 **2 통과, 실패 0**. 지시에 따라 전체 테스트·clippy·기존 통과 검증·R-15/V3는 반복하지 않았다.

Verdict: fix the remaining part of 1 first.

Not checked: 앱·실제 저장/rename 경합은 실행하지 않았다. 남은 undo 순서는 완료 분기와 호출부의 코드 확인이다. src·공유 문서는 수정하지 않았으며 PROGRESS 반영은 lead에게 전달한다.

## R2

결론: PASS

What this change does: 성공한 저장의 경로가 현재 탭 경로와 다르면 디스크 기준을 확정하지 않고 dirty=true로 유지한다. 저장 중 undo가 있어도 버퍼를 보존하고, 새 경로에서 확인 후 저장해야 기준이 다시 확정된다.

- 대상: `git log -1`로 확인한 `work/p3fix` 최신 커밋 `72c3ac7ad01a6cfd1f3b0b3a7c2ffb92865862e4`, `git diff 9321613..72c3ac7`. `.worktrees\editor` 검증 전후 HEAD 동일, 수정 없음. R1의 남은 Must fix 1만 재검토했다.
- **남은 1 해소:** `src/ui/pane.rs:405`의 경로 불일치 성공 분기는 `hash`·`disk_hash`를 확정 불가 기준 `UNSURE_HASH`로 바꾸고 dirty=true를 명시한다. 실제 쓰기가 rename 전/후에 끝났는지 추측하지 않으므로, 앞서 dirty=false였던 undo 경로도 clean으로 남지 않는다.
- 후속 `on_edit`도 원래 old/new 텍스트를 확정 불가 기준과 비교하므로 dirty를 유지한다. `close_state`는 Ask, reload는 버퍼 Fill 없이 디스크 상태만 기록한다. 실제 `save_tab`의 원본 바이트 guard도 확정 불가 기준을 받아 현재 파일의 덮어쓰기를 확인한다. 현재 경로의 저장이 성공하면 실제 쓴 hash를 채택하고 상태가 정상적으로 정리된다.
- 확정 불가 기준은 별도 타입 대신 FNV 값 0을 예약하는 shortcut으로 구현됐으며 실제 hash=0과의 충돌 한계가 주석에 명시됐다. 기존 hash 기반 판정의 한계를 없애는 변경으로 보지는 않는다.

### 추가·변경 테스트

공유 `CARGO_TARGET_DIR=D:\projects\workbench-gpui\target`, `.worktrees\editor`에서 `cargo test --config 'profile.test.package.workbench-gpui.debug=1' --config 'profile.test.package.workbench-gpui.opt-level=2' <filter> -- --nocapture`로 각각 실행했다. 대상 crate 재컴파일을 확인했고 공유 target 잠금은 기다렸다.

- 추가 `undo_during_save_then_rename_stays_unsure`: 1 통과, 실패 0. 현재 파일 내용이 new/old인 두 순서, 닫기 Ask, 후속 편집에서도 dirty 유지, reload 버퍼 보존·충돌 표시, 새 경로 재저장 성공 뒤 정상화를 검증한다.
- 변경 `rename_during_save_keeps_tab_unsaved`: 1 통과, 실패 0. 경로 불일치 후 확정 불가 hash 및 재저장 결과를 확인한다.
- 합계 **2 통과, 실패 0**. 이전 통과한 Must fix 2·전체 테스트·clippy·R-15/V3는 재실행하지 않았다.

Verdict: Ship for Phase 3 final R2. R1에서 통과한 삭제 preview 보존과 함께 최초 최종 확인의 두 지적을 종료한다. 전체 테스트 134개·strict clippy 및 R-15/V3의 기존 증거와 색상/정책 차이 사용자 확인 목록은 본문대로 유지한다. 병합 대상은 이 수정 브랜치이며 master 병합 판단은 lead에게 전달한다.

Not checked: 앱·실제 저장/rename 경합은 실행하지 않았다. src·공유 문서는 수정하지 않았으며 PROGRESS 반영은 lead에게 전달한다.

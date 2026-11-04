# P3-F Phase 3 최종 확인

- reviewer: Codex, 2026-11-04.
- 대상: master `4611dd3b35c531aaf7215dd7d7b58548e0e37e06`. 정확성 비교: `git diff v0.3-phase-2..69a50ce -- src`. `69a50ce..4611dd3 -- src` 차이 없음. 작업 시작 시 변경 파일 없음.
- AGENTS.md 7.1·7.1a, TASKS Phase 3, AUDIT 8~11, 기존 묶음 리뷰, PLAN·HERDR-SETUP·HANDOFF·spec/INDEX 및 R-12/V3 산출물을 읽었다.
- src 수정, 커밋, 앱 실행 없음. 공유 PROGRESS·TASKS·HANDOFF는 lead 소유이므로 이 보고서로 전달한다.

## 수정 필요

1. **P3-2 완료 조건의 비활성 항목 회귀 테스트가 없다.**
   - 위치: `src/ui/menu_common.rs:138–153` 테스트 모듈, `src/ui/context_menu.rs:316–322` item_index 및 `:376–402` intercept.
   - 사유: TASKS P3-2는 세대 보호와 비활성 항목 규칙을 잡는 테스트를 명시한다. 신규 테스트는 `late_timer_does_not_end_a_newer_wait` 하나로 토큰과 버퍼만 검사한다. context_menu에는 테스트가 없고 전체 테스트 57개에도 비활성 단축키 규칙 검증이 없다. 기존 묶음 리뷰의 enabled 코드 확인은 이 완료 조건을 대신하지 못한다.
   - 구체적 사례: 비활성 항목의 액션으로 해석된 단일 키는 예약하지 않고 false를 반환해야 한다. 같은 액션의 다중 키 chord는 예약하지 않으면서 이미 소비한 접두 때문에 true를 반환해야 한다. 접두 확정도 비활성 항목을 예약하면 안 된다. 현재 코드는 이 규칙을 보존하지만 이를 깨는 변경을 신규 테스트가 잡지 못한다.
   - 기대 수정: 기존 세대 테스트를 유지하고, 공통 chord 해석과 컨텍스트 메뉴의 enabled 판정을 함께 거치는 최소 회귀 테스트를 추가한다. 비활성 항목에서 pending/선택/실행이 생기지 않음과 단일 키·chord의 소비 차이를 단언한다. 운영 동작 변경이나 앱 수동 조작은 필요 없다. 이후 관련 테스트만 재검증하고 이 항목을 재리뷰한다.

## 정확성 리뷰

- 메뉴 스타일: list의 id→최소 폭→padding→최대 높이→스크롤, row의 id→margin→padding→radius→정렬→글자 크기→줄 높이, popup의 occlude→배경→글자색→테두리→radius→그림자 순서가 보존된다. separator·shortcut_cell도 기존 순서와 metrics 값을 쓴다. 각 메뉴의 enabled·선택색·hover/click·action·키 컨텍스트·포커스·probe ID가 호출부에 그대로 남는다.
- 안내 화면: 동일 바탕만 로컬 guide closure로 추출했다. probe 등록이 바탕 설정 뒤로 이동했지만 스타일 덮어쓰기는 없고 각 분기의 문구·버튼·probe 이름을 유지한다. V3 박스와 픽셀 결과도 동일하다.
- Chord: pending 우선 판정, 단일/다중 키 구분, 실패 접두를 take한 뒤 현재 키 재처리, 최장 접두에서 처음 발견한 액션만 반환하는 순서가 동일하다. 최장 액션이 메뉴에 없거나 비활성이어도 더 짧은 접두로 내려가지 않는 기존 동작을 유지한다.
- 토큰: wait마다 증가하며 take_expired는 같은 토큰과 비어 있지 않은 버퍼를 요구한다. clear는 기존처럼 버퍼만 지우고 토큰은 보존한다. 재대기가 시작되면 새 토큰으로 이전 타이머가 무효가 된다. 메뉴 열림/closed 가드도 유지한다.
- CHORD_TIMEOUT은 기존 metrics의 1초, SHORTCUT_FLASH는 기존 50ms다. 액션 객체/항목 인덱스의 차이, 예약 generation 검사, F10, 닫힘과 포커스 복원은 각 메뉴에 남아 있다.
- 비활성 규칙은 코드 읽기로 보존 확인: item_index가 enabled를 검사하며 intercept의 미예약 반환은 chord 불리언이다. 실행 경로 execute도 enabled를 다시 검사한다. 위 테스트 누락과 실제 동작 결함은 구별한다.
- dev::now_ms는 기존과 같은 u128, as_millis(), epoch 이전 오류 시 0이다. 세 모듈의 모든 호출이 공통 함수로 연결되고 로그 형식은 불변이다.
- 발견한 동작·값 회귀: 없음. 파일 쓰기/보안 경계/의존성 변경도 이 diff에 없다.

## R-11 재감사

검색: `rg -n 'now_ms|duration_since\(.*UNIX_EPOCH|\.mx\(ROW_MARGIN_X\)|\.min_w\(MIN_WIDTH\)|\.ml\(SHORTCUT_GAP\)|fn resolve|fn prefix_action|pending_input|chord_token|CHORD_TIMEOUT|EMPTY_BODY_PADDING' src` 및 세 메뉴 관련 파일의 전체 호출 흐름 확인.

| AUDIT | 결과 |
| --- | --- |
| 8 | 동일 list·separator·row·shortcut·popup 스타일은 menu_common에 각 1개. 메뉴별 이벤트·색 분기는 필요한 차이로 유지. |
| 9 | 입력 버퍼·토큰·resolve·최장 접두 해석은 Chord/공통 함수로 통합. pending_input/chord_token 잔여 0. 메뉴별 타이머 실행과 예약 래퍼는 수명·실행 모델 차이 때문에 유지. 구현 통합은 완료, 카드의 비활성 테스트는 미완료. |
| 10 | EMPTY_BODY_PADDING을 쓰는 안내 바탕은 folders의 guide 1곳. |
| 11 | now_ms 정의는 dev 1곳, app_menu/context_menu/tooltip은 import. watch::epoch_ms(u128)와 state 시간 형식은 범위 밖으로 유지했으며 무단 통합하지 않음. |

## 실행 검증

- 환경: `CARGO_TARGET_DIR=D:\projects\workbench-gpui\target`, cargo는 `C:\Users\nampl\.cargo\bin\cargo.exe`, 해당 bin을 PATH에 추가. 명령은 RTK proxy로 실행했다. 초기 PATH 탐색 실패 때는 테스트가 실행되지 않았다.
- `cargo test` 전체 정확히 1회 실행: exit 0, **57 passed / 0 failed / 0 ignored**, 신규 늦은 타이머 테스트 포함.
- `cargo clippy --all-targets -- -D warnings`: exit 1. 기준선 `p0-0b-clippy.log`의 10개 진단만 오류로 승격됨. **신규 0개**. clippy 자체 통과로 표현하지 않는다.
- 대조: dev.rs:266 manual_is_multiple_of, :270 chunks_exact_to_as_chunks; fsops/ident.rs:53 unnecessary_lazy_evaluations; names.rs:99 question_mark; tree.rs:201 needless_range_loop; state/mod.rs:13 doc_lazy_continuation; ui/keymap.rs:520 redundant_closure; layout.rs:143·395 doc_lazy_continuation; watch.rs:274 manual_is_multiple_of. dev 줄 번호 이동 외 기준선과 동일.
- 별도 build·추가 전체 테스트·UI 실행은 하지 않았다. 이번 리뷰는 최종 확인용 지정 명령만 실행했다.

## R-12 및 V3 판정

- README·comparison.json, 비교 스크립트, run-index와 rerun-index, 첫 실행 console/results, 백업 after.json, V3 box-diff.txt·png-region-diff.txt 및 measure-phase2/phase3 보고서를 대조했다.
- 최종 9개 결과: phase2 137/0, phase3 122/2, phase4 208/0, d043 13/0, d044 6/0, phase5 62/0, d046 23/0, d047 16/0. phase1은 checks 배열이 없고 9사례·R-1 표가 동일하다. d043-clip 제외는 기준선과 같다.
- phase3의 실패는 기대 300/494 대비 실제 375/617로 기준선과 동일한 Q-15 두 건이다. 새로운 실패가 아니다. GUID 경로 및 flood 이벤트 수 1818→1831 때문에 생긴 itemDiffs 두 쌍은 양쪽 ok=True다.
- **재실행 처리 타당**: 1차 exit 1은 5개이나 그중 phase3는 위의 기존 실패다. 새 환경 간섭을 보인 것은 phase1·phase2·phase4·d043 네 스크립트이며 이 네 개만 1회 재실행했다. 첫 결과를 _first-run에 보존했다. 로그에서 실제 창 이동, 전면 창 불일치로 입력을 보내지 않은 사례를 확인했다. 일부 실패는 기능 단언 실패 형태로도 나타나므로 '전부 기능 단언 실패가 아님'이라는 README 표현보다, 입력/캡처 간섭 뒤 발생하고 동일 exe 재실행에서 해소됐다는 근거로 판단한다.
- 재실행 네 개 exit 0·실패 0, 나머지 다섯 개 1차 결과 유지. 두 백업 after.json 모두 restored=true, exeHash 모두 `9D2559CDFFCC82A9BD51433870FA1577409A022AA88253ADD48F57B040A08B44`. phase4 계열 클립보드 0 확인 절차도 실행기에 있다.
- V3: Phase 2 대비 S1 57/57·S5 249/249·S6 262/262·경로 없음 58/58 박스 차이 0. P0 대비 tree-label-03 및 tooltip-box 차이는 Phase 2와 동일. 대상 메뉴/안내 화면 픽셀 diff 0. png-region-diff에는 최초 Rect 인자 변환 오류와 이후 올바른 영역 비교 성공을 함께 보존했으며 후속 성공 결과가 보고값을 뒷받침한다.
- R-12 동작 불변 및 지정 V3 결과는 수용한다. 원본 이미지 픽셀 계산을 다시 실행하거나 앱을 띄우지는 않았다.

## ponytail-review

What this change does: 두 메뉴의 같은 스타일과 chord 상태 해석을 공유한다. 안내 바탕과 로그 시각 계산도 기존 값으로 재사용한다.

Should fix: 위 1번의 명시된 회귀 테스트 누락. 단일 사용자 Windows 편집기의 기존 입력량을 전제로 읽었으며 새 보안·데이터 손실·성능 문제나 불필요한 추상화는 발견하지 못했다. 함수 5개와 작은 상태 타입으로 범위를 제한했고 의존성 변경은 없다.

Verdict: fix 1 first.

실측 필요: 추가 없음(지정 P3-E 결과 수용). 사용자 확인 필요: 신규 없음. 기존 한계: 라이트 고정으로 다크 렌더 미측정, 글자 크기의 절대 px 판정 대신 픽셀 동일성만 확인.

Not checked: 앱 실행·재실측·원본 픽셀 재계산·범위 밖 기능은 생략했다. 비활성 항목 규칙은 코드 확인만 되어 회귀 테스트 보장이 남아 있다.

결론 REWORK

## R1

- 대상: work/ui `282cfae`, worktree `D:\projects\workbench-gpui\.worktrees\ui`. 커밋 `282cfae`를 부모 `157808e`와 대조했다. 사용자 지정 H-30에 따라 Cargo 변경 없이 순수 decide 함수와 일반 테스트로 검증한다.
- 정확성: closed → is_list_key → Chord::feed 순서를 유지한다. decide는 Wait/Action/Replay/Pass를 같은 순서와 의미로 옮긴다. 활성 Action은 예약 후 true, 미예약 Action은 기존 chord 불리언을 반환한다. Wait는 타이머 후 true, Pass는 false다.
- Replay는 prefix_action 결과에 enabled item_index를 적용하고, 있으면 schedule_item한 뒤 같은 이벤트로 intercept를 다시 호출한다. 예약이 발생할 때의 clear/generation 증가도 기존 schedule_item 그대로다. Replay 결과를 현재 키의 소비 결과로 잘못 반환하지 않았다.
- replay_prefix의 중첩 if-let → and_then은 첫 Option이 Some일 때만 item_index를 호출하며 결과가 Some일 때만 예약하므로 동작 불변이다. 타임아웃 경로도 이 함수를 계속 사용한다.
- `disabled_item_is_never_reserved`는 비활성 단일 키의 None/false, 비활성 chord의 None/true, 비활성 접두 확정의 None, 활성 Action의 Some(1)/true, 활성 접두 확정의 Some(1)을 단언한다. 기존 늦은 타이머 테스트도 유지한다.
- 테스트 한계: Feed를 직접 만들고 enabled 조회와 prefix_action도 테스트 함수로 공급한다. 실제 Chord::feed의 키맵 해석, 실제 ContextMenu::item_index 및 타임아웃 replay_prefix 호출, 재귀 재처리와 실행 이벤트까지 통합 검증하지 않는다. 이 부분은 운영 호출부 코드와 이전 diff를 대조했다. H-30으로 승인된 순수 판정 테스트 범위에서는 이전 REWORK의 필수 소비/예약 규칙을 검증하므로 수용한다. 전체 chord 상호작용 검증으로 확대 해석하지 않는다.
- 검증: worktree에서 공유 CARGO_TARGET_DIR로 전체 cargo test 1회, 59 passed / 0 failed. cargo clippy --all-targets 1회 exit 0, 기준선 경고 10개만 존재하고 신규 0. P3-D 검증과 같은 실행을 공유했으며 반복하지 않았다.
- ponytail-review: 추출된 판정은 운영 intercept가 직접 사용한다. 새로운 의존성·설정·범위 밖 동작 변경 없음. 추가 수정 요구 없음.
- 실측 필요/사용자 확인 필요: 신규 없음. src 수정·커밋·앱 실행 없음. 공유 PROGRESS는 lead가 이 절을 근거로 갱신한다.
- 생략·위험: 실제 키 입력/타이머 통합 테스트는 수행하지 않았다. Feed 및 조회 stub을 통한 판정 단위 테스트라는 한계가 남는다.

결론 PASS

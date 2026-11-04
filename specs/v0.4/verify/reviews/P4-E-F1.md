# P4-E-F1 리뷰

결론: REWORK

What this change does: 첫 화면의 탭 바 끝 단추를 복원하고 Markdown h1·h2에 아래 여백과 선을 추가한다. 링크 밑줄 불투명도의 의존성 한계도 확인한다.

- 대상: `work/ui`의 `2e3dc5191cac53a12edecc31ea06a4d6b8ccb6e3`, `.worktrees\ui`. 대상 커밋 diff·연결 호출부·설치된 gpui-base/component 구현을 읽었다. 검증 전후 HEAD 동일, worktree 수정 없음.
- 기준: `measure-phase4.md` U1·L-105·L-108, Phase 3 `37be418`의 tab_bar, 원문 I-706·I-707 및 01-LAYOUT 5절. ponytail-review와 별도 정확성 리뷰를 수행했다. 여러 제목·참조 링크를 포함한 일반 Markdown 문서를 기준으로 보았다.

## Must fix

1. **서로 다른 제목이 같은 TextView 상태 ID를 사용한다.**
   - 위치: `src/ui/markdown_preview.rs:181~186` (`with_heading_rules` renderer).
   - 역할: 제목마다 별도 TextView를 만들고 상태를 식별한다.
   - 사유: ID가 길이와 바이트 합으로만 정해진다. 문서 `# AB\n\n# BA`의 두 제목은 모두 `md-heading-322`가 된다. 반복된 동일 제목도 같은 문제다. 설치된 TextView는 이 ID로 window.use_keyed_state를 사용하고 매 layout에 해당 상태의 text를 갱신한다. scrollable(false)의 문서 root와 CustomBlockElement에는 제목별 식별 범위를 추가하는 wrapper가 없으므로 같은 문서 안의 두 제목이 상태 키를 충돌시킨다. 단순한 순서 바뀐 제목만으로 선택·포커스·텍스트 상태가 독립적이지 않게 된다.
   - 기대 수정: 별도 TextView를 유지한다면 문서/pane 및 블록 위치·인스턴스를 포함하는 ID를 사용한다. 문자열 해시만 개선해서는 동일 제목 반복을 해결하지 못한다. `# AB`/`# BA`와 동일 제목 두 개를 구별하는 최소 회귀 검증을 추가한다.
   - 영향: 흔한 여러 제목 문서에서 제목별 입력/선택 상태가 충돌한다. 현재 rule_level 테스트는 이를 검사하지 않는다.

2. **제목을 단독 문서로 재파싱해 참조형 링크를 잃는다.**
   - 위치: `src/ui/markdown_preview.rs:172~186` (`MarkdownNode` 생성과 중첩 TextView::markdown).
   - 역할: 기존 Heading 대신 원문 한 줄을 별도 Markdown 문서로 렌더한다.
   - 사유: `# [Guide][docs]\n\n[docs]: https://example.com`에서 새 내부 TextView에는 `# [Guide][docs]`만 전달된다. 원문 문서의 정의 `[docs]: ...`와 link_refs 문맥은 전달하지 않는다. 기존 renderer는 전체 문서의 LinkReference와 node_cx.link_refs를 사용하지만, 새 경로는 정의 없는 별도 문서를 파싱하므로 제목의 참조 링크 표시·연결을 보존하지 못한다. 선을 추가하는 변경이 기존 Markdown 내용을 바꾼다.
   - 기대 수정: 이미 파싱된 제목의 inline 내용과 문서 참조 문맥을 보존해 선/여백만 더하거나, 별도 뷰가 필요한 경우 문서 수준의 참조 정보를 유지한다. 문서 뒤에 정의된 참조 링크를 가진 h1/h2의 회귀 검증을 추가한다. 의존성 변경이나 전체 Markdown renderer 재작성은 요구하지 않는다.
   - 영향: 보통의 참조형 링크 문법이 h1·h2에서만 기존과 다르게 표시되거나 열리지 않는다.

## 코드 확인

- **U1 복원 PASS:** 폴더 없는 분기가 기존 layout::tab_bar에 Some(BarEnd)를 전달한다. Phase 3와 같은 `tab-btn-new`·`tab-btn-split`·`tab-btn-zoom` 및 icon probe, 같은 `New…`·`Split Pane`·`Zoom In` tooltip/Zoom 액션 표기를 재사용한다. 크기·간격·툴팁 구현을 새로 복제하지 않았다. 첫 화면에서 New는 기존과 같이 동작 연결이 없고, zoom callback은 무동작이며 split은 I-707에 따라 비활성 표시한다. Phase 3의 split은 비활성 opacity 처리가 없었으므로 그 표시 차이는 명시한다.
- **활성 pane:** 실제 pane_el의 focused는 `group.active == id`다. 다중 pane에서는 활성 pane에만 끝 단추를 전달한다. 단일 pane은 유일 pane으로 표시하며 활성 pane 모델을 변경하지 않는다. 기존 분할/확대 callback은 유지된다. first_screen_end의 무동작 callback은 workspace가 없는 분기에만 사용한다.
- **L-105 수치:** h1 padding 8, h2 padding 4, 두 선 두께 1을 spec ID로 검증한다. 일반 한 줄 `# `·`## `는 wrapper가 해당 선·여백을 그린다. 다만 위 두 내용/상태 회귀 때문에 이 구현을 승인하지 않는다. setext 제목과 상단 여백을 기존 컴포넌트에 맡긴다는 shortcut, border_variant 대신 theme.border 사용 한계는 명시돼 있다. 전체 제목 문법의 L-105 충족으로 확대 판정하지 않는다.
- **L-108 확인:** 설치된 gpui-base 0.8.1 `src/text/node.rs:3208`의 link_underline은 thickness=1, style.link().opacity(0.4)다. 실측 0.40의 원인은 이 코드이며 AA 추정으로 설명할 항목이 아니다. 직접 설정하는 공개 밑줄 불투명도 setter는 현재 사용한 style API에서 확인되지 않았다. 기대 0.5와의 차이는 컴포넌트 한계로 유지하고, 이번 카드에서 충족으로 판정하지 않는다.
- frontmatter hook과 heading hook은 parser 목록에 추가되므로 기존 frontmatter 등록을 덮어쓰지는 않는다. Cargo 변경 없음. src는 수정하지 않았다.

## 검증

공유 `CARGO_TARGET_DIR=D:\projects\workbench-gpui\target`, 대상 crate 재컴파일 확인.

- `cargo build --config 'profile.dev.package.workbench-gpui.debug=1' --config 'profile.dev.package.workbench-gpui.opt-level=1'`: exit 0. apply-manifest.ps1 적용 뒤 commonControlsV6·perMonitorV2·longPathAware 전부 true.
- `cargo test --config 'profile.test.package.workbench-gpui.debug=1' --config 'profile.test.package.workbench-gpui.opt-level=0' <filter> -- --nocapture`:
  - `ui::pane_view::tests::`: 6 통과(첫 화면 단추/활성 여부 테스트 포함).
  - `ui::markdown_preview::tests::`: 6 통과(새 제목 판정 및 L-105 spec 대조 포함).
- 합계 **12 통과, 실패 0**. 전체 202개는 실행하지 않았다.
- `cargo clippy --all-targets -- -D warnings`: exit 0, 경고·오류 없음.

실측 필요: measure가 U1 첫 화면 단추·툴팁의 미평가 28항목과 L-105 h1/h2 선·여백을 불일치 항목에 한정해 재확인한다. L-108 0.4 대 0.5 및 border 색/setext 한계는 기존 V3 불일치·사용자 결정 목록으로 유지한다. 이미 통과한 Phase 4 항목은 재측정하지 않는다. PROGRESS 반영은 lead에게 전달한다.

Verdict: fix 1 and 2 first.

Not checked: 앱·실제 입력/화면·전체 테스트는 실행하지 않았다. 테스트 통과는 지적한 제목 상태 충돌과 문서 참조 문맥 보존을 검증하지 않는다.

## R1

결론: PASS

What this change does: `work/ui`의 `256a688fd8560c4596cb933d40f11bf64b559187`는 H-25에 따라 제목 분리 렌더를 제거한다. U1 첫 화면 끝 단추 복원은 유지한다.

- **Must fix 1 해소:** `src/ui/markdown_preview.rs`에서 with_heading_rules·heading-rule·md-heading ID 생성·중첩 TextView가 모두 제거됐다. 문서 전체를 pane별 단일 TextView::markdown으로 전달하므로 새로 도입했던 제목 간 상태 ID 충돌 경로가 없다.
- **Must fix 2 해소:** 제목을 한 줄 문서로 재파싱하지 않고 기존 전체 문서 파서와 Heading renderer에 맡긴다. 제목과 뒤의 참조 정의가 동일 문서에 남아 기존 link_refs 문맥을 사용한다. 제목 원문을 별도 MarkdownNode로 바꾸는 경로도 없다.
- **U1 유지:** `git diff 2e3dc51..256a688 -- src/ui/pane_view.rs src/ui/layout.rs`는 비어 있다. 첫 화면 Some(BarEnd), 기존 단추/probe·툴팁 재사용, 다중 pane 활성 여부 판단과 첫 화면 split 비활성·zoom 무동작을 그대로 유지한다. first_screen_keeps_its_end_buttons 테스트도 남아 있다.
- **L-105 한계 처리:** 현재 gpui-component 0.8.1 TextView는 private inner를 감싸고, 공개 style은 component TextViewStyle을 받는다. compat.rs의 resolve_component_style은 heading 설정을 text_size로 변환하며 base의 with_heading 테두리·padding 설정을 노출하지 않는다. 따라서 H-25에 따라 L-105를 V3 불일치·사용자 결정 목록으로 남기는 처리를 수용한다. 선·여백을 충족했다고 판정한 것은 아니다. 코드에도 이 한계가 명시됐다.
- 삭제된 테스트는 철회한 rule_level 및 미사용 L-105 상수 검증에 한정된다. 기존 Markdown/frontmatter·U1 테스트는 유지된다. ponytail-review 및 정확성 코드 확인에서 이번 한정 범위의 추가 지적 없음.

확인: 최신 HEAD 확인, `git diff 2e3dc51..256a688 -- src`와 연결 코드 읽기. worktree 수정 없음. 요청된 Must fix 1·2 해소와 U1 유지 확인에 한정해 테스트·build·clippy는 재실행하지 않았다. src·공유 문서 수정 없음. PROGRESS 반영은 lead에게 전달한다.

실측 필요·사용자 확인 필요: U1의 기존 재측정 목록 유지. L-105와 L-108(0.4 대 0.5)은 컴포넌트 한계로 미충족 기록 및 사용자 결정 대상으로 유지한다.

Verdict: Ship.

Not checked: 앱·실제 입력/화면·테스트·build/clippy는 실행하지 않았다. 이번 PASS는 두 회귀 제거와 U1 유지에 대한 판정이다.

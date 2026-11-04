# P4-E-F3 리뷰

결론: PASS

What this change does: pane 트리에서 내부 경계인 면을 찾아 편집기 자체 테두리를 제거한다. 그 경계는 기존 분할선이 그리고, 바깥 가장자리와 확대 틀은 유지한다.

- 대상: `work/ui`의 `c594bedfc38452a42d5a5742bffbe4f06560a75a`, `.worktrees\ui`. diff·유일한 editor_view 호출부·gpui-component Editor/Input 스타일 적용 순서를 읽었다. ponytail-review 및 별도 정확성 리뷰 수행. 검증 전후 HEAD 동일, worktree 수정 없음.
- 검증 수준: V1·V2 관련 테스트. 지적 없음. 실제 선 두께 해소 판정은 measure 재측정과 구별한다.

## 확인

- **내부 경계:** divider_sides는 전체 pane 트리의 정규화된 Rect에서 안쪽 left/right/bottom만 표시한다. 좌우 두 pane에서는 왼쪽 pane의 오른쪽·오른쪽 pane의 왼쪽 테두리가 빠지고, 상하 분할에서는 위 pane의 아래 테두리가 빠진다. 아래 pane의 editor 위쪽은 tab bar 아래에 있으므로 분할선과 겹치는 면이 아니며 그대로 둔다. 중첩 트리도 leaf Rect로 판단한다.
- **스타일 연결:** Editor의 공개 Styled 경로로 해당 면에 border_*(0)을 전달한다. 설치된 Editor는 스타일을 Input에 전달하고, Input은 기본 border_1 뒤에 refine_style을 적용한다. 따라서 기본 테두리가 다시 덮어쓰는 순서가 아니다. Editor의 focus_bordered(false)도 유지돼 포커스 때 그 면에 별도 테두리를 추가하지 않는다.
- **Phase 3 바깥 가장자리 유지:** Phase 3 `ff836f2`의 editor_view는 Editor 기본 bordered=true를 사용했다. 현재 비확대 단일 pane에서는 DividerSides가 전부 false이며 bordered=true다. 분할 후에도 전체 트리의 x=0/x+w=1/y+h=1인 바깥 면에는 0px override를 넣지 않으므로 기본 편집기 테두리가 유지된다. 사이드바/Dock 경계·탭 바·상태 표시줄 코드는 diff가 없다. 사이드바 경계선과 pane의 바깥 가장자리선이 각각 있던 기존 구성을 임의로 하나로 합치지 않는다.
- **확대 유지:** 확대 틀 padding 8·border 1과 editor_bordered(group.zoomed==Some(id))는 F2 그대로다. 확대 Editor는 기본 테두리가 꺼져 있고, 이번 sides 처리는 0px만 적용하므로 테두리를 다시 만들지 않는다. 바깥 확대 틀에는 이 override가 적용되지 않는다. Markdown/빈 pane도 확대 틀을 계속 사용한다.
- **모델·입력:** PaneGroup·비율·min 80/100·드래그/정수 페인트·readonly·키/IME 처리 diff 없음. 내부 면의 테두리가 빠져 해당 편집 영역이 넓어지는 것은 의도한 변화이며, pane 자체 비율이나 크기는 바꾸지 않는다.
- 재사용: 기존 Rect 계산·Editor 스타일·canvas 분할선·확대 틀. 새 의존성·Cargo 변경 없음. src는 수정하지 않았다.

## 검증

공유 `CARGO_TARGET_DIR=D:\projects\workbench-gpui\target`, 대상 crate 재컴파일 확인.

- `cargo test --config 'profile.test.package.workbench-gpui.debug=1' --config 'profile.test.package.workbench-gpui.opt-level=0' ui::pane_view::tests:: -- --nocapture`: **9 통과 / 실패 0**. 단일 pane·좌우·중첩 상하의 내부/외부 면 판정, 기존 확대 테두리 판단과 드래그/최소 크기 회귀 포함.
- `cargo build --config 'profile.dev.package.workbench-gpui.debug=1' --config 'profile.dev.package.workbench-gpui.opt-level=1'`: exit 0. 이후 manifest 적용 검사 3건 true.
- `cargo clippy --all-targets -- -D warnings`: exit 0, 경고·오류 없음.
- 전체 테스트는 실행하지 않았다.

실측 필요: measure-phase4 R3의 미해소 분할선 두께를 정지 직후·끌기 후·중첩 상태에서 재측정하고, 바깥 가장자리의 기존 구성과 확대 틀 1px 유지를 함께 대조한다. 이미 확인된 비율·padding 등 통과 항목의 반복 측정은 필요 없다.

사용자 확인 필요: 이번 수정으로 추가된 항목 없음. PROGRESS 반영은 lead에게 전달한다.

Verdict: Ship.

Not checked: 앱·실제 픽셀·전체 테스트는 실행하지 않았다. 이번 PASS로 Phase 4 최종 확인의 V3 미해소 항목을 자동 종료하지 않는다.

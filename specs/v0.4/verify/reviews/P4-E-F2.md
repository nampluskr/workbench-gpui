# P4-E-F2 리뷰

결론: PASS

What this change does: 분할선의 페인트 위치만 정수 논리 px에 맞춘다. 확대 중에는 Editor의 안쪽 테두리를 꺼 기존 확대 틀의 1px 테두리와 겹치지 않게 한다.

- 대상: `work/ui`의 `62f7dfaff8b96697b165412df9bdf1bf83058819`, `.worktrees\ui`. 해당 커밋 diff와 호출부·설치된 Editor 구현을 확인했다. 검증 전후 HEAD 동일, worktree 수정 없음.
- 검증 수준: V1·V2 관련 테스트. ponytail-review 및 별도 정확성 리뷰 수행. 이번 PASS는 구현 리뷰이며 실제 픽셀 불일치 해소는 measure의 재측정 대상으로 남는다.

## 확인

- **비율 모델 유지:** `pane_group.rs`와 flex/min 계산은 diff가 없다. node_el의 flex 배분·divider_delta·drag_divider도 그대로다. line_start의 반올림 결과는 canvas의 paint_quad 위치에만 쓰고 모델·히트박스·다음 드래그 delta에 다시 넣지 않는다. 반복 드래그에서 정수화 오차가 비율에 누적되는 경로가 없다.
- **경계 위치:** 현재 canvas bounds에서 `start + hit/2`를 매 프레임 계산해 round한다. 4px 마우스 영역 중심의 실제 분할 경계에서 페인트 시작점 이동은 최대 0.5 논리 px다. 가로/세로 두 방향이 같은 함수를 쓰며 선 폭은 기존 SPLIT_LINE_THICKNESS=1이다. 모델의 pane 경계 자체를 옮기지는 않는다. 인접 pane의 최소 폭·높이를 변경하지 않으며, 드래그 계산은 계속 현재 flex와 포인터 위치로 판단한다.
- **min 80/100 유지:** 기존 폭 80·높이 100 제한, 중첩 subtree 최소 길이, 불균등 하위 비율에서 바깥 드래그 제한 테스트가 통과했다. 최소에 막힌 뒤 포인터를 되돌릴 때 정상 추종하는 기존 UI 판단 테스트도 통과했다.
- **확대 테두리:** editor_view의 유일한 호출부에서 `group.zoomed == Some(id)`일 때만 bordered=false를 전달한다. 비확대는 true로 기존 기본값을 유지한다. 확대 바깥 틀의 padding 8·border 1은 변경하지 않는다. 설치된 gpui-component Editor는 bordered를 Input에 전달하고 focus_bordered(false)를 사용하므로, 별도 편집기 테두리를 끄는 공개 경로다. readonly·키/마우스 재전송·폰트/줄 높이·EditorState는 그대로다. Markdown/빈 pane 경로에는 새 Editor 테두리를 만들지 않는다.
- **재사용·최소 변경:** 기존 canvas/paint_quad·Editor::bordered와 분할 모델을 사용한다. 새 의존성·Cargo 변경 없음. 별도 비율 보정이나 픽셀 잔차 상태를 추가하지 않았다. 추가 지적 없음.

## 검증

공유 `CARGO_TARGET_DIR=D:\projects\workbench-gpui\target`. 대상 crate 재컴파일 확인.

- `cargo test --config 'profile.test.package.workbench-gpui.debug=0' --config 'profile.test.package.workbench-gpui.opt-level=1' <filter> -- --nocapture`:
  - `ui::pane_view::tests::`: **8 통과**(정수화·확대 bordered 판단 및 기존 반복 드래그/최소·균등화 포함).
  - `i726`: **3 통과**(중첩 최소·불균등 하위 비율·제한 전달).
- 합계 **11 통과, 실패 0**. 전체 테스트는 실행하지 않았다.
- `cargo build --config 'profile.dev.package.workbench-gpui.debug=0' --config 'profile.dev.package.workbench-gpui.opt-level=1'`: exit 0. 이후 apply-manifest.ps1 적용, manifest 검사 3건 true.
- `cargo clippy --all-targets -- -D warnings`: exit 0, 경고·오류 없음.

실측 필요: Phase 4 최종 R1의 남은 항목에 한정해 드래그 뒤 가로·세로 분할선 1px, 확대 틀 좌·우·아래 1px을 measure가 재확인한다. 정수 논리 px를 실제 픽셀에 대응시킨 판정은 현재 측정 조건인 100% 기준이며 다른 DPI의 픽셀 두께를 검증한 것은 아니다. 기존 통과 상태를 재측정할 필요는 없다.

사용자 확인 필요: 이번 수정으로 추가된 항목 없음. 기존 컴포넌트 한계·색 토큰 근사 기록 유지. src·공유 문서는 수정하지 않았으며 PROGRESS 반영은 lead에게 전달한다.

Verdict: Ship.

Not checked: 앱·실제 픽셀·다른 DPI·전체 테스트는 실행하지 않았다. Phase 4 최종 REWORK의 렌더 불일치 해소 여부는 재측정 후 별도로 판정한다.

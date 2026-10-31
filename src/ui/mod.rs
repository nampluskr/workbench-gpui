//! 얇은 래퍼 계층(ui 헬퍼). gpui-kit 의존을 이 모듈 안에 가둔다 (DECISIONS D-5).
//!
//! 진입 순서는 gpui-kit 0.8.1 crate 문서의 예시(application → init → open_window)를 따른다.

use gpui_kit::*;

struct Workbench;

impl Render for Workbench {
    fn render(&mut self, _: &mut Window, _: &mut Context<Self>) -> impl IntoElement {
        div().size_full()
    }
}

/// 앱을 시작하고 빈 창 하나를 연다.
pub fn run() {
    gpui_kit::application().run(|cx| {
        gpui_kit::init(cx);
        gpui_kit::open_window(WindowOptions::default(), cx, |_, cx| cx.new(|_| Workbench))
            .expect("failed to open window");
    });
}

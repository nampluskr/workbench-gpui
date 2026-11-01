//! 레이아웃 측정용 탐침 (Phase 3 증거, SPEC R-12~R-15). 디버그 빌드의 `--dev-layout` 으로만 켠다.
//!
//! gpui `Div::on_children_prepainted` 는 자식마다 레이아웃 경계(테두리 포함 바깥 상자)를 넘겨 준다.
//! 부모 div 에 자식 이름 목록을 붙이면, 켜져 있을 때 이름별 경계를 모아 둔다. 꺼져 있으면 아무것도 하지 않는다.

use std::cell::RefCell;
use std::collections::BTreeMap;
use std::sync::atomic::{AtomicBool, Ordering};

use gpui_kit::{App, Bounds, Pixels, Window};

static ENABLED: AtomicBool = AtomicBool::new(false);

thread_local! {
    static BOXES: RefCell<BTreeMap<&'static str, Bounds<Pixels>>> = const { RefCell::new(BTreeMap::new()) };
}

pub fn enable() {
    ENABLED.store(true, Ordering::Relaxed);
}

pub fn is_enabled() -> bool {
    ENABLED.load(Ordering::Relaxed)
}

/// 부모 div 의 `on_children_prepainted` 에 넘길 리스너. `names[i]` 가 i 번째 자식의 이름이다.
/// 빈 문자열인 자식은 기록하지 않는다.
pub fn probe(
    names: &'static [&'static str],
) -> impl Fn(Vec<Bounds<Pixels>>, &mut Window, &mut App) + 'static {
    move |bounds, _, _| {
        if !is_enabled() {
            return;
        }
        BOXES.with(|boxes| {
            let mut boxes = boxes.borrow_mut();
            for (name, b) in names.iter().zip(bounds) {
                if !name.is_empty() {
                    boxes.insert(name, b);
                }
            }
        });
    }
}

/// 지금까지 모은 이름별 경계(이름순).
pub fn snapshot() -> Vec<(&'static str, Bounds<Pixels>)> {
    BOXES.with(|boxes| boxes.borrow().iter().map(|(k, v)| (*k, *v)).collect())
}

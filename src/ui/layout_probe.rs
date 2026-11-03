//! 레이아웃 측정용 탐침 (Phase 3 증거, SPEC R-12~R-15). 디버그 빌드의 `--dev-layout` 으로만 켠다.
//!
//! gpui `Div::on_children_prepainted` 는 자식마다 레이아웃 경계(테두리 포함 바깥 상자)를 넘겨 준다.
//! 부모 div 에 자식 이름 목록을 붙이면, 켜져 있을 때 이름별 경계를 모아 둔다. 꺼져 있으면 아무것도 하지 않는다.
//!
//! v0.2 Phase 2: 경계마다 그 경계를 기록한 프레임 번호를 함께 둔다. 창 루트(Workbench)가 그릴 때마다
//! `begin_frame` 으로 번호를 올리므로, 스냅숏에는 마지막으로 그린 프레임(또는 바로 앞 프레임)에 있던 요소만 나온다.
//! 그래서 사라진 툴팁·메뉴의 경계가 남지 않는다.

use std::cell::{Cell, RefCell};
use std::collections::BTreeMap;
use std::sync::atomic::{AtomicBool, Ordering};

use gpui_kit::{App, Bounds, Pixels, Window};

static ENABLED: AtomicBool = AtomicBool::new(false);

thread_local! {
    static BOXES: RefCell<BTreeMap<&'static str, (Bounds<Pixels>, u64)>> = const { RefCell::new(BTreeMap::new()) };
    static FRAME: Cell<u64> = const { Cell::new(0) };
}

pub fn enable() {
    ENABLED.store(true, Ordering::Relaxed);
}

pub fn is_enabled() -> bool {
    ENABLED.load(Ordering::Relaxed)
}

/// 창 루트가 그리기 시작할 때 부른다.
pub fn begin_frame() {
    FRAME.with(|f| f.set(f.get() + 1));
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
        let frame = FRAME.with(|f| f.get());
        BOXES.with(|boxes| {
            let mut boxes = boxes.borrow_mut();
            for (name, b) in names.iter().zip(bounds) {
                if !name.is_empty() {
                    boxes.insert(name, (b, frame));
                }
            }
        });
    }
}

/// 이름별 경계(이름순). 마지막 프레임에 기록된 것만 낸다.
pub fn snapshot() -> Vec<(&'static str, Bounds<Pixels>)> {
    let frame = FRAME.with(|f| f.get());
    BOXES.with(|boxes| {
        boxes
            .borrow()
            .iter()
            .filter(|(_, (_, f))| *f == frame)
            .map(|(k, (b, _))| (*k, *b))
            .collect()
    })
}

/// Builds the `--dev-layout-json` document (logical px, rounded to 0.01). `boxes` are `(name, [x, y, w, h])`.
pub fn layout_json(seq: u32, rem: f32, scale: f32, viewport: (f32, f32), boxes: &[(&str, [f32; 4])]) -> String {
    let r = |v: f32| (f64::from(v) * 100.0).round() / 100.0;
    let boxes: Vec<_> = boxes
        .iter()
        .map(|(name, [x, y, w, h])| serde_json::json!({ "name": name, "x": r(*x), "y": r(*y), "w": r(*w), "h": r(*h) }))
        .collect();
    serde_json::json!({
        "seq": seq,
        "rem": r(rem),
        "scale": r(scale),
        "viewport": { "w": r(viewport.0), "h": r(viewport.1) },
        "boxes": boxes,
    })
    .to_string()
}

/// 이름이 `prefix` 로 시작하는 경계를 지운다. 닫힌 메뉴·툴팁의 옛 경계가 스냅숏에 남지 않게 한다.
pub fn forget(prefix: &str) {
    BOXES.with(|boxes| boxes.borrow_mut().retain(|k, _| !k.starts_with(prefix)));
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn layout_json_shape() {
        let json = layout_json(3, 16.0, 1.0, (1920.0, 1080.0), &[("titlebar", [0.0, 0.0, 1920.0, 32.0])]);
        let v: serde_json::Value = serde_json::from_str(&json).unwrap();
        assert_eq!(v["seq"], 3);
        assert_eq!(v["rem"], 16.0);
        assert_eq!(v["viewport"]["w"], 1920.0);
        assert_eq!(v["boxes"][0]["name"], "titlebar");
        assert_eq!(v["boxes"][0]["h"], 32.0);
    }
}

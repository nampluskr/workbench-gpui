//! 단축키 표시 문자열 (L-217~L-221, A-27.4, D-3).
//!
//! - L-218: Windows 는 기호 없이 문자열.
//! - L-219: 수식키 구분자는 `-`, 순서는 Fn → Ctrl → Win → Alt → Shift → 키.
//! - L-220: 키 이름은 첫 글자를 대문자로. 예외 `pageup` → `PageUp`, `pagedown` → `PageDown`.
//! - L-221: chord 는 키 입력마다 덩어리 하나. 화면에서는 덩어리 사이 gap 4px 이고, 이 문자열에서는 공백 하나로 잇는다.

/// 키 입력 하나(수식키 + 키 이름). 키 이름은 gpui 표기(소문자, 예: `pageup`, `f10`, `;`).
#[derive(Debug, Clone, Copy, Default)]
pub struct Stroke<'a> {
    pub function: bool,
    pub control: bool,
    pub platform: bool,
    pub alt: bool,
    pub shift: bool,
    pub key: &'a str,
}

/// L-220 키 이름.
pub fn key_name(key: &str) -> String {
    match key {
        "pageup" => "PageUp".into(),
        "pagedown" => "PageDown".into(),
        _ => {
            let mut chars = key.chars();
            match chars.next() {
                Some(first) => first.to_uppercase().chain(chars).collect(),
                None => String::new(),
            }
        }
    }
}

/// 키 입력 하나의 표시 문자열. 예: `Ctrl-Shift-E`.
pub fn stroke_text(stroke: &Stroke) -> String {
    let mut parts: Vec<String> = Vec::new();
    if stroke.function {
        parts.push("Fn".into());
    }
    if stroke.control {
        parts.push("Ctrl".into());
    }
    if stroke.platform {
        parts.push("Win".into());
    }
    if stroke.alt {
        parts.push("Alt".into());
    }
    if stroke.shift {
        parts.push("Shift".into());
    }
    parts.push(key_name(stroke.key));
    parts.join("-")
}

/// 바인딩 하나(chord 포함)의 표시 문자열. 예: `Ctrl-K Ctrl-O`.
pub fn binding_text(strokes: &[Stroke]) -> String {
    strokes
        .iter()
        .map(stroke_text)
        .collect::<Vec<_>>()
        .join(" ")
}

/// 바인딩 하나를 gpui 키 표기(소문자)로 적는다(dev 출력·대조용). 수식키는 L-219 순서로 쓴다.
/// gpui `Keystroke::parse` 는 수식키 순서를 가리지 않으므로 이 꼴도 그대로 읽힌다. 예: `ctrl-k ctrl-shift-c`.
pub fn binding_notation(strokes: &[Stroke]) -> String {
    strokes
        .iter()
        .map(|s| {
            let mut parts: Vec<&str> = Vec::new();
            if s.function {
                parts.push("fn");
            }
            if s.control {
                parts.push("ctrl");
            }
            if s.platform {
                parts.push("win");
            }
            if s.alt {
                parts.push("alt");
            }
            if s.shift {
                parts.push("shift");
            }
            parts.push(s.key);
            parts.join("-")
        })
        .collect::<Vec<_>>()
        .join(" ")
}

#[cfg(test)]
mod tests {
    use super::*;

    fn s(control: bool, alt: bool, shift: bool, key: &str) -> Stroke<'_> {
        Stroke {
            control,
            alt,
            shift,
            key,
            ..Default::default()
        }
    }

    #[test]
    fn l219_examples() {
        assert_eq!(binding_text(&[s(true, false, false, "b")]), "Ctrl-B");
        assert_eq!(binding_text(&[s(true, false, true, "e")]), "Ctrl-Shift-E");
        assert_eq!(binding_text(&[s(true, true, false, "j")]), "Ctrl-Alt-J");
    }

    #[test]
    fn l219_order_all_modifiers() {
        let all = Stroke {
            function: true,
            control: true,
            platform: true,
            alt: true,
            shift: true,
            key: "x",
        };
        assert_eq!(stroke_text(&all), "Fn-Ctrl-Win-Alt-Shift-X");
    }

    #[test]
    fn l220_key_names() {
        assert_eq!(key_name("left"), "Left");
        assert_eq!(key_name("escape"), "Escape");
        assert_eq!(key_name("g"), "G");
        assert_eq!(key_name("pageup"), "PageUp");
        assert_eq!(key_name("pagedown"), "PageDown");
        assert_eq!(key_name("f10"), "F10");
        assert_eq!(key_name(";"), ";");
    }

    #[test]
    fn l221_chord() {
        assert_eq!(
            binding_text(&[s(true, false, false, "k"), s(true, false, false, "t")]),
            "Ctrl-K Ctrl-T"
        );
        assert_eq!(
            binding_notation(&[s(true, false, false, "k"), s(true, false, true, "c")]),
            "ctrl-k ctrl-shift-c"
        );
    }
}

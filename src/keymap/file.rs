//! 사용자 `keymap.json` 읽기 (R-2, A-20.4, D-4, D-14 이후 변경).
//!
//! 형식은 Zed 와 같은 객체 배열이다: `[{ "context": "Editor", "bindings": { "ctrl-k ctrl-t": "theme_selector::Toggle" } }]`.
//! 주석(`//`, `/* */`)과 끝 쉼표를 허용한다(jsonc-parser). 그 밖의 JSON5 확장은 받지 않는다.
//!
//! 오류 문구(D-14 이후 변경, D-027 ①):
//! - 파일을 읽지 못하거나 형식이 틀리면 `Failed to load keymap file`(K-091).
//! - 없는 액션 이름이면 `Action '{이름}' not found`(K-085).
//!
//! 오류가 난 항목만 빼고 나머지는 적용한다. 파일 전체가 JSON 으로 읽히지 않으면 바인딩은 하나도 없다.

use std::path::Path;

use jsonc_parser::ParseOptions;
use serde_json::Value;

/// K-091 원문 문구.
pub const ERR_LOAD: &str = "Failed to load keymap file";

/// K-085 원문 문구.
pub fn err_not_found(name: &str) -> String {
    format!("Action '{name}' not found")
}

/// 사용자 바인딩 하나. `action` 이 None 이면 `null`(해제, I-703)이다.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct UserBinding {
    pub context: Option<String>,
    pub keys: String,
    pub action: Option<String>,
}

/// 읽은 결과. 바인딩과 오류 문구를 파일에 나온 순서대로 담는다.
#[derive(Debug, Default, Clone, PartialEq, Eq)]
pub struct Parsed {
    pub entries: Vec<Result<UserBinding, String>>,
}

#[cfg_attr(not(test), allow(dead_code))]
impl Parsed {
    fn error(text: &str) -> Self {
        Self {
            entries: vec![Err(text.into())],
        }
    }

    pub fn bindings(&self) -> Vec<UserBinding> {
        self.entries
            .iter()
            .filter_map(|e| e.as_ref().ok().cloned())
            .collect()
    }

    pub fn errors(&self) -> Vec<String> {
        self.entries
            .iter()
            .filter_map(|e| e.as_ref().err().cloned())
            .collect()
    }
}

fn options() -> ParseOptions {
    ParseOptions {
        allow_comments: true,
        allow_trailing_commas: true,
        allow_loose_object_property_names: false,
        allow_missing_commas: false,
        allow_single_quoted_strings: false,
        allow_hexadecimal_numbers: false,
        allow_unary_plus_numbers: false,
        allow_bare_decimal_point_numbers: false,
        allow_non_finite_numbers: false,
        allow_extended_string_escapes: false,
    }
}

/// 파일을 읽는다. 파일이 없으면 바인딩·오류 모두 없다.
pub fn read(path: &Path, is_known: &dyn Fn(&str) -> bool) -> Parsed {
    match std::fs::read(path) {
        Ok(bytes) => match String::from_utf8(bytes) {
            Ok(text) => parse(&text, is_known),
            Err(_) => Parsed::error(ERR_LOAD),
        },
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => Parsed::default(),
        Err(_) => Parsed::error(ERR_LOAD),
    }
}

/// 글을 읽는다. `is_known` 은 우리 앱 액션 이름인지 묻는다.
pub fn parse(text: &str, is_known: &dyn Fn(&str) -> bool) -> Parsed {
    let text = text.strip_prefix('\u{feff}').unwrap_or(text);
    let mut out = Parsed::default();
    if text.trim().is_empty() {
        return out;
    }
    let value: Value = match jsonc_parser::parse_to_serde_value(text, &options()) {
        Ok(v) => v,
        Err(_) => {
            out.entries.push(Err(ERR_LOAD.into()));
            return out;
        }
    };
    let Value::Array(sections) = value else {
        out.entries.push(Err(ERR_LOAD.into()));
        return out;
    };
    for section in sections {
        let Value::Object(section) = section else {
            out.entries.push(Err(ERR_LOAD.into()));
            continue;
        };
        let context = match section.get("context") {
            None | Some(Value::Null) => None,
            Some(Value::String(s)) => Some(s.clone()),
            Some(_) => {
                out.entries.push(Err(ERR_LOAD.into()));
                continue;
            }
        };
        let bindings = match section.get("bindings") {
            None => continue,
            Some(Value::Object(b)) => b,
            Some(_) => {
                out.entries.push(Err(ERR_LOAD.into()));
                continue;
            }
        };
        for (keys, value) in bindings {
            let action = match value {
                Value::Null => None,
                Value::String(name) => {
                    if !is_known(name) {
                        out.entries.push(Err(err_not_found(name)));
                        continue;
                    }
                    Some(name.clone())
                }
                _ => {
                    // 인수가 있는 꼴(`["이름", {..}]`)은 우리 액션에 인수가 없어 받지 않는다.
                    out.entries.push(Err(ERR_LOAD.into()));
                    continue;
                }
            };
            out.entries.push(Ok(UserBinding {
                context: context.clone(),
                keys: keys.clone(),
                action,
            }));
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    fn known(name: &str) -> bool {
        matches!(name, "workspace::ToggleLeftDock" | "project_panel::ToggleFocus")
    }

    #[test]
    fn override_binding() {
        let p = parse(
            r#"[{"context":"Workspace","bindings":{"ctrl-b":"project_panel::ToggleFocus"}}]"#,
            &known,
        );
        assert!(p.errors().is_empty());
        assert_eq!(
            p.bindings(),
            vec![UserBinding {
                context: Some("Workspace".into()),
                keys: "ctrl-b".into(),
                action: Some("project_panel::ToggleFocus".into()),
            }]
        );
    }

    #[test]
    fn null_unbinds() {
        let p = parse(r#"[{"context":"Workspace","bindings":{"ctrl-b":null}}]"#, &known);
        assert!(p.errors().is_empty());
        assert_eq!(p.bindings()[0].action, None);
    }

    #[test]
    fn unknown_action_is_skipped_rest_applied() {
        let p = parse(
            r#"[{"context":"Workspace","bindings":{"ctrl-b":"nope::Missing","ctrl-shift-e":"workspace::ToggleLeftDock"}}]"#,
            &known,
        );
        assert_eq!(p.errors(), vec!["Action 'nope::Missing' not found".to_string()]);
        assert_eq!(p.bindings().len(), 1);
        assert_eq!(p.bindings()[0].keys, "ctrl-shift-e");
    }

    #[test]
    fn comments_and_trailing_commas() {
        let p = parse(
            "// 주석\n[\n  /* 블록 */ {\"context\": \"Workspace\", \"bindings\": {\"ctrl-b\": \"workspace::ToggleLeftDock\",},},\n]\n",
            &known,
        );
        assert!(p.errors().is_empty(), "{:?}", p.errors());
        assert_eq!(p.bindings().len(), 1);
    }

    #[test]
    fn broken_file() {
        let p = parse("[{", &known);
        assert_eq!(p.errors(), vec![ERR_LOAD.to_string()]);
        assert!(p.bindings().is_empty());
        let p = parse("{}", &known);
        assert_eq!(p.errors(), vec![ERR_LOAD.to_string()]);
        // JSON5 확장(작은따옴표)은 받지 않는다.
        let p = parse("[{'bindings':{}}]", &known);
        assert_eq!(p.errors(), vec![ERR_LOAD.to_string()]);
    }

    #[test]
    fn several_errors_in_order() {
        let p = parse(
            r#"[{"bindings":{"a":"x::A","b":["workspace::ToggleLeftDock",{}],"c":"y::B"}}, 3]"#,
            &known,
        );
        assert_eq!(
            p.errors(),
            vec![
                "Action 'x::A' not found".to_string(),
                ERR_LOAD.to_string(),
                "Action 'y::B' not found".to_string(),
                ERR_LOAD.to_string(),
            ]
        );
    }

    #[test]
    fn empty_and_bom() {
        assert_eq!(parse("", &known), Parsed::default());
        let p = parse("\u{feff}[]", &known);
        assert!(p.errors().is_empty());
    }
}

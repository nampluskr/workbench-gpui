//! 인라인 이름 입력칸의 검증·확정 (02-INTERACTION 14.8절 P-019~P-022, I-091·I-092).

use std::path::{Path, PathBuf};

/// P-021 경고 문구(앞뒤 공백).
pub const WARN_WHITESPACE: &str = "File or directory name contains leading or trailing whitespace.";

/// 입력할 때마다 보는 검증 결과(P-021). 행 아래 배너와 행 테두리 색으로 보인다.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Validation {
    Warning(String),
    Error(String),
}

impl Validation {
    pub fn text(&self) -> &str {
        match self {
            Validation::Warning(t) | Validation::Error(t) => t,
        }
    }
}

/// P-021 오류 문구(같은 위치에 같은 이름).
pub fn exists_error(name: &str) -> String {
    format!("File or directory '{name}' already exists at location. Please choose a different name.")
}

/// 확정한 이름: `parent` 아래 상대 구간들과 폴더인지.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Confirmed {
    pub parts: Vec<String>,
    pub is_dir: bool,
}

impl Confirmed {
    pub fn path_under(&self, parent: &Path) -> PathBuf {
        let mut p = parent.to_path_buf();
        for part in &self.parts {
            p.push(part);
        }
        p
    }
}

fn is_sep(c: char) -> bool {
    c == '/' || c == '\\'
}

/// P-022 Enter 확정 규칙.
/// - 새 항목에서 입력이 `/`·`\` 로 끝나면 폴더 생성으로 바뀐다.
/// - Windows 에서는 이름 끝의 마침표를 모두 지운다.
/// - `foo/bar/baz.rs` 처럼 쓰면 중간 폴더도 함께 만든다(구간으로 나눈다). 이름 변경은 나누지 않는다(판단).
/// - 공백을 뺀 이름이 비면 None(아무 일 없이 입력칸이 열려 있다, ①).
pub fn confirm(input: &str, new_entry: bool, new_is_dir: bool) -> Option<Confirmed> {
    let mut s = input;
    let mut is_dir = new_is_dir;
    if new_entry && s.ends_with(is_sep) {
        is_dir = true;
        s = s.trim_end_matches(is_sep);
    }
    let s = s.trim_end_matches('.');
    if s.trim().is_empty() {
        return None;
    }
    let parts: Vec<String> = if new_entry {
        s.split(is_sep).filter(|p| !p.is_empty()).map(str::to_string).collect()
    } else {
        vec![s.to_string()]
    };
    // 리뷰 1회차 ①(D-043): 구간마다 Windows 이름 규칙을 본다. 이름 변경은 구분자를 허용하지 않는다(부모 폴더 바로 아래만).
    if parts.is_empty() || !parts.iter().all(|p| valid_component(p)) {
        return None;
    }
    Some(Confirmed { parts, is_dir })
}

/// Windows 예약 장치 이름(확장자가 붙어도 장치로 열린다).
const RESERVED: [&str; 22] = [
    "CON", "PRN", "AUX", "NUL", "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9", "LPT1", "LPT2",
    "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9",
];

/// 경로 구간 하나로 쓸 수 있는 이름인가(D-043 ①). 거부: 빈 이름·`.`·`..`, 구분자(`\` `/`), 드라이브·대체 데이터 스트림(`:`),
/// 그 밖의 Windows 금지 글자(`< > " | ? *`, 제어 문자), 예약 장치 이름, 마침표로 끝나는 구간(Windows 가 지워 다른 이름이 된다).
pub fn valid_component(p: &str) -> bool {
    if p.trim().is_empty() || p == "." || p == ".." || p.ends_with('.') {
        return false;
    }
    if p.chars().any(|c| is_sep(c) || matches!(c, ':' | '<' | '>' | '"' | '|' | '?' | '*') || (c as u32) < 0x20) {
        return false;
    }
    let stem = p.split('.').next().unwrap_or(p).trim_end().to_ascii_uppercase();
    !RESERVED.contains(&stem.as_str())
}

/// P-021 입력할 때마다의 검증. 같은 위치에 같은 이름이 있으면 오류(이름 변경에서 자기 자신은 빼고),
/// 아니면 앞뒤 공백이 있으면 경고. 빈 이름은 배너 없이 무시한다.
pub fn validate(input: &str, parent: &Path, new_entry: bool, self_path: Option<&Path>) -> Option<Validation> {
    let Some(confirmed) = confirm(input, new_entry, false) else {
        return None;
    };
    let target = confirmed.path_under(parent);
    let is_self = self_path.is_some_and(|p| same_path(p, &target));
    if !is_self && target.symlink_metadata().is_ok() {
        return Some(Validation::Error(exists_error(confirmed.parts.last().map(String::as_str).unwrap_or(input))));
    }
    if input != input.trim() {
        return Some(Validation::Warning(WARN_WHITESPACE.to_string()));
    }
    None
}

/// Windows 경로 비교(대소문자 무시). 이름 변경에서 "자기 자신과 같은 이름"을 가린다.
pub fn same_path(a: &Path, b: &Path) -> bool {
    a.to_string_lossy().to_lowercase() == b.to_string_lossy().to_lowercase()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn p022_confirm_rules() {
        // 끝 마침표를 모두 지운다.
        assert_eq!(confirm("a.txt..", true, false), Some(Confirmed { parts: vec!["a.txt".into()], is_dir: false }));
        // `/`·`\` 로 끝나면 폴더.
        assert_eq!(confirm("dir\\", true, false), Some(Confirmed { parts: vec!["dir".into()], is_dir: true }));
        assert_eq!(confirm("dir/", true, false).map(|c| c.is_dir), Some(true));
        // 중간 폴더.
        assert_eq!(confirm("a/b/c.rs", true, false).map(|c| c.parts), Some(vec!["a".into(), "b".into(), "c.rs".into()]));
        // 빈 이름은 거부(입력칸 유지).
        assert_eq!(confirm("   ", true, false), None);
        assert_eq!(confirm("...", true, false), None);
        // 이름 변경은 나누지 않는다.
        assert_eq!(confirm("x.md", false, false).map(|c| c.parts), Some(vec!["x.md".into()]));
    }

    #[test]
    fn p021_validation() {
        let dir = std::env::temp_dir().join(format!("wg-names-{}", std::process::id()));
        std::fs::create_dir_all(&dir).unwrap();
        std::fs::write(dir.join("taken.txt"), b"").unwrap();
        assert_eq!(validate(" a.txt", &dir, true, None), Some(Validation::Warning(WARN_WHITESPACE.into())));
        assert_eq!(validate("taken.txt", &dir, true, None), Some(Validation::Error(exists_error("taken.txt"))));
        assert_eq!(validate("TAKEN.txt", &dir, false, Some(&dir.join("taken.txt"))), None);
        assert_eq!(validate("", &dir, true, None), None);
        assert_eq!(validate("free.txt", &dir, true, None), None);
        std::fs::remove_dir_all(&dir).unwrap();
    }
}

#[cfg(test)]
mod d043_tests {
    use super::*;

    #[test]
    fn d043_rename_rejects_paths_and_bad_names() {
        // 이름 변경: 구분자·부모 이탈·절대 경로·드라이브·스트림·예약 이름은 거부(입력칸 유지).
        for bad in ["..\\outside.txt", "../outside.txt", "sub\\x.txt", "D:\\w\\abs.txt", "C:x.txt", "f.txt:ads", "con", "CON.txt", "lpt1.md", "a<b", "q?.txt"] {
            assert_eq!(confirm(bad, false, false), None, "{bad}");
        }
        // 새 항목: 구간마다 같은 규칙(중간 폴더 허용은 그대로).
        assert_eq!(confirm("../x.txt", true, false), None);
        assert_eq!(confirm("D:/x.txt", true, false), None);
        assert_eq!(confirm("a/nul/b.txt", true, false), None);
        assert_eq!(confirm("a./b.txt", true, false), None);
        assert!(confirm("ok/b.txt", true, false).is_some());
        assert!(confirm("console.txt", false, false).is_some());
    }
}

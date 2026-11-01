//! 폴더 경로 정규화와 비교 (01-zed A-28, A-13.2).
//!
//! - A-28.1 `/` → `\`.
//! - A-28.2 `\\?\C:\x` → `C:\x`, `\\?\UNC\server\share\x` → `\\server\share\x`. 그 밖의 `\\?\` 형식은 등록하지 않는다.
//! - A-28.3 끝의 `\` 는 드라이브 루트(`C:\`)와 UNC 루트(`\\server\share\`)에서만 남긴다.
//! - A-28.4 드라이브 문자는 대문자.
//! - A-28.5 비교 키는 정규화한 문자열의 대소문자 무시(유니코드 단순 소문자화).
//! - A-28.6 심볼릭 링크·정션·8.3 이름은 풀지 않는다. `.`·`..` 구간은 지운다. 드라이브 상대(`C:foo`)·`\` 하나로 시작하는 경로는 절대 경로가 아니라 등록하지 않는다.

/// 정규화한 절대 경로. 등록할 수 없는 꼴이면 None.
pub fn normalize(input: &str) -> Option<String> {
    let s = input.trim().replace('/', "\\");
    // A-28.2 확장 접두사.
    let s = if let Some(rest) = s.strip_prefix("\\\\?\\") {
        if let Some(unc) = rest.strip_prefix("UNC\\").or_else(|| rest.strip_prefix("unc\\")) {
            format!("\\\\{unc}")
        } else if is_drive_abs(rest) {
            rest.to_string()
        } else {
            return None;
        }
    } else {
        s
    };

    if let Some(unc) = s.strip_prefix("\\\\") {
        // UNC: \\server\share\rest...
        let parts: Vec<&str> = unc.split('\\').filter(|p| !p.is_empty()).collect();
        if parts.len() < 2 {
            return None;
        }
        let rest = clean_segments(&parts[2..])?;
        let root = format!("\\\\{}\\{}\\", parts[0], parts[1]);
        return Some(if rest.is_empty() {
            root
        } else {
            format!("{root}{}", rest.join("\\"))
        });
    }

    if !is_drive_abs(&s) {
        return None;
    }
    let drive = s[..1].to_ascii_uppercase();
    let parts: Vec<&str> = s[3..].split('\\').filter(|p| !p.is_empty()).collect();
    let rest = clean_segments(&parts)?;
    Some(if rest.is_empty() {
        format!("{drive}:\\")
    } else {
        format!("{drive}:\\{}", rest.join("\\"))
    })
}

/// `C:\` 로 시작하는가(드라이브 절대 경로).
fn is_drive_abs(s: &str) -> bool {
    let b = s.as_bytes();
    b.len() >= 3 && b[0].is_ascii_alphabetic() && b[1] == b':' && b[2] == b'\\'
}

/// `.` 은 지우고 `..` 은 앞 구간을 지운다. 루트 위로 올라가면 None.
fn clean_segments<'a>(parts: &[&'a str]) -> Option<Vec<&'a str>> {
    let mut out: Vec<&str> = Vec::new();
    for p in parts {
        match *p {
            "." => {}
            ".." => {
                out.pop()?;
            }
            other => out.push(other),
        }
    }
    Some(out)
}

/// A-28.5 비교 키: 유니코드 단순 케이스 폴딩(CaseFolding.txt 의 C·S 항목)으로 문자마다 바꾼다(리뷰 1회차 ⑤, D-037).
/// `to_lowercase` 와 달리 `ς`·`σ`·`Σ` 가 같은 키가 된다(NTFS 도 같은 이름으로 본다).
pub fn compare_key(normalized: &str) -> String {
    normalized.chars().map(simple_fold).collect()
}

/// 문자 하나의 단순 케이스 폴딩. 대부분은 소문자화(결과가 한 글자일 때)와 같고, 다른 것만 표로 둔다.
/// 알려진 한계(DECISIONS 미결 사항, D-040): 표는 CaseFolding.txt C·S 전체가 아니다(예: U+1FD3·U+1FE3·U+FB05 빠짐).
/// 이후 버전에서 버전을 정한 Unicode 표로 바꾼다.
/// 소문자화가 여러 글자가 되는 문자(예: `İ`)는 단순 폴딩 항목이 없어 그대로 둔다.
fn simple_fold(c: char) -> char {
    let mapped = match c as u32 {
        0x00B5 => 0x03BC,          // µ → μ
        0x017F => 0x0073,          // ſ → s
        0x0345 => 0x03B9,          // 그리스 결합 ypogegrammeni → ι
        0x03C2 => 0x03C3,          // ς → σ
        0x03D0 => 0x03B2,          // ϐ → β
        0x03D1 => 0x03B8,          // ϑ → θ
        0x03D5 => 0x03C6,          // ϕ → φ
        0x03D6 => 0x03C0,          // ϖ → π
        0x03F0 => 0x03BA,          // ϰ → κ
        0x03F1 => 0x03C1,          // ϱ → ρ
        0x03F5 => 0x03B5,          // ϵ → ε
        0x1E9B => 0x1E61,          // ẛ → ṡ
        0x1FBE => 0x03B9,          // ι → ι
        0x1C80 => 0x0432,
        0x1C81 => 0x0434,
        0x1C82 => 0x043E,
        0x1C83 => 0x0441,
        0x1C84 | 0x1C85 => 0x0442,
        0x1C86 => 0x044A,
        0x1C87 => 0x0463,
        0x1C88 => 0xA64B,
        // 체로키: 폴딩은 대문자 쪽으로 모은다(소문자화와 반대 방향).
        0x13A0..=0x13F5 => c as u32,
        0x13F8..=0x13FD => c as u32 - 8,
        0xAB70..=0xABBF => c as u32 - 0xAB70 + 0x13A0,
        _ => {
            let mut lower = c.to_lowercase();
            return match (lower.next(), lower.next()) {
                (Some(l), None) => l,
                _ => c,
            };
        }
    };
    char::from_u32(mapped).unwrap_or(c)
}

/// 폴더 이름(마지막 구간). 루트면 경로 그대로(예: `C:\`).
pub fn folder_name(normalized: &str) -> String {
    // 정규화한 경로는 루트(드라이브·UNC)일 때만 `\` 로 끝난다(A-28.3).
    if normalized.ends_with('\\') {
        return normalized.to_string();
    }
    normalized
        .rsplit_once('\\')
        .map(|(_, name)| name.to_string())
        .unwrap_or_else(|| normalized.to_string())
}

/// 바로 위 폴더 이름(A-12.6 같은 이름 구별용). 없으면 None.
pub fn parent_name(normalized: &str) -> Option<String> {
    let trimmed = normalized.trim_end_matches('\\');
    let (parent, _) = trimmed.rsplit_once('\\')?;
    let parent_trimmed = parent.trim_end_matches('\\');
    let (_, name) = parent_trimmed.rsplit_once('\\').unwrap_or(("", parent_trimmed));
    (!name.is_empty()).then(|| name.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a28_examples() {
        assert_eq!(normalize("D:\\projects\\").as_deref(), Some("D:\\projects")); // A-28.7
        assert_eq!(normalize("d:/projects").as_deref(), Some("D:\\projects")); // A-28.8
        assert_eq!(normalize("C:\\").as_deref(), Some("C:\\")); // A-28.9
        assert_eq!(normalize("\\\\?\\C:\\work\\notes").as_deref(), Some("C:\\work\\notes")); // A-28.10
        assert_eq!(
            normalize("\\\\?\\UNC\\nas\\share\\docs\\").as_deref(),
            Some("\\\\nas\\share\\docs")
        ); // A-28.11
        assert_eq!(normalize("\\\\nas\\share\\").as_deref(), Some("\\\\nas\\share\\")); // A-28.12
        assert_eq!(
            compare_key(&normalize("D:\\Projects").unwrap()),
            compare_key(&normalize("d:\\projects").unwrap())
        ); // A-28.13
    }

    #[test]
    fn a28_6_rejects_and_cleans() {
        assert_eq!(normalize("C:foo"), None);
        assert_eq!(normalize("\\foo"), None);
        assert_eq!(normalize("relative\\x"), None);
        assert_eq!(normalize("\\\\?\\GLOBALROOT\\Device\\x"), None);
        assert_eq!(normalize("C:\\a\\.\\b\\..\\c").as_deref(), Some("C:\\a\\c"));
        assert_eq!(normalize("C:\\..\\x"), None);
    }

    #[test]
    fn a28_5_simple_case_folding() {
        // ς·σ·Σ 는 같은 키(to_lowercase 로는 ς 와 σ 가 달랐다).
        assert_eq!(compare_key("C:\\ς"), compare_key("C:\\σ"));
        assert_eq!(compare_key("C:\\Σ"), compare_key("C:\\σ"));
        assert_eq!(compare_key("D:\\Projects"), "d:\\projects");
        assert_eq!(compare_key("C:\\ſ"), compare_key("C:\\S"));
        assert_eq!(compare_key("C:\\µ"), compare_key("C:\\Μ"));
        // 체로키 소문자는 대문자로 모은다.
        assert_eq!(compare_key("\u{AB70}"), compare_key("\u{13A0}"));
        assert_eq!(compare_key("\u{13F8}"), compare_key("\u{13F0}"));
        // 단순 폴딩 항목이 없는 İ 는 그대로.
        assert_eq!(compare_key("İ"), "İ");
    }

    #[test]
    fn names() {
        assert_eq!(folder_name("D:\\one\\docs"), "docs");
        assert_eq!(folder_name("C:\\"), "C:\\");
        assert_eq!(parent_name("D:\\one\\docs").as_deref(), Some("one"));
        assert_eq!(parent_name("D:\\docs").as_deref(), Some("D:"));
    }
}

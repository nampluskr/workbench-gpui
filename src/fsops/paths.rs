//! 경로 문자열 (I-548 Copy Path, I-549 Copy Relative Path, L-247 항목 툴팁).

use std::path::Path;

/// I-548 절대 경로(Windows 구분자 `\`).
pub fn absolute(path: &Path) -> String {
    path.to_string_lossy().into_owned()
}

/// I-549 등록 폴더 루트 기준 상대 경로. 루트 자신이면 폴더 이름(판단: Zed 루트 항목의 상대 경로는 비어 있어 이름으로 둔다).
pub fn relative(path: &Path, root: &Path) -> String {
    match path.strip_prefix(root) {
        Ok(rel) if rel.as_os_str().is_empty() => root
            .file_name()
            .map(|n| n.to_string_lossy().into_owned())
            .unwrap_or_else(|| absolute(root)),
        Ok(rel) => rel.to_string_lossy().into_owned(),
        Err(_) => absolute(path),
    }
}

/// L-247 항목 툴팁: 절대 경로, 홈 폴더는 `~`.
pub fn tooltip(path: &Path, home: Option<&Path>) -> String {
    let abs = absolute(path);
    if let Some(home) = home {
        let h = absolute(home);
        let lower = abs.to_lowercase();
        let hl = h.to_lowercase();
        if lower == hl {
            return "~".into();
        }
        if lower.starts_with(&format!("{hl}\\")) {
            return format!("~{}", &abs[h.len()..]);
        }
    }
    abs
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    #[test]
    fn copy_path_strings() {
        let root = PathBuf::from("D:\\w\\proj");
        assert_eq!(absolute(&root.join("a\\b.md")), "D:\\w\\proj\\a\\b.md");
        assert_eq!(relative(&root.join("a\\b.md"), &root), "a\\b.md");
        assert_eq!(relative(&root, &root), "proj");
        let home = PathBuf::from("C:\\Users\\me");
        assert_eq!(tooltip(&PathBuf::from("C:\\Users\\me\\x\\y.txt"), Some(&home)), "~\\x\\y.txt");
        assert_eq!(tooltip(&PathBuf::from("D:\\x"), Some(&home)), "D:\\x");
    }
}

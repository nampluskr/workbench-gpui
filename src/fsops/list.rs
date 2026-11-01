//! 폴더 읽기와 정렬 (L-50 `sort_mode: "directories_first"`, `sort_order: "default"` = 대소문자 무시 자연 정렬).

use std::cmp::Ordering;
use std::path::{Path, PathBuf};

/// 폴더 안 항목 하나.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Child {
    pub name: String,
    pub path: PathBuf,
    pub is_dir: bool,
}

/// 폴더의 자식 목록(정렬함). 읽지 못하면 오류.
/// 심볼릭 링크·정션은 따라간 대상의 종류로 본다(`metadata`). 대상이 없으면 파일로 본다(판단).
pub fn read_children(dir: &Path) -> std::io::Result<Vec<Child>> {
    let mut out = Vec::new();
    for entry in std::fs::read_dir(dir)? {
        let Ok(entry) = entry else { continue };
        let path = entry.path();
        let is_dir = std::fs::metadata(&path).map(|m| m.is_dir()).unwrap_or(false);
        let name = entry.file_name().to_string_lossy().into_owned();
        out.push(Child { name, path, is_dir });
    }
    sort_children(&mut out);
    Ok(out)
}

/// L-50: 폴더 먼저, 그다음 이름의 대소문자 무시 자연 정렬.
pub fn sort_children(children: &mut [Child]) {
    children.sort_by(|a, b| b.is_dir.cmp(&a.is_dir).then_with(|| natural_cmp(&a.name, &b.name)));
}

/// 대소문자 무시 자연 정렬: 숫자 덩어리는 수 크기로, 나머지는 소문자로 비교한다.
/// 같으면 원래 문자열로 비교해 순서를 하나로 정한다.
pub fn natural_cmp(a: &str, b: &str) -> Ordering {
    let (mut ia, mut ib) = (a.chars().peekable(), b.chars().peekable());
    loop {
        match (ia.peek().copied(), ib.peek().copied()) {
            (None, None) => return a.cmp(b),
            (None, Some(_)) => return Ordering::Less,
            (Some(_), None) => return Ordering::Greater,
            (Some(ca), Some(cb)) if ca.is_ascii_digit() && cb.is_ascii_digit() => {
                let da = take_digits(&mut ia);
                let db = take_digits(&mut ib);
                let ta = da.trim_start_matches('0');
                let tb = db.trim_start_matches('0');
                let ord = ta.len().cmp(&tb.len()).then_with(|| ta.cmp(tb));
                if ord != Ordering::Equal {
                    return ord;
                }
            }
            (Some(ca), Some(cb)) => {
                let la: String = ca.to_lowercase().collect();
                let lb: String = cb.to_lowercase().collect();
                if la != lb {
                    return la.cmp(&lb);
                }
                ia.next();
                ib.next();
            }
        }
    }
}

fn take_digits(it: &mut std::iter::Peekable<std::str::Chars<'_>>) -> String {
    let mut s = String::new();
    while let Some(c) = it.peek().copied().filter(|c| c.is_ascii_digit()) {
        s.push(c);
        it.next();
    }
    s
}

#[cfg(test)]
mod tests {
    use super::*;

    fn c(name: &str, is_dir: bool) -> Child {
        Child { name: name.into(), path: PathBuf::from(name), is_dir }
    }

    #[test]
    fn l50_directories_first_natural() {
        let mut v = vec![c("b.md", false), c("file10", false), c("Zeta", true), c("file2", false), c("alpha", true), c("A.md", false)];
        sort_children(&mut v);
        let names: Vec<_> = v.iter().map(|c| c.name.as_str()).collect();
        assert_eq!(names, ["alpha", "Zeta", "A.md", "b.md", "file2", "file10"]);
    }
}

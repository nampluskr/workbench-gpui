//! 프로젝트 패널 트리의 보이는 행 만들기 (R-17: L-41 루트 맨 위, L-42 경로 접기, L-38 안내선, P-019 새 항목 가상 행).
//! gpui 와 무관하다. UI 는 이 행 목록을 gpui-component TreeState 에 넣어 그린다(D-8).

use std::collections::{HashMap, HashSet};
use std::path::{Path, PathBuf};

use super::list::{Child, read_children};

/// 들여쓰기 안내선 한 단계(L-38). `depth` 단계 폴더의 자식 구간에 걸친다.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Guide {
    pub depth: usize,
    /// 구간의 첫 행(위 4px 여백).
    pub first: bool,
    /// 구간의 마지막 행(아래 4px 여백).
    pub last: bool,
}

/// 보이는 행 하나.
#[derive(Clone, Debug)]
pub struct Row {
    /// 행의 정체: 접힌 경로면 마지막 조각의 경로. 새 항목 가상 행이면 부모 경로.
    pub path: PathBuf,
    pub depth: usize,
    pub is_dir: bool,
    pub is_root: bool,
    pub expanded: bool,
    /// 접힌 경로의 조각들(L-42·L-43). 접히지 않았으면 하나.
    pub segments: Vec<(String, PathBuf)>,
    pub guides: Vec<Guide>,
    /// 새 항목 가상 행이면 Some(폴더인가)(P-019).
    pub new_entry: Option<bool>,
}

impl Row {
    /// TreeState 항목 id.
    pub fn key(&self) -> String {
        match self.new_entry {
            Some(_) => format!("{}\u{0}new", self.path.display()),
            None => self.path.display().to_string(),
        }
    }

    /// 화면 글자: 조각을 ` \ ` 로 잇는다(L-43 Windows 구분자).
    pub fn label(&self) -> String {
        self.segments.iter().map(|(n, _)| n.as_str()).collect::<Vec<_>>().join(" \\ ")
    }

    /// 이 행이 `path` 를 (조각으로라도) 가리키는가.
    pub fn covers(&self, path: &Path) -> bool {
        self.new_entry.is_none() && self.segments.iter().any(|(_, p)| p == path)
    }
}

/// 폴더 읽기 결과 저장. 파일 작업 뒤·창 활성 때 비운다.
#[derive(Default)]
pub struct Listing {
    map: HashMap<PathBuf, Vec<Child>>,
}

impl Listing {
    pub fn clear(&mut self) {
        self.map.clear();
    }

    /// 읽지 못하면 빈 목록(판단).
    pub fn children(&mut self, dir: &Path) -> &[Child] {
        self.map
            .entry(dir.to_path_buf())
            .or_insert_with(|| read_children(dir).unwrap_or_default())
    }
}

/// 트리를 만들 때 쓰는 상태.
pub struct BuildInput<'a> {
    pub root: &'a Path,
    pub root_name: &'a str,
    pub expanded: &'a HashSet<PathBuf>,
    /// Unfold Directory 로 접기를 끈 폴더(I-538).
    pub unfolded: &'a HashSet<PathBuf>,
    /// 새 항목 입력 중이면 (부모 폴더, 폴더인가).
    pub new_entry: Option<(&'a Path, bool)>,
}

/// 보이는 행 목록. 루트는 맨 위 한 줄이고(L-41) 접지 않는다.
pub fn build(input: &BuildInput, listing: &mut Listing) -> Vec<Row> {
    let root = input.root.to_path_buf();
    let expanded = input.expanded.contains(&root);
    let mut rows = vec![Row {
        path: root.clone(),
        depth: 0,
        is_dir: true,
        is_root: true,
        expanded,
        segments: vec![(input.root_name.to_string(), root.clone())],
        guides: Vec::new(),
        new_entry: None,
    }];
    if expanded {
        push_children(input, listing, &root, 1, &mut rows);
    }
    add_guides(&mut rows);
    rows
}

fn new_row(dir: &Path, depth: usize, is_dir: bool) -> Row {
    Row {
        path: dir.to_path_buf(),
        depth,
        is_dir,
        is_root: false,
        expanded: false,
        segments: vec![(String::new(), dir.to_path_buf())],
        guides: Vec::new(),
        new_entry: Some(is_dir),
    }
}

fn push_children(input: &BuildInput, listing: &mut Listing, dir: &Path, depth: usize, rows: &mut Vec<Row>) {
    let children = listing.children(dir).to_vec();
    // P-019 새 항목 가상 행: 새 폴더는 맨 앞, 새 파일은 폴더들 뒤 첫 자리(판단: L-50 폴더 먼저 정렬 안의 맨 앞).
    let new_here = input.new_entry.filter(|(p, _)| *p == dir).map(|(_, d)| d);
    let mut pending = new_here;
    if pending == Some(true) {
        rows.push(new_row(dir, depth, true));
        pending = None;
    }
    for child in children {
        if !child.is_dir {
            if let Some(is_dir) = pending.take() {
                rows.push(new_row(dir, depth, is_dir));
            }
            rows.push(Row {
                path: child.path.clone(),
                depth,
                is_dir: false,
                is_root: false,
                expanded: false,
                segments: vec![(child.name.clone(), child.path.clone())],
                guides: Vec::new(),
                new_entry: None,
            });
            continue;
        }
        // L-42: 자식이 정확히 하나이고 그것도 폴더면 한 줄로 합친다(연쇄). Unfold 한 폴더와 새 항목의 부모에서 멈춘다.
        let mut segments = vec![(child.name.clone(), child.path.clone())];
        let mut last = child.path.clone();
        // D-043 ②: 정션·링크가 자기나 상위를 가리키면 접기가 끝나지 않는다. 실제 경로로 들른 폴더가 다시 나오면 멈춘다.
        let mut seen = std::collections::HashSet::new();
        seen.insert(std::fs::canonicalize(&last).unwrap_or_else(|_| last.clone()));
        loop {
            if input.unfolded.contains(&last) || input.new_entry.is_some_and(|(p, _)| p == last) {
                break;
            }
            let next_is_seen = listing.children(&last).first().is_some_and(|k| {
                !seen.insert(std::fs::canonicalize(&k.path).unwrap_or_else(|_| k.path.clone()))
            });
            if next_is_seen {
                break;
            }
            let kids = listing.children(&last);
            if kids.len() == 1 && kids[0].is_dir {
                let next = kids[0].clone();
                segments.push((next.name, next.path.clone()));
                last = next.path;
            } else {
                break;
            }
        }
        let expanded = input.expanded.contains(&last);
        rows.push(Row {
            path: last.clone(),
            depth,
            is_dir: true,
            is_root: false,
            expanded,
            segments,
            guides: Vec::new(),
            new_entry: None,
        });
        if expanded {
            push_children(input, listing, &last, depth + 1, rows);
        }
    }
    if let Some(is_dir) = pending {
        rows.push(new_row(dir, depth, is_dir));
    }
}

/// L-38: 펼친 폴더마다 자식 구간(첫 자식 ~ 마지막 자손)에 안내선 한 단계.
fn add_guides(rows: &mut [Row]) {
    for i in 0..rows.len() {
        if !(rows[i].is_dir && rows[i].expanded && rows[i].new_entry.is_none()) {
            continue;
        }
        let d = rows[i].depth;
        let mut j = i;
        while j + 1 < rows.len() && rows[j + 1].depth > d {
            j += 1;
        }
        for (k, row) in rows.iter_mut().enumerate().take(j + 1).skip(i + 1) {
            row.guides.push(Guide { depth: d, first: k == i + 1, last: k == j });
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;

    #[test]
    fn l42_fold_and_l38_guides() {
        let root = std::env::temp_dir().join(format!("wg-tree-{}", std::process::id()));
        let _ = fs::remove_dir_all(&root);
        fs::create_dir_all(root.join("docs").join("guides")).unwrap();
        fs::write(root.join("docs").join("guides").join("a.md"), b"").unwrap();
        fs::create_dir_all(root.join("src")).unwrap();
        fs::write(root.join("src").join("main.rs"), b"").unwrap();
        fs::write(root.join("README.md"), b"").unwrap();
        let mut expanded = HashSet::new();
        expanded.insert(root.clone());
        let guides = root.join("docs").join("guides");
        expanded.insert(guides.clone());
        let unfolded = HashSet::new();
        let mut listing = Listing::default();
        let input = BuildInput { root: &root, root_name: "proj", expanded: &expanded, unfolded: &unfolded, new_entry: None };
        let rows = build(&input, &mut listing);
        let labels: Vec<_> = rows.iter().map(|r| (r.depth, r.label())).collect();
        assert_eq!(
            labels,
            vec![(0, "proj".to_string()), (1, "docs \\ guides".into()), (2, "a.md".into()), (1, "src".into()), (1, "README.md".into())]
        );
        assert_eq!(rows[1].path, guides);
        // 루트 안내선은 1~4행, 첫 행·끝 행 표시. docs\guides 안내선은 a.md 한 행.
        assert_eq!(rows[1].guides, vec![Guide { depth: 0, first: true, last: false }]);
        assert_eq!(rows[2].guides.len(), 2);
        assert_eq!(rows[4].guides, vec![Guide { depth: 0, first: false, last: true }]);
        // Unfold: 접기를 끈다.
        let mut unfolded = HashSet::new();
        unfolded.insert(root.join("docs"));
        let input = BuildInput { root: &root, root_name: "proj", expanded: &expanded, unfolded: &unfolded, new_entry: None };
        let rows = build(&input, &mut listing);
        assert_eq!(rows[1].label(), "docs");
        // 새 파일 가상 행: 폴더 뒤 첫 자리.
        let input = BuildInput { root: &root, root_name: "proj", expanded: &expanded, unfolded: &HashSet::new(), new_entry: Some((&root, false)) };
        let rows = build(&input, &mut listing);
        let kinds: Vec<_> = rows.iter().map(|r| (r.new_entry, r.label())).collect();
        assert_eq!(kinds[4], (Some(false), String::new()));
        assert_eq!(kinds[5].1, "README.md");
        fs::remove_dir_all(&root).unwrap();
    }
}

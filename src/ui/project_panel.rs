//! 프로젝트 패널 트리 상태 (v0.2 Phase 4, SPEC R-17·R-18, DECISIONS D-8).
//!
//! 폴더(Workspace)마다 하나다(A-15.2: 펼침·선택·스크롤을 폴더마다 메모리에 둔다, 저장하지 않는다).
//! 보이는 행은 `fsops::tree::build` 가 만들고, gpui-component 의 TreeState(gpui-base `TreeState`, 가상화
//! uniform_list·스크롤 핸들)에 중첩 TreeItem 으로 넣는다(D-8). 펼침·선택·누르기·키는 TreeState 의 기본 동작
//! (한 항목 선택, 누르면 펼침 토글, 자기 `Tree` 컨텍스트의 화살표 키) 대신 우리가 정한다(I-087~I-090):
//! 포커스는 늘 우리 `ProjectPanel` 자리에 두어 TreeState 의 `Tree` 컨텍스트가 키 디스패치 경로에 들어오지 않게 한다.

use std::cell::RefCell;
use std::collections::{HashMap, HashSet};
use std::path::{Path, PathBuf};
use std::rc::Rc;

use gpui_kit::base::{TreeItem, TreeState};
use gpui_kit::component::input::InputState;
use gpui_kit::*;

use crate::fsops::names::Validation;
use crate::fsops::tree::{self as ftree, Listing, Row};

/// 인라인 입력칸의 종류(I-091).
#[derive(Clone, Debug)]
pub enum EditKind {
    New { dir: PathBuf, is_dir: bool },
    Rename { path: PathBuf },
}

/// 인라인 입력칸 상태(P-019~P-022).
pub struct EditState {
    pub kind: EditKind,
    pub input: Entity<InputState>,
    pub validation: Option<Validation>,
    /// Escape 때 되돌릴 선택(P-022).
    pub prev_selected: Option<PathBuf>,
    /// 새 항목을 넣으려고 임시로 펼친 폴더(Escape 때 다시 접는다, P-022).
    pub temp_expanded: Option<PathBuf>,
    pub _subs: Vec<Subscription>,
}

pub struct ProjectTree {
    pub root: PathBuf,
    pub root_name: String,
    pub state: Entity<TreeState>,
    pub expanded: HashSet<PathBuf>,
    pub unfolded: HashSet<PathBuf>,
    pub listing: Listing,
    pub rows: Vec<Row>,
    /// 활성(커서) 항목. 접힌 경로의 조각일 수 있다(L-43).
    pub selected: Option<PathBuf>,
    /// 여러 항목 표시(I-090, I-043). 비어 있으면 `selected` 하나다.
    pub marked: Vec<PathBuf>,
    /// Shift 범위 선택의 기준.
    pub anchor: Option<PathBuf>,
    pub edit: Option<EditState>,
    /// 그린 행의 창 기준 경계(키보드로 연 우클릭 메뉴 위치, I-502). 행 번호 → 경계.
    pub row_bounds: Rc<RefCell<HashMap<usize, Bounds<Pixels>>>>,
}

fn to_items(rows: &[Row], ix: &mut usize, depth: usize) -> Vec<TreeItem> {
    let mut out = Vec::new();
    while *ix < rows.len() && rows[*ix].depth == depth {
        let row = &rows[*ix];
        *ix += 1;
        let children = to_items(rows, ix, depth + 1);
        out.push(TreeItem::new(row.key(), row.label()).expanded(row.expanded).children(children));
    }
    out
}

impl ProjectTree {
    /// 처음에는 루트만 펼친다(판단: Zed 는 워크트리 루트를 펼친 채 시작한다. I-120 은 저장·복원을 정하지 않았다).
    pub fn new(root: PathBuf, root_name: String, cx: &mut App) -> Self {
        let state = cx.new(|cx| TreeState::new(cx));
        let mut expanded = HashSet::new();
        expanded.insert(root.clone());
        let mut this = Self {
            root,
            root_name,
            state,
            expanded,
            unfolded: HashSet::new(),
            listing: Listing::default(),
            rows: Vec::new(),
            selected: None,
            marked: Vec::new(),
            anchor: None,
            edit: None,
            row_bounds: Rc::new(RefCell::new(HashMap::new())),
        };
        this.rebuild(cx);
        this
    }

    /// 보이는 행을 다시 만들고 TreeState 에 넣는다. 사라진 선택·표시는 지운다.
    pub fn rebuild(&mut self, cx: &mut App) {
        let new_entry = match self.edit.as_ref().map(|e| &e.kind) {
            Some(EditKind::New { dir, is_dir }) => Some((dir.clone(), *is_dir)),
            _ => None,
        };
        let input = ftree::BuildInput {
            root: &self.root,
            root_name: &self.root_name,
            expanded: &self.expanded,
            unfolded: &self.unfolded,
            new_entry: new_entry.as_ref().map(|(d, f)| (d.as_path(), *f)),
        };
        self.rows = ftree::build(&input, &mut self.listing);
        let mut ix = 0;
        let items = to_items(&self.rows, &mut ix, 0);
        self.state.update(cx, |s, cx| s.set_items(items, cx));
        let rows = &self.rows;
        if let Some(sel) = self.selected.clone()
            && !rows.iter().any(|r| r.covers(&sel))
        {
            // 선택 항목이 접힌 폴더 안으로 숨었거나 사라졌으면 보이는 가장 가까운 상위 폴더를 고른다(판단).
            let visible = sel.ancestors().skip(1).find(|a| rows.iter().any(|r| r.covers(a))).map(Path::to_path_buf);
            self.selected = visible;
        }
        self.marked.retain(|p| rows.iter().any(|r| r.covers(p)));
    }

    /// 디스크를 다시 읽는다(파일 작업 뒤·창 활성 때).
    pub fn refresh(&mut self, cx: &mut App) {
        self.listing.clear();
        self.expanded.retain(|p| p.is_dir());
        self.rebuild(cx);
    }

    /// 바깥에서 이름이 바뀐 항목을 따라간다(Phase 5, 판단): 펼침·접기 끔·선택·표시·기준의 경로를 새 경로로 바꾼다.
    pub fn follow_rename(&mut self, from: &Path, to: &Path) {
        let map = |p: &Path| -> Option<PathBuf> {
            let rest = p.strip_prefix(from).ok()?;
            Some(if rest.as_os_str().is_empty() { to.to_path_buf() } else { to.join(rest) })
        };
        let remap_set = |set: &mut HashSet<PathBuf>| {
            *set = set.drain().map(|p| map(&p).unwrap_or(p)).collect();
        };
        remap_set(&mut self.expanded);
        remap_set(&mut self.unfolded);
        for p in self.selected.iter_mut().chain(self.anchor.iter_mut()).chain(self.marked.iter_mut()) {
            if let Some(n) = map(p) {
                *p = n;
            }
        }
    }

    pub fn index_of(&self, path: &Path) -> Option<usize> {
        self.rows.iter().position(|r| r.covers(path))
    }

    pub fn selected_index(&self) -> Option<usize> {
        self.selected.as_deref().and_then(|p| self.index_of(p))
    }

    pub fn is_root(&self, path: &Path) -> bool {
        path == self.root
    }

    /// 작업 대상: 표시가 있고 선택이 그 안에 있으면 표시한 모두(하나 남았어도 그 하나), 아니면 선택 하나(I-562, D-043 ③).
    pub fn targets(&self) -> Vec<PathBuf> {
        match &self.selected {
            Some(sel) if !self.marked.is_empty() && self.marked.contains(sel) => self.marked.clone(),
            Some(sel) => vec![sel.clone()],
            None => Vec::new(),
        }
    }

    /// 하나만 선택한다(표시를 지운다).
    pub fn select_only(&mut self, path: Option<PathBuf>) {
        self.selected = path.clone();
        self.anchor = path;
        self.marked.clear();
    }

    /// 행이 보이게 스크롤한다.
    pub fn scroll_to(&self, ix: usize, cx: &mut App) {
        self.state.update(cx, |s, _| s.scroll_to_item(ix, ScrollStrategy::Nearest));
    }

    /// 루트 기준 상대 경로 글자(dev 출력). 루트는 `.`.
    pub fn rel(&self, path: &Path) -> String {
        match path.strip_prefix(&self.root) {
            Ok(r) if r.as_os_str().is_empty() => ".".into(),
            Ok(r) => r.display().to_string(),
            Err(_) => path.display().to_string(),
        }
    }
}

//! 디스크 감시 이벤트 묶기 (v0.2 Phase 5, SPEC R-24, G-115, D-6 `notify`). gpui·notify 와 무관하다.
//!
//! - 바깥 프로그램 한 번의 작업에도 이벤트가 여러 개 온다. 잠잠해질 때(`QUIET`)까지, 길어도 `MAX_WAIT` 까지 모아
//!   한 번만 반영한다(폭주 묶기).
//! - 너무 많이 오면(`KEEP` 넘음) 낱낱의 경로는 버리고 "전부 다시 읽기"로만 남긴다.
//! - 앱 자신이 한 파일 작업의 경로(`SelfOps`)는 잠깐 기억해, 그 작업이 일으킨 이벤트를 바깥 변경과 구분한다.

use std::path::{Path, PathBuf};
use std::time::{Duration, Instant};

/// 마지막 이벤트 뒤 이만큼 조용하면 반영한다(판단).
pub const QUIET: Duration = Duration::from_millis(150);
/// 이벤트가 끊이지 않아도 첫 이벤트 뒤 이만큼 지나면 반영한다(판단).
pub const MAX_WAIT: Duration = Duration::from_millis(1000);
/// 한 묶음에 낱낱이 남기는 이벤트 수. 넘으면 경로는 버리고 전부 다시 읽는다(판단).
pub const KEEP: usize = 2048;
/// 이보다 많은 묶음 뒤에는 잠시 뒤 한 번 더 다시 읽는다(감시 버퍼가 넘쳐 잃은 이벤트 대비, 판단).
pub const FLOOD: usize = 256;
/// 폭주 뒤 한 번 더 다시 읽기까지의 시간(판단).
pub const SETTLE: Duration = Duration::from_millis(500);
/// 앱 자신의 작업 경로를 기억하는 시간(판단).
pub const SELF_WINDOW: Duration = Duration::from_millis(3000);

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Kind {
    Create,
    Remove,
    Modify,
    RenameFrom,
    RenameTo,
    Other,
}

#[derive(Clone, Debug)]
pub struct Change {
    pub kind: Kind,
    pub path: PathBuf,
}

/// 아직 반영하지 않은 이벤트.
#[derive(Default)]
pub struct Pending {
    changes: Vec<Change>,
    /// 이벤트마다 감시 스레드가 받은 시각(changes 와 같은 차례).
    times: Vec<Instant>,
    count: usize,
    lost: bool,
    first: Option<Instant>,
    last: Option<Instant>,
}

/// 한 번에 반영할 묶음.
#[derive(Debug)]
pub struct Batch {
    pub changes: Vec<Change>,
    /// 이벤트마다 감시 스레드가 받은 시각(changes 와 같은 차례). 앱 자신 작업 대응은 이 시각으로 한다(D-047 ⓐ).
    pub times: Vec<Instant>,
    /// 받은 이벤트 수(버린 것 포함).
    pub count: usize,
    /// 낱낱의 경로를 잃었다(너무 많음·감시 오류). 전부 다시 읽는다.
    pub lost: bool,
    pub first: Instant,
}

impl Pending {
    fn touch(&mut self, now: Instant) {
        self.count += 1;
        self.first.get_or_insert(now);
        self.last = Some(now);
    }

    pub fn push(&mut self, change: Change, now: Instant) {
        self.touch(now);
        if self.changes.len() < KEEP {
            self.changes.push(change);
            self.times.push(now);
        } else {
            self.lost = true;
        }
    }

    /// 감시 오류: 무엇이 바뀌었는지 모른다.
    pub fn push_lost(&mut self, now: Instant) {
        self.touch(now);
        self.lost = true;
    }

    pub fn is_empty(&self) -> bool {
        self.count == 0
    }

    /// 반영할 때인가.
    pub fn ready(&self, now: Instant) -> bool {
        match (self.first, self.last) {
            (Some(first), Some(last)) => now >= last + QUIET || now >= first + MAX_WAIT,
            _ => false,
        }
    }

    pub fn take(&mut self) -> Option<Batch> {
        let first = self.first?;
        let taken = std::mem::take(self);
        Some(Batch { changes: taken.changes, times: taken.times, count: taken.count, lost: taken.lost, first })
    }
}

/// `path` 가 `root` 안(루트 자신은 아님)인가.
fn strictly_under(path: &Path, root: &Path) -> bool {
    path != root && path.starts_with(root)
}

impl Batch {
    /// 트리를 다시 읽어야 하나: 루트 안에서 항목이 생기거나 지워지거나 이름이 바뀌었거나 경로를 잃었다.
    /// 내용·속성 수정(Modify)은 트리(이름만 보인다)를 바꾸지 않으므로 세지 않는다. 폴더 수정 시각은 NTFS 가 늦게(약 1초 뒤)
    /// 따로 알려서, 세면 같은 변경에 다시 읽기가 한 번 더 생긴다(판단).
    pub fn touches_tree(&self, root: &Path) -> bool {
        self.lost || self.changes.iter().any(|c| c.kind != Kind::Modify && strictly_under(&c.path, root))
    }

    /// 등록 폴더가 있는지 다시 봐야 하나: 루트 자신이나 루트 밖(부모 폴더 감시)의 변경이 있거나 경로를 잃었다.
    pub fn touches_root(&self, root: &Path) -> bool {
        self.lost || self.changes.iter().any(|c| !strictly_under(&c.path, root))
    }

    /// 이름 바꾸기 짝: RenameFrom 바로 뒤의 RenameTo(ReadDirectoryChangesW 가 같은 버퍼에 잇달아 낸다).
    #[cfg(test)]
    pub fn renames(&self) -> Vec<(PathBuf, PathBuf)> {
        self.changes
            .windows(2)
            .filter(|w| w[0].kind == Kind::RenameFrom && w[1].kind == Kind::RenameTo)
            .map(|w| (w[0].path.clone(), w[1].path.clone()))
            .collect()
    }

    /// 이름 바꾸기 짝과 감시 스레드가 그 RenameFrom 을 받은 시각(D-047 ⓐ).
    pub fn renames_at(&self) -> Vec<(PathBuf, PathBuf, Instant)> {
        (1..self.changes.len())
            .filter(|&i| self.changes[i - 1].kind == Kind::RenameFrom && self.changes[i].kind == Kind::RenameTo)
            .map(|i| (self.changes[i - 1].path.clone(), self.changes[i].path.clone(), self.times[i - 1]))
            .collect()
    }

    /// 이 경로(파일)를 가리키는 변경이 있나.
    pub fn names(&self, path: &Path) -> bool {
        self.lost || self.changes.iter().any(|c| c.path == path || path.starts_with(&c.path))
    }

    /// 루트 자신이 지워졌거나 이름이 바뀌었거나(부모 폴더 감시) 감시가 어긋났나(경로를 잃음). 그러면 지금 감시자가 옛 폴더를
    /// 가리킬 수 있어, 루트가 다시 있어도 감시를 새로 등록한다(리뷰 1회차 ③, D-046).
    pub fn root_replaced(&self, root: &Path) -> bool {
        self.lost
            || self.changes.iter().any(|c| {
                matches!(c.kind, Kind::Remove | Kind::RenameFrom) && super::names::same_path(&c.path, root)
            })
    }
}

/// 앱 작업 기록은 이 시간이 지나면 지운다(쌓이지 않게). 대응 판단은 이벤트를 받은 시각으로 한다(D-047 ⓐ).
const KEEP_RECORDS: Duration = Duration::from_secs(60);
/// 감시 스레드가 이벤트를 앱이 작업을 기록하기 조금 전에 받을 수 있다(작업 → 이벤트 → 기록 차례). 그만큼 앞도 본다.
const RECORD_SLACK: Duration = Duration::from_millis(1000);

/// 이벤트를 받은 시각이 앱 작업 기록 시각과 대응하는가: 기록보다 조금 앞(RECORD_SLACK)부터 기록 뒤 SELF_WINDOW 안.
/// UI 반영이 늦어져도(지금 시각) 판단이 바뀌지 않는다(D-047 ⓐ).
fn matches_time(event_at: Instant, recorded: Instant) -> bool {
    event_at + RECORD_SLACK >= recorded && event_at.saturating_duration_since(recorded) < SELF_WINDOW
}

/// 앱 자신이 한 파일 작업의 경로.
#[derive(Default)]
pub struct SelfOps {
    entries: Vec<(PathBuf, Instant)>,
    /// 앱이 이미 반영한 이름 바꾸기·같은 볼륨 이동(옛 경로, 새 경로). 감시가 같은 짝을 다시 적용하지 않게 한 번 쓰면 지운다(D-046 ①).
    renames: Vec<(PathBuf, PathBuf, Instant)>,
}

impl SelfOps {
    pub fn record_rename(&mut self, from: &Path, to: &Path, now: Instant) {
        self.renames.retain(|(_, _, t)| now.saturating_duration_since(*t) < KEEP_RECORDS);
        self.renames.push((from.to_path_buf(), to.to_path_buf(), now));
    }

    /// 이 이름 바꾸기 짝(감시 스레드가 `event_at` 에 받음)이 앱 자신이 이미 반영한 것이면 기록에서 지우고 true.
    /// 대응은 받은 시각으로 판단하고, 지금 시각(`now`)은 오래된 기록을 치우는 데만 쓴다(D-047 ⓐ).
    pub fn take_rename(&mut self, from: &Path, to: &Path, event_at: Instant, now: Instant) -> bool {
        self.renames.retain(|(_, _, t)| now.saturating_duration_since(*t) < KEEP_RECORDS);
        match self
            .renames
            .iter()
            .position(|(f, t, at)| f == from && t == to && matches_time(event_at, *at))
        {
            Some(i) => {
                self.renames.remove(i);
                true
            }
            None => false,
        }
    }

    pub fn record(&mut self, paths: &[&Path], now: Instant) {
        self.entries.retain(|(_, t)| now.saturating_duration_since(*t) < KEEP_RECORDS);
        for p in paths {
            self.entries.push((p.to_path_buf(), now));
        }
    }

    /// 앱 자신의 작업이 일으킨 이벤트인가(감시 스레드가 `event_at` 에 받음): 그 경로나 그 아래, 또는 그 경로의 부모 폴더가
    /// 바뀌었다는 알림.
    pub fn is_self(&self, change: &Change, event_at: Instant) -> bool {
        self.entries.iter().any(|(p, t)| {
            matches_time(event_at, *t)
                && (change.path.starts_with(p) || (change.kind == Kind::Modify && p.parent() == Some(change.path.as_path())))
        })
    }

    /// (앱 자신, 바깥) 이벤트 수. 잃은 묶음은 모두 바깥으로 센다.
    pub fn classify(&self, batch: &Batch) -> (usize, usize) {
        let own = batch
            .changes
            .iter()
            .zip(&batch.times)
            .filter(|(c, at)| self.is_self(c, **at))
            .count();
        if batch.lost {
            (own, batch.count - own)
        } else {
            (own, batch.changes.len() - own)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn ch(kind: Kind, p: &str) -> Change {
        Change { kind, path: PathBuf::from(p) }
    }

    #[test]
    fn p5_batch_waits_for_quiet_or_max() {
        let t0 = Instant::now();
        let mut p = Pending::default();
        assert!(!p.ready(t0));
        p.push(ch(Kind::Create, "r/a"), t0);
        assert!(!p.ready(t0 + Duration::from_millis(100)));
        assert!(p.ready(t0 + QUIET));
        // 이벤트가 끊이지 않으면 MAX_WAIT 에서 반영한다.
        let mut t = t0;
        while t < t0 + MAX_WAIT {
            t += Duration::from_millis(100);
            p.push(ch(Kind::Modify, "r/a"), t);
        }
        assert!(p.ready(t));
        let b = p.take().unwrap();
        assert_eq!(b.count, 11);
        assert!(p.is_empty() && p.take().is_none());
    }

    #[test]
    fn p5_batch_keeps_limit_then_lost() {
        let t0 = Instant::now();
        let mut p = Pending::default();
        for i in 0..KEEP + 5 {
            p.push(ch(Kind::Create, &format!("r/f{i}")), t0);
        }
        let b = p.take().unwrap();
        assert_eq!((b.changes.len(), b.count, b.lost), (KEEP, KEEP + 5, true));
        assert!(b.touches_tree(Path::new("q")) && b.touches_root(Path::new("q")));
    }

    #[test]
    fn p5_batch_tree_root_rename() {
        let t0 = Instant::now();
        let mut p = Pending::default();
        p.push(ch(Kind::RenameFrom, "r/a"), t0);
        p.push(ch(Kind::RenameTo, "r/b"), t0);
        p.push(ch(Kind::Remove, "r/c"), t0);
        p.push(ch(Kind::RenameTo, "r/d"), t0);
        let b = p.take().unwrap();
        let root = Path::new("r");
        assert!(b.touches_tree(root) && !b.touches_root(root));
        // 내용·폴더 수정 시각만 바뀐 묶음은 트리를 다시 읽지 않는다(탭만 본다).
        let mut m = Pending::default();
        m.push(ch(Kind::Modify, "r/a.txt"), t0);
        m.push(ch(Kind::Modify, "r/sub"), t0);
        let mb = m.take().unwrap();
        assert!(!mb.touches_tree(root) && mb.names(Path::new("r/a.txt")));
        assert_eq!(b.renames(), vec![(PathBuf::from("r/a"), PathBuf::from("r/b"))]);
        assert!(b.names(Path::new("r/c")) && b.names(Path::new("r/a/x.txt")) && !b.names(Path::new("r/e")));
        // 부모 폴더 감시에서 온 형제 변경·루트 자신의 삭제는 존재 확인만.
        let mut p = Pending::default();
        p.push(ch(Kind::Create, "sibling"), t0);
        p.push(ch(Kind::Remove, "r"), t0);
        let b = p.take().unwrap();
        assert!(!b.touches_tree(root) && b.touches_root(root));
    }

    #[test]
    fn p5_self_ops_distinguished() {
        let t0 = Instant::now();
        let mut s = SelfOps::default();
        s.record(&[Path::new("r/new.txt"), Path::new("r/dir")], t0);
        let t = t0 + Duration::from_millis(200);
        assert!(s.is_self(&ch(Kind::Create, "r/new.txt"), t));
        assert!(s.is_self(&ch(Kind::Create, "r/dir/inner"), t));
        assert!(s.is_self(&ch(Kind::Modify, "r"), t)); // 부모 폴더 수정 알림
        assert!(!s.is_self(&ch(Kind::Remove, "r"), t));
        assert!(!s.is_self(&ch(Kind::Create, "r/other.txt"), t));
        assert!(!s.is_self(&ch(Kind::Create, "r/new.txt"), t0 + SELF_WINDOW));
        let mut p = Pending::default();
        p.push(ch(Kind::Create, "r/new.txt"), t);
        p.push(ch(Kind::Create, "r/other.txt"), t);
        assert_eq!(s.classify(&p.take().unwrap()), (1, 1));
    }

    #[test]
    fn d046_own_rename_taken_once() {
        let t0 = Instant::now();
        let mut s = SelfOps::default();
        s.record_rename(Path::new("r/a"), Path::new("r/b"), t0);
        let t = t0 + Duration::from_millis(300);
        assert!(!s.take_rename(Path::new("r/a"), Path::new("r/c"), t, t));
        assert!(s.take_rename(Path::new("r/a"), Path::new("r/b"), t, t));
        // 한 번 쓰면 지운다: 같은 짝이 바깥에서 또 오면 바깥 것으로 적용한다.
        assert!(!s.take_rename(Path::new("r/a"), Path::new("r/b"), t, t));
        s.record_rename(Path::new("r/x"), Path::new("r/y"), t0);
        assert!(!s.take_rename(Path::new("r/x"), Path::new("r/y"), t0 + SELF_WINDOW, t0 + SELF_WINDOW));
    }

    #[test]
    fn d047_own_rename_matched_by_receive_time() {
        let t0 = Instant::now();
        let mut s = SelfOps::default();
        s.record_rename(Path::new("r/a"), Path::new("r/b"), t0);
        // 감시 스레드는 0.2초 뒤에 받았지만 UI 가 늦어 10초 뒤에 반영한다: 받은 시각으로 앱 자신 것이라고 본다.
        let received = t0 + Duration::from_millis(200);
        assert!(s.take_rename(Path::new("r/a"), Path::new("r/b"), received, t0 + Duration::from_secs(10)));
        // 이벤트가 기록보다 조금 먼저 들어와도(작업 → 이벤트 → 기록) 대응한다.
        s.record_rename(Path::new("r/c"), Path::new("r/d"), t0 + Duration::from_millis(500));
        assert!(s.take_rename(Path::new("r/c"), Path::new("r/d"), t0 + Duration::from_millis(480), t0 + Duration::from_secs(5)));
        // 기록 뒤 3초가 지나 받은 같은 짝은 바깥 것이다.
        s.record_rename(Path::new("r/e"), Path::new("r/f"), t0);
        assert!(!s.take_rename(Path::new("r/e"), Path::new("r/f"), t0 + SELF_WINDOW, t0 + SELF_WINDOW));
        // 묶음의 이름 바꾸기 짝에 받은 시각이 붙는다.
        let mut p = Pending::default();
        p.push(ch(Kind::RenameFrom, "r/a"), received);
        p.push(ch(Kind::RenameTo, "r/b"), received + Duration::from_millis(1));
        assert_eq!(p.take().unwrap().renames_at(), vec![(PathBuf::from("r/a"), PathBuf::from("r/b"), received)]);
    }

    #[test]
    fn d046_root_replaced() {
        let t0 = Instant::now();
        let root = Path::new(r"D:\w\proj");
        let mut p = Pending::default();
        p.push(ch(Kind::RenameFrom, r"D:\w\Proj"), t0);
        p.push(ch(Kind::RenameTo, r"D:\w\proj-old"), t0);
        assert!(p.take().unwrap().root_replaced(root));
        let mut p = Pending::default();
        p.push(ch(Kind::Remove, r"D:\w\proj\a.txt"), t0);
        p.push(ch(Kind::Modify, r"D:\w\proj"), t0);
        p.push(ch(Kind::Create, r"D:\w\proj"), t0);
        assert!(!p.take().unwrap().root_replaced(root));
        let mut p = Pending::default();
        p.push_lost(t0);
        assert!(p.take().unwrap().root_replaced(root));
    }
}

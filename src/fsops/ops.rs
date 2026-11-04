//! 파일·폴더 작업 (R-19~R-21, A-14.3). 실패는 io 오류로 돌려준다.

use std::fs;
use std::io;
use std::path::{Path, PathBuf};

/// 새 파일. 중간 폴더도 만든다(P-022). 이미 있으면 오류.
pub fn create_file(path: &Path) -> io::Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    fs::OpenOptions::new().write(true).create_new(true).open(path).map(|_| ())
}

/// 새 폴더. 중간 폴더도 만든다. 이미 있으면 오류.
pub fn create_dir(path: &Path) -> io::Result<()> {
    if path.symlink_metadata().is_ok() {
        return Err(io::Error::new(io::ErrorKind::AlreadyExists, "already exists"));
    }
    fs::create_dir_all(path)
}

/// 이름 바꾸기·같은 볼륨 이동.
pub fn rename(from: &Path, to: &Path) -> io::Result<()> {
    fs::rename(from, to)
}

/// `dir` 안에 `name` 을 붙여 넣을 경로. 이미 있으면 ` copy`, ` copy 1`, ` copy 2` … 를 붙인다.
/// 파일은 확장자 앞에 붙이고(`a copy.txt`), 폴더는 이름 끝에 붙인다(판단, leader 판단 요청).
pub fn paste_path(dir: &Path, name: &str, is_dir: bool) -> PathBuf {
    let first = dir.join(name);
    if first.symlink_metadata().is_err() {
        return first;
    }
    let (stem, ext) = match (is_dir, name.rfind('.')) {
        (false, Some(i)) if i > 0 => (&name[..i], &name[i..]),
        _ => (name, ""),
    };
    let mut ix = 0u32;
    loop {
        let candidate = if ix == 0 {
            format!("{stem} copy{ext}")
        } else {
            format!("{stem} copy {ix}{ext}")
        };
        let path = dir.join(candidate);
        if path.symlink_metadata().is_err() {
            return path;
        }
        ix += 1;
    }
}

/// `inner` 가 `outer` 자신이거나 그 아래인가(대소문자 무시).
pub fn is_within(inner: &Path, outer: &Path) -> bool {
    let i = inner.to_string_lossy().to_lowercase();
    let o = outer.to_string_lossy().to_lowercase();
    i == o || i.starts_with(&format!("{}\\", o.trim_end_matches('\\')))
}

/// 실제 경로(정션·심볼릭 링크를 푼 canonical, 리뷰 1회차 ② D-043). 아직 없는 경로면 가장 가까운 있는 조상을 풀고
/// 나머지 이름을 붙인다.
pub fn real_path(p: &Path) -> io::Result<PathBuf> {
    let mut rest = Vec::new();
    let mut cur = p.to_path_buf();
    loop {
        match fs::canonicalize(&cur) {
            Ok(mut out) => {
                for name in rest.iter().rev() {
                    out.push(name);
                }
                return Ok(out);
            }
            Err(e) => {
                let Some(name) = cur.file_name().map(|n| n.to_os_string()) else { return Err(e) };
                rest.push(name);
                if !cur.pop() {
                    return Err(e);
                }
            }
        }
    }
}

/// 실제 경로로 본 `inner ⊆ outer`. 풀 수 없으면 글자 비교로 대신한다.
pub fn is_within_real(inner: &Path, outer: &Path) -> bool {
    match (real_path(inner), real_path(outer)) {
        (Ok(i), Ok(o)) => is_within(&i, &o),
        _ => is_within(inner, outer),
    }
}

/// 확정 경로가 실제로 `parent` 바로 아래인가(인라인 입력 확정 직전 확인, D-043 ①).
pub fn is_direct_child(target: &Path, parent: &Path) -> bool {
    match (real_path(target), real_path(parent)) {
        (Ok(t), Ok(p)) => t.parent().is_some_and(|tp| tp.to_string_lossy().to_lowercase() == p.to_string_lossy().to_lowercase()),
        _ => false,
    }
}

fn into_itself(what: &str) -> io::Error {
    io::Error::new(io::ErrorKind::InvalidInput, format!("cannot {what} a folder into itself"))
}

/// 복사 결과(리뷰 2회차 D-044 ①): 복사한 파일 수·바이트, 따라가지 않고 건너뛴 재분석 지점(정션·심볼릭 링크).
#[derive(Debug, Default, Clone, PartialEq, Eq)]
pub struct CopyReport {
    pub files: u64,
    pub dirs: u64,
    pub bytes: u64,
    pub skipped_links: Vec<PathBuf>,
}

/// 재분석 지점(정션·심볼릭 링크)인가. 따라가지 않고 본다(std 는 정션도 이름 대리 재분석 지점으로 is_symlink 로 본다).
pub fn is_reparse(path: &Path) -> bool {
    fs::symlink_metadata(path).is_ok_and(|m| m.file_type().is_symlink())
}

/// 파일·폴더 복사(폴더는 통째로). 폴더를 (정션·링크를 거쳐서라도) 자기 아래로 복사하면 오류.
/// D-044 ①: 재분석 지점은 따라가지 않고 건너뛰어 `skipped_links` 에 남긴다(맨 위 항목이 링크여도 같다).
/// 순환 검사는 지금 내려온 조상 경로 집합으로만 한다. 이미 복사한 실제 폴더라도 조상이 아니면 생략하지 않는다.
#[cfg(test)]
pub fn copy_entry(src: &Path, dst: &Path) -> io::Result<CopyReport> {
    copy_entry_with(src, dst, false)
}

/// `copy_entry` whose top-level `dst` was already claimed by `reserve_copy_target` (so it is filled, not created).
pub fn copy_reserved(src: &Path, dst: &Path) -> io::Result<CopyReport> {
    copy_entry_with(src, dst, true)
}

fn copy_entry_with(src: &Path, dst: &Path, reserved: bool) -> io::Result<CopyReport> {
    let mut report = CopyReport::default();
    if is_reparse(src) {
        report.skipped_links.push(src.to_path_buf());
        return Ok(report);
    }
    if fs::metadata(src)?.is_dir() {
        if is_within_real(dst, src) {
            return Err(into_itself("copy"));
        }
        let mut ancestors = Vec::new();
        copy_dir(src, dst, reserved, &mut ancestors, &mut report)?;
    } else {
        report.bytes += copy_file(src, dst, reserved)?;
        report.files += 1;
    }
    Ok(report)
}

/// Single point for copying file contents. The destination name is first claimed exclusively
/// (`create_new`, so an existing file is never overwritten: AlreadyExists), then `fs::copy` fills that
/// empty file, keeping what the platform copy keeps (NTFS streams, attributes, modified time).
/// If the copy fails, the file we claimed is removed.
// shortcut: between claiming the name and fs::copy another program could write into the empty file and
// get overwritten; close it with a handle-based copy (CopyFile2 on the open handle) if that race matters.
fn copy_file(src: &Path, dst: &Path, reserved: bool) -> io::Result<u64> {
    if !reserved {
        fs::OpenOptions::new().write(true).create_new(true).open(dst)?;
    }
    fs::copy(src, dst).inspect_err(|_| {
        let _ = fs::remove_file(dst);
    })
}

fn copy_dir(src: &Path, dst: &Path, reserved: bool, ancestors: &mut Vec<PathBuf>, report: &mut CopyReport) -> io::Result<()> {
    let real = fs::canonicalize(src)?;
    if ancestors.contains(&real) {
        // 링크를 따라가지 않으므로 생기지 않지만, 생기면 순환이다. 건너뛰고 남긴다.
        report.skipped_links.push(src.to_path_buf());
        return Ok(());
    }
    ancestors.push(real);
    if !reserved {
        fs::create_dir(dst)?;
    }
    report.dirs += 1;
    for entry in fs::read_dir(src)? {
        let entry = entry?;
        let path = entry.path();
        let to = dst.join(entry.file_name());
        if is_reparse(&path) {
            report.skipped_links.push(path);
            continue;
        }
        if fs::metadata(&path)?.is_dir() {
            copy_dir(&path, &to, false, ancestors, report)?;
        } else {
            report.bytes += copy_file(&path, &to, false)?;
            report.files += 1;
        }
    }
    ancestors.pop();
    Ok(())
}

/// 트리 요약(따라가지 않음): (파일 수, 폴더 수, 바이트, 재분석 지점 수). 다른 볼륨 이동의 복사 완료 확인에 쓴다.
pub fn tree_summary(path: &Path) -> io::Result<(u64, u64, u64, u64)> {
    let meta = fs::symlink_metadata(path)?;
    if meta.file_type().is_symlink() {
        return Ok((0, 0, 0, 1));
    }
    if !meta.is_dir() {
        return Ok((1, 0, meta.len(), 0));
    }
    let mut acc = (0, 1, 0, 0);
    for entry in fs::read_dir(path)? {
        let (f, d, b, l) = tree_summary(&entry?.path())?;
        acc = (acc.0 + f, acc.1 + d, acc.2 + b, acc.3 + l);
    }
    Ok(acc)
}

/// 다른 볼륨으로 옮기기를 시작 전에 거부한 이유(D-044 ②).
pub const MOVE_REFUSED_LINKS: &str = "contains links";

/// Claims the top-level copy target (`create_new` file or new folder, never an existing one) so it can be filled
/// later without holding any lock. A source link creates nothing (`copy_reserved` then skips it).
/// A folder copied into itself is refused here, before anything is created.
pub fn reserve_copy_target(src: &Path, dst: &Path) -> io::Result<()> {
    if is_reparse(src) {
        return Ok(());
    }
    if fs::metadata(src)?.is_dir() {
        if is_within_real(dst, src) {
            return Err(into_itself("copy"));
        }
        fs::create_dir(dst)
    } else {
        fs::OpenOptions::new().write(true).create_new(true).open(dst).map(|_| ())
    }
}

/// What `move_or_reserve` left to do.
#[derive(Debug, PartialEq, Eq)]
pub enum Moved {
    /// Same-volume rename finished.
    Done,
    /// Other volume: `dst` is claimed; call `finish_reserved_move` (slow part, no lock needed).
    Reserved,
}

/// Moves an entry (replaces the old one-step move_entry): checks, then rename. If the target is on another volume, refuses trees with
/// links and claims `dst` instead of copying, so the caller can hold a lock only for this short step.
pub fn move_or_reserve(src: &Path, dst: &Path) -> io::Result<Moved> {
    move_checks(src, dst)?;
    match fs::rename(src, dst) {
        Ok(()) => Ok(Moved::Done),
        Err(e) if e.raw_os_error() == Some(17) => {
            if tree_summary(src)?.3 > 0 {
                return Err(io::Error::new(io::ErrorKind::Unsupported, MOVE_REFUSED_LINKS));
            }
            reserve_copy_target(src, dst)?;
            Ok(Moved::Reserved)
        }
        Err(e) => Err(e),
    }
}

/// Slow second half after `Moved::Reserved`: copy into the claimed `dst`, verify, delete the source.
pub fn finish_reserved_move(src: &Path, dst: &Path) -> io::Result<()> {
    move_verified_with(src, dst, true, || {})
}

fn move_checks(src: &Path, dst: &Path) -> io::Result<()> {
    if fs::metadata(src).is_ok_and(|m| m.is_dir()) && is_within_real(dst, src) {
        return Err(into_itself("move"));
    }
    if is_within(dst, src) {
        return Err(io::Error::new(io::ErrorKind::InvalidInput, "cannot move a folder into itself"));
    }
    Ok(())
}

/// Sorted (relative path, is_dir, len, modified) list of a tree, not following links.
type Snapshot = Vec<(PathBuf, bool, u64, Option<std::time::SystemTime>)>;

fn snapshot(root: &Path) -> io::Result<Snapshot> {
    fn walk(root: &Path, dir: &Path, out: &mut Snapshot) -> io::Result<()> {
        for entry in fs::read_dir(dir)? {
            let path = entry?.path();
            let meta = fs::symlink_metadata(&path)?;
            let rel = path.strip_prefix(root).unwrap_or(&path).to_path_buf();
            out.push((rel, meta.is_dir(), if meta.is_dir() { 0 } else { meta.len() }, meta.modified().ok()));
            if meta.is_dir() {
                walk(root, &path, out)?;
            }
        }
        Ok(())
    }
    let meta = fs::symlink_metadata(root)?;
    let mut out = vec![(PathBuf::new(), meta.is_dir(), if meta.is_dir() { 0 } else { meta.len() }, meta.modified().ok())];
    if meta.is_dir() {
        walk(root, root, &mut out)?;
    }
    out.sort();
    Ok(out)
}

// shortcut: the source is compared once right before delete(); a change between that check and the
// delete still loses data. Close it with a lock/handle-based delete if that race matters.
/// ERROR_NOT_SAME_DEVICE: 다른 볼륨으로 옮기기(D-044 ②).
/// - 원본 트리에 재분석 지점이 있으면 시작 전에 거부한다(원본·대상 모두 바꾸지 않는다).
/// - 복사한 뒤 원본·대상의 파일 수·폴더 수·바이트가 같을 때만 원본을 지운다. 다르면 원본을 두고 오류.
/// - 삭제 직전 원본의 목록·크기·수정 시각이 복사 전과 다르면 원본을 지우지 않고 오류(복사본은 남긴다).
fn move_verified_with(src: &Path, dst: &Path, reserved: bool, after_copy: impl FnOnce()) -> io::Result<()> {
    let pre = tree_summary(src).and_then(|before| snapshot(src).map(|snap| (before, snap)));
    let (before, snap) = match pre {
        Ok(v) if v.0.3 == 0 => v,
        other => {
            if reserved {
                // Nothing was copied yet: release the claimed (still empty) target.
                let _ = fs::remove_file(dst).or_else(|_| fs::remove_dir(dst));
            }
            return Err(other.err().unwrap_or_else(|| io::Error::new(io::ErrorKind::Unsupported, MOVE_REFUSED_LINKS)));
        }
    };
    let report = copy_entry_with(src, dst, reserved)?;
    after_copy();
    let after = tree_summary(dst)?;
    let copied_ok = report.skipped_links.is_empty() && (after.0, after.1, after.2) == (before.0, before.1, before.2);
    if !copied_ok {
        return Err(io::Error::other(format!(
            "copy incomplete (source {}/{}/{} vs copy {}/{}/{}); source kept",
            before.0, before.1, before.2, after.0, after.1, after.2
        )));
    }
    if snapshot(src)? != snap {
        return Err(io::Error::other("source changed during move; source and copy kept"));
    }
    delete(src)
}

/// 영구 삭제(A-14.3 "지운다").
pub fn delete(path: &Path) -> io::Result<()> {
    if fs::symlink_metadata(path)?.is_dir() {
        fs::remove_dir_all(path)
    } else {
        fs::remove_file(path)
    }
}

/// 휴지통으로 옮긴다(A-14.3, D-6 `trash`).
pub fn trash(path: &Path) -> Result<(), String> {
    trash::delete(path).map_err(|e| e.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn paste_names_and_copy() {
        let dir = std::env::temp_dir().join(format!("wg-ops-{}", std::process::id()));
        let _ = fs::remove_dir_all(&dir);
        fs::create_dir_all(dir.join("sub")).unwrap();
        fs::write(dir.join("a.txt"), b"x").unwrap();
        assert_eq!(paste_path(&dir, "new.txt", false), dir.join("new.txt"));
        assert_eq!(paste_path(&dir, "a.txt", false), dir.join("a copy.txt"));
        fs::write(dir.join("a copy.txt"), b"").unwrap();
        assert_eq!(paste_path(&dir, "a.txt", false), dir.join("a copy 1.txt"));
        assert_eq!(paste_path(&dir, "sub", true), dir.join("sub copy"));
        fs::write(dir.join("sub").join("f.md"), b"m").unwrap();
        copy_entry(&dir.join("sub"), &dir.join("sub2")).unwrap();
        assert_eq!(fs::read(dir.join("sub2").join("f.md")).unwrap(), b"m");
        assert!(copy_entry(&dir.join("sub"), &dir.join("sub").join("inner")).is_err());
        assert!(move_or_reserve(&dir.join("sub"), &dir.join("sub").join("inner")).is_err());
        assert!(is_within(&dir.join("SUB").join("x"), &dir.join("sub")));
        assert!(!is_within(&dir.join("sub2"), &dir.join("sub")));
        create_file(&dir.join("n1").join("n2").join("z.rs")).unwrap();
        assert!(create_file(&dir.join("n1").join("n2").join("z.rs")).is_err());
        delete(&dir.join("n1")).unwrap();
        assert!(!dir.join("n1").exists());
        fs::remove_dir_all(&dir).unwrap();
    }

    #[test]
    fn copy_keeps_existing_destination() {
        let dir = std::env::temp_dir().join(format!("wg-d1-{}", std::process::id()));
        let _ = fs::remove_dir_all(&dir);
        fs::create_dir_all(&dir).unwrap();
        fs::write(dir.join("a.txt"), b"new").unwrap();
        fs::write(dir.join("b.txt"), b"old").unwrap();
        let e = copy_entry(&dir.join("a.txt"), &dir.join("b.txt")).unwrap_err();
        assert_eq!(e.kind(), io::ErrorKind::AlreadyExists);
        assert_eq!(fs::read(dir.join("b.txt")).unwrap(), b"old");
        fs::remove_dir_all(&dir).unwrap();
    }

    #[test]
    fn copy_keeps_streams_and_mtime() {
        let dir = std::env::temp_dir().join(format!("wg-ads-{}", std::process::id()));
        let _ = fs::remove_dir_all(&dir);
        fs::create_dir_all(&dir).unwrap();
        let a = dir.join("a.txt");
        fs::write(&a, b"body").unwrap();
        fs::write(dir.join("a.txt:notes"), b"note").unwrap();
        fs::File::options().write(true).open(&a).unwrap().set_modified(std::time::UNIX_EPOCH + std::time::Duration::from_secs(1_000_000_000)).unwrap();
        copy_entry(&a, &dir.join("b.txt")).unwrap();
        assert_eq!(fs::read(dir.join("b.txt")).unwrap(), b"body");
        assert_eq!(fs::read(dir.join("b.txt:notes")).unwrap(), b"note");
        assert_eq!(fs::metadata(&a).unwrap().modified().unwrap(), fs::metadata(dir.join("b.txt")).unwrap().modified().unwrap());
        fs::remove_dir_all(&dir).unwrap();
    }
}

#[cfg(test)]
mod d044_tests {
    use super::*;

    #[test]
    fn d044_copy_report_and_verified_move() {
        let dir = std::env::temp_dir().join(format!("wg-d044-{}", std::process::id()));
        let _ = fs::remove_dir_all(&dir);
        fs::create_dir_all(dir.join("src").join("deep")).unwrap();
        fs::write(dir.join("src").join("a.txt"), b"abc").unwrap();
        fs::write(dir.join("src").join("deep").join("b.txt"), b"12345").unwrap();
        assert_eq!(tree_summary(&dir.join("src")).unwrap(), (2, 2, 8, 0));
        let r = copy_entry(&dir.join("src"), &dir.join("copy")).unwrap();
        assert_eq!((r.files, r.dirs, r.bytes, r.skipped_links.len()), (2, 2, 8, 0));
        // 같은 볼륨에서도 move_verified_with 는 복사 → 확인 → 원본 삭제 순서다.
        move_verified_with(&dir.join("copy"), &dir.join("moved"), false, || {}).unwrap();
        assert!(!dir.join("copy").exists());
        assert_eq!(tree_summary(&dir.join("moved")).unwrap(), (2, 2, 8, 0));
        // source changed after the copy: source stays, copy stays, error returned
        let changed = || fs::write(dir.join("moved").join("a.txt"), b"abcd").unwrap();
        assert!(move_verified_with(&dir.join("moved"), &dir.join("moved2"), false, changed).is_err());
        assert!(dir.join("moved").join("a.txt").exists() && dir.join("moved2").exists());
        fs::remove_dir_all(&dir).unwrap();
    }

    #[test]
    fn reserve_claims_without_replacing_and_move_or_reserve_renames() {
        let dir = std::env::temp_dir().join(format!("wg-ops-res-{}", std::process::id()));
        let _ = fs::remove_dir_all(&dir);
        fs::create_dir_all(dir.join("sub")).unwrap();
        fs::write(dir.join("a.txt"), b"a").unwrap();
        reserve_copy_target(&dir.join("a.txt"), &dir.join("b.txt")).unwrap();
        assert!(reserve_copy_target(&dir.join("a.txt"), &dir.join("b.txt")).is_err());
        assert!(reserve_copy_target(&dir.join("missing"), &dir.join("c.txt")).is_err() && !dir.join("c.txt").exists());
        assert!(reserve_copy_target(&dir.join("sub"), &dir.join("sub").join("in")).is_err() && !dir.join("sub").join("in").exists());
        assert_eq!(move_or_reserve(&dir.join("a.txt"), &dir.join("d.txt")).unwrap(), Moved::Done);
        assert!(dir.join("d.txt").exists() && !dir.join("a.txt").exists());
        let _ = fs::remove_dir_all(&dir);
    }
}

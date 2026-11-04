//! 폴더 정체 확인·경로 모양 (v0.2 Phase 5 리뷰 1회차 ③④, D-046). gpui 와 무관하다.
//!
//! - `dir_id`: 볼륨 일련번호 + 파일 번호(GetFileInformationByHandle). 같은 경로에 새 폴더가 들어서면 값이 바뀐다.
//! - `plain`: `fs::canonicalize` 가 붙이는 `\\?\` 접두사를 뗀다(감시 이벤트 경로와 같은 모양으로 비교하려고).

use std::os::windows::fs::OpenOptionsExt as _;
use std::os::windows::io::AsRawHandle as _;
use std::path::{Path, PathBuf};

/// 폴더 정체: (볼륨 일련번호, 파일 번호).
pub type DirId = (u32, u64);

#[repr(C)]
#[derive(Default)]
struct FileTime {
    low: u32,
    high: u32,
}

#[repr(C)]
#[derive(Default)]
struct ByHandleFileInformation {
    attributes: u32,
    creation: FileTime,
    access: FileTime,
    write: FileTime,
    volume_serial: u32,
    size_high: u32,
    size_low: u32,
    links: u32,
    index_high: u32,
    index_low: u32,
}

#[link(name = "kernel32")]
unsafe extern "system" {
    fn GetFileInformationByHandle(file: *mut std::ffi::c_void, info: *mut ByHandleFileInformation) -> i32;
}

/// FILE_FLAG_BACKUP_SEMANTICS: 폴더를 열 때 필요하다.
const BACKUP_SEMANTICS: u32 = 0x0200_0000;

/// 폴더 정체를 읽는다. 열지 못하면 None. 핸들은 곧바로 닫는다(공유: 읽기·쓰기·지우기 모두 허용, std 기본값).
pub fn dir_id(path: &Path) -> Option<DirId> {
    let file = std::fs::OpenOptions::new()
        .read(true)
        .custom_flags(BACKUP_SEMANTICS)
        .open(path)
        .ok()?;
    let mut info = ByHandleFileInformation::default();
    // SAFETY: 핸들은 `file` 이 살아 있는 동안 유효하고, info 는 Win32 BY_HANDLE_FILE_INFORMATION 과 같은 배치다.
    let ok = unsafe { GetFileInformationByHandle(file.as_raw_handle(), &mut info) };
    (ok != 0).then_some((info.volume_serial, ((info.index_high as u64) << 32) | info.index_low as u64))
}

/// `\\?\C:\a` → `C:\a`, `\\?\UNC\srv\s` → `\\srv\s`. 그 밖은 그대로.
pub fn plain(path: &Path) -> PathBuf {
    let s = path.to_string_lossy();
    if let Some(rest) = s.strip_prefix(r"\\?\UNC\") {
        PathBuf::from(format!(r"\\{rest}"))
    } else if let Some(rest) = s.strip_prefix(r"\\?\") {
        PathBuf::from(rest)
    } else {
        path.to_path_buf()
    }
}

/// 대소문자를 무시한 경로 접두 비교(Windows): `path` 가 `base` 이거나 그 아래인가.
pub fn starts_with_ci(path: &Path, base: &Path) -> bool {
    let p = path.to_string_lossy().to_lowercase();
    let b = base.to_string_lossy().to_lowercase();
    let b = b.trim_end_matches('\\');
    p == b || (p.starts_with(b) && p[b.len()..].starts_with('\\'))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn d046_plain_and_prefix() {
        assert_eq!(plain(Path::new(r"\\?\D:\a\b")), PathBuf::from(r"D:\a\b"));
        assert_eq!(plain(Path::new(r"\\?\UNC\srv\s\x")), PathBuf::from(r"\\srv\s\x"));
        assert_eq!(plain(Path::new(r"D:\a")), PathBuf::from(r"D:\a"));
        assert!(starts_with_ci(Path::new(r"D:\Proj\x.txt"), Path::new(r"d:\proj")));
        assert!(starts_with_ci(Path::new(r"D:\Proj"), Path::new(r"d:\proj\")));
        assert!(!starts_with_ci(Path::new(r"D:\Project\x"), Path::new(r"D:\Proj")));
    }

    #[test]
    fn d046_dir_id_changes_with_new_folder() {
        let base = std::env::temp_dir().join(format!("wg-d046-ident-{}", std::process::id()));
        let a = base.join("a");
        std::fs::create_dir_all(&a).unwrap();
        let first = dir_id(&a).expect("id");
        assert_eq!(dir_id(&a), Some(first));
        std::fs::rename(&a, base.join("a-old")).unwrap();
        std::fs::create_dir(&a).unwrap();
        let second = dir_id(&a).expect("id");
        assert_ne!(first, second);
        assert_eq!(dir_id(&base.join("a-old")), Some(first));
        assert_eq!(dir_id(&base.join("none")), None);
        std::fs::remove_dir_all(&base).unwrap();
    }
}

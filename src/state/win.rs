//! state.json 에 쓰는 Win32 호출 (DECISIONS D-10 이후 변경, D-035 ③). 새 크레이트 없이 FFI 로 부른다.
//!
//! - `CoCreateGuid`(ole32): `folders[].id` 의 UUID v4(A-22.3).
//! - `ReplaceFileW`·`MoveFileExW`(kernel32): `.tmp` 를 `state.json` 자리에 놓는다(A-24.1).

use std::os::windows::ffi::OsStrExt;
use std::path::Path;

#[repr(C)]
#[derive(Default)]
struct Guid {
    data1: u32,
    data2: u16,
    data3: u16,
    data4: [u8; 8],
}

#[link(name = "ole32")]
unsafe extern "system" {
    fn CoCreateGuid(guid: *mut Guid) -> i32;
}

const MOVEFILE_REPLACE_EXISTING: u32 = 0x1;
const MOVEFILE_WRITE_THROUGH: u32 = 0x8;

#[link(name = "kernel32")]
unsafe extern "system" {
    fn ReplaceFileW(
        replaced: *const u16,
        replacement: *const u16,
        backup: *const u16,
        flags: u32,
        exclude: *mut core::ffi::c_void,
        reserved: *mut core::ffi::c_void,
    ) -> i32;
    fn MoveFileExW(existing: *const u16, new: *const u16, flags: u32) -> i32;
}

fn wide(p: &Path) -> Vec<u16> {
    p.as_os_str().encode_wide().chain(std::iter::once(0)).collect()
}

/// UUID v4 문자열(소문자, 하이픈). `CoCreateGuid` 는 RFC 4122 버전 4 GUID 를 만든다.
pub fn new_uuid() -> String {
    let mut g = Guid::default();
    // SAFETY: g 는 올바른 Guid 를 가리킨다.
    let hr = unsafe { CoCreateGuid(&mut g) };
    assert!(hr >= 0, "CoCreateGuid failed: {hr:#x}");
    format!(
        "{:08x}-{:04x}-{:04x}-{:02x}{:02x}-{:02x}{:02x}{:02x}{:02x}{:02x}{:02x}",
        g.data1,
        g.data2,
        g.data3,
        g.data4[0],
        g.data4[1],
        g.data4[2],
        g.data4[3],
        g.data4[4],
        g.data4[5],
        g.data4[6],
        g.data4[7]
    )
}

/// `tmp` 를 `target` 자리에 놓는다. target 이 있으면 `ReplaceFileW`, 없으면 `MoveFileExW`
/// (`MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH`). 실패하면 OS 오류.
pub fn replace_file(tmp: &Path, target: &Path) -> std::io::Result<()> {
    let t = wide(target);
    let s = wide(tmp);
    // SAFETY: 두 버퍼는 NUL 로 끝나는 UTF-16 경로다.
    let ok = unsafe {
        if target.exists() {
            ReplaceFileW(
                t.as_ptr(),
                s.as_ptr(),
                std::ptr::null(),
                0,
                std::ptr::null_mut(),
                std::ptr::null_mut(),
            )
        } else {
            MoveFileExW(
                s.as_ptr(),
                t.as_ptr(),
                MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH,
            )
        }
    };
    if ok == 0 {
        Err(std::io::Error::last_os_error())
    } else {
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn uuid_v4_shape() {
        let a = new_uuid();
        let b = new_uuid();
        assert_ne!(a, b);
        assert_eq!(a.len(), 36);
        let parts: Vec<&str> = a.split('-').collect();
        assert_eq!(parts.iter().map(|p| p.len()).collect::<Vec<_>>(), [8, 4, 4, 4, 12]);
        assert!(parts[2].starts_with('4'), "version 4: {a}");
        assert!(matches!(parts[3].chars().next(), Some('8' | '9' | 'a' | 'b')), "variant: {a}");
    }
}

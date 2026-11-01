//! 탐색기·기본 앱 열기 (I-532 Reveal in File Explorer, I-533 Open in Default App). 새 크레이트 없이 부른다.

use std::os::windows::process::CommandExt as _;
use std::path::Path;

/// 인자를 그대로(따옴표 포함) 넘겨 실행한다. 기다리지 않는다.
pub fn spawn_raw(program: &str, raw_arg: &str) {
    let _ = std::process::Command::new(program).raw_arg(raw_arg).spawn();
}

#[link(name = "shell32")]
unsafe extern "system" {
    fn ShellExecuteW(
        hwnd: isize,
        operation: *const u16,
        file: *const u16,
        parameters: *const u16,
        directory: *const u16,
        show: i32,
    ) -> isize;
}

const SW_SHOWNORMAL: i32 = 1;

/// 기본 앱으로 연다(ShellExecuteW "open").
pub fn open_default(path: &Path) {
    use std::os::windows::ffi::OsStrExt as _;
    let op: Vec<u16> = "open".encode_utf16().chain(std::iter::once(0)).collect();
    let file: Vec<u16> = path.as_os_str().encode_wide().chain(std::iter::once(0)).collect();
    unsafe {
        ShellExecuteW(0, op.as_ptr(), file.as_ptr(), std::ptr::null(), std::ptr::null(), SW_SHOWNORMAL);
    }
}

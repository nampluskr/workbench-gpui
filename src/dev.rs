//! R-5 (02-gpui G-128) 시험용 숨은 개발 플래그. 사용자에게 보이는 기능이 아니다.
//!
//! - `--dev-taskdialog`: 창이 뜬 뒤 TaskDialog 를 한 번 띄운다. TaskDialog 는 Common Controls v6
//!   에만 있으므로, 매니페스트에 v6 의존성이 없으면 comctl32.dll 에서 함수를 찾지 못한다.
//!   정적 링크하면 그 경우 앱이 시작조차 못 하므로 LoadLibraryW·GetProcAddress 로 실행 중에 찾는다.
//! - `--dev-open-longpath <path>`: `\\?\` 접두사 없이 CreateFileW 로 경로를 연다. Rust 표준
//!   라이브러리는 긴 경로에 접두사를 스스로 붙이므로(std::fs) 매니페스트 `longPathAware` 효과를
//!   보려면 Win32 API 를 직접 불러야 한다. `RtlAreLongPathsEnabled` 값도 함께 낸다.
//!
//! 결과는 표준출력에 `[dev] ...` 한 줄씩 낸다. 새 크레이트 없이 Win32 FFI 로만 부른다.

#[derive(Debug, Default, Clone)]
pub struct DevOptions {
    pub task_dialog: bool,
    pub long_path: Option<String>,
}

impl DevOptions {
    /// 디버그 빌드에서만 명령줄을 읽는다. 릴리스 빌드(debug_assertions 꺼짐)에서는 플래그를
    /// 주어도 항상 꺼진 값을 돌려주므로 시험 기능이 동작하지 않는다.
    pub fn from_args() -> Self {
        let mut options = Self::default();
        if !cfg!(debug_assertions) {
            return options;
        }
        let mut args = std::env::args().skip(1);
        while let Some(arg) = args.next() {
            match arg.as_str() {
                "--dev-taskdialog" => options.task_dialog = true,
                "--dev-open-longpath" => options.long_path = args.next(),
                _ => {}
            }
        }
        options
    }

    pub fn is_active(&self) -> bool {
        self.task_dialog || self.long_path.is_some()
    }
}

pub fn run_checks(options: &DevOptions) {
    if let Some(path) = &options.long_path {
        open_long_path(path);
    }
    if options.task_dialog {
        task_dialog();
    }
}

#[cfg(windows)]
mod win {
    use std::ffi::c_void;

    pub type Handle = *mut c_void;
    pub const INVALID_HANDLE_VALUE: Handle = -1isize as Handle;
    pub const GENERIC_READ: u32 = 0x8000_0000;
    pub const FILE_SHARE_ALL: u32 = 0x1 | 0x2 | 0x4;
    pub const OPEN_EXISTING: u32 = 3;
    /// 폴더도 열 수 있게 한다.
    pub const FILE_FLAG_BACKUP_SEMANTICS: u32 = 0x0200_0000;
    pub const TDCBF_OK_BUTTON: i32 = 0x1;
    pub const TDCBF_CANCEL_BUTTON: i32 = 0x8;

    pub type TaskDialogFn = unsafe extern "system" fn(
        hwnd_owner: Handle,
        instance: Handle,
        window_title: *const u16,
        main_instruction: *const u16,
        content: *const u16,
        common_buttons: i32,
        icon: *const u16,
        button: *mut i32,
    ) -> i32;

    #[link(name = "kernel32")]
    unsafe extern "system" {
        pub fn LoadLibraryW(name: *const u16) -> Handle;
        pub fn GetProcAddress(module: Handle, name: *const u8) -> *mut c_void;
        pub fn CreateFileW(
            name: *const u16,
            access: u32,
            share: u32,
            security: *mut c_void,
            disposition: u32,
            flags: u32,
            template: Handle,
        ) -> Handle;
        pub fn CloseHandle(handle: Handle) -> i32;
        pub fn GetLastError() -> u32;
        pub fn GetModuleHandleW(name: *const u16) -> Handle;
        pub fn FreeLibrary(module: Handle) -> i32;
    }

    /// LoadLibraryW 로 얻은 모듈. 버려질 때 FreeLibrary 를 부른다.
    pub struct Library(pub Handle);

    impl Drop for Library {
        fn drop(&mut self) {
            if !self.0.is_null() {
                unsafe { FreeLibrary(self.0) };
            }
        }
    }

    #[link(name = "user32")]
    unsafe extern "system" {
        pub fn GetActiveWindow() -> Handle;
    }

    /// ntdll 의 `RtlAreLongPathsEnabled` 는 SDK 의 ntdll.lib 가 내보내지 않아(LNK2019) 정적으로
    /// 링크할 수 없다. 이미 올라와 있는 ntdll.dll 에서 GetProcAddress 로 찾는다.
    /// 찾지 못하면 None 이다.
    pub fn rtl_are_long_paths_enabled() -> Option<bool> {
        type RtlAreLongPathsEnabledFn = unsafe extern "system" fn() -> u8;
        let module = unsafe { GetModuleHandleW(wide("ntdll.dll").as_ptr()) };
        if module.is_null() {
            return None;
        }
        let proc = unsafe { GetProcAddress(module, c"RtlAreLongPathsEnabled".as_ptr().cast()) };
        if proc.is_null() {
            return None;
        }
        let f: RtlAreLongPathsEnabledFn = unsafe { std::mem::transmute(proc) };
        Some(unsafe { f() } != 0)
    }

    pub fn wide(s: &str) -> Vec<u16> {
        s.encode_utf16().chain(std::iter::once(0)).collect()
    }
}

#[cfg(windows)]
fn open_long_path(path: &str) {
    use win::*;

    let path_w = wide(path);
    let len = path_w.len() - 1;
    let enabled = match rtl_are_long_paths_enabled() {
        Some(true) => "true",
        Some(false) => "false",
        None => "unknown",
    };
    let handle = unsafe {
        CreateFileW(
            path_w.as_ptr(),
            GENERIC_READ,
            FILE_SHARE_ALL,
            std::ptr::null_mut(),
            OPEN_EXISTING,
            FILE_FLAG_BACKUP_SEMANTICS,
            std::ptr::null_mut(),
        )
    };
    if handle == INVALID_HANDLE_VALUE {
        let error = unsafe { GetLastError() };
        println!(
            "[dev] longpath utf16_len={len} rtl_long_paths_enabled={enabled} result=error win32_error={error}"
        );
    } else {
        unsafe { CloseHandle(handle) };
        println!("[dev] longpath utf16_len={len} rtl_long_paths_enabled={enabled} result=ok");
    }
}

#[cfg(windows)]
fn task_dialog() {
    use win::*;

    let module = unsafe { LoadLibraryW(wide("comctl32.dll").as_ptr()) };
    if module.is_null() {
        let error = unsafe { GetLastError() };
        println!("[dev] taskdialog result=error step=LoadLibraryW win32_error={error}");
        return;
    }
    // 이 함수를 빠져나가는 모든 경로에서 FreeLibrary 를 부른다.
    let _module = Library(module);
    let proc = unsafe { GetProcAddress(module, c"TaskDialog".as_ptr().cast()) };
    if proc.is_null() {
        println!(
            "[dev] taskdialog result=error step=GetProcAddress detail=TaskDialog not exported (Common Controls v6 not active)"
        );
        return;
    }
    let task_dialog: TaskDialogFn = unsafe { std::mem::transmute(proc) };

    let title = wide("workbench-gpui");
    let instruction = wide("TaskDialog test (R-5, G-128)");
    let content = wide("Common Controls v6 is active if this dialog is shown.");
    let mut button = 0i32;
    let owner = unsafe { GetActiveWindow() };
    let hr = unsafe {
        task_dialog(
            owner,
            std::ptr::null_mut(),
            title.as_ptr(),
            instruction.as_ptr(),
            content.as_ptr(),
            TDCBF_OK_BUTTON | TDCBF_CANCEL_BUTTON,
            std::ptr::null(),
            &mut button,
        )
    };
    println!(
        "[dev] taskdialog result={} hresult=0x{:08X} button={button} owner_is_null={}",
        if hr >= 0 { "ok" } else { "error" },
        hr as u32,
        owner.is_null()
    );
}

#[cfg(not(windows))]
fn open_long_path(_path: &str) {
    println!("[dev] longpath result=unsupported");
}

#[cfg(not(windows))]
fn task_dialog() {
    println!("[dev] taskdialog result=unsupported");
}

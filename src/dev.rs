//! R-5 (02-gpui G-128) 시험용 숨은 개발 플래그. 사용자에게 보이는 기능이 아니다.
//!
//! - `--dev-taskdialog`: 창이 뜬 뒤 TaskDialog 를 한 번 띄운다. TaskDialog 는 Common Controls v6
//!   에만 있으므로, 매니페스트에 v6 의존성이 없으면 comctl32.dll 에서 함수를 찾지 못한다.
//!   정적 링크하면 그 경우 앱이 시작조차 못 하므로 LoadLibraryW·GetProcAddress 로 실행 중에 찾는다.
//! - `--dev-open-longpath <path>`: `\\?\` 접두사 없이 CreateFileW 로 경로를 연다. Rust 표준
//!   라이브러리는 긴 경로에 접두사를 스스로 붙이므로(std::fs) 매니페스트 `longPathAware` 효과를
//!   보려면 Win32 API 를 직접 불러야 한다. `RtlAreLongPathsEnabled` 값도 함께 낸다.
//!
//!
//! Phase 2 (편집기 PoC, SPEC R-6~R-11) 플래그. 화면은 `ui::editor_poc` 가 그린다.
//! - `--dev-editor-poc`: 본문에 gpui-kit Input(한 줄)과 Editor(여러 줄) PoC 를 띄운다.
//! - `--dev-poc-file <path>`: Editor 에 파일을 연다(인코딩은 `--dev-roundtrip-mode` 규칙으로 읽는다).
//! - `--dev-no-wrap`: Editor 의 soft wrap 을 끈다(gpui-base 기본값은 켜짐).
//! - `--dev-perf`: 파일을 연 뒤 열기·스크롤·입력 후 다음 프레임까지의 시간을 잰다 (R-8).
//! - `--dev-roundtrip-out <path>`: 연 파일을 Editor 값으로 되읽어 저장한다 (R-9).
//! - `--dev-roundtrip-mode <naive|app>`: naive = UTF-8 로 읽고(손실 허용) UTF-8 로 쓴다.
//!   app = BOM·UTF-8 유효성으로 인코딩을 고르고(UTF-8, UTF-8 BOM, UTF-16 LE/BE, 그 밖은 CP949)
//!   같은 인코딩으로 다시 쓴다. CP949 는 Win32 MultiByteToWideChar/WideCharToMultiByte(코드 페이지 949).
//! - `--dev-measure`: 한글 혼합 줄과 영문 줄의 줄 높이·폭·거터·커서 위치를 낸다 (R-10).
//! - `--dev-pick-folder <파일>`: 폴더 선택 창 대신 파일에 적힌 경로를 고른 것으로 한다 (v0.2 Phase 3, R-10).
//! - Editor·Input 값이 바뀔 때마다 `[dev] value ...` 를 낸다 (R-6 IME 결과 확인용).
//! - `--dev-no-shell`: Reveal in File Explorer·Open in Default App 을 실행하지 않고 기록만 한다 (v0.2 Phase 4, R-22).
//! - `--dev-trash <list|restore|purge> <폴더>`: 휴지통에서 원래 위치가 그 폴더 아래인 항목만 보이거나 되살리거나 비운다.
//!   창을 띄우지 않고 끝난다. 시험이 버린 항목만 다루려고 둔다 (v0.2 Phase 4, R-20).
//! - `--dev-slow-io <경로 조각> <ms>`: 감시 쪽 존재 확인·탭 파일 다시 읽기를 늦춘다(v0.2 Phase 5 리뷰 1회차 ⑤, D-046).
//! - `--dev-ui-stall <이름> <ms>`: 이름이 같은 지점(인라인 입력 확정 `edit-committed`·취소 `edit-cancelled`)에서 UI 스레드를
//!   멈춘다. 파일 작업 직후 `fs-<op>`(예: `fs-create`)도 있다(v0.2 Phase 5 리뷰 2회차, D-047).

#[derive(Debug, Default, Clone)]
pub struct DevOptions {
    pub task_dialog: bool,
    pub long_path: Option<String>,
    pub editor_poc: bool,
    pub poc_file: Option<String>,
    pub no_wrap: bool,
    pub perf: bool,
    pub roundtrip_out: Option<String>,
    pub roundtrip_mode: RoundtripMode,
    pub measure: bool,
    /// `--dev-cp949-selftest`: CP949 인코딩이 손실 문자를 오류로 잡는지 표준출력에 낸다 (R-9).
    pub cp949_selftest: bool,
    /// `--dev-layout`: 레이아웃 경계(이름별 바깥 상자)·rem·Dock 폭을 바뀔 때마다 낸다 (Phase 3, R-12~R-15).
    pub layout: bool,
    /// `--dev-keymap`: 키맵 바인딩 전체·표시 문자열·오류·키 입력 결과를 낸다 (v0.2 Phase 1, R-1~R-4).
    pub keymap: bool,
    /// `--dev-keymap-startup-delay <ms>`: 키맵 최초 로드 직후에 이만큼 멈춘다. 그 사이에 바뀐
    /// keymap.json 도 반영되는지 보는 시험용이다 (v0.2 Phase 1 리뷰 1회차 ②).
    pub keymap_startup_delay_ms: Option<u64>,
    /// `--dev-pick-folder <파일>`: 폴더 선택 창 대신 이 파일의 첫 줄을 고른 경로로 쓴다(v0.2 Phase 3, R-10, D-035).
    /// 파일이 없거나 비었거나 `<cancel>` 이면 취소로 본다. 열 때마다 다시 읽는다.
    pub pick_folder_file: Option<String>,
    /// `--dev-trash <list|restore|purge> <폴더>` (v0.2 Phase 4).
    pub trash_cmd: Option<(String, String)>,
}

/// R-9 파일 읽기·쓰기 방식.
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub enum RoundtripMode {
    /// UTF-8 로 읽고(잘못된 바이트는 U+FFFD) UTF-8 로 쓴다. 인코딩 처리를 하지 않았을 때의 결과.
    Naive,
    /// 인코딩을 감지해 같은 인코딩으로 다시 쓴다.
    #[default]
    App,
}

impl RoundtripMode {
    pub fn name(self) -> &'static str {
        match self {
            Self::Naive => "naive",
            Self::App => "app",
        }
    }
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
                "--dev-editor-poc" => options.editor_poc = true,
                "--dev-poc-file" => options.poc_file = args.next(),
                "--dev-no-wrap" => options.no_wrap = true,
                "--dev-perf" => options.perf = true,
                "--dev-roundtrip-out" => options.roundtrip_out = args.next(),
                "--dev-roundtrip-mode" => {
                    options.roundtrip_mode = match args.next().as_deref() {
                        Some("naive") => RoundtripMode::Naive,
                        _ => RoundtripMode::App,
                    }
                }
                "--dev-measure" => options.measure = true,
                "--dev-cp949-selftest" => options.cp949_selftest = true,
                "--dev-layout" => options.layout = true,
                "--dev-layout-json" => {
                    if let Some(path) = args.next() {
                        let _ = LAYOUT_JSON.set(path);
                        options.layout = true;
                    }
                }
                "--dev-keymap" => options.keymap = true,
                "--dev-keymap-startup-delay" => {
                    options.keymap_startup_delay_ms = args.next().and_then(|v| v.parse().ok())
                }
                "--dev-pick-folder" => options.pick_folder_file = args.next(),
                "--dev-no-shell" => NO_SHELL.store(true, std::sync::atomic::Ordering::Relaxed),
                "--dev-ui-stall" => {
                    let name = args.next().unwrap_or_default();
                    let ms = args.next().and_then(|v| v.parse().ok()).unwrap_or(0);
                    if !name.is_empty() {
                        let _ = UI_STALL.set((name, ms));
                    }
                }
                "--dev-slow-io" => {
                    let part = args.next().unwrap_or_default().to_lowercase();
                    let ms = args.next().and_then(|v| v.parse().ok()).unwrap_or(0);
                    if !part.is_empty() {
                        let _ = SLOW_IO.set((part, ms));
                    }
                }
                "--dev-trash" => {
                    let op = args.next().unwrap_or_default();
                    let dir = args.next().unwrap_or_default();
                    options.trash_cmd = Some((op, dir));
                }
                _ => {}
            }
        }
        // PoC 용 플래그는 PoC 화면이 있어야 의미가 있다.
        if options.poc_file.is_some()
            || options.perf
            || options.measure
            || options.roundtrip_out.is_some()
        {
            options.editor_poc = true;
        }
        options
    }

    /// Phase 1 의 R-5 시험(run_checks)이 켜졌는가.
    pub fn is_active(&self) -> bool {
        self.task_dialog || self.long_path.is_some() || self.cp949_selftest
    }
}

/// CP949 시험 사례: (이름, 글, 손실 없이 옮겨져야 하는가).
pub const CP949_CASES: [(&str, &str, bool); 4] = [
    (
        "korean-crlf",
        "첫째 줄 first line\r\n둘째 줄 second\r\n",
        true,
    ),
    ("ascii-backslash", "C:\\path\\file", true),
    ("won-sign-U+20A9", "가격 \u{20A9}1000", false),
    ("yen-sign-U+00A5", "가격 \u{00A5}1000", false),
];

/// CP949 시험을 돌려 사례마다 `[dev] cp949-selftest ...` 한 줄을 낸다.
fn cp949_selftest() {
    let mut pass = 0;
    for (name, text, lossless) in CP949_CASES {
        let result = encode(text, TextEncoding::Cp949);
        let ok = match (&result, lossless) {
            (Ok(bytes), true) => decode(bytes, RoundtripMode::App)
                .map(|(back, _)| back == text)
                .unwrap_or(false),
            (Err(_), false) => true,
            _ => false,
        };
        if ok {
            pass += 1;
        }
        let expect = if lossless { "ok" } else { "error" };
        match result {
            Ok(bytes) => println!(
                "[dev] cp949-selftest case={name} expect={expect} got=ok bytes={} pass={ok}",
                bytes.len()
            ),
            Err(e) => println!(
                "[dev] cp949-selftest case={name} expect={expect} got=error error={e:?} pass={ok}"
            ),
        }
    }
    println!(
        "[dev] cp949-selftest done pass={pass}/{}",
        CP949_CASES.len()
    );
}

pub use crate::text_io::{TextEncoding, encode};

/// 파일 바이트를 문자열로 바꾼다. 실패하면 이유를 돌려준다. `App` is the app's detection (`text_io::decode`);
/// `Naive` reads UTF-8 lossily, the R-9 baseline without encoding handling.
pub fn decode(bytes: &[u8], mode: RoundtripMode) -> Result<(String, TextEncoding), String> {
    if mode == RoundtripMode::Naive {
        return Ok((String::from_utf8_lossy(bytes).into_owned(), TextEncoding::Utf8));
    }
    crate::text_io::decode(bytes)
}

pub fn run_checks(options: &DevOptions) {
    if let Some(path) = &options.long_path {
        open_long_path(path);
    }
    if options.cp949_selftest {
        cp949_selftest();
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

#[cfg(all(test, windows))]
mod tests {
    use super::*;

    #[test]
    fn cp949_lossless_cases_round_trip() {
        for (name, text, lossless) in CP949_CASES.iter().filter(|c| c.2) {
            let bytes = encode(text, TextEncoding::Cp949).unwrap_or_else(|e| panic!("{name}: {e}"));
            let (back, _) = decode(&bytes, RoundtripMode::App).unwrap();
            assert_eq!(&back, text, "{name} lossless={lossless}");
        }
    }

    #[test]
    fn cp949_rejects_won_sign() {
        let err = encode("가격 \u{20A9}1000", TextEncoding::Cp949).unwrap_err();
        assert!(err.contains("U+20A9"), "{err}");
    }

    #[test]
    fn cp949_rejects_yen_sign() {
        let err = encode("가격 \u{00A5}1000", TextEncoding::Cp949).unwrap_err();
        assert!(err.contains("U+00A5"), "{err}");
    }

    #[test]
    fn cp949_detected_and_written_back_identically() {
        let text = "첫째 줄 first line\r\n";
        let bytes = encode(text, TextEncoding::Cp949).unwrap();
        let (back, encoding) = decode(&bytes, RoundtripMode::App).unwrap();
        assert_eq!(encoding, TextEncoding::Cp949);
        assert_eq!(encode(&back, encoding).unwrap(), bytes);
    }
}

static NO_SHELL: std::sync::atomic::AtomicBool = std::sync::atomic::AtomicBool::new(false);

/// `--dev-no-shell` 이 켜졌는가.
pub fn no_shell() -> bool {
    NO_SHELL.load(std::sync::atomic::Ordering::Relaxed)
}

/// Milliseconds since the Unix epoch for `t_ms=` dev log fields (0 if the clock is before the epoch).
pub fn now_ms() -> u128 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_millis())
        .unwrap_or_default()
}

/// `--dev-slow-io <경로 조각> <ms>` (v0.2 Phase 5 리뷰 1회차 ⑤, D-046): 경로에 조각이 든 폴더 존재 확인·탭 파일 다시 읽기를
/// 이만큼 늦춘다. 응답 없는 네트워크 경로·느린 저장 장치를 흉내 내어 그 일이 메인 스레드를 막는지 본다.
static SLOW_IO: std::sync::OnceLock<(String, u64)> = std::sync::OnceLock::new();

/// `--dev-ui-stall <이름> <ms>` (v0.2 Phase 5 리뷰 2회차, D-047): 이름이 같은 지점에서 UI 스레드를 이만큼 멈춘다.
/// 동기 복사·긴 트리 읽기처럼 UI 가 늦어지는 경우를 흉내 내어 감시 묶음 반영의 순서·만료를 본다.
static UI_STALL: std::sync::OnceLock<(String, u64)> = std::sync::OnceLock::new();

/// `--dev-layout-json <path>` (v0.3 P1-4): also turns on the layout dump and rewrites this file with the
/// latest snapshot as JSON each time it changes. The stdout format of `--dev-layout` is unchanged.
static LAYOUT_JSON: std::sync::OnceLock<String> = std::sync::OnceLock::new();

/// Path given to `--dev-layout-json`, if any.
pub fn layout_json_path() -> Option<&'static str> {
    LAYOUT_JSON.get().map(String::as_str)
}

/// 시험 플래그가 없거나 이름이 다르면 아무것도 하지 않는다.
pub fn ui_stall(name: &str) {
    if let Some((n, ms)) = UI_STALL.get()
        && n == name
    {
        println!("[dev] ui-stall name={name} ms={ms}");
        std::thread::sleep(std::time::Duration::from_millis(*ms));
    }
}

/// 감시 쪽 디스크 일(존재 확인·파일 다시 읽기) 직전에 부른다. 시험 플래그가 없으면 아무것도 하지 않는다.
pub fn slow_io(path: &std::path::Path) {
    if let Some((part, ms)) = SLOW_IO.get()
        && path.to_string_lossy().to_lowercase().contains(part.as_str())
    {
        std::thread::sleep(std::time::Duration::from_millis(*ms));
    }
}

/// `--dev-trash <op> <폴더>`: 원래 위치가 `<폴더>` 아래인 휴지통 항목만 다룬다. 사용자 휴지통의 다른 항목은 건드리지 않는다.
/// 한 줄씩 `[dev] trash-item name=… original_parent=… deleted=…` 를 내고, 끝에 `[dev] trash-done op=… count=…`.
pub fn run_trash_command(op: &str, dir: &str) {
    let base = std::path::PathBuf::from(dir);
    let base_l = base.to_string_lossy().to_lowercase();
    let items = match trash::os_limited::list() {
        Ok(items) => items,
        Err(e) => {
            println!("[dev] trash-done op={op} error={e}");
            return;
        }
    };
    let total = items.len();
    let mine: Vec<trash::TrashItem> = items
        .into_iter()
        .filter(|i| {
            let p = i.original_parent.to_string_lossy().to_lowercase();
            p == base_l || p.starts_with(&format!("{}\\", base_l.trim_end_matches('\\')))
        })
        .collect();
    for i in &mine {
        println!(
            "[dev] trash-item name={} original_parent={} deleted={}",
            i.name.to_string_lossy(),
            i.original_parent.display(),
            i.time_deleted
        );
    }
    let count = mine.len();
    let result = match op {
        "restore" => trash::os_limited::restore_all(mine).map_err(|e| e.to_string()),
        "purge" => trash::os_limited::purge_all(mine).map_err(|e| e.to_string()),
        _ => Ok(()),
    };
    match result {
        Ok(()) => println!("[dev] trash-done op={op} count={count} total={total}"),
        Err(e) => println!("[dev] trash-done op={op} count={count} error={e}"),
    }
}

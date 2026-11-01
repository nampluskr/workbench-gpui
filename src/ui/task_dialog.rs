//! 휴지통·영구 삭제 확인창 (DECISIONS D-12, A-14.7~A-14.9, P-015). Windows TaskDialog 를 새 크레이트 없이 FFI 로 부른다.
//!
//! - 버튼: 확인 버튼(`Trash`·`Delete`)과 `Cancel`. 기본 버튼은 Cancel, Esc 도 Cancel(D-12).
//!   Cancel 은 사용자 정의 버튼에 IDCANCEL 번호를 주고 `TDF_ALLOW_DIALOG_CANCELLATION` 을 켜서 Esc 와 잇는다.
//! - 수준 Info(P-015): 정보 아이콘. 창 제목은 앱 이름이다(판단: 원문에 창 제목 값이 없다).
//! - TaskDialog 는 자체 메시지 루프를 돈다. gpui 를 빌린 채(cx.update 안) 부르면 이벤트 루프와 충돌하므로(v0.1 G-125)
//!   다른 스레드에서 부르고, 부모는 우리 창으로 둔다. gpui 스레드는 그동안 메시지를 계속 처리한다.
//! - `TaskDialogIndirect` 는 Common Controls v6 에만 있다(G-128). 매니페스트는 `tools/apply-manifest.ps1` 이 넣는다.

use std::ffi::c_void;

type Hwnd = isize;
type Pcwstr = *const u16;

#[repr(C, packed(1))]
struct Button {
    id: i32,
    text: Pcwstr,
}

#[repr(C, packed(1))]
struct Config {
    cb_size: u32,
    hwnd_parent: Hwnd,
    h_instance: isize,
    dw_flags: i32,
    dw_common_buttons: i32,
    psz_window_title: Pcwstr,
    psz_main_icon: Pcwstr,
    psz_main_instruction: Pcwstr,
    psz_content: Pcwstr,
    c_buttons: u32,
    p_buttons: *const Button,
    n_default_button: i32,
    c_radio_buttons: u32,
    p_radio_buttons: *const Button,
    n_default_radio_button: i32,
    psz_verification_text: Pcwstr,
    psz_expanded_information: Pcwstr,
    psz_expanded_control_text: Pcwstr,
    psz_collapsed_control_text: Pcwstr,
    psz_footer_icon: Pcwstr,
    psz_footer: Pcwstr,
    pf_callback: *const c_void,
    lp_callback_data: isize,
    cx_width: u32,
}

type TaskDialogIndirectFn =
    unsafe extern "system" fn(*const Config, *mut i32, *mut i32, *mut i32) -> i32;

#[link(name = "kernel32")]
unsafe extern "system" {
    fn LoadLibraryW(name: *const u16) -> *mut c_void;
    fn GetProcAddress(module: *mut c_void, name: *const u8) -> *mut c_void;
}

#[link(name = "user32")]
unsafe extern "system" {
    fn GetActiveWindow() -> *mut c_void;
}

const TDF_ALLOW_DIALOG_CANCELLATION: i32 = 0x0008;
const TDF_POSITION_RELATIVE_TO_WINDOW: i32 = 0x1000;
const IDCANCEL: i32 = 2;
const ID_CONFIRM: i32 = 100;
/// `TD_INFORMATION_ICON` = MAKEINTRESOURCEW(-3).
const TD_INFORMATION_ICON: usize = 0xFFFD;

/// 확인창 내용.
#[derive(Clone, Debug)]
pub struct Prompt {
    pub title: String,
    pub instruction: String,
    pub content: Option<String>,
    pub confirm_label: &'static str,
}

/// 확인창 결과.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Answer {
    Confirm,
    Cancel,
}

/// gpui 스레드에서 부른다: 지금 활성 창(우리 창). 확인창 부모로 쓴다.
pub fn active_window() -> isize {
    unsafe { GetActiveWindow() as isize }
}

fn wide(s: &str) -> Vec<u16> {
    s.encode_utf16().chain(std::iter::once(0)).collect()
}

/// `LoadLibraryW(comctl32)` 를 부른 횟수(리뷰 1회차 ⑥ D-043 확인용).
static LOADS: std::sync::atomic::AtomicUsize = std::sync::atomic::AtomicUsize::new(0);
/// `TaskDialogIndirect` 주소. 프로세스 수명 동안 한 번만 찾는다(모듈 참조를 확인창마다 늘리지 않는다, D-043 ⑥).
static PROC: std::sync::OnceLock<Result<usize, String>> = std::sync::OnceLock::new();

pub fn load_count() -> usize {
    LOADS.load(std::sync::atomic::Ordering::Relaxed)
}

/// comctl32 를 한 번만 올리고 `TaskDialogIndirect` 를 찾는다. 모듈은 프로세스가 끝날 때까지 둔다(의도적 캐시).
fn task_dialog_proc() -> Result<TaskDialogIndirectFn, String> {
    let addr = PROC.get_or_init(|| {
        LOADS.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
        let lib = wide("comctl32.dll");
        let module = unsafe { LoadLibraryW(lib.as_ptr()) };
        if module.is_null() {
            return Err("LoadLibraryW(comctl32) failed".into());
        }
        let proc = unsafe { GetProcAddress(module, c"TaskDialogIndirect".as_ptr().cast()) };
        if proc.is_null() {
            return Err("TaskDialogIndirect not exported (Common Controls v6 not active)".into());
        }
        Ok(proc as usize)
    });
    addr.clone().map(|a| unsafe { std::mem::transmute::<usize, TaskDialogIndirectFn>(a) })
}

/// 확인창을 띄우고 닫힐 때까지 기다린다. gpui 스레드가 아닌 스레드에서 부른다.
pub fn show_blocking(parent: isize, prompt: &Prompt) -> Result<Answer, String> {
    let task_dialog = task_dialog_proc()?;

    let title = wide(&prompt.title);
    let instruction = wide(&prompt.instruction);
    let content = prompt.content.as_deref().map(wide);
    let confirm = wide(prompt.confirm_label);
    let cancel = wide("Cancel");
    // P-015 버튼 순서: 확인 버튼, Cancel.
    let buttons = [
        Button { id: ID_CONFIRM, text: confirm.as_ptr() },
        Button { id: IDCANCEL, text: cancel.as_ptr() },
    ];
    let config = Config {
        cb_size: std::mem::size_of::<Config>() as u32,
        hwnd_parent: parent,
        h_instance: 0,
        dw_flags: TDF_ALLOW_DIALOG_CANCELLATION | TDF_POSITION_RELATIVE_TO_WINDOW,
        dw_common_buttons: 0,
        psz_window_title: title.as_ptr(),
        psz_main_icon: TD_INFORMATION_ICON as Pcwstr,
        psz_main_instruction: instruction.as_ptr(),
        psz_content: content.as_ref().map_or(std::ptr::null(), |c| c.as_ptr()),
        c_buttons: buttons.len() as u32,
        p_buttons: buttons.as_ptr(),
        // D-12: 기본 버튼은 취소.
        n_default_button: IDCANCEL,
        c_radio_buttons: 0,
        p_radio_buttons: std::ptr::null(),
        n_default_radio_button: 0,
        psz_verification_text: std::ptr::null(),
        psz_expanded_information: std::ptr::null(),
        psz_expanded_control_text: std::ptr::null(),
        psz_collapsed_control_text: std::ptr::null(),
        psz_footer_icon: std::ptr::null(),
        psz_footer: std::ptr::null(),
        pf_callback: std::ptr::null(),
        lp_callback_data: 0,
        cx_width: 0,
    };
    let mut pressed = 0i32;
    let hr = unsafe { task_dialog(&config, &mut pressed, std::ptr::null_mut(), std::ptr::null_mut()) };
    if hr < 0 {
        return Err(format!("TaskDialogIndirect hr=0x{:08X}", hr as u32));
    }
    Ok(if pressed == ID_CONFIRM { Answer::Confirm } else { Answer::Cancel })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn config_layout_is_packed_like_commctrl() {
        // commctrl.h 는 TaskDialog 구조체를 pshpack1 로 묶는다. x64: 4+8+8+4+4+8+8+8+8+4+8+4+4+8+4+8*6+8+8+4 = 160.
        assert_eq!(std::mem::size_of::<Config>(), 160);
        assert_eq!(std::mem::size_of::<Button>(), 12);
    }
}

#[cfg(test)]
mod d043_tests {
    use super::*;

    #[test]
    fn d043_comctl32_loaded_once() {
        // 시험 실행 파일에는 v6 매니페스트가 없어 함수 찾기는 실패할 수 있다. 결과와 상관없이 올리기는 한 번이어야 한다.
        for _ in 0..3 {
            let _ = task_dialog_proc();
        }
        assert_eq!(load_count(), 1);
    }
}

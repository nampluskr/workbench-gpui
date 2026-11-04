//! Text file encoding: detect on read, write back with the same encoding (v0.4 D-6, P3-2).
//!
//! Moved from `dev.rs` (v0.1 R-9 PoC, POC-TABLE R-11 items 9~11): UTF-8 (with or without BOM), UTF-16 LE/BE with
//! BOM, and CP949 through Win32 (no new crate). Line endings stay as they are: the editor keeps `\r`.
//! CP949 writes refuse characters CP949 cannot hold (no best-fit), so a save never silently changes text.

use std::path::Path;

/// Encoding a file was read with (R-9).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TextEncoding {
    Utf8,
    Utf8Bom,
    Utf16Le,
    Utf16Be,
    Cp949,
}

impl TextEncoding {
    pub fn name(self) -> &'static str {
        match self {
            Self::Utf8 => "utf-8",
            Self::Utf8Bom => "utf-8-bom",
            Self::Utf16Le => "utf-16le",
            Self::Utf16Be => "utf-16be",
            Self::Cp949 => "cp949",
        }
    }
}

/// 파일 바이트를 문자열로 바꾼다. 실패하면 이유를 돌려준다.
/// Order: BOMs, then valid UTF-8, then CP949.
pub fn decode(bytes: &[u8]) -> Result<(String, TextEncoding), String> {
    if let Some(rest) = bytes.strip_prefix(&[0xEF, 0xBB, 0xBF]) {
        let text = std::str::from_utf8(rest).map_err(|e| format!("utf-8 bom: {e}"))?;
        return Ok((text.to_owned(), TextEncoding::Utf8Bom));
    }
    if let Some(rest) = bytes.strip_prefix(&[0xFF, 0xFE]) {
        return decode_utf16(rest, false).map(|t| (t, TextEncoding::Utf16Le));
    }
    if let Some(rest) = bytes.strip_prefix(&[0xFE, 0xFF]) {
        return decode_utf16(rest, true).map(|t| (t, TextEncoding::Utf16Be));
    }
    if let Ok(text) = std::str::from_utf8(bytes) {
        return Ok((text.to_owned(), TextEncoding::Utf8));
    }
    cp949_decode(bytes).map(|t| (t, TextEncoding::Cp949))
}

/// 문자열을 인코딩 규칙대로 바이트로 바꾼다. CP949 loss is an error naming the characters.
pub fn encode(text: &str, encoding: TextEncoding) -> Result<Vec<u8>, String> {
    Ok(match encoding {
        TextEncoding::Utf8 => text.as_bytes().to_vec(),
        TextEncoding::Utf8Bom => [&[0xEF, 0xBB, 0xBF][..], text.as_bytes()].concat(),
        TextEncoding::Utf16Le => {
            let mut out = vec![0xFF, 0xFE];
            text.encode_utf16().for_each(|u| out.extend_from_slice(&u.to_le_bytes()));
            out
        }
        TextEncoding::Utf16Be => {
            let mut out = vec![0xFE, 0xFF];
            text.encode_utf16().for_each(|u| out.extend_from_slice(&u.to_be_bytes()));
            out
        }
        TextEncoding::Cp949 => cp949_encode(text)?,
    })
}

/// Writes `bytes` to `path` without leaving a half-written file: a temp file next to it (same volume), flushed,
/// then swapped in with `state::win::replace_file` (ReplaceFileW keeps the target's attributes). On failure the
/// temp file is removed and the original stays.
pub fn write_file(path: &Path, bytes: &[u8]) -> std::io::Result<()> {
    let name = path.file_name().ok_or_else(|| std::io::Error::other("no file name"))?;
    let tmp = path.with_file_name(format!("{}.{}.tmp", name.to_string_lossy(), crate::state::win::new_uuid()));
    let result = (|| {
        let mut f = std::fs::File::create_new(&tmp)?;
        std::io::Write::write_all(&mut f, bytes)?;
        f.sync_all()?;
        drop(f);
        crate::state::win::replace_file(&tmp, path)
    })();
    if result.is_err() {
        let _ = std::fs::remove_file(&tmp);
    }
    result
}

fn decode_utf16(bytes: &[u8], big_endian: bool) -> Result<String, String> {
    if !bytes.len().is_multiple_of(2) {
        return Err("utf-16: odd byte length".into());
    }
    let units: Vec<u16> = bytes
        .as_chunks::<2>()
        .0
        .iter()
        .map(|&c| if big_endian { u16::from_be_bytes(c) } else { u16::from_le_bytes(c) })
        .collect();
    String::from_utf16(&units).map_err(|e| format!("utf-16: {e}"))
}

#[cfg(windows)]
fn cp949_decode(bytes: &[u8]) -> Result<String, String> {
    use win::*;
    if bytes.is_empty() {
        return Ok(String::new());
    }
    let len = i32::try_from(bytes.len()).map_err(|_| "cp949: too large".to_string())?;
    let n = unsafe { MultiByteToWideChar(CP_949, MB_ERR_INVALID_CHARS, bytes.as_ptr(), len, std::ptr::null_mut(), 0) };
    if n <= 0 {
        return Err(format!("cp949: MultiByteToWideChar win32_error={}", unsafe { GetLastError() }));
    }
    let mut wide = vec![0u16; n as usize];
    let written = unsafe { MultiByteToWideChar(CP_949, MB_ERR_INVALID_CHARS, bytes.as_ptr(), len, wide.as_mut_ptr(), n) };
    if written != n {
        return Err(format!("cp949: MultiByteToWideChar wrote {written} of {n} win32_error={}", unsafe {
            GetLastError()
        }));
    }
    String::from_utf16(&wide).map_err(|e| format!("cp949: {e}"))
}

/// 문자열을 CP949 로 바꾼다. 손실이 있으면 오류다.
///
/// - `WC_NO_BEST_FIT_CHARS`: 비슷한 글자로 바꿔 쓰는 best-fit 을 막는다. 막지 않으면 U+20A9(₩)가
///   0x5C(역변환하면 `\`), U+00A5(¥)가 0xA1CD(역변환하면 U+FFE5)로 바뀌면서도 used_default 가 0 이다.
/// - 두 호출의 반환값과 used_default 를 모두 검사한다.
/// - 마지막으로 결과를 다시 풀어 원문과 같은지 확인한다(역변환 손실 검사).
#[cfg(windows)]
fn cp949_encode(text: &str) -> Result<Vec<u8>, String> {
    use win::*;
    let wide: Vec<u16> = text.encode_utf16().collect();
    if wide.is_empty() {
        return Ok(Vec::new());
    }
    let len = i32::try_from(wide.len()).map_err(|_| "cp949: too large".to_string())?;
    let mut used_default = 0i32;
    let n = unsafe {
        WideCharToMultiByte(
            CP_949,
            WC_NO_BEST_FIT_CHARS,
            wide.as_ptr(),
            len,
            std::ptr::null_mut(),
            0,
            std::ptr::null(),
            &mut used_default,
        )
    };
    if n <= 0 {
        return Err(format!("cp949: WideCharToMultiByte win32_error={}", unsafe { GetLastError() }));
    }
    if used_default != 0 {
        return Err(lossy_error(text));
    }
    let mut out = vec![0u8; n as usize];
    let written = unsafe {
        WideCharToMultiByte(
            CP_949,
            WC_NO_BEST_FIT_CHARS,
            wide.as_ptr(),
            len,
            out.as_mut_ptr(),
            n,
            std::ptr::null(),
            &mut used_default,
        )
    };
    if written != n {
        return Err(format!("cp949: WideCharToMultiByte wrote {written} of {n} win32_error={}", unsafe {
            GetLastError()
        }));
    }
    if used_default != 0 {
        return Err(lossy_error(text));
    }
    match cp949_decode(&out) {
        Ok(back) if back == text => Ok(out),
        Ok(_) => Err(lossy_error(text)),
        Err(e) => Err(format!("cp949: round-trip check failed: {e}")),
    }
}

/// CP949 로 그대로 옮길 수 없는 글자를 찾아 오류 문구를 만든다.
#[cfg(windows)]
fn lossy_error(text: &str) -> String {
    let bad: Vec<String> = text
        .chars()
        .filter(|c| {
            let mut buf = [0u16; 2];
            let s = c.encode_utf16(&mut buf);
            cp949_encode_units(s).is_none()
        })
        .map(|c| format!("U+{:04X}", c as u32))
        .collect();
    format!("cp949: lossy conversion, characters not in CP949: {}", bad.join(","))
}

/// 글자 하나(UTF-16 단위들)를 손실 없이 CP949 로 옮길 수 있으면 그 바이트를 돌려준다.
#[cfg(windows)]
fn cp949_encode_units(units: &[u16]) -> Option<Vec<u8>> {
    use win::*;
    let len = i32::try_from(units.len()).ok()?;
    let mut used_default = 0i32;
    let mut out = [0u8; 8];
    let n = unsafe {
        WideCharToMultiByte(
            CP_949,
            WC_NO_BEST_FIT_CHARS,
            units.as_ptr(),
            len,
            out.as_mut_ptr(),
            out.len() as i32,
            std::ptr::null(),
            &mut used_default,
        )
    };
    if n <= 0 || used_default != 0 {
        return None;
    }
    let bytes = out[..n as usize].to_vec();
    let back = cp949_decode(&bytes).ok()?;
    (back.encode_utf16().collect::<Vec<_>>() == units).then_some(bytes)
}

#[cfg(not(windows))]
fn cp949_decode(_bytes: &[u8]) -> Result<String, String> {
    Err("cp949: unsupported".into())
}

#[cfg(not(windows))]
fn cp949_encode(_text: &str) -> Result<Vec<u8>, String> {
    Err("cp949: unsupported".into())
}

#[cfg(windows)]
mod win {
    #[link(name = "kernel32")]
    unsafe extern "system" {
        pub fn GetLastError() -> u32;
        pub fn MultiByteToWideChar(
            code_page: u32,
            flags: u32,
            src: *const u8,
            src_len: i32,
            dst: *mut u16,
            dst_len: i32,
        ) -> i32;
        pub fn WideCharToMultiByte(
            code_page: u32,
            flags: u32,
            src: *const u16,
            src_len: i32,
            dst: *mut u8,
            dst_len: i32,
            default_char: *const u8,
            used_default: *mut i32,
        ) -> i32;
    }

    pub const CP_949: u32 = 949;
    pub const WC_NO_BEST_FIT_CHARS: u32 = 0x400;
    pub const MB_ERR_INVALID_CHARS: u32 = 0x8;
}

#[cfg(all(test, windows))]
mod tests {
    use super::*;

    /// Decode then encode gives the same bytes back, and the detected encoding is the expected one.
    fn round_trip(bytes: &[u8], expect: TextEncoding) {
        let (text, encoding) = decode(bytes).unwrap();
        assert_eq!(encoding, expect);
        assert_eq!(encode(&text, encoding).unwrap(), bytes, "{}", expect.name());
    }

    #[test]
    fn utf8_lf_and_crlf_round_trip() {
        round_trip("첫째 줄 one\nsecond\n".as_bytes(), TextEncoding::Utf8);
        round_trip("첫째 줄 one\r\nsecond\r\n".as_bytes(), TextEncoding::Utf8);
    }

    #[test]
    fn utf8_bom_round_trip() {
        round_trip(&[&[0xEF, 0xBB, 0xBF][..], "bom 한글\r\n".as_bytes()].concat(), TextEncoding::Utf8Bom);
    }

    #[test]
    fn utf16le_round_trip() {
        let mut bytes = vec![0xFF, 0xFE];
        "utf16 한글\r\n😀".encode_utf16().for_each(|u| bytes.extend_from_slice(&u.to_le_bytes()));
        round_trip(&bytes, TextEncoding::Utf16Le);
    }

    #[test]
    fn cp949_round_trip() {
        // "첫째 줄 first line\r\n" in CP949 (not valid UTF-8, so detection falls to CP949).
        let bytes = encode("첫째 줄 first line\r\n", TextEncoding::Cp949).unwrap();
        assert!(std::str::from_utf8(&bytes).is_err());
        round_trip(&bytes, TextEncoding::Cp949);
    }

    /// CP949 save refuses characters it cannot hold instead of best-fit (₩ → `\`, ¥ → U+FFE5).
    #[test]
    fn cp949_rejects_lossy_characters() {
        for (text, code) in [("가격 \u{20A9}1000", "U+20A9"), ("가격 \u{00A5}1000", "U+00A5"), ("emoji 😀", "U+1F600")] {
            let err = encode(text, TextEncoding::Cp949).unwrap_err();
            assert!(err.contains(code), "{err}");
        }
    }

    #[test]
    fn write_file_replaces_and_leaves_no_temp() {
        let dir = std::env::temp_dir().join(format!("wg-text-io-{}", crate::state::win::new_uuid()));
        std::fs::create_dir_all(&dir).unwrap();
        let path = dir.join("a.txt");
        std::fs::write(&path, b"old").unwrap();
        write_file(&path, b"new\r\n").unwrap();
        assert_eq!(std::fs::read(&path).unwrap(), b"new\r\n");
        // A missing target is created too.
        let fresh = dir.join("b.txt");
        write_file(&fresh, b"x").unwrap();
        assert_eq!(std::fs::read(&fresh).unwrap(), b"x");
        let names: Vec<_> = std::fs::read_dir(&dir).unwrap().map(|e| e.unwrap().file_name()).collect();
        assert_eq!(names.len(), 2, "temp file left behind: {names:?}");
        std::fs::remove_dir_all(&dir).unwrap();
    }
}

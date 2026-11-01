//! UTC 시각 문자열 (A-22.5 `added_at` ISO 8601, A-24.6 `YYYYMMDD-HHMMSS`). 새 크레이트 없이 std 로 만든다.
//!
//! 깨진 파일 이름의 시각대는 원문(A-24.6)에 없어 UTC 로 둔다(판단, PROGRESS 에 기록).

use std::time::{SystemTime, UNIX_EPOCH};

/// 유닉스 초 → (연, 월, 일, 시, 분, 초). 1970-01-01 이후 그레고리력(Howard Hinnant 의 civil_from_days 방식).
pub fn civil(secs: u64) -> (i64, u32, u32, u32, u32, u32) {
    let days = (secs / 86_400) as i64;
    let rem = secs % 86_400;
    let z = days + 719_468;
    let era = z.div_euclid(146_097);
    let doe = z.rem_euclid(146_097);
    let yoe = (doe - doe / 1_460 + doe / 36_524 - doe / 146_096) / 365;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = (doy - (153 * mp + 2) / 5 + 1) as u32;
    let m = if mp < 10 { mp + 3 } else { mp - 9 } as u32;
    let y = yoe + era * 400 + if m <= 2 { 1 } else { 0 };
    (y, m, d, (rem / 3600) as u32, (rem % 3600 / 60) as u32, (rem % 60) as u32)
}

fn now_secs() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or_default()
}

/// `2026-11-01T12:34:56Z`.
pub fn iso(secs: u64) -> String {
    let (y, mo, d, h, mi, s) = civil(secs);
    format!("{y:04}-{mo:02}-{d:02}T{h:02}:{mi:02}:{s:02}Z")
}

pub fn iso_now() -> String {
    iso(now_secs())
}

/// `20261101-123456`.
pub fn stamp_now() -> String {
    let (y, mo, d, h, mi, s) = civil(now_secs());
    format!("{y:04}{mo:02}{d:02}-{h:02}{mi:02}{s:02}")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn known_dates() {
        assert_eq!(iso(0), "1970-01-01T00:00:00Z");
        assert_eq!(iso(951_782_400), "2000-02-29T00:00:00Z");
        assert_eq!(iso(1_793_491_200), "2026-11-01T00:00:00Z");
    }
}

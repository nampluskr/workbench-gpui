//! Status text from source byte offsets (I-5).
use std::path::Path;

pub fn toggle_color(open: bool, accent: gpui_kit::Hsla, muted: gpui_kit::Hsla) -> gpui_kit::Hsla {
    if open { accent } else { muted }
}

pub fn position(text: &str, offset: usize) -> (usize, usize) {
    let mut end = offset.min(text.len());
    while !text.is_char_boundary(end) { end -= 1; }
    let before = &text[..end];
    (before.bytes().filter(|b| *b == b'\n').count() + 1,
        before.rsplit('\n').next().unwrap_or("").chars().count() + 1)
}

pub fn filetype(path: &Path) -> &'static str {
    let name = path.file_name().and_then(|s| s.to_str()).unwrap_or("");
    let languages: &'static [(&str, &[&str])] = include!("status_languages.rs");
    languages.iter().flat_map(|(language, suffixes)| suffixes.iter().map(move |suffix| (*language, *suffix)))
        .filter(|(_, suffix)| name == *suffix || name.strip_suffix(suffix).is_some_and(|prefix| prefix.ends_with('.')))
        .max_by_key(|(_, suffix)| suffix.len())
        .map_or("Plain Text", |(language, _)| language)
}

pub fn preview_line_start(text: &str, offset: usize) -> usize {
    let mut end = offset.min(text.len());
    while !text.is_char_boundary(end) { end -= 1; }
    text[..end].rfind('\n').map_or(0, |at| at + 1)
}

pub fn left_items(sidebar_open: bool) -> &'static [&'static str] {
    if sidebar_open { &["project", "divider-project", "search", "diagnostics"] }
    else { &["sidebar", "divider-sidebar", "project", "divider-project", "search", "diagnostics"] }
}

/// Zed shows the cursor (with selection counts) and the file type as two separate status buttons.
pub fn parts(text: &str, cursor: usize, ranges: &[std::ops::Range<usize>], path: Option<&Path>) -> (String, Option<&'static str>) {
    let (line, column) = position(text, cursor);
    let (mut lines, mut characters) = (0, 0);
    for range in ranges {
        let Some(selected) = text.get(range.clone()).filter(|s| !s.is_empty()) else { continue };
        characters += selected.chars().count();
        let start = position(text, range.start).0;
        let (end, col) = position(text, range.end);
        lines += end - start + usize::from(col > 1);
    }
    let mut counts = Vec::new();
    for (count, name, threshold) in [(ranges.len(), "selection", 1), (lines, "line", 1), (characters, "character", 0)] {
        if count > threshold { counts.push(format!("{count} {name}{}", if count == 1 { "" } else { "s" })); }
    }
    let mut text = format!("{line}:{column}");
    if !counts.is_empty() { text.push_str(&format!(" ({})", counts.join(", "))); }
    (text, path.map(filetype))
}

#[cfg(test)]
pub fn label(text: &str, cursor: usize, ranges: &[std::ops::Range<usize>], path: Option<&Path>) -> String {
    let (mut text, kind) = parts(text, cursor, ranges, path);
    if let Some(kind) = kind { text.push(' '); text.push_str(kind); }
    text
}

#[cfg(test)]
mod tests {
    use super::{filetype, label, parts, position, toggle_color, preview_line_start, left_items};
    use std::path::Path;

    #[test]
    fn k23_source_positions_and_names() {
        assert_eq!(position("a\n한😀e\u{301}", "a\n한😀".len()), (2, 3));
        assert_eq!(position("\t한\r\n", 1), (1, 2));
        assert_eq!(position("\t한\r\n", 6), (2, 1));
        assert_eq!(position("", 0), (1, 1));
        for (path, expected) in [("x.md", "Markdown"), ("x.rs", "Rust"), ("x.ts", "TypeScript"),
            ("x.json", "JSON"), ("tsconfig.json", "JSONC"), ("x.unknown", "Plain Text")] {
            assert_eq!(filetype(Path::new(path)), expected);
        }
        assert_eq!(label("abc", 1, std::slice::from_ref(&(0..1)), Some(Path::new("x.md"))), "1:2 (1 character) Markdown");
        assert_eq!(label("abc", 1, std::slice::from_ref(&(1..1)), Some(Path::new("x.md"))), "1:2 Markdown");
    }

    #[test]
    fn k23_preview_blocks_use_original_byte_offsets() {
        let source = "# 한글\r\n\r\nsame\r\n\r\n```rust\r\nfn main() {}\r\n```\r\n\r\nsame";
        // Handwritten AST block starts, including repeated text and a fenced block.
        for (offset, expected) in [(0, (1, 1)), (12, (3, 1)), (20, (5, 1)), (50, (9, 1))] {
            assert_eq!(position(source, offset), expected);
            assert_eq!(label(source, offset, std::slice::from_ref(&(offset..offset)), Some(Path::new("x.md"))),
                format!("{}:{} Markdown", expected.0, expected.1));
        }
        assert_eq!(position("한😀", 1), (1, 1));
        assert_eq!(position("한😀", usize::MAX), (1, 3));
    }

    #[test]
    fn k23_toggle_color_follows_open_state() {
        let accent = gpui_kit::Hsla::from(gpui_kit::rgb(0x123456));
        let muted = gpui_kit::Hsla::from(gpui_kit::rgb(0xabcdef));
        for sidebar in [false, true] {
            for dock in [false, true] {
                assert_eq!(toggle_color(sidebar, accent, muted), if sidebar { accent } else { muted });
                assert_eq!(toggle_color(dock, accent, muted), if dock { accent } else { muted });
            }
        }
    }

    #[test]
    fn k24_selection_counts_and_search_format() {
        assert_eq!(label("hello", 5, std::slice::from_ref(&(0..5)), Some(Path::new("x.md"))), "1:6 (5 characters) Markdown");
        assert_eq!(label("한😀\nx\n", 10, std::slice::from_ref(&(0..10)), None), "3:1 (2 lines, 5 characters)");
        assert_eq!(label("ab\ncd", 4, &[0..1, 3..4], None), "2:2 (2 selections, 2 lines, 2 characters)");
        assert_eq!(label("abc", 1, &[0..0, 1..1], None), "1:2 (2 selections)");
        assert_eq!(label("a", 0, std::slice::from_ref(&(0..1)), None), "1:1 (1 character)");
        let search = format!("{}{}", "\n".repeat(44), "a".repeat(34));
        let end = search.len();
        assert_eq!(label(&search, end, std::slice::from_ref(&(end-8..end)), None), "45:35 (8 characters)");
    }

    #[test]
    fn k28_cursor_and_filetype_are_separate_items() {
        let selected = std::slice::from_ref(&(0..5));
        assert_eq!(parts("hello", 5, selected, Some(Path::new("x.md"))), ("1:6 (5 characters)".to_string(), Some("Markdown")));
        assert_eq!(parts("hello", 0, std::slice::from_ref(&(0..0)), None), ("1:1".to_string(), None));
    }

    #[test]
    fn k24_left_order_and_visibility() {
        assert_eq!(left_items(false), &["sidebar", "divider-sidebar", "project", "divider-project", "search", "diagnostics"]);
        assert_eq!(left_items(true), &["project", "divider-project", "search", "diagnostics"]);
    }

    #[test]
    fn k24_innermost_preview_block_lines() {
        let text = "- first\n- second\n\n```rust\ncode\n```\n\n> paragraph\n>\n> inner";
        // Parser span starts: second list item, fenced code, inner quote paragraph.
        for (offset, row) in [(8, 2), (18, 4), (51, 10)] {
            let at = preview_line_start(text, offset);
            assert_eq!(position(text, at), (row, 1));
        }
    }
}

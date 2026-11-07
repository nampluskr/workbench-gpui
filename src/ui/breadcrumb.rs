//! I-12: the breadcrumb text above an editor: the file's path, then the Markdown heading hierarchy at the cursor.
//! Values from Zed `crates/editor/src/editor.rs` `breadcrumbs_inner` and `element.rs` `render_breadcrumb_text` (read only).

use std::{ops::Range, path::Path};

use super::syntax::OutlineSymbol;
use gpui_kit::{HighlightStyle, Hsla};

/// Zed `MAX_SEGMENTS`: more segments than this keep the first and last half and a `⋯` between.
const MAX_SEGMENTS: usize = 12;

/// The path as one segment (never split per directory, `\` kept): relative to the folder root; with several folders
/// open it starts with the root folder's name. A file outside the root shows its file name only (Zed's single-file
/// worktree has the file name as its path).
pub fn path_text(root: &Path, root_name: &str, path: &Path, several_folders: bool) -> String {
    let Ok(rel) = path.strip_prefix(root) else {
        return path.file_name().map_or_else(|| path.display().to_string(), |n| n.to_string_lossy().into_owned());
    };
    let rel = rel.display().to_string();
    if several_folders { format!("{root_name}\\{rel}") } else { rel }
}

/// The Markdown headings that contain the cursor's line, outermost first, each with its `#` prefix (`## Title`).
/// A heading on the cursor's own line counts; a cursor above the first heading gives none.
// shortcut: ATX headings only (no setext `===`/`---` underlines), fences toggle on any line starting with three
// backticks or tildes, `#` inside HTML blocks is read as a heading; upgrade with a real Markdown parser if these show up.
pub fn heading_trail(text: &str, cursor: usize) -> Vec<String> {
    let cursor_line = text.get(..cursor.min(text.len())).map_or(0, |before| before.matches('\n').count());
    let mut stack: Vec<(usize, String)> = Vec::new();
    let mut fence: Option<char> = None;
    for line in text.lines().take(cursor_line + 1) {
        let trimmed = line.trim_start_matches(' ');
        let indented = line.len() - trimmed.len();
        if indented > 3 {
            continue;
        }
        if let Some(mark) = ["```", "~~~"].iter().find(|m| trimmed.starts_with(**m)).and_then(|m| m.chars().next()) {
            match fence {
                None => fence = Some(mark),
                Some(open) if open == mark => fence = None,
                _ => {}
            }
            continue;
        }
        if fence.is_some() {
            continue;
        }
        let level = trimmed.chars().take_while(|c| *c == '#').count();
        let rest = &trimmed[level..];
        if !(1..=6).contains(&level) || !(rest.is_empty() || rest.starts_with([' ', '\t'])) {
            continue;
        }
        let title = rest.trim().trim_end_matches('#').trim_end();
        stack.retain(|(l, _)| *l < level);
        stack.push((level, if title.is_empty() { "#".repeat(level) } else { format!("{} {title}", "#".repeat(level)) }));
    }
    stack.into_iter().map(|(_, s)| s).collect()
}

/// One breadcrumb segment: its text and the highlight runs over it (a code symbol keeps the editor's syntax colours; a
/// Markdown heading is one run in the theme's `title` colour). Unstyled text stays the muted breadcrumb colour.
#[derive(Clone, Debug, Default, PartialEq)]
pub struct Crumb {
    pub text: String,
    pub runs: Vec<(Range<usize>, HighlightStyle)>,
}

impl From<&str> for Crumb {
    fn from(text: &str) -> Self {
        Self { text: text.to_string(), runs: Vec::new() }
    }
}

impl Crumb {
    pub fn plain(text: String) -> Self {
        Self { text, runs: Vec::new() }
    }

    /// The whole text in `color` (a Markdown heading); plain when the theme has no such colour.
    pub fn colored(text: String, color: Option<Hsla>) -> Self {
        let runs = color.map(|color| vec![(0..text.len(), HighlightStyle { color: Some(color), ..Default::default() })]).unwrap_or_default();
        Self { text, runs }
    }
}

impl From<OutlineSymbol> for Crumb {
    fn from(symbol: OutlineSymbol) -> Self {
        Self { text: symbol.text, runs: symbol.runs }
    }
}

/// Path first, then the headings or symbols; more than `MAX_SEGMENTS` become the first 6, `⋯`, the last 6.
pub fn segments<T: From<&'static str>>(path: T, rest: Vec<T>) -> Vec<T> {
    let mut all = Vec::with_capacity(rest.len() + 1);
    all.push(path);
    all.extend(rest);
    let head = all.len().min(MAX_SEGMENTS / 2);
    let tail = all.len().saturating_sub(MAX_SEGMENTS / 2).max(head);
    if tail > head {
        all.splice(head..tail, Some(T::from("⋯")));
    }
    all
}

#[cfg(test)]
mod tests {
    use super::{heading_trail, path_text, segments};
    use std::path::Path;

    fn trail(text: &str, marker: &str) -> Vec<String> {
        heading_trail(text, text.find(marker).unwrap())
    }

    #[test]
    fn k34_heading_trail_follows_the_cursor() {
        let text = "intro\n# AGENTS\nbody\n## 레포 규칙\nrule\n## 다른\n### 깊은\nx\n";
        assert!(trail(text, "intro").is_empty(), "above the first heading: path only");
        assert_eq!(trail(text, "# AGENTS"), ["# AGENTS"], "the heading's own line counts");
        assert_eq!(trail(text, "rule"), ["# AGENTS", "## 레포 규칙"]);
        assert_eq!(trail(text, "x"), ["# AGENTS", "## 다른", "### 깊은"], "a sibling replaces the earlier ## section");
    }

    #[test]
    fn k34_heading_trail_skips_levels_and_fences() {
        let text = "# A\n### C\ntext\n```\n# not a heading\n```\n#nospace\n    # indented\nend\n";
        assert_eq!(trail(text, "text"), ["# A", "### C"], "# then ### keeps both");
        assert_eq!(trail(text, "# not"), ["# A", "### C"], "inside a fence");
        assert_eq!(trail(text, "end"), ["# A", "### C"], "no space, 4-space indent: not headings");
        assert_eq!(heading_trail("# T #\n", 0), ["# T"], "closing hashes are dropped");
    }

    #[test]
    fn k34_path_text_one_or_several_folders() {
        let root = Path::new(r"D:\w\workbench-tauri");
        let file = root.join("src").join("App.tsx");
        assert_eq!(path_text(root, "workbench-tauri", &file, false), r"src\App.tsx");
        assert_eq!(path_text(root, "workbench-tauri", &root.join("AGENTS.md"), true), r"workbench-tauri\AGENTS.md");
        assert_eq!(path_text(root, "workbench-tauri", Path::new(r"D:\other\notes.md"), true), "notes.md", "outside the root");
    }

    /// K-45: a heading is one run in the title colour, a theme without it leaves plain text; the elision keeps runs.
    #[test]
    fn k45_crumbs_carry_their_runs() {
        use super::Crumb;
        use gpui_kit::{HighlightStyle, rgb};
        let color = rgb(0x61afef).into();
        let heading = Crumb::colored("## Rule".into(), Some(color));
        assert_eq!(heading.runs, vec![(0..7, HighlightStyle { color: Some(color), ..Default::default() })]);
        assert!(Crumb::colored("## Rule".into(), None).runs.is_empty());
        let many = segments(Crumb::plain("p".into()), (1..=13).map(|i| Crumb::colored(i.to_string(), Some(color))).collect());
        assert_eq!(many.len(), 13);
        assert_eq!(many[6], Crumb::from("⋯"), "the elision is plain text");
        assert!(many[5].runs.len() == 1 && many[7].runs.len() == 1, "kept segments keep their runs");
    }

    #[test]
    fn k34_long_trails_are_elided_in_the_middle() {
        let few = segments::<String>("a.md".into(), vec!["# 1".into(), "## 2".into()]);
        assert_eq!(few, ["a.md", "# 1", "## 2"]);
        let twelve = segments::<String>("p".into(), (1..12).map(|i| i.to_string()).collect());
        assert_eq!(twelve.len(), 12, "12 segments are kept whole");
        let many = segments::<String>("p".into(), (1..=13).map(|i| i.to_string()).collect());
        assert_eq!(many, ["p", "1", "2", "3", "4", "5", "⋯", "8", "9", "10", "11", "12", "13"]);
    }
}

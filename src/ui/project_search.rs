//! Background workspace search (SPEC R-22).
use std::{collections::BTreeMap, path::{Path, PathBuf}, sync::atomic::{AtomicBool, Ordering}};
use ignore::{WalkBuilder, overrides::OverrideBuilder};
use regex::{Regex, RegexBuilder};

#[derive(Clone, Default)]
pub struct Options {
    pub query: String,
    pub case: bool,
    pub words: bool,
    pub regex: bool,
    pub include: String,
    pub exclude: String,
    pub ignored: bool,
    pub only_open: bool,
}

#[derive(Clone, Debug)]
pub struct Hit { pub range: std::ops::Range<usize>, pub line: usize, pub column: usize, pub excerpt: String, pub context_line: usize }
#[derive(Clone, Debug)]
pub struct File { pub path: PathBuf, pub text: String, pub hits: Vec<Hit>, pub line_starts: Vec<usize> }
#[derive(Default)]
pub struct Results { pub files: Vec<File>, pub limited: bool, pub cancelled: bool, pub errors: Vec<String> }

pub fn pattern(options: &Options) -> Result<Regex, String> {
    if options.query.is_empty() { return Err("Enter a search query".into()); }
    let query = if options.regex { options.query.clone() } else { regex::escape(&options.query) };
    let query = if options.words { format!(r"\b(?:{query})\b") } else { query };
    RegexBuilder::new(&query).case_insensitive(!options.case).multi_line(true).build().map_err(|e| e.to_string())
}

pub fn matches(text: &str, pattern: &Regex, limit: usize, cancel: &AtomicBool) -> Vec<Hit> {
    let mut hits = Vec::new();
    let starts: Vec<_> = std::iter::once(0).chain(text.match_indices('\n').map(|(at, _)| at + 1)).collect();
    for found in pattern.find_iter(text).take(limit) {
        if cancel.load(Ordering::Relaxed) { break; }
        let row = starts.partition_point(|at| *at <= found.end()) - 1;
        let start_row = starts.partition_point(|at| *at <= found.start()) - 1;
        let line = row + 1;
        let column = text[starts[row]..found.end()].chars().count() + 1;
        let context_line = start_row.saturating_sub(2);
        let context = starts[context_line]..starts.get(row + 3).copied().unwrap_or(text.len());
        // SPEC R-22: two source lines on each side of the matching line.
        let excerpt = text[context.clone()].lines().enumerate()
            .map(|(i, text)| format!("{}  {text}", context_line + i + 1)).collect::<Vec<_>>().join("\n");
        hits.push(Hit { range: found.range(), line, column, excerpt, context_line });
    }
    hits
}

pub fn search(root: &Path, options: &Options, open: &BTreeMap<PathBuf, String>, cancel: &AtomicBool) -> Result<Results, String> {
    let pattern = pattern(options)?;
    let mut overrides = OverrideBuilder::new(root);
    for (globs, excluded) in [(&options.include, false), (&options.exclude, true)] {
        for glob in globs.split(',').map(str::trim).filter(|g| !g.is_empty()) {
            overrides.add(&format!("{}{glob}", if excluded { "!" } else { "" })).map_err(|e| e.to_string())?;
        }
    }
    let mut walk = WalkBuilder::new(root);
    walk.follow_links(false).hidden(true).overrides(overrides.build().map_err(|e| e.to_string())?)
        .filter_entry(|entry| {
            use std::os::windows::fs::MetadataExt as _;
            entry.depth() == 0 || (!entry.file_name().to_string_lossy().starts_with('.')
                && entry.path().symlink_metadata().is_ok_and(|meta| meta.file_attributes() & 0x400 == 0))
        })
        .sort_by_file_path(|a, b| a.cmp(b));
    if options.ignored { walk.git_ignore(false).git_global(false).git_exclude(false).ignore(false); }
    let mut results = Results::default();
    let mut count = 0;
    for entry in walk.build() {
        if cancel.load(Ordering::Relaxed) { results.cancelled = true; break; }
        let entry = match entry { Ok(entry) => entry, Err(e) => { results.errors.push(e.to_string()); continue } };
        if !entry.file_type().is_some_and(|t| t.is_file()) { continue; }
        let path = entry.path();
        if options.only_open && !open.contains_key(path) { continue; }
        let text = match open.get(path) {
            Some(text) => text.clone(),
            None => match std::fs::read(path) {
                Ok(bytes) if !bytes.contains(&0) => match String::from_utf8(bytes) {
                    Ok(text) => text.trim_start_matches('\u{feff}').replace("\r\n", "\n"), Err(_) => continue
                },
                Ok(_) => continue,
                Err(e) => { results.errors.push(format!("{}: {e}", path.display())); continue }
            },
        };
        if text.contains('\0') { continue; }
        let hits = matches(&text, &pattern, 10_000 - count, cancel);
        if hits.is_empty() { continue; }
        count += hits.len();
        let line_starts = std::iter::once(0).chain(text.match_indices('\n').map(|(at, _)| at + 1)).collect();
        results.files.push(File { path: path.to_owned(), text, hits, line_starts });
        if results.files.len() >= 5_000 || count >= 10_000 { results.limited = true; break; }
    }
    Ok(results)
}

pub fn replacement(file: &File, current: &str, options: &Options, replacement: &str, one: Option<usize>) -> Result<String, String> {
    if file.text != current { return Err("File changed since search; search again before replacing".into()); }
    let pattern = pattern(options)?;
    if one.is_some_and(|at| at >= file.hits.len()) { return Err("Search result no longer exists".into()); }
    let mut edits = Vec::new();
    for (index, (hit, captures)) in file.hits.iter().zip(pattern.captures_iter(current)).enumerate() {
        if one.is_some_and(|at| at != index) { continue; }
        if captures.get(0).map(|m| m.range()) != Some(hit.range.clone()) { return Err("Invalid search range".into()); }
        let mut value = String::new();
        if options.regex { captures.expand(replacement, &mut value); } else { value.push_str(replacement); }
        edits.push((hit.range.clone(), value));
    }
    let mut text = current.to_owned();
    for (range, value) in edits.into_iter().rev() { text.replace_range(range, &value); }
    Ok(text)
}

#[cfg(test)]
mod tests {
    use super::{Options, search, replacement};
    use std::{collections::BTreeMap, sync::atomic::AtomicBool};
    #[test]
    fn k25_filters_groups_positions_and_replacement() {
        let root = std::env::temp_dir().join(format!("workbench-k25-{}", crate::state::win::new_uuid()));
        std::fs::create_dir_all(root.join(".git")).unwrap();
        std::fs::create_dir(root.join("src")).unwrap();
        for (name, bytes) in [(".gitignore", &b"ignored.txt\n"[..]), ("ignored.txt", &b"word"[..]),
            (".hidden", &b"word"[..]), ("binary", &b"word\0"[..]), ("invalid", &b"word\xff"[..]),
            ("src/a.txt", "before\n한😀 word WORD words\nafter\nend".as_bytes())] {
            std::fs::write(root.join(name), bytes).unwrap();
        }
        let cancel = AtomicBool::new(false);
        let mut options = Options { query: "word".into(), words: true, ..Options::default() };
        let result = search(&root, &options, &BTreeMap::new(), &cancel).unwrap();
        assert_eq!(result.files.len(), 1);
        assert_eq!(result.files[0].hits.len(), 2);
        assert_eq!((result.files[0].hits[0].line, result.files[0].hits[0].column), (2, 8));
        assert!(result.files[0].hits[0].excerpt.contains("1  before"));
        assert_eq!(replacement(&result.files[0], "changed", &options, "x", None).unwrap_err(), "File changed since search; search again before replacing");
        assert!(replacement(&result.files[0], &result.files[0].text, &options, "$x", None).unwrap().contains("$x $x words"));
        options.case = true;
        assert_eq!(search(&root, &options, &BTreeMap::new(), &cancel).unwrap().files[0].hits.len(), 1);
        options.ignored = true;
        assert_eq!(search(&root, &options, &BTreeMap::new(), &cancel).unwrap().files.len(), 2);
        options.include = "src/**".into(); options.exclude = "*.txt".into();
        assert!(search(&root, &options, &BTreeMap::new(), &cancel).unwrap().files.is_empty());
        options.include.clear(); options.exclude.clear(); options.only_open = true;
        assert!(search(&root, &options, &BTreeMap::new(), &cancel).unwrap().files.is_empty());
        options.only_open = false; options.regex = true; options.query = "[".into();
        assert!(search(&root, &options, &BTreeMap::new(), &cancel).is_err());
        options.query = "w.rd".into();
        assert!(!search(&root, &options, &BTreeMap::new(), &cancel).unwrap().files.is_empty());
        options.regex = false; options.query = "word".into(); options.include = "src/**".into();
        assert_eq!(search(&root, &options, &BTreeMap::new(), &cancel).unwrap().files.len(), 1);
        options.only_open = true;
        let open = BTreeMap::from([(root.join("src/a.txt"), "word unsaved word".to_owned())]);
        assert_eq!(search(&root, &options, &open, &cancel).unwrap().files[0].text, "word unsaved word");
        options.only_open = false; options.include.clear(); options.regex = true; options.query = "(word)".into();
        let mut limited = search(&root, &options, &BTreeMap::new(), &cancel).unwrap().files.into_iter().find(|f| f.path.ends_with("a.txt")).unwrap();
        limited.hits.truncate(1);
        assert!(replacement(&limited, &limited.text, &options, "${1}_new", None).unwrap().contains("word_new WORD words"));
        options.query = "word".into();
        cancel.store(true, std::sync::atomic::Ordering::Relaxed);
        assert!(search(&root, &options, &BTreeMap::new(), &cancel).unwrap().cancelled);
        std::fs::remove_dir_all(root).unwrap();
    }

    #[test]
    fn k25_result_limit_and_zero_width_replacements() {
        let cancel = AtomicBool::new(false);
        let options = Options { query: "(?m)^".into(), regex: true, ..Options::default() };
        let regex = super::pattern(&options).unwrap();
        let text = "a\nb\nc";
        let hits = super::matches(text, &regex, 2, &cancel);
        assert_eq!(hits.len(), 2);
        let file = super::File { path: "test".into(), text: text.into(), hits, line_starts: vec![0,2,4] };
        assert_eq!(replacement(&file, text, &options, "x", None).unwrap(), "xa\nxb\nc");
        assert_eq!(replacement(&file, text, &options, "x", Some(1)).unwrap(), "a\nxb\nc");
    }

    /// K-29: Replace only computes the new buffer text (the tab is then marked dirty by `Pane::on_edit`, see `edit_marks_dirty`);
    /// the file on disk keeps its bytes until the user saves the tab.
    #[test]
    fn k29_replacement_does_not_touch_the_disk() {
        let root = std::env::temp_dir().join(format!("workbench-k29-{}", crate::state::win::new_uuid()));
        std::fs::create_dir_all(&root).unwrap();
        let path = root.join("a.txt");
        std::fs::write(&path, "one word\ntwo word\n").unwrap();
        let options = Options { query: "word".into(), ..Options::default() };
        let result = search(&root, &options, &BTreeMap::new(), &AtomicBool::new(false)).unwrap();
        let file = &result.files[0];
        assert_eq!(replacement(file, &file.text, &options, "x", Some(0)).unwrap(), "one x\ntwo word\n");
        assert_eq!(replacement(file, &file.text, &options, "x", None).unwrap(), "one x\ntwo x\n");
        assert_eq!(std::fs::read_to_string(&path).unwrap(), "one word\ntwo word\n");
        std::fs::remove_dir_all(root).unwrap();
    }}

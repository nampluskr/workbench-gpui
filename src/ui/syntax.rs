//! Zed 4304dec language metadata, local query resources (K-42A) and the editor highlighter adapter (K-42B).

use std::{
    cell::{Cell, RefCell},
    collections::HashMap,
    ops::Range,
    path::Path,
    rc::Rc,
    sync::{
        Arc, OnceLock, RwLock,
        atomic::{AtomicU64, Ordering},
    },
};

use gpui_kit::{
    App, Context, Entity, EntityId, Global, HighlightStyle, Window,
    base::text::CodeBlock,
    base::input::{FoldRange, HighlightStyleResolver, InputEdit, InputHighlighter, InputHighlighterFactory, Rope, TabSize},
    component::input::EditorState,
};
use regex::Regex;
use tree_sitter::{
    InputEdit as TsEdit, Language, Node, Parser, Point as TsPoint, Query, QueryCursor, Range as TsRange, StreamingIterator,
    TextProvider, Tree,
};

pub struct LanguageSpec {
    pub id: &'static str,
    pub name: &'static str,
    pub suffixes: &'static [&'static str],
    pub first_line: Option<&'static str>,
    pub grammar: &'static str,
}

/// SPEC R-15: 23 built-ins (including hidden injection languages) and HTML.
pub const LANGUAGES: &[LanguageSpec] = &[
    LanguageSpec { id: "bash", name: "Shell Script", suffixes: &["sh", "bash", "bashrc", "bash_profile", "bash_aliases", "bash_login", "bash_logout", "brushrc", "bats", "envrc", "profile", "zsh", "zshrc", "zshenv", "zsh_profile", "zsh_aliases", "zsh_histfile", "zlogin", "zprofile", "PKGBUILD", "APKBUILD", "ebuild"], first_line: Some(r"^#!.*\b(?:ash|bash|bats|dash|sh|zsh)\b"), grammar: "bash" },
    LanguageSpec { id: "c", name: "C", suffixes: &["c"], first_line: None, grammar: "c" },
    LanguageSpec { id: "cpp", name: "C++", suffixes: &["cc", "ccm", "hh", "cpp", "cppm", "h", "hpp", "cxx", "cxxm", "hxx", "c++", "c++m", "h++", "hip", "ipp", "inl", "ino", "ixx", "cu", "cuh", "C", "H"], first_line: Some(r"^//.*-\*-\s*C\+\+\s*-\*-"), grammar: "cpp" },
    LanguageSpec { id: "css", name: "CSS", suffixes: &["css", "postcss", "pcss"], first_line: None, grammar: "css" },
    LanguageSpec { id: "diff", name: "Diff", suffixes: &["diff", "patch"], first_line: None, grammar: "diff" },
    LanguageSpec { id: "env", name: "Env", suffixes: &[".env"], first_line: None, grammar: "bash" },
    LanguageSpec { id: "gitcommit", name: "Git Commit", suffixes: &["TAG_EDITMSG", "MERGE_MSG", "COMMIT_EDITMSG", "NOTES_EDITMSG", "EDIT_DESCRIPTION"], first_line: None, grammar: "gitcommit" },
    LanguageSpec { id: "go", name: "Go", suffixes: &["go"], first_line: Some(r"^//.*\bgo run\b"), grammar: "go" },
    LanguageSpec { id: "gomod", name: "Go Mod", suffixes: &["mod"], first_line: None, grammar: "gomod" },
    LanguageSpec { id: "gowork", name: "Go Work", suffixes: &["work"], first_line: None, grammar: "gowork" },
    LanguageSpec { id: "javascript", name: "JavaScript", suffixes: &["js", "jsx", "mjs", "cjs"], first_line: Some(r"^#!.*\b(?:[/ ]node|deno run.*--ext[= ]js)\b"), grammar: "tsx" },
    LanguageSpec { id: "jsdoc", name: "JSDoc", suffixes: &[], first_line: None, grammar: "jsdoc" },
    LanguageSpec { id: "json", name: "JSON", suffixes: &["json", "flake.lock", "geojson", "topojson", "prettierrc", "json.dist", "deno.lock"], first_line: None, grammar: "json" },
    LanguageSpec { id: "jsonc", name: "JSONC", suffixes: &["jsonc", "bun.lock", "devcontainer.json", "pyrightconfig.json", "tsconfig.json", "luaurc", "swcrc", "babelrc", "eslintrc", "stylelintrc", "jshintrc"], first_line: None, grammar: "jsonc" },
    LanguageSpec { id: "markdown", name: "Markdown", suffixes: &["md", "mdx", "mdwn", "mdc", "markdown", "MD"], first_line: None, grammar: "markdown" },
    LanguageSpec { id: "markdown-inline", name: "Markdown-Inline", suffixes: &[], first_line: None, grammar: "markdown-inline" },
    LanguageSpec { id: "python", name: "Python", suffixes: &["py", "pyi", "mpy"], first_line: Some(r"^#!.*((\bpython[0-9.]*\b)|(\buv run\b))"), grammar: "python" },
    LanguageSpec { id: "regex", name: "Regex", suffixes: &[], first_line: None, grammar: "regex" },
    LanguageSpec { id: "rust", name: "Rust", suffixes: &["rs"], first_line: None, grammar: "rust" },
    LanguageSpec { id: "tsx", name: "TSX", suffixes: &["tsx"], first_line: None, grammar: "tsx" },
    LanguageSpec { id: "typescript", name: "TypeScript", suffixes: &["ts", "cts", "mts"], first_line: Some(r"^#!.*\b(?:deno run|ts-node|bun|tsx|[/ ]node)\b"), grammar: "typescript" },
    LanguageSpec { id: "yaml", name: "YAML", suffixes: &["yml", "yaml", "pixi.lock", "clang-format", "clangd", "bst"], first_line: None, grammar: "yaml" },
    LanguageSpec { id: "zed-keybind-context", name: "Zed Keybind Context", suffixes: &[], first_line: None, grammar: "rust" },
    LanguageSpec { id: "html", name: "HTML", suffixes: &["html", "htm", "shtml"], first_line: None, grammar: "html" },
    // K-48: TOML (zed-extensions/toml v1.1.0) and Git (d1y/git_firefly v0.1.9), values of each `languages/<name>/config.toml`.
    LanguageSpec { id: "toml", name: "TOML", suffixes: &["Cargo.lock", "toml", "Pipfile", "uv.lock"], first_line: None, grammar: "toml" },
    LanguageSpec { id: "gitattributes", name: "Git Attributes", suffixes: &["gitattributes", ".gitattributes"], first_line: None, grammar: "gitattributes" },
    LanguageSpec { id: "gitconfig", name: "Git Config", suffixes: &["config.worktree", ".gitconfig", ".gitmodules", ".lfsconfig"], first_line: None, grammar: "git_config" },
    LanguageSpec { id: "gitignore", name: "Git Ignore", suffixes: &[".containerignore", ".cursorignore", ".dockerignore", ".eslintignore", ".fdignore", ".gitignore", ".gitignore_global", ".git-blame-ignore-revs", ".ignore", ".npmignore", ".prettierignore", ".rgignore", ".vscodeignore"], first_line: None, grammar: "gitignore" },
    LanguageSpec { id: "gitrebase", name: "Git Rebase", suffixes: &["git-rebase-todo"], first_line: None, grammar: "git_rebase" },
];

pub fn language_for_path(path: &Path, first_line: &str) -> Option<&'static LanguageSpec> {
    let name = path.file_name()?.to_str()?;
    LANGUAGES.iter().flat_map(|language| {
        language.suffixes.iter().filter_map(move |suffix| {
            (name == *suffix || name.strip_suffix(suffix).is_some_and(|prefix| prefix.ends_with('.')))
                .then_some((suffix.len(), language))
        })
    }).max_by_key(|(length, _)| *length).map(|(_, language)| language)
        .or_else(|| LANGUAGES.iter().find(|language| {
            language.first_line.is_some_and(|pattern| Regex::new(pattern).is_ok_and(|re| re.is_match(first_line)))
        }))
}

pub fn grammar(id: &str) -> Option<Language> {
    match id {
        "rust" => Some(tree_sitter_rust::LANGUAGE.into()),
        // Env shares the Shell Script grammar but keeps its own query folder.
        "bash" | "env" => Some(tree_sitter_bash::LANGUAGE.into()),
        "diff" => Some(tree_sitter_diff::LANGUAGE.into()),
        "gitcommit" => Some(tree_sitter_gitcommit::LANGUAGE.into()),
        "go" => Some(tree_sitter_go::LANGUAGE.into()),
        "gomod" => Some(tree_sitter_go_mod::LANGUAGE.into()),
        "gowork" => Some(tree_sitter_gowork::LANGUAGE.into()),
        "html" => Some(vendored(tree_sitter_html)),
        "toml" => Some(vendored(tree_sitter_toml)),
        "gitattributes" => Some(tree_sitter_gitattributes::LANGUAGE.into()),
        "gitconfig" => Some(vendored(tree_sitter_git_config)),
        "gitignore" => Some(vendored(tree_sitter_gitignore)),
        "gitrebase" => Some(tree_sitter_git_rebase::LANGUAGE.into()),
        "python" => Some(tree_sitter_python::LANGUAGE.into()),
        // JavaScript uses the TSX grammar with its own `javascript` query folder (SPEC R-15).
        "javascript" | "tsx" => Some(tree_sitter_typescript::LANGUAGE_TSX.into()),
        "typescript" => Some(tree_sitter_typescript::LANGUAGE_TYPESCRIPT.into()),
        "yaml" => Some(tree_sitter_yaml::LANGUAGE.into()),
        "jsdoc" => Some(tree_sitter_jsdoc::LANGUAGE.into()),
        "regex" => Some(tree_sitter_regex::LANGUAGE.into()),
        // Zed Keybind Context is the Rust grammar with its own highlights.
        "zed-keybind-context" => Some(tree_sitter_rust::LANGUAGE.into()),
        "c" => Some(tree_sitter_c::LANGUAGE.into()),
        "cpp" => Some(tree_sitter_cpp::LANGUAGE.into()),
        "css" => Some(tree_sitter_css::LANGUAGE.into()),
        "json" | "jsonc" => Some(tree_sitter_json::LANGUAGE.into()),
        "markdown" => Some(tree_sitter_md::LANGUAGE.into()),
        "markdown-inline" => Some(tree_sitter_md::INLINE_LANGUAGE.into()),
        _ => None,
    }
}

// The generated parsers of tree-sitter-html (rev bfa075d8), -toml, -git-config and -gitignore, vendored and compiled by
// `build.rs` (each folder's SOURCE.md says why they are not crates).
unsafe extern "C" {
    fn tree_sitter_html() -> *const ();
    fn tree_sitter_toml() -> *const ();
    fn tree_sitter_git_config() -> *const ();
    fn tree_sitter_gitignore() -> *const ();
}

/// A vendored parser's language.
fn vendored(entry: unsafe extern "C" fn() -> *const ()) -> Language {
    // SAFETY: `entry` is the generated entry point of a C parser (ABI 13 or 14) linked by `build.rs`.
    unsafe { tree_sitter_language::LanguageFn::from_raw(entry) }.into()
}

/// What `injections.scm` of one language says (Zed `syntax_map.rs`): the content and optional language captures, and per
/// pattern the `#set! injection.language` name and whether `injection.combined` is set.
struct InjectionConfig {
    query_ix: usize,
    content: Option<u32>,
    language: Option<u32>,
    patterns: Vec<InjectionPattern>,
    combined: bool,
}

struct InjectionPattern {
    language: Option<String>,
    combined: bool,
}

fn injection_config(query: &Query, query_ix: usize) -> InjectionConfig {
    let patterns: Vec<InjectionPattern> = (0..query.pattern_count()).map(|ix| {
        let settings = query.property_settings(ix);
        InjectionPattern {
            language: settings.iter().find(|p| &*p.key == "injection.language").and_then(|p| p.value.as_deref()).map(str::to_string),
            combined: settings.iter().any(|p| &*p.key == "injection.combined"),
        }
    }).collect();
    InjectionConfig {
        query_ix,
        content: query.capture_index_for_name("injection.content"),
        language: query.capture_index_for_name("injection.language"),
        combined: patterns.iter().any(|p| p.combined),
        patterns,
    }
}

pub struct QueryResources {
    queries: HashMap<&'static str, Vec<Query>>,
    injections: HashMap<&'static str, InjectionConfig>,
    errors: Vec<String>,
}

impl QueryResources {
    pub fn load(root: &Path) -> Self {
        let mut resources = Self { queries: HashMap::new(), injections: HashMap::new(), errors: Vec::new() };
        for spec in LANGUAGES {
            let Some(language) = grammar(spec.id) else { continue };
            match load_queries(root, spec.id, &language) {
                Ok(queries) => {
                    if let Some(ix) = query_files(spec.id).iter().position(|name| *name == "injections.scm") {
                        resources.injections.insert(spec.id, injection_config(&queries[ix], ix));
                    }
                    resources.queries.insert(spec.id, queries);
                }
                Err(error) => resources.errors.push(format!("{} ({}): {error}", spec.name, spec.grammar)),
            }
        }
        resources
    }

    /// The injections query of a language and what it says; None if the language has none.
    fn injection(&self, id: &str) -> Option<(&Query, &InjectionConfig)> {
        let config = self.injections.get(id)?;
        Some((self.queries.get(id)?.get(config.query_ix)?, config))
    }

    /// None means plain text; a partial or invalid query set is never installed.
    pub fn queries(&self, id: &str) -> Option<&[Query]> {
        self.queries.get(id).map(Vec::as_slice)
    }
}

/// The query files Zed ships for a language, in the order they are compiled (highlights first).
fn query_files(id: &str) -> &'static [&'static str] {
    match id {
        "json" => &["highlights.scm", "outline.scm"],
        // Zed ships no outline query for these (K-41 4장).
        "jsdoc" | "regex" | "zed-keybind-context" => &["highlights.scm"],
        "markdown-inline" | "bash" | "diff" | "env" | "gitcommit" | "gomod" | "gowork" | "gitattributes" | "gitconfig" | "gitignore" | "gitrebase" => {
            &["highlights.scm", "injections.scm"]
        }
        _ => &["highlights.scm", "injections.scm", "outline.scm"],
    }
}

fn load_queries(root: &Path, id: &str, language: &Language) -> Result<Vec<Query>, String> {
    Parser::new().set_language(language).map_err(|error| error.to_string())?;
    query_files(id).iter().map(|name| {
        let path = root.join(id).join(name);
        let source = std::fs::read_to_string(&path).map_err(|error| format!("{}: {error}", path.display()))?;
        Query::new(language, &source).map_err(|error| format!("{}: {error}", path.display()))
    }).collect()
}

pub fn resources() -> &'static QueryResources {
    static RESOURCES: OnceLock<QueryResources> = OnceLock::new();
    RESOURCES.get_or_init(|| {
        let root = super::zed_icons::resources_dir().join("zed-languages");
        let resources = QueryResources::load(&root);
        if !resources.errors.is_empty() {
            eprintln!("Local Zed queries unavailable; using plain text: {}", resources.errors.join("; "));
        }
        resources
    })
}

pub fn init() {
    resources();
}

/// The theme's `style.syntax` table: key -> style. A key with no colour is still a key (Zed: it stops the lookup and
/// paints the default colour over an outer capture).
pub struct SyntaxTheme {
    id: u64,
    styles: HashMap<String, HighlightStyle>,
}

impl SyntaxTheme {
    pub fn new(styles: HashMap<String, HighlightStyle>) -> Self {
        static NEXT: AtomicU64 = AtomicU64::new(1);
        Self { id: NEXT.fetch_add(1, Ordering::Relaxed), styles }
    }

    /// R-15 (Zed `syntax_theme.rs:87-102`): the longest dot-boundary prefix of the capture name that is a theme key.
    pub fn style(&self, capture: &str) -> Option<HighlightStyle> {
        let mut name = capture;
        loop {
            if let Some(style) = self.styles.get(name) { return Some(*style); }
            name = name.rsplit_once('.')?.0;
        }
    }
}

static THEME: RwLock<Option<Arc<SyntaxTheme>>> = RwLock::new(None);

/// Replaces the colours of every editor (`theme::apply`). Editors read it on their next paint.
pub fn set_theme(styles: HashMap<String, HighlightStyle>) {
    *THEME.write().unwrap_or_else(|e| e.into_inner()) = Some(Arc::new(SyntaxTheme::new(styles)));
    *PREVIEW_HIGHLIGHTER.write().unwrap_or_else(|e| e.into_inner()) = None;
}

fn current_theme() -> Option<Arc<SyntaxTheme>> {
    THEME.read().unwrap_or_else(|e| e.into_inner()).clone()
}

/// Node text for query predicates (`#match?`, `#eq?`), read straight from the rope.
struct RopeText<'a>(&'a Rope);

impl<'a> TextProvider<&'a [u8]> for RopeText<'a> {
    type I = Box<dyn Iterator<Item = &'a [u8]> + 'a>;

    fn text(&mut self, node: Node) -> Self::I {
        match self.0.try_slice(node.byte_range()) {
            Ok(slice) => Box::new(slice.chunks().map(str::as_bytes)),
            Err(_) => Box::new(std::iter::empty()),
        }
    }
}

fn ts_edit(edit: &InputEdit) -> TsEdit {
    let point = |p: gpui_kit::base::input::Point| TsPoint::new(p.row, p.column);
    TsEdit {
        start_byte: edit.start_byte,
        old_end_byte: edit.old_end_byte,
        new_end_byte: edit.new_end_byte,
        start_position: point(edit.start_position),
        old_end_position: point(edit.old_end_position),
        new_end_position: point(edit.new_end_position),
    }
}

/// Ordered, gap-free style runs over `range` from `captures` (start, end, style) in query order. Zed
/// (`buffer.rs:5909-5922, 5967-5972`): captures stack by start order and only the last one still covering a byte
/// gives its colour; a capture without a theme key is not in `captures` at all, so the outer colour stays.
fn style_runs(range: &Range<usize>, captures: &[(usize, usize, HighlightStyle)]) -> Vec<(Range<usize>, HighlightStyle)> {
    let mut runs: Vec<(Range<usize>, HighlightStyle)> = Vec::new();
    let mut stack: Vec<(usize, HighlightStyle)> = Vec::new();
    let (mut next, mut pos) = (0, range.start);
    while pos < range.end {
        while let Some(&(_, end, style)) = captures.get(next).filter(|c| c.0 <= pos) {
            stack.push((end, style));
            next += 1;
        }
        stack.retain(|(end, _)| *end > pos);
        let mut end = range.end;
        if let Some(capture) = captures.get(next) { end = end.min(capture.0); }
        if let Some(stack_end) = stack.iter().map(|s| s.0).min() { end = end.min(stack_end); }
        let style = stack.last().map(|s| s.1).unwrap_or_default();
        match runs.last_mut() {
            Some((run, last)) if *last == style => run.end = end,
            _ => runs.push((pos..end, style)),
        }
        pos = end;
    }
    runs
}

/// Case-insensitive match of an injection language name against language names and file suffixes (Zed
/// `available_languages.rs` `find_by_name_or_extension`: the first language in registration order wins). None for a
/// name no language has, or one whose grammar or queries are not available.
fn injection_language(resources: &QueryResources, name: &str) -> Option<&'static str> {
    let name = name.to_lowercase();
    let spec = LANGUAGES.iter().find(|language| {
        language.name.to_lowercase() == name || language.suffixes.iter().any(|suffix| suffix.to_lowercase() == name)
    })?;
    resources.queries(spec.id).map(|_| spec.id)
}

/// An injected syntax layer nests this deep at most (Markdown -> code block -> HTML -> CSS/JS -> ...).
// shortcut: a fixed depth limit instead of Zed's unbounded nesting; raise it if a real file needs more.
const MAX_LAYER_DEPTH: usize = 6;

/// One parse tree of a language over some byte ranges of the text: the file's own language is the root; injected
/// languages are child layers (K-44).
struct Layer {
    id: &'static str,
    depth: usize,
    tree: Tree,
    /// Bytes this layer stands for: its content (plus the language name of a fence). Shifts with edits.
    host: Range<usize>,
    /// Built from every `injection.combined` match of its parent as one document.
    combined: bool,
    children: Vec<Layer>,
}

/// An injection found by a parent layer's `injections.scm`.
struct Candidate {
    id: &'static str,
    ranges: Vec<TsRange>,
    host: Range<usize>,
    combined: bool,
}

fn touches(host: &Range<usize>, changed: &[Range<usize>]) -> bool {
    changed.iter().any(|r| r.start <= host.end && r.end >= host.start)
}

/// A byte position after `edit` (a position inside the replaced text goes to the start, or to the end for a range end).
fn shift(position: usize, edit: &TsEdit, is_end: bool) -> usize {
    if position >= edit.old_end_byte {
        // Saturating: the root layer's host end is usize::MAX.
        (position - edit.old_end_byte).saturating_add(edit.new_end_byte)
    } else if position > edit.start_byte {
        if is_end { edit.new_end_byte } else { edit.start_byte }
    } else {
        position
    }
}

// shortcut: every layer's tree is edited on every edit, so an edit costs as many `Tree::edit` calls as there are layers
// (one per Markdown paragraph). Measured to be small next to the root reparse; keep an edit log that layers catch up
// with when used if a file with very many layers stalls.
fn edit_layer(layer: &mut Layer, edit: &TsEdit) {
    layer.tree.edit(edit);
    layer.host = shift(layer.host.start, edit, false)..shift(layer.host.end, edit, true);
    for child in &mut layer.children { edit_layer(child, edit); }
}

fn parse_layer(parsers: &mut HashMap<&'static str, Parser>, id: &'static str, text: &Rope, ranges: &[TsRange], old: Option<&Tree>) -> Option<Tree> {
    if !parsers.contains_key(id) {
        let mut parser = Parser::new();
        parser.set_language(&grammar(id)?).ok()?;
        parsers.insert(id, parser);
    }
    let parser = parsers.get_mut(id)?;
    parser.set_included_ranges(ranges).ok()?;
    let mut read = |byte: usize, _: TsPoint| -> &[u8] {
        if byte >= text.len() { return &[]; }
        let (chunk, start) = text.chunk(byte);
        &chunk.as_bytes()[byte - start..]
    };
    parser.parse_with_options(&mut read, old, None)
}

/// A combined layer reads its pieces as separate lines (Zed `insert_newlines_between_ranges`): where two pieces are on
/// different rows, the line break after the first becomes part of the layer.
fn insert_newlines(text: &Rope, ranges: &mut Vec<TsRange>) {
    use gpui_kit::base::input::RopeExt;
    let mut ix = ranges.len();
    while ix > 1 {
        ix -= 1;
        let (a, b) = (ranges[ix - 1], ranges[ix]);
        if a.end_point.column == 0 || a.end_point.row >= b.start_point.row { continue; }
        let line_end = text.line_end_offset(a.end_point.row);
        if a.end_byte >= line_end {
            ranges[ix - 1].end_byte += 1;
            ranges[ix - 1].end_point = TsPoint::new(a.end_point.row + 1, 0);
        } else {
            let line_start = text.line_start_offset(a.end_point.row);
            ranges.insert(ix, TsRange {
                start_byte: line_end,
                end_byte: line_end + 1,
                start_point: TsPoint::new(a.end_point.row, line_end - line_start),
                end_point: TsPoint::new(a.end_point.row + 1, 0),
            });
        }
    }
}

/// The children of `root` that touch `window`, or `root` itself when it has none there. An injection query runs on each of
/// them instead of on the root: a pattern like `(comment) @c [(string) ...]` looks at every later sibling of each
/// comment, which on the root of a big file (thousands of top-level nodes) costs tens of ms per edited byte and
/// quadratic time in the first parse. A pattern that needs the root itself or two top-level siblings would be missed;
/// none of the injection queries has one (K-49 measured and compared the colours of the sample files).
fn top_level_nodes<'t>(root: Node<'t>, window: &Range<usize>) -> Vec<Node<'t>> {
    let mut nodes = Vec::new();
    let mut walker = root.walk();
    if walker.goto_first_child_for_byte(window.start).is_some() {
        loop {
            let node = walker.node();
            if node.start_byte() > window.end { break; }
            nodes.push(node);
            if !walker.goto_next_sibling() { break; }
        }
    }
    if nodes.is_empty() { nodes.push(root); }
    nodes
}

/// Runs `layer`'s injection query over the `changed` bytes (the whole layer if it has combined patterns) and rebuilds
/// the child layers those bytes touch. A rebuilt child reuses the old child's tree of the same language, so editing
/// inside a code block reparses it incrementally.
fn refresh(
    parsers: &mut HashMap<&'static str, Parser>,
    resources: &'static QueryResources,
    text: &Rope,
    layer: &mut Layer,
    changed: &[Range<usize>],
    edited: &[Range<usize>],
) {
    let Some((query, config)) = resources.injection(layer.id) else {
        layer.children.clear();
        return;
    };
    if layer.depth >= MAX_LAYER_DEPTH { return; }
    let whole = layer.host.start..layer.host.end.min(text.len());
    let changed = if config.combined { std::slice::from_ref(&whole) } else { changed };
    let mut stale = Vec::new();
    let mut ix = 0;
    while ix < layer.children.len() {
        if touches(&layer.children[ix].host, changed) { stale.push(layer.children.remove(ix)); } else { ix += 1; }
    }
    let mut candidates: Vec<Candidate> = Vec::new();
    let mut combined: Vec<(&'static str, Vec<TsRange>)> = Vec::new();
    let mut seen = std::collections::HashSet::new();
    let mut cursor = QueryCursor::new();
    for range in changed {
        let window = range.start.saturating_sub(1)..range.end.saturating_add(1);
        cursor.set_byte_range(window.clone());
        for top in top_level_nodes(layer.tree.root_node(), &window) {
            let mut matches = cursor.matches(query, top, RopeText(text));
            while let Some(found) = matches.next() {
                let Some(content) = config.content else { continue };
                let nodes: Vec<TsRange> = found.nodes_for_capture_index(content).map(|node| node.range()).collect();
                let (Some(first), Some(last)) = (nodes.first(), nodes.last()) else { continue };
                if !seen.insert((found.pattern_index, first.start_byte, last.end_byte)) { continue; }
                let pattern = &config.patterns[found.pattern_index];
                let mut host = first.start_byte..last.end_byte;
                let name = match (&pattern.language, config.language) {
                    (Some(name), _) => name.clone(),
                    (None, Some(language)) => {
                        let Some(node) = found.nodes_for_capture_index(language).next() else { continue };
                        host = host.start.min(node.start_byte())..host.end.max(node.end_byte());
                        // A path ending in a language's suffix names that language: "foo/bar/baz.rs" -> "rs".
                        let name = text.slice(node.byte_range()).to_string();
                        name.rsplit_once('.').map_or(name.clone(), |(_, suffix)| suffix.to_string())
                    }
                    (None, None) => continue,
                };
                let Some(id) = injection_language(resources, &name) else { continue };
                if pattern.combined {
                    match combined.iter_mut().find(|(language, _)| *language == id) {
                        Some((_, ranges)) => ranges.extend(nodes),
                        None => combined.push((id, nodes)),
                    }
                } else {
                    candidates.push(Candidate { id, ranges: nodes, host, combined: false });
                }
            }
        }
    }
    for (id, mut ranges) in combined {
        ranges.sort_by_key(|r| (r.start_byte, r.end_byte));
        ranges.dedup();
        insert_newlines(text, &mut ranges);
        let host = ranges.first().map_or(0, |r| r.start_byte)..ranges.last().map_or(0, |r| r.end_byte);
        candidates.push(Candidate { id, ranges, host, combined: true });
    }
    for candidate in candidates {
        if layer.children.iter().any(|c| c.id == candidate.id && c.combined == candidate.combined && c.host == candidate.host) { continue; }
        let overlaps = |s: &Layer| s.id == candidate.id && s.combined == candidate.combined && s.host.start < candidate.host.end && s.host.end > candidate.host.start;
        let old = stale.iter().position(overlaps).map(|ix| stale.remove(ix));
        let Some(tree) = parse_layer(parsers, candidate.id, text, &candidate.ranges, old.as_ref().map(|l| &l.tree)) else { continue };
        let child_changed = changed_bytes(old.as_ref().map(|l| &l.tree), &tree, edited, &candidate.host);
        let mut child = Layer {
            id: candidate.id,
            depth: layer.depth + 1,
            tree,
            host: candidate.host,
            combined: candidate.combined,
            children: old.map(|old| old.children).unwrap_or_default(),
        };
        if !child_changed.is_empty() { refresh(parsers, resources, text, &mut child, &child_changed, edited); }
        layer.children.push(child);
    }
}

/// The layer tree of `text`: the file's own syntax tree (reparsed from `old` when there is one) and its injected layers.
fn build_root(
    parsers: &mut HashMap<&'static str, Parser>,
    resources: &'static QueryResources,
    id: &'static str,
    text: &Rope,
    old: Option<Layer>,
    edited: &[Range<usize>],
) -> Option<Layer> {
    let tree = parse_layer(parsers, id, text, &[], old.as_ref().map(|l| &l.tree))?;
    let changed = changed_bytes(old.as_ref().map(|l| &l.tree), &tree, edited, &(0..text.len()));
    let mut root = Layer {
        id,
        depth: 0,
        tree,
        host: 0..usize::MAX,
        combined: false,
        children: old.map(|old| old.children).unwrap_or_default(),
    };
    refresh(parsers, resources, text, &mut root, &changed, edited);
    Some(root)
}

/// The bytes of `new` that may differ from `old`: where the trees differ plus the edited bytes (Zed joins the edits
/// with the tree changes: a change that only lengthens a leaf is not a tree change). A layer with no old tree is new
/// from start to end.
fn changed_bytes(old: Option<&Tree>, new: &Tree, edited: &[Range<usize>], whole: &Range<usize>) -> Vec<Range<usize>> {
    let Some(old) = old else { return vec![whole.clone()] };
    let mut changed: Vec<Range<usize>> = old.changed_ranges(new).map(|r| r.start_byte..r.end_byte).collect();
    changed.extend(edited.iter().filter(|r| r.start <= whole.end && r.end >= whole.start).cloned());
    changed
}

fn collect_layers<'a>(layer: &'a Layer, range: &Range<usize>, out: &mut Vec<&'a Layer>) {
    if layer.host.start < range.end && layer.host.end > range.start {
        out.push(layer);
        for child in &layer.children { collect_layers(child, range, out); }
    }
}

/// Tree-sitter highlighter for one editor: the file's own syntax tree plus a layer per injected language, the shared
/// per-language queries.
// shortcut: edits are parsed incrementally on the UI thread; only the first parse of a file runs on a background thread
// (K-50, `run_full_parse`). Zed parses every change in the background; move `reparse` to a task too if typing stalls.
// K-49 (release, one character in the middle): 12k-45k-line TypeScript/Rust 3-26 ms, a 10k-line Markdown about 14 ms
// (60 ms for the first edit after opening).
struct SyntaxHighlighter {
    id: &'static str,
    resources: &'static QueryResources,
    parsers: HashMap<&'static str, Parser>,
    root: Option<Layer>,
    text: Rope,
    /// Bytes edited since the last parse, in the coordinates of the text after the latest edit.
    edited: Vec<Range<usize>>,
    /// Theme id and, per language, the resolved style of every capture index of its highlights query.
    colors: RefCell<Option<(u64, CaptureStyles)>>,
    parse: ParseState,
}

/// K-50: the first parse of a file runs off the UI thread. Until it is back the highlighter has no tree and gives plain
/// text and no symbols.
#[derive(Default)]
struct ParseState {
    generation: u64,
    /// The full parse in flight: its generation and the edits made to the text since it started, in order.
    flight: Option<(u64, Vec<InputEdit>)>,
    /// The foreground task that waits for the full parse; dropping it (with the highlighter) abandons the wait.
    task: Option<gpui_kit::Task<()>>,
}

/// A full parse of a text (root and injected layers), everything it needs owned so it can run on a background thread.
struct FullParse {
    resources: &'static QueryResources,
    id: &'static str,
    text: Rope,
    generation: u64,
}

struct Parsed {
    generation: u64,
    root: Option<Layer>,
    parsers: HashMap<&'static str, Parser>,
}

impl FullParse {
    fn run(self) -> Parsed {
        let mut parsers = HashMap::new();
        let root = build_root(&mut parsers, self.resources, self.id, &self.text, None, &[]);
        Parsed { generation: self.generation, root, parsers }
    }
}

/// Zed `buffer.rs` 1177: how long the UI thread waits for a parse before it goes on without one.
const SYNC_PARSE_TIMEOUT: std::time::Duration = std::time::Duration::from_millis(1);

/// Per language id, the style of every capture index of its highlights query under one theme.
type CaptureStyles = HashMap<&'static str, Vec<Option<HighlightStyle>>>;

/// A layer's mapped captures (start, end, style) in query order.
type LayerCaptures = Vec<(usize, usize, HighlightStyle)>;

impl SyntaxHighlighter {
    fn new(resources: &'static QueryResources, id: &str) -> Option<Self> {
        let spec = LANGUAGES.iter().find(|language| language.id == id)?;
        grammar(spec.id)?;
        resources.queries(spec.id)?.first()?;
        Some(Self { id: spec.id, resources, parsers: HashMap::new(), root: None, text: Rope::new(), edited: Vec::new(), colors: RefCell::new(None), parse: ParseState::default() })
    }

    fn edit(&mut self, edit: &InputEdit) {
        let edit = ts_edit(edit);
        // Earlier edits of the same change move with this one; this one is the newest range.
        for range in &mut self.edited { *range = shift(range.start, &edit, false)..shift(range.end, &edit, true); }
        self.edited.push(edit.start_byte..edit.new_end_byte);
        if let Some(root) = &mut self.root { edit_layer(root, &edit); }
    }

    fn reparse(&mut self, text: &Rope) {
        self.text = text.clone();
        let old = self.root.take();
        let edited = std::mem::take(&mut self.edited);
        self.root = build_root(&mut self.parsers, self.resources, self.id, text, old, &edited);
    }

    /// K-50: a change of the text. Returns the full parse to start off the UI thread when there is no tree to edit yet
    /// (the first parse of a file). While such a parse is in flight the edits are only logged; `finish` replays them on
    /// the tree it gets.
    fn changed(&mut self, edits: &[(InputEdit, Rope)]) -> Option<FullParse> {
        let (_, last) = edits.last()?;
        if let Some((_, log)) = &mut self.parse.flight {
            log.extend(edits.iter().map(|(edit, _)| *edit));
            self.text = last.clone();
            return None;
        }
        if self.root.is_none() { return Some(self.start_full(last)); }
        for (edit, _) in edits { self.edit(edit); }
        self.reparse(last);
        None
    }

    /// Forgets the tree and starts a full parse of `text`; an earlier one in flight is abandoned (its result no longer
    /// matches the generation).
    fn start_full(&mut self, text: &Rope) -> FullParse {
        self.root = None;
        self.edited.clear();
        self.text = text.clone();
        self.parse.generation += 1;
        self.parse.flight = Some((self.parse.generation, Vec::new()));
        self.parse.task = None;
        FullParse { resources: self.resources, id: self.id, text: text.clone(), generation: self.parse.generation }
    }

    /// Installs the result of a full parse when it is still the one in flight (false: it was abandoned, nothing
    /// changes). Edits made meanwhile are applied to the new tree and reparsed incrementally, as if it had been there.
    fn finish(&mut self, done: Parsed) -> bool {
        match self.parse.flight.take() {
            Some((generation, log)) if generation == done.generation => {
                self.parsers.extend(done.parsers);
                self.root = done.root;
                if self.root.is_some() && !log.is_empty() {
                    for edit in &log { self.edit(edit); }
                    let text = self.text.clone();
                    self.reparse(&text);
                }
                true
            }
            other => {
                self.parse.flight = other;
                false
            }
        }
    }

    fn runs(&self, range: &Range<usize>, theme: Option<&SyntaxTheme>) -> Vec<(Range<usize>, HighlightStyle)> {
        let Some(root) = &self.root else { return vec![(range.clone(), HighlightStyle::default())] };
        let theme_id = theme.map_or(0, |t| t.id);
        let mut cache = self.colors.borrow_mut();
        if cache.as_ref().is_none_or(|(id, _)| *id != theme_id) { *cache = Some((theme_id, HashMap::new())); }
        let colors = &mut cache.as_mut().expect("filled above").1;
        let mut layers = Vec::new();
        collect_layers(root, range, &mut layers);
        // Each layer's mapped captures in query order, then merged as Zed does (`syntax_map.rs` `sort_key`): by start,
        // longer first, then shallower first - so at the same range the deeper (injected) layer ends up on top.
        let mut streams: Vec<(usize, LayerCaptures)> = Vec::new();
        for layer in layers {
            let Some(query) = self.resources.queries(layer.id).and_then(|q| q.first()) else { continue };
            let styles = colors.entry(layer.id).or_insert_with(|| {
                query.capture_names().iter().map(|name| theme.and_then(|t| t.style(name))).collect()
            });
            let mut cursor = QueryCursor::new();
            cursor.set_byte_range(range.clone());
            let mut captures = Vec::new();
            let mut matches = cursor.captures(query, layer.tree.root_node(), RopeText(&self.text));
            while let Some((found, index)) = matches.next() {
                let capture = found.captures()[*index];
                if let Some(Some(style)) = styles.get(capture.index as usize) {
                    let bytes = capture.node.byte_range();
                    captures.push((bytes.start, bytes.end, *style));
                }
            }
            streams.push((layer.depth, captures));
        }
        let mut merged = Vec::new();
        let mut heads = vec![0; streams.len()];
        loop {
            let next = streams.iter().enumerate()
                .filter_map(|(ix, (depth, captures))| captures.get(heads[ix]).map(|c| ((c.0, std::cmp::Reverse(c.1), *depth), ix)))
                .min_by_key(|(key, _)| *key);
            let Some((_, ix)) = next else { break };
            merged.push(streams[ix].1[heads[ix]]);
            heads[ix] += 1;
        }
        style_runs(range, &merged)
    }
}

/// The outline query of a language, if Zed ships one.
fn outline_query<'a>(resources: &'a QueryResources, id: &str) -> Option<&'a Query> {
    let ix = query_files(id).iter().position(|name| *name == "outline.scm")?;
    resources.queries.get(id)?.get(ix)
}

/// A symbol of the syntax around an offset (an outline item such as `impl Counter` or `pub fn bump`): its text and the
/// highlight runs over that text, in the same styles the editor paints the code with.
#[derive(Debug, Clone, Default, PartialEq)]
pub struct OutlineSymbol {
    pub text: String,
    pub runs: Vec<(Range<usize>, HighlightStyle)>,
}

struct SymbolItem {
    range: Range<usize>,
    symbol: OutlineSymbol,
}

impl SyntaxHighlighter {
    /// The symbols that contain `offset`, outermost first (Zed `buffer.rs` `symbols_containing`, 4782-4797 and
    /// 4890-5110): every `@item` match of every layer's outline query that touches `offset +- 1`, sorted by start then
    /// longest first, nested by containment, and only the strictly deepening chain kept. The text of a symbol is its
    /// `@name` and `@context` nodes (not `@context.extra`) in capture order, a space where the source has a gap, a
    /// multi-line node cut at the end of its first line.
    fn symbols(&self, offset: usize, theme: Option<&SyntaxTheme>) -> Vec<OutlineSymbol> {
        use gpui_kit::base::input::RopeExt;
        let Some(root) = &self.root else { return Vec::new() };
        let len = self.text.len();
        let mut start = offset.saturating_sub(1).min(len);
        while !self.text.is_char_boundary(start) { start -= 1; }
        let mut end = (offset + 1).min(len);
        while !self.text.is_char_boundary(end) { end += 1; }
        let range = start..end;
        let mut layers = Vec::new();
        collect_layers(root, &range, &mut layers);
        let mut items: Vec<SymbolItem> = Vec::new();
        for layer in layers {
            let Some(query) = outline_query(self.resources, layer.id) else { continue };
            let (item_ix, name_ix, context_ix) = (
                query.capture_index_for_name("item"),
                query.capture_index_for_name("name"),
                query.capture_index_for_name("context"),
            );
            let mut cursor = QueryCursor::new();
            cursor.set_byte_range(range.clone());
            let mut matches = cursor.matches(query, layer.tree.root_node(), RopeText(&self.text));
            while let Some(found) = matches.next() {
                let Some(item) = found.captures().iter().find(|c| Some(c.index) == item_ix).map(|c| c.node.byte_range()) else { continue };
                if item.end < range.start || item.start > range.end { continue; }
                let mut pieces: Vec<Range<usize>> = Vec::new();
                let mut has_name = false;
                for capture in found.captures() {
                    let is_name = Some(capture.index) == name_ix;
                    if !is_name && Some(capture.index) != context_ix { continue; }
                    let mut piece = capture.node.byte_range();
                    let row = capture.node.start_position().row;
                    if capture.node.end_position().row > row { piece.end = self.text.line_end_offset(row); }
                    if piece.is_empty() { continue; }
                    has_name |= is_name;
                    pieces.push(piece);
                }
                if !has_name { continue; }
                let mut symbol = OutlineSymbol::default();
                let mut last_end = 0;
                for piece in pieces {
                    if !symbol.text.is_empty() && piece.start > last_end { symbol.text.push(' '); }
                    let base = symbol.text.len();
                    symbol.text.push_str(&self.text.slice(piece.clone()).to_string());
                    for (run, style) in self.runs(&piece, theme) {
                        if style != HighlightStyle::default() {
                            symbol.runs.push((base + run.start - piece.start..base + run.end - piece.start, style));
                        }
                    }
                    last_end = piece.end;
                }
                items.push(SymbolItem { range: item, symbol });
            }
        }
        items.sort_by_key(|item| (item.range.start, std::cmp::Reverse(item.range.end)));
        let mut ends: Vec<usize> = Vec::new();
        let mut previous_depth: Option<usize> = None;
        let mut symbols = Vec::new();
        for item in items {
            while ends.last().is_some_and(|last| *last < item.range.end) { ends.pop(); }
            let depth = ends.len();
            ends.push(item.range.end);
            if previous_depth.is_none_or(|previous| depth > previous) { symbols.push(item.symbol); }
            previous_depth = Some(depth);
        }
        symbols
    }
}


/// The editor owns its highlighter as a `Box<dyn InputHighlighter>`; this shares the parse state with the app so the
/// breadcrumb can ask for symbols without a change in the editor crate (K-45-R1).
type Shared = Rc<RefCell<SyntaxHighlighter>>;

struct SharedHighlighter(Shared);

impl InputHighlighter for SharedHighlighter {
    fn language(&self) -> gpui_kit::SharedString {
        self.0.borrow().id.into()
    }

    /// `None` is a full reset (the text was replaced); `Some` is an edit of the text the highlighter has seen, or, for a
    /// new highlighter, the first look at the text.
    fn update(&mut self, edit: Option<InputEdit>, text: &Rope, _folding: bool, _window: &mut Window, cx: &mut Context<EditorState>) {
        let job = match edit {
            Some(edit) => self.0.borrow_mut().changed(&[(edit, text.clone())]),
            None => Some(self.0.borrow_mut().start_full(text)),
        };
        if let Some(job) = job { run_full_parse(&self.0, job, cx); }
    }

    /// One reparse for the whole change; every edit still reaches the tree in the order it was made.
    fn update_batch(&mut self, edits: &[(InputEdit, Rope)], _folding: bool, _window: &mut Window, cx: &mut Context<EditorState>) {
        let job = self.0.borrow_mut().changed(edits);
        if let Some(job) = job { run_full_parse(&self.0, job, cx); }
    }

    fn styles(&self, range: &Range<usize>, _resolver: &dyn HighlightStyleResolver) -> Vec<(Range<usize>, HighlightStyle)> {
        self.0.borrow().runs(range, current_theme().as_deref())
    }

    // Folding is not part of this card.
    fn fold_ranges(&self, _text: &Rope) -> Vec<FoldRange> {
        Vec::new()
    }
}

/// K-50, Zed `buffer.rs` 1943-2010: parses on a background thread and waits `SYNC_PARSE_TIMEOUT` for it; a small file is
/// done by then and nothing flickers. A big one goes on in the background: until it is back the file is plain text; when
/// it arrives (and was not abandoned by a restart) the highlighter takes the tree and the editor repaints. The wait holds
/// the highlighter only weakly, so closing the file or giving the editor another highlighter drops the result.
fn run_full_parse(shared: &Shared, job: FullParse, cx: &mut Context<EditorState>) {
    let work = cx.background_executor().spawn(async move { job.run() });
    match cx.foreground_executor().block_with_timeout(SYNC_PARSE_TIMEOUT, work) {
        Ok(done) => { shared.borrow_mut().finish(done); }
        Err(rest) => {
            let weak = Rc::downgrade(shared);
            let task = cx.spawn(async move |editor, cx| {
                let done = rest.await;
                let Some(shared) = weak.upgrade() else { return };
                let applied = shared.borrow_mut().finish(done);
                if applied { editor.update(cx, |editor, cx| editor.refresh(cx)).ok(); }
            });
            shared.borrow_mut().parse.task = Some(task);
        }
    }
}

/// What the app keeps next to one editor: the highlighter its factory made last (None for plain text), shared with the
/// editor, and the soft wrap the language wants against what the editor has been given.
#[derive(Clone, Default)]
pub struct EditorExtras {
    highlighter: Rc<RefCell<Option<Shared>>>,
    wrap: Rc<Cell<WrapState>>,
}

/// Soft wrap of one editor. An editor starts wrapped (the editor crate's default).
#[derive(Clone, Copy)]
struct WrapState {
    wanted: bool,
    applied: bool,
}

impl Default for WrapState {
    fn default() -> Self {
        Self { wanted: true, applied: true }
    }
}

/// The wrap value to give the editor now: `wanted` when it differs from what the editor has, else nothing.
fn wrap_to_apply(applied: bool, wanted: bool) -> Option<bool> {
    (applied != wanted).then_some(wanted)
}

impl EditorExtras {
    /// The symbols that contain `offset`, outermost first; empty without a highlighter or while it is being updated.
    fn symbols_at(&self, offset: usize) -> Vec<OutlineSymbol> {
        let Some(shared) = self.highlighter.borrow().clone() else { return Vec::new() };
        shared.try_borrow().map_or_else(|_| Vec::new(), |h| h.symbols(offset, current_theme().as_deref()))
    }
}

/// Installed once per editor; the editor asks it again for a highlighter after every `set_value` and language change.
/// It gives None (plain text) for an unknown language (a `LANGUAGES` id), one whose grammar is not linked yet, or one
/// whose local query copy is missing. `extras` follows the highlighter the editor was given last.
pub fn highlighter_factory(extras: &EditorExtras) -> InputHighlighterFactory {
    let slot = extras.highlighter.clone();
    Rc::new(move |id| {
        let made = SyntaxHighlighter::new(resources(), id).map(|h| Rc::new(RefCell::new(h)));
        *slot.borrow_mut() = made.clone();
        Some(Box::new(SharedHighlighter(made?)))
    })
}

/// Per editor, the app's `EditorExtras`.
#[derive(Default)]
struct AllExtras(HashMap<EntityId, EditorExtras>);

impl Global for AllExtras {}

/// Remembers `extras` (the ones given to `highlighter_factory` for `editor`). Those of dropped editors (nothing but this
/// map holds their highlighter slot any more) are forgotten.
pub fn register_extras(editor: &Entity<EditorState>, extras: EditorExtras, cx: &mut App) {
    let map = &mut cx.default_global::<AllExtras>().0;
    map.retain(|_, e| Rc::strong_count(&e.highlighter) > 1);
    map.insert(editor.entity_id(), extras);
}

fn extras_of(editor: &Entity<EditorState>, cx: &App) -> Option<EditorExtras> {
    cx.try_global::<AllExtras>().and_then(|map| map.0.get(&editor.entity_id())).cloned()
}

/// The symbols around `offset` in `editor`, outermost first (Zed's breadcrumb symbol path); empty for plain text.
pub fn symbols_at(editor: &Entity<EditorState>, offset: usize, cx: &App) -> Vec<OutlineSymbol> {
    extras_of(editor, cx).map_or_else(Vec::new, |e| e.symbols_at(offset))
}

/// Gives `editor` the soft wrap its language wants if it does not have it yet. Called where a `Window` is at hand (the
/// editor crate's `set_soft_wrap` takes one), once per frame for the shown editors; the common case is a comparison.
pub fn sync_soft_wrap(editor: &Entity<EditorState>, window: &mut Window, cx: &mut App) {
    let Some(extras) = extras_of(editor, cx) else { return };
    let state = extras.wrap.get();
    if let Some(wrap) = wrap_to_apply(state.applied, state.wanted) {
        extras.wrap.set(WrapState { applied: wrap, ..state });
        editor.update(cx, |editor, cx| editor.set_soft_wrap(wrap, window, cx));
    }
}


/// K-46: the language id of a code fence's info string, as Zed's markdown preview finds it (`markdown.rs` 1334-1345,
/// `parser.rs` 425-439): trimmed; empty is no language; a `/` makes it a file path (an `:10-20` line range after it is
/// dropped); else a language name or file suffix in any case, and when that fails and there is a space, the first word.
fn fence_language(resources: &QueryResources, info: &str) -> Option<&'static str> {
    let info = info.trim();
    if info.is_empty() { return None; }
    if info.contains('/') {
        let path = info.split_once(':').filter(|(_, range)| range.chars().all(|c| c.is_ascii_digit() || c == '-')).map_or(info, |(path, _)| path);
        return language_for_path(Path::new(path), "").and_then(|language| resources.queries(language.id).map(|_| language.id));
    }
    injection_language(resources, info).or_else(|| {
        let (first, _) = info.split_once(char::is_whitespace)?;
        injection_language(resources, first)
    })
}

/// K-46: the colours of one fenced code block of the markdown preview: the editor's own highlighting (same grammar,
/// queries, injections and theme) over `code`, with a parser of its own. Offsets are in `code`; uncoloured text has no run.
pub fn code_block_runs(info: &str, code: &str) -> Vec<(Range<usize>, HighlightStyle)> {
    block_runs(info, code, current_theme().as_deref())
}

fn block_runs(info: &str, code: &str, theme: Option<&SyntaxTheme>) -> Vec<(Range<usize>, HighlightStyle)> {
    let Some(id) = fence_language(resources(), info) else { return Vec::new() };
    let Some(mut highlighter) = SyntaxHighlighter::new(resources(), id) else { return Vec::new() };
    if code.is_empty() { return Vec::new(); }
    highlighter.reparse(&Rope::from_str(code));
    let mut runs = highlighter.runs(&(0..code.len()), theme);
    runs.retain(|(_, style)| *style != HighlightStyle::default());
    runs
}

type PreviewHighlighter = dyn Fn(&CodeBlock) -> Vec<(Range<usize>, HighlightStyle)> + Send + Sync;

static PREVIEW_HIGHLIGHTER: RwLock<Option<Arc<PreviewHighlighter>>> = RwLock::new(None);

/// The preview's code block highlighter. A block keeps its colours while this is the same `Arc`, so it is made once and
/// dropped by `set_theme`: the next call gives a new one and every block is coloured again under the new theme.
pub fn code_block_highlighter() -> Arc<PreviewHighlighter> {
    if let Some(highlighter) = PREVIEW_HIGHLIGHTER.read().unwrap_or_else(|e| e.into_inner()).clone() { return highlighter; }
    let made: Arc<PreviewHighlighter> = Arc::new(|block| {
        let info = [block.lang(), block.meta()].into_iter().flatten().map(|part| part.to_string()).collect::<Vec<_>>().join(" ");
        code_block_runs(&info, &block.code())
    });
    PREVIEW_HIGHLIGHTER.write().unwrap_or_else(|e| e.into_inner()).replace(made.clone());
    made
}

/// The language id of a file, "" for plain text.
pub fn language_id(path: &Path, text: &str) -> &'static str {
    language_for_path(path, text.lines().next().unwrap_or("")).map_or("", |language| language.id)
}

/// Zed's editor settings of one language (`assets/settings/default.json` at 4304dec).
#[derive(Debug, PartialEq, Eq)]
pub struct EditorSettings {
    /// `soft_wrap: "editor_width"` (true) or the default `"none"` (false).
    pub soft_wrap: bool,
    /// Columns a tab character occupies (`tab_size`).
    pub tab_size: usize,
}

/// `soft_wrap` is `"none"` by default and `"editor_width"` for Markdown, Plain Text (a file no language claims, id "")
/// and Git Commit; `tab_size` is 4 by default (only Dart and Elm differ, and they are not in the language table).
/// `hard_tabs` (Go: true) is about the Tab key, not about how a tab character is shown, and is not applied.
pub fn editor_settings(language_id: &str) -> EditorSettings {
    EditorSettings { soft_wrap: matches!(language_id, "" | "markdown" | "gitcommit"), tab_size: 4 }
}

/// Selects the highlighter of `editor` by file name, or by the first line of `text` when the name says nothing, and
/// the tab width Zed uses for that language, and remembers the wrapping it wants (`sync_soft_wrap` applies it once a
/// `Window` is at hand). A language that did not change keeps its highlighter (a new one would parse the file again).
pub fn set_language(editor: &Entity<EditorState>, path: &Path, text: &str, cx: &mut App) {
    let id = language_id(path, text);
    let settings = editor_settings(id);
    if let Some(extras) = extras_of(editor, cx) {
        extras.wrap.set(WrapState { wanted: settings.soft_wrap, ..extras.wrap.get() });
    }
    editor.update(cx, |editor, cx| {
        if editor.language_name() != id { editor.set_highlighter(id, cx); }
        editor.set_tab_size(TabSize { tab_size: settings.tab_size, hard_tabs: false }, cx);
    });
}

#[cfg(test)]
mod tests {
    use super::{
        HighlightStyle, InputEdit, LANGUAGES, OutlineSymbol, QueryResources, Rope, SyntaxHighlighter, SyntaxTheme, grammar, language_for_path,
        language_id, highlighter_factory, resources, style_runs, EditorExtras,
    };
    use std::{ops::Range, path::Path};
    use tree_sitter::{Parser, QueryCursor, StreamingIterator};

    #[test]
    fn language_table_matches_spec_and_detection() {
        let spec = include_str!("../../specs/v0.5/SPEC.md");
        // SPEC R-15 + W-53 list 29 languages: the 24 of R-15, TOML and the four of git-firefly.
        assert_eq!(LANGUAGES.len(), 29);
        let listed = LANGUAGES;
        let rows: Vec<_> = spec.split("**언어 목록 (ORDER-11, Zed 4304dec)**").nth(1).unwrap()
            .lines().skip_while(|line| !line.starts_with("| Shell Script |"))
            .take_while(|line| line.starts_with('|')).collect();
        assert_eq!(rows.len(), 29);
        for language in listed {
            let row = rows.iter().find(|row| {
                let cell = row.split('|').nth(1).unwrap().trim().split(" (").next();
                cell == Some(language.name) || cell == Some(language.id)
            }).unwrap_or_else(|| panic!("SPEC language missing: {}", language.name));
            let suffix_cell = row.split('|').nth(2).unwrap();
            let suffixes = suffix_cell.split(';').next().unwrap().split(" (`").next().unwrap().trim();
            // The git-firefly rows leave the suffixes to the extension's `config.toml` (checked against the copy in K-48's test).
            if suffixes != "미정" {
                let expected: Vec<_> = if suffixes == "없음" { vec![] } else { suffixes.split_whitespace().collect() };
            assert_eq!(language.suffixes, expected, "{}", language.name);
            }
            if let Some(pattern) = language.first_line { regex::Regex::new(pattern).unwrap(); }
        }
        for (file, first, expected) in [
            ("src/main.rs", "", "rust"), ("data.json", "", "json"),
            ("tsconfig.json", "", "jsonc"), (".env", "", "env"),
            (".bashrc", "", "bash"), ("COMMIT_EDITMSG", "", "gitcommit"),
            ("go.mod", "", "gomod"), ("main.C", "", "cpp"),
            ("PKGBUILD", "", "bash"), ("deploy.sh", "", "bash"), ("a.zshrc", "", "bash"), ("run", "#!/bin/bash\necho", "bash"),
            (".env", "", "env"), ("MERGE_MSG", "", "gitcommit"), ("fix.patch", "", "diff"), ("main.go", "", "go"),
            ("go.work", "", "gowork"), ("go.mod", "", "gomod"), ("run", "// go run x.go", "go"),
            ("a.js", "", "javascript"), ("a.mjs", "", "javascript"), ("a.cjs", "", "javascript"), ("a.ts", "", "typescript"),
            ("a.cts", "", "typescript"), ("a.mts", "", "typescript"), ("a.tsx", "", "tsx"), ("a.py", "", "python"), ("a.pyi", "", "python"),
            ("a.yml", "", "yaml"), ("a.yaml", "", "yaml"), ("pixi.lock", "", "yaml"), ("run", "#!/usr/bin/env node", "javascript"),
            ("run", "#!/usr/bin/python3", "python"),
            ("util.h", "", "cpp"), ("util.H", "", "cpp"), ("main.c", "", "c"), ("site.css", "", "css"), ("a.pcss", "", "css"),
            ("README.MD", "", "markdown"), ("view.jsx", "", "javascript"),
            ("index.html", "", "html"), ("script", "#!/usr/bin/env python3", "python"),
            ("script", "#!/bin/sh", "bash"), ("script", "// -*- C++ -*-", "cpp"),
            ("script", "// go run", "go"), ("script", "#!/usr/bin/node", "javascript"),
            ("script", "#!/usr/bin/env ts-node", "typescript"),
        ] {
            assert_eq!(language_for_path(Path::new(file), first).map(|language| language.id), Some(expected), "{file}: {first}");
        }
        assert!(language_for_path(Path::new("unknown.xyz"), "").is_none());
        assert_eq!(LANGUAGES.iter().find(|language| language.id == "javascript").unwrap().grammar, "tsx");
        // K-43C: every language has a grammar now; the shared ones are the same grammar with their own query folder.
        assert!(LANGUAGES.iter().all(|language| grammar(language.id).is_some()), "a language has no grammar");
        assert_eq!(grammar("javascript"), grammar("tsx"));
        assert_ne!(grammar("typescript"), grammar("tsx"));
        assert_eq!(grammar("zed-keybind-context"), grammar("rust"));
        assert_eq!(grammar("env"), grammar("bash"));
        assert_eq!(grammar("jsonc"), grammar("json"));
        assert!(grammar("no-such-language").is_none());
    }

    fn style(color: u32) -> HighlightStyle {
        HighlightStyle { color: Some(gpui_kit::rgb(color).into()), ..Default::default() }
    }

    fn theme(entries: &[(&str, HighlightStyle)]) -> SyntaxTheme {
        SyntaxTheme::new(entries.iter().map(|(key, style)| (key.to_string(), *style)).collect())
    }

    fn style_at(runs: &[(Range<usize>, HighlightStyle)], offset: usize) -> HighlightStyle {
        runs.iter().find(|(range, _)| range.contains(&offset)).map(|(_, style)| *style).expect("covered")
    }

    /// A parsed highlighter over the copied queries, or None (test skipped) when `fetch-zed-languages.ps1` was not run.
    fn parsed(id: &str, text: &str) -> Option<SyntaxHighlighter> {
        let Some(mut highlighter) = SyntaxHighlighter::new(resources(), id) else {
            eprintln!("SKIP: run tools/fetch-zed-languages.ps1 to test {id} highlighting");
            return None;
        };
        highlighter.reparse(&Rope::from_str(text));
        Some(highlighter)
    }

    fn assert_covers(runs: &[(Range<usize>, HighlightStyle)], range: &Range<usize>) {
        assert_eq!(runs.first().map(|r| r.0.start), Some(range.start));
        assert_eq!(runs.last().map(|r| r.0.end), Some(range.end));
        assert!(runs.windows(2).all(|w| w[0].0.end == w[1].0.start && w[0].1 != w[1].1), "{runs:?}");
    }

    #[test]
    fn capture_name_takes_the_longest_dotted_prefix_in_the_theme() {
        let theme = theme(&[("keyword", style(1)), ("keyword.control", style(2)), ("none", HighlightStyle::default())]);
        assert_eq!(theme.style("keyword.control.import"), Some(style(2)));
        assert_eq!(theme.style("keyword.control"), Some(style(2)));
        assert_eq!(theme.style("keyword.operator"), Some(style(1)));
        assert_eq!(theme.style("keywordish"), None);
        assert_eq!(theme.style("string"), None);
        assert_eq!(theme.style("none.deep"), Some(HighlightStyle::default()));
    }

    #[test]
    fn the_last_capture_covering_a_byte_gives_its_colour() {
        let range = 0..12;
        let (a, b, c) = (style(1), style(2), style(3));
        // Nested: the inner capture on top, the outer one around it.
        let runs = style_runs(&range, &[(2, 10, a), (4, 6, b)]);
        assert_eq!(runs, vec![(0..2, HighlightStyle::default()), (2..4, a), (4..6, b), (6..10, a), (10..12, HighlightStyle::default())]);
        // Same range: the later capture wins.
        assert_eq!(style_runs(&(0..5), &[(0, 5, a), (0, 5, b)]), vec![(0..5, b)]);
        // Overlapping, not nested: the later one starts on top and the earlier one is back only where it is alone.
        assert_eq!(style_runs(&range, &[(0, 6, a), (3, 9, c)]), vec![(0..3, a), (3..9, c), (9..12, HighlightStyle::default())]);
        // Starts before the range, ends inside it.
        assert_eq!(style_runs(&(4..8), &[(2, 6, a), (5, 6, b)]), vec![(4..5, a), (5..6, b), (6..8, HighlightStyle::default())]);
        // Equal neighbours merge; an empty capture paints nothing; an empty range is empty.
        assert_eq!(style_runs(&range, &[(0, 4, a), (4, 8, a), (9, 9, b)]), vec![(0..8, a), (8..12, HighlightStyle::default())]);
        assert!(style_runs(&(3..3), &[(0, 9, a)]).is_empty());
    }

    #[test]
    fn rust_and_json_samples_get_theme_colours() {
        let (keyword, function, string, property, boolean) = (style(1), style(2), style(3), style(4), style(5));
        if let Some(h) = parsed("rust", "fn main() { let x = 1; }") {
            let theme = theme(&[("keyword", keyword), ("function", function)]);
            let runs = h.runs(&(0..24), Some(&theme));
            assert_covers(&runs, &(0..24));
            assert_eq!((style_at(&runs, 0), style_at(&runs, 1)), (keyword, keyword), "fn");
            assert_eq!(style_at(&runs, 3), function, "main");
            assert_eq!(style_at(&runs, 12), keyword, "let");
            assert_eq!(style_at(&runs, 16), HighlightStyle::default(), "x has no theme key");
            // A theme without these keys, and no theme at all, paint nothing.
            assert_eq!(h.runs(&(0..24), None), vec![(0..24, HighlightStyle::default())]);
        }
        if let Some(h) = parsed("json", r#"{"a": "b", "c": true}"#) {
            let theme = theme(&[("string", string), ("property", property), ("boolean", boolean)]);
            let runs = h.runs(&(0..22), Some(&theme));
            assert_eq!(style_at(&runs, 2), property, "key: property.json_key on top of string");
            assert_eq!(style_at(&runs, 7), string, "string value");
            assert_eq!(style_at(&runs, 17), boolean, "true");
            assert_eq!(style_at(&runs, 5), HighlightStyle::default(), "colon");
        }
    }

    /// K-43A: the style of the first byte of `needle` in `text` under a theme of distinct colours 1, 2, 3... per key.
    fn colour_of(id: &str, text: &str, keys: &[&str], needle: &str) -> Option<Option<usize>> {
        let h = parsed(id, text)?;
        let theme = theme(&keys.iter().enumerate().map(|(i, key)| (*key, style(i as u32 + 1))).collect::<Vec<_>>());
        let runs = h.runs(&(0..text.len()), Some(&theme));
        assert_covers(&runs, &(0..text.len()));
        let got = style_at(&runs, text.find(needle).expect("needle"));
        Some((0..keys.len()).find(|i| got == style(*i as u32 + 1)))
    }

    #[test]
    fn c_cpp_and_css_samples_get_theme_colours() {
        let c = "struct P { int x; };\nint add(int a) { return a; }\n";
        let c_keys = ["keyword", "function", "type"];
        // keyword = 0, function = 1, type = 2
        for (needle, want) in [("struct", Some(0)), ("add", Some(1)), ("int add", Some(2)), ("return", Some(0)), ("a;", None)] {
            if let Some(got) = colour_of("c", c, &c_keys, needle) { assert_eq!(got, want, "C: {needle}"); }
        }
        let cpp = "template <typename T>\nclass Box { public: T get(); };\n";
        for (needle, want) in [("template", Some(0)), ("class", Some(0)), ("Box", Some(2)), ("get", Some(1))] {
            if let Some(got) = colour_of("cpp", cpp, &c_keys, needle) { assert_eq!(got, want, "C++: {needle}"); }
        }
        let css = ".card > a:hover { color: red; }\n";
        let css_keys = ["selector", "tag", "property", "operator"];
        for (needle, want) in [("card", Some(0)), ("a:", Some(1)), ("hover", Some(0)), ("color", Some(2)), (">", Some(3))] {
            if let Some(got) = colour_of("css", css, &css_keys, needle) { assert_eq!(got, want, "CSS: {needle}"); }
        }
    }

    #[test]
    fn shell_diff_gitcommit_and_go_samples_get_theme_colours() {
        let keys = ["keyword", "string", "variable", "comment", "function", "type", "diff.plus", "diff.minus", "markup.heading"];
        let ix = |name: &str| keys.iter().position(|k| *k == name);
        let check = |id: &str, text: &str, cases: &[(&str, &str)]| {
            for (needle, key) in cases {
                if let Some(got) = colour_of(id, text, &keys, needle) { assert_eq!(got, ix(key), "{id}: {needle}"); }
            }
        };
        // Shell Script and Env: same grammar, each with its own query folder.
        check("bash", "if [ -f a ]; then echo $A; fi # c\n", &[("if", "keyword"), ("A;", "variable"), ("# c", "comment")]);
        check("env", "export FOO=\"bar\"\n# c\n", &[("export", "keyword"), ("\"bar\"", "string"), ("# c", "comment")]);
        // Diff: `@string @diff.plus` / `@keyword @diff.minus` — the later capture of a pair is on top.
        check("diff", "--- a\n+++ b\n@@ -1 +1 @@\n-old\n+new\n", &[("+new", "diff.plus"), ("-old", "diff.minus")]);
        check("gitcommit", "fix thing\n\n# comment\n", &[("fix", "markup.heading"), ("# comment", "comment")]);
        // `int` is `@type` and, through `#any-of?`, `@type.builtin`: both reach the `type` key.
        check("go", "package main\nfunc add(a int) int { return a }\n", &[("func", "keyword"), ("add", "function"), ("int)", "type"), ("return", "keyword")]);
        check("gomod", "module example.com/m\n\ngo 1.21\n", &[("module", "keyword"), ("1.21", "string")]);
        check("gowork", "go 1.21\nuse ./a\n// c\n", &[("use", "keyword"), ("1.21", "string"), ("// c", "comment")]);
    }

    #[test]
    fn python_script_yaml_and_internal_samples_get_theme_colours() {
        let keys = ["keyword", "function", "type", "string", "comment", "number", "property", "tag", "constant.builtin", "operator"];
        let ix = |name: &str| keys.iter().position(|k| *k == name);
        let check = |id: &str, text: &str, cases: &[(&str, &str)]| {
            for (needle, key) in cases {
                if let Some(got) = colour_of(id, text, &keys, needle) { assert_eq!(got, ix(key), "{id}: {needle}"); }
            }
        };
        // `Foo` is `@type.class` by the query's `#match?` on the identifier text.
        check("python", "class Foo:\n    def bar(self):\n        return \"x\"  # c\n",
            &[("class", "keyword"), ("Foo", "type"), ("bar", "function"), ("return", "keyword"), ("\"x\"", "string"), ("# c", "comment")]);
        // JavaScript = TSX grammar + `javascript` queries, so JSX parses in a `.js` file.
        check("javascript", "const n = 1; // c\nconst a = <div id=\"x\"/>;\n",
            &[("const", "keyword"), ("1;", "number"), ("// c", "comment"), ("div", "tag")]);
        check("typescript", "interface P { a: number }\nlet s = \"x\";\n",
            &[("interface", "keyword"), ("P {", "type"), ("number", "type"), ("\"x\"", "string")]);
        check("tsx", "const a: P = <Box id=\"x\"/>;\n", &[("const", "keyword"), ("P =", "type"), ("Box", "tag")]); // `@type @tag.component.jsx`: the later one is on top
        check("yaml", "name: \"x\"\ncount: 1 # c\nok: true\n",
            &[("name", "property"), ("\"x\"", "string"), ("1 #", "number"), ("# c", "comment")]);
        // Injection-only languages: their own highlights, parsed on their own.
        check("jsdoc", "/**\n * @param {string} a\n */", &[("@param", "keyword"), ("string", "type")]);
        check("regex", "a(b|c)+", &[("+", "operator")]);
        check("zed-keybind-context", "a && b;",&[("&&", "operator")]);
    }

    /// K-44: `cases` as (needle, key) under distinct colours per key; `None` as key means "no colour".
    fn check_layers(id: &str, text: &str, keys: &[&str], cases: &[(&str, Option<&str>)]) {
        for (needle, key) in cases {
            let want = key.map(|key| keys.iter().position(|k| *k == key).expect("key in list"));
            if let Some(got) = colour_of(id, text, keys, needle) { assert_eq!(got, want, "{id}: {needle}"); }
        }
    }

    #[test]
    fn markdown_inline_and_code_blocks_are_injected() {
        let text = "# T *x*\n\nsome **bold** and *it* and `code` and [link](http://x.y)\n\n\
                    ```rust\nfn main() {}\n```\n\n```ts\nconst a = 1;\n```\n\n```foo\nfn zzz\n```\n\n```RUST\nlet q = 1;\n```\n";
        let keys = ["title", "emphasis.strong", "emphasis", "text.literal", "link_text", "link_uri", "keyword"];
        check_layers("markdown", text, &keys, &[
            ("T *x", Some("title")),
            // The inline layer is deeper than the heading, so its capture is on top.
            ("*x*", Some("emphasis")),
            ("**bold**", Some("emphasis.strong")),
            ("*it*", Some("emphasis")),
            ("`code`", Some("text.literal")),
            ("[link]", Some("link_text")),
            ("http", Some("link_uri")),
            // Fence language: a name (any case) or a suffix; an unknown one stays plain.
            ("fn main", Some("keyword")),
            ("const a", Some("keyword")),
            ("let q", Some("keyword")),
            ("fn zzz", None),
        ]);
    }

    #[test]
    fn markdown_front_matter_html_blocks_and_unknown_injections() {
        let keys = ["property", "tag", "attribute", "keyword"];
        check_layers("markdown", "---\nname: x\n---\n\n<div class=\"a\">hi</div>\n\ntext\n", &keys,
            &[("name", Some("property")), ("div", Some("tag")), ("class", Some("attribute")), ("hi", None), ("text", None)]);
        // `+++` front matter is TOML (a language since K-48): its own layer colours the key.
        check_layers("markdown", "+++\nname = 1\n+++\n", &keys, &[("name", Some("property"))]);
        // A script inside an HTML block reaches JavaScript through two layers.
        check_layers("markdown", "<script>const a = 1;</script>\n\ntext\n", &keys, &[("const", Some("keyword"))]);
        check_layers("markdown", "```html\n<script>const a = 1;</script>\n```\n", &keys, &[("const", Some("keyword")), ("script", Some("tag"))]);
    }

    #[test]
    fn inline_html_tags_are_one_combined_layer() {
        let keys = ["tag", "attribute", "emphasis.strong"];
        check_layers("markdown", "text <b class=\"x\">bold</b> end\n", &keys, &[("b class", Some("tag")), ("class", Some("attribute")), ("bold", None)]);
        // The pieces of a combined layer sit on different rows: they are joined with line breaks.
        check_layers("markdown", "a <i>x</i>\nb <u>y</u>\n", &keys, &[("i>", Some("tag")), ("u>", Some("tag"))]);
    }

    #[test]
    fn html_injects_javascript_and_css() {
        let keys = ["keyword", "property", "tag", "comment", "string"];
        check_layers("html", "<script>const a = 1; // c</script>\n", &keys, &[("const", Some("keyword")), ("// c", Some("comment")), ("script", Some("tag"))]);
        check_layers("html", "<style>a { color: red }</style>\n", &keys, &[("color", Some("property"))]);
        // The attribute value is a string in HTML and CSS inside: the injected layer is on top. The CSS grammar has no
        // top-level declarations, so `color: red` is a selector with a pseudo-class and `color` is a tag name (Zed too).
        check_layers("html", "<p style=\"color: red\">x</p>\n", &keys, &[("color", Some("tag")), ("\"color", Some("string"))]);
        check_layers("html", "<p onclick=\"var q = 1\">x</p>\n", &keys, &[("var", Some("keyword"))]);
        // Not `on…` attributes and unknown names are not injected.
        check_layers("html", "<p title=\"var q = 1\">x</p>\n", &keys, &[("var", Some("string"))]);
    }

    #[test]
    fn javascript_injects_regex_and_jsdoc() {
        let keys = ["operator", "keyword", "comment"];
        let text = "const r = /a+b/g;\n/**\n * @param {string} a\n */\nfunction f(a) {}\n";
        check_layers("javascript", text, &keys, &[
            ("+b", Some("operator")),
            ("@param", Some("keyword")),
            ("/**", Some("comment")),
            ("function", Some("keyword")),
        ]);
        // Plain comments inject the `comment` language, which does not exist here: just the outer colour.
        check_layers("javascript", "// plain\nconst a = 1;\n", &keys, &[("// plain", Some("comment"))]);
    }

    /// Applies `edits` ((anchor text, offset from it, bytes removed, text inserted)) one by one through the incremental
    /// path and checks that the result always equals a fresh parse of the new text.
    fn assert_edits_match_full_parse(id: &str, text: &str, edits: &[(&str, usize, usize, &str)]) {
        use gpui_kit::base::input::RopeExt;
        let keys = ["title", "emphasis.strong", "emphasis", "text.literal", "link_text", "link_uri", "keyword", "property",
            "tag", "attribute", "string", "comment", "operator", "number", "function", "type"];
        let theme = theme(&keys.iter().enumerate().map(|(i, k)| (*k, style(i as u32 + 1))).collect::<Vec<_>>());
        let mut text = text.to_string();
        let Some(mut incremental) = parsed(id, &text) else { return };
        for (anchor, offset, removed, inserted) in edits {
            let start = text.find(anchor).unwrap_or_else(|| panic!("anchor {anchor:?} in {text:?}")) + offset;
            let old = Rope::from_str(&text);
            text.replace_range(start..start + removed, inserted);
            let new = Rope::from_str(&text);
            let end = start + inserted.len();
            incremental.edit(&InputEdit {
                start_byte: start,
                old_end_byte: start + removed,
                new_end_byte: end,
                start_position: old.offset_to_point(start),
                old_end_position: old.offset_to_point(start + removed),
                new_end_position: new.offset_to_point(end),
            });
            incremental.reparse(&new);
            let full = parsed(id, &text).expect("same language");
            let range = 0..text.len();
            assert_eq!(incremental.runs(&range, Some(&theme)), full.runs(&range, Some(&theme)), "after editing at {anchor:?}+{offset}: {text:?}");
        }
    }

    #[test]
    fn editing_keeps_injected_layers_equal_to_a_fresh_parse() {
        assert_edits_match_full_parse(
            "markdown",
            "# T *x*\n\nsome **bold** and `code` [l](http://x.y)\n\n```rust\nfn main() {}\n```\n\n<div class=\"a\">hi</div>\n\n```foo\nfn zzz\n```\n",
            &[
                ("fn main", 3, 0, "xx"),          // inside a code block
                ("```rust", 3, 4, "ts"),          // the fence language changes: the layer is replaced
                ("# T", 0, 0, "para one\n\n"),    // text before every layer: all of them shift
                ("**bold**", 2, 0, "ZZ"),         // inside an inline layer
                ("```ts", 0, 5, ""),              // the fence disappears: the block structure changes
                ("```foo", 3, 3, "html"),         // an unknown fence language becomes HTML
                ("<div", 1, 0, "i"),              // an HTML block
            ],
        );
        assert_edits_match_full_parse(
            "html",
            "<script>const a = 1;</script>\n<style>a { color: red }</style>\n<p style=\"color: red\">x</p>\n",
            &[("const", 6, 0, "z"), ("<style>", 0, 0, "<p>q</p>\n"), ("color: red }", 0, 5, "margin"), ("x</p>", 0, 0, "yy")],
        );
        assert_edits_match_full_parse(
            "javascript",
            "const r = /a+b/g;\n/**\n * @param {string} a\n */\nfunction f(a) {}\n",
            &[("+b", 1, 0, "c"), ("@param", 1, 0, "x"), ("const r", 0, 0, "\n")],
        );
    }

    /// K-47: Zed's `soft_wrap` is "editor_width" only for Markdown, Plain Text and Git Commit; `tab_size` is 4.
    #[test]
    fn editor_settings_follow_zed_default_json() {
        use super::editor_settings;
        let wraps: Vec<&str> = LANGUAGES.iter().map(|l| l.id).filter(|id| editor_settings(id).soft_wrap).collect();
        assert_eq!(wraps, ["gitcommit", "markdown"]);
        assert!(editor_settings("").soft_wrap, "a file no language claims is Plain Text");
        for id in std::iter::once("").chain(LANGUAGES.iter().map(|l| l.id)) {
            assert_eq!(editor_settings(id).tab_size, 4, "{id}");
        }
        // Through the file name: a text file wraps, source files do not.
        for (file, wrap) in [("notes.txt", true), ("README.md", true), ("COMMIT_EDITMSG", true), ("sample.html", false), ("main.go", false),
            ("a.rs", false), ("a.json", false), ("a.py", false), ("a.css", false), ("Makefile", true)] {
            assert_eq!(editor_settings(language_id(Path::new(file), "")).soft_wrap, wrap, "{file}");
        }
    }

    /// K-47-R1: the editor starts wrapped; a wrap is applied only when the language wants the other value.
    #[test]
    fn soft_wrap_is_applied_only_when_it_differs() {
        use super::{WrapState, editor_settings, wrap_to_apply};
        let start = WrapState::default();
        assert!(start.applied && start.wanted, "an editor starts wrapped");
        for (applied, wanted, want) in [(true, true, None), (false, false, None), (true, false, Some(false)), (false, true, Some(true))] {
            assert_eq!(wrap_to_apply(applied, wanted), want, "applied {applied}, wanted {wanted}");
        }
        // A code file turns it off once; asking again with the same wish does nothing.
        let wanted = editor_settings(language_id(Path::new("a.rs"), "")).soft_wrap;
        assert_eq!(wrap_to_apply(start.applied, wanted), Some(false));
        assert_eq!(wrap_to_apply(false, wanted), None);
        // Markdown keeps the editor's default and never calls.
        assert_eq!(wrap_to_apply(start.applied, editor_settings("markdown").soft_wrap), None);
    }

    /// K-48: file name -> language of the TOML and Git extensions (their `config.toml` values), the copied `config.toml`
    /// (when `fetch-zed-languages.ps1` ran) says the same, and a short sample of each gets highlight runs.
    #[test]
    fn extension_languages_follow_their_config_and_highlight() {
        for (file, id) in [("Cargo.lock", "toml"), ("pyproject.toml", "toml"), ("Pipfile", "toml"), ("uv.lock", "toml"),
            (".gitconfig", "gitconfig"), (".gitmodules", "gitconfig"), (".lfsconfig", "gitconfig"), ("config.worktree", "gitconfig"),
            (".gitignore", "gitignore"), (".dockerignore", "gitignore"), (".npmignore", "gitignore"), (".git-blame-ignore-revs", "gitignore"),
            (".vscodeignore", "gitignore"), (".gitattributes", "gitattributes"), ("gitattributes", "gitattributes"),
            ("git-rebase-todo", "gitrebase")] {
            assert_eq!(language_for_path(Path::new(file), "").map(|language| language.id), Some(id), "{file}");
        }
        // Neighbours stay what they were: `pixi.lock` is YAML, `package.json` JSON, a bare `config` has no language.
        assert_eq!(language_for_path(Path::new("pixi.lock"), "").map(|l| l.id), Some("yaml"));
        assert_eq!(language_for_path(Path::new("package.json"), "").map(|l| l.id), Some("json"));
        assert!(language_for_path(Path::new("config"), "").is_none());
        let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("resources/zed-languages");
        for language in LANGUAGES.iter().filter(|l| ["toml", "gitconfig", "gitignore", "gitattributes", "gitrebase"].contains(&l.id)) {
            let Ok(text) = std::fs::read_to_string(root.join(language.id).join("config.toml")) else {
                eprintln!("SKIP: run tools/fetch-zed-languages.ps1 to compare {} with its config.toml", language.id);
                continue;
            };
            let config: toml::Table = text.parse().unwrap();
            assert_eq!(config["name"].as_str(), Some(language.name), "{}", language.id);
            let suffixes: Vec<&str> = config["path_suffixes"].as_array().unwrap().iter().filter_map(|v| v.as_str()).collect();
            assert_eq!(language.suffixes, suffixes, "{}", language.id);
            assert_eq!(config.get("first_line_pattern").and_then(|v| v.as_str()), language.first_line, "{}", language.id);
            assert!(config.get("hidden").is_none(), "{} would be hidden", language.id);
        }
        let theme = theme(&[("comment", style(1)), ("string", style(2)), ("property", style(3)), ("keyword", style(4)), ("number", style(5)),
            ("title", style(6)), ("variable", style(7)), ("constant", style(8)), ("punctuation.bracket", style(9)), ("operator", style(10))]);
        for (id, sample) in [("toml", "# c\n[package]\nname = \"x\"\nversion = 1\n"),
            ("gitconfig", "[user]\n\tname = Ann\n# c\n"), ("gitignore", "# c\n*.log\n!keep.log\n/target/\n"),
            ("gitattributes", "# c\n*.rs text eol=lf\n*.png binary\n[attr]x -diff\n"),
            ("gitrebase", "pick 1a2b3c4 first\nsquash 5d6e7f8 second\nexec cargo test\n# c\n")] {
            let Some(h) = parsed(id, sample) else { continue };
            let runs = h.runs(&(0..sample.len()), Some(&theme));
            assert!(runs.iter().any(|(_, s)| *s != HighlightStyle::default()), "{id}: no coloured run in {runs:?}");
        }
    }

    /// K-46: the language of a fence's info string (Zed `markdown.rs` 1334-1345): empty, path, name or suffix, first word.
    #[test]
    fn fence_info_finds_the_language_like_zed() {
        use super::fence_language;
        if resources().queries("rust").is_none() { return; }
        for (info, want) in [("", None), ("   ", None), ("rust", Some("rust")), (" Rust ", Some("rust")), ("rs", Some("rust")),
            ("py", Some("python")), ("TypeScript", Some("typescript")), ("rust no_run", Some("rust")), ("rust,no_run", None),
            ("path/to/x.rs", Some("rust")), ("path/to/x.rs:3-5", Some("rust")), ("path/to/x.unknown", None), ("nolang", None),
            ("nolang with words", None)] {
            assert_eq!(fence_language(resources(), info), want, "{info:?}");
        }
    }

    /// K-46: a block gets the editor's colours (the same runs, uncoloured text left out), HTML's script is coloured by
    /// its injected layer, an unknown language or empty code has none, and the preview's highlighter is one stable `Arc`.
    #[test]
    fn code_block_runs_are_the_editors_colours() {
        use super::{block_runs, code_block_highlighter};
        let theme = theme(&[("keyword", style(1)), ("function", style(2)), ("string", style(3))]);
        let code = "pub fn bump() -> &'static str {\n    \"x\"\n}\n";
        let Some(editor) = parsed("rust", code) else { return };
        let mut want = editor.runs(&(0..code.len()), Some(&theme));
        want.retain(|(_, s)| *s != HighlightStyle::default());
        assert!(!want.is_empty());
        assert_eq!(block_runs("rust", code, Some(&theme)), want);
        assert_eq!(block_runs("rust no_run", code, Some(&theme)), want, "first word");
        let html = "<script>\nlet x = \"a\";\n</script>\n";
        if let Some(editor) = parsed("html", html) {
            let mut want = editor.runs(&(0..html.len()), Some(&theme));
            want.retain(|(_, s)| *s != HighlightStyle::default());
            assert_eq!(block_runs("html", html, Some(&theme)), want);
            let at = html.find("let").unwrap();
            assert!(block_runs("html", html, Some(&theme)).iter().any(|(r, s)| r.contains(&at) && *s == style(1)), "script is injected JavaScript");
        }
        assert!(block_runs("", code, Some(&theme)).is_empty() && block_runs("nolang", code, Some(&theme)).is_empty());
        assert!(block_runs("rust", "", Some(&theme)).is_empty());
        assert!(std::sync::Arc::ptr_eq(&code_block_highlighter(), &code_block_highlighter()));
        // The info string is `lang` plus `meta` of the parsed fence.
        let block = gpui_kit::base::text::CodeBlock::from_code(code, Some("rust")).with_meta(Some("no_run".into()));
        assert_eq!(code_block_highlighter()(&block), super::code_block_runs("rust no_run", code));
    }

    /// K-49 measurement (not run by default; numbers go to the card report, files stay out of the repo): the first parse
    /// and the cost of typing one character in the middle of a big file, through the editor's own `SyntaxHighlighter`.
    /// `K49_FILE=<path> K49_LANG=<id>` or `K49_SYNTH=markdown|html`; `K49_VERIFY=1` also compares the viewport colours
    /// of every edit with a full parse. Run: `cargo test --release k49_measure -- --ignored --nocapture`.
    #[test]
    #[ignore]
    fn k49_measure() {
        use gpui_kit::base::input::RopeExt;
        use std::time::Instant;
        let (name, lang, mut text) = match (std::env::var("K49_FILE"), std::env::var("K49_SYNTH")) {
            (Ok(path), _) => (path.clone(), std::env::var("K49_LANG").expect("K49_LANG"), std::fs::read_to_string(&path).unwrap()),
            (_, Ok(kind)) => (format!("synthetic {kind}"), kind.clone(), k49_synthetic(&kind)),
            _ => return,
        };
        let theme = theme(&[("keyword", style(1)), ("function", style(2)), ("type", style(3)), ("string", style(4)), ("comment", style(5)),
            ("number", style(6)), ("property", style(7)), ("tag", style(8)), ("attribute", style(9)), ("variable", style(10)),
            ("constant", style(11)), ("punctuation.bracket", style(12)), ("operator", style(13)), ("title", style(14)), ("boolean", style(15))]);
        let lines = text.lines().count();
        let mut h = SyntaxHighlighter::new(resources(), &lang).expect("language and queries");
        let started = Instant::now();
        h.reparse(&Rope::from_str(&text));
        let first = started.elapsed().as_secs_f64() * 1000.0;
        // The 40 visible lines starting at `line`.
        let viewport = |text: &str, line: usize| {
            let starts: Vec<usize> = std::iter::once(0).chain(text.match_indices('\n').map(|(i, _)| i + 1)).collect();
            starts[line.min(starts.len() - 1)]..starts[(line + 40).min(starts.len() - 1)]
        };
        let verify = std::env::var("K49_VERIFY").is_ok();
        let (mut totals, mut parts_max, mut blocked) = (Vec::new(), (0f64, 0f64, 0f64), Vec::new());
        for i in 0..10 {
            let line = lines / 2 + i * 7;
            let at = viewport(&text, line).start;
            let old = Rope::from_str(&text);
            text.insert(at, 'x');
            let new = Rope::from_str(&text);
            let edit = InputEdit {
                start_byte: at, old_end_byte: at, new_end_byte: at + 1,
                start_position: old.offset_to_point(at), old_end_position: old.offset_to_point(at), new_end_position: new.offset_to_point(at + 1),
            };
            let range = viewport(&text, line);
            let t0 = Instant::now();
            h.edit(&edit);
            let t1 = Instant::now();
            h.reparse(&new);
            let t2 = Instant::now();
            let runs = h.runs(&range, Some(&theme));
            let t3 = Instant::now();
            let ms = |a: Instant, b: Instant| b.duration_since(a).as_secs_f64() * 1000.0;
            let (e, r, v) = (ms(t0, t1), ms(t1, t2), ms(t2, t3));
            totals.push(e + r + v);
            parts_max = (parts_max.0.max(e), parts_max.1.max(r), parts_max.2.max(v));
            blocked.push((e + r).max(v));
            if verify {
                let mut full = SyntaxHighlighter::new(resources(), &lang).unwrap();
                full.reparse(&new);
                assert_eq!(runs, full.runs(&range, Some(&theme)), "edit {i} at line {line}");
            }
        }
        totals.sort_by(f64::total_cmp);
        blocked.sort_by(f64::total_cmp);
        println!("K49 | {name} | {lines} lines | first parse {first:.1} ms | edit total median {:.1} / max {:.1} ms | edit {:.1} reparse {:.1} runs {:.1} (max each) | blocked longest {:.1} ms",
            totals[5], totals[9], parts_max.0, parts_max.1, parts_max.2, blocked[9]);
    }

    /// K-49 synthetic files: Markdown with 330 fenced blocks in 10,000 lines (a heading, a paragraph and a block of 20..
    /// lines of rotating languages per unit), HTML with 600 `<style>`/`<script>` blocks in 10,013 lines.
    fn k49_synthetic(kind: &str) -> String {
        let mut out = String::new();
        match kind {
            "markdown" => {
                let samples: [(&str, &str); 8] = [
                    ("rust", "fn add(a: i32, b: i32) -> i32 {\n    // sum\n    a + b\n}"),
                    ("typescript", "const greet = (name: string): string => `Hello, ${name}!`;\nconsole.log(greet(\"world\"), 42);"),
                    ("python", "def area(r: float) -> float:\n    \"\"\"Circle area.\"\"\"\n    return 3.14159 * r ** 2"),
                    ("json", "{\"name\": \"x\", \"items\": [1, 2, 3], \"ok\": true}"),
                    ("bash", "for f in *.txt; do\n  echo \"$f\" | wc -l\ndone"),
                    ("css", "a:hover { color: #3b82f6; margin: 0 auto; }"),
                    ("html", "<div class=\"a\"><p id=\"x\">hi</p></div>"),
                    ("yaml", "name: demo\nitems:\n  - one\n  - two"),
                ];
                let mut block = 0;
                while out.lines().count() < 10_000 {
                    out.push_str(&format!("## Section {block}\n\nSome text with `code` and a [link](http://x.y).\n\n"));
                    if block < 330 {
                        let (lang, code) = samples[block % samples.len()];
                        out.push_str(&format!("```{lang}\n"));
                        // Pad every block to the same size with repeated lines of its sample.
                        for _ in 0..4 { out.push_str(code); out.push('\n'); }
                        out.push_str("```\n\n");
                    } else {
                        out.push_str("Plain paragraph.\n\n");
                    }
                    block += 1;
                }
            }
            _ => {
                out.push_str("<!DOCTYPE html>\n<html>\n<body>\n");
                for block in 0..600 {
                    if block % 2 == 0 {
                        out.push_str("<style>\n");
                        for r in 0..8 { out.push_str(&format!(".c{block}-{r} {{ color: #{:06x}; margin: {r}px; }}\n", block * 997 + r)); }
                        out.push_str("</style>\n");
                    } else {
                        out.push_str("<script>\n");
                        for r in 0..8 { out.push_str(&format!("const v{block}_{r} = {r} + \"s\"; // c\n")); }
                        out.push_str("</script>\n");
                    }
                    out.push_str("<div class=\"x\">text</div>\n");
                }
                while out.lines().count() < 10_013 { out.push_str("<p>filler</p>\n"); }
                out.push_str("</body>\n</html>\n");
            }
        }
        out
    }

    /// K-49: a hash of the colours of whole files, to compare before and after a change of the injection pass: every
    /// file of `K49_DIR` (by its name's language) and the two synthetic files, each parsed whole and after one edit.
    #[test]
    #[ignore]
    fn k49_dump() {
        use gpui_kit::base::input::RopeExt;
        use std::hash::{Hash, Hasher};
        let theme = theme(&[("keyword", style(1)), ("function", style(2)), ("type", style(3)), ("string", style(4)), ("comment", style(5)),
            ("number", style(6)), ("property", style(7)), ("tag", style(8)), ("attribute", style(9)), ("variable", style(10)),
            ("constant", style(11)), ("punctuation.bracket", style(12)), ("operator", style(13)), ("title", style(14)), ("boolean", style(15)),
            ("emphasis", style(16)), ("link_text", style(17)), ("text.literal", style(18)), ("punctuation.special", style(19))]);
        let mut files: Vec<(String, String, String)> = Vec::new();
        if let Ok(dir) = std::env::var("K49_DIR") {
            for entry in std::fs::read_dir(dir).unwrap().flatten() {
                let path = entry.path();
                let Ok(text) = std::fs::read_to_string(&path) else { continue };
                let Some(language) = language_for_path(&path, text.lines().next().unwrap_or("")) else { continue };
                files.push((path.file_name().unwrap().to_string_lossy().into_owned(), language.id.to_string(), text));
            }
        }
        for kind in ["markdown", "html"] { files.push((format!("synthetic-{kind}"), kind.to_string(), k49_synthetic(kind))); }
        if let Ok(path) = std::env::var("K49_FILE") {
            files.push((path.clone(), std::env::var("K49_LANG").unwrap(), std::fs::read_to_string(path).unwrap()));
        }
        files.sort();
        for (name, lang, mut text) in files {
            let Some(mut h) = SyntaxHighlighter::new(resources(), &lang) else { continue };
            let hash = |h: &SyntaxHighlighter, len: usize| {
                let mut hasher = std::collections::hash_map::DefaultHasher::new();
                // Whole file in 4 KiB pieces, so the layers a piece touches decide (as the editor asks line groups).
                let mut start = 0;
                while start < len {
                    let end = (start + 4096).min(len);
                    format!("{:?}", h.runs(&(start..end), Some(&theme))).hash(&mut hasher);
                    start = end;
                }
                hasher.finish()
            };
            h.reparse(&Rope::from_str(&text));
            let first = hash(&h, text.len());
            let old = Rope::from_str(&text);
            let at = text.len() / 2 - text[..text.len() / 2].chars().rev().take_while(|c| *c != '\n').count();
            text.insert(at, 'x');
            let new = Rope::from_str(&text);
            h.edit(&InputEdit { start_byte: at, old_end_byte: at, new_end_byte: at + 1,
                start_position: old.offset_to_point(at), old_end_position: old.offset_to_point(at), new_end_position: new.offset_to_point(at + 1) });
            h.reparse(&new);
            println!("DUMP {name} {lang} {first:016x} {:016x}", hash(&h, text.len()));
        }
    }

    /// K-49: the injection query runs on the top-level nodes that touch the changed bytes, not on the root.
    #[test]
    fn top_level_nodes_touch_the_window_and_injections_are_still_found() {
        use super::top_level_nodes;
        let rust = "fn a() {}\n\nfn b() {}\n\nfn c() {}\n";
        let Some(h) = parsed("rust", rust) else { return };
        let root = h.root.as_ref().unwrap().tree.root_node();
        let b = rust.find("fn b").unwrap();
        let kinds = |window: std::ops::Range<usize>| top_level_nodes(root, &window).iter().map(|n| n.byte_range()).collect::<Vec<_>>();
        let holding = kinds(b + 1..b + 2);
        assert!(holding.len() == 1 && holding[0] == (b..b + 9), "only the item holding the byte: {holding:?}");
        assert_eq!(kinds(0..rust.len()).len(), 3, "a whole-file window takes every item");
        assert_eq!(kinds(b + 9..b + 10).len(), 1, "a window in the gap after an item still has a node");
        // JSDoc and a tagged template come through the per-node query (K-44 layers, now one query per top-level node).
        let keys = ["keyword", "tag", "attribute"];
        check_layers("typescript", "/** @param {string} a */\nfunction f(a: string) {}\nconst t = /* html */ `<b class=\"x\">y</b>`;\n", &keys,
            &[("@param", Some("keyword")), ("class", Some("attribute"))]);
    }

    /// K-50: the first parse runs as a `FullParse` on another thread; the colours that arrive equal a synchronous parse,
    /// and until then the file is plain text with no symbols.
    #[test]
    fn first_parse_runs_off_thread_and_equals_a_synchronous_parse() {
        let text = "// c\npub struct Counter { n: u32 }\nimpl Counter {\n    pub fn bump(&mut self) -> u32 { self.n += 1; self.n }\n}\n".repeat(50);
        let rope = Rope::from_str(&text);
        let Some(mut h) = SyntaxHighlighter::new(resources(), "rust") else { return };
        let theme = theme(&[("keyword", style(1)), ("function", style(2)), ("type", style(3)), ("comment", style(4))]);
        let range = 0..text.len();
        let job = h.changed(&[(replacement_edit(&rope), rope.clone())]).expect("a highlighter without a tree starts a full parse");
        // Waiting: plain text, no symbols, and a further change is only logged.
        assert_eq!(h.runs(&range, Some(&theme)), vec![(range.clone(), HighlightStyle::default())]);
        assert!(h.symbols(text.find("n += 1").unwrap(), Some(&theme)).is_empty());
        let done = std::thread::spawn(move || job.run()).join().expect("the parse thread");
        assert!(h.finish(done));
        let mut sync = SyntaxHighlighter::new(resources(), "rust").unwrap();
        sync.reparse(&rope);
        assert_eq!(h.runs(&range, Some(&theme)), sync.runs(&range, Some(&theme)));
        assert!(h.runs(&range, Some(&theme)).iter().any(|(_, s)| *s != HighlightStyle::default()));
        assert!(!h.symbols(text.find("n += 1").unwrap(), Some(&theme)).is_empty());
    }

    /// K-50 races: an edit while the parse is in flight is replayed on the tree that arrives (the colours then equal a
    /// parse of the new text); a restart (the text was replaced) or a second full parse abandons the first result.
    #[test]
    fn edits_during_the_first_parse_are_replayed_and_restarts_discard_the_result() {
        use gpui_kit::base::input::RopeExt;
        let theme = theme(&[("keyword", style(1)), ("function", style(2)), ("string", style(3)), ("comment", style(4))]);
        let text = "fn a() {}\nfn b() { let s = \"x\"; }\n".repeat(40);
        let Some(mut h) = SyntaxHighlighter::new(resources(), "rust") else { return };
        let old = Rope::from_str(&text);
        let job = h.changed(&[(replacement_edit(&old), old.clone())]).unwrap();
        // Two edits while it is parsing (the second one after the first, one batch and one single).
        let first = text.find("fn b").unwrap();
        let mut now = text.clone();
        let mut before = old.clone();
        for (at, inserted) in [(first, "// note\n"), (0, "pub ")] {
            now.insert_str(at, inserted);
            let after = Rope::from_str(&now);
            let edit = InputEdit {
                start_byte: at, old_end_byte: at, new_end_byte: at + inserted.len(),
                start_position: before.offset_to_point(at), old_end_position: before.offset_to_point(at), new_end_position: after.offset_to_point(at + inserted.len()),
            };
            assert!(h.changed(&[(edit, after.clone())]).is_none(), "no second parse while one is in flight");
            before = after;
        }
        let done = std::thread::spawn(move || job.run()).join().unwrap();
        assert!(h.finish(done));
        let mut fresh = SyntaxHighlighter::new(resources(), "rust").unwrap();
        fresh.reparse(&before);
        let range = 0..now.len();
        assert_eq!(h.runs(&range, Some(&theme)), fresh.runs(&range, Some(&theme)));
        // A restart while parsing: the first result is thrown away, the second one counts.
        let mut h = SyntaxHighlighter::new(resources(), "rust").unwrap();
        let (first_job, second_job) = (h.start_full(&old), h.start_full(&old));
        let (first_done, second_done) = (first_job.run(), second_job.run());
        assert!(!h.finish(first_done), "an abandoned parse is discarded");
        assert_eq!(h.runs(&(0..old.len()), Some(&theme)).len(), 1, "still plain text");
        assert!(h.finish(second_done));
        // Nothing in flight (the file was closed or reloaded and a later result arrives): discarded too.
        let late = h.start_full(&old).run();
        let current = h.start_full(&old).run();
        assert!(h.finish(current));
        assert!(!h.finish(late), "a result with no parse in flight changes nothing");
    }

    /// An edit as the editor makes it for the first look at a text (a zero-length replacement).
    fn replacement_edit(text: &Rope) -> InputEdit {
        use gpui_kit::base::input::RopeExt;
        let origin = text.offset_to_point(0);
        InputEdit { start_byte: 0, old_end_byte: 0, new_end_byte: 0, start_position: origin, old_end_position: origin, new_end_position: origin }
    }

    /// K-50 measurement (not run by default): what the UI thread spends when a big file is opened, and when the background
    /// parse is done. `K49_FILE=<path> K49_LANG=<id>` or `K49_SYNTH=markdown|html`, `--release`. Before the change the
    /// UI thread ran the whole parse (`reparse`); now it clones the text, waits `SYNC_PARSE_TIMEOUT` for the thread and
    /// installs the result.
    #[test]
    #[ignore]
    fn k50_measure() {
        use std::time::Instant;
        let (name, lang, text) = match (std::env::var("K49_FILE"), std::env::var("K49_SYNTH")) {
            (Ok(path), _) => (path.clone(), std::env::var("K49_LANG").expect("K49_LANG"), std::fs::read_to_string(&path).unwrap()),
            (_, Ok(kind)) => (format!("synthetic {kind}"), kind.clone(), k49_synthetic(&kind)),
            _ => return,
        };
        let rope = Rope::from_str(&text);
        let mut before = SyntaxHighlighter::new(resources(), &lang).expect("language and queries");
        let started = Instant::now();
        before.reparse(&rope);
        let sync_ms = started.elapsed().as_secs_f64() * 1000.0;
        let mut h = SyntaxHighlighter::new(resources(), &lang).unwrap();
        let t0 = Instant::now();
        let job = h.changed(&[(replacement_edit(&rope), rope.clone())]).unwrap();
        let (sender, receiver) = std::sync::mpsc::channel();
        std::thread::spawn(move || { sender.send(job.run()).ok(); });
        let waited = receiver.recv_timeout(super::SYNC_PARSE_TIMEOUT);
        let t1 = Instant::now();
        let (done, early) = match waited {
            Ok(done) => (done, true),
            Err(_) => (receiver.recv().unwrap(), false),
        };
        let background_ms = t0.elapsed().as_secs_f64() * 1000.0;
        let t2 = Instant::now();
        assert!(h.finish(done));
        let finish_ms = t2.elapsed().as_secs_f64() * 1000.0;
        // The UI thread: start + wait (at most the timeout) + installing the result; the thread's own parse is not it.
        let blocked_ms = t1.duration_since(t0).as_secs_f64() * 1000.0 + finish_ms;
        println!("K50 | {name} | {} lines | before: UI thread {sync_ms:.1} ms | after: UI thread {blocked_ms:.1} ms (finish {finish_ms:.2} ms, parse done within the wait: {early}) | background parse done after {background_ms:.1} ms",
            text.lines().count());
    }

    /// K-45: the texts of the symbols around the first byte of `marker` (one byte in), under distinct colours per key.
    fn symbols_of(id: &str, text: &str, marker: &str, keys: &[&str]) -> Option<Vec<OutlineSymbol>> {
        let h = parsed(id, text)?;
        let theme = theme(&keys.iter().enumerate().map(|(i, key)| (*key, style(i as u32 + 1))).collect::<Vec<_>>());
        Some(h.symbols(text.find(marker).expect("marker") + 1, Some(&theme)))
    }

    fn texts(symbols: &[OutlineSymbol]) -> Vec<&str> {
        symbols.iter().map(|s| s.text.as_str()).collect()
    }

    /// The Zed-capture expectations of SPEC R-12 (W-51) on the fixture files, when they are there (they live in the
    /// tauri workspace, read only), and the same shapes on small inline samples.
    #[test]
    fn code_symbols_match_the_zed_breadcrumb() {
        let rust = "pub struct Counter {\n    counts: u32,\n}\n\nconst MAX: u32 = 1;\n\nimpl Counter {\n    pub fn bump(&mut self, key: &str) -> u32 {\n        fn clamp(value: u32) -> u32 {\n            value.min(MAX)\n        }\n        clamp(1)\n    }\n}\n\nfn main() {}\n";
        if let Some(symbols) = symbols_of("rust", rust, "value.min", &[]) {
            assert_eq!(texts(&symbols), ["impl Counter", "pub fn bump", "fn clamp"]);
        }
        let ts = "export class Inventory<T> {\n  add(item: T): string {\n    function normalize(name: string): string {\n      return name.trim();\n    }\n    return normalize(item);\n  }\n}\n";
        if let Some(symbols) = symbols_of("typescript", ts, "return name", &[]) {
            assert_eq!(texts(&symbols), ["class Inventory", "add( )", "function normalize( )"]);
        }
        let py = "class Library:\n    def add(self, book):\n        def normalize(text):\n            return text.strip()\n\n        return normalize(book)\n";
        if let Some(symbols) = symbols_of("python", py, "return text", &[]) {
            assert_eq!(texts(&symbols), ["class Library", "def add", "def normalize"]);
        }
        // Outside every symbol: nothing, so the breadcrumb is the path only.
        if let Some(symbols) = symbols_of("rust", "// note\nuse std::fmt;\n\nfn main() {}\n", "use std", &[]) {
            assert!(symbols.is_empty(), "{symbols:?}");
        }
        // The fixtures themselves, at the lines R-12 names (21, 18, 21).
        let fixtures = std::path::Path::new(r"D:\projects\workbench-tauri\test-fixtures\syntax");
        for (file, id, line, want) in [
            ("sample.rs", "rust", 21, vec!["impl Counter", "pub fn bump", "fn clamp"]),
            ("sample.ts", "typescript", 18, vec!["class Inventory", "add( )", "function normalize( )"]),
            ("sample.py", "python", 21, vec!["class Library", "def add", "def normalize"]),
        ] {
            let Ok(text) = std::fs::read_to_string(fixtures.join(file)) else { continue };
            let Some(h) = parsed(id, &text) else { continue };
            let offset = text.split_inclusive('\n').take(line - 1).map(str::len).sum::<usize>() + 12;
            assert_eq!(texts(&h.symbols(offset, None)), want, "{file}:{line}");
        }
    }

    #[test]
    fn symbol_text_cuts_multi_line_nodes_and_keeps_syntax_colours() {
        let (keyword, function, type_) = (style(1), style(2), style(3));
        // `impl Foo<\n A,\n>`: the type node spans lines and is cut at the end of its first line.
        let rust = "impl Foo<\n    A,\n> {\n    fn f() {}\n}\n";
        if let Some(symbols) = symbols_of("rust", rust, "f() {}", &[]) {
            assert_eq!(texts(&symbols), ["impl Foo<", "fn f"]);
        }
        // Each piece keeps the editor's colour: `pub`/`fn` keyword, the name function.
        let source = "pub fn bump() {\n    let x = 1;\n}\n";
        let Some(h) = parsed("rust", source) else { return };
        let theme = theme(&[("keyword", keyword), ("function", function), ("type", type_)]);
        let symbols = h.symbols(source.find("let").unwrap(), Some(&theme));
        assert_eq!(texts(&symbols), ["pub fn bump"]);
        let runs = &symbols[0].runs;
        let at = |offset: usize| runs.iter().find(|(r, _)| r.contains(&offset)).map(|(_, s)| *s);
        assert_eq!((at(0), at(4), at(7)), (Some(keyword), Some(keyword), Some(function)), "{runs:?}");
    }

    /// K-45: Markdown headings from the outline query equal the line scan the path line uses, away from heading
    /// boundaries (the scan counts a cursor on a heading's own line; the outline touches the neighbours there).
    #[test]
    fn markdown_outline_agrees_with_the_heading_scan_inside_sections() {
        let text = "# AGENTS\nbody\n## 레포 규칙\nrule\n## 다른\n### 깊은\nx\n";
        for marker in ["body", "rule", "x"] {
            let Some(symbols) = symbols_of("markdown", text, marker, &[]) else { return };
            let scan = super::super::breadcrumb::heading_trail(text, text.find(marker).unwrap() + 1);
            assert_eq!(texts(&symbols), scan, "{marker}");
        }
    }

    #[test]
    fn html_sample_gets_theme_colours() {
        let text = "<!DOCTYPE html>\n<!-- c -->\n<a href=\"x.html\" id='y'>t &amp; u</a>\n";
        let keys = ["tag", "tag.doctype", "attribute", "string", "comment", "string.special", "punctuation.bracket"];
        for (needle, want) in [
            ("DOCTYPE", 1), ("<!-- c", 4), ("a href", 0), ("href", 2), ("x.html", 3), ("id", 2), ("y'", 3), ("&amp;", 5), ("<a", 6),
        ] {
            if let Some(got) = colour_of("html", text, &keys, needle) { assert_eq!(got, Some(want), "HTML: {needle}"); }
        }
        // Text content is not coloured.
        if let Some(got) = colour_of("html", text, &keys, "t &") { assert_eq!(got, None); }
        for file in ["index.html", "old.htm", "page.shtml"] {
            assert_eq!(language_id(Path::new(file), ""), "html", "{file}");
        }
    }

    #[test]
    fn markdown_block_grammar_colours_headings_and_list_markers() {
        let (title, marker) = (style(1), style(2));
        let Some(h) = parsed("markdown", "# Title\n\n- item\n\ntext\n") else { return };
        let theme = theme(&[("title", title), ("punctuation.list_marker", marker)]);
        let runs = h.runs(&(0..21), Some(&theme));
        assert_eq!((style_at(&runs, 0), style_at(&runs, 4)), (title, title));
        assert_eq!(style_at(&runs, 9), marker);
        assert_eq!(style_at(&runs, 11), HighlightStyle::default(), "list text is inline grammar (K-44)");
        assert_eq!(style_at(&runs, 17), HighlightStyle::default(), "paragraph");
    }

    #[test]
    fn edited_tree_gives_the_same_runs_as_a_full_parse() {
        use gpui_kit::base::input::RopeExt;
        let old_text = "fn a() {}\nfn 가() { /* 한 */ }\n";
        let (old, new) = (Rope::from_str(old_text), Rope::from_str(&format!("{}let x = \"글\";{}", &old_text[..7], &old_text[7..])));
        let inserted = "let x = \"글\";".len();
        let theme = theme(&[("keyword", style(1)), ("string", style(2)), ("comment", style(3)), ("function", style(4))]);
        let (Some(mut incremental), Some(full)) = (parsed("rust", old_text), parsed("rust", &new.to_string())) else { return };
        incremental.edit(&InputEdit {
            start_byte: 7,
            old_end_byte: 7,
            new_end_byte: 7 + inserted,
            start_position: old.offset_to_point(7),
            old_end_position: old.offset_to_point(7),
            new_end_position: new.offset_to_point(7 + inserted),
        });
        incremental.reparse(&new);
        let range = 0..new.len();
        let runs = incremental.runs(&range, Some(&theme));
        assert_eq!(runs, full.runs(&range, Some(&theme)));
        assert_covers(&runs, &range);
        assert_eq!(style_at(&runs, 7 + 9), style(2), "the inserted string is coloured");
    }

    #[test]
    fn runs_never_split_a_multibyte_character() {
        let text = "fn 가나() { let s = \"한글 😀\"; } // 끝\n";
        let Some(h) = parsed("rust", text) else { return };
        let theme = theme(&[("keyword", style(1)), ("string", style(2)), ("comment", style(3)), ("function", style(4))]);
        let range = 0..text.len();
        let runs = h.runs(&range, Some(&theme));
        assert_covers(&runs, &range);
        for (run, _) in &runs {
            assert!(text.is_char_boundary(run.start) && text.is_char_boundary(run.end), "{run:?}");
        }
        // A request that starts and ends mid-file (a visible line group) is covered exactly too.
        let line = text.find("let").unwrap()..text.find('\n').unwrap();
        assert_covers(&h.runs(&line, Some(&theme)), &line);
    }

    #[test]
    fn language_by_name_or_first_line_selects_a_highlighter() {
        for (file, text, id) in [("a.rs", "", "rust"), ("b.json", "", "json"), ("tsconfig.json", "", "jsonc"), ("README.md", "", "markdown"),
            ("run", "#!/usr/bin/env python3\nprint()", "python"), ("notes.xyz", "", ""), ("run", "plain", "")] {
            assert_eq!(language_id(Path::new(file), text), id, "{file}");
        }
        let source = EditorExtras::default();
        let make = highlighter_factory(&source);
        if resources().queries("rust").is_some() {
            for id in ["rust", "json", "jsonc", "markdown", "c", "cpp", "css", "bash", "env", "diff", "gitcommit", "go", "gomod", "gowork", "html",
                "python", "javascript", "typescript", "tsx", "yaml", "jsdoc", "regex", "zed-keybind-context"] {
                assert_eq!(make(id).map(|h| h.language().to_string()), Some(id.to_string()));
            }
        }
        // No highlighter: plain text, unknown, or not linked yet.
        assert!(make("").is_none());
        assert!(make("no-such-language").is_none());
        let missing = std::env::temp_dir().join(format!("missing-k42b-{}", crate::state::win::new_uuid()));
        let none: &'static QueryResources = Box::leak(Box::new(QueryResources::load(&missing)));
        assert!(SyntaxHighlighter::new(none, "rust").is_none());
    }

    #[test]
    fn missing_queries_are_plain_text() {
        let root = std::env::temp_dir().join(format!("missing-k42a-{}", crate::state::win::new_uuid()));
        assert!(!root.exists());
        let resources = QueryResources::load(&root);
        assert_eq!(resources.errors.len(), LANGUAGES.len());
        for language in LANGUAGES { assert!(resources.queries(language.id).is_none()); }
    }

    #[test]
    fn copied_queries_compile_and_parse() {
        let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("resources/zed-languages");
        if !root.is_dir() {
            eprintln!("SKIP: run tools/fetch-zed-languages.ps1 to test local queries");
            return;
        }
        let resources = QueryResources::load(&root);
        assert!(resources.errors.is_empty(), "{:?}", resources.errors);
        for (id, sample, count) in [
            ("rust", "fn main() { let x = 1; }", 3),
            ("json", "{\"name\": true}", 2),
            ("jsonc", "{\"name\": true}", 3),
            ("markdown", "# Title\n\ntext\n", 3),
            ("markdown-inline", "**bold** and `code`", 2),
            ("c", "int add(int a) { return a; }", 3),
            ("cpp", "class A { int f(); };", 3),
            ("css", "a { color: red; }", 3),
            ("bash", "echo \"$A\"\n", 2),
            ("env", "export A=\"b\"\n", 2),
            ("diff", "--- a\n+++ b\n@@ -1 +1 @@\n-x\n+y\n", 2),
            ("gitcommit", "fix: thing\n\n# comment\n", 2),
            ("go", "package main\nfunc f() {}\n", 3),
            ("gomod", "module example.com/m\n\ngo 1.21\n", 2),
            ("gowork", "go 1.21\nuse ./a\n", 2),
            ("html", "<p class=\"a\">x</p>", 3),
            ("python", "def f(a):\n    return a\n", 3),
            ("javascript", "const f = (a) => a;\n", 3),
            ("typescript", "let a: number = 1;\n", 3),
            ("tsx", "const a = <div id=\"x\"/>;\n", 3),
            ("yaml", "a: 1\nb: [x]\n", 3),
            ("jsdoc", "/**\n * @param {string} a\n */", 1),
            ("regex", "a(b|c)+", 1),
            ("zed-keybind-context", "a && b;", 1),
        ] {
            let language = grammar(id).unwrap();
            let mut parser = Parser::new();
            parser.set_language(&language).unwrap();
            let tree = parser.parse(sample, None).unwrap();
            assert!(!tree.root_node().has_error(), "{id}");
            let queries = resources.queries(id).unwrap();
            assert_eq!(queries.len(), count, "{id}");
            let mut cursor = QueryCursor::new();
            assert!(cursor.captures(&queries[0], tree.root_node(), sample.as_bytes()).next().is_some(), "{id}");
        }
    }
}

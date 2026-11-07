// Compiles the vendored tree-sitter parsers (see each vendor/tree-sitter-*/SOURCE.md for why they are not crates).
fn main() {
    // (folder, name of the static library, whether the grammar has an external scanner)
    for (folder, name, scanner) in [
        ("tree-sitter-html", "tree-sitter-html", true),
        ("tree-sitter-toml", "tree-sitter-toml", true),
        ("tree-sitter-git-config", "tree-sitter-git-config", false),
        ("tree-sitter-gitignore", "tree-sitter-gitignore", false),
    ] {
        let src = std::path::Path::new("vendor").join(folder).join("src");
        let mut build = cc::Build::new();
        build
            .include(&src)
            .file(src.join("parser.c"))
            .flag_if_supported("-Wno-unused-parameter")
            .flag_if_supported("-Wno-unused-but-set-variable")
            .flag_if_supported("-Wno-trigraphs");
        if scanner {
            build.file(src.join("scanner.c"));
        }
        build.compile(name);
        // Only the vendored files (and this script) trigger a rebuild.
        println!("cargo:rerun-if-changed=vendor/{folder}/src");
    }
    println!("cargo:rerun-if-changed=build.rs");
}

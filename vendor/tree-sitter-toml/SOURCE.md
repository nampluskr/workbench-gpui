# tree-sitter-toml (vendored generated C sources)

- Repository: https://github.com/tree-sitter/tree-sitter-toml
- Rev: `342d9be207c2dba869b9967124c679b5e6fd0ebe` (the grammar of Zed's TOML extension zed-extensions/toml v1.1.0, `extension.toml`; parser LANGUAGE_VERSION 13)
- License: MIT (`LICENSE`, copied verbatim from the repository root)
- Why vendored: the repository's Rust crate (`tree-sitter-toml 0.5.1`) needs `tree-sitter ~0.20` and `cc ~1.0`, which cannot resolve with the app's tree-sitter 0.28 (K-48). The generated parser (ABI 13) works with 0.28, so `build.rs` compiles it directly.
- Files are byte-for-byte copies from the repository at that rev. Do not edit or regenerate them.

| File (relative to this folder) | SHA256 |
|---|---|
| `LICENSE` | `b727eee929bee836e8102cecf749a795b199f291b58c885bcd81cae727ac5a46` |
| `src/parser.c` | `ad4d8d34ff35537ce029565132b97e04d3f77b4219b443fea5072965314193cc` |
| `src/scanner.c` | `59dcf6a51db3b53e4c33ac268221ce4e228c6855ca89d1e3f81786112120766f` |
| `src/tree_sitter/parser.h` | `ab104936984904469572a4e868149f7a22fb2929347f837ae6a1f9b790f1b173` |

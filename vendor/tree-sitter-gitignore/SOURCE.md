# tree-sitter-gitignore (vendored generated C sources)

- Repository: https://github.com/shunsambongi/tree-sitter-gitignore
- Rev: `f4685bf11ac466dd278449bcfe5fd014e94aa504` (a grammar of Zed's git-firefly extension d1y/git_firefly v0.1.9; parser LANGUAGE_VERSION 13)
- License: MIT (`LICENSE`, copied verbatim from the repository root)
- Why vendored: the repository's Rust crate (`tree-sitter-ignore 0.0.1`) needs `tree-sitter ~0.20` and `cc ~1.0`, which cannot resolve with the app's tree-sitter 0.28 (K-48). The generated parser (ABI 13) works with 0.28, so `build.rs` compiles it directly.
- Files are byte-for-byte copies from the repository at that rev. Do not edit or regenerate them.

| File (relative to this folder) | SHA256 |
|---|---|
| `LICENSE` | `ad6e5155699c741cfb3604bd2c296bd214b1f0f7fe5a1446908088add652a29b` |
| `src/parser.c` | `5c396f71afa63a1fd69355b833de150ad5a2b8b28edbbe5c9852587c27eade4d` |
| `src/tree_sitter/parser.h` | `909d292e80a297836c0a4dd2a49441ff982adc14230b4100ff43856cbb1d2247` |

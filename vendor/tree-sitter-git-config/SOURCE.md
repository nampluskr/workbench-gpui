# tree-sitter-git-config (vendored generated C sources)

- Repository: https://github.com/the-mikedavis/tree-sitter-git-config
- Rev: `3a61756a81a86291a0f48e3eeeaa0692b9981aa9` (a grammar of Zed's git-firefly extension d1y/git_firefly v0.1.9; parser LANGUAGE_VERSION 14)
- License: MIT (`LICENSE`, copied verbatim from the repository root)
- Why vendored: the repository's Rust crate (`tree-sitter-git-config 0.0.1`) needs `tree-sitter ~0.20` and `cc ~1.0`, which cannot resolve with the app's tree-sitter 0.28 (K-48). The generated parser (ABI 14) works with 0.28, so `build.rs` compiles it directly.
- Files are byte-for-byte copies from the repository at that rev. Do not edit or regenerate them.

| File (relative to this folder) | SHA256 |
|---|---|
| `LICENSE` | `985c32d2d8721deb8ff66a6b8f801cd49d92fdd300338e62bc9f32559d39f8f8` |
| `src/parser.c` | `1e3a9ab3487b9d2d084971e25d2be997893f2f23b87155d684096b5013a2fc93` |
| `src/tree_sitter/alloc.h` | `d363091b9954cbb609b5e83fb29dcfe77669ed77082e6943edbb26b9c0c5e27e` |
| `src/tree_sitter/array.h` | `9fcb0824a6e38083a40d9e0158b207fd7e6cf7c1efb8046905e59eebbfa7b9dd` |
| `src/tree_sitter/parser.h` | `cdf4a34c3c10b0627c806560d3b605127e1cca4350651288548447423e8e4644` |

# tree-sitter-html (vendored generated C sources)

- Repository: https://github.com/tree-sitter/tree-sitter-html
- Rev: `bfa075d83c6b97cd48440b3829ab8d24a2319809` (the grammar Zed's HTML extension uses, `extensions/html/extension.toml`, extension 0.3.2)
- License: MIT (`LICENSE`, copied verbatim from the repository root)
- Why vendored: the repository's Rust crate (`tree-sitter-html 0.20.2`) needs `tree-sitter ~0.20.10` and `cc ~1.0.83`, which cannot resolve with the app's tree-sitter 0.28 (`cc ^1.2.63`). The generated parser (`LANGUAGE_VERSION 14`) works with 0.28, so `build.rs` compiles it directly. See `specs/v0.5/cards/K-43A.report.md` 2장 and `K-43A-R1.report.md`.
- Files are byte-for-byte copies from the repository at that rev. Do not edit or regenerate them.

| File (relative to this folder) | SHA256 |
|---|---|
| `src/parser.c` | `75aea73263a2828ca4ac6b4dc572e9c062d66d7821c79f0d6e54447816f125f3` |
| `src/scanner.c` | `fef80b4f34828718a8c72a7e42de3670e85402456e4cbe146915c83a6bac2b89` |
| `src/tag.h` | `aaf1a10c8a2f685ef51a4aa6c01a2cbe166bff67eeccf6b9501a625b71f9ab70` |
| `src/tree_sitter/alloc.h` | `253b44a7b4313a7afd0c505c2fc6e7ce4b8e78955ebf4be3ea000532ec060673` |
| `src/tree_sitter/array.h` | `4ff743903dc46f5db6aa54f31c6b4d160a8a9779e5b2ab1ee59ae7ebcd850ea1` |
| `src/tree_sitter/parser.h` | `8e819abdeba5866bf1aaf6e7b97522241c903d94a18395c6a75ed02984270ee8` |
| `LICENSE` | `2e0110e07abef7c2548b26ec9d6969775617ca539a0dc8dbeeb14d6452c711d1` |

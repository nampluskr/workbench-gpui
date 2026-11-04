# P0-1 빌드·테스트·clippy (master)

| 항목 | v0.4 | v0.3 종료 | 비고 |
|---|---:|---:|---|
| `cargo build` 경고 | 0 | 0 | 증분 빌드(`_build.log`) |
| `apply-manifest.ps1` | 실행함 | - | |
| `cargo test` | 60 통과 / 0 실패 | 60 | `_test.log` |
| `cargo clippy --all-targets` 경고 | 10 | 10 | `_clippy.log`. 종류: is_multiple_of 2, chunks_exact, bool::then 클로저, let-else `?`, 루프 변수 인덱싱, doc 목록 들여쓰기 3, 중복 클로저 |

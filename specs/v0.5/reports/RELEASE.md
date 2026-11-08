> 보고: RELEASE · 작성일: 2026-11-08 · 보낸 이: gpui-leader · 받는 이: core-leader · 상위 지시: core [ORDER] 배포본(사용자 지시, v0.5 종료 뒤 사용자 요청 작업) · 카드 K-51(coder) · C-46(checker, PASS) · W-59(writer, PROGRESS)

# RELEASE — 다른 PC에서 도는 배포본

## 결론

master f18fd03 위 변경으로 exe 옆 `resources\`를 읽고 VC++ 런타임 없이 도는 배포본을 만들었다. 레포 밖 `%TEMP%` 경로에 복사해 띄운 exe가 자기 옆 `resources`를 읽었다(C-46 4단계). 전체 테스트 319 통과(3 ignored), clippy 경고 0.

## 바꾼 것

| 항목 | 내용 |
|---|---|
| resources 경로 | `src/ui/zed_icons.rs` `resources_dir()` 하나로 모음. exe 폴더 옆 `resources\`가 있으면 그것, 없으면 `CARGO_MANIFEST_DIR\resources`(개발용). 한 번만 정하고 stderr에 `resources: <경로>` 한 줄. `theme.rs`·`icon_theme.rs`·`syntax.rs`·`extensions.rs`·`zed_icons.rs`(Assets)가 이 함수를 쓴다. 테스트 코드의 `CARGO_MANIFEST_DIR`·`include_str!`/`include_bytes!`는 그대로. 선택 로직 테스트 `resources_prefer_dir_next_to_exe`. |
| 정적 CRT | `.cargo/config.toml`(새 파일) `[target.x86_64-pc-windows-msvc] rustflags = ["-C", "target-feature=+crt-static"]`. `Cargo.toml`·`Cargo.lock`·`vendor/` 변경 없음. 링크 오류 없음. |
| 패키지 스크립트 | `tools/package-release.ps1`(새 파일). `cargo build --release`(`-NoBuild`로 건너뜀) → `apply-manifest.ps1`(release exe) → `target\dist\workbench-gpui\`(exe + `resources\` 4폴더)와 `target\dist\workbench-gpui.zip`. 4폴더가 없으면 fetch 스크립트 이름을 알리고 실패. 지우는 것은 그 폴더와 zip뿐. |

## 배포본

| 항목 | 경로 | 크기 |
|---|---|---|
| exe | `target\dist\workbench-gpui\workbench-gpui.exe` | 41.61 MB(43,631,616 B). 바꾸기 전 41.38 MB(43,394,560 B) → 정적 CRT로 +0.23 MB |
| 배포 폴더 | `D:\projects\workbench-gpui\target\dist\workbench-gpui\` | 47.22 MB, 5,751 파일(exe + `resources\zed-icon-themes`·`zed-icons`·`zed-themes`·`zed-languages`) |
| zip | `D:\projects\workbench-gpui\target\dist\workbench-gpui.zip` | 16.36 MB(17,154,349 B) |

- 배포 폴더와 zip은 `target\` 아래라 git에 들어가지 않는다. 다시 만들 때: `pwsh -NoProfile -File tools/package-release.ps1`.
- 받는 쪽: zip을 풀고 `workbench-gpui\workbench-gpui.exe`를 실행한다. `resources\`는 exe와 같은 폴더에 둔다.

## 확인

| 확인 | 결과 | 근거 |
|---|---|---|
| VCRUNTIME 의존 | `dumpbin /dependents`에 `VCRUNTIME140`·`MSVCP`·`api-ms-win-crt-*`·`ucrt` 없음. 남은 DLL은 전부 OS 제공(KERNEL32, USER32, d3d11, dxgi, dwrite, dcomp, icuuc 등 26개) | K-51 보고, C-46 3절 |
| 다른 경로 실행 | `C:\Users\nampl\AppData\Local\Temp\c46-run-23e06da8\`에 배포 폴더를 복사해 exe 1회 실행(PID 18664, 6초 뒤 살아 있음). stderr 한 줄 `resources: C:\Users\nampl\AppData\Local\Temp\c46-run-23e06da8\resources`, 다른 오류 없음. 그 PID만 닫음. 화면 조작·캡처 없음([SCREEN-OK]·[SCREEN-DONE]) | C-46 4절 |
| 테스트 | `cargo test` 전체 319 passed, 0 failed, 3 ignored | C-46 1절 |
| clippy | `cargo clippy --all-targets -- -D warnings` 경고 0 | K-51, C-46 |

## 남은 제약

1. **실제 다른 PC에서는 아직 안 돌려 봤다.** 같은 PC의 다른 경로에서만 확인했다. VC++ 재배포 패키지가 없는 PC에서 뜨는지, 아이콘·테마·문법 강조가 실제로 보이는지는 사용자 확인이 필요하다.
2. **콘솔 창이 같이 뜬다.** `main.rs`에 `windows_subsystem = "windows"`가 없어 exe를 더블클릭하면 콘솔 창이 함께 열린다(stderr `resources:` 줄이 거기 찍힌다). 이번 지시 범위 밖이라 바꾸지 않았다.
3. **OS 조건:** `icuuc.dll`은 Windows 10 1703 이상의 시스템 DLL이다. 긴 경로 지원(longPathAware)은 그 PC의 레지스트리 `LongPathsEnabled`도 1이어야 켜진다. x64 Windows만 대상이다(정적 CRT 설정은 `x86_64-pc-windows-msvc`에만).
4. **`resources\` 판단은 폴더 존재만 본다.** exe 옆에 빈 `resources\`가 있으면 그 폴더를 쓴다(개발 경로로 넘어가지 않는다). 개발 경로(`CARGO_MANIFEST_DIR`) 문자열은 exe에 그대로 남아 있다.
5. **서명 없음.** exe에 코드 서명이 없어 다른 PC에서 SmartScreen 경고가 뜰 수 있다(확인 안 함).
6. **빌드 시간:** rustflags가 바뀌어 공유 `target`의 모든 프로필이 한 번씩 전부 다시 빌드됐다(debug 3분 36초, release 5분 2초 등, K-51). 이후 빌드는 다시 증분이다.
7. **실행 방식:** 이번 작업은 herdr 서브 에이전트 pane이 떠 있지 않아 leader가 Claude Code 내부 서브 에이전트(Sonnet)로 coder·checker 카드를 돌렸다.

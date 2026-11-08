# 배포본 빌드

workbench-gpui를 소스에서 빌드하고, 다른 PC로 옮겨 실행할 배포 폴더와 zip을 만드는 과정이다. Windows(x64) 전용이다. 새 PC(예: 개인 노트북)에서 `git clone` 한 뒤 0절 순서만 따라 하면 배포본까지 만들 수 있게 썼다.

근거: [RELEASE 보고](../specs/v0.5/reports/RELEASE.md), [K-51 보고](../specs/v0.5/cards/K-51.report.md), [C-46 리뷰](../specs/v0.5/verify/reviews/C-46.md), `tools/package-release.ps1`, `tools/apply-manifest.ps1`, `tools/fetch-zed-*.ps1`, `build.rs`, `.cargo/config.toml`, `Cargo.toml`, `specs/v0.5/HERDR-SETUP.md` 2.2, W-61 카드(leader 코드 확인). 수치는 2026-11-08 이 PC(멀티 에이전트 데스크톱) 값이다.

> 이 문서의 순서는 코드 읽기로만 확인했다. 깨끗한 clone에서 이 문서대로 처음부터 빌드해 본 기록은 아직 없다(7절).

## 0. 처음부터 순서

PowerShell 창에서 차례로 실행한다. 명령은 그대로 복사해 쓴다.

1. **도구 설치**(1절). Windows에 기본으로 있는 PowerShell(5.1)에서 실행해도 된다.

   ```powershell
   winget install --id Git.Git -e
   winget install --id Microsoft.PowerShell -e
   winget install --id Microsoft.VisualStudio.2022.BuildTools -e --override "--wait --passive --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.Windows11SDK.26100 --includeRecommended"
   winget install --id Rustlang.Rustup -e
   ```

   - 시간: 측정 안 함.

2. **새 터미널을 연다.** 설치한 도구의 PATH는 새로 연 터미널에서만 잡힌다. 이후 단계는 PowerShell 7(`pwsh`) 창에서 한다.

3. **Rust 버전 맞추기와 설치 확인.**

   ```powershell
   rustup toolchain install 1.99.1
   rustup default 1.99.1
   git --version
   pwsh -v
   rustc -V
   cargo -V
   rustup show active-toolchain
   ```

   - 확인: `rustc -V`가 `rustc 1.99.1 (58cf8f9c3 2026-10-13)`, `rustup show active-toolchain`이 `1.99.1-x86_64-pc-windows-msvc`로 시작하면 된다.

4. **clone.** 받을 폴더는 마음대로 정한다.

   ```powershell
   git clone https://github.com/nampluskr/workbench-gpui.git
   cd workbench-gpui
   ```

5. **복사본 채우기(fetch)**(2절). 레포 루트(`workbench-gpui`)에서 실행한다.

   ```powershell
   pwsh -NoProfile -File tools/fetch-zed-icons.ps1
   pwsh -NoProfile -File tools/fetch-zed-themes.ps1
   pwsh -NoProfile -File tools/fetch-zed-languages.ps1
   ```

   - 확인(각 스크립트의 마지막 줄):
     - icons: `Fetched 4304dec732a75505066de5ce2dbbfb2bec369498 : 299 UI icons, 96 file icons`
     - themes: `zed-icon-theme: 4304dec732a75505066de5ce2dbbfb2bec369498, ...`(그 앞에 `zed:`·`catppuccin:`·`macos-classic:`·`catppuccin-icons:` 줄)
     - languages: `zed-languages: 4304dec732a75505066de5ce2dbbfb2bec369498 + 2 extensions, ...`
   - 실패하면 빨간 오류(`git failed: ...` 등)가 나고 멈춘다.
   - 시간: 측정 안 함.

6. **배포본 만들기**(3절).

   ```powershell
   pwsh -NoProfile -File tools/package-release.ps1
   ```

   - 확인: 마지막 세 줄이 `folder: ...`, `zip: ... (... MB)`, `size: ... MB, ... files`다.
   - 시간: 이 PC에서 처음부터 5분 23초. 새 PC에서는 cargo가 crates·git 의존성을 받는 시간이 더해지고, PC 사양에 따라 다르다(5절).

7. **결과**(4절): `<레포>\target\dist\workbench-gpui\`(배포 폴더)와 `<레포>\target\dist\workbench-gpui.zip`. 옮기는 법은 6절.

## 1. 필요한 도구와 버전

| 도구 | 버전·조건 | 설치 명령 | 쓰는 곳 |
| --- | --- | --- | --- |
| git | | `winget install --id Git.Git -e` | clone, fetch 스크립트가 고정 커밋을 받는다 |
| PowerShell 7 | `pwsh` | `winget install --id Microsoft.PowerShell -e` | `tools/*.ps1`(`#Requires -Version 7`) |
| Visual Studio Build Tools 2022 | MSVC C++ 도구 | 아래 Build Tools 명령 | C 소스 크레이트 컴파일과 링크 |
| Windows SDK | 10.0.26100.0 | Build Tools 명령에 포함 | `mt.exe`(`apply-manifest.ps1`이 PATH 또는 `C:\Program Files (x86)\Windows Kits\10\bin\<버전>\x64\`에서 찾는다) |
| Rust | 1.99.1(`rustc 1.99.1 (58cf8f9c3 2026-10-13)`, `cargo 1.99.1`), edition 2024, 대상 `x86_64-pc-windows-msvc` | `winget install --id Rustlang.Rustup -e` 뒤 `rustup toolchain install 1.99.1`, `rustup default 1.99.1` | 빌드 전체. 최소 Rust 버전은 정하지 않았다 |
| 네트워크 | 처음 한 번, github.com·crates.io | | fetch 스크립트(GitHub), crates.io·git 의존성(`Cargo.toml`) |

Build Tools(C++ 도구 + Windows SDK 10.0.26100):

```powershell
winget install --id Microsoft.VisualStudio.2022.BuildTools -e --override "--wait --passive --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.Windows11SDK.26100 --includeRecommended"
```

- winget ID와 Build Tools 구성 요소 ID는 이 PC에서 실행해 확인하지 않았다.
- Build Tools를 GUI(Visual Studio Installer)로 설치할 때는 워크로드 "C++를 사용한 데스크톱 개발"과 개별 구성 요소 "Windows 11 SDK(10.0.26100)"를 고른다.
- Windows SDK는 기본 위치(`C:\Program Files (x86)\Windows Kits\10`)에 둔다. `apply-manifest.ps1`은 PATH에 `mt.exe`가 없으면 이 경로만 찾는다.
- Rust 버전: 저장소에 `rust-toolchain` 파일이 없으므로 `rustup default 1.99.1`로 맞춘다. 기본 대상은 `x86_64-pc-windows-msvc`다.
- 설치 확인: `git --version`, `pwsh -v`, `rustc -V`, `cargo -V`, `rustup show active-toolchain`.
- 이 PC 값(참고): `winget v1.29.380`, Rust `1.99.1`.
- Node와 tree-sitter CLI는 필요 없다. 문법은 크레이트와 vendored C 소스로 빌드한다.
- `build.rs`: 저장소 안 `vendor/`의 tree-sitter 문법 4개(html·toml·git-config·gitignore)의 `parser.c`(있으면 `scanner.c`)를 `cc`로 정적 라이브러리로 컴파일한다. `vendor/` 밖은 읽지 않는다.
- `Cargo.toml`의 git 의존성은 전부 GitHub 공개 저장소의 고정 rev다. `[patch.crates-io] gpui-base`는 저장소 안 `vendor/gpui-base`(git 추적)다. 문법 wasm 같은 다른 복사본은 없다.

## 2. 복사본 채우기(fetch)

실행 중 읽는 `resources\` 아래 4폴더는 `.gitignore` 대상이라 저장소에 없다. 새로 clone하면 빌드·패키지 전에 아래 세 스크립트를 꼭 실행한다. 세 스크립트는 서로 다른 폴더를 채우므로 순서는 상관없다.

```powershell
pwsh -NoProfile -File tools/fetch-zed-icons.ps1
pwsh -NoProfile -File tools/fetch-zed-themes.ps1
pwsh -NoProfile -File tools/fetch-zed-languages.ps1
```

- 각 스크립트는 GitHub 공개 저장소의 고정 커밋·태그를 `%TEMP%`에 새로 sparse clone해서 필요한 파일만 복사한다.
- 이 PC에만 있는 것(`D:\projects` 경로, `%TEMP%`에 미리 있던 Zed 사본, 설치된 Zed·확장 폴더, 로컬 캐시)에는 기대지 않는다. `fetch-zed-themes.ps1`의 `zed\zed.json`도 그때 받은 Zed 소스(`crates/theme/src/icon_theme.rs`)에서 만든다. 그래서 새 PC에서 따로 준비할 복사본은 없다.
- 필요한 것은 git, PowerShell 7, 네트워크(github.com)뿐이다. 회사망 등에서 github.com이 막혀 있으면 fetch(그리고 cargo의 git 의존성)가 실패한다.

| 스크립트 | 채우는 폴더 | 받는 곳·고정 커밋 |
| --- | --- | --- |
| `fetch-zed-icons.ps1` | `resources\zed-icons` | `zed-industries/zed` `4304dec732a75505066de5ce2dbbfb2bec369498`의 `assets/icons`(UI 아이콘 299개, 파일 아이콘 96개를 확인)와 `LICENSE-APACHE`·`LICENSE-GPL` |
| `fetch-zed-themes.ps1` | `resources\zed-themes` | `zed-industries/zed` `4304dec7…`의 `assets/themes`, `catppuccin/zed` 태그 `v0.2.27`, `huacnlee/zed-theme-macos-classic` 태그 `v0.4.0`. 각 저장소의 `LICENSE*`·`extension.toml` |
| | `resources\zed-icon-themes` | `catppuccin/zed-icons` 태그 `v1.24.0`(`icon_themes`·`icons`), 그리고 Zed `4304dec7…`의 `crates/theme/src/icon_theme.rs`에서 연결 표(데이터)만 읽어 만든 `zed\zed.json`. Rust 코드는 복사하지 않는다. `zed.json`은 `zed-icons`의 svg를 가리킨다 |
| `fetch-zed-languages.ps1` | `resources\zed-languages` | Zed `4304dec7…`의 `crates/grammars/src/<언어>`와 `extensions/html/languages/html`의 `highlights.scm`·`injections.scm`·`outline.scm`(24폴더), `zed-extensions/toml` `8e18e5045841f0f265f9c8b89f138c7f7dd09e2e`(toml), `d1y/git_firefly` `c63c6c0287ab5c8eb3872cf2bc8803e21c7a9675`(gitattributes·gitconfig·gitignore·gitrebase). Zed `LICENSE-GPL`·`LICENSE-APACHE`, 파일별 sha256을 적은 `manifest.json` |

`package-release.ps1`은 4폴더 중 하나라도 없으면 해당 fetch 스크립트 이름을 알리고 빌드 전에 실패한다.

## 3. 빌드 명령

명령은 레포 루트에서 실행한다.

`CARGO_TARGET_DIR`은 기본으로 설정하지 않는다. 비워 두면 cargo와 `package-release.ps1` 모두 `<레포>\target`을 쓴다. `package-release.ps1`은 이 변수가 있으면 그 값을 쓰고, 상대 경로는 레포 루트 기준으로 푼다.

- 참고(멀티 에이전트 데스크톱 전용): 이 PC는 여러 에이전트가 빌드를 공유하려고 `$env:CARGO_TARGET_DIR = 'D:\projects\workbench-gpui\target'`을 세션마다 지정한다(`AGENTS.md` 2장). 새 PC에서는 하지 않는다.

### 개발 빌드

```powershell
cargo build
pwsh -NoProfile -File tools/apply-manifest.ps1
.\target\debug\workbench-gpui.exe
```

`apply-manifest.ps1`은 gpui가 넣은 매니페스트에 `longPathAware`를 `mt.exe`로 병합한다. 기본 대상은 `target\debug\workbench-gpui.exe`(현재 폴더 기준)다. `cargo build`를 하면 병합이 사라지므로 빌드할 때마다 다시 실행한다. 확인 항목(commonControlsV6·perMonitorV2·longPathAware) 중 하나라도 false면 exit 1이다.

### 배포본

```powershell
pwsh -NoProfile -File tools/package-release.ps1           # 빌드부터
pwsh -NoProfile -File tools/package-release.ps1 -NoBuild  # 이미 release 빌드했을 때
```

스크립트 단계:

1. `resources\` 4폴더(`zed-icon-themes`·`zed-icons`·`zed-themes`·`zed-languages`)가 있는지 본다. 없으면 실패.
2. `cargo build --release`(`-NoBuild`면 건너뜀).
3. `apply-manifest.ps1 -Exe <target>\release\workbench-gpui.exe -DumpTo <target>\manifest\release-manifest.xml`(출력은 숨긴다).
4. 이전 `target\dist\workbench-gpui\`와 `target\dist\workbench-gpui.zip`만 지우고 새로 만든다.
5. exe와 4폴더를 `target\dist\workbench-gpui\`에 복사하고 `workbench-gpui.zip`으로 묶는다.
6. `folder:`(폴더 경로), `zip:`(zip 경로와 크기), `size:`(폴더 크기·파일 수) 세 줄을 출력한다.

- 정적 CRT: `.cargo/config.toml`의 `[target.x86_64-pc-windows-msvc] rustflags = ["-C", "target-feature=+crt-static"]`. 그래서 VC++ 재배포 패키지가 필요 없다. rustflags가 바뀌면 같은 `target`의 모든 프로필이 처음부터 다시 빌드된다.
- 설치 파일(msi 등)은 만들지 않는다. 배포 형태는 폴더와 zip뿐이다.

## 4. 결과 파일

| 항목 | 경로 | 크기(2026-11-08, 이 PC) |
| --- | --- | --- |
| exe | `<레포>\target\dist\workbench-gpui\workbench-gpui.exe` | 41.61 MB(43,631,616 B) |
| 배포 폴더 | `<레포>\target\dist\workbench-gpui\` | 47.22 MB, 5,751 파일 |
| zip | `<레포>\target\dist\workbench-gpui.zip` | 16.36 MB(17,154,349 B) |

`CARGO_TARGET_DIR`을 지정했다면 `<레포>\target` 대신 그 폴더 아래 `dist\`다.

```
workbench-gpui\
  workbench-gpui.exe
  resources\
    zed-icon-themes\
    zed-icons\
    zed-languages\
    zed-themes\
```

pdb·`fonts`·`licenses`·`windows`는 넣지 않는다. 글꼴과 라이선스 문구는 exe에 들어 있고(`include_bytes!`·`include_str!`), `windows`는 빌드용이다.

## 5. 걸린 시간

이 PC 측정값이다. 다른 PC(노트북 등)는 사양에 따라 다를 수 있다.

| 빌드 | 시간 |
| --- | --- |
| release 처음부터 | 5분 2초(`package-release.ps1` 전체 5분 23초) |
| debug 처음부터 | 3분 36초 |
| release, 의존성 캐시가 있을 때 | 약 79초(RELEASE 이전 측정, 이 크레이트만 재컴파일) |

- 측정 PC: `specs/v0.5/HERDR-SETUP.md` 2.2의 데스크톱 빌드 환경(Rust 1.99.1, Build Tools 2022, Windows SDK 10.0.26100.0). CPU·메모리 사양은 확인 안 함.
- 위 "처음부터"는 rustflags 변경으로 이 PC에서 다시 빌드한 시간이라 crates·git 의존성은 이미 받아 둔 상태였다. 새 clone의 첫 빌드는 cargo가 crates·git 의존성을 받는 시간이 더해진다.
- 깨끗한 clone에서의 빌드 시간과 fetch 시간은 측정하지 않았다.

## 6. 다른 PC로 옮기기

1. `workbench-gpui.zip`을 풀고 `workbench-gpui\workbench-gpui.exe`를 실행한다.
2. `resources\`는 exe와 같은 폴더에 둔다. 앱은 exe 옆 `resources\`를 먼저 찾고, 없으면 개발 경로(`CARGO_MANIFEST_DIR\resources`)를 쓴다.
3. VC++ 재배포 패키지는 필요 없다(`dumpbin /dependents`에 `VCRUNTIME140`·`MSVCP`·`api-ms-win-crt-*`·`ucrt` 없음, 남은 DLL은 전부 OS 제공).
4. 확인: 실행하면 stderr에 `resources: <경로>` 한 줄이 찍힌다. 그 경로가 exe 옆 `resources`여야 한다.

사용자 설정(`keymap.json`)과 상태(`state.json`)는 `%APPDATA%\workbench-gpui\`에 있다(README "설정 파일"). 배포 폴더에는 들어가지 않는다.

## 7. 알려진 제약

1~6은 RELEASE 보고 "남은 제약"이다.

1. 실제 다른 PC에서는 아직 안 돌려 봤다. 같은 PC의 다른 경로(`%TEMP%`)에서만 확인했다. VC++ 재배포 패키지가 없는 PC에서 뜨는지, 아이콘·테마·문법 강조가 보이는지는 사용자 확인이 필요하다.
2. 콘솔 창이 같이 뜬다. `main.rs`에 `windows_subsystem = "windows"`가 없어 exe를 더블클릭하면 콘솔 창이 함께 열린다(`resources:` 줄이 거기 찍힌다).
3. OS 조건: `icuuc.dll`은 Windows 10 1703 이상의 시스템 DLL이다. 긴 경로 지원은 그 PC의 레지스트리 `LongPathsEnabled`도 1이어야 켜진다. x64 Windows만 대상이다(정적 CRT 설정은 `x86_64-pc-windows-msvc`에만).
4. `resources\` 판단은 폴더 존재만 본다. exe 옆에 빈 `resources\`가 있으면 그 폴더를 쓴다. 개발 경로 문자열은 exe에 남아 있다.
5. 코드 서명이 없다. 다른 PC에서 SmartScreen 경고가 뜰 수 있다(확인 안 함).
6. 재빌드 시간: rustflags가 바뀌면 같은 `target`의 모든 프로필이 한 번씩 전부 다시 빌드된다(debug 3분 36초, release 5분 2초 등). 이후는 다시 증분이다.
7. 깨끗한 clone에서 이 문서대로 빌드해 본 기록이 없다. 0절 순서는 코드 읽기로만 확인했다(W-61).
8. `apply-manifest.ps1`은 PATH의 `mt.exe` 또는 Windows SDK 기본 경로(`C:\Program Files (x86)\Windows Kits\10\bin\<버전>\x64\mt.exe`)가 필요하다. SDK를 다른 위치에 설치했다면 그 `x64` 폴더를 PATH에 넣는다.
9. 디스크 여유: release 빌드의 `target`이 약 4.5 GB다(이 PC 측정, leader 값). debug 빌드까지 하면 더 든다.

## 8. 라이선스 주의

앱 코드는 Zed 앱 코드(GPL-3.0)를 복사하지 않는다(`AGENTS.md` 레포 규칙). 그러나 배포 폴더의 `resources\` 4폴더는 다른 저장소의 파일을 그대로 받은 복사본이다. **이 복사본들은 개인 용도로 두는 것이며 배포물(폴더·zip)에 포함된다.** 배포물을 다른 사람에게 넘기기 전에 각 라이선스를 확인해야 한다.

| 폴더 | 내용 | 함께 받은 라이선스 파일 |
| --- | --- | --- |
| `zed-languages` | Zed 저장소의 쿼리 파일(`crates/grammars/src`, `extensions/html/languages/html`) | Zed 저장소 GPL-3.0 쪽 파일이다. 폴더에 Zed `LICENSE-GPL`·`LICENSE-APACHE`. `extensions/html` 쿼리에 따로 적용되는 라이선스는 확인 안 함 |
| `zed-languages`(toml, git*) | Zed TOML 확장 1.1.0, Git Firefly 확장 0.1.9의 쿼리 | Apache-2.0(앱 라이선스 목록, `resources/licenses/zed-extension-toml/LICENSE`·`git-firefly/LICENSE`) |
| `zed-icons` | Zed 아이콘 svg | `LICENSES`(Lucide, ISC License), `LICENSE-APACHE`, `LICENSE-GPL` |
| `zed-themes\zed` | Zed 기본 테마 | `LICENSE-APACHE`, `LICENSE-GPL` |
| `zed-themes\catppuccin`, `zed-themes\macos-classic` | Catppuccin, macOS Classic 테마 | 각 폴더 `LICENSE`(MIT License) |
| `zed-icon-themes\catppuccin-icons` | Catppuccin Icons | `LICENSE`(MIT License) |
| `zed-icon-themes\zed` | Zed 연결 표(데이터)로 만든 `zed.json` | 폴더에 라이선스 파일 없음. 원본은 Zed `crates/theme/src/icon_theme.rs` |

exe에 들어 있는 의존성·글꼴 라이선스 문구는 앱 메뉴의 라이선스 목록(`src/ui/app_menu.rs` `LICENSES`)에서 볼 수 있다.

## 9. GitHub에 올리지 않는 것

빌드 산출물(exe·zip·설치 파일·pdb, `target/`·`dist/`·`bundle/`)은 커밋하지 않는다.

- 확인 결과(2026-11-08, leader): `git ls-files`에 산출물 없음(`\.(exe|zip|msi|pdb|dll|7z)$`, `target/`·`dist/`·`bundle/` 경로 0건).
- `.gitignore`는 원래 산출물 중 `target/`만 막았다. W-60에서 `dist/`, `bundle/`, `*.exe`, `*.zip`, `*.msi`, `*.pdb`를 더했다.
- `resources\` 4폴더도 `.gitignore` 대상이다(2절).

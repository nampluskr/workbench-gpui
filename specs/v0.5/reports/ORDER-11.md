[DONE] ORDER-11 gpui        (큰 파일 입력 지연은 측정 못 함 — 아래 "측정 못 함")

## 완료 기준
| 항목 | 판정 방법 요약 | 결과 | 측정값·근거 |
|---|---|---|---|
| 1 언어 목록·형식별 결과 표 | 이름·확장자·문법 출처·버전 표, 형식별 결과 표, 두 갈래 같음 | 충족 | 아래 두 표. 언어 목록은 tauri가 먼저 쓴 SPEC R-15를 옮김(W-48·W-53·W-54) — 29행, TOML·HTML 행은 tauri와 글자까지 같음. 확장자 전체·쿼리·라이선스는 SPEC R-15 표 |
| 2 I-15 구문 강조 | 언어마다 샘플 강조, 마크다운·HTML은 One Dark Zed 캡처와 색 같음 | 충족 | Zed 캡처가 있는 14개 형식 모두 Zed와 같은 색(아래 표). 마크다운 인라인(굵게·기울임·링크·URL·인라인 코드)·코드 펜스 주입, HTML `<style>`·`style=""`의 CSS, `<script>`·`onclick`의 JS 주입이 Zed와 같음. 큰 파일: 증분 파싱(편집은 `Tree::edit` 뒤 재파싱, 일괄 편집은 한 번), UI 스레드 파싱 — 지연은 측정 못 함 |
| 3 I-12 코드 파일 심볼 | 같은 파일·커서에서 경로 줄 글자가 Zed와 같음(2개 이상) | 충족 | 3개: `sample.rs` 21행 `impl Counter › pub fn bump › fn clamp`, `sample.py` 21행 `class Library › def add › def normalize`, `sample.ts` 18행 `class Inventory › add( ) › function normalize( )` — 단어마다 색·x 위치가 Zed 캡처와 같음(오프셋 +240 일정, 2차 `measure-ORDER-11-run2-step5/*-toolbar.png`). 심볼 밖은 경로만(V1). Zed outline 쿼리 사용, 고르기·글자 규칙은 Zed `buffer.rs` 값·규칙만 |
| 3a 미리보기 코드 블록(3.3) | Zed 미리보기처럼 강조 | 충족 | 언어별 강조(편집기와 같은 색·주입). 테두리 1px `border_variant` #363c46, 배경 editor background #282c33, 블록 높이 130/78/104, 연속 블록 사이 16 — Zed `zed-md-preview.png`와 같음(3차). 2차에서 배경 #2f343e·사이 48이라 K-46-R1로 고침 |
| 4 복사본·스크립트·D-8 | 쿼리 복사본 미커밋, 다시 채우는 스크립트, 실행 중 Zed 폴더 안 읽음 | 충족 | 복사본 `resources/zed-languages/`(.gitignore, `git ls-files "*.scm"` 0건 — C-43), `tools/fetch-zed-languages.ps1`(Zed 4304dec + TOML 확장 v1.1.0 8e18e50 + git-firefly 0.1.9 c63c6c0). 언어 표는 `src/ui/syntax.rs` 정적 표, 실행 중 config.toml·Zed 설치 폴더 안 읽음. 복사본 없으면 평문(V1) |
| 5 앞 Phase | 결과 유지 | 충족 | 전체 `cargo test` 315 passed / 0 failed, clippy 0(C-43 PASS) |

## 언어 목록 (SPEC R-15 요약)
| 언어 | 문법 | 버전/rev |
|---|---|---|
| Shell Script | tree-sitter-bash | 0.25.1 |
| C | tree-sitter-c | 0.24.1 |
| C++ | tree-sitter-cpp (git tree-sitter/tree-sitter-cpp) | 0.23.4, rev 5cb9b693 |
| CSS | tree-sitter-css | 0.23.2 |
| Diff | tree-sitter-diff | 0.1.0 |
| Env | tree-sitter-bash | 0.25.1 |
| Git Commit | tree-sitter-gitcommit (git zed-industries) | rev 88309716 |
| Go | tree-sitter-go (git zed-industries) | 0.25.0, rev 6862a49e |
| Go Mod | tree-sitter-gomod (git camdencheek) | 1.1.1, rev 2e886870 |
| Go Work | tree-sitter-gowork (git zed-industries) | rev acb0617b |
| JavaScript | tree-sitter-typescript TSX 문법 | TypeScript 행과 같음 |
| JSDoc | tree-sitter-jsdoc | 0.23.2 |
| JSON / JSONC | tree-sitter-json | 0.24.8 |
| Markdown / Markdown-Inline | tree-sitter-md (git zed-industries) | 0.3.2, rev b596e737 |
| Python | tree-sitter-python | 0.25.0 |
| Regex | tree-sitter-regex | 0.24.3 |
| Rust / Zed Keybind Context | tree-sitter-rust | 0.24.2 |
| TypeScript / TSX | tree-sitter-typescript (git zed-industries) | 0.23.2, rev e2c53597 |
| YAML | tree-sitter-yaml (git zed-industries) | 0.6.1, rev baff0b51 |
| HTML (Zed 레포 확장) | tree-sitter-html | bfa075d8 |
| TOML (확장 v1.1.0) | tree-sitter-toml | 342d9be2 |
| Git Attributes·Config·Ignore·Rebase (git-firefly 0.1.9) | tree-sitter-gitattributes·git-config·gitignore·git-rebase | 1b7af09d·3a61756a·f4685bf1·39bf3b75 |
tree-sitter core 0.28(git 803c6eb), 모두 Zed `Cargo.lock`·확장 고정 커밋과 같은 저장소·버전. gpui-component의 tree-sitter 기능은 끄고 앱이 파싱해 기존 `InputHighlighter`에 넘긴다(vendor/gpui-base 변경 없음).

**vendor한 문법(core 결정 option A, tree-sitter 0.28과 맞는 crate 없음)**: html(bfa075d), toml(342d9be), git-config(3a61756), gitignore(f4685bf) — `vendor/tree-sitter-*/`에 MIT parser.c·scanner.c·헤더·LICENSE·`SOURCE.md`(저장소·커밋·SHA256, 19파일 일치 — C-43), `build.rs`로 컴파일, `.gitattributes` `-text`로 바이트 유지. gitattributes·git-rebase는 0.28 호환 git rev crate.

## 형식별 결과 (V3, One Dark, 대조 tauri의 Zed 캡처 `workbench-tauri\specs\v0.5\verify\ORDER-11\zed-*.png`)
| 형식 | 샘플 | 결과 | 캡처 |
|---|---|---|---|
| Rust | sample.rs | Zed와 같음 | run2-step1 |
| JSON | sample.json | Zed와 같음 | run2-step1 |
| Markdown | sample.md | Zed와 같음(인라인·펜스 주입 포함) | run2-step1 |
| C / C++ | sample.c / .cpp | Zed와 같음 | run2-step2 |
| CSS | sample.css | Zed와 같음 | run2-step2 |
| HTML | sample.html | Zed와 같음(CSS·JS 주입, 줄바꿈 없음 = Zed 기본) | run2-step2 |
| Shell Script | sample.sh | Zed와 같음 | run4-step3 |
| Go | sample.go | Zed와 같음 | run4-step3 |
| Python | sample.py | Zed와 같음 | run4-step4 |
| JavaScript | sample.js | Zed와 같음(JSDoc 주입 포함) | run4-step4 |
| TypeScript / TSX | sample.ts / .tsx | Zed와 같음 | run4-step4 |
| YAML | sample.yaml | Zed와 같음 | run4-step4 |
| Diff, Go Mod, Go Work, Env, Git Commit | sample.diff, go.mod, go.work, .env, COMMIT_EDITMSG | 강조됨, Zed 캡처 없음(비교 못 함) | run4-step3 |
| JSONC, TOML, Git 4종 | — | V1(샘플 run 테스트)만, 화면 샘플 없음 | — |
- 판정: 앱 편집기 캡처와 Zed 캡처를 같은 영역으로 잘라 나란히 비교(leader), 토큰 표본. 픽셀 일치 비교는 안티앨리어싱 가장자리 때문에 쓰지 않음. 비교에서 보인 차이는 문법 색이 아님: Zed의 들여쓰기 안내선이 더 진함, Zed 줄 1의 인라인 blame·⚡ 코드 액션 표시, CSS 색 견본(언어 서버 기능).
- 함께 맞춘 것(1차 V3 뒤 K-47·K-47-R1): 캡처 없는 글자색 `editor.foreground` #acb2be(전에 #dce0e5), 탭 폭 4, 언어별 soft wrap(Zed 기본 — 마크다운·Git Commit·평문만 줄바꿈). soft wrap은 vendor를 고치지 않고 앱이 기억값으로 렌더 때 `set_soft_wrap`(core 결정).

## 두 갈래가 다른 점
- 쿼리 복사본 범위: gpui는 쓰는 쿼리(highlights·injections·outline)만 복사, tauri는 확장의 전체 쿼리 목록. SPEC 표의 쿼리 열은 tauri 원문 그대로이고 값 차이는 아님(W-54).

## 바꾼 파일 (커밋 72a09ea)
- 새: `src/ui/syntax.rs`, `build.rs`, `vendor/tree-sitter-{html,toml,git-config,gitignore}/`, `resources/licenses/tree-sitter*`·확장 라이선스, `tools/fetch-zed-languages.ps1`, `tools/measure/order11-v3.ps1`, `.gitattributes` 한 줄.
- 고침: `Cargo.toml`·`Cargo.lock`(문법 crate — K-48의 두 줄은 coder 세션 권한 검사가 막아 leader가 넣음), `src/ui/{breadcrumb,pane_view,pane_group,pane,panel_ops,watch,markdown_preview,theme,app_menu,layout,mod}.rs`, `spec/*`, `specs/v0.5/{SPEC,PROGRESS,HERDR-SETUP}.md`.

## 검토·측정
- checker: C-41(Zed 미리보기 소스), C-42(측정 스크립트), C-43(리뷰 PASS·전체 테스트·규칙 점검). 측정 결과는 위 표(측정표 별도 파일 없이 이 보고와 PROGRESS에).
- V3 1~4차, 단계별 세션, 모두 띄운 PID만 닫고 앱 데이터 바이트 동일 복원, 남은 앱 없음, 사용자 Zed(18016·20788)·settings.json 불변, 입력 가드. Zed는 띄우지 않고 tauri Zed 캡처로 대조. 시작·끝은 core 알림만.
- 2~4차 전체 캡처에 다른 앱의 오버레이 창(성능 위젯)이 찍혀 그 캡처는 커밋하지 않음(.gitignore). 판정에 쓴 영역(편집기 왼쪽, 경로 줄 잘라낸 캡처)은 가려지지 않음.
- 진행 중 D: 여유 266 MB로 링크 실패 → 이 레포 `target\debug\incremental`(재생성 캐시)을 지워 해결.

## 측정 못 함
- 큰 파일 첫 열기·입력 지연(Zed 대비). 파싱은 UI 스레드(`shortcut:` 주석), 편집은 증분.
- 마크다운 경로 줄을 outline으로 통일하는 일: Zed outline은 섹션 단위라 "제목 줄 첫 글자" 경계에서 앞 섹션 제목이 나올 수 있음(코드 읽기 추정) — 이 레포는 Phase 9 줄 스캔을 유지(결과 `# AGENTS › ## 레포 규칙` 그대로).

## 범위 밖에서 찾은 차이(미리보기)
- 중첩 번호 목록 표시 `A.`/`B.`(Zed `1.`/`2.`), 제목 아래 구분선·본문 폭 가운데 정렬 없음, 코드 블록 다음 제목 위 간격이 Zed보다 약 3px 작음.

## 사용자 확인 필요(Phase 12)
- 언어별 색 품질 인상(V4), 미리보기 코드 블록 인상.
- 코드 파일을 연 첫 프레임에 줄바꿈이 한 번 켜졌다 꺼지는지(렌더 때 적용, 한 프레임 늦음).

## BLOCKED
없음

## ORDER-11-R1 (core 마무리 2건, 2026-11-08)
### (1) 큰 파일 입력 지연 (V1, 화면 없음, K-49)
- 조건: i7-8700K, Windows 11, `--release`, 앱의 `SyntaxHighlighter`(편집기가 부르는 `edit`·`reparse`·`runs` 그대로)를 `#[ignore]` 측정 테스트에서 호출. 파일은 tauri와 같은 것: TS `lib.webworker.d.ts`·`lib.dom.d.ts`(tauri `node_modules`의 typescript, 줄 수는 `wc -l` 기준으로 tauri 표보다 1 작음 — 마지막 줄바꿈), Rust `ash 0.38.0` `native.rs`·`definitions.rs`(cargo 레지스트리), 합성 마크다운(코드 블록 330개, 8개 언어 돌아가며)·HTML(style·script 600개). 생성 규칙은 tauri와 같은 모양이지만 같은 바이트는 아님(`cards/K-49.report.md` 1절). 중간 줄 근처에 한 글자 → 증분 파싱 + 주입 층 갱신 + 보이는 40줄 강조, 10회 중앙/최대. 측정 파일은 레포에 넣지 않음(환경 변수 경로).
- 수정 전: TypeScript만 한 글자에 0.2~1.5초 입력이 멈췄다(첫 파싱 5.8~37.7초). 원인은 주입 쿼리를 루트(`program`)에 돌린 것 — "앞 주석 + 뒤 문자열" 꼴 패턴 6개(html·sql·graphql 등)가 주석마다 최상위 형제 수천 개를 훑었다. 바뀐 범위만 질의하고 안 바뀐 층을 재사용하는 것(Zed `changed_ranges` 방식)은 K-44부터 이미 있었다.
- 고침: 주입 질의를 바뀐 범위에 닿는 **최상위 노드마다** 돈다(형제 탐색이 한 노드 안에 갇힘). 루트나 최상위 형제 둘에 걸친 주입 패턴은 24개 언어 `injections.scm`에 없음(coder 확인, C-44 재확인).

| 파일 | 줄 | 편집 합계 중앙/최대(ms) 전 → 후 | 한 번에 막은 최장(ms) 전 → 후 | 첫 파싱(ms) 전 → 후 |
| --- | ---: | --- | --- | --- |
| TypeScript `lib.webworker.d.ts` | 15,606 | 189.2 / 195.6 → 3.4 / 3.8 | 195.3 → 3.6 | 5,759 → 416 |
| TypeScript `lib.dom.d.ts` | 45,125 | 726.7 / 1,450.8 → 7.3 / 8.7 | 1,450.1 → 8.3 | 37,711 → 1,395 |
| Rust ash `native.rs` | 12,478 | 3.3 / 4.3 → 4.1 / 4.6 | 3.7 → 4.2 | 296 → 306 |
| Rust ash `definitions.rs` | 57,432 | 24.4 / 29.9 → 25.2 / 26.2 | 29.6 → 25.8 | 385 → 386 |
| Markdown(코드 블록 330, 합성) | 10,004 | 19.8 / 61.9 → 19.9 / 61.7 | 61.5 → 61.3 | 223 → 224 |
| HTML(style·script 600, 합성) | 10,015 | 6.1 / 7.1 → 6.4 / 7.9 | 6.7 → 7.6 | 156 → 109 |

- 강조 결과 전/후 같음: 샘플 18개·합성 2개·큰 파일 2개의 전체 강조 해시 같음, 큰 파일 4종·합성 2종에서 모든 편집의 보이는 40줄 색이 같은 텍스트의 전체 파싱과 같음(불일치 0).
- background executor로 옮기지 않음: 고친 뒤 입력을 막는 최장이 TS 3.6~8.3ms, HTML 7.6ms, Rust 1.25만 줄 4.2ms로 한 프레임 안, ash 5.7만 줄 25.8ms. 남은 큰 값은 루트 문법의 증분 파싱 자체 — 합성 마크다운은 파일을 연 뒤 **첫 편집 한 번만 61ms**(이후 중앙 19.9ms, tree-sitter-md 블록 파서), ash 5.7만 줄 루트 파싱 약 25ms. 첫 파싱도 UI 스레드(TS 4.5만 줄 1.4초). tauri(최장 26ms 이하, 시간 쪼개기)와 비교해 마크다운 첫 편집만 크다. Zed식 1ms 동기 + background 이동을 할지는 core 결정으로 V4-LIST "백그라운드 파싱" 행에 둠.
- tauri와 측정 방법 차이: gpui는 단일 호출(`edit`+`reparse` 또는 `runs`)을 "막은 시간"으로 잼(양보 없음), tauri는 8ms 양보 조각 중 최장.
- 확인: 전체 `cargo test` 316 passed / 0 failed (2 ignored = 측정), clippy 0, vendor/gpui-base 변경 없음(C-44 PASS).

### (2) Phase 12 V4 목록
- `specs/v0.5/reports/V4-LIST.md` — tauri 형식(Phase·항목·종류·내용·근거·상태), ORDER-01~11 보고·PROGRESS에서 38행. 상태는 보고·커밋으로 확인되는 것만, 없으면 "기록 없음".

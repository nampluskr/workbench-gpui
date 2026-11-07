> 버전: v0.5 · 작성일: 2026-11-06 · 상태: 확정 (core-leader 판정, 사용자 위임 2026-11-06)
>
> workbench-gpui가 v0.5에서 정한 결정을 기록한다. 두 갈래 공통 결정은 workbench-core `specs/v0.5/DECISIONS.md`의 D-1~D-11에 있고, 여기서는 다시 쓰지 않고 `core D-n`으로 가리킨다. 목적은 `INTENT.md`에, 요구는 `SPEC.md`에 있다.

# DECISIONS — workbench-gpui v0.5

## 적용하는 core 결정

이 레포는 아래 core 결정을 그대로 따른다(`D:\projects\workbench-core\specs\v0.5\DECISIONS.md`).

| core 결정 | 이 레포에서 적용하는 곳 |
|---|---|
| D-1 화면을 다루는 확인은 한 번에 하나씩 | `HERDR-SETUP.md` 5.4, `AGENTS.md` 3A |
| D-2 leader·writer·coder·checker 구성 | `HERDR-SETUP.md` 1·2장, `AGENTS.md` 6·7장 |
| D-3 공통 지시 카드와 파일 보고 | `HERDR-SETUP.md` 5장, `PLAN.md` |
| D-4 SCREEN-REQ·SCREEN-OK·SCREEN-DONE | `HERDR-SETUP.md` 5.4 |
| D-5 ITEMS.md | `SPEC.md` |
| D-6 core에는 core-leader 하나 | 없음(이 레포에 적용할 것 없음) |
| D-7 자기 워크스페이스만 쓴다 | `AGENTS.md` 레포 규칙 |
| D-8 Zed 테마·아이콘 테마 복사 | 이 문서 D-11, `SPEC.md` R-3·R-4, `PLAN.md` Phase 7 |
| D-9 Zed UI 아이콘 복사 | 이 문서 D-6·D-7, `SPEC.md` R-1·R-18, `PLAN.md` Phase 5 |
| D-10 IBM Plex Sans·Lilex 커밋 | `SPEC.md` R-14, `PLAN.md` Phase 3 |
| D-11 ITEMS가 SPEC 역할 | `SPEC.md` 판정 방법 |
| D-12 core ITEMS가 갈래 지침보다 우선 | 루트 `INTENT.md`·`AGENTS.md`의 예외 표시, `AGENTS.md` 레포 규칙 "core ITEMS 우선", `SPEC.md` R-2·R-22, `PLAN.md` Phase 8 |
| D-14 gpui-base 0.8.1 vendor로 줄 번호 열을 Zed와 같게 | 이 문서 D-4·D-5, `SPEC.md` R-13·R-14, `vendor/gpui-base/PATCHES.md` |
| D-15 "v" 메뉴 화면은 Zed의 틀에 이 앱의 실제 내용만 | 이 문서 D-8·D-9, `SPEC.md` R-2 "2단계", `PLAN.md` Phase 6 |
| D-17 상태 바 검색은 실제 Project Search, 진단은 언어 서버 없이 "문제 없음" 화면(ORDER-08 범위) | `SPEC.md` R-22, `PLAN.md` Phase 8 |

---

## D-1. 서브 에이전트 카드는 `specs/v0.5/cards/<ID>.md`에, 보고는 `<ID>.report.md`에 둔다

**선택**

- leader가 서브 에이전트에게 주는 카드는 `specs/v0.5/cards/<ID>.md` 파일로 쓴다. herdr 프롬프트로는 카드 경로만 보낸다.
- 받는 에이전트는 결과를 `specs/v0.5/cards/<ID>.report.md`에 쓰고, 답으로는 그 경로만 말한다.
- W-01 카드부터 적용한다.

**근거**

- leader 확인 사실(2026-11-06, W-01 "확정 사실").
- 카드를 파일로 둘지와 어느 폴더에 둘지는 갈래가 정해 HERDR-SETUP에 적는다(ORDER-01 3.3).
- 카드 하나만 읽고 일할 수 있게 쓰고 보고는 파일 경로로 받는다(core D-3).

**배제한 대안**

- **v0.4처럼 `specs/v0.4/agents/TASKS.md` 작업 보드 하나에 카드를 모은다** — core D-3은 카드 하나만 읽고 일하게 하고, 서브 에이전트 컨텍스트를 Phase마다 비우므로 파일이 따로 있는 편이 낫다. leader가 카드 파일 방식을 정했다(2026-11-06).

---

## D-2. v0.4 worktree(`.worktrees\editor`, `.worktrees\ui`)는 v0.5에서 쓰지 않고 지운다

**선택**

- v0.5는 main checkout(`D:\projects\workbench-gpui`, 브랜치 `master`) 하나에서 작업한다.
- v0.4 worktree `.worktrees\editor`·`.worktrees\ui`와 로컬 브랜치 `work/editor`·`work/ui`는 지운다. 2026-11-06 leader가 master에 병합된 것을 확인한 뒤 지웠다. 원격 브랜치는 건드리지 않는다.

**근거**

- worktree는 두지 않는다. coder가 하나라 같은 checkout에서 겹치지 않는다(core D-2).
- v0.4에서 쓰던 worktree가 남아 있으면 지우지 말고 보고한다. 지울지는 사람이 정한다(ORDER-01 3.2).
- 사용자가 지우기로 했다("미정 네 가지 제안대로 진행해 주세요", 2026-11-06, ORDER-01-R2 C). leader가 지운 사실(2026-11-06, W-03). writer 확인: `git worktree list`에 본 트리 하나만 있고 `git branch`에 `work/editor`·`work/ui`가 없다(2026-11-06).

**배제한 대안**

- **v0.4처럼 coder를 worktree에서 일하게 한다** — core D-2가 worktree를 두지 않기로 했다.
- **worktree를 남겨 둔다** — 사용자가 지우기로 했다(ORDER-01-R2 C).

---

## D-3. `spec/`은 writer가 leader 카드로만 고치고, Zed 값 확인은 checker가 한다

**선택**

- `spec/zed-metrics.toml`·`spec/INDEX.md`·`spec/ambiguous.md`는 `writer`가 leader 카드로만 고친다.
- Zed 값 확인(원문 실측 문서 대조, Zed 화면 측정)은 `checker`가 하고 결과를 보고 파일로 넘긴다. `writer`가 그 보고를 `spec/`에 기록한다.
- `coder`는 `spec/`을 읽기만 한다.
- 스펙 항목 ID는 한번 정하면 바꾸지 않는다(v0.4 `AGENTS.md` 7.3에서 이어짐).
- v0.5에서는 각 I-n의 구현 카드가 그 I-n이 다루는 화면·값만 스펙 값으로 맞춘다. 카드 범위 밖에서 찾은 불일치는 고치지 않고 완료 보고에 적고, `writer`가 PROGRESS의 스펙 불일치 목록에 모은다. 모은 것은 Phase 12 사용자 일괄 확인 때 core-leader에게 올린다.
- workbench-tauri가 스펙 ID가 필요하면 core-leader를 거쳐 gpui-leader 카드로 요청한다. tauri는 이 레포 `spec/`에 쓰지 않는다(core D-7).

**근거**

- gpui-leader 안(`specs/v0.5/reports/ORDER-01-R2.md` "D. spec/ 소유 안")을 core-leader가 승인했다(core-leader 사용자 위임 2026-11-06, core D-13, ORDER-01-R2 D).
- core D-2에서 v0.4 `spec`(agy) 역할이 없어졌다. 문서 담당이 writer, 측정 담당이 checker다.
- 지난 커밋에 workbench-tauri용 스펙 ID를 이 레포 `spec/`에 더한 것이 있다(4badee1, 39350b7, 8eb170e). core D-7 이후로는 tauri가 이 레포에 쓰지 않는다.

**배제한 대안**

- **v0.4처럼 `spec` 역할을 따로 둔다** — core D-2가 v0.4 구성을 잇지 않고 서브 에이전트를 writer·coder·checker 셋으로 줄였다.

---

## D-4. gpui-base 0.8.1을 `vendor/gpui-base/`에 두고 줄 번호 열만 고친다

**선택**

- gpui-base 0.8.1을 `vendor/gpui-base/`에 복사하고 `Cargo.toml` `[patch.crates-io]`에 `gpui-base = { path = "vendor/gpui-base" }`를 둔다. 버전은 0.8.1 그대로다. 원본 `LICENSE-APACHE`(Apache-2.0)를 함께 둔다.
- 고친 곳은 줄 번호 열뿐이다: 최소 자릿수 3 → 4, 번호 좌우 여백(왼쪽 22px + 자릿수 × 숫자 폭 + 오른쪽 29px, 본문은 +5px), 일반·현재 줄 번호 색을 따로 받는 `EditorGutterTheme`. 바꾼 파일은 `src/input/base/element.rs`·`src/theme.rs`·`src/lib.rs` 셋이다.
- 원본과의 차이와 이유는 `vendor/gpui-base/PATCHES.md`에 적는다.

**근거**

- core D-14(core-leader 사용자 위임 2026-11-07, D-13)를 이 레포에 적용했다(K-07).
- gpui-component·gpui-base 0.8.1에는 줄 번호 최소 자릿수·여백을 바꿀 공개 옵션이 없다(K-06 조사). 줄 번호 전용 색도 없다(K-04 조사).
- C-14 리뷰: 원본 218개 파일과 해시 대조해 PATCHES.md에 적은 3개 외에는 같다. Cargo 변경은 patch 한 줄과 lock의 gpui-base source·checksum 두 줄뿐이다.

**배제한 대안**

- core D-14의 배제 대안을 따른다: (A) 지금 폭 유지, (C) 바깥 padding으로 근사, gpui-component 전체 fork.

---

## D-5. I-13 줄 번호 색은 Zed One Light 값으로 한다 (앞의 (A) 결정을 대체)

**선택**

- 현재 줄 번호 `#44454b`(T-05.08), 나머지 줄 번호 `#b4b4bb`(T-05.07). 지금 앱 테마(gpui-component Default Light)에 맞춰 One Light 값을 쓴다. 값은 `src/ui/theme.rs`가 `EditorGutterTheme`으로 넣는다(D-4).
- 앞서 core-leader DECISION(2026-11-07)의 "(A) 줄 번호 색은 현재 동작 유지(`foreground`/`muted_foreground`)"는 이 결정으로 대체됐다.

**근거**

- core D-14가 "(A) 유지"를 뒤집고 vendor로 줄 번호 색도 함께 맞추기로 했다.
- C-15 V3: 현재 줄 번호 `#44454b`, 일반 줄 번호 `#b4b4bb`를 픽셀로 확인(PASS, `verify/reviews/measure-ORDER-03.md`).

**배제한 대안**

- **(A) 현재 동작 유지, 차이를 Phase 12 V4로** — core D-14로 대체됐다.

---

## D-6. Zed UI 아이콘 복사본은 고정 커밋에서 `resources/zed-icons/`로 받고 커밋하지 않는다

**선택**

- 출처: `zed-industries/zed` 커밋 `4304dec732a75505066de5ce2dbbfb2bec369498`의 `assets/icons` 전체(UI SVG 299개, `file_icons/` 96개, `knockouts/` 6개, `LICENSES`)와 저장소 `LICENSE-APACHE`·`LICENSE-GPL`. 모두 404개 파일이다.
- 두는 곳: `resources/zed-icons/`. `.gitignore`에 넣고 커밋하지 않는다.
- 다시 채우기: 저장소 루트에서 `pwsh -NoProfile -File tools/fetch-zed-icons.ps1`. git과 네트워크가 필요하다. 같은 커밋만 받고 다른 커밋으로 대신하지 않는다(커밋·파일 수가 다르면 실패한다).
- 복사본이 없을 때: 앱은 죽지 않는다. 아이콘 자리는 같은 크기의 빈 칸으로 그리고, 시작할 때 stderr에 `zed icons missing: run tools/fetch-zed-icons.ps1`를 한 번 낸다.
- 앱 자리에 쓸 Zed 아이콘 이름은 같은 커밋의 Zed crates 소스에서 이름만 대조한다. 소스는 레포 밖 `%TEMP%`에만 받고 코드는 복사하지 않는다.
- 남은 비-Zed 출처: 파일 트리 파일 아이콘 `IconName::File`(gpui-kit). Phase 7(아이콘 테마)에서 다룬다.

**근거**

- core D-9(Zed UI 아이콘 복사)를 이 레포에 적용했다. 폴더·출처 커밋·없을 때 모습·다시 채우기는 leader가 정했다(K-08).
- K-08 보고: 전체 커밋 해시 확인, 404개 파일, `git ls-files resources/zed-icons` 0행. C-19 리뷰 PASS(파일 수·라이선스 3파일·추적 제외 확인).
- Zed crates 소스를 레포에 받으려던 것을 leader가 막고 `%TEMP%`로 옮기게 했다(K-08 작업 중, K-08 보고 "출처와 복원").
- 복사본 없음: `missing_zed_icons_are_empty_without_panic` 테스트, ORDER-05 V3 `MissingIcons` 단계(경고 있음, 빈 칸, 앱 안 죽음).

**배제한 대안**

- **이 PC의 Zed 설치 폴더에서 읽는다** — 버전이 고정되지 않는다. K-08 카드가 금지했다.
- **복사본을 커밋한다** — core D-9가 `.gitignore` 폴더에 두기로 했다.

---

## D-7. 창 제어 버튼 4개는 Zed Windows처럼 Segoe Fluent Icons 글리프로 그린다 (R-1 SVG 기준의 예외)

**선택**

- 최소화 U+E921, 최대화 U+E922, 복원 U+E923, 닫기 U+E8BB. 글꼴은 `Segoe Fluent Icons`, 없으면 `Segoe MDL2 Assets`.
- R-1의 "아이콘은 Zed 원본 SVG로" 기준에서 이 4자리만 뺀다. Linux용 `generic_*.svg`는 쓰지 않는다.

**근거**

- core-leader 결정(창 버튼 Segoe Fluent 글리프 예외, 2026-11-07, D-13).
- Zed도 Windows에서는 창 제어 버튼을 이 글리프로 그린다: 같은 커밋 `crates/platform_title_bar/src/platforms/platform_windows.rs` 16~39·80~83행(leader 확인, K-08-R1). C-19가 같은 행으로 대조했다.
- K-08-R1로 K-08 전 구현(`src/ui/title_bar.rs`)으로 되돌렸다.

**배제한 대안**

- **K-08처럼 `generic_minimize.svg` 등 SVG로 그린다** — Linux용이라 Windows Zed와 모양이 다르다.

---

## D-8. Settings는 `%APPDATA%\workbench-gpui\settings.json`의 키 4개를 Appearance 범주 행 4개로 보이고, 기본값은 지금 상수다

**선택**

- 파일: `%APPDATA%\workbench-gpui\settings.json`. 형식은 Zed settings.json(JSONC 허용), 키 이름은 Zed와 같다.
- 키 4개: `theme`, `icon_theme`, `ui_font_size`, `buffer_font_size`. 파일이나 키가 없으면 지금 앱 상수가 기본값이다(UI 16, 버퍼 15).
- 범주는 `Appearance` 하나, 행은 위 키마다 하나씩 4개다. 행 이름·설명은 Zed Settings UI 문구 그대로 쓴다.
- 값을 바꾸면 바로 저장하고 바로 적용한다.
- Settings 창 치수는 tauri가 Zed 캡처에서 재서 tauri SPEC에 적은 값을 읽어 쓴다(`SPEC.md` R-2).
- Panel Layout `Classic`은 왼쪽 dock 열기와 dock 기본 폭 복원만 한다. 기본 폭은 두 갈래가 보고하고, 다르면 core가 정한다.

**근거**

- core D-15, core ORDER-06-R1 2.1·2.4.
- core-leader 결정(Settings 공통안, 2026-11-07, 사용자 위임 core D-13). tauri 질문에 대한 답이며 두 갈래 공통이다(core `PROGRESS.md` 2026-11-07).
- 이 앱이 지금 읽는 설정이 이 넷이다(ORDER-06-R1 2.1 "이 앱이 지금 읽는 설정 전부").
- 구현과 Zed 문구 출처: `cards/K-11.report.md`(K-11-R1).

**배제한 대안**

- **Settings 창 치수를 재려고 Zed를 다시 연다** — Zed `Ctrl-,`가 사용자 Zed 프로세스 안에 창을 연다(ORDER-06 V3, `reports/ORDER-06-zed.md`). core-leader가 배제했다.
- **Zed 범주 15개를 다 둔다** — 앱에 없는 설정이 들어간다. core D-15에 어긋난다.

---

## D-9. 메뉴 차이 다섯 가지를 두 갈래 같게 정한다

**선택**

1. 키가 묶인 메뉴 항목은 메뉴에 그 키를 보인다. File → Close Editor는 `Ctrl-W`를 보인다.
2. 편집 단축키는 Zed `assets/keymaps/default-windows.json`(커밋 `4304dec732a75505066de5ce2dbbfb2bec369498`)의 키를 그대로 쓴다. 키가 여럿이면 메뉴에는 첫 키를 보인다. Redo 차이(gpui `Ctrl-Y`, tauri `Ctrl-Shift-Z`)가 여기서 풀린다.
3. 메뉴 막대 이름 간격은 글자 잉크 사이로 잰다. Zed 13~14px과 1px 이내로 맞춘다.
4. "v" 버튼 치수는 tauri가 Zed 캡처로 재서 tauri SPEC에 적은 값을 gpui가 읽어 쓴다(`SPEC.md` R-2).
5. Help → View Dependency Licenses는 앱에 들어간 자원 전부의 라이선스를 보인다.

**근거**

- core-leader 결정(두 갈래 메뉴 차이, 2026-11-07, 사용자 위임 core D-13, core `PROGRESS.md` 2026-11-07).
- 차이 목록: `reports/ORDER-06.md` "두 갈래 메뉴 표 차이", `cards/W-21.report.md`.
- 메뉴 이름 간격: gpui는 1단계에서 막대 gap 4px(I-321)만 쟀고, tauri는 잉크 간격 12~13px을 쟀다(tauri `reports/ORDER-06.md`).
- 구현 카드: `cards/K-12.md`(1·2·3). "v" 버튼 치수(4)와 Licenses(5)의 구현 카드는 아직 없다.

**배제한 대안**

- **Close Editor 키를 메뉴에 보이지 않는다(1단계 tauri)** — 결정 1로 배제.
- **Redo를 gpui-kit input 키맵의 `Ctrl-Y` 또는 tauri의 `Ctrl-Shift-Z`로 둔다** — 두 갈래가 달라진다. 결정 2로 Zed 키맵을 따른다.
- **메뉴 이름 간격을 막대 gap 4px로만 판정한다** — 결정 3으로 배제.

---

## D-10. 측정 중 새로 생긴 창도 내가 연 것만 닫는다

**선택**

- 측정 스크립트는 자기가 띄운 PID와, 자기가 연 것이 확인된 창(HWND)만 닫는다.
- "이번 실행에서 새로 생긴 창"이라도 내가 연 것이 아니면 닫지 않는다. 캡처만 하고, 닫을 창은 화면을 보고 하나씩 정한다.
- 사용자 Zed 프로세스 안에 생긴 창은 닫지 않고 사람에게 알린다.

**근거**

- core ORDER-06-R1 4장 "새로 생긴 창도 내가 연 것만 닫기".
- tauri 스크립트가 새로 생긴 Zed 창을 모두 닫게 되어 있어 사용자 Zed 알림 팝업 하나를 닫았다(tauri `reports/ORDER-06-zed.md` 특이사항).
- gpui V3에서 Zed `Ctrl-,`가 사용자 Zed 프로세스 안에 Settings 창을 열었다. leader가 닫으려 했으나 자동 모드가 거부했다(`PROGRESS.md` Phase 6). C-22가 스크립트를 고쳐 새로 생긴 Zed 창(HWND)만 닫게 했다.

**배제한 대안**

- **이번 실행에서 새로 생긴 Zed 창을 모두 닫는다** — 사용자 창을 닫을 수 있다. 위 tauri 사례로 배제.

---

## D-11. 테마·아이콘 테마 복사본은 고정 버전에서 `resources/zed-themes/`·`resources/zed-icon-themes/`로 받고 커밋하지 않는다

**선택**

- 출처(core ORDER-07 2장, 두 갈래 같은 버전):
  - Zed 기본 테마: `zed-industries/zed` 커밋 `4304dec732a75505066de5ce2dbbfb2bec369498`의 `assets/themes/`(라이선스 `assets/themes/LICENSES`).
  - Catppuccin 테마: `catppuccin/zed` 0.2.27.
  - macOS Classic 테마: `huacnlee/zed-theme-macos-classic` 0.4.0.
  - Catppuccin Icons 아이콘 테마: `catppuccin/zed-icons` 1.24.0.
  - Zed (Default) 아이콘 테마: D-6 복사본(`resources/zed-icons/file_icons/`, 같은 커밋).
  - 확장 셋의 라이선스는 각 저장소 LICENSE다.
- 두는 곳: 테마는 `resources/zed-themes/`, 아이콘 테마는 `resources/zed-icon-themes/`. 둘 다 `.gitignore`에 넣고 커밋하지 않는다.
- 다시 채우기: 저장소 루트에서 `pwsh -NoProfile -File tools/fetch-zed-themes.ps1`. 위 고정 커밋·버전만 받는다.
- 복사본이 없을 때: 앱은 죽지 않는다. gpui-kit 기본 테마로 뜨고 경고를 낸다.
- 기본값: `settings.json`에 값이 없으면 테마 One Dark, 아이콘 테마 Zed (Default)(core ORDER-07 3.1·3.2).

**근거**

- core D-8을 이 레포에 적용했다. 폴더·다시 채우기·없을 때 모습·기본값은 leader가 정했다(W-27).
- 확장 버전은 이 PC에 설치된 버전이다. leader가 `%LOCALAPPDATA%\Zed\extensions\installed\<확장>\extension.toml`을 읽기만 해서 확인했다(core ORDER-07 2장 버전 고정).
- 아이콘 복사본과 같은 방식이다(D-6).

**배제한 대안**

- **이 PC의 Zed 설치 폴더에서 실행 중에 읽는다** — 버전이 고정되지 않는다. core ORDER-07 2장·6장이 금지했다.
- **복사본을 커밋한다** — core D-8이 `.gitignore` 폴더에 두기로 했다.

---

## D-12. Project Search에 crate `ignore 0.4.34`·`regex 1.13.1`을 직접 의존성으로 쓴다

**선택**

- Project Search(R-22, core D-17)의 파일 찾기(`.gitignore` 반영)에 `ignore 0.4.34`, 정규식·단어 단위 검색에 `regex 1.13.1`을 쓴다.
- 두 crate는 이미 `Cargo.lock` 의존성 트리에 있는 버전이다. 직접 의존성으로 올릴 때 같은 버전으로 적는다.
- Help → View Dependency Licenses 창(SPEC R-2 Licenses 창)에 두 crate의 라이선스를 더해야 한다. `ignore`는 Unlicense OR MIT(`UNLICENSE`·`LICENSE-MIT`), `regex`는 MIT OR Apache-2.0(`LICENSE-MIT`·`LICENSE-APACHE`). 넣는 방식은 미정(구현 카드에서 정한다).

**근거**

- core-leader 승인(2026-11-07, gpui-leader W-34 전달). `Cargo.toml` 변경은 승인이 필요하다(`AGENTS.md` 9장).
- 같은 버전을 쓰면 의존성 트리에 새 crate가 늘지 않는다. tauri도 같은 crate로 구현했다(`src-tauri/src/project_search.rs`).

**배제한 대안**

- **표준 라이브러리로 폴더를 돌고 직접 매칭한다** — `.gitignore` 규칙과 정규식을 다시 만드는 일이 커진다(AGENTS 4.1 순서 5).

---

## 미결 사항

- SPEC 요구 번호를 core I-n과 같은 번호의 R-n으로 매기는 것(R-1 = I-1 … R-23 = I-23). writer 초안이다. 번호 체계는 갈래가 정한다(ORDER-01 3.1). 정할 사람: leader(사용자 확정).
- (해소) core D-8의 복사본 경로·출처·없을 때 모습·다시 채우기 — D-11로 정했다. core D-9 쪽은 D-6으로 정했다.
- core D-10에서 넣을 글꼴 굵기·스타일 파일과 글꼴 버전. 정할 사람: leader(Phase 3 카드).

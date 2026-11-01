> 버전: v0.1 · 작성일: 2026-10-31 · 상태: 진행 중
>
> 실제로 한 일과 검증 결과를 기록한다. 계획은 `PLAN.md`에, 요구는 `SPEC.md`에 있다. 검증 보고서는 `specs/v0.1/verify/`에 있다.

# PROGRESS — workbench-gpui v0.1

## Phase별 진행

### Phase 0 — 프로젝트 뼈대

- **빌드 준비물 확인 (G-121)** (2026-10-31)
  - 무엇을 했나: Rust·cargo 버전, MSVC, Windows SDK, CMake 설치 여부를 확인했다.
  - 결과: rustc 1.99.1, cargo 1.99.1이다. crates.io `rust_version` 1.90과 설치 문서 1.92 둘 다 이상이다. Visual Studio Build Tools 2022가 C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools 에 있다. Windows SDK는 10.0.26100.0이다.
  - 검증: `rustc --version`, `cargo --version`, vswhere 조회, Windows Kits Include 폴더 목록으로 확인했다.
  - 특이사항: CMake가 PATH에 없다. Build Tools 안 Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe 에 있다. PATH에 없어도 빌드는 성공했다.

- **cargo 프로젝트 생성** (2026-10-31)
  - 무엇을 했나: 레포 루트에 cargo 바이너리 프로젝트 `workbench-gpui`를 만들었다.
  - 결과: `Cargo.toml`의 의존성은 `gpui-kit = "=0.8.1"` 하나다(D-3). `Cargo.lock`이 생성되었다(D-4, 커밋 대상). `src/main.rs`는 빈 창 하나를 띄운다. `src/ui/mod.rs`는 래퍼 계층 자리다(D-5). `.gitignore`에 `target/`을 넣었다.
  - 검증: runner(wg-runner-build)에서 `cargo build` 성공. dev profile, 4m 26s, exit 0.
  - 특이사항: 없음.

- **빈 창 실행** (2026-10-31)
  - 무엇을 했나: runner(wg-runner-app)에서 앱을 실행했다.
  - 결과: 창이 떴다. 창 2880×1704 물리 px, DPI 192(200%)다. 현재는 OS 기본 타이틀 바와 흰 배경이다.
  - 검증: 증거 `specs/v0.1/verify/phase0/empty-window.png`.
  - 특이사항: 없음.

- **검증 도구 tools/capture.ps1 추가** (2026-10-31)
  - 무엇을 했나: 앱 메인 창의 사각형(물리 px)·DPI 배율·최대화 여부를 JSON으로 내고 창 영역을 PNG로 저장하는 PowerShell 7 스크립트를 만들었다. 측정 전에 스레드를 PER_MONITOR_AWARE_V2로 바꾼다. 외부 모듈 없이 Add-Type(C# P/Invoke)만 쓴다.
  - 결과: `tools/capture.ps1`. 캡처 방식은 Screen(기본)과 PrintWindow 중 고를 수 있다.
  - 검증: 실행 중인 앱에 `pwsh -NoProfile -File tools/capture.ps1 -Out $env:TEMP\cap-test.png`로 실행해 JSON 출력과 PNG 저장을 확인했다.
  - 특이사항: 첫 작성본에서 C# 컴파일 오류가 났다. 원인은 `-ReferencedAssemblies`를 주면 기본 참조가 줄어 생긴 어셈블리 참조 누락이다(System.Collections, System.Private.Windows.GdiPlus 등). 참조를 추가해 고쳤다. 또 캡처 방식이 Screen 복사라 창이 작업 영역보다 크면 작업 표시줄이 같이 찍힌다. Phase 1에서 PrintWindow를 우선 쓰도록 고쳐야 한다.

- **리뷰 (wg-reviewer)** (2026-10-31)
  - 무엇을 했나: `git diff --cached`를 리뷰했다.
  - 결과: 지적 4건. Major 2건은 capture.ps1이 PER_MONITOR_AWARE_V2 스레드에서 GetDpiForMonitor를 부른 것, SetForegroundWindow 실패를 무시하고 화면을 복사한 것이다. Minor 2건은 측정 시점과 캡처 시점이 어긋난 것, main.rs가 D-5 래퍼를 거치지 않은 것이다. 4건 모두 반영했다.
  - 검증: 재빌드 exit 0. capture.ps1이 PrintWindow로 캡처에 성공했고 작업 표시줄이 섞이지 않는다. `specs/v0.1/verify/phase0/empty-window.png`를 다시 만들었다.
  - 특이사항: 없음.

- **완료 조건 검증 (wg-checker)** (2026-10-31)
  - 무엇을 했나: PLAN Phase 0 완료 조건을 검증했다.
  - 결과: `specs/v0.1/verify/phase0/REPORT.md`. 통과 5, 실패 0.
  - 검증: 보고서 `specs/v0.1/verify/phase0/REPORT.md`.
  - 특이사항: "Phase 끝 순서" 1건은 커밋으로 마감한다.

### Phase 1 — 창과 타이틀 바

- **타이틀 바·창 버튼 구현** (2026-10-31)
  - 무엇을 했나: 커스텀 타이틀 바와 창 버튼을 만들었다. gpui-kit `TitleBar`는 높이 34·버튼 34px SVG로 고정이라, 창 옵션만 `TitleBar::window_options()`를 쓰고 그리는 부분은 gpui `WindowControlArea`(Drag/Min/Max/Close)로 직접 조립했다(DECISIONS D-9 이후 변경).
  - 결과: `src/ui/title_bar.rs`, `src/ui/metrics.rs`, `src/ui/mod.rs`. 타이틀 바 32, 창 버튼 36×32, `Segoe Fluent Icons` 글리프 10px(U+E921/E922/E923/E8BB, 최대화 상태에 따라 E922↔E923), 닫기 hover `#E81120`·흰 글자, 최소 크기 360×240이다. L-311 클라이언트 장식 분기는 넣었지만, gpui-pre의 Windows 창은 장식이 Server라 그 분기는 Windows에서 그려지지 않는다.
  - 검증: 아래 "완료 조건 검증" 항목.
  - 특이사항: 닫기 외 버튼 hover·누름 색과 글리프 글꼴 선택 기준은 DECISIONS 미결 사항에 적었다.

- **앱 매니페스트 병합 (G-128)** (2026-10-31)
  - 무엇을 했나: gpui-pre 0.3.10이 기본으로 넣는 매니페스트(Common Controls v6, PerMonitorV2)에 longPathAware가 없어, 조각 `resources/windows/longpath.manifest.xml`을 만들고 `tools/apply-manifest.ps1`이 Windows SDK mt.exe로 exe의 기존 매니페스트(#1)에 병합하게 했다.
  - 결과: 병합한 뒤 꺼낸 매니페스트가 `specs/v0.1/verify/phase1/manifest.xml`에 있다.
  - 검증: `tools/apply-manifest.ps1`이 꺼낸 매니페스트에서 Common Controls v6·PerMonitorV2·longPathAware 세 항목을 검사한다.
  - 특이사항: cargo 빌드를 하면 병합이 사라진다. 빌드할 때마다 `tools/apply-manifest.ps1`을 다시 실행해야 한다.

- **R-5 시험용 dev 플래그** (2026-10-31)
  - 무엇을 했나: `--dev-taskdialog`, `--dev-open-longpath <path>`를 `src/dev.rs`에 만들었다. 새 크레이트 없이 Win32 FFI로 부른다.
  - 결과: 디버그 빌드에서만 동작한다(`cfg!(debug_assertions)`). TaskDialog는 LoadLibraryW·GetProcAddress로 실행 중에 찾고, 모듈은 모든 경로에서 FreeLibrary로 해제한다.
  - 검증: `tools/verify-r5.ps1` 실행 결과(아래 "완료 조건 검증").
  - 특이사항: 없음.

- **증거 수집 스크립트** (2026-10-31)
  - 무엇을 했나: `tools/verify-phase1.ps1`(R-1~R-3: 스냅 플라이아웃, 더블클릭 최대화·복원, 끌기, 리사이즈, 최소 크기, 닫기 hover, 비최대화·최대화 캡처)과 `tools/verify-r5.ps1`(R-5: TaskDialog, 260자 넘는 경로)을 만들었다. `tools/capture.ps1`을 다시 쓴다.
  - 결과: 증거가 `specs/v0.1/verify/phase1/`에 있다. 단계별 PNG·JSON, `summary.json`, `snap-flyout.png`, `r5-taskdialog.txt`·`r5-taskdialog.png`, `r5-longpath.txt`.
  - 검증: `pwsh -NoProfile -File tools/verify-phase1.ps1`을 끝까지 실행해 errors 0, 종료 코드 0, 스크립트가 띄운 앱 종료를 확인했다(2026-11-01, PID 7968 / HWND 0x1F07B4).
  - 특이사항: 첫 작성본에서 C# 컴파일 오류(`Thread`)가 났다. 원인은 `-ReferencedAssemblies`로 줄어든 어셈블리 참조(System.Threading, System.Threading.Thread)였고, 참조를 추가해 고쳤다. 실행 중에 `Process.MainWindowHandle`이 같은 프로세스의 54×36 다른 창을 가리켜 엉뚱한 창을 캡처한 일이 있었다. 그래서 capture.ps1(`-Title`, `-Hwnd`)과 verify-phase1.ps1이 앱 제목인 창을 고르고, 스크립트가 띄운 PID·HWND로 고정하게 바꿨다.

- **빌드** (2026-10-31)
  - 무엇을 했나: runner에서 Phase 1 코드를 빌드했다.
  - 결과: 링크 오류 `LNK2019 unresolved external __imp_RtlAreLongPathsEnabled`가 났다. SDK의 ntdll.lib가 이 심볼을 내보내지 않기 때문이다. `GetModuleHandleW("ntdll.dll")`과 `GetProcAddress`로 실행 중에 찾도록 바꿔 해결했다.
  - 검증: runner 재빌드 성공.
  - 특이사항: 없음.

- **리뷰 (wg-reviewer) 1회차** (2026-10-31)
  - 무엇을 했나: Phase 1 변경을 리뷰했다.
  - 결과: 지적 4건, 모두 반영했다. Major 2건은 dev 플래그가 릴리스 빌드에서도 동작하는 것, 전면 전환·대상 창 확인 없이 SendInput을 보내는 것이다. Minor 2건은 LoadLibraryW 모듈 미해제, SendInput DllImport의 `SetLastError` 누락이다.
  - 검증: 2회차 리뷰에서 해결을 확인했다.
  - 특이사항: 없음.

- **리뷰 (wg-reviewer) 2회차** (2026-11-01)
  - 무엇을 했나: 1회차 반영분을 다시 리뷰했다.
  - 결과: 1회차 4건의 해결을 확인했다. 새 Major 1건은 같은 이름 프로세스가 여러 개일 때 입력 대상과 캡처 대상이 달라질 수 있다는 것(PID/HWND 고정 안 됨)이다. 반영했다. 시작 전에 workbench-gpui가 이미 실행 중이면 오류로 끝내고, 스크립트가 띄운 PID·HWND를 capture.ps1에 `-Hwnd`로 넘겨 결과 JSON의 hwnd·pid를 대조한다.
  - 검증: verify-phase1.ps1 재실행 errors 0.
  - 특이사항: 없음.

- **완료 조건 검증 (wg-checker)** (2026-10-31 ~ 2026-11-01)
  - 무엇을 했나: R-1~R-5를 SPEC 판정 방법대로 검증했다.
  - 결과: 보고서 `specs/v0.1/verify/phase1/REPORT.md`.
    - R-1: 1회차 실패(`snap-flyout.png`에 스냅 플라이아웃이 보이지 않음). 원인은 스크립트의 hover 방식이었다. 앱은 HTMAXBUTTON을 돌려준다(gpui-pre-windows 0.3.10 `src/events.rs` 971행). 마우스를 여러 번 나눠 움직이고 1.5초 머물도록 고친 뒤 2회차 통과.
    - R-2: 통과.
    - R-3: 통과(SPEC R-3 이후 변경 적용: OS가 그린 모서리·테두리 관찰값 기록).
    - R-4: 실패. 100·150% 배율을 시험하지 않았다. 모니터 이동은 모니터가 하나라 판정 불가.
    - R-5: 실패. 150% 배율을 시험하지 않았다. TaskDialog는 성공했다(`r5-taskdialog.txt` hresult=0x00000000, `r5-taskdialog.png`). 319자 경로 열기는 OS 설정 LongPathsEnabled=0이라 실패했다(`r5-longpath.txt` rtl_long_paths_enabled=false, win32_error=3).
  - 검증: 보고서 `specs/v0.1/verify/phase1/REPORT.md`와 위 증거 파일.
  - 특이사항: 미해결 실패 R-4·R-5(배율 시험)는 Windows 디스플레이 배율을 바꿔야 해서 사용자 결정 대기다. PLAN 규칙("미해결 실패가 있으면 다음 Phase로 넘어가지 않는다")에 따라 Phase 1은 커밋하지 않고 멈췄다. → 해소(2026-11-01): 사용자가 배율 변경을 허락해 아래 "배율 시험"과 "완료 조건 재검증"으로 R-4·R-5가 통과했다.

- **배율 시험 (R-4·R-5)** (2026-11-01)
  - 무엇을 했나: 사용자 허락(2026-11-01, "leader가 배율을 바꿔도 됨")으로 leader가 `tools/set-scale.ps1`로 주 모니터 배율을 바꾸고 `tools/verify-scale.ps1`로 증거를 모았다. 시험 뒤 배율을 200%로 되돌렸다.
  - 결과:
    - 100%: DPI 96, 타이틀 바 32 물리 px = 32 논리 px, 닫기 버튼 폭 36.
    - 150%: DPI 144, 타이틀 바 48 물리 px = 32 논리 px, 닫기 버튼 폭 54 물리 px = 36 논리 px. 150%에서 TaskDialog가 정상으로 떴다.
  - 검증: 증거 `specs/v0.1/verify/phase1/scale-100/`, `specs/v0.1/verify/phase1/scale-150/`(각 `result.json`, `window.png`, `close-hover.png`, `buttons-zoom.png`, `buttons-hover-zoom.png`, 150%는 `r5-taskdialog.txt`·`r5-taskdialog.png`·`r5-longpath.txt` 포함).
  - 특이사항: 타이틀 바와 본문의 배경색이 같아, 높이는 닫기 버튼 hover 배경(`#E81120`)의 세로 길이로 쟀다. 레지스트리 LongPathsEnabled가 0이라 319자 경로 열기는 win32_error=3으로 기록만 했다. 시스템 설정은 바꾸지 않았다.

- **완료 조건 재검증 (wg-checker) 3회차** (2026-11-01)
  - 무엇을 했나: R-1~R-5를 SPEC 판정 방법대로 다시 검증했다.
  - 결과: R-1~R-5 모두 통과. R-4의 모니터 이동 시험은 모니터가 하나라 판정 불가로 적었다(SPEC R-4가 허용). 리뷰는 2회차까지 Major·Minor 모두 반영되었다.
  - 검증: 보고서 `specs/v0.1/verify/phase1/REPORT.md`.
  - 특이사항: 없음.

- **Phase 1 완료** (2026-11-01)
  - 무엇을 했나: PLAN Phase 1 완료 조건을 대조했다.
  - 결과: R-1~R-5 통과, `specs/v0.1/verify/phase1/` 검증 보고서 있음, wg-reviewer 리뷰 결과 기록됨. 미해결 실패가 없어 Phase 1을 완료로 본다.
  - 검증: `specs/v0.1/verify/phase1/REPORT.md`와 이 PROGRESS 기록.
  - 특이사항: PLAN의 Phase 1 완료 조건 중 "Phase 1 커밋이 있다"는 이 기록 뒤의 커밋으로 채운다.

### Phase 2 — 편집기 PoC

- **apply-manifest 출력 경로 변경** (2026-11-01)
  - 무엇을 했나: leader 결정(docs/HERDR-DECISIONS.md D-014 ③)으로 `tools/apply-manifest.ps1`의 기본 출력 경로를 `specs\v0.1\verify\phase1\manifest.xml`에서 `target\manifest\manifest.xml`로 바꿨다.
  - 결과: 빌드마다 병합을 다시 해도 Phase 1 증거 파일이 바뀌지 않는다.
  - 검증: `git status`에서 `specs/v0.1/verify/phase1/manifest.xml` 변경 없음(커밋된 내용 그대로).
  - 특이사항: 없음.

- **편집기 PoC 화면** (2026-11-01)
  - 무엇을 했나: 디버그 빌드 전용 플래그 `--dev-editor-poc`로 gpui-kit 0.8.1 `Input`(한 줄)과 `Editor`(여러 줄 코드 편집기)를 본문에 띄우는 화면을 만들었다. 파일 열기(`--dev-poc-file`), soft wrap 끄기(`--dev-no-wrap`), 성능 측정(`--dev-perf`), 열기→저장(`--dev-roundtrip-out`, `--dev-roundtrip-mode naive|app`), 측정(`--dev-measure`) 플래그와, 값이 바뀔 때 `[dev] value ...` 출력을 넣었다.
  - 결과: `src/ui/editor_poc.rs`(새 파일), `src/ui/mod.rs`, `src/dev.rs`. 인코딩 감지·변환(UTF-8, UTF-8 BOM, UTF-16 LE/BE, CP949)은 새 크레이트 없이 표준 라이브러리와 Win32 MultiByteToWideChar/WideCharToMultiByte 로 했다.
  - 검증: `cargo build` 경고 없이 성공, `tools/apply-manifest.ps1` 세 항목 true. PoC 화면 스크린샷 `specs/v0.1/verify/phase2/r7-editor.png`.
  - 특이사항: 없음.

- **R-6 한글 IME 자동화** (2026-11-01)
  - 무엇을 했나: `tools/verify-ime.ps1`을 만들어 실행했다. 대상 창의 기본 IME 창(ImmGetDefaultIMEWnd)에 WM_IME_CONTROL 로 IME 를 열고 한글 모드로 바꾼 뒤, SendInput 가상 키로 "한"을 조합하고 한자 키로 후보창을 띄우고, Space 로 확정하고 "가나"를 이어 쳤다. Editor 와 Input 둘 다 했다.
  - 결과: 자동화가 됐다. 두 필드 모두 조합 중 밑줄 표시, 조합 글자 바로 아래 후보창, 확정 글자 "한 가나 "가 값에 들어감을 확인했다.
  - 검증: `specs/v0.1/verify/phase2/r6-ime.json`(committedTextFound 둘 다 true, IME 변환 모드 전후 값), `r6-editor-composing.png`, `r6-editor-candidate.png`, `r6-editor-committed.png`, `r6-input-*.png`, `r6-stdout.txt`.
  - 특이사항: 첫 실행에서 PowerShell 함수가 한 개짜리 배열을 문자열로 풀어 오류가 나 `@()`로 감싸 고쳤다. 한자 키 뒤 새로 나타난 최상위 창은 창 목록에서 찾지 못해, 후보창 위치는 모니터 전체 캡처로 판정했다.

- **R-7 Editor 동작 지원 범위** (2026-11-01)
  - 무엇을 했나: G-101 항목마다 gpui-base 0.8.1 소스 위치와 PoC 화면으로 지원 여부를 확인했다.
  - 결과: `specs/v0.1/verify/phase2/POC-TABLE.md` G-101 표. 직접 구현 필요는 줄 번호 최소 4자리, 커서 2px, 선택 모서리 둥글림, 열 선택 조작 키, 선택 끌어 옮기기, 스크롤바 15px, 스크롤바 마커다.
  - 검증: 판정표의 소스 파일·줄, `r7-editor.png`.
  - 특이사항: 없음.

- **R-8 큰 파일** (2026-11-01)
  - 무엇을 했나: `tools/verify-phase2.ps1 -Steps r8`로 5만·10만 줄 파일(줄마다 약 78바이트, `target\phase2-data\`, 커밋 안 함)을 열고 스크롤 20회·입력 20회를 했다. 측정은 앱 안에서 변경을 적용한 시점부터 그 변경이 그려진 프레임 직후까지다(leader 승인, HERDR-DECISIONS D-014 ②). 디버그 빌드와, 최적화 빌드에 debug_assertions 만 켠 빌드(`target\opt-dbgassert`, dev 플래그가 동작하게) 두 가지로 쟀다.
  - 결과: opt 기준 10만 줄 set_value 185ms, 그 뒤 첫 프레임 8,356ms(5만 줄 5,007ms). soft wrap 을 끄면 첫 프레임 328ms. 스크롤 평균 8.41ms(최대 16.67), 입력 평균 10.63ms(최대 15.86).
  - 검증: `specs/v0.1/verify/phase2/r8-perf-opt.json`, `r8-perf-debug.json`, `r8-*-stdout.txt`, `r8-100k-opt-nowrap-stdout.txt`, `r8-*-after.png`.
  - 특이사항: 디버그 빌드만으로는 수치를 믿기 어려워 최적화 빌드를 따로 만들었다(빌드 4분 10초). 이 빌드에도 `tools/apply-manifest.ps1`을 적용했다(세 항목 true). 첫 프레임 지연의 원인은 문서 전체의 soft wrap 계산이다. → 리뷰 1회차에서 계측 시점이 draw·present 이전이라는 지적이 있어 다시 쟀다(아래 "리뷰 1회차" 항목). 이 항목의 수치와 증거 파일은 그 재측정으로 대체되었다.

- **R-9 줄 끝·인코딩** (2026-11-01)
  - 무엇을 했나: `tools/verify-phase2.ps1 -Steps r9`로 LF UTF-8, CRLF UTF-8, CRLF UTF-16 LE(BOM), CRLF CP949 파일을 만들고, naive·app 두 방식으로 열기→Editor 값 다시 읽기→저장 후 바이트를 비교했다.
  - 결과: LF·CRLF UTF-8 은 두 방식 모두 바이트가 같다(Editor 가 `\r`을 그대로 둔다). UTF-16 LE 와 CP949 는 naive 에서 바이트가 달라지고(96→126, 56→76), app 에서는 같다(96→96, 56→56).
  - 검증: `specs/v0.1/verify/phase2/r9-roundtrip.json`, `r9/`(입력·출력 파일과 실행 출력).
  - 특이사항: 이 저장소는 `core.autocrlf=true`라 git 이 증거 파일의 LF/CRLF 를 바꿀 수 있다. 루트에 `.gitattributes`를 새로 두어 `r9/in-*`, `r9/out-*`를 `-text`(변환 안 함)로 지정했고, 스테이징한 바이트 수가 디스크와 같음을 확인했다(예: in-crlf-utf8.txt 65=65).

- **R-10 한글 대체 글꼴** (2026-11-01)
  - 무엇을 했나: `--dev-measure`로 영문 줄·한글 줄·혼합 줄의 줄 위치·폭·거터·커서를 내고, 각 줄을 편집기 글꼴로 다시 배치해 글자 묶음마다 쓰인 글꼴을 냈다. 스크린샷 픽셀로 잉크 아래 끝(기준선 근사)과 잉크 폭을 쟀다(`tools/verify-phase2.ps1 -Steps r10`).
  - 결과: 줄 높이 20(세 줄 같음), 거터 45.44, 10글자 폭 영문 71.47·한글 130.00, 줄 끝 커서 x 는 줄 시작+줄 폭과 같다. 잉크 아래 끝은 영문 줄 14, 혼합 줄 영문 15, 한글 16 이다(한글이 섞인 줄은 영문 기준선이 1 내려간다).
  - 검증: `specs/v0.1/verify/phase2/r10-stdout.txt`, `r10-pixels.json`, `r10-measure.png`.
  - 특이사항: leader 결정(HERDR-DECISIONS D-014 ①)으로 gpui-kit 기본 고정폭 글꼴로 쟀다. 이 PC 에서는 Consolas 13px 이고, Consolas 에는 한글이 없어 한글 묶음은 대체 글꼴로 그려진다. gpui 가 알려 준 대체 글꼴 이름은 `.SystemUIFont`(gpui 의 시스템 UI 글꼴 별칭)이고, DirectWrite 가 실제로 고른 글꼴 파일 이름은 알 수 없었다. Zed 글꼴 자산 도입은 DECISIONS 미결 사항에 추가했다. 픽셀 측정 첫 실행에서 구간의 배경색을 다음 글자 위에서 잡는 버그가 있어, 편집기 오른쪽 빈 곳에서 잡도록 고쳐 다시 쟀다.

- **R-11 PoC 판정표** (2026-11-01)
  - 무엇을 했나: R-6~R-10 결과를 `항목 / gpui-kit 지원 / 직접 구현 필요 / 증거` 판정표 하나로 모았다.
  - 결과: `specs/v0.1/verify/phase2/POC-TABLE.md`. 모든 행에 직접 구현 필요/불필요 결정과 근거가 있고, 판정 불가 행은 없다. 직접 구현 필요는 11건(줄 번호 4자리, 커서 2px, 선택 모서리, 열 선택 조작 키, 선택 끌어 옮기기, 스크롤바 15px, 스크롤바 마커, 큰 파일 wrap 열기, UTF-16 LE, CP949, 한글 혼합 줄 기준선)이다.
  - 검증: 판정표의 증거 파일과 소스 위치.
  - 특이사항: 리뷰(wg-reviewer)·검증(wg-checker)과 커밋은 아직이다(leader 지시 대기). → 리뷰 1회차 반영으로 판정표가 바뀌었다(직접 구현 필요 12건, 아래 항목).

- **리뷰 (wg-reviewer) 1회차** (2026-11-01)
  - 무엇을 했나: Phase 2 변경 리뷰에서 Major 3건이 나왔고, leader 가 모두 채택했다(docs/HERDR-DECISIONS.md D-016). 3건을 반영하고 R-6·R-8·R-9 를 다시 실행했다.
  - 결과:
    - ① R-8 계측: 기존 값은 `on_next_frame` 콜백 시점이라, 같은 프레임의 draw·present 보다 먼저 찍혔다(gpui-pre 0.3.10 `src/window.rs` 1878~1912행). 콜백에서 foreground 작업을 예약해 프레임 핸들러(draw·present)가 끝난 뒤 시간을 재도록 바꿨다(`src/ui/editor_poc.rs` after_present). 측정마다 그 시점까지 화면이 실제로 다시 그려졌는지 세어 출력한다. 재측정(opt): 10만 줄 열기(wrap 켜짐) 첫 프레임 7,619ms, wrap 끔 302ms, 스크롤 평균 11.71·최대 19.53ms, 입력 평균 12.70·최대 18.11ms, 모든 측정 drawn=20/20. 최대값이 한 프레임(16.7ms)을 넘어 "한 프레임 안" 근거를 버리고, "줄 수·wrap 에 따라 지연이 달라지지 않는다"로 스크롤·입력 판정 근거를 바꿨다(결정은 불필요 그대로). 스크립트에 10만 줄 wrap 끔 측정을 넣었다.
    - ② CP949 인코딩: WideCharToMultiByte 를 flags 0 으로 불러 best-fit 치환(U+20A9→0x5C, U+00A5→0xA1CD)이 손실 없이 성공으로 나오던 것을 고쳤다. `WC_NO_BEST_FIT_CHARS` 를 쓰고, 두 호출의 반환값·used_default 를 검사하고, 결과를 다시 풀어 원문과 같은지 확인한다. 디코드 쪽 두 번째 호출의 반환값도 검사한다. 시험을 두 가지 넣었다: 단위 테스트 4개(`cargo test --bin workbench-gpui dev::tests`, 4 passed), 앱 자기 시험 `--dev-cp949-selftest`(R-9 단계에서 실행, 4/4 통과, ₩·¥ 는 오류로 잡힘). 판정표에 "CP949 로 옮길 수 없는 글자의 저장 손실" 행(직접 구현 필요)을 더했다.
    - ③ verify-ime.ps1: IME 조회의 음수 실패값과 열림 상태를 먼저 검사하고 그다음 한글 모드 비트를 본다. committedTextFound 가 false 면 errors 에 넣어 종료 코드 1 로 끝낸다. 조합 표시·후보창 위치는 자동 판정이 없어 `r6-ime.json` visualCheck 에 "수동 판정 대기"로 남기고, 판정표에 스크린샷 판정이라고 적었다. 재실행: 두 필드 모두 open 1, mode 1, committedTextFound true, errors 0, 종료 코드 0.
  - 검증: `cargo build` 경고 없음, `tools/apply-manifest.ps1` 세 항목 true(디버그·opt 빌드 둘 다). 증거 `specs/v0.1/verify/phase2/r8-perf-opt.json`, `r8-perf-debug.json`, `r8-*-stdout.txt`, `r9-cp949-selftest.json`, `r9/r9-cp949-selftest-stdout.txt`, `r9/r9-cp949-unittest.txt`, `r9-roundtrip.json`(바이트 비교 결과 이전과 같음), `r6-ime.json`, `r6-*.png`, `POC-TABLE.md`.
  - 특이사항: R-8 이전 증거 파일(`r8-*`)은 지우고 새 계측으로 다시 만들었다. 커밋은 하지 않았다(leader 지시 대기).

- **리뷰 (wg-reviewer) 2회차** (2026-11-01)
  - 무엇을 했나: 1회차 반영분을 다시 리뷰했다.
  - 결과: 1회차 Major 3건(R-8 계측 시점, CP949 저장 손실, verify-ime.ps1 실패의 성공 처리)이 모두 해결됐다고 확인했다. 새 지적은 없다.
  - 검증: 리뷰 결과에 근거로 `r8-perf-opt.json`(세 구성 모두 firstFrameDrawn=true, drawn=20), `r9-cp949-selftest.json`(4/4), `tools/verify-ime.ps1`의 실패 분기가 적혀 있다.
  - 특이사항: 없음.

- **완료 조건 검증 (wg-checker)** (2026-11-01)
  - 무엇을 했나: R-6~R-11 을 SPEC 판정 방법대로 검증했다. 1회차(08:58)는 리뷰 반영 전 증거로, 2회차(09:15)는 리뷰 1회차 반영 뒤 다시 모은 증거로 했다.
  - 결과: 보고서 `specs/v0.1/verify/phase2/REPORT.md`.
    - 1회차: R-6~R-11 모두 통과.
    - 2회차(최종): R-6~R-11 모두 통과. R-6 의 조합 표시·후보창 위치(visualCheck "수동 판정 대기")는 검증 담당이 새 스크린샷을 직접 보고 통과로 판정했다. R-8 은 draw·present 이후 재측정값(drawn=20/20)으로, R-9 는 CP949 단위 테스트 4건·자기 시험 4/4·바이트 비교로 확인했다. R-11 판정표는 35행(직접 구현 필요 12, 불필요 23, 판정 불가 0)이다.
  - 검증: 보고서 `specs/v0.1/verify/phase2/REPORT.md`와 `specs/v0.1/verify/phase2/`의 증거 파일.
  - 특이사항: 없음.

- **Phase 2 완료** (2026-11-01)
  - 무엇을 했나: PLAN Phase 2 완료 조건을 대조했다.
  - 결과: `specs/v0.1/verify/phase2/POC-TABLE.md` 판정표가 있고, R-6~R-10 이 각각 통과(증거 포함), R-11 통과(모든 항목에 직접 구현 필요/불필요 결정과 근거), wg-reviewer 리뷰 결과(1·2회차) 기록됨. 미해결 실패가 없어 Phase 2 를 완료로 본다.
  - 검증: `specs/v0.1/verify/phase2/REPORT.md`와 이 PROGRESS 기록.
  - 특이사항: PLAN 의 Phase 2 완료 조건 중 "Phase 2 커밋이 있다"는 이 기록 뒤의 커밋으로 채운다. 직접 구현이 필요한 12건은 이후 구현 단계의 범위다.

### Phase 3 — 레이아웃 뼈대

아직 없음.

## 사용자 요청 작업

없음.

## 버전 종료

진행 중.

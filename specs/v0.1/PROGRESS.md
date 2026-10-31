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

아직 없음.

### Phase 3 — 레이아웃 뼈대

아직 없음.

## 사용자 요청 작업

없음.

## 버전 종료

진행 중.

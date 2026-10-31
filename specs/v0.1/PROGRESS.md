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

아직 없음.

### Phase 2 — 편집기 PoC

아직 없음.

### Phase 3 — 레이아웃 뼈대

아직 없음.

## 사용자 요청 작업

없음.

## 버전 종료

진행 중.

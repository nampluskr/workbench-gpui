> 버전: v0.3 · 작성일: 2026-11-03 · 상태: 확정 (2026-11-03)
>
> 이번 버전(v0.2까지의 코드 리팩토링, refactor-draft P0~P3)에 적용할 설계 결정을 기록한다. 기준 문서는 `docs/refs/refactor-draft/`이고(D-2), 에이전트 운영은 `HERDR-SETUP.md`에 있다. 이번 버전에 무엇을 왜 하는지는 `specs/v0.3/INTENT.md`에, 변하지 않는 의도는 루트 `INTENT.md`에 있다. 지난 버전 결정은 `specs/v0.1/DECISIONS.md`, `specs/v0.2/DECISIONS.md`에 있다(읽기만 한다).

# DECISIONS — workbench-gpui v0.3

## D-1. v0.1 D-1~D-10과 v0.2 D-2~D-18을 그대로 이어받고, 바꿀 때는 이 문서에 새 결정으로 적는다

**선택**

- `specs/v0.2/DECISIONS.md` D-1(v0.1 D-1~D-10을 이어받음)과 D-2~D-18을 v0.3에서도 그대로 따른다.
- 리팩토링 항목이 이 결정들을 건드리는 경우가 있다. 예를 들어 의존 크레이트를 바꾸거나 빼는 경우(v0.1 D-3·D-4, v0.2 D-4·D-6), 트리 구현을 바꾸는 경우(v0.2 D-8)다. 이런 항목은 사용자가 승인한 뒤 이 문서에 새 `D-n`으로 적는다.
- 지난 버전 폴더는 고치지 않는다.

**근거**

- v0.3의 목적은 기능을 더하지 않고 같은 동작을 유지하는 리팩토링이다(`specs/v0.3/INTENT.md` 목적, 사용자 결정 2026-11-03).
- 지난 결정은 v0.2의 동작과 의존을 정한 것이라, 그대로 두는 것이 "동작 불변"의 전제다.
- 지난 버전 폴더는 그대로 두고 읽기만 한다(WORKFLOW 5절, `AGENTS.md` "지난 버전 폴더 불변").

**배제한 대안**

- **리팩토링 항목마다 지난 결정을 조용히 바꾼다** — 무엇이 바뀌었는지 문서에 남지 않는다. 결정은 사람이 정한다는 규칙(`AGENTS.md` "사람이 정하고 묻는다")에도 어긋난다.

---

## D-2. v0.3는 `docs/refs/refactor-draft/` 문서를 기준으로 진행하고, 데스크톱·워크스페이스·토큰 부담에 맞게 고쳐 반영한다

**선택**

- `docs/refs/refactor-draft/`의 다섯 문서는 사용자가 검토한 v0.3의 **기준 문서**다: PLAN, FINALIZE, HERDR, HERDR-SETUP, AGENTS.draft.
  - 원문은 고치지 않고 보존한다.
  - 반영한 문서가 실제 운영 기준이다.

  | 초안 | 반영 위치 |
  | --- | --- |
  | `HERDR.md` + `HERDR-SETUP.md` | `specs/v0.3/HERDR-SETUP.md` (D-10, D-11) |
  | `AGENTS.draft.md` | 루트 `AGENTS.md` "에이전트 공통 지침" (`CLAUDE.md`는 `@AGENTS.md` 그대로) |
  | `PLAN.md` | `specs/v0.3/PLAN.md` Phase 0~3 카드, 시작·종료 절차, 진행 현황 표. P4~P6은 "v0.4 이후" 절에 내용만 둔다. |
  | `FINALIZE.md` | `specs/v0.3/PLAN.md` Phase 0의 F0~F5 카드, SPEC R-5·R-6·R-13·R-14. 6장 "확정 후 반영 목록"은 이번 반영으로 했다. |

- **범위:** 초안 PLAN의 P0~P3을 v0.3 Phase 0~3으로 둔다. P4·P5·P6은 v0.4 이후다(사용자 결정 2026-11-03).
- **Phase 0:** 초안 P0, FINALIZE F0~F5, 데스크톱 환경·v0.2 동작 점검을 하나의 Phase 0으로 합친다.
- **방식:** 수치 스펙 파일(D-6), 검증 수준 V0~V4(D-7), 레이아웃 테스트·덤프 도구(D-8), 하드코딩 0건 목표(D-9)를 쓴다.
- **에이전트:** 초안 HERDR.md의 역할을 쓰고 토큰 부담에 맞게 조정한다(D-10).
- **고쳐 반영한 것**
  - 데스크톱 환경: 빌드 환경 D-5, Python D-12, 화면·실측 조건(HERDR-SETUP 3.8)
  - 경로: 자리표시자(`<REPO_ROOT>`, `<ZED_MEASURE_DIR>`, `<SPEC_DOC>` 등)를 실제 경로로 바꿨다(D-11). `main`은 `master`로 바꿨다.
  - 도구: 측정 스크립트는 PowerShell(D-8)로 한다. 주석은 `shortcut:` 형식이다(ponytail 5.3.2).
- **워크스페이스 규칙과 맞지 않아 하지 않는 것**
  - 지난 PLAN·PROGRESS를 `archive/`로 옮기고 표시를 덧붙이는 보관 처리(FINALIZE 6.4): 지난 버전 폴더 불변 규칙 때문이다.
  - 루트 `AGENTS.md`를 초안으로 통째로 바꾸는 것: 기존 레포 규칙 6줄을 위에 남기고 그 아래에 초안을 넣었다.
  - FINALIZE F2의 결정 ID 새로 매기기: 지난 결정에 이미 `D-n`이 있다.

**근거**

- 사용자 지시(2026-11-03): "workbench-gpui\docs\refs\refactor-draft 의 문서의 내용이 현재 데스크탑 및 워크스페이스 에 맞게 모두 반영되어야 합니다. web 의 claude.ai 에서 사용자가 미리 검토한 내용입니다. 참고가 아니라 이 문서를 기준으로 v0.3 이 이루어져야 합니다. 1. 데이크탑 환경 적용 2. 멀티에이젼트시 토큰 부담 고려 3. 자료나 파일등 경로 맞게 수정 반영"
- 사용자 답(2026-11-03)
  - 초안 범위: "P0~P3"
  - 들여올 방식: "spec/zed-metrics.toml, 검증 수준 V0~V4, 레이아웃 테스트·덤프 도구, 하드코딩 0건 목표"
  - Phase 0: "하나의 Phase 0으로 합침"
  - P4~P6: "v0.4 이후 유지"
- 앞선 경위: 사용자가 처음에 "docs\temp 에 있는 문서는 claude.ai 에서 작업한 것으로 현재의 워크스페이스와 맞지 않습니다"라고 판단했다(2026-11-03). 그래서 `docs/temp`를 `docs/refs/refactor-draft/`로 옮겼고 `AGENTS.md`·`CLAUDE.md`는 `.draft.md`로 이름을 바꿨다. 이 판단은 원문을 그대로 쓰지 않는다는 뜻이다. 위 지시에 따라 고쳐서 기준으로 쓴다.
- 워크스페이스 규칙은 버전 문서를 `specs/{version}/`에 둔다(`D:\projects\AGENTS.md`, project-workflow-compact DOCUMENTS 2절). 지난 버전 폴더는 고치지 않는다(루트 `AGENTS.md`).

**근거**

- 사용자 판단(2026-11-03): "docs\temp 에 있는 문서는 claude.ai 에서 작업한 것으로 현재의 워크스페이스와 맞지 않습니다." 그래서 `docs/temp`를 `docs/refs/refactor-draft/`로 옮겼고, `AGENTS.md`·`CLAUDE.md`는 `.draft.md`로 이름을 바꿨다.
- 사용자 지시(2026-11-03): "refactor-draft 기반으로 specs\v0.3 스펙 문서 작업을 계속 진행하겠습니다."
- 사용자 답(2026-11-03)
  - 초안 범위: "P0~P3"
  - 들여올 방식: "spec/zed-metrics.toml, 검증 수준 V0~V4, 레이아웃 테스트·덤프 도구, 하드코딩 0건 목표"
  - Phase 0: "하나의 Phase 0으로 합침"
- 워크스페이스 규칙은 버전 문서를 `specs/{version}/`의 다섯 문서로 정한다(`D:\projects\AGENTS.md`, project-workflow-compact DOCUMENTS 2절).
- 지난 버전 폴더는 고치지 않는다(`AGENTS.md`).

**배제한 대안**

- **초안을 참고만 한다(이 문서의 이전 초안)** — 사용자 지시로 배제했다. 사용자가 검토한 HERDR 운영, FINALIZE 단계, AGENTS 지침이 빠진다.
- **초안을 고치지 않고 그대로 쓴다** — 자리표시자 경로, 노트북 기준일, 없는 Python, 지난 버전 폴더 보관 처리가 그대로 남는다. 데스크톱·워크스페이스에서 그대로 실행할 수 없다.
- **초안 P0~P5를 모두 넣는다** — P4·P5는 화면을 Zed 실측에 맞추려고 값을 바꾸는 수정이다. v0.3의 "동작 불변" 목적과 부딪힌다(사용자가 P0~P3을 고름).

---

## D-3. 리팩토링 항목은 ponytail-audit 감사 결과에서 사용자가 채택한 것만 고친다

**선택**

- 저장소 전체를 ponytail-audit로 감사한다. 결과 가운데 사용자가 채택한 항목만 리팩토링한다.
- 채택하지 않은 항목은 손대지 않는다.
- 감사 결과는 `specs/v0.3/AUDIT.md`에 쓴다(`refactor-draft/HERDR-SETUP.md` 변경안 4절의 위치).
- 결과는 초안 PLAN P0-2의 분류로 나눈다: 하드코딩 수치·색상, 반복 스타일 체인, 중복 컴포넌트, 미사용 의존성, 기타.
- 사용자가 채택한 항목은 AUDIT.md의 각 항목에 "채택/보류"로 표시한다.
- 감사는 `reviewer`(Codex, `@ponytail-audit`)가 한다(초안 PLAN P0-2, D-10). 채택·보류안은 `lead`가 만든다.

**근거**

- 사용자 말(2026-11-03, `docs/refs/refactor-draft/HERDR-SETUP.md` 1절 인용): "제일 먼저 github.com/nampluskr/workbench-gpui 에 대한 poytail 기반 리팩토링을 해야 합니다."
- `specs/v0.3/INTENT.md` 범위: 사람이 채택한 항목만 고친다.

**배제한 대안**

- **에이전트가 판단한 항목을 바로 고친다** — 요구·결정은 사람이 정한다(`AGENTS.md`).
- **감사 없이 큰 파일부터 나눈다** — 근거 없이 diff만 커진다. 무엇을 지우고 합칠지 모르는 채로 옮기게 된다.

---

## D-4. herdr 멀티 에이전트 구성(역할·모델·effort)은 구독 현황과 구독별 토큰 부담으로 정한다

**선택**

- v0.3 작업에 쓸 herdr 구성을 정하기 전에 다음 구독 현황을 사람에게 확인한다.
  - 구독 종류
  - 남은 한도와 초기화 시점
  - 동시에 도는 다른 워크스페이스
- 확인한 현황으로 구독별 토큰 부담을 따져 역할·모델·effort를 정한다.
- 근거와 부담은 `specs/v0.3/HERDR-SETUP.md`의 근거(0장)·토큰 부담(1.3) 절에 적는다(D-11). 한도가 바뀌어 구성을 바꾸면 다시 승인받는다.
- v0.3 구성은 D-10이다.

**근거**

- 사용자 지시(2026-11-03): "구독현황 및 토큰 부담에 따라 HERDR 멀티에이젼트를 정해야 함을 지침문서에 반영해 주세요." 이 지시로 `AGENTS.md`에 같은 규칙을 넣었다.
- 확인된 구독(2026-11-03, `docs/refs/refactor-draft/HERDR-SETUP.md` 1절)은 Claude Max, Codex Plus, Gemini Pro(agy)다. agy Gemini 4 Argon은 주간 한도를 다 쓴 상태다.

**배제한 대안**

- **역할만 보고 모델을 정한다** — 한 구독(Claude Max)에 부담이 몰리면 작업 중간에 한도로 멈춘다.

---

## D-5. Phase 0 점검은 데스크톱에 노트북과 같은 빌드 환경(Rust 1.99.1·Build Tools 2022·Windows SDK 10.0.26100.0)을 갖추고 LongPathsEnabled 0으로 하며, 그 결과를 v0.3 기준선으로 쓴다

**선택**

- **빌드 환경:** 노트북에서 v0.1·v0.2를 만든 환경과 같은 버전으로 맞춘다.

  | 항목 | 노트북 (기록) | 데스크톱에서 할 일 |
  | --- | --- | --- |
  | Rust | rustc 1.99.1 | rustup으로 1.99.1(clippy 포함)을 설치하고 기본 툴체인으로 고정 |
  | MSVC | Visual Studio Build Tools 2022 | Build Tools 2022 **최신 버전**(C++ 빌드 도구)을 설치하고, 지금 있는 **Build Tools 2026은 삭제**한다 |
  | Windows SDK | 10.0.26100.0 | 이미 설치되어 있음. 빌드가 이 버전을 쓰는지 확인 |

  - 레포에는 `rust-toolchain.toml`을 두지 않는다.
  - Build Tools 2022의 세부 버전은 노트북 기록에 없다. 그래서 설치 시점의 2022 최신 버전으로 하고, 설치된 버전과 MSVC 도구 집합(14.xx) 버전을 PROGRESS에 기록한다.
  - 2026을 지워 빌드가 항상 2022를 쓰게 한다. 2026 삭제와 2022 설치는 시스템 변경이므로 PLAN 카드 P0-0a에서 사용자 승인 뒤에 한다.
- **LongPathsEnabled:** 0으로 그대로 둔다. 시스템 설정을 바꾸지 않는다.
- **점검 범위:** 빌드·테스트·실행, 그리고 v0.2 검증 스크립트 전체다(`PLAN.md` Phase 0 완료 조건의 목록).
- **기준선:** 리팩토링 전 코드를 이 데스크톱(100% 배율, 1920x1080 모니터 2대)에서 돌린 결과로 한다. 결과는 `specs/v0.3/verify/baseline/`에 둔다.

**근거**

- 사용자 답(2026-11-03)
  - "rustup + 1.99.1 고정"
  - "빌드·테스트·실행 + v0.2 검증 스크립트 전체"
  - "그대로 0"
- 사용자 지시(2026-11-03): "노트북과 같은 버젼으로 설치해야 될 것 같습니다. 노트북과 같은 rust 환경을 구축하는 것으로 문서에 반영해 주세요."
- 사용자 답(2026-11-03, MSVC 버전과 공존): "2022 최신 + 2026 삭제"
- 데스크톱 점검(2026-11-03)
  - Visual Studio IDE는 설치되어 있지 않다(`winget list`, `vswhere`, 레지스트리, `devenv.exe` 확인).
  - Build Tools 2026(18.6.2, MSVC 14.44·14.51)만 있다.
  - Windows SDK는 10.0.22621, 26100, 28000이 있다.
- 노트북 기록
  - rustc 1.99.1, Build Tools 2022, Windows SDK 10.0.26100.0: 루트 `README.md` "빌드와 실행"
  - 200%(DPI 192) 화면 하나: `specs/v0.1/PROGRESS.md` 25행
  - LongPathsEnabled=0: 같은 문서 98행
  - 테스트 49개 통과: `specs/v0.2/PROGRESS.md` Phase 5
- `rust-toolchain.toml`을 두지 않는 이유: 최소 Rust 버전(G-121)은 이 결정(1.99.1 고정)으로 닫았다(F5, 2026-11-03). 노트북과 데스크톱이 같은 버전을 쓰므로 파일로 고정하지 않는다.
- 리팩토링 뒤 결과와 대조하려면 같은 PC에서 만든 기준선이 있어야 한다. 노트북 결과는 배율·모니터 수·D: 종류가 달라 직접 대조할 수 없다.

**배제한 대안**

- **최신 stable 설치** — 새 경고나 실패가 나오면 툴체인 탓인지 코드 탓인지 따로 가려내야 한다.
- **지금 있는 Build Tools 2026으로 빌드** — MSVC·링커 버전이 노트북과 달라진다. 차이가 나면 원인을 가려내기 어렵다(사용자 지시로 배제).
- **2026을 두고 "Developer PowerShell for VS 2022"에서 빌드** — 시스템을 덜 바꾸지만, 패널·에이전트마다 환경을 맞춰야 하고 잘못된 환경에서 빌드될 수 있다(사용자가 2026 삭제를 고름).
- **노트북에서 세부 버전을 확인한 뒤 같은 버전 설치** — 사용자가 2022 최신을 고름.
- **LongPathsEnabled 켜기** — 노트북과 조건이 달라진다. 관리자 권한도 필요하다.
- **빌드·테스트·실행만 점검** — 검증 스크립트가 보던 GUI 동작의 회귀를 잡지 못한다.
- **노트북 결과(`specs/v0.2/verify/`)를 기준선으로 쓰기** — 배율·모니터·드라이브 조건이 달라 픽셀·동작 값을 그대로 대조할 수 없다.

---

## D-6. Zed 실측 수치는 `spec/zed-metrics.toml` 한 곳을 기준으로 하고, 원문은 `docs/refs/01-zed/`다

**선택**

- 01-zed 실측 문서(01-LAYOUT·02-INTERACTION·03-THEME-ICONS·04-APP-SPEC)의 수치를 `spec/zed-metrics.toml`로 옮긴다.
- 옮기는 형식은 초안 FINALIZE 3.1을 따른다.
  - 항목마다 `value`·`unit`·`cond`(측정 조건)·`src`(원문 파일과 절)를 적는다.
  - 섹션은 화면 영역 단위로 나눈다(titlebar, sidebar, dock, tab, pane, statusbar, tooltip, menu, scrollbar 등).
  - 측정 조건은 `[conditions.<이름>]`으로 둔다.
- 항목 ID(섹션 경로와 키)는 한 번 정하면 바꾸지 않는다.
- 다음 경우에는 toml에 넣지 않는다. `spec/ambiguous.md`에 원문 위치와 함께 적는다.
  - 원문끼리 값이 다르다.
  - 값·단위·조건 가운데 하나라도 불분명하다.
- 추정해서 값을 채우지 않는다.
- 원문의 수치가 아닌 내용(상호작용, 상태 전이 같은 동작 규칙)은 옮기지 않는다. `spec/INDEX.md`에 절 위치만 적는다.
- 기존 01-zed 항목 ID(L-n, A-n.n 등)는 `src`에 함께 적는다. `src/ui/metrics.rs`의 상수 주석이 이미 이 ID를 쓰고 있어서, 두 체계를 이어 주기 위해서다.

**근거**

- 사용자가 고른 방식(2026-11-03): "spec/zed-metrics.toml"
- 초안 FINALIZE 1절 "기준은 하나만 둔다", 3.1 toml 형식, 4절 F1
- `src/ui/metrics.rs` 머리 주석: "값은 01-zed 01-LAYOUT·04-APP-SPEC 의 항목 ID 원문 값이다(논리 px, rem 16 기준)."

**배제한 대안**

- **01-zed 마크다운을 그대로 기준으로 쓴다** — 네 문서가 합쳐 약 700KB다. 테스트가 기대값을 기계적으로 찾을 수 없다.
- **`src/ui/metrics.rs`를 유일한 기준으로 쓴다** — 측정 조건과 원문 위치를 담을 자리가 없다. 코드에 아직 없는 수치는 기록할 곳이 없다.

---

## D-7. 작업마다 검증 수준 V0~V4 가운데 하나를 정하고, 그 수준만큼만 검증한다

**선택**

- 초안 `AGENTS.draft.md` 3A.1의 다섯 수준을 쓴다.

  | 수준 | 대상 | 수행 |
  | --- | --- | --- |
  | V0 정적 | 이름 바꾸기, 파일 이동, 같은 값의 상수·테마 치환, 동작이 바뀌지 않는 리팩토링, 주석·문서 | `cargo build`, `cargo clippy` |
  | V1 단위 | 분기·계산·상태·키 처리·이벤트 핸들러를 건드리는 변경 | V0 + 관련 테스트만 |
  | V2 레이아웃 | 크기·간격·배치를 건드릴 수 있는 변경 | V1 + 해당 스펙 ID의 레이아웃 테스트 |
  | V3 UI 실측 | 아래 시점 | 앱을 띄워 화면을 측정하고 스펙·기준선과 대조 |
  | V4 사용자 확인 | 측정으로 판단할 수 없는 시각 품질 | Phase 끝에 모아서 사용자가 확인 |

- 기본은 V0이고, 근거 없이 올리지 않는다.
- V3는 Phase 끝에 그 Phase에서 바뀐 화면을 한 번에 측정한다. 레이아웃 테스트로 잡을 수 없는 항목이 쌓였을 때도 한다. 절차는 초안 3A.4를 따른다.
  - 측정 목록을 먼저 만든다.
  - 측정 조건을 고정한다.
  - 앱은 한 번만 실행한다.
  - 도구로 측정한다.
  - 기록을 남긴다.
  - 측정한 사람은 고치지 않는다.
  - 다시 측정할 때는 불일치 항목만 측정한다.
- 작업 기록(PROGRESS)에 항목마다 검증 수준을 적는다.
- Phase 끝의 v0.2 검증 스크립트 재실행(동작 불변 대조)은 수준과 관계없이 항상 한다(SPEC R-12).

**근거**

- 사용자가 고른 방식(2026-11-03): "검증 수준 V0~V4"
- 초안 `AGENTS.draft.md` 3A "검증은 변경 유형에 맞는 최소 수준만 수행한다", 3A.3 V3 필요 조건, 3A.4 절차

**배제한 대안**

- **모든 변경에 앱 실행 검증을 한다(v0.1·v0.2 방식)** — 리팩토링은 항목 수가 많다. 항목마다 GUI 검증 스크립트를 돌리면 시간이 너무 든다. 동작 불변은 Phase 끝 전체 재실행으로 확인한다.

---

## D-8. 레이아웃 검증은 스펙 ID로 기대값을 찾는 테스트와, 기존 `--dev-layout` 탐침을 넓힌 덤프로 한다

**선택**

- **레이아웃 테스트:** 테스트가 `spec/zed-metrics.toml`의 항목 ID로 기대값을 읽어 대조한다. 대조 대상은 코드 상수(`src/ui/metrics.rs`)와 레이아웃 덤프 값이다.
- **레이아웃 덤프:** 새로 만들지 않는다. 기존 `src/ui/layout_probe.rs`와 디버그 플래그 `--dev-layout`(`src/dev.rs`)을 쓴다. 출력 형식(JSON)과 측정 대상 요소가 모자라면 그 부분만 넓힌다.
- **UI 실측 도구:** 초안의 위치 `tools/measure/`에 두되 PowerShell 7로 쓴다. 기존 `tools/capture.ps1`(창 사각형·DPI·PNG 캡처)을 재사용하고, 덤프 JSON과 스펙을 대조하는 부분만 더한다. Python이 꼭 필요한 부분만 WinPython을 쓴다(D-12).
- toml을 읽는 크레이트를 의존성에 더할지, 더한다면 어떤 범위(개발용)로 할지는 미결이다(D-1: 의존 변경은 사용자 승인).

**근거**

- 사용자가 고른 방식(2026-11-03): "레이아웃 테스트·덤프 도구"
- 사용자 답(2026-11-03, 측정 도구): "PowerShell 재사용"
  - 질문 당시 데스크톱 PATH에는 Python이 없었다(WindowsApps 스텁).
  - 그 뒤 사용자가 WinPython 경로를 알려 주었다(D-12). 그래도 측정 도구는 PowerShell로 둔다.
- 초안 PLAN P1-2~P1-5
- 저장소 확인(2026-11-03)
  - `src/ui/layout_probe.rs`는 v0.1 Phase 3부터 이름별 레이아웃 경계를 모으는 탐침이고, `--dev-layout`으로 켠다.
  - `tools/capture.ps1`은 v0.1 Phase 1부터 쓴 캡처 스크립트다.
- 초안 `AGENTS.draft.md` 4.1 "이 저장소에 이미 있는가"(재사용 우선)

**배제한 대안**

- **초안대로 Python 측정 스크립트(`tools/measure/`)를 새로 만든다** — 사용자가 PowerShell 재사용을 골랐다. 같은 일을 하는 PowerShell 도구가 이미 있고, Python으로 쓰면 도구가 두 언어로 갈린다.
- **레이아웃 덤프를 새로 구현한다** — `layout_probe`가 이미 경계를 모은다.

---

## D-9. 코드 안의 하드코딩 수치·색상을 감사 기준 0건으로 만들되, 값은 바꾸지 않는다

**선택**

- 코드에 직접 적힌 레이아웃 수치(`px(…)`, `rems_from_px(…)` 등)는 스펙 ID 이름의 상수로 옮긴다. 상수 모듈은 `src/ui/metrics.rs`다.
- 색상 리터럴은 테마를 거쳐 쓰도록 옮긴다.
  - 테마 매핑과 선택기, 내장 테마 번들은 PoC 7단계라 v0.4 이후다. 여기서는 리터럴을 한 곳으로 모으는 데까지만 한다.
  - 지금 코드는 대부분 gpui-kit 테마(`cx.theme()`)를 쓴다.
- 같은 값이라도 스펙 ID가 다르면 별개 상수로 둔다.
- **값을 바꾸지 않는다.**
  - 코드 값과 `spec/zed-metrics.toml` 값이 다르면 코드 값을 그대로 둔다.
  - 그 불일치는 PROGRESS의 불일치 목록에 적어 v0.4 이후(초안 P4·P5에 해당)로 넘긴다.
- 스펙에 없는 수치(예: 클릭 판정 여유, 내부 계산용 상수)를 어떻게 다룰지는 미결이다.
- 판정은 감사 결과(Phase 0 AUDIT)의 "하드코딩 수치·색상" 분류가 0건이 되는 것으로 한다. 수를 셀 범위와 방법은 SPEC R-10에 둔다.

**근거**

- 사용자가 고른 방식(2026-11-03): "하드코딩 0건 목표"
- 초안 PLAN P2, 초안 `AGENTS.draft.md` 3절 "같은 값이라도 스펙 ID가 다르면 별개 상수로 유지"
- 값을 바꾸지 않는 이유: v0.3은 동작 불변이고, 값을 Zed에 맞추는 수정(P4·P5)은 v0.4 이후다(`INTENT.md`, 사용자 결정 2026-11-03).
- 저장소 확인(2026-11-03)
  - `metrics.rs` 밖에서 `px(숫자)`·`rems_from_px(숫자)`·색상 리터럴이 쓰인 곳이 9개 파일, 65곳이다(`app_menu.rs` 14, `tooltip.rs` 21, `panel_view.rs` 14, `folders.rs` 8 등).
  - 이 수는 정규식으로 센 것이라 감사 결과로 확정해야 한다.

**배제한 대안**

- **초안 P2대로 값이 다르면 스펙 값으로 바꾼다(V2 검증)** — 화면이 바뀐다. 동작 불변과 부딪힌다.
- **수치만 옮기고 색상은 테마 작업(v0.4 이후) 때 옮긴다** — 사용자가 "하드코딩 0건"을 목표로 골랐다.

---

## D-10. v0.3 에이전트 구성은 초안 HERDR.md의 다섯 역할을 쓰고, 토큰 부담에 맞게 impl-editor는 필요할 때만, reviewer는 묶음 리뷰로 운용한다

**선택**

| 역할 | 도구 · 모델 · effort | 운용 |
| --- | --- | --- |
| `lead` | Claude Code · Opus 5.5 · high | 상시. 코드를 쓰지 않는다. |
| `spec` | agy · gemini-3.8-flash | 상시. ponytail은 끈다. 원문은 문서 하나씩 처리한다. |
| `reviewer` | Codex · gpt-6.1-sol · medium (에디터 로직 high) | 상시. 카드를 묶어 리뷰한다. V3는 Phase 끝과 화면 단위로만 한다. |
| `impl-ui` | agy · Claude Sonnet 5.5 (thinking) | 상시. worktree `work/ui`. Phase 2·3의 주 구현자다. |
| `impl-editor` | Claude Code · Opus 5.5 · medium | **필요할 때만.** 에디터 코어 카드가 생기면 worktree `work/editor`와 함께 띄운다. |

- 대체 모델(한도 소진 시)
  - `impl-ui`: Claude Code Sonnet 5.5 medium
  - `spec`: Claude Code Haiku 5.5 medium
  - `reviewer`: agy gemini-3.8-flash
  - 바꿀 때는 재승인을 받는다.
  - Argon은 쓰지 않는다.
- 리뷰 독립성: 병합 전 리뷰는 Codex `reviewer`만 한다. Claude 계열끼리의 교차 리뷰는 독립 검증으로 인정하지 않는다(초안 HERDR.md 1.2).
- 상세 운영은 `specs/v0.3/HERDR-SETUP.md`가 담는다.

**근거**

- 사용자 답(2026-11-03, 에이전트 구성): "HERDR.md + 부담 조정"
- 사용자 답(2026-11-03, agy 한도): Claude Sonnet과 Flash "둘 다 충분" → `spec`·`impl-ui`를 계획대로 agy에 둔다.
- 사용자 답(2026-11-03, v0.2 검증 스크립트 기준선 P0-0c): "reviewer 전부" → 실행과 차이 분류를 모두 `reviewer`가 한다. Codex Plus 부담은 P0-0c를 한 번에 몰아서 하는 것으로 줄인다.
- 구독(2026-11-03): Claude Max, Codex Plus, Gemini Pro(agy). Argon은 소진 상태다(`docs/refs/refactor-draft/HERDR-SETUP.md` 1절).
- D-4: 구성은 구독과 토큰 부담으로 정한다.
- 부담 판단
  - Codex Plus가 셋 가운데 한도가 가장 작다. 초안 HERDR.md는 `reviewer`에게 빌드·감사·리뷰·V3 실측을 모두 맡긴다. 그래서 묶음 리뷰와 Phase 끝 V3로 호출 횟수를 줄인다.
  - v0.3 범위(P0~P3)에서 에디터 코어는 `src/ui/editor_poc.rs` 하나다(저장소 확인 2026-11-03). `impl-editor`를 상시 띄우면 Claude 한도를 쓰면서 일이 거의 없다.
- 확인한 사실(2026-11-03)
  - herdr 0.9.5와 연동(claude·codex·antigravity-cli)이 설치되어 있다.
  - 동시에 도는 다른 herdr 워크스페이스는 없다.
  - RAM 32GB, 논리 CPU 12개라 worktree 빌드를 감당한다.

**배제한 대안**

- **초안 HERDR.md 그대로(다섯 역할 상시, worktree 2개)** — `impl-editor`가 거의 놀면서 Claude 한도를 쓴다. `reviewer` 호출이 카드마다 생겨 Codex Plus 한도에 먼저 걸린다.
- **`refactor-draft/HERDR-SETUP.md` v0.3 변경안(wg-* 여섯 역할, coder 한 명)** — 사용자가 HERDR.md 기준을 골랐다. 그 문서의 구독·토큰 표, runner 운용, 대리 응답 범위는 `specs/v0.3/HERDR-SETUP.md`에 합쳤다.

---

## D-11. HERDR 문서와 에이전트 운영 문서는 버전별로 `specs/{version}/` 아래에 두고, 초안 경로는 이 배치로 바꾼다

**선택**

| 초안 경로 | v0.3 경로 |
| --- | --- |
| `HERDR.md` (+ `HERDR-SETUP.md`) | `specs/v0.3/HERDR-SETUP.md` |
| (대리 응답 기록) | `specs/v0.3/HERDR-DECISIONS.md` |
| `PLAN.md` (루트) | `specs/v0.3/PLAN.md` |
| `docs/agents/TASKS.md`, `HANDOFF.md` | `specs/v0.3/agents/TASKS.md`, `HANDOFF.md` |
| `docs/agents/reviews/` | `specs/v0.3/verify/reviews/` |
| `docs/agents/finalize/` | `specs/v0.3/verify/finalize/` |
| `<ZED_MEASURE_DIR>` | `docs/refs/01-zed/` (기준 PNG `docs/refs/assets/`) |
| `<SPEC_DOC>` 등 입력 문서 | 루트 `INTENT.md`, `specs/v0.1·v0.2/*.md`(읽기만), `specs/v0.3/*.md` |
| `<REPO_ROOT>` | `D:\projects\workbench-gpui` |
| `<EDITOR_CORE_PATHS>`, `<UI_SHELL_PATHS>` | 후보만 둔다(`HERDR-SETUP.md` 4장). P0-5에서 사용자가 확정한다. |
| `spec/zed-metrics.toml`, `spec/INDEX.md`, `spec/ambiguous.md` | 그대로 |
| `tools/measure/` | 그대로(PowerShell, D-8) |
| `main` 브랜치 | `master` |

- v0.1·v0.2의 `docs/HERDR-SETUP.md`·`docs/HERDR-DECISIONS.md`는 옮기지 않고 기록으로 둔다.
- 루트 `AGENTS.md`의 "HERDR 문서" 규칙을 "`specs/{version}/HERDR-*.md`는 버전마다 따로 두고 lead만 고친다"로 바꿨다.

**근거**

- 사용자 지시(2026-11-03): "HERDR-XXX.md 파일은 sepcs\{version} 에 따로 따로 보관하는 것이 좋을 것 같습니다. 즉, 버젼별로 HERDR 환경이 바뀔수 있습니다."
- 사용자 지시(2026-11-03): "3. 자료나 파일등 경로 맞게 수정 반영"
- v0.1·v0.2는 검증 증거를 `specs/<버전>/verify/`에 두었다. 운영 기록(작업 보드, 리뷰)도 버전에 묶여 있어 같은 규칙을 쓴다.
- 지난 버전 폴더는 고치지 않으므로, 기존 `docs/HERDR-*.md`를 `specs/v0.2/`로 옮기지 않는다(루트 `AGENTS.md`).

**배제한 대안**

- **초안 경로 그대로(루트 `HERDR.md`·`PLAN.md`, `docs/agents/`)** — 버전마다 바뀌는 운영 문서가 버전 밖에 놓인다. 사용자 지시와 어긋난다.
- **기존 `docs/HERDR-*.md`를 `specs/v0.2/`로 옮긴다** — 지난 버전 폴더를 고치게 된다.

---

## D-12. Python이 필요하면 WinPython `C:\winpython\`의 `_cpu`(기본)·`_gpu` 인터프리터를 전체 경로로 쓴다

**선택**

- 기본 인터프리터는 `C:\winpython\WPy64-31180_cpu\python-3.11.8.amd64\python.exe`(Python 3.11.8)다.
- GPU가 필요한 작업에는 `C:\winpython\WPy64-31180_gpu\python-3.11.8.amd64\python.exe`를 쓴다.
- 항상 전체 경로로 부른다. 시스템 PATH의 `python`은 WindowsApps 스텁이라 쓰지 않는다.
- 측정·검증 스크립트의 기본 언어는 PowerShell이다(D-8). Python은 꼭 필요한 경우에만 쓴다. 쓸 때는 초안 규칙을 따른다: 경로는 `os.path`, 주석은 영어.
- 반영 위치: 루트 `AGENTS.md` 2장, `specs/v0.3/HERDR-SETUP.md` 3.7, `README.md` "빌드와 실행"

**근거**

- 사용자 지시(2026-11-03): "파이썬은 c:\winpython\ 에 _cpu, _gpu 환경을 사용하면 됩니다. 파이썬이 필요한 경우 이 경로의 인터프리터를 사용합니다. 필요한 문서에도 반영해 주세요."
- 데스크톱 확인(2026-11-03): 두 폴더에 `python-3.11.8.amd64\python.exe`가 있다. PATH의 `python`은 버전 대신 "Python"만 내는 스텁이다.
- 초안 PLAN P1 주의 "측정 스크립트는 Python으로 작성하고 경로는 `os.path`를 사용한다. 주석은 영어로 작성한다."

**배제한 대안**

- **Python을 새로 설치해 PATH에 둔다** — 사용자가 쓸 인터프리터를 정해 주었다.
- **`python` 명령을 그대로 쓴다** — WindowsApps 스텁이 잡혀 실행되지 않는다.

---

## 미결 사항

v0.3에서 정할 것:

- **Phase 2·3에 넣지 않는 감사 항목을 어떻게 할지** — 감사에서 죽은 코드 삭제, 큰 파일 분할, `dev.rs` 검증 하네스 분리 같은 항목이 나올 수 있다. 이런 항목은 초안 P2·P3(하드코딩·중복) 분류에 들어가지 않는다. 채택하면 어느 Phase에 넣을지 정한다.
- **동작 불변 대조의 허용 범위** — 기준선은 D-5로 정했다. 반영 시간처럼 실행마다 흔들리는 값의 허용 범위가 남아 있다. 후보: Phase 0에서 기준선을 두 번 돌려 정한다(`refactor-draft/HERDR-SETUP.md` 4절 checker 운영 규칙). `SPEC.md` R-12는 이 값을 "미정"으로 둔다.
- **toml 읽기 크레이트를 의존성에 더할지** — `toml`은 지금 `Cargo.lock`에 간접 의존으로만 있다. 개발용(dev-dependencies)으로만 더할지 사용자가 승인한다(D-1, D-8).
- **스펙에 없는 수치를 어떻게 다룰지** — 클릭 판정 여유, 내부 계산용 상수 같은 것이다. 하드코딩 집계에서 뺄지, 스펙 파일에 "앱 자체 값" 섹션으로 둘지 정한다(D-9).
- **`spec/` 폴더 이름** — 초안의 이름을 그대로 쓴다. 버전 문서 폴더 `specs/`와 이름이 비슷하다는 점은 남는다.
- **노트북(200%) 결과와 데스크톱(100%) 기준선이 다른 점을 어떻게 다룰지** — Phase 0의 차이 분류를 보고 정한다.
- **에디터 코어·UI 셸 담당 경로 확정** — 후보는 `HERDR-SETUP.md` 4장에 있다. P0-5에서 사용자가 확정한다(R-15).
- **agy `impl-ui`의 ponytail 적용 방식** — agy에는 플러그인이 없어 루트 `AGENTS.md` 4장의 규칙으로 따르게 했다(초안 HERDR.md 3.3). 플러그인 설치가 가능한지와 필요한지는 확인하지 않았다.
- **줄일 코드 양 같은 수치 목표를 둘지.**
- **동작이 바뀌는 수정(감사의 버그·위험 항목)을 이번 버전에 넣을지** — `HERDR-SETUP.md` 6.5는 따로 표시해 사용자에게 올리고, 승인되면 별도 커밋으로 나누게 한다. 넣을지 자체는 미정이다.
- **v0.2 "남은 것"의 알려진 한계·판정 불가 항목을 넣을지** — `specs/v0.2/PROGRESS.md` "버전 종료" 1·2.

지난 버전에서 이어지는 미결(이번 버전에서 다룰지 미정, `specs/v0.2/DECISIONS.md` 미결 사항):

- 사이드바 폭 조절 핸들(A-11.12)
- 폴더 경로 비교 키의 케이스 폴딩(A-28.5)
- Zed 글꼴(.ZedSans/.ZedMono) 자산 도입
- 닫기 외 창 버튼 hover·누름 색
- ~~글리프 글꼴 선택 기준~~ — F5(2026-11-03, F4 Q-13)에서 지금 방식(`Segoe Fluent Icons` 설치 여부)으로 닫았다.
- ~~G-121 Rust 최소 버전 기준~~ — F5(2026-11-03, F4 V-7)에서 D-5(1.99.1 고정)로 닫았다.

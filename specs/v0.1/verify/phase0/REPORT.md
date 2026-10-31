# Phase 0 완료 조건 검증 보고서

- 검증 일시: 2026-10-31
- 검증자: wg-checker
- 대상: `specs/v0.1/PLAN.md` `## Phase 0 — 프로젝트 뼈대` 완료 조건

## 조건별 판정

| 조건 | 통과·실패 | 증거 |
| --- | --- | --- |
| 레포 루트에 cargo 프로젝트(`Cargo.toml`)가 있다. | 통과 | 레포 루트 `Cargo.toml` 존재 확인 (`name = "workbench-gpui"`, `version = "0.1.0"`, `edition = "2024"`). `git diff --cached --name-only`에 `Cargo.toml`, `src/main.rs`, `src/ui/mod.rs` 포함. |
| `Cargo.toml`의 의존성에 `gpui-kit = "=0.8.1"`이 있고, `gpui`·`gpui-pre`를 직접 넣은 줄이 없다(D-3). | 통과 | `Cargo.toml` 6~7행 `[dependencies]` 아래 `gpui-kit = "=0.8.1"` 한 줄만 존재하며, `gpui`·`gpui-pre` 직접 의존 줄 없음. |
| `Cargo.lock`이 커밋되어 있다(D-4). | 통과 | 레포 루트에 `Cargo.lock` 파일이 존재하며, `git diff --cached --name-only` 결과에 `Cargo.lock`이 스테이지되어 있음(Phase 0 커밋 대기 상태). |
| G-121 빌드 준비물(MSVC, Windows SDK, CMake)의 설치 여부와 Rust 버전이 PROGRESS에 기록되어 있다. Rust 버전이 1.90(crates.io `rust_version`)과 1.92(설치 문서) 둘 다 이상인지 적혀 있다. | 통과 | `specs/v0.1/PROGRESS.md` 11~15행(`빌드 준비물 확인 (G-121)`)에 `rustc 1.99.1`, `cargo 1.99.1`(1.90과 1.92 둘 다 이상임 명시), Visual Studio Build Tools 2022(MSVC), Windows SDK `10.0.26100.0`, Build Tools 내장 CMake(`cmake.exe`, PATH 미등록) 설치 여부가 모두 기록됨. |
| `cargo build`가 성공하고, 실행하면 창이 뜬다. 빌드 출력과 실행 스크린샷이 증거로 남아 있다. | 통과 | `specs/v0.1/PROGRESS.md` 20행에 `cargo build` 성공 출력 요약(`dev profile, 4m 26s, exit 0`)과 23~27행에 실행 결과(`2880×1704 물리 px, DPI 192(200%)`) 기록됨. `specs/v0.1/verify/phase0/empty-window.png` 이미지를 직접 확인한 결과 상단 OS 기본 타이틀 바와 흰색 클라이언트 영역을 가진 앱 창이 화면에 떠 있음이 확인됨. |
| 위의 Phase 끝 순서(리뷰 → 검증 → PROGRESS → 커밋)를 마쳤다. | 진행 중 | 현재 검증 단계 진행 중(검증 완료 후 PROGRESS 기록 및 커밋 예정). |

## 실패 목록

- 없음 (통과 5건, 진행 중 1건, 실패 0건)

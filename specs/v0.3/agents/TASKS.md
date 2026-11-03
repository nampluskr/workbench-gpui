# TASKS — workbench-gpui v0.3 작업 보드

> 소유: `lead`. 형식은 `specs/v0.3/HERDR-SETUP.md` 5.1, 카드 원본은 `specs/v0.3/PLAN.md` 각 Phase 절이다.
> 검증 수준은 루트 `AGENTS.md` 3A.1. 기본값 V0, "-"는 코드를 바꾸지 않는 카드다.
> Phase 0 동안 `src/`는 아무도 수정하지 않는다.

## Phase 0 — 기준선

순서: P0-0a → P0-0b → P0-0c. F0 → (F1 ∥ F2) → F3(F1 뒤) → F4 → F5 → P0-6. P0-2·P0-4는 P0-0a 뒤 F 단계와 병렬.
F1·F2는 P0-0a와 상관없이 먼저 시작할 수 있다.

### P0-0a 데스크톱 빌드 환경 설치
- 상태: done
- 담당: 사용자·lead
- 브랜치: -
- 요구·결정: R-1, D-5
- 스펙 ID: -
- 범위: 시스템(rustup + Rust 1.99.1·clippy, Build Tools 2022 최신 C++ 도구 설치, Build Tools 2026 삭제). 저장소 파일 변경 없음.
- 검증 수준: -
- 완료 조건: `rustc --version` 1.99.1, `cargo clippy --version`, Build Tools 2022 버전·MSVC 버전, 2026 삭제 확인을 PROGRESS 환경 표에 기록
- 비고: 시스템 변경이라 사용자 승인 뒤 사용자와 함께 한다. 빌드가 필요한 P0-0b·P0-0c·P0-2·P0-4의 선행.

### P0-0b master 기준선 (= P0-1)
- 상태: done
- 담당: reviewer
- 브랜치: master
- 요구·결정: R-2, D-5
- 스펙 ID: -
- 범위: `cargo build`·`cargo test`·`cargo clippy --all-targets`·`tools/apply-manifest.ps1`·`cargo run`(1회 기동 확인). src 변경 없음.
- 검증 수준: V0
- 완료 조건: `specs/v0.3/verify/reviews/baseline-<date>.md`에 노트북 기록(빌드 경고 0, 테스트 49개, 세 항목 true)과의 대조. clippy 경고가 많으면 `-D warnings` 없이 기록만.
- 비고: 선행 P0-0a.

### P0-0c v0.2 검증 스크립트 기준선
- 상태: done (phase3 폭 2건·휴지통 판정 불가는 F5 결정 Q-15·Q-16)
- 담당: reviewer
- 브랜치: master
- 요구·결정: R-3, D-10
- 스펙 ID: -
- 범위: `tools/verify-v02-phase1~5`, `phase4-d043`·`phase4-d043-clip`·`phase4-d044`, `phase5-d046`·`phase5-d047`. `phase3-guard` 제외. 항상 `-OutDir specs\v0.3\verify\baseline\<스크립트>\`.
- 검증 수준: V3
- 완료 조건: 노트북 결과와의 차이를 원인별로 분류, 휴지통 항목(A-14.3·A-14.5) 판정 가능 여부 기록
- 비고: 선행 P0-0b. 실행 중 사용자는 마우스·키보드를 쓰지 않는다(HERDR-SETUP 3.8). Codex 부담이 커서 한 번에 몰아서 한다.

### F0 입력 문서 확정
- 상태: done
- 담당: lead
- 브랜치: -
- 요구·결정: R-5
- 스펙 ID: -
- 범위: 문서 확인만
- 검증 수준: -
- 완료 조건: 아래 결과와 이 Phase 0 카드 목록에 사용자 승인
- 비고: 결과

  | 문서 | 줄 | 바이트 | 화면 영역(최상위 절) |
  | --- | --- | --- | --- |
  | `docs/refs/01-zed/01-LAYOUT.md` | 781 | 174,960 | 기준 화면, 단위 체계, 전체 배치, 영역별 치수(4절, 대부분), 마크다운 미리보기, 측정 대조, 설정 기본값 |
  | `docs/refs/01-zed/02-INTERACTION.md` | 1,637 | 313,024 | 키맵, 탭, 미리보기, 프로젝트 패널 조작, 포커스, 상태 복원, 툴팁, ☰·∨·우클릭 메뉴, 편집기, Picker·대화상자, 키맵 편집, 확장 관리 |
  | `docs/refs/01-zed/03-THEME-ICONS.md` | 782 | 90,714 | 테마 토큰, 기본·Catppuccin 값, UI 아이콘, 파일 아이콘, 글꼴, 테마 선택 |
  | `docs/refs/01-zed/04-APP-SPEC.md` | 1,120 | 140,008 | 요건·항목 ID, 멀티 폴더 사이드바, 데이터 모델·설정 파일, 설정 기본값, 일치도 판정 기준 |
  | 합계 | 4,320 | 718,706 | |

  지난 버전 문서: `specs/v0.1/`·`specs/v0.2/`의 INTENT·DECISIONS·SPEC·PLAN·PROGRESS 다섯 개씩 모두 있다(v0.1 약 81KB, v0.2 약 176KB, PROGRESS가 대부분).
  `spec/` 폴더는 아직 없다(F1에서 `spec`이 만든다).

### P0-1 master 기준선
- 상태: done (P0-0b로 갈음)

### P0-2 ponytail 감사
- 상태: review (채택안 사용자 승인 대기)
- 담당: reviewer
- 브랜치: master
- 요구·결정: R-4, D-3
- 스펙 ID: -
- 범위: `@ponytail-audit` 저장소 전체 → `specs/v0.3/AUDIT.md`. src 수정 없음.
- 검증 수준: -
- 완료 조건: 하드코딩 수치·색상 / 반복 스타일 체인 / 중복 컴포넌트 / 미사용 의존성 / 기타로 분류. "사용하지 않음" 판정 전 `src/` 전체·`tools/*.ps1`·`src/dev.rs` 플래그까지 검색. 이후 lead가 채택·보류안 → 사용자 승인.
- 비고: 선행 P0-0a. Codex 부담이 한 번에 몰리므로 P0-0c와 겹치지 않게 P0-0b 직후에 지시한다.

### P0-3 실측 정리
- 상태: done (F1로 갈음)

### P0-4 worktree work/ui 빌드·구조 요약
- 상태: done (`agents/P0-4-report.md`)
- 담당: impl-ui
- 브랜치: work/ui
- 요구·결정: R-15
- 스펙 ID: -
- 범위: 확정된 UI 셸 경로(P0-5). 코드 수정 없음.
- 검증 수준: V0
- 완료 조건: worktree에서 `cargo build`(공유 `CARGO_TARGET_DIR`) + `apply-manifest.ps1` 통과, 모듈 구조·반복 스타일 체인·비슷한 컴포넌트 요약 보고
- 비고: 선행 P0-0a, P0-5. impl-editor는 띄우지 않는다(에디터 코어 카드 없음).

### P0-5 에디터 코어·UI 셸 경로 확정
- 상태: done (HERDR-SETUP 4장 반영)
- 담당: lead
- 브랜치: -
- 요구·결정: R-15, HERDR-SETUP 4장
- 스펙 ID: -
- 범위: HERDR-SETUP 4장 소유권 표의 두 행
- 검증 수준: -
- 완료 조건: 사용자 확정값을 HERDR-SETUP 4장에 반영
- 비고: 제안은 HANDOFF.md "P0-5 제안" 절

### F1 실측 정리 (spec 파일화)
- 상태: done (F3·F3-R1 PASS)
- 담당: spec
- 브랜치: master
- 요구·결정: R-5, D-6
- 스펙 ID: (이 카드가 만든다)
- 범위: `spec/INDEX.md` 먼저, 그다음 01→02→03→04 순서로 문서 하나씩 `spec/zed-metrics.toml`에 추가하고 문서마다 저장. 모호·충돌은 `spec/ambiguous.md`.
- 검증 수준: -
- 완료 조건: 문서마다 짧은 보고, 끝나면 항목 수·모호 수·충돌 수를 5.3 형식으로 보고
- 비고: 선행 F0. 최초 프롬프트는 HERDR-SETUP 7.2. ponytail 비적용.

### F2 의도·결정 검토
- 상태: done
- 담당: lead
- 브랜치: master
- 요구·결정: R-13, D-2
- 스펙 ID: -
- 범위: `specs/v0.3/verify/finalize/review-notes.md`, `plan-reconcile.md`
- 검증 수준: -
- 완료 조건: (1) 루트·v0.3 INTENT와 PLAN 어긋남 (2) v0.1·v0.2 DECISIONS·SPEC과 실측 문서 충돌 목록 (3) 지난 PLAN·PROGRESS → v0.3 Phase 대응(완료·없음·폐기·신규) (4) 결정 ID 새로 매기지 않음
- 비고: 선행 F0. F1과 병렬.

### F3 스펙 표본 대조
- 상태: done (F3-R1 PASS)
- 담당: reviewer
- 브랜치: master
- 요구·결정: R-6
- 스펙 ID: toml 전체에서 표본
- 범위: `specs/v0.3/verify/phase0/spec-sample-check.md`. 앱 실행 없음.
- 검증 수준: -
- 완료 조건: 섹션당 3개 이상, 전체의 10% 이상 원문 대조. 불일치 섹션은 spec 전체 재검토 요청(lead 경유).
- 비고: 선행 F1.

### F1-R1 스펙 재검토 (F3 REWORK)
- 상태: done (F3-R1 PASS)
- 담당: spec
- 브랜치: master
- 요구·결정: R-5, R-6
- 스펙 ID: window, project_panel, interaction, theme.fallback, verification.tolerance 섹션 전체, conditions.reference_*, markdown_preview.heading.margin_*
- 범위: `spec/` 파일
- 검증 수준: -
- 완료 조건: 다섯 섹션 전체 원문 대조와 적용 조건 보존, 기준 배율 역산 불확실성 표시, L-104 이중 취급 정리, 항목 수 재집계. 이후 reviewer가 불일치였던 9개 항목만 재대조(F3-R1)
- 비고: 근거 `specs/v0.3/verify/phase0/spec-sample-check.md`. 조건부 관찰값(L-152·L-153·L-309) 수록은 F5 사용자 결정

### F4 개정안
- 상태: done (`verify/finalize/revision.md`)
- 담당: lead
- 브랜치: master
- 요구·결정: R-13
- 스펙 ID: -
- 범위: PLAN·v0.3 문서 변경안(문서는 승인 전 고치지 않음)
- 검증 수준: -
- 완료 조건: 변경 요약 + 사용자 결정 목록(모호 항목, 문서 간 충돌, 범위 조정)
- 비고: 선행 F2, F3.

### F5 확정
- 상태: done (사용자 "제안대로")
- 담당: 사용자
- 브랜치: -
- 요구·결정: R-5, R-13
- 스펙 ID: -
- 범위: `ambiguous.md` 처리(값 결정·재측정·보류), F2 충돌 처리, F4 개정안 승인
- 검증 수준: -
- 완료 조건: 결정을 lead가 PROGRESS에 모두 기록
- 비고: 선행 F4. 지난 PLAN·PROGRESS 보관 처리는 하지 않는다.

### P0-6 V3 기준 실측
- 상태: done (`verify/reviews/measure-p0.md`)
- 담당: reviewer
- 브랜치: master
- 요구·결정: R-14, D-9
- 스펙 ID: `spec/zed-metrics.toml`의 px·ratio·chars 단위 항목 가운데 아래 섹션: window, titlebar, sidebar, dock, project_panel, tab, pane, statusbar, tooltip, menu, scrollbar, inline_input, buttons, icons(상자 크기만), spacing, borders, typography
- 제외(F5): theme 전체·색 항목(Q-8), 아이콘 그림 자체(Q-8), ms 단위 시간 항목(화면 측정 대상 아님), editor·picker·keymap_editor·extensions·markdown_preview·dialog(현재 앱에 없거나 dev 전용·Win32 기본 대화상자), 사이드바 폭 핸들(Q-12). 추정값(Q-11: 패널 아이콘 16, 메뉴 항목 약 25, 커서 위치 글자색)은 현재 값만 기록하고 판정하지 않는다.
- 범위: `specs/v0.3/verify/reviews/measure-p0.md`(+ `tools/measure/`에 만든 스크립트가 있으면 함께)
- 검증 수준: V3
- 측정 목록(화면 상태 순서대로, 앱 1회 실행, `--dev-layout` 덤프 먼저, 부족한 것만 `tools/capture.ps1` 스크린샷 픽셀)
  1. S1 시작 직후·폴더 없음·최대화: window, titlebar, sidebar(빈 목록·푸터, Q-9 푸터 31 vs 30 기록), statusbar, dock. **사이드바 시작 폭을 반드시 기록**(Q-15, P0-0c phase3 300→375)
  2. S2 시험 폴더 하나 등록(파일이 화면보다 많은 폴더, `target\` 아래 새로 만든 시험 폴더. 사용자 폴더 금지), 트리 펼침·항목 하나 선택: sidebar 행, project_panel(행 높이 comfortable·standard 조건 확인, 들여쓰기, 아이콘 상자), scrollbar
  3. S3 파일 하나 한 번 클릭(미리보기 탭) → 다른 파일 더블클릭(일반 탭): tab, pane
  4. S4 타이틀 바 또는 탭 버튼에 마우스 올려 툴팁: tooltip
  5. S5 ☰ 앱 메뉴 열기: menu(앱 메뉴)
  6. S6 프로젝트 패널 항목 우클릭: menu(컨텍스트 메뉴, I-508 현재 값 기록)
  7. S7 이름 바꾸기 시작(F2) 후 Esc로 취소: inline_input
- 측정 조건: 주 모니터 1920×1080, 100%(DPI 96), 최대화, 앱 기본 테마. 허용 오차 논리 px ±1(Q-6, toml `verification.tolerance` 우선). 기준 화면 200%는 논리 px로 비교(Q-7).
- 사용자 데이터: 실행 전 `%APPDATA%\workbench-gpui`를 `specs\v0.3\verify\reviews\_p0-6-backup\`에 복사하고 끝나면 복원·해시 대조(P0-0c 방식).
- 완료 조건: AGENTS 3A.4 절차, `[MEASURED]` 보고. 불일치는 고치지 않고 스펙 불일치 목록으로만.
- 비고: 선행 F5. 1920x1080 100% 주 모니터.

## Phase 1 — 검증 기반 (사용자 승인 2026-11-03, 구성 H-20)

순서: P1-1 → (P1-2 ∥ P1-4 ∥ P1-5) → P1-3. 카드 리뷰는 `review`(agy Flash high)가 카드마다 하고, 병합 직전 `reviewer`(Codex)가 Phase 묶음 최종 확인을 한 번 한다. Phase 끝 R-12 재실행(9개)은 `measure`, 결과 판정은 `reviewer`.

### P1-1 레이아웃 테스트 요구사항
- 상태: done (2026-11-03, `specs/v0.3/verify/phase1/layout-test-req.md`. P1-3 추천: 타이틀 바 3개, 프로젝트 패널 행 높이. `#[test]` 상수 대조로 사용자 확정, H-24)
- 담당: lead
- 브랜치: master
- 요구·결정: R-7, D-7
- 스펙 ID: -
- 범위: `specs/v0.3/verify/phase1/layout-test-req.md`
- 검증 수준: -
- 완료 조건: 스펙 ID 조회 방식(toml 경로 표기 `테이블["키"]`), 허용 오차(`verification.tolerance` 우선, F5 Q-6), 조건(cond) 처리, 실패 메시지 형식, P0-6 "V2 이전 후보" 10줄 중 P1-3 대상 1~2개 추천
- 비고: 짧게(한 쪽). 구현하지 않는다. 구성 변경으로 reviewer → lead(H-20)

### P1-2 스펙 ID 조회 헬퍼
- 상태: done (review PASS, R-7 없는 ID 테스트 `e0a9556` 추가, metrics 4개 통과. master 병합 `3b26320`)
- 담당: impl-ui
- 브랜치: work/ui
- 요구·결정: R-7, D-7, D-1
- 스펙 ID: (헬퍼가 임의 ID를 받음)
- 범위: 테스트 전용 헬퍼(위치는 lead 지정: `src/ui/metrics.rs` 옆 `#[cfg(test)]` 모듈 후보). `Cargo.toml` `[dev-dependencies]` 한 줄
- 검증 수준: V1
- 완료 조건: 스펙 ID로 value·unit·cond를 돌려주고, 없는 ID는 ID를 담은 오류로 실패. 테스트 1개 이상
- 비고: 사용자 승인(2026-11-03): `Cargo.toml` `[dev-dependencies]`에 `toml = "=1.1.8"` 한 줄. 이 카드에 한해 `Cargo.toml`·`src/ui/metrics.rs`를 impl-ui에 지정. 근거: `Cargo.lock`에 이미 `toml 1.1.8`(gpui-kit 경유)이 있어 `[dev-dependencies] toml = "=1.1.8"`이면 새 다운로드가 없다. 대안은 한 줄 레코드 직접 파싱(`p0-report.ps1`의 shortcut과 같은 한계).

### P1-3 대표 레이아웃 테스트 1~2개
- 상태: done (review PASS, master 병합 `3b26320`)
- 담당: impl-ui
- 브랜치: work/ui
- 요구·결정: R-7
- 스펙 ID: P1-1 추천(후보: `titlebar.height`·`window_button` 36×32, `project_panel.item.height` 26)
- 범위: 일반 `#[test]`로 `src/ui/metrics.rs` 상수(타이틀 바 3개)와 `src/ui/panel_view.rs` `ROW_HEIGHT`를 스펙 ID 기대값과 대조(사용자 승인 2026-11-03, H-24. `#[gpui::test]`·`test-support`는 쓰지 않는다)
- 검증 수준: V2
- 완료 조건: 기대값을 P1-2 헬퍼로 스펙 ID에서 가져온다. 현재 코드 값과 같아 통과하거나, 다르면 테스트가 아니라 불일치로 보고(v0.3은 값 불변). 사이드바 기본 폭(375 vs 300)은 대상에서 뺀다(Q-15)
- 비고: 선행 P1-1·P1-2

### P1-4 레이아웃 덤프 JSON
- 상태: done (review PASS, master 병합 `3b26320`)
- 담당: impl-ui (공통 파일 `src/ui/layout_probe.rs`·`src/dev.rs`를 이 카드에 한해 지정)
- 브랜치: work/ui
- 요구·결정: R-8, D-8
- 스펙 ID: -
- 범위: `src/ui/layout_probe.rs`, `src/dev.rs`
- 검증 수준: V1
- 완료 조건: 기존 `--dev-layout` 출력 형식은 그대로 두고(v0.2 검증 스크립트가 읽음), 지정 요소의 경계를 JSON으로 내는 옵션을 더한다. 테스트 1개. P0-6에서 probe가 없던 요소(탭 슬롯 내부 등) 보강은 이 카드 범위가 아니다(값·화면 불변이면 후속 카드)
- 비고: R-12 재실행으로 기존 형식이 안 바뀐 것을 확인
- JSON 형식(lead 지정, P1-5와 공유): 디버그 빌드 옵션 `--dev-layout-json <path>`. 스냅숏이 바뀔 때마다 파일 전체를 다시 쓴다. `{"seq":n,"rem":16.0,"scale":1.0,"viewport":{"w":..,"h":..},"boxes":[{"name":"..","x":..,"y":..,"w":..,"h":..}]}`, 값은 논리 px. `serde_json`(기존 의존성) 사용. 기존 stdout 출력은 그대로. 이 카드에 한해 `src/ui/mod.rs`도 지정(덤프 출력부 `start_layout_dump`)

### P1-5 V3 측정 스크립트 정리
- 상태: done (measure, review REWORK 1회 → R1 PASS `verify/reviews/P1-5.md`. 이름 변경 H-25. 앱 실행 동작은 R-9 판정·R-12 재실행에서 확인)
- 담당: measure
- 브랜치: master
- 요구·결정: R-9, D-12
- 스펙 ID: -
- 범위: `tools/measure/`
- 검증 수준: -
- 완료 조건: P0-6 스크립트를 재사용 가능한 형태로 정리. 리뷰 지적(lead, 2026-11-03) 2~5 반영: 앱을 숨김 창으로 띄우지 않기(`-WindowStyle Hidden` 제거), `p0-show.ps1` 삭제(`p0-input -Action Maximize`로 대체), 100%·주 모니터 좌표 한계 `shortcut:` 주석, 원래 없던 앱 데이터 폴더는 복원 때 지우기. P1-4 JSON 덤프를 읽도록
- 비고: 사용법 한 쪽(README) 포함. 구성 변경으로 reviewer → measure(H-20). 리뷰는 review

### P1-E Phase 1 끝: R-12 재실행, R-8·R-9 판정
- 상태: done (R-12 9개 기준선 대조 ok 뒤바뀜 0, R-8 통과, R-9 24개 중 23 통과·Q-15 1건, `7e09acc`). reviewer 최종 확인 REWORK 1건 → P1-R1
- 담당: measure (판정은 reviewer)
- 브랜치: master `3b26320`
- 요구·결정: R-8, R-9, R-12, D-1, D-5, D-7
- 스펙 ID: (R-9) P0-6 S1 타이틀 바·창 버튼, 프로젝트 패널 행 높이 등 덤프에 있는 것
- 범위: `specs/v0.3/verify/phase1/` (R-12 결과는 `phase1/<스크립트 이름>/`), `specs/v0.3/verify/reviews/measure-phase1.md`
- 검증 수준: V3
- 완료 조건: (1) master 디버그 빌드 + `tools/apply-manifest.ps1`. (2) R-12: P0-0c와 같은 9개 스크립트를 같은 순서·같은 앱 데이터 보호로 실행, `-OutDir specs0.3erify\phase1\<스크립트 이름>`, `-Exe` 절대 경로, d043-clip 제외, phase1은 `r1-expected.tsv` 미리 복사. 항목 단위로 `verify/baseline` 기준선과 대조(사이드바 375/617은 Q-15 기준선 그대로면 "변화 없음"). (3) R-8: 같은 빌드를 `--dev-layout-json`으로 한 번 띄워 JSON 저장, 파서로 읽히는지와 대상 요소 목록 확인. (4) R-9: 그 JSON에 `tools/measure/compare.ps1`을 돌려 표를 `measure-phase1.md`에 남긴다(불일치는 고치지 않고 목록으로). src·지난 버전 폴더 수정 금지
- 비고: 실행 전 다른 workbench-gpui 프로세스 없음 확인. 결과를 [MEASURED] P1-E로 보고. 이어서 reviewer(Codex, 새 세션)가 전체 테스트 1회·`@ponytail-review`·R-12 판정


### P1-R1 글꼴 크기 허용 오차 판별 통일 (reviewer `phase1-final.md` REWORK 1)
- 상태: done (master `a8191d4`·`6282e98`(work/ui `eabe60a` cherry-pick), reviewer R1 PASS)
- 담당: impl-ui(`src/ui/metrics.rs`), measure(`tools/measure/compare.ps1`)
- 브랜치: work/ui, master
- 요구·결정: R-7, layout-test-req 2절
- 검증 수준: V1 (`cargo test metrics`)
- 완료 조건: 글꼴 오차(`verification.tolerance["font_size"]`)는 ID가 `typography[`로 시작하거나 키에 `font_size`가 들면 적용한다. 두 곳 같은 규칙. typography 밖 글꼴 ID(`statusbar["cursor_position.font_size"]`)에서 0.75px 차이가 실패하는 회귀 테스트 1개
- 비고: 끝나면 reviewer가 이 1건만 재확인

## Phase 2 — 상수·테마 통합 (lead 작성 2026-11-03, 위임 H-26, 미결 처리 H-27)

순서: P1-E 통과 뒤 시작. P2-1 → P2-2 → P2-3(impl-ui, 같은 파일을 겹쳐 고치므로 순차, 카드마다 커밋 하나) → review 묶음 리뷰 → 병합 → P2-E. 모든 카드 공통: 값을 바꾸지 않는다(D-9). 코드 값과 스펙 값이 다르면 코드 값을 두고 보고의 "스펙 불일치"에 ID·코드 값·스펙 값·파일 위치로 적는다. 스펙 ID는 `spec/INDEX.md`·`spec/zed-metrics.toml`에서 찾고 추정하지 않는다. 스펙에 없는 수치는 상수로 옮기되 주석을 `// spec: none (app value)`로 단다(H-27, toml에는 넣지 않는다).

### P2-1 레이아웃 수치 상수화
- 상태: todo
- 담당: impl-ui (이 카드에 한해 `src/ui/metrics.rs`·`src/ui/mod.rs`·`src/ui/layout_probe.rs`·`src/dev.rs`와, `src/ui/editor_poc.rs`의 수치 리터럴 줄만 지정 — editor 코어 로직은 건드리지 않는다)
- 브랜치: work/ui
- 요구·결정: R-10, D-9, AUDIT 6
- 스펙 ID: 각 상수마다
- 범위: `src/` 전체에서 `src/ui/metrics.rs` 밖의 `px(숫자)`·`rems_from_px(숫자)`와 AUDIT 6 위치(`app_menu.rs`·`panel_view.rs`·`tooltip.rs`·`title_bar.rs`·`folders.rs`·`panel_menu.rs`)의 로컬 크기·간격·시간 상수와 인라인 리터럴
- 검증 수준: V0 (+ 기존 `cargo test metrics`·`panel_view` 통과)
- 완료 조건: 위 집계가 0건(`px(0.)`은 `Pixels::ZERO` 등 gpui 상수로 바꿔도 된다). 옮긴 상수는 이름이나 주석에 스펙 ID가 있다. 같은 값이라도 ID가 다르면 별개 상수. 원래 타입(Pixels/Rems/Duration) 유지. `metrics.rs` 기존 상수의 ID 대응 점검. 집계 명령과 결과를 보고에 적는다
- 비고: 로컬 상수를 `pub(super)`로 다른 모듈이 가져다 쓰던 곳(context_menu ← app_menu 등)은 metrics 상수로 함께 바꾼다

### P2-2 글자 크기 별칭 명시화
- 상태: todo
- 담당: impl-ui
- 브랜치: work/ui
- 요구·결정: R-10, D-9, AUDIT 7
- 스펙 ID: 화면별 글자 크기 ID(없으면 H-27 규칙)
- 범위: `.text_sm()`·`.text_xs()` 호출부(AUDIT 7 위치)와 `src/ui/metrics.rs`
- 검증 수준: V2
- 완료 조건: gpui-kit 소스에서 `text_sm`·`text_xs`가 정확히 무엇을 설정하는지(글자 크기, 줄 높이 여부) 확인해 보고에 적고, 같은 설정을 하는 명시 상수 호출로 바꾼다. 렌더 결과 불변. 관련 레이아웃 테스트가 있으면 실행
- 비고: 실측 필요 항목으로 해당 화면 상태를 보고에 적는다(P2-E 측정 목록)

### P2-3 색상 리터럴 테마 경유
- 상태: todo
- 담당: impl-ui (새 공통 모듈 `src/ui/theme.rs`를 이 카드에 한해 지정)
- 브랜치: work/ui
- 요구·결정: R-10, D-9, AUDIT 5
- 스펙 ID: L-84(닫기 버튼), L-211·L-212(`elevation_2`)
- 범위: `src/ui/title_bar.rs`, `src/ui/tooltip.rs`, `src/ui/theme.rs`(새 파일), 그 밖에 집계에 걸리는 색상 리터럴(`rgb(`·`rgba(`·`hsla(`·`white()`·`black()`·16진 색)
- 검증 수준: V0
- 완료 조건: `src/ui/theme.rs` 밖 색상 리터럴 0건. 토큰 이름은 의미별(예: 닫기 hover·active, elevation_2 그림자 라이트/다크 알파), 주석에 스펙 ID. 값·다크/라이트 분기 그대로. `elevation_2_shadow` 재사용 유지
- 비고: 테마 매핑·선택기는 v0.4 이후(D-9). 여기서는 한 곳으로 모으기만

### P2-E Phase 2 끝: V3 실측, R-12 재실행, R-10 재감사
- 상태: todo
- 담당: measure(V3·R-12), reviewer(R-10 재감사·최종 확인·R-12 판정)
- 브랜치: master
- 요구·결정: R-10, R-12, D-9
- 범위: `specs/v0.3/verify/phase2/`, `verify/reviews/measure-phase2.md`
- 검증 수준: V3
- 완료 조건: P0-6 측정 목록(S1~S7) 중 Phase 2에서 바뀐 화면을 P0-6과 같은 방법으로 재측정해 같은지 표로(덤프 JSON·compare.ps1 우선). R-12 9개 재실행 기준선 대조. reviewer가 R-10 집계 0건 확인

> 버전: v0.3 · 작성일: 2026-11-03 · 상태: 진행 중
>
> v0.3에서 실제로 한 일과 검증 결과를 기록한다. 계획은 `PLAN.md`, 결정은 `DECISIONS.md`, 요구는 `SPEC.md`, 에이전트 운영은 `HERDR-SETUP.md`에 있다.

# PROGRESS — workbench-gpui v0.3

## Phase별 진행

### Phase 0 — 기준선: 데스크톱 환경·현재 상태 고정·감사·스펙 파일화

#### Phase 0 카드 작성, F0, P0-5 제안 (2026-11-03, lead)

- 무엇을: PLAN Phase 0 카드 14개(P0-0a~c, F0, P0-1~P0-6, F1~F5)를 `specs/v0.3/agents/TASKS.md`에 HERDR-SETUP 5.1 형식으로 썼다. `HANDOFF.md`를 만들었다. F0 입력 문서를 확인하고, P0-5 경로 확정안을 만들었다.
- 결과
  - 검증 수준: P0-0b·P0-4 V0, P0-0c·P0-6 V3(PLAN 그대로), 나머지는 코드를 바꾸지 않는 카드(-).
  - F0: 01-zed 네 문서 합계 4,320줄·718,706바이트. v0.1·v0.2 문서 다섯 개씩 모두 있다. `spec/` 폴더는 아직 없다. 상세는 TASKS F0 카드.
  - P0-5: 에디터 코어 `src/ui/editor_poc.rs`, 공통에 `src/ui/mod.rs`·`rem.rs`·`layout_probe.rs` 추가 제안. 상세는 HANDOFF.
  - herdr: 워크스페이스 `workbench-gpui` 하나, pane은 lead 하나뿐. 다른 에이전트 pane과 `wt-ui`가 아직 없다.
- 검증: `wc`로 분량, `grep '^## '`로 화면 영역, `grep -rn editor_poc src`로 참조처, `grep '^## R-' SPEC.md`로 카드의 요구 번호를 대조했다. src 변경 없음.
- 상태: 사용자 승인(2026-11-03 "승인합니다. 진행"). P0-5 경로를 HERDR-SETUP 4장에 반영했다.

#### herdr 레이아웃·에이전트 실행 (2026-11-03, lead)

- 무엇을: 탭 `control`(lead `wD:p1`, spec `wD:p2`), `verify`(reviewer `wD:p3`, shell `wD:p4`)를 만들고 pane 이름을 에이전트 이름으로 붙였다(사용자 요청). spec(agy `gemini-3.8-flash-medium`), reviewer(codex, `/model` GPT-6.1-Sol medium 세션 한정)를 띄웠다.
- 결과: 실행 중 생긴 판단은 HERDR-DECISIONS H-1~H-5. `herdr worktree create`가 응답하지 않아 `wt-ui`는 아직 없다(review-notes N-8).
- 검증: `herdr pane list`·`herdr agent list`로 이름과 pane id 대조.

#### P0-0a 데스크톱 빌드 환경 (2026-11-03, 사용자·lead)

- 무엇을: winget으로 rustup 설치 → `rustup toolchain install 1.99.1 --profile minimal --component clippy`, `rustup default 1.99.1`. Build Tools 2022(VCTools 워크로드, 권장 구성 요소 포함) 설치, Build Tools 2026 삭제.
- 결과

  | 항목 | 값 |
  | --- | --- |
  | rustup | 1.29.2 |
  | Rust | rustc 1.99.1 (58cf8f9c3 2026-10-13), 기본 툴체인 `1.99.1-x86_64-pc-windows-msvc` |
  | clippy | 0.1.99 (58cf8f9c35 2026-10-13) |
  | MSVC | Visual Studio Build Tools 2022 17.14.37827.9, MSVC 14.44.35207 |
  | Build Tools 2026 | 삭제(vswhere 목록에서 빠짐, `18\BuildTools` 제거). 빈 `18\` 폴더는 사용자 지시로 지우려 했으나 관리자 권한이 필요해 남았다 |
  | Windows SDK | 10.0.26100.0만 남음. 22621·28000은 2026 삭제와 함께 없어진 것으로 보인다 |

- 검증: `rustc --version`, `rustup default`, `rustup component list --installed`, `cargo-clippy --version`, `vswhere -all -products *`, `ls Windows Kits/10/Lib`. 빌드 확인은 P0-0b.
- 상태: 완료. `winget uninstall` 결과 "성공적으로 제거됨"(exit 0). 빈 `18\` 폴더만 남음(관리자 권한 필요, 사용자 처리)

#### F1 실측 정리 (2026-11-03, spec)

- 무엇을: `spec/INDEX.md`(145줄), `spec/zed-metrics.toml`(568줄), `spec/ambiguous.md`(90줄)를 만들었다. 01 → 02 → 03 → 04 순서로 문서마다 저장했다.
- 결과(spec 보고): 측정 조건 3개(`reference_mocha`·`reference_latte`·`default`), 영역 섹션 20개, 항목 282개, 모호·추정 43개(01: 19, 02: 8, 03: 7, 04: 9), 문서 간 충돌 7개(프로젝트 패널 폭, 사이드바 폭, 들여쓰기 단계 폭, 행 높이, Latte 비활성 탭·패널 배경색, 사이드바 기본 위치, 기본 키맵 스킴).
- 검증(lead, 형식만): WinPython `tomllib`로 파싱 성공. 최상위 섹션 29개, `value`가 있는 항목 388개가 모두 `unit`·`src`·`cond`를 갖는다. spec 보고의 282와 lead 집계 388이 다르다(집계 기준 차이로 보임, F3에서 확인). 값의 정확성은 F3 표본 대조에서 본다.
- 상태: 완료(F3 대기)

#### P0-0b master 기준선 (2026-11-03, reviewer)

- 무엇을: master `c6b680a`에서 build·test·clippy --all-targets·apply-manifest·cargo run 1회.
- 결과: 빌드 경고 0(첫 빌드 3분 24초), 테스트 49/49, clippy 고유 경고 10개(exit 0, `-D warnings` 없이 기록), 매니페스트 commonControlsV6·perMonitorV2·longPathAware 모두 true, 창 생성 뒤 정상 종료. 노트북 기록(v0.2 PROGRESS 626행 등)과 같다. clippy는 노트북 기준 수치가 없다.
- 검증: `specs/v0.3/verify/reviews/baseline-2026-11-03.md`와 같은 폴더의 `p0-0b-*.log`. 판정 PASS. 데스크톱 SDK 26100만으로 빌드됨을 확인했다(P0-0a 검증 완료).
- 상태: 완료

#### P0-2 ponytail 감사 (2026-11-03, reviewer)

- 무엇을: `@ponytail-audit` 저장소 전체 + 정확성 검토 → `specs/v0.3/AUDIT.md`. src 수정 없음.
- 결과: 11건. 데이터 손실 위험 2(1 복사 대상 덮어쓰기 경쟁, 2 교차 볼륨 이동 중 원본 변경 유실), 오류 은폐 1(3), UI 정지 1(4), 하드코딩 수치·색상 3(5~7), 반복 스타일 체인 2(8·10), 중복 컴포넌트 1(9), 기타 1(11). 미사용 의존성 0.
- 검증: 근거 로그 `verify/reviews/p0-2-usage.log`, `p0-2-literals.log`. 1~4는 코드 추적이며 실행 재현은 하지 않았다.
- 상태: 완료(채택·보류 확정)

#### F3 스펙 표본 대조 (2026-11-03, reviewer)

- 무엇을: `spec/zed-metrics.toml` 388개 가운데 85개(21.9%, 테이블마다 처음 3개)의 value·unit·cond·src를 원문 절과 대조했다. 앱 실행 없음.
- 결과: 76/85 일치(89.4%), 판정 REWORK. 불일치 9개는 모두 값이 아니라 적용 조건 또는 출처 절이다. 재검토 섹션: window, project_panel, interaction, theme.fallback, verification.tolerance. 기준 배율 2.0·DPI 192가 역산값이라는 불확실성 미표시, L-104 이중 취급, spec 보고 282는 재현되지 않음(실제 388).
- 검증: `specs/v0.3/verify/phase0/spec-sample-check.md`
- 상태: 완료 → spec에 F1-R1 지시

#### F1-R1 스펙 재검토 (2026-11-03, spec)

- 무엇을: F3 REWORK 다섯 섹션(window, project_panel, interaction, theme.fallback, verification.tolerance) 전체를 원문과 다시 대조했다. 기준 배율 역산 불확실성 표시, L-104 이중 취급 정리, 항목 수 재집계.
- 결과: 측정 조건 6개 추가(`window_unmaximized`, `project_panel_comfortable`·`project_panel_standard`, `focus_follows_mouse`, `theme_token_fallback`, `reference_image_200`). `project_panel.item.height.standard` 1개 추가, `markdown_preview.heading.margin_top/bottom`은 원문이 추정값이라 toml에서 빼고 ambiguous에만 둠. 항목 387개. 앞선 282는 확인 불가.
- 검증(lead, 형식): `tomllib` 파싱 성공, 387개 모두 unit·src·cond 있음, cond가 가리키는 조건 9개 모두 정의됨. 값 재대조는 F3-R1(reviewer, 불일치였던 9개만).
- 상태: 완료(F3-R1 대기)

#### P0-0c v0.2 검증 스크립트 기준선 (2026-11-03, reviewer, V3)

- 무엇을: `verify-v02-*` 10개 가운데 9개를 `-OutDir specs\v0.3\verify\baseline\<스크립트>`로 한 번씩 실행(래퍼 `verify/baseline/run-p0-0c.ps1`, 앱 데이터 백업·해시 대조·복원). phase1은 기대표 누락으로 1회 재실행. d043-clip은 `-Before` 원본(노트북 임시 폴더)이 없어 건너뜀.
- 결과: checks가 있는 8개 합계 585 통과 / 2 실패. phase1 9사례 실패 0(R-1 62/62). phase2·phase4·d043·d044·phase5·d046·d047은 노트북과 같다.
  - phase3 R-28 사이드바 폭 2건: 시작 폭 기대 300 → 실제 375, 저장 폭 복원 494 → 617(약 1.25배). 앱 로그는 scale=1·rem=16, 주 화면 viewport 1920×1032. 원인 미확정(코드 경로 `src/ui/mod.rs:500` 부근 sidebar_width 전달, resizable 정규화가 후보). src는 v0.2 그대로라 리팩토링 회귀가 아니라 화면 크기에 따른 기존 동작 차이로 보인다(lead 판단, 확인 전).
  - 휴지통 A-14.3 휴지통 쪽·A-14.5: 판정 불가. D:는 Fixed NTFS지만 휴지통 설정 `NukeOnDelete=1`(바로 지움)이다. 노트북과 같은 이유.
- 검증: `specs/v0.3/verify/baseline/README.md`, `comparison.json`, `run-index.json`, `_backup/after.json`·`final.json`(restored=true, exe 해시 불변). 지난 버전 폴더·src·Cargo 변경 없음(`git status`).
- 상태: 완료(판정 REWORK 2건은 F5 결정 대상, 고치지 않음)

#### F3-R1 재대조, F4 개정안 (2026-11-03, reviewer·lead)

- 무엇을: reviewer가 F3 불일치 9개와 새 조건 6개, 기준 배율 불확실성 표기만 다시 대조했다. lead가 F2·F3·P0-0c·ambiguous를 묶어 F4 개정안을 썼다.
- 결과: F3-R1 PASS(9개 해소, 조건 6개 일치). F4 `specs/v0.3/verify/finalize/revision.md`: 문서 변경안 V-1~V-8, 사용자 결정 Q-1~Q-17, 문서 간 충돌 7건(spec 처리안대로 제안), 범위 밖 기능의 모호 항목 일괄 보류 제안.
- 검증: `spec-sample-check.md` "F3-R1 재대조" 절. F4 번호는 DECISIONS `D-n`과 겹치지 않게 `Q-n`으로 매겼다.
- 상태: 완료(F5 대기)

#### F5 확정 (2026-11-03, 사용자)

- 요청: F4 개정안(`verify/finalize/revision.md`)의 V-1~V-8, Q-1~Q-17, 문서 간 충돌 7건, 범위 밖 모호 항목 보류를 "제안대로" 승인.
- 결정(요지): Q-1 v0.2 한계·미결은 v0.4 / Q-2 `tools/*.ps1` 리팩토링 안 함 / Q-3 v0.1 스크립트는 R-12에 넣지 않음 / Q-4 spec만 agy 편집 자동 승인 / Q-5 worktree는 `git worktree add .worktrees\<이름>` / Q-6 허용 오차 논리 px ±1, 색 채널 ±2(toml 우선) / Q-7 기준 200% 그대로 / Q-8 P0-6은 색·아이콘 제외 / Q-9 푸터 31은 측정 후 불일치 목록 / Q-10 관찰 폭 toml 제외 / Q-11 추정값은 기록만 / Q-12 폭 핸들 판정 제외 / Q-13 글리프 글꼴 기준 닫음 / Q-14 앱 판단 값 닫음 / Q-15 phase3 폭 2건 포함 데스크톱 결과를 R-12 기준선, 원인은 v0.4 후보 / Q-16 휴지통 판정 불가 유지 / Q-17 d043-clip 제외. 충돌 7건은 spec 처리안대로. 범위 밖 모호 항목은 보류.
- 반영
  - HERDR-SETUP: 2장 worktree 문구, 3.4 worktree 명령, 3.5 실행 명령, 3.7 설치 현황, 6.4 승인 처리, 7.1 lead 프롬프트, 7.2·7.4 셸 최소, 변경 이력(V-1~V-6)
  - DECISIONS: D-5 본문의 G-121 문구, 미결의 G-121·글리프 글꼴 기준을 닫음(V-7, Q-13)
  - PLAN: Phase 종료 1번(R-12 대상 9개·기준선), P0-0c 카드에서 d043-clip 제외(V-8)
  - `.gitignore`에 `.worktrees/`, `git worktree add .worktrees/ui -b work/ui master`, herdr 워크스페이스 `wt-ui`(wE: impl-ui `wE:p1`, shell `wE:p2`)
  - toml 변경은 필요 없다(관찰값·추정값은 이미 toml 밖).
- 검증: `git diff --stat`, 바꾼 줄을 `sed -n`으로 다시 읽음, `git worktree list`.
- 상태: 완료

#### P0-4 worktree work/ui 빌드·구조 요약 (2026-11-03, impl-ui, V0)

- 무엇을: `.worktrees/ui`(work/ui)에서 공유 target으로 `cargo build`(30.8초) + `apply-manifest.ps1 -Exe <절대 경로>`. 담당 범위 모듈 구조, 반복 스타일 체인, 비슷한 컴포넌트를 요약하고 AUDIT 5~11과 대조했다. 코드 수정 없음.
- 결과: 빌드 통과, 매니페스트 세 항목 true. worktree에서는 `-Exe` 절대 경로가 필요하다(AGENTS 2장 규칙대로). 감사가 놓친 것: 시간 로컬 상수(watch TICK 100·TICK_LATE 250, folders SAVE_DEBOUNCE 500, panel_view NAME_TOOLTIP_DELAY 1500), rem을 거치지 않는 raw f32(INDENT 20, GUIDE_OFFSET 15, ROW_LINE_HEIGHT 1.618, MAX_HEIGHT_RATIO 0.75), 트리 가이드선 `px(1.)`, title_bar.rs:200의 `white()`, tooltip.rs:206의 구분선 체인. 이것들은 Phase 2·3 카드의 범위에 더한다(AUDIT 5·6·8 채택 항목의 연장).
- 검증: 보고 전문 `specs/v0.3/agents/P0-4-report.md`. impl-ui `git status` 깨끗함.
- 상태: 완료

#### P0-6 V3 기준 실측 (2026-11-03, reviewer, V3)

- 무엇을: master 빌드를 `--dev-layout --dev-keymap --dev-pick-folder`로 1회 실행해 S1~S7 상태를 만들고, 레이아웃 덤프 우선·부족분만 캡처 픽셀로 쟀다. 측정 도구 `tools/measure/`(p0-session·p0-input·p0-show·p0-pixels·p0-report)를 새로 만들었다(reviewer 소유).
- 측정 조건: DISPLAY1 1920×1080, DPI 96·100%, 최대화, 기본 라이트 테마, rem=16.
- 결과: 통과 47, 기록만 6, 불일치 1, 측정 불가·미적용 125(대부분 현재 화면에 없는 상태·아이콘 그림·글꼴 크기 등, 사유는 보고서에 있음).
  - 불일치: `sidebar.default_width` 기대 300 → 실제 375(+75). P0-0c phase3과 같은 방향. v0.4 이후(Q-15).
  - 푸터 31 vs 30: ±1 안이라 PASS, 기준선 31 보존(Q-9).
  - S6 컨텍스트 메뉴 행 23px, 패널 아이콘 16: 기록만(Q-11).
  - V2 이전 후보 10줄(타이틀 바·창 버튼, 경계선, 패널 행·들여쓰기, 탭 바, 툴팁 외곽, 메뉴 행, 인라인 입력) → Phase 1 P1-3 입력.
- 진행 중 일: S4 전환 중 OpenWith.exe "Open With" 창이 전면을 막아, 사용자 지시로 reviewer가 그 창만 Esc로 닫았다(H-18, 연결 앱 선택·설정 변경 없음). 앱이 숨김 창으로 떠서 `p0-show.ps1`로 표시·최대화했다.
- 검증: `specs/v0.3/verify/reviews/measure-p0.md`, `p0-measure/`(S1~S7 덤프·캡처·measurements.json·actions.log), `_p0-6-backup/after.json`(restored=true, fixtureRemoved=true, exeUnchanged=true). src·spec·지난 버전 폴더 변경 없음.
- 참고: 실행 파일 SHA-256이 P0-0c 때(844E…)와 다르다(FEF3…). 그 사이 P0-4에서 impl-ui가 같은 커밋 `c6b680a`를 worktree에서 공유 target으로 다시 빌드했기 때문이다(소스 같음, 경로·디버그 정보 차이).
- 상태: 완료

#### Phase 0 종료 (2026-11-03, lead)

- 무엇을: PLAN "Phase 종료 때" 절차. 1번(R-12 재실행)은 Phase 0이라 제외. 2·3번 V3는 P0-0c·P0-6으로 했다. 4번 사용자 확인 필요(V4) 항목: 없음(모든 완료 보고가 "없음"). 5번 `/ponytail-debt`. 6번 HANDOFF·PROGRESS 갱신, 커밋, 태그. lead가 미커밋 변경을 `/ponytail-review`로 검토했다(사용자 요청).
- 결과
  - `/ponytail-debt`: 표식 1건 — `tools/measure/p0-report.ps1:8` toml 한 줄 레코드 파싱(형식이 바뀌면 TOML 파서). 트리거 없는 표식 0. `AGENTS.md`·`AGENTS.draft.md`의 것은 규칙 예시.
  - 리뷰 지적 5건: 1 백업 `appdata/`가 커밋될 위험 → `.gitignore`에 `specs/v0.3/verify/**/appdata/` 추가(사용자 "제안대로"). 2 숨김 창 시작, 3 `p0-show.ps1` 중복, 4 100%·주 모니터 좌표 한계 미표시, 5 원래 없던 앱 데이터 폴더가 남음 → P1-5로 넘김.
  - Phase 0 완료 조건: R-1~R-6·R-13~R-15 산출물이 모두 있다. HERDR-SETUP 4장 경로 확정, F5 결정 기록, Phase 0 동안 `src/`·`specs/v0.1·v0.2/` 변경 없음(`git status`).
  - Phase 1 카드 초안을 TASKS에 썼다(사용자 승인 대기).
- 검증: `git check-ignore -v`로 두 백업 경로가 무시됨을 확인, `git status --short src specs/v0.1 specs/v0.2` 빈 결과.
- 상태: 완료(커밋·태그는 아래 커밋)

#### Phase 1 준비: 구성 변경 H-20, 카드 승인, 세션 규칙 (2026-11-03, 사용자·lead)

- 요청: "claude 토큰에 여유가 있으나, codex 여유가 부족 합니다", "gemini 도 여유가 많습니다", "argon 은 사용 불가", 구성안·Phase 1 카드 승인, "진행, 규칙도 추가해 주세요".
- 조치: HERDR-SETUP 1장(review·measure 역할 추가, reviewer 축소)·1.3·4장·9장(Phase마다 새 세션)·변경 이력, AGENTS 7.1a, HERDR-DECISIONS H-20, TASKS Phase 1 카드(P1-1 lead, P1-5 measure, P1-2 toml dev-dep 승인), HANDOFF.
- 검증: 바꾼 줄을 다시 읽음. src 변경 없음.
- 상태: 완료(Phase 1은 새 lead 세션에서 시작)

#### 감사 채택·보류, 동작 변경 범위, P0-0c 시점 결정 (2026-11-03, 사용자)

- 요청: lead가 세 가지 안을 내고 사용자가 "제안대로"로 승인했다.
- 결정
  1. AUDIT 채택: 5·6·7 → Phase 2, 8·9·10·11 → Phase 3(9는 V1). 보류: 3·4 → v0.4 이후. `AUDIT.md` 결정란에 기록했다.
  2. 데이터 손실 위험 AUDIT 1·2는 v0.3 안에서 Phase 3 뒤 별도 카드(P3-D1·P3-D2)·별도 커밋으로 고친다. v0.3 INTENT 제외 범위의 "미정"(review-notes N-2)을 닫았다.
  3. P0-0c는 F3이 끝난 뒤 lead가 묻고, 사용자가 자리를 비울 때 돌린다. 그동안 reviewer에게는 다른 일을 주지 않고 F4는 lead가 쓴다(Codex 주간 한도 41%).
- 반영(F3 기록은 아래): `specs/v0.3/INTENT.md` 제외 범위 한 줄, `specs/v0.3/PLAN.md`에 "Phase 3 뒤" 절 추가(사용자 승인 계획 변경), `AUDIT.md` 결정란.
- 상태: 완료

### Phase 1 — 스펙 ID 레이아웃 테스트·덤프 JSON·측정 도구

#### P1-1~P1-5 (2026-11-03, lead·impl-ui·measure·review)

- 무엇을: P1-1 요구사항(`verify/phase1/layout-test-req.md`, lead), P1-2 스펙 ID 헬퍼 `metrics::spec`(`lookup`·`assert_spec`, dev-dep `toml =1.1.8` 승인), P1-3 타이틀 바·창 버튼·프로젝트 패널 행 상수 대조 `#[test]`(H-24, gpui-kit test-support 없이), P1-4 `--dev-layout-json <path>`(`layout_probe::layout_json`), P1-5 `tools/measure/` 정리(session·input 이름 변경, compare.ps1, README).
- 결과: review `P1-2-3-4.md` PASS(P1-2는 R1 뒤), `P1-5.md` REWORK → R1 PASS. master 병합 `3b26320`(src 191줄 추가·0줄 삭제), tools `e036bef`. 테스트 49 → 55.
- 검증: 카드별 V0~V2(review 기록). clippy 기준선 경고 10개 외 새 경고 0.
- 상태: 완료

#### P1-E Phase 1 끝: R-12·R-8·R-9 (2026-11-03~04, measure, V3)

- 무엇을: master 빌드(exe SHA-256 `E40C2FDF…23380`, 전후 동일)로 v0.2 검증 스크립트 9개 재실행, `--dev-layout-json` 1회, compare.ps1 대조.
- 결과
  - R-12: 9개 모두 기준선과 ok 뒤바뀜·신규·누락 0. 합계 587개 중 585 통과, 실패 2는 phase3 사이드바 폭 375/617(Q-15 기준선 그대로). d043-clip SKIP·휴지통 내부 판정 불가는 기준선과 같은 환경 사유.
  - phase4·d043·d044는 사용자 클립보드의 OLE 형식(49161·49171) 때문에 보호 동작으로 두 번 멈췄다. 사용자가 비운 뒤 실행 직전 `Clipboard.Clear()`로 재실행(H-28, R2).
  - R-8: JSON 파싱됨(seq=2, 박스 57개). R-9: 24개 중 23 통과, 불일치 `sidebar["default_width"]` 300 → 375(Q-15).
- 검증: `verify/phase1/README.md`·`comparison.json`, `verify/reviews/measure-phase1.md`. 커밋 `7e09acc`.
- 상태: 완료

#### Phase 1 최종 확인 (2026-11-04, reviewer)

- 결과: 전체 테스트 55 통과(1회), clippy 기준선 10개·새 경고 0, R-12 PASS. REWORK 1건: 글꼴 오차 판별이 `typography` 테이블에만 걸려 `statusbar["cursor_position.font_size"]`가 ±1을 받음(compare.ps1은 반대로 `font_size` 키만) → P1-R1: 두 곳 모두 "ID가 `typography[`로 시작하거나 키에 `font_size`" 규칙으로 통일, 회귀 테스트 1개(master `a8191d4`, work/ui `eabe60a`).
- 검증: `verify/reviews/phase1-final.md`.

#### 스펙 불일치 목록 (v0.4 이후, 고치지 않음)

| 스펙 ID | 스펙 | 코드·실측 | 근거 |
| --- | ---: | ---: | --- |
| `sidebar["default_width"]` | 300 | 375 | Q-15, P0-0c·P0-6·P1-E 같은 값 |
| `sidebar["footer.height"]` | 30 | 31 | 허용 오차 안(Q-9), 기록만 |

#### Phase 1 종료 (2026-11-04, lead, 위임 H-26)

- 무엇을: PLAN "Phase 종료 때" 절차. R-12(P1-E), V3(R-9 대조), 최종 확인(reviewer PASS), `/ponytail-debt`, HANDOFF·PROGRESS·PLAN 갱신, 태그.
- 결과
  - P1-R1 src 수정은 work/ui `eabe60a`를 master에 cherry-pick(`6282e98`). work/ui에는 그 앞에 Phase 2 커밋이 있어 브랜치 병합은 Phase 2 때 한다.
  - `/ponytail-debt`(`shortcut:` 표식): `tools/measure/compare.ps1:9`·`p0-report.ps1:8` 한 줄 레코드 파싱, `session.ps1:2`·`input.ps1:2` 100%·주 모니터 좌표. src에는 표식 없음.
  - 사용자 확인 필요(V4): 없음.
  - 위임 중 lead 판단: H-26(위임 범위), H-27(스펙에 없는 수치 `// spec: none (app value)`), H-28(클립보드 비우기). 사용자 확인 목록에 올린다.
- 검증: reviewer `phase1-final.md` R1 PASS(`cargo test metrics` 5 통과). 전체 테스트 55는 R1 전 1회.
- 상태: 완료

### Phase 2 — 상수·테마 통합

#### P2-1~P2-3 (2026-11-04, impl-ui·review)

- 무엇을: P2-1 레이아웃 수치를 `metrics.rs`(하위 모듈 menu·project_panel·tooltip)로 모음(AUDIT 5·6), P2-2 `text_sm`/`text_xs` 9곳을 `TEXT_SIZE_DEFAULT`(14)·`TEXT_SIZE_SMALL`(12) 상수로(AUDIT 7), P2-3 색 리터럴을 새 `src/ui/theme.rs`로(닫기 버튼 hover·active, elevation_2 그림자 2개, 개발용 측정 색).
- 결과: work/ui `a564644`·`6949652`·`63c5670`, review `P2-1-2-3.md` 세 카드 PASS, master 병합 `0f814a7`(12파일 +240/−138). 스펙 없는 앱 값은 `// spec: none (app value)`(H-27). AUDIT 6 위치 밖 `Duration::from_*`(watch·keymap·dev·editor_poc·watch_io·mod)는 카드 범위대로 남김.
- 검증: V0(빌드·clippy). 값 동일성은 review·reviewer 코드 대조.
- 상태: 완료

#### P2-E Phase 2 끝: R-12·V3 (2026-11-04, measure)

- 무엇을: master `0f814a7` 빌드(exe SHA-256 `7E22E72F…A6038`, 전후 동일)로 v0.2 검증 9개 재실행(H-28 클립보드 비우기), P0-6 S1~S7 재측정, 닫기 버튼 hover·active 색, 툴팁 그림자, '경로 없음' 화면 변경 전·후 PNG 대조.
- 결과
  - R-12: 9개 모두 기준선과 같음(합계 587 중 585 통과, 실패 2는 phase3 Q-15). 실행기 클립보드 도우미 경로 오류로 phase4 계열 3개가 처음엔 SKIP → 고쳐서 1회 재실행, 모두 exit 0.
  - V3: 불일치 0. 측정 불가: 다크 테마 툴팁 그림자(테마 전환 조작이 범위 밖), 글자 크기 px 값 자체(렌더가 변경 전과 같은 것만 확인).
- 검증: `verify/phase2/README.md`·`comparison.json`, `verify/reviews/measure-phase2.md`. 커밋 `7465d39`.
- 상태: 완료

#### Phase 2 최종 확인 (2026-11-04, reviewer)

- 결과: 값·동작 보존(상수·rem 환산·색·그림자 분기 대조), R-10 재감사 잔여 0(metrics.rs 밖 크기 리터럴·theme.rs 밖 색 리터럴·글꼴 별칭), 전체 테스트 56 통과(1회), clippy 기준선 10개·신규 0, `@ponytail-review` Ship, R-12 PASS. 결론 PASS.
- 검증: `verify/reviews/phase2-final.md`.

#### Phase 2 종료 (2026-11-04, lead, 위임 H-26)

- 결과
  - `/ponytail-debt`: src에 `shortcut:` 표식 없음(Phase 1과 같음, tools/measure 4건 그대로).
  - 스펙 불일치: Phase 1 목록과 같음(새 항목 없음).
  - 사용자 확인 필요(V4): 다크 테마 툴팁 그림자 렌더(코드의 0.06 분기는 보존 확인), 글자 크기 렌더 인상.
- 상태: 완료

## 사용자 요청 작업

### docs\temp 이름 바꾸기·이동 (2026-11-03)

- 요청: "docs\temp -> 폴더명 변경 제안 / 또는 다른 폴더로 이동 검토"
- 조치
  - `docs/temp`를 `docs/refs/refactor-draft/`로 옮겼다.
  - 하위 폴더에서 자동으로 읽히지 않도록 안의 `AGENTS.md`·`CLAUDE.md`를 `AGENTS.draft.md`·`CLAUDE.draft.md`로 이름을 바꿨다.
- 결과: 초안 다섯 개(PLAN·FINALIZE·HERDR·AGENTS.draft·CLAUDE.draft)가 `docs/refs/refactor-draft/`에 있다. 그 뒤 사용자가 `HERDR-SETUP.md`를 더했다.
- 검증: `ls docs docs/refs docs/refs/refactor-draft`로 `docs/temp`가 없어지고 파일이 옮겨진 것을 확인했다.
- 상태: 완료

### specs\v0.3 폴더 만들기 (2026-11-03)

- 요청: "specs\v0.3 폴더 생성 필요"
- 조치: `specs/v0.3/`를 만들었다.
- 결과: 폴더가 있다. 지난 버전 폴더는 건드리지 않았다.
- 검증: `ls specs`
- 상태: 완료

### HERDR 구성 규칙을 지침에 넣기 (2026-11-03)

- 요청: "구독현황 및 토큰 부담에 따라 HERDR 멀티에이젼트를 정해야 함을 지침문서에 반영해 주세요."
- 조치: 루트 `AGENTS.md`에 "HERDR 구성은 구독·토큰 부담으로 정한다" 규칙을 더했다.
- 결과: 규칙 한 줄이 생겼다(뒤의 요청에서 레포 규칙 절로 유지).
- 검증: 파일을 다시 읽어 확인했다.
- 상태: 완료

### v0.3 INTENT·DECISIONS·SPEC·PLAN 초안 (2026-11-03)

- 요청: "v0.3 INTENT 초안 작성해 주세요", "DECISIONS 초안 작성해 주세요", "refactor-draft 기반으로 specs\v0.3 스펙 문서 작업을 계속 진행하겠습니다."
- 조치: project-workflow-compact 템플릿으로 네 문서를 썼다. 데스크톱 환경 점검(Phase 0)과 노트북과 같은 빌드 환경(D-5)을 반영했다.
- 결과: `specs/v0.3/INTENT.md`, `DECISIONS.md`, `SPEC.md`, `PLAN.md`(상태: 초안)
- 검증: `grep '^## '`로 절 구성을 확인했다. SPEC의 R-n이 모두 PLAN Phase에 대응되는지 대조했다.
- 상태: 다음 요청으로 다시 고침

### refactor-draft를 v0.3 기준으로 반영 (2026-11-03)

- 요청: "workbench-gpui\docs\refs\refactor-draft 의 문서의 내용이 현재 데스크탑 및 워크스페이스 에 맞게 모두 반영되어야 합니다. … 참고가 아니라 이 문서를 기준으로 v0.3 이 이루어져야 합니다. 1. 데이크탑 환경 적용 2. 멀티에이젼트시 토큰 부담 고려 3. 자료나 파일등 경로 맞게 수정 반영"
  - 이어진 지시: HERDR 문서는 `specs/{version}/`에 버전별로 둔다. Python은 `C:\winpython\`의 `_cpu`·`_gpu`를 쓴다.
  - 사용자 선택
    - 에이전트 구성: "HERDR.md + 부담 조정"
    - 측정 도구: "PowerShell 재사용"
    - P4~P6: "v0.4 이후 유지"
- 조치
  - 새로 쓴 문서: `specs/v0.3/HERDR-SETUP.md`, `specs/v0.3/HERDR-DECISIONS.md`, 이 PROGRESS
  - 다시 쓰거나 고친 문서: 루트 `AGENTS.md`, `specs/v0.3/PLAN.md`, `SPEC.md`(R-13~R-15 추가), `DECISIONS.md`(D-2 다시 씀, D-10~D-12 추가), `INTENT.md`, `README.md`
  - 고치지 않은 것: `docs/refs/refactor-draft/`, `specs/v0.1·v0.2/`, `docs/HERDR-*.md`
- 결과: 초안 절마다 반영 위치는 아래와 같다.

  | 초안 | 절 | 반영 위치 |
  | --- | --- | --- |
  | HERDR.md | 1 에이전트 구성, 1.1 모델 운용, 1.2 리뷰 독립성 | HERDR-SETUP 1장(impl-editor 필요할 때만, reviewer 대체 모델 추가, 1.3 토큰 부담 신설), D-10 |
  | HERDR.md | 2 레이아웃 | HERDR-SETUP 2장(`zed-main` → 기존 `workbench-gpui`, `wt-editor` 필요할 때만) |
  | HERDR.md | 3 초기 설정 3.1~3.7 | HERDR-SETUP 3.1~3.7(설치 현황 반영, Rust·Build Tools 2022·WinPython), 3.8 화면·실측 조건 신설 |
  | HERDR.md | 4 소유권 | HERDR-SETUP 4장(경로 치환, `specs/v0.3/` 아래), D-11 |
  | HERDR.md | 5 작업 프로토콜 | HERDR-SETUP 5장(카드에 요구·결정 칸 추가, 묶음 리뷰) |
  | HERDR.md | 6 공통 규칙 | HERDR-SETUP 6장(6.5 대리 응답 범위는 HERDR-SETUP 변경안 7절에서) |
  | HERDR.md | 7 최초 지시 프롬프트 | HERDR-SETUP 7장(경로 치환, impl-editor는 필요할 때) |
  | HERDR.md | 8 단계 계획 | HERDR-SETUP 8장, PLAN |
  | HERDR-SETUP.md (변경안) | 1 근거, 6 토큰 부담, 7 대리 응답, 4 운영 규칙(auditor·checker) | HERDR-SETUP 0장·1.3·6.5. 감사는 reviewer가 하고(D-3), 기준선은 P0-0c, 허용 범위는 미결 |
  | AGENTS.draft.md | 0~9장 전체 | 루트 `AGENTS.md` "에이전트 공통 지침"(경로·`master`·`shortcut:`·WinPython 반영) |
  | PLAN.md | 1 요약, 2.1~2.3 운영 규칙 | PLAN "읽는 법" 절 |
  | PLAN.md | 3 P0~P3 | PLAN Phase 0~3 카드표 |
  | PLAN.md | 3 P4~P6 | PLAN "v0.4 이후" 절 |
  | PLAN.md | 4 진행 현황 | PLAN "진행 현황" 표 |
  | FINALIZE.md | 1 원칙 | AGENTS 3장(수치 기준 하나, 원문은 INDEX로), PLAN Phase 0 완료 조건(src 변경 없음) |
  | FINALIZE.md | 2 입력 문서·읽기 규칙 | PLAN F0 카드, AGENTS 0·3·9장 |
  | FINALIZE.md | 3 산출물·소유권, 3.1 toml 형식 | PLAN Phase 0 산출물, HERDR-SETUP 4장, D-6, SPEC R-5 |
  | FINALIZE.md | 4 F0~F5 | PLAN Phase 0 F0~F5 카드, SPEC R-5·R-6·R-13 |
  | FINALIZE.md | 5 최초 지시 프롬프트 | HERDR-SETUP 7.1·7.2·7.3에 합침 |
  | FINALIZE.md | 6 확정 후 반영 목록 | 이번 반영. 6.4 보관 처리는 하지 않음(D-2) |
  | FINALIZE.md | 7 진행 현황 | PLAN 진행 현황(Phase 0 안의 F 카드는 TASKS.md에서 관리) |

- 검증
  - 반영 문서에서 자리표시자(`<REPO_ROOT>`·`<ZED_MEASURE_DIR>` 등), 옛 경로(`docs/agents`, 루트 `HERDR.md`), `main` 브랜치, `ponytail:` 주석 형식을 grep으로 찾았다. 출처 인용을 빼면 0건이다.
  - `grep '^## '`로 절 구성을 확인했다. SPEC R-1~R-15가 모두 PLAN Phase에 대응된다.
  - `git status`로 지난 버전 폴더, `refactor-draft/`, `docs/HERDR-*.md`에 변경이 없음을 확인했다.
- 상태: 완료(문서 상태는 "초안, 사용자 확인 대기")

### Phase 0 시작 전 결정 반영과 v0.3 문서 확정 (2026-11-03)

- 요청: "v0.3 에 대한 필요한 스펙 문서 작업이 모두 끝났나요?"에 이어, Phase 0 시작 전에 정할 네 가지를 질문받고 답했다.
  - MSVC: "2022 최신 + 2026 삭제"
  - P0-0c 기준선: "reviewer 전부"
  - agy 한도: "둘 다 충분"
  - 문서: "반영 후 확정"
- 조치
  - D-5: Build Tools 2022 최신 설치와 2026 삭제를 넣고, 배제한 대안 두 개를 더했다.
  - D-10 근거에 agy 한도와 P0-0c 담당을 넣었다.
  - DECISIONS 미결 사항에서 정해진 네 줄을 지웠다: 2022 세부 버전, 2026과의 공존 방법, P0-0c 담당, agy 남은 한도.
  - SPEC R-1: 2026 삭제와 버전 기록을 판정 기준에 넣고 "미정"을 지웠다.
  - PLAN P0-0a·P0-0c 카드와 HERDR-SETUP 0장·3.7·변경 이력을 고쳤다.
  - INTENT·DECISIONS·SPEC·PLAN·HERDR-SETUP의 상태를 "확정 (2026-11-03)"으로 바꿨다.
- 결과: v0.3 문서가 확정되었다. 남은 미결은 Phase 0 안이나 이후에 정하도록 짜여 있다.
  - Phase 0 안에서: 담당 경로(P0-5), 모호·충돌 항목(F5), 허용 범위
  - 감사 뒤: 채택 범위, 동작 변경 수정
  - Phase 1·2 전: toml 크레이트, 스펙에 없는 수치
- 검증: 다섯 문서의 상태 줄을 grep으로 확인했다. 파일을 다시 읽어 한글이 깨지지 않았음을 확인했다.
- 상태: 완료

### .serena를 .gitignore에 추가 (2026-11-03)

- 요청: ".serena 는 .gitignore 에 추가해 주세요"
- 조치: `.gitignore`에 `.serena/` 한 줄을 더했다.
- 결과: `git status`에 `.serena/`가 더 나오지 않는다.
- 검증: `git status --short`의 결과가 ` M .gitignore`뿐이다.
- 상태: 완료(커밋 전)

## 버전 종료

- 사용자 종료 판단: 진행 중.
- 남은 것: 진행 중.

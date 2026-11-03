# Phase 1 최종 리뷰

- 일자: 2026-11-04. 역할: reviewer. 사용자 요청 작업.
- 브랜치: master, HEAD `7e09accdd40304357c4acae652b311683af91bb3`.
- 대상: `git diff v0.3-phase-0..HEAD` 중 `src/`, `Cargo.toml`, `Cargo.lock`, `tools/measure/`.
- 기준: SPEC R-7~R-9·R-12, PLAN Phase 1, `phase1/layout-test-req.md`, AGENTS 7.1·7.1a.

What this change does: 스펙 ID를 읽는 테스트 헬퍼와 상수 대조 테스트를 추가한다. 기존 레이아웃 덤프에 JSON 출력을 붙이고 PowerShell 측정 도구를 정리한다.

## 검증

공유 `CARGO_TARGET_DIR=D:\projects\workbench-gpui\target`을 사용했다. cargo가 초기 PATH에 없어 `%USERPROFILE%\.cargo\bin`을 앞에 추가했다. 최초 호출은 cargo 프로세스를 시작하지 못했으며, 실제 전체 테스트 실행은 아래 1회다.

| 명령 | 결과 |
| --- | --- |
| `rtk cargo test` | PASS: 55 passed, 0 failed. 전체 테스트 1회 |
| `rtk cargo clippy --all-targets -- -D warnings` | exit 1. 기존 경고 10개가 오류 처리됨. 새 경고 0개 |

clippy 위치는 `P1-2-3-4.md`의 기준선과 일치한다: dev.rs:266·270, fsops/ident.rs:53, names.rs:99, tree.rs:201, state/mod.rs:13, ui/keymap.rs:520, layout.rs:143·395, watch.rs:274. clippy 자체를 통과했다고 판단하지 않았다. 요청한 기준선 예외만 적용했다.

## ponytail-review 및 정확성 리뷰

단일 사용자 Windows 데스크톱 편집기와 100% DPI 주 모니터 측정 세션을 전제로 읽었다. 변경 함수의 호출부, DevOptions의 debug/release 분기, dump 실행 조건, snapshot과 직렬화 흐름, 대표 테스트, 측정 Start/Stop의 백업·복원 및 입력 가드를 확인했다.

### Should fix

1. **글꼴 크기 허용 오차가 테이블에 따라 달라짐** (`src/ui/metrics.rs:138`)
   - What this is: `assert_spec`는 스펙 ID와 실제 값을 비교하는 공통 테스트 헬퍼다.
   - Problem: 글꼴 여부를 `id.starts_with("typography") && id.contains("size")`로 판별한다. 하지만 `statusbar["cursor_position.font_size"]`도 글꼴 크기다(`spec/zed-metrics.toml:264`, 기대 12px, cond default). 이 ID로 실제 12.75px를 넘기면 치수 오차 ±1px가 적용되어 통과한다. `layout-test-req.md` 2절의 글꼴 오차 ±0.5px라면 실패해야 한다. PowerShell `compare.ps1`의 font_size 판별과도 결과가 다르다.
   - Fix: 테이블 접두어 제한을 없애고 스펙의 글꼴 크기 키에 맞게 판별한다. typography 밖 글꼴 ID에서 0.75px 차이가 실패하는 최소 회귀 테스트를 추가한다. src 수정은 담당자에게 넘긴다.
   - If we skip it: 이후 레이아웃 테스트가 글꼴 크기 회귀를 통과시킬 수 있다. 현재 대표 상수 테스트는 이 경로를 다루지 않아 55개 통과로 이 결함을 배제할 수 없다.

추가 차단 결함은 확인하지 못했다. 사용자 UI의 크기·입력·파일 작업 로직 변경은 없다. 테스트 전용 TOML 의존성은 승인된 범위이며 런타임 의존성을 추가하지 않았다. JSON 옵션은 debug에서만 켜지고, 파일 쓰기 실패는 stderr로 보고한다. 기존 stdout 형식은 유지한다. 기존 probe·serde_json·capture 및 네이티브 입력 선언을 재사용하며 새 추상화나 의존성은 필요하지 않다. P1-5 초기 리뷰의 백업 기본 경로 및 shortcut 주석 지적은 현 HEAD에서 수정되어 있다.

Verdict: fix 1 first.

## R-12 판정: PASS (기준선 대비 동작 불변)

`verify/baseline/README.md`와 `verify/phase1/README.md`, `comparison.json`의 최종 R2 결과를 대조했다. 초기 클립보드 중단 기록은 최종 결과와 구분했다.

| 스크립트 | 기준선 → Phase 1 | 판정 |
| --- | --- | --- |
| phase1 | 9사례·실패 0 → 동일, 바인딩표·사례 이름 동일 | PASS |
| phase2 | 137/0 → 137/0 | PASS |
| phase3 | 120/2 → 120/2, 실제 폭 375·617 동일 | PASS |
| phase4 | 208/0 → 208/0 (R2) | PASS |
| phase4-d043 | 13/0 → 13/0 (R2) | PASS |
| phase4-d044 | 6/0 → 6/0 (R2) | PASS |
| phase5 | 62/0 → 62/0 | PASS |
| phase5-d046 | 23/0 → 23/0 | PASS |
| phase5-d047 | 16/0 → 16/0 | PASS |

checks 배열 합계는 양쪽 모두 587개 중 585 통과·2 실패다. Phase 1 README의 360개/358 통과 집계는 초기 실행 집계로, 최종 R2 반영 합계와 구분해야 한다. 기존 Q-15 폭 불일치는 고쳐진 것이 아니라 유지된 것이다.

phase3 itemDiffs의 GUID 경로 1쌍과 phase5 이벤트 수 1818/1811을 포함한 이름 1쌍은 실행별 항목 이름 차이이며 ok 뒤바뀜은 없다. d043-clip은 Before 원본 부재로 양쪽 SKIP, 휴지통 내부·복원은 환경 설정 때문에 양쪽 판정 불가다. phase2 툴팁 문구 차이는 README에 기록되어 있으며, 해당 UI 로직은 이 diff에서 변경되지 않았다.

이 PASS는 저장된 검증 증거 범위의 동작 불변 판정이다. comparison.json은 모든 got/expect 문자열의 동일성을 검사하지 않으므로 모든 측정값의 바이트 단위 동일성까지 보장하지 않는다. 타이밍 허용 범위를 새로 정의하거나 환경상 미검증 항목을 통과로 바꾸지 않았다.

## 전달 사항

- R-8·R-9 증거: 저장된 JSON 57개 박스와 측정 24개 중 23 통과, 기존 sidebar 폭 불일치 1개. 재실측하지 않았다.
- 실측 필요: 이번 리뷰에서 새로 추가할 항목 없음.
- 사용자 확인 필요: 이번 리뷰에서 새로 추가할 항목 없음.
- src·공유 문서·지난 버전 폴더는 수정하지 않았다. PROGRESS는 lead 소유이므로 이 리뷰 결과를 사용자 요청 작업으로 전달한다.
- Not checked: 앱 실행·화면 조작·추가 V3·스크립트 재실행은 하지 않았다. d043-clip 및 휴지통 내부·복원 한계는 남아 있다.

결론 REWORK

## 재확인 (R1)

- 일자: 2026-11-04. 사용자 요청에 따라 REWORK 1만 재확인했다.
- 대상: work/ui `eabe60a`의 `src/ui/metrics.rs`, master `a8191d4`의 `tools/measure/compare.ps1`.
- 코드 확인: Rust 헬퍼가 `typography[` 접두 또는 `font_size` 포함 ID에 글꼴 오차를 적용한다. PowerShell도 같은 스펙 ID 판별 규칙을 사용한다. 두 구현 모두 px 이외 단위는 기존대로 정확 일치를 요구한다.
- 회귀 테스트: `statusbar["cursor_position.font_size"]`의 기대 12px에 실제 12.75px를 전달하면 `spec mismatch`로 panic하는 `should_panic` 테스트가 추가되어 있다. 이전 ±1px 판별에서는 panic하지 않아 실패할 테스트이며, 수정 후에는 ±0.5px로 거부한다.
- 실행: `D:\projects\workbench-gpui\.worktrees\ui` (HEAD `eabe60a2c46524e7eee65b6cb8daee673fd46ee6`)에서 공유 `CARGO_TARGET_DIR=D:\projects\workbench-gpui\target`으로 `rtk cargo test metrics` 1회. 결과: 5 passed, 0 failed, 51 filtered out.
- 판정: REWORK 1 해결. 기존 R-12 판정은 유지한다. PROGRESS 반영은 lead에게 전달한다.
- Not checked: 요청 범위에 따라 전체 테스트·clippy·PowerShell 실행·앱 실행은 하지 않았다. 기존 SKIP·판정 불가 한계는 유지된다.

결론 PASS

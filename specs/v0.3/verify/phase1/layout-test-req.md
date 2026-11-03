# P1-1 레이아웃 테스트 요구사항

> 소유: `lead`. 카드 P1-1(R-7, D-7). P1-2·P1-3 구현자가 따른다. 구현은 하지 않는다.

## 1. 스펙 ID 표기

- ID는 `테이블["키"]`로 쓴다. 테이블은 toml 테이블 경로(점으로 연결), 키는 따옴표 안의 키 그대로다.
  - 예: `titlebar["height"]`, `titlebar["window_button.width"]`, `project_panel["item.height"]`, `verification.tolerance["dimension"]`
  - 키 이름만으로는 겹친다(`"size.xsmall"`이 두 테이블에 있다). 테이블을 빼지 않는다.
- 파일은 `spec/zed-metrics.toml` 하나다. 테스트는 `include_str!(concat!(env!("CARGO_MANIFEST_DIR"), "/spec/zed-metrics.toml"))`로 읽는다(파일이 바뀌면 다시 컴파일된다).
- 헬퍼는 ID 하나로 `value`·`unit`·`cond`(`src`도 함께)를 돌려준다. 없는 테이블·키·`value`는 같은 오류로 실패한다.

## 2. 허용 오차

`verification.tolerance`가 우선이다(F5 Q-6). 코드에 오차 값을 따로 적지 않는다.

| 스펙 단위 | 오차 ID | 현재 값 |
| --- | --- | --- |
| `px`(치수) | `verification.tolerance["dimension"]` | ±1.0 |
| `px`(글꼴 크기 항목) | `verification.tolerance["font_size"]` | ±0.5 |
| `hex`(색) | `verification.tolerance["color_channel"]` | 채널마다 ±1 step |
| 그 밖(`ms`, `count`, `chars`, `ratio`) | 없음 | 정확히 같아야 한다 |

- 비교는 논리 px(rem 16 기준)로 한다. `Rems` 상수는 `rem::BASE_REM_PX`를 곱해 px로 바꾼다.
- 반올림해서 맞추지 않는다. 차이가 오차 안이면 통과다.

## 3. 조건(cond)

- 테스트는 기대하는 `cond`를 함께 적는다. 스펙의 `cond`가 다르면 값과 관계없이 실패한다(조건이 다른 값을 잘못 고르는 것을 막는다).
- `cond` 값은 `[conditions.*]` 이름이다. 헬퍼는 조건을 해석·환산하지 않는다(toml 값은 이미 논리 px).
- `reference_mocha`·`reference_latte`·`reference_image_200` 조건 항목(색·이미지 판독)은 레이아웃 테스트 대상이 아니다.

## 4. 실패 메시지

한 줄, 영어, ID를 맨 앞 가까이에 둔다.

```text
spec id not found: titlebar["heigth"] (spec/zed-metrics.toml)
spec cond mismatch: project_panel["item.height"] expected cond=project_panel_comfortable, spec cond=project_panel_standard
spec mismatch: titlebar["height"] expected 32 px (±1, cond=default, src=01-LAYOUT 4.1절 L-21), actual 31 px
```

- 이 형식과 2절의 오차 규칙은 헬퍼 코드 주석에도 한 줄씩 남긴다(R-7 "테스트 코드나 그 주석").

## 5. P1-3 대상 추천

P0-6 "반복 측정 및 V2 이전 후보"(`specs/v0.3/verify/reviews/measure-p0.md`) 10줄 가운데:

1. **S1 타이틀 바**: `titlebar["height"]`(32), `titlebar["window_button.width"]`(36), `titlebar["window_button.height"]`(32). 코드 `metrics::TITLE_BAR_HEIGHT`·`WINDOW_BUTTON_WIDTH`·`WINDOW_BUTTON_HEIGHT`(px 고정). 매 Phase 첫 화면이라 가장 자주 잰다.
2. **S2 프로젝트 패널 행**: `project_panel["item.height"]`(26, cond `project_panel_comfortable`). 코드 `panel_view.rs` `ROW_HEIGHT`(rem). Rems 환산과 cond 확인을 함께 보여 주는 예시다.

뺀 것: S1 사이드바 기본 폭·푸터(375/31, Q-15·Q-9 기준선 불일치), S4 툴팁·S5·S6 메뉴(문구·글꼴 조건에 따라 변함), S3 탭 슬롯(probe 보강 전).

## 6. 테스트 형태 (사용자 확정 2026-11-03, H-24)

- `#[gpui::test]`로 실제 렌더 경계를 재려면 gpui-kit의 `test-support` 기능이 필요하다. `Cargo.toml` `[dev-dependencies]` 변경이라 사용자 승인 대상이다(HERDR-SETUP 6.5).
- 확정: Cargo는 바꾸지 않는다. P1-3은 일반 `#[test]`로 위 상수를 스펙 ID 기대값과 대조한다. 렌더 경계 대조는 V3(덤프 JSON, P1-4·P1-5)가 맡는다.
- 상수가 아닌 계산 값(행 깊이별 들여쓰기 등)은 이 카드 범위가 아니다.

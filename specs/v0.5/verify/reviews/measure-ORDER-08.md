# measure-ORDER-08 — ORDER-08 V3 실측 판정 보고 (I-5, I-19, I-22)

- **카드**: `specs/v0.5/cards/C-35.md`, `C-35-R1.md` (상위 지시: core ORDER-08)
- **작성일**: 2026-11-07
- **수행자**: gpui-checker (agy)
- **자료 디렉터리**:
  - `specs/v0.5/verify/reviews/measure-ORDER-08-run2/` (2차 실행 16:43)
  - `specs/v0.5/verify/reviews/measure-ORDER-08-run3/` (3차 실행 16:53)
  - `specs/v0.5/verify/reviews/measure-ORDER-08-run4/` (4차 실행 17:02)
  - `specs/v0.5/verify/reviews/measure-ORDER-08-run5/` (5차 실행 17:10)
- **원칙**: 측정값은 gpui-leader가 제공한 실측치만 전사하며 새로 임의 측정하지 않는다.

---

## 1. V3 화면 실측 대조표

| 스펙 ID / 항목 | 기대값 (Zed) | 앱 측정값 (gpui) | 차이 | 판정 | 근거 및 캡처 경로 |
|---|---|---|---|---|---|
| `statusbar.padding_x` / 왼쪽 버튼 박스 x | 4, 33, 64, 94 | 4, 33, 64, 94 (덤프: 아이콘 박스 8, 37, 68, 98, 14폭) | 0 | **PASS** | `measure-ORDER-08-run2/` (사이드바 닫힘, stdout 덤프) |
| `statusbar.left_divider.*` (구분선 x) | 28, 59 | 28, 59 | 0 | **PASS** | 계산 일치 (K-26-R1 단위/레이아웃 테스트) |
| `tooltip.project_search` (Ctrl-Shift-F) | 위치 및 문구 Zed 캡처 일치 | Zed 캡처와 동일 ("Project Search Ctrl-Shift-F") | 0 | **PASS** | `measure-ORDER-08-run2/app-step7-tip-search.png` |
| `statusbar.group_gap` / `5:11 (5 characters)`·`Markdown` 간격 | 19 | 19 | 0 | **PASS** | `measure-ORDER-08-run3/app-step3-selection.png` |
| `statusbar.filetype` (rs, json, jsonc, ts, txt) | 각 파일 형식명 일치 | Rust, JSON, JSONC, TypeScript, Plain Text 정상 표시 | 0 | **PASS** | `measure-ORDER-08-run2/app-step4-type-*-right.png` |
| `diagnostics.toolbar.icons` x | 1343, 1369, 1395, 1421 | 1344, 1370, 1396, 1422 | ±1 | **PASS** | `measure-ORDER-08-run2/app-step9-diagnostics.png` (허용 오차 이내) |
| `diagnostics.empty_message` y | 466 | 465 | -1 | **PASS** | `measure-ORDER-08-run2/app-step9-diagnostics.png` (허용 오차 이내) |
| `editor.search_bar.*` 뒤 잉크 x (필터) | 1179 | 1181 | +2 | **PASS** | `measure-ORDER-08-run4/app-step8-search-empty.png` (허용 오차 ≤2) |
| `editor.search_bar.*` 뒤 잉크 x (바꾸기) | 1204 | 1205 | +1 | **PASS** | `measure-ORDER-08-run4/app-step8-search-empty.png` (허용 오차 ≤2) |
| `editor.search_bar.*` 뒤 잉크 x (‹ 이전) | 1242 | 1242 | 0 | **PASS** | `measure-ORDER-08-run4/app-step8-search-empty.png` |
| `editor.search_bar.*` 뒤 잉크 x (› 다음) | 1263 | 1263 | 0 | **PASS** | `measure-ORDER-08-run4/app-step8-search-empty.png` |
| `search_results.count.*` 뒤 잉크 x (개수) | 1283 | 1285 | +2 | **PASS** | `measure-ORDER-08-run4/app-step8-search-empty.png` (허용 오차 ≤2) |
| `editor.search_input.max_width` / 입력 박스 끝 x | 1167 | 1167 | 0 | **PASS** | `measure-ORDER-08-run3/` |
| `editor.search_input.text_inset` / 글자 시작 x | 291 | 292 | +1 | **PASS** | `measure-ORDER-08-run3/` (허용 오차 이내) |
| `project_search.landing.*` (빈 화면 세로 잉크 y) | 377, 407, 441, 466, 493, 519, 545 | 377, 407, 441, 466, 493, 519, 545 | 0 | **PASS** | `measure-ORDER-08-run5/app-step8-search-empty.png` (사이드바 열림, 영역 540–1440, 중심 990) |
| `project_search.landing.*` (빈 화면 부제 잉크 폭) | 251 (Zed 709–960) | 251 (앱 861–1112) | 0 | **PASS** | `measure-ORDER-08-run5/app-step8-search-empty.png` |
| `project_search.landing.*` (빈 화면 블록 왼쪽 x, 중심 기준) | -131 (Zed 709 − 840) | -129 (앱 861 − 990) | 2 | **PASS** | `measure-ORDER-08-run5/app-step8-search-empty.png` (허용 오차 ≤2) |
| `project_search.landing.*` (글자 크기) | 14 (소스 `TextSize::Default`) | 14 (`TEXT_SIZE_DEFAULT`) | 0 | **PASS** | 소스 값 14로 캡처 폭(251) 일치 확인 (4차 "≈13" 추정은 12px 렌더 비교 오류로 규명) |
| `search_results.header.*` (결과 머리 띠 및 버튼) | 전체 폭 둥근 띠 (x 245–1420), `Open File Alt-Enter` 오른쪽 끝 정렬 | Zed 화면과 동일하게 전체 폭 둥근 띠 및 오른쪽 끝 정렬 확인 | 0 | **PASS** | `measure-ORDER-08-run3/app-step8-search-results.png` |

---

## 2. 측정 불가 항목 (대체 검증)

1. **미리보기 클릭 (R-19)**:
   - 측정 불가 사유: 블록 probe 미제공
   - 대체 검증: K-24 V1 단위 테스트 통과 (`ui::status::tests::k24_innermost_preview_block_lines`)
2. **Replace 뒤 버퍼 dirty 유지 및 디스크 보존 (R-22, K-29 A)**:
   - 측정 불가 사유: V3 스크립트에서 실제 Replace(치환) 동작을 트리거하지 않음 (안전 가드)
   - 대체 검증: K-29 V1 단위 테스트 통과 (`ui::project_search::tests::k29_replacement_does_not_touch_the_disk`) 및 코드 레벨 안전 경로 확인 완료 (사용자 확인 필요)

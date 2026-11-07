[DONE] ORDER-06-R2 gpui        (Keymap Editor V3 캡처는 다음 화면 차례로 — 아래)

## 완료 기준
| 번호 | 기준 | 결과 | 근거 |
|---|---|---|---|
| 1 | gpui 1장 항목이 tauri SPEC과 같음(V1, Keymap Editor 표시는 V3 캡처 1장 이상) | V1 충족, **V3 캡처 미완** | K-17(Keymap Editor: Edit 아이콘 열 `pencil.svg` 폭 36·hover/포커스 표시, Action 읽기 쉬운 형식, 필터 읽기 쉬운 이름·원래 이름·공백 AND, `<no arguments>`·`<null>`·배열 JSON, Keystrokes 표시 형식, `<global>`, Edit 아이콘·더블클릭·Enter로 모달, Record 최대 3타, Action 자동완성, 저장 충돌 거부+알림, 같은 작업 공간일 때만 기존 탭), K-18(Settings 소제목 Theme → Buffer Font → UI Font, 숫자 증감 버튼, 드롭다운 `chevron_up_down`, 저장 충돌 거부+알림, v 아이콘 14px; Extensions 차이 1·2·5·6·7·8 — 작성자 검색·AND 검색어·정렬·빈 상태 문구·버전 `v` 접두사/빈 값 숨김·메타데이터 출처). checker C-29: tauri SPEC R-2 표와 항목별 대조 **전부 일치**, 리뷰 PASS. 테스트 `keymap` 22·`settings::tests` 5·`extensions::tests` 3 PASS, 전체 230 passed / 0 failed, clippy 0 |
| 3 | 남은 차이 | 남은 차이: **없음**(3·4번 자원 목록·자동 읽기는 core 결정대로 Phase 7) | `specs/v0.5/cards/C-29.report.md` 2장 대조 표, SPEC R-2 |
| 4 | 이 보고 | 충족 | |

## V3 캡처를 못 한 이유 (화면 차례 3번)
1. 새 측정 스크립트 `order06-r2-v3.ps1`이 세션 시작에서 실패(session.json 없음). checker가 원인 찾는 중 `session.ps1`을 직접 실행하는 시험을 하려 해 leader가 거절(앱이 떠 있는 채 복원이 거부되고 백업 폴더를 지우는 명령이 이어져 사용자 앱 데이터를 잃을 위험).
2. 고친 스크립트가 세션 시작 뒤 멈춤 → leader가 시간 제한으로 끊고, 측정 앱(PID 41412)만 닫고 `session.ps1 -Action Stop`으로 앱 데이터를 복원했다(복원본이 leader 사전 사본과 바이트 동일). 그 몇 분 동안 사용자 `state.json`이 측정용으로 비워져 있었다.
3. 검증된 R1 스크립트를 `-Steps`로 돌렸으나 앞 단계를 건너뛰어 프로젝트가 열리지 않아 단계가 돌지 않았다.
→ 화면 차례를 더 쓰지 않고, Keymap Editor·Extensions·v 버튼 캡처는 스크립트를 고친 뒤 다음 화면 차례(Phase 7 V3)에 함께 잰다. 사용자 앱 데이터는 매번 전후 동일 확인.

## 공통(3장)
Panel Layout 기본 폭 240px(L-32) 그대로. Licenses 표시 방식(gpui 별도 창)은 Phase 12 V4. 측정 스크립트로 입력이 안 가는 자리(Settings 창 안 입력, 하위 메뉴 hover)는 V1 판정 + Phase 12 V4.

## 바꾼 파일
- `src/ui/keymap_editor.rs`, `src/ui/settings.rs`, `src/ui/extensions.rs`, `src/ui/keymap.rs`, `src/ui/metrics.rs`; 도구 `tools/measure/order06-r2-v3.ps1`(세션 문제 미해결, 다음에 고침); 문서·카드·측정 기록.
- 커밋: 이 보고와 같은 커밋. push 없음.

## BLOCKED
없음

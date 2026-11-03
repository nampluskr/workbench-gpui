# P2-F — Phase 2 최종 확인

- 일자: 2026-11-04. reviewer. 사용자 요청 작업.
- 검증 checkout: master `7465d39d400f895ae16e3d6d0a410b4f41447585`.
- 리뷰 diff: `v0.3-phase-1..0f814a7 -- src`. `0f814a7..7465d39 -- src` 차이 없음. 시작 시 작업 트리는 깨끗했다.
- 범위: AGENTS 7.1a Phase 최종 확인, R-10 재감사, R-12 판정. src 수정·커밋·앱 실행 없음.

What this change does: 여러 UI 파일의 치수·글꼴 크기·일부 시간 상수를 metrics.rs에 모은다. 닫기 버튼과 그림자 색은 theme.rs로 옮기며 기존 렌더 흐름과 값은 유지한다.

## 정확성 및 ponytail-review

변경한 12개 파일의 전체 diff와 상수 사용부, rem 환산 함수, 설치된 gpui-pre 0.3.10의 Styled 구현을 읽었다. 단일 사용자 Windows 편집기의 기존 부하를 전제로 검토했다. 구체적인 수정 필요 결함은 발견하지 못했다.

| 확인 대상 | 기존 → 변경 후 | 판정 |
| --- | --- | --- |
| 글꼴 별칭 | gpui `styled.rs:545` text_xs는 font_size에 rems(0.75)만 설정, :552 text_sm은 rems(0.875)만 설정. text_size도 font_size만 설정 | 동일 |
| TEXT_SIZE_DEFAULT / SMALL | rems_from_px(14/12), BASE_REM_PX=16 → 0.875/0.75rem. 기존 줄 높이·상속을 추가로 변경하지 않음 | 동일 |
| 메뉴 | 폭 200px, 최대 높이 비율 0.75, padding 4/6, gap 16, 글꼴 14, 줄 높이 1.618, 구분선 1px·여백 6, 모서리 4/8, offset -5, 창 여유 8px, 이름 글꼴 12·gap 4·padding 6 | 기존 타입·값 동일 |
| 키보드 메뉴 위치 | x/y 2px, fallback도 2px | 동일 |
| 프로젝트 패널 | 행 26, indent 20, padding 6, gap 4, icon 16, guide offset 15·inset 4·폭 1px, segment padding/radius 2, input 24, banner padding 4/8·글꼴 14·offset -1/-0.5px | 동일 |
| 기타 배치 | 타이틀 gap 2·폴더 이름 padding 6, 사이드바 gap 4, 안내 버튼 padding 8/4·radius 4, 안내 본문 padding/gap 8, 탭 아래 1/16rem | 동일 |
| 툴팁 | 바깥 여백 8/10, 안쪽 4/8, 글꼴 14/12, 최대 폭 288, gap 16, radius 8, 두 줄 gap 8/4·separator padding 4·높이 1px | 동일 |
| 시간 | 저장 debounce 500ms, 메뉴 flash 50ms·chord 1s, 항목 이름 tooltip 1500ms | 동일 |
| 닫기 버튼 | hover rgb(0xE81120)·white(), active rgba(0xE81120CC)·rgba(0xFFFFFFCC) | 호출 함수·반환 타입·값 동일 |
| elevation_2 | 첫 색 hsla(0,0,0,0.12), offset (0,2)·blur 3·spread 0; 둘째 색 dark 0.06/light 0.03, offset (0,1)·blur/spread 0; inset false | 다크/라이트 분기 포함 동일 |
| 개발용 측정 | black()를 그대로 반환, 스크롤 x=px(0) → Pixels::ZERO | 동일 |

`Rems(0.)`는 기존 rems_from_px(0.)와 같은 0rem이다. 계산식·입력 핸들러·비동기 세대 보호·저장 및 오류 처리 흐름을 바꾸지 않았다. 메뉴 두 곳이 기존처럼 같은 치수를 사용하고 `elevation_2_shadow`는 앱 메뉴·컨텍스트 메뉴·툴팁에서 계속 재사용한다. 의존성·설정·추상화 추가는 없다. 같은 값의 상수 이동에 별도 테스트 증설은 요구하지 않았다.

Looks good. Ship.

Verdict: Ship.

## R-10 재감사: PASS

아래 rg 검색은 모두 결과 0행이다(명령은 `rtk`로 실행). 첫 두 검색은 src 전체에서 해당 관리 파일만 제외했다.

```text
rtk rg -n '\b(px|rems_from_px)\(\s*-?[0-9]' src --glob '!metrics.rs'
rtk rg -n '\b(rgb|rgba|hsla|white|black)\s*\(|0x[0-9A-Fa-f]{6,8}\b|#[0-9A-Fa-f]{6,8}\b' src --glob '!theme.rs'
rtk rg -n 'const .*(: (Pixels|Rems|Duration|f32)|= (px|rems_from_px|Duration))|Duration::from_' src/ui/app_menu.rs src/ui/panel_view.rs src/ui/tooltip.rs src/ui/title_bar.rs src/ui/folders.rs src/ui/panel_menu.rs
```

추가로 `rems(...)`, `Pixels(...)`, `Rems(...)`, text_sm/text_xs 및 스타일 메서드의 직접 숫자 인자도 검색했다. 남은 것은 panel_view.rs:323~324의 `Rems(0.)` 두 곳뿐이다. 이는 0을 나타내는 gpui 타입 값이며 TASKS P2-1의 집계 대상인 px(숫자)·rems_from_px(숫자) 잔여가 아니다. 동적 px(y), px(w as f32), 깊이×상수 환산도 크기 리터럴로 세지 않았다. 프레임워크 border_1 같은 기본 스타일은 기존 정책대로 유지한다. AUDIT 6 밖 Duration은 범위에서 제외했다.

따라서 지정된 감사 범위의 크기 리터럴 0건, theme.rs 밖 색 리터럴 0건, 글꼴 별칭 잔여 0건이다. 스펙이 없는 앱 값은 metrics/theme 주석에 별도로 표시되어 있으며, 코드 값을 스펙 값으로 바꾸지 않았다.

## 자동 검증

`CARGO_TARGET_DIR=D:\projects\workbench-gpui\target`, PATH에 `%USERPROFILE%\.cargo\bin`을 추가하여 실행했다.

| 명령 | 결과 |
| --- | --- |
| `rtk cargo test` 전체 1회 | PASS: 56 passed, 0 failed |
| `rtk cargo clippy --all-targets -- -D warnings` | exit 1: 기존 경고 10건이 오류로 처리됨. 신규 0건 |

clippy 위치는 P1-2-3-4.md 기준선과 같다: dev.rs:266·270, fsops/ident.rs:53, names.rs:99, tree.rs:201, state/mod.rs:13, ui/keymap.rs:520, layout.rs:143·395, watch.rs:274. clippy 명령 자체를 통과로 기록하지 않으며 사용자가 지정한 기준선 대비 신규 여부만 통과로 판정한다.

## R-12 판정: PASS

`verify/phase2/README.md`, `comparison.json`, `reviews/measure-phase2.md`를 기존 `verify/baseline/README.md` 기준선과 대조했다. 초기 클립보드 도우미 경로 오류로 SKIP된 phase4 계열은 수정 후 1회 재실행한 최종 결과로 판단했다.

| 스크립트 | 기준선 → Phase 2 |
| --- | --- |
| phase1 | 9사례, failures 0 → 동일. R-1 바인딩표·사례 이름 동일 |
| phase2 | 137/0 → 137/0 |
| phase3 | 120/2 → 120/2 |
| phase4 | 208/0 → 208/0 |
| phase4-d043 | 13/0 → 13/0 |
| phase4-d044 | 6/0 → 6/0 |
| phase5 | 62/0 → 62/0 |
| phase5-d046 | 23/0 → 23/0 |
| phase5-d047 | 16/0 → 16/0 |

checks 배열이 있는 8개 스크립트는 합계 587개 중 585 통과·2 실패로 양쪽이 같다. phase3 R-28 시작 폭 375(기대 300), 복원 폭 617(기대 494)은 기준선 그대로다. phase3 GUID 경로와 phase5 이벤트 수 1818→1825가 포함된 항목 이름 차이는 양쪽 ok=True이며 ok 뒤바뀜은 없다. d043-clip SKIP과 휴지통 내부·복원 판정 불가는 그대로 남는다. comparison.json은 모든 got/expect 문자열의 동일성을 검사하지 않으므로 모든 실행 측정값의 완전 동일성을 보장하는 결과로 확대하지 않는다.

V3 기록에서는 S1~S7의 변경 대상 배치가 유지되었고, 안내 화면·상태 표시줄·타이틀 바·메뉴·라이트 툴팁 그림자는 해당 PNG 영역 차이 0이다. 경로 없음 안내 화면은 변경 전 exe와 전체 PNG 차이 0이다. 시험 폴더 marker 파일 차이로 트리 목록·탭 이름 및 폭 비교가 제외된 부분과 S3/S5 툴팁 표시 시점 차이를 동작 회귀로 계산하지 않았다. 관련 상수·타입은 위 코드 대조에서도 동일했다.

닫기 hover/active 색은 기존 리터럴과 측정 기록이 대응한다. 글리프 안티앨리어싱 ±3 판정은 측정자의 기록이며 새 스펙 허용 오차로 승인한 것이 아니다. 다크 그림자 렌더는 미측정이지만 코드의 0.06 분기가 보존된 것은 확인했다.

## 한계 및 전달

- 실측 필요·사용자 확인 필요: 측정자가 남긴 다크 툴팁 그림자 렌더 미측정, 글꼴 크기 px 자체 판정 불가, fixture 차이로 인한 탭 이름·폭 직접 비교 제외를 그대로 전달한다. 이 리뷰에서는 추가 실행하지 않았다.
- PROGRESS·TASKS·HANDOFF는 lead 소유다. P2-F 사용자 요청 작업 결과로 이 파일을 전달한다.
- Not checked: 앱 실행·화면 조작·V3 재측정·R-12 재실행은 하지 않았다. 기존 환경상 SKIP·판정 불가 항목은 해결되지 않았다.

결론 PASS

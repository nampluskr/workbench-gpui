# POC-TABLE — workbench-gpui v0.1 Phase 2 (편집기 PoC)

> 작성: wg-coder · 2026-11-01 · 대상: SPEC R-6~R-11 (02-gpui G-100·G-101·G-102·G-129·G-139)
>
> gpui-kit 0.8.1(gpui-component 0.8.1, gpui-base 0.8.1)의 `Editor`·`Input`을 PoC 화면(`--dev-editor-poc`, 디버그 빌드 전용)에 그대로 띄워 확인했다. 소스 위치는 `~/.cargo/registry/src/<index>/` 아래 크레이트 기준 경로다. 증거 파일은 모두 이 폴더(`specs/v0.1/verify/phase2/`)에 있다.

## 읽는 법

- **gpui-kit 지원**: 지원 / 일부 / 미지원 / 판정 불가.
- **직접 구현 필요**: 필요 / 불필요. 모든 행에 결정과 근거를 적는다(SPEC R-11). "판정 불가" 행도 결정을 적는다.
- 측정 배율은 200%(DPI 192)다. 수치는 논리 px.
- 증거 수집 스크립트: `tools/verify-ime.ps1`(R-6), `tools/verify-phase2.ps1`(R-7 화면·R-8·R-9·R-10).

## 판정표

### G-100 한글 IME (R-6)

| 항목 | gpui-kit 지원 | 직접 구현 필요 | 증거 |
| --- | --- | --- | --- |
| Editor: 조합 중 표시 | 지원. 조합 중인 "한"이 밑줄과 함께 편집 위치에 보인다 | 불필요. 조합 중 표시가 gpui-kit 기본 동작으로 나온다 | `r6-editor-composing.png`, `r6-ime.json` |
| Editor: 후보창 위치 | 지원. 한자 키로 연 후보창이 조합 중인 글자 바로 아래에 붙어 뜬다 | 불필요. IME 가 조합 위치를 받아 후보창을 그 아래에 둔다 | `r6-editor-candidate.png` |
| Editor: 확정 | 지원. "한 가나 "가 Editor 값에 들어갔다 | 불필요. 확정 글자가 값에 반영된다 | `r6-ime.json` editor.committedTextFound=true, `r6-editor-committed.png`, `r6-stdout.txt` |
| Input: 조합 중 표시 | 지원 | 불필요. Editor 와 같은 결과 | `r6-input-composing.png` |
| Input: 후보창 위치 | 지원. 후보창이 조합 중인 글자 바로 아래에 뜬다 | 불필요. Editor 와 같은 결과 | `r6-input-candidate.png` |
| Input: 확정 | 지원. Input 값이 "한 가나 " | 불필요 | `r6-ime.json` input.committedTextFound=true, `r6-input-committed.png` |

자동화 방법: 대상 창의 기본 IME 창(ImmGetDefaultIMEWnd)에 WM_IME_CONTROL 로 IME 를 열고 변환 모드를 한글로 바꾼 뒤(전후 값은 `r6-ime.json`), SendInput 가상 키(g,k,s / 한자 / Esc / Space / r,k,s,k / Space)를 보냈다. 한자 키 뒤 새로 나타난 최상위 창은 목록에서 찾지 못했다(`newWindowsAfterHanja` 빈 배열). 후보창 위치는 모니터 전체 캡처로 판정했다.

판정 방법(리뷰 1회차 반영): 스크립트가 자동으로 판정하는 것은 IME 상태 조회 성공(음수 실패값 아님)·IME 열림·한글 모드와, 확정 글자가 값에 있는가다. 하나라도 실패하면 종료 코드 1 이다(2026-11-01 재실행: 두 필드 모두 open 1, mode 1, committedTextFound true, errors 0). 조합 중 밑줄 표시와 후보창 위치는 자동 판정이 없어 `r6-ime.json` 의 visualCheck 에 "수동 판정 대기"로 남겼다. 위 표의 그 두 항목은 wg-coder 가 스크린샷을 눈으로 보고 적은 판정이며, 검증 담당의 확인이 필요하다.

### G-101 Editor 동작 지원 범위 (R-7)

| 항목 | gpui-kit 지원 | 직접 구현 필요 | 증거 |
| --- | --- | --- | --- |
| 거터: 줄 번호 최소 4자리 | 일부. 최소 3자리로 고정(`MIN_LINE_NUMBER_DIGITS = 3`, 비공개 상수, 설정 없음) | 필요. 4자리로 바꾸는 공개 설정이 없어 거터 폭 계산을 우리 쪽에서 맞춰야 한다 | gpui-base `src/input/base/element.rs` 56·61행, `r7-editor.png` |
| 현재 줄 강조 범위 | 지원. 활성 줄 배경을 입력 상자 왼쪽 끝(거터 포함)부터 전체 폭으로 칠한다. 색은 테마 `editor.active_line.background` | 불필요. 범위는 기본 동작으로 나온다. 색은 테마 매핑(G-106) 때 맞춘다 | gpui-base `src/input/base/element.rs` 3252~3279행 |
| 커서 2px | 미지원. 커서 폭 1px 고정(`CURSOR_WIDTH = px(1.)`, 비공개) | 필요. 폭을 바꾸는 설정이 없다. 측정도 1 논리 px | gpui-base `src/input/base/blink_cursor.rs` 7행, `r10-pixels.json` cursors(폭 1.00) |
| 커서 500ms 깜빡임 | 지원. `INTERVAL = 500ms` | 불필요. 같은 값이다 | gpui-base `src/input/base/blink_cursor.rs` 4행 |
| 선택 모서리 0.15×줄 높이 | 미지원. 선택 영역을 직선 다각형(PathBuilder, 둥글림 없음)으로 그린다 | 필요. 둥근 모서리 선택 그리기를 직접 만들어야 한다 | gpui-base `src/input/base/element.rs` 813~822행(layout_match_range), 2537행(frame_outline_points) |
| 더블 클릭 단어 선택 | 지원 | 불필요 | gpui-base `src/input/base/state.rs` 2727행(select_word) |
| 트리플 클릭 줄 선택 | 지원 | 불필요 | gpui-base `src/input/base/state.rs` 2721행(select_line) |
| Alt+클릭 다중 커서 | 지원 | 불필요. 같은 조작이다 | gpui-base `src/input/base/state.rs` 2759행(add_cursor_at) |
| Ctrl+Shift 드래그 열 선택 | 일부. 열 선택은 있으나 조작이 Alt+Shift 드래그다(Linux 는 Ctrl+Alt 도) | 필요. 조작 키가 다르고 바꾸는 설정이 없다 | gpui-base `src/input/base/state.rs` 2750~2756행 |
| 선택 끌어 옮기기 | 미지원. 끌기는 선택 확장(on_drag_move)뿐이고 선택 글자를 끌어 옮기는 처리가 없다 | 필요 | gpui-base `src/input/base/state.rs` 3969행(on_drag_move), 소스 전체에서 끌어 놓기(drop) 처리 없음 |
| soft wrap | 지원. `soft_wrap(bool)`·`set_soft_wrap`. 기본값 켜짐 | 불필요. 켜고 끄기는 설정으로 된다. Zed 기본값에 맞춰 앱이 값을 정한다 | gpui-base `src/input/base/state.rs` 12141·12147행, 952행(기본 true), PoC `--dev-no-wrap` |
| 들여쓰기 안내선 | 지원. 코드 편집기 모드 기본 켜짐 | 불필요. 모양·색 대조는 테마 단계에서 한다 | gpui-base `src/input/base/mode.rs` 45행, `src/input/base/element.rs` 3167행, `r7-editor.png`(6행 안내선) |
| 공백 표시 | 일부. `show_whitespaces(bool)` 켜고 끄기만 있다 | 불필요. 켜고 끄기는 된다. Zed 의 세부 모드(선택 영역만 등)를 쓸지는 이후 결정이다 | gpui-base `src/input/base/state.rs` 1505·1511행, `src/input/base/element.rs` 1231행 |
| 스크롤바 15px | 일부. 기본 스크롤바 폭 16px(`WIDTH = 4*2+8`). Editor 는 스크롤바 렌더러를 바꿀 수 있다(`set_scrollbar_renderer`) | 필요. 15px 스크롤바를 렌더러로 직접 그려야 한다 | gpui-base `src/scrollbar.rs` 22행, `src/input/base/state.rs` 1148행, `src/input/scrollbar_presentation.rs` 49행 |
| 스크롤바 마커 | 미지원. 스크롤바에 마커를 그리는 처리가 없다 | 필요. 위 렌더러에서 직접 그린다 | gpui-base `src/scrollbar.rs`, `src/input/` 에서 marker 처리 없음(검색) |

### G-102 큰 파일 (R-8)

측정 방식(leader 승인 HERDR-DECISIONS D-014, 리뷰 1회차 반영 D-016): 앱 내부에서 변경(set_value·set_scroll_offset·insert)을 적용한 시점부터, **그 변경이 그려진 프레임의 draw·present 가 끝난 뒤**까지의 시간이다. gpui-pre 0.3.10 은 한 프레임 핸들러 안에서 `on_next_frame` 콜백 → `window.draw` → `window.present` 를 차례로 동기 실행한다(`src/window.rs` 1878~1912행). 그래서 콜백에서 foreground 작업을 예약하고, 그 작업이 실행되는 시점(프레임 핸들러가 끝난 뒤)에 시간을 잰다. 측정마다 그 시점까지 화면이 실제로 다시 그려졌는지(EditorPoc::render 횟수 증가)를 세었고, 모든 측정에서 그려졌다(drawn=20/20, 첫 프레임 drawn=true). 이 값에는 다음 화면 갱신까지 기다린 시간도 들어 있다. 실제 키 입력부터 화면까지의 지연은 아니다. 측정 파일은 줄마다 약 78바이트(한글 포함)다. SPEC R-8 에 통과 기준 수치는 없다.

빌드는 둘이다. **opt** = 최적화 빌드에 debug_assertions 만 켠 것(`CARGO_PROFILE_RELEASE_DEBUG_ASSERTIONS=true`, 별도 폴더 `target\opt-dbgassert`, dev 플래그가 동작하게). **debug** = 일반 디버그 빌드. 판정은 opt 기준이다. 스크롤·입력은 각 20회.

| 항목 | gpui-kit 지원 | 직접 구현 필요 | 증거 |
| --- | --- | --- | --- |
| 10만 줄 열기 (soft wrap 켜짐, 기본값) | 일부. opt: 읽기 180ms, set_value 165ms, 그 뒤 첫 프레임 draw·present 까지 7,619ms. 5만 줄은 3,880ms. debug 는 10만 줄 15,589ms | 필요. 첫 프레임 지연이 문서 전체의 줄바꿈(wrap) 계산 때문이다(아래 wrap 끔 행과 비교). 큰 파일에서는 wrap 을 끄거나 보이는 범위만 계산하는 처리를 우리 쪽에서 정해야 한다. gpui-kit 소스 주석도 "약 5만 줄까지"라고 적었다 | `r8-perf-opt.json`, `r8-100k-opt-stdout.txt`, `r8-50k-opt-stdout.txt`, `r8-perf-debug.json`, gpui-base `src/input/base/state.rs` 12262행 |
| 10만 줄 열기 (soft wrap 끔) | 지원. opt: set_value 158ms, 첫 프레임 draw·present 까지 302ms (debug 1,316ms) | 불필요. wrap 을 끄면 열기가 1초 안에 끝난다 | `r8-perf-opt.json`(r8-100k-nowrap-opt), `r8-100k-nowrap-opt-stdout.txt` |
| 10만 줄 스크롤 | 지원. opt: 변경→draw·present 이후 평균 11.71, 최소 4.16, 최대 19.53ms (wrap 끔 평균 12.30, 최대 19.62 / 5만 줄 평균 11.52, 최대 20.28). 25,000번째 줄까지 이동 확인 | 불필요. 지연이 줄 수(5만·10만)와 wrap 여부에 따라 달라지지 않아 큰 파일 때문에 생기는 비용이 아니다. 최대 약 20ms(60Hz 기준 약 1.2 프레임)다 | `r8-perf-opt.json`(last_visible_rows 25000..25042, drawn=20) |
| 10만 줄 입력 | 지원. opt: 50,000번째 줄에 글자 입력→draw·present 이후 평균 12.70, 최소 8.65, 최대 18.11ms (wrap 끔 평균 11.97, 최대 18.08 / 5만 줄 평균 11.92, 최대 17.36) | 불필요. 스크롤과 같은 이유로 줄 수·wrap 에 따라 달라지지 않는다 | `r8-perf-opt.json`(drawn=20), `r8-100k-opt-after.png` |

### G-129 줄 끝·인코딩 (R-9)

방식: naive = UTF-8 로 읽고(잘못된 바이트는 U+FFFD) UTF-8 로 쓴다(인코딩 처리를 안 했을 때). app = BOM·UTF-8 유효성으로 인코딩을 고르고 같은 인코딩으로 다시 쓴다(CP949 는 Win32 MultiByteToWideChar/WideCharToMultiByte). 두 방식 모두 Editor 에 `set_value` 한 뒤 Editor 의 `value()` 를 다시 읽어 저장했다.

| 항목 | gpui-kit 지원 | 직접 구현 필요 | 증거 |
| --- | --- | --- | --- |
| LF UTF-8 열기→저장 | 지원. naive·app 모두 바이트 같음(62→62) | 불필요 | `r9-roundtrip.json`, `r9/` |
| CRLF 보존 (UTF-8) | 지원. Editor 가 `\r` 을 글자로 그대로 두어 naive·app 모두 바이트 같음(65→65) | 불필요. 줄 끝이 그대로 보존된다. 다만 상태 표시줄 줄 끝 표시·변환은 앱 몫이다 | `r9-roundtrip.json`, gpui-base `src/input/base/rope_ext.rs` 89~142행(`\r` 포함 주석), `src/input/base/element.rs` 4699행 |
| UTF-16 LE (BOM) | 미지원. Editor 는 문자열만 받는다. naive 는 바이트가 달라짐(96→126, 0바이트째부터) | 필요. 인코딩 감지·변환을 앱이 한다. app 방식으로 바이트 같음(96→96) 확인 | `r9-roundtrip.json`, `r9/out-naive-crlf-utf16le-bom.txt`, `r9/out-app-crlf-utf16le-bom.txt` |
| CP949 | 미지원. naive 는 바이트가 달라짐(56→76, 5바이트째부터) | 필요. 앱이 감지·변환한다. app 방식(Win32 코드 페이지 949, 새 크레이트 없음)으로 바이트 같음(56→56) 확인 | `r9-roundtrip.json`, `r9/out-app-crlf-cp949.txt` |
| CP949 로 옮길 수 없는 글자 (저장 손실) | 미지원(Editor 는 인코딩을 다루지 않는다) | 필요. 앱의 CP949 인코딩이 손실을 오류로 막아야 한다. `WC_NO_BEST_FIT_CHARS` 로 best-fit 치환을 막고, 두 호출의 반환값·used_default 를 검사하고, 결과를 다시 풀어 원문과 같은지 확인한다. 시험: U+20A9(₩)·U+00A5(¥)는 오류, 한글·역슬래시는 손실 없이 왕복(4/4 통과) | `r9-cp949-selftest.json`, `r9/r9-cp949-selftest-stdout.txt`, `r9/r9-cp949-unittest.txt`(cargo test 4 passed), `src/dev.rs` cp949_encode |

### G-139 한글 대체 글꼴 (R-10)

측정 글꼴(leader 승인, HERDR-DECISIONS D-014): gpui-kit 기본 고정폭 글꼴. 이 PC 에서는 `Consolas` 13px 로 정해졌다(`r10-stdout.txt` measure font). Consolas 에는 한글이 없어 한글 글자 묶음은 대체 글꼴로 그려진다. gpui 가 알려 준 그 묶음의 글꼴 이름은 `.SystemUIFont` 다(gpui 의 시스템 UI 글꼴 별칭). DirectWrite 가 실제로 고른 글꼴 파일 이름은 이 방법으로는 알 수 없었다. Zed 글꼴(.ZedSans/.ZedMono) 도입은 DECISIONS 미결 사항에 있다.

| 항목 | gpui-kit 지원 | 직접 구현 필요 | 증거 |
| --- | --- | --- | --- |
| 줄 높이 | 지원. 영문 줄·한글 줄·혼합 줄 모두 20 (Editor 줄 높이 고정, 행 간격 20) | 불필요. 대체 글꼴이 섞여도 행 높이가 바뀌지 않는다 | `r10-stdout.txt` measure line(세 줄 y 89·109·129, 높이 20), `r10-pixels.json` |
| 기준선 | 일부. 잉크 아래 끝(상자 위에서): 영문 줄 14, 혼합 줄의 영문 15, 한글 16. 배치 결과 ascent 가 영문 줄 11.96 → 한글이 있는 줄 14.15 로 커진다 | 필요. 한글이 섞인 줄은 영문 기준선이 1 논리 px 내려가 줄마다 영문 높이가 달라진다. Zed 기준 화면과 맞추려면 기준선을 줄 단위로 고정하는 처리가 필요하다(Zed 글꼴 도입 때 다시 잰다) | `r10-pixels.json`(inkBottom), `r10-stdout.txt` measure font(ascent) |
| 글자 폭 | 지원(측정만). 10글자: 영문 71.47(7.15/자), 한글 130.00(13.00/자, 영문의 1.82배). 혼합 "abc"·"def" 각 21.44, "가나다" 39.00 | 불필요. 폭은 글꼴이 정하는 값이다. 한글이 영문 2배 폭이 아니어서 고정폭 정렬이 맞지 않는 점은 글꼴 선택(미결) 문제로 둔다 | `r10-stdout.txt` measure line·segment, `r10-pixels.json`(inkWidth) |
| 거터 | 지원. 편집기 왼쪽 끝에서 글자 시작까지 45.44. 한글 줄도 같다 | 불필요. 대체 글꼴이 거터 폭에 영향을 주지 않는다(줄 번호 4자리는 G-101 행에서 따로 결정) | `r10-pixels.json` gutterLogical, `r10-stdout.txt` measure line(x 60.44 공통) |
| 커서 위치 | 지원. 줄 끝 커서 x: 영문 131.92, 한글 190.44, 혼합 142.33(= 줄 시작 60.44 + 줄 폭). 높이 17, y 는 줄 위 +1.5 | 불필요. 커서가 대체 글꼴 글자 끝에 정확히 놓인다 | `r10-stdout.txt` measure cursor, `r10-measure.png` |

## R-11 요약

모든 행에 직접 구현 필요/불필요 결정과 근거가 있다. 판정 불가 행은 없다.

**직접 구현 필요 (12건)**

1. 거터: 줄 번호 최소 4자리 (gpui-kit 3자리 고정)
2. 커서 2px (gpui-kit 1px 고정)
3. 선택 모서리 0.15×줄 높이 (gpui-kit 직선)
4. Ctrl+Shift 드래그 열 선택 (gpui-kit 은 Alt+Shift)
5. 선택 끌어 옮기기 (gpui-kit 없음)
6. 스크롤바 15px (gpui-kit 16px, 렌더러 훅으로)
7. 스크롤바 마커 (gpui-kit 없음, 렌더러 훅으로)
8. 큰 파일 + soft wrap 켜짐 열기 (10만 줄 첫 프레임 draw·present 까지 7.6초, opt)
9. UTF-16 LE 열기·저장 (앱이 인코딩 감지·변환)
10. CP949 열기·저장 (앱이 인코딩 감지·변환)
11. CP949 로 옮길 수 없는 글자의 저장 손실 막기 (best-fit 금지·반환값·역변환 검사)
12. 한글 혼합 줄 기준선 (영문 기준선이 1 논리 px 내려감)

**직접 구현 불필요**: IME 6항목(Editor·Input 조합 표시·후보창 위치·확정. 조합 표시·후보창 위치는 스크린샷 판정), 현재 줄 강조 범위, 커서 500ms 깜빡임, 더블·트리플 클릭, Alt+클릭 다중 커서, soft wrap 켜고 끄기, 들여쓰기 안내선, 공백 표시(켜고 끄기), 10만 줄 열기(wrap 끔)·스크롤·입력, LF·CRLF UTF-8 보존, 줄 높이·글자 폭·거터·커서 위치(대체 글꼴 영향).

**판정 불가**: 없음.

**남는 조건**: R-10 은 gpui-kit 기본 고정폭 글꼴(Consolas)로 쟀다. Zed 글꼴 도입(DECISIONS 미결) 때 기준선·폭을 다시 잰다.

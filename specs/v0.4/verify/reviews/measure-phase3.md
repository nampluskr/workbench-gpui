# measure-phase3 — Phase 3 끝 R-15 재실행 + V3 새 화면 (카드 P3-E)

- 실행일: 2026-11-04, measure. 대상: master `37be418`(`cargo build` 오류 0, `apply-manifest.ps1` 적용). exe는 `%TEMP%\wbg-measure\37be418\workbench-gpui.exe` 사본만 썼다(H-11). SHA-256 `BACDBA5A…E2491`.
- 조건: 주 모니터 1920×1080, 100%, 최대화(뷰포트 1920×1032), 앱 기본 테마·폰트. 스펙 기준은 논리 px(100%라 같음).
- 앱 데이터(`%APPDATA%\workbench-gpui`)는 모든 실행 뒤 복원됨(`_backup/after.json`, `_backup-rerun/after.json`, `measure-phase3/_backup/after.json` 모두 restored=true).

## 1. R-15 (원본 `tools/verify-v02-*.ps1`, `-Exe` 사본, `-OutDir …\baseline\phase3\<이름>`)

실행기·대조기: `baseline/phase3/run-phase3.ps1`, `compare.ps1`(phase2b 것에서 경로·exe만 바꿈). 두 번 나눠 돌렸다.
- 1차 `run-phase3.ps1` 9개: phase1은 `r1-expected.tsv`를 `-OutDir`에 복사하지 않아 실패(phase2b에선 손으로 복사). phase4 3개는 클립보드에 텍스트 아닌 형식이 있어 시작 전에 중단.
- 2차 `run-phase3-rerun.ps1`: tsv 복사 + 클립보드 비운 뒤 phase1·phase4·phase4-d043·phase4-d044 다시(1차의 같은 이름 결과를 덮어씀). 사용자는 자리를 비운 상태이며 클립보드를 비우는 것은 phase2b와 같은 절차다.
- 스크립트당 1회씩, 총 실행 exit: phase1 1, phase2 1, phase3 1, phase4 1, d043 0, d044 0, phase5 1, d046 0, d047 0.

### 1.1 대조 표 (R-1 기준)

| 스크립트 (`verify-v02-` 생략) | R-1 통과/실패 | Phase 3 통과/실패 | 항목 수 | 값이 다른 항목 | 분류 |
|---|---|---|---:|---:|---|
| phase1 | 70 / 0 | 70 / 0 (+실패 3, 아래) | 70 | 0 | 의도한 변경(실패 3) |
| phase2 | 137 / 0 | **88 / 1, 항목 89개만 실행** | 89 | 55 | 의도한 변경(File 메뉴 1·툴팁 6) + **미평가 48(스크립트가 중단)** |
| phase3 | 120 / 2 | 121 / 1 | 122 | 7 | 의도한 변경 6 + 이력상 흔들림 1 |
| phase4 | 208 / 0 | 207 / 1 | 208 | 4 | 의도한 변경 4(실패 1 포함) |
| phase4-d043 | 13 / 0 | 13 / 0 | 13 | 0 | 변화 없음 |
| phase4-d044 | 6 / 0 | 6 / 0 | 6 | 0 | 변화 없음 |
| phase5 | 62 / 0 | 57 / 5 | 62 | 7 | 의도한 변경 5(실패 5건 전부) + 이력상 흔들림 2(1.2의 9·10) |
| phase5-d046 | 23 / 0 | 23 / 0 | 23 | 0 | 변화 없음 |
| phase5-d047 | 16 / 0 | 16 / 0 | 16 | 0 | 변화 없음 |

**실패 항목 전수(원본 스크립트 결과). 실제 회귀 0, 미설명 0.**

| # | 스크립트 / 사례 / 항목 | expect | got | 분류 |
|---|---|---|---|---|
| F1 | phase1 / base / 내장 바인딩 "R-1 표 밖" ×3 | R-1 표 | `ctrl-s workspace::Save`, `ctrl-w pane::CloseActiveItem`, `ctrl-f4 pane::CloseActiveItem` | 의도한 변경: Save(P3-2)·탭 닫기(P3-3) 키가 내장 키맵에 추가됨. 스크립트 전제(R-1 키 표가 전부)가 깨짐. `ctrl-w`·`ctrl-f4`는 lead 목록에 없음 — P3-3에서 들어옴(`ca5afb4`) |
| F2 | phase2 / menu / R-8 D-13 I-306 File 항목·구분선 | `Open Folder…\|Ctrl-K Ctrl-O ─ Close Window\|Ctrl-Shift-W` | `… ─ Close Editor\|Ctrl-F4  Close Window\|Ctrl-Shift-W` | 의도한 변경: 탭 닫기(P3-3)가 File에 Close Editor 추가. lead 목록엔 없음 |
| F3 | phase2 / menu / "null 배열로 인덱싱할 수 없습니다" | — | F2 직후 스크립트 중단 | F2의 후속: 스크립트가 `$orig` 표에 없는 행 이름(Close Editor)을 찾다 죽음. **이후 menu 항목 48개(I-303~I-520 등)와 reload·pending·shadow·prevctx·shadowpp·rapid·chord·quit·closewin 사례가 실행되지 않았다 = R-15 미평가** |
| F4 | phase3 / menus / R-8 9.2 File 메뉴 | 위 F2와 같은 기대 | 위 F2와 같은 실제 | 의도한 변경(F2와 같은 원인) |
| F5 | phase4 / readonly / D-18·R-27 글자를 쳐도 탭 내용이 안 바뀐다 | `len=31(LF) fnv=a8bbf6a77956b073, 디스크 같음` | `len=40 fnv=1cd7c3303d70c90d, 디스크 같음=True` | 의도한 변경: 탭 편집 허용(D-18 읽기 전용 전제 해제). 글자가 들어갔고 디스크는 안 바뀜(자동 저장 없음) |
| F6 | phase5 / tab / R-24·E-086·G-115 활성 탭 자동 다시 읽음 | `active_text_fnv=f3333c130cb7fa10`, tab-reload `len=40` | `reloaded len=38 fnv=facef83d0e9eaa58`, 스크립트가 fnv 불일치로 대기 실패(ok=False) | 의도한 변경: 앱 내부 문자열 LF 정규화(D-6·H-15) — CRLF 파일의 길이 2(줄 2개)·fnv 변화. reload 자체는 일어남 |
| F7 | phase5 / tab / R-24 tab-reload 줄의 길이·FNV | `len=40 fnv=f3333c130cb7fa10` | `len=38 fnv=facef83d0e9eaa58` | 의도한 변경(F6과 같은 원인) |
| F8 | phase5 / tab / R-24·G-115 바꿔 넣은 파일도 다시 읽음 | `fnv=f44fa1bf2ed7155c`, len=56 | `len=54 fnv=97899cbe95ed7094` | 의도한 변경(LF 정규화) |
| F9 | phase5 / tab / D-18·E-087 지운 파일의 탭은 그대로 | `fnv f44fa1bf2ed7155c` | `fnv=97899cbe95ed7094`(탭 2개·README.md 활성은 같음) | 의도한 변경(LF 정규화). "표시는 이후 버전" 전제는 P3-4b로 이제 표시됨(아래 V3) |
| F10 | phase5 / tab / R-24·G-115 다시 만든 파일을 탭이 읽음 | `fnv=eeb42a408f255ae4`, len=34 | `len=32 fnv=79dfa0fcb8242014` | 의도한 변경(LF 정규화) |

### 1.2 통과했지만 값이 다른 항목

| # | 항목 | R-1 | Phase 3 | 분류 |
|---|---|---|---|---|
| 1 | phase3 / state / R-28 시작 폭 | 375 | 300 | 의도한 변경(Phase 2) |
| 2 | phase3 / state / R-28 A-22 `sidebar.width` | 494 | 419 | 의도한 변경(Phase 2, 기대·실제 모두 419) |
| 3 | phase3 / state-restart / R-28 복원 폭 | 617 | 419 | 의도한 변경(Phase 2) |
| 4 | phase3 / items / A-11.3 | 374 | 299 | 의도한 변경의 결과(폭 -75) |
| 5 | phase2 / tooltip / L-208·L-209 × 6 (#4,#9,#14,#25,#30,#50) | 403/488/368/641/667/399 | 328/413/293/566/592/324 | 의도한 변경의 결과(전부 정확히 -75) |
| 6 | phase4 / menu / I-042·I-502 × 2 | `377.0,217.0` | `302.0,217.0` | 의도한 변경의 결과(x -75) |
| 7 | phase4 / readonly #1 R-27 탭 내용 길이 | len=33 | len=31 | 의도한 변경(LF 정규화) |
| 8 | phase3 / scroll / A-16.7 `offset_y` | -23 | -234 | 이력상 흔들림(H-10, `baseline/phase2b/history-values.txt`에 두 값 모두 이력 있음) |
| 9 | phase5 / flood / R-24 `watch-applied events` | 1815 | 1806 | 이력상 흔들림(이전 1806은 phase2b에 있음, v0.3~ 범위 1811~1831 근처) |
| 10 | phase5 / flood / R-24(묶기) 이벤트 N | 1815 | 1806 | 9와 같은 값 |

**합계:** 값이 다르거나 실패한 항목 중 의도한 변경 + 이력상 흔들림으로 설명됨. **미설명 0. 실제 회귀 0.** 단 **phase2의 menu 후속 48개 항목과 그 뒤 사례는 평가 못 함(F3)** — 이 부분은 R-15 공백이다.

### 1.3 참고(판정 아님): `verify-v02-phase2-patched.ps1` 사본

lead 질문: "patched phase2"는 무엇을 어디서 고친 것인가. **`tools/verify-v02-phase2.ps1`은 고치지 않았다.** `baseline/phase3/verify-v02-phase2-patched.ps1`(원본의 복사본)에서 딱 두 줄만 바꿨다: ① 45행 `$CaptureScript`를 `$PSScriptRoot` 대신 `tools\capture.ps1` 절대경로로(사본이 다른 폴더에 있어서), ② 585행 File 메뉴 기대 행에 `Close Editor|Ctrl-F4`를 넣음. 결과: File 메뉴 항목은 통과했지만(menu 89 checks, failed 0) **여전히 같은 "null 배열" 오류로 중단** — `$orig` 표(582행)에도 Close Editor가 없어서이며, 더 고치지 않았다(AGENTS 9장 취지). 이 사본의 결과는 **판정에 쓰지 않았고** 참고로만 `verify-v02-phase2-patched/`에 남겼다. 이 공백을 메우려면 lead가 phase2 스크립트를 새 버전용으로 갱신하라는 별도 카드가 필요하다.

## 2. 자동 레이아웃 (`tools/measure/check-layout.ps1 -Exe <사본>`)

exit 0, **28항목 전부 PASS**(허용 오차 0). 보고서: `reviews/_check-layout-phase3.md`. 사이드바 default_width 300 포함.

## 3. V3 새 화면 (첫 구현, 앱 1회 실행)

`tools/measure/session.ps1`(Start `-Json`, Snapshot `-Capture`, Stop) + `input.ps1`(Maximize·Click·DoubleClick) + 이 폴더의 `drive.ps1`(글자 입력·키), `dlg.ps1`(확인창 캡처). 조작: 폴더 추가 → `file-001.txt` 더블클릭 → `X` 입력 → Ctrl-W → 대화창 캡처 → 닫기 → 디스크에서 파일 변경 → 파일 삭제. 눈대중 판정 없이 PNG 픽셀을 셌다(`S2·S3·S4.png`, 점 영역 x 601~617, y 33~65).

| 스펙 ID | 상태 | 기대 | 측정 | 판정 | 증거 |
|---|---|---|---|---|---|
| `tab["indicator_size"]` (L-65) | 글자 하나 입력한 dirty 탭의 수정 점 | 지름 10 px | 경계 x 606~615, y 43~52 = **10×10** | PASS | `S2.png` |
| L-65 수정됨 = Accent 색 | 위와 같음 | Accent | RGB (23,23,23). 스펙에 색 값이 없어 값 대조 불가 — **앱은 theme.primary로 근사**(P3-4b-1 shortcut 주석). 판정: 없음(사용자 확인 필요) | 판정 불가 | `S2.png` |
| L-65 슬롯 | 점 위치 | 시작 슬롯 12×12(L-25) 중앙 | 탭 x 601 + 슬롯 → 점 x 606~615(슬롯 안, 가운데) | PASS(코드 레이아웃과 일치) | `S2.png` |
| A-13.4·I-069 / E-081 닫기 저장 질문 | Ctrl-W로 dirty 탭 닫기 | 제목 Warning, 본문 "`file-001.txt` contains unsaved edits. Do you want to save it?"(상대 경로, 인라인 코드), 버튼 **Save / Don't Save / Cancel** 순서 | 같은 문구·같은 순서(`[dev] task-dialog-open … buttons=Save\|Don't Save\|Cancel`, 창 제목 "Warning", 352×155) | PASS | `closesave-dialog.png` |
| E-086 충돌 점 = Warning 색 | 열린 dirty 탭 파일을 디스크에서 바꿈(`tab-reload result=conflict`) | Warning 색(수정 점과 다른 색) | 점 같은 위치·크기(10×10), 색 **(234,179,8)**(주황 계열) — 수정 점 (23,23,23)과 다름 | PASS(색 구별). Warning의 정확한 값은 스펙 toml에 없음 | `S3.png` |
| E-087 지운 파일 탭 취소선 | 열린 파일을 디스크에서 지움(`result=deleted`) | 제목에 취소선, 내용 있으면 dirty | 라벨 폭 67 px 전체를 덮는 가로선 1줄(y=50) 있음(`S3`엔 없음). 점은 계속 표시(Warning 색 유지, 충돌에서 이어짐) | PASS | `S4.png`, `S4-tab-zoom.png` |

- 대화창 닫기: Esc를 보냈으나 입력 스크립트가 메인 창을 먼저 활성화하는 과정에서 대화창이 이미 닫혔고(`focus-state active=true`), Esc는 편집기에 들어갔다(`key keystroke=escape action=none`). 닫힌 방식(취소 버튼 클릭이 아님)은 직접 확인하지 못했다. 결과로는 탭이 남고 dirty 유지(`tab-reload result=dirty`), 파일 길이 21 그대로 → Save·Don't Save가 아니라 취소로 해석된다. 이후 디스크 변경·삭제는 내가 만든 픽스처 파일만 건드렸다.
- V3 불일치 **0**. 측정 불가 1(수정 점 Accent 색 값).

## 4. 요약

- R-15: 의도한 변경 + 이력상 흔들림으로 모두 설명됨, **미설명 0, 실제 회귀 0**. **공백: phase2 menu 이후 48항목(스크립트 전제 깨짐 F2·F3).**
- check-layout: 28/28 PASS.
- V3: 불일치 0, 측정 불가 1(Accent 값), 사용자 확인 필요: 수정 점이 Accent 근사(theme.primary)로 near-black(23,23,23)인 점, Warning 색 (234,179,8)이 Zed와 같은지.

## R1 — phase2 menu 공백 메우기 (카드 P3-E-R1, H-21)

- 스크립트: `specs/v0.4/verify/scripts/verify-v04-phase2.ps1`(원본 `tools/verify-v02-phase2.ps1`의 사본, **원본은 그대로**). 바꾼 곳은 3곳·6줄뿐이다: ① `$CaptureScript`를 `tools\capture.ps1` 절대경로로(사본 위치가 달라서), ② `$orig` 표에 `'Close Editor' = @('pane::CloseActiveItem','Ctrl+F4')` 추가, ③ File 메뉴 기대 행에 `Close Editor|Ctrl-F4` 추가. 다른 기대값은 안 바꿨다. diff: `specs/v0.4/verify/scripts/verify-v04-phase2.diff`.
- 실행: 사본 exe `37be418`(SHA `BACDBA5A…E2491`), `-OutDir specs\v0.4\verify\baseline\phase3\verify-v04-phase2`, 시작 전 프로세스 없음·클립보드 비움, **1회**. 앱 데이터 restored=True. 결과: **checks 137, failed 0, 단축키 행 32개 불일치 0, failures 0.** 중단 없이 11개 사례(tooltip, menu, reload, pending, shadow, prevctx, shadowpp, rapid, chord, quit, closewin) 전부 실행됨.
- 대조(`baseline/phase3/compare-v04-phase2.ps1`, 기존 compare.ps1과 같은 규칙, 기준 R-1): 항목 137/137, 통과 137/137(R-1 137/0), 시간 값만 다름 23, **값이 다른 항목 8:**

| # | 사례 / 항목 | R-1 | R1 실행 | 분류 |
|---|---|---|---|---|
| 1 | tooltip / L-208·L-209 × 6 (#4,#9,#14,#25,#30,#50) | 403/488/368/641/667/399 | 328/413/293/566/592/324 | 의도한 변경의 결과(Phase 2 사이드바 폭, 전부 정확히 -75) |
| 2 | menu / I-314 | 518 | 443 | 의도한 변경의 결과(-75) |
| 3 | menu / R-8 D-13 I-306 File 항목·구분선 | `Open Folder… ─ Close Window` | `Open Folder… ─ Close Editor\|Ctrl-F4  Close Window` | 의도한 변경(P3-3 Close Editor). 비교 기준이 R-1이라 차이로 잡힘; 사본의 기대값은 이 값 |

- 이전에 미평가였던 menu 48항목(I-303·I-309·I-310·I-313·I-315~I-321·I-445·I-446·I-517~I-520 등)과 reload·pending·shadow·prevctx·shadowpp·rapid·chord·quit·closewin 사례는 **값(got)까지 R-1과 같다**(시간 값만 다름). 이 항목들에서 값이 바뀐 것은 위 #2뿐이다.
- 따라서 R-15 phase2 공백 해소: **미설명 0, 실제 회귀 0.** 1.1 표의 phase2 줄(88/1, 89개 실행, 미평가 48)은 이 R1로 대체된다(137/137 통과). 원본 스크립트(`tools/verify-v02-phase2.ps1`)는 계속 F2·F3으로 실패하며, 판정은 갱신 사본(H-21)을 따른다.

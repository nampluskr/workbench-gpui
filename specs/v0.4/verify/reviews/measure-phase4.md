# measure-phase4 — Phase 4 끝 R-15 재실행 + V3 새 화면 (카드 P4-E)

- 실행일: 2026-11-04, measure. 대상: master `4732464`(`cargo build` 오류 0, `apply-manifest.ps1` 적용). exe는 `%TEMP%\wbg-measure\4732464\workbench-gpui.exe` 사본만 썼다(H-11; 지시문의 `wbg-measure$H`는 기존 관례 `wbg-measure\<커밋>`로 읽었다). SHA-256 `204F5CC3…2BDB`.
- 조건: 주 모니터 1920×1080, 100%, 최대화(뷰포트 1920×1032), 앱 기본 테마·폰트. 스펙은 논리 px(100%라 같음).
- 앱 데이터는 모든 실행 뒤 복원됨(`baseline/phase4/_backup/after.json`·`_backup-p1/after.json` restored=true, V3 `Stop` restored=true·fixtureRemoved=true).

## 1. R-15 (원본 `tools/verify-v02-*.ps1`, phase2만 H-21 사본 `scripts/verify-v04-phase2.ps1`, `-Exe` 사본, `-OutDir …\baseline\phase4\<이름>`)

실행기·대조기: `baseline/phase4/run-phase4.ps1`, `run-phase4-p1.ps1`, `compare.ps1`, `compare-v04-phase2.ps1`(phase3 것에서 경로·exe·phase2 스크립트만 바꿈). 9개를 1회씩 돌렸다. 예외: phase1은 `r1-expected.tsv`가 `-OutDir`에 없어 1차가 항목 28개에서 멎었다(phase3 때와 같은 사정). phase3 폴더의 `r1-*`를 복사해 **phase1만 한 번 더**(`run-phase4-p1.ps1`, 같은 이름 폴더를 덮어씀) 돌렸다. 나머지는 1회씩이다.

### 1.1 대조 표 (R-1 기준, 값 `got`까지)

| 스크립트 (`verify-v02-` 생략) | R-1 통과/실패 | Phase 4 통과/실패 | 항목 수 | 값이 다른 항목 | 분류 |
|---|---|---|---:|---:|---|
| phase1 | 70 / 0 | 54 / 16 | 70 | 28 | 의도한 변경(실패 13 + 컨텍스트 값 28) |
| phase2 (사본) | 137 / 0 | **93 / 16, 항목 109개만 실행** | 109 | 55 | 의도한 변경 + **미설명 3** + **미평가 28** |
| phase3 | 120 / 2 | 120 / 2 | 122 | 8 | 의도한 변경 7 + 이력상 흔들림 1 |
| phase4 | 208 / 0 | 207 / 1 | 208 | 4 | 의도한 변경(Phase 3 것) 4 |
| phase4-d043 | 13 / 0 | 13 / 0 | 13 | 0 | 변화 없음 |
| phase4-d044 | 6 / 0 | 6 / 0 | 6 | 0 | 변화 없음 |
| phase5 | 62 / 0 | 57 / 5 | 62 | 9 | 의도한 변경 5(Phase 3과 같은 got) + 이력상 흔들림 4 |
| phase5-d046 | 23 / 0 | 23 / 0 | 23 | 0 | 변화 없음 |
| phase5-d047 | 16 / 0 | 16 / 0 | 16 | 0 | 변화 없음 |

(phase1의 "통과/실패"는 스크립트 자체 집계 `failures: 16`. 비교기는 키맵 사례 항목을 비교하므로 값이 다른 항목 28은 아래 1.2의 컨텍스트 문자열이다.)

### 1.2 분류

**의도한 변경 (Phase 4)**

| # | 스크립트 / 항목 | R-1(또는 Phase 3) | Phase 4 | 근거 |
|---|---|---|---|---|
| 1 | phase1 / base 실패 13: `ctrl-k shift-enter` TogglePinTab, `ctrl-shift-v` OpenPreview, `ctrl-k v` OpenPreviewToTheSide, `ctrl-\` SplitRight, `ctrl-k up/down/left/right` Split·`ctrl-k ctrl-↑↓←→` ActivatePane, `shift-escape` ToggleZoom | R-1 표 밖 | 내장 바인딩 추가 | 새 키(핀·분할·미리보기 키 I-731 등). 나머지 3(`ctrl-s`·`ctrl-w`·`ctrl-f4`)은 Phase 3 것 |
| 2 | phase1 / base·override·null·unknown·jsonc·broken·order·startup·reload 28항목 `context` | `Root > Workspace` | `Root > Workspace > Pane` | 새 키가 Pane 컨텍스트를 요구해 center 영역에 `Pane` key_context 추가(`reviews/P4-2-3b.md` 78행, PANE_CONTEXT). 키·액션 값은 같다 |
| 4 | phase3 / add#4, menus#1 File 메뉴 | `… Close Window` | `… Close Editor\|Ctrl-F4 … Close Window` | Phase 3(P3-3) |
| 5 | phase3 / menus#2 View 메뉴 행 | `Toggle Left Dock … Project Panel` | 분할·확대 행 추가 | Phase 4 View 메뉴 분할·확대 항목 |
| 6 | phase3 / items#5, state#2·#4, state-restart#1, phase4 / menu#12·#13, phase2 / tooltip ×5(#4·#9·#14·#25·#30), menu#11 | R-1 값 | 정확히 −75 | Phase 2 사이드바 폭(Phase 3 보고와 같은 값) |
| 7 | phase4 / readonly#1·#3 | len=33 / 33·fnv | len=31 / 40·fnv | Phase 3(LF 정규화·탭 편집), Phase 3 보고 F5와 같은 값 |
| 8 | phase2 / menu#4 | File 메뉴 `Close Window` | `Close Editor` 행 추가 | H-21 사본이 기대값에 반영 |
| 9 | phase2 / menu#6, reload#1·#4, shadow#1, prevctx#1, shadowpp#1, chord#1 (View 메뉴 행 문자열) | 행 5개 | 행 10개(분할·확대 추가) | 5와 같은 원인 |
| 10 | phase2 / menu#14·#17·#18·#19 (I-315·I-318 구분선·여백 기하) | 5 / 1 / 6 / 6 | 110 / 23 / 0 / 0 | 스크립트가 View 메뉴의 `menu-row-03·04`를 옛 구분선 위치로 가정. 구분선 위치가 행 증가로 바뀜 → 9의 후속(스크립트 전제) |
| 11 | phase2 / menu#27~#29·#31·#37·#39 (I-517·I-518 down/up/end 항목) | index=4 / 0 | 3 / 4 / 9 | View 메뉴가 항목 10개라 `end`가 9. 9의 후속 |
| 12 | phase2 / menu#42 (I-309 닫은 뒤 포커스 컨텍스트) | `Root > Workspace` | `Root > Workspace > Pane` | 2와 같은 원인 |
| 13 | phase5 / tab#2·#3·#6·#9·#10 실패 5 | R-1 | Phase 3 때와 **같은 got**(`len=38 fnv=facef83d…`, `len=54 fnv=97899cbe…`, `len=32 fnv=79dfa0fc…`) | Phase 3 보고 F6~F10(LF 정규화) |

**이력상 흔들림 (H-10)**: phase3 / scroll#2 A-16.7는 이번엔 값이 R-1과 같아 차이 없음. phase5 / flood#2·#3 R-24 이벤트 수 1815 → 1823(이전 Phase 3은 1806; 1806~1831 범위 안). phase5 / tree#10·#12 `watch-applied events=3` → 4 / 2(`ok=True`, 같은 조건에서 매번 달라지는 OS 감시 이벤트 개수. R-24 판정은 통과). 이력 근거: `baseline/phase2b/history-values.txt`·Phase 3 보고 1.2의 9·10(이벤트 수 흔들림). **tree#10·#12는 이력 파일에 값이 없어 같은 종류로 본 추정이다 — lead 확인 필요.**

**미설명 (회귀 후보, 원인 단위 3, 항목 30)**

| # | phase2 / 사례 / 항목 | R-1 | Phase 4 | 원인 파악 |
|---|---|---|---|---|
| U1 | tooltip#32~#59 (28항목: L-243 New…, L-244 Split Pane, L-245 Zoom In, L-254·L-266 Close Left Dock, L-206/L-207/L-208~L-210 위치·사라짐, L-228, L-253·L-266) | New…·Split·Zoom 툴팁 등 | `tab-btn-new: 레이아웃 스냅숏에 경계가 없다. 입력을 보내지 않고 중단` → 뒤 28항목 **미평가** | **첫 화면(폴더 없음)의 탭 바에서 끝 단추(`tab-btn-new`·`-split`·`-zoom`)가 사라졌다.** `src/ui/pane_view.rs` 폴더 없는 분기가 `layout::tab_bar(&[], None, …)`로 끝 단추를 안 그린다(P4-3b `6ec2df9`). Phase 3까지는 첫 화면에 단추가 있었다(R-1 tooltip#32~이 통과). check-layout S1 박스 목록에도 `tab-btn-new` 없음. P4-2-3b 리뷰 48행이 "focused(활성 pane일 때만 버튼)"를 후속 실측으로 넘겼을 뿐 **첫 화면에서 숨기는 결정은 어느 문서에도 없다** |
| U2 | menu#7 I-303 `이름 hover → 메뉴 3` | `index=3` | `<없음>`(3초 안에 menu-open 로그 없음) | 못 찾음. menu#8(Window 메뉴 항목)은 통과해 메뉴 3 자체는 있다. 흔들림 가능성 있음 — 이 한 번으로는 구분 불가 |
| U3 | menu#50 I-519 `메뉴 밖 누름 닫기` | `reason=click-outside` | `(로그 없음)` | 못 찾음. 스크립트의 바깥 누름 좌표가 이제 Pane 영역(분할·핀 처리)에 닿는지 미확인 |

→ **미설명: U1 28항목·U2 1·U3 1 = 30항목, 원인 단위 3(U1은 원인 파악·결정 문서 없음).**
**실제 회귀 의심: U1(첫 화면 끝 단추 사라짐)**. U2·U3은 phase2 스크립트를 한 번 더 돌리거나 입력 좌표를 열어 봐야 가른다(이번 지시는 1회만이라 하지 않았다).

**phase2 미평가(스크립트 중단): U1 이후 tooltip 사례 28항목**. 그 뒤 menu·reload·pending·shadow·prevctx·shadowpp·rapid·chord·quit·closewin은 **끝까지 돌았다**(109항목 실행, 중단은 tooltip 사례만).

## 2. 자동 레이아웃 (`tools/measure/check-layout.ps1 -Exe <사본>`)

exit 0, **28항목 전부 PASS**(허용 오차 0). 보고서: `reviews/measure-phase4/check-layout.md`. S1은 폴더 없는 첫 화면이다(U1의 끝 단추 없음은 이 목록에 항목이 없어 PASS로 가려진다).

## 3. V3 새 화면 (첫 구현, 앱 1회 실행)

조작: 앱 1회 실행 → 폴더 추가(`sidebar-btn-folder-add`) → 행 한 번 클릭(미리보기 탭) → 같은 행 더블클릭(고정) → 다른 행 클릭 → 탭 클릭 → `Ctrl-K` `Shift-Enter`(핀) → 눈 단추 클릭(마크다운 미리보기) → 탭 바 분할 단추 → `Split Right` → 탭 누른 채 끌기(캡처) → 놓기. 도구: `session.ps1`(Start·Snapshot `-Capture`·Stop), `input.ps1`, 이 폴더의 `drive.ps1`(키), `hold.ps1`(누른 채 끌기), `px-runs.ps1`·`px-row.ps1`(PNG 픽셀 띠·색 구간). 데이터는 픽스처(`target\measure-<GUID>`: 텍스트 80개 + 이 보고서용 `AAA-sample.md`)만 썼다.

| 스펙 ID | 상태 | 기대 | 측정 | 판정 | 증거 |
|---|---|---|---|---|---|
| `tab["bar_height"]` L-22 | 미리보기·핀·분할 탭 바 | 32 | 덤프 `tab-bar` h 32(모든 pane) | PASS | `S3`·`S7`·`S7e-dump` |
| `tab["content_height"]` L-23 | 탭 | 31 | 위 아래 경계 y32·y64 1px, 사이 y33~63 = **31** | PASS | `S7.png` px |
| I-060 미리보기 탭 글자 기울임 | 파일 한 번 클릭 | 기울임 | 코드 `.when(tab.preview, \|d\| d.italic())`(layout.rs:386) + `S3.png`에서 `AAA-sample.md`·`file-001.txt`가 기울어 보임. **픽셀 판정은 하지 않았다(기울기 값 스펙 없음)** | 코드 확인 | `S3.png` |
| L-66·I-063 핀 탭 아이콘 | `Ctrl-K Shift-Enter` 뒤 | 끝 슬롯 14×14(`tab["end_slot.*"]` L-25) | 핀 글자 잉크 x728~741·y41~54 = **14×14**, 탭 끝(탭 x601~747, 폭 146 불변) | PASS | `S4.png` |
| 핀 묶음(핀 탭과 일반 탭 구분) | 핀 1 + 일반 1 | **스펙 값 없음** | 핀 탭이 맨 앞, 사이 구분은 일반 탭 경계와 같은 1px(x746 rgb 229). 묶음 구분선·간격 없음 | 판정 불가(스펙 없음) | `S4.png` |
| L-69 미리보기(마크다운) 탭 제목 | 눈 단추 | `Preview <파일명>` + 책 아이콘, 기울임 없음 | 탭 `Preview AAA-sample.md`, 책 아이콘, 기울임 없음. 폭 217 | PASS(코드·화면) | `S5.png` |
| `markdown_preview["max_width"]` L-101 | 창 폭 1380의 pane | 800 | 본문 x830~1629 = **800**, 가운데(좌우 여백 290) | PASS | `S5.png` px |
| `markdown_preview["container_padding"]` L-102 | 위 여백 | 16 | 탭 바 아래 y65 → 첫 블록 y81 = **16** | PASS | 위 |
| `markdown_preview["h1~h6.font_size"]` L-104 | 'H' 대문자 높이로 비교(글꼴 같음, 비 = 크기 비) | 28 / 22.4 / 19.2 / 16 / 14 / 13.6 | 높이 **20 / 16 / 14 / 12 / 10 / 10** (= 0.714·크기: 20.0 / 16.0 / 13.7 / 11.4 / 10.0 / 9.7 반올림과 일치) | PASS(비율) | `S5.png` |
| `markdown_preview["body.font_size"]` L-103 | 본문 'P' | 16 | 'P' 높이 **12**(= 0.714×16 = 11.4 반올림) | PASS(비율) | 위 |
| `markdown_preview["h1.border_bottom"]`·`["h1.padding_bottom"]` L-105 | `# Heading One` 아래 | 하단 1px 선 + 아래 여백 8 | y215~229 구간에 정경계 없음(차이 임계 2에서도 0). 코드에 상수 없음(`markdown_preview.rs`는 L-104 글자 크기만) | **불일치**(미구현) | `S5.png` px |
| `markdown_preview["h2.border_bottom"]`·`["h2.padding_bottom"]` L-105 | `## Heading Two` 아래 | 1px 선 + 4 | y314~330 구간 선 없음 | **불일치**(미구현) | 위 |
| `markdown_preview["blockquote.border_left"]` L-106 | 인용 | 4 | x830~833 = **4**, 색 (229,229,229) | PASS | `S5.png` px |
| `markdown_preview["table.border_outer"]` L-107 | 표 | 1.5 | 바깥선 **1px**(렌더 반올림, 허용 ±1 안) | PASS(±1) | 위 |
| `markdown_preview["table.cell_padding_*"]` L-107 | 표 셀 | 가로 10·세로 4 | 머리 행 안쪽 높이 30, 몸 행 30 = 4×2 + 줄 22. **줄 높이 24(L-103)와 맞는지는 표 줄 높이 스펙이 없어 판정 불가** | 판정 불가 | 위 |
| `markdown_preview["link.underline_*"]` L-108 | 링크 `link` | 밑줄 1px, 불투명 0.5 | 밑줄 **1px**(y245), 색 (162,162,162) → 글자색(23)에서 흰색 쪽 알파 **0.40** | **불일치(경계)**: 두께 PASS, 불투명도 0.40 ≠ 0.5(안티에일리어싱 오차일 수 있음) | `S5.png` px |
| `markdown_preview["code_block.padding"]·["margin_y"]·["frontmatter.border"]` L-109·L-111 | 코드·frontmatter | 12·16·1 | frontmatter 바깥선 **1px**(y81·147), 행 높이 32. 코드 블록 높이 47 = 1+12+21+12+1, 위 표와 간격 32(= 16+16) | PASS | 위 |
| I-724·`pane["split_line_thickness"]` I-725 | `Split Right` 뒤 두 pane | 1 | 분할선 x1230 **1px**(rgb 229), 두 pane 폭 690 + 690(`active-item` 1230~1920) | PASS | `S7.png` px |
| `pane["split_line_mouse_hitbox"]` I-725 | 분할선 | 4 | 마우스 모양 변화는 캡처로 못 본다 | 측정 불가 | — |
| `pane["directional_drop_overlay_ratio"]` I-714 | 탭을 오른쪽 pane 본문 오른쪽 끝(x=1850, 가장자리 20%=1782~1920 안)으로 끌 때 | 해당 방향 절반 | 오버레이 x1575~1919 = **345 = 690×0.5**, y65~1001(본문 전체 높이) | PASS | `S7d.png` px |
| `pane["drop_target_size_ratio"]` I-712 | 위 같은 상태 | 0.2(가장자리 20%) | 이 위치는 안쪽이라 경계 값은 확인 못 했다 | 측정 불가(경계 위치 시험은 목록 밖) | — |
| `pane["tab_drop_line_width"]` I-715 | 같은 탭 바 안에서 끌 때 삽입선 | 2 | 탭 바 안으로 끌어 보지 않았다 | 측정 불가(상태 미도달) | — |
| 오버레이 색 | 위 | `drop_target_background`(스펙 값 없음, `spec/ambiguous.md` 없음) | (206,224,253) 파란 계열 | 판정 불가(스펙 없음) | `S7d.png` |
| 놓은 뒤 | 오른쪽 가장자리에 놓기 | 오른쪽에 새 pane | pane 3개 **460 + 460 + 460**(540·1000·1460, 분할선 x1000·1460 1px), 새 pane에 끌던 탭 | PASS | `S7e.png` px |

- V3 새 화면 불일치 **3**: L-105 h1·h2 하단선·아래 여백(미구현, 상수 자체가 없다), L-108 링크 밑줄 불투명도 0.40(경계). 측정 불가 4(`split_line_mouse_hitbox`·`drop_target_size_ratio`·`tab_drop_line_width`·핀 묶음). 판정 불가 3(표 줄 높이·오버레이 색·핀 묶음 스펙).
- 목록에 있었으나 **하지 않은 것**: 오른쪽·왼쪽 외 분할 방향, 분할선 크기 조절 드래그, 확대(`zoomed_padding 8`·`zoomed_border 1`), 같은 탭 바 안 삽입선, 포커스에 따른 끝 단추 표시 변화(지시문의 V3 목록에 없었음). 기능 확인용 조작을 하지 않기로 한 3A.4 때문이다.
- 사용자 확인 필요: 미리보기 탭 글자가 기울어 보이는 정도, 핀 아이콘 모양(Segoe Fluent 글리프)과 Zed의 차이, 오버레이 색 (206,224,253)이 Zed `drop_target_background`와 같은지, 마크다운 h1·h2 하단선이 Zed에서 실제로 보이는지.

## 4. 요약

- R-15: 의도한 변경 + 이력상 흔들림으로 설명되지 않는 항목 **미설명 30항목(원인 3: U1 첫 화면 끝 단추 사라짐 28, U2 hover 메뉴 3 1, U3 바깥 누름 닫기 1)**. phase2 사본이 tooltip 사례에서 중단돼 28항목 미평가.
- check-layout: 28/28 PASS.
- V3: 불일치 3(L-105 h1·h2, L-108 불투명도), 측정 불가 4.
- [MEASURED] P4-E: 미설명 3원인(30항목) · V3 불일치 3.

## R1 — U1~U3 재측정 (카드 P4-E-R1)

- 대상: master `56f1d93`(`cargo build` 오류 0, `apply-manifest.ps1`). exe `%TEMP%\wbg-measure\56f1d93\workbench-gpui.exe` 사본(SHA `E8D29A68…95E9`)만 썼다(H-11). 앱 데이터 모두 복원(`baseline/phase4/_backup-r1`·`_backup-r1b` restored=true).
- 실행기·대조기: `baseline/phase4/run-phase4-r1.ps1`·`run-phase4-r1b.ps1`, `compare-r1.ps1`(기준 R-1, got 값까지).

### R1.1 phase2 사본 실행 두 번 (사유)

- **1차** (`verify-v04-phase2.ps1`, 지시한 1회, 결과 `verify-v04-phase2-r1`): **U1 해소** — tooltip 사례가 끝까지 돌았다(New…·Split Pane·Zoom In·Close Left Dock 등 28항목 평가됨, 값은 R-1과 같음. 예외 #45 아래). 그러나 menu 사례가 **View 메뉴 행 검사에서 `null 배열로 인덱싱할 수 없습니다`로 중단**됐다(H-21 때 Close Editor와 같은 패턴: 스크립트 `$orig`에 Phase 4가 View에 넣은 `Split Up/Down/Left/Right`·`Maximize Pane`이 없어 `$orig[$label][0]`이 null). 그 결과 menu#7(U2)·menu#50(U3) 등 menu 후속과 reload~closewin이 **미평가**(91항목)였다. 이 1차로는 U2·U3 판정을 못 한다.
- **2차** (`specs/v0.4/verify/scripts/verify-v04-phase2-r1.ps1`, 결과 `verify-v04-phase2-r1b`): 위 사본에서 **View 기대 행 1곳 + `$orig` 5항목만** 더한 사본(`scripts/make-r1.ps1`가 만든다, 바뀐 줄은 `diff` 10줄). H-21과 같은 취지(의도한 변경만 반영, 다른 기대값 불변)로 **한 번 더** 돌렸다. 이번 지시는 1회라 한 것이므로 이 점을 알린다. 결과: **137/137 항목 실행**, 스크립트 집계 실패 13, 값이 다른 항목 27.

### R1.2 U1·U2·U3 결과

| # | 항목 | 이전(4732464) | R1(56f1d93) | 판정 |
|---|---|---|---|---|
| U1 | tooltip#32~#59 28항목 | 미평가(첫 화면에 `tab-btn-new` 없음) | **평가됨, R-1과 같은 값**(#45만 아래) | **해소** |
| U2 | menu#7 I-303 `이름 hover → 메뉴 3` | `<없음>` | `index=3`, ok=True (R-1·Phase 3 R1과 같음) | **통과 → 이력상 흔들림** |
| U3 | menu#50 I-519 `메뉴 밖 누름 닫기` | `(로그 없음)` | `reason=click-outside`, ok=True (R-1과 같음) | **통과 → 이력상 흔들림** |

U2·U3 이력 근거: 같은 스크립트·같은 항목이 R-1 기준선, Phase 3 R1 실행(`baseline/phase3/verify-v04-phase2`, 137/137 통과)에서 둘 다 통과했고, 이번 R1 2차에서도 통과했다. 실패는 4732464 실행 한 번뿐이다. 그 실행은 menu#6의 View 렌더 로그도 비어 있었고(`got=` 빈 값), hover 3이 `<없음>`이었다 — 즉 View 메뉴가 3초 안에 안 그려지던 실행이다. 원인은 코드 변경이 아니라 그 한 번의 타이밍 흔들림이라는 근거는 **재현 실패(2/2 통과)** 뿐이며, 4732464의 표면에서 같은 실패가 다시 나온 적이 없다. U1을 고친 `56f1d93`가 이 두 항목에 영향을 줬을 가능성도 배제하지 못한다(1차 결과가 U2·U3을 평가하지 못해 전후를 같은 스크립트로 가를 수 없음). **회귀로 보지 않으나 원인 확정은 아님 — lead 판단.**

### R1.3 나머지 값이 다른 항목 (2차, 기준 R-1) — 미설명 0

| # | 항목 | R-1 | R1 | 분류 |
|---|---|---|---|---|
| 1 | tooltip#4·#9·#14·#25·#30·#50 L-208·L-209 | 403/488/368/641/667/399 | 328/413/293/566/592/324 | 의도한 변경(Phase 2 폭 −75) |
| 2 | **tooltip#45 L-210 `tab-btn-zoom` 상자 x** | 1,829.00 | **1,735.00** (기대값 1,735와 일치, ok) | **의도한 변경**: 확대 툴팁이 `Zoom In\|<none>` → `Zoom In\|Shift-Escape`(`rows=` 로그 확인)로 바뀌어 상자가 더 넓다(뒤집힌 x = 오른쪽 기준). Shift-Escape(ToggleZoom)가 Phase 4에서 동작 |
| 3 | menu#4 File 행 | `… Close Window` | `Close Editor` 행 추가 | Phase 3 |
| 4 | menu#6 View 행, reload#1·#4, shadow#1, prevctx#1, shadowpp#1, chord#1 | 행 5개 | 행 10개(분할·확대) | Phase 4 View 메뉴 항목 |
| 5 | menu#11 I-314 | 518 | 443 | Phase 2 폭 −75 |
| 6 | menu#14·#17·#18·#19 (I-315·I-318) | 5 / 1 / 6 / 6 | 110 / 23 / 0 / 0 | 스크립트가 구분선 위치를 `menu-row-03·04`로 가정 → View 행 증가의 후속(스크립트 전제). 의도한 변경의 결과 |
| 7 | menu#27~#29·#31·#37·#39 (I-517·I-518 항목 번호) | 4 / 0 | 3 / 4 / 9 | View가 10항목이라 `end`가 9 등. 위와 같은 후속 |
| 8 | menu#42 I-309 포커스 컨텍스트 | `Root > Workspace` | `Root > Workspace > Pane` | Pane key_context 추가(`reviews/P4-2-3b.md` 78행) |

스크립트 실패 13: 위 6·7·8과 R-5 `Split Up/Down/Left/Right·Maximize Pane`의 "화면 단축키 vs 키맵 적용 결과 `<none>`"(reload·shadow 각 5) 등 — 화면에 보이는 Pane 컨텍스트 키가 스크립트의 Workspace 컨텍스트 조회에 안 잡힌다. Phase 4 새 행의 단축키이며 스크립트 전제 한계. (Phase 3 R1은 0건이었으므로 새로 생긴 실패이며 모두 위 의도한 변경이 원인이다.)

→ **R-15 phase2: 미설명 0**(U2·U3은 통과해 흔들림 분류, 위 근거와 한계 명시). 실제 회귀 0.

### R1.4 check-layout (`check-layout.ps1 -Exe <56f1d93 사본>`)

exit 0, **28항목 전부 PASS**(허용 오차 0). 보고서 `check-layout-r1.md`.

### R1.5 V3: 첫 화면 탭 바 끝 단추

덤프 `check-layout-r1/S1-dump.txt`(폴더 없는 첫 화면, 최대화 1920×1032):

| 박스 | 기대(P4 폴더 연 화면 `S3-dump`) | 측정 | 판정 |
|---|---|---|---|
| `tab-bar-end` | 1833,33,87×32 | 1833,33,87×32 | PASS |
| `tab-btn-new` | 1840,37,22×22 | 1840,37,22×22 | PASS |
| `tab-btn-split` | 1866,37,22×22 | 1866,37,22×22 | PASS |
| `tab-btn-zoom` | 1892,37,22×22 | 1892,37,22×22 | PASS |
| `tab-icon-new/split/zoom` | 14×14 | 14×14 (x 1844/1870/1896, y 41) | PASS |

U1 복원 확인. 스펙 ID 비교는 `tab["bar_icon_size"]` 14·`end_buttons_area` 기존 값(check-layout에 항목 없음; 위 표는 폴더 연 화면과 같은 값인지만 대조).

### R1.6 요약

- [MEASURED] P4-E-R1: **미설명 0.** U1 해소(28항목 평가·R-1과 같은 값), U2·U3 통과(이력상 흔들림 분류, 근거 R1.2), check-layout 28/28, 첫 화면 끝 단추 PASS.
- 알림: phase2 사본을 **2회** 돌렸다(1차는 View 행 때문에 menu 중단 → H-21식 사본 `verify-v04-phase2-r1.ps1`로 2차). 이 사본의 변경은 `scripts/make-r1.ps1`에 있다. Phase 4 이후 R-15에는 이 `-r1` 사본을 쓰는 것이 맞다(View 행이 늘었으므로) — lead 결정.

## R2 — 기록 정정 + 누락 V3 (카드 P4-E-R2, `phase4-final.md` Must fix 1·2)

### R2.1 정정 (재실행 없음, 저장된 결과 기준). 위 본문 1.2·R1.3·1절 L-108 해당 문장은 이 절이 우선한다

1. **1.2 phase3 / scroll#2 A-16.7**: 본문은 "이번엔 값이 R-1과 같아 차이 없음"이라 썼으나 틀렸다. `baseline/phase4/comparison.json`·`_diffs.txt` 31행의 실제 값은 `sidebar-scroll offset_y=-23`(R-1) → `-234`(Phase 4)이다. 분류는 **이력상 흔들림**(H-10: 같은 코드에서 −23/−234로 갈리는 휠 입력 600ms 뒤 스크롤 표본; v0.2 재실행 5회 −234, v0.3 기준선 −23, v0.3 phase1 −234, phase2·phase3 −23, v0.4 기준선 −23 — `history-values.txt`·H-10). 스크립트 자체 판정(`offset_y < 0`)은 통과. 1.1 표 phase3의 "값이 다른 항목 8"에 이 항목이 포함되어 있다(의도한 변경 7 + 이력상 흔들림 1 — 본문 표의 합계는 맞다).
2. **R1.3 마지막 문단(실패 13건 설명)**: 틀렸다. `verify-v04-phase2-r1b/results.json`의 `ok=false` 13건은 **menu 11 + prevctx 1 + chord 1**이다.
   - menu 11 = **기하 4**(I-315 목록 아래 여백, I-318 구분선 높이·위 margin·아래 margin) + **목록 선택 인덱스 6**(I-517·I-518 down ×2·up·end·pagedown·shift-pagedown) + **포커스 컨텍스트 1**(I-309 `Root > Workspace > Pane`).
   - prevctx 1(I-307 D-032 ③)·chord 1(I-307 D-033 ⓑ): 스크립트의 정규식이 `(?:[^\t]*\t){2}---`처럼 **옛 View 행 수(3행 뒤 구분선)를 가정**한다. View에 5행(Split Up/Down/Left/Right·Maximize Pane)이 늘어 구분선이 7번째가 되어 매칭 실패 — Phase 4의 View 행 증가에 따른 스크립트 전제 한계.
   - reload 5·shadow 5의 "화면 단축키 vs 키맵 적용 결과 `<none>`"은 `checks` 실패가 아니라 콘솔의 `shortcut rows: 47, mismatched: 10`(별도 집계, 콘솔 `failures: 23` = 13 + 10)이다. 본문이 이를 `checks` 실패 13에 섞어 쓴 것이 오류다. 이 10건(`Split Up/Down/Left/Right`·`Maximize Pane`의 Pane 컨텍스트 키가 스크립트의 Workspace 컨텍스트 조회에 안 잡힘)은 의도한 변경의 후속으로 분류는 같다.
3. **L-108 링크 밑줄 불투명도(위 V3 표의 "안티에일리어싱 오차일 수 있음")**: 틀렸다. 설치된 `gpui-base-0.8.1/src/text/node.rs:3208`의 `link_underline`이 `thickness: px(1.)`, `color: link().opacity(0.4)`로 **불투명도를 0.4로 고정**한다. 측정 알파 0.40은 AA 오차가 아니라 컴포넌트 값 그대로이고, 스펙 `link.underline_opacity` 0.5와 −0.1 차이다. 분류: **컴포넌트(gpui-base) 한계**(앱 코드가 값을 바꾸지 못함 — P4-E-F1·R1 리뷰와 같은 결론). L-105(h1·h2 하단선)는 H-25의 컴포넌트 한계 기록을 따른다.

### R2.2 누락 V3 (master `56f1d93` 사본 exe, 앱 1회, 조작은 상태 도달만)

exe `%TEMP%\wbg-measure\56f1d93\workbench-gpui.exe`. 조건 1920×1080·100%·최대화(뷰포트 1920×1032). 결과·캡처 `measure-phase4/r2/`(`S2`~`S7b`). 픽스처는 텍스트 파일 `file-001`·`file-002` 탭 2개(앞서 쓴 `AAA-sample.md`는 경로 문자열 처리 실수로 만들어지지 않았다; 이 측정에는 불필요). 조작: 폴더 추가 → 두 파일 더블클릭 → ③ 탭 끌기 → 분할 단추·메뉴 `Split Right` → ① 분할선 끌기 3번 → 오른쪽 pane `Split Down` → 가로 분할선 끌기 → ② `Shift-Escape`. 덤프에는 마지막에 그려진 pane의 `tab-bar`·`active-item` 박스만 남아(이름이 겹침) **다른 pane의 크기는 덤프가 아니라 캡처 픽셀(`px-row.ps1`: 분할선 1px 회색 (229,229,229) 위치)로 구했다.**

| 스펙 ID | 상태 | 기대 | 측정 | 판정 | 증거 |
|---|---|---|---|---|---|
| `pane["split_line_thickness"]` I-725 | 분할 직후 두 pane | 1 | 분할선 x1230 **1px**(S4 동일 구성, 앞 보고와 같음). 끌어서 옮긴 뒤엔 **2px 띠**(x899~900, 619~620; 세로 분할선 가로 y132~133·516~517도 2px) — 분할선 위치가 소수 px가 되어 두 픽셀 걸침(양쪽 모두 같은 회색 (229,229,229), 옅은 중간색 없음) | PASS(정지 상태 1px) / **관찰**: 끈 뒤 2px 띠, 원인 미확정(경계 정수화 아님). 스펙 값 비교는 정지 직후 값 | `S4`·`S5.png` |
| `pane["split_line_mouse_hitbox"]` I-725 | 분할선(1230,y500) | 4 | **끌기가 시작됨**(분할선에 눌러 옮기니 위치가 바뀜) — 4px 폭 자체는 못 잼. 누르는 지점 오프셋 시험(±2·±3px)은 목록 밖이라 하지 않음 | 측정 불가(폭 값), 동작만 확인 | `S5` |
| 가로 두 pane 배치·비율 | 오른쪽 분할 직후 → 분할선 1230→900 끌기 | 새 pane 균등, 끌면 비율 변화 | 직후 540~1230 / 1230~1920(690 + 690 = 1:1). 900으로 끌면 왼쪽 **360**(540~900)·오른쪽 1020(`active-item` 900,65,1020×936) = 비율 0.261:0.739 (= (900−540)/1380) | PASS(모델 비율이 마우스 위치와 일치) | `S4`·`S5` |
| `pane["min_drag_width"]` I-726 | 분할선을 x545로 끎(왼쪽 pane 5px 폭이 되려는 값) | 80 | 분할선 x619~620 → 왼쪽 **80**(540~620), 오른쪽 `active-item` x620 폭 1300 | PASS | `S6.png`, dump |
| 중첩 분할 비율 | 오른쪽 pane에서 `Split Down` | 위·아래 균등 | 세로 분할선 y516~517. 위 pane 33~516 = **484**(탭 바 33~64·본문 65~516), 아래 pane `tab-bar` y517·`active-item` 549,452 → 아래 1002−517 = **485**. 합 969 = 균등 분할(0.5, 소수 .5) | PASS | `S7.png`, dump |
| `pane["min_drag_height"]` I-726 | 가로 분할선을 y40으로 끎(위 pane 7px 높이가 되려는 값) | 100 | 분할선 y132~133 → 위 pane **100**(33~133), 아래 `tab-bar` y133·`active-item` y165 높이 836 | PASS | `S7a.png`, dump |
| 중첩 뒤 왼쪽 pane | 위 중첩 분할 후 | 80 유지 | 왼쪽 x540~620 = **80** 그대로 | PASS | `S7.png` |
| `pane["zoomed_padding"]` L-17 | 아래 오른쪽 pane에서 `Shift-Escape` | 8 | `center` 540,33,1380×968 안, 확대 pane 바깥 흰 여백: 왼쪽 x540~547 **8**, 오른쪽 x1912~1919 **8**, 위 y33~40 **8**, 아래 y993~1000 **8**. `active-item` 549,74,1362×918(= 8 + 테두리 1 + pane 가장자리) | **PASS** | `S7b.png` px |
| `pane["zoomed_border"]` L-17 | 위와 같음 | 1 | 위 y41 **1px**(229). 왼쪽 x548~549·오른쪽 x1910~1911 = **2px 띠**, 아래 y991~992 2px 띠. 확대 안 한 화면의 pane 가장자리도 왼쪽 x540 1px·오른쪽 x1919 1px(pane 자체 가장자리선)라서 **"확대 테두리 1 + pane 가장자리선 1"로 읽히나 이 분해는 추정**(픽셀로 둘을 가르지 못함) | PASS(위) / 판정 보류(좌·우·아래 2px 띠, 추정) | `S7b.png` px |
| `pane["tab_drop_line_width"]` I-715 | 같은 탭 바 안에서 `file-002` 탭을 `file-001` 왼쪽 절반 위로 끄는 중(끌기 캡처) | 2 | 삽입선 x601~602 = **2px**, 색 (84,90,100), 탭 바 위쪽(y33~37)에서 확인(아래는 끌기 고스트가 가림; 고스트가 탭 레이블 위를 덮음). 같은 색 1px 세로선이 x710(탭 오른쪽 경계)에도 y33~64 전체에 있음 — 용도 미확인(관찰만) | **PASS**(2px, 왼쪽 삽입 방향이 끌기 시작 방향과 반대) | `S3a.png` px |

- **못 잰 것과 이유**: ① `split_line_mouse_hitbox` 4px — 마우스 모양을 캡처할 수 없고, 누르는 위치를 ±px씩 옮겨 시험하면 기능 확인 조작이라 3A.4 밖. ② 확대의 좌·우·아래 테두리를 1px로 가르는 일 — 픽셀이 2px로만 구분되고 DOM/덤프에 테두리 박스가 없다. ③ 삽입선 전체 높이 — 끌기 고스트가 y38 이하를 가려 위쪽 5px만 직접 봄. **이 셋은 도구 한계이며 사용자 결정 사항이 아니다.**
- **사용자 결정 필요(측정으로 판단 불가)**: 끈 뒤 분할선이 2px로 보이는 것이 허용되는지(스펙은 1px, 시각 차이), 확대 화면의 좌우 2px 띠가 Zed와 같은지, 삽입선 색 (84,90,100)이 Zed `drop_target`과 같은지.
- 앱 데이터 restored=true, 픽스처 삭제됨.

[MEASURED] P4-E-R2: 정정 3건 반영. V3 PASS 7(가로 비율·min 80·중첩 균등·min 100·중첩 후 80 유지·확대 padding 8·삽입선 2px) + 정지 분할선 1px, 관찰 2(끈 뒤 2px 띠·확대 좌우 2px 띠, 원인 미확정), 측정 불가 1(히트박스 폭, 도구 한계), 불일치 0.

## R3 — P4-E-F2 재측정 (카드 P4-E-R3, 좁은 V3)

- 대상: work/ui `62f7dfa`(worktree `.worktrees/ui`에서 공유 target으로 `cargo build` 오류 0, `apply-manifest.ps1 -Exe <절대경로>` 적용). exe `%TEMP%\wbg-measure\62f7dfa\workbench-gpui.exe` 사본(SHA `0D336EEE…3EBC`)만 썼다. 앱 1회, 조건 1920×1032 최대화 100%. 결과·캡처 `measure-phase4/r3/`(`S4`~`S7`). 앱 데이터 restored, 픽스처 삭제.
- 조작: 폴더 추가 → `file-001`·`file-002` 더블클릭 → **`Ctrl-K` `→`(오른쪽 분할)** → 분할선 1230→900 끌기 → **`Ctrl-K` `↓`(중첩 분할)** → `Shift-Escape`. 분할 단추 클릭은 쓰지 못했다: 사용자 PC의 **다른 프로그램 창(`Zed`, pid 15872)이 (1877,48)을 덮고 있어** `input.ps1`이 "Point is outside the target window"로 중단했다(우리 앱 문제 아님, 그 창은 건드리지 않았다). 키 입력은 포커스된 앱으로 가므로 단추 대신 같은 동작의 키(I-731)를 썼다. 앱 코드 경로는 단추나 키나 같은 `split` 호출이다(코드 확인은 하지 않음).
- 측정 도구: `px-row.ps1`(PNG 한 행·열의 색 구간), `px-runs.ps1`. 분할선 색 (229,229,229), 위치는 연속된 같은 색 픽셀 수로 두께를 읽었다.

| 스펙 ID | 상태 | 기대 | 측정 | 판정 | 증거 |
|---|---|---|---|---|---|
| `pane["split_line_thickness"]` I-725 | ① 오른쪽 분할 직후(`active-item` 1230,65,690×936) | 1 | x1229~1230 = **2px** | **불일치** | `S4.png` |
| 같은 ID | ① 분할선을 x900으로 끈 뒤(`active-item` 900,65,1020×936) | 1 | x899~900 = **2px** | **불일치** | `S5.png` |
| 같은 ID | ② 오른쪽 pane `Split Down` 뒤 가로 분할선(`tab-bar` y517, `active-item` y549) | 1 | y516~517 = **2px**(위 pane 아래 y64~65, 아래 pane 위 y548~549, 아래 y1000~1001도 2px 쌍). 세로 분할선(x899~900)도 2px | **불일치** | `S6.png` |
| `pane["zoomed_padding"]` L-17 | 아래 오른쪽 pane `Shift-Escape` (`center` 540,33,1380×968) | 8 | 왼쪽 x540~547 **8**, 오른쪽 x1912~1919 **8**, 위 y33~40 **8**, 아래 y993~1000 **8**. `active-item` 549,74,1362×918 | **PASS** | `S7.png` |
| `pane["zoomed_border"]` L-17 | 위와 같음 | 1 | 왼쪽 x548 **1px**, 오른쪽 x1911 **1px**, 위 y41 **1px**, 아래 y992 **1px** (색 229, 사방 같음) | **PASS**(R2 때 좌·우·아래 2px였던 것이 1px로 해소) | `S7.png` |

- **불일치 1건(스펙 ID 1개, 상태 3곳)**: `pane["split_line_thickness"]` — 분할선이 정지 직후·끈 뒤·중첩 분할 뒤 모두 **2px**. R2(56f1d93)에서는 정지 직후 분할선이 **1px**(x1230)이었고 끈 뒤에만 2px 띠였다(R2.2). 즉 이번 변경(분할선을 canvas로 그려 정수 px에 맞춤)이 **끈 뒤 2px는 못 없애고 정지 직후 1px를 2px로 늘렸다**. 원인은 확인하지 못했다. 추정(미검증): canvas로 그린 분할선 1px(x1229)과 오른쪽 pane 자신의 왼쪽 가장자리선(x1230)이 나란히 놓여 같은 회색 2px로 보인다. 같은 이유로 확대하지 않은 화면의 왼쪽 가장자리는 R2와 같이 사이드바 경계 x539 + pane 가장자리 x540으로 2개 연속이다(1px씩).
- **판정 보류 0건**: 이번 두 상태 모두 픽셀로 판정했다. 확대 테두리는 R2의 "추정/보류"가 해소되어 **PASS**로 확정한다.
- 집계: PASS 2(`zoomed_padding`·`zoomed_border`), 불일치 1(분할선 두께, 3 상태), 판정 보류 0, 측정 불가 0.

[MEASURED] P4-E-R3: 불일치 1(split_line_thickness 2px ≠ 1, 상태 3곳), PASS 2(확대 padding 8·border 1), 판정 보류 0.

## R4 — P4-E-F3 재측정 (카드 P4-E-R4, 좁은 V3)

- 대상: work/ui `c594bed`(worktree 공유 target `cargo build` 오류 0, `apply-manifest.ps1 -Exe <절대경로>`). exe `%TEMP%\wbg-measure\c594bed\workbench-gpui.exe` 사본(SHA `CBF4B05B…F7C1`)만 썼다. 앱 1회, 1920×1032 최대화 100%. 결과·캡처 `measure-phase4/r4/`(`S2`·`S4`~`S7`). 앱 데이터 restored, 픽스처 삭제.
- 조작은 R3와 같다(폴더 추가 → 두 파일 더블클릭 → `Ctrl-K →` → 분할선 1230→900 끌기 → `Ctrl-K ↓` → `Shift-Escape`). 분할 단추는 R3처럼 다른 프로그램 창이 가려 키를 썼다. 측정은 `px-row.ps1` 픽셀(분할선 색 (229,229,229)).

| 스펙 ID | 상태 | 기대 | 측정 | 판정 | 증거 |
|---|---|---|---|---|---|
| `pane["split_line_thickness"]` I-725 | 오른쪽 분할 직후(`active-item` 1230,65,690×936) | 1 | x1230 **1px** | **PASS** (R3 2px 해소) | `S4.png` |
| 같은 ID | x900으로 끈 뒤(`active-item` 900,65,1020×936) | 1 | x900 **1px** (R2의 x899~900 2px 띠도 없음) | **PASS** | `S5.png` |
| 같은 ID | 오른쪽 pane `Split Down` 뒤(`tab-bar` y517, `active-item` y549) | 1 | 가로 분할선 y517 **1px**, 세로 분할선 x900 **1px** | **PASS** | `S6.png` |
| `pane["zoomed_padding"]` L-17 | `Shift-Escape`(`center` 540,33,1380×968, `active-item` 549,74,1362×918) | 8 | 좌 x540~547 **8**, 우 x1912~1919 **8**, 위 y33~40 **8**, 아래 y993~1000 **8** | **PASS** | `S7.png` |
| `pane["zoomed_border"]` L-17 | 위와 같음 | 1 | 좌 x548 **1px**, 우 x1911 **1px**, 위 y41 **1px**, 아래 y992 **1px** | **PASS** | `S7.png` |
| 분할 안 한 화면의 사이드바 경계(R2·R3의 x539·x540) | 폴더를 열고 탭 2개, 분할 전(`S2`)·분할 뒤(`S5`) | 스펙 ID 없음(참고) | x539~540 = **2px**(x539 사이드바 경계 + x540 pane 가장자리선, 각 1px 같은 회색 (229,229,229)) — **변하지 않음**(R2·R3와 같다). 확대 화면에서는 x539 하나만 보임(pane 가장자리가 x548로 이동) | **변화 없음**(판정 대상 아님: 스펙 값 없음, 사용자 결정 사항) | `S2`·`S5.png` |

- 같은 열에서 보이는 y64~65·y548~549·y1000~1001의 2px 쌍은 분할선이 아니라 **탭 바 아래 테두리 + 편집기 위 테두리 / 본문 아래 테두리 + 상태 표시줄 위 경계**가 맞닿은 것이다(분할 전·R2·R3에도 있었음). 이번 변경 범위 밖이라 판정하지 않았다.
- 집계: PASS 5(분할선 3 상태, 확대 padding, 확대 border), 불일치 0, 판정 보류 0, 측정 불가 0. 사이드바 경계 2px는 R2·R3와 같게 남아 있다(참고).

[MEASURED] P4-E-R4: 불일치 0, PASS 5, 판정 보류 0. 사이드바 경계 x539~540 2px는 그대로(스펙 값 없음).

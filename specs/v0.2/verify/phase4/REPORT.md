# v0.2 Phase 4 일치도 검증 보고서 (프로젝트 패널 트리·파일 작업·최소 탭·시나리오 · R-17~R-23·R-25~R-27)

- 검증자: wg-checker. 요청: wg-leader(2026-11-02). 기준: SPEC R-17~R-23·R-25~R-27, Phase 1~3 이월분, PLAN Phase 4 완료 조건, 01-zed 원문(01-LAYOUT L-36~L-50·L-247, 02-INTERACTION I-030~I-097·I-502·I-520·I-530~I-562·P-015·P-019~P-022·11.2절·11.10절, 04-APP-SPEC A-14·A-15·A-33.2·A-33.4), D-042.
- 방법: 증거를 새로 모으지 않았고 앱도 돌리지 않았다. `phase4/`(EVIDENCE.md, results.json, 사례별 stdout, `*-disk-*.txt`, 스크린샷)와 `phase1~3/p4-rerun/` 을 읽었다. 스크린샷은 시나리오 단계 8장, 확인창 4장, 실패 알림, 인라인 입력칸 4장, 우클릭 메뉴 4장, 트리 배치·reveal·읽기 전용 확인 등 25장을 직접 열어 보았다(실패 알림 2장 포함). 코드는 `src/fsops/paths.rs`, `src/ui/folders.rs` 일부만 읽었다(문구·값 판정은 원문·실행 출력·스크린샷 기준).
- 쓴 파일: 이 보고서 하나. 코드·다른 문서·증거는 고치지 않았다.

## 요약

| 요구 | 판정 | 비고 |
| --- | --- | --- |
| R-17 트리 배치·치수 | **통과** | 판정 74개. 루트 맨 위, 정렬, 접힌 경로, 높이 26·들여쓰기·아이콘 16·안내선 |
| R-18 누르기·키보드 | **통과** | 판정 25개. Shift+Down 은 시험하지 않음(Shift+Up 만) |
| R-19 인라인 생성·이름 변경 | **통과** | 판정 23개. 선택 범위·경고·오류 스크린샷 확인. 입력칸 높이 24 는 재지 않음 |
| R-20 휴지통·영구 삭제 | **통과** (휴지통 안 확인 판정 불가) | 확인창 문구 원문과 글자 단위 일치. 판정 불가 1건은 D-042 ② |
| R-21 클립보드·복제·경로 복사 | **통과** | 판정 13개, 디스크 전후 비교 |
| R-22 우클릭 메뉴 | **통과** | 5종 + 빈 공간, 02 11.2절과 줄마다 일치 |
| R-23 자동 표시 | **통과** | 접힌 경로까지 펼침, 포커스는 편집기에 남음 |
| R-25 시나리오 A-33.2 | **통과** | 4단계 스크린샷 확인 |
| R-26 시나리오 A-33.4 | **통과** | 5단계, 해제 뒤 디스크 같음 |
| R-27 최소 탭 | **통과** | 임시 탭 교체·승격·기울임·폴더별 탭·보기 전용. 탭 바 치수(A-32.3~5)는 Phase 4 증거에 없음 |
| 이월분(R-3 패널 Delete·루트 무동작·Ctrl-N, L-247, 폴더별 트리 상태, 해제 때 탭 닫기, 루트 Remove from Project, I-520) | **통과** | §12 |
| Phase 1·2·3 유지 | **유지** | §14 |

- **명세 값과 다른 실제 값: 0건.** 확인 요청·관찰은 §15.
- **PLAN 완료 조건 미충족 2건**: wg-reviewer Phase 4 리뷰의 PROGRESS 기록 없음, Phase 4 커밋 없음(§16).

## 1. 증거 개요와 신뢰 점검

- `results.json`: 12개 사례, 판정 **208개, 실패 0**, errors 없음. 사례별 판정 수는 layout 74·keys 25·inline 23·trash 16·clip 13·menu 27·reveal 3·readonly 3·tooltip 2·a332 4·a334 9·menukeys 9 로 EVIDENCE.md 와 같다.
- 사용자 파일(`%APPDATA%\workbench-gpui`): `userFiles` 전후 비어 있음, `restored: true`. OS 클립보드 되돌림 `clipboardRestored: true`. 시험 폴더는 `runFolderLeft: false`, `baseLeft: false`.
- 판정 불가 1건(`undetermined`): 휴지통 안 항목 확인·복원(A-14.3·A-14.5). 이유: 시험 폴더 볼륨 D: 가 이동식(DriveType=2)이라 휴지통이 없고, 이 PC 의 휴지통 설정이 `NukeOnDelete=1`. `--dev-trash list` 결과 항목 0(`trash-list-after-trash.txt`, `trash-final-purge.txt`). D-042 ② 대로 사용자 시스템 설정은 바꾸지 않았다.
- 재시도 0번(EVIDENCE.md). 관리자 창 때문에 멈췄던 일은 D-042 ① 에 적혀 있고, 최종 `results.json` 에는 오류가 없다.
- 판정 기록의 한계(§15-라): 판정 기록은 요구 판정에 쓰는 값이다. 이 보고서는 판정 기록과 함께 앱 stdout·디스크 목록·스크린샷으로 교차 확인했다.

## 2. R-17 트리 배치·치수

- **원문**: SPEC R-17(L-36~L-42, A-32.14~A-32.16). L-41 루트 맨 위, L-42 자식 하나뿐인 폴더 경로 접기, L-36 높이 26, L-37 단계당 20, L-38 안내선 폭 1·x=깊이×20+15·위아래 4, L-40 아이콘 16, L-50 폴더 먼저 자연 정렬.
- **판정 기록**(layout 사례, ±1):
  - 루트 `proj` 가 맨 위, 펼친 채(`open 맨 앞`). 순서 `proj / deep \ l1 \ l2 / docs \ guides / many / ops / src / notes.txt / README.md`(폴더 먼저, 대소문자 무시).
  - 접힌 경로 `deep \ l1 \ l2`·`docs \ guides`(연쇄 접기).
  - 보이는 13행 전부: 높이 26, 앞 행 바로 아래 간격 26, 아이콘 x = 1+6+깊이×20(7·27·47·67 실측), 아이콘 16×16, 안내선 단계마다 x = 15·35·55 폭 1.
  - 안내선 구간 첫 행 위 4, 끝 행 아래 4.
- **스크린샷 `layout-tree.png`**(직접 열어 봄): 루트 `proj`, 펼친 `docs ₩ guides`(자식 `a.md`), 펼친 `src`·`util`(`mod.rs`), 안내선이 단계마다 세로로 이어지고 선택 행(`util`)이 강조된다. 파일·폴더 아이콘은 같은 크기다. 아이콘 모양은 판정 대상이 아니다.
- **판정: 통과.**
- **확인하지 못한 것**: L-43 접힌 경로 조각 padding 2·hover, L-44 펼침 표시(폴더 아이콘 개폐 모양은 스크린샷에서 확인: 열림·닫힘 아이콘이 다르다), L-45 가로 스크롤, L-47 색은 R-17 판정 대상이 아니고 증거도 없다.

## 3. R-18 누르기·키보드

- **원문**: SPEC R-18(I-030~I-033, I-043, I-087~I-090).
- **판정 기록**(keys 사례) 모두 통과:
  - Up/Down/Home/End 는 선택만 바꾼다(탭 0, 포커스 패널 그대로). 처음에서 Up 은 그대로(판단: 돌지 않음).
  - Right: 닫힌 폴더 펼침 → 이미 펼쳤으면 다음 항목. Left: 파일이면 부모로 → 펼친 폴더 접기. Ctrl+Right 전체 펼치기, Ctrl+Left 전체 접기(루트는 펼친 채).
  - Space: 임시 탭으로 열고 트리에 포커스 남김(`README.md|preview`, `focus project_panel`).
  - Shift+Up 두 번: 범위 3개.
  - 마우스: 폴더 누르기 펼침·다시 누르기 접힘, Alt+클릭 하위 전체 펼침·접힘, Ctrl+클릭 추가·빼기, Shift+클릭 범위(`many;ops;src;notes.txt`).
  - 파일 한 번 클릭 = 임시 탭(기존 임시 자리 교체)·편집기 포커스 없음. 더블클릭 = 일반 탭 + 편집기 포커스. 가운데 클릭 = 임시였던 탭을 일반 탭 + 편집기 포커스.
- **판정: 통과.** 시험하지 않은 것: Shift+Down(I-043 은 "Shift+Up/Down"). 같은 처리기라고 코드는 읽지 않았다.

## 4. R-19 인라인 생성·이름 변경

- **원문**: SPEC R-19(I-034~I-036, I-091, I-092, I-097, P-019~P-022), 02 P-021(검증 문구), 01-LAYOUT P-019~P-021(모양).
- **판정 기록**(inline 사례) 모두 통과:
  - Ctrl+N → 새 파일 입력칸(빈 값, 루트 가상 행), 포커스는 `panel_input`(editing 컨텍스트). Enter 확정 → 디스크에 `new.txt`, 일반 탭 + 편집기 포커스(I-097, 판단).
  - Alt+N → 새 폴더 입력칸(선택 파일의 부모), 확정 뒤 폴더 생성·패널 포커스.
  - F2 → 파일은 확장자 뺀 이름만 선택(`value="notes.txt" selected_text="notes"`), Enter 로 `renamed.txt`(`notes.txt` 없음). 열린 탭 경로도 새 이름(판단).
  - Enter(Windows) → 폴더는 이름 전체 선택(`selected_text="many"`).
  - Escape → 입력 버림·패널 포커스·디스크 그대로. 루트 F2 → `rename-skipped reason=root`, 입력칸 없음.
  - 포커스 잃음 → 유효하면 만든다(`blur.txt`). 충돌 상태에서 포커스 잃음 → 편집 취소.
  - 같은 이름 → 오류 문구, Enter 는 거부하고 열린 채. 앞뒤 공백 → 경고 문구. 끝 마침표 모두 제거(`dots.txt`). 끝이 `\` 면 폴더(`slashdir`). `foo/bar/baz` 류는 중간 폴더도 생성(`nest\a\b.md`). 빈 이름 Enter → 아무 일 없이 열린 채(P-021 "배너 없이 무시"와 같다). 이름 변경에서 같은 이름 → 편집만 끝.
- **문구 글자 단위 대조**(앱 stdout `validation=` 줄·스크린샷):

| 원문(P-021) | 실제 값 | 일치 |
| --- | --- | --- |
| `File or directory name contains leading or trailing whitespace.` | 같음(경고) | O |
| `File or directory '{이름}' already exists at location. Please choose a different name.` | `File or directory 'README.md' already exists at location. Please choose a different name.` | O |

- **스크린샷**(직접 열어 봄): `inline-rename-file-selection.png` 에서 `notes.txt` 중 `notes` 만 파란 선택, `inline-rename-folder-selection.png` 에서 `many` 전체 선택. `inline-warning-banner.png` 는 행 테두리·배너 글자가 노란색, `inline-error-banner.png` 는 빨간색이고 배너가 편집 행 바로 아래에 겹쳐 뜬다(P-020·P-021 색 규칙에 맞는 모양).
- **디스크 전후**(`inline-disk-before/after.txt`, 67 → 75줄): 더해진 것은 `blur.txt`·`dots.txt`·`nest\a\b.md`·`nest\a`·`nest`·`new.txt`·`newdir`·`renamed.txt`(내용·해시 `notes.txt` 와 같음)·`slashdir` 9줄, 사라진 것은 `notes.txt` 1줄(67−1+9=75). 그 밖의 줄은 변하지 않았다.
- **판정: 통과.**
- **확인하지 못한 것·관찰**: P-019 의 입력칸 높이 24·행 26 은 레이아웃 상자로 재지 않았다. 스크린샷에서 입력칸 글자가 같은 행의 일반 이름보다 몇 px 아래에 앉아 있고(예: `inline-warning-banner.png` 의 `lead.txt`), 테두리에 바짝 붙는다. 값 판정은 못 한다(§15-바).

## 5. R-20 휴지통·영구 삭제

- **원문**: SPEC R-20(A-14.1~A-14.11, I-039·I-040·I-093), 02 P-015.
- **키**(trash 사례): Delete → 휴지통 확인창(`ctrl-t` 사용자 키도 확인창), Backspace → 휴지통 확인창, Shift+Delete·Ctrl+Delete·Ctrl+Backspace → 영구 삭제 확인창(판정 기록으로 확인한 것은 Ctrl+Delete·Ctrl+Backspace·메뉴 Delete. Shift+Delete 는 EVIDENCE.md 에만 적혀 있고 판정 기록에서 따로 찾지 못했다). 루트가 선택된 채 Delete → 아무 일도 하지 않음, 확인창 없음.
- **확인창 문구 원문과 글자 단위 대조**(앱 `task-dialog-open` 출력·스크린샷 `trash-dialog-*.png`, `delete-dialog-*.png`):

| 원문 ID | 원문 | 실제(앱 출력) | 버튼 | 일치 |
| --- | --- | --- | --- | --- |
| A-14.7 | ``Do you want to trash `name`?`` | ``Do you want to trash `f1.txt`?`` | `Trash`·`Cancel`(기본 Cancel) | O |
| A-14.8 | ``Are you sure you want to permanently delete `name`?`` + 보조 `This cannot be undone.` | 같음(`content=Some("This cannot be undone.")`) | `Delete`·`Cancel`(기본 Cancel) | O |
| A-14.9(휴지통, 여러 개) | `… the following N files?` + 목록 | ``Do you want to trash the following 3 files?\nf3.txt\nlocked.txt\nsub`` | `Trash`·`Cancel` | O |
| A-14.9(영구, 넘침) | 목록 10개 + `.. N files not shown` | ``Are you sure you want to permanently delete the following 12 files?`` + `m00.txt`~`m09.txt` + `.. 2 files not shown` + 보조 `This cannot be undone.` | `Delete`·`Cancel` | O |
| A-14.10 | `It has unsaved changes, which will be lost.` | 판정하지 않음(D-18: 수정된 버퍼 없음) | — | 해당 없음 |
| A-14.11 | `Failed to trash/delete X of Y file(s).` | `Failed to delete 1 of 1 file(s).` / `Failed to trash 1 of 1 file(s).`(알림 줄, 스크린샷 `trash-failure-notification.png`·`delete-failure-notification.png`) | — | O |

- **스크린샷**(직접 열어 봄): 네 확인창 모두 제목 `workbench-gpui`(판단 D-042 #12), 본문 문구 일치, 기본 버튼(파란 테두리)이 `Cancel`. 여러 항목 창은 목록 줄이 본문 아래 이어지고 `sub` 폴더 이름도 목록에 들어간다. 넘침 창은 10줄 뒤 `.. 2 files not shown`, 그 아래 `This cannot be undone.`.
- **취소·확인**: Esc → Cancel(디스크 그대로). 확인창에서 바로 Enter → 기본 Cancel(디스크 그대로). 넘치는 목록 취소 → 12개 그대로.
- **디스크 전후**(휴지통 포함):
  - `trash-disk-0-before`(67줄) → `trash-disk-1-after-trash`(66줄): `ops\f1.txt` 한 줄 사라짐(Trash 확인, `fs-op op=trash result=ok`).
  - → `trash-disk-2-after-delete`(65줄): `ops\f2.txt` 한 줄 사라짐(Delete 확인, `fs-op op=delete`). 휴지통 목록에 `f2` 없음.
  - → `trash-disk-3-after-restore`(65줄): 직전과 `cmp` 로 같다. 복원할 항목이 없어 복원은 시험하지 못했다(판정 불가).
  - 취소한 사례(f3 Backspace, 넘침 목록, `ctrl-t`)는 f3·`m*.txt` 가 그대로이고 목록에서 줄어든 것은 위 두 줄뿐이다.
  - 휴지통 목록: `trash-list-after-trash.txt` = `[dev] trash-done op=list count=0 total=0`, 최종 정리 `op=purge count=0`.
- **판정 불가**: 휴지통 안 항목 확인·복원(A-14.3 "휴지통으로 옮긴다"의 휴지통 쪽, A-14.5). 앱이 확인 뒤 `trash` 크레이트로 보냈고(`op=trash result=ok`) 파일이 사라지는 데까지만 판정했다. Trash 와 Delete 가 다른 경로(`op=trash`/`op=delete`)를 타는 것은 확인했다.
- **판정: 통과**(휴지통 안 확인 제외). 루트 메뉴에 Trash·Delete·Rename 이 없는 것은 §7.

## 6. R-21 클립보드·복제·경로 복사

- **판정 기록**(clip 사례) 모두 통과: Paste 는 붙여 넣을 것이 없으면 비활성(`Paste|disabled|Ctrl-V`), Ctrl+C → `file-clipboard op=copy`(텍스트가 아님), Ctrl+V → 대상 폴더에 복사(원본 그대로), 붙여 넣은 파일을 연다(일반 탭, 포커스는 패널, 판단), 같은 이름이면 ` copy`(`s copy.txt`), Ctrl+Insert/Shift+Insert(`f1 copy.txt`), Ctrl+X → Ctrl+V 는 옮김(`ops\sub\f2.txt` 있음, `ops\f2.txt` 없음), 잘라 붙인 뒤 클립보드 비움(Paste 비활성, 판단), Duplicate → 같은 폴더 `f3 copy.txt`, 폴더 복사(`sub\s.txt`·`sub\f2.txt`), Shift+Alt+C → 절대 경로·Ctrl+K Ctrl+Shift+C → 상대 경로(OS 클립보드 문자열 `README.md`), 여러 항목 → 줄마다 하나(`README.md\nops\f1.txt`).
- **작업 흔적(`fs-op`)**: `paste-copy`·`paste-move`·`duplicate` 모두 `result=ok`. Duplicate 뒤 탭은 `f3 copy.txt|normal` 로 열렸다(tabs 줄).
- **디스크 전후**(`clip-disk-0-before`/`1-after`, 67 → 75줄): 더해진 것 `proj\f3 copy.txt`, `ops\f1 copy.txt`, `ops\f3 copy.txt`, `ops\s copy.txt`, `ops\s.txt`, `ops\sub\f2.txt`, `sub\f2.txt`, `sub\s.txt`, `sub`(폴더) 9줄, 사라진 것 `ops\f2.txt` 1줄(옮김, 해시는 `ops\sub\f2.txt` 와 같음). 원본(`ops\sub\s.txt`, `ops\f1.txt`, `ops\f3.txt`)은 그대로다.
- **판정: 통과.** 시험하지 않은 것: ` copy 1` 이름(D-042 판단 #1 의 두 번째 형태), 폴더끼리 잘라 붙이기, 여러 항목 Cut.

## 7. R-22 우클릭 메뉴

- **원문**: SPEC R-22, 02 11.2절 I-660(파일)·I-661(폴더)·I-662(루트·빈 공간)·항목표 I-530~I-557, I-559·I-560·I-561·I-562, I-502, 11.10절.
- **줄마다 대조**(menu 사례 판정 기록의 expect 와 got 문자열이 5종 모두 같음, `SAME: True`):
  - 마크다운 파일 `README.md`(I-660): New File Ctrl-N / New Folder Alt-N / ─ / Reveal in File Explorer Ctrl-Alt-R / Open in Default App Ctrl-Shift-Enter / Open Markdown Preview(비활성, D-15) / ─ / Cut Ctrl-X / Copy Ctrl-C / Duplicate / Paste(비활성) Ctrl-V / ─ / Copy Path Alt-Shift-C / Copy Relative Path Ctrl-K Ctrl-Shift-C / ─ / Rename F2 / Trash Delete / Delete Ctrl-Delete.
  - 일반 파일(`notes.txt`): 위에서 Open Markdown Preview 만 없다.
  - 폴더(`src`, I-661): 파일 메뉴 구성 + ─ + Expand All / Collapse All(단축키 없음, I-556·I-557 하위 폴더).
  - 접힌 폴더(`docs \ guides`): 위 + Reveal/Open 뒤 ─ `Unfold Directory`(I-538).
  - 루트(`proj`, I-662): New~Copy Relative Path 까지 같고, ─ `Add Folders to Project…` / `Remove from Project`(단축키 없음) ─ `Expand All Ctrl-Right` / `Collapse All Ctrl-Left`. Rename·Trash·Delete 없음.
  - 빈 공간(I-559): 루트 메뉴와 같은 줄 구성.
- **스크린샷**(`menu-01`(파일)·`menu-04`(접힌 폴더)·`menu-05`(루트)·`menu-keyboard`(키보드로 연 메뉴)를 직접 열어 봄): 구분선 위치·회색 비활성(Open Markdown Preview, Paste)·오른쪽 단축키 열이 위 표와 같다. 11.10절의 표시 키(Copy=Ctrl-C, Paste=Ctrl-V, Trash=Delete, Delete=Ctrl-Delete, Cut=Ctrl-X)와 같다.
- **I-560**: 우클릭한 항목이 선택이 된다(5종 모두 판정 통과). 접힌 폴더는 선택이 `docs`(조각)다(§15-다).
- **I-042·I-502**: Shift+F10 과 Menu 키 모두 메뉴가 `302,217` 에 열림(선택 행 왼쪽 아래 + (2, 2), 판단 D-042 #11).
- **실행 확인**(27개 판정): Unfold → `docs` 와 `guides` 가 따로 보임, Fold → 다시 `docs \ guides`, Expand All·Collapse All(하위 폴더), Reveal(`explorer.exe /select,"…\notes.txt"`, `executed=false`), Open in Default App(`open-default`, `executed=false`), Copy(`file-clipboard op=copy`), Rename(입력칸), Trash·Delete(확인창), New File(그 폴더에 입력칸), Add Folders to Project…(`folder-add result=added index=1`), Remove from Project(`folder-remove … via=project-panel-menu`, 디스크 `same=True`).
- **판정: 통과.** 시험하지 않은 것: I-562 여러 항목 표시 상태에서 Cut, 접힌 경로의 두 번째 조각을 우클릭하는 경우. 드래그 앤 드롭(D-17)은 만들지 않았다(패널·탭 소스에 drag 처리 없음, grep 결과 0건).

## 8. R-23 자동 표시

- **판정 기록**(reveal 사례): 깊은 위치에 새 파일 `r23\a\b\c.md` 를 만들어 열면 접힌 경로 `r23 \ a \ b` 가 펼쳐지고 `c.md` 가 선택된다(`expanded=.;r23;r23\a;r23\a\b`, `selected=r23\a\b\c.md`, 행 `r23 \ a \ b` 아래 `c.md`). 포커스는 편집기에 남는다(`editor`). `[dev] reveal path=…\r23\a\b\c.md`.
- **스크린샷 `reveal-deep.png`**(직접 열어 봄): 트리에 `r23 ₩ a ₩ b` 아래 `c.md` 가 선택돼 있고, 탭 `c.md` 의 편집기에 캐럿이 있다(트리에 포커스가 가지 않음).
- **판정: 통과.** 시험은 새로 만든 파일을 여는 한 경로다(기존 파일을 탭으로 여는 경로는 시나리오에서 같은 처리가 쓰이지만 reveal 줄을 따로 확인하지는 않았다).

## 9. R-27 최소 탭

- **판정 기록**: 한 번 클릭·Space = 임시 탭(`preview`, 편집기 포커스 없음/Space 는 패널 포커스), 임시 하나 교체(0번 자리), 더블클릭·가운데 클릭 = 일반 탭 + 편집기 포커스, 일반 탭은 두고 새 임시 탭을 뒤에 둔다(`notes.txt|normal / README.md|preview`), 폴더별 탭(§11), 이름 변경 때 탭 경로 갱신(판단).
- **임시 탭 제목 기울임**: 스크린샷 `a332-1`·`a332-2`·`a332-4` 에서 `README.md`·`notes.txt` 가 기울임, `a332-3`·일반 탭은 기울임 없음.
- **보기 전용**(readonly 사례): 탭 내용 길이 33 = 파일 크기(CRLF→LF 로 31~33 허용 범위), 글자·Enter·Backspace·Delete 를 입력한 뒤에도 내용 길이·FNV-1a(`c45e16dbc6dd544f`)와 디스크 해시가 같다. 스크린샷 `readonly-after-typing.png` 은 내용이 그대로(`# README`/`한글 확인 첫 줄`)다.
- **편집기 파일 아이콘 없음(L-67)**: 모든 탭 스크린샷에서 탭 제목 앞에 아이콘이 없다.
- **판정: 통과.**
- **Phase 4 증거에 없는 것**: 탭 바·탭 치수(A-32.3~A-32.5) 측정. 스크린샷으로 v0.1 뼈대와 같아 보이나 값 판정은 하지 않았다(탭 닫기·저장·분할은 범위 밖이라 시험하지 않음).

## 10. R-25 시나리오 A-33.2 (단계별 스크린샷 확인)

| 단계 | 원문 | 스크린샷(직접 열어 봄) | 앱 출력 | 판정 |
| --- | --- | --- | --- | --- |
| ① | README.md 한 번 클릭 → 임시 탭(제목 기울임) | `a332-1-readme-preview.png`: 탭 `README.md` 기울임, 편집기에 내용, 트리 `README.md` 선택 | `active=0 README.md|preview` | 통과 |
| ② | 다른 파일 한 번 클릭 → 같은 자리 교체 | `a332-2-notes-replaced.png`: 탭 하나만 `notes.txt`(기울임), README 탭 없음 | `active=0 notes.txt|preview` | 통과 |
| ③ | 더블클릭 → 일반 탭 | `a332-3-notes-normal.png`: 탭 `notes.txt` 기울임 없음, 편집기에 캐럿(포커스) | `active=0 notes.txt|normal`, `focus editor` | 통과 |
| ④ | (확장 확인) 다른 파일 한 번 클릭 → 일반 탭 뒤에 새 임시 탭 | `a332-4-second-preview.png`: `notes.txt`(일반) 뒤에 `README.md`(기울임) | `notes.txt|normal / README.md|preview` | 통과 |

- **판정: 통과.** (툴팁이 남아 있는 것은 마우스가 항목 위에 있어서다.)

## 11. R-26 시나리오 A-33.4 (단계별 스크린샷 확인)

| 단계 | 원문 | 스크린샷(직접 열어 봄) | 앱 출력·디스크 | 판정 |
| --- | --- | --- | --- | --- |
| ① | 폴더 둘 등록, 각각 탭을 연다 | `a334-1-proj-tab.png`: 사이드바 `proj`(활성)·`proj2`, 탭 `README.md`, 트리는 `many` 안 `m05.txt`~ 로 스크롤된 상태 | proj `README.md|normal` | 통과 |
| ① | 〃 | `a334-2-proj2-tab.png`: `proj2` 활성, 트리 `b-readme.md`·`other.txt`, 탭 `b-readme.md` 하나(proj 탭 안 보임) | proj2 `b-readme.md|normal` | 통과 |
| ② | 전환해도 탭이 따로 유지 | `a334-3-back-to-proj.png`: `proj` 로 돌아오면 같은 스크롤 위치·`README.md` 탭 그대로 | `README.md|normal`, 펼침 `.;many`, 선택 `many`, 스크롤 `-234.0` 같음. proj2 탭도 그대로 | 통과 |
| ③ | 하나 해제 | `a334-4-after-remove.png`: 사이드바에 `proj` 만, 트리·탭 그대로(스크롤 막대 보임) | `folder-tabs-closed id=…0001 count=1`, proj 활성·탭 그대로 | 통과 |
| ④ | 디스크에 그대로 | — | `a334-disk-before/after-remove.txt` 67줄 `cmp` 같음, `proj2\b-readme.md` 있음 | 통과 |

- **판정: 통과.**

## 12. 이월분 확인

| 이월 항목 | 증거 | 판정 |
| --- | --- | --- |
| R-3 패널 Delete = 휴지통 | trash 사례 Delete → `Do you want to trash `f1.txt`?`, 확인 → `fs-op op=trash`, 디스크에서 사라짐(§5) | 통과 |
| R-3 루트 Delete 무동작 | `delete-skipped`(skipped+1), 확인창 없음. 루트 메뉴에 Trash·Delete·Rename 없음(§7) | 통과 |
| R-3 Ctrl-N | inline 사례 Ctrl+N → 새 파일 입력칸(§4) | 통과 |
| L-247 항목 툴팁 | tooltip 사례: hover → 절대 경로(홈 아래가 아니어서 그대로), 지연 1500ms(측정 1500). `~` 치환(홈 아래)은 증거에 없고 `fsops/paths.rs` 의 단위 시험 소스만 있다 | 통과(`~` 부분은 코드·단위 시험 소스만) |
| 폴더별 트리 펼침·선택·스크롤(A-15.2) | a334: 펼침 `.;many`, 선택 `many`, 스크롤 `-234.0` 가 전환 뒤 그대로(§11) | 통과 |
| 해제 때 탭 닫기(A-13.4·A-15.1) | a334 ③ `folder-tabs-closed count=1`, 남은 폴더 탭 그대로 | 통과 |
| 루트 Remove from Project(I-555) | menu 사례 `folder-remove … via=project-panel-menu`, 디스크 `same=True`(`menu-disk-*-remove.txt` 67줄 `cmp` 같음) | 통과 |
| 우클릭 메뉴 I-520(D-042 ④) | menukeys 9개: 열린 메뉴에서 F2 → Rename 선택 표시 뒤 58ms 후 실행·입력칸, chord(Ctrl+K Ctrl+Shift+C) → Copy Relative Path, Down·Escape 는 메뉴 키, 비활성 Paste 의 Ctrl+V 는 예약·실행 없음, F2 뒤 50ms 안에 Escape → 실행 0, 루트 메뉴 Ctrl+Right → Expand All, Delete → Trash → 확인창 | 통과 |

## 13. D-042 ③ 판단 18가지 — 증거가 있는 것과 없는 것

| # | 판단 | 증거 |
| --- | --- | --- |
| 1 | 붙여넣기·복제 이름 ` copy`·` copy 1` | ` copy` 확인(`s copy.txt` 등). ` copy 1` 없음 |
| 2 | 같은 폴더 잘라 붙이기 무동작 | 판정 없음(코드에 `paste-skip-same-folder` 줄이 있음) |
| 3 | 잘라 붙인 뒤 클립보드 비움 | 확인(Paste 비활성) |
| 4 | 붙여넣기 뒤 일반 탭·패널 포커스 | 확인 |
| 5 | 새 파일 뒤 일반 탭 + 편집기 포커스 | 확인 |
| 6 | 새 항목 가상 행 자리(폴더 앞, 파일은 폴더 뒤) | 판정 없음(루트 가상 행만 확인) |
| 7 | Up/Down 끝에서 돌지 않음 | 처음에서 Up 확인 |
| 8 | Ctrl+Left 루트는 펼친 채 | 확인 |
| 9 | 루트 상대 경로 복사 = 폴더 이름 | 판정 없음(단위 시험 소스만) |
| 10 | 여러 항목 경로 복사 줄바꿈 | 확인 |
| 11 | 키보드 메뉴 위치 | 확인(302,217) |
| 12 | 확인창 창 제목 = 앱 이름 | 확인(`title="workbench-gpui"`, 스크린샷) |
| 13 | 삭제 뒤 선택 = 같은 자리 행 | 판정 없음 |
| 14 | 열린 파일을 휴지통·삭제했을 때 탭 그대로 | 판정 없음(잠긴 파일 알림 사례에서 탭 `locked.txt` 가 열린 채 유지된 것만 스크린샷으로 보임) |
| 15 | 이름 변경 때 탭 경로 새 경로 | 확인 |
| 16 | 파일 내용 UTF-8·깨진 바이트 대체 | UTF-8 한글 표시 확인, 깨진 바이트 없음 |
| 17 | 탭 없을 때 탭 바 v0.1 자리 표시 유지 | 확인(`untitled (placeholder)` 탭, menu·layout 스크린샷) |
| 18 | 폴더 클립보드 범위(창 하나에 하나) | 판정 없음 |

- 판단은 모두 leader 승인 사항이라 값을 다시 판정하지 않는다. 증거 없는 항목은 값만 적어 둔다.

## 14. Phase 1~3 결과 유지 확인

- **Phase 1**(`phase1/p4-rerun/`): `passed=true`, 실패 0, 표 밖 키 0. 키 판정 70개(9사례) 실패 0. R-1 대조: 기대 62줄 일치 62줄, 앱 내장 바인딩 56개, 표 밖 내장 바인딩 0. 56개는 이전 54개에 Phase 4 가 더한 `ctrl-alt-r`(I-532)·`ctrl-shift-enter`(I-533)(ProjectPanel 컨텍스트)이고 `results.json` 의 `r1MenuKeys` 에 따로 적혔다. 02 11.2절 단축키 열과 같은 키다. 사용자 `keymap.json`·`state.json` 전후 해시 `<absent>`.
- **Phase 2**(`phase2/p4-rerun/`): `passed=true`, 판정 137개 실패 0. `r5-shortcuts.md` "줄 31개, 불일치 0개". Phase 2 `d037-rerun` 판정과 맞춰 본 결과 시각 값을 뺀 실제 값 차이 0.
- **Phase 3**(`phase3/p4-rerun/`): `passed=true`, 판정 122개 실패 0, errors 없음, `userFiles` 전후 비어 있고 `restored: true`. Phase 3 `d037-rerun/after` 와 맞춰 본 차이 23건은 다음 때문이다.
  - 시험 폴더 경로가 `phase3-folders\run-<id>\…` 로 바뀜, UUID·시각·`.bad-` 이름이 실행마다 다름.
  - 판정 이름 3개 추가(대소문자·끝 `\` 다른 경로, A-22.6, A-28 정규화), 디스크 목록 줄 수 변경(57).
  - `quitsave` 의 저장 줄 수 2 → 1(§15-마).
  - `keys` A-17.1 한 판정의 기록된 실제 값이 기대와 달라 보임(§15-라). 앱 출력은 열림·사이드바 포커스다.
- **판정: Phase 1·2·3 결과 유지.**

## 15. 불일치 · 확인 요청 · 관찰

- **불일치(명세 값과 다른 실제 값): 0건.**
- **가. [판정 불가·leader 확인] Trash 가 휴지통 없는 볼륨에서 영구 삭제처럼 동작한다.** 증거: D: 는 이동식 드라이브로 휴지통이 없고 휴지통 설정이 `NukeOnDelete=1` 이다. 앱은 `Do you want to trash …?` 를 묻고 `trash` 크레이트가 `result=ok` 를 돌려주지만 파일은 휴지통에 없고(`count=0`) 디스크에서 사라졌다. 앱이 휴지통 없는 볼륨을 알려 주지 않는다. Zed 도 같은 OS 동작이라면 차이가 아니다. 이 보고서는 D-042 ② 대로 판정 불가로 두었고, 휴지통 안 확인·복원은 휴지통이 있는 볼륨(예: C:)에서 사람이 다시 확인해야 한다.
- **나. [범위 밖] A-14.10 `It has unsaved changes, which will be lost.`** 는 D-18 로 판정하지 않았다(탭이 보기 전용이라 수정된 버퍼가 없다). 문구가 코드에 있는지도 읽지 않았다.
- **다. [관찰] 접힌 경로 우클릭의 선택 조각.** menu 판정 `I-560`(접힌 폴더 `docs \ guides`)의 기대 값은 `docs \ guides` 인데 실제 값은 `docs` 이고 통과로 기록됐다. 키보드로 접힌 줄을 고르면 마지막 조각(`deep\l1\l2`, `docs\guides`)이 선택되는 것과 다르다. I-561(우클릭한 조각을 활성 단계로 바꾸고 그 조각 기준 메뉴를 연다)과 맞으려면 우클릭 지점이 `docs` 조각 위여야 한다. 증거에 클릭 좌표가 없어 어느 조각을 눌렀는지는 확인하지 못했다. 메뉴 항목 자체(`Unfold Directory` 포함)는 원문과 같다.
- **라. [관찰] Phase 3 재실행 판정 하나의 기록이 어긋남.** `phase3/p4-rerun/results.json` 의 `keys|A-17.1|닫힘에서 Ctrl+Alt+J → 열림 + 포커스 사이드바` 는 `got=open=false focus=center` 인데 `ok=true`. 스크립트(`tools/verify-v02-phase3.ps1`)가 같은 줄에서 실제 값을 한 번, 통과 여부를 한 번 읽어 서로 다른 시각의 값을 썼다. 같은 실행의 앱 출력 `keys-stdout.txt` 는 `[dev] sidebar open=true dock_open=true focus=sidebar` 이므로 동작은 맞다. 기록 방식의 문제이며 판정에는 영향이 없다.
- **마. [관찰] `quitsave` 저장 줄 수가 실행마다 다르다**(Phase 3 `d037-rerun` 2번, `p4-rerun` 1번). Phase 3 2회차에서 적은 "종료 때 같은 내용을 한 번 더 쓸 수 있다"는 관찰과 같은 것이다. 파일 내용은 같다.
- **바. [관찰] 인라인 입력칸 글자가 행 아래쪽에 앉는다.** `inline-rename-file-selection.png`·`inline-warning-banner.png` 에서 입력 글자가 같은 행의 일반 이름 글자보다 아래에 있고 아래 테두리에 붙는다. P-019 입력칸 높이 24·행 26 은 레이아웃 상자 측정이 없어 값으로 판정하지 못했다.
- **사. [알려진 것] 접힌 경로 `\` 가 `₩` 로 보인다**(한국어 UI 글꼴). 문자는 `\`(U+005C)다. PROGRESS 가 이미 적었다. 툴팁·접힌 경로·메뉴 경로 표시 모두 같다.
- **아. [범위] 레이아웃 판정은 처음 13행**(layout 사례)과 안내선 구간이다. 가로 스크롤(L-45)·색(L-47)·접힌 조각 padding(L-43)은 Phase 4 증거에 없다. 탭 바 치수(A-32.3~5)도 없다.
- **자. [시험 방법]** 더블클릭 판정은 먼저 한 번 눌러 임시 탭으로 연 뒤 한다(디버그 빌드의 500ms 정지 때문, EVIDENCE.md). 빠른 더블클릭이 한 번 누르기 둘로 세어지는 현상은 앱 결함인지 환경 문제인지 이 증거로 가릴 수 없다.

## 16. PLAN Phase 4 완료 조건

| 조건 | 상태 |
| --- | --- |
| R-17~R-23·R-25~R-27 이 SPEC 판정 방법대로 통과 | 충족(위 판정. R-20 의 휴지통 안 확인은 판정 불가로 별도) |
| `verify/phase4/` 에 검증 보고서, 파일 작업마다 디스크 전후 비교(휴지통 포함)와 두 시나리오 단계별 증거 | 충족. 디스크 전후: inline·clip·trash(3단)·메뉴 Remove·a334. 휴지통은 목록이 비어 있어 안 확인은 판정 불가 |
| wg-reviewer Phase 4 리뷰 결과 PROGRESS 기록 | **미충족**: PROGRESS Phase 4 항목 끝에 "Phase 4 리뷰(wg-reviewer)와 커밋은 아직이다"(438줄) |
| Phase 4 커밋 | **미충족**: 최신 커밋은 Phase 3 `e110741`. Phase 4 파일은 stage 만 됨(272개 변경). `docs/HERDR-DECISIONS.md` 는 stage 되지 않은 수정 상태 |

## 17. 판정하지 못한 것 · 다른 Phase 로 넘긴 것

- **판정 불가(환경)**: 휴지통 안 항목 확인·복원(A-14.3 휴지통 쪽, A-14.5). 휴지통이 있는 볼륨에서 사람이 확인해야 한다.
- **범위 밖(D-18)**: A-14.10 수정된 버퍼 문구.
- **Phase 5 이월**: R-24 디스크 감시(바깥에서 생기거나 지워지거나 바뀐 파일·폴더 반영), 실행 중 폴더 사라짐(A-16.3). 이번 Phase 4 증거는 바깥 변경을 다루지 않는다.
- **코드·소스로만 본 것**: L-247 `~` 치환(단위 시험 소스), 드래그 처리 없음(grep).
- **시험하지 않은 것**: Shift+Down, ` copy 1`, Cut 여러 항목, 접힌 경로 두 번째 조각 우클릭, 탭 바 치수, 입력칸 높이, D-042 판단 #2·#6·#9·#13·#14·#18 값.
- **내가 쓴 파일은 이 보고서 하나다.** 코드·다른 문서·증거는 고치지 않았다.

---

# 2회차 (D-043 반영 재검증, 2026-11-02)

증거: `d043-rerun/`(`before/`·`after/`·`phase4-full/`·`clip-before/`·`clip-after/`·`clip-results.json`·`EVIDENCE.md`), `phase1~3/d043-rerun/`, 요약 `coder-reply.md`. 1회차 절은 그대로 두었고, 증거는 다시 모으지 않았다. 앱은 돌리지 않았다.

## 18. 2회차 요약

| 항목 | 판정 |
| --- | --- |
| R-17 ~ R-23 | 통과(1회차와 같음) |
| R-25 · R-26 · R-27 | 통과(1회차와 같음) |
| 이월분 | 통과 |
| D-043 ①~⑥ 수정 | 6건 모두 고친 뒤 통과 |
| Phase 1~3 유지 | 유지 |
| 명세 값과 다른 실제 값 | 0건 |

## 19. Phase 4 전체 재실행 (`phase4-full/results.json`)

- 판정 **208개, 실패 0**, 오류 0, `passed=true`. 1회차 `results.json` 과 비교하면 판정 키(사례|ID|내용)가 **새 것 0, 빠진 것 0, ok 가 달라진 것 0** 이다. 문구·치수·디스크 판정이 1회차와 같은 값으로 통과했으므로 R-17~R-23·R-25~R-27 의 1회차 판정을 그대로 유지한다.
- 사용자 파일 before/after 모두 비어 있고 `restored=true`. 클립보드 형식 `13,16,1,7` 이 시작과 끝에서 같고 `clipboardRestored=true`. 시험 폴더(`runFolderLeft`·`baseLeft`) 남지 않음.
- 판정 불가 1건 그대로: A-14.3·A-14.5(휴지통 안 확인·복원). 휴지통 목록은 앞뒤 모두 `count=0`. D: 이동식·`NukeOnDelete=1` 이라는 D-042 ② 사정이 바뀌지 않았다. R-20 은 1회차와 같이 "통과, 휴지통 안은 판정 불가".
- 첫 시도가 trash 사례 도중 전면을 잃어 멈췄고 다시 돌린 결과라는 설명(coder-reply)을 받아들인다. 멈춘 실행의 증거는 폴더에 없다(덮어쓰지 않은 것이 아니라 남기지 않은 것).
- `phase4-full/` 의 스크린샷은 1회차 파일 이름과 같다. 이번 회차에서 새로 연 것은 `after/` 4장이다(§20). 1회차에서 연 25장의 판정은 위 키 대조가 같아 바꾸지 않는다.

## 20. D-043 수정 6건 — 고치기 전/후

`before/results.json`: 판정 13, 실패 11. `after/results.json`: 판정 13, 실패 0. 둘 다 사용자 파일 해시 같음, 시험 폴더 남지 않음(`runFolderLeft=false`).

| 결함 | 고치기 전 `before/` | 고친 뒤 `after/` | 증거 |
| --- | --- | --- | --- |
| ① 이름 변경 경로 탈출 | `..\outside.txt`·절대 경로·`sub\moved.txt`·`con.txt` 가 확정되어 실제 이동. 디스크 목록에 `\abs.txt`·`\outside.txt`(등록 루트 밖)·`ops\con.txt`·`ops\sub\moved.txt` 생기고 원본 4개 사라짐. `f2.txt:ads` 만 그때도 거부 | 다섯 입력 모두 `edit what=rejected active=true`, 입력칸 유지. 디스크 전후 67줄 `cmp` 같음(`AFTER_SAME`) | `d043-rename-stdout.txt`, `d043-rename-disk-*.txt` |
| ② 정션 자기 복사 | 3초에 A 아래 폴더 122개 | `paste-copy result=failed … error=cannot copy a folder into itself`, 폴더 0 | `d043-junction-stdout.txt` |
| ② 정션 순환 | `loopdir` 접힌 줄 조각 64개(글자 448), Ctrl+Right 펼침 2784 | 조각 1(글자 7), 펼침 12, 앱 살아 있음 | `d043-loop-stdout.txt`, `d043-loop-start.png` |
| ③ Ctrl+클릭 대상 | 뺀 `f2.txt` 가 Delete 대상, 다 뺀 뒤에도 확인창 | `marked=ops\f1.txt selected=ops\f1.txt`, 확인창 ``Do you want to trash `f1.txt`?``. 다 빼면 `selected=none`, `delete-skipped` +1, 확인창 +0 | `d043-ctrlclick-stdout.txt` |
| ④ 폴더 간 잘라 붙이기 탭 | 탭 경로 `proj\notes.txt`(옛) | `paste-move ok` 뒤 두 폴더 모두 탭 경로 `…\proj2\notes.txt`. 출발 폴더 트리에서 `notes.txt` 사라짐 | `d043-crossmove-stdout.txt`, `d043-crossmove-back-to-proj.png` |
| ⑥ comctl32 | 올리기 횟수 기록 없음 | 확인창 3번 `comctl32_loads=1` ×3(`task-dialog-result` 줄) | `d043-dialog-stdout.txt` |
| ⑤ 클립보드 형식 | 이미지(형식 8·2·17)를 넣고 고치기 전 스크립트 실행 → 끝난 뒤 `13,16,1,7` 로 바뀜, `imageKept=false` | 고친 스크립트가 "텍스트가 아닌 형식 8,2,17 … 바꾸기 전에 중단"으로 멈춤, `formatsAfterRun=8,2,17`, `imageKept=true`. 사용자 원래 클립보드는 `userRestored=true` | `clip-results.json` |

스크린샷 `after/` 4장(`d043-rename-start`·`d043-ctrlclick-start`·`d043-crossmove-back-to-proj`·`d043-loop-start`)을 열어 보았다.
- 앞의 둘과 `loop-start` 는 사례 시작 상태(등록 루트 `proj`, 접힌 줄 `deep ₩ l1 ₩ l2`·`docs ₩ guides`, 툴팁은 절대 경로)이고 결과는 stdout·디스크 목록으로 판정했다. `loop-start` 에는 `loopdir` 줄이 접힌 채 한 줄로 보인다(`up` 정션 줄도 있음).
- `crossmove-back-to-proj`: 탭 `notes.txt`·내용 `notes 한글`, 트리에 `notes.txt` 없음, 사이드바에 `proj`·`proj2`.

### 코드 쪽 확인(소스 읽기 아님, EVIDENCE.md·단위 시험 기록 기준)
- `cargo test` 39개 통과(새 시험 `d043_rename_rejects_paths_and_bad_names`, `d043_comctl32_loaded_once`), `cargo build` 경고 0이라는 기록은 PROGRESS·EVIDENCE.md 의 주장이다. 나는 빌드·시험을 돌리지 않았다.

## 21. Phase 1~3 재실행 유지 (`phase1~3/d043-rerun/`)

| 단계 | 1회차 재실행(`p4-rerun`) | 이번(`d043-rerun`) | 대조 |
| --- | --- | --- | --- |
| Phase 1 | 실패 0, 외부 키 0, `ok:true` 86개 | 실패 0, 외부 키 0, `ok:true` 86개, `ok:false` 0 | `r1-expected.tsv` 경로를 뺀 diff 없음. `r1-bindings.md` 는 생성 시각 한 줄만 다름. 내장 바인딩 `source=builtin` 56줄로 같음. 키맵 복원 `true` |
| Phase 2 | 판정 137, 실패 0 | 판정 137, 실패 0, 키 대조 새 것 0·ok 달라진 것 0 | `r5-shortcuts.md` 는 생성 시각 줄만 다름(표 줄 같음). 키맵 복원 `true` |
| Phase 3 | 판정 122, 실패 0 | 판정 122, 실패 0, 오류 0 | 달라진 키 1개는 실행 번호가 든 경로 글자뿐(`RUN-…`). 사용자 파일 복원 `true` |

- **1회차 §15-라(Phase 3 판정 기록이 낡은 값)가 이번에는 없어졌다.** `A-17.1 닫힘에서 Ctrl+Alt+J` 판정의 `got` 이 `open=true focus=sidebar` 로 기록됐다(앱 출력은 1회차도 같았다).
- 결론: Phase 1·2·3 결과 유지. Phase 1 의 R-1 62줄 일치, Phase 2 의 R-5 31줄 불일치 0 도 그대로다(§14 의 값과 같음).

## 22. 요구별 2회차 판정

R-17~R-23·R-25~R-27 의 1회차 판정이 §19 의 키 대조(새 것·빠진 것·달라진 것 0)로 유지된다. 이번에 영향을 받은 곳만 따로 적는다.

- **R-19 이름 입력(I-091·P-021·P-022)**: 입력칸 동작은 유지. 새로 추가된 거부(경로 구분자·절대 경로·`:`·`.`/`..`·끝 마침표·예약 장치 이름)는 입력칸을 연 채 두고 배너를 띄우지 않는다. 원문(P-021·P-022)에 이 경우의 문구가 있는지는 확인하지 못했다. 코더의 설명은 "원문 문구 없음"이다. → 아래 §23-카.
- **R-20 삭제·휴지통(I-090·I-562)**: Ctrl+클릭으로 뺀 항목이 더 이상 대상이 되지 않고, 다 빼면 확인창이 안 뜬다(§20 ③). 확인창 문구·기본 버튼·디스크 전후는 `phase4-full` 판정 키가 같아 유지.
- **R-21 복사·붙여넣기**: 자기 안 복사 거부 문구 `cannot copy a folder into itself`(내부 문구, A-14 원문 문구 아님). 폴더 간 잘라 붙이기 뒤 탭 경로 갱신(R-27 포함).
- **R-17 트리 / L-42 접힌 경로**: 자기를 가리키는 정션이 있어도 조각 1개로 접히고 Ctrl+Right 가 12에서 끝난다.
- **R-25·R-26·R-27 탭**: 폴더별 탭 경로가 폴더 간 이동 뒤에도 맞다(§20 ④). A-33.2·A-33.4 판정은 유지.
- **이월분**: 위 키 대조 유지. L-247 툴팁은 `after/` 스크린샷에서 절대 경로(줄바꿈 표시)로 보이고 `~` 치환은 소스 단위 시험뿐이라는 1회차 판정과 같다.

## 23. 2회차 불일치·요청·관찰

명세 값과 다른 실제 값: **0건**.

- **카. 잘못된 이름 거부에 안내가 없다(leader 결정 요청).** 경로 구분자·`:`·예약 이름 등은 거부하고 입력칸을 연 채 두는데 사용자에게 이유가 보이지 않는다. 코더는 원문 문구가 없어서라고 했다. 사람이 문구를 정하거나 "무음 거부"를 인정해야 한다.
- **타. 스크립트 보호는 텍스트 외 클립보드만 막는다.** 이미지 클립보드면 판정 스크립트가 시작하지 않는다(의도). 그때 판정 전체가 안 도는 점만 알린다.
- **파. 정션 시험은 사례 하나씩(자기 안 복사, 순환 2종)만 확인했다.** 정션이 등록 루트 밖을 가리키는 경우의 복사·삭제 동작과 심볼릭 링크 종류는 증거에 없다. 시험하지 않았다.
- **하. 1회차 관찰(가·다·바·사·아·자 등)은 이번 증거로도 바뀌지 않았다.** 접힌 경로 우클릭 선택 조각 `docs`(§15-다), 입력칸 높이 24 미측정(§15-바), `₩` 글리프(§15-사), 탭 바 치수·L-43/45/47 미측정(§15-아).
- 휴지통 없는 볼륨에서 Trash 가 영구 삭제처럼 동작하는 점(§15-가)은 C: 에서 사람이 다시 확인해야 한다. 이번에도 하지 못했다.
- 이번에도 시험하지 않은 것: Shift+Down, ` copy 1`, 여러 항목 Cut, D-042 판단 #2·#6·#9·#13·#14·#18 값.

## 24. PLAN Phase 4 완료 조건 (2회차 시점)

- 이번 증거로 R-17~R-23·R-25~R-27 과 D-043 수정이 확인됐다.
- 아직 확인할 수 없는 것: 커밋 여부(git add 만 했다고 coder-reply 에 적혀 있다. 나는 git 상태를 다시 보지 않았다), wg-reviewer 재검토 결과.
- 쓴 파일: 이 보고서 하나. 코드·다른 문서·증거는 고치지 않았다.

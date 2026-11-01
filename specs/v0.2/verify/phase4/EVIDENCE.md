# v0.2 Phase 4 검증 증거 — 프로젝트 패널 트리·파일 작업·최소 탭·시나리오

생성: 2026-11-02. 스크립트 `tools/verify-v02-phase4.ps1`. 결과 `results.json`.

## 요약

- 12개 사례, 판정 208개, 실패 0.
- 재시도 0번입니다. 더블클릭은 재시도를 한 번 허용하고 그때 `retries` 에 남기게 해 두었으나, 이번에는 쓰지 않았습니다.
- 환경 때문에 판정할 수 없는 것 1건: 휴지통 안 항목 확인·복원. 아래 "판정 불가" 절에 적었습니다.
- 정리 결과
  - 사용자 파일(%APPDATA%\workbench-gpui 의 state.json*·keymap.json): 실행 전후 SHA-256 같음.
  - OS 클립보드: 되돌림(`clipboardRestored = true`).
  - 시험 폴더(`target\phase4-folders\run-<id>`, 표지 `.wg-p4-run`): 남지 않음(`testFolders.runFolderLeft = false`).
  - 휴지통: 이번 실행 시험 폴더에서 버린 항목만 `--dev-trash purge <폴더>` 로 정리합니다. 남은 항목 0.
- 앱 실행 플래그: `--dev-keymap --dev-layout --dev-pick-folder <파일> --dev-no-shell`.
- 시험 트리
  - `proj`: README.md, notes.txt, `docs\guides\a.md`(접힌 경로), `src\{main,lib}.rs`·`src\util\mod.rs`, `deep\l1\l2\deep.txt`, `ops\{f1,f2,f3,locked}.txt`·`ops\sub\s.txt`, `many\m00~m39.txt`.
  - `proj2`: b-readme.md, other.txt.
  - 파일을 바꾸는 사례는 시작 전에 `proj` 를 다시 만듭니다.

## 사례별

| 사례 | 판정 | SPEC | 내용 | 증거 |
| --- | --- | --- | --- | --- |
| layout | 74 | R-17 | 아래 "layout" 참고 | `layout-tree.png`, `layout-stdout.txt` |
| keys | 25 | R-18, R-27 일부 | 아래 "keys" 참고 | `keys-ctrl-click.png`, `keys-shift-click.png`, `keys-tabs.png` |
| inline | 23 | R-19, R-3 이월 | 아래 "inline" 참고 | `inline-*.png`, `inline-disk-before/after.txt` |
| trash | 16 | R-20, R-3 이월 | 아래 "trash" 참고 | `trash-*.png`, `delete-*.png`, `trash-disk-*.txt`, `trash-list-after-trash.txt` |
| clip | 13 | R-21 | 아래 "clip" 참고 | `clip-disk-0-before.txt`, `clip-disk-1-after.txt` |
| menu | 27 | R-22, R-13 이월 | 아래 "menu" 참고 | `menu-01~05.png`, `menu-empty-space.png`, `menu-keyboard.png`, `menu-disk-*-remove.txt` |
| reveal | 3 | R-23 | 아래 "reveal" 참고 | `reveal-deep.png` |
| readonly | 3 | R-27·D-18 | 아래 "readonly" 참고 | `readonly-after-typing.png` |
| tooltip | 2 | L-247(Phase 2 이월) | 아래 "tooltip" 참고 | `tooltip-tree-item.png` |
| a332 | 4 | R-25 | 아래 "a332" 참고 | `a332-1~4-*.png` |
| a334 | 9 | R-26, A-15.2·R-12·R-13 이월 | 아래 "a334" 참고 | `a334-1~4-*.png`, `a334-disk-*-remove.txt` |
| menukeys | 9 | R-9 범위 I-520(D-042 ④) | 아래 "menukeys" 참고 | `menukeys-stdout.txt` |

### layout

- 루트가 맨 위에 펼친 채 있습니다.
- 정렬: 폴더 먼저, 대소문자 무시 자연 정렬.
- 접힌 경로: `docs \ guides`, `deep \ l1 \ l2`.
- 보이는 모든 행의 치수(±1)
  - 높이 26, 행 간격 26
  - 아이콘 x = 1 + 6 + 깊이×20
  - 아이콘 16×16
  - 안내선 x = 단계×20+15, 폭 1
  - 안내선 구간 첫 행 위·끝 행 아래 4

### keys

- 키보드
  - Up/Down/Home/End 는 선택만 바꾸고 열지 않습니다.
  - Right: 펼치고, 이미 펼쳤으면 다음 항목. Left: 부모로, 펼쳤으면 접기.
  - Ctrl+Right/Left: 전체 펼치기·접기.
  - Space: 임시 탭으로 열고 패널 포커스를 남깁니다.
  - Shift+Up: 범위 확장.
- 마우스
  - 폴더 누르기 = 토글, Alt+클릭 = 하위 전체 토글.
  - Ctrl+클릭 개별 표시, Shift+클릭 범위 표시.
  - 한 번 클릭 = 임시 탭(같은 자리 교체), 더블클릭·가운데 클릭 = 일반 탭 + 편집기 포커스.

### inline

- Ctrl+N 새 파일(만든 파일은 일반 탭으로 엽니다), Alt+N 새 폴더.
- F2: 확장자를 뺀 이름(`notes`)을 선택합니다. 폴더는 Enter 로 이름 전체를 선택합니다.
- Escape 는 취소하고 패널로 포커스를 돌립니다. 루트 F2 는 무동작입니다.
- 포커스를 잃으면 확정하고, 이름이 충돌하면 취소합니다.
- 오류·경고 문구를 확인했습니다.
- 확정 규칙
  - 끝 마침표 제거, `\` 로 끝나면 폴더, 중간 폴더 생성
  - 빈 이름은 거부
  - 같은 이름 이름 변경은 편집만 끝냄
- 디스크 전후 목록 비교.

### trash

- 루트 Delete 는 무동작입니다(확인창 없음).
- Delete·Backspace 는 휴지통 확인창, Shift+Delete·Ctrl+Delete·Ctrl+Backspace 는 영구 삭제 확인창입니다. 두 확인창의 문구·버튼을 확인했습니다.
- 기본 버튼은 Cancel 입니다(바로 Enter = Cancel). Esc 도 Cancel 입니다.
- 확인하면 디스크에서 사라집니다.
- 여러 항목·넘치는 목록(`.. 2 files not shown`) 문구를 확인했습니다.
- 잠긴 파일: `Failed to delete 1 of 1 file(s).` / `Failed to trash 1 of 1 file(s).`
- 사용자 키(`ctrl-t`)로 불러도 확인창이 뜹니다.

### clip

- Paste 는 붙여 넣을 것이 없으면 비활성입니다.
- Ctrl+C/V, Ctrl+Insert/Shift+Insert: 복사·` copy` 이름. Ctrl+X/V: 이동 뒤 클립보드를 비웁니다.
- Duplicate, 폴더 통째 복사.
- 경로 복사 결과(OS 클립보드): Shift+Alt+C 는 절대 경로, Ctrl+K Ctrl+Shift+C 는 상대 경로, 여러 항목은 줄바꿈으로 잇습니다.

### menu

- 다섯 종류(마크다운 파일·파일·폴더·접힌 폴더·루트)와 빈 공간 메뉴의 항목·단축키·구분선·비활성을 02 11.2절과 줄마다 대조했습니다(완전 일치).
- 우클릭한 항목이 선택이 됩니다.
- Shift+F10·Menu 키: 선택 행 왼쪽 아래 + (2, 2).
- 실행 확인
  - Unfold·Fold, 하위 폴더 Expand·Collapse All
  - Reveal·Open in Default App(실행 명령 기록)
  - Copy, Rename, Trash, Delete, New File
  - Add Folders to Project…(등록), Remove from Project(등록 해제, 디스크 같음)

### reveal

- 새 파일 `r23/a/b/c.md` 를 만들어 열면, 접힌 경로 `r23 \ a \ b` 가 펼쳐지고 c.md 가 선택됩니다.
- 포커스는 편집기에 그대로 있습니다(트리로 가지 않음).

### readonly

- 탭 내용이 파일과 같습니다(33바이트, CRLF→LF).
- 편집기에서 `XYZ 한글`·Enter·Backspace·Delete 를 입력한 뒤에도 내용(길이·FNV-1a)과 디스크 해시가 같습니다.

### tooltip

- 트리 항목 hover → 절대 경로(홈 아래가 아니면 그대로).
- 지연 1500ms(측정 1500).

### a332

1. README.md 한 번 클릭 → 임시 탭(기울임).
2. notes.txt 한 번 클릭 → 0번 자리에서 교체.
3. 더블클릭 → 일반 탭(기울임 없음), 편집기 포커스.
4. 다른 파일 한 번 클릭 → 일반 탭 뒤에 새 임시 탭.

### a334

1. proj 탭 `README.md|normal`.
2. proj2 탭 `b-readme.md|normal`(proj 탭 안 보임).
3. proj 로 돌아오면 탭·펼침(`.;many`)·선택(`many`)·스크롤(-234.0)이 그대로입니다.
4. proj2 탭도 그대로입니다.
5. proj2 해제 → `folder-tabs-closed count=1`, 디스크 목록 같음, proj 활성·탭 그대로.

### menukeys

1. 메뉴가 열린 채 F2 → Rename 선택 표시, 58ms 뒤 닫고 실행(이름 변경 입력칸).
2. Ctrl+K Ctrl+Shift+C(chord) → Copy Relative Path.
3. Down·Escape 는 메뉴 키입니다.
4. 비활성 Paste 의 Ctrl+V 는 실행하지 않습니다.
5. F2 뒤 50ms 안에 Escape → 예약 취소(실행 0).
6. 루트 메뉴 Ctrl+Right → Expand All.
7. Delete → Trash → 확인창.

## 판정 불가(환경) — 휴지통 안 항목 확인·복원(A-14.3 "휴지통으로 옮긴다"의 휴지통 쪽, A-14.5)

- 시험 폴더가 있는 D: 는 이동식 드라이브(Win32_LogicalDisk DriveType=2)라 Windows 휴지통이 없다.
- 이 PC 의 휴지통 설정(HKCU ...\BitBucket\Volume)은 `NukeOnDelete=1`("휴지통으로 이동하지 않고 바로 제거")이다.
- 그래서 Trash 는 실제로는 바로 지움이 되고, 휴지통 목록(`--dev-trash list`)에 항목이 없다(`trash-list-after-trash.txt`, `trash-final-purge.txt`).
- leader 결정(D-042 ②)대로 판정 불가로 기록하고, 사용자 시스템 설정은 바꾸지 않았다.
  - 판정한 범위: 앱이 확인 뒤 `trash` 크레이트로 보냈다(`fs-op op=trash result=ok`). 파일이 디스크에서 사라졌다.
  - Trash 와 Delete 는 서로 다른 경로를 탄다(`op=trash` / `op=delete`).
- 환경 사실은 `results.json` 의 `undetermined`, `cases.trash.recycleEnv` 에 있다.

## 시험 방법 메모

- 디버그 빌드는 파일을 처음 열 때(편집기 만들기) 500ms 넘게 멈춘다. 그래서 빠른 더블클릭이 두 번의 한 번 누르기로 세어질 수 있다(gpui 는 처리 시각으로 센다). 더블클릭 판정은 먼저 한 번 눌러 임시 탭으로 연 뒤 한다.
- 입력마다 앱 출력이 350ms 동안 잠잠해질 때까지 기다린 뒤 판정한다(`Wait-Quiet`). 화음 키는 마지막 키 뒤에만 기다린다(gpui 화음 대기 1초).
- 확인창(TaskDialog)은 우리 프로세스의 `#32770` 창을 찾는다. 확인창이 전면일 때만 키를 보내고, 확인창 자체를 캡처한다.
- Reveal in File Explorer·Open in Default App 은 사용자 탐색기·앱 창을 만들기 때문에 `--dev-no-shell` 로 실행 명령만 기록해 판정했다.
- 관리자 권한 창이 전면이면 일반 권한 시험 스크립트가 전면을 가져올 수 없다(UIPI). 그동안은 입력을 보내지 않고 멈추며, 전면이 빈 뒤 다시 돌렸다(D-042 ①).

## Phase 1~3 다시 돌리기(Phase 4 변경 뒤, 앞선 증거는 덮어쓰지 않음)

| Phase | 폴더 | 결과 |
| --- | --- | --- |
| 1 | `phase1/p4-rerun/` | 9개 사례 실패 0. R-1 일치 62, 표 밖 내장 0. 메뉴 키 2줄(I-532 Ctrl-Alt-R, I-533 Ctrl-Shift-Enter)은 `r1MenuKeys` 에 따로 기록 |
| 2 | `phase2/p4-rerun/` | 판정 137 실패 0, 단축키 대조 31줄 불일치 0 |
| 3 | `phase3/p4-rerun/` | 판정 122 실패 0, 사용자 파일 해시 같음 |

- 첫 Phase 3 다시 돌리기에서 `menus` 사례가 하나 실패했다. 메뉴는 바르게 그려졌지만 스크립트가 그 줄이 나오기 전에 읽었다. 그 자리에 최대 3초 기다리기를 넣고 다시 돌렸다.

# v0.2 Phase 4 리뷰 1회차(D-043) 수정 증거

생성: 2026-11-02. 앞선 증거(`phase4/`, `phase1~3/p4-rerun/`)는 덮어쓰지 않았습니다.

## 재현 방법

- 고치기 전 실행 파일: stage 해 둔 트리(고치기 전)를 `git checkout-index` 로 scratchpad 에 꺼냈습니다. C: 에서 따로 빌드하고 apply-manifest 를 적용했습니다.
- 사례 스크립트: `tools/verify-v02-phase4-d043.ps1`.
  - Phase 4 스크립트와 같은 안전 규칙입니다. 이번 실행 시험 폴더(`target\phase4-folders\run-<id>`) 안에서만 파일·정션을 만듭니다.
  - `-Exe` 로 고치기 전/뒤를 골라 돌렸습니다.
- 결과
  - `before/`: 고치기 전. 판정 13, 실패 11.
  - `after/`: 고친 뒤. 판정 13, 실패 0.
  - 두 실행 모두 사용자 파일 해시 같음, 시험 폴더 남지 않음.

| 결함 | 사례(판정) | 고치기 전 `before/` | 고친 뒤 `after/` |
| --- | --- | --- | --- |
| ① 이름 변경이 폴더 밖으로 | `d043-rename`: `..\outside.txt`·절대 경로·`sub\moved.txt`·`f2.txt:ads`·`con.txt` | 넷이 확정됨. 등록 루트 밖 `run\outside.txt`·`run\abs.txt`, `ops\sub\moved.txt`, `con.txt` 로 실제 이동. `:` 은 그때도 거부 | 다섯 모두 거부(입력칸 유지), 디스크 그대로 |
| ② 정션으로 자기 안 복사 | `d043-junction`: `link`(정션→A)에 A 붙여넣기 | 3초 동안 A 아래 폴더 122개(A\A\A… 끝없는 복사, UI 막힘. 앱만 닫음) | `paste-copy result=failed … cannot copy a folder into itself`, 폴더 0 |
| ② 정션 순환(접기·전체 펼치기) | `d043-loop`: `loopdir\self`(→loopdir), `up`(→proj) | 접힌 줄 조각 64개(글자 448), Ctrl+Right 펼침 2784개 | 조각 1개, 펼침 12개 |
| ③ Ctrl+클릭으로 뺀 항목이 대상 | `d043-ctrlclick`: f1 → +f2 → −f2 → Delete. 다시 −f1 → Delete | 대상 `f2.txt`(뺀 것). 다 뺀 뒤에도 f1 확인창 | 대상 `f1.txt`. 다 뺀 뒤 selected=none, `delete-skipped`, 확인창 없음 |
| ④ 폴더 사이 잘라 붙이기 뒤 출발 폴더 탭 | `d043-crossmove`: proj 에서 notes.txt 일반 탭 → 잘라내기 → proj2 루트에 붙여넣기 → proj 로 | proj 탭 경로가 `proj\notes.txt`(옛 경로) | proj 탭 경로가 `proj2\notes.txt` |
| ⑥ comctl32 참조 누적 | `d043-dialog`: 확인창 3번 | 올리기 횟수 기록 없음(확인창마다 `LoadLibraryW`, 해제 없음) | `comctl32_loads=1,1,1`. 단위 시험 `d043_comctl32_loaded_once` 도 통과 |
| ⑤ 시험 스크립트가 클립보드 형식을 잃음 | `tools/verify-v02-phase4-d043-clip.ps1` → `clip-results.json` | 1×1 이미지(CF_DIB)를 넣고 고치기 전 스크립트를 돌림 → 끝난 뒤 이미지 없음(`imageKept=false`) | 고친 스크립트는 텍스트가 아닌 형식을 보고 사용자 파일·클립보드를 바꾸기 전에 멈춤 → 이미지 그대로(`imageKept=true`) |

- ⑤ 하네스는 시작 때 사용자 클립보드(텍스트만이었음)를 저장했고, 끝에 되돌렸습니다(`userRestored=true`).

## 고친 내용

- **① `src/fsops/names.rs`, `src/ui/panel_edit.rs`**
  - `valid_component` 로 구간마다 다음을 거부합니다: `\` `/`, `:`(드라이브·스트림), `< > " | ? *`·제어 문자, `.`·`..`, 마침표로 끝나는 구간, 예약 장치 이름(CON·PRN·AUX·NUL·COM1~9·LPT1~9, 확장자 포함).
  - 이름 변경은 한 구간만 허용합니다.
  - 디스크 호출 직전에 실제 경로로 확인합니다: 이름 변경은 원래 부모 바로 아래(`ops::is_direct_child`), 새 항목은 그 폴더·등록 루트 안(`ops::is_within_real`). 아니면 거부하고 `fs-op op=*-refused-outside` 를 남깁니다.
  - 거부는 빈 이름과 같이 배너 없이 입력칸을 연 채 둡니다. 원문에 문구가 없어서입니다.
- **② `src/fsops/ops.rs`**
  - `real_path`(canonical, 없는 끝은 가장 가까운 조상을 풀고 붙임)로 자기 안 복사·이동을 막습니다.
  - 재귀 복사는 실제 경로로 들른 폴더와 방금 만든 대상에 다시 들어가지 않습니다.
  - `src/ui/panel_nav.rs` Expand All 과 `src/fsops/tree.rs` 경로 접기도 실제 경로 방문 집합으로 순환을 막습니다.
- **③ `src/ui/panel_nav.rs`, `project_panel.rs`**
  - Ctrl+클릭으로 표시에서 빼면 커서를 남은 항목(마지막)으로 옮깁니다. 다 빼면 선택을 없앱니다.
  - 작업 대상은 표시가 있고 선택이 그 안에 있으면 표시 전체입니다(하나 남았어도 그 하나).
- **④ `src/ui/panel_ops.rs` `apply_move`**
  - 붙여넣기 이동·이름 변경 뒤, 모든 폴더 Workspace 의 탭 경로를 바꿉니다.
  - 활성이 아닌 관련 폴더 트리는 디스크를 다시 읽습니다.
- **⑤ `tools/verify-v02-phase4.ps1`**
  - 시작 때 `EnumClipboardFormats` 로 형식을 봅니다. 텍스트 형식(1·7·13·16)만이거나 비어 있을 때만 진행합니다. 아니면 사용자 파일·클립보드를 바꾸기 전에 멈춥니다.
  - 끝에는 글자 또는 빈 상태로 되돌리고, 형식·글자를 다시 확인합니다(`clipboardFormatsBefore/After`, `clipboardRestored`).
- **⑥ `src/ui/task_dialog.rs`**
  - `TaskDialogIndirect` 주소를 `OnceLock` 으로 프로세스 수명 동안 한 번만 찾습니다(의도적 캐시, 모듈은 프로세스 끝까지 둠).
  - 확인창 결과 줄에 `comctl32_loads` 를 남깁니다.

## 다시 돌리기(고친 뒤)

| 대상 | 폴더 | 결과 |
| --- | --- | --- |
| Phase 4 전체 | `phase4/d043-rerun/phase4-full/` | 12개 사례, 판정 208, 실패 0 |
| Phase 1 | `phase1/d043-rerun/` | 실패 0 |
| Phase 2 | `phase2/d043-rerun/` | 판정 137 실패 0, 단축키 31줄 불일치 0 |
| Phase 3 | `phase3/d043-rerun/` | 판정 122 실패 0 |

- Phase 4 전체 실행의 첫 시도는 trash 사례 도중 전면을 잃어 입력을 보내지 않고 멈췄습니다(확인창을 닫은 직후의 일시적 전면 변화로 보입니다). 바로 다시 돌린 결과가 위 표입니다.
- `cargo build` 경고 0, `cargo test` 39개 통과(새 단위 시험 2개: `d043_rename_rejects_paths_and_bad_names`, `d043_comctl32_loaded_once`).

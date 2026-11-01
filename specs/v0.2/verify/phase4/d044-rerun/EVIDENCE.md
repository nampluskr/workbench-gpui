# v0.2 Phase 4 리뷰 2회차(D-044) 수정 증거

생성: 2026-11-02. 앞선 증거(`phase4/`, `d043-rerun/`)는 덮어쓰지 않았다.

## 결함

전역 방문 집합이 순환이 아닌 별칭(같은 폴더를 가리키는 정션)까지 건너뛰었다. 그래서 복사가 불완전한데도 Ok 를 돌려주었고, 다른 볼륨 이동은 그 결과를 믿고 원본을 지웠다.

## 재현

### 방법

- 고치기 전 실행 파일: stage 해 둔 트리(D-043 반영판)를 `git checkout-index` 로 꺼내 C: 에서 따로 빌드하고, apply-manifest 를 적용했다.
- 사례 스크립트: `tools/verify-v02-phase4-d044.ps1`. Phase 4 스크립트와 같은 안전 규칙이다.
- 결과: `before/` 판정 6 중 실패 4, `after/` 판정 6 실패 0. 두 실행 모두 사용자 파일 해시 같음, 시험 폴더 남지 않음.
- 다른 볼륨: 이 PC 에서 시험할 수 있다. 두 볼륨 모두 이번 실행이 만든 폴더만 썼다.
  - D:(이동식) — 시험 폴더 `target\phase4-folders\run-<id>`
  - C: — `%TEMP%\wg-p4-d044-<id>`(표지 `.wg-p4-d044`). 사례가 끝나면 표지가 같을 때만 지운다(`results.json` 의 `d044.cRootLeft=false`).
- 정션: 이번 실행 폴더 안에만 만들었다.
  - `proj\ali\z-data\file.txt`
  - `proj\ali\a-link` → `proj\ali\z-data`. 이름순으로 먼저 열거된다.

### 사례별 결과

| 사례 | 고치기 전 `before/` | 고친 뒤 `after/` |
| --- | --- | --- |
| `d044-alias`: ali 를 복사해 루트에 붙여넣기 | `ali copy` 에 a-link 를 따라간 사본만 있고 실제 `z-data` 가 빠짐. 결과는 Ok | `ali copy\z-data\file.txt` 있음. a-link 는 따라가지 않고 건너뜀. `copy-report … skipped_links=1 skipped=…\ali\a-link`. 원본 그대로 |
| `d044-xmove-link`: ali 를 잘라 C: 폴더에 붙여넣기 | `paste-move result=ok` 인데 원본 ali 가 지워짐(데이터 손실), 디스크 목록 달라짐 | 시작 전 거부. 원본(z-data·a-link)·대상(없음)·디스크 목록 같음. 알림 ``Cannot move `ali` to another drive because it contains links (junctions or symbolic links).`` |
| `d044-xmove-plain`: 링크 없는 `ops\sub` 를 잘라 C: 폴더에 붙여넣기 | 옮겨짐(회귀 비교용) | 옮겨짐. 복사 확인 뒤 원본 삭제, `paste-move result=ok` |

## 고친 내용 (`src/fsops/ops.rs`, `src/ui/panel_ops.rs`)

### ① 복사

- 재분석 지점(정션·심볼릭 링크, `symlink_metadata().file_type().is_symlink()`)은 따라가지 않는다.
- 건너뛴 경로는 `CopyReport.skipped_links` 에 남긴다. 맨 위 항목이 링크여도 같다.
- 순환 검사는 지금 내려온 조상 경로 집합으로만 한다. 이미 복사한 실제 폴더라도 조상이 아니면 생략하지 않는다.
- 붙여넣기·복제는 `[dev] copy-report op=… files= dirs= bytes= skipped_links= skipped=` 를 남긴다.

### ② 다른 볼륨 이동 (`move_across_volumes`)

- 원본 트리를 따라가지 않고 센다(`tree_summary`). 재분석 지점이 하나라도 있으면 시작 전에 거부한다. 아무것도 바꾸지 않고 알림을 띄운다.
- 없으면 복사한 뒤 원본과 사본의 파일 수·폴더 수·바이트가 같고 건너뛴 링크가 없을 때만 원본을 지운다.
- 다르면 원본을 두고 오류(`copy incomplete … source kept`)를 낸다.
- 알림 문구는 원문에 없어 우리가 정했다(판단).

## 다시 돌리기 (고친 뒤)

| 대상 | 폴더 | 결과 |
| --- | --- | --- |
| Phase 4 전체 | `d044-rerun/phase4-full/` | 12개 사례, 판정 208, 실패 0 |
| D-043 재현 사례 | `d044-rerun/d043-after/` | 판정 13, 실패 0(회귀 없음) |

- `cargo build` 경고 0, `cargo test` 40개 통과. 새 단위 시험 `d044_copy_report_and_verified_move` 는 같은 볼륨에서 복사 보고·확인 뒤 이동을 본다.

# v0.2 Phase 3 리뷰 2회차(D-040) 수정 증거

생성: 2026-11-01. 앞선 증거(`phase3/`, `d037-rerun/`)는 덮어쓰지 않았다.

## ⓐ 시험 폴더는 이번 실행이 만든 것만 지운다

- **수정:** `tools/verify-v02-phase3.ps1`
  - 실행마다 `target\phase3-folders\run-<id>` 를 새로 만들고 표지 파일 `.wg-p3-run`(내용 = 실행 id)을 둔다.
  - 이미 있으면 쓰지도 지우지도 않고 멈춘다.
  - 끝에는 이번 실행이 만들었고 표지 내용이 같을 때만 그 폴더를 재귀 삭제한다. 바탕 폴더는 이번 실행이 만들었고 비어 있을 때만 지운다.
  - 가드로 일찍 멈추면 폴더를 만든 적이 없으므로 아무것도 지우지 않는다.
- **하네스:** `tools/verify-v02-phase3-guard.ps1`
  - 시작 때 `target\phase3-folders\left-by-earlier-run-<id>\keep.txt`(앞선 실행이 남긴 시험 폴더 표본)를 만든다.
  - 세 사례(running·locked·normal) 뒤마다 그 파일 해시가 그대로이고 `run-*` 폴더가 남지 않았는지 본다.
  - `normal` 사례(앱 없이 `-Only quitnochange` 정상 실행)를 더했다.

| 폴더 | 스크립트 | running(④) | locked(③) | normal | 미리 있던 폴더 보존 |
| --- | --- | --- | --- | --- | --- |
| `guard-before/` | D-037 판(stage 된 것) | 통과 | 통과 | 통과 | **세 사례 모두 실패**(표본 폴더가 지워짐, 일찍 멈춘 running 포함) |
| `guard-after/` | D-040 판 | 통과 | 통과 | 통과 | **세 사례 모두 통과** |

- 사용자 파일은 두 하네스 실행 모두 전후 해시가 같다.
- `after/`: D-040 판 전체 실행 결과는 23사례, 판정 122, 실패 0이다. `results.json` 의 `testFolders.runFolderLeft = false`, `baseLeft = false` 다(바탕 폴더도 이번 실행이 만들었고 비어서 지웠다).
- 이 실행 뒤 `path.rs` 에 주석 두 줄만 더했다(동작 같음). 그 뒤 다시 빌드·시험했다.

## ⓑ A-28.5 표의 남은 부분

수작업 표가 Unicode 단순 케이스 폴딩 전체가 아니라는 점을 `specs/v0.2/DECISIONS.md` "미결 사항"에 알려진 한계로 적었다. 이후 버전에서 Unicode CaseFolding C/S 표를 들여온다. `compare_key` 주석에도 같은 내용을 적었다. 코드 동작은 바꾸지 않았다.

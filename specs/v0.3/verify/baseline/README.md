# P0-0c — v0.2 스크립트 데스크톱 기준선

- 실행일: 2026-11-03. reviewer. 검증 수준 **V3**.
- 실행 완료, 기준선 판정 **REWORK**: phase3 사이드바 폭 2개 불일치. d043-clip은 SKIP, 휴지통 내부 보관·복원은 판정 불가다. 실패를 수정하거나 성공으로 바꾸지 않았다.
- 실행 파일: `D:\projects\workbench-gpui\target\debug\workbench-gpui.exe`, P0-0b 빌드 그대로. 빌드·매니페스트 재실행 없음. SHA-256 `844E52C4BEAA976A7494FD05E9F09C4B67B7B1E0058576DCA51C2BA5DD038E54` 전후 동일.
- 조건: 사용자가 자리를 비워 입력하지 않는 상태. 시작·각 스크립트 전 기존 workbench-gpui 프로세스 없음 확인. 앱 로그의 주 화면 viewport 1920×1032, maximized=true, scale=1, rem=16. 지정 스크립트가 만드는 상태·판정만 수행했고 수동 기능 조작이나 별도 실측은 하지 않았다.
- 실행 순서와 exit code: `run-index.json`. 스크립트 목록의 순서대로 실행했으며 phase3 실패 뒤에도 다음 스크립트를 진행했다. phase3-guard는 제외했다.
- 모든 실행에 명시적 `-OutDir specs\v0.3\verify\baseline\<스크립트 이름>`과 위 절대 `-Exe`를 전달했다. d043-clip은 실행하지 않았다.

## 최종 결과와 노트북 대조

통과/실패는 `results.json.checks[].ok` 기준이다. phase1은 checks 배열이 없는 형식이므로 사례 수·failures 및 R-1 대조를 따로 표시한다. 노트북 경로는 모두 읽기 전용 `specs/v0.2/verify/` 아래다. 최종 D-047 반영판의 재실행 기록을 우선 비교했다.

| 스크립트 (`verify-v02-` 생략) | 데스크톱 통과 / 실패 | 기타 | 노트북 결과·비교 경로 | 차이 분류 |
|---|---|---|---|---|
| phase1 | 9사례, failures 0; R-1 62/62 | 첫 실행 실패 1 → 재실행 성공 | 9사례, 실패 0; `phase1/d047-rerun` | 최종 동일. 최초 실패는 기타: 기대표 파일 누락 |
| phase2 | 137 / 0 | 단축키 31줄 불일치 0 | 137/0; `phase2/d047-rerun` | 동일 |
| phase3 | 120 / 2 | 23사례, cleanup errors 0 | 122/0; `phase3/d047-rerun` | 코드 회귀 의심: 창 크기/분할 비율 계산 또는 폭 복원. 원인 미확정 |
| phase4 | 208 / 0 | 12사례, 판정 불가 1 | 208/0, 판정 불가 1; `phase4/d047-rerun` | 통과 수 동일. 휴지통 불가의 환경 원인은 다름 |
| phase4-d043 | 13 / 0 | 6사례 | 13/0; `phase4/d043-rerun/after` | 동일 |
| phase4-d043-clip | 실행 안 함 | SKIP | before imageKept=false, after=true, userRestored=true; `phase4/d043-rerun/clip-results.json` | 기타: 과거 Before 스크립트 부재 |
| phase4-d044 | 6 / 0 | 3사례 | 6/0; `phase4/d044-rerun/after` | 동일 |
| phase5 | 62 / 0 | 7사례 | 62/0; `phase5/d047-rerun/phase5-full` | 동일 |
| phase5-d046 | 23 / 0 | 6사례 | 23/0; `phase5/d047-rerun/d046-after` | 동일 |
| phase5-d047 | 16 / 0 | 4사례 | 16/0; `phase5/d047-rerun/after` | 동일 |

checks 배열이 있는 8개 실행은 합계 **585 통과 / 2 실패 (587개)**. 모든 실행의 cleanup errors는 0이다. 상세 집계·사례 이름·실패 문구·비교 경로는 `comparison.json`에 있다. 각 스크립트 폴더에 원본 `results.json`, `console.log`, 스크린샷 및 사례별 stdout 등이 있다.

## phase3 불일치

| 사례·요구 | 기대 | 실제 | 근거 | 분류 |
|---|---:|---:|---|---|
| state / R-28 시작 폭 | 300 | 375 | `verify-v02-phase3/results.json`, `state-stdout.txt` | 코드 회귀 의심, 환경별 레이아웃 차이 가능 |
| state-restart / R-28 저장 폭 복원 | 494 | 617 | 같은 폴더의 `results.json`, `state-restart-stdout.txt` | 코드 회귀 의심, 환경별 레이아웃 차이 가능 |

두 값은 약 1.25배다. 그러나 해당 앱 로그는 scale=1·rem=16이므로 DPI 125%라고 설명할 근거가 없다. 시작 시 sidebar_width를 px로 넘기는 경로(`src/ui/mod.rs:500` 부근)와 resizable 분할 크기 정규화가 조사 후보다. 이번 카드에서는 원인 확정이나 코드 수정을 하지 않았다. 타이밍 문제라고 볼 증거도 없다. 결정적인 입력·좌표 실패가 아닌 동일 방향의 폭 차이라 추가 재실행을 하지 않았다.

## 재실행 및 d043-clip

- phase1 첫 실행은 출력 폴더의 `r1-expected.tsv`가 없어서 base 사례에 실패 1개를 기록했다. v0.2 PROGRESS 567·632행에도 같은 전제조건과 기존 기대표 복사 방법이 기록되어 있다.
- `specs/v0.2/verify/phase1/r1-expected.tsv`를 읽어 복사한 뒤 phase1만 **1회 재실행**했다. 최종 exit 0, 9사례, failures/errors/foreignKeys 0, R-1 62줄 일치·표 밖 0. 첫 실행의 전체 증거는 `_attempts/phase1-first/`, 재실행 콘솔은 `verify-v02-phase1/console-retry.log`에 보존했다. `run-index.json`의 phase1 exit=1은 첫 실행 기록이므로 최종 결과와 구분한다.
- 다른 스크립트는 각각 1회 실행, 전체 스크립트 재실행 없음. 스크립트 안에 원래 포함된 더블클릭 등의 재시도는 수정하지 않았다.
- d043-clip은 v0.2 PROGRESS 448·453행 및 `clip-results.json`을 확인했다. 당시 `-Before`는 노트북 임시 경로 `.../scratchpad/p4-before/tools/verify-v02-phase4.ps1`, `-After`는 고친 현행 스크립트였다. 현재 그 임시 파일은 없고, Git에서 phase4 스크립트를 최초 도입한 `12790c0`의 부모에도 해당 파일이 없다. 현행판을 Before로 넣으면 수정 전/후 재현이 아니므로 건너뛰었다. wrapper 자체에는 Exe 파라미터도 없다. `verify-v02-phase4-d043-clip/skip.txt`에 기록했다.

## 휴지통 A-14.3·A-14.5

- **A-14.3 중 디스크에서 사라짐·trash 호출 성공은 통과**했다. `fs-op op=trash result=ok`, `f1=False`다. 영구 삭제 및 휴지통에 없는 것에 대한 별도 판정도 통과했다.
- **휴지통 내부에 f1이 있음(A-14.3의 휴지통 쪽), 휴지통에서 원위치 복원(A-14.5)은 판정 불가**다. `trash-list-after-trash.txt`는 `count=0 total=0`, results의 undetermined에 그대로 남아 있다. 복원 판정은 실행되지 않았다.
- 노트북: D: DriveType=2(이동식), NukeOnDelete=1. 데스크톱: D: DriveType=3(Fixed), NTFS지만 **D:의 NukeOnDelete도 1**이다. 휴지통 폴더가 있는 것과 해당 드라이브에서 휴지통을 사용하도록 설정된 것은 다르다.
- 실제 D: 볼륨은 `{bf551e66-c509-4f55-ac18-5c81da6799d5}`다. Win32_Volume과 동일 GUID의 `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\BitBucket\Volume` 값을 읽어 대응을 확인했다. 증거 `_backup/final.json`의 driveType=3, fileSystem=NTFS, nukeOnDelete=1.
- 검사 함수 `tools/verify-v02-phase4.ps1:822`는 모든 볼륨의 NukeOnDelete를 합산해 하나라도 1이면 available=false로 만든다는 한계도 있다. 이번에는 별도 읽기로 D: 자체가 1임을 확인했으므로 다른 볼륨만의 영향이라고 분류하지 않는다.
- 분류: **환경 / 드라이브·휴지통 설정**. 사용자 설정을 바꾸거나 휴지통 동작을 우회하지 않았다. 향후 사용자가 D: 설정을 바꾼 뒤 별도 승인된 카드로 다시 판정할 수 있다.

## 사용자 데이터 보호·최종 상태

- 실행 전 모든 대상 스크립트를 검색해 데이터 경로·백업·정리를 확인했다. phase1·2는 keymap 임시 교체와 state 불변 검사를, phase3~5·d043·d044·d046·d047은 state.json*·keymap 백업/복원을 한다. 시험 폴더는 target의 GUID run 폴더이며 표지를 검사한 뒤 정리한다. d043-clip은 클립보드를 바꾸는 wrapper지만 이번에는 실행하지 않았다.
- 공통 실행기 `run-p0-0c.ps1`이 시작 전에 `%APPDATA%\workbench-gpui` **전체 폴더**를 `_backup/appdata`로 복사하고 SHA-256 목록을 `_backup/before.json`에 기록했다. 시작 폴더는 존재했지만 파일은 없었다. 각 스크립트 자체 복원 외에 전체 실행 후 백업 복원·해시 대조도 수행했다.
- `_backup/after.json`: 전체 순서 종료 후 restored=true. `_backup/final.json`: phase1 재실행까지 종료한 뒤 restored=true, exeUnchanged=true, appRunning=false. 사용자 클립보드 복원도 각 해당 results의 clipboardRestored로 기록된다.
- phase1 재실행은 공통 백업 래퍼 밖에서 수행했다. **재실행 종료 후 별도 승인된 호스트 PowerShell 7에서 실제 `%APPDATA%\workbench-gpui`를 재귀 조회하여 파일별 SHA-256 목록을 만들고 `_backup/before.json.files`와 대조했다.** 시작 목록과 최종 목록은 모두 `{}`(파일 없음)로 같았다. 그 결과가 `_backup/final.json`의 `files={}`, `restored=true`다. 차이가 없어 `_backup/appdata`에서 추가 복원할 필요는 없었다. 이는 재실행 전의 `_backup/after.json` 확인과 별개의 최종 대조다.
- 재실행에 사용한 기대표 출처는 **`specs/v0.2/verify/phase1/r1-expected.tsv`**이며, 복사 목적지는 **`specs/v0.3/verify/baseline/verify-v02-phase1/r1-expected.tsv`**다. 지난 버전 원본은 읽기만 했으며 기대값을 수정하거나 새로 만들지 않았다.
- src·tools·지난 버전 폴더를 수정하지 않았고 git 커밋하지 않았다. PROGRESS·TASKS·HANDOFF는 lead 소유이므로 이 결과를 전달한다.
- 남은 것: phase3 폭 불일치 조사, Before 원본이 없는 d043-clip, 시스템 설정 때문에 불가한 휴지통 내부·복원 판정. 수동 시각 품질과 P0-6 실측은 수행하지 않았다.

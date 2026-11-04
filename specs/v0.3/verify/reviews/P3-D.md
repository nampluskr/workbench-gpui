# P3-D — P3-D1·P3-D2 묶음 리뷰

What this change does: 복사 대상 파일을 배타 생성해 기존 파일 덮어쓰기를 막는다. 다른 볼륨 이동에서는 복사 전후 원본 목록·크기·수정 시각을 비교한 뒤 삭제한다.

- reviewer: Codex, 2026-11-04. work/ui HEAD `282cfae`, worktree `D:\projects\workbench-gpui\.worktrees\ui`, 검증 전후 작업 트리 깨끗함.
- 리뷰 diff: `7f5e083^..157808e -- src` (D1 `7f5e083`, D2 `157808e`). 기준: AGENTS 7.1·7.1a, TASKS P3-D1·P3-D2, AUDIT 1·2, ponytail-review. 단일 사용자 Windows 편집기에서 외부 프로그램도 같은 파일을 수정하는 조건을 가정했다.

## Must fix

1. **교차 볼륨 이동이 NTFS 추가 데이터 스트림을 버린 뒤 원본을 삭제한다.**
   - 위치: `src/fsops/ops.rs:144–150` copy_file, `:257–270` move_verified.
   - What this is: File::open + io::copy는 기본 데이터 스트림만 복사한다. 기존 Windows fs::copy는 CopyFileEx를 통해 추가 NTFS 스트림도 복사했다. 이 차이는 Rust 표준 문서에 명시돼 있다. [Rust fs::copy](https://doc.rust-lang.org/std/fs/fn.copy.html)
   - Problem: 예를 들어 NTFS 원본 `a.txt`의 본문이 abc이고 `a.txt:notes`에 사용자 데이터가 있을 때, NTFS 대상에 기본 본문만 복사된다. tree_summary와 snapshot에는 ADS가 없으므로 대조는 성공하며 delete(src)가 notes의 유일한 원본까지 삭제한다. 원본이 복사 중 변경되지 않아도 발생한다. Zone.Identifier 같은 스트림도 누락되어 출처 정보가 사라진다. 이는 단순 속성·시각 차이를 보고하는 것으로 수용할 수 없는 데이터 손실이다.
   - Fix: 배타 생성 보호를 유지하면서 ADS를 보존·검증하거나, 지원하지 못하는 ADS가 있는 파일은 원본 삭제 전에 오류로 거부해 원본을 남긴다. 하위 파일에도 같은 보호를 적용한다. 기본 본문과 명명된 스트림을 가진 파일로 교차 볼륨 경로를 호출하는 최소 회귀 테스트를 남겨 보존 또는 명시적 거부를 단언한다. 플랫폼 복사 API를 선택한다면 기존 파일 덮어쓰기 금지도 계속 보장해야 하며, TASKS의 구현 방식 변경은 lead/사용자 결정으로 한다.
   - If we skip it: 잘라 붙이기가 성공으로 끝나지만 사용자 데이터가 복구 불가능하게 사라진다. 본문 바이트 수만 확인하는 현재 테스트들은 이를 잡지 못한다.

## 정확성·요구 충족 확인

- D1: copy_entry의 파일 경로와 copy_dir의 모든 하위 파일 경로가 공통 copy_file을 사용한다. create_new(true)는 존재 확인과 생성을 분리하지 않으며, 이미 있는 파일은 쓰기 전에 AlreadyExists로 반환한다. 소스 open 실패도 대상 생성 전에 전파된다. 기존 대상 보존 테스트가 오류 종류와 기존 내용 old를 검사한다.
- 복사 중 io::copy 오류는 그대로 반환한다. 생성한 부분 대상은 remove_file을 시도하지만 정리 실패는 무시한다. 따라서 '항상 부분 파일이 제거된다'는 보장은 없다. 디렉터리 부분 복사도 남을 수 있으며 원본은 삭제하지 않는다. 정리 실패 자체를 새로운 데이터 보존 보장으로 해석하지 않는다.
- D2: tree_summary의 기존 링크 거부 → 원본 snapshot → copy_entry → 대상 요약 대조 → 원본 snapshot 재대조 → delete 순서다. 상대 경로, 디렉터리 여부, 파일 크기, 수정 시각을 정렬하므로 열거 순서 차이로 실패하지 않는다. 추가/삭제/이름 변경과 크기·시각 변경을 감지하면 원본과 복사본을 남기고 Err를 돌려준다. snapshot/read_dir/metadata/copy/요약/delete 오류는 ?로 전파된다.
- 수정 시각 조회는 modified().ok()여서 조회 실패를 None으로 기록한다. 같은 크기와 같은 시각으로 돌아온 변경, 파일 정체만 바뀐 경우, snapshot 자체의 비원자성은 검출 보장 밖이다. 이는 콘텐츠 해시·파일 ID·잠금 기반 검증이 아니며 '모든 원본 변경을 막는다'고 표현하면 안 된다.
- `shortcut:` 주석은 마지막 비교 뒤 삭제 사이의 경쟁과 잠금/핸들 기반 삭제로 확장할 조건을 명시한다. 승인된 D2의 비교 기반 보호 범위에 맞는다. 다만 ADS 누락은 이 경쟁과 무관하게 발생하므로 위 1번으로 별도 차단한다.
- D2 테스트는 기존 `d044_copy_report_and_verified_move`에 사례를 추가했다. 복사 후 a.txt를 3→4바이트로 바꾸고 Err, 변경된 원본 파일 존재, 복사본 루트 존재를 확인한다. 전용 새 테스트 이름 하나가 늘어난 것은 아니지만 요청한 원본 변경 시 보존 사례가 실제 실행된다. 원본/복사본 전체 내용 일치나 같은 크기 변경은 이 테스트의 보장 밖이다.
- panel_ops.rs 호출부: paste의 copy/move 및 duplicate가 그대로 공통 함수를 쓴다. Err이면 apply_move/created 등록을 하지 않으므로 실패한 이동을 성공으로 UI에 반영하지 않는다. 일반 오류는 dev 로그만 남기고 cut 클립보드는 실패해도 비우는 기존 AUDIT 3 한계가 남는다. 해당 UI 개선은 v0.4로 보류된 범위이며 이번 카드에서 변경하지 않았다.

## fs::copy와의 차이 및 데이터 영향

| 항목 | 판정 |
| --- | --- |
| 기본 본문 | io::copy로 복사, 바이트 수/파일 수 확인. 본문 해시 검증은 기존에도 없음. |
| 파일 속성·권한 비트 | 원본 readonly 등 속성을 복사하지 않음. 생성한 대상의 기본 속성 사용. D1 비고가 보고를 요구한 차이로 남기며 보호 속성 손실에 유의. |
| 생성/수정/접근 시각 | 명시 복제 없음. 특히 수정 시각이 새 복사 시각이 되어 도구의 변경 판정에 영향을 줄 수 있음. |
| ADS·확장 데이터 | 기본 스트림 밖의 데이터가 복사되지 않음. 교차 볼륨 이동에서 원본 삭제 시 영구 손실, 위 1번 차단 사항. |
| ACL·보안·암호화 | 생성 파일은 대상 위치의 기본 보안 설정을 사용하며 원본의 보안 메타데이터를 명시적으로 옮기지 않음. 기존 CopyFileEx가 모든 ACL/소유자를 항상 그대로 복사했다고 단정하지 않는다. 보안 resource attributes와 EFS 암호화 처리 등 기존 플랫폼 API의 정책도 새 스트림 복사에는 없다. |

CopyFileEx는 파일 속성·확장 속성·ADS·security resource attributes를 보존하며, EFS 복사 때 암호화를 시도하고 불가능하면 기본적으로 실패하는 정책이 있다. 새 코드는 이를 수행하지 않아 암호화된 원본도 읽기 권한이 있으면 기본 비암호화 대상에 본문을 쓸 수 있다. 민감한 파일에 대한 플랫폼 보존 정책도 ADS 수정과 함께 검토해야 한다. [Microsoft CopyFileExW](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-copyfileexw)

## 실행 검증 — V1, 병합 직전 전체 테스트 겸용

- 실행 디렉터리: 지정 worktree. CARGO_TARGET_DIR=`D:\projects\workbench-gpui\target`. cargo bin을 PATH에 추가하고 `rtk proxy C:\Users\nampl\.cargo\bin\cargo.exe`로 실행했다.
- `cargo test` 전체 **1회**: exit 0, **59 passed / 0 failed / 0 ignored**. copy_keeps_existing_destination, D2가 확장한 d044 테스트, R1 disabled 테스트 포함.
- `cargo clippy --all-targets` **1회**: exit 0. 고유 경고 **10개, 신규 0개**, bin/test 중복 출력 제외. 기준선과 같은 dev.rs 2개, fsops ident/names/tree 각 1개, state 문서 1개, ui keymap 1개·layout 문서 2개·watch 1개다.
- R1과 같은 실행 결과를 공유했다. 별도 전체 테스트·clippy 재실행 없음. 앱 실행·src 수정·커밋 없음. build 명령을 별도로 추가하지 않았으며 cargo test가 변경 코드를 컴파일했다.

## ponytail-review 및 전달

공통 파일 복사 지점 재사용과 작은 원본 snapshot은 범위에 맞는다. 새 의존성·설정·범위 밖 리팩토링은 없다. 데이터 손실 보호가 우선이므로 코드량 절감을 이유로 위 1번을 생략할 수 없다.

Verdict: fix 1 first.

- 실측 필요: 없음.
- 사용자 확인 필요: 시각 품질 없음. 파일 메타데이터 보존 정책은 lead/사용자 결정 사항이며 위 ADS 데이터 손실을 자동 승인한 것으로 해석하지 않는다.
- PROGRESS·TASKS·HANDOFF는 lead 소유이므로 이 보고서로 결과·검증·잔여 한계를 전달한다. P3-R1은 별도 phase3-final.md R1 절에서 PASS로 판정했다.
- Not checked: 실제 서로 다른 볼륨·NTFS ADS/EFS/ACL의 실행 재현, 실패 I/O 주입, 앱 실행은 생략했다. ADS 손실은 복사/삭제 코드와 플랫폼 문서로 확인했으며 현재 테스트로는 보호되지 않는다.

결론 REWORK

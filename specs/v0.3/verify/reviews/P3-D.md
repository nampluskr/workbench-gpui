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

## R1

What this change does: `683bbfc`는 목적 이름을 create_new로 먼저 확보하고 핸들을 닫은 뒤 fs::copy로 채운다. 기본 스트림만 복사하던 경로를 Windows 플랫폼 복사로 되돌려 ADS·속성·수정 시각을 보존한다.

- 대상: work/ui `683bbfc`, 부모 `282cfae`, worktree `D:\projects\workbench-gpui\.worktrees\ui`. 검증 전후 작업 트리는 깨끗했다. H-31은 master의 `specs/v0.3/HERDR-DECISIONS.md:109–111`을 읽어 확인했다(worktree에는 아직 없음).
- diff 범위: src/fsops/ops.rs의 copy_file 및 새 테스트만 변경. 모든 copy_entry/copy_dir 호출부와 move_verified, panel_ops 연결을 다시 확인했다. src 수정·커밋·앱 실행 없음.

### 기존 REWORK 1 판정

해소됐다. copy_file이 더 이상 io::copy로 기본 스트림만 옮기지 않는다. Windows fs::copy의 ADS 보존 경로가 일반 파일과 모든 하위 파일에서 공통으로 사용된다. 신규 테스트에서 실제 이름 있는 `:notes` 스트림 내용을 읽어 확인했고 성공했다. 플랫폼 정책은 앞 절에 인용한 [Rust fs::copy 문서](https://doc.rust-lang.org/std/fs/fn.copy.html)의 Windows 동작에 근거한다. D2가 이 복사를 완료한 뒤 원본을 삭제하므로 이전의 '고정된 원본에서도 ADS를 버리고 삭제' 경로는 제거됐다.

### 정확성 및 잔여 한계

- 배타 확보: create_new(true)의 실패는 ?로 즉시 반환하며 fs::copy와 정리 콜백을 실행하지 않는다. 따라서 확보 시점에 이미 존재한 파일은 AlreadyExists로 보존된다. 성공한 File 임시값은 해당 문장 끝에서 drop되므로 다음 fs::copy 전에 핸들이 닫힌다. 플랫폼 복사가 확보한 빈 파일을 덮어쓰는 것은 H-31에 부합한다.
- 하위 파일: copy_entry의 단일 파일과 copy_dir의 하위 파일 모두 같은 copy_file을 사용한다. 폴더 생성·링크 건너뛰기·자기 아래 복사 방지 및 CopyReport 집계는 변경하지 않았다.
- 읽기 전용 원본: 대상은 최초 확보 시 기본 쓰기 가능 파일이다. 원본 readonly 속성의 복제는 fs::copy에 맡기므로 앞 구현의 속성 누락을 복구한다. 성공 뒤 대상이 readonly가 되는 것은 정상 플랫폼 복사 결과다. readonly 원본을 교차 볼륨 이동할 때 원본 삭제가 권한 오류로 실패할 수 있지만, delete의 Err가 그대로 전파되고 원본은 남는다. 이를 성공으로 처리하는 새 분기는 없다.
- 암호화 원본: EFS 관련 처리와 실패 정책도 fs::copy/CopyFileEx에 맡긴다. 평문 io::copy로 우회하거나 플랫폼 복사 실패 후 다른 복사 방식으로 재시도하지 않는다. 모든 ACL·소유권을 완전히 복제한다고 확대 해석하지 않는다. 실제 EFS 대상 볼륨 조합의 보존·거부 여부는 이번 실행으로 확인하지 않았다.
- 오류 시 정리: fs::copy가 Err일 때만 확보 대상 경로의 remove_file을 시도하고 원래 복사 오류를 유지한다. create_new 실패 뒤 남의 기존 파일을 지우는 경로는 없다. 다만 remove_file의 오류는 무시되므로 권한·readonly 속성·외부 핸들 등에 따라 빈 파일 또는 부분 복사본이 남을 수 있다. 주석의 'removed'는 정리 시도를 뜻하는 범위로만 수용하며 정리 성공 보장은 아니다. 이 best-effort 한계는 직전 구현에도 있었다.
- 확보 이후 경쟁: 핸들을 닫았으므로 다른 프로세스가 파일을 쓰거나 삭제·교체하면 fs::copy가 그 내용을 덮거나, 복사 실패 뒤 정리가 교체된 경로를 지울 수 있다. '확보 파일만'이라는 보장은 다른 프로세스가 그 경로를 바꾸지 않는 조건에서만 성립한다. H-31이 승인한 확보~복사 경쟁 범위로 명시하며 원자적 no-overwrite 보장으로 보고하지 않는다. shortcut 주석은 쓰기 경쟁을 명시한다. 주석의 향후 CopyFile2 제안 자체가 열린 핸들 API/정체 보존을 보장하는 것은 아니며, 후속 설계 때 실제 플랫폼 API 계약을 확인해야 한다.
- D2: 복사 이전 snapshot과 삭제 직전 snapshot 대조 순서는 그대로다. fs::copy가 대상 수정 시각을 복제해도 비교 대상은 원본 전후이므로 대조를 무력화하지 않는다. 반환 바이트 수는 기본 스트림 크기라 기존 tree_summary 집계와 맞는다. 복사 실패·원본 변경·대상 요약 불일치 때는 delete까지 가지 않는다. 기존 D2 테스트도 통과했다.
- panel_ops: 일반 오류를 dev 로그로만 알리는 AUDIT 3, 실패한 cut 클립보드 정리 정책은 기존 보류 사항 그대로다. 이번 수정으로 오류를 성공으로 바꾸거나 apply_move 호출을 늘리지 않았다.

### 테스트의 의미

`copy_keeps_streams_and_mtime`는 기본 본문 body와 명명된 ADS note를 만들고, 원본 수정 시각을 과거의 고정값으로 설정한 뒤 운영 copy_entry를 호출한다. 대상 본문·ADS의 실제 바이트와 원본/대상 수정 시각을 단언한다. 이전 io::copy 구현이면 ADS가 없거나 시각이 달라 실패하므로 의미 있는 회귀 테스트다. 테스트를 건너뛰는 분기가 없으며 이번 Windows 환경에서 실제 통과했다.

한계: 테스트는 일반 파일 복사 한 건이며 실제 교차 볼륨 삭제, readonly/EFS/ACL, 하위 파일 ADS 및 복사 오류 정리를 직접 실행하지 않는다. 이 경로들은 공통 함수 재사용과 호출 흐름으로 확인했다. 기존 대상 보존 테스트와 D2 변경 감지 테스트도 함께 실행됐다.

### 실행 검증 및 ponytail-review

- 실행 위치: 지정 worktree. CARGO_TARGET_DIR=`D:\projects\workbench-gpui\target`, cargo bin을 PATH에 추가하고 RTK proxy로 실행.
- `cargo test` 전체 정확히 1회: exit 0, **60 passed / 0 failed / 0 ignored**. 신규 copy_keeps_streams_and_mtime 포함.
- `cargo clippy --all-targets` 정확히 1회: exit 0, **기준선 고유 경고 10개 / 신규 0개**. dev 2, fsops ident/names/tree 각 1, state 문서 1, ui keymap 1·layout 문서 2·watch 1. bin/test의 중복 진단은 별개 경고로 세지 않았다.
- ponytail-review: 기존 플랫폼 기능 재사용으로 이전보다 코드가 단순해졌고 의존성·설정 추가가 없다. H-31에서 승인한 경쟁 한계 안에서 새 차단 결함은 발견하지 못했다. 이전 REWORK 1은 종료한다.
- Verdict: Ship, within H-31's stated race limit.
- 실측 필요/사용자 확인 필요: 신규 없음. PROGRESS·TASKS·HANDOFF는 lead가 이 결과로 갱신한다.
- Not checked: 앱·실제 교차 볼륨·EFS/ACL·I/O 실패 주입은 생략했다. 확보 이후 경로 경쟁 및 정리 실패로 부분 대상이 남을 가능성은 계속 존재한다.

결론 PASS

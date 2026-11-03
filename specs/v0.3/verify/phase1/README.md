# P1-E — Phase 1 끝 R-12 재실행, R-8·R-9

- 실행일: 2026-11-03, measure, V3. 사용자 부재(H-26). master `1e73c44`, 디버그 빌드 + `tools/apply-manifest.ps1` 후 exe SHA-256 `E40C2FDF…23380` 전후 동일(`_backup/after.json`).
- 실행기: `run-phase1.ps1`(= `baseline/run-p0-0c.ps1` 복사, 출력 폴더만 `phase1/`, phase1은 `r1-expected.tsv` 미리 복사, d043-clip은 SKIP). 순서·exit code: `run-index.json`, 로그 `run.log`.
- 앱 데이터: 실행 전 전체 백업(`_backup/`), 종료 후 `after.json` restored=true. R-8 세션도 `session.ps1` Start/Stop으로 백업·복원(`_p1-e-session-backup/`, Stop 결과 restored=true, fixtureRemoved=true). 실행 전후 workbench-gpui 프로세스 없음.

## (2) R-12 기준선 대조 (`comparison.json`, 스크립트 `compare-baseline.ps1`)

항목 키는 `case|id|what`, 차이는 `ok` 뒤바뀜 또는 한쪽에만 있는 항목이다(got·expect 문자열은 GUID·경로·시각이 들어 있어 비교하지 않음).

| 스크립트 (`verify-v02-`) | exit | 기준선 통과/실패 | 이번 통과/실패 | 항목 대조 |
| --- | ---: | --- | --- | --- |
| phase1 | 0 | 9사례, failures 0, R-1 62/62 | 9사례, failures 0 | 사례 이름·R-1 바인딩표 동일(생성 시각 줄 제외). 변화 없음 |
| phase2 | 0 | 137 / 0 | 137 / 0 | 항목 차이 0. 변화 없음 |
| phase3 | 1 | 120(122중) / 2 | 120 / 2 | 실패 2개 그대로: R-28 시작 폭 기대 300·실제 375, 저장 폭 복원 기대 494·실제 617. **Q-15 기준선과 같아 변화 없음** |
| phase4 | 0 | 208 / 0 | 208 / 0 | 항목 차이 0(R2 재실행). 판정 불가 1(휴지통 내부·복원 A-14.3/A-14.5)도 기준선과 같음 |
| phase4-d043 | 0 | 13 / 0 | 13 / 0 | 항목 차이 0(R2 재실행) |
| phase4-d043-clip | SKIP | SKIP | SKIP | 기준선과 같은 사유 |
| phase4-d044 | 0 | 6 / 0 | 6 / 0 | 항목 차이 0(R2 재실행) |
| phase5 | 0 | 62 / 0 | 62 / 0 | 항목 차이 0 |
| phase5-d046 | 0 | 23 / 0 | 23 / 0 | 항목 차이 0 |
| phase5-d047 | 0 | 16 / 0 | 16 / 0 | 항목 차이 0 |

- 실행된 5개 스크립트(체크 있는 4개 + phase1)에서 `ok` 뒤바뀜 0. 합계 360개 체크 중 358 통과, 실패 2(위 phase3, 기준선과 동일).
- `comparison.json`의 `itemDiffs`에 남은 phase3·phase5 각 1쌍은 항목 이름 자체에 실행 GUID 경로·이벤트 수(1811→1818)가 들어 있어 키가 어긋난 것이며 양쪽 모두 ok=True다(실질 차이 아님).
- phase2 `L-232 sidebar-btn-toggle` 툴팁 문구가 이번엔 "Toggle Sidebar", 기준선엔 "Focus Sidebar"였다(둘 다 통과, 기대값도 같이 바뀌는 스크립트 동작). 참고로만 기록.

### phase4 계열 첫 실행 중단(R1·R1 재실행 포함, R2에서 해소)

- phase4·d043·d044 모두 같은 메시지로 즉시 중단: `OS 클립보드에 텍스트가 아닌 형식이 있다(형식 번호 49161,49171). 그대로 되돌릴 수 없어 사용자 파일·클립보드를 바꾸기 전에 중단한다`. 클립보드 형식 열거 결과 `49161,13,49171,16,1,7`(사용자 클립보드 내용).
- 스크립트의 사용자 데이터 보호 동작이다(user files restored=True). 사용자 클립보드를 비우거나 바꿔서 우회하지 않았다.
- 재실행 안 함: 원인이 현재 클립보드 상태(결정적)라 같은 조건에서 다시 돌려도 같은 결과다. 사용자가 클립보드를 비우거나 텍스트만 남긴 뒤 이 3개만 재실행하면 된다(`run-phase1.ps1`의 `$names`를 줄여 쓰되 `_backup` 폴더 충돌에 주의). 재실행 0회.

## (3) R-8 덤프 JSON (`layout.json`, 세션 산출물 `p1-e-session/`)

- 실행: `session.ps1 -Action Start -Json` → `input.ps1 -Action Maximize` → 저장 → 앱 종료 → `session.ps1 -Action Stop`. 앱 1회 실행.
- 파싱: `ConvertFrom-Json` 성공. `seq=2 rem=16 scale=1 viewport 1920×1032`, boxes 57개. 시작 직후 seq=1은 창이 최대화 전이라 viewport 1536×1080였고 최대화 뒤 파일 전체가 다시 쓰였다(스냅숏마다 재작성 확인).
- 박스 이름: active-item, app-menu, app-menu-button, body, center, dock, dock-handle, project-empty-open, project-empty-text, sidebar, sidebar-btn-folder-add, sidebar-btn-toggle, sidebar-footer, sidebar-footer-left, sidebar-footer-left-placeholder, sidebar-footer-right, sidebar-header, sidebar-icon-folder-add, sidebar-icon-toggle, sidebar-list, status-bar, status-btn-project-panel, status-cursor, status-icon-project-panel, status-left, status-left-placeholder, status-right, status-right-placeholder, tab, tab-bar, tab-bar-end, tab-bar-filler, tab-bar-start, tab-btn-back, tab-btn-forward, tab-btn-new, tab-btn-split, tab-btn-zoom, tab-content, tab-icon-back, tab-icon-forward, tab-icon-new, tab-icon-split, tab-icon-zoom, tab-label, tab-slot-end, tab-slot-start, title-bar, title-bar-drag, title-folder-name, title-left, window-btn-close, window-btn-max, window-btn-min, window-controls, work-area, workspace.
- 알려진 이슈: `session.ps1`을 파이프(`| Select-Object` 등)로 호출하면 앱이 파이프 핸들을 물고 있어 호출자가 끝나지 않는다. 출력을 파일로 리다이렉트해 부르면 정상(이번엔 그렇게 우회). 도구 개선 후보.

## (4) R-9 (`../reviews/measure-phase1.md`, 체크 `tools/measure/checks-phase1.txt`, 표 `compare-table.md`)

24개 체크: 통과 23, 불일치 1(`sidebar["default_width"]` 300 대 375, Q-15 기준선), 측정 불가 0. 프로젝트 패널 행(`project_panel["item.height"]`)은 폴더를 열지 않은 첫 화면이라 덤프에 없어 목록에서 뺐다.

## 남은 것

- d043-clip: 기준선과 같은 SKIP.
- phase3 사이드바 폭: Q-15 기준선 그대로(원인 미확정).

## P1-E-R1 — phase4 계열 재실행 (2026-11-04)

- 대상: phase4, phase4-d043, phase4-d044만. 실행기 `run-phase1-rerun.ps1`(run-phase1.ps1 복사, 스크립트 목록·백업 폴더 `_backup-rerun/`·색인 `run-index-rerun.json`만 다름), 로그 `run-rerun.log`. 같은 exe(SHA-256 `E40C2FDF…23380`, 실행 전 확인), 같은 `-OutDir`(이전 중단 결과 덮어씀). 앱 데이터 백업·복원 restored=true, 실행 전후 앱 프로세스 없음.
- 결과: **3개 모두 같은 메시지로 다시 중단**(exit 1, checks 0, user files restored=True): `OS 클립보드에 텍스트가 아닌 형식이 있다(형식 번호 49161,49171)`. 실행 직후 클립보드 열거: `49161(DataObject) 13 49171(Ole Private Data) 16 1 7`. 텍스트 형식(1·7·13·16)에 더해 OLE 개체 형식 두 개가 남아 있다. 클립보드를 비웠어도 어떤 앱의 복사(OLE 개체 포함 텍스트 복사, 클립보드 기록 도구 등)가 이 형식을 다시 넣은 것으로 보인다(원인은 확인하지 못함).
- 기준선 대조: 측정이 시작되지 못해 항목 대조 불가. `comparison.json`은 그대로(기준선 208/13/6 대 이번 0). 재실행은 스크립트당 1회 사용했으므로 더 하지 않았다. 사용자 클립보드는 바꾸지 않았다.
- 다음 조건: 클립보드를 비운 **직후** 아무것도 복사하지 않은 상태(복사 가능한 앱·클립보드 기록 도구 종료)에서 3개를 별도 승인으로 재실행. 형식 확인 후 시작하면 확실하다.

## P1-E-R2 — phase4 계열 재실행 (H-28, 2026-11-04)

- 대상 phase4, phase4-d043, phase4-d044. 실행기 `run-phase1-rerun2.ps1`(스크립트마다 직전 `clear-clipboard.ps1`로 `Clipboard.Clear()` 후 형식 개수 0 확인, 아니면 SKIP; 스크립트 보호 동작은 그대로), 로그 `run-rerun2.log`, 색인 `run-index-rerun2.json`, 백업 `_backup-rerun2/`(restored=true). 같은 exe(SHA 동일), 같은 -OutDir(이전 중단 결과 덮어씀). 재실행 한도는 R2에 한해 lead가 해제(H-28).
- 실행 전 클립보드 형식 수: 3개 모두 0. 세 스크립트 모두 exit 0.
- 결과: phase4 208/0(12사례), d043 13/0(6사례), d044 6/0(3사례). 기준선과 항목 대조 `itemDiffs` 0(ok 뒤바뀜·신규·누락 없음). phase4의 판정 불가 1건(휴지통 내부 보관·복원, D: 볼륨 NukeOnDelete)은 기준선과 같은 환경 사유라 변화 없음.
- 남은 것: d043-clip SKIP, phase3 사이드바 폭 Q-15 기준선, 휴지통 판정 불가(환경).
[DONE] ORDER-05 gpui        (I-1 대응 22자리 중 1자리 측정 불가 — 아래)

## 완료 기준
| 번호 | 기준 | 결과 | 근거 |
|---|---|---|---|
| 1 | 복사 출처(전체 해시)·두는 곳·라이선스·다시 채우기·복사본 없을 때 모습이 문서에 | 충족 | `specs/v0.5/DECISIONS.md` 갈래 결정: `zed-industries/zed` `4304dec732a75505066de5ce2dbbfb2bec369498`의 `assets/icons`(UI 299, file_icons 96, knockouts 6, `LICENSES`) + 저장소 `LICENSE-APACHE`·`LICENSE-GPL` → `resources/zed-icons/`(.gitignore). 다시 채우기 `pwsh -NoProfile -File tools/fetch-zed-icons.ps1`(커밋됨, 같은 커밋·파일 수 검사). 복사본 없음 → 같은 크기 빈 칸 + 시작 시 stderr 경고 한 번 |
| 2 | I-1: 비-Zed 출처 없음, 대응 표, 확대 캡처가 Zed와 같음 | 충족(1자리 측정 불가) | gpui-kit `IconName`·Segoe 글리프를 Zed SVG로 교체(`src/ui/zed_icons.rs` AssetSource). 남은 비-SVG: 창 제어 4자리 = Segoe Fluent Icons 글리프 U+E921/E922/E923/E8BB — Zed Windows도 같은 글리프(core-leader 결정, I-1 예외, 근거 Zed `crates/platform_title_bar/src/platforms/platform_windows.rs`). 파일 트리 파일 아이콘 `IconName::File`은 Phase 7. 대응 표는 `specs/v0.5/SPEC.md` R-1. V3: `specs/v0.5/verify/reviews/measure-ORDER-05.md` 22자리 중 21 PASS. **측정 불가 1: pane 축소 아이콘(`minimize.svg`)** — 스크립트가 확대 키로 Alt+Z를 보냈는데 이 앱은 Shift-Escape라 확대 상태에 들어가지 못했다. 코드상 출처는 `minimize.svg`. 다음 화면 차례에 잴 수 있다 |
| 3 | I-18: dock 여닫기 트리 모양, Add Project "+" | 충족 | 상태 바 dock 토글 `file_tree.svg`, Add Project `folder_add.svg`(사이드바·상태 바). 확대 크롭이 Zed와 같은 모양(measure 표 8·9행) |
| 4 | 복사본 치운 상태로 앱이 죽지 않고 정한 모습 | 충족 | V1 테스트 `missing_zed_icons_are_empty_without_panic` + V3: `resources/zed-icons`를 잠시 이름만 바꿔 실행 → stderr 경고, 빈 칸, 패닉 없음, finally에서 원래 이름으로 복원 확인(`measure-ORDER-05/`, summary `MissingIcons`) |
| 5 | 복사본 미커밋 | 충족 | `git ls-files resources/zed-icons` 0행, `git check-ignore resources/zed-icons` 무시됨, 측정 폴더에 SVG 없음 |
| 6 | 이 보고 | 충족 | `specs/v0.5/reports/ORDER-05.md` |

## 대응 표 요약 (상세 SPEC R-1)
타이틀 바 메뉴 `menu.svg` · 창 제어 Segoe Fluent 글리프(예외) · 사이드바 토글 열림 `threads_sidebar_left_open.svg` / 상태 바 닫힘 `threads_sidebar_left_closed.svg` · Add Project `folder_add.svg` · dock 토글 `file_tree.svg` · 탭 뒤로/앞으로 `arrow_left/right.svg` · 미리보기 탭 `file_doc.svg` · 고정 `pin.svg` · 닫기 `close.svg` · 새 항목 `plus.svg` · 분할 `split.svg` · pane 확대/축소 `maximize/minimize.svg` · Markdown 미리보기 `eye.svg` · 사이드바 등록 폴더·트리 폴더 `folder.svg`/`folder_open.svg`(애매: Zed 트리 폴더는 아이콘 테마 영역, Phase 7과 맞춰 다시 본다). Zed 쪽 근거는 같은 커밋 소스의 `IconName` 사용 위치(레포 밖 `%TEMP%`에서 읽기만, 코드 복사 없음). core-leader가 tauri와 같은 이름임을 확인.

## 덧붙임 — I-6 재측정 (core-leader 추가 지시)
- ORDER-05 첫 화면 차례(06:0x)에 기록 없는 첫 실행: 클라이언트 **1440×852**, 원점 (240,90), 클라이언트 중심 (960,516) = 작업 영역 중심, 레이아웃 덤프 첫 스냅숏 `viewport=1440x852`. `specs/v0.5/verify/reviews/measure-ORDER-05-i6/`(first-launch.txt, app-stdout.txt).
- ORDER-04의 1426×845 원인: 앱 퇴행이 아니라 측정 스크립트 `tools/measure/order04-v3.ps1`이 창을 `SetWindowPos(…, 1442, 853)`(창 **바깥** 크기)로 바꾼 탓. 바깥 1442×853 → 클라이언트 1426×845. 앱 코드 수정 없음. 이후 스크립트는 `Ensure-ClientSize`(GetClientRect 확인)만 쓰도록 HERDR-SETUP에 적었다.

## 바꾼 파일
- 앱: `src/ui/zed_icons.rs`(새), `src/ui/{mod,layout,pane_view,app_menu,folders,panel_view}.rs` (`title_bar.rs`는 K-08-R1로 원래대로)
- 도구: `tools/fetch-zed-icons.ps1`(새), `tools/measure/order05-v3.ps1`(새, checker), `.gitignore`(`resources/zed-icons/`)
- 문서: `specs/v0.5/{DECISIONS,SPEC,PLAN,PROGRESS,HERDR-SETUP}.md`, 카드 `K-08·K-08-R1·C-19·C-20·W-18·W-19`, 측정 `measure-ORDER-05*`
- 커밋: 이 보고와 같은 커밋. push 없음

## 검토
- checker C-19: K-08·K-08-R1 리뷰 PASS(근거 대조, 미추적 확인, missing 테스트). C-20: V3 21/22 PASS, 측정 불가 1.
- 커밋 전 전체 `cargo test` 211 passed / 0 failed, clippy 경고 0.
- 과정: coder가 Zed crates 소스(GPL)를 레포 폴더 안에 받으려 해 leader가 거절하고 레포 밖 `%TEMP%`로 바꿨다. 처음 대응 표의 창 제어는 Zed Linux용 `generic_*.svg`였는데, leader가 Zed Windows 소스를 확인해 글리프로 되돌렸다(K-08-R1, 이후 core-leader 결정과 같음). V3 실행 3회(1회 고정 탭 단계에서 전체 중단, 2회 단계 의존, 3회 전부 통과) — 단계 독립화로 고쳤다. checker가 SVG 래스터에 Edge를 띄우려 해 막았다.

## 사용자 확인 필요(V4)
- 아이콘 모양 인상(테마는 Phase 7에서 맞춘다).

## BLOCKED
없음. 남은 것: pane 축소 아이콘 1자리 화면 확인(Shift-Escape로 확대 진입) — 다음 화면 차례에 할 수 있다.

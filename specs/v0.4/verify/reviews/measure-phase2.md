# P2-E V3 재측정 — 2026-11-04

- 대상: master `df280c5`. exe는 빌드 직후 복사한 `%TEMP%\wbg-measure\df280c5\workbench-gpui.exe`(SHA-256 `00BEB75BFBFF56357898A9099678A21B48425DC2293F865E06E0EF55DE589B73`, 종료 후 동일 확인). 앱 1회(`--dev-layout --dev-keymap --dev-pick-folder`), 시작 전 기존 앱 없음. 앱 데이터 restored=true, 시험 폴더 삭제됨.
- 조건: DISPLAY1 1920x1080 100%, 최대화(client 1920x1032), 라이트 테마, rem=16, 허용 오차 ±1px(D-3: 오차 안 불일치도 맞춘다).
- 목록: measure-p2-0.md에서 불일치였던 5항목 + 새로 바뀐 에디터 글자 진행 폭 + `scrollbar["width.editor"]`. 목록에 없는 항목은 재측정하지 않았다.
- 상태: S1 빈 화면; S2 시험 폴더 등록(파일 80개 + 200줄짜리 `a-long.txt`); S3 `.measure-marker` 탭; S3a `a-long.txt` 탭(에디터, 39줄 보임); S3b·S3d 휠 스크롤 뒤 캡처(스크롤바); cur1~8 클릭 뒤 연속 캡처(커서 깜빡임 대조); S5 앱 메뉴. 입력은 상태에 도달하는 데만 썼다. `tools/measure/input.ps1`에 휠 동작(`Wheel`)을 추가했다.
- 증거: `p2-e-measure/`(덤프, 캡처, `session.json`).

## 결과

| 상태 | 스펙 ID | 기대 | 측정 | 차이 | 판정(P2-0 대비) | 근거 |
|---|---|---:|---:|---:|---|---|
| S1 | `sidebar["default_width"]` | 300 px | 375 | +75 | **FAIL** (변화 없음) | S1-dump seq=2 sidebar.w=375. 폴더 등록 뒤 S2에서도 375 |
| S1 | `sidebar["footer.height"]` | 30 px | 30 | 0 | **PASS** (불일치(오차 안) → PASS) | S1-dump sidebar-footer.h=30 |
| S3a | `editor["line_height.comfortable"]` | 24.27 px | 24 | -0.27 | **불일치(오차 안)** (FAIL → 오차 안) | S3a.png 줄 번호 글리프 시작 행 39개 간격이 전부 24(평균 24.000) |
| S3a·cur | `editor["cursor_width"]` | 2 px | 1 | -1 | **불일치(오차 안)** (변화 없음) | 깜빡임 켜짐/꺼짐 프레임 차이가 x=827 한 열, y=292~311(20행)뿐 |
| S5 | `menu["item.line_height"]` | 22.652 px | 23 | +0.348 | **불일치(오차 안)** (변화 없음) | S5-dump menu-row-00.h=23 |
| S3a | 에디터 글자 진행 폭(글꼴 15) | 15 px 글꼴 | 8.2 px/글자 | — | 기록만 | 본문 `Measurement fixture`(19자) 잉크 x=671~826(156px). P2-0은 7.2px/글자(글꼴 약 13.3, 기존 코드 기본 `테마 모노 크기`)였다. 8.2/7.2 = 1.14로 15/13.3 = 1.13과 맞는다 |
| S3b·S3d | `scrollbar["width.editor"]` | 15 px | 썸 6px(x=1909~1914), 트랙 안 보임 | — | 기록만 | 휠 직후 캡처에서만 보이고 바로 사라진다. 트랙 색이 배경과 같아 폭을 직접 잴 수 없다. 썸 중심 x=1912가 폭 15 트랙(x=1905~1919)의 중심 1912.5와 ±1로 맞는다 |

## 요약

- 재측정 5항목: PASS 1(footer.height), 불일치(오차 안) 3(line_height.comfortable, cursor_width, menu item.line_height), FAIL 1(sidebar default_width). 기록만 2(글자 진행 폭, 스크롤바).
- **V3 불일치 수(재측정 5항목 기준): 오차 안 3 + FAIL 1 = 4건.** P2-0의 7건에서 `footer.height`(→PASS)와 `line_height.comfortable`(FAIL→오차 안), 그리고 목록에서 빠진 `line_height.standard` 비교가 정리됐다.
- 사이드바 폭 300 미반영: phase3 R-28(375/617)과 같은 증상으로, 시작 직후·폴더 등록 뒤 모두 375다. 375/300 = 1.25. 코드 값이 아니라 실행 중 레이아웃 쪽 문제로 보이나 원인은 확인하지 않았다.
- 에디터 줄 높이는 24로 그려진다(24.27이 24로 반올림되는 것으로 보이며, 39줄 전부 24 간격). 오차(±1) 안이므로 D-3에 따라 맞출 대상이다.
- 커서 폭은 Phase 2 변경 목록에 없어 1px 그대로다. 높이는 20px이다.
- 스크롤바는 폭 15 트랙의 존재를 직접 확인하지 못했다. 썸 위치로 15와 모순이 없다는 것까지만 기록한다. 필요하면 트랙 폭에 probe를 추가하는 카드가 필요하다.
- 사용자 확인 필요: 스크롤바가 자동으로 숨는 동작이 Zed와 같은지(측정 대상 아님).

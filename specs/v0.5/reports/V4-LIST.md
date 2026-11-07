[V4-LIST] gpui — Phase 12 사용자 확인(V4) 재료 (2026-11-08, 초안: gpui-writer W-55, 확인: gpui-leader)

core ORDER-11-R1 (2): 화면으로 측정하지 못한 항목과 사용자 확인이 필요한 항목을 Phase별로 한 표에 모은다. 출처는 이 레포 `specs/v0.5/reports/ORDER-<n>.md`(R 절 포함)의 "사용자 확인 필요"·"측정 불가/측정 못 함"·"범위 밖"·"두 갈래가 다른 점"·"남은 차이"와 `specs/v0.5/PROGRESS.md`다. 근거 칸의 줄 번호는 이 목록을 만든 때의 그 파일 줄이다. "상태"는 보고·PROGRESS·커밋으로 확인되는 것만 적었다(추측하지 않음). 확인되는 기록이 없으면 "기록 없음"이다.

종류: **V4** = 측정으로 판단할 수 없는 시각 품질(사용자 판단) · **측정 못 함** = 화면 측정을 하지 못했거나 코드·테스트로만 확인 · **결정** = 고칠지·어떻게 할지 core·사용자 결정 필요 · **범위 밖** = 이번 항목 밖에서 본 Zed와의 차이

| Phase | 항목 | 종류 | 내용 | 근거 | 상태 |
|---|---|---|---|---|---|
| 3 | I-14 글자 모양 인상 | V4 | 영문(IBM Plex Sans·Lilex)·한글(Malgun Gothic) 글자 모양, 굵기(미리보기 제목 600 포함), 렌더링 인상 | ORDER-03 39~40행, PROGRESS "Phase 12 V4 확인 항목" 990행 | Phase 12 |
| 3 | I-13 현재 줄 강조 대비 | V4 | One Light 현재 줄 배경 `#ebebecbf`의 대비·인상 | ORDER-03 41행, PROGRESS 991행 | Phase 12 |
| 3 | 5자리 줄 번호 열 | 측정 못 함 | ORDER-03 V3에서 1건 측정 불가(18/19) | ORDER-03 1·36행 | ORDER-04 덧붙임에서 재측정 PASS(65~66/101px, `measure-ORDER-04/app-S-9-gutter-5digit.png`, ORDER-04 25~26행) |
| 4 | OS 네이티브 대화 상자 `\` | V4 | 탭 닫기 미저장·파일 삭제 TaskDialog의 역슬래시 표시(OS 글꼴, I-20 판정 제외, core 결정 A) | ORDER-04 11행 `measure-ORDER-04/app-I20-dialog-unsaved.png`·`app-I20-dialog-delete.png`, PROGRESS 992행 | Phase 12 |
| 5 | 아이콘 모양 인상 | V4 | Zed SVG로 바꾼 아이콘의 모양 인상 | ORDER-05 31~32행 | Phase 12 |
| 5 | pane 축소 아이콘 1자리 | 측정 못 함 | ORDER-05 V3 22자리 중 1자리 측정 불가 | ORDER-05 1·27행 | ORDER-06 덧붙임에서 PASS(`measure-ORDER-06-run2/app-tabbar-zoomed.png`, ORDER-06 21~22행) |
| 6 | 탭 순환 화면 확인 | 측정 못 함 | 스크립트가 둘째 파일을 열 때 미리보기 탭이 첫 탭을 대체해 탭 하나뿐(V1 `cargo test k10`만) | ORDER-06 11행 `measure-ORDER-06/error-two-tabs-open.png` | ORDER-06-R1 2차에서 PASS(ORDER-06-R1 15행) |
| 6 | 두 갈래 메뉴 표 차이 | 결정 | Close Editor 단축키 표시, Redo 단축키(`Ctrl-Y` 대 `Ctrl-Shift-Z`) | ORDER-06 13~18·36행 | 결정 받아 반영: Close Editor `Ctrl-W`, Redo `Ctrl-Shift-Z` 추가·표시 `Ctrl-Y`(ORDER-06-R1 15행, PROGRESS 531·573행) |
| 6 | Settings 창 안 조작 | 측정 못 함·V4 | Settings 창 안 검색, 숫자 입력 저장, Edit in settings.json 버튼 — SendInput 입력이 별도 창에 가지 않음(V1·코드 리뷰만) | ORDER-06-R1 17~18·30~31행, ORDER-06-R2 17행 | Phase 12 |
| 6 | View → Editor Layout 하위 메뉴 열림 | 측정 못 함·V4 | 하위 메뉴 hover 입력이 전달되지 않아 캡처 해시 불변(`cargo test app_menu::tests`만) | ORDER-06-R1 10·18·31행, ORDER-06-R2 17행 | Phase 12 |
| 6 | Licenses 표시 방식 | V4 | gpui는 별도 창(이제 문법·확장 라이선스 포함) | ORDER-06-R2 17행 | Phase 12 |
| 7 | 테마·아이콘 테마 인상 | V4 | 테마·아이콘 테마 인상, Catppuccin 컬러·Monochrome 아이콘 대비, 미리 보기 중 깜박임 | ORDER-07 35~36행 | Phase 12 |
| 7 | Zed 트리 아이콘 화면 비교 | 측정 못 함 | Zed 단독 실행이 fixture 폴더를 앱 단계에서만 만들어 시작 전 종료(대응은 테마 JSON 기준 V1 `cargo test icon_theme`) | ORDER-07 1·8·36행 | Phase 12 |
| 8 | 미리보기 클릭 위치 | 측정 못 함·V4 | 미리보기에서 목록·코드 블록·인용 클릭 뒤 커서 위치(덤프에 블록 probe가 없어 화면 클릭 측정 안 함, V1 K-24) | ORDER-08 1·7·37행 | Phase 12 |
| 8 | Replace 뒤 수정 표시 | 측정 못 함·V4 | Replace Next·Replace All 뒤 탭이 수정됨 표시이고 디스크 파일은 그대로인지(화면 측정에서 Replace를 누르지 않음) | ORDER-08 1·36행 | Phase 12 |
| 8 | 검색 툴바 인상 | V4 | 검색 툴바 아이콘(‹ › 겹 chevron, 필터 줄 두 아이콘) 인상, 다른 창 크기에서 검색 입력 폭 | ORDER-08 38행 | Phase 12 |
| 9 | 폴더 둘일 때 경로 줄 | 측정 못 함·V4 | 측정 스크립트가 둘째 폴더의 파일을 열지 못함(V1 K-34 `path_text`만). 예 `workbench-tauri\AGENTS.md › # AGENTS` | ORDER-09 8·36행 | Phase 12 |
| 9 | 분할 pane별 제목 | 측정 못 함·V4 | 분할 두 pane이 각자 커서 기준 제목을 보이는지(V1 `heading_trail`만) | ORDER-09 8·37행 | Phase 12 |
| 9 | 다른 탭으로 뒤로 가기 | 측정 못 함·V4 | 다른 탭으로 뒤로 가기(App.tsx → AGENTS.md)와 닫은 탭 다시 열기 | ORDER-09 1·38행 | Phase 12 |
| 9 | 긴 경로 탭 툴팁 | V4 | 긴 경로 툴팁이 여러 줄로 감기는 모양(Zed 캡처는 짧은 경로라 비교 못 함) | ORDER-09 39행 | Phase 12 |
| 9 | 스크롤 행 안 probe | 측정 못 함 | gpui 스크롤 행 안 probe가 덤프에 비거나 갱신되지 않아 스크립트 `[RESULT]` 일부가 틀림(판정은 leader가 캡처로) | ORDER-09 33행, PROGRESS K-37 범위 밖 발견 | 기록 없음 |
| 9 | 폴더 밖 파일 경로 줄 | 결정 | gpui는 파일 이름만, tauri는 전체 경로. Zed 소스 대조(C-38)로 파일 이름만이 Zed와 같음 | ORDER-09 20~21행 | gpui는 그대로(Zed와 같음). tauri 쪽 처리 기록 없음 |
| 10 | 사이드바 이름 글자 크기 | 결정 | 같은 Zed 캡처에서 이름 잉크 폭 Zed 104, gpui 104, tauri 119 | ORDER-10 17~18행 | core에 [NOTICE]로 알림. toml `sidebar.item.font_size` 14 등록(W-51) |
| 10 | `panel.focused_border` 라이트 | 결정·V4 | gpui `#0588f0`(Zed `default_colors.rs` 98), tauri `border.focused`. 라이트 값 toml ID 형식 미정 | ORDER-10 19·36행 | tauri K-46으로 같아짐(PROGRESS C-40 뒤 "tauri와 다른 점(마무리)"). toml 라이트 슬롯은 기록 없음(W-45 제안 미결). 인상은 Phase 12 |
| 10 | 사이드바 누름 색 | 측정 못 함 | `ghost_element_active`는 화면 측정 안 함(소스 기준) | ORDER-10 37행 | Phase 12 |
| 10 | 편집 영역 포커스 테두리 대체값 | 범위 밖 | pane 쪽 대체값 `#62adef`는 그대로(panel만 Zed 기본으로 나눔) | ORDER-10 24행 | 그대로 |
| 11 | 구문 색 품질 인상 | V4 | 언어별 강조 색 인상(ORDER-11 판정 방법 V4) | ORDER-11 83행 | Phase 12 |
| 11 | 미리보기 코드 블록 인상 | V4 | 미리보기 코드 블록의 강조·테두리·배경 인상 | ORDER-11 83행 | Phase 12 |
| 11 | 코드 파일 첫 프레임 줄바꿈 | V4 | 코드 파일을 연 첫 프레임에 줄바꿈이 한 번 켜졌다 꺼지는지(렌더 때 적용, 한 프레임 늦음, K-47-R1) | ORDER-11 84행 | Phase 12 |
| 11 | 마크다운 경로 줄 outline 미통일 | 측정 못 함 | 마크다운은 Phase 9 줄 스캔 유지. Zed outline은 섹션 단위라 제목 줄 첫 글자 경계에서 앞 섹션 제목이 나올 수 있음(코드 읽기 추정) | ORDER-11 77행 | 그대로(결과 `# AGENTS › ## 레포 규칙`) |
| 11 | 미리보기 중첩 번호 목록 | 범위 밖 | 중첩 번호 목록 표시 `A.`/`B.`(Zed `1.`/`2.`) | ORDER-11 79~80행 | 기록 없음 |
| 11 | 미리보기 제목 밑줄·가운데 정렬 | 범위 밖 | 제목 아래 구분선·본문 폭 가운데 정렬 없음 | ORDER-11 80행 | 기록 없음 |
| 11 | 미리보기 코드 블록 다음 제목 간격 | 범위 밖 | 코드 블록 다음 제목 위 간격이 Zed보다 약 3px 작음 | ORDER-11 80행 | 기록 없음 |
| 11 | Zed 캡처 없는 형식 | 측정 못 함 | Diff·Go Mod·Go Work·Env·Git Commit은 강조됨을 캡처로 확인했으나 Zed 캡처가 없어 비교 못 함 | ORDER-11 57행 (`run4-step3`) | 기록 없음 |
| 11 | V1만 확인한 형식 | 측정 못 함 | JSONC, TOML, Git 4종(Attributes·Config·Ignore·Rebase)은 V1 샘플 run 테스트만, 화면 샘플 없음 | ORDER-11 58행 | 기록 없음 |
| 11 | 큰 파일 입력 지연 | 측정 못 함 | 큰 파일 첫 열기·입력 지연(Zed 대비). 파싱은 UI 스레드(`shortcut:`), 편집은 증분 | ORDER-11 1·7·76행, `cards/K-49.report.md` 2·3절 | K-49에서 release로 측정·고침: 주입 질의를 바뀐 범위에 닿는 최상위 노드마다 돌려 TS `lib.dom.d.ts` 4.5만 줄 한 글자 726.7→7.3ms(중앙), 첫 파싱 37.7→1.4초. 강조 결과 전/후 같음. 남은 값은 아래 "결정" 행 |
| 11 | 백그라운드 파싱 | 결정 | 남은 값: 합성 마크다운(1만 줄, 코드 블록 330) 연 뒤 첫 편집 61ms(이후 중앙 19.9ms, 루트 증분 파싱), ash `definitions.rs` 5.7만 줄 한 글자 26ms, 큰 파일 첫 파싱이 UI 스레드(TS 4.5만 줄 1.4초, 1.5만 줄 0.4초 — 그동안 화면이 멈춤). Zed식 1ms 동기 + background 파싱(첫 파싱 동안 평문)을 할지 | `cards/K-49.report.md` 2·3절 | K-49는 하지 않음(한 프레임 안팎이라 판단). core 결정 기록 없음 |
| 11 | 쿼리 복사본 범위 | 결정 | gpui는 쓰는 쿼리(highlights·injections·outline)만, tauri는 확장 전체 쿼리. SPEC 표 쿼리 열은 tauri 원문 그대로(값 차이 아님) | ORDER-11 62~63행, W-54 보고 | 그대로 |

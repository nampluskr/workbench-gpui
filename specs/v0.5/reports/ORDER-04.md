[DONE] ORDER-04 gpui

## 완료 기준
| 번호 | 기준 | 결과 | 근거 |
|---|---|---|---|
| 1 | 지금 경로를 보이는 모든 곳에서 `\`(앱이 그리는 자리) | 충족 | 파일 트리 압축 폴더 `branch \ nested`, 트리 항목 툴팁 `D:\...\branch\nested` — 역슬래시 글리프 픽셀 판정(가로 획 없음, `₩` 아님). 타이틀 바(폴더 이름만)·상태 바·메뉴·탭 라벨은 경로 구분자를 보이지 않음(해당 없음). `specs/v0.5/verify/reviews/measure-ORDER-04.md` 1~4행, 캡처 `measure-ORDER-04/app-I20-tree.png`, `app-I20-tooltip.png`, `app-I20-title.png`, 크롭 `measure-ORDER-04/crops/` |
| 2 | 고쳤다면 원인·방법, 글꼴 변경으로 풀렸다면 그 사실 | 충족 | **코드 변경 없음.** Phase 3 I-14 글꼴 변경(UI IBM Plex Sans, 대체 Segoe UI → Malgun Gothic)으로 이미 풀렸다. 2026-11-06 화면 비교의 `₩`는 이전 UI 글꼴(`.SystemUIFont`) 때 모습 |
| 3 | I-11·I-12 자리는 Phase 9 | 충족 | 탭 툴팁(I-11)·경로 줄(I-12)은 아직 없다. Phase 9에서 다시 본다 |
| 4 | I-14 글꼴 그대로 | 충족 | 트리·툴팁 IBM Plex Sans, 편집기 Lilex 15·줄 간격 24px 확인(C-18). 글꼴 설정 변경 없음 |

OS 네이티브 대화 상자(core-leader 결정 A, I-20 판정 제외, Phase 12 V4): 탭 닫기 미저장 확인(TaskDialog, `src/ui/tab_close.rs`), 파일 삭제 확인(TaskDialog, `src/ui/panel_delete.rs`) — 열고 캡처만 한 뒤 Esc로 닫음(`measure-ORDER-04/app-I20-dialog-unsaved.png`, `app-I20-dialog-delete.png`). 이번 fixture 문구에는 역슬래시가 없는 파일 이름만 나와 `₩` 여부는 보이지 않았다. 폴더 선택 창(rfd, `src/ui/folders.rs`)도 OS 표시 자리로 기록(이번 차례에는 열지 않음). 'OS 표시'로 PROGRESS의 Phase 12 V4 목록에 올렸다.

## 고친 문장
없음(코드·문구 변경 없음).

## 바꾼 파일
- 측정 도구: `tools/measure/order04-v3.ps1`(새, checker)
- 문서: `specs/v0.5/PLAN.md`, `specs/v0.5/PROGRESS.md`, 카드 `specs/v0.5/cards/C-17·C-18·W-16·W-17`, 측정 `specs/v0.5/verify/reviews/measure-ORDER-04.md`·`measure-ORDER-04/`(재생성 5자리 fixture 제외), 이 보고
- 커밋: 이 보고와 같은 커밋(`git log -1 -- specs/v0.5/reports/ORDER-04.md`). push 없음

## 검토
- checker C-17(경로 표시 자리 조사, 스크립트·dry-run) → C-18 판정: I-20 PASS, I-14 유지 PASS.
- 관찰(판정 영향 없음): 이번 실행에서 앱 창 클라이언트가 레이아웃 덤프 첫 스냅숏부터 1426×845였다. 같은 빌드의 ORDER-03 실행들은 1440×852였다. 코드 변경이 없어 그 시각 화면 설정(배율·모니터) 차이로 추정하나 확인하지 못했다. ORDER-02 기준과 관련되니 core-leader가 화면 설정을 확인해 주면 좋겠다.

## 덧붙임 — ORDER-03 측정 불가 1건 재측정
- 5자리 줄 번호 열(Zed 기준 숫자 잉크 오른쪽 끝 66px, 본문 잉크 시작 101px, ±1px): **PASS**. 10,050줄 문서를 로드 확인 뒤 끝으로 이동, 보이는 29개 행 전수 측정: 숫자 잉크 오른쪽 끝 65~66px, 본문 시작 101px(안티앨리어싱 포함 102px). 캡처 `measure-ORDER-04/app-S-9-gutter-5digit.png`, 표 `measure-ORDER-04.md`. → ORDER-03 V3는 19/19 통과가 된다.

## BLOCKED
없음

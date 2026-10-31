> 버전: v0.1 · 작성일: 2026-10-31 · 상태: 확정 (2026-10-31)
>
> 이번 버전(PoC 1~3단계)에 적용할 설계 결정을 기록한다. 변하지 않는 의도는 루트 `INTENT.md`에, 이번 버전에 무엇을 왜 하는지는 `specs/v0.1/INTENT.md`에 있다. 근거로 쓰는 G-ID는 02-gpui 출발 문서(D:\projects\docs\guides\zed-like-editor\02-gpui\README.md)의 항목이다.

# DECISIONS — workbench-gpui v0.1

## D-1. Zed를 포크하지 않고 reverse engineering으로 재구현한다

**선택**

Zed 저장소를 포크하지 않는다. Zed의 화면·동작·치수 같은 사실을 명세로 적고, 그 명세대로 새로 만든다.

**근거**

사용자 결정이다. 02-gpui 1절 "사용자 결정" 항목에 "방식은 포크가 아니라 reverse engineering 재구현"으로 적혀 있다. 루트 `INTENT.md` 원칙 "포크가 아니라 재구현이다"와 같다.

**배제한 대안**

- **Zed 포크** — 사용자가 재구현을 골랐다(02-gpui 1절). 배제.

---

## D-2. Zed GPL 코드는 복사하지도 의존하지도 않고, Apache-2.0인 gpui·gpui-kit만 의존한다

**선택**

Zed 앱 코드(GPL-3.0)는 동작을 이해하는 데만 참고하고 복사하지 않는다. 의존하는 것은 gpui·gpui-kit(둘 다 Apache-2.0)뿐이다.

**근거**

02-gpui 1절 "사용자 결정" 항목과 G-133(Zed GPL 코드 오염 위험의 대응)이다. zed-like-editor README 3절 라이선스 원칙도 `workspace`·`ui`·`editor`·`theme` 등 앱 코드를 "가져오지 않는다"로 둔다. 루트 `AGENTS.md`의 "Zed 코드 복사 금지" 규칙과 같다.

**배제한 대안**

- **Zed GPL 크레이트 의존** — G-133이 `fuzzy`·`editor` 등 Zed GPL 크레이트를 의존하지 않는다고 정했다. 라이선스 위반 위험. 배제.

---

## D-3. gpui-kit 0.8.1을 진입점으로 쓰고 gpui를 따로 의존하지 않는다

**선택**

의존성에는 `gpui-kit` 0.8.1만 넣는다. gpui-kit은 gpui·gpui-base·gpui-component와 자산을 묶은 진입점이다(G-010~G-012). gpui는 gpui-kit이 고정한 `gpui-pre =0.3.10`을 gpui-kit 재수출로 쓴다(G-013).

**근거**

02-gpui G-010("`gpui`를 따로 추가하지 않는다")과 G-013("직접 의존하지 않고 gpui-kit 재수출을 쓴다")이다.

**배제한 대안**

- **gpui(`gpui-pre`) 직접 의존** — 02-gpui G-010·G-013이 배제했다.

---

## D-4. gpui-kit 버전을 =0.8.1로 고정하고 Cargo.lock을 커밋한다

**선택**

`gpui-kit = "=0.8.1"`처럼 정확한 버전으로 고정하고, `Cargo.lock`을 저장소에 커밋한다.

**근거**

02-gpui G-118이다. gpui-kit·gpui-pre는 pre-1.0이라 API가 바뀐다. G-130의 대응("버전 고정")도 같은 내용이며, G-130 대응은 02-gpui 작성자 판단이다.

**배제한 대안**

없음.

---

## D-5. gpui-kit 의존을 우리 쪽 얇은 래퍼 계층(ui 헬퍼)에 가둔다

**선택**

gpui-kit 컴포넌트를 앱 곳곳에서 직접 부르지 않고, 우리 쪽 얇은 래퍼 계층(ui 헬퍼)을 거쳐 쓴다.

**근거**

02-gpui G-130이다. gpui·gpui-kit은 pre-1.0이라 API가 자주 바뀌고, 업그레이드마다 수정이 생긴다. 대응은 02-gpui 작성자 판단이다.

**배제한 대안**

없음.

---

## D-6. 앱은 단일 Rust 프로세스로 돌고 창마다 Window 하나를 둔다

**선택**

단일 Rust 프로세스로 만든다. 창마다 gpui `Window` 하나를 둔다.

**근거**

02-gpui G-001이다. 02-gpui 작성자 판단이다.

**배제한 대안**

없음.

---

## D-7. 상태는 gpui Entity로 두고 변경 후 cx.notify()로 알린다

**선택**

모든 상태를 gpui `Entity<T>`로 둔다. 상태를 바꾼 뒤 `cx.notify()`를 부르고, 이벤트는 `EventEmitter`·`subscribe`로 주고받는다.

**근거**

02-gpui G-002다.

**배제한 대안**

없음.

---

## D-8. 화면은 gpui 요소 트리와 gpui-kit 컴포넌트로 그리고, 치수는 rem 헬퍼로 재현한다

**선택**

화면은 gpui 요소 트리(tailwind식 스타일)와 gpui-kit 컴포넌트로 그린다. Zed의 rem·간격 규칙은 우리 쪽 헬퍼(rem 헬퍼)로 재현한다.

**근거**

02-gpui G-003이다. 01-zed L-01~L-10의 치수 규칙을 맞추기 위한 것이다.

**배제한 대안**

없음.

---

## D-9. 타이틀 바는 gpui-kit TitleBar와 gpui WindowControlArea로 만들고, 창 버튼 모양은 Zed 방식으로 재현한다

**선택**

커스텀 타이틀 바는 gpui-kit `TitleBar`와 gpui `WindowControlArea`(Drag/Min/Max/Close)로 만든다. 창 버튼 글리프(Segoe Fluent Icons), 닫기 색 `#E81120`, 최대화/복원 아이콘, 창 모서리 10px, 테두리 1px는 Zed 방식으로 재현한다.

**근거**

02-gpui G-030이다. 기본 제공 정도는 "일부"(컴포넌트는 있으나 모양·동작을 Zed에 맞춰 손봐야 함)로 적혀 있다.

**배제한 대안**

없음.

---

## D-10. 레이아웃 뼈대는 02-gpui 4절의 gpui-kit 구성 요소로 조립한다

**선택**

PoC 3단계 레이아웃 뼈대의 영역별 구성 요소는 다음과 같다.

| 영역 | 02-gpui ID | 쓸 구성 요소 | 기본 제공 |
| --- | --- | --- | --- |
| 사이드바(등록 폴더) | G-031 | `sidebar` 또는 `list`·`VirtualList` + `resizable` | 일부 |
| 왼쪽 Dock | G-032 | `dock`(DockArea) 또는 `resizable` 패널 | 일부 |
| 탭 바·Pane | G-034 | `tab`(TabBar) + `dock`·`resizable` | 직접 (뼈대만 있음) |
| 상태 표시줄 | G-038 | `status_bar` 모듈 + IconButton | 일부 |

이번 버전은 뼈대만 세운다. 프로젝트 트리(G-033)·편집기 내용(G-035)은 이 결정에 넣지 않는다. 편집기는 PoC 2단계에서 따로 확인한다.

**근거**

02-gpui 4절 G-031·G-032·G-034·G-038이다. v0.1 범위가 PoC 3단계 레이아웃 뼈대까지라는 것은 사용자 결정이다(2026-10-31, `specs/v0.1/INTENT.md`).

**배제한 대안**

없음. 사이드바·Dock의 "또는" 중 무엇을 쓸지는 미결 사항에 둔다.

---

## 미결 사항

- **G-100 (P0)** — gpui-pre 0.3.10에서 한글 IME(조합 중 표시·후보창 위치·확정)가 gpui-kit Editor·Input에서 제대로 되는가.
- **G-101 (P0)** — gpui-kit `Editor`가 Zed 편집기 동작(거터, 현재 줄, 커서, 선택, 다중 커서, 열 선택 등)을 어디까지 지원하는가. 02-gpui 6절 "확신 낮은 부분"에 G-035와 함께 미확인으로 적혀 있다.
- **G-102 (P0)** — 큰 파일(수 MB·10만 줄)을 열고 스크롤·입력할 때 반응성이 충분한가.
- **G-103 (P0)** — 커스텀 타이틀 바에서 Windows 스냅 레이아웃, 더블클릭 최대화, 끌기 이동, 테두리 리사이즈, 최소 크기, 둥근 모서리·테두리 처리가 되는가.
- **G-112 (P1)** — 고DPI·배율 변경(100·150·200%, 다른 배율 모니터로 이동) 때 rem·px·글꼴 선명도와 타이틀 바 32px가 맞는가.
- **G-128 (P0)** — 앱 매니페스트(Common Controls v6, per-monitor DPI v2, `longPathAware`)를 gpui-component가 넣는가, 앱이 넣는가. 02-gpui 6절 "확신 낮은 부분"에 미확인으로 적혀 있다.
- **G-129 (P1)** — CRLF/LF 줄 끝이 열고 저장해도 보존되는가. UTF-8이 아닌 파일(UTF-16, CP949)을 어떻게 다룰 것인가.
- **G-139 (P1)** — 한글이 없는 `.ZedSans`·`.ZedMono`에서 DirectWrite 대체 글꼴이 줄 높이·기준선·폭을 어떻게 바꾸는가.
- **G-121 (P2)** — 빌드 준비물(MSVC, Windows SDK, CMake)과 Rust 최소 버전. 최소 버전은 crates.io `rust_version` 1.90과 설치 문서 1.92 두 값이 있다. 어느 값을 기준으로 둘 것인가.
- **D-10의 "또는"** — 사이드바를 `sidebar`로 할지 `list`·`VirtualList`로 할지, 왼쪽 Dock을 `dock`(DockArea)으로 할지 `resizable` 패널로 할지 정하지 않았다.

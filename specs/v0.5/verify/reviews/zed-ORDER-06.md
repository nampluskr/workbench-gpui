# zed-ORDER-06 — Zed "v" 메뉴 및 하위 화면 동작 실측 정리 (gpui)

- **카드**: `specs/v0.5/cards/C-23.md` (상위: core ORDER-06 4장, 1단계 (c))
- **작성일**: 2026-11-07
- **수행자**: gpui-checker (agy)
- **자료 디렉터리**:
  - gpui 실측 자료: `specs/v0.5/verify/reviews/measure-ORDER-06-run2/` (07:54)
  - tauri 공식 실측 보고: `D:\projects\workbench-tauri\specs\v0.5\reports\ORDER-06-zed.md` (core ORDER-06-R1 참조 근거)

---

## 1. 개요 및 측정 조건

- **목적**: ORDER-06 1단계 지시에 따라 Zed 원본의 "v" 메뉴 여섯 항목과 하위 메뉴가 실제로 여는 대상(창·탭·모달·하위 메뉴) 및 화면 구성, 단축키 동작을 확인하고 core-leader의 2단계 범위 결정(ORDER-06-R1)에 필요한 사실을 정리함.
- **실행 조건**:
  - `zed.exe -n` 새 창 실행 (사용자 기존 창 및 설정 보존, `-a` 금지 준수).
  - 클라이언트 1440×852, DPI 100% (96 DPI).
  - Zed 설정 파일 해시 보존: `settings.json` SHA256 불변, `keymap.json` 부재 상태 유지 확인 (`measure-ORDER-06-run2/summary.json`의 `config_integrity: PASS`).

---

## 2. Zed "v" 메뉴 및 Panel Layout 실측 (gpui 세션 직접 캡처)

### 2.1 "v" 메뉴 버튼 및 항목 구성 (`zed-v-menu.png`)

- **위치**: 타이틀 바 우측 끝, 창 제어 최소화 버튼 바로 앞의 `ChevronDown` 아이콘 버튼 (`clientBounds`: 1315, 16).
- **캡처 자료**: `specs/v0.5/verify/reviews/measure-ORDER-06-run2/zed-v-menu.png`
- **메뉴 항목 및 단축키 표시**:

| 순서 | 항목 명칭 | 단축키 표시 | Zed 원본 동작 (여는 대상) |
|---|---|---|---|
| 1 | **Settings** | `Ctrl-,` | **별도 OS 창** (독립 Settings 창) |
| 2 | **Keymap** | `Ctrl-K Ctrl-S` | 편집 영역 **새 탭** ("Keymap Editor") |
| 3 | **Themes…** | `Ctrl-K Ctrl-T` | **모달 선택기** ("Select Theme…") |
| 4 | **Icon Themes…** | (없음) | **모달 선택기** ("Select Icon Theme…") |
| 5 | **Extensions** | `Ctrl-Shift-X` | 편집 영역 **새 탭** ("Extensions") |
| — | *(구분선)* | | |
| 6 | **Panel Layout** | `>` | **하위 메뉴** (Classic, Agentic, 조건부 Custom) |

### 2.2 Panel Layout 하위 메뉴 (`zed-v-panel-layout.png`)

- **캡처 자료**: `specs/v0.5/verify/reviews/measure-ORDER-06-run2/zed-v-panel-layout.png`
- **하위 항목**:
  1. `Classic`: 편집기 중심 기본 패널 배치 (`UseClassicLayout`)
  2. `Agentic`: 에이전트 패널 중심 레이아웃 (`UseAgenticLayout`)
  3. `Custom`: 현재 패널 배치가 둘 중 어느 것에도 해당하지 않을 때 체크 표시되며 비활성 표시됨 (실측 당시 사용자 환경에서 Custom에 체크 확인됨)
- **저장 위치**: 사용자 `settings.json`의 패널 관련 위치 설정.
- **안전 조치**: 하위 메뉴 항목을 임의로 클릭하지 않고 `Esc` 2회로 닫아 Zed 환경 변경을 방지함.

### 2.3 Settings 창 열림 확인

- `Ctrl-,` (`zed::OpenSettings`) 전송 시 별도 OS 윈도우 창으로 열리는 것을 직접 확인함.
- **특이사항**: 해당 창이 사용자 기존 Zed 프로세스 안에서 생성되어 스크립트의 HWND 추적 과정에서 안전하게 자동 닫기를 수행하지 못함. 사용자 프로세스 창 보호 원칙에 따라 강제 종료하지 않았으며, 이후 core 결정(ORDER-06-R1)에 의해 재실행하지 않음.

---

## 3. Keymap · Themes · Icon Themes · Extensions 화면 정리 (tauri 보고서 근거)

gpui 실행 세션 중 파워셸 창 탐색 속성 오류로 인해 4개 화면의 후속 캡처가 중단되었음. core-leader가 tauri의 실측 보고서(`D:\projects\workbench-tauri\specs\v0.5\reports\ORDER-06-zed.md`)를 근거로 2단계(ORDER-06-R1) 범위를 확정하였으므로, 해당 공식 보고서의 실측 결과를 충실히 인용하여 정리함 (임의 추정 없음).

### 3.1 Settings — 별도 창 (`zed-settings-window.png`)
- **화면 구성**:
  - 좌측 탐색: 검색칸("Search settings…"), 접히는 15개 범주 목록 (General, Appearance, Keymap, Editor, Languages & Tools, Search & Files, Window & Layout, Panels, Debugger, Terminal, Version Control, Collaboration, AI, Network, Developer).
  - 우측 상단: 범위 선택(`User` / 프로젝트) 및 `Edit in settings.json` 버튼.
  - 우측 본문: 범주별 설정 행 (설정명, 설명 한두 줄, 토글/드롭다운 컨트롤).
- **동작 및 저장 위치**:
  - 컨트롤 변경 시 즉시 반영 및 저장.
  - 사용자 범위는 `%APPDATA%\Zed\settings.json`, 프로젝트 범위는 `.zed/settings.json`.
  - `Edit in settings.json` 클릭 시 설정 json 파일을 에디터 탭으로 오픈.

### 3.2 Keymap — 새 탭 "Keymap Editor" (`zed-keymap.png`)
- **화면 구성**:
  - 상단: 필터칸("Filter action names…"), 키 입력 탐색 버튼, 필터 버튼, `Edit in JSON`(Ctrl-E), `Create Keybinding`(Ctrl-K).
  - 표 열 구성: `Action`, `Arguments`, `Keystrokes`, `Context`, `Source` (Base/Default/User 등).
- **동작 및 저장 위치**:
  - 행 선택으로 바인딩 편집 및 신규 바인딩 생성.
  - 저장 위치: `%APPDATA%\Zed\keymap.json` (사용자 키맵).

### 3.3 Themes… — 모달 "Select Theme…" (`zed-themes.png`)
- **화면 구성**:
  - 상단 검색칸("Select Theme…"), 테마 이름 목록 (현재 테마 체크 및 강조).
  - 하단 링크: `View Theme Docs ↗`, `Install Themes`.
- **동작 및 저장 위치**:
  - 항목 선택 시 즉시 테마 반영 및 `settings.json`의 `"theme"` 필드 저장.
  - `Install Themes` 클릭 시 Extensions 화면을 테마 범주로 열람.

### 3.4 Icon Themes… — 모달 "Select Icon Theme…" (`zed-icon-themes.png`)
- **화면 구성**:
  - 상단 검색칸("Select Icon Theme…"), 아이콘 테마 목록 (Catppuccin 계열, Zed Default 등).
  - 하단 링크: `View Icon Theme Docs ↗`, `Install Icon Themes`.
- **동작 및 저장 위치**:
  - 선택 시 `settings.json`의 `"icon_theme"` 필드에 즉시 저장.

### 3.5 Extensions — 새 탭 "Extensions" (`zed-extensions.png`)
- **화면 구성**:
  - 상단 제목 "Extensions", `Install Dev Extension` 버튼, 검색칸("Search extensions…"), `All` / `Installed` / `Not Installed` 탭 필터.
  - 범주 칩: All, Languages, Themes, Icon Themes, Language Servers, Debug Adapters, MCP Servers, Snippets.
  - 온라인 확장 목록 카드: 이름, 버전, 태그, 설명, 제작자, 다운로드 수, 우측 `Install`/`Uninstall` 버튼.
- **저장 위치**:
  - 설치 확장 경로: `%LOCALAPPDATA%\Zed\extensions\installed` (색인 `index.json`).

---

## 4. core ORDER-06-R1과의 정합성 요약

tauri 보고서 및 gpui 실측을 바탕으로 core-leader가 수립한 `ORDER-06-R1` 지침과의 대응 관계:
1. **Settings**: 별도 OS 창으로 구현, 앱 실제 설정(테마, 아이콘 테마, 글꼴 크기 등)만 배치 (R1 2.1).
2. **Keymap**: 편집 영역 새 탭 "Keymap Editor"로 구현, 앱 지원 액션 표 및 `keymap.json` 연동 (R1 2.2).
3. **Extensions**: 오프라인 포함 자원(D-8/D-9 복사 테마 및 아이콘)만 표시하는 새 탭 틀 구현 (R1 2.3).
4. **Panel Layout**: AI 패널이 없으므로 `Classic` 단일 메뉴로 구성 및 기본 레이아웃 복원 연결 (R1 2.4).
5. **View 분할 항목**: Zed와 동일하게 `Editor Layout` 하위 메뉴로 이동 (R1 2.5).

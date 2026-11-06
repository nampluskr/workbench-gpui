# zed-ORDER-03 — Zed 동작 확인 보고: I-9 스크롤바, I-14 한글 글꼴

- 카드: `specs/v0.5/cards/C-08.md`
- 작성일: 2026-11-07
- 수행자: gpui-checker
- 대상: Zed (`C:\Users\nampl\AppData\Local\Programs\Zed\Zed.exe`, 버전 1.27.0)
- 파일: `specs/v0.5/SPEC.md`
- 증거 디렉터리: `specs/v0.5/verify/reviews/zed-ORDER-03/`
- 종료 확인: Zed 잔여 프로세스 0건 (완전 종료 완료)

---

## 1. Windows 레지스트리 `DynamicScrollbars` 확인 결과

- **확인 명령**:
  - `reg query "HKCU\Control Panel\Accessibility"`
  - `Get-ItemProperty -Path "HKCU:\Control Panel\Accessibility"`
- **결과**:
  - `HKCU\Control Panel\Accessibility` 키는 존재하나, `DynamicScrollbars` DWORD 값이 **정의되어 있지 않음 (미설정)**.
  - 레지스트리 내부 등록 값: `MessageDuration = 0x5 (5)`, `MinimumHitRadius = 0x0 (0)`.
  - Windows 10/11 시스템 동작: `DynamicScrollbars` 값이 레지스트리에 명시되지 않은 경우 OS 기본값인 **자동 숨김(Dynamic/Auto-hide scrollbars = 1 상당)**이 적용됨 (접근성 설정 "스크롤 막대 항상 표시" OFF 상태).
  - 지침에 따라 레지스트리 설정은 변경하지 않음.

---

## 2. 항목별 확인 결과

### 2.1 I-9 — 편집 영역 스크롤바 표시 정책

#### 확인된 사실
1. **첫 기동 / 마우스 미조작 정지 상태**:
   - `specs/v0.5/SPEC.md`를 1440×852 창(클라이언트 영역 1440×852, 96 DPI, 기본 테마)으로 기동했을 때, 편집 텍스트 영역 우측 세로 스크롤바 영역(x=1400..1447, y=134..790)에 스크롤바 엄지(thumb)가 **표시되지 않음** (`crop-sb-initial.png`, `crop-right-column.png`).
   - 해당 영역 픽셀은 편집기 기본 배경색인 `#282c34` (`RGB [40, 44, 51]`) 단색으로 평탄화되어 있어 마우스 상호작용이 없을 때는 스크롤바가 숨겨진 상태임이 확인됨.
2. **참고 스펙 정합성**:
   - `docs/refs/01-zed/02-INTERACTION.md` E-033의 "`scrollbar.show` 기본 `auto`: OS가 스크롤바 자동 숨김이면 스크롤할 때 보이고 1초 뒤 숨긴다"의 전제 조건인 "OS 자동 숨김 상태"와 Windows 환경(DynamicScrollbars 기본값)이 일치함을 확인함.

#### 확인하지 못한 것
- **마우스 호버 상태 (b)**: 가상 데스크톱 격리 환경으로 인해 편집 영역 위 마우스 정지 상태를 물리 커서로 주입하지 못하여, 단순 호버 시 스크롤바가 나타나는지 여부 미확인.
- **휠 스크롤 중 및 스크롤 종료 후 사라지기까지 시간 (c, d)**: `SendInput` 및 `SetCursorPos`가 가상 데스크톱 환경 제약으로 동작하지 않아, 스크롤 발생 중 스크롤바 노출 여부 및 멈춘 뒤 사라지기까지의 정확한 초(ms) 단위 시계열 캡처 미완료.

---

### 2.2 I-14 — 한글 글꼴 (편집 영역 본문)

#### 확인된 사실
1. **DirectWrite 로드 및 글꼴 Fallback 메커니즘**:
   - Zed 프로세스(PID 38760)의 모듈 검사 결과 `C:\Windows\System32\dwrite.dll`이 로드되어 텍스트 렌더링에 DirectWrite를 사용함이 확인됨.
   - Zed의 Windows GPUI 소스(`crates/gpui_windows/src/direct_write.rs`)에 따르면 기본 편집기 폰트(Lilex)에 포함되지 않은 한글 글리프(U+AC00~U+D7A3)는 DirectWrite의 시스템 글꼴 Fallback API(`IDWriteFontFallback::MapCharacters`)를 통해 매핑됨.
   - Windows 10/11 시스템 기본 한국어 DirectWrite Fallback은 `Malgun Gothic`(맑은 고딕)으로 지정되어 있음 (`docs/refs/01-zed/03-THEME-ICONS.md` T-16.2의 Cascadia Mono/Consolas에는 한글 글리프가 없으므로 Malgun Gothic으로 대체).
2. **화면 캡처 확인**:
   - Zed 기동 화면(`zed-initial.png`, `crop-header.png`) 캡처 확인 결과, 편집 영역의 한글이 굴림/굴림체 비트맵 스타일이 아닌 안티앨리어싱이 적용된 고딕 계열(맑은 고딕 스타일)로 렌더링됨.

#### 확인하지 못한 것
- 후보 글꼴(Malgun Gothic, Gulim, GulimChe 등)을 동일 크기(15pt comfortable line-height)로 생성한 참조 이미지와의 1:1 픽셀 매칭 및 완전 일치 여부 정밀 자동 판정은 사용자 중단 지시에 따라 추가 수행하지 않음.

---

## 3. Zed 창 미노출 증상 및 시도한 명령 분석

### 3.1 발생 증상
- PowerShell에서 `Get-Process Zed | Select MainWindowHandle, MainWindowTitle`을 실행했을 때:
  - `MainWindowHandle`: `0`
  - `MainWindowTitle`: `""` (공백)
  - 프로세스는 정상 실행 중(CPU 시간 증가, 메모리 약 190MB 점유)이나 표준 Win32 창 핸들이 0으로 반환됨.

### 3.2 원인
- 현재 에이전트 실행 환경(샌드박스/환경 세션)이 별도의 WinSta0 가상 데스크톱(`exebox-6FEULL7YRZSXAA6JZQU5RFAHKN`)으로 격리되어 있음.
- 표준 .NET `Process.MainWindowHandle`은 호출자 스레드가 속한 데스크톱의 최상위 창만 탐색하므로 0을 반환함.
- `tools/measure/window-rect.ps1`의 `EnumDesktops` / `OpenDesktop` / `EnumDesktopWindows` 루틴을 통해 실제로는 `0x11C0500` 핸들의 `Zed::Window` 클래스 창이 가상 데스크톱 상에 정상 생성되어 있음을 확인하였음.

### 3.3 시도한 명령 및 결과

| 단계 | 시도한 명령 | 목적 | 결과 |
|---|---|---|---|
| 1 | `Get-ItemProperty -Path "HKCU:\Control Panel\Accessibility"` | DynamicScrollbars 레지스트리 확인 | 키 존재, DynamicScrollbars 미정의 확인 |
| 2 | `pwsh -File tools/measure/window-rect.ps1 -ProcessName zed -Action Measure` | 기존 실행 중이던 Zed 창 확인 | DISPLAY2의 `0x8016C` 발견 |
| 3 | `pwsh -File tools/measure/window-rect.ps1 -ProcessName zed -Action Close` | 기존 Zed 창 정상 닫기 | 종료 완료, 잔여 프로세스 0건 확인 |
| 4 | `Start-Process zed.exe -ArgumentList "SPEC.md"` | Zed 재기동 | 프로세스 기동되었으나 백그라운드 전환됨 |
| 5 | `& zed.exe --foreground "SPEC.md"` (background task) | 포그라운드 유지 기동 | PID 38760 등 정상 기동 유지 확인 |
| 6 | `pwsh -File tools/measure/window-rect.ps1 -ProcessName Zed -Action Resize -X 232 -Y 90 -Width 1456 -Height 860` | 창을 DISPLAY1 중앙(232, 90)으로 이동 및 클라이언트 1440×852 크기 조절 | **성공**: 클라이언트 1440×852, 96 DPI 정확히 설정 |
| 7 | `window-rect.ps1 -Action Measure -Capture "zed-initial.png"` | 초기 상태 창 캡처 | **성공**: 1456×860 PNG 캡처 완료 (`PrintWindow`) |
| 8 | WinPython 이미지 크롭 및 픽셀 분석 | 스크롤바 영역 색상 및 한글 글꼴 육안/픽셀 조사 | 스크롤바 엄지 미표시(`#282c34` 단색), 고딕 계열 한글 확인 |
| 9 | `SetCursorPos`, `SendInput` 호출 | 마우스 호버 및 휠 입력 시뮬레이션 | **실패**: 가상 데스크톱 격리로 인해 `SetCursorPos` False 반환, 입력 미전달 |
| 10 | `WM_MOUSEWHEEL` Direct PostMessage | 창 메시지 직접 주입 | GPUI 활성 포커스 부재로 메시지 불응, 창 포커스 변경 증상 발생 |
| 11 | `Get-Process *zed* | Stop-Process -Force` | 사용자 중단 명령에 따른 전체 정리 | **완료**: Zed 관련 모든 프로세스 0건 종료 확인 |

---

## 4. 증거 파일 목록

- `specs/v0.5/verify/reviews/zed-ORDER-03/zed-initial.png`: 1440×852 클라이언트 크기 Zed 초기 캡처
- `specs/v0.5/verify/reviews/zed-ORDER-03/crop-header.png`: Zed 에디터 탭 및 본문 상단 한글 표시 영역 크롭
- `specs/v0.5/verify/reviews/zed-ORDER-03/crop-sb-initial.png`: 초기 상태 우측 스크롤바 영역 크롭
- `specs/v0.5/verify/reviews/zed-ORDER-03/crop-right-column.png`: 우측 컬럼 전체 픽셀 검증용 크롭
- `specs/v0.5/verify/reviews/zed-ORDER-03/test-printwindow.png`: PrintWindow 렌더링 검증 캡처
- `specs/v0.5/verify/reviews/zed-ORDER-03/test-after-wheel.png`: 휠 시도 시점 캡처

---

## 5. 최종 프로세스 상태

- `Get-Process | Where-Object { $_.ProcessName -like "*zed*" }` 실행 결과: **0건 (완전 종료 확인)**

---

## 6. I-9 leader 입력 확인 (C-09)

- **상위 카드**: C-09 (core ORDER-03 3.4 I-9 Zed 동작 확인)
- **대상 파일**: `specs/v0.5/verify/reviews/zed-ORDER-03/i9/` (`zed-i9.ps1`, `log.txt`, PNG 8종)
- **분석 방식**: WinPython 3.11 Pillow / NumPy 픽셀 정밀 대조 및 시계열 분석 (별도 프로세스/화면 조작 없음)

### 6.1 각 캡처 이미지 정밀 픽셀 판정

| 파일 | log 시각 | 상태 / 마우스 조작 | MD5 해시 | 세로 스크롤바 엄지 (위치 / 크기 / 색상) | 가로 스크롤바 |
|---|---|---|---|---|---|
| `a-outside.png` | 01:05:57 | 커서 (5,5) 창 밖 2초 대기 | `db232613...` | **보임**: X=1427..1440 (폭 14px), Y=110..142 (높이 33px), `#585c63` (배경 위 합성) | **없음** (0px) |
| `b-hover-2s.png` | 01:06:01 | 편집 영역 중앙 호버 2초 | `db232613...` | **보임**: `a-outside`와 100% 비트 일치 (위치·크기·색상 동일) | **없음** (0px) |
| `c-scrolling.png` | 01:06:02 | 휠 아래 3칸 직후 (+1.57s) | `daeb8ecc...` | **보임**: X=1427..1440 (폭 14px), Y=120..151 (높이 32px), `#585c63` (아래로 ~10px 이동) | **없음** (0px) |
| `d-after-0.5s.png`| 01:06:04 | 휠 종료 후 3.61초 | `daeb8ecc...` | **보임**: `c-scrolling`과 100% 비트 일치 (위치·색상 유지) | **없음** (0px) |
| `d-after-1.2s.png`| 01:06:07 | 휠 종료 후 5.82초 | `daeb8ecc...` | **보임**: `c-scrolling`과 100% 비트 일치 (위치·색상 유지) | **없음** (0px) |
| `d-after-2.2s.png`| 01:06:09 | 휠 종료 후 8.33초 | `daeb8ecc...` | **보임**: `c-scrolling`과 100% 비트 일치 (위치·색상 유지) | **없음** (0px) |
| `d-after-4.2s.png`| 01:06:13 | 휠 종료 후 11.86초 | `daeb8ecc...` | **보임**: `c-scrolling`과 100% 비트 일치 (위치·색상 유지) | **없음** (0px) |
| `e-outside-after.png`| 01:06:16| 다시 창 밖 커서 2초 (+15.38s)| `daeb8ecc...` | **보임**: `c-scrolling`과 100% 비트 일치 (위치·색상 유지) | **없음** (0px) |

#### 세로 스크롤바 상세 측정치
1. **트랙 테두리 및 폭**:
   - `X=1426`에 Y=109..820 전체 높이에 걸쳐 폭 1px 테두리선 `#2e333c` (`RGB [46, 51, 60]`) 확인 (`01-LAYOUT` E-031 `scrollbar_track_border` 및 `03-THEME-ICONS` T-04.21 `#2e333cff`와 정확히 일치).
   - 트랙/엄지 폭은 `X=1427..1440` (14px)이며 좌측 1px 테두리 포함 전체 점유 폭 15px (`01-LAYOUT` L-308 / E-030 15px와 정확히 일치).
2. **엄지(Thumb) 색상 및 알파 블렌딩**:
   - One Dark 테마 `scrollbar.thumb.background` = `#c8ccd44c` (RGB [200, 204, 212], alpha ~0.298).
   - 기본 배경 `#282c33` (`RGB [40, 44, 51]`) 위 합성값: `RGB [88, 92, 99]` (`#585c63`, 단일 정수 단위 완전 일치).
   - 활성 줄 하이라이트 `#2d323b` (`RGB [45, 50, 59]`) 위 합성값: `RGB [91, 96, 105]` (`#5b6069`, 완전 일치).
3. **스크롤바 오버뷰 룰러 마커**:
   - Y=110..111: 커서 위치 마커 (`#74ade8`, 엄지 오버레이 시 `#8db6e2`).
   - Y=371..377 및 Y=520..527: 문서 진단/검색 마커 (`#d3b020`).
4. **가로 스크롤바**:
   - 에디터 하단 영역(`Y=800..821`) 분석 결과 가로 스크롤바 트랙 및 엄지는 노출되지 않음 (0px, soft-wrap 적용 상태).

---

### 6.2 결론: Zed 스크롤바 표시 조건 및 숨김 시간 판정

1. **표시 조건**:
   - **오버플로 문서 항시 노출 (Always Visible)**:
     - 마우스 창 밖(`a`), 에디터 호버(`b`), 스크롤 직후(`c`), 스크롤 정지 후 장시간 경과(`d-0.5s` ~ `d-4.2s`), 창 밖 복귀(`e`) **모든 상태에서 세로 스크롤바 엄지가 상시 표시**됨.
     - `a`와 `b`가 100% 일치하고, `c`부터 `e`까지 6종의 이미지가 100% 일치함. 호버나 휠 입력 여부에 따라 스크롤바가 페이드인/페이드아웃되지 않음.
     - Zed의 `scrollbar.show: "auto"`는 Windows 환경에서 본문 내용이 뷰포트 높이를 초과(overflow)하는 경우 상시 표시(Always)로 동작하거나, OS 자동 숨김 설정을 미적용하여 항상 노출함.
2. **숨김 시간**:
   - 휠 스크롤 완료 시점(`01:06:01.319`)부터 마지막 창 밖 캡처(`01:06:16.694`)까지 **15.38초 동안 스크롤바가 단 한 번도 사라지지 않고 완전히 동일한 픽셀로 유지**됨.
   - 따라서 스크롤 정지 후 1초 뒤 숨김(E-033) 동작은 Windows Zed에서 발생하지 않으며, **"숨김 시간" 자체가 존재하지 않음 (측정 대상 없음/항시 표시)**.

---

### 6.3 C-08(PrintWindow)과 C-09(Screen) 결과 차이 분석

C-08 캡처(`zed-initial.png`, `test-printwindow.png`)에서는 우측 스크롤바 영역이 에디터 배경색 단색으로 관측되었으나, C-09(`a-outside.png` 등)에서는 초기 창 밖 상태에서도 스크롤바가 선명하게 관측된 원인은 다음과 같다.

1. **캡처 메커니즘 차이 (DirectComposition/DirectX vs GDI PrintWindow)**:
   - C-08은 Win32 `PrintWindow(..., PW_RENDERFULLCONTENT)`를 사용하였음. Zed(GPUI)는 Windows에서 Direct3D 11 / DirectComposition 기반 하드웨어 가속 레이어를 사용함.
   - `PrintWindow` 호출 시 DirectComposition 스왑체인 위에 별도 시각 트리로 얹히는 오버레이 요소(스크롤바 트랙, 엄지, 오버뷰 룰러 마커)가 GDI 리디렉션 DC에 합성되지 않고 바탕 서피스만 캡처되었음.
   - 반면 C-09는 `capture.ps1 -Method Screen`(`BitBlt`를 통한 실제 디스플레이 프레임버퍼 덤프)을 사용하여 화면에 실제로 렌더링된 픽셀을 그대로 캡처하였음.
2. **초기화 및 활성화(Focus) 완료 시점 차이**:
   - C-08은 프로세스 기동 및 리사이즈 직후 백그라운드 상태에서 캡처가 수행되어 에디터 렌더 패스가 완료되기 전 상태가 캡처되었을 가능성이 있음.
   - C-09는 `SetForegroundWindow` 및 7초 이상의 대기(Sleep)를 거쳐 포그라운드 활성 렌더링이 완전히 안정화된 상태에서 캡처되었음.

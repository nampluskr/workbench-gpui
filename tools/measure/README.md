# tools/measure — V3 실측 스크립트 (PowerShell 7)

AGENTS 3A.4 절차용. 앱은 `measure`가 세션당 1회만 띄운다. 조건은 주 모니터 1920×1080, 100%, 최대화 창이다.
모든 스크립트는 `-Out`(기본 `specs\v0.3\verify\reviews\p0-measure`)에 결과를 쓴다. 새 측정은 `-Out`을 새 폴더로 준다. 사용자 데이터 백업은 `-Backup`을 안 주면 `-Out`의 형제 폴더 `_<Out 폴더명>-backup`을 쓴다(Start·Stop 공통). P0 기록을 다시 돌릴 때는 `-Out`·`-Backup`(`..\_p0-6-backup`)을 명시한다.

| 스크립트 | 하는 일 |
| --- | --- |
| `session.ps1` | `-Action Start`(`-Exe <경로>`로 실행할 exe를 고른다. 기본은 `targetdebug`의 exe이며, 공유 target을 다른 빌드가 덮어쓸 수 있으므로 빌드 직후 임시 폴더로 복사한 사본을 쓴다): 앱 데이터 백업·초기화 후 `target\debug\workbench-gpui.exe`를 `--dev-layout --dev-keymap --dev-pick-folder`로 실행(창은 보이게). `-Json`을 주면 `--dev-layout-json <Out>\layout.json`도 넘긴다. `Snapshot -State S1`: 마지막 완성 덤프를 `S1.json`·`S1-dump.txt`로 저장(`-Capture`로 PNG도). `Stop`: 앱을 닫은 뒤 앱 데이터 복원·해시 대조·픽스처 삭제. 원래 앱 데이터 폴더가 없었다면 폴더째 지운다 |
| `input.ps1` | 측정 창에 최소 입력. `-Action Maximize\|Click\|DoubleClick\|RightClick\|Hover\|Key`, `-Box <덤프 박스 이름>`(중심 좌표) 또는 `-X -Y`, `-Key escape\|f2\|f10\|enter\|right\|down`. `Check`·`DismissOpenWith`는 포그라운드 확인용 |
| `compare.ps1` | `-Json layout.json -Checks checks.txt [-Report out.md]`: 덤프 JSON의 박스를 `spec/zed-metrics.toml` 기대값과 비교. 불일치·누락이면 종료 코드 1 |
| `p0-report.ps1`, `p0-pixels.ps1` | P0-6 기록용 일회성 스크립트(S1~S7 JSON·PNG 전용). 재사용 대상 아님 |

이름 변경(P1-5): `p0-session.ps1` → `session.ps1`, `p0-input.ps1` → `input.ps1`, `p0-show.ps1` 삭제(`input.ps1 -Action Maximize`로 대체). P0 기록 문서는 옛 이름 그대로다.

## 흐름

```powershell
pwsh -File tools/measure/session.ps1 -Action Start -Json -Out <dir>
pwsh -File tools/measure/input.ps1 -Action Maximize -Out <dir>
# ...목록의 상태에 도달하는 최소 입력(input.ps1)...
pwsh -File tools/measure/session.ps1 -Action Snapshot -State S1 -Out <dir>
pwsh -File tools/measure/compare.ps1 -Json <dir>\layout.json -Checks tools/measure/checks.txt -Report <dir>\S1-compare.md
# 앱을 닫은 뒤
pwsh -File tools/measure/session.ps1 -Action Stop -Out <dir>
```

## checks.txt

한 줄에 `스펙ID | 박스이름 | w\|h\|x\|y [| 기대 cond]`, `#` 주석. 스펙 ID는 `테이블["키"]`(P1-1 표기). cond를 적으면 스펙의 cond와 다를 때 실패한다. 허용 오차는 `verification.tolerance`(px 치수 `dimension` ±1, ID가 `typography[`로 시작하거나 키에 `font_size`가 들면 ±0.5, px 외 단위는 정확히 일치).

```text
titlebar["height"] | titlebar | h | default
project_panel["item.height"] | tree-row-04 | h
```

## JSON 형식 (P1-4)

`{"seq":n,"rem":16.0,"scale":1.0,"viewport":{"w":..,"h":..},"boxes":[{"name":"..","x":..,"y":..,"w":..,"h":..}]}` — 논리 px, 스냅숏마다 파일 전체를 다시 쓴다.

## 한계

- 100%·주 모니터 전제다(박스 좌표를 화면 픽셀로 쓴다). 바뀌면 `session.ps1`·`input.ps1` 보강이 필요하다.
- `compare.ps1`은 toml의 한 줄 레코드만 읽는다(형식이 바뀌면 TOML 파서로 교체).
- `input.ps1`은 `tools/verify-v02-phase4.ps1`의 네이티브 선언을 파싱해 재사용한다.

## check-layout.ps1 (R-16)

`pwsh -File tools/measure/check-layout.ps1 -Exe <절대 경로> [-Out <dir>] [-Report <md>]` — 앱을 작게 띄운 뒤 최대화해 빈 화면(S1) 덤프를 받고 `checks-layout.txt`의 28항목을 스펙과 비교한다. FAIL이 하나라도 있으면 exit 1. 출력을 파이프로 받지 않는다(앱이 핸들을 물고 있음). `compare.ps1`에는 두 박스의 차이를 재는 `diff` 행(`A.f ~ B.f`)이 있다. 결과 기록: `specs/v0.4/verify/reviews/check-layout.md`.
`checks.txt` 행에 `| exact`를 붙이면 그 행만 허용 오차 0으로 비교한다(`checks-layout.txt`는 28행 전부 exact).

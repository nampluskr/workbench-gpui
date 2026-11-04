#Requires -Version 7
$ErrorActionPreference='Stop'
Set-Location 'D:\projects\workbench-gpui'
$out='specs/v0.4/verify/reviews/p2-0-measure'
$report='specs/v0.4/verify/reviews/measure-p2-0.md'
$scope=@('window','titlebar','sidebar','dock','project_panel','tab','pane','statusbar','tooltip','menu','scrollbar','inline_input','editor','buttons','icons','spacing','borders','typography')
$metrics=[ordered]@{}; $section=''
# shortcut: parse the current one-line metric records, use a TOML parser if the format changes
foreach ($line in (Get-Content spec/zed-metrics.toml -Encoding utf8)) {
 if ($line -match '^\[(.+)\]') {$section=$matches[1]}
 elseif ($line -match '^"([^"]+)" = \{ value = (.+?), unit = "([^"]+)", cond = "([^"]+)", src = "([^"]+)"') {
  if ($section -in $scope -and $matches[3] -in @('px','ratio','chars')) {
   $metrics["$section|$($matches[1])"]=@{section=$section;key=$matches[1];value=[double]$matches[2];unit=$matches[3];cond=$matches[4];src=$matches[5]}
  }
 }
}
$states=@{}
foreach ($s in @('S1','S2','S3a','S3','S4','S5','S6','S7')) {$states[$s]=Get-Content -Raw "$out/$s.json" | ConvertFrom-Json -AsHashtable}
$tolerance=Get-Content spec/zed-metrics.toml -Encoding utf8 | Select-String '^"dimension" = \{ value = ([\d.]+),'
if ($tolerance.Count -ne 1) {throw 'Dimension tolerance must be unique'}
$tol=[double]$tolerance.Matches[0].Groups[1].Value
if ($tol -ne 1) {throw 'Review changed tolerance before reporting'}
$rows=[Collections.Generic.List[object]]::new(); $covered=[Collections.Generic.HashSet[string]]::new()
function B($s,$name) {if (-not $states[$s].boxes.Contains($name)) {throw "Missing $s $name"}; return $states[$s].boxes[$name]}
function M($s,$section,$key,[double]$actual,$evidence,[switch]$Record,[string]$Note='') {
 $id="$section|$key"; if (-not $metrics.Contains($id)) {throw "Unknown metric $id"}
 $m=$metrics[$id]; $delta=$actual-$m.value
 $t=if($m.unit -eq 'px'){$tol}else{0}; $verdict=if($Record){'기록만'}elseif($delta -eq 0){'PASS'}elseif([math]::Abs($delta) -le $t){'불일치(오차 안)'}else{'FAIL'}
 $rows.Add(@{state=$s;id=($section+'["'+$key+'"]');expected=$m.value;unit=$m.unit;actual=$actual;delta=$delta;verdict=$verdict;evidence="$s-dump.txt seq=$($states[$s].seq) $evidence";note=$Note})
 [void]$covered.Add($id)
}
M S1 titlebar height (B S1 title-bar).h 'title-bar.h'
M S1 titlebar padding_left ((B S1 app-menu).x-(B S1 title-bar).x) 'app-menu.x - title-bar.x'
M S1 titlebar left_group.gap ((B S1 title-folder-name).x-(B S1 app-menu).x-(B S1 app-menu).w) 'title-folder-name.x - app-menu.right'
M S1 titlebar window_button.width (B S1 window-btn-close).w 'window-btn-close.w'
M S1 titlebar window_button.height (B S1 window-btn-close).h 'window-btn-close.h'
M S1 window border_workspace_top ((B S1 body).y-(B S1 work-area).y) 'body.y - work-area.y'
M S1 window border_workspace_bottom ((B S1 status-bar).y-(B S1 body).y-(B S1 body).h) 'status-bar.y - body.bottom'
M S1 window border_sidebar_right ((B S1 sidebar).w-(B S1 sidebar-header).w) 'sidebar.w - sidebar-header.w'
M S1 sidebar default_width (B S1 sidebar).w 'sidebar.w' -Note 'Q-15: empty state, before folder registration'
M S1 sidebar header_height (B S1 sidebar-header).h 'sidebar-header.h'
M S2 sidebar project_header.height (B S2 folder-row-00).h 'folder-row-00.h'
M S1 sidebar footer.height (B S1 sidebar-footer).h 'sidebar-footer.h' -Note 'Q-9: 31 vs 30; +1 is within tolerance'
M S1 sidebar footer.padding ((B S1 sidebar-btn-toggle).x-(B S1 sidebar-footer).x) 'sidebar-btn-toggle.x - sidebar-footer.x'
M S1 sidebar footer.gap ((B S1 sidebar-footer-left-placeholder).x-(B S1 sidebar-btn-toggle).x-(B S1 sidebar-btn-toggle).w) 'placeholder.x - toggle.right'
M S1 sidebar footer.icon_size (B S1 sidebar-icon-toggle).w 'sidebar-icon-toggle.w'
M S1 dock resize_handle_width (B S1 dock-handle).w 'dock-handle.w'
M S1 project_panel default_width (B S1 dock).w 'dock.w'
M S2 project_panel item.height (B S2 tree-row-01).h 'tree-row-01.h' -Note 'comfortable 26 observed; standard is not switchable in this UI'
M S2 project_panel item.gap ((B S2 tree-label-02).x-(B S2 tree-icon-02).x-(B S2 tree-icon-02).w) 'tree-label-02.x - tree-icon-02.right'
M S2 project_panel indent_step ((B S2 tree-icon-02).x-(B S2 tree-icon-03).x) 'depth2 icon.x - depth1 icon.x'
M S2 project_panel indent_guide.width (B S2 tree-guide-02-1).w 'tree-guide-02-1.w'
M S2 project_panel indent_guide.offset_x ((B S2 tree-guide-01-0).x-(B S2 tree-row-01).x) 'tree-guide-01-0.x - tree-row-01.x'
M S2 project_panel indent_guide.padding_y ((B S2 tree-guide-01-0).y-(B S2 tree-row-01).y) 'tree-guide-01-0.y - tree-row-01.y'
M S2 icons size.medium (B S2 tree-icon-02).w 'tree-icon-02.w' -Record -Note 'Q-11/L-40: panel icon box 16 only recorded'
M S3 tab bar_height (B S3 tab-bar).h 'tab-bar.h'
M S3 tab content_height (B S3 tab-00).h 'tab-00.h minus bottom blank/border; combined occupied box' -Record -Note 'tab-content probe absent for live tabs; outer box is 32'
M S3 tab end_buttons_area.gap ((B S3 tab-btn-split).x-(B S3 tab-btn-new).x-(B S3 tab-btn-new).w) 'tab-btn-split.x - tab-btn-new.right'
M S3 tab end_buttons_area.padding_x ((B S3 tab-btn-new).x-(B S3 tab-bar-end).x-1) 'tab-btn-new.x - tab-bar-end.x - left border(1)' -Note 'border measured as adjacent single-pixel gap'
M S3 tab bar_icon_size (B S3 tab-icon-new).w 'tab-icon-new.w'
M S1 statusbar height (B S1 status-bar).h 'status-bar.h'
M S1 statusbar padding_y ((B S1 status-btn-project-panel).y-(B S1 status-bar).y) 'status-btn-project-panel.y - status-bar.y'
M S1 statusbar button_height (B S1 status-btn-project-panel).h 'status-btn-project-panel.h'
M S1 statusbar group_gap ((B S1 status-right).x-(B S1 status-left).x-(B S1 status-left).w) 'status-right.x - status-left.right'
M S1 statusbar item_gap ((B S1 status-left-placeholder).x-(B S1 status-btn-project-panel).x-(B S1 status-btn-project-panel).w) 'status-left-placeholder.x - button.right'
M S1 statusbar icon_size (B S1 status-icon-project-panel).w 'status-icon-project-panel.w'
M S1 buttons height.default (B S1 app-menu-button).h 'app-menu-button.h'
M S1 icons size.small (B S1 sidebar-icon-toggle).w 'sidebar-icon-toggle.w'
$tooltipLine=@(Get-Content "$out/app-stdout.txt" -Encoding utf8 | Where-Object {$_ -match '^\[dev\] tooltip-shown id=tab-btn-new '})[-1]
if ($tooltipLine -notmatch 'mouse=([-\d.]+),([-\d.]+)') {throw 'Tooltip anchor not recorded'}
$mouseX=[double]$matches[1]; $mouseY=[double]$matches[2]
foreach ($combined in @(
 @{id='tooltip.cursor_offset_x + tooltip.transparent_margin_left';expected=$metrics['tooltip|cursor_offset_x'].value+$metrics['tooltip|transparent_margin_left'].value;actual=(B S4 tooltip-box).x-$mouseX;unit='px';evidence='tooltip-box.x - logged mouse.x'},
 @{id='tooltip.cursor_offset_y + tooltip.transparent_margin_top';expected=$metrics['tooltip|cursor_offset_y'].value+$metrics['tooltip|transparent_margin_top'].value;actual=(B S4 tooltip-box).y-$mouseY;unit='px';evidence='tooltip-box.y - logged mouse.y'}
)) {
 $delta=$combined.actual-$combined.expected
 $rows.Add(@{state='S4';id=$combined.id;expected=$combined.expected;unit='px';actual=$combined.actual;delta=$delta;verdict=$(if($delta -eq 0){'PASS'}elseif([math]::Abs($delta)-le $tol){'불일치(오차 안)'}else{'FAIL'});evidence="S4-dump.txt seq=$($states.S4.seq) $($combined.evidence); app-stdout tooltip-shown";note='combined offset only; individual margins are not separately measured'})
}
$rows.Add(@{state='S4';id='tooltip outer box (L-211~L-215)';expected='internal terms not separated';unit='px';actual="$((B S4 tooltip-box).w) x $((B S4 tooltip-box).h)";delta='—';verdict='기록만';evidence="S4-dump.txt seq=$($states.S4.seq) tooltip-box; S4.png";note='57x33 recorded; no independent font/padding/radius verdict'})
M S5 menu min_width ((B S5 menu-box).w-2) 'menu-box.w minus 2 borders' -Record -Note 'observed inner width; 200 is a minimum, not fixed width'
M S5 menu min_outer_width (B S5 menu-box).w 'menu-box.w' -Record -Note '213 >= 202; minimum threshold not reached with this label'
M S5 menu popup_offset_x ((B S5 menu-box).x-(B S5 app-menu).x) 'menu-box.x - app-menu.x'
M S5 menu popup_offset_y ((B S5 menu-box).y-(B S5 app-menu).y-(B S5 app-menu).h) 'menu-box.y - app-menu.bottom'
M S5 menu list_padding_y ((B S5 menu-row-00).y-(B S5 menu-box).y-1) 'menu-row-00.y - menu-box.y - border'
M S5 menu item.margin_x ((B S5 menu-row-00).x-(B S5 menu-box).x-1) 'menu-row-00.x - menu-box.x - border'
M S5 menu item.line_height (B S5 menu-row-00).h 'menu-row-00.h' -Note 'rendered line box 23 vs source 22.652'
M S5 menu horizontal.item_gap ((B S5 menu-name-1).x-(B S5 menu-name-0).x-(B S5 menu-name-0).w) 'menu-name-1.x - menu-name-0.right'
M S6 menu separator.height (B S6 ctx-menu-row-2).h 'ctx-menu-row-2.h'
M S6 menu separator.margin_y ((B S6 ctx-menu-row-2).y-(B S6 ctx-menu-row-1).y-(B S6 ctx-menu-row-1).h) 'separator.y - preceding row.bottom'
M S6 menu item.line_height (B S6 ctx-menu-row-0).h 'ctx-menu-row-0.h' -Record -Note 'Q-11/I-508: current context row height 23; no estimated-height verdict'
M S7 inline_input height (B S7 tree-label-05).h 'tree-label-05.h (rename input container)'
$px=Get-Content -Raw "$out/S7-pixels.json" | ConvertFrom-Json
if ($px.right.length -ne 2 -or $px.top.length -ne 1 -or $px.bottom.length -ne 1) {throw 'S7 pixel scan file inconsistent'}
M S7 inline_input border_right $px.right.length 'S7.png y=176 x=612..613; S7-pixels.json' -Note 'pixel scan, not a source-code value'
M S7 inline_input border_top_bottom_left 1 'S7.png: top y=163, interior y=164..187, bottom y=188 (x=520)' -Note 'top and bottom measured; left border not separable from the dock border (x=374-375, 229-gray)'
$ed=Get-Content -Raw "$out/S3-editor-pixels.json" | ConvertFrom-Json
M S3 editor cursor_width $ed.cursor.width 'S3c.png blink-on frame: dark column x=667 only (1 px), y=75..91' -Note 'pixel scan; cursor visible only in blink-on frames'
M S3 editor line_height.standard $ed.lineNumberDigits.pitch 'S3.png line-number glyph rows 80-87 / 100-107: pitch 20' -Note 'pixel pitch from 2 visible lines (1 px resolution); compared with standard 19.5'
M S3 editor line_height.comfortable $ed.lineNumberDigits.pitch 'S3.png line-number glyph rows 80-87 / 100-107: pitch 20' -Note 'same pitch compared with comfortable 24.27 (Zed default multiplier 1.618)'
$capture=Get-Content -Raw "$out/S1-capture.json" | ConvertFrom-Json
if ($capture.dpi -ne 96 -or $capture.monitor.device -ne '\\.\DISPLAY1' -or -not $capture.maximized) {throw 'Measurement conditions differ from card'}
$rows | ConvertTo-Json -Depth 6 | Set-Content "$out/measurements.json" -Encoding utf8
$lines=[Collections.Generic.List[string]]::new()
$lines.Add('# P2-0 V3 실측 (UI 셸·에디터 영역) — 2026-11-04')
$lines.Add('')
$sess=Get-Content -Raw "$out/session.json" | ConvertFrom-Json
$bi=Get-Content -Raw "$env:TEMP\wbg-measure\cf3a82d\build-info.json" | ConvertFrom-Json
$cap=Get-Content -Raw "$out/S1-capture.json" | ConvertFrom-Json
$lines.Add("- 대상: master ``cf3a82d``. 빌드 직후 ``target\debug\workbench-gpui.exe``를 ``$($sess.exe)``로 복사해 그 사본으로 실행했다(lead 지시). 사본 SHA-256 ``$($sess.exeHash)``(매니페스트 병합 전 ``$($bi.preManifestSha256)``). 종료 뒤 exeUnchanged를 session 정리 결과로 확인.")
$lines.Add('- 이전 시도(`_p2-0-run1-unverified/`): 공유 target exe로 한 번 측정했으나 그 exe가 master 빌드인지 증명할 수 없어(빌드 뒤 다른 worktree 빌드가 덮어썼을 수 있음) 폐기하고 사본으로 다시 쟀다. 이 문서는 사본 실행만 근거로 한다.')
$lines.Add("- 조건: DISPLAY1 1920x1080, DPI $($cap.dpi) (100%), 최대화 client 1920x1032, 앱 기본 라이트 테마, rem=16. 허용 오차는 toml verification.tolerance.dimension = ±1 논리 px.")
$lines.Add('- 판정: 같으면 PASS, 오차(±1px) 안에서 다르면 **불일치(오차 안)**(D-3: 이것도 맞춘다), 오차 밖이면 FAIL, 의미가 최솟값·경계값이라 판정하지 않으면 기록만. 미측정은 통과 수에 넣지 않는다.')
$lines.Add("- 앱 프로세스 1회(PID $($sess.pid)): ``--dev-layout --dev-keymap --dev-pick-folder``, 시작 전 기존 앱 없음 확인. --dev-editor-poc 는 쓰지 않았다(앱 1회 원칙). 에디터 영역은 gpui-kit Editor(읽기 전용)에 probe가 없어 캡처 픽셀로 쟀다.")
$lines.Add('- 상태: S1 빈 화면·최대화; S2 시험 폴더(파일 80개) 등록, branch·nested 펼침; S3a 파일 한 번 클릭(preview 탭); S3 다른 파일 더블클릭(일반 탭, 에디터 표시); S3c 같은 상태를 커서가 켜진 프레임에서 다시 캡처; S4 새 탭 버튼 tooltip; S5 앱 메뉴; S6 파일 컨텍스트 메뉴; S7 F2 이름 바꾸기 입력칸(이후 Esc). 상태에 도달하는 입력만 했다. 원문 덤프·캡처는 `p2-0-measure/`.')
$lines.Add('')
$lines.Add('## 측정 결과')
$lines.Add('')
$lines.Add('| 화면 상태 | 스펙 ID | 기대값 | 측정값 | 차이 | 판정 | 근거 |')
$lines.Add('|---|---|---:|---:|---:|---|---|')
foreach ($r in $rows) {$displayDelta=if($r.delta -is [string]){$r.delta}else{[math]::Round($r.delta,3)}; $lines.Add("| $($r.state) | ``$($r.id)`` | $($r.expected) $($r.unit) | $($r.actual) | $displayDelta | $($r.verdict) | $($r.evidence); $($r.note) |")}
$lines.Add('')
$lines.Add('## 적용되지 않거나 별도 경계를 얻지 못한 항목')
$lines.Add('')
$lines.Add('다음은 PASS로 간주하지 않는다. 카드의 제외 영역을 넓히거나 구현 코드를 실제 측정값 대신 사용하지 않았다. 이 목록은 허용된 섹션의 나머지 px·ratio·chars 항목별 측정 한계를 남긴다.')
$lines.Add('')
$lines.Add('| 스펙 ID | 기대값 / 조건 | 측정값 | 판정 | 사유 |')
$lines.Add('|---|---|---|---|---|')
foreach ($id in $metrics.Keys) {
 if ($covered.Contains($id)) {continue}
 $m=$metrics[$id]
 $reason=switch($m.section) {
  window {'S1은 최대화. 비최대화 모서리·그림자 조건은 미적용. 일부 1px 경계는 중첩 테두리 때문에 독립 probe 없음.'}
  titlebar {'S1/S2에 없는 user-menu 또는 글리프/문자수 한계. 글리프 상자는 font point size와 같지 않아 추정 판정하지 않음.'}
  sidebar {'S1/S2에서 범위 끝값·오버플로·행 내부 개별 경계는 미노출. Q-12 핸들은 제외.'}
  dock {'최소 폭은 이번 기본 폭 상태에서 미도달; 리사이즈 동작 검증을 추가하지 않음.'}
  project_panel {'standard 조건 전환 UI가 없거나 개별 border/segment 경계 probe 없음. 관측 행은 comfortable 외형 26px.'}
  tab {'실제 탭에서 일부 slot/content probe가 없거나 overflow·제목 최대 길이 조건 미도달.'}
  pane {'현재 단일 Pane. 분할선·drag/drop·zoom 조건은 S3에 없고 카드 밖 상태를 만들지 않음.'}
  tooltip {'S4는 짧은 제목 단일줄 tooltip. 상자 probe만 있어 내부 padding·corner·font·shortcut 구간을 독립 식별할 수 없음.'}
  menu {'S5/S6에서 해당 내부 label/icon/font 또는 한계 높이·keyboard 위치 조건이 노출되지 않음.'}
  scrollbar {'S2는 overflow지만 저장된 캡처에서 scrollbar thumb/track을 독립 식별할 probe나 분리된 픽셀 구간이 없음. 숨김 상태에서 폭을 추정하지 않음.'}
  editor {'gpui-kit Editor(읽기 전용)에는 레이아웃 probe가 없다. 캡처 픽셀로 잰 항목만 위에 있고, ch·digits·ms·동작 값과 툴바·검색·스크롤바는 이 화면 상태에 없거나 픽셀로 분리할 수 없다.'}
  inline_input {'S7은 정상 이름을 선택한 입력칸. warning/error banner는 없으며 입력 오류를 일부러 만들지 않음.'}
  buttons {'현재 S1~S7에서 이 크기 변형이 노출되지 않거나 내부 개별 경계 없음.'}
  icons {'허용된 상자만 대상. 이 변형 상자 미노출 또는 viewbox/stroke/inner artwork 제외(Q-8).'}
  spacing {'Base 토큰은 렌더 요소가 아니다. 위 관측 gap을 각 화면 ID로 기록했으며 다른 Base 변형을 만들지 않음.'}
  borders {'현재 probe는 바깥 직사각형. 모서리 radius를 직사각형 bounds에서 역산하지 않음.'}
  typography {'텍스트 line box/잉크 높이는 font size가 아니다. font 설정값을 측정값으로 대체하지 않음.'}
 }
 $lines.Add('| `'+$m.section+'["'+$m.key+'"]` | '+$m.value+' '+$m.unit+' / '+$m.cond+' | 미측정 | 기록만 | '+$reason+' |')
}
$pass=@($rows | Where-Object verdict -eq PASS).Count
$near=@($rows | Where-Object verdict -eq '불일치(오차 안)').Count
$fail=@($rows | Where-Object verdict -eq FAIL).Count
$rec=@($rows | Where-Object verdict -eq '기록만').Count
$lines.Add('')
$lines.Add("계수: 수치 관측 $($rows.Count)행 = PASS $pass, 불일치(오차 안) $near, FAIL $fail, 기록만 $rec. 미측정 $($metrics.Count-$covered.Count)항목은 통과 수에 넣지 않았다.")
$areaOf={ param($r) $id=$r.id; if($id -match '^([a-z_]+)\['){$matches[1]}elseif($id -match '^tooltip'){'tooltip'}else{'기타'} }
$lines.Add('')
$lines.Add('## 영역별 불일치 수')
$lines.Add('')
$lines.Add('| 영역 | 관측 | PASS | 불일치(오차 안) | FAIL | 기록만 |')
$lines.Add('|---|---:|---:|---:|---:|---:|')
foreach($g in ($rows | Group-Object { & $areaOf $_ } | Sort-Object Name)){
 $v=$g.Group.verdict
 $lines.Add("| $($g.Name) | $($g.Count) | $(@($v|?{$_ -eq 'PASS'}).Count) | $(@($v|?{$_ -eq '불일치(오차 안)'}).Count) | $(@($v|?{$_ -eq 'FAIL'}).Count) | $(@($v|?{$_ -eq '기록만'}).Count) |")
}
$lines.Add('')
$lines.Add('## 스펙 불일치 목록 (D-3: Phase 2에서 맞춘다)')
$lines.Add('')
foreach ($r in @($rows | Where-Object {$_.verdict -in 'FAIL','불일치(오차 안)'})) {$d=[math]::Round($r.delta,3); $lines.Add("- [$($r.verdict)] $($r.state) ``$($r.id)``: 기대 $($r.expected)$($r.unit), 실제 $($r.actual), 차이 $d. $($r.note)")}
$lines.Add('')
$lines.Add('## 기록만 항목 중 값이 기대와 다른 것')
$lines.Add('')
foreach ($r in @($rows | Where-Object {$_.verdict -eq '기록만' -and $_.delta -is [double] -and $_.delta -ne 0})) {$d=[math]::Round($r.delta,3); $lines.Add("- $($r.state) ``$($r.id)``: 기준 $($r.expected)$($r.unit), 실제 $($r.actual), 차이 $d. $($r.note)")}
$lines | Set-Content $report -Encoding utf8
@{pass=$pass;near=$near;fail=$fail;record=$rec;observations=$rows.Count;unmeasured=$metrics.Count-$covered.Count} | ConvertTo-Json

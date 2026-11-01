#Requires -Version 7
<#
.SYNOPSIS
  v0.2 Phase 3 리뷰 1회차 ③·④(D-037) 재현: 검증 스크립트의 사용자 파일 보존을 두 상황에서 시험한다.

.DESCRIPTION
  사례(각각 -Script 로 준 검증 스크립트를 `-Only empty` 로 자식 프로세스에서 돌린다):
    running  ④ 앱이 이미 실행 중(--dev-keymap 으로 이 하네스가 띄움). 고친 스크립트는 사용자 파일을 바꾸기 전에 멈춰야 한다.
             판정: 실행 중 앱의 keymap 다시 읽기(keymap-load seq>=2)가 없고, 사용자 파일 해시가 그대로.
    locked   ③ state.json 을 공유 삭제 없이 열어 둔 채(지우기·덮어쓰기 불가) 돌린다. 고친 스크립트는 state.json 복원이
             실패해도 keymap.json 을 되돌려야 한다. 판정: 끝난 뒤 keymap.json 해시가 그대로.
    normal   (리뷰 2회차, D-040) 앱 없이 `-Only quitnochange` 정상 실행. 판정: 스크립트 통과, 사용자 파일 해시 그대로.
    세 사례 모두(D-040): 하네스가 미리 만든 target\phase3-folders\left-by-earlier-run-<id>\keep.txt(앞선 실행이 남긴 시험 폴더 표본)가
             그대로 남고, 스크립트의 이번 실행 폴더(run-<id>)는 남지 않아야 한다.
  두 사례 모두 시험용 사용자 파일(keymap.json `[]`, 빈 state.json)을 먼저 만든다. 하네스는 시작 때 실제 사용자 파일을
  백업하고 끝에 파일마다 따로 되돌린다(시험용 파일은 지운다). 결과는 -OutDir 의 guard-results.json.

.EXAMPLE
  pwsh -NoProfile -File tools/verify-v02-phase3-guard.ps1 -Script tools/verify-v02-phase3.ps1 -OutDir specs/v0.2/verify/phase3/d037-rerun/guard-after
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$Script,
    [Parameter(Mandatory)] [string]$OutDir,
    [string]$Exe = 'target\debug\workbench-gpui.exe'
)
$ErrorActionPreference = 'Stop'
$ProcessName = 'workbench-gpui'
$out = [System.IO.Path]::GetFullPath($OutDir, (Get-Location).Path)
New-Item -ItemType Directory -Path $out -Force | Out-Null
$appDir = Join-Path $env:APPDATA 'workbench-gpui'
$keymapPath = Join-Path $appDir 'keymap.json'
$statePath = Join-Path $appDir 'state.json'
$results = [ordered]@{ script = $Script; startedAt = (Get-Date).ToString('o'); cases = [ordered]@{}; failures = @() }

function Hash([string]$p) { if (Test-Path -LiteralPath $p) { (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash } else { '<absent>' } }
function UserFiles { if (Test-Path -LiteralPath $appDir) { @(Get-ChildItem -LiteralPath $appDir -File | Where-Object { $_.Name -eq 'keymap.json' -or $_.Name -like 'state.json*' }) } else { @() } }
function Put([string]$p, [string]$t) { New-Item -ItemType Directory -Path (Split-Path -Parent $p) -Force | Out-Null; [System.IO.File]::WriteAllText($p, $t, [System.Text.UTF8Encoding]::new($false)) }
function Run-Child([string]$Name, [string]$Case = 'empty') {
    $childOut = Join-Path $out "$Name-script"
    $log = & pwsh -NoProfile -Command "& '$Script' -Only $Case -OutDir '$childOut'" 2>&1 | Out-String
    Set-Content -LiteralPath (Join-Path $out "$Name-script-output.txt") -Value $log -Encoding utf8
    return $log
}

if (@(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue).Count -gt 0) { throw "이미 실행 중인 $ProcessName 가 있다. 닫고 다시 실행하라" }
$backup = Join-Path ([System.IO.Path]::GetTempPath()) ("wg-guard-backup-{0}" -f [guid]::NewGuid())
New-Item -ItemType Directory -Path $backup -Force | Out-Null
$userBefore = @{}; foreach ($f in (UserFiles)) { Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $backup $f.Name); $userBefore[$f.Name] = Hash $f.FullName }
$keymapText = '[]'
$stateText = '{ "version": 1, "windows": [ { "folders": [], "active_folder_id": null } ] }'
# 리뷰 2회차(D-040): 미리 있던 시험 폴더(앞선 실행이 남긴 것처럼)를 만들어 두고, 스크립트가 그것을 지우지 않는지 본다.
$preBase = [System.IO.Path]::GetFullPath('target\phase3-folders', (Get-Location).Path)
$preDir = Join-Path $preBase ("left-by-earlier-run-{0}" -f [guid]::NewGuid().ToString('N'))
$preFile = Join-Path $preDir 'keep.txt'
$preBaseExisted = Test-Path -LiteralPath $preBase
Put $preFile 'earlier run leftover 한글'
$preHash = Hash $preFile
function Check-Pre([string]$Case) {
    $h = Hash $preFile
    $runs = @(Get-ChildItem -LiteralPath $preBase -Directory -Filter 'run-*' -ErrorAction SilentlyContinue).Count
    $ok = ($h -eq $preHash -and $runs -eq 0)
    $script:results.cases["$Case-preexisting"] = [ordered]@{ file = $preFile; hashBefore = $preHash; hashAfter = $h; runFoldersLeft = $runs; ok = $ok }
    if (-not $ok) { $script:results.failures += "${Case}: 미리 있던 시험 폴더가 바뀌었거나(해시 $h) 이번 실행 폴더가 남았다($runs)" }
}
try {
    # ---------------------------------------------------------------- running (④)
    foreach ($f in (UserFiles)) { Remove-Item -LiteralPath $f.FullName -Force }
    Put $keymapPath $keymapText; Put $statePath $stateText
    $k0 = Hash $keymapPath; $s0 = Hash $statePath
    $appLog = Join-Path $out 'running-app-stdout.txt'
    $app = Start-Process -FilePath (Resolve-Path $Exe).Path -ArgumentList @('--dev-keymap') -RedirectStandardOutput $appLog -PassThru
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        while ($sw.Elapsed.TotalSeconds -lt 20 -and -not (Select-String -LiteralPath $appLog -Pattern '^\[dev\] keymap-load seq=1 ' -Quiet -ErrorAction SilentlyContinue)) { Start-Sleep -Milliseconds 200 }
        $log = Run-Child 'running'
        Check-Pre 'running'
        Start-Sleep -Milliseconds 1500
        $reloads = @(Select-String -LiteralPath $appLog -Pattern '^\[dev\] keymap-load seq=([2-9]|\d\d+) ' -ErrorAction SilentlyContinue).Count
        $k1 = Hash $keymapPath; $s1 = Hash $statePath
        $early = $log -match '사용자 파일을 바꾸기 전에 중단한다'
        $ok = ($reloads -eq 0 -and $k1 -eq $k0 -and $s1 -eq $s0)
        $results.cases.running = [ordered]@{ abortedEarlyMessage = $early; runningAppKeymapReloads = $reloads; keymapBefore = $k0; keymapAfter = $k1; stateBefore = $s0; stateAfter = $s1; ok = $ok }
        if (-not $ok) { $results.failures += "running: 실행 중 앱이 사용자 파일 변경을 보았거나(keymap 다시 읽기 $reloads 번) 파일이 바뀌었다" }
    }
    finally { if (-not $app.HasExited) { $app.Kill(); [void]$app.WaitForExit(3000) } }

    # ---------------------------------------------------------------- locked (③)
    foreach ($f in (UserFiles)) { Remove-Item -LiteralPath $f.FullName -Force }
    Put $keymapPath $keymapText; Put $statePath $stateText
    $k0 = Hash $keymapPath
    $lock = [System.IO.File]::Open($statePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
    try { $log = Run-Child 'locked' }
    finally { $lock.Dispose() }
    Check-Pre 'locked'
    $k1 = Hash $keymapPath
    $ok = ($k1 -eq $k0)
    $results.cases.locked = [ordered]@{ keymapBefore = $k0; keymapAfter = $k1; keymapRestored = $ok; scriptReportedFailure = ($log -match 'failures: [1-9]') }
    if (-not $ok) { $results.failures += 'locked: state.json 을 지울 수 없을 때 사용자 keymap.json 이 되돌려지지 않았다' }

    # ---------------------------------------------------------------- normal (D-040): 앱 없이 정상 실행(짧은 사례 하나) 뒤에도 미리 있던 폴더는 남는다
    foreach ($f in (UserFiles)) { Remove-Item -LiteralPath $f.FullName -Force }
    Put $keymapPath $keymapText; Put $statePath $stateText
    $k0 = Hash $keymapPath; $s0 = Hash $statePath
    $log = Run-Child 'normal' 'quitnochange'
    $ok = ((Hash $keymapPath) -eq $k0 -and (Hash $statePath) -eq $s0 -and ($log -match 'failures: 0'))
    $results.cases.normal = [ordered]@{ scriptPassed = ($log -match 'failures: 0'); keymapSame = ((Hash $keymapPath) -eq $k0); stateSame = ((Hash $statePath) -eq $s0); ok = $ok }
    if (-not $ok) { $results.failures += 'normal: 정상 실행이 실패했거나 사용자 파일이 바뀌었다' }
    Check-Pre 'normal'
}
catch { $results.failures += "하네스 오류: $($_.Exception.Message)" }
finally {
    # 하네스가 만든 '미리 있던 폴더' 표본을 지운다(바탕 폴더는 하네스가 만들었고 비어 있을 때만).
    try { Remove-Item -LiteralPath $preDir -Recurse -Force; if (-not $preBaseExisted -and @(Get-ChildItem -LiteralPath $preBase -Force).Count -eq 0) { Remove-Item -LiteralPath $preBase -Force } } catch { $results.failures += "표본 지우기: $($_.Exception.Message)" }
    # 실제 사용자 파일을 파일마다 따로 되돌린다(시험용 파일은 지운다).
    foreach ($f in (UserFiles)) { try { Remove-Item -LiteralPath $f.FullName -Force } catch { $results.failures += "정리 $($f.Name): $($_.Exception.Message)" } }
    foreach ($b in (Get-ChildItem -LiteralPath $backup -File)) { try { Copy-Item -LiteralPath $b.FullName -Destination (Join-Path $appDir $b.Name) -Force } catch { $results.failures += "복원 $($b.Name): $($_.Exception.Message)" } }
    $userAfter = @{}; foreach ($f in (UserFiles)) { $userAfter[$f.Name] = Hash $f.FullName }
    $same = (($userBefore.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join ';') -eq (($userAfter.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join ';')
    $results.userFiles = [ordered]@{ before = $userBefore; after = $userAfter; restored = $same }
    if ($same) { Remove-Item -LiteralPath $backup -Recurse -Force } else { $results.failures += "실제 사용자 파일이 실행 전과 다르다(백업 $backup)" }
}
$results.finishedAt = (Get-Date).ToString('o')
$results | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $out 'guard-results.json') -Encoding utf8
"running: $($results.cases.running | ConvertTo-Json -Compress)"
"locked: $($results.cases.locked | ConvertTo-Json -Compress)"
"normal: $($results.cases.normal | ConvertTo-Json -Compress)"
"preexisting: $(@("running", "locked", "normal") | ForEach-Object { "$_=$($results.cases["$_-preexisting"].ok)" })"
"user files restored: $($results.userFiles.restored)"
$results.failures | ForEach-Object { "  - $_" }
if ($results.failures.Count -gt 0) { exit 1 }

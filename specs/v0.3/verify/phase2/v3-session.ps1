#Requires -Version 7
# P2-E V3 session: replays the P0-6 states (S1..S7) with tools/measure, then close-button hover/active and the missing-path screen.
# param -Exe is informational only: tools/measure/session.ps1 always starts target\debug\workbench-gpui.exe.
param([string]$Out = 'D:\projects\workbench-gpui\specs\v0.3\verify\phase2\v3-session', [string]$P0Fixture = 'p0-measure-27e73612099945d1884eae7551ceef07')
$ErrorActionPreference = 'Stop'
Set-Location 'D:\projects\workbench-gpui'
$m = 'tools/measure'
function Run($script, $argList) { $p = Start-Process pwsh -ArgumentList (@('-NoProfile','-File',"$m/$script") + $argList) -PassThru -Wait -NoNewWindow -RedirectStandardOutput (Join-Path $env:TEMP 'v3-run.log') -RedirectStandardError (Join-Path $env:TEMP 'v3-run.err'); if ($p.ExitCode) { throw "$script $argList failed ($($p.ExitCode))" } }
function In($action, $box, $key) {
    $a = @('-Action', $action, '-Out', $Out)
    if ($box) { $a += @('-Box', $box) }
    if ($key) { $a += @('-Key', $key) }
    Run 'input.ps1' $a
}
function Snap($state) { Start-Sleep -Milliseconds 1200; Run 'session.ps1' @('-Action', 'Snapshot', '-State', $state, '-Capture', '-Out', $Out) }

# Same fixture folder name as P0-6 so folder-name text widths are comparable (80 files + branch\nested).
$fixture = Join-Path 'D:\projects\workbench-gpui\target' $P0Fixture
if (Test-Path $fixture) { throw 'P0 fixture name already exists; refusing to reuse' }
New-Item -ItemType Directory -Path (Join-Path $fixture 'branch\nested') -Force | Out-Null
foreach ($i in 1..80) { 'Measurement fixture' | Set-Content (Join-Path $fixture ('file-{0:D3}.txt' -f $i)) }
'Nested fixture' | Set-Content (Join-Path $fixture 'branch\nested\nested.txt')
try {
    Run 'session.ps1' @('-Action', 'Start', '-Json', '-Out', $Out)
    $fixture | Set-Content (Join-Path $Out 'pick.txt') -Encoding utf8   # overrides the generated fixture path
    Start-Sleep -Seconds 3
    In 'Maximize'; Start-Sleep -Seconds 2
    Snap 'S1'
    In 'Click' 'sidebar-btn-folder-add'; Start-Sleep -Milliseconds 800
    In 'Click' 'tree-row-01'
    In 'Hover' 'active-item'
    Snap 'S2'
    In 'Click' 'tree-row-03'
    Snap 'S3a'
    In 'Hover' 'active-item'
    In 'DoubleClick' 'tree-row-04'
    Snap 'S3'
    In 'Hover' 'active-item'
    In 'Hover' 'tab-btn-new'; Start-Sleep -Milliseconds 1500
    Snap 'S4'
    In 'Key' $null 'f10'
    Snap 'S5'
    In 'Key' $null 'escape'
    In 'RightClick' 'tree-row-04'
    Snap 'S6'
    In 'Key' $null 'escape'
    In 'Key' $null 'f2'
    Snap 'S7'
    In 'Key' $null 'escape'
    Snap 'C0'          # rest state (colors reference)
    In 'Hover' 'window-btn-close'; Start-Sleep -Milliseconds 500
    Snap 'C1'          # close hover
}
finally { }



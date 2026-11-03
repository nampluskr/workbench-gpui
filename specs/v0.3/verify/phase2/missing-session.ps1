#Requires -Version 7
# P2-E extra: "path missing" project panel screen (not in P0-6). Run once per exe (-Tag before|after); the exe at target\debug is swapped by the caller.
param([Parameter(Mandatory)][string]$Tag)
$ErrorActionPreference = 'Stop'
Set-Location 'D:\projects\workbench-gpui'
$out = "D:\projects\workbench-gpui\specs\v0.3\verify\phase2\missing-$Tag"
$m = 'tools/measure'
function Run($script, $argList) { $p = Start-Process pwsh -ArgumentList (@('-NoProfile', '-File', "$m/$script") + $argList) -PassThru -Wait -NoNewWindow -RedirectStandardOutput (Join-Path $env:TEMP 'm-run.log') -RedirectStandardError (Join-Path $env:TEMP 'm-run.err'); if ($p.ExitCode) { throw "$script $argList failed ($($p.ExitCode))" } }
function In($action, $box) { $a = @('-Action', $action, '-Out', $out); if ($box) { $a += @('-Box', $box) }; Run 'input.ps1' $a }
$fixture = 'D:\projects\workbench-gpui\target\p2e-missing-folder'
if (Test-Path $fixture) { throw 'fixture exists' }
New-Item -ItemType Directory -Path $fixture | Out-Null
'x' | Set-Content (Join-Path $fixture 'a.txt')
Run 'session.ps1' @('-Action', 'Start', '-Json', '-Out', $out)
$fixture | Set-Content (Join-Path $out 'pick.txt') -Encoding utf8
Start-Sleep -Seconds 3
In 'Maximize'; Start-Sleep -Seconds 2
In 'Click' 'sidebar-btn-folder-add'; Start-Sleep -Seconds 1
Remove-Item -Recurse -Force $fixture
Start-Sleep -Seconds 3
In 'Hover' 'active-item'
Start-Sleep -Milliseconds 1500
Run 'session.ps1' @('-Action', 'Snapshot', '-State', 'S1', '-Capture', '-Out', $out)
Get-Process workbench-gpui -ErrorAction SilentlyContinue | ForEach-Object { [void]$_.CloseMainWindow() }
Start-Sleep -Seconds 3

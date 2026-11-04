#Requires -Version 7
# Note: child tools are run with `*> $null` (not a pipe) because the app started by session.ps1 inherits the console handles and would keep an outer pipe open.
# Automatic layout check (R-16): launch the app once with --dev-layout, small first and then maximized (the path where the sidebar 1.25x regression
# appeared), dump the empty first screen (S1) and compare it with spec/zed-metrics.toml (checks-layout.txt). Exit 1 if any item fails.
# Usage: pwsh -File tools/measure/check-layout.ps1 -Exe <absolute exe path> [-Out <dir>] [-Report <md>]
# Reuses session.ps1 (start/snapshot/stop), input.ps1 (maximize) and compare.ps1.
# shortcut: assumes primary monitor at 100% DPI like the other tools/measure scripts.
param([Parameter(Mandatory)][string]$Exe, [string]$Out, [string]$Report)
$ErrorActionPreference = 'Stop'
if (-not [IO.Path]::IsPathRooted($Exe) -or -not (Test-Path -LiteralPath $Exe)) { throw "Exe must be an existing absolute path: $Exe" }
if (-not $Out) { $Out = Join-Path $env:TEMP ('wbg-check-layout\' + (Get-Date -Format 'yyyyMMdd-HHmmss')) }
$tools = $PSScriptRoot
$failed = $false
function Header([string]$state) {
    $line = Get-Content (Join-Path $Out "$state-dump.txt") -Encoding utf8 -TotalCount 1
    if ($line -notmatch 'viewport=(\d+)x(\d+) maximized=(true|false)') { throw "No viewport in $state dump" }
    [pscustomobject]@{ w = [int]$matches[1]; h = [int]$matches[2]; maximized = ($matches[3] -eq 'true') }
}
function WaitDump {
    for ($i = 0; $i -lt 40; $i++) {
        if ((Test-Path (Join-Path $Out 'app-stdout.txt')) -and (Select-String -Path (Join-Path $Out 'app-stdout.txt') -Pattern '^\[dev\] layout-snapshot-end' -Quiet)) { return }
        Start-Sleep -Milliseconds 500
    }
    throw 'No layout dump from the app'
}
try {
    # Start via Start-Process with a file redirect: the app inherits the child's stdout, so a pipe would never reach EOF.
    New-Item -ItemType Directory -Force (Split-Path $Out -Parent) | Out-Null
    $starter = Start-Process pwsh -PassThru -NoNewWindow -ArgumentList @('-NoProfile','-File',(Join-Path $tools 'session.ps1'),'-Action','Start','-Json','-Out',$Out,'-Exe',$Exe) -RedirectStandardOutput (Join-Path $env:TEMP 'wbg-check-layout-start.log')
    if (-not $starter.WaitForExit(60000)) { throw 'session start did not finish' }
    Write-Host "started; waiting for first dump"; WaitDump; Write-Host "first dump seen"
    & pwsh -NoProfile -File (Join-Path $tools 'session.ps1') -Action Snapshot -State S1a -Out $Out *> $null
    $before = Header "S1a"; Write-Host "S1a snapshot ok"
    & pwsh -NoProfile -File (Join-Path $tools 'input.ps1') -Action Maximize -Out $Out *> $null
    Write-Host "maximize sent"; $after = $null
    for ($i = 0; $i -lt 20; $i++) {
        Start-Sleep -Milliseconds 500
        & pwsh -NoProfile -File (Join-Path $tools 'session.ps1') -Action Snapshot -State S1 -Out $Out *> $null
        $after = Header 'S1'
        if ($after.maximized) { break }
    }
    "path: first dump $($before.w)x$($before.h) maximized=$($before.maximized) -> $($after.w)x$($after.h) maximized=$($after.maximized)"
    if ($before.maximized) { Write-Host 'FAIL path: the first dump was already maximized; the small-then-maximize path was not exercised'; $failed = $true }
    if (-not $after.maximized) { Write-Host 'FAIL path: the window did not reach the maximized state'; $failed = $true }
    $args2 = @('-NoProfile', '-File', (Join-Path $tools 'compare.ps1'), '-Json', (Join-Path $Out 'layout.json'), '-Checks', (Join-Path $tools 'checks-layout.txt'))
    if ($Report) { $args2 += @('-Report', $Report) }
    & pwsh @args2
    if ($LASTEXITCODE -ne 0) { $failed = $true }
} finally {
    $sj = Join-Path $Out "session.json"; if (Test-Path $sj) { Stop-Process -Id (Get-Content -Raw $sj | ConvertFrom-Json).pid -ErrorAction SilentlyContinue }
    Start-Sleep -Seconds 2
    if (Test-Path (Join-Path $Out "session.json")) { & pwsh -NoProfile -File (Join-Path $tools "session.ps1") -Action Stop -Out $Out | Out-Null }
}
if ($failed) { Write-Host 'CHECK-LAYOUT: FAIL'; exit 1 }
Write-Host 'CHECK-LAYOUT: PASS'

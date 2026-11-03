#Requires -Version 7
# Phase 1 R-12 runner: copy of baseline/run-p0-0c.ps1 with output under verify/phase1 and r1-expected.tsv pre-copied for phase1.
$ErrorActionPreference = 'Stop'
Set-Location 'D:\projects\workbench-gpui'
$phase1 = 'D:\projects\workbench-gpui\specs\v0.3\verify\phase1'
$exe = 'D:\projects\workbench-gpui\target\debug\workbench-gpui.exe'
$appDir = Join-Path $env:APPDATA 'workbench-gpui'
$backup = Join-Path $phase1 '_backup'
if (Get-Process workbench-gpui -ErrorAction SilentlyContinue) { throw 'App already running; stop without changes' }
if (Test-Path -LiteralPath $backup) { throw 'Backup already exists; refusing to overwrite' }
New-Item -ItemType Directory -Path $backup -Force | Out-Null
$existed = Test-Path -LiteralPath $appDir
function Snapshot {
    $items = [ordered]@{}
    if (Test-Path -LiteralPath $appDir) {
        foreach ($file in (Get-ChildItem -LiteralPath $appDir -Recurse -File -Force | Sort-Object FullName)) {
            $items[$file.FullName.Substring($appDir.Length + 1)] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        }
    }
    $items
}
$before = Snapshot
if ($existed) { Copy-Item -LiteralPath $appDir -Destination (Join-Path $backup 'appdata') -Recurse -Force }
@{ existed = $existed; appDir = $appDir; files = $before; exeHash = (Get-FileHash $exe).Hash } | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $backup 'before.json') -Encoding utf8
$runs = @()
$names = @('verify-v02-phase1','verify-v02-phase2','verify-v02-phase3','verify-v02-phase4','verify-v02-phase4-d043','verify-v02-phase4-d043-clip','verify-v02-phase4-d044','verify-v02-phase5','verify-v02-phase5-d046','verify-v02-phase5-d047')
try {
    foreach ($name in $names) {
        if (Get-Process workbench-gpui -ErrorAction SilentlyContinue) { throw "App already running before $name; stop" }
        $out = Join-Path $phase1 $name
        New-Item -ItemType Directory -Path $out -Force | Out-Null
        if ($name -eq 'verify-v02-phase1') { Copy-Item -LiteralPath 'D:\projects\workbench-gpui\specs\v0.2\verify\phase1\r1-expected.tsv' -Destination $out -Force }
        if ($name -eq 'verify-v02-phase4-d043-clip') {
            $reason = 'SKIP: same as baseline (P0-0c); no Before script available.'
            $reason | Set-Content (Join-Path $out 'skip.txt') -Encoding utf8
            $runs += @{ name=$name; status='SKIP'; reason=$reason }
        } else {
            Write-Output "START $name"
            $started = (Get-Date).ToString('o')
            & pwsh -NoProfile -File "tools/$name.ps1" -Exe $exe -OutDir $out > (Join-Path $out 'console.log') 2>&1
            $runs += @{ name=$name; exit=$LASTEXITCODE; started=$started; ended=(Get-Date).ToString('o'); attempts=1 }
            Write-Output "END $name exit=$LASTEXITCODE"
        }
        $runs | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $phase1 'run-index.json') -Encoding utf8
    }
} finally {
    if (Get-Process workbench-gpui -ErrorAction SilentlyContinue) {
        'App remains running; do not restore files while app is active. Backup retained.' | Set-Content (Join-Path $backup 'RESTORE-BLOCKED.txt')
    } else {
        $afterScripts = Snapshot
        foreach ($file in (Get-ChildItem -LiteralPath $appDir -File -Force -ErrorAction SilentlyContinue)) {
            if (-not $before.Contains($file.Name) -and ($file.Name -eq 'keymap.json' -or $file.Name -like 'state.json*' -or $file.Name -eq 'keymap.json.tmp')) {
                if ($file.DirectoryName -ne $appDir) { throw 'Unexpected restore target' }
                Remove-Item -LiteralPath $file.FullName -Force
            }
        }
        if ($existed) {
            foreach ($item in (Get-ChildItem -LiteralPath (Join-Path $backup 'appdata') -Force)) { Copy-Item -LiteralPath $item.FullName -Destination $appDir -Recurse -Force }
        }
        $after = Snapshot
        @{ afterScripts=$afterScripts; after=$after; restored=(($before | ConvertTo-Json -Compress) -eq ($after | ConvertTo-Json -Compress)); exeHash=(Get-FileHash $exe).Hash } | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $backup 'after.json') -Encoding utf8
    }
}

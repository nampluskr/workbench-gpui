#Requires -Version 7
# shortcut: assumes primary monitor at 100% DPI (AGENTS 3A.4); box coordinates are used as screen pixels, add DPI/monitor offset handling if that changes.
param([ValidateSet('Start','Snapshot','Stop')][string]$Action, [string]$State, [switch]$Capture, [switch]$Json, [string]$Out = 'D:\projects\workbench-gpui\specs\v0.3\verify\reviews\p0-measure', [string]$Backup, [string]$Exe = 'D:projectsworkbench-gpui	argetdebugworkbench-gpui.exe')
$ErrorActionPreference = 'Stop'
# Backup defaults to a sibling of -Out (_<leaf>-backup) so Start and Stop agree; pass -Backup to reuse an older location.
if (-not $Backup) { $Backup = Join-Path (Split-Path $Out -Parent) ('_' + (Split-Path $Out -Leaf) + '-backup') }
Set-Location 'D:\projects\workbench-gpui'
$appDir = Join-Path $env:APPDATA 'workbench-gpui'
function Hashes([string]$Dir) {
    $result = [ordered]@{}
    if (Test-Path -LiteralPath $Dir) {
        foreach ($file in (Get-ChildItem -LiteralPath $Dir -Recurse -File -Force | Sort-Object FullName)) {
            $result[$file.FullName.Substring($Dir.Length + 1)] = (Get-FileHash -LiteralPath $file.FullName).Hash
        }
    }
    return $result
}
if ($Action -eq 'Start') {
    if (Get-Process workbench-gpui -ErrorAction SilentlyContinue) { throw 'App already running' }
    if (Test-Path $Backup) { throw 'Existing backup; do not overwrite' }
    New-Item -ItemType Directory -Path $Backup,$Out -Force | Out-Null
    $before = Hashes $appDir
    $existed = Test-Path $appDir
    if ($existed) { Copy-Item -LiteralPath $appDir -Destination (Join-Path $Backup 'appdata') -Recurse -Force }
    @{appDir=$appDir; existed=$existed; files=$before} | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $Backup 'before.json') -Encoding utf8
    New-Item -ItemType Directory -Path $appDir -Force | Out-Null
    foreach ($file in (Get-ChildItem -LiteralPath $appDir -File)) {
        if ($file.Name -eq 'keymap.json' -or $file.Name -like 'state.json*') { Remove-Item -LiteralPath $file.FullName -Force }
    }
    $fixture = Join-Path (Get-Location) ('target\measure-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path (Join-Path $fixture 'branch\nested') -Force | Out-Null
    'measure' | Set-Content (Join-Path $fixture '.measure-marker')
    foreach ($i in 1..80) { 'Measurement fixture' | Set-Content (Join-Path $fixture ('file-{0:D3}.txt' -f $i)) }
    'Nested fixture' | Set-Content (Join-Path $fixture 'branch\nested\nested.txt')
    $pick = Join-Path $Out 'pick.txt'
    $fixture | Set-Content $pick -Encoding utf8
    $exe = $Exe
    $process = Start-Process -FilePath $exe -ArgumentList (@('--dev-layout','--dev-keymap','--dev-pick-folder',$pick) + $(if ($Json) { @('--dev-layout-json', (Join-Path $Out 'layout.json')) } else { @() })) -PassThru -RedirectStandardOutput (Join-Path $Out 'app-stdout.txt') -RedirectStandardError (Join-Path $Out 'app-stderr.txt')
    @{pid=$process.Id; exe=$exe; fixture=$fixture; exeHash=(Get-FileHash $exe).Hash; started=(Get-Date).ToString('o')} | ConvertTo-Json | Set-Content (Join-Path $Out 'session.json') -Encoding utf8
    Get-Content (Join-Path $Out 'session.json')
} elseif ($Action -eq 'Snapshot') {
    if ($State -notmatch '^S[1-7][a-z]?$') { throw 'Unknown state' }
    $lines = @(Get-Content (Join-Path $Out 'app-stdout.txt') -Encoding utf8)
    $end = -1
    for ($i=$lines.Count-1; $i -ge 0; $i--) { if ($lines[$i] -match '^\[dev\] layout-snapshot-end seq=(\d+)') { $end=$i; $seq=$matches[1]; break } }
    if ($end -lt 0) { throw 'No completed layout snapshot' }
    $start=$end
    while ($start -ge 0 -and $lines[$start] -notmatch "^\[dev\] layout-snapshot seq=$seq ") { $start-- }
    if ($start -lt 0) { throw 'Snapshot start not found' }
    $boxes = [ordered]@{}
    foreach ($line in $lines[$start..$end]) {
        if ($line -match 'name=(\S+) bounds=([-\d.]+),([-\d.]+),([-\d.]+),([-\d.]+)') {
            $boxes[$matches[1]]=@{x=[double]$matches[2];y=[double]$matches[3];w=[double]$matches[4];h=[double]$matches[5]}
        }
    }
    @{state=$State; seq=[int]$seq; sourceStartLine=$start+1; sourceEndLine=$end+1; header=$lines[$start];boxes=$boxes} | ConvertTo-Json -Depth 7 | Set-Content (Join-Path $Out "$State.json") -Encoding utf8
    $lines[$start..$end] | Set-Content (Join-Path $Out "$State-dump.txt") -Encoding utf8
    if ($Capture) {
        $session=Get-Content -Raw (Join-Path $Out 'session.json') | ConvertFrom-Json
        $process=Get-Process -Id $session.pid
        & pwsh -NoProfile -File tools/capture.ps1 -Hwnd $process.MainWindowHandle -Out (Join-Path $Out "$State.png") -Method PrintWindow | Set-Content (Join-Path $Out "$State-capture.json") -Encoding utf8
        if ($LASTEXITCODE -ne 0) { throw 'Capture failed' }
    }
    $lines[$start..$end]
} else {
    $session=Get-Content -Raw (Join-Path $Out 'session.json') | ConvertFrom-Json
    if (Get-Process workbench-gpui -ErrorAction SilentlyContinue) { throw 'Close the measurement app before restoring' }
    $before=Get-Content -Raw (Join-Path $Backup 'before.json') | ConvertFrom-Json -AsHashtable
    if (-not $before.existed) {
        # The app data folder did not exist before the session; remove what the app created.
        if ((Split-Path $appDir -Leaf) -ne 'workbench-gpui' -or -not $appDir.StartsWith($env:APPDATA)) { throw 'App data path guard failed' }
        if (Test-Path -LiteralPath $appDir) { Remove-Item -LiteralPath $appDir -Recurse -Force }
    } else {
        foreach ($file in (Get-ChildItem -LiteralPath $appDir -File -Force)) {
            if (-not $before.files.Contains($file.Name) -and ($file.Name -eq 'keymap.json' -or $file.Name -like 'state.json*')) { Remove-Item -LiteralPath $file.FullName -Force }
        }
        foreach ($item in (Get-ChildItem -LiteralPath (Join-Path $Backup 'appdata') -Force)) { Copy-Item -LiteralPath $item.FullName -Destination $appDir -Recurse -Force }
    }
    $after=Hashes $appDir
    $fixture=[IO.Path]::GetFullPath($session.fixture)
    if (-not $fixture.StartsWith('D:\projects\workbench-gpui\target\measure-') -or (Get-Content (Join-Path $fixture '.measure-marker')) -ne 'measure') { throw 'Fixture cleanup guard failed' }
    Remove-Item -LiteralPath $fixture -Recurse -Force
    $result=@{files=$after; restored=(($before.files | ConvertTo-Json -Compress) -eq ($after | ConvertTo-Json -Compress)); fixtureRemoved=(-not (Test-Path $fixture)); exeUnchanged=((Get-FileHash $(if ($session.exe) { $session.exe } else { 'D:\projects\workbench-gpui\target\debug\workbench-gpui.exe' })).Hash -eq $session.exeHash)}
    $result | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $Backup 'after.json') -Encoding utf8
    if (-not $result.restored) { throw 'User data hash mismatch' }
    $result | ConvertTo-Json
}

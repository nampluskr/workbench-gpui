#Requires -Version 7
param([ValidateSet('Start','Snapshot','Stop')][string]$Action, [string]$State, [switch]$Capture)
$ErrorActionPreference = 'Stop'
Set-Location 'D:\projects\workbench-gpui'
$out = 'D:\projects\workbench-gpui\specs\v0.3\verify\reviews\p0-measure'
$backup = 'D:\projects\workbench-gpui\specs\v0.3\verify\reviews\_p0-6-backup'
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
    if (Test-Path $backup) { throw 'Existing backup; do not overwrite' }
    New-Item -ItemType Directory -Path $backup,$out -Force | Out-Null
    $before = Hashes $appDir
    $existed = Test-Path $appDir
    if ($existed) { Copy-Item -LiteralPath $appDir -Destination (Join-Path $backup 'appdata') -Recurse -Force }
    @{appDir=$appDir; existed=$existed; files=$before} | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $backup 'before.json') -Encoding utf8
    New-Item -ItemType Directory -Path $appDir -Force | Out-Null
    foreach ($file in (Get-ChildItem -LiteralPath $appDir -File)) {
        if ($file.Name -eq 'keymap.json' -or $file.Name -like 'state.json*') { Remove-Item -LiteralPath $file.FullName -Force }
    }
    $fixture = Join-Path (Get-Location) ('target\p0-measure-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path (Join-Path $fixture 'branch\nested') -Force | Out-Null
    'P0-6' | Set-Content (Join-Path $fixture '.p0-measure-marker')
    foreach ($i in 1..80) { 'Measurement fixture' | Set-Content (Join-Path $fixture ('file-{0:D3}.txt' -f $i)) }
    'Nested fixture' | Set-Content (Join-Path $fixture 'branch\nested\nested.txt')
    $pick = Join-Path $out 'pick.txt'
    $fixture | Set-Content $pick -Encoding utf8
    $exe = 'D:\projects\workbench-gpui\target\debug\workbench-gpui.exe'
    $process = Start-Process -FilePath $exe -ArgumentList @('--dev-layout','--dev-keymap','--dev-pick-folder',$pick) -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $out 'app-stdout.txt') -RedirectStandardError (Join-Path $out 'app-stderr.txt')
    @{pid=$process.Id; fixture=$fixture; exeHash=(Get-FileHash $exe).Hash; started=(Get-Date).ToString('o')} | ConvertTo-Json | Set-Content (Join-Path $out 'session.json') -Encoding utf8
    Get-Content (Join-Path $out 'session.json')
} elseif ($Action -eq 'Snapshot') {
    if ($State -notmatch '^S[1-7][a-z]?$') { throw 'Unknown state' }
    $lines = @(Get-Content (Join-Path $out 'app-stdout.txt') -Encoding utf8)
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
    @{state=$State; seq=[int]$seq; sourceStartLine=$start+1; sourceEndLine=$end+1; header=$lines[$start];boxes=$boxes} | ConvertTo-Json -Depth 7 | Set-Content (Join-Path $out "$State.json") -Encoding utf8
    $lines[$start..$end] | Set-Content (Join-Path $out "$State-dump.txt") -Encoding utf8
    if ($Capture) {
        $session=Get-Content -Raw (Join-Path $out 'session.json') | ConvertFrom-Json
        $process=Get-Process -Id $session.pid
        & pwsh -NoProfile -File tools/capture.ps1 -Hwnd $process.MainWindowHandle -Out (Join-Path $out "$State.png") -Method PrintWindow | Set-Content (Join-Path $out "$State-capture.json") -Encoding utf8
        if ($LASTEXITCODE -ne 0) { throw 'Capture failed' }
    }
    $lines[$start..$end]
} else {
    $session=Get-Content -Raw (Join-Path $out 'session.json') | ConvertFrom-Json
    if (Get-Process workbench-gpui -ErrorAction SilentlyContinue) { throw 'Close the measurement app before restoring' }
    $before=Get-Content -Raw (Join-Path $backup 'before.json') | ConvertFrom-Json -AsHashtable
    foreach ($file in (Get-ChildItem -LiteralPath $appDir -File -Force)) {
        if (-not $before.files.Contains($file.Name) -and ($file.Name -eq 'keymap.json' -or $file.Name -like 'state.json*')) { Remove-Item -LiteralPath $file.FullName -Force }
    }
    if ($before.existed) {
        foreach ($item in (Get-ChildItem -LiteralPath (Join-Path $backup 'appdata') -Force)) { Copy-Item -LiteralPath $item.FullName -Destination $appDir -Recurse -Force }
    }
    $after=Hashes $appDir
    $fixture=[IO.Path]::GetFullPath($session.fixture)
    if (-not $fixture.StartsWith('D:\projects\workbench-gpui\target\p0-measure-') -or (Get-Content (Join-Path $fixture '.p0-measure-marker')) -ne 'P0-6') { throw 'Fixture cleanup guard failed' }
    Remove-Item -LiteralPath $fixture -Recurse -Force
    $result=@{files=$after; restored=(($before.files | ConvertTo-Json -Compress) -eq ($after | ConvertTo-Json -Compress)); fixtureRemoved=(-not (Test-Path $fixture)); exeUnchanged=((Get-FileHash 'D:\projects\workbench-gpui\target\debug\workbench-gpui.exe').Hash -eq $session.exeHash)}
    $result | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $backup 'after.json') -Encoding utf8
    if (-not $result.restored) { throw 'User data hash mismatch' }
    $result | ConvertTo-Json
}

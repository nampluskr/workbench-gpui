#Requires -Version 7
# shortcut: assumes primary monitor at 100% DPI (AGENTS 3A.4); box coordinates are used as screen pixels, add DPI/monitor offset handling if that changes.
param(
    [ValidateSet('Start','Snapshot','Stop')][string]$Action,
    [string]$State,
    [switch]$Capture,
    [switch]$Json,
    [string]$Out = 'D:\projects\workbench-gpui\specs\v0.3\verify\reviews\p0-measure',
    [string]$Backup,
    [string]$Exe = 'D:\projects\workbench-gpui\target\debug\workbench-gpui.exe',
    [string]$FixtureFile,
    [switch]$CleanBackup
)
$ErrorActionPreference = 'Stop'

# Backup defaults to a sibling of -Out (_<leaf>-backup) so Start and Stop agree; pass -Backup to reuse an older location.
if (-not $Backup) {
    $Backup = Join-Path (Split-Path $Out -Parent) ('_' + (Split-Path $Out -Leaf) + '-backup')
}
Set-Location 'D:\projects\workbench-gpui'
$appDir = Join-Path $env:APPDATA 'workbench-gpui'

function Hashes([string]$Dir) {
    $result = [ordered]@{}
    if (Test-Path -LiteralPath $Dir) {
        foreach ($file in (Get-ChildItem -LiteralPath $Dir -Recurse -File -Force | Sort-Object FullName)) {
            $relPath = $file.FullName.Substring($Dir.Length + 1)
            $result[$relPath] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        }
    }
    return $result
}

function Test-FilesIdentical([string]$PathA, [string]$PathB) {
    if (-not (Test-Path -LiteralPath $PathA) -or -not (Test-Path -LiteralPath $PathB)) { return $false }
    $infoA = Get-Item -LiteralPath $PathA
    $infoB = Get-Item -LiteralPath $PathB
    if ($infoA.Length -ne $infoB.Length) { return $false }
    $hashA = (Get-FileHash -LiteralPath $PathA -Algorithm SHA256).Hash
    $hashB = (Get-FileHash -LiteralPath $PathB -Algorithm SHA256).Hash
    return ($hashA -eq $hashB)
}

function Remove-BackupSafely([string]$BackupDir, [string]$TargetAppDir, [hashtable]$BeforeFiles, [bool]$ExistedBefore) {
    if (-not $BackupDir -or -not (Test-Path -LiteralPath $BackupDir)) { return }

    # Guard: Ensure backup path is within safe bounds (sibling of measure output, contains '-backup' or '_backup')
    $fullBackup = [System.IO.Path]::GetFullPath($BackupDir)
    if (-not ($fullBackup.Contains('-backup') -or $fullBackup.Contains('_backup'))) {
        throw "Backup cleanup guard failed: path '$fullBackup' does not look like a measurement backup directory"
    }

    # Verify byte-for-byte and hash equality before allowing deletion
    if (-not $ExistedBefore) {
        if (Test-Path -LiteralPath $TargetAppDir) {
            throw "Backup cleanup guard failed: AppData directory still exists when it was absent before session"
        }
    } else {
        if (-not (Test-Path -LiteralPath $TargetAppDir)) {
            throw "Backup cleanup guard failed: AppData directory missing after restore"
        }
        $backupAppDir = Join-Path $BackupDir 'appdata'
        $currentHashes = Hashes $TargetAppDir

        # 1. Key count check
        if ($currentHashes.Count -ne $BeforeFiles.Count) {
            throw "Backup cleanup guard failed: File count mismatch (restored: $($currentHashes.Count), before: $($BeforeFiles.Count))"
        }

        # 2. Key and hash check against $BeforeFiles
        foreach ($rel in $BeforeFiles.Keys) {
            if (-not $currentHashes.Contains($rel)) {
                throw "Backup cleanup guard failed: Missing file '$rel' in restored AppData"
            }
            if ($currentHashes[$rel] -ne $BeforeFiles[$rel]) {
                throw "Backup cleanup guard failed: Hash mismatch for file '$rel'"
            }

            # 3. Byte-level identity check against the backup copy
            $srcFile = Join-Path $backupAppDir $rel
            $dstFile = Join-Path $TargetAppDir $rel
            if (-not (Test-FilesIdentical $srcFile $dstFile)) {
                throw "Backup cleanup guard failed: Byte-level comparison failed for '$rel'"
            }
        }
    }

    # If and only if all checks pass, delete the backup directory
    Remove-Item -LiteralPath $fullBackup -Recurse -Force
}

if ($Action -eq 'Start') {
    # 1. workbench-gpui 프로세스가 하나라도 떠 있으면 백업·초기화를 시작하지 않고 오류로 끝낸다 (사용자 데이터 손대지 않음)
    $running = @(Get-Process -Name 'workbench-gpui' -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) {
        throw "workbench-gpui process is already running (PID=$($running[0].Id)). Cannot start measurement session; user data must not be touched."
    }

    if (Test-Path -LiteralPath $Backup) {
        throw "Existing backup directory '$Backup'; do not overwrite existing backup"
    }

    # Create Backup and Out directories
    New-Item -ItemType Directory -Path $Backup, $Out -Force | Out-Null

    $before = Hashes $appDir
    $existed = Test-Path -LiteralPath $appDir

    # 2. 백업 수행 및 해시 검증 (settings.json, keymap.json 등 AppData 전체 파일 보존)
    $backupAppDir = Join-Path $Backup 'appdata'
    if ($existed) {
        Copy-Item -LiteralPath $appDir -Destination $backupAppDir -Recurse -Force
        $backupHashes = Hashes $backupAppDir
        if ($backupHashes.Count -ne $before.Count) {
            throw "Backup verification failed: file count mismatch ($($backupHashes.Count) vs $($before.Count))"
        }
        foreach ($k in $before.Keys) {
            if (-not $backupHashes.Contains($k) -or $backupHashes[$k] -ne $before[$k]) {
                throw "Backup verification failed: file '$k' hash mismatch in backup"
            }
            $origF = Join-Path $appDir $k
            $backF = Join-Path $backupAppDir $k
            if (-not (Test-FilesIdentical $origF $backF)) {
                throw "Backup verification failed: byte mismatch for '$k'"
            }
        }
    }

    # Record before.json
    @{
        appDir = $appDir
        existed = $existed
        files = $before
        backupTime = (Get-Date).ToString('o')
    } | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $Backup 'before.json') -Encoding utf8

    # 트랜잭션 롤백 블록: 백업 이후 초기화 또는 앱 기동 실패 시 원래 데이터로 100% 복원
    $fixture = $null
    $process = $null
    try {
        # 초기화: settings.json, keymap.json, state.json* 제거하여 깨끗한 상태에서 세션 시작
        New-Item -ItemType Directory -Path $appDir -Force | Out-Null
        foreach ($file in (Get-ChildItem -LiteralPath $appDir -File -Force)) {
            if ($file.Name -eq 'keymap.json' -or $file.Name -eq 'settings.json' -or $file.Name -like 'state.json*') {
                Remove-Item -LiteralPath $file.FullName -Force
            }
        }

        # Fixture 준비
        $fixture = Join-Path (Get-Location) ('target\measure-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $fixture 'branch\nested') -Force | Out-Null
        'measure' | Set-Content (Join-Path $fixture '.measure-marker')
        foreach ($i in 1..80) { 'Measurement fixture' | Set-Content (Join-Path $fixture ('file-{0:D3}.txt' -f $i)) }
        'Nested fixture' | Set-Content (Join-Path $fixture 'branch\nested\nested.txt')
        if ($FixtureFile -and (Test-Path -LiteralPath $FixtureFile)) {
            Copy-Item -LiteralPath $FixtureFile -Destination (Join-Path $fixture '00-order03.md') -Force
        }

        $pick = Join-Path $Out 'pick.txt'
        $fixture | Set-Content $pick -Encoding utf8

        # 앱 기동
        $exe = $Exe
        if (-not (Test-Path -LiteralPath $exe)) {
            throw "Executable not found at '$exe'"
        }
        $argList = @('--dev-layout', '--dev-keymap', '--dev-pick-folder', $pick)
        if ($Json) {
            $argList += @('--dev-layout-json', (Join-Path $Out 'layout.json'))
        }
        $process = Start-Process -FilePath $exe -ArgumentList $argList -PassThru `
            -RedirectStandardOutput (Join-Path $Out 'app-stdout.txt') `
            -RedirectStandardError (Join-Path $Out 'app-stderr.txt')

        # 기동 확인: 프로세스가 바로 비정상 종료되지 않았는지 확인
        Start-Sleep -Milliseconds 400
        if ($process.HasExited) {
            throw "workbench-gpui exited immediately after launch with exit code $($process.ExitCode)"
        }

        @{
            pid = $process.Id
            exe = $exe
            fixture = $fixture
            exeHash = (Get-FileHash $exe).Hash
            started = (Get-Date).ToString('o')
        } | ConvertTo-Json | Set-Content (Join-Path $Out 'session.json') -Encoding utf8

        Get-Content (Join-Path $Out 'session.json')
    } catch {
        # 실패 시 롤백! 사용자 데이터 즉시 원래 상태로 복원
        $initError = $_.Exception.Message
        if ($process -and -not $process.HasExited) {
            try { Stop-Process -Id $process.Id -Force } catch {}
        }
        if ($fixture -and (Test-Path -LiteralPath $fixture)) {
            try { Remove-Item -LiteralPath $fixture -Recurse -Force } catch {}
        }
        # AppData 복원
        if (-not $existed) {
            if (Test-Path -LiteralPath $appDir) {
                try { Remove-Item -LiteralPath $appDir -Recurse -Force } catch {}
            }
        } else {
            # 세션 시도 중 새로 생성된 파일 삭제
            foreach ($file in (Get-ChildItem -LiteralPath $appDir -Recurse -File -Force)) {
                $rel = $file.FullName.Substring($appDir.Length + 1)
                if (-not $before.Contains($rel)) {
                    try { Remove-Item -LiteralPath $file.FullName -Force } catch {}
                }
            }
            # 백업에서 원복
            if (Test-Path -LiteralPath $backupAppDir) {
                foreach ($item in (Get-ChildItem -LiteralPath $backupAppDir -Force)) {
                    try { Copy-Item -LiteralPath $item.FullName -Destination $appDir -Recurse -Force } catch {}
                }
            }
        }
        throw "Failed to start measurement session: $initError. AppData was rolled back to original state."
    }
} elseif ($Action -eq 'Snapshot') {
    if ($State -notmatch '^S[1-7][a-z]?$') { throw 'Unknown state' }
    $lines = @(Get-Content (Join-Path $Out 'app-stdout.txt') -Encoding utf8)
    $end = -1
    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        if ($lines[$i] -match '^\[dev\] layout-snapshot-end seq=(\d+)') {
            $end = $i
            $seq = $matches[1]
            break
        }
    }
    if ($end -lt 0) { throw 'No completed layout snapshot' }
    $start = $end
    while ($start -ge 0 -and $lines[$start] -notmatch "^\[dev\] layout-snapshot seq=$seq ") { $start-- }
    if ($start -lt 0) { throw 'Snapshot start not found' }
    $boxes = [ordered]@{}
    foreach ($line in $lines[$start..$end]) {
        if ($line -match 'name=(\S+) bounds=([-\d.]+),([-\d.]+),([-\d.]+),([-\d.]+)') {
            $boxes[$matches[1]] = @{ x = [double]$matches[2]; y = [double]$matches[3]; w = [double]$matches[4]; h = [double]$matches[5] }
        }
    }
    @{ state = $State; seq = [int]$seq; sourceStartLine = $start + 1; sourceEndLine = $end + 1; header = $lines[$start]; boxes = $boxes } | ConvertTo-Json -Depth 7 | Set-Content (Join-Path $Out "$State.json") -Encoding utf8
    $lines[$start..$end] | Set-Content (Join-Path $Out "$State-dump.txt") -Encoding utf8
    if ($Capture) {
        $session = Get-Content -Raw (Join-Path $Out 'session.json') | ConvertFrom-Json
        $process = Get-Process -Id $session.pid
        & pwsh -NoProfile -File tools/capture.ps1 -Hwnd $process.MainWindowHandle -Out (Join-Path $Out "$State.png") -Method PrintWindow | Set-Content (Join-Path $Out "$State-capture.json") -Encoding utf8
        if ($LASTEXITCODE -ne 0) { throw 'Capture failed' }
    }
    $lines[$start..$end]
} else { # Action -eq 'Stop'
    $sessionFile = Join-Path $Out 'session.json'
    if (-not (Test-Path -LiteralPath $sessionFile)) {
        throw "session.json not found at '$sessionFile'"
    }
    $session = Get-Content -Raw $sessionFile | ConvertFrom-Json

    # 1. 앱이 떠 있으면 복원하지 않고 오류
    $running = @(Get-Process -Name 'workbench-gpui' -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) {
        throw "workbench-gpui process is still running (PID=$($running[0].Id)). Close the measurement app before restoring."
    }
    if (Get-Process -Id $session.pid -ErrorAction SilentlyContinue) {
        throw "Measurement app PID $($session.pid) is still running. Close the app before restoring."
    }

    $beforeJsonPath = Join-Path $Backup 'before.json'
    if (-not (Test-Path -LiteralPath $beforeJsonPath)) {
        throw "Backup before.json not found at '$beforeJsonPath'"
    }
    $before = Get-Content -Raw $beforeJsonPath | ConvertFrom-Json -AsHashtable

    # 2. 복원 수행
    if (-not $before.existed) {
        # The app data folder did not exist before the session; remove what the app created.
        if ((Split-Path $appDir -Leaf) -ne 'workbench-gpui' -or -not $appDir.StartsWith($env:APPDATA)) {
            throw 'App data path guard failed'
        }
        if (Test-Path -LiteralPath $appDir) {
            Remove-Item -LiteralPath $appDir -Recurse -Force
        }
    } else {
        # settings.json, keymap.json, state.json* 등 세션 중 생성된 파일 중 $before에 없던 파일 정리
        foreach ($file in (Get-ChildItem -LiteralPath $appDir -Recurse -File -Force)) {
            $rel = $file.FullName.Substring($appDir.Length + 1)
            if (-not $before.files.Contains($rel) -and ($file.Name -eq 'keymap.json' -or $file.Name -eq 'settings.json' -or $file.Name -like 'state.json*')) {
                Remove-Item -LiteralPath $file.FullName -Force
            }
        }
        # 백업에서 원복
        $backupAppDir = Join-Path $Backup 'appdata'
        foreach ($item in (Get-ChildItem -LiteralPath $backupAppDir -Force)) {
            Copy-Item -LiteralPath $item.FullName -Destination $appDir -Recurse -Force
        }
    }

    # 3. 복원 뒤 원본 해시와 바이트 동일 확인
    $after = Hashes $appDir
    $restored = $false
    if (-not $before.existed) {
        $restored = (-not (Test-Path -LiteralPath $appDir))
    } else {
        if ($after.Count -eq $before.files.Count) {
            $matched = $true
            $backupAppDir = Join-Path $Backup 'appdata'
            foreach ($rel in $before.files.Keys) {
                if (-not $after.Contains($rel) -or $after[$rel] -ne $before.files[$rel]) {
                    $matched = $false
                    break
                }
                $srcFile = Join-Path $backupAppDir $rel
                $dstFile = Join-Path $appDir $rel
                if (-not (Test-FilesIdentical $srcFile $dstFile)) {
                    $matched = $false
                    break
                }
            }
            $restored = $matched
        }
    }

    if (-not $restored) {
        throw "User data hash/byte mismatch after restore! Backup is preserved at '$Backup' for manual inspection."
    }

    # 4. 픽스처 정리
    $fixture = [System.IO.Path]::GetFullPath($session.fixture)
    if (-not $fixture.StartsWith('D:\projects\workbench-gpui\target\measure-') -or (Get-Content (Join-Path $fixture '.measure-marker')) -ne 'measure') {
        throw 'Fixture cleanup guard failed'
    }
    Remove-Item -LiteralPath $fixture -Recurse -Force

    $exePath = if ($session.exe) { $session.exe } else { 'D:\projects\workbench-gpui\target\debug\workbench-gpui.exe' }
    $exeUnchanged = ((Get-FileHash $exePath).Hash -eq $session.exeHash)

    $result = @{
        files = $after
        restored = $restored
        fixtureRemoved = (-not (Test-Path -LiteralPath $fixture))
        exeUnchanged = $exeUnchanged
    }
    $result | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $Backup 'after.json') -Encoding utf8

    # 원본 해시와 바이트 동일 확인이 완료되었으므로 안전 정리 함수 제공:
    # -CleanBackup 스위치가 주어진 경우에만 안전 함수를 통해 백업 폴더 정리 (그 외 어디서도 자동 삭제 안 함)
    if ($CleanBackup) {
        Remove-BackupSafely -BackupDir $Backup -TargetAppDir $appDir -BeforeFiles $before.files -ExistedBefore $before.existed
    }

    $result | ConvertTo-Json
}

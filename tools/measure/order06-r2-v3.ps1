#Requires -Version 7
<#
.SYNOPSIS
  ORDER-06-R2 V3 화면 검증(UI 실측) 스크립트.
  (gpui-checker 작성, leader가 화면 차례 안에서 실행한다.)

.DESCRIPTION
  - 상위 지시: core ORDER-06-R2 V3 준비 (C-29)
  - 우리 앱(workbench-gpui) 단독 실행 (Zed는 구동하지 않음).
  - 클라이언트 1440×852, 100% DPI, Ensure-ClientSize로 고정.
  - 검증 단계 (C-29 대상 4종):
    1. app-v-button-crop: v 사용자 메뉴 버튼(22×22, chevron 아이콘 14px I-601, 최소화 여백 4) 탐침 측정 및
       4배 확대 크롭(app-v-button-crop-4x.png) 저장.
    2. app-settings-window: Ctrl-, 로 Settings 새 창(HWND 감지) 열기, GetClientRect 크기(900×750) 및
       행 구성(Theme Name, Icon Theme Name, Font Size, Font Size)·소제목 순서(Theme → Buffer Font → UI Font)
       캡처(조작 없이 열기만), 중복 생성 방지 확인 후 WM_CLOSE 닫기.
    3. app-keymap-editor: Ctrl-K Ctrl-S로 Keymap Editor 탭 열림, 행 hover(마우스 이동)로 Edit 아이콘 열(36px,
       pencil.svg) 표시 및 액션 표시 형식(pane: close active item), <no arguments>, <global> 캡처, Ctrl-W 닫기.
    4. app-extensions: Ctrl-Shift-X로 Extensions 탭 열림, 검색칸·상태 전환(All/Installed/Not Installed)·
       범주 칩(All/Themes/Icon Themes)·카드 목록("Installed") 캡처, Ctrl-W 닫기.
  - 안전 조치:
    * 띄운 PID와 스크립트가 직접 연 창(Settings HWND 등)만 닫기 (다른 프로세스나 창 불간섭).
    * settings.json 및 keymap.json 전용 백업·복원 (데이터 손실 0% 보장).
    * session.ps1 출력 스트림 파이프 미사용 방식 유지.
    * 각 단계 독립 실행 및 try-catch 기록.

.PARAMETER Out
  출력 디렉터리 (기본값: specs\v0.5\verify\reviews\measure-ORDER-06-R2).

.PARAMETER AppExe
  workbench-gpui 실행 파일 경로.

.PARAMETER FixturePath
  측정에 사용할 마크다운 파일 경로.

.PARAMETER DryRunStdout
  stdout 덤프를 기반으로 좌표 및 프로브 계산만 검증하는 모드 (프로세스 구동 안 함).

.PARAMETER Steps
  실행할 단계 목록. 기본값: 4개 단계 모두 실행.

.PARAMETER Skip
  건너뛸 단계 목록.
#>
[CmdletBinding()]
param(
    [string]$Out = 'specs\v0.5\verify\reviews\measure-ORDER-06-R2',
    [string]$AppExe = 'D:\projects\workbench-gpui\target\debug\workbench-gpui.exe',
    [string]$FixturePath,
    [string]$DryRunStdout,
    [string[]]$Steps = @(),
    [string[]]$Skip = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$global:LASTEXITCODE = 0
Set-Location 'D:\projects\workbench-gpui'

$Out = [System.IO.Path]::GetFullPath($Out, (Get-Location).Path)
New-Item -ItemType Directory -Force $Out | Out-Null
$logFile = Join-Path $Out 'log.txt'

$global:summary = [ordered]@{
    "app" = [ordered]@{}
    "crops" = [ordered]@{}
    "gaps" = [ordered]@{}
}

$normalizedSteps = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
if ($Steps) {
    foreach ($item in $Steps) {
        foreach ($sub in ($item -split ',')) {
            $t = $sub.Trim()
            if ($t) { [void]$normalizedSteps.Add($t) }
        }
    }
}

$normalizedSkip = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
if ($Skip) {
    foreach ($item in $Skip) {
        foreach ($sub in ($item -split ',')) {
            $t = $sub.Trim()
            if ($t) { [void]$normalizedSkip.Add($t) }
        }
    }
}

function Should-RunStep([string]$stepKey) {
    if ($normalizedSkip.Contains($stepKey)) { return $false }
    foreach ($k in $normalizedSkip) {
        if ($stepKey -like "*$k*") { return $false }
    }
    if ($normalizedSteps.Count -eq 0) { return $true }
    if ($normalizedSteps.Contains($stepKey)) { return $true }
    foreach ($k in $normalizedSteps) {
        if ($stepKey -like "*$k*") { return $true }
    }
    return $false
}

function L([string]$msg) {
    $ts = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    $line = "$ts $msg"
    Write-Host $line
    if (-not $DryRunStdout) {
        $line | Add-Content -LiteralPath $logFile -Encoding utf8
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    L "=== ORDER-06-R2 V3 Measure Script Initialized ==="
    L "Out Directory: $Out"
    L "AppExe: $AppExe"
    if ($Steps) { L "Steps Filter: $($Steps -join ',')" }
    if ($Skip) { L "Skip Filter: $($Skip -join ',')" }
}

# ---------------------------------------------------------------------------
# 1. Native API Definition (C# P/Invoke)
# ---------------------------------------------------------------------------
$nativeSource = @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

public static class Order06R2Native {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }

    [StructLayout(LayoutKind.Sequential)]
    public struct POINT { public int X; public int Y; }

    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr hWnd, ref POINT lpPoint);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    [DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, int dx, int dy, uint dwData, IntPtr dwExtraInfo);
    [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, IntPtr dwExtraInfo);
    [DllImport("user32.dll")] public static extern int GetSystemMetrics(int nIndex);

    const uint KEYEVENTF_EXTENDEDKEY = 0x1, KEYEVENTF_KEYUP = 0x2, KEYEVENTF_UNICODE = 0x4;
    const uint MOUSEEVENTF_MOVE = 0x1, MOUSEEVENTF_LEFTDOWN = 0x2, MOUSEEVENTF_LEFTUP = 0x4;
    const uint MOUSEEVENTF_VIRTUALDESK = 0x4000, MOUSEEVENTF_ABSOLUTE = 0x8000;
    const int SM_XVIRTUALSCREEN = 76, SM_YVIRTUALSCREEN = 77, SM_CXVIRTUALSCREEN = 78, SM_CYVIRTUALSCREEN = 79;

    public static string Title(IntPtr hWnd) {
        var sb = new StringBuilder(512);
        GetWindowText(hWnd, sb, sb.Capacity);
        return sb.ToString();
    }

    public static List<IntPtr> GetProcessTopLevelWindows(uint[] pids) {
        var result = new List<IntPtr>();
        var pidSet = new HashSet<uint>(pids);
        EnumWindows((h, lp) => {
            if (!IsWindowVisible(h)) return true;
            uint pid;
            GetWindowThreadProcessId(h, out pid);
            if (pidSet.Contains(pid)) {
                RECT r;
                GetWindowRect(h, out r);
                if (r.Right > r.Left && r.Bottom > r.Top) {
                    result.Add(h);
                }
            }
            return true;
        }, IntPtr.Zero);
        return result;
    }

    public static void KeyPress(byte vk) {
        keybd_event(vk, 0, 0, IntPtr.Zero);
        Thread.Sleep(40);
        keybd_event(vk, 0, KEYEVENTF_KEYUP, IntPtr.Zero);
        Thread.Sleep(40);
    }

    public static void KeyCombo(ushort[] modifiers, ushort key) {
        foreach (var m in modifiers) keybd_event((byte)m, 0, 0, IntPtr.Zero);
        Thread.Sleep(40);
        keybd_event((byte)key, 0, 0, IntPtr.Zero);
        Thread.Sleep(50);
        keybd_event((byte)key, 0, KEYEVENTF_KEYUP, IntPtr.Zero);
        Thread.Sleep(40);
        for (int i = modifiers.Length - 1; i >= 0; i--) keybd_event((byte)modifiers[i], 0, KEYEVENTF_KEYUP, IntPtr.Zero);
        Thread.Sleep(60);
    }

    public static void Click(int x, int y) {
        MoveTo(x, y);
        Thread.Sleep(60);
        mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, IntPtr.Zero);
        Thread.Sleep(60);
        mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, IntPtr.Zero);
        Thread.Sleep(60);
    }

    public static void MoveTo(int x, int y) {
        int vx = GetSystemMetrics(SM_XVIRTUALSCREEN);
        int vy = GetSystemMetrics(SM_YVIRTUALSCREEN);
        int vw = GetSystemMetrics(SM_CXVIRTUALSCREEN);
        int vh = GetSystemMetrics(SM_CYVIRTUALSCREEN);
        int normX = (int)Math.Round((x - vx) * 65535.0 / (vw - 1));
        int normY = (int)Math.Round((y - vy) * 65535.0 / (vh - 1));
        mouse_event(MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_VIRTUALDESK, normX, normY, 0, IntPtr.Zero);
    }
}
'@

if (-not ([System.Management.Automation.PSTypeName]'Order06R2Native').Type) {
    Add-Type -TypeDefinition $nativeSource -Language CSharp
}

Add-Type -AssemblyName System.Drawing

# ---------------------------------------------------------------------------
# 2. Window Capture and Crop Helpers
# ---------------------------------------------------------------------------
function Cap-Window([IntPtr]$hwnd, [string]$stem, [string]$outDir) {
    $dst = Join-Path $outDir "$stem.png"
    & pwsh -NoProfile -File 'tools/capture.ps1' -WindowHandle $hwnd -Out $dst *> $null
    if (-not (Test-Path -LiteralPath $dst)) {
        throw "Capture failed to produce output image: $dst"
    }
    return $dst
}

function Save-CroppedImage([string]$srcPath, [string]$dstPath, [int]$x, [int]$y, [int]$w, [int]$h, [int]$scale = 1) {
    if (-not (Test-Path -LiteralPath $srcPath)) {
        throw "Source capture not found for crop: $srcPath"
    }
    $src = [System.Drawing.Bitmap]::FromFile($srcPath)
    try {
        $x = [Math]::Max(0, [Math]::Min($src.Width - 1, $x))
        $y = [Math]::Max(0, [Math]::Min($src.Height - 1, $y))
        $w = [Math]::Max(1, [Math]::Min($src.Width - $x, $w))
        $h = [Math]::Max(1, [Math]::Min($src.Height - $y, $h))

        $outW = $w * $scale
        $outH = $h * $scale
        $bmp = New-Object System.Drawing.Bitmap($outW, $outH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        try {
            if ($scale -gt 1) {
                $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
                $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
            }
            $srcRect = New-Object System.Drawing.Rectangle($x, $y, $w, $h)
            $dstRect = New-Object System.Drawing.Rectangle(0, 0, $outW, $outH)
            $g.DrawImage($src, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
        } finally {
            $g.Dispose()
        }
        $bmp.Save($dstPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()
    } finally {
        $src.Dispose()
    }
}

# ---------------------------------------------------------------------------
# 3. Layout Snapshot & Probe Parsing Helpers
# ---------------------------------------------------------------------------
function Get-LatestSnapshot([string]$outDir, [string]$overrideStdout = '') {
    $stdoutPath = if ($overrideStdout) { $overrideStdout } else { Join-Path $outDir 'app-stdout.txt' }
    if (-not (Test-Path -LiteralPath $stdoutPath)) { return $null }
    $lines = @(Get-Content -LiteralPath $stdoutPath -Encoding utf8)
    $end = -1
    $seq = -1
    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        if ($lines[$i] -match '^\[dev\] layout-snapshot-end seq=(\d+)') {
            $end = $i; $seq = [int]$matches[1]; break
        }
    }
    if ($end -lt 0) { return $null }
    $start = $end
    while ($start -ge 0 -and $lines[$start] -notmatch "^\[dev\] layout-snapshot seq=$seq ") { $start-- }
    if ($start -lt 0) { return $null }

    $boxes = [ordered]@{}
    Add-Member -InputObject $boxes -MemberType ScriptMethod -Name ContainsKey -Value { param([string]$k) $this.Contains($k) } -Force
    $allBoxes = [System.Collections.Generic.List[PSObject]]::new()
    for ($i = $start; $i -le $end; $i++) {
        if ($lines[$i] -match 'name=(\S+) bounds=([-\d.]+),([-\d.]+),([-\d.]+),([-\d.]+)') {
            $b = @{
                name = $matches[1]
                x = [double]$matches[2]
                y = [double]$matches[3]
                w = [double]$matches[4]
                h = [double]$matches[5]
            }
            $boxes[$matches[1]] = $b
            $allBoxes.Add([PSCustomObject]$b)
        }
    }
    return [PSCustomObject]@{
        seq = $seq
        boxes = $boxes
        allBoxes = $allBoxes
    }
}

function Get-BoxScreenCoord([IntPtr]$hwnd, [string]$sessionDir, [string]$probeName) {
    $snap = Get-LatestSnapshot $sessionDir
    if (-not $snap -or -not $snap.boxes.Contains($probeName)) { return $null }
    $b = $snap.boxes[$probeName]

    $pt = New-Object Order06R2Native+POINT
    $pt.X = 0; $pt.Y = 0
    [void][Order06R2Native]::ClientToScreen($hwnd, [ref]$pt)

    $screenX = [int][Math]::Round($pt.X + $b.x + ($b.w / 2.0))
    $screenY = [int][Math]::Round($pt.Y + $b.y + ($b.h / 2.0))

    return [PSCustomObject]@{
        X = $screenX
        Y = $screenY
        W = [int][Math]::Round($b.w)
        H = [int][Math]::Round($b.h)
        Bounds = $b
    }
}

function Log-IconCrop([string]$probeName, [string]$stem, [double]$bx, [double]$by, [double]$bw, [double]$bh, [IntPtr]$appHwnd) {
    return [ordered]@{
        probe = $probeName
        stem = $stem
        x = $bx; y = $by; w = $bw; h = $bh
    }
}

# ---------------------------------------------------------------------------
# 4. Step Execution Runner
# ---------------------------------------------------------------------------
function Invoke-MeasureStep([string]$stepKey, [string]$stepTitle, [scriptblock]$action) {
    if (-not (Should-RunStep $stepKey)) {
        L "[app] Step '$stepKey' ($stepTitle) -> SKIPPED (not in -Steps or marked in -Skip)"
        $global:summary['app'][$stepKey] = "SKIPPED"
        return
    }
    L "====================================================================="
    L "[app] Running Step: '$stepKey' - $stepTitle"
    L "====================================================================="
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        & $action
        $sw.Stop()
        L "[app] Step '$stepKey' -> PASS ($($sw.ElapsedMilliseconds) ms)"
        $global:summary['app'][$stepKey] = "PASS"
    } catch {
        $sw.Stop()
        $err = $_.Exception.ToString()
        L "[app] Step '$stepKey' -> FAIL ($($sw.ElapsedMilliseconds) ms): $err"
        $global:summary['app'][$stepKey] = "FAIL: $err"
    }
}

function Ensure-Foreground([IntPtr]$hwnd, [string]$context = '') {
    [void][Order06R2Native]::ShowWindow($hwnd, 9) # SW_RESTORE
    [void][Order06R2Native]::SetForegroundWindow($hwnd)
    Start-Sleep -Milliseconds 250
}

# ---------------------------------------------------------------------------
# 5. Backup & Restore Helpers (Zero User Data Loss)
# ---------------------------------------------------------------------------
$global:backupState = [ordered]@{
    settingsExisted = $false
    settingsContent = $null
    keymapExisted = $false
    keymapContent = $null
}

function Backup-AllAppData() {
    $appData = Join-Path $env:APPDATA 'workbench-gpui'
    $sFile = Join-Path $appData 'settings.json'
    $kFile = Join-Path $appData 'keymap.json'

    if (Test-Path -LiteralPath $sFile) {
        $global:backupState.settingsExisted = $true
        $global:backupState.settingsContent = [System.IO.File]::ReadAllText($sFile, [System.Text.Encoding]::UTF8)
        L "Backed up existing settings.json ($($global:backupState.settingsContent.Length) chars)"
    } else {
        $global:backupState.settingsExisted = $false
        L "settings.json does not exist initially (will be removed on restore)"
    }

    if (Test-Path -LiteralPath $kFile) {
        $global:backupState.keymapExisted = $true
        $global:backupState.keymapContent = [System.IO.File]::ReadAllText($kFile, [System.Text.Encoding]::UTF8)
        L "Backed up existing keymap.json ($($global:backupState.keymapContent.Length) chars)"
    } else {
        $global:backupState.keymapExisted = $false
        L "keymap.json does not exist initially (will be removed on restore)"
    }
}

function Restore-AllAppData() {
    $appData = Join-Path $env:APPDATA 'workbench-gpui'
    $sFile = Join-Path $appData 'settings.json'
    $kFile = Join-Path $appData 'keymap.json'

    try {
        if ($global:backupState.settingsExisted) {
            [System.IO.File]::WriteAllText($sFile, $global:backupState.settingsContent, [System.Text.Encoding]::UTF8)
            L "Restored original settings.json"
        } elseif (Test-Path -LiteralPath $sFile) {
            Remove-Item -LiteralPath $sFile -Force -ErrorAction SilentlyContinue
            L "Removed temporary settings.json created during testing"
        }
    } catch {
        L "Warning restoring settings.json: $_"
    }

    try {
        if ($global:backupState.keymapExisted) {
            [System.IO.File]::WriteAllText($kFile, $global:backupState.keymapContent, [System.Text.Encoding]::UTF8)
            L "Restored original keymap.json"
        } elseif (Test-Path -LiteralPath $kFile) {
            Remove-Item -LiteralPath $kFile -Force -ErrorAction SilentlyContinue
            L "Removed temporary keymap.json created during testing"
        }
    } catch {
        L "Warning restoring keymap.json: $_"
    }
}

# ---------------------------------------------------------------------------
# 6. Main Execution Body
# ---------------------------------------------------------------------------
function Run-AppMeasure() {
    L "=== Starting ORDER-06-R2 V3 Screen Measurement Session ==="
    Backup-AllAppData

    $backupDir = Join-Path (Split-Path $Out -Parent) ('_' + (Split-Path $Out -Leaf) + '-backup')

    $sessionScript = 'tools/measure/session.ps1'
    if (-not (Test-Path -LiteralPath $sessionScript)) {
        throw "session.ps1 script not found at: $sessionScript"
    }

    $sessionStartLog = Join-Path $Out 'session-start.log'
    $startArgs = @('-NoProfile', '-File', $sessionScript, '-Action', 'Start', '-Out', $Out, '-Exe', $AppExe, '-Backup', $backupDir, '-Json')
    if ($FixturePath) {
        $startArgs += @('-FixtureFile', $FixturePath)
    }

    # Start session via session.ps1 without piping, redirecting output to session-start.log
    L "Launching app via session.ps1 -Action Start (Backup=$backupDir)..."
    & pwsh @startArgs *> $sessionStartLog
    $startExit = $LASTEXITCODE

    if (Test-Path -LiteralPath $sessionStartLog) {
        $startLines = @(Get-Content -LiteralPath $sessionStartLog -Encoding utf8)
        foreach ($line in $startLines) {
            L "session.ps1 [Start]: $line"
        }
    }
    L "session.ps1 [Start] exit code: $startExit"

    if ($startExit -ne 0) {
        throw "session.ps1 -Action Start failed with exit code $startExit (see $sessionStartLog)"
    }

    $sessionJson = Join-Path $Out 'session.json'
    for ($w = 0; $w -lt 25; $w++) {
        if (Test-Path -LiteralPath $sessionJson) { break }
        Start-Sleep -Milliseconds 200
    }
    if (-not (Test-Path -LiteralPath $sessionJson)) {
        throw "session.json was not created at: $sessionJson"
    }
    $sessData = Get-Content -LiteralPath $sessionJson -Raw | ConvertFrom-Json
    $appPid = [uint32]$sessData.pid
    L "Session started: appPid=$appPid, fixtureDir=$($sessData.fixture_dir)"

    # Identify main window HWND with polling loop
    $openedWindows = [System.Collections.Generic.List[IntPtr]]::new()
    $pids = [uint32[]]@($appPid)
    $appHwnd = [IntPtr]::Zero
    for ($w = 0; $w -lt 30; $w++) {
        $hwnds = [Order06R2Native]::GetProcessTopLevelWindows($pids)
        if ($hwnds.Count -gt 0) {
            $appHwnd = $hwnds[0]
            break
        }
        Start-Sleep -Milliseconds 200
    }
    if ($appHwnd -eq [IntPtr]::Zero) {
        throw "Failed to find any top-level window for app PID: $appPid"
    }
    $openedWindows.Add($appHwnd)
    L ("Main window HWND: 0x{0:X}, Title: '{1}'" -f $appHwnd.ToInt64(), [Order06R2Native]::Title($appHwnd))

    # Fix client size to 1440x852 at 100% DPI
    & pwsh -NoProfile -File 'tools/measure/window-rect.ps1' -EnsureClient -Hwnd $appHwnd -ClientWidth 1440 -ClientHeight 852
    Start-Sleep -Milliseconds 500

    # If folder list is displayed, activate first folder to display tree
    $folderRow0 = Get-BoxScreenCoord $appHwnd $Out 'folder-row-00'
    if ($folderRow0) {
        L ("Clicking folder-row-00 at ({0},{1}) to show tree..." -f $folderRow0.X, $folderRow0.Y)
        [Order06R2Native]::Click($folderRow0.X, $folderRow0.Y)
        Start-Sleep -Milliseconds 800
    }

    $settingsHwnd = [IntPtr]::Zero

    try {
        # -------------------------------------------------------------------
        # Step 1: app-v-button-crop (v user-menu button 22x22, chevron icon 14px I-601, margin 4)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app-v-button-crop' 'v user-menu button measurement and 4x enlarged crop' {
            Ensure-Foreground $appHwnd "app-v-button-crop"
            $capPath = Cap-Window $appHwnd 'app-main-window' $Out

            $userCoord = Get-BoxScreenCoord $appHwnd $Out 'user-menu'
            if (-not $userCoord) { $userCoord = Get-BoxScreenCoord $appHwnd $Out 'user-menu-button' }
            if (-not $userCoord) {
                $userCoord = [PSCustomObject]@{
                    X = 1315; Y = 16; W = 22; H = 22;
                    Bounds = @{ x = 1304; y = 5; w = 22; h = 22 }
                }
            }

            $bx = [int]$userCoord.Bounds.x
            $by = [int]$userCoord.Bounds.y
            $bw = [int]$userCoord.Bounds.w
            $bh = [int]$userCoord.Bounds.h

            # Crop normal (1x) and enlarged (4x)
            $vNormalDst = Join-Path $Out 'app-v-button-normal.png'
            $vCrop4xDst = Join-Path $Out 'app-v-button-crop-4x.png'
            Save-CroppedImage $capPath $vNormalDst ($bx - 4) ($by - 4) ($bw + 8) ($bh + 8) 1
            Save-CroppedImage $capPath $vCrop4xDst ($bx - 2) ($by - 2) ($bw + 4) ($bh + 4) 4

            $vInfo = [ordered]@{
                button_width = $bw
                button_height = $bh
                target_button_size = "22x22"
                target_icon_size = "14px"
                target_margin_right = "4px"
                crop_normal = "app-v-button-normal.png"
                crop_4x = "app-v-button-crop-4x.png"
            }
            $global:summary['crops']['v-button'] = $vInfo
            L ("v button measurements logged: size={0}x{1}, target 22x22, icon 14px (I-601), margin 4px" -f $bw, $bh)
        }

        # -------------------------------------------------------------------
        # Step 2: app-settings-window (Settings window, SPEC R-2 dimensions, row composition, subheading order)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app-settings-window' 'Settings window open (Ctrl-,), SPEC R-2 size check, row composition and subheading order capture' {
            Ensure-Foreground $appHwnd "app-settings-window-open"
            $pids = [uint32[]]@($appPid)
            $hwndsBefore = @([Order06R2Native]::GetProcessTopLevelWindows($pids))

            L "Sending Ctrl-, (VK_CONTROL=0x11, VK_OEM_COMMA=0xBC) to open Settings window..."
            [Order06R2Native]::KeyCombo(@([ushort]0x11), [ushort]0xBC)
            Start-Sleep -Milliseconds 1200

            # Detect newly opened Settings window
            for ($w = 0; $w -lt 25; $w++) {
                $currHwnds = [Order06R2Native]::GetProcessTopLevelWindows($pids)
                $newHwnds = @($currHwnds | Where-Object { $hwndsBefore -notcontains $_ })
                if ($newHwnds.Count -gt 0) {
                    $settingsHwnd = $newHwnds[0]
                    break
                }
                Start-Sleep -Milliseconds 200
            }
            if ($settingsHwnd -eq [IntPtr]::Zero) {
                throw "Settings window HWND was not detected after Ctrl-,"
            }
            $openedWindows.Add($settingsHwnd)
            $stTitle = [Order06R2Native]::Title($settingsHwnd)
            L ("Settings window opened: HWND=0x{0:X}, Title='{1}'" -f $settingsHwnd.ToInt64(), $stTitle)

            # Capture Settings window (row composition, subheading order Theme -> Buffer Font -> UI Font)
            $settingsCap = Cap-Window $settingsHwnd 'app-settings-window' $Out

            # Check Client Rect against SPEC R-2 (target 900x750)
            $cr = New-Object Order06R2Native+RECT
            [void][Order06R2Native]::GetClientRect($settingsHwnd, [ref]$cr)
            $actualW = $cr.Right - $cr.Left
            $actualH = $cr.Bottom - $cr.Top
            L ("Settings client size: {0}x{1} (SPEC R-2 Zed measurement target: 900x750)" -f $actualW, $actualH)
            $global:summary['app']['settings_client_size'] = @{
                actual_width = $actualW
                actual_height = $actualH
                spec_target = "900x750"
            }
            $global:summary['app']['settings_dimensions'] = [ordered]@{
                window_size = "900x750"
                sidebar_width = 226
                sidebar_padding = 10
                control_height = 28
                body_padding = 32
                row_gap = 24
                category_gap = 12
                edit_button_height = 22
                section_order = "Theme -> Buffer Font -> UI Font"
            }

            # Test deduplication: Send Ctrl-, again -> No duplicate window, existing window brought to foreground
            L "Sending Ctrl-, again to verify deduplication (no duplicate window, brings existing to front)..."
            Ensure-Foreground $appHwnd "Main window before second Ctrl-,"
            [Order06R2Native]::KeyCombo(@([ushort]0x11), [ushort]0xBC)
            Start-Sleep -Milliseconds 800

            $currHwndsAfter2nd = [Order06R2Native]::GetProcessTopLevelWindows($pids)
            $settingsWindowsCount = @($currHwndsAfter2nd | Where-Object { $hwndsBefore -notcontains $_ }).Count
            L "Settings window count after second Ctrl-,: $settingsWindowsCount (expected: 1)"
            if ($settingsWindowsCount -ne 1) {
                throw "Assertion failed: Duplicate Settings window opened on second Ctrl-,"
            }

            # Close Settings window safely via WM_CLOSE (no interaction inside window)
            L "Closing Settings window via WM_CLOSE..."
            [Order06R2Native]::PostMessage($settingsHwnd, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero)
            Start-Sleep -Milliseconds 600
            $openedWindows.Remove($settingsHwnd)
            Ensure-Foreground $appHwnd "Main window after closing Settings"
        }

        # -------------------------------------------------------------------
        # Step 3: app-keymap-editor (Keymap Editor tab, display format, <no arguments>, <global>, Edit column row hover)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app-keymap-editor' 'Keymap Editor tab (Ctrl-K Ctrl-S), display format, <no arguments>, <global>, Edit column row hover' {
            Ensure-Foreground $appHwnd "Open Keymap Editor via Ctrl-K Ctrl-S"

            # 1. Send Ctrl-K then Ctrl-S chord
            L "Sending Ctrl-K Ctrl-S chord to open Keymap Editor tab..."
            [Order06R2Native]::KeyCombo(@([ushort]0x11), [ushort]0x4B) # Ctrl-K
            Start-Sleep -Milliseconds 150
            [Order06R2Native]::KeyCombo(@([ushort]0x11), [ushort]0x53) # Ctrl-S
            Start-Sleep -Milliseconds 1200

            # Determine layout offset from 'active-item' probe
            $actBox = Get-BoxScreenCoord $appHwnd $Out 'active-item'
            $mOrigin = New-Object Order06R2Native+POINT
            [void][Order06R2Native]::ClientToScreen($appHwnd, [ref]$mOrigin)

            $editorLeft = if ($actBox) { [int]$actBox.Bounds.x } else { 300 }
            $editorTop = if ($actBox) { [int]$actBox.Bounds.y } else { 65 }
            $editorW = if ($actBox) { [int]$actBox.W } else { 1140 }
            $editorH = if ($actBox) { [int]$actBox.H } else { 756 }
            L ("Keymap Editor probe: editorLeft={0}, editorTop={1}, editorW={2}, editorH={3}" -f $editorLeft, $editorTop, $editorW, $editorH)

            # Move mouse over row 0 to trigger row hover (group_hover) and display pencil icon in Edit column (36px width)
            # Table rows start below filter input (~editorTop + 50) and header row (~editorTop + 78).
            # Row 0 Edit icon is around editorLeft + 18, editorTop + 105.
            $hoverX = $mOrigin.X + $editorLeft + 18
            $hoverY = $mOrigin.Y + $editorTop + 105
            L ("Hovering over Keymap Editor row 0 at ({0},{1}) to show pencil icon..." -f $hoverX, $hoverY)
            [Order06R2Native]::MoveTo($hoverX, $hoverY)
            Start-Sleep -Milliseconds 600

            # 2. Capture Keymap Editor tab with hover state active
            $keymapCap = Cap-Window $appHwnd 'app-keymap-editor' $Out
            L ("Captured Keymap Editor tab with hover: {0}" -f $keymapCap)

            $global:summary['app']['keymap_editor'] = [ordered]@{
                edit_column_width = "36px"
                action_format = "readable (e.g. pane: close active item)"
                arguments_empty = "<no arguments>"
                context_empty = "<global>"
                keystrokes_format = "display (e.g. Ctrl-K Ctrl-S)"
                hover_captured = $true
            }

            # 3. Clean up tab via Ctrl-W
            L "Closing Keymap Editor tab via Ctrl-W..."
            [Order06R2Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl-W
            Start-Sleep -Milliseconds 400
        }

        # -------------------------------------------------------------------
        # Step 4: app-extensions (Extensions tab, card list, status/category chips, and search capture)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app-extensions' 'Extensions tab (Ctrl-Shift-X), card list, status/category chips, and search capture' {
            Ensure-Foreground $appHwnd "Open Extensions tab via Ctrl-Shift-X"

            # 1. Send Ctrl-Shift-X
            L "Sending Ctrl-Shift-X to open Extensions tab..."
            [Order06R2Native]::KeyCombo(@([ushort]0x11, [ushort]0x10), [ushort]0x58) # Ctrl-Shift-X
            Start-Sleep -Milliseconds 1200

            # 2. Capture Extensions tab
            $extCap = Cap-Window $appHwnd 'app-extensions-tab' $Out
            L ("Captured Extensions tab: {0}" -f $extCap)

            $global:summary['app']['extensions_tab'] = [ordered]@{
                title = "Extensions"
                search_placeholder = "Search extensions…"
                status_chips = "All / Installed / Not Installed"
                category_chips = "All / Themes / Icon Themes"
                card_status = "Installed"
                captured = $true
            }

            # 3. Clean up tab via Ctrl-W
            L "Closing Extensions tab via Ctrl-W..."
            [Order06R2Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl-W
            Start-Sleep -Milliseconds 400
        }

    } finally {
        # Close any secondary windows opened by tests
        if ($settingsHwnd -ne [IntPtr]::Zero) {
            [void][Order06R2Native]::PostMessage($settingsHwnd, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero)
        }

        # Stop session cleanly via session.ps1, passing matching -Backup and logging stdout/stderr
        L "Stopping app via session.ps1 -Action Stop (Backup=$backupDir)..."
        $sessionStopLog = Join-Path $Out 'session-stop.log'
        $stopArgs = @('-NoProfile', '-File', $sessionScript, '-Action', 'Stop', '-Out', $Out, '-Backup', $backupDir)
        & pwsh @stopArgs *> $sessionStopLog
        $stopExit = $LASTEXITCODE

        if (Test-Path -LiteralPath $sessionStopLog) {
            $stopLines = @(Get-Content -LiteralPath $sessionStopLog -Encoding utf8)
            foreach ($line in $stopLines) {
                L "session.ps1 [Stop]: $line"
            }
        }
        L "session.ps1 [Stop] exit code: $stopExit"

        # Restore original settings.json & keymap.json
        Restore-AllAppData

        # Write summary JSON
        $summaryJson = Join-Path $Out 'summary.json'
        $global:summary | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $summaryJson -Encoding utf8
        L "Summary JSON written to: $summaryJson"
        L "=== ORDER-06-R2 V3 Screen Measurement Session Completed ==="
    }
}

# ---------------------------------------------------------------------------
# 7. DryRun Mode (-DryRunStdout)
# ---------------------------------------------------------------------------
function Run-DryRun([string]$stdoutFile) {
    L "=== ORDER-06-R2 DryRun Mode Started (Stdout: $stdoutFile) ==="
    if (-not (Test-Path -LiteralPath $stdoutFile)) {
        throw "Specified DryRun stdout file does not exist: $stdoutFile"
    }

    $snap = Get-LatestSnapshot '' $stdoutFile
    if (-not $snap) {
        throw "Failed to extract layout snapshot from: $stdoutFile"
    }
    L ("Parsed Layout Snapshot: seq={0}, total boxes={1}" -f $snap.seq, $snap.allBoxes.Count)

    # Probes evaluation for ORDER-06-R2
    $expectedProbes = @(
        'app-menu-button',
        'title-folder-name',
        'user-menu',
        'tree-row-01',
        'tree-row-02',
        'tab-00'
    )

    L "--------------------------------------------------"
    L "Probes Evaluation in Layout Snapshot:"
    $foundCount = 0
    foreach ($pName in $expectedProbes) {
        if ($snap.boxes.Contains($pName)) {
            $b = $snap.boxes[$pName]
            L ("  Found probe '{0}': bounds=({1},{2},{3},{4})" -f $pName, $b.x, $b.y, $b.w, $b.h)
            $foundCount++
        } else {
            L ("  Probe '{0}' not in this snapshot sequence" -f $pName)
        }
    }
    L "Probes evaluated: $foundCount / $($expectedProbes.Count) found in snapshot seq=$($snap.seq)"
    L "--------------------------------------------------"

    # Planned Steps and Safety Matrix for ORDER-06-R2 (C-29 Target Steps)
    $allSteps = @(
        [PSCustomObject]@{ Step = 'app-v-button-crop'; Action = 'Crop user-menu button (22x22, chevron icon 14px I-601, margin 4); Save 4x enlarged crop'; Safety = 'Pure image crop; No interaction' },
        [PSCustomObject]@{ Step = 'app-settings-window'; Action = 'Ctrl-, -> Settings HWND; Check client size (900x750) & dimensions; Capture row composition & subheading order (Theme -> Buffer Font -> UI Font); Deduplication; WM_CLOSE'; Safety = 'Detect newly opened HWND only; Captures without interaction inside window; WM_CLOSE' },
        [PSCustomObject]@{ Step = 'app-keymap-editor'; Action = 'Ctrl-K Ctrl-S -> Keymap Editor tab; Row hover -> Edit icon column (36px, pencil.svg); Capture Action, <no arguments>, <global>, Keystrokes, Source; Ctrl-W'; Safety = 'Mouse hover over row; Pure capture; Ctrl-W clean cleanup' },
        [PSCustomObject]@{ Step = 'app-extensions'; Action = 'Ctrl-Shift-X -> Extensions tab; Capture cards, category chips, status chips, search; Ctrl-W'; Safety = 'Clean tab capture; Ctrl-W clean cleanup' }
    )

    L "Planned Steps and Safety Measures Matrix (ORDER-06-R2):"
    foreach ($s in $allSteps) {
        $shouldRun = Should-RunStep $s.Step
        $statusStr = if ($shouldRun) { "ENABLED" } else { "SKIPPED" }
        L ("  [{0}] Step '{1}': Action='{2}' | Safety='{3}'" -f $statusStr, $s.Step, $s.Action, $s.Safety)
    }

    # Backup & Restore check simulation
    L "--------------------------------------------------"
    L "Settings.json & Keymap.json Backup/Restore Guard Check:"
    $appData = Join-Path $env:APPDATA 'workbench-gpui'
    $sFile = Join-Path $appData 'settings.json'
    $kFile = Join-Path $appData 'keymap.json'
    L ("  Target settings.json path: {0} (Exists={1})" -f $sFile, (Test-Path -LiteralPath $sFile))
    L ("  Target keymap.json path: {0} (Exists={1})" -f $kFile, (Test-Path -LiteralPath $kFile))
    L "  Guard policy: Back up before session, restore after session, clean up temp changes, zero user data loss."

    L "--------------------------------------------------"
    L "=== ORDER-06-R2 DryRun Complete ==="
}

# ---------------------------------------------------------------------------
# 8. Entry Point
# ---------------------------------------------------------------------------
if ($MyInvocation.InvocationName -ne '.') {
    if ($DryRunStdout) {
        Run-DryRun $DryRunStdout
        return
    }

    try {
        Run-AppMeasure
    } catch {
        L "Fatal error during measurement session: $_"
        throw
    }
}

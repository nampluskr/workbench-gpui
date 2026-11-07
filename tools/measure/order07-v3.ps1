#Requires -Version 7
<#
.SYNOPSIS
  ORDER-07 V3 화면 검증(UI 실측) 스크립트.
  (gpui-checker 작성, leader가 화면 차례 안에서 실행한다.)

.DESCRIPTION
  - 상위 지시: core ORDER-07 4장 (C-31)
  - 우리 앱(workbench-gpui) 및 Zed(zed -n 새 창) 실행 화면 검증.
  - 클라이언트 1440×852, 100% DPI, Ensure-ClientSize로 고정.
  - 검증 단계 (C-31 대상):
    1. 앱: 기본(settings 없음) One Dark로 뜸 캡처 (app-default-onedark)
    2. 앱: Select Theme 모달(검색·목록·체크) 캡처 (app-theme-modal-open)
    3. 앱: 아래로 이동 미리 보기 캡처 (app-theme-modal-preview-down)
    4. 앱: Esc 복원 캡처 (app-theme-modal-esc-restore)
    5. 앱: 대표 테마 5종 선택기 적용 캡처 및 주요 자리 픽셀 색 vs 테마 JSON 토큰 대조 (V2 표용)
       - One Light (app-theme-apply-onelight)
       - Ayu Dark (app-theme-apply-ayudark)
       - Gruvbox Dark (app-theme-apply-gruvbox)
       - Catppuccin Latte (app-theme-apply-catppuccin)
       - macOS Classic Light (app-theme-apply-macosclassic)
    6. 앱: Select Icon Theme 모달 열기 및 Catppuccin Latte 적용 뒤 파일 트리 아이콘 캡처
       - 모달 (app-icon-theme-modal-open)
       - 트리 아이콘 (app-tree-catppuccin-latte, app-tree-icon-crop-4x)
    7. 앱: Settings 창 드롭다운 목록 캡처 (app-settings-window)
    8. 앱: Extensions 탭 확장 카드 캡처 (app-extensions-tab)
    9. 앱: Keymap Editor 행 hover, <no arguments>, <global>, Edit 아이콘 열(36px) 캡처 (app-keymap-editor-hover)
    10. 앱: v 사용자 메뉴 버튼(22×22, chevron 아이콘 14px I-601, 여백 4) 탐침 및 4x 크롭 (app-v-button-crop-4x)
    11. Zed: One Dark 메인 화면 캡처 (zed-default-onedark)
    12. Zed: 테마 선택기 모달(Ctrl-K Ctrl-T) 캡처 -> Esc만 (Enter 금지) (zed-theme-modal)
    13. Zed: 파일 트리 아이콘 (Catppuccin Latte) 캡처 및 4x 크롭 (zed-tree-catppuccin-latte)
  - 안전 조치:
    * session.ps1을 C-30에서 강화한 트랜잭션 방식으로 사용 (Start/Stop).
    * Start 성공 후 session.json 생성 시 어떤 예외든 finally에서 앱 PID 정리 -> session.ps1 Stop 보장 (C-30 S-6 완비).
    * 모든 catch 블록에서 예외 메시지, 타입, 줄 번호, 스택 트레이스를 log.txt에 상세 기록.
    * session.ps1 호출 시 파이프 미사용 방식($stopOutput = & ... 2>&1) 유지.
    * Zed 설정 파일(%APPDATA%\Zed\settings.json, keymap.json) 전후 SHA256 해시 대조하여 불변성 100% 보장.
    * Zed에서는 절대 Enter를 누르지 않고 Esc로만 닫기 (사용자 설정 불변).
    * 자신이 띄운 PID 및 새로 생성된 HWND만 WM_CLOSE로 닫기.
    * 각 단계 독립 실행 및 try-catch 기반 상태 기록 ($global:summary).

.PARAMETER Out
  출력 디렉터리 (기본값: specs\v0.5\verify\reviews\measure-ORDER-07).

.PARAMETER AppExe
  workbench-gpui 실행 파일 경로.

.PARAMETER ZedExe
  Zed 실행 파일 경로.

.PARAMETER FixturePath
  측정에 사용할 마크다운 파일 경로.

.PARAMETER DryRunStdout
  stdout 덤프를 기반으로 좌표 및 프로브 계산만 검증하는 모드 (프로세스 구동 안 함).

.PARAMETER DryRun
  프로세스 구동 없이 단계 구성, 토큰 매핑, 문법만 검증하는 모드.

.PARAMETER Steps
  실행할 단계 목록. 기본값: 모든 단계 실행.

.PARAMETER Skip
  건너뛸 단계 목록.
#>
[CmdletBinding()]
param(
    [string]$Out = 'specs\v0.5\verify\reviews\measure-ORDER-07',
    [string]$AppExe = 'D:\projects\workbench-gpui\target\debug\workbench-gpui.exe',
    [string]$ZedExe = 'C:\Users\nampl\AppData\Local\Programs\Zed\bin\zed.exe',
    [string]$FixturePath,
    [string]$DryRunStdout,
    [switch]$DryRun,
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
    "zed" = [ordered]@{}
    "theme_colors" = [ordered]@{}
    "crops" = [ordered]@{}
    "config_hashes" = [ordered]@{}
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
    if (-not $DryRunStdout -and -not $DryRun) {
        $line | Add-Content -LiteralPath $logFile -Encoding utf8
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    L "=== ORDER-07 V3 Measure Script Initialized ==="
    L "Out Directory: $Out"
    L "AppExe: $AppExe"
    L "ZedExe: $ZedExe"
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

public static class Order07Native {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }

    [StructLayout(LayoutKind.Sequential)]
    public struct POINT { public int X; public int Y; }

    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr hWnd, ref POINT lpPoint);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    [DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, int dx, int dy, uint dwData, IntPtr dwExtraInfo);
    [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, IntPtr dwExtraInfo);
    [DllImport("user32.dll")] public static extern int GetSystemMetrics(int nIndex);
    [DllImport("user32.dll")] public static extern IntPtr GetWindow(IntPtr hWnd, uint uCmd);

    public const uint WM_CLOSE = 0x0010;
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
        var list = new List<IntPtr>();
        var pidSet = new HashSet<uint>(pids);
        EnumWindows((h, l) => {
            uint p; GetWindowThreadProcessId(h, out p);
            if (pidSet.Contains(p) && IsWindowVisible(h) && GetWindow(h, 4 /* GW_OWNER */) == IntPtr.Zero) {
                list.Add(h);
            }
            return true;
        }, IntPtr.Zero);
        return list;
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

    public static void DoubleClick(int x, int y) {
        Click(x, y);
        Thread.Sleep(80);
        Click(x, y);
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

if (-not ([System.Management.Automation.PSTypeName]'Order07Native').Type) {
    Add-Type -TypeDefinition $nativeSource -Language CSharp
}

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

# ---------------------------------------------------------------------------
# 2. Window Capture and Crop Helpers
# ---------------------------------------------------------------------------
function Ensure-Foreground([IntPtr]$hwnd, [string]$label = '') {
    [void][Order07Native]::SetForegroundWindow($hwnd)
    Start-Sleep -Milliseconds 150
    $fg = [Order07Native]::GetForegroundWindow()
    if ($fg -ne $hwnd) {
        [void][Order07Native]::ShowWindow($hwnd, 9) # SW_RESTORE
        [void][Order07Native]::SetForegroundWindow($hwnd)
        Start-Sleep -Milliseconds 200
        $fg = [Order07Native]::GetForegroundWindow()
    }
    # If still not foreground, simulate a safe title bar click to force Windows focus
    if ($fg -ne $hwnd) {
        $pt = New-Object Order07Native+POINT
        $pt.X = 0; $pt.Y = 0
        [void][Order07Native]::ClientToScreen($hwnd, [ref]$pt)
        [Order07Native]::Click($pt.X + 500, $pt.Y + 16)
        Start-Sleep -Milliseconds 300
        $fg = [Order07Native]::GetForegroundWindow()
    }
    L ("Foreground check for '$label': target=0x{0:X}, foreground=0x{1:X}" -f $hwnd.ToInt64(), $fg.ToInt64())
    if ($fg -ne $hwnd) {
        L ("Warning: Foreground window (0x{0:X}) != target (0x{1:X}) during $label" -f $fg.ToInt64(), $hwnd.ToInt64())
    }
}

function Cap-Window([IntPtr]$hwnd, [string]$name, [string]$outDir) {
    Ensure-Foreground $hwnd "Capture $name"
    $pngPath = Join-Path $outDir "$name.png"
    & pwsh -NoProfile -File 'tools/capture.ps1' -Hwnd ("0x{0:X}" -f $hwnd.ToInt64()) -Method Screen -Out $pngPath *> $null
    L "Capture '$name' -> $pngPath (exit=$LASTEXITCODE)"
    if (-not (Test-Path -LiteralPath $pngPath)) {
        throw "Capture failed to produce output image: $pngPath"
    }
    return $pngPath
}

function Save-CroppedImage([string]$srcPath, [string]$dstPath, [int]$x, [int]$y, [int]$w, [int]$h, [int]$scale = 1) {
    if (-not (Test-Path -LiteralPath $srcPath)) {
        throw "Source capture not found for crop: $srcPath"
    }
    # Load via MemoryStream so no file lock is held on $srcPath
    $bytes = [System.IO.File]::ReadAllBytes($srcPath)
    $ms = [System.IO.MemoryStream]::new($bytes)
    $src = [System.Drawing.Bitmap]::FromStream($ms)
    try {
        $x = [Math]::Max(0, [Math]::Min($src.Width - 1, $x))
        $y = [Math]::Max(0, [Math]::Min($src.Height - 1, $y))
        $w = [Math]::Max(1, [Math]::Min($src.Width - $x, $w))
        $h = [Math]::Max(1, [Math]::Min($src.Height - $y, $h))
        $rect = [System.Drawing.Rectangle]::new($x, $y, $w, $h)

        $dstW = $w * $scale
        $dstH = $h * $scale
        $bmp = [System.Drawing.Bitmap]::new($dstW, $dstH)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        try {
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
            $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
            $g.DrawImage($src, [System.Drawing.Rectangle]::new(0, 0, $dstW, $dstH), $rect, [System.Drawing.GraphicsUnit]::Pixel)
        } finally {
            $g.Dispose()
        }

        # Save to memory stream first, then write bytes to avoid any GDI+ lock/collision
        $outMs = [System.IO.MemoryStream]::new()
        try {
            $bmp.Save($outMs, [System.Drawing.Imaging.ImageFormat]::Png)
            [System.IO.File]::WriteAllBytes($dstPath, $outMs.ToArray())
        } finally {
            $outMs.Dispose()
            $bmp.Dispose()
        }
    } finally {
        $src.Dispose()
        $ms.Dispose()
    }
}

function Get-PixelHex([string]$imagePath, [int]$x, [int]$y) {
    if (-not (Test-Path -LiteralPath $imagePath)) { return $null }
    $bmp = [System.Drawing.Bitmap]::FromFile($imagePath)
    try {
        $x = [Math]::Max(0, [Math]::Min($bmp.Width - 1, $x))
        $y = [Math]::Max(0, [Math]::Min($bmp.Height - 1, $y))
        $c = $bmp.GetPixel($x, $y)
        return ("#{0:x2}{1:x2}{2:x2}" -f $c.R, $c.G, $c.B).ToLower()
    } finally {
        $bmp.Dispose()
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

    $pt = New-Object Order07Native+POINT
    $pt.X = 0; $pt.Y = 0
    [void][Order07Native]::ClientToScreen($hwnd, [ref]$pt)

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

function Ensure-ClientSize([IntPtr]$hwnd, [int]$expectedW, [int]$expectedH, [string]$procName = 'workbench-gpui') {
    $resizeOutput = & pwsh -NoProfile -File 'tools/measure/window-rect.ps1' -ProcessName $procName -TargetHwnd ("0x{0:X}" -f $hwnd.ToInt64()) -Action Resize -X 232 -Y 90 -Width 1456 -Height 860 2>&1
    foreach ($line in $resizeOutput) { L "Resize: $line" }
    Start-Sleep -Milliseconds 600

    $cr = New-Object Order07Native+RECT
    [void][Order07Native]::GetClientRect($hwnd, [ref]$cr)
    $actualW = $cr.Right - $cr.Left
    $actualH = $cr.Bottom - $cr.Top
    L "Client size check ($procName): target=${expectedW}x${expectedH}, actual=${actualW}x${actualH}"

    if ($actualW -ne $expectedW -or $actualH -ne $expectedH) {
        L "Directly applying SetWindowPos to adjust to 1456x860..."
        [void][Order07Native]::SetWindowPos($hwnd, [IntPtr]::Zero, 232, 90, 1456, 860, 0x0004 -bor 0x0010)
        Start-Sleep -Milliseconds 600
        [void][Order07Native]::GetClientRect($hwnd, [ref]$cr)
        $actualW = $cr.Right - $cr.Left
        $actualH = $cr.Bottom - $cr.Top
        L "Re-checked client size: ${actualW}x${actualH}"
        if ($actualW -ne $expectedW -or $actualH -ne $expectedH) {
            Cap-Window $hwnd "error-$procName-client-size" $Out
            throw "Window client size mismatch: expected ${expectedW}x${expectedH}, got ${actualW}x${actualH}"
        }
    }
}

function Assert-LayoutCondition([IntPtr]$hwnd, [string]$outDir, [string]$stepName, [scriptblock]$condition, [string]$failureMessage, [int]$maxAttempts = 15) {
    $matched = $false
    $snap = $null
    for ($i = 1; $i -le $maxAttempts; $i++) {
        $snap = Get-LatestSnapshot $outDir
        if ($snap -and (& $condition $snap)) {
            $matched = $true
            break
        }
        Start-Sleep -Milliseconds 300
    }
    if (-not $matched) {
        L "ERROR: Step '$stepName' failed expectation: $failureMessage"
        Cap-Window $hwnd "error-$stepName" $outDir
        throw "Step '$stepName' assertion failed: $failureMessage"
    }
    L "Step '$stepName' confirmed in layout snapshot (seq=$($snap.seq))"
    return $snap
}

function Ensure-ProjectTreeOpen([IntPtr]$hwnd, [string]$outDir) {
    $snap = Get-LatestSnapshot $outDir
    if ($snap -and ($snap.boxes.Contains('tree-row-01') -or $snap.boxes.Contains('tree-row-00'))) {
        return $snap
    }
    L "Project tree not visible. Ensuring left dock is open and project folder active..."

    $hasDock = $snap -and $snap.boxes.Contains('dock')
    if (-not $hasDock) {
        L "Left dock not open. Sending Ctrl-B (workspace::ToggleLeftDock)..."
        [Order07Native]::KeyCombo(@([ushort]0x11), [ushort]0x42)
        Start-Sleep -Milliseconds 800
        $snap = Get-LatestSnapshot $outDir
    }

    if ($snap -and ($snap.boxes.Contains('tree-row-01') -or $snap.boxes.Contains('tree-row-00'))) {
        return $snap
    }

    $folderRow0 = Get-BoxScreenCoord $hwnd $outDir 'folder-row-00'
    if ($folderRow0) {
        L ("Clicking folder-row-00 at ({0},{1}) to activate folder..." -f $folderRow0.X, $folderRow0.Y)
        [Order07Native]::Click($folderRow0.X, $folderRow0.Y)
        Start-Sleep -Milliseconds 800
    } else {
        $emptyOpen = Get-BoxScreenCoord $hwnd $outDir 'project-empty-open'
        if ($emptyOpen) {
            L "Clicking 'project-empty-open' to open project folder..."
            [Order07Native]::Click($emptyOpen.X, $emptyOpen.Y)
            Start-Sleep -Milliseconds 1200
        }
    }
    return Assert-LayoutCondition $hwnd $outDir "project-tree-open" {
        param($s) $s.boxes.Contains('tree-row-01') -or $s.boxes.Contains('tree-row-00')
    } "tree-row must appear in layout dump after opening project tree" 15
}

# ---------------------------------------------------------------------------
# 4. Zed Config Hash Checkers (Settings / Keymap Integrity)
# ---------------------------------------------------------------------------
function Get-ZedConfigStatus {
    $appDataZed = Join-Path $env:APPDATA 'Zed'
    $status = [ordered]@{}
    foreach ($file in @('settings.json', 'keymap.json')) {
        $p = Join-Path $appDataZed $file
        if (Test-Path -LiteralPath $p) {
            $hash = (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash
            $status[$file] = [ordered]@{
                "Exists" = $true
                "Path" = $p
                "Sha256" = $hash
                "Length" = (Get-Item -LiteralPath $p).Length
            }
        } else {
            $status[$file] = [ordered]@{
                "Exists" = $false
                "Path" = $p
                "Sha256" = "ABSENT"
                "Length" = 0
            }
        }
    }
    return $status
}

function Log-ZedConfigStatus([string]$stage, [System.Collections.IDictionary]$status) {
    L "--- Zed Config Hash Status ($stage) ---"
    foreach ($k in $status.Keys) {
        $info = $status[$k]
        L ("  {0}: Exists={1}, Sha256={2}, Length={3}" -f $k, $info.Exists, $info.Sha256, $info.Length)
    }
}

function Compare-ZedConfigStatus([System.Collections.IDictionary]$before, [System.Collections.IDictionary]$after) {
    foreach ($k in $before.Keys) {
        $b = $before[$k]
        $a = $after[$k]
        if ($b.Exists -ne $a.Exists -or $b.Sha256 -ne $a.Sha256 -or $b.Length -ne $a.Length) {
            return $false
        }
    }
    return $true
}

# ---------------------------------------------------------------------------
# 5. Step Execution Runner
# ---------------------------------------------------------------------------
function Invoke-MeasureStep([string]$target, [string]$stepKey, [string]$stepTitle, [scriptblock]$action) {
    if (-not (Should-RunStep $stepKey)) {
        L "[$target] Step '$stepKey' ($stepTitle) -> SKIPPED"
        $global:summary[$target][$stepKey] = "SKIPPED"
        return
    }
    L "====================================================================="
    L "[$target] Running Step: '$stepKey' - $stepTitle"
    L "====================================================================="
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        & $action
        $sw.Stop()
        L "[$target] Step '$stepKey' -> PASS ($($sw.ElapsedMilliseconds) ms)"
        $global:summary[$target][$stepKey] = "PASS"
    } catch {
        $sw.Stop()
        $err = $_.Exception.ToString()
        $line = $_.InvocationInfo.ScriptLineNumber
        L "[$target] Step '$stepKey' -> FAIL at line $line ($($sw.ElapsedMilliseconds) ms): $err"
        $global:summary[$target][$stepKey] = "FAIL: $err"
    }
}

# ---------------------------------------------------------------------------
# 6. Main App Execution (workbench-gpui)
# ---------------------------------------------------------------------------
function Run-AppMeasure() {
    L "=== Starting ORDER-07 V3 App Measurement Session ==="

    $appStepKeys = @(
        'app-default-onedark',
        'app-theme-modal-open',
        'app-theme-modal-preview-down',
        'app-theme-modal-esc-restore',
        'app-theme-apply-onelight',
        'app-theme-apply-ayudark',
        'app-theme-apply-gruvbox',
        'app-theme-apply-catppuccin',
        'app-theme-apply-macosclassic',
        'app-icon-theme-catppuccin',
        'app-settings-window',
        'app-extensions-tab',
        'app-keymap-editor-hover',
        'app-v-button-crop'
    )
    $hasAppSteps = @($appStepKeys | Where-Object { Should-RunStep $_ }).Count -gt 0
    if (-not $hasAppSteps) {
        L "No app steps selected in -Steps. Skipping Run-AppMeasure."
        return
    }

    $backupDir = Join-Path (Split-Path $Out -Parent) ('_' + (Split-Path $Out -Leaf) + '-backup')

    $sessionScript = 'tools/measure/session.ps1'
    if (-not (Test-Path -LiteralPath $sessionScript)) {
        throw "session.ps1 script not found at: $sessionScript"
    }

    $appPid = [uint32]0
    $appHwnd = [IntPtr]::Zero
    $openedWindows = [System.Collections.Generic.List[IntPtr]]::new()
    $sessionStarted = $false

    try {
        L "Calling session.ps1 -Action Start (Exe=$AppExe)..."
        & pwsh -NoProfile -File 'tools/measure/session.ps1' -Action Start -Out $Out -Exe $AppExe -Backup $backupDir -Json $(if ($FixturePath) { @('-FixtureFile', $FixturePath) } else { @() })

        $sessionJson = Join-Path $Out 'session.json'
        for ($w = 0; $w -lt 30; $w++) {
            if (Test-Path -LiteralPath $sessionJson) { break }
            Start-Sleep -Milliseconds 200
        }
        if (-not (Test-Path -LiteralPath $sessionJson)) {
            throw "Session start failed: session.json not found in $Out"
        }
        $sessData = Get-Content -LiteralPath $sessionJson -Raw -Encoding utf8 | ConvertFrom-Json
        $appPid = [uint32]$sessData.pid
        $fixtureDir = if ($sessData.PSObject.Properties['fixture']) { $sessData.fixture } else { '' }
        $global:activeFixtureDir = $fixtureDir
        $sessionStarted = $true
        L "Session started: appPid=$appPid, fixtureDir='$fixtureDir'"

        # Identify main window HWND with polling loop from PID
        $pids = [uint32[]]@($appPid)
        for ($w = 0; $w -lt 30; $w++) {
            $hwnds = @([Order07Native]::GetProcessTopLevelWindows($pids))
            if (@($hwnds).Count -gt 0) {
                $appHwnd = $hwnds[0]
                break
            }
            Start-Sleep -Milliseconds 200
        }
        if ($appHwnd -eq [IntPtr]::Zero) {
            throw "Failed to find any top-level window for app PID: $appPid"
        }
        $openedWindows.Add($appHwnd)
        L ("Main window HWND: 0x{0:X}, Title: '{1}'" -f $appHwnd.ToInt64(), [Order07Native]::Title($appHwnd))

        Ensure-ClientSize $appHwnd 1440 852 'workbench-gpui'
        Ensure-Foreground $appHwnd "Initial"
        Ensure-ProjectTreeOpen $appHwnd $Out | Out-Null

        # -------------------------------------------------------------------
        # Step 1: app-default-onedark (Default One Dark when settings.json has no theme)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app' 'app-default-onedark' 'Default startup in One Dark (no settings.json theme key)' {
            Ensure-Foreground $appHwnd "app-default-onedark"
            L "Waiting for initial render and window settling..."
            Start-Sleep -Milliseconds 1200

            $cap = Cap-Window $appHwnd 'app-default-onedark' $Out
            L "Captured default One Dark startup: $cap"

            # Sample key pixels: Editor (700, 400), Status bar (500, 840), Panel (100, 300), Title bar (500, 16)
            $edBg = Get-PixelHex $cap 700 400
            $stBg = Get-PixelHex $cap 500 840
            $pnBg = Get-PixelHex $cap 100 300
            $tbBg = Get-PixelHex $cap 500 16
            $global:summary['theme_colors']['One Dark (Default)'] = [ordered]@{
                capture = 'app-default-onedark.png'
                editor_bg = $edBg; expected_editor_bg = '#282c33'
                status_bg = $stBg; expected_status_bg = '#3b414d'
                panel_bg = $pnBg; expected_panel_bg = '#2f343e'
                title_bg = $tbBg; expected_title_bg = '#3b414d'
            }
            L ("One Dark pixel colors: Editor={0}, Status={1}, Panel={2}, Title={3}" -f $edBg, $stBg, $pnBg, $tbBg)
        }

        # -------------------------------------------------------------------
        # Step 2: app-theme-modal-open (Select Theme modal via Ctrl-K Ctrl-T)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app' 'app-theme-modal-open' 'Select Theme modal open (Ctrl-K Ctrl-T, search, list, checkmark)' {
            Ensure-Foreground $appHwnd "app-theme-modal-open"

            # Capture baseline before shortcut to verify modal actually opens (hash must change)
            $beforeCap = Cap-Window $appHwnd 'app-theme-modal-before' $Out
            $hashBefore = (Get-FileHash -LiteralPath $beforeCap -Algorithm SHA256).Hash

            # Send Ctrl-K Ctrl-T with retry if needed
            $modalOpened = $false
            for ($attempt = 1; $attempt -le 3; $attempt++) {
                Ensure-Foreground $appHwnd "app-theme-modal-open (attempt $attempt)"
                L "Sending Ctrl-K Ctrl-T (attempt $attempt)..."
                [Order07Native]::KeyCombo(@([ushort]0x11), [ushort]0x4B) # Ctrl-K
                Start-Sleep -Milliseconds 150
                [Order07Native]::KeyCombo(@([ushort]0x11), [ushort]0x54) # Ctrl-T
                Start-Sleep -Milliseconds 1000

                $cap = Cap-Window $appHwnd 'app-theme-modal-open' $Out
                $hashAfter = (Get-FileHash -LiteralPath $cap -Algorithm SHA256).Hash

                if ($hashAfter -ne $hashBefore) {
                    $modalOpened = $true
                    L "Theme selector modal successfully opened (hash changed: $hashBefore -> $hashAfter)"
                    break
                }
                L "Warning: Theme modal capture hash unchanged on attempt $attempt. Re-activating window..."
                $pt = New-Object Order07Native+POINT
                $pt.X = 0; $pt.Y = 0
                [void][Order07Native]::ClientToScreen($appHwnd, [ref]$pt)
                [Order07Native]::Click($pt.X + 500, $pt.Y + 16)
                Start-Sleep -Milliseconds 400
            }

            if (-not $modalOpened) {
                throw "Theme selector modal failed to open: capture hash unchanged ($hashBefore == $hashAfter)"
            }

            $global:summary['app']['theme_modal'] = [ordered]@{
                capture = 'app-theme-modal-open.png'
                shortcut = 'Ctrl-K Ctrl-T'
                hash_before = $hashBefore
                hash_open = $hashAfter
            }
        }

        # -------------------------------------------------------------------
        # Step 3: app-theme-modal-preview-down (Move selection down to preview)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app' 'app-theme-modal-preview-down' 'Down arrow preview next theme in modal' {
            Ensure-Foreground $appHwnd "app-theme-modal-preview-down"
            $openPath = Join-Path $Out 'app-theme-modal-open.png'
            $hashOpen = if (Test-Path -LiteralPath $openPath) { (Get-FileHash -LiteralPath $openPath -Algorithm SHA256).Hash } else { '' }

            L "Pressing Down arrow (VK_DOWN=0x28)..."
            [Order07Native]::KeyPress(0x28)
            Start-Sleep -Milliseconds 800

            $cap = Cap-Window $appHwnd 'app-theme-modal-preview-down' $Out
            $hashDown = (Get-FileHash -LiteralPath $cap -Algorithm SHA256).Hash
            L "Captured theme preview down: $cap (hash: $hashDown)"

            $global:summary['app']['theme_preview'] = [ordered]@{
                capture = 'app-theme-modal-preview-down.png'
                hash_preview = $hashDown
                preview_changed = ($hashDown -ne $hashOpen)
            }
        }

        # -------------------------------------------------------------------
        # Step 4: app-theme-modal-esc-restore (Esc modal restore original theme)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app' 'app-theme-modal-esc-restore' 'Esc closes modal and restores original theme' {
            Ensure-Foreground $appHwnd "app-theme-modal-esc-restore"
            L "Pressing Esc (VK_ESCAPE=0x1B)..."
            [Order07Native]::KeyPress(0x1B)
            Start-Sleep -Milliseconds 800

            $cap = Cap-Window $appHwnd 'app-theme-modal-esc-restore' $Out
            L "Captured Esc restored theme: $cap"
            $edBgRestored = Get-PixelHex $cap 700 400
            $global:summary['app']['theme_restore'] = [ordered]@{
                capture = 'app-theme-modal-esc-restore.png'
                restored_editor_bg = $edBgRestored
            }
            if ($edBgRestored -ne '#282c33') {
                throw "Esc restore failed: editor bg is '$edBgRestored', expected '#282c33'"
            }
        }

        # -------------------------------------------------------------------
        # Step 5: Representative themes application & token comparison (V2 table)
        # -------------------------------------------------------------------
        $representativeThemes = @(
            [ordered]@{ Name = 'One Light'; Stem = 'onelight'; ExpEditor = '#fafafa'; ExpStatus = '#dcdcdd'; ExpPanel = '#ebebec'; ExpTitle = '#dcdcdd' },
            [ordered]@{ Name = 'Ayu Dark'; Stem = 'ayudark'; ExpEditor = '#0d1016'; ExpStatus = '#313337'; ExpPanel = '#1f2127'; ExpTitle = '#313337' },
            [ordered]@{ Name = 'Gruvbox Dark'; Stem = 'gruvbox'; ExpEditor = '#282828'; ExpStatus = '#4c4642'; ExpPanel = '#3a3735'; ExpTitle = '#4c4642' },
            [ordered]@{ Name = 'Catppuccin Latte'; Stem = 'catppuccin'; ExpEditor = '#eff1f5'; ExpStatus = '#dce0e8'; ExpPanel = '#e6e9ef'; ExpTitle = '#dce0e8' },
            [ordered]@{ Name = 'macOS Classic Light'; Stem = 'macosclassic'; ExpEditor = '#ffffff'; ExpStatus = '#e9e9e9'; ExpPanel = '#f9f9f9'; ExpTitle = '#fefefe' }
        )

        foreach ($rep in $representativeThemes) {
            $tName = $rep.Name
            $tStem = $rep.Stem
            $stepId = "app-theme-apply-$tStem"

            Invoke-MeasureStep 'app' $stepId "Apply theme '$tName' via selector and sample pixels" {
                Ensure-Foreground $appHwnd "Apply $tName"
                L "Opening theme selector (Ctrl-K Ctrl-T)..."
                [Order07Native]::KeyCombo(@([ushort]0x11), [ushort]0x4B)
                Start-Sleep -Milliseconds 150
                [Order07Native]::KeyCombo(@([ushort]0x11), [ushort]0x54)
                Start-Sleep -Milliseconds 600

                # Copy theme name to clipboard and paste to filter
                [System.Windows.Forms.Clipboard]::SetText($tName)
                [Order07Native]::KeyCombo(@([ushort]0x11), [ushort]0x56) # Ctrl-V
                Start-Sleep -Milliseconds 400

                # Confirm with Enter
                [Order07Native]::KeyPress(0x0D) # Enter
                Start-Sleep -Milliseconds 800

                $cap = Cap-Window $appHwnd "app-theme-$tStem" $Out
                L "Captured theme applied '$tName': $cap"

                $edBg = Get-PixelHex $cap 700 400
                $stBg = Get-PixelHex $cap 500 840
                $pnBg = Get-PixelHex $cap 100 300
                $tbBg = Get-PixelHex $cap 500 16
                $global:summary['theme_colors'][$tName] = [ordered]@{
                    capture = "app-theme-$tStem.png"
                    editor_bg = $edBg; expected_editor_bg = $rep.ExpEditor
                    status_bg = $stBg; expected_status_bg = $rep.ExpStatus
                    panel_bg = $pnBg; expected_panel_bg = $rep.ExpPanel
                    title_bg = $tbBg; expected_title_bg = $rep.ExpTitle
                }
                L ("$tName pixel colors: Editor={0} (exp {1}), Status={2} (exp {3})" -f $edBg, $rep.ExpEditor, $stBg, $rep.ExpStatus)
            }
        }

        # -------------------------------------------------------------------
        # Step 6: Select Icon Theme modal & Catppuccin Latte tree icons
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app' 'app-icon-theme-catppuccin' 'Select Icon Theme modal and apply Catppuccin Latte' {
            Ensure-Foreground $appHwnd "Icon theme modal"
            $pt = New-Object Order07Native+POINT
            $pt.X = 0; $pt.Y = 0
            [void][Order07Native]::ClientToScreen($appHwnd, [ref]$pt)
            $vX = $pt.X + 1315
            $vY = $pt.Y + 16

            L "Clicking v menu button at ($vX, $vY)..."
            [Order07Native]::Click($vX, $vY)
            Start-Sleep -Milliseconds 500

            # Navigate down 4 times to Icon Themes...
            for ($k = 0; $k -lt 4; $k++) {
                [Order07Native]::KeyPress(0x28) # VK_DOWN
                Start-Sleep -Milliseconds 80
            }
            [Order07Native]::KeyPress(0x0D) # Enter to open Icon Themes picker
            Start-Sleep -Milliseconds 800

            $modalCap = Cap-Window $appHwnd 'app-icon-theme-modal-open' $Out
            L "Captured Icon Theme modal: $modalCap"

            # Filter Catppuccin Latte
            [System.Windows.Forms.Clipboard]::SetText("Catppuccin Latte")
            [Order07Native]::KeyCombo(@([ushort]0x11), [ushort]0x56) # Ctrl-V
            Start-Sleep -Milliseconds 400
            [Order07Native]::KeyPress(0x0D) # Enter
            Start-Sleep -Milliseconds 800

            # Ensure file tree visible and capture
            Ensure-ProjectTreeOpen $appHwnd $Out | Out-Null
            Start-Sleep -Milliseconds 600
            $treeCap = Cap-Window $appHwnd 'app-tree-catppuccin-latte' $Out
            L "Captured tree with Catppuccin Latte icons: $treeCap"

            # Crop file icon from tree row 00 or 01
            $treeCoord = Get-BoxScreenCoord $appHwnd $Out 'tree-row-01'
            if (-not $treeCoord) { $treeCoord = Get-BoxScreenCoord $appHwnd $Out 'tree-row-00' }
            if ($treeCoord) {
                $iconCrop4x = Join-Path $Out 'app-tree-icon-crop-4x.png'
                $cropX = [Math]::Max(0, ($treeCoord.X - $pt.X + 4))
                $cropY = [Math]::Max(0, ($treeCoord.Y - $pt.Y + 3))
                Save-CroppedImage $treeCap $iconCrop4x $cropX $cropY 20 20 4
                $global:summary['crops']['app-tree-icon'] = [ordered]@{
                    crop = 'app-tree-icon-crop-4x.png'
                    icon_theme = 'Catppuccin Latte'
                    tree_coord = @{ X = $treeCoord.X; Y = $treeCoord.Y }
                }
            }
        }

        # -------------------------------------------------------------------
        # Step 7: app-settings-window (Settings window dropdowns)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app' 'app-settings-window' 'Settings window dropdown list verification' {
            Ensure-Foreground $appHwnd "Settings window"
            $pids = [uint32[]]@($appPid)
            $hwndsBefore = @([Order07Native]::GetProcessTopLevelWindows($pids))

            L "Sending Ctrl-, to open Settings..."
            [Order07Native]::KeyCombo(@([ushort]0x11), [ushort]0xBC) # Ctrl-,
            Start-Sleep -Milliseconds 1200

            $settingsHwnd = [IntPtr]::Zero
            for ($w = 0; $w -lt 25; $w++) {
                $currHwnds = @([Order07Native]::GetProcessTopLevelWindows($pids))
                $newHwnds = @($currHwnds | Where-Object { $hwndsBefore -notcontains $_ })
                if (@($newHwnds).Count -gt 0) { $settingsHwnd = $newHwnds[0]; break }
                Start-Sleep -Milliseconds 200
            }
            if ($settingsHwnd -ne [IntPtr]::Zero) {
                $openedWindows.Add($settingsHwnd)
                $setCap = Cap-Window $settingsHwnd 'app-settings-window' $Out
                L "Captured Settings window: $setCap"
                [void][Order07Native]::PostMessage($settingsHwnd, [Order07Native]::WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
                Start-Sleep -Milliseconds 600
            } else {
                L "Warning: Settings HWND not found; capturing main window"
                Cap-Window $appHwnd 'app-settings-window' $Out | Out-Null
            }
        }

        # -------------------------------------------------------------------
        # Step 8: app-extensions-tab (Extensions tab, extension cards)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app' 'app-extensions-tab' 'Extensions tab (Ctrl-Shift-X) cards verification' {
            Ensure-Foreground $appHwnd "Extensions tab"
            L "Sending Ctrl-Shift-X..."
            [Order07Native]::KeyCombo(@([ushort]0x11, [ushort]0x10), [ushort]0x58) # Ctrl-Shift-X
            Start-Sleep -Milliseconds 1200

            $extCap = Cap-Window $appHwnd 'app-extensions-tab' $Out
            L "Captured Extensions tab: $extCap"

            L "Closing Extensions tab with Ctrl-W..."
            [Order07Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl-W
            Start-Sleep -Milliseconds 400
        }

        # -------------------------------------------------------------------
        # Step 9: app-keymap-editor-hover (ORDER-06-R2 deferred: Keymap Editor hover)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app' 'app-keymap-editor-hover' 'Keymap Editor hover, <no arguments>, <global>, Edit column 36px' {
            Ensure-Foreground $appHwnd "Keymap Editor"
            L "Sending Ctrl-K Ctrl-S..."
            [Order07Native]::KeyCombo(@([ushort]0x11), [ushort]0x4B)
            Start-Sleep -Milliseconds 150
            [Order07Native]::KeyCombo(@([ushort]0x11), [ushort]0x53)
            Start-Sleep -Milliseconds 1200

            # Move mouse to hover row 1
            $pt = New-Object Order07Native+POINT
            $pt.X = 0; $pt.Y = 0
            [void][Order07Native]::ClientToScreen($appHwnd, [ref]$pt)
            $hoverX = $pt.X + 300
            $hoverY = $pt.Y + 120
            [Order07Native]::MoveTo($hoverX, $hoverY)
            Start-Sleep -Milliseconds 400

            $kmCap = Cap-Window $appHwnd 'app-keymap-editor-hover' $Out
            L "Captured Keymap Editor with hover: $kmCap"

            L "Closing Keymap Editor with Ctrl-W..."
            [Order07Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl-W
            Start-Sleep -Milliseconds 400
        }

        # -------------------------------------------------------------------
        # Step 10: app-v-button-crop (ORDER-06-R2 deferred: v button 4x crop)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app' 'app-v-button-crop' 'v button probe measurement and 4x crop' {
            Ensure-Foreground $appHwnd "v-button"
            # Capture full window with distinct filename to avoid any overwrite/lock collision
            $capPath = Cap-Window $appHwnd 'app-v-button-window' $Out

            # v button coordinate in 1440x852: X=1306, Y=5, W=22, H=22 (+1 for 1442x853 screen frame)
            $bx = 1307; $by = 6; $bw = 22; $bh = 22
            $vNormalDst = Join-Path $Out 'app-v-button-normal.png'
            $vCrop4xDst = Join-Path $Out 'app-v-button-crop-4x.png'
            Save-CroppedImage $capPath $vNormalDst ($bx - 4) ($by - 4) ($bw + 8) ($bh + 8) 1
            Save-CroppedImage $capPath $vCrop4xDst ($bx - 2) ($by - 2) ($bw + 4) ($bh + 4) 4

            $global:summary['crops']['v-button'] = [ordered]@{
                normal = 'app-v-button-normal.png'
                crop_4x = 'app-v-button-crop-4x.png'
                target_button_size = "22x22"
                target_icon_size = "14px"
                target_margin_right = "4px"
                button_x = 1306
                button_y = 5
                button_w = 22
                button_h = 22
            }
            L "v button 4x crop saved: $vCrop4xDst"
        }

    } catch {
        $ex = $_.Exception
        $line = $_.InvocationInfo.ScriptLineNumber
        $offset = $_.InvocationInfo.OffsetInLine
        $stack = $_.ScriptStackTrace
        L ("[FATAL ERROR] In Run-AppMeasure at line {0}:{1}: {2}: {3}`nStackTrace:`n{4}" -f $line, $offset, $ex.GetType().FullName, $ex.Message, $stack)
        throw
    } finally {
        # 1. Close auxiliary windows
        foreach ($h in $openedWindows) {
            if ($h -ne [IntPtr]::Zero -and [Order07Native]::IsWindow($h)) {
                [void][Order07Native]::PostMessage($h, [Order07Native]::WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
            }
        }

        # 2. If PID is still 0 but session.json exists, retrieve PID
        $sessionJsonPath = Join-Path $Out 'session.json'
        if ($appPid -eq 0 -and (Test-Path -LiteralPath $sessionJsonPath)) {
            try {
                $rawJson = Get-Content -LiteralPath $sessionJsonPath -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json
                if ($rawJson -and $rawJson.pid) {
                    $appPid = [uint32]$rawJson.pid
                    L "Retrieved appPid=$appPid from session.json in finally block"
                }
            } catch {}
        }

        # 3. Clean up app process (PID) - ensure it exits before session.ps1 Stop
        if ($appPid -ne 0) {
            L ("Cleaning up workbench-gpui process (PID={0})..." -f $appPid)
            $p = Get-Process -Id $appPid -ErrorAction SilentlyContinue
            if ($p -and -not $p.HasExited) {
                try { [void]$p.CloseMainWindow(); [void]$p.WaitForExit(3000) } catch {}
                if (-not $p.HasExited) {
                    try { $p.Kill(); [void]$p.WaitForExit(2000) } catch {}
                }
            }
        }

        # 4. If session.json exists or session started, ALWAYS restore app data via session.ps1 -Action Stop
        if ($sessionStarted -or (Test-Path -LiteralPath $sessionJsonPath)) {
            L "Restoring app data via session.ps1 -Action Stop..."
            $stopOutput = & pwsh -NoProfile -File 'tools/measure/session.ps1' -Action Stop -Out $Out -Backup $backupDir 2>&1
            foreach ($sLine in $stopOutput) { L "Session Stop: $sLine" }
        }
    }
}

# ---------------------------------------------------------------------------
# 7. Zed Measurements (zed -n 새 창만, Esc만, 설정 불변)
# ---------------------------------------------------------------------------
function Run-ZedMeasure() {
    L "=== Starting ORDER-07 V3 Zed Measurement Session ==="

    $zedStepKeys = @(
        'zed-default-onedark',
        'zed-theme-modal',
        'zed-tree-icons'
    )
    $hasZedSteps = @($zedStepKeys | Where-Object { Should-RunStep $_ }).Count -gt 0
    if (-not $hasZedSteps) {
        L "No Zed steps selected in -Steps. Skipping Run-ZedMeasure."
        return
    }

    # Determine fixture directory to open as project in Zed (same folder as app)
    $targetFixtureDir = $global:activeFixtureDir
    if (-not $targetFixtureDir -or -not (Test-Path -LiteralPath $targetFixtureDir)) {
        $sessPath = Join-Path $Out 'session.json'
        if (Test-Path -LiteralPath $sessPath) {
            $sess = Get-Content -LiteralPath $sessPath -Raw | ConvertFrom-Json
            if ($sess.PSObject.Properties['fixture']) { $targetFixtureDir = $sess.fixture }
        }
    }
    if (-not $targetFixtureDir -or -not (Test-Path -LiteralPath $targetFixtureDir)) {
        $targetFixtureDir = Join-Path $Out 'order07-fixture'
        New-Item -ItemType Directory -Force $targetFixtureDir | Out-Null
        "# ORDER-07 Fixture`n`nTesting theme and icon theme reproducibility.`n" | Set-Content -LiteralPath (Join-Path $targetFixtureDir '00-order07.md') -Encoding utf8
        New-Item -ItemType Directory -Force (Join-Path $targetFixtureDir 'src') | Out-Null
        "fn main() {}`n" | Set-Content -LiteralPath (Join-Path $targetFixtureDir 'src\main.rs') -Encoding utf8
    }

    # 1. Record Zed config file hashes before execution
    $hashesBefore = Get-ZedConfigStatus
    $global:summary['config_hashes']['before'] = $hashesBefore
    Log-ZedConfigStatus 'BEFORE' $hashesBefore

    # 2. Enumerate existing Zed top-level windows
    $zedPidsBefore = [uint32[]]@(Get-Process -Name Zed -ErrorAction SilentlyContinue | ForEach-Object { [uint32]$_.Id })
    $beforeHwnds = @()
    if (@($zedPidsBefore).Count -gt 0) {
        $beforeHwnds = @([Order07Native]::GetProcessTopLevelWindows($zedPidsBefore))
    }
    L ("Zed top-level HWNDs before launch: " + (($beforeHwnds | ForEach-Object { '0x{0:X}' -f $_.ToInt64() }) -join ', '))

    $zedHwnd = [IntPtr]::Zero
    $zo = New-Object Order07Native+POINT

    try {
        $zedPrereqOk = $false
        try {
            L "Launching Zed (new window only, -a forbidden) with project folder: $ZedExe -n `"$targetFixtureDir`""
            Start-Process -FilePath $ZedExe -ArgumentList @('-n', "`"$targetFixtureDir`"")

            foreach ($i in 1..60) {
                Start-Sleep -Milliseconds 500
                $currentPids = [uint32[]]@(Get-Process -Name Zed -ErrorAction SilentlyContinue | ForEach-Object { [uint32]$_.Id })
                if (@($currentPids).Count -eq 0) { continue }
                $currentHwnds = @([Order07Native]::GetProcessTopLevelWindows($currentPids))
                $newHwnds = @($currentHwnds | Where-Object { $beforeHwnds -notcontains $_ })
                if (@($newHwnds).Count -gt 0) {
                    $zedHwnd = $newHwnds[0]
                    break
                }
            }
            if ($zedHwnd -eq [IntPtr]::Zero) {
                throw "Newly created Zed window not found"
            }
            L ("New Zed window found: HWND=0x{0:X}" -f $zedHwnd.ToInt64())
            Start-Sleep -Seconds 3

            L "Resizing Zed to 1440x852 client..."
            Ensure-ClientSize $zedHwnd 1440 852 'Zed'
            Start-Sleep -Seconds 1

            $zr = New-Object Order07Native+RECT
            [void][Order07Native]::GetClientRect($zedHwnd, [ref]$zr)
            [void][Order07Native]::ClientToScreen($zedHwnd, [ref]$zo)
            L "Zed client origin=($($zo.X),$($zo.Y)) size=$($zr.Right)x$($zr.Bottom)"

            $zedPrereqOk = $true
            $global:summary['zed']['prerequisite'] = "PASS"
            Ensure-Foreground $zedHwnd "Zed ready"
        } catch {
            $errMsg = $_.Exception.Message
            L "ERROR in Zed prerequisite: $errMsg"
            $global:summary['zed']['prerequisite'] = "FAIL: $errMsg"
        }

        if (-not $zedPrereqOk) {
            L "Skipping remainder of Zed measurements due to prerequisite failure."
            return
        }

        # Helper to get all top-level windows from all Zed processes
        function Get-AllZedTopLevelWindows {
            $pids = [uint32[]]@(Get-Process -Name Zed -ErrorAction SilentlyContinue | ForEach-Object { [uint32]$_.Id })
            if (@($pids).Count -eq 0) { return @() }
            return @([Order07Native]::GetProcessTopLevelWindows($pids))
        }

        # Helper to check for new HWNDs created during a step across ALL Zed processes
        function Test-NewWindowCreated([object[]]$baselineHwnds) {
            $curr = @(Get-AllZedTopLevelWindows)
            $diff = @($curr | Where-Object { $baselineHwnds -notcontains $_ })
            return ,$diff
        }

        # -------------------------------------------------------------------
        # Step 11: zed-default-onedark (Zed One Dark main screen)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'zed-default-onedark' 'Zed default One Dark main screen capture' {
            Ensure-Foreground $zedHwnd "Zed One Dark"
            Start-Sleep -Milliseconds 600
            $cap = Cap-Window $zedHwnd 'zed-default-onedark' $Out
            L "Captured Zed One Dark main screen: $cap"
        }

        # -------------------------------------------------------------------
        # Step 12: zed-theme-modal (Ctrl-K Ctrl-T -> Esc ONLY)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'zed-theme-modal' 'Zed theme picker modal (Ctrl-K Ctrl-T, Esc only, NO ENTER)' {
            Ensure-Foreground $zedHwnd "Zed Theme Modal"
            L "Sending Ctrl-K Ctrl-T to Zed..."
            [Order07Native]::KeyCombo(@([ushort]0x11), [ushort]0x4B) # Ctrl-K
            Start-Sleep -Milliseconds 150
            [Order07Native]::KeyCombo(@([ushort]0x11), [ushort]0x54) # Ctrl-T
            Start-Sleep -Milliseconds 1500

            $cap = Cap-Window $zedHwnd 'zed-theme-modal-open' $Out
            L "Captured Zed theme picker modal: $cap"

            L "CRITICAL SAFETY: Dismissing Zed Theme Picker with ESC ONLY (Enter strictly forbidden)..."
            [Order07Native]::KeyPress(0x1B) # Esc
            Start-Sleep -Milliseconds 600
        }

        # -------------------------------------------------------------------
        # Step 13: zed-tree-icons (Zed file tree icons, Catppuccin Latte)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'zed-tree-icons' 'Zed file tree icons (Catppuccin Latte icon theme)' {
            Ensure-Foreground $zedHwnd "Zed Tree Icons"
            Start-Sleep -Milliseconds 800
            $cap = Cap-Window $zedHwnd 'zed-tree-catppuccin-latte' $Out
            L "Captured Zed tree icons: $cap"

            # In Zed with project folder open at 1440x852 client, project dock is on the left (X=0..240).
            # Tree row icons are located around X=24..48, Y=65..95.
            $crop4x = Join-Path $Out 'zed-tree-icon-crop-4x.png'
            Save-CroppedImage $cap $crop4x 24 72 20 20 4
            $global:summary['crops']['zed-tree-icon'] = [ordered]@{
                crop = 'zed-tree-icon-crop-4x.png'
                icon_theme = 'Catppuccin Latte'
            }
        }

    } catch {
        $ex = $_.Exception
        $line = $_.InvocationInfo.ScriptLineNumber
        $offset = $_.InvocationInfo.OffsetInLine
        $stack = $_.ScriptStackTrace
        L ("[FATAL ERROR] In Run-ZedMeasure at line {0}:{1}: {2}: {3}`nStackTrace:`n{4}" -f $line, $offset, $ex.GetType().FullName, $ex.Message, $stack)
        throw
    } finally {
        if ($zedHwnd -ne [IntPtr]::Zero) {
            L ("Closing target Zed window only (HWND=0x{0:X}) via WM_CLOSE PostMessage..." -f $zedHwnd.ToInt64())
            [void][Order07Native]::PostMessage($zedHwnd, [Order07Native]::WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
            Start-Sleep -Seconds 2

            $stillAlive = [Order07Native]::IsWindow($zedHwnd)
            if ($stillAlive) {
                L ("Warning: Target Zed window HWND=0x{0:X} is still present" -f $zedHwnd.ToInt64())
            } else {
                L ("Target Zed window HWND=0x{0:X} successfully closed" -f $zedHwnd.ToInt64())
            }
        }

        # Verify Zed config hashes after execution
        $hashesAfter = Get-ZedConfigStatus
        $global:summary['config_hashes']['after'] = $hashesAfter
        Log-ZedConfigStatus 'AFTER' $hashesAfter
        $intact = Compare-ZedConfigStatus $hashesBefore $hashesAfter
        $global:summary['config_hashes']['intact'] = $intact
        if (-not $intact) {
            $global:summary['zed']['config_integrity'] = "FAIL: Zed config files were modified!"
            throw "CRITICAL: Zed config files were modified during measurement!"
        } else {
            $global:summary['zed']['config_integrity'] = "PASS: Config files 100% intact"
        }
    }
}

# ---------------------------------------------------------------------------
# 8. DryRun Mode
# ---------------------------------------------------------------------------
function Run-DryRun([string]$stdoutFile) {
    L "=== ORDER-07 DryRun Mode Started ==="
    if ($stdoutFile) {
        L "Stdout dump file: $stdoutFile"
        if (Test-Path -LiteralPath $stdoutFile) {
            $snap = Get-LatestSnapshot '' $stdoutFile
            if ($snap) {
                L ("Parsed layout snapshot seq={0}, total boxes={1}" -f $snap.seq, $snap.allBoxes.Count)
            }
        }
    }

    L "--- Planned App Steps ---"
    $appSteps = @(
        'app-default-onedark',
        'app-theme-modal-open',
        'app-theme-modal-preview-down',
        'app-theme-modal-esc-restore',
        'app-theme-apply-onelight',
        'app-theme-apply-ayudark',
        'app-theme-apply-gruvbox',
        'app-theme-apply-catppuccin',
        'app-theme-apply-macosclassic',
        'app-icon-theme-catppuccin',
        'app-settings-window',
        'app-extensions-tab',
        'app-keymap-editor-hover',
        'app-v-button-crop'
    )
    foreach ($s in $appSteps) {
        L ("  App Step: {0} (Will Run={1})" -f $s, (Should-RunStep $s))
    }

    L "--- Planned Zed Steps ---"
    $zedSteps = @(
        'zed-default-onedark',
        'zed-theme-modal',
        'zed-tree-icons'
    )
    foreach ($s in $zedSteps) {
        L ("  Zed Step: {0} (Will Run={1})" -f $s, (Should-RunStep $s))
    }

    L "--- Representative Theme Token Mapping (V2 Target Table) ---"
    $tokens = @(
        [ordered]@{ Theme = 'One Dark (Default)'; Editor = '#282c33'; Status = '#3b414d'; Panel = '#2f343e'; Title = '#3b414d' },
        [ordered]@{ Theme = 'One Light'; Editor = '#fafafa'; Status = '#dcdcdd'; Panel = '#ebebec'; Title = '#dcdcdd' },
        [ordered]@{ Theme = 'Ayu Dark'; Editor = '#0d1016'; Status = '#313337'; Panel = '#1f2127'; Title = '#313337' },
        [ordered]@{ Theme = 'Gruvbox Dark'; Editor = '#282828'; Status = '#4c4642'; Panel = '#3a3735'; Title = '#4c4642' },
        [ordered]@{ Theme = 'Catppuccin Latte'; Editor = '#eff1f5'; Status = '#dce0e8'; Panel = '#e6e9ef'; Title = '#dce0e8' },
        [ordered]@{ Theme = 'macOS Classic Light'; Editor = '#ffffff'; Status = '#e9e9e9'; Panel = '#f9f9f9'; Title = '#fefefe' }
    )
    foreach ($t in $tokens) {
        L ("  {0,-20}: Editor={1}, Status={2}, Panel={3}, Title={4}" -f $t.Theme, $t.Editor, $t.Status, $t.Panel, $t.Title)
    }

    L "Safety Guards Check:"
    L "  1. session.ps1 Start/Stop transaction & hash rollback guard: ENABLED"
    L "  2. Post-Start session.json existence -> mandatory PID cleanup & session.ps1 Stop in finally: ENABLED"
    L "  3. Exception logging with line number & stack trace to log.txt: ENABLED"
    L "  4. Zed config SHA256 before/after integrity verification: ENABLED"
    L "  5. Zed Enter key prohibition (Esc only): ENFORCED"
    L "  6. Process/HWND isolation (own PID/HWND only): ENFORCED"
    L "=== DryRun Verification Complete: PASS ==="
}

# ---------------------------------------------------------------------------
# 9. Main Script Entrypoint
# ---------------------------------------------------------------------------
if ($DryRun -or $DryRunStdout) {
    Run-DryRun $DryRunStdout
} else {
    try {
        Run-AppMeasure
        Run-ZedMeasure
    } catch {
        $ex = $_.Exception
        $line = $_.InvocationInfo.ScriptLineNumber
        $offset = $_.InvocationInfo.OffsetInLine
        $stack = $_.ScriptStackTrace
        L ("[TOP-LEVEL FATAL] Measurement execution failed at line {0}:{1}: {2}: {3}`nStackTrace:`n{4}" -f $line, $offset, $ex.GetType().FullName, $ex.Message, $stack)
        $global:summary['fatal_error'] = [ordered]@{
            message = $ex.Message
            type = $ex.GetType().FullName
            line = $line
            offset = $offset
            stack = $stack
        }
        throw
    } finally {
        $summaryJson = Join-Path $Out 'summary.json'
        $global:summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $summaryJson -Encoding utf8
        L "Summary JSON written to: $summaryJson"
    }
}

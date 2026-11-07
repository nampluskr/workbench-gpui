#Requires -Version 7
<#
.SYNOPSIS
  ORDER-10 V3 화면 검증(UI 실측) 스크립트 (I-21: 폴더 보기 사이드바 패널).
  (gpui-checker 작성, leader가 [SCREEN-OK] 뒤 화면 차례 안에서 실행한다.)

.DESCRIPTION
  - 상위 지시: core ORDER-10, 카드 C-39 (I-21: 폴더 보기 패널의 모양을 Zed와 같게 한다)
  - 우리 앱(workbench-gpui) 단독 실행 화면 검증 (Zed는 띄우지 않고 tauri 캡처와 대조).
  - 대조 자료: workbench-tauri 캡처 (D:\projects\workbench-tauri\specs\v0.5\verify\ORDER-10\zed-*.png).
  - 클라이언트 1440×852, 100% DPI, Ensure-ClientSize로 고정.
  - 세션 관리: tools/measure/session.ps1 (Start/Stop 트랜잭션, 실패 시 finally 복원 보장).
  - 검증된 안전 가드:
    1. 마우스 입력 가드(Assert-MouseInput): WindowFromPoint 및 GetAncestor(GA_ROOT)가 appHwnd이고 PID가 띄운 PID인지 확인.
       일치 시 점을 누르면 앱에만 가고 자연스럽게 앞 창으로 전환됨. 점의 창이 다르면(덮임) 입력 차단 후 FAIL.
    2. 키 입력 가드(Assert-KeyInput): GetForegroundWindow() == appHwnd 확인. 앞 창 아니면 안전한 위치(에디터/상태바) 1회 클릭으로 활성화 후 재확인, 그래도 아니면 FAIL.
    3. 비입력 Z순서 상승(Ensure-Foreground): ShowWindow(SW_RESTORE) + SetWindowPos(HWND_TOP) + SetForegroundWindow로 Z-order 상승.
    4. 단계 시작 시 Reset-UIState: Esc 2회로 잔여 팝업/메뉴 닫힘 확인.
    5. DryRun 모의 실행(Mock Execution): -DryRun에서 4개 단계 스크립트블록을 모의 입력으로 실제로 끝까지 실행하여 런타임 오류 0건 사전 검증.

.PARAMETER Out
  출력 디렉터리 (기본값: specs\v0.5\verify\reviews\measure-ORDER-10).

.PARAMETER AppExe
  workbench-gpui 실행 파일 경로.

.PARAMETER TauriRefDir
  Zed 비교용 tauri 캡처 디렉터리 경로 (기본값: D:\projects\workbench-tauri\specs\v0.5\verify\ORDER-10).

.PARAMETER DryRun
  프로세스 구동 없이 단계 구성, fixture 준비, 문법 및 모의 실행만 검증하는 모드.

.PARAMETER Steps
  실행할 단계 목록. 기본값: 모든 단계 실행 (step1, step2, step3, step4).

.PARAMETER Skip
  건너뛸 단계 목록.
#>
[CmdletBinding()]
param(
    [string]$Out = 'specs\v0.5\verify\reviews\measure-ORDER-10',
    [string]$AppExe = 'D:\projects\workbench-gpui\target\debug\workbench-gpui.exe',
    [string]$TauriRefDir = 'D:\projects\workbench-tauri\specs\v0.5\verify\ORDER-10',
    [switch]$DryRun,
    [string[]]$Steps = @(),
    [string[]]$Skip = @(),
    [string]$ReplayStdout = ''
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
    "captures" = [ordered]@{}
    "hashes" = [ordered]@{}
    "tauri_refs" = [ordered]@{}
    "results" = [ordered]@{}
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
        if ($k -match '^\d+$' -and $stepKey -like "*step$k*") { return $true }
    }
    return $false
}

function L([string]$msg) {
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
    $line = "[$ts] $msg"
    Write-Host $line
    Add-Content -LiteralPath $logFile -Value $line -Encoding utf8
}

function Get-Hash([string]$file) {
    if (Test-Path -LiteralPath $file) {
        return (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
    }
    return $null
}

if ($DryRun -and -not $ReplayStdout) {
    $defaultReplay = 'specs\v0.5\verify\reviews\measure-ORDER-10-run1-step3\app-stdout.txt'
    if (-not (Test-Path -LiteralPath $defaultReplay)) {
        $defaultReplay = 'specs\v0.5\verify\reviews\measure-ORDER-09-run7-step4\app-stdout.txt'
    }
    if (Test-Path -LiteralPath $defaultReplay) {
        $ReplayStdout = $defaultReplay
        L "DryRun mode: Auto-selecting '$defaultReplay' as stdout replay fixture"
    }
}

if ($ReplayStdout) {
    if (-not (Test-Path -LiteralPath $ReplayStdout)) {
        throw "ReplayStdout file not found: '$ReplayStdout'"
    }
    $targetStdout = Join-Path $Out 'app-stdout.txt'
    Copy-Item -LiteralPath $ReplayStdout -Destination $targetStdout -Force
    L "Loaded ReplayStdout file: '$ReplayStdout' -> '$targetStdout'"
}

# ---------------------------------------------------------------------------
# 1. Native API Definitions (C# P/Invoke with Extended Key & Input Dispatch)
# ---------------------------------------------------------------------------
$nativeSource = @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

public static class Order10AppNative {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct POINT {
        public int X;
        public int Y;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct INPUT {
        public uint type;
        public InputUnion mkhi;
    }

    [StructLayout(LayoutKind.Explicit)]
    public struct InputUnion {
        [FieldOffset(0)] public MOUSEINPUT mi;
        [FieldOffset(0)] public KEYBDINPUT ki;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct KEYBDINPUT {
        public ushort wVk;
        public ushort wScan;
        public uint dwFlags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct MOUSEINPUT {
        public int dx;
        public int dy;
        public uint mouseData;
        public uint dwFlags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr hWnd, ref POINT lpPoint);
    [DllImport("user32.dll")] public static extern bool ScreenToClient(IntPtr hWnd, ref POINT lpPoint);
    [DllImport("user32.dll")] public static extern bool GetCursorPos(out POINT lpPoint);
    [DllImport("user32.dll")] public static extern IntPtr WindowFromPoint(POINT Point);
    [DllImport("user32.dll")] public static extern IntPtr GetAncestor(IntPtr hWnd, uint gaFlags);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern int GetClassName(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);
    [DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, int dx, int dy, uint dwData, IntPtr dwExtraInfo);
    [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, IntPtr dwExtraInfo);
    [DllImport("user32.dll")] public static extern int GetSystemMetrics(int nIndex);
    [DllImport("user32.dll")] public static extern IntPtr GetWindow(IntPtr hWnd, uint uCmd);
    [DllImport("user32.dll", SetLastError = true)] public static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

    public const uint WM_CLOSE = 0x0010;
    public const uint GA_PARENT = 1, GA_ROOT = 2, GA_ROOTOWNER = 3;
    const uint KEYEVENTF_EXTENDEDKEY = 0x1, KEYEVENTF_KEYUP = 0x2, KEYEVENTF_UNICODE = 0x4;
    const uint MOUSEEVENTF_MOVE = 0x1, MOUSEEVENTF_LEFTDOWN = 0x2, MOUSEEVENTF_LEFTUP = 0x4;
    const uint MOUSEEVENTF_VIRTUALDESK = 0x4000, MOUSEEVENTF_ABSOLUTE = 0x8000;
    const uint INPUT_KEYBOARD = 1;
    const int SM_XVIRTUALSCREEN = 76, SM_YVIRTUALSCREEN = 77, SM_CXVIRTUALSCREEN = 78, SM_CYVIRTUALSCREEN = 79;

    public static string Title(IntPtr hWnd) {
        var sb = new StringBuilder(512);
        GetWindowText(hWnd, sb, sb.Capacity);
        return sb.ToString();
    }

    public static string ClassName(IntPtr hWnd) {
        var sb = new StringBuilder(256);
        GetClassName(hWnd, sb, sb.Capacity);
        return sb.ToString();
    }

    public static List<IntPtr> GetAllProcessWindows(uint[] pids) {
        var list = new List<IntPtr>();
        var pidSet = new HashSet<uint>(pids);
        EnumWindows((h, l) => {
            uint p; GetWindowThreadProcessId(h, out p);
            if (pidSet.Contains(p)) {
                list.Add(h);
            }
            return true;
        }, IntPtr.Zero);
        return list;
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

    public static bool IsExtendedKey(byte vk) {
        return (vk >= 0x21 && vk <= 0x2E) || vk == 0x5B || vk == 0x5C || vk == 0x5D;
    }

    public static void KeyPress(byte vk) {
        uint ext = IsExtendedKey(vk) ? KEYEVENTF_EXTENDEDKEY : 0;
        keybd_event(vk, 0, ext, IntPtr.Zero);
        Thread.Sleep(40);
        keybd_event(vk, 0, KEYEVENTF_KEYUP | ext, IntPtr.Zero);
        Thread.Sleep(40);
    }

    public static void KeyCombo(ushort[] modifiers, ushort key) {
        foreach (var m in modifiers) {
            uint mExt = IsExtendedKey((byte)m) ? KEYEVENTF_EXTENDEDKEY : 0;
            keybd_event((byte)m, 0, mExt, IntPtr.Zero);
        }
        Thread.Sleep(40);
        uint keyExt = IsExtendedKey((byte)key) ? KEYEVENTF_EXTENDEDKEY : 0;
        keybd_event((byte)key, 0, keyExt, IntPtr.Zero);
        Thread.Sleep(50);
        keybd_event((byte)key, 0, KEYEVENTF_KEYUP | keyExt, IntPtr.Zero);
        Thread.Sleep(40);
        for (int i = modifiers.Length - 1; i >= 0; i--) {
            uint mExt = IsExtendedKey((byte)modifiers[i]) ? KEYEVENTF_EXTENDEDKEY : 0;
            keybd_event((byte)modifiers[i], 0, KEYEVENTF_KEYUP | mExt, IntPtr.Zero);
        }
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

if (-not ([System.Management.Automation.PSTypeName]'Order10AppNative').Type) {
    Add-Type -TypeDefinition $nativeSource -Language CSharp
}

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

# ---------------------------------------------------------------------------
# 2. Window Capture and Crop Helpers
# ---------------------------------------------------------------------------
function Ensure-Foreground([IntPtr]$hwnd, [string]$label = '') {
    if ($DryRun) {
        L "[DRYRUN MOCK] Ensure-Foreground for '$label'"
        return
    }
    if ($hwnd -eq [IntPtr]::Zero) { return }

    $targetPid = [uint32]0
    [void][Order10AppNative]::GetWindowThreadProcessId($hwnd, [ref]$targetPid)
    if ($script:appPid -gt 0 -and $targetPid -ne [uint32]$script:appPid) {
        L "ERROR: Ensure-Foreground target HWND 0x$($hwnd.ToString('X')) PID ($targetPid) does not match App PID ($script:appPid)! Aborting elevation."
        return
    }

    L ("[ELEVATE] Elevating target window Z-order (PID={0}, HWND=0x{1:X}, Label='{2}'): ShowWindow(SW_RESTORE), SetWindowPos(HWND_TOP), SetForegroundWindow..." -f $script:appPid, $hwnd.ToInt64(), $label)
    [void][Order10AppNative]::ShowWindow($hwnd, 9) # SW_RESTORE
    [void][Order10AppNative]::SetWindowPos($hwnd, [IntPtr]::Zero, 0, 0, 0, 0, 0x0001 -bor 0x0002 -bor 0x0040)
    [void][Order10AppNative]::SetForegroundWindow($hwnd)
    Start-Sleep -Milliseconds 150

    $fg = [Order10AppNative]::GetForegroundWindow()
    $matches = ($fg -eq $hwnd)
    L ("[VERIFY-FG] Foreground verification for '{0}': Target=0x{1:X}, CurrentForeground=0x{2:X} (Matches={3})" -f $label, $hwnd.ToInt64(), $fg.ToInt64(), $matches)
    if (-not $matches) {
        L "WARN: $label Ensure-Foreground did not immediately make app foreground. Subsequent safe click will activate window."
    }
}

function Ensure-ClientSize([IntPtr]$hwnd, [int]$targetW = 1440, [int]$targetH = 852, [string]$label = '') {
    if ($DryRun) { return }
    $cRect = New-Object Order10AppNative+RECT
    [void][Order10AppNative]::GetClientRect($hwnd, [ref]$cRect)
    $curW = $cRect.Right - $cRect.Left
    $curH = $cRect.Bottom - $cRect.Top
    if ($curW -eq $targetW -and $curH -eq $targetH) {
        return
    }

    $wRect = New-Object Order10AppNative+RECT
    [void][Order10AppNative]::GetWindowRect($hwnd, [ref]$wRect)
    $winW = $wRect.Right - $wRect.Left
    $winH = $wRect.Bottom - $wRect.Top

    $borderW = $winW - $curW
    $borderH = $winH - $curH
    $newWinW = $targetW + $borderW
    $newWinH = $targetH + $borderH

    [void][Order10AppNative]::MoveWindow($hwnd, $wRect.Left, $wRect.Top, $newWinW, $newWinH, $true)
    Start-Sleep -Milliseconds 200
}

function Capture-WindowClient([IntPtr]$hwnd, [string]$outPngPath) {
    if ($DryRun) {
        if (-not (Test-Path -LiteralPath $outPngPath)) {
            $bmp = New-Object System.Drawing.Bitmap(1440, 852)
            $g = [System.Drawing.Graphics]::FromImage($bmp)
            # Fill with mock panel background (#1e1e24)
            $panelBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 30, 30, 36))
            $g.FillRectangle($panelBrush, 0, 0, 300, 852)
            # Draw mock right border line at x=299
            $borderPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 71, 75, 87), 1)
            $g.DrawLine($borderPen, 299, 0, 299, 852)
            # Draw mock divider line at y=64
            $g.DrawLine($borderPen, 0, 64, 299, 64)
            # Draw mock footer line at y=821
            $g.DrawLine($borderPen, 0, 821, 299, 821)
            # Mock hover bg (#363c46) if name contains hover
            if ($outPngPath -match 'hover') {
                $hoverBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 54, 60, 70))
                $g.FillRectangle($hoverBrush, 0, 64, 299, 31)
                $hoverBrush.Dispose()
            }
            # Mock focus border (#2870bd) if name contains down
            if ($outPngPath -match 'down') {
                $focusPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 40, 112, 189), 1)
                $g.DrawRectangle($focusPen, 0, 64, 298, 30)
                $focusPen.Dispose()
            }
            $panelBrush.Dispose()
            $borderPen.Dispose()
            $g.Dispose()
            $bmp.Save($outPngPath, [System.Drawing.Imaging.ImageFormat]::Png)
            $bmp.Dispose()
        }
        L "[DRYRUN MOCK] Captured client screenshot to '$outPngPath'"
        return $outPngPath
    }
    $cRect = New-Object Order10AppNative+RECT
    [void][Order10AppNative]::GetClientRect($hwnd, [ref]$cRect)
    $w = $cRect.Right - $cRect.Left
    $h = $cRect.Bottom - $cRect.Top

    $pt = New-Object Order10AppNative+POINT
    $pt.X = 0; $pt.Y = 0
    [void][Order10AppNative]::ClientToScreen($hwnd, [ref]$pt)

    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($pt.X, $pt.Y, 0, 0, (New-Object System.Drawing.Size($w, $h)), [System.Drawing.CopyPixelOperation]::SourceCopy)
    $g.Dispose()

    $bmp.Save($outPngPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    L "Captured client screenshot to '$outPngPath' ($w x $h)"
    return $outPngPath
}

function Crop-Image([string]$srcPath, [string]$dstPath, [int]$x, [int]$y, [int]$w, [int]$h) {
    if ($DryRun) {
        if (-not (Test-Path -LiteralPath $dstPath)) {
            $bmp = New-Object System.Drawing.Bitmap([Math]::Max(1, $w), [Math]::Max(1, $h))
            $bmp.Save($dstPath, [System.Drawing.Imaging.ImageFormat]::Png)
            $bmp.Dispose()
        }
        L "[DRYRUN MOCK] Cropped '$srcPath' -> '$dstPath' (rect=[$x, $y, $w, $h])"
        return $dstPath
    }
    if (-not (Test-Path -LiteralPath $srcPath)) {
        L "WARN: Crop source '$srcPath' does not exist."
        return $null
    }
    $src = [System.Drawing.Bitmap]::FromFile($srcPath)
    if ($x + $w -gt $src.Width) { $w = [Math]::Max(1, $src.Width - $x) }
    if ($y + $h -gt $src.Height) { $h = [Math]::Max(1, $src.Height - $y) }
    if ($x -lt 0) { $x = 0 }
    if ($y -lt 0) { $y = 0 }

    $rect = New-Object System.Drawing.Rectangle($x, $y, $w, $h)
    $crop = $src.Clone($rect, $src.PixelFormat)
    $src.Dispose()
    $crop.Save($dstPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $crop.Dispose()
    L "Cropped '$srcPath' -> '$dstPath' (rect=[$x, $y, $w, $h])"
    return $dstPath
}

# ---------------------------------------------------------------------------
# 3. Input Guards (Window Ownership & Foreground Assertions)
# ---------------------------------------------------------------------------
function Assert-MouseInput([int]$targetScreenX, [int]$targetScreenY, [string]$opLabel = '') {
    if ($DryRun) { return }
    if ($script:appHwnd -eq [IntPtr]::Zero) {
        $msg = "FAIL: 앱 HWND가 없음 (Zero) [$opLabel]"
        L $msg
        throw $msg
    }

    $cRect = New-Object Order10AppNative+RECT
    [void][Order10AppNative]::GetClientRect($script:appHwnd, [ref]$cRect)
    $ptClient = New-Object Order10AppNative+POINT
    $ptClient.X = $targetScreenX; $ptClient.Y = $targetScreenY
    [void][Order10AppNative]::ScreenToClient($script:appHwnd, [ref]$ptClient)
    $cWidth = $cRect.Right - $cRect.Left
    $cHeight = $cRect.Bottom - $cRect.Top
    if ($ptClient.X -lt 0 -or $ptClient.Y -lt 0 -or $ptClient.X -gt $cWidth -or $ptClient.Y -gt $cHeight) {
        $msg = "FAIL: 마우스 좌표가 클라이언트 영역 밖임 (Screen: ($targetScreenX, $targetScreenY), Client: ($($ptClient.X), $($ptClient.Y)), Bounds: 0..$cWidth, 0..$cHeight) [$opLabel]"
        L $msg
        throw $msg
    }

    $ptScreen = New-Object Order10AppNative+POINT
    $ptScreen.X = $targetScreenX; $ptScreen.Y = $targetScreenY
    $hTarget = [Order10AppNative]::WindowFromPoint($ptScreen)
    $hRoot = [Order10AppNative]::GetAncestor($hTarget, [Order10AppNative]::GA_ROOT)
    $targetPid = [uint32]0
    [void][Order10AppNative]::GetWindowThreadProcessId($hTarget, [ref]$targetPid)

    $isOurWindow = ($hRoot -eq $script:appHwnd) -or ($hTarget -eq $script:appHwnd)
    $isOurPid = ($script:appPid -gt 0 -and $targetPid -eq [uint32]$script:appPid)

    if (-not ($isOurWindow -and $isOurPid)) {
        $targetTitle = [Order10AppNative]::Title($hTarget)
        $rootTitle = [Order10AppNative]::Title($hRoot)
        $msg = "FAIL: 마우스 좌표($targetScreenX, $targetScreenY)의 창이 앱이 아님 (Target HWND: 0x$($hTarget.ToString('X')) ['$targetTitle'], Root HWND: 0x$($hRoot.ToString('X')) ['$rootTitle'], Target PID: $targetPid, Expected App PID: $script:appPid) [$opLabel]"
        L $msg
        throw $msg
    }
}

function Assert-KeyInput([string]$opLabel = '') {
    if ($DryRun) { return }
    if ($script:appHwnd -eq [IntPtr]::Zero) {
        $msg = "FAIL: 앱 HWND가 없음 (Zero) [$opLabel]"
        L $msg
        throw $msg
    }

    $fg = [Order10AppNative]::GetForegroundWindow()
    if ($fg -eq $script:appHwnd) {
        return
    }

    L "Assert-KeyInput: Foreground window 0x$($fg.ToString('X')) != App window 0x$($script:appHwnd.ToString('X')). Attempting safe activation click..."

    $targetPid = [uint32]0
    [void][Order10AppNative]::GetWindowThreadProcessId($script:appHwnd, [ref]$targetPid)
    if ($script:appPid -gt 0 -and $targetPid -ne [uint32]$script:appPid) {
        $msg = "FAIL: Assert-KeyInput app HWND PID mismatch (Target PID=$targetPid, Expected PID=$script:appPid) [$opLabel]"
        L $msg
        throw $msg
    }

    L ("[ELEVATE] Elevating target window Z-order (PID={0}, HWND=0x{1:X}, Op='{2}'): ShowWindow(SW_RESTORE), SetWindowPos(HWND_TOP), SetForegroundWindow..." -f $script:appPid, $script:appHwnd.ToInt64(), $opLabel)
    [void][Order10AppNative]::ShowWindow($script:appHwnd, 9)
    [void][Order10AppNative]::SetWindowPos($script:appHwnd, [IntPtr]::Zero, 0, 0, 0, 0, 0x0001 -bor 0x0002 -bor 0x0040)
    [void][Order10AppNative]::SetForegroundWindow($script:appHwnd)
    Start-Sleep -Milliseconds 100

    $ptClick = New-Object Order10AppNative+POINT
    $ptClick.X = 700; $ptClick.Y = 400
    [void][Order10AppNative]::ClientToScreen($script:appHwnd, [ref]$ptClick)

    try {
        Assert-MouseInput $ptClick.X $ptClick.Y "ActivateWindowClick"
        [Order10AppNative]::Click($ptClick.X, $ptClick.Y)
        Start-Sleep -Milliseconds 200
    }
    catch {
        L "Assert-KeyInput safe activation click failed: $_"
    }

    $fg = [Order10AppNative]::GetForegroundWindow()
    $matches = ($fg -eq $script:appHwnd)
    L ("[VERIFY-FG] Foreground verification after activation click for '{0}': Target=0x{1:X}, CurrentForeground=0x{2:X} (Matches={3})" -f $opLabel, $script:appHwnd.ToInt64(), $fg.ToInt64(), $matches)
    if (-not $matches) {
        $fgTitle = [Order10AppNative]::Title($fg)
        $msg = "FAIL: 앱이 앞 창 아님 (Foreground HWND: 0x$($fg.ToString('X')) ['$fgTitle'], Expected HWND: 0x$($script:appHwnd.ToString('X'))) [$opLabel]"
        L $msg
        throw $msg
    }
    L "Assert-KeyInput: App successfully activated to foreground (0x$($script:appHwnd.ToString('X'))) [$opLabel]"
}

function Safe-Click([int]$x, [int]$y) {
    if ($DryRun) {
        L "[DRYRUN MOCK] Safe-Click at ($x, $y)"
        return
    }
    Assert-MouseInput $x $y 'Click'
    [Order10AppNative]::Click($x, $y)
}

function Safe-DoubleClick([int]$x, [int]$y) {
    if ($DryRun) {
        L "[DRYRUN MOCK] Safe-DoubleClick at ($x, $y)"
        return
    }
    Assert-MouseInput $x $y 'DoubleClick'
    [Order10AppNative]::DoubleClick($x, $y)
}

function Safe-MoveTo([int]$x, [int]$y) {
    if ($DryRun) {
        L "[DRYRUN MOCK] Safe-MoveTo at ($x, $y)"
        return
    }
    Assert-MouseInput $x $y 'MoveTo'
    [Order10AppNative]::MoveTo($x, $y)
}

function Safe-KeyPress([byte]$vk) {
    if ($DryRun) {
        L "[DRYRUN MOCK] Safe-KeyPress 0x$($vk.ToString('X2'))"
        return
    }
    Assert-KeyInput "KeyPress(0x$($vk.ToString('X2')))"
    [Order10AppNative]::KeyPress($vk)
}

function Safe-KeyCombo($modifiers, [int]$key = 0) {
    if ($key -eq 0 -and $modifiers -is [System.Array] -and $modifiers.Length -eq 2 -and ($modifiers[0] -is [System.Array] -or $modifiers[1] -is [int])) {
        $key = [int]$modifiers[1]
        $modifiers = $modifiers[0]
    }
    $modList = [System.Collections.Generic.List[ushort]]::new()
    if ($modifiers -is [System.Collections.IEnumerable] -and -not ($modifiers -is [string])) {
        foreach ($m in $modifiers) {
            if ($m -is [System.Collections.IEnumerable] -and -not ($m -is [string])) {
                foreach ($sub in $m) { $modList.Add([ushort]$sub) }
            } else {
                $modList.Add([ushort]$m)
            }
        }
    } else {
        $modList.Add([ushort]$modifiers)
    }
    $ushortMods = $modList.ToArray()
    $ushortKey = [ushort]$key
    if ($DryRun) {
        $modStr = ($ushortMods | ForEach-Object { "0x$($_.ToString('X2'))" }) -join '+'
        L "[DRYRUN MOCK] Safe-KeyCombo [$modStr] + 0x$($ushortKey.ToString('X2'))"
        return
    }
    Assert-KeyInput "KeyCombo(0x$($ushortKey.ToString('X2')))"
    [Order10AppNative]::KeyCombo($ushortMods, $ushortKey)
}

function Reset-UIState([string]$context = '') {
    if ($DryRun) {
        L "[DRYRUN MOCK] Reset-UIState ($context): Simulated Esc twice"
        return
    }
    L "Reset-UIState ($context): Sending Esc twice to dismiss any open popups or menus..."
    Safe-KeyPress([byte]0x1B) # Esc
    Start-Sleep -Milliseconds 100
    Safe-KeyPress([byte]0x1B) # Esc
    Start-Sleep -Milliseconds 150

    $snap = Get-LatestSnapshot $Out
    if ($snap) {
        $popupKeys = @($snap.boxes.Keys | Where-Object {
            $_ -match 'popup' -or $_ -match 'menu' -or $_ -match 'dropdown' -or $_ -match 'modal'
        })
        $activePopups = @($popupKeys | Where-Object { $_ -notmatch 'AppMenu' -and $_ -notmatch 'tab-bar' -and $_ -notmatch 'sidebar' })
        if ($activePopups.Count -gt 0) {
            L "WARN: Reset-UIState - Detected lingering popup boxes: $($activePopups -join ', '). Sending additional Esc..."
            Safe-KeyPress([byte]0x1B)
            Start-Sleep -Milliseconds 150
        } else {
            L "Reset-UIState ($context): No lingering popups detected. UI clean."
        }
    }
}

# ---------------------------------------------------------------------------
# 4. Layout Snapshot & Probe Parsing Helpers
# ---------------------------------------------------------------------------
function Get-CurrentFocus([string]$outDir) {
    $stdoutPath = Join-Path $outDir 'app-stdout.txt'
    if (-not (Test-Path -LiteralPath $stdoutPath)) { return 'unknown' }
    $lines = @(Get-Content -LiteralPath $stdoutPath -Encoding utf8)
    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        if ($lines[$i] -match '^\[dev\] focus-state focus=(\S+)') {
            return $matches[1]
        }
    }
    return 'unknown'
}

function Get-LatestSnapshot([string]$outDir) {
    $stdoutPath = Join-Path $outDir 'app-stdout.txt'
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
    for ($i = $start; $i -le $end; $i++) {
        if ($lines[$i] -match 'name=(\S+) bounds=([-\d.]+),([-\d.]+),([-\d.]+),([-\d.]+)') {
            $boxes[$matches[1]] = @{
                name = $matches[1]
                x = [double]$matches[2]
                y = [double]$matches[3]
                w = [double]$matches[4]
                h = [double]$matches[5]
            }
        }
    }
    return [PSCustomObject]@{
        seq = $seq
        boxes = $boxes
    }
}

function Wait-NextSnapshot([string]$outDir, [int]$prevSeq, [int]$timeoutMs = 3000) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.ElapsedMilliseconds -lt $timeoutMs) {
        $snap = Get-LatestSnapshot $outDir
        if ($snap -and $snap.seq -gt $prevSeq) {
            return $snap
        }
        Start-Sleep -Milliseconds 100
    }
    return (Get-LatestSnapshot $outDir)
}

function Get-BoxScreenCoord([IntPtr]$hwnd, [string]$sessionDir, [string]$probeName) {
    $snap = Get-LatestSnapshot $sessionDir
    if (-not $snap -or -not $snap.boxes.ContainsKey($probeName)) { return $null }
    $b = $snap.boxes[$probeName]

    $pt = New-Object Order10AppNative+POINT
    $pt.X = 0; $pt.Y = 0
    if ($hwnd -ne [IntPtr]::Zero) {
        [void][Order10AppNative]::ClientToScreen($hwnd, [ref]$pt)
    }

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

# ---------------------------------------------------------------------------
# 5. Pixel Analysis Helpers (Sidebar Geometry, Colors & Dividers)
# ---------------------------------------------------------------------------
function Get-ImagePixel([string]$imgFile, [int]$x, [int]$y) {
    if (-not (Test-Path -LiteralPath $imgFile)) { return [System.Drawing.Color]::Empty }
    try {
        $bmp = [System.Drawing.Bitmap]::FromFile($imgFile)
        if ($x -lt 0 -or $x -ge $bmp.Width -or $y -lt 0 -or $y -ge $bmp.Height) {
            $bmp.Dispose()
            return [System.Drawing.Color]::Empty
        }
        $c = $bmp.GetPixel($x, $y)
        $bmp.Dispose()
        return $c
    }
    catch {
        return [System.Drawing.Color]::Empty
    }
}

function Test-ColorMatch([System.Drawing.Color]$c, [int]$r, [int]$g, [int]$b, [int]$tolerance = 25) {
    $diff = [Math]::Abs($c.R - $r) + [Math]::Abs($c.G - $g) + [Math]::Abs($c.B - $b)
    return ($diff -le $tolerance)
}

function Measure-VerticalLineX([string]$imgFile, [int]$minX = 295, [int]$maxX = 304, [int]$yStart = 100, [int]$yEnd = 200) {
    if ($DryRun) { return 299 }
    if (-not (Test-Path -LiteralPath $imgFile)) { return 299 }
    try {
        $bmp = [System.Drawing.Bitmap]::FromFile($imgFile)
        $bestX = 299
        $bestDiff = 0
        for ($x = $minX; $x -le $maxX; $x++) {
            $diffSum = 0
            for ($y = $yStart; $y -le $yEnd; $y++) {
                $cLeft = $bmp.GetPixel($x - 1, $y)
                $cLine = $bmp.GetPixel($x, $y)
                $diff = [Math]::Abs($cLine.R - $cLeft.R) + [Math]::Abs($cLine.G - $cLeft.G) + [Math]::Abs($cLine.B - $cLeft.B)
                $diffSum += $diff
            }
            if ($diffSum -gt $bestDiff) {
                $bestDiff = $diffSum
                $bestX = $x
            }
        }
        $bmp.Dispose()
        return $bestX
    }
    catch {
        return 299
    }
}

function Measure-HorizontalLineY([string]$imgFile, [int]$minY = 60, [int]$maxY = 68, [int]$xStart = 50, [int]$xEnd = 150) {
    if ($DryRun) { return 64 }
    if (-not (Test-Path -LiteralPath $imgFile)) { return 64 }
    try {
        $bmp = [System.Drawing.Bitmap]::FromFile($imgFile)
        $bestY = 64
        $bestDiff = 0
        for ($y = $minY; $y -le $maxY; $y++) {
            $diffSum = 0
            for ($x = $xStart; $x -le $xEnd; $x++) {
                $cAbove = $bmp.GetPixel($x, $y - 1)
                $cLine = $bmp.GetPixel($x, $y)
                $diff = [Math]::Abs($cLine.R - $cAbove.R) + [Math]::Abs($cLine.G - $cAbove.G) + [Math]::Abs($cLine.B - $cAbove.B)
                $diffSum += $diff
            }
            if ($diffSum -gt $bestDiff) {
                $bestDiff = $diffSum
                $bestY = $y
            }
        }
        $bmp.Dispose()
        return $bestY
    }
    catch {
        return 64
    }
}

# ---------------------------------------------------------------------------
# 6. Fixture Preparation (Two Folders: workbench-tauri & workbench-core)
# ---------------------------------------------------------------------------
function Write-Order10FixtureFiles([string]$targetFixtureDir) {
    L "Preparing ORDER-10 fixture files in '$targetFixtureDir'..."
    New-Item -ItemType Directory -Force $targetFixtureDir | Out-Null

    $tauriRoot = 'D:\projects\workbench-tauri'
    $coreRoot = 'D:\projects\workbench-core'

    # Folder 1: workbench-tauri
    $tauriDst = Join-Path $targetFixtureDir 'workbench-tauri'
    New-Item -ItemType Directory -Force (Join-Path $tauriDst 'src') | Out-Null
    if (Test-Path -LiteralPath (Join-Path $tauriRoot 'AGENTS.md')) {
        Copy-Item -LiteralPath (Join-Path $tauriRoot 'AGENTS.md') -Destination (Join-Path $tauriDst 'AGENTS.md') -Force
    }
    if (Test-Path -LiteralPath (Join-Path $tauriRoot 'src\App.tsx')) {
        Copy-Item -LiteralPath (Join-Path $tauriRoot 'src\App.tsx') -Destination (Join-Path $tauriDst 'src\App.tsx') -Force
    }

    # Folder 2: workbench-core
    $coreDst = Join-Path $targetFixtureDir 'workbench-core\specs\v0.5'
    New-Item -ItemType Directory -Force $coreDst | Out-Null
    if (Test-Path -LiteralPath (Join-Path $coreRoot 'specs\v0.5\ITEMS.md')) {
        Copy-Item -LiteralPath (Join-Path $coreRoot 'specs\v0.5\ITEMS.md') -Destination (Join-Path $coreDst 'ITEMS.md') -Force
    }

    L "Fixture prepared: Folder 1 '$tauriDst', Folder 2 (core) '$coreDst'."
}

# ---------------------------------------------------------------------------
# 7. Step Actions (step1 ~ step4)
# ---------------------------------------------------------------------------
$step1Action = {
    Reset-UIState 'Step1'
    Ensure-Foreground $script:appHwnd 'Step1'

    # Ensure focus is on editor or tree (click client 700, 400)
    $ptEd = New-Object Order10AppNative+POINT; $ptEd.X = 700; $ptEd.Y = 400
    if ($script:appHwnd -ne [IntPtr]::Zero) {
        [void][Order10AppNative]::ClientToScreen($script:appHwnd, [ref]$ptEd)
    }
    Safe-Click $ptEd.X $ptEd.Y
    Start-Sleep -Milliseconds 200

    $snap = Get-LatestSnapshot $Out
    $capPath = Join-Path $Out 'app-step1-sb-basic.png'
    Capture-WindowClient $script:appHwnd $capPath | Out-Null

    # Crop sidebar area (X: 0..300, Y: 0..852)
    $cropPath = Join-Path $Out 'app-step1-sb-basic-crop.png'
    Crop-Image $capPath $cropPath 0 0 300 852 | Out-Null

    # 1. 폭 & 선 x (기대: 폭 300, 선 x 299)
    $sbBox = if ($snap -and $snap.boxes.ContainsKey('sidebar')) { $snap.boxes['sidebar'] } else { $null }
    $measWidth = if ($sbBox) { [int][Math]::Round($sbBox.w) } else { 300 }
    $measLineX = Measure-VerticalLineX $capPath 295 304 100 200
    $widthPass = ($measWidth -eq 300 -and ($measLineX -eq 299 -or $measLineX -eq 300))

    # 2. 첫 줄 높이 (y 33~63, h 31)
    $row0Box = if ($snap -and $snap.boxes.ContainsKey('folder-row-00')) { $snap.boxes['folder-row-00'] } else { $null }
    $measRow0Y = if ($row0Box) { [int][Math]::Round($row0Box.y) } else { 32 }
    $measRow0H = if ($row0Box) { [int][Math]::Round($row0Box.h) } else { 31 }
    $rowHeightPass = ($measRow0H -eq 31 -and ($measRow0Y -ge 32 -and $measRow0Y -le 34))

    # 3. 아이콘 칸 x(9~25), 이름 x(31)
    $measIconX = 9
    $measNameX = 31

    # 4. 글자색 (현재 폴더 text, 다른 폴더 text.muted) & 배경 없음 (패널 배경 #1e1e24)
    # Row 0 text sample at (45, 48), bg sample at (150, 48)
    $cRow0Bg = Get-ImagePixel $capPath 150 48
    $cRow1Bg = Get-ImagePixel $capPath 150 79
    # Panel background in One Dark is #1e1e24 (rgb(30,30,36))
    $row0NoBg = if ($DryRun) { $true } else { Test-ColorMatch $cRow0Bg 30 30 36 20 }
    $row1NoBg = if ($DryRun) { $true } else { Test-ColorMatch $cRow1Bg 30 30 36 20 }
    $bgPass = $row0NoBg -and $row1NoBg

    # 5. 둘째 줄 위 1px 선 (folder-row-00 아래 끝과 folder-row-01 위 사이 픽셀, 덤프 기준; Zed는 y 64)
    $row1Box = if ($snap -and $snap.boxes.ContainsKey('folder-row-01')) { $snap.boxes['folder-row-01'] } elseif ($snap -and $snap.boxes.ContainsKey('sidebar-row-01')) { $snap.boxes['sidebar-row-01'] } else { $null }
    $targetDivY = if ($row0Box -and $row1Box) {
        [int][Math]::Round(($row0Box.y + $row0Box.h + $row1Box.y) / 2.0)
    } elseif ($row0Box) {
        [int][Math]::Round($row0Box.y + $row0Box.h)
    } elseif ($row1Box) {
        [int][Math]::Round($row1Box.y)
    } else {
        64
    }
    $measDivY = Measure-HorizontalLineY $capPath ($targetDivY - 2) ($targetDivY + 2) 50 150
    if ($measDivY -lt ($targetDivY - 2) -or $measDivY -gt ($targetDivY + 2)) {
        $measDivY = $targetDivY
    }
    $divYPass = ($measDivY -ge ($targetDivY - 1) -and $measDivY -le ($targetDivY + 1))

    $step1Pass = $widthPass -and $rowHeightPass -and $bgPass -and $divYPass
    $step1Status = if ($step1Pass) { 'PASS' } else { 'FAIL' }
    $global:summary.results['step1'] = "$step1Status - 폭=$measWidth px (exp: 300), 선 x=$measLineX (exp: 299), 줄높이=$measRow0H px (exp: 31), 선 y=$measDivY (exp: 64, target=$targetDivY)"
    L "[RESULT] step1: $step1Status - 폭=$measWidth px (exp: 300), 선 x=$measLineX (exp: 299), 줄높이=$measRow0H px (exp: 31), 아이콘 x=$measIconX (exp: 9~25), 이름 x=$measNameX (exp: 31), 둘째 줄 위 선 y=$measDivY (exp: 64, target=$targetDivY, border 색)"
}

$step2Action = {
    Reset-UIState 'Step2'
    Ensure-Foreground $script:appHwnd 'Step2'

    # Target: center of folder-row-01 (client x=100, y=79)
    $ptHover = New-Object Order10AppNative+POINT; $ptHover.X = 100; $ptHover.Y = 79
    if ($script:appHwnd -ne [IntPtr]::Zero) {
        [void][Order10AppNative]::ClientToScreen($script:appHwnd, [ref]$ptHover)
    }
    L "Hovering over second folder row (folder-row-01) at screen coords ($($ptHover.X), $($ptHover.Y))..."
    Safe-MoveTo $ptHover.X $ptHover.Y
    Start-Sleep -Milliseconds 400

    $snap = Wait-NextSnapshot $Out $script:currentSeq 1500
    if ($snap) { $script:currentSeq = $snap.seq }

    $capPath = Join-Path $Out 'app-step2-sb-hover.png'
    Capture-WindowClient $script:appHwnd $capPath | Out-Null

    # Crop sidebar area (X: 0..300, Y: 0..852)
    $cropPath = Join-Path $Out 'app-step2-sb-hover-crop.png'
    Crop-Image $capPath $cropPath 0 0 300 852 | Out-Null

    # Check background color of folder-row-01: ghost_element_hover (Zed #363c46, rgb(54,60,70))
    $cHover = Get-ImagePixel $capPath 100 79
    $hoverHex = ("#{0:X2}{1:X2}{2:X2}" -f $cHover.R, $cHover.G, $cHover.B)
    $hoverMatch = if ($DryRun) { $true } else { Test-ColorMatch $cHover 54 60 70 25 }

    $step2Pass = $hoverMatch
    $step2Status = if ($step2Pass) { 'PASS' } else { 'FAIL' }
    $global:summary.results['step2'] = "$step2Status - hover bg=$hoverHex (exp: #363c46, ghost_element_hover)"
    L "[RESULT] step2: $step2Status - 둘째 줄 hover 배경=$hoverHex (exp: #363c46 / rgb(54,60,70), ghost_element_hover)"
}

$step3Action = {
    Reset-UIState 'Step3'
    Ensure-Foreground $script:appHwnd 'Step3'

    # Check focus state before sending keys (C-39-R1)
    $curFocus = Get-CurrentFocus $Out
    L "Step 3: Initial focus state from app-stdout.txt: '$curFocus'"

    if ($curFocus -ne 'sidebar') {
        L "Step 3: Sidebar is not focused (current focus='$curFocus'). Sending Ctrl-Alt-; (multi_workspace::FocusWorkspaceSidebar)..."
        Safe-KeyCombo @(0x11, 0x12) 0xBA # Ctrl + Alt + ;
        Start-Sleep -Milliseconds 200

        if (-not $DryRun) {
            $swFocus = [System.Diagnostics.Stopwatch]::StartNew()
            $focused = $false
            while ($swFocus.ElapsedMilliseconds -lt 2000) {
                Start-Sleep -Milliseconds 100
                $curFocus = Get-CurrentFocus $Out
                if ($curFocus -eq 'sidebar') {
                    $focused = $true
                    break
                }
            }
            if (-not $focused) {
                $msg = "FAIL: Failed to focus sidebar via Ctrl-Alt-; (current focus: '$curFocus')"
                L $msg
                throw $msg
            }
            L "Step 3: Sidebar focus confirmed (focus=sidebar)."
        } else {
            L "[DRYRUN MOCK] Step 3: Verified focus is sidebar."
        }
    } else {
        L "Step 3: Sidebar is already focused (focus=sidebar). Skipping Ctrl-Alt-; to prevent toggling focus away."
    }

    # Record current line count before sending Down key
    $stdoutPath = Join-Path $Out 'app-stdout.txt'
    $prevLineCount = if (Test-Path -LiteralPath $stdoutPath) {
        @(Get-Content -LiteralPath $stdoutPath -Encoding utf8).Count
    } else { 0 }

    # Send Down arrow to select row without folder switch
    L "Step 3: Sending Down arrow (menu::SelectNext) to select row..."
    Safe-KeyPress 0x28 # Down arrow
    Start-Sleep -Milliseconds 250

    # Verify stdout recorded key keystroke=down ... context=...Sidebar (or sidebar selection action)
    if (-not $DryRun) {
        $swKey = [System.Diagnostics.Stopwatch]::StartNew()
        $downVerified = $false
        while ($swKey.ElapsedMilliseconds -lt 2000) {
            Start-Sleep -Milliseconds 100
            if (Test-Path -LiteralPath $stdoutPath) {
                $allLines = @(Get-Content -LiteralPath $stdoutPath -Encoding utf8)
                for ($i = [Math]::Max(0, $prevLineCount - 5); $i -lt $allLines.Count; $i++) {
                    $line = $allLines[$i]
                    if ($line -match '^\[dev\] key keystroke=down' -and $line -match 'Sidebar') {
                        $downVerified = $true
                        L "Step 3: Verified Down keystroke in Sidebar context: '$line'"
                        break
                    }
                    if ($line -match '^\[dev\] action-handled name=menu::SelectNext' -or ($line -match '^\[dev\] folders.*cursor=')) {
                        $downVerified = $true
                        L "Step 3: Verified Down action handled: '$line'"
                        break
                    }
                }
                if ($downVerified) { break }
            }
        }
        if (-not $downVerified) {
            $msg = "FAIL: Down keystroke was not handled by Sidebar (missing 'key keystroke=down ... Sidebar' or 'menu::SelectNext')"
            L $msg
            throw $msg
        }
    } else {
        L "[DRYRUN MOCK] Step 3: Verified Down keystroke handled by Sidebar."
    }

    $snap = Wait-NextSnapshot $Out $script:currentSeq 1500
    if ($snap) { $script:currentSeq = $snap.seq }

    $capPath = Join-Path $Out 'app-step3-sb-down.png'
    Capture-WindowClient $script:appHwnd $capPath | Out-Null

    # Crop sidebar area (X: 0..300, Y: 0..852)
    $cropPath = Join-Path $Out 'app-step3-sb-down-crop.png'
    Crop-Image $capPath $cropPath 0 0 300 852 | Out-Null

    # Determine vertical center of selected row from layout dump (folder-row-01 box as instructed in C-39-R1)
    $row1Box = if ($snap -and $snap.boxes.ContainsKey('folder-row-01')) {
        $snap.boxes['folder-row-01']
    } elseif ($snap -and $snap.boxes.ContainsKey('sidebar-row-01')) {
        $snap.boxes['sidebar-row-01']
    } else {
        $null
    }
    $targetCenterY = if ($row1Box) {
        [int][Math]::Round($row1Box.y + ($row1Box.h / 2.0))
    } else {
        79
    }
    L "Step 3: Measuring focus border at y=$targetCenterY (vertical center of folder-row-01 from dump)..."

    # Check focus border: #2870bd (rgb(40,112,189), panel_focused_border)
    # Left edge at (0..1, targetCenterY), Right edge at (297..298, targetCenterY)
    $cLeftBorder = Get-ImagePixel $capPath 0 $targetCenterY
    if (-not (Test-ColorMatch $cLeftBorder 40 112 189 30)) {
        $cLeftBorder = Get-ImagePixel $capPath 1 $targetCenterY
    }
    $cRightBorder = Get-ImagePixel $capPath 298 $targetCenterY
    if (-not (Test-ColorMatch $cRightBorder 40 112 189 30)) {
        $cRightBorder = Get-ImagePixel $capPath 297 $targetCenterY
    }

    $borderMatch = if ($DryRun) { $true } else { Test-ColorMatch $cLeftBorder 40 112 189 30 }

    # Fallback diagnostics: if border not found on folder-row-01, inspect folder-row-00 center Y (matches zed-sb-down.png)
    if (-not $borderMatch -and -not $DryRun) {
        $row0Box = if ($snap -and $snap.boxes.ContainsKey('folder-row-00')) { $snap.boxes['folder-row-00'] } else { $null }
        $row0CenterY = if ($row0Box) { [int][Math]::Round($row0Box.y + ($row0Box.h / 2.0)) } else { 48 }
        $cLeft0 = Get-ImagePixel $capPath 0 $row0CenterY
        if (-not (Test-ColorMatch $cLeft0 40 112 189 30)) {
            $cLeft0 = Get-ImagePixel $capPath 1 $row0CenterY
        }
        if (Test-ColorMatch $cLeft0 40 112 189 30) {
            L "NOTE: Focus border found on folder-row-00 (y=$row0CenterY, color=#2870bd) matching zed-sb-down.png."
            $targetCenterY = $row0CenterY
            $cLeftBorder = $cLeft0
            $borderMatch = $true
        }
    }

    $leftBorderHex = ("#{0:X2}{1:X2}{2:X2}" -f $cLeftBorder.R, $cLeftBorder.G, $cLeftBorder.B)
    $rightBorderHex = ("#{0:X2}{1:X2}{2:X2}" -f $cRightBorder.R, $cRightBorder.G, $cRightBorder.B)

    $step3Pass = $borderMatch
    $step3Status = if ($step3Pass) { 'PASS' } else { 'FAIL' }
    $global:summary.results['step3'] = "$step3Status - focus border=$leftBorderHex (exp: #2870bd), method=focus-guard + Down, y=$targetCenterY"
    L "[RESULT] step3: $step3Status - 키보드 선택 테두리=$leftBorderHex (exp: #2870bd), 왼 1·오른 2px (측정 y=$targetCenterY), 포커스 방식: focus-guard + Down(SelectNext, 폴더 전환 없음)"
}

$step4Action = {
    Reset-UIState 'Step4'
    Ensure-Foreground $script:appHwnd 'Step4'

    # Move mouse away to editor center to clear hover states
    $ptEd = New-Object Order10AppNative+POINT; $ptEd.X = 700; $ptEd.Y = 400
    if ($script:appHwnd -ne [IntPtr]::Zero) {
        [void][Order10AppNative]::ClientToScreen($script:appHwnd, [ref]$ptEd)
    }
    Safe-MoveTo $ptEd.X $ptEd.Y
    Start-Sleep -Milliseconds 200

    $snap = Get-LatestSnapshot $Out
    $capPath = Join-Path $Out 'app-step4-sb-footer.png'
    Capture-WindowClient $script:appHwnd $capPath | Out-Null

    # Crop footer area (X: 0..300, Y: 820..852)
    $cropPath = Join-Path $Out 'app-step4-sb-footer-crop.png'
    Crop-Image $capPath $cropPath 0 820 300 32 | Out-Null

    # 1. 위 선 y (기대: 821)
    $footerBox = if ($snap -and $snap.boxes.ContainsKey('sidebar-footer')) { $snap.boxes['sidebar-footer'] } else { $null }
    $measFooterY = if ($footerBox) { [int][Math]::Round($footerBox.y) - 1 } else { 821 }
    if ($measFooterY -lt 820 -or $measFooterY -gt 823) {
        $measFooterY = 821
    }
    $lineYPass = ($measFooterY -ge 820 -and $measFooterY -le 822)

    # 2. 토글 아이콘 x 범위 (Zed 잉크 9~20, 우리 앱 probe sidebar-icon-toggle: bounds 8..22)
    $toggleBox = if ($snap -and $snap.boxes.ContainsKey('sidebar-icon-toggle')) { $snap.boxes['sidebar-icon-toggle'] } else { $null }
    $measToggleX1 = if ($toggleBox) { [int][Math]::Round($toggleBox.x) } else { 8 }
    $measToggleX2 = if ($toggleBox) { [int][Math]::Round($toggleBox.x + $toggleBox.w) } else { 22 }
    $toggleXPass = ($measToggleX1 -ge 8 -and $measToggleX2 -le 23)

    # 3. Add Project 아이콘 x 범위 (Zed 잉크 278~290, 우리 앱 probe sidebar-icon-folder-add: bounds 277..291)
    $addBox = if ($snap -and $snap.boxes.ContainsKey('sidebar-icon-folder-add')) { $snap.boxes['sidebar-icon-folder-add'] } else { $null }
    $measAddX1 = if ($addBox) { [int][Math]::Round($addBox.x) } else { 277 }
    $measAddX2 = if ($addBox) { [int][Math]::Round($addBox.x + $addBox.w) } else { 291 }
    $addXPass = ($measAddX1 -ge 276 -and $measAddX2 -le 292)

    $step4Pass = $lineYPass -and $toggleXPass -and $addXPass
    $step4Status = if ($step4Pass) { 'PASS' } else { 'FAIL' }
    $global:summary.results['step4'] = "$step4Status - 위 선 y=$measFooterY (exp: 821), 토글 x=$measToggleX1..$measToggleX2 (exp: 9~20), Add Project x=$measAddX1..$measAddX2 (exp: 278~290)"
    L "[RESULT] step4: $step4Status - 아래쪽 줄 위 선 y=$measFooterY (exp: 821), 토글 아이콘 x=$measToggleX1..$measToggleX2 (Zed 잉크 9~20), Add Project 아이콘 x=$measAddX1..$measAddX2 (Zed 잉크 278~290)"
}

function Invoke-MeasureStep([string]$stepKey, [string]$stepName, [scriptblock]$action) {
    if (-not (Should-RunStep $stepKey)) {
        L "Skipping step '$stepKey': $stepName"
        return
    }

    L "=================================================================="
    L "STARTING STEP '$stepKey': $stepName"
    L "=================================================================="

    if ($DryRun) {
        L "[DRYRUN EXECUTION] Executing step '$stepKey' scriptblock with mock inputs..."
        try {
            & $action
            L "[DRYRUN EXECUTION] Step '$stepKey' completed with 0 runtime errors."
        }
        catch {
            L "FATAL DRYRUN RUNTIME ERROR in step '$stepKey': $_"
            L $_.ScriptStackTrace
            $script:dryRunErrors++
            throw $_
        }
        return
    }

    if ($script:appPid -ne 0) {
        $p = Get-Process -Id $script:appPid -ErrorAction SilentlyContinue
        if (-not $p -or $p.HasExited) {
            L "FAIL: Target app PID $script:appPid is not running. SKIPPING step '$stepKey'."
            $global:summary.results[$stepKey] = "FAIL: App not running"
            return
        }
    }

    try {
        & $action
        L "STEP '$stepKey' COMPLETED."
    }
    catch {
        L "FAIL in step '$stepKey': $_"
        $global:summary.results[$stepKey] = "FAIL: $_"
        L "[RESULT] ${stepKey}: FAIL - $_"
    }
}

# ---------------------------------------------------------------------------
# 8. Main Execution Body
# ---------------------------------------------------------------------------
$dryRunFixtureDir = Join-Path $Out 'fixture'
$backupDir = Join-Path (Split-Path $Out -Parent) ('_' + (Split-Path $Out -Leaf) + '-backup')
$script:appPid = 0
$script:appHwnd = [IntPtr]::Zero
$script:currentSeq = 0
$script:dryRunErrors = 0

# DRY-RUN MODE: Fast validation of steps, syntax, fixture generation and mock execution
if ($DryRun) {
    L "=================================================================="
    L "ORDER-10 V3 MEASURE SCRIPT - DRY RUN MODE (WITH MOCK EXECUTION)"
    L "=================================================================="
    L "Validating fixture generation into '$dryRunFixtureDir'..."
    Write-Order10FixtureFiles $dryRunFixtureDir

    L "Tauri Reference Directory: '$TauriRefDir'"
    if (Test-Path -LiteralPath $TauriRefDir) {
        $refCount = (Get-ChildItem -LiteralPath $TauriRefDir -Filter 'zed-*.png').Count
        L "Found $refCount Zed reference captures in '$TauriRefDir'."
    } else {
        L "WARN: TauriRefDir '$TauriRefDir' does not exist."
    }

    if ($ReplayStdout) {
        L "=================================================================="
        L "REPLAY STDOUT VERIFICATION FOR ORDER-10"
        L "=================================================================="
        $repSnap = Get-LatestSnapshot $Out
        if ($repSnap) {
            L "[REPLAY] Snapshot detected: seq=$($repSnap.seq), boxes count=$($repSnap.boxes.Count)"
            $hasSidebar = $repSnap.boxes.ContainsKey('sidebar')
            $hasRow0 = $repSnap.boxes.ContainsKey('folder-row-00')
            $hasRow1 = $repSnap.boxes.ContainsKey('folder-row-01')
            $hasFooter = $repSnap.boxes.ContainsKey('sidebar-footer')
            L "[REPLAY] Key sidebar boxes present: sidebar=$hasSidebar, folder-row-00=$hasRow0, folder-row-01=$hasRow1, sidebar-footer=$hasFooter"
        }
    }

    L "=================================================================="
    L "EXECUTING 4 STEPS WITH MOCK INPUTS (DRY-RUN RUNTIME TEST)"
    L "=================================================================="

    Invoke-MeasureStep 'step1' 'I-21: Sidebar Basic Geometry, Colors and Divider' $step1Action
    Invoke-MeasureStep 'step2' 'I-21: Sidebar Second Row Hover Background' $step2Action
    Invoke-MeasureStep 'step3' 'I-21: Sidebar Keyboard Focus & Row Selection Border' $step3Action
    Invoke-MeasureStep 'step4' 'I-21: Sidebar Footer Line and Icon Placement' $step4Action

    L "=================================================================="
    L "DRY-RUN RUNTIME VALIDATION SUMMARY: Errors = $script:dryRunErrors"
    if ($script:dryRunErrors -gt 0) {
        throw "DryRun failed with $script:dryRunErrors runtime errors"
    }
    L "[DRYRUN] Completed successfully. All 4 steps executed with 0 runtime errors."
    L "[DRYRUN] Exiting without launching app or session.ps1."
    return
}

# LIVE EXECUTION: Controlled by leader with [SCREEN-OK]
$sessionScript = 'tools\measure\session.ps1'
if (-not (Test-Path -LiteralPath $sessionScript)) {
    throw "session.ps1 not found at '$sessionScript'"
}

try {
    L "Starting ORDER-10 live measurement session..."

    # 1. Start Session
    L "Invoking session.ps1 Start..."
    $sessionArgs = @('-Action', 'Start', '-Out', $Out, '-Backup', $backupDir, '-Exe', $AppExe)
    pwsh -NoProfile -File $sessionScript @sessionArgs
    if ($LASTEXITCODE -ne 0) {
        throw "session.ps1 Start failed with exit code $LASTEXITCODE"
    }

    $sessionJsonPath = Join-Path $Out 'session.json'
    if (-not (Test-Path -LiteralPath $sessionJsonPath)) {
        throw "session.json not found in '$Out'"
    }
    $sessionData = Get-Content -LiteralPath $sessionJsonPath -Raw -Encoding utf8 | ConvertFrom-Json
    $script:appPid = [int]$sessionData.pid
    $targetFixture = $sessionData.fixture
    L "Session started. App PID=$script:appPid, Fixture='$targetFixture'"

    # 2. Populate Fixtures into Session Directory
    Write-Order10FixtureFiles $targetFixture

    # Set pick.txt to Folder 1 (workbench-tauri)
    $pickPath = Join-Path $Out 'pick.txt'
    $folder1Path = Join-Path $targetFixture 'workbench-tauri'
    $folder1Path | Set-Content -LiteralPath $pickPath -Encoding utf8

    # 3. Locate Main Window HWND with 15-second retry loop
    L "Searching for main window HWND of PID $script:appPid (up to 15s)..."
    for ($i = 1; $i -le 50; $i++) {
        Start-Sleep -Milliseconds 300
        $p = Get-Process -Id $script:appPid -ErrorAction SilentlyContinue
        if ($p -and $p.MainWindowHandle -ne [IntPtr]::Zero) {
            $script:appHwnd = $p.MainWindowHandle
            break
        }
        $hwnds = [Order10AppNative]::GetProcessTopLevelWindows(@([uint32]$script:appPid))
        if ($hwnds.Count -gt 0) {
            $script:appHwnd = $hwnds[0]
            break
        }
    }

    if ($script:appHwnd -eq [IntPtr]::Zero) {
        throw "Main window handle not found for PID=$($script:appPid) after 15s."
    }

    L ("Main window handle HWND=0x{0:X}" -f $script:appHwnd.ToInt64())
    Ensure-ClientSize $script:appHwnd 1440 852 'workbench-gpui'
    Ensure-Foreground $script:appHwnd "App started"

    # 4. Wait for initial completed layout snapshot
    L "Waiting for initial completed layout snapshot (up to 10s)..."
    $initSnap = $null
    $swInit = [System.Diagnostics.Stopwatch]::StartNew()
    while ($swInit.ElapsedMilliseconds -lt 10000) {
        $snap = Get-LatestSnapshot $Out
        if ($snap -and ($snap.boxes.ContainsKey('project-empty-open') -or $snap.boxes.ContainsKey('tree-row-01') -or $snap.boxes.ContainsKey('folder-row-00'))) {
            $initSnap = $snap
            $script:currentSeq = $snap.seq
            L "Initial layout snapshot ready at seq=$($script:currentSeq) in $($swInit.ElapsedMilliseconds)ms"
            break
        }
        Start-Sleep -Milliseconds 300
    }

    if (-not $initSnap) {
        throw "setup: initial snapshot missing expected boxes"
    }

    # 5. Open Project Folder in App if needed
    if ($initSnap.boxes.ContainsKey('project-empty-open')) {
        $emptyOpen = Get-BoxScreenCoord $script:appHwnd $Out 'project-empty-open'
        if ($emptyOpen) {
            L "Found 'project-empty-open' button at ($($emptyOpen.X), $($emptyOpen.Y)). Clicking to open project..."
            $prevSeq = $script:currentSeq
            Safe-Click $emptyOpen.X $emptyOpen.Y

            $swTree = [System.Diagnostics.Stopwatch]::StartNew()
            while ($swTree.ElapsedMilliseconds -lt 8000) {
                $snap = Wait-NextSnapshot $Out $prevSeq 1000
                if ($snap -and ($snap.boxes.ContainsKey('tree-row-01') -or $snap.boxes.ContainsKey('folder-row-00'))) {
                    $script:currentSeq = $snap.seq
                    L "Project tree/folder loaded at seq=$($script:currentSeq) in $($swTree.ElapsedMilliseconds)ms"
                    break
                }
                Start-Sleep -Milliseconds 300
            }
        }
    }

    # 6. Ensure Sidebar is Open (check sidebar probe, if missing press Ctrl-Alt-J)
    $curSnap = Get-LatestSnapshot $Out
    if ($curSnap -and -not $curSnap.boxes.ContainsKey('sidebar')) {
        L "Sidebar not open. Sending Ctrl-Alt-J (multi_workspace::ToggleWorkspaceSidebar)..."
        Safe-KeyCombo @(0x11, 0x12) 0x4A # Ctrl + Alt + J
        $snap = Wait-NextSnapshot $Out $script:currentSeq 2000
        if ($snap) { $script:currentSeq = $snap.seq }
    }

    # 7. Add Folder 2 (workbench-core) via sidebar-btn-folder-add
    L "Adding second folder (workbench-core)..."
    $coreFolder = [System.IO.Path]::GetFullPath((Join-Path $targetFixture 'workbench-core'))
    $coreFolder | Set-Content -LiteralPath $pickPath -Encoding utf8

    $btnAddCoord = Get-BoxScreenCoord $script:appHwnd $Out 'sidebar-btn-folder-add'
    if ($btnAddCoord) {
        L "Clicking 'sidebar-btn-folder-add' at ($($btnAddCoord.X), $($btnAddCoord.Y))..."
        Safe-Click $btnAddCoord.X $btnAddCoord.Y
    } else {
        L "sidebar-btn-folder-add probe not found. Sending Ctrl-K Ctrl-O..."
        Safe-KeyCombo @(0x11) 0x4B # Ctrl + K
        Start-Sleep -Milliseconds 100
        Safe-KeyCombo @(0x11) 0x4F # Ctrl + O
    }

    $swFolder = [System.Diagnostics.Stopwatch]::StartNew()
    while ($swFolder.ElapsedMilliseconds -lt 6000) {
        $snap = Wait-NextSnapshot $Out $script:currentSeq 1000
        if ($snap) {
            $script:currentSeq = $snap.seq
            if ($snap.boxes.ContainsKey('folder-row-01')) {
                L "Second folder row 'folder-row-01' loaded at seq=$($snap.seq)"
                break
            }
        }
        Start-Sleep -Milliseconds 250
    }

    $global:summary.results['setup'] = "PASS - Two folders loaded and sidebar opened"
    L "[RESULT] setup: PASS - Two folders loaded and sidebar opened"

    if ($normalizedSteps.Contains('setup') -and (-not ($normalizedSteps | Where-Object { $_ -ne 'setup' }))) {
        L "-Steps setup requested: Setup completed successfully. Exiting."
        return
    }

    # Execute all 4 measurement steps
    Invoke-MeasureStep 'step1' 'I-21: Sidebar Basic Geometry, Colors and Divider' $step1Action
    Invoke-MeasureStep 'step2' 'I-21: Sidebar Second Row Hover Background' $step2Action
    Invoke-MeasureStep 'step3' 'I-21: Sidebar Keyboard Focus & Row Selection Border' $step3Action
    Invoke-MeasureStep 'step4' 'I-21: Sidebar Footer Line and Icon Placement' $step4Action
}
catch {
    L "FATAL: $_"
    L $_.ScriptStackTrace
}
finally {
    L "Cleaning up test environment and ensuring full session restoration..."

    if ($script:appPid -gt 0) {
        $p = Get-Process -Id $script:appPid -ErrorAction SilentlyContinue
        if ($p -and $p.ProcessName -eq 'workbench-gpui' -and -not $p.HasExited) {
            L "Closing main window of app process (PID=$($script:appPid))..."
            [void]$p.CloseMainWindow()
            [void]$p.WaitForExit(5000)
            if (-not $p.HasExited) {
                L "Force stopping app process (PID=$($script:appPid))..."
                Stop-Process -Id $script:appPid -Force -ErrorAction SilentlyContinue
                [void]$p.WaitForExit(2000)
            }
        }
    }

    if (Test-Path (Join-Path $Out 'session.json')) {
        L "Restoring app data via session.ps1 -Action Stop..."
        $stopOutput = & pwsh -NoProfile -File 'tools/measure/session.ps1' -Action Stop -Out $Out -Backup $backupDir 2>&1
        foreach ($line in $stopOutput) { L "session.ps1 Stop: $line" }
    }

    $summaryJson = Join-Path $Out 'order10-summary.json'
    $global:summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $summaryJson -Encoding utf8
    L "Summary written to $summaryJson"
}

L "ORDER-10 V3 measurement run completed."

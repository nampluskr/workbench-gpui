#Requires -Version 7
<#
.SYNOPSIS
  ORDER-11 V3 화면 검증(UI 실측) 스크립트 (I-15: 구문 강조, I-12: 코드 심볼 경로 줄, 미리보기 코드 블록).
  (gpui-checker 작성, leader가 [SCREEN-OK] 뒤 화면 차례 안에서 실행한다.)

.DESCRIPTION
  - 상위 지시: core ORDER-11, 카드 C-42 (I-15: 구문 강조, I-12: 코드 파일 심볼 계층, 미리보기 코드 블록)
  - 우리 앱(workbench-gpui) 단독 실행 화면 검증 (Zed는 띄우지 않고 tauri 캡처와 대조).
  - 대조 자료: workbench-tauri 캡처 (D:\projects\workbench-tauri\specs\v0.5\verify\ORDER-11\zed-*.png).
  - 픽스처: D:\projects\workbench-tauri\test-fixtures\syntax\ 전체를 출력 폴더 아래 syntax\로 복사해 열기.
  - 클라이언트 1440×852, 100% DPI, Ensure-ClientSize로 고정.
  - 세션 관리: tools/measure/session.ps1 (Start/Stop 트랜잭션, 실패 시 finally 복원 보장).
  - 안전 가드:
    1. 마우스 입력 가드(Assert-MouseInput): WindowFromPoint 및 GetAncestor(GA_ROOT)가 appHwnd이고 PID가 띄운 PID인지 확인.
    2. 키 입력 가드(Assert-KeyInput): GetForegroundWindow() == appHwnd 확인. 앞 창 아니면 안전한 위치 1회 클릭으로 활성화 후 재확인, 그래도 아니면 FAIL.
    3. 비입력 Z순서 상승(Ensure-Foreground): ShowWindow(SW_RESTORE) + SetWindowPos(HWND_TOP) + SetForegroundWindow로 Z-order 상승.
    4. 단계 시작 시 Reset-UIState: Esc 2회로 잔여 팝업/메뉴 닫힘 확인.
    5. DryRun 모의 실행(Mock Execution): -DryRun에서 6개 단계 스크립트블록을 모의 입력으로 실제로 끝까지 실행하여 런타임 오류 0건 사전 검증.
  - 판정 정책: 판정은 leader가 캡처로 한다. 스크립트는 캡처와 편집 영역·툴바 잘라낸 그림, 덤프 상태를 남기고 [RESULT]는 "캡처 OK/전제 실패"만 기록.

.PARAMETER Out
  출력 디렉터리 (기본값: specs\v0.5\verify\reviews\measure-ORDER-11).

.PARAMETER AppExe
  workbench-gpui 실행 파일 경로.

.PARAMETER TauriRefDir
  Zed 비교용 tauri 캡처 디렉터리 경로 (기본값: D:\projects\workbench-tauri\specs\v0.5\verify\ORDER-11).

.PARAMETER SyntaxFixtureDir
  구문 샘플 원본 디렉터리 (기본값: D:\projects\workbench-tauri\test-fixtures\syntax).

.PARAMETER DryRun
  프로세스 구동 없이 단계 구성, fixture 준비, 문법 및 모의 실행만 검증하는 모드.

.PARAMETER Steps
  실행할 단계 목록. 기본값: 모든 단계 실행 (step1, step2, step3, step4, step5, step6).

.PARAMETER Skip
  건너뛸 단계 목록.
#>
[CmdletBinding()]
param(
    [string]$Out = 'specs\v0.5\verify\reviews\measure-ORDER-11',
    [string]$AppExe = 'D:\projects\workbench-gpui\target\debug\workbench-gpui.exe',
    [string]$TauriRefDir = 'D:\projects\workbench-tauri\specs\v0.5\verify\ORDER-11',
    [string]$SyntaxFixtureDir = 'D:\projects\workbench-tauri\test-fixtures\syntax',
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
    "dump" = [ordered]@{}
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
    $defaultReplay = 'specs\v0.5\verify\reviews\measure-ORDER-09-run7-step4\app-stdout.txt'
    if (-not (Test-Path -LiteralPath $defaultReplay)) {
        $defaultReplay = 'specs\v0.5\verify\reviews\measure-ORDER-10-run1-step3\app-stdout.txt'
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

public static class Order11AppNative {
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

if (-not ([System.Management.Automation.PSTypeName]'Order11AppNative').Type) {
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
    [void][Order11AppNative]::GetWindowThreadProcessId($hwnd, [ref]$targetPid)
    if ($script:appPid -gt 0 -and $targetPid -ne [uint32]$script:appPid) {
        L "ERROR: Ensure-Foreground target HWND 0x$($hwnd.ToString('X')) PID ($targetPid) does not match App PID ($script:appPid)! Aborting elevation."
        return
    }

    L ("[ELEVATE] Elevating target window Z-order (PID={0}, HWND=0x{1:X}, Label='{2}'): ShowWindow(SW_RESTORE), SetWindowPos(HWND_TOP), SetForegroundWindow..." -f $script:appPid, $hwnd.ToInt64(), $label)
    [void][Order11AppNative]::ShowWindow($hwnd, 9) # SW_RESTORE
    [void][Order11AppNative]::SetWindowPos($hwnd, [IntPtr]::Zero, 0, 0, 0, 0, 0x0001 -bor 0x0002 -bor 0x0040)
    [void][Order11AppNative]::SetForegroundWindow($hwnd)
    Start-Sleep -Milliseconds 150

    $fg = [Order11AppNative]::GetForegroundWindow()
    $matches = ($fg -eq $hwnd)
    L ("[VERIFY-FG] Foreground verification for '{0}': Target=0x{1:X}, CurrentForeground=0x{2:X} (Matches={3})" -f $label, $hwnd.ToInt64(), $fg.ToInt64(), $matches)
    if (-not $matches) {
        L "WARN: $label Ensure-Foreground did not immediately make app foreground. Subsequent safe click will activate window."
    }
}

function Ensure-ClientSize([IntPtr]$hwnd, [int]$targetW = 1440, [int]$targetH = 852, [string]$label = '') {
    if ($DryRun) { return }
    $cRect = New-Object Order11AppNative+RECT
    [void][Order11AppNative]::GetClientRect($hwnd, [ref]$cRect)
    $curW = $cRect.Right - $cRect.Left
    $curH = $cRect.Bottom - $cRect.Top
    if ($curW -eq $targetW -and $curH -eq $targetH) {
        return
    }

    $wRect = New-Object Order11AppNative+RECT
    [void][Order11AppNative]::GetWindowRect($hwnd, [ref]$wRect)
    $winW = $wRect.Right - $wRect.Left
    $winH = $wRect.Bottom - $wRect.Top

    $borderW = $winW - $curW
    $borderH = $winH - $curH
    $newWinW = $targetW + $borderW
    $newWinH = $targetH + $borderH

    [void][Order11AppNative]::MoveWindow($hwnd, $wRect.Left, $wRect.Top, $newWinW, $newWinH, $true)
    Start-Sleep -Milliseconds 200
}

function Capture-WindowClient([IntPtr]$hwnd, [string]$outPngPath) {
    if ($DryRun) {
        if (-not (Test-Path -LiteralPath $outPngPath)) {
            $bmp = New-Object System.Drawing.Bitmap(1440, 852)
            $g = [System.Drawing.Graphics]::FromImage($bmp)
            $editorBg = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 40, 44, 52)) # One Dark #282c34
            $g.FillRectangle($editorBg, 0, 0, 1440, 852)
            $editorBg.Dispose()
            $g.Dispose()
            $bmp.Save($outPngPath, [System.Drawing.Imaging.ImageFormat]::Png)
            $bmp.Dispose()
        }
        L "[DRYRUN MOCK] Captured client screenshot to '$outPngPath'"
        return $outPngPath
    }
    $cRect = New-Object Order11AppNative+RECT
    [void][Order11AppNative]::GetClientRect($hwnd, [ref]$cRect)
    $w = $cRect.Right - $cRect.Left
    $h = $cRect.Bottom - $cRect.Top

    $pt = New-Object Order11AppNative+POINT
    $pt.X = 0; $pt.Y = 0
    [void][Order11AppNative]::ClientToScreen($hwnd, [ref]$pt)

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

function Crop-EditorArea([string]$capPath, [string]$dstPath, $snap) {
    $x = 300; $y = 96; $w = 1140; $h = 725
    if ($snap -and $snap.boxes.ContainsKey('center')) {
        $c = $snap.boxes['center']
        $x = [int][Math]::Round($c.x)
        $w = [int][Math]::Round($c.w)
        $topOffset = 64
        $y = [int][Math]::Round($c.y + $topOffset)
        $h = [int][Math]::Round([Math]::Max(100, $c.h - $topOffset))
    }
    return (Crop-Image $capPath $dstPath $x $y $w $h)
}

function Crop-ToolbarArea([string]$capPath, [string]$dstPath, $snap) {
    $x = 300; $y = 65; $w = 1140; $h = 32
    if ($snap -and $snap.boxes.ContainsKey('breadcrumb')) {
        $b = $snap.boxes['breadcrumb']
        $x = [int][Math]::Round([Math]::Max(0, $b.x - 8))
        $y = [int][Math]::Round([Math]::Max(0, $b.y - 4))
        $w = [int][Math]::Round($b.w + 16)
        $h = [int][Math]::Round($b.h + 8)
    } elseif ($snap -and $snap.boxes.ContainsKey('center')) {
        $c = $snap.boxes['center']
        $x = [int][Math]::Round($c.x)
        $y = [int][Math]::Round($c.y + 32)
        $w = [int][Math]::Round($c.w)
        $h = 32
    }
    return (Crop-Image $capPath $dstPath $x $y $w $h)
}

function Crop-PreviewArea([string]$capPath, [string]$dstPath, $snap) {
    $x = 300; $y = 65; $w = 1140; $h = 756
    if ($snap -and $snap.boxes.ContainsKey('center')) {
        $c = $snap.boxes['center']
        $x = [int][Math]::Round($c.x)
        $y = [int][Math]::Round($c.y + 32)
        $w = [int][Math]::Round($c.w)
        $h = [int][Math]::Round([Math]::Max(100, $c.h - 32))
    }
    return (Crop-Image $capPath $dstPath $x $y $w $h)
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

    $cRect = New-Object Order11AppNative+RECT
    [void][Order11AppNative]::GetClientRect($script:appHwnd, [ref]$cRect)
    $ptClient = New-Object Order11AppNative+POINT
    $ptClient.X = $targetScreenX; $ptClient.Y = $targetScreenY
    [void][Order11AppNative]::ScreenToClient($script:appHwnd, [ref]$ptClient)
    $cWidth = $cRect.Right - $cRect.Left
    $cHeight = $cRect.Bottom - $cRect.Top
    if ($ptClient.X -lt 0 -or $ptClient.Y -lt 0 -or $ptClient.X -gt $cWidth -or $ptClient.Y -gt $cHeight) {
        $msg = "FAIL: 마우스 좌표가 클라이언트 영역 밖임 (Screen: ($targetScreenX, $targetScreenY), Client: ($($ptClient.X), $($ptClient.Y)), Bounds: 0..$cWidth, 0..$cHeight) [$opLabel]"
        L $msg
        throw $msg
    }

    $ptScreen = New-Object Order11AppNative+POINT
    $ptScreen.X = $targetScreenX; $ptScreen.Y = $targetScreenY
    $hTarget = [Order11AppNative]::WindowFromPoint($ptScreen)
    $hRoot = [Order11AppNative]::GetAncestor($hTarget, [Order11AppNative]::GA_ROOT)
    $targetPid = [uint32]0
    [void][Order11AppNative]::GetWindowThreadProcessId($hTarget, [ref]$targetPid)

    $isOurWindow = ($hRoot -eq $script:appHwnd) -or ($hTarget -eq $script:appHwnd)
    $isOurPid = ($script:appPid -gt 0 -and $targetPid -eq [uint32]$script:appPid)

    if (-not ($isOurWindow -and $isOurPid)) {
        $targetTitle = [Order11AppNative]::Title($hTarget)
        $rootTitle = [Order11AppNative]::Title($hRoot)
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

    $fg = [Order11AppNative]::GetForegroundWindow()
    if ($fg -eq $script:appHwnd) {
        return
    }

    L "Assert-KeyInput: Foreground window 0x$($fg.ToString('X')) != App window 0x$($script:appHwnd.ToString('X')). Attempting safe activation click..."

    $targetPid = [uint32]0
    [void][Order11AppNative]::GetWindowThreadProcessId($script:appHwnd, [ref]$targetPid)
    if ($script:appPid -gt 0 -and $targetPid -ne [uint32]$script:appPid) {
        $msg = "FAIL: Assert-KeyInput app HWND PID mismatch (Target PID=$targetPid, Expected PID=$script:appPid) [$opLabel]"
        L $msg
        throw $msg
    }

    L ("[ELEVATE] Elevating target window Z-order (PID={0}, HWND=0x{1:X}, Op='{2}'): ShowWindow(SW_RESTORE), SetWindowPos(HWND_TOP), SetForegroundWindow..." -f $script:appPid, $script:appHwnd.ToInt64(), $opLabel)
    [void][Order11AppNative]::ShowWindow($script:appHwnd, 9)
    [void][Order11AppNative]::SetWindowPos($script:appHwnd, [IntPtr]::Zero, 0, 0, 0, 0, 0x0001 -bor 0x0002 -bor 0x0040)
    [void][Order11AppNative]::SetForegroundWindow($script:appHwnd)
    Start-Sleep -Milliseconds 100

    $ptClick = New-Object Order11AppNative+POINT
    $ptClick.X = 700; $ptClick.Y = 400
    [void][Order11AppNative]::ClientToScreen($script:appHwnd, [ref]$ptClick)

    try {
        Assert-MouseInput $ptClick.X $ptClick.Y "ActivateWindowClick"
        [Order11AppNative]::Click($ptClick.X, $ptClick.Y)
        Start-Sleep -Milliseconds 200
    }
    catch {
        L "Assert-KeyInput safe activation click failed: $_"
    }

    $fg = [Order11AppNative]::GetForegroundWindow()
    $matches = ($fg -eq $script:appHwnd)
    L ("[VERIFY-FG] Foreground verification after activation click for '{0}': Target=0x{1:X}, CurrentForeground=0x{2:X} (Matches={3})" -f $opLabel, $script:appHwnd.ToInt64(), $fg.ToInt64(), $matches)
    if (-not $matches) {
        $fgTitle = [Order11AppNative]::Title($fg)
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
    [Order11AppNative]::Click($x, $y)
}

function Safe-DoubleClick([int]$x, [int]$y) {
    if ($DryRun) {
        L "[DRYRUN MOCK] Safe-DoubleClick at ($x, $y)"
        return
    }
    Assert-MouseInput $x $y 'DoubleClick'
    [Order11AppNative]::DoubleClick($x, $y)
}

function Safe-MoveTo([int]$x, [int]$y) {
    if ($DryRun) {
        L "[DRYRUN MOCK] Safe-MoveTo at ($x, $y)"
        return
    }
    Assert-MouseInput $x $y 'MoveTo'
    [Order11AppNative]::MoveTo($x, $y)
}

function Safe-KeyPress([byte]$vk) {
    if ($DryRun) {
        L "[DRYRUN MOCK] Safe-KeyPress 0x$($vk.ToString('X2'))"
        return
    }
    Assert-KeyInput "KeyPress(0x$($vk.ToString('X2')))"
    [Order11AppNative]::KeyPress($vk)
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
    [Order11AppNative]::KeyCombo($ushortMods, $ushortKey)
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

    $pt = New-Object Order11AppNative+POINT
    $pt.X = 0; $pt.Y = 0
    if ($hwnd -ne [IntPtr]::Zero) {
        [void][Order11AppNative]::ClientToScreen($hwnd, [ref]$pt)
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

function Get-ActiveTabInfo([string]$outDir) {
    if ($DryRun) {
        return [PSCustomObject]@{
            Name = 'mock-tab'
            Path = 'mock-path'
            Type = 'normal'
        }
    }
    $stdoutPath = Join-Path $outDir 'app-stdout.txt'
    if (-not (Test-Path -LiteralPath $stdoutPath)) {
        return [PSCustomObject]@{ Name = 'unknown'; Path = 'unknown'; Type = 'unknown' }
    }
    $lines = @(Get-Content -LiteralPath $stdoutPath -Encoding utf8)
    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        if ($lines[$i] -match '^\[dev\] tabs .* active=(\d+) count=\d+ list=(.*)$') {
            $actIdx = [int]$matches[1]
            $items = $matches[2] -split "`t"
            if ($actIdx -lt $items.Count) {
                $parts = $items[$actIdx] -split '\|'
                return [PSCustomObject]@{
                    Name = if ($parts.Count -gt 0) { $parts[0] } else { 'unknown' }
                    Type = if ($parts.Count -gt 1) { $parts[1] } else { 'normal' }
                    Path = if ($parts.Count -gt 2) { $parts[2] } else { '' }
                }
            }
        }
    }
    return [PSCustomObject]@{ Name = 'none'; Path = ''; Type = 'none' }
}

function Get-TreeRowBoxByName([IntPtr]$hwnd, [string]$outDir, [string]$fileName, [string]$fixtureDir = '') {
    if ($DryRun) {
        return [PSCustomObject]@{
            X = 150
            Y = 100
            W = 200
            H = 22
            Bounds = @{ name = "tree-row-mock"; x = 50; y = 100; w = 200; h = 22 }
        }
    }
    $foundIndex = -1
    $reason = ''

    $stdoutPath = Join-Path $outDir 'app-stdout.txt'
    if (Test-Path -LiteralPath $stdoutPath) {
        $lines = @(Get-Content -LiteralPath $stdoutPath -Encoding utf8)
        for ($i = $lines.Count - 1; $i -ge 0; $i--) {
            if ($lines[$i] -match '^\[dev\] tree .* rows=(.*)$') {
                $entries = $matches[1] -split "`t"
                for ($ix = 0; $ix -lt $entries.Count; $ix++) {
                    $parts = $entries[$ix] -split '\|'
                    if ($parts.Count -gt 0 -and $parts[0].Trim() -eq $fileName) {
                        $foundIndex = $ix
                        $reason = "stdout tree rows match (index $ix)"
                        break
                    }
                }
                if ($foundIndex -ge 0) { break }
            }
        }
    }

    if ($foundIndex -ge 0) {
        $targetBoxName = ("tree-row-{0:D2}" -f $foundIndex)
        L ("Tree row for '$fileName': index=$foundIndex, target=$targetBoxName ($reason)")
        $coord = Get-BoxScreenCoord $hwnd $outDir $targetBoxName
        if ($coord) { return $coord }
        $coord = Get-BoxScreenCoord $hwnd $outDir ("tree-content-{0:D2}" -f $foundIndex)
        if ($coord) { return $coord }
        $coord = Get-BoxScreenCoord $hwnd $outDir ("tree-label-{0:D2}" -f $foundIndex)
        if ($coord) { return $coord }
    } else {
        L ("Tree row for '$fileName': not found in stdout tree rows")
    }
    return $null
}

function Expand-TreeFolder([IntPtr]$hwnd, [string]$outDir, [string]$folderName, [string]$fixtureDir) {
    if ($DryRun) {
        L "[DRYRUN MOCK] Expand-TreeFolder '$folderName'"
        return $true
    }
    L "Attempting to expand tree folder '$folderName'..."
    $treeRow = Get-TreeRowBoxByName $hwnd $outDir $folderName $fixtureDir
    if (-not $treeRow) {
        L "Tree row for folder '$folderName' not found"
        return $false
    }
    L "Clicking tree folder '$folderName' at screen coords ($($treeRow.X), $($treeRow.Y))..."
    $prevSeq = $script:currentSeq
    Safe-Click $treeRow.X $treeRow.Y
    $snap = Wait-NextSnapshot $outDir $prevSeq 2000
    if ($snap) { $script:currentSeq = $snap.seq }
    L "Tree folder '$folderName' toggled, seq=$($script:currentSeq)"
    return $true
}

function Open-FileFromTree([IntPtr]$hwnd, [string]$outDir, [string]$fileName, [string]$fixtureDir) {
    if ($DryRun) {
        L "[DRYRUN MOCK] Open-FileFromTree '$fileName' succeeded"
        return $true
    }

    $activeTab = Get-ActiveTabInfo $outDir
    if ($activeTab.Name -eq $fileName) {
        L "File '$fileName' is already active tab."
        return $true
    }

    L "Attempting to open file '$fileName' from tree..."
    $ptOrigin = New-Object Order11AppNative+POINT
    $ptOrigin.X = 10; $ptOrigin.Y = 10
    if ($hwnd -ne [IntPtr]::Zero) {
        [void][Order11AppNative]::ClientToScreen($hwnd, [ref]$ptOrigin)
    }
    Safe-MoveTo $ptOrigin.X $ptOrigin.Y
    Start-Sleep -Milliseconds 200

    $treeRow = $null
    for ($attempt = 1; $attempt -le 5; $attempt++) {
        $treeRow = Get-TreeRowBoxByName $hwnd $outDir $fileName $fixtureDir
        if ($treeRow) { break }
        Start-Sleep -Milliseconds 300
    }
    if (-not $treeRow) {
        L "Tree row for '$fileName' not found in layout dump after 5 attempts"
        return $false
    }
    L "Double-clicking tree row for '$fileName' at screen coords ($($treeRow.X), $($treeRow.Y))..."
    $prevSeq = $script:currentSeq
    Safe-DoubleClick $treeRow.X $treeRow.Y
    $snap = Wait-NextSnapshot $outDir $prevSeq 3000
    if ($snap) { $script:currentSeq = $snap.seq }
    return $true
}

# ---------------------------------------------------------------------------
# 5. Fixture Preparation Helper
# ---------------------------------------------------------------------------
function Write-Order11FixtureFiles([string]$targetFixtureDir, [string]$sourceFixtureDir) {
    L "Preparing ORDER-11 fixture files in '$targetFixtureDir' from '$sourceFixtureDir'..."
    New-Item -ItemType Directory -Force $targetFixtureDir | Out-Null

    $dstSyntaxDir = Join-Path $targetFixtureDir 'syntax'
    if (Test-Path -LiteralPath $dstSyntaxDir) {
        Remove-Item -LiteralPath $dstSyntaxDir -Recurse -Force
    }
    New-Item -ItemType Directory -Force $dstSyntaxDir | Out-Null

    if (-not (Test-Path -LiteralPath $sourceFixtureDir)) {
        throw "Source syntax fixtures directory '$sourceFixtureDir' not found!"
    }

    Get-ChildItem -LiteralPath $sourceFixtureDir | Copy-Item -Destination $dstSyntaxDir -Recurse -Force
    $copiedCount = (Get-ChildItem -LiteralPath $dstSyntaxDir -Recurse -File).Count
    L "Copied $copiedCount syntax fixture files into '$dstSyntaxDir'."
    return $dstSyntaxDir
}

# ---------------------------------------------------------------------------
# 6. Syntax Sample Test Runner
# ---------------------------------------------------------------------------
function Process-SyntaxSample(
    [string]$stepKey,
    [string]$fileName,
    [string]$relDir,
    [string]$refPngName,
    [string]$outPrefix,
    [int]$targetLine = 1,
    [string]$mode = 'EditorArea' # EditorArea | ToolbarSymbol | Preview
) {
    Reset-UIState $stepKey
    Ensure-Foreground $script:appHwnd $stepKey

    # Expand folder if file is in a subfolder
    if ($relDir) {
        [void](Expand-TreeFolder $script:appHwnd $Out $relDir $script:fixtureDir)
        Start-Sleep -Milliseconds 200
    }

    # Open file from tree
    $openOk = Open-FileFromTree $script:appHwnd $Out $fileName $script:fixtureDir
    if (-not $openOk -and -not $DryRun) {
        $failMsg = "전제 실패: 파일 '$fileName'을 트리에서 열지 못함"
        $global:summary.results[$stepKey] = $failMsg
        L "[RESULT] ${stepKey}: $failMsg"
        return
    }

    $capPath = Join-Path $Out "$outPrefix.png"
    $cropPath = $null

    if ($mode -eq 'EditorArea') {
        # Click editor area to ensure focus and jump to line 1
        $ptEd = New-Object Order11AppNative+POINT; $ptEd.X = 700; $ptEd.Y = 300
        if ($script:appHwnd -ne [IntPtr]::Zero) {
            [void][Order11AppNative]::ClientToScreen($script:appHwnd, [ref]$ptEd)
        }
        Safe-Click $ptEd.X $ptEd.Y
        Start-Sleep -Milliseconds 100
        Safe-KeyCombo @(0x11) 0x24 # Ctrl + Home
        Start-Sleep -Milliseconds 150

        Capture-WindowClient $script:appHwnd $capPath | Out-Null
        $snap = Get-LatestSnapshot $Out
        $cropPath = Join-Path $Out "$outPrefix-editor.png"
        Crop-EditorArea $capPath $cropPath $snap | Out-Null
    }
    elseif ($mode -eq 'ToolbarSymbol') {
        # Click editor area to ensure focus
        $ptEd = New-Object Order11AppNative+POINT; $ptEd.X = 700; $ptEd.Y = 300
        if ($script:appHwnd -ne [IntPtr]::Zero) {
            [void][Order11AppNative]::ClientToScreen($script:appHwnd, [ref]$ptEd)
        }
        Safe-Click $ptEd.X $ptEd.Y
        Start-Sleep -Milliseconds 100
        Safe-KeyCombo @(0x11) 0x24 # Ctrl + Home
        Start-Sleep -Milliseconds 100

        # Move down to target line
        $downCount = [Math]::Max(0, $targetLine - 1)
        L "Navigating to line $targetLine for symbol check (Down $downCount times)..."
        for ($i = 0; $i -lt $downCount; $i++) {
            Safe-KeyPress 0x28 # Down arrow
            if (-not $DryRun) { Start-Sleep -Milliseconds 30 }
        }
        if (-not $DryRun) { Start-Sleep -Milliseconds 200 }

        Capture-WindowClient $script:appHwnd $capPath | Out-Null
        $snap = Get-LatestSnapshot $Out
        $cropPath = Join-Path $Out "$outPrefix-toolbar.png"
        Crop-ToolbarArea $capPath $cropPath $snap | Out-Null
    }
    elseif ($mode -eq 'Preview') {
        # Find toolbar preview button (Eye)
        $btnCoord = Get-BoxScreenCoord $script:appHwnd $Out 'toolbar-btn-preview'
        if ($btnCoord) {
            L "Found 'toolbar-btn-preview' at ($($btnCoord.X), $($btnCoord.Y)). Clicking to open preview..."
            $prevSeq = $script:currentSeq
            Safe-Click $btnCoord.X $btnCoord.Y
            $snap = Wait-NextSnapshot $Out $prevSeq 2500
            if ($snap) { $script:currentSeq = $snap.seq }
        } else {
            L "toolbar-btn-preview probe not found. Sending Ctrl-K V..."
            Safe-KeyCombo @(0x11) 0x4B # Ctrl + K
            Start-Sleep -Milliseconds 100
            Safe-KeyPress 0x56 # V
            Start-Sleep -Milliseconds 500
        }

        Capture-WindowClient $script:appHwnd $capPath | Out-Null
        $snap = Get-LatestSnapshot $Out
        $cropPath = Join-Path $Out "$outPrefix-crop.png"
        Crop-PreviewArea $capPath $cropPath $snap | Out-Null
    }

    # Record dump state
    $activeTab = Get-ActiveTabInfo $Out
    $cursorLine = if ($mode -eq 'ToolbarSymbol') { "$($targetLine):1" } else { "1:1" }

    $refPath = Join-Path $TauriRefDir $refPngName
    $hasRef = Test-Path -LiteralPath $refPath
    $refHash = if ($hasRef) { Get-Hash $refPath } else { $null }

    $capHash = Get-Hash $capPath
    $cropHash = if ($cropPath) { Get-Hash $cropPath } else { $null }

    $global:summary.captures[$stepKey] = $capPath
    $global:summary.crops[$stepKey] = $cropPath
    $global:summary.hashes["$stepKey-cap"] = $capHash
    $global:summary.hashes["$stepKey-crop"] = $cropHash
    $global:summary.dump[$stepKey] = [ordered]@{
        active_tab = $activeTab.Name
        active_type = $activeTab.Type
        cursor_line = $cursorLine
        mode = $mode
    }
    $global:summary.tauri_refs[$stepKey] = [ordered]@{
        ref_file = $refPngName
        exists = $hasRef
        hash = $refHash
    }

    # Record verdict: Strictly "캡처 OK" or "전제 실패" (Judgment is done by leader viewing captures)
    $resStr = "캡처 OK (탭=$($activeTab.Name), 커서=$cursorLine, ref=$refPngName, ref존재=$hasRef)"
    $global:summary.results[$stepKey] = $resStr
    L "[RESULT] ${stepKey}: $resStr"
}

# ---------------------------------------------------------------------------
# 7. Step Actions (step1 ~ step6)
# ---------------------------------------------------------------------------
$step1Action = {
    # step1 rs·json·md: 각 파일을 트리에서 열어 1행, 캡처(편집 영역). 대조 zed-rs.png·zed-json.png·zed-md.png
    Process-SyntaxSample 'step1-rs' 'sample.rs' '' 'zed-rs.png' 'app-step1-rs' 1 'EditorArea'
    Process-SyntaxSample 'step1-json' 'sample.json' '' 'zed-json.png' 'app-step1-json' 1 'EditorArea'
    Process-SyntaxSample 'step1-md' 'sample.md' '' 'zed-md.png' 'app-step1-md' 1 'EditorArea'
}

$step2Action = {
    # step2 c·cpp·css·html: 같은 방식, 대조 zed-c.png·zed-cpp.png·zed-css.png·zed-html.png
    Process-SyntaxSample 'step2-c' 'sample.c' '' 'zed-c.png' 'app-step2-c' 1 'EditorArea'
    Process-SyntaxSample 'step2-cpp' 'sample.cpp' '' 'zed-cpp.png' 'app-step2-cpp' 1 'EditorArea'
    Process-SyntaxSample 'step2-css' 'sample.css' '' 'zed-css.png' 'app-step2-css' 1 'EditorArea'
    Process-SyntaxSample 'step2-html' 'sample.html' '' 'zed-html.png' 'app-step2-html' 1 'EditorArea'
}

$step3Action = {
    # step3 sh·diff·go·(gomod·gowork·env·COMMIT_EDITMSG 폴더/파일)
    Process-SyntaxSample 'step3-sh' 'sample.sh' '' 'zed-sh.png' 'app-step3-sh' 1 'EditorArea'
    Process-SyntaxSample 'step3-diff' 'sample.diff' '' 'zed-diff.png' 'app-step3-diff' 1 'EditorArea'
    Process-SyntaxSample 'step3-go' 'sample.go' '' 'zed-go.png' 'app-step3-go' 1 'EditorArea'
    Process-SyntaxSample 'step3-gomod' 'go.mod' 'gomod' 'zed-gomod.png' 'app-step3-gomod' 1 'EditorArea'
    Process-SyntaxSample 'step3-gowork' 'go.work' 'gowork' 'zed-gowork.png' 'app-step3-gowork' 1 'EditorArea'
    Process-SyntaxSample 'step3-env' '.env' 'env' 'zed-env.png' 'app-step3-env' 1 'EditorArea'
    Process-SyntaxSample 'step3-commit' 'COMMIT_EDITMSG' '' 'zed-commit.png' 'app-step3-commit' 1 'EditorArea'
}

$step4Action = {
    # step4 py·js·ts·tsx·yaml: 같은 방식, 대조 zed-py.png·zed-js.png·zed-ts.png·zed-tsx.png·zed-yaml.png
    Process-SyntaxSample 'step4-py' 'sample.py' '' 'zed-py.png' 'app-step4-py' 1 'EditorArea'
    Process-SyntaxSample 'step4-js' 'sample.js' '' 'zed-js.png' 'app-step4-js' 1 'EditorArea'
    Process-SyntaxSample 'step4-ts' 'sample.ts' '' 'zed-ts.png' 'app-step4-ts' 1 'EditorArea'
    Process-SyntaxSample 'step4-tsx' 'sample.tsx' '' 'zed-tsx.png' 'app-step4-tsx' 1 'EditorArea'
    Process-SyntaxSample 'step4-yaml' 'sample.yaml' '' 'zed-yaml.png' 'app-step4-yaml' 1 'EditorArea'
}

$step5Action = {
    # step5 경로 줄 심볼: sample.rs·sample.py·sample.ts 첫 줄 주석에 적힌 위치로 이동 후 툴바(경로 줄) 잘라내기
    # sample.rs: 21행 (impl Counter > fn bump > fn clamp), 대조 zed-rs-sym.png
    Process-SyntaxSample 'step5-rs-sym' 'sample.rs' '' 'zed-rs-sym.png' 'app-step5-rs-sym' 21 'ToolbarSymbol'

    # sample.py: 21행 (class Library > def add > def normalize), 대조 zed-py-sym.png
    Process-SyntaxSample 'step5-py-sym' 'sample.py' '' 'zed-py-sym.png' 'app-step5-py-sym' 21 'ToolbarSymbol'

    # sample.ts: 18행 (class Inventory > add > function normalize), 대조 zed-ts-sym.png
    Process-SyntaxSample 'step5-ts-sym' 'sample.ts' '' 'zed-ts-sym.png' 'app-step5-ts-sym' 18 'ToolbarSymbol'
}

$step6Action = {
    # step6 미리보기: sample.md의 미리보기(눈 버튼) 캡처, 대조 zed-md-preview.png
    Process-SyntaxSample 'step6-md-preview' 'sample.md' '' 'zed-md-preview.png' 'app-step6-md-preview' 1 'Preview'
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
            $global:summary.results[$stepKey] = "전제 실패: 앱 프로세스 미실행"
            return
        }
    }

    try {
        & $action
        L "STEP '$stepKey' COMPLETED."
    }
    catch {
        L "FAIL in step '$stepKey': $_"
        $global:summary.results[$stepKey] = "전제 실패: $_"
        L "[RESULT] ${stepKey}: 전제 실패 - $_"
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
$script:fixtureDir = ''

# DRY-RUN MODE: Fast validation of steps, syntax, fixture generation and mock execution
if ($DryRun) {
    L "=================================================================="
    L "ORDER-11 V3 MEASURE SCRIPT - DRY RUN MODE (WITH MOCK EXECUTION)"
    L "=================================================================="
    L "Validating fixture generation into '$dryRunFixtureDir' from '$SyntaxFixtureDir'..."
    $script:fixtureDir = Write-Order11FixtureFiles $dryRunFixtureDir $SyntaxFixtureDir

    L "Tauri Reference Directory: '$TauriRefDir'"
    if (Test-Path -LiteralPath $TauriRefDir) {
        $refCount = (Get-ChildItem -LiteralPath $TauriRefDir -Filter 'zed-*.png').Count
        L "Found $refCount Zed reference captures in '$TauriRefDir'."
    } else {
        L "WARN: TauriRefDir '$TauriRefDir' does not exist."
    }

    if ($ReplayStdout) {
        L "=================================================================="
        L "REPLAY STDOUT VERIFICATION FOR ORDER-11"
        L "=================================================================="
        $repSnap = Get-LatestSnapshot $Out
        if ($repSnap) {
            L "[REPLAY] Snapshot detected: seq=$($repSnap.seq), boxes count=$($repSnap.boxes.Count)"
        }
    }

    L "=================================================================="
    L "EXECUTING 6 STEPS WITH MOCK INPUTS (DRY-RUN RUNTIME TEST)"
    L "=================================================================="

    Invoke-MeasureStep 'step1' 'I-15: Syntax bundle 1 (rs, json, md)' $step1Action
    Invoke-MeasureStep 'step2' 'I-15: Syntax bundle 2 (c, cpp, css, html)' $step2Action
    Invoke-MeasureStep 'step3' 'I-15: Syntax bundle 3 (sh, diff, go, subfolders/files)' $step3Action
    Invoke-MeasureStep 'step4' 'I-15: Syntax bundle 4 (py, js, ts, tsx, yaml)' $step4Action
    Invoke-MeasureStep 'step5' 'I-12: Breadcrumb Symbol Hierarchy (sample.rs, sample.py, sample.ts)' $step5Action
    Invoke-MeasureStep 'step6' 'ORDER-11 3.3: Markdown Preview Code Block & Render' $step6Action

    L "=================================================================="
    L "DRY-RUN RUNTIME VALIDATION SUMMARY: Errors = $script:dryRunErrors"
    if ($script:dryRunErrors -gt 0) {
        throw "DryRun failed with $script:dryRunErrors runtime errors"
    }

    $summaryJson = Join-Path $Out 'order11-summary.json'
    $global:summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $summaryJson -Encoding utf8
    L "Summary written to $summaryJson"

    L "[DRYRUN] Completed successfully. All 6 steps executed with 0 runtime errors."
    L "[DRYRUN] Exiting without launching app or session.ps1."
    return
}

# LIVE EXECUTION: Controlled by leader with [SCREEN-OK]
$sessionScript = 'tools\measure\session.ps1'
if (-not (Test-Path -LiteralPath $sessionScript)) {
    throw "session.ps1 not found at '$sessionScript'"
}

try {
    L "Starting ORDER-11 live measurement session..."

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

    # 2. Populate Syntax Fixtures into Session Directory
    $script:fixtureDir = Write-Order11FixtureFiles $targetFixture $SyntaxFixtureDir

    # Set pick.txt to syntax folder
    $pickPath = Join-Path $Out 'pick.txt'
    $script:fixtureDir | Set-Content -LiteralPath $pickPath -Encoding utf8

    # 3. Locate Main Window HWND with 15-second retry loop
    L "Searching for main window HWND of PID $script:appPid (up to 15s)..."
    for ($i = 1; $i -le 50; $i++) {
        Start-Sleep -Milliseconds 300
        $p = Get-Process -Id $script:appPid -ErrorAction SilentlyContinue
        if ($p -and $p.MainWindowHandle -ne [IntPtr]::Zero) {
            $script:appHwnd = $p.MainWindowHandle
            break
        }
        $hwnds = [Order11AppNative]::GetProcessTopLevelWindows(@([uint32]$script:appPid))
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
                    L "Project tree loaded at seq=$($script:currentSeq) in $($swTree.ElapsedMilliseconds)ms"
                    break
                }
                Start-Sleep -Milliseconds 300
            }
        }
    }

    $global:summary.results['setup'] = "PASS - Syntax fixture folder loaded into workspace"
    L "[RESULT] setup: PASS - Syntax fixture folder loaded into workspace"

    if ($normalizedSteps.Contains('setup') -and (-not ($normalizedSteps | Where-Object { $_ -ne 'setup' }))) {
        L "-Steps setup requested: Setup completed successfully. Exiting."
        return
    }

    # Execute all 6 measurement steps
    Invoke-MeasureStep 'step1' 'I-15: Syntax bundle 1 (rs, json, md)' $step1Action
    Invoke-MeasureStep 'step2' 'I-15: Syntax bundle 2 (c, cpp, css, html)' $step2Action
    Invoke-MeasureStep 'step3' 'I-15: Syntax bundle 3 (sh, diff, go, subfolders/files)' $step3Action
    Invoke-MeasureStep 'step4' 'I-15: Syntax bundle 4 (py, js, ts, tsx, yaml)' $step4Action
    Invoke-MeasureStep 'step5' 'I-12: Breadcrumb Symbol Hierarchy (sample.rs, sample.py, sample.ts)' $step5Action
    Invoke-MeasureStep 'step6' 'ORDER-11 3.3: Markdown Preview Code Block & Render' $step6Action
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

    $summaryJson = Join-Path $Out 'order11-summary.json'
    $global:summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $summaryJson -Encoding utf8
    L "Summary written to $summaryJson"
}

L "ORDER-11 V3 measurement run completed."

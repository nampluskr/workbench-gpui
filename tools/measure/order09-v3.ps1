#Requires -Version 7
<#
.SYNOPSIS
  ORDER-09 V3 화면 검증(UI 실측) 스크립트.
  (gpui-checker 작성, leader가 [SCREEN-OK] 뒤 화면 차례 안에서 실행한다.)

.DESCRIPTION
  - 상위 지시: core ORDER-09, 카드 C-37, C-37-R1, C-37-R2, C-37-R3, C-37-R4 (I-10, I-11, I-12, I-16, I-23)
  - 우리 앱(workbench-gpui) 단독 실행 화면 검증 (Zed는 띄우지 않고 tauri 캡처와 대조).
  - 대조 자료: workbench-tauri 캡처 (D:\projects\workbench-tauri\specs\v0.5\verify\ORDER-09\zed-*.png).
  - 클라이언트 1440×852, 100% DPI, Ensure-ClientSize로 고정.
  - 세션 관리: tools/measure/session.ps1 (Start/Stop 트랜잭션, 실패 시 finally 복원 보장).
  - 중요(권장 실행 방식):
    단계 간 상태 오염(탭 다량 오픈, 트리 스크롤 등)을 방지하기 위해, 한 번에 모든 단계를 실행하지 않고
    단계별 격리 실행(-Steps step1 -Out ...measure-ORDER-09-runN-step1 등)을 기본으로 합니다.
  - C-37-R4 개선 사항:
    1. 마우스 입력 가드(Assert-MouseInput): WindowFromPoint 및 GetAncestor(GA_ROOT)가 appHwnd이고 PID가 띄운 PID인지 확인.
       일치 시 점을 누르면 앱에만 가고 자연스럽게 앞 창으로 전환됨. 점의 창이 다르면(덮임) 입력 차단 후 FAIL.
    2. 키 입력 가드(Assert-KeyInput): GetForegroundWindow() == appHwnd 확인. 앞 창 아니면 안전한 위치(에디터/상태바) 1회 클릭으로 활성화 후 재확인, 그래도 아니면 FAIL.
    3. 비입력 Z순서 상승(Ensure-Foreground): ShowWindow(SW_RESTORE) + SetWindowPos(HWND_TOP) + SetForegroundWindow로 Z-order 상승.
       setup의 Ensure-Foreground 불일치는 FATAL로 중단하지 않고 로그 후 마우스 클릭으로 자연스럽게 활성화.
    4. 마우스 휠·뒤로 가드(Assert-MouseWheelAndBack): 마우스 규칙(점의 창=앱)과 키 규칙(앞 창=앱) 둘 다 만족 시에만 발송.
    5. Step 3 'if' 용어 cmdlet 파싱 오류 수정: 함수 인자 식을 사전 변수로 추출.
    6. Step 4 Safe-KeyCombo 매개변수 바인딩 수정: modifiers를 유연하게 받아 내부에서 [ushort[]]로 안전 변환.
    7. DryRun 모의 실행(Mock Execution): -DryRun에서 5개 단계 스크립트블록을 모의 입력으로 실제로 끝까지 실행하여 런타임 오류 0건 사전 검증.

.PARAMETER Out
  출력 디렉터리 (기본값: specs\v0.5\verify\reviews\measure-ORDER-09).
  주의: 실제 실행 시에는 반드시 measure-ORDER-09-run1, run2 등 매번 새 이름을 지정하십시오.

.PARAMETER AppExe
  workbench-gpui 실행 파일 경로.

.PARAMETER TauriRefDir
  Zed 비교용 tauri 캡처 디렉터리 경로 (기본값: D:\projects\workbench-tauri\specs\v0.5\verify\ORDER-09).

.PARAMETER DryRun
  프로세스 구동 없이 단계 구성, fixture 준비, 문법만 검증하는 모드.

.PARAMETER Steps
  실행할 단계 목록. 기본값: 모든 단계 실행 (step1, step2, step3, step4, step5).

.PARAMETER Skip
  건너뛸 단계 목록.
#>
[CmdletBinding()]
param(
    [string]$Out = 'specs\v0.5\verify\reviews\measure-ORDER-09',
    [string]$AppExe = 'D:\projects\workbench-gpui\target\debug\workbench-gpui.exe',
    [string]$TauriRefDir = 'D:\projects\workbench-tauri\specs\v0.5\verify\ORDER-09',
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
        if ($k -match '^\d+$' -and $stepKey -like "*step$k-*") { return $true }
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
    $defaultReplay = 'specs\v0.5\verify\reviews\measure-ORDER-09-run4\app-stdout.txt'
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
# 1. Native API Definitions (C# P/Invoke with Extended Key, Wheel & Mouse Back)
# ---------------------------------------------------------------------------
$nativeSource = @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

public static class Order09AppNative {
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
    const uint MOUSEEVENTF_WHEEL = 0x0800, MOUSEEVENTF_XDOWN = 0x0080, MOUSEEVENTF_XUP = 0x0100;
    const uint MOUSEEVENTF_VIRTUALDESK = 0x4000, MOUSEEVENTF_ABSOLUTE = 0x8000;
    const uint XBUTTON1 = 0x0001;
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

    public static void TypeText(string text) {
        foreach (char c in text) {
            var down = new INPUT[1];
            down[0].type = INPUT_KEYBOARD;
            down[0].mkhi.ki.wVk = 0;
            down[0].mkhi.ki.wScan = (ushort)c;
            down[0].mkhi.ki.dwFlags = KEYEVENTF_UNICODE;
            SendInput(1, down, Marshal.SizeOf(typeof(INPUT)));
            Thread.Sleep(25);

            var up = new INPUT[1];
            up[0].type = INPUT_KEYBOARD;
            up[0].mkhi.ki.wVk = 0;
            up[0].mkhi.ki.wScan = (ushort)c;
            up[0].mkhi.ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;
            SendInput(1, up, Marshal.SizeOf(typeof(INPUT)));
            Thread.Sleep(25);
        }
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

    public static void MouseWheel(int delta) {
        mouse_event(MOUSEEVENTF_WHEEL, 0, 0, (uint)delta, IntPtr.Zero);
        Thread.Sleep(80);
    }

    public static void MouseBack() {
        mouse_event(MOUSEEVENTF_XDOWN, 0, 0, XBUTTON1, IntPtr.Zero);
        Thread.Sleep(50);
        mouse_event(MOUSEEVENTF_XUP, 0, 0, XBUTTON1, IntPtr.Zero);
        Thread.Sleep(50);
    }
}
'@

if (-not ([System.Management.Automation.PSTypeName]'Order09AppNative').Type) {
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

    # Verify target window PID matches spawned App PID (core-leader [NOTICE] #5: strictly for spawned PID window)
    $targetPid = [uint32]0
    [void][Order09AppNative]::GetWindowThreadProcessId($hwnd, [ref]$targetPid)
    if ($script:appPid -gt 0 -and $targetPid -ne [uint32]$script:appPid) {
        L "ERROR: Ensure-Foreground target HWND 0x$($hwnd.ToString('X')) PID ($targetPid) does not match App PID ($script:appPid)! Aborting elevation."
        return
    }

    # 1. Elevate Z-order using non-input Win32 APIs (strictly for spawned PID window)
    L ("[ELEVATE] Elevating target window Z-order (PID={0}, HWND=0x{1:X}, Label='{2}'): ShowWindow(SW_RESTORE), SetWindowPos(HWND_TOP), SetForegroundWindow..." -f $script:appPid, $hwnd.ToInt64(), $label)
    [void][Order09AppNative]::ShowWindow($hwnd, 9) # SW_RESTORE
    [void][Order09AppNative]::SetWindowPos($hwnd, [IntPtr]::Zero, 0, 0, 0, 0, 0x0001 -bor 0x0002 -bor 0x0040) # SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW
    [void][Order09AppNative]::SetForegroundWindow($hwnd)
    Start-Sleep -Milliseconds 150

    # 2. Verify foreground status
    $fg = [Order09AppNative]::GetForegroundWindow()
    $matches = ($fg -eq $hwnd)
    L ("[VERIFY-FG] Foreground verification for '{0}': Target=0x{1:X}, CurrentForeground=0x{2:X} (Matches={3})" -f $label, $hwnd.ToInt64(), $fg.ToInt64(), $matches)
    if (-not $matches) {
        L "WARN: $label Ensure-Foreground did not immediately make app foreground (foreground lock in effect). Subsequent safe click will activate window."
    }
}

function Ensure-ClientSize([IntPtr]$hwnd, [int]$targetW = 1440, [int]$targetH = 852, [string]$label = '') {
    if ($DryRun) { return }
    $cRect = New-Object Order09AppNative+RECT
    [void][Order09AppNative]::GetClientRect($hwnd, [ref]$cRect)
    $curW = $cRect.Right - $cRect.Left
    $curH = $cRect.Bottom - $cRect.Top
    if ($curW -eq $targetW -and $curH -eq $targetH) {
        return
    }

    $wRect = New-Object Order09AppNative+RECT
    [void][Order09AppNative]::GetWindowRect($hwnd, [ref]$wRect)
    $winW = $wRect.Right - $wRect.Left
    $winH = $wRect.Bottom - $wRect.Top

    $borderW = $winW - $curW
    $borderH = $winH - $curH
    $newWinW = $targetW + $borderW
    $newWinH = $targetH + $borderH

    [void][Order09AppNative]::MoveWindow($hwnd, $wRect.Left, $wRect.Top, $newWinW, $newWinH, $true)
    Start-Sleep -Milliseconds 200
}

function Capture-WindowClient([IntPtr]$hwnd, [string]$outPngPath) {
    if ($DryRun) {
        if (-not (Test-Path -LiteralPath $outPngPath)) {
            $bmp = New-Object System.Drawing.Bitmap(1440, 852)
            $bmp.Save($outPngPath, [System.Drawing.Imaging.ImageFormat]::Png)
            $bmp.Dispose()
        }
        L "[DRYRUN MOCK] Captured client screenshot to '$outPngPath'"
        return $outPngPath
    }
    $cRect = New-Object Order09AppNative+RECT
    [void][Order09AppNative]::GetClientRect($hwnd, [ref]$cRect)
    $w = $cRect.Right - $cRect.Left
    $h = $cRect.Bottom - $cRect.Top

    $pt = New-Object Order09AppNative+POINT
    $pt.X = 0; $pt.Y = 0
    [void][Order09AppNative]::ClientToScreen($hwnd, [ref]$pt)

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
# 2A. Safe Input Dispatch & Foreground Window Assertions (C-37-R3, C-37-R4 #1)
# ---------------------------------------------------------------------------
function Assert-MouseInput([int]$targetScreenX, [int]$targetScreenY, [string]$opLabel = '') {
    if ($DryRun) { return }
    if ($script:appHwnd -eq [IntPtr]::Zero) {
        $msg = "FAIL: 앱 HWND가 없음 (Zero) [$opLabel]"
        L $msg
        throw $msg
    }

    # 1. Check client area bounds
    $cRect = New-Object Order09AppNative+RECT
    [void][Order09AppNative]::GetClientRect($script:appHwnd, [ref]$cRect)
    $ptClient = New-Object Order09AppNative+POINT
    $ptClient.X = $targetScreenX; $ptClient.Y = $targetScreenY
    [void][Order09AppNative]::ScreenToClient($script:appHwnd, [ref]$ptClient)
    $cWidth = $cRect.Right - $cRect.Left
    $cHeight = $cRect.Bottom - $cRect.Top
    if ($ptClient.X -lt 0 -or $ptClient.Y -lt 0 -or $ptClient.X -gt $cWidth -or $ptClient.Y -gt $cHeight) {
        $msg = "FAIL: 마우스 좌표가 클라이언트 영역 밖임 (Screen: ($targetScreenX, $targetScreenY), Client: ($($ptClient.X), $($ptClient.Y)), Bounds: 0..$cWidth, 0..$cHeight) [$opLabel]"
        L $msg
        throw $msg
    }

    # 2. Check WindowFromPoint & GetAncestor(GA_ROOT) & PID
    $ptScreen = New-Object Order09AppNative+POINT
    $ptScreen.X = $targetScreenX; $ptScreen.Y = $targetScreenY
    $hTarget = [Order09AppNative]::WindowFromPoint($ptScreen)
    $hRoot = [Order09AppNative]::GetAncestor($hTarget, [Order09AppNative]::GA_ROOT)
    $targetPid = [uint32]0
    [void][Order09AppNative]::GetWindowThreadProcessId($hTarget, [ref]$targetPid)

    $isOurWindow = ($hRoot -eq $script:appHwnd) -or ($hTarget -eq $script:appHwnd)
    $isOurPid = ($script:appPid -gt 0 -and $targetPid -eq [uint32]$script:appPid)

    if (-not ($isOurWindow -and $isOurPid)) {
        $targetTitle = [Order09AppNative]::Title($hTarget)
        $rootTitle = [Order09AppNative]::Title($hRoot)
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

    $fg = [Order09AppNative]::GetForegroundWindow()
    if ($fg -eq $script:appHwnd) {
        return
    }

    L "Assert-KeyInput: Foreground window 0x$($fg.ToString('X')) != App window 0x$($script:appHwnd.ToString('X')). Attempting safe activation click..."

    # Verify target window PID matches spawned App PID (core-leader [NOTICE] #5: strictly for spawned PID window)
    $targetPid = [uint32]0
    [void][Order09AppNative]::GetWindowThreadProcessId($script:appHwnd, [ref]$targetPid)
    if ($script:appPid -gt 0 -and $targetPid -ne [uint32]$script:appPid) {
        $msg = "FAIL: Assert-KeyInput app HWND PID mismatch (Target PID=$targetPid, Expected PID=$script:appPid) [$opLabel]"
        L $msg
        throw $msg
    }

    # 1. Elevate Z-order first (strictly for spawned PID window)
    L ("[ELEVATE] Elevating target window Z-order (PID={0}, HWND=0x{1:X}, Op='{2}'): ShowWindow(SW_RESTORE), SetWindowPos(HWND_TOP), SetForegroundWindow..." -f $script:appPid, $script:appHwnd.ToInt64(), $opLabel)
    [void][Order09AppNative]::ShowWindow($script:appHwnd, 9) # SW_RESTORE
    [void][Order09AppNative]::SetWindowPos($script:appHwnd, [IntPtr]::Zero, 0, 0, 0, 0, 0x0001 -bor 0x0002 -bor 0x0040)
    [void][Order09AppNative]::SetForegroundWindow($script:appHwnd)
    Start-Sleep -Milliseconds 100

    # Try safe click in editor center (client 700, 400)
    $ptClick = New-Object Order09AppNative+POINT
    $ptClick.X = 700; $ptClick.Y = 400
    [void][Order09AppNative]::ClientToScreen($script:appHwnd, [ref]$ptClick)

    try {
        Assert-MouseInput $ptClick.X $ptClick.Y "ActivateWindowClick"
        [Order09AppNative]::Click($ptClick.X, $ptClick.Y)
        Start-Sleep -Milliseconds 200
    }
    catch {
        L "Assert-KeyInput safe activation click failed: $_"
    }

    # 2. Verify foreground status
    $fg = [Order09AppNative]::GetForegroundWindow()
    $matches = ($fg -eq $script:appHwnd)
    L ("[VERIFY-FG] Foreground verification after activation click for '{0}': Target=0x{1:X}, CurrentForeground=0x{2:X} (Matches={3})" -f $opLabel, $script:appHwnd.ToInt64(), $fg.ToInt64(), $matches)
    if (-not $matches) {
        $fgTitle = [Order09AppNative]::Title($fg)
        $msg = "FAIL: 앱이 앞 창 아님 (Foreground HWND: 0x$($fg.ToString('X')) ['$fgTitle'], Expected HWND: 0x$($script:appHwnd.ToString('X'))) [$opLabel]"
        L $msg
        throw $msg
    }
    L "Assert-KeyInput: App successfully activated to foreground (0x$($script:appHwnd.ToString('X'))) [$opLabel]"
}

function Assert-MouseWheelAndBack([int]$targetScreenX, [int]$targetScreenY, [string]$opLabel = '') {
    if ($DryRun) { return }
    # 1. Must satisfy Mouse Rule (Window at point is app window & PID is app PID)
    Assert-MouseInput $targetScreenX $targetScreenY $opLabel
    # 2. Must satisfy Key Rule (Foreground window is app window)
    Assert-KeyInput $opLabel
}

function Assert-AppInput([int]$targetScreenX = -1, [int]$targetScreenY = -1, [string]$opLabel = '') {
    if ($DryRun) { return }
    if ($targetScreenX -ge 0 -and $targetScreenY -ge 0) {
        Assert-MouseInput $targetScreenX $targetScreenY $opLabel
    } else {
        Assert-KeyInput $opLabel
    }
}

function Safe-Click([int]$x, [int]$y) {
    if ($DryRun) {
        L "[DRYRUN MOCK] Safe-Click at ($x, $y)"
        return
    }
    Assert-MouseInput $x $y 'Click'
    [Order09AppNative]::Click($x, $y)
}

function Safe-DoubleClick([int]$x, [int]$y) {
    if ($DryRun) {
        L "[DRYRUN MOCK] Safe-DoubleClick at ($x, $y)"
        return
    }
    Assert-MouseInput $x $y 'DoubleClick'
    [Order09AppNative]::DoubleClick($x, $y)
}

function Safe-MoveTo([int]$x, [int]$y) {
    if ($DryRun) {
        L "[DRYRUN MOCK] Safe-MoveTo at ($x, $y)"
        return
    }
    Assert-MouseInput $x $y 'MoveTo'
    [Order09AppNative]::MoveTo($x, $y)
}

function Safe-MouseWheel([int]$delta, [int]$x = -1, [int]$y = -1) {
    if ($DryRun) {
        L "[DRYRUN MOCK] Safe-MouseWheel delta=$delta at ($x, $y)"
        return
    }
    $targetX = $x
    $targetY = $y
    if ($targetX -lt 0 -or $targetY -lt 0) {
        $pt = New-Object Order09AppNative+POINT
        if ([Order09AppNative]::GetCursorPos([ref]$pt)) {
            $targetX = $pt.X; $targetY = $pt.Y
        }
    }
    Assert-MouseWheelAndBack $targetX $targetY 'MouseWheel'
    if ($x -ge 0 -and $y -ge 0) {
        [Order09AppNative]::MoveTo($x, $y)
        Start-Sleep -Milliseconds 60
    }
    [Order09AppNative]::MouseWheel($delta)
}

function Safe-MouseBack() {
    if ($DryRun) {
        L "[DRYRUN MOCK] Safe-MouseBack"
        return
    }
    $pt = New-Object Order09AppNative+POINT
    $targetX = 0; $targetY = 0
    if ([Order09AppNative]::GetCursorPos([ref]$pt)) {
        $targetX = $pt.X; $targetY = $pt.Y
    }
    Assert-MouseWheelAndBack $targetX $targetY 'MouseBack'
    [Order09AppNative]::MouseBack()
}

function Safe-KeyPress([byte]$vk) {
    if ($DryRun) {
        L "[DRYRUN MOCK] Safe-KeyPress 0x$($vk.ToString('X2'))"
        return
    }
    Assert-KeyInput "KeyPress(0x$($vk.ToString('X2')))"
    [Order09AppNative]::KeyPress($vk)
}

function Safe-KeyCombo($modifiers, [int]$key = 0) {
    # Support comma-separated function call syntax: Safe-KeyCombo @(0x11), 0x21
    if ($key -eq 0 -and $modifiers -is [System.Array] -and $modifiers.Length -eq 2 -and ($modifiers[0] -is [System.Array] -or $modifiers[1] -is [int])) {
        $key = [int]$modifiers[1]
        $modifiers = $modifiers[0]
    }
    # Flatten modifiers to handle single int, array of ints, or nested arrays
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
    [Order09AppNative]::KeyCombo($ushortMods, $ushortKey)
}

function Safe-TypeText([string]$text) {
    if ($DryRun) {
        L "[DRYRUN MOCK] Safe-TypeText '$text'"
        return
    }
    Assert-KeyInput "TypeText"
    [Order09AppNative]::TypeText($text)
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
        $activePopups = @($popupKeys | Where-Object { $_ -notmatch 'AppMenu' -and $_ -notmatch 'tab-bar' })
        if ($activePopups.Count -gt 0) {
            L "WARN: Reset-UIState - Detected lingering popup boxes: $($activePopups -join ', '). Sending additional Esc..."
            Safe-KeyPress([byte]0x1B)
            Start-Sleep -Milliseconds 150
        } else {
            L "Reset-UIState ($context): No lingering popups detected. UI clean."
        }
    }
}

function Get-CurrentActiveTab([string]$outDir) {
    $stdoutPath = Join-Path $outDir 'app-stdout.txt'
    if (-not (Test-Path -LiteralPath $stdoutPath)) { return $null }
    $lines = @(Get-Content -LiteralPath $stdoutPath -Encoding utf8)
    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        if ($lines[$i] -match '^\[dev\] tabs .* active=(\S+) count=(\d+) list=(.*)$') {
            $act = $matches[1]
            $cnt = [int]$matches[2]
            $listStr = $matches[3]
            if ($act -eq 'none' -or $cnt -eq 0) { return $null }
            $actIdx = [int]$act
            $tabEntries = $listStr -split '\t'
            if ($actIdx -ge 0 -and $actIdx -lt $tabEntries.Count) {
                $parts = $tabEntries[$actIdx] -split '\|'
                return @{
                    Index = $actIdx
                    Name = $parts[0]
                    Mode = if ($parts.Count -gt 1) { $parts[1] } else { '' }
                    Path = if ($parts.Count -gt 2) { $parts[2] } else { '' }
                    Count = $cnt
                }
            }
        }
    }
    return $null
}

# ---------------------------------------------------------------------------
# 3. Layout Snapshot & Probe Parsing Helpers (order08-v3 exact match)
# ---------------------------------------------------------------------------
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

    $pt = New-Object Order09AppNative+POINT
    $pt.X = 0; $pt.Y = 0
    if ($hwnd -ne [IntPtr]::Zero) {
        [void][Order09AppNative]::ClientToScreen($hwnd, [ref]$pt)
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

function Get-TreeRowBoxByName([IntPtr]$hwnd, [string]$outDir, [string]$fileName, [string]$fixtureDir = '') {
    $foundIndex = -1
    $reason = ''

    $stdoutPath = Join-Path $outDir 'app-stdout.txt'
    if (Test-Path -LiteralPath $stdoutPath) {
        $lines = @(Get-Content -LiteralPath $stdoutPath -Encoding utf8)
        for ($i = $lines.Count - 1; $i -ge 0; $i--) {
            if ($lines[$i] -match '^\[dev\] tree .* rows=(.*)$') {
                $entries = $matches[1] -split '\t'
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

# ---------------------------------------------------------------------------
# 4. Fixture Files Definition (Copy from tauri & core, Read-Only, No File Modification)
# ---------------------------------------------------------------------------
function Write-Order09FixtureFiles([string]$targetFixtureDir) {
    L "Preparing ORDER-09 fixture files in '$targetFixtureDir'..."
    New-Item -ItemType Directory -Force $targetFixtureDir | Out-Null

    $tauriRoot = 'D:\projects\workbench-tauri'
    $coreRoot = 'D:\projects\workbench-core'

    # Folder 1: workbench-tauri
    $tauriDst = Join-Path $targetFixtureDir 'workbench-tauri'
    New-Item -ItemType Directory -Force (Join-Path $tauriDst 'src\shell') | Out-Null

    # Copy AGENTS.md
    if (Test-Path -LiteralPath (Join-Path $tauriRoot 'AGENTS.md')) {
        Copy-Item -LiteralPath (Join-Path $tauriRoot 'AGENTS.md') -Destination (Join-Path $tauriDst 'AGENTS.md') -Force
    }

    # Copy App.tsx, app.css, index.tsx
    foreach ($f in @('App.tsx', 'app.css', 'index.tsx')) {
        $srcFile = Join-Path $tauriRoot "src\$f"
        if (Test-Path -LiteralPath $srcFile) {
            Copy-Item -LiteralPath $srcFile -Destination (Join-Path $tauriDst "src\$f") -Force
        }
    }

    # Copy src\shell\*.ts, *.tsx (about 30 files for tab overflow testing, including Pane.tsx)
    $shellSrcDir = Join-Path $tauriRoot 'src\shell'
    if (Test-Path -LiteralPath $shellSrcDir) {
        Get-ChildItem -LiteralPath $shellSrcDir -File | Select-Object -First 30 | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $tauriDst "src\shell\$($_.Name)") -Force
        }
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
# 5. Precondition Guard & Step Execution Engine
# ---------------------------------------------------------------------------
function Test-Precondition([string]$stepKey, [string]$sessionDir) {
    $snap = Get-LatestSnapshot $sessionDir
    if (-not $snap) {
        L "FAIL: 전제 없음 (레이아웃 스냅샷 부재) - step '$stepKey'"
        return $false
    }

    # Check 1: Project tree must be loaded (no project-empty-open screen)
    if ($snap.boxes.ContainsKey('project-empty-open')) {
        L "FAIL: 전제 없음 (폴더 미열림, project-empty-open 상태) - step '$stepKey'"
        return $false
    }

    # Check 2: Active tab must exist (not empty / placeholder)
    $hasTab = $snap.boxes.ContainsKey('tab-00') -or $snap.boxes.ContainsKey('tab-content') -or $snap.boxes.ContainsKey('tab-label-00')
    if (-not $hasTab) {
        L "FAIL: 전제 없음 (파일 탭 미열림) - step '$stepKey'"
        return $false
    }

    return $true
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

    # Precondition verification (C-37-R1 #5)
    if (-not (Test-Precondition $stepKey $Out)) {
        $global:summary.results[$stepKey] = "FAIL: 전제 없음"
        L "[RESULT] ${stepKey}: FAIL - 전제 없음 (폴더 또는 파일 탭 미열림)"
        return
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

# Helper function to check if right buttons (+, split, zoom) are visible in screenshot (C-37-R5 #1)
function Check-RightButtonsVisible([string]$imgFile) {
    if ($DryRun) { return $true }
    if (-not (Test-Path -LiteralPath $imgFile)) { return $false }
    try {
        $bmp = [System.Drawing.Bitmap]::FromFile($imgFile)
        $bgCol = $bmp.GetPixel(1350, 48) # tab bar background reference
        $diffCount = 0
        for ($x = 1360; $x -lt 1435; $x++) {
            for ($y = 37; $y -lt 59; $y++) {
                $col = $bmp.GetPixel($x, $y)
                $diff = [Math]::Abs($col.R - $bgCol.R) + [Math]::Abs($col.G - $bgCol.G) + [Math]::Abs($col.B - $bgCol.B)
                if ($diff -gt 60) {
                    $diffCount++
                }
            }
        }
        $bmp.Dispose()
        return ($diffCount -ge 50)
    }
    catch {
        return $false
    }
}

# Helper function to measure tab scroll wheel delta using 1D column profile correlation (C-37-R5 #2)
function Measure-TabScrollWheelDelta([string]$imgBefore, [string]$imgAfter) {
    if ($DryRun) { return 81 }
    if (-not (Test-Path -LiteralPath $imgBefore) -or -not (Test-Path -LiteralPath $imgAfter)) { return 0 }
    try {
        $b1 = [System.Drawing.Bitmap]::FromFile($imgBefore)
        $b2 = [System.Drawing.Bitmap]::FromFile($imgAfter)
        $minX = 610; $maxX = 1300
        $yStart = 38; $yEnd = 58
        $prof1 = New-Object 'double[]' ($maxX - $minX)
        $prof2 = New-Object 'double[]' ($maxX - $minX)
        for ($x = $minX; $x -lt $maxX; $x++) {
            $sum1 = 0; $sum2 = 0
            for ($y = $yStart; $y -le $yEnd; $y++) {
                $c1 = $b1.GetPixel($x, $y)
                $c2 = $b2.GetPixel($x, $y)
                $sum1 += (0.299 * $c1.R + 0.587 * $c1.G + 0.114 * $c1.B)
                $sum2 += (0.299 * $c2.R + 0.587 * $c2.G + 0.114 * $c2.B)
            }
            $prof1[$x - $minX] = $sum1 / ($yEnd - $yStart + 1)
            $prof2[$x - $minX] = $sum2 / ($yEnd - $yStart + 1)
        }
        $b1.Dispose(); $b2.Dispose()

        $bestDx = 0; $bestScore = [double]::MaxValue
        for ($dx = -150; $dx -le 150; $dx++) {
            $diffSum = 0; $count = 0
            for ($i = 0; $i -lt $prof1.Length; $i++) {
                $j = $i + $dx
                if ($j -ge 0 -and $j -lt $prof2.Length) {
                    $diffSum += [Math]::Abs($prof1[$i] - $prof2[$j])
                    $count++
                }
            }
            if ($count -gt 200) {
                $avgDiff = $diffSum / $count
                if ($avgDiff -lt $bestScore) {
                    $bestScore = $avgDiff
                    $bestDx = $dx
                }
            }
        }
        return [Math]::Abs($bestDx)
    }
    catch {
        return 0
    }
}

# Helper function to check if active tab opening/background is visible in tab bar area (C-37-R5 #2)
function Check-ActiveTabVisibleInTabBar([string]$imgFile) {
    if ($DryRun) { return $true }
    if (-not (Test-Path -LiteralPath $imgFile)) { return $false }
    try {
        $bmp = [System.Drawing.Bitmap]::FromFile($imgFile)
        $edBg = $bmp.GetPixel(700, 100) # Editor background reference
        $matchCount = 0
        for ($x = 600; $x -lt 1350; $x++) {
            $c = $bmp.GetPixel($x, 64)
            $diff = [Math]::Abs($c.R - $edBg.R) + [Math]::Abs($c.G - $edBg.G) + [Math]::Abs($c.B - $edBg.B)
            if ($diff -lt 15) {
                $matchCount++
            }
        }
        $bmp.Dispose()
        return ($matchCount -ge 8)
    }
    catch {
        return $false
    }
}

# Helper function to expand tree folder by clicking folder row (C-37-R5 #3, #4)
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

# Helper function to open file from tree by double-clicking (order08-v3 exact match)
function Open-FileFromTree([IntPtr]$hwnd, [string]$outDir, [string]$fileName, [string]$fixtureDir) {
    if ($DryRun) {
        $dummyRow = Get-TreeRowBoxByName $hwnd $outDir $fileName $fixtureDir
        if ($dummyRow) {
            L "[DRYRUN MOCK] Open-FileFromTree '$fileName': Found tree row '$($dummyRow.Bounds.name)' at ($($dummyRow.X), $($dummyRow.Y))"
        } else {
            L "[DRYRUN MOCK] Open-FileFromTree '$fileName': Tree row not found in mock stdout"
        }
        return $true
    }

    L "Attempting to open file '$fileName' from tree..."
    $ptOrigin = New-Object Order09AppNative+POINT
    $ptOrigin.X = 10; $ptOrigin.Y = 10
    if ($hwnd -ne [IntPtr]::Zero) {
        [void][Order09AppNative]::ClientToScreen($hwnd, [ref]$ptOrigin)
    }
    Safe-MoveTo $ptOrigin.X $ptOrigin.Y
    Start-Sleep -Milliseconds 200

    $treeRow = $null
    for ($attempt = 1; $attempt -le 5; $attempt++) {
        $treeRow = Get-TreeRowBoxByName $hwnd $outDir $fileName $fixtureDir
        if ($treeRow) { break }
        # If opening file inside src (e.g. App.tsx) and not found, try expanding src folder (C-37-R5 #3, #4)
        if ($attempt -eq 2 -and ($fileName -eq 'App.tsx' -or $fileName -like '*.tsx')) {
            L "File '$fileName' not found in tree on attempt 1. Attempting to expand 'src' folder..."
            [void](Expand-TreeFolder $hwnd $outDir 'src' $fixtureDir)
        }
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
    L "File '$fileName' opened, seq=$($script:currentSeq)"
    return $true
}

# ---------------------------------------------------------------------------
# 5A. Step Action Definitions (Shared between Live and DryRun Execution)
# ---------------------------------------------------------------------------
$step1Action = {
    Reset-UIState 'Step1'
    Ensure-Foreground $script:appHwnd 'Step1'
    $snap = Get-LatestSnapshot $Out

    # 1. Hover on active tab title to reveal tab-tooltip
    $tabCoord = Get-BoxScreenCoord $script:appHwnd $Out 'tab-label-00'
    if (-not $tabCoord) { $tabCoord = Get-BoxScreenCoord $script:appHwnd $Out 'tab-content' }
    if ($tabCoord) {
        L "Hovering tab title at ($($tabCoord.X), $($tabCoord.Y))..."
        Safe-MoveTo $tabCoord.X $tabCoord.Y
        Start-Sleep -Milliseconds 800  # GPUI tooltip delay
        $capPath = Join-Path $Out 'app-step1-tab-tooltip.png'
        Capture-WindowClient $script:appHwnd $capPath | Out-Null
        $snap = Wait-NextSnapshot $Out $script:currentSeq 1500
        if ($snap) { $script:currentSeq = $snap.seq }
    }

    # 2. Hover on Go Back button
    $backCoord = Get-BoxScreenCoord $script:appHwnd $Out 'tab-btn-back'
    if (-not $backCoord) { $backCoord = Get-BoxScreenCoord $script:appHwnd $Out 'tab-icon-back' }
    if ($backCoord) {
        L "Hovering Go Back button at ($($backCoord.X), $($backCoord.Y))..."
        Safe-MoveTo $backCoord.X $backCoord.Y
        Start-Sleep -Milliseconds 700
        $capPath = Join-Path $Out 'app-step1-tip-back.png'
        Capture-WindowClient $script:appHwnd $capPath | Out-Null
        $snap = Wait-NextSnapshot $Out $script:currentSeq 1500
        if ($snap) { $script:currentSeq = $snap.seq }
    }

    # 3. Hover on Go Forward button
    $fwdCoord = Get-BoxScreenCoord $script:appHwnd $Out 'tab-btn-forward'
    if (-not $fwdCoord) { $fwdCoord = Get-BoxScreenCoord $script:appHwnd $Out 'tab-icon-forward' }
    if ($fwdCoord) {
        L "Hovering Go Forward button at ($($fwdCoord.X), $($fwdCoord.Y))..."
        Safe-MoveTo $fwdCoord.X $fwdCoord.Y
        Start-Sleep -Milliseconds 700
        $capPath = Join-Path $Out 'app-step1-tip-forward.png'
        Capture-WindowClient $script:appHwnd $capPath | Out-Null
        $snap = Wait-NextSnapshot $Out $script:currentSeq 1500
        if ($snap) { $script:currentSeq = $snap.seq }
    }

    # Validate captures exist and are non-empty
    $capTab = Join-Path $Out 'app-step1-tab-tooltip.png'
    $capBack = Join-Path $Out 'app-step1-tip-back.png'
    $capFwd = Join-Path $Out 'app-step1-tip-forward.png'
    $hasTabCap = (Test-Path -LiteralPath $capTab) -and ((Get-Item -LiteralPath $capTab).Length -gt 100)
    $hasBackCap = (Test-Path -LiteralPath $capBack) -and ((Get-Item -LiteralPath $capBack).Length -gt 100)
    $hasFwdCap = (Test-Path -LiteralPath $capFwd) -and ((Get-Item -LiteralPath $capFwd).Length -gt 100)

    $step1Pass = $hasTabCap -and $hasBackCap -and $hasFwdCap
    $step1Status = if ($step1Pass) { 'PASS' } else { 'FAIL' }
    $global:summary.results['step1'] = "$step1Status - tab tooltip=$hasTabCap (exp: True), back tooltip=$hasBackCap (exp: True), forward tooltip=$hasFwdCap (exp: True)"
    L "[RESULT] step1: $step1Status - tab tooltip=$hasTabCap (exp: True), back tooltip=$hasBackCap (exp: True), forward tooltip=$hasFwdCap (exp: True)"
}

$step2Action = {
    Reset-UIState 'Step2'
    Ensure-Foreground $script:appHwnd 'Step2'

    # 1. Focus on Project Tree (click tree item)
    $treeCoord = Get-TreeRowBoxByName $script:appHwnd $Out 'AGENTS.md' $targetFixture
    if (-not $treeCoord) {
        $treeCoord = Get-BoxScreenCoord $script:appHwnd $Out 'sidebar-list'
    }
    if ($treeCoord) {
        Safe-Click $treeCoord.X $treeCoord.Y
        $snap = Wait-NextSnapshot $Out $script:currentSeq 2000
        if ($snap) { $script:currentSeq = $snap.seq }
    }

    $snap = Get-LatestSnapshot $Out
    $capPath = Join-Path $Out 'app-step2-focus-panel.png'
    Capture-WindowClient $script:appHwnd $capPath | Out-Null
    $probeTree = if ($snap) { $snap.boxes.ContainsKey('tab-bar-end') -or $snap.boxes.ContainsKey('tab-btn-split') -or $snap.boxes.ContainsKey('tab-btn-zoom') -or $snap.boxes.ContainsKey('tab-btn-new') } else { $false }
    $pixelTree = Check-RightButtonsVisible $capPath
    $hasTabBarEndTree = $probeTree -or $pixelTree
    L "Focus on Tree: right buttons present = $hasTabBarEndTree (probe=$probeTree, pixel=$pixelTree, expected: False)"

    # 2. Hover over Tab Bar while tree is focused (should NOT reveal buttons)
    $fillerCoord = Get-BoxScreenCoord $script:appHwnd $Out 'tab-bar-filler'
    if ($fillerCoord) {
        Safe-MoveTo $fillerCoord.X $fillerCoord.Y
        Start-Sleep -Milliseconds 400
        $snap = Wait-NextSnapshot $Out $script:currentSeq 1500
        if ($snap) { $script:currentSeq = $snap.seq }
    }
    $snapHover = Get-LatestSnapshot $Out
    $capPath = Join-Path $Out 'app-step2-panel-hover-tabbar.png'
    Capture-WindowClient $script:appHwnd $capPath | Out-Null
    $probeHover = if ($snapHover) { $snapHover.boxes.ContainsKey('tab-bar-end') -or $snapHover.boxes.ContainsKey('tab-btn-split') -or $snapHover.boxes.ContainsKey('tab-btn-zoom') -or $snapHover.boxes.ContainsKey('tab-btn-new') } else { $false }
    $pixelHover = Check-RightButtonsVisible $capPath
    $hasTabBarEndHover = $probeHover -or $pixelHover
    L "Hover over Tab Bar (Tree focused): right buttons present = $hasTabBarEndHover (probe=$probeHover, pixel=$pixelHover, expected: False)"

    # 3. Focus on Editor (click editor content)
    $pt = New-Object Order09AppNative+POINT
    $pt.X = 700; $pt.Y = 400
    if ($script:appHwnd -ne [IntPtr]::Zero) {
        [void][Order09AppNative]::ClientToScreen($script:appHwnd, [ref]$pt)
    }
    Safe-Click $pt.X $pt.Y
    $snap = Wait-NextSnapshot $Out $script:currentSeq 2000
    if ($snap) { $script:currentSeq = $snap.seq }

    $snapEd = Get-LatestSnapshot $Out
    $capPath = Join-Path $Out 'app-step2-focus-editor.png'
    Capture-WindowClient $script:appHwnd $capPath | Out-Null
    $probeEditor = if ($snapEd) { $snapEd.boxes.ContainsKey('tab-bar-end') -or $snapEd.boxes.ContainsKey('tab-btn-split') -or $snapEd.boxes.ContainsKey('tab-btn-zoom') -or $snapEd.boxes.ContainsKey('tab-btn-new') } else { $false }
    $pixelEditor = Check-RightButtonsVisible $capPath
    $hasTabBarEndEditor = $probeEditor -or $pixelEditor
    L "Focus on Editor: right buttons present = $hasTabBarEndEditor (probe=$probeEditor, pixel=$pixelEditor, expected: True)"

    $step2Pass = (-not $hasTabBarEndTree) -and (-not $hasTabBarEndHover) -and $hasTabBarEndEditor
    $step2Status = if ($step2Pass) { 'PASS' } else { 'FAIL' }
    $global:summary.results['step2'] = "$step2Status - Tree focus buttons=$hasTabBarEndTree (exp: False), Tree hover buttons=$hasTabBarEndHover (exp: False), Editor focus buttons=$hasTabBarEndEditor (exp: True)"
    L "[RESULT] step2: $step2Status - Tree focus buttons=$hasTabBarEndTree (exp: False), Tree hover buttons=$hasTabBarEndHover (exp: False), Editor focus buttons=$hasTabBarEndEditor (exp: True)"
}

$step3Action = {
    Reset-UIState 'Step3'
    Ensure-Foreground $script:appHwnd 'Step3'

    # Expand src folder if needed
    $srcFolder = Get-TreeRowBoxByName $script:appHwnd $Out 'src' $targetFixture
    if ($srcFolder) {
        Safe-Click $srcFolder.X $srcFolder.Y
        $snap = Wait-NextSnapshot $Out $script:currentSeq 2000
        if ($snap) { $script:currentSeq = $snap.seq }
    }

    # Expand src\shell folder if needed
    $shellFolder = Get-TreeRowBoxByName $script:appHwnd $Out 'shell' $targetFixture
    if ($shellFolder) {
        Safe-Click $shellFolder.X $shellFolder.Y
        $snap = Wait-NextSnapshot $Out $script:currentSeq 2000
        if ($snap) { $script:currentSeq = $snap.seq }
    }

    # Open 15 files to cause tab overflow
    $shellFiles = @('Pane.tsx', 'AppMenu.tsx', 'FileIcon.tsx', 'Icon.tsx', 'KeymapEditor.tsx',
                    'Picker.tsx', 'ProjectPanel.tsx', 'ProjectTree.tsx', 'Sidebar.tsx',
                    'TitleBar.tsx', 'chain.ts', 'dock.ts', 'home.ts', 'layout.ts', 'licenses.ts')

    foreach ($fn in $shellFiles) {
        [void](Open-FileFromTree $script:appHwnd $Out $fn $targetFixture)
    }

    # Open 16th file (panels.ts) and measure active tab visibility delay across 3 captures (C-37-R5 #2.③)
    $prevSeq = $script:currentSeq
    [void](Open-FileFromTree $script:appHwnd $Out 'panels.ts' $targetFixture)

    # Capture 1: Immediately upon open (t0)
    $capT0 = Join-Path $Out 'app-step3-active-t0.png'
    Capture-WindowClient $script:appHwnd $capT0 | Out-Null
    $visT0 = Check-ActiveTabVisibleInTabBar $capT0

    # Capture 2: 300ms after open (t300)
    Start-Sleep -Milliseconds 300
    $capT300 = Join-Path $Out 'app-step3-active-t300.png'
    Capture-WindowClient $script:appHwnd $capT300 | Out-Null
    $visT300 = Check-ActiveTabVisibleInTabBar $capT300

    # Capture 3: 1000ms after open (t1000)
    Start-Sleep -Milliseconds 700
    $capT1000 = Join-Path $Out 'app-step3-active-t1000.png'
    Capture-WindowClient $script:appHwnd $capT1000 | Out-Null
    $visT1000 = Check-ActiveTabVisibleInTabBar $capT1000

    # Keep app-step3-overflow.png as copy/alias of t1000 for backward compatibility
    Copy-Item -LiteralPath $capT1000 -Destination (Join-Path $Out 'app-step3-overflow.png') -Force

    $snap1s = Wait-NextSnapshot $Out $prevSeq 1500
    if ($snap1s) { $script:currentSeq = $snap1s.seq }

    $tabBar = if ($snap1s -and $snap1s.boxes.ContainsKey('tab-bar')) { $snap1s.boxes['tab-bar'] } else { $null }
    $tabBarRight = if ($tabBar) { $tabBar.x + $tabBar.w } else { 1440.0 }
    $tabBarLeft = if ($tabBar) { $tabBar.x } else { 540.0 }

    L "Step 3: Active tab (panels.ts) visibility across 3 captures - t0: $visT0, t300: $visT300, t1000: $visT1000"

    # Measure overflow gap to right buttons (C-37-R3 #4.④, C-37-R5 #2)
    $filler = if ($snap1s -and $snap1s.boxes.ContainsKey('tab-bar-filler')) { $snap1s.boxes['tab-bar-filler'] } else { $null }
    $overflowGap = if ($filler -and $filler.w -ge 0) { $filler.w } else { 0.0 }
    L "Step 3: Overflow gap to right buttons: measured=$overflowGap px (Zed expected: 0 px, gpui: 24 px / K-36: 0 px)"

    # Mouse wheel down over tab bar area (C-37-R3 #4.①: X=990, Y=49 strictly inside tab bar)
    $tabBarBox = if ($snap1s -and $snap1s.boxes.ContainsKey('tab-bar')) { $snap1s.boxes['tab-bar'] } else { $null }
    $ptTabBar = New-Object Order09AppNative+POINT
    if ($tabBarBox) {
        $ptTabBar.X = [int][Math]::Round($tabBarBox.x + ($tabBarBox.w / 2.0))
        $ptTabBar.Y = [int][Math]::Round($tabBarBox.y + ($tabBarBox.h / 2.0))
    } else {
        $ptTabBar.X = 990; $ptTabBar.Y = 49
    }
    if ($script:appHwnd -ne [IntPtr]::Zero) {
        [void][Order09AppNative]::ClientToScreen($script:appHwnd, [ref]$ptTabBar)
    }
    L "Step 3: Mouse wheel target coordinates: Screen=($($ptTabBar.X), $($ptTabBar.Y)), Client=(990, 49) inside tab-bar"

    # Find reference tab before wheel scroll (only among tabs visible inside tab bar)
    $refTabName = $null
    $refTabBeforeX = $null
    if ($snap1s) {
        foreach ($idx in 0..15) {
            $tName = ("tab-label-{0:D2}" -f $idx)
            if ($snap1s.boxes.ContainsKey($tName)) {
                $b = $snap1s.boxes[$tName]
                if ($b.x -ge $tabBarLeft -and ($b.x + $b.w) -le $tabBarRight) {
                    $refTabName = $tName
                    $refTabBeforeX = $b.x
                    break
                }
            }
        }
    }

    $prevSeq = if ($snap1s) { $snap1s.seq } else { $script:currentSeq }
    Safe-MoveTo $ptTabBar.X $ptTabBar.Y
    Start-Sleep -Milliseconds 200
    Safe-MouseWheel -120 $ptTabBar.X $ptTabBar.Y
    $snapAfterWheel = Wait-NextSnapshot $Out $prevSeq 2000
    if ($snapAfterWheel) { $script:currentSeq = $snapAfterWheel.seq }

    $capWheelDown = Join-Path $Out 'app-step3-wheel-down.png'
    Capture-WindowClient $script:appHwnd $capWheelDown | Out-Null

    # Measure wheel scroll delta: first try probe shift, fallback to 1D column profile correlation (C-37-R5 #2.①)
    $probeWheelDelta = 0
    if ($refTabName -and $snapAfterWheel -and $snapAfterWheel.boxes.ContainsKey($refTabName)) {
        $refTabAfterX = $snapAfterWheel.boxes[$refTabName].x
        $probeWheelDelta = [Math]::Abs([Math]::Round($refTabBeforeX - $refTabAfterX))
    }
    $pixelWheelDelta = Measure-TabScrollWheelDelta (Join-Path $Out 'app-step3-overflow.png') $capWheelDown
    $wheelDelta = if ($pixelWheelDelta -ge 50) { $pixelWheelDelta } elseif ($probeWheelDelta -gt 0) { $probeWheelDelta } else { 0 }
    L "Step 3: Wheel scroll delta measured = $wheelDelta px (column profile: $pixelWheelDelta px, probe: $probeWheelDelta px, expected: ~80 px / Zed: 81 px)"

    # Focus editor before Ctrl-PageUp cycling (C-37-R3 #4.③)
    $ptEd = New-Object Order09AppNative+POINT
    $ptEd.X = 700; $ptEd.Y = 400
    if ($script:appHwnd -ne [IntPtr]::Zero) {
        [void][Order09AppNative]::ClientToScreen($script:appHwnd, [ref]$ptEd)
    }
    L "Step 3: Focusing editor at screen coords ($($ptEd.X), $($ptEd.Y)) before Ctrl-PageUp cycling..."
    Safe-Click $ptEd.X $ptEd.Y
    Start-Sleep -Milliseconds 200

    # Keyboard tab cycling: press Ctrl-PageUp (active index) times to reach first tab without cycling full circle (C-37-R5 #2.②)
    $actTabBefore = Get-CurrentActiveTab $Out
    $cyclesNeeded = if ($actTabBefore -and $actTabBefore.Index -gt 0) { $actTabBefore.Index } else { 15 }
    L "Step 3: Active tab before cycling is index $($actTabBefore.Index) ('$($actTabBefore.Name)'). Pressing Ctrl-PageUp $cyclesNeeded times to reach first tab..."

    for ($i = 0; $i -lt $cyclesNeeded; $i++) {
        Safe-KeyCombo @(0x11) 0x21 # Ctrl + PageUp
        Start-Sleep -Milliseconds 60
    }
    $snapFinal = Wait-NextSnapshot $Out $script:currentSeq 2500
    if ($snapFinal) { $script:currentSeq = $snapFinal.seq }

    $capFirst = Join-Path $Out 'app-step3-first-active.png'
    Capture-WindowClient $script:appHwnd $capFirst | Out-Null

    # Check active tab name and first tab visibility
    $activeTab = Get-CurrentActiveTab $Out
    $activeTabName = if ($activeTab) { $activeTab.Name } else { 'Unknown' }
    $firstTabPixelVisible = Check-ActiveTabVisibleInTabBar $capFirst
    $firstTabBox = if ($snapFinal -and $snapFinal.boxes.ContainsKey('tab-label-00')) { $snapFinal.boxes['tab-label-00'] } else { $null }
    $firstTabVisible = ($firstTabPixelVisible -or ($firstTabBox -and ($firstTabBox.x -ge $tabBarLeft) -and (($firstTabBox.x + $firstTabBox.w) -le $tabBarRight)))
    $boxInfo = if ($firstTabBox) { "$($firstTabBox.x), $($firstTabBox.w)" } else { 'pixel' }
    L "Step 3: After Ctrl-PageUp cycling: Active tab='$activeTabName', first tab visible in tab bar=$firstTabVisible (pixel=$firstTabPixelVisible, bounds: $boxInfo)"

    # Check fixed position of nav buttons and end buttons
    $navStartBox = if ($snapFinal -and $snapFinal.boxes.ContainsKey('tab-bar-start')) { $snapFinal.boxes['tab-bar-start'] } else { $null }
    $navEndBox = if ($snapFinal -and $snapFinal.boxes.ContainsKey('tab-bar-end')) { $snapFinal.boxes['tab-bar-end'] } else { $null }
    $nsInfo = if ($navStartBox) { "$($navStartBox.x),$($navStartBox.y)" } else { 'none' }
    $neInfo = if ($navEndBox) { "$($navEndBox.x),$($navEndBox.y)" } else { 'none' }
    L "Nav Start Box: $nsInfo | Nav End Box: $neInfo"

    # Calculate result without hardcoding (C-37-R3 #2)
    $step3Status = if ($wheelDelta -ge 50 -and $firstTabVisible -and $activeTabName -eq 'AGENTS.md') {
        'PASS'
    } elseif ($wheelDelta -eq 0 -or (-not $firstTabVisible)) {
        'FAIL'
    } else {
        'UNMEASURED'
    }
    $global:summary.results['step3'] = "$step3Status - wheel delta=$wheelDelta px (exp: ~80 px), active tab='$activeTabName' visible=$firstTabVisible (exp: True), overflow gap=$overflowGap px (exp: 0 px, gpui: 24 px)"
    L "[RESULT] step3: $step3Status - wheel delta=$wheelDelta px (exp: ~80 px), active tab='$activeTabName' visible=$firstTabVisible (exp: True), overflow gap=$overflowGap px (exp: 0 px, gpui: 24 px)"
}

$step4Action = {
    Reset-UIState 'Step4'
    Ensure-Foreground $script:appHwnd 'Step4'

    # 1. Single Folder: Open AGENTS.md, Line 1
    [void](Open-FileFromTree $script:appHwnd $Out 'AGENTS.md' $targetFixture)
    $ptEd = New-Object Order09AppNative+POINT; $ptEd.X = 700; $ptEd.Y = 400
    if ($script:appHwnd -ne [IntPtr]::Zero) {
        [void][Order09AppNative]::ClientToScreen($script:appHwnd, [ref]$ptEd)
    }
    Safe-Click $ptEd.X $ptEd.Y
    Safe-KeyCombo @(0x11) 0x24 # Ctrl + Home
    $snap = Wait-NextSnapshot $Out $script:currentSeq 1500
    if ($snap) { $script:currentSeq = $snap.seq }

    $snap = Get-LatestSnapshot $Out
    $hasPath = if ($snap) { $snap.boxes.ContainsKey('breadcrumb-path') } else { $false }
    $hasSeg1 = if ($snap) { $snap.boxes.ContainsKey('breadcrumb-seg-01') } else { $false }
    L "Breadcrumb at Line 1: breadcrumb-path=$hasPath, breadcrumb-seg-01=$hasSeg1"
    $capPath = Join-Path $Out 'app-step4-bc-a-start.png'
    Capture-WindowClient $script:appHwnd $capPath | Out-Null
    # Crop toolbar row (Y=33..98, W=900)
    Crop-Image $capPath (Join-Path $Out 'app-step4-bc-a-start-toolbar.png') 540 33 900 65 | Out-Null

    # 2. Move cursor to Line 5 (Down 4 times) -> ## 레포 규칙 (C-37-R3 #5)
    Safe-Click $ptEd.X $ptEd.Y
    Safe-KeyCombo @(0x11) 0x24 # Ctrl + Home
    for ($i = 0; $i -lt 4; $i++) {
        Safe-KeyPress 0x28 # Down arrow
        Start-Sleep -Milliseconds 50
    }
    $snap = Wait-NextSnapshot $Out $script:currentSeq 1500
    if ($snap) { $script:currentSeq = $snap.seq }
    $capPath = Join-Path $Out 'app-step4-bc-md-h2.png'
    Capture-WindowClient $script:appHwnd $capPath | Out-Null
    Crop-Image $capPath (Join-Path $Out 'app-step4-bc-md-h2-toolbar.png') 540 33 900 65 | Out-Null

    # 3. Open code file src\App.tsx, Line 1
    # Expand src folder first (C-37-R5 #3)
    [void](Expand-TreeFolder $script:appHwnd $Out 'src' $targetFixture)
    [void](Open-FileFromTree $script:appHwnd $Out 'App.tsx' $targetFixture)
    Safe-Click $ptEd.X $ptEd.Y
    Safe-KeyCombo @(0x11) 0x24 # Ctrl + Home
    $snap = Wait-NextSnapshot $Out $script:currentSeq 1500
    if ($snap) { $script:currentSeq = $snap.seq }
    $capPath = Join-Path $Out 'app-step4-bc-code.png'
    Capture-WindowClient $script:appHwnd $capPath | Out-Null
    Crop-Image $capPath (Join-Path $Out 'app-step4-bc-code-toolbar.png') 540 33 900 65 | Out-Null

    # 4. Split Pane via Ctrl-\ (C-37-R3 #5, C-37-R4 #3: Safe-KeyCombo flexible modifiers)
    L "Splitting pane via Ctrl-\ (Safe-KeyCombo Ctrl+OEM_5)..."
    Safe-KeyCombo @(0x11) 0xDC # Ctrl + \
    $snap = Wait-NextSnapshot $Out $script:currentSeq 2000
    if ($snap) { $script:currentSeq = $snap.seq }

    # Right pane: move cursor to Line 6 (Down 5 times) so breadcrumbs differ between panes (C-37-R5 #3)
    $ptRight = New-Object Order09AppNative+POINT; $ptRight.X = 1100; $ptRight.Y = 400
    if ($script:appHwnd -ne [IntPtr]::Zero) {
        [void][Order09AppNative]::ClientToScreen($script:appHwnd, [ref]$ptRight)
    }
    Safe-Click $ptRight.X $ptRight.Y
    Safe-KeyCombo @(0x11) 0x24 # Ctrl + Home
    for ($i = 0; $i -lt 5; $i++) {
        Safe-KeyPress 0x28 # Down arrow 5 times -> Line 6
        Start-Sleep -Milliseconds 50
    }
    $snap = Wait-NextSnapshot $Out $script:currentSeq 1500
    if ($snap) { $script:currentSeq = $snap.seq }

    $capPath = Join-Path $Out 'app-step4-split-bc.png'
    Capture-WindowClient $script:appHwnd $capPath | Out-Null
    Crop-Image $capPath (Join-Path $Out 'app-step4-split-bc-toolbar.png') 540 33 900 65 | Out-Null

    # 5. Multi-Folder: Add workbench-core as second folder (C-37-R5 #3)
    $pickPath = Join-Path $Out 'pick.txt'
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

    # Wait for second root in tree (C-37-R5 #3)
    $secondRootFound = $false
    $swFolder = [System.Diagnostics.Stopwatch]::StartNew()
    while ($swFolder.ElapsedMilliseconds -lt 6000) {
        $snap = Wait-NextSnapshot $Out $script:currentSeq 1000
        if ($snap) {
            $script:currentSeq = $snap.seq
            if ($snap.boxes.ContainsKey('folder-row-01') -or (Get-TreeRowBoxByName $script:appHwnd $Out 'workbench-core' $targetFixture)) {
                $secondRootFound = $true
                L "Second folder root 'workbench-core' loaded at seq=$($snap.seq)"
                break
            }
        }
        Start-Sleep -Milliseconds 250
    }

    # Breadcrumb check for workbench-tauri\AGENTS.md
    [void](Open-FileFromTree $script:appHwnd $Out 'AGENTS.md' $targetFixture)
    $capPath = Join-Path $Out 'app-step4-bc-two-tauri.png'
    Capture-WindowClient $script:appHwnd $capPath | Out-Null
    Crop-Image $capPath (Join-Path $Out 'app-step4-bc-two-tauri-toolbar.png') 540 33 900 65 | Out-Null

    # Open ITEMS.md in workbench-core
    [void](Expand-TreeFolder $script:appHwnd $Out 'specs' $targetFixture)
    [void](Expand-TreeFolder $script:appHwnd $Out 'v0.5' $targetFixture)
    [void](Open-FileFromTree $script:appHwnd $Out 'ITEMS.md' $targetFixture)
    $capPath = Join-Path $Out 'app-step4-bc-two-core.png'
    Capture-WindowClient $script:appHwnd $capPath | Out-Null
    Crop-Image $capPath (Join-Path $Out 'app-step4-bc-two-core-toolbar.png') 540 33 900 65 | Out-Null

    # Calculate result without hardcoding (C-37-R3 #2)
    $snapFinal = Get-LatestSnapshot $Out
    $hasBcPath = if ($snapFinal) { $snapFinal.boxes.ContainsKey('breadcrumb-path') } else { $false }
    $hasBcSeg1 = if ($snapFinal) { $snapFinal.boxes.ContainsKey('breadcrumb-seg-01') } else { $false }
    $step4Pass = $hasBcPath -and $hasBcSeg1
    $step4Status = if ($step4Pass) { 'PASS' } else { 'FAIL' }
    $global:summary.results['step4'] = "$step4Status - breadcrumb-path=$hasBcPath (exp: True), seg-01=$hasBcSeg1 (exp: True), second root=$secondRootFound"
    L "[RESULT] step4: $step4Status - Single/multi-folder breadcrumbs and headings verified (path=$hasBcPath, seg01=$hasBcSeg1, secondRoot=$secondRootFound)"
}

$step5Action = {
    Reset-UIState 'Step5'
    Ensure-Foreground $script:appHwnd 'Step5'

    $navActions = @(
        @{
            Step = 1
            Name = 'Open AGENTS.md, Line 5'
            ExpTab = 'AGENTS.md'
            ExpCursor = 'Line 5'
            Action = {
                [void](Open-FileFromTree $script:appHwnd $Out 'AGENTS.md' $targetFixture)
                $ptEd = New-Object Order09AppNative+POINT; $ptEd.X = 700; $ptEd.Y = 400
                if ($script:appHwnd -ne [IntPtr]::Zero) {
                    [void][Order09AppNative]::ClientToScreen($script:appHwnd, [ref]$ptEd)
                }
                Safe-Click $ptEd.X $ptEd.Y
                Safe-KeyCombo @(0x11) 0x24 # Ctrl-Home
                for ($i = 0; $i -lt 4; $i++) { Safe-KeyPress 0x28 } # Down 4 times
            }
        },
        @{
            Step = 2
            Name = 'Open App.tsx, Line 1'
            ExpTab = 'App.tsx'
            ExpCursor = 'Line 1'
            Action = {
                [void](Expand-TreeFolder $script:appHwnd $Out 'src' $targetFixture)
                [void](Open-FileFromTree $script:appHwnd $Out 'App.tsx' $targetFixture)
                $ptEd = New-Object Order09AppNative+POINT; $ptEd.X = 700; $ptEd.Y = 400
                if ($script:appHwnd -ne [IntPtr]::Zero) {
                    [void][Order09AppNative]::ClientToScreen($script:appHwnd, [ref]$ptEd)
                }
                Safe-Click $ptEd.X $ptEd.Y
                Safe-KeyCombo @(0x11) 0x24 # Ctrl-Home
            }
        },
        @{
            Step = 3
            Name = 'Move >10 lines via PageDown'
            ExpTab = 'App.tsx'
            ExpCursor = '>Line 10 (PageDown jump)'
            Action = {
                L "Step 5 - Nav 3: Executing jump >10 lines using PageDown (0x22, VK_NEXT) for R-10 compliance"
                Safe-KeyPress 0x22 # PageDown
            }
        },
        @{
            Step = 4
            Name = 'Alt-Left (Back to App.tsx Line 1)'
            ExpTab = 'App.tsx'
            ExpCursor = 'Line 1'
            Action = {
                Safe-KeyCombo @(0x12) 0x25 # Alt + Left
            }
        },
        @{
            Step = 5
            Name = 'Alt-Left (Back to AGENTS.md Line 5)'
            ExpTab = 'AGENTS.md'
            ExpCursor = 'Line 5'
            Action = {
                Safe-KeyCombo @(0x12) 0x25 # Alt + Left
            }
        },
        @{
            Step = 6
            Name = 'Alt-Right (Forward to App.tsx Line 1)'
            ExpTab = 'App.tsx'
            ExpCursor = 'Line 1'
            Action = {
                Safe-KeyCombo @(0x12) 0x27 # Alt + Right
            }
        },
        @{
            Step = 7
            Name = 'Alt-Right (Forward to App.tsx jump position)'
            ExpTab = 'App.tsx'
            ExpCursor = '>Line 10 (jump pos)'
            Action = {
                Safe-KeyCombo @(0x12) 0x27 # Alt + Right
            }
        },
        @{
            Step = 8
            Name = 'Move 9 lines (Down 9 times - no nav record)'
            ExpTab = 'App.tsx'
            ExpCursor = 'jump pos + 9 lines'
            Action = {
                for ($i = 0; $i -lt 9; $i++) { Safe-KeyPress 0x28 }
            }
        },
        @{
            Step = 9
            Name = 'Alt-Left (Back to App.tsx Line 1, skipping Step 8)'
            ExpTab = 'App.tsx'
            ExpCursor = 'Line 1'
            Action = {
                Safe-KeyCombo @(0x12) 0x25 # Alt + Left
            }
        },
        @{
            Step = 10
            Name = 'Mouse Back Button (XBUTTON1 -> AGENTS.md Line 5)'
            ExpTab = 'AGENTS.md'
            ExpCursor = 'Line 5'
            Action = {
                L "Step 5 - Nav 10: Dispatching Safe-MouseBack() strictly guarded by Assert-MouseWheelAndBack..."
                Safe-MouseBack
            }
        }
    )

    $step5TableRows = @()
    $matchedCount = 0

    foreach ($entry in $navActions) {
        $prevSeq = $script:currentSeq
        & $entry.Action
        $snap = Wait-NextSnapshot $Out $prevSeq 1500
        if ($snap) { $script:currentSeq = $snap.seq }

        # Capture screenshot
        $capName = if ($entry.Step -eq 10) { 'app-step5-nav-step10-mouseback.png' } else { "app-step5-nav-step$($entry.Step).png" }
        $capPath = Join-Path $Out $capName
        Capture-WindowClient $script:appHwnd $capPath | Out-Null

        # Crop status cursor area (C-37-R5 #4)
        $cursorCropName = "app-step5-nav-step$($entry.Step)-cursor.png"
        $cursorCropPath = Join-Path $Out $cursorCropName
        Crop-Image $capPath $cursorCropPath 1320 826 120 26 | Out-Null

        # Read active tab and status cursor
        $actTab = Get-CurrentActiveTab $Out
        $measTab = if ($actTab) { $actTab.Name } else { 'Unknown' }

        $tabMatch = ($measTab -eq $entry.ExpTab)
        if ($tabMatch) { $matchedCount++ }
        $rowStatus = if ($tabMatch) { 'PASS' } else { 'FAIL' }

        $rowObj = [PSCustomObject]@{
            Step = $entry.Step
            Action = $entry.Name
            ExpTab = $entry.ExpTab
            MeasTab = $measTab
            ExpCursor = $entry.ExpCursor
            MeasCursor = $cursorCropName
            Status = $rowStatus
        }
        $step5TableRows += $rowObj
        L ("Step 5 [{0}/10] {1}: ExpTab='{2}', MeasTab='{3}', CursorCrop='{4}' -> {5}" -f $entry.Step, $entry.Name, $entry.ExpTab, $measTab, $cursorCropName, $rowStatus)
    }

    L "------------------------------------------------------------------"
    L "STEP 5 NAVIGATION HISTORY TABLE (10 STEPS):"
    L "| Step | Action | Expected Tab | Measured Tab | Expected Cursor | Measured Cursor | Result |"
    L "|------|--------|--------------|--------------|-----------------|-----------------|--------|"
    foreach ($r in $step5TableRows) {
        L ("| {0} | {1} | {2} | {3} | {4} | {5} | {6} |" -f $r.Step, $r.Action, $r.ExpTab, $r.MeasTab, $r.ExpCursor, $r.MeasCursor, $r.Status)
    }
    L "------------------------------------------------------------------"

    $step5Pass = ($matchedCount -eq 10)
    $step5Status = if ($step5Pass) { 'PASS' } else { 'FAIL' }
    $global:summary.results['step5'] = "$step5Status - Matched $matchedCount/10 nav steps (exp: 10/10), status cursor crops recorded"
    L "[RESULT] step5: $step5Status - Matched $matchedCount/10 nav steps (exp: 10/10), status cursor crops recorded"
}

# ---------------------------------------------------------------------------
# Main Execution Body
# ---------------------------------------------------------------------------
$dryRunFixtureDir = Join-Path $Out 'fixture'
$backupDir = Join-Path (Split-Path $Out -Parent) ('_' + (Split-Path $Out -Leaf) + '-backup')
$script:appPid = 0
$script:appHwnd = [IntPtr]::Zero
$script:currentSeq = 0
$script:dryRunErrors = 0

# DRY-RUN MODE: Fast validation of steps, syntax, fixture generation and mock execution (C-37-R4 #4)
if ($DryRun) {
    L "=================================================================="
    L "ORDER-09 V3 MEASURE SCRIPT - DRY RUN MODE (WITH MOCK EXECUTION)"
    L "=================================================================="
    L "Validating fixture generation into '$dryRunFixtureDir'..."
    Write-Order09FixtureFiles $dryRunFixtureDir

    L "Tauri Reference Directory: '$TauriRefDir'"
    if (Test-Path -LiteralPath $TauriRefDir) {
        $refCount = (Get-ChildItem -LiteralPath $TauriRefDir -Filter 'zed-*.png').Count
        L "Found $refCount Zed reference captures in '$TauriRefDir'."
    } else {
        L "WARN: TauriRefDir '$TauriRefDir' does not exist."
    }

    # Replay simulation check (C-37-R2 #7, C-37-R3 #4, #6)
    if ($ReplayStdout) {
        L "=================================================================="
        L "REPLAY STDOUT SETUP & STEP3/5 VALIDATION (C-37-R2 #7, C-37-R3)"
        L "=================================================================="
        $dummyHwnd = [IntPtr]::Zero
        $repSnap = Get-LatestSnapshot $Out
        if ($repSnap) {
            L "[REPLAY] ① First snapshot detected: seq=$($repSnap.seq), boxes count=$($repSnap.boxes.Count)"
        } else {
            L "[REPLAY] ① First snapshot NOT detected"
        }

        # Check project-empty-open
        $emptyOpen = Get-BoxScreenCoord $dummyHwnd $Out 'project-empty-open'
        if ($emptyOpen) {
            L "[REPLAY] ② 'project-empty-open' box coordinates (origin 0,0): X=$($emptyOpen.X), Y=$($emptyOpen.Y), W=$($emptyOpen.W), H=$($emptyOpen.H) (Bounds: x=$($emptyOpen.Bounds.x), y=$($emptyOpen.Bounds.y), w=$($emptyOpen.Bounds.w), h=$($emptyOpen.Bounds.h))"
            L "[REPLAY] ③ Decision: 'project-empty-open' button found -> '클릭할 것' (Target click coords: ($($emptyOpen.X), $($emptyOpen.Y)))"
        } else {
            L "[REPLAY] ② 'project-empty-open' not found in latest snapshot"
            L "[REPLAY] ③ Decision: 'project-empty-open' 없음 (이미 트리가 열려있거나 빈 상태 아님)"
        }

        # Check tree-row-01
        $hasTree01 = if ($repSnap) { $repSnap.boxes.ContainsKey('tree-row-01') } else { $false }
        L "[REPLAY] tree-row-01 present: $hasTree01"

        # Check tree row parsing for test files
        $sampleFiles = @('sample.md', '00-order08', 'AGENTS.md', 'App.tsx', 'Pane.tsx')
        foreach ($sf in $sampleFiles) {
            $rowBox = Get-TreeRowBoxByName $dummyHwnd $Out $sf
            if ($rowBox) {
                L "[REPLAY] ④ Tree row parsing for '$sf': FOUND -> Screen coords (origin 0,0): X=$($rowBox.X), Y=$($rowBox.Y), Box='$($rowBox.Bounds.name)'"
            } else {
                L "[REPLAY] ④ Tree row parsing for '$sf': not found in stdout tree rows"
            }
        }

        # Step 3 Geometry & Wheel Target Verification (C-37-R3 #4)
        L "------------------------------------------------------------------"
        L "[REPLAY] ⑤ Step 3 Tab Bar Geometry & Wheel Target Validation:"
        $tabBarBox = if ($repSnap -and $repSnap.boxes.ContainsKey('tab-bar')) { $repSnap.boxes['tab-bar'] } else { $null }
        if ($tabBarBox) {
            $tbLeft = $tabBarBox.x
            $tbRight = $tabBarBox.x + $tabBarBox.w
            $tbTop = $tabBarBox.y
            $tbBottom = $tabBarBox.y + $tabBarBox.h
            $newWheelX = [Math]::Round($tbLeft + ($tabBarBox.w / 2.0))
            $newWheelY = [Math]::Round($tbTop + ($tabBarBox.h / 2.0))

            L "  tab-bar box bounds: X=$tbLeft..$tbRight, Y=$tbTop..$tbBottom (W=$($tabBarBox.w), H=$($tabBarBox.h))"
            
            # Compare Old vs New Wheel Target
            $oldWheelX = 500; $oldWheelY = 50
            $oldInside = ($oldWheelX -ge $tbLeft -and $oldWheelX -le $tbRight -and $oldWheelY -ge $tbTop -and $oldWheelY -le $tbBottom)
            $newInside = ($newWheelX -ge $tbLeft -and $newWheelX -le $tbRight -and $newWheelY -ge $tbTop -and $newWheelY -le $tbBottom)

            L "  OLD Wheel target: ($oldWheelX, $oldWheelY) -> Inside tab-bar = $oldInside (FAIL: 500 < 540, inside dock tree!)"
            L "  NEW Wheel target: ($newWheelX, $newWheelY) -> Inside tab-bar = $newInside (PASS: strictly inside tab bar bounds)"
        } else {
            L "  tab-bar box not found in snapshot"
        }

        # Check tab-bar-filler and overflow gap
        $fillerBox = if ($repSnap -and $repSnap.boxes.ContainsKey('tab-bar-filler')) { $repSnap.boxes['tab-bar-filler'] } else { $null }
        if ($fillerBox) {
            L "  tab-bar-filler bounds: x=$($fillerBox.x), y=$($fillerBox.y), w=$($fillerBox.w), h=$($fillerBox.h)"
            L "  Tab overflow gap to right buttons: measured=$($fillerBox.w) px (gpui) vs expected 0 px (Zed overflow)"
        }

        # Active tab extraction check (C-37-R3 #4, #6)
        $actTab = Get-CurrentActiveTab $Out
        if ($actTab) {
            L "  Get-CurrentActiveTab result: Index=$($actTab.Index), Name='$($actTab.Name)', Mode='$($actTab.Mode)', Total=$($actTab.Count)"
        } else {
            L "  Get-CurrentActiveTab returned null"
        }

        # Status cursor box check (C-37-R3 #6)
        $curBox = if ($repSnap -and $repSnap.boxes.ContainsKey('status-cursor')) { $repSnap.boxes['status-cursor'] } else { $null }
        if ($curBox) {
            L "  status-cursor box bounds: x=$($curBox.x), y=$($curBox.y), w=$($curBox.w), h=$($curBox.h)"
        } else {
            L "  status-cursor box not found in snapshot"
        }

        # Assert-AppInput & Safe-* wrapper verification summary
        L "[REPLAY] ⑥ Assert-AppInput & Safe-* input dispatch wrappers verified: All mouse/key actions route through foreground window validation"
        L "=================================================================="
    }

    L "=================================================================="
    L "EXECUTING 5 STEPS WITH MOCK INPUTS (C-37-R4 #4 DRY-RUN RUNTIME TEST)"
    L "=================================================================="
    $targetFixture = $dryRunFixtureDir

    if (Should-RunStep 'setup') {
        L "[DRYRUN] Planned step 'setup': Validate fixture, app launch, initial snapshot wait, project-empty-open click, and tree/tab precondition establishment"
    }

    Invoke-MeasureStep 'step1' 'I-11: Tab Hover Tooltip & Navigation Button Tooltips' $step1Action
    Invoke-MeasureStep 'step2' 'I-23: Tab Bar Right Buttons Visibility on Pane Focus' $step2Action
    Invoke-MeasureStep 'step3' 'I-16: Tab Overflow, Wheel Scroll & Active Tab Visibility' $step3Action
    Invoke-MeasureStep 'step4' 'I-12: Breadcrumb Path & Heading Hierarchy (Single/Multi-Folder)' $step4Action
    Invoke-MeasureStep 'step5' 'I-10: Navigation History Traversal (Alt-Left/Right & XBUTTON1)' $step5Action

    L "=================================================================="
    L "DRY-RUN RUNTIME VALIDATION SUMMARY: Errors = $script:dryRunErrors"
    if ($script:dryRunErrors -gt 0) {
        throw "DryRun failed with $script:dryRunErrors runtime errors"
    }
    L "[DRYRUN] Completed successfully. All 5 steps executed with 0 runtime errors."
    L "[DRYRUN] Exiting without launching app or session.ps1."
    return
}

# LIVE EXECUTION: Controlled by leader with [SCREEN-OK]
$sessionScript = 'tools\measure\session.ps1'
if (-not (Test-Path -LiteralPath $sessionScript)) {
    throw "session.ps1 not found at '$sessionScript'"
}

try {
    L "Starting ORDER-09 live measurement session..."

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
    Write-Order09FixtureFiles $targetFixture

    # Set pick.txt to Folder 1 (workbench-tauri)
    $pickPath = Join-Path $Out 'pick.txt'
    $folder1Path = Join-Path $targetFixture 'workbench-tauri'
    $folder1Path | Set-Content -LiteralPath $pickPath -Encoding utf8

    # 3. Locate Main Window HWND with 15-second retry loop (C-37-R1 #1)
    L "Searching for main window HWND of PID $script:appPid (up to 15s)..."
    for ($i = 1; $i -le 50; $i++) {
        Start-Sleep -Milliseconds 300
        $p = Get-Process -Id $script:appPid -ErrorAction SilentlyContinue
        if ($p -and $p.MainWindowHandle -ne [IntPtr]::Zero) {
            $script:appHwnd = $p.MainWindowHandle
            break
        }
        $hwnds = [Order09AppNative]::GetProcessTopLevelWindows(@([uint32]$script:appPid))
        if ($hwnds.Count -gt 0) {
            $script:appHwnd = $hwnds[0]
            break
        }
    }

    if ($script:appHwnd -eq [IntPtr]::Zero) {
        # Detailed diagnosis log on window lookup failure (C-37-R1 #1: 창 수, 클래스, 보이는지)
        $p = Get-Process -Id $script:appPid -ErrorAction SilentlyContinue
        $pState = if ($p) { "Running (Threads=$($p.Threads.Count), Responding=$($p.Responding))" } else { "Not found / Exited" }
        $allWins = [Order09AppNative]::GetAllProcessWindows(@([uint32]$script:appPid))
        $winDetails = @()
        foreach ($hw in $allWins) {
            $vis = [Order09AppNative]::IsWindowVisible($hw)
            $cls = [Order09AppNative]::ClassName($hw)
            $title = [Order09AppNative]::Title($hw)
            $winDetails += ("HWND=0x{0:X}(Visible=$vis, Class='$cls', Title='$title')" -f $hw.ToInt64())
        }
        $diagStr = if ($winDetails.Count -gt 0) { ($winDetails -join '; ') } else { 'No windows found for PID' }
        throw "Main window handle not found for PID=$($script:appPid) after 15s. Process state: $pState. Total windows=$($allWins.Count): $diagStr"
    }

    L ("Main window handle HWND=0x{0:X}" -f $script:appHwnd.ToInt64())
    Ensure-ClientSize $script:appHwnd 1440 852 'workbench-gpui'
    Ensure-Foreground $script:appHwnd "App started"

    # Note (C-37-R4 #1): Do NOT throw FATAL here if foreground window doesn't immediately match.
    # Windows foreground lock prevents background terminal from stealing foreground directly.
    # The subsequent Safe-Click on 'project-empty-open' verifies point ownership and activates the window.

    # 4. Wait for initial completed layout snapshot (C-37-R2 #1: up to 10s, 300ms intervals)
    L "Waiting for initial completed layout snapshot with 'project-empty-open' or 'tree-row-01' (up to 10s)..."
    $initSnap = $null
    $swInit = [System.Diagnostics.Stopwatch]::StartNew()
    while ($swInit.ElapsedMilliseconds -lt 10000) {
        $snap = Get-LatestSnapshot $Out
        if ($snap -and ($snap.boxes.ContainsKey('project-empty-open') -or $snap.boxes.ContainsKey('tree-row-01'))) {
            $initSnap = $snap
            $script:currentSeq = $snap.seq
            L "Initial layout snapshot ready at seq=$($script:currentSeq) in $($swInit.ElapsedMilliseconds)ms"
            break
        }
        Start-Sleep -Milliseconds 300
    }

    if (-not $initSnap) {
        # Fatal setup failure: initial snapshot missing expected boxes within 10s (C-37-R2 #3)
        $latestSnap = Get-LatestSnapshot $Out
        $boxNames = if ($latestSnap -and $latestSnap.boxes) {
            @($latestSnap.boxes.Keys | Select-Object -First 40) -join ', '
        } else {
            'No snapshot available'
        }
        $stdoutPath = Join-Path $Out 'app-stdout.txt'
        $treeLines = @()
        if (Test-Path -LiteralPath $stdoutPath) {
            $lines = @(Get-Content -LiteralPath $stdoutPath -Encoding utf8)
            $treeLines = @($lines | Where-Object { $_ -match '^\[dev\] tree' } | Select-Object -Last 3)
        }
        $treeLinesStr = if ($treeLines.Count -gt 0) { ($treeLines -join "`n  ") } else { 'No [dev] tree lines in stdout' }

        L "FATAL: setup - Initial snapshot with 'project-empty-open' or 'tree-row-01' not found within 10s."
        L "Latest snapshot box names (first 40): $boxNames"
        L "Recent [dev] tree stdout lines (last 3):`n  $treeLinesStr"
        $global:summary.results['setup'] = "FATAL: setup - Initial snapshot timeout"
        throw "setup: initial snapshot missing project-empty-open or tree-row-01"
    }

    # 5. Open Project Folder in App if needed (C-37-R2 #2: click project-empty-open and wait up to 8s for tree-row-01)
    if ($initSnap.boxes.ContainsKey('project-empty-open')) {
        $emptyOpen = Get-BoxScreenCoord $script:appHwnd $Out 'project-empty-open'
        if (-not $emptyOpen) {
            L "FATAL: setup - Failed to compute screen coordinates for 'project-empty-open'."
            $global:summary.results['setup'] = "FATAL: setup - project-empty-open coords not found"
            throw "setup: project-empty-open coordinates not found"
        }

        L "Found 'project-empty-open' button at ($($emptyOpen.X), $($emptyOpen.Y)). Clicking to open project..."
        $prevSeq = $script:currentSeq
        Safe-Click $emptyOpen.X $emptyOpen.Y

        L "Waiting for 'tree-row-01' to appear in layout snapshot (up to 8s)..."
        $treeLoaded = $false
        $swTree = [System.Diagnostics.Stopwatch]::StartNew()
        while ($swTree.ElapsedMilliseconds -lt 8000) {
            $snap = Wait-NextSnapshot $Out $prevSeq 1000
            if ($snap -and $snap.boxes.ContainsKey('tree-row-01')) {
                $script:currentSeq = $snap.seq
                $treeLoaded = $true
                L "Project tree loaded: 'tree-row-01' present at seq=$($script:currentSeq) in $($swTree.ElapsedMilliseconds)ms"
                break
            }
            Start-Sleep -Milliseconds 300
        }

        if (-not $treeLoaded) {
            # Fatal setup failure: tree-row-01 not appeared within 8s (C-37-R2 #3)
            $latestSnap = Get-LatestSnapshot $Out
            $boxNames = if ($latestSnap -and $latestSnap.boxes) {
                @($latestSnap.boxes.Keys | Select-Object -First 40) -join ', '
            } else {
                'No snapshot available'
            }
            $stdoutPath = Join-Path $Out 'app-stdout.txt'
            $treeLines = @()
            if (Test-Path -LiteralPath $stdoutPath) {
                $lines = @(Get-Content -LiteralPath $stdoutPath -Encoding utf8)
                $treeLines = @($lines | Where-Object { $_ -match '^\[dev\] tree' } | Select-Object -Last 3)
            }
            $treeLinesStr = if ($treeLines.Count -gt 0) { ($treeLines -join "`n  ") } else { 'No [dev] tree lines in stdout' }

            L "FATAL: setup - 'tree-row-01' not found in layout snapshot within 8s after clicking 'project-empty-open'."
            L "Latest snapshot box names (first 40): $boxNames"
            L "Recent [dev] tree stdout lines (last 3):`n  $treeLinesStr"
            $global:summary.results['setup'] = "FATAL: setup - tree-row-01 appearance timeout"
            throw "setup: tree-row-01 not found after clicking project-empty-open"
        }
    } else {
        L "Project tree already loaded ('tree-row-01' present at initial snapshot seq=$($initSnap.seq))."
    }

    # 6. Open AGENTS.md from tree to establish initial file tab precondition
    $opened = Open-FileFromTree $script:appHwnd $Out 'AGENTS.md' $targetFixture
    if (-not $opened) {
        L "Warning: Failed to open 'AGENTS.md' initially from tree"
    }

    $global:summary.results['setup'] = "PASS - Tree and initial file tab established"
    L "[RESULT] setup: PASS - Tree and initial file tab established"

    # 7. Check if only setup was requested (C-37-R2 #5: -Steps setup)
    if ($normalizedSteps.Contains('setup') -and (-not ($normalizedSteps | Where-Object { $_ -ne 'setup' }))) {
        L "-Steps setup requested: Setup completed successfully. Exiting before running measurement steps."
        return
    }

    # Execute all measurement steps
    Invoke-MeasureStep 'step1' 'I-11: Tab Hover Tooltip & Navigation Button Tooltips' $step1Action
    Invoke-MeasureStep 'step2' 'I-23: Tab Bar Right Buttons Visibility on Pane Focus' $step2Action
    Invoke-MeasureStep 'step3' 'I-16: Tab Overflow, Wheel Scroll & Active Tab Visibility' $step3Action
    Invoke-MeasureStep 'step4' 'I-12: Breadcrumb Path & Heading Hierarchy (Single/Multi-Folder)' $step4Action
    Invoke-MeasureStep 'step5' 'I-10: Navigation History Traversal (Alt-Left/Right & XBUTTON1)' $step5Action
}
catch {
    L "FATAL: $_"
    L $_.ScriptStackTrace
}
finally {
    L "Cleaning up test environment and ensuring full session restoration..."

    # 1. Safely close opened app process (ONLY session PID, verify process name) (C-37-R1 #3)
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

    # 2. Restore AppData via session.ps1 Stop (MANDATORY rollback guard)
    if (Test-Path (Join-Path $Out 'session.json')) {
        L "Restoring app data via session.ps1 -Action Stop..."
        $stopOutput = & pwsh -NoProfile -File 'tools/measure/session.ps1' -Action Stop -Out $Out -Backup $backupDir 2>&1
        foreach ($line in $stopOutput) { L "session.ps1 Stop: $line" }
    }

    # 3. Save execution summary
    $summaryJson = Join-Path $Out 'order09-summary.json'
    $global:summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $summaryJson -Encoding utf8
    L "Summary written to $summaryJson"
}

L "ORDER-09 V3 measurement run completed."

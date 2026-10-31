#Requires -Version 7
<#
.SYNOPSIS
  PLAN Phase 1 (SPEC R-1~R-3) 증거를 모은다. PNG·JSON 을 specs/v0.1/verify/phase1/ 에 저장한다.

.DESCRIPTION
  앱(target\debug\workbench-gpui.exe)을 실행하고 SendInput 으로 마우스를 움직여 다음을 찍는다.
    1 snap-flyout      최대화 버튼 hover 후 모니터 전체 화면 (스냅 레이아웃 플라이아웃은 별도 창이라 화면 복사)
    2 dblclick-*       타이틀 바 더블클릭 → 최대화, 다시 더블클릭 → 복원 (전후)
    3 drag-*           타이틀 바 끌기 이동 (전후)
    4 resize-*         오른쪽 아래 모서리 끌기 리사이즈 (전후)
    5 minsize-*        최소 크기(360×240 논리 px)보다 작게 줄이기 시도 후 크기
    6 close-hover      닫기 버튼 hover 캡처와 배경 색 샘플(hex)
    7 window-normal / window-maximized   비최대화·최대화 캡처
  창 측정·캡처는 tools/capture.ps1 을 다시 쓴다. 이 스크립트도 PER_MONITOR_AWARE_V2 로 바꿔 좌표를 물리 px 로 다룬다.
  마지막에 summary.json 에 단계별 결과와 판정에 쓸 값을 모은다. 판정 자체는 wg-checker 가 한다.

.PARAMETER Exe
  실행할 exe. 기본 target\debug\workbench-gpui.exe.

.PARAMETER OutDir
  저장 폴더. 기본 specs\v0.1\verify\phase1.

.PARAMETER KeepRunning
  끝난 뒤 앱을 닫지 않는다. 이 스크립트가 띄운 앱만 닫는다.

.EXAMPLE
  pwsh -NoProfile -File tools/verify-phase1.ps1
#>
[CmdletBinding()]
param(
    [string]$Exe = 'target\debug\workbench-gpui.exe',
    [string]$OutDir = 'specs\v0.1\verify\phase1',
    [switch]$KeepRunning
)

$ErrorActionPreference = 'Stop'
$ProcessName = 'workbench-gpui'
$AppTitle = 'workbench-gpui'
$CaptureScript = Join-Path $PSScriptRoot 'capture.ps1'

Add-Type -AssemblyName System.Drawing.Common
Add-Type -AssemblyName System.Drawing.Primitives

if (-not ('WgVerify.Native' -as [type])) {
    # -ReferencedAssemblies 를 주면 기본 참조가 줄어든다. C# 코드가 쓰는 어셈블리를 모두 적는다.
    # (Thread 는 System.Threading.Thread.dll 에 있다.)
    $refs = @(
        'System.Runtime'
        'System.Threading'
        'System.Threading.Thread'
        'System.Runtime.InteropServices'
        'System.Drawing.Common'
        'System.Drawing.Primitives'
        'System.ComponentModel.Primitives'
    )
    $drawingDir = [System.IO.Path]::GetDirectoryName([System.Drawing.Bitmap].Assembly.Location)
    foreach ($n in 'System.Private.Windows.GdiPlus', 'System.Private.Windows.Core') {
        $p = Join-Path $drawingDir "$n.dll"
        if (Test-Path -LiteralPath $p) { $refs += $p }
    }
    Add-Type -ReferencedAssemblies $refs -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Threading;

namespace WgVerify
{
    [StructLayout(LayoutKind.Sequential)]
    public struct MOUSEINPUT
    {
        public int dx;
        public int dy;
        public uint mouseData;
        public uint dwFlags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct INPUT
    {
        public uint type;
        public MOUSEINPUT mi;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }

    [StructLayout(LayoutKind.Sequential)]
    public struct POINT { public int X, Y; }

    public static class Native
    {
        public static readonly IntPtr DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = new IntPtr(-4);
        const uint INPUT_MOUSE = 0;
        const uint MOUSEEVENTF_MOVE = 0x0001;
        const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
        const uint MOUSEEVENTF_LEFTUP = 0x0004;
        const uint MOUSEEVENTF_VIRTUALDESK = 0x4000;
        const uint MOUSEEVENTF_ABSOLUTE = 0x8000;
        const int SM_XVIRTUALSCREEN = 76, SM_YVIRTUALSCREEN = 77, SM_CXVIRTUALSCREEN = 78, SM_CYVIRTUALSCREEN = 79;
        public const int SW_MAXIMIZE = 3, SW_RESTORE = 9;
        const uint SWP_NOZORDER = 0x0004, SWP_NOACTIVATE = 0x0010;

        [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr ctx);
        [DllImport("user32.dll", SetLastError = true)] static extern uint SendInput(uint n, INPUT[] inputs, int size);
        [DllImport("user32.dll")] static extern IntPtr WindowFromPoint(POINT p);
        [DllImport("user32.dll")] static extern IntPtr GetAncestor(IntPtr hWnd, uint flags);
        const uint GA_ROOT = 2;
        public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
        [DllImport("user32.dll")] static extern bool EnumWindows(EnumWindowsProc cb, IntPtr lParam);
        [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
        [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr hWnd);
        [DllImport("user32.dll")] static extern IntPtr GetWindow(IntPtr hWnd, uint cmd);
        [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder sb, int max);

        public static string Title(IntPtr h)
        {
            var sb = new System.Text.StringBuilder(512);
            GetWindowText(h, sb, sb.Capacity);
            return sb.ToString();
        }

        // 프로세스의 보이는 소유자 없는 최상위 창 중 제목이 title 인 가장 큰 창, 없으면 가장 큰 창.
        public static IntPtr FindMain(uint pid, string title)
        {
            IntPtr bestTitled = IntPtr.Zero, bestAny = IntPtr.Zero;
            long areaTitled = 0, areaAny = 0;
            EnumWindows((h, l) =>
            {
                uint p;
                GetWindowThreadProcessId(h, out p);
                if (p != pid || !IsWindowVisible(h) || GetWindow(h, 4 /* GW_OWNER */) != IntPtr.Zero) return true;
                RECT r;
                GetWindowRect(h, out r);
                long area = (long)(r.Right - r.Left) * (r.Bottom - r.Top);
                var sb = new System.Text.StringBuilder(512);
                GetWindowText(h, sb, sb.Capacity);
                if (sb.ToString() == title && area > areaTitled) { areaTitled = area; bestTitled = h; }
                if (area > areaAny) { areaAny = area; bestAny = h; }
                return true;
            }, IntPtr.Zero);
            return bestTitled != IntPtr.Zero ? bestTitled : bestAny;
        }

        // 화면 좌표 (x,y) 아래 창의 최상위(루트) 창.
        public static IntPtr RootAt(int x, int y)
        {
            var h = WindowFromPoint(new POINT { X = x, Y = y });
            return h == IntPtr.Zero ? IntPtr.Zero : GetAncestor(h, GA_ROOT);
        }

        // (x0,y0) 에서 (x1,y1) 까지 실제 마우스 이동(SendInput)을 steps 번에 나눠 보낸다.
        public static void Glide(int x0, int y0, int x1, int y1, int steps, int stepMs)
        {
            for (int i = 0; i <= steps; i++)
            {
                MoveTo(x0 + (x1 - x0) * i / steps, y0 + (y1 - y0) * i / steps);
                Thread.Sleep(stepMs);
            }
        }
        [DllImport("user32.dll")] static extern int GetSystemMetrics(int index);
        [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
        [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int cmd);
        [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr hWnd, IntPtr after, int x, int y, int cx, int cy, uint flags);
        [DllImport("user32.dll")] public static extern uint GetDoubleClickTime();

        static void Send(uint flags, int x, int y)
        {
            int vx = GetSystemMetrics(SM_XVIRTUALSCREEN), vy = GetSystemMetrics(SM_YVIRTUALSCREEN);
            int vw = GetSystemMetrics(SM_CXVIRTUALSCREEN), vh = GetSystemMetrics(SM_CYVIRTUALSCREEN);
            var input = new INPUT { type = INPUT_MOUSE };
            input.mi.dx = (int)Math.Round((x - vx) * 65535.0 / Math.Max(1, vw - 1));
            input.mi.dy = (int)Math.Round((y - vy) * 65535.0 / Math.Max(1, vh - 1));
            input.mi.dwFlags = flags | MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_VIRTUALDESK;
            if (SendInput(1, new[] { input }, Marshal.SizeOf(typeof(INPUT))) != 1)
                throw new InvalidOperationException("SendInput failed: " + Marshal.GetLastWin32Error());
        }

        public static void MoveTo(int x, int y) { Send(0, x, y); }
        public static void Down(int x, int y) { Send(MOUSEEVENTF_LEFTDOWN, x, y); }
        public static void Up(int x, int y) { Send(MOUSEEVENTF_LEFTUP, x, y); }

        public static void DoubleClick(int x, int y)
        {
            MoveTo(x, y); Thread.Sleep(80);
            Down(x, y); Thread.Sleep(30); Up(x, y);
            Thread.Sleep(60);
            Down(x, y); Thread.Sleep(30); Up(x, y);
        }

        // (x0,y0) 에서 눌러 steps 번에 나눠 (x1,y1) 까지 끈 뒤 놓는다.
        public static void Drag(int x0, int y0, int x1, int y1, int steps, int stepMs)
        {
            MoveTo(x0, y0); Thread.Sleep(120);
            Down(x0, y0); Thread.Sleep(120);
            for (int i = 1; i <= steps; i++)
            {
                int x = x0 + (x1 - x0) * i / steps, y = y0 + (y1 - y0) * i / steps;
                MoveTo(x, y);
                Thread.Sleep(stepMs);
            }
            Thread.Sleep(120);
            Up(x1, y1);
        }

        public static void Place(IntPtr hWnd, int x, int y, int w, int h)
        {
            SetWindowPos(hWnd, IntPtr.Zero, x, y, w, h, SWP_NOZORDER | SWP_NOACTIVATE);
        }

        // 화면 좌표 사각형을 PNG 로 저장한다 (모니터 전체 캡처용).
        public static void SaveScreen(int x, int y, int w, int h, string path)
        {
            using (var bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb))
            using (var g = Graphics.FromImage(bmp))
            {
                g.CopyFromScreen(x, y, 0, 0, new Size(w, h), CopyPixelOperation.SourceCopy);
                bmp.Save(path, ImageFormat.Png);
            }
        }

        // PNG 의 한 픽셀을 #RRGGBB 로 돌려준다.
        public static string Pixel(string path, int x, int y)
        {
            using (var bmp = new Bitmap(path))
            {
                if (x < 0 || y < 0 || x >= bmp.Width || y >= bmp.Height) return null;
                var c = bmp.GetPixel(x, y);
                return string.Format("#{0:X2}{1:X2}{2:X2}", c.R, c.G, c.B);
            }
        }
    }
}
'@
}

$outPath = [System.IO.Path]::GetFullPath($OutDir, (Get-Location).Path)
if (-not (Test-Path -LiteralPath $outPath)) { New-Item -ItemType Directory -Path $outPath -Force | Out-Null }

$summary = [ordered]@{
    startedAt = (Get-Date).ToString('o')
    exe       = $null
    steps     = [ordered]@{}
    errors    = @()
}

# capture.ps1 을 실행해 JSON 을 저장하고 객체로 돌려준다.
# 스크립트가 고정한 창($script:hwnd)만 capture.ps1 에 넘긴다(-Hwnd). 입력 대상과 캡처 대상이 같아야 한다.
# 결과 JSON 의 hwnd 가 고정한 창과 다르면 오류로 끝낸다.
function Invoke-Capture([string]$Name, [string]$Method = 'PrintWindow') {
    $png = Join-Path $outPath "$Name.png"
    $jsonPath = Join-Path $outPath "$Name.json"
    $expected = '0x{0:X}' -f $script:hwnd.ToInt64()
    $raw = & pwsh -NoProfile -File $CaptureScript -Hwnd $expected -Out $png -Method $Method
    $code = $LASTEXITCODE
    $text = ($raw | Out-String)
    Set-Content -LiteralPath $jsonPath -Value $text -Encoding utf8
    $obj = $text | ConvertFrom-Json
    if ($obj.hwnd -ne $expected -or $obj.pid -ne $script:appPid) {
        throw "capture ${Name}: 캡처한 창(hwnd=$($obj.hwnd), pid=$($obj.pid))이 고정한 창(hwnd=$expected, pid=$($script:appPid))과 다르다"
    }
    if ($code -ne 0 -or -not $obj.capture.ok) {
        $script:summary.errors += "capture $Name 실패: $($obj.capture.error)"
    }
    return $obj
}

# MainWindowHandle 은 같은 프로세스의 다른 작은 최상위 창을 가리킬 수 있어 쓰지 않는다.
# 스크립트가 띄운 프로세스(PID)에서만, 제목이 앱 제목인 가장 큰 보이는 최상위 창을 찾는다.
function Get-MainWindow([int]$ProcessId) {
    $h = [WgVerify.Native]::FindMain([uint32]$ProcessId, $AppTitle)
    if ($h -ne [IntPtr]::Zero -and [WgVerify.Native]::Title($h) -eq $AppTitle) { return $h }
    return [IntPtr]::Zero
}

function Wait-Until([scriptblock]$Condition, [int]$TimeoutMs = 3000) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.ElapsedMilliseconds -lt $TimeoutMs) {
        if (& $Condition) { return $true }
        Start-Sleep -Milliseconds 100
    }
    return $false
}

# 입력 직전 확인: 대상 창이 전면이고, (x,y) 아래 루트 창이 대상 창이어야 한다.
# 하나라도 아니면 입력을 보내지 않고 오류로 끝낸다 (다른 창에 클릭·끌기가 가지 않게).
function Assert-Target([int]$X, [int]$Y, [string]$What) {
    if ([WgVerify.Native]::GetForegroundWindow() -ne $script:hwnd) {
        [void][WgVerify.Native]::SetForegroundWindow($script:hwnd)
        Start-Sleep -Milliseconds 300
    }
    if ([WgVerify.Native]::GetForegroundWindow() -ne $script:hwnd) {
        throw "${What}: 대상 창을 전면으로 가져오지 못했다. 입력을 보내지 않고 중단한다"
    }
    $root = [WgVerify.Native]::RootAt($X, $Y)
    if ($root -ne $script:hwnd) {
        throw ("{0}: 커서 위치 ({1},{2}) 아래 창(0x{3:X})이 대상 창(0x{4:X})이 아니다. 입력을 보내지 않고 중단한다" -f $What, $X, $Y, $root.ToInt64(), $script:hwnd.ToInt64())
    }
}

# 타이틀 바·창 버튼 위치(물리 px). clientRect 기준, 치수는 L-21(32)·L-39(36×32) × 배율.
function Get-Points($m) {
    $s = [double]$m.scale
    $c = $m.clientRect
    $barY = [int]($c.y + 16 * $s)
    [ordered]@{
        dragX  = [int]($c.x + [math]::Min(200 * $s, $c.width / 3))
        barY   = $barY
        closeX = [int]($c.x + $c.width - 18 * $s)
        maxX   = [int]($c.x + $c.width - 54 * $s)
        minX   = [int]($c.x + $c.width - 90 * $s)
        # 최대화하지 않은 창의 오른쪽 아래 리사이즈 경계: DWM 프레임 바깥, GetWindowRect 안쪽.
        cornerX = [int]($m.rect.x + $m.rect.width + 3)
        cornerY = [int]($m.rect.y + $m.rect.height + 3)
    }
}

$prev = [WgVerify.Native]::SetThreadDpiAwarenessContext([WgVerify.Native]::DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)
if ($prev -eq [IntPtr]::Zero) { throw 'SetThreadDpiAwarenessContext(PER_MONITOR_AWARE_V2) 실패' }

$launched = $null
$script:appPid = 0
$hwnd = [IntPtr]::Zero
try {
    # 0) 앱 실행. 이미 실행 중인 workbench-gpui 가 있으면 대상이 섞일 수 있어 오류로 끝낸다
    #    (다른 프로세스는 건드리지 않는다).
    $existing = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
    if ($existing.Count -gt 0) {
        throw "이미 실행 중인 $ProcessName 가 있다 (PID $($existing.Id -join ', ')). 닫고 다시 실행하라"
    }
    $exePath = (Resolve-Path -LiteralPath $Exe).Path
    $summary.exe = $exePath
    $launched = Start-Process -FilePath $exePath -PassThru
    $script:appPid = $launched.Id
    $summary.pid = $script:appPid
    if (-not (Wait-Until { (Get-MainWindow $script:appPid) -ne [IntPtr]::Zero } 20000)) { throw '앱 창이 20초 안에 뜨지 않았다' }
    Start-Sleep -Milliseconds 1500
    # 이후 모든 입력·캡처는 이 PID·HWND 로 고정한다.
    $hwnd = Get-MainWindow $script:appPid
    if ($hwnd -eq [IntPtr]::Zero) { throw '앱 메인 창을 찾지 못했다' }
    $summary.hwnd = '0x{0:X}' -f $hwnd.ToInt64()
    [void][WgVerify.Native]::SetForegroundWindow($hwnd)
    Start-Sleep -Milliseconds 300
    if ([WgVerify.Native]::GetForegroundWindow() -ne $hwnd) {
        throw '시작: 대상 창을 전면으로 가져오지 못했다. 입력을 보내지 않고 중단한다'
    }

    # 시작 상태를 정한다: 복원하고 작업 영역 안쪽 크기로 둔다.
    [void][WgVerify.Native]::ShowWindow($hwnd, [WgVerify.Native]::SW_RESTORE)
    Start-Sleep -Milliseconds 500
    $m0 = Invoke-Capture 'setup'
    $w = $m0.monitor.workRect
    $placeW = [int]($w.width * 0.6); $placeH = [int]($w.height * 0.6)
    [WgVerify.Native]::Place($hwnd, [int]($w.x + $w.width * 0.15), [int]($w.y + $w.height * 0.15), $placeW, $placeH)
    Start-Sleep -Milliseconds 600

    # 7a) 비최대화 캡처
    $normal = Invoke-Capture 'window-normal'
    $summary.steps.windowNormal = [ordered]@{ maximized = $normal.maximized; rect = $normal.rect; clientRect = $normal.clientRect; dpi = $normal.dpi }

    # 1) 최대화 버튼 hover → 스냅 플라이아웃 (모니터 전체 화면 복사)
    #    창 본문에서 최대화 버튼까지 실제 마우스 이동(SendInput MOVE|ABSOLUTE)을 여러 번 나눠 보내
    #    WM_NCMOUSEMOVE 가 오게 하고, 버튼 위에 1.5초 머문 뒤 찍는다.
    $pt = Get-Points $normal
    $startX = $pt.maxX - [int](120 * $normal.scale); $startY = $pt.barY + [int](120 * $normal.scale)
    Assert-Target $startX $startY 'snap-flyout 시작점'
    Assert-Target $pt.maxX $pt.barY 'snap-flyout 최대화 버튼'
    [WgVerify.Native]::Glide($startX, $startY, $pt.maxX, $pt.barY, 20, 15)
    Start-Sleep -Milliseconds 1500
    $mon = $normal.monitor.rect
    $flyPng = Join-Path $outPath 'snap-flyout.png'
    [WgVerify.Native]::SaveScreen($mon.x, $mon.y, $mon.width, $mon.height, $flyPng)
    $summary.steps.snapFlyout = [ordered]@{
        cursor = @($pt.maxX, $pt.barY); screenshot = $flyPng
        note = '플라이아웃이 보이는지는 PNG 를 눈으로 판정한다'
    }
    $awayY = $pt.barY + [int](200 * $normal.scale)
    Assert-Target $pt.dragX $awayY 'snap-flyout 이후 커서 치우기'
    [WgVerify.Native]::MoveTo($pt.dragX, $awayY)
    Start-Sleep -Milliseconds 600

    # 2) 타이틀 바 더블클릭 → 최대화 → 다시 더블클릭 → 복원
    $before = Invoke-Capture 'dblclick-before'
    $pt = Get-Points $before
    Assert-Target $pt.dragX $pt.barY '더블클릭(최대화)'
    [WgVerify.Native]::DoubleClick($pt.dragX, $pt.barY)
    [void](Wait-Until { (Invoke-Capture 'dblclick-maximized').maximized } 3000)
    $maxd = Invoke-Capture 'dblclick-maximized'
    $pt2 = Get-Points $maxd
    Start-Sleep -Milliseconds ([WgVerify.Native]::GetDoubleClickTime() + 100)
    Assert-Target $pt2.dragX $pt2.barY '더블클릭(복원)'
    [WgVerify.Native]::DoubleClick($pt2.dragX, $pt2.barY)
    [void](Wait-Until { -not (Invoke-Capture 'dblclick-restored').maximized } 3000)
    $rest = Invoke-Capture 'dblclick-restored'
    $summary.steps.doubleClick = [ordered]@{
        before = $before.maximized; afterFirst = $maxd.maximized; afterSecond = $rest.maximized
        restoredRectEqualsBefore = (($before.rect | ConvertTo-Json -Compress) -eq ($rest.rect | ConvertTo-Json -Compress))
    }

    # 7b) 최대화 캡처 (최대화 상태의 복원 글리프 U+E923 확인용)
    [void][WgVerify.Native]::ShowWindow($hwnd, [WgVerify.Native]::SW_MAXIMIZE)
    Start-Sleep -Milliseconds 800
    $maxCap = Invoke-Capture 'window-maximized'
    $summary.steps.windowMaximized = [ordered]@{ maximized = $maxCap.maximized; rect = $maxCap.rect; clientRect = $maxCap.clientRect }
    [void][WgVerify.Native]::ShowWindow($hwnd, [WgVerify.Native]::SW_RESTORE)
    Start-Sleep -Milliseconds 800

    # 3) 타이틀 바 끌기 이동
    $before = Invoke-Capture 'drag-before'
    $pt = Get-Points $before
    $dx = [int](150 * $before.scale); $dy = [int](80 * $before.scale)
    Assert-Target $pt.dragX $pt.barY '타이틀 바 끌기'
    [WgVerify.Native]::Drag($pt.dragX, $pt.barY, $pt.dragX + $dx, $pt.barY + $dy, 20, 15)
    Start-Sleep -Milliseconds 600
    $after = Invoke-Capture 'drag-after'
    $summary.steps.drag = [ordered]@{
        requested = @($dx, $dy)
        moved = @(($after.rect.x - $before.rect.x), ($after.rect.y - $before.rect.y))
        sizeUnchanged = ($after.rect.width -eq $before.rect.width -and $after.rect.height -eq $before.rect.height)
        maximizedAfter = $after.maximized
    }

    # 4) 오른쪽 아래 모서리 끌기 리사이즈
    $before = $after
    $pt = Get-Points $before
    $rx = [int](-200 * $before.scale); $ry = [int](-120 * $before.scale)
    Assert-Target $pt.cornerX $pt.cornerY '모서리 리사이즈'
    [WgVerify.Native]::Drag($pt.cornerX, $pt.cornerY, $pt.cornerX + $rx, $pt.cornerY + $ry, 20, 15)
    Start-Sleep -Milliseconds 600
    $after = Invoke-Capture 'resize-after'
    Copy-Item -LiteralPath (Join-Path $outPath 'drag-after.png') -Destination (Join-Path $outPath 'resize-before.png') -Force
    Copy-Item -LiteralPath (Join-Path $outPath 'drag-after.json') -Destination (Join-Path $outPath 'resize-before.json') -Force
    $summary.steps.resize = [ordered]@{
        requested = @($rx, $ry)
        changed = @(($after.rect.width - $before.rect.width), ($after.rect.height - $before.rect.height))
        originUnchanged = ($after.rect.x -eq $before.rect.x -and $after.rect.y -eq $before.rect.y)
    }

    # 5) 최소 크기보다 작게 줄이기 시도
    $before = $after
    $pt = Get-Points $before
    $tx = $before.rect.x + 20; $ty = $before.rect.y + 20
    Assert-Target $pt.cornerX $pt.cornerY '최소 크기 리사이즈'
    [WgVerify.Native]::Drag($pt.cornerX, $pt.cornerY, $tx, $ty, 30, 15)
    Start-Sleep -Milliseconds 600
    $min = Invoke-Capture 'minsize-after'
    $s = [double]$min.scale
    $summary.steps.minSize = [ordered]@{
        expectedLogical = @(360, 240)
        expectedPhysical = @([int](360 * $s), [int](240 * $s))
        clientPhysical = @($min.clientRect.width, $min.clientRect.height)
        framePhysical = @($min.rect.width, $min.rect.height)
        clientLogical = @([math]::Round($min.clientRect.width / $s, 2), [math]::Round($min.clientRect.height / $s, 2))
        note = 'WM_GETMINMAXINFO 의 최소 크기가 프레임 기준인지 클라이언트 기준인지는 판정 때 함께 본다'
    }
    # 다음 단계를 위해 다시 크게 둔다.
    [WgVerify.Native]::Place($hwnd, [int]($w.x + $w.width * 0.15), [int]($w.y + $w.height * 0.15), $placeW, $placeH)
    Start-Sleep -Milliseconds 600

    # 6) 닫기 버튼 hover 캡처와 배경 색
    $cur = Invoke-Capture 'close-hover-setup'
    $pt = Get-Points $cur
    Assert-Target $pt.closeX $pt.barY '닫기 버튼 hover'
    [WgVerify.Native]::MoveTo($pt.closeX, $pt.barY)
    Start-Sleep -Milliseconds 700
    $hover = Invoke-Capture 'close-hover'
    $png = Join-Path $outPath 'close-hover.png'
    # 글리프를 피해 버튼 왼쪽 위 안쪽(4 논리 px)을 샘플한다.
    $sx = [int]($pt.closeX - 18 * $hover.scale + 4 * $hover.scale) - $hover.rect.x
    $sy = [int]($hover.clientRect.y + 4 * $hover.scale) - $hover.rect.y
    $summary.steps.closeHover = [ordered]@{
        cursor = @($pt.closeX, $pt.barY)
        samplePixel = @($sx, $sy)
        sampleColor = [WgVerify.Native]::Pixel($png, $sx, $sy)
        expected = '#E81120'
    }
    $awayY = $pt.barY + [int](200 * $hover.scale)
    Assert-Target $pt.dragX $awayY '닫기 hover 이후 커서 치우기'
    [WgVerify.Native]::MoveTo($pt.dragX, $awayY)
}
catch {
    $summary.errors += $_.Exception.Message
}
finally {
    [void][WgVerify.Native]::SetThreadDpiAwarenessContext($prev)
    if ($launched -and -not $KeepRunning) {
        try { [void]$launched.CloseMainWindow(); [void]$launched.WaitForExit(5000) } catch {}
        if (-not $launched.HasExited) { try { $launched.Kill() } catch {} }
    }
}

$summary.finishedAt = (Get-Date).ToString('o')
$summaryPath = Join-Path $outPath 'summary.json'
$summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $summaryPath -Encoding utf8
Get-Content -LiteralPath $summaryPath -Raw
if ($summary.errors.Count -gt 0) { exit 1 }

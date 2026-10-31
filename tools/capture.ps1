#Requires -Version 7
<#
.SYNOPSIS
  앱 메인 창의 사각형·DPI 배율·최대화 여부를 JSON으로 내고, 창 영역을 PNG로 저장한다.

.DESCRIPTION
  검증 증거용 도구 (specs/v0.1 SPEC 공통 판정 방식).
  - 측정 전에 이 스레드를 PER_MONITOR_AWARE_V2로 바꿔 모든 좌표를 물리 px로 받는다.
  - DPI는 GetDpiForWindow(hwnd)로 얻는다. GetDpiForMonitor는 per-monitor DPI aware 스레드에서
    쓰면 안 된다(MS Learn GetDpiForMonitor Remarks)라서 쓰지 않는다. 모니터는 장치 이름과 사각형만 낸다.
  - rect 는 DWM 확장 프레임 경계(그림자 제외)다. windowRect(GetWindowRect)·clientRect 도 함께 낸다.
  - 사각형·DPI·최대화 여부는 캡처 직전에 한 번에 재고, 캡처 직후 다시 잰다. 다르면 오류로 끝낸다.
  - 저장 방식: PrintWindow(기본, PW_RENDERFULLCONTENT) 또는 Screen(명시했을 때만. 화면 복사).
    Screen은 창을 전면으로 가져오지 못하면 오류로 끝낸다(가려진 화면이 증거가 되지 않게).
  - 실패하면 JSON에 capture.ok=false 와 이유를 남기고 종료 코드 1로 끝낸다.
  외부 모듈 없이 Add-Type(C# P/Invoke)만 쓴다.

.PARAMETER ProcessName
  프로세스 이름 (확장자 없이). 기본 workbench-gpui.

.PARAMETER Out
  저장할 PNG 경로.

.PARAMETER Method
  PrintWindow 또는 Screen. 기본 PrintWindow.

.EXAMPLE
  pwsh -NoProfile -File tools/capture.ps1 -Out specs/v0.1/verify/phase1/window.png
#>
[CmdletBinding()]
param(
    [string]$ProcessName = 'workbench-gpui',
    [Parameter(Mandatory = $true)][string]$Out,
    [ValidateSet('PrintWindow', 'Screen')][string]$Method = 'PrintWindow'
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing.Common
Add-Type -AssemblyName System.Drawing.Primitives

if (-not ('WgCapture.Native' -as [type])) {
    # -ReferencedAssemblies 를 주면 기본 참조가 줄어든다. C# 코드가 쓰는 어셈블리를 모두 적는다.
    $refs = @(
        'System.Runtime'
        'System.Collections'
        'System.Runtime.InteropServices'
        'System.Drawing.Common'
        'System.Drawing.Primitives'
        'System.ComponentModel.Primitives'
    )
    # .NET 9 이후 System.Drawing.Common 은 형식 일부를 System.Private.Windows.* 로 옮겼다. 있으면 함께 참조한다.
    $drawingDir = [System.IO.Path]::GetDirectoryName([System.Drawing.Bitmap].Assembly.Location)
    foreach ($n in 'System.Private.Windows.GdiPlus', 'System.Private.Windows.Core') {
        $p = Join-Path $drawingDir "$n.dll"
        if (Test-Path -LiteralPath $p) { $refs += $p }
    }
    Add-Type -ReferencedAssemblies $refs -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Text;

namespace WgCapture
{
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }

    [StructLayout(LayoutKind.Sequential)]
    public struct POINT { public int X, Y; }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct MONITORINFOEX
    {
        public int cbSize;
        public RECT rcMonitor;
        public RECT rcWork;
        public uint dwFlags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string szDevice;
    }

    public static class Native
    {
        public static readonly IntPtr DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = new IntPtr(-4);
        public const int DWMWA_EXTENDED_FRAME_BOUNDS = 9;
        public const uint PW_RENDERFULLCONTENT = 2;
        public const uint MONITOR_DEFAULTTONEAREST = 2;

        public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

        [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr ctx);
        [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc cb, IntPtr lParam);
        [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
        [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern IntPtr GetWindow(IntPtr hWnd, uint cmd);
        [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
        [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hWnd, out RECT r);
        [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr hWnd, ref POINT p);
        [DllImport("user32.dll")] public static extern bool IsZoomed(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern uint GetDpiForWindow(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdc, uint flags);
        [DllImport("user32.dll")] public static extern IntPtr MonitorFromWindow(IntPtr hWnd, uint flags);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern bool GetMonitorInfo(IntPtr hMon, ref MONITORINFOEX mi);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowText(IntPtr hWnd, StringBuilder sb, int max);
        [DllImport("dwmapi.dll")] public static extern int DwmGetWindowAttribute(IntPtr hWnd, int attr, out RECT r, int size);

        // 주어진 프로세스의 보이는 최상위(소유자 없는) 창을 모두 찾는다.
        public static List<IntPtr> TopLevelWindows(uint pid)
        {
            var list = new List<IntPtr>();
            EnumWindows((h, l) =>
            {
                uint p;
                GetWindowThreadProcessId(h, out p);
                if (p == pid && IsWindowVisible(h) && GetWindow(h, 4 /* GW_OWNER */) == IntPtr.Zero)
                    list.Add(h);
                return true;
            }, IntPtr.Zero);
            return list;
        }

        public static string Title(IntPtr h)
        {
            var sb = new StringBuilder(512);
            GetWindowText(h, sb, sb.Capacity);
            return sb.ToString();
        }

        public static RECT FrameBounds(IntPtr h)
        {
            RECT r;
            if (DwmGetWindowAttribute(h, DWMWA_EXTENDED_FRAME_BOUNDS, out r, Marshal.SizeOf(typeof(RECT))) != 0)
                GetWindowRect(h, out r);
            return r;
        }

        public static RECT WindowRect(IntPtr h)
        {
            RECT r;
            GetWindowRect(h, out r);
            return r;
        }

        public static RECT ClientOnScreen(IntPtr h)
        {
            RECT c;
            GetClientRect(h, out c);
            var p = new POINT { X = 0, Y = 0 };
            ClientToScreen(h, ref p);
            return new RECT { Left = p.X, Top = p.Y, Right = p.X + c.Right, Bottom = p.Y + c.Bottom };
        }

        public static MONITORINFOEX Monitor(IntPtr h)
        {
            var mi = new MONITORINFOEX();
            mi.cbSize = Marshal.SizeOf(typeof(MONITORINFOEX));
            GetMonitorInfo(MonitorFromWindow(h, MONITOR_DEFAULTTONEAREST), ref mi);
            return mi;
        }

        // 화면 복사: 화면 좌표 r 영역을 그대로 복사한다.
        public static void CaptureScreen(RECT r, string path)
        {
            int w = r.Right - r.Left, ht = r.Bottom - r.Top;
            using (var bmp = new Bitmap(w, ht, PixelFormat.Format32bppArgb))
            using (var g = Graphics.FromImage(bmp))
            {
                g.CopyFromScreen(r.Left, r.Top, 0, 0, new Size(w, ht), CopyPixelOperation.SourceCopy);
                bmp.Save(path, ImageFormat.Png);
            }
        }

        // PrintWindow: 창 전체(GetWindowRect 크기)를 그리게 한 뒤, r 영역만 잘라 저장한다.
        // PrintWindow 가 실패하면 저장하지 않고 false 를 돌려준다.
        public static bool CapturePrintWindow(IntPtr h, RECT r, string path)
        {
            RECT wr;
            GetWindowRect(h, out wr);
            int ww = wr.Right - wr.Left, wh = wr.Bottom - wr.Top;
            using (var full = new Bitmap(ww, wh, PixelFormat.Format32bppArgb))
            {
                bool ok;
                using (var g = Graphics.FromImage(full))
                {
                    IntPtr hdc = g.GetHdc();
                    try { ok = PrintWindow(h, hdc, PW_RENDERFULLCONTENT); }
                    finally { g.ReleaseHdc(hdc); }
                }
                if (!ok) return false;
                var crop = new Rectangle(r.Left - wr.Left, r.Top - wr.Top, r.Right - r.Left, r.Bottom - r.Top);
                crop.Intersect(new Rectangle(0, 0, ww, wh));
                using (var part = full.Clone(crop, PixelFormat.Format32bppArgb))
                    part.Save(path, ImageFormat.Png);
            }
            return true;
        }
    }
}
'@
}

function ConvertTo-RectObject([WgCapture.RECT]$r) {
    [ordered]@{
        x      = $r.Left
        y      = $r.Top
        width  = $r.Right - $r.Left
        height = $r.Bottom - $r.Top
    }
}

# 사각형·DPI·최대화 여부를 한 번에 잰다.
function Measure-Window([IntPtr]$h) {
    $dpi = [WgCapture.Native]::GetDpiForWindow($h)
    [ordered]@{
        rect       = ConvertTo-RectObject ([WgCapture.Native]::FrameBounds($h))
        windowRect = ConvertTo-RectObject ([WgCapture.Native]::WindowRect($h))
        clientRect = ConvertTo-RectObject ([WgCapture.Native]::ClientOnScreen($h))
        dpi        = $dpi
        scale      = [math]::Round($dpi / 96.0, 4)
        maximized  = [WgCapture.Native]::IsZoomed($h)
    }
}

$capture = [ordered]@{
    method      = $Method
    ok          = $false
    error       = $null
    foreground  = $null
    out         = $null
    width       = $null
    height      = $null
}
$result = [ordered]@{}
$exitCode = 0

# 1) 이 스레드를 PER_MONITOR_AWARE_V2로 바꾼다. 이후 좌표는 모두 물리 px다.
$prevCtx = [WgCapture.Native]::SetThreadDpiAwarenessContext([WgCapture.Native]::DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)
if ($prevCtx -eq [IntPtr]::Zero) {
    throw 'SetThreadDpiAwarenessContext(PER_MONITOR_AWARE_V2) 실패'
}

try {
    # 2) 메인 창 찾기: MainWindowHandle을 먼저 쓰고, 없으면 보이는 최상위 창 중 가장 큰 것.
    $procs = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
    if ($procs.Count -eq 0) { throw "프로세스를 찾지 못했다: $ProcessName" }

    $hwnd = [IntPtr]::Zero
    $proc = $null
    foreach ($p in $procs) {
        if ($p.MainWindowHandle -ne [IntPtr]::Zero) { $hwnd = $p.MainWindowHandle; $proc = $p; break }
    }
    if ($hwnd -eq [IntPtr]::Zero) {
        $best = 0
        foreach ($p in $procs) {
            foreach ($h in [WgCapture.Native]::TopLevelWindows([uint32]$p.Id)) {
                $r = [WgCapture.Native]::FrameBounds($h)
                $area = ($r.Right - $r.Left) * ($r.Bottom - $r.Top)
                if ($area -gt $best) { $best = $area; $hwnd = $h; $proc = $p }
            }
        }
    }
    if ($hwnd -eq [IntPtr]::Zero) { throw "보이는 창을 찾지 못했다: $ProcessName" }
    if ([WgCapture.Native]::IsIconic($hwnd)) { throw '창이 최소화되어 있어 측정·캡처할 수 없다' }

    $result.processName = $proc.ProcessName
    $result.pid = $proc.Id
    $result.hwnd = ('0x{0:X}' -f $hwnd.ToInt64())
    $result.title = [WgCapture.Native]::Title($hwnd)
    $result.unit = 'physical px'

    $outPath = [System.IO.Path]::GetFullPath($Out, (Get-Location).Path)
    $outDir = [System.IO.Path]::GetDirectoryName($outPath)
    if ($outDir -and -not (Test-Path -LiteralPath $outDir)) {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }

    # 3) Screen 방식은 창을 전면으로 가져온다. 실패하면 오류로 끝낸다.
    if ($Method -eq 'Screen') {
        [void][WgCapture.Native]::SetForegroundWindow($hwnd)
        Start-Sleep -Milliseconds 300
        $capture.foreground = ([WgCapture.Native]::GetForegroundWindow() -eq $hwnd)
        if (-not $capture.foreground) { throw '창을 전면으로 가져오지 못했다 (Screen 방식은 가려진 화면을 찍을 수 있어 중단)' }
    }

    # 4) 캡처 직전 측정
    $before = Measure-Window $hwnd
    $frame = [WgCapture.Native]::FrameBounds($hwnd)
    $mi = [WgCapture.Native]::Monitor($hwnd)

    $result.rect = $before.rect
    $result.windowRect = $before.windowRect
    $result.clientRect = $before.clientRect
    $result.dpi = $before.dpi
    $result.scale = $before.scale
    $result.maximized = $before.maximized
    $result.monitor = [ordered]@{
        device   = $mi.szDevice
        rect     = ConvertTo-RectObject $mi.rcMonitor
        workRect = ConvertTo-RectObject $mi.rcWork
    }

    # 5) 캡처
    if ($Method -eq 'PrintWindow') {
        if (-not [WgCapture.Native]::CapturePrintWindow($hwnd, $frame, $outPath)) {
            throw 'PrintWindow(PW_RENDERFULLCONTENT) 실패'
        }
    } else {
        [WgCapture.Native]::CaptureScreen($frame, $outPath)
    }

    # 6) 캡처 직후 다시 재서 비교한다. 다르면 오류로 끝낸다.
    $after = Measure-Window $hwnd
    $beforeJson = $before | ConvertTo-Json -Depth 4 -Compress
    $afterJson = $after | ConvertTo-Json -Depth 4 -Compress
    if ($beforeJson -ne $afterJson) {
        $result.after = $after
        throw "캡처 중 창 상태가 바뀌었다. before=$beforeJson after=$afterJson"
    }

    $capture.ok = $true
    $capture.out = $outPath
    $capture.width = $frame.Right - $frame.Left
    $capture.height = $frame.Bottom - $frame.Top
}
catch {
    $capture.ok = $false
    $capture.error = $_.Exception.Message
    $exitCode = 1
}
finally {
    [void][WgCapture.Native]::SetThreadDpiAwarenessContext($prevCtx)
}

$result.capture = $capture
$result.timestamp = (Get-Date).ToString('o')
$result | ConvertTo-Json -Depth 5
exit $exitCode

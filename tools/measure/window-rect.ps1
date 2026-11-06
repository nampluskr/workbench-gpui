#Requires -Version 7
<#
.SYNOPSIS
  주어진 프로세스(기본 workbench-gpui)의 창 좌표·작업 영역·클라이언트 크기를 Win32 API로 측정하고 크기 조절/캡처/종료를 수행한다.
#>
[CmdletBinding()]
param(
    [string]$ProcessName = 'workbench-gpui',
    [string]$TargetHwnd,
    [ValidateSet('Measure', 'Resize', 'Close')][string]$Action = 'Measure',
    [int]$X = -10000,
    [int]$Y = -10000,
    [int]$Width = 100,
    [int]$Height = 100,
    [string]$Capture,
    [string]$Out
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing.Common
Add-Type -AssemblyName System.Drawing.Primitives

$refs = @(
    'System.Runtime',
    'System.Collections',
    'System.Runtime.InteropServices',
    'System.Threading',
    'System.Threading.Thread',
    'System.Drawing.Common',
    'System.Drawing.Primitives',
    'System.ComponentModel.Primitives'
)
$drawingDir = [System.IO.Path]::GetDirectoryName([System.Drawing.Bitmap].Assembly.Location)
foreach ($n in 'System.Private.Windows.GdiPlus', 'System.Private.Windows.Core') {
    $p = Join-Path $drawingDir "$n.dll"
    if (Test-Path -LiteralPath $p) { $refs += $p }
}

if (-not ('WgMeasureWin.Engine' -as [type])) {
    Add-Type -ReferencedAssemblies $refs -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

namespace WgMeasureWin
{
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT
    {
        public int Left, Top, Right, Bottom;
        public int Width => Right - Left;
        public int Height => Bottom - Top;
    }

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

    public class WindowMatch
    {
        public IntPtr Hwnd;
        public string Desktop;
        public string Title;
        public string ClassName;
    }

    public class MeasureResult
    {
        public string Hwnd;
        public string Desktop;
        public string Title;
        public string ClassName;
        public RECT WorkAreaSPI;
        public RECT WorkAreaMonitor;
        public string MonitorDevice;
        public RECT WindowRect;
        public RECT ClientRect;
        public POINT ClientOrigin;
        public bool CaptureOk;
        public string CapturePath;
    }

    public static class Engine
    {
        public static readonly IntPtr DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = new IntPtr(-4);
        public const uint SPI_GETWORKAREA = 0x0030;
        public const uint MONITOR_DEFAULTTONEAREST = 2;
        public const uint SWP_NOMOVE = 0x0002;
        public const uint SWP_NOZORDER = 0x0004;
        public const uint SWP_NOACTIVATE = 0x0010;
        public const uint WM_CLOSE = 0x0010;
        public const uint PW_RENDERFULLCONTENT = 2;

        public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
        public delegate bool EnumDesktopsProc(string lpszDesktop, IntPtr lParam);

        [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr ctx);
        [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
        [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern IntPtr GetWindow(IntPtr hWnd, uint cmd);
        [DllImport("user32.dll", SetLastError=true)] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
        [DllImport("user32.dll", SetLastError=true)] public static extern bool GetClientRect(IntPtr hWnd, out RECT r);
        [DllImport("user32.dll", SetLastError=true)] public static extern bool ClientToScreen(IntPtr hWnd, ref POINT p);
        [DllImport("user32.dll")] public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, out RECT pvParam, uint fWinIni);
        [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
        [DllImport("user32.dll")] public static extern IntPtr MonitorFromWindow(IntPtr hWnd, uint flags);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern bool GetMonitorInfo(IntPtr hMon, ref MONITORINFOEX mi);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowText(IntPtr hWnd, StringBuilder sb, int max);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassName(IntPtr hWnd, StringBuilder sb, int max);
        [DllImport("user32.dll")] public static extern IntPtr PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
        [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdc, uint flags);

        [DllImport("user32.dll")] public static extern IntPtr GetProcessWindowStation();
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr OpenDesktop(string lpszDesktop, uint dwFlags, bool fInherit, uint dwDesiredAccess);
        [DllImport("user32.dll")] public static extern bool CloseDesktop(IntPtr hDesktop);
        [DllImport("user32.dll")] public static extern bool SetThreadDesktop(IntPtr hDesktop);
        [DllImport("user32.dll")] public static extern bool EnumDesktopWindows(IntPtr hDesktop, EnumWindowsProc lpfn, IntPtr lParam);
        [DllImport("user32.dll")] public static extern bool EnumDesktops(IntPtr hwinsta, EnumDesktopsProc lpEnumCallback, IntPtr lParam);

        public static WindowMatch FindTargetWindow(uint targetPid, string targetTitle)
        {
            WindowMatch match = null;
            IntPtr hWinsta = GetProcessWindowStation();
            EnumDesktops(hWinsta, (deskName, lParam) => {
                IntPtr d = OpenDesktop(deskName, 0, false, 0x01FF);
                if (d != IntPtr.Zero) {
                    EnumDesktopWindows(d, (h, l) => {
                        uint p;
                        GetWindowThreadProcessId(h, out p);
                        if (p == targetPid && IsWindowVisible(h)) {
                            var sbClass = new StringBuilder(256);
                            GetClassName(h, sbClass, 256);
                            var sbTitle = new StringBuilder(256);
                            GetWindowText(h, sbTitle, 256);
                            string cls = sbClass.ToString();
                            string tit = sbTitle.ToString();
                            if (cls == "Zed::Window" || (!string.IsNullOrEmpty(targetTitle) && tit == targetTitle)) {
                                match = new WindowMatch { Hwnd = h, Desktop = deskName, Title = tit, ClassName = cls };
                                return false;
                            }
                        }
                        return true;
                    }, IntPtr.Zero);
                    CloseDesktop(d);
                }
                return match == null;
            }, IntPtr.Zero);
            return match;
        }

        public static MeasureResult ExecuteOperation(WindowMatch win, string action, int x, int y, int width, int height, string capturePath)
        {
            MeasureResult result = new MeasureResult
            {
                Hwnd = string.Format("0x{0:X}", win.Hwnd.ToInt64()),
                Desktop = win.Desktop,
                Title = win.Title,
                ClassName = win.ClassName,
                CapturePath = capturePath
            };

            Thread t = new Thread(() => {
                IntPtr d = OpenDesktop(win.Desktop, 0, false, 0x01FF);
                if (d != IntPtr.Zero) {
                    SetThreadDesktop(d);
                }
                SetThreadDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);

                if (action == "Close") {
                    PostMessage(win.Hwnd, WM_CLOSE, IntPtr.Zero, IntPtr.Zero);
                    if (d != IntPtr.Zero) CloseDesktop(d);
                    return;
                }

                if (action == "Resize") {
                    uint flags = (x != -10000 && y != -10000)
                        ? (SWP_NOZORDER | SWP_NOACTIVATE)
                        : (SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
                    SetWindowPos(win.Hwnd, IntPtr.Zero, x != -10000 ? x : 0, y != -10000 ? y : 0, width, height, flags);
                    Thread.Sleep(400);
                }

                RECT rSpi;
                SystemParametersInfo(SPI_GETWORKAREA, 0, out rSpi, 0);
                result.WorkAreaSPI = rSpi;

                var mi = new MONITORINFOEX();
                mi.cbSize = Marshal.SizeOf(typeof(MONITORINFOEX));
                IntPtr hMon = MonitorFromWindow(win.Hwnd, MONITOR_DEFAULTTONEAREST);
                GetMonitorInfo(hMon, ref mi);
                result.WorkAreaMonitor = mi.rcWork;
                result.MonitorDevice = mi.szDevice;

                RECT wr;
                GetWindowRect(win.Hwnd, out wr);
                result.WindowRect = wr;

                RECT cr;
                GetClientRect(win.Hwnd, out cr);
                result.ClientRect = cr;

                POINT pt = new POINT { X = 0, Y = 0 };
                ClientToScreen(win.Hwnd, ref pt);
                result.ClientOrigin = pt;

                if (!string.IsNullOrEmpty(capturePath)) {
                    int w = wr.Right - wr.Left;
                    int h = wr.Bottom - wr.Top;
                    if (w > 0 && h > 0) {
                        using (var bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb)) {
                            using (var g = Graphics.FromImage(bmp)) {
                                IntPtr hdc = g.GetHdc();
                                try {
                                    result.CaptureOk = PrintWindow(win.Hwnd, hdc, PW_RENDERFULLCONTENT);
                                } finally {
                                    g.ReleaseHdc(hdc);
                                }
                            }
                            string dir = System.IO.Path.GetDirectoryName(capturePath);
                            if (!string.IsNullOrEmpty(dir) && !System.IO.Directory.Exists(dir)) {
                                System.IO.Directory.CreateDirectory(dir);
                            }
                            bmp.Save(capturePath, ImageFormat.Png);
                        }
                    }
                }

                if (d != IntPtr.Zero) {
                    CloseDesktop(d);
                }
            });

            t.Start();
            t.Join();
            return result;
        }
    }
}
'@
}

# 1. 대상 창 찾기
$match = $null
if ($TargetHwnd) {
    $val = if ($TargetHwnd -match '^0[xX]') { [Convert]::ToInt64($TargetHwnd.Substring(2), 16) } else { [int64]$TargetHwnd }
    $h = [IntPtr]$val
    # Need to find which desktop it is on
    $hWinsta = [WgMeasureWin.Engine]::GetProcessWindowStation()
    [WgMeasureWin.Engine]::EnumDesktops($hWinsta, {
        param($deskName, $lParam)
        $d = [WgMeasureWin.Engine]::OpenDesktop($deskName, 0, $false, 0x01FF)
        if ($d -ne [IntPtr]::Zero) {
            [WgMeasureWin.Engine]::EnumDesktopWindows($d, {
                param($w, $l)
                if ($w -eq $h) {
                    $script:match = [WgMeasureWin.WindowMatch]@{ Hwnd = $w; Desktop = $deskName; Title = ''; ClassName = $ProcessName }
                    return $false
                }
                return $true
            }, [IntPtr]::Zero) | Out-Null
            [WgMeasureWin.Engine]::CloseDesktop($d) | Out-Null
        }
        return ($script:match -eq $null)
    }, [IntPtr]::Zero) | Out-Null
} else {
    $processes = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
    if ($processes.Count -eq 0) { throw "Process '$ProcessName' not found." }
    foreach ($proc in $processes) {
        $m = [WgMeasureWin.Engine]::FindTargetWindow([uint32]$proc.Id, $ProcessName)
        if ($m -ne $null) {
            $match = $m
            break
        }
    }
}

if (-not $match -and $script:match) { $match = $script:match }

if (-not $match) {
    throw "Target window for '$ProcessName' not found on any desktop in WinSta0."
}

# 2. 실행
$captureFullPath = if ($Capture) { [System.IO.Path]::GetFullPath($Capture, (Get-Location).Path) } else { $null }
$res = [WgMeasureWin.Engine]::ExecuteOperation($match, $Action, $X, $Y, $Width, $Height, $captureFullPath)

if ($Action -eq 'Close') {
    $closeObj = [ordered]@{ action = 'Close'; hwnd = $res.Hwnd; desktop = $res.Desktop }
    if ($Out) { $closeObj | ConvertTo-Json | Set-Content -LiteralPath $Out -Encoding utf8 }
    return ($closeObj | ConvertTo-Json)
}

# 3. 좌표 및 중심점 계산
$workArea = $res.WorkAreaMonitor
$win = $res.WindowRect
$client = $res.ClientRect
$pt = $res.ClientOrigin

$clientScreen = [ordered]@{
    left   = $pt.X
    top    = $pt.Y
    right  = $pt.X + $client.Width
    bottom = $pt.Y + $client.Height
    width  = $client.Width
    height = $client.Height
}

$workCenter = [ordered]@{
    x = $workArea.Left + ($workArea.Width / 2.0)
    y = $workArea.Top + ($workArea.Height / 2.0)
}

$windowCenter = [ordered]@{
    x = $win.Left + ($win.Width / 2.0)
    y = $win.Top + ($win.Height / 2.0)
}

$clientCenter = [ordered]@{
    x = $clientScreen.left + ($clientScreen.width / 2.0)
    y = $clientScreen.top + ($clientScreen.height / 2.0)
}

$report = [ordered]@{
    hwnd = $res.Hwnd
    desktop = $res.Desktop
    title = $res.Title
    className = $res.ClassName
    workArea_SPI = [ordered]@{
        left   = $res.WorkAreaSPI.Left
        top    = $res.WorkAreaSPI.Top
        right  = $res.WorkAreaSPI.Right
        bottom = $res.WorkAreaSPI.Bottom
        width  = $res.WorkAreaSPI.Width
        height = $res.WorkAreaSPI.Height
    }
    workArea_Monitor = [ordered]@{
        device = $res.MonitorDevice
        left   = $workArea.Left
        top    = $workArea.Top
        right  = $workArea.Right
        bottom = $workArea.Bottom
        width  = $workArea.Width
        height = $workArea.Height
    }
    workAreaCenter = $workCenter
    windowRect = [ordered]@{
        left   = $win.Left
        top    = $win.Top
        right  = $win.Right
        bottom = $win.Bottom
        width  = $win.Width
        height = $win.Height
    }
    windowCenter = $windowCenter
    windowCenterDiff = [ordered]@{
        dx = $windowCenter.x - $workCenter.x
        dy = $windowCenter.y - $workCenter.y
    }
    clientRect = [ordered]@{
        width  = $client.Width
        height = $client.Height
    }
    clientToScreen = [ordered]@{
        x = $pt.X
        y = $pt.Y
    }
    clientScreenRect = $clientScreen
    clientCenter = $clientCenter
    clientCenterDiff = [ordered]@{
        dx = $clientCenter.x - $workCenter.x
        dy = $clientCenter.y - $workCenter.y
    }
    capture = [ordered]@{
        ok   = $res.CaptureOk
        path = $res.CapturePath
    }
}

if ($Out) {
    $outDir = Split-Path $Out -Parent
    if ($outDir -and -not (Test-Path -LiteralPath $outDir)) {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }
    $report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $Out -Encoding utf8
}

$report | ConvertTo-Json -Depth 6

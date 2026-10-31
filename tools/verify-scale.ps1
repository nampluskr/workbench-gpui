#Requires -Version 7
<#
.SYNOPSIS
  현재 디스플레이 배율에서 SPEC R-4 (와 150% 때 R-5) 증거를 모은다.

.DESCRIPTION
  배율은 바꾸지 않는다. 먼저 tools/set-scale.ps1 -Percent <n> 으로 배율을 바꾼 뒤 실행한다.
  현재 배율(set-scale.ps1 -Get)이 -Percent 와 다르면 오류로 끝낸다.

  1) 앱(target\debug\workbench-gpui.exe)을 새로 띄우고 PID·HWND 를 고정한다.
     이미 실행 중인 workbench-gpui 가 있으면 오류로 끝낸다(다른 프로세스는 건드리지 않는다).
  2) capture.ps1 -Hwnd 로 창·DPI·스크린샷을 specs/v0.1/verify/phase1/scale-<n>/ 에 저장한다.
  3) 타이틀 바 높이를 픽셀로 잰다. 타이틀 바는 본문과 배경색이 같아서 경계를 찾을 수 없으므로,
     닫기 버튼에 마우스를 올려 hover 배경(#E81120, L-84)을 띄우고 그 빨간 영역의 세로 길이를 잰다.
     창 버튼은 타이틀 바 전체 높이를 차지하므로(L-39 36×32, L-21 32) 세로 길이 = 타이틀 바 높이다.
     가로 길이(닫기 버튼 폭)도 함께 잰다. 물리 px 와 논리 px(= 물리 / 배율)를 result.json 에 적는다.
     앱이 표준출력에 `[dev] layout ...` 줄을 내면 그것도 함께 적는다(현재 앱에는 그런 플래그가 없어 null).
  4) 창 버튼 영역을 확대한 PNG(최근접 보간)를 저장한다: buttons-zoom.png(평소), buttons-hover-zoom.png(닫기 hover).
  5) -Percent 150 이면 tools/verify-r5.ps1 을 scale-150/ 에 실행한다(TaskDialog, 긴 경로).
  끝나면 띄운 앱을 종료한다. 실패가 있으면 종료 코드 1 이다.

.PARAMETER Percent
  지금 설정되어 있어야 하는 배율 (예: 100, 150, 200).

.EXAMPLE
  pwsh -NoProfile -File tools/verify-scale.ps1 -Percent 150
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateSet(100, 125, 150, 175, 200)][int]$Percent,
    [string]$Exe = 'target\debug\workbench-gpui.exe',
    [string]$OutRoot = 'specs\v0.1\verify\phase1'
)

$ErrorActionPreference = 'Stop'
$ProcessName = 'workbench-gpui'
$AppTitle = 'workbench-gpui'
$CaptureScript = Join-Path $PSScriptRoot 'capture.ps1'
$ScaleScript = Join-Path $PSScriptRoot 'set-scale.ps1'
$R5Script = Join-Path $PSScriptRoot 'verify-r5.ps1'

Add-Type -AssemblyName System.Drawing.Common
Add-Type -AssemblyName System.Drawing.Primitives

if (-not ('WgScaleVerify.Native' -as [type])) {
    $refs = @(
        'System.Runtime'
        'System.Collections'
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
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

namespace WgScaleVerify
{
    [StructLayout(LayoutKind.Sequential)]
    public struct MOUSEINPUT { public int dx; public int dy; public uint mouseData; public uint dwFlags; public uint time; public IntPtr dwExtraInfo; }

    [StructLayout(LayoutKind.Sequential)]
    public struct INPUT { public uint type; public MOUSEINPUT mi; }

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }

    [StructLayout(LayoutKind.Sequential)]
    public struct POINT { public int X, Y; }

    public static class Native
    {
        public static readonly IntPtr DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = new IntPtr(-4);
        const uint MOUSEEVENTF_MOVE = 0x0001, MOUSEEVENTF_VIRTUALDESK = 0x4000, MOUSEEVENTF_ABSOLUTE = 0x8000;
        const int SM_XVIRTUALSCREEN = 76, SM_YVIRTUALSCREEN = 77, SM_CXVIRTUALSCREEN = 78, SM_CYVIRTUALSCREEN = 79;
        public const int SW_RESTORE = 9;
        const uint SWP_NOZORDER = 0x0004, SWP_NOACTIVATE = 0x0010;
        const uint GA_ROOT = 2;

        public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

        [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr ctx);
        [DllImport("user32.dll", SetLastError = true)] static extern uint SendInput(uint n, INPUT[] inputs, int size);
        [DllImport("user32.dll")] static extern int GetSystemMetrics(int index);
        [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int cmd);
        [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr hWnd, IntPtr after, int x, int y, int cx, int cy, uint flags);
        [DllImport("user32.dll")] static extern IntPtr WindowFromPoint(POINT p);
        [DllImport("user32.dll")] static extern IntPtr GetAncestor(IntPtr hWnd, uint flags);
        [DllImport("user32.dll")] static extern bool EnumWindows(EnumWindowsProc cb, IntPtr lParam);
        [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
        [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr hWnd);
        [DllImport("user32.dll")] static extern IntPtr GetWindow(IntPtr hWnd, uint cmd);
        [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr hWnd, StringBuilder sb, int max);

        public static string Title(IntPtr h)
        {
            var sb = new StringBuilder(512);
            GetWindowText(h, sb, sb.Capacity);
            return sb.ToString();
        }

        // 프로세스의 보이는 소유자 없는 최상위 창 중 제목이 title 인 가장 큰 창.
        public static IntPtr FindTitled(uint pid, string title)
        {
            IntPtr best = IntPtr.Zero; long bestArea = 0;
            EnumWindows((h, l) =>
            {
                uint p;
                GetWindowThreadProcessId(h, out p);
                if (p != pid || !IsWindowVisible(h) || GetWindow(h, 4) != IntPtr.Zero) return true;
                if (Title(h) != title) return true;
                RECT r; GetWindowRect(h, out r);
                long area = (long)(r.Right - r.Left) * (r.Bottom - r.Top);
                if (area > bestArea) { bestArea = area; best = h; }
                return true;
            }, IntPtr.Zero);
            return best;
        }

        public static IntPtr RootAt(int x, int y)
        {
            var h = WindowFromPoint(new POINT { X = x, Y = y });
            return h == IntPtr.Zero ? IntPtr.Zero : GetAncestor(h, GA_ROOT);
        }

        public static void MoveTo(int x, int y)
        {
            int vx = GetSystemMetrics(SM_XVIRTUALSCREEN), vy = GetSystemMetrics(SM_YVIRTUALSCREEN);
            int vw = GetSystemMetrics(SM_CXVIRTUALSCREEN), vh = GetSystemMetrics(SM_CYVIRTUALSCREEN);
            var input = new INPUT { type = 0 };
            input.mi.dx = (int)Math.Round((x - vx) * 65535.0 / Math.Max(1, vw - 1));
            input.mi.dy = (int)Math.Round((y - vy) * 65535.0 / Math.Max(1, vh - 1));
            input.mi.dwFlags = MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_VIRTUALDESK;
            if (SendInput(1, new[] { input }, Marshal.SizeOf(typeof(INPUT))) != 1)
                throw new InvalidOperationException("SendInput failed: " + Marshal.GetLastWin32Error());
        }

        public static void Glide(int x0, int y0, int x1, int y1, int steps, int stepMs)
        {
            for (int i = 0; i <= steps; i++)
            {
                MoveTo(x0 + (x1 - x0) * i / steps, y0 + (y1 - y0) * i / steps);
                Thread.Sleep(stepMs);
            }
        }

        public static void Place(IntPtr hWnd, int x, int y, int w, int h)
        {
            SetWindowPos(hWnd, IntPtr.Zero, x, y, w, h, SWP_NOZORDER | SWP_NOACTIVATE);
        }

        static bool Near(Color c, int rgb, int tol)
        {
            return Math.Abs(c.R - ((rgb >> 16) & 0xFF)) <= tol
                && Math.Abs(c.G - ((rgb >> 8) & 0xFF)) <= tol
                && Math.Abs(c.B - (rgb & 0xFF)) <= tol;
        }

        // 세로 열 x 에서 y0 부터 아래로 색 rgb(±tol) 가 이어지는 구간을 찾는다.
        // 결과: [첫 행, 길이]. 찾지 못하면 [-1, 0].
        public static int[] VerticalRun(string path, int x, int y0, int rgb, int tol)
        {
            using (var bmp = new Bitmap(path))
            {
                if (x < 0 || x >= bmp.Width) return new[] { -1, 0 };
                int start = -1;
                for (int y = Math.Max(0, y0); y < bmp.Height; y++)
                {
                    bool hit = Near(bmp.GetPixel(x, y), rgb, tol);
                    if (start < 0 && hit) start = y;
                    else if (start >= 0 && !hit) return new[] { start, y - start };
                }
                return start < 0 ? new[] { -1, 0 } : new[] { start, bmp.Height - start };
            }
        }

        // 가로 행 y 에서 x0 부터 왼쪽으로 색 rgb(±tol) 가 이어지는 구간을 찾는다.
        // 결과: [왼쪽 끝 열, 길이]. 찾지 못하면 [-1, 0].
        public static int[] HorizontalRunLeft(string path, int x0, int y, int rgb, int tol)
        {
            using (var bmp = new Bitmap(path))
            {
                if (y < 0 || y >= bmp.Height) return new[] { -1, 0 };
                int end = -1;
                for (int x = Math.Min(bmp.Width - 1, x0); x >= 0; x--)
                {
                    bool hit = Near(bmp.GetPixel(x, y), rgb, tol);
                    if (end < 0 && hit) end = x;
                    else if (end >= 0 && !hit) return new[] { x + 1, end - x };
                }
                return end < 0 ? new[] { -1, 0 } : new[] { 0, end + 1 };
            }
        }

        public static string Pixel(string path, int x, int y)
        {
            using (var bmp = new Bitmap(path))
            {
                if (x < 0 || y < 0 || x >= bmp.Width || y >= bmp.Height) return null;
                var c = bmp.GetPixel(x, y);
                return string.Format("#{0:X2}{1:X2}{2:X2}", c.R, c.G, c.B);
            }
        }

        // src 의 사각형을 factor 배 최근접 보간으로 키워 dst 에 저장한다.
        public static void Zoom(string src, int x, int y, int w, int h, int factor, string dst)
        {
            using (var bmp = new Bitmap(src))
            {
                var r = new Rectangle(x, y, w, h);
                r.Intersect(new Rectangle(0, 0, bmp.Width, bmp.Height));
                using (var outBmp = new Bitmap(r.Width * factor, r.Height * factor, PixelFormat.Format32bppArgb))
                using (var g = Graphics.FromImage(outBmp))
                {
                    g.InterpolationMode = InterpolationMode.NearestNeighbor;
                    g.PixelOffsetMode = PixelOffsetMode.Half;
                    g.DrawImage(bmp, new Rectangle(0, 0, outBmp.Width, outBmp.Height), r, GraphicsUnit.Pixel);
                    outBmp.Save(dst, ImageFormat.Png);
                }
            }
        }
    }
}
'@
}

$outDir = [System.IO.Path]::GetFullPath((Join-Path $OutRoot "scale-$Percent"), (Get-Location).Path)
if (-not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

$result = [ordered]@{
    percent    = $Percent
    startedAt  = (Get-Date).ToString('o')
    scale      = $null
    pid        = $null
    hwnd       = $null
    window     = $null
    titleBar   = $null
    closeButton = $null
    devLayout  = $null
    zoom       = $null
    r5         = $null
    errors     = @()
}

$script:hwnd = [IntPtr]::Zero
$script:appPid = 0

function Invoke-Capture([string]$Name) {
    $png = Join-Path $outDir "$Name.png"
    $jsonPath = Join-Path $outDir "$Name.json"
    $expected = '0x{0:X}' -f $script:hwnd.ToInt64()
    $raw = & pwsh -NoProfile -File $CaptureScript -Hwnd $expected -Out $png -Method PrintWindow
    $code = $LASTEXITCODE
    $text = ($raw | Out-String)
    Set-Content -LiteralPath $jsonPath -Value $text -Encoding utf8
    $obj = $text | ConvertFrom-Json
    if ($obj.hwnd -ne $expected -or $obj.pid -ne $script:appPid) {
        throw "capture ${Name}: 캡처한 창(hwnd=$($obj.hwnd), pid=$($obj.pid))이 고정한 창(hwnd=$expected, pid=$($script:appPid))과 다르다"
    }
    if ($code -ne 0 -or -not $obj.capture.ok) { throw "capture $Name 실패: $($obj.capture.error)" }
    $obj | Add-Member -NotePropertyName png -NotePropertyValue $png -Force
    return $obj
}

function Assert-Target([int]$X, [int]$Y, [string]$What) {
    if ([WgScaleVerify.Native]::GetForegroundWindow() -ne $script:hwnd) {
        [void][WgScaleVerify.Native]::SetForegroundWindow($script:hwnd)
        Start-Sleep -Milliseconds 300
    }
    if ([WgScaleVerify.Native]::GetForegroundWindow() -ne $script:hwnd) {
        throw "${What}: 대상 창을 전면으로 가져오지 못했다. 입력을 보내지 않고 중단한다"
    }
    $root = [WgScaleVerify.Native]::RootAt($X, $Y)
    if ($root -ne $script:hwnd) {
        throw ("{0}: 커서 위치 ({1},{2}) 아래 창(0x{3:X})이 대상 창(0x{4:X})이 아니다. 입력을 보내지 않고 중단한다" -f $What, $X, $Y, $root.ToInt64(), $script:hwnd.ToInt64())
    }
}

function Wait-Until([scriptblock]$Condition, [int]$TimeoutMs) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.ElapsedMilliseconds -lt $TimeoutMs) {
        if (& $Condition) { return $true }
        Start-Sleep -Milliseconds 100
    }
    return $false
}

$prev = [WgScaleVerify.Native]::SetThreadDpiAwarenessContext([WgScaleVerify.Native]::DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)
if ($prev -eq [IntPtr]::Zero) { throw 'SetThreadDpiAwarenessContext(PER_MONITOR_AWARE_V2) 실패' }

$launched = $null
$stdoutPath = Join-Path $outDir 'app-stdout.txt'
try {
    # 0) 현재 배율 확인
    $rawScale = & pwsh -NoProfile -File $ScaleScript -Get
    if ($LASTEXITCODE -ne 0) { throw "현재 배율을 읽지 못했다: $($rawScale | Out-String)" }
    $result.scale = ($rawScale | Out-String) | ConvertFrom-Json
    if ($result.scale.current -ne $Percent) {
        throw "현재 배율이 $($result.scale.current)% 다. 먼저 set-scale.ps1 -Percent $Percent 로 바꾼 뒤 실행하라"
    }

    # 1) 앱 실행, PID·HWND 고정
    $existing = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
    if ($existing.Count -gt 0) {
        throw "이미 실행 중인 $ProcessName 가 있다 (PID $($existing.Id -join ', ')). 닫고 다시 실행하라"
    }
    $exePath = (Resolve-Path -LiteralPath $Exe).Path
    $launched = Start-Process -FilePath $exePath -PassThru -RedirectStandardOutput $stdoutPath
    $script:appPid = $launched.Id
    $result.pid = $script:appPid
    if (-not (Wait-Until { [WgScaleVerify.Native]::FindTitled([uint32]$script:appPid, $AppTitle) -ne [IntPtr]::Zero } 20000)) {
        throw '앱 창이 20초 안에 뜨지 않았다'
    }
    Start-Sleep -Milliseconds 1500
    $script:hwnd = [WgScaleVerify.Native]::FindTitled([uint32]$script:appPid, $AppTitle)
    if ($script:hwnd -eq [IntPtr]::Zero) { throw '앱 메인 창을 찾지 못했다' }
    $result.hwnd = '0x{0:X}' -f $script:hwnd.ToInt64()

    [void][WgScaleVerify.Native]::ShowWindow($script:hwnd, [WgScaleVerify.Native]::SW_RESTORE)
    [void][WgScaleVerify.Native]::SetForegroundWindow($script:hwnd)
    Start-Sleep -Milliseconds 500
    $setup = Invoke-Capture 'setup'
    $w = $setup.monitor.workRect
    [WgScaleVerify.Native]::Place($script:hwnd, [int]($w.x + $w.width * 0.15), [int]($w.y + $w.height * 0.15), [int]($w.width * 0.6), [int]($w.height * 0.6))
    Start-Sleep -Milliseconds 800

    # 2) 창·DPI·스크린샷
    $win = Invoke-Capture 'window'
    $s = [double]$win.scale
    $result.window = [ordered]@{
        dpi = $win.dpi
        scale = $win.scale
        dpiMatchesPercent = ($win.dpi -eq [int]($Percent * 96 / 100))
        rect = $win.rect
        clientRect = $win.clientRect
        maximized = $win.maximized
        screenshot = $win.png
    }

    # PNG 안에서 클라이언트 영역의 원점(PNG 는 rect = DWM 프레임 경계 기준)
    $cx0 = $win.clientRect.x - $win.rect.x
    $cy0 = $win.clientRect.y - $win.rect.y
    $cw = $win.clientRect.width

    # 4a) 창 버튼 영역 확대 (평소). 버튼 셋 = 3 × 36 논리 px, 높이 32 논리 px (L-39).
    $btnW = [int][math]::Ceiling(3 * 36 * $s); $btnH = [int][math]::Ceiling(32 * $s)
    $zoomFactor = [math]::Max(2, [int][math]::Round(8 / $s))
    $zoomNormal = Join-Path $outDir 'buttons-zoom.png'
    [WgScaleVerify.Native]::Zoom($win.png, $cx0 + $cw - $btnW - [int](4 * $s), $cy0, $btnW + [int](4 * $s), $btnH + [int](4 * $s), $zoomFactor, $zoomNormal)

    # 3) 닫기 버튼 hover → 빨간 영역의 세로·가로 길이
    $closeX = [int]($win.clientRect.x + $win.clientRect.width - 18 * $s)
    $barY = [int]($win.clientRect.y + 16 * $s)
    $startX = $closeX - [int](120 * $s); $startY = $barY + [int](120 * $s)
    Assert-Target $startX $startY '닫기 hover 시작점'
    Assert-Target $closeX $barY '닫기 버튼 hover'
    [WgScaleVerify.Native]::Glide($startX, $startY, $closeX, $barY, 20, 15)
    Start-Sleep -Milliseconds 800
    $hover = Invoke-Capture 'close-hover'
    $hx0 = $hover.clientRect.x - $hover.rect.x
    $hy0 = $hover.clientRect.y - $hover.rect.y
    $hcw = $hover.clientRect.width
    # 세로: 버튼 왼쪽 끝에서 안쪽 4 논리 px 열(글리프를 피한다), 클라이언트 맨 위부터.
    $colX = $hx0 + $hcw - [int](36 * $s) + [int](4 * $s)
    $v = [WgScaleVerify.Native]::VerticalRun($hover.png, $colX, $hy0, 0xE81120, 8)
    # 가로: 클라이언트 위에서 4 논리 px 행, 클라이언트 오른쪽 끝부터 왼쪽으로.
    $rowY = $hy0 + [int](4 * $s)
    $h = [WgScaleVerify.Native]::HorizontalRunLeft($hover.png, $hx0 + $hcw - 1, $rowY, 0xE81120, 8)
    $result.titleBar = [ordered]@{
        method = 'close-hover-red-run (L-84 #E81120, tol 8)'
        column = $colX
        startRowFromClientTop = if ($v[0] -ge 0) { $v[0] - $hy0 } else { $null }
        heightPhysical = $v[1]
        heightLogical = [math]::Round($v[1] / $s, 2)
        expectedLogical = 32
        sampleColor = [WgScaleVerify.Native]::Pixel($hover.png, $colX, $hy0 + [int](2 * $s))
    }
    $result.closeButton = [ordered]@{
        row = $rowY
        widthPhysical = $h[1]
        widthLogical = [math]::Round($h[1] / $s, 2)
        expectedLogical = 36
        rightGapPhysical = if ($h[0] -ge 0) { ($hx0 + $hcw) - ($h[0] + $h[1]) } else { $null }
    }
    if ($v[1] -eq 0) { $result.errors += '타이틀 바 높이: 닫기 hover 빨간 영역을 찾지 못했다' }

    # 4b) 창 버튼 영역 확대 (닫기 hover)
    $zoomHover = Join-Path $outDir 'buttons-hover-zoom.png'
    [WgScaleVerify.Native]::Zoom($hover.png, $hx0 + $hcw - $btnW - [int](4 * $s), $hy0, $btnW + [int](4 * $s), $btnH + [int](4 * $s), $zoomFactor, $zoomHover)
    $result.zoom = [ordered]@{ factor = $zoomFactor; normal = $zoomNormal; closeHover = $zoomHover; interpolation = 'nearest-neighbor' }

    $awayY = $barY + [int](200 * $s)
    Assert-Target $closeX $awayY '커서 치우기'
    [WgScaleVerify.Native]::MoveTo($closeX - [int](200 * $s), $awayY)
}
catch {
    $result.errors += $_.Exception.Message
}
finally {
    [void][WgScaleVerify.Native]::SetThreadDpiAwarenessContext($prev)
    if ($launched) {
        try { [void]$launched.CloseMainWindow(); [void]$launched.WaitForExit(5000) } catch {}
        if (-not $launched.HasExited) { try { $launched.Kill(); [void]$launched.WaitForExit(3000) } catch {} }
    }
}

# 앱이 [dev] layout 줄을 냈으면 함께 적는다 (현재 앱에는 이 출력이 없다).
if (Test-Path -LiteralPath $stdoutPath) {
    $lines = @(Select-String -LiteralPath $stdoutPath -Pattern '^\[dev\] layout' | ForEach-Object { $_.Line })
    $result.devLayout = if ($lines.Count -gt 0) { $lines } else { $null }
}

# 5) 150% 이면 R-5 시험 (앱을 닫은 뒤 실행한다)
if ($Percent -eq 150 -and $result.errors.Count -eq 0) {
    $rawR5 = & pwsh -NoProfile -File $R5Script -Exe $Exe -OutDir $outDir
    $result.r5 = [ordered]@{
        exitCode = $LASTEXITCODE
        output = ($rawR5 | Out-String)
        files = @('r5-taskdialog.txt', 'r5-taskdialog.png', 'r5-longpath.txt')
    }
    if ($LASTEXITCODE -ne 0) { $result.errors += "verify-r5.ps1 종료 코드 $LASTEXITCODE" }
}

$result.finishedAt = (Get-Date).ToString('o')
$resultPath = Join-Path $outDir 'result.json'
$result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $resultPath -Encoding utf8
Get-Content -LiteralPath $resultPath -Raw
if ($result.errors.Count -gt 0) { exit 1 }

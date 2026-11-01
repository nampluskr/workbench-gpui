#Requires -Version 7
<#
.SYNOPSIS
  PLAN Phase 3 (SPEC R-12~R-15) 증거를 specs/v0.1/verify/phase3/ 에 모은다.

.DESCRIPTION
  앱을 `--dev-layout` 으로 새로 띄워 PID·HWND 를 고정한다(이미 실행 중인 workbench-gpui 가 있으면 오류로 끝낸다).
  앱은 레이아웃이 바뀔 때마다 이름별 바깥 상자(테두리 포함, 창 기준 논리 px)와 rem·Dock 폭을 표준출력에 낸다.

    1 창을 최대화한다. 배율 200% 에서 창 내용이 기준 화면과 같은 1440×852 논리 px 가 된다(A-30.2).
      스크린샷(layout.png) + 레이아웃 스냅숏(layout-boxes.json).
    2 R-12 배치 확인값, R-13 A-32 ID 별 측정값과 통과/실패(a32.json).
    3 R-14 끌기(SendInput): 왼쪽 Dock 핸들 +100 → 왼쪽 끝 너머 → 오른쪽 끝 너머 → 더블클릭, 사이드바 경계 +100 → 800 너머 → 200 아래.
      각 단계 뒤 스냅숏의 폭(r14.json, r14-*.png).
    4 R-15 창 rem 값과, metrics.rs 의 R-13 치수 상수가 rem 헬퍼로 정의되었는지(r15.json).
  입력 직전마다 대상 창이 전면이고 커서 아래 루트 창이 대상 창인지 확인한다. 끝나면 띄운 앱을 닫는다.

  참·거짓 판정은 허용 오차 0 의 CheckBool 로 하고, 시작할 때 CheckBool 자체 시험을 돌린다(실패하면 앱을 띄우지 않는다).

.PARAMETER SelfTest
  CheckBool 자체 시험만 돌리고 결과(JSON)를 낸 뒤 끝낸다. 앱을 띄우지 않는다.

.EXAMPLE
  pwsh -NoProfile -File tools/verify-phase3.ps1
.EXAMPLE
  pwsh -NoProfile -File tools/verify-phase3.ps1 -SelfTest
#>
[CmdletBinding()]
param(
    [string]$Exe = 'target\debug\workbench-gpui.exe',
    [string]$OutDir = 'specs\v0.1\verify\phase3',
    [switch]$SelfTest
)

$ErrorActionPreference = 'Stop'
$ProcessName = 'workbench-gpui'
$AppTitle = 'workbench-gpui'
$CaptureScript = Join-Path $PSScriptRoot 'capture.ps1'
$MetricsFile = Join-Path $PSScriptRoot '..\src\ui\metrics.rs'

if (-not ('WgPhase3.Native' -as [type])) {
    Add-Type -ReferencedAssemblies 'System.Runtime', 'System.Collections', 'System.Threading', 'System.Threading.Thread', 'System.Runtime.InteropServices' -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

namespace WgPhase3
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
        const uint MOUSEEVENTF_MOVE = 0x0001, MOUSEEVENTF_LEFTDOWN = 0x0002, MOUSEEVENTF_LEFTUP = 0x0004;
        const uint MOUSEEVENTF_VIRTUALDESK = 0x4000, MOUSEEVENTF_ABSOLUTE = 0x8000;
        const int SM_XVIRTUALSCREEN = 76, SM_YVIRTUALSCREEN = 77, SM_CXVIRTUALSCREEN = 78, SM_CYVIRTUALSCREEN = 79;
        public const int SW_MAXIMIZE = 3, SW_RESTORE = 9;
        [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr hWnd, IntPtr after, int x, int y, int cx, int cy, uint flags);
        public static void Place(IntPtr hWnd, int x, int y, int w, int h) { SetWindowPos(hWnd, IntPtr.Zero, x, y, w, h, 0x0004 /* SWP_NOZORDER */); }
        public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

        [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr ctx);
        [DllImport("user32.dll", SetLastError = true)] static extern uint SendInput(uint n, INPUT[] inputs, int size);
        [DllImport("user32.dll")] static extern int GetSystemMetrics(int index);
        [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int cmd);
        [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
        [DllImport("user32.dll")] static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool attach);
        [DllImport("user32.dll")] static extern bool BringWindowToTop(IntPtr hWnd);
        [DllImport("kernel32.dll")] static extern uint GetCurrentThreadId();

        // 전면 전환. 입력을 주입하지 않고, 현재 전면 창의 스레드에 이 스레드의 입력 큐를 잠시 붙여
        // 전경 잠금을 피한다. 성공 여부는 호출 쪽이 GetForegroundWindow 로 다시 확인한다.
        public static void Activate(IntPtr hWnd)
        {
            IntPtr fg = GetForegroundWindow();
            uint dummy;
            uint fgThread = fg == IntPtr.Zero ? 0 : GetWindowThreadProcessId(fg, out dummy);
            uint me = GetCurrentThreadId();
            bool attached = fgThread != 0 && fgThread != me && AttachThreadInput(me, fgThread, true);
            try { BringWindowToTop(hWnd); SetForegroundWindow(hWnd); }
            finally { if (attached) AttachThreadInput(me, fgThread, false); }
        }
        [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")] static extern IntPtr WindowFromPoint(POINT p);
        [DllImport("user32.dll")] static extern IntPtr GetAncestor(IntPtr hWnd, uint flags);
        [DllImport("user32.dll")] public static extern uint GetDoubleClickTime();
        [DllImport("user32.dll")] static extern bool EnumWindows(EnumWindowsProc cb, IntPtr lParam);
        [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
        [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr hWnd);
        [DllImport("user32.dll")] static extern IntPtr GetWindow(IntPtr hWnd, uint cmd);
        [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr hWnd, StringBuilder sb, int max);

        public static string Title(IntPtr h) { var sb = new StringBuilder(512); GetWindowText(h, sb, sb.Capacity); return sb.ToString(); }

        public static IntPtr FindTitled(uint pid, string title)
        {
            IntPtr best = IntPtr.Zero; long bestArea = 0;
            EnumWindows((h, l) =>
            {
                uint p; GetWindowThreadProcessId(h, out p);
                if (p != pid || !IsWindowVisible(h) || GetWindow(h, 4) != IntPtr.Zero || Title(h) != title) return true;
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
            return h == IntPtr.Zero ? IntPtr.Zero : GetAncestor(h, 2);
        }

        static void Send(uint flags, int x, int y)
        {
            int vx = GetSystemMetrics(SM_XVIRTUALSCREEN), vy = GetSystemMetrics(SM_YVIRTUALSCREEN);
            int vw = GetSystemMetrics(SM_CXVIRTUALSCREEN), vh = GetSystemMetrics(SM_CYVIRTUALSCREEN);
            var input = new INPUT { type = 0 };
            input.mi.dx = (int)Math.Round((x - vx) * 65535.0 / Math.Max(1, vw - 1));
            input.mi.dy = (int)Math.Round((y - vy) * 65535.0 / Math.Max(1, vh - 1));
            input.mi.dwFlags = flags | MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_VIRTUALDESK;
            if (SendInput(1, new[] { input }, Marshal.SizeOf(typeof(INPUT))) != 1)
                throw new InvalidOperationException("SendInput failed: " + Marshal.GetLastWin32Error());
        }

        public static void MoveTo(int x, int y) { Send(0, x, y); }

        public static void Drag(int x0, int y0, int x1, int y1, int steps, int stepMs)
        {
            MoveTo(x0, y0); Thread.Sleep(150);
            Send(MOUSEEVENTF_LEFTDOWN, x0, y0); Thread.Sleep(150);
            for (int i = 1; i <= steps; i++)
            {
                MoveTo(x0 + (x1 - x0) * i / steps, y0 + (y1 - y0) * i / steps);
                Thread.Sleep(stepMs);
            }
            Thread.Sleep(150);
            Send(MOUSEEVENTF_LEFTUP, x1, y1);
        }

        public static void DoubleClick(int x, int y)
        {
            MoveTo(x, y); Thread.Sleep(150);
            Send(MOUSEEVENTF_LEFTDOWN, x, y); Thread.Sleep(30); Send(MOUSEEVENTF_LEFTUP, x, y);
            Thread.Sleep(60);
            Send(MOUSEEVENTF_LEFTDOWN, x, y); Thread.Sleep(30); Send(MOUSEEVENTF_LEFTUP, x, y);
        }
    }
}
'@
}

$out = [System.IO.Path]::GetFullPath($OutDir, (Get-Location).Path)
if (-not (Test-Path -LiteralPath $out)) { New-Item -ItemType Directory -Path $out -Force | Out-Null }
$stdout = Join-Path $out 'app-stdout.txt'
$result = [ordered]@{ startedAt = (Get-Date).ToString('o'); pid = $null; hwnd = $null; errors = @() }
$script:hwnd = [IntPtr]::Zero
$script:appPid = 0

# ---------- 스냅숏 읽기 ----------
function Get-Snapshots {
    $lines = @(Get-Content -LiteralPath $stdout -ErrorAction SilentlyContinue)
    $snaps = @{}
    foreach ($l in $lines) {
        if ($l -match '^\[dev\] layout-snapshot seq=(\d+) (.*)$') {
            $snaps[[int]$Matches[1]] = [ordered]@{ seq = [int]$Matches[1]; head = $Matches[2]; boxes = [ordered]@{}; done = $false }
        } elseif ($l -match '^\[dev\] layout-box seq=(\d+) name=(\S+) bounds=(\S+)$') {
            $v = $Matches[3].Split(',') | ForEach-Object { [double]$_ }
            $snaps[[int]$Matches[1]].boxes[$Matches[2]] = [ordered]@{ x = $v[0]; y = $v[1]; w = $v[2]; h = $v[3] }
        } elseif ($l -match '^\[dev\] layout-snapshot-end seq=(\d+)$') {
            $snaps[[int]$Matches[1]].done = $true
        }
    }
    return $snaps
}

function Get-HeadField($snap, [string]$key) {
    if ($snap.head -match "(?:^|\s)$key=(\S+)") { return $Matches[1] }
    return $null
}

# 마지막 완성 스냅숏. $AfterSeq 보다 뒤이고 $Condition 을 만족하는 것을 $TimeoutMs 동안 기다린다.
function Wait-Snapshot([int]$AfterSeq, [scriptblock]$Condition, [int]$TimeoutMs = 5000) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $last = $null
    while ($sw.ElapsedMilliseconds -lt $TimeoutMs) {
        $snaps = Get-Snapshots
        # 하나뿐이면 PowerShell 이 배열을 풀어 버리므로 @() 로 감싼다.
        $done = @($snaps.Values | Where-Object { $_.done -and $_.seq -gt $AfterSeq } | Sort-Object { $_.seq })
        if ($done.Count -gt 0) {
            $last = $done[-1]
            if (-not $Condition -or (& $Condition $last)) { return $last }
        }
        Start-Sleep -Milliseconds 200
    }
    return $last
}

function Get-LatestSeq { $s = Get-Snapshots; if ($s.Count) { ($s.Keys | Measure-Object -Maximum).Maximum } else { 0 } }

function Save-Window([string]$Name) {
    $png = Join-Path $out "$Name.png"
    $expected = '0x{0:X}' -f $script:hwnd.ToInt64()
    $raw = & pwsh -NoProfile -File $CaptureScript -Hwnd $expected -Out $png -Method PrintWindow
    $text = ($raw | Out-String)
    Set-Content -LiteralPath (Join-Path $out "$Name.json") -Value $text -Encoding utf8
    $obj = $text | ConvertFrom-Json
    if ($obj.hwnd -ne $expected -or $obj.pid -ne $script:appPid) { throw "capture ${Name}: 고정한 창과 다른 창을 찍었다" }
    if (-not $obj.capture.ok) { throw "capture $Name 실패: $($obj.capture.error)" }
    return $obj
}

function Assert-Target([int]$X, [int]$Y, [string]$What) {
    if ([WgPhase3.Native]::GetForegroundWindow() -ne $script:hwnd) {
        [WgPhase3.Native]::Activate($script:hwnd)
        Start-Sleep -Milliseconds 300
    }
    if ([WgPhase3.Native]::GetForegroundWindow() -ne $script:hwnd) { throw "${What}: 대상 창을 전면으로 가져오지 못했다. 입력을 보내지 않고 중단한다" }
    $root = [WgPhase3.Native]::RootAt($X, $Y)
    if ($root -ne $script:hwnd) { throw ("{0}: 커서 위치 ({1},{2}) 아래 창이 대상 창이 아니다. 입력을 보내지 않고 중단한다" -f $What, $X, $Y) }
}

# 창 기준 논리 좌표 → 화면 물리 좌표
function To-Screen([double]$lx, [double]$ly) {
    @([int][math]::Round($script:client.x + $lx * $script:scale), [int][math]::Round($script:client.y + $ly * $script:scale))
}

function Check([string]$Id, [string]$What, $Expected, $Actual, [string]$Note = '') {
    $pass = $null
    if ($null -ne $Actual -and $null -ne $Expected) { $pass = ([math]::Abs([double]$Actual - [double]$Expected) -le 1.0) }
    [ordered]@{ id = $Id; what = $What; expected = $Expected; actual = $Actual; pass = $pass; note = $Note }
}

# 참·거짓 전용 검사 (허용 오차 0). 치수용 Check(±1)에 0/1 을 넘기면 기대 1·실제 0 도 통과하므로 쓰지 않는다.
# 실제 값이 [bool] 이 아니면(없음·숫자·문자열 등) 통과로 보지 않는다.
function CheckBool([string]$Id, [string]$What, [bool]$Expected, $Actual, [string]$Note = '') {
    $isBool = $Actual -is [bool]
    $pass = $isBool -and ($Actual -eq $Expected)
    [ordered]@{ id = $Id; what = $What; expected = $Expected; actual = $Actual; pass = $pass; kind = 'bool'; note = $(if ($isBool) { $Note } elseif ($null -eq $Actual) { "실제 값이 없다(null). $Note" } else { "실제 값이 bool 이 아니다($($Actual.GetType().Name)). $Note" }) }
}

# CheckBool 자체 시험: 거짓·bool 아닌 값이 통과로 나오지 않는지 시작할 때 확인한다.
function Test-CheckBool {
    $cases = @(
        @{ name = 'true vs true'; expected = $true; actual = $true; want = $true }
        @{ name = 'false vs false'; expected = $false; actual = $false; want = $true }
        @{ name = 'expected true, actual false'; expected = $true; actual = $false; want = $false }
        @{ name = 'expected false, actual true'; expected = $false; actual = $true; want = $false }
        @{ name = 'expected true, actual 1 (int)'; expected = $true; actual = 1; want = $false }
        @{ name = 'expected true, actual 0 (int)'; expected = $true; actual = 0; want = $false }
        @{ name = 'expected true, actual "True" (string)'; expected = $true; actual = 'True'; want = $false }
    )
    $rows = @()
    foreach ($c in $cases) {
        $r = CheckBool 'self-test' $c.name $c.expected $c.actual
        $rows += [ordered]@{ case = $c.name; pass = $r.pass; want = $c.want; ok = ($r.pass -eq $c.want) }
    }
    # 이전 방식(0/1 을 ±1 치수 검사에 넘김)이 거짓을 통과시키는지도 함께 기록한다(지적 재현).
    $legacy = Check 'self-test' 'legacy: expected 1, actual 0 via ±1 Check' 1 0
    [ordered]@{
        cases = $rows
        allOk = -not ($rows | Where-Object { -not $_.ok })
        legacyFalsePassed = $legacy.pass
    }
}

# CheckBool 자체 시험 (리뷰 2회차 D-020). 실패하면 앱을 띄우지 않고 끝낸다.
$checkBoolTest = Test-CheckBool
$result.selfTest = $checkBoolTest
if ($SelfTest) {
    $checkBoolTest | ConvertTo-Json -Depth 4
    if ($checkBoolTest.allOk) { exit 0 } else { exit 1 }
}
if (-not $checkBoolTest.allOk) {
    $result.errors += 'CheckBool 자체 시험 실패: 거짓 또는 bool 아닌 값이 통과로 나왔다'
    $result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $out 'result.json') -Encoding utf8
    throw 'CheckBool 자체 시험 실패'
}

$prev = [WgPhase3.Native]::SetThreadDpiAwarenessContext([WgPhase3.Native]::DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)
$proc = $null
try {
    $existing = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
    if ($existing.Count -gt 0) { throw "이미 실행 중인 $ProcessName 가 있다 (PID $($existing.Id -join ', ')). 닫고 다시 실행하라" }
    $exePath = (Resolve-Path -LiteralPath $Exe).Path
    $proc = Start-Process -FilePath $exePath -ArgumentList '--dev-layout' -RedirectStandardOutput $stdout -PassThru
    $script:appPid = $proc.Id
    $result.pid = $proc.Id
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt 20 -and $script:hwnd -eq [IntPtr]::Zero) {
        Start-Sleep -Milliseconds 100
        $script:hwnd = [WgPhase3.Native]::FindTitled([uint32]$proc.Id, $AppTitle)
    }
    if ($script:hwnd -eq [IntPtr]::Zero) { throw '앱 창이 20초 안에 뜨지 않았다' }
    $result.hwnd = '0x{0:X}' -f $script:hwnd.ToInt64()

    # ---------- 1) 최대화 + 스크린샷 + 스냅숏 ----------
    [WgPhase3.Native]::Activate($script:hwnd)
    [void][WgPhase3.Native]::ShowWindow($script:hwnd, [WgPhase3.Native]::SW_MAXIMIZE)
    $snap = Wait-Snapshot 0 { param($s) (Get-HeadField $s 'maximized') -eq 'true' -and $s.boxes.Contains('tab-bar') } 10000
    if (-not $snap -or (Get-HeadField $snap 'maximized') -ne 'true') { throw '최대화 후 스냅숏을 받지 못했다' }
    Start-Sleep -Milliseconds 500
    $snap = Wait-Snapshot 0 $null 3000
    $cap = Save-Window 'layout'
    $script:scale = [double]$cap.scale
    $script:client = $cap.clientRect
    $snap | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $out 'layout-boxes.json') -Encoding utf8
    $b = $snap.boxes
    $result.window = [ordered]@{
        head = $snap.head
        viewportLogical = Get-HeadField $snap 'viewport'
        rem = Get-HeadField $snap 'rem'
        scale = $script:scale
        expectedViewport = '1440x852 (A-30.2: 2880×1704 ÷ 2)'
    }

    # ---------- 2) R-12 배치, R-13 A-32 ----------
    $r12 = [ordered]@{
        'L-11 사이드바가 왼쪽, Workspace 가 그 오른쪽' = ($b.sidebar.x -eq 0 -and [math]::Abs($b.workspace.x - ($b.sidebar.x + $b.sidebar.w)) -le 1)
        'L-11 오른쪽 사이드바 없음(Workspace 가 창 오른쪽 끝까지)' = ([math]::Abs(($b.workspace.x + $b.workspace.w) - [double]((Get-HeadField $snap 'viewport').Split('x')[0])) -le 1)
        'L-12 사이드바가 창 전체 높이(타이틀 바 줄 포함)' = ($b.sidebar.y -eq 0 -and [math]::Abs($b.sidebar.h - [double]((Get-HeadField $snap 'viewport').Split('x')[1])) -le 1)
        'L-12 타이틀 바가 사이드바 오른쪽에서 시작' = ([math]::Abs($b.'title-bar'.x - $b.workspace.x) -le 1)
        'L-13 Workspace 세로: 타이틀 바 → 본문 → 상태 표시줄' = ($b.'title-bar'.y -lt $b.'work-area'.y -and $b.'work-area'.y -lt $b.'status-bar'.y)
        'L-14 본문 가로: 왼쪽 Dock → 가운데' = ([math]::Abs($b.dock.x - $b.body.x) -le 1 -and [math]::Abs($b.center.x - ($b.dock.x + $b.dock.w)) -le 1)
        'L-14 오른쪽·아래 Dock 없음(가운데가 본문 오른쪽·아래 끝까지)' = ([math]::Abs(($b.center.x + $b.center.w) - ($b.body.x + $b.body.w)) -le 1 -and [math]::Abs(($b.center.y + $b.center.h) - ($b.body.y + $b.body.h)) -le 1)
        'L-15 Pane = 탭 바 + 활성 아이템' = ([math]::Abs($b.'active-item'.y - ($b.'tab-bar'.y + $b.'tab-bar'.h)) -le 1)
    }
    $result.r12 = $r12

    $t = $b.tab; $ss = $b.'tab-slot-start'; $lb = $b.'tab-label'; $se = $b.'tab-slot-end'
    $ts = $b.'tab-bar-start'; $te = $b.'tab-bar-end'
    $row = $b.'sidebar-folder-row'; $rowLabel = $b.'sidebar-folder-row-label'
    $foot = $b.'sidebar-footer'; $ftb = $b.'sidebar-btn-toggle'; $ffa = $b.'sidebar-btn-folder-add'
    $sb = $b.'status-bar'; $sl = $b.'status-btn-project-panel'; $sc = $b.'status-cursor'
    $a32 = @(
        Check 'A-32.1' '타이틀 바 높이' 32 $b.'title-bar'.h
        Check 'A-32.2' '창 버튼 최소화 폭' 36 $b.'window-btn-min'.w
        Check 'A-32.2' '창 버튼 최소화 높이' 32 $b.'window-btn-min'.h
        Check 'A-32.2' '창 버튼 최대화/복원 폭' 36 $b.'window-btn-max'.w
        Check 'A-32.2' '창 버튼 최대화/복원 높이' 32 $b.'window-btn-max'.h
        Check 'A-32.2' '창 버튼 닫기 폭' 36 $b.'window-btn-close'.w
        Check 'A-32.2' '창 버튼 닫기 높이' 32 $b.'window-btn-close'.h
        Check 'A-32.3' '탭 바 높이' 32 $b.'tab-bar'.h
        Check 'A-32.3' '탭 내용 높이' 31 $b.'tab-content'.h
        Check 'A-32.4' '탭 왼쪽 padding' 4 ($ss.x - $t.x) '자리 표시 탭'
        Check 'A-32.4' '탭 오른쪽 padding' 4 (($t.x + $t.w) - ($se.x + $se.w)) '자리 표시 탭'
        Check 'A-32.4' '탭 gap (시작 슬롯→제목)' 4 ($lb.x - ($ss.x + $ss.w)) '자리 표시 탭'
        Check 'A-32.4' '탭 gap (제목→끝 슬롯)' 4 ($se.x - ($lb.x + $lb.w)) '자리 표시 탭'
        Check 'A-32.5' '탭 시작 슬롯 폭' 12 $ss.w '자리 표시 요소(빈 슬롯)'
        Check 'A-32.5' '탭 시작 슬롯 높이' 12 $ss.h '자리 표시 요소(빈 슬롯)'
        Check 'A-32.5' '탭 끝 슬롯 폭' 14 $se.w '자리 표시 요소(빈 슬롯)'
        Check 'A-32.5' '탭 끝 슬롯 높이' 14 $se.h '자리 표시 요소(빈 슬롯)'
        Check 'A-32.6' '탭 바 시작 영역 왼쪽 padding' 6 ($b.'tab-btn-back'.x - $ts.x)
        Check 'A-32.6' '탭 바 시작 영역 오른쪽 padding (테두리 1 제외)' 6 (($ts.x + $ts.w - 1) - ($b.'tab-btn-forward'.x + $b.'tab-btn-forward'.w))
        Check 'A-32.6' '탭 바 시작 영역 gap' 4 ($b.'tab-btn-forward'.x - ($b.'tab-btn-back'.x + $b.'tab-btn-back'.w))
        Check 'A-32.6' '탭 바 끝 영역 왼쪽 padding (테두리 1 제외)' 6 ($b.'tab-btn-new'.x - ($te.x + 1))
        Check 'A-32.6' '탭 바 끝 영역 오른쪽 padding' 6 (($te.x + $te.w) - ($b.'tab-btn-zoom'.x + $b.'tab-btn-zoom'.w))
        Check 'A-32.6' '탭 바 끝 영역 gap' 4 ($b.'tab-btn-split'.x - ($b.'tab-btn-new'.x + $b.'tab-btn-new'.w))
        Check 'A-32.7' '상태 표시줄 높이' 30 $sb.h
        Check 'A-32.8' '상태 표시줄 그룹 사이 gap' 8 ($b.'status-right'.x - ($b.'status-left'.x + $b.'status-left'.w)) '왼쪽 그룹을 flex_1 로 늘려 두 그룹 사이가 gap 그대로 남는다'
        Check 'A-32.8' '상태 표시줄 그룹 안 gap (왼쪽 그룹)' 4 ($b.'status-left-placeholder'.x - ($sl.x + $sl.w)) '자리 표시 요소로 쟀다(측정 모드에서만 넣는 22×22 빈 상자)'
        Check 'A-32.8' '상태 표시줄 그룹 안 gap (오른쪽 그룹)' 4 ($sc.x - ($b.'status-right-placeholder'.x + $b.'status-right-placeholder'.w)) '자리 표시 요소로 쟀다(측정 모드에서만 넣는 22×22 빈 상자)'
        Check 'A-32.7' '상태 표시줄 padding 왼쪽(참고)' 4 ($sl.x - $sb.x)
        Check 'A-32.7' '상태 표시줄 padding 오른쪽(참고)' 4 (($sb.x + $sb.w) - ($b.'status-right'.x + $b.'status-right'.w))
        Check 'A-32.9' 'Dock 리사이즈 핸들 폭' 6 $b.'dock-handle'.w
        Check 'A-32.9' '핸들이 Dock 오른쪽 경계에 절반씩 걸침(핸들 x − 경계 x)' -3 ($b.'dock-handle'.x - ($b.dock.x + $b.dock.w))
        Check 'A-32.10' '프로젝트 패널(왼쪽 Dock) 기본 폭' 240 $b.dock.w
        Check 'A-32.11' '사이드바 기본 폭' 300 $b.sidebar.w
        Check 'A-32.12' '사이드바 폴더 줄 높이' 31 $row.h '자리 표시 줄'
        Check 'A-32.12' '사이드바 폴더 줄 왼쪽 padding' 8 ($rowLabel.x - $row.x) '자리 표시 줄'
        Check 'A-32.12' '사이드바 폴더 줄 오른쪽 padding' 6 (($row.x + $row.w) - ($rowLabel.x + $rowLabel.w)) '자리 표시 줄(라벨을 줄 끝까지 늘려 잼)'
        Check 'A-32.13' '사이드바 푸터 padding 왼쪽' 4 ($ftb.x - $foot.x)
        Check 'A-32.13' '사이드바 푸터 padding 위 (위 테두리 1 제외)' 4 ($ftb.y - ($foot.y + 1))
        Check 'A-32.13' '사이드바 푸터 padding 오른쪽' 4 (($foot.x + $foot.w) - ($ffa.x + $ffa.w))
        Check 'A-32.13' '사이드바 푸터 위 테두리 (푸터 높이 − padding 4×2 − 버튼 22)' 1 ($foot.h - 8 - 22)
        Check 'A-32.13' '사이드바 푸터 gap (그룹 사이)' 4 ($b.'sidebar-footer-right'.x - ($b.'sidebar-footer-left'.x + $b.'sidebar-footer-left'.w)) '왼쪽 그룹을 flex_1 로 늘려 두 그룹 사이가 gap 그대로 남는다'
        Check 'A-32.13' '사이드바 푸터 gap (왼쪽 그룹 안)' 4 ($b.'sidebar-footer-left-placeholder'.x - ($ftb.x + $ftb.w)) '자리 표시 요소로 쟀다(측정 모드에서만 넣는 22×22 빈 상자)'
    )
    foreach ($n in 'tab-icon-back', 'tab-icon-forward', 'tab-icon-new', 'tab-icon-split', 'tab-icon-zoom', 'status-icon-project-panel') {
        $a32 += Check 'A-32.16' "아이콘 $n 폭" 14 $b.$n.w
        $a32 += Check 'A-32.16' "아이콘 $n 높이" 14 $b.$n.h
    }
    $result.a32 = $a32
    $result.a32Summary = [ordered]@{
        pass = @($a32 | Where-Object { $_.pass -eq $true }).Count
        fail = @($a32 | Where-Object { $_.pass -eq $false }).Count
        notMeasurable = @($a32 | Where-Object { $null -eq $_.pass }).Count
    }

    # ---------- 3) R-14 끌기 ----------
    # 앱은 300ms 마다 스냅숏을 낸다. 끌기 도중 스냅숏을 읽지 않도록, 끌기가 끝나고 1초 기다린 뒤의
    # 마지막 완성 스냅숏을 쓴다. 다음 끌기의 시작점도 그 스냅숏에서 다시 계산한다.
    $r14 = [ordered]@{}
    function Get-Settled {
        # 새 스냅숏이 1.2초 동안 더 나오지 않으면 안정된 것으로 본다(최대 약 12초).
        $prevSeq = -1
        for ($i = 0; $i -lt 10; $i++) {
            Start-Sleep -Milliseconds 1200
            $cur = Get-LatestSeq
            if ($cur -eq $prevSeq) { break }
            $prevSeq = $cur
        }
        @((Get-Snapshots).Values | Where-Object { $_.done } | Sort-Object { $_.seq })[-1]
    }
    function Step-Drag([string]$Name, [double]$fromLx, [double]$fromLy, [double]$toLx, [double]$toLy, [string]$What) {
        $p0 = To-Screen $fromLx $fromLy; $p1 = To-Screen $toLx $toLy
        Assert-Target $p0[0] $p0[1] "$Name 시작점"
        [WgPhase3.Native]::Drag($p0[0], $p0[1], $p1[0], $p1[1], 25, 15)
        $s = Get-Settled
        $cap2 = Save-Window "r14-$Name"
        $script:client = $cap2.clientRect
        [ordered]@{ what = $What; fromLogical = @($fromLx, $fromLy); toLogical = @($toLx, $toLy); dockWidth = [double](Get-HeadField $s 'dock_width'); dockBox = $s.boxes.dock; sidebarBox = $s.boxes.sidebar; bodyBox = $s.boxes.body; handleBox = $s.boxes.'dock-handle'; seq = $s.seq }
    }
    function Handle-X($step) { $step.handleBox.x + $step.handleBox.w / 2 }
    $midY = $b.body.y + $b.body.h / 2
    $vw = [double]((Get-HeadField $snap 'viewport').Split('x')[0])
    $r14.dockStart = [ordered]@{ dockWidth = [double](Get-HeadField $snap 'dock_width'); dockBox = $b.dock; bodyBox = $b.body; handleBox = $b.'dock-handle' }
    # 왼쪽 Dock 핸들: 핸들 가운데를 잡는다.
    $hx = Handle-X $r14.dockStart
    $r14.dockPlus100 = Step-Drag 'dock-plus100' $hx $midY ($hx + 100) $midY 'Dock 핸들 +100 → 340 기대(L-30)'
    $hx = Handle-X $r14.dockPlus100
    $r14.dockPastLeft = Step-Drag 'dock-past-left' $hx $midY ($b.body.x - 40) $midY 'Dock 핸들을 본문 왼쪽 끝 너머(사이드바 위)로 → 하한 6 기대(L-31)'
    $hx = Handle-X $r14.dockPastLeft
    $r14.dockPastRight = Step-Drag 'dock-past-right' $hx $midY ($vw - 2) $midY "Dock 핸들을 창 오른쪽 끝 근처로 → 상한 본문 폭−6 = $($b.body.w - 6) 기대(L-31)"
    $hx = Handle-X $r14.dockPastRight
    # 더블클릭 → 240
    $p = To-Screen $hx $midY
    Assert-Target $p[0] $p[1] 'Dock 핸들 더블클릭'
    Start-Sleep -Milliseconds ([WgPhase3.Native]::GetDoubleClickTime() + 100)
    [WgPhase3.Native]::DoubleClick($p[0], $p[1])
    $s = Get-Settled
    [void](Save-Window 'r14-dock-double-click')
    $r14.dockDoubleClick = [ordered]@{ what = '핸들 더블클릭 → 240 기대(L-30)'; dockWidth = [double](Get-HeadField $s 'dock_width'); dockBox = $s.boxes.dock; seq = $s.seq }

    # 사이드바 경계(resizable 핸들): 사이드바 오른쪽 끝을 잡는다.
    $sb0 = $s.boxes.sidebar
    $r14.sidebarStart = [ordered]@{ sidebarBox = $sb0 }
    $sx = $sb0.x + $sb0.w
    $r14.sidebarPlus100 = Step-Drag 'sidebar-plus100' $sx $midY ($sx + 100) $midY '사이드바 경계 +100 → 400 기대(L-33 200~800 안)'
    $sx = $r14.sidebarPlus100.sidebarBox.x + $r14.sidebarPlus100.sidebarBox.w
    $r14.sidebarPast800 = Step-Drag 'sidebar-past800' $sx $midY 1000 $midY '사이드바 경계를 1000 으로 → 800 기대(L-33 상한)'
    $sx = $r14.sidebarPast800.sidebarBox.x + $r14.sidebarPast800.sidebarBox.w
    $r14.sidebarBelow200 = Step-Drag 'sidebar-below200' $sx $midY 60 $midY '사이드바 경계를 60 으로 → 200 기대(L-33 하한)'

    # ---- 리뷰 1회차(D-019) 추가 시나리오: 본문 폭이 바뀌어도 Dock 이 상한 "본문 폭 − 6"을 넘지 않는가 ----
    function Dock-Fits($step) {
        $s = $step.snap
        $dock = [double](Get-HeadField $s 'dock_width'); $body = $s.boxes.body; $h = $s.boxes.'dock-handle'
        [ordered]@{
            dockWidth = $dock; dockStored = Get-HeadField $s 'dock_stored'; bodyWidth = $body.w
            limit = $body.w - 6
            dockWithinLimit = ($dock -le $body.w - 6 + 0.01 -and $dock -ge 6 - 0.01)
            dockBoxWidth = $s.boxes.dock.w
            handleInsideBody = ($h.x -ge $body.x - 3.01 -and ($h.x + $h.w) -le ($body.x + $body.w) + 0.01)
            handleCenteredOnDockEdge = ([math]::Abs(($h.x + $h.w / 2) - ($s.boxes.dock.x + $s.boxes.dock.w)) -le 1)
        }
    }
    function Snap-Step([string]$Name, [string]$What) {
        $s = Get-Settled
        $cap2 = Save-Window "r14-$Name"
        $script:client = $cap2.clientRect
        $step = [ordered]@{ what = $What; snap = $s }
        $fit = Dock-Fits $step
        $step.Remove('snap')
        foreach ($k in $fit.Keys) { $step[$k] = $fit[$k] }
        $step.seq = $s.seq
        $step.boxes = [ordered]@{ body = $s.boxes.body; dock = $s.boxes.dock; handle = $s.boxes.'dock-handle'; sidebar = $s.boxes.sidebar }
        return $step
    }
    # A1) Dock 을 상한까지 넓힌다(사이드바 200, 본문 1240 → 1234).
    $cur = Get-Settled; $hx = $cur.boxes.'dock-handle'.x + $cur.boxes.'dock-handle'.w / 2
    $p0 = To-Screen $hx $midY; $p1 = To-Screen ($vw - 2) $midY
    Assert-Target $p0[0] $p0[1] 'A1 Dock 상한까지'
    [WgPhase3.Native]::Drag($p0[0], $p0[1], $p1[0], $p1[1], 25, 15)
    $r14.reviewDockToMax = Snap-Step 'review-dock-to-max' 'A1 Dock 을 상한까지 넓힘 → 본문 폭 − 6'
    # A2) 더블클릭 없이 사이드바를 800 으로 넓힌다 → 본문이 줄어도 Dock ≤ 본문 − 6.
    $cur = Get-Settled; $sx = $cur.boxes.sidebar.x + $cur.boxes.sidebar.w
    $p0 = To-Screen $sx $midY; $p1 = To-Screen 1000 $midY
    Assert-Target $p0[0] $p0[1] 'A2 사이드바 800 으로'
    [WgPhase3.Native]::Drag($p0[0], $p0[1], $p1[0], $p1[1], 25, 15)
    $r14.reviewSidebarAfterDockMax = Snap-Step 'review-sidebar-800-after-dock-max' 'A2 Dock 상한 상태에서 사이드바 800 으로 확장 → Dock ≤ 본문 − 6'
    # B) 최대화를 풀고 창을 1000×700 논리 px 로 줄인다 → Dock ≤ 본문 − 6.
    [void][WgPhase3.Native]::ShowWindow($script:hwnd, [WgPhase3.Native]::SW_RESTORE)
    Start-Sleep -Milliseconds 600
    $wr = $cap.monitor.workRect
    [WgPhase3.Native]::Place($script:hwnd, [int]($wr.x + 100), [int]($wr.y + 100), [int](1000 * $script:scale), [int](700 * $script:scale))
    $r14.reviewWindowShrink = Snap-Step 'review-window-shrink' 'B 최대화 해제 후 창 1000×700 논리 px 로 축소 → Dock ≤ 본문 − 6'
    # C0) 창을 줄이면 resizable 이 사이드바도 함께 줄여 본문이 넓게 남는다. 사이드바를 다시 넓혀
    #     본문 − 6 이 240 보다 작아지게 만든다(사이드바 상한 800, 창 1000 이면 본문 약 200).
    $cur = Get-Settled; $sx = $cur.boxes.sidebar.x + $cur.boxes.sidebar.w
    $p0 = To-Screen $sx $midY; $p1 = To-Screen 900 $midY
    Assert-Target $p0[0] $p0[1] 'C0 사이드바 넓힘'
    [WgPhase3.Native]::Drag($p0[0], $p0[1], $p1[0], $p1[1], 25, 15)
    $r14.reviewNarrowBody = Snap-Step 'review-narrow-body' 'C0 작은 창에서 사이드바를 넓혀 본문을 좁힘 → Dock ≤ 본문 − 6'
    # C) 좁은 본문에서 핸들 더블클릭 → min(240, 본문 − 6).
    $cur = Get-Settled
    $hx = $cur.boxes.'dock-handle'.x + $cur.boxes.'dock-handle'.w / 2
    $hy = $cur.boxes.body.y + $cur.boxes.body.h / 2
    $p = To-Screen $hx $hy
    Assert-Target $p[0] $p[1] 'C 좁은 본문 더블클릭'
    Start-Sleep -Milliseconds ([WgPhase3.Native]::GetDoubleClickTime() + 100)
    [WgPhase3.Native]::DoubleClick($p[0], $p[1])
    $r14.reviewNarrowDoubleClick = Snap-Step 'review-narrow-double-click' 'C 좁은 본문에서 핸들 더블클릭 → min(240, 본문 − 6)'
    $r14.reviewNarrowDoubleClick.expected = [math]::Min(240, $r14.reviewNarrowDoubleClick.bodyWidth - 6)
    $r14.checks = @(
        Check 'L-30' 'Dock 끌기 +100 후 폭' 340 $r14.dockPlus100.dockWidth
        Check 'L-31' 'Dock 하한' 6 $r14.dockPastLeft.dockWidth
        Check 'L-31' 'Dock 상한 (본문 폭 − 6)' ($b.body.w - 6) $r14.dockPastRight.dockWidth
        Check 'L-30' '더블클릭 후 Dock 폭' 240 $r14.dockDoubleClick.dockWidth
        Check 'L-30' '핸들 폭' 6 $b.'dock-handle'.w
        Check 'L-33' '사이드바 끌기 +100 후 폭' 400 $r14.sidebarPlus100.sidebarBox.w
        Check 'L-33' '사이드바 상한' 800 $r14.sidebarPast800.sidebarBox.w
        Check 'L-33' '사이드바 하한' 200 $r14.sidebarBelow200.sidebarBox.w
        Check 'L-31' 'A1 Dock 상한(본문 − 6)' ($r14.reviewDockToMax.limit) $r14.reviewDockToMax.dockWidth
        Check 'L-31' 'A2 사이드바 800 확장 뒤 Dock = min(저장 폭, 본문 − 6)' ($r14.reviewSidebarAfterDockMax.limit) $r14.reviewSidebarAfterDockMax.dockWidth
        Check 'L-31' 'B 창 축소 뒤 Dock ≤ 본문 − 6 (Dock 상자 폭)' ([math]::Min($r14.reviewWindowShrink.dockWidth, $r14.reviewWindowShrink.limit)) $r14.reviewWindowShrink.dockBoxWidth 'Dock 상자 폭이 유효 폭과 같고 상한 안이어야 한다'
        Check 'L-31' 'C0 본문을 좁힌 뒤 Dock = min(저장 폭, 본문 − 6)' ([math]::Min(([double]($r14.reviewWindowShrink.dockWidth)), $r14.reviewNarrowBody.limit)) $r14.reviewNarrowBody.dockWidth
        CheckBool 'L-30' 'C 좁은 본문(본문 − 6 < 240) 확인' $true ($r14.reviewNarrowDoubleClick.bodyWidth - 6 -lt 240)
        Check 'L-30' 'C 좁은 본문 더블클릭 → min(240, 본문 − 6)' $r14.reviewNarrowDoubleClick.expected $r14.reviewNarrowDoubleClick.dockWidth
        CheckBool 'L-30' 'A2 핸들이 본문 안에 있고 Dock 경계에 걸침' $true ($r14.reviewSidebarAfterDockMax.handleInsideBody -and $r14.reviewSidebarAfterDockMax.handleCenteredOnDockEdge)
        CheckBool 'L-30' 'B 핸들이 본문 안에 있고 Dock 경계에 걸침' $true ($r14.reviewWindowShrink.handleInsideBody -and $r14.reviewWindowShrink.handleCenteredOnDockEdge)
        CheckBool 'L-30' 'C 핸들이 본문 안에 있고 Dock 경계에 걸침' $true ($r14.reviewNarrowDoubleClick.handleInsideBody -and $r14.reviewNarrowDoubleClick.handleCenteredOnDockEdge)
    )
    $result.r14 = $r14

    # ---------- 4) R-15 ----------
    $metrics = Get-Content -LiteralPath $MetricsFile
    $consts = @()
    for ($i = 0; $i -lt $metrics.Count; $i++) {
        if ($metrics[$i] -match '^pub const (\w+): (\w+(?:<\w+>)?) = (.+);') {
            $consts += [ordered]@{ line = $i + 1; name = $Matches[1]; type = $Matches[2]; value = $Matches[3]; viaRemHelper = ($Matches[3] -like 'rems_from_px(*') }
        }
    }
    $pxExceptions = @('TITLE_BAR_HEIGHT', 'TITLE_BAR_PADDING_LEFT', 'WINDOW_BUTTON_WIDTH', 'WINDOW_BUTTON_HEIGHT', 'WINDOW_BUTTON_GLYPH_SIZE', 'WINDOW_ROUNDING', 'WINDOW_MIN_SIZE')
    $nonRem = @($consts | Where-Object { -not $_.viaRemHelper -and $pxExceptions -notcontains $_.name })
    $result.r15 = [ordered]@{
        windowRem = [double](Get-HeadField $snap 'rem')
        expectedRem = 16
        constants = $consts
        pxExceptions = $pxExceptions
        pxExceptionReason = 'SPEC R-15 이후 변경: 타이틀 바·창 버튼(A-32.1, A-32.2)은 L-21 Windows 32 고정이라 px 허용. 창 모서리·최소 크기는 R-13 표 밖'
        nonRemOutsideExceptions = $nonRem
        a32AllMeasuredAndPass = ($a32.Count -gt 0 -and -not ($a32 | Where-Object { $_.pass -ne $true }))
        pass = ([double](Get-HeadField $snap 'rem') -eq 16 -and $nonRem.Count -eq 0 -and $a32.Count -gt 0 -and -not ($a32 | Where-Object { $_.pass -ne $true }))
    }
}
catch {
    $result.errors += $_.Exception.Message
}
finally {
    [void][WgPhase3.Native]::SetThreadDpiAwarenessContext($prev)
    if ($proc -and -not $proc.HasExited) {
        try { [void]$proc.CloseMainWindow(); [void]$proc.WaitForExit(5000) } catch {}
        if (-not $proc.HasExited) { try { $proc.Kill(); [void]$proc.WaitForExit(3000) } catch {} }
    }
}

$result.finishedAt = (Get-Date).ToString('o')
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $out 'result.json') -Encoding utf8
"errors: $($result.errors.Count)"
$result.errors
if ($result.a32Summary) { "A-32: pass=$($result.a32Summary.pass) fail=$($result.a32Summary.fail) notMeasurable=$($result.a32Summary.notMeasurable)" }
if ($result.r14) { $result.r14.checks | ForEach-Object { "{0} {1}: expected={2} actual={3} pass={4}" -f $_.id, $_.what, $_.expected, $_.actual, $_.pass } }
if ($result.r15) { "R-15 rem=$($result.r15.windowRem) nonRem=$($result.r15.nonRemOutsideExceptions.Count) pass=$($result.r15.pass)" }
if ($result.errors.Count -gt 0) { exit 1 }

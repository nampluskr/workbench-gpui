#Requires -Version 7
<#
.SYNOPSIS
  v0.2 Phase 3 (SPEC R-10~R-16·R-28, D-035) 증거: 사이드바 폴더 등록·선택·해제·순서, 표시·포커스 키, state.json.

.DESCRIPTION
  앱을 `--dev-keymap --dev-layout --dev-pick-folder <파일>` 로 사례마다 새로 띄운다(dialog 사례만 플래그 없이 실제 선택 창).
  쓰는 앱 출력: [dev] folders / folder-row / folder-add / folder-activate / folder-remove / folder-move / pick-folder /
  context-menu-open·exec·close / state-load / state-save / sidebar / notification / focus-state / layout-box / menu-render.

  안전 규칙(Phase 1·2 D-028·D-029 와 같다):
    - 시작 전에 workbench-gpui 가 이미 실행 중이면 오류로 끝낸다. 띄운 프로세스(PID)만 닫는다.
    - 키·마우스를 보내기 직전마다 고정한 창이 전면인지, 마우스 아래 최상위 창이 그 창인지 확인한다.
    - %APPDATA%\workbench-gpui 의 state.json·state.json.tmp·state.json.bad-*·keymap.json 은 시작 때 임시 폴더로 백업하고,
      끝날 때 가장 먼저 독립 try/finally 로 되돌린다. 실행 전후 SHA-256 을 results.json 의 userFiles 에 남긴다.
    - 시험 폴더는 target\phase3-folders 아래에만 만든다(사용자 실제 폴더를 건드리지 않는다).

  결과: specs/v0.2/verify/phase3/ 의 <사례>-stdout.txt, 스크린샷, state-*.json, disk-*.txt, results.json.

.EXAMPLE
  pwsh -NoProfile -File tools/verify-v02-phase3.ps1
  pwsh -NoProfile -Command "& ./tools/verify-v02-phase3.ps1 -Only add,remove"
#>
[CmdletBinding()]
param(
    [string]$Exe = 'target\debug\workbench-gpui.exe',
    [string]$OutDir = 'specs\v0.2\verify\phase3',
    [string[]]$Only = @()
)

$ErrorActionPreference = 'Stop'
$ProcessName = 'workbench-gpui'
$AppTitle = 'workbench-gpui'
$CaptureScript = Join-Path $PSScriptRoot 'capture.ps1'

if (-not ('WgP3.Native' -as [type])) {
    Add-Type -ReferencedAssemblies @('System.Runtime', 'System.Collections', 'System.Threading', 'System.Threading.Thread', 'System.Runtime.InteropServices') -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

namespace WgP3
{
    [StructLayout(LayoutKind.Sequential)]
    public struct MOUSEINPUT { public int dx; public int dy; public uint mouseData; public uint dwFlags; public uint time; public IntPtr dwExtraInfo; }
    [StructLayout(LayoutKind.Sequential)]
    public struct KEYBDINPUT { public ushort wVk; public ushort wScan; public uint dwFlags; public uint time; public IntPtr dwExtraInfo; }
    [StructLayout(LayoutKind.Explicit)]
    public struct InputUnion { [FieldOffset(0)] public MOUSEINPUT mi; [FieldOffset(0)] public KEYBDINPUT ki; }
    [StructLayout(LayoutKind.Sequential)]
    public struct INPUT { public uint type; public InputUnion u; }
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)]
    public struct POINT { public int X, Y; }

    public static class Native
    {
        const uint INPUT_MOUSE = 0, INPUT_KEYBOARD = 1, KEYEVENTF_EXTENDEDKEY = 0x1, KEYEVENTF_KEYUP = 0x2;
        const uint MOUSEEVENTF_MOVE = 0x1, MOUSEEVENTF_LEFTDOWN = 0x2, MOUSEEVENTF_LEFTUP = 0x4, MOUSEEVENTF_WHEEL = 0x800;
        const uint MOUSEEVENTF_VIRTUALDESK = 0x4000, MOUSEEVENTF_ABSOLUTE = 0x8000;
        const int SM_XVIRTUALSCREEN = 76, SM_YVIRTUALSCREEN = 77, SM_CXVIRTUALSCREEN = 78, SM_CYVIRTUALSCREEN = 79;
        public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
        [DllImport("user32.dll", SetLastError = true)] static extern uint SendInput(uint n, INPUT[] inputs, int size);
        [DllImport("user32.dll")] static extern uint MapVirtualKey(uint code, uint mapType);
        [DllImport("user32.dll")] static extern int GetSystemMetrics(int index);
        [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern bool IsZoomed(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int cmd);
        [DllImport("user32.dll")] static extern IntPtr WindowFromPoint(POINT p);
        [DllImport("user32.dll")] static extern IntPtr GetAncestor(IntPtr hWnd, uint flags);
        [DllImport("user32.dll")] static extern bool EnumWindows(EnumWindowsProc cb, IntPtr lParam);
        [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
        [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr hWnd);
        [DllImport("user32.dll")] static extern IntPtr GetWindow(IntPtr hWnd, uint cmd);
        [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr hWnd, StringBuilder sb, int max);
        [DllImport("user32.dll")] static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool attach);
        [DllImport("user32.dll")] static extern bool BringWindowToTop(IntPtr hWnd);
        [DllImport("kernel32.dll")] static extern uint GetCurrentThreadId();
        [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr ctx);

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

        // 전면 전환(입력 주입 없이). 결과는 호출 쪽이 GetForegroundWindow 로 다시 확인한다.
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

        public static IntPtr RootAt(int x, int y)
        {
            var h = WindowFromPoint(new POINT { X = x, Y = y });
            return h == IntPtr.Zero ? IntPtr.Zero : GetAncestor(h, 2);
        }

        static void Send(INPUT i)
        {
            if (SendInput(1, new[] { i }, Marshal.SizeOf(typeof(INPUT))) != 1)
                throw new InvalidOperationException("SendInput failed: " + Marshal.GetLastWin32Error());
        }

        static INPUT M(uint flags, int x, int y, uint data)
        {
            int vx = GetSystemMetrics(SM_XVIRTUALSCREEN), vy = GetSystemMetrics(SM_YVIRTUALSCREEN);
            int vw = GetSystemMetrics(SM_CXVIRTUALSCREEN), vh = GetSystemMetrics(SM_CYVIRTUALSCREEN);
            var i = new INPUT { type = INPUT_MOUSE };
            i.u.mi.dx = (int)Math.Round((x - vx) * 65535.0 / Math.Max(1, vw - 1));
            i.u.mi.dy = (int)Math.Round((y - vy) * 65535.0 / Math.Max(1, vh - 1));
            i.u.mi.mouseData = data;
            i.u.mi.dwFlags = flags | MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_VIRTUALDESK;
            return i;
        }

        public static void MoveTo(int x, int y) { Send(M(0, x, y, 0)); }
        public static void Click(int x, int y)
        {
            Send(M(0, x, y, 0)); Thread.Sleep(60);
            Send(M(MOUSEEVENTF_LEFTDOWN, x, y, 0)); Thread.Sleep(40);
            Send(M(MOUSEEVENTF_LEFTUP, x, y, 0));
        }
        public static void Wheel(int x, int y, int delta) { Send(M(MOUSEEVENTF_WHEEL, x, y, unchecked((uint)delta))); }

        const uint MOUSEEVENTF_RIGHTDOWN = 0x8, MOUSEEVENTF_RIGHTUP = 0x10, KEYEVENTF_UNICODE = 0x4;
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetClassName(IntPtr hWnd, StringBuilder sb, int max);
        public static string ClassOf(IntPtr h) { var sb = new StringBuilder(256); GetClassName(h, sb, sb.Capacity); return sb.ToString(); }
        // 이 프로세스의 보이는 최상위 대화상자(#32770) 하나. 없으면 0.
        public static IntPtr FindDialog(uint pid)
        {
            IntPtr found = IntPtr.Zero;
            EnumWindows((h, l) =>
            {
                uint p; GetWindowThreadProcessId(h, out p);
                if (p == pid && IsWindowVisible(h) && ClassOf(h) == "#32770") { found = h; return false; }
                return true;
            }, IntPtr.Zero);
            return found;
        }
        [DllImport("user32.dll")] static extern IntPtr GetDlgItem(IntPtr hDlg, int id);
        // 대화상자 IDOK(1) 버튼의 화면 중심(물리 px). 없으면 (-1,-1).
        public static int[] OkCenter(IntPtr dlg)
        {
            var b = GetDlgItem(dlg, 1);
            if (b == IntPtr.Zero) return new[] { -1, -1 };
            RECT r; GetWindowRect(b, out r);
            return new[] { (r.Left + r.Right) / 2, (r.Top + r.Bottom) / 2 };
        }
        public static string OkText(IntPtr dlg) { var b = GetDlgItem(dlg, 1); return b == IntPtr.Zero ? "" : Title(b); }
        public static void ClickRaw(int x, int y) { Click(x, y); }
        public static void RightClick(int x, int y)
        {
            Send(M(0, x, y, 0)); Thread.Sleep(60);
            Send(M(MOUSEEVENTF_RIGHTDOWN, x, y, 0)); Thread.Sleep(40);
            Send(M(MOUSEEVENTF_RIGHTUP, x, y, 0));
        }
        public static void Drag(int x0, int y0, int x1, int y1)
        {
            Send(M(0, x0, y0, 0)); Thread.Sleep(150);
            Send(M(MOUSEEVENTF_LEFTDOWN, x0, y0, 0)); Thread.Sleep(150);
            for (int n = 1; n <= 10; n++) { Send(M(0, x0 + (x1 - x0) * n / 10, y0 + (y1 - y0) * n / 10, 0)); Thread.Sleep(40); }
            Thread.Sleep(150);
            Send(M(MOUSEEVENTF_LEFTUP, x1, y1, 0));
        }
        public static void TypeText(string s)
        {
            foreach (char c in s)
            {
                var d = new INPUT { type = INPUT_KEYBOARD }; d.u.ki.wScan = c; d.u.ki.dwFlags = KEYEVENTF_UNICODE;
                var u = new INPUT { type = INPUT_KEYBOARD }; u.u.ki.wScan = c; u.u.ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;
                Send(d); Send(u); Thread.Sleep(5);
            }
        }

        static bool IsExtended(ushort vk)
        {
            switch (vk) { case 0x21: case 0x22: case 0x23: case 0x24: case 0x25: case 0x26: case 0x27: case 0x28: case 0x2D: case 0x2E: case 0x5D: return true; }
            return false;
        }

        static INPUT K(ushort vk, bool up)
        {
            var i = new INPUT { type = INPUT_KEYBOARD };
            i.u.ki.wVk = vk;
            i.u.ki.wScan = (ushort)MapVirtualKey(vk, 0);
            i.u.ki.dwFlags = (up ? KEYEVENTF_KEYUP : 0) | (IsExtended(vk) ? KEYEVENTF_EXTENDEDKEY : 0);
            return i;
        }

        // 키 내림·올림 여러 개를 SendInput 한 번에 보낸다(사이 지연 없음). 50ms 안에 이어지는 입력을 재현할 때 쓴다.
        public static void Batch(ushort[] vks, bool[] ups)
        {
            var inputs = new INPUT[vks.Length];
            for (int n = 0; n < vks.Length; n++) inputs[n] = K(vks[n], ups[n]);
            if (SendInput((uint)inputs.Length, inputs, Marshal.SizeOf(typeof(INPUT))) != inputs.Length)
                throw new InvalidOperationException("SendInput batch failed: " + Marshal.GetLastWin32Error());
        }

        public static void Combo(ushort[] mods, ushort key)
        {
            foreach (var m in mods) { Send(K(m, false)); Thread.Sleep(30); }
            Send(K(key, false)); Thread.Sleep(40);
            Send(K(key, true)); Thread.Sleep(30);
            for (int n = mods.Length - 1; n >= 0; n--) { Send(K(mods[n], true)); Thread.Sleep(30); }
        }
    }
}
'@
}

$VK = @{
    ctrl = 0x11; shift = 0x10; alt = 0x12
    tab = 0x09; enter = 0x0D; escape = 0x1B
    pageup = 0x21; pagedown = 0x22; end = 0x23; home = 0x24
    left = 0x25; up = 0x26; right = 0x27; down = 0x28
    f10 = 0x79; delete = 0x2E; semicolon = 0xBA; backspace = 0x08
}
foreach ($c in [char[]]'abcdefghijklmnopqrstuvwxyz') { $VK["$c"] = [int][char]::ToUpper($c) }

$out = [System.IO.Path]::GetFullPath($OutDir, (Get-Location).Path)
if (-not (Test-Path -LiteralPath $out)) { New-Item -ItemType Directory -Path $out -Force | Out-Null }
$appDir = Join-Path $env:APPDATA 'workbench-gpui'
$keymapPath = Join-Path $appDir 'keymap.json'
$statePath = Join-Path $appDir 'state.json'
$backupDir = Join-Path ([System.IO.Path]::GetTempPath()) ("wg-p3-backup-{0}" -f [guid]::NewGuid())
# 백업·복원 대상: keymap.json, state.json, state.json.tmp, state.json.bad-*.
function Get-UserFiles {
    if (-not (Test-Path -LiteralPath $appDir)) { return @() }
    @(Get-ChildItem -LiteralPath $appDir -File | Where-Object { $_.Name -eq 'keymap.json' -or $_.Name -like 'state.json*' })
}
function Get-UserHashes {
    $h = [ordered]@{}
    foreach ($f in (Get-UserFiles | Sort-Object Name)) { $h[$f.Name] = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash }
    return $h
}
$userHashBefore = Get-UserHashes
# 시험 폴더(사용자 폴더가 아니다). 실행마다 따로 만든다(리뷰 2회차, D-040).
$runId = [guid]::NewGuid().ToString('N')
$testBase = [System.IO.Path]::GetFullPath('target\phase3-folders', (Get-Location).Path)
$testRoot = Join-Path $testBase "run-$runId"
$testMarker = Join-Path $testRoot '.wg-p3-run'
$script:testRootCreated = $false
$script:testBaseCreated = $false
$pickFile = Join-Path $testRoot 'pick.txt'

$results = [ordered]@{ startedAt = (Get-Date).ToString('o'); appDir = $appDir; testRoot = $testRoot; cases = [ordered]@{}; failures = @(); errors = @(); checks = @() }

$script:hwnd = [IntPtr]::Zero
$script:appPid = 0
$script:stdout = $null
$script:launched = $null
$script:client = $null
$script:scale = 1.0

function Fail([string]$Case, [string]$Text) { $script:results.failures += "${Case}: $Text" }

# 판정 하나를 남긴다. ok 가 아니면 실패로도 센다.
function Check([string]$Case, [string]$Id, [string]$What, $Expect, $Got, [bool]$Ok, [string]$Evidence = '') {
    $script:results.checks += [ordered]@{ case = $Case; id = $Id; what = $What; expect = "$Expect"; got = "$Got"; ok = $Ok; evidence = $Evidence }
    if (-not $Ok) { Fail $Case "$Id ${What}: 기대 $Expect, 실제 $Got" }
}
function Near([double]$a, [double]$b, [double]$tol = 1.0) { [math]::Abs($a - $b) -le $tol }

function UnixMs { [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() }

function Get-Lines([string]$Pattern) {
    @(Get-Content -LiteralPath $script:stdout -Encoding utf8 -ErrorAction SilentlyContinue | Where-Object { $_ -match $Pattern })
}
function Count-Lines([string]$Pattern) { (Get-Lines $Pattern).Count }

function Wait-NewLine([string]$Pattern, [int]$Before, [double]$Seconds = 5) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $Seconds) {
        $l = @(Get-Lines $Pattern | Select-Object -Skip $Before)
        if ($l.Count -gt 0) { return $l[0] }
        Start-Sleep -Milliseconds 50
    }
    return $null
}

# 가장 최근 레이아웃 스냅숏에서 이름의 경계. 없으면 $null.
function Get-Box([string]$Name) {
    $ends = @(Get-Lines '^\[dev\] layout-snapshot-end seq=(\d+)')
    if ($ends.Count -eq 0) { return $null }
    [void]($ends[-1] -match 'seq=(\d+)'); $seq = $Matches[1]
    $l = @(Get-Lines ("^\[dev\] layout-box seq={0} name={1} bounds=" -f $seq, [regex]::Escape($Name)))
    if ($l.Count -eq 0) { return $null }
    [void]($l[-1] -match 'bounds=([-\d.]+),([-\d.]+),([-\d.]+),([-\d.]+)')
    [pscustomobject]@{ x = [double]$Matches[1]; y = [double]$Matches[2]; w = [double]$Matches[3]; h = [double]$Matches[4] }
}
function Get-Viewport {
    $l = @(Get-Lines '^\[dev\] layout-snapshot seq=\d+ .*viewport=')
    [void]($l[-1] -match 'viewport=([\d.]+)x([\d.]+)')
    [pscustomobject]@{ w = [double]$Matches[1]; h = [double]$Matches[2] }
}
function Wait-Box([string]$Name, [double]$Seconds = 3, [scriptblock]$Until = $null) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $Seconds) {
        $b = Get-Box $Name
        if ($b -and (-not $Until -or (& $Until $b))) { return $b }
        Start-Sleep -Milliseconds 100
    }
    return $null
}
# 입력 대상의 경계. 스냅숏에 나올 때까지 기다리고, 끝내 없으면 입력을 보내지 않고 멈춘다(없는 경계로 (0,0) 을 누르지 않게).
function Need-Box([string]$Name, [double]$Seconds = 3) {
    $b = Wait-Box $Name $Seconds
    if (-not $b) { throw "${Name}: 레이아웃 스냅숏에 경계가 없다. 입력을 보내지 않고 중단한다" }
    return $b
}
function Wait-NoBox([string]$Name, [double]$Seconds = 3) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $Seconds) {
        if (-not (Get-Box $Name)) { return $true }
        Start-Sleep -Milliseconds 100
    }
    return $false
}

function Assert-Foreground([string]$What) {
    if ([WgP3.Native]::GetForegroundWindow() -ne $script:hwnd) {
        [WgP3.Native]::Activate($script:hwnd)
        Start-Sleep -Milliseconds 300
    }
    if ([WgP3.Native]::GetForegroundWindow() -ne $script:hwnd) { throw "${What}: 대상 창이 전면이 아니다. 입력을 보내지 않고 중단한다" }
}
function Assert-Target([int]$X, [int]$Y, [string]$What) {
    Assert-Foreground $What
    if ([WgP3.Native]::RootAt($X, $Y) -ne $script:hwnd) { throw ("{0}: ({1},{2}) 아래 창이 대상 창이 아니다. 입력을 보내지 않고 중단한다" -f $What, $X, $Y) }
}

function ToScreen([double]$x, [double]$y) {
    @([int][math]::Round($script:client.x + $x * $script:scale), [int][math]::Round($script:client.y + $y * $script:scale))
}
function Center($b) { ToScreen ($b.x + $b.w / 2) ($b.y + $b.h / 2) }

function Move-To([double]$x, [double]$y, [string]$What) {
    $p = ToScreen $x $y
    Assert-Target $p[0] $p[1] $What
    [WgP3.Native]::MoveTo($p[0], $p[1])
}
function Click-At([double]$x, [double]$y, [string]$What) {
    $p = ToScreen $x $y
    Assert-Target $p[0] $p[1] $What
    [WgP3.Native]::Click($p[0], $p[1])
}
# 여러 키 입력을 지연 없이 한 번에 보낸다(예: 'ctrl-b left').
function Send-Batch([string]$Keys) {
    $vks = [System.Collections.Generic.List[uint16]]::new()
    $ups = [System.Collections.Generic.List[bool]]::new()
    foreach ($stroke in $Keys.Split(' ', [StringSplitOptions]::RemoveEmptyEntries)) {
        $parts = $stroke.Split('-')
        $mods = @($parts | Select-Object -SkipLast 1 | ForEach-Object { [uint16]$VK[$_] })
        foreach ($m in $mods) { $vks.Add($m); $ups.Add($false) }
        $vks.Add([uint16]$VK[$parts[-1]]); $ups.Add($false)
        $vks.Add([uint16]$VK[$parts[-1]]); $ups.Add($true)
        for ($i = $mods.Count - 1; $i -ge 0; $i--) { $vks.Add($mods[$i]); $ups.Add($true) }
    }
    Assert-Foreground "키 묶음 $Keys"
    [WgP3.Native]::Batch($vks.ToArray(), $ups.ToArray())
    Start-Sleep -Milliseconds 300
}

# 마우스를 가운데 Pane(빈 영역)으로 비켜 둔다. 누르지 않는다.
function Park-Mouse {
    $n = Need-Box 'active-item'
    Move-To ($n.x + $n.w / 2) ($n.y + $n.h / 2) 'park'
    Start-Sleep -Milliseconds 200
}

function Send-Keys([string]$Keys) {
    foreach ($stroke in $Keys.Split(' ', [StringSplitOptions]::RemoveEmptyEntries)) {
        $parts = $stroke.Split('-')
        $key = $parts[-1]
        $mods = @($parts | Select-Object -SkipLast 1 | ForEach-Object { [uint16]$VK[$_] })
        if (-not $VK.ContainsKey($key)) { throw "모르는 키: $key" }
        Assert-Foreground "키 $Keys"
        [WgP3.Native]::Combo([uint16[]]$mods, [uint16]$VK[$key])
        Start-Sleep -Milliseconds 150
    }
}

function Save-Window([string]$Name) {
    $png = Join-Path $out "$Name.png"
    $expected = '0x{0:X}' -f $script:hwnd.ToInt64()
    $raw = & pwsh -NoProfile -File $CaptureScript -Hwnd $expected -Out $png -Method PrintWindow
    $obj = ($raw | Out-String) | ConvertFrom-Json
    if ($obj.hwnd -ne $expected -or $obj.pid -ne $script:appPid) { throw "capture ${Name}: 고정한 창과 다른 창을 찍었다" }
    if (-not $obj.capture.ok) { throw "capture $Name 실패: $($obj.capture.error)" }
    return $obj
}

# 툴팁 하나를 띄워 잰다. 중립 위치로 먼저 옮겨 이전 툴팁을 없앤다.
function Measure-Tooltip([string]$Case, [string]$Id, [string]$Shot) {
    $neutral = Need-Box 'active-item'
    Move-To ($neutral.x + $neutral.w / 2) ($neutral.y + $neutral.h / 2) 'neutral'
    [void](Wait-NoBox 'tooltip-box' 3)
    Start-Sleep -Milliseconds 300
    $b = Need-Box $Id
    if (-not $b) { throw "${Id}: 레이아웃 경계가 없다" }
    $before = Count-Lines '^\[dev\] tooltip-shown '
    $cx = $b.x + $b.w / 2; $cy = $b.y + $b.h / 2
    Move-To $cx $cy "hover $Id"
    $t0 = UnixMs
    $line = Wait-NewLine '^\[dev\] tooltip-shown ' $before 4
    if (-not $line) { return $null }
    [void]($line -match "id=(\S+) t_ms=(\d+) mouse=([-\d.]+),([-\d.]+) rows=(.*)$")
    $r = [ordered]@{ id = $Matches[1]; delayMs = ([int64]$Matches[2] - $t0); mouseX = [double]$Matches[3]; mouseY = [double]$Matches[4]; rows = $Matches[5]; line = $line }
    $box = Wait-Box 'tooltip-box' 3
    $r.box = $box
    Start-Sleep -Milliseconds 200
    if ($Shot) { [void](Save-Window $Shot); $r.screenshot = "$Shot.png" }
    return [pscustomobject]$r
}

# ---------------------------------------------------------------- Phase 3 도우미
function Write-Utf8([string]$Path, [string]$Text) {
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}
# 앱이 다음에 열 선택 창의 결과(dev 주입, D-035). '<cancel>' 이면 취소.
function Set-Pick([string]$Path) { Write-Utf8 $pickFile $Path }
function Clear-StateFiles {
    if (Test-Path -LiteralPath $appDir) {
        Get-ChildItem -LiteralPath $appDir -File | Where-Object { $_.Name -like 'state.json*' } | Remove-Item -Force
    }
}
function Read-State {
    if (-not (Test-Path -LiteralPath $statePath)) { return $null }
    Get-Content -LiteralPath $statePath -Raw -Encoding utf8 | ConvertFrom-Json -AsHashtable -DateKind String
}
# state.json 을 증거로 복사한다.
function Save-State([string]$Name) {
    if (Test-Path -LiteralPath $statePath) { Copy-Item -LiteralPath $statePath -Destination (Join-Path $out "$Name.json") -Force }
    else { Write-Utf8 (Join-Path $out "$Name.json") '<absent>' }
}
# 폴더 목록으로 state.json 을 만든다. $Paths 순서, $Active 는 번호.
function New-StateJson([string[]]$Paths, [int]$Active = 0, $Width = $null, [hashtable]$Extra = $null) {
    $folders = @()
    $i = 0
    foreach ($p in $Paths) { $folders += [ordered]@{ id = ('00000000-0000-4000-8000-{0:d12}' -f $i); path = $p; added_at = '2026-11-01T00:00:00Z' }; $i++ }
    $win = [ordered]@{ folders = $folders; active_folder_id = $(if ($folders.Count) { $folders[$Active].id } else { $null }) }
    if ($null -ne $Width) { $win.sidebar = [ordered]@{ width = $Width } }
    $root = [ordered]@{ version = 1; windows = @($win) }
    if ($Extra) { foreach ($k in $Extra.Keys) { $root[$k] = $Extra[$k] } }
    $root | ConvertTo-Json -Depth 8
}
function Folder([string]$Rel) { Join-Path $testRoot $Rel }
# 시험 폴더 트리를 만든다(파일 하나씩 넣어 디스크 비교가 의미 있게).
function Init-TestFolders {
    # 리뷰 2회차(D-040): 이번 실행만의 폴더(run-<id>)를 새로 만들고 표지 파일을 둔다. 이미 있으면 쓰지 않고 멈춘다(지우지 않는다).
    if (Test-Path -LiteralPath $testRoot) { throw "시험 폴더 $testRoot 가 이미 있다. 지우지 않고 중단한다" }
    if (-not (Test-Path -LiteralPath $testBase)) { New-Item -ItemType Directory -Path $testBase -Force | Out-Null; $script:testBaseCreated = $true }
    New-Item -ItemType Directory -Path $testRoot | Out-Null
    Write-Utf8 $testMarker $runId
    $script:testRootCreated = $true
    foreach ($d in 'alpha', 'alpha\inner', 'beta', 'gamma', 'one\docs', 'two\docs', 'locked', 'rename-me', [string][char]0x03C3, [string][char]0x03C2) {
        New-Item -ItemType Directory -Path (Folder $d) -Force | Out-Null
        Write-Utf8 (Join-Path (Folder $d) 'readme.txt') "$d 한글 확인"
    }
    for ($n = 0; $n -lt 32; $n++) { New-Item -ItemType Directory -Path (Folder ('many\m{0:d2}' -f $n)) -Force | Out-Null }
    Write-Utf8 (Folder 'plain-file.txt') 'file'
    # 읽을 수 없는 폴더: 이 시험 폴더에만 목록 읽기 거부 ACL 을 건다.
    $acl = icacls (Folder 'locked') /deny "${env:USERNAME}:(RD)" 2>&1
    $script:results.lockedAcl = "$acl"
}
# 이번 실행이 만든 폴더(표지 파일 내용 = 이번 실행 id)만 지운다. 그 밖의 폴더·파일은 건드리지 않는다(D-040).
function Remove-TestFolders {
    if (-not $script:testRootCreated) { return }
    if (-not (Test-Path -LiteralPath $testMarker)) { throw "표지 파일이 없어 $testRoot 를 지우지 않는다" }
    if ((Get-Content -LiteralPath $testMarker -Raw -Encoding utf8).Trim() -ne $runId) { throw "표지가 이번 실행 것이 아니어서 $testRoot 를 지우지 않는다" }
    if (Test-Path -LiteralPath (Folder 'locked')) { icacls (Folder 'locked') /remove:d "${env:USERNAME}" 2>&1 | Out-Null }
    Remove-Item -LiteralPath $testRoot -Recurse -Force
    $script:testRootCreated = $false
    # 바탕 폴더는 이번 실행이 만들었고 비어 있을 때만 지운다.
    if ($script:testBaseCreated -and @(Get-ChildItem -LiteralPath $testBase -Force).Count -eq 0) { Remove-Item -LiteralPath $testBase -Force }
}
# 디스크 목록(경로·크기·수정 시각). 등록 해제 전후 비교용(R-13).
function Get-DiskListing {
    Get-ChildItem -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne 'pick.txt' } |
        # 폴더는 이름만(부모 목록의 폴더 수정 시각은 NTFS 가 늦게 갱신해 같은 상태에서도 달라진다), 파일은 크기·수정 시각·SHA-256.
        ForEach-Object {
            $rel = $_.FullName.Substring($testRoot.Length)
            if ($_.PSIsContainer) { "$rel|dir" }
            else { '{0}|{1}|{2}|{3}' -f $rel, $_.Length, $_.LastWriteTimeUtc.Ticks, (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
        } |
        Sort-Object
}

function Start-App([string]$Case, [bool]$Pick = $true) {
    $existing = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
    if ($existing.Count -gt 0) { throw "이미 실행 중인 $ProcessName 가 있다 (PID $($existing.Id -join ', ')). 닫고 다시 실행하라" }
    $script:stdout = Join-Path $out "$Case-stdout.txt"
    if (Test-Path -LiteralPath $script:stdout) { Remove-Item -LiteralPath $script:stdout -Force }
    $exePath = (Resolve-Path -LiteralPath $Exe).Path
    $appArgs = @('--dev-keymap', '--dev-layout')
    if ($Pick) { $appArgs += @('--dev-pick-folder', $pickFile) }
    $p = Start-Process -FilePath $exePath -ArgumentList $appArgs -RedirectStandardOutput $script:stdout -PassThru
    $script:launched = $p
    $script:appPid = $p.Id
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt 20 -and ((Count-Lines '^\[dev\] display-end seq=1') -eq 0 -or (Count-Lines '^\[dev\] folders-end') -eq 0)) { Start-Sleep -Milliseconds 100 }
    if ((Count-Lines '^\[dev\] folders-end') -eq 0) { throw "${Case}: 20초 안에 folders-end 가 나오지 않았다" }
    $sw.Restart()
    do {
        $script:hwnd = [WgP3.Native]::FindTitled([uint32]$p.Id, $AppTitle)
        if ($script:hwnd -ne [IntPtr]::Zero) { break }
        Start-Sleep -Milliseconds 200
    } while ($sw.Elapsed.TotalSeconds -lt 10)
    if ($script:hwnd -eq [IntPtr]::Zero) { throw "${Case}: 앱 메인 창을 찾지 못했다" }
    # 200% 배율에서 기본 창이 작업 영역보다 커서, 띄운 창(고정 HWND)만 최대화한다(Phase 2 와 같다).
    [void][WgP3.Native]::ShowWindow($script:hwnd, 3)
    Start-Sleep -Milliseconds 800
    if (-not (Wait-Box 'app-menu-button' 10)) { throw "${Case}: 레이아웃 스냅숏에 app-menu-button 이 없다" }
    Start-Sleep -Milliseconds 400
    $cap = Save-Window "$Case-start"
    $script:client = $cap.clientRect
    $script:scale = [double]$cap.scale
    return $p
}

function Stop-App($p) {
    if ($p -and -not $p.HasExited) {
        try { [void]$p.CloseMainWindow(); [void]$p.WaitForExit(5000) } catch {}
        if (-not $p.HasExited) { try { $p.Kill(); [void]$p.WaitForExit(3000) } catch {} }
    }
}

function Wants([string]$Case) { $Only.Count -eq 0 -or $Only -contains $Case }

# 사례 하나: state.json 을 $State(없으면 지움)로 두고 앱을 띄워 $Body 를 부른다.
function Run-Case([string]$Case, $State, [scriptblock]$Body, [bool]$Pick = $true, $Tmp = $null) {
    if (-not (Wants $Case)) { return }
    $res = [ordered]@{}
    Clear-StateFiles
    if ($State) { Write-Utf8 $statePath $State }
    if ($Tmp) { Write-Utf8 "$statePath.tmp" $Tmp }
    Set-Pick '<cancel>'
    $script:launched = $null
    try {
        $p = Start-App $Case $Pick
        $res.pid = $p.Id
        $res.hwnd = '0x{0:X}' -f $script:hwnd.ToInt64()
        & $Body $res $p
    }
    catch { Fail $Case $_.Exception.Message }
    finally {
        Stop-App $script:launched
        $script:launched = $null
    }
    $results.cases[$Case] = $res
}

# 가장 최근 [dev] folders 묶음: count, active, cursor, rows(index,id,name,path,missing,active).
function Get-Folders {
    $lines = @(Get-Content -LiteralPath $script:stdout -Encoding utf8 -ErrorAction SilentlyContinue)
    $start = -1
    for ($i = $lines.Count - 1; $i -ge 0; $i--) { if ($lines[$i] -match '^\[dev\] folders count=') { $start = $i; break } }
    if ($start -lt 0) { return $null }
    [void]($lines[$start] -match 'count=(\d+) active=(\S+) cursor=(\S+) workspaces=(\d+)')
    $r = [ordered]@{ count = [int]$Matches[1]; active = $Matches[2]; cursor = $Matches[3]; workspaces = [int]$Matches[4]; rows = @() }
    for ($i = $start + 1; $i -lt $lines.Count -and $lines[$i] -notmatch '^\[dev\] folders-end'; $i++) {
        if ($lines[$i] -match '^\[dev\] folder-row index=(\d+) id=(\S+) name=(.*) path=(.*) missing=(\w+) active=(\w+)$') {
            $r.rows += [pscustomobject]@{ index = [int]$Matches[1]; id = $Matches[2]; name = $Matches[3]; path = $Matches[4]; missing = $Matches[5] -eq 'true'; active = $Matches[6] -eq 'true' }
        }
    }
    [pscustomobject]$r
}
function Names { @((Get-Folders).rows | ForEach-Object { $_.name }) -join ' / ' }
function Last-Line([string]$Pattern) { $l = @(Get-Lines $Pattern); if ($l.Count) { $l[-1] } else { '<none>' } }
function Focus-Now { [void]((Last-Line '^\[dev\] focus-state ') -match 'focus=(\S+)'); $Matches[1] }
function Click-Box([string]$Name, [string]$What = $Name) { $b = Need-Box $Name; Click-At ($b.x + $b.w / 2) ($b.y + $b.h / 2) $What; Start-Sleep -Milliseconds 300 }
function RightClick-Box([string]$Name, [double]$Dx = 0) {
    $b = Need-Box $Name
    $p = ToScreen ($b.x + $b.w / 2 + $Dx) ($b.y + $b.h / 2)
    Assert-Target $p[0] $p[1] "right-click $Name"
    [WgP3.Native]::RightClick($p[0], $p[1])
    Start-Sleep -Milliseconds 400
}
# 폴더 추가 하나: 주입 경로를 쓰고 $Trigger 를 실행한 뒤 새 folder-add·pick-folder 결과 줄을 돌려준다.
function Add-Via([string]$Path, [scriptblock]$Trigger) {
    Set-Pick $Path
    $before = Count-Lines '^\[dev\] (folder-add|pick-folder result=cancel)'
    & $Trigger
    $l = Wait-NewLine '^\[dev\] (folder-add|pick-folder result=cancel)' $before 5
    Start-Sleep -Milliseconds 300
    if ($l) { $l } else { '<none>' }
}
# 메뉴 행 찾기: 최근 menu-render rows 에서 라벨의 번호(구분선 포함 번호).
function Menu-RowIndex([string]$Label) {
    $l = Last-Line '^\[dev\] menu-render '
    [void]($l -match 'rows=(.*)$')
    $rows = $Matches[1].Split("`t")
    for ($i = 0; $i -lt $rows.Count; $i++) { if ($rows[$i].Split('|')[0] -eq $Label) { return $i } }
    return -1
}
# 저장(500ms 묶어 쓰기) 끝날 때까지 기다린다.
function Wait-Save([int]$Before) { $l = Wait-NewLine '^\[dev\] state-save ' $Before 4; Start-Sleep -Milliseconds 200; if ($l) { $l } else { '<none>' } }

# 물리 px 좌표로 다루려고 이 스레드를 PER_MONITOR_AWARE_V2 로 둔다(Phase 2 와 같다).
$prevDpi = [WgP3.Native]::SetThreadDpiAwarenessContext([IntPtr]::new(-4))
$backupDone = $false
try {
    # 리뷰 1회차 ④(D-037): 사용자 파일·시험 폴더를 바꾸기 전에 기존 앱 실행을 검사하고 즉시 중단한다(Start-App 의 재검사도 둔다).
    $running = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) {
        $results.abortedBeforeChanges = $true
        throw "이미 실행 중인 $ProcessName 가 있다 (PID $($running.Id -join ', ')). 사용자 파일을 바꾸기 전에 중단한다"
    }
    # 사용자 파일 백업(옮기지 않고 복사, 끝에 되돌린다).
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    foreach ($uf in (Get-UserFiles)) { Copy-Item -LiteralPath $uf.FullName -Destination (Join-Path $backupDir $uf.Name) -Force }
    $backupDone = $true
    if (Test-Path -LiteralPath $keymapPath) { Remove-Item -LiteralPath $keymapPath -Force }
    Init-TestFolders

    # ================================================================ empty: R-15 A-16.1, R-12 타이틀, R-10 Open Project 버튼
    Run-Case 'empty' $null {
        param($res, $p)
        $f = Get-Folders
        Check 'empty' 'A-16.1' '등록 폴더 없음: 목록 비어 있음' '0' $f.count ($f.count -eq 0)
        Check 'empty' 'A-16.1' '빈 상태 문구 경계' 'project-empty-text' $(if (Get-Box 'project-empty-text') { 'present' } else { 'absent' }) ([bool](Get-Box 'project-empty-text'))
        Check 'empty' 'A-16.1' 'Open Project 버튼 경계' 'project-empty-open' $(if (Get-Box 'project-empty-open') { 'present' } else { 'absent' }) ([bool](Get-Box 'project-empty-open'))
        Check 'empty' 'R-28' '파일 없음 → 빈 상태(source=none), 알림 없음' 'source=none, notification 0' ("{0}, notification {1}" -f (Last-Line '^\[dev\] state-load'), (Count-Lines '^\[dev\] notification text=')) (((Last-Line '^\[dev\] state-load') -match 'source=none') -and (Count-Lines '^\[dev\] notification text=') -eq 0)
        [void](Save-Window 'empty-screen')
        $res.screenshot = 'empty-screen.png (타이틀 바 Open Recent Project, 프로젝트 패널 빈 상태 문구·버튼)'
        $tl = Last-Line '^\[dev\] title '
        Check 'empty' 'A-13.9·L-227' '폴더 없음 → 타이틀 Open Recent Project' '[dev] title text=Open Recent Project placeholder=true' $tl ($tl -ceq '[dev] title text=Open Recent Project placeholder=true')
        # A-16.1 버튼 → 선택 창(주입)
        $l = Add-Via (Folder 'alpha') { Click-Box 'project-empty-open' 'Open Project' }
        Check 'empty' 'A-16.1·A-13.1' 'Open Project 버튼 → 선택 창 → 등록' 'folder-add result=added index=0' $l ($l -match 'result=added index=0')
        $f = Get-Folders
        Check 'empty' 'A-13.3' '등록한 폴더 활성' 'active=0' "active=$($f.active)" ($f.active -eq '0')
        Check 'empty' 'A-15.6·A-13.3' '루트 줄(project-root-row) 경계' 'present' $(if (Wait-Box 'project-root-label' 3) { 'present' } else { 'absent' }) ([bool](Get-Box 'project-root-label'))
        [void](Save-Window 'empty-after-open-project')
    }

    # ================================================================ add: R-10 진입 4가지·중복·대소문자·끝 \·없는 경로·파일·읽기 불가·취소
    Run-Case 'add' $null {
        param($res, $p)
        $l = Add-Via (Folder 'alpha') { Send-Keys 'ctrl-k ctrl-o' }
        Check 'add' 'A-13.1·A-18.4' 'Ctrl+K Ctrl+O → 등록' 'result=added index=0' $l ($l -match 'result=added index=0')
        $l = Add-Via (Folder 'beta') { Click-Box 'sidebar-btn-folder-add' 'footer add' }
        Check 'add' 'A-13.1' '사이드바 푸터 폴더 추가 버튼 → 맨 아래에 등록' 'result=added index=1' $l ($l -match 'result=added index=1')
        $l = Add-Via (Folder 'gamma') { Send-Keys 'f10 right'; Start-Sleep -Milliseconds 300; Send-Keys 'down enter' }
        Check 'add' 'A-13.1' '☰ File → Open Folder... → 등록' 'result=added index=2' $l ($l -match 'result=added index=2')
        Check 'add' 'R-8' 'File 메뉴 첫 항목' 'Open Folder...|Ctrl-K Ctrl-O' (Last-Line '^\[dev\] menu-render .*name=File') ((Last-Line '^\[dev\] menu-render .*name=File') -match 'rows=Open Folder\.\.\.\|Ctrl-K Ctrl-O')
        $f = Get-Folders
        Check 'add' 'A-13.1' '순서·활성(맨 아래가 활성)' 'alpha / beta / gamma, active=2' ("{0}, active={1}" -f (Names), $f.active) (((Names) -eq 'alpha / beta / gamma') -and $f.active -eq '2')
        $up = (Folder 'alpha').ToUpper() + '\'
        $l = Add-Via $up { Send-Keys 'ctrl-k ctrl-o' }
        Check 'add' 'A-13.2·A-16.6' "대소문자·끝 \ 다른 같은 경로($up) → 새 항목 없이 기존 활성" 'result=existing index=0' $l ($l -match 'result=existing index=0')
        $f = Get-Folders
        Check 'add' 'A-13.2' '중복 뒤 개수·활성' 'count=3 active=0' "count=$($f.count) active=$($f.active)" ($f.count -eq 3 -and $f.active -eq '0')
        $cases = @(
            @{ p = (Folder 'no-such-folder'); r = 'not-found'; what = '없는 경로' },
            @{ p = (Folder 'plain-file.txt'); r = 'not-dir'; what = '파일 경로' },
            @{ p = (Folder 'locked'); r = 'read-dir-failed'; what = '읽을 수 없는 폴더(목록 읽기 거부 ACL)' }
        )
        foreach ($c in $cases) {
            $nb = Count-Lines '^\[dev\] notification text=Cannot open this folder\.'
            $l = Add-Via $c.p { Send-Keys 'ctrl-k ctrl-o' }
            $n = Count-Lines '^\[dev\] notification text=Cannot open this folder\.'
            Check 'add' 'A-16.4' "$($c.what) → 등록 안 함 + 알림 'Cannot open this folder.'" "rejected reason=$($c.r), 알림 +1" "$l, 알림 +$($n - $nb)" (($l -match "result=rejected reason=$($c.r)") -and $n -eq $nb + 1)
            if ($c.r -eq 'not-found') { Start-Sleep -Milliseconds 300; [void](Save-Window 'add-notification') }
        }
        $l = Add-Via '<cancel>' { Send-Keys 'ctrl-k ctrl-o' }
        Check 'add' 'A-13.8' '취소 → 아무 일도 없음' 'pick-folder result=cancel' $l ($l -match 'result=cancel')
        $f = Get-Folders
        Check 'add' 'A-16.4·A-13.8' '거부·취소 뒤 개수' '3' $f.count ($f.count -eq 3)
        Start-Sleep -Milliseconds 900
        Save-State 'add-state'
        $s = Read-State
        $w = $s.windows[0]
        $ids = @($w.folders | ForEach-Object { $_.id })
        Check 'add' 'R-28 A-22' 'state.json folders 경로·순서' 'alpha, beta, gamma' (@($w.folders | ForEach-Object { Split-Path -Leaf $_.path }) -join ', ') ((@($w.folders | ForEach-Object { Split-Path -Leaf $_.path }) -join ', ') -eq 'alpha, beta, gamma')
        Check 'add' 'A-22.3' 'id 는 UUID v4' 'xxxxxxxx-xxxx-4xxx-[89ab]xxx-xxxxxxxxxxxx' ($ids -join ' ') (@($ids | Where-Object { $_ -match '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' }).Count -eq 3)
        Check 'add' 'A-22.5' 'added_at ISO 8601 UTC' 'YYYY-MM-DDTHH:MM:SSZ' (@($w.folders | ForEach-Object { $_.added_at }) -join ' ') (@($w.folders | Where-Object { $_.added_at -match '^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$' }).Count -eq 3)
        Check 'add' 'A-22.6' 'active_folder_id = alpha 의 id' $ids[0] $w.active_folder_id ($w.active_folder_id -eq $ids[0])
        Check 'add' 'A-28' 'path 정규화(끝 \ 없음, 드라이브 대문자)' (Folder 'alpha') $w.folders[0].path ($w.folders[0].path -ceq (Folder 'alpha'))
    }

    # ================================================================ items: R-11 모양·상태, R-15 없는 경로·겹침
    $itemsState = New-StateJson @((Folder 'alpha'), (Folder 'one\docs'), (Folder 'two\docs'), (Folder 'vanished'), (Folder 'alpha\inner')) 0
    Run-Case 'items' $itemsState {
        param($res, $p)
        $f = Get-Folders
        Check 'items' 'A-12.6' '같은 이름 폴더 → 이름 · 위 폴더' 'docs · one / docs · two' (($f.rows | Select-Object -Skip 1 -First 2 | ForEach-Object name) -join ' / ') ((($f.rows | Select-Object -Skip 1 -First 2 | ForEach-Object name) -join ' / ') -eq 'docs · one / docs · two')
        Check 'items' 'A-12.7·A-16.2' '없는 경로 → missing' 'vanished missing=true, 나머지 false' (($f.rows | ForEach-Object { "$($_.name)=$($_.missing)" }) -join ' ') (($f.rows[3].missing) -and -not ($f.rows | Where-Object { $_.index -ne 3 -and $_.missing }))
        Check 'items' 'A-16.5' '안쪽·바깥 폴더(alpha, alpha\inner) 독립 항목' 'alpha, inner 둘 다 있음' (Names) ((Names) -match '^alpha / .* / inner$')
        $r0 = Need-Box 'folder-row-00'
        Check 'items' 'A-11.3·A-32.12' '항목 줄 높이 31' '31' $r0.h (Near $r0.h 31 0.5)
        $sb = Need-Box 'sidebar'
        Check 'items' 'A-11.3' '항목 줄 폭 = 사이드바 폭 − 오른쪽 테두리 1' ($sb.w - 1) $r0.w (Near $r0.w ($sb.w - 1) 1)
        $rows = @(0..4 | ForEach-Object { Need-Box ('folder-row-{0:d2}' -f $_) })
        Check 'items' 'A-11.3' '줄 간격 31(빈틈 없음)' '31' ($rows[1].y - $rows[0].y) (Near ($rows[1].y - $rows[0].y) 31 0.5)
        [void](Save-Window 'items-active0')
        # hover: 줄 2 위에 올리고 찍는다(툴팁 없음 A-12.8).
        $b = Need-Box 'folder-row-02'
        $tb = Count-Lines '^\[dev\] tooltip-shown '
        Move-To ($b.x + $b.w / 2) ($b.y + $b.h / 2) 'hover row 2'
        Start-Sleep -Milliseconds 2000
        [void](Save-Window 'items-hover-row2')
        Check 'items' 'A-12.8' '항목 hover 2초 → 툴팁 없음' '0' ((Count-Lines '^\[dev\] tooltip-shown ') - $tb) ((Count-Lines '^\[dev\] tooltip-shown ') -eq $tb)
        # 키보드 포커스 둘레(A-12.5): 사이드바 포커스 + Down 두 번 → 커서 1.
        Park-Mouse
        Send-Keys 'ctrl-alt-semicolon'
        Send-Keys 'down down'
        $f = Get-Folders
        Check 'items' 'A-17.3·A-12.5' '사이드바 포커스, Down×2 → 커서 1(활성 0 은 그대로)' 'cursor=1 active=0 focus=sidebar' ("cursor={0} active={1} focus={2}" -f $f.cursor, $f.active, (Focus-Now)) ($f.cursor -eq '1' -and $f.active -eq '0' -and (Focus-Now) -eq 'sidebar')
        [void](Save-Window 'items-keyboard-focus-row1')
        # 없는 경로 활성화 → 안내 + Remove 버튼(A-16.2)
        Click-Box 'folder-row-03' 'missing row'
        Check 'items' 'A-16.2·A-12.7' '없는 경로 활성 → This folder no longer exists. + Remove' 'project-missing-text, project-missing-remove' ("{0}, {1}" -f [bool](Wait-Box 'project-missing-text'), [bool](Get-Box 'project-missing-remove')) ([bool](Get-Box 'project-missing-text') -and [bool](Get-Box 'project-missing-remove'))
        [void](Save-Window 'items-missing-active')
        $l = Count-Lines '^\[dev\] folder-remove '
        Click-Box 'project-missing-remove' 'missing Remove button'
        $f = Get-Folders
        Check 'items' 'A-16.2' 'Remove 버튼 → 해제, 아래 항목(inner) 활성' 'count=4, active=3(inner)' ("count={0}, active={1}({2})" -f $f.count, $f.active, (($f.rows | Where-Object active).name)) ($f.count -eq 4 -and $f.active -eq '3' -and (($f.rows | Where-Object active).name) -eq 'inner')
    }

    # ================================================================ scroll: A-16.7 개수 제한 없음, 세로 스크롤
    $many = @(0..31 | ForEach-Object { Folder ('many\m{0:d2}' -f $_) })
    Run-Case 'scroll' (New-StateJson $many 0) {
        param($res, $p)
        $f = Get-Folders
        Check 'scroll' 'A-16.7' '폴더 32개 등록' '32' $f.count ($f.count -eq 32)
        $sc0 = Count-Lines '^\[dev\] sidebar-scroll '
        $list = Need-Box 'sidebar-list'
        $pt = ToScreen ($list.x + $list.w / 2) ($list.y + $list.h / 2)
        Assert-Target $pt[0] $pt[1] 'wheel sidebar list'
        [WgP3.Native]::Wheel($pt[0], $pt[1], -360)
        Start-Sleep -Milliseconds 600
        $sl = Last-Line '^\[dev\] sidebar-scroll '
        Check 'scroll' 'A-16.7' '목록 휠 → 세로 스크롤(스크롤 위치 음수)' 'offset_y < 0' $sl (((Count-Lines '^\[dev\] sidebar-scroll ') -gt $sc0) -and $sl -match 'offset_y=-\d')
        [void](Save-Window 'scroll-after-wheel')
    }

    # ================================================================ switch: R-12 활성화(클릭·Enter·Up/Down), Workspace 엔티티 유지, 포커스, 타이틀
    Run-Case 'switch' (New-StateJson @((Folder 'alpha'), (Folder 'beta'), (Folder 'gamma')) 0) {
        param($res, $p)
        $ws0 = (Last-Line '^\[dev\] folder-activate ')
        Check 'switch' 'R-28' '시작 때 활성 alpha' 'active=0' "active=$((Get-Folders).active)" ((Get-Folders).active -eq '0')
        $b = Count-Lines '^\[dev\] folder-activate '
        Click-Box 'folder-row-01' 'click beta'
        $a1 = Wait-NewLine '^\[dev\] folder-activate ' $b 3
        Check 'switch' 'A-13.3' '클릭 → beta 활성, Workspace 새로 만듦' 'index=1 created=true' $a1 ($a1 -match 'index=1 .*created=true')
        Check 'switch' 'A-15.6' '전환 뒤 포커스 = 사이드바' 'sidebar' (Focus-Now) ((Focus-Now) -eq 'sidebar')
        Start-Sleep -Milliseconds 300
        [void](Save-Window 'switch-beta')
        $res.titleShot = 'switch-beta.png: 타이틀 바 beta, 프로젝트 패널 루트 줄 beta'
        $b = Count-Lines '^\[dev\] folder-activate '
        Click-Box 'folder-row-00' 'click alpha'
        $a0 = Wait-NewLine '^\[dev\] folder-activate ' $b 3
        [void]($a0 -match 'workspace=(\S+)'); $w0 = $Matches[1]
        Check 'switch' 'A-15.2·G-002' 'alpha 로 돌아옴 → 같은 Workspace 엔티티(새로 만들지 않음)' 'created=false' $a0 ($a0 -match 'index=0 .*created=false')
        $b = Count-Lines '^\[dev\] folder-activate '
        Click-Box 'folder-row-01' 'click beta again'
        $a1b = Wait-NewLine '^\[dev\] folder-activate ' $b 3
        [void]($a1 -match 'workspace=(\S+)'); $w1 = $Matches[1]
        Check 'switch' 'A-15.2' 'beta 로 다시 → 처음 만든 엔티티 그대로' "workspace=$w1 created=false" $a1b ($a1b -match "workspace=$([regex]::Escape($w1)) created=false")
        Check 'switch' 'A-15.2' 'Workspace 엔티티 수(폴더마다 하나, 메모리에 남음)' '2' (Get-Folders).workspaces ((Get-Folders).workspaces -eq 2)
        # 키보드: 커서 = 1(클릭한 항목). Down → 2, Enter → gamma 활성.
        Send-Keys 'down enter'
        $f = Get-Folders
        Check 'switch' 'A-17.3·A-17.4' 'Down, Enter → gamma 활성, 포커스 사이드바' 'active=2 cursor=2 focus=sidebar' ("active={0} cursor={1} focus={2}" -f $f.active, $f.cursor, (Focus-Now)) ($f.active -eq '2' -and $f.cursor -eq '2' -and (Focus-Now) -eq 'sidebar')
        Send-Keys 'down'
        Check 'switch' 'A-17.3' '끝에서 Down → 처음으로 순환(판단, I-518)' 'cursor=0' "cursor=$((Get-Folders).cursor)" ((Get-Folders).cursor -eq '0')
        Send-Keys 'up up enter'
        $f = Get-Folders
        Check 'switch' 'A-17.3·A-17.4' 'Up×2, Enter → beta 활성' 'active=1' "active=$($f.active)" ($f.active -eq '1')
        Start-Sleep -Milliseconds 900
        Save-State 'switch-state'
        $s = Read-State
        Check 'switch' 'R-28' 'state.json active_folder_id = beta' $s.windows[0].folders[1].id $s.windows[0].active_folder_id ($s.windows[0].active_folder_id -eq $s.windows[0].folders[1].id)
        # 40자 말줄임(L-88) 은 이름이 긴 폴더로 확인한다.
    }
    $long = Folder ('a' * 45)
    New-Item -ItemType Directory -Path $long -Force | Out-Null
    Run-Case 'title' (New-StateJson @($long) 0) {
        param($res, $p)
        [void](Save-Window 'title-long-name')
        $res.note = "폴더 이름 45자 → 타이틀 바 40자 + … (스크린샷 title-long-name.png), 사이드바는 폭에 맞춰 말줄임"
        $want = ('a' * 40) + [char]0x2026
        $tl = Last-Line '^\[dev\] title '
        Check 'title' 'L-88·A-13.9' '45자 이름 → 타이틀 40자 + …' "[dev] title text=$want placeholder=false" $tl ($tl -ceq "[dev] title text=$want placeholder=false")
    }

    # ================================================================ remove: R-13 우클릭 Remove·Delete, 활성 이동, 디스크 그대로
    Run-Case 'remove' (New-StateJson @((Folder 'alpha'), (Folder 'beta'), (Folder 'gamma'), (Folder 'one\docs')) 1) {
        param($res, $p)
        $disk0 = Get-DiskListing
        Set-Content -LiteralPath (Join-Path $out 'remove-disk-before.txt') -Value $disk0 -Encoding utf8
        RightClick-Box 'folder-row-01'
        $o = Last-Line '^\[dev\] context-menu-open '
        Check 'remove' 'I-667·A-12.10' '가운데 항목 우클릭 메뉴' 'Move Up|enabled, Move Down|enabled, ---, Remove|enabled' $o ($o -match "rows=Move Up\|enabled`tMove Down\|enabled`t---`tRemove\|enabled$")
        [void](Save-Window 'remove-context-menu')
        Click-Box 'ctx-menu-row-3' 'Remove'
        $f = Get-Folders
        Check 'remove' 'A-13.4 ①·A-13.5' '활성 beta 를 우클릭 Remove → 아래 항목(gamma) 활성' 'alpha / gamma / docs, active=1(gamma)' ("{0}, active={1}" -f (Names), $f.active) (((Names) -eq 'alpha / gamma / docs') -and $f.active -eq '1')
        Check 'remove' 'A-14.4' '확인창 없음(대화상자 없음)' '0' ([int]([WgP3.Native]::FindDialog([uint32]$p.Id) -ne [IntPtr]::Zero)) ([WgP3.Native]::FindDialog([uint32]$p.Id) -eq [IntPtr]::Zero)
        # Delete: 사이드바 포커스, 커서를 맨 끝(docs)으로 → Delete. 활성(gamma)은 그대로.
        Park-Mouse
        Send-Keys 'ctrl-alt-semicolon up delete'
        $f = Get-Folders
        Check 'remove' 'A-13.4 ②·A-17.5' '사이드바 Delete → 커서 항목(docs) 해제, 활성 그대로' 'alpha / gamma, active=1' ("{0}, active={1}" -f (Names), $f.active) (((Names) -eq 'alpha / gamma') -and $f.active -eq '1')
        Check 'remove' 'A-17.5' 'Delete 처리기' 'action-handled name=project_panel::RemoveFromProject by=workbench' (Last-Line 'action-handled name=project_panel::RemoveFromProject') ((Last-Line 'action-handled name=project_panel::RemoveFromProject') -match 'by=workbench focus=sidebar')
        # 맨 아래 활성 항목 해제 → 위 항목 활성(A-13.5)
        RightClick-Box 'folder-row-01'
        Click-Box 'ctx-menu-row-3' 'Remove last'
        $f = Get-Folders
        Check 'remove' 'A-13.5' '맨 아래 활성 해제 → 위 항목 활성' 'alpha, active=0' ("{0}, active={1}" -f (Names), $f.active) (((Names) -eq 'alpha') -and $f.active -eq '0')
        RightClick-Box 'folder-row-00'
        $o = Last-Line '^\[dev\] context-menu-open '
        Check 'remove' 'I-934' '폴더 하나면 Move Up·Move Down 없음' 'rows=Remove|enabled' $o ($o -match 'rows=Remove\|enabled$')
        Click-Box 'ctx-menu-row-0' 'Remove only'
        $f = Get-Folders
        Check 'remove' 'A-13.5·A-16.1' '모두 해제 → 빈 상태' 'count=0, project-empty-text' ("count={0}, {1}" -f $f.count, [bool](Wait-Box 'project-empty-text')) ($f.count -eq 0 -and [bool](Get-Box 'project-empty-text'))
        [void](Save-Window 'remove-all-empty')
        $disk1 = Get-DiskListing
        Set-Content -LiteralPath (Join-Path $out 'remove-disk-after.txt') -Value $disk1 -Encoding utf8
        $same = (($disk0 -join "`n") -ceq ($disk1 -join "`n"))
        Check 'remove' 'A-13.4·A-14.3' '디스크 폴더·파일 목록(경로·크기·수정 시각) 해제 전후 같음' "$($disk0.Count) 줄 같음" "$($disk1.Count) 줄, same=$same" $same
        Start-Sleep -Milliseconds 900
        Save-State 'remove-state'
        $s = Read-State
        Check 'remove' 'R-28' 'state.json folders 비고 active null' 'folders=0, active=null' ("folders={0}, active={1}" -f @($s.windows[0].folders).Count, $s.windows[0].active_folder_id) (@($s.windows[0].folders).Count -eq 0 -and $null -eq $s.windows[0].active_folder_id)
    }

    # ================================================================ order: R-14 Move Up·Move Down, 비활성, 메뉴 없는 곳, 저장·복원
    $orderState = New-StateJson @((Folder 'alpha'), (Folder 'beta'), (Folder 'gamma')) 0
    Run-Case 'order' $orderState {
        param($res, $p)
        RightClick-Box 'folder-row-00'
        $o = Last-Line '^\[dev\] context-menu-open '
        Check 'order' 'I-940' '맨 위 항목: Move Up 비활성' 'Move Up|disabled, Move Down|enabled' $o ($o -match "rows=Move Up\|disabled`tMove Down\|enabled`t---`tRemove\|enabled$")
        [void](Save-Window 'order-menu-top')
        $mb = Need-Box 'ctx-menu-box'
        Check 'order' 'I-313' '메뉴 상자 최소 폭 200 + 테두리 2' '>= 202' $mb.w ($mb.w -ge 201.5)
        $r1 = Need-Box 'ctx-menu-row-1'; $r2 = Need-Box 'ctx-menu-row-2'
        Check 'order' 'I-318' '구분선 높이 1, 위아래 6' 'sep h=1, 다음 항목까지 13' ("h={0}, gap={1}" -f $r2.h, ((Need-Box 'ctx-menu-row-3').y - ($r1.y + $r1.h))) ((Near $r2.h 1 0.5) -and (Near ((Need-Box 'ctx-menu-row-3').y - ($r1.y + $r1.h)) 13 0.6))
        Click-Box 'ctx-menu-row-0' 'disabled Move Up'
        Check 'order' 'I-940' '비활성 Move Up 누름 → 실행 없음, 메뉴 그대로' 'exec 0, order same' ("exec {0}, {1}" -f (Count-Lines 'context-menu-exec'), (Names)) ((Count-Lines 'context-menu-exec') -eq 0 -and (Names) -eq 'alpha / beta / gamma')
        Click-Box 'ctx-menu-row-1' 'Move Down'
        Check 'order' 'A-13.6' 'alpha Move Down → beta / alpha / gamma' 'beta / alpha / gamma' (Names) ((Names) -eq 'beta / alpha / gamma')
        RightClick-Box 'folder-row-02'
        $o = Last-Line '^\[dev\] context-menu-open '
        Check 'order' 'I-940' '맨 아래 항목: Move Down 비활성' 'Move Up|enabled, Move Down|disabled' $o ($o -match "rows=Move Up\|enabled`tMove Down\|disabled")
        Click-Box 'ctx-menu-row-0' 'Move Up gamma'
        Check 'order' 'A-13.6' 'gamma Move Up → beta / gamma / alpha' 'beta / gamma / alpha' (Names) ((Names) -eq 'beta / gamma / alpha')
        # 키로 메뉴 다루기(I-517): 우클릭 → Down(첫 활성 항목) → Enter.
        RightClick-Box 'folder-row-01'
        Send-Keys 'down enter'
        Check 'order' 'I-517·I-518' '메뉴 Down, Enter → 첫 활성 항목(Move Up) 실행' 'gamma / beta / alpha' (Names) ((Names) -eq 'gamma / beta / alpha')
        Check 'order' 'I-309' '메뉴 실행 뒤 포커스 복원' 'center' (Focus-Now) ((Focus-Now) -eq 'center')
        RightClick-Box 'folder-row-01'
        Send-Keys 'escape'
        Check 'order' 'I-519' 'Escape → 닫힘, 실행 없음' 'reason=cancel' (Last-Line 'context-menu-close') ((Last-Line 'context-menu-close') -match 'reason=cancel')
        # 메뉴 없는 곳(02 11.6절, I-937·I-939)
        $nb = Count-Lines '^\[dev\] context-menu-open '
        $list = Need-Box 'sidebar-list'
        $pt = ToScreen ($list.x + $list.w / 2) ($list.y + $list.h - 40)
        Assert-Target $pt[0] $pt[1] 'right-click empty'
        [WgP3.Native]::RightClick($pt[0], $pt[1]); Start-Sleep -Milliseconds 400
        RightClick-Box 'sidebar-btn-folder-add'
        Check 'order' 'I-937·I-939' '사이드바 빈 공간·폴더 추가 버튼 우클릭 → 메뉴 없음' '0' ((Count-Lines '^\[dev\] context-menu-open ') - $nb) ((Count-Lines '^\[dev\] context-menu-open ') -eq $nb)
        Start-Sleep -Milliseconds 900
        Save-State 'order-state'
        $s = Read-State
        $leafs = @($s.windows[0].folders | ForEach-Object { Split-Path -Leaf $_.path }) -join ' / '
        Check 'order' 'A-13.6·A-22.2' 'state.json folders 순서' 'gamma / beta / alpha' $leafs ($leafs -eq 'gamma / beta / alpha')
    }
    # 같은 state.json 으로 다시 띄워 순서 복원(R-14·R-28).
    if (Wants 'order') {
        $saved = Get-Content -LiteralPath (Join-Path $out 'order-state.json') -Raw
        Run-Case 'order-restart' $saved {
            param($res, $p)
            Check 'order-restart' 'A-13.6·R-28' '다시 시작 → 순서 복원' 'gamma / beta / alpha' (Names) ((Names) -eq 'gamma / beta / alpha')
            [void](Save-Window 'order-restart')
        }
    }

    # ================================================================ keys: R-16 A-17.1·A-17.2·A-17.7·A-17.8, A-11.8·A-11.9 배치, L-251
    Run-Case 'keys' (New-StateJson @((Folder 'alpha'), (Folder 'beta')) 0) {
        param($res, $p)
        function SB { [void]((Last-Line '^\[dev\] sidebar ') -match 'open=(\w+) dock_open=(\w+) focus=(\S+)'); "open=$($Matches[1]) focus=$($Matches[3])" }
        Check 'keys' 'A-11.7' '처음에는 사이드바 열림, 포커스 center' 'sidebar present, center' ("{0}, {1}" -f [bool](Get-Box 'sidebar'), (Focus-Now)) ([bool](Get-Box 'sidebar') -and (Focus-Now) -eq 'center')
        Send-Keys 'ctrl-alt-j'
        Check 'keys' 'A-17.1' '열림 + 포커스 center 에서 Ctrl+Alt+J → 닫힘, 포커스 center 그대로' 'open=false focus=center' (SB) ((SB) -eq 'open=false focus=center')
        [void](Wait-NoBox 'sidebar' 3)
        $t = Need-Box 'status-btn-sidebar-toggle'; $a = Need-Box 'status-btn-folder-add'; $pp = Need-Box 'status-btn-project-panel'
        Check 'keys' 'A-11.9' '사이드바 닫힘: 상태 표시줄 왼쪽 순서 사이드바 토글 → 폴더 추가 → 프로젝트 패널 토글' 'x 증가' ("{0:N1} < {1:N1} < {2:N1}" -f $t.x, $a.x, $pp.x) ($t.x -lt $a.x -and $a.x -lt $pp.x)
        [void](Save-Window 'keys-sidebar-closed')
        $tt = Measure-Tooltip 'keys' 'status-btn-sidebar-toggle' 'keys-tooltip-open-folder-sidebar'
        Check 'keys' 'L-251·L-270' '닫힌 사이드바 토글 툴팁' 'Open Folder Sidebar|Ctrl-Alt-J' $(if ($tt) { $tt.rows } else { '<none>' }) ($tt -and $tt.rows -ceq 'Open Folder Sidebar|Ctrl-Alt-J')
        $tt = Measure-Tooltip 'keys' 'status-btn-folder-add' ''
        Check 'keys' 'L-230' '상태 표시줄 폴더 추가 툴팁' 'Add Project|Ctrl-K Ctrl-O' $(if ($tt) { $tt.rows } else { '<none>' }) ($tt -and $tt.rows -ceq 'Add Project|Ctrl-K Ctrl-O')
        Park-Mouse
        Send-Keys 'ctrl-alt-j'
        Check 'keys' 'A-17.1' '닫힘에서 Ctrl+Alt+J → 열림 + 포커스 사이드바' 'open=true focus=sidebar' (SB) ((SB) -eq 'open=true focus=sidebar')
        Check 'keys' 'A-11.8' '사이드바 열림: 상태 표시줄 왼쪽은 프로젝트 패널 토글만' 'status-btn-sidebar-toggle 없음' $(if (Wait-NoBox 'status-btn-sidebar-toggle' 2) { '없음' } else { '있음' }) (-not (Get-Box 'status-btn-sidebar-toggle'))
        Send-Keys 'ctrl-alt-j'
        Check 'keys' 'A-17.1·I-100' '사이드바 포커스에서 Ctrl+Alt+J → 닫힘, 이전 포커스(center)로' 'open=false focus=center' (SB) ((SB) -eq 'open=false focus=center')
        Send-Keys 'ctrl-alt-semicolon'
        Check 'keys' 'A-17.2' '닫힘에서 Ctrl+Alt+; → 열고 포커스' 'open=true focus=sidebar' (SB) ((SB) -eq 'open=true focus=sidebar')
        Send-Keys 'ctrl-alt-semicolon'
        Check 'keys' 'A-17.2·I-099' '사이드바 포커스에서 Ctrl+Alt+; → 이전 포커스로, 닫지 않음' 'open=true focus=center' (SB) ((SB) -eq 'open=true focus=center')
        Send-Keys 'ctrl-shift-e'
        Check 'keys' 'A-17.8' 'Ctrl+Shift+E → 프로젝트 패널 포커스' 'project_panel' (Focus-Now) ((Focus-Now) -eq 'project_panel')
        Send-Keys 'ctrl-alt-semicolon'
        Check 'keys' 'A-17.2' '패널에서 Ctrl+Alt+; → 사이드바' 'sidebar' (Focus-Now) ((Focus-Now) -eq 'sidebar')
        Send-Keys 'ctrl-alt-semicolon'
        Check 'keys' 'A-17.2' '다시 Ctrl+Alt+; → 이전 포커스(프로젝트 패널)로' 'project_panel' (Focus-Now) ((Focus-Now) -eq 'project_panel')
        Send-Keys 'ctrl-shift-e'
        Check 'keys' 'A-17.8·I-098' '패널에서 Ctrl+Shift+E → center, Dock 은 열린 채' 'center, dock present' ("{0}, dock {1}" -f (Focus-Now), [bool](Get-Box 'dock')) ((Focus-Now) -eq 'center' -and [bool](Get-Box 'dock'))
        # 리뷰 1회차 ⑥(D-037): 사이드바에 포커스가 없을 때(패널) Ctrl+Alt+J 로 닫으면 가운데 Pane 으로.
        Send-Keys 'ctrl-shift-e'
        $pf = Focus-Now
        Send-Keys 'ctrl-alt-j'
        Check 'keys' 'R-16·A-17.1 (D-037 ⑥)' '패널 포커스에서 Ctrl+Alt+J 로 닫기 → 가운데 Pane' 'before=project_panel, open=false focus=center' ("before={0}, {1}" -f $pf, (SB)) ($pf -eq 'project_panel' -and (SB) -eq 'open=false focus=center')
        Send-Keys 'ctrl-alt-j'
        Send-Keys 'ctrl-alt-semicolon'
        Send-Keys 'ctrl-b'
        Check 'keys' 'A-17.7' 'Ctrl+B → Dock 닫힘' 'dock 없음' $(if (Wait-NoBox 'dock' 2) { '없음' } else { '있음' }) (-not (Get-Box 'dock'))
        Send-Keys 'ctrl-shift-e'
        Check 'keys' 'A-17.8' 'Dock 닫힘에서 Ctrl+Shift+E → Dock 열고 패널 포커스' 'project_panel, dock present' ("{0}, dock {1}" -f (Focus-Now), [bool](Wait-Box 'dock' 2)) ((Focus-Now) -eq 'project_panel' -and [bool](Get-Box 'dock'))
        # 상태 표시줄·푸터 버튼 누름(A-11.8): 푸터 사이드바 토글 → 닫힘, 상태 표시줄 사이드바 토글 → 열림.
        Click-Box 'sidebar-btn-toggle' 'footer sidebar toggle'
        Check 'keys' 'A-11.8' '푸터 사이드바 토글 누름 → 닫힘' 'open=false' (SB) ((SB) -match '^open=false')
        Click-Box 'status-btn-sidebar-toggle' 'status sidebar toggle'
        Check 'keys' 'A-11.9' '상태 표시줄 사이드바 토글 누름 → 열림' 'open=true' (SB) ((SB) -match '^open=true')
        # ☰ 메뉴가 열린 채 Ctrl+Alt+; → 사이드바, 다시 Ctrl+Alt+; → 닫힌 메뉴가 아니라 가운데 Pane 으로(돌아갈 자리 확인).
        Park-Mouse
        Send-Keys 'escape'
        Send-Keys 'f10'
        Send-Keys 'ctrl-alt-semicolon'
        Check 'keys' 'A-17.2' '메뉴 열린 채 Ctrl+Alt+; → 사이드바 포커스' 'sidebar' (Focus-Now) ((Focus-Now) -eq 'sidebar')
        Send-Keys 'ctrl-alt-semicolon'
        Check 'keys' 'A-17.2' '다시 Ctrl+Alt+; → 돌아갈 자리(메뉴)가 닫혔으니 center' 'center' (Focus-Now) ((Focus-Now) -eq 'center')
    }

    # ================================================================ menus: 02 9.2절 File·View 항목과 동작(D-031 ④ Phase 3 이월)
    Run-Case 'menus' (New-StateJson @((Folder 'alpha')) 0) {
        param($res, $p)
        $bf = Count-Lines '^\[dev\] menu-render .*name=File'
        Send-Keys 'f10 right'
        # Phase 4 다시 돌리기(p4-rerun): 앱이 커져 디버그 빌드 그리기가 느려졌다. 줄이 나올 때까지(최대 3초) 기다린다.
        [void](Wait-NewLine '^\[dev\] menu-render .*name=File' $bf 3)
        $file = Last-Line '^\[dev\] menu-render .*name=File'
        Check 'menus' 'R-8 9.2' 'File 메뉴' "Open Folder...|Ctrl-K Ctrl-O, ---, Close Window|Ctrl-Shift-W" $file ($file -match "rows=Open Folder\.\.\.\|Ctrl-K Ctrl-O`t---`tClose Window\|Ctrl-Shift-W$")
        Send-Keys 'right'
        Start-Sleep -Milliseconds 300
        $view = Last-Line '^\[dev\] menu-render .*name=View'
        Check 'menus' 'R-8 9.2' 'View 메뉴' 'Toggle Left Dock|Ctrl-B, Toggle Folder Sidebar|Ctrl-Alt-J, Focus Folder Sidebar|Ctrl-Alt-;, ---, Project Panel|Ctrl-Shift-E' $view ($view -match "rows=Toggle Left Dock\|Ctrl-B`tToggle Folder Sidebar\|Ctrl-Alt-J`tFocus Folder Sidebar\|Ctrl-Alt-;`t---`tProject Panel\|Ctrl-Shift-E$")
        [void](Save-Window 'menus-view')
        Send-Keys 'down down enter'
        Start-Sleep -Milliseconds 300
        $sb = Last-Line '^\[dev\] sidebar '
        Check 'menus' 'A-17.1' 'View > Toggle Folder Sidebar → 닫힘, 포커스 center(I-309 복원 뒤 실행)' 'open=false focus=center' $sb ($sb -match 'open=false .*focus=center')
        Send-Keys 'f10 right right'
        Start-Sleep -Milliseconds 300
        Send-Keys 'down down down enter'
        Start-Sleep -Milliseconds 300
        $sb = Last-Line '^\[dev\] sidebar '
        Check 'menus' 'A-17.2' 'View > Focus Folder Sidebar → 열고 포커스' 'open=true focus=sidebar' $sb ($sb -match 'open=true .*focus=sidebar')
    }

    # ================================================================ state: R-28 폭 저장·복원, 알 수 없는 키 보존, 깨진 파일, .tmp 복구, 버전
    $extra = @{ zz_unknown_root = @{ keep = 'root 값' } }
    $st = (New-StateJson @((Folder 'alpha'), (Folder 'beta')) 1 $null $extra) | ConvertFrom-Json -AsHashtable -DateKind String
    $st.windows[0].zz_unknown_window = 'window 값'
    $st.windows[0].folders[0].zz_unknown_folder = 42
    $st.windows[0].sidebar = @{ width = 300; zz_unknown_sidebar = $true }
    Run-Case 'state' ($st | ConvertTo-Json -Depth 8) {
        param($res, $p)
        Check 'state' 'R-28' '시작 복원: 활성 beta' 'active=1' "active=$((Get-Folders).active)" ((Get-Folders).active -eq '1')
        $sb = Need-Box 'sidebar'
        Check 'state' 'R-28' '시작 폭 300' '300' $sb.w (Near $sb.w 300 1)
        # 사이드바 오른쪽 경계(분할 핸들)를 오른쪽으로 120 끌기.
        $x0 = $sb.x + $sb.w; $y0 = $sb.y + $sb.h / 2
        $a = ToScreen ($x0 - 1) $y0; $b = ToScreen ($x0 + 119) $y0
        Assert-Target $a[0] $a[1] 'drag sidebar edge'
        $bs = Count-Lines '^\[dev\] state-save '
        [WgP3.Native]::Drag($a[0], $a[1], $b[0], $b[1])
        $save = Wait-Save $bs
        $sb2 = Wait-Box 'sidebar' 3 { param($x) $x.w -gt 350 }
        Check 'state' 'A-11.1·R-28' '폭 끌기 → 저장' 'state-save result=written' $save ($save -match 'result=written')
        $s = Read-State
        Save-State 'state-after-resize'
        $w = $s.windows[0].sidebar.width
        Check 'state' 'R-28 A-22' 'state.json sidebar.width = 화면 폭' $(if ($sb2) { [math]::Round($sb2.w) } else { '?' }) $w ($sb2 -and (Near $w $sb2.w 1.5) -and $w -gt 350)
        Check 'state' 'A-20' '알 수 없는 키 보존(root·window·folder·sidebar)' 'root 값, window 값, 42, True' ("{0}, {1}, {2}, {3}" -f $s.zz_unknown_root.keep, $s.windows[0].zz_unknown_window, $s.windows[0].folders[0].zz_unknown_folder, $s.windows[0].sidebar.zz_unknown_sidebar) ($s.zz_unknown_root.keep -eq 'root 값' -and $s.windows[0].zz_unknown_window -eq 'window 값' -and $s.windows[0].folders[0].zz_unknown_folder -eq 42 -and $s.windows[0].sidebar.zz_unknown_sidebar -eq $true)
        $res.width = $w
    }
    if (Wants 'state') {
        $saved = Get-Content -LiteralPath (Join-Path $out 'state-after-resize.json') -Raw
        $wantW = ($saved | ConvertFrom-Json).windows[0].sidebar.width
        Run-Case 'state-restart' $saved {
            param($res, $p)
            $sb = Need-Box 'sidebar'
            Check 'state-restart' 'R-28' '다시 시작 → 사이드바 폭 복원' $wantW $sb.w (Near $sb.w $wantW 1)
            Check 'state-restart' 'R-28' '다시 시작 → 목록·활성 복원' 'alpha / beta, active=1' ("{0}, active={1}" -f (Names), (Get-Folders).active) ((Names) -eq 'alpha / beta' -and (Get-Folders).active -eq '1')
            [void](Save-Window 'state-restart')
        }
    }
    # 깨진 state.json → 빈 상태 + 알림 + .bad 로 옮김(A-24.6).
    Run-Case 'broken' '{ "version": 1, "windows": [ { "folders": [ ' {
        param($res, $p)
        Start-Sleep -Milliseconds 500
        $f = Get-Folders
        $bad = @(Get-ChildItem -LiteralPath $appDir -File -Filter 'state.json.bad-*')
        Check 'broken' 'R-28·A-24.6' '깨진 파일 → 빈 상태, source=empty' 'count=0, source=empty' ("count={0}, {1}" -f $f.count, (Last-Line '^\[dev\] state-load ')) ($f.count -eq 0 -and (Last-Line '^\[dev\] state-load ') -match 'source=empty')
        Check 'broken' 'D-035 ②' "알림 문구 'Could not read the window state.'(우리 문구)" 'notification text=Could not read the window state.' (Last-Line '^\[dev\] notification ') ((Last-Line '^\[dev\] notification ') -ceq '[dev] notification text=Could not read the window state.')
        Check 'broken' 'A-24.6' 'state.json.bad-YYYYMMDD-HHMMSS 로 옮김' 'bad 1개, state.json 없음' ("bad {0} ({1}), state.json {2}" -f $bad.Count, ($bad.Name -join ','), (Test-Path -LiteralPath $statePath)) ($bad.Count -eq 1 -and $bad[0].Name -match '^state\.json\.bad-\d{8}-\d{6}$' -and -not (Test-Path -LiteralPath $statePath))
        Start-Sleep -Milliseconds 400
        [void](Save-Window 'broken-notification')
    }
    # state.json 이 깨졌고 .tmp 가 올바르면 .tmp 로 복구(A-24.5).
    Run-Case 'tmp' '{ broken' {
        param($res, $p)
        Check 'tmp' 'A-24.5' '깨진 state.json + 올바른 .tmp → .tmp 로 복구' 'source=tmp, gamma' ("{0}, {1}" -f (Last-Line '^\[dev\] state-load '), (Names)) ((Last-Line '^\[dev\] state-load ') -match 'source=tmp' -and (Names) -eq 'gamma')
        Check 'tmp' 'A-24.6' '깨진 state.json 은 .bad 로 옮기고 알림' 'bad 1, notification' ("bad {0}, {1}" -f @(Get-ChildItem -LiteralPath $appDir -File -Filter 'state.json.bad-*').Count, (Last-Line '^\[dev\] notification ')) (@(Get-ChildItem -LiteralPath $appDir -File -Filter 'state.json.bad-*').Count -eq 1 -and (Last-Line '^\[dev\] notification ') -match 'Could not read the window state\.')
    } $true (New-StateJson @((Folder 'gamma')) 0)
    # ================================================================ dialog: R-10 실제 OS 폴더 선택 창(rfd)을 SendInput 으로 조작
    function Wait-Dialog([uint32]$AppPid, [double]$Seconds = 8) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        while ($sw.Elapsed.TotalSeconds -lt $Seconds) {
            $d = [WgP3.Native]::FindDialog($AppPid)
            if ($d -ne [IntPtr]::Zero) { return $d }
            Start-Sleep -Milliseconds 200
        }
        return [IntPtr]::Zero
    }
    # 대화상자가 전면일 때만 입력한다.
    function Assert-Dialog([IntPtr]$D, [string]$What) {
        if ([WgP3.Native]::GetForegroundWindow() -ne $D) { [WgP3.Native]::Activate($D); Start-Sleep -Milliseconds 400 }
        if ([WgP3.Native]::GetForegroundWindow() -ne $D) { throw "${What}: 선택 창이 전면이 아니다. 입력을 보내지 않고 중단한다" }
    }
    Run-Case 'dialog' $null {
        param($res, $p)
        Send-Keys 'ctrl-k ctrl-o'
        $d = Wait-Dialog ([uint32]$p.Id)
        Check 'dialog' 'A-13.1·D-6' 'Ctrl+K Ctrl+O → OS 폴더 선택 창(#32770, 이 프로세스)' 'found' $(if ($d -ne [IntPtr]::Zero) { "found title=$([WgP3.Native]::Title($d))" } else { 'none' }) ($d -ne [IntPtr]::Zero)
        if ($d -eq [IntPtr]::Zero) { return }
        $res.dialogTitle = [WgP3.Native]::Title($d)
        Start-Sleep -Milliseconds 800
        & pwsh -NoProfile -File $CaptureScript -Hwnd ('0x{0:X}' -f $d.ToInt64()) -Out (Join-Path $out 'dialog-open.png') -Method PrintWindow | Out-Null
        Assert-Dialog $d 'dialog cancel'
        [WgP3.Native]::Combo([uint16[]]@(), [uint16]$VK.escape)
        $l = Wait-NewLine '^\[dev\] pick-folder result=' 0 5
        Check 'dialog' 'A-13.8' '선택 창 Escape → 취소, 아무 일 없음' 'result=cancel, count=0' ("{0}, count={1}" -f $l, (Get-Folders).count) ($l -match 'result=cancel' -and (Get-Folders).count -eq 0)
        Send-Keys 'ctrl-k ctrl-o'
        $d = Wait-Dialog ([uint32]$p.Id)
        if ($d -eq [IntPtr]::Zero) { throw '두 번째 선택 창이 뜨지 않았다' }
        Start-Sleep -Milliseconds 800
        Assert-Dialog $d 'dialog type path'
        # 폴더 칸(처음 포커스)에 전체 경로를 넣고 Enter(Select Folder).
        [WgP3.Native]::TypeText((Folder 'beta'))
        Start-Sleep -Milliseconds 300
        Assert-Dialog $d 'dialog enter'
        [WgP3.Native]::Combo([uint16[]]@(), [uint16]$VK.enter)
        # 폴더 선택 창은 Enter 로 그 폴더 안으로 들어가기만 할 수 있다. 창이 남아 있으면 Alt+S(Select Folder)로 지금 폴더를 고른다.
        Start-Sleep -Milliseconds 1500
        $res.steps = 'type path, Enter'
        if ([WgP3.Native]::FindDialog([uint32]$p.Id) -ne [IntPtr]::Zero) {
            $d2 = [WgP3.Native]::FindDialog([uint32]$p.Id)
            & pwsh -NoProfile -File $CaptureScript -Hwnd ('0x{0:X}' -f $d2.ToInt64()) -Out (Join-Path $out 'dialog-navigated.png') -Method PrintWindow | Out-Null
            Assert-Dialog $d2 'dialog select button'
            $c = [WgP3.Native]::OkCenter($d2)
            if ($c[0] -lt 0 -or [WgP3.Native]::RootAt($c[0], $c[1]) -ne $d2) { throw '선택 창의 확인 버튼 자리를 찾지 못했다. 입력을 보내지 않고 중단한다' }
            $res.okButton = [WgP3.Native]::OkText($d2)
            [WgP3.Native]::Click($c[0], $c[1])
            $res.steps = "type path, Enter(폴더 안으로 이동), 확인 버튼 '$($res.okButton)' 누름(SendInput)"
        }
        $l = Wait-NewLine '^\[dev\] folder-add ' 0 6
        Check 'dialog' 'A-13.1·A-10.6' '선택 창에 경로 입력 + Enter → 등록·활성' "result=added index=0 path=$(Folder 'beta')" $l ($l -match "result=added index=0 path=$([regex]::Escape((Folder 'beta')))")
        Start-Sleep -Milliseconds 400
        [void](Save-Window 'dialog-after-pick')
    } $false

    # 종료 직전 쓰기(A-24.3): 바꾸고 500ms 안에 Ctrl+Q → 바뀐 순서가 저장된다. 바꾼 것이 없으면 쓰지 않는다(판단).
    Run-Case 'quitsave' (New-StateJson @((Folder 'alpha'), (Folder 'beta')) 0) {
        param($res, $p)
        $h0 = (Get-FileHash -LiteralPath $statePath -Algorithm SHA256).Hash
        RightClick-Box 'folder-row-00'
        Click-Box 'ctx-menu-row-1' 'Move Down'
        Send-Keys 'ctrl-q'
        $exited = $p.WaitForExit(5000)
        $s = Read-State
        $leafs = @($s.windows[0].folders | ForEach-Object { Split-Path -Leaf $_.path }) -join ' / '
        Check 'quitsave' 'A-24.3' 'Move Down 직후 Ctrl+Q → 끝나기 전에 저장' 'exited, beta / alpha' ("exited={0}, {1}, saves={2}" -f $exited, $leafs, (Count-Lines '^\[dev\] state-save result=written')) ($exited -and $leafs -eq 'beta / alpha')
        Save-State 'quitsave-state'
    }
    Run-Case 'quitnochange' $null {
        param($res, $p)
        Send-Keys 'ctrl-q'
        $exited = $p.WaitForExit(5000)
        Check 'quitnochange' 'A-24.3' '바꾼 것 없이 종료 → state.json 을 만들지 않는다(판단)' 'exited, state.json 없음' ("exited={0}, exists={1}" -f $exited, (Test-Path -LiteralPath $statePath)) ($exited -and -not (Test-Path -LiteralPath $statePath))
    }
    # ================================================================ 리뷰 1회차(D-037) 재현 사례
    # ① 창이 사라지는 경로의 종료 저장: Move Down 직후(500ms 안) Ctrl-Shift-W·창 닫기 버튼 → 끝나기 전에 저장.
    foreach ($how in 'closesave', 'xclosesave') {
        Run-Case $how (New-StateJson @((Folder 'alpha'), (Folder 'beta')) 0) {
            param($res, $p)
            # 500ms 묶어 쓰기보다 먼저 닫아야 재현된다. 메뉴를 열어 둔 뒤 Move Down(Down, Enter)과 닫기를 지연 없이 보낸다.
            $cb = Need-Box 'window-btn-close'
            $cp = Center $cb
            RightClick-Box 'folder-row-00'
            Assert-Target $cp[0] $cp[1] 'close button'
            $t0 = UnixMs
            if ($how -eq 'closesave') {
                [WgP3.Native]::Batch([uint16[]]@(0x28, 0x28, 0x0D, 0x0D, 0x11, 0x10, 0x57, 0x57, 0x10, 0x11), [bool[]]@($false, $true, $false, $true, $false, $false, $false, $true, $true, $true))
            }
            else {
                [WgP3.Native]::Batch([uint16[]]@(0x28, 0x28, 0x0D, 0x0D), [bool[]]@($false, $true, $false, $true))
                Start-Sleep -Milliseconds 80
                [WgP3.Native]::Click($cp[0], $cp[1])
            }
            $res.sendMs = (UnixMs) - $t0
            $exited = $p.WaitForExit(5000)
            Check $how 'D-037 ①' 'Move Down 과 닫기를 500ms 묶어 쓰기 안에 보냄' '< 400ms' "$($res.sendMs)ms" ($res.sendMs -lt 400)
            $s = Read-State
            $leafs = @($s.windows[0].folders | ForEach-Object { Split-Path -Leaf $_.path }) -join ' / '
            $via = if ($how -eq 'closesave') { 'close-window' } else { 'window-close' }
            Check $how 'A-24.3·R-28 (D-037 ①)' "Move Down 직후 $(if ($how -eq 'closesave') { 'Ctrl-Shift-W' } else { '창 닫기 버튼' }) → 끝나기 전에 저장" "exited, beta / alpha, state-flush via=$via" ("exited={0}, {1}, {2}" -f $exited, $leafs, (Last-Line '^\[dev\] state-flush ')) ($exited -and $leafs -eq 'beta / alpha')
            Save-State "$how-state"
        }
    }
    # ② 저장 실패 뒤 종료: state.json 을 공유 삭제 없이 열어 두어 교체를 막는다 → 실패 알림 → 잠금을 풀고 Ctrl+Q → 종료 직전 쓰기.
    Run-Case 'savefail' (New-StateJson @((Folder 'alpha'), (Folder 'beta')) 0) {
        param($res, $p)
        $lock = [System.IO.File]::Open($statePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
        try {
            $bs = Count-Lines '^\[dev\] state-save '
            RightClick-Box 'folder-row-00'
            Click-Box 'ctx-menu-row-1' 'Move Down'
            $sv = Wait-Save $bs
            Check 'savefail' 'A-24.4' '교체가 막히면 3번 다시 시도 뒤 실패 + 알림' 'result=failed, Could not save the window state.' ("{0}, {1}" -f $sv, (Last-Line '^\[dev\] notification ')) ($sv -match 'result=failed' -and (Last-Line '^\[dev\] notification ') -ceq '[dev] notification text=Could not save the window state.')
            Start-Sleep -Milliseconds 300
            [void](Save-Window 'savefail-notification')
        }
        finally { $lock.Dispose() }
        Send-Keys 'ctrl-q'
        $exited = $p.WaitForExit(5000)
        $s = Read-State
        $leafs = @($s.windows[0].folders | ForEach-Object { Split-Path -Leaf $_.path }) -join ' / '
        Check 'savefail' 'A-24.3·A-24.4 (D-037 ②)' '실패한 변경은 남아 있다가 종료 직전에 다시 쓴다' 'exited, beta / alpha' ("exited={0}, {1}, flush={2}" -f $exited, $leafs, (Last-Line '^\[dev\] state-flush ')) ($exited -and $leafs -eq 'beta / alpha')
        Save-State 'savefail-state'
    }
    # ⑤ A-28.5 단순 케이스 폴딩: σ 를 등록한 뒤 ς 를 고르면 기존 항목 활성. 이 PC 의 NTFS 에서는 σ·ς 가 다른 이름으로 함께 있을 수 있다
    #   (둘 다 만든다). A-28.5 는 원문대로 단순 케이스 폴딩(ς→σ)으로 비교하므로 같은 항목으로 본다.
    Run-Case 'sigma' $null {
        param($res, $p)
        $l1 = Add-Via (Folder ([string][char]0x03C3)) { Send-Keys 'ctrl-k ctrl-o' }
        $l2 = Add-Via (Folder ([string][char]0x03C2)) { Send-Keys 'ctrl-k ctrl-o' }
        Check 'sigma' 'A-28.5·A-13.2 (D-037 ⑤)' 'σ 등록 뒤 ς 선택 → 새 항목 없이 기존 활성' 'added index=0, existing index=0, count=1' ("{0} / {1} / count={2}" -f $l1, $l2, (Get-Folders).count) ($l1 -match 'result=added index=0' -and $l2 -match 'result=existing index=0' -and (Get-Folders).count -eq 1)
    }

    # 앱보다 큰 version → 읽기만(A-24.7).
    $v2 = (New-StateJson @((Folder 'alpha'), (Folder 'beta')) 0).Replace('"version": 1', '"version": 2')
    Run-Case 'version' $v2 {
        param($res, $p)
        $h0 = (Get-FileHash -LiteralPath $statePath -Algorithm SHA256).Hash
        Check 'version' 'A-24.7' 'version 2 → 읽음, read_only' 'read_only=true, alpha / beta' ("{0}, {1}" -f (Last-Line '^\[dev\] state-load '), (Names)) ((Last-Line '^\[dev\] state-load ') -match 'read_only=true' -and (Names) -eq 'alpha / beta')
        $bs = Count-Lines '^\[dev\] state-save '
        Click-Box 'folder-row-01' 'activate beta'
        $sv = Wait-Save $bs
        $h1 = (Get-FileHash -LiteralPath $statePath -Algorithm SHA256).Hash
        Check 'version' 'A-24.7' '바꿔도 쓰지 않음(파일 해시 같음)' 'skipped-read-only, 해시 같음' ("{0}, same={1}" -f $sv, ($h0 -eq $h1)) ($sv -match 'skipped-read-only' -and $h0 -eq $h1)
    }
}
catch { $results.failures += $_.Exception.Message }
finally {
    # 1) 사용자 파일 복원(가장 먼저, 독립 try/finally, D-029).
    try {
        try {
            if ($backupDone) {
                # 리뷰 1회차 ③(D-037): 파일마다 따로 되돌린다. 한 파일의 실패가 다른 파일 복원을 막지 않는다.
                # 먼저 백업한 파일(keymap.json 포함)을 하나씩 복사해 되돌리고, 그다음 시험이 만든 파일만 하나씩 지운다.
                $backupNames = @(Get-ChildItem -LiteralPath $backupDir -File | ForEach-Object Name)
                foreach ($name in $backupNames) {
                    try { Copy-Item -LiteralPath (Join-Path $backupDir $name) -Destination (Join-Path $appDir $name) -Force }
                    catch { $results.errors += "복원 ${name}: $($_.Exception.Message)" }
                }
                foreach ($uf in (Get-UserFiles)) {
                    if ($backupNames -notcontains $uf.Name) {
                        try { Remove-Item -LiteralPath $uf.FullName -Force }
                        catch { $results.errors += "시험 파일 지우기 $($uf.Name): $($_.Exception.Message)" }
                    }
                }
                $results.restoreSteps = [ordered]@{ restored = $backupNames; errors = @($results.errors | Where-Object { $_ -like '복원 *' -or $_ -like '시험 파일 지우기 *' }) }
            }
        }
        finally {
            $after = Get-UserHashes
            $same = (($userHashBefore | ConvertTo-Json -Compress) -eq ($after | ConvertTo-Json -Compress))
            $results.userFiles = [ordered]@{ dir = $appDir; before = $userHashBefore; after = $after; restored = $same; backupDir = $(if ($backupDone) { $backupDir } else { $null }) }
            if (-not $same) { $results.failures += '사용자 파일(state.json·keymap.json)이 실행 전과 다르다' }
        }
    }
    catch { $results.errors += "사용자 파일 복원: $($_.Exception.Message)" }
    # 2) 백업 지우기(복원 확인 때만), 시험 폴더 지우기.
    if ($backupDone -and $results.userFiles -and $results.userFiles.restored) {
        try { Remove-Item -LiteralPath $backupDir -Recurse -Force } catch { $results.errors += "백업 지우기: $($_.Exception.Message)" }
    }
    # 이번 실행이 만든 시험 폴더만 지운다(가드로 일찍 멈췄으면 만든 적이 없어 아무것도 지우지 않는다, D-040).
    try { Remove-TestFolders } catch { $results.errors += "시험 폴더 지우기: $($_.Exception.Message)" }
    $results.testFolders = [ordered]@{ base = $testBase; run = $testRoot; runFolderLeft = (Test-Path -LiteralPath $testRoot); baseLeft = (Test-Path -LiteralPath $testBase) }
    [void][WgP3.Native]::SetThreadDpiAwarenessContext($prevDpi)
    foreach ($e in $results.errors) { $results.failures += "정리 오류: $e" }
}

$results.finishedAt = (Get-Date).ToString('o')
$results.passed = ($results.failures.Count -eq 0)
$results | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $out 'results.json') -Encoding utf8
"cases: $(@($results.cases.get_Keys()) -join ', ')"
"checks: $($results.checks.Count), failed: $(@($results.checks | Where-Object { -not $_.ok }).Count)"
"failures: $($results.failures.Count)"
"user files restored: $($results.userFiles.restored)"
$results.failures | ForEach-Object { "  - $_" }
if ($results.failures.Count -gt 0) { exit 1 }

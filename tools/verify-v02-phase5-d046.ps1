#Requires -Version 7
<#
.SYNOPSIS
  v0.2 Phase 5 리뷰 1회차(D-046) 재현 사례: ① 앱 자신의 이름 바꾸기 재적용 ② 입력 중 미룬 묶음의 이름 바꾸기 버림
  ③ 같은 경로의 새 루트로 바뀜 ④ 루트 실제 트리 밖 열린 파일(옮긴 파일·정션) ⑤ 큰 파일 다시 읽기의 메인 스레드 막힘.

.DESCRIPTION
  Phase 5 스크립트(tools/verify-v02-phase5.ps1)와 같은 안전 규칙·도우미를 쓴다. 시험 폴더는 target\phase5-folders\run-<id>
  (표지 .wg-p5-run)에 이번 실행만 만들고 끝에 표지가 같을 때만 지운다. 바깥 변경·정션은 그 안에서만 한다.
  고치기 전 실행 파일은 -Exe 로 준다(결과는 -OutDir ...\before).

.EXAMPLE
  pwsh -NoProfile -File tools/verify-v02-phase5-d046.ps1
  pwsh -NoProfile -Command "& ./tools/verify-v02-phase5-d046.ps1 -Exe <before.exe> -OutDir specs\v0.2\verify\phase5\d046-rerun\before"
#>
[CmdletBinding()]
param(
    [string]$Exe = 'target\debug\workbench-gpui.exe',
    [string]$OutDir = 'specs\v0.2\verify\phase5\d046-rerun\after',
    [string[]]$Only = @()
)

$ErrorActionPreference = 'Stop'
$ProcessName = 'workbench-gpui'
$AppTitle = 'workbench-gpui'
$CaptureScript = Join-Path $PSScriptRoot 'capture.ps1'

if (-not ('WgP4.Native' -as [type])) {
    Add-Type -ReferencedAssemblies @('System.Runtime', 'System.Collections', 'System.Threading', 'System.Threading.Thread', 'System.Runtime.InteropServices') -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

namespace WgP4
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
        // 전면 잠금(사용자가 다른 창에 막 입력한 경우)으로 Activate 가 안 될 때: Alt 내림·올림을 보내 마지막 입력 프로세스가 된 뒤 전면 전환(널리 쓰는 방법).
        public static void ActivateAlt(IntPtr hWnd)
        {
            Send(K(0x12, false)); Send(K(0x12, true));
            SetForegroundWindow(hWnd);
        }
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
        const uint MOUSEEVENTF_MIDDLEDOWN = 0x20, MOUSEEVENTF_MIDDLEUP = 0x40;
        // 수식키를 누른 채 왼쪽 누르기(Ctrl·Shift·Alt+클릭, I-089·I-090).
        public static void ClickMods(int x, int y, ushort[] mods)
        {
            Send(M(0, x, y, 0)); Thread.Sleep(60);
            foreach (var m in mods) { Send(K(m, false)); Thread.Sleep(30); }
            Send(M(MOUSEEVENTF_LEFTDOWN, x, y, 0)); Thread.Sleep(40);
            Send(M(MOUSEEVENTF_LEFTUP, x, y, 0)); Thread.Sleep(40);
            for (int n = mods.Length - 1; n >= 0; n--) { Send(K(mods[n], true)); Thread.Sleep(30); }
        }
        // 더블클릭: 두 번 누르기를 더블클릭 시간 안에.
        public static void DoubleClick(int x, int y)
        {
            Send(M(0, x, y, 0)); Thread.Sleep(60);
            Send(M(MOUSEEVENTF_LEFTDOWN, x, y, 0)); Thread.Sleep(30);
            Send(M(MOUSEEVENTF_LEFTUP, x, y, 0)); Thread.Sleep(60);
            Send(M(MOUSEEVENTF_LEFTDOWN, x, y, 0)); Thread.Sleep(30);
            Send(M(MOUSEEVENTF_LEFTUP, x, y, 0));
        }
        public static void MiddleClick(int x, int y)
        {
            Send(M(0, x, y, 0)); Thread.Sleep(60);
            Send(M(MOUSEEVENTF_MIDDLEDOWN, x, y, 0)); Thread.Sleep(40);
            Send(M(MOUSEEVENTF_MIDDLEUP, x, y, 0));
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
$backupDir = Join-Path ([System.IO.Path]::GetTempPath()) ("wg-p5-backup-{0}" -f [guid]::NewGuid())
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
$testBase = [System.IO.Path]::GetFullPath('target\phase5-folders', (Get-Location).Path)
$testRoot = Join-Path $testBase "run-$runId"
$testMarker = Join-Path $testRoot '.wg-p5-run'
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
    if ([WgP4.Native]::GetForegroundWindow() -ne $script:hwnd) {
        [WgP4.Native]::Activate($script:hwnd)
        Start-Sleep -Milliseconds 300
    }
    if ([WgP4.Native]::GetForegroundWindow() -ne $script:hwnd) { [WgP4.Native]::ActivateAlt($script:hwnd); Start-Sleep -Milliseconds 400 }
    if ([WgP4.Native]::GetForegroundWindow() -ne $script:hwnd) { throw "${What}: 대상 창이 전면이 아니다. 입력을 보내지 않고 중단한다" }
}
function Assert-Target([int]$X, [int]$Y, [string]$What) {
    Assert-Foreground $What
    if ([WgP4.Native]::RootAt($X, $Y) -ne $script:hwnd) { throw ("{0}: ({1},{2}) 아래 창이 대상 창이 아니다. 입력을 보내지 않고 중단한다" -f $What, $X, $Y) }
}

function ToScreen([double]$x, [double]$y) {
    @([int][math]::Round($script:client.x + $x * $script:scale), [int][math]::Round($script:client.y + $y * $script:scale))
}
function Center($b) { ToScreen ($b.x + $b.w / 2) ($b.y + $b.h / 2) }

function Move-To([double]$x, [double]$y, [string]$What) {
    $p = ToScreen $x $y
    Assert-Target $p[0] $p[1] $What
    [WgP4.Native]::MoveTo($p[0], $p[1])
}
function Click-At([double]$x, [double]$y, [string]$What) {
    $p = ToScreen $x $y
    Assert-Target $p[0] $p[1] $What
    [WgP4.Native]::Click($p[0], $p[1])
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
    [WgP4.Native]::Batch($vks.ToArray(), $ups.ToArray())
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
        [WgP4.Native]::Combo([uint16[]]$mods, [uint16]$VK[$key])
        Start-Sleep -Milliseconds 150
    }
    if (Get-Command Wait-Quiet -ErrorAction SilentlyContinue) { Wait-Quiet }
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
$proj = $null; $proj2 = $null
# Phase 4 시험 트리. proj: 접힌 경로(docs \ guides, deep \ l1 \ l2), 깊이 3, 파일 작업용 ops, 스크롤용 many(40개). proj2: 두 번째 폴더.
function Init-TestFolders {
    if (Test-Path -LiteralPath $testRoot) { throw "시험 폴더 $testRoot 가 이미 있다. 지우지 않고 중단한다" }
    if (-not (Test-Path -LiteralPath $testBase)) { New-Item -ItemType Directory -Path $testBase -Force | Out-Null; $script:testBaseCreated = $true }
    New-Item -ItemType Directory -Path $testRoot | Out-Null
    Write-Utf8 $testMarker $runId
    $script:testRootCreated = $true
    Reset-Proj
    $script:proj2 = Folder 'proj2'
    Write-Utf8 (Join-Path $script:proj2 'b-readme.md') "# proj2 한글"
    Write-Utf8 (Join-Path $script:proj2 'other.txt') 'other'
}
# proj 를 처음 모양으로 다시 만든다(사례마다 같은 시작점). 이번 실행 폴더 안에서만 지운다.
function Reset-Proj {
    $script:proj = Folder 'proj'
    if (Test-Path -LiteralPath $script:proj) {
        if (-not $script:proj.StartsWith($testRoot)) { throw 'proj 가 이번 실행 폴더 밖이다' }
        Remove-Item -LiteralPath $script:proj -Recurse -Force
    }
    $files = [ordered]@{
        'README.md' = "# README`r`n한글 확인 첫 줄`r`n"
        'notes.txt' = 'notes 한글'
        'docs\guides\a.md' = '# a'
        'src\main.rs' = 'fn main() {}'
        'src\lib.rs' = 'pub fn lib() {}'
        'src\util\mod.rs' = 'pub mod util;'
        'deep\l1\l2\deep.txt' = 'deep'
        'ops\f1.txt' = 'f1'
        'ops\f2.txt' = 'f2'
        'ops\f3.txt' = 'f3'
        'ops\locked.txt' = 'locked'
        'ops\sub\s.txt' = 's'
    }
    foreach ($k in $files.Keys) { Write-Utf8 (Join-Path $script:proj $k) $files[$k] }
    for ($n = 0; $n -lt 40; $n++) { Write-Utf8 (Join-Path $script:proj ('many\m{0:d2}.txt' -f $n)) "m$n" }
}
# 이번 실행이 만든 폴더(표지 = 이번 실행 id)만 지운다(D-040).
function Remove-TestFolders {
    if (-not $script:testRootCreated) { return }
    if (-not (Test-Path -LiteralPath $testMarker)) { throw "표지 파일이 없어 $testRoot 를 지우지 않는다" }
    if ((Get-Content -LiteralPath $testMarker -Raw -Encoding utf8).Trim() -ne $runId) { throw "표지가 이번 실행 것이 아니어서 $testRoot 를 지우지 않는다" }
    Remove-Item -LiteralPath $testRoot -Recurse -Force
    $script:testRootCreated = $false
    if ($script:testBaseCreated -and @(Get-ChildItem -LiteralPath $testBase -Force).Count -eq 0) { Remove-Item -LiteralPath $testBase -Force }
}
# 휴지통에서 원래 위치가 이번 실행 시험 폴더 아래인 항목만(--dev-trash). $Op = list|restore|purge. 출력 줄을 돌려준다.
function Invoke-Trash([string]$Op, [string]$Save = '') {
    $exePath = (Resolve-Path -LiteralPath $Exe).Path
    $lines = @(& $exePath --dev-trash $Op $testRoot 2>&1 | ForEach-Object { "$_" })
    if ($Save) { Set-Content -LiteralPath (Join-Path $out "$Save.txt") -Value $lines -Encoding utf8 }
    return $lines
}
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
    if (-not $script:realShell) { $appArgs += '--dev-no-shell' }
    # D-046 ⑤: 사례가 정한 추가 dev 플래그(예: --dev-slow-io).
    if ($script:extraArgs) { $appArgs += $script:extraArgs }
    $p = Start-Process -FilePath $exePath -ArgumentList $appArgs -RedirectStandardOutput $script:stdout -PassThru
    $script:launched = $p
    $script:appPid = $p.Id
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt 20 -and ((Count-Lines '^\[dev\] display-end seq=1') -eq 0 -or (Count-Lines '^\[dev\] folders-end') -eq 0)) { Start-Sleep -Milliseconds 100 }
    if ((Count-Lines '^\[dev\] folders-end') -eq 0) { throw "${Case}: 20초 안에 folders-end 가 나오지 않았다" }
    $sw.Restart()
    do {
        $script:hwnd = [WgP4.Native]::FindTitled([uint32]$p.Id, $AppTitle)
        if ($script:hwnd -ne [IntPtr]::Zero) { break }
        Start-Sleep -Milliseconds 200
    } while ($sw.Elapsed.TotalSeconds -lt 10)
    if ($script:hwnd -eq [IntPtr]::Zero) { throw "${Case}: 앱 메인 창을 찾지 못했다" }
    # 200% 배율에서 기본 창이 작업 영역보다 커서, 띄운 창(고정 HWND)만 최대화한다(Phase 2 와 같다).
    [void][WgP4.Native]::ShowWindow($script:hwnd, 3)
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
    [WgP4.Native]::RightClick($p[0], $p[1])
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


# ---------------------------------------------------------------- Phase 4 도우미(Phase 5 에서 그대로 쓴다)
$VK.f2 = 0x71; $VK.space = 0x20; $VK.insert = 0x2D; $VK.menu = 0x5D; $VK.f10 = 0x79
$script:realShell = $false

# 가장 최근 [dev] tree 줄: selected, marked[], expanded[], rows[](label, depth, kind).
function Get-Tree {
    $l = Last-Line '^\[dev\] tree folder='
    if ($l -eq '<none>') { return $null }
    [void]($l -match '^\[dev\] tree folder=(\S+) selected=(.*?) marked=(.*?) expanded=(.*?) rows=(.*)$')
    $r = [ordered]@{ folder = $Matches[1]; selected = $Matches[2]; marked = @($Matches[3].Split(';', [StringSplitOptions]::RemoveEmptyEntries)); expanded = @($Matches[4].Split(';', [StringSplitOptions]::RemoveEmptyEntries)); rows = @(); line = $l }
    foreach ($row in $Matches[5].Split("`t")) {
        $p = $row.Split('|')
        $r.rows += [pscustomobject]@{ label = $p[0]; depth = [int]$p[1]; kind = $(if ($p.Count -gt 2) { $p[2] } else { 'new' }) }
    }
    [pscustomobject]$r
}
function Tree-Labels { @((Get-Tree).rows | ForEach-Object { $_.label }) -join ' / ' }
function Row-Index([string]$Label) {
    $rows = (Get-Tree).rows
    for ($i = 0; $i -lt $rows.Count; $i++) { if ($rows[$i].label -eq $Label) { return $i } }
    return -1
}
function Row-Box([string]$Label) {
    $i = Row-Index $Label
    if ($i -lt 0) { throw "트리에 '$Label' 행이 없다: $(Tree-Labels)" }
    Need-Box ('tree-row-{0:d2}' -f $i)
}
# 가장 최근 [dev] tabs 줄: active, count, list[](title, kind, path).
function Get-Tabs {
    $l = Last-Line '^\[dev\] tabs folder='
    if ($l -eq '<none>') { return [pscustomobject]@{ folder = ''; active = 'none'; count = 0; list = @(); line = $l } }
    [void]($l -match '^\[dev\] tabs folder=(\S+) active=(\S+) count=(\d+) list=(.*)$')
    $r = [ordered]@{ folder = $Matches[1]; active = $Matches[2]; count = [int]$Matches[3]; list = @(); line = $l }
    if ($Matches[4]) {
        foreach ($t in $Matches[4].Split("`t")) { $p = $t.Split('|'); $r.list += [pscustomobject]@{ title = $p[0]; kind = $p[1]; path = $p[2] } }
    }
    [pscustomobject]$r
}
function Tabs-Text { $t = Get-Tabs; "active=$($t.active) " + (@($t.list | ForEach-Object { "$($_.title)|$($_.kind)" }) -join ' / ') }
# 트리 행 누르기. $Mods = 'ctrl','shift','alt' 중 몇 개.
function Click-Row([string]$Label, [string[]]$Mods = @(), [string]$How = 'single') {
    $b = Row-Box $Label
    $p = ToScreen ($b.x + 60) ($b.y + $b.h / 2)
    Assert-Target $p[0] $p[1] "row $Label"
    switch ($How) {
        'double' { [WgP4.Native]::DoubleClick($p[0], $p[1]) }
        'middle' { [WgP4.Native]::MiddleClick($p[0], $p[1]) }
        'right' { [WgP4.Native]::RightClick($p[0], $p[1]) }
        default {
            if ($Mods.Count) { [WgP4.Native]::ClickMods($p[0], $p[1], [uint16[]]@($Mods | ForEach-Object { $VK[$_] })) }
            else { [WgP4.Native]::Click($p[0], $p[1]) }
        }
    }
    Start-Sleep -Milliseconds 200; Wait-Quiet
}
function Type-Text([string]$Text) { Assert-Foreground "type $Text"; [WgP4.Native]::TypeText($Text); Start-Sleep -Milliseconds 200; Wait-Quiet }
# 확인창(TaskDialog, #32770). 나올 때까지 기다린다.
function Wait-Dialog([double]$Seconds = 5) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $Seconds) {
        $h = [WgP4.Native]::FindDialog([uint32]$script:appPid)
        if ($h -ne [IntPtr]::Zero) { Start-Sleep -Milliseconds 400; return $h }
        Start-Sleep -Milliseconds 100
    }
    return [IntPtr]::Zero
}
function Wait-NoDialog([double]$Seconds = 5) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $Seconds) {
        if ([WgP4.Native]::FindDialog([uint32]$script:appPid) -eq [IntPtr]::Zero) { return $true }
        Start-Sleep -Milliseconds 100
    }
    return $false
}
# 확인창 스크린샷(우리 프로세스의 창인지 확인).
function Save-Dialog([IntPtr]$Dlg, [string]$Name) {
    $png = Join-Path $out "$Name.png"
    $expected = '0x{0:X}' -f $Dlg.ToInt64()
    $raw = & pwsh -NoProfile -File $CaptureScript -Hwnd $expected -Out $png -Method PrintWindow
    $obj = ($raw | Out-String) | ConvertFrom-Json
    if ($obj.pid -ne $script:appPid) { throw "capture ${Name}: 우리 프로세스 창이 아니다" }
    return $obj
}
# 확인창에 키를 보낸다(확인창이 전면일 때만).
function Send-DialogKeys([IntPtr]$Dlg, [string]$Keys) {
    if ([WgP4.Native]::GetForegroundWindow() -ne $Dlg) { [WgP4.Native]::Activate($Dlg); Start-Sleep -Milliseconds 300 }
    if ([WgP4.Native]::GetForegroundWindow() -ne $Dlg) { throw "확인창이 전면이 아니다. 키를 보내지 않는다" }
    foreach ($stroke in $Keys.Split(' ', [StringSplitOptions]::RemoveEmptyEntries)) {
        $parts = $stroke.Split('-')
        $mods = @($parts | Select-Object -SkipLast 1 | ForEach-Object { [uint16]$VK[$_] })
        [WgP4.Native]::Combo([uint16[]]$mods, [uint16]$VK[$parts[-1]])
        Start-Sleep -Milliseconds 200
    }
}
# 휴지통·삭제 요청 하나: $Trigger 로 확인창을 띄우고, $Answer('esc','enter','confirm')로 닫고 결과 줄을 돌려준다.
function Delete-Flow([string]$Case, [scriptblock]$Trigger, [string]$Answer, [string]$Shot = '') {
    $bo = Count-Lines '^\[dev\] task-dialog-open '
    $br = Count-Lines '^\[dev\] task-dialog-result '
    & $Trigger
    $open = Wait-NewLine '^\[dev\] task-dialog-open ' $bo 5
    $dlg = Wait-Dialog 5
    if ($dlg -eq [IntPtr]::Zero) { throw "${Case}: 확인창이 뜨지 않았다" }
    if ($Shot) { [void](Save-Dialog $dlg $Shot) }
    switch ($Answer) {
        'esc' { Send-DialogKeys $dlg 'escape' }
        'enter' { Send-DialogKeys $dlg 'enter' }
        'confirm' { Send-DialogKeys $dlg 'shift-tab enter' }
    }
    $res = Wait-NewLine '^\[dev\] task-dialog-result ' $br 5
    [void](Wait-NoDialog 5)
    Start-Sleep -Milliseconds 700
    [pscustomobject]@{ open = $open; result = $res }
}
function Disk-Has([string]$Rel) { Test-Path -LiteralPath (Join-Path $script:proj $Rel) }
function Save-Disk([string]$Name) { $l = @(Get-DiskListing); Set-Content -LiteralPath (Join-Path $out "$Name.txt") -Value $l -Encoding utf8; return $l }
function Trash-Names { @(Invoke-Trash 'list' | Where-Object { $_ -match '^\[dev\] trash-item ' } | ForEach-Object { [void]($_ -match 'name=(.*?) original_parent='); $Matches[1] }) }
# 앱 출력이 잠잠해질 때까지(350ms 동안 늘지 않음, 최대 4초) 기다린다. 디버그 빌드가 입력을 다 처리한 뒤 판정하려고.
function Wait-Quiet([int]$QuietMs = 350, [double]$Max = 4) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $last = -1; $since = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $Max) {
        $len = (Get-Item -LiteralPath $script:stdout).Length
        if ($len -ne $last) { $last = $len; $since.Restart() }
        elseif ($since.ElapsedMilliseconds -ge $QuietMs) { return }
        Start-Sleep -Milliseconds 50
    }
}
function Disk-Names([string]$Rel = '') { @(Get-ChildItem -LiteralPath (Join-Path $script:proj $Rel) -Force | ForEach-Object Name) }
# 환경 때문에 판정할 수 없는 항목(실패로 세지 않고 따로 남긴다).
function Undetermined([string]$Case, [string]$Id, [string]$What, [string]$Why) {
    if (-not $script:results.Contains('undetermined')) { $script:results.undetermined = @() }
    $script:results.undetermined += [ordered]@{ case = $Case; id = $Id; what = $What; why = $Why }
}
# 휴지통을 볼 수 있는 환경인가: 시험 폴더 볼륨이 고정 디스크이고, 그 볼륨의 휴지통이 "바로 지우기"(NukeOnDelete)가 아니어야 한다.
function Get-RecycleEnv {
    $drive = (Split-Path -Qualifier $testRoot).TrimEnd(':')
    $type = (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='${drive}:'").DriveType
    $nuke = @(Get-ChildItem 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\BitBucket\Volume' -ErrorAction SilentlyContinue | ForEach-Object { (Get-ItemProperty $_.PSPath).NukeOnDelete })
    [pscustomobject]@{ drive = $drive; driveType = $type; removable = ($type -eq 2); nukeOnDelete = ($nuke -join ','); available = ($type -eq 3 -and -not ($nuke -contains 1)) }
}
# 더블클릭으로 일반 탭 열기. 디버그 빌드에서 두 번째 누르기가 늦게 처리돼 한 번 누르기로 세어지면 한 번 더 한다(재시도는 results.json retries 에 남긴다).
function Double-Open([string]$Case, [string]$Label) {
    Click-Row $Label -How 'double'
    $t = @((Get-Tabs).list | Where-Object { $_.title -eq $Label })
    if (-not ($t.Count -and $t[0].kind -eq 'normal')) {
        if (-not $script:results.Contains('retries')) { $script:results.retries = @() }
        $script:results.retries += "${Case}: $Label 더블클릭 재시도(첫 시도 결과: $(Tabs-Text))"
        Start-Sleep -Milliseconds 800
        Click-Row $Label -How 'double'
    }
}

# ---------------------------------------------------------------- Phase 5 도우미
$results.latency = @()
# 앱의 dev 출력과 같은 FNV-1a 64(UTF-8 바이트).
function Fnv([string]$Text) {
    # PowerShell 의 uint64 곱은 넘치면 오류라서 BigInteger 로 곱하고 2^64 로 나눈 나머지를 쓴다(앱의 wrapping_mul 과 같다).
    $mod = [System.Numerics.BigInteger]::Pow(2, 64)
    $prime = [System.Numerics.BigInteger]::Parse('1099511628211')
    $h = [System.Numerics.BigInteger]::Parse('14695981039346656037')
    foreach ($b in [System.Text.Encoding]::UTF8.GetBytes($Text)) { $h = [System.Numerics.BigInteger]::Remainder((($h -bxor $b) * $prime), $mod) }
    '{0:x16}' -f [uint64]$h
}
function Active-Fnv { $l = Last-Line '^\[dev\] layout-snapshot seq='; if ($l -match 'active_text_fnv=([0-9a-f]+)') { $Matches[1] } else { '<none>' } }
function Has-Row([string]$Label) { (Row-Index $Label) -ge 0 }
# 바깥 변경 하나를 하고, $Done 이 참이 될 때까지(최대 $Seconds) 기다린다. 반영 시간을 results.latency 에 남긴다.
#   app_ms: 변경 직전 시각 → 반영을 본 시각 이전에 앱이 낸 마지막 $Pattern 줄의 t_ms.
#   seen_ms: 변경 직전 시각 → 스크립트가 반영을 본 시각(파일 폴링 25ms 포함).
function Reflect([string]$Case, [string]$What, [scriptblock]$Change, [scriptblock]$Done, [string]$Pattern = '^\[dev\] watch-applied ', [double]$Seconds = 6) {
    $before = Count-Lines $Pattern
    $t0 = UnixMs
    & $Change
    $tc = UnixMs
    $ok = $false
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $Seconds) {
        if (& $Done) { $ok = $true; break }
        Start-Sleep -Milliseconds 25
    }
    $ts = UnixMs
    $new = @(Get-Lines $Pattern | Select-Object -Skip $before)
    $app = $null
    # ' t_ms=' 앞 공백: recv_t_ms·wait_ms 와 섞이지 않게.
    foreach ($l in $new) { if ($l -match ' t_ms=(\d+)' -and [int64]$Matches[1] -le $ts) { $app = [int64]$Matches[1] - $t0 } }
    # 감시 스레드가 첫 이벤트를 받은 시각(이 변경 뒤 첫 watch-recv).
    $recv = @(Get-Lines '^\[dev\] watch-recv ' | ForEach-Object { if ($_ -match 'recv_t_ms=(\d+)') { [int64]$Matches[1] - $t0 } } | Where-Object { $_ -ge 0 })
    $recvMs = $(if ($recv.Count) { $recv[0] } else { $null })
    $e = [ordered]@{ case = $Case; what = $What; ok = $ok; change_ms = ($tc - $t0); recv_ms = $recvMs; app_ms = $app; seen_ms = $(if ($ok) { $ts - $t0 } else { $null }); lines = $new.Count; last = $(if ($new.Count) { $new[-1] } else { '<none>' }) }
    $script:results.latency += $e
    [pscustomobject]$e
}
# 반영 결과를 판정으로도 남긴다.
function Check-Reflect([string]$Case, [string]$Id, [string]$What, [string]$Expect, $R) {
    Check $Case $Id $What $Expect ("ok={0}, app_ms={1}, seen_ms={2}, {3}" -f $R.ok, $R.app_ms, $R.seen_ms, $R.last) $R.ok
}
# $Seconds 동안 $Pattern 줄이 새로 나오지 않는가.
function No-NewLine([string]$Pattern, [int]$Before, [double]$Seconds) {
    Start-Sleep -Milliseconds ([int]($Seconds * 1000))
    (Count-Lines $Pattern) -eq $Before
}
# 이번 실행 폴더 안인지 확인하고 지운다.
function Remove-InRun([string]$Path) {
    $full = [System.IO.Path]::GetFullPath($Path)
    if (-not $full.StartsWith($testRoot + '\')) { throw "이번 실행 폴더 밖이라 지우지 않는다: $full" }
    Remove-Item -LiteralPath $full -Recurse -Force
}
function Rename-InRun([string]$Path, [string]$NewName) {
    $full = [System.IO.Path]::GetFullPath($Path)
    if (-not $full.StartsWith($testRoot + '\')) { throw "이번 실행 폴더 밖이라 이름을 바꾸지 않는다: $full" }
    Rename-Item -LiteralPath $full -NewName $NewName
}
function Folder-Missing([int]$Index) {
    $l = Last-Line ('^\[dev\] folder-row index={0} ' -f $Index)
    $l -match 'missing=true'
}
# 판정이 아니라 관찰(알려진 한계 확인 등)로 남긴다.
function Observe([string]$Case, [string]$What, $Got) {
    if (-not $script:results.Contains('observations')) { $script:results.observations = @() }
    $script:results.observations += [ordered]@{ case = $Case; what = $What; got = "$Got" }
}

# 물리 px 좌표로 다루려고 이 스레드를 PER_MONITOR_AWARE_V2 로 둔다(Phase 2 와 같다).
$prevDpi = [WgP4.Native]::SetThreadDpiAwarenessContext([IntPtr]::new(-4))
$backupDone = $false
try {
    # 사용자 파일·시험 폴더를 바꾸기 전에 기존 앱 실행을 검사하고 즉시 중단한다(D-037 ④).
    $running = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) {
        $results.abortedBeforeChanges = $true
        throw "이미 실행 중인 $ProcessName 가 있다 (PID $($running.Id -join ', ')). 사용자 파일을 바꾸기 전에 중단한다"
    }
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    foreach ($uf in (Get-UserFiles)) { Copy-Item -LiteralPath $uf.FullName -Destination (Join-Path $backupDir $uf.Name) -Force }
    $backupDone = $true
    if (Test-Path -LiteralPath $keymapPath) { Remove-Item -LiteralPath $keymapPath -Force }
    Init-TestFolders
    $results.testDrive = (Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f (Split-Path -Qualifier $testRoot))) | Select-Object DeviceID, DriveType, FileSystem

    # ================================================================ d046-own: ① 앱이 이미 반영한 이름 바꾸기를 감시 묶음이 다시 적용
    # 파일 a 를 탭으로 연 채 F2 로 b 로 바꾸고, 감시 묶음이 반영되기 전에 새 파일 a 를 만들어 연다(Ctrl+N, 한 글자 이름).
    # 묶음이 조용해지지 않도록 다른 파일(noise.txt)을 40ms 마다 고쳐 쓴다(묶음은 첫 이벤트 뒤 1초에 반영된다).
    # 늦게 온 앱 자신의 RenameFrom a → RenameTo b 를 다시 적용하면 새 a 탭이 b 로 바뀐다.
    if (-not ('WgP5.Noise' -as [type])) {
        Add-Type -TypeDefinition @'
using System; using System.IO; using System.Threading;
namespace WgP5 {
    public static class Noise {
        static Timer timer; static int left;
        public static void Start(string path, int intervalMs, int count) {
            left = count;
            timer = new Timer(_ => { if (Interlocked.Decrement(ref left) < 0) { timer.Dispose(); return; } try { File.WriteAllText(path, DateTime.Now.Ticks.ToString()); } catch { } }, null, 0, intervalMs);
        }
    }
}
'@
    }
    Reset-Proj
    Write-Utf8 (Join-Path $proj 'a') 'a 처음'
    Run-Case 'd046-own' (New-StateJson @($proj) 0) {
        param($res, $p)
        Send-Keys 'ctrl-shift-e'
        Click-Row 'a'
        Park-Mouse
        Send-Keys 'f2'
        Assert-Foreground 'd046-own burst'
        [WgP5.Noise]::Start((Join-Path $proj 'noise.txt'), 40, 50)
        Start-Sleep -Milliseconds 120
        [WgP4.Native]::TypeText('b')
        Send-Batch 'enter ctrl-n'
        [WgP4.Native]::TypeText('a')
        Send-Batch 'enter'
        Start-Sleep -Milliseconds 3000
        Wait-Quiet
        $tb = Get-Tabs
        $res.tabs = $tb.line
        $res.applied = @(Get-Lines '^\[dev\] watch-applied ')
        $newA = Join-Path $proj 'a'
        $bPath = Join-Path $proj 'b'
        $nA = @($tb.list | Where-Object { $_.path -eq $newA }).Count
        $nB = @($tb.list | Where-Object { $_.path -eq $bPath }).Count
        Check 'd046-own' 'D-046 ①·R-24' '앱 자신의 이름 바꾸기를 감시가 다시 적용하지 않음: 새 a 탭과 b 탭이 따로' 'a 탭 1, b 탭 1' ("a={0}, b={1}, {2}" -f $nA, $nB, $tb.line) ($nA -eq 1 -and $nB -eq 1 -and (Disk-Has 'a') -and (Disk-Has 'b'))
        Check 'd046-own' 'D-046 ①' '선택은 새 a 그대로' 'selected=a' (Get-Tree).selected ((Get-Tree).selected -eq 'a')
        # 앱 작업 직후 같은 경로의 바깥 변경은 반영한다.
        $v = 'a 바깥에서 바꿈 직후'
        $r = Reflect 'd046-own' '앱 작업 직후 같은 경로 바깥 내용 바꾸기 a' { Write-Utf8 $newA $v } { (Active-Fnv) -eq (Fnv $v) } '^\[dev\] tab-reload .*result=reloaded'
        Check-Reflect 'd046-own' 'D-046 ①·G-115' '같은 경로의 바깥 변경은 보존(새 a 탭이 다시 읽음)' "active_text_fnv=$(Fnv $v)" $r
        Check 'd046-own' 'D-046 ①' '활성 탭은 새 a' $newA ((Get-Tabs).list[(Get-Tabs).active].path) ((Get-Tabs).list[(Get-Tabs).active].path -eq $newA)
        [void](Save-Window 'd046-own-after')
    }

    # ================================================================ d046-defer: ② 입력 중 미룬 묶음의 이름 바꾸기를 버림
    Reset-Proj
    Run-Case 'd046-defer' (New-StateJson @($proj) 0) {
        param($res, $p)
        Send-Keys 'ctrl-shift-e'
        Click-Row 'notes.txt'
        Park-Mouse
        Send-Keys 'home'
        Send-Keys 'ctrl-n'
        Type-Text 'typing'
        $wa0 = Count-Lines '^\[dev\] watch-applied '
        $v = 'moved 바깥에서 바꾼 내용'
        Rename-InRun (Join-Path $proj 'notes.txt') 'moved.txt'
        Write-Utf8 (Join-Path $proj 'moved.txt') $v
        $l = Wait-NewLine '^\[dev\] watch-applied ' $wa0 4
        Start-Sleep -Milliseconds 1200
        $res.during = @(Get-Lines '^\[dev\] watch-applied ' | Select-Object -Skip $wa0)
        Check 'd046-defer' 'R-24(판단)' '입력 중 바깥 변경 → 미룸, 입력칸 그대로' 'tree=deferred, panel_input' ("{0}, {1}" -f ($res.during -join ' | '), (Focus-Now)) (($res.during -join ' ') -match 'tree=deferred' -and (Focus-Now) -eq 'panel_input')
        Send-Keys 'escape'
        Start-Sleep -Milliseconds 1200
        Wait-Quiet
        $tb = Get-Tabs
        $res.tabs = $tb.line
        $moved = Join-Path $proj 'moved.txt'
        Check 'd046-defer' 'D-046 ②·R-24' '입력이 끝나면 미룬 이름 바꾸기를 적용: 탭 경로가 moved.txt' $moved $tb.line ($tb.count -eq 1 -and $tb.list[0].path -eq $moved)
        Check 'd046-defer' 'D-046 ②·G-115' '이름이 바뀐 뒤 바뀐 내용을 탭이 다시 읽음' (Fnv $v) (Active-Fnv) ((Active-Fnv) -eq (Fnv $v))
        Check 'd046-defer' 'D-046 ②' '트리에 moved.txt, 가상 행 없음' 'moved.txt 행' (Tree-Labels) ((Has-Row 'moved.txt') -and -not (Has-Row 'notes.txt') -and -not ((Tree-Labels) -match '<new file>'))
        [void](Save-Window 'd046-defer-after')
    }

    # ================================================================ d046-replace: ③ 같은 경로의 새 디렉터리로 루트가 바뀜
    # proj → proj-old, 미리 만든 proj-new → proj 를 잇달아(1초 존재 확인보다 빨리) 한다. 모두 이번 실행 폴더 안.
    Reset-Proj
    $newp = Folder 'proj-new'
    $oldp = Folder 'proj-old'
    foreach ($d in @($newp, $oldp)) { if (Test-Path -LiteralPath $d) { Remove-InRun $d } }
    Write-Utf8 (Join-Path $newp 'fresh.txt') 'fresh'
    Run-Case 'd046-replace' (New-StateJson @($proj) 0) {
        param($res, $p)
        Park-Mouse
        $s0 = Count-Lines '^\[dev\] watch-start '
        $t0 = UnixMs
        Rename-InRun $proj 'proj-old'
        Rename-InRun $newp 'proj'
        $res.swapMs = (UnixMs) - $t0
        Start-Sleep -Milliseconds 2500
        Wait-Quiet
        $res.starts = @(Get-Lines '^\[dev\] watch-start ' | Select-Object -Skip $s0)
        Check 'd046-replace' 'D-046 ③·A-16.3' '루트가 같은 경로의 새 폴더로 바뀌면 다시 감시(watch-start)' "watch-start root=…\proj (교체 $($res.swapMs)ms)" ($res.starts -join ' | ') ($res.starts.Count -ge 1 -and ($res.starts[-1] -match ('root={0} ' -f [regex]::Escape($proj))))
        Check 'd046-replace' 'D-046 ③·R-24' '새 폴더 내용으로 트리를 다시 읽음' 'fresh.txt 행, ops 행 없음' (Tree-Labels) ((Has-Row 'fresh.txt') -and -not (Has-Row 'ops'))
        $r = Reflect 'd046-replace' '바뀐 루트 안 파일 만들기 after-replace.txt' { Write-Utf8 (Join-Path $proj 'after-replace.txt') 'x' } { Has-Row 'after-replace.txt' } '^\[dev\] watch-applied ' 4
        Check-Reflect 'd046-replace' 'D-046 ③·R-24' '새 루트 안 변경이 반영됨' 'after-replace.txt 행' $r
        $wa0 = Count-Lines '^\[dev\] watch-applied '
        Write-Utf8 (Join-Path $oldp 'old-side.txt') 'x'
        Start-Sleep -Milliseconds 1500
        # 앞 변경의 늦은 폴더 수정 알림(tree=none)은 있을 수 있다. 트리를 다시 읽게 한 묶음이 없어야 한다.
        $after = @(Get-Lines '^\[dev\] watch-applied ' | Select-Object -Skip $wa0 | Where-Object { $_ -match 'tree=refreshed' })
        Check 'd046-replace' 'D-046 ③' '옛 폴더(proj-old) 변경은 받지 않음' 'tree=refreshed 묶음 없음, old-side.txt 행 없음' ("{0} | {1}" -f ($after -join ' / '), (Tree-Labels)) ($after.Count -eq 0 -and -not (Has-Row 'old-side.txt'))
        [void](Save-Window 'd046-replace-after')
        # 같은 폴더를 잠깐 다른 이름으로 바꿨다가 되돌림(정체는 같다): 루트 자신의 이름 바꾸기 이벤트로 다시 등록한다(D-046 ③).
        $rw0 = Count-Lines '^\[dev\] watch-rewatch '
        Rename-InRun $proj 'proj-tmp'
        Rename-InRun (Folder 'proj-tmp') 'proj'
        $l = Wait-NewLine '^\[dev\] watch-rewatch ' $rw0 4
        Check 'd046-replace' 'D-046 ③' '루트 자신의 이름 바꾸기 이벤트 → 정체가 같아도 다시 등록' 'watch-rewatch reason=root-event' $l ([bool]$l -and $l -match 'reason=root-event')
        $r = Reflect 'd046-replace' '되돌린 루트 안 파일 만들기 after-bounce.txt' { Write-Utf8 (Join-Path $proj 'after-bounce.txt') 'x' } { Has-Row 'after-bounce.txt' } '^\[dev\] watch-applied ' 4
        Check-Reflect 'd046-replace' 'D-046 ③·R-24' '다시 등록한 뒤 변경 반영' 'after-bounce.txt 행' $r
    }

    # ================================================================ d046-moved: ④ 다른 등록 폴더로 옮긴 열린 파일
    Reset-Proj
    $pb = Folder 'pb'
    if (Test-Path -LiteralPath $pb) { Remove-InRun $pb }
    Write-Utf8 (Join-Path $pb 'b.txt') 'b'
    Run-Case 'd046-moved' (New-StateJson @($proj, $pb) 0) {
        param($res, $p)
        Send-Keys 'ctrl-shift-e'
        Click-Row 'notes.txt'
        Send-Keys 'ctrl-x'
        Click-Box 'folder-row-01' 'activate pb'
        Wait-Quiet
        Send-Keys 'ctrl-shift-e'
        Send-Keys 'home'
        Send-Keys 'ctrl-v'
        Start-Sleep -Milliseconds 600; Wait-Quiet
        Click-Box 'folder-row-00' 'activate proj'
        Wait-Quiet
        Park-Mouse
        Start-Sleep -Milliseconds 1000
        $moved = Join-Path $pb 'notes.txt'
        $tb = Get-Tabs
        Check 'd046-moved' 'R-21·D-043 ④' 'proj 의 탭 경로가 옮긴 pb\notes.txt' $moved $tb.line ($tb.count -eq 1 -and $tb.list[0].path -eq $moved)
        $v = 'pb 로 옮긴 뒤 바깥에서 바꿈'
        $r = Reflect 'd046-moved' '루트 밖(다른 등록 폴더)으로 옮긴 열린 파일 내용 바꾸기' { Write-Utf8 $moved $v } { (Active-Fnv) -eq (Fnv $v) } '^\[dev\] tab-reload .*result=reloaded' 4
        Check-Reflect 'd046-moved' 'D-046 ④·R-24·G-115' '루트 밖 열린 파일의 바깥 변경을 탭이 다시 읽음' "active_text_fnv=$(Fnv $v)" $r
        [void](Save-Window 'd046-moved-after')
    }

    # ================================================================ d046-junction: ④ 정션 안 열린 파일(정션은 이번 실행 폴더 안)
    Reset-Proj
    $jt = Folder 'jtarget'
    if (Test-Path -LiteralPath $jt) { Remove-InRun $jt }
    Write-Utf8 (Join-Path $jt 'inside.txt') 'inside 처음'
    $jl = Join-Path $proj 'jlink'
    if (-not $jl.StartsWith($testRoot) -or -not $jt.StartsWith($testRoot)) { throw '정션이 이번 실행 폴더 밖이다' }
    New-Item -ItemType Junction -Path $jl -Target $jt | Out-Null
    Run-Case 'd046-junction' (New-StateJson @($proj) 0) {
        param($res, $p)
        Click-Row 'jlink'
        Click-Row 'inside.txt'
        Park-Mouse
        Start-Sleep -Milliseconds 1000
        $tb = Get-Tabs
        Check 'd046-junction' 'R-27' '정션 안 inside.txt 탭' (Join-Path $jl 'inside.txt') $tb.line ($tb.count -eq 1 -and $tb.list[0].path -eq (Join-Path $jl 'inside.txt'))
        $v1 = 'inside 대상 경로로 바꿈 1'
        $r = Reflect 'd046-junction' '정션 대상 경로로 열린 파일 내용 바꾸기' { Write-Utf8 (Join-Path $jt 'inside.txt') $v1 } { (Active-Fnv) -eq (Fnv $v1) } '^\[dev\] tab-reload .*result=reloaded' 4
        Check-Reflect 'd046-junction' 'D-046 ④·R-24·G-115' '정션 대상 경로로 바꾼 열린 파일을 탭이 다시 읽음' "active_text_fnv=$(Fnv $v1)" $r
        $v2 = 'inside 정션 경로로 바꿈 2'
        $r = Reflect 'd046-junction' '정션 경로로 열린 파일 내용 바꾸기' { Write-Utf8 (Join-Path $jl 'inside.txt') $v2 } { (Active-Fnv) -eq (Fnv $v2) } '^\[dev\] tab-reload .*result=reloaded' 4
        Check-Reflect 'd046-junction' 'D-046 ④·R-24·G-115' '정션 경로로 바꾼 열린 파일을 탭이 다시 읽음' "active_text_fnv=$(Fnv $v2)" $r
        [void](Save-Window 'd046-junction-after')
    }
    if ((Test-Path -LiteralPath $jl) -and (Get-Item -LiteralPath $jl -Force).LinkType -eq 'Junction') { [System.IO.Directory]::Delete($jl) }
    if (Test-Path -LiteralPath $jt) { Remove-InRun $jt }

    # ================================================================ d046-io: ⑤ 존재 확인·파일 다시 읽기가 메인 스레드를 막음
    # 응답이 느린 경로를 흉내 낸다: `--dev-slow-io slowf 3000` 은 경로에 slowf 가 든 존재 확인·탭 파일 다시 읽기를 3초 늦춘다.
    # 등록 폴더 slowf(활성 아님, 이번 실행 폴더 안)와 활성 폴더 proj 의 열린 파일 slowf-tab.txt.
    # 메인 스레드: 조용한 4초 동안의 틱 늦음(watch-tick-late), 키를 보낸 뒤 앱이 처리하기까지(focus-state 줄)를 잰다.
    Reset-Proj
    $slow = Folder 'slowf'
    if (Test-Path -LiteralPath $slow) { Remove-InRun $slow }
    Write-Utf8 (Join-Path $slow 's.txt') 's'
    $slowTab = Join-Path $proj 'slowf-tab.txt'
    Write-Utf8 $slowTab 'slow 처음'
    $script:extraArgs = @('--dev-slow-io', 'slowf', '3000')
    function Probe-Key {
        $b = Count-Lines '^\[dev\] focus-state '
        Assert-Foreground 'd046-io probe'
        $t = UnixMs
        [WgP4.Native]::Combo([uint16[]]@($VK.ctrl, $VK.shift), [uint16]$VK.e)
        $l = Wait-NewLine '^\[dev\] focus-state ' $b 10
        if ($l) { (UnixMs) - $t } else { 10000 }
    }
    function Late-Since([int]$Before) {
        @(Get-Lines '^\[dev\] watch-tick-late ' | Select-Object -Skip $Before | ForEach-Object { if ($_ -match 'gap_ms=(\d+)') { [int]$Matches[1] } })
    }
    try {
        Run-Case 'd046-io' (New-StateJson @($proj, $slow) 0) {
            param($res, $p)
            Click-Row 'slowf-tab.txt'
            Park-Mouse
            Start-Sleep -Milliseconds 1500
            Wait-Quiet 600 10
            # ① 조용한 동안(그리기 없음): 1초마다 하는 등록 폴더 존재 확인
            $tl0 = Count-Lines '^\[dev\] watch-tick-late '
            Start-Sleep -Milliseconds 4000
            $idle = Late-Since $tl0
            $res.idleGaps = $idle
            Check 'd046-io' 'D-046 ⑤' '느린 등록 폴더 존재 확인이 메인 스레드를 막지 않음(조용한 4초 동안 틱 늦음 없음)' '틱 늦음 0' ("늦음 {0}번: {1}" -f $idle.Count, ($idle -join ',')) ($idle.Count -eq 0)
            $lat = @(); for ($k = 0; $k -lt 3; $k++) { $lat += Probe-Key; Start-Sleep -Milliseconds 700 }
            $res.keyLatency = $lat
            Check 'd046-io' 'D-046 ⑤' '키 입력 응답(3번 모두 500ms 안)' '< 500ms' ($lat -join ',') (@($lat | Where-Object { $_ -ge 500 }).Count -eq 0)
            # ② 느린 경로의 열린 파일 다시 읽기
            Wait-Quiet 600 10
            $v = 'slow 바깥에서 바꿈'
            $tl1 = Count-Lines '^\[dev\] watch-tick-late '
            Write-Utf8 $slowTab $v
            Start-Sleep -Milliseconds 300
            $lat2 = Probe-Key
            $res.keyLatencyDuringReload = $lat2
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            while ($sw.Elapsed.TotalSeconds -lt 8 -and -not ((Last-Line '^\[dev\] tab-reload .*result=reloaded') -match ('fnv={0}' -f (Fnv $v)))) { Start-Sleep -Milliseconds 100 }
            Check 'd046-io' 'R-24·G-115' '느린 경로의 열린 파일도 결국 다시 읽음' "tab-reload fnv=$(Fnv $v)" (Last-Line '^\[dev\] tab-reload ') ((Last-Line '^\[dev\] tab-reload .*result=reloaded') -match ('fnv={0}' -f (Fnv $v)))
            Check 'd046-io' 'D-046 ⑤' '다시 읽는 동안에도 키 입력 응답 500ms 안' '< 500ms' $lat2 ($lat2 -lt 500)
            $res.reloadGaps = Late-Since $tl1
        }
    }
    finally { $script:extraArgs = $null }

}
catch { $results.failures += $_.Exception.Message }
finally {
    # 1) 사용자 파일 복원(가장 먼저, 파일마다 따로, D-037 ③).
    try {
        try {
            if ($backupDone) {
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
                $results.restoreSteps = [ordered]@{ restored = $backupNames }
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
    # 2) 백업 지우기(복원 확인 때만), 이번 실행 시험 폴더만 지우기(D-040).
    if ($backupDone -and $results.userFiles -and $results.userFiles.restored) {
        try { Remove-Item -LiteralPath $backupDir -Recurse -Force } catch { $results.errors += "백업 지우기: $($_.Exception.Message)" }
    }
    try { Remove-TestFolders } catch { $results.errors += "시험 폴더 지우기: $($_.Exception.Message)" }
    $results.testFolders = [ordered]@{ base = $testBase; run = $testRoot; runFolderLeft = (Test-Path -LiteralPath $testRoot); baseLeft = (Test-Path -LiteralPath $testBase) }
    [void][WgP4.Native]::SetThreadDpiAwarenessContext($prevDpi)
    foreach ($e in $results.errors) { $results.failures += "정리 오류: $e" }
}

$results.finishedAt = (Get-Date).ToString('o')
$results.passed = ($results.failures.Count -eq 0)
$results | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $out 'results.json') -Encoding utf8
# 반영 시간 표(LATENCY.md 에 옮겨 적는다).
$lat = @('| 사례 | 바깥 변경 | 반영 | recv_ms | app_ms | seen_ms |', '| --- | --- | --- | ---: | ---: | ---: |')
foreach ($e in $results.latency) { $lat += ('| {0} | {1} | {2} | {3} | {4} | {5} |' -f $e.case, $e.what, $(if ($e.ok) { '됨' } else { '안 됨' }), $e.recv_ms, $e.app_ms, $e.seen_ms) }
Set-Content -LiteralPath (Join-Path $out 'latency.md') -Value $lat -Encoding utf8
"cases: $(@($results.cases.get_Keys()) -join ', ')"
"checks: $($results.checks.Count), failed: $(@($results.checks | Where-Object { -not $_.ok }).Count)"
"failures: $($results.failures.Count)"
"user files restored: $($results.userFiles.restored)"
$results.failures | ForEach-Object { "  - $_" }
if ($results.failures.Count -gt 0) { exit 1 }

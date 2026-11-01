#Requires -Version 7
<#
.SYNOPSIS
  v0.2 Phase 5 (SPEC R-24, D-6·D-9·D-18, G-115, A-16.3) 증거: 디스크 감시·변경 감지.
  바깥 프로그램(이 스크립트의 PowerShell)이 시험 폴더에서 만들기·지우기·이름 바꾸기·내용 바꾸기를 하면 트리·탭에 반영되는지,
  등록 폴더가 사라지면 "경로 없음" 상태가 되는지, 반영까지 걸린 시간을 잰다. 감시자 수명(폴더 전환·해제·사라짐 때 해제),
  이벤트 폭주 묶기, 앱 자신의 파일 작업과 바깥 변경 구분도 본다.

.DESCRIPTION
  앱을 `--dev-keymap --dev-layout --dev-pick-folder <파일> --dev-no-shell` 로 사례마다 새로 띄운다.
  쓰는 앱 출력: [dev] tree / tabs / watch-start / watch-stop / watch-applied / watch-missing / watch-refresh / tab-reload /
  folder-row / focus-state / layout-box / layout 머리 줄(active_text_fnv).
  반영 시간: 바깥 변경 직전 시각(Unix ms)과 앱이 반영한 줄의 t_ms 의 차(app_ms), 스크립트가 반영을 본 시각과의 차(seen_ms).

  안전 규칙(Phase 3 D-037·D-040, Phase 4 와 같다):
    - 시작 전에 workbench-gpui 가 이미 실행 중이면 사용자 파일을 바꾸기 전에 멈춘다. 띄운 프로세스(PID)만 닫는다.
    - 키·마우스를 보내기 직전마다 고정한 창이 전면인지, 마우스 아래 최상위 창이 그 창인지 확인한다.
    - %APPDATA%\workbench-gpui 의 state.json*·keymap.json 은 백업하고 끝에 파일마다 따로 되돌린다. 전후 SHA-256 을 남긴다.
    - 시험 폴더는 target\phase5-folders\run-<id> 에 이번 실행만 만들고(표지 .wg-p5-run), 끝에 표지가 같을 때만 지운다.
      바깥 변경은 모두 이 폴더 안에서만 한다. 휴지통·OS 클립보드는 쓰지 않는다.

  결과: specs/v0.2/verify/phase5/ 의 <사례>-stdout.txt, 스크린샷, results.json(latency 표 포함).

.EXAMPLE
  pwsh -NoProfile -File tools/verify-v02-phase5.ps1
  pwsh -NoProfile -Command "& ./tools/verify-v02-phase5.ps1 -Only tree,tab"
#>
[CmdletBinding()]
param(
    [string]$Exe = 'target\debug\workbench-gpui.exe',
    [string]$OutDir = 'specs\v0.2\verify\phase5',
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

    # ================================================================ tree: R-24 바깥 만들기·지우기·이름 바꾸기 → 트리 (G-115, G-016)
    Reset-Proj
    Run-Case 'tree' (New-StateJson @($proj) 0) {
        param($res, $p)
        $start = Last-Line '^\[dev\] watch-start '
        Check 'tree' 'R-24·D-6' '활성 폴더 감시 시작(루트 하위까지, 부모 한 단계)' "watch-start root=$proj parent_watched=true" $start ($start -match ('root={0} parent_watched=true' -f [regex]::Escape($proj)))
        Click-Row 'ops'
        Click-Row 'sub'
        Click-Row 's.txt'
        Park-Mouse
        $res.treeBefore = (Get-Tree).line
        $ops = Join-Path $proj 'ops'
        $r = Reflect 'tree' '파일 만들기 ops\new-ext.txt' { Write-Utf8 (Join-Path $ops 'new-ext.txt') 'ext' } { Has-Row 'new-ext.txt' }
        Check-Reflect 'tree' 'R-24' '바깥에서 만든 파일이 트리에 나타남' 'new-ext.txt 행' $r
        $r = Reflect 'tree' '폴더 만들기 ops\newdir' { New-Item -ItemType Directory -Path (Join-Path $ops 'newdir') | Out-Null } { Has-Row 'newdir' }
        Check-Reflect 'tree' 'R-24' '바깥에서 만든 폴더가 트리에 나타남' 'newdir 행(닫힘)' $r
        $r = Reflect 'tree' '파일 지우기 ops\f3.txt' { Remove-InRun (Join-Path $ops 'f3.txt') } { -not (Has-Row 'f3.txt') }
        Check-Reflect 'tree' 'R-24' '바깥에서 지운 파일이 트리에서 사라짐' 'f3.txt 행 없음' $r
        $r = Reflect 'tree' '파일 이름 바꾸기 ops\f1.txt → f1-renamed.txt' { Rename-InRun (Join-Path $ops 'f1.txt') 'f1-renamed.txt' } { (Has-Row 'f1-renamed.txt') -and -not (Has-Row 'f1.txt') }
        Check-Reflect 'tree' 'R-24' '바깥에서 이름을 바꾼 파일이 새 이름으로' 'f1-renamed.txt 있음, f1.txt 없음' $r
        $r = Reflect 'tree' '폴더 지우기 ops\newdir' { Remove-InRun (Join-Path $ops 'newdir') } { -not (Has-Row 'newdir') }
        Check-Reflect 'tree' 'R-24' '바깥에서 지운 폴더가 트리에서 사라짐' 'newdir 행 없음' $r
        # 펼친 폴더 이름 바꾸기: 펼침·선택·탭 경로가 새 이름을 따라간다(판단).
        $r = Reflect 'tree' '펼친 폴더 이름 바꾸기 ops\sub → sub2' { Rename-InRun (Join-Path $ops 'sub') 'sub2' } { (Has-Row 'sub2') -and -not (Has-Row 'sub') }
        Check-Reflect 'tree' 'R-24' '바깥에서 이름을 바꾼 폴더가 새 이름으로' 'sub2 행' $r
        $t = Get-Tree
        $tb = Get-Tabs
        $res.afterRename = $t.line
        Check 'tree' 'R-24(판단)' '이름이 바뀐 펼친 폴더: 펼침·선택을 따라감' 'expanded ops\sub2, selected ops\sub2\s.txt' ("expanded={0}, selected={1}" -f ($t.expanded -join ';'), $t.selected) (($t.expanded -contains 'ops\sub2') -and $t.selected -eq 'ops\sub2\s.txt' -and ((Get-Tree).rows | Where-Object { $_.label -eq 'sub2' }).kind -eq 'open')
        Check 'tree' 'R-24(판단)·R-27' '열린 탭 경로도 새 이름을 따라감' '...\ops\sub2\s.txt' $tb.line (@($tb.list | Where-Object { $_.path -eq (Join-Path $ops 'sub2\s.txt') }).Count -eq 1)
        # 접힌 폴더 안의 변경: 보이는 행은 그대로지만 펼치면 새 항목이 보인다(목록 저장을 비운다).
        $n0 = Count-Lines '^\[dev\] watch-applied '
        $r = Reflect 'tree' '접힌 폴더 안 파일 만들기 src\added.rs' { Write-Utf8 (Join-Path $proj 'src\added.rs') 'x' } { (Count-Lines '^\[dev\] watch-applied ') -gt $n0 -and (Last-Line '^\[dev\] watch-applied ') -match 'tree=refreshed' }
        Check-Reflect 'tree' 'R-24' '접힌 폴더 안 변경도 받아 다시 읽음' 'watch-applied tree=refreshed' $r
        Click-Row 'src'
        Check 'tree' 'R-24' '접힌 폴더를 펼치면 바깥에서 만든 항목이 보임' 'added.rs 행' (Tree-Labels) (Has-Row 'added.rs')
        Park-Mouse
        Start-Sleep -Milliseconds 500
        [void](Save-Window 'tree-after')
        $res.treeAfter = (Get-Tree).line
        $ap = @(Get-Lines '^\[dev\] watch-applied ')
        Check 'tree' 'R-24' '바깥 변경은 바깥으로 셈(앱 자신 작업 0)' 'own=0 모든 줄' ($ap -join ' | ') (($ap | Where-Object { $_ -notmatch ' own=0 ' }).Count -eq 0 -and $ap.Count -gt 0)
    }

    # ================================================================ tab: R-24 열린 탭 내용 다시 읽기 (E-086 앞부분, G-115, D-18)
    Reset-Proj
    Run-Case 'tab' (New-StateJson @($proj) 0) {
        param($res, $p)
        $readme = Join-Path $proj 'README.md'
        $notes = Join-Path $proj 'notes.txt'
        Double-Open 'tab' 'notes.txt'
        Click-Row 'README.md'
        Park-Mouse
        Start-Sleep -Milliseconds 500
        $res.tabsBefore = (Get-Tabs).line
        Check 'tab' 'R-27' '탭 둘: notes.txt 일반, README.md 활성' 'README.md 활성' (Tabs-Text) ((Get-Tabs).count -eq 2 -and (Get-Tabs).list[(Get-Tabs).active].title -eq 'README.md')
        $v1 = "# README`r`n바깥에서 바꾼 내용 1`r`n"
        $r = Reflect 'tab' '활성 탭 파일 내용 바꾸기 README.md' { Write-Utf8 $readme $v1 } { (Active-Fnv) -eq (Fnv $v1) } '^\[dev\] tab-reload .*result=reloaded'
        Check-Reflect 'tab' 'R-24·E-086·G-115' '활성 탭 내용을 자동으로 다시 읽음' "active_text_fnv=$(Fnv $v1)" $r
        Check 'tab' 'R-24' 'tab-reload 줄의 길이·FNV' ("len={0} fnv={1}" -f [System.Text.Encoding]::UTF8.GetByteCount($v1), (Fnv $v1)) $r.last ($r.last -match ("len={0} fnv={1}" -f [System.Text.Encoding]::UTF8.GetByteCount($v1), (Fnv $v1)))
        [void](Save-Window 'tab-reloaded')
        $n1 = "notes 바깥에서 바꿈"
        $r = Reflect 'tab' '활성이 아닌 탭 파일 내용 바꾸기 notes.txt' { Write-Utf8 $notes $n1 } { (Last-Line '^\[dev\] tab-reload .*result=reloaded') -match ('path={0} .*fnv={1}' -f [regex]::Escape($notes), (Fnv $n1)) } '^\[dev\] tab-reload .*result=reloaded'
        Check-Reflect 'tab' 'R-24·G-115' '활성이 아닌 탭도 다시 읽음' "tab-reload path=notes.txt fnv=$(Fnv $n1)" $r
        # 같은 내용으로 다시 쓰기: 감시는 받지만 탭은 바꾸지 않는다(내용 비교).
        $rl0 = Count-Lines '^\[dev\] tab-reload .*result=reloaded'
        $wa0 = Count-Lines '^\[dev\] watch-applied '
        $r = Reflect 'tab' '같은 내용으로 다시 쓰기 README.md' { Write-Utf8 $readme $v1 } { (Count-Lines '^\[dev\] watch-applied ') -gt $wa0 }
        Start-Sleep -Milliseconds 400
        Check 'tab' 'R-24(판단)' '내용이 같으면 탭을 다시 넣지 않음' "tab-reload 줄 $rl0 그대로" (Count-Lines '^\[dev\] tab-reload .*result=reloaded') ($r.ok -and (Count-Lines '^\[dev\] tab-reload .*result=reloaded') -eq $rl0)
        # 편집기식 저장(임시 파일에 쓰고 바꿔 넣기).
        $v2 = "# README`r`n바깥 저장 2(임시 파일 바꿔 넣기)`r`n"
        $r = Reflect 'tab' '임시 파일에 쓰고 바꿔 넣기 README.md' { Write-Utf8 "$readme.tmp~" $v2; Move-Item -LiteralPath "$readme.tmp~" -Destination $readme -Force } { (Active-Fnv) -eq (Fnv $v2) } '^\[dev\] tab-reload .*result=reloaded'
        Check-Reflect 'tab' 'R-24·G-115' '바꿔 넣은 파일도 다시 읽음' "active_text_fnv=$(Fnv $v2)" $r
        Start-Sleep -Milliseconds 400
        Check 'tab' 'R-24' '임시 파일은 트리에 남지 않음' 'README.md.tmp~ 행 없음' (Tree-Labels) (-not (Has-Row 'README.md.tmp~'))
        # 지우기: 탭은 그대로(지워진 파일 표시는 이후 버전, D-18·E-087).
        $r = Reflect 'tab' '열린 파일 지우기 README.md' { Remove-InRun $readme } { -not (Has-Row 'README.md') }
        Check-Reflect 'tab' 'R-24' '지운 파일은 트리에서 사라짐' 'README.md 행 없음' $r
        Start-Sleep -Milliseconds 400
        $tb = Get-Tabs
        Check 'tab' 'D-18·E-087' '지운 파일의 탭은 그대로, 내용도 그대로(표시는 이후 버전)' "탭 2개, README.md 활성, fnv $(Fnv $v2)" ("{0}, fnv={1}" -f (Tabs-Text), (Active-Fnv)) ($tb.count -eq 2 -and $tb.list[$tb.active].title -eq 'README.md' -and (Active-Fnv) -eq (Fnv $v2))
        $v3 = "# README`r`n다시 만든 내용 3`r`n"
        $r = Reflect 'tab' '지운 파일 다시 만들기 README.md' { Write-Utf8 $readme $v3 } { (Active-Fnv) -eq (Fnv $v3) } '^\[dev\] tab-reload .*result=reloaded'
        Check-Reflect 'tab' 'R-24·G-115' '다시 만든 파일 내용을 탭이 읽음' "active_text_fnv=$(Fnv $v3)" $r
        [void](Save-Window 'tab-recreated')
        Check 'tab' 'D-18' '보기 전용 탭: 다시 읽은 뒤에도 탭 수·종류 그대로' $res.tabsBefore (Get-Tabs).line ((Get-Tabs).line -eq $res.tabsBefore)
    }

    # ================================================================ root: R-24·A-16.3 실행 중 등록 폴더가 사라짐 → R-15 경로 없음
    Reset-Proj
    Run-Case 'root' (New-StateJson @($proj, $proj2) 0) {
        param($res, $p)
        $gone = Join-Path $testRoot 'proj-gone'
        Check 'root' 'R-24' '시작: 활성 proj 감시' 'watch-start root=proj' (Last-Line '^\[dev\] watch-start ') ((Last-Line '^\[dev\] watch-start ') -match ('root={0} ' -f [regex]::Escape($proj)))
        # ① 활성 폴더 이름 바꾸기(사라짐)
        $ws0 = Count-Lines '^\[dev\] watch-stop '
        $r = Reflect 'root' '활성 등록 폴더 이름 바꾸기 proj → proj-gone' { Rename-InRun $proj 'proj-gone' } { Folder-Missing 0 } '^\[dev\] watch-missing '
        Check-Reflect 'root' 'R-24·A-16.3' '활성 폴더가 사라지면 경로 없음 상태' 'folder-row index=0 missing=true' $r
        $box = Wait-Box 'project-missing-text' 3
        Check 'root' 'R-15·A-16.2' '트리 자리에 안내와 Remove 버튼' 'project-missing-text, project-missing-remove' ("{0}, {1}" -f [bool]$box, [bool](Get-Box 'project-missing-remove')) ([bool]$box -and [bool](Get-Box 'project-missing-remove'))
        Check 'root' 'R-24(감시 해제)' '사라진 폴더 감시 해제' 'watch-stop folder=…0000' (Last-Line '^\[dev\] watch-stop ') ((Count-Lines '^\[dev\] watch-stop ') -gt $ws0 -and (Last-Line '^\[dev\] watch-stop ') -match 'folder=00000000-0000-4000-8000-000000000000 ')
        [void](Save-Window 'root-missing')
        # ② 되돌리기(다시 생김)
        $r = Reflect 'root' '이름 되돌리기 proj-gone → proj' { Rename-InRun $gone 'proj' } { -not (Folder-Missing 0) -and (Has-Row 'ops') } '^\[dev\] watch-missing '
        Check-Reflect 'root' 'R-24·A-16.3' '폴더가 다시 생기면 트리로 돌아감' 'missing=false, ops 행' $r
        Check 'root' 'R-24' '다시 감시' 'watch-start root=proj' (Last-Line '^\[dev\] watch-start ') ((Last-Line '^\[dev\] watch-start ') -match ('root={0} ' -f [regex]::Escape($proj)))
        $r = Reflect 'root' '되돌린 뒤 바깥 파일 만들기 back.txt' { Write-Utf8 (Join-Path $proj 'back.txt') 'b' } { Has-Row 'back.txt' }
        Check-Reflect 'root' 'R-24' '다시 감시한 폴더의 변경 반영' 'back.txt 행' $r
        # ③ 활성이 아닌 등록 폴더 지우기(1초마다 확인)
        $r = Reflect 'root' '활성이 아닌 등록 폴더 지우기 proj2' { Remove-InRun $proj2 } { Folder-Missing 1 } '^\[dev\] watch-missing '
        Check-Reflect 'root' 'R-24·A-16.3·A-12.7' '활성이 아닌 폴더가 사라져도 사이드바에 경로 없음' 'folder-row index=1 missing=true' $r
        [void](Save-Window 'root-inactive-missing')
        $r = Reflect 'root' '활성이 아닌 등록 폴더 다시 만들기 proj2' { Write-Utf8 (Join-Path $proj2 'b-readme.md') '# proj2 한글'; Write-Utf8 (Join-Path $proj2 'other.txt') 'other' } { -not (Folder-Missing 1) } '^\[dev\] watch-missing '
        Check-Reflect 'root' 'R-24' '다시 생기면 경로 없음 해제' 'folder-row index=1 missing=false' $r
        # ④ 활성 폴더 통째로 지우기
        $r = Reflect 'root' '활성 등록 폴더 지우기 proj' { Remove-InRun $proj } { Folder-Missing 0 } '^\[dev\] watch-missing '
        Check-Reflect 'root' 'R-24·A-16.3' '활성 폴더를 지우면 경로 없음 상태' 'folder-row index=0 missing=true' $r
        Start-Sleep -Milliseconds 1200
        Check 'root' 'R-24(감시 해제)' '감시가 잡고 있지 않아 폴더가 실제로 지워짐' 'Test-Path proj = False' (Test-Path -LiteralPath $proj) (-not (Test-Path -LiteralPath $proj))
        $box = Wait-Box 'project-missing-remove' 3
        Click-Box 'project-missing-remove' 'Remove missing folder'
        Wait-Quiet
        Check 'root' 'R-24(감시 해제)·A-13.5' 'Remove → proj2 활성, proj2 감시' 'watch-start root=proj2' (Last-Line '^\[dev\] watch-start ') ((Last-Line '^\[dev\] watch-start ') -match ('root={0} ' -f [regex]::Escape($proj2)))
    }

    # ================================================================ switch: 감시자 수명 — 폴더 전환·해제 때 감시 해제(R-24, D-7)
    # h1\pa, h2\pb 두 폴더. 감시 중인 폴더의 윗 폴더(h1)는 Windows 가 이름 바꾸기를 막는다(감시 핸들). 그래서 h1 이름 바꾸기가
    # 되는지로 감시 핸들을 실제로 놓았는지 본다. 모두 이번 실행 폴더 안이다.
    $pa = Folder 'h1\pa'; $pb = Folder 'h2\pb'
    foreach ($d in @((Folder 'h1'), (Folder 'h2'))) { if (Test-Path -LiteralPath $d) { Remove-InRun $d } }
    Write-Utf8 (Join-Path $pa 'a.txt') 'a 처음'
    Write-Utf8 (Join-Path $pb 'b.txt') 'b'
    function Try-RenameHolder([string]$Holder) {
        $src = Folder $Holder
        try { Rename-InRun $src "$Holder-x"; Rename-InRun (Folder "$Holder-x") $Holder; return 'renamed' }
        catch { return "blocked: $($_.Exception.Message)" }
    }
    Run-Case 'switch' (New-StateJson @($pa, $pb) 0) {
        param($res, $p)
        Check 'switch' 'R-24' '시작: pa 감시' 'watch-start root=…\h1\pa' (Last-Line '^\[dev\] watch-start ') ((Last-Line '^\[dev\] watch-start ') -match ('root={0} ' -f [regex]::Escape($pa)))
        Click-Row 'a.txt'
        Park-Mouse
        $res.holderWhileWatched = Try-RenameHolder 'h1'
        Check 'switch' '관찰(Windows)' '감시 중인 폴더의 윗 폴더 이름 바꾸기는 막힘(감시 핸들)' 'blocked' $res.holderWhileWatched ($res.holderWhileWatched -like 'blocked*')
        # ① 폴더 전환 → pa 감시 해제, pb 감시
        $stop0 = Count-Lines '^\[dev\] watch-stop '
        Click-Box 'folder-row-01' 'activate pb'
        Wait-Quiet
        Check 'switch' 'R-24(감시 해제)' '전환: pa watch-stop, pb watch-start' 'watch-stop …0000 via=activate, watch-start root=…\h2\pb' ("{0} | {1}" -f (Last-Line '^\[dev\] watch-stop '), (Last-Line '^\[dev\] watch-start ')) ((Count-Lines '^\[dev\] watch-stop ') -eq $stop0 + 1 -and (Last-Line '^\[dev\] watch-stop ') -match 'folder=00000000-0000-4000-8000-000000000000 .*via=activate' -and (Last-Line '^\[dev\] watch-start ') -match ('root={0} ' -f [regex]::Escape($pb)))
        Start-Sleep -Milliseconds 300
        $res.holderAfterSwitch = Try-RenameHolder 'h1'
        Check 'switch' 'R-24(감시 해제)' '전환 뒤 pa 의 윗 폴더 이름 바꾸기가 됨(핸들을 놓음)' 'renamed' $res.holderAfterSwitch ($res.holderAfterSwitch -eq 'renamed')
        Start-Sleep -Milliseconds 1500
        # ② 활성이 아닌 폴더의 변경은 받지 않는다(감시하지 않음)
        $wa0 = Count-Lines '^\[dev\] watch-applied '
        Write-Utf8 (Join-Path $pa 'inactive.txt') 'i'
        Write-Utf8 (Join-Path $pa 'a.txt') 'a 바깥에서 바꿈(활성 아님)'
        Check 'switch' 'R-24' '활성이 아닌 폴더 변경 → 감시 줄 없음' "watch-applied $wa0 그대로(1.5초)" (Count-Lines '^\[dev\] watch-applied ') (No-NewLine '^\[dev\] watch-applied ' $wa0 1.5)
        $r = Reflect 'switch' 'pb 안 파일 만들기 b2.txt' { Write-Utf8 (Join-Path $pb 'b2.txt') 'b2' } { Has-Row 'b2.txt' }
        Check-Reflect 'switch' 'R-24' '새 활성 폴더 변경은 반영' 'b2.txt 행' $r
        # ③ 다시 pa → 활성이 아닐 때의 변경을 활성화 때 읽음(트리·탭)
        Click-Box 'folder-row-00' 'activate pa'
        Wait-Quiet
        Start-Sleep -Milliseconds 500
        Check 'switch' 'R-24·A-15.2' '다시 활성화: 그동안 생긴 inactive.txt 가 트리에' 'inactive.txt 행' (Tree-Labels) (Has-Row 'inactive.txt')
        Check 'switch' 'R-24·G-115' '다시 활성화: 그동안 바뀐 a.txt 를 탭이 다시 읽음' (Fnv 'a 바깥에서 바꿈(활성 아님)') (Active-Fnv) ((Active-Fnv) -eq (Fnv 'a 바깥에서 바꿈(활성 아님)'))
        Check 'switch' 'R-24' '다시 pa 감시' 'watch-start root=…\h1\pa via=activate' (Last-Line '^\[dev\] watch-start ') ((Last-Line '^\[dev\] watch-start ') -match ('root={0} .*via=activate' -f [regex]::Escape($pa)))
        # ④ 활성 폴더 해제 → 감시 해제
        RightClick-Box 'folder-row-00'
        Click-Box 'ctx-menu-row-3' 'Remove pa'
        Wait-Quiet
        Start-Sleep -Milliseconds 300
        $res.holderAfterRemove = Try-RenameHolder 'h1'
        Check 'switch' 'R-24(감시 해제)' '해제 뒤 pa 윗 폴더 이름 바꾸기가 됨' 'renamed, watch-start root=…\h2\pb' ("{0}, {1}" -f $res.holderAfterRemove, (Last-Line '^\[dev\] watch-start ')) ($res.holderAfterRemove -eq 'renamed' -and (Last-Line '^\[dev\] watch-start ') -match ('root={0} ' -f [regex]::Escape($pb)))
        # ⑤ 마지막 폴더 해제 → 감시 없음
        $start0 = Count-Lines '^\[dev\] watch-start '
        RightClick-Box 'folder-row-00'
        # 폴더가 하나면 메뉴는 Remove 한 줄이다(I-940 순서 항목 없음).
        Click-Box 'ctx-menu-row-0' 'Remove pb'
        Wait-Quiet
        Start-Sleep -Milliseconds 300
        $res.holder2AfterRemove = Try-RenameHolder 'h2'
        Check 'switch' 'R-24(감시 해제)' '모든 폴더 해제 → watch-stop, 새 감시 없음, h2 이름 바꾸기 됨' 'watch-stop via=remove, renamed' ("{0}, start+{1}, {2}" -f (Last-Line '^\[dev\] watch-stop '), ((Count-Lines '^\[dev\] watch-start ') - $start0), $res.holder2AfterRemove) ((Last-Line '^\[dev\] watch-stop ') -match 'folder=00000000-0000-4000-8000-000000000001 .*via=remove' -and (Count-Lines '^\[dev\] watch-start ') -eq $start0 -and $res.holder2AfterRemove -eq 'renamed')
        [void](Save-Window 'switch-empty')
    }

    # ================================================================ own: 앱 자신의 파일 작업과 바깥 변경 구분, 인라인 입력 중 미루기
    Reset-Proj
    Run-Case 'own' (New-StateJson @($proj) 0) {
        param($res, $p)
        Send-Keys 'ctrl-shift-e'
        # ① 앱 자신의 이름 바꾸기(F2): 감시 이벤트는 own 으로 세고, 탭을 다시 넣지 않고, 트리·선택은 그대로다.
        Click-Row 'notes.txt'
        Park-Mouse
        $wa0 = Count-Lines '^\[dev\] watch-applied '
        $rl0 = Count-Lines '^\[dev\] tab-reload '
        Send-Keys 'f2'
        Type-Text 'renamed'
        Send-Keys 'enter'
        $l = Wait-NewLine '^\[dev\] watch-applied ' $wa0 4
        Start-Sleep -Milliseconds 500
        $treeAfterOp = Get-Tree
        $tc = Count-Lines '^\[dev\] tree folder='
        Start-Sleep -Milliseconds 800
        $ap = @(Get-Lines '^\[dev\] watch-applied ' | Select-Object -Skip $wa0)
        $res.ownApplied = $ap
        Check 'own' 'R-24(구분)' '앱 자신의 이름 바꾸기 → 감시 이벤트는 모두 own, external=0' 'own>0 external=0' ($ap -join ' | ') ($ap.Count -gt 0 -and ($ap | Where-Object { $_ -notmatch ' external=0 ' -or $_ -match ' own=0 ' }).Count -eq 0)
        Check 'own' 'R-24(구분)' '앱 작업 뒤 감시 반영이 탭을 다시 넣지 않음' "tab-reload $rl0 그대로" (Count-Lines '^\[dev\] tab-reload ') ((Count-Lines '^\[dev\] tab-reload ') -eq $rl0)
        Check 'own' 'R-24(구분)' '선택은 앱이 정한 새 이름 그대로' 'selected=renamed.txt' $treeAfterOp.selected ($treeAfterOp.selected -eq 'renamed.txt' -and (Get-Tree).selected -eq 'renamed.txt')
        Check 'own' 'R-24(구분)' '탭 경로는 앱이 바꾼 새 경로 하나' 'renamed.txt 탭 하나' (Tabs-Text) (@((Get-Tabs).list | Where-Object { $_.title -eq 'renamed.txt' }).Count -eq 1 -and (Get-Tabs).count -eq 1)
        # ② 앱 작업 바로 뒤의 바깥 변경은 바깥으로 센다.
        $r = Reflect 'own' '앱 작업 직후 바깥 파일 만들기 after-own.txt' { Write-Utf8 (Join-Path $proj 'after-own.txt') 'x' } { Has-Row 'after-own.txt' }
        Check-Reflect 'own' 'R-24(구분)' '앱 작업 직후(3초 안) 다른 경로의 바깥 변경도 반영' 'after-own.txt 행' $r
        Check 'own' 'R-24(구분)' '그 묶음은 external 로 셈' 'external>=1' $r.last ($r.last -match ' external=[1-9]')
        # ③ 인라인 입력 중의 바깥 변경: 트리를 다시 만들지 않고 미뤘다가 입력이 끝나면 반영한다.
        Send-Keys 'home'
        Send-Keys 'ctrl-n'
        Type-Text 'typing'
        $edit0 = Last-Line '^\[dev\] edit '
        $wa1 = Count-Lines '^\[dev\] watch-applied '
        Write-Utf8 (Join-Path $proj 'during-edit.txt') 'x'
        $l = Wait-NewLine '^\[dev\] watch-applied ' $wa1 4
        Start-Sleep -Milliseconds 300
        Check 'own' 'R-24(판단)' '입력 중 바깥 변경 → 트리 미룸(tree=deferred), 입력칸 그대로' 'tree=deferred, panel_input, <new file> 행' ("{0}, {1}, {2}" -f $l, (Focus-Now), (Tree-Labels)) ($l -match 'tree=deferred' -and (Focus-Now) -eq 'panel_input' -and (Tree-Labels) -match '<new file>' -and -not (Has-Row 'during-edit.txt'))
        [void](Save-Window 'own-deferred')
        $rf0 = Count-Lines '^\[dev\] watch-refresh via=deferred'
        Send-Keys 'escape'
        $l = Wait-NewLine '^\[dev\] watch-refresh via=deferred' $rf0 3
        Start-Sleep -Milliseconds 300
        Check 'own' 'R-24(판단)' '입력이 끝나면 미룬 다시 읽기 → during-edit.txt 행' 'watch-refresh via=deferred, during-edit.txt' ("{0}, {1}" -f $l, (Tree-Labels)) ([bool]$l -and (Has-Row 'during-edit.txt') -and -not ((Tree-Labels) -match '<new file>'))
    }

    # ================================================================ flood: 이벤트 폭주 묶기(R-24)
    Reset-Proj
    Run-Case 'flood' (New-StateJson @($proj) 0) {
        param($res, $p)
        $fd = Join-Path $proj 'flood'
        $r = Reflect 'flood' '폴더 만들기 flood' { New-Item -ItemType Directory -Path $fd | Out-Null } { Has-Row 'flood' }
        Check-Reflect 'flood' 'R-24' 'flood 폴더 나타남' 'flood 행' $r
        Click-Row 'flood'
        Park-Mouse
        $N = 600
        function Flood-Rows { @((Get-Tree).rows | Where-Object { $_.depth -eq 2 -and $_.label -like 'fl-*' }).Count }
        $wa0 = Count-Lines '^\[dev\] watch-applied '
        $st0 = Count-Lines '^\[dev\] watch-refresh via=settle'
        $r = Reflect 'flood' "파일 $N 개 한꺼번에 만들기" { for ($i = 0; $i -lt $N; $i++) { [System.IO.File]::WriteAllText((Join-Path $fd ('fl-{0:d4}.txt' -f $i)), "$i") } } { (Flood-Rows) -eq $N } '^\[dev\] watch-(applied|refresh) ' 15
        Check-Reflect 'flood' 'R-24' "바깥에서 만든 $N 개가 모두 트리에" "flood 아래 $N 행" $r
        Start-Sleep -Milliseconds 1000
        $ap = @(Get-Lines '^\[dev\] watch-applied ' | Select-Object -Skip $wa0)
        $events = ($ap | ForEach-Object { if ($_ -match ' events=(\d+) ') { [int]$Matches[1] } } | Measure-Object -Sum).Sum
        $res.floodApplied = $ap
        $res.floodEvents = $events
        Check 'flood' 'R-24(묶기)' "이벤트 $events 개를 몇 번에 묶어 반영" '반영 10번 이하' ("반영 {0}번, 이벤트 {1}" -f $ap.Count, $events) ($ap.Count -le 10 -and $ap.Count -ge 1)
        Check 'flood' 'R-24(묶기)' '많은 묶음 뒤 한 번 더 다시 읽기(settle)' 'watch-refresh via=settle' (Last-Line '^\[dev\] watch-refresh via=settle') ((Count-Lines '^\[dev\] watch-refresh via=settle') -gt $st0)
        Check 'flood' 'R-24' '폭주 뒤 트리 행 수 = 디스크' "$N" (Flood-Rows) ((Flood-Rows) -eq @(Get-ChildItem -LiteralPath $fd -File).Count)
        [void](Save-Window 'flood-created')
        $wa1 = Count-Lines '^\[dev\] watch-applied '
        $r = Reflect 'flood' "파일 $N 개 한꺼번에 지우기" { Get-ChildItem -LiteralPath $fd -File | ForEach-Object { [System.IO.File]::Delete($_.FullName) } } { (Flood-Rows) -eq 0 } '^\[dev\] watch-(applied|refresh) ' 15
        Check-Reflect 'flood' 'R-24' "바깥에서 지운 $N 개가 모두 트리에서 사라짐" 'flood 아래 0 행' $r
        Start-Sleep -Milliseconds 1000
        $ap = @(Get-Lines '^\[dev\] watch-applied ' | Select-Object -Skip $wa1)
        Check 'flood' 'R-24(묶기)' '지우기 폭주도 묶어 반영' '반영 10번 이하' ("반영 {0}번" -f $ap.Count) ($ap.Count -le 10 -and $ap.Count -ge 1)
    }

    # ================================================================ junction: 정션 안 변경(관찰, 알려진 한계 확인)
    # 정션은 이번 실행 폴더 안에만 만든다: proj\jlink → run\jtarget.
    Reset-Proj
    $jt = Folder 'jtarget'
    if (Test-Path -LiteralPath $jt) { Remove-InRun $jt }
    Write-Utf8 (Join-Path $jt 'inside.txt') 'i'
    $jl = Join-Path $proj 'jlink'
    if (-not $jl.StartsWith($testRoot) -or -not $jt.StartsWith($testRoot)) { throw '정션이 이번 실행 폴더 밖이다' }
    New-Item -ItemType Junction -Path $jl -Target $jt | Out-Null
    Run-Case 'junction' (New-StateJson @($proj) 0) {
        param($res, $p)
        Click-Row 'jlink'
        Park-Mouse
        $r = Reflect 'junction' '정션 대상 경로로 파일 만들기 jtarget\via-target.txt' { Write-Utf8 (Join-Path $jt 'via-target.txt') 'x' } { Has-Row 'via-target.txt' } '^\[dev\] watch-applied ' 3
        Observe 'junction' '정션 대상 경로로 만든 파일이 펼친 정션 아래에 바로 보이나' ("{0} (app_ms={1})" -f $r.ok, $r.app_ms)
        $r = Reflect 'junction' '정션 경로로 파일 만들기 jlink\via-link.txt' { Write-Utf8 (Join-Path $jl 'via-link.txt') 'x' } { Has-Row 'via-link.txt' } '^\[dev\] watch-applied ' 3
        Observe 'junction' '정션 경로로 만든 파일이 바로 보이나' ("{0} (app_ms={1})" -f $r.ok, $r.app_ms)
        # 루트 안 다른 변경이 오면 전부 다시 읽으므로 그때 함께 보인다.
        $r = Reflect 'junction' '루트 안 다른 파일 만들기 poke.txt' { Write-Utf8 (Join-Path $proj 'poke.txt') 'x' } { (Has-Row 'poke.txt') -and (Has-Row 'via-target.txt') -and (Has-Row 'via-link.txt') }
        Check-Reflect 'junction' 'R-24' '루트 안 변경이 오면 정션 아래도 다시 읽음' 'poke.txt·via-target.txt·via-link.txt 행' $r
        $res.tree = (Get-Tree).line
    }
    # 정션을 먼저 지운다(대상은 남기고). 그다음 대상 폴더.
    if ((Test-Path -LiteralPath $jl) -and (Get-Item -LiteralPath $jl -Force).LinkType -eq 'Junction') { [System.IO.Directory]::Delete($jl) }
    if (Test-Path -LiteralPath $jt) { Remove-InRun $jt }

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

#Requires -Version 7
<#
.SYNOPSIS
  v0.2 Phase 4 (SPEC R-17~R-23·R-25~R-27, D-6~D-9·D-12·D-14·D-15·D-17·D-18) 증거: 프로젝트 패널 트리·키·인라인 입력·
  휴지통·영구 삭제·잘라내기/복사/붙여넣기·우클릭 메뉴·자동 표시·최소 탭, 시나리오 A-33.2·A-33.4.
  Phase 1~3 이월분(R-3 패널 Delete=휴지통·루트 Delete 무동작·Ctrl-N 결과, L-247 항목 툴팁, D-035 ① 폴더별 트리·탭) 포함.

.DESCRIPTION
  앱을 `--dev-keymap --dev-layout --dev-pick-folder <파일> --dev-no-shell` 로 사례마다 새로 띄운다
  (shell 사례만 `--dev-no-shell` 없이 실제 탐색기를 연다).
  쓰는 앱 출력: [dev] tree / tabs / open-file / reveal / edit / fs-op / file-clipboard / clipboard-write / task-dialog-open·result /
  delete-skipped / notification / context-menu-open·exec / panel-menu-target·exec / shell / focus-state / layout-box / tooltip-shown.

  안전 규칙(Phase 3 D-037·D-040 과 같다):
    - 시작 전에 workbench-gpui 가 이미 실행 중이면 사용자 파일을 바꾸기 전에 멈춘다. 띄운 프로세스(PID)만 닫는다.
    - 키·마우스를 보내기 직전마다 고정한 창(또는 확인창)이 전면인지, 마우스 아래 최상위 창이 그 창인지 확인한다.
    - %APPDATA%\workbench-gpui 의 state.json*·keymap.json 은 백업하고 끝에 파일마다 따로 되돌린다. 전후 SHA-256 을 남긴다.
    - 시험 폴더는 target\phase4-folders\run-<id> 에 이번 실행만 만들고(표지 .wg-p4-run), 끝에 표지가 같을 때만 지운다.
    - 휴지통: 원래 위치가 이번 실행 시험 폴더 아래인 항목만 `--dev-trash list|restore|purge <폴더>` 로 보고·되살리고·비운다.
      사용자 휴지통의 다른 항목은 건드리지 않는다.
    - OS 클립보드: 시작 때 글자를 저장하고 끝에 되돌린다(Copy Path 시험이 덮어쓴다).

  결과: specs/v0.2/verify/phase4/ 의 <사례>-stdout.txt, 스크린샷, disk-*.txt, trash-*.txt, results.json.

.EXAMPLE
  pwsh -NoProfile -File tools/verify-v02-phase4.ps1
  pwsh -NoProfile -Command "& ./tools/verify-v02-phase4.ps1 -Only layout,keys"
#>
[CmdletBinding()]
param(
    [string]$Exe = 'target\debug\workbench-gpui.exe',
    [string]$OutDir = 'specs\v0.2\verify\phase4',
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
$backupDir = Join-Path ([System.IO.Path]::GetTempPath()) ("wg-p4-backup-{0}" -f [guid]::NewGuid())
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
$testBase = [System.IO.Path]::GetFullPath('target\phase4-folders', (Get-Location).Path)
$testRoot = Join-Path $testBase "run-$runId"
$testMarker = Join-Path $testRoot '.wg-p4-run'
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


# ---------------------------------------------------------------- Phase 4 도우미
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

# 물리 px 좌표로 다루려고 이 스레드를 PER_MONITOR_AWARE_V2 로 둔다(Phase 2 와 같다).
$prevDpi = [WgP4.Native]::SetThreadDpiAwarenessContext([IntPtr]::new(-4))
$backupDone = $false
$clipSaved = $false
$clipBefore = $null
$clipEmpty = $false
# 리뷰 1회차 ⑤(D-043): OS 클립보드 형식을 Win32 로 본다. 텍스트 형식(CF_TEXT 1, CF_OEMTEXT 7, CF_UNICODETEXT 13, CF_LOCALE 16)만
# 있거나 비어 있을 때만 시험한다. 그 밖의 형식(이미지·파일 목록·HTML·RTF 등)이 있으면 그대로 되돌릴 수 없으므로 아무것도 바꾸기 전에 멈춘다.
if (-not ('WgP4Clip.Clip' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
namespace WgP4Clip {
    public static class Clip {
        [DllImport("user32.dll", SetLastError = true)] static extern bool OpenClipboard(IntPtr h);
        [DllImport("user32.dll")] static extern bool CloseClipboard();
        [DllImport("user32.dll")] static extern uint EnumClipboardFormats(uint f);
        [DllImport("user32.dll")] static extern bool EmptyClipboard();
        static bool Open() { for (int i = 0; i < 20; i++) { if (OpenClipboard(IntPtr.Zero)) return true; System.Threading.Thread.Sleep(50); } return false; }
        public static uint[] Formats() {
            if (!Open()) throw new InvalidOperationException("OpenClipboard failed");
            var list = new List<uint>();
            try { uint f = 0; while ((f = EnumClipboardFormats(f)) != 0) list.Add(f); }
            finally { CloseClipboard(); }
            return list.ToArray();
        }
        public static void Empty() {
            if (!Open()) throw new InvalidOperationException("OpenClipboard failed");
            try { EmptyClipboard(); } finally { CloseClipboard(); }
        }
    }
}
'@
}
$TextFormats = @(1, 7, 13, 16)
try {
    # 사용자 파일·시험 폴더를 바꾸기 전에 기존 앱 실행을 검사하고 즉시 중단한다(D-037 ④).
    $running = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) {
        $results.abortedBeforeChanges = $true
        throw "이미 실행 중인 $ProcessName 가 있다 (PID $($running.Id -join ', ')). 사용자 파일을 바꾸기 전에 중단한다"
    }
    # 클립보드 검사(사용자 파일·클립보드를 바꾸기 전, D-043 ⑤).
    $fmts = @([WgP4Clip.Clip]::Formats())
    $results.clipboardFormatsBefore = $fmts
    $other = @($fmts | Where-Object { $TextFormats -notcontains $_ })
    if ($other.Count -gt 0) {
        $results.abortedBeforeChanges = $true
        throw ("OS 클립보드에 텍스트가 아닌 형식이 있다(형식 번호 {0}). 그대로 되돌릴 수 없어 사용자 파일·클립보드를 바꾸기 전에 중단한다" -f ($other -join ','))
    }
    if ($fmts.Count -eq 0) { $clipEmpty = $true; $clipSaved = $true }
    else { $clipBefore = Get-Clipboard -Raw; $clipSaved = $true }
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    foreach ($uf in (Get-UserFiles)) { Copy-Item -LiteralPath $uf.FullName -Destination (Join-Path $backupDir $uf.Name) -Force }
    $backupDone = $true
    if (Test-Path -LiteralPath $keymapPath) { Remove-Item -LiteralPath $keymapPath -Force }
    Init-TestFolders
    $results.trashBefore = @(Invoke-Trash 'list')

    # ================================================================ D-043 ① 이름 변경 입력이 폴더 밖으로 나가지 않는다
    function Edit-Last { Last-Line '^\[dev\] edit ' }
    function Rename-To([string]$Row, [string]$Text) {
        Click-Row $Row
        Send-Keys 'f2'
        Send-Keys 'ctrl-a'
        Type-Text $Text
        Send-Keys 'enter'
        Start-Sleep -Milliseconds 500; Wait-Quiet
    }
    Reset-Proj
    Run-Case 'd043-rename' (New-StateJson @($proj) 0) {
        param($res, $p)
        Send-Keys 'ctrl-shift-e'
        $d0 = Save-Disk 'd043-rename-disk-before'
        Rename-To 'README.md' '..\outside.txt'
        Check 'd043-rename' 'D-043 ①·I-091·P-022' '이름 변경 "..\outside.txt" → 거부(입력칸 유지), 등록 루트 밖에 파일이 생기지 않음' 'README.md 그대로, run\outside.txt 없음, 입력칸 열림' ("README={0}, outside={1}, {2}" -f (Disk-Has 'README.md'), (Test-Path -LiteralPath (Folder 'outside.txt')), (Edit-Last)) ((Disk-Has 'README.md') -and -not (Test-Path -LiteralPath (Folder 'outside.txt')) -and (Edit-Last) -match 'active=true')
        Send-Keys 'escape'
        Rename-To 'notes.txt' (Folder 'abs.txt')
        Check 'd043-rename' 'D-043 ①' '이름 변경에 절대 경로 → 거부' 'notes.txt 그대로, run\abs.txt 없음' ("notes={0}, abs={1}" -f (Disk-Has 'notes.txt'), (Test-Path -LiteralPath (Folder 'abs.txt'))) ((Disk-Has 'notes.txt') -and -not (Test-Path -LiteralPath (Folder 'abs.txt')))
        Send-Keys 'escape'
        Click-Row 'ops'
        Rename-To 'f1.txt' 'sub\moved.txt'
        Check 'd043-rename' 'D-043 ①' '이름 변경에 구분자(하위 폴더로 이동) → 거부' 'ops\f1.txt 그대로, ops\sub\moved.txt 없음' ("f1={0}, moved={1}" -f (Disk-Has 'ops\f1.txt'), (Disk-Has 'ops\sub\moved.txt')) ((Disk-Has 'ops\f1.txt') -and -not (Disk-Has 'ops\sub\moved.txt'))
        Send-Keys 'escape'
        Rename-To 'f2.txt' 'f2.txt:ads'
        Check 'd043-rename' 'D-043 ①' '대체 데이터 스트림(:) 이름 → 거부' 'ops\f2.txt 그대로, 입력칸 열림' ("f2={0}, {1}" -f (Disk-Has 'ops\f2.txt'), (Edit-Last)) ((Disk-Has 'ops\f2.txt') -and (Edit-Last) -match 'active=true')
        Send-Keys 'escape'
        Rename-To 'f3.txt' 'con.txt'
        Check 'd043-rename' 'D-043 ①' '예약 장치 이름(con) → 거부, 입력칸 열림' 'f3.txt 그대로, active=true' ("f3={0}, {1}" -f (Disk-Has 'ops\f3.txt'), (Edit-Last)) ((Disk-Has 'ops\f3.txt') -and (Edit-Last) -match 'active=true')
        Send-Keys 'escape'
        $d1 = Save-Disk 'd043-rename-disk-after'
        $res.diskChanges = @(Compare-Object $d0 $d1 | ForEach-Object { "$($_.SideIndicator) $($_.InputObject.Split('|')[0])" })
    }

    # ================================================================ D-043 ③ Ctrl+클릭으로 뺀 항목은 작업 대상이 아니다
    Reset-Proj
    Run-Case 'd043-ctrlclick' (New-StateJson @($proj) 0) {
        param($res, $p)
        Send-Keys 'ctrl-shift-e'
        Click-Row 'ops'
        Click-Row 'f1.txt'
        Click-Row 'f2.txt' @('ctrl')
        Click-Row 'f2.txt' @('ctrl')
        $t = Get-Tree
        $f = Delete-Flow 'd043-ctrlclick' { Send-Keys 'delete' } 'esc'
        Check 'd043-ctrlclick' 'D-043 ③·I-090·I-562' '2개→1개 해제 뒤 Delete 대상은 남은 f1.txt' 'trash `f1.txt`' ("marked={0} selected={1} / {2}" -f ($t.marked -join ';'), $t.selected, $f.open) ($f.open -match [regex]::Escape('Do you want to trash `f1.txt`?'))
        Click-Row 'f1.txt' @('ctrl')
        $t = Get-Tree
        $bs = Count-Lines '^\[dev\] delete-skipped '
        $bo = Count-Lines '^\[dev\] task-dialog-open '
        Send-Keys 'delete'
        Start-Sleep -Milliseconds 800
        $dlg = [WgP4.Native]::FindDialog([uint32]$script:appPid)
        if ($dlg -ne [IntPtr]::Zero) { Send-DialogKeys $dlg 'escape'; [void](Wait-NoDialog 5) }
        Check 'd043-ctrlclick' 'D-043 ③' '1개→0개 해제 뒤 Delete → 대상 없음(확인창 없음)' 'selected=none, delete-skipped, 확인창 0' ("marked={0} selected={1}, skipped+{2}, dialog+{3}" -f ($t.marked -join ';'), $t.selected, ((Count-Lines '^\[dev\] delete-skipped ') - $bs), ((Count-Lines '^\[dev\] task-dialog-open ') - $bo)) ($t.selected -eq 'none' -and ((Count-Lines '^\[dev\] delete-skipped ') -eq $bs + 1) -and ((Count-Lines '^\[dev\] task-dialog-open ') -eq $bo))
    }

    # ================================================================ D-043 ④ 폴더 사이 잘라 붙이기 뒤 출발 폴더 탭 경로도 갱신
    Reset-Proj
    Run-Case 'd043-crossmove' (New-StateJson @($proj, $proj2) 0) {
        param($res, $p)
        Click-Row 'notes.txt'
        Start-Sleep -Milliseconds 600
        Double-Open 'd043-crossmove' 'notes.txt'
        Send-Keys 'ctrl-shift-e'
        Send-Keys 'ctrl-x'
        Click-Box 'folder-row-01' 'activate proj2'
        Wait-Quiet
        Send-Keys 'ctrl-shift-e'
        Send-Keys 'home'
        Send-Keys 'ctrl-v'
        Start-Sleep -Milliseconds 500
        $moved = Test-Path -LiteralPath (Join-Path $proj2 'notes.txt')
        Click-Box 'folder-row-00' 'activate proj'
        Wait-Quiet
        $tb = Get-Tabs
        $tab = @($tb.list | Where-Object { $_.title -eq 'notes.txt' })[0]
        Check 'd043-crossmove' 'D-043 ④·R-21·R-27·A-15' '폴더 A 의 탭으로 연 파일을 B 로 잘라 붙이면 A 의 탭 경로가 B 의 새 경로' (Join-Path $proj2 'notes.txt') ("moved={0}, tab={1}" -f $moved, $tab.path) ($moved -and $tab.path -eq (Join-Path $proj2 'notes.txt'))
        Check 'd043-crossmove' 'D-043 ④' '출발 폴더 트리에서 옮긴 파일이 사라진다' 'notes.txt 행 없음' (Tree-Labels) ((Row-Index 'notes.txt') -lt 0)
        [void](Save-Window 'd043-crossmove-back-to-proj')
    }

    # ================================================================ D-043 ⑥ comctl32 를 확인창마다 다시 올리지 않는다
    Reset-Proj
    Run-Case 'd043-dialog' (New-StateJson @($proj) 0) {
        param($res, $p)
        Send-Keys 'ctrl-shift-e'
        Click-Row 'notes.txt'
        $loads = @()
        for ($k = 0; $k -lt 3; $k++) {
            $f = Delete-Flow 'd043-dialog' { Send-Keys 'delete' } 'esc'
            $loads += $(if ($f.result -match 'comctl32_loads=(\d+)') { $Matches[1] } else { '<none>' })
        }
        Check 'd043-dialog' 'D-043 ⑥' '확인창 3번 → comctl32 올리기 1번(프로세스 수명 캐시)' '1,1,1' ($loads -join ',') (($loads -join ',') -eq '1,1,1')
    }

    # ================================================================ D-043 ② 정션으로 자기 안에 붙여넣기 → 거부(이번 실행 시험 폴더 안의 정션만)
    Reset-Proj
    $a = Join-Path $proj 'A'
    New-Item -ItemType Directory -Path $a | Out-Null
    Write-Utf8 (Join-Path $a 'file.txt') 'a'
    $link = Join-Path $proj 'link'
    if (-not $link.StartsWith($testRoot)) { throw '정션이 이번 실행 폴더 밖이다' }
    New-Item -ItemType Junction -Path $link -Target $a | Out-Null
    Run-Case 'd043-junction' (New-StateJson @($proj) 0) {
        param($res, $p)
        Send-Keys 'ctrl-shift-e'
        Send-Keys 'ctrl-left'
        Click-Row 'A' @('ctrl')
        Send-Keys 'ctrl-c'
        Click-Row 'link' @('ctrl')
        Assert-Foreground 'paste'
        [WgP4.Native]::Combo([uint16[]]@($VK.ctrl), [uint16]$VK.v)
        # 고치기 전에는 붙여넣기가 A\A\A… 로 끝없이 복사하며 UI 를 막는다. 3초 뒤 깊이를 재고, 막혔으면 이 앱(우리 PID)만 닫는다.
        Start-Sleep -Seconds 3
        $nested = @(Get-ChildItem -LiteralPath $a -Recurse -Directory -Force -ErrorAction SilentlyContinue).Count
        $op = Last-Line '^\[dev\] fs-op op=paste-copy '
        Check 'd043-junction' 'D-043 ②·R-21' '정션 link(→A) 에 A 를 붙여넣기 → 자기 안 복사로 거부, 폴더가 생기지 않음' 'paste-copy failed (into itself), A 아래 폴더 0' ("nested={0}, {1}" -f $nested, $op) ($nested -eq 0 -and $op -match 'result=failed' -and $op -match 'into itself')
        $res.nestedDirs = $nested
    }

    # ================================================================ D-043 ② 정션 순환: 경로 접기·Expand All 이 끝난다(이번 실행 시험 폴더 안의 정션만)
    Reset-Proj
    $loopDir = Join-Path $proj 'loopdir'
    New-Item -ItemType Directory -Path $loopDir | Out-Null
    if (-not $loopDir.StartsWith($testRoot)) { throw '정션이 이번 실행 폴더 밖이다' }
    # loopdir 의 유일한 자식 self 가 loopdir 자신을 가리킨다(접기 순환). up 은 proj 를 가리킨다(Expand All 순환).
    New-Item -ItemType Junction -Path (Join-Path $loopDir 'self') -Target $loopDir | Out-Null
    New-Item -ItemType Junction -Path (Join-Path $proj 'up') -Target $proj | Out-Null
    Run-Case 'd043-loop' (New-StateJson @($proj) 0) {
        param($res, $p)
        $t = Get-Tree
        $loopRow = @($t.rows | Where-Object { $_.label -like 'loopdir*' })[0]
        $segs = if ($loopRow) { @($loopRow.label -split ' \\ ').Count } else { -1 }
        Check 'd043-loop' 'D-043 ②·L-42' '자기를 가리키는 정션이 하나뿐인 폴더 → 접기가 순환하지 않는다' 'loopdir 줄 조각 2개 이하' ("조각={0}, 글자수={1}" -f $segs, $(if ($loopRow) { $loopRow.label.Length } else { 0 })) ($segs -ge 1 -and $segs -le 2)
        Send-Keys 'ctrl-shift-e'
        $bt = Count-Lines '^\[dev\] tree folder='
        Assert-Foreground 'ctrl-right'
        [WgP4.Native]::Combo([uint16[]]@($VK.ctrl), [uint16]$VK.right)
        $l = Wait-NewLine '^\[dev\] tree folder=' $bt 10
        $alive = -not $p.HasExited
        $ex = if ($l) { @((Get-Tree).expanded).Count } else { -1 }
        Check 'd043-loop' 'D-043 ②·I-032' 'proj 를 가리키는 정션(up)이 있어도 Ctrl+Right 전체 펼치기가 끝난다' '10초 안에 트리 갱신, 앱 살아 있음, 펼침 수 유한' ("갱신={0}, alive={1}, expanded={2}" -f [bool]$l, $alive, $ex) ([bool]$l -and $alive -and $ex -gt 0 -and $ex -lt 100)
        $res.expandedCount = $ex
    }

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
    # 2) OS 클립보드 되돌리기.
    if ($clipSaved) {
        try {
            # 시작 때 비어 있었으면 비우고, 텍스트였으면 같은 글자로 되돌린다. 되돌린 뒤 형식·글자를 다시 본다(D-043 ⑤).
            if ($clipEmpty) { [WgP4Clip.Clip]::Empty() } else { Set-Clipboard -Value $clipBefore }
            $after = @([WgP4Clip.Clip]::Formats())
            $results.clipboardFormatsAfter = $after
            $okFormats = @($after | Where-Object { $TextFormats -notcontains $_ }).Count -eq 0
            $okText = if ($clipEmpty) { $after.Count -eq 0 } else { (Get-Clipboard -Raw) -eq $clipBefore }
            $results.clipboardRestored = ($okFormats -and $okText)
            if (-not $results.clipboardRestored) { $results.failures += 'OS 클립보드가 시작 때와 다르다' }
        }
        catch { $results.errors += "클립보드 되돌리기: $($_.Exception.Message)" }
    }
    # 3) 휴지통: 이번 실행 시험 폴더에서 버린 항목만 비운다(사용자 다른 항목은 건드리지 않는다).
    if ($script:testRootCreated) {
        try {
            $results.trashPurge = @(Invoke-Trash 'purge' 'trash-final-purge')
            $results.trashAfter = @(Invoke-Trash 'list')
        }
        catch { $results.errors += "휴지통 정리: $($_.Exception.Message)" }
    }
    # 4) 백업 지우기(복원 확인 때만), 이번 실행 시험 폴더만 지우기(D-040).
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
"cases: $(@($results.cases.get_Keys()) -join ', ')"
"checks: $($results.checks.Count), failed: $(@($results.checks | Where-Object { -not $_.ok }).Count)"
"failures: $($results.failures.Count)"
"user files restored: $($results.userFiles.restored)"
$results.failures | ForEach-Object { "  - $_" }
if ($results.failures.Count -gt 0) { exit 1 }

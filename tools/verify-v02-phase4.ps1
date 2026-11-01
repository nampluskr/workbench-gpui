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

    # ================================================================ layout: R-17 (L-36~L-42, A-32.14~A-32.16)
    Run-Case 'layout' (New-StateJson @($proj) 0) {
        param($res, $p)
        $t = Get-Tree
        Check 'layout' 'L-41' '루트를 맨 위 항목으로(펼친 채)' 'proj|0|open 맨 앞' ($t.rows[0] | ConvertTo-Json -Compress) ($t.rows[0].label -eq 'proj' -and $t.rows[0].depth -eq 0 -and $t.rows[0].kind -eq 'open')
        Check 'layout' 'L-50' '정렬: 폴더 먼저, 대소문자 무시 자연 정렬' 'proj / deep \ l1 \ l2 / docs \ guides / many / ops / src / notes.txt / README.md' (Tree-Labels) ((Tree-Labels) -eq 'proj / deep \ l1 \ l2 / docs \ guides / many / ops / src / notes.txt / README.md')
        Check 'layout' 'L-42' '자식이 폴더 하나뿐이면 한 줄로(연쇄)' 'docs \ guides, deep \ l1 \ l2' ((Get-Tree).rows[1..2].label -join ', ') ((Row-Index 'docs \ guides') -gt 0 -and (Row-Index 'deep \ l1 \ l2') -gt 0)
        Click-Row 'src'
        Click-Row 'docs \ guides'
        Click-Row 'util'
        Park-Mouse
        Start-Sleep -Milliseconds 600
        Check 'layout' 'R-18' '폴더 누르기 = 펼침' 'src·docs\guides·src\util 펼침' ((Get-Tree).expanded -join ';') (((Get-Tree).expanded -contains 'src') -and ((Get-Tree).expanded -contains 'docs\guides') -and ((Get-Tree).expanded -contains 'src\util'))
        $rows = (Get-Tree).rows
        $res.rows = @($rows | ForEach-Object { "$($_.label)|$($_.depth)|$($_.kind)" })
        $boxes = @()
        for ($i = 0; $i -lt $rows.Count; $i++) {
            $nn = '{0:d2}' -f $i
            $rb = Get-Box "tree-row-$nn"
            $ib = if ($i -eq 0) { Get-Box 'project-root-icon' } else { Get-Box "tree-icon-$nn" }
            if (-not $rb -or -not $ib) { continue }
            $d = $rows[$i].depth
            $boxes += [ordered]@{ row = $i; label = $rows[$i].label; depth = $d; rowY = $rb.y; rowH = $rb.h; iconDx = [math]::Round($ib.x - $rb.x, 2); iconW = $ib.w; iconH = $ib.h }
            Check 'layout' 'L-36·A-32.14' "행 $nn 높이 26" '26±1' $rb.h (Near $rb.h 26)
            Check 'layout' 'L-37·A-32.15' "행 $nn 들여쓰기(아이콘 x = 1 + 6 + 깊이×20)" (1 + 6 + 20 * $d) ([math]::Round($ib.x - $rb.x, 2)) (Near ($ib.x - $rb.x) (1 + 6 + 20 * $d))
            Check 'layout' 'L-40·A-32.16' "행 $nn 아이콘 16×16" '16×16±1' ("{0}×{1}" -f $ib.w, $ib.h) ((Near $ib.w 16) -and (Near $ib.h 16))
            if ($i -gt 0) {
                $prev = Get-Box ('tree-row-{0:d2}' -f ($i - 1))
                Check 'layout' 'L-46' "행 $nn 이 앞 행 바로 아래(같은 높이 목록)" '26±1' ($rb.y - $prev.y) (Near ($rb.y - $prev.y) 26)
            }
            foreach ($g in 0..($d - 1)) {
                if ($d -lt 1) { break }
                $gb = Get-Box "tree-guide-$nn-$g"
                if (-not $gb) { Check 'layout' 'L-38' "행 $nn 안내선 단계 $g" 'present' 'absent' $false; continue }
                Check 'layout' 'L-38·A-32.15' "행 $nn 안내선 단계 $g x = 단계×20+15, 폭 1" ("{0}, 1" -f (20 * $g + 15)) ("{0}, {1}" -f [math]::Round($gb.x - $rb.x, 2), $gb.w) ((Near ($gb.x - $rb.x) (20 * $g + 15)) -and (Near $gb.w 1 0.6))
            }
        }
        $res.boxes = $boxes
        # 안내선 위아래 4 여백: 루트 안내선 첫 행(1행) 위 4, 마지막 행 아래 4.
        $g1 = Get-Box 'tree-guide-01-0'; $r1 = Get-Box 'tree-row-01'
        $last = '{0:d2}' -f ($rows.Count - 1)
        $gl = Get-Box "tree-guide-$last-0"; $rl = Get-Box "tree-row-$last"
        Check 'layout' 'L-38' '안내선 구간 첫 행 위 4·끝 행 아래 4' '4 / 4' ("{0} / {1}" -f [math]::Round($g1.y - $r1.y, 2), [math]::Round(($rl.y + $rl.h) - ($gl.y + $gl.h), 2)) ((Near ($g1.y - $r1.y) 4) -and (Near (($rl.y + $rl.h) - ($gl.y + $gl.h)) 4))
        [void](Save-Window 'layout-tree')
        $res.screenshot = 'layout-tree.png'
    }

    # ================================================================ keys: R-18 (I-030~I-033·I-043·I-087~I-090), R-27 일부
    Run-Case 'keys' (New-StateJson @($proj) 0) {
        param($res, $p)
        Send-Keys 'ctrl-shift-e'
        Check 'keys' 'I-023' 'Ctrl+Shift+E → 프로젝트 패널 포커스' 'project_panel' (Focus-Now) ((Focus-Now) -eq 'project_panel')
        Send-Keys 'down'
        Check 'keys' 'I-030' '선택 없음 + Down → 첫 항목(루트)' '.' (Get-Tree).selected ((Get-Tree).selected -eq '.')
        Send-Keys 'down'
        Check 'keys' 'I-030' 'Down → 다음 항목(접힌 경로 줄)' 'deep\l1\l2' (Get-Tree).selected ((Get-Tree).selected -eq 'deep\l1\l2')
        Send-Keys 'end'
        Check 'keys' 'I-030' 'End → 끝 항목' 'README.md' (Get-Tree).selected ((Get-Tree).selected -eq 'README.md')
        Send-Keys 'home'
        Check 'keys' 'I-030' 'Home → 처음 항목' '.' (Get-Tree).selected ((Get-Tree).selected -eq '.')
        Send-Keys 'up'
        Check 'keys' 'I-030' '처음에서 Up → 그대로(판단: 돌지 않는다)' '.' (Get-Tree).selected ((Get-Tree).selected -eq '.')
        Check 'keys' 'I-088' 'Up/Down/Home/End 는 파일을 열지 않는다' 'tabs 0, focus project_panel' ("tabs {0}, focus {1}" -f (Get-Tabs).count, (Focus-Now)) ((Get-Tabs).count -eq 0 -and (Focus-Now) -eq 'project_panel')
        Send-Keys 'down down'
        Send-Keys 'right'
        Check 'keys' 'I-089·I-031' 'Right: 닫힌 폴더 펼침' 'docs\guides 펼침' ((Get-Tree).expanded -join ';') ((Get-Tree).expanded -contains 'docs\guides')
        Send-Keys 'right'
        Check 'keys' 'I-089' 'Right: 이미 펼쳤으면 다음 항목' 'docs\guides\a.md' (Get-Tree).selected ((Get-Tree).selected -eq 'docs\guides\a.md')
        Send-Keys 'left'
        Check 'keys' 'I-089' 'Left: 파일이면 부모로' 'docs\guides' (Get-Tree).selected ((Get-Tree).selected -eq 'docs\guides')
        Send-Keys 'left'
        Check 'keys' 'I-089·I-031' 'Left: 펼친 폴더 접기' 'docs\guides 접힘' ((Get-Tree).expanded -join ';') (-not ((Get-Tree).expanded -contains 'docs\guides'))
        Send-Keys 'ctrl-right'
        $ex = (Get-Tree).expanded
        Check 'keys' 'I-032' 'Ctrl+Right 전체 펼치기' 'src\util·ops\sub·deep\l1\l2 포함' ($ex -join ';') (($ex -contains 'src\util') -and ($ex -contains 'ops\sub') -and ($ex -contains 'deep\l1\l2'))
        Send-Keys 'ctrl-left'
        Check 'keys' 'I-032' 'Ctrl+Left 전체 접기(루트는 펼친 채, 판단)' '.' ((Get-Tree).expanded -join ';') (((Get-Tree).expanded -join ';') -eq '.')
        Send-Keys 'end'
        Send-Keys 'space'
        $tb = Get-Tabs
        Check 'keys' 'I-033·R-27' 'Space: 임시 탭으로 열고 트리에 포커스' 'README.md|preview, focus project_panel' ("{0}, focus {1}" -f (Tabs-Text), (Focus-Now)) ($tb.count -eq 1 -and $tb.list[0].title -eq 'README.md' -and $tb.list[0].kind -eq 'preview' -and (Focus-Now) -eq 'project_panel')
        Send-Keys 'shift-up shift-up'
        Check 'keys' 'I-043' 'Shift+Up 두 번 → 범위 확장 3개' 'src;notes.txt;README.md (순서 무관)' ((Get-Tree).marked -join ';') ((Get-Tree).marked.Count -eq 3 -and ((Get-Tree).marked -contains 'src') -and ((Get-Tree).marked -contains 'README.md'))
        Click-Row 'ops'
        Check 'keys' 'I-089' '폴더 누르기 → 펼침' 'ops 펼침' ((Get-Tree).expanded -join ';') ((Get-Tree).expanded -contains 'ops')
        Click-Row 'ops'
        Check 'keys' 'I-089' '다시 누르기 → 접힘' 'ops 접힘' ((Get-Tree).expanded -join ';') (-not ((Get-Tree).expanded -contains 'ops'))
        Click-Row 'src' @('alt')
        $ex = (Get-Tree).expanded
        Check 'keys' 'I-089' 'Alt+클릭 → 하위 전체 펼침' 'src, src\util' ($ex -join ';') (($ex -contains 'src') -and ($ex -contains 'src\util'))
        Click-Row 'src' @('alt')
        $ex = (Get-Tree).expanded
        Check 'keys' 'I-089' 'Alt+클릭 다시 → 하위 전체 접힘' 'src·src\util 없음' ($ex -join ';') (-not ($ex -contains 'src') -and -not ($ex -contains 'src\util'))
        Click-Row 'notes.txt'
        Click-Row 'README.md' @('ctrl')
        Check 'keys' 'I-090' 'Ctrl+클릭 → 개별 선택 추가' 'notes.txt;README.md' ((Get-Tree).marked -join ';') (((Get-Tree).marked -join ';') -eq 'notes.txt;README.md')
        [void](Save-Window 'keys-ctrl-click')
        Click-Row 'README.md' @('ctrl')
        Check 'keys' 'I-090' 'Ctrl+클릭 다시 → 빼기' 'notes.txt' ((Get-Tree).marked -join ';') (((Get-Tree).marked -join ';') -eq 'notes.txt')
        # 기준점: Ctrl+클릭(폴더를 펼치지 않는다)으로 many 를 고른다.
        Click-Row 'many' @('ctrl')
        Click-Row 'notes.txt' @('shift')
        Check 'keys' 'I-090' 'Shift+클릭 → 보이는 항목 범위' 'many;ops;src;notes.txt' ((Get-Tree).marked -join ';') (((Get-Tree).marked -join ';') -eq 'many;ops;src;notes.txt')
        [void](Save-Window 'keys-shift-click')
        $tb0 = Get-Tabs
        Click-Row 'notes.txt'
        $tb = Get-Tabs
        Check 'keys' 'I-087·I-062' '파일 한 번 클릭 → 임시 탭(기존 임시 자리 교체), 편집기 포커스 없음' 'notes.txt|preview 하나, focus project_panel' ("{0}, focus {1}" -f (Tabs-Text), (Focus-Now)) ($tb.count -eq 1 -and $tb.list[0].title -eq 'notes.txt' -and $tb.list[0].kind -eq 'preview' -and (Focus-Now) -eq 'project_panel')
        # 디버그 빌드는 첫 누르기에서 편집기를 만드느라 500ms 넘게 멈춰, 두 누르기가 따로 세어진다(gpui 는 처리 시각으로 센다).
        # 그래서 먼저 한 번 눌러 임시 탭으로 열어 둔 뒤 더블클릭한다(두 번째 누르기가 click_count 2).
        Click-Row 'README.md'
        Start-Sleep -Milliseconds 800
        Double-Open 'x' 'README.md'
        $tb = Get-Tabs
        Check 'keys' 'I-087' '더블클릭 → 일반 탭 + 편집기 포커스' 'README.md|normal 활성, focus editor' ("{0}, focus {1}" -f (Tabs-Text), (Focus-Now)) (($tb.list | Where-Object { $_.title -eq 'README.md' }).kind -eq 'normal' -and $tb.list[[int]$tb.active].title -eq 'README.md' -and (Focus-Now) -eq 'editor')
        Click-Row 'notes.txt' -How 'middle'
        $tb = Get-Tabs
        Check 'keys' 'I-087·I-063' '가운데 클릭 → 임시였던 탭이 일반 탭 + 편집기 포커스' 'notes.txt|normal, README.md|normal, focus editor' ("{0}, focus {1}" -f (Tabs-Text), (Focus-Now)) ($tb.count -eq 2 -and @($tb.list | Where-Object { $_.kind -eq 'normal' }).Count -eq 2 -and (Focus-Now) -eq 'editor')
        [void](Save-Window 'keys-tabs')
        $res.tabs = (Get-Tabs).line
    }

    # ================================================================ inline: R-19 (I-034~I-036, I-091, I-092, I-097, P-019~P-022), R-3 Ctrl-N 이월
    Run-Case 'inline' (New-StateJson @($proj) 0) {
        param($res, $p)
        function Edit-Last { Last-Line '^\[dev\] edit ' }
        function Panel-Focus { if ((Focus-Now) -ne 'project_panel') { Send-Keys 'ctrl-shift-e' }; if ((Focus-Now) -ne 'project_panel') { Send-Keys 'ctrl-shift-e' } }
        Send-Keys 'ctrl-shift-e'
        Send-Keys 'home'
        $d0 = Save-Disk 'inline-disk-before'
        # ① Ctrl+N 새 파일
        Send-Keys 'ctrl-n'
        $e = Edit-Last
        Check 'inline' 'I-036·P-019' 'Ctrl+N → 새 파일 입력칸(빈 값), 루트에 가상 행' 'kind=new-file target=. value=""' $e ($e -match 'what=start active=true kind=new-file target=\. value=""' -and (Tree-Labels) -match '<new file>')
        Check 'inline' 'P-022' '입력칸 포커스 → editing 컨텍스트' 'panel_input' (Focus-Now) ((Focus-Now) -eq 'panel_input')
        [void](Save-Window 'inline-new-file-start')
        Type-Text 'new.txt'
        Send-Keys 'enter'
        Start-Sleep -Milliseconds 500
        $tb = Get-Tabs
        Check 'inline' 'R-3·I-036·P-022' 'Enter 확정 → 디스크에 new.txt' 'exists' (Disk-Has 'new.txt') (Disk-Has 'new.txt')
        Check 'inline' 'I-097·R-27' '만든 파일을 연다(일반 탭, 편집기 포커스)' 'new.txt|normal, editor' ("{0}, {1}" -f (Tabs-Text), (Focus-Now)) (($tb.list | Where-Object { $_.title -eq 'new.txt' }).kind -eq 'normal' -and (Focus-Now) -eq 'editor')
        # ② Alt+N 새 폴더(선택이 파일이면 그 부모)
        Panel-Focus
        Send-Keys 'alt-n'
        Check 'inline' 'I-036·P-019' 'Alt+N → 새 폴더 입력칸(선택 파일의 부모 = 루트)' 'kind=new-dir target=.' (Edit-Last) ((Edit-Last) -match 'kind=new-dir target=\. ')
        Type-Text 'newdir'
        Send-Keys 'enter'
        Start-Sleep -Milliseconds 400
        Check 'inline' 'I-036' '새 폴더 생성' 'dir' $(if (Test-Path -LiteralPath (Join-Path $proj 'newdir') -PathType Container) { 'dir' } else { 'none' }) (Test-Path -LiteralPath (Join-Path $proj 'newdir') -PathType Container)
        Check 'inline' 'P-022' '폴더를 만든 뒤 패널 포커스' 'project_panel' (Focus-Now) ((Focus-Now) -eq 'project_panel')
        # ③ F2 파일 이름 변경: 확장자를 뺀 이름만 고른다
        Click-Row 'notes.txt'
        Send-Keys 'f2'
        $e = Edit-Last
        Check 'inline' 'I-034·I-091·P-019' 'F2 → 이름 변경, 파일은 확장자 뺀 이름만 선택' 'value="notes.txt" selected_text="notes"' $e ($e -match 'kind=rename target=notes\.txt value="notes\.txt" selected=0\.\.5 selected_text="notes"')
        [void](Save-Window 'inline-rename-file-selection')
        Type-Text 'renamed'
        Send-Keys 'enter'
        Start-Sleep -Milliseconds 400
        Check 'inline' 'I-091' '이름 변경 확정 → renamed.txt, notes.txt 없음' 'renamed.txt' ("renamed={0} notes={1}" -f (Disk-Has 'renamed.txt'), (Disk-Has 'notes.txt')) ((Disk-Has 'renamed.txt') -and -not (Disk-Has 'notes.txt'))
        Check 'inline' 'R-27(판단)' '열린 탭 경로도 새 이름으로' 'renamed.txt 탭' (Tabs-Text) ((Tabs-Text) -match 'renamed\.txt')
        # ④ Enter 폴더 이름 변경: 이름 전체 선택, Escape 취소
        Click-Row 'many' @('ctrl')
        Send-Keys 'enter'
        $e = Edit-Last
        Check 'inline' 'I-034·I-091' 'Enter → 이름 변경(Windows), 폴더는 이름 전체 선택' 'value="many" selected_text="many"' $e ($e -match 'kind=rename target=many value="many" selected=0\.\.4 selected_text="many"')
        [void](Save-Window 'inline-rename-folder-selection')
        Type-Text 'zzz'
        Send-Keys 'escape'
        Check 'inline' 'I-092·P-022' 'Escape → 입력 버림, 패널 포커스, 디스크 그대로' 'cancelled, project_panel, many 있음' ("{0}, {1}, many={2}" -f (Edit-Last), (Focus-Now), (Disk-Has 'many')) ((Edit-Last) -match 'what=cancelled' -and (Focus-Now) -eq 'project_panel' -and (Disk-Has 'many') -and -not (Disk-Has 'zzz'))
        # ⑤ 루트는 이름을 바꿀 수 없다
        Send-Keys 'home'
        $bs = Count-Lines '^\[dev\] rename-skipped reason=root'
        Send-Keys 'f2'
        Check 'inline' 'I-091·A-14' '루트 F2 → 아무 일 없음' 'rename-skipped reason=root, 입력칸 없음' ("{0} / {1}" -f (Count-Lines '^\[dev\] rename-skipped reason=root'), (Focus-Now)) ((Count-Lines '^\[dev\] rename-skipped reason=root') -eq $bs + 1 -and (Focus-Now) -eq 'project_panel')
        # ⑥ 포커스 잃음 → 확정
        Send-Keys 'ctrl-n'
        Type-Text 'blur.txt'
        Park-Mouse
        $c = Need-Box 'active-item'
        Click-At ($c.x + $c.w / 2) ($c.y + $c.h / 2) 'center (blur)'
        Start-Sleep -Milliseconds 600
        Check 'inline' 'I-092·P-022' '포커스 잃음 → 유효하면 만든다' 'blur.txt 있음' (Disk-Has 'blur.txt') (Disk-Has 'blur.txt')
        # ⑦ 같은 이름 → 오류 배너, Enter 거부, 포커스 잃음이면 취소
        Panel-Focus
        Send-Keys 'home'
        Send-Keys 'ctrl-n'
        Type-Text 'README.md'
        $e = Edit-Last
        Check 'inline' 'P-021' '같은 이름 → 오류 문구' "File or directory 'README.md' already exists at location. Please choose a different name." $e ($e -match [regex]::Escape('validation=error text="File or directory ''README.md'' already exists at location. Please choose a different name."'))
        [void](Save-Window 'inline-error-banner')
        Send-Keys 'enter'
        Check 'inline' 'P-022 ②' 'Enter → 거부, 입력칸 열린 채' 'what=rejected active=true' (Edit-Last) ((Edit-Last) -match 'what=rejected active=true')
        $c = Need-Box 'active-item'
        Click-At ($c.x + $c.w / 2) ($c.y + $c.h / 2) 'center (blur conflict)'
        Start-Sleep -Milliseconds 600
        Check 'inline' 'P-022' '충돌 상태에서 포커스 잃음 → 편집 취소' 'what=cancelled' (Edit-Last) ((Edit-Last) -match 'what=cancelled')
        # ⑧ 앞뒤 공백 → 경고
        Panel-Focus
        Send-Keys 'home'
        Send-Keys 'ctrl-n'
        Type-Text ' lead.txt'
        Check 'inline' 'P-021' '앞뒤 공백 → 경고 문구' 'File or directory name contains leading or trailing whitespace.' (Edit-Last) ((Edit-Last) -match 'validation=warning text="File or directory name contains leading or trailing whitespace\."')
        [void](Save-Window 'inline-warning-banner')
        Send-Keys 'escape'
        # ⑨ 끝 마침표 지움, ⑩ \ 로 끝나면 폴더, ⑪ 중간 폴더, ⑫ 빈 이름 거부
        Send-Keys 'home'
        Send-Keys 'ctrl-n'; Type-Text 'dots.txt..'; Send-Keys 'enter'; Start-Sleep -Milliseconds 400
        Check 'inline' 'P-022' 'Windows: 끝 마침표를 모두 지운다' 'dots.txt (dots.txt.. 없음)' (@(Disk-Names | Where-Object { $_ -like 'dots*' }) -join ',') ((Disk-Names) -ccontains 'dots.txt' -and -not ((Disk-Names) -ccontains 'dots.txt..'))
        Panel-Focus; Send-Keys 'home'
        Send-Keys 'ctrl-n'; Type-Text 'slashdir\'; Send-Keys 'enter'; Start-Sleep -Milliseconds 400
        Check 'inline' 'P-022' '새 항목이 \ 로 끝나면 폴더 생성' 'dir' (Test-Path -LiteralPath (Join-Path $proj 'slashdir') -PathType Container) (Test-Path -LiteralPath (Join-Path $proj 'slashdir') -PathType Container)
        Panel-Focus; Send-Keys 'home'
        Send-Keys 'ctrl-n'; Type-Text 'nest/a/b.md'; Send-Keys 'enter'; Start-Sleep -Milliseconds 500
        Check 'inline' 'P-022' 'foo/bar/baz 는 중간 폴더도 만든다' 'nest\a\b.md' (Disk-Has 'nest\a\b.md') (Disk-Has 'nest\a\b.md')
        Panel-Focus; Send-Keys 'home'
        Send-Keys 'ctrl-n'; Send-Keys 'enter'
        Check 'inline' 'P-022 ①' '빈 이름 Enter → 아무 일 없이 열린 채' 'what=rejected active=true' (Edit-Last) ((Edit-Last) -match 'what=rejected active=true')
        Send-Keys 'escape'
        # ⑬ 자기 자신과 같은 이름 → 편집만 끝내고 패널 포커스
        Click-Row 'README.md'
        Send-Keys 'f2'; Send-Keys 'enter'
        Check 'inline' 'P-022' '이름 변경에서 같은 이름 → 편집 끝, 패널 포커스' 'committed, project_panel' ("{0}, {1}" -f (Edit-Last), (Focus-Now)) ((Edit-Last) -match 'what=committed active=false' -and (Focus-Now) -eq 'project_panel')
        $d1 = Save-Disk 'inline-disk-after'
        $res.diskAdded = @(Compare-Object $d0 $d1 | Where-Object SideIndicator -eq '=>' | ForEach-Object { $_.InputObject.Split('|')[0] })
        $res.diskRemoved = @(Compare-Object $d0 $d1 | Where-Object SideIndicator -eq '<=' | ForEach-Object { $_.InputObject.Split('|')[0] })
        [void](Save-Window 'inline-end')
    }

    # ================================================================ trash: R-20 (A-14.1~A-14.11, P-015, D-12, D-14), R-3 이월(패널 Delete=휴지통, 루트 Delete 무동작)
    Reset-Proj
    Run-Case 'trash' (New-StateJson @($proj) 0) {
        param($res, $p)
        function Open-Of($flow) { if ($flow.open) { $flow.open } else { '<none>' } }
        Send-Keys 'ctrl-shift-e'
        Click-Row 'ops'
        # 루트 Delete → 아무 일 없음
        Send-Keys 'home'
        $bs = Count-Lines '^\[dev\] delete-skipped '
        Send-Keys 'delete'
        Start-Sleep -Milliseconds 800
        Check 'trash' 'A-14·R-3' '루트가 선택된 채 Delete → 아무 일도 하지 않음(확인창 없음)' 'delete-skipped, 확인창 없음' ("skipped+{0}, dialog={1}" -f ((Count-Lines '^\[dev\] delete-skipped ') - $bs), ([WgP4.Native]::FindDialog([uint32]$script:appPid) -ne [IntPtr]::Zero)) (((Count-Lines '^\[dev\] delete-skipped ') -eq $bs + 1) -and [WgP4.Native]::FindDialog([uint32]$script:appPid) -eq [IntPtr]::Zero)
        $disk0 = Save-Disk 'trash-disk-0-before'
        # ① 휴지통 하나: Esc 취소
        Click-Row 'f1.txt'
        $f = Delete-Flow 'trash' { Send-Keys 'delete' } 'esc' 'trash-dialog-single'
        Check 'trash' 'A-14.7·P-015·I-039' 'Delete → 휴지통 확인창 문구·버튼(기본 Cancel)' 'instruction="Do you want to trash `f1.txt`?" content=None buttons=Trash|Cancel default=Cancel' (Open-Of $f) ((Open-Of $f) -match [regex]::Escape('instruction="Do you want to trash `f1.txt`?" content=None buttons=Trash|Cancel default=Cancel'))
        Check 'trash' 'D-12' 'Esc → 취소, 디스크 그대로' 'button=Cancel, f1 있음' ("{0}, f1={1}" -f $f.result, (Disk-Has 'ops\f1.txt')) ($f.result -match 'button=Cancel' -and (Disk-Has 'ops\f1.txt'))
        # ② 기본 버튼 = 취소(Enter)
        $f = Delete-Flow 'trash' { Send-Keys 'delete' } 'enter'
        Check 'trash' 'D-12' '확인창에서 바로 Enter → 기본 버튼 Cancel' 'button=Cancel, f1 있음' ("{0}, f1={1}" -f $f.result, (Disk-Has 'ops\f1.txt')) ($f.result -match 'button=Cancel' -and (Disk-Has 'ops\f1.txt'))
        # ③ 확인 → 휴지통
        $f = Delete-Flow 'trash' { Send-Keys 'delete' } 'confirm'
        $tn = Trash-Names
        [void](Invoke-Trash 'list' 'trash-list-after-trash')
        $envr = Get-RecycleEnv
        $res.recycleEnv = $envr
        $fsop = Last-Line '^\[dev\] fs-op op=trash '
        Check 'trash' 'A-14.3·D-6' 'Trash 확인 → trash 크레이트로 보내고 디스크에서 사라짐' 'button=Confirm, fs-op op=trash result=ok, f1 없음' ("{0}, {1}, f1={2}" -f $f.result, $fsop, (Disk-Has 'ops\f1.txt')) ($f.result -match 'button=Confirm' -and $fsop -match 'op=trash result=ok' -and -not (Disk-Has 'ops\f1.txt'))
        if ($envr.available) {
            Check 'trash' 'A-14.3' '휴지통에 f1.txt 가 있음' 'f1.txt' ($tn -join ',') ($tn -contains 'f1.txt')
        } else {
            Undetermined 'trash' 'A-14.3·A-14.5' '휴지통 안 항목 확인·복원' ("시험 폴더 볼륨 {0}: DriveType={1}(2=이동식, 휴지통 없음), 휴지통 설정 NukeOnDelete={2}(1=바로 지움). 사용자 시스템 설정은 바꾸지 않았다. 휴지통 목록={3}" -f $envr.drive, $envr.driveType, $envr.nukeOnDelete, ($tn -join ','))
        }
        $disk1 = Save-Disk 'trash-disk-1-after-trash'
        $res.diskTrash = @(Compare-Object $disk0 $disk1 | ForEach-Object { "$($_.SideIndicator) $($_.InputObject.Split('|')[0])" })
        # ④ Backspace 도 휴지통
        Click-Row 'f3.txt'
        $f = Delete-Flow 'trash' { Send-Keys 'backspace' } 'esc'
        Check 'trash' 'I-039' 'Backspace → 휴지통 확인창' 'trash `f3.txt`' (Open-Of $f) ((Open-Of $f) -match [regex]::Escape('Do you want to trash `f3.txt`?'))
        # ⑤ 영구 삭제: Shift+Delete, Ctrl+Delete, Ctrl+Backspace
        Click-Row 'f2.txt'
        $f = Delete-Flow 'trash' { Send-Keys 'ctrl-delete' } 'esc'
        Check 'trash' 'I-040' 'Ctrl+Delete → 영구 삭제 확인창' 'Delete|Cancel' (Open-Of $f) ((Open-Of $f) -match 'buttons=Delete\|Cancel')
        $f = Delete-Flow 'trash' { Send-Keys 'ctrl-backspace' } 'esc'
        Check 'trash' 'I-040' 'Ctrl+Backspace → 영구 삭제 확인창' 'Delete|Cancel' (Open-Of $f) ((Open-Of $f) -match 'buttons=Delete\|Cancel')
        $f = Delete-Flow 'trash' { Send-Keys 'shift-delete' } 'confirm' 'delete-dialog-single'
        Check 'trash' 'A-14.8·P-015' '영구 삭제 문구 + 보조 문구' 'instruction="Are you sure you want to permanently delete `f2.txt`?" content=Some("This cannot be undone.") buttons=Delete|Cancel' (Open-Of $f) ((Open-Of $f) -match [regex]::Escape('instruction="Are you sure you want to permanently delete `f2.txt`?" content=Some("This cannot be undone.") buttons=Delete|Cancel default=Cancel'))
        $tn = Trash-Names
        Check 'trash' 'A-14.3' 'Delete 확인 → 지운다(휴지통에 없음)' 'f2 없음, 휴지통에 f2 없음' ("{0}, f2={1}, trash={2}" -f $f.result, (Disk-Has 'ops\f2.txt'), ($tn -join ',')) ($f.result -match 'button=Confirm' -and -not (Disk-Has 'ops\f2.txt') -and -not ($tn -contains 'f2.txt'))
        $disk2 = Save-Disk 'trash-disk-2-after-delete'
        $res.diskDelete = @(Compare-Object $disk1 $disk2 | ForEach-Object { "$($_.SideIndicator) $($_.InputObject.Split('|')[0])" })
        # ⑥ 여러 항목
        Click-Row 'f3.txt'
        Click-Row 'locked.txt' @('ctrl')
        Click-Row 'sub' @('ctrl')
        $f = Delete-Flow 'trash' { Send-Keys 'delete' } 'esc' 'trash-dialog-multi'
        Check 'trash' 'A-14.9·I-562' '여러 항목 → following N files + 목록' 'the following 3 files?\nf3.txt\nlocked.txt\nsub' (Open-Of $f) ((Open-Of $f) -match [regex]::Escape('instruction="Do you want to trash the following 3 files?\nf3.txt\nlocked.txt\nsub"'))
        # ⑦ 넘치는 목록(12개 → 10개 + ".. 2 files not shown")
        Click-Row 'many'
        Click-Row 'm00.txt'
        Click-Row 'm11.txt' @('shift')
        $f = Delete-Flow 'trash' { Send-Keys 'shift-delete' } 'esc' 'delete-dialog-overflow'
        Check 'trash' 'A-14.9·P-015' '넘치면 10개 + .. N files not shown' 'following 12 files? … m09.txt\n.. 2 files not shown' (Open-Of $f) ((Open-Of $f) -match [regex]::Escape('permanently delete the following 12 files?\nm00.txt') -and (Open-Of $f) -match [regex]::Escape('m09.txt\n.. 2 files not shown"') -and (Open-Of $f) -notmatch 'm10\.txt')
        Check 'trash' 'D-12' '넘치는 목록 취소 → 12개 그대로' '12' (@(Disk-Names 'many' | Where-Object { $_ -match '^m(0\d|1[01])\.txt$' }).Count) (@(Disk-Names 'many' | Where-Object { $_ -match '^m(0\d|1[01])\.txt$' }).Count -eq 12)
        Click-Row 'many'
        # ⑧ 실패(잠긴 파일) → 알림
        $lockPath = Join-Path $proj 'ops\locked.txt'
        $lock = [System.IO.File]::Open($lockPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::None)
        try {
            Click-Row 'locked.txt'
            $bn = Count-Lines '^\[dev\] notification '
            $f = Delete-Flow 'trash' { Send-Keys 'shift-delete' } 'confirm'
            $n = Wait-NewLine '^\[dev\] notification ' $bn 5
            Check 'trash' 'A-14.11·D-14' '영구 삭제 실패 → 알림 문구' '[dev] notification text=Failed to delete 1 of 1 file(s).' $n ($n -ceq '[dev] notification text=Failed to delete 1 of 1 file(s).' -and (Disk-Has 'ops\locked.txt'))
            Start-Sleep -Milliseconds 300
            [void](Save-Window 'delete-failure-notification')
            $bn = Count-Lines '^\[dev\] notification '
            $f = Delete-Flow 'trash' { Send-Keys 'delete' } 'confirm'
            $n = Wait-NewLine '^\[dev\] notification ' $bn 8
            Check 'trash' 'A-14.11·D-14' '휴지통 실패 → 알림 문구' '[dev] notification text=Failed to trash 1 of 1 file(s).' $n ($n -ceq '[dev] notification text=Failed to trash 1 of 1 file(s).' -and (Disk-Has 'ops\locked.txt'))
            Start-Sleep -Milliseconds 300
            [void](Save-Window 'trash-failure-notification')
        }
        finally { $lock.Dispose() }
        # ⑨ 키를 바꿔도 확인창을 건너뛰지 않는다(사용자 keymap.json, 끝에 지운다)
        Write-Utf8 $keymapPath '[ { "context": "ProjectPanel", "bindings": { "ctrl-t": "project_panel::Trash" } } ]'
        Start-Sleep -Milliseconds 1500
        Click-Row 'f3.txt'
        $f = Delete-Flow 'trash' { Send-Keys 'ctrl-t' } 'esc'
        Check 'trash' 'A-14 아래 목록' '사용자 키(ctrl-t → Trash)도 확인창을 띄운다' 'trash `f3.txt`, Cancel' ("{0} / {1}" -f (Open-Of $f), $f.result) ((Open-Of $f) -match [regex]::Escape('Do you want to trash `f3.txt`?') -and $f.result -match 'Cancel')
        Remove-Item -LiteralPath $keymapPath -Force
        # ⑩ 휴지통에서 복원(A-14.5): 이번 실행이 버린 항목만
        if ($envr.available) {
            $r = Invoke-Trash 'restore' 'trash-restore'
            Start-Sleep -Milliseconds 500
            Check 'trash' 'A-14.5' '휴지통에서 복원 → 원래 자리에 다시 있음' 'f1 있음, 휴지통 비움' ("f1={0}, {1}" -f (Disk-Has 'ops\f1.txt'), ($r[-1])) ((Disk-Has 'ops\f1.txt') -and (@(Trash-Names).Count -eq 0))
        }
        [void](Save-Disk 'trash-disk-3-after-restore')
    }

    # ================================================================ clip: R-21 (I-037, I-041, I-097, I-543, I-544, I-548, I-549)
    function Ctx-Rows { $l = Last-Line '^\[dev\] context-menu-open rows='; [void]($l -match 'rows=(.*)$'); @($Matches[1].Split("`t")) }
    function Ctx-Click([string]$Label) {
        $rows = Ctx-Rows
        for ($i = 0; $i -lt $rows.Count; $i++) { if ($rows[$i].Split('|')[0] -eq $Label) { Click-Box "ctx-menu-row-$i" "menu $Label"; Wait-Quiet; return } }
        throw "메뉴에 '$Label' 이 없다: $($rows -join ' / ')"
    }
    Reset-Proj
    Run-Case 'clip' (New-StateJson @($proj) 0) {
        param($res, $p)
        Send-Keys 'ctrl-shift-e'
        Click-Row 'ops'
        Click-Row 'sub'
        $d0 = Save-Disk 'clip-disk-0-before'
        Click-Row 's.txt' -How 'right'
        Wait-Quiet
        $paste = @(Ctx-Rows | Where-Object { $_ -like 'Paste|*' })[0]
        Check 'clip' 'I-544' '붙여 넣을 것이 없으면 Paste 비활성' 'Paste|disabled|Ctrl-V' $paste ($paste -eq 'Paste|disabled|Ctrl-V')
        Send-Keys 'escape'
        Send-Keys 'ctrl-c'
        Check 'clip' 'I-037' 'Ctrl+C → 파일 복사(텍스트 아님)' 'file-clipboard op=copy …s.txt' (Last-Line '^\[dev\] file-clipboard ') ((Last-Line '^\[dev\] file-clipboard ') -match 'op=copy paths=.*ops\\sub\\s\.txt$')
        Click-Row 'ops' @('ctrl')
        Send-Keys 'ctrl-v'
        Check 'clip' 'I-037' 'Ctrl+V → 대상 폴더에 복사' 'ops\s.txt (원본 그대로)' ("{0}, src={1}" -f (Disk-Has 'ops\s.txt'), (Disk-Has 'ops\sub\s.txt')) ((Disk-Has 'ops\s.txt') -and (Disk-Has 'ops\sub\s.txt'))
        $tb = Get-Tabs
        Check 'clip' 'I-097·R-27' '붙여 넣은 파일을 연다(일반 탭, 포커스는 패널, 판단)' 's.txt|normal, project_panel' ("{0}, {1}" -f (Tabs-Text), (Focus-Now)) (($tb.list | Where-Object { $_.path -like '*\ops\s.txt' }).kind -eq 'normal' -and (Focus-Now) -eq 'project_panel')
        Click-Row 'ops' @('ctrl')
        Click-Row 'ops' @('ctrl')
        Send-Keys 'ctrl-v'
        Check 'clip' 'I-037(판단)' '같은 이름이 있으면 " copy" 이름' 'ops\s copy.txt' (Disk-Has 'ops\s copy.txt') (Disk-Has 'ops\s copy.txt')
        Click-Row 'f1.txt'
        Send-Keys 'ctrl-insert'
        Click-Row 'ops' @('ctrl')
        Send-Keys 'shift-insert'
        Check 'clip' 'I-037' 'Ctrl+Insert 복사 / Shift+Insert 붙여넣기' 'ops\f1 copy.txt' (Disk-Has 'ops\f1 copy.txt') (Disk-Has 'ops\f1 copy.txt')
        Click-Row 'f2.txt'
        Send-Keys 'ctrl-x'
        Click-Row 'sub' @('ctrl')
        Send-Keys 'ctrl-v'
        Check 'clip' 'I-037' 'Ctrl+X → Ctrl+V 는 옮긴다' 'ops\sub\f2.txt 있음, ops\f2.txt 없음' ("{0}, {1}" -f (Disk-Has 'ops\sub\f2.txt'), (Disk-Has 'ops\f2.txt')) ((Disk-Has 'ops\sub\f2.txt') -and -not (Disk-Has 'ops\f2.txt'))
        Click-Row 'f3.txt' -How 'right'
        Wait-Quiet
        $paste = @(Ctx-Rows | Where-Object { $_ -like 'Paste|*' })[0]
        Check 'clip' 'I-544(판단)' '잘라내 붙인 뒤 클립보드를 비운다 → Paste 비활성' 'Paste|disabled|Ctrl-V' $paste ($paste -eq 'Paste|disabled|Ctrl-V')
        Ctx-Click 'Duplicate'
        Check 'clip' 'I-543' 'Duplicate → 같은 폴더에 " copy"' 'ops\f3 copy.txt' (Disk-Has 'ops\f3 copy.txt') (Disk-Has 'ops\f3 copy.txt')
        Click-Row 'sub' @('ctrl')
        Send-Keys 'ctrl-c'
        Send-Keys 'home'
        Send-Keys 'ctrl-v'
        Check 'clip' 'I-037' '폴더 복사(통째로)' 'sub\s.txt, sub\f2.txt' ("{0}, {1}" -f (Disk-Has 'sub\s.txt'), (Disk-Has 'sub\f2.txt')) ((Disk-Has 'sub\s.txt') -and (Disk-Has 'sub\f2.txt'))
        Click-Row 'README.md'
        Send-Keys 'alt-shift-c'
        Start-Sleep -Milliseconds 300
        $abs = Join-Path $proj 'README.md'
        $clip = Get-Clipboard -Raw
        Check 'clip' 'I-041·I-548' 'Shift+Alt+C → 절대 경로(OS 클립보드)' $abs $clip ($clip -eq $abs)
        Send-Keys 'ctrl-k ctrl-shift-c'
        Start-Sleep -Milliseconds 300
        $clip = Get-Clipboard -Raw
        Check 'clip' 'I-041·I-549' 'Ctrl+K Ctrl+Shift+C → 상대 경로' 'README.md' $clip ($clip -eq 'README.md')
        Click-Row 'f1.txt' @('ctrl')
        Send-Keys 'ctrl-k ctrl-shift-c'
        Start-Sleep -Milliseconds 300
        $clip = (Get-Clipboard -Raw) -replace "`r", ''
        Check 'clip' 'I-549·I-562(판단)' '여러 항목 → 줄마다 하나' "README.md`nops\f1.txt" ($clip -replace "`n", '\n') ($clip -eq "README.md`nops\f1.txt")
        $d1 = Save-Disk 'clip-disk-1-after'
        $res.diskChanges = @(Compare-Object $d0 $d1 | ForEach-Object { "$($_.SideIndicator) $($_.InputObject.Split('|')[0])" })
        [void](Save-Window 'clip-end')
    }

    # ================================================================ menu: R-22 (I-530~I-562, I-660~I-662, I-042, I-502, D-15), R-13 이월(루트 Remove from Project)
    $mFileHead = @('New File|enabled|Ctrl-N', 'New Folder|enabled|Alt-N', '---', 'Reveal in File Explorer|enabled|Ctrl-Alt-R', 'Open in Default App|enabled|Ctrl-Shift-Enter')
    $mEdit = @('---', 'Cut|enabled|Ctrl-X', 'Copy|enabled|Ctrl-C', 'Duplicate|enabled', 'Paste|disabled|Ctrl-V', '---', 'Copy Path|enabled|Alt-Shift-C', 'Copy Relative Path|enabled|Ctrl-K Ctrl-Shift-C')
    $mNonRoot = @('---', 'Rename|enabled|F2', 'Trash|enabled|Delete', 'Delete|enabled|Ctrl-Delete')
    $expect = [ordered]@{
        'README.md (마크다운 파일, I-660)' = @($mFileHead + @('Open Markdown Preview|disabled') + $mEdit + $mNonRoot)
        'notes.txt (파일, I-660)' = @($mFileHead + $mEdit + $mNonRoot)
        'src (폴더, I-661)' = @($mFileHead + $mEdit + $mNonRoot + @('---', 'Expand All|enabled', 'Collapse All|enabled'))
        'docs \ guides (접힌 폴더, I-661·I-538)' = @($mFileHead + @('---', 'Unfold Directory|enabled') + $mEdit + $mNonRoot + @('---', 'Expand All|enabled', 'Collapse All|enabled'))
        'proj (루트, I-662)' = @($mFileHead + $mEdit + @('---', 'Add Folders to Project…|enabled', 'Remove from Project|enabled', '---', 'Expand All|enabled|Ctrl-Right', 'Collapse All|enabled|Ctrl-Left'))
    }
    Reset-Proj
    Run-Case 'menu' (New-StateJson @($proj) 0) {
        param($res, $p)
        Send-Keys 'ctrl-shift-e'
        $n = 0
        foreach ($k in $expect.Keys) {
            $label = $k.Split(' (')[0]
            Click-Row $label -How 'right'
            Wait-Quiet
            $got = @(Ctx-Rows)
            $want = $expect[$k]
            $sel = (Get-Tree).selected
            Check 'menu' 'I-530~I-557·11.2절' "$k 메뉴 항목·단축키·구분선·비활성" ($want -join ' / ') ($got -join ' / ') (($got -join "`t") -ceq ($want -join "`t"))
            Check 'menu' 'I-560' "$k 우클릭한 항목이 선택이 된다" $label $sel ((Get-Tree).rows[(Row-Index $label)].label -eq $label -and $sel -ne 'none')
            $n++
            [void](Save-Window ('menu-{0:d2}' -f $n))
            Send-Keys 'escape'
        }
        # I-559 빈 공간 → 루트 메뉴
        $t = Need-Box ('tree-row-{0:d2}' -f ((Get-Tree).rows.Count - 1))
        $pt = ToScreen ($t.x + 80) ($t.y + $t.h + 120)
        Assert-Target $pt[0] $pt[1] 'empty space'
        [WgP4.Native]::RightClick($pt[0], $pt[1]); Start-Sleep -Milliseconds 400; Wait-Quiet
        Check 'menu' 'I-559' '빈 공간 우클릭 → 루트 메뉴' ($expect['proj (루트, I-662)'] -join ' / ') ((Ctx-Rows) -join ' / ') (((Ctx-Rows) -join "`t") -ceq ($expect['proj (루트, I-662)'] -join "`t") -and (Get-Tree).selected -eq '.')
        [void](Save-Window 'menu-empty-space')
        Send-Keys 'escape'
        # I-042·I-502 키보드로 열기: 선택 항목 옆 (2, 2)
        Click-Row 'notes.txt'
        foreach ($key in 'shift-f10', 'menu') {
            $rb = Row-Box 'notes.txt'
            $bt = Count-Lines '^\[dev\] panel-menu-target '
            Send-Keys $key
            $l = Wait-NewLine '^\[dev\] panel-menu-target ' $bt 3
            [void]($l -match 'x=([\d.]+) y=([\d.]+)')
            Check 'menu' 'I-042·I-502' "$key → 메뉴, 선택 항목 왼쪽 아래 + (2, 2)(판단: 기준 모서리)" ("{0},{1}" -f ($rb.x + 2), ($rb.y + $rb.h + 2)) ("{0},{1}" -f $Matches[1], $Matches[2]) ((Near ([double]$Matches[1]) ($rb.x + 2)) -and (Near ([double]$Matches[2]) ($rb.y + $rb.h + 2)))
            if ($key -eq 'menu') { [void](Save-Window 'menu-keyboard') }
            Send-Keys 'escape'
        }
        # 실행: Unfold → Fold
        Click-Row 'docs \ guides' -How 'right'; Ctx-Click 'Unfold Directory'
        Check 'menu' 'I-538' 'Unfold Directory → docs 와 guides 가 따로 보인다' 'docs 줄 있음, docs \ guides 없음' (Tree-Labels) ((Row-Index 'docs') -gt 0 -and (Row-Index 'docs \ guides') -lt 0)
        Click-Row 'docs' -How 'right'
        Check 'menu' 'I-539' '접을 수 있는 폴더에 Fold Directory' 'Fold Directory|enabled' (@(Ctx-Rows | Where-Object { $_ -like '*Fold Directory*' }) -join ',') (@(Ctx-Rows) -contains 'Fold Directory|enabled')
        Ctx-Click 'Fold Directory'
        Check 'menu' 'I-539' 'Fold Directory → 다시 docs \ guides' 'docs \ guides' (Tree-Labels) ((Row-Index 'docs \ guides') -gt 0)
        # 실행: 하위 폴더 Expand All / Collapse All
        Click-Row 'src' -How 'right'; Ctx-Click 'Expand All'
        Check 'menu' 'I-556' '하위 폴더 Expand All → 그 아래 모두 펼침' 'src, src\util' ((Get-Tree).expanded -join ';') (((Get-Tree).expanded -contains 'src') -and ((Get-Tree).expanded -contains 'src\util'))
        Click-Row 'src' -How 'right'; Ctx-Click 'Collapse All'
        Check 'menu' 'I-557' '하위 폴더 Collapse All → 그 아래 모두 접힘' 'src·src\util 없음' ((Get-Tree).expanded -join ';') (-not ((Get-Tree).expanded -contains 'src') -and -not ((Get-Tree).expanded -contains 'src\util'))
        # 실행: Reveal·Open in Default App(--dev-no-shell: 실행 대신 기록)
        Click-Row 'notes.txt' -How 'right'; Ctx-Click 'Reveal in File Explorer'
        $sh = Last-Line '^\[dev\] shell op=reveal '
        Check 'menu' 'I-532' 'Reveal in File Explorer → explorer.exe /select,"경로"' ('/select,"{0}"' -f (Join-Path $proj 'notes.txt')) $sh ($sh -match 'op=reveal program=explorer\.exe arg="/select,\\"' -and $sh -match 'notes\.txt\\"" executed=false$')
        Click-Row 'notes.txt' -How 'right'; Ctx-Click 'Open in Default App'
        $sh = Last-Line '^\[dev\] shell op=open-default '
        Check 'menu' 'I-533' 'Open in Default App → 기본 앱으로 열기(ShellExecute)' (Join-Path $proj 'notes.txt') $sh ($sh -like ('*path=' + (Join-Path $proj 'notes.txt') + '*'))
        # 실행: Copy·Rename·Trash 는 키와 같은 동작(메뉴로 한 번씩)
        Click-Row 'notes.txt' -How 'right'; Ctx-Click 'Copy'
        Check 'menu' 'I-542' '메뉴 Copy → 파일 클립보드' 'op=copy notes.txt' (Last-Line '^\[dev\] file-clipboard ') ((Last-Line '^\[dev\] file-clipboard ') -match 'op=copy paths=.*notes\.txt$')
        Click-Row 'notes.txt' -How 'right'; Ctx-Click 'Rename'
        Check 'menu' 'I-551' '메뉴 Rename → 입력칸' 'kind=rename target=notes.txt' (Last-Line '^\[dev\] edit ') ((Last-Line '^\[dev\] edit ') -match 'kind=rename target=notes\.txt')
        Send-Keys 'escape'
        $f = Delete-Flow 'menu' { Click-Row 'notes.txt' -How 'right'; Ctx-Click 'Trash' } 'esc'
        Check 'menu' 'I-552' '메뉴 Trash → 확인창' 'trash `notes.txt`' $f.open ($f.open -match [regex]::Escape('Do you want to trash `notes.txt`?'))
        $f = Delete-Flow 'menu' { Click-Row 'notes.txt' -How 'right'; Ctx-Click 'Delete' } 'esc'
        Check 'menu' 'I-553' '메뉴 Delete → 영구 삭제 확인창' 'permanently delete `notes.txt`' $f.open ($f.open -match [regex]::Escape('permanently delete `notes.txt`?'))
        Click-Row 'ops' -How 'right'; Ctx-Click 'New File'
        Check 'menu' 'I-530' '메뉴 New File → 그 폴더에 입력칸' 'kind=new-file target=ops' (Last-Line '^\[dev\] edit ') ((Last-Line '^\[dev\] edit ') -match 'kind=new-file target=ops ')
        Send-Keys 'escape'
        # 루트: Add Folders to Project… → 폴더 등록, Remove from Project → 등록 해제(디스크 그대로)
        $l = Add-Via $proj2 { Click-Row 'proj' -How 'right'; Ctx-Click 'Add Folders to Project…' }
        Check 'menu' 'I-554' 'Add Folders to Project… → 폴더 등록' 'folder-add result=added index=1' $l ($l -match 'result=added index=1')
        Start-Sleep -Milliseconds 500
        $d0 = Save-Disk 'menu-disk-before-remove'
        Click-Row 'proj2' -How 'right'; Ctx-Click 'Remove from Project'
        Start-Sleep -Milliseconds 500
        $d1 = Save-Disk 'menu-disk-after-remove'
        $rm = Last-Line '^\[dev\] folder-remove '
        Check 'menu' 'I-555·R-13·A-14.3' 'Remove from Project → 등록 해제, 디스크 그대로' 'folder-remove via=project-panel-menu, 디스크 같음' ("{0}, same={1}" -f $rm, (($d0 -join "`n") -eq ($d1 -join "`n"))) ($rm -match 'via=project-panel-menu' -and $rm -match 'proj2' -and (($d0 -join "`n") -eq ($d1 -join "`n")) -and (Get-Folders).count -eq 1)
        [void](Save-Window 'menu-after-remove')
    }

    # ================================================================ reveal: R-23 (I-096), readonly: R-27·D-18, tooltip: L-247
    function Snap-Field([string]$Name) {
        $l = @(Get-Lines '^\[dev\] layout-snapshot seq=\d+ ')
        if ($l.Count -eq 0) { return $null }
        if ($l[-1] -match ("{0}=(\S+)" -f [regex]::Escape($Name))) { return $Matches[1] }
        return $null
    }
    Reset-Proj
    Run-Case 'reveal' (New-StateJson @($proj) 0) {
        param($res, $p)
        Send-Keys 'ctrl-shift-e'
        Send-Keys 'ctrl-left'
        Send-Keys 'home'
        Send-Keys 'ctrl-n'
        Type-Text 'r23/a/b/c.md'
        Send-Keys 'enter'
        Start-Sleep -Milliseconds 600
        $t = Get-Tree
        Check 'reveal' 'I-096·R-23' '활성 파일이 바뀌면 그 항목까지 펼쳐 보인다(접힌 경로 r23 \ a \ b 펼침, c.md 선택)' 'expanded r23\a\b, selected r23\a\b\c.md, 행 c.md' ("expanded={0}, selected={1}, rows={2}" -f ($t.expanded -join ';'), $t.selected, (Tree-Labels)) (($t.expanded -contains 'r23\a\b') -and $t.selected -eq 'r23\a\b\c.md' -and (Row-Index 'c.md') -gt 0 -and (Row-Index 'r23 \ a \ b') -gt 0)
        Check 'reveal' 'I-096' '트리에 포커스를 가져오지 않는다(편집기에 남음)' 'editor' (Focus-Now) ((Focus-Now) -eq 'editor')
        Check 'reveal' 'R-23' 'reveal 기록' 'reveal path=…\r23\a\b\c.md' (Last-Line '^\[dev\] reveal ') ((Last-Line '^\[dev\] reveal ') -like '*\r23\a\b\c.md')
        [void](Save-Window 'reveal-deep')
    }
    Reset-Proj
    Run-Case 'readonly' (New-StateJson @($proj) 0) {
        param($res, $p)
        $h0 = (Get-FileHash -LiteralPath (Join-Path $proj 'README.md') -Algorithm SHA256).Hash
        Click-Row 'README.md'
        Start-Sleep -Milliseconds 800
        Double-Open 'x' 'README.md'
        Start-Sleep -Milliseconds 800
        $len0 = Snap-Field 'active_text_len'; $fnv0 = Snap-Field 'active_text_fnv'
        $raw = Get-Content -LiteralPath (Join-Path $proj 'README.md') -Raw -Encoding utf8
        $nRaw = [System.Text.Encoding]::UTF8.GetByteCount($raw); $nLf = [System.Text.Encoding]::UTF8.GetByteCount($raw.Replace("`r`n", "`n"))
        Check 'readonly' 'R-27' '탭 내용 = 파일 내용(gpui-kit Editor, 줄 끝 CRLF 는 LF 로 보일 수 있다)' "len=$nRaw 또는 $nLf" "len=$len0" ([int]$len0 -eq $nRaw -or [int]$len0 -eq $nLf)
        Check 'readonly' 'I-087' '편집기 포커스' 'editor' (Focus-Now) ((Focus-Now) -eq 'editor')
        Type-Text 'XYZ 한글'
        Send-Keys 'enter backspace delete'
        Start-Sleep -Milliseconds 800
        $len1 = Snap-Field 'active_text_len'; $fnv1 = Snap-Field 'active_text_fnv'
        $h1 = (Get-FileHash -LiteralPath (Join-Path $proj 'README.md') -Algorithm SHA256).Hash
        Check 'readonly' 'D-18·R-27' '글자를 쳐도 탭 내용·디스크 파일이 바뀌지 않는다' "len=$len0 fnv=$fnv0, 디스크 해시 같음" ("len={0} fnv={1}, 디스크 같음={2}" -f $len1, $fnv1, ($h0 -eq $h1)) ($len0 -eq $len1 -and $fnv0 -eq $fnv1 -and $h0 -eq $h1)
        [void](Save-Window 'readonly-after-typing')
    }
    Reset-Proj
    Run-Case 'tooltip' (New-StateJson @($proj) 0) {
        param($res, $p)
        $i = Row-Index 'README.md'
        $m = Measure-Tooltip 'tooltip' ('tree-row-{0:d2}' -f $i) 'tooltip-tree-item'
        $abs = Join-Path $proj 'README.md'
        Check 'tooltip' 'L-247·L-49' '항목 hover → 절대 경로 툴팁(홈 아래가 아니면 그대로)' "$abs|<none>" $m.rows ($m -and $m.rows -eq "$abs|<none>")
        Check 'tooltip' 'L-247' '지연 1500ms' '1500±250' $m.delayMs ($m -and [math]::Abs($m.delayMs - 1500) -le 250)
        $res.tooltip = $m
    }

    # ================================================================ a332: R-25 시나리오 A-33.2 (I-061, I-062, I-064, I-087)
    Reset-Proj
    Run-Case 'a332' (New-StateJson @($proj) 0) {
        param($res, $p)
        $res.steps = @()
        Click-Row 'README.md'
        $tb = Get-Tabs
        $res.steps += "1 README.md 한 번 클릭: $(Tabs-Text), focus=$(Focus-Now)"
        Check 'a332' 'A-33.2①·I-061·I-064' 'README.md 한 번 클릭 → 임시 탭(제목 기울임, 스크린샷)' 'README.md|preview 하나' (Tabs-Text) ($tb.count -eq 1 -and $tb.list[0].title -eq 'README.md' -and $tb.list[0].kind -eq 'preview')
        [void](Save-Window 'a332-1-readme-preview')
        Click-Row 'notes.txt'
        $tb = Get-Tabs
        $res.steps += "2 notes.txt 한 번 클릭: $(Tabs-Text)"
        Check 'a332' 'A-33.2②·I-062' '다른 파일 한 번 클릭 → 같은 자리(0)에서 교체' 'active=0 notes.txt|preview 하나' (Tabs-Text) ($tb.count -eq 1 -and $tb.active -eq '0' -and $tb.list[0].title -eq 'notes.txt' -and $tb.list[0].kind -eq 'preview')
        [void](Save-Window 'a332-2-notes-replaced')
        Start-Sleep -Milliseconds 600
        Double-Open 'x' 'notes.txt'
        $tb = Get-Tabs
        $res.steps += "3 notes.txt 더블클릭: $(Tabs-Text), focus=$(Focus-Now)"
        Check 'a332' 'A-33.2③·I-087·I-063' '더블클릭 → 일반 탭(기울임 없음), 편집기 포커스' 'notes.txt|normal 하나, editor' ("{0}, {1}" -f (Tabs-Text), (Focus-Now)) ($tb.count -eq 1 -and $tb.list[0].kind -eq 'normal' -and (Focus-Now) -eq 'editor')
        [void](Save-Window 'a332-3-notes-normal')
        Click-Row 'README.md'
        $tb = Get-Tabs
        $res.steps += "4 README.md 한 번 클릭(일반 탭 옆에 새 임시 탭): $(Tabs-Text)"
        Check 'a332' 'I-062' '일반 탭은 두고 새 임시 탭을 뒤에' 'notes.txt|normal, README.md|preview' (Tabs-Text) ($tb.count -eq 2 -and $tb.list[0].kind -eq 'normal' -and $tb.list[1].title -eq 'README.md' -and $tb.list[1].kind -eq 'preview')
        [void](Save-Window 'a332-4-second-preview')
    }

    # ================================================================ a334: R-26 시나리오 A-33.4 (A-13, A-15) + A-15.2·R-12 이월(폴더별 트리 펼침·선택·스크롤)
    Reset-Proj
    Run-Case 'a334' (New-StateJson @($proj, $proj2) 0) {
        param($res, $p)
        $res.steps = @()
        Click-Row 'README.md'
        Start-Sleep -Milliseconds 600
        Double-Open 'x' 'README.md'
        Click-Row 'many'
        $tr = Need-Box 'tree-row-03'
        $wp = ToScreen ($tr.x + 80) ($tr.y + 100)
        Assert-Target $wp[0] $wp[1] 'tree wheel'
        for ($k = 0; $k -lt 3; $k++) { [WgP4.Native]::Wheel($wp[0], $wp[1], -120); Start-Sleep -Milliseconds 150 }
        Start-Sleep -Milliseconds 800; Wait-Quiet
        $treeA = Get-Tree; $scrollA = Snap-Field 'tree_scroll_y'; $tabsA = Tabs-Text
        $res.steps += "1 proj: 탭 $tabsA / 펼침 $($treeA.expanded -join ';') / 선택 $($treeA.selected) / scroll $scrollA"
        Check 'a334' 'A-33.4①' 'proj 에서 탭을 연다' 'README.md|normal' $tabsA ($tabsA -match 'README\.md\|normal')
        [void](Save-Window 'a334-1-proj-tab')
        Click-Box 'folder-row-01' 'activate proj2'
        Wait-Quiet
        Click-Row 'b-readme.md'
        Start-Sleep -Milliseconds 600
        Double-Open 'x' 'b-readme.md'
        $tabsB = Tabs-Text
        $res.steps += "2 proj2: 탭 $tabsB"
        Check 'a334' 'A-33.4①·A-15.1' 'proj2 에서 탭을 연다(proj 탭은 안 보인다)' 'b-readme.md|normal 만' $tabsB ($tabsB -match 'b-readme\.md\|normal' -and $tabsB -cnotmatch 'README\.md')
        [void](Save-Window 'a334-2-proj2-tab')
        Click-Box 'folder-row-00' 'activate proj'
        Wait-Quiet; Start-Sleep -Milliseconds 600; Wait-Quiet
        $treeA2 = Get-Tree; $scrollA2 = Snap-Field 'tree_scroll_y'; $tabsA2 = Tabs-Text
        $res.steps += "3 proj 로 돌아옴: 탭 $tabsA2 / 펼침 $($treeA2.expanded -join ';') / 선택 $($treeA2.selected) / scroll $scrollA2"
        Check 'a334' 'A-33.4②·A-15.1' '전환해도 proj 탭이 그대로' $tabsA $tabsA2 ($tabsA2 -eq $tabsA)
        Check 'a334' 'A-15.2·R-12' 'proj 트리 펼침·선택이 그대로' ("{0} / {1}" -f ($treeA.expanded -join ';'), $treeA.selected) ("{0} / {1}" -f ($treeA2.expanded -join ';'), $treeA2.selected) ((($treeA.expanded -join ';') -eq ($treeA2.expanded -join ';')) -and $treeA.selected -eq $treeA2.selected)
        Check 'a334' 'A-15.2·R-12' 'proj 트리 스크롤 위치가 그대로(스크롤한 값)' $scrollA $scrollA2 ($scrollA -and $scrollA -eq $scrollA2 -and [double]$scrollA -lt 0)
        [void](Save-Window 'a334-3-back-to-proj')
        Click-Box 'folder-row-01' 'activate proj2 again'
        Wait-Quiet
        $tabsB2 = Tabs-Text
        Check 'a334' 'A-33.4②' 'proj2 탭도 그대로' $tabsB $tabsB2 ($tabsB2 -eq $tabsB)
        $d0 = Save-Disk 'a334-disk-before-remove'
        $bc = Count-Lines '^\[dev\] folder-tabs-closed '
        RightClick-Box 'folder-row-01'
        Ctx-Click 'Remove'
        Start-Sleep -Milliseconds 600
        $d1 = Save-Disk 'a334-disk-after-remove'
        $tc = Wait-NewLine '^\[dev\] folder-tabs-closed ' $bc 3
        $res.steps += "4 proj2 해제: $tc / 폴더 $(Names) / 디스크 같음 $((($d0 -join "`n") -eq ($d1 -join "`n")))"
        Check 'a334' 'A-33.4③·R-13' '하나를 해제 → 그 폴더 탭을 닫는다' 'folder-tabs-closed count=1' $tc ($tc -match 'count=1$')
        Check 'a334' 'A-33.4④·A-14.3' '해제한 폴더는 디스크에 그대로' '디스크 목록 같음' ("same={0}, proj2\b-readme.md={1}" -f (($d0 -join "`n") -eq ($d1 -join "`n")), (Test-Path -LiteralPath (Join-Path $proj2 'b-readme.md'))) ((($d0 -join "`n") -eq ($d1 -join "`n")) -and (Test-Path -LiteralPath (Join-Path $proj2 'b-readme.md')))
        Check 'a334' 'A-13.5' '해제 뒤 남은 proj 활성, 탭 그대로' $tabsA ("{0} / {1}" -f (Names), (Tabs-Text)) ((Names) -eq 'proj' -and (Tabs-Text) -eq $tabsA)
        [void](Save-Window 'a334-4-after-remove')
    }

    # ================================================================ menukeys: R-9 범위 I-520(프로젝트 패널 우클릭 메뉴, D-042 ④)
    function Shortcut-Pair([int]$Bs, [int]$Be) {
        $s = Wait-NewLine '^\[dev\] context-menu-shortcut ' $Bs 3
        $e = Wait-NewLine '^\[dev\] context-menu-exec .* via=shortcut ' $Be 3
        $gap = $null
        if ($s -and $e) { [void]($s -match 't_ms=(\d+)'); $t0 = [int64]$Matches[1]; [void]($e -match 't_ms=(\d+)'); $gap = [int64]$Matches[1] - $t0 }
        [pscustomobject]@{ shortcut = $s; exec = $e; gapMs = $gap }
    }
    Reset-Proj
    Run-Case 'menukeys' (New-StateJson @($proj) 0) {
        param($res, $p)
        Send-Keys 'ctrl-shift-e'
        # ① F2: Rename 항목 선택 표시 → 50ms 뒤 닫고 실행
        Click-Row 'notes.txt' -How 'right'; Wait-Quiet
        $bs = Count-Lines '^\[dev\] context-menu-shortcut '; $be = Count-Lines '^\[dev\] context-menu-exec .* via=shortcut '
        Send-Keys 'f2'
        $r = Shortcut-Pair $bs $be
        Check 'menukeys' 'I-520' '메뉴가 열린 채 F2 → Rename 선택 표시 뒤 실행' 'shortcut action=project_panel::Rename → exec item=Rename via=shortcut' ("{0} / {1}" -f $r.shortcut, $r.exec) ($r.shortcut -match 'action=project_panel::Rename' -and $r.exec -match 'item=Rename via=shortcut')
        Check 'menukeys' 'I-520' '선택 표시 뒤 실행까지 약 50ms' '50~200ms' $r.gapMs ($null -ne $r.gapMs -and $r.gapMs -ge 45 -and $r.gapMs -le 200)
        Check 'menukeys' 'I-520·I-309' '실행 결과: 패널 자리에서 이름 변경 입력칸' 'kind=rename target=notes.txt' (Last-Line '^\[dev\] edit ') ((Last-Line '^\[dev\] edit ') -match 'what=start active=true kind=rename target=notes\.txt')
        Send-Keys 'escape'
        # ② chord: Ctrl+K Ctrl+Shift+C → Copy Relative Path(열기 전 패널 컨텍스트로 해석)
        Click-Row 'README.md' -How 'right'; Wait-Quiet
        $bs = Count-Lines '^\[dev\] context-menu-shortcut '; $be = Count-Lines '^\[dev\] context-menu-exec .* via=shortcut '
        Send-Keys 'ctrl-k ctrl-shift-c'
        $r = Shortcut-Pair $bs $be
        Start-Sleep -Milliseconds 300
        $clip = Get-Clipboard -Raw
        Check 'menukeys' 'I-520·I-549' 'chord 단축키도 항목 실행(Copy Relative Path)' 'exec item=Copy Relative Path, 클립보드 README.md' ("{0} / {1}" -f $r.exec, $clip) ($r.exec -match 'item=Copy Relative Path via=shortcut' -and $clip -eq 'README.md')
        # ③ 메뉴 키(Down·Escape)는 메뉴가 받는다
        Click-Row 'README.md' -How 'right'; Wait-Quiet
        $bs = Count-Lines '^\[dev\] context-menu-shortcut '
        Send-Keys 'down escape'
        Check 'menukeys' 'I-517' 'Down·Escape 는 메뉴 키(단축키 실행 없음), Escape 로 닫힘' 'shortcut 0, close reason=cancel' ("shortcut+{0}, {1}" -f ((Count-Lines '^\[dev\] context-menu-shortcut ') - $bs), (Last-Line '^\[dev\] context-menu-close ')) (((Count-Lines '^\[dev\] context-menu-shortcut ') -eq $bs) -and (Last-Line '^\[dev\] context-menu-close ') -match 'reason=cancel')
        # ④ 비활성 항목(Paste) 단축키는 실행하지 않는다
        Click-Row 'README.md' -How 'right'; Wait-Quiet
        $bs = Count-Lines '^\[dev\] context-menu-shortcut '; $bp = Count-Lines '^\[dev\] fs-op op=paste'
        Send-Keys 'ctrl-v'
        Start-Sleep -Milliseconds 300
        Check 'menukeys' 'I-520·I-544·I-515' '비활성 Paste 의 Ctrl+V → 예약·실행 없음' 'shortcut 0, paste 0' ("shortcut+{0}, paste+{1}" -f ((Count-Lines '^\[dev\] context-menu-shortcut ') - $bs), ((Count-Lines '^\[dev\] fs-op op=paste') - $bp)) (((Count-Lines '^\[dev\] context-menu-shortcut ') -eq $bs) -and ((Count-Lines '^\[dev\] fs-op op=paste') -eq $bp))
        Send-Keys 'escape'
        # ⑤ 50ms 안에 Escape → 예약 취소(세대)
        Click-Row 'notes.txt' -How 'right'; Wait-Quiet
        $bs = Count-Lines '^\[dev\] context-menu-shortcut '; $be = Count-Lines '^\[dev\] context-menu-exec .* via=shortcut '; $bed = Count-Lines '^\[dev\] edit what=start'
        Send-Batch 'f2 escape'
        Start-Sleep -Milliseconds 400; Wait-Quiet
        Check 'menukeys' 'I-520(D-032 세대)' '예약 뒤 50ms 안에 닫으면 실행하지 않는다' 'shortcut 1, exec 0, edit 0' ("shortcut+{0}, exec+{1}, edit+{2}" -f ((Count-Lines '^\[dev\] context-menu-shortcut ') - $bs), ((Count-Lines '^\[dev\] context-menu-exec .* via=shortcut ') - $be), ((Count-Lines '^\[dev\] edit what=start') - $bed)) (((Count-Lines '^\[dev\] context-menu-shortcut ') -eq $bs + 1) -and ((Count-Lines '^\[dev\] context-menu-exec .* via=shortcut ') -eq $be) -and ((Count-Lines '^\[dev\] edit what=start') -eq $bed))
        # ⑥ 루트 메뉴 Ctrl+Right → Expand All
        Click-Row 'proj' -How 'right'; Wait-Quiet
        $be = Count-Lines '^\[dev\] context-menu-exec .* via=shortcut '
        Send-Keys 'ctrl-right'
        $e = Wait-NewLine '^\[dev\] context-menu-exec .* via=shortcut ' $be 3
        Start-Sleep -Milliseconds 400; Wait-Quiet
        Check 'menukeys' 'I-520·I-556' '루트 메뉴에서 Ctrl+Right → Expand All' 'exec item=Expand All, src\util 펼침' ("{0} / {1}" -f $e, ((Get-Tree).expanded -join ';')) ($e -match 'item=Expand All via=shortcut' -and ((Get-Tree).expanded -contains 'src\util'))
        # ⑦ Delete → Trash 항목 → 확인창(취소). 먼저 전체 접기(행이 화면 안에 오게).
        Send-Keys 'ctrl-left'
        $f = Delete-Flow 'menukeys' { Click-Row 'notes.txt' -How 'right'; Wait-Quiet; Send-Keys 'delete' } 'esc'
        Check 'menukeys' 'I-520·I-552' '메뉴에서 Delete → Trash 실행 → 확인창' 'exec item=Trash, trash `notes.txt`' ("{0} / {1}" -f (Last-Line '^\[dev\] context-menu-exec '), $f.open) ((Last-Line '^\[dev\] context-menu-exec ') -match 'item=Trash via=shortcut' -and $f.open -match [regex]::Escape('Do you want to trash `notes.txt`?'))
        [void](Save-Window 'menukeys-end')
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

#Requires -Version 7
<#
.SYNOPSIS
  v0.2 Phase 2 (SPEC R-5~R-9, Phase 1 에서 이월한 R-4 화면 판정) 증거: ☰ 앱 메뉴, 툴팁, 단축키 표시.

.DESCRIPTION
  앱을 `--dev-keymap --dev-layout` 으로 사례마다 새로 띄운다. 앱 표준출력에서 쓰는 줄:
    [dev] display seq= where= action= text=        키맵 적용 결과(I-704, 자리별)
    [dev] layout-snapshot / layout-box name= bounds= 레이아웃 경계(창 기준 논리 px)
    [dev] tooltip-shown id= t_ms= mouse= rows=     툴팁이 뜬 시각(유닉스 ms)·마우스 위치·줄(제목|단축키)
    [dev] tooltip-hidden id= t_ms=
    [dev] menu-open / menu-render rows= / menu-selected / menu-close reason= / menu-shortcut / menu-exec
    [dev] key / action-handled

  안전 규칙(Phase 1 D-028·D-029 와 같다):
    - 시작 전에 workbench-gpui 가 이미 실행 중이면 오류로 끝낸다. 띄운 프로세스(PID)만 닫는다.
    - 키·마우스를 보내기 직전마다 고정한 창이 전면인지, 마우스 위치 아래 최상위 창이 그 창인지 확인한다. 아니면 보내지 않는다.
    - %APPDATA%\workbench-gpui\keymap.json 은 시작 때 백업하고, 끝날 때 가장 먼저 독립된 try/finally 로 되돌린다.
      실행 전후 SHA-256 을 results.json 의 userKeymap 에 남긴다. 정리 예외는 errors 에 모은다.

  사례:
    tooltip  R-6·R-7·R-5: 요소마다 마우스를 올려 지연·위치·상자 치수·문구·단축키, 뒤집기(오른쪽·아래), 사라짐(벗어남·누름·스크롤),
             툴팁 없는 요소(창 버튼·사이드바 폴더 줄), Dock 상태에 따른 프로젝트 패널 토글 문구.
    menu     R-8·R-9·R-5: ☰ 클릭·hover 전환·Left/Right 순환·F10 열고 닫기·목록 키·Enter 실행·포커스 복원·
             단축키 실행 50ms(I-520)·메뉴 밖 누름·Window > Zoom/Minimize, 메뉴 상자·항목·구분선 치수, 메뉴 열린 동안 툴팁 없음.
    reload   R-4 이월: keymap.json 을 바꿔 저장하면 ☰ 메뉴와 툴팁의 단축키가 바뀐다.
    quit     Quit workbench-gpui(메뉴 Enter) → 프로세스 끝남.
    closewin Ctrl-Shift-W(Close Window) → 프로세스 끝남.

  결과: specs/v0.2/verify/phase2/ 의 <사례>-stdout.txt, 스크린샷, r5-shortcuts.md(화면 단축키 / 키맵 적용 결과 대조표), results.json.

.EXAMPLE
  pwsh -NoProfile -File tools/verify-v02-phase2.ps1
#>
[CmdletBinding()]
param(
    [string]$Exe = 'target\debug\workbench-gpui.exe',
    [string]$OutDir = 'specs\v0.2\verify\phase2',
    [string[]]$Only = @()
)

$ErrorActionPreference = 'Stop'
$ProcessName = 'workbench-gpui'
$AppTitle = 'workbench-gpui'
$CaptureScript = 'D:\projects\workbench-gpui\tools\capture.ps1'

if (-not ('WgP2.Native' -as [type])) {
    Add-Type -ReferencedAssemblies @('System.Runtime', 'System.Collections', 'System.Threading', 'System.Threading.Thread', 'System.Runtime.InteropServices') -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

namespace WgP2
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
    f10 = 0x79
}
foreach ($c in [char[]]'abcdefghijklmnopqrstuvwxyz') { $VK["$c"] = [int][char]::ToUpper($c) }

$out = [System.IO.Path]::GetFullPath($OutDir, (Get-Location).Path)
if (-not (Test-Path -LiteralPath $out)) { New-Item -ItemType Directory -Path $out -Force | Out-Null }
$keymapPath = Join-Path $env:APPDATA 'workbench-gpui\keymap.json'
$backupPath = Join-Path ([System.IO.Path]::GetTempPath()) ("wg-keymap-backup-{0}.json" -f [guid]::NewGuid())
$hadKeymap = Test-Path -LiteralPath $keymapPath
$userHashBefore = if ($hadKeymap) { (Get-FileHash -LiteralPath $keymapPath -Algorithm SHA256).Hash } else { '<absent>' }
# Phase 3 뒤(D-035): workspace::Open(Ctrl-K Ctrl-O)이 실제 폴더 선택 창을 연다. 이 시험은 키 디스패치만 보므로 선택 창 대신
# `--dev-pick-folder` 로 늘 취소를 주입한다(선택 창에 키가 가거나 폴더가 등록되지 않게). state.json 은 바뀌지 않아야 한다.
# 리뷰 1회차 ④(Phase 3, D-037)와 같은 규칙: 사용자 파일을 바꾸기 전에 기존 앱 실행을 검사하고 즉시 멈춘다(Start-App 의 재검사도 둔다).
if (@(Get-Process -Name 'workbench-gpui' -ErrorAction SilentlyContinue).Count -gt 0) { throw "이미 실행 중인 workbench-gpui 가 있다. 사용자 파일을 바꾸기 전에 중단한다" }
$pickCancel = Join-Path ([System.IO.Path]::GetTempPath()) ("wg-pick-cancel-{0}.txt" -f [guid]::NewGuid())
[System.IO.File]::WriteAllText($pickCancel, '<cancel>', [System.Text.UTF8Encoding]::new($false))
$statePathGuard = Join-Path $env:APPDATA 'workbench-gpui\state.json'
$stateHashBefore = if (Test-Path -LiteralPath $statePathGuard) { (Get-FileHash -LiteralPath $statePathGuard -Algorithm SHA256).Hash } else { '<absent>' }

$results = [ordered]@{ startedAt = (Get-Date).ToString('o'); keymapPath = $keymapPath; cases = [ordered]@{}; failures = @(); errors = @(); checks = @(); shortcutRows = @() }

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
    if ([WgP2.Native]::GetForegroundWindow() -ne $script:hwnd) {
        [WgP2.Native]::Activate($script:hwnd)
        Start-Sleep -Milliseconds 300
    }
    if ([WgP2.Native]::GetForegroundWindow() -ne $script:hwnd) { throw "${What}: 대상 창이 전면이 아니다. 입력을 보내지 않고 중단한다" }
}
function Assert-Target([int]$X, [int]$Y, [string]$What) {
    Assert-Foreground $What
    if ([WgP2.Native]::RootAt($X, $Y) -ne $script:hwnd) { throw ("{0}: ({1},{2}) 아래 창이 대상 창이 아니다. 입력을 보내지 않고 중단한다" -f $What, $X, $Y) }
}

function ToScreen([double]$x, [double]$y) {
    @([int][math]::Round($script:client.x + $x * $script:scale), [int][math]::Round($script:client.y + $y * $script:scale))
}
function Center($b) { ToScreen ($b.x + $b.w / 2) ($b.y + $b.h / 2) }

function Move-To([double]$x, [double]$y, [string]$What) {
    $p = ToScreen $x $y
    Assert-Target $p[0] $p[1] $What
    [WgP2.Native]::MoveTo($p[0], $p[1])
}
function Click-At([double]$x, [double]$y, [string]$What) {
    $p = ToScreen $x $y
    Assert-Target $p[0] $p[1] $What
    [WgP2.Native]::Click($p[0], $p[1])
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
    [WgP2.Native]::Batch($vks.ToArray(), $ups.ToArray())
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
        [WgP2.Native]::Combo([uint16[]]$mods, [uint16]$VK[$key])
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

function Write-Keymap([string]$Text) {
    $dir = Split-Path -Parent $keymapPath
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($keymapPath, $Text, [System.Text.UTF8Encoding]::new($false))
}
function Remove-Keymap { if (Test-Path -LiteralPath $keymapPath) { Remove-Item -LiteralPath $keymapPath -Force } }

function Start-App([string]$Case) {
    $existing = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
    if ($existing.Count -gt 0) { throw "이미 실행 중인 $ProcessName 가 있다 (PID $($existing.Id -join ', ')). 닫고 다시 실행하라" }
    $script:stdout = Join-Path $out "$Case-stdout.txt"
    if (Test-Path -LiteralPath $script:stdout) { Remove-Item -LiteralPath $script:stdout -Force }
    $exePath = (Resolve-Path -LiteralPath $Exe).Path
    $p = Start-Process -FilePath $exePath -ArgumentList @('--dev-keymap', '--dev-layout', '--dev-pick-folder', $pickCancel) -RedirectStandardOutput $script:stdout -PassThru
    $script:launched = $p
    $script:appPid = $p.Id
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt 20 -and (Count-Lines '^\[dev\] display-end seq=1') -eq 0) { Start-Sleep -Milliseconds 100 }
    if ((Count-Lines '^\[dev\] display-end seq=1') -eq 0) { throw "${Case}: 20초 안에 display-end seq=1 이 나오지 않았다" }
    $sw.Restart()
    do {
        $script:hwnd = [WgP2.Native]::FindTitled([uint32]$p.Id, $AppTitle)
        if ($script:hwnd -ne [IntPtr]::Zero) { break }
        Start-Sleep -Milliseconds 200
    } while ($sw.Elapsed.TotalSeconds -lt 10)
    if ($script:hwnd -eq [IntPtr]::Zero) { throw "${Case}: 앱 메인 창을 찾지 못했다" }
    # 기본 창(1440×900 논리 px)은 200% 배율에서 작업 영역보다 커 아래쪽이 작업 표시줄에 가린다. 띄운 창(고정한 HWND)만
    # 최대화해 모든 요소가 작업 영역 안에 오게 한다.
    [void][WgP2.Native]::ShowWindow($script:hwnd, 3)
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

function Run-Case([string]$Case, [string]$Keymap, [scriptblock]$Body) {
    if (-not (Wants $Case)) { return }
    $res = [ordered]@{}
    if ([string]::IsNullOrEmpty($Keymap)) { Remove-Keymap } else { Write-Keymap $Keymap }
    $script:launched = $null
    try {
        $p = Start-App $Case
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

# 키맵 적용 결과(앱의 [dev] display 줄). seq 는 최신, 자리는 center.
function Get-Display([string]$Action, [string]$Where = 'center') {
    $l = @(Get-Lines ("^\[dev\] display seq=\d+ where={0} action={1} text=" -f $Where, [regex]::Escape($Action)))
    if ($l.Count -eq 0) { return '<missing>' }
    [void]($l[-1] -match ' text=(.*)$'); return $Matches[1]
}

# 화면 단축키 / 키맵 적용 결과 / 01-zed 원문 대조 한 줄을 남긴다(R-5).
function Add-ShortcutRow([string]$Case, [string]$Where, [string]$Label, [string]$Action, [string]$Shown, [string]$Original, [string]$Evidence) {
    $computed = if ($Action) { Get-Display $Action } else { '<none>' }
    if ($computed -eq '<missing>') { $computed = '<none>' }
    $ok = ($Shown -ceq $computed)
    $script:results.shortcutRows += [ordered]@{ case = $Case; where = $Where; label = $Label; action = $Action; shown = $Shown; computed = $computed; original = $Original; ok = $ok; evidence = $Evidence }
    if (-not $ok) { Fail $Case "R-5 $Where '$Label': 화면 $Shown, 키맵 적용 결과 $computed" }
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

# 툴팁 상자 위치 판정(L-208~L-210). 뒤집지 않으면 (mouse+1)+(8,10), 뒤집으면 mouse − 상자 − 1.
function Check-TooltipPlacement([string]$Case, $t, [string]$ExpectX = 'normal', [string]$ExpectY = 'normal') {
    $b = $t.box
    if (-not $b) { Check $Case 'L-208' "$($t.id) 툴팁 상자 경계" 'tooltip-box' '<없음>' $false; return }
    $ex = if ($ExpectX -eq 'flip') { $t.mouseX - $b.w - 1 } else { $t.mouseX + 1 + 8 }
    $ey = if ($ExpectY -eq 'flip') { $t.mouseY - $b.h - 1 } else { $t.mouseY + 1 + 10 }
    Check $Case $(if ($ExpectX -eq 'flip') { 'L-210' } else { 'L-208·L-209' }) "$($t.id) 상자 x (마우스 $($t.mouseX))" ('{0:N2}' -f $ex) ('{0:N2}' -f $b.x) (Near $b.x $ex) $t.line
    Check $Case $(if ($ExpectY -eq 'flip') { 'L-210' } else { 'L-208·L-209' }) "$($t.id) 상자 y (마우스 $($t.mouseY))" ('{0:N2}' -f $ey) ('{0:N2}' -f $b.y) (Near $b.y $ey) $t.line
}

# 물리 px 좌표로 다루려고 이 스레드를 PER_MONITOR_AWARE_V2 로 둔다(tools/verify-ime.ps1 과 같다).
$prevDpi = [WgP2.Native]::SetThreadDpiAwarenessContext([IntPtr]::new(-4))
$backupDone = $false
try {
    if ($hadKeymap) { Copy-Item -LiteralPath $keymapPath -Destination $backupPath -Force; $backupDone = $true }

    # ================================================================ tooltip: R-6·R-7·R-5
    Run-Case 'tooltip' $null {
        param($res, $p)
        # R-7 표(요소 → 문구, 단축키 액션, 01-zed 원문 키). 원문 키가 v0.2 에 없는 동작이면 화면에는 단축키가 없다(R-7 설명).
        $items = @(
            @{ id = 'app-menu-button'; rows = @(,@('Open Application Menu', '', '없음 (F10, 표시 안 함 L-225)')); ids = 'L-225' }
            @{ id = 'title-folder-name'; rows = @(,@('Recent Projects', 'projects::OpenRecent', 'Ctrl-R (v0.2 에 동작 없음)')); ids = 'L-226·L-227·D-16' }
            @{ id = 'sidebar-btn-folder-add'; rows = @(,@('Add Project', 'workspace::Open', 'Ctrl-K Ctrl-O (A-13.1)')); ids = 'L-230' }
            @{ id = 'sidebar-btn-toggle'; rows = @(@('Toggle Sidebar', 'multi_workspace::ToggleWorkspaceSidebar', 'Ctrl-Alt-J'), @('Focus Sidebar', 'multi_workspace::FocusWorkspaceSidebar', 'Ctrl-Alt-;')); ids = 'L-232' }
            @{ id = 'tab-btn-back'; rows = @(,@('Go Back', 'pane::GoBack', 'Alt-Left (v0.2 에 동작 없음)')); ids = 'L-236' }
            @{ id = 'tab-btn-forward'; rows = @(,@('Go Forward', 'pane::GoForward', 'Alt-Right (v0.2 에 동작 없음)')); ids = 'L-237' }
            @{ id = 'tab-btn-new'; rows = @(,@("New$([char]0x2026)", '', '없음')); ids = 'L-243' }
            @{ id = 'tab-btn-split'; rows = @(,@('Split Pane', '', '없음')); ids = 'L-244' }
            @{ id = 'tab-btn-zoom'; rows = @(,@('Zoom In', 'workspace::ToggleZoom', 'Shift-Escape (v0.2 에 동작 없음)')); ids = 'L-245'; flipX = $true }
            @{ id = 'status-btn-project-panel'; rows = @(,@('Close Left Dock', 'workspace::ToggleLeftDock', 'Ctrl-B')); ids = 'L-254·L-266'; flipY = $true }
        )
        $res.tooltips = @()
        foreach ($it in $items) {
            $t = Measure-Tooltip 'tooltip' $it.id "r7-$($it.id)"
            if (-not $t) { Check 'tooltip' $it.ids "$($it.id) 툴팁" '뜬다' '안 뜸' $false; continue }
            $res.tooltips += $t
            # 문구·단축키(R-7, R-5).
            $shownRows = @($t.rows.Split("`t"))
            Check 'tooltip' $it.ids "$($it.id) 줄 수" $it.rows.Count $shownRows.Count ($shownRows.Count -eq $it.rows.Count) $t.line
            for ($i = 0; $i -lt [math]::Min($shownRows.Count, $it.rows.Count); $i++) {
                $title, $shortcut = $shownRows[$i].Split('|', 2)
                $exp = $it.rows[$i]
                Check 'tooltip' $it.ids "$($it.id) 문구" $exp[0] $title ($title -ceq $exp[0]) $t.line
                Add-ShortcutRow 'tooltip' "툴팁 $($it.id)" $exp[0] $exp[1] $shortcut $exp[2] "r7-$($it.id).png"
            }
            # 시점(L-206): 500ms 이상, 여유 250ms.
            Check 'tooltip' 'L-206' "$($it.id) 지연 ms" '500~750' $t.delayMs ($t.delayMs -ge 480 -and $t.delayMs -le 750) $t.line
            # 위치(L-208~L-210): 창을 넘는지는 툴팁 바깥 상자(보이는 상자 + 투명 여백 8·10)로 계산한다.
            $vp = Get-Viewport
            $fx = $t.box -and (($t.mouseX + 1 + 8 + $t.box.w) -gt $vp.w)
            $fy = $t.box -and (($t.mouseY + 1 + 10 + $t.box.h) -gt $vp.h)
            $t | Add-Member -NotePropertyName flipX -NotePropertyValue $fx
            $t | Add-Member -NotePropertyName flipY -NotePropertyValue $fy
            Check-TooltipPlacement 'tooltip' $t $(if ($fx) { 'flip' } else { 'normal' }) $(if ($fy) { 'flip' } else { 'normal' })
        }
        # 뒤집기(L-210)가 오른쪽·아래 모두 실제로 일어났는가.
        $flippedX = @($res.tooltips | Where-Object { $_.flipX } | ForEach-Object { $_.id })
        $flippedY = @($res.tooltips | Where-Object { $_.flipY } | ForEach-Object { $_.id })
        Check 'tooltip' 'L-210' '오른쪽 끝에서 왼쪽으로 뒤집은 툴팁' '1개 이상' ($flippedX -join ',') ($flippedX.Count -gt 0)
        Check 'tooltip' 'L-210' '아래 끝에서 위로 뒤집은 툴팁' '1개 이상' ($flippedY -join ',') ($flippedY.Count -gt 0)

        # 상자 치수(L-213·L-214): 한 줄 툴팁 높이 = 위아래 여백 4+4 + 글자 줄 + 테두리 2. 글자 줄 높이는 gpui 기본 줄 높이라
        # 원문에 값이 없어, 같은 상자의 내용 높이에서 여백·테두리를 빼 남은 값을 기록만 한다.
        $one = $res.tooltips | Where-Object { $_.id -eq 'tab-btn-split' } | Select-Object -First 1
        if ($one -and $one.box) { $res.splitTooltipBox = $one.box }

        # 사라짐(L-207): 벗어남 / 누름 / 스크롤. 판정은 레이아웃 스냅숏에서 툴팁 상자가 없어지는 것으로 한다
        # (스냅숏은 마지막으로 그린 프레임의 요소만 낸다, layout_probe.rs).
        foreach ($how in 'leave', 'press', 'scroll') {
            $t = Measure-Tooltip 'tooltip' 'tab-btn-split' $null
            $hadBox = $null -ne (Get-Box 'tooltip-box')
            $b = Need-Box 'tab-btn-split'
            switch ($how) {
                'leave' { $n = Need-Box 'active-item'; Move-To ($n.x + $n.w / 2) ($n.y + $n.h / 2) 'leave' }
                'press' { Click-At ($b.x + $b.w / 2) ($b.y + $b.h / 2) 'press' }
                'scroll' { $sp = Center $b; Assert-Target $sp[0] $sp[1] 'wheel'; [WgP2.Native]::Wheel($sp[0], $sp[1], -120) }
            }
            $gone = Wait-NoBox 'tooltip-box' 2
            Check 'tooltip' 'L-207' "$how 하면 사라짐 (앞서 상자 있음: $hadBox)" '사라짐' $(if ($gone) { '사라짐' } else { '<남음>' }) ($hadBox -and $gone)
        }

        # 툴팁 없는 요소(L-228 창 버튼, L-231 사이드바 폴더 줄): 1.5초 올려 두어도 tooltip-shown 이 없다.
        # 사이드바 폴더 줄(A-12.8)은 Phase 3 에서 자리 표시 줄을 실제 목록으로 바꿨다. 폴더 줄 툴팁 없음은 Phase 3 items 사례가 판정한다.
        foreach ($nid in 'window-btn-min', 'window-btn-close') {
            $n = Need-Box 'active-item'; Move-To ($n.x + $n.w / 2) ($n.y + $n.h / 2) 'neutral'
            Start-Sleep -Milliseconds 400
            $b = Need-Box $nid
            $before = Count-Lines '^\[dev\] tooltip-shown '
            Move-To ($b.x + $b.w / 2) ($b.y + $b.h / 2) "hover $nid"
            Start-Sleep -Milliseconds 1500
            $cnt = (Count-Lines '^\[dev\] tooltip-shown ') - $before
            Check 'tooltip' $(if ($nid -like 'window-*') { 'L-228' } else { 'L-231' }) "$nid 툴팁 없음" 0 $cnt ($cnt -eq 0)
        }

        # Dock 을 닫으면 프로젝트 패널 토글 문구가 바뀐다(L-253·L-266).
        $n = Need-Box 'active-item'; Move-To ($n.x + $n.w / 2) ($n.y + $n.h / 2) 'neutral'
        Send-Keys 'ctrl-b'
        Start-Sleep -Milliseconds 500
        $t = Measure-Tooltip 'tooltip' 'status-btn-project-panel' 'r7-status-btn-project-panel-closed'
        if ($t) {
            $title, $shortcut = $t.rows.Split('|', 2)
            Check 'tooltip' 'L-253·L-266' 'Dock 닫힘 문구' 'Project Panel' $title ($title -ceq 'Project Panel') $t.line
            Add-ShortcutRow 'tooltip' '툴팁 status-btn-project-panel (Dock 닫힘)' 'Project Panel' 'project_panel::ToggleFocus' $shortcut 'Ctrl-Shift-E' 'r7-status-btn-project-panel-closed.png'
        }
        else { Check 'tooltip' 'L-253' 'Dock 닫힘 툴팁' '뜬다' '안 뜸' $false }
    }

    # ================================================================ menu: R-8·R-9·R-5
    Run-Case 'menu' $null {
        param($res, $p)
        $orig = @{ 'Open Folder...' = @('workspace::Open', 'Ctrl+K Ctrl+O'); 'Toggle Folder Sidebar' = @('multi_workspace::ToggleWorkspaceSidebar', 'Ctrl+Alt+J'); 'Focus Folder Sidebar' = @('multi_workspace::FocusWorkspaceSidebar', 'Ctrl+Alt+;'); 'Quit workbench-gpui' = @('zed::Quit', 'Ctrl+Q'); 'Close Window' = @('workspace::CloseWindow', 'Ctrl+Shift+W'); 'Toggle Left Dock' = @('workspace::ToggleLeftDock', 'Ctrl+B'); 'Project Panel' = @('project_panel::ToggleFocus', 'Ctrl+Shift+E'); 'Minimize' = @('zed::Minimize', '없음'); 'Zoom' = @('zed::Zoom', '없음 (F11 은 다른 액션)') }
        $expectRows = @{
            0 = 'Quit workbench-gpui|Ctrl-Q'
            1 = "Open Folder...|Ctrl-K Ctrl-O`t---`tClose Editor|Ctrl-F4`tClose Window|Ctrl-Shift-W"
            2 = "Toggle Left Dock|Ctrl-B`tToggle Folder Sidebar|Ctrl-Alt-J`tFocus Folder Sidebar|Ctrl-Alt-;`t---`tProject Panel|Ctrl-Shift-E"
            3 = "Minimize|<none>`tZoom|<none>"
        }
        $names = @('workbench-gpui', 'File', 'View', 'Window')
        [void](Save-Window 'r8-closed')

        # ☰ 클릭 → 첫 메뉴(I-302).
        $b = Need-Box 'app-menu-button'
        $before = Count-Lines '^\[dev\] menu-open '
        Click-At ($b.x + $b.w / 2) ($b.y + $b.h / 2) 'click ☰'
        $l = Wait-NewLine '^\[dev\] menu-open ' $before 3
        Check 'menu' 'I-302' '☰ 클릭 → 첫 메뉴' 'index=0' $(if ($l) { ($l -replace '.*(index=\d+).*', '$1') } else { '<없음>' }) ($l -match 'index=0 ') $l

        $rendered = @{}
        function Read-Render([int]$Index) {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            while ($sw.Elapsed.TotalSeconds -lt 3) {
                $r = @(Get-Lines ("^\[dev\] menu-render index={0} " -f $Index))
                if ($r.Count -gt 0) { [void]($r[-1] -match ' rows=(.*)$'); return $Matches[1] }
                Start-Sleep -Milliseconds 100
            }
            return $null
        }

        # 메뉴마다 항목·단축키(R-8 구조, R-5) — hover 전환(I-303)으로 차례로 연다.
        for ($i = 0; $i -lt 4; $i++) {
            if ($i -gt 0) {
                $nb = Need-Box ("menu-name-{0}" -f $i)
                $before = Count-Lines '^\[dev\] menu-open '
                Move-To ($nb.x + $nb.w / 2) ($nb.y + $nb.h / 2) "hover menu $i"
                $l = Wait-NewLine '^\[dev\] menu-open ' $before 3
                Check 'menu' 'I-303' "이름 hover → 메뉴 $i" "index=$i" $(if ($l) { ($l -replace '.*(index=\d+).*', '$1') } else { '<없음>' }) ($l -match "index=$i ") $l
            }
            $rows = Read-Render $i
            Check 'menu' 'R-8 D-13 I-306' "$($names[$i]) 항목·구분선" $expectRows[$i] $rows ($rows -ceq $expectRows[$i])
            if ($rows) {
                foreach ($row in $rows.Split("`t")) {
                    if ($row -eq '---') { continue }
                    $label, $shortcut = $row.Split('|', 2)
                    Add-ShortcutRow 'menu' "메뉴 $($names[$i])" $label $orig[$label][0] $shortcut $orig[$label][1] "r8-menu-$i.png"
                }
            }
            Start-Sleep -Milliseconds 400
            [void](Save-Window "r8-menu-$i")
            # 메뉴가 열린 동안 메뉴 이름 위에 툴팁 없음(L-205).
            $tt = Count-Lines '^\[dev\] tooltip-shown '
        }
        $names0 = @(0..3 | ForEach-Object { Get-Box ("menu-name-{0}" -f $_) })
        $res.menuNames = $names0
        $res.menuBar = (Get-Box 'app-menu')
        Check 'menu' 'I-321' '메뉴 이름 버튼 사이 gap' 4 ('{0:N2}' -f ($names0[1].x - ($names0[0].x + $names0[0].w))) (Near ($names0[1].x - ($names0[0].x + $names0[0].w)) 4)

        # View 를 열어 치수를 잰다(R-9, I-313~I-318).
        $nb = Need-Box 'menu-name-2'; Move-To ($nb.x + $nb.w / 2) ($nb.y + $nb.h / 2) 'hover View'
        Start-Sleep -Milliseconds 700
        $box = Wait-Box 'menu-box' 3
        # Phase 3 뒤 View: 0 Toggle Left Dock, 1 Toggle Folder Sidebar, 2 Focus Folder Sidebar, 3 구분선, 4 Project Panel.
        $rf = Need-Box 'menu-row-00'; $r0 = Need-Box 'menu-row-02'; $r1 = Need-Box 'menu-row-03'; $r2 = Need-Box 'menu-row-04'
        $res.viewBox = $box; $res.viewRows = @($rf, $r0, $r1, $r2)
        if ($box -and $r0 -and $r1 -and $r2) {
            Check 'menu' 'I-313' '최소 바깥 폭(200 + 테두리 2)' '>= 202' ('{0:N2}' -f $box.w) ($box.w -ge 201) 'menu-box'
            Check 'menu' 'I-314' '팝업 x = 이름 버튼 왼쪽 − 5' ('{0:N2}' -f ($nb.x - 5)) ('{0:N2}' -f $box.x) (Near $box.x ($nb.x - 5)) 'menu-box, menu-name-2'
            Check 'menu' 'I-314' '팝업 y = 이름 버튼 아래' ('{0:N2}' -f ($nb.y + $nb.h)) ('{0:N2}' -f $box.y) (Near $box.y ($nb.y + $nb.h)) 'menu-box, menu-name-2'
            Check 'menu' 'I-315' '목록 위 여백 4 (테두리 1 안)' 5 ('{0:N2}' -f ($rf.y - $box.y)) (Near ($rf.y - $box.y) 5) 'menu-row-00'
            Check 'menu' 'I-315' '목록 아래 여백 4 (테두리 1 안)' 5 ('{0:N2}' -f (($box.y + $box.h) - ($r2.y + $r2.h))) (Near (($box.y + $box.h) - ($r2.y + $r2.h)) 5) 'menu-row-04'
            Check 'menu' 'I-316' '항목 바깥 좌우 4 (테두리 1 안)' 5 ('{0:N2}' -f ($rf.x - $box.x)) (Near ($rf.x - $box.x) 5) 'menu-row-00'
            Check 'menu' 'I-317' '항목 줄 높이 14 × 1.618' '22.65' ('{0:N2}' -f $rf.h) (Near $rf.h 22.652) 'menu-row-00'
            Check 'menu' 'I-318' '구분선 높이 1' 1 ('{0:N2}' -f $r1.h) (Near $r1.h 1 0.5) 'menu-row-03'
            Check 'menu' 'I-318' '구분선 위 margin 6' 6 ('{0:N2}' -f ($r1.y - ($r0.y + $r0.h))) (Near ($r1.y - ($r0.y + $r0.h)) 6) 'menu-row-02·03'
            Check 'menu' 'I-318' '구분선 아래 margin 6' 6 ('{0:N2}' -f ($r2.y - ($r1.y + $r1.h))) (Near ($r2.y - ($r1.y + $r1.h)) 6) 'menu-row-03·04'
        }
        else { Check 'menu' 'R-9' 'View 메뉴 경계' 'menu-box·row' '<없음>' $false }

        # Left/Right 순환(I-303, I-310): View(2) → Right → Window(3) → Right → 0, Left → 3.
        foreach ($step in @(@('right', 3), @('right', 0), @('left', 3), @('left', 2))) {
            $before = Count-Lines '^\[dev\] menu-open '
            Send-Keys $step[0]
            $l = Wait-NewLine '^\[dev\] menu-open ' $before 2
            Check 'menu' 'I-303' "$($step[0]) → 메뉴 $($step[1])" "index=$($step[1])" $(if ($l) { ($l -replace '.*(index=\d+).*', '$1') } else { '<없음>' }) ($l -match "index=$($step[1]) ") $l
        }

        # 목록 키(I-517·I-518). View(Phase 3 뒤): 항목 0·1·2, 구분선 3, 항목 4.
        foreach ($k in @(@('down', 0), @('down', 1), @('down', 2), @('down', 4), @('down', 0), @('up', 4), @('up', 2), @('end', 4), @('home', 0), @('tab', 1), @('shift-tab', 0), @('ctrl-n', 1), @('ctrl-p', 0), @('pagedown', 4), @('pageup', 0), @('shift-pagedown', 4), @('shift-pageup', 0))) {
            $before = Count-Lines '^\[dev\] menu-selected '
            Send-Keys $k[0]
            $l = Wait-NewLine '^\[dev\] menu-selected ' $before 2
            Check 'menu' 'I-517·I-518' "$($k[0]) → 항목 $($k[1])" "index=$($k[1])" $(if ($l) { ($l -replace '.*(index=\S+).*', '$1') } else { '<없음>' }) ($l -match "index=$($k[1])$") $l
        }

        # 마우스가 메뉴 이름 위에 남아 있으면 메뉴 바가 다시 나타날 때 hover 로 그 메뉴가 열린다(I-303). 키 시험 전에 비켜 둔다.
        Park-Mouse
        # Escape 닫기 + 포커스 복원(I-519, I-309): 닫은 뒤 키 컨텍스트가 메뉴 없이 Workspace.
        $before = Count-Lines '^\[dev\] menu-close '
        Send-Keys 'escape'
        $l = Wait-NewLine '^\[dev\] menu-close ' $before 2
        Check 'menu' 'I-519' 'Escape 닫기' 'reason=cancel' $l ($l -match 'reason=cancel') $l
        $before = Count-Lines '^\[dev\] key keystroke=ctrl-c '
        Send-Keys 'ctrl-c'
        $l = Wait-NewLine '^\[dev\] key keystroke=ctrl-c ' $before 2
        Check 'menu' 'I-309' '닫은 뒤 포커스 복원(컨텍스트)' 'Root > Workspace' $l ($l -match 'context=Root > Workspace$') $l

        # Ctrl-C 닫기(I-517).
        Send-Keys 'f10'; Start-Sleep -Milliseconds 400
        $before = Count-Lines '^\[dev\] menu-close '
        Send-Keys 'ctrl-c'
        $l = Wait-NewLine '^\[dev\] menu-close ' $before 2
        Check 'menu' 'I-517' 'Ctrl-C 닫기' 'reason=cancel' $l ($l -match 'reason=cancel') $l

        # F10 열기 / 열린 채 F10 닫기(I-310).
        $before = Count-Lines '^\[dev\] menu-open '
        Send-Keys 'f10'
        $l = Wait-NewLine '^\[dev\] menu-open ' $before 2
        Check 'menu' 'I-310' 'F10 열기' 'index=0' $l ($l -match 'index=0 ') $l
        $before = Count-Lines '^\[dev\] menu-close '
        Send-Keys 'f10'
        $l = Wait-NewLine '^\[dev\] menu-close ' $before 2
        Check 'menu' 'I-310' '열린 채 F10 닫기' 'reason=toggle' $l ($l -match 'reason=toggle') $l

        # Enter 실행(포커스 복원 뒤 실행, I-309): View > Toggle Left Dock.
        Send-Keys 'f10'; Start-Sleep -Milliseconds 300; Send-Keys 'left'; Send-Keys 'left'; Send-Keys 'down'
        $before = Count-Lines '^\[dev\] action-handled name=workspace::ToggleLeftDock '
        $bx = Count-Lines '^\[dev\] menu-exec '
        Send-Keys 'enter'
        $l = Wait-NewLine '^\[dev\] menu-exec ' $bx 2
        Check 'menu' 'R-8' 'Enter 실행' 'action=workspace::ToggleLeftDock via=enter' $l ($l -match 'action=workspace::ToggleLeftDock via=enter') $l
        $h = Wait-NewLine '^\[dev\] action-handled name=workspace::ToggleLeftDock ' $before 2
        Check 'menu' 'I-309' '실행 때 원래 포커스(center)' 'focus=center' $h ($h -match 'by=workbench focus=center') $h
        Send-Keys 'ctrl-b'; Start-Sleep -Milliseconds 300

        # 단축키 실행(I-520): View 를 연 채 Ctrl-B → 선택 표시 후 50ms 뒤 실행.
        Send-Keys 'f10'; Start-Sleep -Milliseconds 300; Send-Keys 'left'; Send-Keys 'left'; Start-Sleep -Milliseconds 300
        $bs = Count-Lines '^\[dev\] menu-shortcut '; $bx = Count-Lines '^\[dev\] menu-exec '
        Send-Keys 'ctrl-b'
        $s = Wait-NewLine '^\[dev\] menu-shortcut ' $bs 2
        $x = Wait-NewLine '^\[dev\] menu-exec ' $bx 2
        if ($s -and $x) {
            [void]($s -match 't_ms=(\d+)'); $ts = [int64]$Matches[1]
            [void]($x -match 't_ms=(\d+)'); $tx = [int64]$Matches[1]
            Check 'menu' 'I-520' '단축키 → 선택 표시 뒤 실행까지 ms' '50~120' ($tx - $ts) (($tx - $ts) -ge 45 -and ($tx - $ts) -le 120) "$s / $x"
            Check 'menu' 'I-520' '단축키 실행 경로' 'via=shortcut' $x ($x -match 'action=workspace::ToggleLeftDock via=shortcut') $x
        }
        else { Check 'menu' 'I-520' '단축키 실행' 'menu-shortcut + menu-exec' "$s / $x" $false }
        Send-Keys 'ctrl-b'; Start-Sleep -Milliseconds 300

        # 메뉴 밖 누름 닫기(I-519).
        Send-Keys 'f10'; Start-Sleep -Milliseconds 400
        $before = Count-Lines '^\[dev\] menu-close '
        $n = Need-Box 'active-item'; Click-At ($n.x + $n.w / 2) ($n.y + $n.h / 2) 'click outside'
        $l = Wait-NewLine '^\[dev\] menu-close ' $before 2
        Check 'menu' 'I-519' '메뉴 밖 누름 닫기' 'reason=click-outside' $l ($l -match 'reason=click-outside') $l

        # 항목 클릭 실행 + Window > Zoom(I-446 창 확대). gpui-pre-windows `zoom` 은 SW_MAXIMIZE 만 한다(토글이 아니다,
        # gpui-pre-windows 0.3.10 window.rs 947~950행). 그래서 띄운 창을 먼저 복원(SW_RESTORE)해 두고 Zoom 뒤 최대화되는지 본다.
        [void][WgP2.Native]::ShowWindow($script:hwnd, 9)
        Start-Sleep -Milliseconds 800
        $cap = Save-Window 'r8-before-zoom'; $script:client = $cap.clientRect; $script:scale = [double]$cap.scale
        $wasZoomed = [WgP2.Native]::IsZoomed($script:hwnd)
        Start-Sleep -Milliseconds 400
        $b = Need-Box 'app-menu-button'; Click-At ($b.x + $b.w / 2) ($b.y + $b.h / 2) 'click ☰'; Start-Sleep -Milliseconds 400
        $nb = Need-Box 'menu-name-3'; Move-To ($nb.x + $nb.w / 2) ($nb.y + $nb.h / 2) 'hover Window'; Start-Sleep -Milliseconds 600
        $z = Need-Box 'menu-row-01' 2
        $bx = Count-Lines '^\[dev\] menu-exec '
        Click-At ($z.x + $z.w / 2) ($z.y + $z.h / 2) 'click Zoom'
        $l = Wait-NewLine '^\[dev\] menu-exec ' $bx 2
        Start-Sleep -Milliseconds 800
        $nowZoomed = [WgP2.Native]::IsZoomed($script:hwnd)
        Check 'menu' 'I-446' "Window > Zoom 클릭 → 최대화 (전: $wasZoomed)" 'True' "$nowZoomed" ((-not $wasZoomed) -and $nowZoomed -and $l -match 'action=zed::Zoom via=click') $l
        $cap = Save-Window 'r8-after-zoom'; $script:client = $cap.clientRect; $script:scale = [double]$cap.scale

        # Window > Minimize: 실행 뒤 창이 최소화. 확인 뒤 스크립트가 되돌린다(SW_RESTORE).
        Send-Keys 'f10'; Start-Sleep -Milliseconds 300; Send-Keys 'left'; Send-Keys 'down'
        $bx = Count-Lines '^\[dev\] menu-exec '
        Send-Keys 'enter'
        $l = Wait-NewLine '^\[dev\] menu-exec ' $bx 2
        Start-Sleep -Milliseconds 800
        Check 'menu' 'I-445' 'Window > Minimize → 최소화' 'True' "$([WgP2.Native]::IsIconic($script:hwnd))" ([WgP2.Native]::IsIconic($script:hwnd) -and $l -match 'action=zed::Minimize') $l
        [void][WgP2.Native]::ShowWindow($script:hwnd, 9)
        Start-Sleep -Milliseconds 800

        # 메뉴가 열려 있는 동안 메뉴 이름에 툴팁이 뜨지 않았다(L-205).
        $menuTooltips = @(Get-Lines '^\[dev\] tooltip-shown id=app-menu-button')
        $res.appMenuButtonTooltips = $menuTooltips.Count
    }

    # ================================================================ reload: R-4 이월(메뉴·툴팁 화면)
    Run-Case 'reload' '[]' {
        param($res, $p)
        Park-Mouse
        Send-Keys 'f10'; Start-Sleep -Milliseconds 300; Send-Keys 'left'; Send-Keys 'left'; Start-Sleep -Milliseconds 600
        $r = @(Get-Lines '^\[dev\] menu-render index=2 ')[-1]
        Check 'reload' 'R-4' '바꾸기 전 메뉴 View 단축키' 'Toggle Left Dock|Ctrl-B' $r ($r -match 'rows=Toggle Left Dock\|Ctrl-B\t') $r
        [void](Save-Window 'r4-menu-before')
        Send-Keys 'escape'; Start-Sleep -Milliseconds 300
        $t = Measure-Tooltip 'reload' 'status-btn-project-panel' 'r4-tooltip-before'
        Check 'reload' 'R-4' '바꾸기 전 툴팁' 'Close Left Dock|Ctrl-B' $t.rows ($t.rows -ceq 'Close Left Dock|Ctrl-B') $t.line

        $n = Need-Box 'active-item'; Move-To ($n.x + $n.w / 2) ($n.y + $n.h / 2) 'neutral'
        $text = @'
[
  { "context": "Workspace", "bindings": { "ctrl-b": null, "alt-b": "workspace::ToggleLeftDock" } }
]
'@
        Write-Keymap $text
        Set-Content -LiteralPath (Join-Path $out 'reload-keymap-2.json') -Value $text -Encoding utf8 -NoNewline
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        while ($sw.Elapsed.TotalSeconds -lt 10 -and (Count-Lines '^\[dev\] display-end seq=2') -eq 0) { Start-Sleep -Milliseconds 100 }
        Check 'reload' 'R-4' '저장 뒤 다시 읽기' 'display-end seq=2' "$((Count-Lines '^\[dev\] display-end seq=2'))" ((Count-Lines '^\[dev\] display-end seq=2') -gt 0)

        $before = Count-Lines '^\[dev\] menu-render index=2 '
        Send-Keys 'f10'; Start-Sleep -Milliseconds 300; Send-Keys 'left'; Send-Keys 'left'; Start-Sleep -Milliseconds 600
        $r = @(Get-Lines '^\[dev\] menu-render index=2 ')[-1]
        Check 'reload' 'R-4' '바꾼 뒤 메뉴 View 단축키' 'Toggle Left Dock|Alt-B' $r ($r -match 'rows=Toggle Left Dock\|Alt-B\t') $r
        if ($r -match ' rows=(.*)$') {
            foreach ($row in $Matches[1].Split("`t")) {
                if ($row -eq '---') { continue }
                $label, $shortcut = $row.Split('|', 2)
                $act = @{ 'Toggle Left Dock' = 'workspace::ToggleLeftDock'; 'Toggle Folder Sidebar' = 'multi_workspace::ToggleWorkspaceSidebar'; 'Focus Folder Sidebar' = 'multi_workspace::FocusWorkspaceSidebar'; 'Project Panel' = 'project_panel::ToggleFocus' }[$label]
                Add-ShortcutRow 'reload' '메뉴 View (keymap.json 바꾼 뒤)' $label $act $shortcut '사용자 keymap.json' 'r4-menu-after.png'
            }
        }
        [void](Save-Window 'r4-menu-after')
        Send-Keys 'escape'; Start-Sleep -Milliseconds 300
        $t = Measure-Tooltip 'reload' 'status-btn-project-panel' 'r4-tooltip-after'
        Check 'reload' 'R-4' '바꾼 뒤 툴팁' 'Close Left Dock|Alt-B' $t.rows ($t.rows -ceq 'Close Left Dock|Alt-B') $t.line
        if ($t) { Add-ShortcutRow 'reload' '툴팁 status-btn-project-panel (keymap.json 바꾼 뒤)' 'Close Left Dock' 'workspace::ToggleLeftDock' ($t.rows.Split('|', 2)[1]) '사용자 keymap.json' 'r4-tooltip-after.png' }
        $n = Need-Box 'active-item'; Move-To ($n.x + $n.w / 2) ($n.y + $n.h / 2) 'neutral'
        $before = Count-Lines '^\[dev\] action-handled name=workspace::ToggleLeftDock '
        Send-Keys 'alt-b'
        $h = Wait-NewLine '^\[dev\] action-handled name=workspace::ToggleLeftDock ' $before 2
        Check 'reload' 'R-4' '새 키 실행' 'ToggleLeftDock' $h ($null -ne $h) $h
    }

    # ================================================================ 리뷰 1회차(D-032) 재현 사례
    # pending: View 를 연 채 Ctrl-B(I-520 50ms 대기)와 Left 를 지연 없이 보낸다. 50ms 안에 메뉴가 File 로 바뀌면
    # 예약은 취소되어야 한다. 고치기 전 코드는 항목 번호(0)만 들고 있어 File 의 Close Window 를 실행해 창을 닫았다.
    Run-Case 'pending' $null {
        param($res, $p)
        Park-Mouse
        Send-Keys 'f10'; Start-Sleep -Milliseconds 300; Send-Keys 'left'; Send-Keys 'left'; Start-Sleep -Milliseconds 400
        $bs = Count-Lines '^\[dev\] menu-shortcut '; $bo = Count-Lines '^\[dev\] menu-open '; $bx = Count-Lines '^\[dev\] menu-exec '
        Send-Batch 'ctrl-b left'
        Start-Sleep -Milliseconds 700
        $s = @(Get-Lines '^\[dev\] menu-shortcut ' | Select-Object -Skip $bs)
        $o = @(Get-Lines '^\[dev\] menu-open ' | Select-Object -Skip $bo)
        $x = @(Get-Lines '^\[dev\] menu-exec ' | Select-Object -Skip $bx)
        $res.lines = @($s + $o + $x)
        Check 'pending' 'I-520 D-032 ①' 'Ctrl-B 로 예약됨' 'menu-shortcut action=workspace::ToggleLeftDock' ($s -join ' / ') ($s.Count -eq 1 -and $s[0] -match 'action=workspace::ToggleLeftDock') ''
        Check 'pending' 'I-520 D-032 ①' '50ms 안에 Left → File 로 전환' 'menu-open index=1' ($o -join ' / ') ($o.Count -ge 1 -and $o[0] -match 'index=1 ') ''
        Check 'pending' 'I-520 D-032 ①' '전환 뒤 예약 실행 없음' '없음' ($x -join ' / ') ($x.Count -eq 0) ''
        Check 'pending' 'I-520 D-032 ①' '앱이 살아 있음(Close Window 오실행 없음)' 'True' "$(-not $p.HasExited)" (-not $p.HasExited) ''
    }

    # shadow: 사용자 키맵이 Workspace 의 ctrl-b 를 zed::Minimize 로 덮어쓰면 Toggle Left Dock 의 Ctrl-B 는 가려진다(I-704).
    # 메뉴·툴팁에 단축키가 없어야 한다(L-223). 고치기 전 코드는 키맵 전체의 마지막 바인딩으로 돌아가 Ctrl-B 를 보였다.
    Run-Case 'shadow' '[ { "context": "Workspace", "bindings": { "ctrl-b": "zed::Minimize" } } ]' {
        param($res, $p)
        Set-Content -LiteralPath (Join-Path $out 'shadow-keymap.json') -Value '[ { "context": "Workspace", "bindings": { "ctrl-b": "zed::Minimize" } } ]' -Encoding utf8 -NoNewline
        Park-Mouse
        Send-Keys 'f10'; Start-Sleep -Milliseconds 300; Send-Keys 'left'; Send-Keys 'left'; Start-Sleep -Milliseconds 600
        $r = @(Get-Lines '^\[dev\] menu-render index=2 ')[-1]
        Check 'shadow' 'I-704 L-223 D-032 ②' 'View 의 Toggle Left Dock 단축키' 'Toggle Left Dock|<none>' $r ($r -match 'rows=Toggle Left Dock\|<none>\t') $r
        if ($r -match ' rows=(.*)$') {
            foreach ($row in $Matches[1].Split("`t")) {
                if ($row -eq '---') { continue }
                $label, $shortcut = $row.Split('|', 2)
                $act = @{ 'Toggle Left Dock' = 'workspace::ToggleLeftDock'; 'Toggle Folder Sidebar' = 'multi_workspace::ToggleWorkspaceSidebar'; 'Focus Folder Sidebar' = 'multi_workspace::FocusWorkspaceSidebar'; 'Project Panel' = 'project_panel::ToggleFocus' }[$label]
                Add-ShortcutRow 'shadow' '메뉴 View (ctrl-b 를 Minimize 로 덮음)' $label $act $shortcut '가려짐 → 없음' 'shadow-menu.png'
            }
        }
        [void](Save-Window 'shadow-menu')
        Send-Keys 'escape'; Start-Sleep -Milliseconds 300
        $t = Measure-Tooltip 'shadow' 'status-btn-project-panel' 'shadow-tooltip'
        Check 'shadow' 'I-704 L-223 D-032 ②' 'Close Left Dock 툴팁 단축키' 'Close Left Dock|<none>' $t.rows ($t.rows -ceq 'Close Left Dock|<none>') $t.line
        if ($t) { Add-ShortcutRow 'shadow' '툴팁 status-btn-project-panel (ctrl-b 를 Minimize 로 덮음)' 'Close Left Dock' 'workspace::ToggleLeftDock' ($t.rows.Split('|', 2)[1]) '가려짐 → 없음' 'shadow-tooltip.png' }
    }

    # prevctx: ProjectPanel 컨텍스트에만 있는 사용자 바인딩(ctrl-y → Toggle Left Dock, down → Project Panel)으로,
    # 패널에 포커스를 둔 채 메뉴를 연다. 표시는 그 컨텍스트 기준(I-307)이고, Ctrl-Y 는 그 항목의 50ms 실행으로 이어져야 한다(I-520).
    # Down 은 메뉴 목록 키가 먼저다(선택 이동, 실행 아님). 고치기 전 코드는 메뉴 컨텍스트에서만 해석해 Ctrl-Y 가 아무 일도 안 했다.
    $prevKeymap = '[ { "context": "ProjectPanel", "bindings": { "ctrl-y": "workspace::ToggleLeftDock", "down": "project_panel::ToggleFocus" } } ]'
    Run-Case 'prevctx' $prevKeymap {
        param($res, $p)
        Set-Content -LiteralPath (Join-Path $out 'prevctx-keymap.json') -Value $prevKeymap -Encoding utf8 -NoNewline
        Park-Mouse
        Send-Keys 'ctrl-shift-e'; Start-Sleep -Milliseconds 400
        Send-Keys 'f10'; Start-Sleep -Milliseconds 300; Send-Keys 'left'; Send-Keys 'left'; Start-Sleep -Milliseconds 600
        $r = @(Get-Lines '^\[dev\] menu-render index=2 ')[-1]
        Check 'prevctx' 'I-307 D-032 ③' 'View 단축키(패널 컨텍스트 기준)' "Toggle Left Dock|Ctrl-Y / Project Panel|Down" $r ($r -match "rows=Toggle Left Dock\|Ctrl-Y\t(?:[^\t]*\t){2}---\tProject Panel\|Down") $r
        [void](Save-Window 'prevctx-menu')
        $bsel = Count-Lines '^\[dev\] menu-selected '; $bx = Count-Lines '^\[dev\] menu-exec '
        Send-Keys 'down'
        $sel = Wait-NewLine '^\[dev\] menu-selected ' $bsel 2
        Start-Sleep -Milliseconds 300
        $x = @(Get-Lines '^\[dev\] menu-exec ' | Select-Object -Skip $bx)
        Check 'prevctx' 'I-517 D-032 ③' 'Down 은 메뉴 목록 키 우선(선택 이동)' 'menu-selected index=0, 실행 없음' "$sel / exec=$($x.Count)" ($sel -match 'index=0$' -and $x.Count -eq 0) $sel
        $bs = Count-Lines '^\[dev\] menu-shortcut '; $bx = Count-Lines '^\[dev\] menu-exec '; $bh = Count-Lines '^\[dev\] action-handled name=workspace::ToggleLeftDock '
        Send-Keys 'ctrl-y'
        $s = Wait-NewLine '^\[dev\] menu-shortcut ' $bs 2
        $e = Wait-NewLine '^\[dev\] menu-exec ' $bx 2
        $h = Wait-NewLine '^\[dev\] action-handled name=workspace::ToggleLeftDock ' $bh 2
        Check 'prevctx' 'I-520 D-032 ③' 'Ctrl-Y → 항목 예약' 'menu-shortcut action=workspace::ToggleLeftDock' $s ($s -match 'action=workspace::ToggleLeftDock') $s
        Check 'prevctx' 'I-520 D-032 ③' 'Ctrl-Y → 50ms 뒤 실행' 'menu-exec action=workspace::ToggleLeftDock via=shortcut' $e ($e -match 'action=workspace::ToggleLeftDock via=shortcut') $e
        Check 'prevctx' 'I-309 D-032 ③' '실행 때 원래 포커스(project_panel)' 'focus=project_panel' $h ($h -match 'focus=project_panel') $h
    }

    # ================================================================ 리뷰 2회차(D-033) 재현 사례
    # shadowpp(②): ProjectPanel 에서 ctrl-b 를 zed::Minimize 로 덮어쓰고 패널 포커스에서 View 를 연다.
    # 원래 컨텍스트에서 Toggle Left Dock 의 키는 가려졌으니 표시가 없어야 한다(L-223). 고치기 전 코드는 메뉴 포커스
    # (Root > Workspace > menu)로 다시 찾아 살아 있는 내장 Ctrl-B 를 보였다.
    $ppKeymap = '[ { "context": "ProjectPanel", "bindings": { "ctrl-b": "zed::Minimize" } } ]'
    Run-Case 'shadowpp' $ppKeymap {
        param($res, $p)
        Set-Content -LiteralPath (Join-Path $out 'shadowpp-keymap.json') -Value $ppKeymap -Encoding utf8 -NoNewline
        Park-Mouse
        Send-Keys 'ctrl-shift-e'; Start-Sleep -Milliseconds 400
        Send-Keys 'f10'; Start-Sleep -Milliseconds 300; Send-Keys 'left'; Send-Keys 'left'; Start-Sleep -Milliseconds 600
        $r = @(Get-Lines '^\[dev\] menu-render index=2 ')[-1]
        Check 'shadowpp' 'I-704 L-223 D-033 ②' 'View 의 Toggle Left Dock 단축키(패널에서 가려짐)' 'Toggle Left Dock|<none>' $r ($r -match 'rows=Toggle Left Dock\|<none>\t') $r
        [void](Save-Window 'shadowpp-menu')
    }

    # rapid(ⓐ): View 를 연 채 Ctrl-B 와 Ctrl-Shift-E 를 50ms 안에(SendInput 한 번) 보낸다. 두 번째 예약(Project Panel)만
    # 실행되어야 한다. 고치기 전 코드는 첫 타이머가 새 예약을 꺼내 버려 아무것도 실행하지 않았다.
    Run-Case 'rapid' $null {
        param($res, $p)
        Park-Mouse
        Send-Keys 'f10'; Start-Sleep -Milliseconds 300; Send-Keys 'left'; Send-Keys 'left'; Start-Sleep -Milliseconds 400
        $bs = Count-Lines '^\[dev\] menu-shortcut '; $bx = Count-Lines '^\[dev\] menu-exec '
        Send-Batch 'ctrl-b ctrl-shift-e'
        Start-Sleep -Milliseconds 700
        $s = @(Get-Lines '^\[dev\] menu-shortcut ' | Select-Object -Skip $bs)
        $x = @(Get-Lines '^\[dev\] menu-exec ' | Select-Object -Skip $bx)
        $res.lines = @($s + $x)
        Check 'rapid' 'I-520 D-033 ⓐ' '두 번 예약됨' 2 $s.Count ($s.Count -eq 2) ($s -join ' / ')
        Check 'rapid' 'I-520 D-033 ⓐ' '마지막 예약만 실행' 'menu-exec action=project_panel::ToggleFocus via=shortcut (1번)' ($x -join ' / ') ($x.Count -eq 1 -and $x[0] -match 'action=project_panel::ToggleFocus via=shortcut') ''
    }

    # chord(ⓑ): ProjectPanel 에 ctrl-k → Toggle Left Dock, ctrl-k ctrl-y → Project Panel. 패널에서 View 를 연다.
    #   ⑴ Ctrl-K, Ctrl-Y: 접두 대기 뒤 chord 완성 → Project Panel 만 실행(Toggle Left Dock 은 실행 안 함).
    #   ⑵ Ctrl-K 만: gpui 와 같게 1초 뒤 접두가 확정되어 Toggle Left Dock 실행.
    # 고치기 전 코드는 Ctrl-K 에서 바로 Toggle Left Dock 을 예약해 50ms 뒤 메뉴를 닫았다.
    $chordKeymap = '[ { "context": "ProjectPanel", "bindings": { "ctrl-k": "workspace::ToggleLeftDock", "ctrl-k ctrl-y": "project_panel::ToggleFocus" } } ]'
    Run-Case 'chord' $chordKeymap {
        param($res, $p)
        Set-Content -LiteralPath (Join-Path $out 'chord-keymap.json') -Value $chordKeymap -Encoding utf8 -NoNewline
        Park-Mouse
        Send-Keys 'ctrl-shift-e'; Start-Sleep -Milliseconds 400
        Send-Keys 'f10'; Start-Sleep -Milliseconds 300; Send-Keys 'left'; Send-Keys 'left'; Start-Sleep -Milliseconds 600
        $r = @(Get-Lines '^\[dev\] menu-render index=2 ')[-1]
        Check 'chord' 'I-307 D-033 ⓑ' 'View 단축키(패널 컨텍스트)' 'Toggle Left Dock|Ctrl-K / Project Panel|Ctrl-K Ctrl-Y' $r ($r -match "rows=Toggle Left Dock\|Ctrl-K\t(?:[^\t]*\t){2}---\tProject Panel\|Ctrl-K Ctrl-Y") $r
        [void](Save-Window 'chord-menu')
        $bx = Count-Lines '^\[dev\] menu-exec '
        Send-Keys 'ctrl-k ctrl-y'
        Start-Sleep -Milliseconds 1500
        $x = @(Get-Lines '^\[dev\] menu-exec ' | Select-Object -Skip $bx)
        Check 'chord' 'I-520 D-033 ⓑ' '⑴ Ctrl-K Ctrl-Y → Project Panel 만 실행' 'menu-exec action=project_panel::ToggleFocus via=shortcut (1번)' ($x -join ' / ') ($x.Count -eq 1 -and $x[0] -match 'action=project_panel::ToggleFocus via=shortcut') ''

        # ⑵ 다시 패널에 포커스를 두고 Ctrl-K 만 누른다.
        Send-Keys 'ctrl-shift-e'; Start-Sleep -Milliseconds 400
        $ctx = @(Get-Lines '^\[dev\] key keystroke=ctrl-shift-e ')[-1]
        Send-Keys 'f10'; Start-Sleep -Milliseconds 300; Send-Keys 'left'; Send-Keys 'left'; Start-Sleep -Milliseconds 600
        $bx = Count-Lines '^\[dev\] menu-exec '
        $t0 = UnixMs
        Send-Keys 'ctrl-k'
        Start-Sleep -Milliseconds 400
        $early = @(Get-Lines '^\[dev\] menu-exec ' | Select-Object -Skip $bx)
        Start-Sleep -Milliseconds 1400
        $x = @(Get-Lines '^\[dev\] menu-exec ' | Select-Object -Skip $bx)
        $dt = if ($x.Count -gt 0 -and $x[0] -match 't_ms=(\d+)') { [int64]$Matches[1] - $t0 } else { -1 }
        Check 'chord' 'I-520 D-033 ⓑ' '⑵ Ctrl-K 직후(0.4초)에는 아직 실행 안 함(접두 대기)' 0 $early.Count ($early.Count -eq 0) ($early -join ' / ')
        Check 'chord' 'I-520 D-033 ⓑ' '⑵ Ctrl-K 만 → 시간 초과 뒤 Toggle Left Dock 실행' 'menu-exec action=workspace::ToggleLeftDock via=shortcut, 900ms 이상' "$($x -join ' / ') (dt=$dt)" ($x.Count -eq 1 -and $x[0] -match 'action=workspace::ToggleLeftDock via=shortcut' -and $dt -ge 900) $ctx
    }

    # ================================================================ quit / closewin
    Run-Case 'quit' $null {
        param($res, $p)
        Park-Mouse
        Send-Keys 'f10'; Start-Sleep -Milliseconds 300; Send-Keys 'down'
        $r = @(Get-Lines '^\[dev\] menu-render index=0 ')[-1]
        Send-Keys 'enter'
        $exited = $p.WaitForExit(5000)
        Check 'quit' 'I-341' 'Quit workbench-gpui 실행 → 앱 끝남' 'True' "$exited" $exited $r
    }
    Run-Case 'closewin' $null {
        param($res, $p)
        Send-Keys 'ctrl-shift-w'
        $exited = $p.WaitForExit(5000)
        Check 'closewin' 'I-358' 'Ctrl-Shift-W → 창 닫힘(앱 끝남)' 'True' "$exited" $exited
    }
}
catch { $results.failures += $_.Exception.Message }
finally {
    # 1) 사용자 keymap.json 복원(가장 먼저, 독립 try/finally, D-029).
    try {
        try {
            if ($hadKeymap) { if ($backupDone) { Copy-Item -LiteralPath $backupPath -Destination $keymapPath -Force } }
            else { Remove-Keymap }
        }
        finally {
            $existsAfter = Test-Path -LiteralPath $keymapPath
            $userHashAfter = '<absent>'
            if ($existsAfter) {
                try { $userHashAfter = (Get-FileHash -LiteralPath $keymapPath -Algorithm SHA256).Hash }
                catch { $userHashAfter = '<unreadable>'; $results.errors += "user keymap 해시 읽기: $($_.Exception.Message)" }
            }
            $results.userKeymap = [ordered]@{ path = $keymapPath; existedBefore = $hadKeymap; hashBefore = $userHashBefore; existsAfter = $existsAfter; hashAfter = $userHashAfter; restored = ($userHashAfter -eq $userHashBefore); backupPath = $(if ($backupDone) { $backupPath } else { $null }) }
            if ($userHashAfter -ne $userHashBefore) { $results.failures += "사용자 keymap.json 이 실행 전과 다르다" }
        }
    }
    catch { $results.errors += "user keymap 복원: $($_.Exception.Message)" }
    # 2) 백업 지우기(복원 확인 때만).
    if ($backupDone -and $results.userKeymap -and $results.userKeymap.restored) {
        try { Remove-Item -LiteralPath $backupPath -Force } catch { $results.errors += "백업 지우기: $($_.Exception.Message)" }
    }
    # state.json 은 이 시험이 바꾸지 않는다(Phase 3 뒤 추가). 다르면 실패로 남긴다.
    try {
        $stateHashAfter = if (Test-Path -LiteralPath $statePathGuard) { (Get-FileHash -LiteralPath $statePathGuard -Algorithm SHA256).Hash } else { '<absent>' }
        $results.userState = [ordered]@{ path = $statePathGuard; hashBefore = $stateHashBefore; hashAfter = $stateHashAfter; unchanged = ($stateHashBefore -eq $stateHashAfter) }
        if ($stateHashBefore -ne $stateHashAfter) { $results.failures += '사용자 state.json 이 실행 전과 다르다' }
        Remove-Item -LiteralPath $pickCancel -Force -ErrorAction SilentlyContinue
    }
    catch { $results.errors += "state.json 확인: $($_.Exception.Message)" }
    foreach ($e in $results.errors) { $results.failures += "정리 오류: $e" }
}

# ---------------------------------------------------------------- R-5 대조표
$md = [System.Collections.Generic.List[string]]::new()
$md.Add('# R-5 대조표: 화면 단축키 / 키맵 적용 결과 (v0.2 Phase 2)')
$md.Add('')
$md.Add(('생성: tools/verify-v02-phase2.ps1, {0}.' -f (Get-Date).ToString('yyyy-MM-dd HH:mm')))
$md.Add('')
$md.Add('- **화면**: 앱이 그린 단축키 글자(`[dev] tooltip-shown rows=`, `[dev] menu-render rows=`). `<none>` 은 단축키 없이 제목만(L-223).')
$md.Add('- **키맵 적용 결과**: 같은 실행의 `[dev] display seq=<최신> where=center` 줄(gpui `highest_precedence_binding_for_action_in`, I-704: 가려진 키 제외, 남은 것 중 마지막, L-219~L-221 형식). 메뉴는 메뉴를 열기 직전 포커스(가운데 Pane)의 컨텍스트, 툴팁은 지금 포커스(가운데 Pane)의 컨텍스트다(I-307, L-201).')
$md.Add('- **01-zed 원문**: 02 8.2절·9.2절의 키 열. v0.2 에 그 동작이 없는 항목은 키맵에 바인딩이 없어 화면에 단축키가 없다(R-7 설명).')
$md.Add('')
$md.Add('| 사례 | 위치 | 문구 | 액션 | 화면 | 키맵 적용 결과 | 01-zed 원문 | 판정 | 증거 |')
$md.Add('| --- | --- | --- | --- | --- | --- | --- | --- | --- |')
foreach ($r in $results.shortcutRows) {
    $md.Add(('| {0} | {1} | {2} | `{3}` | `{4}` | `{5}` | {6} | {7} | {8} |' -f $r.case, $r.where, $r.label, $r.action, $r.shown, $r.computed, $r.original, $(if ($r.ok) { '일치' } else { '불일치' }), $r.evidence))
}
$md.Add('')
$md.Add(('- 줄 {0}개, 불일치 {1}개.' -f $results.shortcutRows.Count, @($results.shortcutRows | Where-Object { -not $_.ok }).Count))
Set-Content -LiteralPath (Join-Path $out 'r5-shortcuts.md') -Value ($md -join "`n") -Encoding utf8

$results.finishedAt = (Get-Date).ToString('o')
$results.passed = ($results.failures.Count -eq 0)
$results | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $out 'results.json') -Encoding utf8
"cases: $($results.cases.Keys -join ', ')"
"checks: $($results.checks.Count), failed: $(@($results.checks | Where-Object { -not $_.ok }).Count)"
"shortcut rows: $($results.shortcutRows.Count), mismatched: $(@($results.shortcutRows | Where-Object { -not $_.ok }).Count)"
"failures: $($results.failures.Count)"
"user keymap: before=$($results.userKeymap.hashBefore) after=$($results.userKeymap.hashAfter) restored=$($results.userKeymap.restored)"
$results.failures | ForEach-Object { "  - $_" }
if ($results.failures.Count -gt 0) { exit 1 }


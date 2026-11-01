#Requires -Version 7
<#
.SYNOPSIS
  v0.2 Phase 1 (SPEC R-1~R-4) 증거: 내장 키맵 대조, keymap.json 덮어쓰기·null·오류·JSONC, 충돌 규칙, 다시 읽기.

.DESCRIPTION
  앱을 `--dev-keymap` 으로 사례마다 새로 띄운다. 앱은 표준출력에 다음을 낸다.
    [dev] keymap-load / binding / builtin / notification / keymap-load-end   (읽을 때마다, seq 증가)
    [dev] display seq= where=<center|sidebar|project_panel> action= text=     (다음 프레임, I-704 규칙)
    [dev] key keystroke= action= context=                                    (키 입력마다. action=none 이면 아무 액션도 처리되지 않음)
    [dev] action-handled name= by=<workbench|placeholder> [focus=]

  안전 규칙:
    - 시작 전에 workbench-gpui 가 이미 실행 중이면 오류로 끝낸다. 다른 프로세스는 건드리지 않는다.
    - 띄운 프로세스의 PID 와 창 HWND 를 고정하고, 키를 보내기 직전마다 그 창이 전면인지 확인한다.
      전면이 아니면 입력을 보내지 않고 중단한다.
    - %APPDATA%\workbench-gpui\keymap.json 이 이미 있으면 시작 때 백업하고 끝날 때 되돌린다. 없었으면 끝날 때 지운다.

  사례:
    base       keymap.json 없음. R-1 바인딩 대조(r1-expected.tsv), R-3 포커스별 같은 키(Delete·Ctrl-N 등).
    override   R-2 덮어쓰기: Workspace 의 ctrl-b 를 project_panel::ToggleFocus 로.
    null       R-2 해제: Workspace ctrl-b = null, ProjectPanel delete = null.
    unknown    R-2 없는 액션 이름 2개(알림 문구), 나머지 바인딩은 적용.
    jsonc      R-2 주석·끝 쉼표.
    broken     형식이 틀린 파일(알림 문구), 내장 키맵은 그대로.
    order      R-3 같은 깊이 두 번 묶기(나중 것이 이김), 깊이가 다르면 깊은 쪽이 이김.
    startup    R-4 시작 구간: 최초 로드 직후(--dev-keymap-startup-delay 로 멈춘 동안) 저장해도 다시 읽는다.
    reload     R-4 실행 중 keymap.json 을 두 번 바꿔 저장(덮어쓰기, 바꿔치기). 다시 읽기·새 키 실행·표시 문자열 변화.
               바꿔치기용 임시 파일은 GUID 이름이고, 이번 실행이 만든 것만 지운다.
    같은 폴더의 keymap.json.tmp(이 스크립트 것이 아님)는 실행 전후 해시가 같아야 한다. 없으면 표지 파일을 만들어 비교하고 지운다.
    띄운 프로세스는 준비 대기·창 탐색이 실패해도 그 PID 만 닫는다.

  결과: specs/v0.2/verify/phase1/ 의 <사례>-stdout.txt, <사례>-keymap.json, r1-bindings.md, results.json,
  알림 사례의 스크린샷 <사례>-notification.png. 실패가 하나라도 있으면 종료 코드 1.

.EXAMPLE
  pwsh -NoProfile -File tools/verify-v02-phase1.ps1
#>
[CmdletBinding()]
param(
    [string]$Exe = 'target\debug\workbench-gpui.exe',
    [string]$OutDir = 'specs\v0.2\verify\phase1',
    [string[]]$Only = @()
)

$ErrorActionPreference = 'Stop'
$ProcessName = 'workbench-gpui'
$AppTitle = 'workbench-gpui'
$CaptureScript = Join-Path $PSScriptRoot 'capture.ps1'

if (-not ('WgKm.Native' -as [type])) {
    $refs = @(
        'System.Runtime'
        'System.Collections'
        'System.Threading'
        'System.Threading.Thread'
        'System.Runtime.InteropServices'
    )
    Add-Type -ReferencedAssemblies $refs -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

namespace WgKm
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

    public static class Native
    {
        const uint INPUT_KEYBOARD = 1, KEYEVENTF_EXTENDEDKEY = 0x1, KEYEVENTF_KEYUP = 0x2;
        public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
        [DllImport("user32.dll", SetLastError = true)] static extern uint SendInput(uint n, INPUT[] inputs, int size);
        [DllImport("user32.dll")] static extern uint MapVirtualKey(uint code, uint mapType);
        [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")] static extern bool EnumWindows(EnumWindowsProc cb, IntPtr lParam);
        [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
        [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr hWnd);
        [DllImport("user32.dll")] static extern IntPtr GetWindow(IntPtr hWnd, uint cmd);
        [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr hWnd, StringBuilder sb, int max);

        [DllImport("user32.dll")] static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool attach);
        [DllImport("user32.dll")] static extern bool BringWindowToTop(IntPtr hWnd);
        [DllImport("kernel32.dll")] static extern uint GetCurrentThreadId();

        // 전면 전환. 입력을 주입하지 않고, 현재 전면 창의 스레드에 이 스레드의 입력 큐를 잠시 붙여 전경 잠금을 피한다.
        // 성공 여부는 호출 쪽이 GetForegroundWindow 로 다시 확인한다 (tools/verify-phase3.ps1 과 같은 방식).
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

        static bool IsExtended(ushort vk)
        {
            switch (vk)
            {
                case 0x21: case 0x22: case 0x23: case 0x24: // PageUp PageDown End Home
                case 0x25: case 0x26: case 0x27: case 0x28: // Left Up Right Down
                case 0x2D: case 0x2E: // Insert Delete
                case 0x5D: // Apps(Menu)
                    return true;
            }
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

        static void Send(INPUT i)
        {
            if (SendInput(1, new[] { i }, Marshal.SizeOf(typeof(INPUT))) != 1)
                throw new InvalidOperationException("SendInput failed: " + Marshal.GetLastWin32Error());
        }

        // 수식키(들)를 누른 채 키 하나를 누르고 뗀 뒤 수식키를 거꾸로 뗀다.
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

# 가상 키 표.
$VK = @{
    ctrl = 0x11; shift = 0x10; alt = 0x12
    backspace = 0x08; tab = 0x09; enter = 0x0D; escape = 0x1B; space = 0x20
    pageup = 0x21; pagedown = 0x22; end = 0x23; home = 0x24
    left = 0x25; up = 0x26; right = 0x27; down = 0x28
    insert = 0x2D; delete = 0x2E; menu = 0x5D
    f2 = 0x71; f10 = 0x79; ';' = 0xBA
}
foreach ($c in [char[]]'abcdefghijklmnopqrstuvwxyz') { $VK["$c"] = [int][char]::ToUpper($c) }

$out = [System.IO.Path]::GetFullPath($OutDir, (Get-Location).Path)
if (-not (Test-Path -LiteralPath $out)) { New-Item -ItemType Directory -Path $out -Force | Out-Null }
$keymapPath = Join-Path $env:APPDATA 'workbench-gpui\keymap.json'
$backupPath = Join-Path ([System.IO.Path]::GetTempPath()) ("wg-keymap-backup-{0}.json" -f [guid]::NewGuid())
$hadKeymap = Test-Path -LiteralPath $keymapPath
# 사용자 keymap.json 의 실행 전 해시. 끝날 때 복원한 파일과 비교해 results.userKeymap 에 남긴다(리뷰 2회차, D-029).
$userHashBefore = if ($hadKeymap) { (Get-FileHash -LiteralPath $keymapPath -Algorithm SHA256).Hash } else { '<absent>' }
# 이번 실행이 만든 임시 파일 경로. 끝날 때 이것만 지운다.
$script:createdTemps = [System.Collections.Generic.List[string]]::new()

$results = [ordered]@{ startedAt = (Get-Date).ToString('o'); keymapPath = $keymapPath; hadKeymap = $hadKeymap; cases = [ordered]@{}; failures = @(); foreignKeys = @(); errors = @() }

$script:hwnd = [IntPtr]::Zero
$script:appPid = 0
$script:stdout = $null
$script:keyCursor = 0

function Fail([string]$Case, [string]$Text) {
    $script:results.failures += "${Case}: $Text"
}

function Get-Lines([string]$Pattern) {
    @(Get-Content -LiteralPath $script:stdout -Encoding utf8 -ErrorAction SilentlyContinue | Where-Object { $_ -match $Pattern })
}

function Wait-Line([string]$Pattern, [double]$Seconds = 20) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $Seconds) {
        $l = @(Get-Lines $Pattern)
        if ($l.Count -gt 0) { return $l[0] }
        Start-Sleep -Milliseconds 100
    }
    return $null
}

function Assert-Foreground([string]$What) {
    if ([WgKm.Native]::GetForegroundWindow() -ne $script:hwnd) {
        [WgKm.Native]::Activate($script:hwnd)
        Start-Sleep -Milliseconds 300
    }
    if ([WgKm.Native]::GetForegroundWindow() -ne $script:hwnd) {
        throw "${What}: 대상 창(0x{0:X})이 전면이 아니다. 입력을 보내지 않고 중단한다" -f $script:hwnd.ToInt64()
    }
}

# "ctrl-k ctrl-o" 같은 gpui 표기를 키 입력으로 보낸다.
function Send-Binding([string]$Keys) {
    foreach ($stroke in $Keys.Split(' ', [StringSplitOptions]::RemoveEmptyEntries)) {
        $parts = $stroke.Split('-')
        $key = $parts[-1]
        $mods = @($parts | Select-Object -SkipLast 1 | ForEach-Object { [uint16]$VK[$_] })
        if (-not $VK.ContainsKey($key)) { throw "모르는 키: $key" }
        Assert-Foreground "키 $Keys"
        [WgKm.Native]::Combo([uint16[]]$mods, [uint16]$VK[$key])
        Start-Sleep -Milliseconds 120
    }
}

# 수식키만 눌렀다 뗀 줄(예: Alt 조합 뒤에 gpui 가 내는 `keystroke=alt`). 키 판정에서 뺀다.
$ModifierOnly = '^\[dev\] key keystroke=((fn|ctrl|win|alt|shift)-)*(fn|ctrl|win|alt|shift) '

# 키를 보내고, 그 뒤에 나온 [dev] key 줄 중 보낸 마지막 키 입력과 keystroke 가 같은 줄을 돌려준다.
# chord 는 앞 키가 대기(pending)라 줄이 없고, 마지막 키에서 액션이 정해져 줄이 하나 나온다.
# 이 스크립트가 보내지 않은 키 줄(같은 데스크톱의 다른 입력, 수식키만 누른 줄 제외)은 판정에 쓰지 않고
# results.json 의 foreignKeys 에 경고로 남긴다. 다른 입력이 앱 상태를 바꿨을 수 있으므로 검증자가 확인한다.
function Invoke-Key([string]$Case, [string]$Keys, [string]$ExpectAction, [string]$ExpectContext = $null, [string]$Note = '') {
    $before = (Get-Lines '^\[dev\] key ').Count
    Send-Binding $Keys
    $strokes = $Keys.Split(' ', [StringSplitOptions]::RemoveEmptyEntries)
    $mine = '^\[dev\] key keystroke={0} ' -f [regex]::Escape($strokes[-1])
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $new = @()
    while ($sw.Elapsed.TotalSeconds -lt 3) {
        $new = @(Get-Lines '^\[dev\] key ' | Select-Object -Skip $before | Where-Object { $_ -match $mine })
        if ($new.Count -ge 1) { break }
        Start-Sleep -Milliseconds 100
    }
    Start-Sleep -Milliseconds 150
    $all = @(Get-Lines '^\[dev\] key ' | Select-Object -Skip $before)
    $new = @($all | Where-Object { $_ -match $mine })
    $foreign = @($all | Where-Object { $_ -notmatch $mine -and $_ -notmatch $ModifierOnly })
    foreach ($fl in $foreign) { $script:results.foreignKeys += "${Case} (보낸 키 $Keys 뒤): $fl" }
    $last = if ($new.Count -gt 0) { $new[-1] } else { $null }
    $action = if ($last -and $last -match ' action=(\S+)') { $Matches[1] } else { '<no key line>' }
    $context = if ($last -and $last -match ' context=(.*)$') { $Matches[1] } else { '' }
    $ok = ($action -eq $ExpectAction)
    if ($ok -and $ExpectContext) { $ok = $context.Contains($ExpectContext) }
    $row = [ordered]@{ keys = $Keys; note = $Note; expect = $ExpectAction; expectContext = $ExpectContext; got = $action; context = $context; ok = $ok; lines = $all }
    if (-not $ok) { Fail $Case ("키 {0}: 기대 {1}{2}, 실제 {3} (context={4})" -f $Keys, $ExpectAction, $(if ($ExpectContext) { " in $ExpectContext" } else { '' }), $action, $context) }
    return $row
}

function Get-Display([int]$Seq, [string]$Where, [string]$Action) {
    $l = @(Get-Lines ("^\[dev\] display seq={0} where={1} action={2} " -f $Seq, [regex]::Escape($Where), [regex]::Escape($Action)))
    if ($l.Count -eq 0) { return '<missing>' }
    if ($l[0] -match ' text=(.*)$') { return $Matches[1] }
    return '<missing>'
}

function Check-Display([string]$Case, [System.Collections.IList]$Rows, [int]$Seq, [string]$Where, [string]$Action, [string]$Expect) {
    $got = Get-Display $Seq $Where $Action
    $ok = ($got -eq $Expect)
    $Rows.Add([ordered]@{ seq = $Seq; where = $Where; action = $Action; expect = $Expect; got = $got; ok = $ok }) | Out-Null
    if (-not $ok) { Fail $Case "표시 seq=$Seq $Where ${Action}: 기대 '$Expect', 실제 '$got'" }
}

function Get-Notifications([int]$Seq) {
    @(Get-Lines "^\[dev\] notification seq=$Seq text=" | ForEach-Object { $_ -replace "^\[dev\] notification seq=$Seq text=", '' })
}

function Check-Notifications([string]$Case, [System.Collections.IDictionary]$Res, [int]$Seq, [string[]]$Expect) {
    $got = @(Get-Notifications $Seq)
    $Res["notificationsSeq$Seq"] = $got
    $ok = (($got -join "`n") -ceq ($Expect -join "`n"))
    if (-not $ok) { Fail $Case ("알림 seq={0}: 기대 [{1}], 실제 [{2}]" -f $Seq, ($Expect -join ' | '), ($got -join ' | ')) }
}

function Write-Keymap([string]$Text) {
    $dir = Split-Path -Parent $keymapPath
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($keymapPath, $Text, [System.Text.UTF8Encoding]::new($false))
}

function Remove-Keymap { if (Test-Path -LiteralPath $keymapPath) { Remove-Item -LiteralPath $keymapPath -Force } }

function Save-Window([string]$Name) {
    $png = Join-Path $out "$Name.png"
    $expected = '0x{0:X}' -f $script:hwnd.ToInt64()
    $raw = & pwsh -NoProfile -File $CaptureScript -Hwnd $expected -Out $png -Method PrintWindow
    $obj = ($raw | Out-String) | ConvertFrom-Json
    if ($obj.hwnd -ne $expected -or $obj.pid -ne $script:appPid) { throw "capture ${Name}: 고정한 창과 다른 창을 찍었다" }
    if (-not $obj.capture.ok) { throw "capture $Name 실패: $($obj.capture.error)" }
}

# 이번 사례가 띄운 프로세스. Start-App 이 띄우자마자 여기에 넣어, 준비 대기·창 탐색이 실패해 throw 해도
# Run-Case 의 finally 가 이 프로세스(만)를 닫는다.
$script:launched = $null

function Start-App([string]$Case, [string[]]$AppArgs = @(), [scriptblock]$OnLaunched = $null) {
    $existing = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
    if ($existing.Count -gt 0) { throw "이미 실행 중인 $ProcessName 가 있다 (PID $($existing.Id -join ', ')). 닫고 다시 실행하라" }
    $script:stdout = Join-Path $out "$Case-stdout.txt"
    if (Test-Path -LiteralPath $script:stdout) { Remove-Item -LiteralPath $script:stdout -Force }
    $exePath = (Resolve-Path -LiteralPath $Exe).Path
    $p = Start-Process -FilePath $exePath -ArgumentList (@('--dev-keymap') + $AppArgs) -RedirectStandardOutput $script:stdout -PassThru
    $script:launched = $p
    $script:appPid = $p.Id
    if ($OnLaunched) { & $OnLaunched | Out-Null }
    if (-not (Wait-Line '^\[dev\] display-end seq=1')) { throw "${Case}: 20초 안에 display-end seq=1 이 나오지 않았다" }
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    do {
        $script:hwnd = [WgKm.Native]::FindTitled([uint32]$p.Id, $AppTitle)
        if ($script:hwnd -ne [IntPtr]::Zero) { break }
        Start-Sleep -Milliseconds 200
    } while ($sw.Elapsed.TotalSeconds -lt 10)
    if ($script:hwnd -eq [IntPtr]::Zero) { throw "${Case}: 앱 메인 창을 찾지 못했다" }
    Start-Sleep -Milliseconds 500
    return $p
}

function Stop-App($p) {
    if ($p -and -not $p.HasExited) {
        try { [void]$p.CloseMainWindow(); [void]$p.WaitForExit(5000) } catch {}
        if (-not $p.HasExited) { try { $p.Kill(); [void]$p.WaitForExit(3000) } catch {} }
    }
}

function Wants([string]$Case) { $Only.Count -eq 0 -or $Only -contains $Case }

# 사례 하나를 돌린다. $Body 는 결과 hashtable 을 받는다.
function Run-Case([string]$Case, [string]$Keymap, [scriptblock]$Body, [string[]]$AppArgs = @(), [scriptblock]$OnLaunched = $null) {
    if (-not (Wants $Case)) { return }
    $res = [ordered]@{ keymap = $Keymap; keys = [System.Collections.ArrayList]::new(); display = [System.Collections.ArrayList]::new() }
    # [string] 매개변수는 $null 을 빈 문자열로 바꾼다. 빈 값이면 keymap.json 이 없는 사례다.
    if ([string]::IsNullOrEmpty($Keymap)) { Remove-Keymap } else {
        Write-Keymap $Keymap
        Set-Content -LiteralPath (Join-Path $out "$Case-keymap.json") -Value $Keymap -Encoding utf8 -NoNewline
    }
    $script:launched = $null
    try {
        $p = Start-App $Case $AppArgs $OnLaunched
        $res.pid = $p.Id
        $res.hwnd = '0x{0:X}' -f $script:hwnd.ToInt64()
        & $Body $res
    }
    catch {
        Fail $Case $_.Exception.Message
    }
    finally {
        # Start-App 이 반환하기 전에 실패해도 이번에 띄운 프로세스를 닫는다.
        Stop-App $script:launched
        $script:launched = $null
    }
    $results.cases[$Case] = $res
}

# 바인딩 출력 한 줄을 객체로.
function Parse-Binding([string]$Line) {
    if ($Line -match '^\[dev\] binding seq=(\d+) index=(\d+) source=(\S+) keys=(.+?) context=(.+?) action=(\S+)$') {
        [pscustomobject]@{ seq = [int]$Matches[1]; index = [int]$Matches[2]; source = $Matches[3]; keys = $Matches[4]; context = $Matches[5]; action = $Matches[6] }
    }
}

# 정리 단계가 쓰는 상태. try 밖에 두어, 시작 중에 실패해도 정리 단계가 무엇을 했는지 안다.
$backupDone = $false
$foreignTmp = "$keymapPath.tmp"
$foreignExisted = Test-Path -LiteralPath $foreignTmp
$foreignHash = $null
$sentinelCreated = $false

try {
    if ($hadKeymap) {
        Copy-Item -LiteralPath $keymapPath -Destination $backupPath -Force
        $backupDone = $true
    }

    # 이 스크립트가 소유하지 않은 같은 폴더의 파일(예: 편집기가 남긴 keymap.json.tmp)을 건드리지 않는지 본다(리뷰 1회차 ①).
    # 이미 있으면 내용 해시를 기록하고, 없으면 표지 파일을 만들어(끝날 때 지운다) 실행 뒤 그대로인지 비교한다.
    if (-not $foreignExisted) {
        $kdir = Split-Path -Parent $keymapPath
        if (-not (Test-Path -LiteralPath $kdir)) { New-Item -ItemType Directory -Path $kdir -Force | Out-Null }
        [System.IO.File]::WriteAllText($foreignTmp, "verify-v02-phase1 sentinel $([guid]::NewGuid())", [System.Text.UTF8Encoding]::new($false))
        $sentinelCreated = $true
    }
    $foreignHash = (Get-FileHash -LiteralPath $foreignTmp -Algorithm SHA256).Hash

    # ---------------------------------------------------------------- base: R-1, R-3
    Run-Case 'base' $null {
        param($res)
        # R-1: 기대 표와 줄마다 대조.
        $bindings = @(Get-Lines '^\[dev\] binding seq=1 ' | ForEach-Object { Parse-Binding $_ })
        $res.bindingCount = $bindings.Count
        $res.sourceCount = [ordered]@{}
        foreach ($g in ($bindings | Group-Object source)) { $res.sourceCount[$g.Name] = $g.Count }
        $builtin = @($bindings | Where-Object { $_.source -eq 'builtin' })
        $expected = @(Get-Content -LiteralPath (Join-Path $out 'r1-expected.tsv') -Encoding utf8 | Where-Object { $_ -and -not $_.StartsWith('#') } | ForEach-Object {
                $c = $_.Split("`t"); [pscustomobject]@{ id = $c[0]; keys = $c[1]; context = $c[2]; action = $c[3] } })
        $rows = @()
        foreach ($e in $expected) {
            $hit = @($builtin | Where-Object { $_.keys -eq $e.keys -and $_.context -eq $e.context -and $_.action -eq $e.action })
            $ok = $hit.Count -gt 0
            if (-not $ok) { Fail 'base' "R-1 표에 있는데 앱에 없다: $($e.id) $($e.keys) [$($e.context)] $($e.action)" }
            $rows += [pscustomobject]@{ id = $e.id; keys = $e.keys; context = $e.context; action = $e.action; index = $(if ($ok) { $hit[0].index } else { '-' }); ok = $ok }
        }
        # 표에 없는 내장 바인딩(있으면 실패: 표 밖의 키를 넣은 것).
        $extra = @($builtin | Where-Object { $b = $_; -not ($expected | Where-Object { $_.keys -eq $b.keys -and $_.context -eq $b.context -and $_.action -eq $b.action }) })
        foreach ($x in $extra) { Fail 'base' "R-1 표 밖의 내장 바인딩: $($x.keys) [$($x.context)] $($x.action)" }
        $res.r1 = [ordered]@{ expected = $expected.Count; matched = @($rows | Where-Object ok).Count; builtin = $builtin.Count; extra = $extra.Count }
        $script:r1Rows = $rows
        $script:r1Extra = $extra
        $script:r1Builtin = $builtin
        $script:r1Kit = @($bindings | Where-Object { $_.source -eq 'gpui-kit' })

        # R-3: 같은 키를 포커스 자리마다. 처음 포커스는 가운데(center).
        $k = $res.keys
        $k.Add((Invoke-Key 'base' 'delete' 'none' $null 'center: Workspace 에는 Delete 바인딩이 없다')) | Out-Null
        $k.Add((Invoke-Key 'base' 'ctrl-b' 'workspace::ToggleLeftDock' 'Workspace' 'I-022 Dock 닫기')) | Out-Null
        $k.Add((Invoke-Key 'base' 'ctrl-b' 'workspace::ToggleLeftDock' 'Workspace' 'I-022 Dock 다시 열기')) | Out-Null
        $k.Add((Invoke-Key 'base' 'ctrl-k ctrl-o' 'workspace::Open' 'Workspace' 'A-13.1 chord')) | Out-Null
        $k.Add((Invoke-Key 'base' 'f10' 'app_menu::Toggle' 'Workspace' 'I-310')) | Out-Null
        $k.Add((Invoke-Key 'base' 'ctrl-alt-j' 'multi_workspace::ToggleWorkspaceSidebar' 'Workspace' 'I-024')) | Out-Null
        $k.Add((Invoke-Key 'base' 'ctrl-alt-;' 'multi_workspace::FocusWorkspaceSidebar' 'Workspace' 'I-024: 사이드바로 포커스')) | Out-Null
        $k.Add((Invoke-Key 'base' 'down' 'menu::SelectNext' 'Sidebar' 'A-17.3')) | Out-Null
        $k.Add((Invoke-Key 'base' 'up' 'menu::SelectPrevious' 'Sidebar' 'A-17.3')) | Out-Null
        $k.Add((Invoke-Key 'base' 'enter' 'menu::Confirm' 'Sidebar' 'A-17.4')) | Out-Null
        $k.Add((Invoke-Key 'base' 'delete' 'project_panel::RemoveFromProject' 'Sidebar' 'R-3 Delete: 사이드바 = 등록 해제')) | Out-Null
        $k.Add((Invoke-Key 'base' 'ctrl-alt-;' 'multi_workspace::FocusWorkspaceSidebar' 'Sidebar' '가운데로 돌아가기')) | Out-Null
        $k.Add((Invoke-Key 'base' 'ctrl-shift-e' 'project_panel::ToggleFocus' 'Workspace' 'I-023: 프로젝트 패널로 포커스')) | Out-Null
        foreach ($t in @(
                @('delete', 'project_panel::Trash', 'R-3 Delete: 프로젝트 패널 = 휴지통'),
                @('backspace', 'project_panel::Trash', 'I-039'),
                @('shift-delete', 'project_panel::Delete', 'I-040'),
                @('ctrl-delete', 'project_panel::Delete', 'I-040'),
                @('ctrl-n', 'project_panel::NewFile', 'R-3 Ctrl-N: 패널 = 새 파일(menu::SelectNext 보다 나중 등록)'),
                @('alt-n', 'project_panel::NewDirectory', 'I-036'),
                @('ctrl-c', 'project_panel::Copy', 'I-037 (menu::Cancel 보다 나중 등록)'),
                @('ctrl-x', 'project_panel::Cut', 'I-037'),
                @('ctrl-v', 'project_panel::Paste', 'I-037'),
                @('shift-insert', 'project_panel::Paste', 'I-037'),
                @('enter', 'project_panel::Rename', 'I-034 (menu::Confirm 보다 나중 등록)'),
                @('f2', 'project_panel::Rename', 'I-034'),
                @('space', 'project_panel::Open', 'I-033 not_editing'),
                @('down', 'menu::SelectNext', 'I-030 ProjectPanel + menu'),
                @('home', 'menu::SelectFirst', 'I-030'),
                @('end', 'menu::SelectLast', 'I-030'),
                @('tab', 'menu::SelectNext', 'I-030 Tab'),
                @('escape', 'menu::Cancel', 'I-035'),
                @('left', 'project_panel::CollapseSelectedEntry', 'I-031'),
                @('right', 'project_panel::ExpandSelectedEntry', 'I-031'),
                @('ctrl-left', 'project_panel::CollapseAllEntries', 'I-032'),
                @('ctrl-right', 'project_panel::ExpandAllEntries', 'I-032'),
                @('shift-up', 'project_panel::SelectPreviousExtend', 'I-043'),
                @('shift-down', 'project_panel::SelectNextExtend', 'I-043'),
                @('alt-shift-c', 'workspace::CopyPath', 'I-041'),
                @('ctrl-k ctrl-shift-c', 'workspace::CopyRelativePath', 'I-041 chord'),
                @('shift-f10', 'project_panel::DeployContextMenu', 'I-042'),
                @('menu', 'project_panel::DeployContextMenu', 'I-042 Menu 키')
            )) {
            $k.Add((Invoke-Key 'base' $t[0] $t[1] 'ProjectPanel' $t[2])) | Out-Null
        }
        $k.Add((Invoke-Key 'base' 'ctrl-shift-e' 'project_panel::ToggleFocus' 'ProjectPanel' '가운데로 돌아가기')) | Out-Null
        # I-704 표시: 같은 액션이라도 자리마다 가려진 키는 빠진다.
        $d = $res.display
        Check-Display 'base' $d 1 'center' 'workspace::ToggleLeftDock' 'Ctrl-B'
        Check-Display 'base' $d 1 'project_panel' 'menu::Cancel' 'Escape'
        Check-Display 'base' $d 1 'project_panel' 'menu::Confirm' '<none>'
        Check-Display 'base' $d 1 'sidebar' 'menu::Confirm' 'Enter'
        Check-Display 'base' $d 1 'center' 'project_panel::Trash' '<none>'
        Check-Notifications 'base' $res 1 @()
    }

    # ---------------------------------------------------------------- override: R-2 덮어쓰기
    Run-Case 'override' @'
[
  { "context": "Workspace", "bindings": { "ctrl-b": "project_panel::ToggleFocus" } }
]
'@ {
        param($res)
        $user = @(Get-Lines '^\[dev\] binding seq=1 ' | ForEach-Object { Parse-Binding $_ } | Where-Object source -eq 'user')
        $res.userBindings = @($user | ForEach-Object { "$($_.keys) [$($_.context)] $($_.action)" })
        if ($user.Count -ne 1) { Fail 'override' "사용자 바인딩 수 $($user.Count) (기대 1)" }
        $res.keys.Add((Invoke-Key 'override' 'ctrl-b' 'project_panel::ToggleFocus' 'Workspace' '사용자 액션이 실행된다')) | Out-Null
        $res.keys.Add((Invoke-Key 'override' 'ctrl-b' 'project_panel::ToggleFocus' 'ProjectPanel' '패널에서도 Workspace 의 사용자 바인딩')) | Out-Null
        Check-Display 'override' $res.display 1 'center' 'project_panel::ToggleFocus' 'Ctrl-B'
        Check-Display 'override' $res.display 1 'center' 'workspace::ToggleLeftDock' '<none>'
        Check-Notifications 'override' $res 1 @()
    }

    # ---------------------------------------------------------------- null: R-2 해제
    Run-Case 'null' @'
[
  { "context": "Workspace", "bindings": { "ctrl-b": null } },
  { "context": "ProjectPanel", "bindings": { "delete": null } }
]
'@ {
        param($res)
        $user = @(Get-Lines '^\[dev\] binding seq=1 ' | ForEach-Object { Parse-Binding $_ } | Where-Object source -eq 'user')
        $res.userBindings = @($user | ForEach-Object { "$($_.keys) [$($_.context)] $($_.action)" })
        $res.keys.Add((Invoke-Key 'null' 'ctrl-b' 'none' 'Workspace' 'null: 내장 ToggleLeftDock 가 실행되지 않는다')) | Out-Null
        $res.keys.Add((Invoke-Key 'null' 'ctrl-shift-e' 'project_panel::ToggleFocus' 'Workspace' '패널로 포커스')) | Out-Null
        $res.keys.Add((Invoke-Key 'null' 'delete' 'none' 'ProjectPanel' 'null: 패널의 Trash 가 실행되지 않는다')) | Out-Null
        $res.keys.Add((Invoke-Key 'null' 'backspace' 'project_panel::Trash' 'ProjectPanel' '해제하지 않은 다른 키는 그대로')) | Out-Null
        $res.keys.Add((Invoke-Key 'null' 'ctrl-shift-e' 'project_panel::ToggleFocus' 'ProjectPanel' '가운데로')) | Out-Null
        $res.keys.Add((Invoke-Key 'null' 'ctrl-alt-;' 'multi_workspace::FocusWorkspaceSidebar' 'Workspace' '사이드바로')) | Out-Null
        $res.keys.Add((Invoke-Key 'null' 'delete' 'project_panel::RemoveFromProject' 'Sidebar' 'null 은 그 컨텍스트에서만: 사이드바 Delete 는 그대로')) | Out-Null
        Check-Display 'null' $res.display 1 'center' 'workspace::ToggleLeftDock' '<none>'
        Check-Display 'null' $res.display 1 'project_panel' 'project_panel::Trash' 'Backspace'
        Check-Display 'null' $res.display 1 'sidebar' 'project_panel::RemoveFromProject' 'Delete'
        Check-Notifications 'null' $res 1 @()
    }

    # ---------------------------------------------------------------- unknown: R-2 없는 액션 이름
    Run-Case 'unknown' @'
[
  { "context": "Workspace", "bindings": { "ctrl-b": "workspace::NoSuchAction", "f10": "workspace::ToggleLeftDock" } },
  { "bindings": { "ctrl-alt-j": "zed::Unknown" } }
]
'@ {
        param($res)
        Check-Notifications 'unknown' $res 1 @("Action 'workspace::NoSuchAction' not found", "Action 'zed::Unknown' not found")
        Save-Window 'unknown-notification'
        $res.keys.Add((Invoke-Key 'unknown' 'f10' 'workspace::ToggleLeftDock' 'Workspace' '오류 항목만 빼고 나머지는 적용')) | Out-Null
        $res.keys.Add((Invoke-Key 'unknown' 'ctrl-b' 'workspace::ToggleLeftDock' 'Workspace' '잘못된 항목은 무시되어 내장 키 그대로')) | Out-Null
        $res.keys.Add((Invoke-Key 'unknown' 'ctrl-alt-j' 'multi_workspace::ToggleWorkspaceSidebar' 'Workspace' '잘못된 항목은 무시')) | Out-Null
    }

    # ---------------------------------------------------------------- jsonc: R-2 주석·끝 쉼표
    Run-Case 'jsonc' @'
// 사용자 키맵 (주석 허용)
[
  /* F10 을 프로젝트 패널 포커스로 */
  {
    "context": "Workspace",
    "bindings": {
      "f10": "project_panel::ToggleFocus", // 줄 끝 주석
    },
  },
]
'@ {
        param($res)
        Check-Notifications 'jsonc' $res 1 @()
        $res.keys.Add((Invoke-Key 'jsonc' 'f10' 'project_panel::ToggleFocus' 'Workspace' '주석·끝 쉼표가 있어도 읽힌다')) | Out-Null
        Check-Display 'jsonc' $res.display 1 'center' 'app_menu::Toggle' '<none>'
    }

    # ---------------------------------------------------------------- broken: 형식 오류
    Run-Case 'broken' @'
[ { "context": "Workspace", "bindings": { "ctrl-b": "workspace::ToggleLeftDock" }
'@ {
        param($res)
        Check-Notifications 'broken' $res 1 @('Failed to load keymap file')
        Save-Window 'broken-notification'
        $res.keys.Add((Invoke-Key 'broken' 'ctrl-b' 'workspace::ToggleLeftDock' 'Workspace' '내장 키맵은 그대로')) | Out-Null
    }

    # ---------------------------------------------------------------- order: R-3 깊이·순서
    Run-Case 'order' @'
[
  { "context": "Workspace", "bindings": { "f10": "workspace::ToggleLeftDock" } },
  { "context": "Workspace", "bindings": { "f10": "project_panel::ToggleFocus" } },
  { "context": "Workspace", "bindings": { "delete": "workspace::ToggleLeftDock" } }
]
'@ {
        param($res)
        $res.keys.Add((Invoke-Key 'order' 'f10' 'project_panel::ToggleFocus' 'Workspace' '같은 깊이 두 번: 나중 것이 이긴다')) | Out-Null
        $res.keys.Add((Invoke-Key 'order' 'f10' 'project_panel::ToggleFocus' 'ProjectPanel' '패널에서 다시: 가운데로')) | Out-Null
        $res.keys.Add((Invoke-Key 'order' 'delete' 'workspace::ToggleLeftDock' 'Workspace' 'center: Workspace 의 사용자 Delete')) | Out-Null
        $res.keys.Add((Invoke-Key 'order' 'delete' 'workspace::ToggleLeftDock' 'Workspace' 'Dock 다시 열기')) | Out-Null
        $res.keys.Add((Invoke-Key 'order' 'ctrl-alt-;' 'multi_workspace::FocusWorkspaceSidebar' 'Workspace' '사이드바로')) | Out-Null
        $res.keys.Add((Invoke-Key 'order' 'delete' 'project_panel::RemoveFromProject' 'Sidebar' '깊이가 다르면 깊은 쪽(내장 Sidebar)이 나중 등록(사용자 Workspace)보다 이긴다')) | Out-Null
        Check-Display 'order' $res.display 1 'center' 'project_panel::ToggleFocus' 'F10'
        Check-Notifications 'order' $res 1 @()
    }

    # ---------------------------------------------------------------- startup: R-4 시작 구간(리뷰 1회차 ②)
    # 앱이 최초 로드를 마친 직후(--dev-keymap-startup-delay 로 3초 멈춘 동안) 파일을 바꿔 저장한다.
    # 감시가 최초 로드 전에 등록되어 있어야 이 저장을 잡아 seq=2 로 다시 읽는다.
    $startupText = @'
[
  { "context": "Workspace", "bindings": { "alt-b": "workspace::ToggleLeftDock" } }
]
'@
    Run-Case 'startup' @'
[]
'@ {
        param($res)
        $res.startupWrite = $script:startupWrite
        if (-not (Wait-Line '^\[dev\] display-end seq=2' 10)) { Fail 'startup' '최초 로드 직후의 저장을 다시 읽지 않았다(seq=2 없음)' }
        Check-Display 'startup' $res.display 2 'center' 'workspace::ToggleLeftDock' 'Alt-B'
        $res.keys.Add((Invoke-Key 'startup' 'alt-b' 'workspace::ToggleLeftDock' 'Workspace' '시작 구간에 저장한 키가 동작')) | Out-Null
        Check-Notifications 'startup' $res 2 @()
    } @('--dev-keymap-startup-delay', '3000') {
        # 앱이 최초 로드를 마치고 멈춘 것을 확인한 뒤 저장한다.
        $script:startupWrite = 'not written'
        if (Wait-Line '^\[dev\] keymap-startup-pause ' 20) {
            Write-Keymap $startupText
            Set-Content -LiteralPath (Join-Path $out 'startup-keymap-2.json') -Value $startupText -Encoding utf8 -NoNewline
            $script:startupWrite = 'written during startup pause'
        }
        else { throw 'startup: keymap-startup-pause 줄이 나오지 않았다' }
    }

    # ---------------------------------------------------------------- reload: R-4
    Run-Case 'reload' @'
[]
'@ {
        param($res)
        $res.keys.Add((Invoke-Key 'reload' 'ctrl-b' 'workspace::ToggleLeftDock' 'Workspace' '바꾸기 전')) | Out-Null
        $res.keys.Add((Invoke-Key 'reload' 'ctrl-b' 'workspace::ToggleLeftDock' 'Workspace' 'Dock 다시 열기')) | Out-Null
        Check-Display 'reload' $res.display 1 'center' 'workspace::ToggleLeftDock' 'Ctrl-B'

        # 1) 제자리 덮어쓰기 저장.
        $t0 = [System.Diagnostics.Stopwatch]::StartNew()
        $text2 = @'
[
  { "context": "Workspace", "bindings": { "ctrl-b": null, "alt-b": "workspace::ToggleLeftDock" } }
]
'@
        Write-Keymap $text2
        Set-Content -LiteralPath (Join-Path $out 'reload-keymap-2.json') -Value $text2 -Encoding utf8 -NoNewline
        if (-not (Wait-Line '^\[dev\] display-end seq=2' 10)) { Fail 'reload' '저장 뒤 10초 안에 다시 읽지 않았다(seq=2)' } else { $res.reloadMs2 = [int]$t0.Elapsed.TotalMilliseconds }
        Check-Display 'reload' $res.display 2 'center' 'workspace::ToggleLeftDock' 'Alt-B'
        $res.keys.Add((Invoke-Key 'reload' 'alt-b' 'workspace::ToggleLeftDock' 'Workspace' '새 키가 다시 띄우지 않고 동작')) | Out-Null
        $res.keys.Add((Invoke-Key 'reload' 'ctrl-b' 'none' 'Workspace' '옛 키는 해제')) | Out-Null

        # 2) 바꿔치기 저장(다른 파일에 쓴 뒤 이름 바꾸기, 편집기 저장 방식).
        $t1 = [System.Diagnostics.Stopwatch]::StartNew()
        $text3 = @'
[
  { "context": "Workspace", "bindings": { "ctrl-alt-b": "workspace::ToggleLeftDock" } }
]
'@
        # 바꿔치기용 파일은 이번 실행만의 이름을 쓴다. 이미 있는 keymap.json.tmp 같은 다른 파일은 건드리지 않는다.
        $tmp = "$keymapPath.{0}.tmp" -f [guid]::NewGuid()
        $script:createdTemps.Add($tmp) | Out-Null
        [System.IO.File]::WriteAllText($tmp, $text3, [System.Text.UTF8Encoding]::new($false))
        Move-Item -LiteralPath $tmp -Destination $keymapPath -Force
        Set-Content -LiteralPath (Join-Path $out 'reload-keymap-3.json') -Value $text3 -Encoding utf8 -NoNewline
        if (-not (Wait-Line '^\[dev\] display-end seq=3' 10)) { Fail 'reload' '바꿔치기 뒤 10초 안에 다시 읽지 않았다(seq=3)' } else { $res.reloadMs3 = [int]$t1.Elapsed.TotalMilliseconds }
        Check-Display 'reload' $res.display 3 'center' 'workspace::ToggleLeftDock' 'Ctrl-Alt-B'
        $res.keys.Add((Invoke-Key 'reload' 'ctrl-alt-b' 'workspace::ToggleLeftDock' 'Workspace' '바꿔치기 뒤 새 키')) | Out-Null
        $res.keys.Add((Invoke-Key 'reload' 'ctrl-b' 'workspace::ToggleLeftDock' 'Workspace' 'null 을 뺐으므로 내장 Ctrl-B 가 돌아온다')) | Out-Null
        $res.keys.Add((Invoke-Key 'reload' 'alt-b' 'none' 'Workspace' '지운 키는 더 듣지 않는다')) | Out-Null
        foreach ($s in 2, 3) { Check-Notifications 'reload' $res $s @() }
    }
}
catch {
    $results.failures += $_.Exception.Message
}
finally {
    # 정리 단계(리뷰 2회차, D-029). 사용자 keymap.json 복원을 가장 먼저 한다. 나머지 정리는 하나씩 따로 try/catch 해
    # 예외를 $results.errors 에 모으고, 어느 정리가 실패해도 다음 정리는 이어서 한다.

    # 1) 사용자 keymap.json 복원. 복원 결과(해시)는 안쪽 finally 에서 반드시 기록한다.
    try {
        try {
            if ($hadKeymap) {
                # 백업에 실패했다면 시험 내용으로 바꾸기 전에 멈춘 것이므로(백업이 시작의 첫 단계다) 원본이 그대로다.
                if ($backupDone) { Copy-Item -LiteralPath $backupPath -Destination $keymapPath -Force }
            }
            else { Remove-Keymap }
        }
        finally {
            $existsAfter = Test-Path -LiteralPath $keymapPath
            $userHashAfter = '<absent>'
            if ($existsAfter) {
                try { $userHashAfter = (Get-FileHash -LiteralPath $keymapPath -Algorithm SHA256).Hash }
                catch { $userHashAfter = '<unreadable>'; $results.errors += "user keymap 해시 읽기: $($_.Exception.Message)" }
            }
            $results.userKeymap = [ordered]@{
                path = $keymapPath; existedBefore = $hadKeymap; hashBefore = $userHashBefore
                existsAfter = $existsAfter; hashAfter = $userHashAfter; restored = ($userHashAfter -eq $userHashBefore)
                backupPath = $(if ($backupDone) { $backupPath } else { $null })
            }
            if ($userHashAfter -ne $userHashBefore) { $results.failures += "사용자 keymap.json 이 실행 전과 다르다 (전 $userHashBefore, 후 $userHashAfter)" }
        }
    }
    catch { $results.errors += "user keymap 복원: $($_.Exception.Message)" }

    # 2) 백업 지우기. 복원이 확인된 때만 지운다. 아니면 백업을 남겨 사람이 되돌릴 수 있게 한다(경로는 userKeymap.backupPath).
    if ($backupDone -and $results.userKeymap -and $results.userKeymap.restored) {
        try { Remove-Item -LiteralPath $backupPath -Force } catch { $results.errors += "백업 지우기: $($_.Exception.Message)" }
    }

    # 3) 소유하지 않은 keymap.json.tmp 가 그대로인지 확인.
    if ($foreignHash) {
        try {
            $after = if (Test-Path -LiteralPath $foreignTmp) { (Get-FileHash -LiteralPath $foreignTmp -Algorithm SHA256).Hash } else { '<deleted>' }
            $results.foreignTmp = [ordered]@{ path = $foreignTmp; existedBefore = $foreignExisted; hashBefore = $foreignHash; hashAfter = $after; unchanged = ($after -eq $foreignHash) }
            if ($after -ne $foreignHash) { $results.failures += "keymap.json.tmp(소유하지 않은 파일)가 바뀌거나 지워졌다" }
        }
        catch { $results.errors += "keymap.json.tmp 해시 확인: $($_.Exception.Message)" }
    }

    # 4) 이 스크립트가 만든 표지 파일 지우기.
    if ($sentinelCreated) {
        try { if (Test-Path -LiteralPath $foreignTmp) { Remove-Item -LiteralPath $foreignTmp -Force } }
        catch { $results.errors += "표지 파일 지우기: $($_.Exception.Message)" }
    }

    # 5) 이번 실행이 만든 GUID 임시 파일만 하나씩 지운다(바꿔치기가 끝났으면 이미 없다).
    foreach ($t in $script:createdTemps) {
        try { if (Test-Path -LiteralPath $t) { Remove-Item -LiteralPath $t -Force } }
        catch { $results.errors += "임시 파일 지우기 ${t}: $($_.Exception.Message)" }
    }

    # 정리 오류도 실패로 센다(종료 코드 1).
    foreach ($e in $results.errors) { $results.failures += "정리 오류: $e" }
}

# ---------------------------------------------------------------- R-1 대조표
if ($script:r1Rows) {
    $md = [System.Collections.Generic.List[string]]::new()
    $md.Add('# R-1 바인딩 대조표 (v0.2 Phase 1)')
    $md.Add('')
    $md.Add(('생성: tools/verify-v02-phase1.ps1, {0}. 앱 출력: base-stdout.txt 의 `[dev] binding seq=1` 줄(source=builtin).' -f (Get-Date).ToString('yyyy-MM-dd HH:mm')))
    $md.Add('기대 표: r1-expected.tsv (01-zed 02-INTERACTION 1절·9절 I-517, 04-APP-SPEC A-13.1·A-17 원문 키, 02 9.2절 키 열의 I-341·I-358(D-031 ③)).')
    $md.Add('')
    $md.Add(('- 기대 {0}줄, 일치 {1}줄, 앱 내장 바인딩 {2}개, 표 밖 내장 바인딩 {3}개.' -f $script:r1Rows.Count, @($script:r1Rows | Where-Object ok).Count, $script:r1Builtin.Count, $script:r1Extra.Count))
    $md.Add('- 기대 표의 I-030·I-035 줄(`menu` 컨텍스트)과 I-517 줄은 같은 앱 바인딩 하나에 대응한다. 프로젝트 패널 요소가 `ProjectPanel`·`menu`·`not_editing` 을 함께 컨텍스트로 가져(I-002) 이 바인딩이 패널에서도 듣는다.')
    $md.Add(('- 그 밖에 gpui-kit 이 넣은 바인딩 {0}개(source=gpui-kit)는 대조에서 뺐다(D-5 이후 변경, D-027 ③).' -f $script:r1Kit.Count))
    $md.Add('')
    $md.Add('| ID | 키 | 컨텍스트 | 액션 | 앱 index | 판정 |')
    $md.Add('| --- | --- | --- | --- | --- | --- |')
    foreach ($r in $script:r1Rows) {
        $md.Add(('| {0} | `{1}` | `{2}` | `{3}` | {4} | {5} |' -f $r.id, $r.keys, $r.context.Replace('|', '\|'), $r.action, $r.index, $(if ($r.ok) { '통과' } else { '실패' })))
    }
    if ($script:r1Extra.Count -gt 0) {
        $md.Add('')
        $md.Add('## 표 밖 내장 바인딩')
        foreach ($x in $script:r1Extra) { $md.Add("- ``$($x.keys)`` [$($x.context)] $($x.action)") }
    }
    Set-Content -LiteralPath (Join-Path $out 'r1-bindings.md') -Value ($md -join "`n") -Encoding utf8
}

$results.finishedAt = (Get-Date).ToString('o')
$results.passed = ($results.failures.Count -eq 0)
$results | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $out 'results.json') -Encoding utf8
"cases: $($results.cases.Keys -join ', ')"
"failures: $($results.failures.Count)"
"foreign key lines (warning): $($results.foreignKeys.Count)"
"cleanup errors: $($results.errors.Count)"
"user keymap: before=$($results.userKeymap.hashBefore) after=$($results.userKeymap.hashAfter) restored=$($results.userKeymap.restored)"
$results.failures | ForEach-Object { "  - $_" }
if ($results.failures.Count -gt 0) { exit 1 }

#Requires -Version 7
<#
.SYNOPSIS
  ORDER-04 V3 화면 검증(UI 실측) 입력·캡처 스크립트.
  (gpui-checker 작성, leader가 화면 차례 안에서 실행한다.)

.DESCRIPTION
  - workbench-gpui를 화면 검증 조건(클라이언트 1440×852, 100% DPI, 마크다운 픽스처)으로 구동.
  - I-20(경로 역슬래시 '\' 표시)의 각 위치별 상태를 만들어 Screen 방식으로 캡처한다:
    * I20-tree: 파일 트리 압축 폴더 (branch\nested)
    * I20-tooltip: 트리 항목 툴팁 (전체 경로)
    * I20-dialog-unsaved: 탭 닫기 미저장 확인 대화 상자 (상대 경로 포함)
    * I20-dialog-delete: 파일 삭제 확인 대화 상자 (안전하게 열고 Esc로 닫기만 함)
    * I20-title: 타이틀 바 폴더 이름
  - ORDER-03 남은 1건(S-9-5digit)을 재측정한다:
    * 5자리 fixture(10,050줄)를 연 뒤 문서가 로드될 때까지 기다린다(최대 20초 폴링).
    * Ctrl+End 후 5자리 줄 번호가 보이는지 검증하고 캡처한다.
  - 자신이 실행한 프로세스(PID)만 닫으며, 이미 실행 중인 다른 프로세스/창은 절대 건드리지 않는다.
  - Zed는 띄우지 않는다 (tauri 기준 비교, Zed 불필요).
  - session.ps1 -Action Stop으로 앱 데이터 및 픽스처를 완전 복원한다.

.PARAMETER Out
  출력 디렉터리 (기본값: specs\v0.5\verify\reviews\measure-ORDER-04).

.PARAMETER AppExe
  workbench-gpui 실행 파일 경로.

.PARAMETER FixturePath
  측정에 사용할 마크다운 파일 경로 (미지정 시 자동 생성).

.PARAMETER FiveDigitFixturePath
  5자리 줄 번호 측정용 마크다운 파일 경로 (10,050줄, 미지정 시 자동 생성).

.PARAMETER DryRunStdout
  stdout 덤프를 기반으로 좌표 및 프로브 계산만 검증하는 모드 (프로세스 구동 안 함).

.PARAMETER Steps
  실행할 단계 목록 (예: I20-tree,I20-tooltip,I20-dialog-unsaved,I20-dialog-delete,I20-title,S-9-5digit).

.PARAMETER Skip
  건너뛸 단계 목록.
#>
[CmdletBinding()]
param(
    [string]$Out = 'specs\v0.5\verify\reviews\measure-ORDER-04',
    [string]$AppExe = 'D:\projects\workbench-gpui\target\debug\workbench-gpui.exe',
    [string]$FixturePath,
    [string]$FiveDigitFixturePath,
    [string]$DryRunStdout,
    [string[]]$Steps = @(),
    [string[]]$Skip = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$global:LASTEXITCODE = 0
Set-Location 'D:\projects\workbench-gpui'

$Out = [System.IO.Path]::GetFullPath($Out, (Get-Location).Path)
New-Item -ItemType Directory -Force $Out | Out-Null
$logFile = Join-Path $Out 'log.txt'

$global:summary = [ordered]@{
    "app" = [ordered]@{}
}

$normalizedSteps = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
if ($Steps) {
    foreach ($item in $Steps) {
        foreach ($sub in ($item -split ',')) {
            $t = $sub.Trim()
            if ($t) { [void]$normalizedSteps.Add($t) }
        }
    }
}

$normalizedSkip = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
if ($Skip) {
    foreach ($item in $Skip) {
        foreach ($sub in ($item -split ',')) {
            $t = $sub.Trim()
            if ($t) { [void]$normalizedSkip.Add($t) }
        }
    }
}

function Should-RunStep([string]$stepKey) {
    if ($normalizedSkip.Contains($stepKey)) { return $false }
    foreach ($k in $normalizedSkip) {
        if ($stepKey -eq $k -or $stepKey -like "$k-*") { return $false }
    }
    if ($normalizedSteps.Count -gt 0) {
        if ($normalizedSteps.Contains($stepKey)) { return $true }
        foreach ($s in $normalizedSteps) {
            if ($stepKey -like "$s-*" -or $s -like "$stepKey-*") { return $true }
        }
        return $false
    }
    return $true
}

function Should-Skip([string]$stepKey) {
    return (-not (Should-RunStep $stepKey))
}

function L([string]$msg) {
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
    $line = "$ts $msg"
    Write-Host $line
    if (-not $DryRunStdout) {
        $line | Add-Content -LiteralPath $logFile -Encoding utf8
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    L "=== ORDER-04 V3 Capture Script Started (Out=$Out) ==="
}

# ---------------------------------------------------------------------------
# 1. Native API Definition (Order04Native)
# ---------------------------------------------------------------------------
if (-not ('Order04Native' -as [type])) {
    Add-Type -ReferencedAssemblies @('System.Runtime', 'System.Collections', 'System.Threading', 'System.Threading.Thread', 'System.Runtime.InteropServices') -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

public static class Order04Native {
    [StructLayout(LayoutKind.Sequential)]
    public struct MOUSEINPUT { public int dx; public int dy; public uint mouseData; public uint dwFlags; public uint time; IntPtr dwExtraInfo; }
    [StructLayout(LayoutKind.Sequential)]
    public struct KEYBDINPUT { public ushort wVk; public ushort wScan; public uint dwFlags; public uint time; IntPtr dwExtraInfo; }
    [StructLayout(LayoutKind.Explicit)]
    public struct InputUnion { [FieldOffset(0)] public MOUSEINPUT mi; [FieldOffset(0)] public KEYBDINPUT ki; }
    [StructLayout(LayoutKind.Sequential)]
    public struct INPUT { public uint type; public InputUnion u; }
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)]
    public struct POINT { public int X, Y; }

    const uint INPUT_MOUSE = 0, INPUT_KEYBOARD = 1;
    const uint KEYEVENTF_EXTENDEDKEY = 0x1, KEYEVENTF_KEYUP = 0x2;
    const uint MOUSEEVENTF_MOVE = 0x1, MOUSEEVENTF_LEFTDOWN = 0x2, MOUSEEVENTF_LEFTUP = 0x4;
    const uint MOUSEEVENTF_WHEEL = 0x800;
    const uint MOUSEEVENTF_VIRTUALDESK = 0x4000, MOUSEEVENTF_ABSOLUTE = 0x8000;
    const int SM_XVIRTUALSCREEN = 76, SM_YVIRTUALSCREEN = 77, SM_CXVIRTUALSCREEN = 78, SM_CYVIRTUALSCREEN = 79;

    [DllImport("user32.dll", SetLastError = true)] static extern uint SendInput(uint n, INPUT[] inputs, int size);
    [DllImport("user32.dll")] static extern uint MapVirtualKey(uint code, uint mapType);
    [DllImport("user32.dll")] static extern int GetSystemMetrics(int index);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr hWnd, ref POINT p);
    [DllImport("user32.dll")] public static extern bool IsZoomed(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int cmd);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
    [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr ctx);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
    public const uint WM_CLOSE = 0x0010;
    [DllImport("user32.dll")] public static extern IntPtr GetWindow(IntPtr hWnd, uint cmd);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr hWnd, StringBuilder sb, int max);
    [DllImport("user32.dll", CharSet = CharSet.Auto)] static extern int GetClassName(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);

    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] static extern bool EnumWindows(EnumWindowsProc cb, IntPtr lParam);

    public static string Title(IntPtr h) { var sb = new StringBuilder(512); GetWindowText(h, sb, sb.Capacity); return sb.ToString(); }
    public static string ClassName(IntPtr h) { var sb = new StringBuilder(64); GetClassName(h, sb, sb.Capacity); return sb.ToString(); }

    public static System.Collections.Generic.List<IntPtr> GetProcessTopLevelWindows(uint[] pids) {
        var list = new System.Collections.Generic.List<IntPtr>();
        var pidSet = new System.Collections.Generic.HashSet<uint>(pids);
        EnumWindows((h, l) => {
            uint p; GetWindowThreadProcessId(h, out p);
            if (pidSet.Contains(p) && IsWindowVisible(h) && GetWindow(h, 4 /* GW_OWNER */) == IntPtr.Zero) {
                list.Add(h);
            }
            return true;
        }, IntPtr.Zero);
        return list;
    }

    public static IntPtr FindDialog(uint pid) {
        IntPtr result = IntPtr.Zero;
        EnumWindows((h, l) => {
            uint p; GetWindowThreadProcessId(h, out p);
            if (p != pid || !IsWindowVisible(h)) return true;
            if (ClassName(h) == "#32770") {
                result = h;
                return false;
            }
            return true;
        }, IntPtr.Zero);
        return result;
    }

    static void Send(INPUT i) {
        if (SendInput(1, new[] { i }, Marshal.SizeOf(typeof(INPUT))) != 1)
            throw new InvalidOperationException("SendInput failed");
    }

    static INPUT M(uint flags, int x, int y, uint data) {
        int vx = GetSystemMetrics(SM_XVIRTUALSCREEN), vy = GetSystemMetrics(SM_YVIRTUALSCREEN);
        int vw = GetSystemMetrics(SM_CXVIRTUALSCREEN), vh = GetSystemMetrics(SM_CYVIRTUALSCREEN);
        var i = new INPUT { type = INPUT_MOUSE };
        i.u.mi.dx = (int)Math.Round((x - vx) * 65535.0 / Math.Max(1, vw - 1));
        i.u.mi.dy = (int)Math.Round((y - vy) * 65535.0 / Math.Max(1, vh - 1));
        i.u.mi.mouseData = data;
        i.u.mi.dwFlags = flags | MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_VIRTUALDESK;
        return i;
    }

    public static void MoveTo(int x, int y) { SetCursorPos(x, y); Send(M(0, x, y, 0)); }

    public static void Click(int x, int y) {
        MoveTo(x, y); Thread.Sleep(60);
        Send(M(MOUSEEVENTF_LEFTDOWN, x, y, 0)); Thread.Sleep(40);
        Send(M(MOUSEEVENTF_LEFTUP, x, y, 0));
    }

    public static void DoubleClick(int x, int y) {
        MoveTo(x, y); Thread.Sleep(60);
        Send(M(MOUSEEVENTF_LEFTDOWN, x, y, 0)); Thread.Sleep(30);
        Send(M(MOUSEEVENTF_LEFTUP, x, y, 0)); Thread.Sleep(60);
        Send(M(MOUSEEVENTF_LEFTDOWN, x, y, 0)); Thread.Sleep(30);
        Send(M(MOUSEEVENTF_LEFTUP, x, y, 0));
    }

    public static void Wheel(int x, int y, int delta) {
        MoveTo(x, y); Thread.Sleep(60);
        Send(M(MOUSEEVENTF_WHEEL, x, y, unchecked((uint)delta)));
    }

    static bool IsExtended(ushort vk) {
        switch (vk) { case 0x21: case 0x22: case 0x23: case 0x24: case 0x25: case 0x26: case 0x27: case 0x28: case 0x2D: case 0x2E: case 0x5D: return true; }
        return false;
    }

    static INPUT K(ushort vk, bool up) {
        var i = new INPUT { type = INPUT_KEYBOARD };
        i.u.ki.wVk = vk;
        i.u.ki.wScan = (ushort)MapVirtualKey(vk, 0);
        i.u.ki.dwFlags = (up ? KEYEVENTF_KEYUP : 0) | (IsExtended(vk) ? KEYEVENTF_EXTENDEDKEY : 0);
        return i;
    }

    public static void KeyPress(ushort vk) {
        Send(K(vk, false)); Thread.Sleep(30);
        Send(K(vk, true)); Thread.Sleep(30);
    }

    public static void KeyCombo(ushort[] mods, ushort key) {
        foreach (var m in mods) { Send(K(m, false)); Thread.Sleep(20); }
        Send(K(key, false)); Thread.Sleep(30);
        Send(K(key, true)); Thread.Sleep(20);
        for (int n = mods.Length - 1; n >= 0; n--) { Send(K(mods[n], true)); Thread.Sleep(20); }
    }
}
'@
}

[void][Order04Native]::SetThreadDpiAwarenessContext([IntPtr]::new(-4))

# ---------------------------------------------------------------------------
# 2. Fixture Generation
# ---------------------------------------------------------------------------
if (-not $DryRunStdout) {
    if (-not $FixturePath -or -not (Test-Path -LiteralPath $FixturePath)) {
        $FixturePath = Join-Path $Out 'order04-fixture.md'
        $fixtureText = @'
# ORDER-04 Verification Fixture
This fixture is used for verifying path backslash display and 5-digit gutter re-measurement.
Nested files are located under branch/nested directory.
'@
        $fixtureText | Set-Content -LiteralPath $FixturePath -Encoding utf8
    }

    if (-not $FiveDigitFixturePath -or -not (Test-Path -LiteralPath $FiveDigitFixturePath)) {
        $FiveDigitFixturePath = Join-Path $Out 'order04-5digit-fixture.md'
        L "Generating 5-digit fixture (10,050 lines) at '$FiveDigitFixturePath'..."
        $sb = [System.Text.StringBuilder]::new(700000)
        [void]$sb.AppendLine('# ORDER-04 5-Digit Line Number Verification Fixture')
        [void]$sb.AppendLine('This file contains 10,050 lines to verify the 5-digit gutter width (66px/101px).')
        for ($i = 3; $i -le 10050; $i++) {
            [void]$sb.AppendLine(("Line {0:D5}: measurement sample content for line geometry" -f $i))
        }
        [System.IO.File]::WriteAllText($FiveDigitFixturePath, $sb.ToString(), [System.Text.Encoding]::UTF8)
        L "5-digit fixture generation complete (lines=10,050, bytes=$((Get-Item $FiveDigitFixturePath).Length))."
    }
}

# ---------------------------------------------------------------------------
# 3. Layout Parser and Helper Functions
# ---------------------------------------------------------------------------
function Get-LatestSnapshot([string]$outDir, [string]$overrideFile) {
    $stdoutFile = if ($overrideFile) { $overrideFile } else { Join-Path $outDir 'app-stdout.txt' }
    if (-not (Test-Path -LiteralPath $stdoutFile)) { return $null }
    $lines = @(Get-Content -LiteralPath $stdoutFile -Encoding utf8)
    $end = -1
    $seq = 0
    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        if ($lines[$i] -match '^\[dev\] layout-snapshot-end seq=(\d+)') {
            $end = $i
            $seq = [int]$matches[1]
            break
        }
    }
    if ($end -lt 0) { return $null }
    $start = $end
    while ($start -ge 0 -and $lines[$start] -notmatch "^\[dev\] layout-snapshot seq=$seq ") { $start-- }
    if ($start -lt 0) { return $null }

    $boxes = [ordered]@{}
    $allBoxes = [System.Collections.Generic.List[object]]::new()
    foreach ($line in $lines[$start..$end]) {
        if ($line -match 'name=(\S+) bounds=([-\d.]+),([-\d.]+),([-\d.]+),([-\d.]+)') {
            $boxObj = [pscustomobject]@{
                name = $matches[1]
                x = [double]$matches[2]
                y = [double]$matches[3]
                w = [double]$matches[4]
                h = [double]$matches[5]
            }
            $boxes[$matches[1]] = $boxObj
            $allBoxes.Add($boxObj)
        }
    }
    return [pscustomobject]@{
        seq = $seq
        boxes = $boxes
        allBoxes = $allBoxes
    }
}

function Get-BoxScreenCoord([IntPtr]$hWnd, [string]$outDir, [string]$boxName, [string]$overrideFile) {
    $snap = Get-LatestSnapshot $outDir $overrideFile
    if (-not $snap) { return $null }
    $box = $null
    if ($snap.boxes.Contains($boxName)) {
        $box = $snap.boxes[$boxName]
    } else {
        foreach ($b in $snap.allBoxes) {
            if ($b.name -eq $boxName) { $box = $b; break }
        }
    }
    if (-not $box) { return $null }

    $clientPt = [Order04Native+POINT]::new()
    $clientPt.X = [int][Math]::Round($box.x + $box.w / 2.0)
    $clientPt.Y = [int][Math]::Round($box.y + $box.h / 2.0)

    if ($hWnd -ne [IntPtr]::Zero) {
        $screenPt = $clientPt
        [void][Order04Native]::ClientToScreen($hWnd, [ref]$screenPt)
        return [pscustomobject]@{ X = $screenPt.X; Y = $screenPt.Y; Box = $box }
    } else {
        return [pscustomobject]@{ X = $clientPt.X; Y = $clientPt.Y; Box = $box }
    }
}

function Get-TreeRowBoxByName([IntPtr]$hWnd, [string]$outDir, [string]$targetName, [string]$fixtureDir, [string]$overrideFile) {
    $stdoutFile = if ($overrideFile) { $overrideFile } else { Join-Path $outDir 'app-stdout.txt' }
    if (-not (Test-Path -LiteralPath $stdoutFile)) { return $null }
    $lines = @(Get-Content -LiteralPath $stdoutFile -Encoding utf8)
    $treeLine = $null
    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        if ($lines[$i] -match '^\[dev\] tree folder=\S+ .* rows=(.+)$') {
            $treeLine = $matches[1]
            break
        }
    }
    if (-not $treeLine) { return $null }

    $items = $treeLine -split '\t'
    $foundIx = -1
    for ($ix = 0; $ix -lt $items.Count; $ix++) {
        $parts = $items[$ix] -split '\|'
        if ($parts.Count -ge 1) {
            $label = $parts[0]
            if ($label -eq $targetName -or $label -like "*$targetName*") {
                $foundIx = $ix
                break
            }
        }
    }
    if ($foundIx -lt 0) { return $null }

    $boxName = ("tree-row-{0:D2}" -f $foundIx)
    $coord = Get-BoxScreenCoord $hWnd $outDir $boxName $overrideFile
    if ($coord) {
        return [pscustomobject]@{
            Index = $foundIx
            Box = $coord.Box
            X = $coord.X
            Y = $coord.Y
            Reason = "stdout [dev] tree rows parsing (label='$targetName')"
        }
    }
    return $null
}

function Ensure-Foreground([IntPtr]$hWnd, [string]$label) {
    if ($hWnd -eq [IntPtr]::Zero) { return }
    $fg = [Order04Native]::GetForegroundWindow()
    if ($fg -ne $hWnd) {
        [void][Order04Native]::SetForegroundWindow($hWnd)
        Start-Sleep -Milliseconds 300
    }
}

function Cap-Window([IntPtr]$hWnd, [string]$name, [string]$outDir) {
    $png = Join-Path $outDir "$name.png"
    & pwsh -NoProfile -File 'tools/capture.ps1' -Method Screen -Hwnd $hWnd -Out $png
    if ($LASTEXITCODE -ne 0) { throw "Screen capture failed for $name" }
    L "Capture '$name' -> $png"
    return $png
}

function Invoke-MeasureStep([string]$stepKey, [string]$description, [scriptblock]$action) {
    if (Should-Skip $stepKey) {
        L "[app] Step '$stepKey' ($description) -> SKIPPED (-Steps / -Skip filter)"
        return
    }
    L "=== Step '$stepKey': $description ==="
    try {
        & $action
        $global:summary["app"][$stepKey] = 'PASS'
        L "[app] Step '$stepKey' ($description) -> PASS"
    } catch {
        $err = $_.ToString()
        $global:summary["app"][$stepKey] = 'FAIL'
        L "[app] Step '$stepKey' ($description) -> FAIL: $err"
    }
}

# ---------------------------------------------------------------------------
# 4. Dry-Run Mode
# ---------------------------------------------------------------------------
function Run-DryRun([string]$dumpPath) {
    L "=== DryRun Mode: Parsing probes and target coordinates from dump '$dumpPath' ==="
    $resolvedPath = [System.IO.Path]::GetFullPath($dumpPath, (Get-Location).Path)
    if (-not (Test-Path -LiteralPath $resolvedPath)) {
        throw "DryRunStdout file not found: $resolvedPath"
    }

    # 1. Check tree row for compacted folder 'branch \ nested'
    L "----------------------------------------"
    L "Checking target: 'branch \ nested' (compacted folder)"
    $resTree = Get-TreeRowBoxByName ([IntPtr]::Zero) '' 'branch \ nested' '' $resolvedPath
    if (-not $resTree) {
        $resTree = Get-TreeRowBoxByName ([IntPtr]::Zero) '' 'branch' '' $resolvedPath
    }
    if ($resTree) {
        $b = $resTree.Box
        L "Result for 'branch \\ nested':"
        L "  Row Index : $($resTree.Index)"
        L "  Box Name  : $($b.name)"
        L "  Bounds    : x=$($b.x), y=$($b.y), w=$($b.w), h=$($b.h)"
        L "  Coords    : X=$($resTree.X), Y=$($resTree.Y) (client center)"
    } else {
        L "Result for 'branch \\ nested': NOT FOUND in tree rows"
    }

    # 2. Check title-folder-name probe
    L "----------------------------------------"
    L "Checking probe: 'title-folder-name'"
    $titleCoord = Get-BoxScreenCoord ([IntPtr]::Zero) '' 'title-folder-name' $resolvedPath
    if ($titleCoord) {
        $b = $titleCoord.Box
        L "Result for 'title-folder-name':"
        L "  Box Name  : $($b.name)"
        L "  Bounds    : x=$($b.x), y=$($b.y), w=$($b.w), h=$($b.h)"
        L "  Coords    : X=$($titleCoord.X), Y=$($titleCoord.Y)"
    } else {
        L "Result for 'title-folder-name': NOT PRESENT in dump"
    }

    # 3. Check status-bar probe
    L "----------------------------------------"
    L "Checking probe: 'status-bar'"
    $statusCoord = Get-BoxScreenCoord ([IntPtr]::Zero) '' 'status-bar' $resolvedPath
    if ($statusCoord) {
        $b = $statusCoord.Box
        L "Result for 'status-bar':"
        L "  Box Name  : $($b.name)"
        L "  Bounds    : x=$($b.x), y=$($b.y), w=$($b.w), h=$($b.h)"
    } else {
        L "Result for 'status-bar': NOT PRESENT in dump"
    }

    # 4. Check active-item probe (for S-9-5digit editor click)
    L "----------------------------------------"
    L "Checking probe: 'active-item'"
    $activeCoord = Get-BoxScreenCoord ([IntPtr]::Zero) '' 'active-item' $resolvedPath
    if ($activeCoord) {
        $b = $activeCoord.Box
        L "Result for 'active-item':"
        L "  Box Name  : $($b.name)"
        L "  Bounds    : x=$($b.x), y=$($b.y), w=$($b.w), h=$($b.h)"
        L "  Coords    : X=$($activeCoord.X), Y=$($activeCoord.Y)"
    } else {
        L "Result for 'active-item': NOT PRESENT in dump"
    }

    # 5. Check 5-digit fixture target row
    L "----------------------------------------"
    L "Checking target: '01-order03-5digit.md'"
    $res5d = Get-TreeRowBoxByName ([IntPtr]::Zero) '' '01-order03-5digit.md' '' $resolvedPath
    if ($res5d) {
        $b = $res5d.Box
        L "Result for '01-order03-5digit.md':"
        L "  Row Index : $($res5d.Index)"
        L "  Box Name  : $($b.name)"
        L "  Bounds    : x=$($b.x), y=$($b.y), w=$($b.w), h=$($b.h)"
    } else {
        L "Result for '01-order03-5digit.md': NOT FOUND in tree rows"
    }

    L "----------------------------------------"
    L "DryRun coordinate calculation check complete."
}

# ---------------------------------------------------------------------------
# 5. Main Execution Logic
# ---------------------------------------------------------------------------
if ($DryRunStdout) {
    Run-DryRun $DryRunStdout
    return
}

# Real measurement run
$appPid = $null
$appHwnd = [IntPtr]::Zero
$backupDir = Join-Path (Split-Path $Out -Parent) ('_' + (Split-Path $Out -Leaf) + '-backup')

try {
    # 1. Start Session
    L "Calling session.ps1 -Action Start..."
    & pwsh -NoProfile -File 'tools/measure/session.ps1' -Action Start -Out $Out -Exe $AppExe -Json -FixtureFile $FixturePath

    $sessionFile = Join-Path $Out 'session.json'
    if (-not (Test-Path $sessionFile)) { throw "session.json not found after session start" }
    $session = Get-Content -Raw $sessionFile | ConvertFrom-Json
    $appPid = [uint32]$session.pid
    L "App launched PID=$appPid"

    # Copy 5-digit fixture into session fixture folder before opening project so it is indexed
    if ($session.PSObject.Properties['fixture'] -and (Test-Path -LiteralPath $session.fixture)) {
        Copy-Item -LiteralPath $FiveDigitFixturePath -Destination (Join-Path $session.fixture '01-order03-5digit.md') -Force
        L "Copied 5-digit fixture into session fixture folder: $(Join-Path $session.fixture '01-order03-5digit.md')"
    }

    # Wait for app window
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt 15) {
        $windows = [Order04Native]::GetProcessTopLevelWindows(@($appPid))
        if ($windows.Count -gt 0) {
            $appHwnd = $windows[0]
            break
        }
        Start-Sleep -Milliseconds 200
    }
    if ($appHwnd -eq [IntPtr]::Zero) { throw "Failed to locate main window for app PID=$appPid" }
    L ("Main window located HWND=0x{0:X}" -f $appHwnd.ToInt64())

    # Set client size 1440x852 (100% DPI primary monitor)
    [Order04Native]::ShowWindow($appHwnd, 9) # 9 = SW_RESTORE
    Start-Sleep -Milliseconds 300
    [Order04Native]::SetWindowPos($appHwnd, [IntPtr]::Zero, 50, 50, 1442, 853, 0x0040)
    Start-Sleep -Milliseconds 400
    Ensure-Foreground $appHwnd "After resize"

    # Click project-empty-open if present
    $snap = Get-LatestSnapshot $Out
    if ($snap -and $snap.boxes.Contains('project-empty-open')) {
        $openBtn = Get-BoxScreenCoord $appHwnd $Out 'project-empty-open'
        if ($openBtn) {
            L "Clicking 'project-empty-open' button to load project tree..."
            [Order04Native]::Click($openBtn.X, $openBtn.Y)
            Start-Sleep -Milliseconds 600
        }
    }

    # Wait for tree rows to load
    Start-Sleep -Milliseconds 800

    # Dismiss any active tooltip
    [Order04Native]::MoveTo(5, 5)
    Start-Sleep -Milliseconds 200

    # -----------------------------------------------------------------------
    # Step: I20-tree (파일 트리 압축 폴더 'branch \ nested')
    # -----------------------------------------------------------------------
    Invoke-MeasureStep 'I20-tree' 'File Tree Compacted Folder Path (I-20)' {
        Ensure-Foreground $appHwnd "I20-tree"
        [Order04Native]::MoveTo(5, 5)
        Start-Sleep -Milliseconds 200

        $rowBox = Get-TreeRowBoxByName $appHwnd $Out 'branch \ nested' ''
        if (-not $rowBox) {
            $rowBox = Get-TreeRowBoxByName $appHwnd $Out 'branch' ''
        }
        if ($rowBox) {
            $b = $rowBox.Box
            L ("Compacted folder tree row bounds: x={0}, y={1}, w={2}, h={3} (crop target)" -f $b.x, $b.y, $b.w, $b.h)
        } else {
            L "Warning: 'branch \\ nested' row not found by name, using tree-row-01 fallback"
            $fb = Get-BoxScreenCoord $appHwnd $Out 'tree-row-01'
            if ($fb) { L ("Fallback tree row bounds: x={0}, y={1}, w={2}, h={3}" -f $fb.Box.x, $fb.Box.y, $fb.Box.w, $fb.Box.h) }
        }
        Cap-Window $appHwnd 'app-I20-tree' $Out
    }

    # -----------------------------------------------------------------------
    # Step: I20-tooltip (트리 항목 툴팁 - 전체 경로)
    # -----------------------------------------------------------------------
    Invoke-MeasureStep 'I20-tooltip' 'File Tree Item Full Path Tooltip (I-20)' {
        Ensure-Foreground $appHwnd "I20-tooltip"

        $rowBox = Get-TreeRowBoxByName $appHwnd $Out 'branch \ nested' ''
        if (-not $rowBox) {
            $rowBox = Get-TreeRowBoxByName $appHwnd $Out 'branch' ''
        }
        $targetX = 400
        $targetY = 100
        if ($rowBox) {
            $targetX = $rowBox.X
            $targetY = $rowBox.Y
        }
        L "Hovering over compacted tree row at ($targetX, $targetY) to trigger full path tooltip..."
        [Order04Native]::MoveTo($targetX, $targetY)
        Start-Sleep -Milliseconds 600

        Cap-Window $appHwnd 'app-I20-tooltip' $Out

        # Move mouse away to dismiss tooltip
        [Order04Native]::MoveTo(5, 5)
        Start-Sleep -Milliseconds 300
    }

    # -----------------------------------------------------------------------
    # Step: I20-dialog-unsaved (탭 닫기 미저장 확인 대화상자)
    # -----------------------------------------------------------------------
    Invoke-MeasureStep 'I20-dialog-unsaved' 'Unsaved Tab Close TaskDialog (I-20)' {
        Ensure-Foreground $appHwnd "I20-dialog-unsaved"

        # 1. Open nested.txt or 00-order03.md in editor
        $targetRow = Get-TreeRowBoxByName $appHwnd $Out '00-order03.md' ''
        if ($targetRow) {
            L "Opening file for unsaved check at ($($targetRow.X), $($targetRow.Y))..."
            [Order04Native]::DoubleClick($targetRow.X, $targetRow.Y)
            Start-Sleep -Milliseconds 600
        }

        # 2. Focus editor and make it dirty
        $activeCoord = Get-BoxScreenCoord $appHwnd $Out 'active-item'
        if ($activeCoord) {
            [Order04Native]::Click($activeCoord.X, $activeCoord.Y)
        } else {
            [Order04Native]::Click(800, 400)
        }
        Start-Sleep -Milliseconds 200

        # Type space then left arrow to make dirty
        L "Typing space to set modified flag..."
        [Order04Native]::KeyPress([ushort]0x20) # Space
        Start-Sleep -Milliseconds 200

        # 3. Trigger close tab (Ctrl+W) to open TaskDialog
        L "Sending Ctrl+W to trigger unsaved changes confirmation dialog..."
        [Order04Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl+W
        Start-Sleep -Milliseconds 600

        # 4. Find TaskDialog window (#32770)
        $dlgHwnd = [Order04Native]::FindDialog($appPid)
        if ($dlgHwnd -ne [IntPtr]::Zero) {
            L ("Found TaskDialog HWND=0x{0:X}" -f $dlgHwnd.ToInt64())
            Cap-Window $dlgHwnd 'app-I20-dialog-unsaved' $Out

            # Safe dismissal: Send Esc to cancel dialog
            L "Dismissing TaskDialog via Esc key (safe operation, no save/discard)..."
            [Order04Native]::KeyPress([ushort]0x1B) # Esc
            Start-Sleep -Milliseconds 500

            # Revert edits with Ctrl+Z so tab can be cleanly closed
            Ensure-Foreground $appHwnd "Reverting edits"
            [Order04Native]::KeyCombo(@([ushort]0x11), [ushort]0x5A) # Ctrl+Z
            Start-Sleep -Milliseconds 200
            [Order04Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl+W
            Start-Sleep -Milliseconds 300
        } else {
            L "Warning: TaskDialog window not detected within timeout, capturing main window as fallback..."
            Cap-Window $appHwnd 'app-I20-dialog-unsaved' $Out
            [Order04Native]::KeyPress([ushort]0x1B) # Esc
        }
    }

    # -----------------------------------------------------------------------
    # Step: I20-dialog-delete (파일 삭제 확인 대화상자)
    # -----------------------------------------------------------------------
    Invoke-MeasureStep 'I20-dialog-delete' 'File Delete Confirmation TaskDialog (I-20)' {
        Ensure-Foreground $appHwnd "I20-dialog-delete"

        # 1. Select a fixture file in tree (e.g., file-001.txt)
        $fileRow = Get-TreeRowBoxByName $appHwnd $Out 'file-001.txt' ''
        if ($fileRow) {
            L "Selecting 'file-001.txt' in tree at ($($fileRow.X), $($fileRow.Y))..."
            [Order04Native]::Click($fileRow.X, $fileRow.Y)
            Start-Sleep -Milliseconds 300

            # 2. Send Delete key to open Trash confirmation dialog
            L "Sending Delete key to open delete confirmation dialog..."
            [Order04Native]::KeyPress([ushort]0x2E) # Delete
            Start-Sleep -Milliseconds 600

            # 3. Find TaskDialog window (#32770)
            $dlgHwnd = [Order04Native]::FindDialog($appPid)
            if ($dlgHwnd -ne [IntPtr]::Zero) {
                L ("Found Delete TaskDialog HWND=0x{0:X}" -f $dlgHwnd.ToInt64())
                Cap-Window $dlgHwnd 'app-I20-dialog-delete' $Out

                # Safe dismissal: IMMEDIATELY send Esc to cancel (never confirm delete)
                L "Immediately dismissing Delete TaskDialog via Esc key (safe operation, deletion cancelled)..."
                [Order04Native]::KeyPress([ushort]0x1B) # Esc
                Start-Sleep -Milliseconds 400
            } else {
                L "Warning: Delete TaskDialog window not detected within timeout, capturing main window..."
                Cap-Window $appHwnd 'app-I20-dialog-delete' $Out
                [Order04Native]::KeyPress([ushort]0x1B) # Esc
            }
        } else {
            L "Warning: 'file-001.txt' not found in tree, skipping delete dialog trigger"
        }
    }

    # -----------------------------------------------------------------------
    # Step: I20-title (타이틀 바 폴더 이름)
    # -----------------------------------------------------------------------
    Invoke-MeasureStep 'I20-title' 'Title Bar Folder Name Path (I-20)' {
        Ensure-Foreground $appHwnd "I20-title"
        [Order04Native]::MoveTo(5, 5)
        Start-Sleep -Milliseconds 200

        $titleCoord = Get-BoxScreenCoord $appHwnd $Out 'title-folder-name'
        if ($titleCoord) {
            $b = $titleCoord.Box
            L ("Title folder name bounds: x={0}, y={1}, w={2}, h={3} (crop target)" -f $b.x, $b.y, $b.w, $b.h)
        }
        Cap-Window $appHwnd 'app-I20-title' $Out
    }

    # -----------------------------------------------------------------------
    # Step: S-9-5digit (5자리 줄 번호 열 재측정)
    # -----------------------------------------------------------------------
    Invoke-MeasureStep 'S-9-5digit' 'Line Number 5-Digit Gutter Geometry (ORDER-03 Remeasure)' {
        Ensure-Foreground $appHwnd "S-9-5digit"

        # 1. Open 5-digit fixture (01-order03-5digit.md)
        L "Opening 5-digit fixture '01-order03-5digit.md'..."
        $row5d = Get-TreeRowBoxByName $appHwnd $Out '01-order03-5digit.md' ''
        if ($row5d) {
            [Order04Native]::DoubleClick($row5d.X, $row5d.Y)
        } else {
            L "Fallback double-click for 5-digit fixture at (400, 240)..."
            [Order04Native]::DoubleClick(400, 240)
        }
        Start-Sleep -Milliseconds 500

        # 2. Focus editor
        $activeCoord = Get-BoxScreenCoord $appHwnd $Out 'active-item'
        $editorX = 540
        $editorY = 65
        $editorW = 900
        $editorH = 756
        if ($activeCoord) {
            $b = $activeCoord.Box
            $editorX = $b.x
            $editorY = $b.y
            $editorW = $b.w
            $editorH = $b.h
            [Order04Native]::Click($activeCoord.X, $activeCoord.Y)
        } else {
            [Order04Native]::Click(800, 400)
        }
        Start-Sleep -Milliseconds 300

        # 3. Wait for document load (up to 20s polling)
        L "Waiting for 5-digit document (657KB, 10,050 lines) to load into editor..."
        $loadTimeoutSec = 20
        $loadSw = [System.Diagnostics.Stopwatch]::StartNew()
        $loaded5Digit = $false
        $pyExe = 'C:\winpython\WPy64-31180_cpu\python-3.11.8.amd64\python.exe'

        while ($loadSw.Elapsed.TotalSeconds -lt $loadTimeoutSec) {
            # Send Ctrl+End to navigate to end of document
            [Order04Native]::KeyCombo(@([ushort]0x11), [ushort]0x23) # Ctrl+End
            Start-Sleep -Milliseconds 500

            # Capture temporary check screenshot
            $tmpCap = Join-Path $Out 'tmp-5digit-check.png'
            & pwsh -NoProfile -File 'tools/capture.ps1' -Method Screen -Hwnd $appHwnd -Out $tmpCap | Out-Null

            if (Test-Path -LiteralPath $tmpCap) {
                $pyScript = @"
from PIL import Image
import numpy as np
try:
    img = Image.open(r'$tmpCap').convert('RGB')
    arr = np.array(img)
    # editor gutter: x from $editorX to $($editorX + 130), y from $editorY to $($editorY + $editorH)
    crop = arr[int($editorY):int($editorY + $editorH), int($editorX):int($editorX + 130)]
    bg = crop[10, 10]
    diff = (np.abs(crop.astype(int) - bg.astype(int)) > 30).any(axis=2)
    rows_with_text = diff.any(axis=1).sum()
    col_with_text = diff.any(axis=0)
    col_indices = np.where(col_with_text)[0]
    ink_width = (col_indices.max() - col_indices.min() + 1) if len(col_indices) > 0 else 0
    # Condition: multiple rows of line numbers (>= 20) and ink width >= 38px (5 digits)
    if rows_with_text >= 20 and ink_width >= 38:
        print(f'OK rows={rows_with_text} w={ink_width}')
    else:
        print(f'WAIT rows={rows_with_text} w={ink_width}')
except Exception as e:
    print(f'ERR {e}')
"@
                $checkRes = & $pyExe -c $pyScript 2>&1
                L "5-digit load poll ($($loadSw.Elapsed.TotalSeconds.ToString('F1'))s): $checkRes"
                if ($checkRes -like 'OK*') {
                    $loaded5Digit = $true
                    break
                }
            }
            Start-Sleep -Milliseconds 500
        }

        if (-not $loaded5Digit) {
            throw "5-digit document load verification timed out after 20 seconds"
        }

        L "5-digit document successfully loaded! Performing final capture..."
        Cap-Window $appHwnd 'app-S-9-gutter-5digit' $Out

        # Close 5-digit tab (Ctrl+W)
        L "Closing 5-digit fixture tab via Ctrl+W..."
        [Order04Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl+W
        Start-Sleep -Milliseconds 400
    }

} finally {
    # Process cleanup: only kill the PID we launched
    L "Cleaning up workbench-gpui process (PID=$appPid)..."
    if ($appPid) {
        $p = Get-Process -Id $appPid -ErrorAction SilentlyContinue
        if ($p -and -not $p.HasExited) {
            try { [void]$p.CloseMainWindow(); [void]$p.WaitForExit(3000) } catch {}
            if (-not $p.HasExited) { try { $p.Kill(); [void]$p.WaitForExit(2000) } catch {} }
        }
    }
    L "Restoring app data via session.ps1 -Action Stop..."
    & pwsh -NoProfile -File 'tools/measure/session.ps1' -Action Stop -Out $Out -Backup $backupDir 2>&1 | ForEach-Object { L "Session Stop: $_" }

    # Save summary
    $summaryFile = Join-Path $Out 'summary.json'
    $global:summary | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $summaryFile -Encoding utf8
    L "Summary written to '$summaryFile'"
    L "=== ORDER-04 V3 Capture Script Finished ==="
}

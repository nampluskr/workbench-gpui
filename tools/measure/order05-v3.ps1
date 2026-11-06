#Requires -Version 7
<#
.SYNOPSIS
  ORDER-05 V3 화면 검증(UI 실측) 입력·캡처 스크립트.
  (gpui-checker 작성, leader가 화면 차례 안에서 실행한다.)

.DESCRIPTION
  - 우리 앱(workbench-gpui) 및 Zed를 동일 조건(클라이언트 1440×852, 100% DPI, 마크다운 픽스처)으로 구동.
  - I-1(UI 아이콘 모양) 및 I-18(상태 바 왼쪽 아이콘) 화면 상태를 차례로 만들고 Screen 방식으로 캡처한다:
    * I1-titlebar-normal: 타이틀 바 앱 메뉴(menu.svg) 및 창 제어 최소화/최대화/닫기 글리프
    * I1-titlebar-maximized: 창 최대화 후 복원 글리프 확인 및 복원
    * I1-tabbar: 탭 바 뒤로/앞으로/새 항목/분할/확대/닫기 아이콘
    * I1-tabbar-zoomed: 분할 확대 상태(minimize.svg)
    * I1-tabbar-pinned: 탭 고정 상태(pin.svg, Ctrl-K Shift-Enter)
    * I1-toolbar: Markdown 툴바 미리보기 eye 아이콘
    * I1-tab-preview: 마크다운 미리보기 탭 아이콘(file_doc.svg)
    * I1-sidebar-open: 사이드바 열림(토글 open, Add Project, 등록 폴더)
    * I1-sidebar-closed: 사이드바 닫힘
    * I18-statusbar: 상태 바 왼쪽 dock 토글(file_tree.svg), 사이드바 토글(threads_sidebar_left_closed.svg), Add Project(folder_add.svg)
    * I1-tree-folders: 프로젝트 트리 접힌 폴더(folder.svg) 및 열린 폴더(folder_open.svg)
    * MissingIcons: resources/zed-icons 부재 시 빈 칸 렌더링 및 stderr 경고 확인
  - 각 단계는 자기 전제(마크다운 파일 열기 등)를 독립적으로 보장하여 -Skip / -Steps로 단독 실행 가능.
  - 개별 단계 실패 시 FATAL로 중단하지 않고 summary에 FAIL을 기록한 뒤 다음 단계로 계속 진행 (ORDER-03 결정 반영).
  - Zed(zed -n 새 창)에서 동일 영역 캡처:
    * zed-titlebar, zed-tabbar, zed-toolbar, zed-statusbar, zed-project-panel
  - 각 아이콘 자리의 확대 크롭 좌표를 로그(log.txt) 및 crops.json/summary.json에 기록한다.
  - 자신이 실행한 프로세스/창만 닫으며, 이미 실행 중인 다른 프로세스/창은 절대 건드리지 않는다.
  - session.ps1 -Action Stop으로 앱 데이터를 완전 복원한다.

.PARAMETER Out
  출력 디렉터리 (기본값: specs\v0.5\verify\reviews\measure-ORDER-05).

.PARAMETER Only
  App, Zed, Both 중 선택 (기본값: Both).

.PARAMETER AppExe
  workbench-gpui 실행 파일 경로.

.PARAMETER ZedExe
  Zed 실행 파일 경로 (기본값: C:\Users\nampl\AppData\Local\Programs\Zed\bin\zed.exe).

.PARAMETER FixturePath
  측정에 사용할 마크다운 파일 경로 (미지정 시 $Out\order05-fixture.md 자동 생성).

.PARAMETER DryRunStdout
  stdout 덤프를 기반으로 좌표 및 프로브 계산만 검증하는 모드 (프로세스 구동 안 함).

.PARAMETER Steps
  실행할 단계 목록.

.PARAMETER Skip
  건너뛸 단계 목록.

.PARAMETER MissingIcons
  resources/zed-icons 부재 시험 단계만 실행.
#>
[CmdletBinding()]
param(
    [string]$Out = 'specs\v0.5\verify\reviews\measure-ORDER-05',
    [ValidateSet('App', 'Zed', 'Both')][string]$Only = 'Both',
    [string]$AppExe = 'D:\projects\workbench-gpui\target\debug\workbench-gpui.exe',
    [string]$ZedExe = 'C:\Users\nampl\AppData\Local\Programs\Zed\bin\zed.exe',
    [string]$FixturePath,
    [string]$DryRunStdout,
    [string[]]$Steps = @(),
    [string[]]$Skip = @(),
    [switch]$MissingIcons
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
    "zed" = [ordered]@{}
    "crops" = [ordered]@{}
}

$normalizedSteps = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
if ($Steps) {
    foreach ($item in $Steps) {
        foreach ($sub in ($item -split ',')) {
            $t = $sub.Trim()
            if ($t) { [void]$normalizedSteps.Add($t) }
        }
    }
    if ($normalizedSteps.Count -gt 0) {
        $Only = 'App'
    }
}

if ($MissingIcons) {
    [void]$normalizedSteps.Add('MissingIcons')
    $Only = 'App'
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
        if ($k.Contains('*') -or $k.Contains('?')) {
            if ($stepKey -like $k) { return $false }
        }
    }
    if ($normalizedSteps.Count -gt 0) {
        if ($normalizedSteps.Contains($stepKey)) { return $true }
        foreach ($s in $normalizedSteps) {
            if ($s.Contains('*') -or $s.Contains('?')) {
                if ($stepKey -like $s) { return $true }
            }
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
    L "=== ORDER-05 V3 Capture Script Started (Only=$Only, Out=$Out) ==="
}

# ---------------------------------------------------------------------------
# 1. Native API Definition (Order05Native)
# ---------------------------------------------------------------------------
if (-not ('Order05Native' -as [type])) {
    Add-Type -ReferencedAssemblies @('System.Runtime', 'System.Collections', 'System.Threading', 'System.Threading.Thread', 'System.Runtime.InteropServices') -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

public static class Order05Native {
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
    [DllImport("user32.dll")] public static extern void mouse_event(uint f, int dx, int dy, int data, IntPtr extra);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hWnd, out RECT rect);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr hWnd, ref POINT lpPoint);
    [DllImport("user32.dll")] public static extern bool ScreenToClient(IntPtr hWnd, ref POINT lpPoint);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc proc, IntPtr lParam);
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool IsZoomed(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int cmd);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
    [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr ctx);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] public static extern IntPtr GetWindow(IntPtr hWnd, uint uCmd);

    public const uint WM_CLOSE = 0x0010;
    public const uint WM_SYSCOMMAND = 0x0112;
    public const int SC_MAXIMIZE = 0xF030;
    public const int SC_RESTORE = 0xF120;

    public static string Title(IntPtr h) { var sb = new StringBuilder(512); GetWindowText(h, sb, sb.Capacity); return sb.ToString(); }

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

    public static void Click(int x, int y) {
        MoveTo(x, y);
        Thread.Sleep(60);
        mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, IntPtr.Zero);
        Thread.Sleep(60);
        mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, IntPtr.Zero);
        Thread.Sleep(60);
    }

    public static void DoubleClick(int x, int y) {
        Click(x, y);
        Thread.Sleep(80);
        Click(x, y);
    }

    public static void MoveTo(int x, int y) {
        int vx = GetSystemMetrics(SM_XVIRTUALSCREEN);
        int vy = GetSystemMetrics(SM_YVIRTUALSCREEN);
        int vw = GetSystemMetrics(SM_CXVIRTUALSCREEN);
        int vh = GetSystemMetrics(SM_CYVIRTUALSCREEN);
        int normX = (int)Math.Round((x - vx) * 65535.0 / (vw - 1));
        int normY = (int)Math.Round((y - vy) * 65535.0 / (vh - 1));
        mouse_event(MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_VIRTUALDESK, normX, normY, 0, IntPtr.Zero);
    }

    public static void KeyPress(ushort vk) {
        INPUT[] down = new INPUT[1];
        down[0].type = INPUT_KEYBOARD;
        down[0].u.ki.wVk = vk;
        down[0].u.ki.wScan = (ushort)MapVirtualKey(vk, 0);
        SendInput(1, down, Marshal.SizeOf(typeof(INPUT)));
        Thread.Sleep(40);
        INPUT[] up = new INPUT[1];
        up[0].type = INPUT_KEYBOARD;
        up[0].u.ki.wVk = vk;
        up[0].u.ki.wScan = down[0].u.ki.wScan;
        up[0].u.ki.dwFlags = KEYEVENTF_KEYUP;
        SendInput(1, up, Marshal.SizeOf(typeof(INPUT)));
        Thread.Sleep(40);
    }

    public static void KeyCombo(ushort[] modifiers, ushort vk) {
        INPUT[] down = new INPUT[modifiers.Length + 1];
        for (int i = 0; i < modifiers.Length; i++) {
            down[i].type = INPUT_KEYBOARD;
            down[i].u.ki.wVk = modifiers[i];
            down[i].u.ki.wScan = (ushort)MapVirtualKey(modifiers[i], 0);
        }
        down[modifiers.Length].type = INPUT_KEYBOARD;
        down[modifiers.Length].u.ki.wVk = vk;
        down[modifiers.Length].u.ki.wScan = (ushort)MapVirtualKey(vk, 0);
        SendInput((uint)down.Length, down, Marshal.SizeOf(typeof(INPUT)));
        Thread.Sleep(50);
        INPUT[] up = new INPUT[modifiers.Length + 1];
        up[0].type = INPUT_KEYBOARD;
        up[0].u.ki.wVk = vk;
        up[0].u.ki.wScan = down[modifiers.Length].u.ki.wScan;
        up[0].u.ki.dwFlags = KEYEVENTF_KEYUP;
        for (int i = 0; i < modifiers.Length; i++) {
            int idx = i + 1;
            up[idx].type = INPUT_KEYBOARD;
            up[idx].u.ki.wVk = modifiers[modifiers.Length - 1 - i];
            up[idx].u.ki.wScan = (ushort)MapVirtualKey(modifiers[modifiers.Length - 1 - i], 0);
            up[idx].u.ki.dwFlags = KEYEVENTF_KEYUP;
        }
        SendInput((uint)up.Length, up, Marshal.SizeOf(typeof(INPUT)));
        Thread.Sleep(50);
    }
}
'@
}

# ---------------------------------------------------------------------------
# 2. Window and Measurement Helpers
# ---------------------------------------------------------------------------
function Ensure-Foreground([IntPtr]$hwnd, [string]$label) {
    if ($hwnd -eq [IntPtr]::Zero) { return }
    [void][Order05Native]::SetForegroundWindow($hwnd)
    Start-Sleep -Milliseconds 200
    $fg = [Order05Native]::GetForegroundWindow()
    if ($fg -ne $hwnd) {
        [void][Order05Native]::ShowWindow($hwnd, 9) # SW_RESTORE
        [void][Order05Native]::SetForegroundWindow($hwnd)
        Start-Sleep -Milliseconds 300
        $fg = [Order05Native]::GetForegroundWindow()
    }
    L ("Foreground check for '$label': target=0x{0:X}, foreground=0x{1:X}" -f $hwnd.ToInt64(), $fg.ToInt64())
    if ($fg -ne $hwnd) {
        L "Warning: Foreground window ($fg) != target ($hwnd) during $label"
    }
}

function Cap-Window([IntPtr]$hwnd, [string]$name, [string]$outDir) {
    Ensure-Foreground $hwnd "Capture $name"
    $pngPath = Join-Path $outDir "$name.png"
    & pwsh -NoProfile -File 'tools/capture.ps1' -Hwnd ("0x{0:X}" -f $hwnd.ToInt64()) -Method Screen -Out $pngPath *> $null
    L "Capture '$name' -> $pngPath (exit=$LASTEXITCODE)"
    return $pngPath
}

function Ensure-ClientSize([IntPtr]$hwnd, [int]$expectedW, [int]$expectedH) {
    & pwsh -NoProfile -File 'tools/measure/window-rect.ps1' -ProcessName 'workbench-gpui' -TargetHwnd ("0x{0:X}" -f $hwnd.ToInt64()) -Action Resize -X 232 -Y 90 -Width 1456 -Height 860 2>&1 | ForEach-Object { L "Resize: $_" }
    Start-Sleep -Milliseconds 600

    $cr = New-Object Order05Native+RECT
    [void][Order05Native]::GetClientRect($hwnd, [ref]$cr)
    $actualW = $cr.Right - $cr.Left
    $actualH = $cr.Bottom - $cr.Top
    L "Client size check: target=${expectedW}x${expectedH}, actual=${actualW}x${actualH}"

    if ($actualW -ne $expectedW -or $actualH -ne $expectedH) {
        L "Directly applying SetWindowPos to adjust to 1456x860..."
        [void][Order05Native]::SetWindowPos($hwnd, [IntPtr]::Zero, 232, 90, 1456, 860, 0x0004 -bor 0x0010)
        Start-Sleep -Milliseconds 600
        [void][Order05Native]::GetClientRect($hwnd, [ref]$cr)
        $actualW = $cr.Right - $cr.Left
        $actualH = $cr.Bottom - $cr.Top
        L "Re-checked client size: ${actualW}x${actualH}"
        if ($actualW -ne $expectedW -or $actualH -ne $expectedH) {
            Cap-Window $hwnd 'error-app-client-size' $Out
            throw "Window client size mismatch: expected ${expectedW}x${expectedH}, but got ${actualW}x${actualH}"
        }
    }
}

function Log-IconCrop([string]$iconId, [string]$probeName, [double]$bx, [double]$by, [double]$bw, [double]$bh, [IntPtr]$hwnd = [IntPtr]::Zero) {
    $clientOrigin = New-Object Order05Native+POINT
    if ($hwnd -ne [IntPtr]::Zero) {
        [void][Order05Native]::ClientToScreen($hwnd, [ref]$clientOrigin)
    }
    $screenX = [int]($clientOrigin.X + $bx)
    $screenY = [int]($clientOrigin.Y + $by)
    $pad = 6
    $cropLeft = [Math]::Max(0, $screenX - $pad)
    $cropTop = [Math]::Max(0, $screenY - $pad)
    $cropRight = $screenX + [int]$bw + $pad
    $cropBottom = $screenY + [int]$bh + $pad
    $cropWidth = $cropRight - $cropLeft
    $cropHeight = $cropBottom - $cropTop

    $cropInfo = [ordered]@{
        "icon" = $iconId
        "probe" = $probeName
        "clientBounds" = @{ x = $bx; y = $by; w = $bw; h = $bh }
        "screenCoords" = @{ x = $screenX; y = $screenY }
        "cropRect" = @{ left = $cropLeft; top = $cropTop; right = $cropRight; bottom = $cropBottom; width = $cropWidth; height = $cropHeight }
    }
    L ("[CROP] {0} ({1}): client=({2},{3},{4},{5}), screen=({6},{7}), crop=[{8},{9},{10},{11}] ({12}x{13})" -f $iconId, $probeName, $bx, $by, $bw, $bh, $screenX, $screenY, $cropLeft, $cropTop, $cropRight, $cropBottom, $cropWidth, $cropHeight)
    $global:summary['crops'][$iconId] = $cropInfo
    return $cropInfo
}

function Get-LatestSnapshot([string]$outDir, [string]$overrideStdout = '') {
    $stdoutPath = if ($overrideStdout) { $overrideStdout } else { Join-Path $outDir 'app-stdout.txt' }
    if (-not (Test-Path -LiteralPath $stdoutPath)) { return $null }
    $lines = @(Get-Content -LiteralPath $stdoutPath -Encoding utf8)
    $end = -1
    $seq = -1
    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        if ($lines[$i] -match '^\[dev\] layout-snapshot-end seq=(\d+)') {
            $end = $i; $seq = [int]$matches[1]; break
        }
    }
    if ($end -lt 0) { return $null }
    $start = $end
    while ($start -ge 0 -and $lines[$start] -notmatch "^\[dev\] layout-snapshot seq=$seq ") { $start-- }
    if ($start -lt 0) { return $null }

    $boxes = [ordered]@{}
    Add-Member -InputObject $boxes -MemberType ScriptMethod -Name ContainsKey -Value { param([string]$k) $this.Contains($k) } -Force
    $allBoxes = [System.Collections.Generic.List[PSObject]]::new()
    for ($i = $start; $i -le $end; $i++) {
        if ($lines[$i] -match 'name=(\S+) bounds=([-\d.]+),([-\d.]+),([-\d.]+),([-\d.]+)') {
            $b = @{
                name = $matches[1]
                x = [double]$matches[2]
                y = [double]$matches[3]
                w = [double]$matches[4]
                h = [double]$matches[5]
            }
            $boxes[$matches[1]] = $b
            $allBoxes.Add([PSCustomObject]$b)
        }
    }
    return [PSCustomObject]@{
        seq = $seq
        boxes = $boxes
        allBoxes = $allBoxes
    }
}

function Assert-LayoutCondition([IntPtr]$hwnd, [string]$outDir, [string]$stepName, [scriptblock]$condition, [string]$failureMessage, [int]$maxAttempts = 15) {
    $matched = $false
    $snap = $null
    for ($i = 1; $i -le $maxAttempts; $i++) {
        $snap = Get-LatestSnapshot $outDir
        if ($snap -and (& $condition $snap)) {
            $matched = $true
            break
        }
        Start-Sleep -Milliseconds 300
    }
    if (-not $matched) {
        L "ERROR: Step '$stepName' failed expectation: $failureMessage"
        Cap-Window $hwnd "error-$stepName" $outDir
        throw "Step '$stepName' assertion failed: $failureMessage"
    }
    L "Step '$stepName' confirmed in layout snapshot (seq=$($snap.seq))"
    return $snap
}

function Invoke-MeasureStep([string]$appOrZed, [string]$stepKey, [string]$stepTitle, [scriptblock]$action) {
    if ($appOrZed -eq 'app' -and (-not (Should-RunStep $stepKey))) {
        L "[$appOrZed] Step '$stepKey' ($stepTitle) -> SKIPPED (not in -Steps or marked in -Skip)"
        $global:summary[$appOrZed][$stepKey] = "SKIPPED"
        return
    }
    L "=========================================================================="
    L "[$appOrZed] Running step '$stepKey': $stepTitle"
    L "=========================================================================="
    try {
        & $action
        $global:summary[$appOrZed][$stepKey] = "PASS"
        L "[$appOrZed] Step '$stepKey' finished successfully."
    } catch {
        $errMsg = $_.Exception.Message
        L "ERROR in [$appOrZed] step '$stepKey': $errMsg"
        $global:summary[$appOrZed][$stepKey] = "FAIL: $errMsg"
        # Core decision: do not abort remaining steps on single-step failure; continue.
    }
}

function Get-BoxScreenCoord([IntPtr]$hwnd, [string]$outDir, [string]$boxName, [string]$overrideStdout = '') {
    $snap = Get-LatestSnapshot $outDir $overrideStdout
    $b = $null
    if ($snap -and $snap.boxes.Contains($boxName)) {
        $b = $snap.boxes[$boxName]
    }
    if (-not $b -and $outDir) {
        $jsonPath = Join-Path $outDir 'layout.json'
        if (Test-Path -LiteralPath $jsonPath) {
            try {
                $json = Get-Content -LiteralPath $jsonPath -Raw -Encoding utf8 | ConvertFrom-Json
                $b = $json.boxes | Where-Object { $_.name -eq $boxName } | Select-Object -Last 1
            } catch {}
        }
    }
    if (-not $b) { return $null }

    $clientOrigin = New-Object Order05Native+POINT
    if ($hwnd -ne [IntPtr]::Zero) {
        [void][Order05Native]::ClientToScreen($hwnd, [ref]$clientOrigin)
    }
    $screenX = [int]($clientOrigin.X + $b.x + ($b.w / 2.0))
    $screenY = [int]($clientOrigin.Y + $b.y + ($b.h / 2.0))
    return [PSCustomObject]@{
        X = $screenX
        Y = $screenY
        W = $b.w
        H = $b.h
        Bounds = $b
    }
}

function Get-TreeRowBoxByName([IntPtr]$hwnd, [string]$outDir, [string]$fileName, [string]$fixtureDir = '', [string]$overrideStdout = '') {
    $foundIndex = -1
    $reason = ''
    $stdoutPath = if ($overrideStdout) { $overrideStdout } else { Join-Path $outDir 'app-stdout.txt' }
    if (Test-Path -LiteralPath $stdoutPath) {
        $lines = @(Get-Content -LiteralPath $stdoutPath -Encoding utf8)
        for ($i = $lines.Count - 1; $i -ge 0; $i--) {
            if ($lines[$i] -match '^\[dev\] tree .* rows=(.*)$') {
                $entries = $matches[1] -split '\t'
                for ($ix = 0; $ix -lt $entries.Count; $ix++) {
                    $parts = $entries[$ix] -split '\|'
                    if ($parts.Count -gt 0 -and $parts[0].Trim() -eq $fileName) {
                        $foundIndex = $ix
                        $reason = "stdout [dev] tree rows parsing (index $ix, file '$fileName')"
                        break
                    }
                }
                if ($foundIndex -ge 0) { break }
            }
        }
    }
    # Fallback: calculate index based on sorted directory entries if fixtureDir available
    if ($foundIndex -lt 0 -and $fixtureDir -and (Test-Path -LiteralPath $fixtureDir)) {
        $dirItems = @(Get-ChildItem -LiteralPath $fixtureDir -Force | Sort-Object Name)
        $calcIndex = 1
        foreach ($item in $dirItems) {
            if ($item.Name -eq $fileName) {
                $foundIndex = $calcIndex
                $reason = "calculated sorting order from directory scan (index $calcIndex)"
                break
            }
            $calcIndex++
        }
    }
    # Fallback: known position in standard fixture (row 3 is 00-order03.md / 00-order05.md)
    if ($foundIndex -lt 0) {
        if ($fileName -like '*00-order*' -or $fileName -like '*.md') {
            $foundIndex = 3
            $reason = "known default position for markdown fixture file (tree-row-03)"
        }
    }
    if ($foundIndex -ge 0) {
        $targetBoxName = ("tree-row-{0:D2}" -f $foundIndex)
        $coord = Get-BoxScreenCoord $hwnd $outDir $targetBoxName $overrideStdout
        if (-not $coord) {
            $coord = Get-BoxScreenCoord $hwnd $outDir ("tree-label-{0:D2}" -f $foundIndex) $overrideStdout
        }
        if ($coord) {
            $boxName = if ($coord.Bounds -and $coord.Bounds.ContainsKey('name')) { $coord.Bounds['name'] } else { $targetBoxName }
            return [PSCustomObject]@{
                X = $coord.X
                Y = $coord.Y
                W = $coord.W
                H = $coord.H
                Bounds = $coord.Bounds
                BoxName = $boxName
                Index = $foundIndex
                Reason = $reason
            }
        }
    }
    return $null
}

function Ensure-ProjectTreeOpen([IntPtr]$hwnd, [string]$outDir) {
    $snap = Get-LatestSnapshot $outDir
    if ($snap -and $snap.boxes.Contains('tree-row-01')) {
        return $snap
    }
    L "Project tree not visible. Opening project tree / left dock..."
    $emptyOpen = Get-BoxScreenCoord $hwnd $outDir 'project-empty-open'
    if ($emptyOpen) {
        L "Clicking 'project-empty-open'..."
        [Order05Native]::Click($emptyOpen.X, $emptyOpen.Y)
    } else {
        $ppBtn = Get-BoxScreenCoord $hwnd $outDir 'status-btn-project-panel'
        if ($ppBtn) {
            L "Clicking status-btn-project-panel to open dock..."
            [Order05Native]::Click($ppBtn.X, $ppBtn.Y)
        } else {
            L "Sending Ctrl-B to toggle dock..."
            [Order05Native]::KeyCombo(@([ushort]0x11), [ushort]0x42)
        }
    }
    return Assert-LayoutCondition $hwnd $outDir "project-tree-open" {
        param($s) $s.boxes.Contains('tree-row-01')
    } "tree-row-01 must appear in layout dump after opening project tree" 15
}

function Ensure-MarkdownFileOpen([IntPtr]$hwnd, [string]$outDir, [string]$fixtureDir) {
    $snap = Get-LatestSnapshot $outDir
    if ($snap -and $snap.boxes.Contains('toolbar-btn-preview') -and $snap.boxes.Contains('tab-00')) {
        return $snap
    }
    L "Markdown file not active in editor. Ensuring markdown file is open..."
    Ensure-ProjectTreeOpen $hwnd $outDir | Out-Null

    # Move mouse away to dismiss any tooltip
    [Order05Native]::MoveTo(5, 5)
    Start-Sleep -Milliseconds 200

    $target = Get-TreeRowBoxByName $hwnd $outDir '00-order03.md' $fixtureDir
    if (-not $target) {
        $target = Get-TreeRowBoxByName $hwnd $outDir '00-order05.md' $fixtureDir
    }
    if (-not $target) {
        $target = Get-BoxScreenCoord $hwnd $outDir 'tree-row-03'
    }
    if ($target) {
        L ("Double-clicking markdown file row at ({0},{1})..." -f $target.X, $target.Y)
        [Order05Native]::DoubleClick($target.X, $target.Y)
        Start-Sleep -Milliseconds 600
    } else {
        L "Warning: could not locate tree row for markdown file."
    }

    return Assert-LayoutCondition $hwnd $outDir "markdown-file-open" {
        param($s) $s.boxes.Contains('toolbar-btn-preview') -or $s.boxes.Contains('tab-00')
    } "toolbar-btn-preview or tab-00 must be present after opening markdown fixture" 15
}

# ---------------------------------------------------------------------------
# 3. Missing Icons Independent Verification Step
# ---------------------------------------------------------------------------
function Run-MissingIconsStep([string]$outDir, [string]$appExe) {
    L "--- Starting MissingIcons Verification Step ---"
    $iconsDir = Join-Path (Get-Location) 'resources\zed-icons'
    $offDir = Join-Path (Get-Location) 'resources\zed-icons.off'

    if (-not (Test-Path -LiteralPath $iconsDir)) {
        throw "resources\zed-icons not found! Cannot perform MissingIcons test."
    }

    L "Temporarily renaming 'resources\zed-icons' -> 'resources\zed-icons.off'..."
    Rename-Item -LiteralPath $iconsDir -NewName 'zed-icons.off' -Force

    $missingAppPid = 0
    try {
        $stderrPath = Join-Path $outDir 'missing-stderr.txt'
        $stdoutPath = Join-Path $outDir 'missing-stdout.txt'
        if (Test-Path -LiteralPath $stderrPath) { Remove-Item -LiteralPath $stderrPath -Force }
        if (Test-Path -LiteralPath $stdoutPath) { Remove-Item -LiteralPath $stdoutPath -Force }

        L "Launching $appExe with icons absent..."
        $proc = Start-Process -FilePath $appExe -ArgumentList @('--dev-layout') -PassThru -RedirectStandardError $stderrPath -RedirectStandardOutput $stdoutPath
        $missingAppPid = $proc.Id
        L "Launched app PID=$missingAppPid"

        $hwnd = [IntPtr]::Zero
        for ($i = 1; $i -le 30; $i++) {
            Start-Sleep -Milliseconds 400
            $proc.Refresh()
            if ($proc.MainWindowHandle -ne [IntPtr]::Zero) {
                $hwnd = $proc.MainWindowHandle
                break
            }
        }
        if ($hwnd -eq [IntPtr]::Zero) {
            throw "Window not found for MissingIcons test app PID=$missingAppPid"
        }

        L ("MissingIcons window HWND=0x{0:X}" -f $hwnd.ToInt64())
        Ensure-ClientSize $hwnd 1440 852
        Ensure-Foreground $hwnd "MissingIcons capture"
        Start-Sleep -Milliseconds 500

        Cap-Window $hwnd 'app-missing-icons' $outDir

        # Graceful close
        [void]$proc.CloseMainWindow()
        [void]$proc.WaitForExit(3000)
        if (-not $proc.HasExited) {
            try { $proc.Kill(); [void]$proc.WaitForExit(2000) } catch {}
        }

        # Check stderr for expected warning message
        Start-Sleep -Milliseconds 200
        $stderrContent = if (Test-Path -LiteralPath $stderrPath) { Get-Content -LiteralPath $stderrPath -Raw -Encoding utf8 } else { '' }
        $expectedWarning = "zed icons missing: run tools/fetch-zed-icons.ps1"
        if ($stderrContent -match [regex]::Escape($expectedWarning)) {
            L "PASS: stderr contains expected warning: '$expectedWarning'"
            $global:summary['app']['MissingIcons'] = "PASS (warning present, empty icon slot rendered without crash)"
        } else {
            L "WARNING: stderr did not contain expected warning! Stderr content: '$stderrContent'"
            $global:summary['app']['MissingIcons'] = "FAIL: missing stderr warning"
            throw "MissingIcons stderr verification failed"
        }
    } finally {
        # ALWAYS restore directory name in finally
        if (Test-Path -LiteralPath $offDir) {
            L "Restoring 'resources\zed-icons.off' -> 'resources\zed-icons'..."
            try {
                Rename-Item -LiteralPath $offDir -NewName 'zed-icons' -Force
                if (-not (Test-Path -LiteralPath $iconsDir)) {
                    throw "resources\zed-icons still absent after rename attempt"
                }
                L "Restored resources\zed-icons successfully."
            } catch {
                L "FATAL CRITICAL ERROR: Failed to restore 'resources\zed-icons'! Details: $_"
                throw "CRITICAL FAILURE: resources\zed-icons was not restored: $_"
            }
        }
    }
}

# ---------------------------------------------------------------------------
# 4. App Measurement (workbench-gpui)
# ---------------------------------------------------------------------------
function Run-AppMeasure {
    L "--- Starting workbench-gpui measurements ---"

    # Default Fixture creation if needed
    if (-not $FixturePath) {
        $FixturePath = Join-Path $Out 'order05-fixture.md'
        if (-not (Test-Path -LiteralPath $FixturePath)) {
            @"
# ORDER-05 UI Icons Test Document

This document verifies Zed icon rendering in workbench-gpui (I-1, I-18).

- Title bar: Application menu (menu.svg), window buttons (Segoe glyphs)
- Tab bar: back, forward, new, split, zoom, close, pin
- Markdown toolbar: preview eye icon
- Status bar: Left dock file_tree, sidebar toggle, Add Project
- File tree: Folders collapsed and expanded
"@ | Set-Content -LiteralPath $FixturePath -Encoding utf8
            L "Created test fixture: $FixturePath"
        }
    }

    # If MissingIcons is explicitly selected as the only step
    if ($normalizedSteps.Count -eq 1 -and $normalizedSteps.Contains('MissingIcons')) {
        Run-MissingIconsStep $Out $AppExe
        return
    }

    $backupDir = Join-Path (Split-Path $Out -Parent) ('_' + (Split-Path $Out -Leaf) + '-backup')
    $appPid = 0
    $appHwnd = [IntPtr]::Zero
    $fixtureDir = ''

    try {
        # 1. Start Session
        L "Calling session.ps1 -Action Start..."
        & pwsh -NoProfile -File 'tools/measure/session.ps1' -Action Start -Out $Out -Exe $AppExe -Json -FixtureFile $FixturePath

        $sessionFile = Join-Path $Out 'session.json'
        if (-not (Test-Path $sessionFile)) { throw "session.json not found after session start" }
        $session = Get-Content -Raw $sessionFile | ConvertFrom-Json
        $appPid = [uint32]$session.pid
        $fixtureDir = if ($session.PSObject.Properties['fixture']) { $session.fixture } else { '' }
        L "App launched PID=$appPid"

        # 2. Find Window HWND
        for ($i = 1; $i -le 40; $i++) {
            Start-Sleep -Milliseconds 300
            $p = Get-Process -Id $appPid -ErrorAction SilentlyContinue
            if ($p -and $p.MainWindowHandle -ne [IntPtr]::Zero) {
                $appHwnd = $p.MainWindowHandle
                break
            }
        }
        if ($appHwnd -eq [IntPtr]::Zero) { throw "workbench-gpui main window not found for PID=$appPid" }
        L ("Found main window HWND=0x{0:X}" -f $appHwnd.ToInt64())

        # 3. Resize window to client 1440x852 & Verify
        Ensure-ClientSize $appHwnd 1440 852
        Ensure-Foreground $appHwnd "After resize"

        # 4. Open project tree if empty
        Ensure-ProjectTreeOpen $appHwnd $Out | Out-Null

        # Step Actions Map (Each step guarantees its own prerequisites)
        $stepActions = [ordered]@{
            # ---------------------------------------------------------------
            # 1. Title bar normal (menu.svg, Segoe glyphs)
            # ---------------------------------------------------------------
            'I1-titlebar-normal' = {
                Ensure-Foreground $appHwnd "I1-titlebar-normal"
                $snap = Assert-LayoutCondition $appHwnd $Out 'titlebar-normal' {
                    param($s) $s.boxes.Contains('app-menu-button') -and $s.boxes.Contains('window-controls')
                } 'Title bar elements must be present'

                if ($snap.boxes.Contains('app-menu-button')) {
                    $b = $snap.boxes['app-menu-button']
                    Log-IconCrop 'menu' 'app-menu-button' $b.x $b.y $b.w $b.h $appHwnd
                }
                if ($snap.boxes.Contains('window-btn-min')) {
                    $b = $snap.boxes['window-btn-min']
                    Log-IconCrop 'window-min' 'window-btn-min' $b.x $b.y $b.w $b.h $appHwnd
                }
                if ($snap.boxes.Contains('window-btn-max')) {
                    $b = $snap.boxes['window-btn-max']
                    Log-IconCrop 'window-max' 'window-btn-max' $b.x $b.y $b.w $b.h $appHwnd
                }
                if ($snap.boxes.Contains('window-btn-close')) {
                    $b = $snap.boxes['window-btn-close']
                    Log-IconCrop 'window-close' 'window-btn-close' $b.x $b.y $b.w $b.h $appHwnd
                }

                Cap-Window $appHwnd 'app-titlebar-normal' $Out
            }

            # ---------------------------------------------------------------
            # 2. Title bar maximized (restore glyph)
            # ---------------------------------------------------------------
            'I1-titlebar-maximized' = {
                Ensure-Foreground $appHwnd "I1-titlebar-maximized"
                L "Maximizing window (SW_MAXIMIZE)..."
                [void][Order05Native]::ShowWindow($appHwnd, 3) # 3 = SW_MAXIMIZE
                Start-Sleep -Milliseconds 600

                $snap = Assert-LayoutCondition $appHwnd $Out 'titlebar-maximized' {
                    param($s) $s.boxes.Contains('window-btn-max') -and $s.boxes.Contains('title-bar')
                } 'Maximized window must produce layout snapshot'

                if ($snap.boxes.Contains('window-btn-max')) {
                    $b = $snap.boxes['window-btn-max']
                    Log-IconCrop 'window-restore' 'window-btn-max' $b.x $b.y $b.w $b.h $appHwnd
                }

                Cap-Window $appHwnd 'app-titlebar-maximized' $Out

                L "Restoring window back (SW_RESTORE)..."
                [void][Order05Native]::ShowWindow($appHwnd, 9) # 9 = SW_RESTORE
                Start-Sleep -Milliseconds 600
                Ensure-ClientSize $appHwnd 1440 852
            }

            # ---------------------------------------------------------------
            # 3. Tab bar buttons (arrow_left, arrow_right, plus, split, zoom, close)
            # ---------------------------------------------------------------
            'I1-tabbar' = {
                Ensure-Foreground $appHwnd "I1-tabbar"
                Ensure-MarkdownFileOpen $appHwnd $Out $fixtureDir | Out-Null

                $snap = Assert-LayoutCondition $appHwnd $Out 'tabbar' {
                    param($s) $s.boxes.Contains('tab-btn-back') -and $s.boxes.Contains('tab-btn-forward') -and $s.boxes.Contains('tab-btn-new')
                } 'Tab bar navigation buttons must be present'

                foreach ($item in @(
                    @{ id = 'arrow_left'; probe = 'tab-btn-back' },
                    @{ id = 'arrow_right'; probe = 'tab-btn-forward' },
                    @{ id = 'plus'; probe = 'tab-btn-new' },
                    @{ id = 'split'; probe = 'tab-btn-split' },
                    @{ id = 'maximize'; probe = 'tab-btn-zoom' },
                    @{ id = 'close'; probe = 'tab-close-0' }
                )) {
                    if ($snap.boxes.Contains($item.probe)) {
                        $b = $snap.boxes[$item.probe]
                        Log-IconCrop $item.id $item.probe $b.x $b.y $b.w $b.h $appHwnd
                    }
                }

                Cap-Window $appHwnd 'app-tabbar' $Out
            }

            # ---------------------------------------------------------------
            # 4. Tab bar zoom state (minimize.svg)
            # ---------------------------------------------------------------
            'I1-tabbar-zoomed' = {
                Ensure-Foreground $appHwnd "I1-tabbar-zoomed"
                Ensure-MarkdownFileOpen $appHwnd $Out $fixtureDir | Out-Null

                L "Splitting pane right (Ctrl+\)..."
                [Order05Native]::KeyCombo(@([ushort]0x11), [ushort]0xDC) # Ctrl+\
                Start-Sleep -Milliseconds 600

                L "Toggling zoom on pane (Alt+Z)..."
                [Order05Native]::KeyCombo(@([ushort]0x12), [ushort]0x5A) # Alt+Z
                Start-Sleep -Milliseconds 600

                $snap = Assert-LayoutCondition $appHwnd $Out 'tabbar-zoomed' {
                    param($s) $s.boxes.Contains('tab-btn-zoom')
                } 'Zoom button must be present in zoomed state'

                if ($snap.boxes.Contains('tab-btn-zoom')) {
                    $b = $snap.boxes['tab-btn-zoom']
                    Log-IconCrop 'minimize' 'tab-btn-zoom' $b.x $b.y $b.w $b.h $appHwnd
                }

                Cap-Window $appHwnd 'app-tabbar-zoomed' $Out

                L "Restoring unzoomed state (Alt+Z) and closing split pane (Ctrl+W)..."
                [Order05Native]::KeyCombo(@([ushort]0x12), [ushort]0x5A) # Alt+Z
                Start-Sleep -Milliseconds 400
                [Order05Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl+W
                Start-Sleep -Milliseconds 500
            }

            # ---------------------------------------------------------------
            # 5. Pinned tab state (pin.svg, Ctrl-K Shift-Enter)
            # ---------------------------------------------------------------
            'I1-tabbar-pinned' = {
                Ensure-Foreground $appHwnd "I1-tabbar-pinned"
                Ensure-MarkdownFileOpen $appHwnd $Out $fixtureDir | Out-Null

                $snapBefore = Assert-LayoutCondition $appHwnd $Out 'tabbar-has-tab' {
                    param($s) $s.boxes.Contains('tab-00')
                } 'tab-00 must be present before pinning'

                # Click tab-00 to ensure pane focus
                $tabCoord = Get-BoxScreenCoord $appHwnd $Out 'tab-00'
                if ($tabCoord) {
                    [Order05Native]::Click($tabCoord.X, $tabCoord.Y)
                    Start-Sleep -Milliseconds 200
                }

                L "Toggling pin on current tab (Ctrl-K Shift-Enter)..."
                [Order05Native]::KeyCombo(@([ushort]0x11), [ushort]0x4B) # Ctrl-K
                Start-Sleep -Milliseconds 150
                [Order05Native]::KeyCombo(@([ushort]0x10), [ushort]0x0D) # Shift-Enter
                Start-Sleep -Milliseconds 500

                $snap = Assert-LayoutCondition $appHwnd $Out 'tabbar-pinned' {
                    param($s) $s.boxes.Contains('tab-00')
                } 'tab-00 must be present in pinned state'

                if ($snap.boxes.Contains('tab-00')) {
                    $b = $snap.boxes['tab-00']
                    # Pin slot is at the right end of tab-00 (TAB_END_SLOT is 14x14, right margin ~6px)
                    $pinX = $b.x + $b.w - 20
                    $pinY = $b.y + ($b.h - 14) / 2
                    Log-IconCrop 'pin' 'tab-00-pin' $pinX $pinY 14 14 $appHwnd
                }

                Cap-Window $appHwnd 'app-tabbar-pinned' $Out

                L "Restoring unpinned tab state (Ctrl-K Shift-Enter)..."
                [Order05Native]::KeyCombo(@([ushort]0x11), [ushort]0x4B) # Ctrl-K
                Start-Sleep -Milliseconds 150
                [Order05Native]::KeyCombo(@([ushort]0x10), [ushort]0x0D) # Shift-Enter
                Start-Sleep -Milliseconds 400
            }

            # ---------------------------------------------------------------
            # 6. Markdown toolbar (eye.svg)
            # ---------------------------------------------------------------
            'I1-toolbar' = {
                Ensure-Foreground $appHwnd "I1-toolbar"
                Ensure-MarkdownFileOpen $appHwnd $Out $fixtureDir | Out-Null

                $snap = Assert-LayoutCondition $appHwnd $Out 'toolbar' {
                    param($s) $s.boxes.Contains('toolbar-btn-preview')
                } 'toolbar-btn-preview must be present for markdown document'

                if ($snap.boxes.Contains('toolbar-btn-preview')) {
                    $b = $snap.boxes['toolbar-btn-preview']
                    Log-IconCrop 'eye' 'toolbar-btn-preview' $b.x $b.y $b.w $b.h $appHwnd
                }

                Cap-Window $appHwnd 'app-toolbar-preview-eye' $Out
            }

            # ---------------------------------------------------------------
            # 7. Markdown preview tab (file_doc.svg)
            # ---------------------------------------------------------------
            'I1-tab-preview' = {
                Ensure-Foreground $appHwnd "I1-tab-preview"
                Ensure-MarkdownFileOpen $appHwnd $Out $fixtureDir | Out-Null

                L "Opening Markdown Preview (Ctrl+Shift+V)..."
                $btn = Get-BoxScreenCoord $appHwnd $Out 'toolbar-btn-preview'
                if ($btn) {
                    [Order05Native]::Click($btn.X, $btn.Y)
                } else {
                    [Order05Native]::KeyCombo(@([ushort]0x11, [ushort]0x10), [ushort]0x56) # Ctrl+Shift+V
                }
                Start-Sleep -Milliseconds 800

                $snap = Assert-LayoutCondition $appHwnd $Out 'preview-tab' {
                    param($s) $s.boxes.Contains('tab-00') -or $s.boxes.Contains('tab-01')
                } 'Preview tab must appear'

                $targetTabProbe = if ($snap.boxes.Contains('tab-01')) { 'tab-01' } else { 'tab-00' }
                if ($snap.boxes.Contains($targetTabProbe)) {
                    $b = $snap.boxes[$targetTabProbe]
                    # file_doc icon is inside the start slot / label row of preview tab
                    $docX = $b.x + 10
                    $docY = $b.y + ($b.h - 14) / 2
                    Log-IconCrop 'file_doc' $targetTabProbe $docX $docY 14 14 $appHwnd
                }

                Cap-Window $appHwnd 'app-preview-tab-doc' $Out

                L "Closing preview tab (Ctrl+W)..."
                [Order05Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl+W
                Start-Sleep -Milliseconds 500
            }

            # ---------------------------------------------------------------
            # 8. Sidebar open (threads_sidebar_left_open, folder_add, folder)
            # ---------------------------------------------------------------
            'I1-sidebar-open' = {
                Ensure-Foreground $appHwnd "I1-sidebar-open"
                # Ensure sidebar is open
                $snap0 = Get-LatestSnapshot $Out
                if (-not ($snap0 -and $snap0.boxes.Contains('sidebar-btn-toggle'))) {
                    L "Sidebar not open, clicking status-btn-sidebar-toggle..."
                    $sbToggle = Get-BoxScreenCoord $appHwnd $Out 'status-btn-sidebar-toggle'
                    if ($sbToggle) { [Order05Native]::Click($sbToggle.X, $sbToggle.Y); Start-Sleep -Milliseconds 600 }
                }

                $snap = Assert-LayoutCondition $appHwnd $Out 'sidebar-open' {
                    param($s) $s.boxes.Contains('sidebar-btn-toggle') -and $s.boxes.Contains('sidebar-btn-folder-add')
                } 'Sidebar open buttons must be present'

                if ($snap.boxes.Contains('sidebar-btn-toggle')) {
                    $b = $snap.boxes['sidebar-btn-toggle']
                    Log-IconCrop 'threads_sidebar_left_open' 'sidebar-btn-toggle' $b.x $b.y $b.w $b.h $appHwnd
                }
                if ($snap.boxes.Contains('sidebar-btn-folder-add')) {
                    $b = $snap.boxes['sidebar-btn-folder-add']
                    Log-IconCrop 'folder_add_sidebar' 'sidebar-btn-folder-add' $b.x $b.y $b.w $b.h $appHwnd
                }
                if ($snap.boxes.Contains('sidebar-folder-0')) {
                    $b = $snap.boxes['sidebar-folder-0']
                    Log-IconCrop 'folder_sidebar_item' 'sidebar-folder-0' $b.x $b.y $b.w $b.h $appHwnd
                }

                Cap-Window $appHwnd 'app-sidebar-open' $Out
            }

            # ---------------------------------------------------------------
            # 9. Sidebar closed
            # ---------------------------------------------------------------
            'I1-sidebar-closed' = {
                Ensure-Foreground $appHwnd "I1-sidebar-closed"
                $btn = Get-BoxScreenCoord $appHwnd $Out 'sidebar-btn-toggle'
                if ($btn) {
                    L "Clicking sidebar toggle to close sidebar..."
                    [Order05Native]::Click($btn.X, $btn.Y)
                } else {
                    L "Sending Ctrl-B to toggle sidebar..."
                    [Order05Native]::KeyCombo(@([ushort]0x11), [ushort]0x42)
                }
                Start-Sleep -Milliseconds 600

                Cap-Window $appHwnd 'app-sidebar-closed' $Out

                # Reopen sidebar
                L "Re-opening sidebar for subsequent steps..."
                $sbBtn = Get-BoxScreenCoord $appHwnd $Out 'status-btn-sidebar-toggle'
                if ($sbBtn) {
                    [Order05Native]::Click($sbBtn.X, $sbBtn.Y)
                } else {
                    [Order05Native]::KeyCombo(@([ushort]0x11), [ushort]0x42)
                }
                Start-Sleep -Milliseconds 600
            }

            # ---------------------------------------------------------------
            # 10. Status bar left (I-18: file_tree, threads_sidebar_left_closed, folder_add)
            # ---------------------------------------------------------------
            'I18-statusbar' = {
                Ensure-Foreground $appHwnd "I18-statusbar"
                $snap = Assert-LayoutCondition $appHwnd $Out 'statusbar-left' {
                    param($s) $s.boxes.Contains('status-btn-project-panel')
                } 'status-btn-project-panel must be present'

                if ($snap.boxes.Contains('status-btn-project-panel')) {
                    $b = $snap.boxes['status-btn-project-panel']
                    Log-IconCrop 'file_tree' 'status-btn-project-panel' $b.x $b.y $b.w $b.h $appHwnd
                }
                if ($snap.boxes.Contains('status-btn-sidebar-toggle')) {
                    $b = $snap.boxes['status-btn-sidebar-toggle']
                    Log-IconCrop 'threads_sidebar_left_closed' 'status-btn-sidebar-toggle' $b.x $b.y $b.w $b.h $appHwnd
                }
                if ($snap.boxes.Contains('status-btn-folder-add')) {
                    $b = $snap.boxes['status-btn-folder-add']
                    Log-IconCrop 'folder_add_status' 'status-btn-folder-add' $b.x $b.y $b.w $b.h $appHwnd
                }

                Cap-Window $appHwnd 'app-statusbar-left-open' $Out

                # Toggle dock closed
                $ppBtn = Get-BoxScreenCoord $appHwnd $Out 'status-btn-project-panel'
                if ($ppBtn) {
                    L "Clicking project panel dock toggle to close left dock..."
                    [Order05Native]::Click($ppBtn.X, $ppBtn.Y)
                    Start-Sleep -Milliseconds 600
                    Cap-Window $appHwnd 'app-statusbar-left-closed' $Out
                    L "Reopening project panel dock..."
                    [Order05Native]::Click($ppBtn.X, $ppBtn.Y)
                    Start-Sleep -Milliseconds 600
                }
            }

            # ---------------------------------------------------------------
            # 11. Project tree folder icons (folder.svg, folder_open.svg)
            # ---------------------------------------------------------------
            'I1-tree-folders' = {
                Ensure-Foreground $appHwnd "I1-tree-folders"
                Ensure-ProjectTreeOpen $appHwnd $Out | Out-Null

                $snap = Assert-LayoutCondition $appHwnd $Out 'tree-folders' {
                    param($s) $s.boxes.Contains('tree-row-01')
                } 'tree-row-01 must be present'

                # tree-row-01 is 'branch \ nested' directory in standard fixture
                $dirRowBox = if ($snap.boxes.Contains('tree-row-01')) { $snap.boxes['tree-row-01'] } else {
                    $snap.allBoxes | Where-Object { $_.name -like 'tree-row-*' } | Select-Object -First 1
                }

                if ($dirRowBox) {
                    Log-IconCrop 'folder_collapsed' $dirRowBox.name $dirRowBox.x $dirRowBox.y 16 16 $appHwnd
                    $coord = Get-BoxScreenCoord $appHwnd $Out $dirRowBox.name
                    if ($coord) {
                        L "Clicking directory row to expand: $($dirRowBox.name)..."
                        [Order05Native]::Click($coord.X, $coord.Y)
                        Start-Sleep -Milliseconds 600
                        $snap2 = Get-LatestSnapshot $Out
                        $expandedBox = if ($snap2 -and $snap2.boxes.Contains($dirRowBox.name)) { $snap2.boxes[$dirRowBox.name] } else { $dirRowBox }
                        Log-IconCrop 'folder_expanded' $dirRowBox.name $expandedBox.x $expandedBox.y 16 16 $appHwnd
                    }
                }

                Cap-Window $appHwnd 'app-tree-folders' $Out
            }

            # ---------------------------------------------------------------
            # 12. MissingIcons (invoked inside app loop if selected)
            # ---------------------------------------------------------------
            'MissingIcons' = {
                L "MissingIcons step executed separately via Run-MissingIconsStep"
            }
        }

        # Step Titles
        $stepTitles = @{
            'I1-titlebar-normal' = 'Title bar menu & Segoe glyphs'
            'I1-titlebar-maximized' = 'Title bar maximized restore glyph'
            'I1-tabbar' = 'Tab bar action icons'
            'I1-tabbar-zoomed' = 'Tab bar zoom minimize icon'
            'I1-tabbar-pinned' = 'Tab bar pinned tab icon'
            'I1-toolbar' = 'Markdown toolbar preview eye icon'
            'I1-tab-preview' = 'Markdown preview tab file_doc icon'
            'I1-sidebar-open' = 'Sidebar open action icons'
            'I1-sidebar-closed' = 'Sidebar closed state'
            'I18-statusbar' = 'Status bar left dock & project icons (I-18)'
            'I1-tree-folders' = 'Project tree folder collapsed and open icons'
            'MissingIcons' = 'Missing icons absence verification'
        }

        # Select steps to run
        $stepsToRun = [System.Collections.Generic.List[string]]::new()
        if ($normalizedSteps.Count -gt 0) {
            foreach ($k in $stepActions.Keys) {
                foreach ($s in $normalizedSteps) {
                    if ($k -eq $s -or $k -like "$s-*" -or $s -like "$k-*") {
                        if (-not $stepsToRun.Contains($k)) { $stepsToRun.Add($k) }
                    }
                }
            }
        } else {
            foreach ($k in $stepActions.Keys) {
                if ($k -ne 'MissingIcons') { $stepsToRun.Add($k) }
            }
        }

        L ("Steps selected for execution: " + ($stepsToRun -join ', '))
        foreach ($stepKey in $stepsToRun) {
            if ($stepKey -eq 'MissingIcons') {
                continue
            }
            $title = if ($stepTitles.ContainsKey($stepKey)) { $stepTitles[$stepKey] } else { $stepKey }
            Invoke-MeasureStep 'app' $stepKey $title $stepActions[$stepKey]
        }

    } finally {
        # Process cleanup: kill only launched PID, restore session Stop
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
    }

    # Run MissingIcons step if requested and not skipped
    if (Should-RunStep 'MissingIcons' -and ($normalizedSteps.Count -eq 0 -or $normalizedSteps.Contains('MissingIcons'))) {
        Run-MissingIconsStep $Out $AppExe
    }
}

# ---------------------------------------------------------------------------
# 5. Zed Measurement (Zed.exe)
# ---------------------------------------------------------------------------
function Run-ZedMeasure {
    if ($normalizedSteps.Count -gt 0) {
        L "Notice: -Steps mode active, skipping Zed measurement entirely."
        return
    }
    L "--- Starting Zed measurement ---"

    # Enumerate Zed top level windows before launch
    $zedPidsBefore = [uint32[]]@(Get-Process -Name Zed -ErrorAction SilentlyContinue | ForEach-Object { [uint32]$_.Id })
    $beforeHwnds = @()
    if ($zedPidsBefore.Count -gt 0) {
        $beforeHwnds = [Order05Native]::GetProcessTopLevelWindows($zedPidsBefore)
    }
    L ("Zed top-level HWNDs before launch: " + (($beforeHwnds | ForEach-Object { '0x{0:X}' -f $_.ToInt64() }) -join ', '))

    $zedHwnd = [IntPtr]::Zero
    $zo = New-Object Order05Native+POINT

    try {
        $zedPrereqOk = $false
        try {
            L "Launching Zed (new window only, -a forbidden): $ZedExe -n `"$FixturePath`""
            Start-Process -FilePath $ZedExe -ArgumentList @('-n', "`"$FixturePath`"")

            foreach ($i in 1..60) {
                Start-Sleep -Milliseconds 500
                $currentPids = [uint32[]]@(Get-Process -Name Zed -ErrorAction SilentlyContinue | ForEach-Object { [uint32]$_.Id })
                if ($currentPids.Count -eq 0) { continue }
                $currentHwnds = [Order05Native]::GetProcessTopLevelWindows($currentPids)
                $newHwnds = @($currentHwnds | Where-Object { $beforeHwnds -notcontains $_ })
                if ($newHwnds.Count -gt 0) {
                    $zedHwnd = $newHwnds[0]
                    break
                }
            }
            if ($zedHwnd -eq [IntPtr]::Zero) {
                throw "Newly created Zed window not found"
            }
            L ("New Zed window found: HWND=0x{0:X}" -f $zedHwnd.ToInt64())
            Start-Sleep -Seconds 3

            L "Resizing Zed to 1440x852 client..."
            & pwsh -NoProfile -File 'tools/measure/window-rect.ps1' -ProcessName Zed -TargetHwnd ("0x{0:X}" -f $zedHwnd.ToInt64()) -Action Resize -X 232 -Y 90 -Width 1456 -Height 860 2>&1 | ForEach-Object { L "Zed resize: $_" }
            Start-Sleep -Seconds 2

            $zr = New-Object Order05Native+RECT
            [void][Order05Native]::GetClientRect($zedHwnd, [ref]$zr)
            [void][Order05Native]::ClientToScreen($zedHwnd, [ref]$zo)
            L "Zed client origin=($($zo.X),$($zo.Y)) size=$($zr.Right)x$($zr.Bottom)"

            $zedPrereqOk = $true
            $global:summary['zed']['prerequisite'] = "PASS"
            Ensure-Foreground $zedHwnd "Zed ready"
        } catch {
            $errMsg = $_.Exception.Message
            L "ERROR in Zed prerequisite: $errMsg"
            $global:summary['zed']['prerequisite'] = "FAIL: $errMsg"
        }

        if (-not $zedPrereqOk) {
            L "Skipping remainder of Zed measurements due to prerequisite failure."
            return
        }

        # -------------------------------------------------------------------
        # Zed Step 1: Title bar (Menu & Window Controls)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'zed-titlebar' 'Zed Title Bar' {
            Ensure-Foreground $zedHwnd "Zed Title Bar"
            Cap-Window $zedHwnd 'zed-titlebar' $Out
        }

        # -------------------------------------------------------------------
        # Zed Step 2: Tab Bar (Nav arrows, split, zoom, close, plus)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'zed-tabbar' 'Zed Tab Bar' {
            Ensure-Foreground $zedHwnd "Zed Tab Bar"
            Cap-Window $zedHwnd 'zed-tabbar' $Out
        }

        # -------------------------------------------------------------------
        # Zed Step 3: Quick Action Bar / Toolbar Eye
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'zed-toolbar' 'Zed Markdown Toolbar Eye' {
            Ensure-Foreground $zedHwnd "Zed Toolbar"
            Cap-Window $zedHwnd 'zed-toolbar' $Out
        }

        # -------------------------------------------------------------------
        # Zed Step 4: Status Bar Left
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'zed-statusbar' 'Zed Status Bar Left Icons' {
            Ensure-Foreground $zedHwnd "Zed Status Bar"
            Cap-Window $zedHwnd 'zed-statusbar' $Out
        }

        # -------------------------------------------------------------------
        # Zed Step 5: Project Panel Bottom & Folders
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'zed-project-panel' 'Zed Project Panel & Folders' {
            Ensure-Foreground $zedHwnd "Zed Project Panel"
            Cap-Window $zedHwnd 'zed-project-panel' $Out
        }

    } finally {
        # Close ONLY target Zed window via WM_CLOSE (PostMessage)
        if ($zedHwnd -ne [IntPtr]::Zero) {
            L ("Closing target Zed window only (HWND=0x{0:X}) via WM_CLOSE PostMessage..." -f $zedHwnd.ToInt64())
            [void][Order05Native]::PostMessage($zedHwnd, [Order05Native]::WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
            Start-Sleep -Seconds 2

            $stillAlive = [Order05Native]::IsWindow($zedHwnd)
            if ($stillAlive) {
                L ("Warning: Target Zed window HWND=0x{0:X} is still present (dialog or close pending)" -f $zedHwnd.ToInt64())
            } else {
                L ("Target Zed window HWND=0x{0:X} successfully closed" -f $zedHwnd.ToInt64())
            }
        }
    }
}

# ---------------------------------------------------------------------------
# 6. DryRun Mode
# ---------------------------------------------------------------------------
function Run-DryRun([string]$dumpPath) {
    L "=== DryRun Mode: Parsing layout boxes and computing crop coordinates from dump '$dumpPath' ==="
    $resolvedPath = [System.IO.Path]::GetFullPath($dumpPath, (Get-Location).Path)
    if (-not (Test-Path -LiteralPath $resolvedPath)) {
        throw "DryRun target dump file not found: $resolvedPath"
    }

    $snap = Get-LatestSnapshot '' $resolvedPath
    if (-not $snap) {
        throw "Failed to extract layout snapshot from: $resolvedPath"
    }

    L "Found layout snapshot seq=$($snap.seq) with $($snap.boxes.Count) probed boxes."

    # 1. Prerequisite verification check for markdown fixture and tree
    $targetFile = Get-TreeRowBoxByName ([IntPtr]::Zero) '' '00-order03.md' '' $resolvedPath
    if (-not $targetFile) {
        $targetFile = Get-TreeRowBoxByName ([IntPtr]::Zero) '' '00-order05.md' '' $resolvedPath
    }
    L "--------------------------------------------------"
    L "Step Prerequisites Simulation:"
    if ($targetFile) {
        L ("  Markdown Fixture Row in Tree: Index={0}, Box={1}, Basis='{2}'" -f $targetFile.Index, $targetFile.BoxName, $targetFile.Reason)
    } else {
        L "  Markdown Fixture Row in Tree: Fallback tree-row-03 will be used during live execution"
    }

    # 2. Check each requested step and verify prerequisite handling
    $allDefaultSteps = @('I1-titlebar-normal', 'I1-titlebar-maximized', 'I1-tabbar', 'I1-tabbar-zoomed', 'I1-tabbar-pinned', 'I1-toolbar', 'I1-tab-preview', 'I1-sidebar-open', 'I1-sidebar-closed', 'I18-statusbar', 'I1-tree-folders')
    $stepsToCheck = $allDefaultSteps | Where-Object { Should-RunStep $_ }

    foreach ($sKey in $stepsToCheck) {
        $prereqDesc = switch -Wildcard ($sKey) {
            '*toolbar*'     { "Requires Markdown file open -> calls Ensure-MarkdownFileOpen (opens 00-order03.md to yield 'toolbar-btn-preview')"; break }
            '*tab-preview*' { "Requires Markdown file open -> calls Ensure-MarkdownFileOpen, then triggers preview to yield 'file_doc'"; break }
            '*pinned*'      { "Requires Markdown file open -> calls Ensure-MarkdownFileOpen to yield 'tab-00', then sends Ctrl-K Shift-Enter"; break }
            '*tabbar*'      { "Requires tabs present -> calls Ensure-MarkdownFileOpen if empty"; break }
            '*sidebar*'     { "Operates sidebar toggle and buttons"; break }
            '*statusbar*'   { "Operates dock toggle and checks left status bar buttons"; break }
            '*tree*'        { "Requires project tree visible -> calls Ensure-ProjectTreeOpen"; break }
            default         { "Window client 1440x852"; break }
        }
        L ("  Step '{0}': Prerequisite -> {1}" -f $sKey, $prereqDesc)
    }
    L "--------------------------------------------------"

    # 3. Probes evaluation
    $expectedProbes = @(
        'app-menu-button',
        'window-controls',
        'sidebar-btn-toggle',
        'sidebar-btn-folder-add',
        'status-btn-project-panel',
        'tab-btn-back',
        'tab-btn-forward',
        'tab-btn-new',
        'tab-btn-split',
        'toolbar-btn-preview'
    )

    $foundCount = 0
    foreach ($pName in $expectedProbes) {
        if ($snap.boxes.Contains($pName)) {
            $b = $snap.boxes[$pName]
            $crop = Log-IconCrop $pName $pName $b.x $b.y $b.w $b.h ([IntPtr]::Zero)
            L ("  Found probe '{0}': client=({1},{2},{3},{4})" -f $pName, $b.x, $b.y, $b.w, $b.h)
            $foundCount++
        } else {
            L ("  Probe '{0}' not in this snapshot sequence (expected during specific UI state)" -f $pName)
        }
    }

    L "--------------------------------------------------"
    L "Probes evaluated: $foundCount / $($expectedProbes.Count) found in snapshot seq=$($snap.seq)"
    L "Active Steps    : $(($stepsToCheck) -join ', ')"
    if ($normalizedSkip.Count -gt 0) {
        L "Skipped Steps   : $(($normalizedSkip) -join ', ')"
    }
    L "Only parameter  : $Only"
    L "--------------------------------------------------"
    L "=== DryRun Complete ==="
}

# ---------------------------------------------------------------------------
# 7. Main Execution
# ---------------------------------------------------------------------------
if ($MyInvocation.InvocationName -ne '.') {
    if ($DryRunStdout) {
        Run-DryRun $DryRunStdout
        return
    }

    try {
        if ($Only -eq 'App' -or $Only -eq 'Both') {
            Run-AppMeasure
        }
        if ($normalizedSteps.Count -eq 0 -and ($Only -eq 'Zed' -or $Only -eq 'Both')) {
            Run-ZedMeasure
        }
        L "=== ORDER-05 V3 Capture Script Finished ==="
    } catch {
        L "FATAL ERROR: $($_.Exception.Message)"
        L "$($_.ScriptStackTrace)"
    } finally {
        $summaryFile = Join-Path $Out 'summary.json'
        $summaryJson = $global:summary | ConvertTo-Json -Depth 5
        $summaryJson | Set-Content -LiteralPath $summaryFile -Encoding utf8
        $cropsFile = Join-Path $Out 'crops.json'
        ($global:summary['crops'] | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $cropsFile -Encoding utf8
        L "=== Execution Summary written to $summaryFile ==="
    }
}

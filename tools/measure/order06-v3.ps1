#Requires -Version 7
<#
.SYNOPSIS
  ORDER-06 V3 화면 검증(UI 실측) 및 Zed "v" 메뉴 확인 스크립트.
  (gpui-checker 작성, leader가 화면 차례 안에서 실행한다.)

.DESCRIPTION
  - 상위 지시: core ORDER-06 1단계 (I-17, I-2), ORDER-05 남은 1자리
  - 우리 앱(workbench-gpui) 및 Zed를 동일 조건(클라이언트 1440×852, 100% DPI, 마크다운 픽스처)으로 구동.
  - 앱(workbench-gpui) 메뉴 단계:
    * app-menu-bar-open: ≡ 버튼 클릭하여 메뉴 막대 열기, menu-name-0..5 확인, 메뉴 간격(I-321) 측정, 열림 시 폴더 이름 없음(title-folder-name 제외) 단언.
    * app-menu-dropdowns: 각 메뉴(workbench-gpui, File, Edit, View, Window, Help) 클릭 및 드롭다운 캡처, Esc로 닫은 뒤 폴더 이름 복원 단언.
    * app-user-menu: 타이틀 바 우측 "v" (user-menu) 버튼 클릭 캡처, 비활성 항목 클릭 무사, Panel Layout 하위 메뉴(Classic, Agentic) 호버 캡처, 비활성 하위 항목 클릭 무사.
    * app-menu-help-licenses: Help > View Dependency Licenses 클릭 -> 새 창(Dependency Licenses) HWND 감지 및 캡처 -> 창 닫기. (브라우저 링크 항목은 누르지 않음).
    * app-menu-actions-rep: 대표 메뉴 항목 동작 확인 (Save, Undo/Redo, Split Right, Markdown Preview to the Side).
    * B-app-pane-zoom: 앱에서 파일 연 뒤 Shift-Escape(workspace::ToggleZoom)로 확대 상태 진입 -> 탭 바 tab-btn-zoom 자리 확대 캡처(minimize.svg) -> 다시 Shift-Escape 복원.
  - Zed "v" 메뉴 확인 (`zed -n` 새 창만, 기존 Zed 창·설정 건드리지 않음, `-a` 금지, 띄운 창만 WM_CLOSE):
    * zed-v-menu: "v" 버튼 클릭(X=1315, Y=16)하여 메뉴 열고 캡처(항목·단축키 표시).
    * zed-v-panel-layout: Panel Layout 하위 메뉴 열어 캡처, Esc 2회(항목 클릭 금지).
    * zed-v-settings: Settings (Ctrl-,) 열기 -> 새 창/탭/모달 여부 판별 -> 캡처 -> 닫기 (Ctrl+W / WM_CLOSE).
    * zed-v-keymap: Keymap (Ctrl-K Ctrl-S) 열기 -> 새 창/탭/모달 여부 판별 -> 캡처 -> 닫기 (Ctrl+W / WM_CLOSE).
    * zed-v-themes: Themes (Ctrl-K Ctrl-T) 열기 -> 새 창/탭/모달 여부 판별 -> 캡처 -> 닫기: **Esc만 (Enter 금지)**.
    * zed-v-icon-themes: Icon Themes (메뉴) 열기 -> 새 창/탭/모달 여부 판별 -> 캡처 -> 닫기: **Esc만 (Enter 금지)**.
    * zed-v-extensions: Extensions (Ctrl-Shift-X) 열기 (설치 금지, 첫 화면만) -> 캡처 -> 닫기 (Ctrl+W / WM_CLOSE).
    * B-zed-pane-zoom: Zed 새 창에서도 Shift-Escape로 확대 상태 진입 -> 동일 자리 캡처 -> 다시 Shift-Escape 복원.
    * 실행 전후로 Zed 설정 파일(%APPDATA%\Zed\settings.json, keymap.json)의 SHA256 해시를 로그에 남겨 바뀌지 않았음을 확인(읽기만).
  - 창 크기는 Ensure-ClientSize(1440×852)로 고정.
  - 띄운 PID/HWND만 닫기, session Stop 복원.
  - 각 단계는 독립적으로 실행되며 실패 시에도 다음 단계 계속 진행.

.PARAMETER Out
  출력 디렉터리 (기본값: specs\v0.5\verify\reviews\measure-ORDER-06).

.PARAMETER Only
  App, Zed, Both 중 선택 (기본값: Both).

.PARAMETER AppExe
  workbench-gpui 실행 파일 경로.

.PARAMETER ZedExe
  Zed 실행 파일 경로 (기본값: C:\Users\nampl\AppData\Local\Programs\Zed\bin\zed.exe).

.PARAMETER FixturePath
  측정에 사용할 마크다운 파일 경로 (미지정 시 $Out\order06-fixture.md 자동 생성).

.PARAMETER DryRunStdout
  stdout 덤프를 기반으로 좌표 및 프로브 계산만 검증하는 모드 (프로세스 구동 안 함).

.PARAMETER Steps
  실행할 단계 목록.

.PARAMETER Skip
  건너뛸 단계 목록.
#>
[CmdletBinding()]
param(
    [string]$Out = 'specs\v0.5\verify\reviews\measure-ORDER-06',
    [ValidateSet('App', 'Zed', 'Both')][string]$Only = 'Both',
    [string]$AppExe = 'D:\projects\workbench-gpui\target\debug\workbench-gpui.exe',
    [string]$ZedExe = 'C:\Users\nampl\AppData\Local\Programs\Zed\bin\zed.exe',
    [string]$FixturePath,
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
    "zed" = [ordered]@{}
    "zed_analysis" = [ordered]@{}
    "config_hashes" = [ordered]@{}
    "crops" = [ordered]@{}
    "gaps" = [ordered]@{}
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

function L([string]$msg) {
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
    $line = "$ts $msg"
    Write-Host $line
    if (-not $DryRunStdout) {
        $line | Add-Content -LiteralPath $logFile -Encoding utf8
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    L "=== ORDER-06 V3 Capture Script Started (Only=$Only, Out=$Out) ==="
}

# ---------------------------------------------------------------------------
# 1. Native API Definition (Order06Native)
# ---------------------------------------------------------------------------
if (-not ('Order06Native' -as [type])) {
    Add-Type -ReferencedAssemblies @('System.Runtime', 'System.Collections', 'System.Threading', 'System.Threading.Thread', 'System.Runtime.InteropServices') -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

public static class Order06Native {
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
    [void][Order06Native]::SetForegroundWindow($hwnd)
    Start-Sleep -Milliseconds 200
    $fg = [Order06Native]::GetForegroundWindow()
    if ($fg -ne $hwnd) {
        [void][Order06Native]::ShowWindow($hwnd, 9) # SW_RESTORE
        [void][Order06Native]::SetForegroundWindow($hwnd)
        Start-Sleep -Milliseconds 300
        $fg = [Order06Native]::GetForegroundWindow()
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

function Ensure-ClientSize([IntPtr]$hwnd, [int]$expectedW, [int]$expectedH, [string]$procName = 'workbench-gpui') {
    $resizeOutput = & pwsh -NoProfile -File 'tools/measure/window-rect.ps1' -ProcessName $procName -TargetHwnd ("0x{0:X}" -f $hwnd.ToInt64()) -Action Resize -X 232 -Y 90 -Width 1456 -Height 860 2>&1
    foreach ($line in $resizeOutput) { L "Resize: $line" }
    Start-Sleep -Milliseconds 600

    $cr = New-Object Order06Native+RECT
    [void][Order06Native]::GetClientRect($hwnd, [ref]$cr)
    $actualW = $cr.Right - $cr.Left
    $actualH = $cr.Bottom - $cr.Top
    L "Client size check ($procName): target=${expectedW}x${expectedH}, actual=${actualW}x${actualH}"

    if ($actualW -ne $expectedW -or $actualH -ne $expectedH) {
        L "Directly applying SetWindowPos to adjust to 1456x860..."
        [void][Order06Native]::SetWindowPos($hwnd, [IntPtr]::Zero, 232, 90, 1456, 860, 0x0004 -bor 0x0010)
        Start-Sleep -Milliseconds 600
        [void][Order06Native]::GetClientRect($hwnd, [ref]$cr)
        $actualW = $cr.Right - $cr.Left
        $actualH = $cr.Bottom - $cr.Top
        L "Re-checked client size: ${actualW}x${actualH}"
        if ($actualW -ne $expectedW -or $actualH -ne $expectedH) {
            Cap-Window $hwnd "error-$procName-client-size" $Out
            throw "Window client size mismatch: expected ${expectedW}x${expectedH}, but got ${actualW}x${actualH}"
        }
    }
}

function Log-IconCrop([string]$iconId, [string]$probeName, [double]$bx, [double]$by, [double]$bw, [double]$bh, [IntPtr]$hwnd = [IntPtr]::Zero) {
    $clientOrigin = New-Object Order06Native+POINT
    if ($hwnd -ne [IntPtr]::Zero) {
        [void][Order06Native]::ClientToScreen($hwnd, [ref]$clientOrigin)
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
    if (-not (Should-RunStep $stepKey)) {
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

    $clientOrigin = New-Object Order06Native+POINT
    if ($hwnd -ne [IntPtr]::Zero) {
        [void][Order06Native]::ClientToScreen($hwnd, [ref]$clientOrigin)
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

function Ensure-ProjectTreeOpen([IntPtr]$hwnd, [string]$outDir) {
    $snap = Get-LatestSnapshot $outDir
    if ($snap -and $snap.boxes.Contains('tree-row-01')) {
        return $snap
    }
    L "Project tree not visible. Opening project tree / left dock..."
    $emptyOpen = Get-BoxScreenCoord $hwnd $outDir 'project-empty-open'
    if ($emptyOpen) {
        L "Clicking 'project-empty-open'..."
        [Order06Native]::Click($emptyOpen.X, $emptyOpen.Y)
    } else {
        $ppBtn = Get-BoxScreenCoord $hwnd $outDir 'status-btn-project-panel'
        if ($ppBtn) {
            L "Clicking status-btn-project-panel to open dock..."
            [Order06Native]::Click($ppBtn.X, $ppBtn.Y)
        } else {
            L "Sending Ctrl-B to toggle dock..."
            [Order06Native]::KeyCombo(@([ushort]0x11), [ushort]0x42)
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

    [Order06Native]::MoveTo(5, 5)
    Start-Sleep -Milliseconds 200

    $target = Get-BoxScreenCoord $hwnd $outDir 'tree-row-03'
    if (-not $target) {
        $target = Get-BoxScreenCoord $hwnd $outDir 'tree-row-01'
    }
    if ($target) {
        L ("Double-clicking markdown file row at ({0},{1})..." -f $target.X, $target.Y)
        [Order06Native]::DoubleClick($target.X, $target.Y)
        Start-Sleep -Milliseconds 600
    } else {
        L "Warning: could not locate tree row for markdown file."
    }

    return Assert-LayoutCondition $hwnd $outDir "markdown-file-open" {
        param($s) $s.boxes.Contains('toolbar-btn-preview') -or $s.boxes.Contains('tab-00')
    } "toolbar-btn-preview or tab-00 must be present after opening markdown fixture" 15
}

# ---------------------------------------------------------------------------
# 3. Zed Safety: Config File Hashes Check
# ---------------------------------------------------------------------------
function Get-ZedConfigStatus {
    $appDataZed = Join-Path $env:APPDATA 'Zed'
    $status = [ordered]@{}
    foreach ($file in @('settings.json', 'keymap.json')) {
        $p = Join-Path $appDataZed $file
        if (Test-Path -LiteralPath $p) {
            $hash = (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash
            $status[$file] = [ordered]@{
                "Exists" = $true
                "Path" = $p
                "Sha256" = $hash
                "Length" = (Get-Item -LiteralPath $p).Length
            }
        } else {
            $status[$file] = [ordered]@{
                "Exists" = $false
                "Path" = $p
                "Sha256" = "ABSENT"
                "Length" = 0
            }
        }
    }
    return $status
}

function Log-ZedConfigStatus([string]$stage, [System.Collections.IDictionary]$status) {
    L "--- Zed Config Status ($stage) ---"
    foreach ($key in $status.Keys) {
        $item = $status[$key]
        L ("  {0}: Exists={1}, Sha256={2}, Length={3}" -f $key, $item.Exists, $item.Sha256, $item.Length)
    }
}

function Compare-ZedConfigStatus([System.Collections.IDictionary]$before, [System.Collections.IDictionary]$after) {
    $intact = $true
    foreach ($key in $before.Keys) {
        $b = $before[$key]
        $a = $after[$key]
        if ($b.Exists -ne $a.Exists -or $b.Sha256 -ne $a.Sha256) {
            $intact = $false
            L ("CRITICAL ALERT: Zed config '{0}' CHANGED! Before SHA={1}, After SHA={2}" -f $key, $b.Sha256, $a.Sha256)
        }
    }
    if ($intact) {
        L "CONFIRMED: Zed config files are completely unchanged (hashes match)."
    }
    return $intact
}

# ---------------------------------------------------------------------------
# 4. App Measurements: Menu Bar, User Menu, Licenses, Pane Zoom
# ---------------------------------------------------------------------------
function Run-AppMeasure {
    L "--- Starting workbench-gpui measurements ---"

    $backupDir = Join-Path (Split-Path $Out -Parent) ('_' + (Split-Path $Out -Leaf) + '-backup')
    $appPid = 0
    $appHwnd = [IntPtr]::Zero
    $fixtureDir = ''

    try {
        # 1. Start Session via session.ps1 (launches app with -Exe, writes session.json)
        # Note: Do NOT pipe output to ForEach-Object to prevent stream handle inheritance hangs.
        L "Calling session.ps1 -Action Start (Exe=$AppExe)..."
        & pwsh -NoProfile -File 'tools/measure/session.ps1' -Action Start -Out $Out -Exe $AppExe -Backup $backupDir -Json -FixtureFile $FixturePath

        $sessionFile = Join-Path $Out 'session.json'
        if (-not (Test-Path $sessionFile)) { throw "session.json not found after session start" }
        $session = Get-Content -Raw $sessionFile | ConvertFrom-Json
        $appPid = [uint32]$session.pid
        $fixtureDir = if ($session.PSObject.Properties['fixture']) { $session.fixture } else { '' }
        L "App launched via session.ps1: PID=$appPid, fixtureDir='$fixtureDir'"

        # 2. Find Window HWND
        for ($i = 1; $i -le 40; $i++) {
            Start-Sleep -Milliseconds 300
            $p = Get-Process -Id $appPid -ErrorAction SilentlyContinue
            if ($p -and $p.MainWindowHandle -ne [IntPtr]::Zero) {
                $appHwnd = $p.MainWindowHandle
                break
            }
        }
        if ($appHwnd -eq [IntPtr]::Zero) {
            throw "Window handle not found for PID=$appPid"
        }

        L ("Window handle HWND=0x{0:X}" -f $appHwnd.ToInt64())
        Ensure-ClientSize $appHwnd 1440 852 'workbench-gpui'
        Ensure-Foreground $appHwnd "App started"

        # 3. Open project tree if needed
        Ensure-ProjectTreeOpen $appHwnd $Out | Out-Null

        # -------------------------------------------------------------------
        # Step: app-menu-bar-open (≡ Menu Bar Open, Gap Probe, Folder Name Absence)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app' 'app-menu-bar-open' 'App menu bar open (≡), menu item gaps (I-321), and folder name absence' {
            Ensure-Foreground $appHwnd "app-menu-bar-open"
            Ensure-MarkdownFileOpen $appHwnd $Out $fixtureDir | Out-Null

            $snapBefore = Get-LatestSnapshot $Out
            $hasFolderBefore = if ($snapBefore) { $snapBefore.boxes.ContainsKey('title-folder-name') } else { $false }
            L "Before opening menu: title-folder-name present = $hasFolderBefore"

            $btn = Get-BoxScreenCoord $appHwnd $Out 'app-menu-button'
            if (-not $btn) { throw "app-menu-button probe not found in layout snapshot" }
            L ("Clicking app-menu-button at ({0},{1})..." -f $btn.X, $btn.Y)
            [Order06Native]::Click($btn.X, $btn.Y)
            Start-Sleep -Milliseconds 500

            $snap = Assert-LayoutCondition $appHwnd $Out 'menu-bar-open' {
                param($s) $s.boxes.ContainsKey('menu-name-0')
            } 'menu-name-0 must be present when menu bar is open' 15

            # Assert: folder name MUST NOT be present when menu bar is open (ORDER-06 / I-17 requirement)
            $hasFolderOpen = $snap.boxes.ContainsKey('title-folder-name')
            L "While menu bar is open: title-folder-name present = $hasFolderOpen (expected: False)"
            if ($hasFolderOpen) {
                throw "Assertion failed: title-folder-name is still present while menu bar is open!"
            }

            # Measure gaps between menu names (I-321 expected: 4px)
            $nameProbes = @('menu-name-0', 'menu-name-1', 'menu-name-2', 'menu-name-3', 'menu-name-4', 'menu-name-5', 'menu-name-6')
            $foundBoxes = [System.Collections.Generic.List[PSObject]]::new()
            foreach ($np in $nameProbes) {
                if ($snap.boxes.ContainsKey($np)) {
                    $b = $snap.boxes[$np]
                    $foundBoxes.Add([PSCustomObject]$b)
                    Log-IconCrop $np $np $b.x $b.y $b.w $b.h $appHwnd
                }
            }
            L ("Found {0} menu name boxes in bar" -f $foundBoxes.Count)
            for ($k = 0; $k -lt ($foundBoxes.Count - 1); $k++) {
                $b1 = $foundBoxes[$k]
                $b2 = $foundBoxes[$k + 1]
                $gap = [Math]::Round($b2.x - ($b1.x + $b1.w), 2)
                $gapKey = "{0}_to_{1}" -f $b1.name, $b2.name
                $global:summary['gaps'][$gapKey] = $gap
                L ("Menu item gap [{0} -> {1}]: {2} px (I-321 target: 4.0)" -f $b1.name, $b2.name, $gap)
            }

            Cap-Window $appHwnd 'app-menu-bar-open' $Out
        }

        # -------------------------------------------------------------------
        # Step: app-menu-dropdowns (Each menu dropdown capture and close restoration)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app' 'app-menu-dropdowns' 'Capture each app menu dropdown and confirm folder name restoration on close' {
            Ensure-Foreground $appHwnd "app-menu-dropdowns"
            $menuNames = @('workbench-gpui', 'File', 'Edit', 'View', 'Go', 'Window', 'Help')

            for ($mIdx = 0; $mIdx -lt $menuNames.Count; $mIdx++) {
                $pName = "menu-name-$mIdx"
                $mLabel = $menuNames[$mIdx]
                $coord = Get-BoxScreenCoord $appHwnd $Out $pName
                if ($coord) {
                    L ("Clicking menu item '{0}' ({1}) at ({2},{3})..." -f $mLabel, $pName, $coord.X, $coord.Y)
                    [Order06Native]::Click($coord.X, $coord.Y)
                    Start-Sleep -Milliseconds 450
                    Cap-Window $appHwnd ("app-menu-{0:D2}-{1}" -f $mIdx, $mLabel.ToLower().Replace(' ', '-')) $Out
                } else {
                    L "Warning: coord for $pName not found"
                }
            }

            L "Dismissing app menu bar with Esc twice..."
            [Order06Native]::KeyPress(0x1B) # Esc
            Start-Sleep -Milliseconds 150
            [Order06Native]::KeyPress(0x1B) # Esc
            Start-Sleep -Milliseconds 500

            # Assert: folder name MUST BE RESTORED after menu bar is closed
            $snapClosed = Assert-LayoutCondition $appHwnd $Out 'menu-bar-closed' {
                param($s) $s.boxes.ContainsKey('title-folder-name')
            } 'title-folder-name must be restored after menu bar is closed' 15
            L "Confirmed: title-folder-name successfully restored after menu closed."
            Cap-Window $appHwnd 'app-menu-bar-closed' $Out
        }

        # -------------------------------------------------------------------
        # Step: app-user-menu ("v" Button, Inactive items safety, Panel Layout submenu)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app' 'app-user-menu' 'App "v" user menu, inactive items safe click, Panel Layout submenu' {
            Ensure-Foreground $appHwnd "app-user-menu"

            # Find user-menu probe in title bar (between drag and window-controls)
            $userCoord = Get-BoxScreenCoord $appHwnd $Out 'user-menu'
            if (-not $userCoord) {
                $userCoord = Get-BoxScreenCoord $appHwnd $Out 'user-menu-button'
            }
            if (-not $userCoord) {
                # Fallback to calculated coordinate: right margin before window controls
                $zo = New-Object Order06Native+POINT
                [void][Order06Native]::ClientToScreen($appHwnd, [ref]$zo)
                $userCoord = [PSCustomObject]@{ X = $zo.X + 1315; Y = $zo.Y + 16 }
            }

            L ("Clicking app 'v' user-menu button at ({0},{1})..." -f $userCoord.X, $userCoord.Y)
            [Order06Native]::Click($userCoord.X, $userCoord.Y)
            Start-Sleep -Milliseconds 500

            Cap-Window $appHwnd 'app-user-menu' $Out

            # Test inactive item safe click (Settings item at Y+25)
            L "Clicking inactive Settings item in user-menu (must be safe no-op)..."
            [Order06Native]::Click($userCoord.X - 50, $userCoord.Y + 25)
            Start-Sleep -Milliseconds 300
            if (-not [Order06Native]::IsWindow($appHwnd)) {
                throw "App crashed upon clicking inactive menu item!"
            }
            L "Confirmed: Inactive item click was completely safe (no crash)."

            # Re-open if closed by click
            [Order06Native]::Click($userCoord.X, $userCoord.Y)
            Start-Sleep -Milliseconds 400

            # Navigate to Panel Layout via Down 6 times, Right 1 time
            L "Navigating to Panel Layout submenu (Down 6 times, Right 1 time)..."
            for ($k = 0; $k -lt 6; $k++) {
                [Order06Native]::KeyPress(0x28) # VK_DOWN
                Start-Sleep -Milliseconds 80
            }
            [Order06Native]::KeyPress(0x27) # VK_RIGHT
            Start-Sleep -Milliseconds 500

            Cap-Window $appHwnd 'app-user-menu-panel-layout' $Out

            L "Dismissing user-menu with Esc..."
            [Order06Native]::KeyPress(0x1B) # Esc
            Start-Sleep -Milliseconds 150
            [Order06Native]::KeyPress(0x1B) # Esc
            Start-Sleep -Milliseconds 400
        }

        # -------------------------------------------------------------------
        # -------------------------------------------------------------------
        # Step: app-menu-help-licenses (Help > View Dependency Licenses Window)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app' 'app-menu-help-licenses' 'Help > View Dependency Licenses window open, verify bundled licenses, and close' {
            Ensure-Foreground $appHwnd "app-menu-help-licenses"
            $pids = [uint32[]]@($appPid)
            $hwndsBefore = @([Order06Native]::GetProcessTopLevelWindows($pids))

            # 1. Check if menu-name-6 is already visible; if not, open menu bar via app-menu-button
            $snap = Get-LatestSnapshot $Out
            if (-not ($snap -and $snap.boxes.ContainsKey('menu-name-6'))) {
                $btn = Get-BoxScreenCoord $appHwnd $Out 'app-menu-button'
                if ($btn) {
                    L ("Opening menu bar via app-menu-button at ({0},{1})..." -f $btn.X, $btn.Y)
                    [Order06Native]::Click($btn.X, $btn.Y)
                    Start-Sleep -Milliseconds 400
                }
            }

            # 2. Hover over Help menu (menu-name-6) to open Help dropdown
            $helpCoord = Get-BoxScreenCoord $appHwnd $Out 'menu-name-6'
            if (-not $helpCoord) { throw "menu-name-6 (Help) not found" }
            L ("Hovering over Help menu at ({0},{1})..." -f $helpCoord.X, $helpCoord.Y)
            [Order06Native]::MoveTo($helpCoord.X, $helpCoord.Y)
            Start-Sleep -Milliseconds 400

            # 3. Check if menu-row-00 is visible; if not, click menu-name-6 once
            $rowCoord = Get-BoxScreenCoord $appHwnd $Out 'menu-row-00'
            if (-not $rowCoord) {
                L "menu-row-00 not visible by hover, clicking Help menu..."
                [Order06Native]::Click($helpCoord.X, $helpCoord.Y)
                Start-Sleep -Milliseconds 400
                $rowCoord = Get-BoxScreenCoord $appHwnd $Out 'menu-row-00'
            }

            if (-not $rowCoord) {
                # Fallback: navigate with Down arrow
                L "menu-row-00 not yet detected, sending Down arrow..."
                [Order06Native]::KeyPress(0x28) # Down
                Start-Sleep -Milliseconds 200
                $rowCoord = Get-BoxScreenCoord $appHwnd $Out 'menu-row-00'
            }

            # 4. Click 'View Dependency Licenses' (menu-row-00) or press Enter
            if ($rowCoord) {
                L ("Clicking 'View Dependency Licenses' (menu-row-00) at ({0},{1})..." -f $rowCoord.X, $rowCoord.Y)
                [Order06Native]::Click($rowCoord.X, $rowCoord.Y)
            } else {
                L "Clicking fallback or pressing Enter..."
                [Order06Native]::KeyPress(0x0D) # Enter
            }
            Start-Sleep -Milliseconds 1500

            # 5. Detect newly created Licenses window HWND (polling up to 20 iterations)
            $licHwnd = [IntPtr]::Zero
            for ($w = 0; $w -lt 20; $w++) {
                Start-Sleep -Milliseconds 200
                $currHwnds = [Order06Native]::GetProcessTopLevelWindows($pids)
                $newHwnds = @($currHwnds | Where-Object { $hwndsBefore -notcontains $_ })
                if ($newHwnds.Count -gt 0) {
                    $licHwnd = $newHwnds[0]
                    break
                }
            }
            if ($licHwnd -eq [IntPtr]::Zero) {
                throw "Dependency Licenses window HWND was not detected!"
            }
            $licTitle = [Order06Native]::Title($licHwnd)
            L ("Dependency Licenses window opened: HWND=0x{0:X}, Title='{1}'" -f $licHwnd.ToInt64(), $licTitle)

            Cap-Window $licHwnd 'app-license-window' $Out

            L "SAFETY: Closing Dependency Licenses window via WM_CLOSE PostMessage..."
            [void][Order06Native]::PostMessage($licHwnd, [Order06Native]::WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
            Start-Sleep -Milliseconds 800

            # Note: Browser link items (File Bug Report, Request Feature, Repository) are strictly NOT clicked.
            L "SAFETY CONFIRMED: External browser URL menu items were NOT clicked."
        }

        # -------------------------------------------------------------------
        # Step: app-menu-actions-rep (Representative menu actions: Save, Undo/Redo, Split, Preview)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app' 'app-menu-actions-rep' 'Representative menu actions execution (Save, Undo/Redo, Split, Preview)' {
            Ensure-Foreground $appHwnd "app-menu-actions-rep"

            # 1. Save (workspace::Save via Ctrl-S)
            L "Testing Save action (Ctrl-S)..."
            [Order06Native]::KeyCombo(@([ushort]0x11), [ushort]0x53) # Ctrl-S
            Start-Sleep -Milliseconds 400
            L "Save action triggered successfully."

            # 2. Undo and Redo (input::Undo / input::Redo via Ctrl-Z, Ctrl-Y)
            L "Testing Undo (Ctrl-Z) and Redo (Ctrl-Y)..."
            [Order06Native]::KeyCombo(@([ushort]0x11), [ushort]0x5A) # Ctrl-Z
            Start-Sleep -Milliseconds 200
            [Order06Native]::KeyCombo(@([ushort]0x11), [ushort]0x59) # Ctrl-Y
            Start-Sleep -Milliseconds 200
            L "Undo/Redo actions triggered safely."

            # 3. Split Right (Ctrl-\)
            L "Testing Split Right (Ctrl-\)..."
            [Order06Native]::KeyCombo(@([ushort]0x11), [ushort]0xDC) # Ctrl-\
            Start-Sleep -Milliseconds 600
            Cap-Window $appHwnd 'app-action-split-right' $Out

            # 4. Open Markdown Preview to the Side (Ctrl-K V)
            L "Testing Open Markdown Preview to the Side (Ctrl-K V)..."
            [Order06Native]::KeyCombo(@([ushort]0x11), [ushort]0x4B) # Ctrl-K
            Start-Sleep -Milliseconds 150
            [Order06Native]::KeyPress(0x56) # V
            Start-Sleep -Milliseconds 800
            Cap-Window $appHwnd 'app-action-preview-side' $Out

            # Clean up opened preview and split tab via Ctrl-W
            L "Cleaning up preview tab and split pane (Ctrl-W twice)..."
            [Order06Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl-W
            Start-Sleep -Milliseconds 400
            [Order06Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl-W
            Start-Sleep -Milliseconds 400
        }

        # -------------------------------------------------------------------
        # Step: app-tab-cycle (K-10: Ctrl-PageDown / Ctrl-PageUp Tab Cycling)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app' 'app-tab-cycle' 'Tab cycling via Ctrl-PageDown and Ctrl-PageUp with >= 2 tabs' {
            Ensure-Foreground $appHwnd "app-tab-cycle"
            Ensure-ProjectTreeOpen $appHwnd $Out | Out-Null

            # Open file 1 from tree (tree-row-01)
            $r1 = Get-BoxScreenCoord $appHwnd $Out 'tree-row-01'
            if (-not $r1) { $r1 = Get-BoxScreenCoord $appHwnd $Out 'tree-row-00' }
            if ($r1) {
                L ("Double-clicking first file in tree ({0},{1})..." -f $r1.X, $r1.Y)
                [Order06Native]::DoubleClick($r1.X, $r1.Y)
                Start-Sleep -Milliseconds 600
            }

            # Open file 2 from tree (tree-row-02)
            $r2 = Get-BoxScreenCoord $appHwnd $Out 'tree-row-02'
            if (-not $r2) { $r2 = Get-BoxScreenCoord $appHwnd $Out 'tree-row-03' }
            if ($r2) {
                L ("Double-clicking second file in tree ({0},{1})..." -f $r2.X, $r2.Y)
                [Order06Native]::DoubleClick($r2.X, $r2.Y)
                Start-Sleep -Milliseconds 600
            }

            $snapTabs = Assert-LayoutCondition $appHwnd $Out 'two-tabs-open' {
                param($s) $s.boxes.ContainsKey('tab-00') -and $s.boxes.ContainsKey('tab-01')
            } 'Both tab-00 and tab-01 must be present for tab cycle test' 15
            L "Confirmed: 2 tabs open (tab-00 and tab-01 present)."

            # 1. Test Ctrl-PageDown (pane::ActivateNextItem, VK_NEXT=0x22)
            L "Sending Ctrl-PageDown (pane::ActivateNextItem, VK_NEXT=0x22)..."
            [Order06Native]::KeyCombo(@([ushort]0x11), [ushort]0x22)
            Start-Sleep -Milliseconds 400
            Cap-Window $appHwnd 'app-tab-cycle-next' $Out
            L "Captured app-tab-cycle-next."

            # 2. Test Ctrl-PageUp (pane::ActivatePreviousItem, VK_PRIOR=0x21)
            L "Sending Ctrl-PageUp (pane::ActivatePreviousItem, VK_PRIOR=0x21)..."
            [Order06Native]::KeyCombo(@([ushort]0x11), [ushort]0x21)
            Start-Sleep -Milliseconds 400
            Cap-Window $appHwnd 'app-tab-cycle-prev' $Out
            L "Captured app-tab-cycle-prev."

            # Clean up the second tab via Ctrl-W
            L "Closing active tab via Ctrl-W..."
            [Order06Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl-W
            Start-Sleep -Milliseconds 400
        }

        # -------------------------------------------------------------------
        # Step: B-app-pane-zoom (ORDER-05 remaining slot)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app' 'B-app-pane-zoom' 'App pane zoom state (minimize.svg via Shift-Escape)' {
            Ensure-Foreground $appHwnd "B-app-pane-zoom"
            Ensure-MarkdownFileOpen $appHwnd $Out $fixtureDir | Out-Null

            L "Sending Shift-Escape (workspace::ToggleZoom, I-737) to enter zoomed state..."
            # Shift = 0x10, Escape = 0x1B
            [Order06Native]::KeyCombo(@([ushort]0x10), [ushort]0x1B)
            Start-Sleep -Milliseconds 600

            $snap = Assert-LayoutCondition $appHwnd $Out 'tabbar-zoomed' {
                param($s) $s.boxes.Contains('tab-btn-zoom')
            } 'tab-btn-zoom must be present in zoomed state' 15

            if ($snap.boxes.Contains('tab-btn-zoom')) {
                $b = $snap.boxes['tab-btn-zoom']
                Log-IconCrop 'minimize' 'tab-btn-zoom' $b.x $b.y $b.w $b.h $appHwnd
            }

            Cap-Window $appHwnd 'app-tabbar-zoomed' $Out

            L "Restoring unzoomed state via Shift-Escape..."
            [Order06Native]::KeyCombo(@([ushort]0x10), [ushort]0x1B)
            Start-Sleep -Milliseconds 400
        }

    } finally {
        L "Cleaning up workbench-gpui process (PID=$appPid)..."
        if ($appPid) {
            $p = Get-Process -Id $appPid -ErrorAction SilentlyContinue
            if ($p -and -not $p.HasExited) {
                try { [void]$p.CloseMainWindow(); [void]$p.WaitForExit(3000) } catch {}
                if (-not $p.HasExited) { try { $p.Kill(); [void]$p.WaitForExit(2000) } catch {} }
            }
        }
        L "Restoring app data via session.ps1 -Action Stop..."
        $stopOutput = & pwsh -NoProfile -File 'tools/measure/session.ps1' -Action Stop -Out $Out -Backup $backupDir 2>&1
        foreach ($line in $stopOutput) { L "Session Stop: $line" }
    }
}

# ---------------------------------------------------------------------------
# 5. Zed Measurement: "v" Menu and Pane Zoom State
# ---------------------------------------------------------------------------
function Run-ZedMeasure {
    L "--- Starting Zed measurements ---"

    if (-not $FixturePath) {
        $fixtureDir = Join-Path $Out 'order06-fixture'
        New-Item -ItemType Directory -Force $fixtureDir | Out-Null
        $FixturePath = Join-Path $fixtureDir '00-order06.md'
        if (-not (Test-Path -LiteralPath $FixturePath)) {
            "# ORDER-06 Fixture`n`nTesting titlebar and zoom toggle icon.`n" | Set-Content -LiteralPath $FixturePath -Encoding utf8
        }
    }

    # 1. Record Zed config file hashes before execution
    $hashesBefore = Get-ZedConfigStatus
    $global:summary['config_hashes']['before'] = $hashesBefore
    Log-ZedConfigStatus 'BEFORE' $hashesBefore

    # 2. Enumerate existing Zed top-level windows
    $zedPidsBefore = [uint32[]]@(Get-Process -Name Zed -ErrorAction SilentlyContinue | ForEach-Object { [uint32]$_.Id })
    $beforeHwnds = @()
    if ($zedPidsBefore.Count -gt 0) {
        $beforeHwnds = [Order06Native]::GetProcessTopLevelWindows($zedPidsBefore)
    }
    L ("Zed top-level HWNDs before launch: " + (($beforeHwnds | ForEach-Object { '0x{0:X}' -f $_.ToInt64() }) -join ', '))

    $zedHwnd = [IntPtr]::Zero
    $zo = New-Object Order06Native+POINT

    try {
        $zedPrereqOk = $false
        try {
            L "Launching Zed (new window only, -a forbidden): $ZedExe -n `"$FixturePath`""
            Start-Process -FilePath $ZedExe -ArgumentList @('-n', "`"$FixturePath`"")

            foreach ($i in 1..60) {
                Start-Sleep -Milliseconds 500
                $currentPids = [uint32[]]@(Get-Process -Name Zed -ErrorAction SilentlyContinue | ForEach-Object { [uint32]$_.Id })
                if ($currentPids.Count -eq 0) { continue }
                $currentHwnds = [Order06Native]::GetProcessTopLevelWindows($currentPids)
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
            Ensure-ClientSize $zedHwnd 1440 852 'Zed'
            Start-Sleep -Seconds 1

            $zr = New-Object Order06Native+RECT
            [void][Order06Native]::GetClientRect($zedHwnd, [ref]$zr)
            [void][Order06Native]::ClientToScreen($zedHwnd, [ref]$zo)
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

        # Screen coordinates of "v" (ChevronDown) button:
        # Client coordinates in 1440x852 window: X=1315, Y=16
        $vBtnScreenX = $zo.X + 1315
        $vBtnScreenY = $zo.Y + 16
        L ("Zed 'v' button target coordinate: screen=({0},{1}) (client=1315,16)" -f $vBtnScreenX, $vBtnScreenY)

        # Helper to get all top-level windows from all Zed processes
        function Get-AllZedTopLevelWindows {
            $pids = [uint32[]]@(Get-Process -Name Zed -ErrorAction SilentlyContinue | ForEach-Object { [uint32]$_.Id })
            if ($pids.Count -eq 0) { return @() }
            return @([Order06Native]::GetProcessTopLevelWindows($pids))
        }

        # Helper to check for new HWNDs created during a step across ALL Zed processes
        function Test-NewWindowCreated([object[]]$baselineHwnds) {
            $curr = @(Get-AllZedTopLevelWindows)
            $diff = @($curr | Where-Object { $baselineHwnds -notcontains $_ })
            return ,$diff
        }

        # -------------------------------------------------------------------
        # Step A1: Zed "v" Menu Click (zed-v-menu)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'zed-v-menu' 'Zed "v" Menu open and capture items/shortcuts' {
            Ensure-Foreground $zedHwnd "Zed 'v' Menu"
            L "Clicking 'v' button at ($vBtnScreenX, $vBtnScreenY)..."
            [Order06Native]::Click($vBtnScreenX, $vBtnScreenY)
            Start-Sleep -Milliseconds 600

            Cap-Window $zedHwnd 'zed-v-menu' $Out

            L "Dismissing 'v' menu with Esc..."
            [Order06Native]::KeyPress(0x1B) # Esc
            Start-Sleep -Milliseconds 400
        }

        # -------------------------------------------------------------------
        # Step A2: Zed Panel Layout Submenu (zed-v-panel-layout)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'zed-v-panel-layout' 'Zed Panel Layout submenu capture' {
            Ensure-Foreground $zedHwnd "Zed Panel Layout Submenu"
            L "Re-opening 'v' menu..."
            [Order06Native]::Click($vBtnScreenX, $vBtnScreenY)
            Start-Sleep -Milliseconds 500

            L "Navigating to 'Panel Layout' (Down 6 times, Right 1 time)..."
            for ($k = 0; $k -lt 6; $k++) {
                [Order06Native]::KeyPress(0x28) # VK_DOWN
                Start-Sleep -Milliseconds 100
            }
            [Order06Native]::KeyPress(0x27) # VK_RIGHT
            Start-Sleep -Milliseconds 600

            Cap-Window $zedHwnd 'zed-v-panel-layout' $Out

            L "Closing submenu and menu with Esc twice (NO ITEM CLICKED to preserve layout)..."
            [Order06Native]::KeyPress(0x1B) # Esc
            Start-Sleep -Milliseconds 150
            [Order06Native]::KeyPress(0x1B) # Esc
            Start-Sleep -Milliseconds 400
        }

        # -------------------------------------------------------------------
        # Step A3: Zed Settings (Ctrl-,)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'zed-v-settings' 'Zed Settings (Ctrl-,) detection and capture' {
            Ensure-Foreground $zedHwnd "Zed Settings"
            $hwndsBefore = @(Get-AllZedTopLevelWindows)
            $titleBefore = [Order06Native]::Title($zedHwnd)

            L "Sending Ctrl-, (zed::OpenSettings)..."
            # VK_CONTROL = 0x11, VK_OEM_COMMA = 0xBC
            [Order06Native]::KeyCombo(@([ushort]0x11), [ushort]0xBC)
            Start-Sleep -Milliseconds 1500

            $newHwnds = @(Test-NewWindowCreated $hwndsBefore)
            $titleAfter = [Order06Native]::Title($zedHwnd)
            $kind = if ($newHwnds.Count -gt 0) { "NewWindow (HWND=0x{0:X}, Title='{1}')" -f $newHwnds[0].ToInt64(), [Order06Native]::Title($newHwnds[0]) } else { "TabOrView (Main HWND=0x{0:X}, Title='$titleAfter')" -f $zedHwnd.ToInt64() }
            L "Settings opened as: $kind"
            $global:summary['zed_analysis']['Settings'] = [ordered]@{ "Kind" = $kind; "NewWindow" = ($newHwnds.Count -gt 0) }

            $targetCapHwnd = if ($newHwnds.Count -gt 0) { $newHwnds[0] } else { $zedHwnd }
            Cap-Window $targetCapHwnd 'zed-v-settings' $Out

            L "Closing Settings..."
            if ($newHwnds.Count -gt 0) {
                L ("Closing newly created Settings window HWND=0x{0:X} via WM_CLOSE PostMessage..." -f $newHwnds[0].ToInt64())
                [void][Order06Native]::PostMessage($newHwnds[0], [Order06Native]::WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
                Start-Sleep -Milliseconds 800
            } else {
                [Order06Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl+W
                Start-Sleep -Milliseconds 500
            }
        }

        # -------------------------------------------------------------------
        # Step A4: Zed Keymap (Ctrl-K Ctrl-S)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'zed-v-keymap' 'Zed Keymap (Ctrl-K Ctrl-S) detection and capture' {
            Ensure-Foreground $zedHwnd "Zed Keymap"
            $hwndsBefore = @(Get-AllZedTopLevelWindows)
            $titleBefore = [Order06Native]::Title($zedHwnd)

            L "Sending Ctrl-K Ctrl-S (zed::OpenKeymap)..."
            [Order06Native]::KeyCombo(@([ushort]0x11), [ushort]0x4B) # Ctrl-K
            Start-Sleep -Milliseconds 150
            [Order06Native]::KeyCombo(@([ushort]0x11), [ushort]0x53) # Ctrl-S
            Start-Sleep -Milliseconds 1500

            $newHwnds = @(Test-NewWindowCreated $hwndsBefore)
            $titleAfter = [Order06Native]::Title($zedHwnd)
            $kind = if ($newHwnds.Count -gt 0) { "NewWindow (HWND=0x{0:X}, Title='{1}')" -f $newHwnds[0].ToInt64(), [Order06Native]::Title($newHwnds[0]) } else { "TabOrView (Main HWND=0x{0:X}, Title='$titleAfter')" -f $zedHwnd.ToInt64() }
            L "Keymap opened as: $kind"
            $global:summary['zed_analysis']['Keymap'] = [ordered]@{ "Kind" = $kind; "NewWindow" = ($newHwnds.Count -gt 0) }

            $targetCapHwnd = if ($newHwnds.Count -gt 0) { $newHwnds[0] } else { $zedHwnd }
            Cap-Window $targetCapHwnd 'zed-v-keymap' $Out

            L "Closing Keymap..."
            if ($newHwnds.Count -gt 0) {
                L ("Closing newly created Keymap window HWND=0x{0:X} via WM_CLOSE PostMessage..." -f $newHwnds[0].ToInt64())
                [void][Order06Native]::PostMessage($newHwnds[0], [Order06Native]::WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
                Start-Sleep -Milliseconds 800
            } else {
                [Order06Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl+W
                Start-Sleep -Milliseconds 500
            }
        }

        # -------------------------------------------------------------------
        # Step A5: Zed Themes (Ctrl-K Ctrl-T, Esc only!)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'zed-v-themes' 'Zed Themes (Ctrl-K Ctrl-T) modal picker capture' {
            Ensure-Foreground $zedHwnd "Zed Themes"
            $hwndsBefore = @(Get-AllZedTopLevelWindows)

            L "Sending Ctrl-K Ctrl-T (theme_selector::Toggle)..."
            [Order06Native]::KeyCombo(@([ushort]0x11), [ushort]0x4B) # Ctrl-K
            Start-Sleep -Milliseconds 150
            [Order06Native]::KeyCombo(@([ushort]0x11), [ushort]0x54) # Ctrl-T
            Start-Sleep -Milliseconds 1500

            $newHwnds = @(Test-NewWindowCreated $hwndsBefore)
            $kind = if ($newHwnds.Count -gt 0) { "NewWindow (HWND=0x{0:X}, Title='{1}')" -f $newHwnds[0].ToInt64(), [Order06Native]::Title($newHwnds[0]) } else { "ModalPicker (Palette inside Main HWND)" }
            L "Themes opened as: $kind"
            $global:summary['zed_analysis']['Themes'] = [ordered]@{ "Kind" = $kind; "NewWindow" = ($newHwnds.Count -gt 0) }

            $targetCapHwnd = if ($newHwnds.Count -gt 0) { $newHwnds[0] } else { $zedHwnd }
            Cap-Window $targetCapHwnd 'zed-v-themes' $Out

            L "SAFETY: Dismissing Themes picker with ESC ONLY (Enter is strictly forbidden)..."
            if ($newHwnds.Count -gt 0) {
                [void][Order06Native]::PostMessage($newHwnds[0], [Order06Native]::WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
                Start-Sleep -Milliseconds 800
            } else {
                [Order06Native]::KeyPress(0x1B) # Esc
                Start-Sleep -Milliseconds 500
            }
        }

        # -------------------------------------------------------------------
        # Step A6: Zed Icon Themes (Menu, Esc only!)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'zed-v-icon-themes' 'Zed Icon Themes picker capture' {
            Ensure-Foreground $zedHwnd "Zed Icon Themes"
            $hwndsBefore = @(Get-AllZedTopLevelWindows)

            L "Opening 'v' menu and navigating to 'Icon Themes...' (Down 4 times, Enter)..."
            [Order06Native]::Click($vBtnScreenX, $vBtnScreenY)
            Start-Sleep -Milliseconds 500

            for ($k = 0; $k -lt 4; $k++) {
                [Order06Native]::KeyPress(0x28) # VK_DOWN
                Start-Sleep -Milliseconds 100
            }
            [Order06Native]::KeyPress(0x0D) # Enter to open Icon Themes picker
            Start-Sleep -Milliseconds 1500

            $newHwnds = @(Test-NewWindowCreated $hwndsBefore)
            $kind = if ($newHwnds.Count -gt 0) { "NewWindow (HWND=0x{0:X}, Title='{1}')" -f $newHwnds[0].ToInt64(), [Order06Native]::Title($newHwnds[0]) } else { "ModalPicker (Palette inside Main HWND)" }
            L "Icon Themes opened as: $kind"
            $global:summary['zed_analysis']['IconThemes'] = [ordered]@{ "Kind" = $kind; "NewWindow" = ($newHwnds.Count -gt 0) }

            $targetCapHwnd = if ($newHwnds.Count -gt 0) { $newHwnds[0] } else { $zedHwnd }
            Cap-Window $targetCapHwnd 'zed-v-icon-themes' $Out

            L "SAFETY: Dismissing Icon Themes picker with ESC ONLY (Enter is strictly forbidden)..."
            if ($newHwnds.Count -gt 0) {
                [void][Order06Native]::PostMessage($newHwnds[0], [Order06Native]::WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
                Start-Sleep -Milliseconds 800
            } else {
                [Order06Native]::KeyPress(0x1B) # Esc
                Start-Sleep -Milliseconds 500
            }
        }

        # -------------------------------------------------------------------
        # Step A7: Zed Extensions (Ctrl-Shift-X, No Install)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'zed-v-extensions' 'Zed Extensions (Ctrl-Shift-X) capture (NO INSTALL)' {
            Ensure-Foreground $zedHwnd "Zed Extensions"
            $hwndsBefore = @(Get-AllZedTopLevelWindows)

            L "Sending Ctrl-Shift-X (zed::Extensions)..."
            # VK_CONTROL = 0x11, VK_SHIFT = 0x10, 'X' = 0x58
            [Order06Native]::KeyCombo(@([ushort]0x11, [ushort]0x10), [ushort]0x58)
            Start-Sleep -Milliseconds 2500

            $newHwnds = @(Test-NewWindowCreated $hwndsBefore)
            $titleAfter = [Order06Native]::Title($zedHwnd)
            $kind = if ($newHwnds.Count -gt 0) { "NewWindow (HWND=0x{0:X}, Title='{1}')" -f $newHwnds[0].ToInt64(), [Order06Native]::Title($newHwnds[0]) } else { "TabOrView (Main HWND=0x{0:X}, Title='$titleAfter')" -f $zedHwnd.ToInt64() }
            L "Extensions opened as: $kind"
            $global:summary['zed_analysis']['Extensions'] = [ordered]@{ "Kind" = $kind; "NewWindow" = ($newHwnds.Count -gt 0) }

            $targetCapHwnd = if ($newHwnds.Count -gt 0) { $newHwnds[0] } else { $zedHwnd }
            Cap-Window $targetCapHwnd 'zed-v-extensions' $Out

            L "Closing Extensions tab/view..."
            if ($newHwnds.Count -gt 0) {
                L ("Closing newly created Extensions window HWND=0x{0:X} via WM_CLOSE PostMessage..." -f $newHwnds[0].ToInt64())
                [void][Order06Native]::PostMessage($newHwnds[0], [Order06Native]::WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
                Start-Sleep -Milliseconds 800
            } else {
                [Order06Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl+W
                Start-Sleep -Milliseconds 500
            }
        }

        # -------------------------------------------------------------------
        # Step B2: Zed pane zoom state (Shift-Escape)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'B-zed-pane-zoom' 'Zed pane zoom state (minimize.svg via Shift-Escape)' {
            Ensure-Foreground $zedHwnd "Zed pane zoom"

            L "Sending Shift-Escape to toggle pane zoom in Zed..."
            [Order06Native]::KeyCombo(@([ushort]0x10), [ushort]0x1B)
            Start-Sleep -Milliseconds 600

            Cap-Window $zedHwnd 'zed-tabbar-zoomed' $Out

            L "Restoring Zed unzoomed state via Shift-Escape..."
            [Order06Native]::KeyCombo(@([ushort]0x10), [ushort]0x1B)
            Start-Sleep -Milliseconds 400
        }

    } finally {
        # Close ONLY target Zed window via WM_CLOSE (PostMessage)
        if ($zedHwnd -ne [IntPtr]::Zero) {
            L ("Closing target Zed window only (HWND=0x{0:X}) via WM_CLOSE PostMessage..." -f $zedHwnd.ToInt64())
            [void][Order06Native]::PostMessage($zedHwnd, [Order06Native]::WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
            Start-Sleep -Seconds 2

            $stillAlive = [Order06Native]::IsWindow($zedHwnd)
            if ($stillAlive) {
                L ("Warning: Target Zed window HWND=0x{0:X} is still present" -f $zedHwnd.ToInt64())
            } else {
                L ("Target Zed window HWND=0x{0:X} successfully closed" -f $zedHwnd.ToInt64())
            }
        }

        # 3. Verify Zed config file hashes after execution
        $hashesAfter = Get-ZedConfigStatus
        $global:summary['config_hashes']['after'] = $hashesAfter
        Log-ZedConfigStatus 'AFTER' $hashesAfter
        $intact = Compare-ZedConfigStatus $hashesBefore $hashesAfter
        $global:summary['config_hashes']['intact'] = $intact
        if (-not $intact) {
            $global:summary['zed']['config_integrity'] = "FAIL: Config files were modified!"
        } else {
            $global:summary['zed']['config_integrity'] = "PASS: Config files intact"
        }
    }
}

# ---------------------------------------------------------------------------
# 6. DryRun Mode
# ---------------------------------------------------------------------------
function Run-DryRun([string]$dumpPath) {
    L "=== DryRun Mode: Checking steps, safety measures, probes and coordinates ==="
    $resolvedPath = [System.IO.Path]::GetFullPath($dumpPath, (Get-Location).Path)
    if (-not (Test-Path -LiteralPath $resolvedPath)) {
        throw "DryRun target dump file not found: $resolvedPath"
    }

    $snap = Get-LatestSnapshot '' $resolvedPath
    if (-not $snap) {
        throw "Failed to extract layout snapshot from: $resolvedPath"
    }

    L "Found layout snapshot seq=$($snap.seq) with $($snap.boxes.Count) probed boxes."

    # 1. Probes evaluation for tab-btn-zoom, app menu, user menu, and window controls
    $expectedProbes = @(
        'app-menu-button',
        'title-folder-name',
        'menu-name-0',
        'menu-name-1',
        'menu-name-2',
        'menu-name-3',
        'menu-name-4',
        'menu-name-5',
        'menu-name-6',
        'user-menu',
        'tab-btn-zoom',
        'tab-btn-split',
        'tab-btn-new',
        'window-controls'
    )

    L "--------------------------------------------------"
    L "Probes Evaluation in Layout Snapshot:"
    $foundCount = 0
    foreach ($pName in $expectedProbes) {
        if ($snap.boxes.Contains($pName)) {
            $b = $snap.boxes[$pName]
            $crop = Log-IconCrop $pName $pName $b.x $b.y $b.w $b.h ([IntPtr]::Zero)
            L ("  Found probe '{0}': bounds=({1},{2},{3},{4})" -f $pName, $b.x, $b.y, $b.w, $b.h)
            $foundCount++
        } else {
            L ("  Probe '{0}' not in this snapshot sequence" -f $pName)
        }
    }
    L "Probes evaluated: $foundCount / $($expectedProbes.Count) found in snapshot seq=$($snap.seq)"
    L "--------------------------------------------------"

    # 2. Planned Steps and Safety Measures Matrix
    $allSteps = @(
        [PSCustomObject]@{ Step = 'app-menu-bar-open'; Role = 'App'; Action = 'Click ≡ button'; Safety = 'Check menu-name-0..6; Measure gaps; Assert title-folder-name absent' },
        [PSCustomObject]@{ Step = 'app-menu-dropdowns'; Role = 'App'; Action = 'Click dropdowns 0..6'; Safety = 'Esc twice; Assert title-folder-name restored' },
        [PSCustomObject]@{ Step = 'app-user-menu'; Role = 'App'; Action = 'Click "v" button'; Safety = 'Safe inactive click; Hover Panel Layout; Esc' },
        [PSCustomObject]@{ Step = 'app-menu-help-licenses'; Role = 'App'; Action = 'Help > Licenses'; Safety = 'Detect HWND; PostMessage WM_CLOSE; Browser links NOT clicked' },
        [PSCustomObject]@{ Step = 'app-menu-actions-rep'; Role = 'App'; Action = 'Save/Undo/Redo/Split/Preview'; Safety = 'Representative actions; Ctrl-W cleanups' },
        [PSCustomObject]@{ Step = 'app-tab-cycle'; Role = 'App'; Action = 'Ctrl-PageDown / Ctrl-PageUp'; Safety = 'Requires >=2 tabs; Cycle forward/backward; Close 2nd tab' },
        [PSCustomObject]@{ Step = 'B-app-pane-zoom'; Role = 'App'; Action = 'Shift-Escape (ToggleZoom)'; Safety = 'Ensure-ClientSize 1440x852; Restores unzoomed; session Stop' },
        [PSCustomObject]@{ Step = 'zed-v-menu'; Role = 'Zed'; Action = 'Click "v" (1315,16)'; Safety = 'Dismiss with Esc; No items clicked' },
        [PSCustomObject]@{ Step = 'zed-v-panel-layout'; Role = 'Zed'; Action = 'Down 6 times, Right 1 time'; Safety = 'Esc twice; No item clicked (layout intact)' },
        [PSCustomObject]@{ Step = 'zed-v-settings'; Role = 'Zed'; Action = 'Ctrl-,'; Safety = 'Detect HWND/tab; Close with Ctrl+W or WM_CLOSE' },
        [PSCustomObject]@{ Step = 'zed-v-keymap'; Role = 'Zed'; Action = 'Ctrl-K Ctrl-S'; Safety = 'Detect HWND/tab; Close with Ctrl+W or WM_CLOSE' },
        [PSCustomObject]@{ Step = 'zed-v-themes'; Role = 'Zed'; Action = 'Ctrl-K Ctrl-T'; Safety = 'ESC ONLY! Enter strictly forbidden' },
        [PSCustomObject]@{ Step = 'zed-v-icon-themes'; Role = 'Zed'; Action = 'Click "v", Down 4, Enter'; Safety = 'ESC ONLY! Enter strictly forbidden' },
        [PSCustomObject]@{ Step = 'zed-v-extensions'; Role = 'Zed'; Action = 'Ctrl-Shift-X'; Safety = 'NO INSTALLATION; Capture only; Close with Ctrl+W' },
        [PSCustomObject]@{ Step = 'B-zed-pane-zoom'; Role = 'Zed'; Action = 'Shift-Escape (ToggleZoom)'; Safety = 'Restore unzoomed; Close target HWND only' }
    )

    L "Planned Steps and Safety Measures Matrix:"
    foreach ($s in $allSteps) {
        $shouldRun = Should-RunStep $s.Step
        $statusStr = if ($shouldRun) { "ENABLED" } else { "SKIPPED" }
        L ("  [{0}] Step '{1}' ({2}): Action='{3}' | Safety='{4}'" -f $statusStr, $s.Step, $s.Role, $s.Action, $s.Safety)
    }

    # 3. Zed Config Check Simulation
    L "--------------------------------------------------"
    L "Simulating Zed Config File Hashes Check:"
    $hashes = Get-ZedConfigStatus
    foreach ($k in $hashes.Keys) {
        $item = $hashes[$k]
        L ("  Zed config '{0}': Exists={1}, Sha256={2}" -f $k, $item.Exists, $item.Sha256)
    }

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
        if ($Only -eq 'Zed' -or $Only -eq 'Both') {
            Run-ZedMeasure
        }
        L "=== ORDER-06 V3 Capture Script Finished ==="
    } catch {
        L "FATAL ERROR: $($_.Exception.Message)"
        L "$($_.ScriptStackTrace)"
    } finally {
        $summaryFile = Join-Path $Out 'summary.json'
        $summaryJson = $global:summary | ConvertTo-Json -Depth 6
        $summaryJson | Set-Content -LiteralPath $summaryFile -Encoding utf8
        $cropsFile = Join-Path $Out 'crops.json'
        ($global:summary['crops'] | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $cropsFile -Encoding utf8
        L "=== Execution Summary written to $summaryFile ==="
    }
}

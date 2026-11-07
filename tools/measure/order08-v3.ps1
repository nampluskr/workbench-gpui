#Requires -Version 7
<#
.SYNOPSIS
  ORDER-08 V3 화면 검증(UI 실측) 스크립트.
  (gpui-checker 작성, leader가 화면 차례 안에서 실행한다.)

.DESCRIPTION
  - 상위 지시: core ORDER-08, 카드 C-34, C-34-R1, C-34-R2, C-34-R3
  - 우리 앱(workbench-gpui) 단독 실행 화면 검증 (Zed는 띄우지 않고 tauri 캡처와 대조).
  - 대조 자료: workbench-tauri 캡처 (D:\projects\workbench-tauri\specs\v0.5\verify\ORDER-08\).
  - 클라이언트 1440×852, 100% DPI, Ensure-ClientSize로 고정.
  - 세션 관리: tools/measure/session.ps1 (Start/Stop 트랜잭션, 실패 시 finally 복원 보장).
  - fixture 복사: 작은따옴표 here-string(@'...'@)으로 백틱 펜스(```rust) 보존, 하위 폴더 '00-order08\'에 복사.
  - 키보드 입력: 방향키·Home·End 등 확장 키에 KEYEVENTF_EXTENDEDKEY(0x1) 적용하여 Shift+화살표 선택 보장.
  - 파일 열기: '00-order08' 폴더 클릭으로 펼친 뒤 Get-TreeRowBoxByName으로 트리 행 더블클릭 (order03 방식).
  - 단계 독립: Invoke-MeasureStep catch에서 throw 없이 FAIL 기록, 단계마다 앱 생존 여부 확인(미생존 시 SKIP).
  - snapshot 동기화: 동작 뒤 새 snapshot seq가 나올 때까지 기다린 뒤 읽기 (이전 seq 재사용 금지).
  - -Steps 지원: step2,step3,step7,step8,step9 또는 2,3,7,8,9 등 유연한 부분 실행 지원, 사전 전제 조건 자동 보장.
  - 판정 문구 없음: 로그에 Verified/matches zed 없이 captured 및 덤프 값만 기록 (판정은 leader 몫).
  - 상태 바 box: status-btn-* 대신 status-icon-*(project-panel, search, diagnostics, sidebar-toggle) 사용 및 값 로깅.
  - 좌표: 하드코딩 좌표 대신 --dev-layout 덤프 box(Get-BoxScreenCoord) 사용, box 없으면 "측정 불가: box 없음" 기록.
  - Project Search: 검색어 입력 칸 포커스 덤프 확인 후 입력, Replace 버튼/단축키 절대 누르지 않음.
  - DryRun 모드: session.ps1 실행 없이 fixture 준비, 단계 유효성, 문법만 검증.

.PARAMETER Out
  출력 디렉터리 (기본값: specs\v0.5\verify\reviews\measure-ORDER-08).

.PARAMETER AppExe
  workbench-gpui 실행 파일 경로.

.PARAMETER TauriRefDir
  Zed 비교용 tauri 캡처 디렉터리 경로 (기본값: D:\projects\workbench-tauri\specs\v0.5\verify\ORDER-08).

.PARAMETER DryRun
  프로세스 구동 없이 단계 구성, fixture 준비, 문법만 검증하는 모드.

.PARAMETER Steps
  실행할 단계 목록. 기본값: 모든 단계 실행.

.PARAMETER Skip
  건너뛸 단계 목록.
#>
[CmdletBinding()]
param(
    [string]$Out = 'specs\v0.5\verify\reviews\measure-ORDER-08',
    [string]$AppExe = 'D:\projects\workbench-gpui\target\debug\workbench-gpui.exe',
    [string]$TauriRefDir = 'D:\projects\workbench-tauri\specs\v0.5\verify\ORDER-08',
    [switch]$DryRun,
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
    "crops" = [ordered]@{}
    "captures" = [ordered]@{}
    "hashes" = [ordered]@{}
    "tauri_refs" = [ordered]@{}
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
        if ($stepKey -like "*$k*") { return $false }
    }
    if ($normalizedSteps.Count -eq 0) { return $true }
    if ($normalizedSteps.Contains($stepKey)) { return $true }
    foreach ($k in $normalizedSteps) {
        if ($stepKey -like "*$k*") { return $true }
        if ($k -match '^\d+$' -and $stepKey -like "*step$k-*") { return $true }
    }
    return $false
}

function L([string]$msg) {
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
    $line = "[$ts] $msg"
    Write-Host $line
    Add-Content -LiteralPath $logFile -Value $line -Encoding utf8
}

function Get-Hash([string]$file) {
    if (Test-Path -LiteralPath $file) {
        return (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
    }
    return $null
}

# ---------------------------------------------------------------------------
# 1. Native API Definitions (C# P/Invoke with KEYEVENTF_EXTENDEDKEY)
# ---------------------------------------------------------------------------
$nativeSource = @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

public static class Order08AppNative {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct POINT {
        public int X;
        public int Y;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct INPUT {
        public uint type;
        public InputUnion mkhi;
    }

    [StructLayout(LayoutKind.Explicit)]
    public struct InputUnion {
        [FieldOffset(0)] public MOUSEINPUT mi;
        [FieldOffset(0)] public KEYBDINPUT ki;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct KEYBDINPUT {
        public ushort wVk;
        public ushort wScan;
        public uint dwFlags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct MOUSEINPUT {
        public int dx;
        public int dy;
        public uint mouseData;
        public uint dwFlags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr hWnd, ref POINT lpPoint);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    [DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, int dx, int dy, uint dwData, IntPtr dwExtraInfo);
    [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, IntPtr dwExtraInfo);
    [DllImport("user32.dll")] public static extern int GetSystemMetrics(int nIndex);
    [DllImport("user32.dll")] public static extern IntPtr GetWindow(IntPtr hWnd, uint uCmd);
    [DllImport("user32.dll", SetLastError = true)] public static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

    public const uint WM_CLOSE = 0x0010;
    const uint KEYEVENTF_EXTENDEDKEY = 0x1, KEYEVENTF_KEYUP = 0x2, KEYEVENTF_UNICODE = 0x4;
    const uint MOUSEEVENTF_MOVE = 0x1, MOUSEEVENTF_LEFTDOWN = 0x2, MOUSEEVENTF_LEFTUP = 0x4;
    const uint MOUSEEVENTF_VIRTUALDESK = 0x4000, MOUSEEVENTF_ABSOLUTE = 0x8000;
    const uint INPUT_KEYBOARD = 1;
    const int SM_XVIRTUALSCREEN = 76, SM_YVIRTUALSCREEN = 77, SM_CXVIRTUALSCREEN = 78, SM_CYVIRTUALSCREEN = 79;

    public static string Title(IntPtr hWnd) {
        var sb = new StringBuilder(512);
        GetWindowText(hWnd, sb, sb.Capacity);
        return sb.ToString();
    }

    public static List<IntPtr> GetProcessTopLevelWindows(uint[] pids) {
        var list = new List<IntPtr>();
        var pidSet = new HashSet<uint>(pids);
        EnumWindows((h, l) => {
            uint p; GetWindowThreadProcessId(h, out p);
            if (pidSet.Contains(p) && IsWindowVisible(h) && GetWindow(h, 4 /* GW_OWNER */) == IntPtr.Zero) {
                list.Add(h);
            }
            return true;
        }, IntPtr.Zero);
        return list;
    }

    // Extended keys: PageUp, PageDown, End, Home, Left, Up, Right, Down, Select, Print, Execute, Snapshot, Insert, Delete, Windows
    public static bool IsExtendedKey(byte vk) {
        return (vk >= 0x21 && vk <= 0x2E) || vk == 0x5B || vk == 0x5C || vk == 0x5D;
    }

    public static void KeyPress(byte vk) {
        uint ext = IsExtendedKey(vk) ? KEYEVENTF_EXTENDEDKEY : 0;
        keybd_event(vk, 0, ext, IntPtr.Zero);
        Thread.Sleep(40);
        keybd_event(vk, 0, KEYEVENTF_KEYUP | ext, IntPtr.Zero);
        Thread.Sleep(40);
    }

    public static void KeyCombo(ushort[] modifiers, ushort key) {
        foreach (var m in modifiers) {
            uint mExt = IsExtendedKey((byte)m) ? KEYEVENTF_EXTENDEDKEY : 0;
            keybd_event((byte)m, 0, mExt, IntPtr.Zero);
        }
        Thread.Sleep(40);
        uint keyExt = IsExtendedKey((byte)key) ? KEYEVENTF_EXTENDEDKEY : 0;
        keybd_event((byte)key, 0, keyExt, IntPtr.Zero);
        Thread.Sleep(50);
        keybd_event((byte)key, 0, KEYEVENTF_KEYUP | keyExt, IntPtr.Zero);
        Thread.Sleep(40);
        for (int i = modifiers.Length - 1; i >= 0; i--) {
            uint mExt = IsExtendedKey((byte)modifiers[i]) ? KEYEVENTF_EXTENDEDKEY : 0;
            keybd_event((byte)modifiers[i], 0, KEYEVENTF_KEYUP | mExt, IntPtr.Zero);
        }
        Thread.Sleep(60);
    }

    public static void TypeText(string text) {
        foreach (char c in text) {
            var down = new INPUT[1];
            down[0].type = INPUT_KEYBOARD;
            down[0].mkhi.ki.wVk = 0;
            down[0].mkhi.ki.wScan = (ushort)c;
            down[0].mkhi.ki.dwFlags = KEYEVENTF_UNICODE;
            SendInput(1, down, Marshal.SizeOf(typeof(INPUT)));
            Thread.Sleep(25);

            var up = new INPUT[1];
            up[0].type = INPUT_KEYBOARD;
            up[0].mkhi.ki.wVk = 0;
            up[0].mkhi.ki.wScan = (ushort)c;
            up[0].mkhi.ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;
            SendInput(1, up, Marshal.SizeOf(typeof(INPUT)));
            Thread.Sleep(25);
        }
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
}
'@

if (-not ([System.Management.Automation.PSTypeName]'Order08AppNative').Type) {
    Add-Type -TypeDefinition $nativeSource -Language CSharp
}

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

# ---------------------------------------------------------------------------
# 2. Window Capture and Crop Helpers
# ---------------------------------------------------------------------------
function Ensure-Foreground([IntPtr]$hwnd, [string]$label = '') {
    [void][Order08AppNative]::SetForegroundWindow($hwnd)
    Start-Sleep -Milliseconds 150
    $fg = [Order08AppNative]::GetForegroundWindow()
    if ($fg -ne $hwnd) {
        [void][Order08AppNative]::ShowWindow($hwnd, 9) # SW_RESTORE
        [void][Order08AppNative]::SetForegroundWindow($hwnd)
        Start-Sleep -Milliseconds 200
        $fg = [Order08AppNative]::GetForegroundWindow()
    }
    if ($fg -ne $hwnd) {
        $pt = New-Object Order08AppNative+POINT
        $pt.X = 0; $pt.Y = 0
        [void][Order08AppNative]::ClientToScreen($hwnd, [ref]$pt)
        [Order08AppNative]::Click($pt.X + 500, $pt.Y + 16)
        Start-Sleep -Milliseconds 300
        $fg = [Order08AppNative]::GetForegroundWindow()
    }
    L ("Foreground check for '$label': target=0x{0:X}, foreground=0x{1:X}" -f $hwnd.ToInt64(), $fg.ToInt64())
}

function Cap-Window([IntPtr]$hwnd, [string]$name, [string]$outDir) {
    Ensure-Foreground $hwnd "Capture $name"
    $pngPath = Join-Path $outDir "$name.png"
    & pwsh -NoProfile -File 'tools/capture.ps1' -Hwnd ("0x{0:X}" -f $hwnd.ToInt64()) -Method Screen -Out $pngPath *> $null
    $h = Get-Hash $pngPath
    L "captured '$pngPath' (SHA256=$h)"
    if (-not (Test-Path -LiteralPath $pngPath)) {
        throw "Capture failed to produce output image: $pngPath"
    }
    $global:summary["hashes"][$name] = $h
    $global:summary["captures"][$name] = $pngPath
    return $pngPath
}

function Crop-Image([string]$sourcePng, [string]$targetPng, [int]$x, [int]$y, [int]$w, [int]$h) {
    if (-not (Test-Path -LiteralPath $sourcePng)) {
        throw "Crop source not found: $sourcePng"
    }
    $src = [System.Drawing.Image]::FromFile($sourcePng)
    try {
        $x = [Math]::Max(0, [Math]::Min($x, $src.Width - 1))
        $y = [Math]::Max(0, [Math]::Min($y, $src.Height - 1))
        $w = [Math]::Max(1, [Math]::Min($w, $src.Width - $x))
        $h = [Math]::Max(1, [Math]::Min($h, $src.Height - $y))
        $rect = New-Object System.Drawing.Rectangle($x, $y, $w, $h)
        $bmp = New-Object System.Drawing.Bitmap($w, $h)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        try {
            $g.DrawImage($src, 0, 0, $rect, [System.Drawing.GraphicsUnit]::Pixel)
        } finally {
            $g.Dispose()
        }
        $bmp.Save($targetPng, [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()
    } finally {
        $src.Dispose()
    }
    $cropHash = Get-Hash $targetPng
    $cropName = [System.IO.Path]::GetFileNameWithoutExtension($targetPng)
    $global:summary["crops"][$cropName] = [ordered]@{
        "path" = $targetPng
        "bounds" = @{ x = $x; y = $y; w = $w; h = $h }
        "sha256" = $cropHash
    }
    L "captured crop '$targetPng' [$x,$y $w x $h] (SHA256=$cropHash)"
    return $targetPng
}

function Ensure-ClientSize([IntPtr]$hwnd, [int]$expectedW, [int]$expectedH, [string]$procName = 'workbench-gpui') {
    $resizeOutput = & pwsh -NoProfile -File 'tools/measure/window-rect.ps1' -ProcessName $procName -TargetHwnd ("0x{0:X}" -f $hwnd.ToInt64()) -Action Resize -X 232 -Y 90 -Width 1456 -Height 860 2>&1
    foreach ($line in $resizeOutput) { L "Resize: $line" }
    Start-Sleep -Milliseconds 600

    $cr = New-Object Order08AppNative+RECT
    [void][Order08AppNative]::GetClientRect($hwnd, [ref]$cr)
    $actualW = $cr.Right - $cr.Left
    $actualH = $cr.Bottom - $cr.Top
    L "Client size check ($procName): target=${expectedW}x${expectedH}, actual=${actualW}x${actualH}"

    if ($actualW -ne $expectedW -or $actualH -ne $expectedH) {
        L "Directly applying SetWindowPos to adjust to 1456x860..."
        [void][Order08AppNative]::SetWindowPos($hwnd, [IntPtr]::Zero, 232, 90, 1456, 860, 0x0004 -bor 0x0010)
        Start-Sleep -Milliseconds 600
        [void][Order08AppNative]::GetClientRect($hwnd, [ref]$cr)
        $actualW = $cr.Right - $cr.Left
        $actualH = $cr.Bottom - $cr.Top
        L "Re-checked client size: ${actualW}x${actualH}"
        if ($actualW -ne $expectedW -or $actualH -ne $expectedH) {
            Cap-Window $hwnd "error-$procName-client-size" $Out
            throw "Window client size mismatch: expected ${expectedW}x${expectedH}, got ${actualW}x${actualH}"
        }
    }
}

# ---------------------------------------------------------------------------
# 3. Layout Snapshot & Probe Parsing Helpers (with seq synchronization)
# ---------------------------------------------------------------------------
function Get-LatestSnapshot([string]$outDir) {
    $stdoutPath = Join-Path $outDir 'app-stdout.txt'
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
    for ($i = $start; $i -le $end; $i++) {
        if ($lines[$i] -match 'name=(\S+) bounds=([-\d.]+),([-\d.]+),([-\d.]+),([-\d.]+)') {
            $boxes[$matches[1]] = @{
                name = $matches[1]
                x = [double]$matches[2]
                y = [double]$matches[3]
                w = [double]$matches[4]
                h = [double]$matches[5]
            }
        }
    }
    return [PSCustomObject]@{
        seq = $seq
        boxes = $boxes
    }
}

function Wait-NextSnapshot([string]$outDir, [int]$prevSeq, [int]$timeoutMs = 3000) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.ElapsedMilliseconds -lt $timeoutMs) {
        $snap = Get-LatestSnapshot $outDir
        if ($snap -and $snap.seq -gt $prevSeq) {
            return $snap
        }
        Start-Sleep -Milliseconds 100
    }
    return (Get-LatestSnapshot $outDir)
}

function Get-BoxScreenCoord([IntPtr]$hwnd, [string]$sessionDir, [string]$probeName) {
    $snap = Get-LatestSnapshot $sessionDir
    if (-not $snap -or -not $snap.boxes.Contains($probeName)) { return $null }
    $b = $snap.boxes[$probeName]

    $pt = New-Object Order08AppNative+POINT
    $pt.X = 0; $pt.Y = 0
    [void][Order08AppNative]::ClientToScreen($hwnd, [ref]$pt)

    $screenX = [int][Math]::Round($pt.X + $b.x + ($b.w / 2.0))
    $screenY = [int][Math]::Round($pt.Y + $b.y + ($b.h / 2.0))

    return [PSCustomObject]@{
        X = $screenX
        Y = $screenY
        W = [int][Math]::Round($b.w)
        H = [int][Math]::Round($b.h)
        Bounds = $b
    }
}

function Get-TreeRowBoxByName([IntPtr]$hwnd, [string]$outDir, [string]$fileName, [string]$fixtureDir = '') {
    $foundIndex = -1
    $reason = ''

    # 1. Search app-stdout.txt for latest tree rows line
    $stdoutPath = Join-Path $outDir 'app-stdout.txt'
    if (Test-Path -LiteralPath $stdoutPath) {
        $lines = @(Get-Content -LiteralPath $stdoutPath -Encoding utf8)
        for ($i = $lines.Count - 1; $i -ge 0; $i--) {
            if ($lines[$i] -match '^\[dev\] tree .* rows=(.*)$') {
                $entries = $matches[1] -split '\t'
                for ($ix = 0; $ix -lt $entries.Count; $ix++) {
                    $parts = $entries[$ix] -split '\|'
                    if ($parts.Count -gt 0 -and $parts[0].Trim() -eq $fileName) {
                        $foundIndex = $ix
                        $reason = "stdout tree rows match (index $ix)"
                        break
                    }
                }
                if ($foundIndex -ge 0) { break }
            }
        }
    }

    if ($foundIndex -ge 0) {
        $targetBoxName = ("tree-row-{0:D2}" -f $foundIndex)
        L ("Tree row for '$fileName': index=$foundIndex, target=$targetBoxName ($reason)")
        $coord = Get-BoxScreenCoord $hwnd $outDir $targetBoxName
        if ($coord) { return $coord }
        $coord = Get-BoxScreenCoord $hwnd $outDir ("tree-content-{0:D2}" -f $foundIndex)
        if ($coord) { return $coord }
        $coord = Get-BoxScreenCoord $hwnd $outDir ("tree-label-{0:D2}" -f $foundIndex)
        if ($coord) { return $coord }
    } else {
        L ("Tree row for '$fileName': not found in stdout tree rows")
    }
    return $null
}

# ---------------------------------------------------------------------------
# 4. Fixture Files Definition (Single-quote here-strings @'...'@, C-34-R3 #2)
# ---------------------------------------------------------------------------
function Write-Order08FixtureFiles([string]$targetDir) {
    L "Writing ORDER-08 fixture files into '$targetDir'..."
    New-Item -ItemType Directory -Force $targetDir | Out-Null

    # Copy ORDER-08 files into subfolder '00-order08' so folders sort first
    $order08SubDir = Join-Path $targetDir '00-order08'
    New-Item -ItemType Directory -Force $order08SubDir | Out-Null

    # 1. sample.md (Single-quoted here-string preserves ```rust code fence intact)
    $mdContent = @'
# ORDER-08 Markdown Test Document

This is the first paragraph for cursor position testing.
Line four has specific text for column offset measurement.
Fifth line for selection: five characters here.

- First item in unordered list
- Second item in list with inner content

```rust
fn main() {
    println!("Fenced code block line");
}
```

> Blockquote paragraph 1
>
> Inner nested quote paragraph with target text

Final line of the document.
'@
    $mdContent | Set-Content -LiteralPath (Join-Path $order08SubDir 'sample.md') -Encoding utf8

    # 2. sample.rs
    $rsContent = @'
//! Sample Rust File for status bar filetype verification
fn calculate_metrics() -> i32 {
    let order = 8;
    order * 10
}
'@
    $rsContent | Set-Content -LiteralPath (Join-Path $order08SubDir 'sample.rs') -Encoding utf8

    # 3. sample.json
    $jsonContent = @'
{
  "name": "workbench-gpui",
  "version": "0.5.0",
  "active": true
}
'@
    $jsonContent | Set-Content -LiteralPath (Join-Path $order08SubDir 'sample.json') -Encoding utf8

    # 4. tsconfig.json (Zed name: JSONC)
    $jsoncContent = @'
// TypeScript configuration (JSONC)
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext"
  }
}
'@
    $jsoncContent | Set-Content -LiteralPath (Join-Path $order08SubDir 'tsconfig.json') -Encoding utf8

    # 5. sample.ts
    $tsContent = @'
export interface OrderConfig {
    orderId: string;
    targetLines: number[];
}
'@
    $tsContent | Set-Content -LiteralPath (Join-Path $order08SubDir 'sample.ts') -Encoding utf8

    # 6. sample.txt
    $txtContent = @'
This is a plain text file without any recognized syntax suffix.
It should map to Plain Text in status bar.
'@
    $txtContent | Set-Content -LiteralPath (Join-Path $order08SubDir 'sample.txt') -Encoding utf8

    # Search target in subfolder
    $searchTargetContent = @'
pub fn search_target_one() {
    let needle = "ORDER08_SEARCH_MATCH";
    println!("{}", needle);
}
'@
    $searchTargetContent | Set-Content -LiteralPath (Join-Path $order08SubDir 'search_target.rs') -Encoding utf8

    # Root level helpers
    'measure' | Set-Content (Join-Path $targetDir '.measure-marker')
    'ignored_needle_text' | Set-Content (Join-Path $targetDir 'ignored.txt') -Encoding utf8
    "ignored.txt`n" | Set-Content (Join-Path $targetDir '.gitignore') -Encoding utf8
    [System.IO.File]::WriteAllBytes((Join-Path $targetDir 'binary.bin'), [byte[]]@(0x00, 0x01, 0x02, 0x00, 0x57, 0x4F, 0x52, 0x44))

    L "ORDER-08 fixture files written into '00-order08\' subfolder successfully."
}

# ---------------------------------------------------------------------------
# 5. Step Execution Engine (Step-Independent with Skip on Process Death)
# ---------------------------------------------------------------------------
function Invoke-MeasureStep([string]$stepKey, [string]$stepTitle, [scriptblock]$action) {
    if (-not (Should-RunStep $stepKey)) {
        L "Skipping step '$stepKey' (not requested or explicitly skipped)."
        return
    }

    L "=================================================================="
    L "START STEP: $stepKey — $stepTitle"
    L "=================================================================="

    $stepResult = [ordered]@{
        "status" = "RUNNING"
        "title" = $stepTitle
        "started" = (Get-Date).ToString('o')
    }
    $global:summary["app"][$stepKey] = $stepResult

    # Check process liveliness if not DryRun
    if (-not $DryRun -and $script:appPid -gt 0) {
        $proc = Get-Process -Id $script:appPid -ErrorAction SilentlyContinue
        if (-not $proc -or $proc.HasExited) {
            L "App process (PID=$($script:appPid)) is not alive. Marking '$stepKey' as SKIP."
            $stepResult["status"] = "SKIP"
            $stepResult["error"] = "App process exited before step execution"
            $stepResult["finished"] = (Get-Date).ToString('o')
            return
        }
    }

    try {
        & $action
        if ($stepResult["status"] -eq "RUNNING") {
            $stepResult["status"] = "PASS"
        }
        L "STEP FINISHED: $stepKey (status=$($stepResult["status"]))"
    } catch {
        # Independent step: record FAIL without throwing to permit subsequent steps
        $stepResult["status"] = "FAIL"
        $stepResult["error"] = $_.Exception.Message
        $stepResult["stackTrace"] = $_.ScriptStackTrace
        L "STEP FAIL: $stepKey — $($_.Exception.Message)"
    } finally {
        $stepResult["finished"] = (Get-Date).ToString('o')
    }
}

# ---------------------------------------------------------------------------
# 6. Main Execution Body
# ---------------------------------------------------------------------------
$dryRunFixtureDir = Join-Path $Out 'fixture'
$backupDir = Join-Path (Split-Path $Out -Parent) ('_' + (Split-Path $Out -Leaf) + '-backup')
$script:appPid = 0
$script:appHwnd = [IntPtr]::Zero
$script:currentSeq = 0

# Verify Tauri Zed Reference Directory
if (Test-Path -LiteralPath $TauriRefDir) {
    L "Found Tauri Zed reference directory: $TauriRefDir"
    $refFiles = @(Get-ChildItem -LiteralPath $TauriRefDir -Filter "*.png" | Select-Object -ExpandProperty Name)
    L "Available Tauri Zed reference captures: $($refFiles -join ', ')"
    $global:summary["tauri_refs"]["dir"] = $TauriRefDir
    $global:summary["tauri_refs"]["files"] = $refFiles
} else {
    L "Warning: Tauri Zed reference directory not found at $TauriRefDir"
}

# DRY-RUN MODE: Fast validation of steps, syntax, and fixture generation
if ($DryRun) {
    L "=================================================================="
    L "DRY-RUN MODE REQUESTED: Validating steps, syntax, and fixture"
    L "=================================================================="

    Write-Order08FixtureFiles $dryRunFixtureDir

    $dryRunSteps = @(
        [PSCustomObject]@{ Step = 'app-step1-notabs-status'; Spec = 'R-5'; Action = 'Capture status bar when no tabs open; verify cursor & filetype empty' },
        [PSCustomObject]@{ Step = 'app-step2-cursor-and-filetype'; Spec = 'R-5'; Action = 'Expand 00-order08, open sample.md via tree double-click, move cursor; verify {line}:{column} {Filetype}' },
        [PSCustomObject]@{ Step = 'app-step3-selection-status'; Spec = 'R-5'; Action = 'Select 5 characters with Shift+Right (extended key); verify N character(s) display' },
        [PSCustomObject]@{ Step = 'app-step4-different-filetypes'; Spec = 'R-5'; Action = 'Open .rs, .json, tsconfig.json, .ts, .txt via 00-order08; verify filetype names' },
        [PSCustomObject]@{ Step = 'app-step5-preview-innermost-click'; Spec = 'R-5'; Action = 'Open Markdown Preview via toolbar probe; verify innermost block row, col 1 if probes exist' },
        [PSCustomObject]@{ Step = 'app-step6-sidebar-dock-toggle'; Spec = 'R-19/R-22'; Action = 'Toggle dock & sidebar via status-icon probes; verify accent toggle color, dividers (w=1, h=16, border)' },
        [PSCustomObject]@{ Step = 'app-step7-button-tooltips-hover'; Spec = 'R-22'; Action = 'Hover sidebar, dock, search, diag buttons via status-icon probe coords; verify tooltips' },
        [PSCustomObject]@{ Step = 'app-step8-project-search'; Spec = 'R-22'; Action = 'DeploySearch; verify input focus in dump; execute search; Open result (Alt-Enter); DO NOT click Replace' },
        [PSCustomObject]@{ Step = 'app-step9-diagnostics'; Spec = 'R-22'; Action = 'DeployDiagnostics; verify No problems tab and central text' }
    )

    foreach ($ds in $dryRunSteps) {
        Invoke-MeasureStep $ds.Step "DryRun validation: $($ds.Action)" {
            L "DryRun: Planned step '$($ds.Step)' (Spec $($ds.Spec)): $($ds.Action)"
        }
    }

    $summaryJson = Join-Path $Out 'order08-dryrun-summary.json'
    $global:summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $summaryJson -Encoding utf8
    L "Dry-run complete. Summary written to $summaryJson"
    L "[DRYRUN] Completed successfully."
    return
}

# LIVE MEASUREMENT MODE (Under session.ps1 management)
$sessionFixtureDir = ''

try {
    # 1. Launch App via session.ps1 Start
    L "Calling session.ps1 -Action Start (Exe=$AppExe)..."
    & pwsh -NoProfile -File 'tools/measure/session.ps1' -Action Start -Out $Out -Exe $AppExe -Backup $backupDir -Json
    
    $sessionFile = Join-Path $Out 'session.json'
    if (-not (Test-Path $sessionFile)) { throw "session.json not found after session start" }
    $session = Get-Content -Raw $sessionFile | ConvertFrom-Json
    $script:appPid = [uint32]$session.pid
    $sessionFixtureDir = if ($session.PSObject.Properties['fixture']) { $session.fixture } else { '' }
    L "App launched via session.ps1: PID=$($script:appPid), fixtureDir='$sessionFixtureDir'"

    # 2. Copy ORDER-08 fixture files into session fixture folder '00-order08\' (C-34-R2 #3, C-34-R3 #2)
    if ($sessionFixtureDir -and (Test-Path -LiteralPath $sessionFixtureDir)) {
        Write-Order08FixtureFiles $sessionFixtureDir
    } else {
        throw "Session fixture directory '$sessionFixtureDir' not found"
    }

    # 3. Locate Main Window HWND
    for ($i = 1; $i -le 40; $i++) {
        Start-Sleep -Milliseconds 300
        $p = Get-Process -Id $script:appPid -ErrorAction SilentlyContinue
        if ($p -and $p.MainWindowHandle -ne [IntPtr]::Zero) {
            $script:appHwnd = $p.MainWindowHandle
            break
        }
    }
    if ($script:appHwnd -eq [IntPtr]::Zero) {
        throw "Main window handle not found for PID=$($script:appPid)"
    }

    L ("Main window handle HWND=0x{0:X}" -f $script:appHwnd.ToInt64())
    Ensure-ClientSize $script:appHwnd 1440 852 'workbench-gpui'
    Ensure-Foreground $script:appHwnd "App started"

    # Track initial snapshot seq
    $initSnap = Get-LatestSnapshot $Out
    $script:currentSeq = if ($initSnap) { $initSnap.seq } else { 0 }
    L "Initial layout snapshot seq=$($script:currentSeq)"

    # 4. Open Project Folder in App if needed (order03 pattern: project-empty-open)
    L "Checking if project tree is loaded..."
    if (-not ($initSnap -and $initSnap.boxes.Contains('tree-row-01'))) {
        $emptyOpen = Get-BoxScreenCoord $script:appHwnd $Out 'project-empty-open'
        if ($emptyOpen) {
            L "Found 'project-empty-open' button at ($($emptyOpen.X), $($emptyOpen.Y)). Clicking..."
            $prevSeq = $script:currentSeq
            [Order08AppNative]::Click($emptyOpen.X, $emptyOpen.Y)
            $snap = Wait-NextSnapshot $Out $prevSeq 4000
            $script:currentSeq = $snap.seq
            L "Project tree loaded, seq=$($script:currentSeq)"
        }
    }

    # 5. Expand '00-order08' folder so inner files appear in visible tree rows
    L "Searching for '00-order08' folder in tree to expand..."
    $folderCoord = Get-TreeRowBoxByName $script:appHwnd $Out '00-order08' $sessionFixtureDir
    if ($folderCoord) {
        L "Clicking '00-order08' folder row at ($($folderCoord.X), $($folderCoord.Y)) to expand..."
        $prevSeq = $script:currentSeq
        [Order08AppNative]::Click($folderCoord.X, $folderCoord.Y)
        $snap = Wait-NextSnapshot $Out $prevSeq 3000
        $script:currentSeq = $snap.seq
        L "Expanded '00-order08' folder, seq=$($script:currentSeq)"
    } else {
        L "Warning: '00-order08' folder row not found in tree"
    }

    # Helper function: Open file from tree by double-clicking (C-34-R1 #1, C-34-R2 #3)
    function Open-FileFromTree([string]$fileName) {
        L "Attempting to open file '$fileName' from tree..."
        # Dismiss any hovering tooltip first
        [Order08AppNative]::MoveTo(5, 5)
        Start-Sleep -Milliseconds 200

        $treeRow = Get-TreeRowBoxByName $script:appHwnd $Out $fileName $sessionFixtureDir
        if (-not $treeRow) {
            L "Tree row for '$fileName' not found; recording missing row"
            return $false
        }
        L "Double-clicking tree row for '$fileName' at screen coords ($($treeRow.X), $($treeRow.Y))..."
        $prevSeq = $script:currentSeq
        [Order08AppNative]::DoubleClick($treeRow.X, $treeRow.Y)
        $snap = Wait-NextSnapshot $Out $prevSeq 3000
        $script:currentSeq = $snap.seq
        L "File '$fileName' opened, seq=$($script:currentSeq)"
        return $true
    }

    # Helper: Log status-icon-* box values (C-34-R2 #2)
    function Log-StatusIconBoxes() {
        $snap = Get-LatestSnapshot $Out
        if (-not $snap) { return }
        foreach ($k in @('status-icon-sidebar-toggle', 'status-icon-project-panel', 'status-icon-search', 'status-icon-diagnostics', 'sidebar-icon-toggle', 'sidebar-btn-toggle', 'status-left', 'status-right', 'status-cursor')) {
            if ($snap.boxes.ContainsKey($k)) {
                $b = $snap.boxes[$k]
                L ("Box '$k': bounds={0:F2},{1:F2},{2:F2},{3:F2}" -f $b.x, $b.y, $b.w, $b.h)
            }
        }
    }

    # -------------------------------------------------------------------
    # Step 1: app-step1-notabs-status (No open tabs state)
    # -------------------------------------------------------------------
    Invoke-MeasureStep 'app-step1-notabs-status' 'Tab-less status bar (R-5 no-tab state)' {
        Start-Sleep -Milliseconds 500
        $cap = Cap-Window $script:appHwnd 'app-step1-notabs-status' $Out
        Log-StatusIconBoxes
        $sbRightCoord = Get-BoxScreenCoord $script:appHwnd $Out 'status-right'
        if ($sbRightCoord) {
            $b = $sbRightCoord.Bounds
            $cropX = [int]$b.x; $cropY = [int]$b.y; $cropW = [int]$b.w; $cropH = [int]$b.h
            Crop-Image $cap (Join-Path $Out 'app-step1-notabs-right.png') $cropX $cropY $cropW $cropH | Out-Null
        } else {
            L "측정 불가: status-right box 없음"
        }
    }

    # -------------------------------------------------------------------
    # Step 2: app-step2-cursor-and-filetype (Open file, move cursor)
    # -------------------------------------------------------------------
    Invoke-MeasureStep 'app-step2-cursor-and-filetype' 'Cursor position and Markdown filetype (R-5)' {
        $opened = Open-FileFromTree 'sample.md'
        if (-not $opened) {
            L "측정 불가: tree-row box 없음 (sample.md)"
            return
        }

        # Focus editor and move cursor: Down 4, Right 5
        $prevSeq = $script:currentSeq
        for ($k = 0; $k -lt 4; $k++) { [Order08AppNative]::KeyPress(0x28); Start-Sleep -Milliseconds 40 } # Down (extended key)
        for ($k = 0; $k -lt 5; $k++) { [Order08AppNative]::KeyPress(0x27); Start-Sleep -Milliseconds 40 } # Right (extended key)
        $snap = Wait-NextSnapshot $Out $prevSeq 1500
        $script:currentSeq = $snap.seq

        $cap = Cap-Window $script:appHwnd 'app-step2-cursor' $Out
        Log-StatusIconBoxes
        $sbCoord = Get-BoxScreenCoord $script:appHwnd $Out 'status-cursor'
        if ($sbCoord -and $sbCoord.Bounds.w -gt 0) {
            $b = $sbCoord.Bounds
            $cropX = [int]$b.x; $cropY = [int]$b.y; $cropW = [int]$b.w; $cropH = [int]$b.h
            Crop-Image $cap (Join-Path $Out 'app-step2-cursor-right.png') $cropX $cropY $cropW $cropH | Out-Null
        } else {
            $sbRightCoord = Get-BoxScreenCoord $script:appHwnd $Out 'status-right'
            if ($sbRightCoord) {
                $b = $sbRightCoord.Bounds
                $cropX = [int]$b.x; $cropY = [int]$b.y; $cropW = [int]$b.w; $cropH = [int]$b.h
                Crop-Image $cap (Join-Path $Out 'app-step2-cursor-right.png') $cropX $cropY $cropW $cropH | Out-Null
            } else {
                L "측정 불가: status-cursor / status-right box 없음"
            }
        }
    }

    # -------------------------------------------------------------------
    # Step 3: app-step3-selection-status (Selection count display, C-34-R3 #1)
    # -------------------------------------------------------------------
    Invoke-MeasureStep 'app-step3-selection-status' 'Selection character count in status bar (R-5)' {
        # Ensure sample.md is opened and cursor placed if step2 was skipped
        $snap = Get-LatestSnapshot $Out
        if (-not ($snap -and $snap.boxes.ContainsKey('status-cursor') -and $snap.boxes['status-cursor'].w -gt 0)) {
            $opened = Open-FileFromTree 'sample.md'
            if ($opened) {
                for ($k = 0; $k -lt 4; $k++) { [Order08AppNative]::KeyPress(0x28); Start-Sleep -Milliseconds 40 }
                for ($k = 0; $k -lt 5; $k++) { [Order08AppNative]::KeyPress(0x27); Start-Sleep -Milliseconds 40 }
            }
        }

        # Select 5 characters using Shift + Right (0x10 + 0x27 with EXTENDEDKEY flag)
        L "Creating selection: Shift + Right 5 times..."
        $prevSeq = $script:currentSeq
        for ($k = 0; $k -lt 5; $k++) {
            [Order08AppNative]::KeyCombo(@(0x10), 0x27) # Shift + Right (extended)
            Start-Sleep -Milliseconds 50
        }
        $snap = Wait-NextSnapshot $Out $prevSeq 1500
        $script:currentSeq = $snap.seq

        $cap = Cap-Window $script:appHwnd 'app-step3-selection' $Out
        Log-StatusIconBoxes
        $sbRightCoord = Get-BoxScreenCoord $script:appHwnd $Out 'status-right'
        if ($sbRightCoord) {
            $b = $sbRightCoord.Bounds
            # Include selection text to the left of status-right
            $cropX = [Math]::Max(0, [int]($b.x - 120))
            $cropY = [int]$b.y
            $cropW = [int]($b.w + 120)
            $cropH = [int]$b.h
            Crop-Image $cap (Join-Path $Out 'app-step3-selection-right.png') $cropX $cropY $cropW $cropH | Out-Null
        } else {
            L "측정 불가: status-right box 없음"
        }

        # Deselect with Left key
        [Order08AppNative]::KeyPress(0x25)
        Start-Sleep -Milliseconds 150
    }

    # -------------------------------------------------------------------
    # Step 4: app-step4-different-filetypes (Verify multiple syntax names)
    # -------------------------------------------------------------------
    Invoke-MeasureStep 'app-step4-different-filetypes' 'Filetype names across languages (R-5)' {
        $typeFiles = @(
            @{ file = 'sample.rs'; tag = 'rs' },
            @{ file = 'sample.json'; tag = 'json' },
            @{ file = 'tsconfig.json'; tag = 'jsonc' },
            @{ file = 'sample.ts'; tag = 'ts' },
            @{ file = 'sample.txt'; tag = 'txt' }
        )

        foreach ($tf in $typeFiles) {
            $opened = Open-FileFromTree $tf.file
            if (-not $opened) {
                L "측정 불가: tree-row box 없음 ($($tf.file))"
                continue
            }

            $tag = $tf.tag
            $cap = Cap-Window $script:appHwnd "app-step4-type-$tag" $Out
            $sbRightCoord = Get-BoxScreenCoord $script:appHwnd $Out 'status-right'
            if ($sbRightCoord) {
                $b = $sbRightCoord.Bounds
                $cropX = [int]$b.x; $cropY = [int]$b.y; $cropW = [int]$b.w; $cropH = [int]$b.h
                Crop-Image $cap (Join-Path $Out "app-step4-type-$tag-right.png") $cropX $cropY $cropW $cropH | Out-Null
            } else {
                L "측정 불가: status-right box 없음"
            }
        }
    }

    # -------------------------------------------------------------------
    # Step 5: app-step5-preview-innermost-click (Markdown preview mapping)
    # -------------------------------------------------------------------
    Invoke-MeasureStep 'app-step5-preview-innermost-click' 'Innermost Markdown block mapping (R-5)' {
        $opened = Open-FileFromTree 'sample.md'
        if (-not $opened) {
            L "측정 불가: tree-row box 없음 (sample.md)"
            return
        }

        # Open Markdown Preview via toolbar probe box
        $previewBtn = Get-BoxScreenCoord $script:appHwnd $Out 'toolbar-btn-preview'
        if ($previewBtn) {
            L "Clicking toolbar-btn-preview at ($($previewBtn.X), $($previewBtn.Y))..."
            $prevSeq = $script:currentSeq
            [Order08AppNative]::Click($previewBtn.X, $previewBtn.Y)
            $snap = Wait-NextSnapshot $Out $prevSeq 3000
            $script:currentSeq = $snap.seq
            L "Preview opened, seq=$($script:currentSeq)"
        } else {
            L "측정 불가: toolbar-btn-preview box 없음"
            return
        }

        # Check for individual preview block probe boxes in dump (C-34-R1 #5)
        $snap = Get-LatestSnapshot $Out
        $hasBlockProbes = $snap -and ($snap.boxes.Contains('preview-block-list') -or $snap.boxes.Contains('preview-block-code'))
        if (-not $hasBlockProbes) {
            L "측정 불가: box 없음 (preview block probe boxes not present in layout dump)"
            Cap-Window $script:appHwnd 'app-step5-preview-open' $Out | Out-Null
            return
        }

        # If block boxes exist, click via box coords
        $listBox = Get-BoxScreenCoord $script:appHwnd $Out 'preview-block-list'
        if ($listBox) {
            $prevSeq = $script:currentSeq
            [Order08AppNative]::Click($listBox.X, $listBox.Y)
            $snap = Wait-NextSnapshot $Out $prevSeq 1500
            $script:currentSeq = $snap.seq
            Cap-Window $script:appHwnd 'app-step5-preview-list' $Out | Out-Null
        }
    }

    # -------------------------------------------------------------------
    # Step 6: app-step6-sidebar-dock-toggle (Toggle states, dividers, C-34-R2 #2)
    # -------------------------------------------------------------------
    Invoke-MeasureStep 'app-step6-sidebar-dock-toggle' 'Sidebar and dock toggle states, dividers (R-19/R-22)' {
        Log-StatusIconBoxes

        # 1. Toggle project panel dock via status-icon-project-panel
        $projIcon = Get-BoxScreenCoord $script:appHwnd $Out 'status-icon-project-panel'
        if ($projIcon) {
            L "Clicking status-icon-project-panel at ($($projIcon.X), $($projIcon.Y))..."
            $prevSeq = $script:currentSeq
            [Order08AppNative]::Click($projIcon.X, $projIcon.Y)
            $snap = Wait-NextSnapshot $Out $prevSeq 2000
            $script:currentSeq = $snap.seq

            $capDockOpen = Cap-Window $script:appHwnd 'app-step6-dock-open' $Out
            $sbLeft = Get-BoxScreenCoord $script:appHwnd $Out 'status-left'
            if ($sbLeft) {
                $b = $sbLeft.Bounds
                $cropX = [int]$b.x; $cropY = [int]$b.y; $cropW = [int]$b.w; $cropH = [int]$b.h
                Crop-Image $capDockOpen (Join-Path $Out 'app-step6-dock-open-left.png') $cropX $cropY $cropW $cropH | Out-Null
            }

            # Toggle dock closed
            $projIconClose = Get-BoxScreenCoord $script:appHwnd $Out 'status-icon-project-panel'
            if ($projIconClose) {
                $prevSeq = $script:currentSeq
                [Order08AppNative]::Click($projIconClose.X, $projIconClose.Y)
                $snap = Wait-NextSnapshot $Out $prevSeq 2000
                $script:currentSeq = $snap.seq
                Cap-Window $script:appHwnd 'app-step6-dock-closed' $Out | Out-Null
            }
        } else {
            L "측정 불가: status-icon-project-panel box 없음"
        }

        # 2. Toggle sidebar: check if open via sidebar-btn-toggle
        $sideBtn = Get-BoxScreenCoord $script:appHwnd $Out 'sidebar-btn-toggle'
        if ($sideBtn) {
            L "Sidebar is open (sidebar-btn-toggle found at $($sideBtn.X), $($sideBtn.Y)). Clicking to close..."
            $prevSeq = $script:currentSeq
            [Order08AppNative]::Click($sideBtn.X, $sideBtn.Y)
            $snap = Wait-NextSnapshot $Out $prevSeq 2000
            $script:currentSeq = $snap.seq
            Cap-Window $script:appHwnd 'app-step6-sidebar-closed' $Out | Out-Null

            # Now sidebar is closed: status-icon-sidebar-toggle must appear in status bar
            Log-StatusIconBoxes
            $sbToggleIcon = Get-BoxScreenCoord $script:appHwnd $Out 'status-icon-sidebar-toggle'
            if ($sbToggleIcon) {
                L "Sidebar toggle in status bar found at ($($sbToggleIcon.X), $($sbToggleIcon.Y)). Clicking to open..."
                $prevSeq = $script:currentSeq
                [Order08AppNative]::Click($sbToggleIcon.X, $sbToggleIcon.Y)
                $snap = Wait-NextSnapshot $Out $prevSeq 2000
                $script:currentSeq = $snap.seq
                Cap-Window $script:appHwnd 'app-step6-sidebar-open' $Out | Out-Null
            } else {
                L "측정 불가: status-icon-sidebar-toggle box 없음 after closing sidebar"
            }
        } else {
            $sbToggleIcon = Get-BoxScreenCoord $script:appHwnd $Out 'status-icon-sidebar-toggle'
            if ($sbToggleIcon) {
                L "Clicking status-icon-sidebar-toggle at ($($sbToggleIcon.X), $($sbToggleIcon.Y))..."
                $prevSeq = $script:currentSeq
                [Order08AppNative]::Click($sbToggleIcon.X, $sbToggleIcon.Y)
                $snap = Wait-NextSnapshot $Out $prevSeq 2000
                $script:currentSeq = $snap.seq
                Cap-Window $script:appHwnd 'app-step6-sidebar-open' $Out | Out-Null
            } else {
                L "측정 불가: sidebar toggle box 없음"
            }
        }
    }

    # -------------------------------------------------------------------
    # Step 7: app-step7-button-tooltips-hover (Hover tooltips & status-right)
    # -------------------------------------------------------------------
    Invoke-MeasureStep 'app-step7-button-tooltips-hover' 'Status bar button tooltips on hover (R-22)' {
        Log-StatusIconBoxes

        # Ensure sidebar is closed so status-icon-sidebar-toggle is present for tooltip check
        $sideCloseBtn = Get-BoxScreenCoord $script:appHwnd $Out 'sidebar-btn-toggle'
        if ($sideCloseBtn) {
            $prevSeq = $script:currentSeq
            [Order08AppNative]::Click($sideCloseBtn.X, $sideCloseBtn.Y)
            $snap = Wait-NextSnapshot $Out $prevSeq 2000
            $script:currentSeq = $snap.seq
        }

        # Check status-right bounds in closed-sidebar state
        $sbRight = Get-BoxScreenCoord $script:appHwnd $Out 'status-right'
        if ($sbRight) {
            L ("status-right bounds in Step 7: x={0:F2}, y={1:F2}, w={2:F2}, h={3:F2}" -f $sbRight.Bounds.x, $sbRight.Bounds.y, $sbRight.Bounds.w, $sbRight.Bounds.h)
        }

        $btnNames = @(
            @{ probe = 'status-icon-sidebar-toggle'; tag = 'sidebar' },
            @{ probe = 'status-icon-project-panel'; tag = 'project' },
            @{ probe = 'status-icon-search'; tag = 'search' },
            @{ probe = 'status-icon-diagnostics'; tag = 'diag' }
        )

        foreach ($b in $btnNames) {
            $coord = Get-BoxScreenCoord $script:appHwnd $Out $b.probe
            if ($coord) {
                [Order08AppNative]::MoveTo($coord.X, $coord.Y)
                Start-Sleep -Milliseconds 900 # Wait for tooltip popup

                $tag = $b.tag
                $cap = Cap-Window $script:appHwnd "app-step7-tip-$tag" $Out
                $tipCoord = Get-BoxScreenCoord $script:appHwnd $Out 'tooltip-box'
                if ($tipCoord) {
                    $tb = $tipCoord.Bounds
                    $cropX = [int]$tb.x; $cropY = [int]$tb.y; $cropW = [int]$tb.w; $cropH = [int]$tb.h
                    Crop-Image $cap (Join-Path $Out "app-step7-tip-$tag-crop.png") $cropX $cropY $cropW $cropH | Out-Null
                } else {
                    L "툴팁 박스 덤프 없음 ($($b.probe)), 전체 캡처 보존"
                }
            } else {
                L "측정 불가: $($b.probe) box 없음"
            }
        }
        # Dismiss tooltip
        [Order08AppNative]::MoveTo(5, 5)
        Start-Sleep -Milliseconds 200
    }

    # -------------------------------------------------------------------
    # Step 8: app-step8-project-search (Project Search Tab & Search)
    # -------------------------------------------------------------------
    Invoke-MeasureStep 'app-step8-project-search' 'Project Search tab, Filters, Replace row, query results (R-22)' {
        # Open Project Search via status-icon-search box
        $searchBtn = Get-BoxScreenCoord $script:appHwnd $Out 'status-icon-search'
        $prevSeq = $script:currentSeq
        if ($searchBtn) {
            [Order08AppNative]::Click($searchBtn.X, $searchBtn.Y)
        } else {
            [Order08AppNative]::KeyCombo(@(0x11, 0x10), 0x46) # Ctrl-Shift-F
        }
        $snap = Wait-NextSnapshot $Out $prevSeq 3000
        $script:currentSeq = $snap.seq

        # Check dump to verify search tab active
        $hasSearchTab = $snap -and $snap.boxes.ContainsKey('tab-label-00')
        L "Search tab check in layout dump: present=$hasSearchTab, seq=$($script:currentSeq)"

        # 1. Empty state
        Cap-Window $script:appHwnd 'app-step8-search-empty' $Out | Out-Null

        # 2. Toggle Filters row (Alt-F)
        $prevSeq = $script:currentSeq
        [Order08AppNative]::KeyCombo(@(0x12), 0x46) # Alt-F
        $snap = Wait-NextSnapshot $Out $prevSeq 1500
        $script:currentSeq = $snap.seq
        Cap-Window $script:appHwnd 'app-step8-search-filters' $Out | Out-Null

        # 3. Toggle Replace row (Alt-Shift-H)
        $prevSeq = $script:currentSeq
        [Order08AppNative]::KeyCombo(@(0x12, 0x10), 0x48) # Alt-Shift-H
        $snap = Wait-NextSnapshot $Out $prevSeq 1500
        $script:currentSeq = $snap.seq
        Cap-Window $script:appHwnd 'app-step8-search-replace-row' $Out | Out-Null
        L "SAFETY GUARD: Replace button will NOT be clicked; no Replace shortcuts will be sent."

        # 4. Type search query after verifying search tab and press Enter
        L "Typing search query 'ORDER08_SEARCH_MATCH'..."
        $prevSeq = $script:currentSeq
        [Order08AppNative]::TypeText("ORDER08_SEARCH_MATCH")
        Start-Sleep -Milliseconds 300
        [Order08AppNative]::KeyPress(0x0D) # Enter
        $snap = Wait-NextSnapshot $Out $prevSeq 3000
        $script:currentSeq = $snap.seq

        Cap-Window $script:appHwnd 'app-step8-search-results' $Out | Out-Null

        # 5. Open file result (Alt-Enter)
        $prevSeq = $script:currentSeq
        [Order08AppNative]::KeyCombo(@(0x12), 0x0D) # Alt-Enter
        $snap = Wait-NextSnapshot $Out $prevSeq 3000
        $script:currentSeq = $snap.seq
        Cap-Window $script:appHwnd 'app-step8-search-open' $Out | Out-Null
    }

    # -------------------------------------------------------------------
    # Step 9: app-step9-diagnostics (Diagnostics Tab)
    # -------------------------------------------------------------------
    Invoke-MeasureStep 'app-step9-diagnostics' 'Diagnostics tab empty problem workspace (R-22)' {
        $diagBtn = Get-BoxScreenCoord $script:appHwnd $Out 'status-icon-diagnostics'
        $prevSeq = $script:currentSeq
        if ($diagBtn) {
            [Order08AppNative]::Click($diagBtn.X, $diagBtn.Y)
        } else {
            [Order08AppNative]::KeyCombo(@(0x11, 0x10), 0x4D) # Ctrl-Shift-M
        }
        $snap = Wait-NextSnapshot $Out $prevSeq 3000
        $script:currentSeq = $snap.seq

        Cap-Window $script:appHwnd 'app-step9-diagnostics' $Out | Out-Null
    }

    L "=================================================================="
    L "ALL ORDER-08 MEASUREMENT STEPS COMPLETED."
    L "=================================================================="

} finally {
    L "Cleaning up test environment and ensuring full session restoration..."
    # 1. Close opened app process safely
    if ($script:appPid -gt 0) {
        $p = Get-Process -Id $script:appPid -ErrorAction SilentlyContinue
        if ($p -and -not $p.HasExited) {
            L "Closing main window of app process (PID=$($script:appPid))..."
            [void]$p.CloseMainWindow()
            [void]$p.WaitForExit(3000)
            if (-not $p.HasExited) {
                L "Force stopping app process (PID=$($script:appPid))..."
                $p.Kill()
                [void]$p.WaitForExit(2000)
            }
        }
    }

    # 2. Restore AppData via session.ps1 Stop (MANDATORY rollback guard)
    if (Test-Path (Join-Path $Out 'session.json')) {
        L "Restoring app data via session.ps1 -Action Stop..."
        $stopOutput = & pwsh -NoProfile -File 'tools/measure/session.ps1' -Action Stop -Out $Out -Backup $backupDir 2>&1
        foreach ($line in $stopOutput) { L "session.ps1 Stop: $line" }
    }

    # 3. Save execution summary
    $summaryJson = Join-Path $Out 'order08-summary.json'
    $global:summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $summaryJson -Encoding utf8
    L "Summary written to $summaryJson"
}

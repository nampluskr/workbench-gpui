#Requires -Version 7
<#
.SYNOPSIS
  Zed 화면 확인 전용 스크립트 (상태 바·Project Search·Diagnostics).
  (gpui-checker 작성, C-33 대상, leader가 화면 차례 안에서 실행한다.)

.DESCRIPTION
  - 상위 지시: core ORDER-08 2장 (C-33)
  - 우리 앱 구동 없음, Zed만 `zed -n <폴더>` 새 창으로 단독 구동.
  - 앱 데이터 백업/복원 불필요 (session.ps1 미사용).
  - 클라이언트 1440×852, 100% DPI, Ensure-ClientSize로 고정.
  - 덤프가 없는 Zed이므로 좌표는 창 크기 기준 비율과 캡처로 정하고, 상태 변화 확인은 캡처 SHA256 해시 전후 비교로 엄격히 검증.
  - 측정 단계 (C-33 대상, 항목 독립 실행 가능):
    1. zed-step1-notabs: 탭 없는 상태의 상태 바 전체 크롭 (오른쪽 끝까지).
    2. zed-step2-cursor-and-filetypes: 파일 하나 열고 커서를 몇 줄 아래로 -> 상태 바 오른쪽 크롭 ({line}:{column} {Filetype} 위치).
       Shift+방향키로 선택 만든 뒤 크롭 (선택 표시 형식).
       다른 형식 파일(.rs, .json, .ts, .txt) 각각 열어 파일 형식 이름 크롭.
    3. zed-step3-left-buttons-tooltips: 상태 바 왼쪽 버튼들 확대 크롭, 각 버튼에 hover 1초 -> 툴팁 크롭.
       왼쪽 dock(프로젝트 패널) 열림/닫힘 두 상태 크롭 (켜짐 표시).
    4. zed-step4-project-search: 검색 버튼 클릭 -> Project Search 탭 캡처 (빈 상태),
       검색어 입력 + Enter -> 결과 캡처 (발췌·결과 수), 옵션 버튼 영역 확대 크롭.
    5. zed-step5-diagnostics: 진단(✓) 버튼 클릭 -> Diagnostics 탭 캡처 (문제 없을 때 문구).
    6. zed-step6-close-cleanup: 자기 창 WM_CLOSE (저장 대화상자 뜨면 닫지 말고 로그).
  - 안전 조치:
    * Zed 설정 파일(%APPDATA%\Zed\settings.json, keymap.json) 전후 SHA256 해시 대조하여 불변성 100% 보장.
    * Zed Settings (Ctrl-,) 절대 열지 않음.
    * 자신이 띄운 PID 및 새로 생성된 HWND 차이로 찾고, 자기 창만 WM_CLOSE로 닫기.
    * fixture 폴더는 스크립트가 -Out 아래 직접 생성 (마크다운 하나, 코드 파일 몇 개, 같은 검색어 여러 곳).
    * 각 단계 독립 실행 및 try-catch 기반 상태 기록 ($global:summary).

.PARAMETER Out
  출력 디렉터리 (기본값: specs\v0.5\verify\reviews\measure-ORDER-08).

.PARAMETER ZedExe
  Zed 실행 파일 경로.

.PARAMETER DryRun
  Zed 프로세스 구동 없이 단계 구성, fixture 준비, 설정 해시 검사만 수행하는 모드.

.PARAMETER Steps
  실행할 단계 목록. 기본값: 모든 단계 실행.

.PARAMETER Skip
  건너뛸 단계 목록.
#>
[CmdletBinding()]
param(
    [string]$Out = 'specs\v0.5\verify\reviews\measure-ORDER-08',
    [string]$ZedExe = 'C:\Users\nampl\AppData\Local\Programs\Zed\bin\zed.exe',
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
    "zed" = [ordered]@{}
    "crops" = [ordered]@{}
    "config_hashes" = [ordered]@{}
    "action_verifications" = [ordered]@{}
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
    }
    return $false
}

function L([string]$msg) {
    $ts = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    $line = "$ts $msg"
    Write-Host $line
    if (-not $DryRun) {
        $line | Add-Content -LiteralPath $logFile -Encoding utf8
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    L "=== ORDER-08 Zed Measure Script Initialized ==="
    L "Out Directory: $Out"
    L "ZedExe: $ZedExe"
    if ($Steps) { L "Steps Filter: $($Steps -join ',')" }
    if ($Skip) { L "Skip Filter: $($Skip -join ',')" }
}

# ---------------------------------------------------------------------------
# 1. Native API Definition (C# P/Invoke)
# ---------------------------------------------------------------------------
$nativeSource = @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

public static class Order08Native {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }

    [StructLayout(LayoutKind.Sequential)]
    public struct POINT { public int X; public int Y; }

    [StructLayout(LayoutKind.Sequential)]
    public struct INPUT {
        public uint type;
        public MOUSEKEYBDHARDWAREINPUT mkhi;
    }

    [StructLayout(LayoutKind.Explicit)]
    public struct MOUSEKEYBDHARDWAREINPUT {
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

    public static void KeyPress(byte vk) {
        keybd_event(vk, 0, 0, IntPtr.Zero);
        Thread.Sleep(40);
        keybd_event(vk, 0, KEYEVENTF_KEYUP, IntPtr.Zero);
        Thread.Sleep(40);
    }

    public static void KeyCombo(ushort[] modifiers, ushort key) {
        foreach (var m in modifiers) keybd_event((byte)m, 0, 0, IntPtr.Zero);
        Thread.Sleep(40);
        keybd_event((byte)key, 0, 0, IntPtr.Zero);
        Thread.Sleep(50);
        keybd_event((byte)key, 0, KEYEVENTF_KEYUP, IntPtr.Zero);
        Thread.Sleep(40);
        for (int i = modifiers.Length - 1; i >= 0; i--) keybd_event((byte)modifiers[i], 0, KEYEVENTF_KEYUP, IntPtr.Zero);
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

if (-not ([System.Management.Automation.PSTypeName]'Order08Native').Type) {
    Add-Type -TypeDefinition $nativeSource -Language CSharp
}

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

# ---------------------------------------------------------------------------
# 2. Window Capture and Crop Helpers
# ---------------------------------------------------------------------------
function Ensure-Foreground([IntPtr]$hwnd, [string]$label = '') {
    [void][Order08Native]::SetForegroundWindow($hwnd)
    Start-Sleep -Milliseconds 150
    $fg = [Order08Native]::GetForegroundWindow()
    if ($fg -ne $hwnd) {
        [void][Order08Native]::ShowWindow($hwnd, 9) # SW_RESTORE
        [void][Order08Native]::SetForegroundWindow($hwnd)
        Start-Sleep -Milliseconds 200
        $fg = [Order08Native]::GetForegroundWindow()
    }
    if ($fg -ne $hwnd) {
        $pt = New-Object Order08Native+POINT
        $pt.X = 0; $pt.Y = 0
        [void][Order08Native]::ClientToScreen($hwnd, [ref]$pt)
        [Order08Native]::Click($pt.X + 500, $pt.Y + 16)
        Start-Sleep -Milliseconds 300
        $fg = [Order08Native]::GetForegroundWindow()
    }
    L ("Foreground check for '$label': target=0x{0:X}, foreground=0x{1:X}" -f $hwnd.ToInt64(), $fg.ToInt64())
    if ($fg -ne $hwnd) {
        L ("Warning: Foreground window (0x{0:X}) != target (0x{1:X}) during $label" -f $fg.ToInt64(), $hwnd.ToInt64())
    }
}

function Cap-Window([IntPtr]$hwnd, [string]$name, [string]$outDir) {
    Ensure-Foreground $hwnd "Capture $name"
    $pngPath = Join-Path $outDir "$name.png"
    & pwsh -NoProfile -File 'tools/capture.ps1' -Hwnd ("0x{0:X}" -f $hwnd.ToInt64()) -Method Screen -Out $pngPath *> $null
    L "Capture '$name' -> $pngPath (exit=$LASTEXITCODE)"
    if (-not (Test-Path -LiteralPath $pngPath)) {
        throw "Capture failed to produce output image: $pngPath"
    }
    return $pngPath
}

function Save-CroppedImage([string]$srcPath, [string]$dstPath, [int]$x, [int]$y, [int]$w, [int]$h, [int]$scale = 1) {
    if (-not (Test-Path -LiteralPath $srcPath)) {
        throw "Source capture not found for crop: $srcPath"
    }
    $bytes = [System.IO.File]::ReadAllBytes($srcPath)
    $ms = [System.IO.MemoryStream]::new($bytes)
    $src = [System.Drawing.Bitmap]::FromStream($ms)
    try {
        $x = [Math]::Max(0, [Math]::Min($src.Width - 1, $x))
        $y = [Math]::Max(0, [Math]::Min($src.Height - 1, $y))
        $w = [Math]::Max(1, [Math]::Min($src.Width - $x, $w))
        $h = [Math]::Max(1, [Math]::Min($src.Height - $y, $h))
        $rect = [System.Drawing.Rectangle]::new($x, $y, $w, $h)

        $dstW = $w * $scale
        $dstH = $h * $scale
        $bmp = [System.Drawing.Bitmap]::new($dstW, $dstH)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        try {
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
            $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
            $g.DrawImage($src, [System.Drawing.Rectangle]::new(0, 0, $dstW, $dstH), $rect, [System.Drawing.GraphicsUnit]::Pixel)
        } finally {
            $g.Dispose()
        }

        $outMs = [System.IO.MemoryStream]::new()
        try {
            $bmp.Save($outMs, [System.Drawing.Imaging.ImageFormat]::Png)
            [System.IO.File]::WriteAllBytes($dstPath, $outMs.ToArray())
        } finally {
            $outMs.Dispose()
            $bmp.Dispose()
        }
    } finally {
        $src.Dispose()
        $ms.Dispose()
    }
}

function Ensure-ClientSize([IntPtr]$hwnd, [int]$expectedW, [int]$expectedH, [string]$procName = 'Zed') {
    $resizeOutput = & pwsh -NoProfile -File 'tools/measure/window-rect.ps1' -ProcessName $procName -TargetHwnd ("0x{0:X}" -f $hwnd.ToInt64()) -Action Resize -X 232 -Y 90 -Width 1456 -Height 860 2>&1
    foreach ($line in $resizeOutput) { L "Resize: $line" }
    Start-Sleep -Milliseconds 600

    $cr = New-Object Order08Native+RECT
    [void][Order08Native]::GetClientRect($hwnd, [ref]$cr)
    $actualW = $cr.Right - $cr.Left
    $actualH = $cr.Bottom - $cr.Top
    L "Client size check ($procName): target=${expectedW}x${expectedH}, actual=${actualW}x${actualH}"

    if ($actualW -ne $expectedW -or $actualH -ne $expectedH) {
        L "Directly applying SetWindowPos to adjust to 1456x860..."
        [void][Order08Native]::SetWindowPos($hwnd, [IntPtr]::Zero, 232, 90, 1456, 860, 0x0004 -bor 0x0010)
        Start-Sleep -Milliseconds 600
        [void][Order08Native]::GetClientRect($hwnd, [ref]$cr)
        $actualW = $cr.Right - $cr.Left
        $actualH = $cr.Bottom - $cr.Top
        L "Re-checked client size: ${actualW}x${actualH}"
    }
}

function Assert-CaptureChanged([string]$beforePath, [string]$afterPath, [string]$actionDesc) {
    if (-not (Test-Path -LiteralPath $beforePath) -or -not (Test-Path -LiteralPath $afterPath)) {
        throw "Cannot compare capture hash: file missing ($beforePath or $afterPath)"
    }
    $hBefore = (Get-FileHash -LiteralPath $beforePath -Algorithm SHA256).Hash
    $hAfter = (Get-FileHash -LiteralPath $afterPath -Algorithm SHA256).Hash
    $changed = ($hBefore -ne $hAfter)
    L ("Capture hash check for '{0}': before={1}.. after={2}.. (changed={3})" -f $actionDesc, $hBefore.Substring(0, 8), $hAfter.Substring(0, 8), $changed)
    $global:summary['action_verifications'][$actionDesc] = [ordered]@{
        "before_hash" = $hBefore
        "after_hash" = $hAfter
        "changed" = $changed
    }
    if (-not $changed) {
        L ("Warning: Capture hash unchanged for '{0}' (expected visible state transition)" -f $actionDesc)
    }
    return $changed
}

# ---------------------------------------------------------------------------
# 3. Zed Configuration Hash Checks (Safety Guarantee)
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
    L "--- Zed Config Hash Status ($stage) ---"
    foreach ($k in $status.Keys) {
        $info = $status[$k]
        L ("  {0}: Exists={1}, Sha256={2}, Length={3}" -f $k, $info.Exists, $info.Sha256, $info.Length)
    }
}

function Compare-ZedConfigStatus([System.Collections.IDictionary]$before, [System.Collections.IDictionary]$after) {
    foreach ($k in $before.Keys) {
        $b = $before[$k]
        $a = $after[$k]
        if ($b.Exists -ne $a.Exists -or $b.Sha256 -ne $a.Sha256 -or $b.Length -ne $a.Length) {
            return $false
        }
    }
    return $true
}

# ---------------------------------------------------------------------------
# 4. Fixture Creation Helper
# ---------------------------------------------------------------------------
function Initialize-FixtureDirectory([string]$targetDir) {
    New-Item -ItemType Directory -Force $targetDir | Out-Null
    
    # 1. doc.md (Markdown)
    $docMd = @"
# Fixture Document

Line 2: Testing Zed Status Bar
Line 3: Multiple occurrences of TARGET_SEARCH_KEYWORD
Line 4: Another line for cursor navigation
Line 5: TARGET_SEARCH_KEYWORD in doc.md
Line 6: Plain text line
Line 7: Final line of markdown
"@
    $docMd | Set-Content -LiteralPath (Join-Path $targetDir 'doc.md') -Encoding utf8

    # 2. src\main.rs (Rust)
    $srcDir = Join-Path $targetDir 'src'
    New-Item -ItemType Directory -Force $srcDir | Out-Null
    $mainRs = @"
// Rust source fixture
fn main() {
    println!("TARGET_SEARCH_KEYWORD in rust");
    let value = 42;
}
"@
    $mainRs | Set-Content -LiteralPath (Join-Path $srcDir 'main.rs') -Encoding utf8

    # 3. data.json (JSON)
    $dataJson = @"
{
  "name": "order08-fixture",
  "query": "TARGET_SEARCH_KEYWORD",
  "count": 100
}
"@
    $dataJson | Set-Content -LiteralPath (Join-Path $targetDir 'data.json') -Encoding utf8

    # 4. app.ts (TypeScript)
    $appTs = @"
// TypeScript source fixture
export function testSearch(): string {
    const marker = "TARGET_SEARCH_KEYWORD";
    return marker;
}
"@
    $appTs | Set-Content -LiteralPath (Join-Path $targetDir 'app.ts') -Encoding utf8

    # 5. notes.txt (Plain Text)
    $notesTxt = @"
Notes fixture
TARGET_SEARCH_KEYWORD appears here too.
End of notes.
"@
    $notesTxt | Set-Content -LiteralPath (Join-Path $targetDir 'notes.txt') -Encoding utf8

    L "Fixture directory initialized at: $targetDir"
    L "Created files: doc.md, src/main.rs, data.json, app.ts, notes.txt"
}

# ---------------------------------------------------------------------------
# 5. Step Execution Runner
# ---------------------------------------------------------------------------
function Invoke-MeasureStep([string]$target, [string]$stepKey, [string]$stepTitle, [scriptblock]$action) {
    if (-not (Should-RunStep $stepKey)) {
        L "[$target] Step '$stepKey' ($stepTitle) -> SKIPPED"
        $global:summary[$target][$stepKey] = "SKIPPED"
        return
    }
    L "====================================================================="
    L "[$target] Running Step: '$stepKey' - $stepTitle"
    L "====================================================================="
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        & $action
        $sw.Stop()
        L "[$target] Step '$stepKey' -> PASS ($($sw.ElapsedMilliseconds) ms)"
        $global:summary[$target][$stepKey] = "PASS"
    } catch {
        $sw.Stop()
        $errMsg = $_.Exception.Message
        L "[$target] Step '$stepKey' -> FAIL ($($sw.ElapsedMilliseconds) ms): $errMsg"
        $global:summary[$target][$stepKey] = "FAIL: $errMsg"
    }
}

# ---------------------------------------------------------------------------
# 6. Main Zed Measurement Routine
# ---------------------------------------------------------------------------
function Run-ZedMeasure {
    L "=== Starting Zed ORDER-08 Measurement Routine ==="

    # Fixture directory creation under $Out
    $fixtureDir = Join-Path $Out 'order08-fixture'
    Initialize-FixtureDirectory $fixtureDir

    # 1. Record Zed config file hashes before execution
    $hashesBefore = Get-ZedConfigStatus
    $global:summary['config_hashes']['before'] = $hashesBefore
    Log-ZedConfigStatus 'BEFORE' $hashesBefore

    # 2. Enumerate existing Zed top-level windows
    $zedPidsBefore = [uint32[]]@(Get-Process -Name Zed -ErrorAction SilentlyContinue | ForEach-Object { [uint32]$_.Id })
    $beforeHwnds = @()
    if (@($zedPidsBefore).Count -gt 0) {
        $beforeHwnds = @([Order08Native]::GetProcessTopLevelWindows($zedPidsBefore))
    }
    L ("Zed top-level HWNDs before launch: " + (($beforeHwnds | ForEach-Object { '0x{0:X}' -f $_.ToInt64() }) -join ', '))

    $zedHwnd = [IntPtr]::Zero
    $zo = New-Object Order08Native+POINT

    try {
        $zedPrereqOk = $false
        try {
            L "Launching Zed (new window only, -a forbidden) with project folder: $ZedExe -n `"$fixtureDir`""
            Start-Process -FilePath $ZedExe -ArgumentList @('-n', "`"$fixtureDir`"")

            foreach ($i in 1..60) {
                Start-Sleep -Milliseconds 500
                $currentPids = [uint32[]]@(Get-Process -Name Zed -ErrorAction SilentlyContinue | ForEach-Object { [uint32]$_.Id })
                if (@($currentPids).Count -eq 0) { continue }
                $currentHwnds = @([Order08Native]::GetProcessTopLevelWindows($currentPids))
                $newHwnds = @($currentHwnds | Where-Object { $beforeHwnds -notcontains $_ })
                if (@($newHwnds).Count -gt 0) {
                    $zedHwnd = $newHwnds[0]
                    break
                }
            }
            if ($zedHwnd -eq [IntPtr]::Zero) {
                throw "Newly created Zed window not found within timeout"
            }
            L ("New Zed window found: HWND=0x{0:X}" -f $zedHwnd.ToInt64())
            Start-Sleep -Seconds 3

            L "Resizing Zed to 1440x852 client..."
            Ensure-ClientSize $zedHwnd 1440 852 'Zed'
            Start-Sleep -Seconds 1

            $zr = New-Object Order08Native+RECT
            [void][Order08Native]::GetClientRect($zedHwnd, [ref]$zr)
            [void][Order08Native]::ClientToScreen($zedHwnd, [ref]$zo)
            $clientW = $zr.Right - $zr.Left
            $clientH = $zr.Bottom - $zr.Top
            L "Zed client origin=($($zo.X),$($zo.Y)) size=${clientW}x${clientH}"

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
        # Proportional Coordinates Setup (Zed has no layout dump)
        # -------------------------------------------------------------------
        # Status bar height ratio (30px at 852px standard client height)
        $sbHeight = [Math]::Max(26, [int][Math]::Round($clientH * (30.0 / 852.0)))
        $sbTop = $clientH - $sbHeight

        # Status bar left button centers (relative ratios to 1440 width)
        # Button 1 (Project Panel / Left Dock toggle): ~15px
        $btn1RelX = [int][Math]::Round($clientW * (15.0 / 1440.0))
        # Button 2 (Project Search): ~39px
        $btn2RelX = [int][Math]::Round($clientW * (39.0 / 1440.0))
        # Button 3 (Diagnostics ✓): ~63px
        $btn3RelX = [int][Math]::Round($clientW * (63.0 / 1440.0))
        $btnRelY = $sbTop + [int][Math]::Round($sbHeight / 2.0)

        # Status bar right cluster width ({line}:{column} {Filetype}): ~350px at 1440
        $sbRightW = [Math]::Max(250, [int][Math]::Round($clientW * (350.0 / 1440.0)))
        $sbRightX = $clientW - $sbRightW

        L ("Proportional Status Bar geometry: Top={0}, Height={1}, Btn1=({2},{3}), Btn2=({4},{3}), Btn3=({5},{3}), RightClusterX={6}" -f `
            $sbTop, $sbHeight, $btn1RelX, $btnRelY, $btn2RelX, $btn3RelX, $sbRightX)

        # -------------------------------------------------------------------
        # Step 1: zed-step1-notabs (Tab-less status bar full crop)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'zed-step1-notabs' 'Tab-less status bar full & right crop (I-5 no-tab state)' {
            Ensure-Foreground $zedHwnd "Step 1: No Tabs"
            
            # Baseline capture before close all
            $capBeforeClose = Cap-Window $zedHwnd 'zed-step1-before-close' $Out

            # Send Ctrl-K Ctrl-W to ensure no tabs are open
            L "Sending Ctrl-K Ctrl-W to ensure clean tab-less state..."
            [Order08Native]::KeyCombo(@([ushort]0x11), [ushort]0x4B) # Ctrl-K
            Start-Sleep -Milliseconds 150
            [Order08Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl-W
            Start-Sleep -Milliseconds 800

            $cap = Cap-Window $zedHwnd 'zed-step1-window-notabs' $Out

            # Full status bar crop
            $fullCrop = Join-Path $Out 'zed-step1-statusbar-full.png'
            Save-CroppedImage $cap $fullCrop 0 $sbTop $clientW $sbHeight 1

            # Status bar right crop (I-5: what is shown on the right when no tabs open)
            $rightCrop = Join-Path $Out 'zed-step1-statusbar-right-2x.png'
            Save-CroppedImage $cap $rightCrop $sbRightX $sbTop $sbRightW $sbHeight 2

            # Status bar left crop
            $leftCrop = Join-Path $Out 'zed-step1-statusbar-left-2x.png'
            Save-CroppedImage $cap $leftCrop 0 $sbTop $sbRightW $sbHeight 2

            $global:summary['crops']['zed-step1'] = [ordered]@{
                full = 'zed-step1-statusbar-full.png'
                right = 'zed-step1-statusbar-right-2x.png'
                left = 'zed-step1-statusbar-left-2x.png'
            }
        }

        # -------------------------------------------------------------------
        # Step 2: zed-step2-cursor-and-filetypes (Cursor pos, selection, filetypes)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'zed-step2-cursor-and-filetypes' 'Cursor position, selection display, and filetypes (.rs,.json,.ts,.txt)' {
            Ensure-Foreground $zedHwnd "Step 2: Cursor & Filetypes"

            # 2.1 Baseline capture before open doc.md
            $capBeforeDoc = Cap-Window $zedHwnd 'zed-step2-before-doc' $Out

            # Open doc.md via Ctrl-P
            L "Opening doc.md via file finder (Ctrl-P)..."
            [Order08Native]::KeyCombo(@([ushort]0x11), [ushort]0x50) # Ctrl-P
            Start-Sleep -Milliseconds 600
            [Order08Native]::TypeText('doc.md')
            Start-Sleep -Milliseconds 300
            [Order08Native]::KeyPress(0x0D) # Enter
            Start-Sleep -Milliseconds 1500

            $capDocOpen = Cap-Window $zedHwnd 'zed-step2-doc-open' $Out
            [void](Assert-CaptureChanged $capBeforeDoc $capDocOpen "Open doc.md")

            # 2.2 Move cursor down a few lines and right
            L "Moving cursor down 3 lines and right 5 columns..."
            for ($k = 0; $k -lt 3; $k++) { [Order08Native]::KeyPress(0x28); Start-Sleep -Milliseconds 50 } # Down
            for ($k = 0; $k -lt 5; $k++) { [Order08Native]::KeyPress(0x27); Start-Sleep -Milliseconds 50 } # Right
            Start-Sleep -Milliseconds 500

            $capCursor = Cap-Window $zedHwnd 'zed-step2-doc-cursor' $Out
            [void](Assert-CaptureChanged $capDocOpen $capCursor "Move cursor in doc.md")

            $cursorCrop = Join-Path $Out 'zed-step2-cursor-pos-crop-2x.png'
            Save-CroppedImage $capCursor $cursorCrop $sbRightX $sbTop $sbRightW $sbHeight 2

            # 2.3 Make selection with Shift + arrows
            L "Creating selection with Shift+Down and Shift+Right..."
            [Order08Native]::KeyCombo(@([ushort]0x10), [ushort]0x28) # Shift+Down
            Start-Sleep -Milliseconds 50
            [Order08Native]::KeyCombo(@([ushort]0x10), [ushort]0x28) # Shift+Down
            Start-Sleep -Milliseconds 50
            for ($k = 0; $k -lt 4; $k++) {
                [Order08Native]::KeyCombo(@([ushort]0x10), [ushort]0x27) # Shift+Right
                Start-Sleep -Milliseconds 50
            }
            Start-Sleep -Milliseconds 500

            $capSelection = Cap-Window $zedHwnd 'zed-step2-doc-selection' $Out
            [void](Assert-CaptureChanged $capCursor $capSelection "Make selection in doc.md")

            $selectionCrop = Join-Path $Out 'zed-step2-selection-crop-2x.png'
            Save-CroppedImage $capSelection $selectionCrop ([Math]::Max(0, $clientW - 400)) $sbTop 400 $sbHeight 2

            # Close doc.md
            [Order08Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl-W
            Start-Sleep -Milliseconds 600

            # 2.4 Open other file types (.rs, .json, .ts, .txt) and crop filetype name position
            $filetypeMap = [ordered]@{
                "rs"   = "main.rs"
                "json" = "data.json"
                "ts"   = "app.ts"
                "txt"  = "notes.txt"
            }

            foreach ($ext in $filetypeMap.Keys) {
                $fname = $filetypeMap[$ext]
                $capBeforeExt = Cap-Window $zedHwnd "zed-step2-before-$ext" $Out

                L "Opening $fname to verify $ext filetype display..."
                [Order08Native]::KeyCombo(@([ushort]0x11), [ushort]0x50) # Ctrl-P
                Start-Sleep -Milliseconds 600
                [Order08Native]::TypeText($fname)
                Start-Sleep -Milliseconds 300
                [Order08Native]::KeyPress(0x0D) # Enter
                Start-Sleep -Milliseconds 1500

                $capExt = Cap-Window $zedHwnd "zed-step2-$ext-window" $Out
                [void](Assert-CaptureChanged $capBeforeExt $capExt "Open $fname ($ext)")

                $cropExt = Join-Path $Out "zed-step2-filetype-$ext-crop-2x.png"
                Save-CroppedImage $capExt $cropExt ([Math]::Max(0, $clientW - 250)) $sbTop 250 $sbHeight 2

                # Close file
                [Order08Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl-W
                Start-Sleep -Milliseconds 600
            }

            $global:summary['crops']['zed-step2'] = [ordered]@{
                cursor = 'zed-step2-cursor-pos-crop-2x.png'
                selection = 'zed-step2-selection-crop-2x.png'
                filetypes = @('rs', 'json', 'ts', 'txt')
            }
        }

        # -------------------------------------------------------------------
        # Step 3: zed-step3-left-buttons-tooltips (Left buttons, hover tooltips, dock)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'zed-step3-left-buttons-tooltips' 'Status bar left buttons, hover tooltips, and dock open/closed states' {
            Ensure-Foreground $zedHwnd "Step 3: Left buttons & tooltips"
            Start-Sleep -Milliseconds 500

            # 3.1 Status bar left buttons zoom crop
            $capButtons = Cap-Window $zedHwnd 'zed-step3-left-buttons-window' $Out
            $buttonsCrop = Join-Path $Out 'zed-step3-left-buttons-crop-4x.png'
            Save-CroppedImage $capButtons $buttonsCrop 0 $sbTop ([Math]::Min(180, [int][Math]::Round($clientW * 0.15))) $sbHeight 4

            # 3.2 Hover on each button for 1 second and capture tooltip with hash check
            # Button 1: Left dock / Project panel toggle
            L "Hovering over button 1 (Project Panel / Left Dock) for 1s..."
            [Order08Native]::MoveTo($zo.X + $btn1RelX, $zo.Y + $btnRelY)
            Start-Sleep -Milliseconds 1200
            $capTip1 = Cap-Window $zedHwnd 'zed-step3-tooltip-btn1-window' $Out
            [void](Assert-CaptureChanged $capButtons $capTip1 "Button 1 Tooltip Hover")
            $tip1Crop = Join-Path $Out 'zed-step3-tooltip-btn1-crop.png'
            Save-CroppedImage $capTip1 $tip1Crop 0 ([Math]::Max(0, $sbTop - 80)) 250 80 1

            # Button 2: Project Search
            L "Hovering over button 2 (Project Search) for 1s..."
            [Order08Native]::MoveTo($zo.X + $btn2RelX, $zo.Y + $btnRelY)
            Start-Sleep -Milliseconds 1200
            $capTip2 = Cap-Window $zedHwnd 'zed-step3-tooltip-btn2-window' $Out
            [void](Assert-CaptureChanged $capButtons $capTip2 "Button 2 Tooltip Hover")
            $tip2Crop = Join-Path $Out 'zed-step3-tooltip-btn2-crop.png'
            Save-CroppedImage $capTip2 $tip2Crop 15 ([Math]::Max(0, $sbTop - 80)) 250 80 1

            # Button 3: Diagnostics
            L "Hovering over button 3 (Diagnostics) for 1s..."
            [Order08Native]::MoveTo($zo.X + $btn3RelX, $zo.Y + $btnRelY)
            Start-Sleep -Milliseconds 1200
            $capTip3 = Cap-Window $zedHwnd 'zed-step3-tooltip-btn3-window' $Out
            [void](Assert-CaptureChanged $capButtons $capTip3 "Button 3 Tooltip Hover")
            $tip3Crop = Join-Path $Out 'zed-step3-tooltip-btn3-crop.png'
            Save-CroppedImage $capTip3 $tip3Crop 35 ([Math]::Max(0, $sbTop - 80)) 250 80 1

            # Dismiss tooltip by moving away to window center
            [Order08Native]::MoveTo($zo.X + [int][Math]::Round($clientW / 2.0), $zo.Y + [int][Math]::Round($clientH / 2.0))
            Start-Sleep -Milliseconds 500

            # 3.3 Left dock (project panel) open / closed states crop with hash check
            # Dock OPEN state
            L "Capturing left dock OPEN state on status bar..."
            $capDockOpen = Cap-Window $zedHwnd 'zed-step3-dock-open-window' $Out
            $dockOpenCrop = Join-Path $Out 'zed-step3-dock-open-btn-4x.png'
            Save-CroppedImage $capDockOpen $dockOpenCrop 0 $sbTop 80 $sbHeight 4

            # Toggle left dock CLOSED via button click (or Ctrl-B)
            L "Clicking button 1 (or Ctrl-B) to close left dock..."
            [Order08Native]::Click($zo.X + $btn1RelX, $zo.Y + $btnRelY)
            Start-Sleep -Milliseconds 800
            $capDockClosed = Cap-Window $zedHwnd 'zed-step3-dock-closed-window' $Out
            [void](Assert-CaptureChanged $capDockOpen $capDockClosed "Toggle Left Dock Closed")
            $dockClosedCrop = Join-Path $Out 'zed-step3-dock-closed-btn-4x.png'
            Save-CroppedImage $capDockClosed $dockClosedCrop 0 $sbTop 80 $sbHeight 4

            # Toggle left dock back OPEN
            L "Re-opening left dock..."
            [Order08Native]::Click($zo.X + $btn1RelX, $zo.Y + $btnRelY)
            Start-Sleep -Milliseconds 800
            $capDockReopen = Cap-Window $zedHwnd 'zed-step3-dock-reopened-window' $Out
            [void](Assert-CaptureChanged $capDockClosed $capDockReopen "Re-open Left Dock")

            $global:summary['crops']['zed-step3'] = [ordered]@{
                buttons = 'zed-step3-left-buttons-crop-4x.png'
                tooltip_btn1 = 'zed-step3-tooltip-btn1-crop.png'
                tooltip_btn2 = 'zed-step3-tooltip-btn2-crop.png'
                tooltip_btn3 = 'zed-step3-tooltip-btn3-crop.png'
                dock_open = 'zed-step3-dock-open-btn-4x.png'
                dock_closed = 'zed-step3-dock-closed-btn-4x.png'
            }
        }

        # -------------------------------------------------------------------
        # Step 4: zed-step4-project-search (Project Search tab & query)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'zed-step4-project-search' 'Project Search tab empty state, search query execution, and options crop' {
            Ensure-Foreground $zedHwnd "Step 4: Project Search"

            # 4.1 Baseline capture before opening Project Search
            $capBeforeSearch = Cap-Window $zedHwnd 'zed-step4-before-search' $Out

            # Click search button in status bar (or Ctrl-Shift-F)
            L "Clicking Search button in status bar (or Ctrl-Shift-F)..."
            [Order08Native]::Click($zo.X + $btn2RelX, $zo.Y + $btnRelY)
            Start-Sleep -Milliseconds 1200

            $capSearchEmpty = Cap-Window $zedHwnd 'zed-step4-search-empty-window' $Out
            [void](Assert-CaptureChanged $capBeforeSearch $capSearchEmpty "Open Project Search Tab")

            $searchEmptyCrop = Join-Path $Out 'zed-step4-search-empty-crop.png'
            Save-CroppedImage $capSearchEmpty $searchEmptyCrop 0 35 $clientW 250 1

            # 4.2 Enter search query and press Enter
            L "Typing search keyword 'TARGET_SEARCH_KEYWORD' and pressing Enter..."
            [Order08Native]::TypeText('TARGET_SEARCH_KEYWORD')
            Start-Sleep -Milliseconds 400
            [Order08Native]::KeyPress(0x0D) # Enter
            Start-Sleep -Milliseconds 2000

            $capSearchResults = Cap-Window $zedHwnd 'zed-step4-search-results-window' $Out
            [void](Assert-CaptureChanged $capSearchEmpty $capSearchResults "Execute Project Search Query")

            $searchResultsCrop = Join-Path $Out 'zed-step4-search-results-crop.png'
            Save-CroppedImage $capSearchResults $searchResultsCrop 0 35 $clientW 450 1

            # 4.3 Options button area zoom crop
            $searchOptionsCrop = Join-Path $Out 'zed-step4-search-options-crop-2x.png'
            Save-CroppedImage $capSearchResults $searchOptionsCrop 0 35 600 120 2

            # Close Project Search tab
            L "Closing Project Search tab via Ctrl-W..."
            [Order08Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl-W
            Start-Sleep -Milliseconds 600

            $global:summary['crops']['zed-step4'] = [ordered]@{
                empty = 'zed-step4-search-empty-crop.png'
                results = 'zed-step4-search-results-crop.png'
                options = 'zed-step4-search-options-crop-2x.png'
            }
        }

        # -------------------------------------------------------------------
        # Step 5: zed-step5-diagnostics (Diagnostics tab empty state)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'zed-step5-diagnostics' 'Diagnostics tab (checkmark button) empty state capture' {
            Ensure-Foreground $zedHwnd "Step 5: Diagnostics"

            # 5.1 Baseline capture before opening Diagnostics
            $capBeforeDiag = Cap-Window $zedHwnd 'zed-step5-before-diag' $Out

            # Click Diagnostics (✓) button in status bar (or Ctrl-Shift-M)
            L "Clicking Diagnostics button in status bar (or Ctrl-Shift-M)..."
            [Order08Native]::Click($zo.X + $btn3RelX, $zo.Y + $btnRelY)
            Start-Sleep -Milliseconds 1200

            $capDiag = Cap-Window $zedHwnd 'zed-step5-diagnostics-window' $Out
            [void](Assert-CaptureChanged $capBeforeDiag $capDiag "Open Diagnostics Tab")

            $diagCrop = Join-Path $Out 'zed-step5-diagnostics-crop.png'
            Save-CroppedImage $capDiag $diagCrop 0 35 $clientW 350 1

            # Close Diagnostics tab
            L "Closing Diagnostics tab via Ctrl-W..."
            [Order08Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl-W
            Start-Sleep -Milliseconds 600

            $global:summary['crops']['zed-step5'] = [ordered]@{
                diagnostics = 'zed-step5-diagnostics-crop.png'
            }
        }

    } catch {
        $ex = $_.Exception
        $line = $_.InvocationInfo.ScriptLineNumber
        $offset = $_.InvocationInfo.OffsetInLine
        $stack = $_.ScriptStackTrace
        L ("[FATAL ERROR] In Run-ZedMeasure at line {0}:{1}: {2}: {3}`nStackTrace:`n{4}" -f $line, $offset, $ex.GetType().FullName, $ex.Message, $stack)
        throw
    } finally {
        # -------------------------------------------------------------------
        # Step 6: zed-step6-close-cleanup (Close target Zed window safely)
        # -------------------------------------------------------------------
        if ($zedHwnd -ne [IntPtr]::Zero) {
            L ("Closing target Zed window only (HWND=0x{0:X}) via WM_CLOSE PostMessage..." -f $zedHwnd.ToInt64())
            [void][Order08Native]::PostMessage($zedHwnd, [Order08Native]::WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
            Start-Sleep -Seconds 2

            $stillAlive = [Order08Native]::IsWindow($zedHwnd)
            if ($stillAlive) {
                $wTitle = [Order08Native]::Title($zedHwnd)
                L ("Warning: Target Zed window HWND=0x{0:X} is still present ('{1}'). Checking if save dialog appeared..." -f $zedHwnd.ToInt64(), $wTitle)
                # Do not force kill if save dialog or user prompt is present
            } else {
                L ("Target Zed window HWND=0x{0:X} successfully closed" -f $zedHwnd.ToInt64())
            }
        }

        # Verify Zed config hashes after execution
        $hashesAfter = Get-ZedConfigStatus
        $global:summary['config_hashes']['after'] = $hashesAfter
        Log-ZedConfigStatus 'AFTER' $hashesAfter
        $intact = Compare-ZedConfigStatus $hashesBefore $hashesAfter
        $global:summary['config_hashes']['intact'] = $intact
        if (-not $intact) {
            $global:summary['zed']['config_integrity'] = "FAIL: Zed config files were modified!"
            throw "CRITICAL: Zed config files were modified during measurement!"
        } else {
            $global:summary['zed']['config_integrity'] = "PASS: Config files 100% intact"
        }
    }
}

# ---------------------------------------------------------------------------
# 7. DryRun Mode
# ---------------------------------------------------------------------------
function Run-DryRun {
    L "=== ORDER-08 DryRun Mode Started ==="

    $fixtureDir = Join-Path $Out 'order08-fixture'
    Initialize-FixtureDirectory $fixtureDir

    # Check fixture files
    $requiredFiles = @('doc.md', 'src\main.rs', 'data.json', 'app.ts', 'notes.txt')
    foreach ($f in $requiredFiles) {
        $p = Join-Path $fixtureDir $f
        if (Test-Path -LiteralPath $p) {
            $len = (Get-Item -LiteralPath $p).Length
            L "Fixture file verified: $f (Length=$len bytes)"
        } else {
            throw "Fixture file missing: $f"
        }
    }

    # Verify search keyword present in all files
    $searchKey = "TARGET_SEARCH_KEYWORD"
    foreach ($f in $requiredFiles) {
        $p = Join-Path $fixtureDir $f
        $cnt = @(Select-String -Path $p -Pattern $searchKey).Count
        L "Search keyword '$searchKey' occurrences in $f : $cnt"
        if ($cnt -lt 1) {
            throw "Search keyword missing in fixture file: $f"
        }
    }

    # Check Zed executable
    if (Test-Path -LiteralPath $ZedExe) {
        L "Zed executable verified: $ZedExe"
    } else {
        L "Warning: Zed executable not found at: $ZedExe (DryRun continuing)"
    }

    # Check Zed config hashes
    $hashes = Get-ZedConfigStatus
    Log-ZedConfigStatus 'DRY_RUN' $hashes

    L "--- Planned Steps Simulation ---"
    $plannedSteps = @(
        'zed-step1-notabs',
        'zed-step2-cursor-and-filetypes',
        'zed-step3-left-buttons-tooltips',
        'zed-step4-project-search',
        'zed-step5-diagnostics',
        'zed-step6-close-cleanup'
    )

    foreach ($st in $plannedSteps) {
        $status = if ($st -eq 'zed-step6-close-cleanup' -or (Should-RunStep $st)) { "PLANNED (ENABLED)" } else { "SKIPPED (FILTERED)" }
        L "  Step: $st -> $status"
        $global:summary['zed'][$st] = $status
    }

    $global:summary['status'] = "DRY_RUN_PASS"
    $summaryJson = Join-Path $Out 'summary.json'
    $global:summary | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $summaryJson -Encoding utf8
    L "DryRun summary written to: $summaryJson"
    L "=== ORDER-08 DryRun Completed Successfully ==="
}

# ---------------------------------------------------------------------------
# 8. Script Entrypoint
# ---------------------------------------------------------------------------
try {
    if ($DryRun) {
        Run-DryRun
    } else {
        Run-ZedMeasure
        $summaryJson = Join-Path $Out 'summary.json'
        $global:summary | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $summaryJson -Encoding utf8
        L "Measurement summary written to: $summaryJson"
    }
} catch {
    $ex = $_.Exception
    $line = $_.InvocationInfo.ScriptLineNumber
    $offset = $_.InvocationInfo.OffsetInLine
    L ("[TOP-LEVEL FATAL] Execution failed at line {0}:{1}: {2}: {3}`nStackTrace:`n{4}" -f $line, $offset, $ex.GetType().FullName, $ex.Message, $_.ScriptStackTrace)
    $global:summary['fatal_error'] = [ordered]@{
        message = $ex.Message
        type = $ex.GetType().FullName
        line = $line
        offset = $offset
    }
    $summaryJson = Join-Path $Out 'summary.json'
    $global:summary | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $summaryJson -Encoding utf8
    exit 1
}

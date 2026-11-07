#Requires -Version 7
<#
.SYNOPSIS
  ORDER-03 V3 화면 검증(UI 실측) 입력·캡처 스크립트.
  (gpui-checker 작성, leader가 화면 차례 안에서 실행한다.)

.DESCRIPTION
  - 우리 앱(workbench-gpui) 및 Zed를 동일 조건(클라이언트 1440×852, 동일 마크다운 픽스처)으로 구동.
  - S-1 ~ S-8 화면 상태를 차례로 만들고 Screen 방식으로 창을 캡처한다.
  - 각 단계마다 레이아웃 덤프로 기대 상태(트리 행, 에디터 박스, 분할 pane 2개, 미리보기 탭 등)를 확인하고,
    불일치 시 즉시 오류 캡처를 남기고 중단한다 (무효 캡처 방지).
  - 자신이 실행한 프로세스/창만 닫으며, 이미 실행 중인 다른 프로세스/창은 절대 건드리지 않는다.
  - 모든 조작과 좌표, 타임스탬프를 $Out\log.txt에 기록한다.

.PARAMETER Out
  출력 디렉터리 (기본값: specs\v0.5\verify\reviews\measure-ORDER-03).

.PARAMETER Only
  App, Zed, Both 중 선택 (기본값: Both).

.PARAMETER AppExe
  workbench-gpui 실행 파일 경로.

.PARAMETER ZedExe
  Zed 실행 파일 경로 (기본값: C:\Users\nampl\AppData\Local\Programs\Zed\bin\zed.exe).

.PARAMETER FixturePath
  측정에 사용할 마크다운 파일 경로 (미지정 시 $Out\order03-fixture.md 자동 생성).
#>
[CmdletBinding()]
param(
    [string]$Out = 'specs\v0.5\verify\reviews\measure-ORDER-03',
    [ValidateSet('App', 'Zed', 'Both')][string]$Only = 'Both',
    [string]$AppExe = 'D:\projects\workbench-gpui\target\debug\workbench-gpui.exe',
    [string]$ZedExe = 'C:\Users\nampl\AppData\Local\Programs\Zed\bin\zed.exe',
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
    "zed" = [ordered]@{}
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
            if (($stepKey -eq 'S-5-code' -or $stepKey -eq 'S-5') -and ($s -eq 'S-5-code' -or $s -eq 'S-5')) { return $true }
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
    L "=== ORDER-03 V3 Capture Script Started (Only=$Only, Out=$Out) ==="
}

# ---------------------------------------------------------------------------
# 1. Native API Definition (Order03Native)
# ---------------------------------------------------------------------------
if (-not ('Order03Native' -as [type])) {
    Add-Type -ReferencedAssemblies @('System.Runtime', 'System.Collections', 'System.Threading', 'System.Threading.Thread', 'System.Runtime.InteropServices') -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

public static class Order03Native {
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
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hWnd, out RECT r);
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

    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] static extern bool EnumWindows(EnumWindowsProc cb, IntPtr lParam);

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

    public static IntPtr FindTitled(uint pid, string title) {
        IntPtr best = IntPtr.Zero; long bestArea = 0;
        EnumWindows((h, l) => {
            uint p; GetWindowThreadProcessId(h, out p);
            if (p != pid || !IsWindowVisible(h) || GetWindow(h, 4) != IntPtr.Zero) return true;
            if (!string.IsNullOrEmpty(title) && Title(h) != title) return true;
            RECT r; GetWindowRect(h, out r);
            long area = (long)(r.Right - r.Left) * (r.Bottom - r.Top);
            if (area > bestArea) { bestArea = area; best = h; }
            return true;
        }, IntPtr.Zero);
        return best;
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

[void][Order03Native]::SetThreadDpiAwarenessContext([IntPtr]::new(-4))

# ---------------------------------------------------------------------------
# 2. Fixture Generation
# ---------------------------------------------------------------------------
if (-not $DryRunStdout) {
if (-not $FixturePath -or -not (Test-Path -LiteralPath $FixturePath)) {
    $FixturePath = Join-Path $Out 'order03-fixture.md'
    $fixtureText = @'
# ORDER-03 Verification Fixture (Heading 1 SEMIBOLD 600)

## Section 1: English Editor Body (I-14 Lilex 15px, Line Height 1.618)
The quick brown fox jumps over the lazy dog. 0123456789 ()[]{}<>+-=*/.
This paragraph contains normal English sentences to verify the Lilex monospace editor font and comfortable line height.

## Section 2: Markdown Soft-Wrap Long Line (I-8, I-13)
This is an intentionally long line of text designed to test markdown soft wrapping without any horizontal scrollbars appearing in the editor viewport. When soft-wrap is enabled in the editor, this entire logical sentence flows seamlessly across multiple visual rows on the screen. Clicking or navigating the cursor anywhere within this wrapped line must highlight all of its visual rows as a single continuous active line block.

## Section 3: Korean Body Text (I-14 Malgun Gothic Fallback)
다람쥐 헌 쳇바퀴에 타고파. 한국어 고딕 글꼴 대체 테스트입니다.
에디터 및 UI에서 한글이 굴림체 대신 맑은 고딕(Malgun Gothic)으로 바르게 렌더링되는지 확인합니다.
가나다라마바사 아자차카타파하 0123456789.

## Section 4: Code Block (I-14 Lilex 15px)
```rust
fn main() {
    let message = "Testing code block rendering in preview and editor";
    println!("{}", message);
}
```

## Section 5: Vertical Overflow Padding (I-9 Scrollbar)
Line 001: Padding for scrollbar overflow verification
Line 002: Padding for scrollbar overflow verification
Line 003: Padding for scrollbar overflow verification
Line 004: Padding for scrollbar overflow verification
Line 005: Padding for scrollbar overflow verification
Line 006: Padding for scrollbar overflow verification
Line 007: Padding for scrollbar overflow verification
Line 008: Padding for scrollbar overflow verification
Line 009: Padding for scrollbar overflow verification
Line 010: Padding for scrollbar overflow verification
Line 011: Padding for scrollbar overflow verification
Line 012: Padding for scrollbar overflow verification
Line 013: Padding for scrollbar overflow verification
Line 014: Padding for scrollbar overflow verification
Line 015: Padding for scrollbar overflow verification
Line 016: Padding for scrollbar overflow verification
Line 017: Padding for scrollbar overflow verification
Line 018: Padding for scrollbar overflow verification
Line 019: Padding for scrollbar overflow verification
Line 020: Padding for scrollbar overflow verification
Line 021: Padding for scrollbar overflow verification
Line 022: Padding for scrollbar overflow verification
Line 023: Padding for scrollbar overflow verification
Line 024: Padding for scrollbar overflow verification
Line 025: Padding for scrollbar overflow verification
Line 026: Padding for scrollbar overflow verification
Line 027: Padding for scrollbar overflow verification
Line 028: Padding for scrollbar overflow verification
Line 029: Padding for scrollbar overflow verification
Line 030: Padding for scrollbar overflow verification
Line 031: Padding for scrollbar overflow verification
Line 032: Padding for scrollbar overflow verification
Line 033: Padding for scrollbar overflow verification
Line 034: Padding for scrollbar overflow verification
Line 035: Padding for scrollbar overflow verification
Line 036: Padding for scrollbar overflow verification
Line 037: Padding for scrollbar overflow verification
Line 038: Padding for scrollbar overflow verification
Line 039: Padding for scrollbar overflow verification
Line 040: Padding for scrollbar overflow verification
Line 041: Padding for scrollbar overflow verification
Line 042: Padding for scrollbar overflow verification
Line 043: Padding for scrollbar overflow verification
Line 044: Padding for scrollbar overflow verification
Line 045: Padding for scrollbar overflow verification
Line 046: Padding for scrollbar overflow verification
Line 047: Padding for scrollbar overflow verification
Line 048: Padding for scrollbar overflow verification
Line 049: Padding for scrollbar overflow verification
Line 050: Padding for scrollbar overflow verification
Line 051: Padding for scrollbar overflow verification
Line 052: Padding for scrollbar overflow verification
Line 053: Padding for scrollbar overflow verification
Line 054: Padding for scrollbar overflow verification
Line 055: Padding for scrollbar overflow verification
Line 056: Padding for scrollbar overflow verification
Line 057: Padding for scrollbar overflow verification
Line 058: Padding for scrollbar overflow verification
Line 059: Padding for scrollbar overflow verification
Line 060: Padding for scrollbar overflow verification
Line 061: Padding for scrollbar overflow verification
Line 062: Padding for scrollbar overflow verification
Line 063: Padding for scrollbar overflow verification
Line 064: Padding for scrollbar overflow verification
Line 065: Padding for scrollbar overflow verification
Line 066: Padding for scrollbar overflow verification
Line 067: Padding for scrollbar overflow verification
Line 068: Padding for scrollbar overflow verification
Line 069: Padding for scrollbar overflow verification
Line 070: Padding for scrollbar overflow verification
Line 071: Padding for scrollbar overflow verification
Line 072: Padding for scrollbar overflow verification
Line 073: Padding for scrollbar overflow verification
Line 074: Padding for scrollbar overflow verification
Line 075: Padding for scrollbar overflow verification
Line 076: Padding for scrollbar overflow verification
Line 077: Padding for scrollbar overflow verification
Line 078: Padding for scrollbar overflow verification
Line 079: Padding for scrollbar overflow verification
Line 080: Padding for scrollbar overflow verification
Line 081: Padding for scrollbar overflow verification
Line 082: Padding for scrollbar overflow verification
Line 083: Padding for scrollbar overflow verification
Line 084: Padding for scrollbar overflow verification
Line 085: Padding for scrollbar overflow verification
Line 086: Padding for scrollbar overflow verification
Line 087: Padding for scrollbar overflow verification
Line 088: Padding for scrollbar overflow verification
Line 089: Padding for scrollbar overflow verification
Line 090: End of fixture file.
'@
    $fixtureText | Set-Content -LiteralPath $FixturePath -Encoding utf8
    L "Fixture created at $FixturePath"
} else {
    L "Using existing fixture at $FixturePath"
}

if (-not $FiveDigitFixturePath -or -not (Test-Path -LiteralPath $FiveDigitFixturePath)) {
    $FiveDigitFixturePath = Join-Path $Out 'order03-5digit-fixture.md'
    if (-not (Test-Path -LiteralPath $FiveDigitFixturePath)) {
        L "Generating 5-digit line fixture (10,050 lines) at $FiveDigitFixturePath..."
        $sb = [System.Text.StringBuilder]::new(400000)
        [void]$sb.AppendLine("# 5-Digit Line Number Verification Fixture (10,050 lines)")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("Section for verifying 5-digit line number column geometry (I-14).")
        for ($line = 4; $line -le 10050; $line++) {
            [void]$sb.AppendLine(("Line {0:D5}: padding line for five-digit gutter width verification" -f $line))
        }
        [System.IO.File]::WriteAllText($FiveDigitFixturePath, $sb.ToString(), [System.Text.Encoding]::UTF8)
        L "5-digit fixture created at $FiveDigitFixturePath"
    } else {
        L "Using existing 5-digit fixture at $FiveDigitFixturePath"
    }
} else {
    L "Using existing 5-digit fixture at $FiveDigitFixturePath"
}
} # end if (-not $DryRunStdout)

# ---------------------------------------------------------------------------
# 3. Helper Functions
# ---------------------------------------------------------------------------
function Ensure-Foreground([IntPtr]$hwnd, [string]$label) {
    [void][Order03Native]::SetForegroundWindow($hwnd)
    Start-Sleep -Milliseconds 300
    $fg = [Order03Native]::GetForegroundWindow()
    if ($fg -ne $hwnd) {
        [void][Order03Native]::ShowWindow($hwnd, 9) # SW_RESTORE
        [void][Order03Native]::SetForegroundWindow($hwnd)
        Start-Sleep -Milliseconds 300
        $fg = [Order03Native]::GetForegroundWindow()
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

    $cr = New-Object Order03Native+RECT
    [void][Order03Native]::GetClientRect($hwnd, [ref]$cr)
    $actualW = $cr.Right - $cr.Left
    $actualH = $cr.Bottom - $cr.Top
    L "Client size check: target=${expectedW}x${expectedH}, actual=${actualW}x${actualH}"

    if ($actualW -ne $expectedW -or $actualH -ne $expectedH) {
        L "Directly applying SetWindowPos to adjust to 1456x860..."
        [void][Order03Native]::SetWindowPos($hwnd, [IntPtr]::Zero, 232, 90, 1456, 860, 0x0004 -bor 0x0010)
        Start-Sleep -Milliseconds 600
        [void][Order03Native]::GetClientRect($hwnd, [ref]$cr)
        $actualW = $cr.Right - $cr.Left
        $actualH = $cr.Bottom - $cr.Top
        L "Re-checked client size: ${actualW}x${actualH}"
        if ($actualW -ne $expectedW -or $actualH -ne $expectedH) {
            Cap-Window $hwnd 'error-app-client-size' $Out
            throw "Window client size mismatch: expected ${expectedW}x${expectedH}, but got ${actualW}x${actualH}"
        }
    }
    L "Client size 1440x852 verified successfully."
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
            $b = [pscustomobject]@{
                name = $matches[1]
                x = [double]$matches[2]
                y = [double]$matches[3]
                w = [double]$matches[4]
                h = [double]$matches[5]
            }
            $boxes[$matches[1]] = $b
            $allBoxes.Add($b)
        }
    }
    return [pscustomobject]@{
        seq = $seq
        boxes = $boxes
        allBoxes = $allBoxes
        lines = $lines[$start..$end]
    }
}

function Assert-LayoutCondition([IntPtr]$hwnd, [string]$outDir, [string]$stepName, [scriptblock]$condition, [string]$failureMessage, [int]$maxAttempts = 25) {
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

    L "[$appOrZed] === Step '$stepKey': $stepTitle ==="
    try {
        & $action
        L "[$appOrZed] Step '$stepKey' ($stepTitle) -> PASS"
        $global:summary[$appOrZed][$stepKey] = "PASS"
    } catch {
        $errMsg = $_.Exception.Message
        L "[$appOrZed] ERROR in step '$stepKey': $errMsg"
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
    $pt = New-Object Order03Native+POINT
    if ($hwnd -ne [IntPtr]::Zero) {
        [void][Order03Native]::ClientToScreen($hwnd, [ref]$pt)
    }
    $sx = [int]($pt.X + $b.x + $b.w / 2)
    $sy = [int]($pt.Y + $b.y + $b.h / 2)
    return @{ X = $sx; Y = $sy; Box = $b }
}

function Get-TreeRowBoxByName([IntPtr]$hwnd, [string]$outDir, [string]$fileName, [string]$fixtureDir = '', [string]$overrideStdout = '') {
    $foundIndex = -1
    $reason = ''

    # 1. First, search app-stdout.txt for the latest [dev] tree ... rows= line
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
                        $reason = "stdout [dev] tree rows parsing (line $($i + 1), label='$($parts[0].Trim())')"
                        break
                    }
                }
                if ($foundIndex -ge 0) { break }
            }
        }
    }

    # 2. Fallback: if not found in stdout, calculate index based on sorted directory entries
    if ($foundIndex -lt 0 -and $fixtureDir -and (Test-Path -LiteralPath $fixtureDir)) {
        $dirItems = @(Get-ChildItem -LiteralPath $fixtureDir -Force | Sort-Object Name)
        $calcIndex = 1
        foreach ($item in $dirItems) {
            if ($item.Name -eq $fileName) {
                $foundIndex = $calcIndex
                $reason = "calculated sorting order from directory scan (index $calcIndex in $fixtureDir)"
                break
            }
            $calcIndex++
        }
    }

    # 3. Fallback: hardcoded known positions in order03 fixture
    if ($foundIndex -lt 0) {
        if ($fileName -like '*00-order03*') {
            $foundIndex = 3
            $reason = "hardcoded fallback position for 00-order03.md (after root, branch, .measure-marker)"
        } elseif ($fileName -like '*01-order03-5digit*') {
            $foundIndex = 4
            $reason = "hardcoded fallback position for 01-order03-5digit.md"
        }
    }

    if ($foundIndex -ge 0) {
        $targetBoxName = ("tree-row-{0:D2}" -f $foundIndex)
        L ("Tree row for '$fileName': index=$foundIndex, box=$targetBoxName (basis: $reason)")
        $coord = Get-BoxScreenCoord $hwnd $outDir $targetBoxName $overrideStdout
        if ($coord) { return @{ X = $coord.X; Y = $coord.Y; Box = $coord.Box; Index = $foundIndex; Reason = $reason } }
        $coord = Get-BoxScreenCoord $hwnd $outDir ("tree-content-{0:D2}" -f $foundIndex) $overrideStdout
        if ($coord) { return @{ X = $coord.X; Y = $coord.Y; Box = $coord.Box; Index = $foundIndex; Reason = $reason } }
        $coord = Get-BoxScreenCoord $hwnd $outDir ("tree-label-{0:D2}" -f $foundIndex) $overrideStdout
        if ($coord) { return @{ X = $coord.X; Y = $coord.Y; Box = $coord.Box; Index = $foundIndex; Reason = $reason } }
    } else {
        L ("Tree row for '$fileName': NOT FOUND in stdout or directory scan")
    }
    return $null
}

# ---------------------------------------------------------------------------
# 4. Our App Measurement (workbench-gpui)
# ---------------------------------------------------------------------------
function Run-AppMeasure {
    L "--- Starting workbench-gpui measurement ---"
    $appPid = $null
    $appHwnd = [IntPtr]::Zero
    $backupDir = Join-Path (Split-Path $Out -Parent) ('_' + (Split-Path $Out -Leaf) + '-backup')
    $editorCenterX = 0
    $editorCenterY = 0

    try {
        $appPrereqOk = $false
        try {
            # 1. Start Session
            L "Calling session.ps1 -Action Start..."
            & pwsh -NoProfile -File 'tools/measure/session.ps1' -Action Start -Out $Out -Exe $AppExe -Backup $backupDir -Json -FixtureFile $FixturePath
            
            $sessionFile = Join-Path $Out 'session.json'
            if (-not (Test-Path $sessionFile)) { throw "session.json not found after session start" }
            $session = Get-Content -Raw $sessionFile | ConvertFrom-Json
            $appPid = [uint32]$session.pid
            L "App launched PID=$appPid"

            # Copy 5-digit fixture into session fixture folder before opening project so it is indexed
            if ($session.PSObject.Properties['fixture'] -and (Test-Path -LiteralPath $session.fixture)) {
                Copy-Item -LiteralPath $FiveDigitFixturePath -Destination (Join-Path $session.fixture '01-order03-5digit.md') -Force
                L "Copied 5-digit fixture to $($session.fixture)\01-order03-5digit.md"
            }

            # 2. Wait for main window
            foreach ($i in 1..40) {
                Start-Sleep -Milliseconds 300
                $appHwnd = [Order03Native]::FindTitled($appPid, 'workbench-gpui')
                if ($appHwnd -ne [IntPtr]::Zero) { break }
            }
            if ($appHwnd -eq [IntPtr]::Zero) { throw "workbench-gpui main window not found for PID=$appPid" }
            L ("Found main window HWND=0x{0:X}" -f $appHwnd.ToInt64())

            # 3. Resize window to client 1440x852 (1456x860 window rect) & Verify
            Ensure-ClientSize $appHwnd 1440 852
            Ensure-Foreground $appHwnd "After resize"

            # 4. Project Open (트리 행 확인)
            L "Checking if project tree is already loaded or in empty state..."
            $initialSnap = Get-LatestSnapshot $Out
            if (-not ($initialSnap -and $initialSnap.boxes.Contains('tree-row-01'))) {
                # Check for project-empty-open button
                $emptyOpen = Get-BoxScreenCoord $appHwnd $Out 'project-empty-open'
                if ($emptyOpen) {
                    L "Found 'project-empty-open' button at ($($emptyOpen.X), $($emptyOpen.Y)). Clicking to load project..."
                    [Order03Native]::Click($emptyOpen.X, $emptyOpen.Y)
                } else {
                    L "Sending Ctrl-K Ctrl-O (workspace::Open) to load folder..."
                    [Order03Native]::KeyCombo(@([ushort]0x11), [ushort]0x4B) # Ctrl-K
                    Start-Sleep -Milliseconds 100
                    [Order03Native]::KeyCombo(@([ushort]0x11), [ushort]0x4F) # Ctrl-O
                }
                # Assert project opened: tree-row-01 must be present
                Assert-LayoutCondition $appHwnd $Out "project-open" { param($s) $s.boxes.Contains('tree-row-01') } "tree-row-01 must appear in layout dump after opening project"
            } else {
                L "Project tree already loaded (tree-row-01 present)."
            }

            # 5. Open Fixture File from tree: find by name '00-order03.md'
            L "Moving mouse away to dismiss any active tooltip before finding/clicking file..."
            [Order03Native]::MoveTo(5, 5)
            Start-Sleep -Milliseconds 400

            $fixtureDir = if ($session.PSObject.Properties['fixture']) { $session.fixture } else { '' }
            $treeRow = Get-TreeRowBoxByName $appHwnd $Out '00-order03.md' $fixtureDir
            if (-not $treeRow) {
                Cap-Window $appHwnd 'error-app-tree-row-missing' $Out
                throw "tree row for '00-order03.md' not found for clicking"
            }
            L "Double-clicking '00-order03.md' at screen coords ($($treeRow.X), $($treeRow.Y))..."
            [Order03Native]::DoubleClick($treeRow.X, $treeRow.Y)

            # Assert file open: active-item and toolbar-btn-preview (markdown toolbar) must appear
            Assert-LayoutCondition $appHwnd $Out "file-open" { param($s) $s.boxes.Contains('active-item') -and $s.boxes.Contains('toolbar-btn-preview') } "active-item and toolbar-btn-preview must be present after opening markdown fixture"
            L "Fixture file opened successfully in editor."

            # Measure Editor Center
            $cr = New-Object Order03Native+RECT
            [void][Order03Native]::GetClientRect($appHwnd, [ref]$cr)
            $pt = New-Object Order03Native+POINT
            [void][Order03Native]::ClientToScreen($appHwnd, [ref]$pt)
            $editorCenterX = $pt.X + [int]($cr.Right * 0.6)
            $editorCenterY = $pt.Y + [int]($cr.Bottom * 0.5)

            $appPrereqOk = $true
            $global:summary['app']['prerequisite'] = "PASS"
        } catch {
            $errMsg = $_.Exception.Message
            L "ERROR in app prerequisite: $errMsg"
            $global:summary['app']['prerequisite'] = "FAIL: $errMsg"
        }

        if (-not $appPrereqOk) {
            L "Skipping remainder of workbench-gpui measurements due to prerequisite failure."
            return
        }

        # -------------------------------------------------------------------
        # Step Definitions
        # -------------------------------------------------------------------
        $stepActions = [ordered]@{
            'S-1' = {
                Ensure-Foreground $appHwnd "S-1"
                [Order03Native]::Click($editorCenterX, $editorCenterY)
                Start-Sleep -Milliseconds 400
                Assert-LayoutCondition $appHwnd $Out "S-1-body" { param($s) $s.boxes.Contains('active-item') } "active-item must be present"
                Cap-Window $appHwnd 'app-S-1-body' $Out
            }
            'S-2-cursor-line' = {
                Ensure-Foreground $appHwnd "S-2"
                [Order03Native]::Click($editorCenterX, $editorCenterY)
                [Order03Native]::KeyCombo(@([ushort]0x11), [ushort]0x24) # Ctrl+Home
                Start-Sleep -Milliseconds 200
                [Order03Native]::KeyPress([ushort]0x28) # Down
                [Order03Native]::KeyPress([ushort]0x28) # Down
                Start-Sleep -Milliseconds 400
                $snapS2 = Assert-LayoutCondition $appHwnd $Out "S-2-cursor-line" { param($s) $s.boxes.Contains('active-item') } "active-item must be present"
                if ($snapS2 -and $snapS2.boxes.Contains('active-item')) {
                    $eBox = $snapS2.boxes['active-item']
                    L ("Editor bounds for S-2 (cursor line & gutter colors): x={0}, y={1}, w={2}, h={3} (gutter left={0})" -f $eBox.x, $eBox.y, $eBox.w, $eBox.h)
                }
                Cap-Window $appHwnd 'app-S-2-cursor-line' $Out
            }
            'S-2-cursor-softwrap' = {
                L "Navigating cursor to soft-wrapped long line..."
                foreach ($k in 1..8) { [Order03Native]::KeyPress([ushort]0x28); Start-Sleep -Milliseconds 80 }
                Start-Sleep -Milliseconds 400
                Assert-LayoutCondition $appHwnd $Out "S-2-cursor-softwrap" { param($s) $s.boxes.Contains('active-item') } "active-item must be present"
                Cap-Window $appHwnd 'app-S-2-cursor-softwrap' $Out
            }
            'S-3-single' = {
                Assert-LayoutCondition $appHwnd $Out "S-3-single" { param($s) $s.boxes.Contains('active-item') } "active-item must be present"
                Cap-Window $appHwnd 'app-S-3-single-pane' $Out
            }
            'S-3-split' = {
                L "Splitting pane right (via tab-btn-split menu or keyboard shortcut)..."
                $splitBtn = Get-BoxScreenCoord $appHwnd $Out 'tab-btn-split'
                $splitTriggered = $false

                if ($splitBtn) {
                    L "Clicking tab-btn-split at ($($splitBtn.X), $($splitBtn.Y)) to open split menu..."
                    [Order03Native]::Click($splitBtn.X, $splitBtn.Y)
                    Start-Sleep -Milliseconds 400

                    # Wait briefly for split menu to mount (ctx-menu-box)
                    $menuSnap = $null
                    for ($m = 1; $m -le 10; $m++) {
                        $menuSnap = Get-LatestSnapshot $Out
                        if ($menuSnap -and $menuSnap.boxes.Contains('ctx-menu-box')) { break }
                        Start-Sleep -Milliseconds 200
                    }

                    if ($menuSnap -and $menuSnap.boxes.Contains('ctx-menu-box')) {
                        L "Split menu opened (ctx-menu-box present). Finding 'Split Right' row (ctx-menu-row-0)..."
                        $splitRightRow = Get-BoxScreenCoord $appHwnd $Out 'ctx-menu-row-0'
                        if ($splitRightRow) {
                            L "Clicking 'Split Right' (ctx-menu-row-0) at ($($splitRightRow.X), $($splitRightRow.Y))..."
                            [Order03Native]::Click($splitRightRow.X, $splitRightRow.Y)
                            $splitTriggered = $true
                        } else {
                            L "ctx-menu-row-0 probe not found, sending Enter to select default first item..."
                            [Order03Native]::KeyPress([ushort]0x0D) # Enter
                            $splitTriggered = $true
                        }
                    } else {
                        L "ctx-menu-box not detected after button click, falling back to keyboard shortcut..."
                    }
                }

                if (-not $splitTriggered) {
                    L "Sending Split Right key chord (Ctrl-K Right)..."
                    [Order03Native]::KeyCombo(@([ushort]0x11), [ushort]0x4B) # Ctrl-K
                    Start-Sleep -Milliseconds 100
                    [Order03Native]::KeyPress([ushort]0x27) # Right
                    Start-Sleep -Milliseconds 400

                    $postKeySnap = Get-LatestSnapshot $Out
                    if (-not ($postKeySnap -and @($postKeySnap.allBoxes | Where-Object { $_.name -eq 'tab-bar' }).Count -ge 2)) {
                        L "Ctrl-K Right chord did not split pane; trying direct Ctrl+\ (0xDC)..."
                        [Order03Native]::KeyCombo(@([ushort]0x11), [ushort]0xDC) # Ctrl+\
                    }
                }

                # Assert split: tab-bar width decreases from full center width (900) to half (< 800) or appears multiple times
                Assert-LayoutCondition $appHwnd $Out "S-3-split" { param($s) $s.boxes.Contains('tab-bar') -and ($s.boxes['tab-bar'].w -lt 800 -or @($s.allBoxes | Where-Object { $_.name -eq 'tab-bar' }).Count -ge 2) } "tab-bar must split into pane (width < 800 or multiple tab-bars)"
                Cap-Window $appHwnd 'app-S-3-split-pane' $Out

                # 분할 닫기 (Ctrl+W)
                L "Closing split pane tab (Ctrl+W) to restore single pane..."
                Ensure-Foreground $appHwnd "S-3-close-split"
                [Order03Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl+W
                Start-Sleep -Milliseconds 400
                Assert-LayoutCondition $appHwnd $Out "S-3-restore-single" { param($s) $s.boxes.Contains('tab-bar') -and $s.boxes['tab-bar'].w -ge 800 } "pane must return to single tab-bar (width >= 800)"
            }
            'S-4' = {
                L "Navigating to Korean text section..."
                foreach ($k in 1..6) { [Order03Native]::KeyPress([ushort]0x28); Start-Sleep -Milliseconds 80 }
                Start-Sleep -Milliseconds 400
                Assert-LayoutCondition $appHwnd $Out "S-4-korean" { param($s) $s.boxes.Contains('active-item') } "active-item must be present"
                Cap-Window $appHwnd 'app-S-4-korean-body' $Out
            }
            'S-5-code' = {
                L "--- Step S-5-code: Markdown Preview Code Block in Single Pane ---"
                Ensure-Foreground $appHwnd "S-5-code"

                # 1. Ensure single pane
                $curSnap = Get-LatestSnapshot $Out
                if ($curSnap -and $curSnap.boxes.Contains('tab-bar') -and ($curSnap.boxes['tab-bar'].w -lt 800 -or @($curSnap.allBoxes | Where-Object { $_.name -eq 'tab-bar' }).Count -ge 2)) {
                    L "Detected split pane, closing split pane tab (Ctrl+W) to ensure single pane..."
                    [Order03Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl+W
                    Start-Sleep -Milliseconds 400
                }

                # 2. Ensure 00-order03.md is active
                $editorSnap = Get-LatestSnapshot $Out
                if (-not ($editorSnap -and $editorSnap.boxes.Contains('toolbar-btn-preview'))) {
                    L "toolbar-btn-preview absent, ensuring 00-order03.md is open..."
                    $fixtureDir = if ($session.PSObject.Properties['fixture']) { $session.fixture } else { '' }
                    $treeRow03 = Get-TreeRowBoxByName $appHwnd $Out '00-order03.md' $fixtureDir
                    if ($treeRow03) {
                        [Order03Native]::DoubleClick($treeRow03.X, $treeRow03.Y)
                        Start-Sleep -Milliseconds 400
                    }
                }

                # 3. Open Preview: click toolbar-btn-preview or send Ctrl+Shift+V
                $previewBtn = Get-BoxScreenCoord $appHwnd $Out 'toolbar-btn-preview'
                if ($previewBtn) {
                    L "Clicking toolbar-btn-preview at ($($previewBtn.X), $($previewBtn.Y)) to open preview in active pane..."
                    [Order03Native]::Click($previewBtn.X, $previewBtn.Y)
                } else {
                    L "Sending Ctrl+Shift+V to open markdown preview..."
                    [Order03Native]::KeyCombo(@([ushort]0x11, [ushort]0x10), [ushort]0x56) # Ctrl+Shift+V
                }

                # 4. Assert preview is open
                Assert-LayoutCondition $appHwnd $Out "S-5-preview" { param($s) (-not $s.boxes.Contains('toolbar-btn-preview')) -or ($s.boxes['toolbar-btn-preview'].x -lt 1000) } "preview tab active"
                Start-Sleep -Milliseconds 400

                # 5. Check if preview opened in a new split pane; if so, zoom it
                $splitSnap = Get-LatestSnapshot $Out
                if ($splitSnap -and $splitSnap.boxes.Contains('tab-bar') -and ($splitSnap.boxes['tab-bar'].w -lt 800 -or @($splitSnap.allBoxes | Where-Object { $_.name -eq 'tab-bar' }).Count -ge 2)) {
                    L "Preview opened in split pane; zooming preview pane to single view..."
                    $zoomBtn = Get-BoxScreenCoord $appHwnd $Out 'tab-btn-zoom'
                    if ($zoomBtn) {
                        [Order03Native]::Click($zoomBtn.X, $zoomBtn.Y)
                    } else {
                        [Order03Native]::KeyCombo(@([ushort]0x11), [ushort]0x4B) # Ctrl-K
                        Start-Sleep -Milliseconds 100
                        [Order03Native]::KeyPress([ushort]0x5A) # Z
                    }
                    Start-Sleep -Milliseconds 400
                }

                # 6. Scroll inside preview area to ensure Section 4 code block is fully in view
                $snapWa = Get-LatestSnapshot $Out
                $scrollTargetX = $editorCenterX
                $scrollTargetY = $editorCenterY
                if ($snapWa -and $snapWa.boxes.Contains('work-area')) {
                    $wa = $snapWa.boxes['work-area']
                    $pt = New-Object Order03Native+POINT
                    [void][Order03Native]::ClientToScreen($appHwnd, [ref]$pt)
                    $scrollTargetX = [int]($pt.X + $wa.x + $wa.w * 0.5)
                    $scrollTargetY = [int]($pt.Y + $wa.y + $wa.h * 0.5)
                }
                L "Hovering inside preview at ($scrollTargetX, $scrollTargetY) and wheeling down 4 ticks to center Section 4 code block..."
                [Order03Native]::MoveTo($scrollTargetX, $scrollTargetY)
                Start-Sleep -Milliseconds 200
                for ($w = 1; $w -le 4; $w++) {
                    [Order03Native]::Wheel($scrollTargetX, $scrollTargetY, -120)
                    Start-Sleep -Milliseconds 80
                }
                Start-Sleep -Milliseconds 500

                # 7. Capture code block view (save under both names for compatibility)
                Cap-Window $appHwnd 'app-S-5-code-block' $Out
                Cap-Window $appHwnd 'app-S-5-markdown-preview' $Out

                # 8. Close preview tab (Ctrl+W) to restore editor
                L "Closing markdown preview tab (Ctrl+W)..."
                [Order03Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl+W
                Assert-LayoutCondition $appHwnd $Out "S-5-restore-editor" { param($s) $s.boxes.Contains('toolbar-btn-preview') } "returned to markdown editor (toolbar-btn-preview present)"
            }
            'S-6-menu' = {
                L "Opening menu with F10..."
                [Order03Native]::KeyPress([ushort]0x79) # F10
                Assert-LayoutCondition $appHwnd $Out "S-6-menu-open" { param($s) $s.boxes.Contains('menu-box') } "menu-box must be present when menu is open"
                Cap-Window $appHwnd 'app-S-6-menu-open' $Out

                # 메뉴 닫기 (Escape)
                [Order03Native]::KeyPress([ushort]0x1B) # Escape
                Assert-LayoutCondition $appHwnd $Out "S-6-menu-close" { param($s) -not $s.boxes.Contains('menu-box') } "menu-box must be dismissed"
            }
            'S-6-tooltip' = {
                $tipTarget = Get-BoxScreenCoord $appHwnd $Out 'toolbar-btn-preview'
                if (-not $tipTarget) { $tipTarget = Get-BoxScreenCoord $appHwnd $Out 'app-menu-button' }
                if ($tipTarget) {
                    L "Hovering over $($tipTarget.Box.name) at ($($tipTarget.X), $($tipTarget.Y)) for tooltip..."
                    [Order03Native]::MoveTo($tipTarget.X, $tipTarget.Y)
                    Assert-LayoutCondition $appHwnd $Out "S-6-tooltip" { param($s) $s.boxes.Contains('tooltip-box') } "tooltip-box must appear on hover"
                    Cap-Window $appHwnd 'app-S-6-tooltip' $Out
                } else {
                    L "# 수동 필요: 툴팁 탐침 상자 미발견 (수동 호버 후 캡처)"
                }
                [Order03Native]::MoveTo(5, 5)
                Start-Sleep -Milliseconds 400
            }
            'S-7' = {
                [Order03Native]::Click($editorCenterX, $editorCenterY)
                [Order03Native]::KeyCombo(@([ushort]0x11), [ushort]0x24) # Ctrl+Home
                Start-Sleep -Milliseconds 400
                Assert-LayoutCondition $appHwnd $Out "S-7-softwrap" { param($s) $s.boxes.Contains('active-item') } "active-item must be present"
                Cap-Window $appHwnd 'app-S-7-softwrap-no-hscroll' $Out
            }
            'S-8' = {
                [Order03Native]::MoveTo(5, 5)
                Start-Sleep -Seconds 2
                Cap-Window $appHwnd 'app-S-8-scrollbar-outside' $Out

                L "Wheeling down 3 ticks inside editor..."
                [Order03Native]::MoveTo($editorCenterX, $editorCenterY)
                Start-Sleep -Milliseconds 200
                for ($k = 1; $k -le 3; $k++) {
                    [Order03Native]::Wheel($editorCenterX, $editorCenterY, -120)
                    Start-Sleep -Milliseconds 80
                }
                Cap-Window $appHwnd 'app-S-8-scrollbar-scrolling' $Out

                L "Waiting 4.2 seconds to verify no fade out..."
                Start-Sleep -Milliseconds 4200
                Cap-Window $appHwnd 'app-S-8-scrollbar-after-4s' $Out
            }
            'S-9-4digit' = {
                Ensure-Foreground $appHwnd "S-9 4-digit"
                [Order03Native]::Click($editorCenterX, $editorCenterY)
                [Order03Native]::KeyCombo(@([ushort]0x11), [ushort]0x24) # Ctrl+Home
                Start-Sleep -Milliseconds 400
                $snapS9_4 = Assert-LayoutCondition $appHwnd $Out "S-9-4digit" { param($s) $s.boxes.Contains('active-item') } "active-item must be present"
                if ($snapS9_4 -and $snapS9_4.boxes.Contains('active-item')) {
                    $eBox4 = $snapS9_4.boxes['active-item']
                    L ("Editor bounds for S-9 4-digit: x={0}, y={1}, w={2}, h={3} (editor left x={0})" -f $eBox4.x, $eBox4.y, $eBox4.w, $eBox4.h)
                }
                Cap-Window $appHwnd 'app-S-9-gutter-4digit' $Out
            }
            'S-9-5digit' = {
                L "--- Step S-9-5digit: Line Number 5-Digit Gutter Geometry (Single Pane) ---"
                Ensure-Foreground $appHwnd "S-9 5-digit"

                # 1. Ensure single pane
                $curSnap = Get-LatestSnapshot $Out
                if ($curSnap -and $curSnap.boxes.Contains('tab-bar') -and ($curSnap.boxes['tab-bar'].w -lt 800 -or @($curSnap.allBoxes | Where-Object { $_.name -eq 'tab-bar' }).Count -ge 2)) {
                    L "Detected split pane, closing split pane tab (Ctrl+W) to ensure single pane..."
                    [Order03Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl+W
                    Start-Sleep -Milliseconds 400
                }

                # 2. Dismiss any active tooltip
                [Order03Native]::MoveTo(5, 5)
                Start-Sleep -Milliseconds 300

                # 3. Find and double-click 01-order03-5digit.md
                L "Opening 5-digit fixture from tree: find by name '01-order03-5digit.md'..."
                $fixtureDir = if ($session.PSObject.Properties['fixture']) { $session.fixture } else { '' }
                $treeRow04 = Get-TreeRowBoxByName $appHwnd $Out '01-order03-5digit.md' $fixtureDir
                if ($treeRow04) {
                    L "Double-clicking '01-order03-5digit.md' at screen coords ($($treeRow04.X), $($treeRow04.Y))..."
                    [Order03Native]::DoubleClick($treeRow04.X, $treeRow04.Y)
                } else {
                    L "Warning: tree row for '01-order03-5digit.md' not found by name, attempting fallback to tree-row-04..."
                    $fallbackRow = Get-BoxScreenCoord $appHwnd $Out 'tree-row-04'
                    if ($fallbackRow) {
                        [Order03Native]::DoubleClick($fallbackRow.X, $fallbackRow.Y)
                    } else {
                        throw "Could not locate tree row for '01-order03-5digit.md'"
                    }
                }

                # 4. Assert 5-digit fixture open
                Assert-LayoutCondition $appHwnd $Out "S-9-5digit-open" { param($s) $s.boxes.Contains('active-item') } "active-item must be present after opening 5-digit fixture"

                # 5. Click inside active-item to ensure editor focus
                $activeCoord = Get-BoxScreenCoord $appHwnd $Out 'active-item'
                if ($activeCoord) {
                    L "Clicking inside active-item at ($($activeCoord.X), $($activeCoord.Y)) to guarantee editor focus..."
                    [Order03Native]::Click($activeCoord.X, $activeCoord.Y)
                } else {
                    L "Warning: active-item box not found in snapshot, using editor center..."
                    [Order03Native]::Click($editorCenterX, $editorCenterY)
                }
                Start-Sleep -Milliseconds 300

                # 6. Send Ctrl+End to move to end of document (10,050 lines)
                L "Navigating to end of 5-digit document (Ctrl+End)..."
                [Order03Native]::KeyCombo(@([ushort]0x11), [ushort]0x23) # Ctrl+End
                Start-Sleep -Milliseconds 600

                # 7. Confirm 5-digit document state and capture
                $snapS9_5end = Get-LatestSnapshot $Out
                if ($snapS9_5end -and $snapS9_5end.boxes.Contains('active-item')) {
                    $eBox5 = $snapS9_5end.boxes['active-item']
                    L ("Editor bounds for S-9 5-digit (single pane): x={0}, y={1}, w={2}, h={3} (editor left x={0})" -f $eBox5.x, $eBox5.y, $eBox5.w, $eBox5.h)
                }
                Cap-Window $appHwnd 'app-S-9-gutter-5digit' $Out

                # 8. Close 5-digit tab (Ctrl+W) to restore editor state
                L "Closing 5-digit tab (Ctrl+W)..."
                [Order03Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl+W
                Start-Sleep -Milliseconds 400
            }
        }

        $stepTitles = @{
            'S-1' = 'Editor Body Font & Line Height'
            'S-2-cursor-line' = 'Cursor Line Highlight & Gutter Colors'
            'S-2-cursor-softwrap' = 'Soft-Wrapped Long Line Cursor Highlight'
            'S-3-single' = 'Single Pane State'
            'S-3-split' = 'Pane Border & Split Right'
            'S-4' = 'Korean Body Text'
            'S-5' = 'Markdown Preview'
            'S-5-code' = 'Markdown Preview Code Block (I-14)'
            'S-6-menu' = 'UI Shell Menu (F10)'
            'S-6-tooltip' = 'Tooltip on Toolbar Button'
            'S-7' = 'Markdown Soft-Wrap & No Horizontal Scrollbar'
            'S-8' = 'Vertical Scrollbar Always Visible'
            'S-9-4digit' = 'Line Number 4-Digit Gutter Geometry'
            'S-9-5digit' = 'Line Number 5-Digit Gutter Geometry'
        }

        # Determine steps to execute
        $stepsToRun = [System.Collections.Generic.List[string]]::new()
        if ($normalizedSteps.Count -gt 0) {
            foreach ($item in $Steps) {
                foreach ($sub in ($item -split ',')) {
                    $t = $sub.Trim()
                    if ($t -eq 'S-5') { $t = 'S-5-code' }
                    if ($stepActions.Contains($t) -and -not $stepsToRun.Contains($t)) {
                        $stepsToRun.Add($t)
                    } elseif ($t -eq 'S-9') {
                        if (-not $stepsToRun.Contains('S-9-4digit')) { $stepsToRun.Add('S-9-4digit') }
                        if (-not $stepsToRun.Contains('S-9-5digit')) { $stepsToRun.Add('S-9-5digit') }
                    }
                }
            }
        } else {
            foreach ($k in $stepActions.Keys) {
                $stepsToRun.Add($k)
            }
        }

        L ("Steps selected for execution: " + ($stepsToRun -join ', '))
        foreach ($stepKey in $stepsToRun) {
            $title = if ($stepTitles.ContainsKey($stepKey)) { $stepTitles[$stepKey] } else { $stepKey }
            Invoke-MeasureStep 'app' $stepKey $title $stepActions[$stepKey]
        }

    } finally {
        # 프로세스 정리: 자신이 띄운 PID만 닫고, session Stop 호출
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
# 5. Zed Measurement (Zed.exe)
# ---------------------------------------------------------------------------
function Run-ZedMeasure {
    if ($normalizedSteps.Count -gt 0) {
        L "Notice: -Steps mode active, skipping Zed measurement entirely."
        return
    }
    L "--- Starting Zed measurement ---"
    # C-12: 실행 전에 Zed 프로세스들의 최상위 창 HWND 목록을 저장
    $zedPidsBefore = [uint32[]]@(Get-Process -Name Zed -ErrorAction SilentlyContinue | ForEach-Object { [uint32]$_.Id })
    $beforeHwnds = @()
    if ($zedPidsBefore.Count -gt 0) {
        $beforeHwnds = [Order03Native]::GetProcessTopLevelWindows($zedPidsBefore)
    }
    L ("Zed top-level HWNDs before launch: " + (($beforeHwnds | ForEach-Object { '0x{0:X}' -f $_.ToInt64() }) -join ', '))

    $zedHwnd = [IntPtr]::Zero
    $zex = 0
    $zey = 0
    $zo = New-Object Order03Native+POINT

    try {
        $zedPrereqOk = $false
        try {
            # C-12, C-15: 실행: C:\Users\nampl\AppData\Local\Programs\Zed\bin\zed.exe -n "<파일>" (새 창)
            # C-15: 사용자 창 탭 추가 사고 방지: 반드시 -n으로 연 자기 창에만 파일을 연다 (-a 금지).
            # 초기 실행 시 4자리 픽스처와 5자리 픽스처를 함께 열어 같은 창의 탭으로 둔다.
            L "Launching Zed (new window): $ZedExe -n `"$FixturePath`" `"$FiveDigitFixturePath`""
            Start-Process -FilePath $ZedExe -ArgumentList @('-n', "`"$FixturePath`"", "`"$FiveDigitFixturePath`"")

            # C-12: 실행 뒤 새로 생긴 HWND만 대상 창으로 쓴다 (프로세스 ID가 아니라 창 기준)
            foreach ($i in 1..60) {
                Start-Sleep -Milliseconds 500
                $currentPids = [uint32[]]@(Get-Process -Name Zed -ErrorAction SilentlyContinue | ForEach-Object { [uint32]$_.Id })
                if ($currentPids.Count -eq 0) { continue }
                $currentHwnds = [Order03Native]::GetProcessTopLevelWindows($currentPids)
                $newHwnds = @($currentHwnds | Where-Object { $beforeHwnds -notcontains $_ })
                if ($newHwnds.Count -gt 0) {
                    $zedHwnd = $newHwnds[0]
                    break
                }
            }
            if ($zedHwnd -eq [IntPtr]::Zero) {
                L "ERROR: Newly created Zed window HWND not found after launch."
                throw "Newly created Zed window not found"
            }
            L ("New Zed window found: HWND=0x{0:X}" -f $zedHwnd.ToInt64())
            Start-Sleep -Seconds 3

            # C-12: window-rect.ps1 -TargetHwnd를 쓰려면 -ProcessName Zed도 넘긴다
            L "Resizing Zed to 1440x852 client..."
            & pwsh -NoProfile -File 'tools/measure/window-rect.ps1' -ProcessName Zed -TargetHwnd ("0x{0:X}" -f $zedHwnd.ToInt64()) -Action Resize -X 232 -Y 90 -Width 1456 -Height 860 2>&1 | ForEach-Object { L "Zed resize: $_" }
            Start-Sleep -Seconds 2

            $zr = New-Object Order03Native+RECT
            [void][Order03Native]::GetClientRect($zedHwnd, [ref]$zr)
            [void][Order03Native]::ClientToScreen($zedHwnd, [ref]$zo)
            L "Zed client origin=($($zo.X),$($zo.Y)) size=$($zr.Right)x$($zr.Bottom)"
            $zex = $zo.X + [int]($zr.Right * 0.6)
            $zey = $zo.Y + [int]($zr.Bottom * 0.5)

            $zedPrereqOk = $true
            $global:summary['zed']['prerequisite'] = "PASS"

            # C-15: 시작 시 Tab 1 (4자리 픽스처) 활성화
            Ensure-Foreground $zedHwnd "Zed Tab 1 activate"
            [Order03Native]::KeyCombo(@([ushort]0x12), [ushort]0x31) # Alt+1
            Start-Sleep -Milliseconds 400
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
        # Zed S-1: 본문 글꼴 및 줄높이
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'S-1' 'Editor Body' {
            Ensure-Foreground $zedHwnd "Zed S-1"
            [Order03Native]::Click($zex, $zey)
            Start-Sleep -Milliseconds 500
            Cap-Window $zedHwnd 'zed-S-1-body' $Out
        }

        # -------------------------------------------------------------------
        # Zed S-2: 커서 줄 강조 및 줄 번호 색 (I-13)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'S-2-cursor-line' 'Cursor Line Highlight & Gutter Colors' {
            Ensure-Foreground $zedHwnd "Zed S-2"
            [Order03Native]::Click($zex, $zey)
            [Order03Native]::KeyCombo(@([ushort]0x11), [ushort]0x24) # Ctrl+Home
            Start-Sleep -Milliseconds 200
            [Order03Native]::KeyPress([ushort]0x28) # Down
            [Order03Native]::KeyPress([ushort]0x28) # Down
            Start-Sleep -Milliseconds 400
            L ("Editor left edge for Zed S-2: client x=0, screen x={0}" -f $zo.X)
            Cap-Window $zedHwnd 'zed-S-2-cursor-line' $Out
        }

        Invoke-MeasureStep 'zed' 'S-2-cursor-softwrap' 'Soft-Wrapped Long Line Cursor' {
            L "Moving to soft-wrapped line in Zed..."
            foreach ($k in 1..8) { [Order03Native]::KeyPress([ushort]0x28); Start-Sleep -Milliseconds 80 }
            Start-Sleep -Milliseconds 500
            Cap-Window $zedHwnd 'zed-S-2-cursor-softwrap' $Out
        }

        # -------------------------------------------------------------------
        # Zed S-3: 단일 pane 및 분할 (Ctrl+\)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'S-3-single' 'Single Pane' {
            Cap-Window $zedHwnd 'zed-S-3-single-pane' $Out
        }

        Invoke-MeasureStep 'zed' 'S-3-split' 'Pane Border & Split (Ctrl+\)' {
            L "Splitting right in Zed (Ctrl+\)..."
            [Order03Native]::KeyCombo(@([ushort]0x11), [ushort]0xDC) # Ctrl+\
            Start-Sleep -Seconds 1
            Cap-Window $zedHwnd 'zed-S-3-split-pane' $Out

            # 분할 탭 닫기
            [Order03Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl+W
            Start-Sleep -Milliseconds 600
        }

        # -------------------------------------------------------------------
        # Zed S-4: 한글 본문
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'S-4' 'Korean Body' {
            foreach ($k in 1..6) { [Order03Native]::KeyPress([ushort]0x28); Start-Sleep -Milliseconds 80 }
            Start-Sleep -Milliseconds 500
            Cap-Window $zedHwnd 'zed-S-4-korean-body' $Out
        }

        # -------------------------------------------------------------------
        # Zed S-5: 미리보기 (Ctrl+Shift+V)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'S-5' 'Markdown Preview (Ctrl+Shift+V)' {
            [Order03Native]::KeyCombo(@([ushort]0x11, [ushort]0x10), [ushort]0x56) # Ctrl+Shift+V
            Start-Sleep -Seconds 2
            Cap-Window $zedHwnd 'zed-S-5-markdown-preview' $Out

            # 미리보기 닫기
            [Order03Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl+W
            Start-Sleep -Milliseconds 600
        }

        # -------------------------------------------------------------------
        # Zed S-8: 세로 스크롤바 (밖 2s -> 휠 -> 4.2s 대기)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'S-8' 'Scrollbar Always Visible' {
            [Order03Native]::MoveTo(5, 5)
            Start-Sleep -Seconds 2
            Cap-Window $zedHwnd 'zed-S-8-scrollbar-outside' $Out

            L "Wheeling inside Zed editor..."
            [Order03Native]::MoveTo($zex, $zey)
            Start-Sleep -Milliseconds 200
            for ($k = 1; $k -le 3; $k++) {
                [Order03Native]::Wheel($zex, $zey, -120)
                Start-Sleep -Milliseconds 80
            }
            Cap-Window $zedHwnd 'zed-S-8-scrollbar-scrolling' $Out

            L "Waiting 4.2s for Zed scrollbar after-4s check..."
            Start-Sleep -Milliseconds 4200
            Cap-Window $zedHwnd 'zed-S-8-scrollbar-after-4s' $Out
        }

        # -------------------------------------------------------------------
        # Zed S-9: 줄 번호 열 너비 및 여백 (I-14: 4자리 이하 및 5자리 문서)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'zed' 'S-9-4digit' 'Line Number 4-Digit Gutter Geometry' {
            Ensure-Foreground $zedHwnd "Zed S-9 4-digit"
            [Order03Native]::Click($zex, $zey)
            [Order03Native]::KeyCombo(@([ushort]0x11), [ushort]0x24) # Ctrl+Home
            Start-Sleep -Milliseconds 400
            L ("Editor left edge for Zed S-9 4-digit: client x=0, screen x={0}" -f $zo.X)
            Cap-Window $zedHwnd 'zed-S-9-gutter-4digit' $Out
        }

        Invoke-MeasureStep 'zed' 'S-9-5digit' 'Line Number 5-Digit Gutter Geometry' {
            # C-15: -a 금지. -n으로 함께 연 자기 창 안에서 5자리 탭(Tab 2)으로 전환한다.
            L "Switching to 5-digit fixture tab in Zed (Alt+2, within measurement window, -a forbidden)..."
            Ensure-Foreground $zedHwnd "Zed S-9 5-digit"
            [Order03Native]::KeyCombo(@([ushort]0x12), [ushort]0x32) # Alt+2
            Start-Sleep -Milliseconds 600
            [Order03Native]::Click($zex, $zey)
            L "Moving to end of 5-digit document in Zed (Ctrl+End)..."
            [Order03Native]::KeyCombo(@([ushort]0x11), [ushort]0x23) # Ctrl+End
            Start-Sleep -Milliseconds 600
            L ("Editor left edge for Zed S-9 5-digit: client x=0, screen x={0}" -f $zo.X)
            Cap-Window $zedHwnd 'zed-S-9-gutter-5digit' $Out

            # Switch back to Tab 1 (Alt+1)
            L "Switching back to Tab 1 in Zed (Alt+1)..."
            [Order03Native]::KeyCombo(@([ushort]0x12), [ushort]0x31) # Alt+1
            Start-Sleep -Milliseconds 500
        }

    } finally {
        # C-12: 그 HWND에만 WM_CLOSE(PostMessage)를 보낸다.
        # Zed 프로세스를 Kill·Stop-Process·CloseMainWindow 하지 않는다 (사용자 창 보호).
        if ($zedHwnd -ne [IntPtr]::Zero) {
            L ("Closing target Zed window only (HWND=0x{0:X}) via WM_CLOSE PostMessage..." -f $zedHwnd.ToInt64())
            [void][Order03Native]::PostMessage($zedHwnd, [Order03Native]::WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
            Start-Sleep -Seconds 2

            # 닫은 뒤 그 HWND가 사라졌는지만 로그에 적는다.
            $stillAlive = [Order03Native]::IsWindow($zedHwnd)
            if ($stillAlive) {
                # 저장 확인 대화상자가 뜨면 닫지 말고 로그에 남긴다
                L ("Warning: Target Zed window HWND=0x{0:X} is still present (save confirmation dialog or close pending; not killing process)" -f $zedHwnd.ToInt64())
            } else {
                L ("Target Zed window HWND=0x{0:X} successfully closed (window no longer exists)" -f $zedHwnd.ToInt64())
            }
        } else {
            L "No target Zed window to close (HWND is Zero)."
        }
    }
}

# ---------------------------------------------------------------------------
# 5A. DryRun Mode
# ---------------------------------------------------------------------------
function Run-DryRun([string]$dumpPath) {
    L "=== DryRun Mode: Parsing target files and probes from dump '$dumpPath' ==="
    $resolvedPath = [System.IO.Path]::GetFullPath($dumpPath, (Get-Location).Path)
    if (-not (Test-Path -LiteralPath $resolvedPath)) {
        throw "DryRunStdout file not found: $resolvedPath"
    }

    $targets = @('00-order03.md', '01-order03-5digit.md')
    foreach ($fn in $targets) {
        L "----------------------------------------"
        L "Checking target: $fn"
        $res = Get-TreeRowBoxByName ([IntPtr]::Zero) '' $fn '' $resolvedPath
        if ($res) {
            $b = $res.Box
            L "Result for '$fn':"
            L "  Row Index : $($res.Index)"
            L "  Box Name  : $($b.name)"
            L "  Bounds    : x=$($b.x), y=$($b.y), w=$($b.w), h=$($b.h)"
            L "  Coords    : X=$($res.X), Y=$($res.Y) (client center)"
            L "  Basis     : $($res.Reason)"
        } else {
            L "Result for '$fn': NOT FOUND"
        }
    }

    # Check active-item probe (for S-9-5digit editor click)
    L "----------------------------------------"
    L "Checking active-item probe (for S-9-5digit focus click)"
    $activeCoord = Get-BoxScreenCoord ([IntPtr]::Zero) '' 'active-item' $resolvedPath
    if ($activeCoord) {
        $b = $activeCoord.Box
        L "Result for 'active-item':"
        L "  Box Name  : $($b.name)"
        L "  Bounds    : x=$($b.x), y=$($b.y), w=$($b.w), h=$($b.h)"
        L "  Coords    : X=$($activeCoord.X), Y=$($activeCoord.Y) (client center)"
    } else {
        L "Result for 'active-item': NOT PRESENT in dump"
    }

    # Check toolbar-btn-preview probe (for S-5-code preview click)
    L "----------------------------------------"
    L "Checking toolbar-btn-preview probe (for S-5-code preview click)"
    $prevBtn = Get-BoxScreenCoord ([IntPtr]::Zero) '' 'toolbar-btn-preview' $resolvedPath
    if ($prevBtn) {
        $b = $prevBtn.Box
        L "Result for 'toolbar-btn-preview':"
        L "  Box Name  : $($b.name)"
        L "  Bounds    : x=$($b.x), y=$($b.y), w=$($b.w), h=$($b.h)"
        L "  Coords    : X=$($prevBtn.X), Y=$($prevBtn.Y) (client center)"
    } else {
        L "Result for 'toolbar-btn-preview': NOT PRESENT in dump"
    }

    # Check work-area probe (for S-5-code preview scroll)
    L "----------------------------------------"
    L "Checking work-area probe (for S-5-code preview scroll)"
    $waCoord = Get-BoxScreenCoord ([IntPtr]::Zero) '' 'work-area' $resolvedPath
    if ($waCoord) {
        $b = $waCoord.Box
        L "Result for 'work-area':"
        L "  Box Name  : $($b.name)"
        L "  Bounds    : x=$($b.x), y=$($b.y), w=$($b.w), h=$($b.h)"
        L "  Coords    : X=$($waCoord.X), Y=$($waCoord.Y) (client center)"
    } else {
        L "Result for 'work-area': NOT PRESENT in dump"
    }

    # Check split menu probe (ctx-menu-row-0) in dump if present
    L "----------------------------------------"
    L "Checking split menu probe: ctx-menu-row-0"
    $splitRow = Get-BoxScreenCoord ([IntPtr]::Zero) '' 'ctx-menu-row-0' $resolvedPath
    if ($splitRow) {
        $b = $splitRow.Box
        L "Result for 'ctx-menu-row-0':"
        L "  Box Name  : $($b.name)"
        L "  Bounds    : x=$($b.x), y=$($b.y), w=$($b.w), h=$($b.h)"
        L "  Coords    : X=$($splitRow.X), Y=$($splitRow.Y) (client center)"
    } else {
        L "Result for 'ctx-menu-row-0': NOT PRESENT in dump"
    }

    # Verification of -Steps parsing logic in dry-run
    L "----------------------------------------"
    L "Checking -Steps mode verification:"
    L "  Normalized Steps: $(($normalizedSteps) -join ', ')"
    L "  Only parameter  : $Only"
    L "  Zed will run?   : $(if ($normalizedSteps.Count -eq 0 -and ($Only -eq 'Zed' -or $Only -eq 'Both')) { 'YES' } else { 'NO (Zed is skipped)' })"
    L "----------------------------------------"
    L "=== DryRun Complete ==="
}

# ---------------------------------------------------------------------------
# 6. Main Execution
# ---------------------------------------------------------------------------
if ($MyInvocation.InvocationName -ne '.') {
    if ($DryRunStdout) {
        Run-DryRun $DryRunStdout
        return
    }
    try {
        # Copy run5 valid captures if skipped
        if ($normalizedSkip.Count -gt 0) {
            $run5Dir = Join-Path (Split-Path $Out -Parent) 'measure-ORDER-03-run5-aborted'
            if (Test-Path -LiteralPath $run5Dir) {
                $run5Files = @('app-S-1-body.png', 'app-S-2-cursor-line.png', 'app-S-2-cursor-softwrap.png', 'app-S-3-single-pane.png')
                foreach ($fn in $run5Files) {
                    $src = Join-Path $run5Dir $fn
                    $dst = Join-Path $Out $fn
                    if ((Test-Path -LiteralPath $src) -and (-not (Test-Path -LiteralPath $dst))) {
                        Copy-Item -LiteralPath $src -Destination $dst -Force
                        L "Copied run5 valid capture $fn to $Out"
                    }
                }
            }
        }

        if ($Only -eq 'App' -or $Only -eq 'Both') {
            Run-AppMeasure
        }
        if ($normalizedSteps.Count -eq 0 -and ($Only -eq 'Zed' -or $Only -eq 'Both')) {
            Run-ZedMeasure
        }
        L "=== ORDER-03 V3 Capture Script Finished ==="
    } catch {
        L "FATAL ERROR: $($_.Exception.Message)"
        L "$($_.ScriptStackTrace)"
    } finally {
        $summaryFile = Join-Path $Out 'summary.json'
        $summaryJson = $global:summary | ConvertTo-Json -Depth 5
        $summaryJson | Set-Content -LiteralPath $summaryFile -Encoding utf8
        L "=== Execution Summary ==="
        L $summaryJson
    }
}

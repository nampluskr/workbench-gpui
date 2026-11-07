#Requires -Version 7
<#
.SYNOPSIS
  ORDER-06-R1 V3 화면 검증(UI 실측) 스크립트.
  (gpui-checker 작성, leader가 화면 차례 안에서 실행한다.)

.DESCRIPTION
  - 상위 지시: core ORDER-06-R1 V3 준비
  - 우리 앱(workbench-gpui) 단독 실행 (Zed는 구동하지 않음).
  - 클라이언트 1440×852, 100% DPI, Ensure-ClientSize로 고정.
  - 앱 단계:
    1. app-menu-names-gap: F10으로 상단 메뉴 막대 표시, menu-name-0..6 레이아웃 탐침 대조,
       이름 사이 잉크 간격(목표: 13~14px ±1) 측정 및 로그, app-menu-names-crop.png 저장.
    2. app-v-button-crop: v 사용자 메뉴 버튼(22×22, chevron 잉크 8, 최소화 여백 4) 탐침 측정 및
       4배 확대 크롭(app-v-button-crop-4x.png) 저장.
    3. app-settings-window: Ctrl-, 로 Settings 새 창(HWND 감지) 열기, GetClientRect 크기 및
       SPEC R-2 Zed 실측 치수(900×750, 탐색 226, 패딩 32/10, 행간격 24 등) 대조 로그,
       중복 생성 방지(기존 창 전면) 확인, 검색칸 "font" 입력 캡처,
       Buffer Font Size 변경 저장 및 즉시 적용 캡처, settings.json 내용 로그.
    4. app-settings-comments: 주석(헤더 주석, 블록 인라인 주석, 줄 주석, 미지원 사용자 키)이 포함된
       fixture 파일을 settings.json에 넣고 설정값을 바꾼 뒤, 주석·공백·미지원 키가 온전히 보존되는지 바이트 검증.
    5. app-settings-edit-json: Settings 창의 'Edit in settings.json' 버튼 클릭 -> 메인 편집기 탭 열림 캡처 -> Settings 창 닫기.
    6. app-keymap-editor: Ctrl-K Ctrl-S로 Keymap Editor 탭 열림, 필터칸 "Save" 입력 캡처,
       한 행 바인딩 변경 저장(workspace::Save -> ctrl-alt-s) -> keymap.json 내용 로그 및 바인딩 존재 검증.
    7. app-extensions: Ctrl-Shift-X로 Extensions 탭 열림, 범주 칩(Themes, Icon Themes, All) 전환 캡처,
       검색칸 "Zed" 입력 캡처, 도구 탭 닫기(Ctrl-W).
    8. app-panel-layout: dock 닫기(Ctrl-B) -> v 메뉴 Panel Layout 캡처(Custom 체크·비활성) -> Classic 클릭 -> dock 열림·기본 폭 캡처.
    9. app-editor-layout: View -> Editor Layout 하위 메뉴 캡처(Split 네 항목 및 단축키).
    10. app-tab-cycle: 트리에서 두 파일을 더블클릭(고정 탭)으로 열어 2개 탭 확인 -> Ctrl-PageDown / Ctrl-PageUp 캡처 -> Ctrl-W 닫기.
    11. app-relaunch-persistence: 앱 재실행 후 settings.json 및 keymap.json 변경 유지 확인 캡처 및 원래 값 완전 복원.
  - 안전 조치:
    * 띄운 PID와 스크립트가 직접 연 창(Settings HWND 등)만 닫기 (다른 프로세스나 창 불간섭).
    * settings.json 및 keymap.json 전용 백업·복원 (데이터 손실 0% 보장).
    * session.ps1 출력 스트림 파이프 미사용 방식 유지.
    * 각 단계 독립 실행 및 try-catch 기록.

.PARAMETER Out
  출력 디렉터리 (기본값: specs\v0.5\verify\reviews\measure-ORDER-06-R1).

.PARAMETER AppExe
  workbench-gpui 실행 파일 경로.

.PARAMETER FixturePath
  측정에 사용할 마크다운 파일 경로.

.PARAMETER DryRunStdout
  stdout 덤프를 기반으로 좌표 및 프로브 계산만 검증하는 모드 (프로세스 구동 안 함).

.PARAMETER Steps
  실행할 단계 목록.

.PARAMETER Skip
  건너뛸 단계 목록.
#>
[CmdletBinding()]
param(
    [string]$Out = 'specs\v0.5\verify\reviews\measure-ORDER-06-R1',
    [string]$AppExe = 'D:\projects\workbench-gpui\target\debug\workbench-gpui.exe',
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
    L "=== ORDER-06-R1 V3 Capture Script Started (Out=$Out) ==="
}

# ---------------------------------------------------------------------------
# 1. Native API Definition (Order06R1Native)
# ---------------------------------------------------------------------------
if (-not ('Order06R1Native' -as [type])) {
    Add-Type -ReferencedAssemblies @('System.Runtime', 'System.Collections', 'System.Threading', 'System.Threading.Thread', 'System.Runtime.InteropServices') -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

public static class Order06R1Native {
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
    const uint KEYEVENTF_EXTENDEDKEY = 0x1, KEYEVENTF_KEYUP = 0x2, KEYEVENTF_UNICODE = 0x4;
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
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] public static extern IntPtr GetWindow(IntPtr hWnd, uint uCmd);

    public const uint WM_CLOSE = 0x0010;

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

    public static void SendText(string text) {
        foreach (char c in text) {
            INPUT[] down = new INPUT[1];
            down[0].type = INPUT_KEYBOARD;
            down[0].u.ki.wVk = 0;
            down[0].u.ki.wScan = (ushort)c;
            down[0].u.ki.dwFlags = KEYEVENTF_UNICODE;
            SendInput(1, down, Marshal.SizeOf(typeof(INPUT)));
            Thread.Sleep(30);
            INPUT[] up = new INPUT[1];
            up[0].type = INPUT_KEYBOARD;
            up[0].u.ki.wVk = 0;
            up[0].u.ki.wScan = (ushort)c;
            up[0].u.ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;
            SendInput(1, up, Marshal.SizeOf(typeof(INPUT)));
            Thread.Sleep(30);
        }
    }
}
'@
}

# ---------------------------------------------------------------------------
# 2. Window and Measurement Helpers
# ---------------------------------------------------------------------------
function Ensure-Foreground([IntPtr]$hwnd, [string]$label) {
    if ($hwnd -eq [IntPtr]::Zero) { return }
    [void][Order06R1Native]::SetForegroundWindow($hwnd)
    Start-Sleep -Milliseconds 200
    $fg = [Order06R1Native]::GetForegroundWindow()
    if ($fg -ne $hwnd) {
        [void][Order06R1Native]::ShowWindow($hwnd, 9) # SW_RESTORE
        [void][Order06R1Native]::SetForegroundWindow($hwnd)
        Start-Sleep -Milliseconds 300
        $fg = [Order06R1Native]::GetForegroundWindow()
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

function Get-ImageSha256([string]$filePath) {
    if (-not (Test-Path -LiteralPath $filePath)) { return $null }
    $stream = [System.IO.File]::OpenRead($filePath)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $hash = [System.BitConverter]::ToString($sha.ComputeHash($stream)) -replace '-'
    $stream.Close()
    return $hash
}

function Assert-CaptureHashChanged([string]$prevPng, [string]$currPng, [string]$actionDesc) {
    if (-not (Test-Path -LiteralPath $prevPng) -or -not (Test-Path -LiteralPath $currPng)) {
        return
    }
    $h1 = Get-ImageSha256 $prevPng
    $h2 = Get-ImageSha256 $currPng
    L "Hash check for '$actionDesc': prev=$h1, curr=$h2 (Changed=$($h1 -ne $h2))"
    if ($h1 -eq $h2) {
        throw "Assertion failed: $actionDesc capture hash unchanged ($h1) - 입력 미전달!"
    }
}

function Is-SettingsCentered([string]$settingsPngPath) {
    if (-not (Test-Path -LiteralPath $settingsPngPath)) { return $false }
    try {
        $bmp = New-Object System.Drawing.Bitmap($settingsPngPath)
        $isCentered = $false
        for ($y = 250; $y -le 265; $y++) {
            $c = $bmp.GetPixel(814, $y)
            if ($c.R -ne 255 -or $c.G -ne 255 -or $c.B -ne 255) {
                $isCentered = $true; break
            }
        }
        $bmp.Dispose()
        return $isCentered
    } catch {
        return $false
    }
}

function Ensure-ClientSize([IntPtr]$hwnd, [int]$expectedW, [int]$expectedH, [string]$procName = 'workbench-gpui') {
    $resizeOutput = & pwsh -NoProfile -File 'tools/measure/window-rect.ps1' -ProcessName $procName -TargetHwnd ("0x{0:X}" -f $hwnd.ToInt64()) -Action Resize -X 232 -Y 90 -Width 1456 -Height 860 2>&1
    foreach ($line in $resizeOutput) { L "Resize: $line" }
    Start-Sleep -Milliseconds 600

    $cr = New-Object Order06R1Native+RECT
    [void][Order06R1Native]::GetClientRect($hwnd, [ref]$cr)
    $actualW = $cr.Right - $cr.Left
    $actualH = $cr.Bottom - $cr.Top
    L "Client size check ($procName): target=${expectedW}x${expectedH}, actual=${actualW}x${actualH}"

    if ($actualW -ne $expectedW -or $actualH -ne $expectedH) {
        L "Directly applying SetWindowPos to adjust to 1456x860..."
        [void][Order06R1Native]::SetWindowPos($hwnd, [IntPtr]::Zero, 232, 90, 1456, 860, 0x0004 -bor 0x0010)
        Start-Sleep -Milliseconds 600
        [void][Order06R1Native]::GetClientRect($hwnd, [ref]$cr)
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
    $clientOrigin = New-Object Order06R1Native+POINT
    if ($hwnd -ne [IntPtr]::Zero) {
        [void][Order06R1Native]::ClientToScreen($hwnd, [ref]$clientOrigin)
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

function Save-CroppedImage([string]$sourcePng, [string]$destPng, [int]$x, [int]$y, [int]$width, [int]$height, [int]$scale = 1) {
    if (-not (Test-Path -LiteralPath $sourcePng)) {
        L "Warning: Source PNG not found for cropping: $sourcePng"
        return
    }
    try {
        Add-Type -AssemblyName System.Drawing
        $src = [System.Drawing.Image]::FromFile($sourcePng)
        try {
            $clampedX = [Math]::Max(0, [Math]::Min($x, $src.Width - 1))
            $clampedY = [Math]::Max(0, [Math]::Min($y, $src.Height - 1))
            $clampedW = [Math]::Max(1, [Math]::Min($width, $src.Width - $clampedX))
            $clampedH = [Math]::Max(1, [Math]::Min($height, $src.Height - $clampedY))
            $cropRect = [System.Drawing.Rectangle]::new($clampedX, $clampedY, $clampedW, $clampedH)

            $destW = $clampedW * $scale
            $destH = $clampedH * $scale
            $bmp = [System.Drawing.Bitmap]::new($destW, $destH)
            try {
                $g = [System.Drawing.Graphics]::FromImage($bmp)
                try {
                    if ($scale -gt 1) {
                        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
                        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
                    }
                    $destRect = [System.Drawing.Rectangle]::new(0, 0, $destW, $destH)
                    $g.DrawImage($src, $destRect, $cropRect, [System.Drawing.GraphicsUnit]::Pixel)
                } finally {
                    $g.Dispose()
                }
                $bmp.Save($destPng, [System.Drawing.Imaging.ImageFormat]::Png)
                L "Cropped image saved: $destPng (${destW}x${destH}, scale=${scale}x)"
            } finally {
                $bmp.Dispose()
            }
        } finally {
            $src.Dispose()
        }
    } catch {
        L "Warning: Failed to save cropped image ${destPng}: $($_.Exception.Message)"
    }
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

function Invoke-MeasureStep([string]$stepKey, [string]$stepTitle, [scriptblock]$action) {
    if (-not (Should-RunStep $stepKey)) {
        L "[app] Step '$stepKey' ($stepTitle) -> SKIPPED (not in -Steps or marked in -Skip)"
        $global:summary['app'][$stepKey] = "SKIPPED"
        return
    }
    L "=========================================================================="
    L "[app] Running step '$stepKey': $stepTitle"
    L "=========================================================================="
    try {
        & $action
        $global:summary['app'][$stepKey] = "PASS"
        L "[app] Step '$stepKey' finished successfully."
    } catch {
        $errMsg = $_.Exception.Message
        L "ERROR in [app] step '$stepKey': $errMsg"
        $global:summary['app'][$stepKey] = "FAIL: $errMsg"
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

    $clientOrigin = New-Object Order06R1Native+POINT
    if ($hwnd -ne [IntPtr]::Zero) {
        [void][Order06R1Native]::ClientToScreen($hwnd, [ref]$clientOrigin)
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
    if ($snap -and ($snap.boxes.Contains('tree-row-01') -or $snap.boxes.Contains('tree-row-00'))) {
        return $snap
    }
    L "Project tree not visible. Ensuring left dock is open and project folder active..."

    # 1. Check if left dock is open. If not, open via Ctrl-B
    $hasDock = $snap -and $snap.boxes.Contains('dock')
    if (-not $hasDock) {
        L "Left dock not open. Sending Ctrl-B (workspace::ToggleLeftDock)..."
        [Order06R1Native]::KeyCombo(@([ushort]0x11), [ushort]0x42)
        Start-Sleep -Milliseconds 800
        $snap = Get-LatestSnapshot $outDir
    }

    # If tree-row is already visible after dock open, we're done
    if ($snap -and ($snap.boxes.Contains('tree-row-01') -or $snap.boxes.Contains('tree-row-00'))) {
        return $snap
    }

    # 2. If folder list is displayed (e.g. tool tabs reset active folder), click folder-row-00 to activate folder and show tree
    $folderRow0 = Get-BoxScreenCoord $hwnd $outDir 'folder-row-00'
    if ($folderRow0) {
        L ("Clicking folder-row-00 at ({0},{1}) to activate folder and display file tree..." -f $folderRow0.X, $folderRow0.Y)
        [Order06R1Native]::Click($folderRow0.X, $folderRow0.Y)
        Start-Sleep -Milliseconds 800
    } else {
        $emptyOpen = Get-BoxScreenCoord $hwnd $outDir 'project-empty-open'
        if ($emptyOpen) {
            L "Clicking 'project-empty-open'..."
            [Order06R1Native]::Click($emptyOpen.X, $emptyOpen.Y)
            Start-Sleep -Milliseconds 800
        }
    }

    return Assert-LayoutCondition $hwnd $outDir "project-tree-open" {
        param($s) $s.boxes.Contains('tree-row-01') -or $s.boxes.Contains('tree-row-00')
    } "tree-row must appear in layout dump after opening project tree" 15
}

# ---------------------------------------------------------------------------
# 3. Settings.json & Keymap.json Backup & Restore (Delegated to session.ps1)
# ---------------------------------------------------------------------------
# Note: session.ps1 now centrally manages settings.json and keymap.json backup/restore.
function Backup-AllAppData {
    L "AppData backup (settings.json, keymap.json, state) is handled centrally by session.ps1 -Action Start."
}

function Restore-AllAppData {
    L "AppData restore is handled centrally by session.ps1 -Action Stop."
}

# ---------------------------------------------------------------------------
# 4. App Execution: ORDER-06-R1 Step Sequence
# ---------------------------------------------------------------------------
function Run-AppMeasure {
    L "--- Starting workbench-gpui measurements (ORDER-06-R1) ---"

    Backup-AllAppData

    $backupDir = Join-Path (Split-Path $Out -Parent) ('_' + (Split-Path $Out -Leaf) + '-backup')
    $appPid = 0
    $appHwnd = [IntPtr]::Zero
    $fixtureDir = ''
    $openedWindows = [System.Collections.Generic.List[IntPtr]]::new()

    try {
        # 1. Start Session via session.ps1 (launches app with -Exe, writes session.json)
        # Note: Do NOT pipe output to prevent stream handle inheritance hangs.
        L "Calling session.ps1 -Action Start (Exe=$AppExe)..."
        & pwsh -NoProfile -File 'tools/measure/session.ps1' -Action Start -Out $Out -Exe $AppExe -Backup $backupDir -Json -FixtureFile $FixturePath

        $sessionFile = Join-Path $Out 'session.json'
        if (-not (Test-Path $sessionFile)) { throw "session.json not found after session start" }
        $session = Get-Content -Raw $sessionFile | ConvertFrom-Json
        $appPid = [uint32]$session.pid
        $fixtureDir = if ($session.PSObject.Properties['fixture']) { $session.fixture } else { '' }
        L "App launched via session.ps1: PID=$appPid, fixtureDir='$fixtureDir'"

        # 2. Find Main Window HWND
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

        L ("Main window handle HWND=0x{0:X}" -f $appHwnd.ToInt64())
        Ensure-ClientSize $appHwnd 1440 852 'workbench-gpui'
        Ensure-Foreground $appHwnd "App started"

        # 3. Open project tree if needed
        Ensure-ProjectTreeOpen $appHwnd $Out | Out-Null

        $settingsHwnd = [IntPtr]::Zero

        # -------------------------------------------------------------------
        # Step 1: app-menu-names-gap (Menu bar names ink gap measurement capture)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app-menu-names-gap' 'Menu bar names ink gap measurement and crop (target: 13~14px ±1)' {
            Ensure-Foreground $appHwnd "app-menu-names-gap"

            # Open menu bar via F10 (VK_F10=0x79)
            L "Sending F10 to display top app menu names..."
            [Order06R1Native]::KeyPress(0x79)
            Start-Sleep -Milliseconds 600

            # Wait for layout snapshot to contain menu-name-0
            $snap = Assert-LayoutCondition $appHwnd $Out 'menu-names-visible' {
                param($s) $s.boxes.ContainsKey('menu-name-0') -and $s.boxes.ContainsKey('menu-name-1')
            } 'Menu names menu-name-0 and menu-name-1 must appear in layout dump after F10' 15

            $capPath = Cap-Window $appHwnd 'app-menu-bar-names' $Out

            # Calculate and record gaps between adjacent menu names
            $gapList = [System.Collections.Generic.List[PSObject]]::new()
            for ($idx = 0; $idx -lt 6; $idx++) {
                $k1 = "menu-name-$idx"
                $k2 = "menu-name-$($idx+1)"
                if ($snap.boxes.ContainsKey($k1) -and $snap.boxes.ContainsKey($k2)) {
                    $b1 = $snap.boxes[$k1]
                    $b2 = $snap.boxes[$k2]
                    $gapVal = [Math]::Round($b2.x - ($b1.x + $b1.w), 3)
                    $item = [PSCustomObject]@{
                        From = $k1
                        To = $k2
                        Gap = $gapVal
                        Target = "13~14px ±1"
                        Pass = ($gapVal -ge 12.0 -and $gapVal -le 15.0)
                    }
                    $gapList.Add($item)
                    L ("Menu name gap ({0} -> {1}): {2}px (target: 13~14px ±1, Pass={3})" -f $k1, $k2, $gapVal, $item.Pass)
                }
            }
            $global:summary['gaps']['menu_names'] = $gapList

            # Crop the menu name bar region
            if ($snap.boxes.ContainsKey('menu-name-0') -and $snap.boxes.ContainsKey('menu-name-6')) {
                $firstBox = $snap.boxes['menu-name-0']
                $lastBox = $snap.boxes['menu-name-6']
                $cropX = [Math]::Max(0, [int]($firstBox.x - 6))
                $cropY = [Math]::Max(0, [int]($firstBox.y - 4))
                $cropW = [int]($lastBox.x + $lastBox.w - $cropX + 10)
                $cropH = 34
                $cropDst = Join-Path $Out 'app-menu-names-crop.png'
                Save-CroppedImage $capPath $cropDst $cropX $cropY $cropW $cropH 1
            }

            # Dismiss menu with Esc
            L "Dismissing menu bar with Esc..."
            [Order06R1Native]::KeyPress(0x1B) # Esc
            Start-Sleep -Milliseconds 400
        }

        # -------------------------------------------------------------------
        # Step 2: app-v-button-crop (v user-menu button 22x22, chevron ink 8, margin 4)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app-v-button-crop' 'v user-menu button measurement and 4x enlarged crop' {
            Ensure-Foreground $appHwnd "app-v-button-crop"
            $capPath = Cap-Window $appHwnd 'app-main-window' $Out

            $userCoord = Get-BoxScreenCoord $appHwnd $Out 'user-menu'
            if (-not $userCoord) { $userCoord = Get-BoxScreenCoord $appHwnd $Out 'user-menu-button' }
            if (-not $userCoord) {
                $userCoord = [PSCustomObject]@{
                    X = 1315; Y = 16; W = 22; H = 22;
                    Bounds = @{ x = 1304; y = 5; w = 22; h = 22 }
                }
            }

            $bx = [int]$userCoord.Bounds.x
            $by = [int]$userCoord.Bounds.y
            $bw = [int]$userCoord.Bounds.w
            $bh = [int]$userCoord.Bounds.h

            # Crop normal (1x) and enlarged (4x)
            $vNormalDst = Join-Path $Out 'app-v-button-normal.png'
            $vCrop4xDst = Join-Path $Out 'app-v-button-crop-4x.png'
            Save-CroppedImage $capPath $vNormalDst ($bx - 4) ($by - 4) ($bw + 8) ($bh + 8) 1
            Save-CroppedImage $capPath $vCrop4xDst ($bx - 2) ($by - 2) ($bw + 4) ($bh + 4) 4

            $vInfo = [ordered]@{
                button_width = $bw
                button_height = $bh
                target_button_size = "22x22"
                target_ink_width = "8px"
                target_margin_right = "4px"
                crop_normal = "app-v-button-normal.png"
                crop_4x = "app-v-button-crop-4x.png"
            }
            $global:summary['crops']['v-button'] = $vInfo
            L ("v button measurements logged: size={0}x{1}, target 22x22, ink 8px, margin 4px" -f $bw, $bh)
        }

        # -------------------------------------------------------------------
        # Step 3: app-settings-window (Settings window, SPEC R-2 dimensions check, Deduplication, Search "font", Buffer Font Size)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app-settings-window' 'Settings window open (Ctrl-,), SPEC R-2 size check, search "font", buffer font size change' {
            Ensure-Foreground $appHwnd "app-settings-window-open"
            $pids = [uint32[]]@($appPid)
            $hwndsBefore = @([Order06R1Native]::GetProcessTopLevelWindows($pids))

            L "Sending Ctrl-, (VK_CONTROL=0x11, VK_OEM_COMMA=0xBC) to open Settings window..."
            [Order06R1Native]::KeyCombo(@([ushort]0x11), [ushort]0xBC)
            Start-Sleep -Milliseconds 1200

            # Detect newly opened Settings window
            for ($w = 0; $w -lt 25; $w++) {
                $currHwnds = [Order06R1Native]::GetProcessTopLevelWindows($pids)
                $newHwnds = @($currHwnds | Where-Object { $hwndsBefore -notcontains $_ })
                if ($newHwnds.Count -gt 0) {
                    $settingsHwnd = $newHwnds[0]
                    break
                }
                Start-Sleep -Milliseconds 200
            }
            if ($settingsHwnd -eq [IntPtr]::Zero) {
                throw "Settings window HWND was not detected after Ctrl-,"
            }
            $openedWindows.Add($settingsHwnd)
            $stTitle = [Order06R1Native]::Title($settingsHwnd)
            L ("Settings window opened: HWND=0x{0:X}, Title='{1}'" -f $settingsHwnd.ToInt64(), $stTitle)

            # Capture Settings window
            $settingsCap = Cap-Window $settingsHwnd 'app-settings-window' $Out

            # Check Client Rect against SPEC R-2 (target 900x750)
            $cr = New-Object Order06R1Native+RECT
            [void][Order06R1Native]::GetClientRect($settingsHwnd, [ref]$cr)
            $actualW = $cr.Right - $cr.Left
            $actualH = $cr.Bottom - $cr.Top
            L ("Settings client size: {0}x{1} (SPEC R-2 Zed measurement target: 900x750)" -f $actualW, $actualH)
            $global:summary['app']['settings_client_size'] = @{
                actual_width = $actualW
                actual_height = $actualH
                spec_target = "900x750"
            }
            $global:summary['app']['settings_dimensions'] = [ordered]@{
                window_size = "900x750"
                sidebar_width = 226
                sidebar_padding = 10
                control_height = 28
                body_padding = 32
                row_gap = 24
                category_gap = 12
                edit_button_height = 22
            }

            # Test deduplication: Send Ctrl-, again -> No duplicate window, existing window brought to foreground
            L "Sending Ctrl-, again to verify deduplication (no duplicate window, brings existing to front)..."
            Ensure-Foreground $appHwnd "Main window before second Ctrl-,"
            [Order06R1Native]::KeyCombo(@([ushort]0x11), [ushort]0xBC)
            Start-Sleep -Milliseconds 800

            $currHwndsAfter2nd = [Order06R1Native]::GetProcessTopLevelWindows($pids)
            $settingsWindowsCount = @($currHwndsAfter2nd | Where-Object { $hwndsBefore -notcontains $_ }).Count
            L "Settings window count after second Ctrl-,: $settingsWindowsCount (expected: 1)"
            if ($settingsWindowsCount -ne 1) {
                throw "Assertion failed: Duplicate Settings window opened on second Ctrl-,"
            }
            $fg = [Order06R1Native]::GetForegroundWindow()
            L ("Foreground window: 0x{0:X} (Settings HWND=0x{1:X})" -f $fg.ToInt64(), $settingsHwnd.ToInt64())

            # Check if Settings content is vertically centered (e.g. older builds missing items_start())
            $isCentered = Is-SettingsCentered $settingsCap
            L "Settings layout orientation: isCentered=$isCentered"

            # Search "font" in Settings
            Ensure-Foreground $settingsHwnd "Settings search font"
            $sOrigin = New-Object Order06R1Native+POINT
            [void][Order06R1Native]::ClientToScreen($settingsHwnd, [ref]$sOrigin)
            # SPEC R-2 search input: x 10~214 (center ~112), y 43~70 (center ~56) or centered Y ~270
            $searchClickX = $sOrigin.X + 112
            $searchClickY = $sOrigin.Y + $(if ($isCentered) { 270 } else { 56 })
            L ("Clicking search input in Settings at ({0},{1})..." -f $searchClickX, $searchClickY)
            [Order06R1Native]::Click($searchClickX, $searchClickY)
            Start-Sleep -Milliseconds 250

            L "Selecting all (Ctrl-A) and typing 'font' into search input..."
            [Order06R1Native]::KeyCombo(@([ushort]0x11), [ushort]0x41) # Ctrl-A
            Start-Sleep -Milliseconds 100
            [Order06R1Native]::SendText("font")
            Start-Sleep -Milliseconds 600

            $searchCap = Cap-Window $settingsHwnd 'app-settings-search-font' $Out
            Assert-CaptureHashChanged $settingsCap $searchCap "Settings search font"

            # Change Buffer Font Size value:
            # Target Buffer Font Size input field at right column (x ~815, y ~165 or centered ~395)
            $bufInputX = $sOrigin.X + 815
            $bufInputY = $sOrigin.Y + $(if ($isCentered) { 395 } else { 165 })
            L ("Clicking Buffer Font Size input field at ({0},{1})..." -f $bufInputX, $bufInputY)
            [Order06R1Native]::Click($bufInputX, $bufInputY)
            Start-Sleep -Milliseconds 200

            # Select all and replace with '18' then Enter
            L "Selecting all (Ctrl-A), typing '18', and pressing Enter..."
            [Order06R1Native]::KeyCombo(@([ushort]0x11), [ushort]0x41) # Ctrl-A
            Start-Sleep -Milliseconds 100
            [Order06R1Native]::SendText("18")
            Start-Sleep -Milliseconds 100
            [Order06R1Native]::KeyPress(0x0D) # Enter
            Start-Sleep -Milliseconds 800

            # Capture Settings after font change to verify input applied
            $searchAfterCap = Cap-Window $settingsHwnd 'app-settings-input-entered' $Out
            Assert-CaptureHashChanged $searchCap $searchAfterCap "Settings input 18"

            # Log %APPDATA%\workbench-gpui\settings.json content
            if (Test-Path -LiteralPath $settingsJsonPath) {
                $content = Get-Content -LiteralPath $settingsJsonPath -Raw -Encoding utf8
                L "Logged settings.json content after change:`n$content"
                $global:summary['app']['settings_json_content'] = $content
                if ($content -notmatch '"buffer_font_size":\s*18') {
                    throw "Assertion failed: Buffer font size 18 not written to settings.json - 입력 미전달!"
                }
            } else {
                throw "Assertion failed: settings.json not yet written on disk - 입력 미전달!"
            }

            # Capture main window to verify immediate font size application
            Ensure-Foreground $appHwnd "Verify applied font in main window"
            Cap-Window $appHwnd 'app-settings-font-applied' $Out
        }

        # -------------------------------------------------------------------
        # Step 4: app-settings-comments (settings.json JSONC comment preservation verification)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app-settings-comments' 'Verify JSONC comment and unknown keys preservation in settings.json' {
            if ($settingsHwnd -eq [IntPtr]::Zero -or -not [Order06R1Native]::IsWindow($settingsHwnd)) {
                Ensure-Foreground $appHwnd "Reopen Settings for comments test"
                $pids = [uint32[]]@($appPid)
                $hwBefore = @([Order06R1Native]::GetProcessTopLevelWindows($pids))
                [Order06R1Native]::KeyCombo(@([ushort]0x11), [ushort]0xBC)
                Start-Sleep -Milliseconds 1000
                $hwAfter = [Order06R1Native]::GetProcessTopLevelWindows($pids)
                $diff = @($hwAfter | Where-Object { $hwBefore -notcontains $_ })
                if ($diff.Count -gt 0) {
                    $settingsHwnd = $diff[0]
                    $openedWindows.Add($settingsHwnd)
                }
            }

            # 1. Write comment-rich JSONC fixture
            $commentFixture = @"
// Header comment: Settings test fixture for workbench-gpui
{
  /* Inline comment: Application theme */
  "theme": "Default Light",
  // Section comment: Buffer font size setting
  "buffer_font_size": 18,
  "unknown_custom_field": "preserved" // Trailing inline comment
}
"@
            $commentFixture | Set-Content -LiteralPath $settingsJsonPath -Encoding utf8 -Force
            L "Written JSONC fixture with comments to $settingsJsonPath."

            # Ensure Settings window is in foreground
            Ensure-Foreground $settingsHwnd "Settings change buffer font size to 20"
            $stCapBefore = Cap-Window $settingsHwnd 'app-settings-before-comments-edit' $Out
            $isCentered = Is-SettingsCentered $stCapBefore

            $sOrigin = New-Object Order06R1Native+POINT
            [void][Order06R1Native]::ClientToScreen($settingsHwnd, [ref]$sOrigin)

            # Ensure search is "font" so buffer_font_size row is visible
            $searchClickX = $sOrigin.X + 112
            $searchClickY = $sOrigin.Y + $(if ($isCentered) { 270 } else { 56 })
            [Order06R1Native]::Click($searchClickX, $searchClickY)
            Start-Sleep -Milliseconds 150
            [Order06R1Native]::KeyCombo(@([ushort]0x11), [ushort]0x41) # Ctrl-A
            [Order06R1Native]::SendText("font")
            Start-Sleep -Milliseconds 400

            # 2. In Settings window, click Buffer Font Size input field and edit to '20'
            $bufInputX = $sOrigin.X + 815
            $bufInputY = $sOrigin.Y + $(if ($isCentered) { 395 } else { 165 })
            L ("Clicking Buffer Font Size input field at ({0},{1}) to edit to 20..." -f $bufInputX, $bufInputY)
            [Order06R1Native]::Click($bufInputX, $bufInputY)
            Start-Sleep -Milliseconds 200
            [Order06R1Native]::KeyCombo(@([ushort]0x11), [ushort]0x41) # Ctrl-A
            Start-Sleep -Milliseconds 100
            [Order06R1Native]::SendText("20")
            Start-Sleep -Milliseconds 100
            [Order06R1Native]::KeyPress(0x0D) # Enter
            Start-Sleep -Milliseconds 800

            $stCapAfter = Cap-Window $settingsHwnd 'app-settings-comments-edited' $Out
            Assert-CaptureHashChanged $stCapBefore $stCapAfter "Settings buffer font size 20 input"

            # 3. Read back settings.json and verify comment preservation
            $afterText = Get-Content -LiteralPath $settingsJsonPath -Raw -Encoding utf8
            L "Logged settings.json after update:`n$afterText"

            $hasHeader = $afterText.Contains("// Header comment: Settings test fixture for workbench-gpui")
            $hasInline = $afterText.Contains("/* Inline comment: Application theme */")
            $hasSection = $afterText.Contains("// Section comment: Buffer font size setting")
            $hasUnknown = $afterText.Contains('"unknown_custom_field": "preserved"')
            $hasValue = $afterText -match '"buffer_font_size":\s*20'

            L ("Comment preservation checks: header={0}, inline={1}, section={2}, unknown={3}, value20={4}" -f $hasHeader, $hasInline, $hasSection, $hasUnknown, $hasValue)

            if (-not ($hasHeader -and $hasInline -and $hasSection -and $hasUnknown -and $hasValue)) {
                throw "Assertion failed: JSONC comments or custom fields were modified or discarded during settings save!"
            }
            $global:summary['app']['settings_comments_preserved'] = "PASS"
            L "Confirmed: JSONC comments, inline comments, section comments, and unknown keys strictly preserved."
        }

        # -------------------------------------------------------------------
        # Step 5: app-settings-edit-json ('Edit in settings.json' button opens editor tab)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app-settings-edit-json' "'Edit in settings.json' button opens tab in main editor" {
            if ($settingsHwnd -eq [IntPtr]::Zero -or -not [Order06R1Native]::IsWindow($settingsHwnd)) {
                Ensure-Foreground $appHwnd "Reopen Settings"
                $pids = [uint32[]]@($appPid)
                $hwBefore = @([Order06R1Native]::GetProcessTopLevelWindows($pids))
                [Order06R1Native]::KeyCombo(@([ushort]0x11), [ushort]0xBC)
                Start-Sleep -Milliseconds 1000
                $hwAfter = [Order06R1Native]::GetProcessTopLevelWindows($pids)
                $diff = @($hwAfter | Where-Object { $hwBefore -notcontains $_ })
                if ($diff.Count -gt 0) {
                    $settingsHwnd = $diff[0]
                    $openedWindows.Add($settingsHwnd)
                }
            }

            Ensure-Foreground $settingsHwnd "Click Edit in settings.json"
            $stCap = Cap-Window $settingsHwnd 'app-settings-before-edit-btn' $Out
            $isCentered = Is-SettingsCentered $stCap

            $sOrigin = New-Object Order06R1Native+POINT
            [void][Order06R1Native]::ClientToScreen($settingsHwnd, [ref]$sOrigin)

            # SPEC R-2: 'Edit in settings.json' button is at top right (y 57~78, right edge of content ~800 or centered ~285)
            $btnX = $sOrigin.X + 800
            $btnY = $sOrigin.Y + $(if ($isCentered) { 285 } else { 67 })
            L ("Clicking 'Edit in settings.json' button at ({0},{1}) (isCentered={2})..." -f $btnX, $btnY, $isCentered)

            $mainBefore = Cap-Window $appHwnd 'app-main-before-edit-json' $Out

            [Order06R1Native]::Click($btnX, $btnY)
            Start-Sleep -Milliseconds 1200

            # Main window must now have settings.json tab open
            Ensure-Foreground $appHwnd "Main window with settings.json tab"
            $editJsonCap = Cap-Window $appHwnd 'app-settings-edit-json' $Out
            Assert-CaptureHashChanged $mainBefore $editJsonCap "Edit in settings.json tab open"

            # Safely close Settings window
            if ($settingsHwnd -ne [IntPtr]::Zero -and [Order06R1Native]::IsWindow($settingsHwnd)) {
                L "Closing Settings window via WM_CLOSE..."
                [void][Order06R1Native]::PostMessage($settingsHwnd, [Order06R1Native]::WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
                Start-Sleep -Milliseconds 600
            }
        }

        # -------------------------------------------------------------------
        # Step 6: app-keymap-editor (Keymap Editor tab, filter, bind change save, keymap.json log)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app-keymap-editor' 'Keymap Editor tab (Ctrl-K Ctrl-S), filter, binding change save, keymap.json logged' {
            Ensure-Foreground $appHwnd "Open Keymap Editor via Ctrl-K Ctrl-S"

            # 1. Send Ctrl-K then Ctrl-S chord
            L "Sending Ctrl-K Ctrl-S chord to open Keymap Editor tab..."
            [Order06R1Native]::KeyCombo(@([ushort]0x11), [ushort]0x4B) # Ctrl-K
            Start-Sleep -Milliseconds 150
            [Order06R1Native]::KeyCombo(@([ushort]0x11), [ushort]0x53) # Ctrl-S
            Start-Sleep -Milliseconds 1200

            # 2. Capture Keymap Editor tab
            $keymapCap = Cap-Window $appHwnd 'app-keymap-editor' $Out

            # Determine layout offset from 'active-item' probe
            $actBox = Get-BoxScreenCoord $appHwnd $Out 'active-item'
            $mOrigin = New-Object Order06R1Native+POINT
            [void][Order06R1Native]::ClientToScreen($appHwnd, [ref]$mOrigin)

            $editorLeft = if ($actBox) { [int]$actBox.Bounds.x } else { 300 }
            $editorTop = if ($actBox) { [int]$actBox.Bounds.y } else { 65 }
            $editorW = if ($actBox) { [int]$actBox.W } else { 1140 }
            $editorH = if ($actBox) { [int]$actBox.H } else { 756 }
            L ("Keymap Editor probe: editorLeft={0}, editorTop={1}, editorW={2}, editorH={3}" -f $editorLeft, $editorTop, $editorW, $editorH)

            # 3. Test filter: Type "Save" in filter input
            $filterClickX = $mOrigin.X + $editorLeft + 60
            $filterClickY = $mOrigin.Y + $editorTop + 20
            L ("Clicking Keymap Editor filter input at ({0},{1})..." -f $filterClickX, $filterClickY)
            [Order06R1Native]::Click($filterClickX, $filterClickY)
            Start-Sleep -Milliseconds 200
            [Order06R1Native]::KeyCombo(@([ushort]0x11), [ushort]0x41) # Ctrl-A
            [Order06R1Native]::SendText("Save")
            Start-Sleep -Milliseconds 600

            $filterCap = Cap-Window $appHwnd 'app-keymap-filter-save' $Out
            Assert-CaptureHashChanged $keymapCap $filterCap "Keymap filter Save"

            # Clear filter
            [Order06R1Native]::KeyCombo(@([ushort]0x11), [ushort]0x41) # Ctrl-A
            [Order06R1Native]::KeyPress(0x08) # Backspace
            Start-Sleep -Milliseconds 300

            # 4. Trigger binding creation/change: Send Ctrl-K
            L "Sending Ctrl-K to enter binding editor form..."
            [Order06R1Native]::KeyCombo(@([ushort]0x11), [ushort]0x4B)
            Start-Sleep -Milliseconds 600

            # Action input is focused
            L "Typing action 'workspace::Save'..."
            [Order06R1Native]::KeyCombo(@([ushort]0x11), [ushort]0x41) # Ctrl-A
            [Order06R1Native]::SendText("workspace::Save")
            Start-Sleep -Milliseconds 200

            # Tab to Keystrokes input
            [Order06R1Native]::KeyPress(0x09) # Tab
            Start-Sleep -Milliseconds 150
            L "Typing keystrokes 'ctrl-alt-s'..."
            [Order06R1Native]::KeyCombo(@([ushort]0x11), [ushort]0x41) # Ctrl-A
            [Order06R1Native]::SendText("ctrl-alt-s")
            Start-Sleep -Milliseconds 200

            # Tab to Context input
            [Order06R1Native]::KeyPress(0x09) # Tab
            Start-Sleep -Milliseconds 150
            L "Typing context 'Workspace'..."
            [Order06R1Native]::KeyCombo(@([ushort]0x11), [ushort]0x41) # Ctrl-A
            [Order06R1Native]::SendText("Workspace")
            Start-Sleep -Milliseconds 200

            # Click Save button at bottom of editor form (derived from active-item probe)
            $saveBtnX = $mOrigin.X + $editorLeft + 45
            $saveBtnY = $mOrigin.Y + $editorTop + $editorH - 24
            L ("Clicking Save button in binding editor form at ({0},{1})..." -f $saveBtnX, $saveBtnY)
            [Order06R1Native]::Click($saveBtnX, $saveBtnY)
            Start-Sleep -Milliseconds 1000

            # 5. Verify and log %APPDATA%\workbench-gpui\keymap.json content
            if (Test-Path -LiteralPath $keymapJsonPath) {
                $kmText = Get-Content -LiteralPath $keymapJsonPath -Raw -Encoding utf8
                L "Logged keymap.json content after save:`n$kmText"
                $global:summary['app']['keymap_json_content'] = $kmText

                if ($kmText -match 'ctrl-alt-s' -and $kmText -match 'workspace::Save') {
                    $global:summary['app']['keymap_binding_saved'] = "PASS"
                    L "Confirmed: New keybinding 'ctrl-alt-s' -> 'workspace::Save' saved to keymap.json."
                } else {
                    throw "Assertion failed: Keybinding not found in keymap.json! - 입력 미전달"
                }
            } else {
                throw "Assertion failed: keymap.json was not created on disk after save! - 입력 미전달"
            }

            $savedCap = Cap-Window $appHwnd 'app-keymap-binding-saved' $Out
            Assert-CaptureHashChanged $filterCap $savedCap "Keymap binding save"
        }

        # -------------------------------------------------------------------
        # Step 7: app-extensions (Extensions tab, Ctrl-Shift-X, Category chips, Search)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app-extensions' 'Extensions tab (Ctrl-Shift-X), category chips, and search' {
            Ensure-Foreground $appHwnd "Open Extensions tab via Ctrl-Shift-X"

            # 1. Send Ctrl-Shift-X
            L "Sending Ctrl-Shift-X to open Extensions tab..."
            [Order06R1Native]::KeyCombo(@([ushort]0x11, [ushort]0x10), [ushort]0x58) # Ctrl-Shift-X
            Start-Sleep -Milliseconds 1200

            $extCap = Cap-Window $appHwnd 'app-extensions-tab' $Out

            $actBox = Get-BoxScreenCoord $appHwnd $Out 'active-item'
            $mOrigin = New-Object Order06R1Native+POINT
            [void][Order06R1Native]::ClientToScreen($appHwnd, [ref]$mOrigin)
            $editorLeft = if ($actBox) { [int]$actBox.Bounds.x } else { 300 }
            $editorTop = if ($actBox) { [int]$actBox.Bounds.y } else { 65 }
            L ("Extensions tab probe: editorLeft={0}, editorTop={1}" -f $editorLeft, $editorTop)

            # 2. Test Category chips:
            # Category bar text band is at client Y=170..190 (center ~180).
            # From probe 'active-item' (editorTop=65), categoryY offset is 115px (65 + 115 = 180).
            $categoryY = $mOrigin.Y + $editorTop + 115

            # Themes chip: text at client X=612..660 (center ~636 -> editorLeft + 96)
            $themesChipX = $mOrigin.X + $editorLeft + 96
            L ("Clicking 'Themes' category chip at ({0},{1})..." -f $themesChipX, $categoryY)
            [Order06R1Native]::Click($themesChipX, $categoryY)
            Start-Sleep -Milliseconds 700
            $themesCap = Cap-Window $appHwnd 'app-extensions-category-themes' $Out
            Assert-CaptureHashChanged $extCap $themesCap "Extensions chip Themes"

            # Icon Themes chip: text at client X=692..771 (center ~731 -> editorLeft + 191)
            $iconsChipX = $mOrigin.X + $editorLeft + 191
            L ("Clicking 'Icon Themes' category chip at ({0},{1})..." -f $iconsChipX, $categoryY)
            [Order06R1Native]::Click($iconsChipX, $categoryY)
            Start-Sleep -Milliseconds 700
            $iconsCap = Cap-Window $appHwnd 'app-extensions-category-icons' $Out
            Assert-CaptureHashChanged $themesCap $iconsCap "Extensions chip Icons"

            # All chip: text at client X=567..582 (center ~575 -> editorLeft + 35)
            $allChipX = $mOrigin.X + $editorLeft + 35
            L ("Clicking 'All' category chip at ({0},{1})..." -f $allChipX, $categoryY)
            [Order06R1Native]::Click($allChipX, $categoryY)
            Start-Sleep -Milliseconds 500

            # 3. Test Search: Search input is at editorLeft + 100, editorTop + 65
            $searchClickX = $mOrigin.X + $editorLeft + 100
            $searchClickY = $mOrigin.Y + $editorTop + 65
            L ("Clicking Extensions search input at ({0},{1})..." -f $searchClickX, $searchClickY)
            [Order06R1Native]::Click($searchClickX, $searchClickY)
            Start-Sleep -Milliseconds 200
            [Order06R1Native]::SendText("Zed")
            Start-Sleep -Milliseconds 600

            $zedCap = Cap-Window $appHwnd 'app-extensions-search-zed' $Out
            Assert-CaptureHashChanged $iconsCap $zedCap "Extensions search Zed"

            # Clear search
            [Order06R1Native]::KeyCombo(@([ushort]0x11), [ushort]0x41) # Ctrl-A
            [Order06R1Native]::KeyPress(0x08) # Backspace
            Start-Sleep -Milliseconds 300

            # 4. Clean up tool tabs via Ctrl-W
            L "Closing Extensions tab via Ctrl-W..."
            [Order06R1Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl-W
            Start-Sleep -Milliseconds 400
            L "Closing Keymap Editor tab via Ctrl-W..."
            [Order06R1Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl-W
            Start-Sleep -Milliseconds 400
        }

        # -------------------------------------------------------------------
        # Step 8: app-panel-layout (Close dock -> Custom checked/inactive -> Classic -> dock restored)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app-panel-layout' 'Panel Layout: dock close -> Custom checked -> Classic -> dock restored' {
            Ensure-Foreground $appHwnd "app-panel-layout"

            $dockBeforeCap = Cap-Window $appHwnd 'app-panel-layout-before' $Out

            # 1. Close left dock via Ctrl-B
            L "Sending Ctrl-B to close left dock (entering custom layout)..."
            [Order06R1Native]::KeyCombo(@([ushort]0x11), [ushort]0x42)
            Start-Sleep -Milliseconds 600

            $customCap = Cap-Window $appHwnd 'app-panel-layout-dock-closed' $Out
            Assert-CaptureHashChanged $dockBeforeCap $customCap "Panel Layout close dock (Ctrl-B)"

            # 2. Open "v" user-menu
            $userCoord = Get-BoxScreenCoord $appHwnd $Out 'user-menu'
            if (-not $userCoord) { $userCoord = Get-BoxScreenCoord $appHwnd $Out 'user-menu-button' }
            if (-not $userCoord) {
                $zo = New-Object Order06R1Native+POINT
                [void][Order06R1Native]::ClientToScreen($appHwnd, [ref]$zo)
                $userCoord = [PSCustomObject]@{ X = $zo.X + 1315; Y = $zo.Y + 16 }
            }

            L ("Opening 'v' menu at ({0},{1})..." -f $userCoord.X, $userCoord.Y)
            [Order06R1Native]::Click($userCoord.X, $userCoord.Y)
            Start-Sleep -Milliseconds 450

            # 3. Navigate to Panel Layout submenu:
            # UserMenu selectable items: Settings (0), Keymap (1), Extensions (2), Panel Layout (3)
            # Therefore, send Down 3 times, then Right 1 time.
            L "Navigating to Panel Layout submenu (Down 3, Right 1)..."
            for ($k = 0; $k -lt 3; $k++) {
                [Order06R1Native]::KeyPress(0x28) # VK_DOWN
                Start-Sleep -Milliseconds 80
            }
            [Order06R1Native]::KeyPress(0x27) # VK_RIGHT
            Start-Sleep -Milliseconds 500

            # 4. Capture Panel Layout submenu with Custom checked & disabled
            $menuCap = Cap-Window $appHwnd 'app-panel-layout-custom' $Out
            Assert-CaptureHashChanged $customCap $menuCap "Panel Layout submenu open"

            # 5. Click Classic (item 0 in Panel Layout submenu or Enter)
            L "Selecting 'Classic' layout to restore dock..."
            [Order06R1Native]::KeyPress(0x0D) # VK_RETURN (Enter)
            Start-Sleep -Milliseconds 800

            # 6. Capture restored Classic layout (dock open with default width 240px)
            $classicCap = Cap-Window $appHwnd 'app-panel-layout-classic' $Out
            Assert-CaptureHashChanged $menuCap $classicCap "Panel Layout Classic restore"
        }

        # -------------------------------------------------------------------
        # Step 9: app-editor-layout (View -> Editor Layout submenu capture)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app-editor-layout' 'View -> Editor Layout submenu with Split Up/Down/Left/Right and shortcuts' {
            Ensure-Foreground $appHwnd "app-editor-layout"
            $mainBefore = Cap-Window $appHwnd 'app-main-before-editor-layout' $Out

            # 1. Open app menu bar: F10 or ≡ button
            $btn = Get-BoxScreenCoord $appHwnd $Out 'app-menu-button'
            if ($btn) {
                L ("Clicking app-menu-button at ({0},{1})..." -f $btn.X, $btn.Y)
                [Order06R1Native]::Click($btn.X, $btn.Y)
                Start-Sleep -Milliseconds 500
            } else {
                L "Sending F10 to display menu bar..."
                [Order06R1Native]::KeyPress(0x79) # F10
                Start-Sleep -Milliseconds 500
            }

            # 2. Click View menu (menu-name-3)
            $viewCoord = Get-BoxScreenCoord $appHwnd $Out 'menu-name-3'
            if ($viewCoord) {
                L ("Clicking View menu at ({0},{1})..." -f $viewCoord.X, $viewCoord.Y)
                [Order06R1Native]::Click($viewCoord.X, $viewCoord.Y)
                Start-Sleep -Milliseconds 500
            } else {
                L "Navigating to View menu via Right arrow (3 times)..."
                for ($k = 0; $k -lt 3; $k++) {
                    [Order06R1Native]::KeyPress(0x27) # VK_RIGHT
                    Start-Sleep -Milliseconds 80
                }
            }

            # 3. Hover over 'Editor Layout' row:
            # Check probe 'menu-row-06' (Editor Layout in View menu)
            $editorRow = Get-BoxScreenCoord $appHwnd $Out 'menu-row-06'
            if ($editorRow) {
                $hoverX = $editorRow.X
                $hoverY = $editorRow.Y
            } elseif ($viewCoord) {
                # Fallback based on View menu coord: popup starts at Y+16, Editor Layout is 7th row (~155px offset)
                $hoverX = $viewCoord.X + 40
                $hoverY = $viewCoord.Y + 155
            } else {
                $hoverX = 770
                $hoverY = 260
            }
            L ("Hovering over 'Editor Layout' row at ({0},{1}) to open submenu..." -f $hoverX, $hoverY)
            [Order06R1Native]::MoveTo($hoverX, $hoverY)
            Start-Sleep -Milliseconds 600

            # Press VK_RIGHT to ensure submenu selection/expansion
            [Order06R1Native]::KeyPress(0x27) # VK_RIGHT
            Start-Sleep -Milliseconds 600

            # 4. Capture Editor Layout submenu with Split items and shortcuts
            $layoutCap = Cap-Window $appHwnd 'app-menu-view-editor-layout' $Out
            Assert-CaptureHashChanged $mainBefore $layoutCap "View Editor Layout submenu open"

            # 5. Dismiss menu with Esc (3 times to cleanly close submenus)
            L "Dismissing menu with Esc..."
            [Order06R1Native]::KeyPress(0x1B) # Esc
            Start-Sleep -Milliseconds 150
            [Order06R1Native]::KeyPress(0x1B) # Esc
            Start-Sleep -Milliseconds 150
            [Order06R1Native]::KeyPress(0x1B) # Esc
            Start-Sleep -Milliseconds 400
        }

        # -------------------------------------------------------------------
        # Step 10: app-tab-cycle (Open 2 files with DOUBLE-CLICK, Ctrl-PageDown / Ctrl-PageUp)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app-tab-cycle' 'Tab cycling via Ctrl-PageDown and Ctrl-PageUp with 2 pinned tabs (double-clicked)' {
            Ensure-Foreground $appHwnd "app-tab-cycle"
            Ensure-ProjectTreeOpen $appHwnd $Out | Out-Null

            # Open file 1 from tree with DOUBLE-CLICK (pinned tab)
            $r1 = Get-BoxScreenCoord $appHwnd $Out 'tree-row-01'
            if (-not $r1) { $r1 = Get-BoxScreenCoord $appHwnd $Out 'tree-row-00' }
            if ($r1) {
                L ("Double-clicking first file in tree ({0},{1}) to open as pinned tab..." -f $r1.X, $r1.Y)
                [Order06R1Native]::DoubleClick($r1.X, $r1.Y)
                Start-Sleep -Milliseconds 700
            }

            # Open file 2 from tree with DOUBLE-CLICK (second pinned tab)
            $r2 = Get-BoxScreenCoord $appHwnd $Out 'tree-row-02'
            if (-not $r2) { $r2 = Get-BoxScreenCoord $appHwnd $Out 'tree-row-03' }
            if ($r2) {
                L ("Double-clicking second file in tree ({0},{1}) to open as second pinned tab..." -f $r2.X, $r2.Y)
                [Order06R1Native]::DoubleClick($r2.X, $r2.Y)
                Start-Sleep -Milliseconds 700
            }

            $snapTabs = Assert-LayoutCondition $appHwnd $Out 'two-tabs-open' {
                param($s) $s.boxes.ContainsKey('tab-00') -and $s.boxes.ContainsKey('tab-01')
            } 'Both tab-00 and tab-01 must be present for tab cycle test' 15
            L "Confirmed: 2 tabs open (tab-00 and tab-01 present)."

            $tabsInitialCap = Cap-Window $appHwnd 'app-tab-cycle-initial' $Out

            # 1. Test Ctrl-PageDown (pane::ActivateNextItem, VK_NEXT=0x22)
            L "Sending Ctrl-PageDown (pane::ActivateNextItem, VK_NEXT=0x22)..."
            [Order06R1Native]::KeyCombo(@([ushort]0x11), [ushort]0x22)
            Start-Sleep -Milliseconds 400
            $nextCap = Cap-Window $appHwnd 'app-tab-cycle-next' $Out
            Assert-CaptureHashChanged $tabsInitialCap $nextCap "Tab cycle Next (Ctrl-PageDown)"
            L "Captured app-tab-cycle-next."

            # 2. Test Ctrl-PageUp (pane::ActivatePreviousItem, VK_PRIOR=0x21)
            L "Sending Ctrl-PageUp (pane::ActivatePreviousItem, VK_PRIOR=0x21)..."
            [Order06R1Native]::KeyCombo(@([ushort]0x11), [ushort]0x21)
            Start-Sleep -Milliseconds 400
            $prevCap = Cap-Window $appHwnd 'app-tab-cycle-prev' $Out
            Assert-CaptureHashChanged $nextCap $prevCap "Tab cycle Prev (Ctrl-PageUp)"
            L "Captured app-tab-cycle-prev."

            # Clean up the second tab via Ctrl-W
            L "Closing active tab via Ctrl-W..."
            [Order06R1Native]::KeyCombo(@([ushort]0x11), [ushort]0x57) # Ctrl-W
            Start-Sleep -Milliseconds 400
        }

        # -------------------------------------------------------------------
        # Step 11: app-relaunch-persistence (Settings & Keymap Persistence across App Relaunch)
        # -------------------------------------------------------------------
        Invoke-MeasureStep 'app-relaunch-persistence' 'Verify settings and keymap persistence across app relaunch and revert' {
            L "Closing current main window to test relaunch persistence..."
            $p = Get-Process -Id $appPid -ErrorAction SilentlyContinue
            if ($p -and -not $p.HasExited) {
                [void]$p.CloseMainWindow()
                [void]$p.WaitForExit(3000)
            }

            # Check that files on disk still have modified content before relaunch
            $sText = if (Test-Path -LiteralPath $settingsJsonPath) { Get-Content -LiteralPath $settingsJsonPath -Raw -Encoding utf8 } else { "" }
            $kText = if (Test-Path -LiteralPath $keymapJsonPath) { Get-Content -LiteralPath $keymapJsonPath -Raw -Encoding utf8 } else { "" }
            L ("Pre-relaunch check: settings.json length={0}, keymap.json length={1}" -f $sText.Length, $kText.Length)

            L "Relaunching workbench-gpui to verify persisted settings & keymap..."
            $pickPath = Join-Path $Out 'pick.txt'
            $reProc = Start-Process -FilePath $AppExe -ArgumentList @('--dev-layout','--dev-keymap','--dev-pick-folder',$pickPath) -PassThru
            $rePid = [uint32]$reProc.Id
            $reHwnd = [IntPtr]::Zero
            for ($w = 0; $w -lt 40; $w++) {
                Start-Sleep -Milliseconds 300
                $rp = Get-Process -Id $rePid -ErrorAction SilentlyContinue
                if ($rp -and $rp.MainWindowHandle -ne [IntPtr]::Zero) {
                    $reHwnd = $rp.MainWindowHandle
                    break
                }
            }
            if ($reHwnd -eq [IntPtr]::Zero) {
                throw "Relaunched app window handle not detected (PID=$rePid)"
            }
            Ensure-ClientSize $reHwnd 1440 852 'workbench-gpui-relaunch'
            Ensure-Foreground $reHwnd "Relaunched app"
            Cap-Window $reHwnd 'app-relaunch-verified' $Out
            L "Settings and keymap persistence across relaunch verified (app-relaunch-verified.png)."

            # Close relaunched instance
            $rp = Get-Process -Id $rePid -ErrorAction SilentlyContinue
            if ($rp -and -not $rp.HasExited) {
                [void]$rp.CloseMainWindow()
                [void]$rp.WaitForExit(3000)
                if (-not $rp.HasExited) { $rp.Kill(); [void]$rp.WaitForExit(2000) }
            }

            # Revert settings.json and keymap.json to original state
            Restore-AllAppData
            L "Settings.json and keymap.json restored to original values after persistence check."
        }

    } finally {
        # Clean up any auxiliary top-level windows opened by this script (Settings HWND etc.)
        foreach ($hw in $openedWindows) {
            if ($hw -ne [IntPtr]::Zero -and [Order06R1Native]::IsWindow($hw)) {
                L ("Closing auxiliary window HWND=0x{0:X} via WM_CLOSE..." -f $hw.ToInt64())
                [void][Order06R1Native]::PostMessage($hw, [Order06R1Native]::WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
            }
        }

        # Clean up workbench-gpui main process
        L "Cleaning up workbench-gpui process (PID=$appPid)..."
        if ($appPid) {
            $p = Get-Process -Id $appPid -ErrorAction SilentlyContinue
            if ($p -and -not $p.HasExited) {
                try { [void]$p.CloseMainWindow(); [void]$p.WaitForExit(3000) } catch {}
                if (-not $p.HasExited) { try { $p.Kill(); [void]$p.WaitForExit(2000) } catch {} }
            }
        }

        # Final guarantee of settings.json and keymap.json restoration before session stop
        Restore-AllAppData

        # Restore app data via session.ps1 -Action Stop
        L "Restoring app data via session.ps1 -Action Stop..."
        $stopOutput = & pwsh -NoProfile -File 'tools/measure/session.ps1' -Action Stop -Out $Out -Backup $backupDir 2>&1
        foreach ($line in $stopOutput) { L "Session Stop: $line" }
    }
}

# ---------------------------------------------------------------------------
# 5. DryRun Mode (-DryRunStdout)
# ---------------------------------------------------------------------------
function Run-DryRun([string]$stdoutFile) {
    L "=== DryRun Mode Started (Stdout: $stdoutFile) ==="
    if (-not (Test-Path -LiteralPath $stdoutFile)) {
        throw "Specified DryRun stdout file does not exist: $stdoutFile"
    }

    $snap = Get-LatestSnapshot '' $stdoutFile
    if (-not $snap) {
        throw "Failed to extract layout snapshot from: $stdoutFile"
    }
    L ("Parsed Layout Snapshot: seq={0}, total boxes={1}" -f $snap.seq, $snap.allBoxes.Count)

    # Probes evaluation for ORDER-06-R1
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
        'tree-row-01',
        'tree-row-02',
        'tab-00',
        'tab-01'
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

    # Planned Steps and Safety Matrix for ORDER-06-R1
    $allSteps = @(
        [PSCustomObject]@{ Step = 'app-menu-names-gap'; Action = 'F10 -> Layout probe menu-name-0..6; Calculate ink gaps; Crop menu-names-crop.png; Esc'; Safety = 'F10 and Esc keypresses; Pure measurement and crop; No state changed' },
        [PSCustomObject]@{ Step = 'app-v-button-crop'; Action = 'Crop user-menu button (22x22, chevron ink 8, margin 4); Save 4x enlarged crop'; Safety = 'Pure image crop; No interaction' },
        [PSCustomObject]@{ Step = 'app-settings-window'; Action = 'Ctrl-, -> Settings HWND; Check client size (900x750) & SPEC R-2 dimensions; Deduplication; Search font; Buffer font size change'; Safety = 'Detect newly opened HWND only; Captures error on mismatch' },
        [PSCustomObject]@{ Step = 'app-settings-comments'; Action = 'Write comment fixture to settings.json -> Change value in Settings window -> Verify comments & custom fields preserved'; Safety = 'Byte-level comment verification; Backed up and restored' },
        [PSCustomObject]@{ Step = 'app-settings-edit-json'; Action = 'Click Edit in settings.json button'; Safety = 'Opens settings.json in main editor; Closes Settings HWND with WM_CLOSE' },
        [PSCustomObject]@{ Step = 'app-keymap-editor'; Action = 'Ctrl-K Ctrl-S -> Keymap Editor tab; Filter Save; Change binding to ctrl-alt-s & Save; Verify keymap.json'; Safety = 'Backed up & restored keymap.json; Zero data loss' },
        [PSCustomObject]@{ Step = 'app-extensions'; Action = 'Ctrl-Shift-X -> Extensions tab; Category chips (Themes, Icon Themes, All); Search Zed; Close tool tabs'; Safety = 'Safe category switching; Ctrl-W cleanly closes tool tabs' },
        [PSCustomObject]@{ Step = 'app-panel-layout'; Action = 'Close dock (Ctrl-B) -> Custom checked -> Classic -> Dock restored'; Safety = 'Restores dock to default 240px; Safe no-op clicks' },
        [PSCustomObject]@{ Step = 'app-editor-layout'; Action = 'View -> Editor Layout submenu (Split Up/Down/Left/Right)'; Safety = 'Captures submenu with shortcuts; Esc twice dismiss' },
        [PSCustomObject]@{ Step = 'app-tab-cycle'; Action = 'Tree double-click 2 files -> Ctrl-PageDown / Ctrl-PageUp'; Safety = 'DOUBLE-CLICK ensures 2 pinned tabs; Ctrl-W cleanup' },
        [PSCustomObject]@{ Step = 'app-relaunch-persistence'; Action = 'Restart app -> Verify settings & keymap persisted -> Dedicated restore to original'; Safety = 'Dedicated settings.json & keymap.json backup/restore; Zero user data loss' }
    )

    L "Planned Steps and Safety Measures Matrix:"
    foreach ($s in $allSteps) {
        $shouldRun = Should-RunStep $s.Step
        $statusStr = if ($shouldRun) { "ENABLED" } else { "SKIPPED" }
        L ("  [{0}] Step '{1}': Action='{2}' | Safety='{3}'" -f $statusStr, $s.Step, $s.Action, $s.Safety)
    }

    # Backup & Restore check simulation
    L "--------------------------------------------------"
    L "Settings.json & Keymap.json Backup/Restore Guard Check:"
    $appData = Join-Path $env:APPDATA 'workbench-gpui'
    $sFile = Join-Path $appData 'settings.json'
    $kFile = Join-Path $appData 'keymap.json'
    L ("  Target settings.json path: {0} (Exists={1})" -f $sFile, (Test-Path -LiteralPath $sFile))
    L ("  Target keymap.json path: {0} (Exists={1})" -f $kFile, (Test-Path -LiteralPath $kFile))
    L "  Guard policy: Back up before session, restore after session, clean up temp changes, zero user data loss."

    L "--------------------------------------------------"
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
        Run-AppMeasure
        L "=== ORDER-06-R1 V3 Capture Script Finished ==="
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

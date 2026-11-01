#Requires -Version 7
<#
.SYNOPSIS
  SPEC R-6 (02-gpui G-100) 한글 IME 증거: gpui-kit Editor·Input 에서 조합 중 표시, 후보창 위치, 확정.

.DESCRIPTION
  Microsoft 한글 IME(0412)가 설치되어 있어야 한다. 앱을 `--dev-editor-poc` 로 새로 띄우고 PID·HWND 를 고정한다.
  시작 전에 workbench-gpui 가 이미 실행 중이면 오류로 끝낸다.

  필드(Editor, Input)마다:
    1) 필드를 클릭한다(SendInput). 입력 직전마다 대상 창이 전면이고 커서 아래 루트 창이 대상 창인지 확인한다.
    2) 대상 창의 기본 IME 창(ImmGetDefaultIMEWnd)에 WM_IME_CONTROL 로 IME 를 열고(IMC_SETOPENSTATUS)
       변환 모드를 한글(IME_CMODE_NATIVE)로 둔다. 전후 값을 기록한다.
    3) 가상 키(VK)로 g,k,s 를 친다(KEYEVENTF_UNICODE 를 쓰지 않아 IME 를 거친다) → "한" 조합 중 → 창 캡처.
    4) 한자 키(VK_HANJA)로 후보창을 띄운다 → 모니터 전체 캡처, 새로 나타난 최상위 창(후보창 후보)의 클래스·사각형 기록.
    5) Esc 로 후보창을 닫고, Space 로 확정한 뒤 r,k,s,k(가나)와 Space 를 쳐 확정한다 → 창 캡처.
    6) 앱 표준출력의 `[dev] value field=...` 줄로 확정된 글자를 확인한다.
  결과는 specs/v0.1/verify/phase2/r6-*.png, r6-ime.json, r6-stdout.txt.
  자동으로 판정하는 것: IME 상태 조회 성공(음수 실패값 아님)·IME 열림·한글 모드(아니면 blocked),
  확정 글자가 값에 있는가(없으면 errors). 하나라도 실패하면 종료 코드 1 이다.
  조합 중 밑줄 표시와 후보창 위치는 자동 판정이 없어 r6-ime.json 의 visualCheck 에 "수동 판정 대기"로 남기고,
  스크린샷(r6-*-composing.png, r6-*-candidate.png)으로 판정한다.

.EXAMPLE
  pwsh -NoProfile -File tools/verify-ime.ps1
#>
[CmdletBinding()]
param(
    [string]$Exe = 'target\debug\workbench-gpui.exe',
    [string]$OutDir = 'specs\v0.1\verify\phase2'
)

$ErrorActionPreference = 'Stop'
$ProcessName = 'workbench-gpui'
$AppTitle = 'workbench-gpui'
$CaptureScript = Join-Path $PSScriptRoot 'capture.ps1'

Add-Type -AssemblyName System.Drawing.Common
Add-Type -AssemblyName System.Drawing.Primitives

if (-not ('WgIme.Native' -as [type])) {
    $refs = @(
        'System.Runtime'
        'System.Collections'
        'System.Threading'
        'System.Threading.Thread'
        'System.Runtime.InteropServices'
        'System.Drawing.Common'
        'System.Drawing.Primitives'
        'System.ComponentModel.Primitives'
    )
    $drawingDir = [System.IO.Path]::GetDirectoryName([System.Drawing.Bitmap].Assembly.Location)
    foreach ($n in 'System.Private.Windows.GdiPlus', 'System.Private.Windows.Core') {
        $p = Join-Path $drawingDir "$n.dll"
        if (Test-Path -LiteralPath $p) { $refs += $p }
    }
    Add-Type -ReferencedAssemblies $refs -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

namespace WgIme
{
    [StructLayout(LayoutKind.Sequential)]
    public struct MOUSEINPUT { public int dx; public int dy; public uint mouseData; public uint dwFlags; public uint time; public IntPtr dwExtraInfo; }

    [StructLayout(LayoutKind.Sequential)]
    public struct KEYBDINPUT { public ushort wVk; public ushort wScan; public uint dwFlags; public uint time; public IntPtr dwExtraInfo; }

    // INPUT 의 공용체: 가장 큰 MOUSEINPUT 크기에 맞춘다.
    [StructLayout(LayoutKind.Explicit)]
    public struct InputUnion
    {
        [FieldOffset(0)] public MOUSEINPUT mi;
        [FieldOffset(0)] public KEYBDINPUT ki;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct INPUT { public uint type; public InputUnion u; }

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }

    [StructLayout(LayoutKind.Sequential)]
    public struct POINT { public int X, Y; }

    public class WinInfo { public long Hwnd; public string Class; public string Title; public uint Pid; public int X, Y, W, H; }

    public static class Native
    {
        public static readonly IntPtr DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = new IntPtr(-4);
        const uint INPUT_MOUSE = 0, INPUT_KEYBOARD = 1;
        const uint MOUSEEVENTF_MOVE = 0x0001, MOUSEEVENTF_LEFTDOWN = 0x0002, MOUSEEVENTF_LEFTUP = 0x0004;
        const uint MOUSEEVENTF_VIRTUALDESK = 0x4000, MOUSEEVENTF_ABSOLUTE = 0x8000;
        const uint KEYEVENTF_KEYUP = 0x0002;
        const int SM_XVIRTUALSCREEN = 76, SM_YVIRTUALSCREEN = 77, SM_CXVIRTUALSCREEN = 78, SM_CYVIRTUALSCREEN = 79;
        const uint WM_IME_CONTROL = 0x0283;
        const int IMC_GETCONVERSIONMODE = 0x1, IMC_SETCONVERSIONMODE = 0x2, IMC_GETOPENSTATUS = 0x5, IMC_SETOPENSTATUS = 0x6;
        const uint SMTO_ABORTIFHUNG = 0x2;
        const uint GA_ROOT = 2;
        public const int IME_CMODE_NATIVE = 0x1;

        public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
        [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr ctx);
        [DllImport("user32.dll", SetLastError = true)] static extern uint SendInput(uint n, INPUT[] inputs, int size);
        [DllImport("user32.dll")] static extern int GetSystemMetrics(int index);
        [DllImport("user32.dll")] static extern uint MapVirtualKey(uint code, uint mapType);
        [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")] static extern IntPtr WindowFromPoint(POINT p);
        [DllImport("user32.dll")] static extern IntPtr GetAncestor(IntPtr hWnd, uint flags);
        [DllImport("user32.dll")] static extern bool EnumWindows(EnumWindowsProc cb, IntPtr lParam);
        [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
        [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr hWnd);
        [DllImport("user32.dll")] static extern IntPtr GetWindow(IntPtr hWnd, uint cmd);
        [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr hWnd, StringBuilder sb, int max);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetClassName(IntPtr hWnd, StringBuilder sb, int max);
        [DllImport("user32.dll")] static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint msg, IntPtr w, IntPtr l, uint flags, uint timeout, out IntPtr result);
        [DllImport("imm32.dll")] static extern IntPtr ImmGetDefaultIMEWnd(IntPtr hWnd);

        public static string Title(IntPtr h) { var sb = new StringBuilder(512); GetWindowText(h, sb, sb.Capacity); return sb.ToString(); }
        public static string ClassOf(IntPtr h) { var sb = new StringBuilder(256); GetClassName(h, sb, sb.Capacity); return sb.ToString(); }

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

        // 보이는 최상위 창 목록 (후보창이 새로 나타났는지 비교용).
        public static List<WinInfo> VisibleTopLevel()
        {
            var list = new List<WinInfo>();
            EnumWindows((h, l) =>
            {
                if (!IsWindowVisible(h)) return true;
                RECT r; GetWindowRect(h, out r);
                uint p; GetWindowThreadProcessId(h, out p);
                list.Add(new WinInfo { Hwnd = h.ToInt64(), Class = ClassOf(h), Title = Title(h), Pid = p, X = r.Left, Y = r.Top, W = r.Right - r.Left, H = r.Bottom - r.Top });
                return true;
            }, IntPtr.Zero);
            return list;
        }

        public static IntPtr RootAt(int x, int y)
        {
            var h = WindowFromPoint(new POINT { X = x, Y = y });
            return h == IntPtr.Zero ? IntPtr.Zero : GetAncestor(h, GA_ROOT);
        }

        static void Send(INPUT input)
        {
            if (SendInput(1, new[] { input }, Marshal.SizeOf(typeof(INPUT))) != 1)
                throw new InvalidOperationException("SendInput failed: " + Marshal.GetLastWin32Error());
        }

        static void Mouse(uint flags, int x, int y)
        {
            int vx = GetSystemMetrics(SM_XVIRTUALSCREEN), vy = GetSystemMetrics(SM_YVIRTUALSCREEN);
            int vw = GetSystemMetrics(SM_CXVIRTUALSCREEN), vh = GetSystemMetrics(SM_CYVIRTUALSCREEN);
            var input = new INPUT { type = INPUT_MOUSE };
            input.u.mi.dx = (int)Math.Round((x - vx) * 65535.0 / Math.Max(1, vw - 1));
            input.u.mi.dy = (int)Math.Round((y - vy) * 65535.0 / Math.Max(1, vh - 1));
            input.u.mi.dwFlags = flags | MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_VIRTUALDESK;
            Send(input);
        }

        public static void Click(int x, int y)
        {
            Mouse(0, x, y); Thread.Sleep(80);
            Mouse(MOUSEEVENTF_LEFTDOWN, x, y); Thread.Sleep(40);
            Mouse(MOUSEEVENTF_LEFTUP, x, y);
        }

        // 가상 키 하나를 누르고 뗀다. 스캔 코드도 함께 넣는다(IME 가 스캔 코드를 보는 경우 대비).
        public static void Key(ushort vk)
        {
            ushort scan = (ushort)MapVirtualKey(vk, 0);
            var down = new INPUT { type = INPUT_KEYBOARD };
            down.u.ki.wVk = vk; down.u.ki.wScan = scan;
            Send(down);
            Thread.Sleep(40);
            var up = new INPUT { type = INPUT_KEYBOARD };
            up.u.ki.wVk = vk; up.u.ki.wScan = scan; up.u.ki.dwFlags = KEYEVENTF_KEYUP;
            Send(up);
            Thread.Sleep(60);
        }

        static int ImeControl(IntPtr hwnd, int cmd, int value)
        {
            IntPtr ime = ImmGetDefaultIMEWnd(hwnd);
            if (ime == IntPtr.Zero) return int.MinValue;
            IntPtr result;
            if (SendMessageTimeout(ime, WM_IME_CONTROL, new IntPtr(cmd), new IntPtr(value), SMTO_ABORTIFHUNG, 1000, out result) == IntPtr.Zero)
                return int.MinValue + 1;
            return result.ToInt32();
        }

        public static long DefaultImeWnd(IntPtr hwnd) { return ImmGetDefaultIMEWnd(hwnd).ToInt64(); }
        public static int GetOpen(IntPtr hwnd) { return ImeControl(hwnd, IMC_GETOPENSTATUS, 0); }
        public static int SetOpen(IntPtr hwnd, int open) { return ImeControl(hwnd, IMC_SETOPENSTATUS, open); }
        public static int GetMode(IntPtr hwnd) { return ImeControl(hwnd, IMC_GETCONVERSIONMODE, 0); }
        public static int SetMode(IntPtr hwnd, int mode) { return ImeControl(hwnd, IMC_SETCONVERSIONMODE, mode); }

        public static void SaveScreen(int x, int y, int w, int h, string path)
        {
            using (var bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb))
            using (var g = Graphics.FromImage(bmp))
            {
                g.CopyFromScreen(x, y, 0, 0, new Size(w, h), CopyPixelOperation.SourceCopy);
                bmp.Save(path, ImageFormat.Png);
            }
        }
    }
}
'@
}

$VK = @{ G = 0x47; K = 0x4B; S = 0x53; R = 0x52; SPACE = 0x20; ESC = 0x1B; HANJA = 0x19 }

$out = [System.IO.Path]::GetFullPath($OutDir, (Get-Location).Path)
if (-not (Test-Path -LiteralPath $out)) { New-Item -ItemType Directory -Path $out -Force | Out-Null }
$stdout = Join-Path $out 'r6-stdout.txt'
$result = [ordered]@{ startedAt = (Get-Date).ToString('o'); pid = $null; hwnd = $null; layout = $null; fields = [ordered]@{}; blocked = $null; errors = @() }

$script:hwnd = [IntPtr]::Zero
$script:appPid = 0

function Assert-Target([int]$X, [int]$Y, [string]$What) {
    if ([WgIme.Native]::GetForegroundWindow() -ne $script:hwnd) {
        [void][WgIme.Native]::SetForegroundWindow($script:hwnd)
        Start-Sleep -Milliseconds 300
    }
    if ([WgIme.Native]::GetForegroundWindow() -ne $script:hwnd) { throw "${What}: 대상 창을 전면으로 가져오지 못했다. 입력을 보내지 않고 중단한다" }
    if ($X -ge 0) {
        $root = [WgIme.Native]::RootAt($X, $Y)
        if ($root -ne $script:hwnd) { throw ("{0}: 커서 위치 ({1},{2}) 아래 창이 대상 창이 아니다. 입력을 보내지 않고 중단한다" -f $What, $X, $Y) }
    }
}

function Assert-Foreground([string]$What) { Assert-Target -1 -1 $What }

function Send-Keys([string]$What, [int[]]$Keys) {
    foreach ($k in $Keys) {
        Assert-Foreground $What
        [WgIme.Native]::Key([uint16]$k)
    }
}

function Save-Window([string]$Name) {
    $png = Join-Path $out "$Name.png"
    $expected = '0x{0:X}' -f $script:hwnd.ToInt64()
    $raw = & pwsh -NoProfile -File $CaptureScript -Hwnd $expected -Out $png -Method PrintWindow
    $text = ($raw | Out-String)
    Set-Content -LiteralPath (Join-Path $out "$Name.json") -Value $text -Encoding utf8
    $obj = $text | ConvertFrom-Json
    if ($obj.hwnd -ne $expected -or $obj.pid -ne $script:appPid) { throw "capture ${Name}: 고정한 창과 다른 창을 찍었다" }
    if (-not $obj.capture.ok) { throw "capture $Name 실패: $($obj.capture.error)" }
    return $obj
}

function Get-DevLines([string]$Pattern) {
    @(Get-Content -LiteralPath $stdout -ErrorAction SilentlyContinue | Where-Object { $_ -match $Pattern })
}

function Parse-Bounds([string]$Text) {
    $v = $Text.Split(',') | ForEach-Object { [double]$_ }
    [ordered]@{ x = $v[0]; y = $v[1]; w = $v[2]; h = $v[3] }
}

$prev = [WgIme.Native]::SetThreadDpiAwarenessContext([WgIme.Native]::DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)
$proc = $null
try {
    $existing = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
    if ($existing.Count -gt 0) { throw "이미 실행 중인 $ProcessName 가 있다 (PID $($existing.Id -join ', ')). 닫고 다시 실행하라" }

    $exePath = (Resolve-Path -LiteralPath $Exe).Path
    $proc = Start-Process -FilePath $exePath -ArgumentList '--dev-editor-poc' -RedirectStandardOutput $stdout -PassThru
    $script:appPid = $proc.Id
    $result.pid = $proc.Id
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt 20 -and ((Get-DevLines '^\[dev\] layout ').Count -eq 0)) { Start-Sleep -Milliseconds 200 }
    # 함수 반환은 한 개짜리 배열을 문자열로 풀어 버리므로 @() 로 다시 감싼 뒤 [0] 을 쓴다.
    $layoutLine = @(Get-DevLines '^\[dev\] layout ')[0]
    if (-not $layoutLine) { throw '20초 안에 [dev] layout 줄이 나오지 않았다' }
    $script:hwnd = [WgIme.Native]::FindTitled([uint32]$proc.Id, $AppTitle)
    if ($script:hwnd -eq [IntPtr]::Zero) { throw '앱 메인 창을 찾지 못했다' }
    $result.hwnd = '0x{0:X}' -f $script:hwnd.ToInt64()

    [void]($layoutLine -match 'editor=(\S+)'); $editorB = Parse-Bounds $Matches[1]
    [void]($layoutLine -match 'input=(\S+)'); $inputB = Parse-Bounds $Matches[1]
    $base = Save-Window 'r6-start'
    $s = [double]$base.scale
    $result.layout = [ordered]@{ line = $layoutLine; scale = $s; clientRect = $base.clientRect }

    $mon = $base.monitor.rect
    $fields = @(
        # Editor: 4번째 줄(빈 줄, 0부터 3) 가운데. 편집기 위 끝 + 3.5 줄. 줄 높이 20 논리 px(r10 측정값).
        [ordered]@{ name = 'editor'; x = $editorB.x + 80; y = $editorB.y + 3 * 20 + 10; expect = '한 가나 ' }
        [ordered]@{ name = 'input'; x = $inputB.x + 40; y = $inputB.y + $inputB.h / 2; expect = '한 가나 ' }
    )

    foreach ($f in $fields) {
        $fr = [ordered]@{}
        $sx = [int]($base.clientRect.x + $f.x * $s); $sy = [int]($base.clientRect.y + $f.y * $s)
        $fr.clickScreen = @($sx, $sy)
        Assert-Target $sx $sy "$($f.name) 클릭"
        [WgIme.Native]::Click($sx, $sy)
        Start-Sleep -Milliseconds 400

        # IME 를 열고 한글 모드로 둔다.
        $fr.imeWnd = '0x{0:X}' -f [WgIme.Native]::DefaultImeWnd($script:hwnd)
        $fr.openBefore = [WgIme.Native]::GetOpen($script:hwnd)
        $fr.modeBefore = [WgIme.Native]::GetMode($script:hwnd)
        [void][WgIme.Native]::SetOpen($script:hwnd, 1)
        [void][WgIme.Native]::SetMode($script:hwnd, [WgIme.Native]::IME_CMODE_NATIVE)
        Start-Sleep -Milliseconds 200
        $fr.openAfter = [WgIme.Native]::GetOpen($script:hwnd)
        $fr.modeAfter = [WgIme.Native]::GetMode($script:hwnd)
        # 조회 실패는 음수(int.MinValue: IME 창 없음, int.MinValue+1: SendMessageTimeout 실패)다.
        # 음수에 비트 검사를 하면 한글 모드로 잘못 볼 수 있으므로 실패값과 열림 상태를 먼저 본다.
        $reason = $null
        if ($fr.openAfter -lt 0 -or $fr.modeAfter -lt 0) {
            $reason = "IME 상태 조회 실패 (open=$($fr.openAfter) mode=$($fr.modeAfter), 음수는 조회 실패값)"
        } elseif ($fr.openAfter -ne 1) {
            $reason = "IME 가 열리지 않았다 (open=$($fr.openAfter))"
        } elseif (($fr.modeAfter -band [WgIme.Native]::IME_CMODE_NATIVE) -ne [WgIme.Native]::IME_CMODE_NATIVE) {
            $reason = "IME 변환 모드가 한글이 아니다 (mode=$($fr.modeAfter))"
        }
        $fr.hangulMode = ($null -eq $reason)
        if ($reason) {
            $result.blocked = "$($f.name): $reason"
            $result.fields[$f.name] = $fr
            break
        }

        # 1) 조합 중: ㅎ ㅏ ㄴ → "한" (확정 전)
        $valuesBefore = (Get-DevLines "^\[dev\] value field=$($f.name)").Count
        Send-Keys "$($f.name) 조합" @($VK.G, $VK.K, $VK.S)
        Start-Sleep -Milliseconds 500
        [void](Save-Window "r6-$($f.name)-composing")
        $fr.composingScreenshot = "r6-$($f.name)-composing.png"
        $fr.valueLinesWhileComposing = @(Get-DevLines "^\[dev\] value field=$($f.name)" | Select-Object -Skip $valuesBefore)

        # 2) 후보창: 한자 키
        $before = [WgIme.Native]::VisibleTopLevel() | ForEach-Object { $_.Hwnd }
        Send-Keys "$($f.name) 한자" @($VK.HANJA)
        Start-Sleep -Milliseconds 800
        [WgIme.Native]::SaveScreen($mon.x, $mon.y, $mon.width, $mon.height, (Join-Path $out "r6-$($f.name)-candidate.png"))
        $fr.candidateScreenshot = "r6-$($f.name)-candidate.png"
        $fr.newWindowsAfterHanja = @([WgIme.Native]::VisibleTopLevel() | Where-Object { $before -notcontains $_.Hwnd } |
            ForEach-Object { [ordered]@{ hwnd = '0x{0:X}' -f $_.Hwnd; class = $_.Class; title = $_.Title; pid = $_.Pid; rect = @($_.X, $_.Y, $_.W, $_.H) } })
        Send-Keys "$($f.name) 후보창 닫기" @($VK.ESC)
        Start-Sleep -Milliseconds 300

        # 3) 확정: Space, 이어서 ㄱ ㅏ ㄴ ㅏ → "가나", Space
        Send-Keys "$($f.name) 확정" @($VK.SPACE, $VK.R, $VK.K, $VK.S, $VK.K, $VK.SPACE)
        Start-Sleep -Milliseconds 600
        [void](Save-Window "r6-$($f.name)-committed")
        $fr.committedScreenshot = "r6-$($f.name)-committed.png"
        $last = (Get-DevLines "^\[dev\] value field=$($f.name)" | Select-Object -Last 1)
        $fr.lastValueLine = $last
        $fr.expectedSubstring = $f.expect
        $fr.committedTextFound = ($null -ne $last -and $last.Contains($f.expect))
        if (-not $fr.committedTextFound) {
            $result.errors += "$($f.name): 확정 글자 '$($f.expect)' 가 값에 없다 (마지막 값 줄: $last)"
        }
        # 조합 중 표시와 후보창 위치는 자동 판정이 없다. 스크린샷을 보고 사람이(또는 검증 담당이) 판정한다.
        $fr.visualCheck = [ordered]@{
            status = '수동 판정 대기'
            composing = "$($fr.composingScreenshot): 조합 중 글자 '한' 이 밑줄과 함께 입력 위치에 보이는가"
            candidate = "$($fr.candidateScreenshot): 한자 후보창이 조합 중 글자 바로 아래에 붙어 뜨는가"
        }
        $result.fields[$f.name] = $fr
    }
}
catch {
    $result.errors += $_.Exception.Message
}
finally {
    [void][WgIme.Native]::SetThreadDpiAwarenessContext($prev)
    if ($proc -and -not $proc.HasExited) {
        try { [void]$proc.CloseMainWindow(); [void]$proc.WaitForExit(5000) } catch {}
        if (-not $proc.HasExited) { try { $proc.Kill(); [void]$proc.WaitForExit(3000) } catch {} }
    }
}

$result.finishedAt = (Get-Date).ToString('o')
$result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $out 'r6-ime.json') -Encoding utf8
Get-Content -LiteralPath (Join-Path $out 'r6-ime.json') -Raw
if ($result.errors.Count -gt 0 -or $result.blocked) { exit 1 }

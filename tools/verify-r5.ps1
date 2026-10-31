#Requires -Version 7
<#
.SYNOPSIS
  SPEC R-5 (G-128) 증거: TaskDialog 호출과 260자 넘는 경로 열기 결과를 저장한다.

.DESCRIPTION
  - --dev-taskdialog: 앱을 띄우고 TaskDialog 창(#32770)이 뜨면 화면을 찍은 뒤 WM_CLOSE 로 닫는다.
    앱 표준출력을 r5-taskdialog.txt 에, 스크린샷을 r5-taskdialog.png 에 저장한다.
  - --dev-open-longpath: %TEMP% 아래에 260자 넘는 경로의 임시 파일을 만들고 앱에 넘긴다.
    앱 표준출력을 r5-longpath.txt 에 저장하고, 끝나면 만든 임시 폴더만 지운다.
  150% 배율 시험은 시스템 설정 변경이라 이 스크립트에 넣지 않는다.

.EXAMPLE
  pwsh -NoProfile -File tools/verify-r5.ps1
#>
[CmdletBinding()]
param(
    [string]$Exe = 'target\debug\workbench-gpui.exe',
    [string]$OutDir = 'specs\v0.1\verify\phase1'
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing.Common
Add-Type -AssemblyName System.Drawing.Primitives

if (-not ('WgR5.Native' -as [type])) {
    $refs = @(
        'System.Runtime'
        'System.Collections'
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

namespace WgR5
{
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }

    public static class Native
    {
        public static readonly IntPtr DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = new IntPtr(-4);
        const uint WM_CLOSE = 0x0010;
        public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

        [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr ctx);
        [DllImport("user32.dll")] static extern bool EnumWindows(EnumWindowsProc cb, IntPtr lParam);
        [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
        [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr hWnd);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetClassName(IntPtr hWnd, StringBuilder sb, int max);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr hWnd, StringBuilder sb, int max);
        [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")] static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr w, IntPtr l);
        [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
        [DllImport("dwmapi.dll")] static extern int DwmGetWindowAttribute(IntPtr hWnd, int attr, out RECT r, int size);

        // 프로세스의 보이는 최상위 창 중 클래스가 className 인 것.
        public static IntPtr FindWindowOfClass(uint pid, string className)
        {
            IntPtr found = IntPtr.Zero;
            EnumWindows((h, l) =>
            {
                uint p;
                GetWindowThreadProcessId(h, out p);
                if (p != pid || !IsWindowVisible(h)) return true;
                var sb = new StringBuilder(256);
                GetClassName(h, sb, sb.Capacity);
                if (sb.ToString() == className) { found = h; return false; }
                return true;
            }, IntPtr.Zero);
            return found;
        }

        public static string Title(IntPtr h)
        {
            var sb = new StringBuilder(512);
            GetWindowText(h, sb, sb.Capacity);
            return sb.ToString();
        }

        public static RECT Bounds(IntPtr h)
        {
            RECT r;
            if (DwmGetWindowAttribute(h, 9, out r, Marshal.SizeOf(typeof(RECT))) != 0) GetWindowRect(h, out r);
            return r;
        }

        public static void Close(IntPtr h) { PostMessage(h, WM_CLOSE, IntPtr.Zero, IntPtr.Zero); }

        public static void SaveScreen(RECT r, string path)
        {
            int w = r.Right - r.Left, ht = r.Bottom - r.Top;
            using (var bmp = new Bitmap(w, ht, PixelFormat.Format32bppArgb))
            using (var g = Graphics.FromImage(bmp))
            {
                g.CopyFromScreen(r.Left, r.Top, 0, 0, new Size(w, ht), CopyPixelOperation.SourceCopy);
                bmp.Save(path, ImageFormat.Png);
            }
        }
    }
}
'@
}

$exePath = (Resolve-Path -LiteralPath $Exe).Path
$outPath = [System.IO.Path]::GetFullPath($OutDir, (Get-Location).Path)
if (-not (Test-Path -LiteralPath $outPath)) { New-Item -ItemType Directory -Path $outPath -Force | Out-Null }

function Stop-App($proc) {
    if ($proc -and -not $proc.HasExited) {
        try { [void]$proc.CloseMainWindow(); [void]$proc.WaitForExit(3000) } catch {}
        if (-not $proc.HasExited) { try { $proc.Kill(); [void]$proc.WaitForExit(3000) } catch {} }
    }
}

function Wait-Line([string]$File, [string]$Pattern, [int]$TimeoutMs) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.ElapsedMilliseconds -lt $TimeoutMs) {
        if ((Test-Path -LiteralPath $File) -and (Select-String -LiteralPath $File -Pattern $Pattern -Quiet)) { return $true }
        Start-Sleep -Milliseconds 200
    }
    return $false
}

$prev = [WgR5.Native]::SetThreadDpiAwarenessContext([WgR5.Native]::DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)

# ---- 1) 긴 경로 ----
$longOut = Join-Path $outPath 'r5-longpath.txt'
$root = Join-Path $env:TEMP ('wg-longpath-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
$dir = $root
while ($dir.Length -lt 280) { $dir = Join-Path $dir ('d' * 40) }
$longFile = Join-Path $dir 'long-path-test.txt'
try {
    # .NET 은 긴 경로를 스스로 처리하므로 PowerShell 로는 만들 수 있다.
    [System.IO.Directory]::CreateDirectory($dir) | Out-Null
    [System.IO.File]::WriteAllText($longFile, 'r5')
    $p = Start-Process -FilePath $exePath -ArgumentList @('--dev-open-longpath', "`"$longFile`"") `
        -RedirectStandardOutput $longOut -PassThru -WindowStyle Normal
    $ok = Wait-Line $longOut '\[dev\] longpath' 15000
    Stop-App $p
    Add-Content -LiteralPath $longOut -Value "path_length_chars=$($longFile.Length)" -Encoding utf8
    Add-Content -LiteralPath $longOut -Value "path=$longFile" -Encoding utf8
    if (-not $ok) { Add-Content -LiteralPath $longOut -Value 'script: [dev] longpath 줄이 15초 안에 나오지 않았다' -Encoding utf8 }
}
finally {
    if (Test-Path -LiteralPath $root) { [System.IO.Directory]::Delete($root, $true) }
}

# ---- 2) TaskDialog ----
$tdOut = Join-Path $outPath 'r5-taskdialog.txt'
$tdPng = Join-Path $outPath 'r5-taskdialog.png'
$p = Start-Process -FilePath $exePath -ArgumentList @('--dev-taskdialog') `
    -RedirectStandardOutput $tdOut -PassThru -WindowStyle Normal
$dlg = [IntPtr]::Zero
$sw = [System.Diagnostics.Stopwatch]::StartNew()
while ($sw.ElapsedMilliseconds -lt 15000 -and $dlg -eq [IntPtr]::Zero) {
    Start-Sleep -Milliseconds 200
    if ($p.HasExited) { break }
    $dlg = [WgR5.Native]::FindWindowOfClass([uint32]$p.Id, '#32770')
}
$notes = @()
if ($dlg -ne [IntPtr]::Zero) {
    Start-Sleep -Milliseconds 500
    [void][WgR5.Native]::SetForegroundWindow($dlg)
    Start-Sleep -Milliseconds 400
    $fg = ([WgR5.Native]::GetForegroundWindow() -eq $dlg)
    $r = [WgR5.Native]::Bounds($dlg)
    [WgR5.Native]::SaveScreen($r, $tdPng)
    $notes += "script: dialog_found=true class=#32770 title=$([WgR5.Native]::Title($dlg)) foreground=$fg rect=$($r.Left),$($r.Top),$($r.Right - $r.Left)x$($r.Bottom - $r.Top) screenshot=r5-taskdialog.png"
    [WgR5.Native]::Close($dlg)
    if (-not (Wait-Line $tdOut '\[dev\] taskdialog' 5000)) { $notes += 'script: 닫은 뒤 [dev] taskdialog 줄이 5초 안에 나오지 않았다' }
} else {
    [void](Wait-Line $tdOut '\[dev\] taskdialog' 3000)
    $notes += 'script: dialog_found=false (15초 안에 #32770 창이 뜨지 않았다)'
}
Stop-App $p
foreach ($n in $notes) { Add-Content -LiteralPath $tdOut -Value $n -Encoding utf8 }

[void][WgR5.Native]::SetThreadDpiAwarenessContext($prev)

"---- r5-longpath.txt ----"
Get-Content -LiteralPath $longOut
"---- r5-taskdialog.txt ----"
Get-Content -LiteralPath $tdOut

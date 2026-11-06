# I-9 Zed scrollbar check: launch Zed on a file, size client 1440x852, drive mouse, capture screen at timed points.
# Only touches the Zed window it launched itself (new PID not present before launch).
param([string]$Out = 'D:\projects\workbench-gpui\specs\v0.5\verify\reviews\zed-ORDER-03\i9')
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force $Out | Out-Null
Add-Type @'
using System; using System.Runtime.InteropServices;
public static class ZI {
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, int dx, int dy, int data, IntPtr extra);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
  [DllImport("user32.dll")] public static extern bool SetThreadDpiAwarenessContext(IntPtr c);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
}
'@
[void][ZI]::SetThreadDpiAwarenessContext([IntPtr]::new(-4))
$log = Join-Path $Out 'log.txt'
function L($m) { $s = "$(Get-Date -Format HH:mm:ss.fff) $m"; $s | Add-Content $log; $s }

$before = @(Get-Process -Name Zed -ErrorAction SilentlyContinue | ForEach-Object Id)
L "zed pids before: $($before -join ',')"
Start-Process 'C:\Users\nampl\AppData\Local\Programs\Zed\Zed.exe' -ArgumentList '"D:\projects\workbench-gpui\specs\v0.5\SPEC.md"'
$hwnd = [IntPtr]::Zero; $mine = $null
foreach ($i in 1..60) {
  Start-Sleep -Milliseconds 500
  $p = Get-Process -Name Zed -ErrorAction SilentlyContinue | Where-Object { $before -notcontains $_.Id -and $_.MainWindowHandle -ne 0 } | Select-Object -First 1
  if ($p) { $mine = $p.Id; $hwnd = $p.MainWindowHandle; break }
}
if (-not $mine) { L 'no new Zed window found'; exit 1 }
L "launched zed pid=$mine hwnd=$hwnd"
Start-Sleep -Seconds 3
& pwsh -NoProfile -File D:\projects\workbench-gpui\tools\measure\window-rect.ps1 -TargetHwnd ("0x{0:X}" -f $hwnd.ToInt64()) -Action Resize -X 232 -Y 90 -Width 1456 -Height 860 2>&1 | ForEach-Object { L "resize: $_" }
Start-Sleep -Seconds 2
$r = New-Object ZI+RECT; [void][ZI]::GetClientRect($hwnd, [ref]$r)
$o = New-Object ZI+POINT; [void][ZI]::ClientToScreen($hwnd, [ref]$o)
L "client origin=($($o.X),$($o.Y)) size=$($r.R)x$($r.B)"
# editor body point: center-right of client (inside text area, away from panels)
$ex = $o.X + [int]($r.R * 0.6); $ey = $o.Y + [int]($r.B * 0.5)
function Cap($name) { & pwsh -NoProfile -File D:\projects\workbench-gpui\tools\capture.ps1 -Hwnd ("0x{0:X}" -f $hwnd.ToInt64()) -Method Screen -Out (Join-Path $Out "$name.png") *> $null; L "capture $name exit=$LASTEXITCODE" }
[void][ZI]::SetForegroundWindow($hwnd)
[void][ZI]::SetCursorPos(5, 5); Start-Sleep -Seconds 2; Cap 'a-outside'
[void][ZI]::SetCursorPos($ex, $ey); Start-Sleep -Milliseconds 300; [void][ZI]::SetCursorPos($ex + 3, $ey + 3); Start-Sleep -Seconds 2; Cap 'b-hover-2s'
foreach ($k in 1..3) { [ZI]::mouse_event(0x0800, 0, 0, -120, [IntPtr]::Zero); Start-Sleep -Milliseconds 80 }
L 'wheel done'; Cap 'c-scrolling'
Start-Sleep -Milliseconds 500; Cap 'd-after-0.5s'
Start-Sleep -Milliseconds 700; Cap 'd-after-1.2s'
Start-Sleep -Milliseconds 1000; Cap 'd-after-2.2s'
Start-Sleep -Seconds 2; Cap 'd-after-4.2s'
[void][ZI]::SetCursorPos(5, 5); Start-Sleep -Seconds 2; Cap 'e-outside-after'
# close only the window/process this script launched
& pwsh -NoProfile -File D:\projects\workbench-gpui\tools\measure\window-rect.ps1 -TargetHwnd ("0x{0:X}" -f $hwnd.ToInt64()) -Action Close 2>&1 | ForEach-Object { L "close: $_" }
Start-Sleep -Seconds 3
$left = @(Get-Process -Name Zed -ErrorAction SilentlyContinue | Where-Object { $before -notcontains $_.Id } | ForEach-Object Id)
L "new zed pids remaining: $($left -join ',')"

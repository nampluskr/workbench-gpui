#Requires -Version 7
# shortcut: assumes primary monitor at 100% DPI (AGENTS 3A.4); box coordinates are used as screen pixels, add DPI/monitor offset handling if that changes.
param([ValidateSet('Check','DismissOpenWith','Maximize','Click','DoubleClick','RightClick','Hover','Key','Wheel')][string]$Action,[string]$Box,[double]$X=-1,[double]$Y=-1,[string]$Key,[string]$Out='D:\projects\workbench-gpui\specs\v0.3\verify\reviews\p0-measure')
$ErrorActionPreference='Stop'
Set-Location 'D:\projects\workbench-gpui'
# Reuse only the existing native input declaration, never execute the test harness.
$tokens=$null; $parseErrors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path (Get-Location) 'tools/verify-v02-phase4.ps1'),[ref]$tokens,[ref]$parseErrors)
if ($parseErrors.Count) { throw 'Existing harness parse failed' }
$native=$ast.FindAll({param($n) $n -is [Management.Automation.Language.IfStatementAst] -and $n.Extent.Text.StartsWith("if (-not ('WgP4.Native'")},$true)
if ($native.Count -ne 1) { throw 'Native declaration is not unique' }
Invoke-Expression ($native[0].Extent.Text.Replace('static extern uint GetWindowThreadProcessId','public static extern uint GetWindowThreadProcessId'))
[void][WgP4.Native]::SetThreadDpiAwarenessContext([IntPtr]::new(-4))
$out = $Out
$session=Get-Content -Raw (Join-Path $out 'session.json') | ConvertFrom-Json
$handle=[WgP4.Native]::FindTitled($session.pid,'workbench-gpui')
if ($handle -eq [IntPtr]::Zero) { throw 'Measurement window not found' }
if ($Action -eq 'DismissOpenWith') {
 $foreground=[WgP4.Native]::GetForegroundWindow(); [uint32]$owner=0
 [void][WgP4.Native]::GetWindowThreadProcessId($foreground,[ref]$owner)
 if ([WgP4.Native]::ClassOf($foreground) -ne 'Open With' -or (Get-Process -Id $owner).ProcessName -ne 'OpenWith') { throw 'Unexpected foreground; no input sent' }
 [WgP4.Native]::Combo([uint16[]]@(),[uint16]0x1B)
 Start-Sleep -Milliseconds 500
 exit
}
if ($Action -eq 'Check') {
 $foreground=[WgP4.Native]::GetForegroundWindow(); [uint32]$owner=0
 [void][WgP4.Native]::GetWindowThreadProcessId($foreground,[ref]$owner)
 "foreground=$foreground class=$([WgP4.Native]::ClassOf($foreground)) title=$([WgP4.Native]::Title($foreground)) owner=$owner process=$((Get-Process -Id $owner).ProcessName)"
 exit
}
if ($Action -eq 'Maximize') { [void][WgP4.Native]::ShowWindow($handle,3); exit }
if (-not [WgP4.Native]::IsZoomed($handle)) { throw 'Window must remain maximized' }
[WgP4.Native]::Activate($handle)
Start-Sleep -Milliseconds 300
if ([WgP4.Native]::GetForegroundWindow() -ne $handle) { [WgP4.Native]::ActivateAlt($handle); Start-Sleep -Milliseconds 400 }
if ([WgP4.Native]::GetForegroundWindow() -ne $handle) { throw "Measurement window is not foreground: target=$handle foreground=$([WgP4.Native]::GetForegroundWindow()) title=$([WgP4.Native]::Title([WgP4.Native]::GetForegroundWindow()))" }
if ($Action -eq 'Key') {
 $keys=@{escape=0x1B;f2=0x71;f10=0x79;enter=0x0D;right=0x27;down=0x28}
 if (-not $keys.ContainsKey($Key)) { throw 'Key outside measurement states' }
 [WgP4.Native]::Combo([uint16[]]@(),[uint16]$keys[$Key])
} else {
 if ($Box) {
  $lines=@(Get-Content (Join-Path $out 'app-stdout.txt') -Encoding utf8)
  $ends=@($lines | Where-Object {$_ -match '^\[dev\] layout-snapshot-end seq='})
  if (-not $ends.Count) { throw 'No complete dump' }
  [void]($ends[-1] -match 'seq=(\d+)'); $seq=$matches[1]
  $rows=@($lines | Where-Object {$_ -match "^\[dev\] layout-box seq=$seq name=$([regex]::Escape($Box)) bounds="})
  if ($rows.Count -ne 1) { throw "Missing box $Box" }
  [void]($rows[0] -match 'bounds=([-\d.]+),([-\d.]+),([-\d.]+),([-\d.]+)')
  $X=[double]$matches[1]+[double]$matches[3]/2; $Y=[double]$matches[2]+[double]$matches[4]/2
 }
 if ($X -lt 0 -or $Y -lt 0 -or [WgP4.Native]::RootAt([int]$X,[int]$Y) -ne $handle) { throw 'Point is outside the target window' }
 switch ($Action) {
  Click {[WgP4.Native]::Click([int]$X,[int]$Y)}
  DoubleClick {[WgP4.Native]::DoubleClick([int]$X,[int]$Y)}
  RightClick {[WgP4.Native]::RightClick([int]$X,[int]$Y)}
  Hover {[WgP4.Native]::MoveTo([int]$X,[int]$Y)}
  Wheel {[WgP4.Native]::MoveTo([int]$X,[int]$Y); Start-Sleep -Milliseconds 100; foreach ($k in 1..3) { [WgP4.Native]::Wheel([int]$X,[int]$Y,-120); Start-Sleep -Milliseconds 100 }}
 }
}
Start-Sleep -Milliseconds 700
"$Action $Box $Key at $X,$Y" | Add-Content (Join-Path $out 'actions.log')

#Requires -Version 7
# P3-E V3 helper: type text or send one key combo into the measurement window. Reuses the native declaration of tools/verify-v02-phase4.ps1 like tools/measure/input.ps1.
param([ValidateSet('Type','Combo')][string]$Action, [string]$Text, [string]$Mods = '', [string]$Key = '', [string]$Out = 'D:\projects\workbench-gpui\specs\v0.4\verify\reviews\measure-phase3')
$ErrorActionPreference = 'Stop'
$tokens = $null; $parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile('D:\projects\workbench-gpui\tools\verify-v02-phase4.ps1', [ref]$tokens, [ref]$parseErrors)
$native = $ast.FindAll({ param($n) $n -is [Management.Automation.Language.IfStatementAst] -and $n.Extent.Text.StartsWith("if (-not ('WgP4.Native'") }, $true)
Invoke-Expression ($native[0].Extent.Text.Replace('static extern uint GetWindowThreadProcessId', 'public static extern uint GetWindowThreadProcessId'))
[void][WgP4.Native]::SetThreadDpiAwarenessContext([IntPtr]::new(-4))
$session = Get-Content -Raw (Join-Path $Out 'session.json') | ConvertFrom-Json
$handle = [WgP4.Native]::FindTitled($session.pid, 'workbench-gpui')
if ($handle -eq [IntPtr]::Zero) { throw 'Measurement window not found' }
[WgP4.Native]::Activate($handle); Start-Sleep -Milliseconds 300
if ([WgP4.Native]::GetForegroundWindow() -ne $handle) { [WgP4.Native]::ActivateAlt($handle); Start-Sleep -Milliseconds 400 }
if ([WgP4.Native]::GetForegroundWindow() -ne $handle) { throw 'Measurement window is not foreground' }
$vk = @{ ctrl = 0x11; shift = 0x10; alt = 0x12 }
if ($Action -eq 'Type') { [WgP4.Native]::TypeText($Text) }
else {
    $m = @(); foreach ($x in ($Mods -split ',' | ? { $_ })) { $m += [uint16]$vk[$x] }
    $k = if ($Key.Length -eq 1) { [uint16][char]$Key.ToUpper() } else { [uint16]$Key }
    [WgP4.Native]::Combo([uint16[]]$m, $k)
}
Start-Sleep -Milliseconds 700
"$Action $Text $Mods $Key" | Add-Content (Join-Path $Out 'actions.log')

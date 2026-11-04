#Requires -Version 7
# P4-E V3 helper: left-button hold-drag in steps so a capture can be taken mid-drag. Reuses the native declaration of tools/verify-v02-phase4.ps1.
# -Phase Down: move to (X,Y) and press. Move: move in 10 steps from (X0,Y0) to (X,Y) with the button down. Up: release at (X,Y).
param([ValidateSet('Down','Move','Up')][string]$Phase,[int]$X,[int]$Y,[int]$X0=0,[int]$Y0=0,[string]$Out='D:\projects\workbench-gpui\specs\v0.4\verify\reviews\measure-phase4')
$ErrorActionPreference='Stop'
$ast=[Management.Automation.Language.Parser]::ParseFile('D:\projects\workbench-gpui\tools\verify-v02-phase4.ps1',[ref]$null,[ref]$null)
$native=$ast.FindAll({param($n) $n -is [Management.Automation.Language.IfStatementAst] -and $n.Extent.Text.StartsWith("if (-not ('WgP4.Native'")},$true)
Invoke-Expression ($native[0].Extent.Text.Replace('static extern uint GetWindowThreadProcessId','public static extern uint GetWindowThreadProcessId'))
[void][WgP4.Native]::SetThreadDpiAwarenessContext([IntPtr]::new(-4))
Add-Type -Namespace WgHold -Name M -MemberDefinition '[System.Runtime.InteropServices.DllImport("user32.dll")] public static extern void mouse_event(uint f,uint dx,uint dy,uint d,System.UIntPtr e);'
$session=Get-Content -Raw (Join-Path $Out 'session.json')|ConvertFrom-Json
$h=[WgP4.Native]::FindTitled($session.pid,'workbench-gpui')
[WgP4.Native]::Activate($h); Start-Sleep -Milliseconds 300
if ([WgP4.Native]::GetForegroundWindow() -ne $h) { throw 'not foreground' }
if ([WgP4.Native]::RootAt($X,$Y) -ne $h) { throw 'point outside window' }
switch($Phase){
 'Down' { [WgP4.Native]::MoveTo($X,$Y); Start-Sleep -Milliseconds 200; [WgHold.M]::mouse_event(0x2,0,0,0,[UIntPtr]::Zero) }
 'Move' { foreach($n in 1..10){ [WgP4.Native]::MoveTo([int]($X0+($X-$X0)*$n/10),[int]($Y0+($Y-$Y0)*$n/10)); Start-Sleep -Milliseconds 60 } }
 'Up'   { [WgP4.Native]::MoveTo($X,$Y); Start-Sleep -Milliseconds 100; [WgHold.M]::mouse_event(0x4,0,0,0,[UIntPtr]::Zero) }
}
"hold $Phase $X,$Y" | Add-Content (Join-Path $Out 'actions.log')

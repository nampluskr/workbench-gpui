param([string]$Out)
$tokens=$null;$pe=$null
$ast=[Management.Automation.Language.Parser]::ParseFile('D:\projects\workbench-gpui\tools\verify-v02-phase4.ps1',[ref]$tokens,[ref]$pe)
$n=$ast.FindAll({param($x) $x -is [Management.Automation.Language.IfStatementAst] -and $x.Extent.Text.StartsWith("if (-not ('WgP4.Native'")},$true)
Invoke-Expression ($n[0].Extent.Text.Replace('static extern uint GetWindowThreadProcessId','public static extern uint GetWindowThreadProcessId'))
[void][WgP4.Native]::SetThreadDpiAwarenessContext([IntPtr]::new(-4))
$session=Get-Content -Raw "$Out\session.json"|ConvertFrom-Json
$d=[WgP4.Native]::FindDialog([uint32]$session.pid)
"dialog=$d class=$([WgP4.Native]::ClassOf($d)) title=$([WgP4.Native]::Title($d))"
if($d -ne [IntPtr]::Zero){ & pwsh -NoProfile -File D:\projects\workbench-gpui\tools\capture.ps1 -Hwnd $d -Out "$Out\closesave-dialog.png" -Method PrintWindow }

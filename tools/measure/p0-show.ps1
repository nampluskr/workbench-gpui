#Requires -Version 7
$session=Get-Content -Raw 'D:\projects\workbench-gpui\specs\v0.3\verify\reviews\p0-measure\session.json' | ConvertFrom-Json
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class P0Show {
 public delegate bool Callback(IntPtr h, IntPtr p);
 [DllImport("user32.dll")] public static extern bool EnumWindows(Callback cb, IntPtr p);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
 public static IntPtr Find(uint pid) {
  IntPtr found=IntPtr.Zero;
  EnumWindows((h,p)=>{uint id; GetWindowThreadProcessId(h,out id); if(id==pid) {found=h;return false;}return true;},IntPtr.Zero);
  return found;
 }
}
'@
$handle=[P0Show]::Find($session.pid)
if ($handle -eq [IntPtr]::Zero) { throw 'Existing measurement window not found; do not relaunch' }
[void][P0Show]::ShowWindow($handle,3)
"Existing window shown maximized: $handle"

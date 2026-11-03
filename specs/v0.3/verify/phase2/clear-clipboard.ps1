#Requires -Version 7
# H-28 helper: clear the OS clipboard (STA) and print the remaining format count.
Add-Type -AssemblyName System.Windows.Forms
try { [System.Windows.Forms.Clipboard]::Clear() } catch { }
Start-Sleep -Milliseconds 300
$src = @'
using System;using System.Runtime.InteropServices;
public static class Clip3{[DllImport("user32.dll")]public static extern bool OpenClipboard(IntPtr h);[DllImport("user32.dll")]public static extern bool CloseClipboard();[DllImport("user32.dll")]public static extern int CountClipboardFormats();}
'@
Add-Type -TypeDefinition $src
[void][Clip3]::OpenClipboard([IntPtr]::Zero); [Clip3]::CountClipboardFormats(); [void][Clip3]::CloseClipboard()

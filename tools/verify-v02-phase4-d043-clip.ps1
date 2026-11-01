#Requires -Version 7
<#
.SYNOPSIS
  v0.2 Phase 4 리뷰 1회차 ⑤(D-043) 재현: OS 클립보드에 이미지(CF_DIB)가 있을 때 시험 스크립트가 클립보드를 잃지 않는가.

.DESCRIPTION
  1. 지금 사용자 클립보드가 텍스트 형식(1·7·13·16)만이거나 비어 있을 때만 진행한다(아니면 아무것도 바꾸지 않고 멈춘다).
     글자(또는 빈 상태)를 저장한다.
  2. 1×1 이미지(CF_DIB)를 클립보드에 넣고 `-Before` 스크립트(고치기 전)를 `-Only tooltip` 으로 돌린다 → 끝난 뒤 형식을 본다.
  3. 다시 이미지를 넣고 `-After` 스크립트(고친 뒤)를 같은 방식으로 돌린다 → 끝난 뒤 형식을 본다.
  4. 사용자 클립보드를 1의 상태로 되돌린다.
  결과: <OutDir>\clip-results.json, clip-before\·clip-after\(각 스크립트 출력).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Before,
    [string]$After = 'tools\verify-v02-phase4.ps1',
    [string]$OutDir = 'specs\v0.2\verify\phase4\d043-rerun'
)
$ErrorActionPreference = 'Stop'
Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
namespace WgClipRepro {
    public static class C {
        [DllImport("user32.dll")] static extern bool OpenClipboard(IntPtr h);
        [DllImport("user32.dll")] static extern bool CloseClipboard();
        [DllImport("user32.dll")] static extern bool EmptyClipboard();
        [DllImport("user32.dll")] static extern uint EnumClipboardFormats(uint f);
        [DllImport("user32.dll")] static extern IntPtr SetClipboardData(uint f, IntPtr h);
        [DllImport("kernel32.dll")] static extern IntPtr GlobalAlloc(uint flags, UIntPtr size);
        [DllImport("kernel32.dll")] static extern IntPtr GlobalLock(IntPtr h);
        [DllImport("kernel32.dll")] static extern bool GlobalUnlock(IntPtr h);
        static void Open() { for (int i = 0; i < 40; i++) { if (OpenClipboard(IntPtr.Zero)) return; System.Threading.Thread.Sleep(50); } throw new InvalidOperationException("OpenClipboard"); }
        public static uint[] Formats() { Open(); var l = new List<uint>(); try { uint f = 0; while ((f = EnumClipboardFormats(f)) != 0) l.Add(f); } finally { CloseClipboard(); } return l.ToArray(); }
        public static void Empty() { Open(); try { EmptyClipboard(); } finally { CloseClipboard(); } }
        // 1×1 32비트 DIB(BITMAPINFOHEADER 40바이트 + 픽셀 4바이트).
        public static void SetDib() {
            var bytes = new byte[44];
            BitConverter.GetBytes(40).CopyTo(bytes, 0); BitConverter.GetBytes(1).CopyTo(bytes, 4); BitConverter.GetBytes(1).CopyTo(bytes, 8);
            BitConverter.GetBytes((short)1).CopyTo(bytes, 12); BitConverter.GetBytes((short)32).CopyTo(bytes, 14);
            bytes[40] = 0x20; bytes[41] = 0x40; bytes[42] = 0x80; bytes[43] = 0xFF;
            IntPtr h = GlobalAlloc(0x0002, (UIntPtr)bytes.Length); IntPtr p = GlobalLock(h); Marshal.Copy(bytes, 0, p, bytes.Length); GlobalUnlock(h);
            Open(); try { EmptyClipboard(); if (SetClipboardData(8, h) == IntPtr.Zero) throw new InvalidOperationException("SetClipboardData"); } finally { CloseClipboard(); }
        }
    }
}
'@
$text = @(1, 7, 13, 16)
$out = [System.IO.Path]::GetFullPath($OutDir, (Get-Location).Path)
New-Item -ItemType Directory -Path $out -Force | Out-Null
$res = [ordered]@{ startedAt = (Get-Date).ToString('o'); userFormatsBefore = @([WgClipRepro.C]::Formats()) }
if (@($res.userFormatsBefore | Where-Object { $text -notcontains $_ }).Count -gt 0) { throw '사용자 클립보드에 텍스트가 아닌 형식이 있어 아무것도 바꾸지 않고 멈춘다' }
$userEmpty = $res.userFormatsBefore.Count -eq 0
$userText = if ($userEmpty) { $null } else { Get-Clipboard -Raw }
try {
    foreach ($run in @(@('before', $Before), @('after', $After))) {
        [WgClipRepro.C]::SetDib()
        $fmt0 = @([WgClipRepro.C]::Formats())
        $log = & pwsh -NoProfile -Command "& '$($run[1])' -Only tooltip -OutDir '$(Join-Path $out ('clip-' + $run[0]))'" 2>&1 | ForEach-Object { "$_" }
        $fmt1 = @([WgClipRepro.C]::Formats())
        $res[$run[0]] = [ordered]@{ script = $run[1]; formatsSet = $fmt0; formatsAfterRun = $fmt1; imageKept = ($fmt1 -contains 8); output = @($log | Select-Object -Last 6) }
    }
}
finally {
    if ($userEmpty) { [WgClipRepro.C]::Empty() } else { Set-Clipboard -Value $userText }
    $res.userFormatsAfter = @([WgClipRepro.C]::Formats())
    $res.userRestored = if ($userEmpty) { $res.userFormatsAfter.Count -eq 0 } else { (Get-Clipboard -Raw) -eq $userText }
}
$res | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $out 'clip-results.json') -Encoding utf8
"before imageKept=$($res.before.imageKept) after imageKept=$($res.after.imageKept) userRestored=$($res.userRestored)"

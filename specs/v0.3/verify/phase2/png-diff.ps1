#Requires -Version 7
# P2-E: pixel diff of two same-size PNGs (max per-channel delta, count, bbox). Optional -Rect x,y,w,h limits the area.
param([string]$A, [string]$B, [int[]]$Rect)
Add-Type -AssemblyName System.Drawing.Common
function Px([string]$p) {
    $b = [Drawing.Bitmap]::new($p); $r = [Drawing.Rectangle]::new(0, 0, $b.Width, $b.Height)
    $d = $b.LockBits($r, 'ReadOnly', 'Format32bppArgb'); $a = [byte[]]::new($d.Stride * $b.Height)
    [Runtime.InteropServices.Marshal]::Copy($d.Scan0, $a, 0, $a.Length); $b.UnlockBits($d)
    @{ a = $a; w = $b.Width; h = $b.Height; s = $d.Stride }
}
$ia = Px $A; $ib = Px $B
if ($ia.w -ne $ib.w -or $ia.h -ne $ib.h) { "size differs $($ia.w)x$($ia.h) vs $($ib.w)x$($ib.h)"; return }
$rx, $ry, $rw, $rh = if ($Rect) { $Rect } else { 0, 0, $ia.w, $ia.h }
$n = 0; $x0 = 99999; $y0 = 99999; $x1 = -1; $y1 = -1; $md = 0
for ($y = $ry; $y -lt $ry + $rh; $y++) {
    $o = $y * $ia.s + $rx * 4; $len = $rw * 4
    $ra = [byte[]]::new($len); $rb = [byte[]]::new($len)
    [Array]::Copy($ia.a, $o, $ra, 0, $len); [Array]::Copy($ib.a, $o, $rb, 0, $len)
    if ([Linq.Enumerable]::SequenceEqual($ra, $rb)) { continue }
    for ($x = 0; $x -lt $rw; $x++) {
        $i = $x * 4
        $d = [Math]::Max([Math]::Max([Math]::Abs($ra[$i] - $rb[$i]), [Math]::Abs($ra[$i + 1] - $rb[$i + 1])), [Math]::Abs($ra[$i + 2] - $rb[$i + 2]))
        if ($d) { $n++; $px = $rx + $x; if ($px -lt $x0) { $x0 = $px }; if ($y -lt $y0) { $y0 = $y }; if ($px -gt $x1) { $x1 = $px }; if ($y -gt $y1) { $y1 = $y }; if ($d -gt $md) { $md = $d } }
    }
}
"diffpx=$n bbox=($x0,$y0)-($x1,$y1) maxchan=$md"

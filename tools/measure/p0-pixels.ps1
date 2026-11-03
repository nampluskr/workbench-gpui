#Requires -Version 7
$ErrorActionPreference='Stop'
$out='D:\projects\workbench-gpui\specs\v0.3\verify\reviews\p0-measure'
Add-Type -AssemblyName System.Drawing.Common
$state=Get-Content -Raw (Join-Path $out 'S7.json') | ConvertFrom-Json -AsHashtable
$row=$state.boxes['tree-row-04']
$bitmap=[Drawing.Bitmap]::new((Join-Path $out 'S7.png'))
try {
    $runs=@()
    foreach ($dy in @(0,1,13,24,25)) {
        $first=[int]$row.x; $last=$first+[int]$row.w-1; $y=[int]$row.y+$dy
        $start=$first; $previous=$bitmap.GetPixel($first,$y).ToArgb()
        for ($x=$first+1;$x -le $last+1;$x++) {
            $color=if ($x -le $last) {$bitmap.GetPixel($x,$y).ToArgb()} else {$null}
            if ($color -ne $previous) {
                $runs+=@{y=$y; x=$start; length=$x-$start; argb=$previous}
                $start=$x; $previous=$color
            }
        }
    }
    if ($row.w -ne 239 -or $row.h -ne 26) { throw 'Unexpected input row geometry; inspect before using scan' }
    $runs | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $out 'S7-pixel-runs.json') -Encoding utf8
    $runs | Where-Object { $_.y -eq 137 -or $_.y -eq 162 -or $_.x -lt 380 -or $_.x -gt 608 } | ConvertTo-Json -Depth 3
} finally { $bitmap.Dispose() }

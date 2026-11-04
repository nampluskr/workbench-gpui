#Requires -Version 7
# P4-E V3 helper: print colour runs along a row (-Y, x X0..X1) or a column (-X, y Y0..Y1) of a PNG. Usage: px-row.ps1 -Png f.png -Y 458 -X0 826 -X1 840
param([string]$Png,[int]$Y=-1,[int]$X=-1,[int]$X0=0,[int]$X1=0,[int]$Y0=0,[int]$Y1=0)
Add-Type -AssemblyName System.Drawing.Common
$b=[System.Drawing.Bitmap]::new($Png)
$pts = if($Y -ge 0){ $X0..$X1 | % { @{p=$_;c=$b.GetPixel($_,$Y)} } } else { $Y0..$Y1 | % { @{p=$_;c=$b.GetPixel($X,$_)} } }
$prev=$null;$start=0;$last=0
foreach($q in $pts){ $k="$($q.c.R),$($q.c.G),$($q.c.B)"; if($k -ne $prev){ if($prev){"$start..$last ($($last-$start+1)px) rgb=$prev"}; $prev=$k;$start=$q.p }; $last=$q.p }
"$start..$last ($($last-$start+1)px) rgb=$prev"

#Requires -Version 7
# P3-E: per-box diff of two --dev-layout-json dumps (x,y,w,h, tol 0.01). boxes is an object keyed by name.
param([string]$PathA,[string]$PathB)
function L($p){ (Get-Content -Raw $p|ConvertFrom-Json -AsHashtable).boxes }
$a=L $PathA;$b=L $PathB;$common=0;$d=@()
foreach($k in $a.Keys){ if(-not $b.ContainsKey($k)){$d+="only-A:$k";continue}; $common++
  foreach($f in 'x','y','w','h'){ if([math]::Abs([double]$a[$k][$f]-[double]$b[$k][$f]) -gt 0.01){$d+="$k.$f $($a[$k][$f])->$($b[$k][$f])"} } }
foreach($k in $b.Keys){ if(-not $a.ContainsKey($k)){$d+="only-B:$k"} }
"boxes A=$($a.Count) B=$($b.Count) common=$common diffs=$($d.Count)"; $d

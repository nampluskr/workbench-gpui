# Value-level compare of Phase 1 results vs R-1 baseline (saved results.json only; app is not run).
# Items keyed by case|sequence-in-case; compares what, expect, got, ok after masking per-run volatile tokens.
# Masked (D-8 / per-run identity): wall-clock t_ms, ISO times, GUIDs, run-<hex> dirs, *_ms / dt= / Nms durations,
# state.json.bad-<stamp>, file ids (old_id/new_id). Everything else (counts, offsets, paths, text) is compared as is.
# phase1 (no checks[]) compares cases.*.keys[] entries instead.
param([string]$Out='D:\projects\workbench-gpui\specs\v0.4\verify\baseline\phase4')
$b='D:\projects\workbench-gpui\specs\v0.4\verify\baseline'
function Load($p){ Get-Content $p -Raw -Encoding utf8 | ConvertFrom-Json }
function Norm($s){
  $s=[regex]::Replace("$s",'t_ms=\d+','t_ms=N')
  $s=[regex]::Replace($s,'\d{4}-\d\d-\d\dT[\d:.]+Z','<ISO>')
  $s=[regex]::Replace($s,'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}','<GUID>')
  $s=[regex]::Replace($s,'(?i)run-[0-9a-f]{20,}','run-<ID>')
  $s=[regex]::Replace($s,'(app_ms|seen_ms|dt)=\d+','$1=N')
  $s=[regex]::Replace($s,'\b\d+ ?ms\b','Nms')
  $s=[regex]::Replace($s,'\.bad-\d{8}-\d{6}','.bad-<STAMP>')
  $s=[regex]::Replace($s,'root_id=[0-9a-f:]+','root_id=<FID>')
  $s=[regex]::Replace($s,'wg-p4-d044-[0-9a-f]+','wg-p4-d044-<ID>')
  $s=[regex]::Replace($s,'(?i)run-[0-9a-f]{20,}','run-<ID>')
  $s=[regex]::Replace($s,'(old_id|new_id)=[0-9a-f:]+','$1=<FID>')
  $s
}
function BareMs($what,$g){ ($what -match "ms") -and ($g -match "^[\d,]+$") }
function Items($r){
  $out=[ordered]@{}; $seq=@{}
  if($r.checks){ foreach($c in $r.checks){ $seq[$c.case]++; $out["$($c.case)#$($seq[$c.case])"]=[pscustomobject]@{id="$($c.id)";what="$($c.what)";expect="$($c.expect)";got="$($c.got)";ok=[bool]$c.ok} } }
  else { foreach($cn in $r.cases.PSObject.Properties.Name){ foreach($e in @($r.cases.$cn.keys)){ $seq[$cn]++; $out["$cn#$($seq[$cn])"]=[pscustomobject]@{id="$($e.keys)";what="$($e.note)";expect="$($e.expect)|$($e.expectContext)";got="$($e.got)|$($e.context)";ok=[bool]$e.ok} } } }
  $out
}
$rows=foreach($d in Get-ChildItem $b -Directory -Filter 'verify-v02-phase2'|Sort Name){
  $n=$d.Name; $o=Items (Load "$b\$n\results.json"); $p=Items (Load "$Out\verify-v04-phase2\results.json")
  $diff=@(); $timeMasked=0
  foreach($k in $o.Keys){
    if(-not $p.Contains($k)){ $diff+=[pscustomobject]@{item=$k;id=$o[$k].id;what=$o[$k].what;base=$o[$k].got;p1='(missing)';baseOk=$o[$k].ok;p1Ok=$null}; continue }
    $x=$o[$k];$y=$p[$k]
    if((Norm $x.what) -ne (Norm $y.what) -or (Norm $x.expect) -ne (Norm $y.expect) -or ((Norm $x.got) -ne (Norm $y.got) -and -not (BareMs $x.what $x.got)) -or $x.ok -ne $y.ok){
      $diff+=[pscustomobject]@{item=$k;id=$x.id;what=$x.what;base=$x.got;p1=$y.got;baseOk=$x.ok;p1Ok=$y.ok}
    } elseif($x.got -ne $y.got){ $timeMasked++ }
  }
  foreach($k in $p.Keys){ if(-not $o.Contains($k)){ $diff+=[pscustomobject]@{item=$k;id=$p[$k].id;what=$p[$k].what;base='(missing)';p1=$p[$k].got;baseOk=$null;p1Ok=$p[$k].ok} } }
  [pscustomobject]@{script=$n;items=$o.Count;baseFail=@($o.Values|?{-not $_.ok}).Count;p1Items=$p.Count;p1Fail=@($p.Values|?{-not $_.ok}).Count;timeMasked=$timeMasked;diff=$diff}
}
$rows|ConvertTo-Json -Depth 5|Set-Content "$Out\comparison-v04-phase2.json" -Encoding utf8
$rows|%{"$($_.script) items=$($_.items)/$($_.p1Items) fail=$($_.baseFail)/$($_.p1Fail) timeMasked=$($_.timeMasked) diff=$($_.diff.Count)"}
$rows|%{ $s=$_.script; $_.diff|%{ "$s | $($_.item) | $($_.id) | $($_.base) -> $($_.p1)" } } | Set-Content "$Out\_diffs-v04-phase2.txt" -Encoding utf8





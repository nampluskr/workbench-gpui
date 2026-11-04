#Requires -Version 7
# Item-level comparison of phase1 R-12 results against verify/baseline (P0-0c).
# Items are keyed by case|id|what. A difference is an ok flip or an item present in only one run; got/expect text is not compared because it holds run GUIDs, paths and timestamps.
param([string]$Ref='baseline',[string]$OutName='comparison.json')
$ErrorActionPreference = 'Stop'
$root = 'D:\projects\workbench-gpui\specs\v0.3\verify'
function J($p) { [IO.File]::ReadAllText($p) | ConvertFrom-Json -AsHashtable }
function K($c) { "$($c.case)|$($c.id)|$($c.what)" }
function Checks($j) { if ($j.checks) { @($j.checks) } else { @() } }
function Norm($c) { if ("$($c.expect)" -match '~') { return "range-ok" }; ("$($c.got)" -replace 't_ms=\d+', 't_ms=#') }
$names = 'phase1','phase2','phase3','phase4','phase4-d043','phase4-d044','phase5','phase5-d046','phase5-d047' | ForEach-Object { "verify-v02-$_" }
$out = @()
foreach ($n in $names) {
    $bj = J (Join-Path $root "$Ref\$n\results.json"); $pj = J (Join-Path $root "p3d\$n\results.json")
    $e = [ordered]@{ script = $n }
    foreach ($k in $Ref,'p3d') {
        $j = if ($k -eq $Ref) { $bj } else { $pj }
        $c = Checks $j
        $e[$k] = [ordered]@{ checks = $c.Count; failedChecks = @($c | Where-Object { $_.ok -eq $false }).Count; failures = @($j.failures).Count; errors = @($j.errors).Count }
    }
    $bm = @{}
    if ((Checks $bj).Count -gt 0) {
        $bm = @{}; foreach ($c in (Checks $bj)) { $bm[(K $c)] = $c }
        $diffs = @(); $seen = @{}
        foreach ($c in (Checks $pj)) {
            $k = K $c; $seen[$k] = 1
            if (-not $bm.ContainsKey($k)) { $diffs += [ordered]@{ item = $k; change = 'new'; p3d = "ok=$($c.ok) got=$($c.got)" }; continue }
            $o = $bm[$k]
            if ($o.ok -ne $c.ok) { $diffs += [ordered]@{ item = $k; change = 'differs'; baseline = "ok=$($o.ok) got=$($o.got) expect=$($o.expect)"; p3d = "ok=$($c.ok) got=$($c.got) expect=$($c.expect)" } }
        }
        foreach ($k in $bm.Keys) { if (-not $seen.ContainsKey($k)) { $diffs += [ordered]@{ item = $k; change = 'missing in p3d' } } }
        $e.itemDiffs = $diffs
    }
    $e.failedInBoth = @(Checks $pj | Where-Object { $_.ok -eq $false -and $bm -and $bm.ContainsKey((K $_)) -and $bm[(K $_)].ok -eq $false } | ForEach-Object { [ordered]@{ item = (K $_); expect = $_.expect; baselineGot = $bm[(K $_)].got; phase1Got = $_.got } })
$out += $e
}
# phase1 script has no checks array: compare the R-1 binding table (minus the timestamp line) and case names
function Strip($p) { ([IO.File]::ReadAllText($p) -split "\r?\n" | Where-Object { -not $_.StartsWith('생성:') }) -join "`n" }
$out[0].r1BindingsIdentical = ((Strip "$root\$Ref\verify-v02-phase1\r1-bindings.md") -eq (Strip "$root\p3d\verify-v02-phase1\r1-bindings.md"))
$out[0].caseNamesIdentical = (((J "$root\$Ref\verify-v02-phase1\results.json").cases.Keys -join ',') -eq ((J "$root\p3d\verify-v02-phase1\results.json").cases.Keys -join ','))
$out | ConvertTo-Json -Depth 8 | Set-Content "$root\p3d\$OutName" -Encoding utf8
foreach ($e in $out) { "$($e.script): baseline $($e[$Ref].checks)/$($e[$Ref].failedChecks)f fail=$($e[$Ref].failures) | p3d $($e.p3d.checks)/$($e.p3d.failedChecks)f fail=$($e.p3d.failures) | diffs=$(@($e.itemDiffs).Count)" }
"p3d r1 identical=$($out[0].r1BindingsIdentical) cases identical=$($out[0].caseNamesIdentical)"





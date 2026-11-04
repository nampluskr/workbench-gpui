#Requires -Version 7
# Compare a --dev-layout-json dump with spec/zed-metrics.toml expected values.
# Usage: pwsh -File tools/measure/compare.ps1 -Json <layout.json> -Checks <checks.txt> [-Report <out.md>]
# Checks file: one per line `spec-id | box-name | w|h|x|y [| expected-cond]`, `#` starts a comment.
#   e.g. titlebar["height"] | titlebar | h | default
param([Parameter(Mandatory)][string]$Json, [Parameter(Mandatory)][string]$Checks, [string]$Report)
$ErrorActionPreference = 'Stop'
$toml = Join-Path $PSScriptRoot '..\..\spec\zed-metrics.toml'
# shortcut: parses the one-line `"key" = { value = .., unit = .., cond = .. }` records, use a TOML parser if the format changes
$spec = @{}; $table = ''
foreach ($line in (Get-Content $toml -Encoding utf8)) {
    if ($line -match '^\[(.+)\]\s*$') { $table = $matches[1] }
    elseif ($line -match '^"([^"]+)" = \{ value = ([^,]+), unit = "([^"]+)", cond = "([^"]+)"') {
        $spec["$table[`"$($matches[1])`"]"] = @{ value = $matches[2].Trim('"'); unit = $matches[3]; cond = $matches[4] }
    }
}
function Tol($id, $unit) {
    if ($unit -ne 'px') { return 0.0 }
    $t = if ($id.StartsWith('typography[') -or $id -match 'font_size') { 'font_size' } else { 'dimension' }
    return [double]$spec["verification.tolerance[`"$t`"]"].value
}
$dump = Get-Content -Raw $Json | ConvertFrom-Json
$boxes = @{}; foreach ($b in $dump.boxes) { $boxes[$b.name] = $b }
$rows = @(); $fail = 0
foreach ($raw in (Get-Content $Checks -Encoding utf8)) {
    if ($raw -match '^\s*(#|$)') { continue }
    $f = $raw -split '\|' | ForEach-Object { $_.Trim() }
    if ($f.Count -lt 3 -or $f[2] -notin 'w','h','x','y','diff') { throw "Bad check line: $raw" }
    # Optional `exact` column (anywhere after the field): compare with tolerance 0 (items D-3 matched exactly). The cond column is the other optional one.
    $exact = $f.Count -ge 4 -and ($f[3..($f.Count-1)] -contains 'exact'); $condCol = if ($f.Count -ge 4 -and $f[3] -ne 'exact') { $f[3] } else { $null }
    # `diff`: the box column is `A.f ~ B.f` (f = x|y|w|h|r(ight)|b(ottom)) and the measured value is A.f - B.f.
    if ($f[2] -eq 'diff') {
        function EdgeValue($ref) {
            if ($ref -notmatch '^(.+)\.(x|y|w|h|r|b)$') { throw "Bad diff operand: $ref" }
            if (-not $boxes.ContainsKey($matches[1])) { return $null }
            $bx = $boxes[$matches[1]]
            switch ($matches[2]) { 'r' { [double]$bx.x + [double]$bx.w } 'b' { [double]$bx.y + [double]$bx.h } default { [double]$bx.($matches[2]) } }
        }
        $id = $f[0]; $name = $f[1]
        if (-not $spec.ContainsKey($id)) { throw "spec id not found: $id" }
        $s = $spec[$id]; $expected = [double]$s.value; $tol = if ($exact) { 0.0 } else { Tol $id $s.unit }
        $ops = $name -split '\s*~\s*'
        if ($ops.Count -ne 2) { throw "diff needs `A.f ~ B.f`: $raw" }
        $a = EdgeValue $ops[0]; $c = EdgeValue $ops[1]
        if ($null -eq $a -or $null -eq $c) { $actual = $null; $diff = $null; $verdict = 'MISSING'; $fail++ }
        else { $actual = $a - $c; $diff = $actual - $expected; $verdict = if ([Math]::Abs($diff) -le $tol) { 'PASS' } else { $fail++; 'FAIL' } }
        $rows += "| $id | $name | $expected | $(if ($exact) { "exact" } else { "±$tol" }) | $actual | $diff | $verdict |"
        continue
    }
    $id = $f[0]; $name = $f[1]; $field = $f[2]
    if (-not $spec.ContainsKey($id)) { throw "spec id not found: $id" }
    $s = $spec[$id]
    if ($condCol -and $condCol -ne $s.cond) { throw "spec cond mismatch: $id expected cond=$condCol, spec cond=$($s.cond)" }
    $expected = [double]$s.value; $tol = if ($exact) { 0.0 } else { Tol $id $s.unit }
    if ($boxes.ContainsKey($name)) {
        $actual = [double]$boxes[$name].$field
        $diff = $actual - $expected
        $verdict = if ([Math]::Abs($diff) -le $tol) { 'PASS' } else { $fail++; 'FAIL' }
    } else { $actual = $null; $diff = $null; $verdict = 'MISSING'; $fail++ }
    $rows += "| $id | $name.$field | $expected | $(if ($exact) { "exact" } else { "±$tol" }) | $actual | $diff | $verdict |"
}
$table = @('| spec id | box | expected | tol | actual | diff | verdict |', '| --- | --- | --- | --- | --- | --- | --- |') + $rows
$table
if ($Report) { $table | Set-Content $Report -Encoding utf8 }
if ($fail) { Write-Error "$fail check(s) failed"; exit 1 }

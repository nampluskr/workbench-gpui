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
    $t = if ($id -match 'font_size') { 'font_size' } else { 'dimension' }
    return [double]$spec["verification.tolerance[`"$t`"]"].value
}
$dump = Get-Content -Raw $Json | ConvertFrom-Json
$boxes = @{}; foreach ($b in $dump.boxes) { $boxes[$b.name] = $b }
$rows = @(); $fail = 0
foreach ($raw in (Get-Content $Checks -Encoding utf8)) {
    if ($raw -match '^\s*(#|$)') { continue }
    $f = $raw -split '\|' | ForEach-Object { $_.Trim() }
    if ($f.Count -lt 3 -or $f[2] -notin 'w','h','x','y') { throw "Bad check line: $raw" }
    $id = $f[0]; $name = $f[1]; $field = $f[2]
    if (-not $spec.ContainsKey($id)) { throw "spec id not found: $id" }
    $s = $spec[$id]
    if ($f.Count -ge 4 -and $f[3] -ne $s.cond) { throw "spec cond mismatch: $id expected cond=$($f[3]), spec cond=$($s.cond)" }
    $expected = [double]$s.value; $tol = Tol $id $s.unit
    if ($boxes.ContainsKey($name)) {
        $actual = [double]$boxes[$name].$field
        $diff = $actual - $expected
        $verdict = if ([Math]::Abs($diff) -le $tol) { 'PASS' } else { $fail++; 'FAIL' }
    } else { $actual = $null; $diff = $null; $verdict = 'MISSING'; $fail++ }
    $rows += "| $id | $name.$field | $expected | ±$tol | $actual | $diff | $verdict |"
}
$table = @('| spec id | box | expected | tol | actual | diff | verdict |', '| --- | --- | --- | --- | --- | --- | --- |') + $rows
$table
if ($Report) { $table | Set-Content $Report -Encoding utf8 }
if ($fail) { Write-Error "$fail check(s) failed"; exit 1 }

#Requires -Version 7
<#
.SYNOPSIS
  release exe + 실행 중 읽는 resources 4폴더를 target\dist\workbench-gpui\ 에 모으고 zip 으로 묶는다 (K-51).

.DESCRIPTION
  앱은 exe 옆 resources\ 를 먼저 찾는다(없으면 개발용 소스 경로). 그래서 배포 폴더 전체를 다른 PC 로 옮겨도 된다.
  pdb·fonts·licenses·windows 는 exe 에 들어 있거나 빌드용이라 넣지 않는다.

.PARAMETER NoBuild
  cargo build --release 를 건너뛴다 (이미 빌드했을 때).

.EXAMPLE
  pwsh -NoProfile -File tools/package-release.ps1
#>
[CmdletBinding()]
param(
    [switch]$NoBuild
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path

# 상대 경로는 레포 루트 기준. 비어 있으면 레포 target.
$target = if ($env:CARGO_TARGET_DIR) { $env:CARGO_TARGET_DIR } else { 'target' }
$target = [System.IO.Path]::GetFullPath($target, $repo)
$env:CARGO_TARGET_DIR = $target

# 실행 중 읽는 폴더와, 없을 때 알려 줄 fetch 스크립트.
$folders = [ordered]@{
    'zed-icon-themes' = 'tools/fetch-zed-themes.ps1'
    'zed-icons'       = 'tools/fetch-zed-icons.ps1'
    'zed-themes'      = 'tools/fetch-zed-themes.ps1'
    'zed-languages'   = 'tools/fetch-zed-languages.ps1'
}
foreach ($name in $folders.Keys) {
    if (-not (Test-Path -LiteralPath (Join-Path $repo "resources\$name") -PathType Container)) {
        throw "resources\$name 가 없다. $($folders[$name]) 를 먼저 실행한다."
    }
}

Push-Location $repo
try {
    if (-not $NoBuild) {
        & cargo build --release
        if ($LASTEXITCODE -ne 0) { throw "cargo build --release 실패 (exit $LASTEXITCODE)" }
    }

    $exe = Join-Path $target 'release\workbench-gpui.exe'
    if (-not (Test-Path -LiteralPath $exe)) { throw "release exe 가 없다: $exe" }

    & (Join-Path $PSScriptRoot 'apply-manifest.ps1') -Exe $exe -DumpTo (Join-Path $target 'manifest\release-manifest.xml') | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "apply-manifest 실패 (exit $LASTEXITCODE)" }
} finally {
    Pop-Location
}

$dist = Join-Path $target 'dist'
$out = Join-Path $dist 'workbench-gpui'
$zip = Join-Path $dist 'workbench-gpui.zip'
if (Test-Path -LiteralPath $out) { Remove-Item -LiteralPath $out -Recurse -Force }
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
New-Item -ItemType Directory -Path (Join-Path $out 'resources') -Force | Out-Null

Copy-Item -LiteralPath $exe -Destination $out
foreach ($name in $folders.Keys) {
    Copy-Item -LiteralPath (Join-Path $repo "resources\$name") -Destination (Join-Path $out 'resources') -Recurse
}
Compress-Archive -LiteralPath $out -DestinationPath $zip

$files = @(Get-ChildItem -LiteralPath $out -Recurse -File)
$sizeMb = ($files | Measure-Object Length -Sum).Sum / 1MB
"folder: $out"
"zip:    $zip ({0:N2} MB)" -f ((Get-Item -LiteralPath $zip).Length / 1MB)
"size:   {0:N2} MB, {1} files" -f $sizeMb, $files.Count

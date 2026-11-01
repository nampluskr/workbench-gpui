#Requires -Version 7
<#
.SYNOPSIS
  빌드한 exe 의 매니페스트에 longPathAware 를 병합하고, 결과 매니페스트를 파일로 꺼낸다 (G-128, R-5).

.DESCRIPTION
  확인한 사실 (gpui-pre 0.3.10 / gpui-kit 0.8.1 소스):
  - gpui-kit 은 gpui-pre 를 기본 기능 그대로 의존하고, gpui-pre 기본 기능에 `windows-manifest` 가 있다.
    gpui-pre-platform 도 Windows 에서 gpui-pre 를 `features = ["windows-manifest"]` 로 의존한다.
    그래서 앱 쪽에서 이 기능을 끌 수 없다.
  - `windows-manifest` 는 gpui-pre build.rs 가 embed-resource 로 resources/windows/gpui.rc
    (`1 RT_MANIFEST "gpui.manifest.xml"`)를 exe 에 넣는다. 이 매니페스트에는 Common Controls v6
    (dependentAssembly Microsoft.Windows.Common-Controls 6.0.0.0), dpiAware true/pm,
    dpiAwareness PerMonitorV2, heapType SegmentHeap, supportedOS Windows 10 이 있고 longPathAware 는 없다.
  - gpui-component·gpui-kit·gpui-base 의 `windows-manifest-provided-by-host` 는 선택 의존성
    gpui-fast 에만 거는 기능이라 기본 백엔드(gpui-pre)에는 영향이 없다.
  - 같은 RT_MANIFEST #1 을 앱 쪽 리소스로 하나 더 넣으면 링크 때 리소스가 겹친다. 그래서 빌드 뒤에
    mt.exe 로 기존 매니페스트에 병합한다.

  longPathAware 가 실제로 켜지려면 OS 설정 LongPathsEnabled(레지스트리) 도 1 이어야 한다.
  앱의 `--dev-open-longpath` 가 RtlAreLongPathsEnabled 값으로 둘을 합친 결과를 보여 준다.

.PARAMETER Exe
  대상 exe. 기본 target\debug\workbench-gpui.exe.

.PARAMETER Fragment
  병합할 매니페스트 조각. 기본 resources\windows\longpath.manifest.xml.

.PARAMETER DumpTo
  병합 뒤 exe 에서 꺼낸 매니페스트를 저장할 경로. 기본 target\manifest\manifest.xml (빌드 산출물 쪽, 커밋되지 않는다). 검증 증거로 남길 때만 -DumpTo 로 specs 아래 경로를 준다.

.EXAMPLE
  pwsh -NoProfile -File tools/apply-manifest.ps1
#>
[CmdletBinding()]
param(
    [string]$Exe = 'target\debug\workbench-gpui.exe',
    [string]$Fragment = 'resources\windows\longpath.manifest.xml',
    [string]$DumpTo = 'target\manifest\manifest.xml'
)

$ErrorActionPreference = 'Stop'

function Find-Mt {
    $cmd = Get-Command mt.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $kits = 'C:\Program Files (x86)\Windows Kits\10\bin'
    if (-not (Test-Path -LiteralPath $kits)) { throw "Windows SDK bin 폴더가 없다: $kits" }
    $found = Get-ChildItem -LiteralPath $kits -Directory |
        Where-Object { $_.Name -match '^\d+\.\d+\.\d+\.\d+$' } |
        Sort-Object { [version]$_.Name } -Descending |
        ForEach-Object { Join-Path $_.FullName 'x64\mt.exe' } |
        Where-Object { Test-Path -LiteralPath $_ } |
        Select-Object -First 1
    if (-not $found) { throw 'mt.exe 를 찾지 못했다 (Windows SDK x64 bin)' }
    return $found
}

$exePath = (Resolve-Path -LiteralPath $Exe).Path
$fragmentPath = (Resolve-Path -LiteralPath $Fragment).Path
$dumpPath = [System.IO.Path]::GetFullPath($DumpTo, (Get-Location).Path)
$dumpDir = [System.IO.Path]::GetDirectoryName($dumpPath)
if (-not (Test-Path -LiteralPath $dumpDir)) { New-Item -ItemType Directory -Path $dumpDir -Force | Out-Null }

$mt = Find-Mt
Write-Host "mt.exe: $mt"

# 1) 기존 매니페스트(#1)와 조각을 병합해 같은 자리(#1)에 다시 쓴다.
& $mt -nologo "-inputresource:$exePath;#1" -manifest $fragmentPath "-outputresource:$exePath;#1"
if ($LASTEXITCODE -ne 0) { throw "mt.exe 병합 실패 (exit $LASTEXITCODE)" }

# 2) 결과 매니페스트를 꺼내 증거로 저장한다.
& $mt -nologo "-inputresource:$exePath;#1" "-out:$dumpPath"
if ($LASTEXITCODE -ne 0) { throw "mt.exe 추출 실패 (exit $LASTEXITCODE)" }

$xml = Get-Content -LiteralPath $dumpPath -Raw
$checks = [ordered]@{
    commonControlsV6 = ($xml -match "Microsoft\.Windows\.Common-Controls" -and $xml -match "6\.0\.0\.0")
    perMonitorV2     = ($xml -match 'PerMonitorV2')
    longPathAware    = ($xml -match '<\s*(\w+:)?longPathAware[^>]*>\s*true\s*<')
}
[ordered]@{
    exe      = $exePath
    manifest = $dumpPath
    checks   = $checks
} | ConvertTo-Json -Depth 3

if ($checks.Values -contains $false) { exit 1 }

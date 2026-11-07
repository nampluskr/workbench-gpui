#Requires -Version 7
$ErrorActionPreference = 'Stop'
$destination = Join-Path $PSScriptRoot '../resources/zed-themes'
$staging = Join-Path ([IO.Path]::GetTempPath()) ('zed-themes-' + [guid]::NewGuid())
function Invoke-Git {
    & git @args
    if ($LASTEXITCODE -ne 0) { throw "git failed: $args" }
}
$sources = @(
    @('zed', 'https://github.com/zed-industries/zed.git', '4304dec732a75505066de5ce2dbbfb2bec369498', 'assets/themes'),
    @('catppuccin', 'https://github.com/catppuccin/zed.git', 'refs/tags/v0.2.27', 'themes'),
    @('macos-classic', 'https://github.com/huacnlee/zed-theme-macos-classic.git', 'refs/tags/v0.4.0', 'themes')
)
foreach ($source in $sources) {
    $checkout = Join-Path $staging $source[0]
    Invoke-Git init $checkout
    Invoke-Git -C $checkout remote add origin $source[1]
    Invoke-Git -C $checkout sparse-checkout set $source[3]
    Invoke-Git -C $checkout fetch --depth 1 origin $source[2]
    Invoke-Git -C $checkout checkout --detach FETCH_HEAD
    $target = Join-Path $destination $source[0]
    New-Item -ItemType Directory -Force $target | Out-Null
    Copy-Item (Join-Path $checkout $source[3]) $target -Recurse -Force
    Get-ChildItem $checkout -File | Where-Object { $_.Name -like 'LICENSE*' -or $_.Name -eq 'extension.toml' } | Copy-Item -Destination $target -Force
    if (!(Get-ChildItem $target -Recurse -File -Filter '*.json')) { throw "No themes: $target" }
    Write-Output "$($source[0]): $(& git -C $checkout rev-parse HEAD)"
}

# Icon themes (K-20): Catppuccin Icons pack, plus the Zed (Default) association table as data.
# The table is read from Zed's source in TEMP and rewritten as icon-theme JSON; no Rust code is copied.
$iconDestination = Join-Path $PSScriptRoot '../resources/zed-icon-themes'
$zedCommit = '4304dec732a75505066de5ce2dbbfb2bec369498'
$checkout = Join-Path $staging 'catppuccin-icons'
Invoke-Git init $checkout
Invoke-Git -C $checkout remote add origin https://github.com/catppuccin/zed-icons.git
Invoke-Git -C $checkout sparse-checkout set icon_themes icons
Invoke-Git -C $checkout fetch --depth 1 origin refs/tags/v1.24.0
Invoke-Git -C $checkout checkout --detach FETCH_HEAD
$target = Join-Path $iconDestination 'catppuccin-icons'
New-Item -ItemType Directory -Force $target | Out-Null
Copy-Item (Join-Path $checkout 'icon_themes') $target -Recurse -Force
Copy-Item (Join-Path $checkout 'icons') $target -Recurse -Force
Get-ChildItem $checkout -File | Where-Object { $_.Name -like 'LICENSE*' -or $_.Name -eq 'extension.toml' } | Copy-Item -Destination $target -Force
if (!(Get-ChildItem $target -Recurse -File -Filter '*.json')) { throw "No icon themes: $target" }
Write-Output "catppuccin-icons: $(& git -C $checkout rev-parse HEAD)"

$checkout = Join-Path $staging 'zed-icon-theme'
Invoke-Git init $checkout
Invoke-Git -C $checkout remote add origin https://github.com/zed-industries/zed.git
Invoke-Git -C $checkout sparse-checkout set crates/theme/src
Invoke-Git -C $checkout fetch --depth 1 origin $zedCommit
Invoke-Git -C $checkout checkout --detach FETCH_HEAD
$source = Get-Content (Join-Path $checkout 'crates/theme/src/icon_theme.rs') -Raw
function Get-Block($name) { [regex]::Match($source, "const $name[^=]*=\s*&\[(.*?)\n\];", 'Singleline').Groups[1].Value }
function Get-Associations($name) {
    $map = [ordered]@{}
    foreach ($m in [regex]::Matches((Get-Block $name), '\(\s*"([^"]+)"\s*,\s*&\[(.*?)\]\s*,?\s*\)', 'Singleline')) {
        foreach ($s in [regex]::Matches($m.Groups[2].Value, '"([^"]*)"')) { $map[$s.Groups[1].Value] = $m.Groups[1].Value }
    }
    $map
}
$icons = [ordered]@{}
foreach ($m in [regex]::Matches((Get-Block 'FILE_ICONS'), '\("([^"]+)",\s*"([^"]+)"\)')) {
    $icons[$m.Groups[1].Value] = [ordered]@{ path = $m.Groups[2].Value -replace '^icons/', '../../zed-icons/' }
}
$stems = Get-Associations 'FILE_STEMS_BY_ICON_KEY'
$suffixes = Get-Associations 'FILE_SUFFIXES_BY_ICON_KEY'
if ($suffixes['rs'] -ne 'rust' -or $stems['Dockerfile'] -ne 'docker' -or !$icons['default']) { throw 'Zed icon table parse failed' }
$theme = [ordered]@{
    name = 'Zed (Default)'; appearance = 'dark'
    directory_icons = [ordered]@{ collapsed = '../../zed-icons/file_icons/folder.svg'; expanded = '../../zed-icons/file_icons/folder_open.svg' }
    named_directory_icons = [ordered]@{}
    chevron_icons = [ordered]@{ collapsed = '../../zed-icons/file_icons/chevron_right.svg'; expanded = '../../zed-icons/file_icons/chevron_down.svg' }
    file_stems = $stems; file_suffixes = $suffixes; file_icons = $icons
}
$family = [ordered]@{
    name = 'Zed'; author = 'Zed Industries'
    source = "zed-industries/zed@$zedCommit crates/theme/src/icon_theme.rs (association data only)"
    themes = @($theme)
}
$target = Join-Path $iconDestination 'zed'
New-Item -ItemType Directory -Force $target | Out-Null
$family | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8NoBOM (Join-Path $target 'zed.json')
Write-Output "zed-icon-theme: $zedCommit, $($icons.Count) icons, $($stems.Count) stems, $($suffixes.Count) suffixes"

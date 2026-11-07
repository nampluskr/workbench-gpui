#Requires -Version 7
$ErrorActionPreference = 'Stop'
$commit = '4304dec732a75505066de5ce2dbbfb2bec369498'
$destination = Join-Path $PSScriptRoot '../resources/zed-languages'
$checkout = Join-Path ([IO.Path]::GetTempPath()) ('zed-languages-' + [guid]::NewGuid())
function Invoke-Git {
    & git @args
    if ($LASTEXITCODE -ne 0) { throw "git failed: $args" }
}
try {
Invoke-Git init $checkout
Invoke-Git -C $checkout remote add origin https://github.com/zed-industries/zed.git
Invoke-Git -C $checkout sparse-checkout set crates/grammars/src extensions/html/languages/html
Invoke-Git -C $checkout fetch --depth 1 origin $commit
Invoke-Git -C $checkout checkout --detach FETCH_HEAD
$folders = @('bash','c','cpp','css','diff','env','gitcommit','go','gomod','gowork','javascript','jsdoc','json','jsonc','markdown','markdown-inline','python','regex','rust','tsx','typescript','yaml','zed-keybind-context','html')
$files = @()
foreach ($folder in $folders) {
    $source = if ($folder -eq 'html') { 'extensions/html/languages/html' } else { "crates/grammars/src/$folder" }
    $target = Join-Path $destination $folder
    New-Item -ItemType Directory -Force $target | Out-Null
    foreach ($name in @('highlights.scm','injections.scm','outline.scm')) {
        $inputFile = Join-Path $checkout "$source/$name"
        $outputFile = Join-Path $target $name
        if (Test-Path -LiteralPath $inputFile) {
            Copy-Item -LiteralPath $inputFile -Destination $outputFile -Force
            $files += [ordered]@{ path = "$folder/$name"; sha256 = (Get-FileHash -LiteralPath $outputFile -Algorithm SHA256).Hash.ToLowerInvariant() }
        } elseif (Test-Path -LiteralPath $outputFile) {
            Remove-Item -LiteralPath $outputFile
        }
    }
    if (!(Test-Path -LiteralPath (Join-Path $target 'highlights.scm'))) { throw "Missing highlights: $folder" }
}
# K-48: the TOML extension and the Git (git-firefly) extension, each at its pinned commit. Their `languages/<name>/` hold
# the queries and the `config.toml` (names, file suffixes) of the language; the folder name is the language id.
$extensions = @(
    @{ repository = 'https://github.com/zed-extensions/toml'; commit = '8e18e5045841f0f265f9c8b89f138c7f7dd09e2e'; languages = @('toml') },
    @{ repository = 'https://github.com/d1y/git_firefly'; commit = 'c63c6c0287ab5c8eb3872cf2bc8803e21c7a9675'; languages = @('gitattributes','gitconfig','gitignore','gitrebase') }
)
$extensionCommits = [ordered]@{}
foreach ($extension in $extensions) {
    $extensionCheckout = Join-Path ([IO.Path]::GetTempPath()) ('zed-extension-' + [guid]::NewGuid())
    try {
        Invoke-Git init $extensionCheckout
        Invoke-Git -C $extensionCheckout remote add origin $extension.repository
        Invoke-Git -C $extensionCheckout fetch --depth 1 origin $extension.commit
        Invoke-Git -C $extensionCheckout checkout --detach FETCH_HEAD
        if ((& git -C $extensionCheckout rev-parse HEAD) -ne $extension.commit) { throw "Unexpected commit: $($extension.repository)" }
        foreach ($folder in $extension.languages) {
            $target = Join-Path $destination $folder
            New-Item -ItemType Directory -Force $target | Out-Null
            foreach ($name in @('highlights.scm','injections.scm','outline.scm','config.toml')) {
                $inputFile = Join-Path $extensionCheckout "languages/$folder/$name"
                $outputFile = Join-Path $target $name
                if (Test-Path -LiteralPath $inputFile) {
                    Copy-Item -LiteralPath $inputFile -Destination $outputFile -Force
                    $files += [ordered]@{ path = "$folder/$name"; sha256 = (Get-FileHash -LiteralPath $outputFile -Algorithm SHA256).Hash.ToLowerInvariant() }
                } elseif (Test-Path -LiteralPath $outputFile) {
                    Remove-Item -LiteralPath $outputFile
                }
            }
            if (!(Test-Path -LiteralPath (Join-Path $target 'highlights.scm'))) { throw "Missing highlights: $folder" }
        }
        $extensionCommits[$extension.repository] = $extension.commit
    } finally {
        $leaf = Split-Path -Leaf $extensionCheckout
        if ((Test-Path -LiteralPath $extensionCheckout) -and $leaf.StartsWith('zed-extension-') -and
            ((Split-Path -Parent $extensionCheckout) -eq ([IO.Path]::GetTempPath()).TrimEnd('\', '/'))) {
            Remove-Item -LiteralPath $extensionCheckout -Recurse -Force
        }
    }
}
foreach ($name in @('LICENSE-GPL','LICENSE-APACHE')) {
    Copy-Item -LiteralPath (Join-Path $checkout $name) -Destination $destination -Force
}
[ordered]@{ zedCommit = $commit; extensions = $extensionCommits; files = @($files) } | ConvertTo-Json -Depth 5 |
    Set-Content -Encoding utf8NoBOM -LiteralPath (Join-Path $destination 'manifest.json')
Write-Output "zed-languages: $commit + $($extensionCommits.Count) extensions, $($folders.Count) folders, $($files.Count) files"
} finally {
    # Remove only the temporary clone, and only if it is under %TEMP% with our prefix.
    $tempRoot = [IO.Path]::GetTempPath()
    $leaf = Split-Path -Leaf $checkout
    if ((Test-Path -LiteralPath $checkout) -and $leaf.StartsWith('zed-languages-') -and
        ((Split-Path -Parent $checkout) -eq $tempRoot.TrimEnd('\', '/'))) {
        Remove-Item -LiteralPath $checkout -Recurse -Force
    }
}

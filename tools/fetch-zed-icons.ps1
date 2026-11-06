$ErrorActionPreference = 'Stop'
$commit = '4304dec732a75505066de5ce2dbbfb2bec369498'
$destination = Join-Path $PSScriptRoot '../resources/zed-icons'
$staging = Join-Path ([IO.Path]::GetTempPath()) ('zed-icons-' + [guid]::NewGuid())

function Invoke-Git {
    & git @args
    if ($LASTEXITCODE -ne 0) { throw "git failed: $args" }
}

# Only icons and repository license files are materialized, outside the repository.
Invoke-Git init $staging
Invoke-Git -C $staging remote add origin https://github.com/zed-industries/zed.git
Invoke-Git -C $staging sparse-checkout set assets/icons
Invoke-Git -C $staging fetch --depth 1 origin $commit
Invoke-Git -C $staging checkout --detach FETCH_HEAD
if ((& git -C $staging rev-parse HEAD) -ne $commit) { throw 'Unexpected Zed commit' }
$icons = Join-Path $staging 'assets/icons'
if ((Get-ChildItem $icons -Filter '*.svg' -File).Count -ne 299) { throw 'Unexpected UI icon count' }
if ((Get-ChildItem (Join-Path $icons 'file_icons') -Filter '*.svg' -File).Count -ne 96) { throw 'Unexpected file icon count' }
New-Item -ItemType Directory -Force $destination | Out-Null
Copy-Item (Join-Path $icons '*') $destination -Recurse -Force
Copy-Item (Join-Path $staging 'LICENSE-APACHE') $destination -Force
Copy-Item (Join-Path $staging 'LICENSE-GPL') $destination -Force
Write-Output "Fetched $commit : 299 UI icons, 96 file icons"

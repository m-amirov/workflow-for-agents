$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Assert {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "ASSERT FAILED: $Message" }
}

$repo = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$install = Join-Path $repo 'scripts\install.ps1'
$sync = Join-Path $repo 'scripts\sync.ps1'
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("agent-skills-" + [guid]::NewGuid().ToString('N'))
$source = Join-Path $tmp 'source'
$project = Join-Path $tmp 'project'
$sourceCategory = Join-Path $source 'skills\core'
$sourceSkill = Join-Path $sourceCategory 'task-planning'
$targetSkill = Join-Path $project '.agents\skills\task-planning'
$manifest = Join-Path $project '.agents\skills\.workflow-for-agents.manifest.json'

try {
    New-Item -ItemType Directory -Path $sourceCategory, $project -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $repo 'skills\core\task-planning') -Destination $sourceSkill -Recurse

    & $install -Scope project -ProjectPath $project -RepositoryRoot $source -Skills task-planning -DryRun | Out-Null
    Assert (-not (Test-Path -LiteralPath $targetSkill)) 'dry-run created destination'

    & $install -Scope project -ProjectPath $project -RepositoryRoot $source -Skills task-planning | Out-Null
    Assert (Test-Path -LiteralPath (Join-Path $targetSkill 'SKILL.md')) 'install did not copy skill'
    Assert (Test-Path -LiteralPath $manifest) 'install did not save manifest'
    $installedManifest = Get-Content -LiteralPath $manifest -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert ($installedManifest.installed[0].sourceVersion -match '^[a-f0-9]{64}$') 'source version fingerprint not recorded'

    & $install -Scope project -ProjectPath $project -RepositoryRoot $source -Skills task-planning | Out-Null
    $target = Join-Path $targetSkill 'SKILL.md'
    $original = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
    Add-Content -LiteralPath $target -Value '\n# locally edited'
    $failed = $false
    try { & $sync -Scope project -ProjectPath $project -RepositoryRoot $source | Out-Null }
    catch { $failed = $true }
    Assert $failed 'sync overwrote a local modification'
    Assert ((Get-Content -LiteralPath $target -Raw).Contains('locally edited')) 'local edit was lost'

    Copy-Item -LiteralPath (Join-Path $sourceSkill 'SKILL.md') -Destination $target -Force
    Assert ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -eq $original) 'failed to reset fixture'
    Add-Content -LiteralPath (Join-Path $sourceSkill 'SKILL.md') -Value '\n# upstream v2'
    & $sync -Scope project -ProjectPath $project -RepositoryRoot $source -DryRun | Out-Null
    Assert (-not ((Get-Content -LiteralPath $target -Raw).Contains('upstream v2'))) 'sync dry-run changed target'
    & $sync -Scope project -ProjectPath $project -RepositoryRoot $source | Out-Null
    Assert ((Get-Content -LiteralPath $target -Raw).Contains('upstream v2')) 'sync did not update managed file'

    $addedSource = Join-Path $sourceSkill 'new-reference.txt'
    $addedTarget = Join-Path $targetSkill 'new-reference.txt'
    Set-Content -LiteralPath $addedSource -Value 'new upstream file'
    & $sync -Scope project -ProjectPath $project -RepositoryRoot $source | Out-Null
    Assert (Test-Path -LiteralPath $addedTarget) 'sync did not install added upstream file'
    Remove-Item -LiteralPath $addedSource
    & $sync -Scope project -ProjectPath $project -RepositoryRoot $source | Out-Null
    Assert (-not (Test-Path -LiteralPath $addedTarget)) 'sync did not remove obsolete managed file'

    $unmanaged = Join-Path $targetSkill 'local-notes.txt'
    Set-Content -LiteralPath $unmanaged -Value 'user data'
    Add-Content -LiteralPath (Join-Path $sourceSkill 'SKILL.md') -Value '\n# upstream v3'
    & $sync -Scope project -ProjectPath $project -RepositoryRoot $source | Out-Null
    Assert (Test-Path -LiteralPath $unmanaged) 'sync removed unmanaged file'

    Set-Content -LiteralPath (Join-Path $sourceSkill 'local-notes.txt') -Value 'upstream collision'
    $failed = $false
    try { & $sync -Scope project -ProjectPath $project -RepositoryRoot $source | Out-Null }
    catch { $failed = $true }
    Assert $failed 'sync failed to detect new source/local file collision'
    Assert ((Get-Content -LiteralPath $unmanaged -Raw).Contains('user data')) 'collision overwrote local data'

    Write-Output 'PASS: dry-run, version manifest, install, idempotency, local edit protection, update/add/remove sync, unmanaged file protection, collision'
}
finally {
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
}

) 'source version fingerprint not recorded'

    & $install -Scope project -ProjectPath $project -RepositoryRoot $source -Skills task-planning | Out-Null
    $target = Join-Path $targetSkill 'SKILL.md'
    $original = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
    Add-Content -LiteralPath $target -Value '\n# locally edited'
    $failed = $false
    try { & $sync -Scope project -ProjectPath $project -RepositoryRoot $source | Out-Null }
    catch { $failed = $true }
    Assert $failed 'sync overwrote a local modification'
    Assert ((Get-Content -LiteralPath $target -Raw).Contains('locally edited')) 'local edit was lost'

    Copy-Item -LiteralPath (Join-Path $sourceSkill 'SKILL.md') -Destination $target -Force
    Assert ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -eq $original) 'failed to reset fixture'
    Add-Content -LiteralPath (Join-Path $sourceSkill 'SKILL.md') -Value '\n# upstream v2'
    & $sync -Scope project -ProjectPath $project -RepositoryRoot $source -DryRun | Out-Null
    Assert (-not ((Get-Content -LiteralPath $target -Raw).Contains('upstream v2'))) 'sync dry-run changed target'
    & $sync -Scope project -ProjectPath $project -RepositoryRoot $source | Out-Null
    Assert ((Get-Content -LiteralPath $target -Raw).Contains('upstream v2')) 'sync did not update managed file'

    $unmanaged = Join-Path $targetSkill 'local-notes.txt'
    Set-Content -LiteralPath $unmanaged -Value 'user data'
    Add-Content -LiteralPath (Join-Path $sourceSkill 'SKILL.md') -Value '\n# upstream v3'
    & $sync -Scope project -ProjectPath $project -RepositoryRoot $source | Out-Null
    Assert (Test-Path -LiteralPath $unmanaged) 'sync removed unmanaged file'

    Set-Content -LiteralPath (Join-Path $sourceSkill 'local-notes.txt') -Value 'upstream collision'
    $failed = $false
    try { & $sync -Scope project -ProjectPath $project -RepositoryRoot $source | Out-Null }
    catch { $failed = $true }
    Assert $failed 'sync failed to detect new source/local file collision'
    Assert ((Get-Content -LiteralPath $unmanaged -Raw).Contains('user data')) 'collision overwrote local data'

    Write-Output 'PASS: dry-run, install, idempotency, local modification protection, sync, unmanaged file protection, collision'
}
finally {
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
}


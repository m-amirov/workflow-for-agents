$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Assert {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "ASSERT FAILED: $Message" }
}

$repo = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
. (Join-Path $repo 'scripts\SkillUtils.ps1')
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
    Assert ($installedManifest.schema -eq 1) 'manifest schema is invalid'
    Assert ($installedManifest.source -eq 'workflow-for-agents') 'manifest source is invalid'
    $installedEntry = @($installedManifest.installed | Where-Object { $_.name -eq 'task-planning' })
    Assert ($installedEntry.Count -eq 1) 'manifest has no unique task-planning entry'
    Assert ($installedEntry[0].sourceRelative -eq 'skills/core/task-planning') 'manifest source path is invalid'
    $sourceHashes = Get-FileHashes $sourceSkill
    Assert ($installedEntry[0].sourceVersion -eq (Get-SkillVersion $sourceHashes)) 'manifest version does not match source hashes'
    $targetHashes = Get-FileHashes $targetSkill
    Assert ($targetHashes['SKILL.md'] -eq $sourceHashes['SKILL.md']) 'manifest target hash does not match source hash'
    Assert ($installedManifest.installed[0].sourceVersion -match '^[a-f0-9]{64}$') 'source version fingerprint not recorded'

    & $install -Scope project -ProjectPath $project -RepositoryRoot $source -Skills task-planning | Out-Null

    $manifestOriginal = Get-Content -LiteralPath $manifest -Raw -Encoding UTF8
    $tampered = $manifestOriginal | ConvertFrom-Json
    $tampered.installed[0].sourceVersion = ('0' * 64)
    [System.IO.File]::WriteAllText($manifest, ($tampered | ConvertTo-Json -Depth 20) + [Environment]::NewLine,
        (New-Object System.Text.UTF8Encoding($false)))
    $failed = $false
    try { & $install -Scope project -ProjectPath $project -RepositoryRoot $source -Skills task-planning | Out-Null }
    catch { $failed = $true }
    Assert $failed 'install accepted a manifest with a mismatched sourceVersion'
    $syncFailed = $false
    try { & $sync -Scope project -ProjectPath $project -RepositoryRoot $source | Out-Null }
    catch { $syncFailed = $true }
    Assert $syncFailed 'sync accepted a manifest with a mismatched sourceVersion'
    [System.IO.File]::WriteAllText($manifest, $manifestOriginal, (New-Object System.Text.UTF8Encoding($false)))

    $tampered = $manifestOriginal | ConvertFrom-Json
    $tampered.installed[0].sourceRelative = 'skills/core/not-task-planning'
    [System.IO.File]::WriteAllText($manifest, ($tampered | ConvertTo-Json -Depth 20) + [Environment]::NewLine,
        (New-Object System.Text.UTF8Encoding($false)))
    $failed = $false
    try { & $install -Scope project -ProjectPath $project -RepositoryRoot $source -Skills task-planning | Out-Null }
    catch { $failed = $true }
    Assert $failed 'install accepted a manifest with a mismatched sourceRelative'
    $syncFailed = $false
    try { & $sync -Scope project -ProjectPath $project -RepositoryRoot $source | Out-Null }
    catch { $syncFailed = $true }
    Assert $syncFailed 'sync accepted a manifest with a mismatched sourceRelative'
    [System.IO.File]::WriteAllText($manifest, $manifestOriginal, (New-Object System.Text.UTF8Encoding($false)))

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

    # The CI runner uses an ephemeral user profile; verify real user-scoped path without overwriting existing data.
    $userRoot = Join-Path (Join-Path $HOME '.agents') 'skills'
    $userTarget = Join-Path $userRoot 'task-planning'
    $userManifest = Join-Path $userRoot '.workflow-for-agents.manifest.json'
    $userOwned = Join-Path $userRoot 'user-owned-skill'
    if ((Test-Path -LiteralPath $userTarget) -or (Test-Path -LiteralPath $userManifest)) {
        throw 'Unsafe user-scope test: existing managed skill or manifest in HOME'
    }
    try {
        New-Item -ItemType Directory -Path $userOwned -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $userOwned 'notes.txt') -Value 'user data' -Encoding UTF8
        & $install -Scope user -RepositoryRoot $source -Skills task-planning -DryRun | Out-Null
        Assert (-not (Test-Path -LiteralPath $userTarget)) 'user-scope dry-run changed HOME'
        & $install -Scope user -RepositoryRoot $source -Skills task-planning | Out-Null
        Assert (Test-Path -LiteralPath (Join-Path $userTarget 'SKILL.md')) 'user-scope install failed'
        Assert ((Get-Content -LiteralPath (Join-Path $userOwned 'notes.txt') -Raw).Contains('user data')) 'user-owned file was overwritten'
        & $sync -Scope user -RepositoryRoot $source | Out-Null
        Assert (Test-Path -LiteralPath $userManifest) 'user-scope sync has no manifest'
    }
    finally {
        if (Test-Path -LiteralPath $userTarget) { Remove-Item -LiteralPath $userTarget -Recurse -Force }
        if (Test-Path -LiteralPath $userManifest) { Remove-Item -LiteralPath $userManifest -Force }
        if (Test-Path -LiteralPath $userOwned) { Remove-Item -LiteralPath $userOwned -Recurse -Force }
    }

    Write-Output 'PASS: user/project scope, dry-run, manifest schema/source/version/hash integrity, install, idempotency, local edit protection, update/add/remove sync, unmanaged and user-owned file protection, collision'
}
finally {
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
}

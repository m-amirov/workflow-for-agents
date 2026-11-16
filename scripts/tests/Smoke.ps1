param([switch]$SkipUserScope)

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
    New-Item -ItemType Directory -Path (Join-Path $source 'docs') -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $repo 'docs\SKILL_CATALOG.md') -Destination (Join-Path $source 'docs\SKILL_CATALOG.md')

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

    $profileProject = Join-Path $tmp 'profile-project'
    $profileRemote = Join-Path $tmp 'profile-remote.git'
    & git init --bare --quiet $profileRemote
    & git init --quiet $profileProject
    & git -C $profileProject branch -M main
    & git -C $profileProject config user.email 'smoke@example.invalid'
    & git -C $profileProject config user.name 'Workflow Smoke'
    Set-Content -LiteralPath (Join-Path $profileProject 'README.md') -Value 'fixture' -Encoding UTF8
    & git -C $profileProject add README.md
    & git -C $profileProject commit --quiet -m 'fixture'
    & git -C $profileProject remote add origin $profileRemote
    & git -C $profileProject push --quiet -u origin main
    $profileHead = (& git -C $profileProject rev-parse HEAD).Trim()
    $profileRoot = Join-Path $source 'projects\fixture'
    New-Item -ItemType Directory -Path $profileRoot, (Join-Path $profileProject '.agents\skills\fixture-local') -Force | Out-Null
    $profileDocument = [pscustomobject]@{
        schema = 1
        id = 'fixture'
        canonical_repository = $profileRemote
        source_sha = $profileHead
        recommended_skills = @('task-planning')
        activation_conditions = @('fixture')
        protected_local_skills = @('fixture-local')
        compatibility_notes = @('fixture')
        git_workflow = 'main-first-project-refined'
        release_authorization = 'owner-required'
        stop_lines = @('fixture-stop-line')
        release_gates = @('fixture-gate')
        installation_limits = @('project only')
        update_rule = 'fixture'
    }
    [System.IO.File]::WriteAllText((Join-Path $profileRoot 'profile.json'), ($profileDocument | ConvertTo-Json -Depth 10), (New-Object System.Text.UTF8Encoding($false)))
    & $install -Scope project -ProjectPath $profileProject -RepositoryRoot $source -Profile fixture -DryRun | Out-Null
    Assert (-not (Test-Path -LiteralPath (Join-Path $profileProject '.agents\skills\task-planning'))) 'profile dry-run created destination'
    & $install -Scope project -ProjectPath $profileProject -RepositoryRoot $source -Profile fixture | Out-Null
    Assert (Test-Path -LiteralPath (Join-Path $profileProject '.agents\skills\task-planning\SKILL.md')) 'profile install did not copy selected skill'
    $currentFreshness = Get-ProfileRemoteFreshness -ProjectPath $profileProject -Profile $profileDocument
    Assert ($currentFreshness.Status -eq 'CURRENT') 'matching local/profile/remote SHA was not CURRENT'
    Set-Content -LiteralPath (Join-Path $profileProject 'LOCAL-STALE.md') -Value 'not pushed' -Encoding UTF8
    & git -C $profileProject add LOCAL-STALE.md
    & git -C $profileProject commit --quiet -m 'local stale fixture'
    $localStale = Get-ProfileRemoteFreshness -ProjectPath $profileProject -Profile $profileDocument
    Assert ($localStale.Status -eq 'LOCAL_STALE') 'unpushed local HEAD was not LOCAL_STALE'
    & git -C $profileProject reset --hard --quiet $profileHead
    Set-Content -LiteralPath (Join-Path $profileProject 'REMOTE-STALE.md') -Value 'pushed' -Encoding UTF8
    & git -C $profileProject add REMOTE-STALE.md
    & git -C $profileProject commit --quiet -m 'remote stale fixture'
    $remoteHead = (& git -C $profileProject rev-parse HEAD).Trim()
    & git -C $profileProject push --quiet origin main
    $profileStale = Get-ProfileRemoteFreshness -ProjectPath $profileProject -Profile $profileDocument
    Assert ($profileStale.Status -eq 'PROFILE_STALE') 'advanced remote main was not PROFILE_STALE'
    & git --git-dir $profileRemote update-ref refs/heads/main $profileHead
    & git -C $profileProject reset --hard --quiet $profileHead
    $unavailableUrl = Join-Path $tmp 'missing-remote.git'
    & git -C $profileProject remote set-url origin $unavailableUrl
    $unverified = Get-ProfileRemoteFreshness -ProjectPath $profileProject -Profile $profileDocument
    Assert ($unverified.Status -eq 'REMOTE_UNVERIFIED') 'unavailable remote was not REMOTE_UNVERIFIED'
    & git -C $profileProject remote set-url origin $profileRemote
    & $sync -Scope project -ProjectPath $profileProject -RepositoryRoot $source -Profile fixture | Out-Null
    $profileManifest = Join-Path $profileProject '.agents\skills\.workflow-for-agents.manifest.json'
    $profileManifestOriginal = Get-Content -LiteralPath $profileManifest -Raw -Encoding UTF8
    [System.IO.File]::WriteAllText($profileManifest, '{"schema":9}', (New-Object System.Text.UTF8Encoding($false)))
    $failed = $false
    try { & $install -Scope project -ProjectPath $profileProject -RepositoryRoot $source -Profile fixture -DryRun | Out-Null }
    catch { $failed = $true }
    Assert $failed 'profile install accepted a corrupt manifest'
    [System.IO.File]::WriteAllText($profileManifest, $profileManifestOriginal, (New-Object System.Text.UTF8Encoding($false)))
    $profileManifestHidden = "$profileManifest.hidden"
    Move-Item -LiteralPath $profileManifest -Destination $profileManifestHidden
    $failed = $false
    try { & $install -Scope project -ProjectPath $profileProject -RepositoryRoot $source -Profile fixture -DryRun | Out-Null }
    catch { $failed = $true }
    Assert $failed 'profile install treated an unmanaged local Skill as managed'
    Move-Item -LiteralPath $profileManifestHidden -Destination $profileManifest
    $plannedRoot = Join-Path $source 'projects\planned'
    New-Item -ItemType Directory -Path $plannedRoot -Force | Out-Null
    $plannedDocument = $profileDocument | Select-Object *
    $plannedDocument.id = 'planned'
    $plannedDocument.recommended_skills = @('seo-calculators')
    [System.IO.File]::WriteAllText((Join-Path $plannedRoot 'profile.json'), ($plannedDocument | ConvertTo-Json -Depth 10), (New-Object System.Text.UTF8Encoding($false)))
    $failed = $false
    try { & $install -Scope project -ProjectPath $profileProject -RepositoryRoot $source -Profile planned | Out-Null }
    catch { $failed = $true }
    Assert $failed 'profile install accepted a planned Skill'

    $wrongProject = Join-Path $tmp 'wrong-profile-project'
    $wrongRemote = Join-Path $tmp 'wrong-profile-remote.git'
    & git init --bare --quiet $wrongRemote
    & git init --quiet $wrongProject
    & git -C $wrongProject config user.email 'smoke@example.invalid'
    & git -C $wrongProject config user.name 'Workflow Smoke'
    Set-Content -LiteralPath (Join-Path $wrongProject 'README.md') -Value 'wrong' -Encoding UTF8
    & git -C $wrongProject add README.md
    & git -C $wrongProject commit --quiet -m 'wrong fixture'
    & git -C $wrongProject remote add origin $wrongRemote
    $failed = $false
    try { & $install -Scope project -ProjectPath $wrongProject -RepositoryRoot $source -Profile fixture -DryRun | Out-Null }
    catch { $failed = $true }
    Assert $failed 'profile install accepted a wrong Git remote'
    Assert (-not (Test-Path -LiteralPath (Join-Path $wrongProject '.agents\skills\task-planning'))) 'blocked preflight partially installed a Skill'

    Set-Content -LiteralPath (Join-Path $profileProject 'STALE.md') -Value 'new head' -Encoding UTF8
    & git -C $profileProject add STALE.md
    & git -C $profileProject commit --quiet -m 'stale fixture'
    $failed = $false
    try { & $install -Scope project -ProjectPath $profileProject -RepositoryRoot $source -Profile fixture -DryRun | Out-Null }
    catch { $failed = $true }
    Assert $failed 'profile install accepted stale source SHA'
    & git -C $profileProject reset --hard --quiet $profileHead

    $noGitProject = Join-Path $tmp 'no-git-profile-project'
    New-Item -ItemType Directory -Path $noGitProject -Force | Out-Null
    $failed = $false
    try { & $install -Scope project -ProjectPath $noGitProject -RepositoryRoot $source -Profile fixture -DryRun | Out-Null }
    catch { $failed = $true }
    Assert $failed 'profile install accepted a non-Git target'

    $prProfileRoot = Join-Path $source 'projects\prfixture'
    New-Item -ItemType Directory -Path $prProfileRoot -Force | Out-Null
    $prDocument = $profileDocument | Select-Object *
    $prDocument.id = 'prfixture'
    $prDocument.git_workflow = 'pr-only'
    [System.IO.File]::WriteAllText((Join-Path $prProfileRoot 'profile.json'), ($prDocument | ConvertTo-Json -Depth 10), (New-Object System.Text.UTF8Encoding($false)))
    $normalPreflight = Invoke-ProjectProfilePreflight -RepoRoot $source -ProjectPath $profileProject -Profile prfixture
    Assert ($normalPreflight.Decision -eq 'PASS') 'PR-only refinement was blocked without a direct-main request'
    $directMainPreflight = Invoke-ProjectProfilePreflight -RepoRoot $source -ProjectPath $profileProject -Profile prfixture -DirectMainRequired
    Assert ($directMainPreflight.Decision -eq 'BLOCKED') 'direct-main requirement was not blocked for PR-only profile'
    Assert (@($directMainPreflight.Findings | Where-Object { $_.Class -eq 'HARD_CONFLICT' }).Count -eq 1) 'PR-only conflict was not classified as HARD_CONFLICT'
    $prototypePreflight = Invoke-ProjectProfilePreflight -RepoRoot $source -ProjectPath $profileProject -Profile fixture -Operation prototype
    Assert ($prototypePreflight.Decision -eq 'BLOCKED') 'prototype operation was authorized by profile installation'

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
    if (-not $SkipUserScope) {
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
    } else {
        Write-Output 'SKIP: user-scope smoke requires an isolated HOME'
    }

    $scopeSummary = if ($SkipUserScope) { 'project scope (user scope skipped)' } else { 'user/project scope' }
    $protectionSummary = if ($SkipUserScope) { 'unmanaged file protection' } else { 'unmanaged and user-owned file protection' }
    Write-Output "PASS: $scopeSummary, profile selection, dry-run, manifest schema/source/version/hash integrity, install, idempotency, local edit protection, update/add/remove sync, $protectionSummary, collision"
}
finally {
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
}

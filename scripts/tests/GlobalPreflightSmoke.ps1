# Stage 10: read-only global Skills preflight regression fixtures.
# Every fixture is disposable. The real HOME is never passed to a mutating command.
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Assert {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "ASSERT FAILED: $Message" }
}

$repo = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$preflight = Join-Path $repo 'scripts\global-preflight.ps1'
$install = Join-Path $repo 'scripts\install.ps1'
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("wfa-preflight-" + [guid]::NewGuid().ToString('N'))

function New-FixtureHome {
    $path = Join-Path $tmp ([guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    return $path
}

function Copy-FixtureSkill {
    param([string]$HomeDirectory, [string]$Name, [string]$Root = '.agents\skills')
    $sourceMatches = @(Get-ChildItem -LiteralPath (Join-Path $repo 'skills') -Directory -Recurse -Force |
        Where-Object { $_.Name -eq $Name -and (Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') -PathType Leaf) })
    Assert ($sourceMatches.Count -eq 1) "source Skill is not unique: $Name"
    $target = Join-Path (Join-Path $HomeDirectory $Root) $Name
    New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
    Copy-Item -LiteralPath $sourceMatches[0].FullName -Destination $target -Recurse -Force
    return $target
}

function Install-FixtureSet {
    param([string]$HomeDirectory, [string]$Set = 'ceos-migrated')
    & $install -Scope user -RepositoryRoot $repo -HomePath $HomeDirectory -Set $Set | Out-Null
}

function Invoke-FixturePreflight {
    param([string]$HomeDirectory, [switch]$All, [string]$Set = '')
    if ($All) {
        $raw = (& $preflight -All -OutputFormat Json -HomePath $HomeDirectory | Out-String).Trim()
    } else {
        $raw = (& $preflight -Set $Set -OutputFormat Json -HomePath $HomeDirectory | Out-String).Trim()
    }
    Assert ($raw.StartsWith('{')) 'preflight did not return JSON'
    return [pscustomobject]@{ Raw = $raw; Json = ($raw | ConvertFrom-Json) }
}

function Get-Target {
    param([object]$Report, [string]$Name)
    $matches = @($Report.Targets | Where-Object { $_.Skill -eq $Name })
    Assert ($matches.Count -eq 1) "target is not unique: $Name"
    return $matches[0]
}

function Assert-Status {
    param([object]$Report, [string]$Name, [string]$Expected)
    $target = Get-Target $Report $Name
    Assert ($target.Status -eq $Expected) "$Name expected $Expected, got $($target.Status)"
    return $target
}

function Write-JsonFile {
    param([string]$Path, [object]$Value)
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    [System.IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 30) + [Environment]::NewLine,
        (New-Object System.Text.UTF8Encoding($false)))
}

function Get-HashOrNull {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

try {
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null

    # 1. Empty HOME: no directory creation and all selected Skills are absent.
    $empty = New-FixtureHome
    $beforeEmpty = @(Get-ChildItem -LiteralPath $empty -Force)
    $emptyReport = (Invoke-FixturePreflight $empty -All).Json
    Assert ($emptyReport.Summary.CheckedSelectedSkills -eq 29) 'empty HOME did not audit all implemented Skills'
    Assert ($emptyReport.Summary.SafeToInstallWithoutOwnershipConflict -eq 29) 'empty HOME did not classify all Skills as installable'
    Assert ($emptyReport.Summary.Ready -eq $true) 'empty HOME was not ready'
    Assert (-not (Test-Path -LiteralPath (Join-Path $empty '.agents'))) 'preflight created .agents in empty HOME'
    Assert (@(Get-ChildItem -LiteralPath $empty -Force).Count -eq $beforeEmpty.Count) 'empty HOME changed during preflight'

    # 2. Fully installed current migrated set.
    $full = New-FixtureHome
    Install-FixtureSet $full
    $fullReport = (Invoke-FixturePreflight $full -Set ceos-migrated).Json
    Assert (@($fullReport.Targets | Where-Object { $_.Status -ne 'CURRENT' }).Count -eq 0) 'fully installed set was not CURRENT'
    Assert ($fullReport.Manifests.WorkflowForAgents.State -eq 'VALID') 'current WFA manifest was not VALID'

    # 3. Legacy CEOS manifest and matching Skill are never treated as installable.
    $legacy = New-FixtureHome
    $legacySkill = Copy-FixtureSkill $legacy 'audit'
    Write-JsonFile (Join-Path $legacy '.codex\ceos\installation.json') ([pscustomobject]@{
        version = '0.5.41'
        skills = [pscustomobject]@{ audit = [pscustomobject]@{ source = 'legacy-ceos'; version = 'legacy-v1' } }
    })
    $legacyReport = (Invoke-FixturePreflight $legacy -Set ceos-migrated).Json
    Assert-Status $legacyReport 'audit' 'LEGACY_CEOS_MANAGED' | Out-Null
    Assert ($legacyReport.Summary.Ready -eq $false) 'legacy CEOS collision returned READY'
    Assert ((Get-HashOrNull (Join-Path $legacySkill 'SKILL.md')) -ne $null) 'legacy fixture Skill disappeared'

    # 4. Same name with different SHA and no WFA manifest is an unmanaged collision.
    $collision = New-FixtureHome
    $collisionSkill = Copy-FixtureSkill $collision 'fix'
    Add-Content -LiteralPath (Join-Path $collisionSkill 'SKILL.md') -Value "`nfixture collision" -Encoding UTF8
    $collisionReport = (Invoke-FixturePreflight $collision -Set ceos-migrated).Json
    $collisionTarget = Assert-Status $collisionReport 'fix' 'UNMANAGED_COLLISION'
    Assert ($collisionTarget.CurrentSHA -ne $collisionTarget.TargetSHA) 'collision fixture did not have different SHA'

    # 5. User Skill without a manifest remains ownership-unverified.
    $userSkill = New-FixtureHome
    $customPath = Join-Path $userSkill '.agents\skills\custom-fixture'
    New-Item -ItemType Directory -Path $customPath -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $customPath 'SKILL.md') -Value "---`nname: custom-fixture`ndescription: fixture-only skill`n---`n" -Encoding UTF8
    $userReport = (Invoke-FixturePreflight $userSkill -All).Json
    $customInventory = @($userReport.Inventory | Where-Object { $_.Skill -eq 'custom-fixture' })
    Assert ($customInventory.Count -eq 1 -and $customInventory[0].Status -eq 'OWNERSHIP_UNVERIFIED') 'custom Skill without manifest was not ownership-unverified'

    # 6. A locally modified managed Skill is USER_MODIFIED.
    $modified = New-FixtureHome
    Install-FixtureSet $modified
    Add-Content -LiteralPath (Join-Path $modified '.agents\skills\audit\SKILL.md') -Value "`nfixture local edit" -Encoding UTF8
    $modifiedReport = (Invoke-FixturePreflight $modified -Set ceos-migrated).Json
    Assert-Status $modifiedReport 'audit' 'USER_MODIFIED' | Out-Null

    # 7. Corrupt manifest is INVALID_MANIFEST and remains untouched.
    $badManifest = New-FixtureHome
    Install-FixtureSet $badManifest
    $badManifestPath = Join-Path $badManifest '.agents\skills\.workflow-for-agents.manifest.json'
    [System.IO.File]::WriteAllText($badManifestPath, '{"schema":9}', (New-Object System.Text.UTF8Encoding($false)))
    $badManifestHash = Get-HashOrNull $badManifestPath
    $badManifestReport = (Invoke-FixturePreflight $badManifest -Set ceos-migrated).Json
    Assert ($badManifestReport.Manifests.WorkflowForAgents.State -eq 'INVALID_MANIFEST') 'corrupt manifest was not INVALID_MANIFEST'
    Assert ((Get-HashOrNull $badManifestPath) -eq $badManifestHash) 'preflight changed corrupt manifest'

    # 8. Missing managed file is USER_MODIFIED, not a permission to reinstall.
    $missing = New-FixtureHome
    Install-FixtureSet $missing
    Remove-Item -LiteralPath (Join-Path $missing '.agents\skills\audit\SKILL.md') -Force
    $missingReport = (Invoke-FixturePreflight $missing -Set ceos-migrated).Json
    Assert-Status $missingReport 'audit' 'USER_MODIFIED' | Out-Null

    # 9. Incorrect manifest hash/sourceVersion is INVALID_MANIFEST.
    $badHash = New-FixtureHome
    Install-FixtureSet $badHash
    $badHashManifest = Join-Path $badHash '.agents\skills\.workflow-for-agents.manifest.json'
    $badHashDocument = Get-Content -LiteralPath $badHashManifest -Raw -Encoding UTF8 | ConvertFrom-Json
    $badHashDocument.installed[0].sourceVersion = ('0' * 64)
    Write-JsonFile $badHashManifest $badHashDocument
    $badHashReport = (Invoke-FixturePreflight $badHash -Set ceos-migrated).Json
    Assert ($badHashReport.Manifests.WorkflowForAgents.State -eq 'INVALID_MANIFEST') 'incorrect hash manifest was accepted'

    # 10. Junction is detected before traversal and classified UNSAFE_PATH.
    $junction = New-FixtureHome
    $junctionTarget = Join-Path $tmp 'junction-target'
    New-Item -ItemType Directory -Path $junctionTarget -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $junctionTarget 'SKILL.md') -Value '# junction target' -Encoding UTF8
    $junctionPath = Join-Path $junction '.agents\skills\fix'
    New-Item -ItemType Directory -Path (Split-Path -Parent $junctionPath) -Force | Out-Null
    try { New-Item -ItemType Junction -Path $junctionPath -Target $junctionTarget -ErrorAction Stop | Out-Null }
    catch { throw "Junction fixture could not be created; unsafe-path gate was not tested: $($_.Exception.Message)" }
    $junctionReport = (Invoke-FixturePreflight $junction -Set ceos-migrated).Json
    Assert-Status $junctionReport 'fix' 'UNSAFE_PATH' | Out-Null

    # 11. Traversal in manifest is UNSAFE_PATH and is not followed.
    $traversal = New-FixtureHome
    Copy-FixtureSkill $traversal 'audit' | Out-Null
    $traversalEntry = [pscustomobject]@{
        name = 'audit'; sourceRelative = 'skills/development/audit'; sourceVersion = ('0' * 64)
        files = @([pscustomobject]@{ path = '../outside.txt'; sha256 = ('0' * 64) })
    }
    Write-JsonFile (Join-Path $traversal '.agents\skills\.workflow-for-agents.manifest.json') ([pscustomobject]@{
        schema = 1; source = 'workflow-for-agents'; installed = @($traversalEntry)
    })
    $traversalReport = (Invoke-FixturePreflight $traversal -Set ceos-migrated).Json
    Assert ($traversalReport.Manifests.WorkflowForAgents.State -eq 'UNSAFE_PATH') 'manifest traversal was not UNSAFE_PATH'
    Assert-Status $traversalReport 'audit' 'UNSAFE_PATH' | Out-Null

    # 12. Partial installation is reported per Skill, without assuming a fixed set size.
    $partial = New-FixtureHome
    & $install -Scope user -RepositoryRoot $repo -HomePath $partial -Skills audit | Out-Null
    $partialReport = (Invoke-FixturePreflight $partial -Set ceos-migrated).Json
    Assert-Status $partialReport 'audit' 'CURRENT' | Out-Null
    Assert (@($partialReport.Targets | Where-Object { $_.Status -eq 'NOT_INSTALLED' }).Count -eq 14) 'partial set count was not 14 absent Skills'

    # 13. Pending transaction remains a blocking root gate and is not recovered.
    $pending = New-FixtureHome
    Install-FixtureSet $pending
    $pendingPath = Join-Path $pending '.agents\skills\.workflow-for-agents.sync-transaction'
    New-Item -ItemType Directory -Path $pendingPath -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $pendingPath 'journal.json') -Value '{"fixture":"pending"}' -Encoding UTF8
    $pendingHash = Get-HashOrNull (Join-Path $pendingPath 'journal.json')
    $pendingReport = (Invoke-FixturePreflight $pending -Set ceos-migrated).Json
    Assert ($pendingReport.Summary.Blocked -eq $true -and $pendingReport.Summary.Ready -eq $false) 'pending transaction did not block readiness'
    Assert (@($pendingReport.Summary.Blockers | Where-Object { $_ -match 'pending sync transaction' }).Count -eq 1) 'pending transaction blocker missing'
    Assert ((Get-HashOrNull (Join-Path $pendingPath 'journal.json')) -eq $pendingHash) 'preflight changed pending transaction'

    # 14. Repeated preflight on identical bytes is byte-stable.
    $repeat = New-FixtureHome
    Install-FixtureSet $repeat
    $repeatA = Invoke-FixturePreflight $repeat -Set ceos-migrated
    $repeatB = Invoke-FixturePreflight $repeat -Set ceos-migrated
    Assert ($repeatA.Raw -eq $repeatB.Raw) 'repeated preflight changed machine-readable output'

    # 15. Unknown owner with matching content is still a collision, not CURRENT.
    $unknownSame = New-FixtureHome
    Copy-FixtureSkill $unknownSame 'audit' '.codex\skills' | Out-Null
    $unknownReport = (Invoke-FixturePreflight $unknownSame -Set ceos-migrated).Json
    $unknownTarget = Assert-Status $unknownReport 'audit' 'UNMANAGED_COLLISION'
    Assert ($unknownTarget.CurrentSHA -eq $unknownTarget.TargetSHA) 'same-content unknown owner did not retain matching SHA evidence'

    # 16. Existing AGENTS.md, hooks and user settings are never read/changed by preflight.
    $settings = New-FixtureHome
    New-Item -ItemType Directory -Path (Join-Path $settings '.codex') -Force | Out-Null
    $agentsFile = Join-Path $settings '.codex\AGENTS.md'
    $hooksFile = Join-Path $settings '.codex\hooks.json'
    $configFile = Join-Path $settings '.codex\config.toml'
    Set-Content -LiteralPath $agentsFile -Value 'user AGENTS' -Encoding UTF8
    Set-Content -LiteralPath $hooksFile -Value '{"user":true}' -Encoding UTF8
    Set-Content -LiteralPath $configFile -Value 'user_setting = true' -Encoding UTF8
    $settingsHashesBefore = @{
        agents = Get-HashOrNull $agentsFile
        hooks = Get-HashOrNull $hooksFile
        config = Get-HashOrNull $configFile
    }
    $settingsReport = (Invoke-FixturePreflight $settings -All).Json
    Assert ((Get-HashOrNull $agentsFile) -eq $settingsHashesBefore.agents) 'preflight changed AGENTS.md'
    Assert ((Get-HashOrNull $hooksFile) -eq $settingsHashesBefore.hooks) 'preflight changed hooks.json'
    Assert ((Get-HashOrNull $configFile) -eq $settingsHashesBefore.config) 'preflight changed config.toml'
    Assert (-not $settingsReport.Summary.FilesChanged) 'read-only report claimed file changes'
    Assert (-not $settingsReport.Summary.InstallOrSyncInvoked) 'preflight report claimed install/sync invocation'
    Assert (-not $settingsReport.Summary.BackupCreated) 'preflight report claimed backup creation'

    Write-Output 'PASS: Stage 10 global preflight read-only fixtures (empty/current/legacy/collision/user-modified/manifest/path/pending/idempotency/settings)'
}
finally {
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
}

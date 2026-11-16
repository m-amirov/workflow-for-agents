[CmdletBinding()]
param(
    [ValidateSet('ceos-migrated')][string]$Set = '',
    [switch]$All,
    [ValidateSet('Text','Json')][string]$OutputFormat = 'Text',
    [string]$HomePath = '',
    [string]$RepositoryRoot = (Join-Path $PSScriptRoot '..')
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'SkillUtils.ps1')

if ($Set -and $All) { throw 'Use either -Set or -All, not both' }
if (-not $Set -and -not $All) { throw 'Select a target set with -Set ceos-migrated or -All' }

$repo = Get-RepoRoot $RepositoryRoot
$resolvedHome = if ($HomePath) { [System.IO.Path]::GetFullPath($HomePath) } else { [System.IO.Path]::GetFullPath($HOME) }

function Test-PreflightMapEqual {
    param([hashtable]$Expected, [hashtable]$Actual)
    if ($Expected.Count -ne $Actual.Count) { return $false }
    foreach ($key in $Expected.Keys) {
        if (-not $Actual.ContainsKey($key) -or $Actual[$key] -ne $Expected[$key]) { return $false }
    }
    return $true
}

function Get-PreflightSourceRecords {
    param([string]$RepoRoot, [string[]]$SelectedNames)
    $available = Get-AvailableSkills $RepoRoot
    $records = New-Object System.Collections.Generic.List[object]
    foreach ($name in @($SelectedNames | Sort-Object)) {
        if (-not $available.ContainsKey($name)) {
            $records.Add([pscustomobject]@{
                Name = $name; Present = $false; Directory = $null; SourceRelative = $null
                FileMap = @{}; TargetSkillSha = $null; TargetVersion = $null
                Metadata = $null; Error = 'Source Skill is missing'
            })
            continue
        }
        $skill = $available[$name]
        try {
            $map = Get-FileHashes $skill.Directory
            $metadata = Get-PreflightSkillMetadata (Join-Path $skill.Directory 'SKILL.md')
            $records.Add([pscustomobject]@{
                Name = $name; Present = $true; Directory = $skill.Directory
                SourceRelative = $skill.SourceRelative; FileMap = $map
                TargetSkillSha = if ($map.ContainsKey('SKILL.md')) { $map['SKILL.md'] } else { $null }
                TargetVersion = Get-SkillVersion $map; Metadata = $metadata; Error = $null
            })
        }
        catch {
            $records.Add([pscustomobject]@{
                Name = $name; Present = $false; Directory = $skill.Directory
                SourceRelative = $skill.SourceRelative; FileMap = @{}
                TargetSkillSha = $null; TargetVersion = $null; Metadata = $null
                Error = $_.Exception.Message
            })
        }
    }
    return $records.ToArray()
}

function Get-PreflightRootsAndCandidates {
    param([string]$HomeDirectory)
    $roots = @(
        [pscustomobject]@{ Key = 'agents'; Label = '~/.agents/skills'; Path = Join-Path (Join-Path $HomeDirectory '.agents') 'skills'; Exists = $false; Safe = $true; Error = $null; Pending = $false }
        [pscustomobject]@{ Key = 'codex'; Label = '~/.codex/skills'; Path = Join-Path (Join-Path $HomeDirectory '.codex') 'skills'; Exists = $false; Safe = $true; Error = $null; Pending = $false }
    )
    $candidates = New-Object System.Collections.Generic.List[object]
    foreach ($rootInfo in $roots) {
        $root = $rootInfo.Path
        $rootParent = Split-Path -Parent $root
        if (Test-Path -LiteralPath $rootParent -PathType Container) {
            $parentItem = Get-Item -LiteralPath $rootParent -Force
            if (($parentItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                $rootInfo.Safe = $false
                $rootInfo.Error = "Reparse point in Skills path: $rootParent"
                continue
            }
        }
        if (-not (Test-Path -LiteralPath $root -PathType Container)) { continue }
        $rootInfo.Exists = $true
        try {
            $rootItem = Get-Item -LiteralPath $root -Force
            if (($rootItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                $rootInfo.Safe = $false
                $rootInfo.Error = "Reparse point: $root"
                continue
            }
            $transaction = Get-SyncTransactionPath $root
            if ((Test-Path -LiteralPath $transaction) -or (Test-Path -LiteralPath (Get-InstallTransactionPath $root))) { $rootInfo.Pending = $true }
            foreach ($directory in @(Get-ChildItem -LiteralPath $root -Directory -Force)) {
                if ($directory.Name -eq (Split-Path -Leaf $transaction) -or
                    $directory.Name -eq '.workflow-for-agents.install-transaction') { continue }
                $unsafe = (($directory.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
                $snapshot = if ($unsafe) {
                    [pscustomobject]@{ Exists = $true; Safe = $false; Error = "Reparse point: $($directory.FullName)"; AllFiles = @(); Files = @{}; MissingFiles = @(); SkillMdPresent = $false; SkillMdSha256 = $null; Version = $null }
                } else {
                    Get-PreflightTreeSnapshot -Directory $directory.FullName -HashFiles @('SKILL.md')
                }
                $candidates.Add([pscustomobject]@{
                    RootKey = $rootInfo.Key; RootLabel = $rootInfo.Label; Path = $directory.FullName
                    Name = $directory.Name; Snapshot = $snapshot; Virtual = $false
                })
            }
        }
        catch {
            $rootInfo.Safe = $false
            $rootInfo.Error = $_.Exception.Message
        }
    }
    return [pscustomobject]@{ Roots = $roots; Candidates = $candidates.ToArray() }
}

function Get-PreflightCandidateClassification {
    param(
        [object]$Candidate,
        [object]$Source,
        [object]$WorkflowManifest,
        [object]$LegacyManifest
    )
    $name = [string]$Candidate.Name
    $entry = $null
    if ($Candidate.RootKey -eq 'agents' -and $WorkflowManifest.State -eq 'VALID' -and
        $WorkflowManifest.EntryByName.ContainsKey($name)) {
        $entry = $WorkflowManifest.EntryByName[$name]
    }

    if (-not $Candidate.Snapshot.Safe) {
        return [pscustomobject]@{ Status = 'UNSAFE_PATH'; Owner = 'unknown'; Reason = $Candidate.Snapshot.Error; Candidate = $Candidate; Entry = $entry }
    }
    if (-not $Candidate.Snapshot.Exists -and $Candidate.Virtual -and $Candidate.RootKey -eq 'agents' -and $null -ne $entry) {
        return [pscustomobject]@{ Status = 'INVALID_MANIFEST'; Owner = 'workflow-for-agents'; Reason = 'Manifest lists a Skill directory that is missing'; Candidate = $Candidate; Entry = $entry }
    }
    if ($Candidate.RootKey -eq 'agents' -and $WorkflowManifest.State -in @('INVALID_MANIFEST','UNSAFE_PATH')) {
        return [pscustomobject]@{ Status = $WorkflowManifest.State; Owner = 'unknown'; Reason = $WorkflowManifest.Error; Candidate = $Candidate; Entry = $null }
    }
    if ($null -ne $entry -and $LegacyManifest.State -eq 'VALID' -and $LegacyManifest.SkillByName.ContainsKey($name)) {
        return [pscustomobject]@{ Status = 'OWNERSHIP_UNVERIFIED'; Owner = 'conflicting-manifests'; Reason = 'Both workflow-for-agents and legacy CEOS manifests name this Skill'; Candidate = $Candidate; Entry = $entry }
    }
    if ($LegacyManifest.State -eq 'VALID' -and $LegacyManifest.SkillByName.ContainsKey($name)) {
        return [pscustomobject]@{ Status = 'LEGACY_CEOS_MANAGED'; Owner = 'legacy-ceos'; Reason = 'Named by .codex/ceos/installation.json'; Candidate = $Candidate; Entry = $entry }
    }
    if ($null -ne $entry) {
        if ($null -eq $Source -or -not $Source.Present -or $entry.SourceRelative -ne $Source.SourceRelative) {
            return [pscustomobject]@{ Status = 'INVALID_MANIFEST'; Owner = 'workflow-for-agents'; Reason = 'Manifest source binding does not match the current source'; Candidate = $Candidate; Entry = $entry }
        }
        $expected = $entry.Files
        $actual = Get-PreflightTreeSnapshot -Directory $Candidate.Path -HashFiles @($expected.Keys)
        if (-not $actual.Safe) {
            return [pscustomobject]@{ Status = 'UNSAFE_PATH'; Owner = 'workflow-for-agents'; Reason = $actual.Error; Candidate = $Candidate; Entry = $entry }
        }
        $Candidate.Snapshot = $actual
        $managedMatches = $true
        foreach ($key in $expected.Keys) {
            if (-not $actual.Files.ContainsKey($key) -or $actual.Files[$key] -ne $expected[$key]) { $managedMatches = $false; break }
        }
        $extra = @($actual.AllFiles | Where-Object { -not $expected.ContainsKey($_) })
        if (-not $managedMatches -or $actual.MissingFiles.Count -gt 0 -or $extra.Count -gt 0) {
            return [pscustomobject]@{ Status = 'USER_MODIFIED'; Owner = 'workflow-for-agents'; Reason = 'Managed files differ, are missing, or have unmanaged extras'; Candidate = $Candidate; Entry = $entry }
        }
        if (Test-PreflightMapEqual $Source.FileMap $actual.Files) {
            return [pscustomobject]@{ Status = 'CURRENT'; Owner = 'workflow-for-agents'; Reason = 'Manifest, local files and source hashes match'; Candidate = $Candidate; Entry = $entry }
        }
        return [pscustomobject]@{ Status = 'UPDATE_AVAILABLE'; Owner = 'workflow-for-agents'; Reason = 'Managed local files match the manifest; source fingerprint changed'; Candidate = $Candidate; Entry = $entry }
    }
    if ($null -ne $Source -and $Source.Present -and $name -eq $Source.Name) {
        return [pscustomobject]@{ Status = 'UNMANAGED_COLLISION'; Owner = 'unmanaged-or-other-system'; Reason = 'Central Skill name exists without confirmed workflow-for-agents ownership'; Candidate = $Candidate; Entry = $null }
    }
    return [pscustomobject]@{ Status = 'OWNERSHIP_UNVERIFIED'; Owner = 'unknown'; Reason = 'No trusted ownership metadata for this Skill'; Candidate = $Candidate; Entry = $null }
}

function Get-PreflightStatusPriority {
    param([string]$Status)
    switch ($Status) {
        'UNSAFE_PATH' { return 100 }
        'INVALID_MANIFEST' { return 90 }
        'LEGACY_CEOS_MANAGED' { return 80 }
        'USER_MODIFIED' { return 70 }
        'UNMANAGED_COLLISION' { return 60 }
        'OWNERSHIP_UNVERIFIED' { return 50 }
        'UPDATE_AVAILABLE' { return 30 }
        'CURRENT' { return 20 }
        'NOT_INSTALLED' { return 10 }
        default { return 95 }
    }
}

function Get-PreflightAction {
    param([string]$Status)
    switch ($Status) {
        'NOT_INSTALLED' { return 'Install missing Skill after separate dry-run and approval' }
        'CURRENT' { return 'Leave unchanged' }
        'UPDATE_AVAILABLE' { return 'Update unchanged managed copy through existing sync after dry-run' }
        'USER_MODIFIED' { return 'Preserve user changes; require manual migration decision' }
        'LEGACY_CEOS_MANAGED' { return 'Require backup-backed ownership migration and explicit owner approval' }
        'UNMANAGED_COLLISION' { return 'Preserve existing Skill; confirm owner before any change' }
        'OWNERSHIP_UNVERIFIED' { return 'Leave unchanged; confirm owner and manifest first' }
        'INVALID_MANIFEST' { return 'Block until manifest is restored and verified' }
        'UNSAFE_PATH' { return 'Block until symlink/junction/path traversal is investigated' }
        default { return 'Block until manually classified' }
    }
}

function Get-PreflightTargetRecords {
    param(
        [object[]]$Sources,
        [object[]]$Candidates,
        [object]$Roots,
        [object]$WorkflowManifest,
        [object]$LegacyManifest
    )
    $records = New-Object System.Collections.Generic.List[object]
    foreach ($source in @($Sources | Sort-Object Name)) {
        $matches = @($Candidates | Where-Object { $_.Name -eq $source.Name })
        if ($matches.Count -eq 0 -and $WorkflowManifest.State -eq 'VALID' -and $WorkflowManifest.EntryByName.ContainsKey($source.Name)) {
            $agentsRoot = @($Roots | Where-Object { $_.Key -eq 'agents' })[0]
            $matches = @([pscustomobject]@{
                RootKey = 'agents'; RootLabel = '~/.agents/skills';
                Path = Join-Path $agentsRoot.Path $source.Name; Name = $source.Name
                Snapshot = [pscustomobject]@{ Exists = $false; Safe = $true; Error = $null; AllFiles = @(); Files = @{}; MissingFiles = @('manifest-listed'); SkillMdPresent = $false; SkillMdSha256 = $null; Version = $null }
                Virtual = $true
            })
        }
        if ($matches.Count -eq 0 -and $LegacyManifest.State -eq 'VALID' -and $LegacyManifest.SkillByName.ContainsKey($source.Name)) {
            $matches = @([pscustomobject]@{
                RootKey = 'legacy'; RootLabel = '~/.codex/ceos/installation.json'; Path = $null; Name = $source.Name
                Snapshot = [pscustomobject]@{ Exists = $false; Safe = $true; Error = $null; AllFiles = @(); Files = @{}; MissingFiles = @(); SkillMdPresent = $false; SkillMdSha256 = $null; Version = $null }
                Virtual = $true
            })
        }
        if ($matches.Count -eq 0) {
            $status = if ($source.Present) { 'NOT_INSTALLED' } else { 'INVALID_MANIFEST' }
            $classification = [pscustomobject]@{ Status = $status; Owner = 'none'; Reason = if ($source.Present) { 'No matching global Skill directory was found' } else { $source.Error }; Candidate = $null; Entry = $null }
            $matches = @()
        } else {
            $classifications = @($matches | ForEach-Object { Get-PreflightCandidateClassification $_ $source $WorkflowManifest $LegacyManifest })
            $classification = @($classifications | Sort-Object @{Expression={ Get-PreflightStatusPriority $_.Status }; Descending=$true }, @{Expression={$_.Candidate.RootKey}})[0]
            if ($classifications.Count -gt 1 -and $classification.Status -in @('CURRENT','UPDATE_AVAILABLE')) {
                $classification = [pscustomobject]@{ Status = 'UNMANAGED_COLLISION'; Owner = 'conflicting-copies'; Reason = 'More than one global directory contains the same Skill name'; Candidate = $classification.Candidate; Entry = $classification.Entry }
            }
        }
        $currentSha = if ($null -ne $classification.Candidate) { $classification.Candidate.Snapshot.SkillMdSha256 } else { $null }
        $records.Add([pscustomobject]@{
            Skill = $source.Name
            CurrentOwner = $classification.Owner
            CurrentPath = if ($null -ne $classification.Candidate) { $classification.Candidate.Path } else { $null }
            CurrentSHA = $currentSha
            CurrentVersion = if ($null -ne $classification.Candidate) { $classification.Candidate.Snapshot.Version } else { $null }
            TargetSHA = $source.TargetSkillSha
            TargetVersion = $source.TargetVersion
            CurrentFingerprintScope = if ($null -ne $classification.Entry) { 'manifest-listed' } elseif ($null -ne $classification.Candidate) { 'skill-md-only' } else { $null }
            TargetFingerprintScope = if ($source.Present) { 'source-tree' } else { $null }
            Status = $classification.Status
            RequiredAction = Get-PreflightAction $classification.Status
            Reason = $classification.Reason
            HasSkillMd = if ($null -ne $classification.Candidate) { $classification.Candidate.Snapshot.SkillMdPresent } else { $false }
            Locations = @($matches | ForEach-Object { if ($_.Path) { $_.Path } else { $_.RootLabel } } | Sort-Object)
            SourceRelative = $source.SourceRelative
            SourceMetadata = if ($source.Metadata) { [pscustomobject]@{ Migration = $source.Metadata.Migration; SourceSha = $source.Metadata.SourceSha; Status = $source.Metadata.Status } } else { $null }
            ActivationDescription = if ($source.Metadata) { $source.Metadata.Description } else { '' }
        })
    }
    return $records.ToArray()
}

function Get-PreflightInventoryRecords {
    param([object[]]$Candidates,[object]$WorkflowManifest,[object]$LegacyManifest,[object[]]$Sources)
    $sourceByName = @{}
    foreach ($source in $Sources) { $sourceByName[$source.Name] = $source }
    $records = New-Object System.Collections.Generic.List[object]
    foreach ($candidate in @($Candidates | Sort-Object RootKey, Name)) {
        $source = if ($sourceByName.ContainsKey($candidate.Name)) { $sourceByName[$candidate.Name] } else { $null }
        $classification = Get-PreflightCandidateClassification $candidate $source $WorkflowManifest $LegacyManifest
        $records.Add([pscustomobject]@{
            Skill = $candidate.Name; Path = $candidate.Path; Root = $candidate.RootLabel
            HasSkillMd = $candidate.Snapshot.SkillMdPresent; CurrentSHA = $candidate.Snapshot.SkillMdSha256
            CurrentVersion = $candidate.Snapshot.Version; CurrentOwner = $classification.Owner
            FingerprintScope = if ($classification.Entry) { 'manifest-listed' } else { 'skill-md-only' }
            Status = $classification.Status; Reason = $classification.Reason
            CentralTarget = ($null -ne $source -and $source.Present)
        })
    }
    return $records.ToArray()
}

function Get-PreflightOverlapRecords {
    param([object[]]$Sources,[string[]]$ImplementedNames)
    $records = New-Object System.Collections.Generic.List[object]
    foreach ($source in @($Sources | Where-Object { $_.Metadata -and $_.Metadata.Overlaps.Count -gt 0 } | Sort-Object Name)) {
        foreach ($overlap in @($source.Metadata.Overlaps | Sort-Object)) {
            if ($ImplementedNames -contains $overlap) {
                $records.Add([pscustomobject]@{
                    MigratedSkill = $source.Name; ExistingSkill = $overlap
                    Reason = 'Declared metadata overlap; inspect activation descriptions, preserve both until explicit ownership/product decision'
                    MigratedActivation = $source.Metadata.Description
                })
            }
        }
    }
    return $records.ToArray()
}

function New-PreflightMigrationPlan {
    param([object[]]$Targets,[object]$Roots,[object]$WorkflowManifest,[object]$LegacyManifest)
    return [pscustomobject]@{
        Mode = 'plan-only; no migration executed'
        Preserve = @(
            'All existing global Skill directories and SKILL.md bytes until ownership approval',
            'The current .agents/skills/.workflow-for-agents.manifest.json, if present',
            'The current .codex/ceos/installation.json, if present',
            'AGENTS.md, hooks, config and other user settings; preflight never edits or backs them up'
        )
        FutureSequence = @(
            'Capture a user-approved backup of the legacy manifest and affected Skill directories outside the live HOME',
            'Record current SHA-256 hashes and compare them with this report and the expected source fingerprints',
            'Obtain explicit ownership-migration approval for each LEGACY_CEOS_MANAGED, USER_MODIFIED, UNMANAGED_COLLISION or OWNERSHIP_UNVERIFIED row',
            'Run the existing install/sync dry-run against an isolated or explicitly approved HOME and inspect the planned changes',
            'Only after approval, perform the smallest existing install/sync operation; never use a force-migrate path',
            'Re-run global-preflight, then verify manifest, file hashes, user settings and rollback evidence'
        )
        ExpectedHashes = @($Targets | ForEach-Object { [pscustomobject]@{ Skill = $_.Skill; CurrentSHA = $_.CurrentSHA; TargetSHA = $_.TargetSHA; TargetVersion = $_.TargetVersion } })
        Rollback = @(
            'If a future managed sync fails, use the existing pending transaction recovery only after inspecting its journal and hashes',
            'If ownership transfer was approved and then fails verification, restore the external backup and keep the old owner manifest until re-audit',
            'Never delete the legacy manifest or overwrite user-modified files as part of automatic recovery'
        )
        RequiredApprovals = @(
            'Explicit owner approval for backup location and each ownership transfer',
            'Explicit approval to modify or remove legacy CEOS ownership metadata',
            'Separate authorization for any real HOME write; this Stage 10 preflight does not grant it'
        )
        BlockedWhen = @(
            'Manifest is invalid or missing a managed Skill',
            'A Skill or root is a symlink/junction/reparse point, or a manifest contains traversal',
            'A pending sync transaction exists',
            'The current owner is user-modified, unmanaged or otherwise unverified',
            'Expected source bytes or source catalog cannot be read'
        )
    }
}

function Get-PreflightSourceCommitSha {
    param([string]$RepoRoot)
    try {
        $value = @(& git -C $RepoRoot rev-parse HEAD 2>$null)
        if ($LASTEXITCODE -eq 0 -and $value.Count -gt 0) { return ([string]$value[0]).Trim() }
    } catch { }
    return $null
}

function New-PreflightNotRunReport {
    param([string]$Reason)
    return [pscustomobject]@{
        Schema = 1
        Tool = 'workflow-for-agents.global-preflight'
        Mode = 'read-only'
        Selection = if ($Set) { $Set } else { 'All implemented Skills' }
        Input = [pscustomobject]@{
            HomePath = $resolvedHome
            ExplicitHomePath = [bool]$HomePath
            RealHomeAudit = "NOT RUN: $Reason"
            RepositoryRoot = $repo
        }
        Source = [pscustomobject]@{
            Repository = 'workflow-for-agents'
            CurrentSourceCommit = Get-PreflightSourceCommitSha $repo
            HistoricalCeosSourceSha = 'c8cc13bd3852409be93097ee823e9cd35e512b73'
            ImplementedCount = $null
            SelectedCount = $null
        }
        States = @('NOT_INSTALLED','CURRENT','UPDATE_AVAILABLE','USER_MODIFIED','LEGACY_CEOS_MANAGED','UNMANAGED_COLLISION','OWNERSHIP_UNVERIFIED','INVALID_MANIFEST','UNSAFE_PATH')
        Manifests = [pscustomobject]@{
            WorkflowForAgents = [pscustomobject]@{ Path = Join-Path (Join-Path $resolvedHome '.agents') 'skills\.workflow-for-agents.manifest.json'; Present = $false; State = 'NOT_RUN'; Error = $Reason; Entries = @() }
            LegacyCeos = [pscustomobject]@{ Path = Join-Path (Join-Path $resolvedHome '.codex') 'ceos\installation.json'; Present = $false; State = 'NOT_RUN'; Error = $Reason; Version = $null; Skills = @() }
        }
        Roots = @()
        Inventory = @()
        Targets = @()
        FunctionalOverlaps = @()
        MigrationPlan = [pscustomobject]@{ Mode = 'not-run'; Reason = $Reason }
        Summary = [pscustomobject]@{
            DiscoveredSkillDirectories = 0; CheckedSelectedSkills = 0
            SafeToInstallWithoutOwnershipConflict = 0; SafeToUpdateManagedSkills = 0
            RequiringMigrationAuthorization = 0; StatusCounts = @{}
            Ready = $false; Blocked = $true; Blockers = @($Reason)
            FilesChanged = $false; InstallOrSyncInvoked = $false; BackupCreated = $false
        }
    }
}

if (-not (Test-Path -LiteralPath $resolvedHome -PathType Container)) {
    $notRun = New-PreflightNotRunReport 'Home directory is not accessible'
    if ($OutputFormat -eq 'Json') { $notRun | ConvertTo-Json -Depth 20 } else {
        Write-Output 'Workflow for Agents - Global Skills preflight (READ-ONLY)'
        Write-Output "NOT RUN: $($notRun.Input.RealHomeAudit)"
    }
    return
}

$homeItem = Get-Item -LiteralPath $resolvedHome -Force
if (($homeItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
    $homeUnsafeReason = 'HomePath is a reparse point; traversal was refused'
    $notRun = New-PreflightNotRunReport $homeUnsafeReason
    $notRun.Summary.Blockers = @('UNSAFE_PATH: ' + $homeUnsafeReason)
    if ($OutputFormat -eq 'Json') { $notRun | ConvertTo-Json -Depth 20 } else {
        Write-Output 'Workflow for Agents - Global Skills preflight (READ-ONLY)'
        Write-Output "NOT RUN: $($notRun.Input.RealHomeAudit)"
    }
    return
}

$implementedNames = @(Get-PreflightImplementedSkillNames $repo)
$selectedNames = if ($Set) { @(Get-SkillSetNames $Set) } else { @($implementedNames) }
$sources = @(Get-PreflightSourceRecords $repo $selectedNames)
$allSourceRecords = @(Get-PreflightSourceRecords $repo $implementedNames)
$global = Get-PreflightRootsAndCandidates $resolvedHome
$agentsRoot = @($global.Roots | Where-Object { $_.Key -eq 'agents' })[0]
$workflowManifest = if ($agentsRoot.Exists -and -not $agentsRoot.Safe) {
    [pscustomobject]@{
        Path = Join-Path $agentsRoot.Path '.workflow-for-agents.manifest.json'; Present = $false
        State = 'UNSAFE_PATH'; Error = $agentsRoot.Error; Entries = @(); EntryByName = @{}
    }
} else {
    Get-PreflightManifestInspection (Join-Path $agentsRoot.Path '.workflow-for-agents.manifest.json')
}
$legacyManifest = Get-PreflightLegacyManifestInspection $resolvedHome
$targets = @(Get-PreflightTargetRecords $sources $global.Candidates $global.Roots $workflowManifest $legacyManifest)
$inventory = @(Get-PreflightInventoryRecords $global.Candidates $workflowManifest $legacyManifest $allSourceRecords)
$overlaps = @(Get-PreflightOverlapRecords $allSourceRecords $implementedNames)

$blockers = New-Object System.Collections.Generic.List[string]
foreach ($rootInfo in @($global.Roots)) {
    if (-not $rootInfo.Safe) { $blockers.Add("$($rootInfo.Label): $($rootInfo.Error)") }
    if ($rootInfo.Pending) { $blockers.Add("$($rootInfo.Label): pending sync transaction or install transaction; preflight does not recover or unlock it") }
}
if ($workflowManifest.State -in @('INVALID_MANIFEST','UNSAFE_PATH')) { $blockers.Add("workflow-for-agents manifest: $($workflowManifest.Error)") }
if ($legacyManifest.State -in @('INVALID_MANIFEST','UNSAFE_PATH')) { $blockers.Add("legacy CEOS manifest: $($legacyManifest.Error)") }
foreach ($target in $targets) {
    if ($target.Status -in @('LEGACY_CEOS_MANAGED','UNMANAGED_COLLISION','USER_MODIFIED','OWNERSHIP_UNVERIFIED','INVALID_MANIFEST','UNSAFE_PATH')) {
        $blockers.Add("$($target.Skill): $($target.Status)")
    }
}

$statusCounts = @{}
foreach ($target in $targets) {
    if (-not $statusCounts.ContainsKey($target.Status)) { $statusCounts[$target.Status] = 0 }
    $statusCounts[$target.Status]++
}
$safeInstall = if ($blockers.Count -eq 0) { @($targets | Where-Object { $_.Status -eq 'NOT_INSTALLED' }).Count } else { 0 }
$safeUpdate = @($targets | Where-Object { $_.Status -eq 'UPDATE_AVAILABLE' }).Count
$requiresAuth = @($targets | Where-Object { $_.Status -in @('LEGACY_CEOS_MANAGED','USER_MODIFIED','UNMANAGED_COLLISION','OWNERSHIP_UNVERIFIED') }).Count
$ready = ($blockers.Count -eq 0 -and @($targets | Where-Object { $_.Status -notin @('NOT_INSTALLED','CURRENT','UPDATE_AVAILABLE') }).Count -eq 0)
$sourceCommit = Get-PreflightSourceCommitSha $repo

$report = [pscustomobject]@{
    Schema = 1
    Tool = 'workflow-for-agents.global-preflight'
    Mode = 'read-only'
    Selection = if ($Set) { $Set } else { 'All implemented Skills' }
    Input = [pscustomobject]@{
        HomePath = $resolvedHome
        ExplicitHomePath = [bool]$HomePath
        RealHomeAudit = if ($HomePath) { 'NOT RUN: explicit disposable/fixture HomePath' } else { 'RUN: current HOME read-only' }
        RepositoryRoot = $repo
    }
    Source = [pscustomobject]@{
        Repository = 'workflow-for-agents'
        CurrentSourceCommit = $sourceCommit
        HistoricalCeosSourceSha = 'c8cc13bd3852409be93097ee823e9cd35e512b73'
        ImplementedCount = $implementedNames.Count
        SelectedCount = $selectedNames.Count
    }
    States = @('NOT_INSTALLED','CURRENT','UPDATE_AVAILABLE','USER_MODIFIED','LEGACY_CEOS_MANAGED','UNMANAGED_COLLISION','OWNERSHIP_UNVERIFIED','INVALID_MANIFEST','UNSAFE_PATH')
    Manifests = [pscustomobject]@{
        WorkflowForAgents = [pscustomobject]@{ Path = $workflowManifest.Path; Present = $workflowManifest.Present; State = $workflowManifest.State; Error = $workflowManifest.Error; Entries = @($workflowManifest.Entries | ForEach-Object { [pscustomobject]@{ Name = $_.Name; SourceRelative = $_.SourceRelative; SourceVersion = $_.SourceVersion; FileCount = $_.Files.Count } }) }
        LegacyCeos = [pscustomobject]@{ Path = $legacyManifest.Path; Present = $legacyManifest.Present; State = $legacyManifest.State; Error = $legacyManifest.Error; Version = $legacyManifest.Version; Skills = @($legacyManifest.Skills | ForEach-Object { [pscustomobject]@{ Name = $_.Name; Evidence = $_.Evidence; Source = $_.Source; Version = $_.Version; Sha256 = $_.Sha256 } }) }
    }
    Roots = @($global.Roots | ForEach-Object { [pscustomobject]@{ Label = $_.Label; Path = $_.Path; Exists = $_.Exists; Safe = $_.Safe; PendingTransaction = $_.Pending; Error = $_.Error } })
    Inventory = $inventory
    Targets = $targets
    FunctionalOverlaps = $overlaps
    MigrationPlan = New-PreflightMigrationPlan $targets $global.Roots $workflowManifest $legacyManifest
    Summary = [pscustomobject]@{
        DiscoveredSkillDirectories = $inventory.Count
        CheckedSelectedSkills = $targets.Count
        SafeToInstallWithoutOwnershipConflict = $safeInstall
        SafeToUpdateManagedSkills = $safeUpdate
        RequiringMigrationAuthorization = $requiresAuth
        StatusCounts = $statusCounts
        Ready = $ready
        Blocked = ($blockers.Count -gt 0)
        Blockers = @($blockers | Select-Object -Unique)
        FilesChanged = $false
        InstallOrSyncInvoked = $false
        BackupCreated = $false
    }
}

if ($OutputFormat -eq 'Json') {
    $report | ConvertTo-Json -Depth 30
    return
}

Write-Output 'Workflow for Agents - Global Skills preflight (READ-ONLY)'
Write-Output "Selection: $($report.Selection); Home: $($report.Input.HomePath)"
Write-Output "Real HOME audit: $($report.Input.RealHomeAudit); source commit: $($report.Source.CurrentSourceCommit)"
Write-Output "Discovered directories: $($report.Summary.DiscoveredSkillDirectories); selected targets: $($report.Summary.CheckedSelectedSkills)"
Write-Output ''
Write-Output 'Skill`tOwner`tCurrent SHA`tTarget SHA`tStatus`tRequired action'
foreach ($target in @($targets | Sort-Object Skill)) {
    Write-Output "$($target.Skill)`t$($target.CurrentOwner)`t$($target.CurrentSHA)`t$($target.TargetSHA)`t$($target.Status)`t$($target.RequiredAction)"
}
Write-Output ''
Write-Output "Safe to install: $safeInstall; safe managed updates: $safeUpdate; migration authorization required: $requiresAuth"
Write-Output "READY: $ready; BLOCKED: $($blockers.Count -gt 0)"
if ($blockers.Count -gt 0) {
    Write-Output 'Blockers:'
    foreach ($blocker in @($blockers | Select-Object -Unique)) { Write-Output "- $blocker" }
}
if ($overlaps.Count -gt 0) {
    Write-Output 'Declared migrated/central functional overlaps:'
    foreach ($overlap in $overlaps) { Write-Output "- $($overlap.MigratedSkill) <-> $($overlap.ExistingSkill): $($overlap.Reason)" }
}
Write-Output 'No install, sync, recovery, backup, manifest deletion or ownership migration was executed.'

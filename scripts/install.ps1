[CmdletBinding()]
param(
    [ValidateSet('user','project')][string]$Scope = 'user',
    [string]$ProjectPath = '.',
    [string[]]$Skills = @(),
    [switch]$All,
    [ValidateSet('ceos-migrated')][string]$Set = '',
    [string]$Profile = '',
    [switch]$DryRun,
    [switch]$Recover,
    [string]$BackupPath = '',
    [ValidateSet('None','AfterFirstMove','BeforeManifest','AfterManifest','InterruptAfterFirstMove','InterruptDuringStaging')]
    [string]$TestFailurePoint = 'None',
    [string]$HomePath = '',
    [string]$RepositoryRoot = (Join-Path $PSScriptRoot '..')
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'SkillUtils.ps1')
. (Join-Path $PSScriptRoot 'SyncTransaction.ps1')
. (Join-Path $PSScriptRoot 'InstallTransaction.ps1')

$destination = Get-SkillsDestination $Scope $ProjectPath $HomePath
$manifestPath = Join-Path $destination '.workflow-for-agents.manifest.json'
if (Test-Path -LiteralPath $destination) { Assert-NotLinked $destination }
if ($Recover) {
    if ($DryRun -or $Skills.Count -gt 0 -or $All -or $Set -or $Profile -or
        $BackupPath -or $TestFailurePoint -ne 'None') {
        throw 'Use -Recover alone without Skills, All, Set, Profile, DryRun, BackupPath or TestFailurePoint'
    }
    Assert-NoPendingSyncTransaction $destination
    Restore-InstallTransaction -Destination $destination -ManifestPath $manifestPath
    return
}
Assert-NoPendingInstallTransaction $destination
Assert-NoPendingSyncTransaction $destination
if ($TestFailurePoint -ne 'None') {
    if ($Scope -ne 'user' -or -not $HomePath) {
        throw 'Install test fault injection requires explicit -Scope user -HomePath disposable fixture'
    }
    $testHome = [System.IO.Path]::GetFullPath($HomePath).TrimEnd([char[]]@('\','/'))
    $realHome = [System.IO.Path]::GetFullPath($HOME).TrimEnd([char[]]@('\','/'))
    $tempPrefix = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd([char[]]@('\','/')) + [System.IO.Path]::DirectorySeparatorChar
    if ($testHome.Equals($realHome,[System.StringComparison]::OrdinalIgnoreCase) -or
        -not $testHome.StartsWith($tempPrefix,[System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'Install test fault injection requires a disposable HOME under system TEMP'
    }
    $marker = Join-Path $testHome '.wfa-install-transaction-test-home'
    if (-not (Test-Path -LiteralPath $marker -PathType Leaf)) {
        throw "Install test fault injection requires test marker: $marker"
    }
    Assert-NotLinked $testHome
    Assert-NotLinked $marker
}
$repo = Get-RepoRoot $RepositoryRoot
$available = Get-AvailableSkills $repo
if ($Profile) {
    if ($Scope -ne 'project') { throw 'Project profiles can only be installed with -Scope project' }
    if ($All -or $Skills.Count -gt 0 -or $Set) { throw 'Use -Profile alone; do not combine it with -Skills, -Set or -All' }
    $preflight = Invoke-ProjectProfilePreflight -RepoRoot $repo -ProjectPath $ProjectPath -Profile $Profile
    Assert-ProjectProfilePreflight $preflight
    $selected = @(Get-SelectedNames $available $preflight.Skills)
} else {
    $selected = @(Get-SelectedNames $available $Skills -All:$All -Set $Set)
}
$legacy = Get-LegacyCeosOwnership $HomePath
Assert-NoLegacyCeosCollision $legacy $selected
$manifest = Read-Manifest $manifestPath
$planned = @()

foreach ($name in $selected) {
    $skill = $available[$name]
    $sourceMap = Get-FileHashes $skill.Directory
    $target = Join-Path $destination $name
    $managed = @($manifest.installed | Where-Object { $_.name -eq $name })
    if ($managed.Count -gt 1) { throw "Duplicate installed skill: $name" }
    if ($managed.Count -eq 1 -and $managed[0].sourceRelative -ne $skill.SourceRelative) {
        throw "Skill source path changed; verify migration before installing: $name"
    }

    if (Test-Path -LiteralPath $target) {
        if ($managed.Count -eq 0) { throw "Destination is unmanaged and must not be overwritten: $target" }
        $oldMap = Get-ManifestEntryMap $managed[0]
        $actualMap = Get-FileHashes $target
        Assert-SameManagedFiles $oldMap $actualMap $name -RejectExtra
        Assert-SameManagedFiles $sourceMap $oldMap $name -RejectExtra
        Write-Output "SKIP $name (already installed)"
        continue
    }
    if ($managed.Count -gt 0) { throw "Previously installed skill directory missing: $target" }
    $planned += [pscustomobject]@{ Skill = $skill; Target = $target; Hashes = $sourceMap }
}

if ($planned.Count -eq 0) { Write-Output "No changes"; return }
foreach ($plan in $planned) { Write-Output "INSTALL $($plan.Skill.Name) version $(Get-SkillVersion $plan.Hashes) -> $($plan.Target)" }
if ($DryRun) { Write-Output "DRY RUN: no filesystem changes"; return }

if ($Scope -eq 'user') {
    $effectiveHome = if ($HomePath) { [System.IO.Path]::GetFullPath($HomePath) } else { [System.IO.Path]::GetFullPath($HOME) }
    if ($effectiveHome.TrimEnd([char[]]@('\','/')).Equals(
        [System.IO.Path]::GetFullPath($HOME).TrimEnd([char[]]@('\','/')),
        [System.StringComparison]::OrdinalIgnoreCase) -and -not $BackupPath) {
        throw 'Real user HOME install requires explicit -BackupPath outside HOME; dry-run first'
    }
}
if ($BackupPath) {
    New-InstallExternalBackup -BackupPath $BackupPath -Destination $destination -ManifestPath $manifestPath -Manifest $manifest
}
if (-not (Test-Path -LiteralPath $destination)) {
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
}
Invoke-TransactionalInstall -Destination $destination -ManifestPath $manifestPath -Manifest $manifest -Plans $planned -TestFailurePoint $TestFailurePoint
Write-Output "Installed $($planned.Count) skill(s); manifest: $manifestPath"


[CmdletBinding()]
param(
    [ValidateSet('user','project')][string]$Scope = 'user',
    [string]$ProjectPath = '.',
    [string[]]$Skills = @(),
    [ValidateSet('ceos-migrated')][string]$Set = '',
    [string]$Profile = '',
    [switch]$DryRun,
    [switch]$Recover,
    [ValidateSet('None','AfterFirstSwap','BeforeManifest','AfterManifest','InterruptAfterFirstSwap','InterruptAfterBackup')]
    [string]$TestFailurePoint = 'None',
    [string]$HomePath = '',
    [string]$RepositoryRoot = (Join-Path $PSScriptRoot '..')
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'SkillUtils.ps1')
. (Join-Path $PSScriptRoot 'SyncTransaction.ps1')

$destination = Get-SkillsDestination $Scope $ProjectPath $HomePath
$manifestPath = Join-Path $destination '.workflow-for-agents.manifest.json'
if (Test-Path -LiteralPath $destination) { Assert-NotLinked $destination }
if ($Recover) {
    if ($DryRun -or $Skills.Count -gt 0 -or $Set -or $Profile -or $TestFailurePoint -ne 'None') {
        throw 'Use -Recover without selection, DryRun or test failure injection'
    }
    Restore-SyncTransaction -Destination $destination -ManifestPath $manifestPath
    return
}
Assert-NoPendingSyncTransaction $destination
if ($TestFailurePoint -ne 'None') {
    if ($Scope -ne 'user' -or -not $HomePath) {
        throw 'TestFailurePoint is allowed only with explicit -Scope user -HomePath disposable fixture'
    }
    $testHome = [System.IO.Path]::GetFullPath($HomePath).TrimEnd([char[]]@('\','/'))
    $realHome = [System.IO.Path]::GetFullPath($HOME).TrimEnd([char[]]@('\','/'))
    $tempPrefix = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd([char[]]@('\','/')) + [System.IO.Path]::DirectorySeparatorChar
    if ($testHome.Equals($realHome, [System.StringComparison]::OrdinalIgnoreCase) -or
        -not $testHome.StartsWith($tempPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'TestFailurePoint requires a disposable HOME beneath system TEMP, never the real HOME'
    }
    $marker = Join-Path $testHome '.wfa-sync-transaction-test-home'
    if (-not (Test-Path -LiteralPath $marker -PathType Leaf)) {
        throw "TestFailurePoint requires explicit disposable test marker: $marker"
    }
    Assert-NotLinked $testHome
    Assert-NotLinked $marker
}
$repo = Get-RepoRoot $RepositoryRoot
$legacy = Get-LegacyCeosOwnership $HomePath
if ($Set) { Assert-NoLegacyCeosCollision $legacy (Get-SkillSetNames $Set) }
$manifest = Read-Manifest $manifestPath -Require
$available = Get-AvailableSkills $repo
$installed = @($manifest.installed)
if ($Profile) {
    if ($Scope -ne 'project') { throw 'Project profiles can only be synchronized with -Scope project' }
    if ($Skills.Count -gt 0 -or $Set) { throw 'Use -Profile alone; do not combine it with -Skills or -Set' }
    $preflight = Invoke-ProjectProfilePreflight -RepoRoot $repo -ProjectPath $ProjectPath -Profile $Profile
    Assert-ProjectProfilePreflight $preflight
    $selected = @($preflight.Skills | Select-Object -Unique)
} else {
    if ($Set) { $selected = @(Get-SkillSetNames $Set) }
    elseif ($Skills.Count -gt 0) { $selected = @($Skills | Select-Object -Unique) }
    else { $selected = @($installed | ForEach-Object { $_.name }) }
}
if (-not $Set) { Assert-NoLegacyCeosCollision $legacy $selected }
$plans = @()

foreach ($name in $selected) {
    $entry = @($installed | Where-Object { $_.name -eq $name })
    if ($entry.Count -ne 1) { throw "Skill is not installed: $name" }
    if (-not $available.ContainsKey($name)) { throw "Source skill missing: $name" }
    $skill = $available[$name]
    if ($entry[0].sourceRelative -ne $skill.SourceRelative) {
        throw "Skill source path changed; verify migration before syncing: $name"
    }
    $target = Join-Path $destination $name
    if (-not (Test-Path -LiteralPath $target -PathType Container)) {
        throw "Installed directory missing: $target"
    }

    $oldMap = Get-ManifestEntryMap $entry[0]
    $newMap = Get-FileHashes $skill.Directory
    $actualMap = Get-FileHashes $target

    Assert-SameManagedFiles $oldMap $actualMap $name
    foreach ($key in $newMap.Keys) {
        if (-not $oldMap.ContainsKey($key) -and $actualMap.ContainsKey($key)) {
            throw "New source conflicts with unmanaged local file: $name/$key"
        }
    }

    $actions = @()
    foreach ($key in $oldMap.Keys) {
        if (-not $newMap.ContainsKey($key)) {
            $actions += [pscustomobject]@{ Operation = 'REMOVE'; Path = $key }
        } elseif ($newMap[$key] -ne $oldMap[$key]) {
            $actions += [pscustomobject]@{ Operation = 'UPDATE'; Path = $key }
        }
    }
    foreach ($key in $newMap.Keys) {
        if (-not $oldMap.ContainsKey($key)) {
            $actions += [pscustomobject]@{ Operation = 'ADD'; Path = $key }
        }
    }
    $plans += [pscustomobject]@{
        Name = $name
        Skill = $skill
        Target = $target
        OldMap = $oldMap
        NewMap = $newMap
        Actions = @($actions | Sort-Object Path)
    }
}

$changes = 0
foreach ($plan in $plans) {
    foreach ($action in $plan.Actions) {
        $changes++
        Write-Output "$($action.Operation) $($plan.Name)/$($action.Path)"
    }
}
if ($changes -eq 0) { Write-Output "All installed skills are up to date"; return }
if ($DryRun) { Write-Output "DRY RUN: no filesystem changes"; return }

foreach ($plan in $plans) {
    # Recheck after planning to guard against a concurrent edit before writing.
    $actual = Get-FileHashes $plan.Target
    Assert-SameManagedFiles $plan.OldMap $actual $plan.Name
    foreach ($key in $plan.NewMap.Keys) {
        if (-not $plan.OldMap.ContainsKey($key) -and $actual.ContainsKey($key)) {
            throw "New collision detected: $($plan.Name)/$key"
        }
    }
}

Invoke-TransactionalSync -Destination $destination -ManifestPath $manifestPath -Manifest $manifest -Plans $plans -TestFailurePoint $TestFailurePoint
foreach ($plan in $plans) { Write-Output "VERSION $($plan.Name): $(Get-SkillVersion $plan.NewMap)" }
Write-Output "Synchronized $changes file change(s); manifest: $manifestPath"

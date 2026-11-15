[CmdletBinding()]
param(
    [ValidateSet('user','project')][string]$Scope = 'user',
    [string]$ProjectPath = '.',
    [string[]]$Skills = @(),
    [switch]$All,
    [switch]$DryRun,
    [string]$RepositoryRoot = (Join-Path $PSScriptRoot '..')
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'SkillUtils.ps1')

$repo = Get-RepoRoot $RepositoryRoot
$destination = Get-SkillsDestination $Scope $ProjectPath
$manifestPath = Join-Path $destination '.workflow-for-agents.manifest.json'
$available = Get-AvailableSkills $repo
$selected = @(Get-SelectedNames $available $Skills -All:$All)
$manifest = Read-Manifest $manifestPath
$planned = @()

foreach ($name in $selected) {
    $skill = $available[$name]
    $sourceMap = Get-FileHashes $skill.Directory
    $target = Join-Path $destination $name
    $managed = @($manifest.installed | Where-Object { $_.name -eq $name })
    if ($managed.Count -gt 1) { throw "Duplicate installed skill: $name" }

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
foreach ($plan in $planned) { Write-Output "INSTALL $($plan.Skill.Name) -> $($plan.Target)" }
if ($DryRun) { Write-Output "DRY RUN: no filesystem changes"; return }

if (-not (Test-Path -LiteralPath $destination)) {
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
}
foreach ($plan in $planned) {
    if (Test-Path -LiteralPath $plan.Target) { throw "Destination appeared during install: $($plan.Target)" }
    Copy-Item -LiteralPath $plan.Skill.Directory -Destination $plan.Target -Recurse -Force
    $actual = Get-FileHashes $plan.Target
    Assert-SameManagedFiles $plan.Hashes $actual $plan.Skill.Name -RejectExtra
    $entry = New-ManifestEntry $plan.Skill $plan.Hashes
    $manifest.installed = @($manifest.installed) + @($entry)
}
Write-Manifest $manifestPath $manifest
Write-Output "Installed $($planned.Count) skill(s); manifest: $manifestPath"


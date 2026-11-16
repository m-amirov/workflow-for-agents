[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Profile,
    [Parameter(Mandatory = $true)][string]$ProjectPath,
    [ValidateSet('skill-install', 'prototype', 'merge', 'release')][string]$Operation = 'skill-install',
    [switch]$DirectMainRequired,
    [string]$RepositoryRoot = (Join-Path $PSScriptRoot '..')
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'SkillUtils.ps1')

$repo = Get-RepoRoot $RepositoryRoot
$result = Invoke-ProjectProfilePreflight -RepoRoot $repo -ProjectPath $ProjectPath -Profile $Profile -Operation $Operation -DirectMainRequired:$DirectMainRequired
foreach ($finding in @($result.Findings)) {
    Write-Output "PREFLIGHT $($finding.Class) $($finding.Code): $($finding.Message)"
}
if ($result.Decision -ne 'PASS') {
    throw "Profile preflight BLOCKED for '$Profile'; no files were changed"
}

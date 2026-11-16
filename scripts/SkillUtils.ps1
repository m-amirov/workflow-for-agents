Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-RepoRoot {
    param([string]$Root)
    if (-not (Test-Path -LiteralPath (Join-Path $Root 'skills') -PathType Container)) {
        throw "Source skills directory not found in: $Root"
    }
    return [System.IO.Path]::GetFullPath($Root)
}

function Get-SkillsDestination {
    param([string]$Scope, [string]$ProjectPath, [string]$HomePath = '')
    if ($Scope -eq 'user') {
        $resolvedHome = if ($HomePath) { [System.IO.Path]::GetFullPath($HomePath) } else { [System.IO.Path]::GetFullPath($HOME) }
        if (-not (Test-Path -LiteralPath $resolvedHome -PathType Container)) {
            throw "User home directory not found: $resolvedHome"
        }
        return (Join-Path (Join-Path $resolvedHome '.agents') 'skills')
    }
    $project = [System.IO.Path]::GetFullPath($ProjectPath)
    if (-not (Test-Path -LiteralPath $project -PathType Container)) {
        throw "Project directory not found: $project"
    }
    return (Join-Path (Join-Path $project '.agents') 'skills')
}

function Get-SkillSetNames {
    param([string]$Set)
    switch ($Set) {
        'ceos-migrated' {
            return @(
                'audit', 'audit-repair-loop', 'ceos-continue', 'fix', 'verification',
                'release', 'visual-qa', 'video-production', 'romance-narrative',
                'narrative-dialogue-editor', 'narrative-continuity-engine',
                'reader-experience-review', 'production-art', 'prod-check', 'incident-analysis'
            )
        }
        default { throw "Unknown Skill set: $Set. Available sets: ceos-migrated" }
    }
}

function Get-RelativeFilePath {
    param([string]$File, [string]$Root)
    $prefix = [System.IO.Path]::GetFullPath($Root).TrimEnd([char[]]@('\','/')) +
        [System.IO.Path]::DirectorySeparatorChar
    $absolute = [System.IO.Path]::GetFullPath($File)
    if (-not $absolute.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "File outside expected directory: $File"
    }
    return $absolute.Substring($prefix.Length).Replace('\', '/')
}

function Assert-NotLinked {
    param([string]$Path)
    $item = Get-Item -LiteralPath $Path -Force
    if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Refusing symbolic link or junction: $Path"
    }
}

function Get-FileHashes {
    param([string]$Directory)
    $map = @{}
    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) { return $map }
    Assert-NotLinked $Directory
    foreach ($item in @(Get-ChildItem -LiteralPath $Directory -Recurse -Force)) {
        Assert-NotLinked $item.FullName
        if (-not $item.PSIsContainer) {
            $relative = Get-RelativeFilePath $item.FullName $Directory
            $map[$relative] = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        }
    }
    return $map
}

function Get-AvailableSkills {
    param([string]$RepoRoot)
    $found = @{}
    $skillRoot = Join-Path $RepoRoot 'skills'
    foreach ($file in @(Get-ChildItem -LiteralPath $skillRoot -Filter SKILL.md -Recurse -File)) {
        $folder = $file.Directory.FullName
        $name = Split-Path -Leaf $folder
        if ($found.ContainsKey($name)) { throw "Duplicate skill name: $name" }
        $found[$name] = [pscustomobject]@{
            Name = $name
            Directory = $folder
            SourceRelative = (Get-RelativeFilePath $folder $RepoRoot)
        }
    }
    return $found
}

function Get-SelectedNames {
    param([hashtable]$Available, [string[]]$Names, [switch]$All, [string]$Set = '')
    if ($Set -and ($All -or $Names.Count -gt 0)) { throw "Use -Set alone; do not combine it with -Skills or -All" }
    if ($Set) { $Names = @(Get-SkillSetNames $Set) }
    if ($All -and $Names.Count -gt 0) { throw "Use either -All or -Skills, not both" }
    if (-not $All -and $Names.Count -eq 0) {
        throw "Select skills with -Skills skill-a,skill-b, -Set ceos-migrated or -All"
    }
    if ($All) { return @($Available.Keys | Sort-Object) }
    $unique = @($Names | Select-Object -Unique)
    foreach ($name in $unique) {
        if (-not $Available.ContainsKey($name)) { throw "Unknown skill: $name" }
    }
    return $unique
}

function Get-LegacyCeosOwnership {
    param([string]$HomePath)
    $resolvedHome = if ($HomePath) { [System.IO.Path]::GetFullPath($HomePath) } else { [System.IO.Path]::GetFullPath($HOME) }
    $manifestPath = Join-Path (Join-Path $resolvedHome '.codex') 'ceos\installation.json'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        return [pscustomobject]@{ Present = $false; ManifestPath = $manifestPath; SkillNames = @(); Error = $null }
    }
    Assert-NotLinked $manifestPath
    try {
        $document = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $names = @()
        if ($document.PSObject.Properties.Name -contains 'skills') {
            $names += @($document.skills.PSObject.Properties | ForEach-Object { $_.Name })
        }
        if ($document.PSObject.Properties.Name -contains 'installed') {
            $names += @($document.installed | ForEach-Object { [string]$_.name })
        }
        return [pscustomobject]@{
            Present = $true
            ManifestPath = $manifestPath
            SkillNames = @($names | Where-Object { $_ } | Select-Object -Unique)
            Error = $null
        }
    }
    catch {
        return [pscustomobject]@{ Present = $true; ManifestPath = $manifestPath; SkillNames = @(); Error = $_.Exception.Message }
    }
}

function Assert-NoLegacyCeosCollision {
    param([object]$Ownership, [string[]]$Selected)
    if (-not $Ownership.Present) { return }
    if ($Ownership.Error) {
        throw "Legacy CEOS ownership manifest cannot be read: $($Ownership.ManifestPath). Preserve it and resolve it explicitly before installing or syncing. Error: $($Ownership.Error)"
    }
    $conflicts = @($Selected | Where-Object { $Ownership.SkillNames -contains $_ } | Select-Object -Unique)
    if ($conflicts.Count -eq 0) {
        Write-Output "NOTICE legacy CEOS ownership manifest detected: $($Ownership.ManifestPath); selected Skills have no named collision"
        return
    }
    $lines = @(
        "Legacy CEOS-managed Skill collision: $($conflicts -join ', ')"
        "Manifest: $($Ownership.ManifestPath)"
        "Migration plan: preserve the CEOS manifest and Skill files; review the listed files and hashes; obtain explicit approval for a backup-backed ownership migration; only then remove the old owner and rerun this install/sync."
        "No files were changed."
    )
    throw ($lines -join [Environment]::NewLine)
}

function Get-ProjectProfile {
    param([string]$RepoRoot, [string]$Profile)
    if ($Profile -notmatch '^[a-z0-9-]+$') { throw "Invalid project profile name: $Profile" }
    $path = Join-Path $RepoRoot (Join-Path 'projects' (Join-Path $Profile 'profile.json'))
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Project profile not found: $Profile" }
    Assert-NotLinked $path
    try { $document = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch { throw "Invalid project profile JSON: $Profile" }
    if ($null -eq $document -or $document.schema -ne 1 -or $document.id -ne $Profile -or
        -not $document.canonical_repository -or -not $document.source_sha -or
        $null -eq $document.recommended_skills -or $null -eq $document.protected_local_skills -or
        -not $document.git_workflow -or $null -eq $document.stop_lines -or
        -not $document.release_authorization) { throw "Invalid or incompatible project profile: $Profile" }
    if ([string]$document.source_sha -notmatch '^[a-f0-9]{40}$') {
        throw "Project profile has invalid source_sha: $Profile"
    }
    $selected = @($document.recommended_skills | ForEach-Object { [string]$_ })
    if ($selected.Count -eq 0 -or @($selected | Where-Object { -not $_ }).Count -gt 0) {
        throw "Project profile has no valid recommended skills: $Profile"
    }
    $catalogPath = Join-Path $RepoRoot 'docs\SKILL_CATALOG.md'
    if (-not (Test-Path -LiteralPath $catalogPath -PathType Leaf)) {
        throw "Skill catalog is required for project profile installation: $catalogPath"
    }
    $catalogStates = @{}
    foreach ($line in @(Get-Content -LiteralPath $catalogPath -Encoding UTF8)) {
        $columns = @($line.Split('|'))
        if ($columns.Count -ge 5) {
            $name = $columns[2].Trim()
            $state = $columns[4].Trim()
            if ($name -match '^[a-z0-9-]+$' -and $state) { $catalogStates[$name] = $state }
        }
    }
    foreach ($name in $selected) {
        if (-not $catalogStates.ContainsKey($name)) { throw "Profile Skill is absent from catalog: $name" }
        if ($catalogStates[$name] -ne 'implemented') { throw "Profile Skill is not implemented: $name" }
    }
    return [pscustomobject]@{ Document = $document; Skills = $selected }
}

function Normalize-GitRepository {
    param([string]$Repository)
    $value = ([string]$Repository).Trim()
    if (-not $value) { throw 'Git repository URL is empty' }
    if ($value -match '^git@([^:]+):(.+)$') {
        $value = "https://$($Matches[1])/$($Matches[2])"
    }
    $value = $value.Replace('\\', '/')
    if ($value.EndsWith('.git', [System.StringComparison]::OrdinalIgnoreCase)) {
        $value = $value.Substring(0, $value.Length - 4)
    }
    return $value.TrimEnd('/').ToLowerInvariant()
}

function Invoke-GitText {
    param([string]$ProjectPath, [string[]]$Arguments)
    $output = @(& git -C $ProjectPath @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw (($output | ForEach-Object { [string]$_ }) -join [Environment]::NewLine)
    }
    return (($output | ForEach-Object { [string]$_ }) -join [Environment]::NewLine).Trim()
}

function New-PreflightFinding {
    param([string]$Class, [string]$Code, [string]$Message)
    return [pscustomobject]@{ Class = $Class; Code = $Code; Message = $Message }
}

function Get-ProfileRemoteFreshness {
    param([string]$ProjectPath, [object]$Profile, [switch]$HistoricalPinned)
    try {
        $head = Invoke-GitText $ProjectPath @('rev-parse', 'HEAD')
        $remoteMain = Invoke-GitText $ProjectPath @('ls-remote', 'origin', 'refs/heads/main')
    }
    catch {
        return [pscustomobject]@{ Status = 'REMOTE_UNVERIFIED'; Head = $null; RemoteMain = $null; Message = "Cannot verify origin/main read-only: $($_.Exception.Message)" }
    }
    if (-not $remoteMain) {
        return [pscustomobject]@{ Status = 'REMOTE_UNVERIFIED'; Head = $head; RemoteMain = $null; Message = 'origin has no refs/heads/main' }
    }
    $remoteSha = ($remoteMain -split '\s+')[0]
    $profileSha = [string]$Profile.source_sha
    if ($remoteSha -ne $profileSha) {
        $kind = if ($HistoricalPinned) { 'historical pinned evidence' } else { 'rollout profile' }
        return [pscustomobject]@{ Status = 'PROFILE_STALE'; Head = $head; RemoteMain = $remoteSha; Message = "$kind source_sha $profileSha is not current origin/main $remoteSha" }
    }
    if ($head -ne $remoteSha) {
        return [pscustomobject]@{ Status = 'LOCAL_STALE'; Head = $head; RemoteMain = $remoteSha; Message = "Target HEAD $head is behind or differs from origin/main $remoteSha" }
    }
    return [pscustomobject]@{ Status = 'CURRENT'; Head = $head; RemoteMain = $remoteSha; Message = "Target HEAD, profile source_sha and origin/main are $remoteSha" }
}

function Invoke-ProjectProfilePreflight {
    [OutputType([pscustomobject])]
    param(
        [string]$RepoRoot,
        [string]$ProjectPath,
        [string]$Profile,
        [ValidateSet('skill-install', 'prototype', 'merge', 'release')][string]$Operation = 'skill-install',
        [switch]$DirectMainRequired
    )

    $profileData = Get-ProjectProfile $RepoRoot $Profile
    $document = $profileData.Document
    $project = [System.IO.Path]::GetFullPath($ProjectPath)
    $findings = @()
    $blocked = $false

    if (-not (Test-Path -LiteralPath $project -PathType Container)) {
        $findings += New-PreflightFinding 'BLOCKED' 'project-root' "Target project directory does not exist: $project"
        return [pscustomobject]@{ Profile = $Profile; Operation = $Operation; Decision = 'BLOCKED'; Skills = $profileData.Skills; Findings = $findings }
    }

    try {
        $inside = Invoke-GitText $project @('rev-parse', '--is-inside-work-tree')
        if ($inside -ne 'true') { throw 'not a work tree' }
        $remote = Invoke-GitText $project @('remote', 'get-url', 'origin')
        $head = Invoke-GitText $project @('rev-parse', 'HEAD')
    }
    catch {
        $findings += New-PreflightFinding 'BLOCKED' 'git-identity' "Target is not a usable Git checkout with origin and HEAD: $($_.Exception.Message)"
        return [pscustomobject]@{ Profile = $Profile; Operation = $Operation; Decision = 'BLOCKED'; Skills = $profileData.Skills; Findings = $findings }
    }

    if ((Normalize-GitRepository $remote) -ne (Normalize-GitRepository ([string]$document.canonical_repository))) {
        $blocked = $true
        $findings += New-PreflightFinding 'BLOCKED' 'canonical-repository' "origin '$remote' does not match profile canonical repository '$($document.canonical_repository)'"
    }
    if ($head -ne [string]$document.source_sha) {
        $blocked = $true
        $findings += New-PreflightFinding 'STALE_EVIDENCE' 'source-sha' "HEAD $head differs from profile source_sha $($document.source_sha); refresh the profile before rollout"
    }
    $freshness = Get-ProfileRemoteFreshness -ProjectPath $project -Profile $document
    if ($freshness.Status -ne 'CURRENT') {
        $blocked = $true
        $findings += New-PreflightFinding $freshness.Status 'remote-freshness' $freshness.Message
    }

    $destination = Get-SkillsDestination 'project' $project
    $manifestPath = Join-Path $destination '.workflow-for-agents.manifest.json'
    $manifest = $null
    try {
        if (Test-Path -LiteralPath $destination) { Assert-NotLinked $destination }
        $manifest = Read-Manifest $manifestPath
    }
    catch {
        $blocked = $true
        $findings += New-PreflightFinding 'BLOCKED' 'manifest-integrity' "Existing manifest is invalid: $($_.Exception.Message)"
    }

    if ($null -ne $manifest) {
        foreach ($name in $profileData.Skills) {
            $target = Join-Path $destination $name
            $managed = @($manifest.installed | Where-Object { $_.name -eq $name })
            if ((Test-Path -LiteralPath $target) -and $managed.Count -eq 0) {
                $blocked = $true
                $findings += New-PreflightFinding 'BLOCKED' 'local-skill-collision' "Unmanaged local Skill would be overwritten: $name"
            }
        }
    }

    foreach ($name in @($document.protected_local_skills | ForEach-Object { [string]$_ })) {
        $protectedPath = Join-Path $destination $name
        if (-not (Test-Path -LiteralPath $protectedPath -PathType Container)) {
            $blocked = $true
            $findings += New-PreflightFinding 'BLOCKED' 'protected-local-skill' "Expected protected local Skill is missing: $name"
        }
    }

    if ([string]$document.git_workflow -eq 'pr-only') {
        if ($DirectMainRequired) {
            $blocked = $true
            $findings += New-PreflightFinding 'HARD_CONFLICT' 'git-workflow' 'Explicit direct-main operation conflicts with this project PR-only workflow'
        }
        else {
            $findings += New-PreflightFinding 'PROJECT_REFINEMENT' 'git-workflow' 'Project PR-only workflow refines central main-first guidance'
        }
    }

    if ($Operation -ne 'skill-install') {
        $blocked = $true
        $findings += New-PreflightFinding 'BLOCKED' 'operation-authorization' "Profile installation never authorizes '$Operation'; obtain and record the project-specific authorization separately"
    }
    elseif (@($document.stop_lines).Count -gt 0) {
        $findings += New-PreflightFinding 'PROJECT_REFINEMENT' 'stop-lines' 'Skills installation does not lift project stop-lines or release authorization requirements'
    }

    if (-not $blocked) {
        $findings += New-PreflightFinding 'PASS' 'profile-preflight' "Profile '$Profile' is safe for skill-install at verified source SHA $head"
    }
    return [pscustomobject]@{
        Profile = $Profile
        Operation = $Operation
        Decision = if ($blocked) { 'BLOCKED' } else { 'PASS' }
        Skills = $profileData.Skills
        Findings = $findings
    }
}

function Assert-ProjectProfilePreflight {
    param([object]$Preflight)
    foreach ($finding in @($Preflight.Findings)) {
        Write-Output "PREFLIGHT $($finding.Class) $($finding.Code): $($finding.Message)"
    }
    if ($Preflight.Decision -ne 'PASS') {
        throw "Profile preflight BLOCKED for '$($Preflight.Profile)'; no files were changed"
    }
}

function New-Manifest {
    return [pscustomobject]@{
        schema = 1
        source = 'workflow-for-agents'
        installed = @()
    }
}

function Read-Manifest {
    param([string]$Path, [switch]$Require)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        if ($Require) { throw "Manifest missing: $Path; run install.ps1 first" }
        return (New-Manifest)
    }
    Assert-NotLinked $Path
    $doc = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($null -eq $doc -or $doc.schema -ne 1 -or $doc.source -ne 'workflow-for-agents' -or
        $null -eq $doc.installed) { throw "Invalid or incompatible manifest: $Path" }
    $names = @{}
    foreach ($entry in @($doc.installed)) {
        if (-not $entry.name -or $names.ContainsKey([string]$entry.name)) {
            throw "Invalid or duplicate manifest skill entry"
        }
        if ([string]$entry.sourceRelative -notmatch '^[^/\\]+(?:/[^/\\]+)*$') {
            throw "Invalid manifest source path: $($entry.sourceRelative)"
        }
        $fileEntries = @($entry.files)
        if ($fileEntries.Count -eq 0) {
            throw "Manifest skill has no managed files: $($entry.name)"
        }
        $fileMap = Get-ManifestEntryMap $entry
        $expectedVersion = Get-SkillVersion $fileMap
        if ([string]$entry.sourceVersion -ne $expectedVersion) {
            throw "Manifest source version does not match file hashes: $($entry.name)"
        }
        $names[[string]$entry.name] = $true
    }
    return $doc
}


function Get-SkillVersion {
    param([hashtable]$Map)
    $lines = @(
        foreach ($key in @($Map.Keys | Sort-Object)) {
            "$key=$($Map[$key])"
        }
    )
    $data = [System.Text.Encoding]::UTF8.GetBytes(($lines -join "`n"))
    $hash = [System.Security.Cryptography.SHA256]::Create()
    try {
        return [System.BitConverter]::ToString($hash.ComputeHash($data)).Replace('-', '').ToLowerInvariant()
    }
    finally { $hash.Dispose() }
}

function New-ManifestEntry {
    param([object]$Skill, [hashtable]$Map)
    $files = @(
        foreach ($key in @($Map.Keys | Sort-Object)) {
            [pscustomobject]@{ path = [string]$key; sha256 = [string]$Map[$key] }
        }
    )
    return [pscustomobject]@{
        name = $Skill.Name
        sourceRelative = $Skill.SourceRelative
        sourceVersion = (Get-SkillVersion $Map)
        files = $files
    }
}

function Get-ManifestEntryMap {
    param([object]$Entry)
    $map = @{}
    foreach ($file in @($Entry.files)) {
        $key = [string]$file.path
        if ($key -notmatch '^[^/\\]+(?:/[^/\\]+)*$' -or $key -match '(^|/)\.\.?(?:/|$)' -or
            $map.ContainsKey($key) -or [string]$file.sha256 -notmatch '^[a-fA-F0-9]{64}$') {
            throw "Unsafe or invalid manifest file: $key"
        }
        $map[$key] = ([string]$file.sha256).ToLowerInvariant()
    }
    return $map
}

function Assert-SameManagedFiles {
    param([hashtable]$Expected, [hashtable]$Actual, [string]$SkillName, [switch]$RejectExtra)
    foreach ($key in $Expected.Keys) {
        if (-not $Actual.ContainsKey($key) -or $Actual[$key] -ne $Expected[$key]) {
            throw "Local modification or deletion: $SkillName/$key"
        }
    }
    if ($RejectExtra) {
        foreach ($key in $Actual.Keys) {
            if (-not $Expected.ContainsKey($key)) { throw "Unmanaged extra file: $SkillName/$key" }
        }
    }
}

function Write-Manifest {
    param([string]$Path, [object]$Manifest)
    $folder = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }
    $temporary = "$Path.tmp-$PID-$([guid]::NewGuid().ToString('N'))"
    try {
        $json = $Manifest | ConvertTo-Json -Depth 20
        [System.IO.File]::WriteAllText($temporary, $json + [Environment]::NewLine,
            (New-Object System.Text.UTF8Encoding($false)))
        Move-Item -LiteralPath $temporary -Destination $Path -Force
    }
    finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
    }
}


function Get-SyncTransactionPath {
    param([string]$Destination)
    return (Join-Path $Destination '.workflow-for-agents.sync-transaction')
}

function Assert-NoPendingSyncTransaction {
    param([string]$Destination)
    $transaction = Get-SyncTransactionPath $Destination
    if (Test-Path -LiteralPath $transaction) {
        throw "Pending sync transaction: $transaction. Stop all writes and use sync.ps1 -Recover after inspection."
    }
}

function Test-PreflightPathWithinRoot {
    param([string]$Path, [string]$Root)
    $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd([char[]]@('\','/'))
    $pathFull = [System.IO.Path]::GetFullPath($Path).TrimEnd([char[]]@('\','/'))
    return $pathFull.Equals($rootFull, [System.StringComparison]::OrdinalIgnoreCase) -or
        $pathFull.StartsWith($rootFull + [System.IO.Path]::DirectorySeparatorChar,
            [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-PreflightTreeSnapshot {
    [OutputType([pscustomobject])]
    param(
        [string]$Directory,
        [string[]]$HashFiles = @()
    )

    $result = [ordered]@{
        Exists = $false
        Safe = $true
        Error = $null
        AllFiles = @()
        Files = @{}
        MissingFiles = @()
        SkillMdPresent = $false
        SkillMdSha256 = $null
        Version = $null
    }
    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
        return [pscustomobject]$result
    }

    try {
        $root = Get-Item -LiteralPath $Directory -Force
        if (($root.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            $result.Safe = $false
            $result.Error = "Reparse point: $Directory"
            return [pscustomobject]$result
        }
        $result.Exists = $true
        $hashSet = @{}
        foreach ($relative in @($HashFiles)) {
            if (-not $relative) { continue }
            $hashSet[[string]$relative.Replace('\','/')] = $true
        }

        $queue = New-Object System.Collections.Queue
        $queue.Enqueue($root)
        $allFiles = New-Object System.Collections.Generic.List[string]
        $hashes = @{}
        while ($queue.Count -gt 0) {
            $current = $queue.Dequeue()
            foreach ($item in @(Get-ChildItem -LiteralPath $current.FullName -Force)) {
                if (-not (Test-PreflightPathWithinRoot $item.FullName $Directory)) {
                    throw "Path escaped expected Skill directory: $($item.FullName)"
                }
                if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                    throw "Reparse point inside Skill directory: $($item.FullName)"
                }
                if ($item.PSIsContainer) {
                    $queue.Enqueue($item)
                    continue
                }
                $relative = Get-RelativeFilePath $item.FullName $Directory
                $allFiles.Add($relative)
                if ($hashSet.ContainsKey($relative)) {
                    $hashes[$relative] = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
                }
            }
        }
        $result.AllFiles = @($allFiles | Sort-Object)
        $result.Files = $hashes
        $missing = @($hashSet.Keys | Where-Object { -not $hashes.ContainsKey($_) } | Sort-Object)
        $result.MissingFiles = $missing
        $result.SkillMdPresent = $result.AllFiles -contains 'SKILL.md'
        if ($hashes.ContainsKey('SKILL.md')) { $result.SkillMdSha256 = $hashes['SKILL.md'] }
        if ($hashSet.Count -gt 0 -and $missing.Count -eq 0) {
            $result.Version = Get-SkillVersion $hashes
        }
    }
    catch {
        $result.Safe = $false
        $result.Error = $_.Exception.Message
    }
    return [pscustomobject]$result
}

function Get-PreflightManifestInspection {
    [OutputType([pscustomobject])]
    param([string]$Path)

    $result = [ordered]@{
        Path = [System.IO.Path]::GetFullPath($Path)
        Present = $false
        State = 'ABSENT'
        Error = $null
        Entries = @()
        EntryByName = @{}
    }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return [pscustomobject]$result
    }
    $result.Present = $true
    try {
        Assert-NotLinked $Path
        $document = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($null -eq $document -or $document.schema -ne 1 -or
            $document.source -ne 'workflow-for-agents' -or $null -eq $document.installed) {
            throw 'Manifest schema/source/installed contract is invalid'
        }
        $names = @{}
        $entries = New-Object System.Collections.Generic.List[object]
        foreach ($entry in @($document.installed)) {
            $name = [string]$entry.name
            if ($name -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$' -or $names.ContainsKey($name)) {
                throw "Invalid or duplicate manifest skill entry: $name"
            }
            $sourceRelative = [string]$entry.sourceRelative
            if ($sourceRelative -notmatch '^[^/\\]+(?:/[^/\\]+)*$' -or
                $sourceRelative -match '(^|/)\.\.?(?:/|$)') {
                throw "Unsafe manifest source path: $sourceRelative"
            }
            $map = @{}
            foreach ($file in @($entry.files)) {
                $key = [string]$file.path
                $sha = [string]$file.sha256
                if ($key -notmatch '^[^/\\]+(?:/[^/\\]+)*$' -or
                    $key -match '(^|/)\.\.?(?:/|$)' -or $map.ContainsKey($key) -or
                    $sha -notmatch '^[a-fA-F0-9]{64}$') {
                    throw "Unsafe or invalid manifest file: $key"
                }
                $map[$key] = $sha.ToLowerInvariant()
            }
            if ($map.Count -eq 0) { throw "Manifest skill has no managed files: $name" }
            $expectedVersion = Get-SkillVersion $map
            if ([string]$entry.sourceVersion -ne $expectedVersion) {
                throw "Manifest source version does not match file hashes: $name"
            }
            $record = [pscustomobject]@{
                Name = $name
                SourceRelative = $sourceRelative
                SourceVersion = [string]$entry.sourceVersion
                Files = $map
            }
            $names[$name] = $true
            $entries.Add($record)
        }
        $result.Entries = @($entries | Sort-Object Name)
        foreach ($entry in $result.Entries) { $result.EntryByName[$entry.Name] = $entry }
        $result.State = 'VALID'
    }
    catch {
        $result.State = if ($_.Exception.Message -match 'Reparse point|Unsafe') { 'UNSAFE_PATH' } else { 'INVALID_MANIFEST' }
        $result.Error = $_.Exception.Message
    }
    return [pscustomobject]$result
}

function Get-PreflightLegacyManifestInspection {
    [OutputType([pscustomobject])]
    param([string]$HomePath)

    $path = Join-Path (Join-Path $HomePath '.codex') 'ceos\installation.json'
    $result = [ordered]@{
        Path = [System.IO.Path]::GetFullPath($path)
        Present = $false
        State = 'ABSENT'
        Error = $null
        Version = $null
        Skills = @()
        SkillByName = @{}
    }
    try {
        foreach ($parent in @((Join-Path $HomePath '.codex'), (Join-Path (Join-Path $HomePath '.codex') 'ceos'))) {
            if (Test-Path -LiteralPath $parent -PathType Container) {
                $parentItem = Get-Item -LiteralPath $parent -Force
                if (($parentItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                    throw "Reparse point in legacy CEOS path: $parent"
                }
            }
        }
    }
    catch {
        $result.State = 'UNSAFE_PATH'
        $result.Error = $_.Exception.Message
        return [pscustomobject]$result
    }
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return [pscustomobject]$result
    }
    $result.Present = $true
    try {
        Assert-NotLinked $path
        $document = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($null -eq $document) { throw 'Legacy CEOS manifest is empty' }
        if ($document.PSObject.Properties.Name -contains 'version') { $result.Version = [string]$document.version }
        $records = New-Object System.Collections.Generic.List[object]
        if ($document.PSObject.Properties.Name -contains 'skills') {
            foreach ($property in @($document.skills.PSObject.Properties)) {
                $sourceProperty = $property.Value.PSObject.Properties['source']
                $versionProperty = $property.Value.PSObject.Properties['version']
                $shaProperty = $property.Value.PSObject.Properties['sha256']
                $records.Add([pscustomobject]@{
                    Name = [string]$property.Name
                    Evidence = 'legacy-ceos-manifest.skills'
                    Source = if ($null -ne $sourceProperty) { [string]$sourceProperty.Value } else { $null }
                    Version = if ($null -ne $versionProperty) { [string]$versionProperty.Value } else { $null }
                    Sha256 = if ($null -ne $shaProperty) { [string]$shaProperty.Value } else { $null }
                })
            }
        }
        if ($document.PSObject.Properties.Name -contains 'installed') {
            foreach ($installed in @($document.installed)) {
                $name = [string]$installed.name
                if ($name) {
                    $sourceProperty = $installed.PSObject.Properties['source']
                    $versionProperty = $installed.PSObject.Properties['version']
                    $shaProperty = $installed.PSObject.Properties['sha256']
                    $records.Add([pscustomobject]@{
                        Name = $name
                        Evidence = 'legacy-ceos-manifest.installed'
                        Source = if ($null -ne $sourceProperty) { [string]$sourceProperty.Value } else { $null }
                        Version = if ($null -ne $versionProperty) { [string]$versionProperty.Value } else { $null }
                        Sha256 = if ($null -ne $shaProperty) { [string]$shaProperty.Value } else { $null }
                    })
                }
            }
        }
        $unique = @($records | Where-Object { $_.Name } | Sort-Object Name, Evidence | Group-Object Name | ForEach-Object { $_.Group[0] })
        $result.Skills = $unique
        foreach ($skill in $unique) { $result.SkillByName[$skill.Name] = $skill }
        $result.State = 'VALID'
    }
    catch {
        $result.State = if ($_.Exception.Message -match 'Reparse point') { 'UNSAFE_PATH' } else { 'INVALID_MANIFEST' }
        $result.Error = $_.Exception.Message
    }
    return [pscustomobject]$result
}

function Get-PreflightImplementedSkillNames {
    param([string]$RepoRoot)
    $catalog = Join-Path $RepoRoot 'docs\SKILL_CATALOG.md'
    if (-not (Test-Path -LiteralPath $catalog -PathType Leaf)) {
        throw "Skill catalog not found: $catalog"
    }
    $names = @()
    foreach ($line in @(Get-Content -LiteralPath $catalog -Encoding UTF8)) {
        if ($line -match '^\|\s*[^|]+\|\s*([a-z0-9-]+)\s*\|[^|]*\|\s*implemented\s*\|\s*$') {
            $names += $Matches[1]
        }
    }
    return @($names | Select-Object -Unique | Sort-Object)
}

function Get-PreflightSkillMetadata {
    param([string]$Path)
    $result = [ordered]@{
        Name = $null
        Description = ''
        Migration = $null
        SourceSha = $null
        Status = $null
        Overlaps = @()
    }
    $content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $frontmatter = ''
    if ($content -match '(?s)^---\r?\n(.*?)\r?\n---') { $frontmatter = $Matches[1] }
    if ($frontmatter) {
        if ($frontmatter -match '(?m)^name:\s*(?:>[-+]?\s*)?([^\r\n]+)') { $result.Name = $Matches[1].Trim() }
        if ($frontmatter -match '(?ms)^description:\s*(.*?)(?=^metadata:|^---|\z)') {
            $result.Description = (($Matches[1] -replace '[\r\n]+', ' ').Trim() -replace '^>[-+]?\s*', '').Trim()
        }
        foreach ($field in @('migration','source_sha','status','overlaps')) {
            $pattern = '(?m)^\s*' + [regex]::Escape($field) + ':\s*([^\r\n]+)'
            if ($frontmatter -match $pattern) {
                $value = $Matches[1].Trim().Trim([char]39).Trim([char]34)
                if ($field -eq 'overlaps') { $result.Overlaps = @($value -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }
                else { $result[[string]($field.Substring(0,1).ToUpperInvariant() + $field.Substring(1).Replace('_',''))] = $value }
            }
        }
    }
    return [pscustomobject]$result
}

function Get-InstallTransactionPath {
    param([string]$Destination)
    return (Join-Path $Destination '.workflow-for-agents.install-transaction')
}

function Assert-NoPendingInstallTransaction {
    param([string]$Destination)
    $transaction = Get-InstallTransactionPath $Destination
    if (Test-Path -LiteralPath $transaction) {
        throw "Pending install transaction: $transaction. Stop writes and use install.ps1 -Recover after inspection."
    }
}

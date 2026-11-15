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
    param([string]$Scope, [string]$ProjectPath)
    if ($Scope -eq 'user') {
        return (Join-Path (Join-Path $HOME '.agents') 'skills')
    }
    $project = [System.IO.Path]::GetFullPath($ProjectPath)
    if (-not (Test-Path -LiteralPath $project -PathType Container)) {
        throw "Project directory not found: $project"
    }
    return (Join-Path (Join-Path $project '.agents') 'skills')
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
    param([hashtable]$Available, [string[]]$Names, [switch]$All)
    if ($All -and $Names.Count -gt 0) { throw "Use either -All or -Skills, not both" }
    if (-not $All -and $Names.Count -eq 0) {
        throw "Select skills with -Skills skill-a,skill-b or -All"
    }
    if ($All) { return @($Available.Keys | Sort-Object) }
    $unique = @($Names | Select-Object -Unique)
    foreach ($name in $unique) {
        if (-not $Available.ContainsKey($name)) { throw "Unknown skill: $name" }
    }
    return $unique
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
    $doc = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($null -eq $doc -or $doc.schema -ne 1 -or $doc.source -ne 'workflow-for-agents' -or
        $null -eq $doc.installed) { throw "Invalid or incompatible manifest: $Path" }
    $names = @{}
    foreach ($entry in @($doc.installed)) {
        if (-not $entry.name -or $names.ContainsKey([string]$entry.name)) {
            throw "Invalid or duplicate manifest skill entry"
        }
        $names[[string]$entry.name] = $true
    }
    return $doc
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


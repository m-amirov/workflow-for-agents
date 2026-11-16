# Stage 9C: recoverable directory-level sync. Requires SkillUtils.ps1.

function Get-SyncFingerprint {
    param([string]$Directory)
    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) { throw "Missing Skill directory: $Directory" }
    return (Get-SkillVersion (Get-FileHashes $Directory))
}

function Get-SyncFileFingerprint {
    param([string]$File)
    if (-not (Test-Path -LiteralPath $File -PathType Leaf)) { throw "Missing file: $File" }
    Assert-NotLinked $File
    return (Get-FileHash -LiteralPath $File -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Read-SyncJournal {
    param([string]$Destination)
    $transaction = Get-SyncTransactionPath $Destination
    if (-not (Test-Path -LiteralPath $transaction -PathType Container)) { throw "No pending sync transaction" }
    Assert-NotLinked $transaction
    $path = Join-Path $transaction 'journal.json'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing sync journal: $transaction; preserve it for manual inspection"
    }
    Assert-NotLinked $path
    try { $j = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch { throw "Invalid sync journal; preserve transaction: $transaction" }
    if ($null -eq $j -or $j.schema -ne 1 -or
        $j.destination -ne [System.IO.Path]::GetFullPath($Destination) -or
        [string]$j.oldManifestHash -notmatch '^[a-f0-9]{64}$' -or
        [string]$j.newManifestHash -notmatch '^[a-f0-9]{64}$' -or
        $null -eq $j.entries -or @($j.entries).Count -eq 0) {
        throw "Unsafe sync journal; preserve transaction for manual inspection"
    }
    $seen = @{}
    foreach ($e in @($j.entries)) {
        $name = [string]$e.name
        if ($name -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$' -or $seen.ContainsKey($name) -or
            [string]$e.oldHash -notmatch '^[a-f0-9]{64}$' -or
            [string]$e.newHash -notmatch '^[a-f0-9]{64}$') {
            throw "Unsafe sync journal entry: $name"
        }
        $seen[$name] = $true
    }
    return $j
}

function Restore-SyncTransaction {
    param([string]$Destination,[string]$ManifestPath)
    $transaction = Get-SyncTransactionPath $Destination
    $j = Read-SyncJournal $Destination
    $oldManifest = Join-Path $transaction 'old.manifest.json'
    if ((Get-SyncFileFingerprint $oldManifest) -ne [string]$j.oldManifestHash) {
        throw 'Original manifest backup has changed; manual recovery required'
    }
    $currentManifest = if (Test-Path -LiteralPath $ManifestPath -PathType Leaf) {
        Get-SyncFileFingerprint $ManifestPath
    } else { '' }
    if ($currentManifest -and $currentManifest -ne [string]$j.oldManifestHash -and
        $currentManifest -ne [string]$j.newManifestHash) {
        throw 'Manifest was edited after interruption; recovery blocked'
    }

    # Validate all snapshots before overwriting any current path.
    foreach ($e in @($j.entries)) {
        $target = Join-Path $Destination ([string]$e.name)
        $backup = Join-Path (Join-Path $transaction 'backup') ([string]$e.name)
        $hasBackup = Test-Path -LiteralPath $backup -PathType Container
        $hasTarget = Test-Path -LiteralPath $target -PathType Container
        if ($hasBackup -and (Get-SyncFingerprint $backup) -ne [string]$e.oldHash) {
            throw "Backup changed: $($e.name); recovery blocked"
        }
        if ($hasTarget) {
            $hash = Get-SyncFingerprint $target
            if ($hasBackup -and $hash -ne [string]$e.oldHash -and $hash -ne [string]$e.newHash) {
                throw "Selected Skill changed after interruption: $($e.name); recovery blocked"
            }
            if (-not $hasBackup -and $hash -ne [string]$e.oldHash) {
                throw "Selected Skill lost its backup: $($e.name); recovery blocked"
            }
        }
        elseif (-not $hasBackup) { throw "Selected Skill and backup both missing: $($e.name)" }
    }

    foreach ($e in @($j.entries)) {
        $target = Join-Path $Destination ([string]$e.name)
        $backup = Join-Path (Join-Path $transaction 'backup') ([string]$e.name)
        if (Test-Path -LiteralPath $backup -PathType Container) {
            if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
            Move-Item -LiteralPath $backup -Destination $target
        }
    }
    if ((-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) -or
        (Get-SyncFileFingerprint $ManifestPath) -ne [string]$j.oldManifestHash) {
        $restoring = Join-Path $transaction 'restoring.manifest.json'
        Copy-Item -LiteralPath $oldManifest -Destination $restoring -Force
        Move-Item -LiteralPath $restoring -Destination $ManifestPath -Force
    }
    foreach ($e in @($j.entries)) {
        if ((Get-SyncFingerprint (Join-Path $Destination ([string]$e.name))) -ne [string]$e.oldHash) {
            throw "Rollback verification failed: $($e.name)"
        }
    }
    if ((Get-SyncFileFingerprint $ManifestPath) -ne [string]$j.oldManifestHash) {
        throw 'Rollback manifest verification failed'
    }
    $null = Read-Manifest $ManifestPath -Require
    Remove-Item -LiteralPath $transaction -Recurse -Force
    Write-Output 'RECOVERED: previous Skills and manifest restored'
}

function Invoke-TransactionalSync {
    param([string]$Destination,[string]$ManifestPath,[object]$Manifest,[array]$Plans,
        [ValidateSet('None','AfterFirstSwap','BeforeManifest','AfterManifest','InterruptAfterFirstSwap','InterruptAfterBackup')]
        [string]$TestFailurePoint = 'None')
    Assert-NoPendingSyncTransaction $Destination
    $transaction = Get-SyncTransactionPath $Destination
    New-Item -ItemType Directory -Path $transaction -ErrorAction Stop | Out-Null
    $stageRoot = Join-Path $transaction 'stage'
    $backupRoot = Join-Path $transaction 'backup'
    $nextManifest = Join-Path $transaction 'next.manifest.json'
    $oldManifest = Join-Path $transaction 'old.manifest.json'
    $entries = @()
    try {
        New-Item -ItemType Directory -Path $stageRoot,$backupRoot -Force | Out-Null
        Copy-Item -LiteralPath $ManifestPath -Destination $oldManifest
        $oldManifestHash = Get-SyncFileFingerprint $oldManifest
        if ((Get-SyncFileFingerprint $ManifestPath) -ne $oldManifestHash) {
            throw 'Manifest changed while staging'
        }
        foreach ($plan in $Plans) {
            $stage = Join-Path $stageRoot $plan.Name
            Copy-Item -LiteralPath $plan.Target -Destination $stage -Recurse
            $originalMap = Get-FileHashes $plan.Target
            Assert-SameManagedFiles $plan.OldMap $originalMap $plan.Name
            foreach ($a in @($plan.Actions)) {
                $relative = $a.Path.Replace('/',[System.IO.Path]::DirectorySeparatorChar)
                $stagedFile = Join-Path $stage $relative
                if ($a.Operation -eq 'REMOVE') { Remove-Item -LiteralPath $stagedFile -Force }
                else {
                    $sourceFile = Join-Path $plan.Skill.Directory $relative
                    $parent = Split-Path -Parent $stagedFile
                    if (-not (Test-Path -LiteralPath $parent)) {
                        New-Item -ItemType Directory -Path $parent -Force | Out-Null
                    }
                    Copy-Item -LiteralPath $sourceFile -Destination $stagedFile -Force
                }
            }
            $newStageMap = Get-FileHashes $stage
            Assert-SameManagedFiles $plan.NewMap $newStageMap $plan.Name
            foreach ($key in $originalMap.Keys) {
                if (-not $plan.OldMap.ContainsKey($key) -and
                    (-not $newStageMap.ContainsKey($key) -or $newStageMap[$key] -ne $originalMap[$key])) {
                    throw "Unmanaged file changed while staging: $($plan.Name)/$key"
                }
            }
            $entries += [pscustomobject]@{
                name = $plan.Name
                oldHash = (Get-SkillVersion $originalMap)
                newHash = (Get-SkillVersion $newStageMap)
            }
            foreach ($item in @($Manifest.installed)) {
                if ($item.name -eq $plan.Name) {
                    $replacement = New-ManifestEntry $plan.Skill $plan.NewMap
                    $item.files = @($replacement.files)
                    $item | Add-Member -NotePropertyName sourceVersion -NotePropertyValue $replacement.sourceVersion -Force
                }
            }
        }
        Write-Manifest $nextManifest $Manifest
        $newManifestHash = Get-SyncFileFingerprint $nextManifest
        foreach ($e in $entries) {
            if ((Get-SyncFingerprint (Join-Path $Destination ([string]$e.name))) -ne [string]$e.oldHash) {
                throw "Selected Skill changed during staging: $($e.name)"
            }
        }
        if ((Get-SyncFileFingerprint $ManifestPath) -ne $oldManifestHash) {
            throw 'Manifest changed during staging'
        }
        $journal = [pscustomobject]@{
            schema = 1
            destination = [System.IO.Path]::GetFullPath($Destination)
            oldManifestHash = $oldManifestHash
            newManifestHash = $newManifestHash
            entries = @($entries)
        }
        [System.IO.File]::WriteAllText((Join-Path $transaction 'journal.json'),
            ($journal | ConvertTo-Json -Depth 12) + [Environment]::NewLine,
            (New-Object System.Text.UTF8Encoding($false)))
    }
    catch {
        Remove-Item -LiteralPath $transaction -Recurse -Force -ErrorAction SilentlyContinue
        throw
    }

    try {
        $swapped = 0
        foreach ($e in $entries) {
            $name = [string]$e.name
            $target = Join-Path $Destination $name
            Move-Item -LiteralPath $target -Destination (Join-Path $backupRoot $name)
            if ($swapped -eq 0 -and $TestFailurePoint -eq 'InterruptAfterBackup') {
                throw 'TEST-INJECT: InterruptAfterBackup'
            }
            Move-Item -LiteralPath (Join-Path $stageRoot $name) -Destination $target
            $swapped++
            if ($swapped -eq 1 -and $TestFailurePoint -in @('AfterFirstSwap','InterruptAfterFirstSwap')) {
                throw "TEST-INJECT: $TestFailurePoint"
            }
        }
        if ($TestFailurePoint -eq 'BeforeManifest') { throw 'TEST-INJECT: BeforeManifest' }
        Move-Item -LiteralPath $nextManifest -Destination $ManifestPath -Force
        if ($TestFailurePoint -eq 'AfterManifest') { throw 'TEST-INJECT: AfterManifest' }
        foreach ($e in $entries) {
            if ((Get-SyncFingerprint (Join-Path $Destination ([string]$e.name))) -ne [string]$e.newHash) {
                throw "New Skill fingerprint mismatch: $($e.name)"
            }
        }
        if ((Get-SyncFileFingerprint $ManifestPath) -ne $newManifestHash) {
            throw 'New manifest fingerprint mismatch'
        }
        $null = Read-Manifest $ManifestPath -Require
    }
    catch {
        $problem = $_.Exception.Message
        if ($TestFailurePoint -in @('InterruptAfterFirstSwap','InterruptAfterBackup') -and
            $problem -eq "TEST-INJECT: $TestFailurePoint") {
            throw 'TEST-INJECT simulated interruption; pending journal preserved for sync.ps1 -Recover'
        }
        try { Restore-SyncTransaction -Destination $Destination -ManifestPath $ManifestPath | Out-Null }
        catch {
            throw "Sync failed ($problem); automatic rollback FAILED ($($_.Exception.Message)); preserve transaction for sync.ps1 -Recover"
        }
        throw "Sync failed ($problem); original Skills and manifest restored"
    }
    Remove-Item -LiteralPath $transaction -Recurse -Force
}

# Stage 11: recoverable add-only installation, using SkillUtils.ps1 and
# SyncTransaction.ps1 for SHA-256 helpers. Does not migrate ownership.

function Get-InstallManifestHash {
    param([string]$ManifestPath)
    if (Test-Path -LiteralPath $ManifestPath -PathType Leaf) {
        return (Get-SyncFileFingerprint $ManifestPath)
    }
    return ''
}

function Assert-InstallRecord {
    param([object]$Record,[string]$Destination,[string]$Kind)
    if ($null -eq $Record -or $Record.schema -ne 1 -or
        [string]$Record.destination -ne [System.IO.Path]::GetFullPath($Destination) -or
        $null -eq $Record.entries -or @($Record.entries).Count -eq 0) {
        throw "Invalid $Kind record; preserve transaction for manual inspection"
    }
    if ([string]$Record.oldManifestHash -notmatch '^(?:[a-f0-9]{64})?$' -or
        $Record.hadManifest -isnot [bool]) {
        throw "Invalid manifest metadata in $Kind record"
    }
    if ($Record.hadManifest -ne [bool]([string]$Record.oldManifestHash)) {
        throw "Inconsistent manifest metadata in $Kind record"
    }
    $seen = @{}
    foreach ($entry in @($Record.entries)) {
        $name = [string]$entry.name
        if ($name -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$' -or $seen.ContainsKey($name)) {
            throw "Unsafe or duplicate Skill name in $Kind record: $name"
        }
        $seen[$name] = $true
        if ($Kind -eq 'journal' -and [string]$entry.sha256 -notmatch '^[a-f0-9]{64}$') {
            throw "Invalid Skill fingerprint in install journal: $name"
        }
    }
}

function Assert-OriginalInstalledSkills {
    param([string]$OriginalManifest,[string]$Destination)
    if (-not (Test-Path -LiteralPath $OriginalManifest -PathType Leaf)) { return }
    $doc = Read-Manifest $OriginalManifest -Require
    foreach ($entry in @($doc.installed)) {
        $target = Join-Path $Destination ([string]$entry.name)
        $expected = Get-ManifestEntryMap $entry
        $actual = Get-FileHashes $target
        Assert-SameManagedFiles $expected $actual ([string]$entry.name) -RejectExtra
    }
}

function New-InstallExternalBackup {
    param([string]$BackupPath,[string]$Destination,[string]$ManifestPath,[object]$Manifest)
    $out = [System.IO.Path]::GetFullPath($BackupPath)
    if (Test-Path -LiteralPath $out) { throw "Backup destination already exists: $out" }
    $root = [System.IO.Path]::GetFullPath($Destination).TrimEnd([char[]]@('\','/'))
    $installHome = [System.IO.Path]::GetFullPath((Split-Path -Parent (Split-Path -Parent $root))).TrimEnd([char[]]@('\','/'))
    $home = [System.IO.Path]::GetFullPath($HOME).TrimEnd([char[]]@('\','/'))
    $compare = [System.StringComparison]::OrdinalIgnoreCase
    $separator = [System.IO.Path]::DirectorySeparatorChar
    if ($out.Equals($root,$compare) -or $out.StartsWith($root + $separator,$compare) -or
        $out.Equals($home,$compare) -or $out.StartsWith($home + $separator,$compare) -or
        $out.Equals($installHome,$compare) -or $out.StartsWith($installHome + $separator,$compare)) {
        throw 'External backup must be outside installed Skills and selected HOME'
    }
    $parent = Split-Path -Parent $out
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        throw "External backup parent directory does not exist: $parent"
    }
    Assert-NotLinked $parent
    New-Item -ItemType Directory -Path $out -ErrorAction Stop | Out-Null
    $managedBackup = Join-Path $out 'managed-skills'
    try {
        New-Item -ItemType Directory -Path $managedBackup | Out-Null
        $hadManifest = Test-Path -LiteralPath $ManifestPath -PathType Leaf
        $manifestSha = ''
        if ($hadManifest) {
            $saved = Join-Path $out 'original.manifest.json'
            Copy-Item -LiteralPath $ManifestPath -Destination $saved
            $manifestSha = Get-SyncFileFingerprint $ManifestPath
            if ((Get-SyncFileFingerprint $saved) -ne $manifestSha) { throw 'Backup manifest checksum mismatch' }
        }
        $savedEntries = @()
        foreach ($entry in @($Manifest.installed)) {
            $name = [string]$entry.name
            $expected = Get-ManifestEntryMap $entry
            $target = Join-Path $Destination $name
            $actual = Get-FileHashes $target
            Assert-SameManagedFiles $expected $actual $name -RejectExtra
            $saved = Join-Path $managedBackup $name
            Copy-Item -LiteralPath $target -Destination $saved -Recurse
            $copied = Get-FileHashes $saved
            Assert-SameManagedFiles $expected $copied $name -RejectExtra
            $savedEntries += [pscustomobject]@{ name = $name; sourceVersion = Get-SkillVersion $expected }
        }
        $record = [pscustomobject]@{
            schema = 1
            purpose = 'WFA user-scope install backup; existing managed Skills only'
            originalManifestPresent = $hadManifest
            originalManifestSha256 = $manifestSha
            existingManagedSkills = @($savedEntries)
        }
        [System.IO.File]::WriteAllText((Join-Path $out 'backup-record.json'),
            ($record | ConvertTo-Json -Depth 10) + [Environment]::NewLine,
            (New-Object System.Text.UTF8Encoding($false)))
        Write-Output "BACKUP_VERIFIED: $out ($($savedEntries.Count) existing managed Skills)"
    }
    catch {
        throw "Backup was not verified at $out; install ABORTED without modifying Skills: $($_.Exception.Message)"
    }
}

function Restore-InstallTransaction {
    param([string]$Destination,[string]$ManifestPath)
    $transaction = Get-InstallTransactionPath $Destination
    if (-not (Test-Path -LiteralPath $transaction -PathType Container)) {
        throw "No pending install transaction: $transaction"
    }
    Assert-NotLinked $transaction
    $journalPath = Join-Path $transaction 'journal.json'
    $preparePath = Join-Path $transaction 'prepare.json'
    $isJournal = Test-Path -LiteralPath $journalPath -PathType Leaf
    $recordPath = if ($isJournal) { $journalPath } else { $preparePath }
    if (-not (Test-Path -LiteralPath $recordPath -PathType Leaf)) {
        throw "Install transaction has no readable journal or prepare record: $transaction; manual recovery required"
    }
    Assert-NotLinked $recordPath
    try { $record = Get-Content -LiteralPath $recordPath -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch { throw "Invalid install transaction record: $transaction; manual recovery required" }
    $kind = if ($isJournal) { 'journal' } else { 'prepare' }
    Assert-InstallRecord $record $Destination $kind
    if ($isJournal -and [string]$record.newManifestHash -notmatch '^[a-f0-9]{64}$') {
        throw 'Install journal has no valid new manifest hash'
    }
    $currentManifest = Get-InstallManifestHash $ManifestPath
    if ($currentManifest -ne [string]$record.oldManifestHash -and
        (-not $isJournal -or $currentManifest -ne [string]$record.newManifestHash)) {
        throw 'Manifest changed after install interruption; recovery blocked'
    }
    $oldBackup = Join-Path $transaction 'old.manifest.json'
    if ($record.hadManifest) {
        if ((Get-SyncFileFingerprint $oldBackup) -ne [string]$record.oldManifestHash) {
            throw 'Install backup manifest hash mismatch; recovery blocked'
        }
        Assert-OriginalInstalledSkills $oldBackup $Destination
    }
    foreach ($entry in @($record.entries)) {
        $target = Join-Path $Destination ([string]$entry.name)
        if (Test-Path -LiteralPath $target) {
            if (-not $isJournal -or -not (Test-Path -LiteralPath $target -PathType Container)) {
                throw "Unexpected install target: $target; recovery blocked"
            }
            if ((Get-SyncFingerprint $target) -ne [string]$entry.sha256) {
                throw "Install target changed after interruption: $target; recovery blocked"
            }
        }
    }
    # No product files were mutated during preparation. During journaled
    # commit, selected newly added directories are owned by this transaction.
    foreach ($entry in @($record.entries)) {
        $target = Join-Path $Destination ([string]$entry.name)
        if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
    }
    if ($record.hadManifest) {
        if ((Get-InstallManifestHash $ManifestPath) -ne [string]$record.oldManifestHash) {
            $tempRestore = Join-Path $transaction 'restore.manifest.json'
            Copy-Item -LiteralPath $oldBackup -Destination $tempRestore -Force
            Move-Item -LiteralPath $tempRestore -Destination $ManifestPath -Force
        }
    }
    elseif (Test-Path -LiteralPath $ManifestPath) {
        Remove-Item -LiteralPath $ManifestPath -Force
    }
    if ((Get-InstallManifestHash $ManifestPath) -ne [string]$record.oldManifestHash) {
        throw 'Install rollback manifest verification failed'
    }
    if ($record.hadManifest) { Assert-OriginalInstalledSkills $oldBackup $Destination }
    Remove-Item -LiteralPath $transaction -Recurse -Force
    Write-Output 'RECOVERED: added Skills removed; original manifest and installed Skills preserved'
}

function Invoke-TransactionalInstall {
    param([string]$Destination,[string]$ManifestPath,[object]$Manifest,[array]$Plans,
        [ValidateSet('None','AfterFirstMove','BeforeManifest','AfterManifest','InterruptAfterFirstMove','InterruptDuringStaging')]
        [string]$TestFailurePoint = 'None')
    Assert-NoPendingInstallTransaction $Destination
    Assert-NoPendingSyncTransaction $Destination
    $transaction = Get-InstallTransactionPath $Destination
    New-Item -ItemType Directory -Path $transaction -ErrorAction Stop | Out-Null
    $stageRoot = Join-Path $transaction 'stage'
    $oldBackup = Join-Path $transaction 'old.manifest.json'
    $nextManifest = Join-Path $transaction 'next.manifest.json'
    $oldHash = Get-InstallManifestHash $ManifestPath
    $entries = @($Plans | ForEach-Object { [pscustomobject]@{ name = $_.Skill.Name } })
    $prepare = [pscustomobject]@{
        schema = 1
        destination = [System.IO.Path]::GetFullPath($Destination)
        oldManifestHash = $oldHash
        hadManifest = [bool]$oldHash
        entries = $entries
    }
    try {
        [System.IO.File]::WriteAllText((Join-Path $transaction 'prepare.json'),
            ($prepare | ConvertTo-Json -Depth 10) + [Environment]::NewLine,
            (New-Object System.Text.UTF8Encoding($false)))
        if ($oldHash) {
            Copy-Item -LiteralPath $ManifestPath -Destination $oldBackup
            if ((Get-SyncFileFingerprint $oldBackup) -ne $oldHash) { throw 'Manifest changed before staging' }
            Assert-OriginalInstalledSkills $oldBackup $Destination
        }
        New-Item -ItemType Directory -Path $stageRoot | Out-Null
        $snapshotEntries = @()
        foreach ($plan in $Plans) {
            if (Test-Path -LiteralPath $plan.Target) {
                throw "Destination appeared during install: $($plan.Target)"
            }
            $stage = Join-Path $stageRoot $plan.Skill.Name
            Copy-Item -LiteralPath $plan.Skill.Directory -Destination $stage -Recurse
            $stagedMap = Get-FileHashes $stage
            Assert-SameManagedFiles $plan.Hashes $stagedMap $plan.Skill.Name -RejectExtra
            $snapshotEntries += [pscustomobject]@{
                name = $plan.Skill.Name
                sha256 = Get-SkillVersion $stagedMap
            }
            $Manifest.installed = @($Manifest.installed) + @(New-ManifestEntry $plan.Skill $plan.Hashes)
            if ($TestFailurePoint -eq 'InterruptDuringStaging') {
                throw 'TEST-INJECT: InterruptDuringStaging'
            }
        }
        Write-Manifest $nextManifest $Manifest
        $newHash = Get-SyncFileFingerprint $nextManifest
        if ((Get-InstallManifestHash $ManifestPath) -ne $oldHash) {
            throw 'Manifest changed during install staging'
        }
        if ($oldHash) { Assert-OriginalInstalledSkills $oldBackup $Destination }
        foreach ($plan in $Plans) {
            if (Test-Path -LiteralPath $plan.Target) {
                throw "Install target appeared during staging: $($plan.Target)"
            }
        }
        $journal = [pscustomobject]@{
            schema = 1
            destination = [System.IO.Path]::GetFullPath($Destination)
            oldManifestHash = $oldHash
            hadManifest = [bool]$oldHash
            newManifestHash = $newHash
            entries = @($snapshotEntries)
        }
        [System.IO.File]::WriteAllText((Join-Path $transaction 'journal.json'),
            ($journal | ConvertTo-Json -Depth 12) + [Environment]::NewLine,
            (New-Object System.Text.UTF8Encoding($false)))
    }
    catch {
        $problem = $_.Exception.Message
        if ($problem -eq 'TEST-INJECT: InterruptDuringStaging') {
            throw 'TEST-INJECT staging interrupted; prepare record preserved for install.ps1 -Recover'
        }
        # Preparation never changed the installed set.
        Remove-Item -LiteralPath $transaction -Recurse -Force -ErrorAction SilentlyContinue
        throw "Install staging failed ($problem); no Skills were installed"
    }
    try {
        $moved = 0
        foreach ($entry in $snapshotEntries) {
            $stage = Join-Path $stageRoot $entry.name
            $target = Join-Path $Destination $entry.name
            if (Test-Path -LiteralPath $target) { throw "Install target appeared during commit: $target" }
            Move-Item -LiteralPath $stage -Destination $target
            $moved++
            if ($moved -eq 1 -and $TestFailurePoint -in @('AfterFirstMove','InterruptAfterFirstMove')) {
                throw "TEST-INJECT: $TestFailurePoint"
            }
        }
        if ($TestFailurePoint -eq 'BeforeManifest') { throw 'TEST-INJECT: BeforeManifest' }
        Move-Item -LiteralPath $nextManifest -Destination $ManifestPath -Force
        if ($TestFailurePoint -eq 'AfterManifest') { throw 'TEST-INJECT: AfterManifest' }
        foreach ($entry in $snapshotEntries) {
            if ((Get-SyncFingerprint (Join-Path $Destination $entry.name)) -ne [string]$entry.sha256) {
                throw "Installed Skill hash mismatch: $($entry.name)"
            }
        }
        if ((Get-InstallManifestHash $ManifestPath) -ne $newHash) {
            throw 'Installed manifest hash mismatch'
        }
        $null = Read-Manifest $ManifestPath -Require
    }
    catch {
        $problem = $_.Exception.Message
        if ($problem -eq 'TEST-INJECT: InterruptAfterFirstMove') {
            throw 'TEST-INJECT commit interrupted; pending journal preserved for install.ps1 -Recover'
        }
        try { Restore-InstallTransaction $Destination $ManifestPath | Out-Null }
        catch {
            throw "Install failed ($problem); automatic rollback FAILED ($($_.Exception.Message)); preserve transaction for install.ps1 -Recover"
        }
        throw "Install failed ($problem); original manifest and installed Skills preserved"
    }
    Remove-Item -LiteralPath $transaction -Recurse -Force
}

# Stage 9C failure-injection smoke; writes only to disposable HomePath.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "ASSERT FAILED: $Message" }
}

$repo = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
. (Join-Path $repo 'scripts\SkillUtils.ps1')
$install = Join-Path $repo 'scripts\install.ps1'
$sync = Join-Path $repo 'scripts\sync.ps1'
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("wfa-txn-" + [guid]::NewGuid().ToString('N'))
$source = Join-Path $tmp 'source'
$fixtureHome = Join-Path $tmp 'home'
$root = Join-Path (Join-Path $fixtureHome '.agents') 'skills'
$manifest = Join-Path $root '.workflow-for-agents.manifest.json'
$transaction = Get-SyncTransactionPath $root

function Get-Snapshot {
    return [pscustomobject]@{
        manifest = (Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash
        a = (Get-SkillVersion (Get-FileHashes (Join-Path $root 'task-planning')))
        b = (Get-SkillVersion (Get-FileHashes (Join-Path $root 'audit')))
    }
}

function Assert-Snapshot {
    param([object]$Expected,[string]$Name)
    $snapshot = Get-Snapshot
    Assert ($snapshot.manifest -eq $Expected.manifest) "${Name}: manifest mismatch"
    Assert ($snapshot.a -eq $Expected.a) "${Name}: first Skill mismatch"
    Assert ($snapshot.b -eq $Expected.b) "${Name}: second Skill mismatch"
}

try {
    New-Item -ItemType Directory -Path $fixtureHome,(Join-Path $source 'skills\core'),(Join-Path $source 'skills\development') -Force | Out-Null
    $srcA = Join-Path $source 'skills\core\task-planning'
    $srcB = Join-Path $source 'skills\development\audit'
    Copy-Item -LiteralPath (Join-Path $repo 'skills\core\task-planning') -Destination $srcA -Recurse
    Copy-Item -LiteralPath (Join-Path $repo 'skills\development\audit') -Destination $srcB -Recurse
    & $install -Scope user -RepositoryRoot $source -HomePath $fixtureHome -Skills task-planning,audit | Out-Null
    Assert (Test-Path -LiteralPath $manifest -PathType Leaf) 'initial manifest not written'
    $unmanaged = Join-Path $root 'task-planning\private-notes.txt'
    Set-Content -LiteralPath $unmanaged -Value 'local notes' -Encoding UTF8
    $before = Get-Snapshot

    # Fault injection requires an isolated TEMP home and an explicit marker.
    $denied = $false
    try { & $sync -Scope user -RepositoryRoot $source -HomePath $fixtureHome -Skills task-planning,audit -TestFailurePoint AfterFirstSwap | Out-Null }
    catch { $denied = $_.Exception.Message.Contains('disposable test marker') }
    Assert $denied 'TestFailurePoint accepted an unmarked HOME'
    Assert-Snapshot $before 'unmarked-home rejection'
    Set-Content -LiteralPath (Join-Path $fixtureHome '.wfa-sync-transaction-test-home') -Value 'disposable' -Encoding UTF8

    Add-Content -LiteralPath (Join-Path $srcA 'SKILL.md') -Value '# update A' -Encoding UTF8
    Add-Content -LiteralPath (Join-Path $srcB 'SKILL.md') -Value '# update B' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $srcB 'added.txt') -Value 'new managed file' -Encoding UTF8
    & $sync -Scope user -RepositoryRoot $source -HomePath $fixtureHome -Skills task-planning,audit -DryRun | Out-Null
    Assert-Snapshot $before 'dry-run'
    Assert (-not (Test-Path -LiteralPath $transaction)) 'dry-run created transaction'

    foreach ($point in @('AfterFirstSwap','BeforeManifest','AfterManifest')) {
        $failed = $false
        try { & $sync -Scope user -RepositoryRoot $source -HomePath $fixtureHome -Skills task-planning,audit -TestFailurePoint $point | Out-Null }
        catch { $failed = $true }
        Assert $failed "${point}: did not raise failure"
        Assert-Snapshot $before "${point}: rollback"
        Assert (-not (Test-Path -LiteralPath $transaction)) "${point}: transaction left behind"
        Assert ((Get-Content -LiteralPath $unmanaged -Raw).Contains('local notes')) "${point}: unmanaged file deleted"
    }

    foreach ($interruptPoint in @('InterruptAfterBackup','InterruptAfterFirstSwap')) {
        $interrupted = $false
        try { & $sync -Scope user -RepositoryRoot $source -HomePath $fixtureHome -Skills task-planning,audit -TestFailurePoint $interruptPoint | Out-Null }
        catch { $interrupted = $_.Exception.Message.Contains('pending journal preserved') }
        Assert $interrupted "$interruptPoint did not leave recoverable journal"
        Assert (Test-Path -LiteralPath (Join-Path $transaction 'journal.json') -PathType Leaf) 'journal not retained'
        $blocked = $false
        try { & $sync -Scope user -RepositoryRoot $source -HomePath $fixtureHome -DryRun | Out-Null }
        catch { $blocked = $_.Exception.Message.Contains('Pending sync transaction') }
        Assert $blocked 'pending transaction did not block sync dry-run'
        $blocked = $false
        try { & $install -Scope user -RepositoryRoot $source -HomePath $fixtureHome -Skills task-planning | Out-Null }
        catch { $blocked = $_.Exception.Message.Contains('Pending sync transaction') }
        Assert $blocked 'pending transaction did not block install'
        & $sync -Scope user -HomePath $fixtureHome -Recover | Out-Null
        Assert-Snapshot $before "$interruptPoint recovery"
        Assert (-not (Test-Path -LiteralPath $transaction)) 'recovery did not clear journal'
    }

    & $sync -Scope user -RepositoryRoot $source -HomePath $fixtureHome -Skills task-planning,audit | Out-Null
    $after = Get-Snapshot
    Assert ($after.manifest -ne $before.manifest) 'successful sync did not update manifest'
    Assert ($after.a -ne $before.a -and $after.b -ne $before.b) 'both Skills not updated'
    Assert (Test-Path -LiteralPath (Join-Path $root 'audit\added.txt') -PathType Leaf) 'added source file missing'
    Assert ((Get-Content -LiteralPath $unmanaged -Raw).Contains('local notes')) 'success lost unmanaged data'
    Assert (-not (Test-Path -LiteralPath $transaction)) 'success left journal'
    & $sync -Scope user -RepositoryRoot $source -HomePath $fixtureHome -Skills task-planning,audit | Out-Null
    Assert-Snapshot $after 'repeat sync'

    $manifestOriginal = Get-Content -LiteralPath $manifest -Raw -Encoding UTF8
    [System.IO.File]::WriteAllText($manifest, '{"schema":9}', (New-Object System.Text.UTF8Encoding($false)))
    $badHash = (Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash
    $failed = $false
    try { & $sync -Scope user -RepositoryRoot $source -HomePath $fixtureHome | Out-Null }
    catch { $failed = $true }
    Assert $failed 'corrupted manifest was accepted'
    Assert ((Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash -eq $badHash) 'invalid manifest modified'
    Assert (-not (Test-Path -LiteralPath $transaction)) 'corrupt manifest initiated transaction'
    [System.IO.File]::WriteAllText($manifest, $manifestOriginal, (New-Object System.Text.UTF8Encoding($false)))

    Add-Content -LiteralPath (Join-Path $srcA 'SKILL.md') -Value '# update C' -Encoding UTF8
    $interrupted = $false
    try { & $sync -Scope user -RepositoryRoot $source -HomePath $fixtureHome -Skills task-planning,audit -TestFailurePoint InterruptAfterFirstSwap | Out-Null }
    catch { $interrupted = $true }
    Assert $interrupted 'second interruption failed'
    $j = Get-Content -LiteralPath (Join-Path $transaction 'journal.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $modified = Join-Path (Join-Path $root ([string]$j.entries[0].name)) 'SKILL.md'
    Add-Content -LiteralPath $modified -Value '# post-interruption user edit' -Encoding UTF8
    $blocked = $false
    try { & $sync -Scope user -HomePath $fixtureHome -Recover | Out-Null }
    catch { $blocked = $_.Exception.Message.Contains('recovery blocked') }
    Assert $blocked 'recovery overwrote a post-interruption user edit'
    Assert (Test-Path -LiteralPath $transaction) 'blocked recovery deleted backup'
    Assert ((Get-Content -LiteralPath $modified -Raw).Contains('post-interruption user edit')) 'post-interruption edit lost'

    Write-Output 'PASS: transactional two-Skill sync; staged hashes, rollback, interruption, recovery, tamper protection, unmanaged files'
}
finally {
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
}

# Stage 11: add-only install failure injection in disposable HOME fixtures.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Assert {
    param([bool]$Condition,[string]$Message)
    if (-not $Condition) { throw "ASSERT FAILED: $Message" }
}
$repo = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
. (Join-Path $repo 'scripts\SkillUtils.ps1')
$install = Join-Path $repo 'scripts\install.ps1'
$sync = Join-Path $repo 'scripts\sync.ps1'
$preflight = Join-Path $repo 'scripts\global-preflight.ps1'
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("wfa-install-" + [guid]::NewGuid().ToString('N'))
$source = Join-Path $tmp 'source'
$fixtureHome = Join-Path $tmp 'home'
$root = Join-Path (Join-Path $fixtureHome '.agents') 'skills'
$manifest = Join-Path $root '.workflow-for-agents.manifest.json'
$transaction = Get-InstallTransactionPath $root

function Get-Baseline {
    $doc = Get-Content -LiteralPath $manifest -Raw -Encoding UTF8 | ConvertFrom-Json
    return [pscustomobject]@{
        manifest = (Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash
        workflow = (Get-SkillVersion (Get-FileHashes (Join-Path $root 'git-workflow')))
        debugging = (Get-SkillVersion (Get-FileHashes (Join-Path $root 'root-cause-debugging')))
        count = @($doc.installed).Count
    }
}
function Assert-Baseline {
    param([object]$Expected,[string]$Label)
    $current = Get-Baseline
    Assert ($current.manifest -eq $Expected.manifest) "$($Label): manifest changed"
    Assert ($current.workflow -eq $Expected.workflow) "$($Label): git-workflow changed"
    Assert ($current.debugging -eq $Expected.debugging) "$($Label): root-cause-debugging changed"
    Assert ($current.count -eq $Expected.count) "$($Label): manifest count changed"
    Assert (-not (Test-Path -LiteralPath (Join-Path $root 'audit'))) "$($Label): audit partial"
    Assert (-not (Test-Path -LiteralPath (Join-Path $root 'task-planning'))) "$($Label): task-planning partial"
}
try {
    New-Item -ItemType Directory -Path $fixtureHome,(Join-Path $source 'skills') -Force | Out-Null
    foreach ($name in @('git-workflow','root-cause-debugging','audit','task-planning')) {
        $hits = @(Get-ChildItem -LiteralPath (Join-Path $repo 'skills') -Filter SKILL.md -Recurse -File |
            Where-Object { $_.Directory.Name -eq $name })
        Assert ($hits.Count -eq 1) "Source Skill not unique: $name"
        $rel = Get-RelativeFilePath $hits[0].Directory.FullName (Join-Path $repo 'skills')
        $dest = Join-Path (Join-Path $source 'skills') $rel
        New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force | Out-Null
        Copy-Item -LiteralPath $hits[0].Directory.FullName -Destination $dest -Recurse
    }
    & $install -Scope user -HomePath $fixtureHome -RepositoryRoot $source -Skills git-workflow,root-cause-debugging | Out-Null
    $baseline = Get-Baseline
    Assert ($baseline.count -eq 2) 'fixture should have two managed Skills'
    $unmanaged = Join-Path $root 'user-owned'
    New-Item -ItemType Directory -Path $unmanaged -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $unmanaged 'note.txt') -Value 'keep data' -Encoding UTF8
    New-Item -ItemType Directory -Path (Join-Path $fixtureHome '.codex') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $fixtureHome '.codex\AGENTS.md') -Value 'keep AGENTS' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $fixtureHome '.codex\hooks.json') -Value 'keep hooks' -Encoding UTF8

    $backup = Join-Path $tmp 'backup-injected'
    & $install -Scope user -HomePath $fixtureHome -RepositoryRoot $source -All -DryRun -BackupPath $backup | Out-Null
    Assert (-not (Test-Path -LiteralPath $backup)) 'dry-run created backup'
    Assert-Baseline $baseline 'dry-run'
    $blocked = $false
    try { & $install -Scope user -HomePath $fixtureHome -RepositoryRoot $source -All -TestFailurePoint AfterFirstMove | Out-Null }
    catch { $blocked = $_.Exception.Message.Contains('test marker') }
    Assert $blocked 'unmarked HOME accepted failure injection'
    Assert-Baseline $baseline 'unmarked HOME'
    Set-Content -LiteralPath (Join-Path $fixtureHome '.wfa-install-transaction-test-home') -Value 'fixture' -Encoding UTF8

    foreach ($point in @('AfterFirstMove','BeforeManifest','AfterManifest')) {
        $failed = $false
        $failureDetail = ''
        try {
            if ($point -eq 'AfterFirstMove') {
                & $install -Scope user -HomePath $fixtureHome -RepositoryRoot $source -All -BackupPath $backup -TestFailurePoint $point | Out-Null
            } else {
                & $install -Scope user -HomePath $fixtureHome -RepositoryRoot $source -All -TestFailurePoint $point | Out-Null
            }
        }
        catch { $failed = $true; $failureDetail = $_.Exception.Message }
        Assert $failed "$point did not raise injected failure"
        Assert ($failureDetail.Contains("TEST-INJECT: $point")) "$point failed for unexpected reason: $failureDetail"
        Assert-Baseline $baseline "$point rollback"
        Assert (-not (Test-Path -LiteralPath $transaction)) "$point left transaction"
    }
    Assert (Test-Path -LiteralPath (Join-Path $backup 'backup-record.json')) 'external backup record missing'
    Assert ((Get-FileHash -LiteralPath (Join-Path $backup 'original.manifest.json') -Algorithm SHA256).Hash -eq $baseline.manifest) 'external manifest backup differs'
    foreach ($name in @('git-workflow','root-cause-debugging')) {
        Assert (Test-Path -LiteralPath (Join-Path (Join-Path $backup 'managed-skills') $name)) "missing backup Skill $name"
    }

    foreach ($point in @('InterruptDuringStaging','InterruptAfterFirstMove')) {
        $interrupted = $false
        try { & $install -Scope user -HomePath $fixtureHome -RepositoryRoot $source -All -TestFailurePoint $point | Out-Null }
        catch { $interrupted = $_.Exception.Message.Contains('preserved for install.ps1 -Recover') }
        Assert $interrupted "$point did not preserve recovery"
        Assert (Test-Path -LiteralPath $transaction -PathType Container) 'transaction dir missing'
        $blocked = $false
        try { & $install -Scope user -HomePath $fixtureHome -RepositoryRoot $source -All -DryRun | Out-Null }
        catch { $blocked = $_.Exception.Message.Contains('Pending install transaction') }
        Assert $blocked 'install bypassed pending transaction'
        $blocked = $false
        try { & $sync -Scope user -HomePath $fixtureHome -RepositoryRoot $source -DryRun | Out-Null }
        catch { $blocked = $_.Exception.Message.Contains('Pending install transaction') }
        Assert $blocked 'sync bypassed pending install'
        $report = ((& $preflight -All -HomePath $fixtureHome -RepositoryRoot $repo -OutputFormat Json | Out-String).Trim() | ConvertFrom-Json)
        Assert ($report.Summary.Blocked -eq $true -and $report.Summary.Ready -eq $false) 'preflight false READY during pending install'
        & $install -Scope user -HomePath $fixtureHome -Recover | Out-Null
        Assert-Baseline $baseline "$point recovered"
        Assert (-not (Test-Path -LiteralPath $transaction)) 'recovery did not clean transaction'
    }
    & $install -Scope user -HomePath $fixtureHome -RepositoryRoot $source -All -BackupPath (Join-Path $tmp 'backup-success') | Out-Null
    $after = Get-Baseline
    Assert ($after.count -eq 4) 'success did not install all four Skills'
    Assert ($after.workflow -eq $baseline.workflow -and $after.debugging -eq $baseline.debugging) 'existing managed Skill changed'
    Assert ((Get-Content -LiteralPath (Join-Path $unmanaged 'note.txt') -Raw).Contains('keep data')) 'unmanaged data lost'
    Assert ((Get-Content -LiteralPath (Join-Path $fixtureHome '.codex\AGENTS.md') -Raw).Contains('keep AGENTS')) 'AGENTS changed'
    Assert ((Get-Content -LiteralPath (Join-Path $fixtureHome '.codex\hooks.json') -Raw).Contains('keep hooks')) 'hooks changed'
    Assert (-not (Test-Path -LiteralPath $transaction)) 'successful install left transaction'
    & $install -Scope user -HomePath $fixtureHome -RepositoryRoot $source -All | Out-Null
    Assert ((Get-Baseline).manifest -eq $after.manifest) 'repeat installation changed manifest'

    # Real source tree in temporary HOME: installed 2, then 27 missing.
    $fullHome = Join-Path $tmp 'full-home'
    New-Item -ItemType Directory -Path $fullHome -Force | Out-Null
    & $install -Scope user -HomePath $fullHome -RepositoryRoot $repo -Skills git-workflow,root-cause-debugging | Out-Null
    $fullBackup = Join-Path $tmp 'full-backup'
    & $install -Scope user -HomePath $fullHome -RepositoryRoot $repo -All -BackupPath $fullBackup | Out-Null
    $fullReport = ((& $preflight -All -HomePath $fullHome -RepositoryRoot $repo -OutputFormat Json | Out-String).Trim() | ConvertFrom-Json)
    $expectedCount = @(Get-PreflightImplementedSkillNames $repo).Count
    Assert (@($fullReport.Targets | Where-Object { $_.Status -ne 'CURRENT' }).Count -eq 0) 'full catalog not CURRENT'
    Assert ($fullReport.Summary.CheckedSelectedSkills -eq $expectedCount) 'catalog target count mismatch'
    Assert (Test-Path -LiteralPath (Join-Path $fullBackup 'original.manifest.json')) 'full rollout missing backup'

    # An interrupted, then user-modified newly added file must not be deleted by recovery.
    $tamperHome = Join-Path $tmp 'tamper-home'
    New-Item -ItemType Directory -Path $tamperHome -Force | Out-Null
    & $install -Scope user -HomePath $tamperHome -RepositoryRoot $source -Skills git-workflow,root-cause-debugging | Out-Null
    Set-Content -LiteralPath (Join-Path $tamperHome '.wfa-install-transaction-test-home') -Value 'fixture' -Encoding UTF8
    $tamperRoot = Join-Path (Join-Path $tamperHome '.agents') 'skills'
    $tamperTxn = Get-InstallTransactionPath $tamperRoot
    $failed = $false
    try { & $install -Scope user -HomePath $tamperHome -RepositoryRoot $source -All -TestFailurePoint InterruptAfterFirstMove | Out-Null }
    catch { $failed = $true }
    Assert $failed 'tamper fixture did not interrupt'
    $journal = Get-Content -LiteralPath (Join-Path $tamperTxn 'journal.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $target = Join-Path (Join-Path $tamperRoot ([string]$journal.entries[0].name)) 'SKILL.md'
    Add-Content -LiteralPath $target -Value '# user edit after interruption'
    $blocked = $false
    try { & $install -Scope user -HomePath $tamperHome -Recover | Out-Null }
    catch { $blocked = $_.Exception.Message.Contains('recovery blocked') }
    Assert $blocked 'recovery did not protect modified target'
    Assert (Test-Path -LiteralPath $tamperTxn) 'blocked recovery removed evidence'
    Assert ((Get-Content -LiteralPath $target -Raw).Contains('user edit after interruption')) 'recovery overwrote user changes'

    Write-Output "PASS: Stage 11 transactional install, rollback, recovery, backup, unchanged WFA/AGENTS/hooks, full $expectedCount-Skill catalog, tamper protection"
}
finally {
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
}

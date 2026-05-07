# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026, UAB Kurokesu
#
# Host-side (Windows). Sync CinePiUi/ to the target Pi and restart
# ui-sandbox.service so the running harness picks up the new QML.
#
# Initial run does a full scp -r to establish the baseline. -Watch mode
# then pushes individual files as they change (one scp per file), with
# a short debounce so a burst of saves = one restart.
#
# Usage: ./sync.ps1 <SshTarget> [-Watch] [-RemotePath PATH] [-NoRestart]
#
# Example: ./sync.ps1 cinepi -Watch
#
# Prerequisites on the host:
#   - OpenSSH client (built-in on Windows 10+: Settings > Optional Features)
#
# Prerequisites on the target:
#   1. Passwordless SSH from host. See https://github.com/Kurokesu/ssh-keyup
#   2. Passwordless sudo for the one restart command:
#        echo "$USER ALL=(root) NOPASSWD: /bin/systemctl restart ui-sandbox.service" |
#          sudo tee /etc/sudoers.d/cinepi-ui-sandbox
#        sudo chmod 440 /etc/sudoers.d/cinepi-ui-sandbox
#   3. ui-sandbox/run.sh running in another shell to see changes live.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$SshTarget,

    [switch]$Watch,

    [string]$RemotePath = '/var/tmp/cinepi-ui-sandbox/CinePiUi',

    [switch]$NoRestart
)

$ErrorActionPreference = 'Stop'

$sandboxDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoDir    = Split-Path -Parent $sandboxDir
$srcDir     = (Resolve-Path (Join-Path $repoDir 'CinePiUi')).Path

if (-not (Test-Path $srcDir)) { throw "CinePiUi not found at $srcDir" }

# Extensions worth syncing. Everything else (QDS atomic-save tempfiles,
# generated .cmake/.h, editor swap files, ...) is ignored at the watcher.
$includeExt = @(
    '.qml', '.conf',
    '.png', '.jpg', '.jpeg', '.svg', '.webp',
    '.ttf', '.otf', '.woff', '.woff2',
    '.json', '.js'
)

function Write-Tag($msg, $color = 'Green') {
    Write-Host "[sync] " -ForegroundColor $color -NoNewline
    Write-Host $msg
}

function Test-Watched($name) {
    $ext = [System.IO.Path]::GetExtension($name).ToLowerInvariant()
    return $includeExt -contains $ext
}

function Invoke-Ssh([string[]]$RemoteCmd) {
    & ssh -o BatchMode=yes $SshTarget @RemoteCmd
    return $LASTEXITCODE
}

function Sync-FullTree {
    # Full tree copy to establish / reset the baseline.
    & scp -rq "$srcDir/." "${SshTarget}:${RemotePath}/"
    if ($LASTEXITCODE -ne 0) { throw "scp (full) failed (exit $LASTEXITCODE)" }
}

function Sync-File([string]$RelPath) {
    # Push one file. Ensure its parent dir exists first.
    $posixRel = $RelPath.Replace('\', '/')
    $parent   = [System.IO.Path]::GetDirectoryName($posixRel).Replace('\', '/')
    $dstDir   = if ($parent) { "$RemotePath/$parent" } else { $RemotePath }

    $code = Invoke-Ssh @("mkdir -p '$dstDir'")
    if ($code -ne 0) {
        Write-Tag "mkdir failed for $dstDir" 'Yellow'
        return
    }

    $srcFile = Join-Path $srcDir $RelPath
    & scp -q $srcFile "${SshTarget}:${dstDir}/"
    if ($LASTEXITCODE -ne 0) {
        Write-Tag "scp failed for $posixRel (exit $LASTEXITCODE)" 'Yellow'
    }
}

function Remove-RemoteFile([string]$RelPath) {
    $posixRel = $RelPath.Replace('\', '/')
    $code = Invoke-Ssh @("rm -f '$RemotePath/$posixRel'")
    if ($code -ne 0) {
        Write-Tag "rm failed for $posixRel" 'Yellow'
    }
}

function Restart-Service {
    if ($NoRestart) { return }
    $code = Invoke-Ssh @('sudo -n systemctl restart ui-sandbox.service')
    if ($code -ne 0) {
        Write-Tag 'restart failed (is ui-sandbox.service running? NOPASSWD sudo configured?)' 'Yellow'
    }
}

Write-Tag "target:      $SshTarget"
Write-Tag "remote path: $RemotePath"
Write-Tag "restart:     $(-not $NoRestart)"

$code = Invoke-Ssh @("mkdir -p '$RemotePath'")
if ($code -ne 0) { throw "failed to reach $SshTarget or create $RemotePath" }

Sync-FullTree
Write-Tag 'initial sync done'
Restart-Service

if (-not $Watch) { return }

$watcher = [System.IO.FileSystemWatcher]::new($srcDir)
$watcher.IncludeSubdirectories = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite -bor
                        [System.IO.NotifyFilters]::FileName

Write-Tag "watching $srcDir for changes (Ctrl+C to stop)"

try {
    while ($true) {
        $change = $watcher.WaitForChanged([System.IO.WatcherChangeTypes]::All, 1000)
        if ($change.TimedOut) { continue }
        if (-not (Test-Watched $change.Name)) { continue }

        # Per-path latest-op table; collapses burst events (Create+Modify)
        # and QDS atomic-save tempfile churn down to one op per real file.
        $ops = [System.Collections.Generic.Dictionary[string, string]]::new()
        $ops[$change.Name] = if ($change.ChangeType -eq [System.IO.WatcherChangeTypes]::Deleted) { 'delete' } else { 'sync' }

        # Drain follow-up events in a 300ms window.
        $deadline = (Get-Date).AddMilliseconds(300)
        while ((Get-Date) -lt $deadline) {
            $extra = $watcher.WaitForChanged([System.IO.WatcherChangeTypes]::All, 100)
            if ($extra.TimedOut) { break }
            if (-not (Test-Watched $extra.Name)) { continue }
            $ops[$extra.Name] = if ($extra.ChangeType -eq [System.IO.WatcherChangeTypes]::Deleted) { 'delete' } else { 'sync' }
        }

        $acted = $false
        foreach ($rel in $ops.Keys) {
            switch ($ops[$rel]) {
                'delete' {
                    Remove-RemoteFile $rel
                    Write-Tag "deleted $($rel.Replace('\', '/'))"
                    $acted = $true
                }
                'sync' {
                    # Renamed away / deleted-then-present races: skip if the
                    # file vanished before we got here (next event will cover it).
                    if (Test-Path (Join-Path $srcDir $rel)) {
                        Sync-File $rel
                        Write-Tag "synced  $($rel.Replace('\', '/'))"
                        $acted = $true
                    }
                }
            }
        }

        if ($acted) { Restart-Service }
    }
} finally {
    $watcher.Dispose()
    Write-Tag 'stopped' 'Red'
}

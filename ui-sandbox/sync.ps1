# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026, UAB Kurokesu. All rights reserved.
#
# Host-side (Windows). scp CinePiUi/ to the target Pi, then restart
# ui-sandbox.service so the running harness picks up the new QML.
#
# Usage: ./sync.ps1 <SshTarget> [-Watch] [-RemotePath PATH] [-NoRestart]
#
# Example: ./sync.ps1 kurokesu@cinepi.local -Watch
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
#   3. ui-sandbox/run.sh already running (in another shell) if you want
#      -NoRestart omitted; otherwise nothing will pick up the changes.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$SshTarget,

    [switch]$Watch,

    [string]$RemotePath = '~/kurokesu-cinepi/CinePiUi',

    [switch]$NoRestart
)

$ErrorActionPreference = 'Stop'

$sandboxDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoDir    = Split-Path -Parent $sandboxDir
$srcDir     = Join-Path $repoDir 'CinePiUi'

if (-not (Test-Path $srcDir)) { throw "CinePiUi not found at $srcDir" }

function Write-Tag($msg, $color = 'Green') {
    Write-Host "[sync] " -ForegroundColor $color -NoNewline
    Write-Host $msg
}

function Invoke-Sync {
    # Full-tree copy. scp -r preserves subdir structure; overwrites existing files.
    & scp -rq "$srcDir/." "${SshTarget}:${RemotePath}/"
    if ($LASTEXITCODE -ne 0) { throw "scp failed (exit $LASTEXITCODE)" }

    if (-not $NoRestart) {
        & ssh -o BatchMode=yes $SshTarget 'sudo -n systemctl restart ui-sandbox.service'
        if ($LASTEXITCODE -ne 0) {
            Write-Tag 'restart failed (is ui-sandbox.service running? NOPASSWD sudo configured?)' 'Yellow'
        }
    }
}

Write-Tag "target:      $SshTarget"
Write-Tag "remote path: $RemotePath"
Write-Tag "restart:     $(-not $NoRestart)"

& ssh -o BatchMode=yes $SshTarget "mkdir -p $RemotePath"
if ($LASTEXITCODE -ne 0) { throw "failed to create $RemotePath on $SshTarget" }

Invoke-Sync
Write-Tag 'initial sync done'

if ($Watch) {
    Write-Tag "watching $srcDir for changes (Ctrl+C to stop)"

    $watcher = [System.IO.FileSystemWatcher]::new($srcDir)
    $watcher.IncludeSubdirectories = $true
    $watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite -bor
                            [System.IO.NotifyFilters]::FileName

    # Whitelist of extensions that trigger a re-sync. Everything else
    # (QDS atomic-save tempfiles, generated .cmake/.h, editor swap files, ...)
    # is ignored at the watcher. scp still pushes the full tree when triggered.
    $includeExt = @(
        '.qml', '.conf',
        '.png', '.jpg', '.jpeg', '.svg', '.webp',
        '.ttf', '.otf', '.woff', '.woff2',
        '.json', '.js'
    )
    $debounceMs = 400

    function Test-Watched($name) {
        $ext = [System.IO.Path]::GetExtension($name).ToLowerInvariant()
        return $includeExt -contains $ext
    }

    try {
        while ($true) {
            $change = $watcher.WaitForChanged([System.IO.WatcherChangeTypes]::All, 1000)
            if ($change.TimedOut) { continue }
            if (-not (Test-Watched $change.Name)) { continue }

            $changed = [System.Collections.Generic.HashSet[string]]::new()
            [void]$changed.Add($change.Name)

            # Drain any follow-up events in the next 300ms window so a burst
            # of saves coalesces into a single re-sync.
            $deadline = (Get-Date).AddMilliseconds(300)
            while ((Get-Date) -lt $deadline) {
                $extra = $watcher.WaitForChanged([System.IO.WatcherChangeTypes]::All, 100)
                if ($extra.TimedOut) { break }
                if (Test-Watched $extra.Name) { [void]$changed.Add($extra.Name) }
            }

            Invoke-Sync

            $names = $changed | ForEach-Object { $_.Replace('\', '/') }
            if ($names.Count -le 3) {
                Write-Tag "synced ($($names -join ', '))"
            } else {
                Write-Tag "synced ($($names.Count) files)"
            }
        }
    } finally {
        $watcher.Dispose()
        Write-Tag 'stopped' 'Red'
    }
}

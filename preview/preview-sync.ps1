# QML Preview host-side sync script (Windows PowerShell)
# Watches CinePiUi directory and syncs changed files to RPi via scp
#
# Usage: .\preview-sync.ps1 [-RemoteHost altcinecam] [-RemotePath ~/CinePiUi]

param(
    [string]$ProjectDir = "..\CinePiUi",
    [string]$RemoteHost = "altcinecam",
    [string]$RemotePath = "~/CinePiUi"
)

$ProjectDir = (Resolve-Path $ProjectDir).Path
Write-Host "=== QML Preview Sync ===" -ForegroundColor Cyan
Write-Host "Local:  $ProjectDir"
Write-Host "Remote: ${RemoteHost}:${RemotePath}"
Write-Host ""

Write-Host "Initial full sync..." -ForegroundColor Yellow
scp -r "$ProjectDir\CinePiUi" "${RemoteHost}:${RemotePath}/"
scp -r "$ProjectDir\CinePiUiContent" "${RemoteHost}:${RemotePath}/"
scp "$ProjectDir\qtquickcontrols2.conf" "${RemoteHost}:${RemotePath}/"
Write-Host "Initial sync done." -ForegroundColor Green
Write-Host ""

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $ProjectDir
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite -bor
                         [System.IO.NotifyFilters]::FileName

$ctx = @{
    RemoteHost = $RemoteHost
    RemotePath = $RemotePath
    ProjectDir = $ProjectDir
    Extensions = @('.qml', '.conf', '.jpg', '.png', '.ttf')
    LastSync   = @{}
}

$action = {
    $path = $Event.SourceEventArgs.FullPath
    $ext = [System.IO.Path]::GetExtension($path)
    $c = $Event.MessageData

    if ($ext -notin $c.Extensions) { return }

    $now = [DateTime]::Now
    if ($c.LastSync.ContainsKey($path) -and ($now - $c.LastSync[$path]).TotalMilliseconds -lt 500) {
        return
    }
    $c.LastSync[$path] = $now

    $relative = $path.Substring($c.ProjectDir.Length + 1).Replace('\', '/')
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Syncing: $relative" -ForegroundColor Yellow
    scp "$path" "$($c.RemoteHost):$($c.RemotePath)/$relative"
}

Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action -MessageData $ctx | Out-Null
Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action -MessageData $ctx | Out-Null
Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $action -MessageData $ctx | Out-Null

Write-Host "Watching for changes... (Ctrl+C to stop)" -ForegroundColor Cyan

try {
    while ($true) { Wait-Event -Timeout 1 | Out-Null }
} finally {
    Get-EventSubscriber | Unregister-Event
    $watcher.Dispose()
    Write-Host "Stopped." -ForegroundColor Red
}

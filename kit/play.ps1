# Plays Vanilla VR on a friend's server over Tailscale. The first run asks where your 1.12.1 game
# is and for the server's address, and keeps both in settings.txt beside this file (edit it to
# change them). Start SteamVR (or your headset's PC link) first; without it the game runs flat.
# Each run first brings this folder up to the version your friend published (only what changed,
# every file checked, the old copies kept for ROLLBACK.cmd) and sends your last game logs back to
# them, so bugs can be fixed (SEND_LOGS=no in settings.txt stops that).
# -DryRun checks everything and prints what it would start, without starting it. -Rollback goes
# back to the version before the last update (ROLLBACK.cmd).
param([switch]$DryRun, [switch]$Rollback)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$here = $PSScriptRoot
$settingsPath = Join-Path $here 'settings.txt'
$versionPath = Join-Path $here 'version.txt'
# Your friend's update channel, beside their server.
$updatesPort = 3726

function Read-Settings {
    $s = @{}
    if (Test-Path $settingsPath) {
        foreach ($l in Get-Content $settingsPath) {
            if ($l -match '^\s*([A-Z_]+)\s*=\s*(.*?)\s*$') { $s[$Matches[1]] = $Matches[2] }
        }
    }
    return $s
}

function Save-Settings($s) {
    $lines = @('# Vanilla VR: your game folder, your friend''s server (its Tailscale address), the name your',
        '# logs go to your friend under, and SEND_LOGS=no to keep your logs to yourself.')
    $lines += $s.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }
    Set-Content -Path $settingsPath -Value $lines -Encoding UTF8
}

# A 1.12.1 install: its Data folder holds the game's MPQ archives.
function Test-GameDir([string]$dir) {
    if (-not $dir) { return $false }
    $data = Join-Path $dir 'Data'
    return (Test-Path (Join-Path $data 'dbc.MPQ')) -and (Test-Path (Join-Path $data 'patch.MPQ'))
}

function Test-Tcp([string]$hostName, [int]$port) {
    $c = New-Object Net.Sockets.TcpClient
    try {
        $ar = $c.BeginConnect($hostName, $port, $null, $null)
        if (-not $ar.AsyncWaitHandle.WaitOne(3000)) { return $false }
        $c.EndConnect($ar)
        return $true
    } catch { return $false } finally { $c.Close() }
}

function Get-Sha256([string]$path) { (Get-FileHash -Path $path -Algorithm SHA256).Hash.ToLowerInvariant() }

function Get-Version {
    if (Test-Path $versionPath) { return "$(Get-Content $versionPath -TotalCount 1)".Trim() }
    return ''
}

function Expand-Gzip([string]$src, [string]$dst) {
    $in = [IO.File]::OpenRead($src)
    try {
        $gz = New-Object IO.Compression.GZipStream($in, [IO.Compression.CompressionMode]::Decompress)
        try {
            $out = [IO.File]::Create($dst)
            try { $gz.CopyTo($out) } finally { $out.Dispose() }
        } finally { $gz.Dispose() }
    } finally { $in.Dispose() }
}

function Compress-Gzip([string]$src, [string]$dst) {
    $in = [IO.File]::Open($src, 'Open', 'Read', 'ReadWrite')
    try {
        $out = [IO.File]::Create($dst)
        try {
            $gz = New-Object IO.Compression.GZipStream($out, [IO.Compression.CompressionLevel]::Optimal)
            try { $in.CopyTo($gz) } finally { $gz.Dispose() }
        } finally { $out.Dispose() }
    } finally { $in.Dispose() }
}

# Brings this folder to the version your friend published: only the files that changed, each one
# checked against its SHA-256 before anything is replaced, the old copies kept in previous\ for
# ROLLBACK.cmd. A version you rolled back from is not taken again (a newer one is). No answer from
# the update channel leaves everything as it is.
function Update-Kit([string]$server, $s) {
    $base = "http://${server}:$updatesPort"
    try {
        $r = Invoke-WebRequest -Uri "$base/manifest.json" -TimeoutSec 8 -UseBasicParsing -Headers @{ 'Cache-Control' = 'no-cache' }
    } catch {
        Write-Host 'No update check (your friend''s update channel did not answer): playing the version you have.' -ForegroundColor Yellow
        return
    }
    $json = if ($r.Content -is [byte[]]) { [Text.Encoding]::UTF8.GetString($r.Content) } else { "$($r.Content)" }
    $m = $null
    try { $m = $json.TrimStart([char]0xFEFF) | ConvertFrom-Json } catch { }
    if (-not $m -or -not $m.version -or @($m.files).Count -eq 0) {
        Write-Host 'Your friend''s update could not be read: playing the version you have.' -ForegroundColor Yellow
        return
    }
    $have = Get-Version
    if ($m.version -eq $have) {
        Write-Host "Up to date ($have)." -ForegroundColor Green
        return
    }
    if ($s['SKIP'] -and $m.version -eq $s['SKIP']) {
        Write-Host "Version $($m.version) is the one you went back from: staying on $have until a newer one." -ForegroundColor Yellow
        return
    }
    if (Get-Process -Name 'benilla-vr' -ErrorAction SilentlyContinue) {
        Write-Host 'Vanilla VR is still running: close it, then PLAY again to update.' -ForegroundColor Yellow
        return
    }
    Write-Host "Updating to $($m.version)..." -ForegroundColor Cyan
    $stage = Join-Path $here 'update'
    if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
    New-Item -ItemType Directory -Force -Path $stage | Out-Null
    $changed = @()
    foreach ($f in $m.files) {
        if ("$($f.path)" -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$' -or "$($f.url)" -notmatch '^[A-Za-z0-9._/-]+$') {
            throw "the update names a file it should not ($($f.path)); nothing was changed"
        }
        $local = Join-Path $here $f.path
        if ((Test-Path $local) -and (Get-Sha256 $local) -eq $f.sha256) { continue }
        Write-Host ("  {0} ({1:N1} MB)" -f $f.path, ($f.gz_size / 1MB))
        $gz = Join-Path $stage "$($f.path).gz"
        Invoke-WebRequest -Uri "$base/$($f.url)" -OutFile $gz -TimeoutSec 900 -UseBasicParsing
        $new = Join-Path $stage $f.path
        Expand-Gzip $gz $new
        Remove-Item $gz
        if ((Get-Sha256 $new) -ne $f.sha256) { throw "$($f.path) arrived damaged; nothing was changed, press PLAY to try again" }
        $changed += $f
    }
    # Everything arrived and checked: the old copies to previous\, the new ones in place.
    if ($changed.Count -gt 0) {
        $prev = Join-Path $here 'previous'
        if (Test-Path $prev) { Remove-Item -Recurse -Force $prev }
        New-Item -ItemType Directory -Force -Path $prev | Out-Null
        foreach ($f in $changed) {
            $local = Join-Path $here $f.path
            if (Test-Path $local) { Move-Item -Force $local (Join-Path $prev $f.path) }
            Move-Item -Force (Join-Path $stage $f.path) $local
        }
        Set-Content -Path (Join-Path $prev 'version.txt') -Value $have -Encoding ASCII
    }
    Remove-Item -Recurse -Force $stage
    Set-Content -Path $versionPath -Value $m.version -Encoding ASCII
    Write-Host "Updated to $($m.version)." -ForegroundColor Green
    foreach ($h in @($m.history)) {
        if ($h.version -eq $have) { break }
        Write-Host "  $($h.version): $($h.notes)" -ForegroundColor Green
    }
}

# Back to the version before the last update, and that update is not taken again.
function Undo-Update($s) {
    $prev = Join-Path $here 'previous'
    if (-not (Test-Path $prev)) { throw 'There is no earlier version kept to go back to.' }
    if (Get-Process -Name 'benilla-vr' -ErrorAction SilentlyContinue) { throw 'Vanilla VR is still running: close it first.' }
    $bad = Get-Version
    $back = ''
    $kept = Join-Path $prev 'version.txt'
    if (Test-Path $kept) { $back = "$(Get-Content $kept -TotalCount 1)".Trim() }
    foreach ($f in Get-ChildItem -Path $prev -File | Where-Object { $_.Name -ne 'version.txt' }) {
        Move-Item -Force $f.FullName (Join-Path $here $f.Name)
    }
    Remove-Item -Recurse -Force $prev
    Set-Content -Path $versionPath -Value $back -Encoding ASCII
    if ($bad) { $s['SKIP'] = $bad; Save-Settings $s }
    Write-Host "Back to $(if ($back) { $back } else { 'the version you had' }). $bad will not be installed again; the next one will." -ForegroundColor Green
}

# Your last sessions' game logs to your friend, gzipped, each once, so a crash or a bug can be
# looked at. Logs of a game still running wait for the next time.
function Send-Logs([string]$server, [string]$who) {
    $logs = Join-Path $here 'logs'
    if (-not (Test-Path $logs)) { return }
    if (Get-Process -Name 'benilla-vr' -ErrorAction SilentlyContinue) { return }
    $sentPath = Join-Path $logs 'sent.txt'
    $sent = if (Test-Path $sentPath) { @(Get-Content $sentPath) } else { @() }
    $todo = Get-ChildItem -Path $logs -Filter 'game-*.err.log' -ErrorAction SilentlyContinue |
        Where-Object { $sent -notcontains $_.Name } | Sort-Object LastWriteTime -Descending | Select-Object -First 3
    $n = 0
    foreach ($f in $todo) {
        if ($f.Length -gt 0) {
            $gz = Join-Path ([IO.Path]::GetTempPath()) "$($f.Name).gz"
            try {
                Compress-Gzip $f.FullName $gz
                Invoke-WebRequest -Uri "http://${server}:$updatesPort/logs/$who/$($f.Name).gz" -Method Put -InFile $gz `
                    -ContentType 'application/gzip' -TimeoutSec 60 -UseBasicParsing | Out-Null
                $n++
            } catch {
                return
            } finally {
                Remove-Item $gz -ErrorAction SilentlyContinue
            }
        }
        Add-Content -Path $sentPath -Value $f.Name
    }
    if ($n -gt 0) { Write-Host "Sent your last $n game log(s) to your friend." -ForegroundColor DarkGray }
}

try {
    $s = Read-Settings
    if ($Rollback) { Undo-Update $s; return }
    for ($try = 0; -not (Test-GameDir $s['GAME']); $try++) {
        if ($try -ge 5) { throw 'No 1.12.1 game folder found.' }
        if ($s['GAME']) { Write-Host "No 1.12.1 game files in $($s['GAME']) (looked for Data\dbc.MPQ and Data\patch.MPQ)." -ForegroundColor Yellow }
        $s['GAME'] = "$(Read-Host 'Where is your World of Warcraft 1.12.1 folder (the one with WoW.exe and a Data folder)?')".Trim().Trim('"')
    }
    if (-not $s['SERVER']) {
        $given = Join-Path $here 'server.txt'
        $suggest = if (Test-Path $given) { "$(Get-Content $given -TotalCount 1)".Trim() } else { '' }
        $prompt = "Your friend's server address (their Tailscale address, like 100.101.102.103)"
        if ($suggest) { $prompt += " [Enter for $suggest]" }
        $a = (Read-Host $prompt).Trim()
        $s['SERVER'] = if ($a) { $a } else { $suggest }
        if (-not $s['SERVER']) { throw 'No server address: ask your friend for it.' }
    }
    # The name your logs reach your friend under: your Windows name, letters and digits only.
    if (-not $s['NAME']) { $s['NAME'] = ($env:USERNAME -replace '[^A-Za-z0-9._-]', '') }
    if (-not $s['NAME']) { $s['NAME'] = 'friend' }
    Save-Settings $s
    $server = $s['SERVER']

    if (-not (Test-Tcp $server 3724)) {
        Write-Host "Can't reach the server at ${server}. Check that Tailscale is connected (its tray icon), that you accepted your friend's share link, and that their server is running." -ForegroundColor Yellow
        if (-not $DryRun) {
            $a = Read-Host 'Start anyway? [y/N]'
            if ($a -notmatch '^\s*(y|yes)\s*$') { return }
        }
    } else {
        Write-Host "The server at $server answers." -ForegroundColor Green
        try {
            Update-Kit $server $s
        } catch {
            Write-Host "The update failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        if ($s['SEND_LOGS'] -ne 'no') {
            try { Send-Logs $server ($s['NAME'] -replace '[^A-Za-z0-9._-]', '') } catch { }
        }
    }

    $logs = Join-Path $here 'logs'
    New-Item -ItemType Directory -Force -Path $logs | Out-Null
    $env:WOW_DATA = Join-Path $s['GAME'] 'Data'
    $env:WOW_HOST = "${server}:3724"
    # Your arms and hands to the other VR players near you, through your friend's relay.
    $env:WOWVR_RELAY = "${server}:3725"
    # First-time tips are shown once ever: the ones seen are listed here.
    $env:WOWVR_TIPS_FILE = Join-Path $logs 'tips-seen.txt'
    # Tuning: vr-settings.txt beside this file; the book's VR page writes back to it.
    $vrSettings = Join-Path $here 'vr-settings.txt'
    $env:WOWVR_SETTINGS_FILE = $vrSettings
    if (Test-Path $vrSettings) {
        foreach ($line in Get-Content $vrSettings) {
            if ($line -match '^\s*(WOWVR_[A-Z_]+)\s*=\s*(.*?)\s*$') { Set-Item -Path "env:$($Matches[1])" -Value $Matches[2] }
        }
    }
    $exe = Join-Path $here 'benilla-vr.exe'
    if ($DryRun) {
        foreach ($n in 'WOW_DATA', 'WOW_HOST', 'WOWVR_RELAY') { Write-Host "$n=$((Get-Item "env:$n").Value)" }
        Write-Host "version $(Get-Version); would start $exe in $here"
        return
    }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    Get-ChildItem -Path $logs -Filter 'game-*.log' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -Skip 10 | Remove-Item -ErrorAction SilentlyContinue
    Start-Process -FilePath $exe -WorkingDirectory $here `
        -RedirectStandardOutput (Join-Path $logs "game-$stamp.out.log") `
        -RedirectStandardError (Join-Path $logs "game-$stamp.err.log") | Out-Null
    Write-Host 'Vanilla VR is starting. Log in with the account and password your friend gave you.' -ForegroundColor Green
    Write-Host 'Controls: https://claude.ai/artifact/JvCN7hMaJAwirPu6VZmg2J' -ForegroundColor Green
}
catch {
    Write-Host "PLAY FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

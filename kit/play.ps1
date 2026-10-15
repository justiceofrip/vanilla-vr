# Plays Vanilla VR on a friend's server over Tailscale, or on a realm of your own on this PC (solo,
# solo.ps1). The first run asks where your 1.12.1 game is and for the server's address, and keeps
# both in settings.txt beside this file (edit it to change them; MODE=solo plays on your own). Start
# SteamVR (or your headset's PC link) first; without it the game runs flat.
# Each run first brings this folder up to the newest version (your friend's, only what changed,
# every file checked, the old copies kept for ROLLBACK.cmd; with no friend's server, the project's
# own on GitHub) and sends your last game logs, motion recordings and feedback back to your friend,
# so bugs can be fixed and the moves tuned (SEND_LOGS=no in settings.txt stops the logs).
# -DryRun checks everything and prints what it would start, without starting it. -Rollback goes
# back to the version before the last update (ROLLBACK.cmd). -Library only defines the functions,
# for the launcher's window (launcher.ps1), which does the same through them.
param([switch]$DryRun, [switch]$Rollback, [switch]$Library)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
# GitHub takes nothing older than TLS 1.2.
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$here = $PSScriptRoot
$settingsPath = Join-Path $here 'settings.txt'
$versionPath = Join-Path $here 'version.txt'
# The last update's notes, newest first, kept for the launcher's news when the channel is quiet.
$newsPath = Join-Path $here 'news.json'
# Your friend's update channel, beside their server.
$updatesPort = 3726
# The project on GitHub: its releases are the update channel for anyone with no friend's server,
# and its issues take playtest reports.
$githubRepo = 'justiceofrip/vanilla-vr'
$feedbackDir = Join-Path $here 'feedback'

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
    $lines = @('# Vanilla VR: your game folder, MODE=solo to play on your own (else your friend''s server, its',
        '# Tailscale address after SERVER=), the name your logs go to your friend under, SEND_LOGS=no to',
        '# keep your logs to yourself, FEEDBACK=no to not be asked how it went after you play.')
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

# The name your logs and feedback reach your friend under: letters, digits, '.', '_' and '-'.
function Get-PlayerName($s) {
    $n = "$($s['NAME'])" -replace '[^A-Za-z0-9._-]', ''
    if (-not $n) { $n = $env:USERNAME -replace '[^A-Za-z0-9._-]', '' }
    if (-not $n) { $n = 'friend' }
    return $n
}

# A line for the player: the console's, or the launcher's window when it set
# $global:VanillaReport (a script block taking the line and how far along, 0 to 1, or -1).
function Say([string]$text, [string]$color = 'Gray', [double]$fraction = -1) {
    if ($global:VanillaReport) { & $global:VanillaReport $text $fraction }
    else { Write-Host $text -ForegroundColor $color }
}

# A download to $out, its progress told as a share of the whole update ($before of $total bytes
# already fetched; a $total of 0 takes the file's own size), at most ten times a second. With
# $global:VanillaShare (@{ From; To }) the share is told within that part of the bar.
function Save-Url([string]$url, [string]$out, [long]$before, [long]$total, [string]$label) {
    $req = [Net.HttpWebRequest]::Create($url)
    $req.Timeout = 30000
    $req.ReadWriteTimeout = 60000
    $req.UserAgent = 'vanilla-vr'
    $resp = $req.GetResponse()
    try {
        if ($total -le 0) { $total = [long]$resp.ContentLength }
        $in = $resp.GetResponseStream()
        $file = [IO.File]::Create($out)
        try {
            $buf = New-Object byte[] 65536
            $got = 0L
            $last = [DateTime]::MinValue
            while (($n = $in.Read($buf, 0, $buf.Length)) -gt 0) {
                $file.Write($buf, 0, $n)
                $got += $n
                if ($global:VanillaReport -and $total -gt 0 -and ([DateTime]::UtcNow - $last).TotalMilliseconds -ge 100) {
                    $last = [DateTime]::UtcNow
                    $share = [math]::Min(1.0, ($before + $got) / $total)
                    $shown = $share
                    if ($global:VanillaShare) { $shown = $global:VanillaShare.From + ($global:VanillaShare.To - $global:VanillaShare.From) * $share }
                    & $global:VanillaReport ("Downloading {0}... {1:P0}" -f $label, $share) $shown
                }
            }
        } finally { $file.Dispose(); $in.Dispose() }
    } finally { $resp.Close() }
}

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

# Brings this folder to the newest version: your friend's ($server's update channel), or with
# -GitHub the project's latest release. Only the files that changed, each one checked against its
# SHA-256 before anything is replaced, the old copies kept in previous\ for ROLLBACK.cmd. A version
# you rolled back from is not taken again (a newer one is). No answer leaves everything as it is.
function Update-Kit([string]$server, $s, [switch]$GitHub) {
    if ($GitHub) {
        $from = 'GitHub'
        $manifestUrl = "https://github.com/$githubRepo/releases/latest/download/manifest.json"
    } else {
        $from = 'your friend''s update channel'
        $manifestUrl = "http://${server}:$updatesPort/manifest.json"
    }
    $result = [pscustomobject]@{ Status = 'quiet'; Version = (Get-Version); History = @(); Changed = @() }
    try {
        $r = Invoke-WebRequest -Uri $manifestUrl -TimeoutSec 15 -UseBasicParsing -Headers @{ 'Cache-Control' = 'no-cache' }
    } catch {
        Say "No update check ($from did not answer): playing the version you have." 'Yellow'
        return $result
    }
    $json = if ($r.Content -is [byte[]]) { [Text.Encoding]::UTF8.GetString($r.Content) } else { "$($r.Content)" }
    $m = $null
    try { $m = $json.TrimStart([char]0xFEFF) | ConvertFrom-Json } catch { }
    if (-not $m -or -not $m.version -or @($m.files).Count -eq 0) {
        Say "The update from $from could not be read: playing the version you have." 'Yellow'
        $result.Status = 'unreadable'
        return $result
    }
    # The notes, for the launcher's news, kept for the next time the channel is quiet.
    $result.History = @($m.history)
    try {
        [IO.File]::WriteAllText($newsPath, (ConvertTo-Json -InputObject @($m.history) -Depth 3), (New-Object Text.UTF8Encoding $false))
    } catch { }
    $have = Get-Version
    if ($m.version -eq $have) {
        Say "Up to date ($have)." 'Green' 1
        $result.Status = 'current'
        return $result
    }
    # GitHub's latest release can be older than what your friend gave you: never step back.
    if ($GitHub -and $have -and ([version]("$($m.version)" -replace '[^0-9.]', '') -le [version]($have -replace '[^0-9.]', ''))) {
        Say "Up to date ($have)." 'Green' 1
        $result.Status = 'current'
        return $result
    }
    if ($s['SKIP'] -and $m.version -eq $s['SKIP']) {
        Say "Version $($m.version) is the one you went back from: staying on $have until a newer one." 'Yellow'
        $result.Status = 'skipped'
        return $result
    }
    if (Get-Process -Name 'benilla-vr' -ErrorAction SilentlyContinue) {
        Say 'Vanilla VR is still running: close it, then PLAY again to update.' 'Yellow'
        $result.Status = 'running'
        return $result
    }
    Say "Updating to $($m.version)..." 'Cyan' 0
    $stage = Join-Path $here 'update'
    if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
    New-Item -ItemType Directory -Force -Path $stage | Out-Null
    $changed = @()
    $todo = @()
    foreach ($f in $m.files) {
        if ("$($f.path)" -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$' -or "$($f.url)" -notmatch '^[A-Za-z0-9._/-]+$') {
            throw "the update names a file it should not ($($f.path)); nothing was changed"
        }
        $local = Join-Path $here $f.path
        if ((Test-Path $local) -and (Get-Sha256 $local) -eq $f.sha256) { continue }
        $todo += $f
    }
    $total = [long](($todo | Measure-Object -Property gz_size -Sum).Sum)
    $before = 0L
    foreach ($f in $todo) {
        Say ("  {0} ({1:N1} MB)" -f $f.path, ($f.gz_size / 1MB))
        $gz = Join-Path $stage "$($f.path).gz"
        # A release's files sit side by side under its tag.
        $url = if ($GitHub) { "https://github.com/$githubRepo/releases/download/v$($m.version)/$(("$($f.url)" -split '/')[-1])" } else { "http://${server}:$updatesPort/$($f.url)" }
        Save-Url $url $gz $before $total $f.path
        $before += [long]$f.gz_size
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
    Say "Updated to $($m.version)." 'Green' 1
    foreach ($h in @($m.history)) {
        if ($h.version -eq $have) { break }
        Say "  $($h.version): $($h.notes)" 'Green'
    }
    $result.Status = 'updated'
    $result.Version = $m.version
    $result.Changed = @($changed | ForEach-Object { "$($_.path)" })
    return $result
}

# The notes kept from the last update check, newest first (none before the first).
function Read-News {
    if (-not (Test-Path $newsPath)) { return @() }
    try {
        $text = [IO.File]::ReadAllText($newsPath)
        return @($text.TrimStart([char]0xFEFF) | ConvertFrom-Json)
    } catch { return @() }
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
    Say "Back to $(if ($back) { $back } else { 'the version you had' }). $bad will not be installed again; the next one will." 'Green'
}

# Sends files to your friend's PC, each gzipped, each once: your feedback first (always, you
# pressed Send), then with $logs your last sessions' game logs, journals, motion recordings and
# session reports, so a crash or a bug can be looked at and the moves tuned. Files of a game
# still running wait for the next time.
function Send-Logs([string]$server, [string]$who, [bool]$logs = $true) {
    if (Get-Process -Name 'benilla-vr' -ErrorAction SilentlyContinue) { return }
    $todo = @()
    foreach ($place in @(@{ Dir = $feedbackDir; Filters = @('feedback-*.json') },
            @{ Dir = (Join-Path $here 'logs'); Filters = $(if ($logs) { @('session-*.json', 'game-*.err.log', 'journal-*.txt', 'motion-*.csv') } else { @() }) })) {
        if (-not (Test-Path $place.Dir)) { continue }
        $sentPath = Join-Path $place.Dir 'sent.txt'
        $sent = if (Test-Path $sentPath) { @(Get-Content $sentPath) } else { @() }
        foreach ($filter in $place.Filters) {
            $todo += Get-ChildItem -Path $place.Dir -Filter $filter -ErrorAction SilentlyContinue |
                Where-Object { $sent -notcontains $_.Name } | Sort-Object LastWriteTime -Descending | Select-Object -First 3 |
                ForEach-Object { @{ File = $_; Sent = $sentPath } }
        }
    }
    $n = 0
    foreach ($t in $todo) {
        $f = $t.File
        if ($f.Length -gt 0) {
            $gz = Join-Path ([IO.Path]::GetTempPath()) "$($f.Name).gz"
            try {
                Compress-Gzip $f.FullName $gz
                # Your friend's PC takes up to 32 MB a file: a longer recording stays here.
                if ((Get-Item $gz).Length -lt 31MB) {
                    Invoke-WebRequest -Uri "http://${server}:$updatesPort/logs/$who/$($f.Name).gz" -Method Put -InFile $gz `
                        -ContentType 'application/gzip' -TimeoutSec 120 -UseBasicParsing | Out-Null
                    $n++
                }
            } catch {
                return
            } finally {
                Remove-Item $gz -ErrorAction SilentlyContinue
            }
        }
        Add-Content -Path $t.Sent -Value $f.Name
    }
    if ($n -gt 0) { Say "Sent $n file(s) to your friend." 'DarkGray' }
}

# Your realm's login details when you play solo: its port, and the account the launcher logs you
# in with.
function Get-SoloLogin {
    $st = Read-Solo
    if (-not $st.Ports -or -not $st.User) { throw 'Your realm is not built yet.' }
    return @{ Realm = $st.Ports.Realm; User = $st.User; Pass = $st.Pass }
}

# Starts the game against your friend's server, or your own realm with MODE=solo, with the game
# folder in $s: its logs, the session's journal (how much it asked of your arms, the frame times)
# and its motion recording in logs\, the VR tuning from vr-settings.txt. The process (its Stamp
# names the session's files), or with -DryRun what it would start.
function Start-Game($s, [switch]$DryRun) {
    $server = $s['SERVER']
    $logs = Join-Path $here 'logs'
    New-Item -ItemType Directory -Force -Path $logs | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $env:WOW_DATA = Join-Path $s['GAME'] 'Data'
    if ($s['MODE'] -eq 'solo') {
        $solo = Get-SoloLogin
        $env:WOW_HOST = "127.0.0.1:$($solo.Realm)"
        # Your realm's own account, so the game logs you straight in.
        $env:WOW_USER = $solo.User
        $env:WOW_PASS = $solo.Pass
        $env:WOW_ALLOW_ACCOUNT = '1'
        Remove-Item env:WOWVR_RELAY -ErrorAction SilentlyContinue
    } else {
        $env:WOW_HOST = "${server}:3724"
        foreach ($n in 'WOW_USER', 'WOW_PASS', 'WOW_ALLOW_ACCOUNT') { Remove-Item "env:$n" -ErrorAction SilentlyContinue }
        # Your arms and hands to the other VR players near you, and your voice, through your friend's relay.
        $env:WOWVR_RELAY = "${server}:3725"
    }
    # First-time tips are shown once ever: the ones seen are listed here.
    $env:WOWVR_TIPS_FILE = Join-Path $logs 'tips-seen.txt'
    # The session's load on your arms and its frame times, and every move that fired (a recording
    # of head, hands and buttons, about 20 MB an hour): what tunes the gestures. Clicking both
    # sticks together marks a moment that felt wrong. WOWVR_MOTION_LOG= in vr-settings.txt stops it.
    $env:WOWVR_JOURNAL = Join-Path $logs "journal-$stamp.txt"
    $env:WOWVR_MOTION_LOG = Join-Path $logs "motion-$stamp.csv"
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
        foreach ($n in 'WOW_DATA', 'WOW_HOST', 'WOWVR_RELAY') { Write-Host "$n=$((Get-Item "env:$n" -ErrorAction SilentlyContinue).Value)" }
        Write-Host "version $(Get-Version); would start $exe in $here"
        return $null
    }
    # Only the last sessions' files stay: logs and journals for 10, recordings for 6.
    foreach ($keep in @(@('game-*.log', 20), @('journal-*.txt', 10), @('session-*.json', 10), @('motion-*.csv', 6))) {
        Get-ChildItem -Path $logs -Filter $keep[0] -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -Skip $keep[1] | Remove-Item -ErrorAction SilentlyContinue
    }
    $p = Start-Process -FilePath $exe -WorkingDirectory $here -PassThru `
        -RedirectStandardOutput (Join-Path $logs "game-$stamp.out.log") `
        -RedirectStandardError (Join-Path $logs "game-$stamp.err.log")
    $null = $p.Handle
    $p | Add-Member -NotePropertyName Stamp -NotePropertyValue $stamp
    return $p
}

# ---------------------------------------------------------------- feedback

# What a session was like, from its own files: your PC and headset, how long you played and as
# whom, what it asked of your arms and the frame times (the journal), every move that fired and
# the moments you marked (the motion recording), the game's errors, your VR settings. Nothing
# personal: no account, no address. $session (@{ Stamp; Started; Ended; ExitCode; Mode; SteamVR })
# or $null for the newest session in logs\.
function New-SessionReport($session) {
    $logs = Join-Path $here 'logs'
    if (-not $session) {
        $last = Get-ChildItem -Path $logs -Filter 'game-*.err.log' -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        $session = @{ Stamp = $(if ($last) { $last.Name -replace '^game-(.*)\.err\.log$', '$1' } else { '' }) }
    }
    $stamp = $session.Stamp
    $s = Read-Settings
    $r = [ordered]@{
        stamp   = $stamp
        kit     = (Get-Version)
        mode    = $(if ($s['MODE'] -eq 'solo') { 'solo' } else { 'friend' })
        session = [ordered]@{}
        pc      = [ordered]@{}
        vr      = [ordered]@{}
        play    = [ordered]@{}
        moves   = [ordered]@{}
        game    = [ordered]@{}
        settings = @()
    }
    if ($session.Started) {
        $r.session.started = $session.Started.ToString('s')
        $r.session.minutes = [math]::Round(($session.Ended - $session.Started).TotalMinutes, 1)
        $r.session.exit_code = $session.ExitCode
        $r.session.steamvr_at_start = [bool]$session.SteamVR
    }
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $r.pc.os = "$($os.Caption) $($os.Version)".Trim()
        $r.pc.cpu = "$((Get-CimInstance Win32_Processor | Select-Object -First 1).Name)".Trim()
        # The real graphics cards, not the virtual displays a headset's streaming app adds.
        $r.pc.gpu = @(Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch 'Virtual|Basic Display|Remote|Parsec|Mirror' } |
                ForEach-Object { "$($_.Name) ($($_.DriverVersion))" })
        $r.pc.ram_gb = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
    } catch { }
    # The game's log: the headset it ran on, and its errors.
    $log = Join-Path $logs "game-$stamp.err.log"
    if ($stamp -and (Test-Path $log)) {
        $errors = @()
        $warn = 0
        foreach ($line in [IO.File]::ReadLines($log)) {
            $plain = $line -replace '\x1b\[[0-9;]*m', ''
            if ($plain -match 'Loaded OpenXR runtime: (.*)$') { $r.vr.runtime = $Matches[1].Trim() }
            elseif ($plain -match 'Using system: (.*)$') { $r.vr.system = $Matches[1].Trim() }
            elseif ($plain -match 'XrCamera resolution: (.*)$') { $r.vr.resolution = $Matches[1].Trim() }
            elseif ($plain -match '^\S+\s+ERROR\s+(.*)$') { $errors += ($Matches[1] -replace '\d+', '#') }
            elseif ($plain -match '^\S+\s+WARN\s') { $warn++ }
            elseif ($plain -match 'panicked at') { $errors += "PANIC $($plain.Trim())" }
        }
        $r.game.errors = $errors.Count
        $r.game.warnings = $warn
        $r.game.top_errors = @($errors | Group-Object | Sort-Object Count -Descending | Select-Object -First 5 |
                ForEach-Object { "$($_.Count)x $($_.Name)".Substring(0, [math]::Min(220, "$($_.Count)x $($_.Name)".Length)) })
    }
    # The journal's last line: the whole session.
    $journal = Join-Path $logs "journal-$stamp.txt"
    if ($stamp -and (Test-Path $journal)) {
        $line = Get-Content $journal -Tail 1
        $r.play.journal = "$line" -replace '^unix \d+: ', ''
        if ($line -match '([\d.]+) min in the world') { $r.play.minutes_in_world = [double]$Matches[1] }
        if ($line -match 'hands up (\d+)%') { $r.play.hands_up_pct = [int]$Matches[1] }
        if ($line -match '([\d.]+) arm actions/min') { $r.play.arm_actions_per_min = [double]$Matches[1] }
        if ($line -match 'p95 (\d+) ms') { $r.play.frame_p95_ms = [int]$Matches[1] }
        if ($line -match '([\d.]+)% dropped') { $r.play.dropped_pct = [double]$Matches[1] }
        if ($line -match '; level (\d+) (.+)$') { $r.play.character = "level $($Matches[1]) $($Matches[2])" }
    }
    # The motion recording: each move that fired, and the moments marked as feeling wrong.
    $motion = Join-Path $logs "motion-$stamp.csv"
    if ($stamp -and (Test-Path $motion)) {
        $counts = @{}
        $marks = @()
        $first = $null
        foreach ($line in [IO.File]::ReadLines($motion)) {
            if ($line.StartsWith('t,')) { continue }
            $cols = $line.Split(',')
            if ($cols.Count -lt 35) { continue }
            if ($null -eq $first) { $first = [double]$cols[0] }
            if (-not $cols[34]) { continue }
            foreach ($e in $cols[34].Split(';')) {
                if (-not $e) { continue }
                if ($e -eq 'mark') { $marks += [math]::Round(([double]$cols[0] - $first) / 60, 1) }
                else { $counts[$e] = 1 + [int]$counts[$e] }
            }
        }
        foreach ($k in ($counts.Keys | Sort-Object { -$counts[$_] })) { $r.moves[$k] = $counts[$k] }
        $r.game.marked_minutes = @($marks)
        $r.game.motion_file = "motion-$stamp.csv"
    }
    $vr = Join-Path $here 'vr-settings.txt'
    if (Test-Path $vr) {
        $r.settings = @(Get-Content $vr | Where-Object { $_ -match '^\s*WOWVR_[A-Z_]+\s*=' } | ForEach-Object { $_.Trim() })
    }
    if ($stamp) {
        New-Item -ItemType Directory -Force -Path $logs | Out-Null
        [IO.File]::WriteAllText((Join-Path $logs "session-$stamp.json"), ($r | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding $false))
    }
    return $r
}

# Your answers with the session's report, kept in feedback\ until your friend's PC has them.
# $answers: fun, works, body (1 to 5, or $null), great, broke (text), named (put your name on it),
# posted (you posted it on GitHub yourself, so your friend's PC does not post it again).
function Save-Feedback($report, $answers) {
    New-Item -ItemType Directory -Force -Path $feedbackDir | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $fb = [ordered]@{
        feedback = [ordered]@{
            fun    = $answers.fun
            works  = $answers.works
            body   = $answers.body
            great  = "$($answers.great)".Trim()
            broke  = "$($answers.broke)".Trim()
            from   = $(if ($answers.named) { Get-PlayerName (Read-Settings) } else { '' })
            posted = [bool]$answers.posted
        }
        report   = $report
    }
    $path = Join-Path $feedbackDir "feedback-$stamp.json"
    [IO.File]::WriteAllText($path, ($fb | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding $false))
    return $fb
}

# The session in a few plain lines, for a playtest report.
function Format-Report($report) {
    $lines = @()
    if ($report.play.character) { $lines += "Played: $($report.play.character)" }
    if ($report.session.minutes) { $lines += "Session: $($report.session.minutes) min ($($report.mode)), exit code $($report.session.exit_code)" }
    if ($report.play.journal) { $lines += "Journal: $($report.play.journal)" }
    if (@($report.moves.Keys).Count -gt 0) { $lines += "Moves: " + (($report.moves.Keys | ForEach-Object { "$_ $($report.moves[$_])" }) -join ', ') }
    if (@($report.game.marked_minutes).Count -gt 0) { $lines += "Marked as wrong at minute: " + (@($report.game.marked_minutes) -join ', ') }
    if ($null -ne $report.game.errors) { $lines += "Game log: $($report.game.errors) errors" }
    $lines += "Kit: $($report.kit)"
    if ($report.vr.system) { $lines += "Headset: $($report.vr.system); $($report.vr.runtime)" }
    if ($report.pc.cpu) { $lines += "PC: $($report.pc.cpu); $(@($report.pc.gpu) -join ', '); $($report.pc.ram_gb) GB; $($report.pc.os)" }
    return $lines
}

# The project's playtest form on GitHub, filled in with your answers and the session: you post
# it yourself, signed in to GitHub.
function Get-FeedbackUrl($fb) {
    $f = $fb.feedback
    $rate = { param($v) if ($v) { "$v/5" } else { '-' } }
    $q = [ordered]@{
        template = 'playtest.yml'
        title    = "Playtest: fun $(& $rate $f.fun), works $(& $rate $f.works), body $(& $rate $f.body)"
        ratings  = "Fun $(& $rate $f.fun), it worked $(& $rate $f.works), your body afterwards $(& $rate $f.body)"
        great    = $f.great
        broke    = $f.broke
        data     = ((Format-Report $fb.report) -join "`n")
    }
    if ($fb.report.play.character) { $q.class = $fb.report.play.character }
    $parts = foreach ($k in $q.Keys) { "$k=" + [Uri]::EscapeDataString("$($q[$k])") }
    $url = "https://github.com/$githubRepo/issues/new?" + ($parts -join '&')
    # Browsers and GitHub take about 8000 characters of address.
    if ($url.Length -gt 7500) { $url = $url.Substring(0, 7500) }
    return $url
}

# Your own realm (MODE=solo): solo.ps1.
$soloScript = Join-Path $here 'solo.ps1'
if (Test-Path $soloScript) { . $soloScript }

# The launcher's window (launcher.ps1) takes the functions only.
if ($Library) { return }

try {
    $s = Read-Settings
    if ($Rollback) { Undo-Update $s; return }
    for ($try = 0; -not (Test-GameDir $s['GAME']); $try++) {
        if ($try -ge 5) { throw 'No 1.12.1 game folder found.' }
        if ($s['GAME']) { Write-Host "No 1.12.1 game files in $($s['GAME']) (looked for Data\dbc.MPQ and Data\patch.MPQ)." -ForegroundColor Yellow }
        $s['GAME'] = "$(Read-Host 'Where is your World of Warcraft 1.12.1 folder (the one with WoW.exe and a Data folder)?')".Trim().Trim('"')
    }
    $solo = $s['MODE'] -eq 'solo'
    if (-not $s['SERVER'] -and -not $solo) {
        $given = Join-Path $here 'server.txt'
        $suggest = if (Test-Path $given) { "$(Get-Content $given -TotalCount 1)".Trim() } else { '' }
        $prompt = "Your friend's server address (their Tailscale address, like 100.101.102.103), or solo to play on your own"
        if ($suggest) { $prompt += " [Enter for $suggest]" }
        $a = (Read-Host $prompt).Trim()
        if ($a -eq 'solo') { $s['MODE'] = 'solo'; $solo = $true }
        else {
            $s['SERVER'] = if ($a) { $a } else { $suggest }
            if (-not $s['SERVER']) { throw 'No server address: ask your friend for it.' }
        }
    }
    $s['NAME'] = Get-PlayerName $s
    Save-Settings $s
    $server = $s['SERVER']

    $hostUp = $server -and (Test-Tcp $server $(if ($solo) { $updatesPort } else { 3724 }))
    if ($hostUp) {
        Write-Host "The server at $server answers." -ForegroundColor Green
        try { Update-Kit $server $s | Out-Null } catch { Write-Host "The update failed: $($_.Exception.Message)" -ForegroundColor Yellow }
        try { Send-Logs $server $s['NAME'] ($s['SEND_LOGS'] -ne 'no') } catch { }
    } elseif ($solo) {
        try { Update-Kit '' $s -GitHub | Out-Null } catch { Write-Host "The update failed: $($_.Exception.Message)" -ForegroundColor Yellow }
    } else {
        Write-Host "Can't reach the server at ${server}. Check that Tailscale is connected (its tray icon), that you accepted your friend's share link, and that their server is running." -ForegroundColor Yellow
        if (-not $DryRun) {
            $a = Read-Host 'Start anyway? [y/N]'
            if ($a -notmatch '^\s*(y|yes)\s*$') { return }
        }
    }

    if ($DryRun) { Start-Game $s -DryRun | Out-Null; return }
    if ($solo) {
        if (-not (Test-SoloBuilt)) {
            Write-Host 'Building your realm: about 130 MB of downloads, then your game''s maps (an hour or so, once).' -ForegroundColor Cyan
            Install-Solo $s
        }
        Start-Solo
    }
    $game = Start-Game $s
    Write-Host 'Vanilla VR is starting.' -ForegroundColor Green
    Write-Host 'Controls: https://claude.ai/artifact/JvCN7hMaJAwirPu6VZmg2J' -ForegroundColor Green
    if ($solo) {
        Write-Host 'Keep this window open: when the game closes, it puts your realm to sleep.' -ForegroundColor Green
        $game.WaitForExit()
        Stop-Solo
    }
}
catch {
    Write-Host "PLAY FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

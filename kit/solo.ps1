# The solo realm: a private server of your own on this PC, the same build and house rules your
# friend runs (the vMaNGOS server, its world database and a MariaDB database server), so you can
# play Vanilla VR alone with no friend's server needed. Install-Solo builds it once: about 130 MB
# of downloads, then your game's maps read from your own 1.12.1 folder (an hour or so of your PC's
# time, 3.5 GB in solo\). Start-Solo wakes it for a session and Stop-Solo puts it to sleep. Every
# part listens on this PC only (127.0.0.1), on ports away from the usual ones.
# Dot-sourced by play.ps1 (Say, Save-Url, Get-Sha256 and Test-GameDir are its).

$soloDir = Join-Path $here 'solo'
$soloStatePath = Join-Path $soloDir 'solo.json'

# What the realm is built from: the versions your friend's server runs, each checked by its
# SHA-256. vMaNGOS publishes one rolling build; once it has moved on from this one, the build it
# offers then is taken instead, with its own database, unchecked.
$soloPins = @{
    MariaZip = 'mariadb-11.4.13-winx64.zip'
    MariaUrl = 'https://archive.mariadb.org/mariadb-11.4.13/winx64-packages/mariadb-11.4.13-winx64.zip'
    MariaSha = 'd62986d433eeebfde218560b276103831604a61e929e87f1a17f5aebd80257e2'
    VmZip    = 'dev-windows-amd64-53d24d5.zip'
    VmSha    = '068bc79dc9e08fd62351acb3b798b26c6c7c3c29e5b81ad056f10f9f75cd9e34'
    VmCommit = '53d24d5c748bef5e0cde7b1155bcb3d979af614c'
    DbZip    = 'db-4641790.zip'
    DbSha    = '9e178f1d70363e92a7b8c259000102dc9739333d79ca00c99ea32dd1fb43e904'
}
# The first ports tried: database, login, world, and the world server's admin line.
$soloPortsFirst = [ordered]@{ Db = 13306; Realm = 13724; World = 18085; Ra = 13443 }
# What a finished build has done, in order; solo.json keeps the steps done, so a build that
# stopped picks up where it was.
$soloSteps = @('database', 'server', 'import', 'account', 'configs', 'maps', 'vmaps', 'mmaps')
# The maps with pathfinding, as on your friend's server: Eastern Kingdoms, Kalimdor, the Deadmines.
$soloPathMaps = @(0, 1, 36)
# What a full build holds, for its progress: map files, line-of-sight files, pathfinding tiles.
$soloExpect = @{ Maps = 2429; Vmaps = 6082; Tiles = 1202 }

function Get-SoloPath([string]$part) { return Join-Path $soloDir $part }

function Read-Solo {
    if (Test-Path $soloStatePath) {
        try { return [IO.File]::ReadAllText($soloStatePath) | ConvertFrom-Json } catch { }
    }
    return [pscustomobject]@{ Done = @() }
}

function Save-Solo($st) {
    New-Item -ItemType Directory -Force -Path $soloDir | Out-Null
    [IO.File]::WriteAllText($soloStatePath, ($st | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding $false))
}

function Set-SoloValue($st, [string]$name, $value) {
    $st | Add-Member -NotePropertyName $name -NotePropertyValue $value -Force
}

function Test-SoloStep($st, [string]$step) { return @($st.Done) -contains $step }

function Complete-SoloStep($st, [string]$step) {
    Set-SoloValue $st 'Done' (@(@($st.Done) | Where-Object { $_ -ne $step }) + $step)
    Save-Solo $st
}

function Test-SoloBuilt {
    $st = Read-Solo
    foreach ($step in $soloSteps) { if (-not (Test-SoloStep $st $step)) { return $false } }
    return $true
}

function Test-LocalPort([int]$port) {
    $c = New-Object Net.Sockets.TcpClient
    try { $c.Connect('127.0.0.1', $port); return $true } catch { return $false } finally { $c.Close() }
}

# Random text from an unambiguous alphabet: the realm's own passwords, never shown or sent.
function New-SoloSecret([int]$n) {
    $chars = [char[]]'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789'
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    $bytes = New-Object byte[] $n
    $rng.GetBytes($bytes)
    return -join ($bytes | ForEach-Object { $chars[$_ % $chars.Length] })
}

# A program of the realm's, hidden, its output to solo\logs; $tick runs every second while it
# works (the progress). Throws unless it ends with one of $ok.
function Invoke-SoloTool([string]$exe, [string[]]$arguments, [string]$workDir, [string]$name, [scriptblock]$tick, [int[]]$ok = @(0)) {
    $logs = Get-SoloPath 'logs'
    New-Item -ItemType Directory -Force -Path $logs | Out-Null
    $quoted = $arguments | ForEach-Object { if ($_ -match '\s') { '"' + $_ + '"' } else { $_ } }
    $p = Start-Process -FilePath $exe -ArgumentList $quoted -WorkingDirectory $workDir -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput (Join-Path $logs "$name.out.txt") -RedirectStandardError (Join-Path $logs "$name.err.txt")
    $null = $p.Handle
    while (-not $p.WaitForExit(1000)) { if ($tick) { & $tick } }
    $p.WaitForExit()
    if ($ok -notcontains $p.ExitCode) {
        throw "$name stopped with code $($p.ExitCode) (solo\logs\$name.err.txt says why)"
    }
}

function Get-SoloExe([string]$name) {
    $f = Get-ChildItem -Path (Get-SoloPath 'vmangos') -Recurse -Filter $name -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $f) { throw "$name is missing from solo\vmangos: build the realm again" }
    return $f.FullName
}

function Get-MariaTool([string]$name) {
    $p = Join-Path (Get-SoloPath 'mariadb') "bin\$name"
    if (-not (Test-Path $p)) { throw "$name is missing from solo\mariadb: build the realm again" }
    return $p
}

# SQL as the database's root, on the realm's own database server. -File runs a whole file.
function Invoke-SoloSql($st, [string]$sql, [string]$database = '', [string]$file = '') {
    $a = @('--host=127.0.0.1', "--port=$($st.Ports.Db)", '--user=root', "--password=$($st.RootPassword)",
        '--max_allowed_packet=512M', '--default-character-set=utf8')
    if ($database) { $a += $database }
    if ($file) { $a += @('-e', "source $($file -replace '\\', '/')") } else { $a += @('-e', $sql) }
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $out = & (Get-MariaTool 'mariadb.exe') @a 2>&1 | ForEach-Object { "$_" } |
            Where-Object { $_ -notmatch 'Using a password on the command line' }
        $code = $LASTEXITCODE
    } finally { $ErrorActionPreference = $old }
    if ($code -ne 0) { throw "the realm's database refused it: $($out -join ' ')" }
    return $out
}

function Start-SoloDb($st) {
    if (Test-LocalPort $st.Ports.Db) { return }
    $ini = Join-Path (Get-SoloPath 'db-data') 'my.ini'
    Start-Process -FilePath (Get-MariaTool 'mariadbd.exe') -ArgumentList "--defaults-file=`"$ini`"" -WindowStyle Hidden `
        -RedirectStandardOutput (Join-Path (Get-SoloPath 'logs') 'database.out.txt') `
        -RedirectStandardError (Join-Path (Get-SoloPath 'logs') 'database.err.txt') | Out-Null
    for ($i = 0; $i -lt 90; $i++) {
        if (Test-LocalPort $st.Ports.Db) { return }
        Start-Sleep -Seconds 1
    }
    throw 'the realm''s database did not start (solo\logs\database.err.txt says why)'
}

function Stop-SoloDb($st) {
    if (-not $st.Ports -or -not (Test-LocalPort $st.Ports.Db)) { return }
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & (Get-MariaTool 'mariadb-admin.exe') --host=127.0.0.1 "--port=$($st.Ports.Db)" --user=root "--password=$($st.RootPassword)" shutdown 2>&1 | Out-Null
    } finally { $ErrorActionPreference = $old }
    for ($i = 0; $i -lt 30 -and (Test-LocalPort $st.Ports.Db); $i++) { Start-Sleep -Seconds 1 }
}

# The realm's own processes: only those started from solo\, never a server of your own.
function Get-SoloProcesses {
    Get-Process -Name 'mangosd', 'realmd', 'mariadbd' -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -and $_.Path.StartsWith($soloDir, [StringComparison]::OrdinalIgnoreCase) }
}

function Test-SoloAwake {
    $st = Read-Solo
    return [bool]($st.Ports -and (Test-LocalPort $st.Ports.World) -and (Test-LocalPort $st.Ports.Realm))
}

# One step of the build, as a share of the whole: [from, to].
function Say-Build([string]$text, [double]$from, [double]$to, [double]$share) {
    Say $text 'Cyan' ($from + ($to - $from) * [math]::Max(0.0, [math]::Min(1.0, $share)))
}

# The time left at the rate so far, said plainly.
function Get-TimeLeft([datetime]$since, [double]$share) {
    if ($share -lt 0.03) { return '' }
    $left = ((Get-Date) - $since).TotalMinutes * (1 - $share) / $share
    if ($left -lt 1.5) { return ', about a minute left' }
    return ", about $([math]::Round($left)) min left"
}

# A file of vMaNGOS's own: the pinned build while it is still offered (checked), else the one it
# offers now, from the release tagged $tag, whose asset name is like $like.
function Get-VmAsset([string]$tag, [string]$pinned, [string]$sha, [string]$like) {
    $url = "https://github.com/vmangos/core/releases/download/$tag/$pinned"
    try {
        $req = [Net.HttpWebRequest]::Create($url)
        $req.Method = 'HEAD'
        $req.Timeout = 15000
        $req.GetResponse().Close()
        return @{ Name = $pinned; Url = $url; Sha = $sha }
    } catch { }
    $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/vmangos/core/releases/tags/$tag" -TimeoutSec 30 `
        -Headers @{ 'User-Agent' = 'vanilla-vr'; 'Accept' = 'application/vnd.github+json' }
    $a = @($rel.assets) | Where-Object { $_.name -like $like } | Select-Object -First 1
    if (-not $a) { throw "vMaNGOS offers no $like right now; try again later" }
    return @{ Name = $a.name; Url = $a.browser_download_url; Sha = $null }
}

function Get-SoloDownload($asset, [string]$label, [double]$from, [double]$to) {
    $dl = Get-SoloPath 'downloads'
    New-Item -ItemType Directory -Force -Path $dl | Out-Null
    $out = Join-Path $dl $asset.Name
    if (-not ((Test-Path $out) -and $asset.Sha -and (Get-Sha256 $out) -eq $asset.Sha)) {
        $global:VanillaShare = @{ From = $from; To = $to }
        try { Save-Url $asset.Url "$out.part" 0 0 $label } finally { $global:VanillaShare = $null }
        Move-Item -Force "$out.part" $out
        if ($asset.Sha -and (Get-Sha256 $out) -ne $asset.Sha) {
            Remove-Item $out
            throw "$label arrived damaged; press Play to try again"
        }
    }
    return $out
}

function Expand-SoloZip([string]$zip, [string]$to) {
    if (Test-Path $to) { Remove-Item -Recurse -Force $to }
    $tmp = "$to.unpack"
    if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::ExtractToDirectory($zip, $tmp)
    # A zip holding one folder is that folder.
    $inner = @(Get-ChildItem $tmp)
    if ($inner.Count -eq 1 -and $inner[0].PSIsContainer) {
        Move-Item $inner[0].FullName $to
        Remove-Item -Recurse -Force $tmp
    } else {
        Move-Item $tmp $to
    }
}

function Set-SoloConfKey([string]$text, [string]$key, [string]$value) {
    $pattern = '(?m)^' + [regex]::Escape($key) + '\s*=.*$'
    $line = "$key = $value"
    if ([regex]::IsMatch($text, $pattern)) { return [regex]::Replace($text, $pattern, { param($m) $line }) }
    return $text.TrimEnd() + "`r`n$line`r`n"
}

# SRP6 verifier and salt exactly as vMaNGOS stores them (AccountMgr::CreateAccount):
# x = SHA1(salt_LE || SHA1(UPPER(user) ":" UPPER(pass))) read little-endian, v = 7^x mod N,
# both as big-endian uppercase hex.
function New-SoloSrp6([string]$user, [string]$pass) {
    Add-Type -AssemblyName System.Numerics
    $U = $user.ToUpperInvariant()
    $P = $pass.ToUpperInvariant()
    $sha = [Security.Cryptography.SHA1]::Create()
    $h1 = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes("$U`:$P"))
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    $saltBE = New-Object byte[] 32
    do { $rng.GetBytes($saltBE) } while ($saltBE[0] -eq 0)
    $saltLE = [byte[]]$saltBE.Clone()
    [Array]::Reverse($saltLE)
    $xh = $sha.ComputeHash([byte[]]($saltLE + $h1))
    $x = New-Object Numerics.BigInteger (, [byte[]]($xh + [byte]0))
    $N = [Numerics.BigInteger]::Parse('0894B645E89E1535BBDAD5B8B290650530801B18EBFBF5E8FAB3C82872A3E9BB7', [Globalization.NumberStyles]::AllowHexSpecifier)
    $v = [Numerics.BigInteger]::ModPow([Numerics.BigInteger]7, $x, $N)
    $vLE = $v.ToByteArray()
    $len = $vLE.Length
    while ($len -gt 1 -and $vLE[$len - 1] -eq 0) { $len-- }
    $vBE = [byte[]]$vLE[0..($len - 1)]
    [Array]::Reverse($vBE)
    return @{
        User = $U
        V    = ($vBE | ForEach-Object { $_.ToString('X2') }) -join ''
        S    = ($saltBE | ForEach-Object { $_.ToString('X2') }) -join ''
    }
}

# The house rules your friend plays by (house-rules.sql beside this file, re-runnable), applied
# whenever they change.
function Update-SoloRules($st) {
    $rules = Join-Path $here 'house-rules.sql'
    if (-not (Test-Path $rules)) { return }
    $sha = Get-Sha256 $rules
    if ($st.RulesSha -eq $sha) { return }
    Invoke-SoloSql $st '' 'mangos' $rules | Out-Null
    Set-SoloValue $st 'RulesSha' $sha
    Save-Solo $st
}

function Get-FileCount([string]$dir, [string]$filter = '*') {
    if (-not (Test-Path $dir)) { return 0 }
    return [IO.Directory]::GetFiles($dir, $filter).Count
}

# Builds the realm, each step once; a build that stopped picks up where it was.
function Install-Solo($s) {
    if (-not (Test-GameDir $s['GAME'])) { throw 'Set your World of Warcraft 1.12.1 folder in Settings first.' }
    $game = $s['GAME']
    New-Item -ItemType Directory -Force -Path $soloDir, (Get-SoloPath 'logs') | Out-Null
    $st = Read-Solo
    if (-not (Test-SoloBuilt)) {
        $drive = Get-PSDrive -Name $soloDir.Substring(0, 1) -ErrorAction SilentlyContinue
        if ($drive -and $drive.Free -lt 6GB) {
            throw ("Your realm needs about 6 GB free on {0}: (it has {1:N1} GB)." -f $drive.Name, ($drive.Free / 1GB))
        }
    }
    if (-not $st.Ports) {
        $ports = [ordered]@{}
        foreach ($k in $soloPortsFirst.Keys) {
            $p = $soloPortsFirst[$k]
            while (Test-LocalPort $p) { $p++ }
            $ports[$k] = $p
        }
        Set-SoloValue $st 'Ports' ([pscustomobject]$ports)
        Set-SoloValue $st 'RootPassword' (New-SoloSecret 20)
        Set-SoloValue $st 'DbPassword' (New-SoloSecret 20)
        Set-SoloValue $st 'User' 'SOLO'
        Set-SoloValue $st 'Pass' (New-SoloSecret 12)
        Save-Solo $st
    }

    # 1. The database server (MariaDB), private to this PC.
    if (-not (Test-SoloStep $st 'database')) {
        Say-Build 'Building your realm: downloading the database server...' 0.0 0.04 0
        $zip = Get-SoloDownload @{ Name = $soloPins.MariaZip; Url = $soloPins.MariaUrl; Sha = $soloPins.MariaSha } 'the database server' 0.0 0.04
        Say-Build 'Building your realm: unpacking the database server...' 0.04 0.05 0
        Expand-SoloZip $zip (Get-SoloPath 'mariadb')
        $data = Get-SoloPath 'db-data'
        if (Test-Path $data) { Remove-Item -Recurse -Force $data }
        Invoke-SoloTool (Get-MariaTool 'mariadb-install-db.exe') @("--datadir=$data", "--password=$($st.RootPassword)", "--port=$($st.Ports.Db)") `
            (Get-SoloPath 'mariadb') 'database-setup' $null
        Add-Content -Path (Join-Path $data 'my.ini') -Value @(
            '', '[mysqld]', '# Only this PC can connect.', 'bind-address=127.0.0.1', 'skip-name-resolve',
            'sql_mode=NO_ENGINE_SUBSTITUTION', 'max_allowed_packet=512M', 'innodb_buffer_pool_size=256M'
        )
        Complete-SoloStep $st 'database'
    }

    # 2. The server (vMaNGOS) and its world database.
    if (-not (Test-SoloStep $st 'server')) {
        Say-Build 'Building your realm: downloading the vMaNGOS server...' 0.05 0.06 0
        $vm = Get-VmAsset 'latest' $soloPins.VmZip $soloPins.VmSha 'dev-windows-amd64-*.zip'
        $db = if ($vm.Sha) { Get-VmAsset 'db_latest' $soloPins.DbZip $soloPins.DbSha 'db-[0-9a-f]*.zip' } else { $null }
        if (-not $db -or -not $db.Sha) {
            # The build has moved on: its database too.
            $vm = Get-VmAsset 'latest' '-' $null 'dev-windows-amd64-*.zip'
            $db = Get-VmAsset 'db_latest' '-' $null 'db-[0-9a-f]*.zip'
        }
        $vmZip = Get-SoloDownload $vm 'the vMaNGOS server' 0.05 0.06
        $dbZip = Get-SoloDownload $db 'the world database' 0.06 0.08
        Expand-SoloZip $vmZip (Get-SoloPath 'vmangos')
        Expand-SoloZip $dbZip (Get-SoloPath 'world-db')
        $short = ($vm.Name -replace '^dev-windows-amd64-', '') -replace '\.zip$', ''
        $commit = $soloPins.VmCommit
        if (-not $soloPins.VmCommit.StartsWith($short)) {
            $commit = (Invoke-RestMethod -Uri "https://api.github.com/repos/vmangos/core/commits/$short" -TimeoutSec 30 `
                    -Headers @{ 'User-Agent' = 'vanilla-vr'; 'Accept' = 'application/vnd.github+json' }).sha
        }
        Set-SoloValue $st 'Server' $vm.Name
        Set-SoloValue $st 'WorldDb' $db.Name
        Set-SoloValue $st 'Commit' $commit
        Complete-SoloStep $st 'server'
    }

    # 3. The databases: the login, characters, logs and world databases, then the house rules.
    if (-not (Test-SoloStep $st 'import')) {
        Say-Build 'Building your realm: filling the world database (a few minutes)...' 0.08 0.11 0
        Start-SoloDb $st
        foreach ($d in 'realmd', 'mangos', 'characters', 'logs') {
            Invoke-SoloSql $st "DROP DATABASE IF EXISTS $d; CREATE DATABASE $d DEFAULT CHARSET utf8 COLLATE utf8_general_ci;" | Out-Null
        }
        # The servers' own database user, for this PC only, with the realm's own password.
        $grants = foreach ($h in 'localhost', '127.0.0.1') {
            "CREATE USER IF NOT EXISTS 'mangos'@'$h'; ALTER USER 'mangos'@'$h' IDENTIFIED BY '$($st.DbPassword)';"
            foreach ($d in 'realmd', 'mangos', 'characters', 'logs') { "GRANT ALL PRIVILEGES ON $d.* TO 'mangos'@'$h';" }
        }
        Invoke-SoloSql $st (($grants -join ' ') + ' FLUSH PRIVILEGES;') | Out-Null
        # A build done before kept no copy of the database: it is fetched again.
        if (-not (Test-Path (Get-SoloPath 'world-db'))) {
            $sha = if ($st.WorldDb -eq $soloPins.DbZip) { $soloPins.DbSha } else { $null }
            $db = Get-VmAsset 'db_latest' "$($st.WorldDb)" $sha 'db-[0-9a-f]*.zip'
            Expand-SoloZip (Get-SoloDownload $db 'the world database' 0.08 0.09) (Get-SoloPath 'world-db')
        }
        $map = [ordered]@{ 'logon.sql' = 'realmd'; 'characters.sql' = 'characters'; 'logs.sql' = 'logs'; 'mangos.sql' = 'mangos' }
        $i = 0
        foreach ($k in $map.Keys) {
            $f = Get-ChildItem -Path (Get-SoloPath 'world-db') -Recurse -Filter $k | Select-Object -First 1
            if (-not $f) { throw "the world database download has no $k" }
            Say-Build "Building your realm: filling the $($map[$k]) database..." 0.08 0.11 ($i / 4)
            Invoke-SoloSql $st '' $map[$k] $f.FullName | Out-Null
            $i++
        }
        Set-SoloValue $st 'RulesSha' ''
        Update-SoloRules $st
        Remove-Item -Recurse -Force (Get-SoloPath 'world-db') -ErrorAction SilentlyContinue
        Complete-SoloStep $st 'import'
    }

    # 4. Your realm and your account on it (GM, as your friend's own; the password is the realm's
    # own, used by the launcher to log you in).
    if (-not (Test-SoloStep $st 'account')) {
        Start-SoloDb $st
        Invoke-SoloSql $st ("REPLACE INTO realmlist (id, name, address, localAddress, localSubnetMask, port, icon, realmflags, timezone, allowedSecurityLevel, population, gamebuild_min, gamebuild_max, flag) " +
            "VALUES (1, 'Vanilla VR Solo', '127.0.0.1', '127.0.0.1', '255.0.0.0', $($st.Ports.World), 1, 0, 1, 0, 0, 5875, 5875, 0);") 'realmd' | Out-Null
        $r = New-SoloSrp6 $st.User $st.Pass
        Invoke-SoloSql $st "DELETE FROM account WHERE username='$($r.User)'; INSERT INTO account (username, v, s, joindate) VALUES ('$($r.User)','$($r.V)','$($r.S)',NOW());" 'realmd' | Out-Null
        $id = "$((Invoke-SoloSql $st "SELECT id FROM account WHERE username='$($r.User)';" 'realmd') | Select-Object -Last 1)".Trim()
        Invoke-SoloSql $st ("REPLACE INTO account_access (id, gmlevel, RealmID) VALUES ($id, 6, -1); " +
            "REPLACE INTO realmcharacters (realmid, acctid, numchars) VALUES (1, $id, 0);") 'realmd' | Out-Null
        Complete-SoloStep $st 'account'
    }

    # 5. The servers' settings: vMaNGOS's own, as your friend's server has them, on this PC only.
    if (-not (Test-SoloStep $st 'configs')) {
        $raw = "https://raw.githubusercontent.com/vmangos/core/$($st.Commit)"
        $get = { param($u) $r = Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 60; if ($r.Content -is [byte[]]) { [Text.Encoding]::UTF8.GetString($r.Content) } else { "$($r.Content)" } }
        $m = & $get "$raw/src/mangosd/mangosd.conf.dist.in"
        $rd = & $get "$raw/src/realmd/realmd.conf.dist.in"
        $etc = Get-SoloPath 'etc'
        $data = Get-SoloPath 'data'
        $logs = Get-SoloPath 'logs'
        New-Item -ItemType Directory -Force -Path $etc, $data | Out-Null
        $fwd = { param($p) ($p -replace '\\', '/').TrimEnd('/') + '/' }
        $p = $st.Ports
        $dbInfo = { param($d) "`"127.0.0.1;$($p.Db);mangos;$($st.DbPassword);$d`"" }
        foreach ($kv in @(
                @('DataDir', ('"' + (& $fwd $data) + '"')), @('LogsDir', ('"' + (& $fwd $logs) + '"')),
                @('LoginDatabase.Info', (& $dbInfo 'realmd')), @('WorldDatabase.Info', (& $dbInfo 'mangos')),
                @('CharacterDatabase.Info', (& $dbInfo 'characters')), @('LogsDatabase.Info', (& $dbInfo 'logs')),
                @('BindIP', '"127.0.0.1"'), @('WorldServerPort', "$($p.World)"),
                # As your friend's server: GMs take damage like anyone.
                @('GM.CheatGod', '0'),
                # Its admin line, for putting it to sleep with your progress saved.
                @('Console.Enable', '0'), @('Ra.Enable', '1'), @('Ra.IP', '127.0.0.1'), @('Ra.Port', "$($p.Ra)"),
                @('Ra.MinAccountLevel', '3'), @('Ra.Restricted', '0'),
                @('Motd', '"Welcome to your solo realm."'))) {
            $m = Set-SoloConfKey $m $kv[0] $kv[1]
        }
        foreach ($kv in @(
                @('LoginDatabaseInfo', (& $dbInfo 'realmd')), @('LogsDir', ('"' + (& $fwd $logs) + '"')),
                @('BindIP', '"127.0.0.1"'), @('RealmServerPort', "$($p.Realm)"))) {
            $rd = Set-SoloConfKey $rd $kv[0] $kv[1]
        }
        Set-Content -Path (Join-Path $etc 'mangosd.conf') -Value $m -Encoding ASCII
        Set-Content -Path (Join-Path $etc 'realmd.conf') -Value $rd -Encoding ASCII
        foreach ($f in 'config.json', 'offmesh.txt') {
            Invoke-WebRequest -Uri "$raw/contrib/mmap/$f" -OutFile (Join-Path $data $f) -UseBasicParsing -TimeoutSec 60
        }
        Complete-SoloStep $st 'configs'
    }
    Stop-SoloDb $st

    # 6. Your game's maps, read from your 1.12.1 folder (never changed): the land's heights.
    $data = Get-SoloPath 'data'
    if (-not (Test-SoloStep $st 'maps')) {
        $since = Get-Date
        $tick = {
            $share = (Get-FileCount (Join-Path $data 'maps')) / $soloExpect.Maps
            Say-Build ("Building your realm: reading your game's maps ({0:P0}{1})..." -f [math]::Min(1, $share), (Get-TimeLeft $since $share)) 0.11 0.24 $share
        }
        Invoke-SoloTool (Get-SoloExe 'MapExtractor.exe') @('-i', ($game -replace '\\', '/'), '-o', ($data -replace '\\', '/'), '--silent') $data 'maps' $tick
        $dbc = Join-Path $data 'dbc'
        $dbcTo = Join-Path $data '5875\dbc'
        if (Test-Path $dbc) {
            New-Item -ItemType Directory -Force -Path (Join-Path $data '5875') | Out-Null
            if (Test-Path $dbcTo) { Remove-Item -Recurse -Force $dbcTo }
            Move-Item $dbc $dbcTo
        }
        if (-not (Test-Path (Join-Path $dbcTo 'Map.dbc'))) { throw 'reading your game''s maps gave no Map.dbc' }
        Complete-SoloStep $st 'maps'
    }

    # 7. Line of sight: the buildings and caves, which spells and creatures cannot see through.
    if (-not (Test-SoloStep $st 'vmaps')) {
        $since = Get-Date
        $tick = {
            $share = [math]::Min(0.95, ((Get-Date) - $since).TotalMinutes / 4)
            Say-Build ("Building your realm: reading your game's buildings ({0:P0})..." -f $share) 0.24 0.36 $share
        }
        Invoke-SoloTool (Get-SoloExe 'VMapExtractor.exe') @('-d', ((Join-Path $game 'Data') -replace '\\', '/'), '--silent') $data 'vmaps-read' $tick @(0, 1)
        New-Item -ItemType Directory -Force -Path (Join-Path $data 'vmaps') | Out-Null
        $since = Get-Date
        $tick = {
            $share = (Get-FileCount (Join-Path $data 'vmaps')) / $soloExpect.Vmaps
            Say-Build ("Building your realm: line of sight ({0:P0}{1})..." -f [math]::Min(1, $share), (Get-TimeLeft $since $share)) 0.36 0.45 $share
        }
        Invoke-SoloTool (Get-SoloExe 'VMapAssembler.exe') @('Buildings', 'vmaps', '--silent') $data 'vmaps' $tick @(0, 1)
        if (-not (Get-ChildItem (Join-Path $data 'vmaps') -Filter '*.vmtree' -ErrorAction SilentlyContinue)) { throw 'line of sight came out empty' }
        Remove-Item -Recurse -Force (Join-Path $data 'Buildings') -ErrorAction SilentlyContinue
        Complete-SoloStep $st 'vmaps'
    }

    # 8. Pathfinding, so creatures walk round walls and Charge and Blink find their way.
    if (-not (Test-SoloStep $st 'mmaps')) {
        New-Item -ItemType Directory -Force -Path (Join-Path $data 'mmaps') | Out-Null
        $threads = [Math]::Max(1, [Environment]::ProcessorCount - 2)
        $since = Get-Date
        foreach ($map in $soloPathMaps) {
            $tick = {
                $share = (Get-FileCount (Join-Path $data 'mmaps') '*.mmtile') / $soloExpect.Tiles
                Say-Build ("Building your realm: pathfinding ({0:P0}{1})..." -f [math]::Min(1, $share), (Get-TimeLeft $since $share)) 0.45 1.0 $share
            }
            Invoke-SoloTool (Get-SoloExe 'MoveMapGenerator.exe') @("$map", '--silent', '--threads', "$threads") $data "mmaps-$map" $tick @(0, 1)
        }
        Complete-SoloStep $st 'mmaps'
    }
    Remove-Item -Recurse -Force (Get-SoloPath 'downloads') -ErrorAction SilentlyContinue
    Set-SoloValue $st 'BuiltAt' (Get-Date -Format s)
    Save-Solo $st
    Say 'Your realm is built.' 'Green' 1
}

# Wakes the realm: the database, the house rules if they changed, the login and world servers.
# The world server takes a minute or three to load.
function Start-Solo {
    if (-not (Test-SoloBuilt)) { throw 'Your realm is not built yet.' }
    $st = Read-Solo
    if (Test-SoloAwake) { Say 'Your realm is awake.' 'Green' 1; return }
    Say 'Waking your realm...' 'Cyan' 0
    Start-SoloDb $st
    Update-SoloRules $st
    $etc = Get-SoloPath 'etc'
    $logs = Get-SoloPath 'logs'
    if (-not (Test-LocalPort $st.Ports.Realm)) {
        $realmd = Get-SoloExe 'realmd.exe'
        Start-Process -FilePath $realmd -ArgumentList '-c', "`"$etc\realmd.conf`"" -WorkingDirectory (Split-Path $realmd) -WindowStyle Hidden `
            -RedirectStandardOutput (Join-Path $logs 'realmd.out.txt') -RedirectStandardError (Join-Path $logs 'realmd.err.txt') | Out-Null
    }
    if (-not (Test-LocalPort $st.Ports.World)) {
        $mangosd = Get-SoloExe 'mangosd.exe'
        Start-Process -FilePath $mangosd -ArgumentList '-c', "`"$etc\mangosd.conf`"" -WorkingDirectory (Split-Path $mangosd) -WindowStyle Hidden `
            -RedirectStandardOutput (Join-Path $logs 'mangosd.out.txt') -RedirectStandardError (Join-Path $logs 'mangosd.err.txt') | Out-Null
    }
    $since = Get-Date
    while (-not (Test-SoloAwake)) {
        $secs = ((Get-Date) - $since).TotalSeconds
        if ($secs -gt 360) { throw 'your realm did not wake in six minutes (solo\logs\mangosd.out.txt says why)' }
        if (-not (Get-SoloProcesses | Where-Object { $_.ProcessName -eq 'mangosd' })) {
            throw 'your realm''s world server stopped while loading (solo\logs\mangosd.out.txt says why)'
        }
        Say ('Waking your realm ({0:N0} s; it takes a minute or three)...' -f $secs) 'Cyan' ([math]::Min(0.95, $secs / 150))
        Start-Sleep -Milliseconds 900
    }
    Say 'Your realm is awake.' 'Green' 1
}

# The world server's admin line: logs in as your account and sends the commands.
function Send-SoloCommands($st, [string[]]$commands) {
    $c = New-Object Net.Sockets.TcpClient
    try {
        $c.Connect('127.0.0.1', [int]$st.Ports.Ra)
        $stream = $c.GetStream()
        $stream.ReadTimeout = 3000
        $buf = New-Object byte[] 4096
        $read = {
            $text = ''
            $until = (Get-Date).AddSeconds(3)
            while ((Get-Date) -lt $until) {
                try { $n = $stream.Read($buf, 0, $buf.Length) } catch { break }
                if ($n -le 0) { break }
                $text += [Text.Encoding]::ASCII.GetString($buf, 0, $n)
                if ($text -match '(?i)(user|pass|logged|mangos>|-auth)') { break }
            }
            $text
        }
        $send = { param($line) $b = [Text.Encoding]::ASCII.GetBytes("$line`r`n"); $stream.Write($b, 0, $b.Length) }
        & $read | Out-Null
        & $send $st.User
        & $read | Out-Null
        & $send $st.Pass
        $hello = & $read
        if ($hello -notmatch '(?i)logged') { return $false }
        foreach ($cmd in $commands) { & $send $cmd; Start-Sleep -Milliseconds 400; & $read | Out-Null }
        return $true
    } catch {
        return $false
    } finally { $c.Close() }
}

# Puts the realm to sleep: everyone saved, the world server shut down, then the login server and
# the database. Anything that will not stop in time is stopped.
function Stop-Solo {
    $st = Read-Solo
    if (-not $st.Ports) { return }
    $world = @(Get-SoloProcesses | Where-Object { $_.ProcessName -eq 'mangosd' })
    if ($world.Count -gt 0) {
        Say 'Saving your progress and putting your realm to sleep...' 'Cyan' 0.2
        if (Send-SoloCommands $st @('saveall', 'server shutdown 1')) {
            foreach ($p in $world) { try { [void]$p.WaitForExit(30000) } catch { } }
        }
    }
    Get-SoloProcesses | Where-Object { $_.ProcessName -ne 'mariadbd' } | Stop-Process -Force -ErrorAction SilentlyContinue
    Stop-SoloDb $st
    Get-SoloProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
    Say 'Your realm is asleep.' 'Green' 1
}

# SPGG RootPW audit runner v1.0 - PowerShell 7 / Windows OpenSSH
# Remote script is run through sudo noninteractively only if already authorized/cached.
# Use -InteractiveSudo for environments requiring an interactive root password.
[CmdletBinding()]
param(
  [string]$ServerList = (Join-Path $PSScriptRoot 'SPGG_Servidores_Ubuntu.txt'),
  [string]$LinuxScript = (Join-Path $PSScriptRoot 'SPGG_RootPW.sh'),
  [string]$SshUser = 'spggadmin',
  [string]$StartDate = '2026-07-01',
  [string]$EndDate = '2026-10-01',
  [switch]$InteractiveSudo
)
$ErrorActionPreference = 'Stop'
if (!(Test-Path $ServerList)) { throw "Server list not found: $ServerList" }
if (!(Test-Path $LinuxScript)) { throw "Linux script not found: $LinuxScript" }
if ($StartDate -notmatch '^\d{4}-\d{2}-\d{2}$' -or $EndDate -notmatch '^\d{4}-\d{2}-\d{2}$') { throw 'Dates must be YYYY-MM-DD' }
$dest = Join-Path $PSScriptRoot 'SPGG_RootPW'
New-Item -ItemType Directory -Path $dest -Force | Out-Null
$servers = Get-Content $ServerList | ForEach-Object { $_.Trim() } | Where-Object { $_ -and !$_.StartsWith('#') }
foreach ($server in $servers) {
  if ($server -notmatch '^[A-Za-z0-9._-]+$') { Write-Warning "Invalid server: $server"; continue }
  $target = "$SshUser@$server"
  $token = [guid]::NewGuid().ToString('N')
  $remoteDir = "/tmp/spgg-rootpw-$token"
  $remoteScript = "$remoteDir/SPGG_RootPW.sh"
  $remoteReport = "$remoteDir/report.txt"
  $localReport = Join-Path $dest "$(Get-Date -Format yyyyMMdd)_${server}_SPGG_RootPW.txt"
  Write-Host "Auditing $server ..."
  try {
    & ssh -o ConnectTimeout=15 -- $target "umask 077; mkdir '$remoteDir'" 
    if ($LASTEXITCODE -ne 0) { throw 'Remote mkdir failed' }
    & scp -q -- $LinuxScript "${target}:${remoteScript}"
    if ($LASTEXITCODE -ne 0) { throw 'SCP upload failed' }
    $sudoPrefix = if ($InteractiveSudo) { 'sudo' } else { 'sudo -n' }
    $tty = if ($InteractiveSudo) { '-tt' } else { '-T' }
    # Redirection runs under unprivileged shell, output remains in private temp directory.
    & ssh $tty -- $target "$sudoPrefix bash '$remoteScript' '$StartDate' '$EndDate' > '$remoteReport' 2>&1"
    if ($LASTEXITCODE -ne 0) { Write-Warning "Audit command returned $LASTEXITCODE on $server (retrieving report anyway)" }
    & scp -q -- "${target}:${remoteReport}" $localReport
    if ($LASTEXITCODE -ne 0) { throw 'SCP report failed' }
    Write-Host "Saved: $localReport"
  } catch { Write-Warning "${server}: $_" }
  finally {
    & ssh -o ConnectTimeout=15 -- $target "rm -f '$remoteScript' '$remoteReport'; rmdir '$remoteDir' 2>/dev/null" 2>$null
  }
}

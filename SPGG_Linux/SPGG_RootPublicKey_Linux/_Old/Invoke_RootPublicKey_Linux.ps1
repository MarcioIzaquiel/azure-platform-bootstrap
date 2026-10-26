# SPGG - Inventario de chaves SSH autorizadas para root - v1.0
# PowerShell 7 + OpenSSH | auditoria somente leitura de configuracoes remotas
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Usuario,
    [ValidateRange(1,65535)][int]$Porta = 22,
    [string]$ServerList = (Join-Path $PSScriptRoot 'SPGG_Servidores_Ubuntu.txt'),
    [string]$LinuxScript = (Join-Path $PSScriptRoot 'SPGG_RootPublicKey_Linux.sh')
)
$ErrorActionPreference = 'Stop'
if ($Usuario -notmatch '^[a-zA-Z_][a-zA-Z0-9_.-]*$') { throw 'Usuario SSH invalido.' }
foreach ($file in @($ServerList,$LinuxScript)) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Arquivo ausente: $file" }
}
foreach ($cmd in @('ssh','scp')) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { throw "Comando ausente: $cmd" }
}
# Apenas linhas nao vazias e nao comentadas; preserva a regra do inventario SPGG.
$targets = @(
    Get-Content -LiteralPath $ServerList |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and -not $_.StartsWith('#') } |
        Select-Object -Unique
)
if ($targets.Count -eq 0) { throw 'Nenhum IP ativo na lista. Descomente os IPs desejados.' }
foreach ($target in $targets) {
    if ($target -notmatch '^[a-zA-Z0-9][a-zA-Z0-9.-]*$') { throw "Endereco invalido: $target" }
}
$base = Join-Path $PSScriptRoot 'SPGG_RootPublicKey_Linux'
if (-not (Test-Path -LiteralPath $base -PathType Container)) {
    throw "Pasta de respostas nao encontrada: $base (crie antes de executar)."
}
$results = [System.Collections.Generic.List[object]]::new()
Write-Host "SPGG ROOT PUBLIC KEY - READ ONLY | Alvos: $($targets.Count) | Pasta: $base"
foreach ($ip in $targets) {
    $destination = "${Usuario}@${ip}"
    $id = [guid]::NewGuid().ToString('N')
    $remoteDir = "/tmp/spgg-rootpubkey-$id"
    $remoteScript = "$remoteDir/SPGG_RootPublicKey_Linux.sh"
    $remoteReport = "$remoteDir/report.txt"
    $tempLocalReport = Join-Path $base (".spgg-rootpubkey-{0}.tmp" -f $id)
    $localReport = ''
    $created = $false
    $copied = $false
    $status = 'FALHA'
    $detail = ''
    Write-Host "`n===== $ip ====="
    try {
        & ssh -p $Porta -o ConnectTimeout=15 $destination "mkdir -m 700 '$remoteDir'"
        if ($LASTEXITCODE -ne 0) { throw 'Falha ao criar pasta remota' }
        $created = $true
        & scp -P $Porta -q $LinuxScript "${destination}:${remoteScript}"
        if ($LASTEXITCODE -ne 0) { throw 'Falha ao transferir script' }
        Write-Host 'Coletando metadados SSH via sudo (pode solicitar senha)...'
        & ssh -tt -p $Porta $destination "umask 077; sudo bash '$remoteScript' > '$remoteReport'"
        if ($LASTEXITCODE -ne 0) { throw "Falha na auditoria (exit $LASTEXITCODE)" }
        & scp -P $Porta -q "${destination}:${remoteReport}" $tempLocalReport
        if ($LASTEXITCODE -ne 0) { throw 'Falha ao baixar relatorio' }
        $hostnameLine = Get-Content -LiteralPath $tempLocalReport | Where-Object { $_ -match '^HOSTNAME=' } | Select-Object -First 1
        if (-not $hostnameLine) { throw 'Relatorio sem HOSTNAME; temporario preservado' }
        $hostnameValue = ($hostnameLine -replace '^HOSTNAME=', '').Trim().ToLowerInvariant()
        if ($hostnameValue -notmatch '^[a-z0-9][a-z0-9.-]*$') { throw "Hostname invalido: $hostnameValue" }
        $localReport = Join-Path $base ("{0}_{1}_SPGG_RootPublicKey_Linux.txt" -f (Get-Date -Format 'yyyyMMdd'),$hostnameValue)
        if (Test-Path -LiteralPath $localReport) { throw "Relatorio ja existe: $localReport. Preserve ou mova o anterior antes de repetir." }
        Move-Item -LiteralPath $tempLocalReport -Destination $localReport -ErrorAction Stop
        $copied = $true
        $status = 'SUCESSO'
        Write-Host "Relatorio: $localReport" -ForegroundColor Green
    } catch {
        $detail = $_.Exception.Message
        Write-Warning "Falha em ${ip}: $detail"
    } finally {
        if ($created -and $copied) {
            & ssh -p $Porta -o ConnectTimeout=15 $destination "rm -f '$remoteScript' '$remoteReport' && rmdir '$remoteDir'" 2>$null
            if ($LASTEXITCODE -ne 0) { Write-Warning "Limpeza remota pendente: $remoteDir" }
        } elseif ($created) {
            Write-Warning "Pasta temporaria preservada para diagnostico: $remoteDir"
        }
    }
    $results.Add([pscustomobject]@{
        IP=$ip; Status=$status; Relatorio=$(if($copied){$localReport}else{''}); Erro=$detail
    })
}
$csv = Join-Path $base 'SPGG_RootPublicKey_Execucao.csv'
$results | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding utf8
Write-Host "`nResumo: $(@($results | Where-Object Status -eq 'SUCESSO').Count)/$($targets.Count) | CSV: $csv"
if (@($results | Where-Object Status -eq 'FALHA').Count -gt 0) { exit 1 }

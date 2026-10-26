# SPGG - Padronizacao Etapa 1 - Precheck v1.0
# PowerShell 7 + OpenSSH | somente leitura no sistema remoto
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Usuario,
    [ValidateRange(1,65535)][int]$Porta = 22,
    [ValidateSet('Grupo1','Grupo2','Ambos')][string]$Grupo = 'Grupo1',
    [string]$ServerList = (Join-Path $PSScriptRoot 'SPGG_Servidores_Ubuntu.txt'),
    [string]$LinuxScript = (Join-Path $PSScriptRoot 'SPGG_Hardening_Precheck.sh')
)
$ErrorActionPreference = 'Stop'
if ($Usuario -notmatch '^[a-zA-Z_][a-zA-Z0-9_.-]*$') { throw 'Usuario SSH invalido.' }
foreach ($file in @($ServerList,$LinuxScript)) { if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Arquivo ausente: $file" } }
foreach ($cmd in @('ssh','scp')) { if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { throw "Comando ausente: $cmd" } }
# Lista original tem IPs comentados; selecionar apenas os grupos 1 e 2, sem tocar HomeLab/outros.
$targets = [System.Collections.Generic.List[object]]::new()
$currentGroup = ''
$description = ''
foreach ($raw in (Get-Content -LiteralPath $ServerList)) {
    $line = $raw.Trim()
    if ($line -match '^#\s*Grupo\s*1\b') { $currentGroup = 'Grupo1'; continue }
    if ($line -match '^#\s*Grupo\s*2\b') { $currentGroup = 'Grupo2'; continue }
    if ($line -match '^#\s*Fim do Grupo\s*[12]') { $currentGroup = ''; continue }
    if ($currentGroup -eq '') { continue }
    if ($line -match '^#\s*(VM\d+)\s+(.+?)\s+(\d{1,3}(?:\.\d{1,3}){3})(?:\s+.*)?$') {
        $description = $Matches[2]
        continue
    }
    if ($line -match '^#\s*(\d{1,3}(?:\.\d{1,3}){3})\s*$') {
        $ip = $Matches[1]
        $parsedIp = $null
        if (-not [System.Net.IPAddress]::TryParse($ip,[ref]$parsedIp) -or $parsedIp.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) { throw "IP invalido: $ip" }
        $targets.Add([pscustomobject]@{Grupo=$currentGroup;IP=$ip;Descricao=$description})
    }
}
$targets = @($targets | Where-Object { $Grupo -eq 'Ambos' -or $_.Grupo -eq $Grupo } | Sort-Object IP -Unique)
if ($targets.Count -eq 0) { throw "Nenhum alvo encontrado para $Grupo. Confira os comentarios na lista." }
$expected = if ($Grupo -eq 'Ambos') { 12 } else { 6 }
if ($targets.Count -ne $expected) { throw "Esperados $expected servidores, encontrados $($targets.Count). Verifique lista antes de executar." }
$base = Join-Path $PSScriptRoot 'SPPG_Padronizacao_Etapa_1'
$runDir = Join-Path $base (Get-Date -Format 'yyyyMMdd_HHmmss')
New-Item -ItemType Directory -Path $runDir -Force | Out-Null
$results = [System.Collections.Generic.List[object]]::new()
Write-Host "SPGG PRECHECK - SOMENTE LEITURA | Grupo: $Grupo | Alvos: $($targets.Count) | Pasta: $runDir"
foreach ($target in $targets) {
    $ip = $target.IP
    $destination = "${Usuario}@${ip}"
    $id = [guid]::NewGuid().ToString('N')
    $remoteDir = "/tmp/spgg-precheck-$id"
    $remoteScript = "$remoteDir/SPGG_Hardening_Precheck.sh"
    $remoteReport = "$remoteDir/report.txt"
    $localReport = Join-Path $runDir ("{0}_{1}_SPGG_Hardening_Precheck.txt" -f (Get-Date -Format yyyyMMdd),$ip)
    $created = $false
    $copied = $false
    $status = 'FALHA'
    $detail = ''
    Write-Host "`n===== $($target.Grupo) $ip ($($target.Descricao)) ====="
    try {
        & ssh -p $Porta -o ConnectTimeout=15 $destination "mkdir -m 700 '$remoteDir'"
        if ($LASTEXITCODE -ne 0) { throw 'Falha ao criar pasta remota' }
        $created = $true
        & scp -P $Porta -q $LinuxScript "${destination}:${remoteScript}"
        if ($LASTEXITCODE -ne 0) { throw 'Falha ao transferir script' }
        Write-Host 'Executando precheck via sudo (pode solicitar senha conforme configuracao atual)...'
        # Redirecionamento pelo usuario SSH, para SCP posterior sem root remoto.
        & ssh -tt -p $Porta $destination "umask 077; sudo bash '$remoteScript' > '$remoteReport'"
        if ($LASTEXITCODE -ne 0) { throw "Falha no precheck (exit $LASTEXITCODE)" }
        & scp -P $Porta -q "${destination}:${remoteReport}" $localReport
        if ($LASTEXITCODE -ne 0) { throw 'Falha ao baixar relatorio' }
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
        } elseif ($created) { Write-Warning "Pasta temporaria preservada para diagnostico: $remoteDir" }
    }
    $results.Add([pscustomobject]@{Grupo=$target.Grupo;IP=$ip;Descricao=$target.Descricao;Status=$status;Relatorio= $(if($copied){$localReport}else{''});Erro=$detail})
}
$csv = Join-Path $runDir 'SPGG_Precheck_Execucao.csv'
$results | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding utf8
Write-Host "`nResumo: $(@($results | Where-Object Status -eq 'SUCESSO').Count)/$($targets.Count) | CSV: $csv"
if (@($results | Where-Object Status -eq 'FALHA').Count -gt 0) { exit 1 }

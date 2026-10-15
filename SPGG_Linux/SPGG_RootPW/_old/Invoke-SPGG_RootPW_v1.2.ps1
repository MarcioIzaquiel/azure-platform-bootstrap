# SPGG - Auditoria remota RootPW | Versao 1.2 | PowerShell 7 / OpenSSH
# Uso: .\Invoke-SPGG_RootPW.ps1 -Usuario spggadmin
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Usuario,
    [int]$Porta = 22,
    [string]$StartDate = '2026-07-01',
    [string]$EndDate = '2026-10-01',
    [string]$ServerList = (Join-Path $PSScriptRoot 'SPGG_Servidores_Ubuntu.txt'),
    [string]$LinuxScript = (Join-Path $PSScriptRoot 'SPGG_RootPW.sh')
)
$ErrorActionPreference = 'Stop'
if ($Usuario -notmatch '^[a-zA-Z_][a-zA-Z0-9_.-]*$') { throw 'Nome de usuario invalido.' }
if ($Porta -lt 1 -or $Porta -gt 65535) { throw 'Porta SSH invalida.' }
foreach ($d in @($StartDate, $EndDate)) {
    if ($d -notmatch '^\d{4}-\d{2}-\d{2}$') { throw 'Datas devem estar em YYYY-MM-DD.' }
    $parsed = [datetime]::MinValue
    if (-not [datetime]::TryParseExact($d, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$parsed)) { throw "Data invalida: $d" }
}
if ($StartDate -ge $EndDate) { throw 'StartDate deve ser anterior a EndDate.' }
foreach ($f in @($ServerList, $LinuxScript)) { if (-not (Test-Path -LiteralPath $f -PathType Leaf)) { throw "Arquivo nao encontrado: $f" } }
foreach ($cmd in @('ssh', 'scp')) { if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { throw "Comando nao encontrado: $cmd" } }
$Servidores = @(Get-Content -LiteralPath $ServerList | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') } | Select-Object -Unique)
if ($Servidores.Count -eq 0) { throw 'Lista de servidores vazia.' }
$PastaBase = $PSScriptRoot
$PastaRelatorios = Join-Path $PastaBase 'SPGG_RootPW'
New-Item -ItemType Directory -Path $PastaRelatorios -Force | Out-Null
$Sucessos = 0; $Falhas = 0
Write-Host "SPGG RootPW v1.2 | Usuario: $Usuario | Porta: $Porta | Servidores: $($Servidores.Count)"
Write-Host "Periodo: $StartDate a $EndDate (fim exclusivo)"
foreach ($Servidor in $Servidores) {
    if ($Servidor -notmatch '^[a-zA-Z0-9][a-zA-Z0-9.-]*$') { Write-Warning "Endereco invalido: $Servidor"; $Falhas++; continue }
    $DestinoSSH = "${Usuario}@${Servidor}"
    $Id = [guid]::NewGuid().ToString('N')
    $PastaRemota = "/tmp/spgg-rootpw-$Id"
    $RelatorioRemoto = "$PastaRemota/report.txt"
    $HostnameRemoto = "$PastaRemota/hostname.txt"
    $ArquivoRemoto = "$PastaRemota/SPGG_RootPW.sh"
    $CriouPasta = $false
    $CopiouRelatorio = $false
    Write-Host "`n===== $Servidor ====="
    try {
        Write-Host '[1/4] Criando pasta temporaria...'
        & ssh -p $Porta -o ConnectTimeout=15 $DestinoSSH "mkdir -m 700 '$PastaRemota'"
        if ($LASTEXITCODE -ne 0) { throw 'Falha ao criar pasta remota.' }
        $CriouPasta = $true
        Write-Host '[2/4] Transferindo script...'
        & scp -P $Porta -q $LinuxScript "${DestinoSSH}:${ArquivoRemoto}"
        if ($LASTEXITCODE -ne 0) { throw 'Falha ao transferir script.' }
        Write-Host '[3/4] Executando auditoria via sudo (pode solicitar senha root)...'
        # O redirecionamento pertence ao shell SSH do usuario, nao ao processo sudo.
        # Assim o relatorio fica acessivel ao proprio usuario para SCP.
        & ssh -tt -p $Porta $DestinoSSH "umask 077; sudo bash '$ArquivoRemoto' '$StartDate' '$EndDate' > '$RelatorioRemoto'"
        if ($LASTEXITCODE -ne 0) { throw "Falha na execucao remota (exit $LASTEXITCODE)." }
        Write-Host '[4/4] Recuperando relatorio e hostname...'
        # Hostname is supplied by the remote Linux host, not by the IP/server list.
        # Write it into the restricted remote temp folder to avoid stdout/TTY parsing.
        & ssh -p $Porta -o ConnectTimeout=15 $DestinoSSH "hostname -s > '$HostnameRemoto'"
        if ($LASTEXITCODE -ne 0) { throw 'Falha ao obter hostname remoto.' }
        $HostnameLocal = Join-Path $PastaRelatorios (".hostname_{0}.txt" -f $Id)
        try {
            & scp -P $Porta -q "${DestinoSSH}:${HostnameRemoto}" $HostnameLocal
            if ($LASTEXITCODE -ne 0) { throw 'Falha ao recuperar hostname remoto.' }
            $Hostname = (Get-Content -LiteralPath $HostnameLocal -TotalCount 1).Trim()
        } finally {
            Remove-Item -LiteralPath $HostnameLocal -Force -ErrorAction SilentlyContinue
        }
        if ($Hostname -notmatch '^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}$') {
            throw "Hostname remoto invalido para nome de arquivo: $Hostname"
        }
        $Nome = "$(Get-Date -Format yyyyMMdd)_${Hostname}_SPGG_RootPW.txt"
        $Destino = Join-Path $PastaRelatorios $Nome
        if (Test-Path -LiteralPath $Destino) {
            $Destino = Join-Path $PastaRelatorios ("{0}_{1}.txt" -f [IO.Path]::GetFileNameWithoutExtension($Nome), (Get-Date -Format 'HHmmssfff'))
        }
        & scp -P $Porta -q "${DestinoSSH}:${RelatorioRemoto}" $Destino
        if ($LASTEXITCODE -ne 0) { throw 'Falha ao recuperar relatorio.' }
        $CopiouRelatorio = $true
        Write-Host "SUCESSO: $Destino" -ForegroundColor Green
        $Sucessos++
    } catch {
        Write-Warning "FALHA em ${Servidor}: $($_.Exception.Message)"
        $Falhas++
    } finally {
        if ($CriouPasta -and $CopiouRelatorio) {
            & ssh -p $Porta -o ConnectTimeout=15 $DestinoSSH "rm -f '$ArquivoRemoto' '$RelatorioRemoto' '$HostnameRemoto' && rmdir '$PastaRemota'" 2>$null
            if ($LASTEXITCODE -ne 0) { Write-Warning "Limpeza remota nao concluida: $Servidor" }
        } elseif ($CriouPasta) {
            Write-Warning "Pasta remota preservada para diagnostico: $PastaRemota"
        }
    }
}
Write-Host "`n===== RESUMO ====="
Write-Host "Total: $($Servidores.Count) | Sucesso: $Sucessos | Falhas: $Falhas"
if ($Falhas -gt 0) { exit 1 }

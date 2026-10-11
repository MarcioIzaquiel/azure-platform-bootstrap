
# SPGG - Execucao remota de auditoria Linux
# Versao: 1.0
# Requisitos: PowerShell 7, OpenSSH Client e acesso sudo no Ubuntu

param(
    [Parameter(Mandatory = $true)]
    [string]$Usuario,

    [int]$Porta = 22
)

$ErrorActionPreference = "Stop"

# Os arquivos sao localizados em relacao a este .ps1
$PastaBase = $PSScriptRoot
$ArquivoBash = Join-Path $PastaBase "SPGG_Linux.sh"
$ArquivoServidores = Join-Path $PastaBase "SPGG_Servidores_Ubuntu.txt"

if (-not (Test-Path -LiteralPath $ArquivoBash -PathType Leaf)) {
    throw "Script Bash nao encontrado: $ArquivoBash"
}

if (-not (Test-Path -LiteralPath $ArquivoServidores -PathType Leaf)) {
    throw "Lista de servidores nao encontrada: $ArquivoServidores"
}

foreach ($Comando in @("ssh", "scp")) {
    if (-not (Get-Command $Comando -ErrorAction SilentlyContinue)) {
        throw "Comando nao encontrado: $Comando"
    }
}

if ($Usuario -notmatch '^[a-zA-Z_][a-zA-Z0-9_.-]*$') {
    throw "Nome de usuario invalido."
}

# Ler IPs ou nomes DNS, ignorando comentarios e linhas vazias
$Servidores = @(
    Get-Content -LiteralPath $ArquivoServidores |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and -not $_.StartsWith("#") } |
        Select-Object -Unique
)

if ($Servidores.Count -eq 0) {
    throw "Nenhum servidor encontrado na lista."
}

$Sucessos = 0
$Falhas = 0

Write-Host ""
Write-Host "SPGG - AUDITORIA REMOTA LINUX"
Write-Host "Servidores encontrados: $($Servidores.Count)"
Write-Host "Usuario SSH: $Usuario"
Write-Host "Porta SSH: $Porta"
Write-Host "Destino dos relatorios: $PastaBase"

foreach ($Servidor in $Servidores) {

    Write-Host ""
    Write-Host "============================================"
    Write-Host "Servidor: $Servidor"
    Write-Host "============================================"

    if ($Servidor -notmatch '^[a-zA-Z0-9][a-zA-Z0-9.-]*$') {
        Write-Warning "Endereco invalido: $Servidor"
        $Falhas++
        continue
    }

    $DestinoSSH = "${Usuario}@${Servidor}"

    # Pasta unica para cada execucao
    $Id = [guid]::NewGuid().ToString("N")
    $PastaRemota = "/tmp/spgg-auditoria-$Id"

    $RelatorioCopiado = $false

    try {
        # 1 - Criar pasta temporaria no Ubuntu
        Write-Host "[1/4] Criando diretorio remoto..."

        & ssh -p $Porta -o ConnectTimeout=10 `
            $DestinoSSH "mkdir -m 700 '$PastaRemota'"

        if ($LASTEXITCODE -ne 0) {
            throw "Falha ao criar diretorio remoto."
        }

        # 2 - Transferir script Bash
        Write-Host "[2/4] Transferindo script..."

        & scp -P $Porta `
            $ArquivoBash "${DestinoSSH}:${PastaRemota}/SPGG_Linux.sh"

        if ($LASTEXITCODE -ne 0) {
            throw "Falha na transferencia do script."
        }

        # 3 - Executar auditoria
        Write-Host "[3/4] Executando auditoria..."
        Write-Host "O sudo podera solicitar a senha do usuario."

        # -tt permite autenticacao sudo interativa
        & ssh -tt -p $Porta `
            $DestinoSSH `
            "cd '$PastaRemota' && bash ./SPGG_Linux.sh"

        if ($LASTEXITCODE -ne 0) {
            throw "Falha na execucao remota."
        }

        # 4 - Recuperar relatorio
        Write-Host "[4/4] Recuperando relatorio..."

        # Primeiro, baixar para uma pasta local temporaria
        $PastaLocalTemp = Join-Path $PastaBase "_temp_$Id"
        New-Item -ItemType Directory -Path $PastaLocalTemp |
            Out-Null

        & scp -P $Porta `
            "${DestinoSSH}:${PastaRemota}/*.txt" `
            $PastaLocalTemp

        if ($LASTEXITCODE -ne 0) {
            throw "Falha ao recuperar relatorio."
        }

        $Relatorios = @(
            Get-ChildItem -LiteralPath $PastaLocalTemp `
                -Filter "*.txt" -File
        )

        if ($Relatorios.Count -ne 1) {
            throw "Quantidade inesperada de relatorios."
        }

        $Origem = $Relatorios[0].FullName
        $Destino = Join-Path $PastaBase $Relatorios[0].Name

        # Nao sobrescrever relatorios anteriores
        if (Test-Path -LiteralPath $Destino) {
            $Nome = [IO.Path]::GetFileNameWithoutExtension($Destino)
            $Destino = Join-Path $PastaBase (
                "{0}_{1}.txt" -f $Nome, (Get-Date -Format "HHmmssfff")
            )
        }

        Move-Item -LiteralPath $Origem -Destination $Destino
        $RelatorioCopiado = $true

        Write-Host "SUCESSO: $Destino" -ForegroundColor Green
        $Sucessos++
    }
    catch {
        Write-Warning "FALHA em ${Servidor}: $($_.Exception.Message)"
        $Falhas++
    }
    finally {
        # Limpeza local
        if (Test-Path -LiteralPath $PastaLocalTemp) {
            Remove-Item -LiteralPath $PastaLocalTemp `
                -Recurse -Force
        }

        # Limpeza remota somente se o relatorio foi recuperado
        if ($RelatorioCopiado) {
            & ssh -p $Porta $DestinoSSH `
                "rm -f '$PastaRemota/SPGG_Linux.sh' '$PastaRemota'/*.txt && rmdir '$PastaRemota'"

            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Limpeza remota nao concluida em $Servidor."
            }
        }
        else {
            Write-Warning "Se criada, a pasta remota foi preservada para diagnostico: $PastaRemota"
        }
    }
}

Write-Host ""
Write-Host "===== RESUMO ====="
Write-Host "Total   : $($Servidores.Count)"
Write-Host "Sucesso : $Sucessos"
Write-Host "Falhas  : $Falhas"

if ($Falhas -gt 0) {
    exit 1
}
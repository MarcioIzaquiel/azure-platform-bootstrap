# ==========================================================
# ------------------- BLOCO 01 -----------------------------
# ==========================================================


# =====================================================================
# Script_XML_UltimoAcesso_PADRAO_v5.ps1
#
# Objetivo:
#   Interpretar o XML gerado pelo FSRM
#   (Least Recently Accessed Files)
#   e gerar um CSV padronizado para analise.
#
# Padrao Corporativo v2.0
# =====================================================================

Clear-Host

$ErrorActionPreference = "Stop"

# ==========================================================
# CONFIGURACAO
# ==========================================================

# Arquivo XML exportado pelo FSRM

$XmlFile = "C:\Temp_Marcio\AZURE\azure-platform-bootstrap\SPGG_FS01\LeastRecentlyAccessed341_2026-11-12_12-24-04.xml"

# Pasta de saida

$OutputDir = "C:\Temp_Marcio\FS_Scripts"

# Quantidade maxima de linhas do CSV

$TopN = 1000

# Cultura para utilizar ponto como separador decimal

$Culture = [System.Globalization.CultureInfo]::InvariantCulture

# Formato das datas para o Excel Online

$DateFormat = "MM/dd/yyyy"

# ==========================================================
# FUNCAO DE CONVERSAO DE DATA
# ==========================================================

function Convert-FsrmDate
{
    param
    (
        [AllowNull()]
        [string]$DateText,

        [string]$OutputFormat = "MM/dd/yyyy"
    )

    if ([string]::IsNullOrWhiteSpace($DateText))
    {
        return ""
    }

    $SourceFormats = @(
        "dd/MM/yyyy HH:mm:ss",
        "dd/MM/yyyy H:mm:ss",
        "dd/MM/yyyy"
    )

    foreach ($SourceFormat in $SourceFormats)
    {
        try
        {
            $ParsedDate = [datetime]::ParseExact(
                $DateText.Trim(),
                $SourceFormat,
                [System.Globalization.CultureInfo]::InvariantCulture
            )

            return $ParsedDate.ToString(
                $OutputFormat,
                [System.Globalization.CultureInfo]::InvariantCulture
            )
        }
        catch
        {
        }
    }

    return ""
}

# ==========================================================
# VALIDACOES
# ==========================================================

if (!(Test-Path $XmlFile))
{
    throw "Arquivo XML nao encontrado: $XmlFile"
}

if (!(Test-Path $OutputDir))
{
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# ==========================================================
# LEITURA DO XML
# ==========================================================

[xml]$Xml = Get-Content -Path $XmlFile

if ($null -eq $Xml.StorageReport)
{
    throw "Estrutura StorageReport nao encontrada no XML."
}

$Header = $Xml.StorageReport.ReportHeader

if ($null -eq $Header)
{
    throw "ReportHeader nao encontrado no XML."
}

$Machine = [string]$Header.MachineName

$GeneratedAt = [string]$Header.GeneratedAt

$FilesCount = [int64]$Header.FilesCount

$MaxDisplayItems = [int64]$Header.MaxDisplayItems

# ==========================================================
# NAMESPACE
# ==========================================================

if ($Header.ReportNamespaces.Namespace -is [System.Array])
{
    $Namespace = $Header.ReportNamespaces.Namespace[0].InnerText.Trim()
}
else
{
    $Namespace = $Header.ReportNamespaces.Namespace.InnerText.Trim()
}

if ([string]::IsNullOrWhiteSpace($Namespace))
{
    $Namespace = "ROOT"
}

$FolderName = Split-Path -Path $Namespace -Leaf

if ([string]::IsNullOrWhiteSpace($FolderName))
{
    $FolderName = "ROOT"
}

# ==========================================================
# FILTROS DO RELATORIO
# ==========================================================

$MinimumAccessedDays = ""

if ($Header.ReportFilters -and $Header.ReportFilters.Filter)
{
    foreach ($Filter in $Header.ReportFilters.Filter)
    {
        if ([string]$Filter.Name -eq "Minimum accessed days")
        {
            $MinimumAccessedDays = [string]$Filter.Value
        }
    }
}

# ==========================================================
# AVISOS DO FSRM
# ==========================================================

if ($Header.ReportWarnings -and $Header.ReportWarnings.Warning)
{
    $Warnings = @($Header.ReportWarnings.Warning)
}
else
{
    $Warnings = @()
}

# ==========================================================
# TOTAIS DO RELATORIO
# ==========================================================

$ReportTotals = $Xml.StorageReport.ReportSummary.ReportTotals

if ($null -eq $ReportTotals)
{
    throw "ReportSummary.ReportTotals nao encontrado no XML."
}

# Total de todos os arquivos que atenderam ao criterio

$TotalFilesFSRM = [int64]$ReportTotals.FileCount

$TotalBytesFSRM = [int64]$ReportTotals.Size

$TotalMBFSRM = [Math]::Round(
    ($TotalBytesFSRM / 1MB),
    2
)

# Total dos arquivos detalhados dentro do XML

$DisplayFiles = [int64]$ReportTotals.DisplayFileCount

$DisplayBytes = [int64]$ReportTotals.DisplaySize

$DisplayMB = [Math]::Round(
    ($DisplayBytes / 1MB),
    2
)

# ==========================================================
# ARQUIVOS DE SAIDA
# ==========================================================

$Today = Get-Date -Format "yyyyMMdd"

$CsvPath = Join-Path -Path $OutputDir -ChildPath (
    $Today + "_ultimo_acesso_csv_" + $FolderName + ".csv"
)

$LogPath = Join-Path -Path $OutputDir -ChildPath (
    $Today + "_ultimo_acesso_log_" + $FolderName + ".txt"
)

# ==========================================================
# INICIO DO LOG
# ==========================================================

try
{
    Stop-Transcript | Out-Null
}
catch
{
}

$TranscriptAtivo = $false

try
{
    Start-Transcript -Path $LogPath -Force | Out-Null

    $TranscriptAtivo = $true
}
catch
{
    Write-Host ""
    Write-Host "AVISO: Nao foi possivel iniciar o arquivo de log."
    Write-Host ("LOG bloqueado ou em uso: {0}" -f $LogPath)
    Write-Host "O processamento continuara sem transcript."
    Write-Host ""
}

$StartTime = Get-Date

# ==========================================================
# CABECALHO DO RELATORIO
# ==========================================================

Write-Host ""
Write-Host "============================================================"
Write-Host "RELATORIO - ULTIMO ACESSO (FSRM XML)"
Write-Host "============================================================"
Write-Host ("XML....................: {0}" -f $XmlFile)
Write-Host ("Servidor...............: {0}" -f $Machine)
Write-Host ("Pasta..................: {0}" -f $Namespace)
Write-Host ("Data relatorio.........: {0}" -f $GeneratedAt)

if (-not [string]::IsNullOrWhiteSpace($MinimumAccessedDays))
{
    Write-Host ("Criterio FSRM..........: {0}" -f $MinimumAccessedDays)
}

Write-Host ("Arquivos encontrados...: {0:N0}" -f $FilesCount)
Write-Host ("Max itens no XML.......: {0:N0}" -f $MaxDisplayItems)
Write-Host ("Arquivos no XML........: {0:N0}" -f $DisplayFiles)
Write-Host ("MB no XML..............: {0:N2}" -f $DisplayMB)
Write-Host ("CSV....................: {0}" -f $CsvPath)
Write-Host ("LOG....................: {0}" -f $LogPath)
Write-Host "============================================================"
Write-Host ""

# ==========================================================
# EXIBICAO DOS AVISOS DO FSRM
# ==========================================================

if ($Warnings.Count -gt 0)
{
    Write-Host "AVISOS DO FSRM:"
    Write-Host ""

    foreach ($Warning in $Warnings)
    {
        Write-Host (" - {0}" -f [string]$Warning)
    }

    Write-Host ""
}


# ==========================================================
# ------------------- BLOCO 02 -----------------------------
# ==========================================================


# ==========================================================
# LEITURA DOS ITENS DO XML
# ==========================================================

Write-Host "Lendo arquivos do XML..."
Write-Host ""

$ItensXML = @($Xml.StorageReport.ReportData.Item)

$ArquivosProcessados = 0

$ArquivosComData = 0

$ArquivosSemData = 0

# ==========================================================
# PROCESSAMENTO DOS ARQUIVOS
# ==========================================================

$Resultado = foreach ($Item in $ItensXML)
{
    $ArquivosProcessados++

    # ======================================================
    # NOME DO ARQUIVO
    # ======================================================

    $NomeArquivo = [string]$Item.Name

    # ======================================================
    # TAMANHO
    # ======================================================

    $TamanhoBytes = 0

    if (-not [string]::IsNullOrWhiteSpace([string]$Item.Size))
    {
        $TamanhoBytes = [int64]$Item.Size
    }

    $TamanhoMB = [Math]::Round(
        ($TamanhoBytes / 1MB),
        2
    )

    # ======================================================
    # DIRETORIO
    # ======================================================

    $Diretorio = ""

    if (
        $Item.RemotePath -and
        $Item.RemotePath.Path -and
        -not [string]::IsNullOrWhiteSpace(
            [string]$Item.RemotePath.Path
        )
    )
    {
        $Diretorio = [string]$Item.RemotePath.Path
    }
    elseif (
        -not [string]::IsNullOrWhiteSpace(
            [string]$Item.Path
        )
    )
    {
        $Diretorio = [string]$Item.Path
    }

    # ======================================================
    # ULTIMO ACESSO
    # ======================================================

    $TextoDataAcesso = [string]$Item.LastAccessTimeString

    $DataAcesso = Convert-FsrmDate `
        -DateText $TextoDataAcesso `
        -OutputFormat $DateFormat

    if ([string]::IsNullOrWhiteSpace($DataAcesso))
    {
        $ArquivosSemData++
    }
    else
    {
        $ArquivosComData++
    }

    # ======================================================
    # TEMPO SEM ACESSO
    # ======================================================

    $DiasSemAcesso = 0

    if (
        -not [string]::IsNullOrWhiteSpace(
            [string]$Item.DaysSinceLastAccessed
        )
    )
    {
        $DiasSemAcesso = [int64]$Item.DaysSinceLastAccessed
    }

    $AnosSemAcesso = [Math]::Round(
        ($DiasSemAcesso / 365.25),
        2
    )

    # ======================================================
    # OBJETO DE SAIDA
    # ======================================================

    [PSCustomObject]@{

        TamanhoBytes = $TamanhoBytes

        DiasSemAcesso = $DiasSemAcesso

        NOME_ARQUIVO = $NomeArquivo

        TAMANHO_MB = $TamanhoMB.ToString($Culture)

        DIRETORIO = $Diretorio

        ACESSADO_EM = $DataAcesso

        ANOS_SEM_ACESSO = $AnosSemAcesso.ToString($Culture)

    }
}

# ==========================================================
# RESULTADO DO PROCESSAMENTO
# ==========================================================

Write-Host ("Arquivos processados...: {0:N0}" -f $ArquivosProcessados)
Write-Host ("Arquivos com data......: {0:N0}" -f $ArquivosComData)
Write-Host ("Arquivos sem data......: {0:N0}" -f $ArquivosSemData)
Write-Host ""

# ==========================================================
# ------------------- BLOCO 03 -----------------------------
# ==========================================================


# ==========================================================
# ORDENACAO
# ==========================================================

Write-Host "Ordenando resultados..."
Write-Host ""

$ResultadoFinal = $Resultado |
    Sort-Object `
        @{ Expression = "DiasSemAcesso"; Descending = $true },
        @{ Expression = "TamanhoBytes"; Descending = $true },
        @{ Expression = "NOME_ARQUIVO"; Ascending = $true } |
    Select-Object -First $TopN

# ==========================================================
# ESTATISTICAS GERAIS DA EXPORTACAO
# ==========================================================

$ArquivosExportados = @($ResultadoFinal).Count

$TotalBytesExportados = (
    $ResultadoFinal |
    Measure-Object -Property TamanhoBytes -Sum
).Sum

if ($null -eq $TotalBytesExportados)
{
    $TotalBytesExportados = 0
}

$TotalMBExportados = [Math]::Round(
    ($TotalBytesExportados / 1MB),
    2
)

# ==========================================================
# LIMITES DE TEMPO
# ==========================================================

$DiasTresAnos = [int][Math]::Floor(
    (365.25 * 3)
)

$DiasCincoAnos = [int][Math]::Floor(
    (365.25 * 5)
)

# ==========================================================
# ARQUIVOS ENTRE 3 E 5 ANOS
# ==========================================================

$ArquivosEntreTresECincoAnos = @(
    $ResultadoFinal |
    Where-Object {
        $_.DiasSemAcesso -ge $DiasTresAnos -and
        $_.DiasSemAcesso -lt $DiasCincoAnos
    }
)

$QuantidadeEntreTresECincoAnos = (
    $ArquivosEntreTresECincoAnos
).Count

$BytesEntreTresECincoAnos = (
    $ArquivosEntreTresECincoAnos |
    Measure-Object -Property TamanhoBytes -Sum
).Sum

if ($null -eq $BytesEntreTresECincoAnos)
{
    $BytesEntreTresECincoAnos = 0
}

$MBEntreTresECincoAnos = [Math]::Round(
    ($BytesEntreTresECincoAnos / 1MB),
    2
)

# ==========================================================
# ARQUIVOS COM 5 ANOS OU MAIS
# ==========================================================

$ArquivosCincoAnosOuMais = @(
    $ResultadoFinal |
    Where-Object {
        $_.DiasSemAcesso -ge $DiasCincoAnos
    }
)

$QuantidadeCincoAnosOuMais = (
    $ArquivosCincoAnosOuMais
).Count

$BytesCincoAnosOuMais = (
    $ArquivosCincoAnosOuMais |
    Measure-Object -Property TamanhoBytes -Sum
).Sum

if ($null -eq $BytesCincoAnosOuMais)
{
    $BytesCincoAnosOuMais = 0
}

$MBCincoAnosOuMais = [Math]::Round(
    ($BytesCincoAnosOuMais / 1MB),
    2
)

# ==========================================================
# ARQUIVOS COM MENOS DE 3 ANOS
# ==========================================================

$ArquivosMenosDeTresAnos = @(
    $ResultadoFinal |
    Where-Object {
        $_.DiasSemAcesso -lt $DiasTresAnos
    }
)

$QuantidadeMenosDeTresAnos = (
    $ArquivosMenosDeTresAnos
).Count

$BytesMenosDeTresAnos = (
    $ArquivosMenosDeTresAnos |
    Measure-Object -Property TamanhoBytes -Sum
).Sum

if ($null -eq $BytesMenosDeTresAnos)
{
    $BytesMenosDeTresAnos = 0
}

$MBMenosDeTresAnos = [Math]::Round(
    ($BytesMenosDeTresAnos / 1MB),
    2
)

# ==========================================================
# RESULTADO DAS ESTATISTICAS
# ==========================================================

Write-Host ("Arquivos exportados.........: {0:N0}" -f $ArquivosExportados)
Write-Host ("MB exportados...............: {0:N2}" -f $TotalMBExportados)
Write-Host ""

Write-Host ("Arquivos com menos de 3 anos: {0:N0}" -f $QuantidadeMenosDeTresAnos)
Write-Host ("MB com menos de 3 anos......: {0:N2}" -f $MBMenosDeTresAnos)
Write-Host ""

Write-Host ("Arquivos entre 3 e 5 anos...: {0:N0}" -f $QuantidadeEntreTresECincoAnos)
Write-Host ("MB entre 3 e 5 anos.........: {0:N2}" -f $MBEntreTresECincoAnos)
Write-Host ""

Write-Host ("Arquivos com 5 anos ou mais.: {0:N0}" -f $QuantidadeCincoAnosOuMais)
Write-Host ("MB com 5 anos ou mais.......: {0:N2}" -f $MBCincoAnosOuMais)
Write-Host ""

# ==========================================================
# ------------------- BLOCO 04 -----------------------------
# ==========================================================


# ==========================================================
# EXPORTACAO DO CSV
# ==========================================================

Write-Host "Exportando CSV..."
Write-Host ""

$ResultadoCSV = $ResultadoFinal |
    Select-Object `
        NOME_ARQUIVO,
        TAMANHO_MB,
        DIRETORIO,
        ACESSADO_EM,
        ANOS_SEM_ACESSO

$ResultadoCSV |
    Export-Csv `
        -Path $CsvPath `
        -Delimiter ";" `
        -NoTypeInformation `
        -Encoding UTF8

Write-Host ("CSV gerado com sucesso: {0}" -f $CsvPath)
Write-Host ""

# ==========================================================
# ------------------- BLOCO 05 -----------------------------
# ==========================================================


# ==========================================================
# TEMPO DE EXECUCAO
# ==========================================================

$EndTime = Get-Date

$ExecutionTime = $EndTime - $StartTime

$ExecutionTimeText = "{0:00}:{1:00}:{2:00}" -f `
    [Math]::Floor($ExecutionTime.TotalHours),
    $ExecutionTime.Minutes,
    $ExecutionTime.Seconds

# ==========================================================
# RESUMO FINAL
# ==========================================================

Write-Host ""
Write-Host "============================================================"
Write-Host "RESUMO"
Write-Host "============================================================"
Write-Host ""

Write-Host "TOTAL DA PASTA / CRITERIO FSRM"
Write-Host "------------------------------"
Write-Host ("Arquivos encontrados.....: {0:N0}" -f $TotalFilesFSRM)
Write-Host ("MB encontrados...........: {0:N2}" -f $TotalMBFSRM)
Write-Host ""

Write-Host "DADOS PRESENTES NO XML"
Write-Host "---------------------"
Write-Host ("Arquivos no XML..........: {0:N0}" -f $DisplayFiles)
Write-Host ("MB no XML................: {0:N2}" -f $DisplayMB)
Write-Host ""

Write-Host "DADOS PROCESSADOS"
Write-Host "----------------"
Write-Host ("Arquivos processados.....: {0:N0}" -f $ArquivosProcessados)
Write-Host ("Arquivos com data........: {0:N0}" -f $ArquivosComData)
Write-Host ("Arquivos sem data........: {0:N0}" -f $ArquivosSemData)
Write-Host ""

Write-Host "DADOS EXPORTADOS"
Write-Host "----------------"
Write-Host ("Arquivos exportados......: {0:N0}" -f $ArquivosExportados)
Write-Host ("MB exportados............: {0:N2}" -f $TotalMBExportados)
Write-Host ""

Write-Host ("Arquivos abaixo de 3 anos: {0:N0}" -f $QuantidadeMenosDeTresAnos)
Write-Host ("MB abaixo de 3 anos......: {0:N2}" -f $MBMenosDeTresAnos)
Write-Host ""

Write-Host ("Arquivos entre 3 e 5 anos: {0:N0}" -f $QuantidadeEntreTresECincoAnos)
Write-Host ("MB entre 3 e 5 anos......: {0:N2}" -f $MBEntreTresECincoAnos)
Write-Host ""

Write-Host ("Arquivos com 5 anos ou +.: {0:N0}" -f $QuantidadeCincoAnosOuMais)
Write-Host ("MB com 5 anos ou mais....: {0:N2}" -f $MBCincoAnosOuMais)
Write-Host ""

# ==========================================================
# AVISO METODOLOGICO
# ==========================================================

if ($Warnings.Count -gt 0)
{
    Write-Host "AVISO METODOLOGICO"
    Write-Host "------------------"
    Write-Host "O XML contem avisos emitidos pelo FSRM."
    Write-Host "Esses avisos devem ser considerados antes de utilizar"
    Write-Host "os dados de ultimo acesso para tomada de decisao."
    Write-Host ""
}

Write-Host "ARQUIVOS GERADOS"
Write-Host "----------------"
Write-Host ("CSV......................: {0}" -f $CsvPath)
Write-Host ("LOG......................: {0}" -f $LogPath)
Write-Host ("Tempo de execucao........: {0}" -f $ExecutionTimeText)
Write-Host ""
Write-Host "============================================================"
Write-Host "PROCESSAMENTO CONCLUIDO"
Write-Host "============================================================"
Write-Host ""

# ==========================================================
# ENCERRAMENTO DO LOG
# ==========================================================

if ($TranscriptAtivo)
{
    try
    {
        Stop-Transcript | Out-Null
    }
    catch
    {
        Write-Host "AVISO: Nao foi possivel encerrar o transcript corretamente."
    }
}


# ==========================================================
# ------------------- BLOCO 01 -----------------------------
# ==========================================================


# =====================================================================
# Script_XML_ArquivosGrandes_PADRAO_v1.ps1
#
# Objetivo:
#   Interpretar o XML gerado pelo FSRM
#   (Large Files Report)
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

$XmlFile = "C:\Temp_Marcio\AZURE\azure-platform-bootstrap\SPGG_FS01\LargeFiles344_2026-11-12_12-30-15.xml"

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
        "dd/MM/yyyy",
        "MM/dd/yyyy HH:mm:ss",
        "MM/dd/yyyy H:mm:ss",
        "MM/dd/yyyy",
        "yyyy-MM-ddTHH:mm:ss",
        "yyyy-MM-dd HH:mm:ss"
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

if (!(Test-Path -Path $XmlFile))
{
    throw "Arquivo XML nao encontrado: $XmlFile"
}

if (!(Test-Path -Path $OutputDir))
{
    New-Item `
        -ItemType Directory `
        -Path $OutputDir `
        -Force |
        Out-Null
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

# ==========================================================
# INFORMACOES DO CABECALHO
# ==========================================================

$Machine = [string]$Header.MachineName

$GeneratedAt = [string]$Header.GeneratedAt

$FilesCount = [int64]$Header.FilesCount

$MaxDisplayItems = [int64]$Header.MaxDisplayItems

$ReportType = [string]$Header.Type

# ==========================================================
# VALIDACAO DO TIPO DE RELATORIO
# ==========================================================

if (
    -not [string]::IsNullOrWhiteSpace($ReportType) -and
    $ReportType -ne "FsrmReportType_LargeFiles"
)
{
    throw (
        "O XML informado nao corresponde a um relatorio Large Files. " +
        "Tipo encontrado: " +
        $ReportType
    )
}

# ==========================================================
# NAMESPACE
# ==========================================================

if ($Header.ReportNamespaces.Namespace -is [System.Array])
{
    $Namespace = [string](
        $Header.ReportNamespaces.Namespace[0].InnerText
    )
}
else
{
    $Namespace = [string](
        $Header.ReportNamespaces.Namespace.InnerText
    )
}

if ([string]::IsNullOrWhiteSpace($Namespace))
{
    $Namespace = [string]$Header.ReportNamespaces.Namespace
}

if ([string]::IsNullOrWhiteSpace($Namespace))
{
    $Namespace = "ROOT"
}
else
{
    $Namespace = $Namespace.Trim()
}

$FolderName = Split-Path -Path $Namespace -Leaf

if ([string]::IsNullOrWhiteSpace($FolderName))
{
    $FolderName = "ROOT"
}

# Remove caracteres inadequados para nomes de arquivo

$InvalidFileNameCharacters = [System.IO.Path]::GetInvalidFileNameChars()

foreach ($InvalidCharacter in $InvalidFileNameCharacters)
{
    $FolderName = $FolderName.Replace(
        [string]$InvalidCharacter,
        "_"
    )
}

# ==========================================================
# FILTRO DE TAMANHO MINIMO
# ==========================================================

$MinimumFileSizeText = ""

$MinimumFileSizeBytes = 0

if (
    $Header.ReportFilters -and
    $Header.ReportFilters.Filter
)
{
    foreach ($Filter in @($Header.ReportFilters.Filter))
    {
        if ([string]$Filter.Name -eq "Minimum file size")
        {
            $MinimumFileSizeText = [string]$Filter.Value

            if (
                -not [string]::IsNullOrWhiteSpace(
                    [string]$Filter.ValueEx
                )
            )
            {
                $MinimumFileSizeBytes = [int64]$Filter.ValueEx
            }

            break
        }
    }
}

$MinimumFileSizeMB = [Math]::Round(
    ($MinimumFileSizeBytes / 1MB),
    2
)

# ==========================================================
# AVISOS DO FSRM
# ==========================================================

if (
    $Header.ReportWarnings -and
    $Header.ReportWarnings.Warning
)
{
    $Warnings = @(
        $Header.ReportWarnings.Warning
    )
}
else
{
    $Warnings = @()
}

# ==========================================================
# TOTAIS DO RELATORIO
# ==========================================================

$ReportSummary = $Xml.StorageReport.ReportSummary

if ($null -eq $ReportSummary)
{
    throw "ReportSummary nao encontrado no XML."
}

$ReportTotals = $ReportSummary.ReportTotals

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
# ITENS PRESENTES NO XML
# ==========================================================

$ItensXML = @(
    $Xml.StorageReport.ReportData.Item
)

$ItensNoXML = $ItensXML.Count

# ==========================================================
# ARQUIVOS DE SAIDA
# ==========================================================

$Today = Get-Date -Format "yyyyMMdd"

$CsvPath = Join-Path `
    -Path $OutputDir `
    -ChildPath (
        $Today +
        "_arquivos_grandes_csv_" +
        $FolderName +
        ".csv"
    )

$LogPath = Join-Path `
    -Path $OutputDir `
    -ChildPath (
        $Today +
        "_arquivos_grandes_log_" +
        $FolderName +
        ".txt"
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
    Start-Transcript `
        -Path $LogPath `
        -Force |
        Out-Null

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
Write-Host "RELATORIO - ARQUIVOS GRANDES (FSRM XML)"
Write-Host "============================================================"
Write-Host ("XML....................: {0}" -f $XmlFile)
Write-Host ("Servidor...............: {0}" -f $Machine)
Write-Host ("Pasta..................: {0}" -f $Namespace)
Write-Host ("Data relatorio.........: {0}" -f $GeneratedAt)

if (-not [string]::IsNullOrWhiteSpace($MinimumFileSizeText))
{
    Write-Host ("Tamanho minimo FSRM....: {0}" -f $MinimumFileSizeText)
}
elseif ($MinimumFileSizeBytes -gt 0)
{
    Write-Host ("Tamanho minimo FSRM....: {0:N2} MB" -f $MinimumFileSizeMB)
}

Write-Host ("Arquivos encontrados...: {0:N0}" -f $TotalFilesFSRM)
Write-Host ("MB encontrados.........: {0:N2}" -f $TotalMBFSRM)
Write-Host ("Max itens no XML.......: {0:N0}" -f $MaxDisplayItems)
Write-Host ("Itens identificados....: {0:N0}" -f $ItensNoXML)
Write-Host ("Arquivos no XML........: {0:N0}" -f $DisplayFiles)
Write-Host ("MB no XML..............: {0:N2}" -f $DisplayMB)
Write-Host ("Limite do CSV..........: {0:N0}" -f $TopN)
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
# LEITURA DOS ARQUIVOS
# ==========================================================

Write-Host "Lendo arquivos do XML..."
Write-Host ""

$ArquivosProcessados = 0

$ArquivosComDataAcesso = 0

$ArquivosSemDataAcesso = 0

$ArquivosComDataModificacao = 0

$ArquivosSemDataModificacao = 0

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

    if (
        -not [string]::IsNullOrWhiteSpace(
            [string]$Item.Size
        )
    )
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
        $ArquivosSemDataAcesso++
    }
    else
    {
        $ArquivosComDataAcesso++
    }

    # ======================================================
    # ULTIMA MODIFICACAO
    # ======================================================

    $TextoDataModificacao = [string]$Item.LastModificationTimeString

    $DataModificacao = Convert-FsrmDate `
        -DateText $TextoDataModificacao `
        -OutputFormat $DateFormat

    if ([string]::IsNullOrWhiteSpace($DataModificacao))
    {
        $ArquivosSemDataModificacao++
    }
    else
    {
        $ArquivosComDataModificacao++
    }

    # ======================================================
    # DIAS SEM ACESSO
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

    # ======================================================
    # DIAS SEM MODIFICACAO
    # ======================================================

    $DiasSemModificacao = 0

    if (
        -not [string]::IsNullOrWhiteSpace(
            [string]$Item.DaysSinceLastModified
        )
    )
    {
        $DiasSemModificacao = [int64]$Item.DaysSinceLastModified
    }

    # ======================================================
    # OBJETO DE SAIDA
    # ======================================================

    [PSCustomObject]@{

        # Campos tecnicos (nao exportados)

        TamanhoBytes = $TamanhoBytes

        # Campos do CSV

        NOME_ARQUIVO = $NomeArquivo

        TAMANHO_MB = $TamanhoMB.ToString($Culture)

        DIRETORIO = $Diretorio

        ACESSADO_EM = $DataAcesso

        MODIFICADO_EM = $DataModificacao

        DIAS_SEM_ACESSO = $DiasSemAcesso

        DIAS_SEM_MODIFICACAO = $DiasSemModificacao

    }
}

# ==========================================================
# RESULTADO DO PROCESSAMENTO
# ==========================================================

Write-Host ("Arquivos processados........: {0:N0}" -f $ArquivosProcessados)
Write-Host ("Com data de acesso..........: {0:N0}" -f $ArquivosComDataAcesso)
Write-Host ("Sem data de acesso..........: {0:N0}" -f $ArquivosSemDataAcesso)
Write-Host ("Com data de modificacao.....: {0:N0}" -f $ArquivosComDataModificacao)
Write-Host ("Sem data de modificacao.....: {0:N0}" -f $ArquivosSemDataModificacao)
Write-Host ""

# ==========================================================
# ------------------- BLOCO 03 -----------------------------
# ==========================================================


# ==========================================================
# VALIDACAO DO RESULTADO
# ==========================================================

$Resultado = @($Resultado)

if ($Resultado.Count -eq 0)
{
    Write-Host "Nenhum arquivo foi encontrado para exportacao."
    Write-Host ""

    $ResultadoFinal = @()
}
else
{
    # ======================================================
    # ORDENACAO
    # ======================================================

    Write-Host "Ordenando arquivos por maior tamanho..."
    Write-Host ""

    $ResultadoFinal = @(
        $Resultado |
        Sort-Object `
            -Property TamanhoBytes `
            -Descending |
        Select-Object -First $TopN
    )
}

# ==========================================================
# ESTATISTICAS DOS ARQUIVOS EXPORTADOS
# ==========================================================

$ArquivosExportados = $ResultadoFinal.Count

$TotalBytesExportado = 0

if ($ArquivosExportados -gt 0)
{
    $TotalBytesExportado = [int64](
        (
            $ResultadoFinal |
            Measure-Object `
                -Property TamanhoBytes `
                -Sum
        ).Sum
    )
}

$TotalMBExportado = [Math]::Round(
    ($TotalBytesExportado / 1MB),
    2
)

$TotalGBExportado = [Math]::Round(
    ($TotalBytesExportado / 1GB),
    2
)

# ==========================================================
# FAIXAS DE TAMANHO
# ==========================================================

$ArquivosAte500MB = @(
    $ResultadoFinal |
    Where-Object {
        $_.TamanhoBytes -lt 500MB
    }
).Count

$ArquivosEntre500MBe1GB = @(
    $ResultadoFinal |
    Where-Object {
        $_.TamanhoBytes -ge 500MB -and
        $_.TamanhoBytes -lt 1GB
    }
).Count

$ArquivosAcima1GB = @(
    $ResultadoFinal |
    Where-Object {
        $_.TamanhoBytes -ge 1GB
    }
).Count

# ==========================================================
# MAIOR ARQUIVO
# ==========================================================

$MaiorArquivo = $null

if ($ArquivosExportados -gt 0)
{
    $MaiorArquivo = $ResultadoFinal[0]
}

# ==========================================================
# ARQUIVOS ANTIGOS
# ==========================================================

$ArquivosSemAcesso1Ano = @(
    $ResultadoFinal |
    Where-Object {
        $_.DIAS_SEM_ACESSO -ge 365
    }
).Count

$ArquivosSemAcesso3Anos = @(
    $ResultadoFinal |
    Where-Object {
        $_.DIAS_SEM_ACESSO -ge 1095
    }
).Count

$ArquivosSemModificacao1Ano = @(
    $ResultadoFinal |
    Where-Object {
        $_.DIAS_SEM_MODIFICACAO -ge 365
    }
).Count

$ArquivosSemModificacao3Anos = @(
    $ResultadoFinal |
    Where-Object {
        $_.DIAS_SEM_MODIFICACAO -ge 1095
    }
).Count

# ==========================================================
# RESUMO DO RESULTADO
# ==========================================================

Write-Host "============================================================"
Write-Host "RESUMO DOS ARQUIVOS SELECIONADOS"
Write-Host "============================================================"
Write-Host ("Arquivos processados.............: {0:N0}" -f $Resultado.Count)
Write-Host ("Arquivos exportados..............: {0:N0}" -f $ArquivosExportados)
Write-Host ("Tamanho total exportado MB.......: {0:N2}" -f $TotalMBExportado)
Write-Host ("Tamanho total exportado GB.......: {0:N2}" -f $TotalGBExportado)
Write-Host ("Arquivos abaixo de 500 MB........: {0:N0}" -f $ArquivosAte500MB)
Write-Host ("Arquivos entre 500 MB e 1 GB.....: {0:N0}" -f $ArquivosEntre500MBe1GB)
Write-Host ("Arquivos com 1 GB ou mais........: {0:N0}" -f $ArquivosAcima1GB)
Write-Host ("Sem acesso ha 1 ano ou mais......: {0:N0}" -f $ArquivosSemAcesso1Ano)
Write-Host ("Sem acesso ha 3 anos ou mais.....: {0:N0}" -f $ArquivosSemAcesso3Anos)
Write-Host ("Sem modificacao ha 1 ano ou mais.: {0:N0}" -f $ArquivosSemModificacao1Ano)
Write-Host ("Sem modificacao ha 3 anos ou mais: {0:N0}" -f $ArquivosSemModificacao3Anos)

if ($null -ne $MaiorArquivo)
{
    Write-Host ""
    Write-Host "MAIOR ARQUIVO:"
    Write-Host ("Nome.........................: {0}" -f $MaiorArquivo.NOME_ARQUIVO)
    Write-Host ("Tamanho MB...................: {0}" -f $MaiorArquivo.TAMANHO_MB)
    Write-Host ("Diretorio....................: {0}" -f $MaiorArquivo.DIRETORIO)
}

Write-Host "============================================================"
Write-Host ""

# ==========================================================
# ------------------- BLOCO 04 -----------------------------
# ==========================================================


# ==========================================================
# PREPARACAO DAS COLUNAS DO CSV
# ==========================================================

Write-Host "Preparando dados para exportacao..."
Write-Host ""

$DadosCSV = @(
    $ResultadoFinal |
    Select-Object `
        NOME_ARQUIVO,
        TAMANHO_MB,
        DIRETORIO,
        ACESSADO_EM,
        MODIFICADO_EM,
        DIAS_SEM_ACESSO,
        DIAS_SEM_MODIFICACAO
)

# ==========================================================
# EXPORTACAO DO CSV
# ==========================================================

if ($DadosCSV.Count -gt 0)
{
    try
    {
        $DadosCSV |
        Export-Csv `
            -Path $CsvPath `
            -Delimiter ";" `
            -NoTypeInformation `
            -Encoding UTF8

        Write-Host "CSV exportado com sucesso."
        Write-Host ("Arquivo.................: {0}" -f $CsvPath)
        Write-Host ("Linhas exportadas.......: {0:N0}" -f $DadosCSV.Count)
        Write-Host ""
    }
    catch
    {
        Write-Host "ERRO AO EXPORTAR O CSV:"
        Write-Host $_.Exception.Message
        Write-Host ""

        throw
    }
}
else
{
    Write-Host "Nenhum registro disponivel para exportacao."
    Write-Host "O arquivo CSV nao foi criado."
    Write-Host ""
}

# ==========================================================
# ------------------- BLOCO 05 -----------------------------
# ==========================================================


# ==========================================================
# TEMPO TOTAL DE EXECUCAO
# ==========================================================

$EndTime = Get-Date

$Elapsed = $EndTime - $StartTime

# ==========================================================
# RESUMO FINAL
# ==========================================================

Write-Host ""
Write-Host "============================================================"
Write-Host "PROCESSAMENTO FINALIZADO"
Write-Host "============================================================"

Write-Host ("Servidor....................: {0}" -f $Machine)
Write-Host ("Pasta.......................: {0}" -f $Namespace)
Write-Host ("Data do relatorio...........: {0}" -f $GeneratedAt)

Write-Host ""

Write-Host ("Arquivos encontrados FSRM...: {0:N0}" -f $TotalFilesFSRM)
Write-Host ("Arquivos presentes no XML...: {0:N0}" -f $ItensNoXML)
Write-Host ("Arquivos exportados.........: {0:N0}" -f $ArquivosExportados)

Write-Host ""

Write-Host ("Total MB encontrados........: {0:N2}" -f $TotalMBFSRM)
Write-Host ("Total MB exportados.........: {0:N2}" -f $TotalMBExportado)

Write-Host ""

Write-Host ("CSV.........................: {0}" -f $CsvPath)

if ($TranscriptAtivo)
{
    Write-Host ("LOG.........................: {0}" -f $LogPath)
}
else
{
    Write-Host "LOG.........................: Nao gerado (arquivo em uso)"
}

Write-Host ""

Write-Host ("Tempo total................: {0:hh\:mm\:ss}" -f $Elapsed)

Write-Host "============================================================"

# ==========================================================
# AVISOS DO FSRM
# ==========================================================

if ($Warnings.Count -gt 0)
{
    Write-Host ""
    Write-Host "AVISOS DO FSRM"
    Write-Host "------------------------------------------------------------"

    foreach ($Warning in $Warnings)
    {
        Write-Host ("- {0}" -f [string]$Warning)
    }

    Write-Host "------------------------------------------------------------"
}

Write-Host ""
Write-Host "Script concluido com sucesso."
Write-Host ""

# ==========================================================
# ENCERRAMENTO DO TRANSCRIPT
# ==========================================================

if ($TranscriptAtivo)
{
    try
    {
        Stop-Transcript | Out-Null
    }
    catch
    {
    }
}
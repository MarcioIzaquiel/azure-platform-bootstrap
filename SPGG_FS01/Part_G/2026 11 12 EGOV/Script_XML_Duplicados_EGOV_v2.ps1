# ==========================================================
# ------------------- BLOCO 01 -----------------------------
# ==========================================================


# =====================================================================
# Script_XML_Duplicados_PADRAO_v1.ps1
#
# Objetivo:
#   Interpretar o XML gerado pelo FSRM (Duplicate Files)
#   e gerar um CSV padronizado para analise.
#
# Padrao Corporativo v1.0
# =====================================================================

Clear-Host
$ErrorActionPreference = "Stop"

# ==========================================================
# CONFIGURACAO
# ==========================================================

# Arquivo XML exportado pelo FSRM

$XmlFile = "C:\Temp_Marcio\AZURE\azure-platform-bootstrap\SPGG_FS01\DuplicateFiles334_2026-11-12_12-27-26.xml"

# Pasta de saida

$OutputDir = "C:\Temp_Marcio\FS_Scripts"

# Quantidade maxima de linhas do CSV

$TopN = 1000

# Cultura para utilizar "." como separador decimal

$Culture = [System.Globalization.CultureInfo]::InvariantCulture

# Formato das datas

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

[xml]$Xml = Get-Content $XmlFile

$Header = $Xml.StorageReport.ReportHeader

$Machine = [string]$Header.MachineName

$GeneratedAt = [string]$Header.GeneratedAt

$GroupsCount = [int64]$Header.MaxGroups

$FilesCount = [int64]$Header.FilesCount

$MaxFilesPerGroup = [int64]$Header.MaxFilesPerGroup

# Namespace

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

$FolderName = Split-Path $Namespace -Leaf

# Avisos do FSRM

if ($Header.ReportWarnings -and $Header.ReportWarnings.Warning)
{
    $Warnings = $Header.ReportWarnings.Warning
}
else
{
    $Warnings = @()
}

# ==========================================================
# TOTAIS DO RELATORIO
# ==========================================================

$ReportTotals = $Xml.StorageReport.ReportSummary.ReportTotals

$NamespaceTotals = $Xml.StorageReport.ReportSummary.NamespaceTotals

$NamespaceDuplicateGroups = [int64]$NamespaceTotals.DuplicateGroups

$NamespaceFiles = [int64]$NamespaceTotals.FileCount

$NamespaceBytes = [int64]$NamespaceTotals.Size

$NamespaceWastedBytes = [int64]$NamespaceTotals.WastedSpace

$NamespaceMB = [Math]::Round(($NamespaceBytes / 1MB),2)

$NamespaceWastedMB = [Math]::Round(($NamespaceWastedBytes / 1MB),2)

# Arquivos de saida

$Today = Get-Date -Format "yyyyMMdd"

$CsvPath = Join-Path $OutputDir ($Today + "_duplicados_csv_" + $FolderName + ".csv")

$LogPath = Join-Path $OutputDir ($Today + "_duplicados_log_" + $FolderName + ".txt")

# ==========================================================
# INICIO DO LOG
# ==========================================================

Start-Transcript -Path $LogPath | Out-Null

$StartTime = Get-Date

Write-Host ""
Write-Host "============================================================"
Write-Host "RELATORIO - DUPLICADOS (FSRM XML)"
Write-Host "============================================================"
Write-Host ("XML..................: {0}" -f $XmlFile)
Write-Host ("Servidor............ : {0}" -f $Machine)
Write-Host ("Pasta............... : {0}" -f $Namespace)
Write-Host ("Data Relatorio...... : {0}" -f $GeneratedAt)
Write-Host ("Grupos encontrados..: {0:N0}" -f $GroupsCount)
Write-Host ("Arquivos encontrados: {0:N0}" -f $FilesCount)
Write-Host ("Max grupos..........: {0:N0}" -f $GroupsCount)
Write-Host ("Max arquivos/grupo..: {0:N0}" -f $MaxFilesPerGroup)
Write-Host ("CSV................ : {0}" -f $CsvPath)
Write-Host ("LOG................ : {0}" -f $LogPath)
Write-Host "============================================================"
Write-Host ""

if ($Warnings)
{
    Write-Host "Avisos do FSRM:"
    Write-Host ""

    foreach ($Warning in $Warnings)
    {
        Write-Host (" - {0}" -f $Warning)
    }

    Write-Host ""
}

# ==========================================================
# ------------------- BLOCO 02 -----------------------------
# ==========================================================

# ==========================================================
# LEITURA DOS DUPLICADOS
# ==========================================================

Write-Host "Lendo grupos de duplicados..."
Write-Host ""

$GruposProcessados = 0
$ArquivosProcessados = 0

$Resultado = foreach ($Group in $Xml.StorageReport.ReportData.DuplicateGroup)
{

    $GruposProcessados++

    $GrupoID = "G{0:D5}" -f $GruposProcessados

    $QtdNoGrupo = [int]$Group.FileCount

    $EspacoDesperdicadoBytes = [int64]$Group.WastedSpace

    $EspacoDesperdicadoMB = [Math]::Round(($EspacoDesperdicadoBytes / 1MB),2)

    foreach ($File in $Group.DuplicateFile)
    {

        $ArquivosProcessados++

        # O tamanho pertence ao grupo, nao ao DuplicateFile

		$TamanhoBytes = [int64]$Group.FileSize

		$TamanhoMB = [Math]::Round(($TamanhoBytes / 1MB),2)

		$DataAcesso = Convert-FsrmDate `
			-DateText ([string]$File.LastAccessTime) `
			-OutputFormat $DateFormat

        [PSCustomObject]@{

            # Campos tecnicos

            EspacoDesperdicadoBytes = $EspacoDesperdicadoBytes

            TamanhoBytes = $TamanhoBytes

            # Campos do CSV

            GRUPO_ID = $GrupoID

            QTD_NO_GRUPO = $QtdNoGrupo

            ESPACO_DESPERDICADO_MB = $EspacoDesperdicadoMB.ToString($Culture)

            NOME_ARQUIVO = [string]$File.Name

            TAMANHO_MB = $TamanhoMB.ToString($Culture)

			DIRETORIO = $File.RemotePath.Path

            ACESSADO_EM = $DataAcesso

        }

    }

}

Write-Host ("Grupos processados...: {0:N0}" -f $GruposProcessados)

Write-Host ("Arquivos processados.: {0:N0}" -f $ArquivosProcessados)

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
        @{ Expression = "EspacoDesperdicadoBytes"; Descending = $true },
        @{ Expression = "TamanhoBytes"; Descending = $true },
        @{ Expression = "QTD_NO_GRUPO"; Descending = $true } |
    Select-Object -First $TopN

# ==========================================================
# ESTATISTICAS
# ==========================================================

$ArquivosExportados = @($ResultadoFinal).Count

$GruposExportados = (
    $ResultadoFinal |
    Select-Object -ExpandProperty GRUPO_ID -Unique
).Count

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
# ESPACO DESPERDICADO
# ==========================================================

$TotalBytesDesperdicados = (
    $ResultadoFinal |
    Select-Object `
        GRUPO_ID,
        EspacoDesperdicadoBytes |
    Sort-Object GRUPO_ID -Unique |
    Measure-Object `
        -Property EspacoDesperdicadoBytes `
        -Sum
).Sum

if ($null -eq $TotalBytesDesperdicados)
{
    $TotalBytesDesperdicados = 0
}

$TotalMBDesperdicados = [Math]::Round(
    ($TotalBytesDesperdicados / 1MB),
    2
)

Write-Host ("Grupos exportados....: {0:N0}" -f $GruposExportados)

Write-Host ("Arquivos exportados..: {0:N0}" -f $ArquivosExportados)

Write-Host ("MB exportados........: {0:N2}" -f $TotalMBExportados)

Write-Host ("MB desperdicados.....: {0:N2}" -f $TotalMBDesperdicados)

Write-Host ""

# ==========================================================
# ------------------- BLOCO 04 -----------------------------
# ==========================================================

# ==========================================================
# EXPORTACAO CSV
# ==========================================================

Write-Host "Gerando arquivo CSV..."
Write-Host ""

$ResultadoFinal |
Select-Object `
    GRUPO_ID,
    QTD_NO_GRUPO,
    ESPACO_DESPERDICADO_MB,
    NOME_ARQUIVO,
    TAMANHO_MB,
    DIRETORIO,
    ACESSADO_EM |
Export-Csv `
    -Path $CsvPath `
    -Delimiter ";" `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host ("Arquivo CSV..........: {0}" -f $CsvPath)
Write-Host ("Registros exportados.: {0:N0}" -f $ArquivosExportados)
Write-Host ""

# ==========================================================
# ------------------- BLOCO 05 -----------------------------
# ==========================================================

Write-Host ""
Write-Host "============================================================"
Write-Host "RESUMO"
Write-Host "============================================================"

Write-Host ""
Write-Host "TOTAL DO COMPARTILHAMENTO"
Write-Host "-------------------------"

Write-Host ("Grupos existentes.......: {0:N0}" -f $NamespaceDuplicateGroups)

Write-Host ("Arquivos existentes.....: {0:N0}" -f $NamespaceFiles)

Write-Host ("MB totais...............: {0:N2}" -f $NamespaceMB)

Write-Host ("MB desperdicados........: {0:N2}" -f $NamespaceWastedMB)

Write-Host ""

Write-Host "DADOS EXPORTADOS"
Write-Host "----------------"

Write-Host ("Grupos exportados.......: {0:N0}" -f $GruposExportados)

Write-Host ("Arquivos exportados.....: {0:N0}" -f $ArquivosExportados)

Write-Host ("MB exportados...........: {0:N2}" -f $TotalMBExportados)

Write-Host ("MB desperdicados........: {0:N2}" -f $TotalMBDesperdicados)

Write-Host ""

Write-Host ("Tempo de execucao.......: {0}" -f $TempoExecucao)

Write-Host ""

Write-Host ("CSV.....................: {0}" -f $CsvPath)

Write-Host ("LOG.....................: {0}" -f $LogPath)

Write-Host "============================================================"
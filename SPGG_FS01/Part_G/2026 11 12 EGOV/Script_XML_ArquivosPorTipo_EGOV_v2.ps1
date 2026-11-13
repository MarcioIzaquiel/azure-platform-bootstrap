# ==========================================================
# ------------------- BLOCO 01 -----------------------------
# ==========================================================


# =====================================================================
# Script_XML_ArquivosPorTipo_PADRAO_v3.ps1
#
# Objetivo:
#   Interpretar o XML gerado pelo FSRM
#   (Files by Type)
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

$XmlFile = "C:\Temp_Marcio\AZURE\azure-platform-bootstrap\SPGG_FS01\FilesByType335_2026-11-12_12-27-26.xml"

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

$MaxGroups = [int64]$Header.MaxGroups

$MaxFilesPerGroup = [int64]$Header.MaxFilesPerGroup

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

# Total de todos os arquivos que atenderam aos criterios

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
# GRUPOS PRESENTES NO XML
# ==========================================================

$GroupsXML = @(
    $Xml.StorageReport.ReportGroupData
)

$DisplayGroups = $GroupsXML.Count

# ==========================================================
# ARQUIVOS DE SAIDA
# ==========================================================

$Today = Get-Date -Format "yyyyMMdd"

$CsvPath = Join-Path `
    -Path $OutputDir `
    -ChildPath (
        $Today +
        "_arquivos_por_tipo_csv_" +
        $FolderName +
        ".csv"
    )

$LogPath = Join-Path `
    -Path $OutputDir `
    -ChildPath (
        $Today +
        "_arquivos_por_tipo_log_" +
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
Write-Host "RELATORIO - ARQUIVOS POR TIPO (FSRM XML)"
Write-Host "============================================================"
Write-Host ("XML....................: {0}" -f $XmlFile)
Write-Host ("Servidor...............: {0}" -f $Machine)
Write-Host ("Pasta..................: {0}" -f $Namespace)
Write-Host ("Data relatorio.........: {0}" -f $GeneratedAt)
Write-Host ("Arquivos encontrados...: {0:N0}" -f $TotalFilesFSRM)
Write-Host ("MB encontrados.........: {0:N2}" -f $TotalMBFSRM)
Write-Host ("Max grupos.............: {0:N0}" -f $MaxGroups)
Write-Host ("Max arquivos por grupo.: {0:N0}" -f $MaxFilesPerGroup)
Write-Host ("Grupos no XML..........: {0:N0}" -f $DisplayGroups)
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
# LEITURA DOS GRUPOS E ARQUIVOS
# ==========================================================

Write-Host "Lendo grupos e arquivos do XML..."
Write-Host ""

$GruposProcessados = 0

$ArquivosProcessados = 0

$ArquivosComData = 0

$ArquivosSemData = 0

$TotalBytesGrupos = 0

# ==========================================================
# PROCESSAMENTO DOS GRUPOS
# ==========================================================

$Resultado = foreach ($Group in $GroupsXML)
{
    $GruposProcessados++

    # ======================================================
    # INFORMACOES DO GRUPO
    # ======================================================

    $GrupoFSRM = [string]$Group.Name

    if ([string]::IsNullOrWhiteSpace($GrupoFSRM))
    {
        $GrupoFSRM = "SEM_GRUPO"
    }

    $QtdNoGrupo = 0

    if (
        -not [string]::IsNullOrWhiteSpace(
            [string]$Group.FileCount
        )
    )
    {
        $QtdNoGrupo = [int64]$Group.FileCount
    }

    $BytesGrupo = 0

    if (
        -not [string]::IsNullOrWhiteSpace(
            [string]$Group.Size
        )
    )
    {
        $BytesGrupo = [int64]$Group.Size
    }

    $TotalBytesGrupos += $BytesGrupo

    $MBGrupo = [Math]::Round(
        ($BytesGrupo / 1MB),
        2
    )

    # ======================================================
    # LEITURA DOS ARQUIVOS DO GRUPO
    # ======================================================

    $ItensGrupo = @($Group.Item)

    foreach ($File in $ItensGrupo)
    {
        $ArquivosProcessados++

        # ==================================================
        # NOME DO ARQUIVO
        # ==================================================

        $NomeArquivo = [string]$File.Name

        # ==================================================
        # TAMANHO DO ARQUIVO
        # ==================================================

        $TamanhoBytes = 0

        if (
            -not [string]::IsNullOrWhiteSpace(
                [string]$File.Size
            )
        )
        {
            $TamanhoBytes = [int64]$File.Size
        }

        $TamanhoMB = [Math]::Round(
            ($TamanhoBytes / 1MB),
            2
        )

        # ==================================================
        # DIRETORIO
        # ==================================================

        $Diretorio = ""

        if (
            $File.RemotePath -and
            $File.RemotePath.Path -and
            -not [string]::IsNullOrWhiteSpace(
                [string]$File.RemotePath.Path
            )
        )
        {
            $Diretorio = [string]$File.RemotePath.Path
        }
        elseif (
            -not [string]::IsNullOrWhiteSpace(
                [string]$File.Path
            )
        )
        {
            $Diretorio = [string]$File.Path
        }

        # ==================================================
        # DATA DO ULTIMO ACESSO
        # ==================================================

        $TextoDataAcesso = [string]$File.LastAccessTimeString

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

        # ==================================================
        # EXTENSAO DO ARQUIVO
        # ==================================================

        $Extensao = [System.IO.Path]::GetExtension(
            $NomeArquivo
        )

        if ([string]::IsNullOrWhiteSpace($Extensao))
        {
            $Extensao = "SEM_EXTENSAO"
        }
        else
        {
            $Extensao = $Extensao.TrimStart(".").ToUpper()
        }

        # ==================================================
        # OBJETO DE SAIDA
        # ==================================================

        [PSCustomObject]@{

            TamanhoBytes = $TamanhoBytes

            BytesGrupo = $BytesGrupo

            GRUPO_FSRM = $GrupoFSRM

            QTD_NO_GRUPO = $QtdNoGrupo

            TAMANHO_GRUPO_MB = $MBGrupo.ToString($Culture)

            NOME_ARQUIVO = $NomeArquivo

            EXTENSAO = $Extensao

            TAMANHO_MB = $TamanhoMB.ToString($Culture)

            DIRETORIO = $Diretorio

            ACESSADO_EM = $DataAcesso

        }
    }
}

# ==========================================================
# RESULTADO DO PROCESSAMENTO
# ==========================================================

$TotalMBGrupos = [Math]::Round(
    ($TotalBytesGrupos / 1MB),
    2
)

Write-Host ("Grupos processados.....: {0:N0}" -f $GruposProcessados)
Write-Host ("Arquivos processados...: {0:N0}" -f $ArquivosProcessados)
Write-Host ("Arquivos com data......: {0:N0}" -f $ArquivosComData)
Write-Host ("Arquivos sem data......: {0:N0}" -f $ArquivosSemData)
Write-Host ("MB somados nos grupos..: {0:N2}" -f $TotalMBGrupos)
Write-Host ""

# ==========================================================
# ------------------- BLOCO 03 -----------------------------
# ==========================================================


# ==========================================================
# ORDENACAO
# ==========================================================

Write-Host "Ordenando resultados..."
Write-Host ""

$ResultadoFinal = @(
    $Resultado |
    Sort-Object `
        @{ Expression = "TamanhoBytes"; Descending = $true },
        @{ Expression = "GRUPO_FSRM"; Ascending = $true },
        @{ Expression = "NOME_ARQUIVO"; Ascending = $true } |
    Select-Object -First $TopN
)

# ==========================================================
# ESTATISTICAS GERAIS DA EXPORTACAO
# ==========================================================

$ArquivosExportados = $ResultadoFinal.Count

$TotalBytesExportados = (
    $ResultadoFinal |
    Measure-Object `
        -Property TamanhoBytes `
        -Sum
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
# GRUPOS EXPORTADOS
# ==========================================================

$GruposExportados = @(
    $ResultadoFinal |
    Select-Object `
        -ExpandProperty GRUPO_FSRM `
        -Unique
)

$QuantidadeGruposExportados = $GruposExportados.Count

# ==========================================================
# EXTENSOES EXPORTADAS
# ==========================================================

$ExtensoesExportadas = @(
    $ResultadoFinal |
    Select-Object `
        -ExpandProperty EXTENSAO `
        -Unique
)

$QuantidadeExtensoesExportadas = $ExtensoesExportadas.Count

# ==========================================================
# ESTATISTICAS POR GRUPO
# ==========================================================

$ResumoPorGrupo = @(
    $ResultadoFinal |
    Group-Object -Property GRUPO_FSRM |
    ForEach-Object {

        $ItensDoGrupo = @($_.Group)

        $QuantidadeArquivosGrupo = $ItensDoGrupo.Count

        $BytesExportadosGrupo = (
            $ItensDoGrupo |
            Measure-Object `
                -Property TamanhoBytes `
                -Sum
        ).Sum

        if ($null -eq $BytesExportadosGrupo)
        {
            $BytesExportadosGrupo = 0
        }

        $MBExportadosGrupo = [Math]::Round(
            ($BytesExportadosGrupo / 1MB),
            2
        )

        $QuantidadeTotalGrupo = 0

        if ($ItensDoGrupo.Count -gt 0)
        {
            $QuantidadeTotalGrupo = [int64](
                $ItensDoGrupo[0].QTD_NO_GRUPO
            )
        }

        [PSCustomObject]@{

            GRUPO_FSRM = $_.Name

            ARQUIVOS_TOTAL_GRUPO = $QuantidadeTotalGrupo

            ARQUIVOS_EXPORTADOS = $QuantidadeArquivosGrupo

            MB_EXPORTADOS = $MBExportadosGrupo

        }
    } |
    Sort-Object `
        @{ Expression = "MB_EXPORTADOS"; Descending = $true },
        @{ Expression = "GRUPO_FSRM"; Ascending = $true }
)

# ==========================================================
# ESTATISTICAS POR EXTENSAO
# ==========================================================

$ResumoPorExtensao = @(
    $ResultadoFinal |
    Group-Object -Property EXTENSAO |
    ForEach-Object {

        $ItensDaExtensao = @($_.Group)

        $QuantidadeArquivosExtensao = $ItensDaExtensao.Count

        $BytesExtensao = (
            $ItensDaExtensao |
            Measure-Object `
                -Property TamanhoBytes `
                -Sum
        ).Sum

        if ($null -eq $BytesExtensao)
        {
            $BytesExtensao = 0
        }

        $MBExtensao = [Math]::Round(
            ($BytesExtensao / 1MB),
            2
        )

        [PSCustomObject]@{

            EXTENSAO = $_.Name

            ARQUIVOS_EXPORTADOS = $QuantidadeArquivosExtensao

            MB_EXPORTADOS = $MBExtensao

        }
    } |
    Sort-Object `
        @{ Expression = "MB_EXPORTADOS"; Descending = $true },
        @{ Expression = "EXTENSAO"; Ascending = $true }
)

# ==========================================================
# MAIOR ARQUIVO EXPORTADO
# ==========================================================

$MaiorArquivo = $ResultadoFinal |
    Sort-Object `
        -Property TamanhoBytes `
        -Descending |
    Select-Object -First 1

if ($null -ne $MaiorArquivo)
{
    $MaiorArquivoNome = [string]$MaiorArquivo.NOME_ARQUIVO

    $MaiorArquivoMB = [Math]::Round(
        ($MaiorArquivo.TamanhoBytes / 1MB),
        2
    )

    $MaiorArquivoGrupo = [string]$MaiorArquivo.GRUPO_FSRM
}
else
{
    $MaiorArquivoNome = ""

    $MaiorArquivoMB = 0

    $MaiorArquivoGrupo = ""
}

# ==========================================================
# RESULTADO DAS ESTATISTICAS
# ==========================================================

Write-Host ("Arquivos exportados.....: {0:N0}" -f $ArquivosExportados)
Write-Host ("MB exportados...........: {0:N2}" -f $TotalMBExportados)
Write-Host ("Grupos exportados.......: {0:N0}" -f $QuantidadeGruposExportados)
Write-Host ("Extensoes exportadas....: {0:N0}" -f $QuantidadeExtensoesExportadas)
Write-Host ""

if ($null -ne $MaiorArquivo)
{
    Write-Host ("Maior arquivo...........: {0}" -f $MaiorArquivoNome)
    Write-Host ("Tamanho do maior arquivo: {0:N2} MB" -f $MaiorArquivoMB)
    Write-Host ("Grupo do maior arquivo..: {0}" -f $MaiorArquivoGrupo)
    Write-Host ""
}

# ==========================================================
# RESUMO DOS GRUPOS NA TELA
# ==========================================================

Write-Host "RESUMO POR GRUPO"
Write-Host "----------------"
Write-Host ""

foreach ($Grupo in $ResumoPorGrupo)
{
    Write-Host (
        "{0} | Total no grupo: {1:N0} | Exportados: {2:N0} | MB: {3:N2}" -f `
        $Grupo.GRUPO_FSRM,
        $Grupo.ARQUIVOS_TOTAL_GRUPO,
        $Grupo.ARQUIVOS_EXPORTADOS,
        $Grupo.MB_EXPORTADOS
    )
}

Write-Host ""

# ==========================================================
# ------------------- BLOCO 04 -----------------------------
# ==========================================================


# ==========================================================
# PREPARACAO DOS DADOS PARA O CSV
# ==========================================================

Write-Host "Preparando dados para exportacao..."
Write-Host ""

$ResultadoCSV = $ResultadoFinal |
    Select-Object `
        GRUPO_FSRM,
        QTD_NO_GRUPO,
        TAMANHO_GRUPO_MB,
        NOME_ARQUIVO,
        EXTENSAO,
        TAMANHO_MB,
        DIRETORIO,
        ACESSADO_EM

# ==========================================================
# EXPORTACAO DO CSV
# ==========================================================

$ResultadoCSV |
    Export-Csv `
        -Path $CsvPath `
        -Delimiter ";" `
        -NoTypeInformation `
        -Encoding UTF8

# ==========================================================
# VALIDACAO DO ARQUIVO GERADO
# ==========================================================

if (!(Test-Path -Path $CsvPath))
{
    throw "O arquivo CSV nao foi gerado: $CsvPath"
}

$CsvInfo = Get-Item -Path $CsvPath

if ($CsvInfo.Length -eq 0)
{
    throw "O arquivo CSV foi gerado, mas esta vazio: $CsvPath"
}

# ==========================================================
# RESULTADO DA EXPORTACAO
# ==========================================================

Write-Host ("CSV gerado com sucesso.: {0}" -f $CsvPath)
Write-Host ("Linhas exportadas.......: {0:N0}" -f $ArquivosExportados)
Write-Host ("Tamanho do CSV..........: {0:N0} bytes" -f $CsvInfo.Length)
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
Write-Host "----------------------"
Write-Host ("Grupos no XML...........: {0:N0}" -f $DisplayGroups)
Write-Host ("Arquivos no XML.........: {0:N0}" -f $DisplayFiles)
Write-Host ("MB no XML...............: {0:N2}" -f $DisplayMB)
Write-Host ""

Write-Host "DADOS PROCESSADOS"
Write-Host "-----------------"
Write-Host ("Grupos processados......: {0:N0}" -f $GruposProcessados)
Write-Host ("Arquivos processados....: {0:N0}" -f $ArquivosProcessados)
Write-Host ("Arquivos com data.......: {0:N0}" -f $ArquivosComData)
Write-Host ("Arquivos sem data.......: {0:N0}" -f $ArquivosSemData)
Write-Host ""

Write-Host "DADOS EXPORTADOS"
Write-Host "----------------"
Write-Host ("Arquivos exportados.....: {0:N0}" -f $ArquivosExportados)
Write-Host ("MB exportados...........: {0:N2}" -f $TotalMBExportados)
Write-Host ("Grupos exportados.......: {0:N0}" -f $QuantidadeGruposExportados)
Write-Host ("Extensoes exportadas....: {0:N0}" -f $QuantidadeExtensoesExportadas)
Write-Host ""

if ($MaiorArquivoNome -ne "")
{
    Write-Host "MAIOR ARQUIVO EXPORTADO"
    Write-Host "-----------------------"
    Write-Host ("Arquivo................: {0}" -f $MaiorArquivoNome)
    Write-Host ("Grupo..................: {0}" -f $MaiorArquivoGrupo)
    Write-Host ("Tamanho................: {0:N2} MB" -f $MaiorArquivoMB)
    Write-Host ""
}

Write-Host "TOP GRUPOS EXPORTADOS"
Write-Host "---------------------"

foreach ($Grupo in ($ResumoPorGrupo | Select-Object -First 10))
{
    Write-Host (
        "{0} | Arquivos: {1:N0} | MB: {2:N2}" -f `
        $Grupo.GRUPO_FSRM,
        $Grupo.ARQUIVOS_EXPORTADOS,
        $Grupo.MB_EXPORTADOS
    )
}

Write-Host ""

Write-Host "TOP EXTENSOES EXPORTADAS"
Write-Host "------------------------"

foreach ($Extensao in ($ResumoPorExtensao | Select-Object -First 10))
{
    Write-Host (
        "{0} | Arquivos: {1:N0} | MB: {2:N2}" -f `
        $Extensao.EXTENSAO,
        $Extensao.ARQUIVOS_EXPORTADOS,
        $Extensao.MB_EXPORTADOS
    )
}

Write-Host ""

# ==========================================================
# AVISOS DO FSRM
# ==========================================================

if ($Warnings.Count -gt 0)
{
    Write-Host "AVISOS DO FSRM"
    Write-Host "--------------"

    foreach ($Warning in $Warnings)
    {
        Write-Host ("- {0}" -f $Warning)
    }

    Write-Host ""
}

# ==========================================================
# ARQUIVOS GERADOS
# ==========================================================

Write-Host "ARQUIVOS GERADOS"
Write-Host "----------------"
Write-Host ("CSV.....................: {0}" -f $CsvPath)
Write-Host ("LOG.....................: {0}" -f $LogPath)
Write-Host ("Tempo de execucao.......: {0}" -f $ExecutionTimeText)
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
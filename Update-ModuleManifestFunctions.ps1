[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$ModuleRoot,           # e.g. C:\repos\MyModule
    [Parameter(Mandatory)]
    [string]$ManifestPath,         # e.g. C:\repos\MyModule\MyModule.psd1
    [string]$PublicFolderName = 'Public',
    [switch]$Sort
)

# --- Enforce UTF-8 I/O (works in pwsh 7 and WinPS 5.1) ---
function Initialize-Utf8 {
    try {
        if ($PSVersionTable.PSVersion.Major -lt 7 -and $IsWindows) {
            try { chcp 65001 > $null } catch { }
        }
        [Console]::InputEncoding  = [System.Text.UTF8Encoding]::new()
        [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
        $script:OutputEncoding    = [Console]::OutputEncoding

        $enc = if ($PSVersionTable.PSVersion.Major -ge 7) { 'utf8NoBOM' } else { 'utf8' }
        $PSDefaultParameterValues['Out-File:Encoding']    = $enc
        $PSDefaultParameterValues['Set-Content:Encoding'] = $enc
        $PSDefaultParameterValues['Add-Content:Encoding'] = $enc
    } catch {
        Write-Warning "Could not initialize UTF-8 I/O: $($_.Exception.Message)"
    }
}
Initialize-Utf8

function Get-PublicFunctionNames {
    param([string]$PublicPath)

    if (-not (Test-Path -LiteralPath $PublicPath)) {
        Write-Error "Public folder not found: $PublicPath"
        return @()
    }

    $functions = New-Object System.Collections.Generic.List[string]

    Get-ChildItem -LiteralPath $PublicPath -Filter *.ps1 -File -Recurse | ForEach-Object {
        $null   = $null
        $tokens = $null
        $errors = $null
        try {
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$errors)
            $ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
            }, $true) | ForEach-Object {
                if ($_.Name) { $functions.Add($_.Name) }
            }
        } catch {
            Write-Warning "Could not parse '$($_.FullName)': $($_.Exception.Message)"
        }
    }

    $unique = $functions | Select-Object -Unique
    if ($Sort) { $unique = $unique | Sort-Object }
    return ,$unique
}

# --- Main ---
if (-not (Test-Path -LiteralPath $ManifestPath)) {
    throw "Manifest not found: $ManifestPath"
}

$publicPath = Join-Path -Path $ModuleRoot -ChildPath $PublicFolderName
$funcs = Get-PublicFunctionNames -PublicPath $publicPath

if (-not $funcs -or $funcs.Count -eq 0) {
    Write-Warning "No public functions found in folder '$publicPath'."
    return
}

try {
    $manifestData = Import-PowerShellDataFile -LiteralPath $ManifestPath
} catch {
    throw "Could not read manifest: $($_.Exception.Message)"
}

$old = @()
if ($manifestData.ContainsKey('FunctionsToExport')) {
    $old = @($manifestData.FunctionsToExport)
}

Write-Host "Old (FunctionsToExport): $($old -join ', ')" -ForegroundColor Yellow
Write-Host "New (FunctionsToExport): $($funcs -join ', ')" -ForegroundColor Green

if ($PSCmdlet.ShouldProcess($ManifestPath, "Update FunctionsToExport")) {
    Update-ModuleManifest -Path $ManifestPath -FunctionsToExport $funcs
    Write-Host "Manifest updated: $ManifestPath" -ForegroundColor Cyan
}

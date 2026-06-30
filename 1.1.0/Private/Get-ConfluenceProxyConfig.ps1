function Get-ConfluenceProxyConfig {
    <#
    .SYNOPSIS
        Liest einen benannten Proxy-Eintrag aus der Konfigurationsdatei.
    .PARAMETER Name
        Name des Proxy-Profils, z.B. "server-proxy" oder "client-proxy".
    .PARAMETER ConfigPath
        Pfad zur Konfigurationsdatei (JSON). Standard: <Modulstamm>\Configurations\ProxyConfig.json
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter(Mandatory = $false)]
        [string]
        $ConfigPath = $script:CFL_DefaultProxyConfigPath
    )

    begin {
        $ErrorActionPreference = "Stop"

        if (-not (Test-Path -LiteralPath $ConfigPath)) {
            Throw "Proxy-Konfigurationsdatei nicht gefunden: $ConfigPath. Mit Set-ConfluenceProxyConfig anlegen."
        }

        $Config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
    }

    process {
        if ($Config.PSObject.Properties.Name -notcontains $Name) {
            Throw "Kein Proxy-Profil '$Name' in $ConfigPath gefunden. Vorhandene Profile: $($Config.PSObject.Properties.Name -join ', ')"
        }

        $Entry = $Config.$Name
    }

    end {
        return $Entry
    }
}

function Set-ConfluenceProxyConfig {
    <#
    .SYNOPSIS
        Legt ein benanntes Proxy-Profil in der Konfigurationsdatei an oder aktualisiert es.
    .PARAMETER Name
        Frei wählbarer Bezeichner, z.B. "server-proxy" oder "client-proxy".
    .PARAMETER ProxyUrl
        Proxy-URI, z.B. http://proxy.firma.ch:8080
    .PARAMETER UseDefaultCredentials
        Proxy mit den aktuellen Windows-Anmeldedaten authentifizieren.
    .PARAMETER ConfigPath
        Pfad zur Konfigurationsdatei (JSON). Standard: <Modulstamm>\Configurations\ProxyConfig.json
    .EXAMPLE
        Set-ConfluenceProxyConfig -Name "server-proxy" -ProxyUrl "http://server-proxy.firma.ch:8080"
    .EXAMPLE
        Set-ConfluenceProxyConfig -Name "client-proxy" -ProxyUrl "http://client-proxy.firma.ch:8080" -UseDefaultCredentials
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter(Mandatory = $true)]
        [string]
        $ProxyUrl,

        [Parameter(Mandatory = $false)]
        [switch]
        $UseDefaultCredentials,

        [Parameter(Mandatory = $false)]
        [string]
        $ConfigPath = $script:CFL_DefaultProxyConfigPath
    )

    begin {
        $ErrorActionPreference = "Stop"

        $ConfigDir = Split-Path -Path $ConfigPath -Parent
        if (-not (Test-Path -LiteralPath $ConfigDir)) {
            New-Item -Path $ConfigDir -ItemType Directory -Force | Out-Null
        }

        $Config = if (Test-Path -LiteralPath $ConfigPath) {
            Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
        }
        else {
            [pscustomobject]@{}
        }
    }

    process {
        $Entry = [pscustomobject]@{
            ProxyUrl              = $ProxyUrl
            UseDefaultCredentials = [bool]$UseDefaultCredentials
        }

        if ($Config.PSObject.Properties.Name -contains $Name) {
            $Config.$Name = $Entry
        }
        else {
            $Config | Add-Member -MemberType NoteProperty -Name $Name -Value $Entry
        }

        ($Config | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $ConfigPath -Encoding UTF8
    }

    end {
        return [pscustomobject]@{
            ConfigPath = $ConfigPath
            Proxies    = $Config.PSObject.Properties.Name
        }
    }
}

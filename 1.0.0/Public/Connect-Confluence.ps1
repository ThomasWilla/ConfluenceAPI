function Connect-Confluence {
    <#
    .SYNOPSIS
        Stellt eine Verbindung zu Confluence Cloud her (API-Token-Auth).
    .PARAMETER BaseUrl
        z.B. https://deinedomain.atlassian.net
    .PARAMETER Email
        Atlassian-Account-E-Mail
    .PARAMETER ApiToken
        API-Token von https://id.atlassian.com/manage-profile/security/api-tokens
    .PARAMETER UseProxy
        Verbindung über einen Firmenproxy aufbauen.
    .PARAMETER ProxyServer
        Proxy-Variante: "server-proxy" (mit explizitem Proxy-URI) oder "client-proxy" (mit Default Credentials).
    .EXAMPLE
        Connect-Confluence -BaseUrl "https://meinefirma.atlassian.net" -Email "ich@firma.ch" -ApiToken (Read-Host -AsSecureString)
    .EXAMPLE
        Connect-Confluence -BaseUrl "https://meinefirma.atlassian.net" -Email "ich@firma.ch" -ApiToken $Token -UseProxy -ProxyServer "client-proxy"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $BaseUrl,

        [Parameter(Mandatory = $true)]
        [string]
        $Email,

        [Parameter(Mandatory = $true)]
        [object]
        $ApiToken,

        [Parameter(Mandatory = $false)]
        [Parameter(ParameterSetName = "proxy")]
        [switch]
        $UseProxy,

        [Parameter(Mandatory = $false)]
        [Parameter(ParameterSetName = "proxy")]
        [ValidateSet("server-proxy", "client-proxy")]
        [string]
        $ProxyServer
    )

    begin {
        $ErrorActionPreference = "Stop"

        if ($ApiToken -is [System.Security.SecureString]) {
            $PlainToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ApiToken)
            )
        }
        else {
            $PlainToken = [string]$ApiToken
        }

        $Pair = "{0}:{1}" -f $Email, $PlainToken
        $Base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Pair))
    }

    process {
        $script:CFL_BaseUrl = $BaseUrl.TrimEnd('/')
        $script:CFL_Email = $Email
        $script:CFL_AuthHeader = @{ Authorization = "Basic $Base64" }
        $script:CFL_UseProxy = [bool]$UseProxy
        $script:CFL_ProxyServer = $ProxyServer

        $ProxyParams = Get-ConfluenceProxyParams

        try {
            $null = Invoke-RestMethod -Method Get -Uri "$($script:CFL_BaseUrl)/wiki/api/v2/spaces?limit=1" -Headers $script:CFL_AuthHeader @ProxyParams
        }
        catch {
            $script:CFL_BaseUrl = $null
            $script:CFL_Email = $null
            $script:CFL_AuthHeader = $null
            $script:CFL_UseProxy = $null
            $script:CFL_ProxyServer = $null
            Write-Error $_.Exception.Message
            Throw "Verbindung zu Confluence fehlgeschlagen."
        }
    }

    end {
        [pscustomobject]@{
            BaseUrl  = $script:CFL_BaseUrl
            Email    = $script:CFL_Email
            UseProxy = $script:CFL_UseProxy
        }
    }
}

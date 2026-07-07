function Connect-Confluence {
    <#
    .SYNOPSIS
        Stellt eine Verbindung zu Confluence Cloud her (API-Token, OAuth2 Bearer oder OAuth2 Service Account).
    .PARAMETER BaseUrl
        z.B. https://deinedomain.atlassian.net (ein angehängtes "/wiki" wird automatisch entfernt)
    .PARAMETER Email
        Atlassian-Account-E-Mail (nur bei BasicAuth)
    .PARAMETER ApiToken
        API-Token von https://id.atlassian.com/manage-profile/security/api-tokens (nur bei BasicAuth)
    .PARAMETER AccessToken
        OAuth2 Bearer Access Token als String, SecureString oder PSCredential (Token im Password-Feld). Alternativ zu Email/ApiToken.
    .PARAMETER ClientId
        Client ID eines OAuth 2.0 Service-Account-Credentials (Atlassian Administration -> Directory -> Service accounts).
    .PARAMETER ClientSecret
        Client Secret des Service-Account-Credentials, als String, SecureString oder PSCredential (Secret im Password-Feld).
    .PARAMETER ProxyServer
        Name eines in der Konfigurationsdatei abgelegten Proxy-Profils, z.B. "server-proxy" oder "client-proxy".
        Siehe Set-ConfluenceProxyConfig.
    .PARAMETER ProxyConfigPath
        Pfad zur Proxy-Konfigurationsdatei (JSON). Standard: <Modulstamm>\Configurations\ProxyConfig.json
    .PARAMETER ProxyUrl
        Alternative zu -ProxyServer: Proxy-URI direkt angeben, z.B. "http://proxy.firma.ch:8080".
    .PARAMETER ProxyUseDefaultCredentials
        Nur zusammen mit -ProxyUrl: Verwendet die aktuellen Windows-Anmeldedaten für die Proxy-Authentifizierung.
    .PARAMETER ProxyCredential
        Nur zusammen mit -ProxyUrl: Explizite Anmeldedaten für die Proxy-Authentifizierung.
    .EXAMPLE
        Connect-Confluence -BaseUrl "https://meinefirma.atlassian.net" -Email "ich@firma.ch" -ApiToken (Read-Host -AsSecureString)
    .EXAMPLE
        Connect-Confluence -BaseUrl "https://meinefirma.atlassian.net" -AccessToken $BearerToken
    .EXAMPLE
        Connect-Confluence -BaseUrl "https://meinefirma.atlassian.net" -ClientId $ClientId -ClientSecret $ClientSecret
    .EXAMPLE
        Connect-Confluence -BaseUrl "https://meinefirma.atlassian.net" -Email "ich@firma.ch" -ApiToken $Token -ProxyServer "client-proxy"
    .EXAMPLE
        Connect-Confluence -BaseUrl "https://meinefirma.atlassian.net" -Email "ich@firma.ch" -ApiToken $Token -ProxyUrl "http://proxy.firma.ch:8080" -ProxyUseDefaultCredentials
    #>
    [CmdletBinding(DefaultParameterSetName = 'BasicAuth')]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $BaseUrl,

        [Parameter(Mandatory = $true, ParameterSetName = 'BasicAuth')]
        [string]
        $Email,

        [Parameter(Mandatory = $true, ParameterSetName = 'BasicAuth')]
        [object]
        $ApiToken,

        [Parameter(Mandatory = $true, ParameterSetName = 'OAuth2')]
        [object]
        $AccessToken,

        [Parameter(Mandatory = $true, ParameterSetName = 'ServiceAccount')]
        [string]
        $ClientId,

        [Parameter(Mandatory = $true, ParameterSetName = 'ServiceAccount')]
        [object]
        $ClientSecret,

        [Parameter(Mandatory = $false)]
        [ArgumentCompleter({
            param($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters)

            $ConfigPath = $FakeBoundParameters['ProxyConfigPath']
            if (-not $ConfigPath) {
                $ModuleBase = (Get-Module -Name ConfluenceAPI | Select-Object -First 1).ModuleBase
                if ($ModuleBase) {
                    $ConfigPath = Join-Path -Path (Split-Path -Path $ModuleBase -Parent) -ChildPath "Configurations\ProxyConfig.json"
                }
            }

            if ($ConfigPath -and (Test-Path -LiteralPath $ConfigPath)) {
                (Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json).PSObject.Properties.Name |
                    Where-Object { $_ -like "$WordToComplete*" }
            }
        })]
        [string]
        $ProxyServer,

        [Parameter(Mandatory = $false)]
        [string]
        $ProxyConfigPath = $script:CFL_DefaultProxyConfigPath,

        [Parameter(Mandatory = $false)]
        [string]
        $ProxyUrl,

        [Parameter(Mandatory = $false)]
        [switch]
        $ProxyUseDefaultCredentials,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $ProxyCredential
    )

    begin {
        $ErrorActionPreference = "Stop"

        switch ($PSCmdlet.ParameterSetName) {
            'BasicAuth' {
                if ($ApiToken -is [System.Security.SecureString]) {
                    $PlainToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ApiToken)
                    )
                }
                else {
                    $PlainToken = [string]$ApiToken
                }
                $Pair   = "{0}:{1}" -f $Email, $PlainToken
                $Base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Pair))
                $AuthValue = "Basic $Base64"
            }
            'OAuth2' {
                if ($AccessToken -is [System.Management.Automation.PSCredential]) {
                    $PlainBearer = $AccessToken.GetNetworkCredential().Password
                }
                elseif ($AccessToken -is [System.Security.SecureString]) {
                    $PlainBearer = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AccessToken)
                    )
                }
                else {
                    $PlainBearer = [string]$AccessToken
                }
                $AuthValue = "Bearer $PlainBearer"
            }
            'ServiceAccount' {
                if ($ClientSecret -is [System.Management.Automation.PSCredential]) {
                    $PlainClientSecret = $ClientSecret.GetNetworkCredential().Password
                }
                elseif ($ClientSecret -is [System.Security.SecureString]) {
                    $PlainClientSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ClientSecret)
                    )
                }
                else {
                    $PlainClientSecret = [string]$ClientSecret
                }
                # $AuthValue wird weiter unten im process-Block gesetzt, nachdem der Access Token angefordert wurde
            }
        }
    }

    process {
        if ($ProxyServer) {
            $ProxyConfigEntry = Get-ConfluenceProxyConfig -Name $ProxyServer -ConfigPath $ProxyConfigPath
            $script:CFL_ProxyUrl = $ProxyConfigEntry.ProxyUrl
            $script:CFL_ProxyUseDefaultCredentials = [bool]$ProxyConfigEntry.UseDefaultCredentials
            $script:CFL_ProxyCredential = $null
        }
        elseif ($ProxyUrl) {
            $script:CFL_ProxyUrl = $ProxyUrl
            $script:CFL_ProxyUseDefaultCredentials = [bool]$ProxyUseDefaultCredentials
            $script:CFL_ProxyCredential = $ProxyCredential
        }
        else {
            $script:CFL_ProxyUrl = $null
            $script:CFL_ProxyUseDefaultCredentials = $null
            $script:CFL_ProxyCredential = $null
        }

        $ProxyParams = Get-ConfluenceProxyParams
        $script:CFL_TokenExpiresAt = $null

        if ($PSCmdlet.ParameterSetName -eq 'ServiceAccount') {
            # 2-legged OAuth2 (client_credentials), Scopes sind am Service-Account-Credential selbst hinterlegt
            $TokenBody = @{
                client_id     = $ClientId
                client_secret = $PlainClientSecret
                grant_type    = 'client_credentials'
            }

            try {
                $TokenResponse = Invoke-RestMethod -Method Post -Uri 'https://auth.atlassian.com/oauth/token' -Body $TokenBody @ProxyParams
            }
            catch {
                Write-Error $_.Exception.Message
                Throw "Token-Anfrage bei Atlassian fehlgeschlagen."
            }

            $AuthValue = "Bearer $($TokenResponse.access_token)"
            $script:CFL_TokenExpiresAt = (Get-Date).AddSeconds($TokenResponse.expires_in)
            $script:CFL_ClientSecret = ConvertTo-SecureString -String $PlainClientSecret -AsPlainText -Force
        }
        else {
            $script:CFL_ClientSecret = $null
        }

        $SiteUrl = $BaseUrl.TrimEnd('/') -replace '/wiki$', ''

        if ($PSCmdlet.ParameterSetName -in @('OAuth2', 'ServiceAccount')) {
            # OAuth2 Bearer-Tokens werden nicht gegen die Tenant-Domain validiert, sondern über
            # das api.atlassian.com-Gateway mit der Cloud-ID der Site (unauthentifiziert ermittelbar).
            try {
                $TenantInfo = Invoke-RestMethod -Method Get -Uri "$SiteUrl/_edge/tenant_info" @ProxyParams
            }
            catch {
                Write-Error $_.Exception.Message
                Throw "Cloud-ID konnte nicht ermittelt werden ($SiteUrl/_edge/tenant_info)."
            }
            $ApiBaseUrl = "https://api.atlassian.com/ex/confluence/$($TenantInfo.cloudId)"
        }
        else {
            $ApiBaseUrl = $SiteUrl
        }

        $script:CFL_SiteUrl  = $SiteUrl
        $script:CFL_BaseUrl  = $ApiBaseUrl
        $script:CFL_Email    = if ($PSCmdlet.ParameterSetName -eq 'BasicAuth') { $Email } else { $null }
        $script:CFL_ClientId = if ($PSCmdlet.ParameterSetName -eq 'ServiceAccount') { $ClientId } else { $null }
        $script:CFL_AuthHeader = @{ Authorization = $AuthValue }

        try {
            $null = Invoke-RestMethod -Method Get -Uri "$($script:CFL_BaseUrl)/wiki/api/v2/spaces?limit=1" -Headers $script:CFL_AuthHeader @ProxyParams
        }
        catch {
            $script:CFL_BaseUrl = $null
            $script:CFL_SiteUrl = $null
            $script:CFL_Email = $null
            $script:CFL_ClientId = $null
            $script:CFL_ClientSecret = $null
            $script:CFL_AuthHeader = $null
            $script:CFL_ProxyUrl = $null
            $script:CFL_ProxyUseDefaultCredentials = $null
            $script:CFL_ProxyCredential = $null
            $script:CFL_TokenExpiresAt = $null
            Write-Error $_.Exception.Message
            Throw "Verbindung zu Confluence fehlgeschlagen."
        }
    }

    end {
        [pscustomobject]@{
            BaseUrl        = $script:CFL_SiteUrl
            AuthMethod     = $PSCmdlet.ParameterSetName
            Email          = $script:CFL_Email
            ClientId       = $script:CFL_ClientId
            TokenExpiresAt = $script:CFL_TokenExpiresAt
            ProxyUrl       = $script:CFL_ProxyUrl
        }
    }
}

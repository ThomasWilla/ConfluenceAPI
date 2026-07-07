function Confirm-ConfluenceConnection {
    <#
    .SYNOPSIS
        Prüft, ob eine aktive Confluence-Verbindung besteht, und gibt den Auth-Header zurück.
    #>
    [CmdletBinding()]
    param ()

    process {
        if (-not $script:CFL_AuthHeader) {
            Throw "Keine aktive Confluence-Verbindung. Zuerst Connect-Confluence ausführen."
        }

        if ($script:CFL_TokenExpiresAt -and (Get-Date).AddSeconds(30) -ge $script:CFL_TokenExpiresAt) {
            Write-Verbose "OAuth2 Access Token abgelaufen (oder läuft gleich ab) - hole neues Token via client_credentials"

            $PlainClientSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($script:CFL_ClientSecret)
            )
            $TokenBody = @{
                client_id     = $script:CFL_ClientId
                client_secret = $PlainClientSecret
                grant_type    = 'client_credentials'
            }
            $ProxyParams = Get-ConfluenceProxyParams

            try {
                $TokenResponse = Invoke-RestMethod -Method Post -Uri 'https://auth.atlassian.com/oauth/token' -Body $TokenBody @ProxyParams
            }
            catch {
                Write-Error $_.Exception.Message
                Throw "Erneuerung des Access Tokens fehlgeschlagen."
            }

            $script:CFL_AuthHeader = @{ Authorization = "Bearer $($TokenResponse.access_token)" }
            $script:CFL_TokenExpiresAt = (Get-Date).AddSeconds($TokenResponse.expires_in)
        }
    }

    end {
        return $script:CFL_AuthHeader
    }
}

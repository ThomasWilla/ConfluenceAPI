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
    .EXAMPLE
        Connect-Confluence -BaseUrl "https://meinefirma.atlassian.net" -Email "ich@firma.ch" -ApiToken (Read-Host -AsSecureString)
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
        $ApiToken
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
        $Global:CFL_BaseUrl = $BaseUrl.TrimEnd('/')
        $Global:CFL_Email = $Email
        $Global:CFL_AuthHeader = @{ Authorization = "Basic $Base64" }

        try {
            $null = Invoke-RestMethod -Method Get -Uri "$($Global:CFL_BaseUrl)/wiki/api/v2/spaces?limit=1" -Headers $Global:CFL_AuthHeader
        }
        catch {
            $Global:CFL_BaseUrl = $null
            $Global:CFL_Email = $null
            $Global:CFL_AuthHeader = $null
            Write-Error $_.Exception.Message
            Throw "Verbindung zu Confluence fehlgeschlagen."
        }
    }

    end {
        [pscustomobject]@{
            BaseUrl = $Global:CFL_BaseUrl
            Email   = $Global:CFL_Email
        }
    }
}

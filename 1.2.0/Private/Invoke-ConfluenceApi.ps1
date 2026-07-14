function Invoke-ConfluenceApi {
    <#
    .SYNOPSIS
        Interner Low-Level-Wrapper um Invoke-RestMethod gegen die Confluence Cloud REST API v2.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Get", "Post", "Put", "Delete")]
        [string]
        $Method,

        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        [Parameter(Mandatory = $false)]
        [object]
        $Body = $null,

        [Parameter(Mandatory = $false)]
        [hashtable]
        $Headers = @{}
    )

    begin {
        $ErrorActionPreference = "Stop"
        $AuthHeader = Confirm-ConfluenceConnection
    }

    process {
        $Uri = "$($script:CFL_BaseUrl)$Path"
        Write-Verbose "$Method $Uri"
        $AllHeaders = $AuthHeader.Clone()
        foreach ($Key in $Headers.Keys) { $AllHeaders[$Key] = $Headers[$Key] }

        $Params = @{
            Method  = $Method
            Uri     = $Uri
            Headers = $AllHeaders
        }
        $Params += Get-ConfluenceProxyParams

        if ($null -ne $Body) {
            # Als UTF-8-Bytes statt String übergeben: Invoke-RestMethod kodiert einen String-Body
            # unter Windows PowerShell 5.1 nicht zuverlässig als UTF-8, was bei Sonderzeichen
            # (Umlaute, Gedankenstriche, Aufzählungszeichen etc.) zu "Invalid UTF-8" Fehlern der API führt.
            $JsonBody = $Body | ConvertTo-Json -Depth 20
            $Params.Body = [System.Text.Encoding]::UTF8.GetBytes($JsonBody)
            $Params.ContentType = "application/json; charset=utf-8"
        }

        try {
            # Invoke-WebRequest + manuelles UTF-8-Decoding statt Invoke-RestMethod: Unter Windows
            # PowerShell 5.1 wird die Response ohne explizites charset im Content-Type-Header nicht
            # zuverlässig als UTF-8 dekodiert, was Sonderzeichen (z.B. Umlaute in Titeln) korrumpiert -
            # und sich bei jedem erneuten Speichern des ungeprüft übernommenen Werts weiter aufschaukelt.
            $WebResponse = Invoke-WebRequest @Params -UseBasicParsing
        }
        catch {
            $ApiError = Resolve-ConfluenceApiError -ErrorRecord $_
            Write-Error $ApiError.Message
            Throw "Confluence API Fehler ($($ApiError.StatusCode)): $($ApiError.Message)"
        }

        $RawBytes = $WebResponse.RawContentStream.ToArray()
        $JsonText = [System.Text.Encoding]::UTF8.GetString($RawBytes)
        $response = if ([string]::IsNullOrWhiteSpace($JsonText)) { $null } else { $JsonText | ConvertFrom-Json }
    }

    end {
        return $response
    }
}

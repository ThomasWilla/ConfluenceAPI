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
        $AllHeaders = $AuthHeader.Clone()
        foreach ($Key in $Headers.Keys) { $AllHeaders[$Key] = $Headers[$Key] }

        $Params = @{
            Method  = $Method
            Uri     = $Uri
            Headers = $AllHeaders
        }
        $Params += Get-ConfluenceProxyParams

        if ($null -ne $Body) {
            $Params.Body = ($Body | ConvertTo-Json -Depth 20)
            $Params.ContentType = "application/json"
        }

        try {
            $response = Invoke-RestMethod @Params
        }
        catch {
            $ApiError = Resolve-ConfluenceApiError -ErrorRecord $_
            Write-Error $ApiError.Message
            Throw "Confluence API Fehler ($($ApiError.StatusCode)): $($ApiError.Message)"
        }
    }

    end {
        return $response
    }
}

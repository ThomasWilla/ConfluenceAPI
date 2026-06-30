function Resolve-ConfluenceApiError {
    <#
    .SYNOPSIS
        Liest Statuscode und Fehlertext aus einem fehlgeschlagenen Invoke-RestMethod/Invoke-WebRequest-Aufruf,
        kompatibel mit Windows PowerShell 5.1 (HttpWebResponse) und PowerShell 7+ (HttpResponseMessage).
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    process {
        $StatusCode = $ErrorRecord.Exception.Response.StatusCode

        $ErrorBody = $ErrorRecord.ErrorDetails.Message

        if (-not $ErrorBody) {
            $Resp = $ErrorRecord.Exception.Response
            if ($Resp) {
                if ($Resp.PSObject.Methods.Name -contains "GetResponseStream") {
                    # Windows PowerShell 5.1 (HttpWebResponse)
                    $Reader = New-Object System.IO.StreamReader($Resp.GetResponseStream())
                    $ErrorBody = $Reader.ReadToEnd()
                }
                elseif ($Resp.PSObject.Properties.Name -contains "Content") {
                    # PowerShell 7+ (HttpResponseMessage)
                    $ErrorBody = $Resp.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                }
            }
        }

        if (-not $ErrorBody) { $ErrorBody = $ErrorRecord.Exception.Message }
    }

    end {
        return [pscustomobject]@{
            StatusCode = $StatusCode
            Message    = $ErrorBody
        }
    }
}

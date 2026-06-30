function Get-ConfluenceAttachment {
    <#
    .SYNOPSIS
        Listet Anhänge einer Confluence-Seite auf.
    .PARAMETER PageId
        ID der Seite.
    .EXAMPLE
        Get-ConfluenceAttachment -PageId 12345
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $PageId
    )

    begin {
        $ErrorActionPreference = "Stop"
    }

    process {
        $response = (Invoke-ConfluenceApi -Method Get -Path "/wiki/api/v2/pages/$PageId/attachments").results
    }

    end {
        return $response
    }
}

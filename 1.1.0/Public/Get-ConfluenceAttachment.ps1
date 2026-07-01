function Get-ConfluenceAttachment {
    <#
    .SYNOPSIS
        Listet Anhänge einer Confluence-Seite auf.
    .PARAMETER PageId
        ID der Seite.
    .PARAMETER FileNameFilter
        Filtert nach exaktem Dateinamen.
    .EXAMPLE
        Get-ConfluenceAttachment -PageId 12345
    .EXAMPLE
        Get-ConfluenceAttachment -PageId 12345 -FileNameFilter "report.pdf"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $PageId,

        [Parameter(Mandatory = $false)]
        [string]
        $FileNameFilter
    )

    begin {
        $ErrorActionPreference = "Stop"
    }

    process {
        $Path = "/wiki/api/v2/pages/$PageId/attachments"
        if ($FileNameFilter) { $Path += "?filename=$([uri]::EscapeDataString($FileNameFilter))" }

        $response = (Invoke-ConfluenceApi -Method Get -Path $Path).results
    }

    end {
        return $response
    }
}

function Get-ConfluencePage {
    <#
    .SYNOPSIS
        Ruft eine oder mehrere Confluence-Seiten ab.
    .PARAMETER PageId
        ID einer einzelnen Seite.
    .PARAMETER SpaceId
        Filtert Seiten nach Space-ID, falls keine PageId angegeben ist.
    .PARAMETER Title
        Filtert nach Titel (exakte Übereinstimmung), benötigt SpaceId.
    .PARAMETER IncludeBody
        Gibt den Seiteninhalt (storage-Format) mit zurück.
    .EXAMPLE
        Get-ConfluencePage -PageId 12345 -IncludeBody
    .EXAMPLE
        Get-ConfluencePage -SpaceId 98765
    #>
    [CmdletBinding(DefaultParameterSetName = "ById")]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ById")]
        [string]
        $PageId,

        [Parameter(Mandatory = $false, ParameterSetName = "ByQuery")]
        [string]
        $SpaceId,

        [Parameter(Mandatory = $false, ParameterSetName = "ByQuery")]
        [string]
        $Title,

        [Parameter(Mandatory = $false)]
        [switch]
        $IncludeBody
    )

    begin {
        $ErrorActionPreference = "Stop"
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq "ById") {
            $Path = "/wiki/api/v2/pages/$PageId"
            if ($IncludeBody) { $Path += "?body-format=storage" }
            $response = Invoke-ConfluenceApi -Method Get -Path $Path
        }
        else {
            $QueryParts = @()
            if ($SpaceId) { $QueryParts += "space-id=$SpaceId" }
            if ($Title) { $QueryParts += "title=$([uri]::EscapeDataString($Title))" }
            if ($IncludeBody) { $QueryParts += "body-format=storage" }
            $Query = if ($QueryParts.Count -gt 0) { "?" + ($QueryParts -join "&") } else { "" }

            $response = (Invoke-ConfluenceApi -Method Get -Path "/wiki/api/v2/pages$Query").results
        }
    }

    end {
        return $response
    }
}

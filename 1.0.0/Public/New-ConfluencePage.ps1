function New-ConfluencePage {
    <#
    .SYNOPSIS
        Erstellt eine neue Confluence-Seite.
    .PARAMETER SpaceId
        ID des Ziel-Space.
    .PARAMETER Title
        Titel der neuen Seite.
    .PARAMETER Body
        Inhalt im Confluence-Storage-Format (XHTML).
    .PARAMETER ParentId
        Optionale Parent-Seiten-ID.
    .EXAMPLE
        New-ConfluencePage -SpaceId 98765 -Title "Neue Seite" -Body "<p>Hallo Welt</p>"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $SpaceId,

        [Parameter(Mandatory = $true)]
        [string]
        $Title,

        [Parameter(Mandatory = $true)]
        [string]
        $Body,

        [Parameter(Mandatory = $false)]
        [string]
        $ParentId
    )

    begin {
        $ErrorActionPreference = "Stop"

        $Payload = @{
            spaceId = $SpaceId
            status  = "current"
            title   = $Title
            body    = @{
                representation = "storage"
                value          = $Body
            }
        }
        if ($ParentId) { $Payload.parentId = $ParentId }
    }

    process {
        $response = Invoke-ConfluenceApi -Method Post -Path "/wiki/api/v2/pages" -Body $Payload
    }

    end {
        return $response
    }
}

function Update-ConfluencePage {
    <#
    .SYNOPSIS
        Aktualisiert eine bestehende Confluence-Seite (erstellt neue Version).
    .PARAMETER PageId
        ID der zu aktualisierenden Seite.
    .PARAMETER Title
        Neuer Titel (optional, sonst unverändert).
    .PARAMETER Body
        Neuer Inhalt im Storage-Format.
    .EXAMPLE
        Update-ConfluencePage -PageId 12345 -Body "<p>Aktualisierter Inhalt</p>"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $PageId,

        [Parameter(Mandatory = $false)]
        [string]
        $Title,

        [Parameter(Mandatory = $true)]
        [string]
        $Body
    )

    begin {
        $ErrorActionPreference = "Stop"
        $Current = Get-ConfluencePage -PageId $PageId
        $NextVersion = $Current.version.number + 1
        $NewTitle = if ($Title) { $Title } else { $Current.title }

        $Payload = @{
            id      = $PageId
            status  = "current"
            title   = $NewTitle
            body    = @{
                representation = "storage"
                value          = $Body
            }
            version = @{ number = $NextVersion }
        }
    }

    process {
        $response = Invoke-ConfluenceApi -Method Put -Path "/wiki/api/v2/pages/$PageId" -Body $Payload
    }

    end {
        return $response
    }
}

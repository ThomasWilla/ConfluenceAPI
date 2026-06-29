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
    }

    end {
        return $script:CFL_AuthHeader
    }
}

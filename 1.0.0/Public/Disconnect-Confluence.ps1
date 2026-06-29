function Disconnect-Confluence {
    <#
    .SYNOPSIS
        Trennt die aktuelle Confluence-Verbindung.
    .EXAMPLE
        Disconnect-Confluence
    #>
    [CmdletBinding()]
    param ()

    process {
        $Global:CFL_BaseUrl = $null
        $Global:CFL_Email = $null
        $Global:CFL_AuthHeader = $null
    }
}

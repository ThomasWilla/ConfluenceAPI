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
        $script:CFL_BaseUrl = $null
        $script:CFL_Email = $null
        $script:CFL_AuthHeader = $null
    }
}

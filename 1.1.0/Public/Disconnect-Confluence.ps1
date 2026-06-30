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
        $script:CFL_ProxyUrl = $null
        $script:CFL_ProxyUseDefaultCredentials = $null
        $script:CFL_ProxyCredential = $null
    }
}

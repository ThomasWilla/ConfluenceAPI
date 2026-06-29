function Remove-ConfluencePage {
    <#
    .SYNOPSIS
        Löscht (verschiebt in den Papierkorb) eine Confluence-Seite.
    .PARAMETER PageId
        ID der zu löschenden Seite.
    .EXAMPLE
        Remove-ConfluencePage -PageId 12345
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $PageId
    )

    process {
        if ($PSCmdlet.ShouldProcess("Seite $PageId", "Löschen")) {
            Invoke-ConfluenceApi -Method Delete -Path "/wiki/api/v2/pages/$PageId" | Out-Null
        }
    }
}

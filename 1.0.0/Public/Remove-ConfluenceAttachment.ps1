function Remove-ConfluenceAttachment {
    <#
    .SYNOPSIS
        Löscht einen Anhang.
    .PARAMETER AttachmentId
        ID des zu löschenden Anhangs.
    .EXAMPLE
        Remove-ConfluenceAttachment -AttachmentId 99887
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $AttachmentId
    )

    process {
        if ($PSCmdlet.ShouldProcess("Anhang $AttachmentId", "Löschen")) {
            Invoke-ConfluenceApi -Method Delete -Path "/wiki/api/v2/attachments/$AttachmentId" | Out-Null
        }
    }
}

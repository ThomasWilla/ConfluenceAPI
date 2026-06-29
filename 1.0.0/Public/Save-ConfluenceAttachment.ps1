function Save-ConfluenceAttachment {
    <#
    .SYNOPSIS
        Lädt einen Anhang herunter und speichert ihn lokal.
    .PARAMETER AttachmentId
        ID des Anhangs (aus Get-ConfluenceAttachment, Feld 'id').
    .PARAMETER DownloadLink
        Alternativ: direkter Download-Link (Feld 'downloadLink' aus Get-ConfluenceAttachment).
    .PARAMETER OutFile
        Zielpfad für die gespeicherte Datei.
    .EXAMPLE
        $att = Get-ConfluenceAttachment -PageId 12345 | Select-Object -First 1
        Save-ConfluenceAttachment -DownloadLink $att._links.download -OutFile "C:\Downloads\datei.pdf"
    #>
    [CmdletBinding(DefaultParameterSetName = "ByLink")]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ById")]
        [string]
        $AttachmentId,

        [Parameter(Mandatory = $true, ParameterSetName = "ByLink")]
        [string]
        $DownloadLink,

        [Parameter(Mandatory = $true)]
        [string]
        $OutFile
    )

    begin {
        $ErrorActionPreference = "Stop"
        $AuthHeader = Confirm-ConfluenceConnection
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq "ById") {
            $Meta = Invoke-ConfluenceApi -Method Get -Path "/wiki/api/v2/attachments/$AttachmentId"
            $DownloadLink = $Meta._links.download
        }

        if ($DownloadLink -notmatch "^https?://") {
            $DownloadLink = "$($script:CFL_BaseUrl)$DownloadLink"
        }

        $ProxyParams = Get-ConfluenceProxyParams
        Invoke-WebRequest -Uri $DownloadLink -Headers $AuthHeader -OutFile $OutFile @ProxyParams
    }
}

function Add-ConfluenceAttachment {
    <#
    .SYNOPSIS
        Lädt eine Datei als Anhang zu einer Confluence-Seite hoch.
    .PARAMETER PageId
        ID der Zielseite.
    .PARAMETER FilePath
        Pfad zur hochzuladenden Datei.
    .PARAMETER Comment
        Optionaler Kommentar zum Anhang.
    .EXAMPLE
        Add-ConfluenceAttachment -PageId 12345 -FilePath "C:\Dateien\bericht.pdf"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $PageId,

        [Parameter(Mandatory = $true)]
        [string]
        $FilePath,

        [Parameter(Mandatory = $false)]
        [string]
        $Comment
    )

    begin {
        $ErrorActionPreference = "Stop"

        if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
            Throw "Datei nicht gefunden: $FilePath"
        }

        $AuthHeader = Confirm-ConfluenceConnection
        $Uri = "$($script:CFL_BaseUrl)/wiki/rest/api/content/$PageId/child/attachment"
        $Headers = $AuthHeader.Clone()
        $Headers["X-Atlassian-Token"] = "no-check"

        $Form = @{ file = Get-Item -LiteralPath $FilePath }
        if ($Comment) { $Form.comment = $Comment }
    }

    process {
        try {
            $response = (Invoke-RestMethod -Method Post -Uri $Uri -Headers $Headers -Form $Form).results
        }
        catch {
            $Resp = $_.Exception.Response
            if ($Resp) {
                $Reader = New-Object System.IO.StreamReader($Resp.GetResponseStream())
                $ErrBody = $Reader.ReadToEnd()
                Write-Error $ErrBody
                Throw "Confluence API Fehler ($($Resp.StatusCode)): $ErrBody"
            }
            Write-Error $_.Exception.Message
            Throw $_.ErrorDetails
        }
    }

    end {
        return $response
    }
}

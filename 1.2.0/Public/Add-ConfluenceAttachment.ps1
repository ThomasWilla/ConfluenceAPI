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

        # Multipart-Body manuell bauen statt Invoke-RestMethod -Form: -Form gibt es erst ab
        # PowerShell 6+ (Core), nicht in Windows PowerShell 5.1. Ausserdem so garantiert
        # korrektes UTF-8 fuer Dateiname/Kommentar mit Sonderzeichen.
        $FileName = [System.IO.Path]::GetFileName($FilePath)
        $FileBytes = [System.IO.File]::ReadAllBytes($FilePath)
        $Boundary = [System.Guid]::NewGuid().ToString()
        $LF = "`r`n"
        $Utf8 = New-Object System.Text.UTF8Encoding($false)

        $BodyParts = New-Object System.Collections.Generic.List[byte]

        $FileHeader = "--$Boundary$LF" +
            "Content-Disposition: form-data; name=`"file`"; filename=`"$FileName`"$LF" +
            "Content-Type: application/octet-stream$LF$LF"
        $BodyParts.AddRange([byte[]]$Utf8.GetBytes($FileHeader))
        $BodyParts.AddRange([byte[]]$FileBytes)
        $BodyParts.AddRange([byte[]]$Utf8.GetBytes($LF))

        if ($Comment) {
            $CommentPart = "--$Boundary$LF" +
                "Content-Disposition: form-data; name=`"comment`"$LF$LF" +
                "$Comment$LF"
            $BodyParts.AddRange([byte[]]$Utf8.GetBytes($CommentPart))
        }

        $BodyParts.AddRange([byte[]]$Utf8.GetBytes("--$Boundary--$LF"))
        $BodyBytes = $BodyParts.ToArray()
    }

    process {
        try {
            $ProxyParams = Get-ConfluenceProxyParams
            $WebResponse = Invoke-WebRequest -Method Post -Uri $Uri -Headers $Headers -Body $BodyBytes `
                -ContentType "multipart/form-data; boundary=$Boundary" -UseBasicParsing @ProxyParams
        }
        catch {
            $ApiError = Resolve-ConfluenceApiError -ErrorRecord $_
            Write-Error $ApiError.Message
            Throw "Confluence API Fehler ($($ApiError.StatusCode)): $($ApiError.Message)"
        }

        $RawBytes = $WebResponse.RawContentStream.ToArray()
        $JsonText = [System.Text.Encoding]::UTF8.GetString($RawBytes)
        $response = if ([string]::IsNullOrWhiteSpace($JsonText)) { $null } else { ($JsonText | ConvertFrom-Json).results }
    }

    end {
        return $response
    }
}

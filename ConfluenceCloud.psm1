#Requires -Version 5.1

# Modulweiter Verbindungskontext
$script:ConfluenceConnection = $null

function Connect-Confluence {
    <#
    .SYNOPSIS
        Stellt eine Verbindung zu Confluence Cloud her (API-Token-Auth).
    .PARAMETER BaseUrl
        z.B. https://deinedomain.atlassian.net
    .PARAMETER Email
        Atlassian-Account-E-Mail
    .PARAMETER ApiToken
        API-Token von https://id.atlassian.com/manage-profile/security/api-tokens
    .EXAMPLE
        Connect-Confluence -BaseUrl "https://meinefirma.atlassian.net" -Email "ich@firma.ch" -ApiToken (Read-Host -AsSecureString)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $BaseUrl,
        [Parameter(Mandatory)] [string] $Email,
        [Parameter(Mandatory)] [object] $ApiToken
    )

    if ($ApiToken -is [System.Security.SecureString]) {
        $plainToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ApiToken)
        )
    } else {
        $plainToken = [string]$ApiToken
    }

    $pair = "{0}:{1}" -f $Email, $plainToken
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($pair)
    $base64 = [Convert]::ToBase64String($bytes)

    $script:ConfluenceConnection = [pscustomobject]@{
        BaseUrl = $BaseUrl.TrimEnd('/')
        Email   = $Email
        AuthHeader = @{ Authorization = "Basic $base64" }
    }

    # Verbindung testen
    try {
        $null = Invoke-ConfluenceApi -Method Get -Path "/wiki/api/v2/spaces?limit=1"
        Write-Verbose "Verbindung zu $BaseUrl erfolgreich."
    } catch {
        $script:ConfluenceConnection = $null
        throw "Verbindung zu Confluence fehlgeschlagen: $($_.Exception.Message)"
    }

    return $script:ConfluenceConnection | Select-Object BaseUrl, Email
}

function Disconnect-Confluence {
    <#
    .SYNOPSIS
        Trennt die aktuelle Confluence-Verbindung.
    #>
    [CmdletBinding()]
    param()
    $script:ConfluenceConnection = $null
}

function Test-ConfluenceConnection {
    if (-not $script:ConfluenceConnection) {
        throw "Keine aktive Confluence-Verbindung. Zuerst Connect-Confluence ausführen."
    }
}

function Invoke-ConfluenceApi {
    <#
    .SYNOPSIS
        Interner Low-Level-Wrapper um Invoke-RestMethod gegen die Confluence Cloud REST API v2.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [ValidateSet('Get','Post','Put','Delete')] [string] $Method,
        [Parameter(Mandatory)] [string] $Path,
        [object] $Body = $null,
        [hashtable] $Headers = @{},
        [string] $ContentType = 'application/json',
        [switch] $RawBody
    )

    Test-ConfluenceConnection

    $uri = "$($script:ConfluenceConnection.BaseUrl)$Path"
    $allHeaders = $script:ConfluenceConnection.AuthHeader.Clone()
    foreach ($k in $Headers.Keys) { $allHeaders[$k] = $Headers[$k] }

    $params = @{
        Method      = $Method
        Uri         = $uri
        Headers     = $allHeaders
        ErrorAction = 'Stop'
    }

    if ($Body -ne $null) {
        if ($RawBody) {
            $params.Body = $Body
        } else {
            $params.Body = ($Body | ConvertTo-Json -Depth 20)
            $params.ContentType = $ContentType
        }
    } elseif ($ContentType -ne 'application/json') {
        $params.ContentType = $ContentType
    }

    try {
        return Invoke-RestMethod @params
    } catch {
        $resp = $_.Exception.Response
        if ($resp) {
            $stream = $resp.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $errBody = $reader.ReadToEnd()
            throw "Confluence API Fehler ($($resp.StatusCode)): $errBody"
        }
        throw
    }
}

function Get-ConfluencePage {
    <#
    .SYNOPSIS
        Ruft eine oder mehrere Confluence-Seiten ab.
    .PARAMETER PageId
        ID einer einzelnen Seite.
    .PARAMETER SpaceId
        Filtert Seiten nach Space-ID, falls keine PageId angegeben ist.
    .PARAMETER Title
        Filtert nach Titel (exakte Übereinstimmung), benötigt SpaceId.
    .PARAMETER IncludeBody
        Gibt den Seiteninhalt (storage-Format) mit zurück.
    .EXAMPLE
        Get-ConfluencePage -PageId 12345 -IncludeBody
    .EXAMPLE
        Get-ConfluencePage -SpaceId 98765
    #>
    [CmdletBinding(DefaultParameterSetName = 'ById')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ById')] [string] $PageId,
        [Parameter(ParameterSetName = 'ByQuery')] [string] $SpaceId,
        [Parameter(ParameterSetName = 'ByQuery')] [string] $Title,
        [switch] $IncludeBody
    )

    if ($PSCmdlet.ParameterSetName -eq 'ById') {
        $path = "/wiki/api/v2/pages/$PageId"
        if ($IncludeBody) { $path += "?body-format=storage" }
        return Invoke-ConfluenceApi -Method Get -Path $path
    }

    $queryParts = @()
    if ($SpaceId) { $queryParts += "space-id=$SpaceId" }
    if ($Title)   { $queryParts += "title=$([uri]::EscapeDataString($Title))" }
    if ($IncludeBody) { $queryParts += "body-format=storage" }
    $query = if ($queryParts.Count -gt 0) { "?" + ($queryParts -join '&') } else { "" }

    $result = Invoke-ConfluenceApi -Method Get -Path "/wiki/api/v2/pages$query"
    return $result.results
}

function New-ConfluencePage {
    <#
    .SYNOPSIS
        Erstellt eine neue Confluence-Seite.
    .PARAMETER SpaceId
        ID des Ziel-Space.
    .PARAMETER Title
        Titel der neuen Seite.
    .PARAMETER Body
        Inhalt im Confluence-Storage-Format (XHTML).
    .PARAMETER ParentId
        Optionale Parent-Seiten-ID.
    .EXAMPLE
        New-ConfluencePage -SpaceId 98765 -Title "Neue Seite" -Body "<p>Hallo Welt</p>"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $SpaceId,
        [Parameter(Mandatory)] [string] $Title,
        [Parameter(Mandatory)] [string] $Body,
        [string] $ParentId
    )

    $payload = @{
        spaceId = $SpaceId
        status  = 'current'
        title   = $Title
        body    = @{
            representation = 'storage'
            value          = $Body
        }
    }
    if ($ParentId) { $payload.parentId = $ParentId }

    return Invoke-ConfluenceApi -Method Post -Path "/wiki/api/v2/pages" -Body $payload
}

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
    param(
        [Parameter(Mandatory)] [string] $PageId,
        [string] $Title,
        [Parameter(Mandatory)] [string] $Body
    )

    $current = Get-ConfluencePage -PageId $PageId
    $nextVersion = $current.version.number + 1
    $newTitle = if ($Title) { $Title } else { $current.title }

    $payload = @{
        id      = $PageId
        status  = 'current'
        title   = $newTitle
        body    = @{
            representation = 'storage'
            value          = $Body
        }
        version = @{ number = $nextVersion }
    }

    return Invoke-ConfluenceApi -Method Put -Path "/wiki/api/v2/pages/$PageId" -Body $payload
}

function Remove-ConfluencePage {
    <#
    .SYNOPSIS
        Löscht (verschiebt in den Papierkorb) eine Confluence-Seite.
    .PARAMETER PageId
        ID der zu löschenden Seite.
    .EXAMPLE
        Remove-ConfluencePage -PageId 12345
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [string] $PageId
    )

    if ($PSCmdlet.ShouldProcess("Seite $PageId", "Löschen")) {
        Invoke-ConfluenceApi -Method Delete -Path "/wiki/api/v2/pages/$PageId" | Out-Null
    }
}

function Get-ConfluenceAttachment {
    <#
    .SYNOPSIS
        Listet Anhänge einer Confluence-Seite auf.
    .PARAMETER PageId
        ID der Seite.
    .EXAMPLE
        Get-ConfluenceAttachment -PageId 12345
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $PageId
    )
    $result = Invoke-ConfluenceApi -Method Get -Path "/wiki/api/v2/pages/$PageId/attachments"
    return $result.results
}

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
    param(
        [Parameter(Mandatory)] [string] $PageId,
        [Parameter(Mandatory)] [string] $FilePath,
        [string] $Comment
    )

    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
        throw "Datei nicht gefunden: $FilePath"
    }

    Test-ConfluenceConnection
    $uri = "$($script:ConfluenceConnection.BaseUrl)/wiki/rest/api/content/$PageId/child/attachment"
    $headers = $script:ConfluenceConnection.AuthHeader.Clone()
    $headers['X-Atlassian-Token'] = 'no-check'

    $form = @{
        file = Get-Item -LiteralPath $FilePath
    }
    if ($Comment) { $form.comment = $Comment }

    try {
        $result = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Form $form -ErrorAction Stop
        return $result.results
    } catch {
        $resp = $_.Exception.Response
        if ($resp) {
            $stream = $resp.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $errBody = $reader.ReadToEnd()
            throw "Confluence API Fehler ($($resp.StatusCode)): $errBody"
        }
        throw
    }
}

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
    [CmdletBinding(DefaultParameterSetName = 'ByLink')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ById')] [string] $AttachmentId,
        [Parameter(Mandatory, ParameterSetName = 'ByLink')] [string] $DownloadLink,
        [Parameter(Mandatory)] [string] $OutFile
    )

    Test-ConfluenceConnection

    if ($PSCmdlet.ParameterSetName -eq 'ById') {
        $meta = Invoke-ConfluenceApi -Method Get -Path "/wiki/api/v2/attachments/$AttachmentId"
        $DownloadLink = $meta._links.download
    }

    if ($DownloadLink -notmatch '^https?://') {
        $DownloadLink = "$($script:ConfluenceConnection.BaseUrl)$DownloadLink"
    }

    Invoke-WebRequest -Uri $DownloadLink -Headers $script:ConfluenceConnection.AuthHeader -OutFile $OutFile -ErrorAction Stop
}

function Remove-ConfluenceAttachment {
    <#
    .SYNOPSIS
        Löscht einen Anhang.
    .PARAMETER AttachmentId
        ID des zu löschenden Anhangs.
    .EXAMPLE
        Remove-ConfluenceAttachment -AttachmentId 99887
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [string] $AttachmentId
    )

    if ($PSCmdlet.ShouldProcess("Anhang $AttachmentId", "Löschen")) {
        Invoke-ConfluenceApi -Method Delete -Path "/wiki/api/v2/attachments/$AttachmentId" | Out-Null
    }
}

function ConvertTo-ConfluenceStorageFormat {
    <#
    .SYNOPSIS
        Wandelt Text/einfaches HTML in das Confluence-Storage-Format (XHTML) um.
    .DESCRIPTION
        Bei -PlainText wird jede Zeile zu einem eigenen <p>-Absatz, Sonderzeichen werden escaped.
        Ohne -PlainText wird der Input als bereits gültiges (X)HTML/Storage-Markup durchgereicht
        und nur grob auf Wohlgeformtheit geprüft.
    .PARAMETER InputText
        Der zu konvertierende Text bzw. das HTML-Fragment.
    .PARAMETER PlainText
        Behandelt InputText als reinen Text statt als HTML.
    .EXAMPLE
        ConvertTo-ConfluenceStorageFormat -InputText "Zeile 1`nZeile 2" -PlainText
    .EXAMPLE
        New-ConfluencePage -SpaceId 123 -Title "Test" -Body (ConvertTo-ConfluenceStorageFormat -InputText "Hallo`nWelt" -PlainText)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)] [string] $InputText,
        [switch] $PlainText
    )

    process {
        if ($PlainText) {
            $lines = $InputText -split "`r?`n"
            $paragraphs = foreach ($line in $lines) {
                if ($line.Trim() -eq '') {
                    continue
                }
                $escaped = [System.Net.WebUtility]::HtmlEncode($line)
                "<p>$escaped</p>"
            }
            return ($paragraphs -join "")
        }

        try {
            $xmlFragment = "<root>$InputText</root>"
            [xml]$null = $xmlFragment
        } catch {
            throw "InputText ist kein wohlgeformtes XHTML-Fragment. Für reinen Text -PlainText verwenden. Fehler: $($_.Exception.Message)"
        }

        return $InputText
    }
}

Export-ModuleMember -Function @(
    'ConvertTo-ConfluenceStorageFormat',
    'Connect-Confluence',
    'Disconnect-Confluence',
    'Get-ConfluencePage',
    'New-ConfluencePage',
    'Update-ConfluencePage',
    'Remove-ConfluencePage',
    'Get-ConfluenceAttachment',
    'Add-ConfluenceAttachment',
    'Save-ConfluenceAttachment',
    'Remove-ConfluenceAttachment'
)

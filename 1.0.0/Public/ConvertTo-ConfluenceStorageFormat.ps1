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
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]
        $InputText,

        [Parameter(Mandatory = $false)]
        [switch]
        $PlainText
    )

    process {
        if ($PlainText) {
            $Lines = $InputText -split "`r?`n"
            $Paragraphs = foreach ($Line in $Lines) {
                if ($Line.Trim() -eq "") { continue }
                $Escaped = [System.Net.WebUtility]::HtmlEncode($Line)
                "<p>$Escaped</p>"
            }
            return ($Paragraphs -join "")
        }

        try {
            [xml]$null = "<root>$InputText</root>"
        }
        catch {
            Throw "InputText ist kein wohlgeformtes XHTML-Fragment. Für reinen Text -PlainText verwenden. Fehler: $($_.Exception.Message)"
        }

        return $InputText
    }
}

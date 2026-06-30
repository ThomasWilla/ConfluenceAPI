function ConvertTo-ConfluenceStorageFormat {
    <#
    .SYNOPSIS
        Wandelt Text/Markdown/einfaches HTML in das Confluence-Storage-Format (XHTML) um.
    .DESCRIPTION
        Bei -PlainText wird jede Zeile zu einem eigenen <p>-Absatz, Sonderzeichen werden escaped.
        Bei -Markdown werden Überschriften (#), Listen (-, *, 1.), Tabellen (| ... | oder || ... ||)
        sowie Inline-Markdown (**fett**, *kursiv*, `code`, [Text](URL)) in Storage-Format umgewandelt.
        Ohne beide Switches wird der Input als bereits gültiges (X)HTML/Storage-Markup durchgereicht
        und nur grob auf Wohlgeformtheit geprüft.
    .PARAMETER InputText
        Der zu konvertierende Text bzw. das HTML/Markdown-Fragment.
    .PARAMETER PlainText
        Behandelt InputText als reinen Text statt als HTML.
    .PARAMETER Markdown
        Behandelt InputText als Markdown (Tabellen, Listen, Überschriften, Inline-Formatierung).
    .EXAMPLE
        ConvertTo-ConfluenceStorageFormat -InputText "Zeile 1`nZeile 2" -PlainText
    .EXAMPLE
        $md = "||Tenant||Beschreibung||`n| Prod | Produktion |`n| Test | Testumgebung |"
        ConvertTo-ConfluenceStorageFormat -InputText $md -Markdown
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]
        $InputText,

        [Parameter(Mandatory = $false)]
        [switch]
        $PlainText,

        [Parameter(Mandatory = $false)]
        [switch]
        $Markdown
    )

    process {
        if ($PlainText -and $Markdown) {
            Throw "-PlainText und -Markdown können nicht gemeinsam verwendet werden."
        }

        if ($Markdown) {
            return (Convert-ConfluenceMarkdownToStorage -Markdown $InputText)
        }

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
            Throw "InputText ist kein wohlgeformtes XHTML-Fragment. Für reinen Text -PlainText oder für Markdown -Markdown verwenden. Fehler: $($_.Exception.Message)"
        }

        return $InputText
    }
}

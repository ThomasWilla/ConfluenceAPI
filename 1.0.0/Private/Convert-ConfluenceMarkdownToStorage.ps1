function Convert-ConfluenceMarkdownToStorage {
    <#
    .SYNOPSIS
        Wandelt einen vollständigen Markdown-Text in Confluence-Storage-Format (XHTML) um.
    .DESCRIPTION
        Zerlegt den Text in durch Leerzeilen getrennte Blöcke und erkennt je Block:
        Tabellen (| ... | oder || ... ||), Überschriften (#), Listen (-, *, + oder 1.) und Absätze.
        Innerhalb von Absätzen, Listen und Tabellenzellen werden fett/kursiv/Code/Links umgewandelt.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Markdown
    )

    process {
        $Lines = $Markdown -split "`r?`n"

        $Blocks = New-Object System.Collections.Generic.List[string[]]
        $Current = New-Object System.Collections.Generic.List[string]

        foreach ($Line in $Lines) {
            if ($Line.Trim() -eq "") {
                if ($Current.Count -gt 0) {
                    $Blocks.Add($Current.ToArray())
                    $Current.Clear()
                }
            }
            else {
                $Current.Add($Line)
            }
        }
        if ($Current.Count -gt 0) { $Blocks.Add($Current.ToArray()) }

        $Html = foreach ($Block in $Blocks) {
            $First = $Block[0].Trim()

            if ($Block | Where-Object { $_.Trim() -match '^\|' }) {
                Convert-ConfluenceMarkdownTable -Lines $Block
            }
            elseif ($First -match '^(#{1,6})\s+(.*)$') {
                $Level = $Matches[1].Length
                "<h$Level>$(Convert-ConfluenceMarkdownInline -Text $Matches[2])</h$Level>"
            }
            elseif ($First -match '^[-*+]\s+') {
                $Items = foreach ($BlockLine in $Block) {
                    if ($BlockLine.Trim() -match '^[-*+]\s+(.*)$') {
                        "<li>$(Convert-ConfluenceMarkdownInline -Text $Matches[1])</li>"
                    }
                }
                "<ul>$($Items -join '')</ul>"
            }
            elseif ($First -match '^\d+\.\s+') {
                $Items = foreach ($BlockLine in $Block) {
                    if ($BlockLine.Trim() -match '^\d+\.\s+(.*)$') {
                        "<li>$(Convert-ConfluenceMarkdownInline -Text $Matches[1])</li>"
                    }
                }
                "<ol>$($Items -join '')</ol>"
            }
            else {
                $ParagraphLines = $Block | ForEach-Object { Convert-ConfluenceMarkdownInline -Text $_.Trim() }
                "<p>$($ParagraphLines -join '<br/>')</p>"
            }
        }
    }

    end {
        return ($Html -join '')
    }
}

function Convert-ConfluenceMarkdownTable {
    <#
    .SYNOPSIS
        Wandelt einen Markdown-Tabellenblock in Confluence-Storage-Format (XHTML-Tabelle) um.
    .DESCRIPTION
        Unterstützt sowohl Standard-Markdown-Tabellen ("| A | B |" mit "|---|---|"-Trennzeile)
        als auch Confluence-Wiki-Style-Kopfzeilen ("||A||B||").
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]
        $Lines
    )

    process {
        $HeaderCells = $null
        $Rows = New-Object System.Collections.Generic.List[object]
        $RowIndex = 0

        foreach ($Line in $Lines) {
            $Trimmed = $Line.Trim()
            if (-not $Trimmed) { continue }

            $IsPipeHeader = $Trimmed.StartsWith('||')
            $Delimiter = if ($IsPipeHeader) { '\|\|' } else { '\|' }
            $Body = $Trimmed -replace '^\|+', '' -replace '\|+$', ''
            $Cells = @($Body -split $Delimiter | ForEach-Object { $_.Trim() })

            $IsSeparatorRow = -not ($Cells | Where-Object { $_ -and $_ -notmatch '^:?-{2,}:?$' })
            if ($IsSeparatorRow) { continue }

            if ($IsPipeHeader) {
                $HeaderCells = $Cells
            }
            elseif (-not $HeaderCells -and $RowIndex -eq 0) {
                $HeaderCells = $Cells
            }
            else {
                $Rows.Add($Cells)
            }
            $RowIndex++
        }

        $Sb = [System.Text.StringBuilder]::new()
        [void]$Sb.Append('<table><tbody>')

        if ($HeaderCells) {
            [void]$Sb.Append('<tr>')
            foreach ($Cell in $HeaderCells) {
                [void]$Sb.Append("<th>$(Convert-ConfluenceMarkdownInline -Text $Cell)</th>")
            }
            [void]$Sb.Append('</tr>')
        }

        foreach ($Row in $Rows) {
            [void]$Sb.Append('<tr>')
            foreach ($Cell in $Row) {
                [void]$Sb.Append("<td>$(Convert-ConfluenceMarkdownInline -Text $Cell)</td>")
            }
            [void]$Sb.Append('</tr>')
        }

        [void]$Sb.Append('</tbody></table>')
    }

    end {
        return $Sb.ToString()
    }
}

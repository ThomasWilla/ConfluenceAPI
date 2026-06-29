function Convert-ConfluenceMarkdownInline {
    <#
    .SYNOPSIS
        Wandelt Inline-Markdown (fett, kursiv, Code, Links) eines einzelnen Textfragments in Storage-Format-Spans um.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Text
    )

    process {
        $Escaped = [System.Net.WebUtility]::HtmlEncode($Text)

        # Links [Text](URL)
        $Escaped = [regex]::Replace($Escaped, '\[([^\]]+)\]\(([^)]+)\)', '<a href="$2">$1</a>')

        # Fett **Text** oder __Text__
        $Escaped = [regex]::Replace($Escaped, '\*\*([^\*]+)\*\*', '<strong>$1</strong>')
        $Escaped = [regex]::Replace($Escaped, '__([^_]+)__', '<strong>$1</strong>')

        # Kursiv *Text* oder _Text_
        $Escaped = [regex]::Replace($Escaped, '(?<!\*)\*([^\*]+)\*(?!\*)', '<em>$1</em>')
        $Escaped = [regex]::Replace($Escaped, '(?<!_)_([^_]+)_(?!_)', '<em>$1</em>')

        # Inline-Code `Text`
        $Escaped = [regex]::Replace($Escaped, '`([^`]+)`', '<code>$1</code>')
    }

    end {
        return $Escaped
    }
}

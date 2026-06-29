function Get-ConfluenceProxyParams {
    <#
    .SYNOPSIS
        Liefert die Proxy-Parameter für Invoke-RestMethod/Invoke-WebRequest, falls beim Connect ein Proxy konfiguriert wurde.
    #>
    [CmdletBinding()]
    param ()

    process {
        $ProxyParams = @{}

        if ($script:CFL_ProxyUrl) {
            $ProxyParams.Proxy = $script:CFL_ProxyUrl

            if ($script:CFL_ProxyCredential) {
                $ProxyParams.ProxyCredential = $script:CFL_ProxyCredential
            }
            elseif ($script:CFL_ProxyUseDefaultCredentials) {
                $ProxyParams.ProxyUseDefaultCredentials = $true
            }
        }
    }

    end {
        return $ProxyParams
    }
}

function Get-ConfluenceProxyParams {
    <#
    .SYNOPSIS
        Liefert die Proxy-Parameter für Invoke-RestMethod/Invoke-WebRequest, falls beim Connect ein Proxy gesetzt wurde.
    #>
    [CmdletBinding()]
    param ()

    process {
        $ProxyParams = @{}

        if ($script:CFL_UseProxy) {
            switch ($script:CFL_ProxyServer) {
                "server-proxy" {
                    $ProxyParams.Proxy = "http://server-proxy.xaas.swissic.ch:8080"
                }
                "client-proxy" {
                    $ProxyParams.Proxy = "http://client-proxy.xaas.swissic.ch:8080"
                    $ProxyParams.ProxyUseDefaultCredentials = $true
                }
            }
        }
    }

    end {
        return $ProxyParams
    }
}

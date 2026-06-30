function Invoke-ModuleCleanup {

    # Cleanup Skripte welche immer beim Beenden oder Schliessen der Session ausgeführt werden sollen (bspw. Logging, API-Disconnect)

    if ($script:CFL_AuthHeader) {
        Disconnect-Confluence
    }

    Write-Host "Module Cleanup for $($ExecutionContext.SessionState.Module.Name) done!"
}

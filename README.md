# ConfluenceAPI

[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/ConfluenceAPI.svg)](https://www.powershellgallery.com/packages/ConfluenceAPI)
[![PowerShell Gallery Downloads](https://img.shields.io/powershellgallery/dt/ConfluenceAPI.svg)](https://www.powershellgallery.com/packages/ConfluenceAPI)

PowerShell-Modul für die Confluence Cloud REST API (v2). Ermöglicht das Lesen, Erstellen und Bearbeiten von Seiten sowie das Verwalten von Anhängen über API-Token-Authentifizierung, optional über einen konfigurierbaren Proxy.

## Installation

Über die PowerShell Gallery ([ConfluenceAPI](https://www.powershellgallery.com/packages/ConfluenceAPI)):

```powershell
Install-Module -Name ConfluenceAPI
```

Oder direkt aus dem Repo:

```powershell
git clone https://github.com/ThomasWilla/ConfluenceAPI.git
Import-Module "C:\Pfad\zu\ConfluenceAPI\1.1.0\ConfluenceAPI.psd1"
```

## Struktur

```
ConfluenceAPI/
└── 1.1.0/
    ├── ConfluenceAPI.psd1
    ├── ConfluenceAPI.psm1
    ├── Public/      # Eine Funktion pro Datei, wird exportiert
    └── Private/     # Interne Hilfsfunktionen (API-Wrapper, Proxy-Auflösung)
```

## Voraussetzungen

- PowerShell 5.1 oder höher
- Ein Atlassian API-Token: https://id.atlassian.com/manage-profile/security/api-tokens

## Verbindung herstellen

### API-Token (Basic Auth)

```powershell
Connect-Confluence -BaseUrl "https://deinefirma.atlassian.net" -Email "du@firma.ch" -ApiToken (Read-Host -AsSecureString)
```

### OAuth2 Bearer Token

Alternativ kann ein OAuth2 Access Token übergeben werden (z.B. aus dem Atlassian OAuth 2.0 (3LO) Flow):

```powershell
Connect-Confluence -BaseUrl "https://deinefirma.atlassian.net" -AccessToken $BearerToken
```

Den Token beziehst du über eine Atlassian OAuth 2.0 App ([developer.atlassian.com](https://developer.atlassian.com/console/myapps/)) mit dem Authorization Code / PKCE-Flow. Das Modul akzeptiert den fertigen Token als `[string]` oder `[SecureString]`.

### OAuth2 Service Account (Client Credentials)

Für vollautomatisierte Szenarien ohne Browser-Login kann ein OAuth 2.0 Service-Account-Credential (Client ID/Secret) verwendet werden:

```powershell
Connect-Confluence -BaseUrl "https://deinefirma.atlassian.net" -ClientId $ClientId -ClientSecret (Read-Host -AsSecureString)
```

Das Credential erstellst du unter **Atlassian Administration → Directory → Service accounts → Create credentials** (nicht über developer.atlassian.com). Dabei werden die benötigten Confluence-Scopes direkt ausgewählt, u.a. `read:space:confluence` (Pflicht für den Verbindungstest), sowie je nach Bedarf `read:page:confluence`, `write:page:confluence`, `read:attachment:confluence`, `write:attachment:confluence`, `delete:page:confluence`, `delete:attachment:confluence`, `read:label:confluence`, `write:label:confluence`. Der Service Account benötigt zudem Produktzugriff auf Confluence auf der jeweiligen Site.

Das Modul holt sich das Access Token intern per `client_credentials`-Grant (60 Minuten gültig, kein Refresh-Token nötig — bei Bedarf wird bei jedem `Connect-Confluence`-Aufruf ein neues Token angefordert).

> **Hinweis:** OAuth2-Bearer-Tokens (sowohl `-AccessToken` als auch `-ClientId`/`-ClientSecret`) werden nicht direkt gegen die Tenant-Domain validiert. Das Modul ermittelt intern die Cloud-ID über den unauthentifizierten Endpoint `<BaseUrl>/_edge/tenant_info` und leitet alle API-Aufrufe über `https://api.atlassian.com/ex/confluence/{cloudId}/...`. Bei Basic Auth (API-Token) läuft alles weiterhin direkt über die Tenant-Domain.

### Verbindung über einen Proxy

Falls dein Netzwerk einen ausgehenden Proxy benötigt, kannst du diesen beim Connect konfigurieren. Die Einstellung gilt danach für alle Aufrufe der Session (Seiten, Anhänge). Es gibt zwei Wege: über benannte Profile aus einer Konfigurationsdatei, oder direkt als Parameter.

#### Variante 1: Benannte Proxy-Profile aus einer Konfigurationsdatei

Profile (z.B. `server-proxy`, `client-proxy` oder beliebige eigene Namen) werden einmalig mit `Set-ConfluenceProxyConfig` angelegt und danach per `-ProxyServer` ausgewählt:

```powershell
# Profile einmalig anlegen/aktualisieren
Set-ConfluenceProxyConfig -Name "server-proxy" -ProxyUrl "http://server-proxy.firma.ch:8080"
Set-ConfluenceProxyConfig -Name "client-proxy" -ProxyUrl "http://client-proxy.firma.ch:8080" -UseDefaultCredentials

# Verbindung unter Verwendung eines Profils
Connect-Confluence -BaseUrl "https://deinefirma.atlassian.net" -Email "du@firma.ch" -ApiToken $Token -ProxyServer "client-proxy"
```

Die Konfigurationsdatei liegt standardmässig unter `<Modulstamm>\Configurations\ProxyConfig.json` und kann mit `-ConfigPath` (bei `Set-ConfluenceProxyConfig`) bzw. `-ProxyConfigPath` (bei `Connect-Confluence`) an einen anderen Ort gelegt werden, z.B. ein zentrales, geteiltes Verzeichnis.

| Parameter (`Set-ConfluenceProxyConfig`) | Beschreibung |
|---|---|
| `-Name` | Frei wählbarer Profilname, z.B. `server-proxy` oder `client-proxy`. |
| `-ProxyUrl` | Proxy-URI, z.B. `http://proxy.firma.ch:8080`. |
| `-UseDefaultCredentials` | Profil mit den aktuellen Windows-Anmeldedaten authentifizieren. |
| `-ConfigPath` | Pfad zur Konfigurationsdatei (Standard: `<Modulstamm>\Configurations\ProxyConfig.json`). |

| Parameter (`Connect-Confluence`) | Beschreibung |
|---|---|
| `-ProxyServer` | Name eines Profils aus der Konfigurationsdatei. |
| `-ProxyConfigPath` | Pfad zur Konfigurationsdatei, falls abweichend vom Standard. |

#### Variante 2: Proxy direkt angeben (ohne Konfigurationsdatei)

```powershell
# Mit den aktuellen Windows-Anmeldedaten
Connect-Confluence -BaseUrl "https://deinefirma.atlassian.net" -Email "du@firma.ch" -ApiToken $Token `
    -ProxyUrl "http://proxy.firma.ch:8080" -ProxyUseDefaultCredentials

# Mit expliziten Proxy-Anmeldedaten
Connect-Confluence -BaseUrl "https://deinefirma.atlassian.net" -Email "du@firma.ch" -ApiToken $Token `
    -ProxyUrl "http://proxy.firma.ch:8080" -ProxyCredential (Get-Credential)
```

| Parameter (`Connect-Confluence`) | Beschreibung |
|---|---|
| `-ProxyUrl` | Proxy-URI, z.B. `http://proxy.firma.ch:8080`. Hat Vorrang vor `-ProxyServer`, falls beide fehlen wird kein Proxy verwendet. |
| `-ProxyUseDefaultCredentials` | Verwendet die aktuellen Windows-Anmeldedaten für die Proxy-Authentifizierung. |
| `-ProxyCredential` | Explizite Anmeldedaten für die Proxy-Authentifizierung (überschreibt `-ProxyUseDefaultCredentials`). |

## Funktionen

| Funktion | Beschreibung |
|---|---|
| `Connect-Confluence` | Stellt die Verbindung zu Confluence Cloud her (inkl. optionalem Proxy) |
| `Disconnect-Confluence` | Trennt die aktuelle Verbindung |
| `Get-ConfluencePage` | Ruft eine oder mehrere Seiten ab |
| `New-ConfluencePage` | Erstellt eine neue Seite |
| `Update-ConfluencePage` | Aktualisiert eine bestehende Seite (neue Version) |
| `Remove-ConfluencePage` | Löscht eine Seite (Papierkorb) |
| `Get-ConfluenceAttachment` | Listet Anhänge einer Seite auf |
| `Add-ConfluenceAttachment` | Lädt eine Datei als Anhang hoch |
| `Save-ConfluenceAttachment` | Lädt einen Anhang lokal herunter |
| `Remove-ConfluenceAttachment` | Löscht einen Anhang |
| `ConvertTo-ConfluenceStorageFormat` | Wandelt Text/HTML in das Confluence-Storage-Format um |
| `Set-ConfluenceProxyConfig` | Legt ein benanntes Proxy-Profil in der Konfigurationsdatei an/aktualisiert es |

## Beispiele

```powershell
# Seite abrufen
Get-ConfluencePage -SpaceId 123456

# Seite mit reinem Text erstellen
$body = ConvertTo-ConfluenceStorageFormat -InputText "Erste Zeile`nZweite Zeile" -PlainText
New-ConfluencePage -SpaceId 123456 -Title "Neue Seite" -Body $body

# Seite aktualisieren
Update-ConfluencePage -PageId 789 -Body "<p>Neuer Inhalt</p>"

# Anhang hochladen / herunterladen
Add-ConfluenceAttachment -PageId 789 -FilePath "C:\Dateien\bericht.pdf"
Get-ConfluenceAttachment -PageId 789
Get-ConfluenceAttachment -PageId 789 -FileNameFilter "bericht.pdf"
Save-ConfluenceAttachment -AttachmentId 111 -OutFile "C:\Downloads\datei.pdf"

# Seite löschen
Remove-ConfluencePage -PageId 789
```

## Hinweis

Alle Funktionen nutzen die Confluence Cloud REST API v2 (`/wiki/api/v2/...`), `Add-ConfluenceAttachment` nutzt aus Kompatibilitätsgründen die v1-API (`/wiki/rest/api/...`) für den Multipart-Upload.

## Changelog

### Unreleased

- `Connect-Confluence`: neuer `-ClientId`/`-ClientSecret`-Parameter (ParameterSetName `ServiceAccount`) für OAuth 2.0 Service Accounts (`client_credentials`-Grant, kein Browser-Login nötig). OAuth2-Bearer-Verbindungen (`-AccessToken` und `-ClientId`/`-ClientSecret`) laufen neu über das `api.atlassian.com/ex/confluence/{cloudId}`-Gateway statt direkt über die Tenant-Domain; die Cloud-ID wird intern über `<BaseUrl>/_edge/tenant_info` ermittelt. Das Rückgabeobjekt enthält neu die Felder `ClientId` und `TokenExpiresAt`.
- `Connect-Confluence`: neuer `-AccessToken`-Parameter (ParameterSetName `OAuth2`) als Alternative zu `-Email`/`-ApiToken` — ermöglicht Authentifizierung über einen OAuth2 Bearer Token (z.B. aus dem Atlassian Authorization Code / PKCE-Flow). Das Rückgabeobjekt enthält neu das Feld `AuthMethod`.
- `Get-ConfluenceAttachment`: neuer `-FileNameFilter`-Parameter, filtert Anhänge über den `filename`-Query-Parameter der API nach exaktem Dateinamen.

### 1.1.0 (2026-06-30)

- Fix: `ConvertTo-ConfluenceStorageFormat`/`-Markdown` akzeptiert jetzt leere Tabellenzellen/Zeilen, statt mit einem Validierungsfehler abzubrechen.
- Fix: API-Fehlerbehandlung funktioniert jetzt sowohl unter Windows PowerShell 5.1 als auch PowerShell 7+ (unterschiedliche Response-Objekte beim Fehlschlagen von `Invoke-RestMethod`).
- `ConvertTo-ConfluenceStorageFormat`: neuer `-Markdown`-Switch — wandelt Überschriften, Listen, Tabellen (`| ... |` und `||...||`) sowie Inline-Formatierung (`**fett**`, `*kursiv*`, `` `code` ``, `[Text](URL)`) in Storage-Format um.
- LICENSE (MIT) sowie PSGallery-Metadaten (Tags, LicenseUri, ProjectUri, ReleaseNotes) ergänzt.
- VS-Code-Workspace-Konfiguration (`.vscode/`) und Modul-Cleanup-Hook (`Invoke-ModuleCleanup`, trennt die Verbindung automatisch bei `Remove-Module`/Sitzungsende) ergänzt.
- Fix: `BaseUrl` mit angehängtem `/wiki` führte zu doppeltem `/wiki/wiki/` in den API-Pfaden — wird jetzt automatisch normalisiert.
- `-ProxyServer` bei `Connect-Confluence` unterstützt jetzt Tab-Completion anhand der Profile in `ProxyConfig.json`.
- Proxy-Konfiguration über benannte Profile in `Configurations\ProxyConfig.json` (`Set-ConfluenceProxyConfig`, `-ProxyServer`) ergänzt, als Alternative zu den direkten `-ProxyUrl`/`-ProxyUseDefaultCredentials`/`-ProxyCredential`-Parametern.
- Verbindungszustand wird modul-intern (`$script:`-Scope) statt global verwaltet.
- Modul auf das versionierte `Public`/`Private`-Layout umgestellt.

### 1.0.0 (2026-06-29)

- Initiale Veröffentlichung auf der PowerShell Gallery.
- Seiten lesen/erstellen/aktualisieren/löschen (`Get-/New-/Update-/Remove-ConfluencePage`).
- Anhänge verwalten (`Get-/Add-/Save-/Remove-ConfluenceAttachment`).
- API-Token-Authentifizierung (`Connect-Confluence`/`Disconnect-Confluence`).
- `ConvertTo-ConfluenceStorageFormat` für reinen Text/HTML.

## Lizenz

MIT

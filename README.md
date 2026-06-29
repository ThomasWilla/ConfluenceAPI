# ConfluenceCloud

PowerShell-Modul für die Confluence Cloud REST API (v2). Ermöglicht das Lesen, Erstellen und Bearbeiten von Seiten sowie das Verwalten von Anhängen über API-Token-Authentifizierung.

## Installation

```powershell
git clone https://github.com/ThomasWilla/ConfluenceCloud.git
Import-Module "C:\Pfad\zu\ConfluenceCloud\ConfluenceCloud.psd1"
```

## Voraussetzungen

- PowerShell 5.1 oder höher
- Ein Atlassian API-Token: https://id.atlassian.com/manage-profile/security/api-tokens

## Verbindung herstellen

```powershell
Connect-Confluence -BaseUrl "https://deinefirma.atlassian.net" -Email "du@firma.ch" -ApiToken (Read-Host -AsSecureString)
```

## Funktionen

| Funktion | Beschreibung |
|---|---|
| `Connect-Confluence` | Stellt die Verbindung zu Confluence Cloud her |
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
Save-ConfluenceAttachment -AttachmentId 111 -OutFile "C:\Downloads\datei.pdf"

# Seite löschen
Remove-ConfluencePage -PageId 789
```

## Hinweis

Alle Funktionen nutzen die Confluence Cloud REST API v2 (`/wiki/api/v2/...`), `Add-ConfluenceAttachment` nutzt aus Kompatibilitätsgründen die v1-API (`/wiki/rest/api/...`) für den Multipart-Upload.

## Lizenz

MIT

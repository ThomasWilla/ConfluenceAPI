# ConfluenceAPI

[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/ConfluenceAPI.svg)](https://www.powershellgallery.com/packages/ConfluenceAPI)
[![PowerShell Gallery Downloads](https://img.shields.io/powershellgallery/dt/ConfluenceAPI.svg)](https://www.powershellgallery.com/packages/ConfluenceAPI)

> 🇩🇪 [Deutsche Version](README.md)

PowerShell module for the Confluence Cloud REST API (v2). Read, create and update pages, manage attachments — using API token, OAuth2, or OAuth2 service account authentication, with optional proxy support.

## Installation

From the PowerShell Gallery ([ConfluenceAPI](https://www.powershellgallery.com/packages/ConfluenceAPI)):

```powershell
Install-Module -Name ConfluenceAPI
```

Or directly from the repo:

```powershell
git clone https://github.com/ThomasWilla/ConfluenceAPI.git
Import-Module "C:\path\to\ConfluenceAPI\1.2.0\ConfluenceAPI.psd1"
```

## Structure

```
ConfluenceAPI/
└── 1.2.0/
    ├── ConfluenceAPI.psd1
    ├── ConfluenceAPI.psm1
    ├── Public/      # One function per file, exported
    └── Private/     # Internal helpers (API wrapper, proxy resolution)
```

## Prerequisites

- PowerShell 5.1 or higher
- An Atlassian API token: https://id.atlassian.com/manage-profile/security/api-tokens

## Connecting

### API Token (Basic Auth)

```powershell
Connect-Confluence -BaseUrl "https://yourcompany.atlassian.net" -Email "you@company.com" -ApiToken (Read-Host -AsSecureString)
```

### OAuth2 Bearer Token

Pass an OAuth2 access token obtained via the Atlassian OAuth 2.0 (3LO) Authorization Code / PKCE flow:

```powershell
Connect-Confluence -BaseUrl "https://yourcompany.atlassian.net" -AccessToken $BearerToken
```

Create an OAuth 2.0 app at [developer.atlassian.com](https://developer.atlassian.com/console/myapps/). The module accepts the token as `[string]`, `[SecureString]`, or `[PSCredential]` (token in the Password field).

### OAuth2 Service Account (Client Credentials)

For fully automated scenarios without a browser login, use an OAuth 2.0 service account credential (Client ID / Secret):

```powershell
Connect-Confluence -BaseUrl "https://yourcompany.atlassian.net" -ClientId $ClientId -ClientSecret (Read-Host -AsSecureString)
```

Create the credential under **Atlassian Administration → Directory → Service accounts → Create credentials** (not via developer.atlassian.com). Select the required Confluence scopes there, including `read:space:confluence` (required for the connection test), plus `read:page:confluence`, `write:page:confluence`, `read:attachment:confluence`, `write:attachment:confluence`, `delete:page:confluence`, `delete:attachment:confluence` as needed. The service account also requires product access to Confluence on the respective site.

The module fetches the access token internally via `client_credentials` grant (valid 60 minutes) and **renews it automatically** when it expires — transparently before the next API call, without needing to call `Connect-Confluence` again.

> **Note:** OAuth2 Bearer tokens (both `-AccessToken` and `-ClientId`/`-ClientSecret`) are not validated directly against the tenant domain. The module resolves the Cloud ID internally via the unauthenticated endpoint `<BaseUrl>/_edge/tenant_info` and routes all API calls through `https://api.atlassian.com/ex/confluence/{cloudId}/...`. Basic Auth (API token) still calls the tenant domain directly.

> **Troubleshooting `404 Not Found` on write operations (e.g. `Update-ConfluencePage`):** If `Get-ConfluencePage` succeeds on the same page but `Update-`/`Remove-ConfluencePage` returns `404`, the cause is usually page restrictions (Confluence page → "..." → Restrictions) or missing space permissions for the service account — not missing OAuth scopes.

### Proxy Support

If your network requires an outbound proxy, configure it at connect time. The setting applies to all calls in the session. Two options are available: named profiles from a config file, or inline parameters.

#### Option 1: Named proxy profiles from a config file

```powershell
# Create / update profiles once
Set-ConfluenceProxyConfig -Name "corp-proxy" -ProxyUrl "http://proxy.company.com:8080" -UseDefaultCredentials

# Connect using a profile
Connect-Confluence -BaseUrl "https://yourcompany.atlassian.net" -Email "you@company.com" -ApiToken $Token -ProxyServer "corp-proxy"
```

The config file defaults to `<ModuleRoot>\Configurations\ProxyConfig.json`. Use `-ConfigPath` (on `Set-ConfluenceProxyConfig`) or `-ProxyConfigPath` (on `Connect-Confluence`) to point it elsewhere.

| Parameter (`Set-ConfluenceProxyConfig`) | Description |
|---|---|
| `-Name` | Freely chosen profile name, e.g. `corp-proxy`. |
| `-ProxyUrl` | Proxy URI, e.g. `http://proxy.company.com:8080`. |
| `-UseDefaultCredentials` | Authenticate with current Windows credentials. |
| `-ConfigPath` | Path to the config file (default: `<ModuleRoot>\Configurations\ProxyConfig.json`). |

| Parameter (`Connect-Confluence`) | Description |
|---|---|
| `-ProxyServer` | Name of a profile from the config file. |
| `-ProxyConfigPath` | Path to the config file, if different from the default. |

#### Option 2: Specify the proxy inline

```powershell
# With current Windows credentials
Connect-Confluence -BaseUrl "https://yourcompany.atlassian.net" -Email "you@company.com" -ApiToken $Token `
    -ProxyUrl "http://proxy.company.com:8080" -ProxyUseDefaultCredentials

# With explicit proxy credentials
Connect-Confluence -BaseUrl "https://yourcompany.atlassian.net" -Email "you@company.com" -ApiToken $Token `
    -ProxyUrl "http://proxy.company.com:8080" -ProxyCredential (Get-Credential)
```

## Functions

| Function | Description |
|---|---|
| `Connect-Confluence` | Connect to Confluence Cloud (with optional proxy) |
| `Disconnect-Confluence` | Disconnect the current session |
| `Get-ConfluencePage` | Retrieve one or more pages |
| `New-ConfluencePage` | Create a new page |
| `Update-ConfluencePage` | Update an existing page (increments version) |
| `Remove-ConfluencePage` | Delete a page (moves to trash) |
| `Get-ConfluenceAttachment` | List attachments on a page |
| `Add-ConfluenceAttachment` | Upload a file as an attachment |
| `Save-ConfluenceAttachment` | Download an attachment locally |
| `Remove-ConfluenceAttachment` | Delete an attachment |
| `ConvertTo-ConfluenceStorageFormat` | Convert text/Markdown/HTML to Confluence Storage Format |
| `Set-ConfluenceProxyConfig` | Create or update a named proxy profile in the config file |

## Examples

```powershell
# Get pages
Get-ConfluencePage -SpaceId 123456

# Create a page with plain text
$body = ConvertTo-ConfluenceStorageFormat -InputText "Line 1`nLine 2" -PlainText
New-ConfluencePage -SpaceId 123456 -Title "New Page" -Body $body

# Create a page from Markdown
$md = "# Heading`n`n**Bold** and *italic* text."
$body = ConvertTo-ConfluenceStorageFormat -InputText $md -Markdown
New-ConfluencePage -SpaceId 123456 -Title "Markdown Page" -Body $body

# Update a page
Update-ConfluencePage -PageId 789 -Body "<p>New content</p>"

# Upload and download attachments
Add-ConfluenceAttachment -PageId 789 -FilePath "C:\Files\report.pdf"
Get-ConfluenceAttachment -PageId 789
Get-ConfluenceAttachment -PageId 789 -FileNameFilter "report.pdf"
Save-ConfluenceAttachment -AttachmentId 111 -OutFile "C:\Downloads\file.pdf"

# Delete a page
Remove-ConfluencePage -PageId 789
```

## Notes

All functions use the Confluence Cloud REST API v2 (`/wiki/api/v2/...`). `Add-ConfluenceAttachment` uses the v1 API (`/wiki/rest/api/...`) for the multipart upload due to compatibility reasons.

## Changelog

### Unreleased

- Fix: Write operations (`New-`/`Update-ConfluencePage`, etc.) could fail under Windows PowerShell 5.1 with `400 Bad Request "Invalid UTF-8 middle byte"` when the payload contained special characters. The JSON body is now explicitly converted to UTF-8 bytes before sending.

### 1.2.0 (2026-07-07)

- `Connect-Confluence`: new `-ClientId`/`-ClientSecret` parameters (ParameterSetName `ServiceAccount`) for OAuth 2.0 service accounts (`client_credentials` grant, no browser login required). OAuth2 Bearer connections route through the `api.atlassian.com/ex/confluence/{cloudId}` gateway; Cloud ID is resolved via `<BaseUrl>/_edge/tenant_info`. Return object now includes `ClientId` and `TokenExpiresAt`.
- Service account connections automatically renew the access token (valid 60 min) before expiry — no manual reconnect needed.
- `Connect-Confluence`: new `-AccessToken` parameter (ParameterSetName `OAuth2`) as an alternative to `-Email`/`-ApiToken`. Return object now includes `AuthMethod`.
- `Get-ConfluenceAttachment`: new `-FileNameFilter` parameter to filter by exact filename via the API's `filename` query parameter.

### 1.1.0 (2026-06-30)

- Fix: `ConvertTo-ConfluenceStorageFormat -Markdown` now accepts empty table cells/rows instead of throwing a validation error.
- Fix: API error handling now works under both Windows PowerShell 5.1 and PowerShell 7+.
- `ConvertTo-ConfluenceStorageFormat`: new `-Markdown` switch — converts headings, lists, tables (`| ... |` and `||...||`), and inline formatting (`**bold**`, `*italic*`, `` `code` ``, `[text](url)`) to Storage Format.
- Added LICENSE (MIT) and PSGallery metadata (Tags, LicenseUri, ProjectUri, ReleaseNotes).
- Added VS Code workspace config (`.vscode/`) and module cleanup hook (`Invoke-ModuleCleanup`).
- Fix: `-BaseUrl` with a trailing `/wiki` no longer causes duplicate `/wiki/wiki/` in API paths.
- `-ProxyServer` on `Connect-Confluence` now supports tab-completion from `ProxyConfig.json` profiles.
- Added configurable proxy profiles via `Configurations\ProxyConfig.json` (`Set-ConfluenceProxyConfig`, `-ProxyServer`).
- Connection state is now managed module-internally (`$script:` scope) instead of globally.
- Module restructured to versioned `Public`/`Private` layout.

### 1.0.0 (2026-06-29)

- Initial release on PowerShell Gallery.
- Read/create/update/delete pages (`Get-/New-/Update-/Remove-ConfluencePage`).
- Manage attachments (`Get-/Add-/Save-/Remove-ConfluenceAttachment`).
- API token authentication (`Connect-Confluence`/`Disconnect-Confluence`).
- `ConvertTo-ConfluenceStorageFormat` for plain text/HTML.

## License

MIT

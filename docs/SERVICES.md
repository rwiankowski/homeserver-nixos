# Service Configuration Guide

This guide covers initial configuration for each service after deployment.

## Service URLs

All services are accessible at `https://servicename.home.yourdomain.com` via Tailscale.

---

## Homepage Dashboard

**URL**: `https://home.home.yourdomain.com`

### Initial Setup

Homepage is auto-configured with all services. No initial setup needed!

### Customization

```bash
# On server
cd /mnt/shared/homepage

# Edit services
vim services.yaml

# Edit appearance
vim settings.yaml

# Restart to apply
docker restart homepage
```

**Tip**: Bookmark this URL - it's your central hub for all services!

---

## Authentik SSO

**URL**: `https://authentik.home.yourdomain.com`

### Initial Setup

1. First visit runs setup wizard
2. Create admin account
3. Set up email (optional)

### Configure SSO for Services

#### For Jellyfin (LDAP)

1. Authentik → Applications → Create
2. Name: Jellyfin
3. Provider: LDAP
4. Bind DN: Auto-generated
5. In Jellyfin: Settings → LDAP → Add

#### For NextCloud (OIDC)

1. Authentik → Applications → Create
2. Provider: OAuth2/OIDC
3. Redirect URI: `https://nextcloud.home.yourdomain.com/apps/oidc_login/redirect`
4. In NextCloud: Install OIDC app, configure

#### For Other Services

Most modern services support OAuth2/OIDC. Check each service's documentation.

---

## Jellyfin Media Server

**URL**: `https://jellyfin.home.yourdomain.com`

### Initial Setup

1. Create admin account
2. Select language and preferences
3. Add media libraries:
   - Movies: `/mnt/media/jellyfin/movies`
   - TV Shows: `/mnt/media/jellyfin/tv`
   - Music: `/mnt/media/jellyfin/music`

### Add Media

```bash
# SSH to server
# Copy media files
scp -r ~/Movies/* root@server:/mnt/media/jellyfin/movies/

# Or use SMB/NFS share (configure separately)
```

### Configure Transcoding

For GPU transcoding (if you have GPU):

1. Dashboard → Playback
2. Hardware acceleration: Select your GPU
3. Enable hardware decoding

### Install Clients

- **iOS/Android**: Search "Jellyfin" in app stores
- **TV Apps**: Available for Roku, Fire TV, Apple TV, Android TV
- **Desktop**: Web browser works great

---

## *arr Stack (Sonarr, Radarr, Prowlarr, Bazarr)

### Prowlarr (Indexer Manager)

**URL**: `https://prowlarr.home.yourdomain.com`

1. Settings → Indexers → Add
2. Add your preferred indexers
3. Settings → Apps → Add Sonarr/Radarr
4. Test connection

### Sonarr (TV Shows)

**URL**: `https://sonarr.home.yourdomain.com`

1. Settings → Media Management
   - Root folder: `/mnt/media/jellyfin/tv`
2. Settings → Download Clients
   - Add Transmission: `http://localhost:9091`
3. Settings → Indexers
   - Auto-sync from Prowlarr
4. Series → Add Series

### Radarr (Movies)

**URL**: `https://radarr.home.yourdomain.com`

Same as Sonarr, but:
- Root folder: `/mnt/media/jellyfin/movies`

### Bazarr (Subtitles)

**URL**: `https://bazarr.home.yourdomain.com`

1. Settings → Sonarr → Add connection
2. Settings → Radarr → Add connection
3. Settings → Providers → Add subtitle providers
4. Settings → Languages → Select your languages

---

## Immich Photo Management

**URL**: `https://immich.home.yourdomain.com`

### Initial Setup

1. Create admin account
2. Configure storage settings (defaults are good)

### Mobile Apps

1. **iOS**: App Store → "Immich"
2. **Android**: Play Store → "Immich"

### Configure Auto-Upload

1. Open mobile app
2. Settings → Backup
3. Enable automatic backup
4. Select albums to backup

### Features

- AI-powered face recognition
- Location-based organization
- Shared albums
- Mobile/web access
- RAW photo support

---

## NextCloud File Sync

**URL**: `https://nextcloud.home.yourdomain.com`

### Initial Setup

Admin credentials from `/etc/nextcloud-admin-pass` on server.

### Install Apps

1. Apps → Search for:
   - Calendar
   - Contacts
   - Talk (chat/video calls)
   - Notes
   - Deck (project management)

### Desktop Sync Client

1. Download from https://nextcloud.com/install/#install-clients
2. Add account: `https://nextcloud.home.yourdomain.com`
3. Select folders to sync

### Mobile Apps

- iOS/Android: Search "NextCloud" in app stores

---

## Paperless-ngx Document Management

**URL**: `https://paperless.home.yourdomain.com`

### Initial Setup

Login with credentials from `/etc/paperless-password` on server.

### Add Documents

**Method 1: Web Upload**
- Click "Upload" → Select files

**Method 2: Consumption Folder**
```bash
# Copy files to consumption folder
scp document.pdf root@server:/mnt/docs/paperless/consume/
# Paperless auto-processes them
```

**Method 3: Email** (configure separately)

### Organization

1. Create document types: Personal, Work, Taxes, etc.
2. Create tags: Important, Urgent, Archive, etc.
3. Set up correspondents: Banks, employers, etc.

### OCR Languages

Default: English. To add more:

```bash
# On server
vim /etc/nixos/modules/paperless.nix

# Add to settings:
PAPERLESS_OCR_LANGUAGE = "eng+deu+fra";  # English + German + French

# Rebuild
sudo nixos-rebuild switch --flake .#homeserver
```

---

## Mealie Recipe Manager

**URL**: `https://mealie.home.yourdomain.com`

### Initial Setup

1. Create account (first user is admin)
2. Configure preferences

### Add Recipes

**Method 1: Import from URL**
- Recipe → Import → Paste URL
- Supports most popular recipe sites

**Method 2: Manual Entry**
- Recipe → Create New

### Meal Planning

1. Meal Plan → Create plan
2. Add recipes to days
3. Generate shopping list

---

## Audiobookshelf

**URL**: `https://audiobooks.home.yourdomain.com`

### Initial Setup

1. Create admin account
2. Create library:
   - Type: Audiobooks
   - Folder: `/audiobooks`

### Add Content

```bash
# Copy audiobooks
scp -r audiobook-folder/ root@server:/mnt/media/audiobooks/
```

### Mobile Apps

- iOS/Android: Search "Audiobookshelf"
- Download audiobooks for offline listening

---

## Home Assistant

**URL**: `https://hass.home.yourdomain.com`

### Initial Setup

1. Create account
2. Set location
3. Complete onboarding

### Add Integrations

1. Settings → Devices & Services → Add Integration
2. Search for your smart home devices:
   - Philips Hue
   - Google Home
   - Z-Wave
   - MQTT
   - etc.

### Create Automations

1. Settings → Automations
2. Create automation
3. Example: Turn on lights at sunset

---

## Open WebUI (LLM Assistant)

**URL**: `https://llm.home.yourdomain.com`

### Initial Setup

1. Create account (first user is admin)

### Pull Models

```bash
# SSH to server

# Small model (7B, ~4GB)
ollama pull llama3.1:8b

# Large model (70B, ~40GB, needs 64GB RAM)
ollama pull llama3.1:70b

# Code-specialized
ollama pull codellama:13b

# List models
ollama list
```

### Configure Web Search

1. Settings → Web Search
2. Enable search
3. SearXNG is already configured!

### Usage Tips

- Use for coding help
- Ask questions with web search enabled
- Create custom prompts
- Chat history is saved

---

## Grafana Monitoring

**URL**: `https://grafana.home.yourdomain.com`

### Initial Setup

Login with credentials from `secrets.yaml`.

### Import CrowdSec Dashboard

1. Dashboards → Import
2. Dashboard ID: `14524`
3. Select Prometheus datasource
4. Import

Shows real-time security metrics!

---

## pgAdmin Database Management

**URL**: `https://pgadmin.home.yourdomain.com`

### Initial Setup

Login with credentials from `secrets.yaml`.

### Add Server

1. Right-click Servers → Register → Server
2. General: Name: "Homeserver"
3. Connection:
   - Host: localhost
   - Port: 5432
   - Database: postgres
   - Username: postgres
4. Save

Now you can browse all databases!

---

## Service Dependencies

Some services depend on others:

```
Authentik → Can provide SSO for all services
PostgreSQL → Used by Authentik, Immich, NextCloud, Paperless
Prowlarr → Syncs indexers to Sonarr/Radarr
Sonarr/Radarr → Send downloads to Transmission → Files go to Jellyfin
```

---

## Common Tasks

### Restart a Service

```bash
# NixOS service
sudo systemctl restart jellyfin

# Docker container
docker restart immich-server
```

### View Logs

```bash
# NixOS service
journalctl -u jellyfin -f

# Docker container
docker logs -f immich-server
```

### Check Service Status

```bash
systemctl status jellyfin
docker ps | grep immich
```

---

## Enable/Disable Services

Edit `/etc/nixos/configuration.nix`:

```nix
imports = [
  ./modules/jellyfin.nix     # Enabled
  # ./modules/paperless.nix  # Disabled (commented out)
];
```

Then rebuild:
```bash
sudo nixos-rebuild switch --flake .#homeserver
```

---

## Getting Help

- Service-specific docs: Check each service's official documentation
- NixOS issues: `journalctl -u servicename`
- Docker issues: `docker logs containername`
- General issues: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

**All services configured? Time to enjoy your self-hosted cloud! ☁️**

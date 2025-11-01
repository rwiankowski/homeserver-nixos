# Service Configuration Guide

This guide covers initial configuration for each service after deployment.

## Service URLs

All services are accessible at `https://servicename.home.yourdomain.com` via Tailscale.

---

## Homepage Dashboard

**URL**: `https://home.home.yourdomain.com`  
**Port**: 3001 (internal)

### Initial Setup

Homepage is auto-configured with all services. No initial setup needed!

### Customisation

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

## Homarr Dashboard

**URL**: `https://homarr.home.yourdomain.com`  
**Port**: 7575 (internal)

Homarr is a modern, customisable dashboard with advanced features like service monitoring, Docker integration, and beautiful widgets.

### Initial Setup

1. **First Visit**
   - No authentication required initially
   - You'll see a default dashboard

2. **Add Services**
   - Click "Edit" (pencil icon)
   - Click "Add a tile"
   - Configure service:
     - Name: e.g., "Jellyfin"
     - URL: `https://jellyfin.home.yourdomain.com`
     - Icon: Search for service icon
     - Type: Select "Service"
   - Save tile

### Service Integration

Homarr can integrate directly with many services to show live stats:

#### Sonarr/Radarr/Readarr/Lidarr Integration

1. Add service tile
2. Integration tab:
   - Type: Select service type (Sonarr, Radarr, etc.)
   - URL: `http://localhost:PORT`
   - API Key: (from service settings)
3. Save

Now the tile shows:
- Queue status
- Missing items
- Recent additions
- Calendar

#### qBittorrent Integration

1. Add service tile
2. Integration tab:
   - Type: qBittorrent
   - URL: `http://localhost:8282`
   - Username/Password: (your credentials)
3. Save

Shows active torrents and download speed!

#### Docker Integration

Homarr has access to Docker socket and can show container status:

1. Settings → Docker
2. Enable Docker integration
3. Containers will show status indicators

### Widgets

Add useful widgets to your dashboard:

1. **Weather Widget**
   - Add widget → Weather
   - Configure location
   - Choose temperature units

2. **Calendar Widget**
   - Shows upcoming releases from Sonarr/Radarr
   - Auto-populated from integrations

3. **Media Requests**
   - If Jellyseerr is configured
   - Shows pending requests

4. **System Resources**
   - CPU, RAM, disk usage
   - Requires integration setup

### Customisation

- **Themes**: Settings → Appearance → Choose theme
- **Layout**: Drag and drop tiles to rearrange
- **Categories**: Group services into categories
- **Background**: Settings → Appearance → Custom background

### Multiple Dashboards

Create different dashboards for different purposes:
- Media dashboard
- Home automation dashboard
- System monitoring dashboard

### User Management

1. Settings → Users
2. Add users with different permission levels
3. Share dashboard with family members

**Tip**: Homarr is great for users who want a more visual, interactive dashboard compared to Homepage's simplicity.

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
**Port**: 8096 (internal)

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

## Jellyseerr Media Requests

**URL**: `https://jellyseerr.home.yourdomain.com`  
**Port**: 5055 (internal)

Jellyseerr provides a beautiful interface for users to request movies and TV shows, which are then automatically sent to Sonarr/Radarr for download.

### Initial Setup

1. **Sign in with Jellyfin**
   - Click "Use your Jellyfin account"
   - Enter Jellyfin URL: `http://localhost:8096`
   - Sign in with your Jellyfin admin account
   - Grant permissions

2. **Configure Jellyfin**
   - Server: `http://localhost:8096`
   - Select libraries to sync (Movies, TV Shows)
   - Test connection

3. **Connect Sonarr**
   - Settings → Services → Sonarr
   - Default Server: Enable
   - Server Name: "Sonarr"
   - Hostname/IP: `localhost`
   - Port: `8989`
   - API Key: (copy from Sonarr → Settings → General)
   - Quality Profile: Select default
   - Root Folder: Select `/mnt/media/jellyfin/tv`
   - Test and Save

4. **Connect Radarr**
   - Settings → Services → Radarr
   - Default Server: Enable
   - Server Name: "Radarr"
   - Hostname/IP: `localhost`
   - Port: `7878`
   - API Key: (copy from Radarr → Settings → General)
   - Quality Profile: Select default
   - Root Folder: Select `/mnt/media/jellyfin/movies`
   - Test and Save

### User Management

1. **Import Jellyfin Users**
   - Settings → Users → Import Jellyfin Users
   - Select users to import

2. **Set Permissions**
   - Settings → Users → Select user
   - Configure request limits and permissions:
     - Request movies/TV shows
     - Auto-approve requests
     - Request limits per day/week

### Making Requests

Users can now:
1. Browse or search for movies/TV shows
2. Click "Request"
3. Track request status
4. Get notified when available in Jellyfin

### Notifications

Configure notifications for request updates:
- Settings → Notifications
- Add Discord, Email, Telegram, etc.
- Customise notification triggers

---

## qBittorrent Download Client

**URL**: `https://qbittorrent.home.yourdomain.com`  
**Port**: 8282 (internal)

### ⚠️ Initial Setup - CRITICAL

**Default credentials**: `admin` / `adminadmin`

**YOU MUST CHANGE THIS IMMEDIATELY!**

1. Login with default credentials
2. Tools → Options → Web UI
3. Change password under "Authentication"
4. Save changes

### Configure Download Directories

1. Tools → Options → Downloads
2. Default Save Path: `/mnt/media/downloads`
3. Keep incomplete torrents in: `/mnt/media/downloads/.incomplete`
4. Enable "Create subfolder for torrents with multiple files"

### Set Up Categories

Create categories for different media types:

1. Right-click in Categories pane → Add category
2. Create these categories:
   - **tv-sonarr**: Save path `/mnt/media/jellyfin/tv`
   - **movies-radarr**: Save path `/mnt/media/jellyfin/movies`
   - **books-readarr**: Save path `/mnt/media/books`
   - **music-lidarr**: Save path `/mnt/media/jellyfin/music`

### Integration with *arr Apps

When configuring download clients in Sonarr/Radarr/Readarr/Lidarr:

1. Settings → Download Clients → Add → qBittorrent
2. Host: `localhost`
3. Port: `8282`
4. Username: `admin`
5. Password: (your new password)
6. Category: (use the appropriate category from above)
7. Test and Save

---

## *arr Stack (Sonarr, Radarr, Readarr, Lidarr, Prowlarr, Bazarr)

### Prowlarr (Indexer Manager)

**URL**: `https://prowlarr.home.yourdomain.com`  
**Port**: 9696 (internal)

Prowlarr manages indexers for all *arr applications.

#### Initial Setup

1. Settings → Indexers → Add Indexer
2. Add your preferred indexers (public or private)
3. Configure each indexer with required credentials

#### Connect to *arr Apps

1. Settings → Apps → Add Application
2. Add each app:
   - **Sonarr**: `http://localhost:8989`, API key from Sonarr
   - **Radarr**: `http://localhost:7878`, API key from Radarr
   - **Readarr**: `http://localhost:8787`, API key from Readarr
   - **Lidarr**: `http://localhost:8686`, API key from Lidarr
3. Test connections
4. Sync → This will push all indexers to connected apps

### Sonarr (TV Shows)

**URL**: `https://sonarr.home.yourdomain.com`  
**Port**: 8989 (internal)

#### Initial Setup

1. **Media Management**
   - Settings → Media Management
   - Root Folder: `/mnt/media/jellyfin/tv`
   - Enable "Rename Episodes"
   - Set your preferred naming scheme

2. **Download Client**
   - Settings → Download Clients → Add → qBittorrent
   - Host: `localhost`, Port: `8282`
   - Username/Password: (your qBittorrent credentials)
   - Category: `tv-sonarr`
   - Test and Save

3. **Indexers**
   - Auto-synced from Prowlarr
   - Or manually add: Settings → Indexers → Add

4. **Quality Profiles**
   - Settings → Profiles
   - Customise quality preferences (1080p, 4K, etc.)

#### Add TV Series

1. Series → Add New Series
2. Search for show
3. Select quality profile and root folder
4. Monitor: All episodes or specific seasons
5. Add Series

### Radarr (Movies)

**URL**: `https://radarr.home.yourdomain.com`  
**Port**: 7878 (internal)

Configuration is similar to Sonarr:

1. **Root Folder**: `/mnt/media/jellyfin/movies`
2. **Download Client**: qBittorrent with category `movies-radarr`
3. **Quality Profiles**: Customise for movies
4. **Indexers**: Auto-synced from Prowlarr

#### Add Movies

1. Movies → Add New Movie
2. Search for movie
3. Select quality profile and root folder
4. Monitor: Yes
5. Add Movie

### Readarr (Ebooks & Audiobooks)

**URL**: `https://readarr.home.yourdomain.com`  
**Port**: 8787 (internal)

#### Initial Setup

1. **Media Management**
   - Settings → Media Management
   - Root Folder: `/mnt/media/books`
   - Enable "Rename Books"

2. **Download Client**
   - Settings → Download Clients → Add → qBittorrent
   - Host: `localhost`, Port: `8282`
   - Category: `books-readarr`

3. **Metadata Profiles**
   - Settings → Profiles → Metadata Profiles
   - Choose what to monitor (ebooks, audiobooks, or both)

4. **Calibre Integration** (Optional)
   - If you use Calibre, configure under Settings → Metadata

#### Add Books

1. Library → Add New Book
2. Search by title or author
3. Select metadata profile
4. Add Book

**Tip**: Readarr works best with private trackers that have good ebook collections.

### Lidarr (Music)

**URL**: `https://lidarr.home.yourdomain.com`  
**Port**: 8686 (internal)

#### Initial Setup

1. **Media Management**
   - Settings → Media Management
   - Root Folder: `/mnt/media/jellyfin/music`
   - Enable "Rename Tracks"
   - Set naming format for albums/tracks

2. **Download Client**
   - Settings → Download Clients → Add → qBittorrent
   - Host: `localhost`, Port: `8282`
   - Category: `music-lidarr`

3. **Quality Profiles**
   - Settings → Profiles → Quality Profiles
   - Customise (FLAC, MP3 320, etc.)

4. **Metadata Profiles**
   - Settings → Profiles → Metadata Profiles
   - Choose what to monitor (Studio albums, EPs, Singles, etc.)

#### Add Music

1. Library → Add New Artist
2. Search for artist
3. Select quality and metadata profiles
4. Monitor: Choose which releases to monitor
5. Add Artist

**Tip**: Lidarr can automatically monitor new releases from your favourite artists.

### Bazarr (Subtitles)

**URL**: `https://bazarr.home.yourdomain.com`  
**Port**: 6767 (internal)

#### Initial Setup

1. **Connect to Sonarr**
   - Settings → Sonarr → Add
   - Address: `http://localhost:8989`
   - API Key: (from Sonarr)

2. **Connect to Radarr**
   - Settings → Radarr → Add
   - Address: `http://localhost:7878`
   - API Key: (from Radarr)

3. **Add Subtitle Providers**
   - Settings → Providers
   - Add providers (OpenSubtitles, Subscene, etc.)
   - Configure credentials if required

4. **Configure Languages**
   - Settings → Languages
   - Add your preferred subtitle languages
   - Set language profiles

Bazarr will automatically download subtitles for your media!

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

Understanding service dependencies helps with troubleshooting:

```
Authentik → Can provide SSO for all services
PostgreSQL → Used by Authentik, Immich, NextCloud, Paperless
Prowlarr → Syncs indexers to Sonarr/Radarr/Readarr/Lidarr
Sonarr/Radarr/Readarr/Lidarr → Send downloads to qBittorrent → Files go to Jellyfin
Jellyseerr → Manages requests → Triggers Sonarr/Radarr → Downloads via qBittorrent
Homarr → Monitors Docker containers and integrates with *arr apps
```

### Typical Media Workflow

1. **User requests content** via Jellyseerr
2. **Jellyseerr** sends request to Sonarr or Radarr
3. **Sonarr/Radarr** searches indexers (via Prowlarr)
4. **Download sent** to qBittorrent
5. **qBittorrent** downloads to appropriate folder
6. **Sonarr/Radarr** renames and organises files
7. **Jellyfin** detects new media and adds to library
8. **User notified** via Jellyseerr that content is available

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

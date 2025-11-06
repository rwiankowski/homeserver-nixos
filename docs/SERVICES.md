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

Homarr is a powerful, modern dashboard for managing and monitoring all your services. This server runs **Homarr v1+** (currently v1.43.1), which represents a major upgrade with enterprise-grade features.

### What's New in v1+

Homarr v1+ includes significant improvements over the legacy version:

- ✅ **Built-in authentication** - User accounts and permission management
- ✅ **SSO support** - OIDC and LDAP integration (works with Authentik)
- ✅ **30+ integrations** - Expanded from the previous version
- ✅ **Built-in search** - Search across all services and media
- ✅ **11,000+ icons** - Massive icon library with search
- ✅ **Real-time updates** - WebSocket-based live data
- ✅ **Better performance** - Faster, more responsive interface
- ✅ **Enhanced customization** - Improved drag-and-drop, widgets, themes

**Backward compatible:** Your existing Homarr data and configuration work seamlessly with v1+.

### Initial Setup

1. **First Visit**
   - Open Homarr web interface
   - If authentication is enabled, create your admin account
   - Otherwise, you'll see a default dashboard ready to customize

2. **Enable User Management** (Recommended for shared servers)
   - Settings → Users
   - Create accounts for family members
   - Set different permission levels (view-only, editor, admin)
   - Each user gets their own personalized dashboard

3. **Add Your First Service**
   - Click "Edit" (pencil icon) to enter edit mode
   - Click "Add a tile"
   - Configure service:
     - **Name:** e.g., "Jellyfin"
     - **URL:** `https://jellyfin.home.yourdomain.com`
     - **Icon:** Use the icon picker (11K+ icons!)
     - **Type:** Select "Service"
   - Save tile

### Service Integration

Homarr v1+ supports **30+ integrations** with real-time monitoring:

#### *arr Apps Integration (Sonarr, Radarr, Readarr, Lidarr)

1. Add service tile
2. **Integration** tab:
   - **Type:** Select service type (Sonarr, Radarr, etc.)
   - **URL:** `http://localhost:PORT`
   - **API Key:** (from service Settings → General)
3. **Test** connection
4. **Save**

**Live data shown:**
- Queue status and active downloads
- Missing/wanted items count
- Recent additions to library
- Upcoming releases calendar
- Health and system status

#### qBittorrent Integration

1. Add service tile
2. **Integration** tab:
   - **Type:** qBittorrent
   - **URL:** `http://localhost:8282`
   - **Username:** `admin`
   - **Password:** (your qBittorrent password)
3. **Test** and **Save**

**Live data shown:**
- Active torrents with progress
- Download/upload speeds
- Queue status
- Completed downloads

#### Jellyfin Integration

1. Add service tile
2. **Integration** tab:
   - **Type:** Jellyfin
   - **URL:** `http://localhost:8096`
   - **API Key:** (from Jellyfin Dashboard → API Keys)
3. **Test** and **Save**

**Live data shown:**
- Currently playing media
- Active streams and users
- Library statistics
- Recent additions

#### Jellyseerr Integration

1. Add service tile
2. **Integration** tab:
   - **Type:** Jellyseerr (or Overseerr)
   - **URL:** `http://localhost:5055`
   - **API Key:** (from Jellyseerr settings)
3. **Test** and **Save**

**Live data shown:**
- Pending requests
- Request statistics
- Recently requested media

#### Docker Integration

Homarr v1+ has direct access to the Docker socket for container monitoring:

1. **Automatic detection** - Containers are auto-discovered
2. **Settings** → **Docker** → Enable integration
3. Tiles automatically show container status indicators:
   - 🟢 Running
   - 🔴 Stopped
   - 🟡 Restarting

**Actions available:**
- Start/stop containers (if permissions allow)
- View container logs
- Monitor resource usage

### Built-in Search (v1+ Feature)

One of the most powerful new features:

1. **Access search:**
   - Click the search icon in the header
   - Or press `/` keyboard shortcut

2. **Search across:**
   - All integrated services
   - Jellyfin media library
   - Sonarr/Radarr content
   - Your bookmarks and apps
   - Web (if configured)

3. **Quick actions:**
   - Jump directly to any service
   - Search for movies/TV shows
   - Open service settings
   - Launch integrations

💡 **Tip:** The search feature makes Homarr your central hub for accessing everything!

### Widgets

Homarr v1+ includes powerful widgets for enhanced functionality:

#### Available Widgets

1. **Calendar Widget**
   - Shows upcoming releases from Sonarr/Radarr
   - Auto-populated from integrations
   - Click to view details

2. **Media Requests Widget**
   - Displays Jellyseerr pending requests
   - Shows request statistics
   - Quick approve/deny actions

3. **Download Speed Widget**
   - Real-time qBittorrent stats
   - Upload/download graphs
   - Active torrent count

4. **System Resources Widget**
   - CPU usage and temperature
   - RAM usage
   - Disk space
   - Network activity

5. **Weather Widget**
   - Local weather information
   - Forecast
   - Customizable location and units

6. **RSS Feed Widget**
   - News and updates
   - Custom RSS feeds
   - Refresh intervals

7. **Docker Widget**
   - Container status overview
   - Quick start/stop actions
   - Resource monitoring

#### Adding Widgets

1. **Edit mode** → **Add Widget**
2. Select widget type
3. Configure settings (location, refresh rate, etc.)
4. Position and resize
5. **Save**

### Customisation

Homarr v1+ offers extensive customization options:

#### Themes
- **Settings** → **Appearance** → **Theme**
- Choose from built-in themes
- Light/dark mode
- Custom color schemes
- Accent colors

#### Layout
- **Drag and drop** tiles to rearrange
- **Resize tiles** by dragging corners
- **Grid system** for precise alignment
- **Responsive design** adapts to screen size

#### Categories
- **Group services** into logical categories
- Create sections: Media, Productivity, System, etc.
- Collapsible categories
- Custom category icons

#### Background
- **Settings** → **Appearance** → **Background**
- Solid colors
- Gradients
- Custom images
- Unsplash integration

### Multiple Dashboards

Create different dashboards for different purposes:

1. **Media Dashboard**
   - Jellyfin, Jellyseerr, *arr apps
   - Download stats
   - Upcoming releases

2. **Home Automation Dashboard**
   - Home Assistant
   - Smart home controls
   - Sensor data

3. **System Monitoring Dashboard**
   - Docker containers
   - System resources
   - Logs and metrics

**Switch between dashboards** using the dashboard selector in the header.

### User Management & Permissions

Perfect for families and shared servers:

1. **Create Users**
   - Settings → Users → Add User
   - Set username and password
   - Assign permission level

2. **Permission Levels:**
   - **View-only** - Can view dashboard, no editing
   - **Editor** - Can customize their own dashboard
   - **Manager** - Can manage integrations and settings
   - **Admin** - Full access to everything

3. **Personal Dashboards**
   - Each user gets their own dashboard
   - Customizations are per-user
   - Share dashboards between users (optional)

### SSO Integration (Advanced)

Homarr v1+ supports enterprise-grade authentication:

#### OIDC (OpenID Connect)

1. **Settings** → **Authentication** → **OIDC**
2. Configure provider (e.g., Authentik):
   - **Issuer URL:** `https://authentik.home.yourdomain.com`
   - **Client ID:** (from Authentik)
   - **Client Secret:** (from Authentik)
3. **Test** connection
4. **Save**

Users can now sign in with Authentik credentials!

#### LDAP

1. **Settings** → **Authentication** → **LDAP**
2. Configure LDAP server:
   - **Server URL:** `ldap://localhost:389`
   - **Bind DN:** (from Authentik LDAP provider)
   - **Search base:** (user search base)
3. **Test** and **Save**

💡 **Tip:** If you're using Authentik for other services, integrate Homarr for unified authentication across your entire homeserver!

### Real-time Updates (v1+ Feature)

Homarr v1+ uses WebSockets for instant updates:

- ✅ Download progress updates automatically
- ✅ Queue changes reflect instantly
- ✅ Container status updates in real-time
- ✅ No page refresh needed
- ✅ Smooth, responsive experience

**Technical note:** WebSocket connection is established automatically. Check browser console if updates aren't working.

### Mobile Experience

Homarr v1+ is fully responsive:

- **Touch-optimized** interface
- **Swipe gestures** for navigation
- **Mobile-friendly** widgets
- **PWA support** - Add to home screen
- **Fast performance** on mobile devices

### Comparison: Homarr vs Homepage

Both dashboards are available on this server. Choose based on your needs:

| Feature | Homarr v1+ | Homepage |
|---------|-----------|----------|
| **Setup** | Web UI configuration | File-based (YAML) |
| **Integrations** | 30+ with live data | Basic service links |
| **Authentication** | Built-in users & SSO | None (relies on proxy) |
| **Customization** | Drag-and-drop, themes | Edit YAML files |
| **Search** | Built-in across services | None |
| **Real-time updates** | Yes (WebSockets) | No |
| **Best for** | Interactive, feature-rich | Simple, minimal |

**Recommendation:** Use **Homarr** for a powerful, interactive dashboard. Use **Homepage** if you prefer simplicity and file-based configuration.

### Troubleshooting

#### Integrations Not Working

1. **Check service is running:** `systemctl status servicename`
2. **Verify API key** is correct (copy from service settings)
3. **Use localhost URLs** not external URLs (`http://localhost:PORT`)
4. **Check logs:** Browser console for errors
5. **Test connection** using the Test button

#### Docker Integration Issues

1. **Verify socket mount:** Check `/var/run/docker.sock` is mounted
2. **Check permissions:** Homarr container needs read access
3. **Restart container:** `docker restart homarr`

#### Real-time Updates Not Working

1. **Check WebSocket connection** in browser console
2. **Verify no proxy issues** blocking WebSocket
3. **Clear browser cache** and reload
4. **Check Homarr logs:** `docker logs homarr`

#### Authentication Problems

1. **Reset admin password** via container environment variables
2. **Check SSO configuration** matches provider settings
3. **Verify callback URLs** are correct
4. **Test provider** connection separately

### Advanced Configuration

For advanced users who want to customize further:

**Environment Variables:**
- Edit `/etc/nixos/modules/homarr.nix`
- Add custom environment variables
- Rebuild: `sudo nixos-rebuild switch --flake .#homeserver`

**Data Location:**
- Configs: `/mnt/shared/homarr/configs`
- Icons: `/mnt/shared/homarr/icons`
- Data: `/mnt/shared/homarr/data`
- Backed up automatically via Restic

**Docker Socket Access:**
- Homarr has read-only access to Docker socket
- Enables container monitoring and management
- Security: Socket is mounted as read-only (`:ro`)

### Getting Help

- **Official Docs:** [Homarr Documentation](https://homarr.dev/docs)
- **GitHub:** [homarr-labs/homarr](https://github.com/homarr-labs/homarr)
- **Discord:** Join the Homarr community
- **Issues:** Report bugs on GitHub

**Tip:** Homarr v1+ is actively developed with regular updates. Check the GitHub releases for new features!

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

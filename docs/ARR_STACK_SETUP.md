# Arr Stack Setup Guide

A comprehensive guide to configuring your complete media automation workflow from scratch.

## Table of Contents

1. [Introduction](#introduction)
2. [Architecture Overview](#architecture-overview)
3. [Initial Setup Order](#initial-setup-order)
4. [Step-by-Step Configuration](#step-by-step-configuration)
5. [Complete Workflow Test](#complete-workflow-test)
6. [Optimisation & Best Practices](#optimisation--best-practices)
7. [Troubleshooting](#troubleshooting)
8. [Next Steps](#next-steps)

---

## Introduction

### What is the Arr Stack?

The "arr stack" is a collection of applications that work together to automate your media library management. Instead of manually searching for, downloading, and organising media files, these services handle everything automatically.

**Core Services:**
- 🎬 **Sonarr** - TV show management
- 🎥 **Radarr** - Movie management
- 🔍 **Prowlarr** - Indexer management (finds content)
- 📥 **qBittorrent** - Download client
- 📺 **Jellyfin** - Media server (watch your content)
- 🎫 **Jellyseerr** - Request management (user-friendly interface)

**Optional Services:**
- 📚 **Readarr** - Ebook and audiobook management
- 🎵 **Lidarr** - Music library management
- 💬 **Bazarr** - Subtitle downloads
- 📊 **Homarr** - Dashboard for monitoring

### What You'll Accomplish

By following this guide, you'll set up a complete media automation workflow where:

1. You (or family/friends) request content via Jellyseerr
2. Sonarr/Radarr automatically search for the content
3. qBittorrent downloads it
4. Files are automatically organised and renamed
5. Jellyfin detects and displays the new content
6. Everyone can watch immediately

**Estimated setup time:** 2-3 hours for core services, 4-5 hours including optional services.

### Prerequisites

✅ **Before you begin, ensure:**
- NixOS configuration is deployed (services are running)
- You can access services via `https://servicename.home.yourdomain.com`
- You have basic understanding of web interfaces
- You're comfortable following step-by-step instructions

⚠️ **This guide assumes:**
- Services are already installed and running via NixOS
- You're starting with fresh, unconfigured services
- You have access to the web interfaces
- All required directories are automatically created (managed by `modules/disk-mounts.nix`)

---

## Architecture Overview

### How the Services Work Together

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Interface                           │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                      Jellyseerr                           │  │
│  │         (Request movies/TV shows via web UI)             │  │
│  └────────────────────┬─────────────────────────────────────┘  │
└────────────────────────┼────────────────────────────────────────┘
                         │
         ┌───────────────┴────────────────┐
         │                                │
         ▼                                ▼
┌─────────────────┐              ┌─────────────────┐
│     Sonarr      │              │     Radarr      │
│   (TV Shows)    │              │    (Movies)     │
└────────┬────────┘              └────────┬────────┘
         │                                │
         │         ┌──────────────────────┘
         │         │
         ▼         ▼
    ┌─────────────────┐
    │    Prowlarr     │
    │   (Indexers)    │
    └────────┬────────┘
             │
             │ (Searches for torrents)
             │
             ▼
    ┌─────────────────┐
    │  qBittorrent    │
    │   (Downloads)   │
    └────────┬────────┘
             │
             │ (Saves to media folders)
             │
             ▼
    ┌─────────────────┐
    │    Jellyfin     │
    │  (Media Server) │
    └─────────────────┘
             │
             ▼
    ┌─────────────────┐
    │   Your TV/App   │
    │  (Watch Media)  │
    └─────────────────┘
```

### Service Responsibilities

| Service | Purpose | Port | Data Location | Priority |
|---------|---------|------|---------------|----------|
| **qBittorrent** | Downloads torrent files | 8282 | `/mnt/shared/qbittorrent` | 🔴 Critical |
| **Prowlarr** | Manages indexers, searches for content | 9696 | `/var/lib/prowlarr` | 🔴 Critical |
| **Sonarr** | Manages TV shows, triggers downloads | 8989 | `/mnt/shared/sonarr` | 🔴 Critical |
| **Radarr** | Manages movies, triggers downloads | 7878 | `/mnt/shared/radarr` | 🔴 Critical |
| **Jellyfin** | Streams media to your devices | 8096 | `/var/lib/jellyfin` | 🔴 Critical |
| **Jellyseerr** | User-friendly request interface | 5055 | `/mnt/shared/jellyseerr` | 🟡 Important |
| **Bazarr** | Downloads subtitles automatically | 6767 | `/var/lib/bazarr` | 🟢 Optional |
| **Readarr** | Manages ebooks and audiobooks | 8787 | `/mnt/shared/readarr` | 🟢 Optional |
| **Lidarr** | Manages music library | 8686 | `/mnt/shared/lidarr` | 🟢 Optional |
| **Homarr** | Dashboard for monitoring services | 7575 | `/mnt/shared/homarr` | 🟢 Optional |

**Storage Management:** 
- Most service configuration directories are automatically created on `/mnt/shared` during system boot via `modules/disk-mounts.nix`
- **Note:** Bazarr and Prowlarr use default NixOS paths (`/var/lib/*`) as they don't support custom data directories in NixOS 25.05
- Media files are stored on `/mnt/media` (separate from configuration data)

### Data Flow Example

**When you request a movie:**

1. **Jellyseerr** → Sends request to Radarr
2. **Radarr** → Asks Prowlarr to search indexers
3. **Prowlarr** → Returns torrent results to Radarr
4. **Radarr** → Sends best torrent to qBittorrent
5. **qBittorrent** → Downloads to `/mnt/media/downloads`
6. **Radarr** → Monitors download, renames and moves to `/mnt/media/jellyfin/movies`
7. **Jellyfin** → Detects new file, adds to library
8. **You** → Watch the movie! 🎉

---

## Initial Setup Order

⚠️ **Important:** Follow this order! Each service builds on the previous ones.

### Recommended Configuration Order

1. **qBittorrent** (15 mins) - Download client must be configured first
2. **Prowlarr** (20 mins) - Indexers needed before *arr apps can search
3. **Sonarr** (20 mins) - TV show management
4. **Radarr** (20 mins) - Movie management
5. **Jellyfin** (30 mins) - Media server setup
6. **Jellyseerr** (15 mins) - Request interface (connects everything)
7. **Bazarr** (15 mins) - Optional: Subtitles
8. **Readarr** (15 mins) - Optional: Books
9. **Lidarr** (15 mins) - Optional: Music
10. **Homarr** (10 mins) - Optional: Dashboard

### Why This Order Matters

- **qBittorrent first** - Everything else needs a download client
- **Prowlarr second** - Sonarr/Radarr need indexers to search
- **Sonarr/Radarr third** - Must be configured before Jellyseerr
- **Jellyfin before Jellyseerr** - Jellyseerr connects to Jellyfin
- **Jellyseerr last** - Connects to all other services

💡 **Tip:** You can skip optional services and add them later. The core workflow (qBittorrent → Prowlarr → Sonarr/Radarr → Jellyfin → Jellyseerr) is what matters most.

---

## Step-by-Step Configuration

### 4.1 qBittorrent Setup

**Time required:** 15 minutes  
**URL:** `https://qbittorrent.home.yourdomain.com`

#### First Login

1. Open qBittorrent web interface
2. Login with default credentials:
   - **Username:** `admin`
   - **Password:** `adminadmin`

#### 🚨 CRITICAL SECURITY STEP: Change Default Password

**⚠️ DO THIS IMMEDIATELY! The default password is publicly known.**

1. Click **Tools** → **Options**
2. Select **Web UI** tab
3. Under **Authentication**:
   - Change password to something strong
   - Use a password manager to generate and store it
4. Click **Save** at the bottom

💡 **Important:** Write this password down! You'll need it when configuring Sonarr, Radarr, etc.

#### Configure Download Settings

1. **Tools** → **Options** → **Downloads** tab

2. **Default Save Path:**
   - Set to: `/mnt/media/downloads`
   - This is where downloads initially go

3. **Keep incomplete torrents in:**
   - Enable this option
   - Set to: `/mnt/media/downloads/.incomplete`
   - Prevents partial files from being processed

4. **Torrent Management:**
   - ✅ Enable "Create subfolder for torrents with multiple files"
   - ✅ Enable "Keep incomplete torrents in"
   - ✅ Enable "Append .!qB extension to incomplete files"

5. Click **Save**

#### Create Categories

Categories tell qBittorrent where to save completed downloads for each service.

**Right-click in the Categories pane (left sidebar) → Add category:**

| Category Name | Save Path | Used By |
|---------------|-----------|---------|
| `tv-sonarr` | `/mnt/media/jellyfin/tv` | Sonarr |
| `movies-radarr` | `/mnt/media/jellyfin/movies` | Radarr |
| `books-readarr` | `/mnt/media/books` | Readarr |
| `music-lidarr` | `/mnt/media/jellyfin/music` | Lidarr |

**For each category:**
1. Right-click in Categories → **Add category**
2. Enter category name (e.g., `tv-sonarr`)
3. Set save path (e.g., `/mnt/media/jellyfin/tv`)
4. Click **Add**

#### Performance Tuning (Optional)

For better performance, adjust these settings:

1. **Tools** → **Options** → **BitTorrent** tab:
   - **Max active downloads:** 3-5
   - **Max active uploads:** 5-10
   - **Max active torrents:** 10

2. **Connection** tab:
   - **Global maximum connections:** 500
   - **Maximum connections per torrent:** 100

3. Click **Save**

#### Verify Setup

✅ **Checklist:**
- [ ] Default password changed
- [ ] Download path set to `/mnt/media/downloads`
- [ ] Incomplete path set to `/mnt/media/downloads/.incomplete`
- [ ] Categories created: tv-sonarr, movies-radarr, books-readarr, music-lidarr
- [ ] You've saved the new password somewhere safe

🎉 **qBittorrent is ready!** You can now configure Prowlarr.

---

### 4.2 Prowlarr Setup

**Time required:** 20 minutes  
**URL:** `https://prowlarr.home.yourdomain.com`

Prowlarr manages indexers (sites that list torrents) and connects them to all your *arr apps.

**Note:** Prowlarr configuration is stored in `/var/lib/prowlarr` (NixOS default location). This is managed automatically by the system.

#### Initial Configuration

1. Open Prowlarr web interface
2. You'll see the welcome screen
3. Click through the initial setup wizard

#### Add Indexers

Indexers are where Prowlarr searches for content. You'll need at least one.

**To add an indexer:**

1. Click **Indexers** in the left menu
2. Click **Add Indexer** (big + button)
3. Search for an indexer (e.g., "1337x", "RARBG", "The Pirate Bay")
4. Click on the indexer name
5. Configure settings (most work with defaults)
6. Click **Test** to verify it works
7. Click **Save**

**Recommended public indexers to start with:**
- 1337x
- EZTV (TV shows)
- YTS (movies)

💡 **Tip:** Start with 2-3 public indexers. You can add more later, including private trackers if you have accounts.

#### Configure Indexer Priorities

1. **Indexers** → Select an indexer
2. Set **Priority:**
   - Higher number = higher priority
   - Private trackers: 50
   - Good public indexers: 25
   - Backup indexers: 10

#### Test Indexer Connections

1. Go to **Indexers**
2. Click **Test All** button
3. Verify all indexers show green checkmarks
4. Fix any that show errors

#### Get Prowlarr API Key

You'll need this for connecting *arr apps:

1. **Settings** → **General**
2. Under **Security**, find **API Key**
3. Copy this key (you'll need it soon)

✅ **Checklist:**
- [ ] At least 2 indexers added and tested
- [ ] Indexer priorities configured
- [ ] API key copied and saved

🎉 **Prowlarr is ready!** Now we'll connect it to Sonarr and Radarr.

---

### 4.3 Sonarr Setup

**Time required:** 20 minutes  
**URL:** `https://sonarr.home.yourdomain.com`

Sonarr manages your TV show library automatically.

#### Initial Configuration Wizard

1. Open Sonarr web interface
2. Complete the initial setup wizard:
   - **Authentication:** Set up later (optional)
   - **Media Management:** Use defaults for now
   - Click **Finish**

#### Add Root Folder

Root folders tell Sonarr where to store TV shows.

1. **Settings** → **Media Management**
2. Scroll to **Root Folders**
3. Click **Add Root Folder**
4. Enter: `/mnt/media/jellyfin/tv`
5. Click **OK**

#### Configure Quality Profiles

Quality profiles determine what quality downloads Sonarr accepts.

1. **Settings** → **Profiles**
2. Edit the **HD-1080p** profile (or create a new one):
   - Enable qualities you want (e.g., WEBDL-1080p, Bluray-1080p)
   - Drag to reorder (top = preferred)
3. Click **Save**

💡 **Tip:** Start with 1080p. You can add 4K later if you want.

#### Add qBittorrent as Download Client

1. **Settings** → **Download Clients**
2. Click **+** to add a new client
3. Select **qBittorrent**
4. Configure:
   - **Name:** qBittorrent
   - **Enable:** ✅ Yes
   - **Host:** `localhost`
   - **Port:** `8282`
   - **Username:** `admin`
   - **Password:** (your qBittorrent password)
   - **Category:** `tv-sonarr`
5. Click **Test** - should show green checkmark
6. Click **Save**

#### Connect to Prowlarr

1. **Settings** → **Indexers**
2. Click **Add Indexer**
3. Scroll down and select **Prowlarr**
4. Configure:
   - **Name:** Prowlarr
   - **Sync Level:** Full Sync
   - **Prowlarr Server:** `http://localhost:9696`
   - **API Key:** (paste Prowlarr API key from earlier)
5. Click **Test** - should succeed
6. Click **Save**
7. Wait 30 seconds, then refresh the page
8. You should now see all your Prowlarr indexers listed!

#### Configure Media Management

1. **Settings** → **Media Management**
2. Enable these options:
   - ✅ **Rename Episodes**
   - ✅ **Replace Illegal Characters**
   - ✅ **Use Season Folders**
3. **Episode Naming:**
   - Standard Episode Format: `{Series Title} - S{season:00}E{episode:00} - {Episode Title} {Quality Full}`
   - Daily Episode Format: `{Series Title} - {Air-Date} - {Episode Title} {Quality Full}`
   - Anime Episode Format: `{Series Title} - S{season:00}E{episode:00} - {Episode Title} {Quality Full}`
4. Click **Save Changes**

#### Add Your First TV Show

Let's test the setup!

1. Click **Series** in the left menu
2. Click **Add New**
3. Search for a TV show (e.g., "Breaking Bad")
4. Click on the show
5. Configure:
   - **Root Folder:** `/mnt/media/jellyfin/tv`
   - **Monitor:** All Episodes
   - **Quality Profile:** HD-1080p
   - **Series Type:** Standard
   - ✅ **Start search for missing episodes**
6. Click **Add Series**

Sonarr will now:
1. Search Prowlarr for the episodes
2. Send torrents to qBittorrent
3. Monitor the downloads
4. Rename and organise files when complete

#### Verify the Workflow

1. Go to **Activity** → **Queue** to see active downloads
2. Open qBittorrent to see torrents downloading
3. Wait for an episode to complete
4. Check `/mnt/media/jellyfin/tv` - you should see the organised files!

✅ **Checklist:**
- [ ] Root folder added: `/mnt/media/jellyfin/tv`
- [ ] qBittorrent connected and tested
- [ ] Prowlarr connected and indexers synced
- [ ] Media management configured
- [ ] Test TV show added and downloading

🎉 **Sonarr is working!** Let's set up Radarr next.

---

### 4.4 Radarr Setup

**Time required:** 20 minutes  
**URL:** `https://radarr.home.yourdomain.com`

Radarr manages your movie library. Setup is very similar to Sonarr.

#### Initial Configuration Wizard

1. Open Radarr web interface
2. Complete the initial setup wizard (similar to Sonarr)

#### Add Root Folder

1. **Settings** → **Media Management**
2. Scroll to **Root Folders**
3. Click **Add Root Folder**
4. Enter: `/mnt/media/jellyfin/movies`
5. Click **OK**

#### Configure Quality Profiles

1. **Settings** → **Profiles**
2. Edit the **HD-1080p** profile:
   - Enable qualities you want
   - Reorder by preference
3. Click **Save**

#### Add qBittorrent as Download Client

1. **Settings** → **Download Clients**
2. Click **+** to add a new client
3. Select **qBittorrent**
4. Configure:
   - **Name:** qBittorrent
   - **Enable:** ✅ Yes
   - **Host:** `localhost`
   - **Port:** `8282`
   - **Username:** `admin`
   - **Password:** (your qBittorrent password)
   - **Category:** `movies-radarr` ⚠️ Different from Sonarr!
5. Click **Test**
6. Click **Save**

#### Connect to Prowlarr

1. **Settings** → **Indexers**
2. Click **Add Indexer**
3. Select **Prowlarr**
4. Configure:
   - **Name:** Prowlarr
   - **Sync Level:** Full Sync
   - **Prowlarr Server:** `http://localhost:9696`
   - **API Key:** (Prowlarr API key)
5. Click **Test**
6. Click **Save**
7. Refresh page - indexers should appear

#### Configure Media Management

1. **Settings** → **Media Management**
2. Enable:
   - ✅ **Rename Movies**
   - ✅ **Replace Illegal Characters**
3. **Movie Naming:**
   - Standard Movie Format: `{Movie Title} ({Release Year}) {Quality Full}`
4. Click **Save Changes**

#### Add Your First Movie

1. Click **Movies** in the left menu
2. Click **Add New**
3. Search for a movie (e.g., "The Matrix")
4. Click on the movie
5. Configure:
   - **Root Folder:** `/mnt/media/jellyfin/movies`
   - **Monitor:** Yes
   - **Quality Profile:** HD-1080p
   - ✅ **Start search for missing movie**
6. Click **Add Movie**

#### Verify the Workflow

1. **Activity** → **Queue** - see the download
2. Check qBittorrent - torrent should be downloading
3. Wait for completion
4. Check `/mnt/media/jellyfin/movies` - organised file should appear!

✅ **Checklist:**
- [ ] Root folder added: `/mnt/media/jellyfin/movies`
- [ ] qBittorrent connected with `movies-radarr` category
- [ ] Prowlarr connected and indexers synced
- [ ] Media management configured
- [ ] Test movie added and downloading

🎉 **Radarr is working!** The core automation is now complete.

---

### 4.5 Readarr Setup (Optional)

**Time required:** 15 minutes  
**URL:** `https://readarr.home.yourdomain.com`

Readarr manages ebooks and audiobooks. Setup is similar to Sonarr/Radarr.

#### Initial Configuration

1. Open Readarr web interface
2. Complete initial setup wizard

#### Add Root Folder

1. **Settings** → **Media Management**
2. **Root Folders** → **Add Root Folder**
3. Enter: `/mnt/media/books`
4. Click **OK**

#### Add qBittorrent

1. **Settings** → **Download Clients**
2. Click **+** → **qBittorrent**
3. Configure:
   - **Host:** `localhost`
   - **Port:** `8282`
   - **Username:** `admin`
   - **Password:** (your qBittorrent password)
   - **Category:** `books-readarr`
4. **Test** and **Save**

#### Connect to Prowlarr

1. **Settings** → **Indexers**
2. **Add Indexer** → **Prowlarr**
3. Configure:
   - **Prowlarr Server:** `http://localhost:9696`
   - **API Key:** (Prowlarr API key)
4. **Test** and **Save**

#### Add Your First Book

1. **Library** → **Add New**
2. Search for an author or book
3. Select root folder: `/mnt/media/books`
4. Click **Add**

✅ **Readarr is configured!**

---

### 4.6 Lidarr Setup (Optional)

**Time required:** 15 minutes  
**URL:** `https://lidarr.home.yourdomain.com`

Lidarr manages your music library.

#### Initial Configuration

1. Open Lidarr web interface
2. Complete initial setup wizard

#### Add Root Folder

1. **Settings** → **Media Management**
2. **Root Folders** → **Add Root Folder**
3. Enter: `/mnt/media/jellyfin/music`
4. Click **OK**

#### Add qBittorrent

1. **Settings** → **Download Clients**
2. Click **+** → **qBittorrent**
3. Configure:
   - **Host:** `localhost`
   - **Port:** `8282`
   - **Username:** `admin`
   - **Password:** (your qBittorrent password)
   - **Category:** `music-lidarr`
4. **Test** and **Save**

#### Connect to Prowlarr

1. **Settings** → **Indexers**
2. **Add Indexer** → **Prowlarr**
3. Configure:
   - **Prowlarr Server:** `http://localhost:9696`
   - **API Key:** (Prowlarr API key)
4. **Test** and **Save**

#### Add Your First Artist

1. **Library** → **Add New**
2. Search for an artist
3. Select root folder: `/mnt/media/jellyfin/music`
4. Choose what to monitor (all albums, future albums, etc.)
5. Click **Add**

✅ **Lidarr is configured!**

---

### 4.7 Bazarr Setup (Optional)

**Time required:** 15 minutes  
**URL:** `https://bazarr.home.yourdomain.com`

Bazarr automatically downloads subtitles for your media.

**Note:** Bazarr configuration is stored in `/var/lib/bazarr` (NixOS default location). This is managed automatically by the system.

#### Initial Configuration

1. Open Bazarr web interface
2. Complete the setup wizard

#### Connect to Sonarr

1. **Settings** → **Sonarr**
2. Click **Add**
3. Configure:
   - **Name:** Sonarr
   - **Hostname:** `localhost`
   - **Port:** `8989`
   - **API Key:** (get from Sonarr → Settings → General)
   - **Base URL:** Leave empty
4. **Test** and **Save**

#### Connect to Radarr

1. **Settings** → **Radarr**
2. Click **Add**
3. Configure:
   - **Name:** Radarr
   - **Hostname:** `localhost`
   - **Port:** `7878`
   - **API Key:** (get from Radarr → Settings → General)
   - **Base URL:** Leave empty
4. **Test** and **Save**

#### Configure Subtitle Providers

1. **Settings** → **Providers**
2. Enable providers (e.g., OpenSubtitles, Subscene)
3. Some require registration - create free accounts
4. Enter credentials for each provider
5. **Save**

#### Configure Languages

1. **Settings** → **Languages**
2. **Languages Filter:** Add languages you want (e.g., English)
3. **Default Settings:**
   - Enable **Series** and **Movies**
   - Set languages
4. **Save**

#### Enable Automatic Downloads

1. **Settings** → **Sonarr** → Edit your Sonarr connection
2. Enable **Download Subtitles**
3. **Save**
4. Repeat for Radarr

✅ **Bazarr is configured!** Subtitles will download automatically.

---

### 4.8 Jellyfin Setup

**Time required:** 30 minutes  
**URL:** `https://jellyfin.home.yourdomain.com`

Jellyfin is your media server - where you actually watch content.

#### Initial Setup Wizard

1. Open Jellyfin web interface
2. **Welcome screen** → Click **Next**
3. **Language:** Select your preferred language → **Next**

#### Create Admin Account

1. **Username:** Choose an admin username
2. **Password:** Set a strong password
3. Click **Next**

#### Add Media Libraries

Now we'll tell Jellyfin where your media is located.

**Add Movies Library:**

1. Click **Add Media Library**
2. **Content type:** Movies
3. **Display name:** Movies
4. Click **+** next to **Folders**
5. Enter: `/mnt/media/jellyfin/movies`
6. Click **OK**
7. **Library settings:**
   - **Language:** English (or your preference)
   - **Country:** Your country
   - Enable **Automatically refresh metadata from the internet**
8. Click **OK**

**Add TV Shows Library:**

1. Click **Add Media Library**
2. **Content type:** Shows
3. **Display name:** TV Shows
4. Click **+** next to **Folders**
5. Enter: `/mnt/media/jellyfin/tv`
6. Click **OK**
7. Configure language and country
8. Click **OK**

**Add Music Library (if using Lidarr):**

1. Click **Add Media Library**
2. **Content type:** Music
3. **Display name:** Music
4. Click **+** next to **Folders**
5. Enter: `/mnt/media/jellyfin/music`
6. Click **OK**
7. Click **OK**

**Add Books Library (if using Readarr):**

1. Click **Add Media Library**
2. **Content type:** Books
3. **Display name:** Books
4. Click **+** next to **Folders**
5. Enter: `/mnt/media/books`
6. Click **OK**
7. Click **OK**

#### Configure Remote Access

1. **Remote Access:** Leave default settings
2. Click **Next**

#### Finish Setup

1. Review settings
2. Click **Finish**
3. Login with your admin account

#### Configure Library Scanning

1. **Dashboard** → **Libraries**
2. For each library, click the **⋮** menu → **Scan Library**
3. Wait for initial scan to complete

#### Create User Accounts

1. **Dashboard** → **Users**
2. Click **+** to add a new user
3. **Name:** User's name
4. **Password:** Set a password (or leave empty for no password)
5. **Library Access:** Choose which libraries they can access
6. **Enable media playback:** ✅ Yes
7. Click **Save**

#### Test Media Playback

1. Go to **Home**
2. Navigate to **Movies** or **TV Shows**
3. Click on a media item
4. Click **Play**
5. Verify playback works

✅ **Checklist:**
- [ ] Admin account created
- [ ] Media libraries added (Movies, TV Shows, Music, Books)
- [ ] Libraries scanned successfully
- [ ] User accounts created
- [ ] Test playback successful

🎉 **Jellyfin is ready!** Your media server is now operational.

---

### 4.9 Jellyseerr Setup

**Time required:** 15 minutes  
**URL:** `https://jellyseerr.home.yourdomain.com`

Jellyseerr provides a beautiful interface for requesting media. This is what you and your family/friends will use.

#### Initial Setup Wizard

1. Open Jellyseerr web interface
2. **Welcome screen** → Click **Get Started**

#### Sign In with Jellyfin

1. **Jellyfin URL:** Enter `http://localhost:8096`
2. Click **Save Changes**
3. **Sign in with Jellyfin**
4. Enter your Jellyfin admin credentials
5. Click **Sign In**

#### Configure Jellyfin

1. **Server Name:** Should auto-detect
2. **Libraries:** Select libraries to sync (Movies, TV Shows)
3. Click **Continue**

#### Connect to Radarr

1. **Default Server:**
   - **Server Name:** Radarr
   - **Hostname or IP:** `localhost`
   - **Port:** `7878`
   - **API Key:** (get from Radarr → Settings → General)
   - **Use SSL:** ❌ No
   - **Base URL:** Leave empty
2. **Quality Profile:** HD-1080p (or your preference)
3. **Root Folder:** `/mnt/media/jellyfin/movies`
4. **Minimum Availability:** Released
5. Click **Test** - should succeed
6. Enable **Default Server**
7. Click **Add Server**

#### Connect to Sonarr

1. Click **Add Sonarr Server**
2. **Default Server:**
   - **Server Name:** Sonarr
   - **Hostname or IP:** `localhost`
   - **Port:** `8989`
   - **API Key:** (get from Sonarr → Settings → General)
   - **Use SSL:** ❌ No
   - **Base URL:** Leave empty
3. **Quality Profile:** HD-1080p
4. **Root Folder:** `/mnt/media/jellyfin/tv`
5. **Language Profile:** English (or your preference)
6. Click **Test**
7. Enable **Default Server**
8. Enable **Season Folders**
9. Click **Add Server**
10. Click **Continue**

#### Configure User Permissions

1. **Admin Account:** This is you - full permissions
2. Click **Continue**

#### Finish Setup

1. Review settings
2. Click **Finish Setup**
3. You'll be taken to the Jellyseerr home page

#### Configure Request Limits (Optional)

1. Click your profile icon → **Settings**
2. **Users** → Select a user
3. **Request Limits:**
   - **Movie Requests:** 10 per week (adjust as needed)
   - **TV Requests:** 5 per week
4. Click **Save**

#### Configure Notifications (Optional)

1. **Settings** → **Notifications**
2. Enable notification methods (Email, Discord, etc.)
3. Configure each method
4. **Test** and **Save**

#### Test the Request Workflow

Let's make sure everything works end-to-end!

1. Go to Jellyseerr home page
2. Search for a movie or TV show
3. Click **Request**
4. Confirm the request
5. **Verify the workflow:**
   - Check Radarr/Sonarr - request should appear
   - Check qBittorrent - download should start
   - Wait for completion
   - Check Jellyfin - media should appear

✅ **Checklist:**
- [ ] Jellyfin connected and authenticated
- [ ] Radarr connected and tested
- [ ] Sonarr connected and tested
- [ ] User permissions configured
- [ ] Test request successful

🎉 **Jellyseerr is working!** Your media automation is now complete.

---

### 4.10 Homarr Setup (Optional)

**Time required:** 10 minutes  
**URL:** `https://homarr.home.yourdomain.com`

Homarr provides a beautiful dashboard to monitor all your services.

**Note:** This server uses Homarr v1+ from the homarr-labs organization, which includes many improvements over the legacy version including better authentication, more integrations, and enhanced customization options.

#### Initial Setup

1. Open Homarr web interface
2. You'll see a default dashboard or setup wizard

#### Customise Dashboard

1. Click the **Edit** button (pencil icon)
2. **Add tiles** for your services:
   - Jellyfin
   - Jellyseerr
   - Sonarr
   - Radarr
   - Prowlarr
   - qBittorrent
3. Drag tiles to arrange them
4. Click **Save**

#### Add Service Integrations

For live stats and monitoring:

1. **Edit mode** → Click on a service tile
2. **Integration settings:**
   - **URL:** `http://localhost:PORT`
   - **API Key:** (from service settings)
3. **Save**

Repeat for each service.

#### Add Widgets

1. **Edit mode** → **Add Widget**
2. Choose widgets:
   - **Calendar** - Upcoming releases
   - **Media Requests** - Jellyseerr stats
   - **Download Speed** - qBittorrent stats
   - **System Resources** - CPU, RAM, disk usage
3. Configure and save

✅ **Homarr is configured!** You now have a beautiful dashboard.

---

## Complete Workflow Test

Let's verify everything works together perfectly.

### End-to-End Test

**Test Movie Request:**

1. Open Jellyseerr
2. Search for a movie you don't have
3. Click **Request**
4. **Verify each step:**
   - ✅ Jellyseerr shows "Requested"
   - ✅ Radarr shows the movie as "Wanted"
   - ✅ Radarr searches Prowlarr
   - ✅ qBittorrent starts downloading
   - ✅ Download completes
   - ✅ Radarr renames and moves file to `/mnt/media/jellyfin/movies`
   - ✅ Jellyfin detects and adds the movie
   - ✅ You can watch it in Jellyfin

**Test TV Show Request:**

1. Open Jellyseerr
2. Search for a TV show
3. Request a specific season
4. **Verify each step:**
   - ✅ Jellyseerr shows "Requested"
   - ✅ Sonarr shows episodes as "Wanted"
   - ✅ Episodes download via qBittorrent
   - ✅ Files organised to `/mnt/media/jellyfin/tv/Show Name/Season XX/`
   - ✅ Jellyfin detects episodes
   - ✅ You can watch them

### Verification Checklist

✅ **Services:**
- [ ] qBittorrent is downloading torrents
- [ ] Prowlarr is searching indexers
- [ ] Sonarr is managing TV shows
- [ ] Radarr is managing movies
- [ ] Jellyfin is playing media
- [ ] Jellyseerr is accepting requests

✅ **Automation:**
- [ ] Requests automatically trigger searches
- [ ] Downloads start automatically
- [ ] Files are renamed and organised automatically
- [ ] Jellyfin detects new media automatically

✅ **File Organisation:**
- [ ] Movies in `/mnt/media/jellyfin/movies/Movie Name (Year)/`
- [ ] TV shows in `/mnt/media/jellyfin/tv/Show Name/Season XX/`
- [ ] Files properly named
- [ ] Permissions correct (media:media)

### What Success Looks Like

When everything is working correctly:

1. **Request** a movie/show in Jellyseerr
2. **Wait** 5-60 minutes (depending on download speed)
3. **Watch** it in Jellyfin - no manual intervention needed!

🎉 **Congratulations!** Your media automation stack is fully operational.

---

## Optimisation & Best Practices

### Quality Profiles (TRaSH Guides)

The [TRaSH Guides](https://trash-guides.info/) provide optimised quality profiles.

**For Sonarr:**
1. Visit https://trash-guides.info/Sonarr/
2. Follow the quality profile recommendations
3. Import custom formats for better releases

**For Radarr:**
1. Visit https://trash-guides.info/Radarr/
2. Import quality profiles
3. Configure custom formats

💡 **Tip:** TRaSH guides help you get the best quality releases automatically.

### Naming Conventions

Proper naming ensures Jellyfin correctly identifies media.

**Movies:**
```
Movie Name (Year)/Movie Name (Year) - Quality.ext
Example: The Matrix (1999)/The Matrix (1999) - Bluray-1080p.mkv
```

**TV Shows:**
```
Show Name/Season XX/Show Name - SXXEXX - Episode Title - Quality.ext
Example: Breaking Bad/Season 01/Breaking Bad - S01E01 - Pilot - WEBDL-1080p.mkv
```

These are configured in Sonarr/Radarr media management settings.

### Automation Settings

**Sonarr/Radarr:**
- Enable **Automatic Search** for new content
- Enable **RSS Sync** for automatic downloads
- Set **Retention** to delete old releases after upgrade

**Prowlarr:**
- Sync indexers regularly (automatic)
- Monitor indexer health
- Remove dead indexers

**qBittorrent:**
- Enable **Automatic Torrent Management**
- Set **Seeding Limits:**
  - Ratio: 2.0 (or as required by private trackers)
  - Time: 7 days
- Enable **Remove torrent when seeding complete**

### Monitoring and Maintenance

**Weekly Tasks:**
- Check Sonarr/Radarr for failed downloads
- Review Prowlarr indexer health
- Clear qBittorrent completed torrents

**Monthly Tasks:**
- Update quality profiles
- Review disk space usage
- Check for service updates

**Automated:**
- NixOS handles service updates
- Jellyfin scans libraries automatically
- Bazarr downloads subtitles automatically

### Backup Recommendations

**What to backup:**
- ✅ Sonarr/Radarr/Prowlarr databases (`/mnt/shared/*arr/`)
- ✅ qBittorrent configuration
- ✅ Jellyfin database and configuration
- ✅ Jellyseerr database

**What NOT to backup:**
- ❌ Media files (can be re-downloaded)
- ❌ Torrents in progress

Your NixOS configuration already backs up `/mnt/shared` to Azure via Restic.

### Performance Tips

**For better performance:**

1. **Use SSD for databases:**
   - Sonarr/Radarr/Prowlarr data on SSD (`/mnt/shared`)
   - Media files on HDD (`/mnt/media`)

2. **Optimise Jellyfin:**
   - Enable hardware transcoding if you have a GPU
   - Pre-download subtitles with Bazarr
   - Use direct play when possible

3. **qBittorrent:**
   - Limit active torrents (5-10)
   - Use categories for organisation
   - Enable sequential download for streaming

---

## Troubleshooting

### Common Issues During Initial Setup

#### qBittorrent Won't Accept Connections

**Symptom:** *arr apps can't connect to qBittorrent

**Solutions:**
1. Verify qBittorrent is running: `systemctl status qbittorrent`
2. Check you changed the default password
3. Verify credentials are correct
4. Test connection: `curl http://localhost:8282` (should return login page)
5. Check firewall isn't blocking port 8282

#### Prowlarr Indexers Failing

**Symptom:** "Unable to connect to indexer" errors

**Solutions:**
1. Test indexer manually in Prowlarr
2. Check indexer isn't down (visit website)
3. Verify API keys if using private trackers
4. Try different indexers
5. Check internet connectivity

#### Sonarr/Radarr Not Finding Releases

**Symptom:** "No results found" when searching

**Solutions:**
1. Verify Prowlarr connection is working
2. Check indexers are enabled in Prowlarr
3. Test indexers manually
4. Broaden quality profile (accept more qualities)
5. Try searching manually in Prowlarr
6. Check content actually exists on indexers

#### Downloads Going to Wrong Location

**Symptom:** Files downloading to incorrect folders

**Solutions:**
1. Verify qBittorrent categories are set correctly
2. Check category is specified in *arr download client settings
3. Verify folder permissions: `ls -la /mnt/media/`
4. Ensure media user has write access
5. Check paths match exactly (case-sensitive)

**Note:** All required directories are automatically created by `modules/disk-mounts.nix` during system boot. If directories are missing, check the service logs.

#### Jellyfin Not Detecting New Media

**Symptom:** New downloads don't appear in Jellyfin

**Solutions:**
1. Manually scan library: Dashboard → Libraries → Scan
2. Check file permissions: `ls -la /mnt/media/jellyfin/`
3. Verify files are in correct location
4. Check file naming matches Jellyfin expectations
5. Enable debug logging in Jellyfin

#### Jellyseerr Can't Connect to Services

**Symptom:** "Connection failed" when setting up Jellyseerr

**Solutions:**
1. Use `http://localhost:PORT` not `https://service.home...`
2. Verify service is running: `systemctl status servicename`
3. Check API keys are correct
4. Test API manually: `curl http://localhost:PORT/api/v3/system/status`
5. Check firewall rules

### Service Connectivity Problems

**Test internal connectivity:**

```bash
# Test Jellyfin
curl http://localhost:8096

# Test Sonarr
curl http://localhost:8989/api/v3/system/status -H "X-Api-Key: YOUR_API_KEY"

# Test Radarr
curl http://localhost:7878/api/v3/system/status -H "X-Api-Key: YOUR_API_KEY"

# Test Prowlarr
curl http://localhost:9696/api/v1/health -H "X-Api-Key: YOUR_API_KEY"

# Test qBittorrent
curl http://localhost:8282
```

### Permission Issues

**Fix media folder permissions:**

```bash
# Fix ownership
sudo chown -R media:media /mnt/media/jellyfin
sudo chown -R media:media /mnt/media/downloads
sudo chown -R media:media /mnt/media/books

# Fix permissions
sudo chmod -R 755 /mnt/media/jellyfin
sudo chmod -R 755 /mnt/media/downloads
```

**Note:** Directory permissions are managed centrally in `modules/disk-mounts.nix`. For permanent changes, edit that file and run `nixos-rebuild switch`.

### Download Client Problems

**qBittorrent issues:**

```bash
# Check service status
systemctl status qbittorrent

# View logs
journalctl -u qbittorrent -n 50

# Restart service
sudo systemctl restart qbittorrent
```

### Indexer Issues

**Prowlarr indexer troubleshooting:**

1. **Indexer down:** Try alternative indexers
2. **Rate limited:** Wait and try again, or use different indexer
3. **Banned:** Check if your IP is banned, use VPN if needed
4. **API issues:** Verify API keys for private trackers

### Getting Help

If you're stuck:

1. **Check logs:**
   ```bash
   # View service logs
   journalctl -u servicename -n 100
   
   # Follow logs in real-time
   journalctl -u servicename -f
   ```

2. **Review this guide:** Ensure you followed all steps correctly

3. **Check service documentation:**
   - [Sonarr Wiki](https://wiki.servarr.com/sonarr)
   - [Radarr Wiki](https://wiki.servarr.com/radarr)
   - [Prowlarr Wiki](https://wiki.servarr.com/prowlarr)
   - [Jellyfin Docs](https://jellyfin.org/docs/)

4. **Search Reddit:**
   - r/sonarr
   - r/radarr
   - r/jellyfin
   - r/selfhosted

5. **Check project troubleshooting:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## Next Steps

### Advanced Features to Explore

**Quality Management:**
- Import TRaSH guide custom formats
- Set up quality upgrades
- Configure preferred words

**Automation:**
- Set up lists (Trakt, IMDb) for automatic additions
- Configure RSS feeds for new releases
- Enable automatic series/movie additions

**Monitoring:**
- Set up Homarr dashboard
- Configure Grafana for metrics
- Enable notifications (Discord, Telegram, etc.)

**Optimisation:**
- Hardware transcoding in Jellyfin
- Custom scripts for post-processing
- Advanced qBittorrent settings

### Additional Services to Consider

**Already installed:**
- **Audiobookshelf** - Audiobook and podcast server
- **Homepage** - Alternative dashboard
- **Grafana** - Metrics and monitoring

**Could add:**
- **Tautulli** - Jellyfin monitoring and statistics
- **Requestrr** - Discord bot for requests
- **Organizr** - Unified dashboard
- **Ombi** - Alternative to Jellyseerr

### Community Resources

**Learn more:**
- [TRaSH Guides](https://trash-guides.info/) - Quality profiles and guides
- [r/selfhosted](https://reddit.com/r/selfhosted) - Self-hosting community
- [Servarr Wiki](https://wiki.servarr.com/) - Official *arr documentation
- [Jellyfin Docs](https://jellyfin.org/docs/) - Jellyfin documentation

**Get help:**
- [Sonarr Discord](https://discord.gg/M6BvZn5)
- [Radarr Discord](https://discord.gg/AD3UP37)
- [Jellyfin Matrix](https://matrix.to/#/#jellyfin:matrix.org)

### Share Your Success

If you found this guide helpful:
- ⭐ Star the repository
- 📝 Share your experience
- 🐛 Report issues or improvements
- 🤝 Help others in discussions

---

## Success! 🎉

You now have a fully automated media server that:

- ✅ Accepts requests via beautiful web interface
- ✅ Automatically searches for content
- ✅ Downloads and organises media
- ✅ Streams to all your devices
- ✅ Downloads subtitles automatically
- ✅ Manages TV shows, movies, books, and music
- ✅ Requires minimal maintenance

**Enjoy your automated media server!**

---

*Last updated: 2025-11-01*
*Part of the [NixOS Home Server](../README.md) project*

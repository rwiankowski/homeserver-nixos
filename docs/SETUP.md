# Complete Setup Guide

This guide will walk you through deploying your NixOS home server from scratch.

**Estimated time**: 2-3 hours (mostly waiting for downloads)

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Phase 1: Prepare Hardware](#phase-1-prepare-hardware)
3. [Phase 2: Install NixOS](#phase-2-install-nixos)
4. [Phase 3: Configure Secrets](#phase-3-configure-secrets)
5. [Phase 4: Customize Configuration](#phase-4-customize-configuration)
6. [Phase 5: Deploy](#phase-5-deploy)
7. [Phase 6: Configure Services](#phase-6-configure-services)
8. [Phase 7: Final Testing](#phase-7-final-testing)
9. [Next Steps](#next-steps)

## Prerequisites

### Accounts & Services

- [ ] **GitHub account** - For hosting your configuration
- [ ] **Tailscale account** - Free tier at https://tailscale.com
- [ ] **Azure account** - For backups and DNS (free $200 credit)
- [ ] **Domain name** - Optional but recommended for clean URLs
- [ ] **CrowdSec account** - Optional, free at https://app.crowdsec.net

### Hardware/VM

- [ ] **Server or VM** with:
  - Minimum: 4 CPU cores, 8GB RAM
  - Recommended: 6+ cores, 16GB+ RAM (for LLMs)
  - 5 virtual disks (see below)

### Knowledge

- [ ] Basic Linux command line
- [ ] Basic understanding of NixOS (helpful but not required)
- [ ] SSH key generated on your laptop

---

## Phase 1: Prepare Hardware

### 1.1 Create VM in Proxmox (or Prepare Physical Server)

If using Proxmox:

```bash
# Create VM with:
- Name: homeserver
- OS: Linux
- BIOS: UEFI
- CPU: 4+ cores
- RAM: 8192 MB (8GB) minimum, 16384 MB (16GB) recommended
- Network: VirtIO, bridge to your LAN
```

### 1.2 Add Virtual Disks

Create 5 virtual disks (adjust sizes to your needs):

| Disk | Size | Type | Purpose | Label |
|------|------|------|---------|-------|
| vda | 50GB | SSD | Operating system | `nixos` |
| vdb | 500GB+ | HDD | Media (Jellyfin) | `media` |
| vdc | 200GB+ | SSD | Photos (Immich) | `photos` |
| vdd | 100GB+ | SSD | Documents (NextCloud, Paperless) | `docs` |
| vde | 100GB+ | SSD | App data, databases | `shared` |

**Why separate disks?**
- 💰 Cost optimization (HDD for cheap media storage)
- ⚡ Performance (SSD for apps and databases)
- 🎯 Backup efficiency (exclude media from backups)

---

## Phase 2: Install NixOS

### 2.1 Boot from NixOS ISO

1. Download NixOS ISO: https://nixos.org/download.html#nixos-iso
2. Mount ISO in your VM
3. Boot from ISO

### 2.2 Partition and Format Disks

```bash
# Partition root disk (vda)
parted /dev/vda -- mklabel gpt
parted /dev/vda -- mkpart ESP fat32 1MiB 512MiB
parted /dev/vda -- set 1 esp on
parted /dev/vda -- mkpart primary 512MiB 100%

# Format root partitions
mkfs.fat -F 32 -n boot /dev/vda1
mkfs.ext4 -L nixos /dev/vda2

# Format additional disks with LABELS (important for modules/disk-mounts.nix)
mkfs.ext4 -L media /dev/vdb
mkfs.ext4 -L photos /dev/vdc
mkfs.ext4 -L docs /dev/vdd
mkfs.ext4 -L shared /dev/vde
```

### 2.3 Mount Filesystems

```bash
# Mount root
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

# Mount additional disks
mkdir -p /mnt/mnt/{media,photos,docs,shared}
mount /dev/disk/by-label/media /mnt/mnt/media
mount /dev/disk/by-label/photos /mnt/mnt/photos
mount /dev/disk/by-label/docs /mnt/mnt/docs
mount /dev/disk/by-label/shared /mnt/mnt/shared
```

### 2.4 Generate Initial Configuration

```bash
# Generate hardware config
nixos-generate-config --root /mnt

# This creates:
# /mnt/etc/nixos/configuration.nix
# /mnt/etc/nixos/hardware-configuration.nix
```

### 2.5 Install NixOS

```bash
# Install
nixos-install

# Set root password when prompted
# Create user if desired (or do it via configuration later)

# Reboot
reboot
```

After reboot, you should be able to SSH to your server.

---

## Phase 3: Configure Secrets

See [SOPS.md](SOPS.md) for detailed instructions. Here's the quick version:

### 3.1 Generate Age Key on Server

```bash
# SSH to server as root
ssh root@your-server

# Generate age key
mkdir -p /var/lib/sops-nix
age-keygen -o /var/lib/sops-nix/key.txt
chmod 600 /var/lib/sops-nix/key.txt

# Display public key - SAVE THIS!
age-keygen -y /var/lib/sops-nix/key.txt
# Output: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**⚠️ IMPORTANT**: Back up `/var/lib/sops-nix/key.txt` securely! Store it in your password manager.

### 3.2 Install sops on Your Laptop

```bash
# On NixOS
nix-shell -p sops age

# On macOS
brew install sops age

# On other Linux
# Download from GitHub releases
```

### 3.3 Configure sops

On your laptop, in the cloned repository:

```bash
# Create .sops.yaml
cat > .sops.yaml << 'EOF'
keys:
  - &server age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

creation_rules:
  - path_regex: secrets/secrets\.yaml$
    key_groups:
      - age:
          - *server
EOF

# Replace age1xxx... with YOUR server's public key from step 3.1
```

### 3.4 Create Secrets File

```bash
# Create secrets directory
mkdir -p secrets

# Copy example
cp secrets/secrets.yaml.example secrets/secrets.yaml

# Edit with sops (auto-encrypts on save)
sops secrets/secrets.yaml
```

Fill in all the secrets (see [SOPS.md](SOPS.md) for details on getting each credential).

---

## Phase 4: Customize Configuration

### 4.1 Update vars.nix

```bash
vim vars.nix
```

Update these critical values:

```nix
{
  system = {
    hostname = "homeserver";          # Your server's hostname
    timezone = "Europe/Amsterdam";    # Your timezone
    locale = "en_US.UTF-8";          # Your locale
  };

  users = {
    admin = {
      username = "yourusername";      # YOUR username
      sshKeys = [
        "ssh-ed25519 AAAAC3... you@laptop"  # YOUR SSH public key
      ];
    };
  };

  networking = {
    baseDomain = "yourdomain.com";    # YOUR domain
    homeSubdomain = "home";           # Services at *.home.yourdomain.com
    homeDomain = "home.yourdomain.com";
    acmeEmail = "you@email.com";      # For Let's Encrypt notifications
  };

  # Service hostnames (subdomain part only)
  services = {
    authentik = "authentik";
    jellyfin = "jellyfin";
    jellyseerr = "jellyseerr";        # NEW in v2.0
    immich = "immich";
    nextcloud = "nextcloud";
    mealie = "mealie";
    homeassistant = "hass";
    llm = "llm";
    sonarr = "sonarr";
    radarr = "radarr";
    readarr = "readarr";              # NEW in v2.0
    lidarr = "lidarr";                # NEW in v2.0
    prowlarr = "prowlarr";
    bazarr = "bazarr";
    qbittorrent = "qbittorrent";      # NEW in v2.0 (replaces Transmission)
    paperless = "paperless";
    audiobookshelf = "audiobooks";
    homepage = "home";
    homarr = "homarr";                # NEW in v2.0
    pgadmin = "pgadmin";
    grafana = "grafana";
  };

  # Storage paths - should match disk labels from Phase 2
  storage = {
    media = "/mnt/media";
    photos = "/mnt/photos";
    docs = "/mnt/docs";
    shared = "/mnt/shared";
  };
}
```

### 4.2 Update flake.nix

```bash
vim flake.nix
```

Change the auto-upgrade URL:

```nix
system.autoUpgrade = {
  flake = "github:YOURUSERNAME/nixos-homeserver#homeserver";  # YOUR GitHub repo
};
```

### 4.3 Create .gitignore

```bash
cat > .gitignore << 'EOF'
# Hardware configuration (machine-specific)
hardware-configuration.nix

# Nix build results
result
result-*

# direnv
.direnv/

# Editor files
.vscode/
.idea/
*.swp
*.swo
*~

# Secrets (unencrypted)
key.txt
/var/lib/sops-nix/key.txt

# IMPORTANT: secrets.yaml IS committed (it's encrypted)
# Only exclude if unencrypted
EOF
```

---

## Phase 5: Deploy

### 5.1 Copy Configuration to Server

```bash
# On your laptop
git clone https://github.com/yourusername/nixos-homeserver
cd nixos-homeserver

# Copy to server
scp -r * root@your-server:/etc/nixos/

# Or if you prefer, clone directly on server:
ssh root@your-server
cd /etc/nixos
git clone https://github.com/yourusername/nixos-homeserver .
```

### 5.2 Generate Hardware Configuration

```bash
# On server
cd /etc/nixos
nixos-generate-config --show-hardware-config > hardware-configuration.nix
```

### 5.3 First Build

```bash
# On server
cd /etc/nixos

# Build and switch (takes 15-30 minutes on first build)
nixos-rebuild switch --flake .#homeserver

# If you see errors, don't panic! Check:
# - All secrets are filled in secrets.yaml
# - vars.nix is properly configured
# - Azure credentials are correct
```

Expected output:
- Lots of package downloads
- Services starting
- No critical errors (some warnings are OK)

### 5.4 Verify System

```bash
# Check critical services
systemctl status tailscaled
systemctl status caddy
systemctl status postgresql
systemctl status crowdsec

# All should show "active (running)"

# Check if you can still SSH
# (you should be logged in, but verify)
```

---

## Phase 6: Configure Services

See detailed guides:
- [TAILSCALE.md](TAILSCALE.md) - Connect to VPN
- [AZURE.md](AZURE.md) - Set up DNS and backups
- [CROWDSEC.md](CROWDSEC.md) - Configure security
- [SERVICES.md](SERVICES.md) - Individual service setup
- [MIGRATION.md](MIGRATION.md) - Upgrading from previous versions

### 6.1 Connect Tailscale

```bash
# Authenticate
sudo tailscale up

# Follow the URL and authorize

# Get your Tailscale IP
tailscale ip -4
# Save this: 100.x.x.x
```

### 6.2 Set Up Azure DNS

See [AZURE.md](AZURE.md) for complete instructions.

Quick summary:
1. Create CNAME: `*.home.yourdomain.com` → `homeserver.tail-scale.ts.net`
2. Create service principal for DNS-01 challenge
3. Add credentials to secrets.yaml
4. Rebuild system

### 6.3 Enroll in CrowdSec

```bash
# Sign up at https://app.crowdsec.net
# Get enrollment key

# Add to secrets.yaml
sops secrets/secrets.yaml
# Add: crowdsec.enroll_key: "your-key"

# Rebuild
nixos-rebuild switch --flake .#homeserver

# Verify enrollment
cscli console status
```

### 6.4 Test HTTPS Access

```bash
# From your laptop (connected to Tailscale)
curl -I https://home.home.yourdomain.com

# Should show:
# HTTP/2 200
# No certificate warnings!

# Open in browser
open https://home.home.yourdomain.com
```

### 6.5 Quick Setup for New Services (v2.0+)

If you're deploying version 2.0.0 or later, configure these new services:

#### qBittorrent - CRITICAL SECURITY STEP

**⚠️ Change default password immediately!**

1. Access `https://qbittorrent.home.yourdomain.com`
2. Login: `admin` / `adminadmin`
3. Tools → Options → Web UI → Change password
4. Create categories:
   - `tv-sonarr` → `/mnt/media/jellyfin/tv`
   - `movies-radarr` → `/mnt/media/jellyfin/movies`
   - `books-readarr` → `/mnt/media/books`
   - `music-lidarr` → `/mnt/media/jellyfin/music`

#### Update Download Clients in *arr Apps

For each of Sonarr, Radarr, Readarr, Lidarr:

1. Settings → Download Clients → Add → qBittorrent
2. Host: `localhost`, Port: `8282`
3. Username: `admin`, Password: (your new password)
4. Category: (appropriate category from above)
5. Test and Save

#### Jellyseerr

1. Access `https://jellyseerr.home.yourdomain.com`
2. Sign in with Jellyfin account
3. Connect Jellyfin: `http://localhost:8096`
4. Connect Sonarr: `http://localhost:8989` (with API key)
5. Connect Radarr: `http://localhost:7878` (with API key)

#### Readarr & Lidarr

1. Access each service
2. Settings → Media Management → Set root folder
3. Settings → Download Clients → Add qBittorrent
4. Connect to Prowlarr (Settings → Apps in Prowlarr)

See [SERVICES.md](SERVICES.md) for detailed configuration of all services.

---

## Phase 7: Final Testing

### 7.1 Test Each Service

Access each service and complete initial setup:

- [ ] **Homepage** (`https://home.home.yourdomain.com`) - Should load
- [ ] **Homarr** (`https://homarr.home.yourdomain.com`) - Should load
- [ ] **Authentik** (`https://authentik.home.yourdomain.com`) - Complete setup wizard
- [ ] **Jellyfin** (`https://jellyfin.home.yourdomain.com`) - Add media libraries
- [ ] **Jellyseerr** (`https://jellyseerr.home.yourdomain.com`) - Connect to Jellyfin
- [ ] **qBittorrent** (`https://qbittorrent.home.yourdomain.com`) - Change default password
- [ ] **Sonarr** (`https://sonarr.home.yourdomain.com`) - Configure download client
- [ ] **Radarr** (`https://radarr.home.yourdomain.com`) - Configure download client
- [ ] **Readarr** (`https://readarr.home.yourdomain.com`) - Configure download client
- [ ] **Lidarr** (`https://lidarr.home.yourdomain.com`) - Configure download client
- [ ] **Prowlarr** (`https://prowlarr.home.yourdomain.com`) - Add indexers
- [ ] **Immich** (`https://immich.home.yourdomain.com`) - Create account
- [ ] **NextCloud** (`https://nextcloud.home.yourdomain.com`) - Login
- [ ] **Paperless** (`https://paperless.home.yourdomain.com`) - Login
- [ ] **Home Assistant** (`https://hass.home.yourdomain.com`) - Complete onboarding
- [ ] **Mealie** (`https://mealie.home.yourdomain.com`) - Create account
- [ ] **Audiobookshelf** (`https://audiobooks.home.yourdomain.com`) - Create account
- [ ] **Open WebUI** (`https://llm.home.yourdomain.com`) - Create account
- [ ] **Grafana** (`https://grafana.home.yourdomain.com`) - Login
- [ ] **pgAdmin** (`https://pgadmin.home.yourdomain.com`) - Login

### 7.2 Test Backups

```bash
# Run manual backup
sudo systemctl start restic-backups-homeserver

# Check status
sudo systemctl status restic-backups-homeserver

# Verify snapshot created (need Azure env vars)
export AZURE_ACCOUNT_NAME=$(sudo cat /run/secrets/restic/azure_account_name)
export AZURE_ACCOUNT_KEY=$(sudo cat /run/secrets/restic/azure_account_key)
export RESTIC_PASSWORD=$(sudo cat /run/secrets/restic/password)
export RESTIC_REPOSITORY=azure:restic-backups:/

sudo -E restic snapshots
```

### 7.3 Test CrowdSec

```bash
# Check metrics
sudo cscli metrics

# View active scenarios
sudo cscli scenarios list

# Check for any alerts
sudo cscli alerts list
```

### 7.4 System Health

```bash
# Check disk usage
df -h

# Check memory
free -h

# Check for failed services
systemctl --failed

# Check logs for errors
journalctl -p err -b
```

---

## Next Steps

### Immediate Tasks

1. **⚠️ Change qBittorrent password** - Default is admin/adminadmin (SECURITY RISK!)
2. **Configure download clients** - Connect Sonarr/Radarr/Readarr/Lidarr to qBittorrent
3. **Set up Jellyseerr** - Connect to Jellyfin and arr services
4. **Configure SSO** - Set up Authentik for all services
5. **Import media** - Add your movies/TV to Jellyfin
6. **Upload photos** - Start using Immich
7. **Set up Home Assistant** - Add your smart home devices
8. **Pull LLM models** - `ollama pull llama3.1:8b`
9. **Customise dashboards** - Configure Homepage and Homarr to your liking

### Optional Enhancements

- Add more services (see modules/ for examples)
- Set up monitoring dashboards in Grafana
- Configure notification webhooks
- Enable email delivery (for Paperless, etc.)
- Set up remote backups to additional locations

### Maintenance

Your server will:
- ✅ **Auto-update** weekly (system packages)
- ✅ **Auto-backup** daily at 2 AM
- ✅ **Auto-renew** certificates (Let's Encrypt)
- ✅ **Auto-protect** against threats (CrowdSec)

Monthly tasks:
- Review CrowdSec alerts in Grafana
- Check backup status
- Review disk usage

Quarterly tasks:
- Rotate secrets/passwords
- Review and update services
- Check for NixOS channel updates

---

## Troubleshooting

If something goes wrong:

1. **Check logs**: `journalctl -xe`
2. **Check service**: `systemctl status servicename`
3. **Rollback**: `nixos-rebuild switch --rollback`
4. **See**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## Getting Help

- **Issues with this config**: Open a GitHub issue
- **NixOS questions**: https://discourse.nixos.org
- **Service-specific**: Check each service's documentation
- **CrowdSec**: https://discord.gg/crowdsec
- **Tailscale**: https://tailscale.com/kb/

---

**Congratulations! Your home server is now operational! 🎉**

Don't forget to:
- ⭐ Star this repo if it helped you
- 📝 Document any customizations you make
- 🤝 Contribute improvements back to the community

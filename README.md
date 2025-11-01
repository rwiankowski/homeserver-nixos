# 🏠 NixOS Home Server

A complete, production-ready NixOS configuration for self-hosting 20+ services with enterprise-grade security, automated backups, and zero-trust networking.

> **Perfect for**: Home lab enthusiasts, privacy-conscious users, and anyone wanting to self-host their digital life with minimal maintenance.

> DISCLAIMER - this entire project was vibe-engineered with claude.ai 

## ✨ Features

### 🎬 Media & Entertainment
- **Jellyfin** - Stream your movies, TV shows, and music
- **Jellyseerr** - Media request management for Jellyfin
- **Sonarr/Radarr** - Automated TV show and movie management
- **Readarr/Lidarr** - Ebook and music library management
- **Prowlarr/Bazarr** - Indexer management and subtitles
- **qBittorrent** - Torrent download client with modern web UI
- **Audiobookshelf** - Audiobook and podcast server

### 📸 Photos & Documents
- **Immich** - Google Photos alternative with ML features
- **NextCloud** - File sync and collaboration
- **Paperless-ngx** - Document management with OCR

### 🏡 Smart Home & Productivity
- **Home Assistant** - Home automation platform
- **Mealie** - Recipe manager and meal planner
- **Homepage** - Beautiful dashboard for all services
- **Homarr** - Modern dashboard with service monitoring

### 🤖 AI & LLM
- **Open WebUI** - ChatGPT-like interface
- **Ollama** - Run Llama, Mistral, and other models locally
- **SearXNG** - Private web search integration

### 🔐 Security & Infrastructure
- **Authentik** - Single sign-on (SSO) provider
- **CrowdSec** - Collaborative threat protection
- **Tailscale** - Zero-config VPN
- **Caddy** - Automatic HTTPS reverse proxy
- **PostgreSQL** - Centralized database
- **pgAdmin** - Database management interface
- **Grafana** - Monitoring and metrics

### 💾 Backups & Storage
- **Restic** - Encrypted, deduplicated backups to Azure Blob Storage
- **Multi-disk optimization** - Separate SSDs/HDDs for performance
- **Automated retention** - Daily, weekly, monthly, and yearly snapshots

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Internet                                 │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                │ (Tailscale VPN - 100.x.x.x)
                                │ (No exposed ports!)
                                │
┌───────────────────────────────┼─────────────────────────────────┐
│                         Your Devices                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │  Laptop  │  │  Phone   │  │  Tablet  │  │  Desktop │       │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                │ HTTPS (Let's Encrypt)
                                │ *.home.yourdomain.com
                                │
┌───────────────────────────────┼─────────────────────────────────┐
│                    Caddy Reverse Proxy                           │
│         ┌──────────────────────────────────────────┐            │
│         │  Authentik SSO  │  CrowdSec Protection   │            │
│         └──────────────────────────────────────────┘            │
└───────────────────────────────┬─────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
┌───────▼────────┐    ┌────────▼────────┐    ┌───────▼────────┐
│  Media Services│    │ Document Services│    │  Smart Home    │
│  • Jellyfin    │    │ • NextCloud      │    │ • Home Assist. │
│  • Jellyseerr  │    │ • Paperless      │    │ • Mealie       │
│  • Sonarr      │    │ • Immich         │    │ • Open WebUI   │
│  • Radarr      │    │                  │    │ • Homarr       │
│  • Readarr     │    │                  │    │ • Homepage     │
│  • Lidarr      │    │                  │    │                │
│  • qBittorrent │    │                  │    │                │
│  • Audiobooks  │    │                  │    │                │
└────────────────┘    └──────────────────┘    └────────────────┘
        │                       │                       │
        └───────────────────────┼───────────────────────┘
                                │
                    ┌───────────▼──────────┐
                    │  PostgreSQL Database │
                    │  (Centralized)       │
                    └──────────────────────┘
                                │
                    ┌───────────▼──────────┐
                    │   Multi-Disk Storage │
                    │  📀 SSD: Docs/Photos │
                    │  💿 HDD: Media       │
                    └──────────────────────┘
                                │
                    ┌───────────▼──────────┐
                    │   Restic Backups     │
                    │   → Azure Blob       │
                    └──────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- NixOS installed on a server/VM
- Domain name (optional but recommended)
- Azure account (for backups and DNS)
- Tailscale account (free)
- Basic understanding of NixOS

### Installation

```bash
# 1. Clone this repository
git clone https://github.com/yourusername/nixos-homeserver
cd nixos-homeserver

# 2. Copy and customize variables
cp vars.nix.example vars.nix
vim vars.nix  # Set your hostname, timezone, domain, etc.

# 3. Set up secrets (see docs/SOPS.md)
# Generate age key, create secrets file

# 4. Generate hardware configuration
sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix

# 5. Deploy
sudo nixos-rebuild switch --flake .#homeserver
```

**⚠️ Important:** Follow the complete setup guide in [docs/SETUP.md](docs/SETUP.md) for detailed instructions.

## 📚 Documentation

### Getting Started
- **[Complete Setup Guide](docs/SETUP.md)** - Step-by-step deployment instructions
- **[Azure Setup](docs/AZURE.md)** - Configure DNS, storage, and service principal
- **[Tailscale Guide](docs/TAILSCALE.md)** - VPN configuration
- **[Secrets Management](docs/SOPS.md)** - Using sops-nix for secrets

### Service Configuration
- **[Arr Stack Setup](docs/ARR_STACK_SETUP.md)** - Complete media automation workflow setup
- **[Service Configuration](docs/SERVICES.md)** - Individual service setup
- **[CrowdSec Guide](docs/CROWDSEC.md)** - Security monitoring

### Maintenance
- **[Backup Guide](docs/BACKUP.md)** - Backup and restore procedures
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions

## 💡 Key Design Decisions

### Why These Choices?

**NixOS** - Declarative configuration, atomic upgrades, easy rollbacks  
**Tailscale** - Zero-config VPN, no exposed ports, works everywhere  
**Azure DNS** - Custom domain with Let's Encrypt certs, private access  
**CrowdSec** - Community-powered threat protection  
**Authentik** - Modern SSO with great UI  
**PostgreSQL** - Single database instance (not multiple containers)  
**Restic** - Encrypted backups with deduplication  
**sops-nix** - Secrets encrypted in git  

### Security Features

- ✅ **No exposed ports** - Everything via Tailscale VPN
- ✅ **Encrypted secrets** - sops-nix with age encryption
- ✅ **SSH hardening** - Key-based only, no root login
- ✅ **Automatic updates** - Weekly system updates
- ✅ **Fail2ban** - Brute force protection
- ✅ **CrowdSec** - Real-time threat detection and blocking
- ✅ **SSL/TLS** - Let's Encrypt certificates for all services
- ✅ **Firewall** - Minimal attack surface

### Storage Strategy

**Optimized for cost and performance:**
- 📀 **SSD**: Photos (Immich), Documents (NextCloud, Paperless)
- 💿 **HDD**: Media (Jellyfin) - large, replaceable content
- ☁️ **Cloud**: Backups (Azure) - critical data only (~100-300GB)
- 🚫 **Not backed up**: Media files (can be re-downloaded)

**Monthly cost**: ~$2-3 for Azure backups

## 🎯 Use Cases

Perfect for:
- 🏠 **Home Lab** - Run your own cloud services
- 👨‍👩‍👧‍👦 **Family** - Shared photos, documents, media
- 🔐 **Privacy** - Keep your data under your control
- 📚 **Learning** - Understand infrastructure and DevOps
- 💼 **Portfolio** - Demonstrate infrastructure skills

## 🛠️ Customization

### Enable/Disable Services

Edit `configuration.nix` to comment out services you don't want:

```nix
imports = [
  # ./modules/jellyfin.nix     # Disable Jellyfin
  ./modules/immich.nix          # Keep Immich
  # ./modules/paperless.nix     # Disable Paperless
];
```

### Add New Services

1. Create `modules/myservice.nix`
2. Add to `configuration.nix` imports
3. Rebuild: `sudo nixos-rebuild switch --flake .#homeserver`

### Customize Variables

All user-specific settings are in `vars.nix`:
- Hostname and timezone
- Domain names
- Service URLs
- Storage paths

## 📊 Resource Requirements

**Minimum:**
- CPU: 4 cores
- RAM: 8GB
- Storage: 100GB+ (root) + additional disks

**Recommended:**
- CPU: 6+ cores
- RAM: 16GB+ (for LLMs)
- Storage: 50GB (root) + 500GB (media) + 200GB (photos/docs)
- GPU: Optional (for LLM inference and Jellyfin transcoding)

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on a clean NixOS install
5. Submit a pull request

**Ideas for contributions:**
- Additional services
- Alternative DNS providers
- Monitoring improvements
- Documentation enhancements
- Bug fixes

## 🙏 Acknowledgments

Built with these amazing open-source projects:
- [NixOS](https://nixos.org/) - The Purely Functional Linux Distribution
- [Tailscale](https://tailscale.com/) - Zero config VPN
- [CrowdSec](https://www.crowdsec.net/) - Collaborative security
- [Caddy](https://caddyserver.com/) - Automatic HTTPS server
- [Authentik](https://goauthentik.io/) - Identity provider
- All the incredible self-hosted services this config supports

Special thanks to the NixOS community for the excellent documentation and support.

## 📄 License

MIT License - feel free to use, modify, and share!

## 🌟 Star History

If you find this useful, please give it a star! ⭐

## 💬 Community

- **Questions?** Open an issue or discussion
- **Found a bug?** Please report it
- **Success story?** Share it!

## 📮 Contact

- GitHub: [@rwiankowski](https://github.com/rwiankowski)

---

**Built with ❤️ using NixOS**

*Self-hosting should be easy, secure, and fun!*

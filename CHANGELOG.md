# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-11-01

### Added
- **qBittorrent**: Replaced Transmission with qBittorrent for improved web UI and better NixOS integration
  - Configured on port 8282 with media user/group permissions
  - Automatic download directory creation and permissions management
- **Jellyseerr**: Media request management system for Jellyfin
  - Deployed as Docker container on port 5055
  - Integrated with Caddy reverse proxy
- **Homarr**: Modern dashboard for service management
  - Deployed as Docker container on port 7575
  - Docker socket integration for service monitoring
- **Readarr**: Ebook and audiobook library management
  - Native NixOS service on port 8787
  - Configured with media user/group permissions
- **Lidarr**: Music library management and automation
  - Native NixOS service on port 8686
  - Configured with media user/group permissions
- New "Books & Music" section in Homepage dashboard
- Caddy reverse proxy entries for all new services

### Changed
- Updated Homepage dashboard layout to accommodate new services
  - Media section expanded to 4 columns
  - System section expanded to 3 columns
  - Added dedicated Books & Music section with 3 columns
- Reorganized service groupings in Homepage for better categorization

### Removed
- **Transmission**: Removed in favor of qBittorrent

### Security
- All new services configured with `openFirewall = false` for security
- Services only accessible through Caddy reverse proxy with Tailscale integration
- Docker containers run with appropriate permission restrictions

## [1.0.0] - Initial Release

### Added
- Initial NixOS homeserver configuration with flakes
- Core services: Jellyfin, Sonarr, Radarr, Prowlarr, Bazarr
- Productivity suite: Nextcloud, Paperless-ngx, Mealie
- Smart home: Home Assistant
- Photo management: Immich
- AI tools: LLM Assistant (Open WebUI)
- Authentication: Authentik SSO
- Monitoring: Grafana, pgAdmin
- Media: Audiobookshelf
- Networking: Caddy reverse proxy with Tailscale and Azure DNS integration
- Security: CrowdSec integration, sops-nix for secrets management
- Backup system with automated schedules
- Modular configuration structure

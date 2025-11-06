# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- **Redis**: Disabled protected mode to allow Docker container connections (fixes error 104)
  - Added `settings = { protected-mode = "no"; }` to Redis configuration
  - Fixes "error 104 - Connection reset by peer" when Authentik containers try to connect
  - Root cause: Redis protected mode blocks non-localhost connections when no password is configured
  - Security maintained: Firewall still blocks external access (`openFirewall = false`)
  - Redis remains accessible only from localhost and Docker containers, no internet exposure
  - This is the standard approach for containerized environments with firewall protection
  - System rebuild required: `sudo nixos-rebuild switch --flake .#homeserver`
  - After rebuild, verify Authentik can connect: `docker logs authentik-server` (should show no Redis errors)
  - Alternative approach: Use password authentication with `requirePass` (more complex, same security level)
- **Redis**: Fixed bind address configuration to resolve Authentik connection errors
  - Changed bind address from `127.0.0.1 172.17.0.1` to `0.0.0.0` (all interfaces)
  - Fixes "error 102 while writing to socket" when Authentik tries to connect via `host.docker.internal`
  - Root cause: `--add-host=host.docker.internal:host-gateway` resolves to the host's gateway IP from container's perspective, which may not be `172.17.0.1`
  - Security maintained: `openFirewall = false` ensures Redis port 6379 remains blocked by firewall
  - Redis now accessible from Docker containers regardless of network mode (bridge or host)
  - System rebuild required: `sudo nixos-rebuild switch --flake .#homeserver`
  - After rebuild, verify Redis is listening on all interfaces: `ss -tlnp | grep 6379` (should show `0.0.0.0:6379`)
  - Verify Authentik can connect: `docker logs authentik-server` (should show no Redis connection errors)
- **Redis**: Fixed Redis service configuration to actually start and be accessible from Docker containers
  - Redis was configured but never activated (service was not running at all)
  - Changed bind address from `127.0.0.1` to `127.0.0.1 172.17.0.1` to allow Docker container access
  - Added explicit `openFirewall = false` for security (Redis only accessible locally and from Docker)
  - System rebuild required for Redis to start: `sudo nixos-rebuild switch --flake .#homeserver`
  - After rebuild, verify with: `systemctl status redis-shared.service` and `ss -tlnp | grep 6379`
- **Authentik**: Fixed PostgreSQL and Redis connection from Docker containers
  - Changed `AUTHENTIK_POSTGRESQL__HOST` from `127.0.0.1` to `host.docker.internal`
  - Changed `AUTHENTIK_REDIS__HOST` from `127.0.0.1` to `host.docker.internal`
  - Containers now correctly connect to host services using the Docker gateway
  - Note: Immich correctly uses `127.0.0.1` because it runs with `--network=host`

### Added
- **Local Network Access**: Services now accessible from LAN using domain-based routing
  - LAN interface added to firewall trusted interfaces for seamless local access
  - Same domain names work on both Tailscale VPN and local network (e.g., `https://media.home.lucy31.cloud`)
  - DNS-based routing: Tailscale DNS resolves to VPN IP, local DNS resolves to LAN IP
  - Let's Encrypt certificates work for both access methods (no self-signed certificates needed)
  - New configuration variables in `vars.nix`:
    - `networking.lanInterface` - LAN network interface name (e.g., `enp24s0`)
    - `networking.enableLocalAccess` - Toggle for local network access (default: `true`)
  - Requires local DNS configuration to resolve `*.home.lucy31.cloud` to server's LAN IP
  - Security maintained: No internet exposure, interface-specific access control

### Changed
- **Homarr**: Upgraded to v1+ (v1.43.1) - Major feature release
  - **New features:**
    - Built-in user authentication and management
    - SSO support (OIDC/LDAP) for enterprise integration
    - 30+ service integrations (expanded from previous version)
    - Built-in search across all services and media
    - 11,000+ icons in icon picker
    - Real-time updates using WebSockets
    - Enhanced drag-and-drop customization
  - **Technical changes:**
    - Updated Docker image from `ghcr.io/ajnart/homarr:latest` to `ghcr.io/homarr-labs/homarr:1`
    - Project moved to homarr-labs GitHub organization
    - Now using semantic versioning (`:1` tag for v1.x releases)
  - **Backward compatible:** Existing data and configuration work seamlessly
  - **No action required:** Upgrade is automatic on next deployment
- **Directory Management**: Centralized all disk-related directory creation in `disk-mounts.nix`
  - Moved arr stack directory creation from individual service modules to centralized location
  - Removed duplicate `systemd.tmpfiles.rules` from arr-stack.nix, jellyseerr.nix, and homarr.nix
  - Added `/mnt/media/books` directory for Readarr ebook storage
  - Improved organization with clear section comments (System services vs Arr Stack)
  - All directory permissions now managed in a single, maintainable location
  - Removed directory creation for Bazarr and Prowlarr (use default /var/lib paths)

### Fixed
- **qBittorrent**: Corrected NixOS module configuration to use valid options
  - Replaced invalid `dataDir` option with `profileDir` for config storage
  - Replaced invalid `port` option with proper `webuiPort` configuration
  - Added `serverConfig` to properly configure download paths and WebUI settings
  - Downloads now correctly saved to `/mnt/media/downloads` as intended
  - Profile/config data stored on `/mnt/shared/qbittorrent` for backups
- **Bazarr & Prowlarr**: Removed invalid `dataDir` configuration options
  - Bazarr in NixOS 25.05 does not support custom `dataDir` (uses StateDirectory)
  - Prowlarr in NixOS 25.05 does not support custom `dataDir` (uses StateDirectory)
  - Both services now use default paths: `/var/lib/bazarr` and `/var/lib/prowlarr`
  - Sonarr, Radarr, Readarr, and Lidarr continue to support custom `dataDir` on `/mnt/shared`

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

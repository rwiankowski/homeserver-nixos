{ config, pkgs, ... }:

let
  vars = import ../vars.nix;
  mkServiceUrl = service: "https://${service}.${vars.networking.homeDomain}";
in {
  virtualisation.oci-containers.containers.homepage = {
    image = "ghcr.io/gethomepage/homepage:latest";
    environment = {
      TZ = vars.system.timezone;
    };
    ports = [ "3001:3000" ];
    volumes = [
      "${vars.storage.shared}/homepage:/app/config"
      "/var/run/docker.sock:/var/run/docker.sock:ro"
    ];
  };

  # Create initial homepage configuration
  system.activationScripts.homepage-config = ''
    mkdir -p ${vars.storage.shared}/homepage
    
    # Create services.yaml if it doesn't exist
    if [ ! -f ${vars.storage.shared}/homepage/services.yaml ]; then
      cat > ${vars.storage.shared}/homepage/services.yaml << 'EOF'
---
- Media:
    - Jellyfin:
        icon: jellyfin.png
        href: ${mkServiceUrl vars.services.jellyfin}
        description: Media server
    - Sonarr:
        icon: sonarr.png
        href: ${mkServiceUrl vars.services.sonarr}
        description: TV shows
    - Radarr:
        icon: radarr.png
        href: ${mkServiceUrl vars.services.radarr}
        description: Movies
    - Prowlarr:
        icon: prowlarr.png
        href: ${mkServiceUrl vars.services.prowlarr}
        description: Indexer manager
    - Bazarr:
        icon: bazarr.png
        href: ${mkServiceUrl vars.services.bazarr}
        description: Subtitles
    - Audiobookshelf:
        icon: audiobookshelf.png
        href: ${mkServiceUrl vars.services.audiobookshelf}
        description: Audiobooks & Podcasts

- Productivity:
    - NextCloud:
        icon: nextcloud.png
        href: ${mkServiceUrl vars.services.nextcloud}
        description: Cloud storage
    - Paperless-ngx:
        icon: paperless.png
        href: ${mkServiceUrl vars.services.paperless}
        description: Document management
    - Mealie:
        icon: mealie.png
        href: ${mkServiceUrl vars.services.mealie}
        description: Recipe manager

- Smart Home:
    - Home Assistant:
        icon: home-assistant.png
        href: ${mkServiceUrl vars.services.homeassistant}
        description: Home automation

- Photos:
    - Immich:
        icon: immich.png
        href: ${mkServiceUrl vars.services.immich}
        description: Photo management

- AI & Tools:
    - LLM Assistant:
        icon: openwebui.png
        href: ${mkServiceUrl vars.services.llm}
        description: AI chat with web search

- System:
    - Authentik:
        icon: authentik.png
        href: ${mkServiceUrl vars.services.authentik}
        description: SSO provider
    - pgAdmin:
        icon: postgres.png
        href: ${mkServiceUrl vars.services.pgadmin}
        description: Database management
    - Grafana:
        icon: grafana.png
        href: ${mkServiceUrl vars.services.grafana}
        description: Monitoring & CrowdSec stats
EOF
    fi

    # Create settings.yaml if it doesn't exist
    if [ ! -f ${vars.storage.shared}/homepage/settings.yaml ]; then
      cat > ${vars.storage.shared}/homepage/settings.yaml << 'EOF'
---
title: Home Server
theme: dark
color: slate
headerStyle: boxed
layout:
  Media:
    style: row
    columns: 3
  Productivity:
    style: row
    columns: 3
  Smart Home:
    style: row
    columns: 2
  Photos:
    style: row
    columns: 2
  AI & Tools:
    style: row
    columns: 2
  System:
    style: row
    columns: 2
EOF
    fi

    chmod -R 755 ${vars.storage.shared}/homepage
  '';
}

{
  # System settings
  system = {
    hostname = "nixtromo";
    timezone = "Europe/Amsterdam";
    locale = "en_US.UTF-8";
  };

  # User configuration
  users = {
    admin = {
      username = "rwiankowski";
      sshKeys = [
        # Add your SSH public keys here
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGZ2HI4YZCT2JFg+8wqt8Lhqhb7kKd41M72GTBvTiwk1"
      ];
    };
  };

   # Domain configuration - YOUR custom domain!
  networking = {
    # Your public domain
    baseDomain = "lucy31.cloud";
    
    # Subdomain for home services
    # Services will be at: jellyfin.home.yourdomain.com
    homeSubdomain = "home";
    
    # Full home domain (computed)
    homeDomain = "home.lucy31.cloud";
    
    # Email for Let's Encrypt notifications
    acmeEmail = "rwiankowski@mac.com";
  };

  # Service hostnames (subdomain part only)
  # Will become: service.home.yourdomain.com
  services = {
    authentik = "sso";
    jellyfin = "media";
    immich = "photos";
    nextcloud = "docs";
    mealie = "recipes";
    homeassistant = "assistant";
    llm = "chat";
    sonarr = "sonarr";
    radarr = "radarr";
    prowlarr = "prowlarr";
    bazarr = "bazarr";
    readarr = "books";
    lidarr = "music";
    qbittorrent = "downloads";
    jellyseerr = "discover";
    homarr = "watch";
    paperless = "scans";
    audiobookshelf = "audiobooks";
    homepage = "dash";
    pgadmin = "pgadmin";
    grafana = "monitor";
  };

  # Storage paths - mount points for dedicated disks
  storage = {
    media = "/mnt/media";         # HDD - Jellyfin, Audiobookshelf
    photos = "/mnt/photos";       # SSD - Immich
    docs = "/mnt/docs";           # SSD - NextCloud, Paperless
    shared = "/mnt/shared";       # SSD/HDD - Everything else
  };
}


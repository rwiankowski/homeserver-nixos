{ config, pkgs, ... }:

let
  vars = import ../vars.nix;
in {
  services.sonarr = {
    enable = true;
    openFirewall = false;
    user = "media";
    group = "media";
    dataDir = "${vars.storage.shared}/sonarr";
  };

  services.radarr = {
    enable = true;
    openFirewall = false;
    user = "media";
    group = "media";
    dataDir = "${vars.storage.shared}/radarr";
  };

  services.prowlarr = {
    enable = true;
    openFirewall = false;
    # Note: Prowlarr in NixOS 25.05 does not support custom dataDir
    # Data will be stored in /var/lib/prowlarr (managed by StateDirectory)
  };

  services.bazarr = {
    enable = true;
    openFirewall = false;
    user = "media";
    group = "media";
    # Note: Bazarr in NixOS 25.05 does not support custom dataDir
    # Data will be stored in /var/lib/bazarr (managed by StateDirectory)
  };

  services.readarr = {
    enable = true;
    openFirewall = false;
    user = "media";
    group = "media";
    dataDir = "${vars.storage.shared}/readarr";
  };

  services.lidarr = {
    enable = true;
    openFirewall = false;
    user = "media";
    group = "media";
    dataDir = "${vars.storage.shared}/lidarr";
  };

  services.qbittorrent = {
    enable = true;
    openFirewall = false;
    user = "media";
    group = "media";
    profileDir = "${vars.storage.shared}/qbittorrent";
    webuiPort = 8282;
    
    serverConfig = {
      LegalNotice.Accepted = true;
      Preferences = {
        Downloads = {
          SavePath = "${vars.storage.media}/downloads";
          TempPath = "${vars.storage.media}/downloads/.incomplete";
          TempPathEnabled = true;
        };
        WebUI = {
          # Allow access from reverse proxy
          CSRFProtection = false;
          HostHeaderValidation = false;
        };
      };
    };
  };

}


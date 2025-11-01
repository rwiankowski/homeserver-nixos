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
    dataDir = "${vars.storage.shared}/prowlarr";
  };

  services.bazarr = {
    enable = true;
    openFirewall = false;
    user = "media";
    group = "media";
    dataDir = "${vars.storage.shared}/bazarr";
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


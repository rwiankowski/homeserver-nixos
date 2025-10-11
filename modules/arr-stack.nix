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
  };

  services.bazarr = {
    enable = true;
    openFirewall = false;
    user = "media";
    group = "media";
  };

  services.transmission = {
    enable = true;
    openFirewall = false;
    user = "media";
    group = "media";
    settings = {
      download-dir = "${vars.storage.media}/downloads";
      incomplete-dir = "${vars.storage.media}/downloads/.incomplete";
      rpc-bind-address = "127.0.0.1";
      rpc-whitelist-enabled = false;
    };
  };
}


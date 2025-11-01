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
    dataDir = "${vars.storage.shared}/qbittorrent";
    port = 8282;
    webuiPort = 8282;
  };

  systemd.services.qbittorrent.preStart = ''
    mkdir -p ${vars.storage.media}/downloads
    chown media:media ${vars.storage.media}/downloads
  '';

  systemd.tmpfiles.rules = [
    "d ${vars.storage.media}/downloads 0755 media media -"
    "d ${vars.storage.media}/downloads/.incomplete 0755 media media -"
  ];
}


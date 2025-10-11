{ config, pkgs, ... }:

let
  vars = import ../vars.nix;
in {
  services.jellyfin = {
    enable = true;
    openFirewall = false;
    user = "media";
    group = "media";
    dataDir = "${vars.storage.shared}/jellyfin";
  };

  users.users.media = {
    isSystemUser = true;
    group = "media";
    createHome = false;
  };
  users.groups.media = {};
}


{ config, pkgs, ... }:

let
  vars = import ../vars.nix;
in {
  virtualisation.oci-containers.containers.audiobookshelf = {
    image = "ghcr.io/advplyr/audiobookshelf:latest";
    environment = {
      TZ = vars.system.timezone;
      AUDIOBOOKSHELF_UID = "1000";
      AUDIOBOOKSHELF_GID = "1000";
    };
    ports = [ "13378:80" ];
    volumes = [
      "${vars.storage.media}/audiobooks:/audiobooks"
      "${vars.storage.media}/podcasts:/podcasts"
      "${vars.storage.shared}/audiobookshelf/config:/config"
      "${vars.storage.shared}/audiobookshelf/metadata:/metadata"
    ];
    user = "media:media";
  };
}

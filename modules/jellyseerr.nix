{ config, pkgs, ... }:

let
  vars = import ../vars.nix;
in {
  virtualisation.docker.enable = true;

  virtualisation.oci-containers.containers.jellyseerr = {
    image = "fallenbagel/jellyseerr:latest";
    environment = {
      TZ = vars.system.timezone;
      LOG_LEVEL = "info";
    };
    ports = [ "5055:5055" ];
    volumes = [
      "${vars.storage.shared}/jellyseerr:/app/config"
    ];
  };
}

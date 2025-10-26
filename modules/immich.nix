{ config, pkgs, ... }:

let
  vars = import ../vars.nix;
in {
  virtualisation.oci-containers.containers = {
    immich-server = {
      image = "ghcr.io/immich-app/immich-server:release";
      environmentFiles = [ config.sops.templates."immich-env".path ];
      environment = {
        UPLOAD_LOCATION = "${vars.storage.photos}/immich/upload";
      };
      ports = [ "2283:3001" ];
      volumes = [
        "${vars.storage.photos}/immich/upload:/usr/src/app/upload"
        "${vars.storage.photos}/immich/library:/usr/src/app/library"
      ];
      extraOptions = [ "--add-host=host.docker.internal:host-gateway" ];
    };
    
    immich-machine-learning = {
      image = "ghcr.io/immich-app/immich-machine-learning:release";
      volumes = [ "${vars.storage.shared}/immich/model-cache:/cache" ];
    };
  };
}

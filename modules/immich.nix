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
      volumes = [
        "${vars.storage.photos}/immich/upload:/usr/src/app/upload"
        "${vars.storage.photos}/immich/library:/usr/src/app/library"
      ];
      extraOptions = [ "--network=host" ];
    };
    
    immich-machine-learning = {
      image = "ghcr.io/immich-app/immich-machine-learning:release";
      volumes = [ "${vars.storage.shared}/immich/model-cache:/cache" ];
    };
  };
}

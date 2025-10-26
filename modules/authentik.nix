{ config, pkgs, ... }:

let
  vars = import ../vars.nix;
in {
  virtualisation.docker.enable = true;
  
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      authentik-server = {
        image = "ghcr.io/goauthentik/server:2025.8";
        environmentFiles = [ config.sops.templates."authentik-env".path ];
        ports = [ "9000:9000" "9443:9443" ];
        volumes = [ "${vars.storage.shared}/authentik/media:/media" ];
        cmd = [ "server" ];
        extraOptions = [ "--add-host=host.docker.internal:host-gateway" ];
      };
      
      authentik-worker = {
        image = "ghcr.io/goauthentik/server:2025.8";
        environmentFiles = [ config.sops.templates."authentik-env".path ];
        volumes = [ "${vars.storage.shared}/authentik/media:/media" ];
        cmd = [ "worker" ];
        extraOptions = [ "--add-host=host.docker.internal:host-gateway" ];
      };
    };
  };
}

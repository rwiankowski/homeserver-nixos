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
        environmentFiles = [
          (pkgs.writeText "authentik-env" ''
            AUTHENTIK_ERROR_REPORTING__ENABLED=false
            AUTHENTIK_POSTGRESQL__HOST=127.0.0.1
            AUTHENTIK_POSTGRESQL__NAME=authentik
            AUTHENTIK_POSTGRESQL__USER=authentik
            AUTHENTIK_REDIS__HOST=127.0.0.1
          '')
        ];
        environment = {
          AUTHENTIK_SECRET_KEY = "$(cat ${config.sops.secrets."authentik/secret_key".path})";
          AUTHENTIK_POSTGRESQL__PASSWORD = "$(cat ${config.sops.secrets."database/authentik_password".path})";
        };
        ports = [ "9000:9000" "9443:9443" ];
        volumes = [ "${vars.storage.shared}/authentik/media:/media" ];
        cmd = [ "server" ];
        extraOptions = [ "--network=host" ];
      };
      
      authentik-worker = {
        image = "ghcr.io/goauthentik/server:2025.8";
        environmentFiles = [
          (pkgs.writeText "authentik-env" ''
            AUTHENTIK_ERROR_REPORTING__ENABLED=false
            AUTHENTIK_POSTGRESQL__HOST=127.0.0.1
            AUTHENTIK_POSTGRESQL__NAME=authentik
            AUTHENTIK_POSTGRESQL__USER=authentik
            AUTHENTIK_REDIS__HOST=127.0.0.1
          '')
        ];
        environment = {
          AUTHENTIK_SECRET_KEY = "$(cat ${config.sops.secrets."authentik/secret_key".path})";
          AUTHENTIK_POSTGRESQL__PASSWORD = "$(cat ${config.sops.secrets."database/authentik_password".path})";
        };
        volumes = [ "${vars.storage.shared}/authentik/media:/media" ];
        cmd = [ "worker" ];
        extraOptions = [ "--network=host" ];
      };
    };
  };
}

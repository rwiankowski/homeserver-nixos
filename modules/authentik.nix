
{ config, pkgs, ... }:

let
  vars = import ../vars.nix;
in {
  virtualisation.docker.enable = true;
  
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      authentik-server = {
        image = "ghcr.io/goauthentik/server:2024.8";
        environment = {
          AUTHENTIK_SECRET_KEY = "replace-with-generated-secret";
          AUTHENTIK_ERROR_REPORTING__ENABLED = "false";
          AUTHENTIK_POSTGRESQL__HOST = "host.docker.internal";
          AUTHENTIK_POSTGRESQL__NAME = "authentik";
          AUTHENTIK_POSTGRESQL__USER = "authentik";
          AUTHENTIK_POSTGRESQL__PASSWORD = "replace-with-password";
          AUTHENTIK_REDIS__HOST = "host.docker.internal";
        };
        ports = [ "9000:9000" "9443:9443" ];
        volumes = [ "${vars.storage.shared}/authentik/media:/media" ];
        cmd = [ "server" ];
        extraOptions = [ "--add-host=host.docker.internal:host-gateway" ];
      };
      
      authentik-worker = {
        image = "ghcr.io/goauthentik/server:2024.8";
        environment = {
          AUTHENTIK_SECRET_KEY = "replace-with-generated-secret";
          AUTHENTIK_ERROR_REPORTING__ENABLED = "false";
          AUTHENTIK_POSTGRESQL__HOST = "host.docker.internal";
          AUTHENTIK_POSTGRESQL__NAME = "authentik";
          AUTHENTIK_POSTGRESQL__USER = "authentik";
          AUTHENTIK_POSTGRESQL__PASSWORD = "replace-with-password";
          AUTHENTIK_REDIS__HOST = "host.docker.internal";
        };
        volumes = [ "${vars.storage.shared}/authentik/media:/media" ];
        cmd = [ "worker" ];
        extraOptions = [ "--add-host=host.docker.internal:host-gateway" ];
      };
    };
  };
}


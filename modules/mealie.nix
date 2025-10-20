{ config, pkgs, ... }:

let
  vars = import ../vars.nix;
in {
  virtualisation.oci-containers.containers.mealie = {
    image = "ghcr.io/mealie-recipes/mealie:v3.3.2";
    environment = {
      ALLOW_SIGNUP = "false";
      PUID = "1000";
      PGID = "1000";
      TZ = vars.system.timezone;
      MAX_WORKERS = "1";
      WEB_CONCURRENCY = "1";
      BASE_URL = "https://${vars.services.mealie}.${vars.networking.homeDomain}";
    };
    ports = [ "9925:9000" ];
    volumes = [ "${vars.storage.shared}/mealie:/app/data" ];
  };
}


{ config, pkgs, ... }:

let
  vars = import ../vars.nix;
in {
  virtualisation.docker.enable = true;

  virtualisation.oci-containers.containers.homarr = {
    # Homarr v1+ from homarr-labs organization
    # https://github.com/homarr-labs/homarr
    image = "ghcr.io/homarr-labs/homarr:1";
    environment = {
      TZ = vars.system.timezone;
      BASE_URL = "https://${vars.services.homarr}.${vars.networking.homeDomain}";
    };
    ports = [ "7575:7575" ];
    volumes = [
      "${vars.storage.shared}/homarr/configs:/app/data/configs"
      "${vars.storage.shared}/homarr/icons:/app/public/icons"
      "${vars.storage.shared}/homarr/data:/data"
      "/var/run/docker.sock:/var/run/docker.sock:ro"
    ];
  };
}

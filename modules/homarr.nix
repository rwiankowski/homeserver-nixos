{ config, pkgs, ... }:

let
  vars = import ../vars.nix;
in {
  virtualisation.docker.enable = true;

  virtualisation.oci-containers.containers.homarr = {
    image = "ghcr.io/ajnart/homarr:latest";
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

  systemd.tmpfiles.rules = [
    "d ${vars.storage.shared}/homarr 0755 root root -"
    "d ${vars.storage.shared}/homarr/configs 0755 root root -"
    "d ${vars.storage.shared}/homarr/icons 0755 root root -"
    "d ${vars.storage.shared}/homarr/data 0755 root root -"
  ];
}

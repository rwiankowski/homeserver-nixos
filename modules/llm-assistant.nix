{ config, pkgs, ... }:

let
  vars = import ../vars.nix;
in {
  virtualisation.oci-containers.containers = {
    open-webui = {
      image = "ghcr.io/open-webui/open-webui:v0.4.5";  # Pinned to stable version
      environmentFiles = [ config.sops.templates."openwebui-env".path ];
      ports = [ "3000:8080" ];
      volumes = [ "${vars.storage.shared}/open-webui:/app/backend/data" ];
      extraOptions = [ "--add-host=host.docker.internal:host-gateway" ];
    };
    
    searxng = {
      image = "searxng/searxng:latest";
      ports = [ "8888:8080" ];
      volumes = [ "${vars.storage.shared}/searxng:/etc/searxng" ];
    };
  };

  services.ollama = {
    enable = true;
    acceleration = "rocm";
    openFirewall = false;
    host = "127.0.0.1";
    port = 11434;
  };
}

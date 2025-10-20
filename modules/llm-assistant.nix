{ config, pkgs, ... }:

let
  vars = import ../vars.nix;
in {
  virtualisation.oci-containers.containers = {
    open-webui = {
      image = "ghcr.io/open-webui/open-webui:main";
      environment = {
        OLLAMA_BASE_URL = "http://host.docker.internal:11434";
        WEBUI_SECRET_KEY = "replace-with-secret";
        ENABLE_RAG_WEB_SEARCH = "true";
        RAG_WEB_SEARCH_ENGINE = "searxng";
        SEARXNG_QUERY_URL = "http://host.docker.internal:8888/search?q=<query>";
      };
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

{ config, pkgs, ... }:

let
  vars = import ../vars.nix;
in {
  services.home-assistant = {
    enable = true;
    openFirewall = false;
    dataDir = "${vars.storage.shared}/home-assistant";
    
    config = {
      default_config = {};
      http = {
        server_host = "127.0.0.1";
        server_port = 8123;
        use_x_forwarded_for = true;
        trusted_proxies = [ "127.0.0.1" ];
      };
      homeassistant = {
        name = "Home";
        latitude = "!secret latitude";
        longitude = "!secret longitude";
        elevation = 0;
        unit_system = "metric";
        time_zone = vars.system.timezone;
      };
    };
  };
}


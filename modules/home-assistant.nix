{ config, pkgs, ... }:

let
  vars = import ../vars.nix;
in {
  services.home-assistant = {
    enable = true;
    openFirewall = false;
    configDir = "${vars.storage.shared}/home-assistant";
    
    config = {
      default_config = {};
      http = {
        server_host = "::";  # Listen on both IPv4 and IPv6
        server_port = 8123;
        use_x_forwarded_for = true;
        trusted_proxies = [ 
          "127.0.0.1"
          "::1"
          "::ffff:127.0.0.1"  # IPv4-mapped IPv6 address
        ];
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

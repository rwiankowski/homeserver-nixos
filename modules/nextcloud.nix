{ config, pkgs, ... }:

let
  vars = import ../vars.nix;
in {
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud31;
    hostName = "${vars.services.nextcloud}.${vars.networking.homeDomain}";
    datadir = "${vars.storage.docs}/nextcloud";
    
    config = {
      adminpassFile = "/etc/nextcloud-admin-pass";
      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbhost = "/run/postgresql";
      dbname = "nextcloud";
    };

    settings = {
      trusted_domains = [ "${vars.services.nextcloud}.${vars.networking.homeDomain}" ];
      trusted_proxies = [ "127.0.0.1" ];
      overwriteprotocol = "https";
    };

    https = true;
    enableImagemagick = true;
    
    phpOptions = {
      "opcache.interned_strings_buffer" = "16";
      "opcache.max_accelerated_files" = "10000";
      "opcache.memory_consumption" = "128";
      "opcache.revalidate_freq" = "1";
      "opcache.fast_shutdown" = "1";
    };
  };

    services.nginx = {
    enable = true;
    
    # Don't listen on port 80 - only localhost
    defaultHTTPListenPort = 8080;
    defaultListenAddresses = [ "127.0.0.1" ];
    
    # Disable the default virtual host
    virtualHosts = {
      "${vars.services.nextcloud}.${vars.networking.homeDomain}" = {
        listen = [
          { addr = "127.0.0.1"; port = 8080; }
        ];
      };
    };
  };

  system.activationScripts.nextcloud-admin-pass = ''
    if [ ! -f /etc/nextcloud-admin-pass ]; then
      echo "replace-with-secure-password" > /etc/nextcloud-admin-pass
      chmod 600 /etc/nextcloud-admin-pass
    fi
  '';
}


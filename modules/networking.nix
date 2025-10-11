{ config, pkgs, ... }:

let
  vars = import ../vars.nix;
  # Construct service URLs: service.home.yourdomain.com
  mkServiceUrl = service: "${service}.${vars.networking.homeDomain}";
in {
  networking = {
    networkmanager.enable = true;
    
    # Firewall configuration - NO ports exposed!
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];  # Only SSH
      trustedInterfaces = [ "tailscale0" ];
      checkReversePath = "loose";
    };
  };

  # Tailscale VPN
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
  };

  # Caddy with Let's Encrypt DNS-01 challenge via Azure DNS
  services.caddy = {
    enable = true;
    
    # Email for Let's Encrypt notifications
    email = vars.networking.acmeEmail;
    
    # Global Caddy configuration
    globalConfig = ''
      # Use DNS-01 challenge via Azure DNS
      acme_dns azure {
        tenant_id {env.AZURE_TENANT_ID}
        client_id {env.AZURE_CLIENT_ID}
        client_secret {env.AZURE_CLIENT_SECRET}
        subscription_id {env.AZURE_SUBSCRIPTION_ID}
        resource_group_name {env.AZURE_RESOURCE_GROUP}
      }
      
      servers {
        metrics
      }
    '';
    
    # Log format for CrowdSec parsing
    extraConfig = ''
      (crowdsec_logs) {
        log {
          output file /var/log/caddy/access.log
          format json
        }
      }
    '';
    
    virtualHosts = {
      "${mkServiceUrl vars.services.authentik}" = {
        extraConfig = ''
          reverse_proxy localhost:9000
          import crowdsec_logs
        '';
      };
      "${mkServiceUrl vars.services.jellyfin}" = {
        extraConfig = ''
          reverse_proxy localhost:8096
          import crowdsec_logs
        '';
      };
      "${mkServiceUrl vars.services.immich}" = {
        extraConfig = ''
          reverse_proxy localhost:2283
          import crowdsec_logs
        '';
      };
      "${mkServiceUrl vars.services.nextcloud}" = {
        extraConfig = ''
          reverse_proxy localhost:8080
          import crowdsec_logs
        '';
      };
      "${mkServiceUrl vars.services.mealie}" = {
        extraConfig = ''
          reverse_proxy localhost:9925
          import crowdsec_logs
        '';
      };
      "${mkServiceUrl vars.services.homeassistant}" = {
        extraConfig = ''
          reverse_proxy localhost:8123
          import crowdsec_logs
        '';
      };
      "${mkServiceUrl vars.services.llm}" = {
        extraConfig = ''
          reverse_proxy localhost:3000
          import crowdsec_logs
        '';
      };
      "${mkServiceUrl vars.services.sonarr}" = {
        extraConfig = ''
          reverse_proxy localhost:8989
          import crowdsec_logs
        '';
      };
      "${mkServiceUrl vars.services.radarr}" = {
        extraConfig = ''
          reverse_proxy localhost:7878
          import crowdsec_logs
        '';
      };
      "${mkServiceUrl vars.services.prowlarr}" = {
        extraConfig = ''
          reverse_proxy localhost:9696
          import crowdsec_logs
        '';
      };
      "${mkServiceUrl vars.services.bazarr}" = {
        extraConfig = ''
          reverse_proxy localhost:6767
          import crowdsec_logs
        '';
      };
      "${mkServiceUrl vars.services.paperless}" = {
        extraConfig = ''
          reverse_proxy localhost:28981
          import crowdsec_logs
        '';
      };
      "${mkServiceUrl vars.services.audiobookshelf}" = {
        extraConfig = ''
          reverse_proxy localhost:13378
          import crowdsec_logs
        '';
      };
      "${mkServiceUrl vars.services.homepage}" = {
        extraConfig = ''
          reverse_proxy localhost:3001
          import crowdsec_logs
        '';
      };
      "${mkServiceUrl vars.services.pgadmin}" = {
        extraConfig = ''
          reverse_proxy localhost:5050
          import crowdsec_logs
        '';
      };
      "${mkServiceUrl vars.services.grafana}" = {
        extraConfig = ''
          reverse_proxy localhost:3002
          import crowdsec_logs
        '';
      };
    };
  };

  # Environment for Caddy to access Azure credentials
  systemd.services.caddy.serviceConfig = {
    EnvironmentFile = pkgs.writeText "caddy-env" ''
      AZURE_TENANT_ID_FILE=${config.sops.secrets."azure/tenant_id".path}
      AZURE_CLIENT_ID_FILE=${config.sops.secrets."azure/client_id".path}
      AZURE_CLIENT_SECRET_FILE=${config.sops.secrets."azure/client_secret".path}
      AZURE_SUBSCRIPTION_ID_FILE=${config.sops.secrets."azure/subscription_id".path}
      AZURE_RESOURCE_GROUP_FILE=${config.sops.secrets."azure/resource_group".path}
    '';
  };

  services.resolved = {
    enable = true;
  };
  
  # Create log directory for Caddy
  systemd.tmpfiles.rules = [
    "d /var/log/caddy 0755 caddy caddy -"
  ];
}

{ config, pkgs, lib, ... }:

let
  vars = import ../vars.nix;
  mkServiceUrl = service: "${service}.${vars.networking.homeDomain}";
  
  # Caddy with plugins
  caddyPkg = pkgs.caddy.withPlugins {
    plugins = [ "github.com/caddy-dns/azure@v0.6.0" ];
    hash = "sha256-EBPD0qDOExQxaF3X+PY8NdZWhsgPdYnes8is7E2UV50=";
  };
  
  # Wrapper script that loads credentials and runs caddy
  caddyWithEnv = pkgs.writeShellScript "caddy-with-env" ''
    # Load credentials into environment
    export AZURE_TENANT_ID=$(cat $CREDENTIALS_DIRECTORY/azure_tenant_id)
    export AZURE_CLIENT_ID=$(cat $CREDENTIALS_DIRECTORY/azure_client_id)
    export AZURE_CLIENT_SECRET=$(cat $CREDENTIALS_DIRECTORY/azure_client_secret)
    export AZURE_SUBSCRIPTION_ID=$(cat $CREDENTIALS_DIRECTORY/azure_subscription_id)
    export AZURE_RESOURCE_GROUP=$(cat $CREDENTIALS_DIRECTORY/azure_resource_group)
    
    # Run caddy
    exec ${caddyPkg}/bin/caddy run --config /etc/caddy/caddy_config --adapter caddyfile
  '';
in {
  networking = {
    networkmanager.enable = true;
    
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      trustedInterfaces = [ 
        "tailscale0" 
        "docker0"
      ];
      checkReversePath = "loose";
    };
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
  };

  services.caddy = {
    enable = true;
    package = caddyPkg;
    
    email = vars.networking.acmeEmail;
    
    globalConfig = ''
      acme_dns azure {
        tenant_id {$AZURE_TENANT_ID}
        client_id {$AZURE_CLIENT_ID}
        client_secret {$AZURE_CLIENT_SECRET}
        subscription_id {$AZURE_SUBSCRIPTION_ID}
        resource_group_name {$AZURE_RESOURCE_GROUP}
      }
      
      servers {
        metrics
      }
    '';
    
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
      "${mkServiceUrl vars.services.readarr}" = {
        extraConfig = ''
          reverse_proxy localhost:8787
          import crowdsec_logs
        '';
      };
      "${mkServiceUrl vars.services.lidarr}" = {
        extraConfig = ''
          reverse_proxy localhost:8686
          import crowdsec_logs
        '';
      };
      "${mkServiceUrl vars.services.qbittorrent}" = {
        extraConfig = ''
          reverse_proxy localhost:8282
          import crowdsec_logs
        '';
      };
      "${mkServiceUrl vars.services.jellyseerr}" = {
        extraConfig = ''
          reverse_proxy localhost:5055
          import crowdsec_logs
        '';
      };
      "${mkServiceUrl vars.services.homarr}" = {
        extraConfig = ''
          reverse_proxy localhost:7575
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

  # Override systemd service to use wrapper and load credentials
  systemd.services.caddy.serviceConfig = {
    LoadCredential = [
      "azure_tenant_id:${config.sops.secrets."azure/tenant_id".path}"
      "azure_client_id:${config.sops.secrets."azure/client_id".path}"
      "azure_client_secret:${config.sops.secrets."azure/client_secret".path}"
      "azure_subscription_id:${config.sops.secrets."azure/subscription_id".path}"
      "azure_resource_group:${config.sops.secrets."azure/resource_group".path}"
    ];
    
    ExecStart = lib.mkForce [ "" caddyWithEnv ];
  };

  services.resolved = {
    enable = true;
  };
  
  systemd.tmpfiles.rules = [
    "d /var/log/caddy 0755 caddy caddy -"
  ];
}

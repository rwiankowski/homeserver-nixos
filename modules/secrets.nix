{ config, pkgs, ... }:

{
  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    
    age = {
      keyFile = "/var/lib/sops-nix/key.txt";
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };

    secrets = {
      # Database passwords
      "database/authentik_password" = {
        owner = "root";
        mode = "0400";
      };
      "database/immich_password" = {
        owner = "root";
        mode = "0400";
      };
      "database/paperless_password" = {
        owner = "root";
        mode = "0400";
      };
      
      # Application secrets
      "authentik/secret_key" = {
        owner = "root";
        mode = "0400";
      };
      "openwebui/secret_key" = {
        owner = "root";
        mode = "0400";
      };
      "nextcloud/admin_password" = {
        owner = "root";
        mode = "0400";
      };
      "paperless/admin_password" = {
        owner = "root";
        mode = "0400";
      };
      "pgadmin/admin_password" = {
        owner = "root";
        mode = "0400";
      };
      
      # Backup encryption
      "restic/password" = {
        owner = "root";
        mode = "0400";
      };
      "restic/repository" = {
        owner = "root";
        mode = "0400";
      };
      "restic/azure_account_name" = {
        owner = "root";
        mode = "0400";
      };
      "restic/azure_account_key" = {
        owner = "root";
        mode = "0400";
      };
      
      # CrowdSec
      "crowdsec/enroll_key" = {
        owner = "root";
        mode = "0400";
      };
      
      # Grafana
      "grafana/admin_password" = {
        owner = "root";
        mode = "0400";
      };
      
      # Azure credentials for DNS-01 challenge
      "azure/tenant_id" = {
        owner = "caddy";
        mode = "0400";
      };
      "azure/client_id" = {
        owner = "caddy";
        mode = "0400";
      };
      "azure/client_secret" = {
        owner = "caddy";
        mode = "0400";
      };
      "azure/subscription_id" = {
        owner = "caddy";
        mode = "0400";
      };
      "azure/resource_group" = {
        owner = "caddy";
        mode = "0400";
      };
    };
  };
}


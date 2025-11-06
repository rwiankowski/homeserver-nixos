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
      "mealie/oidc_client_id" = {
    	owner = "root";
    	mode = "0400";
      };
      "mealie/oidc_client_secret" = {
    	owner = "root";
    	mode = "0400";
      };
      "homarr/secret_key" = {
        owner = "root";
        mode = "0400";
      };
    };
    
     # Templates for environment files
    templates = {
      "authentik-env" = {
        content = ''
          AUTHENTIK_ERROR_REPORTING__ENABLED=false
          AUTHENTIK_POSTGRESQL__HOST=host.docker.internal
          AUTHENTIK_POSTGRESQL__NAME=authentik
          AUTHENTIK_POSTGRESQL__USER=authentik
          AUTHENTIK_REDIS__HOST=host.docker.internal
          AUTHENTIK_SECRET_KEY=${config.sops.placeholder."authentik/secret_key"}
          AUTHENTIK_POSTGRESQL__PASSWORD=${config.sops.placeholder."database/authentik_password"}
        '';
        owner = "root";
        mode = "0400";
      };

      "immich-env" = {
        content = ''
          DB_HOSTNAME=127.0.0.1
          DB_USERNAME=immich
          DB_DATABASE_NAME=immich
          REDIS_HOSTNAME=127.0.0.1
          DB_PASSWORD=${config.sops.placeholder."database/immich_password"}
        '';
        owner = "root";
        mode = "0400";
      };

      "openwebui-env" = {
        content = ''
          OLLAMA_BASE_URL=http://host.docker.internal:11434
          ENABLE_RAG_WEB_SEARCH=true
          RAG_WEB_SEARCH_ENGINE=searxng
          SEARXNG_QUERY_URL=http://host.docker.internal:8888/search?q=<query>
          WEBUI_SECRET_KEY=${config.sops.placeholder."openwebui/secret_key"}
        '';
        owner = "root";
        mode = "0400";
      };

      "restic-env" = {
        content = ''
          AZURE_ACCOUNT_NAME=${config.sops.placeholder."restic/azure_account_name"}
          AZURE_ACCOUNT_KEY=${config.sops.placeholder."restic/azure_account_key"}
        '';
        owner = "root";
        mode = "0400";
      };

      "homarr-env" = {
        content = ''
          SECRET_ENCRYPTION_KEY=${config.sops.placeholder."homarr/secret_key"}
        '';
        owner = "root";
        mode = "0400";
      };
    };
  };
}


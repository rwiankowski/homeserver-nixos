{ config, pkgs, ... }:

let
  vars = import ../vars.nix;
in {
  # Centralized PostgreSQL instance for all services
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    
    # Store database on shared disk
    dataDir = "${vars.storage.shared}/postgresql/16";
    
    # Enable extensions
    enableTCPIP = true;
    
    settings = {
      max_connections = 200;
      shared_buffers = "256MB";
      effective_cache_size = "1GB";
      maintenance_work_mem = "64MB";
      checkpoint_completion_target = 0.9;
      wal_buffers = "16MB";
      default_statistics_target = 100;
      random_page_cost = 1.1;
      effective_io_concurrency = 200;
      work_mem = "2621kB";
      min_wal_size = "1GB";
      max_wal_size = "4GB";
    };

    # Create databases and users for all services
    ensureDatabases = [
      "authentik"
      "immich"
      "nextcloud"
      "paperless"
    ];

    ensureUsers = [
      {
        name = "authentik";
        ensureDBOwnership = true;
      }
      {
        name = "immich";
        ensureDBOwnership = true;
      }
      {
        name = "nextcloud";
        ensureDBOwnership = true;
      }
      {
        name = "paperless";
        ensureDBOwnership = true;
      }
    ];

    authentication = pkgs.lib.mkOverride 10 ''
      # Allow local connections
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
      # Allow Docker network
      host all all 172.17.0.0/16 md5
    '';
  };

  # pgAdmin for database management
  services.pgadmin = {
    enable = true;
    initialEmail = "admin@${vars.networking.domain}";
    initialPasswordFile = "/etc/pgadmin-password";
    
    settings = {
      PGADMIN_LISTEN_ADDRESS = "127.0.0.1";
      PGADMIN_LISTEN_PORT = 5050;
    };
  };

  # Create password file for pgAdmin
  system.activationScripts.pgadmin-pass = ''
    if [ ! -f /etc/pgadmin-password ]; then
      echo "replace-with-secure-password" > /etc/pgadmin-password
      chmod 600 /etc/pgadmin-password
    fi
  '';

  # Redis for caching (shared by multiple services)
  services.redis.servers.shared = {
    enable = true;
    port = 6379;
    bind = "127.0.0.1";
  };
}


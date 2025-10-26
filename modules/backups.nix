{ config, pkgs, ... }:

let
  vars = import ../vars.nix;
in {
  services.restic.backups = {
    homeserver = {
      initialize = true;
      repositoryFile = config.sops.secrets."restic/repository".path;
      passwordFile = config.sops.secrets."restic/password".path;
      environmentFile = config.sops.templates."restic-env".path;
      
      paths = [
        vars.storage.photos
        vars.storage.docs
        "${vars.storage.shared}/authentik"
        "${vars.storage.shared}/mealie"
        "${vars.storage.shared}/home-assistant"
        "${vars.storage.shared}/open-webui"
        "${vars.storage.shared}/audiobookshelf"
        "${vars.storage.shared}/homepage"
        "${vars.storage.shared}/postgresql"
      ];
      
      exclude = [
        # Immich thumbnails (regenerated automatically)
        "${vars.storage.photos}/immich/library/thumbs"
        "${vars.storage.photos}/immich/thumbs"
        # Incomplete downloads
        "${vars.storage.media}/downloads/.incomplete"
        # Temporary files
        "**/.tmp"
        "**/cache"
        "**/temp"
        "**/*.tmp"
        # Media (not backed up - can be re-downloaded)
        "${vars.storage.media}/jellyfin"
        "${vars.storage.media}/downloads"
        "${vars.storage.media}/audiobooks"
        "${vars.storage.media}/podcasts"
        # Sonarr/Radarr cover art (regenerated)
        "${vars.storage.shared}/sonarr/MediaCover"
        "${vars.storage.shared}/radarr/MediaCover"
      ];
      
      timerConfig = {
        OnCalendar = "02:00";  # Daily at 2 AM
        Persistent = true;
        RandomizedDelaySec = "30m";  # Random delay up to 30 minutes
      };
      
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
        "--keep-yearly 2"
      ];
      
      # Backup verification
      checkOpts = [
        "--read-data-subset=5%"  # Check 5% of data each run
      ];
      
      # Run check monthly
      backupPrepareCommand = ''
        # Check if it's the first day of the month
        if [ $(date +%d) = "01" ]; then
          echo "Running monthly repository check..."
          ${pkgs.restic}/bin/restic check --read-data-subset=10%
        fi
      '';
    };
  };

  # Create backup notification service (optional)
  systemd.services."restic-backup-notify" = {
    description = "Notify on backup completion";
    after = [ "restic-backups-homeserver.service" ];
    
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "backup-notify" ''
        STATUS=$(systemctl is-active restic-backups-homeserver.service)
        if [ "$STATUS" = "active" ]; then
          echo "Backup completed successfully"
          # Add notification here (e.g., ntfy, email, etc.)
        else
          echo "Backup failed!"
          # Add failure notification here
        fi
      '';
    };
  };
}

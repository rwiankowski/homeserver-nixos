{ config, pkgs, ... }:

let
  vars = import ../vars.nix;
in {
  services.restic.backups = {
    homeserver = {
      initialize = true;
      repository = "${vars.storage.shared}/backups/restic";
      passwordFile = "/etc/restic-password";
      
      paths = [
        vars.storage.media
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
        "${vars.storage.photos}/immich/library/thumbs"
        "${vars.storage.media}/downloads/.incomplete"
        "**/.tmp"
        "**/cache"
        "**/temp"
      ];
      
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
      
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
        "--keep-yearly 2"
      ];
    };
  };

  system.activationScripts.restic-pass = ''
    if [ ! -f /etc/restic-password ]; then
      echo "replace-with-secure-password" > /etc/restic-password
      chmod 600 /etc/restic-password
    fi
  '';
}

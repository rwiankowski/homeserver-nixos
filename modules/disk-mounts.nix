{ config, pkgs, ... }:

let
  vars = import ../vars.nix;
in {
  # Define mount points for additional disks
  # You'll need to update hardware-configuration.nix with actual disk UUIDs
  
  fileSystems."${vars.storage.media}" = {
    device = "/dev/disk/by-label/media";
    fsType = "ext4";
    options = [ "defaults" "nofail" ];
  };

  fileSystems."${vars.storage.photos}" = {
    device = "/dev/disk/by-label/photos";
    fsType = "ext4";
    options = [ "defaults" "nofail" ];
  };

  fileSystems."${vars.storage.docs}" = {
    device = "/dev/disk/by-label/docs";
    fsType = "ext4";
    options = [ "defaults" "nofail" ];
  };

  fileSystems."${vars.storage.shared}" = {
    device = "/dev/disk/by-label/shared";
    fsType = "ext4";
    options = [ "defaults" "nofail" ];
  };

  # Create directory structure on each disk
  systemd.tmpfiles.rules = [
    # Media disk (HDD)
    "d ${vars.storage.media}/jellyfin 0755 media media -"
    "d ${vars.storage.media}/jellyfin/movies 0775 media media -"
    "d ${vars.storage.media}/jellyfin/tv 0775 media media -"
    "d ${vars.storage.media}/jellyfin/music 0775 media media -"
    "d ${vars.storage.media}/audiobooks 0775 1000 1000 -"
    "d ${vars.storage.media}/podcasts 0775 1000 1000 -"
    "d ${vars.storage.media}/downloads 0775 media media -"
    "d ${vars.storage.media}/downloads/.incomplete 0775 media media -"     
    
    # Photos disk (SSD)
    "d ${vars.storage.photos}/immich 0755 root root -"
    "d ${vars.storage.photos}/immich/upload 0755 root root -"
    "d ${vars.storage.photos}/immich/library 0755 root root -"
    
    # Docs disk (SSD)
    "d ${vars.storage.docs}/nextcloud 0755 nextcloud nextcloud -"
    "d ${vars.storage.docs}/nextcloud/config 0755 nextcloud nextcloud -"
    "d ${vars.storage.docs}/paperless 0755 paperless paperless -"
    "d ${vars.storage.docs}/paperless/log 0755 paperless paperless -"
    "d ${vars.storage.docs}/paperless/consume 0755 paperless paperless -"
    "d ${vars.storage.docs}/paperless/media 0755 paperless paperless -"
    "d ${vars.storage.docs}/paperless/export 0755 paperless paperless -"
    
    # Shared disk
    "d ${vars.storage.shared}/backups 0700 root root -"
    "d ${vars.storage.shared}/postgresql 0755 postgres postgres -" 
    "d ${vars.storage.shared}/postgresql/16 0755 postgres postgres -"
    "d ${vars.storage.shared}/authentik/media 0755 1000 1000 -"
    "d ${vars.storage.shared}/mealie 0755 root root -"
    "d ${vars.storage.shared}/home-assistant 0755 root root -"
    "d ${vars.storage.shared}/open-webui 0755 root root -"
    "d ${vars.storage.shared}/homepage 0755 root root -"
    "d ${vars.storage.shared}/audiobookshelf 0755 1000 1000 -"
  ];
}

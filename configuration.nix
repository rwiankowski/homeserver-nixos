{ config, pkgs, pkgs-unstable, ... }:

let
  vars = import ./vars.nix;
in {
  imports = [
    ./hardware-configuration.nix
    ./modules/disk-mounts.nix
    ./modules/networking.nix
    ./modules/security.nix
#    ./modules/crowdsec.nix
    ./modules/database.nix
    ./modules/authentik.nix
    ./modules/jellyfin.nix
    ./modules/arr-stack.nix
    ./modules/immich.nix
    ./modules/nextcloud.nix
    ./modules/mealie.nix
    ./modules/home-assistant.nix
    ./modules/llm-assistant.nix
    ./modules/paperless.nix
    ./modules/audiobookshelf.nix
    ./modules/homepage.nix
    ./modules/backups.nix
    ./modules/secrets.nix
  ];

  # System basics
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Time zone and locale from vars
  time.timeZone = vars.system.timezone;
  i18n.defaultLocale = vars.system.locale;

  # Hostname from vars
  networking.hostName = vars.system.hostname;

  # Enable automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Auto-upgrade system
  system.autoUpgrade = {
    enable = true;
    flake = "github:rwiankowski/homeserver-nixos#homeserver";
    flags = [ "--update-input" "nixpkgs" "--commit-lock-file" ];
    dates = "weekly";
  };

  # User configuration from vars
  users.users.${vars.users.admin.username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = vars.users.admin.sshKeys;
  };

  # Basic packages
  environment.systemPackages = with pkgs; [
    neovim
    git
    htop
    curl
    wget
    rsync
    ncdu
  ];

  system.stateVersion = "25.05";
}


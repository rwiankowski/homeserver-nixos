{ config, pkgs, lib, ... }:

let
  vars = import ../vars.nix;
in {
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
    openFirewall = true;
  };

  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = [
      "127.0.0.1/8"
      "100.64.0.0/10"  # Tailscale CGNAT range
      "192.168.0.0/16" # Private network range
      "10.0.0.0/8"     # Private network range
      "172.16.0.0/12"  # Private network range
    ];
  };

  # Firewall configuration for local network access
  networking.firewall = lib.mkIf vars.networking.enableLocalAccess {
    interfaces."${vars.networking.lanInterface}" = {
      allowedTCPPorts = [ 
        80   # HTTP (redirects to HTTPS)
        443  # HTTPS
        5353 # mDNS
      ];
      allowedUDPPorts = [
        5353 # mDNS
      ];
    };
  };

  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
  };

  security.apparmor.enable = true;

  services.journald.extraConfig = ''
    SystemMaxUse=500M
    MaxRetentionSec=7day
  '';
}

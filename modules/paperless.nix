{ config, pkgs, ... }:

let
  vars = import ../vars.nix;
in {
  services.paperless = {
    enable = true;
    address = "127.0.0.1";
    port = 28981;
    
    dataDir = "${vars.storage.docs}/paperless";
    mediaDir = "${vars.storage.docs}/paperless/media";
    consumptionDir = "${vars.storage.docs}/paperless/consume";
    
    settings = {
      PAPERLESS_OCR_LANGUAGE = "eng";
      PAPERLESS_TIME_ZONE = vars.system.timezone;
      PAPERLESS_ADMIN_USER = vars.users.admin.username;
      PAPERLESS_DBHOST = "/run/postgresql";
      PAPERLESS_DBNAME = "paperless";
      PAPERLESS_DBUSER = "paperless";
      PAPERLESS_URL = "https://${vars.services.paperless}.${vars.networking.homeDomain}";
    };

    passwordFile = config.sops.secrets."paperless/admin_password".path;
  };
}

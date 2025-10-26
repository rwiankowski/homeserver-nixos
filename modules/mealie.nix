{ config, pkgs, lib, ... }:

let
  vars = import ../vars.nix;
  authentikUrl = "${vars.services.authentik}.${vars.networking.homeDomain}";
  mealieUrl = "${vars.services.mealie}.${vars.networking.homeDomain}";
in {
  systemd.services.docker-mealie.preStart = lib.mkBefore ''
    echo "OIDC_CLIENT_ID=$(cat ${config.sops.secrets."mealie/oidc_client_id".path})" > /run/mealie-secrets.env
    echo "OIDC_CLIENT_SECRET=$(cat ${config.sops.secrets."mealie/oidc_client_secret".path})" >> /run/mealie-secrets.env
    chmod 644 /run/mealie-secrets.env
  '';

  virtualisation.oci-containers.containers.mealie = {
    image = "ghcr.io/mealie-recipes/mealie:v3.3.2";
    environment = {
      ALLOW_SIGNUP = "false";
      PUID = "1000";
      PGID = "1000";
      TZ = vars.system.timezone;
      MAX_WORKERS = "1";
      WEB_CONCURRENCY = "1";
      BASE_URL = "https://${vars.services.mealie}.${vars.networking.homeDomain}";

      # OIDC Configuration
      OIDC_AUTH_ENABLED = "true";
      OIDC_SIGNUP_ENABLED = "true";
      OIDC_USER_GROUP = "Family";  # Default group for OIDC users
      OIDC_ADMIN_GROUP = "Admins";  # Group that gets admin privileges
      OIDC_AUTO_REDIRECT = "false";  # Set to "true" to skip login page
      OIDC_PROVIDER_NAME = "authentik";
      OIDC_CONFIGURATION_URL = "https://${vars.services.authentik}.${vars.networking.homeDomain}/application/o/mealie/.well-known/openid-configuration";
    };
   
    # Use extraOptions to pass --env-file
    extraOptions = [
      "--add-host=${authentikUrl}:172.17.0.1"  # Docker bridge gateway
      "--add-host=${mealieUrl}:172.17.0.1"  # In case Mealie needs to reach itself
      "--env-file=/run/mealie-secrets.env"
    ];

    ports = [ "9925:9000" ];
    volumes = [ "${vars.storage.shared}/mealie:/app/data" ];
  };
}


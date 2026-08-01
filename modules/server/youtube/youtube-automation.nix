{ pkgs, ... }:

let
  pythonEnv = pkgs.python3.withPackages (ps: with ps; [
    google-api-python-client
    google-auth-httplib2
    google-auth-oauthlib
    requests
  ]);
  workDir = "/var/lib/nixos-config/modules/server/youtube";
in
{
  users.users.youtube-sync = {
    isSystemUser = true;
    group = "youtube-sync";
    home = workDir;
    createHome = true;
  };
  users.groups.youtube-sync = {};

  systemd.services.youtube-playlist-sync = {
    description = "Sync YouTube subscriptions uploads from last 24 hours into playlist";
    serviceConfig = {
      Type = "oneshot";
      User = "youtube-sync";
      Group = "youtube-sync";
      WorkingDirectory = workDir;
      ExecStart = "${pythonEnv}/bin/python3 ${workDir}/sync_playlist.py --config ${workDir}/config.json";

      # Hardening
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ workDir ];
      NoNewPrivileges = true;
      PrivateTmp = true;
    };
  };

  systemd.timers.youtube-playlist-sync = {
    description = "Run youtube-playlist-sync periodically";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      # Every 15 minutes; adjust to taste (e.g. "hourly").
      OnBootSec = "5m";
      OnUnitActiveSec = "15m";
      Persistent = true;
    };
  };
}

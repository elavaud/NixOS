
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    autossh
    procps
  ];

  # sudo -u tunnel ssh-keygen -a 100 -t ed25519 -N "" -C "$(whoami)@${HOSTNAME}" -f ${HOME}/id_${HOSTNAME}

  users.extraUsers.tunnel = {
    isSystemUser = true;
    createHome = true;
    home = "/var/tunnel";
  };

  environment.etc.id_tunnel = {
    source = ./local/id_tunnel;
    mode = "0400";
    user = "tunnel";
    group = "tunnel";
  };

  systemd.services = let
    inherit (lib.lists) foldl;
    reverse_tunnel_config = [ { name = "autossh-reverse-tunnel-google";  host = "msfrelay1.msfict.info"; }
                              { name = "autossh-reverse-tunnel-ixelles"; host = "194.78.17.132"; } ];
    make_service = conf: {
      "${conf.name}" = {
        enable = true;
        description = "AutoSSH reverse tunnel service to ensure resilient ssh access";
        after = [ "NetworkManager-wait-online.service"
                  "network.target"
                  "network-online.target"
                  "dbus.service"
        ];
        wantedBy = [ "multi-user.target" ];
        wants = [ "NetworkManager-wait-online.service" "network-online.target" ];
        environment = {
          AUTOSSH_GATETIME = "0";
          AUTOSSH_PORT = "0";
        };
        serviceConfig = {
          User = "tunnel";
          Restart = "always";
          RestartSec = 10;
          ExecStart = let
            remote_host = conf.host;
            remote_forward_port = (import ./settings.nix).reverse_tunnel_forward_port;
          in ''${pkgs.autossh}/bin/autossh \
                 -q -N \
                 -o "ExitOnForwardFailure=yes" \
                 -o "ServerAliveInterval=60" \
                 -o "ServerAliveCountMax=3" \
                 -o "ConnectTimeout=30" \
                 -o "UpdateHostKeys=yes" \
                 -o "StrictHostKeyChecking=no" \
                 -o "IdentitiesOnly=yes" \
                 -o "Compression=yes" \
                 -o "ControlMaster=no" \
                 -R ${remote_forward_port}:localhost:22 \
                 -i /etc/id_tunnel \
                 tunnel@${remote_host}
             '';
        };
      };
    };
  in
    foldl (services: conf: services // (make_service conf)) {} reverse_tunnel_config;

}



########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{
  networking.hostName = "benuc002";
  time.timeZone = "Europe/Brussels";

  settings = {
    boot.mode = "uefi";
    reverse_tunnel = {
      enable = true;
      remote_forward_port = 6002;
    };
    crypto = {
      enable = false;
      device = "/safe.img";
    };
  };

  imports = [
  ];

}


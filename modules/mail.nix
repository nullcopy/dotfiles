{
  config,
  lib,
  pkgs,
  ...
}:

# aerc, imported by ../profiles/desktop.nix. The mail password never
# touches this repo or the Nix store: aerc asks the GNOME keyring for
# it at connect time, through the source-cred-cmd / outgoing-cred-cmd
# that home-manager derives from passwordCommand. nixos-core's
# core.desktop.enable runs the keyring and unlocks it at greetd login,
# which is why this is desktop-only; a headless machine has no keyring
# to ask.
#
# Store the password once per machine, before the first aerc start:
#
#   secret-tool store --label='aerc john@coldnoise.net' email john@coldnoise.net
#
# The attributes after `store` must match the lookup below.
let
  address = config.programs.git.settings.user.email;
  secret-tool = lib.getExe' pkgs.libsecret "secret-tool";
in
{
  # secret-tool on PATH, for the one-time `store` above.
  home.packages = [ pkgs.libsecret ];

  programs.aerc = {
    enable = true;
    # home-manager writes accounts.conf into the store (0444); aerc
    # refuses to start unless told that is fine. It is: the file holds
    # no secret, only the command that fetches one.
    extraConfig.general.unsafe-accounts-conf = true;
  };

  accounts.email.accounts.coldnoise = {
    primary = true;
    address = address;
    userName = address;
    realName = config.programs.git.settings.user.name;

    # Forward Email hosts the domain's MX; IMAPS and SMTPS on the
    # default ports (993, 465).
    imap.host = "imap.forwardemail.net";
    smtp.host = "smtp.forwardemail.net";

    passwordCommand = "${secret-tool} lookup email ${address}";

    # copy-to / postpone take the home-manager defaults (Sent, Drafts).
    # If the server names them differently, set folders.sent and
    # folders.drafts here.

    aerc.enable = true;
  };
}

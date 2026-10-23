{
  config,
  lib,
  pkgs,
  ...
}:

# aerc on every machine; the account only where it can get its
# password. The password never touches this repo or the Nix store:
# aerc asks the GNOME keyring for it at connect time, through the
# source-cred-cmd / outgoing-cred-cmd that home-manager derives from
# passwordCommand. A machine says it has that keyring with my.keyring
# (../profiles/desktop.nix does: nixos-core's core.desktop.enable runs
# it and unlocks it at greetd login). Elsewhere aerc is installed with
# no account, and nothing asks a keyring that is not there.
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
  options.my.keyring = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Whether this user's session has a secret service (the GNOME
      keyring), unlocked at login. Config that keeps a secret there is
      applied only when this is true.
    '';
  };

  config = lib.mkMerge [
    { programs.aerc.enable = true; }

    (lib.mkIf config.my.keyring {
      # secret-tool on PATH, for the one-time `store` above.
      home.packages = [ pkgs.libsecret ];

      # home-manager writes accounts.conf into the store (0444); aerc
      # refuses to start unless told that is fine. It is: the file
      # holds no secret, only the command that fetches one.
      programs.aerc.extraConfig.general.unsafe-accounts-conf = true;

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

        # copy-to / postpone take the home-manager defaults (Sent,
        # Drafts). If the server names them differently, set
        # folders.sent and folders.drafts here.

        aerc.enable = true;
      };
    })
  ];
}

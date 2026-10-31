{
  pkgs,
  ...
}:

# aerc, imported by ../profiles/desktop.nix. The flake owns the client
# and its public settings; the account does not live here at all.
# ~/.config/aerc/accounts.conf is written once per machine — by aerc's
# wizard, with its embedded password swapped for the two cred-cmds
# that fetch it from the GNOME keyring, or straight from the template
# in the README's Mail section — and never enters this repo or the
# Nix store, the same deal as ~/.config/git/local for commit signing.
# Declaring no accounts keeps home-manager from generating
# accounts.conf, and a 0600 local file passes aerc's permission check
# without unsafe-accounts-conf.
#
# Desktop only: those cred-cmds ask the GNOME keyring, which a
# headless machine has no secret service to answer.
{
  # secret-tool on PATH, for the cred-cmds and the one-time store.
  home.packages = [ pkgs.libsecret ];

  programs.aerc.enable = true;
}

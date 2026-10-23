# headless plus niri, noctalia, alacritty and GUI apps, on a machine
# that runs nixos-core's core.desktop.enable.
{
  imports = [
    ./headless.nix
    ../modules/desktop.nix
    ../modules/niri.nix
  ];

  # core.desktop.enable runs the GNOME keyring and unlocks it at login;
  # modules/mail.nix keeps the mail password there.
  my.keyring = true;
}

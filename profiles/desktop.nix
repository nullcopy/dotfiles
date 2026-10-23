# headless plus niri, noctalia, alacritty, GUI apps and mail, on a machine
# that runs nixos-core's core.desktop.enable.
{
  imports = [
    ./headless.nix
    ../modules/desktop.nix
    ../modules/niri.nix
    ../modules/mail.nix
  ];
}

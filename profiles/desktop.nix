# headless plus niri, noctalia, alacritty and GUI apps, on a machine
# that runs nixos-core's core.desktop.enable.
{
  imports = [
    ./headless.nix
    ../modules/desktop.nix
    ../modules/niri.nix
  ];
}

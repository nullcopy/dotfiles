# aurora, a desktop. What this machine alone gets goes beside the type.
{ config, ... }:
{
  imports = [ ../profiles/desktop.nix ];

  my.noctalia.wallpaper = "${config.home.homeDirectory}/Pictures/Wallpapers/tokyo-alley-at-night.jpg";

  programs.git.settings.user.signingkey = "781C65EEE6ACD2BB7E0DB7691A6E2D470A6F6535";
}

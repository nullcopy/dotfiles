# kestrel desktop
{ config, ... }:
{
  imports = [ ../profiles/desktop.nix ];

  my.noctalia.wallpaper = "${config.home.homeDirectory}/Pictures/Wallpapers/kestrel-perched.jpg";

  programs.git.settings.user.signingkey = "781C65EEE6ACD2BB7E0DB7691A6E2D470A6F6535";
}

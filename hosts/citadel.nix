# citadel, a headless server. What this machine alone gets goes beside
# the type.
{ pkgs, ... }:
{
  imports = [ ../profiles/headless.nix ];

  home.packages = with pkgs; [ ];
}

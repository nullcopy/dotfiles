# obelisk, a headless server. What this machine alone gets goes beside
# the type.
{ pkgs, ... }:
{
  imports = [ ../profiles/headless.nix ];

  nixpkgs.config.allowUnfree = true;
  home.packages = with pkgs; [
    claude-code
    gh
  ];
}

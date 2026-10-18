{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

# nullcopy's home environment, applied with standalone home-manager:
# what every machine gets. ../profiles/headless.nix imports this
# directory; ../profiles/desktop.nix adds ./desktop.nix and ./niri.nix.
# The `my.*` options are what a machine's module in ../hosts can set.
{
  imports = [
    inputs.nixvim.homeModules.nixvim
    inputs.gwt.homeModules.default
    ./zsh.nix
    ./aliases.nix
    ./devshell.nix
    ./git.nix
    ./neovim.nix
    ./opencode.nix
    ./updates.nix
  ];

  options.my = {
    entry = lib.mkOption {
      type = lib.types.str;
      description = "Name of this home's homeConfigurations entry, set by ../flake.nix.";
    };

    repoPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.dotfiles";
      description = ''
        Absolute path to this repo's checkout on this machine. Apps that
        rewrite their own config files (noctalia) get an out-of-store symlink
        into this checkout, so in-app changes land as unstaged git diffs here
        — commit them to persist.
      '';
    };
  };

  config = {
    home.username = lib.mkDefault "nullcopy";
    home.homeDirectory = lib.mkDefault "/home/nullcopy";
    home.stateVersion = "25.11";

    # Let home-manager manage itself, so the `home-manager` CLI stays
    # available after the first `nix run home-manager -- switch`.
    programs.home-manager.enable = true;

    ## ----- packages ------------------------------------------------------------
    # CLI-only here; GUI packages live in desktop.nix.
    home.packages = with pkgs; [
      fzf
      tldr
      ripgrep
      rage
    ];

    ## ----- nix -----------------------------------------------------------------
    # A user-level collector, because NixOS' own nix.gc timer runs as root:
    # it prunes /nix/var/nix/profiles and never looks in
    # ~/.local/state/nix/profiles, where the home-manager profile and the
    # devshell profiles created by `devshell` live. --delete-older-than keeps
    # the current generation and the newest one past the cutoff, so a
    # rollback to 30 days ago stays possible; everything older is collected.
    # This pulls in pkgs.nix for the unit's ExecStart, which may differ from
    # the system nix on NixOS.
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}

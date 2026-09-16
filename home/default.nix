{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

# nullcopy's home environment, applied with standalone home-manager.
# Per-machine knobs are the `my.*` options, set per entry in ../flake.nix.
{
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./aliases.nix
    ./neovim.nix
    ./opencode.nix
    ./niri.nix
    ./desktop.nix
  ];

  ## ----- per-machine options ---------------------------------------------------
  options.my = {
    desktop.enable = lib.mkEnableOption "graphical desktop config (niri, noctalia, alacritty, GUI apps)";

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

  # NOTE: because this module declares `options`, everything else must sit
  # under `config` (a module can't mix top-level settings with options).
  config = {
    home.username = lib.mkDefault "nullcopy";
    home.homeDirectory = lib.mkDefault "/home/nullcopy";

    # Let home-manager manage itself, so the `home-manager` CLI stays
    # available after the first `nix run home-manager -- switch`.
    programs.home-manager.enable = true;

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

    ## ----- packages ------------------------------------------------------------
    # CLI-only here; GUI packages live in desktop.nix.
    home.packages = with pkgs; [
      fzf
      tldr
      ripgrep
      rage
    ];

    ## ----- programs ------------------------------------------------------------
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      initContent = ''
        export PATH="$HOME/.cargo/bin:$PATH"

        ## --- devShell helper ---------------------------------------------
        # Enter a fallback shell from this flake through a profile, because a
        # profile is a GC root and a bare `nix develop` is not: nothing roots
        # the toolchain, so the collector deletes it and the next entry pulls
        # the whole closure down again. The profile sits under the per-user
        # profile dir that nix-collect-garbage scans, so the `nix.gc` timer
        # prunes its old generations too.
        devshell () {
          if [ $# -ne 1 ]; then
            echo "usage: devshell <name>" >&2
            echo "available: $(ls ${config.my.repoPath}/devShells | sed 's/\.nix$//' | tr '\n' ' ')" >&2
            return 2
          fi
          local dir=''${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/devshells
          mkdir -p "$dir" || return
          nix develop --profile "$dir/$1" "${config.my.repoPath}#$1"
        }
      '';
      history = {
        path = "${config.home.homeDirectory}/.zsh_history";
        size = 100000;
        save = 100000;
        share = true;
        extended = true;
        ignoreDups = true;
        ignoreSpace = true;
      };
      historySubstringSearch = {
        enable = true;
        # Bind both cursor-mode (^[[A) and application-mode (^[OA) escapes:
        searchUpKey = [
          "^[[A"
          "^[OA"
        ]; # Up arrow
        searchDownKey = [
          "^[[B"
          "^[OB"
        ]; # Down arrow
      };
    };

    programs.starship = {
      enable = true;
      presets = [ "gruvbox-rainbow" ];
    };

    programs.gpg.enable = true;

    programs.git = {
      enable = true;
      settings = {
        user = {
          name = "nullcopy";
          email = "john@coldnoise.net";
        };
        core.editor = "vim";
        commit.gpgsign = true;
        tag.gpgsign = true;
      };
    };
  };
}

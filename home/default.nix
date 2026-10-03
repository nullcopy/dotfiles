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
    inputs.gwt.homeModules.default
    ./aliases.nix
    ./neovim.nix
    ./opencode.nix
    ./niri.nix
    ./desktop.nix
    ./updates.nix
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

    ## ----- session -------------------------------------------------------------
    home.sessionVariables = {
      COLORTERM = "truecolor";
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
      defaultKeymap = "viins";
      initContent = ''
        ## --- devShell helper ---------------------------------------------
        # Enter a fallback shell from this flake through a profile, because a
        # profile is a GC root and a bare `nix develop` is not: nothing roots
        # the toolchain, so the collector deletes it and the next entry pulls
        # the whole closure down again. The profile sits under the per-user
        # profile dir that nix-collect-garbage scans, so the `nix.gc` timer
        # prunes its old generations too.
        #
        # --offline is handed to nix. It is not the default because it turns
        # substituters off, so an entry after a flake.lock bump would build
        # the toolchain from source. nix disables the network by itself
        # only when no interface holds an address, which any virtual
        # interface that stays up defeats.
        devshell () {
          local -a nixflags
          local name help
          while [ $# -gt 0 ]; do
            case $1 in
              -h|--help) help=1 ;;
              --offline) nixflags+=(--offline) ;;
              -*)
                echo "devshell: unknown option $1" >&2
                return 2
                ;;
              *)
                if [ -n "$name" ]; then
                  echo "devshell: expected one shell name" >&2
                  return 2
                fi
                name=$1
                ;;
            esac
            shift
          done
          if [ -n "$help" ] || [ -z "$name" ]; then
            # Help on stdout when asked for, on stderr for a missing name.
            local fd=2
            [ -n "$help" ] && fd=1
            cat >&$fd <<EOF
        usage: devshell [--offline] <name>

        Enter the <name> shell of ${config.my.repoPath}
        through a profile that roots its closure, so the toolchain survives
        garbage collection.

        options:
          --offline   Hand --offline to nix: no substituters, no downloads.
                      Enough for a shell entered online since the last
                      flake.lock bump. A new toolchain needs the network.
          -h, --help  Show this help.

        shells: $(ls ${config.my.repoPath}/devShells | sed 's/\.nix$//' | tr '\n' ' ')
        EOF
            [ -n "$help" ] && return 0
            return 2
          fi
          # The profile below roots the shell's closure, but not the source
          # trees the flake is evaluated from, and a checkout with
          # uncommitted changes gets no eval cache to skip that evaluation.
          # devshell-inputs links those trees and the out-link roots them.
          # It stays out of the profiles dir, where nix-collect-garbage
          # would take it for a profile.
          local roots=''${XDG_STATE_HOME:-$HOME/.local/state}/nix/gcroots
          mkdir -p "$roots" || return
          nix build "''${nixflags[@]}" --out-link "$roots/devshell-inputs" \
            "${config.my.repoPath}#devshell-inputs"

          local dir=''${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/devshells
          mkdir -p "$dir" || return
          nix develop "''${nixflags[@]}" --profile "$dir/$name" "${config.my.repoPath}#$name"
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
      presets = [ "pure-preset" ];

      # Merged over the preset, not alongside it: these win.
      settings = {
        # pure-preset's own format with ${custom.worktree} spliced in ahead
        # of $directory. Setting `format` replaces the preset's outright, so
        # keep this in step with pure-preset.toml by hand.
        format = "$username$hostname\${custom.worktree}$directory$git_branch$git_state$git_status$cmd_duration$line_break$python$character";

        # $directory trims to the repo root, which in a linked worktree is
        # the worktree dir itself — ~/Projects/dotfiles/scratch renders as
        # `scratch`, naming the branch but never the repo. These layouts
        # keep the repo one level up (bare-repo/branch/...), so print that
        # component too, and only where the per-worktree git dir differs
        # from the common one. One `git rev-parse`, only inside a repo.
        custom.worktree = {
          description = "parent of the repo root, when in a linked worktree";
          require_repo = true;
          when = true;
          shell = [ "sh" ];
          command = ''
            git rev-parse --path-format=absolute \
                --git-dir --git-common-dir --show-toplevel 2>/dev/null | {
              read -r gitdir
              read -r common
              read -r top
              [ "$gitdir" = "$common" ] && exit 0
              parent=''${top%/*}
              printf '%s/' "''${parent##*/}"
            }
          '';
          format = "[$output]($style)";
          style = "blue";
        };
      };
    };

    programs.gpg.enable = true;

    # git worktree wrappers for the .bare workspace layout (gwt init/clone/
    # add/rm/switch); the module sources the function and installs the zsh
    # completion.
    programs.gwt.enable = true;

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

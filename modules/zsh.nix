{ config, ... }:

# zsh and its prompt. The git aliases are in ./aliases.nix, the
# `devshell` function in ./devshell.nix.
{
  ## ----- session -------------------------------------------------------------
  home.sessionVariables = {
    COLORTERM = "truecolor";
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    defaultKeymap = "viins";
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
}

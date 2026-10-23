{ config, lib, ... }:

# direnv with nix-direnv, for projects that ship their own flake. An
# `.envrc` holding `use flake` loads the project's dev shell into the
# current zsh on `cd`. nix-direnv caches the evaluated shell under the
# project's `.direnv/` and registers it as a GC root, so a collection
# leaves the toolchain alone (the job `devshell` does for ../devShells)
# and a later entry skips the evaluation until flake.nix or flake.lock
# changes. See ../doc/devshells.md, "Project flakes".
let
  direnv = lib.getExe config.programs.direnv.package;
in
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    # The zsh hook comes from programs.zsh.enable. `silent` drops the
    # "direnv: export +AR +CC ..." list a Rust shell prints on each entry;
    # errors and the "is blocked" notice still show.
    silent = true;
  };

  # The `.envrc` below is ours, not the project's: kept out of every
  # `git status` without a per-repo exclude. A project that tracks its
  # own `.envrc` is unaffected; ignores only hide untracked files.
  programs.git.ignores = [
    ".envrc"
    ".direnv/"
  ];

  # Offer the flake's shell on `cd` into the top of a checkout that has a
  # flake.nix and no .envrc. The answer is a trust decision about the
  # repository's flake, so it is asked once per repository and kept in
  # its git config (`direnv.flake`), which all its worktrees share: a new
  # worktree of a "yes" repository gets its .envrc without asking, and a
  # "no" repository is never asked again. `git config --unset
  # direnv.flake` in the repository asks again.
  #
  # chpwd runs before the precmd hook of direnv, so a new .envrc loads on
  # the same `cd`. Command substitutions inherit chpwd, hence the
  # ZSH_SUBSHELL guard.
  programs.zsh.initContent = ''
    ## --- direnv: offer a project's flake -------------------------------
    _direnv_flake_offer () {
      [[ -o interactive && -t 0 && $ZSH_SUBSHELL -eq 0 ]] || return 0
      [[ -f flake.nix && ! -e .envrc ]] || return 0
      [[ $(git rev-parse --show-toplevel 2>/dev/null) == $PWD ]] || return 0
      local answer
      answer=$(git config --get direnv.flake)
      case $answer in
        no) return 0 ;;
        yes) ;;
        *)
          if read -q "?direnv: load this repository's flake dev shell? [y/N] "; then
            answer=yes
          else
            answer=no
          fi
          print
          git config --local direnv.flake $answer
          if [[ $answer == no ]]; then
            print "direnv: not asking again here (git config --unset direnv.flake to undo)"
            return 0
          fi
          ;;
      esac
      print 'use flake' > .envrc && ${direnv} allow
    }
    autoload -Uz add-zsh-hook
    add-zsh-hook chpwd _direnv_flake_offer
  '';
}

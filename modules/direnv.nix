{ ... }:

# direnv with nix-direnv, for projects that ship their own flake. An
# `.envrc` holding `use flake` loads the project's dev shell into the
# current zsh on `cd`. nix-direnv caches the evaluated shell under the
# project's `.direnv/` and registers it as a GC root, so a collection
# leaves the toolchain alone (the job `devshell` does for ../devShells)
# and a later entry skips the evaluation until flake.nix or flake.lock
# changes. See ../doc/devshells.md, "Project flakes".
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    # The zsh hook comes from programs.zsh.enable. `silent` drops the
    # "direnv: export +AR +CC ..." list a Rust shell prints on each entry;
    # errors and the "is blocked" notice still show.
    silent = true;
  };
}

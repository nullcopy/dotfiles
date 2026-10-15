{ config, ... }:

# git and the gwt worktree wrappers. Signing is a per-machine choice,
# made outside this repo: see "Commit signing" in the README.
{
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
    };

    # Settings that differ by machine and that no profile can know, such
    # as whether the signing key is on this one. git ignores the include
    # while the file does not exist.
    includes = [ { path = "${config.xdg.configHome}/git/local"; } ];
  };
}

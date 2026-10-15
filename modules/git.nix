# git, with signed commits and tags, and the gwt worktree wrappers.
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
      commit.gpgsign = true;
      tag.gpgsign = true;
    };
  };
}

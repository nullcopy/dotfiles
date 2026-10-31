# zellij, the terminal multiplexer. tmux stays installed beside it
# (./default.nix); nothing here starts zellij on its own, so the two
# can coexist and new terminals are unaffected.
{
  programs.zellij = {
    enable = true;

    # The built-in integration evals zellij's auto-start snippet in zsh,
    # which wraps every new zsh in a zellij session. Off: start it by
    # hand with `zellij` (rejoin with `zellij attach`).
    enableZshIntegration = false;

    settings = {
      # Matches the desktop palette (noctalia's Kanagawa, app-state/).
      theme = "kanagawa";

      # No borders around panes; the UI bars name the active one.
      pane_frames = false;

      # Lines of scrollback kept before the top is cut off
      # (zellij's default is 10_000).
      scroll_buffer_size = 50000;

      # Clipboard reads default to OSC 52, which also reaches a local
      # terminal over SSH. On a desktop that wants the system clipboard
      # directly instead, set copy_command here (wl-copy on Wayland).
    };
  };
}

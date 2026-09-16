{
  config,
  lib,
  pkgs,
  ...
}:

# Graphical config, applied only where my.desktop.enable is set (the
# machine runs nixos-core's core.desktop.enable).
let
  # Link a file in app-state/ to the path where its app rewrites it.
  appState = path: config.lib.file.mkOutOfStoreSymlink "${config.my.repoPath}/app-state/${path}";
in
{
  config = lib.mkIf config.my.desktop.enable {
    home.packages = with pkgs; [
      brave
      nerd-fonts.jetbrains-mono
      nautilus
      signal-desktop
      tor-browser
      qbittorrent
    ];

    # Standalone home-manager needs this for home.packages fonts to be
    # picked up by fontconfig.
    fonts.fontconfig.enable = true;

    ## ----- session variables ---------------------------------------------------
    home.sessionVariables = {
      BROWSER = "brave";
      TERMINAL = "alacritty";
    };

    ## ----- default applications ------------------------------------------------
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = "brave-browser.desktop";
        "x-scheme-handler/http" = "brave-browser.desktop";
        "x-scheme-handler/https" = "brave-browser.desktop";
        "x-scheme-handler/about" = "brave-browser.desktop";
        "x-scheme-handler/unknown" = "brave-browser.desktop";
      };
    };

    ## ----- programs ------------------------------------------------------------
    # The noctalia binary and the baseline /etc/niri/config.kdl come from
    # core.desktop.enable; this repo personalizes niri (./niri.nix) and
    # captures settings.toml (symlink below).

    programs.alacritty = {
      enable = true;
      settings = {
        font.normal.family = "JetBrainsMono Nerd Font";
        window.decorations = "None";
        window.opacity = 0.9;
      };
    };

    ## ----- app-rewritten configs (app-state/) ----------------------------------
    # In-app changes show up here as unstaged diffs. noctalia's atomic
    # writer canonicalises the settings link, so it survives every save.
    home.file.".local/state/noctalia/settings.toml".source = appState "noctalia/settings.toml";
    home.file.".config/noctalia/palettes".source = appState "noctalia/palettes";
  };
}

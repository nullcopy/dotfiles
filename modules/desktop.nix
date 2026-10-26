{ config, pkgs, ... }:

# Graphical config, imported by ../profiles/desktop.nix: the machine
# runs nixos-core's core.desktop.enable.
let
  # Link a file in app-state/ to the path where its app rewrites it.
  appState = path: config.lib.file.mkOutOfStoreSymlink "${config.my.repoPath}/app-state/${path}";
in
{
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

  ## ----- noctalia plugins (vendor/) ------------------------------------------
  # Third-party plugins are vendored and installed from the store, so they
  # stay read-only and change only through a reviewed commit here: noctalia
  # does not sandbox plugins, and a git source would auto-update them.
  # noctalia's built-in "local" source scans <data>/noctalia/plugins/<name>;
  # plugins keep their own data under ~/.local/state/noctalia instead.
  # pricebar: github.com/humblemane/pricebar at 0bd8a14 (2.0.0), audited.
  home.file.".local/share/noctalia/plugins/pricebar".source = ../vendor/noctalia-plugins/pricebar;
}

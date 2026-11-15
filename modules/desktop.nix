{
  config,
  lib,
  pkgs,
  ...
}:

# Graphical config, imported by ../profiles/desktop.nix: the machine
# runs nixos-core's core.desktop.enable.
let
  # Link a file in this checkout to the path where its app reads it.
  repoFile = path: config.lib.file.mkOutOfStoreSymlink "${config.my.repoPath}/${path}";
in
{
  options.my.noctalia.wallpaper = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = ''
      Absolute path to this machine's default Noctalia wallpaper. A
      wallpaper chosen in the Settings UI is stored in the machine-local
      state file and overrides this value.
    '';
  };

  config = {
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
    # supplies noctalia's shared config (symlink below).

    programs.alacritty = {
      enable = true;
      settings = {
        font.normal.family = "JetBrainsMono Nerd Font";
        window.decorations = "None";
        window.opacity = 0.9;
      };
    };

    ## ----- noctalia config ------------------------------------------------------
    # Shared settings are declarative and tracked. The Settings UI writes
    # machine-local overrides to ~/.local/state/noctalia/settings.toml,
    # which loads last and is not managed here.
    home.file.".config/noctalia/config.toml".source = repoFile "config/noctalia/config.toml";
    home.file.".config/noctalia/palettes".source = repoFile "app-state/noctalia/palettes";
    home.file.".config/noctalia/wallpaper.toml" = lib.mkIf (config.my.noctalia.wallpaper != null) {
      text = ''
        [wallpaper.default]
        path = ${builtins.toJSON config.my.noctalia.wallpaper}
      '';
    };
  };
}

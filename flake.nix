{
  description = "nullcopy's home environment (standalone home-manager) and dev shells";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # No nixpkgs.follows here: nixvim tracks its own nixpkgs pin, and
    # forcing ours has caused build errors before.
    nixvim = {
      url = "github:nix-community/nixvim";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = nixpkgs.lib;

      # One homeConfiguration per machine. desktop pairs with nixos-core's
      # core.desktop.enable; stateVersion is the HM version at first setup
      # on that machine; repoPath is the checkout path when it differs
      # from ~/.dotfiles.
      mkHome =
        {
          desktop,
          stateVersion,
          repoPath ? null,
        }:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit inputs; };
          modules = [
            ./home
            (
              {
                my.desktop.enable = desktop;
                home.stateVersion = stateVersion;
              }
              // lib.optionalAttrs (repoPath != null) { my.repoPath = repoPath; }
            )
          ];
        };

      # Shells are auto-discovered from ./devShells/*.nix. mkDevShell sets
      # $SHELL and re-execs into zsh: `nix develop` spawns a bare
      # bashInteractive, which child processes would otherwise inherit.
      # The guard keeps that out of runs with no terminal on stdout, which
      # the exec would otherwise hijack, `nix develop --command` included.
      mkDevShell =
        file:
        (import file { inherit pkgs system; }).overrideAttrs (old: {
          shellHook = (old.shellHook or "") + ''
            export SHELL=${pkgs.zsh}/bin/zsh
            if [ -t 1 ] && [ -z "''${DEVSHELL_NO_EXEC:-}" ]; then
              exec ${pkgs.zsh}/bin/zsh
            fi
          '';
        });

      shellNames = lib.pipe (builtins.readDir ./devShells) [
        (lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name))
        builtins.attrNames
        (map (lib.removeSuffix ".nix"))
      ];
    in
    {
      # `home-manager switch --flake <this repo>` auto-selects the
      # "<user>@<hostname>" entry, so no #attr needed on the command line.
      homeConfigurations = {
        "nullcopy@wisp" = mkHome {
          desktop = true;
          stateVersion = "25.11";
        };
        "nullcopy@aurora" = mkHome {
          desktop = true;
          stateVersion = "25.11";
        };
      };

      # One shell per language; enter with `nix develop <flake>#<name>`.
      devShells.${system} = lib.genAttrs shellNames (name: mkDevShell (./devShells + "/${name}.nix"));

      formatter.${system} = pkgs.nixfmt;
    };
}

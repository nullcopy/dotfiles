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

    gwt = {
      url = "github:nullcopy/gwt";
      inputs.nixpkgs.follows = "nixpkgs";
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

      mkHome =
        modules:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit inputs; };
          inherit modules;
        };

      # The two kinds of machine. desktop pairs with nixos-core's
      # core.desktop.enable. A machine entry below is one of these, plus
      # any modules of its own.
      headless = [ ./home ];
      desktop = headless ++ [ { my.desktop.enable = true; } ];

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

      # The source trees of the inputs in `ins` and of the inputs of each,
      # as linkFarm entries under `dir`.
      inputTrees =
        dir: ins:
        lib.concatLists (
          lib.mapAttrsToList (
            name: input:
            [
              {
                name = "${dir}/${name}";
                path = input.outPath;
              }
            ]
            ++ inputTrees "${dir}/${name}.inputs" (input.inputs or { })
          ) ins
        );
    in
    {
      # One entry per machine, named "<user>@<hostname>": home-manager and
      # the fetch timer (home/updates.nix) select it by that name. Machine
      # specifics go in extra modules, for example
      #   "nullcopy@fern" = mkHome (headless ++ [ ./hosts/fern.nix ]);
      homeConfigurations = {
        "nullcopy@wisp" = mkHome desktop;
        "nullcopy@aurora" = mkHome desktop;
      };

      # One shell per language; enter with `nix develop <flake>#<name>`.
      devShells.${system} = lib.genAttrs shellNames (name: mkDevShell (./devShells + "/${name}.nix"));

      packages.${system} = {
        # What an entry needs besides the shell's closure, as one buildable
        # path for `devshell` to hold a GC root on: the source trees the
        # devShells are evaluated from, and the bashInteractive that
        # `nix develop` realises from the flake's nixpkgs for the shell it
        # spawns. Neither is in the closure, so without this root the
        # collection takes them and the next entry downloads them again.
        # List every input that a file in ./devShells reads.
        devshell-inputs = pkgs.linkFarm "devshell-inputs" [
          {
            name = "nixpkgs";
            path = nixpkgs.outPath;
          }
          {
            name = "bashInteractive";
            path = pkgs.bashInteractive;
          }
        ];

        # What the daily fetch (home/updates.nix) builds and roots next to
        # the generation: every devShell, the bashInteractive an entry
        # realises, and the source tree of every input, which no closure
        # includes.
        fetch-roots = pkgs.linkFarm "fetch-roots" (
          inputTrees "inputs" (removeAttrs inputs [ "self" ])
          ++ [
            {
              name = "bashInteractive";
              path = pkgs.bashInteractive;
            }
          ]
          ++ map (name: {
            name = "devShells/${name}";
            path = self.devShells.${system}.${name};
          }) shellNames
        );
      };

      formatter.${system} = pkgs.nixfmt;
    };
}

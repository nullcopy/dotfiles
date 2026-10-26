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

      # A home from its machine's module in ./hosts. It knows the entry it
      # was built from (my.entry), so the fetch timer in modules/updates.nix
      # builds that same entry.
      mkHome =
        name: host:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit inputs; };
          modules = [
            host
            { my.entry = name; }
          ];
        };

      # Shells are auto-discovered from ./devShells/*.nix. mkDevShell sets
      # $SHELL and re-execs into zsh: `nix develop` spawns a bare
      # bashInteractive, which child processes would otherwise inherit.
      # The guard keeps that out of runs with no terminal on stdout, which
      # the exec would otherwise hijack, `nix develop --command` included,
      # and out of direnv (DIRENV_IN_ENVRC), which runs the hook inside
      # zsh's prompt hook with the terminal still on stdout: an `.envrc`
      # with `use flake ~/.config/dotfiles#rust` would hang on the nested
      # zsh.
      mkDevShell =
        file:
        (import file { inherit pkgs system; }).overrideAttrs (old: {
          shellHook = (old.shellHook or "") + ''
            export SHELL=${pkgs.zsh}/bin/zsh
            if [ -t 1 ] && [ -z "''${DEVSHELL_NO_EXEC:-}" ] && [ -z "''${DIRENV_IN_ENVRC:-}" ]; then
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
      # One "<user>@<hostname>" entry per machine, which home-manager
      # selects by hostname: `home-manager switch --flake <this repo>`,
      # with no attribute. On a host with no entry it fails; nothing is
      # applied by guess.
      homeConfigurations = lib.mapAttrs mkHome {
        "nullcopy@aurora" = ./hosts/aurora.nix;
        "nullcopy@obelisk" = ./hosts/obelisk.nix;
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

        # What the daily fetch (modules/updates.nix) builds and roots next to
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

{ pkgs, system }:

# Every language shell at once, for a session that touches several of them
# and would rather not pick. Composed from the raw shell files, not from
# self.devShells: mkShell concatenates the shellHooks of everything in
# inputsFrom, and the wrapper in flake.nix appends an `exec zsh` hook to
# each shell, so composing the wrapped ones would stack one per shell and
# the first would hijack the session. forgebox is left out; it is a tool
# shell rather than a language one, and it builds from source.
let
  shells = map (file: import file { inherit pkgs system; }) [
    ./bash.nix
    ./c.nix
    ./go.nix
    ./lua.nix
    ./nix.nix
    ./python.nix
    ./rust.nix
  ];
in
pkgs.mkShell {
  inputsFrom = shells;

  # inputsFrom merges the *Inputs lists and shellHook and nothing else, so
  # plain env attrs set by an individual shell do not come along: this is
  # rust.nix's LD_LIBRARY_PATH, repeated because that merge skips it.
  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
    pkgs.stdenv.cc.cc.lib
  ];
}

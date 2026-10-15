{ config, ... }:

# `devshell`, a zsh function that enters a shell of ../devShells through a
# profile, so that its closure survives garbage collection. See
# ../doc/devshells.md.
{
  programs.zsh.initContent = ''
    ## --- devShell helper ---------------------------------------------
    # Enter a fallback shell from this flake through a profile, because a
    # profile is a GC root and a bare `nix develop` is not: nothing roots
    # the toolchain, so the collector deletes it and the next entry pulls
    # the whole closure down again. The profile sits under the per-user
    # profile dir that nix-collect-garbage scans, so the `nix.gc` timer
    # prunes its old generations too.
    #
    # --offline is handed to nix. It is not the default because it turns
    # substituters off, so an entry after a flake.lock bump would build
    # the toolchain from source. nix disables the network by itself
    # only when no interface holds an address, which any virtual
    # interface that stays up defeats.
    devshell () {
      local -a nixflags
      local name help
      while [ $# -gt 0 ]; do
        case $1 in
          -h|--help) help=1 ;;
          --offline) nixflags+=(--offline) ;;
          -*)
            echo "devshell: unknown option $1" >&2
            return 2
            ;;
          *)
            if [ -n "$name" ]; then
              echo "devshell: expected one shell name" >&2
              return 2
            fi
            name=$1
            ;;
        esac
        shift
      done
      if [ -n "$help" ] || [ -z "$name" ]; then
        # Help on stdout when asked for, on stderr for a missing name.
        local fd=2
        [ -n "$help" ] && fd=1
        cat >&$fd <<EOF
    usage: devshell [--offline] <name>

    Enter the <name> shell of ${config.my.repoPath}
    through a profile that roots its closure, so the toolchain survives
    garbage collection.

    options:
      --offline   Hand --offline to nix: no substituters, no downloads.
                  Enough for a shell entered online since the last
                  flake.lock bump. A new toolchain needs the network.
      -h, --help  Show this help.

    shells: $(ls ${config.my.repoPath}/devShells | sed 's/\.nix$//' | tr '\n' ' ')
    EOF
        [ -n "$help" ] && return 0
        return 2
      fi
      # The profile below roots the shell's closure, but not the source
      # trees the flake is evaluated from, and a checkout with
      # uncommitted changes gets no eval cache to skip that evaluation.
      # devshell-inputs links those trees and the out-link roots them.
      # It stays out of the profiles dir, where nix-collect-garbage
      # would take it for a profile.
      local roots=''${XDG_STATE_HOME:-$HOME/.local/state}/nix/gcroots
      mkdir -p "$roots" || return
      nix build "''${nixflags[@]}" --out-link "$roots/devshell-inputs" \
        "${config.my.repoPath}#devshell-inputs"

      local dir=''${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/devshells
      mkdir -p "$dir" || return
      nix develop "''${nixflags[@]}" --profile "$dir/$name" "${config.my.repoPath}#$name"
    }
  '';
}

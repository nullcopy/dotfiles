# Updates

## Updating

```
nix flake update && home-manager switch --flake ~/.dotfiles
```

To see what that would download before switching:

```
nix flake update && home-manager build -n --flake ~/.dotfiles
```

## Background fetch

An update downloads a large part of the closure. The
`home-manager-fetch` user timer does that download ahead of time: once a
day it builds the generation and the devShells the newest inputs give.
When you update, the inputs have moved by a day at most, and nearly
every path the switch needs is in the store.

The service runs three nix commands and nothing else
(`home/updates.nix`):

```
nix flake update --flake ~/.dotfiles --output-lock-file <lock>
nix build ~/.dotfiles#homeConfigurations."<user>@<host>".activationPackage \
  --reference-lock-file <lock> --no-write-lock-file --out-link <link>
nix build ~/.dotfiles#fetch-roots \
  --reference-lock-file <lock> --no-write-lock-file --out-link <link>-roots
```

- The updated lock is written to the runtime directory, not to the
  checkout. The fetch leaves `flake.lock` and the working tree alone.
- `fetch-roots` (`flake.nix`) links every devShell, the
  `bashInteractive` an entry realises, and the source tree of every
  input. The `forgebox` shell builds from source, so the fetch compiles
  it when its inputs have moved.
- The builds are linked at `home-manager-fetch` and
  `home-manager-fetch-roots` in `~/.local/state/nix/gcroots`, or in
  `$XDG_STATE_HOME/nix/gcroots` where that is set. The links are GC
  roots, so what was fetched survives `nix.gc` until the next fetch
  replaces it.
- An interrupted fetch keeps every path it finished. The next run
  downloads the rest.
- `<host>` is the short hostname.

A failed run is tried again after 30 minutes, twice. systemd allows the
service three starts in six hours, manual ones included, and refuses a
fourth with `start-limit-hit`. `reset-failed` clears that count.

```
systemctl --user list-timers home-manager-fetch
journalctl --user -u home-manager-fetch -e
systemctl --user start home-manager-fetch          # fetch now
systemctl --user reset-failed home-manager-fetch   # after start-limit-hit
```

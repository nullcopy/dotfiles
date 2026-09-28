# devShells

One fallback shell per language, for projects without their own flake.

## Usage

```
devshell rust    # enter a shell
devshell         # list them
```

`devshell` is a zsh function defined in `home/default.nix`.

## Shells

One shell per file in `devShells/`, discovered automatically. Add one by
dropping a file there: a function taking `{ pkgs, system }` and returning
a `pkgs.mkShell`.

- `rust` includes `rustPlatform.bindgenHook`, so bindgen-based crates
  build without manual setup.
- `all` composes the language shells with `inputsFrom`, for a session
  that touches several of them. `inputsFrom` merges the `*Inputs` lists
  and the shell hooks and nothing else, so a plain env attr set by one of
  the composed shells (`rust.nix`'s `LD_LIBRARY_PATH`) has to be repeated
  there.

## Garbage collection

A plain `nix develop <flake>#<name>` registers no GC root, so the next
collection deletes what the shell needs and the following entry downloads
it again. `devshell` holds two kinds of root to prevent that.

### Shell closures

`devshell` wraps `nix develop --profile
~/.local/state/nix/profiles/devshells/<name>`. A profile is a GC root, so
the shell's closure survives. The flake ref is still evaluated on every
entry, so the toolchain moves only when `flake.lock` does.

The profiles sit under the per-user profile directory that
`nix-collect-garbage` scans, so the weekly `nix.gc` user timer (in
`home/default.nix`) prunes generations older than 30 days. The current
generation of each profile is never collected, so every shell you have
entered pins one toolchain until you delete its profile:

```
rm ~/.local/state/nix/profiles/devshells/rust*   # then let nix.gc run
```

### Flake inputs

A profile does not root the source trees the flake is evaluated from, so
a collection would take nixpkgs. The eval cache would skip the evaluation
altogether, but it is keyed on a flake fingerprint, which a checkout with
uncommitted changes has none of, and this one carries them by design
(see "App state" in the README).

So the flake has a `devshell-inputs` package, a `linkFarm` of those
trees, and `devshell` builds it with `--out-link
~/.local/state/nix/gcroots/devshell-inputs` before entering. The link is
repointed on each entry, so a `flake.lock` bump releases the tree it
moved off.

A shell that reads an input other than nixpkgs needs that input added to
`devshell-inputs` in `flake.nix`.

# devShells

One fallback shell per language, for projects without their own flake.

## Usage

```
devshell rust              # enter a shell
devshell --offline rust    # enter one without a network
devshell --help            # options and the list of shells
```

`devshell` is a zsh function defined in `modules/devshell.nix`.

## Offline

`--offline` is handed to nix. It turns substituters off and treats every
downloaded file as current, so an entry touches nothing but the store.
That is enough for a shell entered online since the last `flake.lock`
bump: the roots below keep everything it needs. A shell never entered,
or one whose toolchain moved with the lock, still needs the network.

It is not the default because it is the wrong setting online: a lock
bump would then compile the toolchain instead of downloading it. nix
turns the network off by itself only when no interface holds a
non-loopback address, which any virtual interface that stays up without
an uplink defeats, so the flag has to be passed when the machine is
offline.

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

## Editor tooling

nvim installs no language server and no formatter, for any language.
`modules/neovim.nix` sets `package = null` on every server it configures,
so nvim runs whatever `clangd`, `gopls` or `rust-analyzer` is on `PATH`,
and the home closure carries none of them. A server or formatter that is
not on `PATH` does not run.

They come from a shell here or from the project's own flake, so start
nvim inside one. nvim is configured for two servers that no shell here
provides: `marksman` for Markdown and `yaml-language-server` for YAML.
Add them to a shell to use them. A new language shell has to bring its
own server.

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
`modules/default.nix`) prunes generations older than 30 days. The current
generation of each profile is never collected, so every shell you have
entered pins one toolchain until you delete its profile:

```
rm ~/.local/state/nix/profiles/devshells/rust*   # then let nix.gc run
```

### Flake inputs and bashInteractive

A profile does not root the source trees the flake is evaluated from, so
a collection would take nixpkgs. The eval cache would skip the evaluation
altogether, but it is keyed on a flake fingerprint, which a checkout with
uncommitted changes has none of, and this one carries them by design
(see "App state" in the README).

Nor does it root `bashInteractive`: `nix develop` realises that package
from the flake's nixpkgs on every entry, for the shell it spawns, and no
closure here contains it. A collection takes it, and the next entry
downloads it again before the shell starts.

So the flake has a `devshell-inputs` package, a `linkFarm` of those
trees and of `bashInteractive`, and `devshell` builds it with
`--out-link ~/.local/state/nix/gcroots/devshell-inputs` before entering.
The link is repointed on each entry, so a `flake.lock` bump releases
what it moved off.

A shell that reads an input other than nixpkgs needs that input added to
`devshell-inputs` in `flake.nix`.

## Project flakes

A project with its own flake does not need a shell here: direnv loads
the project's shell instead, with the same protection from the
collector. `modules/direnv.nix` enables direnv and nix-direnv. In the
checkout:

```
echo 'use flake' > .envrc
echo .envrc >> "$(git rev-parse --git-path info/exclude)"
direnv allow
```

The exclude line keeps `.envrc` out of `git status`; skip it in a
project that commits one. `--git-path` finds the file in a linked
worktree too, where `.git` is a file, and resolves to the main
repository's `info/exclude`, which every worktree shares, so it is
needed once per repository.

The shell loads into the current zsh on `cd` and unloads on leaving it.
nix-direnv keeps the evaluated shell in `.direnv/` and registers it and
the flake's inputs as GC roots, so neither the weekly user collector nor
a system one deletes the toolchain. A later entry reads the cached
environment instead of evaluating the flake, until `flake.nix`,
`flake.lock` or `.envrc` changes; if that evaluation fails, the last
working environment stays loaded.

The roots live in each checkout's `.direnv/`, so every worktree with an
`.envrc` holds one (the same store paths, so no extra disk), and a
checkout holds its toolchain until its `.direnv/` is deleted. To find
stale ones:

```
nix-store --gc --print-roots | grep /.direnv/
```

A project without a flake can load a shell from here the same way, with
`use flake ~/.dotfiles#rust` in its `.envrc`. The zsh re-exec in
`flake.nix` stays out of direnv runs (`DIRENV_IN_ENVRC`); without that
guard the hook would start a nested zsh and hang the prompt.

Only an interactive zsh runs the hook. A command run from elsewhere
(a script, an agent) gets the environment with `direnv exec . <cmd>`.

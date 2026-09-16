# dotfiles

nullcopy's home environment, applied with **standalone
[home-manager](https://github.com/nix-community/home-manager)**. Works on
any Linux with Nix. The desktop half (`desktop = true`) expects the
system to provide niri + noctalia — on NixOS that is
[nixos-core](https://github.com/nullcopy/nixos-core)'s
`core.desktop.enable`.

## Layout

```
flake.nix              # homeConfigurations."nullcopy@<machine>" per machine + devShells
app-state/             # configs apps rewrite (see "App state")
home/
  default.nix          # entry point: my.* options + CLI baseline (zsh, git, starship)
  aliases.nix          # zsh + oh-my-zsh-style git aliases
  neovim.nix           # nixvim config (AstroNvim-flavoured UX)
  opencode.nix         # opencode pointed at the local ollama service
  desktop.nix          # GUI apps, noctalia, alacritty — my.desktop.enable only
  niri.nix             # niri keybindings wired to Noctalia IPC — desktop only
devShells/             # fallback per-language shells (see "devShells")
```

## Setup on a new machine

Clone to the canonical path and apply:

```
git clone git@github.com:nullcopy/dotfiles ~/.dotfiles
nix run home-manager -- switch --flake ~/.dotfiles
```

home-manager picks the `nullcopy@<hostname>` entry automatically; add a
new machine to `homeConfigurations` in `flake.nix` (set `desktop` per
machine). After the first switch, plain
`home-manager switch --flake ~/.dotfiles` works. For a checkout outside
`~/.dotfiles`, pass `repoPath` in the machine's entry so the
app-state symlinks resolve.

## App state

Apps that rewrite their own config keep their file in `app-state/`,
linked out-of-store into place: the file in the working tree **is** the
live file. A change in the app shows up as an unstaged diff; commit it
to persist.

- `app-state/noctalia/settings.toml` → `~/.local/state/noctalia/settings.toml`
  (everything the v5 settings UI writes)
- `app-state/noctalia/palettes/` → `~/.config/noctalia/palettes/`

## devShells

One fallback shell per language, for projects without their own flake.
Enter one with the `devshell` zsh function, which takes a shell name (run
it with no argument to list them):

```
devshell rust
```

One shell per file in `devShells/`; add one by dropping a file there (a
function taking `{ pkgs, system }` returning a `pkgs.mkShell`).
`#rust` includes `rustPlatform.bindgenHook`, so bindgen-based crates
build without manual setup.

`all` is the exception to one-shell-per-language: it composes the
language shells with `inputsFrom`, for a session that touches several of
them. `inputsFrom` merges the `*Inputs` lists and the shell hooks and
nothing else, so a plain env attr set by one of the composed shells
(`rust.nix`'s `LD_LIBRARY_PATH`) has to be repeated there.

`devshell` wraps `nix develop --profile
~/.local/state/nix/profiles/devshells/<name>` rather than plain `nix
develop <flake>#<name>`. A plain `nix develop` registers no GC root, so
the next garbage collection deletes the toolchain and the following entry
re-downloads the whole closure — the reason `#rust` felt like it was
fetching a new toolchain every time. A profile is a GC root, so the
closure survives; the flake ref is still evaluated on every entry, so the
toolchain moves only when `flake.lock` does.

Those profiles sit under the per-user profile directory that
`nix-collect-garbage` scans, so the weekly `nix.gc` user timer (in
`home/default.nix`) prunes generations older than 30 days. The current
generation of each profile is never collected, so every shell you have
entered pins one toolchain until you delete its profile:

```
rm ~/.local/state/nix/profiles/devshells/rust*   # then let nix.gc run
```

## Day to day

```
home-manager switch --flake ~/.dotfiles                        # apply config edits
nix flake update && home-manager switch --flake ~/.dotfiles    # bump inputs, then apply
```

Pre-commit formatting hook: `git config core.hooksPath .githooks` after clone.

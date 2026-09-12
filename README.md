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
Pick one explicitly:

```
nix develop ~/.dotfiles#rust
```

One shell per file in `devShells/`; add one by dropping a file there (a
function taking `{ pkgs, system }` returning a `pkgs.mkShell`).
`#rust` includes `rustPlatform.bindgenHook`, so bindgen-based crates
build without manual setup.

## Day to day

```
home-manager switch --flake ~/.dotfiles                        # apply config edits
nix flake update && home-manager switch --flake ~/.dotfiles    # bump inputs, then apply
```

Pre-commit formatting hook: `git config core.hooksPath .githooks` after clone.

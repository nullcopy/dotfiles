# dotfiles

nullcopy's home environment, applied with **standalone
[home-manager](https://github.com/nix-community/home-manager)**. Works on
any Linux with Nix. The desktop type expects the system to provide
niri + noctalia — on NixOS that is
[nixos-core](https://github.com/nullcopy/nixos-core)'s
`core.desktop.enable`.

## Layout

```
flake.nix              # headless and desktop homes, machine entries + devShells
app-state/             # configs apps rewrite (see "App state")
profiles/              # the two types, as lists of modules
  headless.nix         # CLI only: modules/
  desktop.nix          # headless plus modules/desktop.nix and modules/niri.nix
modules/               # one module per concern
  default.nix          # imports the always-on modules; my.* options, identity, base packages, nix.gc
  zsh.nix              # zsh and starship
  aliases.nix          # zsh + oh-my-zsh-style git aliases
  devshell.nix         # the `devshell` zsh function (see "devShells")
  git.nix              # git, gpg, gwt
  neovim.nix           # nixvim config (AstroNvim-flavoured UX)
  opencode.nix         # opencode pointed at the local ollama service
  desktop.nix          # GUI apps, noctalia, alacritty — desktop only
  niri.nix             # niri keybindings wired to Noctalia IPC — desktop only
  updates.nix          # daily timer that fetches input updates ahead of a switch
devShells/             # fallback per-language shells (see "devShells")
doc/                   # longer notes (devshells.md, updates.md)
```

## Setup on a new machine

Clone to the canonical path and apply one of the two types:

```
git clone git@github.com:nullcopy/dotfiles ~/.dotfiles
nix run home-manager -- switch --flake ~/.dotfiles#headless   # CLI only: zsh, git, neovim, devShells
nix run home-manager -- switch --flake ~/.dotfiles#desktop    # headless plus niri, noctalia, GUI apps
```

Later switches name the type too: `home-manager switch --flake
~/.dotfiles#desktop`. Without one, home-manager looks for a
`nullcopy@<hostname>` entry and fails when there is none; the type is
never guessed.

A machine that has the signing key turns signing on once; see "Commit
signing" below.

A machine with config of its own gets that entry in `homeConfigurations`
in `flake.nix`: a type plus its modules, in a file under `hosts/` or
inline. `my.repoPath` names a checkout outside `~/.dotfiles` so the
app-state symlinks resolve. home-manager selects the entry by hostname,
with no type on the command line:

```nix
"nullcopy@fern" = headless ++ [ ./hosts/fern.nix { my.repoPath = "/srv/dotfiles"; } ];
```

## Commit signing

Signing is off until a machine turns it on: most machines have no key,
and a signed commit needs one. A machine with the key opts in once, in
a git config file outside this repo:

```
git config --file ~/.config/git/local commit.gpgsign true
git config --file ~/.config/git/local tag.gpgsign true
```

`~/.config/git/config` includes that file; git ignores the include while
the file does not exist. The file holds whatever else differs on this
machine alone. To stop signing here, delete the file. The choice is
recorded on the machine, like the home type, and never in this repo.

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
Enter one with the `devshell` zsh function, which takes a shell name
(`devshell --help` lists them):

```
devshell rust
devshell --offline rust    # without a network
```

Adding shells, the `all` shell, offline use and how the shells survive
garbage collection are covered in [doc/devshells.md](doc/devshells.md).

## Day to day

```
nix flake update --commit-lock-file              # bump inputs & commit lockfile
home-manager switch --flake ~/.dotfiles#<type>   # apply config edits
```

A daily timer fetches what the second line would download, so most of
it is in the store by then. See [doc/updates.md](doc/updates.md).

Pre-commit formatting hook: `git config core.hooksPath .githooks` after clone.

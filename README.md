# dotfiles

nullcopy's home environment, applied with **standalone
[home-manager](https://github.com/nix-community/home-manager)**. Works on
any Linux with Nix. The desktop type expects the system to provide
niri + noctalia — on NixOS that is
[nixos-core](https://github.com/nullcopy/nixos-core)'s
`core.desktop.enable`.

## Layout

```
flake.nix              # homeConfigurations."<user>@<host>" per machine + devShells
app-state/             # configs apps rewrite (see "App state")
hosts/                 # host-specific configs, one module per machine
profiles/              # the two types
  headless.nix         # CLI only: modules/
  desktop.nix          # headless plus modules/desktop.nix and modules/niri.nix
modules/               # one module per concern
  default.nix          # imports the always-on modules; my.* options, identity, base packages, nix.gc
  zsh.nix              # zsh and starship
  aliases.nix          # zsh + oh-my-zsh-style git aliases
  devshell.nix         # the `devshell` zsh function (see "devShells")
  direnv.nix           # direnv + nix-direnv for project flakes (see "devShells")
  git.nix              # git, gpg, gwt
  neovim.nix           # nixvim config (AstroNvim-flavoured UX)
  opencode.nix         # opencode with local ollama; hosted providers via /connect
  desktop.nix          # GUI apps, noctalia, alacritty — desktop only
  niri.nix             # niri keybindings wired to Noctalia IPC — desktop only
  updates.nix          # daily timer that fetches input updates ahead of a switch
devShells/             # fallback per-language shells (see "devShells")
doc/                   # longer notes (checkout.md, devshells.md, updates.md)
```

## Setup on a new machine

Every machine has a `<user>@<hostname>` entry in `homeConfigurations`
in `flake.nix`, pointing at its module under `hosts/`:

```nix
"nullcopy@oak" = ./hosts/oak.nix;
```

The module imports one of the two types, `profiles/headless.nix` (CLI
only: zsh, git, neovim, devShells) or `profiles/desktop.nix` (headless
plus niri, noctalia, GUI apps), and holds whatever the machine alone
gets: packages and program settings.

```nix
# hosts/oak.nix
{ pkgs, ... }:
{
  imports = [ ../profiles/headless.nix ];
  home.packages = with pkgs; [ htop ];
}
```

Then clone to `~/.config/dotfiles` and apply:

```
git clone git@github.com:nullcopy/dotfiles ~/.config/dotfiles
nix run home-manager -- switch --flake ~/.config/dotfiles
```

home-manager selects the entry by hostname, so no attribute goes on
the command line. On a host with no entry it fails; nothing is applied
by guess. After the first switch,
`home-manager switch --flake ~/.config/dotfiles` works.

The checkout can live anywhere else (a `~/src` tree, a bare repo with
worktrees) behind a symlink at `~/.config/dotfiles`, made before the
first switch. That, moving a checkout later, and machines still on
`~/.dotfiles` are covered in [doc/checkout.md](doc/checkout.md). A
switch with nothing at `~/.config/dotfiles` stops before changing
anything.

A machine that has the signing key turns signing on once; see "Commit
signing" below.

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
recorded on the machine and never in this repo.

## App state

Apps that rewrite their own config keep their file in `app-state/`,
linked out-of-store into place: the file in the working tree **is** the
live file. A change in the app shows up as an unstaged diff; commit it
to persist. The links go through `~/.config/dotfiles`, so they follow
the checkout wherever that path leads.

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

Adding shells, the `all` shell, offline use, how the shells survive
garbage collection and direnv for projects with their own flake are
covered in [doc/devshells.md](doc/devshells.md).

## Day to day

```
nix flake update --commit-lock-file             # bump inputs & commit lockfile
home-manager switch --flake ~/.config/dotfiles  # apply config edits
```

A daily timer fetches what the second line would download, so most of
it is in the store by then. See [doc/updates.md](doc/updates.md).

Pre-commit formatting hook: `git config core.hooksPath .githooks` after clone.

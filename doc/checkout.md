# Checkout location

The repo lives at `~/.config/dotfiles`. Setup clones it there and
nothing else is needed. This page is for the exceptions: a checkout
somewhere else, a move, or a machine still on the old `~/.dotfiles`.

## What depends on it

`my.repoPath` (`modules/default.nix`) is the path that leads to the
checkout, `~/.config/dotfiles` by default. A flake is evaluated from a
copy in the store, so it can't find its checkout by itself; these read
the path instead, all at runtime:

- the app-state links (`modules/desktop.nix`): noctalia's settings and
  palettes are out-of-store symlinks into `app-state/`
- `devshell` (`modules/devshell.nix`): `nix develop <path>#<name>`
- the `home-manager-fetch` timer (`modules/updates.nix`), which skips
  when `<path>/flake.nix` is missing

If the path leads nowhere, noctalia starts from defaults and the other
two fail.

## A checkout somewhere else

Clone where you like and put a symlink at `~/.config/dotfiles`
pointing at it, **before the first switch**:

```
git clone git@github.com:nullcopy/dotfiles ~/src/dotfiles
ln -sfn ~/src/dotfiles ~/.config/dotfiles
nix run home-manager -- switch --flake ~/.config/dotfiles
```

The links go store → `~/.config/dotfiles/app-state/…` → the checkout,
so in-app changes still land in the checkout as unstaged diffs.

`ln -sfn` replaces an existing symlink, but if `~/.config/dotfiles` is a
real directory it puts the link *inside* it. Move the directory away
first.

### Bare repo with worktrees

With a bare repo and one worktree per branch, link the worktree that
should be live, not the bare repo (which has no `flake.nix`):

```
git clone --bare git@github.com:nullcopy/dotfiles ~/src/dotfiles
git -C ~/src/dotfiles config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
git -C ~/src/dotfiles worktree add main master
ln -sfn ~/src/dotfiles/main ~/.config/dotfiles
```

The `config` line gives the bare clone remote-tracking branches, which
`git clone --bare` leaves out. Don't make it shallow: nix's git fetcher
can fail with "object not found" in a shallow clone with worktrees.

Only the linked worktree is live: noctalia writes there, and `devshell`
and the fetch timer read it. Another worktree builds with
`home-manager build --flake .`; to try its app-state, point the link at
it for a while and restart noctalia.

## Moving the checkout

No switch is needed, since the generation only knows
`~/.config/dotfiles`:

1. Commit anything in `app-state/` you want to keep
   (`git -C ~/.config/dotfiles status`).
2. Move the checkout, or set up the new one. Move a worktree with
   `git worktree move`, or run `git worktree repair` after a plain `mv`.
3. Repoint the link: `ln -sfn <new checkout> ~/.config/dotfiles`.
4. Restart noctalia (or log out and in) so it rereads its settings.
5. Check: `readlink -f ~/.local/state/noctalia/settings.toml` ends in
   `<new checkout>/app-state/noctalia/settings.toml`.

Moving a checkout that *is* `~/.config/dotfiles` (no link) works the
same: move it, then link the new path there.

Projects whose `.envrc` loads a shell from here (`use flake
~/.config/dotfiles#rust`, see devshells.md) follow the link too.

## From ~/.dotfiles

A machine set up before `~/.config/dotfiles` has its checkout at
`~/.dotfiles`, and its current generation links into it. Move the
checkout, but leave a link at the old path until the switch, so the
running generation's links never dangle:

```
git -C ~/.dotfiles status            # commit app-state/ changes first
mv ~/.dotfiles ~/.config/dotfiles
ln -s ~/.config/dotfiles ~/.dotfiles
git -C ~/.config/dotfiles pull
home-manager switch --flake ~/.config/dotfiles
rm ~/.dotfiles
```

Also update any `.envrc` that names `~/.dotfiles`.

## Recovering from a reset

If noctalia came up with defaults after a switch, its link leads
nowhere. Your settings are still in the checkout:

1. Find where the link leads: `readlink -f ~/.local/state/noctalia/settings.toml`.
2. Make that path exist: link the checkout to `~/.config/dotfiles` (or
   whatever `my.repoPath` is) as above.
3. If noctalia saved defaults over the link meanwhile, a plain file is
   now in the way: delete it and switch again.
4. If defaults landed in the checkout, `git restore app-state/noctalia`.
5. Restart noctalia.

## Overriding the path

A host can set `my.repoPath = "/srv/dotfiles";` in its module under
`hosts/`. Then a move needs an edit, a commit and a switch, so prefer
the link.

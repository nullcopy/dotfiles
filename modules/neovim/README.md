# Neovim

`default.nix` defines the Nixvim configuration installed in every home profile.
It provides an AstroNvim-flavoured interface with Telescope, Neo-tree, buffer
tabs, diagnostics and LSP navigation, completion, folding, Git signs and an
integrated terminal. Alabaster is the colorscheme and `<Space>` is the leader.
Which-key shows the available leader mappings while Neovim is running.

The configuration uses two-space indentation by default, four spaces for C++,
Python and Rust, and tabs for Go. It enables project-local `.nvim.lua` files
through `exrc`; Neovim asks before trusting a new local configuration file.

## Language tooling

Neovim does not install language servers or formatters into the home closure.
Each LSP server has `package = null`, so Neovim runs the executable on `PATH`.
Enter one of the repository's development shells or a project's own dev shell
before starting Neovim. See [Editor tooling](../../doc/devshells.md#editor-tooling).

Completion comes from the active language server, buffer paths and snippets.
Inlay hints are enabled for servers that support them. Rust formatting uses
rust-analyzer through the LSP formatting fallback.

Common LSP mappings are:

| Mapping      | Action                        |
| ------------ | ----------------------------- |
| `gd`         | Go to definition              |
| `gD`         | Go to declaration             |
| `gi`         | Go to implementation          |
| `gr`         | Show references               |
| `gy`         | Go to type definition         |
| `K`          | Hover documentation           |
| `<leader>la` | Code action                   |
| `<leader>lr` | Rename symbol                 |
| `<leader>lf` | Format buffer through the LSP |
| `<leader>lS` | Toggle the symbol outline     |
| `<leader>lD` | Search diagnostics            |

Formatting runs on save through Conform, using each filetype's configured
formatter where available. The fallback formatter trims trailing whitespace
and extra final newlines. Three commands control automatic formatting:

- `:FormatDisable` disables format-on-save for the session.
- `:FormatDisable!` disables it only for the current buffer.
- `:FormatEnable` re-enables it globally and for the current buffer.

`:BufferClose` closes the current buffer without quitting Neovim;
`:BufferClose!` also discards unsaved changes.

## rust-analyzer settings

Cargo features and Rust `cfg` values are different kinds of configuration. A
feature is selected through Cargo; a `cfg` such as `zcash_unstable = "nu8"`
controls conditional Rust source code. The `Ra` commands change both kinds of
setting in running rust-analyzer clients without editing the repository.

Updating either setting preserves other rust-analyzer settings and sends
`workspace/didChangeConfiguration`. Every running rust-analyzer client is
updated. After changing cfg flags, run `:LspCargoReload` to reload the Cargo
workspace and apply the new cfg set; a full LSP restart is not necessary. The
overrides are session-local: they are not saved in this repository and do not
apply to new Neovim sessions.

### Cargo features

Each non-bang command sets both the explicit feature list and whether Cargo's
default features form the base of that list:

| Command                            | Effect                                             |
| ---------------------------------- | -------------------------------------------------- |
| `:RaFeatures foo,bar`              | Enable `foo` and `bar` on top of default features. |
| `:RaFeatures --default foo,bar`    | Explicit spelling of the default-feature base.     |
| `:RaFeatures --no-default foo,bar` | Enable only `foo` and `bar`, without defaults.     |
| `:RaFeatures --no-default`         | Enable no features, including default features.    |
| `:RaFeatures --default`            | Enable only the default features.                  |
| `:RaFeatures`                      | Enable only the default features.                  |
| `:RaFeatures all`                  | Enable every Cargo feature.                        |
| `:RaFeatures!`                     | Restore the configured defaults.                   |

Feature lists are comma-separated, without spaces. `--default` and
`--no-default` set rust-analyzer's `cargo.noDefaultFeatures` to `false` and
`true`, respectively. The bang form removes both the `cargo.features` and
`cargo.noDefaultFeatures` runtime overrides. Combining `--no-default` with
`all` is rejected because those options have contradictory intent.

### Additional cfg flags

| Command                     | Effect                                                         |
| --------------------------- | -------------------------------------------------------------- |
| `:RaCfgs foo,key=value`     | Add `foo` and `key=value` to the automatically detected cfgs.  |
| `:RaCfgs !debug_assertions` | Disable `debug_assertions` in rust-analyzer's source analysis. |
| `:RaCfgs`                   | Clear the explicit cfg list; detected cfgs remain.             |
| `:RaCfgs!`                  | Restore the configured defaults.                               |

For example, this makes librustzcash's NU8-gated source available to the LSP:

```vim
:RaCfgs zcash_unstable=nu8
:LspCargoReload
```

Multiple enabled and disabled entries remain comma-separated:

```vim
:RaCfgs zcash_unstable=nu8,!debug_assertions
```

Do not add Rust string quotes around `nu8` in `RaCfgs`; rust-analyzer parses
the text after `=` as the cfg value. Disabling a cfg uses `!name` or
`!name=value`, following rust-analyzer's `cargo.cfgs` syntax. The bang form
removes the `cargo.cfgs` runtime override.

Rust cfgs have no `noDefaultFeatures` equivalent. rust-analyzer determines base
cfgs from rustc, the target and build scripts. `:RaCfgs` changes that base only
through individual additions and `!` exclusions; there is no global
`--no-default` cfg mode.

### Current selections

`:RaStatus` shows the default-feature base, explicit features, and enabled and
disabled cfgs for each running client, grouped by workspace root. For example:

```text
/home/nullcopy/src/zcash/librustzcash:
  default features: disabled
  features: sapling, orchard
  cfgs: zcash_unstable=nu8
  disabled cfgs: debug_assertions
```

`default` means a runtime override is absent and the existing configuration
applies. `none` means the explicitly supplied list is empty. Default features
are `enabled` when `cargo.noDefaultFeatures` is unset or `false`, and `disabled`
when it is `true`. Disabled cfgs are `none` unless exclusions are explicitly
configured; enabled cfgs remain `default` without an override because their
values come from rustc, the target and build scripts. All three commands warn
instead of failing when no rust-analyzer client is running.

These commands are deliberately LSP-only. They do not modify
`.cargo/config.toml`, dirty the Git worktree, or set features and cfgs for
Cargo commands run in a terminal.

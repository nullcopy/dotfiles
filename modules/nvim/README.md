# Neovim

`default.nix` configures nixvim for every machine. It owns editor options,
keymaps, completion, highlighting, LSP servers, and the user commands below.
Language servers come from `PATH`, not from the home closure; see
[`doc/devshells.md`](../../doc/devshells.md#editor-tooling).

## Rust-analyzer build configuration

Rust-analyzer has two independent controls for conditional compilation:

- Cargo features, set with `rust-analyzer.cargo.features`.
- `--cfg` flags, set with `rust-analyzer.cargo.cfgs`.

The commands below update the attached rust-analyzer client and send the new
settings through `workspace/didChangeConfiguration`. After rust-analyzer asks
for and receives the new configuration, the client requests
`rust-analyzer/reloadWorkspace`. The workspace reload re-runs `cargo metadata`,
so it can take a moment on a large project. Restarting Neovim or the language
server is not required.

### `:RaFeatures`

Set the Cargo features used for analysis:

```vim
:RaFeatures sapling,orchard
:RaFeatures all
```

`all` passes `--all-features`. A comma-separated list adds those features on
top of Cargo's default features. Names are passed through unchanged, including
dependency forms such as `dep:foo` or `dep/feature`.

Inspect or reset the setting:

```vim
:RaFeatures
:RaFeatures!
```

Bare usage reports the active `cargo.features` value. `RaFeatures!` removes the
explicit selection so Cargo's default features apply.

### `:RaCfgs`

Set `cfg` flags used for analysis:

```vim
:RaCfgs zcash_unstable="nu8"
:RaCfgs zcash_unstable=nu8,live_network_tests
```

Entries are comma-separated. rust-analyzer's `cargo.cfgs` format is
`key=value`, while Rust attributes write `key="value"`; both are accepted and
stored in the former form. These are cfg expressions, not Cargo features;
`zcash_unstable="nu8"` matches:

```rust
#[cfg(zcash_unstable = "nu8")]
```

Use `:RaFeatures` for feature gates such as `#[cfg(feature = "sapling")]`.

Inspect or clear the setting:

```vim
:RaCfgs
:RaCfgs!
```

Bare usage reports the active `cargo.cfgs` value. `RaCfgs!` clears all explicit
cfg flags.

### `:RaStatus`

Report both values for every attached rust-analyzer client:

```vim
:RaStatus
```

### State

These commands change the attached language server's in-memory `settings`.
Nothing is written to disk, `Cargo.toml`, or this repository. The values last
for the current Neovim session and disappear when the client stops. A new
session starts again from the settings declared in `default.nix`.

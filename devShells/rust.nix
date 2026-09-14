{ pkgs, ... }:

pkgs.mkShell {
  packages = with pkgs; [
    # Stable toolchain straight from nixpkgs, so every path substitutes
    # from cache.nixos.org instead of being unpacked and patchelf'd
    # locally. pkgs.rust-analyzer is a wrapper that already points
    # RUST_SRC_PATH at rustPlatform.rustLibSrc, so std resolves with no
    # extra wiring. Projects needing a specific channel or version should
    # carry their own flake.
    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer

    # Sets LIBCLANG_PATH + BINDGEN_EXTRA_CLANG_ARGS for bindgen-based crates
    # (librocksdb-sys, zcash_script, ring, ...).
    rustPlatform.bindgenHook

    # Common -sys crate build deps.
    pkg-config
    openssl

    taplo
    prettier

    cargo-audit
    cargo-vet
  ];

  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
    pkgs.stdenv.cc.cc.lib
  ];
}

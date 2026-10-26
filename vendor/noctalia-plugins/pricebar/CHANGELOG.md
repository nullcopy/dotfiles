# Changelog

All notable changes to PriceBar (formerly HyprPrice). This project follows [Semantic Versioning](https://semver.org).

## 2.0.0

- **Renamed from HyprPrice to PriceBar.** The plugin ID is now `humblemane/pricebar` and the repository is
  `github.com/humblemane/pricebar`. Existing setups need the new ID in the bar layout (`humblemane/pricebar:price`),
  in `noctalia msg` commands and in keybinds.
- Smaller panel (320×320). Search is now a magnifier button in the header that opens a dropdown of results.
- Click the price to switch between USD and EUR. An asset with no EUR pair on Kraken falls back to USD and shows a
  notice instead of `--`.
- Monero now uses the official full-color symbol from the Monero press kit.
- New panel screenshot and store thumbnail.

## 1.3.2

- Manifest and README brought in line with the Noctalia community store rules: allowed tags, a description under 120
  characters, and the store's README structure.

## 1.3.1

- The panel's change percentage now uses the same green/red as the bar (it was following the theme's accent).
- Added a panel screenshot to the README and a `thumbnail.webp` for the plugin store.

## 1.3.0

- Polished the project: rewritten README with screenshots, `CONTRIBUTING.md`, this changelog, issue templates, and an
  offline consistency check (`tools/check.py`).

## 1.2.0

- Logos now come only from open-licensed sources (CC0 / MIT); every file is attributed in `assets/logos/SOURCES.md`.
  Assets without a logo show their ticker instead.
- Removed unused glyph data and state.

## 1.1.1

- Switching assets clears the previous asset's price, change and chart, so an old price never shows under a new logo
  (for example while offline).

## 1.1.0

- 52 stocks via Yahoo Finance alongside the 33 coins, with a fuzzy, scrollable search across both.
- Real logos in the bar and panel header.
- "Set as default" button; the default is saved in the plugin's data directory.
- USD / EUR toggle works for stocks (converted with Kraken's EUR/USD rate).
- Green/red ▲/▼ percentage change on the bar.
- "Updated Ns ago" line in the panel, red when a poll fails.
- 24h / 7d / 30d chart timeframe toggle.
- Manifest: `plugin_api` raised to 24 (required for `require` and argument-array `runAsync`); `xdg-open` declared as
  a dependency.

## 1.0.0

- First release: bar widget and chart panel for Monero and other coins, priced from Kraken's public API.

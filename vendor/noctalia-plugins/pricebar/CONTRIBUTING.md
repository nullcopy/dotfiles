# Contributing

Thanks for helping. PriceBar is a small [Noctalia](https://noctalia.dev) plugin written in
[Luau](https://luau.org); bug reports, new assets and fixes are all welcome.

## Layout

| Path | What it is |
| --- | --- |
| `plugin.toml` | Manifest: id, settings, and the three entries |
| `service.luau` | Background service: fetches prices from Kraken / Yahoo, publishes state |
| `bar.luau` | Bar widget: renders the price and change |
| `chart.luau` | Dropdown panel: chart, search, buttons |
| `lib/coins.luau` | The list of coins and stocks |
| `assets/logos/` | Logos, each attributed in `SOURCES.md` |
| `tools/check.py` | Offline consistency checks |

The three entries are separate VMs that share data only through `noctalia.state`; the panel talks back to the service
with `noctalia msg plugin …` (see the IPC section of the README).

## Develop

```sh
git clone https://github.com/humblemane/pricebar ~/.local/share/noctalia/plugins/pricebar
noctalia msg plugins enable humblemane/pricebar
```

Edits to `.luau` files hot-reload; after changing `plugin.toml` run `noctalia msg config-reload`. Before opening a PR:

```sh
noctalia plugins lint .
python3 tools/check.py
```

Service logs go to `~/.cache/noctalia/noctalia.log` (search for `pricebar`).

## Adding a coin or stock

1. Confirm the data source resolves it:
   - Coin: `curl -s "https://api.kraken.com/0/public/Ticker?pair=<BASE>USD"` (Kraken's ticker, e.g. `XBT` for Bitcoin)
   - Stock: `curl -s -A "Mozilla/5.0" "https://query1.finance.yahoo.com/v8/finance/chart/<TICKER>?range=1d&interval=5m"`
2. Add a line to `lib/coins.luau` (`id`, `symbol`, `name`, `base`, `color`; add `kind = "stock"` for stocks). Symbols
   must be unique because logo filenames come from them.
3. Optional logo: a square PNG, `assets/logos/<symbol lowercase>.png`, from a source whose license allows
   redistribution (CC0, MIT, etc.). **Do not add logos whose license you can't point to.** Add the file to the right row
   of `assets/logos/SOURCES.md`. Without a logo the ticker is shown.
4. Update the counts in the README and add a `CHANGELOG.md` line. `python3 tools/check.py` tells you what's out of sync.

## Pull requests

- Keep changes focused, and describe what you tested (which assets, which currency and timeframe).
- Match the surrounding style; comments only where the reason isn't obvious.
- The plugin is trusted, unsandboxed code: no obfuscation, no downloading or executing remote code, and mention any new
  network call, file write or process in the README's "What it touches" section.

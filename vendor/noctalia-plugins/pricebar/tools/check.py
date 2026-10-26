#!/usr/bin/env python3
"""Offline consistency checks for PriceBar. Run from anywhere: python3 tools/check.py

Verifies the manifest, translations, asset list and logo attribution agree with
each other. It makes no network calls; use the curl commands in the README to
confirm a new asset resolves on Kraken or Yahoo Finance.
"""
import json
import re
import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
errors: list[str] = []


def fail(msg: str) -> None:
    errors.append(msg)


manifest = tomllib.loads((ROOT / "plugin.toml").read_text())
translations = json.loads((ROOT / "translations" / "en.json").read_text())


def lookup(key: str) -> bool:
    node = translations
    for part in key.split("."):
        if not isinstance(node, dict) or part not in node:
            return False
        node = node[part]
    return isinstance(node, str)


# Manifest
for field in ("id", "name", "version", "plugin_api", "author", "license", "description"):
    if field not in manifest:
        fail(f"plugin.toml: missing `{field}`")
if manifest.get("id", "").split("/")[0] != manifest.get("author"):
    fail("plugin.toml: id prefix should match author")

for setting in manifest.get("setting", []):
    for key in ("label_key", "description_key"):
        if key in setting and not lookup(setting[key]):
            fail(f"translations: missing `{setting[key]}` (setting `{setting['key']}`)")
    for option in setting.get("options", []):
        if not lookup(option["label_key"]):
            fail(f"translations: missing `{option['label_key']}`")

for kind in ("widget", "service", "panel"):
    for entry in manifest.get(kind, []):
        if not (ROOT / entry["entry"]).is_file():
            fail(f"plugin.toml: entry file `{entry['entry']}` does not exist")

# Assets
coins_src = (ROOT / "lib" / "coins.luau").read_text()
entries = re.findall(r"^\s*\{ id = \"([^\"]+)\", symbol = \"([^\"]+)\".*\},$", coins_src, re.M)
ids = [e[0] for e in entries]
symbols = [e[1] for e in entries]
stocks = len(re.findall(r'^\s*\{ id = .*kind = "stock" \},$', coins_src, re.M))
crypto = len(entries) - stocks

if len(set(ids)) != len(ids):
    fail("lib/coins.luau: duplicate ids")
if len(set(symbols)) != len(symbols):
    fail("lib/coins.luau: duplicate symbols (logo paths are derived from the symbol)")
for line in re.findall(r"^\s*\{ id = .*\},$", coins_src, re.M):
    if not re.search(r'base = "[^"]+"', line):
        fail(f"lib/coins.luau: missing base: {line.strip()[:60]}")
    if not re.search(r'color = "#[0-9A-Fa-f]{6}"', line):
        fail(f"lib/coins.luau: missing/invalid color: {line.strip()[:60]}")
default = next((s["default"] for s in manifest.get("setting", []) if s["key"] == "coin"), None)
if default not in ids:
    fail(f"plugin.toml: default coin `{default}` is not in lib/coins.luau")

# Logos
logos = {p.stem for p in (ROOT / "assets" / "logos").glob("*.png")}
known = {s.lower() for s in symbols}
for stem in sorted(logos - known):
    fail(f"assets/logos/{stem}.png has no matching asset symbol")
sources = (ROOT / "assets" / "logos" / "SOURCES.md").read_text()
listed = set(re.findall(r"`([a-z0-9-]+)`", sources))
for stem in sorted(logos - listed):
    fail(f"assets/logos/{stem}.png is not attributed in SOURCES.md")
for stem in sorted(listed - logos):
    fail(f"SOURCES.md lists `{stem}` but assets/logos/{stem}.png does not exist")

# README claims
readme = (ROOT / "README.md").read_text()
if f"{crypto} coins" not in readme or f"{stocks} stocks" not in readme:
    fail(f"README.md should say {crypto} coins and {stocks} stocks")
if manifest.get("version") not in (ROOT / "CHANGELOG.md").read_text():
    fail("CHANGELOG.md has no entry for the current version")

if errors:
    print("\n".join(f"FAIL {e}" for e in errors))
    sys.exit(1)
print(f"ok: {crypto} coins, {stocks} stocks, {len(logos)} logos, manifest v{manifest['version']}")

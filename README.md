# codex-app-bin

Unofficial Arch Linux packaging for the OpenAI Codex desktop app.

This repo repackages the upstream macOS DMG into a native Arch package by:
- reusing the shipped app assets
- rebuilding the Linux native modules against the matching Electron version
- swapping in the Linux Codex CLI runtime
- patching the desktop bundle so the editor picker includes Linux targets

## Installation

Build and install from the repo root with:

```bash
makepkg -si
```

If you prefer the helper wrapper, it runs the same flow:

```bash
./packaging-tools/build.sh -si
```

After installation, launch the app with:

```bash
codex-app
```
Fixes the ide picker (rephrase)

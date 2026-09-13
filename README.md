# codex-app-linux

Arch Linux packaging for OpenAI's official Linux desktop application. OpenAI
publishes the application as **ChatGPT**, with Codex included.

The package directly repacks OpenAI's official Fedora RPM. It does not modify
the application bundle or install OpenAI's Fedora package repository.

## Installation

Build and install from the repository root:

```bash
makepkg -si
```

Launch the application with:

```bash
chatgpt
```

`codex-app` remains available as a compatibility alias for installations made
from earlier versions of this repository.

The official Linux preview supports XWayland by default. To request native
Wayland explicitly, run:

```bash
chatgpt --ozone-platform=wayland
```

## Updating

`packaging-tools/update.sh` reads OpenAI's RPM repository metadata, updates the
package version and checksum, regenerates `.SRCINFO`, and builds the new
package.

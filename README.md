# codex-app-linux

Arch Linux packaging for OpenAI's official Linux desktop application. OpenAI
publishes the application as **ChatGPT**, with Codex included.

The package directly repacks OpenAI's official Fedora RPM. It does not modify
the application bundle or install OpenAI's Fedora package repository.

## Installation

Build and install from the repository root:

```bash
./packaging-tools/build.sh -si
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

Close the application, then run as your normal user:

```bash
./packaging-tools/update.sh
```

The script reads OpenAI's RPM repository metadata, updates the package version
and checksum, regenerates `.SRCINFO`, and builds and installs the package through
`makepkg`. Pacman prompts for elevated privileges when needed. There is no need
to uninstall the existing package first.

Check the installed version with:

```bash
pacman -Q codex-app-bin
```

## Project files and build output

`PKGBUILD` defines the Arch package; `.SRCINFO` contains its generated metadata.
`packaging-tools/update.sh` refreshes them from the official RPM repository.

The build and update scripts keep generated files under the Git-ignored
`build/` directory:

- `build/sources/`: downloaded RPMs.
- `build/packages/`: installable Arch packages.
- `build/work/`: temporary extraction and packaging directories.
- `build/source-packages/`: source archives, when requested.
- `build/logs/`: build logs, when requested.

`build/work/` can be removed after a successful build. Keep the current Arch
package if you want a local copy for reinstallation. Older downloads and packages
can be removed when you no longer need them for rollback.

Use the scripts above to keep this layout; running `makepkg` directly uses your
normal makepkg output settings instead.

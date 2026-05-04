#!/bin/sh
set -eu

appdir='/opt/codex-app'

export ELECTRON_FORCE_IS_PACKAGED="${ELECTRON_FORCE_IS_PACKAGED:-1}"
export ELECTRON_OZONE_PLATFORM_HINT="${ELECTRON_OZONE_PLATFORM_HINT:-auto}"
export CODEX_CLI_PATH="${CODEX_CLI_PATH:-$appdir/resources/codex}"

exec "$appdir/electron" "$appdir/resources/app.asar" "$@"

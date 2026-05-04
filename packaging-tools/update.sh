#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"

extract_pkgbuild_var() {
  local name="$1"
  sed -n "s/^${name}=//p" PKGBUILD | head -n1 | tr -d "'"
}

update_pkgbuild_var() {
  local name="$1"
  local value="$2"
  sed -i -E "s|^${name}=.*|${name}=${value}|" PKGBUILD
}

extract_plist_string() {
  local plist_path="$1"
  local key="$2"
  awk -v key="$key" '
    $0 ~ "<key>" key "</key>" {
      getline
      if (match($0, /<string>([^<]+)<\/string>/)) {
        value = $0
        sub(/^.*<string>/, "", value)
        sub(/<\/string>.*$/, "", value)
        print value
        exit
      }
    }
  ' "$plist_path"
}

extract_codex_cli_version() {
  local codex_bin="$1"
  strings -n 8 "$codex_bin" \
    | grep -Eo '0\.[0-9]+\.[0-9]+' \
    | sort -Vu \
    | tail -n1
}

extract_app_runtime_versions() {
  local app_dir="$1"
  python - <<'PY' "$app_dir"
from pathlib import Path
import json
import shlex
import sys


def emit(name: str, value: str) -> None:
    print(f"{name}={shlex.quote(value)}")


root = Path(sys.argv[1])
package = json.loads((root / "package.json").read_text())
better_sqlite3 = json.loads((root / "node_modules" / "better-sqlite3" / "package.json").read_text())
node_pty = json.loads((root / "node_modules" / "node-pty" / "package.json").read_text())

emit("pkgver", package["version"])
emit("electron_ver", package["devDependencies"]["electron"].lstrip("^~"))
emit("better_sqlite3_ver", better_sqlite3["version"])
emit("node_pty_ver", node_pty["version"])
PY
}

dmg_url="$(extract_pkgbuild_var "_codex_dmg_url")"
dmg_path="$repo_dir/Codex-latest-x64.dmg"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

# Force a fresh upstream fetch so the package is rebuilt from the latest DMG.
rm -f "$dmg_path"
rm -f "$repo_dir"/codex-app-bin-*

curl -L --fail --silent --show-error "$dmg_url" -o "$dmg_path"
7z x -y "$dmg_path" -o"$tmp_dir" >/dev/null

plist_path="$tmp_dir/Codex Installer/Codex.app/Contents/Info.plist"
codex_bin="$tmp_dir/Codex Installer/Codex.app/Contents/Resources/codex"
app_resources="$tmp_dir/Codex Installer/Codex.app/Contents/Resources"
app_dir="$tmp_dir/app"

asar extract "$app_resources/app.asar" "$app_dir" >/dev/null

eval "$(extract_app_runtime_versions "$app_dir")"
plist_pkgver="$(extract_plist_string "$plist_path" "CFBundleShortVersionString")"
codex_cli_ver="$(extract_codex_cli_version "$codex_bin")"

if [[ -z "$pkgver" || -z "$plist_pkgver" || -z "$electron_ver" || -z "$better_sqlite3_ver" || -z "$node_pty_ver" || -z "$codex_cli_ver" ]]; then
  printf 'failed to extract embedded runtime versions from %s\n' "Codex-latest-x64.dmg" >&2
  exit 1
fi

if [[ "$pkgver" != "$plist_pkgver" ]]; then
  printf 'version mismatch in %s: package.json=%s Info.plist=%s\n' "Codex-latest-x64.dmg" "$pkgver" "$plist_pkgver" >&2
  exit 1
fi

update_pkgbuild_var "pkgver" "$pkgver"
update_pkgbuild_var "_electron_ver" "$electron_ver"
update_pkgbuild_var "_codex_cli_ver" "$codex_cli_ver"
update_pkgbuild_var "_better_sqlite3_ver" "$better_sqlite3_ver"
update_pkgbuild_var "_node_pty_ver" "$node_pty_ver"

updpkgsums
makepkg --printsrcinfo > .SRCINFO
"$repo_dir/packaging-tools/build.sh" -C -f -si "$@"

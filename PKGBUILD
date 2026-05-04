pkgname=codex-app-bin
pkgver=26.429.30905
_electron_ver=41.2.0
_codex_cli_ver=0.128.0
_better_sqlite3_ver=12.8.0
_node_pty_ver=1.1.0
_codex_dmg_url='https://persistent.oaistatic.com/codex-app-prod/Codex-latest-x64.dmg'
pkgrel=7
pkgdesc="Unofficial Arch Linux package for the OpenAI Codex desktop app"
arch=('x86_64')
url='https://openai.com/codex'
license=('custom')
depends=(
  'alsa-lib'
  'at-spi2-core'
  'cairo'
  'cups'
  'dbus'
  'expat'
  'gcc-libs'
  'glib2'
  'gtk3'
  'libdrm'
  'libnotify'
  'libsecret'
  'libx11'
  'libxcb'
  'libxcomposite'
  'libxdamage'
  'libxext'
  'libxfixes'
  'libxkbcommon'
  'libxrandr'
  'nspr'
  'nss'
  'pango'
  'xdg-utils'
)
makedepends=(
  'asar'
  'node-gyp'
  'nodejs'
  '7zip'
  'python-pillow'
)
provides=('codex-app')
conflicts=('codex-app')
options=(
  '!debug'
  '!strip'
)
source=(
  "Codex-latest-x64.dmg::${_codex_dmg_url}"
  "electron-v${_electron_ver}-linux-x64.zip::https://github.com/electron/electron/releases/download/v${_electron_ver}/electron-v${_electron_ver}-linux-x64.zip"
  "better-sqlite3-${_better_sqlite3_ver}.tgz::https://registry.npmjs.org/better-sqlite3/-/better-sqlite3-${_better_sqlite3_ver}.tgz"
  "node-pty-${_node_pty_ver}.tgz::https://registry.npmjs.org/node-pty/-/node-pty-${_node_pty_ver}.tgz"
  "codex-${_codex_cli_ver}-linux-x64.tgz::https://registry.npmjs.org/@openai/codex/-/codex-${_codex_cli_ver}-linux-x64.tgz"
  'codex-app.sh'
  'codex-app.desktop'
  'patch-linux-editor-targets.py'
)
noextract=(
  'Codex-latest-x64.dmg'
  "electron-v${_electron_ver}-linux-x64.zip"
  "better-sqlite3-${_better_sqlite3_ver}.tgz"
  "node-pty-${_node_pty_ver}.tgz"
  "codex-${_codex_cli_ver}-linux-x64.tgz"
)
sha256sums=('d28760f9336b0eeda78330d54e6a5b82769bf31e857f05434ec44a8846a95f02'
            'fb0b31f5bb2b248d571c08ab57437c08a69b57f63ccdf9e55d6692b6132848d4'
            '2602a5726d0a9d8e6be407c59bc125e605110eda8e3b04e7ef8d6ddf762c9122'
            'c7517f19083ddcb05f276904680eb2b11a6b5ecab778b8e4e5685a6d645b3f60'
            '21160b4f6af2f63e7879cd22c24c15a789683326f03cbf1ccee9a566d3835378'
            '94939fdc2de467415d16dcca126e5f7795943592ead4610ea44957dcc95ec689'
            'd746443e9e014e1ba3e1fc8382bb8b65175d325bab6351ff56c1078e7c6fd073'
            '6ae6b258a299d31e8e2906a3ce6c25ced59fe11d0f04070210ee66d41d5934b7')

_app_resources() {
  printf '%s\n' "$srcdir/_dmg/Codex Installer/Codex.app/Contents/Resources"
}

_prune_native_build_artifacts() {
  local module_dir="$1"
  shift

  local keep_dir="$module_dir/.pkg-keep"
  rm -rf "$keep_dir"
  mkdir -p "$keep_dir"

  local relpath
  for relpath in "$@"; do
    if [[ -e "$module_dir/$relpath" ]]; then
      install -Dm755 "$module_dir/$relpath" "$keep_dir/$relpath"
    fi
  done

  rm -rf "$module_dir/build" "$module_dir/node-addon-api"
  mkdir -p "$module_dir/build"
  cp -a "$keep_dir"/. "$module_dir/"
  rm -rf "$keep_dir"
}

_repack_app_asar() {
  local repack_dir="$srcdir/_asar_repack"

  rm -rf "$repack_dir"
  mkdir -p "$repack_dir"

  # Keep rebuilt Linux native modules in app.asar.unpacked and only replace app.asar.
  asar pack \
    --unpack '*.node' \
    --unpack-dir node_modules/node-pty \
    "$srcdir/_app" \
    "$repack_dir/app.asar"

  install -Dm644 "$repack_dir/app.asar" "$srcdir/_electron/resources/app.asar"
}

prepare() {
  cd "$srcdir"

  rm -rf _dmg _app _electron _codex_cli

  7z x -y "Codex-latest-x64.dmg" -o"_dmg" >/dev/null

  mkdir -p _electron
  bsdtar -xf "electron-v${_electron_ver}-linux-x64.zip" -C _electron

  asar extract "$(_app_resources)/app.asar" _app
  local main_bundle
  shopt -s nullglob
  local main_candidates=("$srcdir"/_app/.vite/build/main-*.js)
  shopt -u nullglob
  if (( ${#main_candidates[@]} != 1 )); then
    printf 'expected exactly one main bundle, found %d\n' "${#main_candidates[@]}" >&2
    return 1
  fi
  main_bundle="${main_candidates[0]}"
  python "$srcdir/patch-linux-editor-targets.py" "$main_bundle"

  cp -a "$(_app_resources)/app.asar" _electron/resources/app.asar
  cp -a "$(_app_resources)/app.asar.unpacked" _electron/resources/app.asar.unpacked

  rm -rf _electron/resources/app.asar.unpacked/node_modules/better-sqlite3
  rm -rf _electron/resources/app.asar.unpacked/node_modules/node-pty
  mkdir -p _electron/resources/app.asar.unpacked/node_modules/better-sqlite3
  mkdir -p _electron/resources/app.asar.unpacked/node_modules/node-pty

  bsdtar -xf "better-sqlite3-${_better_sqlite3_ver}.tgz" \
    -C _electron/resources/app.asar.unpacked/node_modules/better-sqlite3 \
    --strip-components=1
  bsdtar -xf "node-pty-${_node_pty_ver}.tgz" \
    -C _electron/resources/app.asar.unpacked/node_modules/node-pty \
    --strip-components=1

  cp -a _app/node_modules/node-addon-api \
    _electron/resources/app.asar.unpacked/node_modules/

  mkdir -p _codex_cli
  bsdtar -xf "codex-${_codex_cli_ver}-linux-x64.tgz" -C _codex_cli --strip-components=1
}

build() {
  cd "$srcdir"

  local unpacked="$srcdir/_electron/resources/app.asar.unpacked/node_modules"
  local gyp_cache="$srcdir/_node_gyp"
  (
    cd "$unpacked/better-sqlite3"
    env \
      npm_config_runtime=electron \
      npm_config_target="${_electron_ver}" \
      npm_config_disturl='https://electronjs.org/headers' \
      npm_config_build_from_source=true \
      npm_config_devdir="$gyp_cache" \
      node-gyp rebuild --release
  )

  (
    cd "$unpacked/node-pty"
    env \
      npm_config_runtime=electron \
      npm_config_target="${_electron_ver}" \
      npm_config_disturl='https://electronjs.org/headers' \
      npm_config_build_from_source=true \
      npm_config_devdir="$gyp_cache" \
      node-gyp rebuild
  )
  rm -rf "$unpacked/node-addon-api"
  _prune_native_build_artifacts \
    "$unpacked/better-sqlite3" \
    "build/Release/better_sqlite3.node"
  _prune_native_build_artifacts \
    "$unpacked/node-pty" \
    "build/Release/pty.node" \
    "build/Release/spawn-helper"

  _repack_app_asar

  install -Dm755 \
    "$srcdir/_codex_cli/vendor/x86_64-unknown-linux-musl/codex/codex" \
    "$srcdir/_electron/resources/codex"
  install -Dm755 \
    "$srcdir/_codex_cli/vendor/x86_64-unknown-linux-musl/path/rg" \
    "$srcdir/_electron/resources/rg"

  local notification_asset="$(_app_resources)/notification.wav"
  if [[ ! -f "$notification_asset" ]]; then
    notification_asset="$(_app_resources)/codex-notification.wav"
  fi

  cp -a "$(_app_resources)/plugins" "$srcdir/_electron/resources/"
  install -Dm644 "$notification_asset" "$srcdir/_electron/resources/notification.wav"
  install -Dm644 "$(_app_resources)/codexTemplate.png" "$srcdir/_electron/resources/codexTemplate.png"
  install -Dm644 "$(_app_resources)/codexTemplate@2x.png" "$srcdir/_electron/resources/codexTemplate@2x.png"

  chmod 4755 "$srcdir/_electron/chrome-sandbox"

  python - <<'PY'
from pathlib import Path
from PIL import Image

src = Path.cwd() / "_dmg" / "Codex Installer" / "Codex.app" / "Contents" / "Resources" / "electron.icns"
dst = Path.cwd() / "codex-app.png"

with Image.open(src) as img:
    icon = img.convert("RGBA")
    if icon.size != (512, 512):
        icon = icon.resize((512, 512), Image.Resampling.LANCZOS)
    icon.save(dst)
PY
}

package() {
  cd "$srcdir"

  install -dm755 "$pkgdir/opt/codex-app"
  cp -a _electron/. "$pkgdir/opt/codex-app/"

  install -Dm755 codex-app.sh "$pkgdir/usr/bin/codex-app"
  install -Dm644 codex-app.desktop "$pkgdir/usr/share/applications/codex-app.desktop"
  install -Dm644 codex-app.png "$pkgdir/usr/share/icons/hicolor/512x512/apps/codex-app.png"

  install -Dm644 _electron/LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE.electron"
  install -Dm644 "$(_app_resources)/THIRD_PARTY_NOTICES.txt" \
    "$pkgdir/usr/share/licenses/$pkgname/THIRD_PARTY_NOTICES.txt"
}

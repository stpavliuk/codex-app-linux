pkgname=codex-app-bin
pkgver=26.908.40834
_rpmrel=1
pkgrel=1
pkgdesc="Official OpenAI ChatGPT desktop app with Codex, repackaged for Arch Linux"
arch=('x86_64')
url='https://developers.openai.com/codex/app'
license=('custom')
depends=(
  'alsa-lib'
  'at-spi2-core'
  'cairo'
  'cups'
  'dbus'
  'expat'
  'gcc-libs'
  'gdk-pixbuf2'
  'glib2'
  'glibc'
  'gtk3'
  'libdrm'
  'libglvnd'
  'libnotify'
  'libusb'
  'libx11'
  'libxcb'
  'libxcomposite'
  'libxdamage'
  'libxext'
  'libxfixes'
  'libxkbcommon'
  'libxrandr'
  'mesa'
  'nspr'
  'nss'
  'pango'
  'systemd-libs'
  'xdg-utils'
)
optdepends=(
  'apparmor: load the packaged profile on AppArmor-enabled systems'
  'bubblewrap: preferred sandbox helper for Codex commands'
  'git: Git repository integration'
)
provides=('codex-app' 'chatgpt')
conflicts=('codex-app' 'chatgpt')
options=('!debug' '!strip')
source=(
  "chatgpt-${pkgver}-${_rpmrel}.x86_64.rpm::https://persistent.oaistatic.com/codex-app-prod/linux/rpm/x86_64/chatgpt-${pkgver}-${_rpmrel}.x86_64.rpm"
)
sha256sums=('fc63bde0c514e2066d2ce213ec5f1bf59622f436cb7721561a5f923aeacf3657')

package() {
  cd "$srcdir"

  # The RPM contains a complete native Linux build. Keep its layout and
  # symlinks intact, but leave Fedora's repository configuration out.
  cp -a --no-preserve=ownership usr "$pkgdir/"

  install -Dm644 etc/apparmor.d/chatgpt \
    "$pkgdir/etc/apparmor.d/chatgpt"

  # Preserve the command used by older versions of this Arch package.
  ln -s chatgpt "$pkgdir/usr/bin/codex-app"

  install -Dm644 usr/lib/chatgpt/LICENSE \
    "$pkgdir/usr/share/licenses/$pkgname/LICENSE.electron"
}

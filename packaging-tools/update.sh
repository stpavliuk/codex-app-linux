#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"

rpm_repo_url='https://persistent.oaistatic.com/codex-app-prod/linux/rpm/x86_64'
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

update_pkgbuild_var() {
  local name="$1"
  local value="$2"
  sed -i -E "s|^${name}=.*|${name}=${value}|" PKGBUILD
}

curl -L --fail --silent --show-error \
  "$rpm_repo_url/repodata/repomd.xml" \
  -o "$tmp_dir/repomd.xml"

primary_href="$(python - "$tmp_dir/repomd.xml" <<'PY'
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

root = ET.parse(Path(sys.argv[1])).getroot()
namespace = {"repo": "http://linux.duke.edu/metadata/repo"}
location = root.find("repo:data[@type='primary']/repo:location", namespace)
if location is None or not location.get("href"):
    raise SystemExit("primary metadata location is missing from repomd.xml")
print(location.get("href"))
PY
)"

curl -L --fail --silent --show-error \
  "$rpm_repo_url/$primary_href" \
  -o "$tmp_dir/primary.xml.gz"

eval "$(python - "$tmp_dir/primary.xml.gz" <<'PY'
from pathlib import Path
import gzip
import shlex
import sys
import xml.etree.ElementTree as ET

namespace = {"common": "http://linux.duke.edu/metadata/common"}
with gzip.open(Path(sys.argv[1]), "rb") as stream:
    root = ET.parse(stream).getroot()

matches = []
for package in root.findall("common:package", namespace):
    name = package.findtext("common:name", namespaces=namespace)
    arch = package.findtext("common:arch", namespaces=namespace)
    if name == "chatgpt" and arch == "x86_64":
        matches.append(package)

if len(matches) != 1:
    raise SystemExit(f"expected one x86_64 chatgpt package, found {len(matches)}")

package = matches[0]
version = package.find("common:version", namespace)
checksum = package.find("common:checksum", namespace)
location = package.find("common:location", namespace)
if version is None or checksum is None or location is None:
    raise SystemExit("incomplete package metadata")
if checksum.get("type") != "sha256":
    raise SystemExit(f"unsupported checksum type: {checksum.get('type')}")

values = {
    "upstream_pkgver": version.get("ver"),
    "upstream_rpmrel": version.get("rel"),
    "upstream_sha256": checksum.text,
    "upstream_location": location.get("href"),
}
if any(not value for value in values.values()):
    raise SystemExit("empty field in package metadata")

for name, value in values.items():
    print(f"{name}={shlex.quote(value)}")
PY
)"

expected_location="chatgpt-${upstream_pkgver}-${upstream_rpmrel}.x86_64.rpm"
if [[ "$upstream_location" != "$expected_location" ]]; then
  printf 'unexpected RPM location: %s (expected %s)\n' \
    "$upstream_location" "$expected_location" >&2
  exit 1
fi

update_pkgbuild_var "pkgver" "$upstream_pkgver"
update_pkgbuild_var "_rpmrel" "$upstream_rpmrel"
update_pkgbuild_var "pkgrel" "1"
sed -i -E \
  "s|^sha256sums=.*|sha256sums=('${upstream_sha256}')|" \
  PKGBUILD

makepkg --printsrcinfo > .SRCINFO
"$repo_dir/packaging-tools/build.sh" -C -f -si "$@"

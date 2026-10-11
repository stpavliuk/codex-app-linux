#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"

export SRCDEST="$repo_dir/build/sources"
export PKGDEST="$repo_dir/build/packages"
export BUILDDIR="$repo_dir/build/work"
export SRCPKGDEST="$repo_dir/build/source-packages"
export LOGDEST="$repo_dir/build/logs"
mkdir -p "$SRCDEST" "$PKGDEST" "$BUILDDIR" "$SRCPKGDEST" "$LOGDEST"

exec makepkg "$@"

#!/usr/bin/env bash
# Runs as root on Arch Linux (normally inside the build container started by ../build.sh).
set -euo pipefail

: "${DUYOS_ROOT:?DUYOS_ROOT must point at the repository root}"
scripts="${DUYOS_ROOT}/source/scripts"

echo "==> [1/3] Updating build environment (archiso, base-devel, git)"
# Full -Syu: a partial upgrade (-Sy) breaks on older container images.
pacman -Syu --noconfirm --needed archiso base-devel git sudo

echo "==> [2/3] Building AUR packages into the local repository"
"${scripts}/build-aur.sh" "$@"

echo "==> [3/3] Assembling profile and building the ISO"
"${scripts}/build-iso.sh"

#!/usr/bin/env bash
# DuyOS build entry point.
#
#   ./source/build.sh            build inside an Arch Linux container (any distro with podman; asks for sudo)
#   ./source/build.sh --native   build directly on an Arch Linux host
#
# Options (both modes):
#   --rebuild-aur     rebuild the AUR packages even if build/localrepo already has them
#
# Output: out/duyos-<date>-x86_64.iso (+ .sha256), full log in out/build-<timestamp>.log
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
image="${DUYOS_BUILD_IMAGE:-docker.io/library/archlinux:latest}"
engine="${CONTAINER_ENGINE:-podman}"

native=0
args=()
for a in "$@"; do
    case "$a" in
        --native) native=1 ;;
        -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
        *) args+=("$a") ;;
    esac
done

# mkarchiso must mount /dev, /proc etc. inside the image's chroot, which rootless
# containers are not allowed to do, so the build runs as root (rootful podman).
if (( EUID != 0 )); then
    echo "==> mkarchiso needs root; re-running with sudo..."
    exec sudo --preserve-env=CONTAINER_ENGINE,DUYOS_BUILD_IMAGE "$0" "$@"
fi
# When started via sudo, give the build outputs back to the invoking user afterwards.
trap '[[ -n "${SUDO_UID:-}" ]] && chown -R "${SUDO_UID}:${SUDO_GID}" "${repo_root}/out" "${repo_root}/build" 2>/dev/null || true' EXIT

mkdir -p "${repo_root}/out"
log="${repo_root}/out/build-$(date +%Y%m%d-%H%M%S).log"
echo "==> Logging to ${log}"

if (( native )); then
    DUYOS_ROOT="${repo_root}" "${repo_root}/source/scripts/build-all.sh" "${args[@]}" 2>&1 | tee "${log}"
else
    command -v "${engine}" >/dev/null || { echo "${engine} not found (set CONTAINER_ENGINE=docker to use docker)" >&2; exit 1; }
    # --privileged: mkarchiso needs mount/loop/namespace operations to assemble the image.
    # --network=host: use the host's network/DNS directly (rootful podman's bridge DNS
    # can time out on some hosts, e.g. Fedora with systemd-resolved).
    "${engine}" run --rm --privileged --network=host \
        -v "${repo_root}:/duyos:z" \
        -e DUYOS_ROOT=/duyos \
        "${image}" \
        /duyos/source/scripts/build-all.sh "${args[@]}" 2>&1 | tee "${log}"
fi

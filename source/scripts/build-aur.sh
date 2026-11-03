#!/usr/bin/env bash
# Builds the AUR packages listed in source/aur-packages.txt (plus every AUR-only
# dependency they pull in) and publishes them as the local pacman repo [duyos-aur].
#
# makepkg refuses to run as root, so the build happens as an unprivileged "builder"
# user using the yay AUR helper, which resolves the AUR dependency chain for us.
set -euo pipefail

: "${DUYOS_ROOT:?}"
localrepo="${DUYOS_ROOT}/build/localrepo"
pkg_list="${DUYOS_ROOT}/source/aur-packages.txt"
mapfile -t aur_pkgs < <(grep -vE '^\s*(#|$)' "${pkg_list}")

rebuild=0
[[ "${1:-}" == "--rebuild-aur" ]] && rebuild=1

# Skip if every requested package is already in the repo (speeds up iteration).
if (( ! rebuild )) && [[ -f "${localrepo}/duyos-aur.db.tar.gz" ]]; then
    missing=0
    for p in "${aur_pkgs[@]}"; do
        compgen -G "${localrepo}/${p}-[0-9r]*.pkg.tar.zst" >/dev/null || missing=1
    done
    if (( ! missing )); then
        echo "    local repo already contains: ${aur_pkgs[*]} (use --rebuild-aur to force)"
        exit 0
    fi
fi

# Unprivileged build user with passwordless sudo (yay installs build deps via pacman).
id builder &>/dev/null || useradd -m builder
echo 'builder ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/builder
# Parallel compilation; skip -debug split packages.
cat > /etc/makepkg.conf.d/duyos.conf <<EOF
MAKEFLAGS="-j$(nproc)"
OPTIONS=(strip docs !libtool !staticlibs emptydirs zipman purge !debug lto)
EOF

as_builder() { sudo -u builder -H bash -c "$*"; }

if ! command -v yay >/dev/null; then
    echo "    bootstrapping yay"
    as_builder 'rm -rf ~/yay-bin && git clone --depth 1 https://aur.archlinux.org/yay-bin.git ~/yay-bin \
                && cd ~/yay-bin && makepkg -si --noconfirm'
fi

echo "    building: ${aur_pkgs[*]}"
as_builder "mkdir -p ~/aur-build && yay -S --noconfirm --needed --answerdiff None --answerclean All --removemake \
            --builddir ~/aur-build ${aur_pkgs[*]}"

echo "    publishing packages to ${localrepo}"
rm -rf "${localrepo}"
mkdir -p "${localrepo}"
find /home/builder/aur-build -name '*.pkg.tar.zst' ! -name '*-debug-*' -exec cp -t "${localrepo}" {} +
repo-add -q "${localrepo}/duyos-aur.db.tar.gz" "${localrepo}"/*.pkg.tar.zst

# Record exactly which AUR package versions went into this build (for reproducibility).
( cd "${localrepo}" && ls -1 ./*.pkg.tar.zst | sed 's|^\./||' ) > "${DUYOS_ROOT}/build/aur-manifest.txt"
echo "    AUR packages built:"
sed 's/^/      /' "${DUYOS_ROOT}/build/aur-manifest.txt"

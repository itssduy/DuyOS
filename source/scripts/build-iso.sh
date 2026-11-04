#!/usr/bin/env bash
# Assembles the final archiso profile in build/profile and runs mkarchiso.
#
# The committed profile (source/profile) holds everything DuyOS-specific. At build
# time we add two generated pieces to a *copy* of it, so the source tree stays clean:
#   1. Caelestia's upstream dotfiles (Hyprland Lua config, foot, fish, btop, micro),
#      pinned to a known commit, copied into /etc/skel/.config.
#   2. The real path of the local AUR repo, substituted into pacman.conf.
set -euo pipefail

: "${DUYOS_ROOT:?}"
build="${DUYOS_ROOT}/build"
out="${DUYOS_ROOT}/out"
profile="${build}/profile"

# Pinned Caelestia dotfiles commit (github.com/caelestia-dots/caelestia, 2026-11-03).
CAELESTIA_DOTS_REPO="https://github.com/caelestia-dots/caelestia.git"
CAELESTIA_DOTS_COMMIT="${CAELESTIA_DOTS_COMMIT:-01d2df329240be60148d25804690779a078c6378}"
dots_components=(hypr foot fish btop micro)

echo "    fetching Caelestia dotfiles @ ${CAELESTIA_DOTS_COMMIT:0:12}"
dots="${build}/caelestia-dots"
# build/ is handed back to the invoking user after each run, but this script runs as
# root, so tell git the checkout is trusted (otherwise: "dubious ownership").
git config --global --get-all safe.directory | grep -qxF "${dots}" \
    || git config --global --add safe.directory "${dots}"
if [[ ! -d "${dots}/.git" ]]; then
    git clone --quiet "${CAELESTIA_DOTS_REPO}" "${dots}"
fi
git -C "${dots}" fetch --quiet origin
git -C "${dots}" checkout --quiet --force "${CAELESTIA_DOTS_COMMIT}"

echo "    assembling profile in ${profile}"
rm -rf "${profile}"
cp -a "${DUYOS_ROOT}/source/profile" "${profile}"
skel_cfg="${profile}/airootfs/etc/skel/.config"
mkdir -p "${skel_cfg}"
for c in "${dots_components[@]}"; do
    # -n: never overwrite a DuyOS file with an upstream one.
    cp -rn "${dots}/${c}" "${skel_cfg}/"
done
sed -i "s|@LOCALREPO@|${build}/localrepo|" "${profile}/pacman.conf"

echo "    running mkarchiso"
mkdir -p "${out}"
rm -rf "${build}/work"
mkarchiso -v -r -w "${build}/work" -o "${out}" "${profile}"

iso="$(ls -t "${out}"/duyos-*.iso | head -n1)"
( cd "${out}" && sha256sum "$(basename "${iso}")" > "$(basename "${iso}").sha256" )
cp "${build}/aur-manifest.txt" "${out}/" 2>/dev/null || true
echo "==> Done: ${iso}"
cat "${iso}.sha256"

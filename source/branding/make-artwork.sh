#!/usr/bin/env bash
# Regenerates the DuyOS BIOS boot menu splash with ImageMagick 7 (`magick`).
# The output is committed to the repo, so you only need this if you change the design.
# (The desktop uses Caelestia's own default wallpaper.)
#
#   boot menu  -> profile/syslinux/splash.png   (640x480, BIOS menu background)
set -euo pipefail

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
profile="${here}/../profile"

# Use the first font file that exists (works on Fedora and Arch); override with FONT_BOLD.
pick_font() { for f in "$@"; do [[ -f "$f" ]] && { echo "$f"; return; }; done; echo "Sans"; }
FONT_BOLD="${FONT_BOLD:-$(pick_font \
  /usr/share/fonts/TTF/DejaVuSans-Bold.ttf \
  /usr/share/fonts/dejavu-sans-fonts/DejaVuSans-Bold.ttf \
  /usr/share/fonts/google-droid-sans-fonts/DroidSans-Bold.ttf \
  /usr/share/fonts/open-sans/OpenSans-Bold.ttf)}"

# DuyOS palette ("night sky"): deep indigo -> violet, soft cyan accent.
BG_TOP='#0b1026'
BG_BOTTOM='#2a1650'
ACCENT='#7dd3fc'

magick -size 640x480 "gradient:${BG_TOP}-${BG_BOTTOM}" \
  -gravity north -font "${FONT_BOLD}" -pointsize 64 -fill "${ACCENT}" -annotate +0+36 'DuyOS' \
  -depth 8 -type TrueColor "PNG24:${profile}/syslinux/splash.png"

echo "Wrote ${profile}/syslinux/splash.png"

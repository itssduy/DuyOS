#!/usr/bin/env bash
# Boots the newest DuyOS ISO in QEMU/KVM with a 3D-accelerated virtio GPU
# (Hyprland needs GPU acceleration; plain VGA/std graphics will not work).
#
#   ./source/run-vm.sh [path/to.iso] [--bios] [--window] [--res WxH] [--serial-log FILE]
#
# Defaults: UEFI firmware (OVMF), 4 vCPUs, 4 GiB RAM, virtio-vga-gl with an OpenGL GTK display,
# full screen at the host monitor's native resolution (so the image is not scaled/pixelated).
#   --window      open in a window instead of full screen (Ctrl+Alt+F toggles full screen)
#   --res WxH     guest resolution, e.g. --res 2560x1440 (default: detected native resolution)
# In the QEMU window: Ctrl+Alt+G releases the mouse/keyboard, Ctrl+Alt+F toggles full screen.
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
iso=""
uefi=1
serial_log=""
fullscreen=on
res=""
while (( $# )); do
    case "$1" in
        --bios) uefi=0 ;;
        --window) fullscreen=off ;;
        --res) res="$2"; shift ;;
        --serial-log) serial_log="$2"; shift ;;
        *) iso="$1" ;;
    esac
    shift
done

# Native resolution of the first connected display (e.g. laptop panel), else 1920x1080.
if [[ -z "${res}" ]]; then
    for c in /sys/class/drm/card*-*; do
        if [[ "$(cat "$c/status" 2>/dev/null)" == connected ]]; then
            res="$(head -n1 "$c/modes" 2>/dev/null)"; [[ -n "${res}" ]] && break
        fi
    done
    res="${res:-1920x1080}"
fi
xres="${res%x*}"; yres="${res#*x}"
iso="${iso:-$(ls -t "${repo_root}"/out/duyos-*.iso 2>/dev/null | head -n1 || true)}"
[[ -f "${iso}" ]] || { echo "No ISO found. Build one with ./source/build.sh or pass a path." >&2; exit 1; }

fw=()
if (( uefi )); then
    for f in /usr/share/edk2/ovmf/OVMF_CODE.fd /usr/share/edk2/x64/OVMF_CODE.4m.fd /usr/share/OVMF/OVMF_CODE.fd; do
        if [[ -f "$f" ]]; then fw=(-drive "if=pflash,format=raw,readonly=on,file=$f"); break; fi
    done
    (( ${#fw[@]} )) || { echo "OVMF not found (install edk2-ovmf), falling back to BIOS." >&2; }
fi

serial=(-serial none)
[[ -n "${serial_log}" ]] && serial=(-serial "file:${serial_log}")

echo "Booting ${iso} ($([[ ${#fw[@]} -gt 0 ]] && echo UEFI || echo BIOS), ${xres}x${yres}, fullscreen=${fullscreen})"
echo "Tip: Ctrl+Alt+F toggles full screen, Ctrl+Alt+G releases the mouse."
exec qemu-system-x86_64 \
    -enable-kvm -machine q35 -cpu host -smp 4 -m 4G \
    "${fw[@]}" \
    -cdrom "${iso}" -boot d \
    -device "virtio-vga-gl,xres=${xres},yres=${yres}" \
    -display "gtk,gl=on,full-screen=${fullscreen},zoom-to-fit=on" \
    -device virtio-net-pci,netdev=n0 -netdev user,id=n0 \
    -device intel-hda -device hda-duplex \
    -device virtio-tablet-pci -device virtio-keyboard-pci \
    "${serial[@]}"

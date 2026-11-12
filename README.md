# DuyOS

DuyOS is my own Linux distro for my "Build Your Own Linux Distribution" assignment. It's based on
Arch Linux and built with archiso, the official tool Arch uses to make its ISO. When you boot it, it
goes straight into a Hyprland desktop running the [Caelestia shell](https://github.com/caelestia-dots/shell).

![DuyOS desktop](demo/screenshots/04-desktop.png)

**Quick facts:**
- Based on Arch Linux (archiso's `releng` profile)
- Desktop: Hyprland + Caelestia shell
- Boots on both UEFI and BIOS
- Live login: user `duyos`, password `duyos`
- ISO is about 2.2 GB

## Why I made it this way

I've been running a very similar setup (Arch with Hyprland and Caelestia) on my own computer for a
while, so for this project I wanted to turn that into a distro anyone can boot. I wanted it to
actually look nice and be usable right away, instead of a bare terminal.

I went with **Arch + archiso** because I really like how configurable Arch is. You start small and
add exactly what you want, and that's basically what building a distro is. I also like **pacman**:
it's fast, simple, and makes it easy to add packages, which made picking the software for DuyOS
straightforward. archiso is also what Arch itself uses to build its ISO, so I knew it's maintained
and works. On top of that, Arch has the newest versions of Hyprland and the graphics drivers, which
a Wayland desktop like this needs.

For the desktop, I picked **Hyprland with Caelestia** because it's what I already use and like.
Caelestia gives you a full, good-looking setup (bar, app launcher, notifications, dashboard, lock
screen) on top of Hyprland.

I actually started with Fedora bootc first (it's in `old-bootc/`), but switched to archiso because
it's more of a real "build a distro" tool and gave me more control over the system.

## How to build it

You need Linux with **podman** installed, `sudo`, about 20 GB of free space and internet. I built
it on Fedora 44, but it runs inside an Arch container so it should work on any distro.

```bash
git clone https://github.com/itssduy/DuyOS.git
cd DuyOS
./source/build.sh
```

It'll ask for your sudo password (archiso needs root to build the image). The first build takes
about 30–60 minutes because it has to compile the Caelestia packages from the AUR. After that it's
around 10–15 minutes.

When it's done, the ISO is at `out/duyos-<date>-x86_64.iso`, along with a checksum and a build log.

What `build.sh` does, step by step:
1. Starts an Arch Linux container
2. Builds the AUR packages (Caelestia shell, Caelestia CLI, Quickshell and a few others) and puts
   them in a local package repo
3. Grabs Caelestia's config files at a fixed commit, so the build doesn't change if they update
4. Runs `mkarchiso` to build the ISO

If you're on Arch already, you can skip the container with `./source/build.sh --native`.

## How to run it

The easiest way is the QEMU script I made:

```bash
./source/run-vm.sh
```

It opens the newest ISO in a VM, full screen, with 3D graphics turned on.
**Ctrl+Alt+F** gets you out of full screen.

**Important:** Hyprland needs 3D acceleration, so if you use virt-manager or VirtualBox, turn it on:
- **virt-manager:** Video → Virtio with 3D acceleration, Display → OpenGL on, Firmware → UEFI
- **VirtualBox:** Graphics Controller → VMSVGA, Enable 3D Acceleration

If the desktop doesn't start, pick **"DuyOS live, text mode"** in the boot menu to get a working
terminal.

Some keys once you're in:
- **Super**: app launcher
- **Super+T**: terminal
- **Super+W**: Firefox
- **Super+E**: files
- **Super+Q**: close window
- **Super+/**: help screen with all the shortcuts

Note: it's a live system, so nothing you do is saved after you shut it down.

## What I changed

### Branding
- Named it **DuyOS** everywhere: `/etc/os-release`, the ISO name, the hostname, and all the boot
  menus (GRUB, systemd-boot and syslinux)
- Made my own boot splash for the BIOS menu (`source/branding/make-artwork.sh`)
- Custom welcome message in the terminal and a DuyOS logo in fastfetch
- Fun fact: `os-release` can't just be replaced, because an Arch package owns that file. So I wrote
  a small pacman hook that swaps it in during the build.

### Software I added
- **Hyprland + Caelestia shell**: the desktop
- **Firefox**: browser
- **Thunar**: file manager
- **foot**: terminal
- **btop**: system monitor
- **fastfetch**: system info with the DuyOS logo
- **micro**: simple text editor
- **git**, plus **fish** as the shell with starship, eza and zoxide
- **PipeWire** for audio and **NetworkManager** for internet

The full package list is in `source/profile/packages.x86_64` (my additions are at the bottom).

### System-level changes
1. **zram swap:** a live ISO runs entirely in RAM and has no swap, so the VM can run out of memory
   with Firefox open. I added compressed swap in RAM (`zram-generator.conf`), which basically gives
   you more memory to work with.
2. **Kernel tuning for zram:** in `sysctl.d/99-duyos.conf` I set `vm.swappiness=180` (the
   recommended value for zram) and a few other memory settings. I also added the kernel option
   `zswap.enabled=0`, so the kernel doesn't compress memory twice.
3. **Normal user instead of root:** the stock Arch ISO logs you in as root. DuyOS logs in as a
   regular user called `duyos` and starts the desktop automatically. I wrote a small script,
   `duyos-session`, that checks the graphics first and drops you to a terminal if Hyprland can't
   start, instead of just showing a black screen.
4. **NetworkManager instead of systemd-networkd:** Caelestia's network widget needs NetworkManager.
5. **SSH turned off:** the Arch ISO starts SSH by default, but the DuyOS password is public, so I
   disabled it.
6. **Faster image compression:** zstd instead of xz. The ISO is a bit bigger, but it loads faster.

### Caelestia config
I didn't edit Caelestia's own config files. Instead I used its override files
(`hypr-vars.lua`, `hypr-user.lua`) to:
- point it at apps I actually installed (its defaults use some apps I didn't include)
- turn the blur down so it runs smoother in a VM
- add two shortcuts: **Super+/** for help and **Super+Shift+B** for btop

## Project layout

```
source/
  build.sh         - builds the ISO
  run-vm.sh        - runs it in QEMU
  scripts/         - the actual build steps
  branding/        - makes the boot splash
  profile/         - the archiso profile (this is the distro itself)
demo/              - screenshots and build log
old-bootc/         - my first attempt with Fedora bootc
```

## Problems I ran into

- **Black screen in the VM:** Hyprland needs 3D graphics turned on in the VM.
- **QEMU looked blurry:** the VM started at a low resolution. `run-vm.sh` now uses your screen's
  real resolution.
- **Build couldn't mount `/dev`:** archiso needs root, so the build runs in a rootful container
  (that's why it asks for sudo).
- **No internet in the build container:** fixed by using the host's network.

## Credits

This wouldn't exist without these projects:
- [Arch Linux](https://archlinux.org) and [archiso](https://gitlab.archlinux.org/archlinux/archiso):
  the base system and the build tool (GPL-3.0)
- [Hyprland](https://hypr.land): the window manager (BSD-3-Clause)
- [Caelestia](https://github.com/caelestia-dots) shell, CLI and dotfiles: the desktop shell and
  its configs (GPL-3.0)
- [Quickshell](https://quickshell.org): what Caelestia is built with (LGPL-3.0)
- [yay](https://github.com/Jguer/yay): for building the AUR packages
- [QEMU](https://www.qemu.org): for testing it in a VM

I'm not affiliated with any of these. This is just a school project.

## License

GPL-3.0. See [LICENSE](LICENSE). It has to be GPL because my profile is based on archiso's
`releng` profile, which is GPL-3.0.

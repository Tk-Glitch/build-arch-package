#!/bin/bash -ex

if [ -z "$INPUT_PKGBUILD" ] || [ -z "$INPUT_OUTDIR" ] || [ -z "$GITHUB_SHA" ]; then
    echo 'Missing environment variables'
    exit 1
fi

# Resolve environment paths
INPUT_PKGBUILD="$(eval echo $INPUT_PKGBUILD)"
INPUT_OUTDIR="$(eval echo $INPUT_OUTDIR)"

# Get PKGBUILD dir
PKGBUILD_DIR=$(dirname $(readlink -f $INPUT_PKGBUILD))

# Prepare the environment
echo -e "[multilib]\nInclude = \/etc\/pacman\.d\/mirrorlist" >> /etc/pacman.conf
pacman -Syu --noconfirm --noprogressbar --needed base-devel devtools multilib-devel btrfs-progs dbus dbus-glib lib32-dbus lib32-dbus-glib sudo

dbus-uuidgen --ensure=/etc/machine-id

sed -i "s|MAKEFLAGS=.*|MAKEFLAGS=-j$(nproc)|" /etc/makepkg.conf

useradd -m user
cd /home/user

# Copy PKGBUILD and others
cp -r "$PKGBUILD_DIR"/* ./ || true
sed "s|%COMMIT%|$GITHUB_SHA|" "$INPUT_PKGBUILD" > PKGBUILD
chown user PKGBUILD
chown -R user ./*
mkdir -p "/home/user/.config/frogminer"
echo -e '_NOINITIALPROMPT="false"' > /home/user/.config/frogminer/wine-tkg.cfg

# Build the package
multilib-build -- -U user
#mkdir ~/chroot
#CHROOT=$HOME/chroot
#mkarchroot $CHROOT/root base-devel
#makechrootpkg -c -r -U user $CHROOT

# Save the artifacts
mkdir -p "$INPUT_OUTDIR"
cp *.pkg.* "$INPUT_OUTDIR"/

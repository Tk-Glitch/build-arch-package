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
cp -rv "$PKGBUILD_DIR"/* ./
#sed "s|%COMMIT%|$GITHUB_SHA|" "$INPUT_PKGBUILD" > PKGBUILD
chown user PKGBUILD
chown -R user ./*
mkdir -p "/home/user/.config/frogminer"
echo -e '_NOINITIALPROMPT="true"' > /home/user/.config/frogminer/wine-tkg.cfg

echo -e '_distro=""' > /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_EXT_CONFIG_PATH=~/.config/frogminer/linux58-tkg.cfg' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_NUKR="true"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e 'CUSTOM_GCC_PATH=""' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_OPTIPROFILE="1"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_force_all_threads="true"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_noccache="true"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_modprobeddb="false"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_menunconfig="false"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_diffconfig="false"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_diffconfig_name=""' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_configfile="config.x86_64"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_debugdisable="false"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_cpusched="upds"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_sched_yield_type="0"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_rr_interval="default"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_ftracedisable="false"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_numadisable="false"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_misc_adds="true"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_tickless="2"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_voluntary_preempt="false"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_OFenable="false"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_acs_override="false"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_zfsfix="true"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_fsync="true"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_zenify="true"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_compileroptlevel="1"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_processor_opt="generic"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_irq_threading="false"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_smt_nice="true"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_random_trust_cpu="false"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_runqueue_sharing="mc"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_timer_freq="500"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_default_cpu_gov="ondemand"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_aggressive_ondemand="true"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_disable_acpi_cpufreq="false"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_custom_commandline="intel_pstate=passive"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_custom_pkgbase=""' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_kernel_localversion=""' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_community_patches=""' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_user_patches="true"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_user_patches_no_confirm="false"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_config_fragments="false"' >> /home/user/.config/frogminer/linux58-tkg.cfg
echo -e '_config_fragments_no_confirm="false"' >> /home/user/.config/frogminer/linux58-tkg.cfg

#cd "$PKGBUILD_DIR"
chown -R user ./*
chmod +w -R *
#chmod +w -R "$SRCDEST"

# Build the package
#multilib-build -- -U user
#multilib-build
makechrootpkg -r /var/lib/archbuild/multilib-x86_64
#mkdir ~/chroot
#CHROOT=$HOME/chroot
#mkarchroot $CHROOT/root base-devel
#makechrootpkg -c -r -U user $CHROOT

# Save the artifacts
mkdir -p "$INPUT_OUTDIR"
cp *.pkg.* "$INPUT_OUTDIR"/

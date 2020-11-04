#!/bin/bash
set -euo pipefail

FILE="$(basename "$0")"

# Enable the multilib repository
cat << EOM >> /etc/pacman.conf
[multilib]
Include = /etc/pacman.d/mirrorlist
EOM

pacman -Syu --noconfirm base-devel git schedtool ccache

# Create miniglitch
useradd miniglitch -m
echo "miniglitch ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

cd .. && git clone --recurse-submodules https://github.com/Tk-Glitch/PKGBUILDS.git
  for _tkg_tools in */; do
    if [ "$_tkg_tools" != ".git" ]; then
      ( cd "$_tkg_tools" && git config pull.rebase false && git checkout master && git pull origin master )
    fi
  done
cd PKGBUILDS

# Get packages list from dir
cd "$INPUT_PKGBUILD"
chmod -R a+rw .
mapfile -t PKGFILES < <( sudo -u miniglitch makepkg --packagelist )
echo "Package(s): ${PKGFILES[*]}"

_userhome="/home/miniglitch"
_linuxcfg="$_userhome"/.config/frogminer/linux-tkg.cfg
_winecfg="$_userhome"/.config/frogminer/wine-tkg.cfg
_protoncfg="$_userhome"/.config/frogminer/proton-tkg.cfg

mkdir -p "$_userhome/.config/frogminer"

# wine/proton-tkg
echo -e '_NOINITIALPROMPT="true"' > "$_winecfg"
echo -e '_NOINITIALPROMPT="true"' > "$_protoncfg"
echo -e '_hotfixes_no_confirm="true"' > "$_winecfg"
echo -e '_hotfixes_no_confirm="true"' > "$_protoncfg"

# linux-tkg
echo -e "_version=\"$INPUT_KERNELVER\"" > "$_linuxcfg"
echo -e '_distro=""' >> "$_linuxcfg"
echo -e '_EXT_CONFIG_PATH=~/.config/frogminer/linux-tkg.cfg' >> "$_linuxcfg"
echo -e '_NUKR="true"' >> "$_linuxcfg"
echo -e 'CUSTOM_GCC_PATH=""' >> "$_linuxcfg"
echo -e '_OPTIPROFILE="1"' >> "$_linuxcfg"
echo -e '_force_all_threads="true"' >> "$_linuxcfg"
echo -e '_noccache="false"' >> "$_linuxcfg"
echo -e '_compiler="gcc"' >> "$_linuxcfg"
echo -e '_modprobeddb="false"' >> "$_linuxcfg"
echo -e '_menunconfig="false"' >> "$_linuxcfg"
echo -e '_diffconfig="false"' >> "$_linuxcfg"
echo -e '_diffconfig_name=""' >> "$_linuxcfg"
echo -e '_configfile="config.x86_64"' >> "$_linuxcfg"
echo -e '_debugdisable="false"' >> "$_linuxcfg"
echo -e "_cpusched=\"$INPUT_CPUSCHED\"" >> "$_linuxcfg"
echo -e '_sched_yield_type="0"' >> "$_linuxcfg"
echo -e '_rr_interval="default"' >> "$_linuxcfg"
echo -e '_ftracedisable="false"' >> "$_linuxcfg"
echo -e '_numadisable="false"' >> "$_linuxcfg"
echo -e '_misc_adds="true"' >> "$_linuxcfg"
echo -e '_tickless="2"' >> "$_linuxcfg"
echo -e '_voluntary_preempt="false"' >> "$_linuxcfg"
echo -e '_OFenable="false"' >> "$_linuxcfg"
echo -e '_acs_override="false"' >> "$_linuxcfg"
echo -e '_bcachefs="true"' >> "$_linuxcfg"
echo -e '_zfsfix="true"' >> "$_linuxcfg"
echo -e '_fsync="true"' >> "$_linuxcfg"
echo -e '_zenify="true"' >> "$_linuxcfg"
echo -e '_compileroptlevel="1"' >> "$_linuxcfg"
echo -e '_processor_opt="generic"' >> "$_linuxcfg"
echo -e '_irq_threading="false"' >> "$_linuxcfg"
echo -e '_smt_nice="true"' >> "$_linuxcfg"
echo -e '_random_trust_cpu="false"' >> "$_linuxcfg"
echo -e '_runqueue_sharing="mc"' >> "$_linuxcfg"
echo -e '_timer_freq="500"' >> "$_linuxcfg"
echo -e '_default_cpu_gov="ondemand"' >> "$_linuxcfg"
echo -e '_aggressive_ondemand="true"' >> "$_linuxcfg"
echo -e '_disable_acpi_cpufreq="false"' >> "$_linuxcfg"
echo -e '_custom_commandline="intel_pstate=passive"' >> "$_linuxcfg"
echo -e '_custom_pkgbase=""' >> "$_linuxcfg"
echo -e '_kernel_localversion=""' >> "$_linuxcfg"
echo -e '_community_patches=""' >> "$_linuxcfg"
echo -e '_user_patches="true"' >> "$_linuxcfg"
echo -e '_user_patches_no_confirm="false"' >> "$_linuxcfg"
echo -e '_config_fragments="false"' >> "$_linuxcfg"
echo -e '_config_fragments_no_confirm="false"' >> "$_linuxcfg"

# build
sudo -H -u miniglitch makepkg --syncdeps --noconfirm ${INPUT_MAKEPKGARGS:-}

# Report built package archives
i=0
for PKGFILE in "${PKGFILES[@]}"; do
	# makepkg reports absolute paths, must be relative for use by other actions
	RELPKGFILE="$(realpath --relative-base="$PWD" "$PKGFILE")"
	# Caller arguments to makepkg may mean the pacakge is not built
	if [ -f "$PKGFILE" ]; then
		echo "::set-output name=pkgfile$i::$RELPKGFILE"
	else
		echo "Archive $RELPKGFILE not built"
	fi
	(( ++i ))
done

#!/bin/bash
set -euo pipefail

FILE="$(basename "$0")"

# Enable the multilib repository
cat << EOM >> /etc/pacman.conf
[multilib]
Include = /etc/pacman.d/mirrorlist
EOM

pacman -Syu --noconfirm base-devel

# Makepkg does not allow running as root
# Create a new user `builder`
# `builder` needs to have a home directory because some PKGBUILDs will try to
# write to it (e.g. for cache)
useradd builder -m
# When installing dependencies, makepkg will use sudo
# Give user `builder` passwordless sudo access
echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

cd "$INPUT_PKGBUILD"

# Give all users (particularly builder) full access to these files
chmod -R a+rw .

# Assume that if .SRCINFO is missing then it is generated elsewhere.
# AUR checks that .SRCINFO exists so a missing file can't go unnoticed.
if [ -f .SRCINFO ] && ! sudo -u builder makepkg --printsrcinfo | diff - .SRCINFO; then
	echo "::error file=$FILE,line=$LINENO::Mismatched .SRCINFO. Update with: makepkg --printsrcinfo > .SRCINFO"
	exit 1
fi

# Get array of packages to be built
mapfile -t PKGFILES < <( sudo -u builder makepkg --packagelist )
echo "Package(s): ${PKGFILES[*]}"

# Optionally install dependencies from AUR
if [ -n "${INPUT_AURDEPS:-}" ]; then
	# First install yay
	pacman -S --noconfirm git
	git clone https://aur.archlinux.org/yay.git /tmp/yay
	pushd /tmp/yay
	chmod -R a+rw .
	sudo -H -u builder makepkg --syncdeps --install --noconfirm
	popd

	# Extract dependencies from .SRCINFO (depends or depends_x86_64) and install
	mapfile -t PKGDEPS < \
		<(sed -n -e 's/^[[:space:]]*depends\(_x86_64\)\? = \([[:alnum:][:punct:]]*\)[[:space:]]*$/\2/p' .SRCINFO)
	sudo -H -u builder yay --sync --noconfirm "${PKGDEPS[@]}"
fi

_userhome="/home/builder"
_linux58cfg="$_userhome"/.config/frogminer/linux58-tkg.cfg

mkdir -p "$_userhome/.config/frogminer"
echo -e '_NOINITIALPROMPT="true"' > "$_userhome"/.config/frogminer/wine-tkg.cfg

echo -e '_distro=""' > "$_linux58cfg"
echo -e '_EXT_CONFIG_PATH=~/.config/frogminer/linux58-tkg.cfg' >> "$_linux58cfg"
echo -e '_NUKR="true"' >> "$_linux58cfg"
echo -e 'CUSTOM_GCC_PATH=""' >> "$_linux58cfg"
echo -e '_OPTIPROFILE="1"' >> "$_linux58cfg"
echo -e '_force_all_threads="true"' >> "$_linux58cfg"
echo -e '_noccache="true"' >> "$_linux58cfg"
echo -e '_modprobeddb="false"' >> "$_linux58cfg"
echo -e '_menunconfig="false"' >> "$_linux58cfg"
echo -e '_diffconfig="false"' >> "$_linux58cfg"
echo -e '_diffconfig_name=""' >> "$_linux58cfg"
echo -e '_configfile="config.x86_64"' >> "$_linux58cfg"
echo -e '_debugdisable="false"' >> "$_linux58cfg"
echo -e '_cpusched="upds"' >> "$_linux58cfg"
echo -e '_sched_yield_type="0"' >> "$_linux58cfg"
echo -e '_rr_interval="default"' >> "$_linux58cfg"
echo -e '_ftracedisable="false"' >> "$_linux58cfg"
echo -e '_numadisable="false"' >> "$_linux58cfg"
echo -e '_misc_adds="true"' >> "$_linux58cfg"
echo -e '_tickless="2"' >> "$_linux58cfg"
echo -e '_voluntary_preempt="false"' >> "$_linux58cfg"
echo -e '_OFenable="false"' >> "$_linux58cfg"
echo -e '_acs_override="false"' >> "$_linux58cfg"
echo -e '_zfsfix="true"' >> "$_linux58cfg"
echo -e '_fsync="true"' >> "$_linux58cfg"
echo -e '_zenify="true"' >> "$_linux58cfg"
echo -e '_compileroptlevel="1"' >> "$_linux58cfg"
echo -e '_processor_opt="generic"' >> "$_linux58cfg"
echo -e '_irq_threading="false"' >> "$_linux58cfg"
echo -e '_smt_nice="true"' >> "$_linux58cfg"
echo -e '_random_trust_cpu="false"' >> "$_linux58cfg"
echo -e '_runqueue_sharing="mc"' >> "$_linux58cfg"
echo -e '_timer_freq="500"' >> "$_linux58cfg"
echo -e '_default_cpu_gov="ondemand"' >> "$_linux58cfg"
echo -e '_aggressive_ondemand="true"' >> "$_linux58cfg"
echo -e '_disable_acpi_cpufreq="false"' >> "$_linux58cfg"
echo -e '_custom_commandline="intel_pstate=passive"' >> "$_linux58cfg"
echo -e '_custom_pkgbase=""' >> "$_linux58cfg"
echo -e '_kernel_localversion=""' >> "$_linux58cfg"
echo -e '_community_patches=""' >> "$_linux58cfg"
echo -e '_user_patches="true"' >> "$_linux58cfg"
echo -e '_user_patches_no_confirm="false"' >> "$_linux58cfg"
echo -e '_config_fragments="false"' >> "$_linux58cfg"
echo -e '_config_fragments_no_confirm="false"' >> "$_linux58cfg"

# Build packages
# INPUT_MAKEPKGARGS is intentionally unquoted to allow arg splitting
# shellcheck disable=SC2086
sudo -H -u builder makepkg --syncdeps --noconfirm ${INPUT_MAKEPKGARGS:-}

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

function prepend () {
	# Prepend the argument to each input line
	while read -r line; do
		echo "$1$line"
	done
}

function namcap_check() {
	# Run namcap checks
	# Installing namcap after building so that makepkg happens on a minimal
	# install where any missing dependencies can be caught.
	pacman -S --noconfirm namcap

	NAMCAP_ARGS=()
	if [ -n "${INPUT_NAMCAPRULES:-}" ]; then
		NAMCAP_ARGS+=( "-r" "${INPUT_NAMCAPRULES}" )
	fi
	if [ -n "${INPUT_NAMCAPEXCLUDERULES:-}" ]; then
		NAMCAP_ARGS+=( "-e" "${INPUT_NAMCAPEXCLUDERULES}" )
	fi

	namcap "${NAMCAP_ARGS[@]}" PKGBUILD \
		| prepend "::warning file=$FILE,line=$LINENO::"
	for PKGFILE in "${PKGFILES[@]}"; do
		if [ -f "$PKGFILE" ]; then
			RELPKGFILE="$(realpath --relative-base="$PWD" "$PKGFILE")"
			namcap "${NAMCAP_ARGS[@]}" "$PKGFILE" \
				| prepend "::warning file=$FILE,line=$LINENO::$RELPKGFILE:"
		fi
	done
}

#if [ -z "${INPUT_NAMCAPDISABLE:-}" ]; then
#	namcap_check
#fi

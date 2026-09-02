#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Enabling the multilib repo (needed for the lib32-* packages)..."
echo "---------------------------------------------------------------"
if ! sudo grep -q '^\[multilib\]' /etc/pacman.conf; then
	sudo sh -c "printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' >> /etc/pacman.conf"
fi

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
sudo pacman -Syu --noconfirm patchelf file

if [ "$ARCH" = 'x86_64' ]; then
	# lib32-gcc-libs provides the 32-bit libgcc_s.so.1 needed to link
	# anylinux.so with -m32 (32-bit deployment mode of quick-sharun)
	sudo pacman -S --noconfirm mingw-w64-binutils mingw-w64-gcc lib32-glibc lib32-gcc-libs
fi

# Download Kron4ek 32-bit wine build
echo "Downloading Kron4ek wine 11.16 x86..."
wget --retry-connrefused --tries=30 https://github.com/Kron4ek/Wine-Builds/releases/download/11.16/wine-11.16-x86.tar.xz -O /tmp/wine-x86.tar.xz
mkdir -p /tmp/wine-x86
tar -xf /tmp/wine-x86.tar.xz -C /tmp/wine-x86 --strip-components=1
sudo cp -r /tmp/wine-x86/* /usr/

echo "Done."

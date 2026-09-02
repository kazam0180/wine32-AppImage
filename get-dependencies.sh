#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
sudo pacman -Syu --noconfirm patchelf file

if [ "$ARCH" = 'x86_64' ]; then
	sudo pacman -S --noconfirm mingw-w64-binutils mingw-w64-gcc lib32-glibc
fi

# Download Kron4ek 32-bit wine build
echo "Downloading Kron4ek wine 11.16 x86..."
wget --retry-connrefused --tries=30 https://github.com/Kron4ek/Wine-Builds/releases/download/11.16/wine-11.16-x86.tar.xz -O /tmp/wine-x86.tar.xz
mkdir -p /tmp/wine-x86
tar -xf /tmp/wine-x86.tar.xz -C /tmp/wine-x86 --strip-components=1

echo "Done."

#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing 32-bit CLI Wine dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm wine

# Only install mingw strip tools for32-bit DLL stripping
if [ "$ARCH" = 'x86_64' ]; then
	sudo pacman -S --noconfirm mingw-w64-binutils
fi

echo "Minimal 32-bit CLI Wine dependencies installed."

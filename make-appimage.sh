#!/bin/sh

# Minimal CLI-only Wine AppImage
# For running CLI apps like COD1 map compiler (coutils.exe)

set -eu

ARCH=$(uname -m)
VERSION=$(pacman -Q wine | awk '{print $2; exit}')
export ARCH VERSION
export OUTPATH=./dist
export ADD_HOOKS="self-updater.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export ICON=https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-icon-theme/bcf6aa9582f676e1c93d0022319e6055cd1f2de2/Papirus/64x64/apps/wine.svg
export DESKTOP=/usr/share/applications/wine.desktop
export APPNAME=wine-cli

# Disable all GUI-related deployments for CLI-only mode
export DEPLOY_SDL=0
export DEPLOY_PIPEWIRE=0
export DEPLOY_GSTREAMER=0
export DEPLOY_VULKAN=0
export DEPLOY_OPENGL=0
export DEPLOY_QT=0
export DEPLOY_GTK=0
export DEPLOY_PULSE=0

# Deploy only minimal CLI Wine dependencies
# Wine 11.x layout: usr/lib/wine/{i386-windows,x86_64-windows,x86_64-unix}
mkdir -p /tmp/wine
WINEPREFIX=/tmp/wine quick-sharun \
	/usr/bin/wine              \
	/usr/bin/wineserver        \
	/usr/bin/wineboot          \
	/usr/lib/wine              \
	/usr/bin/regsvr32

# Strip Windows DLLs to reduce size
if command -v x86_64-w64-mingw32-strip >/dev/null 2>&1; then
	x86_64-w64-mingw32-strip -R .comment --strip-unneeded ./AppDir/lib/wine/x86_64-windows/*.dll 2>/dev/null || true
fi
if command -v i686-w64-mingw32-strip >/dev/null 2>&1; then
	i686-w64-mingw32-strip -R .comment --strip-unneeded ./AppDir/lib/wine/i386-windows/*.dll 2>/dev/null || true
fi

# Turn AppDir into AppImage
quick-sharun --make-appimage

#!/bin/sh

# Minimal 32-bit Wine AppImage
# Uses Kron4ek 32-bit wine build (no WoW64 needed)

set -eu

ARCH=$(uname -m)
VERSION="$(curl -s https://api.github.com/repos/Kron4ek/Wine-Builds/releases/latest | jq -r '.tag_name' | sed 's|^v||')"
export ARCH VERSION
export OUTPATH=./dist
export ADD_HOOKS="self-updater.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export ICON=https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-icon-theme/bcf6aa9582f676e1c93d0022319e6055cd1f2de2/Papirus/64x64/apps/wine.svg
export DESKTOP=/usr/share/applications/wine.desktop
export APPNAME=wine32

# Disable all GUI-related deployments for CLI-only mode
export DEPLOY_SDL=1
export DEPLOY_PIPEWIRE=1
export DEPLOY_GSTREAMER=1
export DEPLOY_VULKAN=1
export DEPLOY_OPENGL=1

# Deploy from Kron4ek 32-bit wine build
# LIB_DIR=/usr/lib32 enables 32-bit deployment (LIB32=1): quick-sharun puts
# the 32-bit libs and ld-linux.so.2 in AppDir/lib32/ and builds anylinux.so
# with -m32. sharun looks for the interpreter of a 32-bit ELF binary ONLY in
# AppDir/lib32/, without this wine dies with "Interpreter not found!"
mkdir -p /tmp/wine
WINEPREFIX=/tmp/wine LIB_DIR=/usr/lib32 quick-sharun \
	/usr/bin/wine              \
	/usr/bin/wineserver        \
	/usr/bin/wineboot          \
	/usr/bin/regsvr32          \
	/usr/lib/wine

# alright here the pain starts
ln -sr ./AppDir/lib/wine/i386-unix/*.so* ./AppDir/bin

# Belt and suspenders: make sure the 32-bit loader is where sharun expects it
# even if lib4bin ever stops deploying it (shared/lib32 is a symlink to lib32)
mkdir -p ./AppDir/lib32
cp -f /lib/ld-linux.so.2 ./AppDir/shared/lib32/ld-linux.so.2

# Patch wine binaries with random interpreter
# wineserver is exec()'d by wine directly at runtime, so it needs the same
# patch or the kernel would use the host's loader (missing on 64-bit-only
# and musl systems, mismatched glibc everywhere else)
kek=.$(tr -dc 'A-Za-z0-9_=-' < /dev/urandom | head -c 10)
rm -f ./AppDir/shared/bin/wine
cp /usr/bin/wine ./AppDir/shared/bin/wine
patchelf --set-interpreter /tmp/"$kek" ./AppDir/shared/bin/wine
patchelf --set-interpreter /tmp/"$kek" ./AppDir/shared/bin/wineserver
patchelf --add-needed anylinux.so ./AppDir/shared/lib32/libc.so.6

cat <<EOF > ./AppDir/bin/random-linker.src.hook
#!/bin/sh
cp -f "\$APPDIR"/shared/lib32/ld-linux.so.2 /tmp/"$kek"
EOF
chmod +x ./AppDir/bin/*.hook

# lib32 is needed for child processes spawned by wine (wineserver), which
# inherit this env var instead of sharun's --library-path
echo 'LD_LIBRARY_PATH=${APPDIR}/lib32:${APPDIR}/lib:${APPDIR}/lib/wine/i386-unix' >> ./AppDir/.env

# Strip Windows DLLs
if [ "$ARCH" = 'x86_64' ]; then
	i686-w64-mingw32-strip -R .comment --strip-unneeded ./AppDir/lib/wine/i386-windows/*.dll 2>/dev/null || true
fi

# Clean up broken symlinks
find ./AppDir/ -xtype l -delete 2>/dev/null || true

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test the app for 12 seconds, if the app normally quits before that time
# then skip this or check if some flag can be passed that makes it stay open
quick-sharun --simple-test ./dist/*.AppImage

# simple-test only catches "error while loading shared libraries"-style
# failures, it stays green even when wine dies with "Interpreter not found!",
# so actually run wine to be sure the bundle works
./dist/*.AppImage --version

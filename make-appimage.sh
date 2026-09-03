#!/bin/sh

# Minimal 32-bit Wine AppImage
# Uses Void Linux system wine package

set -eu

ARCH=$(uname -m)
VERSION="$(xbps-query -H wine 2>/dev/null | awk '/^version:/{print $2; exit}')" || VERSION="0.0.0"
export ARCH VERSION
export OUTPATH=./dist
export ADD_HOOKS="self-updater.hook"
: ${GITHUB_REPOSITORY:=pkgforge/wine32-AppImage}
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export ICON=https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-icon-theme/bcf6aa9582f676e1c93d0022319e6055cd1f2de2/Papirus/64x64/apps/wine.svg
export DESKTOP=/usr/share/applications/wine.desktop
export APPNAME=wine32

# Deploy settings
export DEPLOY_SDL=1
export DEPLOY_PIPEWIRE=1
export DEPLOY_GSTREAMER=0
export DEPLOY_VULKAN=0
export DEPLOY_OPENGL=1

# Deploy dependencies - use lib32 path for multilib
LIB32="/usr/lib32"
if [ ! -d "$LIB32" ]; then
	LIB32="/usr/lib/i686-linux-gnu"
fi
if [ ! -d "$LIB32" ]; then
	LIB32="/usr/lib"
fi

mkdir -p /tmp/wine
WINEPREFIX=/tmp/wine LIB_DIR="$LIB32" quick-sharun \
	/usr/bin/wine              \
	/usr/bin/wineserver        \
	/usr/bin/wineboot          \
	/usr/bin/regsvr32          \
	/usr/lib/wine       #       \
#	/usr/bin/cabextract        \
#	/usr/bin/wget              \
#	/usr/bin/unzip             \
#	/usr/bin/7zip              \
#	"$LIB32"/libfreetype.so*   \
#	"$LIB32"/libharfbuzz*      \
#	"$LIB32"/libgraphite*      \
#	"$LIB32"/libavcodec.so*    \
#	"$LIB32"/libavdevice.so*   \
#	"$LIB32"/libavfilter.so*   \
#	"$LIB32"/libavformat.so*   \
#	"$LIB32"/libavutil.so*     \
#	"$LIB32"/libswresample.so* \
#	"$LIB32"/libswscale.so*

# alright here the pain starts
ln -sr ./AppDir/lib/wine/i386-unix/*.so* ./AppDir/bin

# Belt and suspenders: make sure the 32-bit loader is where sharun expects it
# even if lib4bin ever stops deploying it (shared/lib32 is a symlink to lib32)
mkdir -p ./AppDir/lib32
# Find ld-linux.so.2 - Void Linux multilib may have it in different paths
LD_LINUX=""
for path in /lib/ld-linux.so.2 /usr/lib/ld-linux.so.2 /lib32/ld-linux.so.2 /usr/lib32/ld-linux.so.2; do
	if [ -f "$path" ]; then
		LD_LINUX="$path"
		break
	fi
done
if [ -z "$LD_LINUX" ]; then
	echo "ERROR: Cannot find ld-linux.so.2"
	exit 1
fi
cp -f "$LD_LINUX" ./AppDir/shared/lib32/ld-linux.so.2

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
	# Find the correct mingw strip command (Void Linux vs Arch naming)
	STRIP_CMD=""
	for cmd in i686-w64-mingw32-strip i686-w64-mingw32-elfstrip; do
		if command -v "$cmd" >/dev/null 2>&1; then
			STRIP_CMD="$cmd"
			break
		fi
	done
	if [ -n "$STRIP_CMD" ]; then
		"$STRIP_CMD" -R .comment --strip-unneeded ./AppDir/lib/wine/i386-windows/*.dll 2>/dev/null || true
	else
		echo "WARNING: No mingw strip command found, skipping DLL stripping"
	fi
fi

# Clean up broken symlinks
find ./AppDir/ -xtype l -delete 2>/dev/null || true

# Turn AppDir into AppImage
export DWARFS_COMP="zstd:level=19 -N4"
quick-sharun --make-appimage

# Test the app for 12 seconds, if the app normally quits before that time
# then skip this or check if some flag can be passed that makes it stay open
quick-sharun --simple-test ./dist/*.AppImage

# simple-test only catches "error while loading shared libraries"-style
# failures, it stays green even when wine dies with "Interpreter not found!",
# so actually run wine to be sure the bundle works
./dist/*.AppImage --version

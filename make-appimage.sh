#!/bin/sh

set -eu

ARCH=$(uname -m)
VERSION=$(pacman -Q ladybird 2>/dev/null || pacman -Q ladybird-git 2>/dev/null || true)
VERSION=$(echo "$VERSION" | awk '{print $2; exit}')
VERSION=${VERSION:-latest}
export ARCH VERSION
export OUTPATH=./dist
export ADD_HOOKS="self-updater.bg.hook"
if [ -n "${GITHUB_REPOSITORY:-}" ]; then
	export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
fi
export ICON=https://raw.githubusercontent.com/LadybirdBrowser/ladybird/refs/heads/master/Base/res/icons/128x128/app-browser.png
export DESKTOP=https://raw.githubusercontent.com/LadybirdBrowser/ladybird/refs/heads/master/Meta/CMake/freedesktop/org.ladybird.Ladybird.desktop
export ANYLINUX_LIB=1

# Deploy dependencies
if [ -d /opt/ladybird/usr ]; then
	quick-sharun \
		/opt/ladybird/usr/bin/*          \
		/opt/ladybird/usr/lib/*          \
		/opt/ladybird/usr/lib/ladybird/* \
		/opt/angle/usr/lib/*             \
		/opt/ladybird/usr/share/*
else
	quick-sharun \
		/usr/bin/Ladybird                \
		/usr/bin/js                      \
		/usr/bin/wasm                    \
		/usr/lib/ladybird/*              \
		/usr/share/ladybird/*
fi

if [ -d ./AppDir/lib/angle/usr/lib ]; then
	mv -v ./AppDir/lib/angle/usr/lib/* ./AppDir/lib/
	rm -rf ./AppDir/lib/angle
fi

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test the app for 12 seconds, if the test fails due to the app
# having issues running in the CI use --simple-test instead
pacman -S --noconfirm vulkan-swrast # app now needs a vulkan device to launch
quick-sharun --test ./dist/*.AppImage

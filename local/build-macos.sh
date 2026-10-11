#!/usr/bin/env bash
# Build the local OpenPencil.app from this fork (ad-hoc signed, updater disabled).
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

# Use the system Xcode toolchain and SDK, not an inherited Nix compiler shell
# (clang wrapper, xcbuild xcrun, apple-sdk), so the app links like upstream.
unset DEVELOPER_DIR SDKROOT MACOSX_DEPLOYMENT_TARGET CC CXX LD AR NIX_CC NIX_LDFLAGS NIX_CFLAGS_COMPILE
export PATH="/usr/bin:$PATH"

bun install --frozen-lockfile
# mbx runs the Cargo build with the shared local compiler cache.
bun run tauri build --bundles app --runner mbx --config local/tauri.local.conf.json

app="$repo_root/desktop/target/release/bundle/macos/OpenPencil.app"
codesign --verify --deep --strict "$app"
printf 'built %s (version %s)\n' "$app" \
  "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")"

#!/usr/bin/env bash
# Replace /Applications/OpenPencil.app with the locally built fork.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
app="$repo_root/desktop/target/release/bundle/macos/OpenPencil.app"
target="/Applications/OpenPencil.app"

[[ -d "$app" ]] || { echo "error: $app missing; run local/build-macos.sh first" >&2; exit 1; }
codesign --verify --deep --strict "$app"

if /usr/bin/pgrep -x OpenPencil >/dev/null; then
  echo "error: OpenPencil is running; save your documents, quit it and retry" >&2
  exit 1
fi
if command -v brew >/dev/null && brew list --cask openpencil >/dev/null 2>&1; then
  echo "error: the Homebrew cask openpencil is installed and would replace this build;" >&2
  echo "       remove it from homebrew.casks and run: brew uninstall --cask openpencil" >&2
  exit 1
fi

incoming="$target.incoming"
rm -rf "$incoming"
ditto "$app" "$incoming"
if [[ -e "$target" ]]; then
  backup="$(mktemp -d /tmp/openpencil-previous.XXXXXX)/OpenPencil.app"
  mv "$target" "$backup"
  echo "previous app kept at $backup"
fi
mv "$incoming" "$target"
printf 'installed %s (version %s)\n' "$target" \
  "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$target/Contents/Info.plist")"

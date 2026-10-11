# Local OpenPencil build

Fork of `open-pencil/open-pencil` for Patrick's Mac. Branch `disable-background-throttling`
is based on the upstream release tag and carries two commits:

1. `fix(desktop)`: `backgroundThrottling: "disabled"` on the main window. Without it, WKWebView
   suspends the web content when the window is hidden, minimized, on another Space or fully
   covered, and every MCP/RPC call times out (upstream issue #979).
2. This `local/` directory: build overrides and scripts, not meant for upstream.

`local/tauri.local.conf.json` signs ad hoc (`-`), skips updater artifacts and empties the updater
endpoints. The app therefore never offers an upstream update that would replace this build; the
OpenPencil MCP bridge in `/Users/patwoz/dev/Personal/infra` must stay on the same major.minor
version as the app.

## Build and install

```sh
local/build-macos.sh    # bun install, Tauri build via mbx, system Xcode SDK
local/install-macos.sh  # requires OpenPencil to be quit; keeps the previous app in /tmp
```

The Homebrew cask `openpencil` must not be installed; it would replace this build.

## Update to a new upstream release

```sh
git fetch origin --tags
git rebase --onto vX.Y.Z vOLD disable-background-throttling
local/build-macos.sh
```

Bump `@open-pencil/mcp` and `testedAppVersion` in the infra repository to the same release.

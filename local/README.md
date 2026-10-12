# Local OpenPencil build

Fork of `open-pencil/open-pencil` (remote `upstream`) for Patrick's Mac, published as
`patlux/open-pencil` (remote `origin`). Branch `disable-background-throttling` is based on the
upstream release tag and carries these changes:

1. `fix(desktop)`: `backgroundThrottling: "disabled"` on the main window. Without it, WKWebView
   suspends the web content when the window is hidden, minimized, on another Space or fully
   covered, and every MCP/RPC call times out (upstream issue #979).
2. `fix(desktop)`: `desktop/src/webview_activity.rs` disables WebKit window-occlusion detection
   (private SPI) and App Nap. A window on another Space or fully covered then keeps its
   foreground priority, so MCP calls stay fast on a busy Mac. A hidden (Cmd-H) or minimized
   window still runs the web content at background priority: keep the window on any Space
   instead of hiding or minimizing it while an agent works.
3. This `local/` directory: build overrides and scripts, not meant for upstream.

`local/tauri.local.conf.json` signs ad hoc (`-`), skips updater artifacts and empties the updater
endpoints. The app therefore never offers an upstream update that would replace this build; the
OpenPencil MCP bridge in `/Users/patwoz/dev/Personal/infra` must stay on the same major.minor
version as the app.

## Build and install

```sh
local/build-macos.sh    # bun install, Tauri build via mbx, system Xcode SDK -> local/dist
local/install-macos.sh  # requires OpenPencil to be quit; keeps the previous app in /tmp
```

`desktop/target` links to an mbx-managed directory that mbx may prune, so the build script copies
the finished app to `local/dist/` (ignored by Git). At startup the app logs
`[webview] App Nap disabled: true` and `[webview] occlusion detection disabled: true` to stderr
(`open --stderr <file> -a /Applications/OpenPencil.app`).

The Homebrew cask `openpencil` must not be installed; it would replace this build.

## Update to a new upstream release

```sh
git fetch upstream --tags
git rebase --onto vX.Y.Z vOLD disable-background-throttling
local/build-macos.sh
```

Bump `@open-pencil/mcp` and `testedAppVersion` in the infra repository to the same release.

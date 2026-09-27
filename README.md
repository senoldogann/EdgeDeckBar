# EdgeDeck

A liquid-glass edge dock for macOS with live widgets and a command center for your AI coding agents.

EdgeDeck sits on the edge of your screen as a slim glass dock. Apps, links and widgets live in it; clicking a widget opens a flyout next to the dock.

## Features

- **Edge dock.** Left, right or top edge, auto-hide, icon magnification, drag to reorder, native-style launch bounce, and Show / Hide / Quit / Force Quit for running apps.
- **AI Usage.**
  - Real plan limits for Claude Code and OpenAI Codex: remaining 5-hour and weekly quota with reset countdowns.
  - A 7-day token chart built from your local transcripts.
  - The Ollama models currently loaded in memory.
- **Multiple AI accounts.** Save several Claude Code and Codex logins and switch the active one in one click. The switch applies to the terminal, IDE extensions and other tools.
- **Dispatch.** Send a task to Claude Code, Codex, OpenCode or Ollama and read the answer in place, or open it as an interactive Terminal session.
- **Widgets.** System monitor (plus a live detailed window), clipboard history with images, weather, now playing, Bluetooth devices and a quick-notes scratchpad.
- **Command palette** (⌥Space) for apps, widgets, window tiling and quick actions such as Lock Screen and Sleep Display.

## Install

Download the latest `EdgeDeck-x.y.z.dmg` from [Releases](https://github.com/senoldogann/EdgeDeckBar/releases). Open it and drag **EdgeDeck** into **Applications**. Releases are signed with a Developer ID and notarized by Apple, so they open without Gatekeeper warnings.

## Requirements

- macOS 15 or later
- Swift 6 toolchain (Xcode 16 or later)

## Build and run

```sh
./script/build_and_run.sh          # debug build, bundles and launches dist/EdgeDeck.app
EDGEDECK_VERSION=1.0.0 ./script/package_app.sh   # release build, signed .app and .dmg in build/
swift test                         # test suite
```

Optional permissions, requested only when a feature needs them:

| Permission | Used for |
| --- | --- |
| Accessibility | Window tiling and window previews |
| Bluetooth | Listing paired devices and their battery level |
| Automation (Terminal) | Opening AI tasks and logins in Terminal |

## Where AI limits come from

EdgeDeck only reads data the tools already keep on your Mac, plus Anthropic's own account endpoint:

- **Codex:** rate-limit events in `~/.codex/sessions/**/rollout-*.jsonl`.
- **Claude Code:**
  - the usage cache that [T3 Code](https://github.com/pingdotgg/t3code) keeps in `~/.t3/caches`, if you use it;
  - otherwise an optional status line bridge. It wraps your existing `statusLine` command in `~/.claude/settings.json`, backs the file up first, can be removed from the account menu, and keeps your status line output unchanged.
- **Token chart:** usage records in `~/.claude/projects` and `~/.codex/sessions`, scanned incrementally.

## Security and privacy

Account switching handles real login credentials, so it is deliberately conservative:

- **Where logins are stored.** Saved logins stay in your login Keychain. They are never written to disk in plain text and never sent anywhere.
- **Claude ownership checks.** Before a Claude login is saved under an account, EdgeDeck asks Anthropic's `/api/oauth/profile` endpoint (the same one Claude Code uses) which account the token belongs to. Revoked logins are flagged and are never saved.
- **Switching needs closed sessions.** EdgeDeck refuses to switch while that provider's CLI is running. Running sessions refresh their login in the background and would overwrite or revoke the switched one.

## Releasing

Pushing a version tag builds, signs, notarizes and publishes the DMG automatically (`.github/workflows/release.yml`):

```sh
git tag v1.0.0 && git push origin v1.0.0
```

The workflow needs these repository secrets:

| Secret | Value |
| --- | --- |
| `MACOS_CERTIFICATE_P12_BASE64` | Your *Developer ID Application* certificate and private key, exported as `.p12` and base64-encoded |
| `MACOS_CERTIFICATE_PASSWORD` | The password chosen when exporting the `.p12` |
| `APPLE_ID` | The Apple ID email of the developer account |
| `APPLE_APP_SPECIFIC_PASSWORD` | An app-specific password from [account.apple.com](https://account.apple.com) |
| `APPLE_TEAM_ID` | Your 10-character Apple Developer Team ID |

## License

[MIT](LICENSE)

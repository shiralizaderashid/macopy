# Macopy

**Clipboard history for macOS** — a lightweight menu bar app that remembers what you copy, so you never lose a snippet again.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5-orange?logo=swift)
![License](https://img.shields.io/badge/license-MIT-green)

---

## Features

- **Automatic history** — saves the last 50 copied text snippets and images
- **Global hotkey** — open history instantly with `⌘⇧V` (customizable)
- **Search** — filter items in real time
- **Pin items** — keep important snippets at the top
- **Auto-paste** — select an item and it pastes into your previous app
- **Menu bar app** — lives quietly in the menu bar, no Dock icon
- **Launch at login** — optional, enabled by the install script
- **100% local** — no network, no telemetry, no cloud sync

---

## Requirements

| Requirement | Details |
|-------------|---------|
| **macOS** | 13.0 (Ventura) or later |
| **Architecture** | Apple Silicon (M1/M2/M3/M4) |
| **Tools** | Xcode Command Line Tools (`xcode-select --install`) |

---

## Quick Install

```bash
git clone https://github.com/shiralizaderashid/macopy.git
cd macopy
bash install.sh
```

This builds the app, copies it to `/Applications`, launches it, and adds a login item.

---

## Manual Build

```bash
bash build.sh
open .build/Macopy.app
```

To install manually:

```bash
cp -r .build/Macopy.app /Applications/
```

---

## First Launch

Because Macopy is not signed with an Apple Developer certificate, macOS may block it on first open.

1. Open **Applications**
2. **Right-click** Macopy → **Open** (do not double-click)
3. Click **Open** on the "unidentified developer" warning
4. Go to **System Settings → Privacy & Security → Accessibility**
5. Enable **Macopy**
6. Restart the app

> Without Accessibility permission, Macopy still works — copied items land on the clipboard and you paste with `⌘V` manually.

---

## Usage

| Action | Shortcut |
|--------|----------|
| Open clipboard history | `⌘⇧V` (default, configurable) |
| Navigate items | `↑` / `↓` |
| Paste selected item | `↵` |
| Quick paste item 1–9 | `1` – `9` |
| Delete selected item | `⌘⌫` |
| Close panel | `⎋` |
| Settings | Menu bar → **Settings…** |
| Clear history | Menu bar → **Clear History** |

---

## Settings

Open **Settings…** from the menu bar to change the global hotkey. Click the shortcut pill, press your desired key combination (must include at least one modifier: `⌘`, `⇧`, `⌥`, or `⌃`), then click **Save**.

---

## Distribution (DMG)

To create a shareable DMG for colleagues:

```bash
bash package.sh
```

This produces `Macopy-1.0.dmg` in the project root.

---

## Privacy

All clipboard data stays on your Mac in `UserDefaults`. Macopy does not connect to the internet or send any data anywhere.

Be mindful that clipboard history may contain passwords, tokens, or other sensitive text.

---

## Project Structure

```
macopy/
├── Sources/
│   ├── AppDelegate.swift           # Menu bar, accessibility prompt
│   ├── ClipboardManager.swift      # Polling, persistence
│   ├── ClipboardItem.swift         # Item model
│   ├── HistoryPanelController.swift # Floating panel + keyboard
│   ├── HistoryView.swift           # SwiftUI history UI
│   ├── HotkeyConfig.swift          # Hotkey persistence
│   ├── HotkeyManager.swift         # Carbon global hotkey
│   ├── SettingsWindowController.swift
│   └── main.swift
├── build.sh
├── install.sh
├── package.sh
└── Info.plist
```

---

## License

MIT — use freely, modify, and share.

# YouTube Vision

A macOS menu bar app that acts as a floating remote control for YouTube playing in your browser.

No browser extension needed — it uses AppleScript to control your browser's YouTube tab directly.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange)

## Features

- 🎵 **Floating player bar** — draggable, resizable, always-on-top panel with frosted glass blur
- ▶️ **Playback controls** — play/pause, next/previous, seek, volume, speed (1×/2×)
- 🎨 **Color themes** — 7 accent themes (Classic, Blue, Red, Crimson, Sky, Teal, Green)
- 🔊 **Wave animation** — animated wave bars synced to playback state
- 📋 **Smart next video** — follows playlist order or sidebar suggestions
- 🧹 **Clean title** — strips notification counts and "- YouTube" suffix

## Installation

1. Download **YouTubeVision.dmg** from [Releases](../../releases)
2. Open the DMG and drag **YouTube Vision** into **Applications**
3. Open Terminal and run:

```bash
sudo xattr -cr "/Applications/YouTube Vision.app"
```

> This removes the macOS quarantine flag so the app can launch without Gatekeeper blocking it (required for apps not signed with an Apple Developer certificate).

4. Enable **JavaScript from Apple Events** in your browser (see below)
5. Launch **YouTube Vision** from Applications
6. When prompted, grant **Accessibility** permission

## Supported Browsers

Works with any Chromium-based browser:

**Google Chrome** · **Brave** · **Microsoft Edge** · **Arc** · **Yandex** · **Opera** · **Vivaldi** · **Chromium**

### Enable JavaScript from Apple Events

YouTube Vision needs this setting to control your browser. Enable it **once** per browser:

**In the browser:** Go to **View → Developer → Allow JavaScript from Apple Events** and check it.

**Or via Terminal:**

| Browser | Command |
|---------|---------|
| Chrome | `defaults write com.google.Chrome AppleScriptEnabled -bool true` |
| Brave | `defaults write com.brave.Browser AppleScriptEnabled -bool true` |
| Edge | `defaults write com.microsoft.edgemac AppleScriptEnabled -bool true` |
| Opera | `defaults write com.operasoftware.Opera AppleScriptEnabled -bool true` |
| Vivaldi | `defaults write com.vivaldi.Vivaldi AppleScriptEnabled -bool true` |
| Yandex | `defaults write ru.yandex.desktop.browser AppleScriptEnabled -bool true` |

> **Arc** has this enabled by default — no action needed.

Restart the browser after enabling.

## Usage

- **Left-click** the menu bar icon (🎵) to show/hide the player
- **Right-click** the menu bar icon for the context menu (show/hide, quit)
- Play any YouTube video in your browser — the player bar picks it up automatically
- Multiple browsers open? YouTube Vision finds the **playing** tab automatically
- Drag the grip dots to move the panel anywhere on screen
- Drag the edge to resize the panel width
- Use the ⏻ power menu for themes, hide, or quit

## Requirements

- macOS 13 Ventura or later
- A supported Chromium-based browser (see above)

## Building from Source

```bash
git clone https://github.com/ahmadxonQ/youtube-vision.git
cd youtube-vision
xcodebuild -scheme YouTubeVision -configuration Release build
```

The built app will be in `~/Library/Developer/Xcode/DerivedData/YouTubeVision-*/Build/Products/Release/`.

## License

MIT

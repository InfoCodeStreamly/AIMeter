# AIMeter

<p align="center">
  <img src="Resources/AppIcon.png" alt="AIMeter Icon" width="128" height="128">
</p>

<p align="center">
  <strong>Track your Claude AI usage limits in real-time from your macOS menu bar</strong>
</p>

<p align="center">
  <a href="https://github.com/InfoCodeStreamly/AIMeter/releases/latest">
    <img src="https://img.shields.io/github/v/release/InfoCodeStreamly/AIMeter?style=for-the-badge" alt="Latest Release">
  </a>
  <a href="https://github.com/InfoCodeStreamly/AIMeter/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/InfoCodeStreamly/AIMeter?style=for-the-badge" alt="License">
  </a>
  <img src="https://img.shields.io/badge/platform-macOS%2015%2B-blue?style=for-the-badge" alt="Platform">
  <img src="https://img.shields.io/badge/swift-6.0-orange?style=for-the-badge" alt="Swift">
</p>

---

## About

AIMeter sits in your macOS menu bar and shows Claude AI usage limits at a glance — session limits, weekly limits, reset countdowns, and more. No more guessing when your limits will reset.

Automatically syncs your OAuth token from Claude Code CLI. Zero configuration.

### Key Features

- **Usage Tracking** — real-time session & weekly limits with selectable time granularity (15m / 1h / 3h / 6h)
- **Color-coded Status** — green (safe), orange (moderate), red (critical)
- **Reset Countdown** — know exactly when your limits refresh
- **Voice Input** — push-to-talk transcription powered by on-device Whisper
- **Auto-Updates** — seamless updates via Sparkle
- **Native macOS** — glassmorphism UI, menu bar integration, launch at login

## Installation

### Download (Recommended)

1. Go to [**Releases**](https://github.com/InfoCodeStreamly/AIMeter/releases/latest)
2. Download `AIMeter-x.x.x.dmg`
3. Drag AIMeter to Applications
4. Launch from Applications

> The app is signed and notarized by Apple.

### Build from Source

```bash
git clone https://github.com/InfoCodeStreamly/AIMeter.git
cd AIMeter
open AIMeter.xcodeproj
```

Build and run in Xcode (`Cmd+R`).

## Getting Started

1. Install [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code/overview)
2. Launch AIMeter — your OAuth token syncs automatically from `~/.claude` keychain
3. Usage appears in the menu bar immediately

No API keys or manual setup required.

## Requirements

- macOS 15.0 (Sequoia) or later
- Claude Pro / Team / Enterprise subscription

## Built With

| Technology | Purpose |
|---|---|
| **Swift 6.0** | Strict concurrency, actors, Sendable |
| **SwiftUI** | Modern declarative UI |
| **MenuBarExtra** | Native menu bar integration |
| **Whisper** | On-device speech-to-text |
| **Sparkle** | Auto-update framework |
| **Keychain** | Secure credential storage |

**Architecture:** Clean Architecture — Domain / Application / Infrastructure / Presentation

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes
4. Push and open a Pull Request

## License

[MIT](LICENSE)

## Author

**Ievgen Chugunov** — [@CodeStreamly](https://x.com/CodeStreamly)

# AIMeter

<p align="center">
  <img src="Resources/AppIcon.png" alt="AIMeter Icon" width="128" height="128">
</p>

<p align="center">
  <strong>Track your Claude AI usage limits in real-time from your macOS menu bar</strong>
</p>

<p align="center">
  <a href="https://github.com/InfoCodeStreamly/AIMeter/releases/latest">
    <img src="https://img.shields.io/github/v/release/InfoCodeStreamly/AIMeter?style=flat-square" alt="Latest Release">
  </a>
  <a href="https://github.com/InfoCodeStreamly/AIMeter/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/InfoCodeStreamly/AIMeter?style=flat-square" alt="License">
  </a>
  <img src="https://img.shields.io/badge/platform-macOS%2015%2B-blue?style=flat-square" alt="Platform">
  <img src="https://img.shields.io/badge/swift-6.0-orange?style=flat-square" alt="Swift">
</p>

---

## What is AIMeter?

AIMeter is a native macOS menu bar app that displays your Claude AI (claude.ai) usage limits at a glance. No more guessing when your limits will reset!

**Features:**
- Real-time usage tracking (session & weekly limits)
- Color-coded status (green/orange/red)
- Reset time countdown
- Auto-refresh every 30 seconds
- Native macOS design with glassmorphism UI
- Launch at login support
- Secure OAuth token storage in Keychain

## Installation

### Download DMG (Recommended)

1. Go to [Releases](https://github.com/InfoCodeStreamly/AIMeter/releases/latest)
2. Download `AIMeter-x.x.x.dmg`
3. Open DMG and drag AIMeter to Applications
4. Launch AIMeter from Applications

> **Note:** The app is signed and notarized by Apple for your security.

### Build from Source

```bash
git clone https://github.com/InfoCodeStreamly/AIMeter.git
cd AIMeter
open AIMeter.xcodeproj
```

Build and run in Xcode (⌘R).

## Setup

1. Launch AIMeter
2. Click the menu bar icon
3. Open Settings (gear icon)
4. Enter your Claude session key or connect via OAuth

### Getting Your Session Key

AIMeter syncs with Claude Code CLI automatically. If you have Claude Code installed, the token will be detected.

Alternatively, you can manually enter your OAuth token from claude.ai.

## Screenshots

<p align="center">
  <em>Menu bar usage display</em>
</p>

## Requirements

- macOS 15.0 (Sequoia) or later
- Claude Pro/Team subscription (for API access)

## Tech Stack

- **Swift 6.0** with strict concurrency
- **SwiftUI** for modern UI
- **MenuBarExtra** for native menu bar integration
- **Keychain** for secure token storage
- **Clean Architecture** (Domain/Application/Infrastructure/Presentation)

## Contributing

Contributions are welcome! Feel free to:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Support the Project

If you find AIMeter useful, consider:

- Starring the repository
- [Sponsoring on GitHub](https://github.com/sponsors/InfoCodeStreamly)
- Sharing with friends and colleagues

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**Ievgen Chugunov** — [@prdxn](https://x.com/prdxn)

---

<p align="center">
  Made with ❤️ for the Claude community
</p>

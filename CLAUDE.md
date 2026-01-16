# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AIMeter is a native Apple ecosystem widget app for tracking AI service usage limits in real-time. The app targets iOS, macOS, watchOS, and visionOS with shared code architecture.

**Current Status:** Early development - basic SwiftUI app structure created.

**Reference Project:** https://github.com/hamed-elfayome/Claude-Usage-Tracker (for API integration patterns)

## Build Commands

```bash
# Build from command line
xcodebuild -project AIMeter.xcodeproj -scheme AIMeter -configuration Debug build

# Build for specific platform
xcodebuild -project AIMeter.xcodeproj -scheme AIMeter -destination 'platform=macOS' build
xcodebuild -project AIMeter.xcodeproj -scheme AIMeter -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests (when tests are added)
xcodebuild -project AIMeter.xcodeproj -scheme AIMeter test
```

Open in Xcode: `open AIMeter.xcodeproj`

## Technical Stack

- **Language:** Swift 5 + SwiftUI
- **Architecture:** MVVM
- **Platforms:** iOS 26.2+, macOS 26.1+, visionOS 26.2+
- **Bundle ID:** `com.codestreamly.AIMeter`
- **Sync:** iCloud (CloudKit) - planned
- **Security:** Keychain for credentials - planned

## Planned Architecture

```
AIMeter/
├── Shared/
│   ├── Models/          # UsageData, etc. (cross-platform)
│   ├── API/             # ClaudeAPI client
│   └── ViewModels/      # UsageViewModel
├── macOS/               # MenuBarView (Phase 1 priority)
├── iOS/                 # WidgetView
├── watchOS/             # ComplicationView
└── visionOS/            # OrnamentView
```

## Design Guidelines

- Use native Apple materials (`.ultraThinMaterial`, `.regularMaterial`, `.thickMaterial`)
- SF Symbols for icons, SF Pro for typography
- Native animations (spring, easeInOut)
- Platform-specific patterns:
  - macOS: Translucent menu bar popover
  - iOS: Glass cards with blur
  - watchOS: Circular complications
  - visionOS: 3D glass panels with depth

## Development Phases

**Phase 1 (Current Focus):** macOS menu bar app with Claude API integration
- Distribution via DMG (no App Store)

**Phase 2:** Full ecosystem with App Store distribution
- Add iOS, watchOS, visionOS targets
- iCloud sync between devices

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Communication

**Language:** Communicate with the user in Ukrainian (українська) exclusively.

---

## Project Overview

AIMeter is a native Apple ecosystem widget app for tracking AI service usage limits in real-time. Phase 1 focuses on macOS Menu Bar app.

**Current Status:** Phase 1 - macOS Menu Bar app development

**Reference:** `Docs/Claude-Usage-Tracker-main/` (API integration patterns, local copy)

## Build Commands

```bash
# Build macOS
xcodebuild -project AIMeter.xcodeproj -scheme AIMeter -destination 'platform=macOS' build

# Build with verbose errors
xcodebuild -project AIMeter.xcodeproj -scheme AIMeter build 2>&1 | head -50

# Run tests
xcodebuild -project AIMeter.xcodeproj -scheme AIMeter test
```

Open in Xcode: `open AIMeter.xcodeproj`

## Technical Stack

- **Swift:** 6.0 (strict concurrency)
- **UI:** SwiftUI + `MenuBarExtra` + `.menuBarExtraStyle(.window)`
- **State:** `@Observable` macro (not ObservableObject)
- **Concurrency:** `actor` for services, `@MainActor` for ViewModels, `Sendable` protocol
- **Platforms:** macOS 26.1+ (Phase 1), iOS/watchOS/visionOS (Phase 2)
- **Bundle ID:** `com.codestreamly.AIMeter`
- **Security:** Keychain for session key storage

## Architecture (Phase 1)

```
AIMeter/
├── App/
│   └── AIMeterApp.swift              # @main with MenuBarExtra
│
├── Shared/
│   ├── Models/
│   │   ├── ClaudeUsage.swift         # Usage data (Sendable)
│   │   └── UsageStatusLevel.swift    # safe/moderate/critical
│   │
│   ├── Services/
│   │   ├── ClaudeAPIService.swift    # actor, API client
│   │   ├── KeychainService.swift     # actor, secure storage
│   │   └── Protocols/
│   │       └── APIServiceProtocol.swift
│   │
│   ├── ViewModels/
│   │   └── UsageViewModel.swift      # @Observable, @MainActor
│   │
│   ├── Utilities/
│   │   ├── Constants.swift           # API endpoints, defaults
│   │   └── DateExtensions.swift      # resetTimeString()
│   │
│   └── ErrorHandling/
│       └── AppError.swift            # Unified errors
│
└── Features/
    └── MenuBar/
        ├── MenuBarView.swift         # Main popover (280px)
        └── Components/
            └── UsageCardView.swift   # Usage card with progress
```

## Claude API (OAuth)

- **Auth:** OAuth token from Claude Code CLI (auto-sync from Keychain)
- **Token format:** `sk-ant-oat01-...` (OAuth Access Token)
- **Base URL:** `https://api.anthropic.com/api/oauth`
- **Headers:**
  - `Authorization: Bearer {token}`
  - `anthropic-beta: oauth-2025-04-20`
- **Endpoint:** `GET /usage`
- **Response fields:** `five_hour`, `seven_day`, `seven_day_opus`, `seven_day_sonnet`
  - Each contains: `utilization` (0-100), `resets_at` (ISO8601)

## Code Style

### Documentation Comments

Use `///` Swift documentation comments:

```swift
/// Fetches current usage from API
/// - Throws: `AppError` on failure
/// - Returns: Current usage statistics
func fetchUsage() async throws -> ClaudeUsage
```

### Patterns

- `actor` for thread-safe services
- `@MainActor` for ViewModels and UI state
- `Sendable` for all models crossing actor boundaries
- `@Environment` for dependency injection in views

## Design Guidelines

- Materials: `.ultraThinMaterial`, `.regularMaterial` (glassmorphism)
- Icons: SF Symbols
- Animations: `.easeInOut`, `.spring`
- Popover width: 280px
- Color coding: green (safe), orange (moderate), red (critical)

## Development Phases

**Phase 1 (Current):** macOS Menu Bar app ✅
- [x] Menu bar UI with usage display
- [x] OAuth integration via Claude Code CLI sync
- [ ] DMG distribution packaging
- [ ] Auto-update mechanism

**Phase 2:** Full ecosystem
- iOS, watchOS, visionOS targets
- iCloud sync
- App Store distribution
- Multiple AI service support (OpenAI, etc.)

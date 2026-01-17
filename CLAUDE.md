# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Communication

**Language:** Communicate with the user in Ukrainian (українська) exclusively.

## Project Overview

AIMeter is a native macOS menu bar app for tracking Claude AI usage limits in real-time. It syncs OAuth tokens from Claude Code CLI and displays usage statistics.

- **Bundle ID:** `com.codestreamly.AIMeter`
- **Platforms:** macOS 15.0+ (Sequoia)
- **Swift:** 6.0 with strict concurrency

## Build Commands

```bash
# Build macOS
xcodebuild -project AIMeter.xcodeproj -scheme AIMeter -destination 'platform=macOS' build

# Build with verbose errors
xcodebuild -project AIMeter.xcodeproj -scheme AIMeter build 2>&1 | head -50

# Run tests
xcodebuild -project AIMeter.xcodeproj -scheme AIMeter test

# Open in Xcode
open AIMeter.xcodeproj
```

## Architecture

Clean Architecture with 4 layers:

```
AIMeter/
├── Domain/           # Entities, ValueObjects, Repository protocols
├── Application/      # Use Cases, DTOs, Mappers
├── Infrastructure/   # API clients, Keychain, Repositories impl
├── Presentation/     # ViewModels, Views (SwiftUI)
└── CrossCutting/     # DI container, Constants, Extensions
```

### Key Patterns

- **Concurrency:** `actor` for services, `@MainActor` for ViewModels, `Sendable` for models
- **State:** `@Observable` macro (not ObservableObject)
- **DI:** `DependencyContainer.shared` singleton with factory methods
- **UI:** SwiftUI + `MenuBarExtra` + `.menuBarExtraStyle(.window)`

### Data Flow

```
Claude Code CLI Keychain → ClaudeCodeSyncService → OAuthCredentials
                                ↓
UsageViewModel → FetchUsageUseCase → ClaudeUsageRepository → ClaudeAPIClient
                                ↓
                         MenuBarView (usage display)
```

## Claude API

- **Auth:** OAuth token synced from Claude Code CLI (`~/.claude` keychain)
- **Token format:** `sk-ant-oat01-...` (OAuth Access Token)
- **Usage endpoint:** `GET /api/oauth/usage` with `Authorization: Bearer {token}`
- **Auto-refresh:** Tokens refresh proactively when < 5 min remaining

## Versioning (SSOT)

Version is determined by git tags at build time:
- **Version:** From latest `v*` tag (e.g., `v1.5` → `1.5`)
- **Build:** From commit count
- Set via build phase script in `project.pbxproj`

## Release Process

Releases are automated via GitHub Actions on tag push:

```bash
git tag v1.6 && git push origin v1.6
```

Workflow: Build → Sign (Developer ID) → Notarize → DMG → Sparkle sign → GitHub Release

## Git Workflow

Commit and push to both `stage` and `main` in one command:

```bash
git add -A && git commit -m "type: message

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>" && git push origin stage && git checkout main && git merge stage --no-edit && git push origin main && git checkout stage
```

Commit types: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`

## Design Guidelines

- Materials: `.ultraThinMaterial`, `.regularMaterial` (glassmorphism)
- Icons: SF Symbols only
- Animations: `.easeInOut`, `.spring`
- Color coding: green (safe <50%), orange (moderate 50-80%), red (critical >80%)

# PMI WBS Principles - Work Breakdown Structure

## Project Management

**GitHub Project:** [AIMeter](https://github.com/InfoCodeStreamly/AIMeter)

---

## Table of Contents

### [FOUNDATION MODULES](#foundation-modules)
- [Core Concepts](#core-concepts)
- [Hierarchy Levels](#hierarchy-levels)

### [IMPLEMENTATION MODULES](#implementation-modules)
- [Decomposition Rules](#decomposition-rules)
- [Vertical Slices Approach](#vertical-slices-approach)
- [Layer-by-Layer Verification Workflow](#layer-by-layer-verification-workflow)
- [Examples](#examples)
- [AI Agent Guidelines](#ai-agent-guidelines)

### [REFERENCE MODULES](#reference-modules)
- [Clean Architecture Layer Mapping](#clean-architecture-layer-mapping)

---

## FOUNDATION MODULES

### Core Concepts

#### WBS (Work Breakdown Structure)
Hierarchical decomposition of project scope into **deliverables** (what we create), not processes (how we do it).

#### 100% Rule
All hierarchy levels must capture **100% of project scope** - nothing more, nothing less.

#### Deliverable-Based Approach
Use **nouns** (deliverables), not verbs (processes):
- "Auth System" (what we create)
- "Planning", "Development", "Testing" (how we do it)

---

### Hierarchy Levels

#### Level 1: EPIC
**What:** Major business feature/module - "parts of the bicycle" (wheel, handlebar, pedals)

**Characteristics:**
- Business-facing deliverable
- Major component of the system
- Named with single noun
- No technical implementation details

**Examples for AIMeter:**
- Auth (Claude session management)
- Usage (usage data tracking)
- Widget (menu bar/widget UI)
- Settings (user preferences)
- Sync (iCloud sync)
- Notifications (alerts)

---

#### Level 2: STORY (User Story)
**What:** Business requirement from user perspective - what user wants to achieve

**Format:**
```
As a [user role], I want [goal], so that [benefit]
```

**Characteristics:**
- User-facing functionality
- Describes business value
- No technical implementation
- Has acceptance criteria
- Belongs to parent Epic

**Examples:**
```
Epic: Usage
├── Story: View current usage limits
├── Story: See usage history
├── Story: Get reset countdown
└── Story: Track multiple AI services
```

---

#### Level 3: TASK (Technical Task)
**What:** Technical implementation unit - specific file/method/change in codebase

**Decomposition Principle:**
```
1 file to create/modify = 1 Task
1 method to add = 1 Task
10 files to change = 10 Tasks
```

**Characteristics:**
- Technical implementation detail
- Specific to Clean Architecture layer
- Points to exact file path
- Lists methods to create/modify
- Belongs to parent Story

**Structure:**
```
Task Title: [Layer] - [Action] [File/Component]

Examples:
- Domain - Create UsageData model (AIMeter/Shared/Models/UsageData.swift)
- Application - Create FetchUsageUseCase (AIMeter/Shared/UseCases/FetchUsageUseCase.swift)
- Infrastructure - Implement ClaudeAPIClient (AIMeter/Shared/Services/ClaudeAPIClient.swift)
- Presentation - Create MenuBarView (AIMeter/macOS/Views/MenuBarView.swift)
```

---

## IMPLEMENTATION MODULES

### Decomposition Rules

#### Epic Decomposition
1. Identify major business modules
2. Use single nouns
3. Business perspective only
4. No technical terms
5. Must cover 100% of app scope

#### Story Decomposition
1. User-facing feature within Epic
2. Express as user goal
3. Define acceptance criteria
4. Should be completable in 1 sprint
5. No technical implementation

#### Task Decomposition
1. **Granularity:** 1 file or 1 method = 1 Task
2. **Layer-based:** Group by Clean Architecture layers
   - Domain tasks
   - Application tasks
   - Infrastructure tasks
   - Presentation tasks
3. **Sequential order:** Follow layer dependencies
4. **Specificity:** Exact file paths, method names
5. **Completeness:** All files/methods must be tasks

---

### Vertical Slices Approach

#### What is a Vertical Slice?

A **Vertical Slice** is a Story implementation that cuts through **all Clean Architecture layers** to deliver a **complete, working user-facing feature**.

```
Story: "View Usage Limits" (Vertical Slice)
├── Domain Layer      - UsageData model, ResetTime value object
├── Application Layer - FetchUsageUseCase, UsageViewModel
├── Infrastructure Layer - ClaudeAPIClient, KeychainService
└── Presentation Layer - UsageView, MenuBarPopover

Result: Fully working "View Usage" feature
```

#### Why Vertical Slices?

**Benefits:**
- **Complete feature** delivered at story completion
- **Testable immediately** - working functionality end-to-end
- **Minimal dependencies** on other stories
- **Clear scope** - focused on single user goal
- **AI agent friendly** - limited context, clear boundaries

**Comparison:**

```
Horizontal Layers (Anti-Pattern):
Phase 1: ALL Domain models
Phase 2: ALL Use Cases
Phase 3: ALL Services
Phase 4: ALL UI views
Problem: Nothing works until Phase 4!

Vertical Slices (Recommended):
Slice 1: View Usage (all layers) → Working feature
Slice 2: Auth Session (all layers) → Working feature
Slice 3: Settings (all layers) → Working feature
Benefit: Each slice delivers value!
```

---

### Layer-by-Layer Verification Workflow

#### Core Principle: Small Chunks, Accurate Execution

**CRITICAL:** When planning or executing layer changes:
- Check ONE layer → Fix plan → Check NEXT layer
- DON'T read everything at once (context gets lost!)
- Better to do small pieces accurately than read all and make mistakes

#### 5-Step Verification Cycle (Per Layer)

```
┌──────────────────────────────────────────────────────┐
│  1. DISCOVER  │  Find files with Glob/Grep           │
├──────────────────────────────────────────────────────┤
│  2. PLAN      │  Files + Actions table               │
├──────────────────────────────────────────────────────┤
│  3. EXECUTE   │  Checkboxes per file (one at a time) │
├──────────────────────────────────────────────────────┤
│  4. VERIFY    │  xcodebuild (expect errors)          │
├──────────────────────────────────────────────────────┤
│  5. FIX       │  Document new issues for next layer  │
└──────────────────────────────────────────────────────┘
```

#### Verification Commands

```bash
# Build and check for errors
xcodebuild -project AIMeter.xcodeproj -scheme AIMeter -configuration Debug build 2>&1 | head -50

# Count errors
xcodebuild -project AIMeter.xcodeproj -scheme AIMeter build 2>&1 | grep -c "error:"

# Find specific error patterns
xcodebuild -project AIMeter.xcodeproj -scheme AIMeter build 2>&1 | grep "UsageData"
```

#### Progress Markers
- ⏳ Pending
- 🔄 In Progress
- ✅ Completed
- ❌ Blocked (document why)
- ⚠️ Needs Review

---

### Examples

#### Example: Complete Decomposition for AIMeter

```
Epic: Usage (AIM-1)
│
└── Story: View current Claude usage limits (AIM-10)
    │
    ├── Task: Domain - Create UsageData model (AIM-11)
    │   └── File: AIMeter/Shared/Models/UsageData.swift
    │   └── Properties: used, limit, resetTime, percentage
    │   └── Methods: isNearLimit(), formattedUsage()
    │
    ├── Task: Domain - Create ResetTime value object (AIM-12)
    │   └── File: AIMeter/Shared/Models/ResetTime.swift
    │   └── Methods: timeUntilReset(), formattedCountdown()
    │
    ├── Task: Application - Create UsageViewModel (AIM-13)
    │   └── File: AIMeter/Shared/ViewModels/UsageViewModel.swift
    │   └── Properties: usageData, isLoading, error
    │   └── Methods: fetchUsage(), startAutoRefresh()
    │
    ├── Task: Infrastructure - Create ClaudeAPIClient (AIM-14)
    │   └── File: AIMeter/Shared/Services/ClaudeAPIClient.swift
    │   └── Methods: fetchUsageData(sessionToken:)
    │
    ├── Task: Infrastructure - Create KeychainService (AIM-15)
    │   └── File: AIMeter/Shared/Services/KeychainService.swift
    │   └── Methods: saveToken(_:), getToken(), deleteToken()
    │
    ├── Task: Presentation - Create UsageView (AIM-16)
    │   └── File: AIMeter/Shared/Views/UsageView.swift
    │   └── Component: SwiftUI view with progress ring
    │
    └── Task: Presentation - Create MenuBarPopover (AIM-17)
        └── File: AIMeter/macOS/Views/MenuBarPopover.swift
        └── Component: NSPopover with UsageView
```

---

### AI Agent Guidelines

#### When Creating Tasks
1. **Be specific:** Exact file paths
2. **Be granular:** 1 file/method = 1 Task
3. **Follow layers:** Domain → Application → Infrastructure → Presentation
4. **List methods:** What methods to create/modify
5. **Mark completed:** Use ✅ for implemented items

#### Quality Checklist
- [ ] Epic covers business deliverable only
- [ ] Story expresses user value
- [ ] Tasks follow Clean Architecture layers
- [ ] Each task points to specific file
- [ ] Task granularity: 1 file/method per task
- [ ] No duplicate work between tasks

---

## REFERENCE MODULES

### Clean Architecture Layer Mapping

#### Domain Layer (AIMeter/Shared/Models/)
- Models: `UsageData.swift`, `AIService.swift`
- Value Objects: `ResetTime.swift`, `SessionToken.swift`
- Protocols: `UsageRepositoryProtocol.swift`

#### Application Layer (AIMeter/Shared/ViewModels/, UseCases/)
- ViewModels: `UsageViewModel.swift`, `SettingsViewModel.swift`
- Use Cases: `FetchUsageUseCase.swift`, `AuthenticateUseCase.swift`

#### Infrastructure Layer (AIMeter/Shared/Services/)
- API Clients: `ClaudeAPIClient.swift`
- Storage: `KeychainService.swift`, `UserDefaultsService.swift`
- Networking: `HTTPClient.swift`

#### Presentation Layer (Platform-specific Views/)
- macOS: `AIMeter/macOS/Views/` - MenuBarView, PopoverView
- iOS: `AIMeter/iOS/Views/` - WidgetView, MainView
- watchOS: `AIMeter/watchOS/Views/` - ComplicationView
- visionOS: `AIMeter/visionOS/Views/` - OrnamentView
- Shared UI: `AIMeter/Shared/Views/` - UsageView, SettingsView

---

**Last Updated:** 2026-01-16
**Project:** AIMeter - AI Usage Tracking Widget
**Methodology:** PMI + Agile + Clean Architecture + MVVM

# Versioning & Release Rules

## Version Source of Truth (SSOT)

Version is determined **ONLY** by git tags. Never hardcode versions in project files.

- **Version number:** From latest `v*` tag (e.g., `v1.5` → `1.5`)
- **Build number:** From total commit count
- Set automatically via build phase script at compile time

## When to Create a New Version

Create a new version tag when:
- New feature implemented (`feat:` commits)
- Significant bug fixes
- User explicitly requests a release

**DO NOT** create tags for:
- Minor refactoring
- Documentation changes
- Work in progress

## How to Create a Release

After committing changes to `stage` and `main`:

```bash
# Check current latest version
git tag -l "v*" | sort -V | tail -3

# Create and push new tag (triggers GitHub Actions release)
git tag v1.X && git push origin v1.X
```

Replace `1.X` with the next version number.

## Version Numbering

Follow semantic versioning:
- `v1.0` → `v1.1` — new features, minor changes
- `v1.1` → `v1.2` — more features
- `v1.X` → `v2.0` — major changes, breaking changes

## Release Workflow (Automated)

When a `v*` tag is pushed, GitHub Actions automatically:

1. **Build** — xcodebuild Release
2. **Sign** — Developer ID Application certificate
3. **Notarize** — Apple notarization service
4. **Package** — Create DMG with drag-to-Applications
5. **Sparkle** — Sign with EdDSA for auto-updates
6. **Release** — Upload to GitHub Releases with appcast.xml

Monitor release progress: https://github.com/InfoCodeStreamly/AIMeter/actions

## Sparkle Auto-Updates

- Users receive updates automatically via Sparkle framework
- `appcast.xml` is generated and uploaded with each release
- EdDSA signature ensures update integrity

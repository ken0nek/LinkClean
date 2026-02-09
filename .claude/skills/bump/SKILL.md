---
name: bump
description: "Bump version and/or build number. Usage: /bump (build+1), /bump build 10, /bump patch|minor|major, /bump 1.2.0"
---

# Bump Version & Build

Bump version and/or build numbers via fastlane for the app and action extension targets (LinkClean, LinkCleanAction, LinkCleanMarkdownAction).

## Argument parsing

Parse `$ARGUMENTS` (may be empty) into one of these cases:

| `$ARGUMENTS`          | Action                                          |
|-----------------------|-------------------------------------------------|
| *(empty)*             | Build +1 only                                   |
| `build <N>` (number) | Build = N                                       |
| `patch`/`minor`/`major` | Version bump by type + build +1               |
| `X.Y.Z` (semver)     | Version = X.Y.Z + build +1                      |

## Steps

1. Run the appropriate fastlane command(s) based on the parsed arguments:
   - Build only: `bundle exec fastlane bump_build` or `bundle exec fastlane bump_build number:<N>`
   - Version + build: `bundle exec fastlane bump type:<type>` or `bundle exec fastlane bump version:<X.Y.Z>`
2. Grep `CURRENT_PROJECT_VERSION` and `MARKETING_VERSION` in `LinkClean.xcodeproj/project.pbxproj` to confirm the new values.
3. Commit with message:
   - Build only: `Bump build number to <new>`
   - Version + build: `Bump version to <version> (<build>)`

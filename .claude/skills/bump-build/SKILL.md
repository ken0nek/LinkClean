---
name: bump-build
description: Bump the Xcode build number (CURRENT_PROJECT_VERSION) in project.pbxproj
---

# Bump Build Number

Increment `CURRENT_PROJECT_VERSION` in `LinkClean.xcodeproj/project.pbxproj` for the app and action extension targets (Debug + Release).

## Steps

1. Grep `CURRENT_PROJECT_VERSION` in `LinkClean.xcodeproj/project.pbxproj` to find the current highest build number.
2. Determine the new build number:
   - If `$ARGUMENTS` is a number, use that as the new build number.
   - Otherwise, increment the current highest build number by 1.
3. Use the Edit tool with `replace_all: true` to replace all `CURRENT_PROJECT_VERSION = <current>;` with `CURRENT_PROJECT_VERSION = <new>;` in the pbxproj file. Only replace the lines that match the current highest number (app + extension targets).
4. Commit with message: `Bump build number to <new>`

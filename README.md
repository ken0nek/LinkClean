# LinkClean

**Privacy-focused URL cleaning for iOS**

![Platform: iOS 18+](https://img.shields.io/badge/platform-iOS%2018%2B-blue)
![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple)
![SwiftData](https://img.shields.io/badge/persistence-SwiftData-green)

LinkClean strips tracking parameters from URLs before you share them — keeping your links clean and your browsing private.

## Features

### URL Cleaning
Removes 85+ tracking parameters across 7 categories: UTM, common tracking, ads & attribution, analytics, email/CRM, social, and affiliate.

### Share Extension
Use **Clean URL** from any app's share sheet. The extension cleans the URL, copies it to your clipboard, saves it to history, and dismisses — all in one tap.

### History
Every cleaned URL is saved with rich link previews powered by LinkPresentation — including page titles and thumbnails. Copy, share, or delete entries at any time.

### Custom Tracking Parameters
Add your own parameters to remove. Custom parameters are shared between the app and extension via App Group.

### Auto-Paste
When enabled, LinkClean automatically reads a valid URL from your clipboard when you open the app or return to it.

### Settings
- Toggle auto-paste from clipboard
- Toggle save history (disabling clears all history)
- Manage default tracking parameters (enable/disable individually)
- Add or remove custom tracking parameters
- Clear history

## Tech Stack

- **Swift 6.2** with strict concurrency and MainActor default isolation
- **SwiftUI** with the Observation framework (`@Observable`)
- **SwiftData** for history persistence
- **LinkPresentation** for rich link previews
- **App Group** for sharing data between the app and extension
- **iOS 18.0+** deployment target

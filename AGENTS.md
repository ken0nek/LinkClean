# Repository Guidelines

## Architecture
- See `ARCHITECTURE.md` for the MVVM/Observation layering and dependency wiring conventions used in this repo.

## Project Structure & Module Organization
- `LinkClean/`: SwiftUI app source (`LinkCleanApp.swift`, `ContentView.swift`, `URLCleaner.swift`) plus assets in `LinkClean/Assets.xcassets`.
- `LinkCleanAction/`: Action Extension target (`ActionViewController.swift`, `Info.plist`, extension-specific `URLCleaner.swift`). Keep cleaner logic in sync with the app.
- `LinkCleanTests/`: Unit tests using the Swift Testing framework.
- `LinkCleanUITests/`: UI test target.
- `LinkClean.xcodeproj`: Xcode project with schemes `LinkClean` and `LinkCleanAction`.

## Build, Test, and Development Commands
- Open in Xcode: `xed .` or `open LinkClean.xcodeproj`.
- Build the app: `xcodebuild -project LinkClean.xcodeproj -scheme LinkClean -configuration Debug build`.
- Build the extension: `xcodebuild -project LinkClean.xcodeproj -scheme LinkCleanAction build`.
- Run tests (requires a simulator): `xcodebuild -project LinkClean.xcodeproj -scheme LinkClean -destination 'platform=iOS Simulator,name=iPhone 15' test`.

## Coding Style & Naming Conventions
- Swift 6.2 + SwiftUI. Use Xcode default formatting (4-space indentation) and Swift API Design Guidelines.
- Concurrency: default actor isolation is `MainActor`. Mark background utilities `nonisolated` when needed.
- Observation pattern: `@Observable` models + `@State` in views; avoid `ObservableObject`, `@Published`, and `@StateObject`.
- SwiftData: use `@Model`, `@Query`, and `ModelContext` from the environment.
- Avoid Combine and GCD; prefer async/await, actors, and TaskGroup. Avoid force unwraps unless invariants are documented.

## Collaboration
- Ask the user when uncertain about requirements, scope, or approach, or when more data is needed.
- Hand off tasks that require Xcode GUI or Apple Developer portal: creating targets, configuring App Groups, entitlements, signing, capabilities, adding frameworks via Xcode UI.
- When handing off, state exactly what needs to be done so the user can act quickly.

## Testing Guidelines
- Framework: Swift Testing (`import Testing`, `@Test`, `#expect`, `#require`).
- Naming: files end with `*Tests.swift` and test functions are descriptive verbs (e.g., `removesUtmSource`).
- No explicit coverage threshold; add tests when changing URL-cleaning rules or UI flows.

## Debugging
- Prefer `print()` debugging first—add prints, build & run, read logs, remove prints. Don't over-engineer logging.

## Commit & Pull Request Guidelines
- Commit messages are short, imperative, and unprefixed (e.g., "Add Action Extension for cleaning and copying URLs").
- PRs should include: a brief description, test notes (Xcode run or `xcodebuild test`), and screenshots for any UI changes (app + extension if affected).

## Platform & Feature Notes
- Target platforms: iOS 18+, iPadOS 18+.
- If introducing on-device AI, check `SystemLanguageModel.default.availability` before use.
- Prefer SwiftUI-native components and WebView; avoid UIKit bridging unless there is no SwiftUI equivalent.

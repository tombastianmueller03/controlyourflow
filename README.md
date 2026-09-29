# Control your Flow

A free, fully local iOS app. Before an app you picked (for example Instagram) opens, a Shortcuts automation shows a short mental-math pause.

> Work in progress. The full guide (setup, Shortcuts automation, sideloading, known limits) follows in the final milestone.

## Build

- Requirements: Xcode 26 or later, iOS 26.0 or later, [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- `brew install xcodegen && xcodegen generate`, then open `ControlYourFlow.xcodeproj`
- CI: GitHub Actions (`.github/workflows/ci.yml`) runs the unit tests and builds an unsigned `.ipa`

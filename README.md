# Beaver Notes — Apple

Native iOS / iPadOS / macOS client for [Beaver Notes](https://github.com/eduard256/beaver-notes), the self-hosted note wall.

Built with SwiftUI, SwiftData, Swift Concurrency. Targets iOS 17, iPadOS 17, macOS 14 (via Mac Catalyst).

## Status

Pre-MVP. Project skeleton.

## Features (planned)

- Multi-server support (up to 100 self-hosted servers)
- Local-first sync with outbox + LWW conflict resolution
- Markdown editor with live preview and full toolbar
- Image editor: crop, draw, filters, optimize before upload
- Video trim + optimize (HEIC, H.265)
- Background uploads via URLSession background session
- Share Extension, Widgets, App Intents, Spotlight indexing
- Keyboard shortcuts on iPad/Mac

## Requirements

- Xcode 16+
- iOS 17 / iPadOS 17 / macOS 14
- Apple Developer account (for App Group, Keychain Sharing, TestFlight)

## License

MIT

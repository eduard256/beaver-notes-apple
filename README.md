# Beaver Notes — Apple

Native iOS, iPadOS, and macOS client for [Beaver Notes](https://github.com/eduard256/beaver-notes), a self-hosted note wall.

Built with SwiftUI, SwiftData, and Swift Concurrency. Targets iOS 17, iPadOS 17, macOS 14.

## Features

- **Multi-server** — connect to multiple self-hosted Beaver Notes servers and switch between them from the sidebar.
- **Local-first sync** — outbox-backed message delivery with last-write-wins conflict resolution; works offline and catches up when the server comes back.
- **Markdown editor** — live rendering, code blocks, lists, links.
- **Attachments** — photos, videos, and arbitrary files. Images shown in an adaptive grid with a fullscreen viewer. Video playback inline.
- **Upload progress** — per-file and per-message progress overlays, including failure states.
- **Image editor** — crop, draw, filters, and optional optimization before upload.
- **Video trim and optimize** — HEIC and H.265 encoding to keep uploads small.
- **Quick input** — compact composer at the bottom of the wall for fast capture.
- **Search** — local full-text search across notes.
- **Spotlight indexing** — system-wide search hits land directly in the note.
- **Privacy** — biometric lock (Face ID / Touch ID), auto-lock timeout, hide previews in the App Switcher.
- **Cache control** — per-server cache size limit and one-tap clear.
- **Multi-platform UI** — adapted layouts for iPhone, iPad, and Mac (sidebar, context menus, swipe actions, keyboard shortcuts).

## Privacy

The app talks **only** to the self-hosted server(s) the user adds. No analytics, no third-party SDKs, no telemetry. See [PRIVACY.md](./PRIVACY.md).

## Requirements

- Xcode 16+
- iOS 17 / iPadOS 17 / macOS 14
- A running [Beaver Notes](https://github.com/eduard256/beaver-notes) server (HTTPS, self-signed TLS, or HTTP on a local network all supported)

## Build

```sh
open BeaverNotes.xcodeproj
```

Select a simulator or your Mac and run.

## License

[MIT](./LICENSE)

# Privacy Policy

**Effective date:** 2026-05-21
**App:** Beaver Notes for iOS, iPadOS, and macOS
**Developer:** webaweba
**Contact:** dev.apps.pol@gmail.com

Beaver Notes is a client application for the open-source, self-hosted [Beaver Notes](https://github.com/eduard256/beaver-notes) server. This policy describes what data the app handles, where that data is stored, and what is — and is not — sent anywhere.

## TL;DR

- We (the developer) do **not** run any backend.
- Your notes, files, photos, and videos go **only** to the self-hosted server you configure.
- The app does **not** collect analytics, telemetry, advertising identifiers, or crash reports.
- The app does **not** contact any third-party services.

## What data the app processes

The app processes the following data **on your device** and sends it **only to the server you configure**:

- Note text content you create.
- Files, photos, and videos you choose to attach.
- Metadata of your messages (timestamps, pin state, etc.).
- The URL, name, and authentication credentials of the server(s) you add.

The app does **not** collect:

- Your name, email, phone number, or any contact information.
- Your location.
- Your contacts, calendar, health data, or browsing history.
- Advertising or tracking identifiers (IDFA, IDFV, etc.).
- Usage analytics, behavioral data, or crash reports.

## Where data is stored

- **On your device**: notes, attachments, cache, and a local database (Apple's SwiftData). This data is sandboxed by iOS / macOS and removable by deleting the app or using the in-app "clear cache" action.
- **In Apple Keychain**: server authentication credentials. Keychain is encrypted and managed by the operating system.
- **On the self-hosted server you choose**: a copy of your notes and attachments, sent over HTTPS (or HTTP if your server is configured that way — see "Network access" below).

We have no access to your self-hosted server or to the data stored on it. Server-side privacy is governed by the operator of that server (which may be you).

## Network access

The app makes network requests only to:

1. The Beaver Notes server URL(s) you explicitly add.
2. Nothing else.

The app supports user-provided servers that may use:

- HTTPS with public certificates,
- HTTPS with self-signed certificates,
- HTTP (for local-network deployments such as `192.168.x.x` or `.local`).

This is why the app declares `NSAllowsArbitraryLoads` in its Info.plist — it has no fixed backend and must reach whatever address the user provides.

## Permissions the app may request

The app asks for the following system permissions only when you actively use the related feature:

- **Camera** — to capture photos for note attachments.
- **Photo Library (read)** — to attach existing photos and videos.
- **Photo Library (write)** — to save photos you download from a note.
- **Face ID / Touch ID** — to unlock the app, if you enable biometric lock.
- **Files (user-selected)** — to attach arbitrary files you pick.

Permission strings shown by iOS / macOS match these purposes and the data never leaves your device or your configured server.

## Children

The app is not directed at children under 13. It does not knowingly collect data from children.

## Account deletion and data removal

Beaver Notes does not maintain a developer-side user account. To remove data:

- **Local data**: use the in-app "Clear cache" action, or delete the app from your device.
- **Server data**: delete messages from within the app (they are removed from your server), or remove the server entry, or contact the operator of your self-hosted server.

## Third-party SDKs

None. The app contains no third-party analytics, advertising, or tracking SDKs.

## Changes to this policy

Updates will be published in this file in the project repository. The "Effective date" at the top of this document reflects the latest revision.

## Contact

Questions about this policy: **dev.apps.pol@gmail.com**
Issue tracker: <https://github.com/eduard256/beaver-notes-apple/issues>

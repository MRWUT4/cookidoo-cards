# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SwiftUI multi-platform app (iOS/macOS/visionOS) for Cookidoo recipe cards. Built with Xcode, targeting iOS 26.1, macOS 26.0, and visionOS 26.1.

Bundle ID: `de.davidochmann.cookidoo-cards`

## Build Commands

```bash
# Build (Debug)
xcodebuild -project cookidoo-cards.xcodeproj -scheme cookidoo-cards -configuration Debug

# Build (Release)
xcodebuild -project cookidoo-cards.xcodeproj -scheme cookidoo-cards -configuration Release

# Open in Xcode
open cookidoo-cards.xcodeproj
```

No test targets or linting tools are currently configured.

## Architecture

Standard SwiftUI app structure:
- `cookidoo-cards/cookidoo_cardsApp.swift` — App entry point (`@main`)
- `cookidoo-cards/ContentView.swift` — Main view

Swift concurrency uses `MainActor` default isolation with approachable concurrency enabled.

## Cookidoo API

The app integrates with the Cookidoo (Vorwerk/Thermomix) API:
- **Discovery**: HATEOAS pattern via `https://cookidoo.{country_code}/.well-known/home`
- **Auth**: OAuth 2.0 password grant to `https://{country_code}.tmmobile.vorwerk-digital.com/ciam/auth/token`
- **API namespace**: Relations prefixed with `tmde2:`
- **Token usage**: `Authorization: Bearer {access_token}` on all requests

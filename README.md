# Clipper - Native macOS Clipboard Manager

[![Platform](https://img.shields.io/badge/Platform-macOS%2012.0%2B-blue?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Flutter](https://img.shields.io/badge/Flutter-3.x%20%7C%20Dart%203.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-FA7343?logo=swift&logoColor=white)](https://developer.apple.com/swift/)
[![Architecture](https://img.shields.io/badge/Architecture-Feature--First%20%2B%20Clean-emerald)](https://pub.dev)
[![State Management](https://img.shields.io/badge/State%20Management-Riverpod%203-blueviolet)](https://riverpod.dev)
[![Privacy](https://img.shields.io/badge/Privacy-100%25%20Local--First-success)](https://github.com)

**Clipper** is a high-performance, native-grade clipboard productivity suite engineered specifically for macOS. Combining the expressive UI capabilities of **Flutter** with the deep system-level integration of **Swift and AppKit**, Clipper continuously monitors clipboard activity, securely catalogs history locally, and provides instantaneous search, visual previews, text transformations, drag-and-drop organization, and privacy controls.

---

## Table of Contents

- [Executive Summary](#executive-summary)
- [System Architecture](#system-architecture)
  - [High-Level Architectural Flow](#high-level-architectural-flow)
  - [Native AppKit Layer (Swift)](#native-appkit-layer-swift)
  - [UI & State Layer (Flutter & Dart)](#ui--state-layer-flutter--dart)
- [Key Features](#key-features)
  - [1. Real-Time Clipboard Monitoring](#1-real-time-clipboard-monitoring)
  - [2. Multi-Type Capture & Rich Image Previews](#2-multi-type-capture--rich-image-previews)
  - [3. Interactive Drag & Drop Organization](#3-interactive-drag--drop-organization)
  - [4. Instant Search & Deep Filtering](#4-instant-search--deep-filtering)
  - [5. One-Click Text Transformations](#5-one-click-text-transformations)
  - [6. Native Menu Bar & Global Hotkey](#6-native-menu-bar--global-hotkey)
  - [7. Privacy & Application Blacklisting](#7-privacy--application-blacklisting)
  - [8. macOS Human Interface Guidelines (HIG) Theming](#8-macos-human-interface-guidelines-hig-theming)
- [Project Directory Layout](#project-directory-layout)
- [Platform Channel Interface](#platform-channel-interface)
- [Keyboard Shortcuts Reference](#keyboard-shortcuts-reference)
- [Getting Started & Development Setup](#getting-started--development-setup)
  - [Prerequisites](#prerequisites)
  - [Installation & Execution](#installation--execution)
  - [Release Build Creation](#release-build-creation)
- [Local Storage & Data Integrity](#local-storage--data-integrity)
- [Security, Privacy & Sandboxing](#security-privacy--sandboxing)
- [Contributing](#contributing)
- [License](#license)

---

## Executive Summary

Standard operating system clipboards are volatile and single-occupancy: copying new data irrevocably overwrites preceding content. **Clipper** transforms the macOS system pasteboard into a structured, searchable, and persistent productivity engine.

### Core Value Propositions:
* **Zero-Latency Monitoring**: Lightweight polling of `NSPasteboard.general.changeCount` with self-write suppression guarantees negligible CPU overhead (<0.01% idle utilization).
* **Multi-Modal Data Handling**: Full support for Plain Text, Web URLs, Rich Images (PNG/TIFF/JPEG/HEIC), File URLs, and Hex Color Codes.
* **100% Local-First Storage**: Zero cloud dependencies, zero external telemetry, and fully encrypted/isolated local file persistence.
* **Native Desktop Ergonomics**: System menu bar agent, global hotkey summoning (`⌘⇧V`), drag-and-drop reordering, and native Sonoma/Tahoe glassmorphic aesthetics.

---

## System Architecture

The application implements a decoupled, event-driven architecture bridging **macOS AppKit** (host environment) with **Flutter Desktop** (presentation layer) via high-performance platform channels.

### High-Level Architectural Flow

```
+-------------------------------------------------------------------------+
|                              macOS System                               |
|   +-------------------+    +--------------------+    +--------------+   |
|   | NSPasteboard.gen  |    | NSWorkspace (Apps) |    | Carbon HotKey|   |
|   +---------+---------+    +---------+----------+    +-------+------+   |
+-------------|------------------------|-----------------------|----------+
              |                        |                       |
              v                        v                       v
+-------------------------------------------------------------------------+
|                     Swift Native Subsystem (AppKit)                     |
|                                                                         |
|  +---------------------+   +---------------------+   +---------------+  |
|  |  ClipboardMonitor   |-->|   ClipboardReader   |-->|  NSStatusItem |  |
|  | (ChangeCount Poll)  |   | (TIFF->PNG, URLs)   |   |   (MenuBar)   |  |
|  +---------------------+   +---------------------+   +---------------+  |
|             |                         |                      |          |
|             +------------+------------+                      |          |
|                          v                                   v          |
|             +-------------------------+             +----------------+  |
|             |   MacPlatformBridge     |<----------->| GlobalShortcut |  |
|             | (Method & EventChannels)|             +----------------+  |
+--------------------------|----------------------------------------------+
                           |
            Platform Channel Communication
      (com.clipper/methods & /events)
                           |
                           v
+-------------------------------------------------------------------------+
|                  Flutter / Dart Application Subsystem                   |
|                                                                         |
|  +-------------------------------------------------------------------+  |
|  |                  NativeClipboardBridge (Service)                  |  |
|  +---------------------------------+---------------------------------+  |
|                                    v                                    |
|  +-------------------------------------------------------------------+  |
|  |            ClipboardNotifier (Riverpod 3 State Management)         |  |
|  +---------------------------------+---------------------------------+  |
|                                    |                                    |
|          +-------------------------+-------------------------+          |
|          v                                                   v          |
|  +-------------------------------+           +-----------------------+  |
|  |     Presentation Layer        |           |      Storage Layer    |  |
|  |  - MainClipboardScreen        |           |  - ClipboardStorage   |  |
|  |  - ReorderableListView        |           |  - SettingsStorage    |  |
|  |  - ClipboardItemTile          |           |  - PNG Image Cache    |  |
|  |  - SettingsDialog (Tabbed)    |           +-----------------------+  |
|  +-------------------------------+                                      |
+-------------------------------------------------------------------------+
```

### Native AppKit Layer (Swift)

Located in `macos/Runner/`:

* **`ClipboardMonitor.swift`**: Polls `NSPasteboard.general.changeCount` at 250ms intervals. Employs a self-write suppression mechanism (`notifySelfWrite`) to prevent feedback loops when Clipper re-copies historical records back to the clipboard.
* **`ClipboardReader.swift`**: Extracts data types in prioritized sequence:
  1. `[NSURL]` file arrays (with auto-detection of single image files).
  2. `NSImage` via `tiffRepresentation` -> `NSBitmapImageRep` conversion to standard PNG. Saves full-resolution images to the application support sandbox and attaches base64 thumbnails for instant in-memory rendering.
  3. `NSPasteboard.PasteboardType.string` with URI schema inspection (HTTP/HTTPS/FTP).
  4. Hex color representation for system color pickers.
* **`ClipboardWriter.swift`**: Directly handles writing back strings, file URLs, and raw `NSImage` instances onto `NSPasteboard.general`.
* **`ActiveApplicationManager.swift`**: Captures the bundle identifier (`com.google.Chrome`, `com.apple.finder`, etc.) and localized name of the frontmost application active when the copy occurred.
* **`MenuBarManager.swift`**: Configures and manages the status item in the macOS system menu bar, offering instant popup controls, pause/resume toggling, and history purging.
* **`GlobalShortcutManager.swift`**: Installs a low-level Carbon HotKey event handler for `⌘⇧V` (Command + Shift + V) allowing system-wide focus and window toggling.

### UI & State Layer (Flutter & Dart)

Located in `lib/`:

* **Riverpod 3 State Machine**: Unidirectional data flow driven by `NotifierProvider<ClipboardNotifier, ClipboardState>`. Reactively responds to native pasteboard events, search filters, and manual item transformations.
* **Clean Feature Structure**: Strict modular decoupling into `core`, `features/clipboard`, and `features/settings`.
* **Atomic Storage Engine**: Direct local disk persistence using JSON documents with atomic replace patterns to prevent data corruption during unexpected terminations.

---

## Key Features

### 1. Real-Time Clipboard Monitoring
* Monitors the macOS clipboard continuously in background daemon mode.
* Automatically records source application metadata, timestamp, content length, and copy frequency.
* Deduplication engine: configurable to update timestamp & increment copy counter (`2x`, `3x`), create discrete records, or ignore duplicates.

### 2. Multi-Type Capture & Rich Image Previews
* **Visual Thumbnails**: When copying images or capturing screenshots (`⌘⌃⇧4`), converts raw TIFF/pasteboard data into standard PNG files stored at `~/Library/Application Support/.../images/{id}.png`.
* **Instant Rendering**: Flutter tiles display aspect-fitted visual thumbnails, dimension and file-size badges, and high-resolution zoomed inspection dialogs.
* **Finder Image Recognition**: Copying an image file directly in macOS Finder immediately tags it as an Image item rather than a generic file, enabling inline visual previewing.

### 3. Interactive Drag & Drop Organization
* **Fluid Reordering**: Replaced static scrollable lists with `ReorderableListView.builder` configured with zero-conflict grab handles (`Icons.drag_indicator_rounded`).
* **Gesture Arena Isolation**: Drag handles utilize dedicated opaque hit-test boundaries, preventing card click events or text selection from interfering with drag gestures.
* **Synchronized Storage**: Drag reordering immediately syncs indices across both filtered active views and master disk storage.
* **Fast Movement Shortcuts**: Includes **Move to Top** and **Move to Bottom** action menu commands for instantaneous repositioning.

### 4. Instant Search & Deep Filtering
* **Sub-millisecond Search**: Real-time filtering across item content, metadata titles, file paths, and source applications.
* **Category Filtering**: Filter instantly between **All History**, **Pinned Items**, **Favorites**, and specific types (**Text**, **Links / URLs**, **Images**, **Files**).
* **Application Facets**: Dedicated sidebar section breaking down clipboard items by source application (e.g., Google Chrome, Antigravity IDE, Xcode, Slack).
* **Search UX**: macOS-native search bar equipped with `⌘K` keyboard shortcut, clear button, and centered vertical alignment.

### 5. One-Click Text Transformations
Directly transform any copied text snippet without pasting into an external editor:
* **UPPERCASE** & **lowercase**
* **Title Case** & **Capitalize Words**
* **Trim Whitespace** & **Remove Line Breaks**
* **URL Encode** & **URL Decode**
* **Base64 Encode** & **Base64 Decode**
* **JSON Prettifier / Formatter**
* **Slugify** (kebab-case URL friendly formatting)

### 6. Native Menu Bar & Global Hotkey
* **Menu Bar Resident with Live History**: Clicking the menu bar status icon displays an active list of your recent copied items:
  * **Instant 1-Click Copy**: Clicking any item in the menu immediately copies it to your clipboard. Number keys `1`–`9` act as instant keyboard shortcuts.
  * **Visual Thumbnails in Menu Bar**: Image clipboard items render true 16×16 visual thumbnails right inside the native macOS dropdown.
  * **Multiple Deletion Workflows**:
    * **Per-Item Submenu**: Hovering over any item's arrow provides explicit `📋 Copy to Clipboard` and `🗑 Delete Item` choices.
    * **Native `⌥ Option` Modifier**: Hold the **Option (`⌥`)** key while looking at the menu — all items dynamically switch to `🗑 Delete: [Item Title]`.
    * **Dedicated Submenu**: `🗑 Delete an Item...` lists items for fast one-click removal.
    * **Purge All History**: Wipes history directly from the menu bar without opening the full UI.
* **Global Shortcut (`⌘⇧V`)**: Summon or dismiss the clipboard interface from any workspace or full-screen app via low-level Carbon HotKey APIs.
* **Keyboard Navigation**: Full keyboard navigation support (`⌘K` to search, `Esc` to dismiss, `⌘,` for Settings, `1`–`9` for menu bar fast-copy).

### 7. Privacy & Application Blacklisting
* **App Exclusion**: Add sensitive applications (e.g., 1Password, Bitwarden, Apple Keychain, Terminal) to an excluded blacklist. Any copy events originating from blacklisted bundle IDs are discarded at the native layer.
* **Sensitive Content Detection**: Flags suspected credit cards, API keys, passwords, and private tokens with warning badges and optional exclusion.
* **Zero Telemetry**: All data remains strictly on your local disk.

### 8. macOS Human Interface Guidelines (HIG) Theming
* Native typography, SF Pro font stack, and adaptive palette conforming to macOS Sonoma and Tahoe design systems.
* Supports **Light Theme**, **Dark Theme (Graphite)**, and **System Automatic Theme**.
* Subtle borders, responsive hover states, smooth micro-interactions, and high-contrast accessibility compliance.

---

## Project Directory Layout

```text
clipper/
├── lib/
│   ├── main.dart                                    # Application entrypoint & ProviderScope
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart                   # Global configuration constants & limits
│   │   ├── services/
│   │   │   └── native_clipboard_bridge.dart         # MethodChannel & EventChannel implementation
│   │   ├── theme/
│   │   │   └── app_theme.dart                       # macOS Light & Dark design systems
│   │   └── utils/
│   │       └── text_transformations.dart            # Case, encoding, slug, and JSON formatters
│   └── features/
│       ├── clipboard/
│       │   ├── data/
│       │   │   └── clipboard_storage.dart           # Atomic JSON disk persistence engine
│       │   ├── domain/
│       │   │   ├── clipboard_item.dart              # Clipboard entity model & serialization
│       │   │   ├── clipboard_state.dart             # Riverpod UI state representation
│       │   │   └── clipboard_type.dart              # Data types & TransformationType enums
│       │   └── presentation/
│       │       ├── providers/
│       │       │   └── clipboard_provider.dart      # Business logic & clipboard event handler
│       │       ├── screens/
│       │       │   └── main_clipboard_screen.dart   # Main split-view dashboard & toolbar
│       │       └── widgets/
│       │           ├── clipboard_item_tile.dart     # Interactive card with image previews & drag handles
│       │           ├── clipboard_detail_dialog.dart # Full inspector modal with image viewer
│       │           └── edit_clipboard_dialog.dart   # In-place content editor dialog
│       └── settings/
│           ├── data/
│           │   └── settings_storage.dart            # Settings disk storage manager
│           ├── domain/
│           │   └── settings_state.dart              # User preferences model
│           └── presentation/
│               ├── settings_provider.dart           # Preferences state notifier
│               └── screens/
│                   └── settings_dialog.dart         # Native macOS tabbed preferences dialog
├── macos/
│   └── Runner/
│       ├── AppDelegate.swift                        # App lifecycle initialization
│       ├── MainFlutterWindow.swift                  # Window chrome styling & FlutterViewController
│       ├── Bridge/
│       │   └── MacPlatformBridge.swift              # Bi-directional AppKit <-> Flutter channel bridge
│       ├── Clipboard/
│       │   ├── ClipboardMonitor.swift               # Background pasteboard observer & change detection
│       │   ├── ClipboardReader.swift                # Multi-type pasteboard reader & image PNG exporter
│       │   └── ClipboardWriter.swift                # Native write-back engine for text, files, & images
│       ├── Applications/
│       │   └── ActiveApplicationManager.swift       # NSWorkspace frontmost application resolver
│       ├── MenuBar/
│       │   └── MenuBarManager.swift                 # NSStatusItem macOS menu bar integration
│       └── Shortcuts/
│           └── GlobalShortcutManager.swift          # Carbon API global hotkey registration
├── pubspec.yaml                                     # Dependencies & assets declaration
└── README.md                                        # Technical documentation
```

---

## Platform Channel Interface

Communication between Swift and Flutter is conducted over two designated channels:

### 1. Method Channel: `com.clipper/methods`

| Method Name | Direction | Arguments | Return Type | Description |
|---|---|---|---|---|
| `startMonitoring` | Flutter -> Swift | None | `bool` | Starts the pasteboard observer timer. |
| `stopMonitoring` | Flutter -> Swift | None | `bool` | Stops the pasteboard observer timer. |
| `pauseMonitoring` | Flutter -> Swift | `{ "seconds": Double? }` | `bool` | Temporarily suspends clipboard capture. |
| `resumeMonitoring` | Flutter -> Swift | None | `bool` | Resumes clipboard capture. |
| `isMonitoring` | Flutter -> Swift | None | `bool` | Queries observer running state. |
| `isPaused` | Flutter -> Swift | None | `bool` | Queries observer pause state. |
| `readClipboard` | Flutter -> Swift | None | `Map<String, Any>?` | Reads the current pasteboard snapshot on-demand. |
| `writeClipboard` | Flutter -> Swift | `{ "type": String, "content": String, "filePath": String? }` | `bool` | Writes an item back to `NSPasteboard` without loopback. |
| `updateMenuBarItems` | Flutter -> Swift | `List<Map<String, Any>>` | `bool` | Synchronizes active clipboard items with native Menu Bar. |
| `getFrontmostApplication` | Flutter -> Swift | None | `{ "name": String, "bundleId": String }` | Retrieves active app info. |
| `setExcludedApplications` | Flutter -> Swift | `List<String>` | `bool` | Updates the native bundle ID exclusion list. |
| `showMainWindow` | Flutter -> Swift | None | `bool` | Focuses and brings main window to front. |
| `hideMainWindow` | Flutter -> Swift | None | `bool` | Minimizes or orders out the main window. |
| `toggleMainWindow` | Flutter -> Swift | None | `bool` | Toggles main window visibility. |
| `onClearHistoryRequested` | Swift -> Flutter | None | `void` | Triggered when Menu Bar requests history wipe. |
| `onItemCopiedFromMenuBar` | Swift -> Flutter | `Map<String, Any>` | `void` | Triggered when an item is copied from the Menu Bar dropdown. |
| `onItemDeletedFromMenuBar`| Swift -> Flutter | `String` (item ID) | `void` | Triggered when an item is deleted from the Menu Bar dropdown. |
| `onGlobalShortcutTriggered`| Swift -> Flutter | None | `void` | Triggered when `⌘⇧V` is pressed system-wide. |

### 2. Event Channel: `com.clipper/events`

* **Event Stream**: Broadcasts a dictionary payload whenever `ClipboardMonitor` detects a new pasteboard item:
  ```json
  {
    "id": "B1E91CF8-8928-44A1-94E5-C808E5F0288E",
    "type": "IMAGE",
    "content": "data:image/png;base64,iVBORw0KGgo...",
    "title": "Image (120 KB)",
    "preview": "[Image 120 KB]",
    "filePath": "/Users/.../Application Support/.../images/B1E91CF8.png",
    "sourceAppName": "Google Chrome",
    "sourceAppBundleId": "com.google.Chrome",
    "timestamp": 1728000000000
  }
  ```

---

## Keyboard Shortcuts Reference

| Shortcut | Scope | Action |
|---|---|---|
| `⌘⇧V` (Command + Shift + V) | Global (System-wide) | Toggle Clipper window |
| `1` – `9` | Menu Bar Dropdown | Instantly copy items 1 through 9 |
| `⌥` (Hold Option) | Menu Bar Dropdown | Dynamically switch items to Delete mode |
| `Single Click` | In-App Tile / Menu Bar | Instantly copy item to clipboard |
| `Double Click` | In-App Tile | Open full detail inspector modal |
| `App Logo Click` | In-App Header | Reset view to Show All History |
| `Drag Handle` | In-App Tile | Reorder items in history list |
| `⌘K` | In-App | Focus search box |
| `⌘,` | In-App | Open Settings & Preferences |
| `⌘A` | In-App | Toggle Selection / Batch mode |
| `⌘⌫` (Command + Backspace) | In-App | Clear all clipboard history |
| `Esc` | In-App | Clear search / Close modal / Exit selection mode |

---

## Getting Started & Development Setup

### Prerequisites

* **macOS**: 12.0 (Monterey) or later (Tested on macOS 14 Sonoma & macOS 15 Sequoia).
* **Xcode**: 15.0 or later with Command Line Tools installed (`xcode-select --install`).
* **Flutter SDK**: 3.19.0 or later with Dart 3.x (`flutter doctor`).

### Installation & Execution

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/clipper.git
   cd clipper
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify static analysis**:
   ```bash
   flutter analyze
   ```

4. **Launch in Debug mode**:
   ```bash
   flutter run -d macos
   ```

---

### Release Build Creation

To compile an optimized, standalone macOS desktop application bundle:

```bash
flutter build macos --release
```

The resulting executable will be located at:
```
build/macos/Build/Products/Release/Clipper.app
```

To run the release bundle directly:
```bash
open "build/macos/Build/Products/Release/Clipper.app"
```

---

## Local Storage & Data Integrity

All application data is isolated within the sandboxed user Application Support directory:

* **Clipboard Records**:
  ```
  ~/Library/Application Support/com.clipper.app/database/clipboard_history.json
  ```
* **User Preferences**:
  ```
  ~/Library/Application Support/com.clipper.app/database/settings.json
  ```
* **Persistent PNG Images**:
  ```
  ~/Library/Application Support/com.clipper.app/images/{UUID}.png
  ```

Data writes are atomic: content is committed via temporary buffers before renaming, preventing partial-write corruption during power interruptions or force-close events.

---

## Security, Privacy & Sandboxing

* **Local-First Processing**: No network client or socket is initialized. The application functions completely offline.
* **Zero Loopback Vulnerability**: Custom `changeCount` tracking ensures Clipper never re-records its own write actions.
* **Password Manager Protection**: Built-in support to exclude standard password management software (`com.agilebits.onepassword`, `com.bitwarden.desktop`, etc.).
* **Entitlements**: Uses minimum necessary macOS entitlements for pasteboard monitoring and file access within its container.

---

## Contributing

1. Fork the repository and create your feature branch:
   ```bash
   git checkout -b feature/amazing-feature
   ```
2. Commit your modifications with descriptive commit messages following Conventional Commits:
   ```bash
   git commit -m "feat(image-preview): add thumbnail cache retention policy"
   ```
3. Verify static analysis and formatting:
   ```bash
   flutter analyze
   dart format --set-exit-if-changed .
   ```
4. Push to the branch and open a Pull Request.

---

## License

This project is distributed under the **MIT License**. See `LICENSE` for comprehensive terms and conditions.

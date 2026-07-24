# KOReader Things

A homepage for my KOReader-related projects: Android-focused plugins and one small user patch that make KOReader fit my reading setup better.

## Plugins

### [Syncest](https://github.com/titandrive/syncest)

Syncest syncs KOReader reading data to a WebDAV folder you control.

It can sync reading progress, annotations, reading stats, vocabulary, and an optional book library across multiple KOReader devices. The goal is to keep your reading data in your own storage instead of tying it to a single device or service.

### [Bluetooth Configurator](https://github.com/titandrive/bluetoothconfigurator.koplugin)

Bluetooth Configurator makes it easier to map Bluetooth page turners, controllers, remotes, and hardware keyboards to KOReader actions on Android.

Instead of manually editing KOReader keymapping files, you can press a button, pick an action, and save the binding from inside KOReader. It supports separate bindings for the reader and file manager.

### [KOBoard](https://github.com/titandrive/koboard)

KOBoard replaces KOReader's built-in virtual keyboard with the Android system keyboard.

This lets you use your normal Android keyboard app for KOReader text input, including keyboards like Gboard, Samsung Keyboard, and Heliboard. It is Android-only and experimental.

## Patches

### [UI Font Patch](https://github.com/titandrive/koreader/blob/main/patches/2--ui-font_updated.lua)

A KOReader user patch that adds a UI font picker to the file manager and reader settings menus.

It lets you choose the font used by KOReader's interface, saves the selected font, updates KOReader's UI font map, and prompts for a restart so the change applies cleanly. This is a modified version of sebdelsol's UI font patch with fixes for newer KOReader behavior and Android devices where font paths can differ from KOReader's normal font scan.

Install it as:

```text
2--ui-font.lua
```

### [Move to Archive Patch](patches/2-move-to-archive.lua)

A KOReader user patch that adds **Move to archive** to the long-press book menu in History (library), Collections, file search, and File Manager views.

For books already in the configured archive folder, the action changes to **Move to library**. The patch remembers each book's original folder when archiving it and restores it there; for books archived before the patch was installed, it falls back to KOReader's HOME folder.

Install it as:

```text
2-move-to-archive.lua
```

### [Custom Center Gestures Patch](patches/2-custom-center-gestures.lua)

Adds a **Center gestures** section to KOReader's Gesture Manager with fourteen
additional assignable gestures:

- Tap at the top center, screen center, or bottom center
- Long-press at the top center, screen center, or bottom center
- One-finger swipe from the top or bottom to the screen center
- Two-finger swipe from the top or bottom to the screen center
- One-finger swipe from the screen center to the top or bottom
- Two-finger swipe from the screen center to the top or bottom

The Center gestures menu organizes these into separate **Taps**,
**Long-presses**, **One-finger swipes**, and **Two-finger swipes** sections.

Each gesture can have different actions in the Reader and File Manager, just
like KOReader's built-in gestures. The swipe gestures check both their starting
zone and endpoint, allowing the two-finger variants to remain distinct from the
normal full-screen two-finger swipe up and down gestures.

Inspired by the r/KOReader post
[“Bunch of custom gestures”](https://www.reddit.com/r/koreader/comments/1v1dczh/bunch_of_custom_gestures/).

Install it as:

```text
2-custom-center-gestures.lua
```

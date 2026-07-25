# KOReader Things

A homepage for my KOReader-related plugins and user patches.

## Plugins

### [Syncest](https://github.com/titandrive/syncest)

**Platforms:** Multi-platform

Syncest syncs KOReader reading data to a WebDAV folder you control.

It can sync reading progress, annotations, reading stats, vocabulary, and an optional book library across multiple KOReader devices. The goal is to keep your reading data in your own storage instead of tying it to a single device or service.

### [Bluetooth Configurator](https://github.com/titandrive/bluetoothconfigurator.koplugin)

**Platforms:** Android only

Bluetooth Configurator makes it easier to map Bluetooth page turners, controllers, remotes, and hardware keyboards to KOReader actions on Android.

Instead of manually editing KOReader keymapping files, you can press a button, pick an action, and save the binding from inside KOReader. It supports separate bindings for the reader and file manager.

### [KOBoard](https://github.com/titandrive/koboard)

**Platforms:** Android only

KOBoard replaces KOReader's built-in virtual keyboard with the Android system keyboard.

This lets you use your normal Android keyboard app for KOReader text input, including keyboards like Gboard, Samsung Keyboard, and Heliboard. It is Android-only and experimental.

## Patches

### [UI Font Patch](https://github.com/titandrive/koreader/blob/main/patches/2--ui-font_updated.lua)

A KOReader user patch that adds a UI font picker to the file manager and reader settings menus.

It lets you choose the font used by KOReader's interface, saves the selected font, updates KOReader's UI font map, and prompts for a restart so the change applies cleanly.

Original patch by [sebdelsol](https://github.com/sebdelsol/KOReader.patches).

Changes from the original:

- Uses crengine's discovered font faces directly instead of requiring their
  paths to also match KOReader's separate `FontList` scan. This prevents valid
  fonts from disappearing on devices where the two path sources differ,
  including some Android and Boox setups.
- Asks crengine for each font's actual bold face instead of guessing it by
  changing `-Regular` to `-Bold` in the filename. If no bold face is available,
  it safely falls back to the regular face.

Install it as:

```text
2--ui-font.lua
```

### [Move to Archive Patch](patches/2-move-to-archive.lua)

A KOReader user patch that adds **Move to archive** to the long-press book menu in History (library), Collections, file search, and File Manager views. After moving a book, the menu closes and the active view refreshes immediately.

For books already in the configured archive folder, the action changes to **Move to library**. The patch remembers each book's original folder when archiving it and restores it there; for books archived before the patch was installed, it falls back to KOReader's HOME folder.

The end-of-book popup also gains **Mark as complete and archive**, which marks the finished book as complete, moves it to the configured archive folder, and returns to the folder it was archived from.

Install it as:

```text
2-move-to-archive.lua
```

### [Bonus Gestures Patch](patches/2-bonus-gestures.lua)

Adds a **Bonus gestures** section to KOReader's Gesture Manager with fourteen
additional assignable gestures. They appear in this order:

- **Tap**
  - Center
- **Long-press**
  - Top center
  - Center left
  - Center / center
  - Center right
  - Bottom center
- **One-finger swipe**
  - Top to center
  - Center to top
  - Bottom to center
  - Center to bottom
- **Two-finger swipe**
  - Top to center
  - Center to top
  - Bottom to center
  - Center to bottom

Each gesture can have different actions in the Reader and File Manager, just
like KOReader's built-in gestures. The swipe gestures check both their starting
zone and endpoint, allowing the two-finger variants to remain distinct from the
normal full-screen two-finger swipe up and down gestures.

> **Note:** Custom gestures may overlap with existing KOReader actions in the
> same screen area. For example, assigning an action to **Long-press → Center / center**
> in the Reader will take priority over the normal long-press used to select and
> highlight text in that center zone.

Inspired by the r/KOReader post
[“Bunch of custom gestures”](https://www.reddit.com/r/koreader/comments/1v1dczh/bunch_of_custom_gestures/).

Install it as:

```text
2-bonus-gestures.lua
```

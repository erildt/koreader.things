# KOReader Things

A homepage for my KOReader-related projects: plugins, Android-focused experiments, and small patches that make KOReader fit my reading setup better.

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

### [KOReader Patches](https://github.com/titandrive/koreader_things)

Small patches and tweaks for KOReader that do not make sense as standalone plugins.

This is where I keep changes that patch KOReader behavior directly, experiment with upstream changes, or support my personal KOReader setup. These may be rougher than the plugin repos and may need to be updated when KOReader changes.

## Installation

Each plugin has its own README and release downloads:

- [Syncest releases](https://github.com/titandrive/syncest/releases)
- [Bluetooth Configurator releases](https://github.com/titandrive/bluetoothconfigurator.koplugin/releases)
- [KOBoard releases](https://github.com/titandrive/koboard/releases)

In general, KOReader plugins are installed by placing the `.koplugin` folder inside KOReader's `plugins` directory and restarting KOReader.

Patches are different: check the patch repo for details, because they may depend on a specific KOReader version or source layout.

## Platform Notes

Most of these projects are focused on KOReader running on Android-based e-readers, especially devices like Boox, Bigme, and other Android readers.

Check each project before installing. Some are Android-only and will not work on Kindle, Kobo, or other non-Android KOReader platforms.

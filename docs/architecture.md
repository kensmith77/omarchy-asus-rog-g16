# Architecture

`Panel.qml` is the Omarchy bar-widget entry point. It reads a JSON snapshot
from `bin/asus-g16-control state` and sends all mutations back through the same
command, keeping shell UI code away from parsing hardware-specific output.

The control command has three backends:

1. `asusctl` for ROG firmware, profiles, battery, and Aura lighting.
2. `~/.config/omarchy/asus-g16/settings.json` for durable plugin preferences.
3. `~/.config/hypr/asus-g16.lua` for touchpad, gestures, and special-key binds.

Firmware capabilities are discovered from `asusctl armoury list`. This keeps
the panel usable across GU605 variants without displaying dead toggles.

The QML process receives argument arrays rather than shell strings. User-entered
RGB values are validated again by the control command before reaching
`asusctl`. Gesture and key commands are selected from fixed allowlists; they
cannot inject arbitrary shell text into the generated Lua module.

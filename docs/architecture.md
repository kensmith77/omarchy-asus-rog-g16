# Architecture

`Panel.qml` is the Omarchy bar-widget entry point. It reads a JSON snapshot
from `bin/asus-g16-control state` and sends all mutations back through the same
command, keeping shell UI code away from parsing hardware-specific output.

The control command has three backends:

1. `asusctl` for ROG firmware writes, profiles, battery, Aura, and Slash lighting.
2. `~/.config/omarchy/asus-g16/settings.json` for durable plugin preferences.
3. `~/.config/hypr/asus-g16.lua` for touchpad, gestures, and special-key binds.

Firmware capabilities and current values are read from Linux's
`/sys/class/firmware-attributes/asus-armoury/attributes` interface. This keeps
refreshes immediate and avoids displaying controls unavailable on a GU605
variant.

Slash LED writes use `asusctl slash set`; their last selected values live in
the plugin settings so the shell does not need to block on repeated D-Bus
reads. Special-key actions are generated as native Hyprland Lua binds. The
Copilot key removes both its `F23` and `code:201` aliases before rebinding, so
Omarchy's stock launcher action cannot fire alongside the selected command.

The QML process receives argument arrays rather than shell strings. User-entered
RGB values are validated again by the control command before reaching
`asusctl`. Gesture and key commands are selected from fixed allowlists; they
cannot inject arbitrary shell text into the generated Lua module.

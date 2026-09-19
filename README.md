# ASUS ROG Zephyrus G16 controls for Omarchy

A native Omarchy shell panel for the ASUS ROG Zephyrus G16. It is tuned for
the GU605 family and detects optional firmware controls before showing them.

## Features

- Keyboard backlight brightness and Aura static, breathe, and rainbow effects
- Slash LED enable, brightness, interval, animation, and boot/sleep/battery behavior
- Quiet, Balanced, and Performance profiles
- Battery charge limit
- Boot sound, panel overdrive, Eco/dGPU-disable, and discrete GPU MUX toggles
- GPU TGP, Dynamic Boost, temperature target, and CPU PL1/PL2 tuning
- Reassignable M1–M4 and Copilot keys, including custom commands and key combos
- Trackpad enable, natural scrolling, pointer/scroll speed, tap-to-click,
  clickfinger, disable-while-typing, drag lock, and middle-click emulation
- Configurable 3- and 4-finger swipe gestures

Workspace swipes use Hyprland's `-1` / `+1` relative-ID selectors so they traverse
empty numbered workspaces as well as occupied ones. Fullscreen and close use
Hyprland's native gesture actions rather than shell subprocesses.

The panel only invokes `asusctl` and writes one isolated Hyprland module:
`~/.config/hypr/asus-g16.lua`. It adds one `require("hypr.asus-g16")` line to
the user-owned `~/.config/hypr/hyprland.lua` and saves the original as
`hyprland.lua.bak.asus-g16` before the first change.

## Requirements

- Omarchy 4 or later
- `asusctl` / `asusd` 6.5 or later
- `jq`
- A Hyprland session

## Install

From a published Git repository:

```bash
omarchy plugin add https://github.com/design-nexus/omarchy-asus-rog-g16.git --enable
```

The checked-out plugin on this machine already lives at:

```text
~/.config/omarchy/plugins/asus.rog-g16
```

Enable it on the right side of the bar with:

```bash
omarchy plugin enable asus.rog-g16 --section right
```

## Command-line interface

The panel is backed by `bin/asus-g16-control`, which can also be used directly:

```bash
bin/asus-g16-control state | jq
bin/asus-g16-control doctor
bin/asus-g16-control set touchpad.scrollFactor 0.6
bin/asus-g16-control set keys.m4 control-panel
bin/asus-g16-control set-led-brightness high
bin/asus-g16-control set-led-effect static 7c3aed
bin/asus-g16-control set-slash enabled true
bin/asus-g16-control set-slash mode Spectrum
bin/asus-g16-control set-charge-limit 80
bin/asus-g16-control set keys.m4 custom-command
bin/asus-g16-control set keyCommands.m4 "notify-send 'M4 pressed'"
bin/asus-g16-control set keys.copilot key-combo
bin/asus-g16-control set keyCombos.copilot "CTRL + SHIFT + T"
```

## Gesture constraints

The Linux input stack reserves two-finger movement for scrolling. Libinput
maps two- and three-finger taps through `tap_button_map`, so the panel offers
the two useful conventions:

- `lrm`: two fingers right-click, three fingers middle-click
- `lmr`: two fingers middle-click, three fingers right-click

The GU605 touchpad/libinput combination does not emit a four-finger tap event.
The plugin therefore exposes four-finger swipes instead of presenting a
setting that cannot work.

## Special-key notes

On this laptop generation, M1–M3 arrive as the standard volume-down,
volume-up, and microphone-mute keysyms. M4 arrives as `XF86Launch1`, and the
Copilot key arrives as `Super+Shift+code:201` (`F23`). The plugin removes
Omarchy's existing launcher binding for that code before installing the chosen
action, preventing one press from launching both Codex and the app menu.

Each special key can also run a custom one-line shell command or send a custom
key combination such as `CTRL + SHIFT + T` to the focused application.

If a firmware update changes a keysym, run `wev`, press the key once, and use
the reported keysym in the generated `~/.config/hypr/asus-g16.lua` mapping.

## Safety and recovery

The plugin never edits `/usr/share/omarchy`. To disable it:

```bash
omarchy plugin disable asus.rog-g16
```

To remove its Hyprland integration, delete the single
`require("hypr.asus-g16")` line from `~/.config/hypr/hyprland.lua`, then remove
`~/.config/hypr/asus-g16.lua` and reload Hyprland.

Changing GPU MUX mode can require a logout or reboot. Eco mode and discrete
MUX mode are intentionally separate firmware controls; avoid enabling both at
the same time.

## License

MIT

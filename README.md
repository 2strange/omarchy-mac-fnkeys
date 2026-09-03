# MacBook Function Keys

Omarchy plugin for MacBooks with the Apple keyboard driver (`hid_apple`). It
makes the function row send its printed functions (brightness, volume, media,
Mission Control, Spotlight, Do Not Disturb) without holding Fn, the way macOS
does, and adds a bar icon that switches the row back to F1-F12 when you need
real function keys.

Omarchy's Apple install defaults the other way (`fnmode=2`), which is why
brightness and volume require Fn out of the box.

![Fn keys toggle in the Omarchy bar](preview.png)

## Bar icon

| Icon | Meaning | Click |
| --- | --- | --- |
| 󰃞 | Printed keys (brightness, volume, media) without Fn | Switch to F1-F12 |
| 󰡀 | F1-F12 without Fn | Switch to printed keys |
| 󰌌 | One-time setup has not run yet | Run setup in a floating terminal |

Hover the icon for a tooltip describing the current mode. The mode persists
across shell reloads and reboots. The icon hides itself on machines where
`hid_apple` is not loaded.

## Function row in printed-keys mode

Tested on a 2021 14-inch MacBook Pro (MacBookPro18,3). Other MacBooks with the
same row layout should behave the same.

| Key | Printed function | Linux key | Omarchy action |
| --- | --- | --- | --- |
| F1 | Brightness down | `XF86MonBrightnessDown` | Display brightness down |
| F2 | Brightness up | `XF86MonBrightnessUp` | Display brightness up |
| F3 | Mission Control | `XF86LaunchA` | Apps menu |
| F4 | Spotlight | `XF86Search` | Omarchy menu |
| F5 | Dictation | `XF86AudioMicMute` | Microphone mute |
| F6 | Do Not Disturb | `XF86Sleep` | Silence notifications |
| F7 | Previous | `XF86AudioPrev` | Previous track |
| F8 | Play/Pause | `XF86AudioPlay` | Play/pause |
| F9 | Next | `XF86AudioNext` | Next track |
| F10 | Mute | `XF86AudioMute` | Mute |
| F11 | Volume down | `XF86AudioLowerVolume` | Volume down |
| F12 | Volume up | `XF86AudioRaiseVolume` | Volume up |

Hold **Fn** to get real F1-F12 for terminals and IDEs, or click the bar icon
to make F1-F12 the default.

F6 is `KEY_SLEEP` to the kernel. While printed-keys mode is active the plugin
holds a logind `handle-suspend-key` inhibitor so the key silences
notifications instead of suspending the machine. The inhibitor is released as
soon as you switch to F1-F12 or the shell exits.

## Install

```sh
omarchy plugin add https://github.com/alnandr/omarchy-macbook-fn-keys.git --enable
```

Then click the 󰌌 icon on the right of the bar (or run the setup script
directly) and enter your password once:

```sh
~/.config/omarchy/plugins/io.github.alnandr.macbook-fn-keys/scripts/setup
```

Setup does three things, all reversible:

1. Installs a root-owned helper at `/usr/local/libexec/omarchy-mac-fnmode` and
   a sudoers rule in `/etc/sudoers.d/omarchy-mac-fnmode` that lets your user
   run exactly `omarchy-mac-fnmode 1` and `omarchy-mac-fnmode 2` without a
   password. Nothing else is granted; the helper accepts no other arguments.
2. Switches `hid_apple` to `fnmode=1` and persists it in
   `/etc/modprobe.d/hid_apple.conf` (the same file Omarchy's Apple install
   writes).
3. Appends one clearly marked block to `~/.config/hypr/bindings.lua` that
   loads `hypr/bindings.lua` from the plugin folder (F3, F4, F6). Nothing
   already in that file is modified.

## How it works

- `Service.qml` reads `/sys/module/hid_apple/parameters/fnmode` directly (no
  privileges needed), holds the F6 suspend inhibitor, and runs the helper
  through `sudo -n` when you click.
- `BarWidget.qml` paints the mode and forwards clicks to the service, so all
  monitors show the same state.
- `scripts/omarchy-mac-fnmode` is the only privileged code path. Read it before
  running setup; it is under 60 lines.

## Dependencies

Everything used is part of a standard Omarchy install: `sudo`, `visudo`,
`systemd-inhibit`, `hyprctl`, and the JetBrainsMono Nerd Font for the bar
glyphs. No packages are installed and nothing is downloaded.

## Remove

```sh
~/.config/omarchy/plugins/io.github.alnandr.macbook-fn-keys/scripts/uninstall
omarchy plugin remove io.github.alnandr.macbook-fn-keys
```

Uninstall restores Omarchy's Apple default (`fnmode=2`), removes the helper
and sudoers rule, and removes the marked block from `bindings.lua`.

## License

MIT. See [LICENSE](LICENSE).

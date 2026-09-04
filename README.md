# MacBook Function Keys

Omarchy plugin for MacBooks with the Apple keyboard driver (`hid_apple`). It
makes the function row send its printed functions (brightness, volume, media,
Mission Control, Spotlight, Do Not Disturb) without holding Fn, the way macOS
does, and adds a bar icon that switches the row back to F1-F12 when you need
real function keys.

Omarchy's Apple install defaults the other way (`fnmode=2`), which is why
brightness and volume require Fn out of the box.

![Right section of the Omarchy top bar with the Fn keys toggle showing printed-keys mode](https://raw.githubusercontent.com/alnandr/omarchy-macbook-fn-keys/89c6c8623539a67271f64bda4b550e0457dfdd9e/preview.png)

The <img src="docs/icons/media.png" width="16" alt="brightness icon"> icon sits in the right section of the bar, next to the tray, and
shows that the function row is currently sending its printed keys.

## Bar icon

| Icon | Meaning | Click |
| --- | --- | --- |
| <img src="docs/icons/media.png" width="24" alt="brightness icon"> | Printed keys (brightness, volume, media) without Fn | Switch to F1-F12 |
| <img src="docs/icons/fkeys.png" width="24" alt="function key icon"> | F1-F12 without Fn | Switch to printed keys |
| <img src="docs/icons/keyboard.png" width="24" alt="keyboard icon"> | One-time setup has not run yet | Run setup in a floating terminal |

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

Then click the <img src="docs/icons/keyboard.png" width="16" alt="keyboard icon"> icon on the right of the bar (or run the setup script
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
  through `/usr/bin/sudo -n` when you click. Every child process is started by
  absolute path with the inherited environment cleared, output is bounded to
  one line, the helper call has a 10 s deadline (SIGTERM, then SIGKILL), and
  all children are torn down when the plugin unloads.
- `BarWidget.qml` paints the mode and forwards clicks to the service, so all
  monitors show the same state.
- `scripts/omarchy-mac-fnmode` is the only code that ever runs as root after
  setup. Read it before running setup; it is under 60 lines.

### Privilege boundary during setup

Root never opens a file under the user-writable plugin checkout. `scripts/setup`
reads `scripts/setup-root` into memory and passes it to root as a string via
`sudo /usr/bin/bash -c`, and streams the helper's bytes to root on stdin.
`setup-root` carries the helper's SHA-256 and refuses to install anything that
does not match, verifies the installed file again, validates the generated
sudoers rule with `visudo -c`, and stages everything in a root-only
`mktemp -d` under `/run`. Swapping either file after the password prompt
cannot change what root installs. Uninstall uses the same by-value pattern with
a fixed string.

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

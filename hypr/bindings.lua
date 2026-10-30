-- Hyprland bindings for the MacBook function row in media mode (fnmode=1).
--
-- Loaded from ~/.config/hypr/bindings.lua by the block scripts/setup adds.
-- Omarchy already binds F1/F2 (brightness), F5 (mic mute), and F7-F12
-- (media, volume). These cover the three keys it does not.
--
-- F6 sends KEY_SLEEP. The plugin service holds a logind suspend-key inhibitor
-- while media mode is active so this binding runs instead of a suspend.

o.bind("XF86LaunchA", "Mission Control", "omarchy-menu toggle apps", { locked = true })
o.bind("XF86Search", "Spotlight", "omarchy-menu toggle", { locked = true })
-- MacBookPro11,3 sends KEY_DASHBOARD (Launchpad) on F4 instead of Spotlight.
o.bind("XF86LaunchB", "Launchpad", "omarchy-menu toggle", { locked = true })
o.bind_toggle("XF86Sleep", "Do Not Disturb", "notification-silencing", { locked = true })

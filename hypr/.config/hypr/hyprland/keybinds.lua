-- My programs
local terminal = "kitty"
local fileManager = "thunar"
local menu = "~/.config/rofi/scripts/launcher.sh"
local clipboard = "~/.config/rofi/scripts/cliphist-rofi.sh"
local theme = "~/.local/bin/walset"
local stickyNote = "~/.config/rofi/scripts/note-launcher.sh"

-- Keybindings
-- https://wiki.hypr.land/Configuring/Basics/Binds/
local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- --- App Launchers ---
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(clipboard))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("librewolf"))
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("code"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(theme))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd(stickyNote))

-- Night mode
hl.bind("SUPER + N", hl.dsp.exec_cmd("~/.local/bin/night-mode.sh"))

-- Speed mode
hl.bind("WIN + F1", hl.dsp.exec_cmd("~/.config/hypr/gamemode.sh"))

-- --- Window Management ---
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("~/.config/rofi/scripts/powermenu.sh"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle only
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("~/.config/waybar/scripts/launch.sh"))
-- Lock screen
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))

-- Screenshot
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("~/.config/rofi/scripts/screenshot.sh"))
hl.bind("Print", hl.dsp.exec_cmd("~/.config/rofi/scripts/screenshot.sh \"[AREA] Select Area\""))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("~/.config/rofi/scripts/screenshot.sh \"[FULL] Fullscreen\""))
hl.bind("CTRL + Print", hl.dsp.exec_cmd("~/.config/rofi/scripts/screenshot.sh \"[ACTIVE] Active Window\""))
hl.bind("ALT + Print", hl.dsp.exec_cmd("~/.config/rofi/scripts/screenshot.sh \"Window Picker\""))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "d" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Resize active window with CTRL+ALT+arrows.
-- NOTE: routed through `hyprctl dispatch` rather than a hl.dsp.window.resize()
-- table, because that helper's exact shape for a *relative* resize (as
-- opposed to resizing to an absolute size) isn't confirmed from available
-- references. `hyprctl dispatch resizeactive <dx> <dy>` is the same
-- dispatcher hyprlang used, so this is guaranteed to keep working.
hl.bind("CTRL + ALT + LEFT", hl.dsp.exec_cmd("hyprctl dispatch resizeactive \"-50 0\""))
hl.bind("CTRL + ALT + RIGHT", hl.dsp.exec_cmd("hyprctl dispatch resizeactive \"50 0\""))
hl.bind("CTRL + ALT + UP", hl.dsp.exec_cmd("hyprctl dispatch resizeactive \"0 -50\""))
hl.bind("CTRL + ALT + DOWN", hl.dsp.exec_cmd("hyprctl dispatch resizeactive \"0 50\""))

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("amixer set Master 5%+ && pkill -RTMIN+10 waybar"),
    { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("amixer set Master 5%- && pkill -RTMIN+10 waybar"),
    { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && pkill -RTMIN+10 waybar"),
    { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 10%+ && pkill -RTMIN+9 waybar"),
    { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 10%- && pkill -RTMIN+9 waybar"),
    { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Autostart
-- https://wiki.hypr.land/Configuring/Basics/Autostart/
-- exec-once commands now live inside this hl.on("hyprland.start", ...) callback

hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("udiskie")
    hl.exec_cmd("wal -R --cols16")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("eww daemon")
    hl.exec_cmd("~/.local/bin/togglebar.sh")
end)

-- Windows and workspaces
-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- https://wiki.hypr.land/Configuring/Basics/Layer-Rules/

-- Remove the weird pop-up behavior in VSCode
hl.window_rule({ match = { title = "^$", class = "^$" }, stay_focused = true })
hl.window_rule({ match = { class = "^(code)$" }, opacity = { 0.8, 0.8 } })

-- Make file picker windows floating
hl.window_rule({
    match = { title = "^(Open File|Open|Save|Save As|Export|Import|Choose File|Open Folder)$" },
    float = true,
    center = true,
})
hl.window_rule({
    match = { class = "^(xdg-desktop-portal-gtk|Xdg-desktop-portal-gtk)$" },
    float = true,
    center = true,
    border_size = 0,
})

-- make nmtui windows floating
hl.window_rule({ match = { class = "^(st)$", title = "^(NetworkManager TUI)$" }, float = true })
hl.window_rule({
    match = { class = "^(Alacritty|foot|kitty|wezterm)$", title = "^(nmtui)$" },
    float = true,
    size = { 600, 400 },
    center = true,
})

-- make waybar pkg upgrade floating (pacman)
hl.window_rule({ match = { title = "^(pacman)$" }, float = true, center = true, size = { 800, 600 } })

-- make thunar floating
hl.window_rule({ match = { class = "^(thunar)$" }, float = true, center = true, size = { 800, 600 } })

-- Blur swaync layers
hl.layer_rule({ match = { namespace = "swaync-control-center" }, blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, blur = true, ignore_alpha = 0.5 })

-- Disable borders for swaync window (kalau swaync muncul sebagai window, bukan layer)
hl.window_rule({ match = { class = "^(swaync)$" }, border_size = 0 })

-- Ignore maximize requests from apps
hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })

-- Fix some dragging issues with XWayland
hl.window_rule({
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

-- Sticky note floating
hl.window_rule({ match = { class = "^sticky-note$" }, float = true, center = true, size = { 800, 500 } })

-- Clipboard edit floating
hl.window_rule({ match = { class = "^clipboard-edit$" }, float = true, center = true, size = { 600, 300 } })

-- Game idle inhibit
hl.window_rule({ match = { title = "^Hades$" }, idle_inhibit = "always" })

-- YouTube Picture-in-Picture
hl.window_rule({
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
    pin = true,
    size = { 480, 270 },
    move = "100%-500 100%-300",
})

local aero = {
    paper    = "f5f8fb",
    cloud    = "e3eef9",
    cobalt   = "1446c2",
    blue     = "1e6fd9",
    sky      = "3d9be9",
    ink      = "0b0d12",
    graphite = "5a6270",
    chrome   = "c6d0db",
}

local function rgba(hex, alpha)
    return "rgba(" .. hex .. alpha .. ")"
end

local terminal    = "kitty"
local fileManager = "__FILEMANAGER__"
local menu        = "__HOME__/.config/hyper-aero/scripts/phone.sh toggle"
local classicMenu = "rofi -show drun"
local browser     = "__BROWSER__"


pcall(dofile, "__HOME__/.config/hypr/aero-displays.lua")

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})


hl.on("hyprland.start", function()
    hl.exec_cmd("__HOME__/.config/hyper-aero/scripts/displays.sh daemon")
    hl.exec_cmd("__HOME__/.config/hyper-aero/scripts/snap.sh daemon")
    hl.exec_cmd("__HOME__/.config/hyper-aero/scripts/wallpaper.sh start")
    hl.exec_cmd("__HOME__/.config/hyper-aero/scripts/motion-guard.py")
    hl.exec_cmd("__HOME__/.config/hyper-aero/scripts/win-thumbs.sh")
    hl.exec_cmd("__HOME__/.config/hyper-aero/scripts/night-deck.py daemon")
    hl.exec_cmd("swaync")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("__HOME__/.config/hyper-aero/scripts/aero-start.sh")
    hl.exec_cmd("__HOME__/.config/hyper-aero/scripts/phone.sh daemon")
    hl.exec_cmd("__HOME__/.config/hyper-aero/scripts/veil.sh daemon")
    hl.exec_cmd("__HOME__/.config/hyper-aero/scripts/desk.sh daemon")
end)


hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("GSK_RENDERER", "ngl")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")


hl.config({
    general = {
        gaps_in  = 6,
        gaps_out = { top = 8, right = 14, bottom = 14, left = 14 },

        border_size = 2,

        col = {
            active_border = {
                colors = { rgba(aero.cobalt, "ff"), rgba(aero.blue, "ff"), rgba(aero.sky, "ff") },
                angle  = 135,
            },
            inactive_border = {
                colors = { rgba(aero.graphite, "55"), rgba(aero.chrome, "77") },
                angle  = 135,
            },
        },

        resize_on_border        = true,
        extend_border_grab_area = 12,
        hover_icon_on_border    = true,
        allow_tearing           = false,
        layout                  = "dwindle",

        snap = {
            enabled      = true,
            window_gap   = 12,
            monitor_gap  = 14,
            respect_gaps = true,
        },
    },

    decoration = {
        rounding       = 14,
        rounding_power = 2.6,

        active_opacity     = 1.0,
        inactive_opacity   = 0.9,
        fullscreen_opacity = 1.0,

        dim_inactive = false,
        dim_special  = 0.2,

        shadow = {
            enabled        = true,
            range          = 30,
            render_power   = 3,
            offset         = { 0, 10 },
            color          = rgba(aero.ink, "40"),
            color_inactive = rgba(aero.ink, "22"),
        },

        glow = {
            enabled        = true,
            range          = 14,
            render_power   = 3,
            color          = rgba(aero.sky, "77"),
            color_inactive = rgba(aero.sky, "00"),
        },

        blur = {
            enabled           = true,
            size              = 10,
            passes            = 3,
            new_optimizations = true,
            xray              = false,
            noise             = 0.01,
            contrast          = 0.95,
            brightness        = 1.0,
            vibrancy          = 0.2,
            vibrancy_darkness = 0.0,
            popups            = true,
            special           = true,
        },
    },

    animations = {
        enabled              = true,
        workspace_wraparound = false,
    },
})


hl.curve("aeroGlide",    { type = "bezier", points = { {0.22, 1},    {0.36, 1}    } })
hl.curve("aeroRise",     { type = "bezier", points = { {0.05, 0.9},  {0.1, 1.08}  } })
hl.curve("aeroSnap",     { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })
hl.curve("linear",       { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear", { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })

hl.curve("aeroSpring",   { type = "spring", mass = 1, stiffness = 210, dampening = 19 })

hl.animation({ leaf = "global",        enabled = true, speed = 10,  bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 6,   bezier = "aeroGlide" })
hl.animation({ leaf = "windows",       enabled = true, speed = 5,   spring = "aeroSpring" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.5, spring = "aeroSpring",   style = "popin 78%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.8, bezier = "aeroSnap",     style = "popin 85%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 2,   bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.6, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3,   bezier = "aeroSnap" })
hl.animation({ leaf = "layers",        enabled = true, speed = 4,   bezier = "aeroGlide" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,   bezier = "aeroRise",     style = "popin 90%" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.8, bezier = "aeroSnap",     style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 2,   bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.5, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 3.5, bezier = "aeroGlide",    style = "slidefadevert 18%" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 3.5, bezier = "aeroGlide",    style = "slidefadevert 18%" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 3.5, bezier = "aeroGlide",    style = "slidefadevert 18%" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,   bezier = "aeroSnap" })
hl.animation({ leaf = "windowsMove",   enabled = true, speed = 5,   spring = "aeroSpring" })
hl.animation({ leaf = "borderangle",   enabled = true, speed = 14,  bezier = "aeroGlide",    style = "once" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "aeroRise",   style = "slidefadevert 30%" })
hl.animation({ leaf = "fadeDim",       enabled = true, speed = 4,   bezier = "aeroGlide" })


hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})

hl.config({
    dwindle = {
        preserve_split = true,
    },
})

hl.config({
    master = {
        new_status = "master",
    },
})

hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})


hl.config({
    misc = {
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = false,
        disable_splash_rendering = true,
        font_family              = "Exo 2",
        background_color         = "rgb(" .. aero.paper .. ")",
        allow_session_lock_restore = true,
    },
})


hl.config({
    input = {
        kb_layout  = "__KB_LAYOUT__",
        kb_variant = "__KB_VARIANT__",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0,

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})


local mainMod = "SUPER"

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("pkill -SIGUSR1 waybar"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("swaync-client -d -sw"))
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/hud-toggle.sh"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/airlock.sh"))
hl.bind(mainMod .. " + F1", hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/keymap.sh"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/phone.sh bluetooth"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/phone.sh wifi"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("pkill rofi || __HOME__/.config/hyper-aero/scripts/wifi-menu.sh"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/desk-toggle.sh"))
hl.bind("SUPER + ALT + D", hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/desk.sh edit"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/night-deck.py toggle"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/night-deck.py warm toggle"))
hl.bind(mainMod .. " + ALT + T", hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/night-deck.py auto"))
hl.bind("ALT + Tab", hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/alt-tab.sh"), { non_consuming = true })
hl.bind("ALT + SHIFT + Tab", hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/alt-tab.sh reverse"), { non_consuming = true })
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/overview.sh"))
hl.bind("Escape", hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/overview.sh escape"), { non_consuming = true })
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/motion-toggle.sh"))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd(classicMenu))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/phone.sh controls"))
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/phone.sh today"))
hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/screenrec.sh toggle full"))
hl.bind("SUPER + ALT + SHIFT + R", hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/screenrec.sh toggle region"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/displays.sh toggle"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + ALT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/screenshot.sh region"))
hl.bind("Print", hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/screenshot.sh full"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/screenshot.sh window"))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/osd.sh vol-up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/osd.sh vol-down"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/osd.sh mute"),     { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/osd.sh mic-mute"),   { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/osd.sh bri-up"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/osd.sh bri-down"),                  { locked = true, repeating = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })


hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})


hl.layer_rule({
    name  = "aero-glass-layers",
    match = { namespace = "^(waybar|wofi|rofi|swaync-control-center|swaync-notification-window|aero-.*)$" },

    blur         = true,
    blur_popups  = true,
    ignore_alpha = 0.15,
})

hl.layer_rule({
    name  = "aerobar-drop-in",
    match = { namespace = "^waybar$" },

    animation = "slide top",
})

hl.layer_rule({
    name  = "aero-signal-slide",
    match = { namespace = "^swaync-(notification-window|control-center)$" },

    animation = "slide right",
})

hl.layer_rule({
    name  = "aero-hud-slide",
    match = { namespace = "^aero-hud$" },

    animation = "slide right",
})

hl.layer_rule({
    name  = "aero-osd-rise",
    match = { namespace = "^aero-osd$" },

    animation = "slide bottom",
})

hl.layer_rule({
    name  = "aero-overview-fade",
    match = { namespace = "^aero-overview$" },

    animation = "fade",
})

hl.layer_rule({
    name  = "aero-desk-fade",
    match = { namespace = "^aero-desk$" },

    animation = "fade",
})

hl.layer_rule({
    name  = "aero-saver-fade",
    match = { namespace = "^(mpvpaper|aerosaver-clock)$" },

    animation = "fade",
})

hl.layer_rule({
    name  = "aero-dock-rise",
    match = { namespace = "^aero-dock$" },

    animation = "slide bottom",
})

hl.layer_rule({
    name  = "aero-dock-handle-fade",
    match = { namespace = "^aerodock-handle$" },

    animation = "fade",
})

hl.layer_rule({
    name  = "aero-phone-fade",
    match = { namespace = "^aero-phone$" },

    blur      = false,
    animation = "fade",
})

hl.layer_rule({
    name  = "aero-launcher-pop",
    match = { namespace = "^rofi$" },

    animation = "popin 82%",
})

hl.window_rule({
    name  = "aero-floating-tools",
    match = { class = "^(aero-float|aero-wifi)$" },

    float = true,
})


hl.layer_rule({
    name  = "aero-veil-still",
    match = { namespace = "^hyperveil$" },

    no_anim = true,
})


hl.layer_rule({
    name  = "aero-snap-still",
    match = { namespace = "^aero-snap$" },

    no_anim = true,
})

pcall(dofile, "__HOME__/.config/hypr/aero-deskmove.lua")

hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/carousel.sh"))

hl.bind(mainMod .. " + F2", hl.dsp.exec_cmd("__HOME__/.config/hyper-aero/scripts/aero-profile menu"))

pcall(dofile, "__HOME__/.config/hypr/aero-profile.lua")
pcall(dofile, "__HOME__/.config/hypr/user.lua")

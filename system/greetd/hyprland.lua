hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GSK_RENDERER", "ngl")

hl.config({
    general = {
        gaps_in     = 0,
        gaps_out    = 0,
        border_size = 0,
    },

    decoration = {
        rounding = 0,
        shadow   = { enabled = false },
        glow     = { enabled = false },
        blur     = { enabled = false },
    },

    animations = {
        enabled = true,
    },

    input = {
        kb_layout    = "__KB_LAYOUT__",
        kb_variant   = "__KB_VARIANT__",
        follow_mouse = 1,
    },

    misc = {
        disable_hyprland_logo           = true,
        disable_splash_rendering        = true,
        disable_hyprland_guiutils_check = true,
        force_default_wallpaper         = 0,
        background_color                = "rgb(f5f8fb)",
    },
})

hl.on("hyprland.start", function()
    hl.exec_cmd("/etc/greetd/aero-greet.sh; hyprctl dispatch 'hl.dsp.exit()'")
end)

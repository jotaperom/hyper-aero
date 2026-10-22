local home = os.getenv("HOME")

hl.bind("SUPER + F12", hl.dsp.exec_cmd("kitty --class aero-float -e nano " .. home .. "/.config/hypr/user.lua"))

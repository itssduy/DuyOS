-- DuyOS additions on top of the Caelestia Hyprland config (loaded last).

-- First login: welcome notification with the key bindings.
hl.on("hyprland.start", function()
    hl.exec_cmd("duyos-firstlogin")
end)

-- Extra keybinds.
hl.bind("SUPER + slash", hl.dsp.exec_cmd("foot --hold -e duyos-info"))
hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd("foot -e btop"))

-- DuyOS overrides for Caelestia's Hyprland variables (hypr/variables.lua).
-- Caelestia's hyprland.lua merges this table over its defaults.
return {
    -- Apps: point at packages DuyOS actually ships (defaults need AUR/extra installs).
    terminal      = "foot",
    browser       = "firefox",
    editor        = "foot -e micro",   -- default "codium" is not installed
    fileExplorer  = "thunar",
    audioSettings = "pavucontrol",     -- default "pwvucontrol" is AUR-only
    cursorTheme   = "Adwaita",         -- default "sweet-cursors" is AUR-only

    -- Lighter effects so the desktop stays smooth in VMs with virtual GPUs.
    blurPasses        = 1,
    blurSize          = 6,
    shadowRenderPower = 2,

    -- DuyOS look: slightly tighter rounding and gaps.
    windowRounding = 12,
    windowGapsOut  = 8,
    windowOpacity  = 0.97,
}

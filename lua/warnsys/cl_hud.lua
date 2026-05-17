-- WarnSys :: HUD-Anzeige (Matte Black + Slide-Animation)

local convar = CreateClientConVar("warnsys_show_hud", "1", true, false,
    "WarnSys: Eigene Verwarnungs-Anzahl im HUD anzeigen.")

surface.CreateFont("WS.HUD",     { font = "Roboto", size = 18, weight = 700, antialias = true })
surface.CreateFont("WS.HUDSub",  { font = "Roboto", size = 11, weight = 500, antialias = true })

local state = {
    visible      = 0,    -- 0..1 sichtbarkeit
    displayCount = 0,    -- animierte Zahl
    pulse        = 0,    -- pulsiert bei neuem warn
    lastCount    = 0,
}

hook.Add("WarnSys.WarnsReceived", "WarnSys.HUDPulse", function() end)

-- Pulse-Trigger: wenn sich ActiveWarns erhöht
timer.Create("WarnSys.HUDWatch", 0.25, 0, function()
    local n = WarnSys.Client and WarnSys.Client.ActiveWarns or 0
    if n > state.lastCount then
        state.pulse = 1
        surface.PlaySound("buttons/button10.wav")
    end
    state.lastCount = n
end)

hook.Add("HUDPaint", "WarnSys.HUD", function()
    if convar:GetInt() == 0 then return end
    local n = WarnSys.Client and WarnSys.Client.ActiveWarns or 0
    local target = n > 0 and 1 or 0

    local dt = FrameTime() * 6
    state.visible = state.visible + (target - state.visible) * math.min(dt, 1)
    state.displayCount = state.displayCount + (n - state.displayCount) * math.min(FrameTime() * 8, 1)
    state.pulse = math.max(0, state.pulse - FrameTime() * 1.5)

    if state.visible < 0.01 then return end

    local w, h = 220, 56
    local x = ScrW() - w - 24 + (1 - state.visible) * 40
    local y = 110
    local alpha = state.visible * 255

    -- Schatten
    for i = 1, 6 do
        local a = alpha * (1 - i / 6) * 0.15
        draw.RoundedBox(8 + i, x - i, y - i, w + i * 2, h + i * 2, Color(0, 0, 0, a))
    end

    -- Karte
    draw.RoundedBox(8, x, y, w, h, Color(18, 18, 22, alpha))

    -- Pulse-Effekt (roter Glow)
    if state.pulse > 0.01 then
        draw.RoundedBox(8, x, y, w, h, Color(220, 50, 50, state.pulse * 80))
    end

    -- Akzentleiste
    local accent = n >= 5 and Color(220, 50, 50)
        or (n >= 3 and Color(245, 180, 60) or Color(245, 200, 60))
    draw.RoundedBoxEx(8, x, y, 4, h, ColorAlpha(accent, alpha),
        true, false, true, false)

    -- Icon
    draw.SimpleText("⚠", "WS.H1", x + 24, y + h / 2, ColorAlpha(accent, alpha),
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Zahl (animiert)
    local nDisp = math.floor(state.displayCount + 0.5)
    draw.SimpleText(tostring(nDisp), "WS.HUD", x + 54, y + 10,
        ColorAlpha(Color(235, 235, 240), alpha),
        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(nDisp == 1 and "Verwarnung" or "Verwarnungen", "WS.HUDSub",
        x + 54, y + 32, ColorAlpha(Color(140, 140, 150), alpha),
        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    -- Hint
    draw.SimpleText("!warns", "WS.HUDSub", x + w - 14, y + h - 14,
        ColorAlpha(Color(95, 95, 105), alpha),
        TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end)

-- WarnSys :: HUD-Anzeige der eigenen aktiven Warns

local convar = CreateClientConVar("warnsys_show_hud", "1", true, false,
    "WarnSys: Eigene Verwarnungs-Anzahl im HUD anzeigen.")

local PAD = 8
surface.CreateFont("WarnSys.HUD", {
    font = "Roboto", size = 18, weight = 600, antialias = true,
})

hook.Add("HUDPaint", "WarnSys.HUD", function()
    if convar:GetInt() == 0 then return end
    local n = WarnSys.Client and WarnSys.Client.ActiveWarns or 0
    if n <= 0 then return end

    local text = "⚠ " .. n .. (n == 1 and " Verwarnung" or " Verwarnungen")
    surface.SetFont("WarnSys.HUD")
    local tw, th = surface.GetTextSize(text)

    local w, h = tw + PAD * 2, th + PAD
    local x, y = ScrW() - w - 20, 100

    draw.RoundedBox(6, x, y, w, h, Color(0, 0, 0, 180))
    draw.RoundedBox(6, x, y, 3, h,
        n >= 5 and Color(231, 76, 60) or Color(241, 196, 15))

    surface.SetTextColor(255, 255, 255)
    surface.SetTextPos(x + PAD, y + PAD / 2)
    surface.DrawText(text)
end)

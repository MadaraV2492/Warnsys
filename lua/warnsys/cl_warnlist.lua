-- WarnSys :: Persönlicher Warn-Viewer für jeden Spieler (!warns oder F3-Fallback)

surface.CreateFont("WarnSys.MyTitle",  { font = "Roboto", size = 22, weight = 700 })
surface.CreateFont("WarnSys.MyBody",   { font = "Roboto", size = 14, weight = 400 })

local function openSelfMenu()
    local f = vgui.Create("DFrame")
    f:SetSize(640, 440)
    f:Center()
    f:SetTitle("Meine Verwarnungen")
    f:MakePopup()
    f.Paint = function(_, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(30, 32, 38))
        draw.RoundedBoxEx(6, 0, 0, w, 24, Color(40, 42, 50), true, true, false, false)
    end

    local lbl = vgui.Create("DLabel", f)
    lbl:SetPos(15, 32)
    lbl:SetFont("WarnSys.MyTitle")
    lbl:SetTextColor(color_white)
    lbl:SetText("Lädt…")
    lbl:SizeToContents()

    local lv = vgui.Create("DListView", f)
    lv:SetPos(10, 70)
    lv:SetSize(620, 360)
    lv:AddColumn("ID"):SetFixedWidth(50)
    lv:AddColumn("Grund")
    lv:AddColumn("Admin"):SetFixedWidth(130)
    lv:AddColumn("Datum"):SetFixedWidth(110)
    lv:AddColumn("Status"):SetFixedWidth(80)

    hook.Add("WarnSys.WarnsReceived", "WarnSys.SelfView", function(sid, rows)
        if sid ~= LocalPlayer():SteamID() then return end
        lv:Clear()
        local active = 0
        for _, r in ipairs(rows) do
            if r.active then active = active + 1 end
            lv:AddLine(r.id, r.reason, r.admin_nick,
                WarnSys.Util.FormatTime(r.created),
                r.active and "Aktiv" or "Abgelaufen")
        end
        lbl:SetText(string.format("%d aktive / %d gesamt", active, #rows))
        lbl:SizeToContents()
    end)

    f.OnRemove = function()
        hook.Remove("WarnSys.WarnsReceived", "WarnSys.SelfView")
    end

    WarnSys.Client.RequestWarns(LocalPlayer():SteamID(), true)
end

concommand.Add("warnsys_mywarns", openSelfMenu)

-- Chat-Trigger: !mywarns
hook.Add("OnPlayerChat", "WarnSys.MyWarnsChat", function(ply, text)
    if ply ~= LocalPlayer() then return end
    local lower = string.lower(text)
    if lower == "!mywarns" or lower == "/mywarns" then
        timer.Simple(0.1, openSelfMenu)
    end
end)

-- WarnSys :: Admin-GUI

local COLORS = {
    bg      = Color(30, 32, 38),
    panel   = Color(40, 42, 50),
    accent  = Color(231, 76, 60),
    text    = Color(235, 235, 235),
    sub     = Color(160, 160, 165),
    line    = Color(60, 62, 70),
    ok      = Color(46, 204, 113),
    warn    = Color(241, 196, 15),
}

surface.CreateFont("WarnSys.Title",  { font = "Roboto", size = 24, weight = 700 })
surface.CreateFont("WarnSys.Header", { font = "Roboto", size = 16, weight = 600 })
surface.CreateFont("WarnSys.Body",   { font = "Roboto", size = 14, weight = 400 })
surface.CreateFont("WarnSys.Small",  { font = "Roboto", size = 12, weight = 400 })

local function styledButton(parent, text, col)
    col = col or COLORS.accent
    local b = vgui.Create("DButton", parent)
    b:SetText(text)
    b:SetTextColor(color_white)
    b:SetFont("WarnSys.Body")
    b.Paint = function(self, w, h)
        local c = col
        if self:IsHovered() then
            c = Color(math.min(c.r + 25, 255), math.min(c.g + 25, 255), math.min(c.b + 25, 255))
        end
        draw.RoundedBox(4, 0, 0, w, h, c)
    end
    return b
end

local function frame()
    local f = vgui.Create("DFrame")
    f:SetSize(900, 600)
    f:Center()
    f:SetTitle("")
    f:ShowCloseButton(false)
    f:MakePopup()
    f.Paint = function(_, w, h)
        draw.RoundedBox(8, 0, 0, w, h, COLORS.bg)
        draw.RoundedBoxEx(8, 0, 0, w, 40, COLORS.panel, true, true, false, false)
        draw.SimpleText(WarnSys.L("menu_title"), "WarnSys.Title", 16, 8, COLORS.text)
        surface.SetDrawColor(COLORS.accent)
        surface.DrawRect(0, 40, w, 2)
    end

    local close = styledButton(f, "X", Color(180, 60, 60))
    close:SetSize(30, 24)
    close:SetPos(860, 8)
    close.DoClick = function() f:Remove() end
    return f
end

-- ============================================================
--  Spieler-Zeile (links)
-- ============================================================
local function playerRow(list, ply)
    local row = list:Add("DPanel")
    row:Dock(TOP)
    row:DockMargin(0, 0, 0, 4)
    row:SetTall(44)
    row.ply = ply

    row.Paint = function(self, w, h)
        local c = self.selected and COLORS.accent or COLORS.panel
        if self:IsHovered() and not self.selected then c = COLORS.line end
        draw.RoundedBox(4, 0, 0, w, h, c)
    end

    local av = vgui.Create("AvatarImage", row)
    av:SetPos(6, 6)
    av:SetSize(32, 32)
    av:SetPlayer(ply, 32)

    local nick = vgui.Create("DLabel", row)
    nick:SetPos(46, 4)
    nick:SetText(ply:Nick())
    nick:SetFont("WarnSys.Header")
    nick:SetTextColor(COLORS.text)
    nick:SizeToContents()

    local sub = vgui.Create("DLabel", row)
    sub:SetPos(46, 24)
    sub:SetText(ply:SteamID() .. "  •  " .. ply:GetUserGroup())
    sub:SetFont("WarnSys.Small")
    sub:SetTextColor(COLORS.sub)
    sub:SizeToContents()

    row.OnMousePressed = function(self, key)
        if key ~= MOUSE_LEFT then return end
        for _, child in ipairs(list:GetChildren()) do
            if child.selected ~= nil then child.selected = false end
        end
        self.selected = true
        if list.OnSelect then list.OnSelect(ply) end
    end

    return row
end

-- ============================================================
--  Hauptmenü
-- ============================================================
function WarnSys.Client.OpenMenu()
    local f = frame()
    local selected -- gewählter Spieler

    -- Linke Seite: Spielerliste
    local left = vgui.Create("DPanel", f)
    left:SetPos(10, 50)
    left:SetSize(280, 540)
    left.Paint = function(_, w, h)
        draw.RoundedBox(6, 0, 0, w, h, COLORS.panel)
    end

    local search = vgui.Create("DTextEntry", left)
    search:SetPos(8, 8)
    search:SetSize(264, 26)
    search:SetPlaceholderText("Spieler suchen…")

    local scroll = vgui.Create("DScrollPanel", left)
    scroll:SetPos(8, 40)
    scroll:SetSize(264, 492)

    local function refreshPlayers()
        scroll:Clear()
        local needle = string.lower(search:GetValue() or "")
        local plys = player.GetAll()
        table.sort(plys, function(a, b) return a:Nick() < b:Nick() end)
        for _, p in ipairs(plys) do
            if needle == "" or string.find(string.lower(p:Nick()), needle, 1, true)
                or string.find(string.lower(p:SteamID()), needle, 1, true) then
                playerRow(scroll, p)
            end
        end
    end
    search.OnChange = refreshPlayers

    -- Rechte Seite
    local right = vgui.Create("DPanel", f)
    right:SetPos(300, 50)
    right:SetSize(590, 540)
    right.Paint = function(_, w, h)
        draw.RoundedBox(6, 0, 0, w, h, COLORS.panel)
    end

    -- Spieler-Header
    local header = vgui.Create("DPanel", right)
    header:SetPos(10, 10)
    header:SetSize(570, 50)
    header.text = "Bitte links einen Spieler wählen."
    header.sub  = ""
    header.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, COLORS.bg)
        draw.SimpleText(self.text, "WarnSys.Header", 10, 8, COLORS.text)
        draw.SimpleText(self.sub,  "WarnSys.Small",  10, 28, COLORS.sub)
    end

    -- Grund-Eingabe
    local reasonLbl = vgui.Create("DLabel", right)
    reasonLbl:SetPos(10, 70)
    reasonLbl:SetText(WarnSys.L("menu_reason"))
    reasonLbl:SetFont("WarnSys.Header")
    reasonLbl:SetTextColor(COLORS.text)
    reasonLbl:SizeToContents()

    local presetLbl = vgui.Create("DLabel", right)
    presetLbl:SetPos(10, 92)
    presetLbl:SetText(WarnSys.L("menu_preset") .. ":")
    presetLbl:SetTextColor(COLORS.sub)
    presetLbl:SizeToContents()

    local preset = vgui.Create("DComboBox", right)
    preset:SetPos(80, 90)
    preset:SetSize(490, 22)
    preset:SetValue("— Voreinstellung wählen —")
    for _, r in ipairs(WarnSys.Config.PresetReasons) do
        preset:AddChoice(r)
    end

    local reason = vgui.Create("DTextEntry", right)
    reason:SetPos(10, 120)
    reason:SetSize(560, 26)
    reason:SetPlaceholderText("Grund eingeben oder Voreinstellung wählen…")
    preset.OnSelect = function(_, _, value) reason:SetValue(value) end

    -- Aktions-Buttons
    local btnWarn = styledButton(right, WarnSys.L("menu_warn_btn"), COLORS.accent)
    btnWarn:SetPos(10, 156)
    btnWarn:SetSize(180, 32)

    local btnView = styledButton(right, WarnSys.L("menu_view_btn"), Color(52, 152, 219))
    btnView:SetPos(200, 156)
    btnView:SetSize(180, 32)

    local btnClear = styledButton(right, WarnSys.L("menu_clear_btn"), Color(127, 140, 141))
    btnClear:SetPos(390, 156)
    btnClear:SetSize(180, 32)

    -- Tabs für Warn-Liste
    local sheet = vgui.Create("DPropertySheet", right)
    sheet:SetPos(10, 200)
    sheet:SetSize(570, 330)
    sheet.Paint = function() end

    local function buildList(parent)
        local lv = vgui.Create("DListView", parent)
        lv:Dock(FILL)
        lv:AddColumn("ID"):SetFixedWidth(50)
        lv:AddColumn("Grund")
        lv:AddColumn("Admin"):SetFixedWidth(120)
        lv:AddColumn("Datum"):SetFixedWidth(110)
        lv.OnRowRightClick = function(_, _, line)
            local id = tonumber(line:GetValue(1))
            if not id then return end
            local menu = DermaMenu()
            menu:AddOption(WarnSys.L("menu_unwarn_btn"), function()
                Derma_Query(WarnSys.L("menu_confirm_unw", id),
                    "WarnSys", "Ja", function()
                        net.Start("WarnSys.DoUnwarn")
                            net.WriteUInt(id, 32)
                        net.SendToServer()
                        timer.Simple(0.4, function()
                            if selected then
                                WarnSys.Client.RequestWarns(selected:SteamID(), true)
                            end
                        end)
                    end, "Nein")
            end):SetIcon("icon16/cross.png")
            menu:Open()
        end
        return lv
    end

    local activeList  = buildList(sheet)
    local historyList = buildList(sheet)
    sheet:AddSheet(WarnSys.L("menu_active"),  activeList,  "icon16/exclamation.png")
    sheet:AddSheet(WarnSys.L("menu_history"), historyList, "icon16/clock.png")

    local function fillLists(rows)
        activeList:Clear()
        historyList:Clear()
        for _, r in ipairs(rows) do
            local date = WarnSys.Util.FormatTime(r.created)
            historyList:AddLine(r.id, r.reason, r.admin_nick, date)
            if r.active then
                activeList:AddLine(r.id, r.reason, r.admin_nick, date)
            end
        end
    end

    hook.Add("WarnSys.WarnsReceived", "WarnSys.MenuFill", function(sid, rows)
        if not selected or selected:SteamID() ~= sid then return end
        fillLists(rows)
        header.sub = string.format("Aktive Warns: %d  •  Gesamt: %d",
            #activeList:GetLines(), #rows)
    end)

    -- Spielerauswahl-Callback
    scroll.OnSelect = function(ply)
        selected = ply
        header.text = ply:Nick()
        header.sub  = ply:SteamID() .. " • Lädt…"
        WarnSys.Client.RequestWarns(ply:SteamID(), true)
    end

    -- Button-Handler
    btnWarn.DoClick = function()
        if not IsValid(selected) then
            Derma_Message("Bitte zuerst einen Spieler auswählen.", "WarnSys", "OK")
            return
        end
        local r = reason:GetValue()
        if #r < WarnSys.Config.MinReasonLength then
            Derma_Message(WarnSys.L("invalid_reason",
                WarnSys.Config.MinReasonLength,
                WarnSys.Config.MaxReasonLength), "WarnSys", "OK")
            return
        end
        net.Start("WarnSys.DoWarn")
            net.WriteEntity(selected)
            net.WriteString(r)
        net.SendToServer()
        reason:SetValue("")
        preset:SetValue("— Voreinstellung wählen —")
        timer.Simple(0.4, function()
            if IsValid(selected) then
                WarnSys.Client.RequestWarns(selected:SteamID(), true)
            end
        end)
    end

    btnView.DoClick = function()
        if IsValid(selected) then
            WarnSys.Client.RequestWarns(selected:SteamID(), true)
        end
    end

    btnClear.DoClick = function()
        if not IsValid(selected) then return end
        Derma_Query(WarnSys.L("menu_confirm_clear", selected:Nick()),
            "WarnSys", "Ja", function()
                net.Start("WarnSys.DoClear")
                    net.WriteEntity(selected)
                net.SendToServer()
                timer.Simple(0.4, function()
                    if IsValid(selected) then
                        WarnSys.Client.RequestWarns(selected:SteamID(), true)
                    end
                end)
            end, "Nein")
    end

    -- Initial laden
    refreshPlayers()

    -- Auto-Refresh bei Spieler-Connect/Disconnect
    hook.Add("WarnSys.PlayerListChanged", f, refreshPlayers)
    f.OnRemove = function()
        hook.Remove("WarnSys.WarnsReceived", "WarnSys.MenuFill")
    end
end

-- Befehl
concommand.Add("warnsys_menu", function(ply)
    WarnSys.Client.OpenMenu()
end)

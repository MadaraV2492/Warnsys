-- WarnSys :: Modernes Menü (Matte Black + Animationen)
--
-- Öffnet ein einheitliches Fenster für JEDEN Spieler.
-- Admin-Tabs werden nur eingeblendet, wenn die Berechtigung passt.

WarnSys.Client = WarnSys.Client or {}

-- ============================================================
--  Theme
-- ============================================================
local THEME = {
    bg          = Color(15, 15, 18),
    bgAlt       = Color(20, 20, 24),
    card        = Color(24, 24, 28),
    cardHover   = Color(32, 32, 38),
    border      = Color(40, 40, 46),
    text        = Color(235, 235, 240),
    textDim     = Color(140, 140, 150),
    textMuted   = Color(95, 95, 105),
    accent      = Color(220, 50, 50),
    accentSoft  = Color(220, 50, 50, 40),
    info        = Color(80, 170, 255),
    ok          = Color(70, 200, 130),
    warn        = Color(245, 180, 60),
    overlay     = Color(0, 0, 0, 200),
}

surface.CreateFont("WS.H1",   { font = "Roboto", size = 26, weight = 700, antialias = true })
surface.CreateFont("WS.H2",   { font = "Roboto", size = 18, weight = 600, antialias = true })
surface.CreateFont("WS.H3",   { font = "Roboto", size = 15, weight = 600, antialias = true })
surface.CreateFont("WS.Body", { font = "Roboto", size = 14, weight = 400, antialias = true })
surface.CreateFont("WS.Mono", { font = "Consolas", size = 13, weight = 400, antialias = true })
surface.CreateFont("WS.Small",{ font = "Roboto", size = 12, weight = 400, antialias = true })
surface.CreateFont("WS.Big",  { font = "Roboto", size = 42, weight = 700, antialias = true })
surface.CreateFont("WS.Icon", { font = "Roboto", size = 18, weight = 600, antialias = true })

-- ============================================================
--  Util
-- ============================================================
local function lerp(a, b, t) return a + (b - a) * t end
local function lerpCol(t, a, b)
    return Color(lerp(a.r, b.r, t), lerp(a.g, b.g, t), lerp(a.b, b.b, t),
        lerp(a.a or 255, b.a or 255, t))
end

local function shadow(x, y, w, h, r, alpha, spread)
    alpha = alpha or 60
    spread = spread or 8
    for i = 1, spread do
        local a = alpha * (1 - i / spread) * 0.5
        draw.RoundedBox(r + i, x - i, y - i, w + i * 2, h + i * 2, Color(0, 0, 0, a))
    end
end

local function canPerm(action)
    if not WarnSys.Util then return false end
    return WarnSys.Util.HasPermission(LocalPlayer(), action)
end

-- ============================================================
--  Komponenten
-- ============================================================

-- Smooth-Hover-Button (matte schwarz mit Akzent-Leuchten)
local function makeButton(parent, text, accent, icon)
    accent = accent or THEME.accent
    local b = vgui.Create("DButton", parent)
    b:SetText("")
    b.hoverFrac = 0
    b.clickFrac = 0

    b.Think = function(s)
        local dt = FrameTime() * 10
        s.hoverFrac = lerp(s.hoverFrac, s:IsHovered() and 1 or 0, math.min(dt, 1))
        s.clickFrac = lerp(s.clickFrac, s:IsDown() and 1 or 0, math.min(FrameTime() * 14, 1))
    end

    b.Paint = function(s, w, h)
        local base = lerpCol(s.hoverFrac, THEME.card, THEME.cardHover)
        if s.clickFrac > 0.05 then
            base = lerpCol(s.clickFrac * 0.4, base, accent)
        end
        draw.RoundedBox(6, 0, 0, w, h, base)
        -- akzentleiste links
        draw.RoundedBoxEx(6, 0, 0, 3, h,
            ColorAlpha(accent, 200 + s.hoverFrac * 55), true, false, true, false)
        -- subtiler glow
        if s.hoverFrac > 0 then
            draw.RoundedBox(6, 0, 0, w, h, ColorAlpha(accent, s.hoverFrac * 18))
        end
        -- text + icon
        local tx = icon and 36 or w / 2
        if icon then
            draw.SimpleText(icon, "WS.Icon", 16, h / 2, THEME.text,
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(text, "WS.Body", tx, h / 2, THEME.text,
                TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        else
            draw.SimpleText(text, "WS.Body", w / 2, h / 2, THEME.text,
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
    return b
end

-- Sidebar-Tab
local function makeTab(parent, label, icon, key)
    local t = vgui.Create("DButton", parent)
    t:SetText("")
    t:Dock(TOP)
    t:DockMargin(8, 4, 8, 0)
    t:SetTall(44)
    t.hoverFrac = 0
    t.activeFrac = 0
    t.key = key

    t.Think = function(s)
        local dt = math.min(FrameTime() * 10, 1)
        s.hoverFrac  = lerp(s.hoverFrac,  s:IsHovered() and 1 or 0, dt)
        s.activeFrac = lerp(s.activeFrac, s.isActive and 1 or 0, dt)
    end

    t.Paint = function(s, w, h)
        local bg = lerpCol(math.max(s.hoverFrac * 0.5, s.activeFrac),
            THEME.bg, THEME.card)
        draw.RoundedBox(6, 0, 0, w, h, bg)
        -- aktiv-indikator (sliding bar links)
        if s.activeFrac > 0.01 then
            surface.SetDrawColor(THEME.accent)
            surface.DrawRect(0, h / 2 - 10 * s.activeFrac, 3, 20 * s.activeFrac)
        end
        local txtCol = lerpCol(s.activeFrac, THEME.textDim, THEME.text)
        draw.SimpleText(icon,  "WS.Icon", 18, h / 2, txtCol,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(label, "WS.Body", 42, h / 2, txtCol,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    return t
end

-- Karten-Container
local function makeCard(parent)
    local p = vgui.Create("DPanel", parent)
    p.Paint = function(_, w, h)
        draw.RoundedBox(8, 0, 0, w, h, THEME.border)
        draw.RoundedBox(8, 1, 1, w - 2, h - 2, THEME.card)
    end
    return p
end

-- Stat-Block (große Zahl + Label)
local function makeStat(parent, label, valueFn, color)
    local c = makeCard(parent)
    color = color or THEME.accent
    c.appearFrac = 0
    c.Think = function(s)
        s.appearFrac = lerp(s.appearFrac, 1, math.min(FrameTime() * 4, 1))
    end
    c.Paint = function(s, w, h)
        local a = s.appearFrac
        draw.RoundedBox(8, 0, 0, w, h, THEME.border)
        draw.RoundedBox(8, 1, 1, w - 2, h - 2, THEME.card)
        -- akzentstreifen oben
        draw.RoundedBoxEx(8, 0, 0, w * a, 2, color, true, true, false, false)
        local val = tostring(valueFn() or "0")
        draw.SimpleText(val, "WS.Big", 16, 16, lerpCol(a, THEME.bg, THEME.text),
            TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(label, "WS.Small", 16, h - 18, THEME.textDim,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    return c
end

-- Eigene ScrollBar
local function styleScroll(scroll)
    local bar = scroll:GetVBar()
    bar:SetWide(6)
    function bar:Paint(w, h) draw.RoundedBox(3, 0, 0, w, h, THEME.bgAlt) end
    function bar.btnUp:Paint() end
    function bar.btnDown:Paint() end
    function bar.btnGrip:Paint(w, h)
        draw.RoundedBox(3, 0, 0, w, h, THEME.cardHover)
    end
end

-- ============================================================
--  Warn-Listen-Zeile (animiert)
-- ============================================================
local function makeWarnRow(parent, row, isAdmin)
    local r = vgui.Create("DPanel", parent)
    r:Dock(TOP)
    r:DockMargin(0, 0, 0, 6)
    r:SetTall(64)
    r.hoverFrac = 0
    r.row = row

    r.Think = function(s)
        s.hoverFrac = lerp(s.hoverFrac, s:IsHovered() and 1 or 0,
            math.min(FrameTime() * 10, 1))
    end

    r.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h,
            lerpCol(s.hoverFrac, THEME.card, THEME.cardHover))
        local statusCol = row.active and THEME.accent or THEME.textMuted
        draw.RoundedBoxEx(6, 0, 0, 3, h, statusCol, true, false, true, false)

        -- ID Badge
        draw.RoundedBox(4, 14, 12, 50, 22, THEME.bg)
        draw.SimpleText("#" .. row.id, "WS.Mono", 14 + 25, 23, THEME.textDim,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Status Badge
        local statusTxt = row.active and "AKTIV" or "ABGELAUFEN"
        surface.SetFont("WS.Small")
        local sw, sh = surface.GetTextSize(statusTxt)
        local bx, by = w - sw - 28, 12
        draw.RoundedBox(4, bx, by, sw + 14, 20, ColorAlpha(statusCol, 40))
        draw.SimpleText(statusTxt, "WS.Small", bx + 7 + sw / 2, by + 10,
            statusCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Grund
        draw.SimpleText(row.reason or "-", "WS.H3", 80, 12, THEME.text,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        -- Meta
        local meta = string.format("von %s  •  %s",
            row.admin_nick or "?",
            WarnSys.Util.FormatTime(row.created))
        draw.SimpleText(meta, "WS.Small", 80, h - 14, THEME.textDim,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    if isAdmin then
        r:SetCursor("hand")
        r.OnMousePressed = function(s, key)
            if key ~= MOUSE_RIGHT then return end
            local m = DermaMenu()
            m:AddOption("Verwarnung entfernen", function()
                Derma_Query(WarnSys.L("menu_confirm_unw", row.id),
                    "WarnSys", "Ja, entfernen", function()
                        net.Start("WarnSys.DoUnwarn")
                            net.WriteUInt(row.id, 32)
                        net.SendToServer()
                        surface.PlaySound("buttons/button14.wav")
                        timer.Simple(0.4, function()
                            hook.Run("WarnSys.MenuRefresh")
                        end)
                    end, "Abbrechen")
            end):SetIcon("icon16/cross.png")
            m:AddOption("ID kopieren", function()
                SetClipboardText(tostring(row.id))
            end):SetIcon("icon16/page_copy.png")
            m:Open()
        end
    end
    return r
end

-- ============================================================
--  Menü-Haupt
-- ============================================================
local CURRENT_MENU

function WarnSys.Client.OpenMenu(initialTab)
    if IsValid(CURRENT_MENU) then CURRENT_MENU:Remove() end

    local W, H = 1020, 640
    local f = vgui.Create("DFrame")
    f:SetSize(W, H)
    f:Center()
    f:SetTitle("")
    f:ShowCloseButton(false)
    f:SetDraggable(true)
    f:MakePopup()
    CURRENT_MENU = f

    -- Öffnungs-Animation
    f.openFrac = 0
    f:SetAlpha(0)
    f.Think = function(s)
        s.openFrac = lerp(s.openFrac, 1, math.min(FrameTime() * 6, 1))
        s:SetAlpha(math.Clamp(s.openFrac * 255, 0, 255))
    end

    f.Paint = function(s, w, h)
        -- Rounded Border (Außenkante) + Hintergrund
        draw.RoundedBox(10, 0, 0, w, h, THEME.border)
        draw.RoundedBox(10, 1, 1, w - 2, h - 2, THEME.bg)
        -- Top-Bar (inset)
        draw.RoundedBoxEx(9, 1, 1, w - 2, 55, THEME.bgAlt, true, true, false, false)
        -- subtle akzent unter top-bar
        surface.SetDrawColor(ColorAlpha(THEME.accent, 120))
        surface.DrawRect(1, 56, w - 2, 1)
        -- Logo + Titel
        draw.SimpleText("⚠", "WS.H1", 22, 28, THEME.accent,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("WarnSys", "WS.H1", 50, 22, THEME.text,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("v" .. (WarnSys.Version or "?"), "WS.Small",
            148, 30, THEME.textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        -- Spielername rechts oben
        local nick = LocalPlayer():Nick()
        draw.SimpleText(nick, "WS.Body", w - 60, 22, THEME.textDim,
            TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        draw.SimpleText(LocalPlayer():GetUserGroup(), "WS.Small", w - 60, 38,
            THEME.textMuted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    end

    -- Close-Button (X)
    local close = vgui.Create("DButton", f)
    close:SetText("")
    close:SetSize(32, 32)
    close:SetPos(W - 44, 12)
    close.hoverFrac = 0
    close.Think = function(s)
        s.hoverFrac = lerp(s.hoverFrac, s:IsHovered() and 1 or 0,
            math.min(FrameTime() * 10, 1))
    end
    close.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h,
            lerpCol(s.hoverFrac, THEME.card, THEME.accent))
        draw.SimpleText("✕", "WS.H2", w / 2, h / 2, THEME.text,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    close.DoClick = function()
        f.openFrac = 0
        f.Think = function(s)
            s.openFrac = lerp(s.openFrac, 0, math.min(FrameTime() * 10, 1))
            s:SetAlpha(s.openFrac * 255)
            if s.openFrac < 0.05 then s:Remove() end
        end
    end

    -- ============================================================
    --  Sidebar
    -- ============================================================
    local sidebar = vgui.Create("DPanel", f)
    sidebar:SetPos(0, 56)
    sidebar:SetSize(220, H - 56)
    sidebar.Paint = function(_, w, h)
        draw.RoundedBoxEx(10, 0, 0, w, h, THEME.bgAlt, false, false, true, false)
        surface.SetDrawColor(THEME.border)
        surface.DrawLine(w - 1, 0, w - 1, h)
    end

    -- ============================================================
    --  Content-Bereich
    -- ============================================================
    local content = vgui.Create("DPanel", f)
    content:SetPos(220, 56)
    content:SetSize(W - 220, H - 56)
    content.Paint = function() end

    -- Inhalts-Wrapper mit Slide-Animation
    local pages = {}
    local activePage
    local tabs = {}

    local function switchTab(key)
        if activePage and activePage.key == key then return end
        for _, t in pairs(tabs) do t.isActive = (t.key == key) end

        -- alte Seite ausfaden
        if IsValid(activePage) then
            local old = activePage
            old.fadeOut = 0
            old.Think = function(s)
                s.fadeOut = lerp(s.fadeOut, 1, math.min(FrameTime() * 14, 1))
                s:SetAlpha((1 - s.fadeOut) * 255)
                if s.fadeOut > 0.9 then s:Remove() end
            end
        end

        -- neue Seite einbauen
        local builder = pages[key]
        if not builder then return end
        local p = vgui.Create("DPanel", content)
        p:Dock(FILL)
        p.key = key
        p.Paint = function() end
        p:SetAlpha(0)
        p.slide = 20
        p.Think = function(s)
            local dt = math.min(FrameTime() * 10, 1)
            s.slide = lerp(s.slide, 0, dt)
            s:SetAlpha(math.min(s:GetAlpha() + FrameTime() * 600, 255))
        end
        builder(p)
        activePage = p
        surface.PlaySound("ui/buttonrollover.wav")
    end

    -- Refresh-Hook (von Row-Aktionen ausgelöst)
    hook.Add("WarnSys.MenuRefresh", f, function()
        if activePage and activePage.refresh then activePage.refresh() end
    end)

    -- ============================================================
    --  PAGE: Dashboard
    -- ============================================================
    pages.dashboard = function(page)
        local pad = 18

        -- Stats-Reihe (3 Karten)
        local statRow = vgui.Create("DPanel", page)
        statRow:Dock(TOP)
        statRow:DockMargin(pad, pad, pad, 8)
        statRow:SetTall(110)
        statRow.Paint = function() end

        local function getList()
            return WarnSys.Client.LastList
                and WarnSys.Client.LastList[LocalPlayer():SteamID()]
        end
        local function getTotal()
            local l = getList()
            return l and #l.rows or 0
        end
        local function getLast()
            local l = getList()
            return l and l.rows[1] and l.rows[1].created
        end

        local s1 = makeStat(statRow, "AKTIVE VERWARNUNGEN",
            function() return WarnSys.Client.ActiveWarns or 0 end,
            THEME.accent)
        s1:Dock(LEFT) s1:DockMargin(0, 0, 8, 0) s1:SetWide(240)

        local s2 = makeStat(statRow, "GESAMT (INKL. ABGELAUFEN)",
            getTotal, THEME.info)
        s2:Dock(LEFT) s2:DockMargin(0, 0, 8, 0) s2:SetWide(240)

        local s3 = makeStat(statRow, "LETZTE VERWARNUNG",
            function()
                local last = getLast()
                if not last then return "—" end
                local diff = os.time() - last
                if diff < 60 then return "gerade" end
                if diff < 3600 then return math.floor(diff / 60) .. "m" end
                if diff < 86400 then return math.floor(diff / 3600) .. "h" end
                return math.floor(diff / 86400) .. "d"
            end, THEME.warn)
        s3:Dock(FILL)

        -- Info-Karte
        local info = makeCard(page)
        info:Dock(TOP)
        info:DockMargin(pad, 6, pad, 6)
        info:SetTall(90)
        info.Paint = function(s, w, h)
            draw.RoundedBox(8, 0, 0, w, h, THEME.border)
            draw.RoundedBox(8, 1, 1, w - 2, h - 2, THEME.card)
            draw.SimpleText("Hinweis", "WS.H3", 18, 16, THEME.accent,
                TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            local txt = "Bei Verstößen gegen die Serverregeln kann ein Admin dich verwarnen.\n" ..
                "Ab einer bestimmten Anzahl wird automatisch eine Strafe (Kick/Ban) verhängt."
            draw.DrawText(txt, "WS.Body", 18, 38, THEME.textDim)
        end

        -- Neueste Warns
        local listHdr = vgui.Create("DLabel", page)
        listHdr:Dock(TOP)
        listHdr:DockMargin(pad, 8, pad, 4)
        listHdr:SetTall(24)
        listHdr:SetText("Deine letzten Verwarnungen")
        listHdr:SetFont("WS.H2")
        listHdr:SetTextColor(THEME.text)

        local scroll = vgui.Create("DScrollPanel", page)
        scroll:Dock(FILL)
        scroll:DockMargin(pad, 0, pad, pad)
        styleScroll(scroll)

        local function fill(rows)
            scroll:Clear()
            if not rows or #rows == 0 then
                local empty = vgui.Create("DLabel", scroll)
                empty:Dock(TOP)
                empty:SetTall(60)
                empty:SetText("Keine Verwarnungen — sauber bleiben! 🎉")
                empty:SetFont("WS.Body")
                empty:SetTextColor(THEME.textDim)
                empty:SetContentAlignment(5)
                return
            end
            for i = 1, math.min(#rows, 5) do
                makeWarnRow(scroll, rows[i], false)
            end
        end

        page.refresh = function()
            WarnSys.Client.RequestWarns(LocalPlayer():SteamID(), true)
        end

        hook.Add("WarnSys.WarnsReceived", page, function(sid, rows)
            if sid == LocalPlayer():SteamID() then fill(rows) end
        end)

        page.refresh()
    end

    -- ============================================================
    --  PAGE: Meine Verwarnungen
    -- ============================================================
    pages.mywarns = function(page)
        local pad = 18

        local hdr = vgui.Create("DPanel", page)
        hdr:Dock(TOP)
        hdr:DockMargin(pad, pad, pad, 8)
        hdr:SetTall(54)
        hdr.Paint = function(_, w, h)
            draw.RoundedBox(8, 0, 0, w, h, THEME.border)
            draw.RoundedBox(8, 1, 1, w - 2, h - 2, THEME.card)
            draw.SimpleText("Vollständige Verwarnungs-Historie", "WS.H2",
                16, h / 2, THEME.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        local filter = vgui.Create("DTextEntry", hdr)
        filter:SetPos(380, 13)
        filter:SetSize(260, 28)
        filter:SetPlaceholderText("Grund / Admin filtern…")
        filter.Paint = function(s, w, h)
            draw.RoundedBox(6, 0, 0, w, h, THEME.border)
            draw.RoundedBox(6, 1, 1, w - 2, h - 2, THEME.bg)
            s:DrawTextEntryText(THEME.text, THEME.accent, THEME.text)
        end

        local refreshBtn = makeButton(hdr, "Aktualisieren", THEME.info)
        refreshBtn:SetPos(hdr:GetWide() - 130, 13)
        refreshBtn:SetSize(110, 28)
        hdr.PerformLayout = function(_, w, h)
            refreshBtn:SetPos(w - 130, 13)
            filter:SetPos(w - 410, 13)
        end

        local scroll = vgui.Create("DScrollPanel", page)
        scroll:Dock(FILL)
        scroll:DockMargin(pad, 0, pad, pad)
        styleScroll(scroll)

        local allRows = {}
        local function fill()
            scroll:Clear()
            local needle = string.lower(filter:GetValue() or "")
            local shown = 0
            for _, r in ipairs(allRows) do
                if needle == ""
                    or string.find(string.lower(r.reason or ""), needle, 1, true)
                    or string.find(string.lower(r.admin_nick or ""), needle, 1, true) then
                    makeWarnRow(scroll, r, false)
                    shown = shown + 1
                end
            end
            if shown == 0 then
                local e = vgui.Create("DLabel", scroll)
                e:Dock(TOP) e:SetTall(60)
                e:SetText("Keine passenden Einträge.")
                e:SetFont("WS.Body") e:SetTextColor(THEME.textDim)
                e:SetContentAlignment(5)
            end
        end
        filter.OnChange = fill
        refreshBtn.DoClick = function()
            WarnSys.Client.RequestWarns(LocalPlayer():SteamID(), true)
        end

        page.refresh = refreshBtn.DoClick

        hook.Add("WarnSys.WarnsReceived", page, function(sid, rows)
            if sid ~= LocalPlayer():SteamID() then return end
            allRows = rows
            fill()
        end)
        page.refresh()
    end

    -- ============================================================
    --  PAGE: Admin (Spielerliste + Warn-UI)
    -- ============================================================
    pages.admin = function(page)
        local pad = 18
        local selected

        -- LINKS: Spieler-Liste
        local left = vgui.Create("DPanel", page)
        left:Dock(LEFT)
        left:DockMargin(pad, pad, 8, pad)
        left:SetWide(280)
        left.Paint = function(_, w, h)
            draw.RoundedBox(8, 0, 0, w, h, THEME.border)
            draw.RoundedBox(8, 1, 1, w - 2, h - 2, THEME.card)
        end

        local search = vgui.Create("DTextEntry", left)
        search:Dock(TOP)
        search:DockMargin(10, 10, 10, 6)
        search:SetTall(30)
        search:SetPlaceholderText("Spieler suchen…")
        search.Paint = function(s, w, h)
            draw.RoundedBox(6, 0, 0, w, h, THEME.border)
            draw.RoundedBox(6, 1, 1, w - 2, h - 2, THEME.bg)
            s:DrawTextEntryText(THEME.text, THEME.accent, THEME.text)
        end

        local plyScroll = vgui.Create("DScrollPanel", left)
        plyScroll:Dock(FILL)
        plyScroll:DockMargin(8, 0, 8, 10)
        styleScroll(plyScroll)

        local function refreshPlayers()
            plyScroll:Clear()
            local needle = string.lower(search:GetValue() or "")
            local plys = player.GetAll()
            table.sort(plys, function(a, b) return a:Nick() < b:Nick() end)
            for _, p in ipairs(plys) do
                if needle == ""
                    or string.find(string.lower(p:Nick()), needle, 1, true)
                    or string.find(string.lower(p:SteamID()), needle, 1, true) then

                    local row = vgui.Create("DButton", plyScroll)
                    row:Dock(TOP)
                    row:DockMargin(0, 0, 0, 4)
                    row:SetTall(50)
                    row:SetText("")
                    row.hoverFrac = 0
                    row.activeFrac = 0
                    row.ply = p
                    row.Think = function(s)
                        local dt = math.min(FrameTime() * 10, 1)
                        s.hoverFrac = lerp(s.hoverFrac, s:IsHovered() and 1 or 0, dt)
                        s.activeFrac = lerp(s.activeFrac,
                            (selected == p) and 1 or 0, dt)
                    end
                    row.Paint = function(s, w, h)
                        local c = lerpCol(math.max(s.hoverFrac * 0.6, s.activeFrac),
                            THEME.bg, THEME.cardHover)
                        draw.RoundedBox(6, 0, 0, w, h, c)
                        if s.activeFrac > 0.01 then
                            surface.SetDrawColor(THEME.accent)
                            surface.DrawRect(0, 0, 3 * s.activeFrac, h)
                        end
                        draw.SimpleText(p:Nick(), "WS.H3", 50, 10,
                            THEME.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                        draw.SimpleText(p:GetUserGroup(), "WS.Small", 50, 30,
                            THEME.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    end
                    local av = vgui.Create("AvatarImage", row)
                    av:SetPos(10, 10)
                    av:SetSize(30, 30)
                    av:SetPlayer(p, 32)
                    av:SetMouseInputEnabled(false)

                    row.DoClick = function()
                        selected = p
                        page.onSelect(p)
                        surface.PlaySound("ui/buttonclick.wav")
                    end
                end
            end
        end
        search.OnChange = refreshPlayers

        -- RECHTS: Aktionen + Liste
        local right = vgui.Create("DPanel", page)
        right:Dock(FILL)
        right:DockMargin(0, pad, pad, pad)
        right.Paint = function(_, w, h)
            draw.RoundedBox(8, 0, 0, w, h, THEME.border)
            draw.RoundedBox(8, 1, 1, w - 2, h - 2, THEME.card)
        end

        local plyHeader = vgui.Create("DPanel", right)
        plyHeader:Dock(TOP)
        plyHeader:SetTall(64)
        plyHeader.subtxt = "Wähle links einen Spieler aus."
        plyHeader.maintxt = "Kein Spieler gewählt"
        plyHeader.Paint = function(s, w, h)
            surface.SetDrawColor(THEME.border)
            surface.DrawLine(10, h - 1, w - 10, h - 1)
            draw.SimpleText(s.maintxt, "WS.H2", 18, 14,
                THEME.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(s.subtxt, "WS.Small", 18, 40,
                THEME.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        -- Grund-Eingabe
        local reasonWrap = vgui.Create("DPanel", right)
        reasonWrap:Dock(TOP)
        reasonWrap:DockMargin(14, 12, 14, 4)
        reasonWrap:SetTall(76)
        reasonWrap.Paint = function() end

        local preset = vgui.Create("DComboBox", reasonWrap)
        preset:Dock(TOP)
        preset:SetTall(28)
        preset:DockMargin(0, 0, 0, 6)
        preset:SetValue("— Voreinstellung —")
        preset:SetTextColor(THEME.text)
        for _, r in ipairs(WarnSys.Config.PresetReasons) do preset:AddChoice(r) end
        preset.Paint = function(s, w, h)
            draw.RoundedBox(6, 0, 0, w, h, THEME.border)
            draw.RoundedBox(6, 1, 1, w - 2, h - 2, THEME.bg)
            draw.SimpleText(s:GetText(), "WS.Body", 10, h / 2,
                THEME.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        local reason = vgui.Create("DTextEntry", reasonWrap)
        reason:Dock(TOP)
        reason:SetTall(32)
        reason:SetPlaceholderText("Grund eingeben…")
        reason.Paint = function(s, w, h)
            draw.RoundedBox(6, 0, 0, w, h, THEME.border)
            draw.RoundedBox(6, 1, 1, w - 2, h - 2, THEME.bg)
            s:DrawTextEntryText(THEME.text, THEME.accent, THEME.text)
        end
        preset.OnSelect = function(_, _, value) reason:SetValue(value) end

        -- Aktions-Buttons
        local actions = vgui.Create("DPanel", right)
        actions:Dock(TOP)
        actions:DockMargin(14, 4, 14, 8)
        actions:SetTall(40)
        actions.Paint = function() end

        local btnWarn = makeButton(actions, "Verwarnen", THEME.accent, "⚠")
        btnWarn:Dock(LEFT)
        btnWarn:DockMargin(0, 0, 8, 0)
        btnWarn:SetWide(160)

        local btnView = makeButton(actions, "Aktualisieren", THEME.info, "↻")
        btnView:Dock(LEFT)
        btnView:DockMargin(0, 0, 8, 0)
        btnView:SetWide(160)

        local btnClear
        if canPerm("clearwarns") then
            btnClear = makeButton(actions, "Alle löschen", Color(120, 120, 130), "✕")
            btnClear:Dock(LEFT)
            btnClear:DockMargin(0, 0, 0, 0)
            btnClear:SetWide(160)
        end

        -- Warn-Liste des Ziels
        local scroll = vgui.Create("DScrollPanel", right)
        scroll:Dock(FILL)
        scroll:DockMargin(14, 4, 14, 14)
        styleScroll(scroll)

        local function fill(rows)
            scroll:Clear()
            if #rows == 0 then
                local e = vgui.Create("DLabel", scroll)
                e:Dock(TOP) e:SetTall(60)
                e:SetText("Keine Verwarnungen für diesen Spieler.")
                e:SetFont("WS.Body") e:SetTextColor(THEME.textDim)
                e:SetContentAlignment(5)
                return
            end
            for _, r in ipairs(rows) do
                makeWarnRow(scroll, r, true)
            end
        end

        page.onSelect = function(p)
            plyHeader.maintxt = p:Nick()
            local active = 0
            plyHeader.subtxt = p:SteamID() .. "  •  Rang: " .. p:GetUserGroup()
            WarnSys.Client.RequestWarns(p:SteamID(), true)
        end

        hook.Add("WarnSys.WarnsReceived", page, function(sid, rows)
            if not IsValid(selected) or selected:SteamID() ~= sid then return end
            local active = 0
            for _, r in ipairs(rows) do
                if r.active then active = active + 1 end
            end
            plyHeader.subtxt = string.format("%s  •  %s  •  %d aktiv / %d gesamt",
                selected:SteamID(), selected:GetUserGroup(), active, #rows)
            fill(rows)
        end)

        btnWarn.DoClick = function()
            if not IsValid(selected) then
                Derma_Message("Wähle zuerst einen Spieler.", "WarnSys", "OK") return
            end
            local r = reason:GetValue()
            if #r < WarnSys.Config.MinReasonLength then
                Derma_Message(WarnSys.L("invalid_reason",
                    WarnSys.Config.MinReasonLength,
                    WarnSys.Config.MaxReasonLength), "WarnSys", "OK") return
            end
            net.Start("WarnSys.DoWarn")
                net.WriteEntity(selected)
                net.WriteString(r)
            net.SendToServer()
            reason:SetValue("")
            preset:SetValue("— Voreinstellung —")
            surface.PlaySound("buttons/button14.wav")
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

        if btnClear then
            btnClear.DoClick = function()
                if not IsValid(selected) then return end
                Derma_Query(WarnSys.L("menu_confirm_clear", selected:Nick()),
                    "WarnSys", "Ja, alle löschen", function()
                        net.Start("WarnSys.DoClear")
                            net.WriteEntity(selected)
                        net.SendToServer()
                        timer.Simple(0.4, function()
                            if IsValid(selected) then
                                WarnSys.Client.RequestWarns(selected:SteamID(), true)
                            end
                        end)
                    end, "Abbrechen")
            end
        end

        page.refresh = refreshPlayers
        refreshPlayers()

        -- Auto-Refresh wenn Spieler joinen/leaven
        timer.Create("WarnSys.AdminPlyRefresh", 5, 0, function()
            if not IsValid(page) then
                timer.Remove("WarnSys.AdminPlyRefresh") return
            end
            refreshPlayers()
        end)
    end

    -- ============================================================
    --  PAGE: Hilfe / Regeln
    -- ============================================================
    pages.help = function(page)
        local pad = 18

        local card = makeCard(page)
        card:Dock(TOP)
        card:DockMargin(pad, pad, pad, 8)
        card:SetTall(200)
        card.Paint = function(_, w, h)
            draw.RoundedBox(8, 0, 0, w, h, THEME.border)
            draw.RoundedBox(8, 1, 1, w - 2, h - 2, THEME.card)
            draw.SimpleText("Befehle", "WS.H2", 18, 14, THEME.text,
                TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            local cmds = {
                { "!warns",           "Dieses Menü öffnen" },
                { "!warn <p> <g>",    "Spieler verwarnen (Admin)" },
                { "!unwarn <id>",     "Verwarnung entfernen (Admin)" },
                { "ulx warns [p]",    "Verwarnungen anzeigen" },
                { "ulx clearwarns p", "Alle Warns löschen (SuperAdmin)" },
            }
            local y = 50
            for _, c in ipairs(cmds) do
                draw.SimpleText(c[1], "WS.Mono", 22, y, THEME.accent,
                    TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText(c[2], "WS.Body", 220, y, THEME.textDim,
                    TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                y = y + 24
            end
        end

        local rules = makeCard(page)
        rules:Dock(FILL)
        rules:DockMargin(pad, 0, pad, pad)
        rules.Paint = function(_, w, h)
            draw.RoundedBox(8, 0, 0, w, h, THEME.border)
            draw.RoundedBox(8, 1, 1, w - 2, h - 2, THEME.card)
            draw.SimpleText("Auto-Bestrafung", "WS.H2", 18, 14, THEME.text,
                TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            local y = 50
            local thresholds = {}
            for n in pairs(WarnSys.Config.AutoPunish) do
                table.insert(thresholds, n)
            end
            table.sort(thresholds)
            for _, n in ipairs(thresholds) do
                local r = WarnSys.Config.AutoPunish[n]
                local label = r.type
                if r.type == "tempban" then label = "Tempban " .. r.time .. " min" end
                if r.type == "ban" then label = "Permanenter Ban" end
                if r.type == "kick" then label = "Kick" end
                draw.SimpleText("Ab " .. n .. " Warns:", "WS.H3", 22, y,
                    THEME.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText(label, "WS.Body", 160, y,
                    THEME.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText(r.reason or "", "WS.Small", 22, y + 22,
                    THEME.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                y = y + 50
            end
        end
    end

    -- ============================================================
    --  PAGE: Einstellungen (nur für SuperAdmin / editConfig)
    -- ============================================================
    pages.settings = function(page)
        local pad = 18

        -- ---------- Mini-Widget-Helfer ----------
        local function styledEntry(parent, default, numeric)
            local e = vgui.Create("DTextEntry", parent)
            e:SetTall(28)
            e:SetText(tostring(default or ""))
            e:SetNumeric(numeric == true)
            e:SetUpdateOnType(true)
            e.Paint = function(s, w, h)
                draw.RoundedBox(6, 0, 0, w, h, THEME.border)
                draw.RoundedBox(6, 1, 1, w - 2, h - 2, THEME.bg)
                s:DrawTextEntryText(THEME.text, THEME.accent, THEME.text)
            end
            return e
        end

        local function styledCheckbox(parent, checked)
            local c = vgui.Create("DButton", parent)
            c:SetText("")
            c:SetSize(28, 28)
            c.checked = checked == true
            c.hoverFrac = 0
            c.Think = function(s)
                s.hoverFrac = lerp(s.hoverFrac, s:IsHovered() and 1 or 0,
                    math.min(FrameTime() * 10, 1))
            end
            c.Paint = function(s, w, h)
                local col = s.checked and THEME.accent
                    or lerpCol(s.hoverFrac, THEME.bg, THEME.cardHover)
                draw.RoundedBox(6, 0, 0, w, h, THEME.border)
                draw.RoundedBox(6, 1, 1, w - 2, h - 2, col)
                if s.checked then
                    draw.SimpleText("✓", "WS.H3", w / 2, h / 2, THEME.text,
                        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end
            c.DoClick = function(s)
                s.checked = not s.checked
                surface.PlaySound("ui/buttonclick.wav")
            end
            return c
        end

        local function styledCombo(parent, choices, current)
            local c = vgui.Create("DComboBox", parent)
            c:SetTall(28)
            c:SetValue(current or choices[1] or "")
            c:SetTextColor(THEME.text)
            for _, ch in ipairs(choices) do c:AddChoice(ch) end
            c.Paint = function(s, w, h)
                draw.RoundedBox(6, 0, 0, w, h, THEME.border)
                draw.RoundedBox(6, 1, 1, w - 2, h - 2, THEME.bg)
                draw.SimpleText(s:GetText(), "WS.Body", 10, h / 2,
                    THEME.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText("▼", "WS.Small", w - 12, h / 2,
                    THEME.textDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
            return c
        end

        local function sectionHeader(parent, title, icon)
            local p = vgui.Create("DPanel", parent)
            p:Dock(TOP)
            p:DockMargin(0, 8, 0, 6)
            p:SetTall(38)
            p.Paint = function(_, w, h)
                draw.SimpleText(icon or "▸", "WS.H2", 0, h / 2,
                    THEME.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(title, "WS.H2", 28, h / 2,
                    THEME.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                surface.SetDrawColor(THEME.border)
                surface.DrawLine(0, h - 1, w, h - 1)
            end
            return p
        end

        -- Eine Zeile: Label links, Widget rechts
        local function row(parent, label, widget, hint)
            local p = vgui.Create("DPanel", parent)
            p:Dock(TOP)
            p:DockMargin(0, 4, 0, 4)
            p:SetTall(hint and 50 or 36)
            p.Paint = function(_, w, h)
                draw.SimpleText(label, "WS.Body", 4, hint and 6 or h / 2,
                    THEME.text, TEXT_ALIGN_LEFT,
                    hint and TEXT_ALIGN_TOP or TEXT_ALIGN_CENTER)
                if hint then
                    draw.SimpleText(hint, "WS.Small", 4, h - 14,
                        THEME.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
            end
            widget:SetParent(p)
            widget:Dock(RIGHT)
            widget:DockMargin(8, 4, 0, 4)
            return p
        end

        -- ---------- Layout: Header + Scroll + Footer ----------
        local header = vgui.Create("DPanel", page)
        header:Dock(TOP)
        header:DockMargin(pad, pad, pad, 0)
        header:SetTall(54)
        header.Paint = function(_, w, h)
            draw.RoundedBox(8, 0, 0, w, h, THEME.border)
            draw.RoundedBox(8, 1, 1, w - 2, h - 2, THEME.card)
            draw.SimpleText("⚙  Server-Einstellungen", "WS.H2",
                16, h / 2, THEME.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText("Änderungen werden persistent gespeichert",
                "WS.Small", w - 16, h / 2, THEME.textDim,
                TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end

        -- Footer (Speichern-Buttons)
        local footer = vgui.Create("DPanel", page)
        footer:Dock(BOTTOM)
        footer:DockMargin(pad, 0, pad, pad)
        footer:SetTall(52)
        footer.Paint = function(_, w, h)
            draw.RoundedBox(8, 0, 0, w, h, THEME.border)
            draw.RoundedBox(8, 1, 1, w - 2, h - 2, THEME.card)
        end

        -- Scroll-Bereich (direktes Docking auf Scroll)
        local scroll = vgui.Create("DScrollPanel", page)
        scroll:Dock(FILL)
        scroll:DockMargin(pad, 6, pad, 6)
        styleScroll(scroll)
        local canvas = scroll

        -- ---------- Felder erstellen (vorerst leer; werden bei Empfang gefüllt) ----------
        local fields = {}

        local function build(cfg)
            scroll:GetCanvas():Clear()
            fields = {}

            -- ALLGEMEIN
            sectionHeader(canvas, "Allgemein", "⚙"):SetParent(canvas)
            fields.Language = styledCombo(canvas, { "de", "en" }, cfg.Language)
            fields.Language:SetWide(120)
            row(canvas, "Sprache", fields.Language,
                "Wird live an alle Spieler übertragen.")

            fields.MinReasonLength = styledEntry(canvas, cfg.MinReasonLength, true)
            fields.MinReasonLength:SetWide(80)
            row(canvas, "Min. Grund-Länge", fields.MinReasonLength)

            fields.MaxReasonLength = styledEntry(canvas, cfg.MaxReasonLength, true)
            fields.MaxReasonLength:SetWide(80)
            row(canvas, "Max. Grund-Länge", fields.MaxReasonLength)

            fields.WarnCooldown = styledEntry(canvas, cfg.WarnCooldown, true)
            fields.WarnCooldown:SetWide(80)
            row(canvas, "Cooldown (Sek.)", fields.WarnCooldown,
                "Sekunden zwischen zwei Warns desselben Admins.")

            fields.ExpireDays = styledEntry(canvas, cfg.ExpireDays, true)
            fields.ExpireDays:SetWide(80)
            row(canvas, "Ablauf (Tage)", fields.ExpireDays,
                "0 = Verwarnungen laufen nie ab.")

            fields.KeepHistory = styledCheckbox(canvas, cfg.KeepHistory)
            row(canvas, "History behalten", fields.KeepHistory,
                "Abgelaufene Warns werden archiviert, statt gelöscht.")

            fields.AllowSelfWarn = styledCheckbox(canvas, cfg.AllowSelfWarn)
            row(canvas, "Selbst-Warnen erlauben", fields.AllowSelfWarn)

            fields.AllowWarnHigherRank = styledCheckbox(canvas, cfg.AllowWarnHigherRank)
            row(canvas, "Höhere Ränge warnen", fields.AllowWarnHigherRank)

            fields.NotifyAllAdmins = styledCheckbox(canvas, cfg.NotifyAllAdmins)
            row(canvas, "Admins informieren", fields.NotifyAllAdmins,
                "Andere Admins sehen, wenn jemand verwarnt wird.")

            fields.BroadcastWarn = styledCheckbox(canvas, cfg.BroadcastWarn)
            row(canvas, "Broadcast im Chat", fields.BroadcastWarn,
                "Jeder Spieler sieht jede Verwarnung im Chat.")

            -- AUTO-BESTRAFUNG
            sectionHeader(canvas, "Auto-Bestrafung", "⚠"):SetParent(canvas)
            local punishContainer = vgui.Create("DPanel", canvas)
            punishContainer:Dock(TOP)
            punishContainer:DockMargin(0, 4, 0, 4)
            punishContainer:SetTall(10)
            punishContainer.Paint = function() end
            fields.AutoPunish = {}

            local function addPunishRow(threshold, def)
                local p = vgui.Create("DPanel", punishContainer)
                p:Dock(TOP)
                p:DockMargin(0, 0, 0, 6)
                p:SetTall(40)
                p.Paint = function(_, w, h)
                    draw.RoundedBox(6, 0, 0, w, h, THEME.bg)
                end

                local lblWarns = vgui.Create("DLabel", p)
                lblWarns:Dock(LEFT) lblWarns:SetWide(70)
                lblWarns:DockMargin(10, 0, 4, 0)
                lblWarns:SetText("Ab Warns:") lblWarns:SetTextColor(THEME.textDim)
                lblWarns:SetFont("WS.Small")

                local entryNum = styledEntry(p, threshold, true)
                entryNum:SetWide(50)
                entryNum:Dock(LEFT) entryNum:DockMargin(0, 6, 8, 6)

                local typeCombo = styledCombo(p,
                    { "kick", "tempban", "ban", "none" }, def.type)
                typeCombo:SetWide(110)
                typeCombo:Dock(LEFT) typeCombo:DockMargin(0, 6, 8, 6)

                local entryTime = styledEntry(p, def.time or 60, true)
                entryTime:SetWide(70)
                entryTime:Dock(LEFT) entryTime:DockMargin(0, 6, 8, 6)
                entryTime:SetTooltip("Minuten (nur bei tempban)")

                local entryReason = styledEntry(p, def.reason or "")
                entryReason:Dock(FILL) entryReason:DockMargin(0, 6, 8, 6)

                local delBtn = vgui.Create("DButton", p)
                delBtn:SetText("")
                delBtn:Dock(RIGHT) delBtn:DockMargin(0, 6, 10, 6)
                delBtn:SetWide(32)
                delBtn.hoverFrac = 0
                delBtn.Think = function(s)
                    s.hoverFrac = lerp(s.hoverFrac, s:IsHovered() and 1 or 0,
                        math.min(FrameTime() * 10, 1))
                end
                delBtn.Paint = function(s, w, h)
                    draw.RoundedBox(6, 0, 0, w, h,
                        lerpCol(s.hoverFrac, THEME.card, THEME.accent))
                    draw.SimpleText("✕", "WS.H3", w / 2, h / 2, THEME.text,
                        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end

                local entry = {
                    num = entryNum, typeC = typeCombo,
                    time = entryTime, reason = entryReason, panel = p,
                }
                table.insert(fields.AutoPunish, entry)

                delBtn.DoClick = function()
                    for i, e in ipairs(fields.AutoPunish) do
                        if e == entry then
                            table.remove(fields.AutoPunish, i) break
                        end
                    end
                    p:Remove()
                    surface.PlaySound("buttons/button10.wav")
                end
            end

            -- Bestehende Rules laden
            local thresholds = {}
            for n in pairs(cfg.AutoPunish or {}) do table.insert(thresholds, n) end
            table.sort(thresholds)
            for _, n in ipairs(thresholds) do
                addPunishRow(n, cfg.AutoPunish[n])
            end

            local addBtn = makeButton(canvas, "+ Regel hinzufügen", THEME.info, "+")
            addBtn:Dock(TOP) addBtn:DockMargin(0, 4, 0, 8)
            addBtn:SetTall(32)
            addBtn.DoClick = function()
                addPunishRow(1, { type = "kick", reason = "" })
                punishContainer:SizeToChildren(false, true)
            end

            -- MYSQL
            sectionHeader(canvas, "Speicher (SQLite / MySQL)", "▤"):SetParent(canvas)
            fields.Storage = styledCombo(canvas, { "sqlite", "mysql" }, cfg.Storage)
            fields.Storage:SetWide(140)
            row(canvas, "Speicher-Backend", fields.Storage,
                "MySQL benötigt das MySQLOO-Modul.")

            local m = cfg.MySQL or {}
            fields.MySQL_host = styledEntry(canvas, m.host)
            fields.MySQL_host:SetWide(260)
            row(canvas, "MySQL Host", fields.MySQL_host)

            fields.MySQL_port = styledEntry(canvas, m.port, true)
            fields.MySQL_port:SetWide(100)
            row(canvas, "MySQL Port", fields.MySQL_port)

            fields.MySQL_user = styledEntry(canvas, m.user)
            fields.MySQL_user:SetWide(220)
            row(canvas, "MySQL User", fields.MySQL_user)

            fields.MySQL_pass = styledEntry(canvas, m.pass)
            fields.MySQL_pass:SetWide(220)
            fields.MySQL_pass:SetTextColor(THEME.text)
            -- Hinweis: kein echter Passwort-Modus, weil DTextEntry kein SetPasswordChar hat,
            --        aber die Anzeige reicht für Server-Owner.
            row(canvas, "MySQL Passwort", fields.MySQL_pass)

            fields.MySQL_database = styledEntry(canvas, m.database)
            fields.MySQL_database:SetWide(220)
            row(canvas, "MySQL Datenbank", fields.MySQL_database)

            local testBtn = makeButton(canvas, "Verbindung testen", THEME.info, "↻")
            testBtn:Dock(TOP) testBtn:DockMargin(0, 4, 0, 8)
            testBtn:SetTall(34)
            testBtn:SetWide(200)
            testBtn.DoClick = function()
                WarnSys.Client.TestMySQL({
                    host     = fields.MySQL_host:GetValue(),
                    port     = tonumber(fields.MySQL_port:GetValue()) or 3306,
                    user     = fields.MySQL_user:GetValue(),
                    pass     = fields.MySQL_pass:GetValue(),
                    database = fields.MySQL_database:GetValue(),
                })
                WarnSys.Util.Notify(LocalPlayer(), "Teste Verbindung…", 3)
            end

            -- DISCORD
            sectionHeader(canvas, "Discord-Webhook", "▣"):SetParent(canvas)
            local d = cfg.Discord or {}
            fields.Discord_enabled = styledCheckbox(canvas, d.enabled)
            row(canvas, "Aktiviert", fields.Discord_enabled)

            fields.Discord_webhook = styledEntry(canvas, d.webhook)
            fields.Discord_webhook:SetWide(420)
            row(canvas, "Webhook-URL", fields.Discord_webhook,
                "https://discord.com/api/webhooks/…")

            fields.Discord_username = styledEntry(canvas, d.username)
            fields.Discord_username:SetWide(220)
            row(canvas, "Anzeigename", fields.Discord_username)

        end

        -- ---------- Buttons im Footer ----------
        local saveBtn = makeButton(footer, "Einstellungen speichern", THEME.accent, "✓")
        saveBtn:SetPos(0, 0) saveBtn:SetSize(220, 0)
        local reloadBtn = makeButton(footer, "Neu laden", THEME.info, "↻")
        reloadBtn:SetPos(0, 0) reloadBtn:SetSize(140, 0)

        footer.PerformLayout = function(_, w, h)
            saveBtn:SetPos(w - 240, 10) saveBtn:SetSize(220, h - 20)
            reloadBtn:SetPos(w - 400, 10) reloadBtn:SetSize(140, h - 20)
        end

        saveBtn.DoClick = function()
            -- AutoPunish-Map zusammenbauen
            local auto = {}
            for _, e in ipairs(fields.AutoPunish) do
                local n = tonumber(e.num:GetValue())
                if n then
                    auto[n] = {
                        type   = e.typeC:GetText(),
                        time   = tonumber(e.time:GetValue()),
                        reason = e.reason:GetValue(),
                    }
                end
            end
            local data = {
                Language            = fields.Language:GetText(),
                MinReasonLength     = tonumber(fields.MinReasonLength:GetValue()),
                MaxReasonLength     = tonumber(fields.MaxReasonLength:GetValue()),
                WarnCooldown        = tonumber(fields.WarnCooldown:GetValue()),
                ExpireDays          = tonumber(fields.ExpireDays:GetValue()),
                KeepHistory         = fields.KeepHistory.checked,
                AllowSelfWarn       = fields.AllowSelfWarn.checked,
                AllowWarnHigherRank = fields.AllowWarnHigherRank.checked,
                NotifyAllAdmins     = fields.NotifyAllAdmins.checked,
                BroadcastWarn       = fields.BroadcastWarn.checked,
                AutoPunish          = auto,
                Storage             = fields.Storage:GetText(),
                MySQL = {
                    host     = fields.MySQL_host:GetValue(),
                    port     = tonumber(fields.MySQL_port:GetValue()) or 3306,
                    user     = fields.MySQL_user:GetValue(),
                    pass     = fields.MySQL_pass:GetValue(),
                    database = fields.MySQL_database:GetValue(),
                },
                Discord = {
                    enabled  = fields.Discord_enabled.checked,
                    webhook  = fields.Discord_webhook:GetValue(),
                    username = fields.Discord_username:GetValue(),
                },
            }
            WarnSys.Client.SaveConfig(data)
            surface.PlaySound("buttons/button14.wav")
        end

        reloadBtn.DoClick = function()
            WarnSys.Client.RequestConfig()
            surface.PlaySound("ui/buttonclick.wav")
        end

        -- Test-Result Notification
        hook.Add("WarnSys.MySQLTestResult", page, function(ok, msg)
            WarnSys.Util.Notify(LocalPlayer(),
                (ok and "MySQL OK: " or "MySQL Fehler: ") .. msg,
                ok and 0 or 1)
        end)

        -- Empfangs-Hook
        hook.Add("WarnSys.RemoteConfigReceived", page, function()
            if WarnSys.Client.RemoteConfig then
                build(WarnSys.Client.RemoteConfig)
            end
        end)

        -- Initial laden
        if WarnSys.Client.RemoteConfig then
            build(WarnSys.Client.RemoteConfig)
        else
            WarnSys.Client.RequestConfig()
            local loading = vgui.Create("DLabel", canvas)
            loading:Dock(TOP) loading:SetTall(60)
            loading:SetText("Lädt Einstellungen…")
            loading:SetFont("WS.Body") loading:SetTextColor(THEME.textDim)
            loading:SetContentAlignment(5)
        end

        page.refresh = function() WarnSys.Client.RequestConfig() end
    end

    -- ============================================================
    --  Sidebar-Tabs erstellen
    -- ============================================================
    local title = vgui.Create("DLabel", sidebar)
    title:Dock(TOP)
    title:DockMargin(20, 16, 20, 4)
    title:SetTall(18)
    title:SetText("ÜBERSICHT")
    title:SetFont("WS.Small")
    title:SetTextColor(THEME.textMuted)

    tabs.dashboard = makeTab(sidebar, "Dashboard",  "▣", "dashboard")
    tabs.mywarns   = makeTab(sidebar, "Meine Warns", "◉", "mywarns")

    if canPerm("warn") then
        local sep = vgui.Create("DLabel", sidebar)
        sep:Dock(TOP) sep:DockMargin(20, 16, 20, 4) sep:SetTall(18)
        sep:SetText("ADMIN") sep:SetFont("WS.Small")
        sep:SetTextColor(THEME.textMuted)
        tabs.admin = makeTab(sidebar, "Spieler verwalten", "⚙", "admin")
    end

    if canPerm("editConfig") then
        local sep = vgui.Create("DLabel", sidebar)
        sep:Dock(TOP) sep:DockMargin(20, 16, 20, 4) sep:SetTall(18)
        sep:SetText("SERVER") sep:SetFont("WS.Small")
        sep:SetTextColor(THEME.textMuted)
        tabs.settings = makeTab(sidebar, "Einstellungen", "✦", "settings")
    end

    local sep2 = vgui.Create("DLabel", sidebar)
    sep2:Dock(TOP) sep2:DockMargin(20, 16, 20, 4) sep2:SetTall(18)
    sep2:SetText("INFO") sep2:SetFont("WS.Small")
    sep2:SetTextColor(THEME.textMuted)
    tabs.help = makeTab(sidebar, "Befehle & Regeln", "?", "help")

    for _, t in pairs(tabs) do
        t.DoClick = function(s) switchTab(s.key) end
    end

    -- Footer in Sidebar
    local footer = vgui.Create("DPanel", sidebar)
    footer:Dock(BOTTOM)
    footer:DockMargin(20, 0, 20, 14)
    footer:SetTall(36)
    footer.Paint = function(_, w, h)
        draw.SimpleText("WarnSys v" .. WarnSys.Version, "WS.Small",
            0, 0, THEME.textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Made for RP-Servers", "WS.Small",
            0, 18, THEME.textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    -- ESC schließt (zusätzlich zum Think-Anim-Loop)
    local prevThink = f.Think
    f.Think = function(s)
        prevThink(s)
        if input.IsKeyDown(KEY_ESCAPE) and not s._closing then
            s._closing = true
            close:DoClick()
        end
    end

    switchTab(initialTab or "dashboard")
    surface.PlaySound("ui/buttonclick.wav")
end

-- Konsolen-Befehle
concommand.Add("warnsys_menu",    function() WarnSys.Client.OpenMenu() end)
concommand.Add("warnsys_mywarns", function() WarnSys.Client.OpenMenu("mywarns") end)

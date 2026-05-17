-- WarnSys :: Chat-Befehle (Fallback, wenn ULX nicht installiert ist)

-- Eigene Warns dem Aufrufer privat in den Chat schreiben
local function printOwnWarns(ply)
    if not IsValid(ply) then return end
    WarnSys.DB.GetByPlayer(ply:SteamID(), true, function(rows)
        if not IsValid(ply) then return end
        rows = rows or {}
        local active = 0
        for _, r in ipairs(rows) do
            if tonumber(r.active) == 1 then active = active + 1 end
        end
        ply:ChatPrint(WarnSys.L("warnlist_header", ply:Nick(), active))
        if #rows == 0 then
            ply:ChatPrint(WarnSys.L("warnlist_empty"))
            return
        end
        for _, r in ipairs(rows) do
            local tag = tonumber(r.active) == 1 and "" or WarnSys.L("expired_tag")
            ply:ChatPrint(WarnSys.L("warnlist_line",
                tonumber(r.id), r.reason or "?", r.admin_nick or "?",
                WarnSys.Util.FormatTime(tonumber(r.created)), tag))
        end
    end)
end

hook.Add("PlayerSay", "WarnSys.ChatCmds", function(ply, text)
    local lower = string.lower(text)

    -- !warns / !warnmenu / !mywarns  ->  Menü öffnen (für alle Spieler)
    if lower == "!warns" or lower == "/warns"
        or lower == "!warnmenu" or lower == "/warnmenu"
        or lower == "!mywarns" or lower == "/mywarns" then

        -- Menü-Öffnen Recht
        if not WarnSys.Util.HasPermission(ply, "openMenu") then
            WarnSys.Util.Notify(ply, WarnSys.L("no_perm"), 1)
            return ""
        end

        -- !warnmenu => Admin-Tab (falls erlaubt), sonst eigene Warns
        local tab = "mywarns"
        if lower:find("warnmenu") and WarnSys.Util.CanSeePanel(ply, "admin") then
            tab = "admin"
        end
        if not WarnSys.Util.CanSeePanel(ply, tab) then
            tab = "mywarns"
        end

        net.Start("WarnSys.OpenMenu")
            net.WriteString(tab)
        net.Send(ply)

        -- Eigene Warns immer auch privat im Chat anzeigen (nur für den Aufrufer)
        if lower ~= "!warnmenu" and lower ~= "/warnmenu" then
            printOwnWarns(ply)
        end
        return ""
    end

    -- !warnhelp
    if lower == "!warnhelp" or lower == "/warnhelp" then
        ply:ChatPrint(WarnSys.L("cmd_help"))
        return ""
    end

    -- !warn <nick> <grund>  (Fallback ohne ULX)
    if lower:sub(1, 5) == "!warn" and lower:sub(6, 6) == " " then
        if not WarnSys.Util.HasPermission(ply, "warn") then
            WarnSys.Util.Notify(ply, WarnSys.L("no_perm"), 1) return ""
        end
        local rest = string.Trim(text:sub(6))
        local space = rest:find(" ")
        if not space then
            WarnSys.Util.Notify(ply, WarnSys.L("cmd_help"), 1) return ""
        end
        local nick   = rest:sub(1, space - 1)
        local reason = string.Trim(rest:sub(space + 1))

        local target
        local lc = string.lower(nick)
        for _, p in ipairs(player.GetAll()) do
            if string.find(string.lower(p:Nick()), lc, 1, true) then
                target = p break
            end
        end
        if not IsValid(target) then
            WarnSys.Util.Notify(ply, WarnSys.L("invalid_target"), 1) return ""
        end
        WarnSys.Core.Warn(ply, target, reason)
        return ""
    end

    -- !unwarn <id>  (Fallback ohne ULX)
    if lower:sub(1, 7) == "!unwarn" and lower:sub(8, 8) == " " then
        if not WarnSys.Util.HasPermission(ply, "unwarn") then
            WarnSys.Util.Notify(ply, WarnSys.L("no_perm"), 1) return ""
        end
        local id = tonumber(string.Trim(text:sub(8)))
        if not id then
            WarnSys.Util.Notify(ply, "Ungültige ID.", 1) return ""
        end
        WarnSys.Core.Unwarn(ply, id)
        return ""
    end
end)
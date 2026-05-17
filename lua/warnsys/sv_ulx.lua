-- WarnSys :: ULX-Integration
-- Registriert die Befehle erst, sobald ULX wirklich verfügbar ist.

local function register()
    if not ulx or not ULib then return false end

    local CATEGORY = "Warn-System"

    -- ============================================================
    --  ulx warn <ply> <reason>
    -- ============================================================
    function ulx.warn(calling_ply, target_ply, reason)
        WarnSys.Core.Warn(calling_ply, target_ply, reason)
    end
    local warnCmd = ulx.command(CATEGORY, "ulx warn", ulx.warn, "!warn", true)
    warnCmd:addParam{ type = ULib.cmds.PlayerArg }
    warnCmd:addParam{ type = ULib.cmds.StringArg,
                      hint = "Grund", ULib.cmds.takeRestOfLine }
    warnCmd:defaultAccess(ULib.ACCESS_ADMIN)
    warnCmd:help("Verwarnt einen Spieler mit angegebenem Grund.")

    -- ============================================================
    --  ulx unwarn <id>
    -- ============================================================
    function ulx.unwarn(calling_ply, id)
        WarnSys.Core.Unwarn(calling_ply, id)
    end
    local unwarnCmd = ulx.command(CATEGORY, "ulx unwarn", ulx.unwarn, "!unwarn")
    unwarnCmd:addParam{ type = ULib.cmds.NumArg, hint = "Warn-ID", min = 1 }
    unwarnCmd:defaultAccess(ULib.ACCESS_ADMIN)
    unwarnCmd:help("Entfernt eine Verwarnung anhand ihrer ID.")

    -- ============================================================
    --  ulx clearwarns <ply>
    -- ============================================================
    function ulx.clearwarns(calling_ply, target_ply)
        WarnSys.Core.ClearWarns(calling_ply, target_ply)
    end
    local clearCmd = ulx.command(CATEGORY, "ulx clearwarns", ulx.clearwarns, "!clearwarns")
    clearCmd:addParam{ type = ULib.cmds.PlayerArg }
    clearCmd:defaultAccess(ULib.ACCESS_SUPERADMIN)
    clearCmd:help("Löscht ALLE Verwarnungen eines Spielers.")

    -- ============================================================
    --  ulx warns [ply]
    -- ============================================================
    function ulx.warns(calling_ply, target_ply)
        local sid = IsValid(target_ply) and target_ply:SteamID() or calling_ply:SteamID()
        if sid ~= calling_ply:SteamID() and not WarnSys.Util.HasPermission(calling_ply, "viewWarns") then
            WarnSys.Util.Notify(calling_ply, WarnSys.L("no_perm"), 1)
            return
        end
        WarnSys.DB.GetByPlayer(sid, true, function(rows)
            rows = rows or {}
            local nick = IsValid(target_ply) and target_ply:Nick() or calling_ply:Nick()
            local active = 0
            for _, r in ipairs(rows) do
                if tonumber(r.active) == 1 then active = active + 1 end
            end
            calling_ply:ChatPrint(WarnSys.L("warnlist_header", nick, active))
            if #rows == 0 then
                calling_ply:ChatPrint(WarnSys.L("warnlist_empty"))
                return
            end
            for _, r in ipairs(rows) do
                local tag = tonumber(r.active) == 1 and "" or WarnSys.L("expired_tag")
                calling_ply:ChatPrint(WarnSys.L("warnlist_line",
                    tonumber(r.id), r.reason or "?", r.admin_nick or "?",
                    WarnSys.Util.FormatTime(tonumber(r.created)), tag))
            end
        end)
    end
    local warnsCmd = ulx.command(CATEGORY, "ulx warns", ulx.warns, "!warns")
    warnsCmd:addParam{ type = ULib.cmds.PlayerArg, ULib.cmds.optional }
    warnsCmd:defaultAccess(ULib.ACCESS_ALL)
    warnsCmd:help("Listet Verwarnungen (eigene ohne Argument).")

    -- ============================================================
    --  ulx warnmenu
    -- ============================================================
    function ulx.warnmenu(calling_ply)
        if not WarnSys.Util.HasPermission(calling_ply, "openMenu") then
            WarnSys.Util.Notify(calling_ply, WarnSys.L("no_perm"), 1)
            return
        end
        -- Admin-Tab nur, wenn erlaubt; sonst auf eigene Warns leiten.
        local tab = WarnSys.Util.CanSeePanel(calling_ply, "admin")
            and "admin" or "mywarns"
        net.Start("WarnSys.OpenMenu")
            net.WriteString(tab)
        net.Send(calling_ply)
    end
    local menuCmd = ulx.command(CATEGORY, "ulx warnmenu", ulx.warnmenu, "!warnmenu")
    menuCmd:defaultAccess(ULib.ACCESS_ADMIN)
    menuCmd:help("Öffnet das WarnSys-Admin-Menü.")

    print("[WarnSys] ULX-Befehle registriert.")
    return true
end

-- ULX lädt asynchron – mehrfach versuchen
hook.Add("Initialize", "WarnSys.RegisterULX", function()
    timer.Simple(2, function()
        if not register() then
            timer.Simple(5, register)
        end
    end)
end)
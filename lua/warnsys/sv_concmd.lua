-- WarnSys :: Chat-Befehle (Fallback, wenn ULX nicht installiert ist)

hook.Add("PlayerSay", "WarnSys.ChatCmds", function(ply, text)
    local lower = string.lower(text)

    -- !warns / !warnmenu / !mywarns  ->  Menü öffnen (für alle Spieler)
    if lower == "!warns" or lower == "/warns"
        or lower == "!warnmenu" or lower == "/warnmenu"
        or lower == "!mywarns" or lower == "/mywarns" then
        net.Start("WarnSys.OpenMenu")
            net.WriteString(lower:find("mywarns") and "mywarns" or "dashboard")
        net.Send(ply)
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

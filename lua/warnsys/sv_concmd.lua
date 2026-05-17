-- WarnSys :: Chat-Befehle (Fallback, wenn ULX nicht installiert ist)

hook.Add("PlayerSay", "WarnSys.ChatCmds", function(ply, text)
    local lower = string.lower(text)

    -- !warns – eigene oder eines Ziels
    if lower:sub(1, 6) == "!warns" then
        local arg = string.Trim(lower:sub(7))
        if arg == "" then
            WarnSys.DB.GetByPlayer(ply:SteamID(), true, function(rows)
                rows = rows or {}
                local active = 0
                for _, r in ipairs(rows) do
                    if tonumber(r.active) == 1 then active = active + 1 end
                end
                ply:ChatPrint(WarnSys.L("warnlist_header", ply:Nick(), active))
                if #rows == 0 then
                    ply:ChatPrint(WarnSys.L("warnlist_empty"))
                else
                    for _, r in ipairs(rows) do
                        local tag = tonumber(r.active) == 1 and "" or WarnSys.L("expired_tag")
                        ply:ChatPrint(WarnSys.L("warnlist_line",
                            tonumber(r.id), r.reason or "?", r.admin_nick or "?",
                            WarnSys.Util.FormatTime(tonumber(r.created)), tag))
                    end
                end
            end)
            return ""
        end
    end

    -- !warnmenu
    if lower == "!warnmenu" or lower == "/warnmenu" then
        if WarnSys.Util.HasPermission(ply, "openMenu") then
            net.Start("WarnSys.OpenMenu") net.Send(ply)
        else
            WarnSys.Util.Notify(ply, WarnSys.L("no_perm"), 1)
        end
        return ""
    end

    -- !warnhelp
    if lower == "!warnhelp" then
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

        -- Ziel über Nick suchen (Teilstring, wie ULX)
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
end)

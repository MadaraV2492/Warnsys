-- WarnSys :: Kern-Logik für Verwarnungen

WarnSys.Core = {}
local Core = WarnSys.Core
local cooldowns = {}

-- ============================================================
--  Auto-Bestrafung
-- ============================================================
local function applyAutoPunish(target, count)
    local rule
    -- höchste Stufe, die <= count ist
    local highest = -1
    for threshold, def in pairs(WarnSys.Config.AutoPunish) do
        if count >= threshold and threshold > highest then
            highest = threshold
            rule = def
        end
    end
    if not rule or rule.type == "none" then return end

    local steamid = target:SteamID()
    local nick    = target:Nick()
    local reason  = rule.reason or "Auto-Bestrafung"

    WarnSys.Logs.Write(string.format(
        "AutoPunish [%s] %s -> %s (%d Warns)",
        rule.type, nick, steamid, count
    ))
    WarnSys.Logs.DiscordAutoPunish({
        nick = nick, steamid = steamid,
        action = rule.type .. (rule.time and (" " .. rule.time .. "min") or ""),
        count = count, reason = reason,
    })

    if rule.type == "kick" then
        target:Kick(reason)
    elseif rule.type == "tempban" then
        -- ULX-tempban bevorzugt
        if ULib and ULib.kickban then
            ULib.kickban(target, rule.time or 60, reason, nil)
        else
            game.ConsoleCommand(string.format('banid %d %s "%s"\n',
                rule.time or 60, steamid, reason))
            target:Kick(reason)
        end
    elseif rule.type == "ban" then
        if ULib and ULib.kickban then
            ULib.kickban(target, 0, reason, nil) -- 0 = permanent
        else
            game.ConsoleCommand(string.format('banid 0 %s "%s"\n', steamid, reason))
            target:Kick(reason)
        end
    end
end

-- ============================================================
--  Warn ausführen
-- ============================================================
-- admin: Player oder nil (= Konsole)
-- target: Player
-- reason: string
-- silent: bool – kein Broadcast
function Core.Warn(admin, target, reason, silent)
    -- Berechtigungen
    if IsValid(admin) and not WarnSys.Util.HasPermission(admin, "warn") then
        WarnSys.Util.Notify(admin, WarnSys.L("no_perm"), 1)
        return false
    end

    local can, why = WarnSys.Util.CanWarnTarget(admin, target)
    if not can then
        WarnSys.Util.Notify(admin, WarnSys.L(why), 1)
        return false
    end

    -- Grund prüfen
    local ok, clean = WarnSys.Util.ValidReason(reason)
    if not ok then
        WarnSys.Util.Notify(admin, WarnSys.L("invalid_reason",
            WarnSys.Config.MinReasonLength, WarnSys.Config.MaxReasonLength), 1)
        return false
    end

    -- Cooldown
    if IsValid(admin) and WarnSys.Config.WarnCooldown > 0 then
        local last = cooldowns[admin:SteamID()] or 0
        local remain = (last + WarnSys.Config.WarnCooldown) - CurTime()
        if remain > 0 then
            WarnSys.Util.Notify(admin, WarnSys.L("cooldown", math.ceil(remain)), 1)
            return false
        end
        cooldowns[admin:SteamID()] = CurTime()
    end

    local now = os.time()
    local data = {
        steamid       = target:SteamID(),
        nick          = target:Nick(),
        admin_steamid = IsValid(admin) and admin:SteamID() or "CONSOLE",
        admin_nick    = IsValid(admin) and admin:Nick()   or "Konsole",
        reason        = clean,
        created       = now,
    }

    WarnSys.DB.Insert(data, function(id, err)
        if err or not id then
            WarnSys.Util.Notify(admin, "DB-Fehler beim Speichern.", 1)
            return
        end
        data.id = id

        WarnSys.DB.CountActive(data.steamid, function(count)
            data.activeCount = count

            -- Hook für Drittanbieter
            hook.Run("WarnSys.PlayerWarned", target, admin, data)

            -- Logs
            WarnSys.Logs.Write(string.format(
                "WARN #%d %s (%s) <- %s | Grund: %s | Aktive: %d",
                id, data.nick, data.steamid, data.admin_nick, clean, count
            ))
            WarnSys.Logs.DiscordWarn(data)

            -- Benachrichtigungen
            WarnSys.Util.Notify(target,
                WarnSys.L("warn_received", clean, data.admin_nick, count), 1)
            if target.EmitSound and WarnSys.Config.NotifySound ~= "" then
                target:SendLua(string.format(
                    'surface.PlaySound(%q)', WarnSys.Config.NotifySound))
            end

            if IsValid(admin) then
                WarnSys.Util.Notify(admin,
                    WarnSys.L("warn_success", data.nick, clean), 0)
            else
                print(string.format("[WarnSys] %s verwarnt (%s).", data.nick, clean))
            end

            -- Andere Admins informieren
            if WarnSys.Config.NotifyAllAdmins then
                for _, p in ipairs(player.GetAll()) do
                    if p ~= admin and p ~= target and WarnSys.Util.HasPermission(p, "viewWarns") then
                        WarnSys.Util.Notify(p, string.format("%s -> %s | %s",
                            data.admin_nick, data.nick, clean), 0)
                    end
                end
            end

            if WarnSys.Config.BroadcastWarn and not silent then
                for _, p in ipairs(player.GetAll()) do
                    WarnSys.Util.Notify(p,
                        WarnSys.L("broadcast_warn", data.nick, data.admin_nick, clean), 1)
                end
            end

            applyAutoPunish(target, count)
        end)
    end)

    return true
end

-- ============================================================
--  Unwarn
-- ============================================================
function Core.Unwarn(admin, warnID)
    if IsValid(admin) and not WarnSys.Util.HasPermission(admin, "unwarn") then
        WarnSys.Util.Notify(admin, WarnSys.L("no_perm"), 1)
        return false
    end
    warnID = tonumber(warnID)
    if not warnID then return false end

    WarnSys.DB.GetByID(warnID, function(row)
        if not row then
            WarnSys.Util.Notify(admin, WarnSys.L("unwarn_notfound"), 1)
            return
        end
        WarnSys.DB.Remove(warnID, function()
            WarnSys.Util.Notify(admin, WarnSys.L("unwarn_success", warnID), 0)
            WarnSys.Logs.Write(string.format(
                "UNWARN #%d %s (%s) durch %s",
                warnID, row.nick or "?", row.steamid or "?",
                IsValid(admin) and admin:Nick() or "Konsole"
            ))
            WarnSys.Logs.DiscordUnwarn({
                id = warnID,
                nick = row.nick, steamid = row.steamid,
                admin_nick = IsValid(admin) and admin:Nick() or "Konsole",
            })
            hook.Run("WarnSys.PlayerUnwarned", row, admin)
        end)
    end)
    return true
end

-- ============================================================
--  Clear all (für einen Spieler)
-- ============================================================
function Core.ClearWarns(admin, target)
    if IsValid(admin) and not WarnSys.Util.HasPermission(admin, "clearwarns") then
        WarnSys.Util.Notify(admin, WarnSys.L("no_perm"), 1)
        return false
    end
    if not IsValid(target) then return false end
    local sid, nick = target:SteamID(), target:Nick()
    WarnSys.DB.ClearByPlayer(sid, function()
        WarnSys.Util.Notify(admin, WarnSys.L("clearwarns_ok", nick), 0)
        WarnSys.Logs.Write(string.format(
            "CLEAR %s (%s) durch %s", nick, sid,
            IsValid(admin) and admin:Nick() or "Konsole"
        ))
        hook.Run("WarnSys.PlayerCleared", target, admin)
    end)
    return true
end

-- ============================================================
--  ConVar-Befehl für Konsole/RCON
-- ============================================================
concommand.Add("warnsys_warn", function(ply, _, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    local sid    = args[1]
    local reason = table.concat(args, " ", 2)
    if not sid or sid == "" then
        print("Verwendung: warnsys_warn <steamid> <grund>")
        return
    end
    local target = player.GetBySteamID(sid)
    if not IsValid(target) then
        print("Spieler nicht online.")
        return
    end
    Core.Warn(ply, target, reason)
end)

-- WarnSys :: Net-Messages (Server-Seite)

util.AddNetworkString("WarnSys.Notify")
util.AddNetworkString("WarnSys.OpenMenu")
util.AddNetworkString("WarnSys.RequestWarns")
util.AddNetworkString("WarnSys.SendWarns")
util.AddNetworkString("WarnSys.DoWarn")
util.AddNetworkString("WarnSys.DoUnwarn")
util.AddNetworkString("WarnSys.DoClear")
util.AddNetworkString("WarnSys.UpdateCount")

-- ============================================================
--  Hilfsfunktion: Warn-Liste senden
-- ============================================================
local function sendWarns(requester, targetSteamID, includeExpired)
    WarnSys.DB.GetByPlayer(targetSteamID, includeExpired, function(rows)
        rows = rows or {}
        net.Start("WarnSys.SendWarns")
            net.WriteString(targetSteamID)
            net.WriteBool(includeExpired)
            net.WriteUInt(#rows, 16)
            for _, r in ipairs(rows) do
                net.WriteUInt(tonumber(r.id) or 0, 32)
                net.WriteString(r.nick or "")
                net.WriteString(r.admin_nick or "")
                net.WriteString(r.admin_steamid or "")
                net.WriteString(r.reason or "")
                net.WriteUInt(tonumber(r.created) or 0, 32)
                net.WriteUInt(tonumber(r.expires) or 0, 32)
                net.WriteBool(tonumber(r.active) == 1)
            end
        net.Send(requester)
    end)
end

-- ============================================================
--  Receiver: Anfrage einer Warn-Liste
-- ============================================================
net.Receive("WarnSys.RequestWarns", function(_, ply)
    if not IsValid(ply) then return end
    local sid = net.ReadString()
    local includeExpired = net.ReadBool()

    -- Validierung des SteamID-Strings (Anti-Spoofing / Abuse)
    if not isstring(sid) or #sid > 32 then return end

    -- Spieler darf immer seine eigene Liste sehen
    if sid ~= ply:SteamID() and not WarnSys.Util.HasPermission(ply, "viewWarns") then
        WarnSys.Util.Notify(ply, WarnSys.L("no_perm"), 1)
        return
    end
    sendWarns(ply, sid, includeExpired)
end)

-- ============================================================
--  Receiver: Warn ausführen
-- ============================================================
net.Receive("WarnSys.DoWarn", function(_, ply)
    if not WarnSys.Util.HasPermission(ply, "warn") then
        WarnSys.Util.Notify(ply, WarnSys.L("no_perm"), 1)
        return
    end
    local target = net.ReadEntity()
    local reason = net.ReadString()
    if not IsValid(target) or not target:IsPlayer() then
        WarnSys.Util.Notify(ply, WarnSys.L("invalid_target"), 1)
        return
    end
    WarnSys.Core.Warn(ply, target, reason)
end)

-- ============================================================
--  Receiver: Unwarn
-- ============================================================
net.Receive("WarnSys.DoUnwarn", function(_, ply)
    if not WarnSys.Util.HasPermission(ply, "unwarn") then
        WarnSys.Util.Notify(ply, WarnSys.L("no_perm"), 1)
        return
    end
    local id = net.ReadUInt(32)
    WarnSys.Core.Unwarn(ply, id)
end)

-- ============================================================
--  Receiver: Clear
-- ============================================================
net.Receive("WarnSys.DoClear", function(_, ply)
    if not WarnSys.Util.HasPermission(ply, "clearwarns") then
        WarnSys.Util.Notify(ply, WarnSys.L("no_perm"), 1)
        return
    end
    local target = net.ReadEntity()
    if not IsValid(target) or not target:IsPlayer() then return end
    WarnSys.Core.ClearWarns(ply, target)
end)

-- ============================================================
--  Server -> Client: Aktive Warn-Anzahl beim Join updaten
-- ============================================================
local function broadcastCount(target)
    if not IsValid(target) then return end
    WarnSys.DB.CountActive(target:SteamID(), function(c)
        if not IsValid(target) then return end
        net.Start("WarnSys.UpdateCount")
            net.WriteUInt(c, 8)
        net.Send(target)
    end)
end

hook.Add("PlayerInitialSpawn", "WarnSys.SendCount", function(ply)
    timer.Simple(3, function()
        if IsValid(ply) then broadcastCount(ply) end
    end)
end)

hook.Add("WarnSys.PlayerWarned", "WarnSys.UpdateOnWarn", function(ply)
    timer.Simple(0.2, function() broadcastCount(ply) end)
end)

hook.Add("WarnSys.PlayerUnwarned", "WarnSys.UpdateOnUnwarn", function(row)
    local ply = player.GetBySteamID(row.steamid)
    if IsValid(ply) then timer.Simple(0.2, function() broadcastCount(ply) end) end
end)

hook.Add("WarnSys.PlayerCleared", "WarnSys.UpdateOnClear", function(target)
    if IsValid(target) then broadcastCount(target) end
end)
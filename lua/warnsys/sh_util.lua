-- WarnSys :: Hilfsfunktionen (shared)

WarnSys.Util = {}

function WarnSys.Util.HasPermission(ply, action)
    if not IsValid(ply) then return true end -- Konsole
    if ply:IsSuperAdmin() then return true end

    local groups = WarnSys.Config.Permissions[action]
    if not groups then return false end

    local plyGroup = ply:GetUserGroup()
    for _, g in ipairs(groups) do
        if g == "*" or g == plyGroup then return true end
    end
    return false
end

-- Welche Panel-Tabs darf der Spieler im Menü sehen?
function WarnSys.Util.CanSeePanel(ply, tab)
    if not IsValid(ply) then return true end
    if ply:IsSuperAdmin() then return true end

    local cfg = WarnSys.Config.PanelTabs
    local groups = cfg and cfg[tab]
    if not groups then return false end

    local plyGroup = ply:GetUserGroup()
    for _, g in ipairs(groups) do
        if g == "*" or g == plyGroup then return true end
    end
    return false
end

-- Rang-Hierarchie über ULib (falls vorhanden), sonst feste Reihenfolge
local fallbackRanks = {
    user        = 0,
    vip         = 5,
    operator    = 10,
    moderator   = 15,
    admin       = 20,
    superadmin  = 100,
}

function WarnSys.Util.GetRankPower(ply)
    if not IsValid(ply) then return math.huge end
    local g = ply:GetUserGroup()
    if ULib and ULib.ucl and ULib.ucl.groups and ULib.ucl.groups[g] then
        -- ULib hat keine "power"-Zahl, also über Vererbungs-Tiefe abschätzen
        local depth, cur = 0, g
        while cur and ULib.ucl.groups[cur] and ULib.ucl.groups[cur].inherit_from do
            depth = depth + 1
            cur = ULib.ucl.groups[cur].inherit_from
            if depth > 32 then break end
        end
        return depth + (fallbackRanks[g] or 0)
    end
    return fallbackRanks[g] or 0
end

function WarnSys.Util.CanWarnTarget(admin, target)
    if not IsValid(target) then return false, "invalid_target" end
    if IsValid(admin) and admin == target and not WarnSys.Config.AllowSelfWarn then
        return false, "self_warn"
    end
    if not WarnSys.Config.AllowWarnHigherRank and IsValid(admin) then
        if WarnSys.Util.GetRankPower(target) > WarnSys.Util.GetRankPower(admin) then
            return false, "higher_rank"
        end
    end
    return true
end

function WarnSys.Util.CleanReason(reason)
    if not isstring(reason) then return "" end
    reason = string.Trim(reason)
    reason = reason:gsub("[%c]", " ") -- Steuerzeichen entfernen
    if #reason > WarnSys.Config.MaxReasonLength then
        reason = reason:sub(1, WarnSys.Config.MaxReasonLength)
    end
    return reason
end

function WarnSys.Util.ValidReason(reason)
    reason = WarnSys.Util.CleanReason(reason)
    local len = #reason
    return len >= WarnSys.Config.MinReasonLength
        and len <= WarnSys.Config.MaxReasonLength, reason
end

function WarnSys.Util.FormatTime(unix)
    return os.date("%d.%m.%Y %H:%M", unix or 0)
end

function WarnSys.Util.Notify(ply, msg, typ)
    typ = typ or 1
    if SERVER then
        if not IsValid(ply) then
            print(WarnSys.Config.Prefix .. " " .. msg)
            return
        end
        net.Start("WarnSys.Notify")
            net.WriteString(msg)
            net.WriteUInt(typ, 4)
        net.Send(ply)
    else
        if WarnSys.Config.UseDarkRP and DarkRP and DarkRP.notify then
            DarkRP.notify(ply or LocalPlayer(), typ, WarnSys.Config.NotifyDuration, msg)
        else
            notification.AddLegacy(msg, typ, WarnSys.Config.NotifyDuration)
            surface.PlaySound("buttons/button14.wav")
        end
    end
end

function WarnSys.Util.Debug(...)
    if WarnSys.Config.Debug then
        print("[WarnSys/Debug]", ...)
    end
end

-- WarnSys :: Runtime-Einstellungen (Ingame-Editor für SuperAdmins)
--
-- Lädt Overrides aus data/warnsys_runtime.json beim Server-Start.
-- Speichert Änderungen, die im Ingame-Menü gemacht werden.

WarnSys.Settings = {}
local S = WarnSys.Settings
local RUNTIME_FILE = "warnsys_runtime.json"

-- Welche Keys werden überhaupt persistiert? (Whitelist, kein blindes Merge)
local PERSISTED = {
    "Language", "MinReasonLength", "MaxReasonLength", "WarnCooldown",
    "ExpireDays", "KeepHistory", "AllowSelfWarn", "AllowWarnHigherRank",
    "NotifyAllAdmins", "BroadcastWarn", "AutoPunish",
    "Storage", "MySQL", "Discord", "PresetReasons",
    "Permissions", "PanelTabs",
}

-- ============================================================
--  Laden
-- ============================================================
function S.Load()
    if not file.Exists(RUNTIME_FILE, "DATA") then return end
    local raw  = file.Read(RUNTIME_FILE, "DATA") or ""
    local data = util.JSONToTable(raw)
    if not istable(data) then
        ErrorNoHalt("[WarnSys] runtime.json beschädigt – ignoriert.\n")
        return
    end
    for _, key in ipairs(PERSISTED) do
        if data[key] ~= nil then
            WarnSys.Config[key] = data[key]
        end
    end
    print("[WarnSys] Runtime-Einstellungen geladen.")
end

-- ============================================================
--  Speichern
-- ============================================================
function S.Save()
    local snap = {}
    for _, key in ipairs(PERSISTED) do
        snap[key] = WarnSys.Config[key]
    end
    file.Write(RUNTIME_FILE, util.TableToJSON(snap, true))
end

-- ============================================================
--  Snapshot für den Client (sicher: Passwort ausgeblendet)
-- ============================================================
local function snapshot(forAdmin)
    local mysql = table.Copy(WarnSys.Config.MySQL)
    if not forAdmin then mysql.pass = "" end
    return {
        Language            = WarnSys.Config.Language,
        MinReasonLength     = WarnSys.Config.MinReasonLength,
        MaxReasonLength     = WarnSys.Config.MaxReasonLength,
        WarnCooldown        = WarnSys.Config.WarnCooldown,
        ExpireDays          = WarnSys.Config.ExpireDays,
        KeepHistory         = WarnSys.Config.KeepHistory,
        AllowSelfWarn       = WarnSys.Config.AllowSelfWarn,
        AllowWarnHigherRank = WarnSys.Config.AllowWarnHigherRank,
        NotifyAllAdmins     = WarnSys.Config.NotifyAllAdmins,
        BroadcastWarn       = WarnSys.Config.BroadcastWarn,
        AutoPunish          = WarnSys.Config.AutoPunish,
        PresetReasons       = WarnSys.Config.PresetReasons,
        Storage             = WarnSys.Config.Storage,
        MySQL               = mysql,
        Discord = {
            enabled  = WarnSys.Config.Discord.enabled,
            webhook  = forAdmin and WarnSys.Config.Discord.webhook or "",
            username = WarnSys.Config.Discord.username,
        },
    }
end

-- ============================================================
--  Validierung (server-seitig, niemals nur dem Client trauen)
-- ============================================================
local TYPES = { kick = true, tempban = true, ban = true, none = true }

local function clampNum(v, min, max, fallback)
    v = tonumber(v)
    if not v then return fallback end
    return math.Clamp(v, min, max)
end

local function sanitize(data)
    if not istable(data) then return nil, "invalid root" end
    local out = {}

    out.Language            = (data.Language == "en") and "en" or "de"
    out.MinReasonLength     = clampNum(data.MinReasonLength, 1, 50, 3)
    out.MaxReasonLength     = clampNum(data.MaxReasonLength, out.MinReasonLength, 500, 200)
    out.WarnCooldown        = clampNum(data.WarnCooldown, 0, 60, 2)
    out.ExpireDays          = clampNum(data.ExpireDays, 0, 3650, 30)
    out.KeepHistory         = data.KeepHistory ~= false
    out.AllowSelfWarn       = data.AllowSelfWarn == true
    out.AllowWarnHigherRank = data.AllowWarnHigherRank == true
    out.NotifyAllAdmins     = data.NotifyAllAdmins ~= false
    out.BroadcastWarn       = data.BroadcastWarn == true
    out.Storage             = (data.Storage == "mysql") and "mysql" or "sqlite"

    -- AutoPunish
    out.AutoPunish = {}
    if istable(data.AutoPunish) then
        for k, v in pairs(data.AutoPunish) do
            local n = tonumber(k)
            if n and n > 0 and n < 1000 and istable(v) and TYPES[v.type] then
                out.AutoPunish[n] = {
                    type   = v.type,
                    time   = clampNum(v.time, 1, 525600, 60),
                    reason = tostring(v.reason or ""):sub(1, 200),
                }
                if v.type ~= "tempban" then out.AutoPunish[n].time = nil end
            end
        end
    end

    -- MySQL
    local m = istable(data.MySQL) and data.MySQL or {}
    out.MySQL = {
        host     = tostring(m.host or "127.0.0.1"):sub(1, 128),
        port     = clampNum(m.port, 1, 65535, 3306),
        user     = tostring(m.user or ""):sub(1, 64),
        pass     = tostring(m.pass or ""):sub(1, 128),
        database = tostring(m.database or ""):sub(1, 64),
    }

    -- Discord
    local d = istable(data.Discord) and data.Discord or {}
    out.Discord = {
        enabled  = d.enabled == true,
        webhook  = tostring(d.webhook or ""):sub(1, 512),
        username = tostring(d.username or "WarnSys"):sub(1, 64),
        avatar   = WarnSys.Config.Discord.avatar,
        color    = WarnSys.Config.Discord.color,
    }

    -- PresetReasons (falls geschickt)
    if istable(data.PresetReasons) then
        out.PresetReasons = {}
        for _, r in ipairs(data.PresetReasons) do
            if isstring(r) and #r > 0 then
                table.insert(out.PresetReasons, r:sub(1, 100))
                if #out.PresetReasons >= 30 then break end
            end
        end
    end

    return out
end

-- ============================================================
--  Apply (Config überschreiben + Nebenwirkungen)
-- ============================================================
function S.Apply(sanitized, adminNick)
    local prevStorage = WarnSys.Config.Storage
    local prevMySQL   = util.TableToJSON(WarnSys.Config.MySQL)

    for k, v in pairs(sanitized) do
        WarnSys.Config[k] = v
    end
    if not sanitized.PresetReasons then
        -- Defaults beibehalten, falls Client das Feld weggelassen hat
    end

    S.Save()

    -- Sprache live an alle Clients schicken
    net.Start("WarnSys.SyncLanguage")
        net.WriteString(WarnSys.Config.Language)
    net.Broadcast()

    -- MySQL: Reconnect, falls geändert
    local newMySQL = util.TableToJSON(WarnSys.Config.MySQL)
    if WarnSys.Config.Storage ~= prevStorage or newMySQL ~= prevMySQL then
        if WarnSys.DB and WarnSys.DB.Reconnect then
            WarnSys.DB.Reconnect()
        end
    end

    WarnSys.Logs.Write(string.format("Settings aktualisiert von %s",
        adminNick or "Konsole"))
    print("[WarnSys] Einstellungen geändert von " .. (adminNick or "Konsole"))
end

-- ============================================================
--  Boot
-- ============================================================
hook.Add("Initialize", "WarnSys.Settings.Load", function()
    S.Load()
end)

-- ============================================================
--  Net-Handler
-- ============================================================
util.AddNetworkString("WarnSys.RequestConfig")
util.AddNetworkString("WarnSys.SendConfig")
util.AddNetworkString("WarnSys.SaveConfig")
util.AddNetworkString("WarnSys.SyncLanguage")
util.AddNetworkString("WarnSys.MySQLTest")
util.AddNetworkString("WarnSys.MySQLTestResult")

net.Receive("WarnSys.RequestConfig", function(_, ply)
    if not WarnSys.Util.HasPermission(ply, "editConfig") then
        WarnSys.Util.Notify(ply, WarnSys.L("no_perm"), 1)
        return
    end
    local snap = snapshot(true)
    net.Start("WarnSys.SendConfig")
        net.WriteString(util.TableToJSON(snap))
    net.Send(ply)
end)

net.Receive("WarnSys.SaveConfig", function(_, ply)
    if not WarnSys.Util.HasPermission(ply, "editConfig") then
        WarnSys.Util.Notify(ply, WarnSys.L("no_perm"), 1) return
    end
    local raw  = net.ReadString()
    local data = util.JSONToTable(raw or "")
    local clean, err = sanitize(data)
    if not clean then
        WarnSys.Util.Notify(ply, "Ungültige Daten: " .. tostring(err), 1) return
    end
    S.Apply(clean, ply:Nick())
    WarnSys.Util.Notify(ply, "Einstellungen gespeichert.", 0)
end)

-- MySQL Test-Connection (ohne Speichern)
net.Receive("WarnSys.MySQLTest", function(_, ply)
    if not WarnSys.Util.HasPermission(ply, "editConfig") then
        WarnSys.Util.Notify(ply, WarnSys.L("no_perm"), 1)
        return
    end
    local raw  = net.ReadString()
    local data = util.JSONToTable(raw or "")
    if not istable(data) then return end

    local ok, mysqloo = pcall(require, "mysqloo")
    if not ok or not mysqloo then
        net.Start("WarnSys.MySQLTestResult")
            net.WriteBool(false)
            net.WriteString("MySQLOO ist nicht installiert.")
        net.Send(ply) return
    end

    local db = mysqloo.connect(
        tostring(data.host or ""), tostring(data.user or ""),
        tostring(data.pass or ""), tostring(data.database or ""),
        tonumber(data.port) or 3306)

    function db:onConnected()
        net.Start("WarnSys.MySQLTestResult")
            net.WriteBool(true)
            net.WriteString("Verbindung erfolgreich.")
        net.Send(ply)
        self:disconnect(true)
    end
    function db:onConnectionFailed(err)
        net.Start("WarnSys.MySQLTestResult")
            net.WriteBool(false)
            net.WriteString(tostring(err))
        net.Send(ply)
    end
    db:connect()
end)

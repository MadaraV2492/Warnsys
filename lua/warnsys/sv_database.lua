-- WarnSys :: Datenbank (SQLite + optional MySQLOO)

WarnSys.DB = {}
local DB = WarnSys.DB

local mysql -- aktuelle MySQL-Verbindung
local function isMySQL() return WarnSys.Config.Storage == "mysql" and mysql end

-- ============================================================
--  MySQL-Connect / Reconnect
-- ============================================================
function DB.Connect()
    if WarnSys.Config.Storage ~= "mysql" then return end
    local ok, mysqloo = pcall(require, "mysqloo")
    if not ok or not mysqloo then
        ErrorNoHalt("[WarnSys] MySQLOO nicht installiert – nutze SQLite.\n")
        WarnSys.Config.Storage = "sqlite"
        return
    end
    local c = WarnSys.Config.MySQL
    if not c or c.host == "" or c.database == "" then
        ErrorNoHalt("[WarnSys] MySQL-Konfiguration unvollständig.\n")
        return
    end
    mysql = mysqloo.connect(c.host, c.user, c.pass, c.database, c.port)
    function mysql:onConnected()
        print("[WarnSys] MySQL verbunden (" .. c.host .. "/" .. c.database .. ").")
        DB.Init()
    end
    function mysql:onConnectionFailed(err)
        ErrorNoHalt("[WarnSys] MySQL fehlgeschlagen: " .. err .. " – Fallback SQLite.\n")
        mysql = nil
        WarnSys.Config.Storage = "sqlite"
    end
    mysql:connect()
end

function DB.Reconnect()
    if mysql then
        pcall(function() mysql:disconnect(true) end)
        mysql = nil
    end
    if WarnSys.Config.Storage == "mysql" then
        DB.Connect()
    else
        DB.Init() -- SQLite hat sowieso eine "Verbindung"
    end
end

-- ============================================================
--  Internals
-- ============================================================
local function escape(s)
    if isMySQL() then return mysql:escape(tostring(s)) end
    return sql.SQLStr(tostring(s), true)
end

local function query(q, cb)
    WarnSys.Util.Debug("SQL:", q)
    if isMySQL() then
        local r = mysql:query(q)
        function r:onSuccess(data) if cb then cb(data) end end
        function r:onError(err)
            ErrorNoHalt("[WarnSys] SQL-Fehler: " .. err .. "\nQuery: " .. q .. "\n")
            if cb then cb(nil, err) end
        end
        r:start()
    else
        local data = sql.Query(q)
        if data == false then
            ErrorNoHalt("[WarnSys] SQL-Fehler: " .. sql.LastError() .. "\nQuery: " .. q .. "\n")
            if cb then cb(nil, sql.LastError()) end
        else
            if cb then cb(data or {}) end
        end
    end
end
DB.Query = query

-- ============================================================
--  Schema
-- ============================================================
function DB.Init()
    local mySQL = isMySQL()
    local autoInc = mySQL and "AUTO_INCREMENT" or "AUTOINCREMENT"
    local intType = mySQL and "INT" or "INTEGER"

    query(([[
        CREATE TABLE IF NOT EXISTS warnsys_warns (
            id %s PRIMARY KEY %s,
            steamid VARCHAR(32) NOT NULL,
            nick    VARCHAR(64),
            admin_steamid VARCHAR(32),
            admin_nick    VARCHAR(64),
            reason  TEXT,
            created %s NOT NULL,
            expires %s DEFAULT 0,
            active  %s DEFAULT 1
        );
    ]]):format(intType, autoInc, intType, intType, intType))

    query("CREATE INDEX IF NOT EXISTS idx_warnsys_steamid ON warnsys_warns(steamid);")
    query("CREATE INDEX IF NOT EXISTS idx_warnsys_active  ON warnsys_warns(active);")
end

hook.Add("Initialize", "WarnSys.DB.Init", function()
    if WarnSys.Config.Storage == "mysql" then
        DB.Connect() -- onConnected ruft DB.Init()
    else
        DB.Init()
    end
end)

-- ============================================================
--  CRUD
-- ============================================================
function DB.Insert(data, cb)
    local expires = 0
    if WarnSys.Config.ExpireDays > 0 then
        expires = data.created + (WarnSys.Config.ExpireDays * 86400)
    end
    local q = string.format([[
        INSERT INTO warnsys_warns
        (steamid, nick, admin_steamid, admin_nick, reason, created, expires, active)
        VALUES ('%s','%s','%s','%s','%s',%d,%d,1);
    ]],
        escape(data.steamid),
        escape(data.nick or ""),
        escape(data.admin_steamid or "CONSOLE"),
        escape(data.admin_nick or "Konsole"),
        escape(data.reason or ""),
        data.created,
        expires
    )
    query(q, function(_, err)
        if err then if cb then cb(nil, err) end return end
        if isMySQL() then
            query("SELECT LAST_INSERT_ID() AS id;", function(r)
                if cb then cb(r and r[1] and tonumber(r[1].id)) end
            end)
        else
            local r = sql.QueryRow("SELECT last_insert_rowid() AS id;")
            if cb then cb(r and tonumber(r.id)) end
        end
    end)
end

function DB.Remove(id, cb)
    query("DELETE FROM warnsys_warns WHERE id = " .. tonumber(id) .. ";", cb)
end

function DB.ClearByPlayer(steamid, cb)
    query("DELETE FROM warnsys_warns WHERE steamid = '" .. escape(steamid) .. "';", cb)
end

function DB.GetByPlayer(steamid, includeExpired, cb)
    local where = "steamid = '" .. escape(steamid) .. "'"
    if not includeExpired then where = where .. " AND active = 1" end
    query("SELECT * FROM warnsys_warns WHERE " .. where .. " ORDER BY created DESC;", cb)
end

function DB.CountActive(steamid, cb)
    query(string.format(
        "SELECT COUNT(*) AS c FROM warnsys_warns WHERE steamid='%s' AND active=1;",
        escape(steamid)
    ), function(r)
        local n = 0
        if r and r[1] then n = tonumber(r[1].c) or tonumber(r[1].C) or 0 end
        if cb then cb(n) end
    end)
end

function DB.GetByID(id, cb)
    query("SELECT * FROM warnsys_warns WHERE id = " .. tonumber(id) .. " LIMIT 1;", function(r)
        if cb then cb(r and r[1]) end
    end)
end

function DB.ExpireOld()
    if WarnSys.Config.ExpireDays <= 0 then return end
    local now = os.time()
    if WarnSys.Config.KeepHistory then
        query("UPDATE warnsys_warns SET active = 0 WHERE active = 1 AND expires > 0 AND expires <= " .. now .. ";")
    else
        query("DELETE FROM warnsys_warns WHERE expires > 0 AND expires <= " .. now .. ";")
    end
end

timer.Create("WarnSys.Expire", 300, 0, function() DB.ExpireOld() end)
hook.Add("InitPostEntity", "WarnSys.ExpireBoot", function() DB.ExpireOld() end)

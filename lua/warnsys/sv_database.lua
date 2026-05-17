-- WarnSys :: Datenbank (SQLite + optional MySQLOO)

WarnSys.DB = {}
local DB = WarnSys.DB

local function isMySQL() return WarnSys.Config.Storage == "mysql" end

-- ============================================================
--  MySQL-Wrapper (lazy, nur wenn MySQLOO geladen)
-- ============================================================
local mysql
if isMySQL() then
    if not pcall(require, "mysqloo") then
        ErrorNoHalt("[WarnSys] MySQLOO konnte nicht geladen werden – fallback auf SQLite.\n")
        WarnSys.Config.Storage = "sqlite"
    else
        local c = WarnSys.Config.MySQL
        mysql = mysqloo.connect(c.host, c.user, c.pass, c.database, c.port)
        function mysql:onConnected() print("[WarnSys] MySQL verbunden.") end
        function mysql:onConnectionFailed(err)
            ErrorNoHalt("[WarnSys] MySQL-Verbindung fehlgeschlagen: " .. err .. "\n")
            WarnSys.Config.Storage = "sqlite"
        end
        mysql:connect()
    end
end

local function escape(s)
    if isMySQL() and mysql then return mysql:escape(tostring(s)) end
    return sql.SQLStr(tostring(s), true)
end

local function query(q, cb)
    WarnSys.Util.Debug("SQL:", q)
    if isMySQL() and mysql then
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
    local autoInc = isMySQL() and "AUTO_INCREMENT" or "AUTOINCREMENT"
    local intType = isMySQL() and "INT" or "INTEGER"

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
hook.Add("Initialize", "WarnSys.DB.Init", function() DB.Init() end)

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
        -- letzte ID holen
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

-- Periodisch ablaufen lassen
timer.Create("WarnSys.Expire", 300, 0, function() DB.ExpireOld() end)
hook.Add("InitPostEntity", "WarnSys.ExpireBoot", function() DB.ExpireOld() end)

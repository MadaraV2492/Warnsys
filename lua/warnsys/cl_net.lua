-- WarnSys :: Client-Net-Receiver

WarnSys.Client = WarnSys.Client or {}
WarnSys.Client.ActiveWarns = 0
WarnSys.Client.LastList    = {}  -- [steamid] = { includeExpired, rows }

net.Receive("WarnSys.Notify", function()
    local msg = net.ReadString()
    local typ = net.ReadUInt(4)
    WarnSys.Util.Notify(LocalPlayer(), msg, typ)
end)

net.Receive("WarnSys.OpenMenu", function()
    local tab = net.ReadString()
    if tab == "" then tab = nil end
    if WarnSys.Client.OpenMenu then WarnSys.Client.OpenMenu(tab) end
end)

net.Receive("WarnSys.UpdateCount", function()
    WarnSys.Client.ActiveWarns = net.ReadUInt(8)
end)

net.Receive("WarnSys.SendWarns", function()
    local sid = net.ReadString()
    local includeExpired = net.ReadBool()
    local count = net.ReadUInt(16)
    local rows = {}
    for i = 1, count do
        rows[i] = {
            id            = net.ReadUInt(32),
            nick          = net.ReadString(),
            admin_nick    = net.ReadString(),
            admin_steamid = net.ReadString(),
            reason        = net.ReadString(),
            created       = net.ReadUInt(32),
            expires       = net.ReadUInt(32),
            active        = net.ReadBool(),
        }
    end
    WarnSys.Client.LastList[sid] = { expired = includeExpired, rows = rows }
    hook.Run("WarnSys.WarnsReceived", sid, rows, includeExpired)
end)

function WarnSys.Client.RequestWarns(sid, includeExpired)
    net.Start("WarnSys.RequestWarns")
        net.WriteString(sid)
        net.WriteBool(includeExpired or false)
    net.SendToServer()
end

-- Sprache live updaten (von Server gesendet, wenn Admin im Settings-Tab speichert)
net.Receive("WarnSys.SyncLanguage", function()
    if not WarnSys.Config then return end
    WarnSys.Config.Language = net.ReadString()
    hook.Run("WarnSys.LanguageChanged")
end)

-- Settings vom Server (nur SuperAdmin bekommt das)
net.Receive("WarnSys.SendConfig", function()
    local raw = net.ReadString()
    WarnSys.Client.RemoteConfig = util.JSONToTable(raw) or {}
    hook.Run("WarnSys.RemoteConfigReceived")
end)

-- MySQL-Verbindungstest-Ergebnis
net.Receive("WarnSys.MySQLTestResult", function()
    local ok = net.ReadBool()
    local msg = net.ReadString()
    hook.Run("WarnSys.MySQLTestResult", ok, msg)
end)

function WarnSys.Client.RequestConfig()
    net.Start("WarnSys.RequestConfig")
    net.SendToServer()
end

function WarnSys.Client.SaveConfig(tbl)
    net.Start("WarnSys.SaveConfig")
        net.WriteString(util.TableToJSON(tbl))
    net.SendToServer()
end

function WarnSys.Client.TestMySQL(tbl)
    net.Start("WarnSys.MySQLTest")
        net.WriteString(util.TableToJSON(tbl))
    net.SendToServer()
end
